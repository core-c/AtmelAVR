;-------------------------------------------------------------------
;--- Een DCC-Decoder voor de trein-modelbouw
;---
;---	Pin D6 (ICP) op de AT90S8535
;---	CK = 7372800 Hz
;---	TCK = CK, dus evenveel timerticks als clockticks per seconde
;---	ICP gebruiken we om de tijdsduur tussen 2 signaalveranderingen op een pin te meten
;---	DCC protocol: "1" duur tussen 52us - 64us, "0" duur tussen 90us - 10000us
;---	              "1" duur 383.3856 - 471.8592 ticks, "0" 663.552 - 73728 ticks
;---
;---	de stappen tijdens ontvangen van een packet:
;---		0 = wachten op (en verwerken van) een preamble
;---        1 = wachten op de packet-startbit
;---		2 = bezig met ontvangen van de address-byte
;---		3 = bezig met ontvangen van de data-startbit voor de instructie-byte
;---		4 = bezig met ontvangen van de instructie-byte
;---		5 = bezig met ontvangen van de data-startbit voor de error-correction-byte
;---		6 = bezig met ontvangen van de error-correction-byte
;---		7 = bezig met ontvangen van de packet-end-bit
;-------------------------------------------------------------------


;--- INCLUDE FILES --------------------\
;.nolist
.include "8535def.inc"					; AVR AT90S8535
.include "System.inc"					; 
.include "RotatingBuffer.asm"			; Een roterende buffer in SRAM
;.list
;--------------------------------------/



;--- CONSTANTEN -----------------------\
.equ CK = 7372800
.equ TCK = CK
.equ Tick = 1/TCK						; de duur van 1 (timer)tick
.equ Min_1 = 384						; 52us = 383.3856 ticks
.equ Max_1 = 472						; 64us = 471.8592 ticks
.equ Min_0 = 664						; 90us = 663.552 ticks
.equ Max_0 = $FFFF						; 10000us >= $FFFF ticks
;.equ Min_1 = (52/1000000)/Tick			; 52 us
;.equ Max_1 = (64/1000000)/Tick			; 64 us
;.equ Min_0 = (90/1000000)/Tick			; 90 us
;.if (10000/1000000)/(1/TCK) > $FFFF
;	.equ Max_0 = $FFFF					; gecorrigeerd
;.else
;	.equ Max_0 = (10000/1000000)/(1/TCK); 10000 us
;.endif

;-- de stappen tijdens ontvangst van de DCC-stream
.equ Step_Preamble					= 0
.equ Step_PacketStartBit			= 1
.equ Step_Address					= 2
.equ Step_InstructionStartBit		= 3
.equ Step_Instruction				= 4
.equ Step_ErrorDetectionStartBit	= 5
.equ Step_ErrorDetection			= 6
.equ Step_PacketEndBit				= 7
;--------------------------------------/


;--- REGISTER ALIASSEN ----------------\
.def temp			= R16				; Een register voor algemeen gebruik
.def Seq_1			= R17				; Een register voor telling aantal achter elkaar ontvangen "1"-bits
.def Step			= R18				; welke stap we zijn met ontvangen van een packet
.def Seq_Addr		= R19				; tbv. telling van aantal ontvangen adres-bits
.def Address		= R20				; de ontvangen adres byte
.def Seq_Instr		= R21				; tbv. telling van aantal ontvangen instructie-bits
.def Instruction	= R22				; de ontvangen instructie byte
.def Seq_ErrDet		= R23				; tbv. telling van aantal ontvangen error-detection-bits
.def ErrorDetection	= R24				; de ontvangen error-detection byte
;--------------------------------------/



;--- De AVR-AT90S8535 "vector"-tabel --\
.CSEG
.org $0000								; Het begin van de vector-tabel op adres 0 van het RAM
	rjmp RESET							; Reset Handler
	reti								; External Interrupt0 Vector Address
	reti								; External Interrupt1 Vector Address
	reti								; Timer2 compare match Vector Address
	reti								; Timer2 overflow Vector Address
	rjmp Timer_Interrupt_InputCapture	; Timer1 Input Capture Vector Address
	reti								; Timer1 Output Compare A Interrupt Vector Address
	reti								; Timer1 Output Compare B Interrupt Vector Address
	reti								; Overflow1 Interrupt Vector Address
	reti								; Overflow0 Interrupt Vector Address
	reti								; SPI Interrupt Vector Address
	reti								; UART Receive Complete Interrupt Vector Address
	reti								; UART Data Register Empty Interrupt Vector Address
	reti								; UART Transmit Complete Interrupt Vector Address
	reti								; ADC Conversion Complete Interrupt Vector Address
	reti								; EEPROM Write Complete Interrupt Vector Address
	reti								; Analog Comparator Interrupt Vector Address
;--------------------------------------/



;--- INCLUDE FILES --------------------\
.include "RS232.asm"					; 
;--------------------------------------/



;---------------------------------------
;--- een bit waarde op COMx afbeelden
;--------------------------------------\
UART_DisplayBit:
	ldi		temp, '0'
	brtc	UART_WriteBit
	ldi		temp, '1'
UART_WriteBit:
	rcall	UART_transmit
	ret
;--------------------------------------/


;---------------------------------------
;--- ICP initialiseren
;--------------------------------------\
ICP_Initialize:
	; interrupts tegengaan
	clr		temp
	out		TIMSK, temp
	; poort D pin 6 (ICP) als input instellen
	; voor de Input Capture
	ldi		temp, (0<<PIND4)
	out		DDRD, temp
	; De Timer1 HW-PWM uitschakelen
	clr		temp
	out		TCCR1A, temp
	; ICNC1: Noise Canceler uitschakelen => input capture om elke sample/capture.
	; ICES1: Input Capture Interrupts op neergaande flank laten genereren.
	; CTC1:  Clear TCNT on compareA match  uitschakelen
	; CS12,CS11 & CS10: timer1clock-select instellen op CK
	ldi		temp, (0<<ICNC1 | 0<<ICES1 | 0<<CTC1 | 0<<CS12 | 0<<CS11 | 1<<CS10)
	out		TCCR1B, temp
	; de counter op 0 instellen
	rcall	Reset_TimerCounter
	; Input-Capture interrupts inschakelen
	ldi		temp, (1<<TICIE1)
	out		TIMSK, temp
	; de stappen (tijdens ontvangst) resetten
	clr		Step
	; "1"-bit telling resetten (tbv ontdekken preamble)
	clr		Seq_1
	ret
;--------------------------------------/


;---------------------------------------
;--- Reset de timercounter op 0
;--------------------------------------\
Reset_TimerCounter:
	; de counter op 0 instellen
	clr		temp
	out		TCNT1H, temp
	out		TCNT1L, temp
	ret
;--------------------------------------/


;---------------------------------------
;--- T-flag naar Carry-flag
;--------------------------------------\
T_To_C:
	brts	Carry1
	clc
	rjmp	Done_T_To_C
Carry1:
	sec
Done_T_To_C:
	ret
;--------------------------------------/


;---------------------------------------
;--- NOT T-flag naar Carry-flag
;--------------------------------------\
NotT_To_C:
	brtc	Carry1_
	clc
	rjmp	Done_NotT_To_C
Carry1_:
	sec
Done_NotT_To_C:
	ret
;--------------------------------------/


;---------------------------------------
;--- Op de omgekeerde flank interrupts laten genereren.
;--- uitvoer: zero-flag geeft aan op welke flank
;---          we nu interrupts krijgen.
;---          1 = opgaande flank, 0 = neergaande flank
;--------------------------------------\
IRQ_OmgekeerdeFlank:
	; instellen om te reageren op de omgekeerde flank
	; Op welke flank krijgen we nu een interrupt?
	in		temp, TCCR1B
	andi	temp, (1<<ICES1)
	breq	Flank1
Flank0:
	; Er is zojuist gereageerd op een opgaande flank.
	; nu instellen om te reageren op neergaande flanken.
	andi	temp, ~(1<<ICES1)
	out		TCCR1B, temp
	; De Timer-Counter op 0 instellen om opnieuw te tellen
	rcall	Reset_TimerCounter
	clz									; resultaat 0 in zero-flag
	rjmp	Done_IRQ_OmgekeerdeFlank
Flank1:
	; Er is zojuist gereageerd op een neergaande flank.
	; nu instellen om te reageren op opgaande flanken
	ori		temp, (1<<ICES1)
	out		TCCR1B, temp
	sez									; resultaat 1 in zero-flag
Done_IRQ_OmgekeerdeFlank:
	ret
;--------------------------------------/


;---------------------------------------
;--- Test of een "1"- of "0"-bit is ontvangen.
;--- uitvoer: T-flag bevat de gelezen bit.
;---          carry-flag = 0, als de bit-pulsduur geldig is
;---          carry-flag = 1, als de bit ongeldig is.
;--------------------------------------\
Bit_Check:
	push	R16
	push	R17
	; Input-Capture-word lezen
	in		ZL, ICR1L
	in		ZH, ICR1H
	; was het een "1"-bit?
	; alles < Max_1 moet wel een "1"-bit zijn geweest..
	; als de pulsduur nog < Min_1 is, dan is het bit ongeldig verklaard.
	ldi		R16, low(Max_1)
	ldi		R17, high(Max_1)
	cp		ZL,	R16
	cpc		ZH, R17
	brsh	Bit_0						; Z > Max_1 => een "0"-bit ontvangen
	ldi		R16, low(Min_1)
	ldi		R17, high(Min_1)
	cp		ZL,	R16
	cpc		ZH, R17
	brlo	Bit_Fout					; Z < Min_1 => ongeldige packet
Bit_1:
	; Er is een geldige "1" ontvangen.
	set									; bit is een "1"
	clc									; bit is geldig
	rjmp	Done_Bit_Check
Bit_0:
	; alles > Max_1 moet wel een "0"-bit zijn geweest..
	; als de pulsduur < Min_0 of > Max_0 is, dan is het bit ongeldig verklaard.
	ldi		R16, low(Min_0)
	ldi		R17, high(Min_0)
	cp		ZL,	R16
	cpc		ZH, R17
	brlo	Bit_Fout					; Z < Min_0 => ongeldige packet
	ldi		R16, low(Max_0)
	ldi		R17, high(Max_0)
	cp		ZL,	R16
	cpc		ZH, R17
	brsh	Bit_Fout					; Z < Max_0 => ongeldige packet
	; Er is een geldige "0" ontvangen..
	clt									; bit is een "0"
	clc									; bit is geldig
	rjmp	Done_Bit_Check
Bit_Fout:
	; een ongeldige bit ontvangen.
	sec									; bit is ongeldig
Done_Bit_Check:
	pop		R17
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- de "1"-bits tellen die samen een preamble vormen.
;--------------------------------------\
Detect_Preamble:
	; Alleen tellen als een "1"-bit is ontvangen.
	; Bij ontvangst van een "0"-bit, de teller resetten.
	brts	Count_1
	clr		Seq_1
	rjmp	Done_Detect_Preamble
Count_1:
	inc		Seq_1
	; is er nu een complete preamble ontvangen?
	cpi		Seq_1, 10
	brlo	Done_Detect_Preamble		; nee, nog niet..
	; er is een (geldige) preamble ontvangen.
	; Op naar de volgende proces-stap,..
	; wachten op een "0"-bit (packet-start-bit)
	inc		Step
Done_Detect_Preamble:
	ret
;--------------------------------------/


;---------------------------------------
;--- uitvoer: zero-flag = 0, er is zojuist een "1"-bit ontvangen;
;---                         dwz. het END-MARKER-bit. Er komt niks meer..
;---          zero-flag = 1, er is zojuist een "0"-bit ontvangen; 
;---                         dwz. er komt nog (tenminste) een byte
;--------------------------------------\
Detect_StartStopBit:
	sez
	; was de laatst ontvangen bit een "0"?
	brtc	Done_Detect_StartStopBit
	clz
Done_Detect_StartStopBit:
	ret
;--------------------------------------/


;---------------------------------------
;--- uitvoer: carry-flag = 0, alles OK.
;---          carry-flag = 1, fout in protocol.
;---          zero-flag = 0, deze stap is niet aan de beurt..
;---          zero-flag = 1, deze stap is afgehandeld. Ga verder met de volgende stap in de volgende handler-doorgang
;--------------------------------------\
Detect_PacketStartBit:
	; alleen in stap 'Step_PacketStartBit' op een packet-start-bit testen..
	cpi		Step, Step_PacketStartBit
	brne	Done_Detect_PacketStartBit
	clz
	; was de laatst ontvangen bit een "0"?
	brts	Done_Detect_PacketStartBit
	inc		Step
	ldi		Seq_Addr, 1					; we gaan het 1e bit van het adres ontvangen..
	clr		Address
	sez									; vlaggetje zetten: "deze stap is afgehandeld"
Done_Detect_PacketStartBit:
	rcall	T_To_C						; T-flag naar de carry-flag.
	ret
;--------------------------------------/


;---------------------------------------
;---          zero-flag = 0, deze stap is niet aan de beurt..
;---          zero-flag = 1, deze stap is afgehandeld. Ga verder met de volgende stap in de volgende handler-doorgang
;--------------------------------------\
Detect_AddressByte:
	; alleen in stap 'Step_Address' op een adres-bit testen..
	cpi		Step, Step_Address
	brne	Done_Detect_AddressByte
	rcall	T_To_C						; T-flag naar de carry-flag.
	rol		Address
	lsl		Seq_Addr
	; register "Seq_Addr" bevat het bit-nummer van de te ontvangen adres-bit.
	cpi		Seq_Addr, 0
	brne	Done_Detect_AddressByte
	inc		Step
	sez									; vlaggetje zetten: "deze stap is afgehandeld"
	;
	; nu de gelezen data byte opslaan in de buffer
	;
Done_Detect_AddressByte:
	ret
;--------------------------------------/


;---------------------------------------
;--- uitvoer: carry-flag = 0, alles OK.
;---          carry-flag = 1, fout in protocol.
;---          zero-flag = 0, deze stap is niet aan de beurt..
;---          zero-flag = 1, deze stap is afgehandeld. Ga verder met de volgende stap in de volgende handler-doorgang
;--------------------------------------\
Detect_InstructionStartBit:
	; alleen in stap 'Step_InstructionStartBit' op een instructie startbit testen..
	cpi		Step, Step_InstructionStartBit
	brne	Done_Detect_InstructionStartBit
	clz
	; er moet zojuist een "0"-bit zijn ontvangen..
	brts	Done_Detect_InstructionStartBit
	; er is idd. een "0"-bit ontvangen..
	inc		Step
	ldi		Seq_Instr, 1				; we gaan het 1e bit van de instructie ontvangen..
	clr		Instruction
	sez									; vlaggetje zetten: "deze stap is afgehandeld"
Done_Detect_InstructionStartBit:
	rcall	T_To_C						; T-flag naar de carry-flag.
	ret
;--------------------------------------/


;---------------------------------------
;---          zero-flag = 0, deze stap is niet aan de beurt..
;---          zero-flag = 1, deze stap is afgehandeld. Ga verder met de volgende stap in de volgende handler-doorgang
;--------------------------------------\
Detect_InstructionByte:
	; alleen in stap 'Step_Instruction0' op een instructie-bit testen..
	cpi		Step, Step_Instruction
	brne	Done_Detect_InstructionByte
	rcall	T_To_C						; T-flag naar de carry-flag.
	rol		Instruction
	lsl		Seq_Instr
	; register "Seq_Instr" bevat het bit-nummer van de te ontvangen instructie-bit.
	cpi		Seq_Instr, 0
	brne	Done_Detect_InstructionByte
	inc		Step
	sez									; vlaggetje zetten: "deze stap is afgehandeld"
	;
	; nu de gelezen data byte opslaan in de buffer
	;
Done_Detect_InstructionByte:
	ret
;--------------------------------------/


;---------------------------------------
;--- uitvoer: carry-flag = 0, alles OK.
;---          carry-flag = 1, fout in protocol.
;---          zero-flag = 0, deze stap is niet aan de beurt..
;---          zero-flag = 1, deze stap is afgehandeld. Ga verder met de volgende stap in de volgende handler-doorgang
;--------------------------------------\
Detect_ErrorDetectionStartBit:
	; alleen in stap 'Step_ErrorDetectionStartBit' op een error-detection startbit testen..
	cpi		Step, Step_ErrorDetectionStartBit
	brne	Done_Detect_ErrorDetectionStartBit
	clz
	; er moet zojuist een "0"-bit zijn ontvangen..
	brts	Done_Detect_ErrorDetectionStartBit
	; er is idd. een "0"-bit ontvangen..
	inc		Step
	ldi		Seq_ErrDet, 1				; we gaan het 1e bit van de error-detection ontvangen..
	clr		ErrorDetection
	sez									; vlaggetje zetten: "deze stap is afgehandeld"
Done_Detect_ErrorDetectionStartBit:
	rcall	T_To_C						; T-flag naar de carry-flag.
	ret
;--------------------------------------/


;---------------------------------------
;---          zero-flag = 0, deze stap is niet aan de beurt..
;---          zero-flag = 1, deze stap is afgehandeld. Ga verder met de volgende stap in de volgende handler-doorgang
;--------------------------------------\
Detect_ErrorDetectionByte:
	; alleen in stap 'Step_ErrorDetection' op een error-detection-bit testen..
	cpi		Step, Step_ErrorDetection
	brne	Done_Detect_ErrorDetectionByte
	rcall	T_To_C						; T-flag naar de carry-flag.
	rol		ErrorDetection
	lsl		Seq_ErrDet
	; register "Seq_ErrDet" bevat het bit-nummer van de te ontvangen error-detection-bit.
	cpi		Seq_ErrDet, 0
	brne	Done_Detect_ErrorDetectionByte
	inc		Step
	sez									; vlaggetje zetten: "deze stap is afgehandeld"
Done_Detect_ErrorDetectionByte:
	ret
;--------------------------------------/


;---------------------------------------
;--- uitvoer: carry-flag = 0, alles OK.
;---          carry-flag = 1, fout in protocol.
;---          zero-flag = 0, deze stap is niet aan de beurt..
;---          zero-flag = 1, deze stap is afgehandeld. Ga verder met de volgende stap in de volgende handler-doorgang
;--------------------------------------\
Detect_PacketEndBit:
	; alleen in stap 'Step_PacketEndBit' op een packet end-bit testen..
	cpi		Step, Step_PacketEndBit
	brne	Done_Detect_PacketEndBit
	clz
	; er moet zojuist een "1"-bit zijn ontvangen..
	brtc	Done_Detect_PacketEndBit
	; er is idd. een "1"-bit ontvangen..
	; Alle stappen zijn nu succesvol doorlopen.
	; Er is een compleet pakketje ontvangen.
	clr		Step
	clr		Seq_1
	sez									; vlaggetje zetten: "deze stap is afgehandeld"
Done_Detect_PacketEndBit:
	rcall	NotT_To_C					; NOT T-flag naar de carry-flag.
	ret
;--------------------------------------/


;---------------------------------------
;---
;--------------------------------------\
Packet_Reset:
	cpi		Address, 0
	brne	Done_Packet_Reset
	cpi		Instruction, 0
	brne	Done_Packet_Reset
	cpi		ErrorDetection, 0
	brne	Done_Packet_Reset
Done_Packet_Reset:
	ret
;--------------------------------------/


;---------------------------------------
;---
;--------------------------------------\
Packet_Idle:
	cpi		Address, $FF
	brne	Done_Packet_Idle
	cpi		Instruction, 0
	brne	Done_Packet_Idle
	cpi		ErrorDetection, $FF
	brne	Done_Packet_Idle
Done_Packet_Idle:
	ret
;--------------------------------------/


;---------------------------------------
;---
;--------------------------------------\
Packet_Stop:
	cpi		Address, 0
	brne	Done_Packet_Stop
	cp		Instruction, ErrorDetection
	brne	Done_Packet_Stop
Done_Packet_Stop:
	ret
;--------------------------------------/


;---------------------------------------
;--- De ICP handler
;--------------------------------------\
Timer_Interrupt_InputCapture:
	; De ICF1 flag in het TIFR-register is nu gezet.
	; Deze flag wordt automatisch gewist als de interrupt-handler wordt uitgevoerd.
	push	temp						; register "temp" bewaren op de stack
	in		temp, SREG					; register "SREG"
	push	temp
	push	ZL							; register "Z"
	push	ZH

	; instellen om te reageren op de omgekeerde flank
	rcall	IRQ_OmgekeerdeFlank
	; de zero-flag is nu gezet als we interrupts krijgen op opgaande flanken..
	; dwz. als er zojuist is gereageerd op een neergaande flank (het einde van een bit-cycle)
	brne	Done_ICP	

	; bepaal of een "1"- of "0"-bit was ontvangen,
	; en of de bit wel een geldige pulsduur heeft.
	; na afloop bevat de processor T-flag de ontvangen bit-waarde.
	rcall	Bit_Check
	brcs	Bit_Ongeldig

	; deze bit afbeelden op de com poort.
	rcall	UART_DisplayBit

	; een mogelijke preamble detecteren.
	rcall	Detect_Preamble
	; een packet startbit detecteren.
	rcall	Detect_PacketStartBit
	breq	Done_ICP					; als het packet-startbit is verwerkt dan zijn we klaar nu..
	brcs	Bit_Ongeldig				; ongeldig protocol indien de carry is gezet..
	; een adres-bit detecteren
	rcall	Detect_AddressByte
	breq	Done_ICP					; als een adres-bit is verwerkt dan zijn we klaar nu..
	; een instructie startbit detecteren
	rcall	Detect_InstructionStartBit
	breq	Done_ICP					; als het instructie-startbit is verwerkt dan zijn we klaar nu..
	brcs	Bit_Ongeldig				; ongeldig protocol..
	; een instructie bit detecteren
	rcall	Detect_InstructionByte
	breq	Done_ICP					; als een instructie-bit is verwerkt dan zijn we klaar nu..
	; een error-detection startbit detecteren
	rcall	Detect_ErrorDetectionStartBit
	breq	Done_ICP					; als het error-detection-startbit is verwerkt dan zijn we klaar nu..
	brcs	Bit_Ongeldig				; ongeldig protocol..
	; een error-detection bit detecteren
	rcall	Detect_ErrorDetectionByte
	breq	Done_ICP					; als een error-detection-bit is verwerkt dan zijn we klaar nu..
	; een packet endbit detecteren
	rcall	Detect_PacketEndBit
	breq	Packet_Complete				; als het packet-endbit is verwerkt dan de packet verwerken..
	brcs	Bit_Ongeldig				; ongeldig protocol..
	rjmp	Done_ICP

Packet_Complete:
	; er is een compleet pakketje ontvangen.
	rcall	UART_Space
	; registers "Address", "Instruction" & "ErrorDetection" bevatten de ontvangen data.
	rcall	Packet_Reset
	breq	Done_ICP
	rcall	Packet_Idle
	breq	Done_ICP
	rcall	Packet_Stop
	breq	Done_ICP
	;
	mov		temp, Address				; Address
	rcall	UART_transmit
	ldi		temp, ' '					; spatie
	rcall	UART_transmit
	mov		temp, Instruction			; Instruction
	rcall	UART_transmit
	ldi		temp, ' '					; spatie
	rcall	UART_transmit
	mov		temp, ErrorDetection		; ErrorDetection
	rcall	UART_transmit
	rcall	UART_CrLf					; CrLf
	;
	rjmp	Done_ICP

Bit_Ongeldig:
	; proces-stap aanpassen na ontvangst van een ongeldige bit.
	; Opnieuw op een preamble wachten (nieuwe packet).
	clr		Step
	clr		Seq_1

Done_ICP:
	pop		ZH
	pop		ZL
	pop		temp
	out		SREG, temp
	pop		temp
	reti
;--------------------------------------/




;---------------------------------------
;--- Main Program
;--------------------------------------\
RESET:
	cli									; interrupts tegenhouden
	initStackPointer					; initialiseer de stack pointer

	;-- initialisatie
	rcall	UART_Initialize_Buffer
	rcall	UART_Initialize

	rcall	ICP_Initialize
	;--

	sei									; interrupts weer toelaten

	rcall	delay1s
	rcall	UART_transmit_InitString

main_loop:
	rjmp 	main_loop
;--------------------------------------/




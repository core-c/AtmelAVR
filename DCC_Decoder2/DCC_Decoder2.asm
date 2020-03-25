;-------------------------------------------------------------------
;--- Een DCC-Decoder voor de trein-modelbouw
;---
;---	Pin D6 (ICP) op de AT90S8535
;---	CK = 7372800 Hz
;---	TCK = CK, dus evenveel timerticks als clockticks per seconde
;---	ICP gebruiken we om de tijdsduur tussen 2 signaalveranderingen op een pin te meten
;---	DCC protocol: "1" duur tussen 52us - 64us, "0" duur tussen 90us - 10000us
;---	              "1" duur 383.3856 - 471.8592 ticks, "0" 663.552 - 73728 ticks (TCK=CK, CK=7.372800MHz)
;---	              "1" duur 52-64 ticks, "0" 90 - 10000 ticks (TCK=CK/8, CK=8MHz)
;---	De tijd tussen 2 packets moet zijn tenminste 5 ms. (40000 timerticks)
;-------------------------------------------------------------------


;--- INCLUDE FILES --------------------\
;.nolist
.include "8535def.inc"					; AVR AT90S8535
.include "System.inc"					; 
.include "RotatingBuffer.asm"			; Een roterende buffer in SRAM
;.list
;--------------------------------------/



;--- CONSTANTEN -----------------------\
;.equ CK = 7372800						; CPU clock frequentie					; 8000000	; 8000000
;.equ TCK = CK							; timer1 frequentie						; CK		; CK/8
;.equ Tick = 1/TCK						; de duur van 1 (timer)tick in seconden	; 1/TCK		; 1/TCK
;.equ Min_1 = 384						; 52us = 383.3856 ticks					; 416		; 52
;.equ Max_1 = 472						; 64us = 471.8592 ticks					; 512		; 64
;.equ Min_0 = 664						; 90us = 663.552 ticks					; 720		; 90
;.equ Max_0 = $FFFF						; 10000us >= $FFFF ticks				; 80000		; 10000

.equ CK = 8000000						; CPU clock frequentie					; 8000000
.equ TCK = CK/8							; timer1 frequentie						; CK/8
.equ Tick = 1/TCK						; de duur van 1 (timer)tick in seconden	; 1/TCK
.equ Min_1 = 52							; 52us									; 52 ticks
.equ Max_1 = 64							; 64us									; 64
.equ Min_0 = 90							; 90us									; 90
.equ Max_0 = 10000						; 10000us								; 10000



;-- waarden voor TCCR1B
; ICNC1: Noise Canceler uitschakelen => input capture om elke sample/capture.
; ICES1: Input Capture Interrupts op neergaande flank laten genereren.
; CTC1:  Clear TCNT on compareA match  uitschakelen
; CS12,CS11 & CS10: timer1clock-select instellen op CK (0,0,1)      CK/8=0,1,0
.equ IntOnLowEdge	= (0<<ICNC1 | 0<<ICES1 | 0<<CTC1 | 0<<CS12 | 1<<CS11 | 0<<CS10)
.equ IntOnHighEdge	= (0<<ICNC1 | 1<<ICES1 | 0<<CTC1 | 0<<CS12 | 1<<CS11 | 0<<CS10)


;-- de stappen tijdens ontvangst van de DCC-stream
.equ Step_Preamble					= 0
.equ Step_PacketStartBit			= 1
.equ Step_Address					= 2
.equ Step_DataStartBit				= 3
.equ Step_Data						= 4
.equ Step_PacketEndBit				= 5	; 1=packet-end-bit (goto step 0), 0=data-start-bit (goto step 4)
;--------------------------------------/


;--- REGISTER ALIASSEN ----------------\
.def temp			= R16				; Een register voor algemeen gebruik
.def Edge			= R17				; huidige flank die een interrupt zal veroorzaken
.def Step			= R18				; huidige stap tijdens ontvang-proces van een packet
.def Seq_1			= R19				; Een register voor telling aantal achter elkaar ontvangen "1"-bits
.def Seq_Addr		= R20				; tbv. telling aantal ontvangen bits van huidige adres-byte
.def AddressByte	= R21				; de (huidige) ontvangen adres-byte
.def Seq_Data		= R22				; tbv. telling aantal ontvangen bits van huidige data-byte
.def DataByte		= R23				; de (huidige) ontvangen data-byte
.def EOP			= R24				; End-Of-Packet (waarden: 1=compleet packet binnen, 0=bezig met ontvangen)
;--------------------------------------/



;--- EEPROM ---------------------------\
;--------------------------------------/


;--- BUFFER in SRAM
;--- voor ontvangst ICP-data ----------\
.DSEG
.equ Bit_BufferSize = 100				; genoeg plek ongeveer 10 bytes DCC-bitstream data
Bit_Buffer:	.BYTE Bit_BufferSize
Bit_Input:	.BYTE 2						; het adres voor nieuw toe te voegen Bit-data
Bit_Count:	.BYTE 1						; aantal bytes (Bit-data) in buffer
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
	rjmp Timer_Interrupt_Overflow		; Overflow1 Interrupt Vector Address
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
.include "NumToStr.asm"					;
;--------------------------------------/



;---------------------------------------
;--- De bit-buffer initialiseren
;--------------------------------------\
Bit_Buffer_Initialize:
	; aantal bytes in buffer op 0
	clr		temp						; Bit_Count := 0
	sts		Bit_Count, temp				;
	; input-pointer op 1e byte van buffer
	ldi		R26, low(Bit_Buffer)		; Bit_Input := Bit_Buffer^
	ldi		R27, high(Bit_Buffer)		;
	sts		Bit_Input, R26				;
	sts		Bit_Input+1, R27			;
	; End-Of-Packet instellen om te ontvangen/verwerken
	clr		EOP
	ret
;--------------------------------------/


;---------------------------------------
;--- T-flag naar Carry-flag
;--------------------------------------\
T_To_C:
	sec
	brts	Done_T_To_C
	clc
Done_T_To_C:
	ret
;--------------------------------------/


;---------------------------------------
;--- NOT T-flag naar Carry-flag
;--------------------------------------\
NotT_To_C:
	clc
	brts	Done_NotT_To_C
	sec
Done_NotT_To_C:
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
	cbi		DDRD, PD6
	; De Timer1 HW-PWM uitschakelen
	clr		temp
	out		TCCR1A, temp
	; Input Capture Interrupts op opgaande flank laten genereren.
	ldi		Edge, IntOnHighEdge			; 1e interrupt op een opgaande flank
	out		TCCR1B, Edge
	; de counter op 0 instellen
	clr		temp
	out		TCNT1H, temp
	out		TCNT1L, temp
	; Input-Capture interrupts inschakelen
	; timer1 overflow interrupt inschakelen
	ldi		temp, (1<<TICIE1 | 1<<TOIE1)
	out		TIMSK, temp
	; de stappen (tijdens ontvangst) resetten
	clr		Step
	; "1"-bit telling resetten (tbv ontdekken preamble)
	clr		Seq_1
	ret
;--------------------------------------/


;---------------------------------------
;--- Test of een "1"- of "0"-bit is ontvangen.
;--- invoer: Z register bevat ICP-timing word
;--- uitvoer: T-flag bevat de gelezen bit.
;---          carry-flag = 0, als de bit-pulsduur geldig is
;---          carry-flag = 1, als de bit ongeldig is.
;--------------------------------------\
Bit_Check:
	push	R16
	push	R17
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
;--- De Overflow handler
;--- Als aan deze overflow conditie wordt
;--- voldaan, is er een ongeldige bit ontvangen.
;--- Of we zitten op een tijdstip tussen 2 DCC-packets.
;--- Sowieso op een nieuw packet wachten...
;--------------------------------------\
Timer_Interrupt_Overflow:
	push	temp						; register "temp" bewaren op de stack
	in		temp, SREG					; register "SREG"
	push	temp

	; proces-stap aanpassen na ontvangst van een ongeldige bit.
	; Opnieuw op een preamble wachten (nieuwe packet).
	clr		Step
	clr		Seq_1
	; packet eerst verwerken (marker zetten)..
	; alvorens een nieuw packet te ontvangen..
	ldi		EOP, 1
	
	pop		temp
	out		SREG, temp
	pop		temp
	reti
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

	; De Timer-Counter op 0 instellen om opnieuw te tellen
	clr		temp
	out		TCNT1H, temp
	out		TCNT1L, temp

	; Input-Capture-word lezen
	in		ZL, ICR1L
	in		ZH, ICR1H

	; instellen om te reageren op de omgekeerde flank
	ldi		temp, IntOnLowEdge			;
	cpi		Edge, IntOnHighEdge			;
	breq	Done_IRQ_OmgekeerdeFlank
	ldi		temp, IntOnHighEdge			;
Done_IRQ_OmgekeerdeFlank:
	mov		Edge, temp					; volgende Edge-waarde bewaren..
	out		TCCR1B, temp				; 
	; zero-flag instellen
	cpi		Edge, IntOnHighEdge			;

	; de zero-flag is nu gezet als we interrupts krijgen op opgaande flanken..
	; dwz. als er zojuist is gereageerd op een neergaande flank (het einde van een bit-cycle)
	brne	Done_ICP

	; packets ontvangen/verwerken?
	cpi		EOP, 1
	breq	Done_ICP

	; bepaal of een "1"- of "0"-bit was ontvangen,
	; en of de bit wel een geldige pulsduur heeft.
	; na afloop bevat de processor T-flag de ontvangen bit-waarde.
	; de carry-flag is gezet als de bit ongeldig is.
	rcall	Bit_Check
	brcs	Bit_Ongeldig

	; de gelezen bit opslaan in de buffer,
	; voor latere verwerking buiten de(ze) interrupt-handler.
	ldi		temp, '1'					; T-flag naar ASCII-waarde
	brts	Bit_ASCII					;
	ldi		temp, '0'					;
Bit_ASCII:
	; opslaan in buffer
	lds		ZL, Bit_Input				; Z := Bit_Input^
	lds		ZH, Bit_Input+1				;
	st		Z+, temp					; Bit_Buffer[Bit_Input^] := temp;  Z := Z+1
	sts		Bit_Input, ZL				; Bit_Input := Z
	sts		Bit_Input, ZH				;
	; aantal bits in buffer met 1 verhogen
	lds		temp, Bit_Count				; Bit_Count := Bit_Count+1
	inc		temp						;
	sts		Bit_Count, temp				;

	rjmp	Done_ICP

Bit_Ongeldig:
	; proces-stap aanpassen na ontvangst van een ongeldige bit.
	; Opnieuw op een preamble wachten (nieuwe packet).
	clr		Step
	clr		Seq_1
	; buffer resetten voor nieuwe ontvangst..
	rcall	Bit_Buffer_Initialize		;

Done_ICP:
	pop		ZH
	pop		ZL
	pop		temp
	out		SREG, temp
	pop		temp
	reti
;--------------------------------------/



;---------------------------------------
;--- Een packet verwerken
;--- (in main-loop)
;--------------------------------------\
Process_Packet:
	cpi		EOP, 0
	breq	Done_Process_Packet
	; de bits uitvoeren naar de COM: poort
	push	R25
	lds		R25, Bit_Count				; R25 := Bit_Count

	lds		ZL, Bit_Buffer				; Z := Bit_Buffer^
	lds		ZH, Bit_Buffer+1			;
Send_Next_Bit:
	ld		temp, Z+					; temp := [Z];   Z := Z+1
	rcall	UART_transmit
	dec		R25
	brne	Send_Next_Bit
	rcall	UART_CrLf

	pop		R25
	rcall	Bit_Buffer_Initialize		; het packet is "verwerkt"..
Done_Process_Packet:
	ret
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

	rcall	Bit_Buffer_Initialize

	;--

	rcall	delay1s
	rcall	UART_transmit_InitString

	rcall	ICP_Initialize

	sei									; interrupts weer toelaten

main_loop:
	rcall	Process_Packet
	rjmp 	main_loop
;--------------------------------------/





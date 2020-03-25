;-------------------------------------------------------------------
;--- Een DCC-Zender voor de trein-modelbouw
;---
;---	Output op Pin D6 op de AT90S8535
;---	CK = 7.372800 MHz
;---	TCK = CK /8, dus een timertick per microseconde
;---	DCC protocol: "1" duur tussen 52us - 64us, "0" duur tussen 90us - 10000us (10ms)
;---	(Het verschil in dutycycle tussen perioden A & B, mag niet zijn > 6us)
;---	De tijd tussen 2 packets moet zijn >= 5 ms. (dus packet-end-bit <-> preamble)
;---	Tenminste elke 30ms moet een packet kunnen worden verzonden
;---
;---	          __    __
;---	         |  |  |  |  |
;---	         |pB|  |  |  |
;---	------+--+  +--+  +--+
;---	      .pA.  .  .  .  .      pA = periode A
;---	      .  .  .  .  .  .      pB = periode B
;---	      ....  ....  ....	     . = signaal door booster gemaakt
;---
;---	         *     *     *       * = verwerk periode A
;---	      #     #     #          # = verwerk periode B
;---
;---
;--- BitStream in SRAM: '0'=0-bit, '1'=1-bit, '*'=ongeldige bit, ' '=pulsduur te lang/packet-end
;---
;-------------------------------------------------------------------


;--- INCLUDE FILES --------------------\
;.nolist
.include "8535def.inc"					; AVR AT90S8535
.include "RotatingBuffer.asm"			; Ron's ring-buffer macro's
;.list
;--------------------------------------/




;--- COMPILER DIRECTIVES --------------\
.equ Output_To_COM 		= 0				; ontvangen bits uitvoeren naar de COM: poort (binnen handlers)
.equ Output_To_LED 		= 1				; ontvangen bits uitvoeren naar de LED's
.equ Save_To_Bitstream	= 1				; ontvangen bits bewaren als een stream in SRAM
;--------------------------------------/




;--- CONSTANTEN -----------------------\
.equ CK 			= 7372800			; CPU clock frequentie	; 7372800
.equ TCK 			= CK/8				; timer1 frequentie		; CK/8
.equ Min1 			= 0.000052 * TCK	; duur van een (halve/positieve) bit (in timerticks)
.equ Max1 			= 0.000064 * TCK
.equ Min0 			= 0.000090 * TCK
.equ Max0 			= 0.010000 * TCK
.equ TimeOutValue	= 0.018 * TCK		; 18 milliseconden
; connecties met AVR
.equ CaptureDDR		= DDRD
.equ CapturePort	= PORTD
.equ CaptureIn		= PIND
.equ CapturePin		= PD6
; LED's
.equ LED_DDR		= DDRC
.equ LED_Port		= PORTC
.equ LED_Error		= PC7
.equ LED_Bit		= PC6
; strings/chars
.equ CHR_0			= '0'
.equ CHR_1			= '1'
.equ CHR_Error		= '*'
.equ CHR_Timeout	= ' '
; TCCR1B waarden
; ICNC1: Noise Canceler uitschakelen => input capture om elke sample/capture.
; ICES1: Input Capture Interrupts op neergaande flank laten genereren (0).
; CTC1:  Clear TCNT on compareA match uitschakelen
; CS12,CS11 & CS10: timer1clock-select instellen op CK/8 (0,1,0)
.equ EdgeLow	= (0<<ICNC1 | 0<<ICES1 | 0<<CTC1 | 0<<CS12 | 1<<CS11 | 0<<CS10)
.equ EdgeHigh	= (0<<ICNC1 | 1<<ICES1 | 0<<CTC1 | 0<<CS12 | 1<<CS11 | 0<<CS10)
;--------------------------------------/




;--- REGISTER ALIASSEN ----------------\
.def temp				= R16			; Een register voor algemeen gebruik
.def temp2				= R17			; nog 1..
.def TimeOut			= R18			; De time-out vlag
.def CaptureComplete	= R19			; End-Of-Capture vlag
.def CaptureL			= R20			; De laatste ICP-sample waarde  (Low/High)
.def CaptureH			= R21			;
.def BytesCaptured		= R22
;.def XL								; pointer naar te schrijven adres in BitStream
;.def XH
;--------------------------------------/



;--- Variablelen in SRAM --------------\
.DSEG
BitStream:	.BYTE 100					; 100 bytes data voor de bitstream (1 byte per bit)
ByteStream:	.BYTE 8						; de bitstream gedecodeerd naar een "byte-stream"
;--------------------------------------/


;--- De AVR-AT90S8535 "vector"-tabel --\
.CSEG
.org $0000								; Het begin van de vector-tabel op adres 0 van het RAM
	rjmp RESET							; Reset Handler
	reti								; External Interrupt0 Vector Address
	reti								; External Interrupt1 Vector Address
	reti								; Timer2 compare match Vector Address
	reti								; Timer2 overflow Vector Address
	rjmp Timer_Input_Capture			; Timer1 Input Capture Vector Address
	rjmp Timer_Interrupt_CompareA		; Timer1 Output Compare A Interrupt Vector Address
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
.include "RS232.asm"					; UART routines
.include "NumToStr.asm"					; getallen naar Hex of Dec
;--------------------------------------/




;---------------------------------------
;--- MACRO's
;--------------------------------------\
; De stack-pointer instellen op het einde van het RAM
.MACRO initStackPointer
	ldi		temp2, high(RAMEND)
	ldi		temp, low(RAMEND)
	out		SPH, temp2
	out		SPL, temp
.ENDMACRO

.MACRO LED_Off;(LED)
	cbi		LED_Port, @0				; LED uit
.ENDMACRO

.MACRO LED_On;(LED)
	sbi		LED_Port, @0				; LED aan
.ENDMACRO

.MACRO ResetCounter
	; de counter op 0 instellen
	clr		temp
	out		TCNT1H, temp
	out		TCNT1L, temp
.ENDMACRO

.MACRO ReadCounter;(Dutycycle_LOW, Dutycycle_HIGH : register)
	; de timercounter uitlezen in register "Dutycycle"
	in		@0, TCNT1L
	in		@1, TCNT1H
.ENDMACRO

.MACRO WaitForICP
_0:	sbrc	CaptureComplete, 0
	rjmp	_0
	clr		CaptureComplete
.ENDMACRO

.MACRO ICP_OnLowEdge
	ldi		temp, EdgeLow
	out		TCCR1B, temp
.ENDMACRO

.MACRO ICP_OnHighEdge
	ldi		temp, EdgeHigh
	out		TCCR1B, temp
.ENDMACRO

.MACRO PushBit;(Bit)
	; X verwijst naar het volgende te schrijven adres in de BitStream-buffer..
	st		X+, @0						; [X] := @0,  X++
.ENDMACRO

;--- Macro TestPeriode
.MACRO TestPeriode;(Dutycycle_LOW, Dutycycle_HIGH : register)
	; test of de bit geldig is; dwz:   (# betekent ongeldig)
	;
	; #####|      1      |##########|      0      |#####
	;      ^             ^          ^             ^
	;      Min1          Max1       Min0          Max0
	;

	; Dutycycle < Min1 ?
	cpi		@0, low(Min1)
	ldi		temp, high(Min1)
	cpc		@1, temp
	brlo	_2							; bit ongeldig
	; Dutycycle <= Max1 ?
	cpi		@0, low(Max1+1)
	ldi		temp, high(Max1+1)
	cpc		@1, temp
	brlo	_1							; geldige "1"
	; Dutycycle < Min0 ?
	cpi		@0, low(Min0)
	ldi		temp, high(Min0)
	cpc		@1, temp
	brlo	_2							; bit ongeldig
	; Dutycycle <= Max0 ?
	cpi		@0, low(Max0+1)
	ldi		temp, high(Max0+1)
	cpc		@1, temp
	brlo	_0							; geldige "0"
_2:	;ongeldige bit
	.ifdef Output_To_LED
		LED_On LED_Error				; Error LED aan (ongeldig)
		LED_Off LED_Bit					; Bit LED uit
	.endif
	.ifdef Output_To_COM
		ldi		temp, CHR_Error
		;rcall	UART_transmit
_4:		sbis	USR, UDRE
		rjmp	_4
		out		UDR, temp
	.endif
	.ifdef Save_To_Bitstream
		ldi		temp, CHR_Error
		PushBit temp
	.endif
	rjmp	_3
_0:	; een geldige "0"
	.ifdef Output_To_LED
		LED_Off LED_Error				; Error LED uit (geldig)
		LED_Off LED_Bit					; Bit LED uit ("0")
	.endif
	.ifdef Output_To_COM
		ldi		temp, CHR_0
		;rcall	UART_transmit
_5:		sbis	USR, UDRE
		rjmp	_5
		out		UDR, temp
	.endif
	.ifdef Save_To_Bitstream
		ldi		temp, CHR_0
		PushBit temp
	.endif
	rjmp	_3
_1:	; een geldige "1"
	.ifdef Output_To_LED
		LED_Off LED_Error				; Error LED uit (geldig)
		LED_On LED_Bit					; Bit LED aan ("1")
	.endif
	.ifdef Output_To_COM
		ldi		temp, CHR_1
		;rcall	UART_transmit
_6:		sbis	USR, UDRE
		rjmp	_6
		out		UDR, temp
	.endif
	.ifdef Save_To_Bitstream
		ldi		temp, CHR_1
		PushBit temp
	.endif
_3:	
.ENDMACRO

.MACRO ResetStream
	ldi		XL, low(BitStream)
	ldi		XH, high(BitStream)
.ENDMACRO

.MACRO SetTimeout
	ser		Timeout
.ENDMACRO

.MACRO ClearTimeout
	clr		Timeout
.ENDMACRO

.MACRO WaitForTimeOut
_0:	sbrs	TimeOut, 0
	rjmp	_0
	clr		TimeOut
	clr		CaptureComplete
.ENDMACRO

.MACRO If_Timedout_Jmp;(label)
	sbrc	TimeOut, 0
	rjmp	@0
.ENDMACRO

.MACRO LoadBit;(Label_onError)
	cp		YL, XL						; Y>=X?
	cpc		YH, XH						;
	brsh	@0							; ja? dan klaar..
	ld		temp, Y+					; temp := [Y],  Y++
	; bit controleren
	cpi		temp, CHR_Error				; foute bit?
	breq	@0							; ja? dan klaar..	
	cpi		temp, CHR_Timeout			; foute bit?
	breq	@0							; ja? dan klaar..	
.ENDMACRO

.MACRO GetByte;(register, Label_onError)
	ldi		@0, 1					;
_3:
	LoadBit @1
	; bit naar carry-flag
	cpi		temp, CHR_0
	breq	_0
_1:
	sec
	rjmp	_2
_0:
	clc
_2:
	rol		@0							; bit in de byte schuiven
	brcc	_3							; byte nog niet binnen? dan naar Byte1..
.ENDMACRO
;--------------------------------------/





;---------------------------------------
;--- De LED poorten instellen
;--------------------------------------\
LED_Initialize:
	sbi		LED_DDR, LED_Error			; output
	LED_Off LED_Error					; Error LED uit
	sbi		LED_DDR, LED_Bit			; output
	LED_Off LED_Bit						; Bit LED uit
	ret
;---------------------------------------


;---------------------------------------
;--- De Capture pin instellen
;--------------------------------------\
Capture_Initialize:
	cbi		CaptureDDR, CapturePin		; "input capture" pin
	cbi		CapturePORT, CapturePin		; tri-state
	clr		CaptureL					; de ICP sample-waarde resetten
	clr		CaptureH
	; de analog comparator uitschakelen
	cbi		ACSR, ACIE
	sbi		ACSR, ACD
	cbi		ACSR, ACIC
	ret
;--------------------------------------/


;---------------------------------------
;--- De Bitstream (schrijf-adres)pointer
;--------------------------------------\
BitStream_Initialize:
	ResetStream							; pointer voor buffer-input resetten
	ClearTimeout						; de time-out vlag wissen
	ret
;--------------------------------------/


;---------------------------------------
;--- De Bitstream afbeelden op de COM: poort
;--- invoer: register X = pointer naar EndOfBitstream in buffer
;--------------------------------------\
BitStream_Display:
	;NB. X bevat de pointer naar het einde van de buffer (excl. X)
	ldi		YL, low(BitStream)			; Y := begin bitstream buffer
	ldi		YH, high(BitStream)			;
EOB:
	cp		YL, XL						; Y>=X?
	cpc		YH, XH						;
	brsh	Done_BitStream_Display		; ja? dan klaar..
	ld		temp, Y+					; temp := [Y],  Y++
	rcall	UART_transmit
	rjmp	EOB
Done_BitStream_Display:
	rcall	UART_CrLf
	ret
;--------------------------------------/


;---------------------------------------
;--- De Bytestream afbeelden op de COM: poort
;--- invoer: BytesCaptured = aantal bytes in Bytestream-buffer
;--------------------------------------\
ByteStream_Display:
	cpi		BytesCaptured, 0
	breq	Done_ByteStream_Display
NB:
	ldi		ZL, low(ByteStream)			; Z := begin bytestream buffer
	ldi		ZH, high(ByteStream)		;
	ld		temp, Z+
	rcall	HexByte
	rcall	UART_Space
	;
	dec		BytesCaptured
	brne	NB

Done_ByteStream_Display:
	rcall	UART_CrLf
	ret


;---------------------------------------
;--- De Bitstream decoderen naar aparte bytes
;--- invoer: register X = pointer naar EndOfBitstream in buffer
;--------------------------------------\
BitStream_Decode:
	;NB. X bevat de pointer naar het einde van de buffer (excl. X)
	ldi		ZL, low(ByteStream)			; Z := begin bytestream buffer
	ldi		ZH, high(ByteStream)		;
	clr		BytesCaptured

	;--- nu de preamble verwerken ------
	ldi		YL, low(BitStream)			; Y := begin bitstream buffer
	ldi		YH, high(BitStream)			;
Preamble:
	LoadBit Done_BitStream_Decode
	; de preamble inslikken
	cpi		temp, CHR_1
	breq	Preamble
	; de preamble is voorbij,
	; de packet-start-bit is zojuist gelezen..
	cpi		temp, CHR_0
	brne	Done_BitStream_Decode

	;--- nu de 1e byte verwerken -------
	;--- (adres in temp2)
DataByte:
	GetByte temp2, Done_BitStream_Decode
	; er is nu een complete byte binnen
	; opslaan in de byte-buffer.
	st		Z+, temp2
	inc		BytesCaptured

	;--- nu een data-start-bit verwerken
	;--- Als dit bit == 1 dan is dit het packet-end-bit.
	LoadBit Done_BitStream_Decode
	; de packet-start-bit is altijd een "0"-bit
	cpi		temp, CHR_0
	brne	Done_BitStream_Decode

	;--- nu de 2e byte verwerken -------
	rjmp	DataByte

Done_BitStream_Decode:
	ret
;--------------------------------------/



;---------------------------------------
;--- De Timer1 initialiseren
;--------------------------------------\
Timer_Initialize:
	; interrupts tegengaan
	clr		temp
	out		TIMSK, temp
	; De Timer1 HW-PWM uitschakelen
	clr		temp
	out		TCCR1A, temp
	;-- waarden voor TCCR1B
	; ICNC1: Noise Canceler uitschakelen => input capture om elke sample/capture.
	; ICES1: Input Capture Interrupts op neergaande flank laten genereren.
	; CTC1:  Clear TCNT on compareA match uitschakelen
	; CS12,CS11 & CS10: timer1clock-select instellen op CK/8 (0,1,0)
	ICP_OnLowEdge
	; timer1 ICP inschakelen
	; timer1 compareA match interrupt inschakelen
	; timer1 compareB match interrupt uitschakelen
	ldi		temp, (1<<TICIE1 | 1<<OCIE1A | 0<<OCIE1B)
	out		TIMSK, temp
	; Compare-A waarde instellen
	ldi		temp2, high(TimeOutValue)
	ldi		temp, low(TimeOutValue)
	out		OCR1AH, temp2
	out		OCR1AL, temp
	; de counter op 0 instellen
	ResetCounter
	ret
;--------------------------------------/



;---------------------------------------
;--- Timer1 CompareA match handler
;--------------------------------------\
Timer_Input_Capture:
	push	temp
	push	temp2
	in		temp, SREG
	push	temp
	; ICP sample bewaren
	in		CaptureL, ICR1L
	in		CaptureH, ICR1H
	; timercounter op 0
	ResetCounter
	; op de omgekeerde flank reageren
	ldi		temp, EdgeLow
	in		temp2, TCCR1B

	sbrs	temp2, ICES1
	;andi	temp2, (1<<ICES1)
	;brne	NextLow
	ldi		temp, EdgeHigh
;NextLow:
	out		TCCR1B, temp
	; vlag zetten voor markering End-Of-Capture
	ser		CaptureComplete
	;
	pop		temp
	out		SREG, temp
	pop		temp2
	pop		temp
	reti
;--------------------------------------/



;---------------------------------------
;--- Timer1 CompareA match handler
;--------------------------------------\
Timer_Interrupt_CompareA:
	push	temp
	in		temp, SREG
	push	temp

	; Als deze handler wordt aangesproken houdt dat in:
	; Het signaal is al <TimeoutValue> op een 0-niveau, een tijdstip tussen 2 packets
	SetTimeout							; de time-out vlag zetten

	; * eventueel uitvoer naar LED's en/of COM:-poort
	.ifdef Output_To_LED
		LED_On LED_Error				; Error LED aan (ongeldig)
		LED_Off LED_Bit					; Bit LED uit
	.endif
	.ifdef Output_To_COM
		ldi		temp, CHR_Timeout
		rcall	UART_transmit
	.endif
	; * Herstel de bitsreampointer in het X-register
	;ResetStream
	; * de stream is klaar om te worden afgebeeld..
	;   buiten deze handler dan.. ;)
	;rcall	BitStream_Display

	pop		temp
	out		SREG, temp
	pop		temp
	reti
;--------------------------------------/




;---------------------------------------
;--- Main Program
;--------------------------------------\
RESET:
	;-- initialisatie
	cli									; interrupts tegenhouden
	initStackPointer					; initialiseer de stack pointer
	rcall	LED_Initialize				; de LED's
	rcall	Capture_Initialize			; de signaal input pin
	rcall	BitStream_Initialize		; de bitsream ontvangst buffer
	rcall	Timer_Initialize			; de timer
	sei									; interrupts weer toelaten
	;--

	; in periode A.. of op een tijdstip tussen 2 packets
	; eerst wachten tot het een tijd (>TimeoutValue) stil is geweest op de DCC-bus..
	WaitForTimeOut
main_loop:
	ICP_OnLowEdge						; nu op een neergaande flank wachten
	.ifdef Save_To_Bitstream
		rcall	BitStream_Display		; bitstream afbeelden op COM: poort
		rcall	BitStream_Decode		; bits naar bytes
		rcall	ByteStream_Display		; BYTEstream afbeelden op COM: poort
	.endif
	rcall	BitStream_Initialize		; bitstream + timeout wissen
	WaitForTimeOut
	ICP_OnLowEdge						; nu op een neergaande flank wachten
CheckStream:
	WaitForICP
	; begin periode A
	If_Timedout_Jmp main_loop
	TestPeriode CaptureL, CaptureH		; controleer ontvangen halve bit
	WaitForICP
	; begin periode B
	If_Timedout_Jmp main_loop
	TestPeriode CaptureL, CaptureH		; controleer ontvangen halve bit
	;
	rjmp 	main_loop
;--------------------------------------/









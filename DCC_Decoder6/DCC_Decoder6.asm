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
;--- BitStream in SRAM:
;---	CHR_0      CHR_1      CHR_Error          CHR_Timeout
;---	'0'=0-bit  '1'=1-bit  '*'=ongeldige bit  ' '=pulsduur te lang/packet-end
;-------------------------------------------------------------------


;--- INCLUDE FILES --------------------\
;.nolist
.include "8535def.inc"					; AVR AT90S8535
.include "RotatingBuffer.asm"			; Ron's ring-buffer macro's
;.list
;--------------------------------------/




;--- COMPILER DIRECTIVES --------------\
.equ Output_To_COM 		= 1				; ontvangen bits uitvoeren naar de COM: poort
.equ Output_To_LED 		= 0				; ontvangen bits uitvoeren naar de LED's
.equ Save_To_Bitstream	= 0				; ontvangen bits bewaren als een stream in SRAM
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
.equ Flag_TimedOut			= 0			; bit 0 van register 'Flags' = timed out
.equ Flag_CaptureComplete	= 1			; bit 1 van register 'Flags' = capture complete
.def Flags					= R18

.def temp					= R16		; Een register voor algemeen gebruik
.def temp2					= R17		; nog 1..
.def CaptureL				= R20		; De laatste ICP-sample waarde  (low-byte)
.def CaptureH				= R21		; ^^(high-byte)
.def PreambleCount			= R19		; telling aantal sequentiele "1"-bits ontvangen
.def DataByte				= R23		; de ontvangen data-byte
;Z register								; pointer naar buffer in SRAM
;--------------------------------------/



;--- Variablelen in EEPROM ------------\
.ESEG
E_TimeOut:	.db low(TimeOutValue), high(TimeOutValue); de timeout waarde in EEPROM
;--------------------------------------/


;--- Variablelen in SRAM --------------\
.DSEG
DCCStream:	.BYTE 8						; de bitstream gedecodeerd naar een "byte-stream"
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



.MACRO SetTimeout
	ori		Flags, Flag_TimedOut
.ENDMACRO

.MACRO ClearTimeout
	andi	Flags, ~Flag_TimedOut
.ENDMACRO

.MACRO WaitForTimeOut
_0:	sbrs	Flags, Flag_TimedOut
	rjmp	_0
	ClearTimeout
.ENDMACRO

.MACRO If_Timedout_Jmp;(label)
	sbrc	Flags, Flag_TimedOut
	rjmp	@0
.ENDMACRO



.MACRO SetCaptureComplete
	ori		Flags, Flag_CaptureComplete
.ENDMACRO

.MACRO ClearCaptureComplete
	andi	Flags, ~Flag_CaptureComplete	; bitwise not
.ENDMACRO

.MACRO WaitForICP
_0:	sbrc	Flags, Flag_CaptureComplete
	rjmp	_0
	ClearCaptureComplete
.ENDMACRO

.MACRO ICP_OnLowEdge
	ldi		temp, EdgeLow
	out		TCCR1B, temp
.ENDMACRO

.MACRO ICP_OnHighEdge
	ldi		temp, EdgeHigh
	out		TCCR1B, temp
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
	.if Output_To_LED == 1
		LED_On LED_Error				; Error LED aan (ongeldig)
		LED_Off LED_Bit					; Bit LED uit
	.endif
	.if Output_To_COM == 1
		ldi		temp, CHR_Error
		;rcall	UART_transmit
_4:		sbis	USR, UDRE
		rjmp	_4
		out		UDR, temp
	.endif
	.if Save_To_Bitstream == 1
		ldi		temp, CHR_Error
		;PushBit temp
	.endif
	rjmp	_3
_0:	; een geldige "0"
	.if Output_To_LED == 1
		LED_Off LED_Error				; Error LED uit (geldig)
		LED_Off LED_Bit					; Bit LED uit ("0")
	.endif
	.if Output_To_COM == 1
		ldi		temp, CHR_0
		;rcall	UART_transmit
_5:		sbis	USR, UDRE
		rjmp	_5
		out		UDR, temp
	.endif
	.if Save_To_Bitstream == 1
		ldi		temp, CHR_0
		PushBit temp
	.endif
	rjmp	_3
_1:	; een geldige "1"
	.if Output_To_LED == 1
		LED_Off LED_Error				; Error LED uit (geldig)
		LED_On LED_Bit					; Bit LED aan ("1")
	.endif
	.if Output_To_COM == 1
		ldi		temp, CHR_1
		;rcall	UART_transmit
_6:		sbis	USR, UDRE
		rjmp	_6
		out		UDR, temp
	.endif
	.if Save_To_Bitstream == 1
		ldi		temp, CHR_1
		PushBit temp
	.endif
_3:	
.ENDMACRO





;---------------------------------------
;--- De timeout waarde (een word) lezen
;--- uit EEPROM geheugen.
;--- uitvoer: Z = gelezen word
;--------------------------------------\
ReadETimeout:
	push	R16
	push	R17
	; low byte adresseren
	ldi		ZL, LOW(E_TimeOut)
	ldi		ZH, HIGH(E_TimeOut)
	; low byte lezen
	rcall	ReadEEPROM
	mov		R17, R16					; bewaren in R17
	; high byte adresseren
	adiw	ZL, 1
	; high byte lezen
	rcall	ReadEEPROM
	mov		ZH, R16
	mov		ZL, R17
	;
	pop		R17
	pop		R16
	ret

;---------------------------------------
;--- een byte uit EEPROM geheugen lezen
;--- invoer: Z-register = adres in EEPROM
;--- uitvoer: R16 = gelezen byte
;--------------------------------------\
ReadEEPROM:
	;Write-Enable bit moet eerst 0 zijn.
	sbic	EECR, EEWE
	rjmp	ReadEEPROM
	;Het adres instellen in het EEPROM Address Register.
	;512 Bytes = > 9 bits adres (b8-0).
	out		EEARL, ZL
	out		EEARH, ZH
	;Read-Enable signaal geven
	sbi		EECR, EERE
	;byte inlezen via het EEPROM Data-Register (low-byte)
	in		R16, EEDR
	ret
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
	; ICES1: Input Capture Interrupts op opgaande flank laten genereren.
	; CTC1:  Clear TCNT on compareA match uitschakelen
	; CS12,CS11 & CS10: timer1clock-select instellen op CK/8 (0,1,0)
	ICP_OnHighEdge
	; timer1 ICP inschakelen
	; timer1 compareA match interrupt inschakelen
	; timer1 compareB match interrupt uitschakelen
	ldi		temp, (1<<TICIE1 | 1<<OCIE1A | 0<<OCIE1B)
	out		TIMSK, temp
	; Compare-A waarde instellen
	rcall	ReadETimeout				; Timeout word-waarde lezen uit EEPROM
	;ldi	ZH, high(TimeOutValue)		; Timeout waarde direct ingeven (vast)
	;ldi	ZL, low(TimeOutValue)		;
	out		OCR1AH, ZH
	out		OCR1AL, ZL
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
	; timercounter op 0
	ResetCounter
	; ICP sample bewaren
	in		CaptureL, ICR1L
	in		CaptureH, ICR1H
	; op de omgekeerde flank reageren
	ldi		temp, EdgeLow
	in		temp2, TCCR1B
	sbrs	temp2, ICES1
	ldi		temp, EdgeHigh
	out		TCCR1B, temp
	; vlag zetten voor markering End-Of-Capture
	SetCaptureComplete
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
	.if Output_To_LED == 1
		LED_On LED_Error				; Error LED aan (ongeldig)
		LED_Off LED_Bit					; Bit LED uit
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
;--- Een ontvangen DCC-packet afbeelden
;--------------------------------------\
DCCPacket_Display:
	mov		YL, ZL						; pointer naar einde buffer overnemen
	mov		YH, ZH
	; Z-register naar begin van DCC-buffer in SRAM laten wijzen
	ldi		ZL, low(DCCStream)
	ldi		ZH, high(DCCStream)
NextDCCByte:
	cp		ZL, YL
	cpc		ZH, YH
	breq	Done_DCCPacket_Display
	ld		R16, Z+
	rcall	HexByte
	rcall	UART_Space
	rjmp	NextDCCByte
Done_DCCPacket_Display:
	ret
;--------------------------------------/




;---------------------------------------
;--- Main Program
;--------------------------------------\
RESET:
	;-- initialisatie
	cli									; interrupts tegenhouden
	initStackPointer					; initialiseer de stack pointer
	rcall	UART_Initialize_Buffer
	rcall	UART_Initialize
	rcall	LED_Initialize				; de LED's
	rcall	Capture_Initialize			; de signaal input pin
	rcall	Timer_Initialize			; de timer

	;rcall	UART_transmit_InitString
	sei									; interrupts weer toelaten
	;--

	; in periode A.. of op een tijdstip tussen 2 packets
	; eerst wachten tot het een tijd (>TimeoutValue) stil is geweest op de DCC-bus..
	WaitForTimeOut
	ICP_OnHighEdge						; nu op een opgaande flank wachten
main_loop:
	ClearTimeout
	clr		PreambleCount				; preamble "1"-bits ontvangen teller
preamble:
	WaitForICP							; wacht op het seintje van de ICP-handler
	;begin periode B'
	WaitForICP
	;begin periode A

	; controleer de voorgaande periode (B')
	If_Timedout_Jmp main_loop			; timed-out?
	TestPeriode CaptureL, CaptureH		; controleer ontvangen halve bit
	; de carry-flag gezet? dan is de ontvangen bit ongeldig..
	brcs	main_loop
	; de zero-flag gezet? dan is een "0" ontvangen..
	brne	main_loop
	; de zero-flag is gewist; Er is een "1" ontvangen..
	inc		PreambleCount				; preamble ontvangen "1"-bit teller ophogen
	cpi		PreambleCount, 12			; 12 ontvangen achter elkaar?
	brlo	preamble					; nee? dan de volgende puls proberen..
	;* Er zijn 11 "1"-bits achter elkaar ontvangen; De preamble is binnen.

	; nu wachten op de packet-start-bit, een "0"-bit is dat..
packet_start_bit:
	WaitForICP
	;begin periode B
	WaitForICP
	;begin periode A

	; controleer de voorgaande periode (B)
	If_Timedout_Jmp main_loop			; timed-out?
	TestPeriode CaptureL, CaptureH		; controleer ontvangen halve bit
	; de carry-flag gezet? dan is de ontvangen bit ongeldig..
	;brcs	main_loop					; relative branch out of reach
	brcc	psb_0
	rjmp	main_loop
psb_0:
	; de zero-flag gezet? dan is een "0" ontvangen..
	brne	packet_start_bit
	;* er is een packet-start-bit ontvangen..een"0"-bit is dat..

	; Z-register naar begin van DCC-buffer in SRAM laten wijzen
	ldi		ZL, low(DCCStream)
	ldi		ZH, high(DCCStream)
data_byte:
	ldi		DataByte, 1					; eerste van de 8 bits
data_bit:
	; nu de adres-byte ontvangen..
	WaitForICP
	;begin periode B
	WaitForICP
	;begin periode A

	; controleer de voorgaande periode (B)
	If_Timedout_Jmp main_loop			; timed-out?
	TestPeriode CaptureL, CaptureH		; controleer ontvangen halve bit
	; de carry-flag gezet? dan is de ontvangen bit ongeldig..
	;brcs	main_loop					; relative branch out of reach
	brcc	db_0
	rjmp	main_loop
db_0:
	; de zero-flag gezet?, dan is een "0" ontvangen, anders een "1"..
	; zero -> carry
	sec
	breq	build_byte
	clc
build_byte:
	lsl		DataByte
	brcc	data_bit					; nog niet 8x gedaan?
	;* Er is een complete data-byte ontvangen..

	; sla de byte op in SRAM [Z]
	st		Z+, DataByte

	;* wacht nu op een data-start-bit ("0") OF  packet-end-bit ("1")
packet_end_bit:
	; nu de adres-byte ontvangen..
	WaitForICP
	;begin periode B
	WaitForICP
	;begin periode A

	; controleer de voorgaande periode (B)
	If_Timedout_Jmp main_loop			; timed-out?
	TestPeriode CaptureL, CaptureH		; controleer ontvangen halve bit
	; de carry-flag gezet? dan is de ontvangen bit ongeldig..
	;brcs	main_loop					; relative branch out of reach
	brcc	peb_0
	rjmp	main_loop
peb_0:
	; de zero-flag gezet?, dan is een "0" ontvangen, anders een "1"..
	;breq	data_byte					; relative branch out of reach
	brne	peb_1
	rjmp	data_byte
peb_1:

	;* Het DCC-packet is helemaal ontvangen..
	rcall	DCCPacket_Display

	rjmp 	main_loop
;--------------------------------------/










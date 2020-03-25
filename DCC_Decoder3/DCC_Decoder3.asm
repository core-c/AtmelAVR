;-------------------------------------------------------------------
;--- Een DCC-Zender voor de trein-modelbouw
;---
;---	Output op Pin D6 op de AT90S8535
;---	CK = 8 MHz
;---	TCK = CK /8, dus een timertick per microseconde
;---	DCC protocol: "1" duur tussen 52us - 64us, "0" duur tussen 90us - 10000us
;---	De tijd tussen 2 packets moet zijn tenminste 5 ms.
;---
;---	          __    __
;---	         |  |  |  |  |
;---	         |  |  |  |  |
;---	------+--+  +--+  +--+
;---	      .  .  .  .  .  .
;---	      .  .  .  .  .  .
;---	      ....  ....  ....		. = signaal door booster gemaakt
;---
;---	      *     *     *
;---	         ^  ^
;---	         :  :
;---	         B  A
;---
;-------------------------------------------------------------------


;--- INCLUDE FILES --------------------\
;.nolist
.include "8535def.inc"					; AVR AT90S8535
;.list
;--------------------------------------/




;--- COMPILER DIRECTIVES --------------\
.equ Output_To_COM = 0
;--------------------------------------/




;--- CONSTANTEN -----------------------\
.equ CK = 7372800						; CPU clock frequentie					; 7372800
.equ TCK = CK							; timer1 frequentie						; CK
.equ Min1 = 0.000052 * TCK				; duur van een (halve/positieve) bit (in timerticks)
.equ Max1 = 0.000064 * TCK
.equ Min0 = 0.000090 * TCK
.equ Max0 = 0.010000 * TCK
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
;--------------------------------------/




;--- REGISTER ALIASSEN ----------------\
.def temp			= R16				; Een register voor algemeen gebruik
.def temp2			= R17
;--------------------------------------/






;--- De AVR-AT90S8535 "vector"-tabel --\
.CSEG
.org $0000								; Het begin van de vector-tabel op adres 0 van het RAM
	rjmp RESET							; Reset Handler
	reti								; External Interrupt0 Vector Address
	reti								; External Interrupt1 Vector Address
	reti								; Timer2 compare match Vector Address
	reti								; Timer2 overflow Vector Address
	reti								; Timer1 Input Capture Vector Address
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
.ifdef Output_To_COM
	.include "RS232.asm"				; UART routines
.endif
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

.MACRO WaitFor1
	; wacht op de volgende omhooggaande flank..
_0:	sbis	CaptureIn, CapturePin		;
	rjmp	_0
.ENDMACRO

.MACRO ResetCounter
	; de counter op 0 instellen
	clr		temp
	out		TCNT1H, temp
	out		TCNT1L, temp
.ENDMACRO

.MACRO WaitFor0
	; wacht op de volgende omlaaggaande flank..
_0:	sbic	CaptureIn, CapturePin		;
	rjmp	_0
.ENDMACRO

.MACRO ReadCounter
	; de timercounter uitlezen in register Z
	in		ZL, TCNT1L
	in		ZH, TCNT1H
.ENDMACRO


;--- Macro TestBit
;--- invoer: Z register
;--- uitvoer: LED's
.MACRO TestBit
	; test of de bit geldig is
	; Z < Min1 ?
	cpi		ZL, low(Min1)
	ldi		temp, high(Min1)
	cpc		ZH, temp
	brlo	_2							; bit ongeldig
	; Z <= Max1 ?
	cpi		ZL, low(Max1+1)
	ldi		temp, high(Max1+1)
	cpc		ZH, temp
	brlo	_1							; geldige "1"
	; Z < Min0 ?
	cpi		ZL, low(Min0)
	ldi		temp, high(Min0)
	cpc		ZH, temp
	brlo	_2							; bit ongeldig
	; Z <= Max0 ?
	cpi		ZL, low(Max0+1)
	ldi		temp, high(Max0+1)
	cpc		ZH, temp
	brlo	_0							; geldige "0"
	rjmp	_2							; anders bit ongeldig
_0:	; een geldige "0"
	LED_Off LED_Error					; Error LED uit (geldig)
	LED_Off LED_Bit						; Bit LED uit ("0")
	.ifdef Output_To_COM
		ldi		temp, '0'
		rcall	UART_transmit
	.endif
	rjmp	_3
_1:	; een geldige "1"
	LED_Off LED_Error					; Error LED uit (geldig)
	LED_On LED_Bit						; Bit LED aan ("1")
	.ifdef Output_To_COM
		ldi		temp, '1'
		rcall	UART_transmit
	.endif
	rjmp	_3
_2:	;ongeldige bit
	LED_On LED_Error					; Error LED aan (ongeldig)
	LED_Off LED_Bit						; Bit LED uit
	.ifdef Output_To_COM
		ldi		temp, '*'
		rcall	UART_transmit
	.endif
_3:	
.ENDMACRO

.MACRO LED_Off;(LED)
	cbi		LED_Port, @0				; LED uit
.ENDMACRO

.MACRO LED_On;(LED)
	sbi		LED_Port, @0				; LED aan
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
	cbi		CaptureDDR, CapturePin		; input
	cbi		CapturePORT, CapturePin		; tri-state
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
	; ICNC1: Noise Canceler uitschakelen => input capture om elke sample/capture. (nvt nu)
	; ICES1: Input Capture Interrupts op opgaande flank laten genereren. (nvt nu)
	; CTC1:  Clear TCNT on compareA match uitschakelen
	; CS12,CS11 & CS10: timer1clock-select instellen op CK (0,0,1)
	ldi		temp, (0<<ICNC1 | 0<<ICES1 | 0<<CTC1 | 0<<CS12 | 0<<CS11 | 1<<CS10)
	out		TCCR1B, temp

	; timer1 compareA match interrupt uitschakelen
	; timer1 compareB match interrupt uitschakelen
	ldi		temp, (0<<OCIE1A | 0<<OCIE1B)
	out		TIMSK, temp

	; de counter op 0 instellen
	ResetCounter
	ret
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
	rcall	Timer_Initialize			; de timer
	sei									; interrupts weer toelaten
	;--
main_loop:
	WaitFor1							; wacht op de eerste omhooggaande flank..
	ResetCounter						; de counter op 0 instellen
	WaitFor0							; wacht op de volgende omlaaggaande flank..
	ReadCounter							; de timercounter uitlezen
	TestBit								; controleer ontvangen bit
	rjmp 	main_loop
;--------------------------------------/






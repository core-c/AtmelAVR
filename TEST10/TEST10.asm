
;*************************************************************************************
;***
;***  Hardware-matige 10-bits PWM met output op pin D4 (OC1B)
;***
;***  Onze AVR's clockspeed bedraagt 7.3728 Mhz  =  7372800 Hz
;***  De Timer1-frequentie wordt afgeleid van de clockspeed van de AVR. Deze timer-
;***  frequentie kan gedeeld worden (prescaled) om lagere frequenties te gebruiken.
;***  Alle in te stellen Timer-frequenties :
;***	clockspeed			= 7372800 Hz
;***	clockspeed / 8		= 7372800 /8	= 921600 Hz
;***	clockspeed / 64		= 7372800 /64	= 115200 Hz
;***	clockspeed / 256	= 7372800 /256	= 28800 Hz
;***	clockspeed / 1024	= 7372800 /1024	= 7200 Hz
;*** 
;***  Als de AVR in PWM-mode werkt, wordt de uiteindelijke PWM-frequentie bepaalt door
;***  de PWM-resolutie; 8-, 9- of 10-bits PWM (zie onderstaande tabel*):
;***	 8 bits PWM : PWM-frequentie = Timer-frequentie / 510
;***	 9 bits PWM : PWM-frequentie = Timer-frequentie / 1022
;***	10 bits PWM : PWM-frequentie = Timer-frequentie / 2046
;***  De PWM-resolutie bepaalt ook de TOP-waarde van de Timer-Counter :
;***	 8 bits PWM : Timer-Counter TOP =	00FF	0000000011111111	 255
;***	 9 bits PWM : Timer-Counter TOP =	01FF	0000000111111111	 511
;***	10 bits PWM : Timer-Counter TOP =	03FF	0000001111111111	1023
;***
;***
;***
;*** *AVR-CK		Prescale		Timer-CK		PWM-freqentie (8, 9 & 10-bits)
;***  _________________________________________________________________________________________
;***  7.3728 MHz					7.3728 MHz		14.45647 KHz	7.2141 KHz		3.60352 KHz
;***				/ 8				921.6  KHz		1.8071   KHz	901.76  Hz		450.44   Hz
;***				/ 64			115.2  KHz		225.88    Hz	112.72  Hz		56.30    Hz
;***				/ 256			28.8   KHz		56.47     Hz	28.18   Hz		14.08    Hz
;***				/ 1024			7.2    KHz		14.12     Hz	7.05    Hz		3.52     Hz
;***
;***
;*************************************************************************************

.include "8535def.inc"

;--- Timer frequenties -----------------
.equ TIMERFREQ_CK1024	= (1<<CS12 | 0<<CS11 | 1<<CS10)	; timerFrequentie = clock/1024 
.equ TIMERFREQ_CK256	= (1<<CS12 | 0<<CS11 | 0<<CS10)	; timerFrequentie = clock/256
.equ TIMERFREQ_CK64		= (0<<CS12 | 1<<CS11 | 1<<CS10)	; timerFrequentie = clock/64
.equ TIMERFREQ_CK8		= (0<<CS12 | 1<<CS11 | 0<<CS10)	; timerFrequentie = clock/8
.equ TIMERFREQ_CK		= (0<<CS12 | 0<<CS11 | 1<<CS10)	; timerFrequentie = clock
.equ TIMERFREQ_OFF		= (0<<CS12 | 0<<CS11 | 0<<CS10)	; timer uitschakelen


;--- PWM-modes -------------------------
; PWM11:PWM10 =>  0:0=uit, 0:1=8bits, 1:0=9bits, 1:1=10bits
.equ PWM_OFF	= (0<<PWM11  | 0<<PWM10)
.equ PWM_8BITS	= (0<<PWM11  | 1<<PWM10)
.equ PWM_9BITS	= (1<<PWM11  | 0<<PWM10)
.equ PWM_10BITS	= (1<<PWM11  | 1<<PWM10)
; COM1B1:COM1B0  =>  1:0=non inverted PWM, 1:1=inverted PWM  (bij gebruik CompareB)
.equ PWM_NON_INVERTED_1B	= (1<<COM1B1 | 0<<COM1B0)
.equ PWM_INVERTED_1B		= (1<<COM1B1 | 1<<COM1B0)
; COM1A1:COM1A0  =>  1:0=non inverted PWM, 1:1=inverted PWM  (bij gebruik CompareA)
.equ PWM_NON_INVERTED_1A	= (1<<COM1A1 | 0<<COM1A0)
.equ PWM_INVERTED_1A		= (1<<COM1A1 | 1<<COM1A0)
;
.equ PWM_8BITS_NON_INVERTED_1B	= (PWM_8BITS  | PWM_NON_INVERTED_1B)
.equ PWM_9BITS_NON_INVERTED_1B	= (PWM_9BITS  | PWM_NON_INVERTED_1B)
.equ PWM_10BITS_NON_INVERTED_1B	= (PWM_10BITS | PWM_NON_INVERTED_1B)
.equ PWM_8BITS_INVERTED_1B		= (PWM_8BITS  | PWM_INVERTED_1B)
.equ PWM_9BITS_INVERTED_1B		= (PWM_9BITS  | PWM_INVERTED_1B)
.equ PWM_10BITS_INVERTED_1B		= (PWM_10BITS | PWM_INVERTED_1B)
;
.equ PWM_8BITS_NON_INVERTED_1A	= (PWM_8BITS  | PWM_NON_INVERTED_1A)
.equ PWM_9BITS_NON_INVERTED_1A	= (PWM_9BITS  | PWM_NON_INVERTED_1A)
.equ PWM_10BITS_NON_INVERTED_1A	= (PWM_10BITS | PWM_NON_INVERTED_1A)
.equ PWM_8BITS_INVERTED_1A		= (PWM_8BITS  | PWM_INVERTED_1A)
.equ PWM_9BITS_INVERTED_1A		= (PWM_9BITS  | PWM_INVERTED_1A)
.equ PWM_10BITS_INVERTED_1A		= (PWM_10BITS | PWM_INVERTED_1A)
;
.equ PWM_8BITS_TOP	= 0b11111111		; De TOP-waarde voor 8-bits = 2^8 - 1
.equ PWM_9BITS_TOP	= 0b111111111		; De TOP-waarde voor 9-bits = 2^9 - 1
.equ PWM_10BITS_TOP	= 0b1111111111		; De TOP-waarde voor 10-bits = 2^10 - 1
;---------------------------------------



;--- De timer1 TOP-waarde --------------
.equ TOP			= PWM_10BITS_TOP

; De te gebruiken duty-cycle (in procenten)
.equ DUTY_CYCLE		= 10

;--- De timer1 COMPARE-waarde ----------
;.equ COMPARE		= TOP				; duty-cycle 100%
;.equ COMPARE		= TOP/10*9			; duty-cycle 90%
;.equ COMPARE		= TOP/10*8			; duty-cycle 80%
;.equ COMPARE		= TOP/10*7			; duty-cycle 70%
;.equ COMPARE		= TOP/10*6			; duty-cycle 60%
;.equ COMPARE		= ((TOP+1)/2)-1		; duty-cycle 50%
;.equ COMPARE		= TOP/10*4			; duty-cycle 40%
;.equ COMPARE		= TOP/10*3			; duty-cycle 30%
;.equ COMPARE		= TOP/10*2			; duty-cycle 20%
;.equ COMPARE		= TOP/10*1			; duty-cycle 10%
.equ COMPARE		= TOP/100*DUTY_CYCLE


;--- Register synoniemen ---------------
.def temp	= R16
.def tempL	= R17




;--- Macro's ---------------------------
.MACRO SET_STACKPOINTER
	ldi		temp, high(RAMEND)
	ldi		tempL, low(RAMEND)
	out		SPH, temp
	out		SPL, tempL
.ENDMACRO

.MACRO SET_PIN_AS_OUTPUT;(Poort: byte; Pin : bit-nummer)
	; Éen bit van een poort als output zetten
	clr		temp
	ori		temp, (1<<@1)				; argument(1) is de Pin
	out		@0, temp					; argument(0) is de Poort
.ENDMACRO

.MACRO SET_PINS_AS_OUTPUT;(Poort: byte; Pins : byte-mask)
	clr		temp
	ori		temp, @1					; argument(1) is de Pin-mask
	out		@0, temp					; argument(0) is de Poort
.ENDMACRO

.MACRO SET_LEDS;(Poort: byte; Pins : byte-mask)
	ldi		temp, @1
	out		@0, temp
.ENDMACRO

.MACRO SET_PWM_DUTYCYCLE_1B;(CompareB-waarde : word)
	ldi		temp, high(@0)				; argument(0)
	ldi		tempL, low(@0)
	out		OCR1BH, temp
	out		OCR1BL, tempL
.ENDMACRO

.MACRO SET_TIMER1_PWM_MODE;(PWM-mode : byte)
	ldi		temp, @0
	out		TCCR1A, temp 
.ENDMACRO

.MACRO SET_TIMER1FREQ;(frequentie : byte)
	ldi		temp, @0
	out		TCCR1B, temp
.ENDMACRO

.MACRO MAIN_LOOP
eLoop:
	rjmp eLoop
.ENDMACRO





; Het begin van het CODE-segment
.cseg
;--- De vector-tabel -------------------
.org 0x0000								; Het begin van de vector-tabel op adres 0 van het RAM
	rjmp RESET							; Reset Handler
	reti								;External Interrupt0 Vector Address
	reti								;External Interrupt1 Vector Address
	reti								;Timer2 compare match Vector Address
	reti								;Timer2 overflow Vector Address
	reti								;Timer1 Input Capture Vector Address
	reti								;Timer1 Output Compare A Interrupt Vector Address
	reti								;Timer1 Output Compare B Interrupt Vector Address
	reti								;Overflow1 Interrupt Vector Address
	reti								;Overflow0 Interrupt Vector Address
	reti								;SPI Interrupt Vector Address
	reti								;UART Receive Complete Interrupt Vector Address
	reti								;UART Data Register Empty Interrupt Vector Address
	reti								;UART Transmit Complete Interrupt Vector Address
	reti								;ADC Conversion Complete Interrupt Vector Address
	reti								;EEPROM Write Complete Interrupt Vector Address
	reti								;Analog Comparator Interrupt Vector Address
;---------------------------------------




RESET:
	; interrupts uitschakelen tijdens opnieuw instellen van de AVR
	cli
	; De stack-pointer instellen op het einde van het RAM
	SET_STACKPOINTER

	;nog even wat LED's aanzetten ter indicatie dat de AVR runt.
	SET_PINS_AS_OUTPUT DDRC, (1<<PINC2 | 1<<PINC1 | 1<<PINC0)
	; alle 3 aan bij 10-bits PWM
	SET_LEDS PORTC, (1<<PINC2 | 1<<PINC1 | 1<<PINC0)


	; poort D pin 4 (OC1B) als output zetten voor de PWM output-pin
	SET_PIN_AS_OUTPUT DDRD, PIND4

	; De duty-cycle instellen op een 16-bit waarde
	SET_PWM_DUTYCYCLE_1B COMPARE

	; PWM-mode inschakelen op non inverted PWM:
	SET_TIMER1_PWM_MODE PWM_10BITS_NON_INVERTED_1B

	; Timer1 clock instellen.
	SET_TIMER1FREQ TIMERFREQ_CK1024
;	SET_TIMER1FREQ TIMERFREQ_CK256
;	SET_TIMER1FREQ TIMERFREQ_CK64
;	SET_TIMER1FREQ TIMERFREQ_CK8
;	SET_TIMER1FREQ TIMERFREQ_CK


	; interrupts weer inschakelen
	sei

	MAIN_LOOP


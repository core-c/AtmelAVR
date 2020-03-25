
;*************************************************************************************
;***
;***  Hardware-matige 8-bits PWM met output op pin D4 (OC1B)
;***
;***  Onze AVR's clockspeed bedraagt 7.3728 Mhz  =  7372800 Hz
;***  De Timer1-frequentie wordt afgeleid van de clockspeed van de AVR. Deze timer-
;***  frequentie kan gedeeld worden (prescaled) om lagere frequenties te gebruiken.
;***  Alle in te stellen timer-frequenties :
;***	clockspeed			= 7372800 Hz
;***	clockspeed / 8		= 7372800 /8	= 921600 Hz
;***	clockspeed / 64		= 7372800 /64	= 115200 Hz
;***	clockspeed / 256	= 7372800 /256	= 28800 Hz
;***	clockspeed / 1024	= 7372800 /1024	= 7200 Hz
;*** 
;***  Als de AVR in PWM-mode werkt, wordt de uiteindelijke PWM-frequentie bepaalt door
;***  de PWM-resolutie; 8-, 9- of 10-bits PWM :
;***	 8 bits PWM : PWM-frequentie = Timer-frequentie / 510
;***	 9 bits PWM : PWM-frequentie = Timer-frequentie / 1022
;***	10 bits PWM : PWM-frequentie = Timer-frequentie / 2046
;***  De PWM-resolutie bepaalt ook de TOP-waarde van de Timer-Counter :
;***	 8 bits PWM : Timer-Counter TOP =	00FF	0000000011111111	 255
;***	 9 bits PWM : Timer-Counter TOP =	01FF	0000000111111111	 511
;***	10 bits PWM : Timer-Counter TOP =	03FF	0000001111111111	1023
;***
;*************************************************************************************

.include "8535def.inc"


; De timer1 TOP-waarde
.equ TOP			= 255				; De TOP-waarde voor een 8-bits timer = 2^8 - 1
.equ TOP_high		= high(TOP)			; De MSB van TOP (de hoogste 8 bits)
.equ TOP_low		= low(TOP)			; De LSB van TOP (de laagste 8 bits)
; De timer1 COMPARE-waarde
.equ COMPARE		= ((TOP+1)/2)-1		; duty-cycle 50%
;.equ COMPARE		= 1					; duty-cycle minimaal
.equ COMPARE_high	= high(COMPARE)
.equ COMPARE_low	= low(COMPARE)

; Register synoniemen
.def temp	= R16
.def tempL	= R17


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
	; interrupts uitschakelen
	cli
	; De stack-pointer instellen op het einde van het RAM
	ldi		temp, high(RAMEND)
	ldi		tempL, low(RAMEND)
	out		SPH, temp
	out		SPL, tempL

	;nog even een LED aanzetten ter indicatie dat de AVR runt.
	clr		temp
	out		PORTC, temp
	ldi		temp, (0<<PINC2 | 0<<PINC1 | 1<<PINC0)
	out		DDRC, temp
	ldi		temp, (0<<PINC2 | 0<<PINC1 | 1<<PINC0)
	out		PORTC, temp					; 1 LED aan bij 8-bits PWM


	; poort D als output zetten voor de PWM output-pin
	clr		temp
	ori		temp, (1<<PIND4)
	out		DDRD, temp

	; De duty-cycle instellen op 50%
	ldi		temp, COMPARE_high
	ldi		tempL, COMPARE_low			; duty cycle van 50%
	out		OCR1BH, temp
	out		OCR1BL, tempL

	; PWM-mode inschakelen
	; PWM11:PWM10 =>  0:0=uit, 0:1=8bits, 1:0=9bits, 1:1=10bits
	; COM1B1:COM1B00  =>  1:0=non inverted PWM, 1:1=inverted PWM
	; 
	; COM1B1:COM1B0 moet ingesteld op non inverted PWM:
	ldi		temp, (1<<COM1B1 | 0<<COM1B0 | 0<<PWM11 | 1<<PWM10)
	out		TCCR1A, temp 

	; Timer1 clock op Clock/1024
;	ldi		temp, (1<<CS12 | 0<<CS11 | 1<<CS10)	; clock/1024
;	ldi		temp, (1<<CS12 | 0<<CS11 | 0<<CS10)	; clock/256
;	ldi		temp, (0<<CS12 | 1<<CS11 | 1<<CS10)	; clock/64
;	ldi		temp, (0<<CS12 | 1<<CS11 | 0<<CS10)	; clock/8
	ldi		temp, (0<<CS12 | 0<<CS11 | 1<<CS10)	; clock
	out		TCCR1B, temp

	; interrupts uitschakelen
	sei
eLoop:
	rjmp eLoop

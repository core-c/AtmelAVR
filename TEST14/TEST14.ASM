
;*************************************************************************************
;***
;***  Hardware-matige 8-bits PWM (Timer2) met output op pin D7 (OC2)
;***
;*************************************************************************************

.include "8535def.inc"


; De timer1 TOP-waarde
.equ TOP			= 255				; De TOP-waarde voor een 8-bits timer = 2^8 - 1
; De timer1 COMPARE-waarde
.equ COMPARE		= 128				; duty-cycle 50%

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
	ldi		temp, (1<<PC3 | 1<<PC2 | 1<<PC1 | 1<<PC0)
	out		DDRC, temp
	ldi		temp, (1<<PC3 | 0<<PC2 | 0<<PC1 | 0<<PC0)
	out		PORTC, temp					; 1 LED aan bij 8-bits PWM


	; poort D als output zetten voor de PWM output-pin
	ldi		temp, (1<<PD7)
	out		DDRD, temp

	; De duty-cycle instellen
	ldi		temp, COMPARE
	out		OCR2, temp

	; Timer2-counter op 0
	clr		temp
	out		TCNT2, temp

	; Timer1 clock instellen,
	; PWM-mode inschakelen:   PWM2 => 0=uit, 1=8bits
	; COM21:COM20  =>  1:0=non inverted PWM, 1:1=inverted PWM
	ldi		temp, (1<<PWM2 | 1<<COM21 | 0<<COM20 | 0<<CS22 | 0<<CS21 | 1<<CS20)
	out		TCCR2, temp

	; interrupts inschakelen
	sei
eLoop:
	rjmp eLoop


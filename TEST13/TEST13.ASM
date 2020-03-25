
;*************************************************************************************
;***
;***  Software-matige 8-bits PWM (Timer2) met output op pin D7 (OC2)
;***
;***    De PWM-frequentie wordt: de prescaled Timer2-Clock / 256
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
	rjmp Timer2_Compare					;Timer2 compare match Vector Address
	rjmp Timer2_Overflow				;Timer2 overflow Vector Address
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
	; nog even een LED aanzetten ter indicatie dat de AVR runt.
	ldi		temp, (1<<PC3 | 1<<PC2 | 1<<PC1 | 1<<PC0)
	out		DDRC, temp
	ldi		temp, (1<<PC3 | 0<<PC2 | 0<<PC1 | 0<<PC0)
	out		PORTC, temp					; 1 LED aan bij 8-bits PWM


	; De interrupts voor Overflow & Compare-Match inschakelen
	ldi		temp, (1<<OCIE2 | 1<<TOIE2)
	out		TIMSK, temp

	; poort D als output zetten voor de PWM output-pin
	sbi		DDRD, PD7

	; De duty-cycle instellen
	ldi		temp, COMPARE
	out		OCR2, temp

	; Timer2-counter op de TOP instellen,
	; zodat direct een puls gestart wordt.
	ser		temp
	out		TCNT2, temp

	; Timer2 instellen en starten,
	; Hardware PWM-mode uitschakelen:   PWM2 => 0=uit, 1=8bits
	ldi		temp, (0<<PWM2 | 0<<CS22 | 0<<CS21 | 1<<CS20)
	out		TCCR2, temp

	; interrupts inschakelen
	sei
eLoop:
	rjmp eLoop






;---------------------------------------
;- De Timer2-Overflow Interrupt-Handler
;---------------------------------------
Timer2_Overflow:
	; Als de timer-counter de TOP bereikt heeft,
	; wordt een Overflow-interrupt gegenereerd.
	;
	; De uitgang van het PWM-signaal hoog maken
	; bij de start van een nieuwe puls.
	sbi		PORTD, PD7
	reti






;---------------------------------------
;- De Timer2-Compare Interrupt-Handler
;---------------------------------------
Timer2_Compare:
	; Als de timer-counter = OCR2,
	; wordt een Comnpare-interrupt gegenereerd.
	;
	; De uitgang van het PWM-signaal laag maken
	; bij het einde van een puls.
	cbi		PORTD, PD7
	reti

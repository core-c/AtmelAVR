
;*******************************************************************************
;*** 8 bit PWM. 16-bit timer1 (met Overflow- & Compare-Interrupts.)
;***
;*** Onze AVR-AT90S8535 draait op een clock-frequentie van 7.3728MHz
;*** De Clock-frequentie wordt gedeeld door 510 bij gebruik van 8-bit PWM.
;*** De timer zal dus draaien op 7.3728MHz / 510 = 14.456471 KHz
;*** Bij gebruik van een evt. prescaler zijn de timer-frequenties:
;***
;*** CK/8    = 1.8070 KHz
;*** CK/64   = 225.882 Hz
;*** CK/256  = 56.471 Hz
;*** CK/1024 = 14.118 Hz
;***
;*******************************************************************************
;
.include "8535def.inc"

; De timer1 TOP-waarde
.equ TOP			= 255					; De TOP-waarde voor een 8-bits timer = 2^8 - 1
.equ TOP_high		= high(TOP)			; De MSB van TOP (de hoogste 8 bits)
.equ TOP_low		= low(TOP)			; De LSB van TOP (de laagste 8 bits)
; De timer1 COMPARE-waarde
.equ COMPARE		= 127
.equ COMPARE_high	= high(COMPARE)
.equ COMPARE_low	= low(COMPARE)


.def temp		= R17					; Een register voor algemeen gebruik
.def tempL		= R18					; Een register voor algemeen gebruik
.def status		= R19					; De status-register backup.



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








;--- Het begin van de App Main Loop --------------------------------------------
RESET:
	; Interrupts inschakelen
	cli
	; De stack-pointer instellen op het einde van het RAM
	ldi		temp, high(RAMEND)
	ldi		tempL, low(RAMEND)
	out		SPH, temp
	out		SPL, tempL


	;--- De 16-bit timer1 op PWM-mode instellen ---------------------------------------------------------
	; Port D pin 5 (OC1A) op output instellen, want deze pin zal het PWM-signaal leveren.
	clr		temp
	out		PORTD, temp					;poort D pin 5 als output
	ori		temp, (1<<PIND5)
	out		DDRD, temp

	; 8-bits PWM op Timer1
	; De 16-bit counter instellen over 2 8-bit registers.
	; De hoogste teller-waarde met 8-bit PWM is $FF; Deze waarde representeerd een 100% PWM duty-cycle.
;	in		temp, TCCR1A				;
;	andi	temp, 0b00111100			;
;	ori		temp, (1<<PWM10)			; 8-bits PWM  (max.counter waarde => $FF)
;	ori		temp, (1<<COM1A1)			; Als registerpaar OCR1H:OCR1L = 0  dan is Pin OC1A  laag
										; Als registerpaar OCR1H:OCR1L = TOP  dan is Pin OC1A hoog
	ldi		temp, (1<<COM1A1 | 1<<COM1A0 | 1<<PWM10)
	out		TCCR1A, temp

	; De te gebruiken timer-clock instellen
	in		temp, TCCR1B				; bits[0..2] bepalen de gebruikte timer-clock
	andi	temp, 0b11111000			; CTC1 op 1 om timer-counter op 0 te zetten na een compare-match
	ori		temp, (0<<CS12 | 0<<CS11 | 1<<CS10)	; bits[0..2] instellen op Clock
	out		TCCR1B, temp

	; De 16-bit compare-registers instellen op een 50% PWM duty-cycle
	; Voor een 50% PWM duty-cycle gebruiken we de helft van deze waarde $FF.
	; Als er een compare-IRQ plaatstvindt, kan pin PD5 ge-toggled worden (indien zo ingesteld)
	ldi		temp, COMPARE_high
	ldi		tempL, COMPARE_low
	out		OCR1AH, temp
	out		OCR1AL, tempL

;	ldi		temp, TOP_high
;	ldi		tempL, TOP_low
;	out		OCR1BH, temp
;	out		OCR1BL, tempL

	; De teller op 0, zodat direct een puls zal starten
	ldi		temp, 0
	ldi		tempL, 0
	out		TCNT1H, temp
	out		TCNT1L, tempL

	; De Timer1-Overflow & -compare inschakelen,
	; In PWM-mode wordt deze IRQ gegenereerd als de timer (up/down)PWM-telling door $0000 gaat met tellen.
	; De Timer1-CompareA inschakelen,
	; Een compare-IRQ vindt plaats als de timer-PWM-telling gelijk is aan de waarde in het OCR1A regsiter.
;	in		temp, TIFR					; Het Timer-Interrupt-Flag-Register aanspreken
;	andi	temp, 0b11101011			; alleen bits 2 & 4 aanpassen
;	ori		temp, (1<<TOV1)				; bit 2 zetten (TOV1 - Timer1-Overflow)
;	ori		temp, (1<<OCF1A)			; bit 4 aanzetten (OCF1A - Timer1-CompareA)
;	out		TIFR, temp

	; Het Timer-Interrupt-Mask-Register instellen
;	in		temp, TIMSK					; Het Timer-Interrupt-Mask-Register aanspreken
;	andi	temp, 0b11101011			; alleen bits 2 & 4 aanpassen
;	ori		temp, (1<<TOIE1)			; bit 2 zetten (TOIE1 - Timer1-Overflow-Interrupt-Enabled)
;	ori		temp, (1<<OCIE1A)			; bit 4 aanzetten (OCIE1A - Timer1-compareA-Interrupt-Enabled)
;	out		TIMSK, temp
	ldi		temp, 0
	out		TIFR, temp
	ldi		temp, 0
	out		TIMSK, temp

	; Interrupts inschakelen
	sei
	;----------------------------------------------------------------------------------------------------
eloop:
	rjmp	eloop						; een eeuwige lus....










;--- De Timer1-Overflow Interrupt routine --------------------------------------
Timer_Interrupt_Overflow:
	in		status, SREG
	; pin D5 op 1
;	sbi		PORTD, PIND5
	out		SREG, status
	reti








;--- De Timer-Compare-A Interrupt routine --------------------------------------
Timer_Interrupt_CompareA:
	in		status, SREG
	; pin D5 op 0
;	cbi		PORTD, PIND5
	; counter op 0??;
;	ldi		temp, 0;TOP_high
;	ldi		tempL, 0;TOP_low-1
;	out		TCNT1H, temp
;	out		TCNT1L, tempL
	out		SREG, status
	reti

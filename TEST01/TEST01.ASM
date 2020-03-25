
;*******************************************************************************
;*** 10 bit PWM. 16-bit timer1 met Overflow- & Compare-Interrupts.
;***
;*** Onze AVR-AT90S8535 draait op een clock-frequentie van 7.3728MHz
;*** De Clock-frequentie wordt gedeeld door 2046 bij gebruik van 10-bit PWM.
;*** De timer zal dus draaien op 7.3728MHz / 2046 = 7.200KHz
;*******************************************************************************
;
.include "8535def.inc"


.def temp		= R17					; Een register voor algemeen gebruik
.def tempL		= R18					; Een register voor algemeen gebruik




; Het begin van het CODE-segment
.cseg
;--- De vector-tabel -------------------
.org 0x0000								; Het begin van de vector-tabel op adres 0 van het RAM
	rjmp RESET							; Reset Handler
	reti								; IRQ0 Handler
	reti								; IRQ1 Handler
	reti								; Timer1 Capture Handler
	rjmp Timer_Interrupt_CompareA		; Timer1 compare Handler
	rjmp Timer_Interrupt_Overflow		; Timer1 Overflow Handler
	reti								; Timer0 Overflow Handler
	reti								; SPI Transfer Complete Handler
	reti								; UART RX Complete Handler
	reti								; UDR Empty Handler
	reti								; UART TX Complete Handler
	reti								; ADC Conversion Complete Interrupt Handler
	reti								; EEPROM Ready Handler
	reti								; Analog Comparator Handler
;---------------------------------------








;--- Het begin van de App Main Loop --------------------------------------------
RESET:
	; De stack-pointer instellen op het einde van het RAM
	ldi		temp, high(RAMEND)
	ldi		tempL, low(RAMEND)
	out		SPH, temp
	out		SPL, tempL


	;--- De 16-bit timer1 op PWM-mode instellen ---------------------------------------------------------
	; Port D pin 5 (OC1A) op output instellen, want deze pin zal het PWM-signaal leveren.
	in		temp, DDRD
	andi	temp, 0b11011111
	ori		temp, PIND5
	out		DDRD, temp

	; Bij 10-bits PWM instellen
	in		temp, TCCR1A				;
	andi	temp, 0b00111100			;
	ori		temp, (1<<PWM11 | 1<<PWM10)	; 10-bits PWM  (max.counter waarde => $3FF)
	ori		temp, (1<<COM1A0 | 1<<COM1A1)	; toggle output pin (PD5) bij elke timer-interrupt (inverted PWM)
	out		TCCR1A, temp

	; De te gebruiken timer-clock instellen
	in		temp, TCCR1B				; bits[0..2] bepalen de gebruikte timer-clock
	andi	temp, 0b11111000			;
	ori		temp, (1<<CS22 | 1<<CS20)	; bits[0..2] instellen op Clock/1024
	out		TCCR1B, temp

	; De 16-bit counter instellen over 2 8-bit registers.
	; De hoogste teller-waarde met 10-bit PWM is $3FF; Deze waarde representeerd een 100% PWM duty-cycle.
	ldi		temp, $03
	ldi		tempL, $FF
	out		TCNT1H, temp
	out		TCNT1L, tempL

	; De 16-bit compare-registers instellen op een 50% PWM duty-cycle
	; Voor een 50% PWM duty-cycle gebruiken we de helft van deze waarde $1FF.
	; Als er een compare-IRQ plaatstvindt, kan pin PD5 ge-toggled worden (indien zo ingesteld)
	ldi		temp, $01
	ldi		tempL, $FF
	out		OCR1AH, temp
	out		OCR1AL, tempL

	; De Timer1-Overflow inschakelen,
	; In PWM-mode wordt deze IRQ gegenereerd als de timer (up/down)PWM-telling door $0000 gaat met tellen.
	; De Timer1-CompareA inschakelen,
	; Een compare-IRQ vindt plaats als de timer-PWM-telling gelijk is aan de waarde in het OCR1A regsiter.
	in		temp, TIFR					; Het Timer-Interrupt-Flag-Register aanspreken
	andi	temp, 0b11101011			; alleen bits 2 & 4 aanpassen
	ori		temp, (1<<TOV1)				; bit 2 zetten (TOV1 - Timer1-Overflow)
	ori		temp, (1<<OCF1A)				; bit 4 aanzetten (OCF1A - Timer1-CompareA)
	out		TIFR, temp

	; Het Timer-Interrupt-Mask-Register instellen
	in		temp, TIMSK					; Het Timer-Interrupt-Mask-Register aanspreken
	andi	temp, 0b11101011			; alleen bits 2 & 4 aanpassen
	ori		temp, (1<<TOIE1)			; bit 2 zetten (TOIE1 - Timer1-Overflow-Interrupt-Enabled)
	ori		temp, (1<<OCIE1A)			; bit 4 aanzetten (OCIE1A - Timer1-compareA-Interrupt-Enabled)
	out		TIMSK, temp

	; Interrupts inschakelen
	sei
	;----------------------------------------------------------------------------------------------------
eloop:
	rjmp	eloop						; een eeuwige lus....










;--- De Timer1-Overflow Interrupt routine --------------------------------------
Timer_Interrupt_Overflow:
	reti








;--- De Timer-Compare-A Interrupt routine --------------------------------------
Timer_Interrupt_CompareA:
	reti

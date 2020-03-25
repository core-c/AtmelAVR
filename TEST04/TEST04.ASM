
;********************************************************************************
;***
;***  Een implementatie voor aansturing van de UART.
;***    Ervan uitgaand dat onze AVR op een clockfrequentie van 7.3728MHz draait.
;***
;********************************************************************************


.include "8535def.inc"

; Mijn constanten
.def temp		= R17					; Een register voor algemeen gebruik
.def tempL		= R18					; Een register voor algemeen gebruik
.def lastRead	= R19					; De laatst gelezen/ontvangen byte van de UART





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
	rjmp Timer_Interrupt_CompareA		;Timer1 Output Compare A Interrupt Vector Address
	reti								;Timer1 Output Compare B Interrupt Vector Address
	rjmp Timer_Interrupt_Overflow		;Overflow1 Interrupt Vector Address
	reti								;Overflow0 Interrupt Vector Address
	reti								;SPI Interrupt Vector Address
	rjmp UART_Rx_Interrupt				;UART Receive Complete Interrupt Vector Address
	reti								;UART Data Register Empty Interrupt Vector Address
	reti								;UART Transmit Complete Interrupt Vector Address
	reti								;ADC Conversion Complete Interrupt Vector Address
	reti								;EEPROM Write Complete Interrupt Vector Address
	reti								;Analog Comparator Interrupt Vector Address
;---------------------------------------





;------------------------------------------
;--- De Timer1-Overflow Interrupt-Handler
;------------------------------------------
Timer_Interrupt_Overflow:
	reti



;------------------------------------------
;--- De Timer1-Compare-A Interrupt-Handler
;------------------------------------------
Timer_Interrupt_CompareA:
	reti










;------------------------------------------
;--- De UART Receive Interrupt-Handler
;------------------------------------------
UART_Rx_Interrupt:
	push	temp
	
	in		lastRead, UDR
	;mov	temp, lastRead
	;rcall	transmit

	; Timer1-CompareA waarde instellen (PWM puls breedte)
	ldi		temp, $00
	mov		tempL, lastRead
	out		OCR1AH, temp
	out		OCR1AL, tempL

	pop		temp
	reti



;------------------------------------------
;--- Initialiseer de UART. (subroutine)
;---
;--- De te gebruiken baudrate moet tevoren
;--- in register 'temp' worden aangereikt.
;------------------------------------------
UART_Initialize:
	out		UBRR, temp
	;Schakel de receiver, transmitter & TXCint in
	ldi		temp, (1<<RXEN) | (1<<TXEN) | (1<<RXCIE)
	out		UCR, temp
	ret



;------------------------------------------
;--- UART: Verzend een byte. (subroutine)
;---
;--- De te verzenden byte tevoren in
;--- register 'temp' laden.
;------------------------------------------
UART_transmit:
	; Klaar om te verzenden ??
	sbis	USR, UDRE
	rjmp	UART_transmit
	out		UDR, temp
	ret









;------------------------------------------
;--- Het begin van de programma uitvoer.
;------------------------------------------
RESET:
	; De stack-pointer instellen op het einde van het RAM
	ldi		temp, high(RAMEND)
	ldi		tempL, low(RAMEND)
	out		SPH, temp
	out		SPL, tempL



	;--- De 16-bit timer1 op PWM-mode instellen ---------------------------------------------------------
	; Port D pin 5 (OC1A) op output instellen, want deze pin zal het PWM-signaal leveren.
	in		temp, DDRD
	;andi	temp, 0b11011111
	ori		temp, (1<<PIND5)
	out		DDRD, temp

	; Bij 10-bits PWM loopt de Timer1 op Clock/2046 = 7.324MHz / 2046 = 3579.6676Hz
	in		temp, TCCR1A				;
	andi	temp, 0b00111100			;
	ori		temp, (1<<PWM10)			; 8-bits PWM  (max.counter waarde => $FF)
	ori		temp, (1<<COM1A0 | 1<<COM1A1)	; toggle output pin (PD5) bij elke timer-interrupt (inverted PWM)
	out		TCCR1A, temp

	; De te gebruiken timer-clock instellen
	in		temp, TCCR1B				; bits[0..2] bepalen de gebruikte timer-clock
	andi	temp, 0b11111000			;
	ori		temp, (1<<CS22 | 1<<CS20)	; bits[0..2] instellen op Clock/1024
	out		TCCR1B, temp

	; De 16-bit counter instellen over 2 8-bit registers.
	; De hoogste teller-waarde met 8-bit PWM is $FF; Deze waarde representeerd een 100% PWM duty-cycle.
	ldi		temp, $00
	ldi		tempL, $FF
	out		TCNT1H, temp
	out		TCNT1L, tempL

	; De 16-bit compare-registers instellen op een 50% PWM duty-cycle
	; Voor een 50% PWM duty-cycle gebruiken we de helft van deze waarde $FF.
	; Als er een compare-IRQ plaatstvindt, kan pin PD5 ge-toggled worden (indien zo ingesteld)
	ldi		temp, $00
	ldi		tempL, $80
	out		OCR1AH, temp
	out		OCR1AL, tempL

	; De Timer1-Overflow inschakelen,
	; In PWM-mode wordt deze IRQ gegenereerd als de timer (up/down)PWM-telling door $0000 gaat met tellen.
	; De Timer1-CompareA inschakelen,
	; Een compare-IRQ vindt plaats als de timer-PWM-telling gelijk is aan de waarde in het OCR1A regsiter.
	in		temp, TIFR					; Het Timer-Interrupt-Flag-Register aanspreken
	andi	temp, 0b11101011			; alleen bits 2 & 4 aanpassen
	ori		temp, (1<<TOV1)				; bit 2 zetten (TOV1 - Timer1-Overflow)
	ori		temp, (1<<OCF1A)			; bit 4 aanzetten (OCF1A - Timer1-CompareA)
	out		TIFR, temp

	; Het Timer-Interrupt-Mask-Register instellen
	in		temp, TIMSK					; Het Timer-Interrupt-Mask-Register aanspreken
	andi	temp, 0b11101011			; alleen bits 2 & 4 aanpassen
	ori		temp, (1<<TOIE1)			; bit 2 zetten (TOIE1 - Timer1-Overflow-Interrupt-Enabled)
	ori		temp, (1<<OCIE1A)			; bit 4 aanzetten (OCIE1A - Timer1-compareA-Interrupt-Enabled)
	out		TIMSK, temp





	; De baudrate instellen op 19200@7.3728MHz  met een afwijking van 0.0%
	ldi		temp, 23
	rcall	UART_Initialize




	; globale interrupts inschakelen
	sei

	; Een eeuwige lus....
eloop:
	rjmp eloop


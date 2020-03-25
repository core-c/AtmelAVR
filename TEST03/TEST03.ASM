
;********************************************************************************
;***
;***  Een implementatie voor aansturing van de UART.
;***    Ervan uitgaand dat onze AVR op een clockfrequentie van 7.324MHz draait.
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
	reti								;Timer1 Output Compare A Interrupt Vector Address
	reti								;Timer1 Output Compare B Interrupt Vector Address
	reti								;Overflow1 Interrupt Vector Address
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
;--- De UART Receive Interrupt-Handler
;------------------------------------------
UART_Rx_Interrupt:
	in		lastRead, UDR
	;mov	temp, lastRead
	;rcall	transmit
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
	; globale interrupts inschakelen
	sei
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

	; De baudrate instellen op 19200@7.324MHz  met een afwijking van ~1.5%
	ldi		temp, 24
	rcall	UART_Initialize


	; Een eeuwige lus....
eloop:
	rjmp eloop

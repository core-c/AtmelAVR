
;--- Includes -------------------------\
.include "8535def.inc"					; AT90S8535
;--------------------------------------/

;--- FLASH/PROGRAM.
;--- De AVR-AT90S8535 Interrupt"vector" tabel
;--------------------------------------\
.CSEG                      				; het code-segment aanspreken
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

;--- Subroutines ----------------------\
.include "LED.asm"						; De LED sub-routine's
.include "LCD_8.asm"					; De LCD sub-routine's
.include "I2C.asm"						; De I2C sub-routine's ZONDER interrupt-handlers
;--------------------------------------/


RESET:
	cli									; interrupts blokkeren
	
	ldi		R16, high(RAMEND)			; De stack-pointer instellen op het einde van het RAM
	ldi		R17, low(RAMEND)
	out		SPH, R16
	out		SPL, R17

	rcall	LED_Initialize				; LED's & LCD initialiseren
	rcall	LCD_Initialize
	LED_Aan LED_Running

	rcall	TWI_initialize				; De I2C-bus initialiseren

	sei									; interrupts weer toelaten

main:	
	rcall	HandleTransaction			; een bus-transactie afhandelen
	rjmp	main						;



;**** Includes ****
.include "8535def.inc"
;include "RotatingBuffer.asm"			; Mijn roterende buffer in SRAM Macro-setje

;---------------------------------------
;--- FLASH/PROGRAM.
;--- De AVR-AT90S8535 Interrupt"vector" tabel
;--------------------------------------\
.CSEG                      				; het code-segment aanspreken
.org $0000								; Het begin van de vector-tabel op adres 0 van het RAM
	rjmp RESET							; Reset Handler
	rjmp EXT_INT0						; External Interrupt0 Vector Address
	reti								; External Interrupt1 Vector Address
	reti								; Timer2 compare match Vector Address
	reti								; Timer2 overflow Vector Address
	reti								; Timer1 Input Capture Vector Address
	reti								; Timer1 Output Compare A Interrupt Vector Address
	reti								; Timer1 Output Compare B Interrupt Vector Address
	reti								; Overflow1 Interrupt Vector Address
	rjmp TIM0_OVF						; Overflow0 Interrupt Vector Address
	reti								; SPI Interrupt Vector Address
	reti								; UART Receive Complete Interrupt Vector Address
	reti								; UART Data Register Empty Interrupt Vector Address
	reti								; UART Transmit Complete Interrupt Vector Address
	reti								; ADC Conversion Complete Interrupt Vector Address
	reti								; EEPROM Write Complete Interrupt Vector Address
	reti								; Analog Comparator Interrupt Vector Address
;--------------------------------------/

;--- Subroutines ----------------------\
.include "LED.asm"						; Running, Error, TWI-Activity & TWI-AddressMatch LED's
.include "LCD_8.asm"					; De avrasm2 versie, 8-bit LCD IF.
;include "TWI_Buffers.asm"				; De Buffers voor in- & uitvoer op de I2C-bus
.include "I2C.asm"						; De I2C sub-routine's en interrupt-handlers
;include "Unit1.asm"					; subroutine's
;--------------------------------------/


;---------------------------------------
;--- AnalogComparator_Initialize
;--------------------------------------\
AnalogComparator_Initialize:
	; De analog-comparator uitschakelen om vermogen te besparen
	ldi		temp, (1<<ACD)				; ACD = Analog Compare Disable
	out		ACSR, temp					; ACSR = Analog comparator Control & Status Register
	ret
;--------------------------------------/


RESET:
	; interrupts blokkeren
	cli
	
	; De stack-pointer instellen op het einde van het RAM
	ldi		R16, high(RAMEND)
	ldi		R17, low(RAMEND)
	out		SPH, R16
	out		SPL, R17

	; De analog-comparator uitschakelen om vermogen te besparen
	rcall	AnalogComparator_Initialize

;**** LED Initialization ****
	rcall	LED_Initialize

;**** LCD Initialization ****
	rcall	LCD_Initialize
	LED_Aan LED_Running						; .. en nu de "Running" LED aan

;	; De I2C-buffers initialiseren
;	rcall	TWI_Initialize_Buffers
	; De I2C-bus initialiseren
	rcall	TWI_init

	; interrupts weer toelaten
	sei

;***************************************************
;* Wait for TWI Start Condition (13 intstructions) *
;***************************************************
;De volgende 13 instructies zijn niet nodig als men er zeker
;van is dat de I2C-bus niet bezet is als deze slave wordt geactiveerd.

;do_start_w:								; do
;	in		temp,PIND						; 	sample SDA & SCL
;	com		temp							;	invert
;	andi	temp,pinmask					;	mask SDA and SCL
;	brne	do_start_w						; while (!(SDA && SCL))
;
;	in		temp,PIND						; sample SDA & SCL
;	andi	temp,pinmask					; mask out SDA and SCL
;do_start_w2:								; do
;	in		temp2,PIND						;	new sample
;	andi	temp2,pinmask					;	mask out SDA and SCL
;	cp		temp2,temp
;	breq	do_start_w2						; while no change
;
;	sbrc	temp2,PIND2						; if SDA no changed to low
;	rjmp	do_start_w						;	repeat
;
;	rcall	TWI_get_adr						; call(!) interrupt handle (New transfer)


;***************************************************************************
;*
;* PROGRAM
;*	main - Test of TWI slave implementation
;*
;***************************************************************************

main:	
;	rcall	TWI_ProcessMessages				; eventuele seriële I2C data verwerken..
	rjmp	main							; loop forever

;**** End of File ****


;---------------------------------------------------------------------------------------------------
;--- Een 4-bits / 8-bits LCD implementatie.
;---------------------------------------------------------------------------------------------------


;--- INCLUDE FILES --------------------\
;.nolist
.include "8535def.inc"					; AVR AT90S8535
;.list
;--------------------------------------/



;--- De AVR-AT90S8535 "vector"-tabel --\
.CSEG
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



;--- INCLUDED SUB-ROUTINES ------------\
.include "LCD_4_8.asm"					; LCD sub-routine's
;--------------------------------------/



;---------------------------------------
;--- AnalogComparator_Initialize
;--------------------------------------\
AnalogComparator_Initialize:
	; De analog-comparator uitschakelen om vermogen te besparen
	ldi		R16, (1<<ACD)				; ACD = Analog Compare Disable
	out		ACSR, R16					; ACSR = Analog comparator Control & Status Register
	ret
;--------------------------------------/



;---------------------------------------
;--- Main Program
;--------------------------------------\
RESET:
	cli									; interrupts tegenhouden

	ldi		R16, high(RAMEND)			; initialiseer de stack pointer
	ldi		R17, low(RAMEND)
	out		SPH, R16
	out		SPL, R17

	rcall	AnalogComparator_Initialize	; initialiseer de Analog Comparator

	rcall	LCD_Initialize				; Het LCD instellen

	sei									; interrupts weer toelaten

main_loop:
	rjmp 	main_loop
;--------------------------------------/


;-------------------------------------------------------------------
;--- Het orginele programma is van:
; dave clausen
; ee281
; avr-ne2k.asm
; 11/26/2000
;--- Code uitbreiding door:
;--- Ron Driessen
;--- 28-11-2003
;-------------------------------------------------------------------
;--- ISA-slot Connectie met AVR:
;---			B				A
;---		 <1>|---------------|<1>
;---		Gnd |Gnd     -IOCHCK|
;---	AVR-PA7 |RESET        D7| AVR-PD7
;---		Vcc |+5v          D6| AVR-PD6
;---			|IRQ9         D5| AVR-PD5
;---			|-5v          D4| AVR-PD4
;---			|DREQ2        D3| AVR-PD3
;---			|-12v         D2| AVR-PD2
;---			|-0WS         D1| AVR-PD1
;---			|Gnd          D0| AVR-PD0
;---			|+12v    IOCHRDY|
;---		Vcc |-SMEMW      AEN| Gnd
;---		Vcc |-SMEMR      A19| Gnd
;---	AVR-PA6 |-IOW        A18| Gnd
;---	AVR-PA5 |-IOR        A17| Gnd
;---			|-DACK3      A16| Gnd
;---			|DRQ3        A15| Gnd
;---			|-DACK1      A14| Gnd
;---			|DRQ1        A13| Gnd
;---			|-REFSH      A12| Gnd
;---			|CLK         A11| Gnd
;---			|IRQ7        A10| Gnd
;---			|IRQ6         A9| Gnd ?!  moet volgens mij zijn: Vcc
;---			|IRQ5         A8| Vcc ?!                         Vcc
;---			|IRQ4         A7| Vcc ?!                         Gnd
;---			|IRQ3         A6| Gnd
;---			|-DACK2       A5| Gnd
;---			|TC           A4| AVR-PA4
;---			|BALE         A3| AVR-PA3
;---		Vcc |+5v          A2| AVR-PA2
;---			|Osc          A1| AVR-PA1
;---		Gnd |Gnd          A0| AVR-PA0
;---	   <B31>|---------------|<A31>
;---		 <D>|---------------|<C>
;---			|               |
;---			|               |
;---			|               |
;---			| No Connection |
;---			| to this part  |
;---			| of the ISA    |
;---			| connector     |
;---			|               |
;---			|               |
;---			|               |
;---			|---------------|
;---
;-------------------------------------------------------------------
;--- Connecties met AVR:
;---
;---			|---------------|
;---		LED	|PB0         PA0| \
;---	 LCD RS	|PB1         PA1|  |
;---	 LCD RW	|PB2         PA2|  > ISA A4-A0
;---	  LCD E	|PB3         PA3|  |
;---			|            PA4| /
;---			|            PA5| ISA -IOR
;---			|            PA6| ISA -IOW
;---			|            PA7| ISA RESET
;---			|               |
;---			|               |
;---			|               |
;---			|            PC7| \ 
;---			|            PC6|  |
;---	 ISA D0	|PD0         PC5|  |
;---	 ISA D1	|PD1         PC4|  > LCD DB7-DB0
;---	 ISA D2	|PD2         PC3|  |
;---	 ISA D3	|PD3         PC2|  |
;---	 ISA D4	|PD4         PC1|  |
;---	 ISA D5	|PD5         PC0| /
;---	 ISA D6	|PD6         PD7| ISA D7
;---			|---------------|
;---
;-------------------------------------------------------------------


;--- INCLUDE FILES --------------------\
.nolist
.include "8535def.inc"					; AVR AT90S8535
.include "System.inc"					; 
.list
;--------------------------------------/


;--- LED Connecties -------------------\
.equ LED_PORT		= PORTB
.equ LED_PIN		= PB0
.equ LED_DDR		= DDRB
;--------------------------------------/


;--- REGISTER ALIASSEN ----------------\
.def CharReg	= R0					; tbv. LPM-instructie
.def temp		= R16					; Een register voor algemeen gebruik
.def temp2		= R17					;  "
.def temp3		= R18					;  "
.def temp4		= R19					;  "
;--------------------------------------/


;--- De AVR-AT90S8535 vector-tabel ----\
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


;--- SUB-ROUTINES ---------------------\
.include "Delays.asm"					; Delay
.include "LCD.asm"						; LCD
.include "NE2000.asm"					; NIC
;--------------------------------------/




;---------------------------------------
;--- Main Program
;--------------------------------------\
RESET:
	cli									; block interrupts
	initStackPointer					; reset the stack pointer

	; turn off the analog comparator to save power
	ldi		r16, 0b10000000				; ACD - analog compare disable
	out		ACSR, r16

	sbi		LED_DDR, LED_PIN			; LED poort als output

	rcall	LCD_Initialize				; intialiseer het LCD

	rcall 	NE2K_Initialize				; Initialiseer de NE2000
	rcall 	NE2K_Establish_IP_Address
	rcall 	Display_MAC_Address
	rcall 	Display_IP_Address

main_loop:
	rcall 	NE2K_ProcessMessages		; verwerk netwerk packets
	rjmp 	main_loop
;--------------------------------------/





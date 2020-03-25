
;********************************************************************************
;***
;***  Een implementatie voor een 4-bit aansturing van het LED-display.
;***
;***	LED-Display		AVR
;***	--------------		----------------
;***	1 Vss		->  	GND 
;***	2 Vcc		->	5V 
;***	3 Vee		->	GND of naar een potmeter
;***	4 RS		->	PC4
;***	5 RW		->	GND * 
;***	6 E			->	PC5
;***	7 DB0		->	GND }
;***	8 DB1		->	GND }
;***	9 DB2		->	GND }
;***	10 DB3		->	GND }
;***	11 DB4		->	PC0
;***	12 DB5		->	PC1
;***	13 DB6		->	PC2
;***	14 DB7		->	PC3
;***
;*** RS high = DATA, RS low = BEVEL/COMMANDO
;***
;*** RW high = lezen, RW low = schrijven.
;*** * Als RW op LEZEN (1) is ingesteld, en RS op BEVEL (0), dan kan de busy-flag
;*** gelezen worden.
;*** Als de LED-Display pin RW aan de AVR-GND aangesloten is, dan kan er geen
;*** busy-flag gelezen worden om te bepalen of commando's verwerkt zijn. In dat
;*** geval moeten er korte pauzes ingelast worden tussen bevelen/commando's om er
;*** zeker van te zijn dat commando's verwerkt zijn.
;*** Er zijn 2 pauze routines gedefinieerd, een korte 50 micro-seconde pauze en
;*** een langere 5 milli-seconde pauze. Deze pauze-routines zijn afgestemd op een
;*** 7.3728MHz AVR.
;********************************************************************************


.include "8535def.inc"

; Mijn constanten
.equ LCD_RS	= 4							; RS op pin 4 van poort C
.equ LCD_E	= 5							; E op pin 5 van poort C
; en de register-alias voor de gebruikte registers
.def temp	= R17						; Een register voor algemeen gebruik
.def tempL	= R18						; Een register voor algemeen gebruik
.def temp2	= R19						; Een register voor algemeen gebruik
.def temp3	= R20						; Een register voor algemeen gebruik
.def temp4	= R21						; Een register voor algemeen gebruik




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





;------------------------------------------
;--- Zend een DATA-byte naar het LED-Display.
;------------------------------------------
LCD_data:
	mov		temp2, temp					; "kopie" tbv. overdragen 2e nibble.
	swap	temp						; nibbles swappen
	andi	temp, 0b00001111			; bovenste nibble op 0 zetten
	sbr		temp, (1<<LCD_RS)			; RS-bit op 1 om DATA te schrijven
	out		PORTC, temp					; en 1e nibble schrijven
	rcall	LCD_enable					; Enable-Routine oproepen
                                        ; 2e Nibble, geen swap meer nodig
	andi	temp2, 0b00001111			; bovenste nibble op 0 zetten
	sbr		temp2, (1<<LCD_RS)			; RS-bit op 1 om DATA te schrijven
	out		PORTC, temp2				; en 2e nibble schrijven
	rcall	LCD_enable					; Enable-Routine oproepen
	rcall	delay50us					; Delay-Routine oproepen (alleen als RW aan GND hangt)
	ret									;



;------------------------------------------
;--- Zend een COMMANDO-byte naar het LED-Display.
;------------------------------------------
LCD_command:							;zoals LCD_data, maar zonder RS te zetten
	mov		temp2, temp					; "kopie" tbv. overdragen 2e nibble.
	swap	temp						; nibbles swappen
	andi	temp, 0b00001111			; bovenste nibble op 0 zetten
	out		PORTC, temp					; en 1e nibble schrijven
	rcall	LCD_enable					; Enable-Routine oproepen
                                        ; 2e Nibble, geen swap meer nodig
	andi	temp2, 0b00001111			; bovenste nibble op 0 zetten
	out		PORTC, temp2				; en 2e nibble schrijven
	rcall	LCD_enable					; Enable-Routine oproepen
	rcall	delay50us					; Delay-Routine oproepen (alleen als RW aan GND hangt)
	ret									;



;------------------------------------------
;--- Zend een ENABLE-puls naar het LED-Display.
;------------------------------------------
LCD_enable:
	sbi		PORTC, LCD_E				; Enable hoog maken
	nop									; 3 cycles wachten
	nop
	nop
	cbi		PORTC, LCD_E				; Enable weer laag maken
	ret									;




;------------------------------------------
;--- Een pauze na elke overdracht.
;--- 50us => 3686.4 clockcycles  (14.4*256 innerloop)
;---  5ms => 368640 clockcycles
;------------------------------------------
delay50us:								;50us pauze
	ldi		temp, 14
innerloop50us:
	ldi		temp2, 0
	dec		temp2
	brne	innerloop50us
	dec		temp
	brne	innerloop50us
afterloop50us:
	ldi		temp, 67
	dec		temp
	brne	afterloop50us
	ret


 ;een langere pauze na bevelen/commando's
delay5ms:								;5ms Pause
	ldi		temp3, 100					; 100 x 50us = 5ms
innerloop5ms:
	rcall	delay50us
	dec		temp3
	brne	innerloop5ms
	ret






;------------------------------------------
;--- Initialiseer het LED-Display.
;------------------------------------------
LCD_init:
	ldi		temp4, 50
powerupwait:
	rcall	delay5ms
	dec		temp4
	brne	powerupwait

	ldi		temp, 0b00000011			; Dit moet 3x gezonden worden (Home Cursor)
	out		PORTC, temp					;   om te initialiseren.
	rcall	LCD_enable					; 1
	rcall	delay5ms
	rcall	LCD_enable					; 2
	rcall	delay5ms
	rcall	LCD_enable					; en 3!
	rcall	delay5ms
	ldi		temp, 0b00000010			; (Home Cursor)
	out		PORTC, temp
	rcall	LCD_enable
	rcall	delay5ms
	ldi		temp, 0b00101000			; 4bit-Modus instellen, 1/16 duty, 5x8 dots
	rcall	LCD_command
	ldi		temp, 0b00001100			; Display On, Cursor Off, Blinking Off
	rcall	LCD_command
	ldi		temp, 0b00000100			; set cursor move direction
	rcall	LCD_command
	ret





;------------------------------------------
;--- Wis het scherm van het LED-Display.
;------------------------------------------
LCD_clear:
	ldi		temp, 0b00000001			; Display legen
	rcall	LCD_command
	rcall	delay5ms
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


	;--- De gebruikte poort instellen -------------------------------------------------------------------
	; Poort C als output instellen (het LED display hangt hieraan)
	ser		temp
	out		DDRC, temp


	rcall	LCD_init
	rcall	LCD_clear

	ldi		temp, 'H'
	rcall	LCD_data

	ldi		temp, 'i'
	rcall	LCD_data
           
	ldi		temp, 'j'
	rcall	LCD_data

	ldi		temp, ' '
	rcall	LCD_data

	ldi		temp, 'd'
	rcall	LCD_data

	ldi		temp, 'o'
	rcall	LCD_data

	ldi		temp, 'e'
	rcall	LCD_data

	ldi		temp, 't'
	rcall	LCD_data

	ldi		temp, ' '
	rcall	LCD_data

	ldi		temp, ''''
	rcall	LCD_data

	ldi		temp, 't'
	rcall	LCD_data


	; Een eeuwige lus....
eloop:
	rjmp eloop




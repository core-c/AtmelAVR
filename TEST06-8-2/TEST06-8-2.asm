;********************************************************************************
;***
;***  Een implementatie voor een 8-bit aansturing van het LED-display.
;***
;***	LED-Display	AVR
;***	-----------	-----------------------------
;***	1	Vss	   	GND 
;***	2	Vcc	  	5V 
;***	3	Vee	  	GND of naar een potmeter
;***
;***	4	RS	  	PA5 |
;***	5	RW	  	PA6 > control lijnen (OUTPUT)
;***	6	E	  	PA7 |
;***
;***	7	DB0	  	PC0 |
;***	8	DB1	  	PC1 |
;***	9	DB2	  	PC2 |
;***	10	DB3	  	PC3 > data lijnen (OUTPUT)
;***	11	DB4	  	PC4 |
;***	12	DB5	  	PC5 |
;***	13	DB6	  	PC6 |
;***	14	DB7	  	PC7 |
;***
;*** RW high = lezen, RW low = schrijven.
;*** RS high = DATA, RS low = COMMANDO
;***
;*** * Als RW op LEZEN (1) is ingesteld, en RS op BEVEL (0), dan kan de busy-flag
;*** gelezen worden.
;*** Als de LED-Display pin RW aan de AVR-GND aangesloten is, dan kan er geen
;*** busy-flag gelezen worden om te bepalen of commando's verwerkt zijn. In dat
;*** geval moeten er korte pauzes ingelast worden tussen bevelen/commando's om er
;*** zeker van te zijn dat commando's verwerkt zijn.
;*** Bij onze 8-bits aansturing wordt de RW pin echter normaal aangesloten.
;*** Er zijn wat pauze routines gedefinieerd; Deze pauze-routines zijn afgestemd 
;*** op een 7.3728MHz AVR.
;***
;*** registergebruik:
;***	R30:R31 = het Z-Register
;***	R0 (CharReg) wordt gebruikt in samenhang met de LPM-instructie.
;***	Alle temp-registers zijn voor algemeen gebruik
;***	Alle delay-registers worden gebruikt voor wacht-routine's
;***
;********************************************************************************


;--- INCLUDE FILES -----------------
.include "8535def.inc"				; Atmel AVR-AT90S8535 definities
.include "IO.inc"					; Instellen I/O-poorten


;--- REGISTER ALIASSEN ADC ---------
.def AD_ValueL	= R10
.def AD_ValueH	= R11


.cseg								; Het begin van het CODE-segment
;--- De Interrupt-vector tabel -----
.org $0000							; Het begin van de vector-tabel op adres 0 van het RAM
	rjmp RESET						; Reset Handler
	reti							; External Interrupt0 Vector Address
	reti							; External Interrupt1 Vector Address
	reti							; Timer2 compare match Vector Address
	reti							; Timer2 overflow Vector Address
	reti							; Timer1 Input Capture Vector Address
	reti							; Timer1 Output Compare A Interrupt Vector Address
	reti							; Timer1 Output Compare B Interrupt Vector Address
	reti							; Overflow1 Interrupt Vector Address
	reti							; Overflow0 Interrupt Vector Address
	reti							; SPI Interrupt Vector Address
	reti							; UART Receive Complete Interrupt Vector Address
	reti							; UART Data Register Empty Interrupt Vector Address
	reti							; UART Transmit Complete Interrupt Vector Address
	rjmp ADC_CC_Interrupt			; ADC Conversion Complete Interrupt Vector Address
	reti							; EEPROM Write Complete Interrupt Vector Address
	reti							; Analog Comparator Interrupt Vector Address
;-----------------------------------



;--- LCD INCLUDE FILE --------------
.include "LCD.asm"					; LC-Display

;--- De teksten in programma-geheugen --
Line0:	.db	"AVR @ 7.3728 MHz.", EOS_Symbol
Line1:	.db	"LCD @ 8-bit", EOS_Symbol
Line2:	.db	"ADC 0000h ", EOS_Symbol		; regel bevat zelf-gedefinieerde tekens
Line3:	.db	"COMM-Rx/Tx: 00h 00h", EOS_Symbol


;--- Zelf-gedefinieerde tekens in programma-geheugen --
;          	  ___12345
CChar0:	.db	0b00000000;1
		.db	0b00000000;2
		.db	0b00010000;3
		.db	0b00010000;4
		.db	0b00010000;5
		.db	0b00010000;6
		.db	0b00000000;7
		.db	0b00000000;|
CChar1:	.db	0b00000000
		.db	0b00000000
		.db	0b00011000
		.db	0b00011000
		.db	0b00011000
		.db	0b00011000
		.db	0b00000000
		.db	0b00000000
CChar2:	.db	0b00000000
		.db	0b00000000
		.db	0b00011100
		.db	0b00011100
		.db	0b00011100
		.db	0b00011100
		.db	0b00000000
		.db	0b00000000
CChar3:	.db	0b00000000
		.db	0b00000000
		.db	0b00011110
		.db	0b00011110
		.db	0b00011110
		.db	0b00011110
		.db	0b00000000
		.db	0b00000000
CChar4:	.db	0b00000000
		.db	0b00000000
		.db	0b00011111
		.db	0b00011111
		.db	0b00011111
		.db	0b00011111
		.db	0b00000000
		.db	0b00000000



;---------------------------------------
;--- PROGRAMMA START
;---------------------------------------
RESET:
	; interrupts uitschakelen
	cli
	; De stack-pointer instellen op het einde van het RAM
	ldi		temp, high(RAMEND)
	ldi		temp2, low(RAMEND)
	out		SPH, temp
	out		SPL, temp2

	; LCD-Display initialiseren
	rcall	LCD_Init

	; De zelf-gedefinieerde tekens uploaden naar het LCD
	; register temp bits 5..0 bevatten het CGRAM adres
	ldi		temp2, 0					; |
	ldi		ZL, low(CChar0)
	ldi		ZH, high(CChar0)
	rcall	LCD_CustomCharacter
	ldi		temp2, 1					; ||
	ldi		ZL, low(CChar1)
	ldi		ZH, high(CChar1)
	rcall	LCD_CustomCharacter
	ldi		temp2, 2					; |||
	ldi		ZL, low(CChar2)
	ldi		ZH, high(CChar2)
	rcall	LCD_CustomCharacter
	ldi		temp2, 3					; ||||
	ldi		ZL, low(CChar3)
	ldi		ZH, high(CChar3)
	rcall	LCD_CustomCharacter
	ldi		temp2, 4					; |||||
	ldi		ZL, low(CChar4)
	ldi		ZH, high(CChar4)
	rcall	LCD_CustomCharacter


	; Een intro laten zien direct na een RESET
	rcall	LCD_SplashScreen


	; display-ares instellen op 1e regel
	ldi		temp, AddrLine0
	rcall	LCD_SetDisplayAddr
	; 1e regel afbeelden
	LCD_PrintString Line0

	; display-ares instellen op 2e regel
	ldi		temp, AddrLine1
	rcall	LCD_SetDisplayAddr
	; 2e regel afbeelden
	LCD_PrintString Line1

	; display-ares instellen op 3e regel
	ldi		temp, AddrLine2
	rcall	LCD_SetDisplayAddr
	; 3e regel afbeelden
	LCD_PrintString Line2

	; display-ares instellen op 4e regel
	ldi		temp, AddrLine3
	rcall	LCD_SetDisplayAddr
	; 4e regel afbeelden
	LCD_PrintString Line3


	;--- De ADC instellen -------------------------------------------------------------------------------
	rcall	ADC_Initialize
	; interrupts inschakelen
	sei
	; start de eerste AD-conversie.
	; Als Free-Running-mode is geselecteerd, dan volgen de andere conversies "automatisch"
	sbi		ADCSR, ADSC

eLoop:
	rcall	ADC_ProcessValuesOut
	rjmp	eLoop







;---------------------------------------
;--- ADC-waarde naar METER-string (max.len = 8)
;---	input:	Z = ADC-waarde (0..$3FF)
;---			temp2 = column (0..19)
;---			temp3 = row/line-adres
;---	output:	temp  = string-lengte afgebeelde string
;---------------------------------------
ADC_Meter:
;	; cursor uitschakelen tijdens verplaatsing ervan
;	; display-mode initialiseren (alles uit)
;	ldi		temp, (DISPLAY_ON | CURSOR_OFF | CURSOR_BLINK_OFF)
;	rcall	LCD_DisplayMode

	; cursor positie instellen
	rcall	LCD_CursorXY
	; Z bevat een 10-bits waarde (0000-03FF). Deze waarde moeten we
	; over 8 tekens op het LCD verdelen. Dwz. elk teken vertegenwoordigt
	; dan 1024/8=128 (1 bit verschil;)
	; laagste 7 bits van waarde in Z naar temp2 (LSB 7 bits van 10-bit sample)
	mov		temp2, ZL
	andi	temp2, $7F
	; bits 9-7 van waarde in Z naar temp3 (MSB 3 bits van 10-bit sample)
	mov		temp3, ZL
	lsl		temp3						; bit 7 van ZL in Carry-flag
	mov		temp3, ZH
	rol		temp3						; Carry-flag erin schuiven
	andi	temp3, 0b00000111
	; De stringlengte (!) bewaren om later als resultaat te retourneren
	mov		temp, temp3					; temp3 onveranderd laten
	inc		temp
	push	temp						; !!!! resultaat op de stack pushen
	; nu temp3.value x CChar4 afbeelden op cursor-positie
	; en daarna de waarde in temp2 omzetten naar 1 teken en erachter plakken
	cpi		temp3, 0
	breq	Remainer
NextCC:
	ldi		temp, 4						; Custom-Character 4 (vol blokje)
	rcall	LCD_Data
	dec		temp3
	brne	NextCC

Remainer:
	; De resterende (gedeeltelijk gevulde blokjes) afbeelden
	; Dit is een waarde in het bereik 0..127 welke evrdeeld wordt over
	; 5 ASCII-tekens (spatie, 1 dot, 2 dots, 3 dots & 4 dots)
	mov		temp, temp2
	andi	temp, 0b01111111
	clr		temp3						; temp3 op 0
isDot:
	cpi		temp, 25
	brlo	NextDot
	sbci	temp, 25					; 127/5=25.4
	inc		temp3
	rjmp	isDot
NextDot:
	; temp3 bevat nu het aantal af te beelden dots voor het laatste ASCII-teken
	ldi		temp, ' '
	cpi		temp3, 0
	breq	DrawRemainer
	dec		temp3						; de ASCII-code is 1 minder dan het aantal dots in het teken
	mov		temp, temp3
DrawRemainer:
	rcall	LCD_Data

;	; Cursor weer inschakelen
;	ldi		temp, (DISPLAY_ON | CURSOR_OFF | CURSOR_BLINK_OFF)
;	rcall	LCD_DisplayMode

	; resultaat in register temp aanleveren
	; De stringlengte van de afgebeelde string ophalen in register temp3
	pop		temp						; !!!! van de stack poppen
	ret


;---------------------------------------
;--- ADC-sample waarde als decimaal getal
;--- afbeelden. altijd met 4 cijfers.
;---	input:	Z = ADC-waarde (0..$3FF)
;---			temp2 = column (0..19)
;---			temp3 = row/line-adres
;---------------------------------------
ADC_Decimal:
	ret


;---------------------------------------
;--- ADC-sample waarde als hexadecimaal
;--- getal afbeelden. altijd met 4 cijfers.
;---	input:	Z = ADC-waarde (0..$3FF)
;---			temp2 = column (0..19)
;---			temp3 = row/line-adres
;---------------------------------------
ADC_Hex:
	; cursor positie instellen
	rcall	LCD_CursorXY
	rcall	LCD_HexWord	
	ret


;------------------------------------------
;--- ADC: Initialiseer de ADC. (subroutine)
;------------------------------------------
ADC_Initialize:
	; Poort A pin 0 als input instellen
	cbi		DDRA, PINA0
	; pushpull instellen??
	;
	; ADC Enable
	; ADC Free Running Mode selecteren
	; ADC Interrupt Enable na Conversion-Complete
	; ADC prescale instellen: 7.73728 MHz / 128 = 57600 Hz
	ldi		temp, (1<<ADEN | 1<<ADFR | 1<<ADIE | 1<<ADPS2 | 1<<ADPS1 | 1<<ADPS0)
	out		ADCSR, temp
	; Selecteer ADC kanaal 0 op de multiplexer
	ldi		temp, 0
	out		ADMUX, temp
	ret


;------------------------------------------
;--- ADC: Conversion Complete (interrupt)
;------------------------------------------
ADC_CC_Interrupt:
	; De geconverteerde waarden inlezen van de ADC en
	; bewaren in de toegewezen registers.
	in		AD_ValueL, ADCL
	in		AD_ValueH, ADCH
	reti


;------------------------------------------
;--- Subroutine: ADC samples afbeelden op LCD
;------------------------------------------
ADC_ProcessValuesOut:
	; sample-waarde op LCD afbeelden
	mov		ZL, AD_ValueL
	mov		ZH, AD_ValueH
	ldi		temp2, 10
	ldi		temp3, AddrLine2
	rcall	ADC_Meter
	; register temp bevat nu de stringlengte van de afgebeelde "meter/progressbar"....
	; 2e regel wissen na ADC-meter
	ldi		temp2, 10
	add		temp2, temp						; De stringlengte van de meter erbij optellen
	ldi		temp3, AddrLine2
	rcall	LCD_ClearLineFromXY
	; ADC-waarde ook hexadecimaal afbeelden
	mov		ZL, AD_ValueL
	mov		ZH, AD_ValueH
	ldi		temp2, 4
	ldi		temp3, AddrLine2
	rcall	ADC_Hex
	ret

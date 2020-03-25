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
;***	4	RS	  	PB1 |
;***	5	RW	  	PB2 > control lijnen (OUTPUT)
;***	6	E	  	PB3 |
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
;*** Als RW = 1, en RS = 0, dan kan de busy-flag gelezen worden.
;***
;*** De busy-flag (DB7) moet getest worden voor elke schrijf-opdracht (BF: 0=ready, 1=busy)
;*** Bij leesopdrachten hoeft dit niet te gebeuren.
;***
;*** Als de LED-Display pin RW aan de AVR-GND aangesloten is, dan kan er geen
;*** busy-flag gelezen worden om te bepalen of commando's verwerkt zijn. In dat
;*** geval moeten er korte pauzes ingelast worden tussen bevelen/commando's om er
;*** zeker van te zijn dat commando's verwerkt zijn.
;*** Bij onze 8-bits aansturing wordt de RW pin echter normaal aangesloten.
;*** Er zijn wat pauze routines gedefinieerd; Deze pauze-routines zijn afgestemd 
;*** op een 7.3728MHz AVR. Deze pauzes moeten gebruikt worden tijdens initialisatie
;*** van het LCD als het display nog niet weet of het als 8- of 4-bits interface
;*** gebruikt gaat worden.
;***
;*** registergebruik:
;***	R30:R31 = het Z-Register
;***	R0 (CharReg) wordt gebruikt in samenhang met de LPM-instructie.
;***	Alle temp-registers zijn voor algemeen gebruik
;***	Alle delay-registers worden gebruikt voor wacht-routine's
;***
;********************************************************************************
;***
;*** 1 regel:  1/8 duty  => 5x7 dots font + cursor, 5x8 dots.
;***           1/11 duty => 5x11 dots font.
;***           1/16 duty => 5x7 dots font + cursor, 5x8 dots.
;*** 2 regels: 1/16 duty => 5x7 dots font + cursor, 5x8 dots.
;*** 4 regels: 1/16 duty => 5x8 dots.
;***
;*** Zelf-gedefinieerde tekens bezetten ASCII plekken 0 t/m 7 van een 5x7 font.
;*** Zelf-gedefinieerde tekens bezetten ASCII plekken 0 t/m 3 van een 5x10 font.
;***
;********************************************************************************


;;--- INCLUDE FILES -----------------------\
;.include "8535def.inc"						; Atmel AVR-AT90S8535 definities
;.include "IO.inc"							; Instellen I/O-poorten
;;-----------------------------------------/


;;--- REGISTER ALIASSEN -------------------\
;.def CharReg	= R0						; tbv. LPM-instructie
;.def temp		= R16						; Een register voor algemeen gebruik
;.def temp2		= R17						;  "
;.def temp3		= R18						;  "
;.def temp4		= R19						;  "
;;-----------------------------------------/


;--- CONSTANTEN ---------------------------\
.equ EOS_Symbol	= '$'						; End-Of-String teken
;--- Begin-adressen van elke regel ---------
.equ AddrLine0	= $00
.equ AddrLine1	= $40
.equ AddrLine2	= $14
.equ AddrLine3	= $54
;--- Bit-waarden besturingslijnen ----------
.equ RS_COMMAND	= 0							; LCD_RS-bit bij commando's
.equ RS_DATA	= 1							; LCD-RS-bit bij data
.equ RW_WRITE	= 0							; LCD_RW-bit bij schrijven naar LCD-geheugen
.equ RW_READ	= 1							; LCD_RW-bit bij lezen van LCD-geheugen
;--- Toegekende bits tbv. commando's -------
.equ CMD_DDRAMAddress		= (1<<7)		; DataBus bits 7..0
.equ CMD_CGRAMAddress		= (1<<6)
.equ CMD_FunctionSet		= (1<<5)
.equ CMD_CursorDisplayShift	= (1<<4)
.equ CMD_DisplayMode		= (1<<3)
.equ CMD_EntryMode			= (1<<2)
.equ CMD_CursorHome			= (1<<1)
.equ CMD_Clear				= (1<<0)
;--- Geldige DB7..0-bits bij commando's ----
.equ MASK_BUSYFlag	 			= 0b10000000
.equ MASK_DDRAMAddress 			= 0b01111111
.equ MASK_CGRAMAddress 			= 0b00111111
.equ MASK_FunctionSet			= 0b00011100
.equ MASK_CursorDisplayShift	= 0b00001100
.equ MASK_DisplayMode			= 0b00000111
.equ MASK_EntryMode				= 0b00000011
;--- Function Set bits ---------------------
.equ DATA_LEN_4			= (0<<4)			; 4-bits IF
.equ DATA_LEN_8			= (1<<4)			; 8-bits IF
.equ LINE_COUNT_1		= (0<<3)			; 1/8 or 1/11 Duty (1 line)
.equ LINE_COUNT_2		= (1<<3)			; 1/16 Duty (2 lines)
.equ FONT_5x7			= (0<<2)			; 5x7 dots font
.equ FONT_5x10			= (1<<2)			; 5x10 dots font
;--- CursorDisplayShift bits ---------------
.equ SHIFT_DISPLAY_LEFT			= (0<<3)	; beweeg display & cursor naar links
.equ SHIFT_DISPLAY_RIGHT		= (1<<3)	; beweeg display & cursor naar rechts
.equ SHIFT_CURSOR_LEFT			= (0<<2)	; beweeg de cursor naar links
.equ SHIFT_CURSOR_RIGHT			= (1<<2)	; beweeg de cursor naar rechts
;--- DisplayMode bits ----------------------
.equ DISPLAY_OFF		= (0<<2)			; LCD-display uit
.equ DISPLAY_ON			= (1<<2)			; LCD-display aan
.equ CURSOR_OFF			= (0<<1)			; Cursor uit
.equ CURSOR_ON			= (1<<1)			; Cursor aan
.equ CURSOR_BLINK_OFF	= (0<<0)			; Cursor knipperen uit
.equ CURSOR_BLINK_ON	= (1<<0)			; Cursor knipperen aan
;--- Entry Mode bits -----------------------
.equ AUTO_DECREMENT		= (0<<1)			; Auto-Verlagen video-adres
.equ AUTO_INCREMENT		= (1<<1)			; Auto-Verhogen video-adres
.equ NO_DISPLAY_SHIFT	= (0<<0)			; Display-shift uitschakelen
.equ DISPLAY_SHIFT		= (1<<0)			; Display-shift inschakelen
;------------------------------------------/


;--- Connecties ---------------------------\
.equ LCD_CTRL_PORT	= PORTB					; De control-port (alleen als OUTPUT)
.equ LCD_CTRL_DDR	= DDRB
.equ LCD_RS			= PB1					; RS op AVR pin 2
.equ LCD_RW			= PB2					; RW op AVR pin 3
.equ LCD_E			= PB3					; E(nable) op AVR pin 4
.equ LCD_DATA_PORT	= PORTC					; De data-port DB7-0 (INPUT/OUTPUT)
.equ LCD_DATA_DDR	= DDRC
.equ LCD_DATA_IN	= PINC
.equ LCD_BUSY		= PC7					; Busy-Flag op pin 7 van poort C (=DB7)
;; LED
;.equ LED_PORT		= PORTB
;.equ LED_PIN		= PB0
;.equ LED_DDR		= DDRB
;------------------------------------------/



;--- Een CODE-segment in FLASH ---------
.CSEG


;--------------------------------------\
;.include "Delays.asm"					; Delay routine's
;--------------------------------------/


;;--- De teksten in programma-geheugen --
;Line0:	.db	"AVR @ 7.3728 MHz.", EOS_Symbol
;Line1:	.db	"LCD @ 8-bit", EOS_Symbol
;Line2:	.db	"ADC 0000h ", EOS_Symbol		; regel bevat zelf-gedefinieerde tekens
;Line3:	.db	"COMM-Rx/Tx: 00h 00h", EOS_Symbol


;--- Zelf-gedefinieerde tekens in programma-geheugen --
;;          	  ___12345
;CChar0:.db	0b00000000;1
;		.db	0b00000000;2
;		.db	0b00010000;3
;		.db	0b00010000;4
;		.db	0b00010000;5
;		.db	0b00010000;6
;		.db	0b00000000;7
;		.db	0b00000000;|cursor
;CChar1:.db	0b00000000
;		.db	0b00000000
;		.db	0b00011000
;		.db	0b00011000
;		.db	0b00011000
;		.db	0b00011000
;		.db	0b00000000
;		.db	0b00000000
;CChar2:db	0b00000000
;		.db	0b00000000
;		.db	0b00011100
;		.db	0b00011100
;		.db	0b00011100
;		.db	0b00011100
;		.db	0b00000000
;		.db	0b00000000
;CChar3:.db	0b00000000
;		.db	0b00000000
;		.db	0b00011110
;		.db	0b00011110
;		.db	0b00011110
;		.db	0b00011110
;		.db	0b00000000
;		.db	0b00000000
;CChar4:.db	0b00000000
;		.db	0b00000000
;		.db	0b00011111
;		.db	0b00011111
;		.db	0b00011111
;		.db	0b00011111
;		.db	0b00000000
;		.db	0b00000000

; Omdat het Flash/programma-geheugen per word is te adresseren
; dienen de bytes voor de patronen ook per word worden opgeslagen.
CChar0:	.dw	0b0000000000000000;2,1
		.dw	0b0001000000010000;4,3
		.dw	0b0001000000010000;6,5
		.dw	0b0000000000000000;8,7
CChar1:	.dw	0b0000000000000000
		.dw	0b0001100000011000
		.dw	0b0001100000011000
		.dw	0b0000000000000000
CChar2:	.dw	0b0000000000000000
		.dw	0b0001110000011100
		.dw	0b0001110000011100
		.dw	0b0000000000000000
CChar3:	.dw	0b0000000000000000
		.dw	0b0001111000011110
		.dw	0b0001111000011110
		.dw	0b0000000000000000
CChar4:	.dw	0b0000000000000000
		.dw	0b0001111100011111
		.dw	0b0001111100011111
		.dw	0b0000000000000000






;---------------------------------------
;--- MACRO'S
;--------------------------------------\
.MACRO LCD_CTRL_Data:
	sbi		LCD_CTRL_PORT, LCD_RS		; RS = 1 (data)
.ENDMACRO

.MACRO LCD_CTRL_Command:
	cbi		LCD_CTRL_PORT, LCD_RS		; RS = 0 (commando)
.ENDMACRO

.MACRO LCD_CTRL_Read:
    sbi		LCD_CTRL_PORT, LCD_RW		; R/W = 1 (lezen)
.ENDMACRO

.MACRO LCD_CTRL_Write:
    cbi		LCD_CTRL_PORT, LCD_RW		; R/W = 0 (schrijven)
.ENDMACRO

.MACRO LCD_CTRL_Enable1:
    sbi		LCD_CTRL_PORT, LCD_E		; E = 1
.ENDMACRO

.MACRO LCD_CTRL_Enable0:
    cbi		LCD_CTRL_PORT, LCD_E		; E = 0
.ENDMACRO

.MACRO LCD_Send;(register)
	; Tenminste 40 ns wachten alvorens Enable op 1. (<1 clockcycle)
	nop
	; De Enable-puls moet tenminste 230 ns op 1 blijven. (= 0.6290 clockcycle)
    sbi		LCD_CTRL_PORT, LCD_E
    out		LCD_DATA_PORT, @0
    cbi		LCD_CTRL_PORT, LCD_E		; register temp wordt nu overgedragen
.ENDMACRO


.MACRO LCD_PrintString;(address)
	ldi		ZL, low(2*@0)
	ldi		ZH, high(2*@0)
	rcall	LCD_Print
.ENDMACRO
;--------------------------------------/




;---------------------------------------
;--- De CTRL pin instellen.
;---------------------------------------
LCD_SetCTRLPins:
	; pinnen als input instellen
	cbi		LCD_CTRL_DDR, LCD_RS
	cbi		LCD_CTRL_DDR, LCD_RW
	cbi		LCD_CTRL_DDR, LCD_E
	; tristate instellen
	cbi		LCD_CTRL_PORT, LCD_RS
	cbi		LCD_CTRL_PORT, LCD_RW
	cbi		LCD_CTRL_PORT, LCD_E
	; poort als output instellen
	sbi		LCD_CTRL_DDR, LCD_RS
	sbi		LCD_CTRL_DDR, LCD_RW
	sbi		LCD_CTRL_DDR, LCD_E
	;
	cbi		LCD_CTRL_PORT, LCD_RS
	cbi		LCD_CTRL_PORT, LCD_RW
	cbi		LCD_CTRL_PORT, LCD_E
	ret

;---------------------------------------
;--- De DATA poort instellen.
;---	input:	temp2 = DDR waarde
;---			temp3 = poort waarde
;---------------------------------------
LCD_SetDATAPort:
	push	temp
	ldi		temp, PORT_AS_INPUT
	out		LCD_DATA_DDR, temp
	ldi		temp, INPUT_PORT_TRIS
	out		LCD_DATA_PORT, temp
	out		LCD_DATA_DDR, temp2
	out		LCD_DATA_PORT, temp3
	pop		temp
	ret

LCD_SetDATAPort_AS_OUTPUT:
	ldi		temp2,PORT_AS_OUTPUT
	ldi		temp3,0
	rcall	LCD_SetDATAPort
	ret

LCD_SetDATAPort_AS_INPUT:
	ldi		temp2, PORT_AS_INPUT
	ldi		temp3, INPUT_PORT_TRIS
	rcall	LCD_SetDATAPort
	ret



;---------------------------------------
;--- Wacht op busy-signaal
;---------------------------------------
LCD_WaitWhileBusy:
	push	temp
	push	temp2
	push	temp3
	rcall	LCD_SetDATAPort_AS_INPUT
	;
	LCD_CTRL_Command					; RS = 0 (command)
    LCD_CTRL_Read						; R/W = 1 (lezen)
	LCD_CTRL_Enable1					; E = 1
	rcall	delay1us					; 1-2 us wachten
	rcall	delay1us
WaitWhileFlag1:
	in		temp, LCD_DATA_IN			; Data Input (DB7..0) inlezen (BF=BD7)
	andi	temp, MASK_BUSYFlag			; busy flag filteren
	brne	WaitWhileFlag1
	LCD_CTRL_Enable0					; E = 0
    LCD_CTRL_Write						; R/W = 0 (schrijven)
	;
	rcall	LCD_SetDATAPort_AS_OUTPUT
	pop		temp3
	pop		temp2
	pop		temp
	ret



;---------------------------------------
;--- Schrijf commando
;---	input:	temp = waarde
;---------------------------------------
LCD_Command:
	rcall	LCD_WaitWhileBusy
LCD_Command_:
	LCD_CTRL_Command					; RS = 0 (commando)
    LCD_CTRL_Write						; R/W = 0 (schrijven)
	LCD_Send temp						; Data zenden naar LCD
	; 10 ms wachten na zenden COMMAND (4bits-IF)
	ret

;---------------------------------------
;--- Schrijf data
;---	input:	temp = waarde
;---------------------------------------
LCD_Data:
	rcall	LCD_WaitWhileBusy
	LCD_CTRL_Data						; RS = 1 (data)
    LCD_CTRL_Write						; R/W = 0 (schrijven)
	LCD_Send temp						; Data zenden naar LCD
	; 1 ms wachten na zenden DATA (4bits-IF)
	ret

;---------------------------------------
;--- Lees data
;---	output:	temp = gelezen byte
;---------------------------------------
LCD_Read_Data:
	push	temp2
	push	temp3
	rcall	LCD_WaitWhileBusy			; wacht op de busy-flag
	rcall	delay40us					; 40us wachten tot de auto-increment klaar is
	rcall	LCD_SetDATAPort_AS_INPUT
	LCD_CTRL_Data						; RS = 1 (data)
	LCD_CTRL_Read						; R/W = 1 (lezen)
	LCD_CTRL_Enable1					; E = 1
	rcall	delay1us					; 1-2 us wachten
	rcall	delay1us
	in		temp, LCD_DATA_IN			; Data Input
	LCD_CTRL_Enable0					; E = 0
    LCD_CTRL_Write						; R/W = 0 (schrijven)
	rcall	LCD_SetDATAPort_AS_OUTPUT
	pop		temp3
	pop		temp2
	ret










;---------------------------------------
;--- LCD-scherm wissen
;---------------------------------------
LCD_Clear:
	ldi		temp, CMD_Clear
    rcall	LCD_Command
	ret


;---------------------------------------
;--- LCD-cursor naar Home-positie
;---------------------------------------
LCD_Home:
	ldi		temp, CMD_CursorHome
    rcall	LCD_Command
	ret


;---------------------------------------
;--- LCD-Entry-mode instellen.
;---	input:	temp = b0 : 0=no display shift, 1=display shift
;--- 				   b1 : 0=auto-AUTO_DECREMENT, 1=auto-AUTO_INCREMENT
;---------------------------------------
LCD_EntryMode:
	andi	temp, MASK_EntryMode
	ori		temp, CMD_EntryMode
    rcall	LCD_Command
	ret


;---------------------------------------
;--- LCD-Display-mode instellen.
;---	input:	temp = b0 : 0=cursor blink off, 1=cursor blink on (als b1 = 1)
;--- 				   b1 : 0=cursor off,  1=cursor on
;---				   b2 : 0=display off, 1=display on (display data remains in DD-RAM)
;---------------------------------------
LCD_DisplayMode:
	andi	temp, MASK_DisplayMode
	ori		temp, CMD_DisplayMode
    rcall	LCD_Command
	ret


;---------------------------------------
;--- LCD-Cursor-Display-mode instellen.
;---	input:	temp = b2 : 0=shift left, 1=shift right
;--- 				   b3 : 0=cursor-shift, 1=display-shift
;---------------------------------------
LCD_CursorDisplayShift:
	andi	temp, MASK_CursorDisplayShift
	ori		temp, CMD_CursorDisplayShift
    rcall	LCD_Command
	ret


;---------------------------------------
;--- LCD_FunctionSet (Function Set)
;---	input:	temp = b2  : 0=5x7 dots font, 1=5x10 dots font
;--- 				   b3  : 0=1/8 or 1/11 Duty (1 line), 1=1/16 Duty (2 lines) 
;--- 				   b4  : 0=4-bit, 1=8-bit
;---------------------------------------
LCD_FunctionSet:						; entry point (busy-flag testen)
	rcall	LCD_WaitWhileBusy
LCD_FunctionSet_:						; entry point (zonder busy-flag test)
	andi	temp, MASK_FunctionSet
	ori		temp, CMD_FunctionSet
	rcall	LCD_Command_				; commando zonder busy-flag test aanroepen
	ret


;---------------------------------------
;--- LCD-SetCharGenAddr
;--- Instellen van het Character-Generator-RAM adres.
;--- CGRAM data lezen/schrijven na dit commando.
;---	input:	temp = b0-5 : CGRAM adres
;---------------------------------------
LCD_SetCharGenAddr:
	andi	temp, MASK_CGRAMAddress
	ori		temp, CMD_CGRAMAddress
    rcall	LCD_Command
	ret


;---------------------------------------
;--- LCD-SetDisplayAddr
;--- Instellen van het Display-Data-RAM adres.
;--- DDRAM data lezen/schrijven na dit commando.
;---	input:	temp = b0-6 : DDRAM adres
;---------------------------------------
LCD_SetDisplayAddr:
	ori		temp, CMD_DDRAMAddress
    rcall	LCD_Command
	ret


;---------------------------------------
;--- LCD_GetDisplayAddr
;--- Resulteer de adres-counter waarde (DDRAM/CGRAM).
;---	output:	temp bit6-0 : DDRAM/CGRAM adres
;---------------------------------------
LCD_GetDisplayAddr:
	push	temp2
	push	temp3
	rcall	LCD_WaitWhileBusy
	rcall	LCD_SetDATAPort_AS_INPUT
	LCD_CTRL_Command					; RS = 0 (command)
    LCD_CTRL_Read						; R/W = 1 (lezen)
	LCD_CTRL_Enable1					; E = 1
	rcall	delay1us					; 1-2 us wachten
	rcall	delay1us
	in		temp, LCD_DATA_IN			; Data Input (DB7..0) inlezen (BF=BD7)
	andi	temp, MASK_DDRAMAddress		; busy flag strippen
	LCD_CTRL_Enable0					; E = 0
    LCD_CTRL_Write						; R/W = 0 (schrijven)
	rcall	LCD_SetDATAPort_AS_OUTPUT
	pop		temp3
	pop		temp2
	ret






;---------------------------------------
;--- Een zelf-gedefinieerd teken in RAM plaatsen
;---	input:	temp2 = adres (0..7) in LCD-RAM
;---			Z = adres van teken-patroon (8 bytes lang) in AVR-program-memory
;--- !!! AUTO-INCREMENT MOET INGESCHAKELD ZIJN
;---------------------------------------
LCD_CustomCharacter:
	mov		temp, temp2
	lsl		temp						; LCD-RAM adres * 8
	lsl		temp
	lsl		temp
	rcall	LCD_SetCharGenAddr
	; nu de 8 bytes van het patroon overzenden
	lsl		ZL							; Eerst het adres x2 tbv. de LPM-instructie....
	rol		ZH
	ldi		temp2, 8					; 8 bytes overbrengen naar LCD-RAM
NextChar:
	lpm									; R0 (=CharReg) krijgt de waarde van de byte op adres [Z]
	adiw	ZL,1						; Z-register verhogen
	mov		temp, CharReg				; R0 = CharReg
	rcall	LCD_Data
	dec		temp2
	brne	NextChar
	; DDRAM adresseren ipv. CGRAM
	ldi		temp, 0
	rcall	LCD_SetDisplayAddr
	ret


;---------------------------------------
;--- LCD-Init
;---------------------------------------
LCD_Init:
	; LCD-Control poorten op AVR als output instellen
	rcall	LCD_SetCTRLPins
	; zo ook de LCD-Data poort op de AVR
	rcall	LCD_SetDATAPort_AS_OUTPUT
	;
	; instellen op 8-bits interface
	; moet 3x gebeuren met pauzes ertussen....
	rcall	delay15ms					; 15 milli-seconde pauze
	rcall	delay15ms					; 15 milli-seconde pauze
	;
    ldi		temp, DATA_LEN_8			; als 8-bit IF instellen
	rcall	LCD_FunctionSet_			; entry point zonder BF-test
	;
	rcall	delay4_1ms					; 4.1 milli-seconde pauze
	;
    ldi		temp, DATA_LEN_8			; als 8-bit IF instellen
	rcall	LCD_FunctionSet_			; entry point zonder BF-test
	;
	rcall	delay100us					; 100 micro-seconde pauze
	;
    ldi		temp, DATA_LEN_8			; als 8-bit IF instellen
	rcall	LCD_FunctionSet_			; entry point zonder BF-test
	; vanaf nu kan de BUSY-flag worden afgevraagd....
	;
	; Aantal regels en font instellen
    ldi		temp, (DATA_LEN_8 | LINE_COUNT_2 | FONT_5x7)
	rcall	LCD_FunctionSet				; entry point met BF-test
	; display-mode initialiseren (alles uit)
	ldi		temp, (DISPLAY_OFF | CURSOR_OFF | CURSOR_BLINK_OFF)
	rcall	LCD_DisplayMode
	; LCD-scherm wissen
	rcall	LCD_Clear
	; entry-mode instellen (AUTO-INCREMENT)
	ldi		temp, (AUTO_INCREMENT | NO_DISPLAY_SHIFT)
	rcall	LCD_EntryMode
	; Scherm aan, cursor aan, knipperen uit
	ldi		temp, (DISPLAY_ON | CURSOR_OFF | CURSOR_BLINK_OFF)
	rcall	LCD_DisplayMode

	rcall	delay15ms					; 15 milli-seconde pauze
	ret


;---------------------------------------
;--- LCD-Init + Splashscreen
;---------------------------------------
LCD_Initialize:
	; het LCD initialiseren
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
	;scherm wissen, cursor op 1e positie 1e regel, cursor knipperend
	rcall	LCD_Clear
	rcall	LCD_Home
	ldi		temp, (DISPLAY_ON | CURSOR_ON | CURSOR_BLINK_ON)
	rcall	LCD_DisplayMode
	ret




;---------------------------------------
;--- LCD XY2Addr
;---	input:	temp2 = column [0..19]
;---			temp3 = row [0..3]
;--- 	output: temp  = DDRAM Address
;---------------------------------------
LCD_XY2Addr:
	push	temp3
	cpi		temp3, 0
	brne	_XY1
	ldi		temp3, AddrLine0
	rjmp	_XY
_XY1:
	cpi		temp3, 1
	brne	_XY2
	ldi		temp3, AddrLine1
	rjmp	_XY
_XY2:
	cpi		temp3, 2
	brne	_XY3
	ldi		temp3, AddrLine2
	rjmp	_XY
_XY3:
	cpi		temp3, 3
	brne	_XY
	ldi		temp3, AddrLine3
_XY:
	mov		temp, temp3
	add		temp, temp2
	pop		temp3
	ret

;---------------------------------------
;--- LCD Addr2XY
;--- 	input:	temp  = DDRAM Address
;---	output:	temp2 = column [0..19]
;---			temp3 = row [0..3]
;---------------------------------------
LCD_Addr2XY:
	push	temp4
	; temp = [$00..$13] || [$40..$53] || [$14..$27] || [$54..$67]
	; cursor nu nog ergens op de 4e regel?
	cpi		temp, AddrLine3
	brlo	_Addr2
	ldi		temp4, AddrLine3
	ldi		temp3, 3
	rjmp	_Addr
_Addr2:; cursor nu nog ergens op de 2e regel?
	cpi		temp, AddrLine1
	brlo	_Addr3
	ldi		temp4, AddrLine1
	ldi		temp3, 1
	rjmp	_Addr
_Addr3:; cursor nu nog ergens op de 3e regel?
	cpi		temp, AddrLine2
	brlo	_Addr1
	ldi		temp4, AddrLine2
	ldi		temp3, 2
	rjmp	_Addr
_Addr1:; cursor nu nog ergens op de 1e regel
	ldi		temp4, AddrLine0
	ldi		temp3, 0
_Addr:
	;cursor positie resulteren in temp2 & temp3
	mov		temp2, temp
	sub		temp2, temp4
	pop		temp4
	ret





;---------------------------------------
;--- LCD GetCursorXY
;--- De cursor plaatsen op XY(column,row)
;---	output:	temp2 = column [0..19]
;---			temp3 = row [0..3]
;---------------------------------------
LCD_GetCursorXY:
	push	temp
	; huidige adres opvragen in DD/CG-RAM
	rcall	LCD_GetDisplayAddr
	rcall	LCD_Addr2XY
	pop		temp
	ret

;---------------------------------------
;--- De cursor plaatsen op XY(column,row)
;---	input:	temp2 = column [0..19]
;---			temp3 = row [0..3]
;---------------------------------------
LCD_SetCursorXY:
	push	temp
	rcall	LCD_XY2Addr
	rcall	LCD_SetDisplayAddr
	pop		temp
	ret







;---------------------------------------
;--- Een string afbeelden op LCD-display
;---	input:	register Z (R31:R30)= string-adres(*2)
;---------------------------------------
LCD_Print:
	;methode 2: lees uit FLASH/PROGRAM-memory
	lsl		ZL							; Z*2
	rol		ZH
LCD_Print_:
	lpm									; Register R0 <- Program Memory [Z]  (R0 = CharReg)
	adiw	ZL, 1						; Adres in Z-Register verhogen
	mov		temp, CharReg
	cpi		temp, EOS_Symbol
	breq	EOS
	rcall	LCD_LinePrintChar;LCD_Data
	rjmp	LCD_Print_
EOS:
	ret


;---------------------------------------
;--- Een string afbeelden op LCD-display
;--- De cursor wordt zelf verplaatst naar de volgende
;--- logische positie op het scherm. (regel 1,2,3,4 ipv. regel 1,3,2,4)
;---	input:	temp = ASCII-waarde
;---------------------------------------
LCD_LinePrintChar:
	push	temp4;
	push 	temp3;!
	push	temp2;!!					; nieuwe cursor-positie

	clr		temp4						; vlag wissen (cursor niet verplaatsen)
	push	temp;!!!
	rcall	LCD_GetCursorXY
	;--- temp2 = column [0..19]
	;--- temp3 = row [0..3]
	cpi		temp2, 19					; cursor op laatste positie van een regel?
	brne	printChar
	ser		temp4						; vlag zetten als cursor met de hand verplaatst moet worden
printChar:
	pop		temp;!!!
	rcall	LCD_Data					; ASCII-waarde schrijven naar LCD

	tst		temp4
	breq	Exit_LinePrintChar

	clr		temp2						; 1e positie nieuwe regel
	inc		temp3						; volgende regel
	cpi		temp3, 4
	brmi	SetNewLine
	rcall	LCD_ScrollUp				;|\1 De scherminhoud omhoog scrollen
	rjmp	Exit_LinePrintChar			;|/
;	ldi		temp3, 0					;|-2 of  naar de 1e regel overlopen
SetNewLine:
	rcall	LCD_SetCursorXY

Exit_LinePrintChar:
	pop		temp2;!!
	pop		temp3;!
	pop		temp4
	ret


;---------------------------------------
;--- Een hele LCD-regel copiëren naar andere regel
;--- input: temp2 = beginadres src
;---        temp3 = beginadres dest
;---        temp  = aantal tekens n
;---------------------------------------
LCD_CopyLine:
	push	XL							; src
	push	XH							; dest
	push	YL							; n tekens
	push	temp4						; vooruit/achteruit copiëren
	push	temp2

	mov		YL, temp					; aantal tekens te copiëren overnemen naar YL
	; src<dest? dan vanaf src+n beginnen met copy naar dest+n, n--
	; src>dest? dan vanaf src beginnen met copy naar dest, n++
	cp		temp2, temp3
	brmi	CountBack
	brpl	CountForward
	; src = dest
	rjmp	Done_CopyLine
CountBack:
	ser		temp4						; achteruit tellen
	mov		XL, temp2					; XL vullen met het src-sdres
	add		XL, YL
	dec		XL							; XL bevat het src-adres van de 1e te copiëren byte
	mov		XH, temp3					; XH vullen met het dest-adres
	add		XH, YL
	dec		XH							; XH bevat het dest-adres van de 1e te copiëren byte
	rjmp	StartCopy
CountForward:
	clr		temp4						; vooruit tellen
	mov		XL, temp2					; XL bevat het src-adres van de 1e te copiëren byte
	mov		XH, temp3					; XH bevat het dest-adres van de 1e te copiëren byte

StartCopy:
	; huidige cursor-positie opvragen en bewaren
	rcall	LCD_GetDisplayAddr
	push	temp
CopyLoop:
	; plaats cursor op source plaasten (XL)
	mov		temp, XL
	rcall	LCD_SetDisplayAddr
	; teken lezen op cursor-positie
	rcall	LCD_Read_Data
	mov		temp2, temp
	; plaats cursor op dest. plaasten (XH)
	mov		temp, XH
	rcall	LCD_SetDisplayAddr
	; gelezen teken schrijven
	mov		temp, temp2
	rcall	LCD_Data
	; teller op volgende teken plaatsen
	tst		temp4
	brne	CountingBackward
CountingForward:
	inc		XL							; src++
	inc		XH							; dest++
	rjmp	NextCopy
CountingBackward:
	dec		XL							; src--
	dec		XH							; dest--
NextCopy:
	dec		YL							; n--
	brne	CopyLoop
	; cursor-positie herstellen
	pop		temp
	rcall	LCD_SetDisplayAddr

Done_CopyLine:
	pop		temp2
	pop		temp4
	pop		YL
	pop		XH
	pop		XL
	ret

;;---------------------------------------
;;--- Een hele LCD-regel copiëren naar andere regel
;;--- input: temp2 = beginadres src
;;---        temp3 = beginadres dest
;;---------------------------------------
;LCD_CopyLine:
;	push	XL							; src
;	push	XH							; dest
;	push	YL							; 20 tekens
;	push	temp
;	push	temp2
;
;	ldi		YL, 20						; aantal tekens te copiëren (20 per regel)
;	mov		XL, temp2					; XL bevat het src-adres van de 1e te copiëren byte
;	mov		XH, temp3					; XH bevat het dest-adres van de 1e te copiëren byte
;;StartCopy:
;	; huidige cursor-positie opvragen en bewaren
;	rcall	LCD_GetDisplayAddr
;	push	temp
;CopyLoop:
;	; plaats cursor op source plaasten (XL)
;	mov		temp, XL
;	rcall	LCD_SetDisplayAddr
;	; teken lezen op cursor-positie
;	rcall	LCD_Read_Data
;	mov		temp2, temp
;	; plaats cursor op dest. plaasten (XH)
;	mov		temp, XH
;	rcall	LCD_SetDisplayAddr
;	; gelezen teken schrijven
;	mov		temp, temp2
;	rcall	LCD_Data
;	; teller op volgende teken plaatsen
;	inc		XL							; src++
;	inc		XH							; dest++
;	dec		YL							; n--
;	brne	CopyLoop
;	; cursor-positie herstellen
;	pop		temp
;	rcall	LCD_SetDisplayAddr
;
;Done_CopyLine:
;	pop		temp2
;	pop		temp
;	pop		YL
;	pop		XH
;	pop		XL
;	ret

;---------------------------------------
;--- Scroll de LCD-inhoud 1 regel
;---------------------------------------
LCD_ScrollUp:
	push	temp
	push	temp2
	push	temp3
	; 2e regel naar de 1e
	ldi		temp2, AddrLine1
	ldi		temp3, AddrLine0
	ldi		temp, 20
	rcall	LCD_CopyLine
	; 3e regel naar de 2e
	ldi		temp2, AddrLine2
	ldi		temp3, AddrLine1
	ldi		temp, 20
	rcall	LCD_CopyLine
	; 4e regel naar de 3e
	ldi		temp2, AddrLine3
	ldi		temp3, AddrLine2
	ldi		temp, 20
	rcall	LCD_CopyLine
	; 4e regel legen
	ldi		temp2, 0
	ldi		temp3, 3
	rcall	LCD_ClearLineFromXY
	; cursor op begin van 4e regel plaatsen
	ldi		temp2, 0
	ldi		temp3, 3
	rcall	LCD_SetCursorXY
	pop		temp3
	pop		temp2
	pop		temp
	ret




;---------------------------------------
;--- Een regel leegmaken vanaf de 
;--- opgegeven kolom tot aan het einde 
;--- van de regel.
;---	input:	temp2 = column [0..19]
;---			temp3 = row [0..3]
;---------------------------------------
LCD_ClearLineFromXY:
	rcall	LCD_SetCursorXY				; cursor plaatsen
NextPos:
	ldi		temp, ' '					; een spatie....
	rcall	LCD_Data					; ....afbeelden op cursor-positie
	inc		temp2						; volgende kolom
	cpi		temp2, 20
	brlo	NextPos
	ret





;---------------------------------------
;--- Het hele scherm vullen met het teken in temp
;---	input:	temp = ASCII-teken
;---------------------------------------
LCD_Fill:
	push	temp
	push	temp2
	push	temp3

	ldi		temp2, 0					; 1e kolom
	ldi		temp3, 0					; 1e rij
	rcall	LCD_SetCursorXY
NextFill0:
	rcall	LCD_Data					; ....afbeelden op cursor-positie
	inc		temp2						; volgende kolom
	cpi		temp2, 40;20				; de regel loopt over in de 3e regel, 1e positie
	brne	NextFill0
	;
	ldi		temp2, 0					; 1e kolom
	ldi		temp3, 1					; 2e rij
	rcall	LCD_SetCursorXY
NextFill1:
	rcall	LCD_Data					; ....afbeelden op cursor-positie
	inc		temp2						; volgende kolom
	cpi		temp2, 40;20				; de regel loopt over in de 4e regel, 1e positie
	brne	NextFill1
	;
	pop		temp3
	pop		temp2
	pop		temp
	ret



;---------------------------------------
;--- De cursor naar de volgende regel
;--- op het LCD verplaatsen.
;---------------------------------------
LCD_NextLine:
	push	temp
	push	temp2
	push	temp3
	rcall	LCD_GetCursorXY
	;--- temp2 = column [0..19]
	;--- temp3 = row [0..3]
	inc		temp3
	cpi		temp3, 4
	brne	SetNextLine
	; overlopen naar 1e regel
;	ldi		temp3, 0
	; of scherminhoud scrollen
	rcall	LCD_ScrollUp				; De scherminhoud omhoog scrollen
	rjmp	Done_NextLine
SetNextLine:
	;cursor naar de logisch volgende regel verplaasten.
	clr		temp2
	rcall	LCD_SetCursorXY
Done_NextLine:
	pop		temp3
	pop		temp2
	pop		temp
	ret



;---------------------------------------
;--- LCD LineHome
;--- Cursor naar begin van huidige regel
;---------------------------------------
LCD_LineHome:
	push	temp
	push	temp2
	push	temp3
	rcall	LCD_GetCursorXY				; temp2 = column [0..19], temp3 = row [0..3]
	clr		temp2
	rcall	LCD_SetCursorXY
	pop		temp3
	pop		temp2
	pop		temp
	ret


;---------------------------------------
;--- LCD LineEnd
;--- Cursor naar einde tekst op huidige regel
;---------------------------------------
LCD_LineEnd:
	push	XL
	push	temp
	push	temp2
	push	temp3
	push	temp4
	; bepaal vanaf het einde van de regel of
	; het teken nog een spatie is..
	rcall	LCD_GetCursorXY				; temp2 = column [0..19], temp3 = row [0..3]
	clr		temp2
	rcall	LCD_XY2Addr
	mov		XL, temp					; XL = LCD Cursor AC op laatste teken deze regel
	ldi		temp4, 19
	add		XL, temp4
NextEOL:
	mov		temp, XL
	rcall	LCD_SetDisplayAddr
	; teken lezen op cursor-positie
	rcall	LCD_Read_Data
	cpi		temp, ' '
	brne	_nEOL
	dec		XL
	dec		temp4
	brpl	NextEOL
_nEOL:
	mov		temp, XL					; auto-increment herstellen
	rcall	LCD_SetDisplayAddr			;
	mov		temp, XL
	rcall	LCD_Addr2XY					; temp2 = column [0..19], temp3 = row [0..3]
	cpi		temp, 19
	breq	Done_LineEnd
	inc		temp2
	rcall	LCD_SetCursorXY
Done_LineEnd:
	pop		temp4
	pop		temp3
	pop		temp2
	pop		temp
	pop		XL
	ret



LCD_BackSpace:
	push	R2
	push	R3
	push	temp
	push	temp2
	push	temp3
	push	temp4

	;- Lees de huidige LCD cursor positie
	rcall	LCD_GetCursorXY
	;--- temp2 = column [0..19]
	;--- temp3 = row [0..3]
	mov		R2, temp2
	mov		R3, temp3

	;- Bepaal hoeveel tekens er gekopieerd moeten worden
	ldi		temp4, 19+1
	sub		temp4, temp2
	;- Copy 'temp' vanaf 'cursorpositie' naar 'cursorpositie-1'
	; huidige cursorpositie staat nu in temp2,temp3. Converteren naar een LCD DDRAM-adres in temp
	rcall	LCD_XY2Addr
	push	temp					;!!! src. bewaren op de stack
	tst		temp2
	breq	_is0
	dec		temp2						; cursorpositie-1 in temp2,temp3
  _is0:
	rcall	LCD_XY2Addr					; Converteren naar een LCD DDRAM-adres in temp
	mov		temp3, temp					; dest.
	pop		temp2					;!!! src. ophalen van de stack
	mov		temp, temp4					; aantal te copieren tekens
	rcall	LCD_CopyLine

Done_BackSpace:
	; Huidige regel vanaf rechts aanvullen met spaties
	ldi		temp2, 19
	mov		temp3, R3
	rcall	LCD_SetCursorXY
	ldi		temp, ' '
	rcall	LCD_Data
	;- Stel de LCD cursor positie in op huidige-1
	tst		R2
	breq	__is0
	dec		R2
__is0:
	mov		temp2, R2
	mov		temp3, R3
	rcall	LCD_SetCursorXY

	pop		temp4
	pop		temp3
	pop		temp2
	pop		temp
	pop		R3
	pop		R2
	ret


;---------------------------------------
;--- LCD Delete
;---------------------------------------
LCD_Delete:
	push	R2
	push	R3
	push	temp
	push	temp2
	push	temp3
	push	temp4

	;- Lees de huidige LCD cursor positie
	rcall	LCD_GetCursorXY
	;--- temp2 = column [0..19]
	;--- temp3 = row [0..3]
	mov		R2, temp2
	mov		R3, temp3

	;- Bepaal hoeveel tekens er gekopieerd moeten worden
	ldi		temp4, 19
	sub		temp4, temp2
	;- Copy 'temp' vanaf 'cursorpositie+1' naar 'cursorpositie'
	; huidige cursorpositie staat nu in temp2,temp3. Converteren naar een LCD DDRAM-adres in temp
	rcall	LCD_XY2Addr
	push	temp						;!!! dest. bewaren op de stack
	inc		temp2						; cursorpositie+1 in temp2,temp3
	rcall	LCD_XY2Addr					; Converteren naar een LCD DDRAM-adres in temp
	mov		temp2, temp					; src.
	pop		temp3						;!!! dest. ophalen van de stack
	mov		temp, temp4					; aantal te copieren tekens
	rcall	LCD_CopyLine

Done_Delete:
	; Huidige regel vanaf rechts aanvullen met spaties
	ldi		temp2, 19
	mov		temp3, R3
	rcall	LCD_SetCursorXY
	ldi		temp, ' '
	rcall	LCD_Data
	;- Herstel de LCD cursor positie
	mov		temp2, R2
	mov		temp3, R3
	rcall	LCD_SetCursorXY

	pop		temp4
	pop		temp3
	pop		temp2
	pop		temp
	pop		R3
	pop		R2
	ret


;---------------------------------------
;--- LCD Insert
;--- input: temp = in te voegen teken
;---------------------------------------
LCD_Insert:
	push	R2
	push	R3
	push	R4
	mov		R4, temp
	push	temp2
	push	temp3
	push	temp4
	;- Lees de huidige LCD cursor positie
	rcall	LCD_GetCursorXY
	;--- temp2 = column [0..19]
	;--- temp3 = row [0..3]
	mov		R2, temp2
	mov		R3, temp3

	;- Bepaal hoeveel tekens er gekopieerd moeten worden
	ldi		temp4, 19
	sub		temp4, temp2
	breq	Done_Insert
	;- Copy 'temp' vanaf 'cursorpositie' naar 'cursorpositie+1'
	; huidige cursorpositie staat nu in temp2,temp3. Converteren naar een LCD DDRAM-adres in temp
	rcall	LCD_XY2Addr
	push	temp						;!!! src. bewaren op de stack
	inc		temp2						; cursorpositie+1 in temp2,temp3
	rcall	LCD_XY2Addr					; Converteren naar een LCD DDRAM-adres in temp
	mov		temp3, temp					; dest.
	pop		temp2						;!!! src. ophalen van de stack
	mov		temp, temp4					; aantal te copieren tekens
	rcall	LCD_CopyLine

Done_Insert:
	; Huidige cursorpositie vullen met het af te beelden teken
	mov		temp2, R2
	mov		temp3, R3
	rcall	LCD_SetCursorXY
	mov		temp, R4

	rcall	LCD_LinePrintChar
;	rcall	LCD_Data
;	;- Herstel de LCD cursor positie
;	mov		temp2, R2
;	mov		temp3, R3
;	rcall	LCD_SetCursorXY

	pop		temp4
	pop		temp3
	pop		temp2
	mov		temp, R4
	pop		R4
	pop		R3
	pop		R2
	ret



;---------------------------------------
;--- LCD Arrow
;--- input: temp = richting cursorbeweging
;---               ==0 => omhoog
;---               ==1 => omlaag
;---               ==2 => rechts
;---               ==3 => links
;---------------------------------------
LCD_Arrow:
	push	temp2
	push	temp3
	rcall	LCD_GetCursorXY
	;--- temp2 = column [0..19]
	;--- temp3 = row [0..3]
ArrowUp:
	cpi		temp,0
	brne	ArrowDn
	cpi		temp3, 0
	breq	Done_Arrow
	dec		temp3
	rjmp	MoveCursor
ArrowDn:
	cpi		temp,1
	brne	ArrowR
	cpi		temp3, 3
	breq	Done_Arrow
	inc		temp3
	rjmp	MoveCursor
ArrowR:
	cpi		temp,2
	brne	ArrowL
	cpi		temp2, 19
	breq	Done_Arrow
	inc		temp2
	rjmp	MoveCursor
ArrowL:
	cpi		temp,3
	brne	Done_Arrow
	cpi		temp2, 0
	breq	Done_Arrow
	dec		temp2
MoveCursor:
	rcall	LCD_SetCursorXY
Done_Arrow:
	pop		temp3
	pop		temp2
	ret









;---------------------------------------
;--- Een Hex-Nibble afbeelden
;---	input:	temp bits 3-0 = nibble
;---------------------------------------
LCD_HexNibble:
	push	temp2
	andi	temp, $0F
	; naar ASCII converteren
	cpi		temp, $0A
	brsh	isHex
	; een getal van 0-9
	ldi		temp2, $30
	rjmp	isBCD
isHex:
	; een getal van A-F
	ldi		temp2, $41-10
isBCD:
	add		temp, temp2
	; het teken afbeelden op LCD
	rcall	LCD_LinePrintChar ;LCD_Data
	pop		temp2
	ret


;---------------------------------------
;--- Een Hex-Byte afbeelden
;---	input:	temp b7-4, b3-0 = byte
;---------------------------------------
LCD_HexByte:
	push	temp
	swap	temp
	rcall	LCD_HexNibble
	pop		temp
	rcall	LCD_HexNibble
	ret


;---------------------------------------
;--- Een Hex-Word afbeelden
;---	input:	waarde in Z = word-waarde
;---------------------------------------
LCD_HexWord:
	push	temp
	mov		temp, ZH
	rcall	LCD_HexByte
	mov		temp, ZL
	rcall	LCD_HexByte
	pop	temp
	ret


;---------------------------------------
;--- Een Decimale Byte afbeelden
;---	input:	temp = byte
;---------------------------------------
LCD_DecByte:
	push	ZH
	push	ZL
	push	temp
	push	temp3
	; 3-cijfer BCD getallen in ZH:ZL
	clr		ZL
	clr		ZH
	mov		temp3, temp
	;/100
Div100:
	cpi		temp3, 100
	brlo	Div10
	subi	temp3, 100
	inc		ZH
	rjmp	Div100
Div10:
	;/10
	cpi		temp3, 10
	brlo	Div1
	subi	temp3, 10
	inc		ZL
	rjmp	Div10
Div1:
	swap	ZL
	;/1
	add		ZL, temp3
	; Nu afbeelden op LCD
	clr		temp3						; tbv. leading 0's niet afbeelden
	mov		temp, ZH
	cpi		temp ,0						; Is dit een leading 0?
	breq	Leading0					; ja? dan dit getal overslaan
	ori		temp, $30					; getal in temp naar ASCII converteren
	rcall	LCD_LinePrintChar ;LCD_Data
	ser		temp3
Leading0:
	mov		temp, ZL
	swap	temp
	andi	temp, $0F
	tst		temp3						; nog leading 0's testen?
	brne	NotLeading					; nee? dan gewoon afbeelden dit getal
	cpi		temp ,0						; Is dit een leading 0?
	breq	Leading0_2					; ja? dan dit getal overslaan
NotLeading:
	ori		temp, $30
	rcall	LCD_LinePrintChar ;LCD_Data
Leading0_2:
	mov		temp, ZL
	andi	temp, $0F
	ori		temp, $30
	rcall	LCD_LinePrintChar ;LCD_Data
	pop		temp3
	pop		temp
	pop		ZL
	pop		ZH
	ret



;---------------------------------------
;--- De 2 regels tekst in het splashScreen afbeelden
;---------------------------------------
SplashText0:	.db "   AVR-ASM Code   ", EOS_Symbol
SplashText1:	.db "  KB,LCD  v0.999  ", EOS_Symbol
SplashText:
	;--- temp2 = column [0..19]
	;--- temp3 = row [0..3]
	push	temp
	push	temp2
	push	temp3
	ldi		temp2, 1
	ldi		temp3, 1
	rcall	LCD_SetCursorXY
	ldi		ZL, low(2*SplashText0)
	ldi		ZH, high(2*SplashText0)
	rcall	LCD_Print_
	ldi		temp2, 1
	ldi		temp3, 2
	rcall	LCD_SetCursorXY
	ldi		ZL, low(2*SplashText1)
	ldi		ZH, high(2*SplashText1)
	rcall	LCD_Print_
	pop		temp3
	pop		temp2
	pop		temp
	ret

;---------------------------------------
;--- Een intro direct na een RESET
;--- !!!!!!!deze proc is uitgebreid met een LED-knipper voor de show.!!!!!!!!
;---------------------------------------
LCD_SplashScreen:
	rcall	delay150ms					; pauze inlassen
	; LCD-scherm wissen
	rcall	LCD_Clear
	; temp2 x het intro laten zien
	ldi		temp2, 1
SplashStart:
	push	temp2				;!!!! register temp2 op stack pushen

	rcall	LCD_Clear
	rcall	SplashText
	rcall	delay150ms					; pauze inlassen
	; pixels vermeerderen
	ldi		temp, 0						; CG teken 0 (1 pixel blokje)
SplashLoop2:
	rcall	LCD_Fill
	rcall	SplashText
	rcall	delay150ms					; pauze inlassen
	sbi		LED_PORT, LED_PIN			; LED aan !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	inc		temp
	cpi		temp, 5
	brne	SplashLoop2					; 
	; pixels verminderen
	ldi		temp, 4						; CG teken 4 (vol blokje)
SplashLoop1:
	rcall	LCD_Fill
	rcall	SplashText
	rcall	delay150ms					; pauze inlassen
	cbi		LED_PORT, LED_PIN			; LED uit !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	dec		temp
	brpl	SplashLoop1

	pop		temp2				;!!!! register temp2 van stack poppen
	dec		temp2
	cpi		temp2, 0
	brne	SplashStart

	rcall	LCD_Clear
	rcall	SplashText
	rcall	delay1_5s					; pauze inlassen
	rcall	LCD_Clear
	ret







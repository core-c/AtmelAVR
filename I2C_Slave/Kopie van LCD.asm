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
;*** Als RW = 1, en RS = 0, dan kan de busy-flag gelezen worden.
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


;--- INCLUDE FILES -------------------------
;.include "8535def.inc"						; Atmel AVR-AT90S8535 definities
;.include "System.inc"						; Instellen I/O-poorten


;--- REGISTER ALIASSEN ---------------------
.def CharReg	= R0						; tbv. LPM-instructie
;.def temp		= R16						; Een register voor algemeen gebruik
;.def etemp		= R17						;  "
.def temp3		= R21						;  "
.def temp4		= R22						;  "
.def delay0		= R23						; Een register alleen tbv delays
.def delay1		= R24						;  "
.def delay2		= R25						;  "


;--- CONSTANTEN ----------------------------
.equ EOS_Symbol	= '$'						; End-Of-String teken

;--- Begin-adressen van elke regel ---------
.equ AddrLine0	= $00
.equ AddrLine1	= $40
.equ AddrLine2	= $14
.equ AddrLine3	= $54

;--- Toegekende poorten & pinnen -----------
.equ LCD_CTRL_PORT	= PORTA					; De control-port (alleen als OUTPUT)
.equ LCD_CTRL_DDR	= DDRA
.equ LCD_RS			= PA5					; RS op pin 5 van poort A
.equ LCD_RW			= PA6					; RW op pin 6 van poort A
.equ LCD_E			= PA7					; E op pin 7 van poort A
;
.equ LCD_DATA_PORT	= PORTC					; De data-port DB7-0 (INPUT/OUTPUT)
.equ LCD_DATA_DDR	= DDRC
.equ LCD_DATA_IN	= PINC
.equ LCD_BUSY		= PC7					; Busy-Flag op pin 7 van poort C (=DB7)
;
.equ RS_COMMAND	= 0							; LCD_RS-bit bij commando's
.equ RS_DATA	= 1							; LCD-RS-bit bij data
.equ RW_WRITE	= 0							; LCD_RW-bit bij schrijven naar LCD-geheugen
.equ RW_READ	= 1							; LCD_RW-bit bij lezen van LCD-geheugen

;--- Toegekende bits tbv. commando's -------
.equ CMD_DDRAMAddress		= (1<<7)
.equ CMD_CGRAMAddress		= (1<<6)
.equ CMD_FunctionSet		= (1<<5)
.equ CMD_CursorDisplayShift	= (1<<4)
.equ CMD_DisplayMode		= (1<<3)
.equ CMD_EntryMode			= (1<<2)
.equ CMD_CursorHome			= (1<<1)
.equ CMD_Clear				= (1<<0)

;--- Geldige data-bits bij commando's ------
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



.include "LCD_constants.asm"



;---------------------------------------
;--- Pauze routine's.
;---  1us	=>      7.3728 clockcycles
;---  100us	=>    737.28   clockcycles
;---  15ms	=> 110592      clockcycles
;---  4.1ms =>  30288.48   clockcycles
;---------------------------------------
;delay1us:	; @7.372800MHz
;	; een rcall instructie neemt 3 cycles in beslag	|	  1*3 =   3 +
;	nop									; 1 cycle	>	  1*1 =	  1 +
;	ret									; 4 cycles	|	  1*4 =	  4
;										;				-------------
;										;				          8 clockcycles
delay2us:	; @4.000000MHz
	nop
	ret





;---------------------------------------
;delay100us:	; @7.372800MHz				;100 micro-seconde = 0.1 milli seconde
;	; een rcall instructie neemt 3 cycles in beslag	|	  1*3 =   3 +
;	ldi		delay0, 243					; 1 cycle	|	  1*1 =   1 +
;innerloop100us:							;			|
;	dec		delay0						; 1 cycle	|	243*1 = 243 +
;	brne	innerloop100us				; 2 cycles	>	242*2 = 484 +	;241 x wordt de branche genomen (springen = 2 cycles)
;										; 1 cycle	|	  1*1 =   1 +	;bij de laatste branche wordt niet gesprongen (1 cycle)
;	nop									; 1 cycle	|	  1*1 =	  1 +
;	nop									; 1 cycle	|	  1*1 =	  1 +
;	ret									; 4 cycles	|	  1*4 =   4
;										;				-------------
;										;				        738 clockcycles
delay100us:	; @4.000000MHz
	; een rcall instructie neemt 3 cycles in beslag	|	  1*3 =   3 +
	ldi		delay0, 131					; 1 cycle	|	  1*1 =   1 +
innerloop100us:							;			|
	dec		delay0						; 1 cycle	|	131*1 = 131 +
	brne	innerloop100us				; 2 cycles	>	130*2 = 260 +	;132 x wordt de branche genomen (springen = 2 cycles)
										; 1 cycle	|	  1*1 =   1 +	;bij de laatste branche wordt niet gesprongen (1 cycle)
	ret									; 4 cycles	|	  1*4 =   4
										;				-------------
										;				        400 clockcycles






;---------------------------------------
;delay15ms:	; @7.372800MHz
;	; een rcall instructie neemt 3 cycles in beslag	|	    1*3 =      3 +	   \
;	ldi		delay1, 149					; 1 cycle	|	    1*1 =      1 +		|
;innerloop15ms:							;			|							|
;	rcall	delay100us					; 3 cycles	|	149*738 = 109962 +		|
;	dec		delay1						; 1 cycle	|	  149*1 =    149 +		|
;	brne	innerloop15ms				; 2 cycles	>	  148*2 =    296 +		|
;										; 1 cycle	|	    1*1 =      1 +		|
;										;				------------------		|
;										;				          110412		>	110412 +
;	;180 cycles to go....														|	   180 +
;	ldi		delay1, 58					; 1 cycle	|	    1*1 =      1 +		|	--------
;innerloop15ms_:							;			|							|	110592 cycles
;	dec		delay1						; 1 cycle	|	   58*1 =     58 +		|
;	brne	innerloop15ms_				; 2 cycles	>	   57*2 =    114 +		|
;										; 1 cycle	|	    1*1 =      1 +		|
;	nop									; 1 cycle	|	    1*1 =	   1 +		|
;	nop									; 1 cycle	|	    1*1 =	   1 +		|
;	ret									; 4 cycles	|	    1*4 =      4		|
;										;				------------------		|
;										;				             180	   /
delay15ms:	; @4.000000MHz => 60000 clockcycles
	; een rcall instructie neemt 3 cycles in beslag	|	    1*3 =      3 +	   \
	ldi		delay1, 148					; 1 cycle	|	    1*1 =      1 +		|
innerloop15ms:							;			|							|
	rcall	delay100us					; 3 cycles	|	148*400 =  59200 +		|
	dec		delay1						; 1 cycle	|	  148*1 =    148 +		|
	brne	innerloop15ms				; 2 cycles	>	  147*2 =    294 +		|
										; 1 cycle	|	    1*1 =      1 +		|
										;				------------------		|
										;				          59650			>	 59650 +
	;350 cycles to go....														|	   350 +
	ldi		delay1, 115					; 1 cycle	|	    1*1 =      1 +		|	--------
innerloop15ms_:							;			|							|	 60000 cycles
	dec		delay1						; 1 cycle	|	  115*1 =    115 +		|
	brne	innerloop15ms_				; 2 cycles	>	  114*2 =    228 +		|
										; 1 cycle	|	    1*1 =      1 +		|
	nop									; 1 cycle	|	    1*1 =	   1 +		|
	ret									; 4 cycles	|	    1*4 =      4		|
										;				------------------		|
										;				             350	   /






;---------------------------------------
;delay4_1ms:	; @7.372800MHz
;	; een rcall instructie neemt 3 cycles in beslag	|	    1*3 =      3 +	   \
;	ldi		delay1, 40					; 1 cycle	|	    1*1 =      1 +		|
;innerloop4_1ms:							;			|							|
;	rcall	delay100us					; 3 cycles	|	 40*738 =  29520 +		|
;	dec		delay1						; 1 cycle	|	   40*1 =     40 +		|
;	brne	innerloop4_1ms				; 2 cycles	>	   39*2 =     78 +		|
;										; 1 cycle	|	    1*1 =      1 +		|
;										;				------------------		|
;										;				           29643		>	 29643 +
;	;646 cycles to go....														|	   646 +
;	ldi		delay1, 213					; 1 cycle	|	    1*1 =      1 +		|	--------
;innerloop4_1ms_:						;			|							|	 30289 cycles
;	dec		delay1						; 1 cycle	|	  213*1 =    213 +		|
;	brne	innerloop15ms_				; 2 cycles	>	  212*2 =    424 +		|
;										; 1 cycle	|	    1*1 =      1 +		|
;	nop									; 1 cycle	|	    1*1 =	   1 +		|
;	nop									; 1 cycle	|	    1*1 =	   1 +		|
;	nop									; 1 cycle	|	    1*1 =	   1 +		|
;	ret									; 4 cycles	|	    1*4 =      4		|
;										;				------------------		|
;										;				             646	   /
delay4_1ms:	; @4.000000MHz = 16400 clockcycles
	; een rcall instructie neemt 3 cycles in beslag	|	    1*3 =      3 +	   \
	ldi		delay1, 40					; 1 cycle	|	    1*1 =      1 +		|
innerloop4_1ms:							;			|							|
	rcall	delay100us					; 3 cycles	|	 40*400 =  16000 +		|
	dec		delay1						; 1 cycle	|	   40*1 =     40 +		|
	brne	innerloop4_1ms				; 2 cycles	>	   39*2 =     78 +		|
										; 1 cycle	|	    1*1 =      1 +		|
										;				------------------		|
										;				           16123		>	 16123 +
	;277 cycles to go....														|	   277 +
	ldi		delay1, 92					; 1 cycle	|	    1*1 =      1 +		|	--------
innerloop4_1ms_:						;			|							|	 16400 cycles
	dec		delay1						; 1 cycle	|	   92*1 =     92 +		|
	brne	innerloop15ms_				; 2 cycles	>	   91*2 =    182 +		|
										; 1 cycle	|	    1*1 =      1 +		|
	nop									; 1 cycle	|	    1*1 =	   1 +		|
	ret									; 4 cycles	|	    1*4 =      4		|
										;				------------------		|
										;				             277	   /
	





;---------------------------------------
;delay1ms:	; @7.372800MHz
;	; een rcall instructie neemt 3 cycles in beslag	|	    1*3 =      3 +	   \
;	ldi		delay1, 9					; 1 cycle	|	    1*1 =      1 +		|
;innerloop1ms:							;			|							|
;	rcall	delay100us					; 3 cycles	|	  9*738 =   6642 +		|
;	dec		delay1						; 1 cycle	|	    9*1 =      9 +		|
;	brne	innerloop1ms				; 2 cycles	>	    8*2 =     16 +		|
;										; 1 cycle	|	    1*1 =      1 +		|
;										;				------------------		|
;										;				            6672	    >	 6672 +
;	;701 cycles to go....				;										|	  702 +
;	ldi		delay1, 233					; 1 cycle	|	    1*1 =      1 +		|	-----
;innerloop1ms_:							;			|							|	 7374 cycles (1 extra mag wel;)
;	dec		delay1						; 1 cycle	|	  233*1 =    233 +		|
;	brne	innerloop1ms_				; 2 cycles	>	  232*2 =    464 +		|
;	ret									; 4 cycles	|	    1*4 =      4		|
;										;				------------------		|
;										;				             702	   /
delay1ms:	; @4.000000MHz => 4000 clockcycles
	; een rcall instructie neemt 3 cycles in beslag	|	    1*3 =      3 +	   \
	ldi		delay1, 9					; 1 cycle	|	    1*1 =      1 +		|
innerloop1ms:							;			|							|
	rcall	delay100us					; 3 cycles	|	  9*400 =   3600 +		|
	dec		delay1						; 1 cycle	|	    9*1 =      9 +		|
	brne	innerloop1ms				; 2 cycles	>	    8*2 =     16 +		|
										; 1 cycle	|	    1*1 =      1 +		|
										;				------------------		|
										;				            3630	    >	 3630 +
	;370 cycles to go....				;										|	  370 +
	ldi		delay1, 122					; 1 cycle	|	    1*1 =      1 +		|	-----
innerloop1ms_:							;			|							|	 4000 cycles
	dec		delay1						; 1 cycle	|	  122*1 =    122 +		|
	brne	innerloop1ms_				; 2 cycles	>	  121*2 =    242 +		|
										; 1 cycle	|	    1*1 =      1 +		|
	ret									; 4 cycles	|	    1*4 =      4		|
										;				------------------		|
										;				             370	   /






;---------------------------------------
delaySplash:
	ldi		delay2, 10					; pauze tbv. splashscreen direct na RESET
innerloopSplash:
	rcall	delay15ms
	dec		delay2
	brne	innerloopSplash
	ret




;---------------------------------------
;--- MACRO'S
;---------------------------------------
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
;---	input:	etemp = DDR waarde
;---			temp3 = poort waarde
;---------------------------------------
LCD_SetDATAPort:
	push	temp
	ldi		temp, PORT_AS_INPUT
	out		LCD_DATA_DDR, temp
	ldi		temp, INPUT_PORT_TRIS
	out		LCD_DATA_PORT, temp
	out		LCD_DATA_DDR, etemp
	out		LCD_DATA_PORT, temp3
	pop		temp
	ret



;---------------------------------------
;--- Wacht op busy-signaal
;---------------------------------------
LCD_WaitWhileBusy:
	push	temp
	push	etemp
	push	temp3
	;
	ldi		etemp, PORT_AS_INPUT
	ldi		temp3, INPUT_PORT_TRIS
	rcall	LCD_SetDATAPort
	;
    cbi		LCD_CTRL_PORT, LCD_RS		; RS = 0 (commando)
    sbi		LCD_CTRL_PORT, LCD_RW		; R/W = 1 (lezen)
    sbi		LCD_CTRL_PORT, LCD_E		; E = 1
;	rcall	delay1us					; 1-2 us wachten
	rcall	delay2us					; 2 us wachten @4.000000MHz
WaitForBit0:
	in		etemp, LCD_DATA_IN
	sbrc	etemp, LCD_BUSY				; zolang de BUSY-flag=1....
	rjmp	WaitForBit0					; ....wachten
    cbi		LCD_CTRL_PORT, LCD_E		; E = 0
    cbi		LCD_CTRL_PORT, LCD_RW		; R/W = 0 (schrijven)
	;
	ldi		etemp, PORT_AS_OUTPUT
	ldi		temp3, 0
	rcall	LCD_SetDATAPort
	;
	pop		temp3
	pop		etemp
	pop		temp
	ret



;---------------------------------------
;--- Schrijf commando
;---	input:	temp = waarde
;---------------------------------------
LCD_Command:
	rcall	LCD_WaitWhileBusy
	cbi		LCD_CTRL_PORT, LCD_RS		; RS = 0 (commando)
    cbi		LCD_CTRL_PORT, LCD_RW		; R/W = 0 (schrijven)
	LCD_Send temp						; Macro
	; 10 ms wachten na zenden COMMAND (4bits-IF)
	ret



;---------------------------------------
;--- Schrijf data
;---	input:	temp = waarde
;---------------------------------------
LCD_Data:
	rcall	LCD_WaitWhileBusy
	sbi		LCD_CTRL_PORT, LCD_RS		; RS = 1 (data)
    cbi		LCD_CTRL_PORT, LCD_RW		; R/W = 0 (schrijven)
	LCD_Send temp						; Macro
	; 1 ms wachten na zenden DATA (4bits-IF)
	ret



;---------------------------------------
;--- Een string afbeelden op LCD-display
;---	input:	register Z (R31:R30)= string-adres
;---------------------------------------
LCD_Print:
	;methode 2: lees uit FLASH/PROGRAM-memory
	lpm									; Register R0 <- Program Memory [Z]  (R0 = CharReg)
	adiw	ZL, 1						; Adres in Z-Register verhogen
	mov		temp, CharReg
	cpi		temp, EOS_Symbol
	breq	EOS
	rcall	LCD_Data
	rjmp	LCD_Print
;	;methode 1: lees uit EEPROM-memory
;	ld		temp, Z+
;	cpi		temp, EOS_Symbol
;	breq	EOS
;	rcall	LCD_Data
;	rjmp	LCD_Print
EOS:
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
LCD_FunctionSet_TestBUSYflag:
	rcall	LCD_WaitWhileBusy
LCD_FunctionSet:
	andi	temp, MASK_FunctionSet
	ori		temp, CMD_FunctionSet
	;
	cbi		LCD_CTRL_PORT, LCD_RS		; RS = 0 (commando)
    cbi		LCD_CTRL_PORT, LCD_RW		; R/W = 0 (schrijven)
	LCD_Send temp						; Macro
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
;--- LCD-GetAddrCounter
;--- Resulteer de adres-counter waarde (DDRAM/CGRAM).
;---	output:	temp bit6-0 : DDRAM/CGRAM adres
;---			Carry-Flag	: BUSY-flag LCD
;---------------------------------------
LCD_GetAddrCounter:
	push	etemp
	push	temp3

	ldi		etemp,PORT_AS_INPUT
	ldi		temp3,INPUT_PORT_TRIS
	rcall	LCD_SetDATAPort
	;
    cbi		LCD_CTRL_PORT, LCD_RS		; RS = 0 (commando)
    sbi		LCD_CTRL_PORT, LCD_RW		; R/W = 1 (lezen)
    sbi		LCD_CTRL_PORT, LCD_E
;	rcall	delay1us					; 1-2 us wachten
	rcall	delay2us					; 2 us wachten @4.000000MHz
	in		temp, LCD_DATA_IN
    cbi		LCD_CTRL_PORT, LCD_E
	;
	ldi		etemp,PORT_AS_OUTPUT
	ldi		temp3,0
	rcall	LCD_SetDATAPort

	mov		etemp, temp					; bit7 van register temp naar de carry
	lsl		etemp						;
	andi	temp, ~LCD_BUSY				; busy-flag strippen (bitwise not)

	pop		temp3
	pop		etemp
	ret



;---------------------------------------
;--- LCD-Init
;---------------------------------------
LCD_Init:
	; AVR-poorten als output instellen
	rcall	LCD_SetCTRLPins
	;
	ldi		etemp,PORT_AS_OUTPUT
	ldi		temp3,0
	rcall	LCD_SetDATAPort
	;
	; instellen op 8-bits interface
	; moet 3x gebeuren met pauzes ertussen....
	rcall	delay15ms					; 15 milli-seconde pauze
	rcall	delay15ms					; 15 milli-seconde pauze
	;
    ldi		temp, DATA_LEN_8			; als 8-bit IF instellen
	rcall	LCD_FunctionSet
	;
	rcall	delay4_1ms					; 4.1 milli-seconde pauze
	;
    ldi		temp, DATA_LEN_8			; als 8-bit IF instellen
	rcall	LCD_FunctionSet
	;
	rcall	delay100us					; 100 micro-seconde pauze
	;
    ldi		temp, DATA_LEN_8			; als 8-bit IF instellen
	rcall	LCD_FunctionSet
	; vanaf nu kan de BUSY-flag worden afgevraagd....
	;
	; Aantal regels en font instellen
    ldi		temp, (DATA_LEN_8 | LINE_COUNT_2 | FONT_5x7)
	rcall	LCD_FunctionSet_TestBUSYflag
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
;--- De cursor plaatsen op XY(column,row)
;---	input:	etemp = column (0..19)
;---			temp3 = row/line-adres
;---------------------------------------
LCD_CursorXY:
	push	temp
	mov		temp, temp3
	add		temp, etemp
	rcall	LCD_SetDisplayAddr
	pop		temp
	ret




;---------------------------------------
;--- Een regel leegmaken vanaf de 
;--- opgegeven kolom tot aan het einde 
;--- van de regel.
;---	input:	etemp = column (0..19)
;---			temp3 = row/line-adres
;---------------------------------------
LCD_ClearLineFromXY:
	rcall	LCD_CursorXY				; cursor plaatsen
NextPos:
	ldi		temp, ' '					; een spatie....
	rcall	LCD_Data					; ....afbeelden op cursor-positie
	inc		etemp						; volgende kolom
	cpi		etemp, 20
	brlo	NextPos
	ret



;---------------------------------------
;--- Het hele scherm vullen met het teken in temp
;---	input:	temp = ASCII-teken
;---------------------------------------
LCD_Fill:
	push	temp
	push	etemp
	push	temp3

	ldi		etemp, 0
	ldi		temp3, AddrLine0
	rcall	LCD_CursorXY
NextFill0:
	rcall	LCD_Data					; ....afbeelden op cursor-positie
	inc		etemp						; volgende kolom
	cpi		etemp, 40;20				; de regel loopt over in de 3e regel, 1e positie
	brne	NextFill0
	;
	ldi		etemp, 0
	ldi		temp3, AddrLine1
	rcall	LCD_CursorXY
NextFill1:
	rcall	LCD_Data					; ....afbeelden op cursor-positie
	inc		etemp						; volgende kolom
	cpi		etemp, 40;20				; de regel loopt over in de 4e regel, 1e positie
	brne	NextFill1
	;
	pop		temp3
	pop		etemp
	pop		temp
	ret



;---------------------------------------
;--- Een zelf-gedefinieerd teken in RAM plaatsen
;---	input:	etemp = adres (0..7) in LCD-RAM
;---			Z = adres van teken-patroon (8 bytes lang) in AVR-program-memory
;---------------------------------------
LCD_CustomCharacter:
	mov		temp, etemp
	lsl		temp						; LCD-RAM adres * 8
	lsl		temp
	lsl		temp
	rcall	LCD_SetCharGenAddr
	; nu de 8 bytes van het patroon overzenden
	lsl		ZL							; Eerst het adres x2 tbv. de LPM-instructie....
	rol		ZH
	ldi		etemp, 8					; 8 bytes overbrengen naar LCD-RAM
NextChar:
	lpm									; R0 (=CharReg) krijgt de waarde van de byte op adres [Z]
	adiw	ZL,1						; Z-register verhogen
	mov		temp, CharReg				; R0 = CharReg
	rcall	LCD_Data
	dec		etemp
	brne	NextChar
	; DDRAM adresseren ipv. CGRAM
	ldi		temp, 0
	rcall	LCD_SetDisplayAddr
	ret









;---------------------------------------
;--- Een Hex-Nibble afbeelden
;---	input:	temp bits 3-0 = nibble
;---------------------------------------
LCD_HexNibble:
	push	etemp
	andi	temp, $0F
	; naar ASCII converteren
	cpi		temp, $0A
	brsh	isHex
	; een getal van 0-9
	ldi		etemp, $30
	rjmp	isBCD
isHex:
	; een getal van A-F
	ldi		etemp, $41-10
isBCD:
	add		temp, etemp
	; het teken afbeelden op LCD
	rcall	LCD_Data
	pop		etemp
	ret


;---------------------------------------
;--- Een Hex-Byte afbeelden
;---	input:	temp b7-3, b3-0 = byte
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
;--- Een intro direct na een RESET
;---------------------------------------
;SplashTxt:	.db	"De Stoel LCD", EOS_Symbol
LCD_SplashScreen:
	rcall	delaySplash					; pauze inlassen
	; LCD-scherm wissen
	rcall	LCD_Clear
	; etemp x het intro laten zien
	ldi		etemp, 3
SplashStart:
	push	etemp				;!!!! register etemp op stack pushen

	rcall	LCD_Clear
	rcall	delaySplash					; pauze inlassen
	; pixels vermeerderen
	ldi		temp, 0						; CG teken 0 (1 pixel blokje)
SplashLoop2:
	rcall	LCD_Fill
	rcall	delaySplash					; pauze inlassen
	inc		temp
	cpi		temp, 5
	brne	SplashLoop2					; 
	; pixels verminderen
	ldi		temp, 4						; CG teken 4 (vol blokje)
SplashLoop1:
	rcall	LCD_Fill
	rcall	delaySplash					; pauze inlassen
	dec		temp
	cpi		temp, $FF
	brne	SplashLoop1					;

	pop		etemp				;!!!! register etemp van stack poppen
	dec		etemp
	cpi		etemp, 0
	brne	SplashStart

	rcall	delaySplash					; pauze inlassen
	rcall	LCD_Clear
	ret



LCD_Initialize:
	; LCD-Display initialiseren
	rcall	LCD_Init

	; De zelf-gedefinieerde tekens uploaden naar het LCD
	; register temp bits 5..0 bevatten het CGRAM adres
	ldi		etemp, 0					; |
	ldi		ZL, low(CChar0)
	ldi		ZH, high(CChar0)
	rcall	LCD_CustomCharacter
	ldi		etemp, 1					; ||
	ldi		ZL, low(CChar1)
	ldi		ZH, high(CChar1)
	rcall	LCD_CustomCharacter
	ldi		etemp, 2					; |||
	ldi		ZL, low(CChar2)
	ldi		ZH, high(CChar2)
	rcall	LCD_CustomCharacter
	ldi		etemp, 3					; ||||
	ldi		ZL, low(CChar3)
	ldi		ZH, high(CChar3)
	rcall	LCD_CustomCharacter
	ldi		etemp, 4					; |||||
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
	ret
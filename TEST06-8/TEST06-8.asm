
;********************************************************************************
;***
;***  Een implementatie voor een 8-bit aansturing van het LED-display.
;***
;***	LED-Display		AVR
;***	--------------	----------------
;***	1	Vss		-> 	GND 
;***	2	Vcc		->	5V 
;***	3	Vee		->	GND of naar een potmeter
;***	4	RS		->	PA5
;***	5	RW		->	PA6
;***	6	E		->	PA7
;***	7	DB0		->	PC0 \
;***	8	DB1		->	PC1  |
;***	9	DB2		->	PC2  |
;***	10	DB3		->	PC3   \ data lijnen (OUTPUT)
;***	11	DB4		->	PC4   /
;***	12	DB5		->	PC5  |
;***	13	DB6		->	PC6  |
;***	14	DB7		->	PC7 /
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
;*** Bij onze 8-bits aansturing wordt de RW pin echter normaal aangesloten.
;*** Er zijn 2 pauze routines gedefinieerd, een korte 50 micro-seconde pauze en
;*** een langere 5 milli-seconde pauze. Deze pauze-routines zijn afgestemd op een
;*** 7.3728MHz AVR.
;***
;*** registergebruik: R0 wordt gebruikt in samenhang met de LPM-instructie.
;***                  R30:R31 = het Z-Register
;***
;********************************************************************************


.include "8535def.inc"


;--- REGISTER ALIASSEN ---------------------
.def CharReg	= R0						; tbv. LPM-instructie
.def temp		= R17						; Een register voor algemeen gebruik
.def tempL		= R18						; Een register voor algemeen gebruik
.def temp2		= R19						; Een register voor algemeen gebruik
.def temp3		= R20						; Een register voor algemeen gebruik
.def temp4		= R21						; Een register voor algemeen gebruik
.def delay0		= R22						; Een register alleen tbv delays
.def delay1		= R23						; Een register alleen tbv delays


;--- CONSTANTEN ----------------------------
.equ EOS_Symbol	= '$'						; End-Of-String teken

;--- Begin-adressen van elke regel ---------
.equ AddrLine0	= $00
.equ AddrLine1	= $40
.equ AddrLine2	= $14
.equ AddrLine3	= $54

;--- Poorten instellen ---------------------
.equ PORT_AS_INPUT	= 0						; Waarde om een poort als input in te stellen
.equ PORT_AS_OUTPUT	= $FF					; Waarde om een poort als output in te stellen
.equ IN_PORT_TRIS	= 0						; Waarde om een input-poort als tristate in te stellen
.equ IN_PORT_PULL	= $FF					; Waarde om een input-poort's pull-up weerstanden in te schakelen

;--- Toegekende poorten & pinnen -----------
.equ LCD_CTRL_PORT	= PORTA					; De control-port
.equ LCD_CTRL_DDR	= DDRA
.equ LCD_DATA_PORT	= PORTC					; De data-port
.equ LCD_DATA_DDR	= DDRC
.equ LCD_DATA_IN	= PINC
;
.equ LCD_BUSY		= PC7					; Busy op pin 7 van poort C
;
.equ LCD_RS			= PA5					; RS op pin 5 van poort A
.equ LCD_RW			= PA6					; RW op pin 6 van poort A
.equ LCD_E			= PA7					; E op pin 7 van poort A
;
.equ RS_COMMAND	= 0							; LCD_RS-bit bij commando's
.equ RS_DATA	= 1							; LCD-RS-bit bij data
.equ RW_WRITE	= 0							; LCD_RW-bit bij schrijven naar LCD-geheugen
.equ RW_READ	= 1							; LCD_RW-bit bij lezen van LCD-geheugen

;--- Toegekende bits tbv. commando's -------
.equ CMD_SetDDRAMAddress	= (1<<7)
.equ CMD_SetCGRAMAddress	= (1<<6)
.equ CMD_FunctionSet		= (1<<5)
.equ CMD_CursorDisplayShift	= (1<<4)
.equ CMD_DisplayMode		= (1<<3)
.equ CMD_EntryMode			= (1<<2)
.equ CMD_CursorHome			= (1<<1)
.equ CMD_Clear				= (1<<0)

;--- Geldige data-bits bij commando's ------
.equ MASK_SetCGRAMAddress 		= 0b00111111
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
	reti							; ADC Conversion Complete Interrupt Vector Address
	reti							; EEPROM Write Complete Interrupt Vector Address
	reti							; Analog Comparator Interrupt Vector Address
;-----------------------------------


;--- De teksten in programma-geheugen --
Line0:	.db	"LCD-Display @ 8-bit", EOS_Symbol
Line1:	.db	"AVR @ 7.3728 MHz.", EOS_Symbol
Line2:	.db	"ADC-Value: ", EOS_Symbol
Line3:	.db	"COMM-Rx: ", EOS_Symbol


RESET:
	; De stack-pointer instellen op het einde van het RAM
	ldi		temp, high(RAMEND)
	ldi		tempL, low(RAMEND)
	out		SPH, temp
	out		SPL, tempL

	; LCD-Display initialiseren
	rcall	LCD_Init

	; display-ares instellen op 1e regel
	ldi		temp, AddrLine0
	rcall	LCD_SetDisplayAddr
	; regel-0 afbeelden
	ldi		R30, low(Line0)
	ldi		R31, high(Line0)
	rcall	LCD_Print

	; display-ares instellen op 2e regel
	ldi		temp, AddrLine1
	rcall	LCD_SetDisplayAddr
	; regel-1 afbeelden
	ldi		R30, low(Line1)
	ldi		R31, high(Line1)
	rcall	LCD_Print

	; display-ares instellen op 3e regel
	ldi		temp, AddrLine2
	rcall	LCD_SetDisplayAddr
	; regel-3 afbeelden
	ldi		R30, low(Line2)
	ldi		R31, high(Line2)
	rcall	LCD_Print

	; display-ares instellen op 4e regel
	ldi		temp, AddrLine3
	rcall	LCD_SetDisplayAddr
	; regel-4 afbeelden
	ldi		R30, low(Line3)
	ldi		R31, high(Line3)
	rcall	LCD_Print

eLoop:
	rjmp	eLoop







;---------------------------------------
;--- Pauze routine's.
;---  1us	=>      7.3728 clockcycles
;---  100us	=>    737.28   clockcycles
;---  15ms	=> 110592      clockcycles
;---  4.1ms =>  30288.48   clockcycles
;---------------------------------------
delay1us:
	; een rcall instructie neemt 3 cycles in beslag	|	  1*3 =   3 +
	nop									; 1 cycle	>	  1*1 =	  1 +
	ret									; 4 cycles	|	  1*4 =	  4
										;				-------------
										;				          8 clockcycles


;---------------------------------------
delay100us:								;100 micro-seconde = 0.1 milli seconde
	; een rcall instructie neemt 3 cycles in beslag	|	  1*3 =   3 +
	ldi		delay0, 243					; 1 cycle	|	  1*1 =   1 +
innerloop100us:							;			|
	dec		delay0						; 1 cycle	|	243*1 = 243 +
	brne	innerloop100us				; 2 cycles	>	242*2 = 484 +	;241 x wordt de branche genomen (springen = 2 cycles)
										; 1 cycle	|	  1*1 =   1 +	;bij de laatste branche wordt niet gesprongen (1 cycle)
	nop									; 1 cycle	|	  1*1 =	  1 +
	nop									; 1 cycle	|	  1*1 =	  1 +
	ret									; 4 cycles	|	  1*4 =   4
										;				-------------
										;				        738 clockcycles


;---------------------------------------
delay15ms:
	; een rcall instructie neemt 3 cycles in beslag	|	    1*3 =      3 +	   \
	ldi		delay1, 149					; 1 cycle	|	    1*1 =      1 +		|
innerloop15ms:							;			|							|
	rcall	delay100us					; 3 cycles	|	149*738 = 109962 +		|
	dec		delay1						; 1 cycle	|	  149*1 =    149 +		|
	brne	innerloop15ms				; 2 cycles	>	  148*2 =    296 +		|
										; 1 cycle	|	    1*1 =      1 +		|
										;				------------------		|
										;				          110412		>	110412 +
	;180 cycles to go....														|	   180 +
	ldi		delay1, 58					; 1 cycle	|	    1*1 =      1 +		|	--------
innerloop15ms_:							;			|							|	110592 cycles
	dec		delay1						; 1 cycle	|	   58*1 =     58 +		|
	brne	innerloop15ms_				; 2 cycles	>	   57*2 =    114 +		|
										; 1 cycle	|	    1*1 =      1 +		|
	nop									; 1 cycle	|	    1*1 =	   1 +		|
	nop									; 1 cycle	|	    1*1 =	   1 +		|
	ret									; 4 cycles	|	    1*4 =      4		|
										;				------------------		|
										;				             180	   /


;---------------------------------------
delay4_1ms:
	; een rcall instructie neemt 3 cycles in beslag	|	    1*3 =      3 +	   \
	ldi		delay1, 40					; 1 cycle	|	    1*1 =      1 +		|
innerloop4_1ms:							;			|							|
	rcall	delay100us					; 3 cycles	|	 40*738 =  29520 +		|
	dec		delay1						; 1 cycle	|	   40*1 =     40 +		|
	brne	innerloop4_1ms				; 2 cycles	>	   39*2 =     78 +		|
										; 1 cycle	|	    1*1 =      1 +		|
										;				------------------		|
										;				           29643		>	 29643 +
	;646 cycles to go....														|	   646 +
	ldi		delay1, 213					; 1 cycle	|	    1*1 =      1 +		|	--------
innerloop4_1ms_:						;			|							|	 30289 cycles
	dec		delay1						; 1 cycle	|	  213*1 =    213 +		|
	brne	innerloop15ms_				; 2 cycles	>	  212*2 =    424 +		|
										; 1 cycle	|	    1*1 =      1 +		|
	nop									; 1 cycle	|	    1*1 =	   1 +		|
	nop									; 1 cycle	|	    1*1 =	   1 +		|
	nop									; 1 cycle	|	    1*1 =	   1 +		|
	ret									; 4 cycles	|	    1*4 =      4		|
										;				------------------		|
										;				             646	   /
	

;---------------------------------------
delay1ms:
	; een rcall instructie neemt 3 cycles in beslag	|	    1*3 =      3 +	   \
	ldi		delay1, 9					; 1 cycle	|	    1*1 =      1 +		|
innerloop1ms:							;			|							|
	rcall	delay100us					; 3 cycles	|	  9*738 =   6642 +		|
	dec		delay1						; 1 cycle	|	    9*1 =      9 +		|
	brne	innerloop1ms				; 2 cycles	>	    8*2 =     16 +		|
										; 1 cycle	|	    1*1 =      1 +		|
										;				------------------		|
										;				            6672	    >	 6672 +
	;701 cycles to go....				;										|	  702 +
	ldi		delay1, 233					; 1 cycle	|	    1*1 =      1 +		|	-----
innerloop1ms_:							;			|							|	 7374 cycles (1 extra mag wel;)
	dec		delay1						; 1 cycle	|	  233*1 =    233 +		|
	brne	innerloop1ms_				; 2 cycles	>	  232*2 =    464 +		|
	ret									; 4 cycles	|	    1*4 =      4		|
										;				------------------		|
										;				             702	   /




;---------------------------------------
;--- De DATA poort instellen.
;---	input:	temp2 = poort waarde
;---			temp3 = DDR waarde
;---------------------------------------
LCD_SetDATAPort:
	push	temp
	ldi		temp, PORT_AS_INPUT
	out		LCD_DATA_DDR, temp
	ldi		temp, IN_PORT_TRIS
	out		LCD_DATA_PORT, temp
	out		LCD_DATA_DDR, temp3
	out		LCD_DATA_PORT, temp2
	pop		temp
	ret


;---------------------------------------
;--- De CTRL poort instellen.
;---	input:	temp2 = poort waarde
;---			temp3 = DDR waarde
;---------------------------------------
LCD_SetCTRLPort:
	push	temp
	ldi		temp, PORT_AS_INPUT
	out		LCD_CTRL_DDR, temp
	ldi		temp, IN_PORT_TRIS
	out		LCD_CTRL_PORT, temp
	out		LCD_CTRL_DDR, temp3
	out		LCD_CTRL_PORT, temp2
	pop		temp
	ret



;---------------------------------------
;--- Wacht op busy-signaal
;---------------------------------------
LCD_CheckBusy:
	push	temp
	push	temp2
	push	temp3
	;
	ldi		temp2, IN_PORT_TRIS
	ldi		temp3, PORT_AS_INPUT
	rcall	LCD_SetDATAPort
	;
    cbi		LCD_CTRL_PORT, LCD_RS		; RS = 0 (commando)
    sbi		LCD_CTRL_PORT, LCD_RW		; R/W = 1 (lezen)
    sbi		LCD_CTRL_PORT, LCD_E		; E = 1
	rcall	delay1us					; 1-2 us wachten
	rcall	delay1us
WaitForBit0:
	in		temp2, LCD_DATA_IN
	sbrc	temp2, LCD_BUSY
	rjmp	WaitForBit0	
    cbi		LCD_CTRL_PORT, LCD_E		; E = 0
    cbi		LCD_CTRL_PORT, LCD_RW		; R/W = 0 (schrijven)
	;
	ldi		temp2, 0
	ldi		temp3, PORT_AS_OUTPUT
	rcall	LCD_SetDATAPort
	;
	pop		temp3
	pop		temp2
	pop		temp
	ret



;---------------------------------------
;--- MACRO
;---------------------------------------
.MACRO LCD_Send
	; Tenminste 40 ns wachten alvorens Enable op 1. (<1 clockcycle)
	nop
	; De Enable-puls moet tenminste 230 ns op 1 blijven. (= 0.6290 clockcycle)
    sbi		LCD_CTRL_PORT, LCD_E
    out		LCD_DATA_PORT, temp
    cbi		LCD_CTRL_PORT, LCD_E		; register temp wordt nu overgedragen
;	; R/W-bit weer op 1
;   sbi		LCD_CTRL_PORT, LCD_RW		; R/W = 1 (lezen)
.ENDMACRO



;---------------------------------------
;--- Schrijf commando
;---	input:	temp = waarde
;---------------------------------------
LCD_Command:
	rcall	LCD_CheckBusy
	cbi		LCD_CTRL_PORT, LCD_RS		; RS = 0 (commando)
    cbi		LCD_CTRL_PORT, LCD_RW		; R/W = 0 (schrijven)
	LCD_Send							; Macro
	; 10 ms wachten na zenden COMMAND
	ret


;---------------------------------------
;--- Schrijf data
;---	input:	temp = waarde
;---------------------------------------
LCD_Data:
	rcall	LCD_CheckBusy
	sbi		LCD_CTRL_PORT, LCD_RS		; RS = 1 (data)
    cbi		LCD_CTRL_PORT, LCD_RW		; R/W = 0 (schrijven)
	LCD_Send							; Macro
	; 1 ms wachten na zenden DATA
	ret





;---------------------------------------
;--- Een string afbeelden op LCD-display
;---	input:	register Z (R31:R30)= string-adres
;---------------------------------------
LCD_Print:
	;methode 2
	lpm									; R0 <- [Z]  (R0 = CharReg)
	adiw	r30, 1						; Z verhogen
	mov		temp, CharReg				;
	cpi		temp, EOS_Symbol
	breq	EOS
	rcall	LCD_Data
	rjmp	LCD_Print
;	;methode 1
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
;--- LCD-Setup (Function Set)
;---	input:	temp = b2  : 0=5x7 dots font, 1=5x10 dots font
;--- 				   b3  : 0=1/8 or 1/11 Duty (1 line), 1=1/16 Duty (2 lines) 
;--- 				   b4  : 0=4-bit, 1=8-bit
;---------------------------------------
LCD_FunctionSet_TestBUSYflag:
	rcall	LCD_CheckBusy
LCD_FunctionSet:
	andi	temp, MASK_FunctionSet
	ori		temp, CMD_FunctionSet
	;
	cbi		LCD_CTRL_PORT, LCD_RS		; RS = 0 (commando)
    cbi		LCD_CTRL_PORT, LCD_RW		; R/W = 0 (schrijven)
	LCD_Send							; Macro
	ret



;---------------------------------------
;--- LCD-SetCharGenAddr
;--- Sets the Character-Generator-RAM address.
;--- CGRAM data is read/written after this setting.
;---	input:	temp = b0-5 : required CGRAM address
;---------------------------------------
LCD_SetCharGenAddr:
	andi	temp, MASK_SetCGRAMAddress
	ori		temp, CMD_SetCGRAMAddress
    rcall	LCD_Command
	ret



;---------------------------------------
;--- LCD-SetDisplayAddr
;--- Sets the Display-Data-RAM address.
;--- DDRAM data is read/written after this setting.
;---	input:	temp = b0-6 : required DDRAM address
;---------------------------------------
LCD_SetDisplayAddr:
	ori		temp, CMD_SetDDRAMAddress
    rcall	LCD_Command
	ret



;---------------------------------------
;--- LCD-GetAddrCounter
;--- Returns address counter contents, used for both DDRAM and CGRAM.
;---	output:	temp = b0-6 : DDRAM/CGRAM address
;---------------------------------------
LCD_GetAddrCounter:
	ldi		temp2,IN_PORT_TRIS
	ldi		temp3,PORT_AS_INPUT
	rcall	LCD_SetDATAPort
	;
    cbi		LCD_CTRL_PORT, LCD_RS		; RS = 0 (commando)
    sbi		LCD_CTRL_PORT, LCD_RW		; R/W = 1 (lezen)
	;
    sbi		LCD_CTRL_PORT, LCD_E
	rcall	delay1us					; 1-2 us wachten
	rcall	delay1us
	in		temp, LCD_DATA_IN
	andi	temp, ~LCD_BUSY				; busy-flag strippen (bitwise not)
    cbi		LCD_CTRL_PORT, LCD_E
	;
	ldi		temp2,0
	ldi		temp3,PORT_AS_OUTPUT
	rcall	LCD_SetDATAPort
	ret



;---------------------------------------
;--- LCD-Init
;---------------------------------------
LCD_Init:
	; AVR-poorten als output instellen
	ldi		temp2,0
	ldi		temp3,PORT_AS_OUTPUT
	rcall	LCD_SetCTRLPort
	;
	ldi		temp2,0
	ldi		temp3,PORT_AS_OUTPUT
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
	ldi		temp, (DISPLAY_ON | CURSOR_ON | CURSOR_BLINK_ON)
	rcall	LCD_DisplayMode

	rcall	delay15ms					; 15 milli-seconde pauze
	ret




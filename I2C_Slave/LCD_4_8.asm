;********************************************************************************
;***
;***  Een implementatie voor een 4/8-bit aansturing van een LCD.
;***
;***	LCD	8-bit   AVR
;***	---------  	-----------------------------
;***	1	Vss	   	GND 
;***	2	Vcc	  	5V 
;***	3	Vee	  	GND of naar een potmeter
;***	4	RS	  	PA5 \
;***	5	RW	  	PA6 > control lijnen (OUTPUT)
;***	6	E	  	PA7 /
;***	7	DB0	  	PC0 \
;***	8	DB1	  	PC1 |
;***	9	DB2	  	PC2 |
;***	10	DB3	  	PC3 > data lijnen (INPUT/OUTPUT)
;***	11	DB4	  	PC4 |
;***	12	DB5	  	PC5 |
;***	13	DB6	  	PC6 |
;***	14	DB7	  	PC7 /
;***
;***
;***	LCD	4-bit   AVR
;***	---------  	-----------------------------
;***	1	Vss	   	GND 
;***	2	Vcc	  	5V 
;***	3	Vee	  	GND of naar een potmeter
;***	4	RS	  	PC1 |
;***	5	RW	  	PC2 > control lijnen (OUTPUT)
;***	6	E	  	PC3 |
;***	7	DB0 GND
;***	8	DB1 GND
;***	9	DB2 GND
;***	10	DB3 GND
;***	11	DB4	  	PC4 |
;***	12	DB5	  	PC5 > data lijnen (INPUT/OUTPUT)
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


;--- INCLUDE FILES ------------------------\
;.include "8535def.inc"						; Atmel AVR-AT90S8535 definities
;------------------------------------------/


;--- COMPLIER DIRECTIVES ------------------\
;.equ DATA_LEN = 4							; compileer voor een 4-bits InterFace
.equ DATA_LEN = 8							; compileer voor een 8-bits InterFace
;------------------------------------------/


;--- Toegekende poorten & pinnen ----------\
.if DATA_LEN == 8
	;--- De control-port en control-lijnen -
	.equ LCD_CTRL_PORT	= PORTA				; De control-port (alleen als OUTPUT)
	.equ LCD_CTRL_DDR	= DDRA				; Het Data-Direction-Register van de control-port
	.equ LCD_RS			= PA5				; RS op pin 5 van poort A
	.equ LCD_RW			= PA6				; RW op pin 6 van poort A
	.equ LCD_E			= PA7				; E op pin 7 van poort A
	;--- De data-port en data-lijnen -------
	.equ LCD_DATA_PORT	= PORTC				; De data-port DB7-0 (INPUT/OUTPUT)
	.equ LCD_DATA_DDR	= DDRC				;
	.equ LCD_DATA_IN	= PINC				; Input data lezen van deze poort
	.equ LCD_BUSY		= PC7				; Busy-Flag op pin 7 van poort C (=DB7)
	;--- De datalijnen ---------------------
	.equ LCD_DB0		= PC0				; 
	.equ LCD_DB1		= PC1				;
	.equ LCD_DB2		= PC2				;
	.equ LCD_DB3		= PC3				;
	.equ LCD_DB4		= PC4				; 
	.equ LCD_DB5		= PC5				;
	.equ LCD_DB6		= PC6				;
	.equ LCD_DB7		= PC7				;
.else ;if DATA_LEN == 4
	;--- De control-port (OUTPUT) ----------
	.equ LCD_CTRL_PORT	= PORTA				; De control-port (alleen als OUTPUT)
	.equ LCD_CTRL_DDR	= DDRA				; Het Data-Direction-Register van de control-port
	;--- De control-lijnen -----------------
	.equ LCD_RS			= PA5				; RS op pin 5 van poort A
	.equ LCD_RW			= PA6				; RW op pin 6 van poort A
	.equ LCD_E			= PA7				; E op pin 7 van poort A
	;--- De data-port (INPUT/OUTPUT) -------
	.equ LCD_DATA_PORT	= PORTC				; De data-port DB7-0 
	.equ LCD_DATA_DDR	= DDRC				;
	.equ LCD_DATA_IN	= PINC				; Input data lezen van deze poort
	.equ LCD_BUSY		= PC7				; Busy-Flag op pin 7 van poort C (=DB7)
	;--- De datalijnen ---------------------
	;.equ LCD_DB0		= PC0				; 
	;.equ LCD_DB1		= PC1				;
	;.equ LCD_DB2		= PC2				;
	;.equ LCD_DB3		= PC3				;
	.equ LCD_DB4		= PC4				; 
	.equ LCD_DB5		= PC5				;
	.equ LCD_DB6		= PC6				;
	.equ LCD_DB7		= PC7				;
.endif
;------------------------------------------/


;--- CONSTANTEN ---------------------------\
;--- I/O -----------------------------------
.equ PIN_AS_INPUT		= 0		; Een pin als input instellen
.equ PIN_AS_OUTPUT		= 1		; Een pin als output instellen
.equ PORT_AS_INPUT		= $00	; Een poort als input instellen
.equ PORT_AS_OUTPUT		= $FF	; Een poort als output instellen
.equ INPUT_PORT_TRIS	= $00	; Een input-poort's tristate instellen
.equ INPUT_PORT_PULL	= $FF	; Een input-poort's pull-up weerstanden inschakelen

.equ EOS_Symbol	= '$'						; End-Of-String teken
;--- LCD Begin-adressen van elke regel -----
.equ AddrLine0	= $00
.equ AddrLine1	= $40
.equ AddrLine2	= $14
.equ AddrLine3	= $54
;--- Bits ----------------------------------
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
.equ SHIFT_DISPLAY_LEFT		= (0<<3)		; beweeg display & cursor naar links
.equ SHIFT_DISPLAY_RIGHT	= (1<<3)		; beweeg display & cursor naar rechts
.equ SHIFT_CURSOR_LEFT		= (0<<2)		; beweeg de cursor naar links
.equ SHIFT_CURSOR_RIGHT		= (1<<2)		; beweeg de cursor naar rechts
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




;---------------------------------------
;--- Zelf-gedefinieerde tekens
;--  in programma(/flash)-geheugen
;--------------------------------------\
;		      ___12345
;CChar0:.db	0b00000000;1
;		.db	0b00000000;2
;		.db	0b00010000;3
;		.db	0b00010000;4
;		.db	0b00010000;5
;		.db	0b00010000;6
;		.db	0b00000000;7
;		.db	0b00000000;|
;CChar1:.db	0b00000000
;		.db	0b00000000
;		.db	0b00011000
;		.db	0b00011000
;		.db	0b00011000
;		.db	0b00011000
;		.db	0b00000000
;		.db	0b00000000
;CChar2:.db	0b00000000
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
		.dw	0b0000110000001100
		.dw	0b0000110000001100
		.dw	0b0000000000000000
CChar3:	.dw	0b0000000000000000
		.dw	0b0000011000000110
		.dw	0b0000011000000110
		.dw	0b0000000000000000
CChar4:	.dw	0b0000000000000000
		.dw	0b0000001100000011
		.dw	0b0000001100000011
		.dw	0b0000000000000000
;---------------------------------------
;--- Teksten van het splashscreen
;--  in programma(/flash)-geheugen
SplashText0: .db "   AVR-ASM Code   ", EOS_Symbol;, 0
SplashText1: .db " 4b/8b LCD v0.900 ", EOS_Symbol;, 0
;--------------------------------------/





;---------------------------------------
;--- MACRO'S
;--------------------------------------\
.MACRO LCD_CTRL_Data
	sbi		LCD_CTRL_PORT, LCD_RS		; RS = 1 (data)
.ENDMACRO

.MACRO LCD_CTRL_Command
	cbi		LCD_CTRL_PORT, LCD_RS		; RS = 0 (commando)
.ENDMACRO

.MACRO LCD_CTRL_Read
    sbi		LCD_CTRL_PORT, LCD_RW		; R/W = 1 (lezen)
.ENDMACRO

.MACRO LCD_CTRL_Write
    cbi		LCD_CTRL_PORT, LCD_RW		; R/W = 0 (schrijven)
.ENDMACRO

.MACRO LCD_CTRL_Enable1
    sbi		LCD_CTRL_PORT, LCD_E		; E = 1
.ENDMACRO

.MACRO LCD_CTRL_Enable0
    cbi		LCD_CTRL_PORT, LCD_E		; E = 0
.ENDMACRO

.MACRO LCD_CTRL_ToggleEnable
	LCD_CTRL_Enable1					; E = 1
	nop
	nop
	nop
	LCD_CTRL_Enable0					; E = 0
.ENDMACRO

; Plaats een nibble op de LCD_Data_Port vanaf bitnummer 'bit'
.MACRO LCD_SendNibble;(register,bit)
	; de 4 LCD-Data pinnen afzonderlijk beschrijven
	cbi		LCD_DATA_PORT, LCD_DB7
	sbrc	@0, @1
	sbi		LCD_DATA_PORT, LCD_DB7
	cbi		LCD_DATA_PORT, LCD_DB6
	sbrc	@0, @1-1
	sbi		LCD_DATA_PORT, LCD_DB6
	cbi		LCD_DATA_PORT, LCD_DB5
	sbrc	@0, @1-2
	sbi		LCD_DATA_PORT, LCD_DB5
	cbi		LCD_DATA_PORT, LCD_DB4
	sbrc	@0, @1-3
	sbi		LCD_DATA_PORT, LCD_DB4
.ENDMACRO

.MACRO LCD_Send;(register)
	; Tenminste 40 ns wachten alvorens Enable op 1. (<1 clockcycle)
	nop
	nop
	nop
	.if DATA_LEN == 8
		; De Enable-puls moet tenminste 230 ns op 1 blijven. (= 0.6290 clockcycle)
	    sbi		LCD_CTRL_PORT, LCD_E
	    out		LCD_DATA_PORT, @0
	    cbi		LCD_CTRL_PORT, LCD_E	; register temp wordt nu overgedragen
	.else ;if DATA_LEN == 4
		; Enable 1
	    sbi		LCD_CTRL_PORT, LCD_E
		; Eerst de 4 hoogste bits sturen,...
		LCD_SendNibble @0, 7 ; t/m 4
		; Enable 0
	    cbi		LCD_CTRL_PORT, LCD_E	; register temp wordt nu overgedragen
		; Tenminste 40 ns wachten alvorens Enable op 1. (<1 clockcycle)
		rcall	delay2us				; 1-2 us wachten
		; Enable 1
	    sbi		LCD_CTRL_PORT, LCD_E
		; ...daarna de 4 laagste bits sturen
		LCD_SendNibble @0, 3 ; t/m 4
		; Enable 0
	    cbi		LCD_CTRL_PORT, LCD_E	; register temp wordt nu overgedragen
		; Een kleine vertraging inlassen
		rcall	delay50us
	.endif
.ENDMACRO

; Plaats een nibble vanaf bitnummer 'bit' van LCD_Data_IN in het register
.MACRO LCD_ReceiveNibble;(register,bit)
	; de 4 LCD-Data pinnen afzonderlijk lezen
	push	R31
	in		R31, LCD_DATA_IN
	clr		@0	
	.if @1 == 7 ;hoogste nibble?
		sbrc	R31, LCD_DB7
		sbr		@0, 7
		sbrc	R31, LCD_DB6
		sbr		@0, 6
		sbrc	R31, LCD_DB5
		sbr		@0, 5
		sbrc	R31, LCD_DB4
		sbr		@0, 4
	.else
		sbrc	R31, LCD_DB7
		sbr		@0, 3
		sbrc	R31, LCD_DB6
		sbr		@0, 2
		sbrc	R31, LCD_DB5
		sbr		@0, 1
		sbrc	R31, LCD_DB4
		sbr		@0, 0
	.endif
	pop		R31
.ENDMACRO

.MACRO LCD_Receive;(register)
	.if DATA_LEN == 8
		LCD_CTRL_Enable1				; E = 1
		rcall	delay2us				; 1-2 us wachten
		in		@0, LCD_DATA_IN			; Data Input
		LCD_CTRL_Enable0				; E = 0
	.else ;if DATA_LEN == 4
		push	R31
		; 1e nibble lezen
		LCD_CTRL_Enable1				; E = 1
		rcall	delay2us				; 1-2 us wachten
		
		;!in		@0, LCD_DATA_IN		; Data Input
		LCD_ReceiveNibble @0, 7

		LCD_CTRL_Enable0				; E = 0
		rcall	delay2us				; 1-2 us wachten
		; 2e nibble lezen
		LCD_CTRL_Enable1				; E = 1
		rcall	delay2us				; 1-2 us wachten

		;!in		R30, LCD_DATA_IN	; Data Input
		LCD_ReceiveNibble R30, 4

		LCD_CTRL_Enable0				; E = 0
		rcall	delay2us				; 1-2 us wachten
		; 1 byte maken
		;!swap	R30
		;!andi	R30, $0F
		;!andi	@0, $F0
		add		@0, R30
		pop		R30
	.endif
.ENDMACRO
;--------------------------------------/






;---------------------------------------
;--- De CTRL pins instellen.
;--------------------------------------\
LCD_SetCTRLPins:
	;--- Reset de pin.
	; pinnen als input instellen
	cbi		LCD_CTRL_DDR, LCD_RS
	cbi		LCD_CTRL_DDR, LCD_RW
	cbi		LCD_CTRL_DDR, LCD_E
	; tristate instellen
	cbi		LCD_CTRL_PORT, LCD_RS
	cbi		LCD_CTRL_PORT, LCD_RW
	cbi		LCD_CTRL_PORT, LCD_E
	;--- Opnieuw instellen.
	; pinnen als output instellen
	sbi		LCD_CTRL_DDR, LCD_RS
	sbi		LCD_CTRL_DDR, LCD_RW
	sbi		LCD_CTRL_DDR, LCD_E
	; Push-Pull zero output
	cbi		LCD_CTRL_PORT, LCD_RS
	cbi		LCD_CTRL_PORT, LCD_RW
	cbi		LCD_CTRL_PORT, LCD_E
	ret
;--------------------------------------/


;---------------------------------------
;--- De DATA poort/pins instellen.
;--------------------------------------\
LCD_SetDATAPort_AS_OUTPUT:
	.if DATA_LEN == 8
		push	R16
		; poort zeker vrijgeven..
		ldi		R16, PORT_AS_INPUT
		out		LCD_DATA_DDR, R16
		ldi		R16, INPUT_PORT_TRIS
		out		LCD_DATA_PORT, R16
		; ..en opnieuw instellen.
		ldi		R16,PORT_AS_OUTPUT		; output
		out		LCD_DATA_DDR, R16
		ldi		R16,0					; Push-Pull zero output
		out		LCD_DATA_PORT, R16
		pop		R16
	.else ;if DATA_LEN == 4
		cbi		LCD_DATA_DDR, LCD_DB7	; poort zeker vrijgeven (input,tri-state)
		cbi		LCD_DATA_PORT, LCD_DB7	;
		sbi		LCD_DATA_DDR, LCD_DB7	; output,
		cbi		LCD_DATA_PORT, LCD_DB7	; Push-Pull zero output.
		cbi		LCD_DATA_DDR, LCD_DB6	; poort zeker vrijgeven (input,tri-state)
		cbi		LCD_DATA_PORT, LCD_DB6	;
		sbi		LCD_DATA_DDR, LCD_DB6	; output,
		cbi		LCD_DATA_PORT, LCD_DB6	; Push-Pull zero output.
		cbi		LCD_DATA_DDR, LCD_DB5	; poort zeker vrijgeven (input,tri-state)
		cbi		LCD_DATA_PORT, LCD_DB5	;
		sbi		LCD_DATA_DDR, LCD_DB5	; output,
		cbi		LCD_DATA_PORT, LCD_DB5	; Push-Pull zero output.
		cbi		LCD_DATA_DDR, LCD_DB4	; poort zeker vrijgeven (input,tri-state)
		cbi		LCD_DATA_PORT, LCD_DB4	;
		sbi		LCD_DATA_DDR, LCD_DB4	; output,
		cbi		LCD_DATA_PORT, LCD_DB4	; Push-Pull zero output.
	.endif
	ret
;---------------------------------------
LCD_SetDATAPort_AS_INPUT:
	.if DATA_LEN == 8
		push	R16
		ldi		R16, PORT_AS_INPUT		; poort zeker vrijgeven..
		out		LCD_DATA_DDR, R16
		ldi		R16, INPUT_PORT_TRIS
		out		LCD_DATA_PORT, R16
		pop		R16
	.else ;if DATA_LEN == 4
		cbi		LCD_DATA_DDR, LCD_DB7	; poort zeker vrijgeven (input,tri-state)
		cbi		LCD_DATA_PORT, LCD_DB7	;
		cbi		LCD_DATA_DDR, LCD_DB6	; poort zeker vrijgeven (input,tri-state)
		cbi		LCD_DATA_PORT, LCD_DB6	;
		cbi		LCD_DATA_DDR, LCD_DB5	; poort zeker vrijgeven (input,tri-state)
		cbi		LCD_DATA_PORT, LCD_DB5	;
		cbi		LCD_DATA_DDR, LCD_DB4	; poort zeker vrijgeven (input,tri-state)
		cbi		LCD_DATA_PORT, LCD_DB4	;
	.endif
	ret
;--------------------------------------/







;---------------------------------------
;--- Wacht op busy-signaal
;--------------------------------------\
LCD_WaitWhileBusy:
	push	R16
	rcall	LCD_SetDATAPort_AS_INPUT

	LCD_CTRL_Command					; RS = 0 (command)
    LCD_CTRL_Read						; R/W = 1 (lezen)
WaitWhileFlag1:
	LCD_Receive R16						; Commando lezen van LCD (incl. busy flag)
;	.if DATA_LEN == 8
		andi	R16, MASK_BUSYFlag		; busy flag filteren
;	.else ;if DATA_LEN == 4
;fout	andi	R16, (1<<LCD_DB7)		; busy flag filteren
;	.endif
	brne	WaitWhileFlag1

    LCD_CTRL_Write						; R/W = 0 (schrijven)
	rcall	LCD_SetDATAPort_AS_OUTPUT
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- Commando uitvoeren (schrijven)
;---	input:	R16 = commando
;--------------------------------------\
LCD_Command:
	rcall	LCD_WaitWhileBusy
LCD_Command_:
	LCD_CTRL_Command					; RS = 0 (commando)
    LCD_CTRL_Write						; R/W = 0 (schrijven)
	LCD_Send R16						; Commando zenden naar LCD
	.if DATA_LEN == 4
		; 10 ms wachten na zenden COMMAND (4bits-IF)
		rcall	delay15ms
	.endif
	ret
;--------------------------------------/


;---------------------------------------
;--- Schrijf data
;---	input:	R16 = data
;--------------------------------------\
LCD_Data:
	rcall	LCD_WaitWhileBusy
	LCD_CTRL_Data						; RS = 1 (data)
    LCD_CTRL_Write						; R/W = 0 (schrijven)
	LCD_Send R16						; Data zenden naar LCD
	.if DATA_LEN == 4
		; 1 ms wachten na zenden DATA (4bits-IF)
		rcall	delay1ms
	.endif
	ret
;--------------------------------------/


;---------------------------------------
;--- Lees data
;---	output:	R16 = gelezen byte
;--------------------------------------\
LCD_Read_Data:
	rcall	LCD_WaitWhileBusy			; wacht op de busy-flag
	rcall	delay100us					; 40us wachten tot de auto-increment klaar is
	rcall	LCD_SetDATAPort_AS_INPUT

	LCD_CTRL_Data						; RS = 1 (data)
	LCD_CTRL_Read						; R/W = 1 (lezen)
	LCD_Receive R16						;

    LCD_CTRL_Write						; R/W = 0 (schrijven)
	rcall	LCD_SetDATAPort_AS_OUTPUT
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD-scherm wissen
;--------------------------------------\
LCD_Clear:
	push	R16
	ldi		R16, CMD_Clear
    rcall	LCD_Command
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD-cursor naar Home-positie
;--------------------------------------\
LCD_Home:
	push	R16
	ldi		R16, CMD_CursorHome
    rcall	LCD_Command
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD-Entry-mode instellen.
;---	input:	R16 =	b0 : 0=no display shift, 1=display shift
;--- 				 	b1 : 0=auto-AUTO_DECREMENT, 1=auto-AUTO_INCREMENT
;--------------------------------------\
LCD_EntryMode:
	andi	R16, MASK_EntryMode
	ori		R16, CMD_EntryMode
    rcall	LCD_Command
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD-Display-mode instellen.
;---	input:	R16 =	b0 : 0=cursor blink off, 1=cursor blink on (als b1 = 1)
;--- 				 	b1 : 0=cursor off,  1=cursor on
;---				 	b2 : 0=display off, 1=display on (display data remains in DD-RAM)
;--------------------------------------\
LCD_DisplayMode:
	andi	R16, MASK_DisplayMode
	ori		R16, CMD_DisplayMode
    rcall	LCD_Command
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD-Cursor-Display-mode instellen.
;---	input:	R16 =	b2 : 0=shift left, 1=shift right
;--- 				 	b3 : 0=cursor-shift, 1=display-shift
;--------------------------------------\
LCD_CursorDisplayShift:
	andi	R16, MASK_CursorDisplayShift
	ori		R16, CMD_CursorDisplayShift
    rcall	LCD_Command
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD_FunctionSet (Function Set)
;---	input:	R16 =	b2  : 0=5x7 dots font, 1=5x10 dots font
;--- 				 	b3  : 0=1/8 or 1/11 Duty (1 line), 1=1/16 Duty (2 lines) 
;--- 				 	b4  : 0=4-bit, 1=8-bit
;--------------------------------------\
LCD_FunctionSet:						; entry point (busy-flag testen)
	rcall	LCD_WaitWhileBusy
LCD_FunctionSet_:						; entry point (zonder busy-flag test)
	andi	R16, MASK_FunctionSet
	ori		R16, CMD_FunctionSet
	rcall	LCD_Command_				; commando zonder busy-flag test aanroepen
	ret
;---------------------------------------
;--- Alleen nodig tijdens initialisatie
;--- van een 4-bits interface.
;---------------------------------------
LCD_FunctionSet4:
	andi	R16, MASK_FunctionSet
	ori		R16, CMD_FunctionSet
	; commando zonder busy-flag test aanroepen
	LCD_CTRL_Command					; RS = 0 (commando)
    LCD_CTRL_Write						; R/W = 0 (schrijven)
    sbi		LCD_CTRL_PORT, LCD_E		; Enable 1
	LCD_SendNibble R16, 7				; Alleen de 4 hoogste bits sturen,...
    cbi		LCD_CTRL_PORT, LCD_E		; Enable 0,  register R16 (bits7-4) wordt nu overgedragen
	; 10 ms wachten na zenden COMMAND (4bits-IF)
	rcall	delay15ms
	ret
;--------------------------------------/



;---------------------------------------
;--- LCD-SetCharGenAddr
;--- Instellen van het Character-Generator-RAM adres.
;--- CGRAM data lezen/schrijven na dit commando.
;---	input:	R16 = b0-5 : CGRAM adres
;--------------------------------------\
LCD_SetCharGenAddr:
	andi	R16, MASK_CGRAMAddress
	ori		R16, CMD_CGRAMAddress
    rcall	LCD_Command
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD-SetDisplayAddr
;--- Instellen van het Display-Data-RAM adres.
;--- DDRAM data lezen/schrijven na dit commando.
;---	input:	R16 = b0-6 : DDRAM adres
;--------------------------------------\
LCD_SetDisplayAddr:
	ori		R16, CMD_DDRAMAddress
    rcall	LCD_Command
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD_GetDisplayAddr
;--- Resulteer de adres-counter waarde (DDRAM/CGRAM).
;---	output:	R16 bit6-0 : DDRAM/CGRAM adres (bit 7 wordt altijd 0)
;--------------------------------------\
LCD_GetDisplayAddr:
	rcall	LCD_WaitWhileBusy
	rcall	LCD_SetDATAPort_AS_INPUT

	LCD_CTRL_Command					; RS = 0 (command)
    LCD_CTRL_Read						; R/W = 1 (lezen)
	LCD_Receive R16						;
	andi	R16, MASK_DDRAMAddress		; busy flag strippen

	LCD_CTRL_Write						; R/W = 0 (schrijven)
	rcall	LCD_SetDATAPort_AS_OUTPUT
	ret
;--------------------------------------/


;---------------------------------------
;--- Een zelf-gedefinieerd teken in RAM plaatsen
;---	input:	R16 = adres (0..7) in LCD-RAM
;---			Z = adres van teken-patroon 
;---                (8 bytes lang) in AVR-program-memory
;--- !!! AUTO-INCREMENT MOET INGESCHAKELD ZIJN
;--------------------------------------\
LCD_CustomCharacter:
	push	R16
	push	R17
	push	R0

	lsl		R16						; LCD-RAM adres * 8
	lsl		R16
	lsl		R16
	rcall	LCD_SetCharGenAddr
	; nu de 8 bytes van het patroon overzenden
	lsl		ZL							; Eerst het adres x2 tbv. de LPM-instructie....
	rol		ZH
	ldi		R17, 8					; 8 bytes overbrengen naar LCD-RAM
NextChar:
	lpm									; R0 (=CharReg) krijgt de waarde van de byte op adres [Z]
	adiw	ZL,1						; Z-register verhogen
	mov		R16, R0						; R0 bevat het resultaat van de LPM instructie
	rcall	LCD_Data
	dec		R17
	brne	NextChar
	; DDRAM adresseren ipv. CGRAM
	ldi		R16, 0
	rcall	LCD_SetDisplayAddr

	pop		R0
	pop		R17
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD XY2Addr
;---	input:	R17 = column [0..19]
;---			R18 = row [0..3]
;--- 	output: R16  = DDRAM Address
;--------------------------------------\
LCD_XY2Addr:
	push	R18
	cpi		R18, 0
	brne	_XY1
	ldi		R18, AddrLine0
	rjmp	_XY
_XY1:
	cpi		R18, 1
	brne	_XY2
	ldi		R18, AddrLine1
	rjmp	_XY
_XY2:
	cpi		R18, 2
	brne	_XY3
	ldi		R18, AddrLine2
	rjmp	_XY
_XY3:
	cpi		R18, 3
	brne	_XY
	ldi		R18, AddrLine3
_XY:
	mov		R16, R18
	add		R16, R17
	pop		R18
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD Addr2XY
;--- 	input:	R16  = DDRAM Address
;---	output:	R17 = column [0..19]
;---			R18 = row [0..3]
;--------------------------------------\
LCD_Addr2XY:
	push	R19
	; R16 = [$00..$13] || [$40..$53] || [$14..$27] || [$54..$67]
	; cursor nu nog ergens op de 4e regel?
	cpi		R16, AddrLine3
	brlo	_Addr2
	ldi		R19, AddrLine3
	ldi		R18, 3
	rjmp	_Addr
_Addr2:; cursor nu nog ergens op de 2e regel?
	cpi		R16, AddrLine1
	brlo	_Addr3
	ldi		R19, AddrLine1
	ldi		R18, 1
	rjmp	_Addr
_Addr3:; cursor nu nog ergens op de 3e regel?
	cpi		R16, AddrLine2
	brlo	_Addr1
	ldi		R19, AddrLine2
	ldi		R18, 2
	rjmp	_Addr
_Addr1:; cursor nu nog ergens op de 1e regel
	ldi		R19, AddrLine0
	ldi		R18, 0
_Addr:
	;cursor positie resulteren in temp2 & temp3
	mov		R17, R16
	sub		R17, R19
	pop		R19
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD GetCursorXY
;--- De cursorpositie lezen
;---	output:	R17 = column [0..19]
;---			R18 = row [0..3]
;--------------------------------------\
LCD_GetCursorXY:
	push	R16
	; huidige adres opvragen in DD/CG-RAM
	rcall	LCD_GetDisplayAddr
	rcall	LCD_Addr2XY
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- De cursor plaatsen op XY(column,row)
;---	input:	R17 = column [0..19]
;---			R18 = row [0..3]
;--------------------------------------\
LCD_SetCursorXY:
	push	R16
	rcall	LCD_XY2Addr
	rcall	LCD_SetDisplayAddr
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD-Init
;--------------------------------------\
LCD_Init:
	push	R16
	; LCD-Control poorten op AVR als output instellen
	rcall	LCD_SetCTRLPins
	; zo ook de LCD-Data poort op de AVR
	rcall	LCD_SetDATAPort_AS_OUTPUT

	rcall	delay15ms					; 15 milli-seconde pauze
	rcall	delay15ms					; 15 milli-seconde pauze

	; De InterFace initialiseren.
	; moet 3x gebeuren met pauzes ertussen....
	.if DATA_LEN == 8
		; instellen op 8-bits interface
	    ldi		R16, DATA_LEN_8				; als 8-bit IF instellen
		rcall	LCD_FunctionSet_			; entry point zonder BF-test
		;
		rcall	delay4_1ms					; 4.1 milli-seconde pauze
		;
	    ldi		R16, DATA_LEN_8				; als 8-bit IF instellen
		rcall	LCD_FunctionSet_			; entry point zonder BF-test
		;
		rcall	delay100us					; 100 micro-seconde pauze
		;
	    ldi		R16, DATA_LEN_8				; als 8-bit IF instellen
		rcall	LCD_FunctionSet_			; entry point zonder BF-test
	.else ;if DATA_LEN == 4
	    ldi		R16, DATA_LEN_8				; als 8-bit IF instellen
		rcall	LCD_FunctionSet4			; entry point zonder BF-test
		;
		rcall	delay4_1ms					; 4.1 milli-seconde pauze
		;
	    ldi		R16, DATA_LEN_8				; als 8-bit IF instellen
		rcall	LCD_FunctionSet4			; entry point zonder BF-test
		;
		rcall	delay100us					; 100 micro-seconde pauze
		;
	    ldi		R16, DATA_LEN_8				; als 8-bit IF instellen
		rcall	LCD_FunctionSet4			; entry point zonder BF-test
	.endif

	;!! vanaf nu kan de BUSY-flag worden afgevraagd....

	; Aantal regels en font instellen
	.if DATA_LEN == 8
	    ldi		R16, (DATA_LEN_8 | LINE_COUNT_2 | FONT_5x7)
		rcall	LCD_FunctionSet				; entry point met BF-test
	.else ;if DATA_LEN == 4
	    ldi		R16, (DATA_LEN_4 | LINE_COUNT_2 | FONT_5x7)
		rcall	LCD_FunctionSet				; entry point met BF-test
	.endif

	; display-mode initialiseren (alles uit)
	ldi		R16, (DISPLAY_OFF | CURSOR_OFF | CURSOR_BLINK_OFF)
	rcall	LCD_DisplayMode
	; LCD-scherm wissen
	rcall	LCD_Clear
	; entry-mode instellen (AUTO-INCREMENT)
	ldi		R16, (AUTO_INCREMENT | NO_DISPLAY_SHIFT)
	rcall	LCD_EntryMode
	; Scherm aan, cursor aan, knipperen uit
	ldi		R16, (DISPLAY_ON | CURSOR_OFF | CURSOR_BLINK_OFF)
	rcall	LCD_DisplayMode

	rcall	delay15ms					; 15 milli-seconde pauze
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD-Init + Splashscreen
;--------------------------------------\
LCD_Initialize:
	push	R16
	push	R17
	; het LCD initialiseren
	rcall	LCD_Init
	; De zelf-gedefinieerde tekens uploaden naar het LCD
	; register temp bits 5..0 bevatten het CGRAM adres
	ldi		R17, 0					; |
	ldi		ZL, low(CChar0)
	ldi		ZH, high(CChar0)
	rcall	LCD_CustomCharacter
	ldi		R17, 1					; ||
	ldi		ZL, low(CChar1)
	ldi		ZH, high(CChar1)
	rcall	LCD_CustomCharacter
	ldi		R17, 2					; |||
	ldi		ZL, low(CChar2)
	ldi		ZH, high(CChar2)
	rcall	LCD_CustomCharacter
	ldi		R17, 3					; ||||
	ldi		ZL, low(CChar3)
	ldi		ZH, high(CChar3)
	rcall	LCD_CustomCharacter
	ldi		R17, 4					; |||||
	ldi		ZL, low(CChar4)
	ldi		ZH, high(CChar4)
	rcall	LCD_CustomCharacter
	; Een intro laten zien direct na een RESET
	rcall	LCD_SplashScreen
	;scherm wissen, cursor op 1e positie 1e regel, cursor knipperend
	rcall	LCD_Clear
	rcall	LCD_Home
	ldi		R16, (DISPLAY_ON | CURSOR_ON | CURSOR_BLINK_ON)
	rcall	LCD_DisplayMode
	pop		R17
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- De 2 regels tekst in het splashScreen afbeelden
;--- input:	R17 = column [0..19]
;--- 		R18 = row [0..3]
;--------------------------------------\
SplashText:
	push	R16
	push	R17
	push	R18
	ldi		R17, 1
	ldi		R18, 1
	rcall	LCD_SetCursorXY
	ldi		ZL, low(2*SplashText0)
	ldi		ZH, high(2*SplashText0)
	rcall	LCD_Print_
	ldi		R17, 1
	ldi		R18, 2
	rcall	LCD_SetCursorXY
	ldi		ZL, low(2*SplashText1)
	ldi		ZH, high(2*SplashText1)
	rcall	LCD_Print_
	pop		R18
	pop		R17
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- Een intro direct na een RESET
;--------------------------------------\
LCD_SplashScreen:
	push	R16
	rcall	delaySplash					; pauze inlassen
	; LCD-scherm wissen
	rcall	LCD_Clear
	; R17 x het intro laten zien
	ldi		R17, 3
SplashStart:
	push	R17				;!!!! register R17 op stack pushen

	rcall	LCD_Clear
	rcall	SplashText
	rcall	delaySplash					; pauze inlassen
	; pixels vermeerderen
	ldi		R16, 0						; CG teken 0 (1 pixel blokje)
SplashLoop2:
	rcall	LCD_Fill
	rcall	SplashText
	rcall	delaySplash					; pauze inlassen
	inc		R16
	cpi		R16, 5
	brne	SplashLoop2					; 
	; pixels verminderen
	ldi		R16, 4						; CG teken 4 (vol blokje)
SplashLoop1:
	rcall	LCD_Fill
	rcall	SplashText
	rcall	delaySplash					; pauze inlassen
	dec		R16
	brpl	SplashLoop1

	pop		R17				;!!!! register R17 van stack poppen
	dec		R17
	cpi		R17, 0
	brne	SplashStart

	rcall	LCD_Clear
	rcall	SplashText
	rcall	delaySplash1_5s				; pauze inlassen
	rcall	LCD_Clear
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- Een string afbeelden op LCD-display
;---	input:	register Z (R31:R30)= string-adres*2
;--------------------------------------\
LCD_Print:
	;methode 2: lees uit FLASH/PROGRAM-memory
	lsl		ZL							; Z*2
	rol		ZH
LCD_Print_:
	push	R16
LCD_Print_loop:
	lpm									; Register R0 <- Program Memory [Z]  (R0 = CharReg)
	adiw	ZL, 1						; Adres in Z-Register verhogen
	mov		R16, R0
	cpi		R16, EOS_Symbol
	breq	EOS
	rcall	LCD_Data
	rjmp	LCD_Print_loop
EOS:
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- Een string afbeelden op LCD-display
;--- De cursor wordt zelf verplaatst naar de volgende
;--- logische positie op het scherm. (regel 1,2,3,4 ipv. regel 1,3,2,4)
;---	input:	R16 = ASCII-waarde
;--------------------------------------\
LCD_LinePrintChar:
	push	R19;
	push 	R18;!
	push	R17;!!						; nieuwe cursor-positie

	clr		R19							; vlag wissen (cursor niet verplaatsen)
	push	R16;!!!
	rcall	LCD_GetCursorXY
	;--- R17 = column [0..19]
	;--- R18 = row [0..3]
	cpi		R17, 19						; cursor op laatste positie van een regel?
	brne	printChar
	ser		R19							; vlag zetten als cursor met de hand verplaatst moet worden
printChar:
	pop		R16;!!!
	rcall	LCD_Data					; ASCII-waarde schrijven naar LCD

	tst		R19
	breq	Exit_LinePrintChar

	clr		R17							; 1e positie nieuwe regel
	inc		R18							; volgende regel
	cpi		R18, 4
	brmi	SetNewLine
	rcall	LCD_ScrollUp				;|\1 De scherminhoud omhoog scrollen
	rjmp	Exit_LinePrintChar			;|/
;	ldi		temp3, 0					;|-2 of  naar de 1e regel overlopen
SetNewLine:
	rcall	LCD_SetCursorXY

Exit_LinePrintChar:
	pop		R17;!!
	pop		R18;!
	pop		R19
	ret
;--------------------------------------/


;---------------------------------------
;--- Een Hex-Nibble afbeelden
;---	input:	R16 bits 3-0 = nibble
;--------------------------------------\
LCD_HexNibble:
	push	R17
	andi	R16, $0F
	; naar ASCII converteren
	cpi		R16, $0A
	brsh	isHex
	; een getal van 0-9
	ldi		R17, $30
	rjmp	isBCD
isHex:
	; een getal van A-F
	ldi		R17, $41-10
isBCD:
	add		R16, R17
	; het teken afbeelden op LCD
	rcall	LCD_LinePrintChar ;LCD_Data
	pop		R17
	ret
;--------------------------------------/


;---------------------------------------
;--- Een Hex-Byte afbeelden
;---	input:	R16 b7-3, b3-0 = byte
;--------------------------------------\
LCD_HexByte:
	push	R16
	swap	R16
	rcall	LCD_HexNibble
	pop		R16
	rcall	LCD_HexNibble
	ret
;--------------------------------------/


;---------------------------------------
;--- Een Hex-Word afbeelden
;---	input:	waarde in Z = word-waarde
;--------------------------------------\
LCD_HexWord:
	push	R16
	mov		R16, ZH
	rcall	LCD_HexByte
	mov		R16, ZL
	rcall	LCD_HexByte
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- Een regel leegmaken vanaf de 
;--- opgegeven kolom tot aan het einde 
;--- van de regel.
;---	input:	R17 = column [0..19]
;---			R18 = row [0..3]
;--------------------------------------\
LCD_ClearLineFromXY:
	push	R16
	rcall	LCD_SetCursorXY				; cursor plaatsen
NextPos:
	ldi		R16, ' '					; een spatie....
	rcall	LCD_Data					; ....afbeelden op cursor-positie
	inc		R17							; volgende kolom
	cpi		R17, 20
	brlo	NextPos
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- Een hele LCD-regel copiëren naar andere regel
;--- input: R17 = beginadres src
;---        R18 = beginadres dest
;---        R16  = aantal tekens n
;--------------------------------------\
LCD_CopyLine:
	push	XL							; src
	push	XH							; dest
	push	YL							; n tekens
	push	R19							; vooruit/achteruit copiëren
	push	R17

	mov		YL, R16						; aantal tekens te copiëren overnemen naar YL
	; src<dest? dan vanaf src+n beginnen met copy naar dest+n, n--
	; src>dest? dan vanaf src beginnen met copy naar dest, n++
	cp		R17, R18
	brmi	CountBack
	brpl	CountForward
	; src = dest
	rjmp	Done_CopyLine
CountBack:
	ser		R19							; achteruit tellen
	mov		XL, R17						; XL vullen met het src-sdres
	add		XL, YL
	dec		XL							; XL bevat het src-adres van de 1e te copiëren byte
	mov		XH, R18						; XH vullen met het dest-adres
	add		XH, YL
	dec		XH							; XH bevat het dest-adres van de 1e te copiëren byte
	rjmp	StartCopy
CountForward:
	clr		R19							; vooruit tellen
	mov		XL, R17						; XL bevat het src-adres van de 1e te copiëren byte
	mov		XH, R18						; XH bevat het dest-adres van de 1e te copiëren byte

StartCopy:
	; huidige cursor-positie opvragen en bewaren
	rcall	LCD_GetDisplayAddr
	push	R16
CopyLoop:
	; plaats cursor op source plaasten (XL)
	mov		R16, XL
	rcall	LCD_SetDisplayAddr
	; teken lezen op cursor-positie
	rcall	LCD_Read_Data
	mov		R17, R16
	; plaats cursor op dest. plaasten (XH)
	mov		R16, XH
	rcall	LCD_SetDisplayAddr
	; gelezen teken schrijven
	mov		R16, R17
	rcall	LCD_Data
	; teller op volgende teken plaatsen
	tst		R19
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
	pop		R16
	rcall	LCD_SetDisplayAddr

Done_CopyLine:
	pop		R17
	pop		R19
	pop		YL
	pop		XH
	pop		XL
	ret
;--------------------------------------/


;---------------------------------------
;--- Het hele scherm vullen met het teken in R16
;---	input:	R16 = ASCII-teken
;--------------------------------------\
LCD_Fill:
	push	R16
	push	R17
	push	R18

	ldi		R17, 0						; 1e kolom
	ldi		R18, 0						; 1e rij
	rcall	LCD_SetCursorXY
NextFill0:
	rcall	LCD_Data					; ....afbeelden op cursor-positie
	inc		R17							; volgende kolom
	cpi		R17, 40;20					; de regel loopt over in de 3e regel, 1e positie
	brne	NextFill0
	;
	ldi		R17, 0						; 1e kolom
	ldi		R18, 1						; 2e rij
	rcall	LCD_SetCursorXY
NextFill1:
	rcall	LCD_Data					; ....afbeelden op cursor-positie
	inc		R17							; volgende kolom
	cpi		R17, 40;20					; de regel loopt over in de 4e regel, 1e positie
	brne	NextFill1
	;
	pop		R18
	pop		R17
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- Scroll de LCD-inhoud 1 regel
;--------------------------------------\
LCD_ScrollUp:
	push	R16
	push	R17
	push	R18
	; 2e regel naar de 1e
	ldi		R17, AddrLine1
	ldi		R18, AddrLine0
	ldi		R16, 20
	rcall	LCD_CopyLine
	; 3e regel naar de 2e
	ldi		R17, AddrLine2
	ldi		R18, AddrLine1
	ldi		R16, 20
	rcall	LCD_CopyLine
	; 4e regel naar de 3e
	ldi		R17, AddrLine3
	ldi		R18, AddrLine2
	ldi		R16, 20
	rcall	LCD_CopyLine
	; 4e regel legen
	ldi		R17, 0
	ldi		R18, 3
	rcall	LCD_ClearLineFromXY
	; cursor op begin van 4e regel plaatsen
	ldi		R17, 0
	ldi		R18, 3
	rcall	LCD_SetCursorXY
	pop		R18
	pop		R17
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD LineHome
;--- Cursor naar begin van huidige regel
;--------------------------------------\
LCD_LineHome:
	push	R16
	push	R17
	push	R18
	rcall	LCD_GetCursorXY				; R17 = column [0..19], R18 = row [0..3]
	clr		R17
	rcall	LCD_SetCursorXY
	pop		R18
	pop		R17
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD LineEnd
;--- Cursor naar einde tekst op huidige regel
;--------------------------------------\
LCD_LineEnd:
	push	XL
	push	R16
	push	R17
	push	R18
	push	R19
	; bepaal vanaf het einde van de regel of
	; het teken nog een spatie is..
	rcall	LCD_GetCursorXY				; R17 = column [0..19], R18 = row [0..3]
	clr		R17
	rcall	LCD_XY2Addr
	mov		XL, R16						; XL = LCD Cursor AC op laatste teken deze regel
	ldi		R19, 19
	add		XL, R19
NextEOL:
	mov		R16, XL
	rcall	LCD_SetDisplayAddr
	; teken lezen op cursor-positie
	rcall	LCD_Read_Data
	cpi		R16, ' '
	brne	_nEOL
	dec		XL
	dec		R19
	brpl	NextEOL
_nEOL:
	mov		R16, XL						; auto-increment herstellen
	rcall	LCD_SetDisplayAddr			;
	mov		R16, XL
	rcall	LCD_Addr2XY					; R17 = column [0..19], R18 = row [0..3]
	cpi		R16, 19
	breq	Done_LineEnd
	inc		R17
	rcall	LCD_SetCursorXY
Done_LineEnd:
	pop		R19
	pop		R18
	pop		R17
	pop		R16
	pop		XL
	ret
;--------------------------------------/


;---------------------------------------
;--- De cursor naar de volgende regel
;--- op het LCD verplaatsen.
;--------------------------------------\
LCD_NextLine:
	push	R16
	push	R17
	push	R18
	rcall	LCD_GetCursorXY
	;--- R17 = column [0..19]
	;--- R18 = row [0..3]
	inc		R18
	cpi		R18, 4
	brne	SetNextLine
	; overlopen naar 1e regel
;	ldi		R18, 0
	; of scherminhoud scrollen
	rcall	LCD_ScrollUp				; De scherminhoud omhoog scrollen
	rjmp	Done_NextLine
SetNextLine:
	;cursor naar de logisch volgende regel verplaasten.
	clr		R17
	rcall	LCD_SetCursorXY
Done_NextLine:
	pop		R18
	pop		R17
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD_BackSpace
;--------------------------------------\
LCD_BackSpace:
	push	R2
	push	R3
	push	R16
	push	R17
	push	R18
	push	R19

	;- Lees de huidige LCD cursor positie
	rcall	LCD_GetCursorXY
	;--- R17 = column [0..19]
	;--- R18 = row [0..3]
	mov		R2, R17
	mov		R3, R18

	;- Bepaal hoeveel tekens er gekopieerd moeten worden
	ldi		R19, 19+1
	sub		R19, R17
	;- Copy 'R16' vanaf 'cursorpositie' naar 'cursorpositie-1'
	; huidige cursorpositie staat nu in R17,R18. Converteren naar een LCD DDRAM-adres in temp
	rcall	LCD_XY2Addr
	push	R16						;!!! src. bewaren op de stack
	tst		R17
	breq	_is0
	dec		R17							; cursorpositie-1 in temp2,temp3
  _is0:
	rcall	LCD_XY2Addr					; Converteren naar een LCD DDRAM-adres in temp
	mov		R18, R16					; dest.
	pop		R17						;!!! src. ophalen van de stack
	mov		R16, R19					; aantal te copieren tekens
	rcall	LCD_CopyLine

Done_BackSpace:
	; Huidige regel vanaf rechts aanvullen met spaties
	ldi		R17, 19
	mov		R18, R3
	rcall	LCD_SetCursorXY
	ldi		R16, ' '
	rcall	LCD_Data
	;- Stel de LCD cursor positie in op huidige-1
	tst		R2
	breq	__is0
	dec		R2
__is0:
	mov		R17, R2
	mov		R18, R3
	rcall	LCD_SetCursorXY

	pop		R19
	pop		R18
	pop		R17
	pop		R16
	pop		R3
	pop		R2
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD Delete
;--------------------------------------\
LCD_Delete:
	push	R2
	push	R3
	push	R16
	push	R17
	push	R18
	push	R19

	;- Lees de huidige LCD cursor positie
	rcall	LCD_GetCursorXY
	;--- R17 = column [0..19]
	;--- R18 = row [0..3]
	mov		R2, R17
	mov		R3, R18

	;- Bepaal hoeveel tekens er gekopieerd moeten worden
	ldi		R19, 19
	sub		R19, R17
	;- Copy 'R16' vanaf 'cursorpositie+1' naar 'cursorpositie'
	; huidige cursorpositie staat nu in R17,R18. Converteren naar een LCD DDRAM-adres in temp
	rcall	LCD_XY2Addr
	push	R16							;!!! dest. bewaren op de stack
	inc		R17							; cursorpositie+1 in temp2,temp3
	rcall	LCD_XY2Addr					; Converteren naar een LCD DDRAM-adres in temp
	mov		R17, R16					; src.
	pop		R18							;!!! dest. ophalen van de stack
	mov		R16, R19					; aantal te copieren tekens
	rcall	LCD_CopyLine

Done_Delete:
	; Huidige regel vanaf rechts aanvullen met spaties
	ldi		R17, 19
	mov		R18, R3
	rcall	LCD_SetCursorXY
	ldi		R16, ' '
	rcall	LCD_Data
	;- Herstel de LCD cursor positie
	mov		R17, R2
	mov		R18, R3
	rcall	LCD_SetCursorXY

	pop		R19
	pop		R18
	pop		R17
	pop		R16
	pop		R3
	pop		R2
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD Insert
;--- input: R16 = in te voegen teken
;--------------------------------------\
LCD_Insert:
	push	R2
	push	R3
	push	R4
	mov		R4, R16
	push	R17
	push	R18
	push	R19
	;- Lees de huidige LCD cursor positie
	rcall	LCD_GetCursorXY
	;--- R17 = column [0..19]
	;--- R18 = row [0..3]
	mov		R2, R17
	mov		R3, R18

	;- Bepaal hoeveel tekens er gekopieerd moeten worden
	ldi		R19, 19
	sub		R19, R17
	breq	Done_Insert
	;- Copy 'R16' vanaf 'cursorpositie' naar 'cursorpositie+1'
	; huidige cursorpositie staat nu in R17,R18. Converteren naar een LCD DDRAM-adres in temp
	rcall	LCD_XY2Addr
	push	R16							;!!! src. bewaren op de stack
	inc		R17							; cursorpositie+1 in temp2,temp3
	rcall	LCD_XY2Addr					; Converteren naar een LCD DDRAM-adres in temp
	mov		R18, R16					; dest.
	pop		R17							;!!! src. ophalen van de stack
	mov		R16, R19					; aantal te copieren tekens
	rcall	LCD_CopyLine

Done_Insert:
	; Huidige cursorpositie vullen met het af te beelden teken
	mov		R17, R2
	mov		R18, R3
	rcall	LCD_SetCursorXY
	mov		R16, R4

	rcall	LCD_LinePrintChar
;	rcall	LCD_Data
;	;- Herstel de LCD cursor positie
;	mov		R17, R2
;	mov		R18, R3
;	rcall	LCD_SetCursorXY

	pop		R19
	pop		R18
	pop		R17
	mov		R16, R4
	pop		R4
	pop		R3
	pop		R2
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD Arrow
;--- input: R16 = richting cursorbeweging
;---               ==0 => omhoog
;---               ==1 => omlaag
;---               ==2 => rechts
;---               ==3 => links
;--------------------------------------\
LCD_Arrow:
	push	R17
	push	R18
	rcall	LCD_GetCursorXY
	;--- R17 = column [0..19]
	;--- R18 = row [0..3]
ArrowUp:
	cpi		R16,0
	brne	ArrowDn
	cpi		R18, 0
	breq	Done_Arrow
	dec		R18
	rjmp	MoveCursor
ArrowDn:
	cpi		R16,1
	brne	ArrowR
	cpi		R18, 3
	breq	Done_Arrow
	inc		R18
	rjmp	MoveCursor
ArrowR:
	cpi		R16,2
	brne	ArrowL
	cpi		R17, 19
	breq	Done_Arrow
	inc		R17
	rjmp	MoveCursor
ArrowL:
	cpi		R16,3
	brne	Done_Arrow
	cpi		R17, 0
	breq	Done_Arrow
	dec		R17
MoveCursor:
	rcall	LCD_SetCursorXY
Done_Arrow:
	pop		R18
	pop		R17
	ret
;--------------------------------------/







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
	push	R16
	; een rcall instructie neemt 3 cycles in beslag	|	  1*3 =   3 +
	ldi		R16, 131					; 1 cycle	|	  1*1 =   1 +
innerloop100us:							;			|
	dec		R16							; 1 cycle	|	131*1 = 131 +
	brne	innerloop100us				; 2 cycles	>	130*2 = 260 +	;132 x wordt de branche genomen (springen = 2 cycles)
										; 1 cycle	|	  1*1 =   1 +	;bij de laatste branche wordt niet gesprongen (1 cycle)
	pop		R16
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
	push	R16
	; een rcall instructie neemt 3 cycles in beslag	|	    1*3 =      3 +	   \
	ldi		R16, 148					; 1 cycle	|	    1*1 =      1 +		|
innerloop15ms:							;			|							|
	rcall	delay100us					; 3 cycles	|	148*400 =  59200 +		|
	dec		R16							; 1 cycle	|	  148*1 =    148 +		|
	brne	innerloop15ms				; 2 cycles	>	  147*2 =    294 +		|
										; 1 cycle	|	    1*1 =      1 +		|
										;				------------------		|
										;				          59650			>	 59650 +
	;350 cycles to go....														|	   350 +
	ldi		R16, 115					; 1 cycle	|	    1*1 =      1 +		|	--------
innerloop15ms_:							;			|							|	 60000 cycles
	dec		R16							; 1 cycle	|	  115*1 =    115 +		|
	brne	innerloop15ms_				; 2 cycles	>	  114*2 =    228 +		|
										; 1 cycle	|	    1*1 =      1 +		|
	nop									; 1 cycle	|	    1*1 =	   1 +		|
	pop		R16
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
	push	R16
	; een rcall instructie neemt 3 cycles in beslag	|	    1*3 =      3 +	   \
	ldi		R16, 40						; 1 cycle	|	    1*1 =      1 +		|
innerloop4_1ms:							;			|							|
	rcall	delay100us					; 3 cycles	|	 40*400 =  16000 +		|
	dec		R16							; 1 cycle	|	   40*1 =     40 +		|
	brne	innerloop4_1ms				; 2 cycles	>	   39*2 =     78 +		|
										; 1 cycle	|	    1*1 =      1 +		|
										;				------------------		|
										;				           16123		>	 16123 +
	;277 cycles to go....														|	   277 +
	ldi		R16, 92						; 1 cycle	|	    1*1 =      1 +		|	--------
innerloop4_1ms_:						;			|							|	 16400 cycles
	dec		R16							; 1 cycle	|	   92*1 =     92 +		|
	brne	innerloop15ms_				; 2 cycles	>	   91*2 =    182 +		|
										; 1 cycle	|	    1*1 =      1 +		|
	nop									; 1 cycle	|	    1*1 =	   1 +		|
	pop		R16
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
	push	R16
	; een rcall instructie neemt 3 cycles in beslag	|	    1*3 =      3 +	   \
	ldi		R16, 9						; 1 cycle	|	    1*1 =      1 +		|
innerloop1ms:							;			|							|
	rcall	delay100us					; 3 cycles	|	  9*400 =   3600 +		|
	dec		R16							; 1 cycle	|	    9*1 =      9 +		|
	brne	innerloop1ms				; 2 cycles	>	    8*2 =     16 +		|
										; 1 cycle	|	    1*1 =      1 +		|
										;				------------------		|
										;				            3630	    >	 3630 +
	;370 cycles to go....				;										|	  370 +
	ldi		R16, 122					; 1 cycle	|	    1*1 =      1 +		|	-----
innerloop1ms_:							;			|							|	 4000 cycles
	dec		R16							; 1 cycle	|	  122*1 =    122 +		|
	brne	innerloop1ms_				; 2 cycles	>	  121*2 =    242 +		|
										; 1 cycle	|	    1*1 =      1 +		|
	pop		R16
	ret									; 4 cycles	|	    1*4 =      4		|
										;				------------------		|
										;				             370	   /






;---------------------------------------
delaySplash:
	push	R16
	ldi		R16, 10					; pauze tbv. splashscreen direct na RESET
innerloopSplash:
	rcall	delay15ms
	dec		R16
	brne	innerloopSplash
	pop		R16
	ret

delaySplash1_5s:
	push	R16
	ldi		R16, 100
innerloopSplash1_5s:
	rcall	delay15ms
	dec		R16
	brne	innerloopSplash1_5s
	pop		R16
	ret

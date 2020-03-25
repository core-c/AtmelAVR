;---------------------------------------------------------------------------------
;---
;---  LCD HD44780 constanten en macro's					Ron Driessen
;---  AVR AT90S8535										2005
;---
;---------------------------------------------------------------------------------
.ifndef Linked_LCD_HD44780
	.ifndef Link_LCD_HD44780					; Deze unit markeren als zijnde ingelinkt,
		.equ Link_LCD_HD44780 = 1				; in geval dat nog niet eerder is gebeurd in code.
	.endif										; (Units nl. maar 1x inlinken)
	.equ Linked_LCD_HD44780 = 1					;
.endif
; de Delay-unit inlinken als dat nog niet is gebeurd..
.ifndef Linked_AVR_Delay
	.ifndef Link_AVR_Delay
		.equ Link_AVR_Delay = 1
	.endif
	.equ Linked_AVR_Delay = 1
	.include "AVR_Delay.asm"					; Vertragingen in US, MS & Seconden
.endif





;********************************************************************************
;***
;***  Een implementatie voor een 8-bit LCD aansturing
;***
;***	LCD	8-bit   AVR
;***	---------  	-----------------------------
;***	1	Vss	   	GND 
;***	2	Vcc	  	5V 
;***	3	Vee	  	GND of naar een potmeter
;***	4	RS	  	PA5 \
;***	5	RW	  	PA6  } control lijnen (OUTPUT)
;***	6	E	  	PA7 /
;***	7	DB0	  	PC0 \
;***	8	DB1	  	PC1 |
;***	9	DB2	  	PC2 |
;***	10	DB3	  	PC3  } data lijnen (INPUT/OUTPUT)
;***	11	DB4	  	PC4 |
;***	12	DB5	  	PC5 |
;***	13	DB6	  	PC6 |
;***	14	DB7	  	PC7 /
;***
;***
;*** RW hoog = lezen,
;*** RW laag = schrijven.
;***
;*** RS hoog = DATA,
;*** RS laag= COMMANDO
;***
;*** Als RW=hoog en RS=laag, (commando lezen), dan kan de busy-flag (+AddressCounter) gelezen worden.
;***
;*** Als de LED-Display pin RW aan de AVR-GND aangesloten is, dan kan er geen
;*** busy-flag gelezen worden om te bepalen of commando's verwerkt zijn. In dat
;*** geval moeten er korte pauzes ingelast worden tussen bevelen/commando's om er
;*** zeker van te zijn dat commando's verwerkt zijn.
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
;*** Tekens met ASCII-code 0b10000000 t/m 0b10011111 zijn niet gedefiniëerd.
;***
;********************************************************************************


;--- COMPLIER DIRECTIVES --\
;.equ DATA_LEN			= 8	; compileer voor een 8-bits InterFace
.equ CopyViaSRAM		= 1	; boolean: 0 (false) of 1 (true)
							; 1=Regels copieeren via SRAM, 0=direct copieeren (geen SRAM)
;--------------------------/

;--------------------------------------\
.if CopyViaSRAM == 1
	.DSEG
	LCD_Data_Buffer: .BYTE 20			; plek voor 1 complete LCD-regel
	.CSEG
.endif
;--------------------------------------/



;--- Toegekende poorten & pinnen ----------\
;--- De control-port en control-lijnen -----
.equ LCD_CTRL_PORT	= PORTA					; De control-port (alleen als OUTPUT)
.equ LCD_CTRL_DDR	= DDRA					; Het Data-Direction-Register van de control-port
.equ LCD_RS			= PA5					; RS op pin 5 van poort A
.equ LCD_RW			= PA6					; RW op pin 6 van poort A
.equ LCD_E			= PA7					; E op pin 7 van poort A
;--- De data-port en data-lijnen -----------
.equ LCD_DATA_PORT	= PORTC					; De data-port DB7-0 (INPUT/OUTPUT)
.equ LCD_DATA_DDR	= DDRC					;
.equ LCD_DATA_IN	= PINC					; Input data lezen van deze poort
.equ LCD_BUSY		= PC7					; Busy-Flag op pin 7 van poort C (=DB7)
;--- De datalijnen -------------------------
.equ LCD_DB0		= PC0					; 
.equ LCD_DB1		= PC1					;
.equ LCD_DB2		= PC2					;
.equ LCD_DB3		= PC3					;
.equ LCD_DB4		= PC4					; 
.equ LCD_DB5		= PC5					;
.equ LCD_DB6		= PC6					;
.equ LCD_DB7		= PC7					;
;------------------------------------------/


;--- I/O -----------------------------------
.equ PIN_AS_INPUT		= 0					; Een pin als input instellen
.equ PIN_AS_OUTPUT		= 1					; Een pin als output instellen
.equ PORT_AS_INPUT		= $00				; Een poort als input instellen
.equ PORT_AS_OUTPUT		= $FF				; Een poort als output instellen
.equ INPUT_PORT_TRIS	= $00				; Een input-poort's tristate instellen
.equ INPUT_PORT_PULL	= $FF				; Een input-poort's pull-up weerstanden inschakelen


;--- LCD Begin-adressen van elke regel -----
.equ AddrLine0	= $00
.equ AddrLine1	= $40
.equ AddrLine2	= $14
.equ AddrLine3	= $54
;--- Bits ----------------------------------
; RS:Register Selector. RS=0:IR (Instruction Register), RS=1:DR (Data Register)
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


;--- Vlaggen ------------------\
.equ Flag_Display			= 7	; bit 7: 1=Display aan,				0=Display uit
.equ Flag_Cursor			= 6	; bit 6: 1=Cursor aan,				0=Cursor uit
.equ Flag_CursorBlock		= 5	; bit 5: 1=Blok cursor,				0=Streep cursor
.equ Flag_CursorBlinking	= 4	; bit 4: 1=Knipperen cursor aan,	0=uit
.equ Flag_Scrolling			= 3	; bit 3: 1=scrolling aan,			0=scrolling uit
.equ Flag_WordWrap			= 2	; bit 2: 1=word-wrap aan,			0=word-wrap uit
.equ Flag_ClearNewLine		= 1	; bit 1: 1=nieuwe regel wissen, 	0=nieuwe regel niet legen
.equ Flag_FullScreen		= 0	; bit 0: 1=fullscreen backspace/delete/insert/wordwrap aan, 0=uit (nog niet geïmplementeerd)
;------------------------------/


;--- Registers ------------\
.def LCD_Flags		= R10	; Vlaggen voor software-matig in te stellen zaken
.def LCD_LastChar	= R11	; Het laatst afgebeelde teken (de cursor staat er nu net achter)
;--------------------------/


;---------------------------------------
;--- Zelf-gedefinieerde tekens
;--  in programma(/flash)-geheugen
;--------------------------------------\
.CSEG
;		      ___12345
;CChar0:.db	0b00011111;1
;		.db	0b00010000;2
;		.db	0b00011111;3
;		.db	0b00010000;4
;		.db	0b00010000;5
;		.db	0b00010000;6
;		.db	0b00000000;7
;		.db	0b00000000;|
; Omdat het Flash/programma-geheugen per word is te adresseren
; dienen de bytes voor de patronen ook per word worden opgeslagen.
;             2_______1_______,  4_______3_______,  6_______5_______,  8_______7_______
CChar0:	.dw	0b0001001100011001,0b0000110000000110,0b0001001100011001,0b0000110000000110
CChar1:	.dw	0b0000011000010011,0b0001100100001100,0b0000011000010011,0b0001100100001100
CChar2:	.dw	0b0000110000000110,0b0001001100011001,0b0000110000000110,0b0001001100011001
CChar3:	.dw	0b0001100100001100,0b0000011000010011,0b0001100100001100,0b0000011000010011

;--- Teksten in programma(/flash)-geheugen
.CSEG
;--- Het SplashScreen
.equ EOS_Symbol	= '$'					; End-Of-String teken
SplashText1: .db "   AVR-Team UJE   ", EOS_Symbol, 0
SplashText2: .db "LCD HD44780  8-bit", EOS_Symbol, 0
;--- InfoScreen (LCD_CMD_1F)
InfoText0: .db "  Firmware v0.90-RD ", EOS_Symbol, 0
InfoText1: .db "  AT90S8535 code    ", EOS_Symbol, 0
InfoText2: .db "  LCD_HD44780.asm   ", EOS_Symbol, 0
InfoText3: .db "  8-bit IF          ", EOS_Symbol, 0
;--------------------------------------/







;--- Vertragingen / wachttijden -------\
.MACRO LCD_Delay_Init0
	rcall	LCD_Delay100ms				; vertraging 100 milli-seconden
.ENDMACRO

.MACRO LCD_Delay_Init1
	rcall	LCD_Delay4_1ms				; vertraging 4.1 milli-seconden
.ENDMACRO

.MACRO LCD_Delay_Init2
	rcall	LCD_Delay100us				; vertraging 100 micro-seconden
.ENDMACRO

.MACRO LCD_Delay_Init3
	rcall	LCD_Delay15ms				; vertraging 15 milli-seconden
.ENDMACRO


.MACRO LCD_Delay_Enable
	rcall	LCD_Delay2us				; Enable toggle vertraging 2 us
.ENDMACRO

.MACRO LCD_Delay_AfterWrite
	rcall	LCD_Delay40us				; vertraging na een schrijfactie 40 us
.ENDMACRO

.MACRO LCD_Delay_AfterRead
	rcall	LCD_Delay40us				; vertraging na een leesactie 40 us
.ENDMACRO

.MACRO LCD_Delay_AfterCMD
	rcall	LCD_Delay2ms				; vertraging na een Clear Command >1.52ms (ik heb 'm op 2ms)
.ENDMACRO

.MACRO LCD_Delay_SwapRAM
	rcall	LCD_Delay120u				; vertraging na een CG-/DD-RAM selectie wissel (120us)
.ENDMACRO


.MACRO LCD_Delay_SplashShort
	rcall	LCD_Delay150ms				; vertraging 150 milli-seconden
.ENDMACRO

.MACRO LCD_Delay_SplashLong
	rcall	LCD_Delay1_5s				; vertraging 1.5 seconde
.ENDMACRO
;--------------------------------------/



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
	LCD_Delay_Enable
.ENDMACRO

.MACRO LCD_CTRL_Enable0
    cbi		LCD_CTRL_PORT, LCD_E		; E = 0
	LCD_Delay_Enable
.ENDMACRO

.MACRO LCD_CTRL_ToggleEnable
	LCD_CTRL_Enable1					; E = 1
	LCD_CTRL_Enable0					; E = 0
.ENDMACRO


.MACRO LCD_Send;(Value:register)
	LCD_Delay_Enable					; RS/RW setup time volgens datasheet 140ns
	LCD_CTRL_Enable1
    out		LCD_DATA_PORT, @0			; de waarde in register "Value" op de LCD data-poort zetten
	LCD_Delay_Enable
	LCD_CTRL_Enable0					; register waarde wordt nu overgedragen
	LCD_Delay_AfterWrite				; na een Write-opdracht tenminste 40us wachten..
.ENDMACRO

.MACRO LCD_Receive;(Value:register)
	LCD_Delay_Enable					; RS/RW setup time volgens datasheet 140ns
	LCD_CTRL_Enable1					; E = 1
	in		@0, LCD_DATA_IN				; de waarde op de LCD data-poort naar register "Value" overnemen
	LCD_CTRL_Enable0					; E = 0
	LCD_Delay_AfterRead					; na een Read-opdracht tenminste 40us wachten..
.ENDMACRO


.MACRO LCD_DataOut;(Data:register)
	LCD_CTRL_Data						; RS = 1 (data)
    LCD_CTRL_Write						; R/W = 0 (schrijven)
	LCD_Send @0							; Data zenden naar LCD
.ENDMACRO

.MACRO LCD_CommandOut;(Command:register)
	LCD_CTRL_Command					; RS = 0 (commando)
    LCD_CTRL_Write						; R/W = 0 (schrijven)
	LCD_Send @0							; Commando zenden naar LCD
.ENDMACRO

.MACRO LCD_DataIn;(Data:register)
	LCD_CTRL_Data						; RS = 1 (data)
	LCD_CTRL_Read						; R/W = 1 (lezen)
	LCD_Receive @0						; Data lezen van LCD
.ENDMACRO

.MACRO LCD_CommandIn;(Command:register)
	LCD_CTRL_Command					; RS = 0 (commando)
	LCD_CTRL_Read						; R/W = 1 (lezen)
	LCD_Receive @0						; Commando lezen van LCD
.ENDMACRO





;----------------------------------------------------------------------------------------
;---------- AVR pin richtingen
;----------------------------------------------------------------------------------------
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
LCD_SetDATAPort_AS_INPUT:
	push	R16
	ldi		R16, PORT_AS_INPUT		; poort zeker vrijgeven..
	out		LCD_DATA_DDR, R16
	ldi		R16, INPUT_PORT_TRIS
	out		LCD_DATA_PORT, R16
	pop		R16
	ret
;---------------------------------------
LCD_SetDATAPort_AS_OUTPUT:
	push	R16
	; poort zeker vrijgeven..
	rcall	LCD_SetDATAPort_AS_INPUT
	; ..en opnieuw instellen.
	ldi		R16,PORT_AS_OUTPUT		; output
	out		LCD_DATA_DDR, R16
	ldi		R16,0					; Push-Pull zero output
	out		LCD_DATA_PORT, R16
	pop		R16
	ret
;--------------------------------------/





;----------------------------------------------------------------------------------------
;---------- Commando's lezen
;----------------------------------------------------------------------------------------
;---------------------------------------
;--- CMD Lezen:
;--- Wachten zolang de LCD-controller
;--- nog bezig is met verwerken.
;--------------------------------------\
LCD_WaitWhileBusy:						; wacht op busy-flag==0
	push	R16
	; AVR poort richting instellen
	rcall	LCD_SetDATAPort_AS_INPUT	; AVR poort op input
	; LCD data poort richting instellen
	LCD_CTRL_Command					; RS = 0 (commando)
	LCD_CTRL_Read						; R/W = 1 (lezen)
	; wacht op busy-flag gewist..
WaitWhileBusyFlag1:
	LCD_Receive R16						; Commando lezen van LCD (busy-flag + een ongeldige AddressCounter)
	andi	R16, MASK_BUSYFlag			; busy flag filteren
	brne	WaitWhileBusyFlag1			; blijf wachten zolang de busy-flag nog is gezet
	; LCD data poort richting herstellen
    LCD_CTRL_Write						; R/W = 0 (schrijven)
	; AVR poort richting herstellen
	rcall	LCD_SetDATAPort_AS_OUTPUT	; AVR poort als output
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- CMD Lezen:
;--- LCD_GetDisplayAddr
;--- Resulteer de adres-counter waarde (DDRAM/CGRAM).
;---	output:	R16 bit6-0 : DDRAM/CGRAM adres (bit 7 wordt altijd 0)
;--------------------------------------\
LCD_GetDisplayAddr:
	; AVR poort richting instellen
	rcall	LCD_SetDATAPort_AS_INPUT	; AVR poort op input
	; LCD data poort richting instellen
	LCD_CTRL_Command					; RS = 0 (commando)
	LCD_CTRL_Read						; R/W = 1 (lezen)
	; wacht op busy-flag gewist..
wb0:LCD_Receive R16						; Commando lezen van LCD (busy-flag + een ongeldige AddressCounter)
	andi	R16, MASK_BUSYFlag			; busy flag filteren
	brne	wb0							; blijf wachten zolang de busy-flag nog is gezet
	; 4us later is de AddressCounter pas bijgewerkt..
	LCD_Delay_Enable					; het mag ietsje meer zijn..
	LCD_Delay_Enable
	LCD_Delay_Enable
	LCD_Delay_Enable
	; nu dan de AddressCounter inlezen..
	LCD_Receive R16						; Commando lezen van LCD (AC & BF)
	LCD_Receive R16						; (enkele keren voor de zekerheid ;)
	LCD_Receive R16						;
	LCD_Receive R16						;
	andi	R16, MASK_DDRAMAddress		; busy flag strippen en alleen adres overhouden
	; LCD data poort richting herstellen
    LCD_CTRL_Write						; R/W = 0 (schrijven)
	; AVR poort richting herstellen
	rcall	LCD_SetDATAPort_AS_OUTPUT	; AVR poort als output
	ret
;--------------------------------------/






;----------------------------------------------------------------------------------------
;---------------------------------------
;--- DATA Schrijven
;---	input:	R16 = data
;--------------------------------------\
LCD_WriteData:
	rcall	LCD_WaitWhileBusy			; wacht op busy-flag==0
	LCD_DataOut R16						; een byte schrijven naar de LCD Data poort
	rcall	LCD_WaitWhileBusy			; wacht op busy-flag==0
	ret
;--------------------------------------/


;---------------------------------------
;--- CMD Schrijven / Uitvoeren
;---	input:	R16 = commando
;--------------------------------------\
LCD_WriteCommand:						; Entry-point: incl. wachten op busy-flag
	rcall	LCD_WaitWhileBusy			; wacht op busy-flag==0
LCD_WriteCommand_:						; Entry-point: excl. wachten op busy-flag
	LCD_CommandOut R16					; een commando geven aan de LCD-controller
	rcall	LCD_WaitWhileBusy			; wacht op busy-flag==0
	ret
;--------------------------------------/



;---------------------------------------
;--- DATA Lezen
;---	output:	R16 = gelezen data
;--------------------------------------\
LCD_ReadData:
	rcall	LCD_WaitWhileBusy			; wacht op busy-flag==0
	; AVR poort richting instellen
	rcall	LCD_SetDATAPort_AS_INPUT	; AVR poort op input
	LCD_DataIn R16						; een byte lezen van de LCD Data poort
	; LCD data poort richting herstellen
    LCD_CTRL_Write						; R/W = 0 (schrijven)
	; AVR poort richting herstellen
	rcall	LCD_SetDATAPort_AS_OUTPUT	; AVR poort als output
	rcall	LCD_WaitWhileBusy			; wacht op busy-flag==0
	ret
;--------------------------------------/


;---------------------------------------
;--- CMD Lezen
;---	output:	R16 = gelezen commando
;--------------------------------------\
LCD_ReadCommand:
	rcall	LCD_WaitWhileBusy			; wacht op busy-flag==0
	; AVR poort richting instellen
	rcall	LCD_SetDATAPort_AS_INPUT	; AVR poort op input
	LCD_CommandIn R16					; een commando lezen van de LCD-controller
	; LCD data poort richting herstellen
    LCD_CTRL_Write						; R/W = 0 (schrijven)
	; AVR poort richting herstellen
	rcall	LCD_SetDATAPort_AS_OUTPUT	; AVR poort als output
	rcall	LCD_WaitWhileBusy			; wacht op busy-flag==0
	ret
;--------------------------------------/





;----------------------------------------------------------------------------------------
;---------- Commando's schrijven
;----------------------------------------------------------------------------------------
;---------------------------------------
;--- LCD-scherm wissen
;--------------------------------------\
LCD_Clear:
	push	R16
	ldi		R16, CMD_Clear
    rcall	LCD_WriteCommand
	LCD_Delay_AfterCMD					; na een Clear commando tenminste 1.52ms wachten
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD-cursor naar Home-positie
;--------------------------------------\
LCD_Home:
	push	R16
	ldi		R16, CMD_CursorHome
    rcall	LCD_WriteCommand
	LCD_Delay_AfterCMD					; na een Home commando tenminste 1.52ms wachten
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
    rcall	LCD_WriteCommand
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
    rcall	LCD_WriteCommand
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
    rcall	LCD_WriteCommand
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD_FunctionSet (Function Set)
;---	input:	R16 =	b2  : 0=5x7 dots font, 1=5x10 dots font
;--- 				 	b3  : 0=1/8 or 1/11 Duty (1 line), 1=1/16 Duty (2 lines) 
;--- 				 	b4  : 0=4-bit, 1=8-bit
;--------------------------------------\
LCD_FunctionSet:						; Entry-point: incl. wachten op busy-flag
	rcall	LCD_WaitWhileBusy
LCD_FunctionSet_:						; Entry-point: excl. wachten op busy-flag
	andi	R16, MASK_FunctionSet
	ori		R16, CMD_FunctionSet
    rcall	LCD_WriteCommand_			; commando uitvoeren zonder de busy-flag test
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD_SetCharGenAddr
;--- Instellen van het Character-Generator-RAM adres.
;--- CGRAM data lezen/schrijven na dit commando.
;---	input:	R16 = b0-5 : CGRAM adres
;--------------------------------------\
LCD_SetCharGenAddr:
	andi	R16, MASK_CGRAMAddress
	ori		R16, CMD_CGRAMAddress
    rcall	LCD_WriteCommand
	LCD_Delay_SwapRAM					; Na een CGRAM/DDRAM wissel tenminste 120us wachten
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD_SetDisplayAddr
;--- Instellen van het Display-Data-RAM adres.
;--- DDRAM data lezen/schrijven na dit commando.
;---	input:	R16 = b0-6 : DDRAM adres
;--------------------------------------\
LCD_SetDisplayAddr:
	LCD_Delay_SwapRAM					; onbekende voor-geschiedenis.. voor de zekerheid een delay
	ori		R16, CMD_DDRAMAddress
    rcall	LCD_WriteCommand
	LCD_Delay_SwapRAM					; Na een CGRAM/DDRAM wissel tenminste 120us wachten
	ret
;--------------------------------------/





;----------------------------------------------------------------------------------------
;---------------------------------------
;--- LCD-Init + Splashscreen + SW-config
;--------------------------------------\
LCD_Initialize:
	push	R16
	push	R17
	; het LCD initialiseren
	rcall	LCD_Init
	; Een intro laten zien direct na een RESET
	rcall	LCD_SplashScreen
	;scherm wissen, cursor op 1e positie 1e regel, cursor knipperend
	rcall	LCD_Clear
	rcall	LCD_Home
	;ldi	R16, (DISPLAY_ON | CURSOR_ON | CURSOR_BLINK_ON)
	;rcall	LCD_DisplayMode
	;--- softwarematig aan te passen LCD-instellingen
	ldi		R16, (1<<Flag_Display | 1<<Flag_Cursor | 1<<Flag_CursorBlock | 1<<Flag_Scrolling | 1<<Flag_WordWrap | 1<<Flag_ClearNewLine)
	mov		LCD_Flags, R16
	rcall	DisplayMode_From_Flags
	;---
	pop		R17
	pop		R16
	ret
;--------------------------------------/



;---------------------------------------
;--- LCD-Init de controller
;--------------------------------------\
LCD_Init:
	push	R16
	; LCD-Control poorten op AVR als output instellen
	rcall	LCD_SetCTRLPins
	; zo ook de LCD-Data poort op de AVR
	rcall	LCD_SetDATAPort_AS_OUTPUT
	; tenminste 40 milli-seconde pauze
	; na het inschakelen van de power (2.7V, 15ms bij 4.5V)
	LCD_Delay_Init0
	LCD_Delay_Init0
	; De InterFace initialiseren.
	; moet 3x gebeuren met pauzes ertussen....
	; instellen op 8-bits interface
    ldi		R16, DATA_LEN_8				; als 8-bit IF instellen
	rcall	LCD_FunctionSet_			; entry point zonder BF-test
	;
	LCD_Delay_Init1						; tenminste 4.1 milli-seconde pauze
	LCD_Delay_Init1
	;
    ldi		R16, DATA_LEN_8				; als 8-bit IF instellen
	rcall	LCD_FunctionSet_			; entry point zonder BF-test
	;
	LCD_Delay_Init2						; tenminste 100 micro-seconde pauze
	LCD_Delay_Init2
	;
    ldi		R16, DATA_LEN_8				; als 8-bit IF instellen
	rcall	LCD_FunctionSet_			; entry point zonder BF-test

	LCD_Delay_Init2						; tenminste 100 micro-seconde pauze
	LCD_Delay_Init2

	;!! vanaf nu kan de BUSY-flag worden afgevraagd.... 't werkt! / hij doet 't

	; Aantal regels en font instellen
    ldi		R16, (DATA_LEN_8 | LINE_COUNT_2 | FONT_5x7)
	rcall	LCD_FunctionSet				; entry point met BF-test
	LCD_Delay_Init1						; een korte pauze
	; display-mode initialiseren (alles uit)
	ldi		R16, (DISPLAY_OFF | CURSOR_OFF | CURSOR_BLINK_OFF)
	rcall	LCD_DisplayMode
	; LCD-scherm wissen
	rcall	LCD_Clear
	LCD_Delay_Init1						; een korte pauze
	; entry-mode instellen (AUTO-INCREMENT)
	ldi		R16, (AUTO_INCREMENT | NO_DISPLAY_SHIFT)
	rcall	LCD_EntryMode
	; Scherm aan, cursor aan, knipperen uit
	ldi		R16, (DISPLAY_ON | CURSOR_OFF | CURSOR_BLINK_OFF)
	rcall	LCD_DisplayMode

	LCD_Delay_Init3						; 15 milli-seconde pauze
	pop		R16
	ret
;--------------------------------------/



;---------------------------------------
;--- Software instellingen voor DisplayMode
;--- overnemen naar de LCD-hardware.
;--------------------------------------\
DisplayMode_From_Flags:
	push	R16
	push	R17
	; DisplayMode instellingen uit Flags overnemen..
	clr		R16
	mov		R17, LCD_Flags
	; Display aan/uit
	sbrc	R17, Flag_Display			; Display vlag niet aan?
	ori		R16, DISPLAY_ON
	; Cursor aan/uit
	sbrc	R17, Flag_Cursor			; Cursor vlag niet aan?
	ori		R16, CURSOR_ON
	; Cursor Block/Streep
	sbrc	R17, Flag_CursorBlock		; BlockCursor vlag niet aan?
	ori		R16, CURSOR_BLINK_ON
	; DisplayMode instellen..
	rcall	LCD_DisplayMode
	pop		R17
	pop		R16
	ret
;--------------------------------------/



;---------------------------------------
;--- Een intro direct na een RESET
;--------------------------------------\
LCD_SplashScreen:
	push	R16
	push	R17
	push	ZL
	push	ZH
	; De zelf-gedefinieerde tekens uploaden naar het LCD.
	; Register R16 bits 5..0 bevatten het CGRAM adres.
	ldi		R16, 0						; |
	ldi		ZL, low(CChar0)
	ldi		ZH, high(CChar0)
	rcall	LCD_CustomCharacter
	ldi		R16, 1						; ||
	ldi		ZL, low(CChar1)
	ldi		ZH, high(CChar1)
	rcall	LCD_CustomCharacter
	ldi		R16, 2						; |||
	ldi		ZL, low(CChar2)
	ldi		ZH, high(CChar2)
	rcall	LCD_CustomCharacter
	ldi		R16, 3						; ||||
	ldi		ZL, low(CChar3)
	ldi		ZH, high(CChar3)
	rcall	LCD_CustomCharacter
	;
	LCD_Delay_SplashShort				; korte pauze inlassen
	rcall	LCD_Clear					; LCD-scherm wissen
	rcall	SplashText
	LCD_Delay_SplashShort				; korte pauze inlassen

	; R17 x het intro laten zien
	ldi		R17, 6
SplashStart:
	push	R17				;!!!! register R17 op stack pushen
	; pixels animeren mbv. characters
	ldi		R16, 0						; CG teken 0
SplashLoop2:
	rcall	LCD_Fill
	rcall	SplashText
	LCD_Delay_SplashShort				; korte pauze inlassen
	inc		R16							; volgende CG teken
	cpi		R16, 4
	brne	SplashLoop2					; 
	pop		R17				;!!!! register R17 van stack poppen
	dec		R17
	brne	SplashStart

	; scherm leeg maken en tekst afbeelden
	rcall	LCD_Clear
	rcall	SplashText
	LCD_Delay_SplashLong				; pauze inlassen
	rcall	LCD_Clear
	
	pop		ZH
	pop		ZL
	pop		R17
	pop		R16
	ret
;---------------------------------------
;--- De 2 regels tekst in het splashScreen afbeelden
;--------------------------------------\
SplashText:
	push	R16
	push	R17
	push	R18
	ldi		R17, 1
	ldi		R18, 1
	rcall	LCD_SetCursorXY
	ldi		ZL, low(2*SplashText1)
	ldi		ZH, high(2*SplashText1)
	rcall	LCD_Print_From_Flash_
	ldi		R17, 1
	ldi		R18, 2
	rcall	LCD_SetCursorXY
	ldi		ZL, low(2*SplashText2)
	ldi		ZH, high(2*SplashText2)
	rcall	LCD_Print_From_Flash_
	pop		R18
	pop		R17
	pop		R16
	ret
;--------------------------------------/



;---------------------------------------
;--- De 4 regels tekst van het InfoScreen afbeelden
;--------------------------------------\
LCD_InfoScreen:
	push	R17
	push	R18
	rcall	LCD_Clear
	rcall	LCD_Home
	ldi		R17, 0						; X
	ldi		R18, 0						; Y
	rcall	LCD_SetCursorXY
	ldi		ZL, low(2*InfoText0)
	ldi		ZH, high(2*InfoText0)
	rcall	LCD_Print_From_Flash_
	ldi		R17, 0
	ldi		R18, 1
	rcall	LCD_SetCursorXY
	ldi		ZL, low(2*InfoText1)
	ldi		ZH, high(2*InfoText1)
	rcall	LCD_Print_From_Flash_
	ldi		R17, 0
	ldi		R18, 2
	rcall	LCD_SetCursorXY
	ldi		ZL, low(2*InfoText2)
	ldi		ZH, high(2*InfoText2)
	rcall	LCD_Print_From_Flash_
	ldi		R17, 0
	ldi		R18, 3
	rcall	LCD_SetCursorXY
	ldi		ZL, low(2*InfoText3)
	ldi		ZH, high(2*InfoText3)
	rcall	LCD_Print_From_Flash_
	pop		R18
	pop		R17
	ret
;--------------------------------------/



;---------------------------------------
;--- Een string afbeelden op LCD-display
;---	input:	register Z (R31:R30)= string-adres*2
;--------------------------------------\
LCD_Print_From_Flash:
	;methode 2: lees uit FLASH/PROGRAM-memory
	lsl		ZL							; Z*2
	rol		ZH
LCD_Print_From_Flash_:
	push	R16
LCD_Print_loop:
	lpm									; Register R0 <- Program Memory [Z]  (R0 = CharReg)
	adiw	ZL, 1						; Adres in Z-Register verhogen
	mov		R16, R0
	cpi		R16, EOS_Symbol
	breq	EOS
	rcall	LCD_WriteData
	rjmp	LCD_Print_loop
EOS:
	pop		R16
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

	lsl		R16							; LCD-RAM adres * 8
	lsl		R16
	lsl		R16
	rcall	LCD_SetCharGenAddr
	; nu de 8 bytes van het patroon overzenden
	lsl		ZL							; Eerst het adres x2 tbv. de LPM-instructie....
	rol		ZH
	ldi		R17, 8						; 8 bytes overbrengen naar LCD-RAM
NextChar:
	lpm									; R0 (=CharReg) krijgt de waarde van de byte op adres [Z]
	adiw	ZL,1						; Z-register verhogen
	mov		R16, R0						; R0 bevat het resultaat van de LPM instructie
	rcall	LCD_WriteData
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
;--- LCD GetCursorXY
;--- De cursorpositie lezen
;---	output:	R17 = column [0..19]
;---			R18 = row [0..3]
;--------------------------------------\
LCD_GetCursorXY:
	push	R16
	rcall	LCD_GetDisplayAddr			; huidige adres opvragen in DD/CG-RAM
	rcall	LCD_Addr2XY					; LCD RAM-adres omzetten naar (X,Y) LCD schermcoordinaten
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
	;cpi		R18, 3
	;brne	_XY
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
;--- Het hele scherm vullen met het teken in R16
;---	input:	R16 = ASCII-teken
;--- !! auto-increment moet zijn aangeschakeld.
;--------------------------------------\
LCD_Fill:
	push	R16
	push	R17
	push	R18

	ldi		R17, 0						; 1e kolom
	ldi		R18, 0						; 1e rij
	rcall	LCD_SetCursorXY
NextFill0:
	rcall	LCD_WriteData				; ....afbeelden op cursor-positie
	inc		R17							; volgende kolom
	cpi		R17, 40;20					; de regel loopt over in de 3e regel, 1e positie
	brne	NextFill0
	;
	ldi		R17, 0						; 1e kolom
	ldi		R18, 1						; 2e rij
	rcall	LCD_SetCursorXY
NextFill1:
	rcall	LCD_WriteData				; ....afbeelden op cursor-positie
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
;--- Een regel leegmaken vanaf de 
;--- opgegeven kolom tot aan het einde 
;--- van de regel.
;---	input:	R17 = column [0..19]
;---			R18 = row [0..3]
;--------------------------------------\
LCD_ClearLineFromXY:
	push	R16
	push	R17							; huidige LCD-cursor X positie
	push	R18							; huidige LCD-cursor Y positie
	rcall	LCD_SetCursorXY				; cursor plaatsen
NextPos:
	ldi		R16, ' '					; een spatie....
	rcall	LCD_WriteData				; ....afbeelden op cursor-positie
	inc		R17							; volgende kolom
	cpi		R17, 20
	brlo	NextPos
	; cursor positie herstellen
	pop		R18
	pop		R17
	rcall	LCD_SetCursorXY
	pop		R16
	ret
;--------------------------------------/



;---------------------------------------
;--- De nieuwe regel wissen naar gelang
;--- de instelling van de optie "Flag_ClearNewLine" in "LCD_Flags".
;--- input: R17 = column [0..19]	(== 0)
;---        R18 = row [0..3]
;--------------------------------------\
LCD_ClearNewLine:
	push	R16
	push	R17
	push	R18
	; ClearNewLine optie aan?
	mov		R16, LCD_Flags
	andi	R16, (1<<Flag_ClearNewLine)
	breq	Done_LCD_ClearNewLine
	; Leeg de nieuwe regel..
	rcall	LCD_ClearLineFromXY
Done_LCD_ClearNewLine:
	pop		R18
	pop		R17
	pop		R16
	ret
;--------------------------------------/



;---------------------------------------
;--- Scrollen of overlopen naar de 1e regel?
;--- input: R16 = het teken dat de scroll veroorzaakt
;---              (dat teken is al afgebeeld op het LCD)
;--------------------------------------\
LCD_Scroll_Or_Overflow:
	push	R16
	push	R17
	push	R18
	; Scrolling aan?
	mov		R17, LCD_Flags
	andi	R17, (1<<Flag_Scrolling)
	breq	GoToRow1
	; Scrollen..
	rcall	LCD_ScrollUp				; De scherminhoud omhoog scrollen
	rjmp	Done_Scroll_Or_Overflow			;
	; Overlopen naar 1e regel
GoToRow1:
	clr		R17							; overlopen naar kolom 1..
	clr		R18							; ..van de 1e regel
	rcall	LCD_SetCursorXY
	rcall	LCD_ClearNewLine
Done_Scroll_Or_Overflow:
	pop		R18
	pop		R17
	pop		R16
	ret
;--------------------------------------/




;---------------------------------------
;--- Woorden heel laten en niet halverwege knippen en plakken op 2 regels..
;--- input: register LCD_LastChar = het vorig afgebeelde teken
;---        R16 = het teken dat op een WordWrap getest moet worden.
;---              (dat teken is nog niet afgebeeld op het LCD)
;---        R17 = column [0..19]	(== 0)
;---        R18 = row [0..3]
;--------------------------------------\
LCD_WordWrap:
	push	R16
	push	R17
	push	R18
	push	R20
	push	R21
	push	R7
	push	R8
	push	R9
	mov		R9, R16						; !!!!

	; WordWrap aan?
	mov		R21, LCD_Flags
	andi	R21, (1<<Flag_WordWrap)
	brne	WordWrap_Aan
	rjmp	Done_WordWrap				; nee: dan al klaar..
WordWrap_Aan:
	; cursor op eerste positie(0) van een regel?
	cpi		R17, 0						; helemaal links?
	brne	Done_WordWrap				; nee: dan al klaar..
	; Geen wordwrap VOOR een spatie, koppel-teken, punt en comma
	cpi		R16, ' '					;
	breq	Done_WordWrap				;
	cpi		R16, '-'					;
	breq	Done_WordWrap				;
	cpi		R16, ','					;
	breq	Done_WordWrap				;
	cpi		R16, '.'					;
	breq	Done_WordWrap				;
	; Geen wordwrap NA een spatie, koppel-teken, punt en comma
	mov		R16, LCD_LastChar			; vorige teken ophalen (dat staat dus op kolom(19)..)
	cpi		R16, ' '					; indien vorige teken == spatie..
	breq	Done_WordWrap				; ..geen wrapping want een ander (nieuw) woord begint
	cpi		R16, '-'					; indien vorige teken == koppel-teken..
	breq	Done_WordWrap				; ..idem
	cpi		R16, ','					;
	breq	Done_WordWrap				;
	cpi		R16, '.'					;
	breq	Done_WordWrap				;
	; Er moet een WordWrap worden uitgevoerd!..
	;(de cursor staat nu op kolom(0) van de nieuwe regel. Het teken(R9) is nog niet afgebeeld)
	; Dwz. de tekens op regel(R18-1), vanaf kolom(18) en lager /verder naar links/ ..
	; ..moeten vervangen worden door spaties, en gekopieerd naar regel(R18):kolom(R17)==0

	;----------------------------------\
	push	R17;!!!
	push	R18;!!
	; Lees de tekens op regel(R18-1) vanaf kolom(19) en lager..
	; ..en scan naar een spatie als sein voor het begin/einde van het woord.
	ldi		R17, 19						; kolom 19 (bevat een teken, anders dan spatie of koppelteken)
	dec		R18							; regel - 1
WordEnd:
	dec		R17							; kolom 18 initieel, en lager (lus)
	rcall	LCD_SetCursorXY				; de cursor-positie instellen
	rcall	LCD_ReadData				; lees het teken uit DDRAM
	cpi		R16, ' '					; spatie?..
	breq	EndOfWord
	cpi		R16, '-'					; koppel-teken?..
	breq	EndOfWord
	cpi		R16, '.'					; punt?..
	breq	EndOfWord
	cpi		R16, ','					; comma?..
	breq	EndOfWord
	cpi		R17, 0						; zijn we vooraan de regel?
	brne	WordEnd						; ..volgende teken (vorige op scherm) testen..
	ldi		R20, 0						; geen wrapping uitvoeren, de regel staat vol met 1 woord.
	rjmp	NotWrapped
EndOfWord:
	; (De kolom(R17+1) is nu de begin-positie van het woord op scherm)
	; (De lengte van het woord op scherm (19-R17) in R16 (tenminste 1 altijd))
	;-- Kopieer een woord naar nieuwe regel:kolom(0)...
	ldi		R16, 19
	sub		R16, R17
	mov		R20, R16					; R20 := lengte van het woord op schem
	inc		R17							; kolom(R17) = begin woord op scherm
	rcall	LCD_XY2Addr					; R18:R17 adresvorm naar LCD adres in R16
	;--- R17:R18 tijdelijk bewaren
	mov		R8, R18						; !!!
	mov		R7, R17						; !!!
	;---
	mov		R21, R16					; R21 := src address
	inc		R18							; volgende regel..
	clr		R17							; vooraan, 1e teken..
	rcall	LCD_XY2Addr					; R18:R17 adresvorm naar LCD adres in R16
	mov		R18, R16					; R18 := dst address
	mov		R16, R20					; R16 := aantal
	mov		R17, R21					; R17 := src address
	rcall	LCD_CopyLine
Done_Word:
	;--- R17:R18 ophalen
	mov		R18, R8						; !!! regel: begin woord
	mov		R17, R7						; !!! kolom: begin woord
	;---
	mov		R16, R20					; aantal
	;-- Wis regel(R18) vanaf kolom(R17)
	rcall	LCD_ClearLineFromXY			; wis het ge-wrapte woord..
NotWrapped:
	pop		R18;!!						; huidige regel
	pop		R17;!!!						; begin van de regel, kolom(0)
	;----------------------------------/
	add		R17, R20					; aantal gekopieerd/lengte WordWrapped woord..
	rcall	LCD_SetCursorXY				; de cursor-positie herstellen
	; het huidige teken afbeelden
	mov		R16, R9						; !!!!
	rcall	LCD_WriteData				; ASCII-waarde schrijven naar LCD

	; De zero-flag wissen.. 
	clz
Done_WordWrap:
	; De zeroflag is gezet als er geen WordWrap nodig is (uitgeschakeld).
	; De zero-flag is gewist als er een WordWrap is uitgevoerd EN 
	;  de LinePrint routine niet verder moet worden uitgevoerd.
	;  (WordWrap routine heeft alles al afgehandeld dan)
	pop		R9
	pop		R8
	pop		R7
	pop		R21
	pop		R20
	pop		R18
	pop		R17
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- Een (evt.) actuele wordwrap tegengaan.
;--------------------------------------\
CancelWordWrap:
	push	R16
	ldi		R16, ' '					; een teken, ongevoelig voor wordwraps, als
	mov		LCD_LastChar, R16			; laatste teken gebruiken, waardoor de wordwrap
	pop		R16							; als het ware wordt tegengegaan.
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
	; cursor op begin van 4e regel plaatsen
	ldi		R17, 0
	ldi		R18, 3
	rcall	LCD_SetCursorXY
	; 4e regel legen
	ldi		R17, 0
	ldi		R18, 3
	rcall	LCD_ClearLineFromXY
	;
	pop		R18
	pop		R17
	pop		R16
	ret
;--------------------------------------/





.if CopyViaSRAM == 0
	;de 2e versie
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

		cp		R17, R18					; src==dst ?
		breq	Done_CopyLine

		mov		XL, R17						; XL bevat het src-adres van de 1e te copiëren byte
		mov		XH, R18						; XH bevat het dest-adres van de 1e te copiëren byte
		mov		YL, R16						; aantal tekens te copiëren overnemen naar YL

		; huidige cursor-positie opvragen en bewaren
		rcall	LCD_GetDisplayAddr
		push	R16
	CopyLoop:
		; plaats cursor op source plaasten (XL)
		mov		R16, XL
		rcall	LCD_SetDisplayAddr
		; teken lezen op cursor-positie
		rcall	LCD_ReadData
		mov		R17, R16
		; plaats cursor op dest. plaasten (XH)
		mov		R16, XH
		rcall	LCD_SetDisplayAddr
		; gelezen teken schrijven
		mov		R16, R17
		rcall	LCD_WriteData
		; teller op volgende teken plaatsen
		inc		XL							; src++
		inc		XH							; dest++
		dec		YL							; n--
		brne	CopyLoop
		; cursor-positie herstellen
		pop		R16
		rcall	LCD_SetDisplayAddr

	Done_CopyLine:
		pop		YL
		pop		XH
		pop		XL
		ret
	;--------------------------------------/
.elif CopyViaSRAM == 1
	; De laatste versie die SRAM gebruikt.
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
		push	YH
		push	ZL
		push	ZH

		cp		R17, R18
		breq	Done_CopyLine

		mov		XL, R17						; XL bevat het src-adres van de 1e te copiëren byte
		mov		XH, R18						; XH bevat het dest-adres van de 1e te copiëren byte
		mov		YL, R16						; aantal tekens te copiëren overnemen naar YL
		mov		YH, YL

		; huidige cursor-positie opvragen en bewaren
;		rcall	LCD_GetDisplayAddr
		push	R16
		; plaats cursor op source plaasten (XL)
		mov		R16, XL
		rcall	LCD_SetDisplayAddr
		; het Z-register naar de buffer laten wijzen
		ldi		ZL, low(LCD_Data_Buffer)	
		ldi		ZH, high(LCD_Data_Buffer)	
		; lees 'YL' tekens van LCD en plaats deze in SRAM.
	CopyLoop:
		rcall	LCD_ReadData				; teken lezen op cursor-positie
		st		Z+, R16						; schrijven in SRAM en pointer verplaatsen
		; teller verlagen
		dec		YL							; n--
		brne	CopyLoop
		;--- nu de buffer plakken naar dest.
		; plaats cursor op dest. plaasten (XH)
		mov		R16, XH
		rcall	LCD_SetDisplayAddr
		; het Z-register naar de buffer laten wijzen
		ldi		ZL, low(LCD_Data_Buffer)	
		ldi		ZH, high(LCD_Data_Buffer)	
		; 'YL' tekens uit SRAM lezen en schrijven naar LCD.
	PasteLoop:
		ld		R16, Z+						; lezen uit SRAM en pointer verplaatsen
		rcall	LCD_WriteData				; teken plakken
		; teller verlagen
		dec		YH							; n--
		brne	PasteLoop
		; cursor-positie herstellen
		pop		R16
;		rcall	LCD_SetDisplayAddr

	Done_CopyLine:
		pop		ZH
		pop		ZL
		pop		YH
		pop		YL
		pop		XH
		pop		XL
		ret
	;--------------------------------------/
.endif



;---------------------------------------
;--- Een string afbeelden op LCD-display
;--- De cursor wordt verplaatst naar de volgende logische
;--- positie op het scherm. (regel 1,2,3,4 ipv. regel 1,3,2,4)
;---	input:	R16 = ASCII-waarde van het af te beelden teken
;--------------------------------------\
LCD_LinePrintChar:
	push	R20
	push	R19;
	push 	R18;!-
	push	R17;!!--					; nieuwe cursor-positie

	mov		R20, R16					; te printen data bewaren..
	clr		R19							; vlag wissen (cursor niet verplaatsen)
	rcall	LCD_GetCursorXY
	;--- R17 = column [0..19]
	;--- R18 = row [0..3]
	; Test op een wordwrap nodig?
	cpi		R17, 0						; cursor op eerste positie(0) van een regel?
	brne	TestLastCol
	rcall	LCD_WordWrap
	; Na afloop van de WordWrap-routine geeft de zero-flag aan 
	; of de rest van de LinePrint-routine moet worden afgemaakt (zeroflag=1).
	; Als zeroflag=0 dan heeft de WordWrap al alles gedaan wat nodig was..
	breq	printChar
	rjmp	Exit_LinePrintChar			; klaar als zeroflag=0
TestLastCol:
	cpi		R17, 19						; cursor op laatste positie(19) van een regel?
	brne	printChar
	ser		R19							; vlag zetten als cursor met de hand verplaatst moet worden
printChar:
	mov		R16, R20					; te printen data ophalen..
	rcall	LCD_WriteData				; ASCII-waarde schrijven naar LCD

	tst		R19							; kolom19-vlag gezet?
	breq	Exit_LinePrintChar			; nee: alles is 0,  klaar..
	; De cursor stond op de laatste kolom(19)..
	; inmiddels is de cursor overgelopen naar de nieuwe (onlogische) beeldregel.
	; De cursorpositie nu herstellen naar de gewenste regel.
	clr		R17							; 1e positie nieuwe regel
	inc		R18							; volgende regel
	cpi		R18, 4						; cursor buiten beeld?
	brne	SetNewLine					; nee: dan verder
	rcall	LCD_Scroll_Or_Overflow		; anders: actie correct afhandelen...
	rjmp	PrepareWordWrap
SetNewLine:
	rcall	LCD_SetCursorXY				; de cursor-positie instellen
	rcall	LCD_ClearNewLine			; Eventueel de "nieuwe" regel legen vanaf regel(R18):kolom(R17)..
PrepareWordWrap:
	; het laatste teken onthouden dat een scroll veroorzaakt,
	; of een wordwrap kan veroorzaken.
	; Dit teken wordt verwerkt bij de volgende aanroep van LCD_WordWrap
	mov		LCD_LastChar, R16			

Exit_LinePrintChar:
	pop		R17;!!--
	pop		R18;!-
	pop		R19
	pop		R20
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
	rcall	LCD_ReadData
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
	; scrollen of overlopen
	rcall	LCD_Scroll_Or_Overflow
	rjmp	Done_NextLine
SetNextLine:
	; teken op 1e kolom
	clr		R17
	rcall	LCD_SetCursorXY
	rcall	LCD_ClearNewLine			; Eventueel de "nieuwe" regel legen vanaf regel(R18):kolom(R17)..
Done_NextLine:
	;--- Na een ENTER (waardoor de wordwrap "in de war" raakt),
	;--- een evt. actuele wordwrap tegengaan.
	rcall	CancelWordWrap
	;---
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
	rcall	LCD_WriteData
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
	; huidige cursorpositie staat nu in R17,R18. Converteren naar een LCD DDRAM-adres in R16
	rcall	LCD_XY2Addr
	push	R16				;!!! dest. bewaren op de stack
	inc		R17							; cursorpositie+1 in temp2,temp3
	rcall	LCD_XY2Addr					; Converteren naar een LCD DDRAM-adres in temp
	mov		R17, R16					; src.
	pop		R18				;!!! dest. ophalen van de stack
	mov		R16, R19					; aantal te copieren tekens
	rcall	LCD_CopyLine

Done_Delete:
	; Huidige regel vanaf rechts aanvullen met spaties
	ldi		R17, 19
	mov		R18, R3
	rcall	LCD_SetCursorXY
	ldi		R16, ' '
	rcall	LCD_WriteData
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
	push	R16				;!!! src. bewaren op de stack
	inc		R17							; cursorpositie+1 in temp2,temp3
	rcall	LCD_XY2Addr					; Converteren naar een LCD DDRAM-adres in temp
	mov		R18, R16					; dest.
	pop		R17				;!!! src. ophalen van de stack
	mov		R16, R19					; aantal te copieren tekens
	rcall	LCD_CopyLine

Done_Insert:
	; Huidige cursorpositie vullen met het af te beelden teken
	mov		R17, R2
	mov		R18, R3
	rcall	LCD_SetCursorXY
	mov		R16, R4

	rcall	LCD_LinePrintChar			; houd rekening met per SW instelbare opties (scroll,wordwrap etc)
;	rcall	LCD_WriteData
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
	dec		R18							; 1 naar boven
	rjmp	MoveCursor
ArrowDn:
	cpi		R16,1
	brne	ArrowR
	cpi		R18, 3
	breq	Done_Arrow
	inc		R18							; 1 naar onder
	rjmp	MoveCursor
ArrowR:
	cpi		R16,2
	brne	ArrowL
	cpi		R17, 19
	breq	Done_Arrow
	inc		R17							; 1 naar rechts
	rjmp	MoveCursor
ArrowL:
	cpi		R16,3
	brne	Done_Arrow
	cpi		R17, 0
	breq	Done_Arrow
	dec		R17							; 1 naar links
MoveCursor:
	rcall	LCD_SetCursorXY
Done_Arrow:
	;--- Na een pijltje (waardoor de wordwrap "in de war" raakt),
	;--- het laatste teken ongeldig maken zodat er geen wordwrap
	;--- wordt toegepast.
	rcall	CancelWordWrap
	;---
	pop		R18
	pop		R17
	ret
;--------------------------------------/





;---------------------------------------
;--- Vertragingen
;--- (gebruikt unit "AVR_Delay.asm")
;--------------------------------------\
LCD_Delay2us:							; vertraging 2 micro-seconden
	Delay_US 2
	ret

LCD_Delay40us:							; vertraging 40 micro-seconden
	Delay_US 40
	ret

LCD_Delay100us:							; vertraging 100 micro-seconden
	Delay_US 100
	ret

LCD_Delay120us:							; vertraging 120 micro-seconden
	Delay_US 120
	ret

LCD_Delay2ms:							; vertraging 2 milli-seconden
	Delay_MS 2
	ret

LCD_Delay4_1ms:							; vertraging 4.1 milli-seconden
	Delay_MS 4
	Delay_US 100
	ret

LCD_Delay15ms:							; vertraging 15 milli-seconden
	Delay_MS 15
	ret

LCD_Delay100ms:							; vertraging 100 milli-seconden
	Delay_MS 100
	ret

LCD_Delay150ms:							; vertraging 150 milli-seconden
	Delay_MS 150
	ret

LCD_Delay1_5s:							; vertraging 1.5 seconde
	Delay_S 1
	Delay_MS 500
	ret
;--------------------------------------/

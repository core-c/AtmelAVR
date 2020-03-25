;---------------------------------------
;--- Compiler Directives
;--------------------------------------\
;.equ DEBUGPRINT = 0					; undef DEBUGPRINT
.equ DEBUGPRINT = 1						; def DEBUGPRINT
;--------------------------------------/



;-----------------------------------------------
;--- EEPROM.
;--- I2C Slave LCD User Commands
;----------------------------------------------\
.equ EOT = $FF									; End Of Table symbool
.ESEG                             				; het EEPROM-segment aanspreken
; Command-code		Aantal Data-bytes
LCD_CommandCodes:
	.db $00, 		1							; LCD character lineprint
	.db $01,		0							; LCD-cursor naar volgende regel (CrLf)
	.db $02,		0							; LCD-cursor Home
	.db $03,		0							; LCD-cursor naar EndOfLine
	.db $04,		1							; LCD print hex.nibble
	.db $05,		1							; LCD print hex.byte
	.db $06,		2							; LCD print hex.word
	.db $07,		0							; LCD Scroll-Up
	.db $08,		0							; LCD Backspace
	.db $09,		0							; LCD Delete
	.db $0A,		1							; LCD Insert character
	.db $0B,		0							; LCD pijl omhoog
	.db $0C,		0							; LCD pijl omlaag
	.db $0D,		0							; LCD pijl naar links
	.db $0E,		0							; LCD pijl naar rechts
	.db $0F,		1							; LCD Fill
	.db $10,		2							; LCD Clear Line from (X,Y)
	.db $11,		0							; LCD SplashScreen
	.db $12,		2							; LCD Set Cursor (X,Y)
	.db EOT,		EOT							; End of Table marker
;----------------------------------------------/
.CSEG


;---------------------------------------
;--- Een byte lezen van EEPROM
;---  input:	register Z bevat het EEPROM-adres
;---  output:	R16 bevat de gelezen byte
;--------------------------------------\
ReadEEPROM:
	;Write-Enable bit moet eerst 0 zijn.
WE0:sbic	EECR, EEWE
	rjmp	WE0
	;Het adres instellen in het EEPROM Address Register.
	;512 Bytes = > 9 bits adres (b8-0).
	out		EEARL, ZL
	out		EEARH, ZH
	;Read-Enable signaal geven
	sbi		EECR, EERE
	;byte inlezen via het EEPROM Data-Register
	in		R16, EEDR
	ret
;--------------------------------------/


;---------------------------------------
;--- Resulteer de benodigde aantal bytes
;--- van een UserCommand in de buffer.
;---  input:	R17 = UserCommand-Code
;---  output:	R16 = Aantal Data-Bytes + 1 (de command-code zelf),
;---			      0 indien de UserCommand-Code ongeldig is.
;--------------------------------------\
UserCommand_Length:
	push	ZL
	push	ZH

	ldi		ZL, LOW(LCD_CommandCodes)
	ldi		ZH, HIGH(LCD_CommandCodes)
Loop_CommandCodeTable:
	rcall	ReadEEPROM					; Table Command-Code nu in R16
	cpi		R16, EOT					; laatste tabel-element?
	breq	CommandCode_NotFound
	cp		R16, R17
	breq	CommandCode_Found
	adiw	ZL, 2						; Z naar volgende Command-Code in de tabel laten wijzen
	rjmp	Loop_CommandCodeTable

CommandCode_NotFound:
	ldi		R16, 0						; ongeldige UserCommand-Code
	rjmp	Done_UserCommandLength

CommandCode_Found:
	; bepaal hoeveel Data-Bytes deze Command-Code heeft
	adiw	ZL,1						; Z naar het bijbehorende Data-Bytes element laten wijzen
	rcall	ReadEEPROM					; Table aantal Data-Bytes nu in R16
	inc		R16							; de UserCommand-Code zelf is 1 byte in de buffer

Done_UserCommandLength:
	pop		ZH
	pop		ZL
	ret
;--------------------------------------/




;---------------------------------------
;--- Compleet UserCommand in TWI_IN_Buffer?
;---  output:	zero-flag 0 = nee,	R16 = ongedefinieerd
;---			zero-flag 1 = ja,	R16 = UserCommand_Length()
;--------------------------------------\
UserCommand_IsReady:
	push	R17
	; Peek de als eerste te lezen byte uit de buffer
	; om de command-code te bepalen.
	; De carry-flag wordt gezet indien de buffer leeg is.
	PeekByteSRAMFromBuffer R17, TWI_IN_Buffer_Output, TWI_IN_BytesInBuffer
	brcs	UserCommandCode_NotReady
	; R17 bevat nu de LCD command-code...

	rcall	UserCommand_Length
	; R16 bevat nu de lengte van het UserCommand in de buffer
	; Als dit == 0 dan betreft het een ongeldige UserCommand-Code.
	; In dat geval de byte uit de buffer lezen...
	cpi		R16, 0
	brne	DoesItFit
	; een ongeldige command-code, verwijder/lees de byte uit de buffer
	rcall	LoadByteSRAMFrom_TWI_IN_Buffer
	.ifdef DEBUGPRINT
		rcall	LCD_HexByte				; waarde van R16 als hexadecimaal getal afbeelden op LCD
	.endif
	rjmp	UserCommandCode_NotReady

DoesItFit:
	; zijn er R16 bytes in de TWI_IN_Buffer?
	lds		R17, TWI_IN_BytesInBuffer
	cp		R17, R16
	brlo	UserCommandCode_NotReady
	sez									; succes, zero-flag zetten
	rjmp	Done_UserCommandIsReady

UserCommandCode_NotReady:
	clz									; geen succes, zero-flag wissen

Done_UserCommandIsReady:
	pop		R17
	ret
;--------------------------------------/



;---------------------------------------
;--- Een UserCommand uit TWI_IN_Buffer
;--- lezen, en uitvoeren naar/op LCD.
;--------------------------------------\
UserCommand_Process:
	push	R16
	rcall	UserCommand_IsReady			; Een compleet UserCommand in de buffer?
	breq	Load_UserCommand
	rjmp	Done_DoUserCommand

Load_UserCommand:
	; R16 bevat nu de lengte van het UserCommand in de buffer...
	; Dat is de command-code (byte) + de evt. data-bytes
	; Lees de UserCommand-Code uit de TWI_IN_Buffer (1 byte)
	rcall	LoadByteSRAMFrom_TWI_IN_Buffer
	brcc	Compare_UserCommand			; buffer lezen was mislukt als de carry-flag gezet is
	rjmp	Done_DoUserCommand

Compare_UserCommand:
	; register R16 bevat de uit de invoer-buffer gelezen byte
UCC_00: ;-------------------------------
	cpi		R16, $00					; LCD character lineprint
	brne	UCC_01
	; Lees	1 byte data (het te lineprinten teken) in R16
	rcall	LoadByteSRAMFrom_TWI_IN_Buffer
	brcs	UCC_00_Done					; buffer lezen was mislukt als de carry-flag gezet is
	; waarde van R16 schrijven naar LCD
	rcall	LCD_LinePrintChar
UCC_00_Done:
	rjmp	Done_DoUserCommand

UCC_01: ;-------------------------------
	cpi		R16, $01					; LCD-cursor naar volgende regel (CrLf)
	brne	UCC_02
	;,		0
	rcall	LCD_NextLine
	rjmp	Done_DoUserCommand

UCC_02: ;-------------------------------
	cpi		R16, $02					; LCD-cursor Home
	brne	UCC_03
	;,		0
	rcall	LCD_LineHome
	rjmp	Done_DoUserCommand

UCC_03: ;-------------------------------
	cpi		R16, $03					; LCD-cursor naar EndOfLine
	brne	UCC_04
	;,		0
	rcall	LCD_LineEnd
	rjmp	Done_DoUserCommand

UCC_04: ;-------------------------------
	cpi		R16, $04					; LCD print hex.nibble
	brne	UCC_05
	; Lees	1 byte data (waarvan alleen bits 3-0 geldig) in R16
	rcall	LoadByteSRAMFrom_TWI_IN_Buffer
	brcs	UCC_04_Done					; buffer lezen was mislukt als de carry-flag gezet is
	andi	R16, 0b00001111			; de LS nibble wordt afgebeeld
	rcall	LCD_HexNibble
UCC_04_Done:
	rjmp	Done_DoUserCommand

UCC_05: ;-------------------------------
	cpi		R16, $05					; LCD print hex.byte
	brne	UCC_06
	; Lees	1 byte data (de byte) in R16
	rcall	LoadByteSRAMFrom_TWI_IN_Buffer
	brcs	UCC_05_Done					; buffer lezen was mislukt als de carry-flag gezet is
	rcall	LCD_HexByte
UCC_05_Done:
	rjmp	Done_DoUserCommand

UCC_06: ;-------------------------------
	cpi		R16, $06					; LCD print hex.word
	brne	UCC_07
	; Lees	2 bytes data (Low,High order) in het Z-register
	push	ZH
	push	ZL
	rcall	LoadByteSRAMFrom_TWI_IN_Buffer
	brcs	UCC_06_Done					; buffer lezen was mislukt als de carry-flag gezet is
	mov		ZL, R16
	rcall	LoadByteSRAMFrom_TWI_IN_Buffer
	brcs	UCC_06_Done					; buffer lezen was mislukt als de carry-flag gezet is
	mov		ZH, R16
	rcall	LCD_HexWord
UCC_06_Done:
	pop		ZL
	pop		ZH
	rjmp	Done_DoUserCommand

UCC_07: ;-------------------------------
	cpi		R16, $07					; LCD Scroll-Up
	brne	UCC_08
	;,		0
	rcall	LCD_ScrollUp	
	rjmp	Done_DoUserCommand

UCC_08: ;-------------------------------
	cpi		R16, $08					; LCD Backspace
	brne	UCC_09
	;,		0
	rcall	LCD_BackSpace
	rjmp	Done_DoUserCommand

UCC_09: ;-------------------------------
	cpi		R16, $09					; LCD Delete
	brne	UCC_0A
	;,		0
	rcall	LCD_Delete
	rjmp	Done_DoUserCommand

UCC_0A: ;-------------------------------
	cpi		R16, $0A					; LCD Insert character
	brne	UCC_0B
	; Lees	1 byte data (in te voegen teken)
	rcall	LoadByteSRAMFrom_TWI_IN_Buffer
	brcs	UCC_0A_Done					; buffer lezen was mislukt als de carry-flag gezet is
	rcall	LCD_Insert					; waarde van R16 inserten op LCD
UCC_0A_Done:
	rjmp	Done_DoUserCommand

UCC_0B: ;-------------------------------
	cpi		R16, $0B					; LCD pijl omhoog
	brne	UCC_0C
	;,		0
	ldi		R16, 0
	rcall	LCD_Arrow
	rjmp	Done_DoUserCommand

UCC_0C: ;-------------------------------
	cpi		R16, $0C					; LCD pijl omlaag
	brne	UCC_0D
	;,		0
	ldi		R16, 1
	rcall	LCD_Arrow
	rjmp	Done_DoUserCommand

UCC_0D: ;-------------------------------
	cpi		R16, $0D					; LCD pijl naar links
	brne	UCC_0E
	;,		0
	ldi		R16, 3
	rcall	LCD_Arrow
	rjmp	Done_DoUserCommand

UCC_0E: ;-------------------------------
	cpi		R16, $0E					; LCD pijl naar rechts
	brne	UCC_0F
	;,		0
	ldi		R16, 2
	rcall	LCD_Arrow
	rjmp	Done_DoUserCommand

UCC_0F: ;-------------------------------
	cpi		R16, $0F					; LCD Fill
	brne	UCC_10
	; Lees	1 byte data ("opvul"-teken) in R16
	rcall	LoadByteSRAMFrom_TWI_IN_Buffer
	brcs	UCC_0F_Done					; buffer lezen was mislukt als de carry-flag gezet is
	rcall	LCD_Fill					; LCD vullen met waarde in R16
UCC_0F_Done:
	rjmp	Done_DoUserCommand

UCC_10: ;-------------------------------
	cpi		R16, $10					; LCD Clear Line from (X,Y)
	brne	UCC_11
	; Lees	2 bytes data (X,Y) in R17, R18
	push	R17
	push	R18
	rcall	LoadByteSRAMFrom_TWI_IN_Buffer
	brcs	UCC_10_Done					; buffer lezen was mislukt als de carry-flag gezet is
	mov		R17, R16					; X
	rcall	LoadByteSRAMFrom_TWI_IN_Buffer
	brcs	UCC_10_Done					; buffer lezen was mislukt als de carry-flag gezet is
	mov		R18, R16					; Y
	rcall	LCD_ClearLineFromXY
UCC_10_Done:
	pop		R18
	pop		R17
	rjmp	Done_DoUserCommand

UCC_11: ;-------------------------------
	cpi		R16, $11					; LCD SplashScreen
	brne	UCC_12
	;,		0
	rcall	LCD_SplashScreen
	rjmp	Done_DoUserCommand

UCC_12: ;-------------------------------
	cpi		R16, $12					; LCD Set Cursor (X,Y)
	brne	Done_DoUserCommand
	; Lees	2 bytes data (X,Y) in R17, R18
	push	R17
	push	R18
	rcall	LoadByteSRAMFrom_TWI_IN_Buffer
	brcs	UCC_12_Done					; buffer lezen was mislukt als de carry-flag gezet is
	mov		R17, R16					; X
	rcall	LoadByteSRAMFrom_TWI_IN_Buffer
	brcs	UCC_12_Done					; buffer lezen was mislukt als de carry-flag gezet is
	mov		R18, R16					; Y
	rcall	LCD_SetCursorXY
UCC_12_Done:
	pop		R18
	pop		R17
	;rjmp	Done_DoUserCommand

Done_DoUserCommand: ;-------------------
	pop		R16
	ret
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








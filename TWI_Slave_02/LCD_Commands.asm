;---------------------------------------
;--- LCD Commando's ($00-$1F)
;--- aantal data bytes tabel
;----------------------\
.ESEG
LCD_CMD_00: .db $00		; NULL
LCD_CMD_01: .db $01		; Turn On									1 data byte		(vlag)
LCD_CMD_02: .db $01		; Turn Off									1 data byte		(vlag)
LCD_CMD_03: .db $00		; Cursor Home
LCD_CMD_04: .db $00		; Cursor LineHome
LCD_CMD_05: .db $00		; Cursor LineEnd
LCD_CMD_06: .db $02		; Print Hex									2 data bytes	(1 word)
LCD_CMD_07: .db $02		; Print Dec									2 data bytes	(1 word)
LCD_CMD_08: .db $00		; BackSpace
LCD_CMD_09: .db $01		; Control Bootscreen						1 data byte
LCD_CMD_0A: .db $00		; LineFeed
LCD_CMD_0B: .db $00		; Delete
LCD_CMD_0C: .db $00		; Form Feed (Clear Display)
LCD_CMD_0D: .db $00		; Carriage Return
LCD_CMD_0E: .db $01		; Backlight Control							1 data byte
LCD_CMD_0F: .db $01		; Contrast Control							1 data byte
LCD_CMD_10: .db $01		; Fill										1 data byte
LCD_CMD_11: .db $00		; Set Cursor Position						2 data  bytes	(X,Y)
LCD_CMD_12: .db $01		; Insert									1 data byte
LCD_CMD_13: .db $00		; 																					(niet gebruikt)
LCD_CMD_14: .db $00		; 																					(niet gebruikt)
LCD_CMD_15: .db $00		; 																					(niet gebruikt)
LCD_CMD_16: .db $00		; 																					(niet gebruikt)
LCD_CMD_17: .db $00		; 																					(niet gebruikt)
LCD_CMD_18: .db $00		; 																					(niet gebruikt)
LCD_CMD_19: .db $09		; Upload Custom Character Bitmap			9 data bytes	(ASCII, bitpatroon)
LCD_CMD_1A: .db $00		; Reboot
LCD_CMD_1B: .db $02		; Escape Sequence Prefix					2 data bytes	(#91,pijl)
LCD_CMD_1C: .db $00		; 																					(niet gebruikt)
LCD_CMD_1D: .db $00		; 																					(niet gebruikt)
LCD_CMD_1E: .db $02		; Send Data Directly To LCD-Controller		2 data bytes
LCD_CMD_1F: .db $00		; Show Information Screen
;-----------------------
;LCD_CMD_80: .db $00	; Print Custom Character 0
;LCD_CMD_81: .db $00	; Print Custom Character 1
;LCD_CMD_82: .db $00	; Print Custom Character 2
;LCD_CMD_83: .db $00	; Print Custom Character 3
;LCD_CMD_84: .db $00	; Print Custom Character 4
;LCD_CMD_85: .db $00	; Print Custom Character 5
;LCD_CMD_86: .db $00	; Print Custom Character 6
;LCD_CMD_87: .db $00	; Print Custom Character 7
.CSEG
;----------------------/



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
;--- LCD_CMD_Length
;--- input: R16 = Command-code
;--- output: R16 = Lengte Commando+data
;--------------------------------------\
LCD_CMD_Length:
	push	ZL
	push	ZH
	ldi		ZL, low(LCD_CMD_00)
	ldi		ZH, high(LCD_CMD_00)
	; Z := Z + R16
	add		ZL, R16
	clr		R16
	adc		ZH, R16
	rcall	ReadEEPROM					; lees het aantal data bytes voor dit commando
	inc		R16							; het commando zelf neemt 1 byte in beslag..
	pop		ZH
	pop		ZL
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD_CMD_IsReady
;--- output: zeroflag: 1=commando compleet in buffer, 0=commando nog niet helemaal binnen
;---         carryflag: 1=fout opgetreden (buffer leeg bv.)
;--- (bij succes) R16: 0=ongeldig teken in buffer
;---                   1=normaal teken in buffer
;---                   2=Command-Code CustomCharacter in buffer
;---                   3=Command-Code in buffer
;--------------------------------------\
LCD_CMD_IsReady:
	push	R17
	rcall	PeekByteFrom_TWI_IN_Buffer
	brcs	Done_LCD_CMD_IsReady		; fout opgetreden?
	; Bevat R16 nu een control-code?
	cpi		R16, $20
	brlo	ControlCode					; code<$20 ?
	; Bevat R16 een control-code voor CustomCharacters?
	cpi		R16, $80
	brlo	NormalChar					; code>=$20 en code<$80
	cpi		R16, $88
	brlo	CustomCharCode				; code>=$80 en code<=$87
	cpi		R16, 0b10100000
	brlo	InvalidChar					; code>=$88 en code<$A0
	; code>=$A0
NormalChar:
	; Een normaal teken staat klaar in de buffer..
	ldi		R16, 1
	rjmp	CommandReady
ControlCode:
	; Er komt een commando in de buffer..
	; Bepaal nu de lengte van het commando (+ data bytes) in de buffer
	rcall	LCD_CMD_Length				; R16 = aantal bytes nodig in buffer voor dit commando
	mov		R17, R16
	rcall	Get_TWI_IN_Buffer_Count		; R16 = aantal bytes nu in buffer
	cp		R16, R17					; genoeg bytes in de buffer?
	brlo	CommandNotReady				; nee, nog niet..
	ldi		R16, 3
	rjmp	CommandReady				; ja..
CustomCharCode:
	; Er komt een commando voor/met een CustomCharacter in de buffer..
	; Een CMD- & data zitten in dezelfde byte; Het commando (+data) is dus al binnen..
	ldi		R16, 2
	rjmp	CommandReady				; ja..
InvalidChar:
	; Er is een foute ASCII-waarde ontvangen om af te beelden.
	ldi		R16, 0

CommandNotReady:
	clz
	sec
	rjmp	Done_LCD_CMD_IsReady
CommandReady:
	sez
	clc

Done_LCD_CMD_IsReady:
	pop		R17
	ret
;--------------------------------------/


;---------------------------------------
;--- LCD_ProcessCommand
;--------------------------------------\
LCD_ProcessCommand:
	rcall	LCD_CMD_IsReady
	breq	ReadCommand					; Er is een compleet commando in de buffer..
	rjmp	Done_LCD_ProcessCommand		; nog geen compleet commando in buffer..
ReadCommand:
	; Er is een compleet commando binnen.
	; R16 bevat nu een code voor het te verwerken commando.
	cpi		R16, 0						; Is het een ongeldige byte om af te beelden?
	brne	CheckNormalChar
	rcall	LoadByteFrom_TWI_IN_Buffer	; Slik deze byte in..., niet afbeelden
	rjmp	Done_LCD_ProcessCommand
CheckNormalChar:
	cpi		R16, 1						; Betreft het een normaal af te beelden byte?
	brne	CheckCustomChar
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de byte uit de buffer..
	rcall	LCD_LinePrintChar			; ..en afbeelden op het LCD.
	rjmp	Done_LCD_ProcessCommand
CheckCustomChar:
	cpi		R16, 2						; Een commando-byte voor een custom-character?
	brne	Handle_CMD
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de CMD/data-byte uit de buffer..
	andi	R16, $7F					; hoogste bit uit..en ASCII blijft over
	rcall	LCD_LinePrintChar			; ..en afbeelden op het LCD.
	rjmp	Done_LCD_ProcessCommand

Handle_CMD:
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de CMD-byte..
	brcc	Handle_CMD_00				; geen fout? dan verwerken..
	rjmp	Done_LCD_ProcessCommand		; fout opgetreden bij lezen van buffer
	;-----------------------------------
Handle_CMD_00:							; $00	NULL
	cpi		R16, $00
	brne	Handle_CMD_01
	; doe niets..
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_01:							; $01	Turn On
	cpi		R16, $01
	brne	Handle_CMD_02
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de data-byte met de vlag..
	rcall	Turn_On
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_02:							; $01	Turn Off
	cpi		R16, $02
	brne	Handle_CMD_03
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de data-byte met de vlag..
	rcall	Turn_Off
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_03:							; $01	Cursor Home
	cpi		R16, $03
	brne	Handle_CMD_04
	rcall	LCD_Home
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_04:							; $04	Cursor LineHome
	cpi		R16, $04
	brne	Handle_CMD_05
	rcall	LCD_LineHome
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_05:							; $05	Cursor LineEnd
	cpi		R16, $05
	brne	Handle_CMD_06
	rcall	LCD_LineEnd
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_06:							; $06	Print Hex
	cpi		R16, $06
	brne	Handle_CMD_07
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de data-byte, low(word)
	mov		ZL, R16
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de data-byte, high(word)
	mov		ZH, R16
	rcall	LCD_Hex
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_07:							; $07	(niet gebruikt)
	cpi		R16, $07
	brne	Handle_CMD_08
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de data-byte, low(word)
	mov		ZL, R16
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de data-byte, high(word)
	mov		ZH, R16
	rcall	LCD_Dec
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_08:							; $08	BackSpace
	cpi		R16, $08
	brne	Handle_CMD_09
	rcall	LCD_BackSpace
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_09:							; $09	Control Bootscreen (1 data byte)
	cpi		R16, $09
	brne	Handle_CMD_0A
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de data-byte..
	;!!!!!DEBUG!!!!!
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_0A:							; $0A	LineFeed
	cpi		R16, $0A
	brne	Handle_CMD_0B
	;!!!!!DEBUG!!!!!
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_0B:							; $0B	Delete
	cpi		R16, $0B
	brne	Handle_CMD_0C
	rcall	LCD_Delete
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_0C:							; $0C	Form Feed (Clear Display)
	cpi		R16, $0C
	brne	Handle_CMD_0D
	rcall	LCD_Clear
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_0D:							; $0D	Carriage Return
	cpi		R16, $0D
	brne	Handle_CMD_0E
	rcall	LCD_NextLine
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_0E:							; $0E	Backlight Control (1 data byte)
	cpi		R16, $0E
	brne	Handle_CMD_0F
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de data-byte..
	;!!!!!DEBUG!!!!!
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_0F:							; $0F	Contrast Control (1 data byte)
	cpi		R16, $0F
	brne	Handle_CMD_10
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de data-byte..
	;!!!!!DEBUG!!!!!
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_10:							; $10	Fill (1 data byte)
	cpi		R16, $10
	brne	Handle_CMD_11
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de data-byte (vul-teken)..
	rcall	LCD_Fill
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_11:							; $11	Set Cursor Position(X,Y) (2 data bytes)
	cpi		R16, $11
	brne	Handle_CMD_12
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de data-byte (X)..
	mov		R17, R16
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de data-byte (Y)..
	mov		R18, R16
	rcall	LCD_SetCursorXY
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_12:							; $12	Insert
	cpi		R16, $12
	brne	Handle_CMD_13
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de data-byte (invoeg-teken)..
	rcall	LCD_Insert
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_13:							; $13	(niet gebruikt)
	cpi		R16, $13
	brne	Handle_CMD_14
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_14:							; $14	(niet gebruikt)
	cpi		R16, $14
	brne	Handle_CMD_15
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_15:							; $15	(niet gebruikt)
	cpi		R16, $15
	brne	Handle_CMD_16
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_16:							; $16	(niet gebruikt)
	cpi		R16, $16
	brne	Handle_CMD_17
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_17:							; $17	(niet gebruikt)
	cpi		R16, $17
	brne	Handle_CMD_18
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_18:							; $18	(niet gebruikt)
	cpi		R16, $18
	brne	Handle_CMD_19
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_19:							; $19	Set Custom Character Bitmap (9 data bytes)
	cpi		R16, $19
	brne	Handle_CMD_1A
	rcall	Upload_CustomCharacter
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_1A:							; $1A	Reboot
	cpi		R16, $1A
	brne	Handle_CMD_1B
	; Een soft reboot..
	rcall	LCD_Initialize
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_1B:							; $1B	Escape Sequence Prefix (2 data bytes)
	cpi		R16, $1B
	brne	Handle_CMD_1C
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de data-byte..
	; R16 zou nu een '[' teken moeten bevatten (code 91)
	mov		R17, R16
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de data-byte..
	cpi		R17, '['
	brne	NoArrow
	cpi		R16, 'A'					; Pijl omhoog?
	brne	ArrowDown
	ldi		R16, 0
	rjmp	DoArrow
ArrowDown:
	cpi		R16, 'B'					; Pijl omlaag?
	brne	ArrowRight
	ldi		R16, 1
	rjmp	DoArrow
ArrowRight:
	cpi		R16, 'C'					; Pijl rechts?
	brne	ArrowLeft
	ldi		R16, 2
	rjmp	DoArrow
ArrowLeft:
	cpi		R16, 'D'					; Pijl links?
	brne	NoArrow
	ldi		R16, 3
DoArrow:
	rcall	LCD_Arrow
NoArrow:
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_1C:							; $1C	(niet gebruikt)
	cpi		R16, $1C
	brne	Handle_CMD_1D
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_1D:							; $1D	(niet gebruikt)
	cpi		R16, $1D
	brne	Handle_CMD_1E
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_1E:							; $1E	Send Data Directly To LCD-Controller (2 data bytes)
	cpi		R16, $1E
	brne	Handle_CMD_1F
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de data-byte..
	;!!!!!DEBUG!!!!!
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees de data-byte..
	;!!!!!DEBUG!!!!!
	rjmp	Done_LCD_ProcessCommand

Handle_CMD_1F:							; $1F	Show Information Screen
	cpi		R16, $1F
	brne	Done_LCD_ProcessCommand
	rcall	LCD_InfoScreen
	;rjmp	Done_LCD_ProcessCommand

Done_LCD_ProcessCommand:
	ret
;--------------------------------------/



;---------------------------------------
;--- Een zelf-gedefinieerd teken in CGRAM plaatsen
;--- input: 9 bytes in TWI_IN_Buffer
;--- !!! AUTO-INCREMENT MOET INGESCHAKELD ZIJN
;--------------------------------------\
Upload_CustomCharacter:
	push	R16
	push	R17
	push	R18
	; huidige cursor-positie bewaren
	rcall	LCD_GetCursorXY
	; De ASCII-code van het teken bepaald waar in het CGRAM de data wordt geplaatst
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees ASCII-code uit de buffer..
	lsl		R16							; LCD-RAM adres * 8
	lsl		R16
	lsl		R16
	rcall	LCD_SetCharGenAddr
	; nu de 8 bytes van het patroon overzenden
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees rij 0 van het bitpatroon uit de buffer..
	rcall	LCD_Data
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees rij 1 van het bitpatroon uit de buffer..
	rcall	LCD_Data
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees rij 2 van het bitpatroon uit de buffer..
	rcall	LCD_Data
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees rij 3 van het bitpatroon uit de buffer..
	rcall	LCD_Data
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees rij 4 van het bitpatroon uit de buffer..
	rcall	LCD_Data
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees rij 5 van het bitpatroon uit de buffer..
	rcall	LCD_Data
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees rij 6 van het bitpatroon uit de buffer..
	rcall	LCD_Data
	rcall	LoadByteFrom_TWI_IN_Buffer	; Lees rij 7 van het bitpatroon uit de buffer..
	rcall	LCD_Data
	; DDRAM adresseren ipv. CGRAM
	rcall	LCD_SetCursorXY
	pop		R18
	pop		R17
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- Een optie uitschakelen
;--- input: R16=LED_Flag
;--------------------------------------\
Turn_Off:
	push	R17
	mov		R17, LCD_Flags
	sbrc	R16, Flag_Display			; Display uit?
	rjmp	Off_Display
	sbrc	R16, Flag_Cursor			; Cursor uit?
	rjmp	Off_Cursor
	sbrc	R16, Flag_CursorBlock		; Cursor blok uit?
	rjmp	Off_CursorBlock
	sbrc	R16, Flag_CursorBlinking	; Cursor knipperen uit?
	rjmp	Off_CursorBlink
	sbrc	R16, Flag_Scrolling			; Scrolling uit?
	rjmp	Off_Scrolling
	sbrc	R16, Flag_ClearNewLine		; ClearNewLine uit?
	rjmp	Off_ClearNewLine
	sbrc	R16, Flag_WordWrap			; WordWrap uit?
	rjmp	Off_WordWrap
	rjmp	Done_Turn_Off
Off_Display:
	; Display-flag 0
	andi	R17, ~(1<<Flag_Display)
	mov		LCD_Flags, R17
	rcall	DisplayMode_From_Flags
	rjmp	Done_Turn_Off
Off_Cursor:
	andi	R17, ~(1<<Flag_Cursor)
	mov		LCD_Flags, R17
	rcall	DisplayMode_From_Flags
	rjmp	Done_Turn_Off
Off_CursorBlock:
	andi	R17, ~(1<<Flag_CursorBlock)
	mov		LCD_Flags, R17
	rcall	DisplayMode_From_Flags
	rjmp	Done_Turn_Off
Off_CursorBlink:
	andi	R17, ~(1<<Flag_CursorBlinking)
	mov		LCD_Flags, R17
	rcall	DisplayMode_From_Flags
	rjmp	Done_Turn_Off
Off_Scrolling:
	andi	R17, ~(1<<Flag_Scrolling)
	mov		LCD_Flags, R17
	rjmp	Done_Turn_Off
Off_ClearNewLine:
	andi	R17, ~(1<<Flag_ClearNewLine)
	mov		LCD_Flags, R17
	rjmp	Done_Turn_Off
Off_WordWrap:
	andi	R17, ~(1<<Flag_WordWrap)
	mov		LCD_Flags, R17
	;rjmp	Done_Turn_Off
Done_Turn_Off:
	pop		R17
	ret
;--------------------------------------/


;---------------------------------------
;--- Een optie inschakelen
;--- input: R16=LED_Flag
;--------------------------------------\
Turn_On:
	push	R17
	mov		R17, LCD_Flags
	sbrc	R16, Flag_Display			; Display aan?
	rjmp	On_Display
	sbrc	R16, Flag_Cursor			; Cursor aan?
	rjmp	On_Cursor
	sbrc	R16, Flag_CursorBlock		; Cursor blok aan?
	rjmp	On_CursorBlock
	sbrc	R16, Flag_CursorBlinking	; Cursor knipperen aan?
	rjmp	On_CursorBlink
	sbrc	R16, Flag_Scrolling			; Scrolling aan?
	rjmp	On_Scrolling
	sbrc	R16, Flag_ClearNewLine		; ClearNewLine aan?
	rjmp	On_ClearNewLine
	sbrc	R16, Flag_WordWrap			; WordWrap aan?
	rjmp	On_WordWrap
	rjmp	Done_Turn_On
On_Display:
	; Display-flag 0
	ori		R17, (1<<Flag_Display)
	mov		LCD_Flags, R17
	rcall	DisplayMode_From_Flags
	rjmp	Done_Turn_On
On_Cursor:
	ori		R17, (1<<Flag_Cursor)
	mov		LCD_Flags, R17
	rcall	DisplayMode_From_Flags
	rjmp	Done_Turn_On
On_CursorBlock:
	; Cursor-flag 1
	; BlockCursor-flag 1
	; Flag_CursorBlinking-flag 0
	ori		R17, (1<<Flag_Cursor)
	ori		R17, (1<<Flag_CursorBlock)
	andi	R17, ~(1<<Flag_CursorBlinking)
	mov		LCD_Flags, R17
	rcall	DisplayMode_From_Flags
	rjmp	Done_Turn_On
On_CursorBlink:
	; Cursor-flag 1
	; BlockCursor-flag 1
	; Flag_CursorBlinking-flag 1
	ori		R17, (1<<Flag_Cursor)
	ori		R17, (1<<Flag_CursorBlock)
	ori		R17, (1<<Flag_CursorBlinking)
	mov		LCD_Flags, R17
	rcall	DisplayMode_From_Flags
	rjmp	Done_Turn_On
On_Scrolling:
	ori		R17, (1<<Flag_Scrolling)
	mov		LCD_Flags, R17
	rjmp	Done_Turn_On
On_ClearNewLine:
	ori		R17, (1<<Flag_ClearNewLine)
	mov		LCD_Flags, R17
	rjmp	Done_Turn_On
On_WordWrap:
	ori		R17, (1<<Flag_WordWrap)
	mov		LCD_Flags, R17
	;rjmp	Done_Turn_On
Done_Turn_On:
	pop		R17
	ret
;--------------------------------------/

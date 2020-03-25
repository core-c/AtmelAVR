
.include "RotatingBuffer.asm"			; macro's voor implementatie van een roterende buffer.
.include "ScanCodes.inc"				; toetsen scancodes in EEPROM-geheugen


;--- Toetsenbord pinnen ----------------
.equ Keyboard_Data_Port	= PINB
.equ Keyboard_Data_Pin	= PB1
.equ Keyboard_Clock_Pin	= PD3



.equ KeyBufferSize	= 16
;--- Het begin van het DATA-segment ----; SRAM
.DSEG
KeyBuffer:		.BYTE KeyBufferSize		;| alloceer de toetsenbord-buffer
KeyInput:		.BYTE 2					;| het adres voor de nieuw toe te voegen Key
KeyOutput:		.BYTE 2					;| het adres voor de uit de buffer te lezen Key
KeysInBuffer:	.BYTE 1					;| Het aantal toetsen in de buffer
Key:			.BYTE 1					; tbv. de huidige toets
Edge:			.BYTE 1					; 0=neg (neergaand), <>0=pos (opgaand)
BitCount:		.BYTE 1					; de seriële bit-teller
isKeyUp:		.BYTE 1					; tbv. toetsdruk-status <>0 = toets uitgedrukt
isKeyShift:		.BYTE 1					; tbv. toetsdruk-status <>0 = Shift gedrukt
isKeyCtrl:		.BYTE 1					; tbv. toetsdruk-status <>0 = Ctrl gedrukt
isKeyAlt:		.BYTE 1					; tbv. toetsdruk-status <>0 = Alt gedrukt
isKeyExtended:	.BYTE 1					; tbv. extended scancode ($E0 .. [..])
;_____________ totaal 29 bytes voor buffer

;--- Het begin van het CODE-segment ----
.CSEG									; FLASH/PROGRAM


;------------------------------------------
;--- Subroutine: Initialiseer toetsenbord
;------------------------------------------
KB_Initialize:
	; variabelen instellen
	StoreIByteSRAM Edge, 0
	StoreIByteSRAM BitCount, 0
	StoreIByteSRAM isKeyUp, 0
	StoreIByteSRAM isKeyShift, 0
	StoreIByteSRAM isKeyCtrl, 0
	StoreIByteSRAM isKeyExtended, 0
	StoreIByteSRAM KeysInBuffer, 0
	; De toetsenbord-buffer pointers instellen
	; voor (buffer) inkomende toetsen....
	StoreIWordSRAM KeyInput, KeyBuffer
	; voor (buffer) uitgaande toetsen....
	StoreIWordSRAM KeyOutput, KeyBuffer
	rcall	KB_On
	ret








;------------------------------------------
;--- INT1 reageren bij opgaande flank
;------------------------------------------
.MACRO INT1_On_RisingEdge
	in		temp, MCUCR
;	andi	temp, ~(1<<ISC11 | 1<<ISC10)
	ori		temp, (1<<ISC11 | 1<<ISC10)		;ISC11 & ISC10 bits op 1
	out		MCUCR, temp
.ENDMACRO

;------------------------------------------
;--- INT1 reageren bij neergaande flank
;------------------------------------------
.MACRO INT1_On_FallingEdge
	in		temp, MCUCR
	andi	temp, ~(1<<ISC11 | 1<<ISC10)	;ISC11 & ISC10 bits op 0
	ori		temp, (1<<ISC11 | 0<<ISC10)		;ISC11 op 1
	out		MCUCR, temp
.ENDMACRO



;------------------------------------------
;--- Keyboard inschakelen
;------------------------------------------
KB_On:
;	cli
	; externe interrupt INT1 activeren op vallende flank 
	; (trigger als de knop INgedrukt wordt)
	INT1_On_FallingEdge
	; externe interrupt INT1 inschakelen in Global Interrupt Mask Register
	in		temp, GIMSK
	ori		temp, (1<<INT1)
	out		GIMSK, temp
;	sei
	ret

;------------------------------------------
;--- Keyboard uitschakelen
;------------------------------------------
KB_Off:
;	cli
	; externe interrupt INT1 uitschakelen in Global Interrupt Mask Register
	in		temp, GIMSK
	ori		temp, (0<<INT1)
	out		GIMSK, temp
;	sei
	ret




;------------------------------------------
;--- Een byte uit EEPROM-geheugen lezen
;--- output: R20 = gelezen byte
;------------------------------------------
ReadEEPROM:
	sbic	EECR, EEWE			; EEPROM Control Register; EEPROM Write Enable
	rjmp	ReadEEPROM
	out		EEARH, ZH			; EEPROM Address Register High/Low
	out		EEARL, ZL
	sbi		EECR, EERE			; Read Enable zetten
	in		R20, EEDR			; EEPROM Data Register
	ret
;------------------------------------------
;--- Decodeer Scancode naar ASCII-code
;--- input: temp = Laatst ontvangen byte
;---               van de scancode
;--- output: temp = ASCII-code of $00 als er
;---                geen geldige ASCII-code is
;------------------------------------------
KB_ScancodeToASCII:
	push	ZL
	push	ZH
	push	R20					; resultaat
	ldi		R20, 0; (ongeldige ASCII-waarde)
	; De hele scancode-tabel doorlopen
	; op zoek naar een overeenkomende scancode.
	; Start-adres van de tabel in EEPROM-geheugen in Z-register laden
	ldi		ZH, HIGH(ScanCodes1)
	ldi		ZL, LOW(ScanCodes1)
	; lees het EEPROM adres en plaats de byte in temp
ReadTable1:
	rcall	ReadEEPROM			; lees scan-code
	cpi		R20, 0				; einde van de tabel?
	breq	_1
	cp		R20, temp
	breq	CodeFound
	adiw	ZL,2				; adres-pointer op volgende scan-code in tabel plaatsen
	rjmp	ReadTable1
CodeFound:
	adiw	ZL,1				; adres-pointer op ASCII-code in tabel plaatsen
	rcall	ReadEEPROM			; lees bijhorende ASCII-code
_1:
	mov		temp, R20
	pop		R20
	pop		ZH
	pop		ZL
	ret



;------------------------------------------
;--- Decodeer ASCII-code
;---          kleine -> grote letters
;--- input: temp = ASCII-code
;--- output: temp = hoofdletter ASCII-code
;------------------------------------------
KB_ShiftASCII:
	; als de waarde in register 'temp' in ['a','z']
	; dan 20h van de waarde in 'temp' aftrekken.
	cpi		temp, 'a'
	brmi	ReadTable1_Shifted
	cpi		temp, 'z'
	brpl	ReadTable1_Shifted
	subi	temp, $20
	rjmp	Done_ShiftASCII
ReadTable1_Shifted:
	ldi		ZH, HIGH(ScanCodes1_Shifted)
	ldi		ZL, LOW(ScanCodes1_Shifted)
	rcall	ReadEEPROM			; lees scan-code
	cpi		R20, 0				; einde van de tabel?
	breq	Done_ShiftASCII
	cp		R20, temp
	breq	ShiftedCodeFound
	adiw	ZL,2				; adres-pointer op volgende scan-code in tabel plaatsen
	rjmp	ReadTable1_Shifted
ShiftedCodeFound:
	adiw	ZL,1				; adres-pointer op ASCII-code in tabel plaatsen
	rcall	ReadEEPROM			; lees bijhorende ASCII-code
	mov		temp, R20
Done_ShiftASCII:
	ret






;------------------------------------------
;--- Decodeer Scancode naar ASCII.
;--- Bij indrukken van de Enter-toets wordt
;--- de LCD-cursor naar de logisch volgende
;--- regel verplaatst.
;------------------------------------------
KB_DecodeKey:
	push	temp

	; is er een toets losgelaten?
	LoadByteSRAM temp, isKeyUp ;SRAM variabele
	tst		temp
	breq	_KeyPressed

_KeyUnPressed:
	StoreIByteSRAM isKeyUp, 0
	LoadByteSRAM temp, Key
_keyShiftL_:
	cpi		temp, scLShift ;scancode
	brne	_keyShiftR_
	StoreIByteSRAM isKeyShift, 0
	rjmp	ForgetKey
_keyShiftR_:
	cpi		temp, scRShift ;scancode
	brne	_Frgt
	StoreIByteSRAM isKeyShift, 0
_Frgt:
	rjmp	ForgetKey

_KeyPressed:
	; bij escape toets LCD wissen
	; (nu doen want anders komt de toets niet in de buffer)
	LoadByteSRAM temp, Key
	cpi		temp, scESC ;scancode
	brne	_keyupper
	rcall	LCD_Clear
	rcall	LCD_Home
	rjmp	ForgetKey
_keyupper:
	cpi		temp, scKeyUp ;scancode
	brne	_keyShiftL
	StoreIByteSRAM isKeyUp, $FF
	rjmp	ForgetKey
_keyShiftL:
	cpi		temp, scLShift ;scancode
	brne	_keyShiftR
	StoreIByteSRAM isKeyShift, $FF
	rjmp	ForgetKey
_keyShiftR:
	cpi		temp, scRShift ;scancode
	brne	_keyEnter
	StoreIByteSRAM isKeyShift, $FF
	rjmp	ForgetKey

_keyEnter:
;	LoadByteSRAM temp, Key
	cpi		temp, scEnter ;scancode
	brne	_keyBS
	; cursor naar de logisch volgende regel verplaasten.
	rcall	LCD_NextLine
	rjmp	ForgetKey
_keyBS:
	cpi		temp, scBS ;scancode
	brne	_Convert
	rcall	LCD_BackSpace
;	rjmp	ForgetKey

ForgetKey:
	ldi		temp, 0 ;deze scancode-byte verder negeren...
_Convert:
;	LoadByteSRAM temp, Key
	; Eerst naar ASCII converteren (alleen cijfers en kleine letters)
	rcall	KB_ScancodeToASCII
	; ASCII-code in register 'temp' naar SRAM variabele 'Key'
	StoreByteSRAM Key, temp
	cpi		temp, 0
	breq	Done_DecodeKey
	LoadByteSRAM temp, isKeyShift	; shiften?
	tst		temp
	breq	Done_DecodeKey
	LoadByteSRAM temp, Key
	rcall	KB_ShiftASCII			; ASCII -> ASCII shifted key
	StoreByteSRAM Key, temp

Done_DecodeKey:
	pop		temp
	ret







;------------------------------------------
;--- De INT0- of INT1- Interrupt-Handler
;------------------------------------------
KB_Interrupt:
	push	R25
;	push	temp3
	push	temp
	; Bepaal op welke flank de INT1 is ge-activeerd.
	LoadByteSRAM R25, Edge
	tst		R25
	brne	_33;OpgaandeFlank

_31: ;NeergaandeFlank:--------------------\
	; INT1 bij opgaande flank activeren
	INT1_On_RisingEdge
	; Op de opgaande flank reageren vlag
	StoreIByteSRAM Edge, $FF

	; BitCount 0    = start bit, 
	; BitCount 1..8 = databits[0..7], 
	; BitCount 9    = parity bit,
	; BitCount 10   = stop bit
	; Alleen de data-bits hebben we nodig.
	; Start-, Stop- & Parity-bit vooralsnog negeren.
	LoadByteSRAM R25, BitCount
	cpi		R25, 1
	brmi	_32;doneIRQ1'
	cpi		R25, 8
	brpl	_32;doneIRQ1'
	; de bits schuiven
	LoadByteSRAM R25, Key				
	lsr		R25
	; hoogste bit van Key zetten als Keyboard_Data_Pin hoog is
	in		temp, Keyboard_Data_Port
	andi	temp, (1<<Keyboard_Data_Pin)
	breq	_311
	ori		R25, 0b10000000
_311:
	StoreByteSRAM Key, R25
_32: ;doneIRQ1'
	rjmp	_34;doneIRQ1
	;--------------------------------------/

_33: ;OpgaandeFlank:-----------------------\
	; externe interrupt INT1 activeren op vallende flank 
	; (trigger als de knop INgedrukt wordt)
	INT1_On_FallingEdge
	; Op de neergaande flank reageren vlag
	StoreIByteSRAM Edge, 0

	; de gezonden bits tellen
	IncrementByteSRAM BitCount; via R25
	cpi		R25, 11
	brne	_34;doneIRQ1
	; opnieuw 11 bits tellen
	StoreIByteSRAM BitCount, 0
; alle 11 bits hebben we, nu decoderen naar een scancode

Decode:
;	;!!!!! de volgende statements horen niet in een interrupt-handler thuis !!!!!
;	; print de waarde van deze byte direct naar het LCD !!!!!!!!!!!!!!!!! ter vervanging van: rcall	Decode_Key
;	LoadByteSRAM temp, Key
;	rcall	LCD_HexByte
;	ldi		temp, ' '
;	rcall	LCD_Data
;	rjmp	_331
;	;!!!!! 

	rcall	KB_DecodeKey

	LoadByteSRAM temp, Key
	cpi		temp, 0
	breq	_331
StoreInBuffer:
	; Plaats de ASCII-code in de toetsenbuffer.
;	LoadByteSRAM R25, Key
	StoreByteSRAMIntoBuffer temp, KeyBuffer, KeyInput, KeysInBuffer, KeyBufferSize
;	; extended "flag" wissen
;	StoreIByteSRAM isKeyExtended, 0

_331:
	StoreIByteSRAM Key, 0
	;--------------------------------------/

_34: ;doneIRQ1:
	pop		temp
;	pop		temp3
	pop		R25
	reti


;*************************************************************************************
;***
;***  Een AT-Keyboard implementatie.
;***
;***  De keyboard-clock wordt aangesloten op de INT1-pin van de AVR.
;***  De keyboard-data wordt aangesloten op een willekeurige pin, in dit geval PB1.
;***
;***
;***    keyboard 5-pin DIN connector:	pin #1 (Clock)	->	AVR-INT1 (PD3, pin #17)
;***    								pin #2 (Data)	->	AVR-PB1 (pin #2)
;***    	   2*						pin #3 (Not Connected)
;***    	 4*   *5					pin #4 (GND)	->	AVR-GND
;***    	 1*	_ *3					pin #5 (VCC)	->	AVR-VCC
;***
;***    keyboard 6-pin MiniDIN (PS/2):	pin #1 (Data)	->	AVR-PB1 (pin #2)
;***									pin #2 (Not Connected)
;***		  6*|*5						pin #3 (GND)	->	AVR-GND
;***		 4*   *3					pin #4 (VCC)	->	AVR-VCC
;***		 2* _ *1					pin #5 (Clock)	->	AVR-INT1 (PD3, pin #17)
;***									pin #6 (Not Connected)
;***
;***  De gezonden keyboard-data is serieel:
;***    1 startbit (altijd 0), 
;***    8 data-bits[0..7] (scancode),
;***    1 parity-bit,
;***    1 stopbit (altijd 1).
;***
;***  De AT-toetsenbord scancode(s) voor het loslaten van een toets is de normale
;***  scancode(s) voorafgegaand door $F0. Een ESC indrukken: scancode = $EC
;***                                      Een ESC loslaten: scancodes = $F0 $EC
;***  Het aangesloten Compaq toetsenbord geeft echter een $E0 code ipv. een $F0.
;***
;*************************************************************************************

.include "RotatingBuffer.asm"			; macro's voor implementatie van een roterende buffer.
.include "ScanCodes.inc"				; toetsen scancodes in EEPROM-geheugen


;--- Toetsenbord pinnen ----------------
.equ Keyboard_Data_Port	= PINB			; keyboard data input port
.equ Keyboard_Data_Pin	= PB1			; keyboard data pin
.equ Keyboard_Clock_Pin	= PD3			; keyboard clock pin


;--- De buffer voor scancodes ----------
.equ KeyBufferSize	= 16				; De lengte van de scancode-buffer in SRAM
.DSEG									;--- Het begin van een DATA-segment ---- SRAM
KeyBuffer:		.BYTE KeyBufferSize		;| alloceer de toetsenbord-buffer
KeyInput:		.BYTE 2					;| het adres voor de nieuw toe te voegen Key
KeyOutput:		.BYTE 2					;| het adres voor de uit de buffer te lezen Key
KeysInBuffer:	.BYTE 1					;| Het aantal toetsen in de buffer
Key:			.BYTE 1					; de huidige laatst ontvangen byte van de toets scancode
Edge:			.BYTE 1					; 0=neg (neergaand), <>0=pos (opgaand)
BitCount:		.BYTE 1					; de seriële bit-teller [0..10]
;_____________ totaal 20 bytes voor ScanCode-buffer

;--- De buffer voor ASCII-codes --------
; ASCII flags bit toekenningen
.equ flagExtended	= (1<<7)			; extended scancode verwerken?
.equ flagKeyUp		= (1<<6)			; keyUp scancode verwerken?
.equ flagShift		= (1<<5)			; Shift ingedrukt?
.equ flagCtrl		= (1<<4)			; Ctrl ingedrukt?
.equ flagAlt		= (1<<3)			; Alt ingedrukt?
.equ flagCAPSL		= (1<<2)			; Caps locked?
.equ flagNUML		= (1<<1)			; Num locked?
; SPECIAL flags bit toekenningen
.equ flagF1	= (1<<7)					; F1 toggle-status
.equ flagF2	= (1<<6)					; F2 toggle-status
.equ flagF3	= (1<<5)					; F3 toggle-status
.equ flagF4	= (1<<4)					; F4 toggle-status

.equ ASCIIBufferSize	= 4				; De lengte van de ASCII-buffer in SRAM
.DSEG									;--- Het begin van een DATA-segment ---- SRAM
ASCIIBuffer:	.BYTE ASCIIBufferSize	;| alloceer de ASCII-buffer
ASCIIInput:		.BYTE 2					;| het adres voor de nieuw toe te voegen ASCII-code
ASCIIOutput:	.BYTE 2					;| het adres voor de uit de buffer te lezen ASCII-code
ASCIIInBuffer:	.BYTE 1					;| Het aantal ASCII-codes in de buffer
ASCIIKey:		.BYTE 1					; tbv. omzetting naar ASCII
ASCIIFlags:		.BYTE 1					; status (KeyUp/Shift/Ctrl/Alt/CAPSL/NUML)
SPECIALFlags:	.BYTE 1					; Speciale status
;_____________ totaal 12 bytes voor ASCII-buffer
.CSEG									;--- Het begin van een CODE-segment ----  FLASH/PROGRAM


;------------------------------------------
;--- Subroutine: Initialiseer toetsenbord
;------------------------------------------
KB_Initialize:
	; De ASCII-buffer initialiseren
	rcall	ASCII_Initialize
	; variabelen instellen
	StoreIByteSRAM Edge, 0
	StoreIByteSRAM BitCount, 0
	StoreIByteSRAM KeysInBuffer, 0
	; De toetsenbord-buffer pointers instellen
	; voor (buffer) inkomende toetsen....
	StoreIWordSRAM KeyInput, KeyBuffer
	; voor (buffer) uitgaande toetsen....
	StoreIWordSRAM KeyOutput, KeyBuffer
	; De keyboard data-lijn als input instellen
	cbi		DDRB, Keyboard_Data_Pin
	; poort D3 als input zetten tbv. INT1 Keyboard-input
	cbi		DDRD, Keyboard_Clock_Pin
	sbi		PORTD, Keyboard_Clock_Pin; met de interne pull-up actief
	; toetsenbord inschakelen
	rcall	KB_On
	ret

;------------------------------------------
;--- Initialiseer ASCII-buffer
;------------------------------------------
ASCII_Initialize:
	StoreIByteSRAM ASCIIKey, 0
	StoreIByteSRAM ASCIIInBuffer, 0
	StoreIWordSRAM ASCIIInput, ASCIIBuffer
	StoreIWordSRAM ASCIIOutput, ASCIIBuffer
	; status bits allemaal op 0 resetten
	StoreIByteSRAM ASCIIFlags, 0
	StoreIByteSRAM SPECIALFlags, 0
	ret




;------------------------------------------
;--- INT1 reageren bij opgaande flank
;------------------------------------------
.MACRO Next_INT1_On_RisingEdge
	in		temp, MCUCR
;	andi	temp, ~(1<<ISC11 | 1<<ISC10)
	ori		temp, (1<<ISC11 | 1<<ISC10)		;ISC11 & ISC10 bits op 1
	out		MCUCR, temp
.ENDMACRO

;------------------------------------------
;--- INT1 reageren bij neergaande flank
;------------------------------------------
.MACRO Next_INT1_On_FallingEdge
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
	Next_INT1_On_FallingEdge
	; externe interrupt INT1 inschakelen in Global Interrupt Mask Register
	in		temp, GIMSK
	ori		temp, (1<<INT1)
	out		GIMSK, temp
;	sei
	ret

;;------------------------------------------
;;--- Keyboard uitschakelen
;;------------------------------------------
;KB_Off:
;;	cli
;	; externe interrupt INT1 uitschakelen in Global Interrupt Mask Register
;	in		temp, GIMSK
;	ori		temp, (0<<INT1)
;	out		GIMSK, temp
;;	sei
;	ret




;------------------------------------------
;--- De INT0- of INT1- Interrupt-Handler
;------------------------------------------
KB_Interrupt:
	push	temp
	push	R24	; in RotatingBuffer
	push	R25	;    RotatingBuffer
	push	ZL	;    RotatingBuffer
	push	ZH	;    RotatingBuffer
	; Bepaal op welke flank de INT1 is ge-activeerd.
	LoadByteSRAM R25, Edge					; reactie op wat voor een flank?
	tst		R25
	brne	RisingEdge

FallingEdge:;-------------------------\
	;---- Er is een bit ontvangen, nu bit aanschuiven in Key.
	; volgende INT1 bij opgaande flank activeren
	Next_INT1_On_RisingEdge
	; Op de opgaande flank reageren vlag
	StoreIByteSRAM Edge, $FF

	; BitCount 0    = start bit,		negeren
	; BitCount 1..8 = databits[0..7],	verzamelen als byte 'Key'
	; BitCount 9    = parity bit,		negeren
	; BitCount 10   = stop bit			negeren
	LoadByteSRAM R25, BitCount
	cpi		R25, 1
	brlo	doneIRQ_KB_
	cpi		R25, 8+1
	brsh	doneIRQ_KB_
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
doneIRQ_KB_:
	rjmp	doneIRQ_KB
	;--------------------------------------/

RisingEdge:;----------------------------\
	;--- De nieuw te lezen bit gaat binnenkomen, nu bits tellen.
	;--- Als alle bits zijn ontvangen, dan Key opslaan in buffer.
	; externe interrupt INT1 activeren op vallende flank 
	; (trigger als de knop INgedrukt wordt)
	Next_INT1_On_FallingEdge
	; Op de neergaande flank reageren vlag
	StoreIByteSRAM Edge, 0

	; de gezonden bits tellen
	IncrementByteSRAM BitCount; via R25
	cpi		R25, 11	; 11e bit ontvangen?
	brne	doneIRQ_KB
	; opnieuw 11 bits tellen; teller op 0
	StoreIByteSRAM BitCount, 0
	; alle 11 bits hebben we ontvangen ('Key' in SRAM), 
	; nu de scancode in de buffer plaatsen....

	; Plaats de scancode-code in de toetsen-scancode buffer.
	LoadByteSRAM temp, Key
	StoreByteSRAMIntoBuffer temp, KeyBuffer, KeyInput, KeysInBuffer, KeyBufferSize
	; Key-waarde resetten op 0
	StoreIByteSRAM Key, 0
	;--------------------------------------/

doneIRQ_KB:
	pop		ZH	; in RotatingBuffer
	pop		ZL	;    RotatingBuffer
	pop		R25	;    RotatingBuffer
	pop		R24 ;    RotatingBuffer
	pop		temp
	reti





;------------------------------------------
;--- Verwerk scancodes in de scancode-buffer.
;--- Als de code een ASCII-waarde<>0 oplevert
;--- dan gaat de ASCII-code naar de ASCII-buffer.
;--- In de main-loop hoeft een programma zich
;--- dan geen zorgen te maken om scancodes en
;--- kan direct de meer bruikbare ASCII-codes
;--- lezen uit de ASCII-buffer.
;--- De toetsen die geen ASCII-waarde opleveren
;--- (pijltjes ed.) moeten nog .... (*)
;------------------------------------------
KB_ProcessMessages:
	push	temp
	push	R20	; in KB_DecodeKey
	push	R24	; in RotatingBuffer
	push	R25	;    RotatingBuffer
	push	ZL	;    RotatingBuffer
	push	ZH	;    RotatingBuffer
	; als de buffer leeg is, wordt de carry-flag gewist, anders gezet..
	IsBufferEmpty KeysInBuffer
	brcs	ProcessScanCode
	rjmp	Done_ProcessMessages
ProcessScanCode:
	; laadt de scancode uit de scan-code buffer
	LoadByteSRAMFromBuffer temp, KeyBuffer, KeyOutput, KeysInBuffer, KeyBufferSize
	brcs	Done_ProcessMessages			; buffer lezen was mislukt
	StoreByteSRAM ASCIIKey, temp			; sts ASCIIKey, R16
	;waarde in ASCIIKey omzetten naar ASCII
	; en speciale toetsen verwerken (F1,ESC ed.)
	push	temp		; !**
	rcall	KB_DecodeKey
	pop		R24			; !**

	LoadByteSRAM R20, SPECIALFlags			; F1 gelocked? dan de scancodes afbeelden ipv. ASCII
	andi	R20, flagF1						;
	breq	DisplayASCII

;DisplayScancodes:
	; print de waarde van deze laatst ontvangen byte
	; direct naar het LCD. Dit is een byte van de scancode.
	mov		temp, R24	; !**
	;LoadByteSRAM temp, ASCIIKey
	rcall	LCD_HexByte
	ldi		temp, ' '
	rcall	LCD_Data
	rjmp	Done_ProcessMessages			; niet naar ASCII-buffer

DisplayASCII:
;	;waarde in ASCIIKey omzetten naar ASCII
;	rcall	KB_DecodeKey
	LoadByteSRAM temp, ASCIIKey				; lds R16, ASCIIKey
	cpi		temp, 0							; alleen ASCII-code's bewaren in ASCII-buffer	
	breq	Done_ProcessMessages
	; Plaats de ASCII-code in de ASCII-buffer.
	StoreByteSRAMIntoBuffer temp, ASCIIBuffer, ASCIIInput, ASCIIInBuffer, ASCIIBufferSize

Done_ProcessMessages:
	pop		ZH	; in RotatingBuffer
	pop		ZL	;    RotatingBuffer
	pop		R25	;    RotatingBuffer
	pop		R24 ;    RotatingBuffer
	pop		R20	; in KB_DecodeKey
	pop		temp
	ret









;------------------------------------------
;--- Lees een bit van een Flags-byte
;--- input:  temp      = bit masker Flags-bit
;--- output: Zero-flag = status-bit
;------------------------------------------
ReadFlags_SPECIAL:
	ldi		ZH, high(SPECIALFlags)
	ldi		ZL, low(SPECIALFlags)
	rjmp	ReadFlags_Z
ReadFlags_ASCII:
	ldi		ZH, high(ASCIIFlags)
	ldi		ZL, low(ASCIIFlags)
	;
ReadFlags_Z:
	push	temp2
	ld		temp2, Z
	and		temp2, temp						; bepaal de Zero-Flag
	pop		temp2
	ret

;------------------------------------------
;--- Schrijf een bit in een Flags-byte
;--- input: temp       = bit masker Flags-bit
;---        Zero-flag  = bit-waarde te schrijven
;------------------------------------------
WriteFlags_SPECIAL:
	ldi		ZH, high(SPECIALFlags)
	ldi		ZL, low(SPECIALFlags)
	rjmp	WriteFlags_Z
WriteFlags_ASCII:
	ldi		ZH, high(ASCIIFlags)
	ldi		ZL, low(ASCIIFlags)
	;
WriteFlags_Z:
	push	temp
	push	temp2
	brne	BitTo0							; test de Zero-Flag
BitTo1:
	ld		temp2, Z
	or		temp2, temp
	rjmp	Done_WriteFlags
BitTo0:
	ldi		temp2, $FF
	eor		temp, temp2
	ld		temp2, Z
	and		temp2, temp
Done_WriteFlags:
	st		Z, temp2
	pop		temp2
	pop		temp
	ret

;------------------------------------------
;--- Toggle een bit in een Flags-byte
;--- input: temp = bit masker Flags-bit
;------------------------------------------
ToggleFlags_ASCII:
	ldi		ZH, high(ASCIIFlags)
	ldi		ZL, low(ASCIIFlags)
	rjmp	ToggleFlags_Z
ToggleFlags_SPECIAL:
	ldi		ZH, high(SPECIALFlags)
	ldi		ZL, low(SPECIALFlags)
	;
ToggleFlags_Z:
	push	temp
	rcall	ReadFlags_Z
	breq	_BitTo1
	clz
	rjmp	Done_ToggleFlags
_BitTo1:
	sez
Done_ToggleFlags:
	rcall	WriteFlags_Z
	pop		temp
	ret









;------------------------------------------
;--- Een byte uit EEPROM-geheugen lezen
;--- input: Z = EEPROM adres
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
;--- Een scancode opzoeken in de tabel in
;--- EEPROM-geheugen.
;--- input:    Z = EEPROM beginadres tabel
;---        temp = scancode
;--- output: R20 = gelezen byte[x][1]
;------------------------------------------
ReadTableEEPROM:
	rcall	ReadEEPROM			; lees scan-code
	cpi		R20, 0				; einde van de tabel?
	breq	_EOT
	cp		R20, temp			; scancode in R20 == waarde in temp ??
	breq	_CodeFound
	adiw	ZL,2				; nee, adres-pointer op volgende scan-code in tabel plaatsen
	rjmp	ReadTableEEPROM
_CodeFound:
	adiw	ZL,1				; ja, adres-pointer op ASCII-code in tabel plaatsen
	rcall	ReadEEPROM			; lees bijhorende ASCII-code
_EOT:
	ret

;------------------------------------------
;--- Decodeer Scancode naar ASCII-code
;--- input:  SRAM var ASCIIKey = Laatst ontvangen byte van de scancode
;--- output: SRAM var ASCIIKey = ASCII-code of $00 als er geen geldige ASCII-code is
;---         temp =  <>0 KeyPad toets gedrukt (nooit shiften)
;------------------------------------------
KB_ScancodeToASCII:
	LoadByteSRAM temp, ASCIIKey
	ldi		R20, 0; (ongeldige ASCII-waarde)
	cpi		temp, 0				; te converteren ASCII=0?
	breq	StoreASCII
	; De hele scancode-tabel doorlopen
	; op zoek naar een overeenkomende scancode.
	; Start-adres van de tabel in EEPROM-geheugen in Z-register laden
	ldi		ZH, HIGH(ScanCodes1)
	ldi		ZL, LOW(ScanCodes1)
	rcall	ReadTableEEPROM
	clr		temp				; KeyPad vlag wissen
	cpi		R20, 0				; geconverteerde ASCII<>0?
	brne	StoreASCII
	; Opzoeken in de scancode-tabel voor de toetsen van het KeyPad
	ldi		ZH, HIGH(ScanCodes1KP)
	ldi		ZL, LOW(ScanCodes1KP)
	rcall	ReadTableEEPROM
	ser		temp				; KeyPad vlag zetten
StoreASCII:
	StoreByteSRAM ASCIIKey, R20
	ret

;------------------------------------------
;--- Decodeer ASCII-code
;---          kleine -> grote letters
;--- input:  SRAM var ASCIIKey = ASCII-code
;--- output: SRAM var ASCIIKey = hoofdletter ASCII-code
;---         R20 = <>0 ASCIIKey is een letter[a..z] en al geshift
;------------------------------------------
KB_CapsASCII:
	clr		R20
	; als de waarde in register 'temp' in ['a','z']
	; dan 20h van de waarde in 'temp' aftrekken.
	LoadByteSRAM temp, ASCIIKey
	cpi		temp, 'a'
	brlo	Done_CapsASCII
	cpi		temp, 'z'+1			; !!
	brsh	Done_CapsASCII
	subi	temp, $20			; ASCII-code voor hoofdletters is altijd 32 lager
	StoreByteSRAM ASCIIKey, temp
	ser		R20
Done_CapsASCII:
	ret

KB_ShiftASCII:
	rcall	KB_CapsASCII
	tst		R20
	brne	Done_ShiftASCII
	LoadByteSRAM temp, ASCIIKey
	ldi		ZH, HIGH(ScanCodes1_Shifted)
	ldi		ZL, LOW(ScanCodes1_Shifted)
	rcall	ReadTableEEPROM
	mov		temp, R20
	StoreByteSRAM ASCIIKey, temp
Done_ShiftASCII:
	ret



;------------------------------------------
;--- Decodeer Scancode in ASCIIKey naar ASCII.
;--- Bij indrukken van de Enter-toets wordt
;--- de LCD-cursor naar de logisch volgende
;--- regel verplaatst.
;------------------------------------------
KB_DecodeKey:
	; is er een toets losgelaten?
	ldi		temp, flagKeyUp		; is de KeyUp Flag gezet?
	rcall	ReadFlags_ASCII		;
	breq	KeyPressed			; Flag niet gezet? dan jmp naar KeyPressed

KeyReleased: ;--- TOETS LOSGELATEN ------------------------\
	ldi		temp, flagKeyUp		; de KeyUp flag...
	clz							; ... wissen...
	rcall	WriteFlags_ASCII	; ... in ASCIIFlags
	LoadByteSRAM temp, ASCIIKey
;_keyShiftL_:
	cpi		temp, scLShift ;scancode
	brne	_keyShiftR_
	rjmp	_ClearFlagShift
_keyShiftR_:
	cpi		temp, scRShift ;scancode
	brne	_keyCtrlL_
	rjmp	_ClearFlagShift
_keyCtrlL_:
	cpi		temp, scLCtrl ;scancode
	brne	_keyAltL_
	rjmp	_ClearFlagCtrl
_keyAltL_:
	cpi		temp, scLAlt ;scancode
	brne	_isExtended_
	rjmp	_ClearFlagAlt
	;--- TOETS MET EXTENDED SCANCODES UITGEDRUKT\
_isExtended_:
	ldi		temp, flagExtended	; is de Extended Flag gezet?
	rcall	ReadFlags_ASCII		;
	breq	_ForgetKey_			; Flag niet gezet? dan jump naar _ForgetKey_
	; Er is een toets met een extended scancode losgelaten
	LoadByteSRAM temp, ASCIIKey
;_keyCtrlR_:
	cpi		temp, scRCtrl ;extended scancode
	brne	_keyAltR_
	rjmp	_ClearFlagCtrl
_keyAltR_:
	cpi		temp, scRAlt ;extended scancode
	brne	_ForgetKey_
	rjmp	_ClearFlagAlt
	;-------------------------------------------/
_ClearFlagKeyUp:
	ldi		temp, flagKeyUp		; de KeyUp Flag...
	rjmp	_ClearFlag
_ClearFlagShift:
	ldi		temp, flagShift		; de Shift Flag...
	rjmp	_ClearFlag
_ClearFlagCtrl:
	ldi		temp, flagCtrl		; de Ctrl Flag...
	rjmp	_ClearFlag
_ClearFlagAlt:
	ldi		temp, flagAlt		; de Alt Flag...
_ClearFlag:
	clz							; ...wissen...
	rcall	WriteFlags_ASCII	; ... in ASCIIFlags
_ForgetKey_:
	ldi		temp, flagExtended	; de Extended Flag
	clz							; ...wissen...
	rcall	WriteFlags_ASCII	; ... in ASCIIFlags
	rjmp	ForgetKey
	;------------------------------------------------------/


KeyPressed: ;--- TOETS INGEDRUKT --------------------------\
	LoadByteSRAM temp, ASCIIKey
;_keyExtended:
	cpi		temp, scExtended ;scancode
	brne	_keyUp
	rjmp	_SetFlagExtended
_keyUp:
	cpi		temp, scKeyUp ;scancode
	brne	_keyShiftL
	rjmp	_SetFlagKeyUp
_keyShiftL:
	cpi		temp, scLShift ;scancode
	brne	_keyShiftR
	rjmp	_SetFlagShift
_keyShiftR:
	cpi		temp, scRShift ;scancode
	brne	_keyCtrlL
	rjmp	_SetFlagShift
_keyCtrlL:
	cpi		temp, scLCtrl ;scancode
	brne	_keyAltL
	rjmp	_SetFlagCtrl
_keyAltL:
	cpi		temp, scLAlt ;scancode
	brne	_keyCAPSL
	rjmp	_SetFlagAlt
_keyCAPSL:
	cpi		temp, scCAPSL ;scancode
	brne	_isExtended
	ldi		temp, flagCAPSL		; de CAPSL Flag flippen...
	rcall	ToggleFlags_ASCII	; ...in ASCIIFlags
	rjmp	ForgetKey
	;--- TOETS MET EXTENDED SCANCODES GEDRUKT -\
_isExtended:
	ldi		temp, flagExtended	; is de Extended Flag gezet?
	rcall	ReadFlags_ASCII		;
	breq	_SpecialKeys1		; Flag niet gezet? dan jump naar _SpecialKeys1
	; Er is een toets met een extended scancode losgelaten
	LoadByteSRAM temp, ASCIIKey
;_keyCtrlR: ;extended scancode
	cpi		temp, scRCtrl ;extended scancode
	brne	_keyAltR
	rjmp	_SetFlagCtrl
_keyAltR: ;extended scancode
	cpi		temp, scRAlt ;extended scancode
	brne	_ArrowUp
	rjmp	_SetFlagAlt
	;--- MET SPECIALE (LCD)FUNCTIE TOEGEKEND
;_SpecialKeysExtended:
_ArrowUp:
	cpi		temp, scArrowUp ;extended scancode
	brne	_ArrowDn
	ldi		temp, 0
	rjmp	_A_
_ArrowDn:
	cpi		temp, scArrowDn ;extended scancode
	brne	_ArrowL
	ldi		temp, 1
	rjmp	_A_
_ArrowL:
	cpi		temp, scArrowL ;extended scancode
	brne	_ArrowR
	ldi		temp, 3
	rjmp	_A_
_ArrowR:
	cpi		temp, scArrowR ;extended scancode
	brne	_Home
	ldi		temp, 2
_A_:
	rcall	LCD_Arrow
	rjmp	ForgetKey
_Home:
	cpi		temp, scHome ;extended scancode
	brne	_KPEnter
	rcall	LCD_LineHome
	rjmp	ForgetKey
_KPEnter:
	cpi		temp, scKPEnter
	brne	_DEL
	rcall	LCD_NextLine
	rjmp	ForgetKey
_DEL:
	cpi		temp, scDEL ;extended scancode
	brne	NoReset
	; de AVR resetten als ook Ctrl & Alt is gedrukt
	ldi		temp, flagCtrl		; is de Ctrl Flag gezet?...
	rcall	ReadFlags_ASCII		; ...in ASCIIFlags
	breq	NoReset
	ldi		temp, flagAlt		; is de Alt Flag gezet?...
	rcall	ReadFlags_ASCII		; ...in ASCIIFlags
	breq	NoReset
	; CTRL-ALT-DEL is gedrukt => de AVR resetten
	rjmp	RESET				; Ctrl-Alt-Del gedrukt
NoReset:
	rjmp	ForgetKey
	;-------------------------------------------/
	;--- TOETS MET ENKELE SCANCODE GEDRUKT -----\
	;--- MET SPECIALE (LCD)FUNCTIE TOEGEKEND
_SpecialKeys1:
	LoadByteSRAM temp, ASCIIKey
;_keyEnter:
	cpi		temp, scEnter ;scancode
	brne	_keyBS
	; cursor naar de logisch volgende regel verplaasten.
	rcall	LCD_NextLine
	rjmp	ForgetKey
_keyBS:
	cpi		temp, scBS ;scancode
	brne	_keyESC
	rcall	LCD_BackSpace
	rjmp	ForgetKey
_keyESC:
	; bij escape toets LCD wissen
	cpi		temp, scESC ;scancode
	brne	_keyF1
	rjmp	_CLS
_keyF1:
	; bij F1 wisselen afbeelden scancodes/ASCII
	cpi		temp, scF1 ;scancode
	brne	_Convert			; geen aparte scancode? dan converteren naar een ASCII-waarde
	ldi		temp, flagF1		; de F1 Flag...
	rcall	ToggleFlags_SPECIAL	; ... flippen in SPECIALFlags
_CLS:							; De beeldinhoud van het LCD wissen & cursor op begin 1e regel
	rcall	LCD_Clear
	rcall	LCD_Home
	rjmp	ForgetKey
	;-------------------------------------------/
_SetFlagExtended:
	ldi		temp, flagExtended	; de Extended Flag...
	rjmp	_SetFlag
_SetFlagKeyUp:
	ldi		temp, flagKeyUp		; de KeyUp Flag...
	rjmp	_SetFlag
_SetFlagShift:
	ldi		temp, flagShift		; de Shift Flag...
	rjmp	_SetFlag
_SetFlagCtrl:
	ldi		temp, flagCtrl		; de Ctrl Flag...
	rjmp	_SetFlag
_SetFlagAlt:
	ldi		temp, flagAlt		; de Alt Flag...
_SetFlag:
	sez							; ...zetten...
	rcall	WriteFlags_ASCII	; ... in ASCIIFlags
	;------------------------------------------------------/
ForgetKey:
	; Deze scancode-byte verder negeren (inslikken>null)...
	ldi		temp, 0
_Convert:
	StoreByteSRAM ASCIIKey, temp
	; Eerst naar ASCII converteren (alleen cijfers en kleine letters)
	rcall	KB_ScancodeToASCII	; scancode -> ASCII-code (na afloop temp<>0 dan toets op KeyPad gedrukt)
	tst		temp
	brne	Done_DecodeKey
	LoadByteSRAM temp, ASCIIKey
	cpi		temp, 0
	breq	Done_DecodeKey
	ldi		temp, flagShift		; is de Shift Flag gezet?...
	rcall	ReadFlags_ASCII		; ...in ASCIIFlags
	breq	_Caps
	rcall	KB_ShiftASCII		; ASCII -> ASCII shifted key
	rjmp	Done_DecodeKey
_Caps:
	ldi		temp, flagCAPSL		; is de CAPSL Flag gezet?...
	rcall	ReadFlags_ASCII		; ...in ASCIIFlags
	breq	Done_DecodeKey
	rcall	KB_CapsASCII		; ASCII -> ASCII Caps key
Done_DecodeKey:
	ret

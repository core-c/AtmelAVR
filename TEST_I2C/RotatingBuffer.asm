;---------------------------------------------------------------------------------------
;--- RotatingBuffer.asm
;--- Code by Ron Driessen, 09-mei-2003.
;---
;--- Macro's tbv. een roterende buffer
;---
;---   De buffer in SRAM moet alsvolgt aangemaakt worden:
;---   (in dit voorbeeld wordt een toetsenbord-buffer gemaakt, maar dat zou
;---    elk ander soort buffer kunnen zijn, bv. tbv UART-Rx)
;---
;---    .equ KeyBufferSize = 32           ; de gewenste grootte (bytes) van de buffer
;---    .DSEG                             ; het data-segment selecteren
;---    KeyBuffer:    .BYTE KeyBufferSize ; alloceer de toetsenbord-buffer
;---    KeyInput:     .BYTE 2             ; het adres voor de nieuw toe te voegen Key
;---    KeyOutput:    .BYTE 2             ; het adres voor de uit de buffer te lezen Key
;---    KeysInBuffer: .BYTE 1             ; Het aantal toetsen in de buffer
;---
;---   Om een byte toe te voegen aan de buffer wordt dan de volgende code gebruikt:
;---    ldi temp, 13                  ; De te schrijven byte met waarde 13
;---    StoreByteSRAMInBuffer temp, KeyBuffer, KeyInput, KeysInBuffer, KeyBufferSize
;---
;---   De code om een byte te lezen uit de buffer en in register temp te plaatsen:
;---    LoadByteSRAMFromBuffer temp, KeyBuffer, KeyOutput, KeysInBuffer, KeyBufferSize
;---
;---  Alle gebruikte registers worden bewaard op de stack, zodat voor 
;---  aanroepende programma-code men zich geen zorgen hoeft te maken
;---  voor register-waarden die veranderen.
;---  Registers mRegH & mRegL dienen voor tijdelijke (macro) bewerkingen.
;---
;---------------------------------------------------------------------------------------

;--- RotatingBuffer.asm
;.def mRegL	= R24 ; Macro Register Low
;.def mRegH	= R25 ; Macro Register High


;---------------------------------------------------------------------------------------
; load een byte uit SRAM
; uitvoer naar register '@0'
;
;	Registers aangetast: geen	(aRegister)
;
.MACRO LoadByteSRAM;(aRegister, aAddress)
	lds		@0, @1				; aRegister = aAddress^
.ENDMACRO


;-------------------------------
; load een word uit SRAM
; uitvoer naar registers '@0' & '@1' (High, Low)
;
;	Registers aangetast: geen	(aRegisterL, aRegisterH)
;
.MACRO LoadWordSRAM;(aRegisterL, aRegisterH, aAddress)
	push	ZH
	push	ZL
	ldi		ZL, low(@2)			; ZL = low(aAddress)
	ldi		ZH, high(@2)		; ZH = high(aAddress)
	ld		@0, Z+				; aRegisterL = Z^
	ld		@1, Z-				; aRegisterH = (Z+1)^
	pop		ZL
	pop		ZH
.ENDMACRO






;---------------------------------------------------------------------------------------
; store een Immediate/Constante byte-waarde in SRAM
;
;	Registers aangetast: geen
;
.MACRO StoreIByteSRAM;(aAddress, aByte)
	push	R25
	ldi		R25, @1				; R25 = aByte
	sts		@0, R25				; aAddress^ = R25
	pop		R25
.ENDMACRO


;-------------------------------
; store een byte-waarde in SRAM
;
;	Registers aangetast: geen
;
.MACRO StoreByteSRAM;(aAddress, aRegister)
	sts		@0, @1				; aAddress^ = aRegister
.ENDMACRO


;-------------------------------
; store een Immediate/Constante word-waarde in SRAM
;
;	Registers aangetast: geen
;
.MACRO StoreIWordSRAM;(aAddress, aWord)
	push	R24
	push	R25
	ldi		R24, low(@1)		; R24 = low(aWord)
	ldi		R25, high(@1)		; R25 = high(aWord)
	sts		@0, R24				; aAddress^ = R24
	sts		@0+1, R25			; (aAddress+1)^ = R25
	pop		R25
	pop		R24
.ENDMACRO


;-------------------------------
; store een word-waarde in SRAM
;
;	Registers aangetast: geen
;
.MACRO StoreWordSRAM;(aAddress, aRegisterL, aRegisterH)
	sts		@0, @1				; aAddress^ = aRegisterL
	sts		@0+1, @2			; (aAddress+1)^ = aRegisterH
.ENDMACRO







;---------------------------------------------------------------------------------------
; decrement (verlaag) een byte in SRAM
;
;	Registers aangetast: geen
;
.MACRO DecrementByteSRAM;(aAddress)
	push	R25
	lds		R25, @0				; R25 = aAddress^
	dec		R25
	sts		@0, R25				; aAddress^ = R25
	pop		R25
.ENDMACRO


;-------------------------------
; increment (verhoog) een byte in SRAM
;
;	Registers aangetast: geen
;
.MACRO IncrementByteSRAM;(aAddress)
	push	R25
	lds		R25, @0				; R25 = aAddress^
	inc		R25
	sts		@0, R25				; aAddress^ = R25
	pop		R25
.ENDMACRO







;---------------------------------------------------------------------------------------
; Bepaal of de roterende buffer leeg is
; zet!! de carry-flag als de buffer gevuld is met tenminste 1 byte.
; clear!! de carry-flag als de buffer leeg is.
;
;	Registers aangetast: geen, dus deze routine is vrij te gebruiken in een interrupt-handler.
;
.MACRO IsBufferEmpty;(aAddressBytesInBuffer)
	push	R25
	;
	lds		R25, @0				; R25 = aAddressBytesInBuffer^
	cpi		R25, 0
	clc
	breq	_41					; de buffer is leeg
	sec							; De carry-flag zetten als buffer gevuld is
_41:
	pop		R25
.ENDMACRO




;---------------------------------------------------------------------------------------
; Schrijf een byte in de roterende-buffer in SRAM.
; Als er geen plek is in de buffer, dan niets toevoegen aan de buffer
; maar de carry-flag zetten en direct de (sub-)routine beëindigen.
; Als de byte toegevoegd is, wordt de carry-flag gewist.
;
; Een AVR AT90S8535 bevat 512 bytes SRAM (9 bits).
; dus ZL:ZH is nodig om te adresseren, ZL alleen is niet voldoende.
;
;	Registers aangetast: geen, dus deze routine is vrij te gebruiken in een interrupt-handler.
;
;	Opletten! argument "aRegister" mag niet zijn: R25, ZH, ZL, XH of XL.
;
;--- geschikt voor SRAM adressen in het bereik [$0000..$FFFF]
.MACRO StoreByteSRAMIntoBuffer;(aRegister, aAddressBuffer, aAddressInput, aAddressBytesInBuffer, aBufferSize)
	push	R25
	push	ZH
	push	ZL
	push	XH
	push	XL
	;
	; bepaal of de buffer niet vol is, anders kan niet toegevoegd worden
	lds		R25, @3				; mRegH = aAddressBytesInBuffer^
	cpi		R25, @4				; mRegH ? aBufferSize
	brlo	_1					; jump naar local macro-label 1
	sec							; De carry-flag zetten als buffer al vol is
	brcs	_3

_1:
	; 'aAddressBuffer' + 'aBufferSize' in X-register
	ldi		XL, low(@1)			; XL = low(aAddressBuffer)
	ldi		XH, high(@1)		; XH = high(aAddressBuffer)
	adiw	XL, @4				; X = aAddressBuffer + aBufferSize

	; de byte in de buffer plaatsen  èn
	; de buffer-input pointer met 1 verplaatsen
	lds		ZL, @2				; ZL = aAddressInput^
	lds		ZH, @2+1			; ZH = (aAddressInput+1)^
	st		Z+, @0				; Z^ = aRegister, Z++

	; vergelijk de output-pointer met het einde van de buffer
	; Als de pointer er voorbij wijst, dan op begin van buffer plaatsen (roteren).
	cp		ZH, XH
	brlo	_2; brmi?             pointer staat zeker niet voorbij einde buffer (EOB)
	breq	_10
	brsh	_11;brpl?             pointer staat voorbij einde buffer (EOB)
_10:; ZH = XH
	cp		ZL, XL
	brlo	_2;brmi?
	; pointer staat voorbij einde buffer (EOB)
_11:; voorbij EOB
	; pointer herstellen op begin van de buffer (roteren)
	ldi		ZL, low(@1)			; low(aAddressBuffer)
	ldi		ZH, high(@1)		; low(aAddressBuffer)
_2:; (NIET voorbij EOB)
	; De buffer-output pointer terug-schrijven naar SRAM
	sts		@2, ZL				; aAddressOutput^ = Z
	sts		@2+1, ZH			; 

	; het aantal bytes in de buffer (variabele op adres 'aAddressBytesInBuffer') verhogen met 1
	lds		R25, @3				; mRegH = aAddressBytesInBuffer^
	inc		R25
	sts		@3, R25				; aAddressBytesInBuffer^ = mRegH

	clc							; De carry-flag wissen
_3:
	pop		XL
	pop		XH
	pop		ZL
	pop		ZH
	pop		R25
.ENDMACRO



;---------------------------------------------------------------------------------------
;Probeer een byte te lezen uit de buffer.
;zet de carry-flag als de operatie mislukt (bv. buffer is leeg)
; clear de carry-flag als het wel lukt.
; De gelezen byte komt als resultaat in register aRegister.
;
;	Registers aangetast: geen, dus deze routine is vrij te gebruiken in een interrupt-handler.
;
;	Opletten! argument "aRegister" mag niet zijn: R25, ZH, ZL, XH of XL.
;
;--- geschikt voor SRAM adressen in het bereik [$0000..$FFFF]
.MACRO LoadByteSRAMFromBuffer;(aRegister, aAddressBuffer, aAddressOutput, aAddressBytesInBuffer, aBufferSize)
	push	R25
	push	ZH
	push	ZL
	push	XH
	push	XL
	;
	; test of er bytes in de buffer staan om te lezen.
	; zoniet? dan de carry-flag zetten en macro beëindigen.
	lds		R25, @3				; aAddressBytesInBuffer
	cpi		R25, 0
	sec
	breq	_54					; de buffer is leeg

	; 'aAddressBuffer' + 'aBufferSize' in X-register
	ldi		XL, low(@1)			; XL = low(aAddressBuffer)
	ldi		XH, high(@1)		; XH = high(aAddressBuffer)
	adiw	XL, @4				; X = aAddressBuffer + aBufferSize

	; argument 'aAddressOutput' bevat het adres in SRAM van de te lezen byte
	; Deze byte lezen in register 'aRegister'....
	lds		ZL, @2				; low(aAddressOutput^)
	lds		ZH, @2+1			; high(aAddressOutput^)
	ld		@0, Z+				; aRegister vullen met de (byte)waarde op adres[Z],
								; en Z met 1 verhogen, zodat Z naar de volgende te lezen byte wijst.

	; vergelijk de output-pointer met het einde van de buffer
	; Als de pointer er voorbij wijst, dan op begin van buffer plaatsen (roteren).
	cp		ZH, XH
	brlo	_55; brmi?            pointer staat zeker niet voorbij einde buffer (EOB)
	breq	_57
	brsh	_56; brpl?            pointer staat voorbij einde buffer (EOB)
_57:; ZH = XH
	cp		ZL, XL
	brlo	_55; brmi?
	; pointer staat voorbij einde buffer (EOB)
_56:; voorbij EOB
	; pointer herstellen op begin van de buffer (roteren)
	ldi		ZL, low(@1)			; low(aAddressBuffer)
	ldi		ZH, high(@1)		; low(aAddressBuffer)
_55:; (NIET voorbij EOB)
	; De buffer-output pointer terug-schrijven naar SRAM
	sts		@2, ZL				; aAddressOutput^ = Z
	sts		@2+1, ZH			; 

	; het aantal bytes in de buffer (variabele op adres 'aAddressBytesInBuffer') verlagen met 1
	lds		R25, @3				; mRegH = aAddressBytesInBuffer^
	dec		R25
	brpl	_53
	ldi		R25, 0
_53:
	sts		@3, R25				; aAddressBytesInBuffer^ = mRegH
	;
	clc							; De carry-flag wissen als byte uit buffer gelezen is
_54:
	pop		XL
	pop		XH
	pop		ZL
	pop		ZH
	pop		R25
.ENDMACRO









;---------------------------------------------------------------------------------------
; store een byte in de roterende-buffer in SRAM
; Als er geen plek is in de buffer, dan niets toevoegen aan de buffer
; maar de carry-flag zetten en direct de (sub-)routine beëindigen.
; Als de byte toegevoegd is, wordt de carry-flag gewist.
;
; Een AVR AT90S8535 bevat 512 bytes SRAM (9 bits).
; dus ZL:ZH is nodig om te adresseren, ZL alleen is niet voldoende.
;
;	Registers aangetast: geen, dus deze routine is vrij te gebruiken in een interrupt-handler.
;
;	Opletten! argument "aRegister" mag niet zijn: R25, ZH of ZL.
;
;--- geschikt voor SRAM adressen in het bereik [$00..$FF]
.MACRO StoreByteSRAMIntoBuffer8;(aRegister, aAddressBuffer, aAddressInput, aAddressBytesInBuffer, aBufferSize)
	push	R25
	push	ZH
	push	ZL
	;
	; bepaal of de buffer niet vol is, anders kan niet toegevoegd worden
	lds		R25, @3				; mRegH = aAddressBytesInBuffer^
	cpi		R25, @4				; mRegH ? aBufferSize
	brlo	_1					; jump naar local macro-label 1
	sec							; De carry-flag zetten als buffer al vol is
	brcs	_3

_1:
	; de byte in de buffer plaatsen  èn
	; de buffer-input pointer met 1 verplaatsen
	lds		ZL, @2				; ZL = aAddressInput^
	lds		ZH, @2+1			; ZH = (aAddressInput+1)^
	st		Z+, @0				; aRegister

	; vergelijk de input-pointer met het einde van de buffer
	; Als de pointer er voorbij wijst, dan op begin van buffer plaatsen (roteren).
	cpi		ZL, low(@1) + @4	; ZL ? low(aAddressBuffer) + aBufferSize
	brlo	_2
	;   pointer wijst voorbij einde buffer. Op begin plaatsen om te roteren
	ldi		ZL, low(@1)			; ZL = aAddressBuffer
_2:
	; De buffer-input pointer terug-schrijven naar SRAM
	sts		@2, ZL				; aAddressInput^ = ZL

	; het aantal bytes in de buffer (variabele op adres 'aAddressBytesInBuffer') verhogen met 1
	lds		R25, @3				; mRegH = aAddressBytesInBuffer^
	inc		R25
	sts		@3, R25				; aAddressBytesInBuffer^ = mRegH

	clc							; De carry-flag wissen
_3:
	pop		ZL
	pop		ZH
	pop		R25
.ENDMACRO


;---------------------------------------------------------------------------------------
;Probeer een byte te lezen uit de buffer.
;zet de carry-flag als de operatie mislukt (bv. buffer is leeg)
; clear de carry-flag als het wel lukt.
; De gelezen byte komt als resultaat in aRegister.
;
;	Registers aangetast: geen, dus deze routine is vrij te gebruiken in een interrupt-handler.
;
;	Opletten! argument "aRegister" mag niet zijn: R25, ZH of ZL.
;
;--- geschikt voor SRAM adressen in het bereik [$00..$FF]
.MACRO LoadByteSRAMFromBuffer8;(aRegister, aAddressBuffer, aAddressOutput, aAddressBytesInBuffer, aBufferSize)
	push	R25
	push	ZH
	push	ZL
	;
	; test of er bytes in de buffer staan om te lezen.
	; zoniet? dan de carry-flag zetten en macro beëindigen.
	lds		R25, @3				; mRegH = aAddressBytesInBuffer^
	cpi		R25, 0
	sec
	breq	_54					; de buffer is leeg

	; argument 'aAddressOutput' bevat het adres in SRAM van de te lezen byte
	; Deze byte lezen in register 'aRegister'....
	lds		ZL, @2				; ZL = low(aAddressOutput^)
	lds		ZH, @2+1			; ZH = high(aAddressOutput^)
	ld		@0, Z+				; aRegister = Z^, Z met 1 verhogen zodat deze naar de volgende te lezen byte wijst.

	; vergelijk de output-pointer met het einde van de buffer
	; Als de pointer er voorbij wijst, dan op begin van buffer plaatsen (roteren).
	cpi		ZL, low(@1) + @4	; ZL ? low(aAddressBuffer) + aBufferSize
	brlo	_50
	;   pointer wijst voorbij einde buffer. Op begin plaatsen om te roteren
	ldi		ZL, low(@1)			; low(aAddressBuffer)
_50:
	; De buffer-output pointer terug-schrijven naar SRAM
	sts		@2, ZL				; aAddressOutput^ = ZL

	; het aantal bytes in de buffer (variabele op adres 'aAddressBytesInBuffer') verlagen met 1
	lds		R25, @3				; mRegH = aAddressBytesInBuffer^
	dec		R25
	brpl	_53
	ldi		R25, 0
_53:
	sts		@3, R25				; aAddressBytesInBuffer^ = mRegH
	;
	clc							; De carry-flag wissen als byte uit buffer gelezen is
_54:
	pop		ZL
	pop		ZH
	pop		R25
.ENDMACRO




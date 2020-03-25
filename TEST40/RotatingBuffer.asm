;---------------------------------------------------------------------------------------
;--- Code by Ron Driessen, May 9th 2003.
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
;---    StoreByteInBuffer temp, KeyBuffer, KeyInput, KeysInBuffer, KeyBufferSize
;---
;---   De code om een byte te lezen uit de buffer en in register temp te plaatsen:
;---    LoadByteFromBuffer temp, KeyBuffer, KeyOutput, KeysInBuffer, KeyBufferSize
;---
;---  Alle gebruikte registers worden bewaard op de stack, zodat voor 
;---  aanroepende programma-code men zich geen zorgen hoeft te maken
;---  voor register-waarden die veranderen.
;---  Registers R25 & R24 dienen voor tijdelijke (macro) bewerkingen.
;---
;---------------------------------------------------------------------------------------

; store een byte-waarde in SRAM
.MACRO StoreByte;(aAddress, aByte)
	ldi		R25, @1
	sts		@0, R25
.ENDMACRO

.MACRO StoreRegister;(aAddress, aRegister)
	sts		@0, @1
.ENDMACRO


; store een word-waarde in SRAM
.MACRO StoreWord;(aAddress, aWord)
	ldi		R24, low(@1)
	ldi		R25, high(@1)
	sts		@0, R24
	sts		@0+1, R25
.ENDMACRO


; load een byte uit SRAM
; uitvoer naar register '@0'
.MACRO LoadRegister;(aRegister, aAddress)
	lds		@0, @1
.ENDMACRO


; load een word uit SRAM
; uitvoer naar registers '@0' & '@1' (High, Low)
.MACRO LoadWord;(aRegisterL, aRegisterH, aAddress)
	ldi		ZL, low(@2)
	ldi		ZH, high(@2)
	ld		@0, Z+
	ld		@1, Z-
.ENDMACRO



; Bepaal of de roterende buffer leeg is
; clear!! de carry-flag als de buffer gevuld is met tenminste 1 byte.
; zet!! de carry-flag als de buffer leeg is.
.MACRO IsBufferEmpty;(aAddressBytesInBuffer)
;	push	R25
	;
	lds		R25, @0
	cpi		R25, 0
	breq	_41					; de buffer is leeg
	clc							; De carry-flag wissen als buffer gevuld is
	rjmp	_42
_41:
	sec
_42:
;	pop		R25
.ENDMACRO



; store een byte in de roterende-buffer in SRAM
; Als er geen plek is in de buffer, dan niets toevoegen aan de buffer
; maar de carry-flag zetten en direct de (sub-)routine beëindigen.
; Als de byte toegevoegd is, wordt de carry-flag gewist.
.MACRO StoreByteIntoBuffer;(aRegister, aAddressBuffer, aAddressInput, aAddressBytesInBuffer, aBufferSize)
;	push	R24
;	push	R25
;	push	ZH
;	push	ZL
	;
	; bepaal of de buffer niet vol is, anders kan niet toegevoegd worden
	lds		R25, @3
	cpi		R25, @4
	brlo	_1					; jump naar local label 1
	sec							; De carry-flag zetten als buffer al vol is
	brcs	_3

_1:
	; de byte in de buffer plaatsen  èn
	; de buffer-input pointer met 1 verplaatsen
	lds		ZL, @2
	lds		ZH, @2+1
	st		Z+, @0

	; vergelijk de input-pointer met het einde van de buffer
	; Als de pointer er voorbij wijst, dan op begin van buffer plaatsen (roteren).
	cpi		ZL, low(@1) + @4
	brlo	_2
;#	; controleer de high-byte van het adres
;#	cpi		ZH, high(@1)
;#	brlo	xx
	;   pointer wijst voorbij einde buffer. Op begin plaatsen om te roteren
	ldi		ZL, low(@1)
;>	ldi		ZH, high(@1)		; altijd =0.  vanwege tijdwinst eruit gehaald....
_2:
	; De buffer-input pointer terug-schrijven naar SRAM
	sts		@2, ZL
;>	sts		@2+1, ZH			; altijd =0

	; het aantal bytes in de buffer (variabele op adres 'aAddressBytesInBuffer') verhogen met 1
	lds		R25, @3
	inc		R25
	sts		@3, R25

	clc							; De carry-flag wissen
_3:
;	pop		ZL
;	pop		ZH
;	pop		R25
;	pop		R24
.ENDMACRO




;Probeer een byte te lezen uit de buffer.
;zet de carry-flag als de operatie mislukt (bv. buffer is leeg)
; clear de carry-flag als het wel lukt.
; De gelezen byte komt als resultaat in aRegister.
.MACRO LoadByteFromBuffer;(aRegister, aAddressBuffer, aAddressOutput, aAddressBytesInBuffer, aBufferSize)
;	push	ZH
;	push	ZL
;	push	R25
	;
	; test of er bytes in de buffer staan om te lezen.
	; zoniet? dan de carry-flag zetten en macro beëindigen.
	lds		R25, @3
	cpi		R25, 0
	sec
	breq	_54					; de buffer is leeg

	; argument 'aAddressOutput' bevat het adres in SRAM van de te lezen byte
	; Deze byte lezen in register 'aRegister'....
	lds		ZL, @2
	lds		ZH, @2+1
	ld		@0, Z+				; Z met 1 verhogen, zodat deze naar de volgende te lezen byte wijst.

	; vergelijk de output-pointer met het einde van de buffer
	; Als de pointer er voorbij wijst, dan op begin van buffer plaatsen (roteren).
	cpi		ZL, low(@1) + @4
	brlo	_50
	;   pointer wijst voorbij einde buffer. Op begin plaatsen om te roteren
	ldi		ZL, low(@1)
;>	ldi		ZH, high(@1)		; altijd =0
_50:
	; De buffer-output pointer terug-schrijven naar SRAM
	sts		@2, ZL
;>	sts		@2+1, ZH			; altijd =0

	; het aantal bytes in de buffer (variabele op adres 'aAddressBytesInBuffer') verlagen met 1
	lds		R25, @3
	dec		R25
	brpl	_53
	ldi		R25, 0
_53:
	sts		@3, R25
	;
	clc							; De carry-flag wissen als byte uit buffer gelezen is
_54:
;	pop		R25
;	pop		ZL
;	pop		ZH
.ENDMACRO




.equ RS232BufferSize	= 16			; Buffer van 0x0060-0x0070 in SRAM (!!niet voorbij 256-byte boundry!!)
;--- Het begin van het DATA-segment ----
.DSEG
.org 0x0060								; De 1e byte van de buffer op begin van SRAM plaatsen
RS232Buffer:	.BYTE RS232BufferSize	; alloceer de RS232 data-buffer
RS232Input:		.BYTE 2					; het adres voor de nieuw toe te voegen byte
RS232Output:	.BYTE 2					; het adres voor de uit de buffer te lezen byte
BytesInBuffer:	.BYTE 1					; Het aantal bytes in de buffer

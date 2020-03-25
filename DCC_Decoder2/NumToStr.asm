;---------------------------------------
;--- Een Hex-Nibble afbeelden
;---	input:	R16 bits 3-0 = nibble
;--------------------------------------\
HexNibble:
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
	; het teken afbeelden op COM:
	rcall	UART_transmit
	pop		R17
	ret
;--------------------------------------/


;---------------------------------------
;--- Een Hex-Byte afbeelden
;---	input:	R16 b7-3, b3-0 = byte
;--------------------------------------\
HexByte:
	push	R16
	swap	R16
	rcall	HexNibble
	pop		R16
	rcall	HexNibble
	ret
;--------------------------------------/


;---------------------------------------
;--- Een Hex-Word afbeelden
;---	input:	waarde in Z = word-waarde
;--------------------------------------\
HexWord:
	push	R16
	mov		R16, ZH
	rcall	HexByte
	mov		R16, ZL
	rcall	HexByte
	pop		R16
	ret
;--------------------------------------/


;---------------------------------------
;--- Een waarde hexadecimaal afbeelden.
;--- input: Z=word waarde
; waarden kleiner dan $10 worden als een nibble afgebeeld, anders
; waarden kleiner dan $100 worden als een byte afgebeeld, anders
; waarden tot $FFFF worden als een word afgebeeld.
;--------------------------------------\
Hex:
	push	R16
	; Z<$100?
	cpi		ZH, 0
	brne	hWord
	; Z<$10?
	cpi		ZL, $10
	brlo	hNibble
	; als een byte afbeelden..
	mov		R16, ZL
	rcall	HexByte
	rjmp	Done_Hex
hWord:
	; als een word afbeelden..
	rcall	HexWord
	rjmp	Done_Hex
hNibble:
	mov		R16, ZL
	rcall	HexNibble
Done_Hex:
	pop		R16
	ret
;--------------------------------------/

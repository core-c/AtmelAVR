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


;---------------------------------------
;--- Een waarde decimaal afbeelden.
;--- input: Z=word waarde
; Geen leading-0's bij decimaal afbeelden..
;--------------------------------------\
Decimal:
	push	R16
	push	YL
	push	YH
	push	ZL
	push	ZH
	push	R2
	clr		R2							; indicator leading-0's
	; Met een 16-bit word nooit meer dan 5 cijfers dec.
	; Z / 10000
	ldi		YL, low(10000)
	ldi		YH, high(10000)
	rcall	Divide_16u_16u				; Y := Z / 10000, rest in Z
	rcall	Display_Digit
	; Z / 1000
	ldi		YL, low(1000)
	ldi		YH, high(1000)
	rcall	Divide_16u_16u				; Y := Z / 1000, rest in Z
	rcall	Display_Digit
	; Z / 100
	ldi		YL, low(100)
	ldi		YH, high(100)
	rcall	Divide_16u_16u				; Y := Z / 100, rest in Z
	rcall	Display_Digit
	; Z / 10
	ldi		YL, low(10)
	ldi		YH, high(10)
	rcall	Divide_16u_16u				; Y := Z / 10, rest in Z
	rcall	Display_Digit
	; Z is nu < 10..
	mov		R16, ZL
	rcall	HexNibble					; 5e cijfer afbeelden
	pop		R2
	pop		ZH
	pop		ZL
	pop		YH
	pop		YL
	pop		R16
	ret
;---------------------------------------
Display_Digit:
	push	R16
	tst		R2							; test op leading-0's...
	brne	Digit_out					; ..niet meer nodig
	cpi		YL, 0
	brne	Digit_out					; YL<>0 dus vanaf nu zijn nullen (0) niet meer leading..
	rjmp	Done_Display_Digit			; geen leading-0 afdrukken
Digit_out:
	ser		R16							;
	mov		R2, R16						; leading-0 vlag zetten
	mov		R16, YL
	rcall	HexNibble					; 1e cijfer afbeelden
Done_Display_Digit:
	pop		R16
	ret
;---------------------------------------
;--- Delen 16b unsigned / 16b unsigned
;--- input: Z-register = getal
;---        Y-register = deler
;--- output: resultaat in Y, rest in Z
;--------------------------------------\
Divide_16u_16u:
	push	XL							; tijdelijk resultaat
	push	XH
	clr		XL
	clr		XH
Deel:
	; Z < Y ?
	cp		ZL, YL
	cpc		ZH, YH
	brlo	Te_Klein
	; Z := Z - Y
	sub		ZL, YL
	sbc		ZH, YH
	adiw	XL, 1						; resultaat bijwerken..
	rjmp	Deel
Te_Klein:
	; de rest staat nu al in Z..
	; resultaat naar Y overnemen
	mov		YL, XL
	mov		YH, XH
	pop		XH
	pop		XL
	ret
;--------------------------------------/

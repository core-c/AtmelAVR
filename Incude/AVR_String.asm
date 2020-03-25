;---------------------------------------------------------------------------------
;---
;---  Timer constanten en macro's						Ron Driessen
;---  AVR AT90S8535										2005
;---
;---------------------------------------------------------------------------------
.ifndef Linked_AVR_String
	.ifndef Link_AVR_String						; Deze unit markeren als zijnde ingelinkt,
		.equ Link_AVR_String = 1				; in geval dat nog niet eerder is gebeurd in code.
	.endif										; (Units nl. maar 1x inlinken)
	.equ Linked_AVR_String = 1					;
.endif
;; de UART-unit inlinken als dat nog niet is gebeurd..
;.ifndef Linked_8535_UART
;	.ifndef Link_8535_UART
;		.equ Link_8535_UART = 1
;	.endif
;	.equ Linked_8535_UART = 1
;	.include "8535_UART.asm"					; De UART RS232 COM:poort
;.endif
;; de LCD-unit inlinken als dat nog niet is gebeurd..
;.ifndef Linked_LCD_HD44780
;	.ifndef Link_LCD_HD44780
;		.equ Link_LCD_HD44780 = 1
;	.endif
;	.equ Linked_LCD_HD44780 = 1
;	.include "LCD_HD44780.asm"					; De LCD
;.endif






;---------------------------------------
.DSEG									; Data Segment (SRAM) addresseren
	StringOutput:	.BYTE 1				; uitvoer naar COM: en/of LCD
										;	bits 7 = (1=afbeelden op COM:), (0=niet afbeelden op COM:)
										;	bits 6 = (1=afbeelden op LCD), (0=niet afbeelden op LCD)
.CSEG
;---------------------------------------


;--- uitvoer toestaan
.MACRO StringOutputTo_COM
	lds		R16, StringOutput
	ori		R16, 0b10000000
	sts		StringOutput, R16
.ENDMACRO

.MACRO StringOutputTo_LCD
	lds		R16, StringOutput
	ori		R16, 0b01000000
	sts		StringOutput, R16
.ENDMACRO

.MACRO StringOutputTo_COM_LCD
	lds		R16, StringOutput
	ori		R16, 0b11000000
	sts		StringOutput, R16
.ENDMACRO


;--- uitvoer alleen toestaan naar
.MACRO StringOutputOnlyTo_COM
	ldi		R16, 0b10000000
	sts		StringOutput, R16
.ENDMACRO

.MACRO StringOutputOnlyTo_LCD
	ldi		R16, 0b01000000
	sts		StringOutput, R16
.ENDMACRO

.MACRO StringOutputOnlyTo_COM_LCD
	ldi		R16, 0b11000000
	sts		StringOutput, R16
.ENDMACRO


;--- uitvoer tegengaan
.MACRO StringNoOutputTo_COM
	lds		R16, StringOutput
	andi	R16, ~0b10000000
	sts		StringOutput, R16
.ENDMACRO

.MACRO StringNoOutputTo_LCD
	lds		R16, StringOutput
	andi	R16, ~0b01000000
	sts		StringOutput, R16
.ENDMACRO

.MACRO StringNoOutputTo_COM_LCD
	lds		R16, StringOutput
	andi	R16, ~0b11000000
	sts		StringOutput, R16
.ENDMACRO








;---------------------------------------
;--- Een Hex-Nibble afbeelden
;---	input:	R16 bits 3-0 = nibble waarde
;---	output:	R16 [evt. op COM: en/of LCD indien units ingelinkt en betreffende bit gezet in StringOutput]
;--------------------------------------\
HexNibble:
	push	R17
	push	R18
	andi	R16, $0F					; bits 7-4 op 0 zetten
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

.ifdef Linked_LCD_HD44780
	; het teken afbeelden op LCD
	lds		R18, StringOutput
	sbrc	R18, 6
	rcall	LCD_LinePrintChar ;LCD_WriteData
.endif

.ifdef Linked_8535_UART
	; het teken afbeelden op COM:
	lds		R18, StringOutput
	sbrc	R18, 7
	rcall	UART_Transmit
.endif

	pop		R18
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
	push	R2
	clr		R2							; indicator leading-0's
	; Met een 16-bit word nooit meer dan 5 cijfers dec.
	; Z / 10000
	ldi		YL, low(10000)				; Y := 10000
	ldi		YH, high(10000)				;
	rcall	Divide_16u_16u				; Y := Z/Y, rest in Z
	rcall	Display_Digit				; Y waarde afbeelden
	; Z / 1000
	ldi		YL, low(1000)				; Y := 1000
	ldi		YH, high(1000)				;
	rcall	Divide_16u_16u				; Y := Z/Y, rest in Z
	rcall	Display_Digit				; Y waarde afbeelden
	; Z / 100
	ldi		YL, low(100)				; Y := 100
	ldi		YH, high(100)				;
	rcall	Divide_16u_16u				; Y := Z/Y, rest in Z
	rcall	Display_Digit				; Y waarde afbeelden
	; Z / 10
	ldi		YL, low(10)					; Y := 10
	ldi		YH, high(10)				;
	rcall	Divide_16u_16u				; Y := Z/Y, rest in Z
	rcall	Display_Digit				; Y waarde afbeelden
	; Z is nu < 10..
	mov		R16, ZL						; Z waarde afbeelden
	rcall	HexNibble					; een nibble (4bits) volstaat
	pop		R2
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
	ser		R16							; leading-0 vlag zetten..
	mov		R2, R16						; ..
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
Deel:	; Z < Y ?
	cp		ZL, YL
	cpc		ZH, YH
	brlo	Gedeeld
	; Z := Z - Y
	sub		ZL, YL
	sbc		ZH, YH
	; X := X + 1
	adiw	XL, 1						; resultaat bijwerken..
	rjmp	Deel
Gedeeld:
	; de rest staat nu al in Z..
	; resultaat naar Y overnemen
	mov		YL, XL
	mov		YH, XH
	pop		XH
	pop		XL
	ret
;--------------------------------------/

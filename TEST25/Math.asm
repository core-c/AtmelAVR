
;---------------------------
;--- Z_ZLx10
;---	Vermenigvuldig het getal in register ZL met 10
;---	Het resultaat komt in register Z (ZH:ZL)
;---	Het getal in ZL is in het bereik90..255]
;---------------------------
.MACRO Z_ZLx10
	push	XL
	push	XH
	mov		XL, ZL
	clr		ZH
	clr		XH
	lsl		ZL				; Z := ZL*8
	rol		ZH
	lsl		ZL
	rol		ZH
	lsl		ZL
	rol		ZH
	lsl		XL				; X := ZL*2
	rol		XH
	clc						; Z := Z+X
	add		ZL, XL
	brcc	_1
	inc		ZH
_1:
	add		ZH, XH
	pop		XH
	pop		XL
.ENDMACRO



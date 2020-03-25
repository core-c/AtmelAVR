;---------------------------------------------------------------------------------
;---
;---  Buffer constanten en macro's						Ron Driessen
;---  AVR												2005
;---
;---------------------------------------------------------------------------------
.ifndef Linked_AVR_Buffer
	.ifndef Link_AVR_Buffer						; Deze unit markeren als zijnde ingelinkt,
		.equ Link_AVR_Buffer = 1				; in geval dat nog niet eerder is gebeurd in code.
	.endif										; (Units nl. maar 1x inlinken)
	.equ Linked_AVR_Buffer = 1					;
.endif






;;---------------------------------------------------------------------------------
;;--- Een (FIFO-)buffer reserveren in het SRAM geheugen.
;;---------------------------------------------------------------------------------
;.equ TheBufferSize = 32
;.DSEG											; Data Segment (SRAM) addresseren
;	BufferSize:		.BYTE 2						; Een pointer naar het einde van de buffer (NIET nodig bij gebruik van alleen Buffer_Push2 & Buffer_Pop2)
;	BufferCount: 	.BYTE 1						; Het aantal bytes in de buffer
;	BufferPtrR:		.BYTE 2						; De pointer bij lezen uit de buffer (H:L)
;	BufferPtrW:		.BYTE 2						; De pointer bij schrijven in de buffer (H:L)
;	Buffer: 		.BYTE TheBufferSize			; de buffer vanaf adres "Buffer", met een grootte van "BufferSize" bytes
;.CSEG											; Code Segment (FLASH/PM) addresseren
;---------------------------------------------------------------------------------


;--------------------------------------------
;--- Naam:			Buffer_Initialize
;--- Beschrijving:	De buffer initialiseren voor gebruik
;--------------------------------------------
.MACRO Buffer_Initialize;(Buffer:Label; Size:8b-constante)
	; Buffergrootte ook in SRAM bewaren
	ldi		R16, @1
	sts		@0-6, R16
	; BufferCount op 0
	clr		R16
	sts		@0-5, R16
	; BufferPtrR op Buffer
	ldi		ZH, high(@0)
	ldi		ZL, low(@0)
	sts		@0-4, ZH
	sts		@0-3, ZL
	; BufferPtrW op Buffer
	sts		@0-2, ZH
	sts		@0-1, ZL
.ENDMACRO


;--------------------------------------------
;--- Naam:			Buffer_IsEmpty
;--- Beschrijving:	Test of de buffer leeg/gevuld is
;--- uitvoer:		carry-flag gezet en zero-flag gezet = buffer is leeg
;---				carry-flag gewist en zero-flag gewist = buffer is gevuld
;--------------------------------------------
.MACRO Buffer_IsEmpty;(Buffer:Label)
	; is de buffer gevuld met tenminste 1 byte?
	; Lees "BufferCount" in R16
	lds		R16, @1-5
	cpi		R16, 0
	brne	_1
	; de buffer is leeg
	sec											; klaar, buffer is leeg
	rjmp	_0
_1:	clc											; klaar, buffer is gevuld
_0:	
.ENDMACRO


;--------------------------------------------
;--- Naam:			Buffer_Peek
;--- Beschrijving:	Lees een byte in de buffer,
;---				zonder de buffer-inhoud te veranderen
;--- uitvoer:		carry-flag gezet = buffer is leeg, @0 is ongedefinieerd
;---				carry-flag gewist = gelezen byte in @0
;--------------------------------------------
.MACRO Buffer_Peek;(Value:register; Buffer:Label)
	; is de buffer gevuld met tenminste 1 byte?
	; Lees "BufferCount" in R16
	lds		R16, @1-5
	cpi		R16, 0
	brne	_1
	; de buffer is leeg
	sec											; klaar, met fout
	rjmp	_0
_1:	; byte uit buffer lezen vanaf adres [BufferPtrR]
	ldi		ZL, low(@1-4)
	ldi		ZH, high(@1-4)
	ld		@0, Z
	clc											; klaar, zonder fouten
_0:	
.ENDMACRO


;--------------------------------------------
;--- Naam:			Buffer_Write
;--- Beschrijving:	Schrijf een byte in de buffer
;--- invoer:		"Buffer" is het label/adres wat het beginadres van de buffer bevat
;---				"Value" is een register dat de waarde bevat om op te slaan in de buffer
;--- uitvoer:		carry-flag gezet = buffer is al vol, de byte is niet geschreven
;---				carry-flag gewist = byte is naar de buffer geschreven
;--------------------------------------------
.MACRO Buffer_Write;(Buffer:Label; Value: register)
	push	@1
	; is er nog plek in de buffer?
	lds		R17, @0-6							; Lees "BufferSize" in R17
	lds		R16, @0-5							; Lees "BufferCount" in R16
	cp		R16, R17
	brlo	_1
	; de buffer is al vol
	pop		@1
	sec											; klaar, met fout
	rjmp	_0
_1:	; "aantal bytes in buffer" teller ophogen
	inc		R16
	sts		@0-5, R16
	; byte in buffer plaatsen op adres [BufferPtrW]
	lds		ZH, @0-2
	lds		ZL, @0-1
	pop		@1
	st		Z+, @1								; pointer "BufferPtrW" ophogen
	; pointer "BufferPtrW" valideren
	ldi		XL, low(@0)
	ldi		XH, high(@0)
	clr		R16
	add		XL, R17
	adc		XH, R16
	cp		ZL, XL
	cpc		ZH, XH
	brlo	_2
	; pointer "BufferPtrW" corrigeren
	ldi		ZH, high(@0)
	ldi		ZL, low(@0)
_2:	; pointer "BufferPtrW" terugschrijven
	sts		@0-2, ZH
	sts		@0-1, ZL
	clc											; klaar, zonder fouten
_0:	
.ENDMACRO

;--------------------------------------------
;--- Naam:			Buffer_Read
;--- Beschrijving:	Lees een byte uit de buffer
;--- invoer:		"Buffer" is het label/adres wat het beginadres van de buffer bevat
;---				"Value" is een register dat de waarde bevat van de uit de buffer te lezen byte
;--- uitvoer:		carry-flag gezet = buffer is leeg, @0 is ongedefinieerd
;---				carry-flag gewist = gelezen byte in @0
;--------------------------------------------
.MACRO Buffer_Read;(Value:register; Buffer:Label)
	; is de buffer gevuld met tenminste 1 byte?
	lds		R16, @1-5							; Lees "BufferCount" in R16
	cpi		R16, 0
	brne	_1
	; de buffer is leeg
	sec											; klaar, met fout
	rjmp	_0
_1:	; "aantal bytes in buffer" teller verlagen
	dec		R16
	sts		@1-5, R16
	; byte uit buffer lezen vanaf adres [BufferPtrR]
	lds		ZH, @1-4
	lds		ZL, @1-3
	ld		@0, Z+								; pointer "BufferPtrR" ophogen
	push	@0									;! in geval @0 == R16
	; pointer "BufferPtrR" valideren
	ldi		XL, low(@1)							; X := begin buffer
	ldi		XH, high(@1)
	lds		R17, @1-6							; Lees "BufferSize" in R17
	clr		R16
	add		XL, R17								; X := X + "BufferSize"
	adc		XH, R16
	cp		ZL, XL
	cpc		ZH, XH
	brlo	_2
	; pointer "BufferPtrR" corrigeren
	ldi		ZH, high(@1)
	ldi		ZL, low(@1)
_2:	; pointer "BufferPtrR" terugschrijven
	sts		@1-4, ZH
	sts		@1-3, ZL
	pop		@0									;!
	clc											; klaar, zonder fouten
_0:	
.ENDMACRO


;--------------------------------------------
;--- Naam:			Buffer_Write2
;--- Beschrijving:	Schrijf een byte in de buffer
;--- invoer:		"Buffer" is het label/adres wat het beginadres van de buffer bevat
;---				"Value" is een register dat de waarde bevat om op te slaan in de buffer
;---				"BufferSize" is een 8-bit constante die de grootte van de buffer bevat
;--- uitvoer:		carry-flag gezet = buffer is al vol, de byte is niet geschreven
;---				carry-flag gewist = byte is naar de buffer geschreven
;--------------------------------------------
.MACRO Buffer_Write2;(Buffer:Label; Value: register; BufferSize:8b-constante)
	push	@1
	; is er nog plek in de buffer?
	lds		R16, @0-5							; Lees "BufferCount" in R16
	cpi		R16, @2
	brlo	_1
	; de buffer is al vol
	pop		@1
	sec											; klaar, met fout
	rjmp	_0
_1:	; "aantal bytes in buffer" teller ophogen
	inc		R16
	sts		@0-5, R16
	; byte in buffer plaatsen op adres [BufferPtrW]
	lds		ZH, @0-2
	lds		ZL, @0-1
	pop		@1
	st		Z+, @1								; pointer "BufferPtrW" ophogen
	; pointer "BufferPtrW" valideren
	cpi		ZL, low(@0+@2)
	ldi		R16, high(@0+@2)
	cpc		ZH, R16
	brlo	_2
	; pointer "BufferPtrW" corrigeren
	ldi		ZH, high(@0)
	ldi		ZL, low(@0)
_2:	; pointer "BufferPtrW" terugschrijven
	sts		@0-2, ZH
	sts		@0-1, ZL
	clc											; klaar, zonder fouten
_0:	
.ENDMACRO

;--------------------------------------------
;--- Naam:			Buffer_Read2
;--- Beschrijving:	Lees een byte uit de buffer
;--- invoer:		"Buffer" is het label/adres wat het beginadres van de buffer bevat
;---				"Value" is een register dat de waarde bevat van de uit de buffer te lezen byte
;---				"BufferSize" is een 8-bit constante die de grootte van de buffer bevat
;--- uitvoer:		carry-flag gezet = buffer is leeg, @0 is ongedefinieerd
;---				carry-flag gewist = gelezen byte in @0
;--------------------------------------------
.MACRO Buffer_Read2;(Value:register; Buffer:Label; BufferSize:8b-constante)
	; is de buffer gevuld met tenminste 1 byte?
	lds		R16, @1-5							; Lees "BufferCount" in R16
	cpi		R16, 0
	brne	_1
	; de buffer is leeg
	sec											; klaar, met fout
	rjmp	_0
_1:	; "aantal bytes in buffer" teller verlagen
	dec		R16
	sts		@1-5, R16
	; byte uit buffer lezen vanaf adres [BufferPtrR]
	lds		ZH, @1-4
	lds		ZL, @1-3
	ld		@0, Z+								; pointer "BufferPtrR" ophogen
	push	@0									;! in geval @0 == R16
	; pointer "BufferPtrR" valideren
	cpi		ZL, low(@1+@2)
	ldi		R16, high(@1+@2)
	cpc		ZH, R16
	brlo	_2
	; pointer "BufferPtrR" corrigeren
	ldi		ZH, high(@1)
	ldi		ZL, low(@1)
_2:	; pointer "BufferPtrR" terugschrijven
	sts		@1-4, ZH
	sts		@1-3, ZL
	pop		@0									;!
	clc											; klaar, zonder fouten
_0:	
.ENDMACRO





;;---------------------------------------------------------------------------------
;;--- Een (LIFO-)buffer reserveren in het SRAM geheugen.
;;---------------------------------------------------------------------------------
;.equ TheStackSize = 16
;.DSEG											; Data Segment (SRAM) addresseren
;	StackPtr:		.BYTE 2						; De pointer bij lezen/schrijven in de buffer (H:L)
;	Stack:	 		.BYTE TheStackSize			; de buffer vanaf adres "Stack", met een grootte van "TheStackSize" bytes
;.CSEG											; Code Segment (FLASH/PM) addresseren
;---------------------------------------------------------------------------------

.MACRO LIFO_Initialize;(Buffer:Label)
	; StackPtr op begin Buffer
	ldi		ZH, high(@0)
	ldi		ZL, low(@0)
	sts		@0-2, ZH
	sts		@0-1, ZL
.ENDMACRO

.MACRO LIFO_Push;(Buffer:Label; Value: register; BufferSize:8b-constante)
	push	@1
	; past de byte nog in de buffer?
	lds		ZH, @0-2							; "StackPtr" opvragen in Z
	lds		ZL, @0-1
	; pointer "StackPtr" al op einde-buffer?
	cpi		ZL, low(@0+@2)
	ldi		R16, high(@0+@2)
	cpc		ZH, R16
	brlo	_2
	; de buffer zit al vol
	pop		@1
	sec											; klaar, met fout
	rjmp	_0
_2:	; de byte schrijven in de buffer
	pop		@1
	st		Z+, @1
	; pointer "StackPtr" terugschrijven
	sts		@0-2, ZH
	sts		@0-1, ZL
	clc											; klaar, zonder fouten
_0:	
.ENDMACRO

.MACRO LIFO_Pop;(Value:register; Buffer:Label)
	; is de buffer wel gevuld met tenminste 1 byte?
	lds		ZH, @1-2							; "StackPtr" opvragen in Z
	lds		ZL, @1-1
	; pointer "StackPtr" op begin-buffer?
	cpi		ZL, low(@1)
	ldi		R16, high(@1)
	cpc		ZH, R16
	brne	_2
	; de buffer is leeg
	sec											; klaar, met fout
	rjmp	_0
_2:	; de byte lezen uit de buffer
	ld		@0, -Z								; Z-- , daarna pas lezen uit buffer
	; pointer "StackPtr" terugschrijven
	sts		@1-2, ZH
	sts		@1-1, ZL
	clc											; klaar, zonder fouten
_0:
.ENDMACRO

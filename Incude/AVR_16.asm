;---------------------------------------------------------------------------------
;---
;---  16-bit Bewerkingen / macro's						Ron Driessen
;---  AVR												2005
;---
;---------------------------------------------------------------------------------
.ifndef Linked_AVR_16
	.ifndef Link_AVR_16							; Deze unit markeren als zijnde ingelinkt,
		.equ Link_AVR_16 = 1					; in geval dat nog niet eerder is gebeurd in code.
	.endif										; (Units nl. maar 1x inlinken)
	.equ Linked_AVR_16 = 1						;
.endif





;----------------------------------------------------------------------------------------
;---
;--- 2 16-bit getallen optellen (via 2 paren registers)
;---
.MACRO add16;(Value1H,Value1L, Value2H,Value2L: register)
	add		@1, @3						; low-bytes optellen
	adc		@0, @2						; high-bytes optellen met carry
.ENDMACRO

;---
;--- 2 16-bit getallen optellen (via 1 paar registers en een 16-bit constante)
;---
.MACRO addi16;(Value1H,Value1L: register; Value2: 16b-constante)
	subi	@1, low(-@2)				; low-bytes optellen; x-(-y)=x+y
	sbci	@0, high(-@2)				; high-bytes optellen met carry
.ENDMACRO



;----------------------------------------------------------------------------------------
;---
;--- 2 16-bit getallen van elkaar aftrekken (via 2 paren registers)
;---
.MACRO sub16;(Value1H,Value1L, Value2H,Value2L: register)
	sub		@1, @3						; low-bytes aftrekken
	sbc		@0, @2						; high-bytes aftrekken met carry
.ENDMACRO

;---
;--- 2 16-bit getallen van elkaar aftrekken (via 1 paar registers en een 16-bit constante)
;---
.MACRO subi16;(Value1H,Value1L: register; Value2: 16b-constante)
	subi	@1, low(@2)					; low-bytes aftrekken
	sbci	@0, high(@2)				; high-bytes aftrekken met carry
.ENDMACRO



;----------------------------------------------------------------------------------------
;---
;--- 2 16-bit getallen vergelijken (via 2 paren registers)
;---
.MACRO cp16;(Value1H,Value1L, Value2H,Value2L: register)
	cp		@1, @3						; low-bytes vergelijken
	cpc		@0, @2						; high-bytes vergelijken met carry
.ENDMACRO

;---
;--- 2 16-bit getallen vergelijken (via 1 paar registers en een 16-bit constante)
;---
.MACRO cpi16;(Value1H,Value1L: register; Value2: 16b-constante)
	cpi		@1, low(@2)					; low-bytes vergelijken
	ldi		R16, high(@2)				; high-bytes vergelijken met carry
	cpc		@0, R16						;
.ENDMACRO



;----------------------------------------------------------------------------------------
;---
;--- Een 16-bit getal van een poort lezen (via 1 paar registers en een poortadres)
;---
.MACRO in16;(ValueH,ValueL: register; PortAddress:Port)
	in		@1, @2-1					; low-byte lezen
	in		@0, @2						; high-byte lezen
.ENDMACRO

;---
;--- Een 16-bit getal naar een poort schrijven (via een poortadres en 1 paar registers)
;---
.MACRO out16;(PortAddress:Port; ValueH,ValueL: register)
	out		@0, @1						; high-byte schrijven
	out		@0-1, @2					; low-byte schrijven
.ENDMACRO

;---
;--- Een 16-bit getal naar een poort schrijven (via een poortadres en een 16-bit constante)
;---
.MACRO outi16;(PortAddress:Port; Value: 16b-constante)
	out		@0, high(@1)				; high-byte schrijven
	out		@0-1, low(@1)				; low-byte schrijven
.ENDMACRO

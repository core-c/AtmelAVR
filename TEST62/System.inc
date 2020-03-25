
;--- I/O-Poorten instellen -----
.equ PIN_AS_INPUT		= 0		; Een pin als input instellen
.equ PIN_AS_OUTPUT		= 1		; Een pin als output instellen
.equ PORT_AS_INPUT		= $00	; Een poort als input instellen
.equ PORT_AS_OUTPUT		= $FF	; Een poort als output instellen
.equ INPUT_PORT_TRIS	= $00	; Een input-poort's tristate instellen
.equ INPUT_PORT_PULL	= $FF	; Een input-poort's pull-up weerstanden inschakelen


; De stack-pointer instellen op het einde van het RAM
.MACRO initStackPointer
	ldi		R16, high(RAMEND)
	ldi		R17, low(RAMEND)
	out		SPH, R16
	out		SPL, R17
.ENDMACRO


; Een waarde toekennen aan een 32-bit getal (zonder teken)
;		.DSEG				;Het SRAM aanspreken
;		LongJohn: .BYTE 4	;Een 32-bit getal definiren
.MACRO SetVar32b;(Address, Value)
	ldi		ZL, low(@0)
	ldi		ZH, high(@0)
	ldi		R16, low(@1)
	st		Z+, R16
	ldi		R16, high(@1)
	st		Z+, R16
	ldi		R16, byte3(@1)
	st		Z+, R16
	ldi		R16, byte4(@1)
	st		Z+, R16
.ENDMACRO

; Een waarde opvragen van een 32-bit getal (zonder teken)
; output: registers Y:X bevatten de gelezen 32b Integer
.MACRO GetVar32b;(Address)
	ldi		ZL, low(@0)
	ldi		ZH, high(@0)
	ld		XL, Z+
	ld		XH, Z+
	ld		YL, Z+
	ldi		YH, Z+
.ENDMACRO

; Een 16-bit waarde in "Register" optellen
; bij een 32-bit getal (zonder teken)
.MACRO Add16bToVar32b;(Address, RegisterL, RegisterH)
	ldi		ZL, low(@0)
	ldi		ZH, high(@0)
	clc							;
	ld		R16, Z
	add		R16, @1
	st		Z+, R16
	ld		R16, Z				;
	adc		R16, @2
	st		Z+, R16
	ldi		R17, 0				;
	ld		R16, Z
	adc		R16, R17
	st		Z+, R16
	ld		R16, Z				;
	adc		R16, R17
	st		Z+, R16
.ENDMACRO


; Een 16-bit waarde in "Register" optellen
; bij een 16-bit getal (zonder teken)
.MACRO Add16bToVar16b;(Address, RegisterL, RegisterH)
	ldi		ZL, low(@0)
	ldi		ZH, high(@0)
	clc							;
	ld		R16, Z
	add		R16, @1
	st		Z+, R16
	ld		R16, Z				;
	adc		R16, @2
	st		Z+, R16
.ENDMACRO









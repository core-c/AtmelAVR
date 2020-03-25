
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










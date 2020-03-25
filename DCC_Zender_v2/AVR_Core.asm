;---------------------------------------------------------------------------------
;---
;---  Core Bewerkingen / macro's						Ron Driessen
;---  AVR												2005
;---
;---------------------------------------------------------------------------------
.ifndef Linked_AVR_Core
	.ifndef Link_AVR_Core						; Deze unit markeren als zijnde ingelinkt,
		.equ Link_AVR_Core = 1					; in geval dat nog niet eerder is gebeurd in code.
	.endif										; (Units nl. maar 1x inlinken)
	.equ Linked_AVR_Core = 1						;
.endif





;----------------------------------------------------------------------------------------
;---	DDR		PORT	omschrijving
;---	 0		 0		INPUT	TRI-STATE
;---	 0		 1		INPUT	PULL-UP (intern)
;---	 1		 0		OUTPUT	0
;---	 1		 1		OUTPUT	1
;---
.equ AVR_INPUT		= 0
.equ AVR_OUTPUT		= 1
.equ AVR_TRISTATE	= 0
.equ AVR_PULLUP		= 1




;----------------------------------------------------------------------------------------
;---
;--- De stack-pointer instellen op het einde van het RAM
;---
.MACRO StackPointer_Initialize
	ldi		R17, high(RAMEND)
	ldi		R16, low(RAMEND)
	out		SPH, R17
	out		SPL, R16
.ENDMACRO



;----------------------------------------------------------------------------------------
;---
;--- Een poort als OUTPUT instellen
;---
.MACRO PORT_Set_OUTPUT;(AVRport:PORT)
	ser		R16										; DDR instellen
	.if @0 == PORTA
		out		DDRA, R16
	.else
		.if @0 == PORTB
			out		DDRB, R16
		.else
			.if @0 == PORTC
				out		DDRC, R16
			.else
				.if @0 == PORTD
					out		DDRD, R16
				.else
					out		@0, R16
				.endif
			.endif
		.endif
	.endif
.ENDMACRO

;----------------------------------------------------------------------------------------
;---
;--- Een poort als INPUT instellen
;---
.MACRO PORT_Set_INPUT;(AVRport:PORT)
	clr		R16										; DDR instellen
	.if @0 == PORTA
		out		DDRA, R16
	.else
		.if @0 == PORTB
			out		DDRB, R16
		.else
			.if @0 == PORTC
				out		DDRC, R16
			.else
				.if @0 == PORTD
					out		DDRD, R16
				.else
					out		@0, R16
				.endif
			.endif
		.endif
	.endif
.ENDMACRO

;----------------------------------------------------------------------------------------
;---
;--- De interne PULL-UP's inschakelen van een poort
;---
.MACRO PORT_Set_PULLUP;(AVRport:PORT)
	ser		R16										; INPUT PORT interne PULL-UP's inschakelen
	.if @0 == DDRA
		out		PORTA, R16
	.else
		.if @0 == DDRB
			out		PORTB, R16
		.else
			.if @0 == DDRC
				out		PORTC, R16
			.else
				.if @0 == DDRD
					out		PORTD, R16
				.else
					out		@0, R16
				.endif
			.endif
		.endif
	.endif
.ENDMACRO

;----------------------------------------------------------------------------------------
;---
;--- De TRI-STATE inschakelen van een poort
;---
.MACRO PORT_Set_TRISTATE;(AVRport:PORT)
	clr		R16										; INPUT PORT instellen op TRISTATE
	.if @0 == DDRA
		out		PORTA, R16
	.else
		.if @0 == DDRB
			out		PORTB, R16
		.else
			.if @0 == DDRC
				out		PORTC, R16
			.else
				.if @0 == DDRD
					out		PORTD, R16
				.else
					out		@0, R16
				.endif
			.endif
		.endif
	.endif
.ENDMACRO


;----------------------------------------------------------------------------------------
;---
;--- Een poort als INPUT instellen, met de interne pull-up's ingeschakeld
;---
.MACRO PORT_Set_INPUT_PULLUP;(AVRport:PORT)
	PORT_Set_INPUT @0
	PORT_Set_PULLUP @0
.ENDMACRO

;----------------------------------------------------------------------------------------
;---
;--- Een poort als INPUT instellen, in TRI-STATE (open collector)
;---
.MACRO PORT_Set_INPUT_TRISTATE;(AVRport:PORT)
	PORT_Set_INPUT @0
	PORT_Set_TRISTATE @0
.ENDMACRO




;----------------------------------------------------------------------------------------
;---
;--- Een pin als OUTPUT instellen
;---
.MACRO PIN_Set_OUTPUT;(AVRport:PORT; AVRpin:PIN)
	.if @0 == PORTA
		sbi		DDRA, @1
	.else
		.if @0 == PORTB
			sbi		DDRB, @1
		.else
			.if @0 == PORTC
				sbi		DDRC, @1
			.else
				.if @0 == PORTD
					sbi		DDRD, @1
				.else
					sbi		@0, @1
				.endif
			.endif
		.endif
	.endif
.ENDMACRO

;----------------------------------------------------------------------------------------
;---
;--- Een pin als INPUT instellen
;---
.MACRO PIN_Set_INPUT;(AVRport:PORT; AVRpin:PIN)
	.if @0 == PORTA
		cbi		DDRA, @1
	.else
		.if @0 == PORTB
			cbi		DDRB, @1
		.else
			.if @0 == PORTC
				cbi		DDRC, @1
			.else
				.if @0 == PORTD
					cbi		DDRD, @1
				.else
					cbi		@0, @1
				.endif
			.endif
		.endif
	.endif
.ENDMACRO

;----------------------------------------------------------------------------------------
;---
;--- De interne PULL-UP's inschakelen van een pin
;---
.MACRO PIN_Set_PULLUP;(AVRport:PORT; AVRpin:PIN)
	.if @0 == DDRA
		sbi		PORTA, @1
	.else
		.if @0 == DDRB
			sbi		PORTB, @1
		.else
			.if @0 == DDRC
				sbi		PORTC, @1
			.else
				.if @0 == DDRD
					sbi		PORTD, @1
				.else
					sbi		@0, @1
				.endif
			.endif
		.endif
	.endif
.ENDMACRO

;----------------------------------------------------------------------------------------
;---
;--- De TRI-STATE inschakelen van een pin
;---
.MACRO PIN_Set_TRISTATE;(AVRport:PORT; AVRpin:PIN)
	.if @0 == DDRA
		cbi		PORTA, @1
	.else
		.if @0 == DDRB
			cbi		PORTB, @1
		.else
			.if @0 == DDRC
				cbi		PORTC, @1
			.else
				.if @0 == DDRD
					cbi		PORTD, @1
				.else
					cbi		@0, @1
				.endif
			.endif
		.endif
	.endif
.ENDMACRO


;----------------------------------------------------------------------------------------
;---
;--- Een pin als INPUT instellen, met de interne pull-up's ingeschakeld
;---
.MACRO PIN_Set_INPUT_PULLUP;(AVRport:PORT; AVRpin:PIN)
	PIN_Set_INPUT @0, @1
	PIN_Set_PULLUP @0, @1
.ENDMACRO

;----------------------------------------------------------------------------------------
;---
;--- Een pin als INPUT instellen, in TRI-STATE (open collector)
;---
.MACRO PIN_Set_INPUT_TRISTATE;(AVRport:PORT; AVRpin:PIN)
	PIN_Set_INPUT @0, @1
	PIN_Set_TRISTATE @0, @1
.ENDMACRO

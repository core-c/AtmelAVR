;---------------------------------------------------------------------------------
;---
;---  Analog-Comparator constanten en macro's			Ron Driessen
;---  AVR AT90S8535										2005
;---
;---------------------------------------------------------------------------------
.ifndef Linked_8535_AC
	.ifndef Link_8535_AC						; Deze unit markeren als zijnde ingelinkt,
		.equ Link_8535_AC = 1					; in geval dat nog niet eerder is gebeurd in code.
	.endif										; (Units nl. maar 1x inlinken)
	.equ Linked_8535_AC = 1					;
.endif





;---------------------------------------------------------------------------------
;--- ACSR	- Analog Comparator control en Status Register
;---
;---	bit  7        6        5        4        3        2        1        0
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	|   ACD  |        |   ACO  |   ACI  |  ACIE  |  ACIC  |  ACIS1 |  ACIS0 |
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	Bit 7		ACD					Analog Comparator Disable
;---	Bit 6							Reserved Bit
;---	Bit 5		ACO					Analog Comparator Output
;---	Bit 4		ACI					Analog Comparator Interrupt Flag
;---	Bit 3		ACIE				Analog Comparator Interrupt Enable
;---	Bit 2		ACIC				Analog Comparator Input Capture Enable
;---	Bit 1..0	ACIS1,ACIS0			Analog Comparator Interrupt Mode Select
;---
;---------------------------------------------------------------------------------



;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			Disable_AnalogComparator
;--- Beschrijving:	De Analog Comparator uitschakelen
;--------------------------------------------
.MACRO Disable_AnalogComparator
	cbi		ACSR, ACIE						; AC interrupt disable
	sbi		ACSR, ACD						; AC disable
	cbi		ACSR, ACIC						; AC bij Input-Capturing uitschakelen
.ENDMACRO

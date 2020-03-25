;---------------------------------------------------------------------------------
;---
;---  Timer constanten en macro's						Ron Driessen
;---  AVR AT90S8535										2005
;---
;---------------------------------------------------------------------------------
.ifndef Linked_8535_Timers
	.ifndef Link_8535_Timers					; Deze unit markeren als zijnde ingelinkt,
		.equ Link_8535_Timers = 1				; in geval dat nog niet eerder is gebeurd in code.
	.endif										; (Units nl. maar 1x inlinken)
	.equ Linked_8535_Timers = 1					;
.endif
; de 3 timer-units inlinken als dat nog niet is gebeurd..
.ifndef Linked_8535_Timer0
	.ifndef Link_8535_Timer0
		.equ Link_8535_Timer0 = 1
	.endif
	.equ Linked_8535_Timer0 = 1
	.include "8535_Timer0.asm"					; Timer0 constanten en macro's
.endif
.ifndef Linked_8535_Timer1
	.ifndef Link_8535_Timer1
		.equ Link_8535_Timer1 = 1
	.endif
	.equ Linked_8535_Timer1 = 1
	.include "8535_Timer1.asm"					; Timer1 constanten en macro's
.endif
.ifndef Linked_8535_Timer2
	.ifndef Link_8535_Timer2
		.equ Link_8535_Timer2 = 1
	.endif
	.equ Linked_8535_Timer2 = 1
	.include "8535_Timer2.asm"					; Timer2 constanten en macro's
.endif






;--- Algemene constanten ---------------------------------------------------------
;# TimerCounter TOP-waarden:
.equ TOP_8BITS	= 0b11111111		; De TOP-waarde voor 8-bits = 2^8 - 1
.equ TOP_9BITS	= 0b111111111		; De TOP-waarde voor 9-bits = 2^9 - 1
.equ TOP_10BITS	= 0b1111111111		; De TOP-waarde voor 10-bits = 2^10 - 1
.equ TOP_16BITS	= 0b1111111111111111; De TOP-waarde voor 16-bits = 2^16 - 1



;---------------------------------------------------------------------------------
;--- TIMSK - Timercounter Interrupt MaSK register
;---
;---	bit  7        6        5        4        3        2        1        0
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	|  OCIE2 |  TOIE2 | TICIE1 | OCIE1A | OCIE1B |  TOIE1 |        |  TOIE0 |
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	Bit 7		OCIE2				Timer/Counter2 Output Compare Match Interrupt Enable
;---	Bit 6		TOIE2				Timer/Counter2 Overflow Interrupt Enable
;---	Bit 5		TICIE1				Timer/Counter1 Input Capture Interrupt Enable
;---	Bit 4		OCIE1A				Timer/Counter1 Output CompareA Match Interrupt Enable
;---	Bit 3		OCIE1B				Timer/Counter1 Output CompareB Match Interrupt Enable
;---	Bit 2		TOIE1				Timer/Counter1 Overflow Interrupt Enable
;---	Bit 1							Reserved Bit
;---	Bit 0		TOIE0				Timer/Counter0 Overflow Interrupt Enable
;---
;---------------------------------------------------------------------------------


;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			Disable_Interrupts
;--- Beschrijving:	Alle interrupts uitschakelen
;--------------------------------------------
.MACRO Disable_Interrupts
	clr		R16
	out		TIMSK, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Enable_Interrupts
;--- Beschrijving:	Interrupt Enable voor het opgegeven masker in register @0
;--------------------------------------------
.MACRO Enable_Interrupts;(interrupt[s]-mask: register)
	out		TIMSK, @0
.ENDMACRO


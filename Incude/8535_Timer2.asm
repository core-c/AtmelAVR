;---------------------------------------------------------------------------------
;---
;---  Timer2 constanten									Ron Driessen
;---  AVR AT90S8535										2005
;---
;---------------------------------------------------------------------------------
.ifndef Linked_8535_Timer2
	.ifndef Link_8535_Timer2					; Deze unit markeren als zijnde ingelinkt,
		.equ Link_8535_Timer2 = 1				; in geval dat nog niet eerder is gebeurd in code.
	.endif										; (Units nl. maar 1x inlinken)
	.equ Linked_8535_Timer2 = 1					;
.endif



;---------------------------------------------------------------------------------
;--- TCCR2	- Timer2 Counter Control Register
;---
;---	bit  7        6        5        4        3        2        1        0
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	|        |  PWM2  |  COM21 |  COM20 |  CTC2  |  CS22  |  CS21  |  CS20  |
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	Bits 7							Reserved Bit
;---	Bit 6		PWM2				Pulse Width Modulator Enable
;---	Bit 5..4	COM21,COM20			Compare Output Mode, Bits 1 and 0
;---	Bit 3		CTC2				Clear Timer/Counter on Compare Match
;---	Bits 2..0	CS21,CS21,CS20		Clock Select2, Bits 2, 1 and 0
;---
;---------------------------------------------------------------------------------


;# Hardware (Output-Compare) actie op pin PD7 "OC2" bij een Timer2 Compare Match
;!! (in geval er geen PWM wordt gebruikt)
.equ TIMER_2__OUTPUTCOMPARE_OFF		= (0<<COM21 | 0<<COM20)	; geen actie op PD7
.equ TIMER_2__OUTPUTCOMPARE_TOGGLE	= (0<<COM21 | 1<<COM20)	; toggle PD7
.equ TIMER_2__OUTPUTCOMPARE_0		= (1<<COM21 | 0<<COM20)	; PD7 op 0
.equ TIMER_2__OUTPUTCOMPARE_1		= (1<<COM21 | 1<<COM20)	; PD7 op 1
;- - - - - - - - - - - - - - - - - - - - - - 
;# Hardware PWM-mode, met output op pins PD7 "OC2"
;!! (Als HW PWM is ingeschakeld, is automatisch OUTPUTCOMPARE uitgeschakeld.)
.equ TIMER_2_PWM_OFF		= (0<<PWM2)
.equ TIMER_2_PWM_8BITS		= (1<<PWM2)
;# De verschillende PWM-modes:
; output op PD7 "OC2"
.equ TIMER_2_PWM_NONINVERTED	= (1<<COM21 | 0<<COM20)		; non-inverted PWM op PD7
.equ TIMER_2_PWM_INVERTED		= (1<<COM21 | 1<<COM20)		; inverted PWM op PD7

;- - - - - - - - - - - - - - - - - - - - - - 
; combinaties met voorgaande constanten:
;# Hardwarematige Output Compare:
; Helemaal geen Output-Compare gebruiken:
.equ TIMER_2_OUTPUTCOMPARE_OFF				= (TIMER_2_PWM_OFF | TIMER_2__OUTPUTCOMPARE_OFF)
; Timer-2 Output-Compare gebruiken:
.equ TIMER_2_OUTPUTCOMPARE_0				= (TIMER_2_PWM_OFF | TIMER_2__OUTPUTCOMPARE_0)
.equ TIMER_2_OUTPUTCOMPARE_1				= (TIMER_2_PWM_OFF | TIMER_2__OUTPUTCOMPARE_1)
.equ TIMER_2_OUTPUTCOMPARE_Toggle			= (TIMER_2_PWM_OFF | TIMER_2__OUTPUTCOMPARE_TOGGLE)
;--------------------------------------------
;# Hardwarematige PWM 2: output op PD7 "OC2":
; (non inverted)
.equ TIMER_2_PWM_8BITS_NONINVERTED			= (TIMER_2_PWM_8BITS	| TIMER_2_PWM_NONINVERTED)
; (inverted)
.equ TIMER_2_PWM_8BITS_INVERTED				= (TIMER_2_PWM_8BITS	| TIMER_2_PWM_INVERTED)


;--------------------------------------------
; De Timer2Counter (hardwarematig/automatisch) wissen (op 0 zetten) bij een Timer2-Compare match
.equ TIMER_2_CLEARCOUNTER_ON_MATCH	= (1<<CTC2)


;--- Timer2 Prescale -------------------------------------------------------------
.equ TIMER_2_CLOCK_OFF				= (0<<CS22 | 0<<CS21 | 0<<CS20)	; timer uitschakelen
.equ TIMER_2_CLOCK_PRESCALE_CK		= (0<<CS22 | 0<<CS21 | 1<<CS20)	; timer frequentie = CK
.equ TIMER_2_CLOCK_PRESCALE_CK8		= (0<<CS22 | 1<<CS21 | 0<<CS20)	; timer frequentie = CK/8
.equ TIMER_2_CLOCK_PRESCALE_CK32	= (0<<CS22 | 1<<CS21 | 1<<CS20)	; timer frequentie = CK/32
.equ TIMER_2_CLOCK_PRESCALE_CK64	= (1<<CS22 | 0<<CS21 | 0<<CS20)	; timer frequentie = CK/64
.equ TIMER_2_CLOCK_PRESCALE_CK128	= (1<<CS22 | 0<<CS21 | 1<<CS20)	; timer frequentie = CK/128
.equ TIMER_2_CLOCK_PRESCALE_CK256	= (1<<CS22 | 1<<CS21 | 0<<CS20)	; timer frequentie = CK/256
.equ TIMER_2_CLOCK_PRESCALE_CK1024	= (1<<CS22 | 1<<CS21 | 1<<CS20)	; timer frequentie = CK/1024



;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			Config_Timer2
;--- Beschrijving:	De Timer-2 instellen
;--------------------------------------------
.MACRO Config_Timer2;(instelling: register)
	out		TCCR2, @0
.ENDMACRO

;--------------------------------------------
;--- Naam:			Initialize_OutputCompare2
;--- Beschrijving:	De Timer-2 Output-Compare-Pin als output instellen
;--------------------------------------------
.MACRO Initialize_OutputCompare2
	sbi		DDRD, PD7						; PD7 "OC2" als output instellen
.ENDMACRO



;--------------------------------------------
;--- Naam:			Timer2Clock_Off
;--- Beschrijving:	De Timer-2 stoppen
;--------------------------------------------
.MACRO Timer2Clock_Off
	in		R16, TCCR2
	andi	R16, ~(1<<CS22 | 1<<CS21 | 1<<CS20) ;0b11111000
	;ori	R16, TIMER_2_CLOCK_OFF
	out		TCCR2, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer2Clock_PrescaleCK
;--- Beschrijving:	De Timer-2 prescalen op CK (TCK=CK)
;--------------------------------------------
.MACRO Timer2Clock_PrescaleCK
	in		R16, TCCR2
	andi	R16, ~(1<<CS22 | 1<<CS21 | 1<<CS20) ;0b11111000
	ori		R16, TIMER_2_CLOCK_PRESCALE_CK
	out		TCCR2, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer2Clock_PrescaleCK8
;--- Beschrijving:	De Timer-2 prescalen op CK/8 (TCK=CK/8)
;--------------------------------------------
.MACRO Timer2Clock_PrescaleCK8
	in		R16, TCCR2
	andi	R16, ~(1<<CS22 | 1<<CS21 | 1<<CS20) ;0b11111000
	ori		R16, TIMER_2_CLOCK_PRESCALE_CK8
	out		TCCR2, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer2Clock_PrescaleCK32
;--- Beschrijving:	De Timer-2 prescalen op CK/32 (TCK=CK/32)
;--------------------------------------------
.MACRO Timer2Clock_PrescaleCK32
	in		R16, TCCR2
	andi	R16, ~(1<<CS22 | 1<<CS21 | 1<<CS20) ;0b11111000
	ori		R16, TIMER_2_CLOCK_PRESCALE_CK32
	out		TCCR2, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer2Clock_PrescaleCK64
;--- Beschrijving:	De Timer-2 prescalen op CK/64 (TCK=CK/64)
;--------------------------------------------
.MACRO Timer2Clock_PrescaleCK64
	in		R16, TCCR2
	andi	R16, ~(1<<CS22 | 1<<CS21 | 1<<CS20) ;0b11111000
	ori		R16, TIMER_2_CLOCK_PRESCALE_CK64
	out		TCCR2, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer2Clock_PrescaleCK128
;--- Beschrijving:	De Timer-2 prescalen op CK/128 (TCK=CK/128)
;--------------------------------------------
.MACRO Timer2Clock_PrescaleCK128
	in		R16, TCCR2
	andi	R16, ~(1<<CS22 | 1<<CS21 | 1<<CS20) ;0b11111000
	ori		R16, TIMER_2_CLOCK_PRESCALE_CK128
	out		TCCR2, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer2Clock_PrescaleCK256
;--- Beschrijving:	De Timer-2 prescalen op CK/256 (TCK=CK/256)
;--------------------------------------------
.MACRO Timer2Clock_PrescaleCK256
	in		R16, TCCR2
	andi	R16, ~(1<<CS22 | 1<<CS21 | 1<<CS20) ;0b11111000
	ori		R16, TIMER_2_CLOCK_PRESCALE_CK256
	out		TCCR2, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer2Clock_PrescaleCK1024
;--- Beschrijving:	De Timer-2 prescalen op CK/1024 (TCK=CK/1024)
;--------------------------------------------
.MACRO Timer2Clock_PrescaleCK1024
	in		R16, TCCR2
	andi	R16, ~(1<<CS22 | 1<<CS21 | 1<<CS20) ;0b11111000
	ori		R16, TIMER_2_CLOCK_PRESCALE_CK1024
	out		TCCR2, R16
.ENDMACRO





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


;--------------------------------------------
;--- Timer-2 Interrupt Enable
;--------------------------------------------
.equ TIMER_2_INTERRUPTENABLE_COMPAREMATCH	= (1<<OCIE2)
.equ TIMER_2_INTERRUPTENABLE_OVERFLOW		= (1<<TOIE2)





;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			Disable_Interrupt_CompareMatch2
;--- Beschrijving:	Interrupt uitschakelen voor Timer-2 Compare-Match
;--------------------------------------------
.MACRO Disable_Interrupt_CompareMatch2
	cbi		TIMSK, OCIE2
.ENDMACRO

;--------------------------------------------
;--- Naam:			Disable_Interrupt_Overflow2
;--- Beschrijving:	Interrupt uitschakelen voor Timer-2 Overflow
;--------------------------------------------
.MACRO Disable_Interrupt_Overflow2
	cbi		TIMSK, TOIE2
.ENDMACRO


;--------------------------------------------
;--- Naam:			Enable_Interrupt_CompareMatch2
;--- Beschrijving:	Interrupt inschakelen voor Timer-2 Compare-Match
;--------------------------------------------
.MACRO Enable_Interrupt_CompareMatch2
	sbi		TIMSK, OCIE2
.ENDMACRO

;--------------------------------------------
;--- Naam:			Enable_Interrupt_Overflow2
;--- Beschrijving:	Interrupt inschakelen voor Timer-2 Overflow
;--------------------------------------------
.MACRO Enable_Interrupt_Overflow2
	sbi		TIMSK, TOIE2
.ENDMACRO



;--------------------------------------------
;--- Naam:			Get_TimerCounter2
;--- Beschrijving:	TimerCounter-2 opvragen in register "Value"
;--------------------------------------------
.MACRO Get_TimerCounter2;(Value : register)
	in		@0, TCNT2
.ENDMACRO

;--------------------------------------------
;--- Naam:			Set_TimerCounter2
;--- Beschrijving:	TimerCounter-2 instellen; Register "Value" bevat de nieuwe teller-waarde
;--------------------------------------------
.MACRO Set_TimerCounter2;(Value : register)
	out		TCNT2, @0
.ENDMACRO

;--------------------------------------------
;--- Naam:			SetI_TimerCounter2
;--- Beschrijving:	TimerCounter-2 instellen op een opgegeven constante (8-bits) waarde
;--------------------------------------------
.MACRO SetI_TimerCounter2;(Value : 8bit-constante)
	ldi		R16, @0
	out		TCNT2, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Clear_TimerCounter2
;--- Beschrijving:	TimerCounter-2 wissen / waarde op 0
;--------------------------------------------
.MACRO Clear_TimerCounter2
	clr		R16
	out		TCNT2, R16
.ENDMACRO



;--------------------------------------------
;--- Naam:			Get_Compare2
;--- Beschrijving:	De Timer-2 Compare waarde opvragen in register "Value"
;--------------------------------------------
.MACRO Get_Compare2;(Value : register)
	in		@0, OCR2
.ENDMACRO

;--------------------------------------------
;--- Naam:			Set_Compare2
;--- Beschrijving:	De Timer-2 Compare instellen: Register "Value" bevat de nieuwe teller-waarde
;--------------------------------------------
.MACRO Set_Compare2;(Value: register)
	out		OCR2, @0
.ENDMACRO

;--------------------------------------------
;--- Naam:			SetI_Compare2
;--- Beschrijving:	De Timer-2 Compare waarde instellen op een opgegeven constante (8-bits) waarde
;--------------------------------------------
.MACRO SetI_Compare2;(8bit-constante)
	ldi		R16, @0
	out		OCR2, R16
.ENDMACRO

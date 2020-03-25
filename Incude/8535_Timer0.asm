;---------------------------------------------------------------------------------
;---
;---  Timer0 constanten									Ron Driessen
;---  AVR AT90S8535										2005
;---
;---------------------------------------------------------------------------------
.ifndef Linked_8535_Timer0
	.ifndef Link_8535_Timer0					; Deze unit markeren als zijnde ingelinkt,
		.equ Link_8535_Timer0 = 1				; in geval dat nog niet eerder is gebeurd in code.
	.endif										; (Units nl. maar 1x inlinken)
	.equ Linked_8535_Timer0 = 1					;
.endif





;---------------------------------------------------------------------------------
;--- TCCR0	- Timer0 Counter Control Register
;---
;---	bit  7        6        5        4        3        2        1        0
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	|        |        |        |        |        |  CS02  |  CS01  |  CS00  |
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	Bits 7..3						Reserved Bits
;---	Bits 2..0	CS01,CS01,CS00		Clock Select0, Bits 2, 1 and 0
;---
;---------------------------------------------------------------------------------


;--------------------------------------------
;--- Timer-0 Prescale
;--------------------------------------------
.equ TIMER_0_CLOCK_OFF				= (0<<CS02 | 0<<CS01 | 0<<CS00)	; timer uitschakelen
.equ TIMER_0_CLOCK_PRESCALE_CK		= (0<<CS02 | 0<<CS01 | 1<<CS00)	; timer frequentie = CK
.equ TIMER_0_CLOCK_PRESCALE_CK8		= (0<<CS02 | 1<<CS01 | 0<<CS00)	; timer frequentie = CK/8
.equ TIMER_0_CLOCK_PRESCALE_CK64	= (0<<CS02 | 1<<CS01 | 1<<CS00)	; timer frequentie = CK/64
.equ TIMER_0_CLOCK_PRESCALE_CK256	= (1<<CS02 | 0<<CS01 | 0<<CS00)	; timer frequentie = CK/256
.equ TIMER_0_CLOCK_PRESCALE_CK1024	= (1<<CS02 | 0<<CS01 | 1<<CS00)	; timer frequentie = CK/1024
.equ TIMER_0_CLOCK_EXT_FALLINGEDGE	= (1<<CS02 | 1<<CS01 | 0<<CS00)	; timer frequentie = Ext. pin T0 op neergaande flank
.equ TIMER_0_CLOCK_EXT_RISINGEDGE	= (1<<CS02 | 1<<CS01 | 1<<CS00)	; timer frequentie = Ext. pin T0 op opgaande flank



;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			Config_Timer0
;--- Beschrijving:	Timer-0 instellen
;--------------------------------------------
.MACRO Config_Timer0;(instelling: register)
	out		TCCR0, @0
.ENDMACRO


;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			Timer0Clock_Off
;--- Beschrijving:	De timer0 stoppen
;--------------------------------------------
.MACRO Timer0Clock_Off
	in		R16, TCCR0
	andi	R16, ~(1<<CS02 | 1<<CS01 | 1<<CS00) ;0b11111000
	;ori	R16, TIMER_0_CLOCK_OFF
	out		TCCR0, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer0Clock_PrescaleCK
;--- Beschrijving:	De timer0 prescalen op CK (TCK=CK)
;--------------------------------------------
.MACRO Timer0Clock_PrescaleCK
	in		R16, TCCR0
	andi	R16, ~(1<<CS02 | 1<<CS01 | 1<<CS00) ;0b11111000
	ori		R16, TIMER_0_CLOCK_PRESCALE_CK
	out		TCCR0, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer0Clock_PrescaleCK8
;--- Beschrijving:	De timer0 prescalen op CK/8 (TCK=CK/8)
;--------------------------------------------
.MACRO Timer0Clock_PrescaleCK8
	in		R16, TCCR0
	andi	R16, ~(1<<CS02 | 1<<CS01 | 1<<CS00) ;0b11111000
	ori		R16, TIMER_0_CLOCK_PRESCALE_CK8
	out		TCCR0, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer0Clock_PrescaleCK64
;--- Beschrijving:	De timer0 prescalen op CK/64 (TCK=CK/64)
;--------------------------------------------
.MACRO Timer0Clock_PrescaleCK64
	in		R16, TCCR0
	andi	R16, ~(1<<CS02 | 1<<CS01 | 1<<CS00) ;0b11111000
	ori		R16, TIMER_0_CLOCK_PRESCALE_CK64
	out		TCCR0, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer0Clock_PrescaleCK256
;--- Beschrijving:	De timer0 prescalen op CK/256 (TCK=CK/256)
;--------------------------------------------
.MACRO Timer0Clock_PrescaleCK256
	in		R16, TCCR0
	andi	R16, ~(1<<CS02 | 1<<CS01 | 1<<CS00) ;0b11111000
	ori		R16, TIMER_0_CLOCK_PRESCALE_CK256
	out		TCCR0, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer0Clock_PrescaleCK1024
;--- Beschrijving:	De timer0 prescalen op CK/1024 (TCK=CK/1024)
;--------------------------------------------
.MACRO Timer0Clock_PrescaleCK1024
	in		R16, TCCR0
	andi	R16, ~(1<<CS02 | 1<<CS01 | 1<<CS00) ;0b11111000
	ori		R16, TIMER_0_CLOCK_PRESCALE_CK1024
	out		TCCR0, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer0Clock_External_FallingEdge
;--- Beschrijving:	De timer0 extern timen, tellen op een neergaande flank (TCK</PB0 "T0")
;---				(pulzen tellen op elke neergaande flank)
;--------------------------------------------
.MACRO Timer0Clock_External_FallingEdge
	in		R16, TCCR0
	andi	R16, ~(1<<CS02 | 1<<CS01 | 1<<CS00) ;0b11111000
	ori		R16, TIMER_0_CLOCK_EXT_FALLINGEDGE
	out		TCCR0, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer0Clock_External_RisingEdge
;--- Beschrijving:	De timer0 extern timen, tellen op een opgaande flank (TCK<\PB0 "T0")
;---				(pulzen tellen op elke opgaande flank)
;--------------------------------------------
.MACRO Timer0Clock_External_RisingEdge
	in		R16, TCCR0
	andi	R16, ~(1<<CS02 | 1<<CS01 | 1<<CS00) ;0b11111000
	ori		R16, TIMER_0_CLOCK_EXT_RISINGEDGE
	out		TCCR0, R16
.ENDMACRO
;---------------------------------------------------------------------------------





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
;--- Timer-0 Interrupt Enable
;--------------------------------------------
.equ TIMER_0_INTERRUPTENABLE_OVERFLOW	= (1<<TOIE0)





;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			Disable_Interrupt_Overflow0
;--- Beschrijving:	Interrupt uitschakelen voor Timer-0 Overflow
;--------------------------------------------
.MACRO Disable_Interrupt_Overflow0
	cbi		TIMSK, TOIE0
.ENDMACRO

;--------------------------------------------
;--- Naam:			Enable_Interrupt_Overflow0
;--- Beschrijving:	Interrupt Enable voor Timer-0 Overflow
;--------------------------------------------
.MACRO Enable_Interrupt_Overflow0
	sbi		TIMSK, TOIE0
.ENDMACRO



;--------------------------------------------
;--- Naam:			Get_TimerCounter0
;--- Beschrijving:	TimerCounter-0 opvragen in register "Value"
;--------------------------------------------
.MACRO Get_TimerCounter0;(Value : register)
	in		@0, TCNT0
.ENDMACRO

;--------------------------------------------
;--- Naam:			Set_TimerCounter0
;--- Beschrijving:	TimerCounter-0 instellen; Register "Value" bevat de nieuwe teller-waarde
;--------------------------------------------
.MACRO Set_TimerCounter0;(Value : register)
	out		TCNT0, @0
.ENDMACRO

;--------------------------------------------
;--- Naam:			SetI_TimerCounter0
;--- Beschrijving:	TimerCounter-0 instellen op een opgegeven constante (8-bits) waarde
;--------------------------------------------
.MACRO SetI_TimerCounter0;(Value : 8bit-constante)
	ldi		R16, @0
	out		TCNT0, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Clear_TimerCounter0
;--- Beschrijving:	TimerCounter-0 wissen / waarde op 0
;--------------------------------------------
.MACRO Clear_TimerCounter0
	clr		R16
	out		TCNT0, R16
.ENDMACRO


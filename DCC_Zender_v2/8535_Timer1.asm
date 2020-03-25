;---------------------------------------------------------------------------------
;---
;---  Timer1 constanten									Ron Driessen
;---  AVR AT90S8535										2005
;---
;---------------------------------------------------------------------------------
.ifndef Linked_8535_Timer1
	.ifndef Link_8535_Timer1					; Deze unit markeren als zijnde ingelinkt,
		.equ Link_8535_Timer1 = 1				; in geval dat nog niet eerder is gebeurd in code.
	.endif										; (Units nl. maar 1x inlinken)
	.equ Linked_8535_Timer1 = 1					;
.endif



;---------------------------------------------------------------------------------
;--- TCCR1A	- Timer1 Counter Control Register A
;---
;---	bit  7        6        5        4        3        2        1        0
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	| COM1A1 | COM1A0 | COM1B1 | COM1B0 |        |        |  PWM11 |  PWM10 |
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	Bits 7, 6	COM1A1,COM1A0		Compare Output Mode1A, Bits 1 and 0
;---	Bits 5, 4	COM1B1,COM1B0		Compare Output Mode1B, Bits 1 and 0
;---	Bits 3..2						Reserved Bits
;---	Bits 1..0	PWM11,PWM10			Pulse Width Modulator Select Bits
;---
;---------------------------------------------------------------------------------


;# Hardware (Output-Compare) actie op pin PD5 "OC1A" bij een Timer1 CompareA Match
;!! (in geval er geen PWM wordt gebruikt)
.equ TIMER_1A_OUTPUTCOMPARE_OFF		= (0<<COM1A1 | 0<<COM1A0)	; geen actie op PD5
.equ TIMER_1A_OUTPUTCOMPARE_TOGGLE	= (0<<COM1A1 | 1<<COM1A0)	; toggle PinD5
.equ TIMER_1A_OUTPUTCOMPARE_0		= (1<<COM1A1 | 0<<COM1A0)	; PD5 op 0
.equ TIMER_1A_OUTPUTCOMPARE_1		= (1<<COM1A1 | 1<<COM1A0)	; PD5 op 1
;  Hardware (Output-Compare) actie op pin PD4 "OC1B" bij een Timer1 CompareB Match
.equ TIMER_1B_OUTPUTCOMPARE_OFF		= (0<<COM1B1 | 0<<COM1B0)	; geen actie op PD4
.equ TIMER_1B_OUTPUTCOMPARE_TOGGLE	= (0<<COM1B1 | 1<<COM1B0)	; toggle PinD4
.equ TIMER_1B_OUTPUTCOMPARE_0		= (1<<COM1B1 | 0<<COM1B0)	; PD4 op 0
.equ TIMER_1B_OUTPUTCOMPARE_1		= (1<<COM1B1 | 1<<COM1B0)	; PD4 op 1
;- - - - - - - - - - - - - - - - - - - - - - 
;# Hardware PWM-modes, met output op pins PD5 & PD4 ("OC1A" & "OC1B")
;!! (Als HW PWM is ingeschakeld, is automatisch OUTPUTCOMPARE uitgeschakeld.)
;# De PWM-resolutie in bits:
.equ TIMER_1_PWM_OFF		= (0<<PWM11  | 0<<PWM10)
.equ TIMER_1_PWM_8BITS		= (0<<PWM11  | 1<<PWM10)
.equ TIMER_1_PWM_9BITS		= (1<<PWM11  | 0<<PWM10)
.equ TIMER_1_PWM_10BITS		= (1<<PWM11  | 1<<PWM10)
;# De verschillende PWM-modes:
; output op PD5 "OC1A"
.equ TIMER_1A_PWM_NONINVERTED	= (1<<COM1A1 | 0<<COM1A0)		; non-inverted PWM op PD5
.equ TIMER_1A_PWM_INVERTED		= (1<<COM1A1 | 1<<COM1A0)		; inverted PWM op PD5
; output op PD4 "OC1B"
.equ TIMER_1B_PWM_NONINVERTED	= (1<<COM1B1 | 0<<COM1B0)		; non-inverted PWM op PD4
.equ TIMER_1B_PWM_INVERTED		= (1<<COM1B1 | 1<<COM1B0)		; inverted PWM op PD4

;- - - - - - - - - - - - - - - - - - - - - - 
; combinaties met voorgaande constanten:
;# Hardwarematige Output Compare:
; Helemaal geen Output-Compare gebruiken:
.equ TIMER_1_OUTPUTCOMPARE_OFF				= (TIMER_1_PWM_OFF | TIMER_1A_OUTPUTCOMPARE_OFF		| TIMER_1B_OUTPUTCOMPARE_OFF)
; alleen Output-CompareA gebruiken:
.equ TIMER_1_OUTPUTCOMPARE_A0				= (TIMER_1_PWM_OFF | TIMER_1A_OUTPUTCOMPARE_0)
.equ TIMER_1_OUTPUTCOMPARE_A1				= (TIMER_1_PWM_OFF | TIMER_1A_OUTPUTCOMPARE_1)
.equ TIMER_1_OUTPUTCOMPARE_AToggle			= (TIMER_1_PWM_OFF | TIMER_1A_OUTPUTCOMPARE_TOGGLE)
; alleen Output-CompareB gebruiken:
.equ TIMER_1_OUTPUTCOMPARE_B0				= (TIMER_1_PWM_OFF | TIMER_1B_OUTPUTCOMPARE_0)
.equ TIMER_1_OUTPUTCOMPARE_B1				= (TIMER_1_PWM_OFF | TIMER_1B_OUTPUTCOMPARE_1)
.equ TIMER_1_OUTPUTCOMPARE_BToggle			= (TIMER_1_PWM_OFF | TIMER_1B_OUTPUTCOMPARE_TOGGLE)
;- - - - - - - - - - - - - - - - - - - - - - 
; combinaties Output-CompareA & Output-CompareB gebruiken:
.equ TIMER_1_OUTPUTCOMPARE_A0_B0			= (TIMER_1_PWM_OFF | TIMER_1A_OUTPUTCOMPARE_0		| TIMER_1B_OUTPUTCOMPARE_0)
.equ TIMER_1_OUTPUTCOMPARE_A0_B1			= (TIMER_1_PWM_OFF | TIMER_1A_OUTPUTCOMPARE_0		| TIMER_1B_OUTPUTCOMPARE_1)
.equ TIMER_1_OUTPUTCOMPARE_A0_BToggle		= (TIMER_1_PWM_OFF | TIMER_1A_OUTPUTCOMPARE_0		| TIMER_1B_OUTPUTCOMPARE_TOGGLE)
.equ TIMER_1_OUTPUTCOMPARE_A1_B0			= (TIMER_1_PWM_OFF | TIMER_1A_OUTPUTCOMPARE_1		| TIMER_1B_OUTPUTCOMPARE_0)
.equ TIMER_1_OUTPUTCOMPARE_A1_B1			= (TIMER_1_PWM_OFF | TIMER_1A_OUTPUTCOMPARE_1		| TIMER_1B_OUTPUTCOMPARE_1)
.equ TIMER_1_OUTPUTCOMPARE_A1_BToggle		= (TIMER_1_PWM_OFF | TIMER_1A_OUTPUTCOMPARE_1		| TIMER_1B_OUTPUTCOMPARE_TOGGLE)
.equ TIMER_1_OUTPUTCOMPARE_AToggle_B0		= (TIMER_1_PWM_OFF | TIMER_1A_OUTPUTCOMPARE_TOGGLE	| TIMER_1B_OUTPUTCOMPARE_0)
.equ TIMER_1_OUTPUTCOMPARE_AToggle_B1		= (TIMER_1_PWM_OFF | TIMER_1A_OUTPUTCOMPARE_TOGGLE	| TIMER_1B_OUTPUTCOMPARE_1)
.equ TIMER_1_OUTPUTCOMPARE_AToggle_BToggle	= (TIMER_1_PWM_OFF | TIMER_1A_OUTPUTCOMPARE_TOGGLE	| TIMER_1B_OUTPUTCOMPARE_TOGGLE)
;--------------------------------------------
;# Hardwarematige PWM 1A: output op PD5 "OC1A":
; (non inverted)
.equ TIMER_1A_PWM_8BITS_NONINVERTED				= (TIMER_1_PWM_8BITS	| TIMER_1A_PWM_NONINVERTED)
.equ TIMER_1A_PWM_9BITS_NONINVERTED				= (TIMER_1_PWM_9BITS	| TIMER_1A_PWM_NONINVERTED)
.equ TIMER_1A_PWM_10BITS_NONINVERTED			= (TIMER_1_PWM_10BITS	| TIMER_1A_PWM_NONINVERTED)
; (inverted)
.equ TIMER_1A_PWM_8BITS_INVERTED				= (TIMER_1_PWM_8BITS	| TIMER_1A_PWM_INVERTED)
.equ TIMER_1A_PWM_9BITS_INVERTED				= (TIMER_1_PWM_9BITS	| TIMER_1A_PWM_INVERTED)
.equ TIMER_1A_PWM_10BITS_INVERTED				= (TIMER_1_PWM_10BITS	| TIMER_1A_PWM_INVERTED)
;# Hardwarematige PWM 1B: output op PD4 "OC1B":
; (non inverted)
.equ TIMER_1B_PWM_8BITS_NONINVERTED				= (TIMER_1_PWM_8BITS	| TIMER_1B_PWM_NONINVERTED)
.equ TIMER_1B_PWM_9BITS_NONINVERTED				= (TIMER_1_PWM_9BITS	| TIMER_1B_PWM_NONINVERTED)
.equ TIMER_1B_PWM_10BITS_NONINVERTED			= (TIMER_1_PWM_10BITS	| TIMER_1B_PWM_NONINVERTED)
; (inverted)
.equ TIMER_1B_PWM_8BITS_INVERTED				= (TIMER_1_PWM_8BITS	| TIMER_1B_PWM_INVERTED)
.equ TIMER_1B_PWM_9BITS_INVERTED				= (TIMER_1_PWM_9BITS	| TIMER_1B_PWM_INVERTED)
.equ TIMER_1B_PWM_10BITS_INVERTED				= (TIMER_1_PWM_10BITS	| TIMER_1B_PWM_INVERTED)
;- - - - - - - - - - - - - - - - - - - - - - 
; combinaties PWM 1A & 1B gebruiken:
;# HW PWM 1A (non inverted) & HW PWM 1B (non inverted)
.equ TIMER_1AB_PWM_8BITS_NONINVERTED			= (TIMER_1_PWM_8BITS	| TIMER_1A_PWM_NONINVERTED	| TIMER_1B_PWM_NONINVERTED)
.equ TIMER_1AB_PWM_9BITS_NONINVERTED			= (TIMER_1_PWM_9BITS	| TIMER_1A_PWM_NONINVERTED	| TIMER_1B_PWM_NONINVERTED)
.equ TIMER_1AB_PWM_10BITS_NONINVERTED			= (TIMER_1_PWM_10BITS	| TIMER_1A_PWM_NONINVERTED	| TIMER_1B_PWM_NONINVERTED)
;# HW PWM 1A (non inverted) & HW PWM 1B (inverted)
.equ TIMER_1AB_PWM_8BITS_NONINVERTED_INVERTED	= (TIMER_1_PWM_8BITS	| TIMER_1A_PWM_NONINVERTED	| TIMER_1B_PWM_INVERTED)
.equ TIMER_1AB_PWM_9BITS_NONINVERTED_INVERTED	= (TIMER_1_PWM_9BITS	| TIMER_1A_PWM_NONINVERTED	| TIMER_1B_PWM_INVERTED)
.equ TIMER_1AB_PWM_10BITS_NONINVERTED_INVERTED	= (TIMER_1_PWM_10BITS	| TIMER_1A_PWM_NONINVERTED	| TIMER_1B_PWM_INVERTED)
;# HW PWM 1A (inverted) & HW PWM 1B (non inverted)
.equ TIMER_1AB_PWM_8BITS_INVERTED_NONINVERTED	= (TIMER_1_PWM_8BITS	| TIMER_1A_PWM_INVERTED		| TIMER_1B_PWM_NONINVERTED)
.equ TIMER_1AB_PWM_9BITS_INVERTED_NONINVERTED	= (TIMER_1_PWM_9BITS	| TIMER_1A_PWM_INVERTED		| TIMER_1B_PWM_NONINVERTED)
.equ TIMER_1AB_PWM_10BITS_INVERTED_NONINVERTED	= (TIMER_1_PWM_10BITS	| TIMER_1A_PWM_INVERTED		| TIMER_1B_PWM_NONINVERTED)



;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			Config_Timer1
;--- Beschrijving:	De Timer-1 instellen
;--------------------------------------------
.MACRO Config_Timer1;(instelling: register)
	out		TCCR1A, @0
.ENDMACRO

;--------------------------------------------
;--- Naam:			Initialize_OutputCompare1A
;--- Beschrijving:	De Timer-1 Output-CompareA-Pin als output instellen
;--------------------------------------------
.MACRO Initialize_OutputCompare1A
	sbi		DDRD, PD5						; PD5 "OC1A" als output instellen
.ENDMACRO

;--------------------------------------------
;--- Naam:			Initialize_OutputCompare1B
;--- Beschrijving:	De Timer-1 Output-CompareB-Pin als output instellen
;--------------------------------------------
.MACRO Initialize_OutputCompare1B
	sbi		DDRD, PD4						; PD4 "OC1B" als output instellen
.ENDMACRO

;--------------------------------------------
;--- Naam:			Initialize_InputCapture1
;--- Beschrijving:	De Timer-1 Input-Capture-Pin als input instellen
;--------------------------------------------
.MACRO Initialize_InputCapture1
	cbi		DDRD, PD6						; PD6 "ICP" als input instellen
.ENDMACRO







;---------------------------------------------------------------------------------
;--- TCCR1B - Timer1 Counter Control Register B
;---
;---	bit  7        6        5        4        3        2        1        0
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	|  ICNC1 |  ICES1 |        |        |  CTC1  |  CS12  |  CS11  |  CS10  |
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	Bit 7		ICNC1				Input Capture1 Noise Canceler (4 CKs)
;---	Bit 6		ICES1				Input Capture1 Edge Select
;---	Bits 5, 4						Reserved Bits
;---	Bit 3		CTC1				Clear Timer/Counter1 on Compare Match
;---	Bits 2..0	CS12,CS11,CS10		Clock Select1, Bits 2, 1 and 0
;---
;---------------------------------------------------------------------------------


;--------------------------------------------
;--- Timer-1 Prescale
;--------------------------------------------
.equ TIMER_1_CLOCK_OFF				= (0<<CS12 | 0<<CS11 | 0<<CS10)	; timer uitschakelen
.equ TIMER_1_CLOCK_PRESCALE_CK		= (0<<CS12 | 0<<CS11 | 1<<CS10)	; timer frequentie = CK
.equ TIMER_1_CLOCK_PRESCALE_CK8		= (0<<CS12 | 1<<CS11 | 0<<CS10)	; timer frequentie = CK/8
.equ TIMER_1_CLOCK_PRESCALE_CK64	= (0<<CS12 | 1<<CS11 | 1<<CS10)	; timer frequentie = CK/64
.equ TIMER_1_CLOCK_PRESCALE_CK256	= (1<<CS12 | 0<<CS11 | 0<<CS10)	; timer frequentie = CK/256
.equ TIMER_1_CLOCK_PRESCALE_CK1024	= (1<<CS12 | 0<<CS11 | 1<<CS10)	; timer frequentie = CK/1024
.equ TIMER_1_CLOCK_EXT_FALLINGEDGE	= (1<<CS12 | 1<<CS11 | 0<<CS10)	; timer frequentie = Ext. pin T1 op neergaande flank
.equ TIMER_1_CLOCK_EXT_RISINGEDGE	= (1<<CS12 | 1<<CS11 | 1<<CS10)	; timer frequentie = Ext. pin T1 op opgaande flank
;--------------------------------------------
; De Timer1Counter (hardwarematig/automatisch) wissen (op 0 zetten) bij een Timer1-CompareA match
.equ TIMER_1_CLEARCOUNTER_ON_MATCHA			= (1<<CTC1)
; De Input-Capture-trigger Noise Canceler
.equ TIMER_1_INPUTCAPTURE_NOISECANCELER		= (1<<ICNC1)	; inschakelen/gebruiken
.equ TIMER_1_INPUTCAPTURE_NOISECANCELER_OFF	= (0<<ICNC1)	; niet opgeven kan ook, en is korter ;)
; De Input Capture Edge Select
.equ TIMER_1_INPUTCAPTURE_ON_RISINGEDGE		= (1<<ICES1)
.equ TIMER_1_INPUTCAPTURE_ON_FALLINGEDGE	= (0<<ICES1)



;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			Timer1Clock_Off
;--- Beschrijving:	De Timer-1 stoppen
;--------------------------------------------
.MACRO Timer1Clock_Off
	in		R16, TCCR1B
	andi	R16, ~(1<<CS12 | 1<<CS11 | 1<<CS10) ;0b11111000
	;ori	R16, TIMER_1_CLOCK_OFF
	out		TCCR1B, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer1Clock_PrescaleCK
;--- Beschrijving:	De Timer-1 prescalen op CK (TCK=CK)
;--------------------------------------------
.MACRO Timer1Clock_PrescaleCK
	in		R16, TCCR1B
	andi	R16, ~(1<<CS12 | 1<<CS11 | 1<<CS10) ;0b11111000
	ori		R16, TIMER_1_CLOCK_PRESCALE_CK
	out		TCCR1B, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer1Clock_PrescaleCK8
;--- Beschrijving:	De Timer-1 prescalen op CK/8 (TCK=CK/8)
;--------------------------------------------
.MACRO Timer1Clock_PrescaleCK8
	in		R16, TCCR1B
	andi	R16, ~(1<<CS12 | 1<<CS11 | 1<<CS10) ;0b11111000
	ori		R16, TIMER_1_CLOCK_PRESCALE_CK8
	out		TCCR1B, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer1Clock_PrescaleCK64
;--- Beschrijving:	De Timer-1 prescalen op CK/64 (TCK=CK/64)
;--------------------------------------------
.MACRO Timer1Clock_PrescaleCK64
	in		R16, TCCR1B
	andi	R16, ~(1<<CS12 | 1<<CS11 | 1<<CS10) ;0b11111000
	ori		R16, TIMER_1_CLOCK_PRESCALE_CK64
	out		TCCR1B, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer1Clock_PrescaleCK256
;--- Beschrijving:	De Timer-1 prescalen op CK/256 (TCK=CK/256)
;--------------------------------------------
.MACRO Timer1Clock_PrescaleCK256
	in		R16, TCCR1B
	andi	R16, ~(1<<CS12 | 1<<CS11 | 1<<CS10) ;0b11111000
	ori		R16, TIMER_1_CLOCK_PRESCALE_CK256
	out		TCCR1B, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer1Clock_PrescaleCK1024
;--- Beschrijving:	De Timer-1 prescalen op CK/1024 (TCK=CK/1024)
;--------------------------------------------
.MACRO Timer1Clock_PrescaleCK1024
	in		R16, TCCR1B
	andi	R16, ~(1<<CS12 | 1<<CS11 | 1<<CS10) ;0b11111000
	ori		R16, TIMER_1_CLOCK_PRESCALE_CK1024
	out		TCCR1B, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer1Clock_External_FallingEdge
;--- Beschrijving:	De Timer-1 extern timen, tellen op een neergaande flank (TCK<\PB1 "T1")
;---				(pulzen tellen op elke neergaande flank)
;--------------------------------------------
.MACRO Timer1Clock_External_FallingEdge
	in		R16, TCCR1B
	andi	R16, ~(1<<CS12 | 1<<CS11 | 1<<CS10) ;0b11111000
	ori		R16, TIMER_1_CLOCK_EXT_FALLINGEDGE
	out		TCCR1B, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Timer1Clock_External_RisingEdge
;--- Beschrijving:	De Timer-1 extern timen, tellen op een opgaande flank (TCK<\PB1 "T1")
;---				(pulzen tellen op elke opgaande flank)
;--------------------------------------------
.MACRO Timer1Clock_External_RisingEdge
	in		R16, TCCR1B
	andi	R16, ~(1<<CS12 | 1<<CS11 | 1<<CS10) ;0b11111000
	ori		R16, TIMER_1_CLOCK_EXT_RISINGEDGE
	out		TCCR1B, R16
.ENDMACRO



;--------------------------------------------
;--- Naam:			InputCapture1_OnFallingEdge
;--- Beschrijving:	Bij InputCapturing reageren op een neergaande flank
;--------------------------------------------
.MACRO InputCapture1_OnFallingEdge
	cbi		TCCR1B, ICES1
.ENDMACRO

;--------------------------------------------
;--- Naam:			InputCapture1_OnRisingEdge
;--- Beschrijving:	Bij InputCapturing reageren op een opgaande flank
;--------------------------------------------
.MACRO InputCapture1_OnRisingEdge
	sbi		TCCR1B, ICES1
.ENDMACRO

;--------------------------------------------
;--- Naam:			InputCapture1_ToggleEdge
;--- Beschrijving:	Bij InputCapturing reageren op de "andere/omgekeerde" flank
;--------------------------------------------
.MACRO InputCapture1_ToggleEdge
	sbic	TCCR1B, ICES1
	rjmp	_1					; bit is nu 1
_0:
	InputCapture1_OnRisingEdge
	rjmp	_2
_1:	; ..nu ingesteld om InputCapture-interrupts te genereren op rising-edge
	; Dus nu instellen om interrupts te krijgen op een falling-edge..
	InputCapture1_OnFallingEdge
_2:
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
;--- Timer-1 Interrupt Enable
;--------------------------------------------
.equ TIMER_1_INTERRUPTENABLE_COMPAREMATCHA	= (1<<OCIE1A)
.equ TIMER_1_INTERRUPTENABLE_COMPAREMATCHB	= (1<<OCIE1B)
.equ TIMER_1_INTERRUPTENABLE_OVERFLOW		= (1<<TOIE1)
.equ TIMER_1_INTERRUPTENABLE_INPUTCAPTURE	= (1<<TICIE1)





;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			Disable_Interrupt_CompareMatch1A
;--- Beschrijving:	Interrupt uitschakelen voor Timer-1 Compare-Match A
;--------------------------------------------
.MACRO Disable_Interrupt_CompareMatch1A
;	cbi		TIMSK, OCIE1A
	in		R16, TIMSK
	andi	R16, ~(1<<OCIE1A)
	out		TIMSK, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Disable_Interrupt_CompareMatch1B
;--- Beschrijving:	Interrupt uitschakelen voor Timer-1 Compare-Match B
;--------------------------------------------
.MACRO Disable_Interrupt_CompareMatch1B
	cbi		TIMSK, OCIE1B
.ENDMACRO

;--------------------------------------------
;--- Naam:			Disable_Interrupt_Overflow1
;--- Beschrijving:	Interrupt uitschakelen voor Timer-1 Overflow
;--------------------------------------------
.MACRO Disable_Interrupt_Overflow1
	cbi		TIMSK, TOIE1
.ENDMACRO

;--------------------------------------------
;--- Naam:			Disable_Interrupt_InputCapture1
;--- Beschrijving:	Interrupt uitschakelen voor Timer-1 Input-Capture
;--------------------------------------------
.MACRO Disable_Interrupt_InputCapture1
	cbi		TIMSK, TICIE1
.ENDMACRO


;--------------------------------------------
;--- Naam:			Enable_Interrupt_CompareMatch1A
;--- Beschrijving:	Interrupt inschakelen voor Timer-1 Compare-Match A
;--------------------------------------------
.MACRO Enable_Interrupt_CompareMatch1A
;	sbi		TIMSK, OCIE1A
	in		R16, TIMSK
	ori		R16, (1<<OCIE1A)
	out		TIMSK, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Enable_Interrupt_CompareMatch1B
;--- Beschrijving:	Interrupt inschakelen voor Timer-1 Compare-Match B
;--------------------------------------------
.MACRO Enable_Interrupt_CompareMatch1B
	sbi		TIMSK, OCIE1B
.ENDMACRO

;--------------------------------------------
;--- Naam:			Enable_Interrupt_Overflow1
;--- Beschrijving:	Interrupt inschakelen voor Timer-1 Overflow
;--------------------------------------------
.MACRO Enable_Interrupt_Overflow1
	sbi		TIMSK, TOIE1
.ENDMACRO

;--------------------------------------------
;--- Naam:			Enable_Interrupt_InputCapture1
;--- Beschrijving:	Interrupt inschakelen voor Timer-1 Input-Capture
;--------------------------------------------
.MACRO Enable_Interrupt_InputCapture1
	sbi		TIMSK, TICIE1
.ENDMACRO



;--------------------------------------------
;--- Naam:			Get_TimerCounter1
;--- Beschrijving:	TimerCounter-1 opvragen in registers "ValueL" & "ValueH"
;--------------------------------------------
.MACRO Get_TimerCounter1;(ValueH,ValueL : register)
	in		@1, TCNT1L
	in		@0, TCNT1H
.ENDMACRO

;--------------------------------------------
;--- Naam:			Set_TimerCounter1
;--- Beschrijving:	TimerCounter-1 instellen; Registers "ValueH" & "ValueL" bevatten de nieuwe teller-waarde
;--------------------------------------------
.MACRO Set_TimerCounter1;(ValueH,ValueL : register)
	out		TCNT1H, @0
	out		TCNT1L, @1
.ENDMACRO

;--------------------------------------------
;--- Naam:			SetI_TimerCounter1
;--- Beschrijving:	TimerCounter-1 instellen op een opgegeven constante (16-bits) waarde
;--------------------------------------------
.MACRO SetI_TimerCounter1;(Value : 16bit-constante)
	ldi		R16, low(@0)
	ldi		R17, high(@0)
	out		TCNT1H, R17
	out		TCNT1L, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Clear_TimerCounter1
;--- Beschrijving:	TimerCounter-1 wissen / waarde op 0
;--------------------------------------------
.MACRO Clear_TimerCounter1
	clr		R16
	out		TCNT1H, R16
	out		TCNT1L, R16
.ENDMACRO



;--------------------------------------------
;--- Naam:			Get_Compare1A
;--- Beschrijving:	De Timer-1 Compare-A waarde opvragen in registers "ValueL" & "ValueH"
;--------------------------------------------
.MACRO Get_Compare1A;(ValueH,ValueL : register)
	in		@1, OCR1AL
	in		@0, OCT1AH
.ENDMACRO

;--------------------------------------------
;--- Naam:			Set_Compare1A
;--- Beschrijving:	De Timer-1 Compare-A instellen: Registers "ValueH" & "ValueL" bevatten de nieuwe teller-waarde
;--------------------------------------------
.MACRO Set_Compare1A;(ValueH,ValueL: register)
	out		OCR1AH, @0
	out		OCR1AL, @1
.ENDMACRO

;--------------------------------------------
;--- Naam:			SetI_Compare1A
;--- Beschrijving:	De Timer-1 Compare-A waarde instellen op een opgegeven constante (16-bits) waarde
;--------------------------------------------
.MACRO SetI_Compare1A;(Value : 16bit-constante)
	ldi		R16, low(@0)
	ldi		R17, high(@0)
	out		OCR1AH, R17
	out		OCR1AL, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			Set_Compare1B
;--- Beschrijving:	De Timer-1 Compare-B instellen: Registers "ValueH" & "ValueL" bevatten de nieuwe teller-waarde
;--------------------------------------------
.MACRO Set_Compare1B;(ValueH,ValueL: register)
	out		OCR1BH, @0
	out		OCR1BL, @1
.ENDMACRO

;--------------------------------------------
;--- Naam:			SetI_Compare1B
;--- Beschrijving:	De Timer-1 Compare-B waarde instellen op een opgegeven constante (16-bits) waarde
;--------------------------------------------
.MACRO SetI_Compare1B;(Value : 16bit-constante)
	ldi		R16, low(@0)
	ldi		R17, high(@0)
	out		OCR1BH, R17
	out		OCR1BL, R16
.ENDMACRO



;--------------------------------------------
;--- Naam:			Get_InputCapture1
;--- Beschrijving:	De Timer-1 Input-Capture waarde opvragen in registers "ValueL" & "ValueH"
;--------------------------------------------
.MACRO Get_InputCapture1;(ValueH,ValueL : register)
	in		@1, ICR1L
	in		@0, ICR1H
.ENDMACRO

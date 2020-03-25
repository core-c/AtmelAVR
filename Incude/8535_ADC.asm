;---------------------------------------------------------------------------------
;---
;---  Analog-Digital Converter constanten en macro's		Ron Driessen
;---  AVR AT90S8535											2005
;---
;---------------------------------------------------------------------------------
.ifndef Linked_8535_ADC
	.ifndef Link_8535_ADC						; Deze unit markeren als zijnde ingelinkt,
		.equ Link_8535_ADC = 1					; in geval dat nog niet eerder is gebeurd in code.
	.endif										; (Units nl. maar 1x inlinken)
	.equ Linked_8535_ADC = 1					;
.endif




;---------------------------------------------------------------------------------
;--- ADMUX	- Analog-Digital MUltipleXer select register
;---
;---	bit  7        6        5        4        3        2        1        0
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	|        |        |        |        |        |  MUX2  |  MUX1  |  MUX0  |
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	Bit 7..3						Reserved Bits
;---	Bit 2..0	MUX2,MUX1,MUX0		Analog Channel Select Bits 2-0
;---
;---------------------------------------------------------------------------------



;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			Get_ADC_Channel
;--- Beschrijving:	Het huidige ADC-multiplexer kanaal opvragen in register "Value"
;--------------------------------------------
.MACRO Get_ADC_Channel;(Value : register)
	in		@0, ADMUX
.ENDMACRO

;--------------------------------------------
;--- Naam:			Set_ADC_Channel
;--- Beschrijving:	selecteer een ADC-kanaal voor input
;--------------------------------------------
.MACRO Set_ADC_Channel;(Value: register)
	out		ADMUX, @0
.ENDMACRO

;--------------------------------------------
;--- Naam:			SetI_ADC_Channel
;--- Beschrijving:	selecteer een ADC-kanaal voor input
;--------------------------------------------
.MACRO SetI_ADC_Channel;(Value: 8bit-constante)
	ldi		R16, @0
	out		ADMUX, R16
.ENDMACRO





;---------------------------------------------------------------------------------
;--- ADCSR	- Analog-Digital Converter control and Status Register
;---
;---	bit  7        6        5        4        3        2        1        0
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	|  ADEN  |  ADSC  |  ADFR  |  ADIF  |  ADIE  |  ADPS2 |  ADPS1 |  ADPS0 |
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	Bit 7		ADEN				ADC Enable
;---	Bit 6		ADSC				ADC Start Conversion
;---	Bit 5		ADFR				ADC Free Running Select
;---	Bit 4		ADIF				ADC Interrupt Flag
;---	Bit 3		ADIE				ADC Interrupt Enable
;---	Bit 2..0	ADPS2,ADPS1,ADPS0	ADC Prescaler Select Bits	
;---
;---------------------------------------------------------------------------------


;--------------------------------------------
;--- ADC Prescale
;--------------------------------------------
;.equ ADC_CLOCK_PRESCALE_CK		= (0<<CS02 | 0<<CS01 | 0<<CS00)	; ADC samplerate = CK		; CK/2 ??
.equ ADC_CLOCK_PRESCALE_CK2		= (0<<CS02 | 0<<CS01 | 1<<CS00)	; ADC samplerate = CK/2
.equ ADC_CLOCK_PRESCALE_CK4		= (0<<CS02 | 1<<CS01 | 0<<CS00)	; ADC samplerate = CK/4
.equ ADC_CLOCK_PRESCALE_CK8		= (0<<CS02 | 1<<CS01 | 1<<CS00)	; ADC samplerate = CK/8
.equ ADC_CLOCK_PRESCALE_CK16	= (1<<CS02 | 0<<CS01 | 0<<CS00)	; ADC samplerate = CK/16
.equ ADC_CLOCK_PRESCALE_CK32	= (1<<CS02 | 0<<CS01 | 1<<CS00)	; ADC samplerate = CK/32
.equ ADC_CLOCK_PRESCALE_CK64	= (1<<CS02 | 1<<CS01 | 0<<CS00)	; ADC samplerate = CK/64
.equ ADC_CLOCK_PRESCALE_CK128	= (1<<CS02 | 1<<CS01 | 1<<CS00)	; ADC samplerate = CK/128

.equ ADC_FREERUNNING_MODE		= (1<<ADFR)
.equ ADC_SINGLECONVERSION_MODE	= (0<<ADFR)

.equ ADC_INTERRUPTENABLE		= (1<<ADIE)		; Conversion-Complete interrupt



;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			ConfigTimer0
;--- Beschrijving:	Timer-0 instellen
;--------------------------------------------
.MACRO Config_ADC;(instelling: register)
	out		ADCSR, @0
.ENDMACRO

;--------------------------------------------
;--- Naam:			Initialize_ADC
;--- Beschrijving:	De ADC poort/pinnen initialiseren voor ADC gebruik
;---				(het masker bevat een 1 voor elke pin (A0-A7) waarvoor ADC moet worden gebruikt)
;--------------------------------------------
.MACRO Initialize_ADC;(kanaal-masker: register)
	; Poort A pinnen als input instellen
	com		@0								; input=0, output=1
	out		DDRA, @0
.ENDMACRO

;--------------------------------------------
;--- Naam:			Initialize_ADC_Channel0
;--- Beschrijving:	De ADC pin initialiseren voor ADC kanaal 0 gebruik
;--------------------------------------------
.MACRO Initialize_ADC_Channel0
	cbi		DDRA, PA0
.ENDMACRO

;--------------------------------------------
;--- Naam:			Initialize_ADC_Channel1
;--- Beschrijving:	De ADC pin initialiseren voor ADC kanaal 1 gebruik
;--------------------------------------------
.MACRO Initialize_ADC_Channel1
	cbi		DDRA, PA1
.ENDMACRO

;--------------------------------------------
;--- Naam:			Initialize_ADC_Channel2
;--- Beschrijving:	De ADC pin initialiseren voor ADC kanaal 2 gebruik
;--------------------------------------------
.MACRO Initialize_ADC_Channel2
	cbi		DDRA, PA2
.ENDMACRO

;--------------------------------------------
;--- Naam:			Initialize_ADC_Channel3
;--- Beschrijving:	De ADC pin initialiseren voor ADC kanaal 3 gebruik
;--------------------------------------------
.MACRO Initialize_ADC_Channel3
	cbi		DDRA, PA3
.ENDMACRO

;--------------------------------------------
;--- Naam:			Initialize_ADC_Channel4
;--- Beschrijving:	De ADC pin initialiseren voor ADC kanaal 4 gebruik
;--------------------------------------------
.MACRO Initialize_ADC_Channel4
	cbi		DDRA, PA4
.ENDMACRO

;--------------------------------------------
;--- Naam:			Initialize_ADC_Channel5
;--- Beschrijving:	De ADC pin initialiseren voor ADC kanaal 5 gebruik
;--------------------------------------------
.MACRO Initialize_ADC_Channel5
	cbi		DDRA, PA5
.ENDMACRO

;--------------------------------------------
;--- Naam:			Initialize_ADC_Channel6
;--- Beschrijving:	De ADC pin initialiseren voor ADC kanaal 6 gebruik
;--------------------------------------------
.MACRO Initialize_ADC_Channel6
	cbi		DDRA, PA6
.ENDMACRO

;--------------------------------------------
;--- Naam:			Initialize_ADC_Channel7
;--- Beschrijving:	De ADC pin initialiseren voor ADC kanaal 7 gebruik
;--------------------------------------------
.MACRO Initialize_ADC_Channel7
	cbi		DDRA, PA7
.ENDMACRO


;--------------------------------------------
;--- Naam:			Disable_Interrupt_ADC
;--- Beschrijving:	Interrupt voor ADC uitschakelen
;--------------------------------------------
.MACRO Disable_Interrupt_ADC
	cbi		ADCSR, ADIE
.ENDMACRO

;--------------------------------------------
;--- Naam:			Enable_Interrupt_ADC
;--- Beschrijving:	Interrupt Enable voor ADC
;--------------------------------------------
.MACRO Enable_Interrupt_ADC
	sbi		ADCSR, ADIE
.ENDMACRO



;--------------------------------------------
;--- Naam:			Disable_ADC
;--- Beschrijving:	Het ADC uitschakelen
;--------------------------------------------
.MACRO Disable_ADC
	cbi		ADCSR, ADEN
.ENDMACRO

;--------------------------------------------
;--- Naam:			Enable_ADC
;--- Beschrijving:	Het ADC inschakelen
;--------------------------------------------
.MACRO Enable_ADC
	sbi		ADCSR, ADEN
.ENDMACRO



;--------------------------------------------
;--- Naam:			Get_ADC_SampleValue
;--- Beschrijving:	De laatste sample lezen
;--------------------------------------------
.MACRO Get_ADC_SampleValue;(ValueL,ValueH: register)
	in		@0, ADCL						; de 10-bit sample lezen in 2 de opgegeven registers
	in		@1, ADCH
.ENDMACRO

;--------------------------------------------
;--- Naam:			Sample_ADC
;--- Beschrijving:	1 single-conversion sample maken en resultaat teruggeven in registers "ValueL" & "ValueH"
;--------------------------------------------
.MACRO Sample_ADC;(ValueL,ValueH: register)
	sbi		ADCSR, ADSC						; een conversie starten
_0:	sbic	ADCSR, ADSC						; wachten op End-Of-Conversion sein
	rjmp	_0
	in		@0, ADCL						; de 10-bit sample lezen in 2 de opgegeven registers
	in		@1, ADCH
.ENDMACRO

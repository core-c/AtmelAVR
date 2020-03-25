
;*******************************************************************************
;*** Software-matige PWM. 16-bit timer1
;*** met Overflow A-, Overflow B- & Compare-Interrupts.
;***
;***  Onze AVR's clockspeed bedraagt 7.3728 Mhz  =  7372800 Hz
;***  De Timer1-frequentie wordt afgeleid van de clockspeed van de AVR. Deze timer-
;***  frequentie kan gedeeld worden (prescaled) om lagere frequenties te gebruiken.
;***  Alle mogelijk in te stellen timer-frequenties :
;***	clockspeed			= 7372800 Hz
;***	clockspeed / 8		= 7372800 /8	= 921600 Hz
;***	clockspeed / 64		= 7372800 /64	= 115200 Hz
;***	clockspeed / 256	= 7372800 /256	= 28800 Hz
;***	clockspeed / 1024	= 7372800 /1024	= 7200 Hz
;*** 
;***  Als de AVR in PWM-mode werkt, wordt de uiteindelijke PWM-frequentie bepaalt door
;***  de PWM-resolutie; 8-, 9- of 10-bits PWM :
;***	 8 bits PWM : PWM-frequentie = Timer-frequentie / 510
;***	 9 bits PWM : PWM-frequentie = Timer-frequentie / 1022
;***	10 bits PWM : PWM-frequentie = Timer-frequentie / 2046
;***  De PWM-resolutie bepaalt ook de TOP-waarde van de Timer-Counter :
;***	 8 bits PWM : Timer-Counter TOP =	00FF	0000000011111111	 255
;***	 9 bits PWM : Timer-Counter TOP =	01FF	0000000111111111	 511
;***	10 bits PWM : Timer-Counter TOP =	03FF	0000001111111111	1023
;***
;*************************************************************************************
;
.include "8535def.inc"
;--- De clock-frequentie (CK) van onze AVR (in Hz.)
.equ CK = 7372800
;--- 1 seconde bij verschillende TCK prescalers
.equ SECONDE_CK1024		= CK/1024		;  7200 = $1C20
.equ SECONDE_CK256		= CK/256		; 28800	= $7080
;.equ SECONDE_CK64		= CK/64
;.equ SECONDE_CK8		= CK/8
;.equ SECONDE_CK		= CK


;--- Timer frequenties -----------------
.equ TIMERFREQ_CK1024	= (1<<CS12 | 0<<CS11 | 1<<CS10)	; timerFrequentie = clock/1024 
.equ TIMERFREQ_CK256	= (1<<CS12 | 0<<CS11 | 0<<CS10)	; timerFrequentie = clock/256
.equ TIMERFREQ_CK64		= (0<<CS12 | 1<<CS11 | 1<<CS10)	; timerFrequentie = clock/64
.equ TIMERFREQ_CK8		= (0<<CS12 | 1<<CS11 | 0<<CS10)	; timerFrequentie = clock/8
.equ TIMERFREQ_CK		= (0<<CS12 | 0<<CS11 | 1<<CS10)	; timerFrequentie = clock
.equ TIMERFREQ_OFF		= (0<<CS12 | 0<<CS11 | 0<<CS10)	; timer uitschakelen
;--- Timer Flags -----------------------
.equ TIMER1_OVERFLOW	= (1<<TOIE1)
.equ TIMER1_COMPAREA	= (1<<OCIE1A)
.equ TIMER1_COMPAREB	= (1<<OCIE1B)


;--- Hardware PWM-modes ----------------
.equ PWM_OFF	= (0<<PWM11  | 0<<PWM10)
.equ PWM_8BITS	= (0<<PWM11  | 1<<PWM10)
.equ PWM_9BITS	= (1<<PWM11  | 0<<PWM10)
.equ PWM_10BITS	= (1<<PWM11  | 1<<PWM10)
; COM1B1:COM1B0  =>  1:0=non inverted PWM, 1:1=inverted PWM  (bij gebruik CompareB)
.equ PWM_NON_INVERTED_1B	= (1<<COM1B1 | 0<<COM1B0)
.equ PWM_INVERTED_1B		= (1<<COM1B1 | 1<<COM1B0)
; COM1A1:COM1A0  =>  1:0=non inverted PWM, 1:1=inverted PWM  (bij gebruik CompareA)
.equ PWM_NON_INVERTED_1A	= (1<<COM1A1 | 0<<COM1A0)
.equ PWM_INVERTED_1A		= (1<<COM1A1 | 1<<COM1A0)
;
.equ PWM_8BITS_NON_INVERTED_1B	= (PWM_8BITS  | PWM_NON_INVERTED_1B)
.equ PWM_9BITS_NON_INVERTED_1B	= (PWM_9BITS  | PWM_NON_INVERTED_1B)
.equ PWM_10BITS_NON_INVERTED_1B	= (PWM_10BITS | PWM_NON_INVERTED_1B)
.equ PWM_8BITS_INVERTED_1B		= (PWM_8BITS  | PWM_INVERTED_1B)
.equ PWM_9BITS_INVERTED_1B		= (PWM_9BITS  | PWM_INVERTED_1B)
.equ PWM_10BITS_INVERTED_1B		= (PWM_10BITS | PWM_INVERTED_1B)
;
.equ PWM_8BITS_NON_INVERTED_1A	= (PWM_8BITS  | PWM_NON_INVERTED_1A)
.equ PWM_9BITS_NON_INVERTED_1A	= (PWM_9BITS  | PWM_NON_INVERTED_1A)
.equ PWM_10BITS_NON_INVERTED_1A	= (PWM_10BITS | PWM_NON_INVERTED_1A)
.equ PWM_8BITS_INVERTED_1A		= (PWM_8BITS  | PWM_INVERTED_1A)
.equ PWM_9BITS_INVERTED_1A		= (PWM_9BITS  | PWM_INVERTED_1A)
.equ PWM_10BITS_INVERTED_1A		= (PWM_10BITS | PWM_INVERTED_1A)
;
.equ PWM_8BITS_TOP	= 0b11111111		; De TOP-waarde voor 8-bits = 2^8 - 1	(HW-PWM)
.equ PWM_9BITS_TOP	= 0b111111111		; De TOP-waarde voor 9-bits = 2^9 - 1	(HW-PWM)
.equ PWM_10BITS_TOP	= 0b1111111111		; De TOP-waarde voor 10-bits = 2^10 - 1	(HW-PWM)
;--- Software PWM ----------------------
; COM1A1:COM1A0  HW pin PD5 (OC1A) output on CompareA Match
.equ PWM_COMPAREA_ACTION_OFF	= (0<<COM1A1 | 0<<COM1A0)	; geen actie op pin D5
.equ PWM_COMPAREA_ACTION_TOGGLE	= (0<<COM1A1 | 1<<COM1A0)	; toggle PinD5
.equ PWM_COMPAREA_ACTION_0		= (1<<COM1A1 | 0<<COM1A0)	; PinD5 op 0
.equ PWM_COMPAREA_ACTION_1		= (1<<COM1A1 | 1<<COM1A0)	; PinD5 op 1
; COM1B1:COM1B0  HW pin PD4 (OC1B) output on CompareB Match
.equ PWM_COMPAREB_ACTION_OFF	= (0<<COM1B1 | 0<<COM1B0)	; geen actie op pin D4
.equ PWM_COMPAREB_ACTION_TOGGLE	= (0<<COM1B1 | 1<<COM1B0)	; toggle PinD4
.equ PWM_COMPAREB_ACTION_0		= (1<<COM1B1 | 0<<COM1B0)	; PinD4 op 0
.equ PWM_COMPAREB_ACTION_1		= (1<<COM1B1 | 1<<COM1B0)	; PinD4 op 1

.equ PWM_16BITS_TOP	= 0b1111111111111111; De TOP-waarde voor 16-bits = 2^16 - 1	(SW-PWM)
;--- De timer1 TOP-waarde op 16-bits instellen
.equ TOP			= PWM_16BITS_TOP
;---------------------------------------





;--- Deze waarden naar believen aanpassen....
; De Timer1 prescale
;.equ MY_TIMER_FREQ	= TIMERFREQ_CK1024
.equ MY_TIMER_FREQ	= TIMERFREQ_CK256
;.equ MY_TIMER_FREQ	= TIMERFREQ_CK64
;.equ MY_TIMER_FREQ	= TIMERFREQ_CK8
;.equ MY_TIMER_FREQ	= TIMERFREQ_CK

; De te gebruiken duty-cycle (in procenten)
.equ MY_DUTY_CYCLE	= 10

; mbv. webpagina uitgerekende waarden
.equ PWM_FREQ		= 28800							;@@ 
.equ DUTY_CYCLE		= PWM_FREQ/100*MY_DUTY_CYCLE	;@@ 

; De PWM-frequentie (in Hz.)
;@@ .equ MY_PWM_FREQ	= 1
;---------------------------------------....
;
; De Software PWM TOP-waarde instellen (PWM-frequentie)
; Dit is de CompareA waarde.
;@@ .equ PWM_FREQ		= MY_PWM_FREQ * SECONDE_CK256
;--- De Timer1 CompareB-waarde ----------
;@@ .equ DUTY_CYCLE		= PWM_FREQ/100*MY_DUTY_CYCLE




;--- Register synoniemen ---------------
.def temp	= R16
.def tempL	= R17
.def Treg	= R20						; regsiter tbv. de timer-handler
;.def status	= R22						; de backup tbv. het CPU-satus register




;--- Macro's ---------------------------
.MACRO SET_STACKPOINTER
	ldi		temp, high(RAMEND)
	ldi		tempL, low(RAMEND)
	out		SPH, temp
	out		SPL, tempL
.ENDMACRO

.MACRO SET_PIN_AS_OUTPUT;(Poort: byte; Pin : bit-nummer)
	; Éen bit van een poort als output zetten
	clr		temp
	ori		temp, (1<<@1)				; argument(1) is de Pin
	out		@0, temp					; argument(0) is de Poort
.ENDMACRO

.MACRO SET_PINS_AS_OUTPUT;(Poort: byte; Pins : byte-mask)
	clr		temp
	ori		temp, @1					; argument(1) is het Pins-masker
	out		@0, temp					; argument(0) is de Poort
.ENDMACRO

.MACRO SET_LEDS;(Poort: byte; Pins : byte-mask)
	ldi		temp, @1
	out		@0, temp
.ENDMACRO

.MACRO SET_PWM_DUTYCYCLE_1B;(CompareB-waarde : word)
	ldi		temp, high(@0)				; argument(0) is de pulsbreedte (CompareB-waarde)
	ldi		tempL, low(@0)
	out		OCR1BH, temp
	out		OCR1BL, tempL
.ENDMACRO

.MACRO SET_PWM_FREQ_1A;(CompareA-waarde : word)
	ldi		temp, high(@0)				; argument(0) is de PWM-frequentie (CompareA-waarde)
	ldi		tempL, low(@0)
	out		OCR1AH, temp
	out		OCR1AL, tempL
.ENDMACRO

.MACRO SET_TIMER1_PWM_MODE;(PWM-mode : byte)
	ldi		temp, @0					; argument(0) is de PWM-mode byte
	out		TCCR1A, temp 
.ENDMACRO

.MACRO SET_TIMER1FREQ;(frequentie : byte)
	ldi		temp, @0					; argument(0) is de Timer1-Clock
	out		TCCR1B, temp
.ENDMACRO

.MACRO RESET_TIMER1COUNTER_ON_COMPAREA
	in		temp, TCCR1B
	ori		temp, (1<<CTC1)				; CTC1 = clear timer-counter on compare match A
	out		TCCR1B, temp
.ENDMACRO

.MACRO CLEAR_TIMER1COUNTER
	clr		temp
	out		TCNT1H, temp
	out		TCNT1L, temp
.ENDMACRO

.MACRO RESET_TIMER1COUNTER;(TOP : word)
	ldi		temp, @0
	out		TCNT1H, temp
	out		TCNT1L, temp
.ENDMACRO

.MACRO USE_INTERRUPTS;(InterruptFlags : byte-mask)
	in		temp, TIMSK					; Het Timer-Interrupt-Mask-Register aanspreken
	ori		temp, @0					; argument(0) is het Interrupt-Enable-Flag masker
	out		TIMSK, temp
.ENDMACRO

.MACRO MAIN_LOOP
eLoop:
	rjmp eLoop							; eeuwige lus....
.ENDMACRO





; Het begin van het CODE-segment
.cseg
;--- De vector-tabel -------------------
.org 0x0000								; Het begin van de vector-tabel op adres 0 van het RAM
	rjmp RESET							; Reset Handler
	reti								;External Interrupt0 Vector Address
	reti								;External Interrupt1 Vector Address
	reti								;Timer2 compare match Vector Address
	reti								;Timer2 overflow Vector Address
	reti								;Timer1 Input Capture Vector Address
	rjmp Timer_Interrupt_CompareA		;Timer1 Output Compare A Interrupt Vector Address
	rjmp Timer_Interrupt_CompareB		;Timer1 Output Compare B Interrupt Vector Address
	reti								;Overflow1 Interrupt Vector Address
	reti								;Overflow0 Interrupt Vector Address
	reti								;SPI Interrupt Vector Address
	reti								;UART Receive Complete Interrupt Vector Address
	reti								;UART Data Register Empty Interrupt Vector Address
	reti								;UART Transmit Complete Interrupt Vector Address
	reti								;ADC Conversion Complete Interrupt Vector Address
	reti								;EEPROM Write Complete Interrupt Vector Address
	reti								;Analog Comparator Interrupt Vector Address
;---------------------------------------




RESET:
	; De stack-pointer instellen op het einde van het RAM
	SET_STACKPOINTER
	; zorg ervoor dat geen interrupts voorvallen tijdens zetten van deze PWM-mode
	cli
	clr		temp
	out		TIMSK, temp

	;nog even wat LED's aanzetten ter indicatie dat de AVR runt.
	SET_PINS_AS_OUTPUT DDRC, (1<<PINC3 | 1<<PINC2 | 1<<PINC1 | 1<<PINC0)
	; 4 LED's aan bij 16-bits software PWM
	SET_LEDS PORTC, (1<<PINC3 | 1<<PINC2 | 1<<PINC1 | 1<<PINC0)


	; poort D pin 4 (OC1B) als output zetten voor de PWM output-pin
	SET_PIN_AS_OUTPUT DDRD, PIND4

	; Hardware-matige PWM uitschakelen, hardware-matige pin-output ook uitschakelen.
	; We gebruiken alleen de timer-counter en compare registers voor de telling.
	; De pin-out regelen we zelf in de onCompare(A & B)Match handlers.
	SET_TIMER1_PWM_MODE	(PWM_COMPAREA_ACTION_OFF | PWM_COMPAREB_ACTION_OFF | PWM_OFF)
;	SET_TIMER1_PWM_MODE	(PWM_COMPAREA_ACTION_1 | PWM_COMPAREB_ACTION_0 | PWM_OFF)

	; Timer1 clock instellen.
	SET_TIMER1FREQ MY_TIMER_FREQ	
	; De Timer1-Counter resetten op een CompareA Match
	RESET_TIMER1COUNTER_ON_COMPAREA
	
	; De PWM TOP-waarde instellen (PWM-frequentie)
	SET_PWM_FREQ_1A PWM_FREQ
	; De duty-cycle instellen op een 16-bit waarde
	SET_PWM_DUTYCYCLE_1B DUTY_CYCLE

	; de counter op 0 instellen om direct met een puls te beginnen
	;CLEAR_TIMER1COUNTER
	RESET_TIMER1COUNTER PWM_FREQ-1

	USE_INTERRUPTS (TIMER1_COMPAREA | TIMER1_COMPAREB)

	; interrupts weer inschakelen
	sei

	MAIN_LOOP








;--- De Timer-Compare-A Interrupt routine -------------------------------------------
Timer_Interrupt_CompareA:
	sbi		PORTD, PIND4				; Pin D4 hoog maken
;	; de counter resetten
;	clr		Treg
;	out		TCNT1H, Treg
;	out		TCNT1L, Treg
	; omdat de CTC1 bit in het TCCR1B register wordt de counter
	; "automatisch" op 0 gezet bij een CompareA match.
	reti





;--- De Timer-Compare-B Interrupt routine -------------------------------------------
Timer_Interrupt_CompareB:
	; Een timer-compare interrupt komt voor als de timer-teller de compare-waarde
	; heeft afgeteld. De CompareB-waarde representeert de pulsbreedte.
	; Als een compare-interrupt plaatsvindt moeten we de pin zelf weer laag maken.
	;
	cbi		PORTD, PIND4				; pin laag maken
	reti

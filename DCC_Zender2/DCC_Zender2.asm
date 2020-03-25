;-------------------------------------------------------------------
;--- Een DCC-Zender voor de trein-modelbouw
;---
;---	Output op Pin D6 op de AT90S8535
;---	CK = 8 MHz
;---	TCK = CK /8, dus een timertick per microseconde
;---	DCC protocol: "1" duur 58us, "0" duur 100us
;---	              "1" duur 58 ticks, "0" 100 ticks
;---	De tijd tussen 2 packets moet zijn tenminste 5 ms.
;---
;---	          __    __
;---	         |  |  |  |  |
;---	         |  |  |  |  |		|
;---	------+--+  +--+  +--+		+ = signaal door deze AVR gemaakt
;---	      .  .  .  .  .  .
;---	      .  .  .  .  .  .		.
;---	      ....  ....  ....		. = signaal door booster gemaakt
;---
;---	      *     *     *			* = instellen compare-A en -B waarden
;---	         ^  ^				compare-A waarden zijn alijd 2*compareB-waarden
;---	         :  :				op een compareB-match output op 1
;---	compare  B  A  match		op een compareA-match output op 0
;---
;---
;-------------------------------------------------------------------


;--- INCLUDE FILES --------------------\
;.nolist
.include "8535def.inc"					; AVR AT90S8535
.include "System.inc"					; 
;.list
;--------------------------------------/



;--- CONSTANTEN -----------------------\
.equ CK = 8000000						; CPU clock frequentie					; 8000000
.equ TCK = CK/8							; timer1 frequentie						; CK/8
.equ Tick = 1/TCK						; de duur van 1 (timer)tick in seconden	; 1/TCK
.equ Puls1 = 58							; 58us
.equ Puls0 = 100						; 100us
.equ BitStreamEnd = $FF					; einde-van-stream marker
;--------------------------------------/




;--- REGISTER ALIASSEN ----------------\
.def temp			= R16				; Een register voor algemeen gebruik
.def temp2			= R17
.def temp3			= R18
;--------------------------------------/






;--- De AVR-AT90S8535 "vector"-tabel --\
.CSEG
.org $0000								; Het begin van de vector-tabel op adres 0 van het RAM
	rjmp RESET							; Reset Handler
	reti								; External Interrupt0 Vector Address
	reti								; External Interrupt1 Vector Address
	reti								; Timer2 compare match Vector Address
	reti								; Timer2 overflow Vector Address
	reti								; Timer1 Input Capture Vector Address
	rjmp Timer_Interrupt_CompareA		; Timer1 Output Compare A Interrupt Vector Address
	rjmp Timer_Interrupt_CompareB		; Timer1 Output Compare B Interrupt Vector Address
	reti								; Overflow1 Interrupt Vector Address
	reti								; Overflow0 Interrupt Vector Address
	reti								; SPI Interrupt Vector Address
	reti								; UART Receive Complete Interrupt Vector Address
	reti								; UART Data Register Empty Interrupt Vector Address
	reti								; UART Transmit Complete Interrupt Vector Address
	reti								; ADC Conversion Complete Interrupt Vector Address
	reti								; EEPROM Write Complete Interrupt Vector Address
	reti								; Analog Comparator Interrupt Vector Address
;--------------------------------------/



;---------------------------------------
;--- De te verzenden bitstream
;--------------------------------------\
BitStream:
;	111111111111 0 00110111 0 01110100 0 01000011 1
.DB	Puls1, Puls1, Puls1, Puls1, Puls1, Puls1, Puls1, Puls1, Puls1, Puls1, Puls1, Puls1
.DB	Puls0
.DB	Puls0, Puls0, Puls1, Puls1, Puls0, Puls1, Puls1, Puls1
.DB	Puls0
.DB	Puls0, Puls1, Puls1, Puls1, Puls0, Puls1, Puls0, Puls0
.DB	Puls0
.DB	Puls0, Puls1, Puls0, Puls0, Puls0, Puls0, Puls1, Puls1
.DB	Puls1
.DB	BitStreamEnd
;--------------------------------------/




;---------------------------------------
;--- De Timer1 initialiseren
;--------------------------------------\
Timer_Initialize:
	; interrupts tegengaan
	clr		temp
	out		TIMSK, temp

	; poort D pin 6 als output instellen
	; voor de DCC-output
	sbi		DDRD, PD6
	; beginnen met de preamble
	cbi		PORTD, PD6

	; De Timer1 HW-PWM uitschakelen
	clr		temp
	out		TCCR1A, temp

	;-- waarden voor TCCR1B
	; ICNC1: Noise Canceler uitschakelen => input capture om elke sample/capture. (nvt nu)
	; ICES1: Input Capture Interrupts op opgaande flank laten genereren. (nvt nu)
	; CTC1:  Clear TCNT on compareA match inschakelen
	; CS12,CS11 & CS10: timer1clock-select instellen op CK/8 (0,1,0)
	ldi		temp, (0<<ICNC1 | 0<<ICES1 | 1<<CTC1 | 0<<CS12 | 1<<CS11 | 0<<CS10)
	out		TCCR1B, temp

	; timer1 compareA match interrupt inschakelen
	; timer1 compareB match interrupt inschakelen
	ldi		temp, (1<<OCIE1A | 1<<OCIE1B)
	out		TIMSK, temp

	; compare waarden instellen
	rcall	Bit_To_Compare

	; de counter op 0 instellen
	clr		temp
	out		TCNT1H, temp
	out		TCNT1L, temp
	ret
;--------------------------------------/



;---------------------------------------
;--- De Timer1 CompareB handler
;--------------------------------------\
Timer_Interrupt_CompareB:
 	push	temp						; register "temp" bewaren op de stack
	in		temp, SREG					; register "SREG"
	push	temp

	sbi		PORTD, PD6					; output signaal op 1

	pop		temp
	out		SREG, temp
	pop		temp
	reti
;--------------------------------------/


;---------------------------------------
;--- De Timer1 CompareA handler
;--------------------------------------\
Timer_Interrupt_CompareA:
 	push	temp						; register "temp" bewaren op de stack
	in		temp, SREG					; register "SREG"
	push	temp

	cbi		PORTD, PD6					; output signaal op 0

	rcall	Bit_To_Compare				; volgende compare-waarden instellen

	pop		temp
	out		SREG, temp
	pop		temp
	reti
;--------------------------------------/



;---------------------------------------
;--- Volgende bit van de bitstream lezen
;--- en de compare-waarden instellen
;--------------------------------------\
Bit_To_Compare:
	lpm									; load program memory: R0 := [Z]
	mov		temp, R0					; temp := R0
	; alle bits gehad?
	cpi		temp, BitStreamEnd
	brne	Next_Bit
	; de bitstream is verzonden, herhaal de bitstream.
	; Wel tenminste 5ms wachten alvorens de stream opnieuw te verzenden
	; dwz. 5000 timerticks (ik maak er 6ms van)
	;
	; de volgende compare-B match over 6ms laten komen
	; de volgende compare-A match over (6ms + Puls1) laten komen
	; Zodoende wordt de eerste preamble bit van de volgende stream
	; pas verzonden over 6ms, en wordt de bitstream herhaald.
	;
	; nu eerst de pointer naar het begin van de stream verplaatsen
	; op de 2e byte te verzenden
	ldi		ZL, low(2*BitStream)		; de pointer naar de bitstream in CSEG
	ldi		ZH, high(2*BitStream)
	adiw	ZL, 1						; ..laten wijzen naar de 2e byte van de bitstream
	; de compare-waarden instellen
	; compareB op 6ms
	ldi		temp2, high(6000)
	ldi		temp, low(6000)
	out		OCR1BH, temp2
	out		OCR1BL, temp
	; compareA op 6ms + Puls1
	ldi		temp2, high(6000+Puls1)
	ldi		temp, low(6000+Puls1)
	out		OCR1AH, temp2
	out		OCR1AL, temp
	; klaar..
	rjmp	Done_Bit_To_Compare

Next_Bit:
	adiw	ZL, 1						; Z := Z+1
	mov		temp2, R0					; temp2 := R0*2
	lsl		temp2						;
	clr		temp3						; temp3 := 0
	; compareB waarde
	out		OCR1BH, temp3
	out		OCR1BL, temp
	; compareA waarde
	out		OCR1AH, temp3
	out		OCR1AL, temp2
Done_Bit_To_Compare:
	ret
;--------------------------------------/





;---------------------------------------
;--- Main Program
;--------------------------------------\
RESET:
	cli									; interrupts tegenhouden
	initStackPointer					; initialiseer de stack pointer

	;-- initialisatie
	
	; de pointer naar de bitstream in CSEG
	ldi		ZL, low(2*BitStream)
	ldi		ZH, high(2*BitStream)
	
	; de timer en interrupts
	rcall	Timer_Initialize
	
	;--

	sei									; interrupts weer toelaten

main_loop:
	rjmp 	main_loop
;--------------------------------------/





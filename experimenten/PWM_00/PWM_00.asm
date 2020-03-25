
; PWM operatie timer/counter 1
; Verhoog de OCR1A-waarde mbv. PB2  ->  vergroot de PWM duty-cycle
; Verlaag de OCR1B-waarde mbv. PB3  ->  verhoog de PWM frequentie 


; 'tn15def.inc'
.include "8535def.inc"


.def zero	= R1
.def status	= R2
.def temp	= R15 ;R16
.def duty_cycle	= R16
.def frequency	= R17


 
.cseg					; Het begin van het code-segment
	rjmp RESET			; relatieve jump naar label RESET


.org OVF0addr			; De Timer interrupt-vector
	TIM0_OVF


; Timer 0 Overflow Interrupt Routine
TIM0_OVF:
	in		status, SREG
	sbis	PINB, PB2
	inc		duty_cycle
	cp		duty_cycle, frequency
	brcs	no0
	ldi		duty_cycle, 0x00
no0:
	sbis	PINB, PB3
	dec		frequency
	cp		frequency, zero
	brne	no1
	ldi		frequency, 0xFF
no1:
	out		OCR1A, duty_cycle
	out		OCR1B, frequency
	sbic	PINB, PB0
	cbi		PORTB, PB0
	sbis	PINB, PB0
	sbi		PORTB, PB0
	out		SREG, status
	reti




; Hier begint de uitvoer van het programma
RESET:
	clr		zero
	ldi		temp, 0x03
	out		DDRB, temp
	ldi		temp, 0xFE
	out		PORTB, temp
	ldi		temp, 0x04
	out		TCCR0, temp
	ldi		temp, (1<<TOIE0)
	out		TIMSK, temp
	ldi		temp, 0x61
	out		TCCR1, temp
	ldi		duty_cycle, 0x00
	ldi		frequency, 0xFF
	sei

e_loop:
	rjmp	e_loop


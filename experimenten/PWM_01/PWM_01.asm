;**********************************
;PWM.ASM
;this is a very simple program
;which write a value from the
;register: pwm, to the pwm pin PD5.
;**********************************

;.include	"C:\Program Files\Atmel\AVR Tools\AvrAssembler\Appnotes\8535def.inc"
.include	"8535def.inc"

.def	temp = r16
.def	pwm = r17

.cseg
.org	$000
	rjmp	reset			;reset handle

.org OVF0addr			; De Timer interrupt-vector
	rjmp	TIM0_OVF




reset:
	rjmp	init			;start init


init:
	ldi	temp,ramend
	out	spl,temp		;set spl
	ldi	temp,high(ramend)
	out	sph,temp		;set sph

	ldi	temp,0b11111111		;portb = output
	out	ddrd,temp	
	
	out	portb,temp		;switch led's off

	ldi	temp,0b10000001		;init PWM... (choose 8-Bit PWM etc...)
	out	tccr1a,temp

	ldi	temp,0					
	out	ocr1ah,temp		

	ldi	temp,1			
	out	ocr1al,temp

	ldi	temp,0b00000001		
	out	tccr1b,temp

	sei				;enable interrupts
	
	rjmp	loop

loop:	
	ldi	pwm,230			;choose the value for pwm
	out	ocr1al,pwm				
	rjmp	loop




; Timer 0 Overflow Interrupt Routine
TIM0_OVF:
	reti



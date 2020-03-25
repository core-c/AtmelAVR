;***********************************
;BLINK.ASM
;this program use the interrupt of
;an Timer_0 overflow, and switch the
;led's on PortB on and off.
;***********************************

.include	"c:\avrtools\appnotes\8515def.inc"

.def	temp = r16
.def	counter = r17
.def	time = r18
.def	one = r19
.def	zero = r20
.def	tim_reg = r21

.cseg
.org	$000
	rjmp	reset			;reset handle
.cseg
.org	OVF0addr			
	rjmp	intrpt			;interrupt adress for timer0 ovf
		
reset:	rjmp	init			;start init

intrpt:	inc	counter			;increase counter
	cpse	one,counter		;compare counter with the valuable 255
	reti				
	rjmp	count_0			;jump to count_0

count_0:
	ldi	counter,0		;load counter
	reti				;go back from the interrupt

init:	ldi	temp,0			;temp register = 0
	ldi	counter,0	        ;counter = 0

	ldi	temp,ramend
	out	spl,temp		;set spl
	ldi	temp,high(ramend)
	out	sph,temp		;set sph
			
	ldi	temp,255
	out	ddrb,temp		;PortB = output
	ldi	temp,0
	out	ddrd,temp		;PortD = input

	ldi	one,255
	ldi	zero,0	

	ldi	temp,0b01111111		;switch all led's off
	out 	portb,temp
			
	rjmp	timer			;start to init the timer

timer:	sei				;enable interrupts
		
	ldi	tim_reg,timsk		;init the register timsk
	ori	tim_reg,0b00000010	
	out	timsk,tim_reg		

	ldi	tim_reg,tccr0		;start Timer0 with
	ori	tim_reg,0b00000101	;1/1024 
	out	tccr0,tim_reg		
			
	rjmp	loop			;jump to the loop

wait:	ldi	counter,0		;load counter
	ldi	time,10			;load time value
	rjmp	count			;jump to count

count:	cpse	counter,time		;compare counter and time
	rjmp	count			;till both reg's are equal
	ret				;go back

loop:	rcall	wait
	out	portb,zero
	rcall	wait
	out	portb,one
	rjmp	loop

			
;***************************************
;AD_535.ASM
;this program will read channel 0 of the
;A/D converter of an AT90S8515, and will
;write the result of the conversion to
;PortB and PortD
;***************************************

.include	"c:\avrtools\appnotes\8535def.inc"

.def	temp = r16
.def	temp2 = r17

.cseg
.org	$000
	rjmp	reset			;reset handle
.cseg
.org	ADCCaddr			;adc interrupt adress
	rjmp	output

reset:	rjmp	init			;start init

output: in	temp,adcl		;read both adc register
	in	temp2,adch		
				
	out	portb,temp		;write lowbyte from adc
					;to portb
	out	portd,temp2		;write highbyte from adc
					;to portd
	reti				;go back...

init:	ldi	temp,low(ramend)
	out	spl,temp		;set spl
	ldi	temp,high(ramend)
	out	sph,temp		;set sph 
			
	ldi	temp,0b11111111		;set portb and portd as output
	out	ddrb,temp		
	out	ddrd,temp		

	sei				;enable interrupts

	ldi	temp,0b00000000		;choose channel 0 from adc
	out	admux,temp

	ldi	temp,0b11101111		;set the register adcsr
	out	adcsr,temp

	rjmp	loop			;let's go...

loop:	rjmp	loop

			

			

			
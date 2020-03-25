;*********************************
;SER.ASM
;this program does read a value
;from the comX, and write it as an
;echo back to the pc-screen.
;*********************************

.include "c:\avrtools\appnotes\8515def.inc"	

.equ	clock = 4000000		;clock frequency
.equ	baudrate = 9600		;choose a baudrate

.equ	baudkonstant = (clock/(16*baudrate))-1

.def	temp = r16

.cseg
.org	$00
	rjmp	reset		;reset handle

reset:	rjmp	init		;start init

init:	ldi	temp,low(ramend)
	out	spl,temp	;set spl
	ldi	temp,high(ramend)
	out	sph,temp	;set sph

	ldi	temp,baudkonstant	
	out	ubrr,temp	;load baudrate

	rjmp	loop		;let's go...

rs_rec:	sbi	ucr,rxen	;set reciver bit...			
	sbis	usr,rxc		;wait for a value
	rjmp	rs_rec
	in	temp,udr	;read value
	cbi	ucr,rxen	;clear register
	ret			;go back
	
rs_send:
	sbi	ucr,txen	;set sender bit
	sbis	usr,udre	;wait till register is cleared
	rjmp	rs_send
	out	udr,temp	;send the recived value
	cbi	ucr,txen	;clear sender bit
	ret			;go back

loop:	rcall	rs_rec		;read from comX
	rcall	rs_send		;send to comX
	rjmp	loop		;repeat		
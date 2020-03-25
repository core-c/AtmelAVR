;**************************************************************
;  test00.ASM
;
; Ons eerste testproggie voor de AVR schakelt 3 LED's aan.
; Met een schakelaart(je) kan er een noodstop gemaakt worden.
;**************************************************************

.include "8535def.inc"	


; Mijn constanten
.def	temp		= R16
.def	tim_reg		= R17
.def	teller		= R18
;.def	NoodStop	= R19

.equ	vertraging	= 32	;min:1  max:255



; Definities die betrekking hebben op het CODE-segment
.cseg
; --- De Interrupt-Vectoren ---
; De RESET vector
.org	$00
	rjmp	RESET

; De externe interrupt voor de schakelaar
;.org	INT0addr
;	rjmp	Schakelaar_Interrupt

; De Timer 0 Overflow vector
.org	OVF0addr
	rjmp	Timer_Interrupt







RESET:
	cli					;interrupts uitschakelen
	; De stackpointer instellen op het einde van het RAM
	ldi	temp,low(ramend)
	out	spl,temp	;set spl
	ldi	temp,high(ramend)
	out	sph,temp	;set sph

	; Poort C van de AVR als output instellen
	ldi	temp,255
	out	DDRC,temp		;PortC = output
;	ldi	temp,0
;	out	ddrd,temp		;PortD = input


	; Bits[0..0] op 1, de bits[1..7] op 0
	ldi temp,1
	out PORTC, temp


	; Initialiseer het General Interrupt Mask
;	ldi temp, 0b00000010  ;INT0 instellen
;	out MCUCR, temp
;	ldi temp, 0b01000000  ;alleen INT0 aktiveren
;	out GIMSK, temp


	; Initialiseer de Timer.
	ldi	tim_reg,TCCR0			;start Timer0 with
	andi tim_reg, ~(1<<CS02 | 1<<CS01 | 1<<CS00)	;not (cs02 or cs01 or cs00)
	ori	tim_reg,(1<<CS02 | 1<<CS00);  0b00000101	;TimerClock/1024 => 32768/1024=32Hz timer
	out	TCCR0,tim_reg

	ldi	tim_reg,TIMSK			;init the register timsk
	ori	tim_reg,(1<<TOIE0)		; 0b00000010	timer0 interrupt overflow enable
	out	TIMSK,tim_reg		

;	clr NoodStop				; de noodstop op 0 (voor niet ingedrukt)
	ldi	teller,vertraging+1		; een "om de x keer" teller

	sei							; Interrupts aan

	; En eeuwig blijven doorgaan/wachten/loopen/hangen
eloop:
	rjmp eloop









;-------------------------------------------------------------
;---  De INT0addr Interrupt Handler
;---
;---    Dit is de NoodStop code.
;-------------------------------------------------------------
;Schakelaar_Interrupt:
;	ser temp						; alle bits aan
;	eor NoodStop,temp				; de noodstop togglen
;
;	reti









;-------------------------------------------------------------
;---  De Timer 0 Overflow Interrupt Handler
;-------------------------------------------------------------
Timer_Interrupt:
	;--- Als de NoodStop 'ingedrukt' is dan meteen de interrupt-handler laten stoppen
;	cpi NoodStop,0
;	breq isOK
;	reti


isOK:
	;--- om de 32 keer een actie starten
	dec teller					; 1 van teller aftrekken
	cpi teller,0				; teller met 0 vergelijken
	breq OmDe32					; spring naar 'OmDe32' als teller kleiner is dan 0
	reti						; anders einde van de interrupt.
OmDe32:
	ldi	teller,vertraging+1		; de teller weer opnieuw instellen

	
	;--- de 3 laagste bitjes op poort C als een looplicht laten functioneren
	in temp,PORTC
	andi temp, 0b00000111
	ror temp					; rotate right
	brcc LaagsteBitWas0
	; als het laagste bitje 1 was dan nu bit 2 zetten,
	; want dit bitje was er rechts uit geschoven
	ori temp,0b00000100
LaagsteBitWas0:
	out PORTC, temp

	reti
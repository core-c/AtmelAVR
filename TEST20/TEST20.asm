;*************************************************************************************
;***
;***  Een LED-dimmer.
;***  Software-matige 8-bits PWM (Timer2) met output op PD4 (OC1A)
;***  (PD7 (OC2) is de standaard output-pin voor Timer2-PWM, maar onze
;***  groene LED hangt nu aan PD4 (OC1B), pin #18. Aangezien we toch zelf de PWM genereren
;***  kunnen we ook zelf de uitvoer-pin bepalen waar het signaal op komt.
;***
;***    De PWM-frequentie wordt: de prescaled Timer2-Clock / (TOP+1)
;***    Met een timer-prescale /256 komt de PWM-frequentie op: 28.8KHz/256 = 112.5Hz
;***    (volgens mij zien mensen dan geen geknipper meer van de LED ;)
;***    De LED zal dan dimmen op een frequentie van 112.5/256 = 0.44Hz
;***
;***  Er is ook een INT0-handler voor een aangesloten schakelaar op AVR pin 16.
;***  Als de schakelaar wordt ingedrukt, wordt de timer2 in pauze-stand gezet.
;***  Nogmaals indrukken om de timer2 weer verder te laten tellen, en de LED te dimmen.
;***
;*************************************************************************************

.include "8535def.inc"

;@@.equ vertraging	= 64

; Register synoniemen
.def temp			= R16
.def tempL			= R17
.def LED_Brightness	= R18				; de felheid van de LED (=duty-cycle)
.def LED_CountingUp	= R19				; <>0=omhoog tellen, 0=omlaag tellen
;@@.def delay			= R20

; Het begin van het CODE-segment
.cseg
;--- De vector-tabel -------------------
.org 0x0000								; Het begin van de vector-tabel op adres 0 van het RAM
	rjmp RESET							; Reset Handler
	rjmp IRQ0_Interrupt					; External Interrupt0 Vector Address
	reti								; External Interrupt1 Vector Address
	rjmp Timer2_Compare					; Timer2 compare match Vector Address
	rjmp Timer2_Overflow				; Timer2 overflow Vector Address
	reti								; Timer1 Input Capture Vector Address
	reti								; Timer1 Output Compare A Interrupt Vector Address
	reti								; Timer1 Output Compare B Interrupt Vector Address
	reti								; Overflow1 Interrupt Vector Address
	reti								; Overflow0 Interrupt Vector Address
	reti								; SPI Interrupt Vector Address
	reti								; UART Receive Complete Interrupt Vector Address
	reti								; UART Data Register Empty Interrupt Vector Address
	reti								; UART Transmit Complete Interrupt Vector Address
	reti								; ADC Conversion Complete Interrupt Vector Address
	reti								; EEPROM Write Complete Interrupt Vector Address
	reti								; Analog Comparator Interrupt Vector Address
;---------------------------------------



RESET:
	; interrupts uitschakelen
	cli
	; De stack-pointer instellen op het einde van het RAM
	ldi		temp, high(RAMEND)
	ldi		tempL, low(RAMEND)
	out		SPH, temp
	out		SPL, tempL
	; nog even een LED aanzetten ter indicatie dat de AVR runt.
	ldi		temp, (1<<PC3 | 1<<PC2 | 1<<PC1 | 1<<PC0)
	out		DDRC, temp
	ldi		temp, (1<<PC3 | 0<<PC2 | 0<<PC1 | 0<<PC0)
	out		PORTC, temp					; 1 LED aan bij 8-bits PWM
	; De begin-brightness op 0 instellen
	clr		LED_Brightness
	; Beginnen met omhoog tellen om de LED te laten oplichten
	ser		LED_CountingUp
;@@	; de vertraging instellen
;@@	ldi		delay, vertraging



	;--- De externe interrupt IRQ0 instellen ------------------------------------------------------------
	; externe interrupt IRQ0 inschakelen in Global Interrupt Mask Register
	in		temp, GIMSK
	ori		temp, (1<<INT0)
	out		GIMSK, temp

	; externe interrupt IRQ0 activeren op vallende flank (trigger als de knop INgedrukt wordt)
	in		temp, MCUCR
	ori		temp, (1<<ISC01)
	out		MCUCR, temp
	;----------------------------------------------------------------------------------------------------

	; De interrupts voor Overflow & Compare-Match inschakelen
	ldi		temp, (1<<OCIE2 | 1<<TOIE2)
	out		TIMSK, temp

	; poort D als output zetten voor de PWM output-pin
	sbi		DDRD, PD4					; tbv. de groene LED

	; De duty-cycle instellen
	out		OCR2, LED_Brightness

	; Timer2-counter op de TOP instellen,
	; zodat direct een puls gestart wordt.
	ser		temp
	out		TCNT2, temp

	; Timer2 instellen en starten,
	; Hardware PWM-mode uitschakelen:   PWM2 => 0=uit, 1=8bits
	; Timer2Clock op CK/256 instellen.
	ldi		temp, (0<<PWM2 | 1<<CS22 | 1<<CS21 | 0<<CS20);/256
	out		TCCR2, temp

	; interrupts inschakelen
	sei
eLoop:
	rjmp eLoop






;---------------------------------------
;- De LED-fader subroutine
;---------------------------------------
LEDFader:
	; De duty-cycle aanpassen voor het LED-fade effect
	tst		LED_CountingUp
	breq	TelOmlaag
TelOmhoog:
	inc		LED_Brightness
	brne	done
	clr		LED_CountingUp
	dec		LED_Brightness				; brightness corrigeren (max=TOP, niet 0)
	rjmp	done
TelOmlaag:
	dec		LED_Brightness
	brne	done
	ser		LED_CountingUp
	inc		LED_Brightness				; brightness corrigeren (min=BOTTOM, niet $FF)
done:
	; De duty-cycle instellen op het Output-Compare-Register voor Timer2
	out		OCR2, LED_Brightness
	ret




;---------------------------------------
;- De Timer2-Overflow Interrupt-Handler
;---------------------------------------
Timer2_Overflow:
	; Als de timer-counter de TOP bereikt heeft,
	; wordt een Overflow-interrupt gegenereerd.
	;
	; De uitgang van het PWM-signaal hoog maken
	; bij de start van een nieuwe puls.
	sbi		PORTD, PD4
	;
;@@	; Een extra vertraging inbouwen
;@@	dec		delay
;@@	brne	doneHere
;@@	ldi		delay, vertraging
	;
	; De duty-cycle aanpassen zodat de LED gaat in- & uit-dimmen.
	rcall	LEDFader
;@@doneHere:
	reti






;---------------------------------------
;- De Timer2-Compare Interrupt-Handler
;---------------------------------------
Timer2_Compare:
	;--- Als de timer-counter = OCR2, wordt een Comnpare-interrupt gegenereerd.
	; De uitgang van het PWM-signaal laag maken om het einde van een puls te markeren.
	cbi		PORTD, PD4
	reti







;------------------------------------------
;--- De INT0 Interrupt-Handler
;------------------------------------------
IRQ0_Interrupt:
	;--- Als de schakelaar wordt ingedrukt, wordt INT0 gegenereerd.
;	in		temp, PORTC
;	com		temp						; Alle bits van deze byte omdraaien (XOR met $FF)
;	out		PORTC, temp
	
	; toggle de timer2 aan/uit status
	in		temp, TCCR2
	andi	temp, (1<<CS22 | 1<<CS21 | 1<<CS20)
	breq	startTimer2
stopTimer2:
	; de timer2 stoppen
	clr		temp
	out		TCCR2, temp
	rjmp	doneIRQ0
startTimer2:
	; de timer2 starten
	ldi		temp, (0<<PWM2 | 1<<CS22 | 1<<CS21 | 0<<CS20);/256
	out		TCCR2, temp
doneIRQ0:
	reti

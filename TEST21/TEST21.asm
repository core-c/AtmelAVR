
;*************************************************************************************
;***
;***  Een LED-dimmer voor 3 LED's.
;***  Software-matige 8-bits PWM (Timer2) met output op PD7 (OC2), standaard pin.
;***  Hardware-matige 8-bits PWM (Timer1) met output op PD4 (OC1A) & PD5 (OC1B).
;***  (Hoewel we bij software-matige PWM zelf de output-pin kunnen selecteren voor
;***   het PWM-signaal, kies ik er nu voor om de standaard poort te gebruiken.)
;***
;***  De Timer1- & Timer2 prescale zetten we beiden op CK/256. Bij een hardware 
;***  8-bits PWM wordt de PWM-frequentie uiteindelijk TCK/510. (7372800/256)/256=
;***  28800/256=125.5Hz. (volgens mij zien mensen dan geen geknipper meer van de
;***  LED's ;) De LED's zullen dan dimmen op een frequentie van 112.5/(2^8)=0.44Hz
;***  Bij een software-matige PWM op timer2 wordt de uiteindelijke PWM-frequentie 
;***  2x zo hoog, dit geldt voor de groene timer2-LED.
;***
;***  Er is ook een INT0-handler voor een aangesloten schakelaar op AVR pin 16.
;***  Als de schakelaar wordt ingedrukt, wordt de dimmer in pauze-stand gezet.
;***  Nogmaals indrukken om de dimmer weer verder te starten.
;***  NB: Als de dimmer in pauze-stand staat, worden er nog steeds PWM-pulzen naar
;***  de LED's gestuurd (zodat deze dimmen). De pulsbreedte wordt echter niet meer
;***  aangepast, totdat de schakelaar nogmaals ingedrukt wordt.
;***  De rode LED's aan poort C blijven roteren zolang de timer2 loopt; Die draait
;***  altijd door, ook al wordt de schakelaar ingedrukt (LED-dimmer gepauzeerd).
;***  !! De waarde op de poort wordt wèl ge-reset op 0b00010000 !!
;***
;***
;***  Wat me opvalt is dat de hardware-PWM's van Timer1 (8-bits) op de uiterste
;***  waarden van de TimerCounter1 (BOTTOM & TOP) de LED's laten knipperen. De 
;***  software-matige PWM's van Timer2 leveren dit effect niet op.
;***  (misschien dat dit effect niet te zien is als de duty-cycle ingesteld wordt
;***   op een compare-match ipv. een overflow).
;***
;*************************************************************************************

.include "8535def.inc"

.equ LED_GREEN		= PD7				; de PWM output pinnen met de
.equ LED_YELLOW		= PD4				; toegewezen/verbonden LED-kleuren.
.equ LED_ORANGE		= PD5				;

.equ LED1A	= LED_ORANGE				; deze LED gebruiken we voor T1A
.equ LED1B	= LED_YELLOW				; deze LED gebruiken we voor T1B
.equ LED2	= LED_GREEN					; deze LED gebruiken we voor T2

; Register synoniemen
.def temp				= R16
.def tempL				= R17
.def LED1A_Brightness	= R18			; de felheid van de LED (=duty-cycle)
.def LED1A_CountingUp	= R19			; <>0=omhoog tellen, 0=omlaag tellen
.def LED1B_Brightness	= R20			;
.def LED1B_CountingUp	= R21			;
.def LED2_Brightness	= R22			;
.def LED2_CountingUp	= R23			;
.def LED_OnOff			= R24			; de aan/uit status: 0=uit, 1=aan
.def tREG				= R25			; voor gebruik in de ISP's


; De PostScaler
.equ vertraging	= 20
.def delay				= R26


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
	reti;rjmp Timer1A_Compare			; Timer1 Output Compare A Interrupt Vector Address
	reti;rjmp Timer1B_Compare			; Timer1 Output Compare B Interrupt Vector Address
	rjmp Timer1_Overflow				; Overflow1 Interrupt Vector Address
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
	ldi		temp, (1<<PC5 | 1<<PC4 | 1<<PC3 | 1<<PC2 | 1<<PC1 | 1<<PC0)
	out		DDRC, temp
	ldi		temp, (0<<PC5 | 1<<PC4 | 0<<PC3 | 0<<PC2 | 0<<PC1 | 0<<PC0)
	out		PORTC, temp					; 1 LED aan bij 8-bits PWM

	; poort D als output zetten voor de PWM output-pinnen
	sbi		DDRD, LED1A					; tbv. de oranje LED
	sbi		DDRD, LED1B					; tbv. de gele LED
	sbi		DDRD, LED2					; tbv. de groene LED

	clr		LED2_Brightness				; De begin-brightness op 0 instellen
	ser		LED2_CountingUp				; omhoog tellen om de LED te laten oplichten
	clr		LED1A_Brightness
	ser		LED1A_CountingUp			; omhoog tellen
	clr		LED1B_Brightness
	clr		LED1B_CountingUp			; omlaag tellen
	; schakel de dimmer aan
	ser		LED_OnOff


	; de vertraging instellen
	ldi		delay, vertraging


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

	; De interrupts voor Overflow ($$ & Compare-Match) inschakelen
;$$	ldi		temp, (1<<OCIE1A | 1<<OCIE1B | 1<<TOIE1 | 1<<OCIE2 | 1<<TOIE2)
	ldi		temp, (1<<TOIE1 | 1<<OCIE2 | 1<<TOIE2)
	out		TIMSK, temp

	; De duty-cycle instellen
	out		OCR2, LED2_Brightness
	;
	clr		temp
	out		OCR1AH, temp
	out		OCR1AL, LED1A_Brightness
	;
	clr		temp
	out		OCR1BH, temp
	out		OCR1BL, LED1B_Brightness

	; Timer2-counter op de TOP instellen,
	; zodat direct een puls gestart wordt.
	ser		temp
	out		TCNT2, temp
	;
	clr		temp
	out		TCNT1H, temp
	out		TCNT1L, LED1A_Brightness

	; Timer2 instellen en starten,
	; Hardware PWM-mode uitschakelen:   PWM2 => 0=uit, 1=8bits
	; Timer2Clock op CK/256 instellen.
	ldi		temp, (0<<PWM2 | 1<<CS22 | 1<<CS21 | 0<<CS20);/256
	out		TCCR2, temp
	;
	; De Timer1 in hardware-PWM mode schakelen, anders kunnen we
	; geen 2 PWM pulzen genereren.
	; HW Non-Inverted PWM selecteren voor beide counters, 1A & 1B.
	ldi		temp, (1<<COM1A1 | 0<<COM1A0 | 1<<COM1B1 | 0<<COM1B0 | 0<<PWM11 | 1<<PWM10)
	out		TCCR1A, temp
	; TCK instellen op CK/256
	ldi		temp, (1<<CS12 | 0<<CS11 | 0<<CS10)
	out		TCCR1B, temp

	; interrupts inschakelen
	sei
eLoop:
	rjmp eLoop






;---------------------------------------
;- De LED-fader subroutine voor LED2
;---------------------------------------
LED2Fader:
	; De duty-cycle aanpassen voor het LED-fade effect
	tst		LED2_CountingUp
	breq	TelOmlaag
TelOmhoog:
	inc		LED2_Brightness
	brne	done
	clr		LED2_CountingUp
	dec		LED2_Brightness				; brightness corrigeren (max=TOP, niet 0)
	rjmp	done
TelOmlaag:
	dec		LED2_Brightness
	brne	done
	ser		LED2_CountingUp
	inc		LED2_Brightness				; brightness corrigeren (min=BOTTOM, niet $FF)
done:
	; De duty-cycle instellen op het Output-Compare-Register voor Timer2
	out		OCR2, LED2_Brightness
	ret




;---------------------------------------
;- De LED-fader subroutine voor LED1A
;---------------------------------------
LED1AFader:
	push	tREG
	; De duty-cycle aanpassen voor het LED-fade effect
	tst		LED1A_CountingUp
	breq	TelOmlaag1A
TelOmhoog1A:
	inc		LED1A_Brightness
	brne	done1A
	clr		LED1A_CountingUp
	dec		LED1A_Brightness				; brightness corrigeren (max=TOP, niet 0)
	rjmp	done1A
TelOmlaag1A:
	dec		LED1A_Brightness
	brne	done1A
	ser		LED1A_CountingUp
	inc		LED1A_Brightness				; brightness corrigeren (min=BOTTOM, niet $FF)
done1A:
	; De duty-cycle instellen op het Output-Compare-Register voor Timer1A
	clr		tREG
	out		OCR1AH, tREG
	out		OCR1AL, LED1A_Brightness
	;
	pop		tREG
	ret




;---------------------------------------
;- De LED-fader subroutine voor LED1B
;---------------------------------------
LED1BFader:
	push	tREG
	; De duty-cycle aanpassen voor het LED-fade effect
	tst		LED1B_CountingUp
	breq	TelOmlaag1B
TelOmhoog1B:
	inc		LED1B_Brightness
	brne	done1B
	clr		LED1B_CountingUp
	dec		LED1B_Brightness				; brightness corrigeren (max=TOP, niet 0)
	rjmp	done1B
TelOmlaag1B:
	dec		LED1B_Brightness
	brne	done1B
	ser		LED1B_CountingUp
	inc		LED1B_Brightness				; brightness corrigeren (min=BOTTOM, niet $FF)
done1B:
	; De duty-cycle instellen op het Output-Compare-Register voor Timer1B
	clr		tREG
	out		OCR1BH, tREG
	out		OCR1BL, LED1B_Brightness
	;
	pop		tREG
	ret




;---------------------------------------
;- De Timer2-Overflow Interrupt-Handler
;---------------------------------------
Timer2_Overflow:
	push	tREG
	; Als de timer-counter de TOP bereikt heeft,
	; wordt een Overflow-interrupt gegenereerd.
	;
	; De uitgang van het PWM-signaal hoog maken
	; bij de start van een nieuwe puls.
	sbi		PORTD, LED2
	;
	; Een extra vertraging inbouwen--------------------
	dec		delay
	brne	verder; doneHere
	ldi		delay, vertraging
	; de waarde op poort C (LED's) rotaten/shiften
	in		tREG, PORTC
	rol		tREG
	out		PORTC, tREG
	;--------------------------------------------------
	;
verder:
	tst		LED_OnOff					; staat de dimmer aan??
	breq	doneHere
	; De duty-cycle aanpassen zodat de LED gaat in- & uit-dimmen.
	rcall	LED2Fader
doneHere:
	pop		tREG
	reti






;---------------------------------------
;- De Timer2-Compare Interrupt-Handler
;---------------------------------------
Timer2_Compare:
	;--- Als de timer-counter = OCR2, wordt een Comnpare-interrupt gegenereerd.
	; De uitgang van het PWM-signaal laag maken om het einde van een puls te markeren.
	cbi		PORTD, LED2
	reti







;---------------------------------------
;- De Timer1-Overflow Interrupt-Handler
;---------------------------------------
Timer1_Overflow:
	; Als de timer-counter de TOP bereikt heeft,
	; wordt een Overflow-interrupt gegenereerd.
	;
	; De uitgang van het PWM-signaal hoog maken
	; bij de start van een nieuwe puls.
;	sbi		PORTD, LED1A
;	sbi		PORTD, LED1B
	;
;@@	; Een extra vertraging inbouwen
;@@	dec		delay
;@@	brne	doneHere
;@@	ldi		delay, vertraging
	;
	tst		LED_OnOff					; staat de dimmer aan??
	breq	doneHere1
	; De duty-cycle aanpassen zodat de LED gaat in- & uit-dimmen.
	rcall	LED1AFader
	rcall	LED1BFader
doneHere1:
	reti






;---------------------------------------
;- De Timer1A-Compare Interrupt-Handler
;---------------------------------------
Timer1A_Compare:
	;--- Als de timer1-counter = OCR1A, wordt een Comnpare-interrupt gegenereerd.
	; De uitgang van het PWM-signaal laag maken om het einde van een puls te markeren.
;	cbi		PORTD, LED1A
	reti







;---------------------------------------
;- De Timer1B-Compare Interrupt-Handler
;---------------------------------------
Timer1B_Compare:
	;--- Als de timer1-counter = OCR1B, wordt een Comnpare-interrupt gegenereerd.
	; De uitgang van het PWM-signaal laag maken om het einde van een puls te markeren.
;	cbi		PORTD, LED1B
	reti







;------------------------------------------
;--- De INT0 Interrupt-Handler
;------------------------------------------
IRQ0_Interrupt:
	push	tREG
	;--- Als de schakelaar wordt ingedrukt, wordt INT0 gegenereerd.
	; toggle de dimmer aan/uit status
	com		LED_OnOff
	; zet 1 bit aan op poort C
	ldi		tREG, (0<<PC5 | 1<<PC4 | 0<<PC3 | 0<<PC2 | 0<<PC1 | 0<<PC0)
	out		PORTC, tREG					; 1 LED aan bij 8-bits PWM
	;
	pop		tREG
	reti


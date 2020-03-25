

; Op een T1_CompareA Match gaat de servo-puls op 1 (compareA bepaald de servo frequentie)
; Op een T1_CompareB Match gaat de servo-puls op 0 (compareB bepaald dus de servo duty-cycle)


;--- AVR clockfrequentie
.equ CK	= 4433619							; Hz

;--- Timer1
.equ TCK			= CK					; prescale
.equ T1_FREQ		= 70					; Hz (NB! CK/65535 == meest geschikte freq.)
.equ T1_COMPAREA	= TCK/T1_FREQ			; T1-CompareA waarde

;--- FineTune percentage
.equ TuneDown	= 0							; xxx% verder linksom (vanaf middenstand/100%)
.equ TuneUp		= 10						; xxx% verder rechtsom (vanaf middenstand/100%)
;--- Servo pulsduren in timerticks
.equ ms1	= TCK/1000						; 1 ms
.equ ms0_5	= ms1/2							; 0.5 ms
.equ ms2	= ms1*2							; 2 ms
.equ ms1_5	= ms1+ms0_5						; 1.5 ms
;--- Duty-cycle verschil over 256 waarden (de gestuurde byte)
; Omdat DCB een breuk is, en ik zo min mogelijk afrondingsfouten wil verkrijgen, 
; vermenigvuldig ik de waarde met 1000. Later deel ik weer door 1000.
;--- De laagste waarde voor een duty-cycle  
.equ PercDown	= (ms1_5-ms1)*TuneDown/100	; percentages vanaf de middenstand
.equ PercUp		= (ms2-ms1_5)*TuneUp/100	;
.equ TDB		= ms1-PercDown				; Linksom - TuneDown
.equ TUB		= ms2+PercUp				; Rechtsom + TuneUp
.equ DCB		= (TUB-TDB)*1000/256		; het verschil per stap(0..255) tuned

;--- Tabel in EEPROM met alle duty-cycles voor alle gezonden byte-waarden
.ESEG
Table_DutyCycles:
	.dw TDB+(0*DCB/1000)					; 0
	.dw TDB+(1*DCB/1000)					; 1
	.dw TDB+(2*DCB/1000)					; 2
	.dw TDB+(3*DCB/1000)					; 3
	.dw TDB+(4*DCB/1000)					; 4
	.dw TDB+(5*DCB/1000)					; 5
	.dw TDB+(6*DCB/1000)					; 6
	.dw TDB+(7*DCB/1000)					; 7
	.dw TDB+(8*DCB/1000)					; 8
	.dw TDB+(9*DCB/1000)					; 9
	.dw TDB+(10*DCB/1000)					; 10
	.dw TDB+(11*DCB/1000)					; 1
	.dw TDB+(12*DCB/1000)					; 2
	.dw TDB+(13*DCB/1000)					; 3
	.dw TDB+(14*DCB/1000)					; 4
	.dw TDB+(15*DCB/1000)					; 5
	.dw TDB+(16*DCB/1000)					; 6
	.dw TDB+(17*DCB/1000)					; 7
	.dw TDB+(18*DCB/1000)					; 8
	.dw TDB+(19*DCB/1000)					; 9
	.dw TDB+(20*DCB/1000)					; 20
	.dw TDB+(21*DCB/1000)					; 1
	.dw TDB+(22*DCB/1000)					; 2
	.dw TDB+(23*DCB/1000)					; 3
	.dw TDB+(24*DCB/1000)					; 4
	.dw TDB+(25*DCB/1000)					; 5
	.dw TDB+(26*DCB/1000)					; 6
	.dw TDB+(27*DCB/1000)					; 7
	.dw TDB+(28*DCB/1000)					; 8
	.dw TDB+(29*DCB/1000)					; 9
	.dw TDB+(30*DCB/1000)					; 30
	.dw TDB+(31*DCB/1000)					; 1
	.dw TDB+(32*DCB/1000)					; 2
	.dw TDB+(33*DCB/1000)					; 3
	.dw TDB+(34*DCB/1000)					; 4
	.dw TDB+(35*DCB/1000)					; 5
	.dw TDB+(36*DCB/1000)					; 6
	.dw TDB+(37*DCB/1000)					; 7
	.dw TDB+(38*DCB/1000)					; 8
	.dw TDB+(39*DCB/1000)					; 9
	.dw TDB+(40*DCB/1000)					; 40
	.dw TDB+(41*DCB/1000)					; 1
	.dw TDB+(42*DCB/1000)					; 2
	.dw TDB+(43*DCB/1000)					; 3
	.dw TDB+(44*DCB/1000)					; 4
	.dw TDB+(45*DCB/1000)					; 5
	.dw TDB+(46*DCB/1000)					; 6
	.dw TDB+(47*DCB/1000)					; 7
	.dw TDB+(48*DCB/1000)					; 8
	.dw TDB+(49*DCB/1000)					; 9
	.dw TDB+(50*DCB/1000)					; 50
	.dw TDB+(51*DCB/1000)					; 1
	.dw TDB+(52*DCB/1000)					; 2
	.dw TDB+(53*DCB/1000)					; 3
	.dw TDB+(54*DCB/1000)					; 4
	.dw TDB+(55*DCB/1000)					; 5
	.dw TDB+(56*DCB/1000)					; 6
	.dw TDB+(57*DCB/1000)					; 7
	.dw TDB+(58*DCB/1000)					; 8
	.dw TDB+(59*DCB/1000)					; 9
	.dw TDB+(60*DCB/1000)					; 60
	.dw TDB+(61*DCB/1000)					; 1
	.dw TDB+(62*DCB/1000)					; 2
	.dw TDB+(63*DCB/1000)					; 3
	.dw TDB+(64*DCB/1000)					; 4
	.dw TDB+(65*DCB/1000)					; 5
	.dw TDB+(66*DCB/1000)					; 6
	.dw TDB+(67*DCB/1000)					; 7
	.dw TDB+(68*DCB/1000)					; 8
	.dw TDB+(69*DCB/1000)					; 9
	.dw TDB+(70*DCB/1000)					; 70
	.dw TDB+(71*DCB/1000)					; 1
	.dw TDB+(72*DCB/1000)					; 2
	.dw TDB+(73*DCB/1000)					; 3
	.dw TDB+(74*DCB/1000)					; 4
	.dw TDB+(75*DCB/1000)					; 5
	.dw TDB+(76*DCB/1000)					; 6
	.dw TDB+(77*DCB/1000)					; 7
	.dw TDB+(78*DCB/1000)					; 8
	.dw TDB+(79*DCB/1000)					; 9
	.dw TDB+(80*DCB/1000)					; 80
	.dw TDB+(81*DCB/1000)					; 1
	.dw TDB+(82*DCB/1000)					; 2
	.dw TDB+(83*DCB/1000)					; 3
	.dw TDB+(84*DCB/1000)					; 4
	.dw TDB+(85*DCB/1000)					; 5
	.dw TDB+(86*DCB/1000)					; 6
	.dw TDB+(87*DCB/1000)					; 7
	.dw TDB+(88*DCB/1000)					; 8
	.dw TDB+(89*DCB/1000)					; 9
	.dw TDB+(90*DCB/1000)					; 90
	.dw TDB+(91*DCB/1000)					; 1
	.dw TDB+(92*DCB/1000)					; 2
	.dw TDB+(93*DCB/1000)					; 3
	.dw TDB+(94*DCB/1000)					; 4
	.dw TDB+(95*DCB/1000)					; 5
	.dw TDB+(96*DCB/1000)					; 6
	.dw TDB+(97*DCB/1000)					; 7
	.dw TDB+(98*DCB/1000)					; 8
	.dw TDB+(99*DCB/1000)					; 9
	.dw TDB+(100*DCB/1000)					; 100
	.dw TDB+(101*DCB/1000)					; 1
	.dw TDB+(102*DCB/1000)					; 2
	.dw TDB+(103*DCB/1000)					; 3
	.dw TDB+(104*DCB/1000)					; 4
	.dw TDB+(105*DCB/1000)					; 5
	.dw TDB+(106*DCB/1000)					; 6
	.dw TDB+(107*DCB/1000)					; 7
	.dw TDB+(108*DCB/1000)					; 8
	.dw TDB+(109*DCB/1000)					; 9
	.dw TDB+(110*DCB/1000)					; 110
	.dw TDB+(111*DCB/1000)					; 1
	.dw TDB+(112*DCB/1000)					; 2
	.dw TDB+(113*DCB/1000)					; 3
	.dw TDB+(114*DCB/1000)					; 4
	.dw TDB+(115*DCB/1000)					; 5
	.dw TDB+(116*DCB/1000)					; 6
	.dw TDB+(117*DCB/1000)					; 7
	.dw TDB+(118*DCB/1000)					; 8
	.dw TDB+(119*DCB/1000)					; 9
	.dw TDB+(120*DCB/1000)					; 120
	.dw TDB+(121*DCB/1000)					; 1
	.dw TDB+(122*DCB/1000)					; 2
	.dw TDB+(123*DCB/1000)					; 3
	.dw TDB+(124*DCB/1000)					; 4
	.dw TDB+(125*DCB/1000)					; 5
	.dw TDB+(126*DCB/1000)					; 6
	.dw TDB+(127*DCB/1000)					; 7
	.dw TDB+(128*DCB/1000)					; 8
	.dw TDB+(129*DCB/1000)					; 9
	.dw TDB+(130*DCB/1000)					; 130
	.dw TDB+(131*DCB/1000)					; 1
	.dw TDB+(132*DCB/1000)					; 2
	.dw TDB+(133*DCB/1000)					; 3
	.dw TDB+(134*DCB/1000)					; 4
	.dw TDB+(135*DCB/1000)					; 5
	.dw TDB+(136*DCB/1000)					; 6
	.dw TDB+(137*DCB/1000)					; 7
	.dw TDB+(138*DCB/1000)					; 8
	.dw TDB+(139*DCB/1000)					; 9
	.dw TDB+(140*DCB/1000)					; 140
	.dw TDB+(141*DCB/1000)					; 1
	.dw TDB+(142*DCB/1000)					; 2
	.dw TDB+(143*DCB/1000)					; 3
	.dw TDB+(144*DCB/1000)					; 4
	.dw TDB+(145*DCB/1000)					; 5
	.dw TDB+(146*DCB/1000)					; 6
	.dw TDB+(147*DCB/1000)					; 7
	.dw TDB+(148*DCB/1000)					; 8
	.dw TDB+(149*DCB/1000)					; 9
	.dw TDB+(150*DCB/1000)					; 150
	.dw TDB+(151*DCB/1000)					; 1
	.dw TDB+(152*DCB/1000)					; 2
	.dw TDB+(153*DCB/1000)					; 3
	.dw TDB+(154*DCB/1000)					; 4
	.dw TDB+(155*DCB/1000)					; 5
	.dw TDB+(156*DCB/1000)					; 6
	.dw TDB+(157*DCB/1000)					; 7
	.dw TDB+(158*DCB/1000)					; 8
	.dw TDB+(159*DCB/1000)					; 9
	.dw TDB+(160*DCB/1000)					; 160
	.dw TDB+(161*DCB/1000)					; 1
	.dw TDB+(162*DCB/1000)					; 2
	.dw TDB+(163*DCB/1000)					; 3
	.dw TDB+(164*DCB/1000)					; 4
	.dw TDB+(165*DCB/1000)					; 5
	.dw TDB+(166*DCB/1000)					; 6
	.dw TDB+(167*DCB/1000)					; 7
	.dw TDB+(168*DCB/1000)					; 8
	.dw TDB+(169*DCB/1000)					; 9
	.dw TDB+(170*DCB/1000)					; 170
	.dw TDB+(171*DCB/1000)					; 1
	.dw TDB+(172*DCB/1000)					; 2
	.dw TDB+(173*DCB/1000)					; 3
	.dw TDB+(174*DCB/1000)					; 4
	.dw TDB+(175*DCB/1000)					; 5
	.dw TDB+(176*DCB/1000)					; 6
	.dw TDB+(177*DCB/1000)					; 7
	.dw TDB+(178*DCB/1000)					; 8
	.dw TDB+(179*DCB/1000)					; 9
	.dw TDB+(180*DCB/1000)					; 180
	.dw TDB+(181*DCB/1000)					; 1
	.dw TDB+(182*DCB/1000)					; 2
	.dw TDB+(183*DCB/1000)					; 3
	.dw TDB+(184*DCB/1000)					; 4
	.dw TDB+(185*DCB/1000)					; 5
	.dw TDB+(186*DCB/1000)					; 6
	.dw TDB+(187*DCB/1000)					; 7
	.dw TDB+(188*DCB/1000)					; 8
	.dw TDB+(189*DCB/1000)					; 9
	.dw TDB+(190*DCB/1000)					; 190
	.dw TDB+(191*DCB/1000)					; 1
	.dw TDB+(192*DCB/1000)					; 2
	.dw TDB+(193*DCB/1000)					; 3
	.dw TDB+(194*DCB/1000)					; 4
	.dw TDB+(195*DCB/1000)					; 5
	.dw TDB+(196*DCB/1000)					; 6
	.dw TDB+(197*DCB/1000)					; 7
	.dw TDB+(198*DCB/1000)					; 8
	.dw TDB+(199*DCB/1000)					; 9
	.dw TDB+(200*DCB/1000)					; 200
	.dw TDB+(201*DCB/1000)					; 1
	.dw TDB+(202*DCB/1000)					; 2
	.dw TDB+(203*DCB/1000)					; 3
	.dw TDB+(204*DCB/1000)					; 4
	.dw TDB+(205*DCB/1000)					; 5
	.dw TDB+(206*DCB/1000)					; 6
	.dw TDB+(207*DCB/1000)					; 7
	.dw TDB+(208*DCB/1000)					; 8
	.dw TDB+(209*DCB/1000)					; 9
	.dw TDB+(210*DCB/1000)					; 210
	.dw TDB+(211*DCB/1000)					; 1
	.dw TDB+(212*DCB/1000)					; 2
	.dw TDB+(213*DCB/1000)					; 3
	.dw TDB+(214*DCB/1000)					; 4
	.dw TDB+(215*DCB/1000)					; 5
	.dw TDB+(216*DCB/1000)					; 6
	.dw TDB+(217*DCB/1000)					; 7
	.dw TDB+(218*DCB/1000)					; 8
	.dw TDB+(219*DCB/1000)					; 9
	.dw TDB+(220*DCB/1000)					; 220
	.dw TDB+(221*DCB/1000)					; 1
	.dw TDB+(222*DCB/1000)					; 2
	.dw TDB+(223*DCB/1000)					; 3
	.dw TDB+(224*DCB/1000)					; 4
	.dw TDB+(225*DCB/1000)					; 5
	.dw TDB+(226*DCB/1000)					; 6
	.dw TDB+(227*DCB/1000)					; 7
	.dw TDB+(228*DCB/1000)					; 8
	.dw TDB+(229*DCB/1000)					; 9
	.dw TDB+(230*DCB/1000)					; 230
	.dw TDB+(231*DCB/1000)					; 1
	.dw TDB+(232*DCB/1000)					; 2
	.dw TDB+(233*DCB/1000)					; 3
	.dw TDB+(234*DCB/1000)					; 4
	.dw TDB+(235*DCB/1000)					; 5
	.dw TDB+(236*DCB/1000)					; 6
	.dw TDB+(237*DCB/1000)					; 7
	.dw TDB+(238*DCB/1000)					; 8
	.dw TDB+(239*DCB/1000)					; 9
	.dw TDB+(240*DCB/1000)					; 240
	.dw TDB+(241*DCB/1000)					; 1
	.dw TDB+(242*DCB/1000)					; 2
	.dw TDB+(243*DCB/1000)					; 3
	.dw TDB+(244*DCB/1000)					; 4
	.dw TDB+(245*DCB/1000)					; 5
	.dw TDB+(246*DCB/1000)					; 6
	.dw TDB+(247*DCB/1000)					; 7
	.dw TDB+(248*DCB/1000)					; 8
	.dw TDB+(249*DCB/1000)					; 9
	.dw TDB+(250*DCB/1000)					; 250
	.dw TDB+(251*DCB/1000)					; 1
	.dw TDB+(252*DCB/1000)					; 2
	.dw TDB+(253*DCB/1000)					; 3
	.dw TDB+(254*DCB/1000)					; 4
	.dw TDB+(255*DCB/1000)					; 5
.CSEG


;--- Servo connecties
.equ Servo_PORT	= PORTC
.equ Servo_DDR	= DDRC
.equ Servo_PIN	= PINC
.equ Servo_0	= PC0
.equ Servo_1	= PC1
.equ Servo_2	= PC2
.equ Servo_3	= PC3
.equ Servo_4	= PC4
.equ Servo_5	= PC5
.equ Servo_6	= PC6
.equ Servo_7	= PC7

;--- Servo variabelen
;.DSEG
;; Duty-cycles voor 8 servo's
;DUTY_CYCLE_0: .BYTE 2
;DUTY_CYCLE_1: .BYTE 2
;DUTY_CYCLE_2: .BYTE 2
;DUTY_CYCLE_3: .BYTE 2
;DUTY_CYCLE_4: .BYTE 2
;DUTY_CYCLE_5: .BYTE 2
;DUTY_CYCLE_6: .BYTE 2
;DUTY_CYCLE_7: .BYTE 2
;.CSEG



;--- Lees een byte uit EEPROM geheugen
; input: Z-register = het adres
; output: R16 = de gelezen byte
ReadEEPROM:
	;Write-Enable bit moet eerst 0 zijn.
re_1:
	sbic	EECR, EEWE
	rjmp	re_1
	;Het adres instellen in het EEPROM Address Register.
	;512 Bytes = > 9 bits adres (b8-0).
	out		EEARL, ZL
	out		EEARH, ZH
	;Read-Enable signaal geven
	sbi		EECR, EERE
	;(low)byte inlezen via het EEPROM Data-Register
	in		R16, EEDR
	ret




; input: R16 = tabel-(word)element index
; output: word in R17:R16 (high:low)
DutyValue_To_CompareValue:
	push	ZH
	push	ZL
	;Laad het adres van de variabele in register Z (R31:R30)
	; elementen in de tabel zijn words => byte-index*2 gebruiken als echte index
	clr		R17
	ldi		ZL, low(Table_DutyCycles)
	ldi		ZH, high(Table_DutyCycles)
	add		ZL, R16								; Z := Z+R16
	adc		ZH, R17
	add		ZL, R16								; Z := Z+R16
	adc		ZH, R17
	rcall	ReadEEPROM
	push	R16
	; adres verhogen
	adiw	ZL, 1
	rcall	ReadEEPROM
	mov		R17, R16
	pop		R16
	pop		ZL
	pop		ZH
	ret


;; zoek de bytewaarde op die bij de gebruikte duty-cycle hoort
;; output: R16 = duty-cycle byte-waarde
;CompareValue_To_DutyValue:
;	push	R20
;	push	R21
;	push	R22
;	clr		R22									; resultaat
;	lds		R21, DUTY_CYCLE_0					; low
;	lds		R20, DUTY_CYCLE_0+1					; high
;	ldi		ZL, low(Table_DutyCycles)
;	ldi		ZH, high(Table_DutyCycles)
;DoNextDC:
;	; lees een duty-cycle word
;	rcall	ReadEEPROM
;	push	R16
;	adiw	ZL, 1
;	rcall	ReadEEPROM
;	mov		R17, R16
;	pop		R16
;	adiw	ZL, 1
;	; test de waarden
;	cp		R16, R21
;	brne	nextDC
;	cp		R16, R20
;	brne	nextDC
;	; de duty-cycle waarde is gevonden
;	mov		R16, R22
;	rjmp	Done_GetDutyCycle	
;nextDC:
;	inc		R22
;	brne	DoNextDC
;Done_GetDutyCycle:
;	pop		R22
;	pop		R21
;	pop		R20
;	ret


;--- Duty-cycles voor alle servo's op dezelfde stand (R17:R16) (high:low)
;--- input: R17:R16 = duty-cycle timercounter-waarde
DutyCycles_Initialize:
;	sts		DUTY_CYCLE_0, R16
;	sts		DUTY_CYCLE_0+1, R17
;	sts		DUTY_CYCLE_1, R16
;	sts		DUTY_CYCLE_1+1, R17
;	sts		DUTY_CYCLE_2, R16
;	sts		DUTY_CYCLE_2+1, R17
;	sts		DUTY_CYCLE_3, R16
;	sts		DUTY_CYCLE_3+1, R17
;	sts		DUTY_CYCLE_4, R16
;	sts		DUTY_CYCLE_4+1, R17
;	sts		DUTY_CYCLE_5, R16
;	sts		DUTY_CYCLE_5+1, R17
;	sts		DUTY_CYCLE_6, R16
;	sts		DUTY_CYCLE_6+1, R17
;	sts		DUTY_CYCLE_7, R16
;	sts		DUTY_CYCLE_7+1, R17
	out		OCR1BH, R17
	out		OCR1BL, R16
	ret


;;--- Servo's uitschakelen waarvan de duty-cycle
;;--- gelijk is aan de compare-B waarde.
;;--- En de volgende CompareB-waarde bepalen.
;Servo_Puls_Off:
;	push	R16							; low(A)	de huidige compareB waarde
;	push	R17							; high(A)
;	push	R18							; low(B)	de loop-waarde
;	push	R19							; high(B)
;	push	R20							; Servo masker
;	push	R21							; low(C)	de volgende in te stellen duty-cycle waarde
;	push	R22							; high(C)
;	push	R23							; vlaggetje..
;	push	R24							; low(D)	de laagste van de 8 duty-cycles
;	push	R25							; high(D)
;	push	ZL
;	push	ZH
;	; Doorloop alle duty-cycles voor de 8 servo's..
;	; Als de duty-cycle < huidige compareB-waarde dan is die servo al behandeld. (B<A)
;	; Als de duty-cycle == huidige compareB-waarde dan de servo-puls uitschakelen. (B==A)
;	; Als de duty-cycle > huidige compareB-waarde (B>A) dan testen of de duty-cycle < C; Zoja: C:=B
;	in		R16, OCR1BL					; A := huidige Compare-B waarde
;	in		R17, OCR1BH
;	ldi		R21, $FF					; C := $FFFF	"maxword"
;	ldi		R22, $FF
;	ldi		R24, $FF					; D := $FFFF	"maxword"
;	ldi		R25, $FF
;	ldi		R20, 0b00000001				; Servo_0 maskeren
;	clr		R23							; vlaggetje wissen..
;	ldi		ZL, low(DUTY_CYCLE_0)		; Z := adres duty-cycle servo-0
;	ldi		ZH, high(DUTY_CYCLE_0)
;ServoLoop:
;	ld		R18, Z+						; B := [Z]++
;	ld		R19, Z+
;	cp		R18, R16					; vergelijk B met A
;	cpc		R19, R17
;	breq	ServoOff					; B==A, servo-puls uitschakelen
;	brlo	NextServo					; B<A
;	; Nu geldt: B>A
;	;--- De eerstvolgende compareB-waarde bepalen
;	; Is B < C?
;	cp		R18, R21					; vergelijk B met C
;	cpc		R19, R22
;	brsh	NextServo
;	; Nu geldt: B<C
;	mov		R21, R18					; C := B
;	mov		R22, R19
;	ser		R23							; vlaggetje zetten..
;	rjmp	NextServo
;ServoOff:
;	;--- Een servo signaal laag maken
;	push	R18
;	in		R18, Servo_PORT				; Lees de latch van de servo-(output)-poort (ipv. de PIN)
;	com		R20
;	and		R18, R20					; Servo 0 signaal laag maken..
;	out		Servo_PORT, R18
;	com		R20
;	pop		R18
;NextServo:
;	;--- De laagste compareB-waarde bepalen
;	; Is B < D?
;	cp		R18, R24					; vergelijk B met D
;	cpc		R19, R25
;	brsh	LoopNextServo
;	; Nu geldt: B<D
;	mov		R24, R18					; D := B
;	mov		R25, R19
;LoopNextServo:
;	; loop alle servo's
;	lsl		R20							; masker voor volgende servo instellen
;	brne	ServoLoop
;	; De "vlag" in R23 geeft nu aan of er een eerstvolgende compareB-waarde is gevonden..
;	; Als R23 is gezet, dan is de gevonden waarde in C de laagste (eerstvolgende) duty-cycle
;	; Als R23 niet is gezet, dan de laagste duty-cycle in C plaatsen
;	; De laagste duty-cycle waarde staat nu in D.
;	tst		R23
;	brne	Put_CompareB
;	; De laagste duty-cycle van D naar C
;	mov		R21, R24					; C := D
;	mov		R22, R25
;Put_CompareB:
;	; stel de volgende compareB waarde in..
;	out		OCR1BH, R22
;	out		OCR1BL, R21
;
;Done_Servo_Puls_Off:
;	pop		ZH
;	pop		ZL
;	pop		R25
;	pop		R24
;	pop		R23
;	pop		R22
;	pop		R21
;	pop		R20
;	pop		R19
;	pop		R18
;	pop		R17
;	pop		R16
;	ret




;--- Servo's initialiseren
Servo_Initialize:
	; Servo pinnen als output instellen
	ldi		R16, $FF
	out		Servo_DDR, R16
	; Hardware-matige PWM uitschakelen, hardware-matige pin-output ook uitschakelen.
	; We gebruiken alleen de timer-counter en compare registers voor de telling.
	; De pin-out regelen we zelf in de onCompare(A & B)Match handlers.
	ldi		R16, (0<<COM1A1 | 0<<COM1A0 | 0<<COM1B1 | 0<<COM1B0 | 0<<PWM11 | 0<<PWM10)
	out		TCCR1A, R16
	; Timer1 clock instellen.
	ldi		R16, (0<<CS12 | 0<<CS11 | 1<<CS10 | 1<<CTC1)
	out		TCCR1B, R16
	; De Timer1-Counter resetten op een CompareA Match
	;in		R16, TCCR1B
	;ori	R16, (1<<CTC1)
	;out	TCCR1B, R16
	; De Servo-puls-frequentie (timer1-TOP-waarde) instellen
	ldi		R17, high(T1_COMPAREA)
	ldi		R16, low(T1_COMPAREA)
	out		OCR1AH, R17
	out		OCR1AL, R16
	; De duty-cycle instellen op een 16-bit waarde
	ldi		R17, high(ms1_5)
	ldi		R16, low(ms1_5)
	rcall	DutyCycles_Initialize
	; de counter op 0 instellen om direct met een puls te beginnen
	clr		R16
	out		TCNT1H, R16
	out		TCNT1L, R16
	; Interrupts gebruiken: T1-CompareA & T1-CompareB
	in		R16, TIMSK
	ori		R16, (1<<OCIE1A | 1<<OCIE1B)
	out		TIMSK, R16
	ret



;--- Servo frequentie handler
Timer_Interrupt_CompareA:
	push	R16
	in		R16,SREG
	push	R16
	; servo-uitgang signalen op 1
	ser		R16								; Alle 8 servo-signalen op 1
	out		Servo_PORT, R16
	; omdat het CTC1 bit is gezet in het TCCR1B register wordt
	; de counter "automatisch" op 0 gezet bij een CompareA match.
	pop		R16
	out		SREG, R16
	pop		R16
	reti



;--- Servo duty-cycle handler
Timer_Interrupt_CompareB:
	push	R16
	in		R16,SREG
	push	R16
	; Een timer-compare interrupt komt voor als de timer-teller de compare-waarde
	; heeft afgeteld. De CompareB-waarde representeert de pulsbreedte.
	; Als een compare-interrupt plaatsvindt moeten we de pin zelf weer laag maken.
	;rcall	Servo_Puls_Off

	clr		R16
	out		Servo_PORT, R16

	;
	pop		R16
	out		SREG, R16
	pop		R16
	reti



;--- Servo duty-cycle instellen
; input: R16 = Duty-cycle
;        1 byte: $00 = servo helemaal linksom (1ms)
;                $80 = servo in het midden (1.5ms)
;                $FF = servo helemaal rechtsom (2ms)
;        R18 = Servo nummer (0..7)
Servo_Set_DutyCycle:
	;1 servo prg.
	rcall	DutyValue_To_CompareValue
	out		OCR1BH, R17
	out		OCR1BL, R16
	ret

;	; 8 servo's prg.
;	push	R16
;	push	R17
;	push	ZH
;	push	ZL
;	ldi		ZL, low(DUTY_CYCLE_0)
;	ldi		ZH, high(DUTY_CYCLE_0)
;	clr		R17
;	lsl		R18
;	add		ZL, R18
;	adc		ZH, R17
;	; 1 byte in R16 omzetten naar 1 word in DUTY_CYCLE_x. (opzoeken in tabel in EEPROM)
;	rcall	DutyValue_To_CompareValue	
;	; Duty-cycle waarde opslaan in SRAM
;	st		Z+, R17
;	st		Z, R16
;	pop		ZH
;	pop		ZL
;	pop		R17
;	pop		R16
;	ret


;--- Servo duty-cycle opvragen
; output: R16 = Duty-cycle
;        1 byte: $00 = servo helemaal linksom (1ms)
;                $80 = servo in het midden (1.5ms)
;                $FF = servo helemaal rechtsom (2ms)
Servo_Get_DutyCycle:
	rcall	DutyValue_To_CompareValue
	ret



;---
Servo_ProcessMessages:
;	rcall	Get_TWI_IN_Buffer_Count
;	cpi		R16, 0
;	breq	Done_Servo_ProcessMessages
;	rcall	LoadByteFrom_TWI_IN_Buffer				; lees de byte (duty-cycle)
;	rcall	Servo_Set_DutyCycle

	; Servo commando's zijn altijd 2 bytes in lengte (servo# + duty-cycle data byte)
	rcall	Get_TWI_IN_Buffer_Count
	cpi		R16, 2
	brlo	Done_Servo_ProcessMessages
	; Er is een nieuw servo-commando binnen
	rcall	LoadByteFrom_TWI_IN_Buffer				; lees de byte met het servo-nummer
	mov		R18, R16
	andi	R18, $7F
	rcall	LoadByteFrom_TWI_IN_Buffer				; lees de duty-cycle waarde (byte)
	rcall	Servo_Set_DutyCycle

Done_Servo_ProcessMessages:
	ret



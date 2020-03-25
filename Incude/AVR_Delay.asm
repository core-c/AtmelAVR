;---------------------------------------------------------------------------------
;---
;---  Delay constanten en macro's						Ron Driessen
;---  AVR												2005
;---
;---------------------------------------------------------------------------------
.ifndef Linked_AVR_Delay
	.ifndef Link_AVR_Delay						; Deze unit markeren als zijnde ingelinkt,
		.equ Link_AVR_Delay = 1					; in geval dat nog niet eerder is gebeurd in code.
	.endif										; (Units nl. maar 1x inlinken)
	.equ Linked_AVR_Delay = 1					;
.endif





;.equ CK	= 7372800										; AVR clock frequentie
.equ SECOND	= CK											; een seconde in clockticks
.equ MSEC	= CK*0.001										; een milliseconde in clockticks
.equ USEC	= CK*0.000001									; een microseconde in clockticks




.MACRO FillWithNOPs;(Value: 8b-constante)
	.if @0 > 0
		nop
	.endif
	.if @0 > 1
		nop
	.endif
	.if @0 > 2
		nop
	.endif
	.if @0 > 3
		nop
	.endif
	.if @0 > 4
		nop
	.endif
	.if @0 > 5
		nop
	.endif
	.if @0 > 6
		nop
	.endif
	.if @0 > 7
		nop
	.endif
	.if @0 > 8
		nop
	.endif
	.if @0 > 9
		nop
	.endif
	.if @0 > 10
		nop
	.endif
	.if @0 > 11
		nop
	.endif
	.if @0 > 12
		nop
	.endif
	.if @0 > 13
		nop
	.endif
	.if @0 > 14
		nop
	.endif
	.if @0 > 15
		.message "DELAY: >15 x nop (CK>16MHz???)"
	.endif
.ENDMACRO



	;;A) ValueUS microseconden = [Z] totaal aantal cycles te wachten
	;.equ TotalCycles	= ValueUS*USEC
	;;B) aantal loops
	;.equ Loops			= (TotalCycles-2-3)/4+1
	;;C) tot dusver (in loop) gewachtte aantal cycles
	;.equ LoopCycles	= 2+(Loops-1)*4+3
	;;D) rest cycles
	;.equ RestCycles	= TotalCycles - LoopCycles

; Een vertraging in US (micro-seconden).
; maximale vertraging = 999us (=1ms-1us)
;
.MACRO Delay_US;(ValueUS: word)
	.if @0 == 0
		.message "DELAY: 0 US ignored"
	.else
		.if @0 >= 1000
			.error "DELAY: use MS instead of US"
			Delay_MS (@0*0.001)		; /1000 ms wachten..
		.else
			; hoeveel cycles moet de vertraging duren?
			; Aantal cycles = ValueUS*USEC
			.if @0*CK*0.000001 < 5
				; Een minder dan 5 cycles delay maken mbv. nop's
				.message "DELAY: using NOP delay"
				FillWithNOPs (@0*CK*0.000001)
			.else
				; Een delay >5 cycles maken mbv. een loop (+ evt. rest-cycles opvullen met nop's)

				; eerst het aantal loops bepalen: (TotalCycles-2-3)/4+1
				; dan een evt. rest: TotalCycles - LoopCycles  (waarbij LoopCycles = 2+(Loops-1)*4+3)
				ldi		ZH, high((@0*CK*0.000001-2-3)*0.25+1)	; 1 cycle
				ldi		ZL, low((@0*CK*0.000001-2-3)*0.25+1)	; 1 cycle
			_0:	sbiw	ZL, 1									; 2 cycles
				brne	_0										; 2/1 cycles
																;-----------
																; 2+(Loops-1)*4+3 cycles in loop

				; de resterende cycles met nop's vullen (maximaal mod 4).
				; RestCycles = TotalCycles - LoopCycles
;				FillWithNOPs (@0*USEC)-(2+((@0*USEC-2-3)/4+1)*4+3) ; dit geeft een "flex scanner push-back overflow"
				.if (@0*CK*0.000001)-(2+((@0*CK*0.000001-2-3)*0.25+1)*4+3) == 1
					nop
				.endif
				.if (@0*CK*0.000001)-(2+((@0*CK*0.000001-2-3)*0.25+1)*4+3) == 2
					nop
					nop
				.endif
				.if (@0*CK*0.000001)-(2+((@0*CK*0.000001-2-3)*0.25+1)*4+3) == 3
					nop
					nop
					nop
				.endif
			.endif
		.endif
	.endif
.ENDMACRO



; Een vertraging in MS (milli-seconden).
; maximale vertraging = 999ms  (=1s-1ms)
.MACRO Delay_MS;(ValueMS: word)
	.if @0 == 0
		.message "DELAY: 0 MS ignored"
	.else
		.if @0 >= 1000
			.error "DELAY: use S instead of MS"
			Delay_S (@0*0.001)		; /1000
		.else
			.if @0 == 1
				Delay_US 999			; 1ms - 1us vertraging
				; nog 1us te gaan aan cycles..
				Delay_US 1				; 1us vertraging
			.else
				ldi		YH, high(@0-1)	; 1 cycle
				ldi		YL, low(@0-1)	; 1 cycle
			_0:	Delay_US 999			; 1ms - 1us vertraging
				; 1us = USEC cycles te gaan in deze loop-doorgang
				; (waarvan 2 cycles = sbiw, en 2 cycles = brne), (laatste doorgang: 2+1 cycles)
				; Het verschil aanvullen met nop's
				FillWithNOPs (CK*0.000001-4)
				sbiw	YL, 1			; 2 cycles
				brne	_0				; 2/1 cycles
				; er zijn nu uitgevoerd: 2 + (ValueMS-1)*1000US_cycles - 1
				; 		=> rest nog: 1000US_cycles-2+1 cycles
				Delay_US 999
				; nog te gaan: 1US_cycles - 2 + 1 cycles
				FillWithNOPs (CK*0.000001-2+1)
			.endif
		.endif
	.endif
.ENDMACRO





.MACRO Delay_S;(Value: word)
	.if @0 == 0
		.message "DELAY: 0 S ignored"
	.else
		.if @0 > $FFFF
			.error "DELAY: delay too long (>$FFFF seconds)"
		.else
			ldi		XH, high(@0)	; 1 cycle
			ldi		XL, low(@0)		; 1 cyle
		_0:	Delay_MS 999			; 1S = 999MS + 1MS
			Delay_MS 1
			sbiw	XL, 1			; 2 cycles
			brne	_0				; 2/1 cycles
		.endif
	.endif
.ENDMACRO

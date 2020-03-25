;---------------------------------------
;--- Pauze routine's.
;---  Geijkt voor een 7.372800 MHz AVR
;---    1   us	=>      7.3728 clockcycles
;---   40   us	=>    295      clockcycles
;---  100   us	=>    737.28   clockcycles
;---    1   ms	=>   7374      clockcycles
;---    4.1 ms	=>  30288.48   clockcycles
;---    5   ms
;---   15   ms	=> 110592      clockcycles
;---   25   ms
;---  100   ms
;---  150   ms
;---    1.5 s
;---------------------------------------
;--- Register-waarden blijven gelijk
;---------------------------------------


;---------------------------------------
;--- 1 µs
;---------------------------------------
delay1us:
	; een rcall instructie neemt 3 cycles in beslag	|	  1*3 =   3 +
	nop									; 1 cycle	>	  1*1 =	  1 +
	ret									; 4 cycles	|	  1*4 =	  4
										;				-------------
										;				          8 clockcycles


;---------------------------------------
;--- 40 µs
;---------------------------------------
delay40us:								;41 micro-seconde (295 clockcycles)
	; een rcall instructie neemt 3 cycles in beslag	|	  1*3 =   3 +
	push	R20							; 2 cycles	|	  1*2 =   2 +
	ldi		R20, 94						; 1 cycle	|	  1*1 =   1 +
innerloop40us:
	dec		R20							; 1 cycle	|	 94*1 =  94 +
	brne	innerloop40us				; 2 cycles	>	 93*2 = 186 +	;93 x wordt de branche genomen (springen = 2 cycles)
										; 1 cycle	|	  1*1 =   1 +	;bij de laatste branche wordt niet gesprongen (1 cycle)
	pop		R20							; 2 cycles	|	  1*2 =   2 +
	nop									; 1 cycle	|	  1*1 =	  1 +
	nop									; 1 cycle	|	  1*1 =	  1 +
	ret									; 4 cycles	|	  1*4 =   4
										;				-------------
										;				        295 clockcycles



;---------------------------------------
;--- 100 µs  =  0.1 ms
;---------------------------------------
delay100us:								;100 micro-seconde = 0.1 milli seconde
	; een rcall instructie neemt 3 cycles in beslag	|	  1*3 =   3 +
	push	R20							; 2 cycles	|	  1*2 =   2 +
	ldi		R20, 242					; 1 cycle	|	  1*1 =   1 +
innerloop100us:							;			|
	dec		R20							; 1 cycle	|	242*1 = 242 +
	brne	innerloop100us				; 2 cycles	>	241*2 = 482 +	;241 x wordt de branche genomen (springen = 2 cycles)
										; 1 cycle	|	  1*1 =   1 +	;bij de laatste branche wordt niet gesprongen (1 cycle)
	pop		R20							; 2 cycles	|	  1*2 =   2 +
	nop									; 1 cycle	|	  1*1 =	  1 +
	ret									; 4 cycles	|	  1*4 =   4
										;				-------------
										;				        738 clockcycles


;---------------------------------------
;--- 1 ms
;---------------------------------------
delay1ms:
	; een rcall instructie neemt 3 cycles in beslag	|	    1*3 =      3 +	   \
	push	R21							; 2 cycles	|	    1*2 =      2 +		|
	ldi		R21, 9						; 1 cycle	|	    1*1 =      1 +		|
innerloop1ms:							;			|							|
	rcall	delay100us					; 3 cycles	|	  9*738 =   6642 +		|
	dec		R21							; 1 cycle	|	    9*1 =      9 +		|
	brne	innerloop1ms				; 2 cycles	>	    8*2 =     16 +		|
										; 1 cycle	|	    1*1 =      1 +		|
										;				------------------		|
										;				            6674	    >	 6674 +
	;699 cycles to go....				;										|	  699 +
	ldi		R21, 231					; 1 cycle	|	    1*1 =      1 +		|	-----
innerloop1ms_:							;			|							|	 7373 cycles
	dec		R21							; 1 cycle	|	  231*1 =    231 +		|
	brne	innerloop1ms_				; 2 cycles	>	  230*2 =    460 +		|
	pop		R21							; 2 cycles	|	    1*2 =      2 +		|
	nop									; 1 cycle	|	    1*1 =	   1 +		|
	ret									; 4 cycles	|	    1*4 =      4		|
										;				------------------		|
										;				             699	   /


;---------------------------------------
;--- 4.1 ms
;---------------------------------------
delay4_1ms:
	; een rcall instructie neemt 3 cycles in beslag	|	    1*3 =      3 +	   \
	push	R21							; 2 cycles	|	    1*2 =      2 +		|
	ldi		R21, 40						; 1 cycle	|	    1*1 =      1 +		|
innerloop4_1ms:							;			|							|
	rcall	delay100us					; 3 cycles	|	 40*738 =  29520 +		|
	dec		R21							; 1 cycle	|	   40*1 =     40 +		|
	brne	innerloop4_1ms				; 2 cycles	>	   39*2 =     78 +		|
										; 1 cycle	|	    1*1 =      1 +		|
										;				------------------		|
										;				           29645		>	 29645 +
	;644 cycles to go....														|	   644 +
	ldi		R21, 212					; 1 cycle	|	    1*1 =      1 +		|	--------
innerloop4_1ms_:						;			|							|	 30289 cycles
	dec		R21							; 1 cycle	|	  212*1 =    212 +		|
	brne	innerloop15ms_				; 2 cycles	>	  211*2 =    422 +		|
										; 1 cycle	|	    1*1 =      1 +		|
	pop		R21							; 2 cycles	|	    1*2 =      2 +		|
	nop									; 1 cycle	|	    1*1 =	   1 +		|
	nop									; 1 cycle	|	    1*1 =	   1 +		|
	nop									; 1 cycle	|	    1*1 =	   1 +		|
	nop									; 1 cycle	|	    1*1 =	   1 +		|
	ret									; 4 cycles	|	    1*4 =      4		|
										;				------------------		|
										;				             644	   /
	

;---------------------------------------
;--- 5 ms
;---------------------------------------
delay5ms:
	rcall	delay1ms
	rcall	delay1ms
	rcall	delay1ms
	rcall	delay1ms
	rcall	delay1ms
	ret


;---------------------------------------
;--- 15 ms
;---------------------------------------
delay15ms:
	; een rcall instructie neemt 3 cycles in beslag	|	    1*3 =      3 +	   \
	push	R21							; 2 cycles	|	    1*2 =      2 +		|
	ldi		R21, 149					; 1 cycle	|	    1*1 =      1 +		|
innerloop15ms:							;			|							|
	rcall	delay100us					; 3 cycles	|	149*738 = 109962 +		|
	dec		R21							; 1 cycle	|	  149*1 =    149 +		|
	brne	innerloop15ms				; 2 cycles	>	  148*2 =    296 +		|
										; 1 cycle	|	    1*1 =      1 +		|
										;				------------------		|
										;				          110414		>	110414 +
	;178 cycles to go....														|	   178 +
	ldi		R21, 57						; 1 cycle	|	    1*1 =      1 +		|	--------
innerloop15ms_:							;			|							|	110592 cycles
	dec		R21							; 1 cycle	|	   57*1 =     57 +		|
	brne	innerloop15ms_				; 2 cycles	>	   56*2 =    112 +		|
										; 1 cycle	|	    1*1 =      1 +		|
	pop		R21							; 2 cycles	|	    1*2 =      2 +		|
	nop									; 1 cycle	|	    1*1 =	   1 +		|
	ret									; 4 cycles	|	    1*4 =      4		|
										;				------------------		|
										;				             178	   /


;---------------------------------------
;--- 25 ms
;---------------------------------------
delay25ms:
	rcall	delay5ms
	rcall	delay5ms
	rcall	delay5ms
	rcall	delay5ms
	rcall	delay5ms
	ret


;---------------------------------------
;--- 100 ms
;---------------------------------------
delay100ms:
	rcall	delay25ms
	rcall	delay25ms
	rcall	delay25ms
	rcall	delay25ms
	ret


;---------------------------------------
;--- 150 ms
;---------------------------------------
delay150ms:
	rcall	delay100ms
	rcall	delay25ms
	rcall	delay25ms
	ret


;---------------------------------------
;--- 1.5 s
;---------------------------------------
delay1_5s:
	push	R22
	ldi		R22, 100
innerloop1_5s:
	rcall	delay15ms
	dec		R22
	brne	innerloop1_5s
	pop		R22
	ret


;;---------------------------------------
;;--- MultiDelay
;;---------------------------------------
;.MACRO MultiDelay;(DelaySeconds, CK)
;	;aantal cycles = CK*DelaySeconds
;	.if @1*@0 < 7
;		; een rcall neemt 3 cycles in beslag
;		ret	; 4 cycles
;	.else
;		.if @1*@0 < 775
;			; een rcall neemt 3 cycles in beslag
;			push	R25					; 2 cycles
;			ldi		R25, (@1*@0-13)/3	; 1 cycle
;		loop775:
;			dec		R25					; 1 cycle
;			brne	loop775				; 2/1 cycle
;			pop		R25					; 2 cycles
;			ret							; 4 cycles
;		.else
;		.endif
;	.endif
;.ENDMACRO

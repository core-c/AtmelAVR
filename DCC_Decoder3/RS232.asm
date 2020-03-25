

.equ EOS_Character = '$'


;------------------------------------------
;--- Initialiseer de UART. (subroutine)
;---
;--- De te gebruiken baudrate moet 
;--- in register 'temp' worden aangereikt.
;------------------------------------------
UART_Initialize:
	; De baudrate instellen op 19200 (met een afwijking van 0.0% @ 7.3728MHz)
	ldi		temp, 23 ; 19200, 7.372800MHz
	out		UBRR, temp
	;Schakel de receiver, transmitter & RX-int in
	ldi		temp, (1<<RXCIE) | (1<<RXEN) | (1<<TXEN)
	out		UCR, temp
	ret



;------------------------------------------
;--- UART: Verzend een byte. (subroutine)
;---
;--- De te verzenden byte tevoren in
;--- register 'temp' laden.
;------------------------------------------
UART_transmit:
	sbis	USR, UDRE
	rjmp	UART_transmit
	out		UDR, temp
	ret



;------------------------------------------
;--- De UART-Rx Interrupt-Handler
;------------------------------------------
UART_Rx_Interrupt:
	push	R21
	in		R21, SREG
	push	R21
	push	temp

	; Lees de ontvangen byte van het UART Data Register,
	in		temp, UDR

	pop		temp
	pop		R21
	out		SREG, R21
	pop		R21
	reti




;%%;------------------------------------------
;%%;--- De UART-Tx-Complete Interrupt-Handler
;%%;------------------------------------------
;%%UART_Tx_Interrupt:
;%%doneTx:
;%%	reti





;------------------------------------------
;--- Zend een CRLF
;------------------------------------------
UART_CrLf:
	push	R16
	ldi		R16, 13
	rcall	UART_transmit
	ldi		R16, 10
	rcall	UART_transmit
	pop		R16
	ret


;------------------------------------------
;--- Zend een spatie
;------------------------------------------
UART_Space:
	push	R16
	ldi		R16, ' '
	rcall	UART_transmit
	pop		R16
	ret





;------------------------------------------
InitString:
	.db 13,10, "AVR running: DCC_Decoder2.asm", 13,10, EOS_Character
;------------------------------------------
;--- zend een initstring
;------------------------------------------
UART_transmit_InitString:
	ldi		ZL, low(2*InitString)
	ldi		ZH, high(2*InitString)
UART_transmit_String:
	push	R16
txloop:
	push	R0
	lpm
	adiw	ZL,1
	mov		temp, R0
	pop		R0
	cpi		temp, EOS_Character
	breq	endtxloop
	rcall	UART_transmit
	rjmp	txloop
endtxloop:
	pop		R16
	ret




;--- delays @ 7.372800 MHz

;---------------------------------------
;--- 100 �s  =  0.1 ms
;---------------------------------------
delay100us:								;100 micro-seconde = 0.1 milli seconde
	; een rcall instructie neemt 3 cycles in beslag	|	  1*3 =   3 +
	push	R25							; 2 cycles	|	  1*2 =   2 +
	ldi		R25, 242					; 1 cycle	|	  1*1 =   1 +
innerloop100us:							;			|
	dec		R25							; 1 cycle	|	242*1 = 242 +
	brne	innerloop100us				; 2 cycles	>	241*2 = 482 +	;241 x wordt de branche genomen (springen = 2 cycles)
										; 1 cycle	|	  1*1 =   1 +	;bij de laatste branche wordt niet gesprongen (1 cycle)
	pop		R25							; 2 cycles	|	  1*2 =   2 +
	nop									; 1 cycle	|	  1*1 =	  1 +
	ret									; 4 cycles	|	  1*4 =   4


;---------------------------------------
;--- 1 ms
;---------------------------------------
delay1ms:
	; een rcall instructie neemt 3 cycles in beslag	|	    1*3 =      3 +	   \
	push	R26							; 2 cycles	|	    1*2 =      2 +		|
	ldi		R26, 9						; 1 cycle	|	    1*1 =      1 +		|
innerloop1ms:							;			|							|
	rcall	delay100us					; 3 cycles	|	  9*738 =   6642 +		|
	dec		R26							; 1 cycle	|	    9*1 =      9 +		|
	brne	innerloop1ms				; 2 cycles	>	    8*2 =     16 +		|
										; 1 cycle	|	    1*1 =      1 +		|
										;				------------------		|
										;				            6674	    >	 6674 +
	;699 cycles to go....				;										|	  699 +
	ldi		R26, 231					; 1 cycle	|	    1*1 =      1 +		|	-----
innerloop1ms_:							;			|							|	 7373 cycles
	dec		R26							; 1 cycle	|	  231*1 =    231 +		|
	brne	innerloop1ms_				; 2 cycles	>	  230*2 =    460 +		|
	pop		R26							; 2 cycles	|	    1*2 =      2 +		|
	nop									; 1 cycle	|	    1*1 =	   1 +		|
	ret									; 4 cycles	|	    1*4 =      4		|


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
;--- 1.0 s
;---------------------------------------
delay1s:
	push	R27
	ldi		R27, 10
innerloop1s:
	rcall	delay100ms
	dec		R27
	brne	innerloop1s
	pop		R27
	ret

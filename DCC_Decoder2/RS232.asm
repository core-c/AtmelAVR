


;---------------------------------------
;--- De RS232 invoer-buffer in SRAM.
;----------------------------------------------\
.equ RS232_BufferSize = 16						; Buffer
.DSEG                             				; het data-segment aanspreken
RS232_IN_Buffer:		.BYTE RS232_BufferSize	; alloceer de RS232 data-buffer
RS232_IN_Buffer_Input:	.BYTE 2					; het adres voor de nieuw toe te voegen byte
RS232_IN_Buffer_Output:	.BYTE 2					; het adres voor de uit de buffer te lezen byte
RS232_IN_BytesInBuffer:	.BYTE 1					; Het aantal bytes in de buffer
.CSEG
;----------------------------------------------/

.equ EOS_Character	= '$'

;----------------------------------------------\
;!! spreek de routines voor alle mogelijke SRAM adressen aan
StoreByteInto_RS232_IN_Buffer:
	StoreByteSRAMIntoBuffer temp, RS232_IN_Buffer, RS232_IN_Buffer_Input, RS232_IN_BytesInBuffer, RS232_BufferSize
	ret

LoadByteFrom_RS232_IN_Buffer:
	LoadByteSRAMFromBuffer temp, RS232_IN_Buffer, RS232_IN_Buffer_Output, RS232_IN_BytesInBuffer, RS232_BufferSize
	ret

PeekByteFrom_RS232_IN_Buffer:
	PeekByteSRAMFromBuffer temp, RS232_IN_Buffer_Output, RS232_IN_BytesInBuffer
	ret
;----------------------------------------------/


;------------------------------------------
;--- Subroutine: Initialiseer Rx-Data-Buffer
;------------------------------------------
UART_Initialize_Buffer:
	; variabelen instellen voor het aantal bytes in de buffer.
	StoreIByteSRAM RS232_IN_BytesInBuffer, 0
	; De buffer pointers instellen op het begin van de buffer.
	; voor (buffer) inkomende bytes....
	StoreIWordSRAM RS232_IN_Buffer_Input, RS232_IN_Buffer
	; voor (buffer) uitgaande bytes....
	StoreIWordSRAM RS232_IN_Buffer_Output, RS232_IN_Buffer
	ret



;------------------------------------------
;--- Initialiseer de UART. (subroutine)
;---
;--- De te gebruiken baudrate moet 
;--- in register 'temp' worden aangereikt.
;------------------------------------------
UART_Initialize:
;.if device==AT90S8535
	; baudrate
	; De baudrate instellen op 19200 (met een afwijking van 0.0% @ 7.3728MHz)
	ldi		temp, 23 ; 19200
	; De baudrate instellen op 19200 (met een afwijking van 0.2% @ 8MHz)
	;ldi		temp, 25 ; 19200
	out		UBRR, temp
	;inschakelen de receiver, transmitter & RX-int
	ldi		temp, (1<<RXCIE | 1<<RXEN | 1<<TXEN)
	out		UCR, temp
;.elseif device==ATmega32
;	; baudrate
;	; UBRR = CK/(16*Baudrate)-1
;	; dus voor de mega32 op 12MHz en 19200 bps: UBRR=12000000/(16*19200)-1=38
;	ldi		temp, high(38)
;	out		UBRRH, temp
;	ldi		temp, low(38)
;	out		UBRRL, temp
;	;inschakelen de receiver, transmitter & RX-int
;	ldi		temp, (1<<RXCIE | 1<<RXEN | 1<<TXEN)
;	out		UCSRB, temp
;	; asynchroon, parity=none, stopbits=1, databits=8
;	ldi		temp, (1<<URSEL | 0<<UMSEL | 0<<UPM1 | 0<<UPM0 | 0<<USBS | 0<<UCSZ2 | 1<<UCSZ1 | 1<<UCSZ0)
;	out		UCSRC, temp
;	; Rx buffer legen
;	rcall	USART_Flush
;.endif
	ret


;.if device==ATmega32
;------------------------------------------
;--- leeg de Rx buffer
;------------------------------------------
;USART_Flush:
;	sbic	UCSRA, RXC
;	in		temp, UDR
;	sbic	UCSRA, RXC
;	rjmp	USART_Flush
;	ret
;	;sbis	UCSRA, RXC
;	;ret
;	;in		temp, UDR
;	;rjmp	USART_Flush
;	;ret
;------------------------------------------
;.endif



;------------------------------------------
;--- UART: Verzend een byte. (subroutine)
;---
;--- De te verzenden byte tevoren in
;--- register 'temp' laden.
;------------------------------------------
UART_transmit:
;.if device==AT90S8535
	sbis	USR, UDRE
	rjmp	UART_transmit
;.elseif device==ATmega32
;	sbis	UCSRA, UDRE
;	rjmp	UART_transmit
;.endif
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
;	sbi		LED_PORT, LED_RS232			; "RS232 Activity" LED aan

	; Lees de ontvangen byte van het UART Data Register,
	in		temp, UDR
	; plaats de byte in de roterende data-buffer
	rcall	StoreByteInto_RS232_IN_Buffer

;	cbi		LED_PORT, LED_RS232			; "RS232 Activity" LED uit
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
;--- 100 µs  =  0.1 ms
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

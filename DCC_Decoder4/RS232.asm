

.equ EOS_Character = '$'


;------------------------------------------
;--- Initialiseer de UART. (subroutine)
;---
;--- De te gebruiken baudrate moet 
;--- in register 'temp' worden aangereikt.
;------------------------------------------
UART_Initialize:
	; De baudrate instellen op 19200 (met een afwijking van 0.0% @ 7.3728MHz)
	;ldi	temp, 23 ; 19200, 7.372800MHz
	ldi		temp, 3 ; 115200, 7.372800MHz
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

	; Lees de ontvangen byte van het UART Data Register,
	in		R1, UDR

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
;--- Zend een CR
;------------------------------------------
UART_CR:
	push	R16
	ldi		R16, 13
	rcall	UART_transmit
	pop		R16
	ret

;------------------------------------------
;--- Zend een LF
;------------------------------------------
UART_LF:
	push	R16
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
;--- Zend een TAB
;------------------------------------------
UART_TAB:
	push	R16
	ldi		R16, 9
	rcall	UART_transmit
	pop		R16
	ret

;------------------------------------------
;--- Zend een BS
;------------------------------------------
UART_BS:
	push	R16
	ldi		R16, 8
	rcall	UART_transmit
	pop		R16
	ret






;------------------------------------------
InitString: .db 13,10, "AVR running: DCC_Decoder4.asm", 13,10, EOS_Character
;------------------------------------------
;--- zend een initstring
;------------------------------------------
UART_transmit_InitString:
	ldi		ZL, low(2*InitString)
	ldi		ZH, high(2*InitString)
UART_transmit_String:
	push	R16 ;!
	push	R0 ;!!
txloop:
	lpm
	adiw	ZL,1
	mov		R16, R0
	cpi		R16, EOS_Character
	breq	endtxloop
	rcall	UART_transmit
	rjmp	txloop
endtxloop:
	pop		R0 ;!!
	pop		R16 ;!
	ret



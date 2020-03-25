
;*******************************************************************************
;***
;*** Een RC-ontvanger test.
;***
;*** 
;***
;***
;***
;***
;*************************************************************************************
;
.include "8535def.inc"

;--- De RS232 data buffer --------------
.include "RotatingBuffer.asm"
;---------------------------------------

;--- De clock-frequentie (CK) van onze AVR (in Hz.)
.equ CK = 7372800




;--- Register synoniemen ---------------
.def fREG		= R8					; voor gebruik in de ISP's bewaren flag-register
.def temp		= R16
.def tempL		= R17
.def icL		= R18					; input capture Low
.def icH		= R19					; input capture High
.def Treg		= R20					; regsiter tbv. de timer-handler




;--- De vector-tabel -------------------
; Het begin van het CODE-segment
.CSEG									; Het code-segment selecteren
.org 0x0000								; Het begin van de vector-tabel op adres 0 van het geheugen
	rjmp RESET							; Reset Handler
	reti								; External Interrupt 0
	reti								; External Interrupt 1
	reti								; Timer2 compare match
	reti								; Timer2 overflow
	rjmp Timer_Interrupt_InputCapture	; Timer1 Input Capture
	rjmp Timer_Interrupt_CompareA		; Timer1 Output Compare A
	rjmp Timer_Interrupt_CompareB		; Timer1 Output Compare B
	reti								; Timer1 Overflow
	reti								; Timer0 Overflow
	reti								; SPI
	rjmp UART_Rx_Interrupt				; UART Receive Complete
	reti								; UART Data Register Empty
	reti								; UART Transmit Complete
	reti								; ADC Conversion Complete
	reti								; EEPROM Write Complete
	reti								; Analog Comparator
;---------------------------------------




RESET:
	; De stack-pointer instellen op het einde van het RAM
	ldi		temp, high(RAMEND)
	ldi		tempL, low(RAMEND)
	out		SPH, temp
	out		SPL, tempL
	; zorg ervoor dat geen interrupts voorvallen tijdens zetten van deze PWM-mode
	cli
	clr		temp
	out		TIMSK, temp


	;nog even wat LED's aanzetten ter indicatie dat de AVR runt.
	clr		temp
	ori		temp, (1<<PINC2 | 1<<PINC1 | 1<<PINC0)
	out		DDRC, temp
	; alle LED's aan
	ldi		temp, (1<<PINC2 | 1<<PINC1 | 1<<PINC0)
	out		PORTC, temp

	; poort D pin 6 (ICP) als input zetten voor de Input Capture
	ldi		temp, (0<<PIND4)
	out		DDRD, temp
	

	;--- De UART instellen ------------------------------------------------------------------------------
	; de RS232 Data-Ontvangst-Buffer in SRAM inintialiseren
	rcall	UART_Initialize_Buffer
	; De UART zelf initialiseren
	rcall	UART_Initialize


	; Input-Capture interrupts inschakelen
	ldi		temp, (1<<TICIE1)
	out		TIMSK, temp

	; de counter op 0 instellen
	clr		temp
	out		TCNT1H, temp
	out		TCNT1L, temp

	; De Timer1 HW-PWM uitschakelen
	clr		temp
	out		TCCR1A, temp

	; ICNC1: Noise Canceler uitschakelen => input capture om elke sample/capture.
	; ICES1: Input Capture Interrupts op stijgende flank laten genereren.
	; CTC1:  Clear TCNT on compareA match  uitschakelen
	; CS12,CS11 & CS10: clock-select instellen op CK/8
	ldi		temp, (0<<ICNC1 | 1<<ICES1 | 0<<CTC1 | 0<<CS12 | 1<<CS11 | 0<<CS10)
	out		TCCR1B, temp

	; interrupts inschakelen
	sei

;	MAIN_LOOP
eLoop:
	; eventuele seriële data verwerken (zsm).
	rcall	UART_ProcessRecordIn

	; De Input-Capture schrijven over RS232 naar de PC
	mov		temp, icL
	rcall	UART_transmit
	mov		temp, icH
	rcall	UART_transmit
	;	
	rjmp eLoop							; eeuwige lus....









;--- De Timer1-Input Capture Interrupt routine --------------------------------------
Timer_Interrupt_InputCapture:
	; De ICF1 flag in het TIFR-register is nu gezet.
	; Deze flag wordt automatisch gewist als de interrupt-handler wordt uitgevoerd.
;	in		status, SREG
	push	temp

	; De Input-Capture-word lezen
	in		icL, ICR1L
	in		icH, ICR1H

	; De Timer-Counter op 0 instellen om opnieuw te tellen
	clr		temp
	out		TCNT1H, temp
	out		TCNT1L, temp
	;
	pop		temp
;	out		SREG, status
	reti






;--- De Timer-Compare-A Interrupt routine -------------------------------------------
Timer_Interrupt_CompareA:
;	in		status, SREG

	;
;	out		SREG, status
	reti





;--- De Timer-Compare-B Interrupt routine -------------------------------------------
Timer_Interrupt_CompareB:
;	in		status, SREG

	;
;	out		SREG, status
	reti













;------------------------------------------
;--- Subroutine: Initialiseer Rx-Data-Buffer
;------------------------------------------
UART_Initialize_Buffer:
	; variabelen instellen voor het aantal bytes in de buffer.
	StoreByte BytesInBuffer, 0
	; De buffer pointers instellen op het begin van de buffer.
	; voor (buffer) inkomende bytes....
	StoreWord RS232Input, RS232Buffer
	; voor (buffer) uitgaande bytes....
	StoreWord RS232Output, RS232Buffer
	ret



;------------------------------------------
;--- Initialiseer de UART. (subroutine)
;---
;--- De te gebruiken baudrate moet 
;--- in register 'temp' worden aangereikt.
;------------------------------------------
UART_Initialize:
	; De baudrate instellen op 19200
	; (met een afwijking van 0.0% @ 7.3728MHz)
	ldi		temp, 23 ; 19200
	;ldi		temp, 47 ; 9600
	out		UBRR, temp
	;Schakel de receiver, transmitter & TXCint in
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
	; Klaar om te verzenden ??
;	sbis	USR, RXC		;!!!!!DEBUG!!!!! testje
;	rjmp	UART_transmit	;
;	sbis	USR, TXC		;!!!!!DEBUG!!!!! testje
;	rjmp	UART_transmit	;
	;
	sbis	USR, UDRE
	rjmp	UART_transmit
	out		UDR, temp
	ret



;------------------------------------------
;--- De UART-Rx Interrupt-Handler
;------------------------------------------
UART_Rx_Interrupt:
	in		fREG, SREG
	push	temp
	; Lees de ontvangen byte van het UART Data Register,
	in		temp, UDR

	; was er een framing-error??
	in		tempL, USR
	sbrs	tempL, FE
	rjmp	NoFrameError
;@@	; Bij een Frame-Error dan het laatst (gedeeltelijk) ontvangen record negeren
;@@	
;@@	; nog te maken....
	rjmp	doneRx
NoFrameError:

	; was er een overrun?? (laatst ontvangen byte nog niet verwerkt)
	in		tempL, UCR
	sbrs	tempL, 3 						; OR-bit
	rjmp	NoOverrun
;@@	; Bij een overrun dan het laatst (gedeeltelijk) ontvangen record negeren
;@@	
;@@	; nog te maken....
	rjmp	doneRx
NoOverrun:

	; plaats de byte in de roterende data-buffer
	StoreByteIntoBuffer temp, RS232Buffer, RS232Input, BytesInBuffer, RS232BufferSize

doneRx:
	pop		temp
	out		SREG, fREG
	reti




;%%;------------------------------------------
;%%;--- De UART-Tx-Complete Interrupt-Handler
;%%;------------------------------------------
;%%UART_Tx_Interrupt:
;%%doneTx:
;%%	reti



;------------------------------------------
;--- Subroutine: Record in Rx-Data-Buffer??
;------------------------------------------
UART_ProcessRecordIn:
	; Als er genoeg bytes in de buffer staan om een record te vullen dan verwerken die bytes
	LoadRegister temp, BytesInBuffer
	cpi		temp, 1
	brsh	RecordInBuffer
	rjmp	doneCheck
	;
RecordInBuffer:
	; lees een byte uit de buffer
	LoadByteFromBuffer temp, RS232Buffer, RS232Output, BytesInBuffer, RS232BufferSize
	;
	; actie ondernemen met de gelezen byte(s)....	

	;
doneCheck:
	ret





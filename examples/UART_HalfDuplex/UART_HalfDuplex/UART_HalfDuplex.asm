
;**** A P P L I C A T I O N   N O T E   A V R 3 0 4 ************************
;*
;* Title:		Half Duplex Interrupt Driven Software UART 
;* Version:		1.0
;* Last updated:	nov 5 2002, by ØE
;* Target:		AT90Sxxxx (All AVR Devices)
;*
;* Support E-mail:	avr@atmel.com
;*
;* Code Size		:72 words
;* Low Register Usage	:2
;* High Register Usage	:5
;* Interrupt Usage	:External Interrupt,
;*			 Timer/Counter0 overflow interrupt
;*
;* DESCRIPTION
;*
;* This application note describes how to make a half duplex software UART
;* on any AVR device with the 8-bit Timer/Counter0 and External Interrupt.
;* As a lot of control applications communicate in one direction at a time
;* only, a half duplex UART will limit the usage of MCU resources.
;*
;* The constants N and R determine the data rate. R selects clock frequency
;* as described in the T/C Prescaler in the AVR databook. If the T/C pre-
;* scaling factor is denoted C, the following expression yields the data rate:
;*
;*		 XTAL
;*	 BAUD = ------		min. N*C = 17
;*		 N*C		max. N   = 170
;*
;* Absolute minimum value for N*C is 17 (which causes the interrupt flag to be 
;* set again before the interrupt is finished). Absolute maximum is 170.
;* (Caused by the 1.5bit-lenght that is necessary to receive bits correctly.)
;*
;* The UART uses PD2 as receive pin because it utilizes the external interrupt.
;* The transmit-pin is PD4 in this example, but it can be any other pins.
;*
;* Since the UART is half duplex, it can either send or recieve data. It can't
;* do both simoutaneausly. When idle it will automatically recieve incoming
;* data, but if it is transmitting data while incoming data arrives, it will
;* ignore it. Also, if u_transmit is called without waiting for the 'READY' bit
;* in the 'u_status' register to become cleared, it will abort any pending 
;* reception or transmittal.
;*
;*
;* *** Initialization
;*
;*  1. Call uart_init
;*  2. Enable global interrupts (with 'sei')
;*
;* *** Receive
;*
;*  1. Wait until RDR in 'u_status' becomes set
;*  2. Read 'u_buffer'
;*
;* *** Transmit
;*
;* (0. Initialize the UART by executing uart_init and sei)
;*  1. Wait until READY in 'u_status' becomes clear
;*  2. Set 'u_buffer'
;*  3. Call 'u_transmit'
;*
;**************************************************************************

.include "8535def.inc"

;***** BAUD-rate settings

				;BAUD-RATES @1MHz XTAL AND R=1
;.equ	N=104			; 9600
;.equ	N=52			;19200 
;.equ	N=26			;38400
.equ	C=1			;Divisor
.equ	R=1			;R=1 when C=1


				;BAUD-RATES @922kHz XTAL AND R=1
.equ	N=96			; 9600
;.equ	C=1			;Divisor
;.equ	R=1			;R=1 when C=1


;***** UART Global Registers

.def	u_buffer	=r14	;Serial buffer
.def	u_sr		=r15	;Status-register storage
.def	u_tmp		=r16	;Scratchregister
.def	u_bit_cnt	=r17	;Bit counter
.def	u_status	=r18	;Status buffer
.def	u_reload	=r19	;Reload-register (internal - do not use)
.def	u_transmit	=r20	;Data to transmit


;***** Bit positions in the Status-register

.equ	RDR=0			;Receive data ready bit
.equ	TD=6			;Transmitting data (internal - read-only)
.equ	BUSY=7			;Busy-flag (internal - read-only)


;**************************************************************************
;*
;*	PROGRAM START - EXECUTION STARTS HERE
;*
;**************************************************************************
	.cseg

	.org $0000
	rjmp	start			;Reset handler

	.org INT0addr
	rjmp	ext_int0		;External interrupt handler

	.org OVF0addr
	rjmp	tim0_ovf		;Timer0 overflow handler

	.org ACIaddr
	reti				;Analog comparator handler (Not Used)



;**************************************************************************
;*
;* EXT_INT0 - External Interrupt Routine 0
;*
;*
;* DESCRIPTION
;* This routine is executed when a negative edge on the incoming serial
;* signal is detected. It disables further external interrupts and enables
;* timer interrupts (bit-timer) because the UART must now receive the
;* incoming data. 
;*
;* This routine sets bits in the GIMSK, TIFR and TIMSK registers. In this
;* code when the bits are set, it overwrites all other bits. This is done
;* because of the lack of available cycles when it operates at low clock
;* rate and high baudrates.
;*
;*
;* Total number of words	: 12
;* Total number of cycles	: 15 (incl. reti)
;* Low register usage		: 1 (u_sr)
;* High register usage		: 4 (u_bit_cnt,u_tmp,u_status,u_reload)
;*
;**************************************************************************
ext_int0:
	in	u_sr,SREG		;Store Status Register

	ldi	u_status,1<<BUSY	;Set busy-flag (clear all others)

	ldi	u_tmp,(256-(N+N/2)+(29/C));Set timer reload-value (to 1.5
	out	TCNT0,u_tmp		;  bit len). 29 = time delay that
					;  have already been used in this
					;  interrupt plus the time
					;  that will be used by the time
					;  delay between timer interrupt request
					;  and the actual sampling of the first
					;  data bit.

	ldi	u_tmp,1<<TOIE0		;Set bit 1 in u_tmp
	out	TIFR,u_tmp		;   to clear T/C0 overflow flag
	out	TIMSK,u_tmp		;   and enable T/C0 overflow interrupt

	clr	u_bit_cnt		;Clear bit counter
	out	GIMSK,u_bit_cnt		;Disable external interrupt

	ldi	u_reload,(256-N+(8/C))	;Set reload-value (constant).

	out	SREG,u_sr		;Restore SREG
	reti


;**************************************************************************
;*
;* TIM0_OVF - Timer/Counter 0 Overflow Interrupt
;*
;*
;* DESCRIPTION
;* This routine coordinates the transmition and reception of bits. This 
;* routine is automatically executed at a rate equal to the baud-rate. When
;* transmitting, this routine shifts the bits and sends it. When receiving,
;* it samples the bit and shifts it into the buffer.
;*
;* The serial routines uses a status register (u_status): READ-ONLY.
;*		BUSY	This bit indicates whenever the UART is busy
;*		TD	Transmit Data. Set when the UART is transmitting
;*		RDR	Receive Data Ready. Set when new data has arrived
;*			and it is ready for reading.
;*
;* When the RDR flag is set, the (new) data can be read from u_buffer.
;*
;* This routine also sets bits in TIMSK and TIMSK. See ext_int0 description
;*
;* 
;* Total number of words	: 35
;* Total number of cycles	: min. 18, max. 28 - depending on if it is
;*				  receiving or transmitting, what bit is
;*				  pending, etc.
;* Low register usage		: 2 (u_sr,u_buffer)
;* High register usage		: 4 (u_bit_cnt,u_tmp,u_status,u_reload)
;* 
;**************************************************************************
tim0_ovf:
	in	u_sr,SREG		;Store statusregister

	out	TCNT0,u_reload		;Reload timer

	inc	u_bit_cnt		;Increment bit_counter
	sbrs	u_status,TD		;if transmit-bit set
	rjmp	tim0_receive		;    goto receive

	sbrc	u_bit_cnt,3		;if bit 3 in u_bit_cnt (>7) is set
	rjmp	tim0_stopb		;    jump to stop-bit-part

	sbrc	u_buffer,0		;if LSB in buffer is 1
	sbi	PORTD,PD4		;    Set transmit to 1
	sbrs	u_buffer,0		;if LSB in buffer is 0
	cbi	PORTD,PD4		;    Set transmit to 0
	lsr	u_buffer		;Shift buffer right

	ldi u_tmp,INTF0 
	out GIFR,u_tmp ; clear pending ext. int. 
	
	out	SREG,u_sr		;Restore SREG
	reti

tim0_stopb:
	sbi	PORTD,PD4		;Generate stop-bit

	sbrs	u_bit_cnt,0		;if u_bit_cnt==8 (stop-bit)
	rjmp	tim0_ret		;      jump to exit

tim0_complete:
	ldi u_tmp,1<<INTF0 
	out GIFR,u_tmp ; clear pending ext. int. 
	ldi	u_tmp,1<<INT0		;(u_bit_cnt==9):
	out	GIMSK,u_tmp		;Enable external interrupt
	clr	u_tmp 
	out	TIMSK,u_tmp		    ;Disable timer interrupt
	cbr	u_status,(1<<BUSY)|(1<<TD)  ;Clear busy-flag and transmit-flag

tim0_ret:
	out	SREG,u_sr		;Restore status register
	reti

tim0_receive:
	sec				;Set carry
	sbis	PIND,2			;if PD2=LOW         <=== SAMPLE HERE
	clc				;    clear carry
	ror	u_buffer		;Shift carry into data
	in	u_tmp,SREG		;Store SREG

	cpi	u_bit_cnt,9		;if u_bit_cnt!=9 (must sample stop-bit)
	brne	tim0_ret		;   exit interrupt

	out	SREG,u_tmp		;Get old SREG
	rol	u_buffer		;Rotate back data (to get rid of the stop-bit)

	sbr	u_status,1<<RDR		;Clear busy-flag
	rjmp	tim0_complete



;**************************************************************************
;*
;* uart_init - Subroutine for UART initialization
;*
;*
;* DESCRIPTION
;* This routine initializes the UART. It sets the timer and enables the
;* external interrupt (receiving). To enable the UART the global interrupt
;* flag must be set (with SEI).
;*
;*
;* Total number of words	: 8
;* Total number of cycles	: 11 (including the RET instructions)
;* Low register usage		: None
;* High register usage		: 2 (u_tmp,u_status)
;* 
;**************************************************************************
uart_init:	
	ldi	u_tmp,R
	out	TCCR0,u_tmp		;Start timer and set clock source
	ldi	u_tmp,1<<INT0
	out	GIMSK,u_tmp		;Enable external interrupt 0
	ldi	u_tmp,1<<ISC01
	out	MCUCR,u_tmp		;On falling edges
	clr	u_status		;Erase status-byte
	ret



;**************************************************************************
;*
;* uart_transmit - Subroutine for UART transmittal
;*
;*
;* DESCRIPTION
;* This routine initialize the UART to transmit data. The data to be sent
;* must be located in u_transmit. 
;*
;* Warning: This routine cancels all other transmittions or receptions.
;* So be careful. If a byte is being received and the timer interrupt is
;* currently running, the tranmittion may be corrupted. By checking the
;* READY-bit and/or TD-bit in the u_status register for safe transmissions.
;*
;* This routine also sets bits in TIMSK and TIMSK. See ext_int0 description
;*
;*
;* Total number of words	: 13
;* Total number of cycles	: 17 (including RET)
;* Low register usage		: 1 (u_buffer)
;* High register usage		: 4 (u_bit_cnt,u_tmp,u_transmit,u_reload)
;* 
;**************************************************************************
uart_transmit:
	ldi	u_status,(1<<BUSY)|(1<<TD)   ;Set only busy- and transmit flag

	clr	u_tmp
	out	GIMSK,u_tmp		;Disable external interrupt

	ser	u_bit_cnt		;Erase bit-counter (set all bits)
	mov	u_buffer,u_transmit	;Copy transmit-data to buffer

	ldi	u_tmp,1<<TOIE0		;Set bit 1 in u_tmp
	out	TIFR,u_tmp		;  to clear T/C0 overflow flag
	out	TIMSK,u_tmp		;  and enable T/C0 overflow interrupt
	
	ldi	u_reload,(256-N+(8/C))	;Set reload-value
	ldi	u_tmp,(256-N+(14/C))	;Set timer delay to first bit
	out	TCNT0,u_tmp		;Set timer reload-value (1 bit)

	cbi	PORTD,PD4		;Clear output (start-bit)
	ret



;**************************************************************************
;*
;*	Test/Example Program
;*
;* This example program can be used for evaluation of the UART agains a PC
;* running a terminal emulator. If a key is pressed on the PC keyboard, the
;* message 'You typed <characher>' is sent back. The character is also
;* presented on port B.
;*
;**************************************************************************

.def	tmp=r21				;Temp. register
.def	buffer=r22			;Recieved byte
.def	adr=r23				;EEPROM Address

start:	ser	tmp			;Initialize
	ldi tmp, low(RAMEND)
	out SPL, tmp
	out	PORTD,tmp		;Set port D as input with pullups
	sbi	DDRD,DDD4		;    except PD4 -> output with 1's
	out	DDRB,tmp		;Set port B as output with 1's (LED-off)
	out	PORTB,tmp

	rcall	uart_init		;Init UART
	sei				;Enable interrupts

idle:	sbrs	u_status,RDR		;Wait for Character
	rjmp	idle
	mov	buffer,u_buffer		;Get recieved character
	out	PORTB,u_buffer		;Output the byte on port B
	ldi	adr,example_data	;Set/Restore pointer to EEPROM data

loop:	out	EEARL,adr		;Set the EEPROM's address
	sbi	EECR,EERE		;Send the Read strobe
	in	u_transmit,EEDR		;Put the data in the transmit register
	rcall	uart_transmit		;And transmit the data

wait:	sbrc	u_status,TD		;Wait until data is sent
	rjmp	wait

	inc	adr			;Increase pointer
	cpi	adr,example_data+12	;Reached byte 12? (End?)
	breq	idle			;    Yes, wait for new char.

	cpi	adr,example_data+10	;Reached byte 10?
	brne	loop			;    No, jump back

	mov	u_transmit,buffer	;Put data in transmit register
	rcall	uart_transmit		;And transmit it

wait2:	sbrc	u_status,TD		;Wait until data is sent
	rjmp	wait2

	rjmp	loop			;Continue sendig chars


;**************************************************************************
;*
;*	Test/Example program data.
;*
;* This is the data that will be sent back when a character is recieved.
;*
;**************************************************************************
	.eseg
example_data:
	.db	89	;'Y'
	.db	111	;'o'
	.db	117	;'u'
	.db	32	;' '
	.db	116	;'t'
	.db	121	;'y'
	.db	112	;'p'
	.db	101	;'e'
	.db	100	;'d'
	.db	32	;' '
	.db	13	;<CR>
	.db	10	;<LF>

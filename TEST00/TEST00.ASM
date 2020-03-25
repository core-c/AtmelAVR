;***************************************************************************
;*
;* Title	: AVR ISP (Auto adr inc, 19200bps)
;* Version	: 2.0
;* Last updated	: 1998.01.06 (mlund)
;* Target	: AT90S1200
;* File		: ispprog.asm
;* Author       : Atmel Norway
;*
;* DESCRIPTION
;*	The firmware on all programmers now support a unified protocol for 
;*	program and data memory programming. The host computer do not need
;*	to know if the programmer operates in serial or parallel mode.
;*
;*	The following commands are supported. All commands start with a
;*	single letter. The programmer returns 13d (carriage return) or the
;*	data read after the command is finished.
;*
;*                                     +-------------+------------+------+
;*  Commands                           | Host writes | Host reads |      |
;*  --------                           +-----+-------+------+-----+      |
;*                                     | ID  | data  | data |     | Note |
;* +-----------------------------------+-----+-------+------+-----+------+
;* | Enter programming mode            | 'P' |       |      | 13d |   1  |
;* | Set address                       | 'A' | ah al |      | 13d |   2  |
;* | Write program memory, low byte    | 'c' |    dd |      | 13d |   3  |
;* | Write program memory, high byte   | 'C' |    dd |      | 13d |   3  |
;* | Issue Page Write                  | 'm' |       |      | 13d |      |
;* | Read program memory               | 'R' |       |dd(dd)|     |   4  |
;* | Write data memory                 | 'D' |    dd |      | 13d |      |
;* | Read data memory                  | 'd' |       |   dd |     |      |
;* | Chip erase                        | 'e' |       |      | 13d |      |
;* | Write lock bits                   | 'l' |    dd |      | 13d |      |
;* | Write fuse bits                   | 'f' |    dd |      | 13d |  11  |
;* | Read fuse and lock bits           | 'F' |       |   dd |     |  11  |
;* | Leave programming mode            | 'L' |       |      | 13d |   5  |
;* | Select device type                | 'T' |    dd |      | 13d |   6  |
;* | Read signature bytes              | 's' |       | 3*dd |     |      |
;* | Return supported device codes     | 't' |       | n*dd | 00d |   7  |
;* | Return software identifier        | 'S' |       | s[7] |     |   8  |
;* | Return sofware version            | 'V' |       |dd dd |     |   9  |
;* | Return hardware version           | 'v' |       |dd dd |     |   9  |
;* | Return programmer type            | 'p' |       |   dd |     |  10  |
;* | Set LED                           | 'x' |    dd |      | 13d |  12  |
;* | Clear LED                         | 'y' |    dd |      | 13d |  12  |
;* | Universial command                | ':' |  3*dd |   dd | 13d |      |
;* +-----------------------------------+-----+-------+------+-----+------+
;*
;* NOTE 1
;*	The Enter programming mode command MUST be sent one time prior to
;*	the other commands, with the exception of the 't', 'S', 'V', 'v'
;*	and 'T' commands. The 'T' command must be sent before this command
;*	(see note 6).
;*
;*	For programmers supporting both parallel and serial programming
;*	mode this command enters parallel programming mode. For programmers
;*	supporting only serial programming mode, this command enters serial
;*	programming mode.
;*
;* NOTE 2
;*	The ah and al are the high and low order bytes of the address. For
;*	parallel programmers this command issues the Load Address Low/High
;*	Byte command. For serial programmers the address byte is stored for
;*	use by the Read/Write commands.
;*
;* NOTE 3
;*	For parallel programmers this command issues the Program Flash
;*	command. For serial programmers this command iussues the Write
;*	Program Memory Command. For devices with byte-wide program memories
;*	only the low byte command should be used.
;*
;* NOTE 4
;*	The contents of the program memory at the address given by the 'A'
;*	command are written to the serial port in binary form. For byte
;*	wide memories one byte is written. For 16 bit memories two bytes
;*	are written,MSB first.
;*
;* NOTE 5
;*	This command must be executed after the programming is finished.
;*
;* NOTE 6
;*	The select device type command must be sent before the enter
;*	programming command
;*
;* NOTE 7
;*	The supported device codes are returned in binary form terminated
;*	by 0x00.
;*
;* NOTE 8
;*	This return a 7 character ASCII string identifying the programmer.
;*      For the in-system programmer it is "AVR ISP".
;*
;* NOTE 9
;*	The software/hardware version are returned as two ASCII numbers.
;*
;* NOTE 10
;*	This command should be used to identify the programmer type. The
;*	return value is 'S' for serial (or SPI) programmers or 'P' for
;*	parallel programmers.
;*
;* NOTE 11
;*	The write fuse bits command are available only on parallel
;*	programmers and only for AVR devices (device code < 0x80). The host
;*	should use the return programmer type command to determine the
;*	programmer type, do not use the  "AVR PPR" idenifier because other
;*	programmers may be available in the future.
;*
;* NOTE 12
;*	Currently only the AVR development board has LEDs. The other boards
;*	must implement this commands as NOPs.
;*
;* NOTE 13
;*      Devices using Page Mode Programming write one page of flash memory
;*      before issuing a Page Mode Write Pulse.
;***************************************************************************

;**** includes ****

#define AT90S1200
#include "avr.inc"

;***************************************************************************
;*
;* CONSTANTS
;*	device codes
;*
;* DESCRIPTION
;*	The following device codes must be used by the host computer. Note
;*	that the device codes are arbitrary selected, they do not have any
;*	thing in common with the signature bytes stored in the device.
;*
;*	The following devices are supported (make a new table for each
;*	software release):
;*
;*	SW_MAJOR=1, SW_MINOR=5	
;*	AT90S1200 rev. C (abbreviated S1200C)
;*	AT90S1200 rev. D (abbreviated S1200D)
;*	AT90S8515 rev. A (abbreviated S8515A)
;*	AT89S8252 (abbreviated S8252)
;*
;*	SW_MAJOR=1, SW_MINOR=6
;*	AT90S1200 rev. C (abbreviated S1200C)
;*	AT90S1200 rev. D (abbreviated S1200D)
;*	AT90S8515 rev. A (abbreviated S8515A)
;*	AT89S8252 (abbreviated S8252)
;*      ATmega103 rev. A (abbreviated S01838A)
;*
;***************************************************************************

#define	S1200C	0x12
#define	S1200D	0x13
#define	S2313A	0x20
#define	S4414A	0x28
#define	S8515A	0x38
#define	S8252	0x86
#define	S2323A	0x48

#define	S01838C	0x40
#define	S01838D	0x41

;**** Revision Codes ****

#define	SW_MAJOR 2		; Major SW revision number
#define	SW_MINOR 0		; Minor SW revision number
#define	HW_MAJOR 1		; Major HW revision number
#define	HW_MINOR 0		; Minor HW revision number


;***************************************************************************
;*
;* MACROS
;*	Program Macros
;*
;* DESCRIPTION
;*	Change the following four macros if the RESET pin to the
;*	target moves and/or if the SCK/MISO/MOSO moves.
;*
;***************************************************************************


;*****************
;* SPI Constants *
;*****************

#define	MOSI	6		; Bit number on PORTB
#define	MISO	5		; Bit number on PORTB
#define	SCK	7		; Bit number on PORTB


;******************
;* UART Constants *
;******************

;**** Constant declarations Data Rate ****

;#define	N 95			; 115200 BAUD when R=1 and XTAL=11.059MHz
;#define	N 31			; 57600 BAUD when R=2 and XTAL=11.059MHz
;#define	N 43			; 38400 BAUD when R=2 and XTAL=11.059MHz
#define	N 33			; 19200 BAUD when R=2 and XTAL=4.00MHz
;#define	N 102			; 38400 BAUD when R=1 and XTAL=4.00MHz
#define	R 2

;**** UART transmit pin in PORTD ****

#define	TXPIN 1
#define	RXPIN 0			; Receive pin must be external interrupt !!

;**** Bit positions in UART Status Register ****

#define	TXC 0			; Transmit
#define	RXC 1			; Receive


;*****************************
;* Global Register Variables *
;*****************************

#define	device	r16		; Device code
#define	temp1	r17
#define	temp2	r18
#define	s_data	r19		; SPI data
#define	u_data	r20		; UART data
#define	addrl	r21		; Low order byte of address
#define	addrh	r22		; High order byte of address
#define	bit_cnt	r23		; Bit count used by UART routine
#define	u_stat	r24		; Status byte used by UART routine
#define	cmd	r25		; Serial programming command
#define	count	r26		; Time out variable for "enter programming mode"
#define	param1	r27
#define	cmd1	r28
#define	cmd2	r29
#define	cmd3	r30

#define set_reset	sbi	PORTB,4
#define	clr_reset	cbi	PORTB,4

#define ddrd_init	nop	sbi	DDRD,3

; PB5 is input, the rest is output
#define ddrb_init	ldi	temp1,0xdf \
			out	DDRB,temp1 
			
; PB4 (RESET) is output, the rest is input
#define	ddrb_release	ldi	temp1,(1<<4) \
			out	DDRB,temp1 


;*********************
;* Interrupt Vectors *
;*********************

	seg abs=0 flash.vectors
	rjmp	RESET		; Reset Handle
	reti			; IRQ0 Handle (not used)
	rjmp	TIM0_OVF	; Timer0 Overflow Handle
	reti			; Analog Comparator Handle (not used)

;********
;* Code *
;********
	seg flash.code

;***************************************************************************
;*
;* INTERRUPT
;*	TIM0_OVF - Software UART Service Routine
;*
;***************************************************************************

TIM0_OVF:
	in	r0,SREG		; store SREG
	ldi	temp1,(256-N+8)
	out	TCNT0,temp1	; reset T/C0 to one bit lenght
	inc	bit_cnt		; increment bit counter
	sbrs	u_stat,TXC	; if (transmit complete flag clear)
	rjmp	transmit	;    goto transmit

to_0:	sec			; set carry
	sbis	PIND,RXPIN	; if (RxD == LOW)
	clc			;	clear carry
	ror	u_data		; shift carry into u_data

	cpi	bit_cnt,8	; if (bit_cnt == 8)
	brne	to_1		; {
	clr	temp1		;    disable T/C0 Overflow Interrupt
	out	TIMSK,temp1
	sbr	u_stat,1<<RXC	;    set receive complete
to_1:				; }
	out	SREG,r0	        ; restore SREG
	reti			; exit

transmit:
	cpi	bit_cnt,1	; if (bit_cnt == 1)	\\ start bit
	brne	to_2		; {
	cbi	PORTD,TXPIN	;	generate start bit
	rjmp	to_1		;	exit
to_2:				; }
	cpi	bit_cnt,10	; if (bit_cnt == 10)	\\ stop bit
	brne	to_3		; {
	sbi	PORTD,TXPIN	;	generate stop bit
	clr	temp1		;	disable TC0 overflow interrupt
	out	TIMSK,temp1
	sbr	u_stat,1<<TXC	;	set transmit complete bit
	rjmp	to_1		;	exit
to_3:				; }
	sbrc	u_data,0	; if (LSB set)
	sbi	PORTD,TXPIN	;	PD3 = HIGH
	sbrs	u_data,0	; if (LSB clear)
	cbi	PORTD,TXPIN	;	PD3 = LOW
	lsr	u_data		; shift left u_data
	rjmp	to_1		; exit


;***************************************************************************
;*
;* FUNCTION
;*	u_init
;*
;* DESCRIPTION
;*	Initialize UART.
;*
;***************************************************************************

u_init:	ldi	u_stat,1<<TXC	; set TXC
	ldi	temp1,R		; set clock rate
	out	TCCR0,temp1
	sbi	DDRD,TXPIN	; initialize UART pins
	cbi	DDRD,RXPIN
	ret


;***************************************************************************
;*
;* FUNCTION
;*	putc
;*
;* DESCRIPTION
;*	Send a character on the UART Tx line.
;*
;***************************************************************************

putc:	clr	u_stat		; clear UART status flags
	clr	bit_cnt		; clear bit counter
	ldi	temp1,1<<TOV0	; enable T/C0 overflow interrupt
	out	TIMSK,temp1
putc0:	sbrs	u_stat,TXC	; while (!(u_stat & TXC)); // Wait for TXC
	rjmp	putc0
	ret


;***************************************************************************
;*
;* FUNCTION
;*	getc
;*
;* DESCRIPTION
;*	Wait for start bit and receive a character on the UART Rx line.
;*
;***************************************************************************

getc:	sbis	PIND,RXPIN
	rjmp	getc
getc0:	sbic	PIND,RXPIN
	rjmp	getc0
	ldi	temp1,(256-(N+N/2)+8+12);
	out	TCNT0,temp1 	; preset T/C0 to 1.5 bit lengths
	ldi	temp1,1<<TOIE0
	out	TIFR,temp1	; clear T/C0 overflow flag
	out	TIMSK,temp1	; enable T/C0 overflow Interrupt
	clr	bit_cnt		; clear bit counter
getc1:	sbrs	u_stat,RXC	; wait for Receive Complete
	rjmp	getc1
	cbr	u_stat,1<<RXC	; clear RXC
	ret


;***************************************************************************
;*
;* FUNCTION
;*	delay
;*
;* DESCRIPTION
;*	 Make a small delay.
;*
;***************************************************************************

delay:	ldi	temp2,0xff
dl:	dec	temp2
	brne	dl
	dec	temp1
	brne	delay
	ret


;***************************************************************************
;*
;* FUNCTION
;*	wrser
;*
;* DESCRIPTION
;*	 Write a byte to the SPI.
;*
;***************************************************************************

wrser:	ldi	temp1,8
wrs0:	rol	s_data
	brcc	wrs1
	sbi	PORTB,MOSI
	rjmp	wrs2
wrs1:	cbi	PORTB,MOSI
wrs2:	
	sbi	PORTB,SCK
	ldi	temp2,6
am0:	dec	temp2
	brne	am0
	cbi	PORTB,SCK
	ldi	temp2,1		; 3
am1:	dec	temp2
	brne	am1
	
	dec	temp1
	brne	wrs0
	ret


;***************************************************************************
;*
;* FUNCTION
;*	rdser
;*
;* DESCRIPTION
;*	 Read a byte from the SPI.
;*
;***************************************************************************

rdser:	ldi	temp1,8
	ldi	s_data,0
rd0:	lsl	s_data
	sbic	PINB,MISO
	ori	s_data,1
	
	sbi	PORTB,SCK
	ldi	temp2,6
bm0:	dec	temp2
	brne	bm0
	cbi	PORTB,SCK
	ldi	temp2,1		; 3
bm1:	dec	temp2
	brne	bm1
	
	dec	temp1
	brne	rd0
	ret


;***************************************************************************
;*
;* FUNCTION
;*	spiinit (Enter programming mode)
;*
;* DESCRIPTION
;*	Initialize SPI interface on AVR or 'AT89 device.
;*
;***************************************************************************

spiinit:ddrd_init		; initialize port D
	ddrb_init		; initialize port B
	cbi	PORTB,SCK	; clear SCK
	cpi	device,S8252	; if (device != S8252)
	breq	s89		; {
	set_reset		;	set RESET = 1
	ldi	temp1,0xff	;	delay(0xff);
	rcall	delay
	clr_reset		;	set RESET = 0
	rjmp	s0		; }
				; else
s89:				; {
	clr_reset		; 	set RESET = 0
	ldi	temp1,0xff	;	delay(0xff);
	rcall	delay
	set_reset		;	set RESET = 1
s0:				; }
	ldi	temp1,0xff	; delay(0xff);
	rcall	delay

	ldi	s_data,0xac	; wrser(0xac);		// SPI write (byte 1)
	rcall	wrser
	ldi	s_data,0x53	; wrser(0x53);		// SPI write (byte 2)
	rcall	wrser

				; // SPI Synchronization (fix!)
	cpi	device,0x20	; if ( (device >= 0x20) && (device <= 0x7F) )
	brlo	s2
	tst	device
	brmi	s2
s0b:				; {
	ldi	count,32	;	count = 32;
s1:				;	do {
	rcall	rdser		;		if (rdser == 0x53)	// SPI read (byte 3)
	cpi	s_data,0x53
	breq	s3		;			break;
	ldi	s_data,0x00	;		wrser(0x00);		// SPI write (byte 4)
	rcall	wrser

	
	sbi	PORTB,SCK
	ldi	temp2,6
cm0:	dec	temp2
	brne	cm0
	cbi	PORTB,SCK
	ldi	temp2,1		; 3
cm1:	dec	temp2
	brne	cm1
	
				;		pulse SCK
	ldi	s_data,0xac	;		wrser(0xac);		// SPI write (byte 1)
	rcall	wrser
	ldi	s_data,0x53	;		wrser(0x53);		// SPI write (byte 2)
	rcall	wrser
	dec	count		;	} while(--count);
	brne	s1
	rjmp	s3		; }
				; else
s2:				; {
	ldi	s_data,0x00	;	wrser(0x00);		// SPI write (byte 3)
	rcall	wrser
s3:				; }
	cpi	device,S8252	; if (device != S8252)
	breq	s4		; {
	ldi	s_data,0x00	;	wrser(0x00);	// SPI write (byte 4)
	rcall	wrser
s4:				; }
	ldi	temp1,0x10	; delay(0x10);
	rcall	delay
	ret



;***************************************************************************
;*
;* FUNCTION
;*	show_id
;*
;* DESCRIPTION
;*	Show our ID ("AVR ISP") on the serial line.
;*
;***************************************************************************

show_id:ldi	u_data,0x41		; 'A'
	rcall	putc
	ldi	u_data,0x56		; 'V'
	rcall	putc
	ldi	u_data,0x52		; 'R'
	rcall	putc
	ldi	u_data,0x20		; ' '
	rcall	putc
	ldi	u_data,0x49		; 'I'
	rcall	putc
	ldi	u_data,0x53		; 'S'
	rcall	putc
	ldi	u_data,0x50		; 'P'
	rcall	putc
	ret


;***************************************************************************
;*
;* RESET
;*
;* DESCRIPTION
;*	Initialization
;*
;***************************************************************************

RESET:	clr	temp1
	out	GIMSK,temp1	; disable external interrupt
	ser	temp1		; Initialize
	out	PORTD,temp1
	set_reset		; set RESET=1
	out	PORTB,temp1
	ddrb_release
	rcall	u_init		; Initialize UART
	sei			; Enable interrupts


;***************************************************************************
;*
;* PROGRAM
;*	waitcmd -> main
;*
;* DESCRIPTION
;*	Wait for and execute commands.
;*
;***************************************************************************

waitcmd:rcall	getc		; while (getc() == ESC) {};
	cpi	u_data,0x1b
	breq	waitcmd

;**** Device Type ****

	cpi	u_data,0x54     ; 'T' Device type
	brne	w0
	rcall	getc		; getc();	// dummy
	mov	device,u_data	; putc(device);
	rjmp	put_ret

;**** Return Software Identifier ****

w0:	cpi	u_data,0x53	; 'S' Return software identifier
	brne	w1
	rcall	show_id		; show_id();
	rjmp	waitcmd

;**** Return Software Version ****

w1:	cpi	u_data,0x56	;'V' Return software version
	brne	w2
	ldi	u_data,0x30+SW_MAJOR ; putc(0x30+SW_MAJOR);
	rcall	putc
	ldi	u_data,0x30+SW_MINOR ; putc(0x30+SW_MINOR);
	rcall	putc
	rjmp	waitcmd

;**** Return Hardware Version ****

w2:	cpi	u_data,0x76	;'v' Return hardware version
	brne	w3
	ldi	u_data,0x30+HW_MAJOR ; putc(0x30+HW_MAJOR);
	rcall	putc
	ldi	u_data,0x30+HW_MINOR ; putc(0x30+HW_MINOR);
	rcall	putc
	rjmp	waitcmd

;**** Show Supported Devices ****

w3:	cpi	u_data,0x74	; 't' Show supported devices
	brne	w4
	ldi	u_data,S1200C	; putc(S1200C);
	rcall	putc
	ldi	u_data,S1200D	; putc(S1200D);
	rcall	putc
	ldi	u_data,S2313A	; putc(S2313A);
	rcall	putc
	ldi	u_data,S4414A	; putc(S4414A);
	rcall	putc
	ldi	u_data,S8515A	; putc(S8515A);
	rcall	putc
	ldi	u_data,S2323A	; putc(S2323A);
	rcall	putc
	ldi	u_data,S8252	; putc(S8252);
	rcall	putc
	ldi	u_data,0x00	; putc(0x00);	// end of device list
	rcall	putc
	rjmp	waitcmd

;**** Return Programmer Type ****

w4:	cpi	u_data,0x70     ; 'p' Return programmer type
	brne	w5
	ldi	u_data,0x53     ; putc('S');	// serial programmer
	rcall	putc
	rjmp	waitcmd

;**** Set LED ****

w5:	cpi	u_data,0x78	; 'x' Set LED (ignored)
	brne	w6
	rjmp	put_ret

;**** Clear LED ****

w6:	cpi	u_data,0x79     ; 'y' Clear LED (ignored)
	brne	w7
	rjmp	put_ret

;**** Enter Programming Mode ****

; We require that the device code be selected before any of the other commands

w7:
	cpi	device,S1200C	; if ((device != S1200C) &&
	breq	w72
	cpi	device,S1200D	;     (device != S1200D) &&
	breq	w72
	cpi	device,S8515A	;     (device != S8515A) &&
	breq	w72
	cpi	device,S4414A	;     (device != S4414A) &&
	breq	w72
	cpi	device,S2313A	;     (device != S2313A) &&
	breq	w72
	cpi	device,S8252	;     (device != S8252) &&
	breq	w72
	cpi	device,S01838C	;     (device != S01838C) &&
	breq	w72
	cpi	device,S01838D	;     (device != S01838D) &&
	breq	w72
	cpi	device,S2323A	;     (device != S2323A))
	breq	w72
	rjmp	put_err		;	goto put_err();

w72:	cpi	u_data,0x50	; 'P' Enter programming mode
	brne	w8
	rcall	spiinit		; spiinit();
	rjmp	put_ret

;**** Wait Program Memory ****

;* USAGE
;*	wait_pm(byte cmd, byte c_data);
;*
;*	cmd :		0x28 - wait for high byte written
;*			0x20 - wait for low byte written
;*	u_data :	current data written

;wait_pm:			; do
;				; {
;	mov	s_data,cmd	;	wrser(cmd);		// SPI write (byte 1)
;	rcall	wrser
;	mov	s_data,addrh	;	wrser(addrh);		// SPI write (byte 2)
;	rcall	wrser
;	mov	s_data,addrl	;	wrser(addrl);		// SPI write (byte 3)
;	rcall	wrser
;	rcall	rdser		;	s_data = rdser();	// SPI read (byte 4)
				; }
;	cp	s_data,u_data	; while(s_data != u_data);
;	brne	wait_pm
;	ret

;**** Write Program Memory, High Byte ****

w8:	cpi	u_data,0x43	; 'C' Write program memory, high byte
	brne	w9
	rcall	getc
	cpi	device,S8252	; if (device == S8252)
	brne	w81		; {
	rjmp	put_err		; 	goto err();
				;	// (AT89 series have byte wide program memory !)
				; }
w81:	ldi	s_data,0x48	; wrser(0x48);		// SPI write (byte 1)
	rcall	wrser
	mov	s_data,addrh	; wrser(addrh);		// SPI write (byte 2)
	rcall	wrser
	mov	s_data,addrl	; wrser(addrl);		// SPI write (byte 3)
	rcall	wrser
	cpi	device,S01838C	; invert data on 01838 rev C!
	brne	w81b
	com	u_data
w81b:
	mov	s_data,u_data	; wrser(u_data);	// SPI write (byte 4)
	rcall	wrser
	cpi	device,S01838C	; no delay for S01838 (Uses Page Write Mode instead)
	breq	w82
	cpi	device,S01838D
	breq	w82

	ldi	temp1,0x20	; delay(0x20);		// 24585 cycles delay
	rcall	delay		;			// Page mode requires no delay!
w82:
	ldi	temp1,0x01	; Auto increment address				!!!!
	clr	temp2
	add	addrl,temp1
	adc	addrh,temp2
	rjmp	put_ret		; goto reply();

;**** Write Program Memory, Low Byte ****

w9:	cpi	u_data,0x63     ; 'c' Write program memory, low byte
	brne	w12
	rcall	getc

	cpi	device,S8252	; if (device != S8252)
	breq	w989		; {
	ldi	s_data,0x40	;	wrser(0x40);	// SPI write (byte 1)
	rcall	wrser
	mov	s_data,addrh	;	s_data = addrh;
	rjmp	w91		; }
				; else
w989:				; {
	mov	s_data,addrh	;	s_data = (addrh << 3) | 0x02;
	rcall	shift_s_data3
	ori	s_data,0x02
w91:				; }
	rcall	wrser		; wrser(s_data);	// SPI write (byte 2)
	mov	s_data,addrl	; wrser(addrl);		// SPI write (byte 3)
	rcall	wrser
	cpi	device,S01838C	; invert data on 01838 rev C!
	brne	w91b
	com	u_data
w91b:
	mov	s_data,u_data	; wrser(u_data);	// SPI write (byte 4)
	rcall	wrser
	cpi	device,S01838C	; no delay for S01838 (Uses Page Write Mode instead)
	breq	w92
	cpi	device,S01838D
	breq	w92
	ldi	temp1,0x20	; delay(0x20);		// 24585 cycles delay
	rcall	delay		;			// Page mode requires no delay!
w92:
	rjmp	put_ret		; goto reply();

;**** Read Program Memory ****

w12:	cpi	u_data,0x52	; 'R' Read program memory
	brne	w10		;
	cpi	device,S8252	; if (device != S8252)
	breq	w1289		; {
	ldi	s_data,0x28	;	wrser(0x28);	// SPI write (byte 1)
	rcall	wrser
	mov	s_data,addrh	;	s_data = addrh;
	rjmp	w121		; }
				; else
w1289:				; {
	mov	s_data,addrh	;	s_data = (addrh << 3) | 0x01;
	rcall	shift_s_data3
	ori	s_data,0x01
w121:				; }
	rcall	wrser		; wrser(s_data);	// SPI write (byte 2)
	mov	s_data,addrl	; wrser(addrl);		// SPI write (byte 3)
	rcall	wrser
	rcall	rdser		; putc(rdser());	// Send data (byte 4)
	mov	u_data,s_data
	rcall	putc
	cpi	device,S8252	; if (device == S8252)
	brne	w122		; {
	rjmp	waitcmd		;	goto waitcmd();
				; }
				; else
w122:				; {
	ldi	s_data,0x20	;	wrser(0x20);	// SPI write (byte 1)
	rcall	wrser
	mov	s_data,addrh	;	wrser(addrh);	// SPI write (byte 2)
	rcall	wrser
	mov	s_data,addrl	;	wrser(addrl);	// SPI write (byte 3)
	rcall	wrser
	rcall	rdser		;	putc(rdser());	// Send data (byte 4)
	mov	u_data,s_data
	rcall	putc

	ldi	temp1,0x01	;	Auto increment address				!!!!
	clr	temp2
	add	addrl,temp1
	adc	addrh,temp2

	rjmp	waitcmd		;	goto waitcmd();
				; }
shift_s_data3:
	lsl	s_data
	lsl	s_data
	lsl	s_data
	ret

;**** Load Address ****

w10:	cpi	u_data,0x41	; 'A' Load address
	brne	w11
	rcall	getc		; addrh = getc();
	mov	addrh,u_data
	rcall	getc		; addrl = getc();
	mov	addrl,u_data
	rjmp	put_ret		; goto reply();

;**** Write Data Memory ****

w11:	cpi	u_data,0x44	; 'D' Write data memory
	brne	w13
	rcall	getc
	cpi	device,S8252
	breq	w1189

	ldi	s_data,0xc0
	rcall	wrser
	mov	s_data,addrh
	rjmp	w111

w1189:	mov	s_data,addrh
	rcall	shift_s_data3
	ori	s_data,0x06

w111:	rcall	wrser
	mov	s_data,addrl
	rcall	wrser
	mov	s_data,u_data
	rcall	wrser
	ldi	temp1,0x20
	rcall	delay
	rjmp	put_ret

;;**** Read Data Memory ****

w13:	cpi	u_data,0x64	; 'd' Read data memory
	brne	w14
	cpi	device,S8252	; if (device != S8252)
	breq	w1389		; {
	ldi	s_data,0xa0	;	wrser(0xA0);	// SPI write (byte 1)
	rcall	wrser
	mov	s_data,addrh	;	s_data = addrh;
	rjmp	w131		; }
				; else
w1389:				; {
	mov	s_data,addrh	;	s_data = (addrh << 3) | 0x05;
	rcall	shift_s_data3
	ori	s_data,0x05
w131:				; }
	rcall	wrser		; wrser(s_data);	// SPI write (byte 2)
	mov	s_data,addrl	; wrser(addrl);		// SPI write (byte 3)
	rcall	wrser
	rcall	rdser		; putc(rdser());	// Send data (byte 4)
	mov	u_data,s_data
	rcall	putc
	rjmp	waitcmd		; goto waitcmd();


;**** Leave Programming Mode ****

w14:	cpi	u_data,0x4c	; 'L' Leave programming mode
	brne	w15
	ddrb_release
	cpi	device,S8252
	breq	w141
	set_reset		; set RESET = 1
	rjmp    put_ret
w141:	clr_reset		; set RESET = 0
	rjmp	put_ret

;**** Chip Erase ****

w15:	cpi	u_data,0x65     ; 'e' Chip erase
        brne	w16
	ldi	s_data,0xac
	rcall	wrser
	cpi	device,S8252
	breq	w1589
	ldi	s_data,0x80
	rcall	wrser
w1589:	ldi	s_data,0x04
	rcall	wrser
	ldi	s_data,0x00
	rcall	wrser
	ldi	temp1,0x30
	rcall	delay
	rjmp	put_ret

;**** Write Lock Bits ****

w16:	cpi	u_data,0x6c	; 'l' Write lock bits
	brne	w17
	rcall	getc
	ldi	s_data,0xac
	rcall	wrser
	mov	s_data,u_data
	cpi	device,S8252
	breq	w1689
	andi	s_data,0x06
	ori	s_data,0xe0
	rcall	wrser
	ldi	s_data,0x00
	rcall	wrser
	rjmp	w162

w1689:	andi	s_data,0xe0
	ori	s_data,0x07
	rcall	wrser
w162:	ldi	s_data,0x00
	rcall	wrser
	ldi	temp1,0x30
	rcall	delay
	rjmp	put_ret

;**** Read Signature Bytes ****

w17:	cpi	u_data,0x73	; 's' Read signature bytes
	brne	w18
	cpi	device,S8252
	brne	w17begin
	rjmp	put_err
w17begin:
	ldi	param1,0x02
	rcall	w17call
	ldi	param1,0x01
	rcall	w17call
	ldi	param1,0x00
	rcall	w17call
	rjmp	waitcmd

w17call:ldi	s_data,0x30
	rcall	wrser
	ldi	s_data,0x00
	rcall	wrser
	mov	s_data,param1
	rcall	wrser
	rcall	rdser
	mov	u_data,s_data
	rcall	putc
	ret


;**** Write Program Memory Page ****

w18:	cpi	u_data,0x6D	; 'm' Write Program Memory Page
	brne	w19

	ldi	s_data,0x4c	;	wrser(0x4c);	// SPI write (byte 1)
	rcall	wrser

	mov	s_data,addrh	;	wrser(addrh);	// SPI write (byte 2)
	rcall	wrser
	mov	s_data,addrl	;	wrser(addrl);	// SPI write (byte 3)
	rcall	wrser

	ldi	s_data,0x00	;	wrser(0x00);	// SPI write (byte 4)
	rcall	wrser
	ldi	temp1,0xff	; 	delay(0xFF);	// 0x20 = 24585 cycles delay
	rcall	delay
	rjmp	put_ret

;**** Universal Command ****

w19:	cpi	u_data,0x3A	; ':' Universal Command
	brne	w99

	rcall	getc
	mov	cmd1,u_data
	rcall	getc
	mov	cmd2,u_data
	rcall	getc
	mov	cmd3,u_data
	rcall	universal
	ldi	temp1,0xff	; 	delay(0xFF);	// 0x20 = 24585 cycles delay
	rcall	delay
	rjmp	put_ret

universal:
	mov	s_data,cmd1
	rcall	wrser
	mov	s_data,cmd2
	rcall	wrser
	mov	s_data,cmd3
	rcall	wrser
	rcall	rdser
	mov	u_data,s_data
	rcall	putc
	ret

w99:

;**** Command Error ****

put_err:
	ldi	u_data,0x3f	; putc('?');	// send '?'
	rcall	putc
	rjmp	waitcmd

;**** Reply Command ****

put_ret:
	ldi	u_data,0x0d	; putc(0x0D);	// send CR
	rcall	putc
	rjmp	waitcmd



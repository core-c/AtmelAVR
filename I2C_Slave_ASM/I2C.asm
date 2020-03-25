;**** A P P L I C A T I O N   N O T E   A V R 3 0 2 ************************
;*
;* Title		: TWI Slave Implementation
;* Version		: 1.2
;* Last updated		: 2002.05.03
;* Target		: AT90Sxxxx (All AVR Device)
;*			  Fast Mode: AT90S1200 only
;*
;* Support email	: avr@atmel.com
;*
;* Code Size		: 160 words
;* Low Register Usage	: 0
;* High Register Usage	: 5
;* Interrupt Usage	: External Interrupt0,
;*			  Timer/Counter0 overflow interrupt
;*
;* DESCRIPTION
;* 	This application note shows how to implement an AVR AT90S1200 device
;*	as an TWI slave peripheral. For use with other AT90S AVR devices, other
;*	I/O pins might have to be used, and the stack pointer might have to be
;*	initialized.
;*	Received data is stored in r1* and r1* is transmitted during a master
;*	read transfer. This simple protocol is implemented for demonstration
;*	purposes only. (*c)
;*
;*	Some features :
;*	* Interrupt based (using INT0 and TIM0).
;*	* The device can be given any 7-bit address. (Expandable to 10bit).
;*	* Supports normal and fast mode.
;*	* Easy insertion of "wait states".
;*	* Size and speed optimized.
;*	* Supports wake-up from idle mode.
;*
;*	Refers to the application note AVR302 documentation for more
;*	detailed description.
;*
;* USAGE
;*	Insert user code in the two locations marked "insert user code here".
;*
;* NOTES
;*	Minimum one instruction will be executed between each interrupt.
;*
;* STATISTICS
;*	Code Size	: 160
;*	Register Usage	: 5 High, 0 Low   (c* 4 high, 1 Low)
;*	Interrupt Usage	: EXT_INT0 and TIM0_OVF
;*	Port Usage		: PD4(T0) and PD2(INT0)
;*	XTAL			: - TWI Fast Mode     : min 16.0MHz
;*			 		  - TWI Standard Mode : min  3.0MHz
;*
;***************************************************************************

;**** Includes ****
;.include "8535def.inc"

;--- compiler directive
.equ LEDs = 1							; LED's aansturen



;**** Global TWI Constants ****
.equ Slave_Address	= 0x30				; Slave device address
.equ devadrm		= 0x7F				; Slave multi address mask
.equ pinmask		= (1<<PD4)+(1<<PD2)	; == 0x14

;**** Global Register Variables ****
.def Reply			= R1				; Dit terugzenden bij een master-read actie (demo)
.def temp			= R16				; Temporary variable
.def temp2			= R17				; Extra temporary variable
.def TWI_Data		= R23				; TWI data register
.def TWI_Address	= R24				; TWI address and direction register




;--- Macros ---------------------------\
.MACRO StartWaitState
	sbi		DDRD,DDD4					; start wait state
.ENDMACRO

.MACRO EndWaitState
	cbi		DDRD,DDD4					; end wait state
.ENDMACRO

.MACRO WaitFor_SCL_Low
_1:	sbic	PIND,PIND4					; wait for SCL low
	rjmp	_1
.ENDMACRO

.MACRO WaitFor_SCL_High
_1:	sbis	PIND,PIND4					; wait for SCL high
	rjmp	_1
.ENDMACRO

.MACRO Release_SDA
	cbi		DDRD,DDD2					; release SDA
.ENDMACRO

.MACRO Force_SDA
	sbi		DDRD,DDD2					; force SDA
.ENDMACRO

.MACRO Acknowledge
	sbi		DDRD,DDD2					; acknowledge on SDA
.ENDMACRO

.MACRO NotAcknowledge
	cbi		DDRD,DDD2					; NOT acknowledge on SDA
.ENDMACRO
;--------------------------------------/




;***************************************************************************
;*
;* INTERRUPT
;*	EXT_INT0 / TWI_wakeup
;*
;* DESCRIPTION
;*	Detects the start condition and handles the data transfer on 
;*	the TWI bus.
;*
;*	Received data is stored in the Reply register and Reply is transmitted 
;*	during a master read transfer.
;*
;* NOTE
;*	This interrupt code, in some cases, jumps to code parts in the 
;*	TIM0_OVF / TWI_skip section to reduce code size.
;*
;***************************************************************************

EXT_INT0:								; INT0 handle
	push	temp
	push	temp2
	in		temp, SREG					; push SREG
	push	temp						;

.if LEDs == 1
	LED_Aan LED_TWI_Activity			; "TWI Activity" LED aan (2 clockcycles)
.endif

;*************************
;* Get TWI Slave Address *
;*************************

TWI_get_adr:
	ldi		TWI_Address,1				; initialize address register
	WaitFor_SCL_Low						; wait for SCL low
	rjmp	first_ga
do_ga:									; do
	WaitFor_SCL_Low						; 	wait for SCL low

	mov		temp,TWI_Address			;	test address
	andi	temp,devadrm				; 	mask "register full" floating bit
	cpi		temp,Slave_Address			; 	if device addressed
	in		temp,SREG					;		set T flag ("T = Z")
	bst		temp,1

first_ga:
	sec									; 	set carry
	WaitFor_SCL_High					; 	wait for SCL high

	sbis	PIND,PIND2					; 	if SDA low
	clc									;		clear carry
	rol		TWI_Address					; 	shift carry into address register

	brcc	do_ga						; while register not full

	WaitFor_SCL_Low						; wait for SCL low

;**** Check Address ****
										; if T flag set (device addressed)
	brts	TWI_adr_ack					;	acknowledge address
										; else
	rjmp	TWI_adr_miss				; 	goto address miss handle

;**** Acknowledge Address ****

TWI_adr_ack:
	Acknowledge							; assert acknowledge on SDA

.if LEDs == 1
	LED_Aan LED_TWI_AddrMatch			; "TWI Address Match" LED aan (2 clockcycles)
.endif

	WaitFor_SCL_High					; wait for SCL high

;**** Check Transfer Direction ****

	lsr		TWI_Address					; if master write
	brcc	TWI_master_write			;	goto master write handle	


;*******************************
;* Transmit Data (master read) *
;*******************************

TWI_master_read:

;**** Load Data (handle outgoing data) ****

;---! INSERT USER CODE HERE !----------\
;!NOTE!	If the user code is more than ONE instruction then wait
;	states MUST be inserted as shown in description.

	; insert wait states here if nessesary
	StartWaitState						; (start wait state)

	mov		TWI_Data,Reply				; insert data in "serial"
										;  register (user code example)

	EndWaitState						; (end wait state)

;---! END USER CODE HERE !-------------/

	sec									; shift MSB out and "floating empty flag" in
	rol		TWI_Data

	WaitFor_SCL_Low						; wait for SCL low


;**** Transmitt data ****

	brcc	fb_low_mr					; if current data bit high
	Release_SDA							;	release SDA
	rjmp	fb_mr						;	goto read loop
fb_low_mr:								; else
	Force_SDA							;	force SDA
fb_mr:
	lsl	TWI_Data						; 	if data register not empty

loop_mr:
	WaitFor_SCL_High					; wait for SCL high
	WaitFor_SCL_Low						; wait for SCL low

	brcc	b_low_mr					; if current data bit high

	Release_SDA							;	release SDA
	lsl		TWI_Data					; 	if data register not empty
	brne	loop_mr						;		loop
	rjmp	done_mr						;	done
b_low_mr:								; else
	Force_SDA							;	force SDA
	lsl		TWI_Data					; 	if data register not empty
	brne	loop_mr						;		loop

done_mr:
	WaitFor_SCL_High					; wait for SCL high
	WaitFor_SCL_Low						; wait for SCL low

	Release_SDA							; release SDA

;**** Read Acknowledge from Master ****

	WaitFor_SCL_High					; wait for SCL high

	sec									; read acknowledge
	sbis	PIND,PIND2
	clc
	brcc	TWI_master_read				; if ack transfer (next) data

	WaitFor_SCL_Low						; wait for SCL low

	rjmp	TWI_wait_cond				; goto wait condition (rep. start or stop)


;*******************************
;* Receive Data (master write) *
;*******************************

TWI_master_write:
	WaitFor_SCL_Low						; wait for SCL low

	NotAcknowledge						; remove acknowledge from SDA

	WaitFor_SCL_High					; wait for SCL high

	in		temp,PIND					; sample SDA (first bit) and SCL
	andi	temp,pinmask				; mask out SDA and SCL
do_mw:									; do
	in		temp2,PIND					;	new sample
	andi	temp2,pinmask				;	mask out SDA and SCL
	cp		temp2,temp
	breq	do_mw						; while no change

	sbrs	temp2,PIND4					; if SCL changed to low
	rjmp	receive_data				;	goto receive data

	sbrs	temp2,PIND2					; if SDA changed to low
	rjmp	TWI_get_adr					;	goto repeated start
										; else
	rjmp	TWI_stop					;	goto transfer stop

receive_data:
	ldi		TWI_Data,2					; set TWI_Data MSB to zero
	sbrc	temp,PIND2					; if SDA sample is one
	ldi		TWI_Data,3					;	set TWI_Data MSB to one

do_rd:									; do
	WaitFor_SCL_Low						; 	wait for SCL low
	sec									; 	set carry
	WaitFor_SCL_High					; wait for SCL high

	sbis	PIND,PIND2					; 	if SDA low
	clc									;		clear carry
	rol		TWI_Data					; 	shift carry into data register

	brcc	do_rd						; while register not full

;**** Acknowledge Data ****

TWI_dat_ack:
	WaitFor_SCL_Low						; wait for SCL low
	Acknowledge							; assert acknowledge on SDA
	WaitFor_SCL_High					; wait for SCL high
										; (acknowledge is removed later)

;**** Store Data (handle incoming data) ****

;---! INSERT USER CODE HERE !----------\
;!NOTE!	If the user code is more than TWO instructions then wait
;	states MUST be inserted as shown in description.

	; insert wait states here if nessesary
	StartWaitState						; (start wait state)

	mov		Reply,TWI_Data				; Store data receved in "serial"
										;  register (user code example)

;	mov		temp, TWI_Data				; De gelezen byte opslaan in de TWI_IN_Buffer
;	rcall	StoreByteSRAMInto_TWI_IN_Buffer

	mov		temp, TWI_Data
	rcall	LCD_LinePrintChar

	EndWaitState						; (end wait state)

;---! END USER CODE HERE !-------------/

	rjmp	TWI_master_write			; Start on next transfer


;***************************************************************************
;*
;* INTERRUPT
;*	TIM0_OVF / TWI_skip
;*
;* DESCRIPTION
;*	This interrupt handles a "address miss". If the slave device is
;*	not addressed by a master, it will not acknowledge the address.
;*
;*	Instead of waiting for a new start condition in a "busy loop"
;*	the slave set up the counter to count 8 falling edges on SCL and 
;*	returns from the current interrupt. This "skipping" of data
;*	do not occupies any processor time. When 8 egdes are counted, a
;*	timer overflow interrupt handling routine (this one) will check
;*	the next condition that accure. If it's a stop condition
;*	the transfer ends, if it's a repeated start condition a jump
;*	to the TWI_wakeup interrupt will read the new address. If a new
;*	transfer is initiated the "skipping" process is repeated.
;*
;***************************************************************************

TIM0_OVF:								; ( Timer 0 overflow handle )
	push	temp
	push	temp2
	in		temp, SREG					; push SREG
	push	temp						;

TWI_adr_miss:
	
;**** Drop Acknowledge ****

	WaitFor_SCL_High					; wait for SCL high
	WaitFor_SCL_Low						; wait for SCL low

	; disable timer 0 overflow interrupt
	ldi		temp,(0<<TOIE0)
	out		TIMSK,temp
	; enable external interrupt request 0
	ldi		temp,(1<<INT0)
	out		GIMSK,temp


;************************
;* Wait for a Condition *
;************************

TWI_wait_cond:
	WaitFor_SCL_High					; wait for SCL high

	in		temp,PIND					; sample SDA (first bit) and SCL
	andi	temp,pinmask				; mask out SDA and SCL
do_wc:									; do
	in		temp2,PIND					;	new sample
	andi	temp2,pinmask				;	mask out SDA and SCL
	cp		temp2,temp
	breq	do_wc						; while no change

	sbrs	temp2,PIND4					; if SCL changed to low
	rjmp	TWI_skip_byte				;	goto skip byte

	sbrs	temp2,PIND2					; if SDA changed to low
	rjmp	TWI_get_adr					;	goto repeated start
										; else
										;	goto transfer stop


;*************************
;* Handle Stop Condition *
;*************************

TWI_stop:
	;! Set INT0 to generate an interrupt on low level,
	;! then set INT0 to generate an interrupt on falling edge.
	;! This will clear the EXT_INT0 request flag.
	ldi		temp,(0<<ISC01)+(0<<ISC00)
	out		MCUCR,temp
	ldi		temp,(1<<ISC01)+(0<<ISC00)
	out		MCUCR,temp

.if LEDs == 1
	LED_Uit LED_TWI_Activity			; "TWI Activity" LED uit
	LED_Uit LED_TWI_AddrMatch			; "TWI Address Match" LED uit
.endif

	pop		temp						; pop SREG
	out		SREG, temp					;
	pop		temp2
	pop		temp
	reti								; return from interrupt


;****************
;* Skip byte(s) *
;****************

TWI_skip_byte:
	; set counter initial value
	ldi		temp,-7
	out		TCNT0,temp
	; enable timer 0 overflow interrupt
	ldi		temp,(1<<TOIE0)
	out		TIMSK,temp
	; disable external interrupt request 0
	ldi		temp,(0<<INT0)
	out		GIMSK,temp

.if LEDs == 1
	LED_Uit LED_TWI_Activity			; "TWI Activity" LED uit
	LED_Uit LED_TWI_AddrMatch			; "TWI Address Match" LED uit
.endif

	pop		temp						; pop SREG
	out		SREG, temp					;
	pop		temp2
	pop		temp
	reti


;***************************************************************************
;*
;* FUNCTION
;*	TWI_init
;*
;* DESCRIPTION
;*	Initialization of interrupts and port used by the TWI interface
;*	and waits for the first start condition.
;*
;* USAGE
;*	Jump to this code directly after a reset.
;*
;* RETURN
;*	none
;*
;* NOTE
;*	Code size can be reduced by 12 instructions (words) if no transfer
;*	is started on the TWI bus (bus free), before the interrupt
;*	initialization is finished. If this can be ensured, remove the
;*	"Wait for TWI Start Condition" part and replace it with a "sei"
;*	instruction.
;*
;***************************************************************************
TWI_init:
;**** PORT Initialization ****

	; Initialize PD2 (INT0) for open colector operation (SDA in/out)
	; Initialize PD4 (T0) for open colector operation (SCL in/out)
	ldi		temp,(0<<DDD4)+(0<<DDD2)
	out		DDRD,temp
	ldi		temp,(0<<PD4)+(0<<PD2)
	out		PORTD,temp

;**** Interrupt Initialization ****

	; Set INT0 to generate an interrupt on falling edge
	ldi		temp,(1<<ISC01)+(0<<ISC00)
	out		MCUCR,temp

	; Enable INT0
	ldi		temp,(1<<INT0)
	out		GIMSK,temp

	; Set clock to count on falling edge of T0
	ldi		temp,(1<<CS02)+(1<<CS01)+(0<<CS00)
	out		TCCR0,temp
	ret



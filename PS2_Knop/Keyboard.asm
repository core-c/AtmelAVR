
;===========================================
;=== constanten
;===========================================

.equ CLOCK_DDR					= DDRD
.equ CLOCK_PORT					= PORTD
.equ CLOCK_Pin					= PD3

.equ DATA_DDR					= DDRD
.equ DATA_PORT					= PORTD
.equ DATA_Pin					= PD4

.equ BUTTON_DDR					= DDRD
.equ BUTTON_PORT				= PORTD
.equ BUTTON_Pin					= PD2		; INT0


.equ ScanCode					= $3B		; F1


.equ ticks_30us					= 0.000030 * CK







;===========================================
;=== macro's
;===========================================

;-------------------------------------------
;--- De clock-lijn laag maken/forceren
;-------------------------------------------
.MACRO Force_CLOCK_Low
	sbi		CLOCK_DDR, CLOCK_Pin
.ENDMACRO

.MACRO CLOCK_Low
	Force_CLOCK_Low
.ENDMACRO

;-------------------------------------------
;--- De clock-lijn hoog maken/vrijgeven
;-------------------------------------------
.MACRO Release_CLOCK
	cbi		CLOCK_DDR, CLOCK_Pin
.ENDMACRO

.MACRO CLOCK_High
	Release_CLOCK
.ENDMACRO

;-------------------------------------------
;--- De data-lijn laag maken/forceren
;-------------------------------------------
.MACRO Force_DATA_Low
	sbi		DATA_DDR, DATA_Pin
.ENDMACRO

.MACRO DATA_Low
	Force_DATA_Low
.ENDMACRO

;-------------------------------------------
;--- De data-lijn hoog maken/vrijgeven
;-------------------------------------------
.MACRO Release_DATA
	cbi		DATA_DDR, DATA_Pin
.ENDMACRO

.MACRO DATA_High
	Release_DATA
.ENDMACRO

;-------------------------------------------
;--- De bus vrijgeven
;-------------------------------------------
.MACRO Free_The_Bus
	Release_DATA
	Release_CLOCK
.ENDMACRO

;-------------------------------------------
;--- Test of de clock-lijn vrij is
;--- resultaat in de zero-flag:
;---	ZF==1	clock-lijn is vrij
;---	ZF==0	clock-lijn is bezet
;-------------------------------------------
.MACRO is_CLOCK_Released
	in		tmp, CLOCK_PORT
	com		tmp
	andi	tmp, (1<<CLOCK_Pin)
.ENDMACRO

;-------------------------------------------
;--- Test of de data-lijn vrij is
;--- resultaat in de zero-flag:
;---	ZF==1	data-lijn is vrij
;---	ZF==0	data-lijn is bezet
;-------------------------------------------
.MACRO is_DATA_Released
	in		tmp, DATA_PORT
	com		tmp
	andi	tmp, (1<<DATA_Pin)
.ENDMACRO

;-------------------------------------------
;--- Test of de bus vrij is
;--- resultaat in de zero-flag:
;---	ZF==1	bus is vrij
;---	ZF==0	bus is bezet
;-------------------------------------------
.MACRO is_Bus_Free
	is_CLOCK_Released
	brne	_0
	is_DATA_Released
_0:
.ENDMACRO

;-------------------------------------------
;--- De bit-waarde van de data-lijn 
;--- naar de carry overnemen.
;--- Data laag: Carry-flag == 1
;--- Data hoog: Carry-flag == 0
;-------------------------------------------
.MACRO DATA_To_Carry
	in		tmp, DATA_PORT
	com		tmp
	andi	tmp, (1<<DATA_Pin)
	clc
	breq	_0
	sec
_0:
.ENDMACRO

;------------------------------------------
;--- controleer de bus-bezetting door de host
;------------------------------------------
.MACRO Check_The_Bus;(onContinue:label)
	; Het keyboard is niet zelf aan het zenden.
	; De bus is dus vrij.
	; Blijf controleren of de host de bus bezet..
	is_CLOCK_Released
	breq	@0

	; start een counter..					; !

_0:	;WaitForHostDATA:
	; wacht op DATA-lijn laag,
	; of op een vrije bus..
	is_Bus_Free
	breq	@0								; bus vrij?? clock is weer hoog => opnieuw wachten..
	is_DATA_Released
	breq	_0								; data nog hoog?? => wacht langer op data laag..

_1:	;WaitForHostCLOCK:
	;wacht op clock-hoog
	; of op een vrije bus..
	is_Bus_Free
	breq	@0								; bus vrij?? clock is weer hoog => opnieuw wachten..
	is_CLOCK_Released
	brne	_1

	; de host bezet de bus om een commando te zenden..

	; stop de counter,
	; en test of het gemeten interval >1bit duurde..
.ENDMACRO


;------------------------------------------
;--- Jumpen als het keyboard zelf aan het verzenden is
;------------------------------------------
;.MACRO ifTransmitting_JumpTo;(Adddress:label)
;	clr		tmp
;	cpse	Transmitting, tmp
;	rjmp	@0
;.ENDMACRO



;------------------------------------------
;--- Pariteit-berekening starten
;------------------------------------------
.MACRO Reset_Parity
	clr		Parity
.ENDMACRO

;------------------------------------------
;--- Pariteit-berekening
;--- input: Carry-flag
;------------------------------------------
.MACRO Calc_Parity
	brcc	_0
	inc		Parity
_0:
.ENDMACRO

;------------------------------------------
;--- Pariteit testen
;--- input: register 'Parity'
;---        carry-flag
;--- output: register 'Parity' == $00 | $FF
;---         $00 = goede pariteit
;---         $FF = pariteit fout
;------------------------------------------
.MACRO Check_Parity
	; test de pariteit..					; !		!!!!!test de uitkomst 1 of 0 van de parity
	; pariteit fout?? dan geen ack geven..			!!!!!misschien nog omdraaien die bit.. xor ff
	mov		tmp, Parity
	clr		Parity							; markering: pariteit GOED!
	andi	tmp, 1							; laagste bit == pariteit bit
	breq	_2
	; pariteit moet 1 zijn..
	brcs	_0								; parity is goed
	rjmp	_1								; parity is fout
	; pariteit moet 0 zijn..
_2:	brcc	_0								; parity is goed
_1:	ser		Parity							; markering: pariteit FOUT!
_0:
.ENDMACRO





;------------------------------------------
;--- Lees/ontvang een byte van de host/PC
;--- lezen inclusief:
;---   startbit, data-byte, pariteit-bit &
;---   stop-bit.
;---   + zenden van de juiste ACK-bit.
;------------------------------------------
.MACRO GetByte;(data:register; onError:label)
;ReceiveStartBit:
	; begin met het genereren van een clock-puls
	; ..en ontvang een startbit:

	clr		@0

	; wacht 30us							; !
	rcall	Delay30us

	; clock signaal laag maken
	Clock_Low

	; de start-bit lezen..
	DATA_To_Carry
	brcc	_0								; error??..start-bit moet altijd 0 zijn
	rjmp	@1								; error!  :-(
_0:
	; wacht 30us							; !
	rcall	Delay30us

	; clock-signaal hoog maken
	Clock_High


	;---------------------------------------
	; pariteit controle resetten..
	Reset_Parity
	; 8 bits ontvangen
	ldi		tmp, 8
	mov		BitCount, tmp
ReceiveByte:
	; ontvang een byte:

	; wacht 30us							; !
	rcall	Delay30us

	; clock signaal laag maken
	Clock_Low

	; de data-bit lezen..
	DATA_To_Carry
	; en inschuiven in de doel-byte
	ror		@0

	; de pariteit berekenen
	Calc_Parity

	; wacht 30us							; !
	rcall	Delay30us

	; clock-signaal hoog maken
	Clock_High

	; volgende bit..
	dec		BitCount
	brne	ReceiveByte

	;---------------------------------------
;ReceiveParityBit:
	; ontvang de pariteits-bit:

	; wacht 30us							; !
	rcall	Delay30us

	; clock signaal laag maken
	Clock_Low

	; de parity-bit lezen..
	DATA_To_Carry

	; controleer de pariteit..				; !		!!!!!test de uitkomst 1 of 0 van de parity
	; pariteit fout?? dan geen ack geven..			!!!!!misschien nog omdraaien die bit.. xor ff
	Check_Parity

	; wacht 30us							; !
	rcall	Delay30us

	; clock-signaal hoog maken
	Clock_High

	;---------------------------------------
ReceiveStopBit:
	; ontvang de stop-bit:

	; wacht 30us							; !
	rcall	Delay30us

	; clock signaal laag maken
	Clock_Low

	; de stop-bit lezen..
	DATA_To_Carry
	brcc	StopBitReceived					; indien stop-bit niet correct,
											; blijf clock-pulsen maken totdat DATA laag is..

	; wacht 30us							; !
	rcall	Delay30us

	; clock-signaal hoog maken
	Clock_High

	rjmp	ReceiveStopBit

StopBitReceived:
	; wacht 30us							; !
	rcall	Delay30us

	
	; alvast een NOT-ACK op de data-lijn "zetten"
	DATA_High
	sbrc	Parity, 0
	rjmp	_1
	; een ACK op de data-lijn zetten
	DATA_Low
_1:

	; clock-signaal hoog maken
	Clock_High

	;---------------------------------------
;SendAcknowledge:
	; zend een ack naar de host:

	; wacht 30us							; !
	rcall	Delay30us

	; clock signaal laag maken
	Clock_Low

	; wacht 30us							; !
	rcall	Delay30us

	; clock-signaal hoog maken
	Clock_High
.ENDMACRO





;------------------------------------------
.MACRO PutByte;(data:register; onError:label)

	; begin met de verzending van de start-bit
	DATA_Low

	;---------------------------------------
;SendStartBit:
	; begin met het genereren van een clock-puls
	; ..en verzend een startbit:

	; wacht 30us							; !
	rcall	Delay30us

	; clock signaal laag maken
	Clock_Low

	; wacht 30us							; !
	rcall	Delay30us


	;---------------------------------------
	; pariteit controle resetten..
	Reset_Parity
	; 8 bits zenden
	ldi		tmp, 8
	mov		BitCount, tmp

SendByte:
	; laagste bit via carry-flag naar data-lijn
	DATA_High
	ror		@0
	brcs	_01
	DATA_Low
_01:

	; de pariteit berekenen
	Calc_Parity

	; clock-signaal hoog maken
	Clock_High

	; wacht 30us							; !
	rcall	Delay30us

	; clock signaal laag maken
	Clock_Low

	; wacht 30us							; !
	rcall	Delay30us

	; volgende bit..
	dec		BitCount
	brne	SendByte

	;---------------------------------------
;SendParityBit:

	DATA_High
	ldi		tmp, $FF
	eor		Parity, tmp
	andi	Parity, 1
	brcs	_02
	DATA_Low
_02:


	; clock-signaal hoog maken
	Clock_High


	; wacht 30us							; !
	rcall	Delay30us

	; clock signaal laag maken
	Clock_Low

	; wacht 30us							; !
	rcall	Delay30us


	;---------------------------------------
;SendStopBit:
	; zend de stop-bit:

	DATA_High

	; clock-signaal hoog maken
	Clock_High


	; wacht 30us							; !
	rcall	Delay30us

	; clock signaal laag maken
	Clock_Low

	; wacht 30us							; !
	rcall	Delay30us


	DATA_High

	; clock-signaal hoog maken
	Clock_High

.ENDMACRO


;------------------------------------------
;--- Verwerk een commando van de host
;------------------------------------------
.MACRO Process_Command;(HostCommand:register)
;		case 0xFF: //reset  0xAA, 0x00
;		case 0xF4: //enable transmit  
//		case 0xE6: //set scaling 1:1
//		case 0xE7: //set scaling 2:
;		case 0xF2: //get device ID      
//		case 0xEB: //read data, for remote mode   
;		case 0xE8: //set resolution
;		case 0xE9: //status request respond 0xFA, 0x00, 0x02, 0x64
//		case 0xEA: //set stream mode	
//   	case 0xEB: //read data (for Remote Mode)
//		case 0xEC: //reset wrap mode	           
//		case 0xEE: //set wrap mode
//		case 0xF0: //set remote mode
;		case 0xF3: //set sample rate
;		case 0xF5: //disable data reporting
;		case 0xF6: //set defaults       
;		default: //all other commands
.ENDMACRO




;------------------------------------------
;--- INT0 reageren bij opgaande flank
;------------------------------------------
.MACRO Next_INT0_On_RisingEdge
	in		tmp, MCUCR
;	andi	temp, ~(1<<ISC01 | 1<<ISC00)
	ori		tmp, (1<<ISC01 | 1<<ISC00)		;ISC01 & ISC00 bits op 1
	out		MCUCR, tmp
.ENDMACRO

;------------------------------------------
;--- INT0 reageren bij neergaande flank
;------------------------------------------
.MACRO Next_INT0_On_FallingEdge
	in		tmp, MCUCR
	andi	tmp, ~(1<<ISC01 | 1<<ISC00)		;ISC01 & ISC00 bits op 0
	ori		tmp, (1<<ISC01 | 0<<ISC00)		;ISC01 op 1
	out		MCUCR, tmp
.ENDMACRO

;------------------------------------------
;--- INT0 reageren bij omgekeerde flank
;------------------------------------------
.MACRO Next_INT0_On_ToggleEdge
	ldi		tmp2, (1<<ISC00)
	in		tmp, MCUCR
	eor		tmp, tmp2						;ISC00 bit omdraaien
	out		MCUCR, tmp
.ENDMACRO






;===========================================
;=== subroutine's
;===========================================

;------------------------------------------
;--- Keyboard initialiseren
;------------------------------------------
KBD_Initialize:
	; AVR-pinnen
	PIN_Set_INPUT_TRISTATE CLOCK_DDR, CLOCK_Pin
	PIN_Set_INPUT_TRISTATE DATA_DDR, DATA_Pin
	Free_The_Bus

	PIN_Set_INPUT_PULLUP BUTTON_DDR, BUTTON_Pin

	; toetsenbord uitschakelen
	rcall	Button_Off

;	; de timer instellen
;	Timer1Clock_Off
;	Disable_Interrupt_CompareMatch1A
;	SetI_Compare1A ticks_30us				; 30us == 221 ticks
;	Clear_TimerCounter1
;	Enable_Interrupt_CompareMatch1A
;;	Timer1Clock_PrescaleCK


	; er is nog geen byte ontvangen van de host
	clr		DataByte

	; er is nog geen toets ingedrukt
	clr		DownUp

	; toetsenbord aanschakelen
	rcall	Button_On

	ret


;------------------------------------------
;--- Knop externe interrupt inschakelen
;------------------------------------------
Button_On:
;	cli

	; externe interrupt INT0 activeren op vallende flank 
	Next_INT0_On_FallingEdge				; trigger als de knop wordt INgedrukt

	; externe interrupt INT0 inschakelen in Global Interrupt Mask Register
	in		tmp, GIMSK
	ori		tmp, (1<<INT0)
	out		GIMSK, tmp

;	sei
	ret

;-------------------------------------------
;--- Knop externe interrupt uitschakelen
;-------------------------------------------
Button_Off:
;	cli
	; externe interrupt INT0 uitschakelen
	in		tmp, GIMSK
	andi	tmp, ~(1<<INT0)
;	ori		tmp, (0<<INT1)
	out		GIMSK, tmp

;	sei
	ret

;-------------------------------------------
;--- een 30 us vertraging
;-------------------------------------------
Delay30us:
	Delay_US 30
	ret




;===========================================
;=== interrupt handler
;===========================================

; de knop/schakelaar ligt aan INT0
Button_Interrupt:
	push	tmp
	;push	DownUp
	;push	DataByte

	; wordt de knop INgedrukt??
	cpi		DownUp, 0
	brne	KeyUp

	;---------------------------------------
KeyDown:
	Next_INT0_On_RisingEdge
	ser		DownUp

	; zend: scancode
	ldi		DataByte, ScanCode
	PutByte DataByte

	rjmp	Done_Button_Interrupt

	;---------------------------------------
KeyUp:
	Next_INT0_On_FallingEdge
	clr		DownUp

	; zend: $F0 + scancode
	ldi		DataByte, $F0
	PutByte DataByte
	ldi		DataByte, ScanCode
	PutByte DataByte

Done_Button_Interrupt:
	;pop	DataByte
	;pop	DownUp
	pop		tmp
	reti

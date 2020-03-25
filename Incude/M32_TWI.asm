;---------------------------------------------------------------------------------
;---
;---  TWI constanten en macro's							Ron Driessen
;---  AVR ATMega32										2005
;---
;---------------------------------------------------------------------------------
;.include "m32def.inc"





;---------------------------------------------------------------------------------
;---	Pin 23		PC1		SDA
;---	Pin 22		PC0		SCL
;---------------------------------------------------------------------------------
.equ TWI_SDA	= PC1
.equ TWI_SCL	= PC0
.equ TWI_READ	= 1				; waarden bij SLA/W & SLA/R
.equ TWI_WRITE	= 0				;


;---------------------------------------------------------------------------------
;---	I/O-Buffers in SRAM
;---------------------------------------------------------------------------------
.DSEG
.equ TWI_BufferSize	= 32						; de grootte van elke buffer (in bytes)
; De TWI invoer buffer
TWI_BufferIN:			.BYTE TWI_BufferSize
TWI_BufferIN_Count:		.BYTE 1					; aantal bytes in deze buffer
TWI_BufferIN_PtrR:		.BYTE 2					; pointer naar adres in SRAM; (Bij byte lezen uit BufferIN)
TWI_BufferIN_PtrW:		.BYTE 2					; pointer naar adres in SRAM; (Bij byte schrijven in BufferIN)
; De TWI uitvoer buffer
TWI_BufferOUT:			.BYTE TWI_BufferSize
TWI_BufferOUT_Count:	.BYTE 1					; aantal bytes in deze buffer
TWI_BufferOUT_PtrR:		.BYTE 2					; pointer naar adres in SRAM; (Bij byte lezen uit BufferOUT)
TWI_BufferOUT_PtrW:		.BYTE 2					; pointer naar adres in SRAM; (Bij byte schrijven in BufferOUT)
.CSEG
;---------------------------------------------------------------------------------



;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			GetPointer
;--- Beschrijving:	een (16bit) pointer waarde opvragen in Z
;--- uitvoer: 		Z = gelezen pointer adres-waarde
;--------------------------------------------
.MACRO GetPointer;(Pointer: Address)
	lds		ZH, @0							; high
	lds		ZL, @0+1						; low
.ENDMACRO

;--------------------------------------------
;--- Naam:			SetPointer
;--- Beschrijving:	een (16bit) pointer waarde instellen
;--- invoer: 		Z = in te stellen pointer adres-waarde
;--------------------------------------------
.MACRO SetPointer;(Pointer: Address)
	sts		@0, ZH							; high
	sts		@0+1, ZL						; low
.ENDMACRO

;--------------------------------------------
;--- Naam:			SetPointerTo
;--- Beschrijving:	een (16bit) pointer een constante waarde toekennen
;--------------------------------------------
.MACRO SetPointerTo;(Pointer: Address; Value: Label)
	ldi		R16, high(@1)
	sts		@0, R16
	ldi		R16, low(@1)
	sts		@0+1, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			ValidatePointer
;--- Beschrijving:	een (16bit) pointer controleren en evt. corrigeren
;--- invoer:		Z = pointer-waarde in de opgegeven buffer @0
;--- aangetast:		R16
;--------------------------------------------
.MACRO ValidatePointer;(Buffer: [TWI_BufferIN | TWI_BufferOUT])
	; Z-waarde is al goed als geldt: Z < @0+TWI_BufferSize (anders Z := @0 maken)
	; Z<@0+TWI_BufferSize ?
	cpi		ZL, low(@0 + TWI_BufferSize)
	ldi		R16, high(@0 + TWI_BufferSize)
	cpc		ZH, R16
	brlo	_0
	; Z is kleiner..herstellen naar @0
	ldi		ZH, high(@0)					; [Z] = @0
	ldi		ZL, low(@0)
_0:
.ENDMACRO

;--------------------------------------------
;--- Naam:			Initialize_TWI_Buffers
;--- Beschrijving:	De TWI I/O-buffers initialiseren voor gebruik
;--------------------------------------------
.MACRO Initialize_TWI_Buffers
	; aantal bytes in de buffer op 0
	clr		R16
	sts		TWI_BufferIN_Count, R16			; invoer buffer
	sts		TWI_BufferOUT_Count, R16		; uitvoer buffer
	; de pointer bij lezen uit de buffer	; HIGH_LOW
	SetPointerTo TWI_BufferIN_PtrR, TWI_BufferIN
	SetPointerTo TWI_BufferOUT_PtrR, TWI_BufferOUT
	; de pointer bij schrijven in de buffer	; HIGH_LOW
	SetPointerTo TWI_BufferIN_PtrW, TWI_BufferIN
	SetPointerTo TWI_BufferOUT_PtrW, TWI_BufferOUT
.ENDMACRO

;--------------------------------------------
;--- Naam:			TWI_Buffer_Write
;--- Beschrijving:	Een byte in de TWI OUT-buffer plaatsen (voor verzending)
;---				!Deze macro dient te worden gebruikt door de user om bytes
;---				in de buffer te plaatsen alvorens een transactie te starten.
;--- invoer:		register "Value" = de te schrijven byte
;--- uitvoer:		carry-flag = gezet bij een fout (buffer al vol), anders gewist
;---				XL = nieuwe aantal bytes in de buffer (na toevoeging)
;---				Z = nieuwe waarde van TWI_BufferOUT_PtrW
;--- aangetast:		R16
;--------------------------------------------
.MACRO TWI_BufferOUT_push
	TWI_Buffer_Write @0
.ENDMACRO
.MACRO TWI_Buffer_Write;(Value: register)	; TWI_BufferOUT_push
	; past de byte nog in de buffer?
	lds		XL, TWI_BufferOUT_Count
	cpi		XL, TWI_BufferSize
	brlo	_0
	sec										; fout: buffer al vol.
	rjmp	_1
_0:	; "bytes in buffer" teller ophogen
	inc		XL
	sts		TWI_BufferOUT_Count, XL

	; Z := waarde van pointer "TWI_BufferOUT_PtrW"
	GetPointer TWI_BufferOUT_PtrW
	; de byte in register R16 bewaren op adres [Z]  (in bufferOUT)
	st		Z+, @0							; na afloop het Z-register verhogen met 1
	; De TWI_BufferOUT_PtrW evt. corrigeren, en daarna bijwerken in SRAM:
	ValidatePointer TWI_BufferOUT
	; de pointer-waarde in Z opslaan in SRAM (TWI_BufferOUT_PtrW)
	SetPointer TWI_BufferOUT_PtrW

	clc										; succes
_1:
.ENDMACRO

;--------------------------------------------
;--- Naam:			TWI_BufferOUT_pop
;--- Beschrijving:	Een byte lezen uit de TWI OUT-buffer
;---				!Deze macro dient NIET te worden gebruikt door de user.
;--- uitvoer:		carry-flag = gezet bij een fout (buffer al leeg), anders gewist
;---				Register "Value" = de gelezen byte (<>XL, <>XH, <>ZL, <>ZH)
;---				XL = nieuwe aantal bytes in de buffer (na "pop" uit buffer)
;---				Z = nieuwe waarde van TWI_BufferOUT_PtrR
;--- aangetast:		XH
;--------------------------------------------
.MACRO TWI_BufferOUT_pop;(Value: register)
	; is de buffer gevuld met tenminste een byte?
	lds		XL, TWI_BufferOUT_Count
	cpi		XL, 0
	brne	_0
	sec										; fout: buffer is al leeg.
	rjmp	_1
_0:	; "bytes in buffer" teller verlagen
	dec		XL
	sts		TWI_BufferOUT_Count, XL

	; Z := waarde van pointer "TWI_BufferOUT_PtrR"
	GetPointer TWI_BufferOUT_PtrR
	; de byte in register XH lezen vanaf adres [Z]  (in bufferOUT)
	ld		@0, Z+							; na afloop het Z-register verhogen met 1
	; De TWI_BufferOUT_PtrR evt. corrigeren, en daarna bijwerken in SRAM:
	ValidatePointer TWI_BufferOUT
	; de pointer-waarde in Z opslaan in SRAM (TWI_BufferOUT_PtrR)
	SetPointer TWI_BufferOUT_PtrR

	clc										; succes
_1:
.ENDMACRO

;--------------------------------------------
;--- Naam:			TWI_BufferIN_push
;--- Beschrijving:	Een byte schrijven naar de TWI IN-buffer
;---				!Deze macro dient NIET te worden gebruikt door de user.
;--- invoer:		Register "Value" = de te schrijven byte  (<>XL, <>ZL, <>ZH)
;--- uitvoer:		carry-flag = gezet bij een fout (buffer al vol), anders gewist
;---				XL = nieuwe aantal bytes in de buffer (na "push" in buffer)
;---				Z = nieuwe waarde van TWI_BufferIN_PtrW
;--------------------------------------------
.MACRO TWI_BufferIN_push;(Value: register)
	; past de byte nog in de buffer?
	lds		XL, TWI_BufferIN_Count
	cpi		XL, TWI_BufferSize
	brlo	_0
	sec										; fout: buffer al vol.
	rjmp	_1
_0:	; "bytes in buffer" teller ophogen
	inc		XL
	sts		TWI_BufferIN_Count, XL

	; Z := waarde van pointer "TWI_BufferIN_PtrW"
	GetPointer TWI_BufferIN_PtrW
	; de byte in register "Value" bewaren op adres [Z]  (in bufferIN)
	st		Z+, @0							; na afloop het Z-register verhogen met 1
	; De TWI_BufferOUT_PtrW evt. corrigeren, en daarna bijwerken in SRAM:
	ValidatePointer TWI_BufferIN
	; de pointer-waarde in Z opslaan in SRAM (TWI_BufferIN_PtrW)
	SetPointer TWI_BufferIN_PtrW

	clc										; succes
_1:
.ENDMACRO

;--------------------------------------------
;--- Naam:			TWI_Buffer_Read
;--- Beschrijving:	Een byte uit de TWI IN-buffer lezen (na ontvangst)
;---				!Deze macro dient te worden gebruikt door de user om bytes
;---				uit de buffer te lezen na een (lees)transactie.
;--- uitvoer:		carry-flag = gezet bij een fout (buffer al leeg), anders gewist
;--- 				Register "Value" = de gelezen byte
;---				XL = nieuwe aantal bytes in de buffer (na eruit lezen)
;---				Z = nieuwe waarde van TWI_BufferIN_PtrR
;--- aangetast:		XH
;--------------------------------------------
.MACRO TWI_BufferIN_pop
	TWI_Buffer_Read @0
.ENDMACRO
.MACRO TWI_Buffer_Read;(Value: register)	; TWI_BufferIN_pop
	; is de buffer gevuld met tenminste een byte?
	lds		XL, TWI_BufferIN_Count
	cpi		XL, 0
	brne	_0
	sec										; fout: buffer is al leeg
	rjmp	_1
_0:	; "bytes in buffer" teller verlagen
	dec		XL
	sts		TWI_BufferIN_Count, XL

	; Z := waarde van pointer "TWI_BufferIN_PtrR"
	GetPointer TWI_BufferIN_PtrR
	; de byte lezen uit de buffer
	ld		@0, Z+							; na afloop het Z-register verhogen met 1
	; De TWI_BufferIN_PtrR evt. corrigeren, en daarna bijwerken in SRAM:
	ValidatePointer TWI_BufferIN
	; waarde in Z opslaan in SRAM TWI_BufferOUT_PtrW
	SetPointer TWI_BufferIN_PtrR

	clc										; succes
_1:
.ENDMACRO



;--------------------------------------------
;--- Naam:			Initialize_TWI
;--- Beschrijving:	De TWI poort/pinnen initialiseren voor gebruik
;--------------------------------------------
.MACRO Initialize_TWI
	; Poort C pinnen als input instellen
	cbi		DDRC, TWI_SCL
	cbi		DDRC, TWI_SDA
	; tri-state instellen indien externe pull-ups gebruikt..
	cbi		PORTC, TWI_SCL
	cbi		PORTC, TWI_SDA
	; ..of..  interne pull-ups inschakelen
	;sbi	PORTC, TWI_SCL
	;sbi	PORTC, TWI_SDA
	; De buffers in SRAM initialiseren
	Initialize_TWI_Buffers
.ENDMACRO





;---------------------------------------------------------------------------------
;--- TWAR - TWI (slave) Address Register
;---
;---	bit  7        6        5        4        3        2        1        0
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	|  TWA6  |  TWA5  |  TWA4  |  TWA3  |  TWA2  |  TWA1  |  TWA0  |  TWGCE |
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	Bit 7..1	TWA6..TWA0		TWI (Slave) Address
;---	Bit 0		TWGCE			TWI General Call Recognition Enable Bit
;---
;---------------------------------------------------------------------------------
; Dit register TWAR wordt gebruikt als de AVR als een Slave-Receiver/Transmitter werkt.



;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			Set_TWI_SlaveAddress
;--- Beschrijving:	Het TWI slave-adres instellen
;---				!! niet reageren op een "General Call" (naar adres 0)
;---				invoer: register "Address" bevat het slave-adres
;--------------------------------------------
.MACRO Set_TWI_SlaveAddress;(Address: register)
	lsl		@0
	out		TWAR, @0
.ENDMACRO

;--------------------------------------------
;--- Naam:			Set_TWI_SlaveAddress_And_GeneralCall
;--- Beschrijving:	Het TWI slave-adres instellen
;---				!! ook reageren op een "General Call" (naar adres 0)
;---				invoer: register "Address" bevat het slave-adres
;--------------------------------------------
.MACRO Set_TWI_SlaveAddress_And_GeneralCall;(Address: register)
	lsl		@0
	ori		@0, (1<<TWGCE)
	out		TWAR, @0
.ENDMACRO






;---------------------------------------------------------------------------------
;--- TWBR - TWI Bitrate Register
;---
;---	bit  7        6        5        4        3        2        1        0
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	| TWBR7  | TWBR6  | TWBR5  | TWBR4  | TWBR3  | TWBR2  | TWBR1  | TWBR0  |
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	Bit 7..0	TWBR7..TWBR0		TWI Bit Rate Register
;---
;---------------------------------------------------------------------------------
;
; BaudRate- & Prescale-waarde berekenen voor een gewenste TWI-frequentie:
; (De TWBR-waarde moet zijn: >=10, anders komen er verkeerde bijeffecten)
; (De CK van elke slave moet tenminste 10x hoger zijn dan de TWI-Frequentie)
;	prescale-waarden:	1,4,16 of 64
;	formule:			TWIfrequentie = CK/(16+2TWBR*Prescale)
;					<=>	16+2TWBR*Prescale = CK/TWIfrequentie
;					<=> TWBR*Prescale = (CK/TWIfrequentie-16)/2






;---------------------------------------------------------------------------------
;--- TWSR - TWI Status Register
;---
;---	bit  7        6        5        4        3        2        1        0
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	|  TWS7  |  TWS6  |  TWS5  |  TWS4  |  TWS3  |        |  TWPS1 |  TWPS0 |
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	Bit 7..3	TWS7..TWS3			TWI Status
;---	Bit 2							Reserved Bit
;---	Bit 1..0	TWPS1,TWPS0			TWI Prescaler Bits
;---
;---------------------------------------------------------------------------------

; maskers
.equ TWS7	= 7
.equ TWS6	= 6
.equ TWS5	= 5
.equ TWS4	= 4
.equ TWS3	= 3
.equ TWPS1	= 1
.equ TWPS0	= 0

.equ TWI_STATUS_MASK	= (1<<TWS7 | 1<<TWS6 | 1<<TWS5 | 1<<TWS4 | 1<<TWS3)
.equ TWI_PRESCALE_MASK	= (1<<TWPS1 | 1<<TWPS0)
;- - - - - - - - - - - - - - - - - - - - - - - - -
; TWI Prescale waarden (TWSR waarden voor bits in TWI_PRESCALE_MASK)
.equ TWI_PRESCALE_1		= (0<<TWPS1 | 0<<TWPS0)
.equ TWI_PRESCALE_4		= (0<<TWPS1 | 1<<TWPS0)
.equ TWI_PRESCALE_16	= (1<<TWPS1 | 0<<TWPS0)
.equ TWI_PRESCALE_64	= (1<<TWPS1 | 1<<TWPS0)
;- - - - - - - - - - - - - - - - - - - - - - - - -
; TWI-status codes !! (TWSR waarden voor bits in TWI_STATUS_MASK)
; algemeen
.equ TWI_STATUS_Bus_Error							= $00
.equ TWI_STATUS_No_Status_Available					= $F8
.equ TWI_STATUS_Start_Transmitted					= $08	; geldig bij MT & MR
.equ TWI_STATUS_RepeatedStart_Transmitted			= $10	; geldig bij MT & MR
.equ TWI_STATUS_Arbitration_Lost					= $38	; geldig bij MT & MR
; Bij Master Transmitter mode (afgekort tot: MT)
.equ TWI_STATUS_SLAW_Transmitted_ACK_Received		= $18
.equ TWI_STATUS_SLAW_Transmitted_NACK_Received		= $20
.equ TWI_STATUS_Data_Transmitted_ACK_Received		= $28
.equ TWI_STATUS_Data_Transmitted_NACK_Received		= $30
; Bij Master Receiver mode (afgekort tot: MR)
.equ TWI_STATUS_SLAR_Transmitted_ACK_Received		= $40
.equ TWI_STATUS_SLAR_Transmitted_NACK_Received		= $48
.equ TWI_STATUS_Data_Received_ACK_Transmitted		= $50
.equ TWI_STATUS_Data_Received_NACK_Transmitted		= $58



;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			
;--- Beschrijving:	
;--------------------------------------------
.MACRO Set_TWI_Clock;(CK,TWI-Frequentie)
	;.SET BRPS64	= ((@0/@1-16)/2)/64
	;.SET BRPS16	= ((@0/@1-16)/2)/16
	;.SET BRPS4		= ((@0/@1-16)/2)/4
	;.SET BRPS1		= ((@0/@1-16)/2)
	;
	; voldoet prescale 64?
	.if ((@0/@1-16)/2)/64 >= 10
		.message "TWI-Prescale used: 64"
		; het TWI-Bitrate register instellen
		ldi		R16, ((@0/@1-16)/2)/64
		out		TWBR, R16
		; en de prescale instellen in het Status Register
		in		R16, TWSR				;
		andi	R16, TWI_STATUS_MASK	;
		ori		R16, TWI_PRESCALE_64	;
		out		TWSR, R16
		;clc
	.else
		; voldoet prescale 16?
		.if ((@0/@1-16)/2)/16 >= 10
			.message "TWI-Prescale used: 16"
			ldi		R16, ((@0/@1-16)/2)/16
			out		TWBR, R16
			in		R16, TWSR				;
			andi	R16, TWI_STATUS_MASK	;
			ori		R16, TWI_PRESCALE_16	;
			out		TWSR, R16
			;clc
		.else
			; voldoet prescale 4?
			.if ((@0/@1-16)/2)/4 >= 10
				.message "TWI-Prescale used: 4"
				ldi		R16, ((@0/@1-16)/2)/4
				out		TWBR, R16
				in		R16, TWSR				;
				andi	R16, TWI_STATUS_MASK	;
				ori		R16, TWI_PRESCALE_4		;
				out		TWSR, R16
				;clc
			.else
				; voldoet prescale 1?
				.if ((@0/@1-16)/2) >= 10
					.message "TWI-Prescale used: 1"
					ldi		R16, ((@0/@1-16)/2)
					out		TWBR, R16
					in		R16, TWSR				;
					andi	R16, TWI_STATUS_MASK	;
					ori		R16, TWI_PRESCALE_1		;
					out		TWSR, R16
					;clc
				.else
					.error "ERROR: TWI-Frequency too high (TWBR<10)"
					;sec
				.endif
			.endif
		.endif
	.endif
.ENDMACRO





;---------------------------------------------------------------------------------
;--- TWCR - TWI Control Register
;---
;---	bit  7        6        5        4        3        2        1        0
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	|  TWINT |  TWEA  |  TWSTA |  TWSTO |  TWWC  |  TWEN  |        |  TWIE  |
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	Bit 7		TWINT				TWI Interrupt Flag
;---	Bit 6		TWEA				TWI Enable Acknowledge Bit
;---	Bit 5		TWSTA				TWI START Condition Bit
;---	Bit 4		TWSTO				TWI STOP Condition Bit
;---	Bit 3		TWWC				TWI Write Collision Flag
;---	Bit 2		TWEN				TWI Enable Bit
;---	Bit 1							Reserved Bit
;---	Bit 0		TWIE				TWI Interrupt Enable
;---
;---------------------------------------------------------------------------------


;--------------------------------------------
;--- TWI Interrupt Enable
;--------------------------------------------
.equ TWI_INTERRUPTENABLE	=	(1<<TWIE)





;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			Disable_TWI
;--- Beschrijving:	De TWI uitschakelen
;--------------------------------------------
.MACRO Disable_TWI
	cbi		TWCR, TWEN
.ENDMACRO

;--------------------------------------------
;--- Naam:			Enable_ADC
;--- Beschrijving:	De TWI inschakelen
;--------------------------------------------
.MACRO Enable_TWI
	sbi		TWCR, TWEN
.ENDMACRO


;--------------------------------------------
;--- Naam:			Disable_Interrupt_TWI
;--- Beschrijving:	Interrupt uitschakelen voor TWI
;--------------------------------------------
.MACRO Disable_Interrupt_TWI
	cbi		TWCR, TWIE
.ENDMACRO

;--------------------------------------------
;--- Naam:			Enable_Interrupt_TWI
;--- Beschrijving:	Interrupt inschakelen voor TWI
;--------------------------------------------
.MACRO Enable_Interrupt_TWI
	sbi		TWCR, TWIE
.ENDMACRO


;--------------------------------------------
;--- Naam:			Enable_TWI_ACK
;--- Beschrijving:	"automatisch" TWI ACKnowledge geven
;--------------------------------------------
.MACRO Enable_TWI_ACK
	in		R16, TWCR
	ori		R16, (1<<TWEA)
	out		TWCR, R16
	;sbi	TWCR, TWEA
.ENDMACRO

;--------------------------------------------
;--- Naam:			Enable_TWI_NACK
;--- Beschrijving:	"automatisch" TWI Not-ACKnowledge geven
;--------------------------------------------
.MACRO Enable_TWI_NACK
	in		R16, TWCR
	andi	R16, ~(1<<TWEA)
	out		TWCR, R16
	;cbi	TWCR, TWEA
.ENDMACRO




;--------------------------------------------
;--- Naam:			TWI_START
;--- Beschrijving:	Een TWI START zenden (Als MT)
;--------------------------------------------
.MACRO TWI_START
	ldi		R16, (1<<TWINT | 1<<TWEN | 1<<TWEA | 1<<TWSTA)
	out		TWCR, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			TWI_REPEATEDSTART
;--- Beschrijving:	Een TWI REPEATED-START zenden (Als MT)
;--------------------------------------------
.MACRO TWI_REPEATEDSTART
	TWI_START
.ENDMACRO

;--------------------------------------------
;--- Naam:			TWI_STOP
;--- Beschrijving:	Een TWI STOP zenden (Als MT)
;--------------------------------------------
.MACRO TWI_STOP
	ldi		R16, (1<<TWINT | 1<<TWEN | 1<<TWEA | 1<<TWSTO)
	out		TWCR, R16
.ENDMACRO

;--------------------------------------------
;--- Naam:			TWI_WAIT_READY
;--- Beschrijving:	Wachten zolang de TWINT vlag "0" is,
;---				..ga verder als de TWINT vlag "1" is.
;--------------------------------------------
.MACRO TWI_WAIT_READY
_0:	in		R16, TWCR
	sbrs	R16, TWINT
	rjmp	_0
.ENDMACRO

;--------------------------------------------
;--- Naam:			TWI_CHECK
;--- Beschrijving:	Test de status van het resultaat na een acie
;--- invoer:	TWI_STATUS_x bevat een constante waarde uit de TWI_STATUS_ lijst
;---			na het uitvoeren van een TWI-actie, wordt gekeken of het resultaat is
;---			zoals de status-code die deze constante representeerd.
;---			Als de huidige status niet overeenkomt, wordt gesprongen naar
;---			het adres/label "OnError".
;--------------------------------------------
.MACRO TWI_CHECK;(TWI_STATUS_x: constante; OnError: Label)
	in		R16, TWSR
	andi	R16, TWI_STATUS_MASK
	cpi		R16, TWI_STATUS_Bus_Error
	breq	_2
	cpi		R16, TWI_STATUS_No_Status_Available
	breq	_2
	cpi		R16, @0
	breq	_0
_2:	; bus-error; Geef een STOP
	TWI_STOP
_1:	rjmp	@1
_0:
.ENDMACRO

;--------------------------------------------
;--- Naam:			TWI_ByteIn
;--- Beschrijving:	Een byte lezen van de bus en opslaan in de BufferIN
;--- invoer:	register "Data" bevat de gelezen byte-waarde
;--------------------------------------------
.MACRO TWI_ByteIn;(Data: register)
	in		@0, TWDR
.ENDMACRO

;--------------------------------------------
;--- Naam:			TWI_ByteOut
;--- Beschrijving:	Een byte schrijven op de bus
;--- invoer:	register "Data" bevat de te schrijven byte-waarde
;--------------------------------------------
.MACRO TWI_ByteOut;(Data: register)
	out		TWDR, @0
	ldi		@0, (1<<TWINT | 1<<TWEN | 1<<TWEA)
	out		TWCR, @0
.ENDMACRO

;--------------------------------------------
;--- Naam:			TWI_SLAW
;--- Beschrijving:	Het 'slave-adres + WRITE' bit schrijven op de bus
;--- invoer:	register "Address" bevat het adres van de slave
;--------------------------------------------
.MACRO TWI_SLAW;(Address: register)
	lsl		@0
	;ori	@0, TWI_WRITE
	TWI_ByteOut @0
.ENDMACRO

;--------------------------------------------
;--- Naam:			TWI_SLAR
;--- Beschrijving:	Het 'slave-adres + READ' bit schrijven op de bus
;--- invoer:	register "Address" bevat het adres van de slave
;--------------------------------------------
.MACRO TWI_SLAR;(Address: register)
	lsl		@0
	ori		@0, TWI_READ
	TWI_ByteOut @0
.ENDMACRO

;--------------------------------------------
;--- Naam:			TWI_GENERALCALL-W
;--- Beschrijving:	Het 'General-Call adres + WRITE' bit schrijven op de bus
;--------------------------------------------
.MACRO TWI_GENERALCALL-W
	ldi		R16, TWI_WRITE					; adres 0 + TWI_WRITE = TWI_WRITE
	TWI_ByteOut R16
.ENDMACRO



;--------------------------------------------
;--- Naam:			TWI_Transmit
;--- Beschrijving:	bytes schrijven op de bus
;--- invoer: 		register "Address" bevat het adres van de slave					(<>R16, <>XL, <>XH, <>ZL, <>ZH)
;---				BufferOUT bevat de te schrijven bytes
;--- uitvoer:		carry-flag is gewist bij succesvolle verzending
;---				carry-flag is gezet als er zich een fout heeft voorgedaan
;--------------------------------------------
.MACRO TWI_Transmit;(Address: register)
	lds		R16, TWI_BufferOUT_Count
	cpi		R16, 0							; iets te verzenden?
	brne	_4								; nee? dan al klaar..met foutcode
	rjmp	_0
_4:	; START
	TWI_START
	TWI_WAIT_READY
	TWI_CHECK TWI_STATUS_Start_Transmitted, _0
	; SLA/W
	TWI_SLAW @0
	TWI_WAIT_READY
	TWI_CHECK TWI_STATUS_SLAW_Transmitted_ACK_Received, _0
	;- - - - - - - - - - - - - - - - - - - \
_2:	; DATA schrijven
	TWI_BufferOUT_pop R16					; byte ophalen uit BufferOUT in R16
	brcs	_3
	TWI_ByteOut R16							; byte schrijven op de bus
	TWI_WAIT_READY
	TWI_CHECK TWI_STATUS_Data_Transmitted_ACK_Received, _0
	rjmp	_2
_3:	;- - - - - - - - - - - - - - - - - - - /
	; STOP
	TWI_STOP
	clc										; succes
	rjmp	_1
_0:	;OnError label
	sec										; fout
_1:	;klaar..
.ENDMACRO

;--------------------------------------------
;--- Naam:			TWI_Transceive
;--- Beschrijving:	bytes schrijven op de bus en daarna bytes lezen van de bus
;--- invoer: 		register "SlaveAddress" bevat het adres van de slave			(<>R16, <>XL, <>XH, <>ZL, <>ZH)
;---				BufferOUT bevat de te schrijven bytes
;---				register "CountIn" bevat het aantal te lezen bytes				(<>R16, <>XL, <>XH, <>ZL, <>ZH)
;--- uitvoer:		carry-flag is gewist bij succesvolle overdracht
;---				carry-flag is gezet als er zich een fout heeft voorgedaan
;---				BufferIN bevat de gelezen bytes
;--------------------------------------------
.MACRO TWI_Transceive;(SlaveAddress,CountIn: register)
	lds		R16, TWI_BufferOUT_Count
	cpi		R16, 0							; iets te verzenden?
	brne	_7
	rjmp	_0								; nee? dan al klaar..met foutcode
_7:	cpi		@1, 0							; iets te ontvangen?
	brne	_8
	rjmp	_0								; nee? dan al klaar..met foutcode
_8:	; START
	TWI_START
	TWI_WAIT_READY
	TWI_CHECK TWI_STATUS_Start_Transmitted, _0
	; SLA/W
	TWI_SLAW @0
	TWI_WAIT_READY
	TWI_CHECK TWI_STATUS_SLAW_Transmitted_ACK_Received, _0
	;- - - - - - - - - - - - - - - - - - - \
_2:	; DATA schrijven
	TWI_BufferOUT_pop R16					; byte ophalen uit BufferOUT in R16
	brcs	_6
	TWI_ByteOut R16							; byte schrijven op de bus
	TWI_WAIT_READY
	TWI_CHECK TWI_STATUS_Data_Transmitted_ACK_Received, _0
	rjmp	_2
	;- - - - - - - - - - - - - - - - - - - /
_6:	; REPEATED-START
	TWI_REPEATEDSTART
	TWI_WAIT_READY
	TWI_CHECK TWI_STATUS_RepeatedStart_Transmitted, _0
	; SLA/R
	TWI_SLAR @0
	TWI_WAIT_READY
	TWI_CHECK TWI_STATUS_SLAR_Transmitted_ACK_Received, _0
	;- - - - - - - - - - - - - - - - - - - \
_3:	; ACK of NACK instellen
	cpi		@1, 1							; laatste te ontvangen byte?
	brne	_5								; nee? dan data ontvangen en ACK laten geven
	Enable_TWI_NACK							; ..anders: NACK geven bij de laatste byte
_5:	; DATA lezen
	TWI_WAIT_READY
	TWI_CHECK TWI_STATUS_Data_Received_ACK_Transmitted, _0
	TWI_ByteIn R16							; byte lezen van de bus
	TWI_BufferIN_push R16					; byte in R16 opslaan in BufferIN
	dec		@1								; "aantal bytes te ontvangen" teller verlagen, en loopen
_4:	cpi		@1, 0
	brne	_3
	;- - - - - - - - - - - - - - - - - - - /
	; STOP
	TWI_STOP
	clc										; succes
	rjmp	_1
_0:	;OnError label
	sec										; fout
_1:	;klaar..
.ENDMACRO

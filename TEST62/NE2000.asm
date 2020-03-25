
;;--- REGISTER ALIASSEN ----------------\
;.def CharReg	= R0					; tbv. LPM-instructie
;.def temp		= R16					; Een register voor algemeen gebruik
;.def temp2		= R17					;  "
;.def temp3		= R18					;  "
;.def temp4		= R19					;  "
;;--------------------------------------/


;;--------------------------------------\
;.include "Delays.asm"					; Delay routine's
;.include "LCD.asm"						; LCD routine's
;;--------------------------------------/


;--- NE2000 ethernet card -------------\
; internal command registers for the DP8390 chip.
; definitions are taken from National Semiconductor document
; DP8390D.pdf: "DP8390D/NS32490D NIC Network Interface Controller"
; (this is the datasheet for the DP8390D chip, which was used in
; the original NE2000 cards).
; hardware has the base address hardwired. the software
; only needs to set the lowest 5 bits
.equ NE2K_BASE = 0
; internal registers (see page 17 of DP8390D.pdf).
; these are defined here for completeness. i doubt i will need to use
; all of them in the code.
;--- Page 0 readable registers ---------
.equ NE2K_CR	= NE2K_BASE + 0			; command register
.equ NE2K_CLDA0	= NE2K_BASE + 1			; current local DMA address 0
.equ NE2K_CLDA1	= NE2K_BASE + 2			; local dma 1
.equ NE2K_BNRY	= NE2K_BASE + 3			; boundary pointer
.equ NE2K_TSR	= NE2K_BASE + 4			; transmit status register
.equ NE2K_NCR	= NE2K_BASE + 5			; number of collisions register
.equ NE2K_FIFO	= NE2K_BASE + 6			; FIFO
.equ NE2K_ISR	= NE2K_BASE + 7			; interrupt status register
.equ NE2K_CRDA0	= NE2K_BASE + 8			; current remote DMA address 0
.equ NE2K_CRDA1	= NE2K_BASE + 9			; remote DMA 1
.equ NE2K_RESV1	= NE2K_BASE + 10		; reserved
.equ NE2K_RESV2	= NE2K_BASE + 11		; reserved
.equ NE2K_RSR	= NE2K_BASE + 12		; receive status register
.equ NE2K_CNTR0	= NE2K_BASE + 13		; tally counter 0 (frame alignment errors)
.equ NE2K_CNTR1 = NE2K_BASE + 14		; tally counter 1 (CRC errors)
.equ NE2K_CNTR2 = NE2K_BASE + 15		; tally counter 2 (missed packet errors)
;--- Page 0 writable registers ---------
; +0: CR is read/write
.equ NE2K_PSTART	= NE2K_BASE + 1		; page start register
.equ NE2K_PSTOP		= NE2K_BASE + 2		; page stop register
; +3: BNRY is read/write
.equ NE2K_TPSR	= NE2K_BASE + 4			; transmit page start address
.equ NE2K_TBCR0	= NE2K_BASE + 5			; transmit byte count register 0
.equ NE2K_TBCR1	= NE2K_BASE + 6			; transmit byte count register 1
; +7: ISR is read/write
.equ NE2K_RSAR0	= NE2K_BASE + 8			; remote start address register 0
.equ NE2K_RSAR1	= NE2K_BASE + 9			; remote start address register 1
.equ NE2K_RBCR0	= NE2K_BASE + 10		; remote byte count register 0
.equ NE2K_RBCR1	= NE2K_BASE + 11		; remote byte count register 1
.equ NE2K_RCR	= NE2K_BASE + 12		; receive configuration register
.equ NE2K_TCR	= NE2K_BASE + 13		; transmit configuration register
.equ NE2K_DCR	= NE2K_BASE + 14		; data configuration register
.equ NE2K_IMR	= NE2K_BASE + 15		; interrupt mask register
;--- Page 1 registers ------------------
; +0: CR spans pages 0,1, and 2
.equ NE2K_PAR0	= NE2K_BASE + 1			; physical address register 0
.equ NE2K_PAR1	= NE2K_BASE + 2			; physical address register 1
.equ NE2K_PAR2	= NE2K_BASE + 3			; physical address register 2
.equ NE2K_PAR3	= NE2K_BASE + 4			; physical address register 3
.equ NE2K_PAR4	= NE2K_BASE + 5			; physical address register 4
.equ NE2K_PAR5	= NE2K_BASE + 6			; physical address register 5
.equ NE2K_CURR	= NE2K_BASE + 7			; current page register
.equ NE2K_MAR0	= NE2K_BASE + 8			; multicast address register 0
.equ NE2K_MAR1	= NE2K_BASE + 8			; multicast address register 1
.equ NE2K_MAR2	= NE2K_BASE + 10		; multicast address register 2
.equ NE2K_MAR3	= NE2K_BASE + 11		; multicast address register 3
.equ NE2K_MAR4	= NE2K_BASE + 12		; multicast address register 4
.equ NE2K_MAR5	= NE2K_BASE + 13		; multicast address register 5
.equ NE2K_MAR6	= NE2K_BASE + 14		; multicast address register 6
.equ NE2K_MAR7	= NE2K_BASE + 15		; multicast address register 7
;--- Page 2 registers ------------------
; ... not implemented ...
;--- Page 3 registers ------------------
; ... not implemented ...
;--- other special locations -----------
.equ NE2K_DATAPORT	= NE2K_BASE + 0x10
.equ NE2K_RESET		= NE2K_BASE + 0x1f
;.equ NE2K_IO_EXTENT = NE2K_BASE + 0x20

; bits in various registers
.equ NE2K_CR_STOP			= 0x01		; stop card
.equ NE2K_CR_START			= 0x02		; start card
.equ NE2K_CR_TRANSMIT		= 0x04		; transmit packet
.equ NE2K_CR_DMAREAD		= 0x08		; remote DMA read
.equ NE2K_CR_DMAWRITE		= 0x10		; remote DMA write
.equ NE2K_CR_NODMA			= 0x20		; abort/complete remote DMA
.equ NE2K_CR_PAGE0			= 0x00		; select register page 0
.equ NE2K_CR_PAGE1			= 0x40		; select register page 1
.equ NE2K_CR_PAGE2			= 0x80		; select register page 2
.equ NE2K_RCR_BCAST			= 0x04
.equ NE2K_RCR_MCAST			= 0x08
.equ NE2K_RCR_PROMISCUOUS	= 0x10
.equ NE2K_RCR_MONITOR		= 0x20
.equ NE2K_DCR_BYTEDMA		= 0x00
.equ NE2K_DCR_WORDDMA		= 0x01
.equ NE2K_DCR_NOLPBK		= 0x08
.equ NE2K_DCR_FIFO2			= 0x00
.equ NE2K_DCR_FIFO4			= 0x20
.equ NE2K_DCR_FIFO8			= 0x40
.equ NE2K_DCR_FIFO12		= 0x60
.equ NE2K_TCR_NOLPBK		= 0x00
.equ NE2K_TCR_INTLPBK		= 0x02
.equ NE2K_TCR_EXTLPBK		= 0x04
.equ NE2K_TCR_EXTLPBK2		= 0x06

; i don't have a spec sheet on it, but it seems that the ne2000 cards have 16kb
; of onboard ram mapped to locations 0x4000 - 0x8000. this is used as a buffer
; for packets, either before transmission, or after reception. the DP8390D spec
; sheet describes how the chip manages the buffer space. in summary, you need to
; mark off a relatively small section for your transmit buffer. it seems that
; you can use a chunk either at the beginning or the end of the ram segment. 6
; pages is the typical size. you then use the rest of the remaining space as a
; receive buffer. the chip treats this as a ring - in other words if it reaches
; the end of the space, it wraps around to the beginning and continues filling
; from there. you need to empty the data out fast enough, otherwise it will
; wrap around and hit itself in the tail. (it will detect this sitaution, and
; just drop incoming data until you clear out some space). there are several
; pointers which are used to keep track of all this. read the datashet for more
; details.
.equ NE2K_TRANSMIT_BUFFER	= 0x40 ; transmit buffer from 0x4000 - 0x45ff.
; we could add a second 6-page buffer
; here to do ping-pong (back-to-back)
; transmissions, but lets leave that for
; later...
.equ NE2K_START_PAGE	= 0x46			; receive buffer ring from
;.equ NE2K_STOP_PAGE		= 0x80			; 0x4600-0x7fff
.equ NE2K_STOP_PAGE		= 0x60			; 0x4600-0x5fff
;--------------------------------------/



;--- Hardcoded IP-address -------------\
.equ NE2K_IP_OCTET_1	= 192
.equ NE2K_IP_OCTET_2	= 168
.equ NE2K_IP_OCTET_3	= 2
.equ NE2K_IP_OCTET_4	= 65
;--- Hardcoded MAC-address ------------
.equ NE2K_MAC_OCTET_1	= '0'
.equ NE2K_MAC_OCTET_2	= 'A'
.equ NE2K_MAC_OCTET_3	= 'V'
.equ NE2K_MAC_OCTET_4	= 'R'
.equ NE2K_MAC_OCTET_5	= '0'
.equ NE2K_MAC_OCTET_6	= '1'
;--------------------------------------/



;--- Ethernet Packet layout offsets ---\
.equ EthPacketDest0		= $00
.equ EthPacketDest1		= $01
.equ EthPacketDest2		= $02
.equ EthPacketDest3		= $03
.equ EthPacketDest4		= $04
.equ EthPacketDest5		= $05
.equ EthPacketSrc0		= $06
.equ EthPacketSrc1		= $07
.equ EthPacketSrc2		= $08
.equ EthPacketSrc3		= $09
.equ EthPacketSrc4		= $0A
.equ EthPacketSrc5		= $0B
.equ EthPacketType0		= $0C
.equ EthPacketType1		= $0D
;--------------------------------------/

;--- ARP Packet layout offsets --------\
.equ ARP_hwtype			= $0E
.equ ARP_prtype			= $10
.equ ARP_hwlen			= $12
.equ ARP_prlen			= $13
.equ ARP_op				= $14
; ARP source MAC address
.equ ARP_shaddr			= $16
; ARP source IP address
.equ ARP_sipaddr		= $1C
; ARP target MAC address
.equ ARP_thaddr			= $20
; ARP target IP address
.equ ARP_tipaddr0		= $26
.equ ARP_tipaddr1		= $27
.equ ARP_tipaddr2		= $28
.equ ARP_tipaddr3		= $29
;--------------------------------------/

;--- IP Packet layout offsets ---------\
; IP header layout IP version and header length
.equ IP_vers_len		= $0E
; IP type of service
.equ IP_tos				= $0F
; packet length
.equ IP_pktlen0			= $10
.equ IP_pktlen1			= $11
; datagram id
.equ IP_id				= $12
; fragment offset
.equ IP_frag_offset		= $14
; time to live
.equ IP_ttl				= $16
; protocol (ICMP=1, TCP=6, UDP=11)
.equ IP_proto			= $17
; header checksum
.equ IP_hdr_cksum0		= $18
.equ IP_hdr_cksum1		= $19
; IP address of source
.equ IP_srcaddr0		= $1A
.equ IP_srcaddr1		= $1B
.equ IP_srcaddr2		= $1C
.equ IP_srcaddr3		= $1D
; IP address of destination
.equ IP_destaddr0		= $1E
.equ IP_destaddr1		= $1F
.equ IP_destaddr2		= $20
.equ IP_destaddr3		= $21
; IP data area
.equ IP_data			= $22
;--------------------------------------/

;--- ICMP Packet layout offsets -------\
.equ ICMP_type			= IP_data
.equ ICMP_code			= ICMP_type + 1
.equ ICMP_cksum			= ICMP_code + 1
.equ ICMP_id			= ICMP_cksum + 2
.equ ICMP_seqnum		= ICMP_id + 2
.equ ICMP_data			= ICMP_seqnum + 2
;--------------------------------------/

;--- UDP Packet layout offsets --------\
.equ UDP_srcport0		= IP_data
.equ UDP_srcport1		= IP_data + 1
.equ UDP_destport0		= UDP_srcport0 + 2
.equ UDP_destport1		= UDP_srcport0 + 3
.equ UDP_len			= UDP_destport0 + 2
.equ UDP_chksum0		= UDP_len + 2
.equ UDP_chksum1		= UDP_len + 3
.equ UDP_data			= UDP_chksum0 + 2
;--------------------------------------/




;--- ISA Connectie --------------------\
.equ NE2K_DATA_OUT		= PORTD
.equ NE2K_DATA_IN		= PIND
.equ NE2K_DATA_DDR		= DDRD
.equ NE2K_ADDR_OUT		= PORTA			; bits 0-4
.equ NE2K_ADDR_DDR		= DDRA
.equ NE2K_CTRL_OUT		= PORTA			; bits 5-7
.equ NE2K_ISA_ADDR		= 0b00011111	; masker
.equ NE2K_ISA_IOR		= 0b00100000
.equ NE2K_ISA_IOR_PIN	= PA5
.equ NE2K_ISA_IOW		= 0b01000000
.equ NE2K_ISA_IOW_PIN	= PA6
.equ NE2K_ISA_RESET		= 0b10000000
.equ NE2K_ISA_RESET_PIN	= PA7
;; LED
;.equ LED_PORT		= PORTB
;.equ LED_PIN		= PB0
;.equ LED_DDR		= DDRB
;--------------------------------------/





;--- Een EEPROM-segment ---------------\
;.ESEG
;txtICMP:	.db	"ICMP", EOS_Symbol
;txtTCP:		.db	"TCP", EOS_Symbol
;--------------------------------------/


;--- Een DATA-segment in SRAM ---------\
.DSEG
NE2K_Resend:		.BYTE 1				; resend packet after overrun
NE2K_Packet:		.BYTE 300			; de packet-buffer
NE2K_PageHeader0:	.BYTE 1				; de page-header status
NE2K_PageHeader1:	.BYTE 1				;     "    "     nextBlock_ptr
NE2K_PageHeader2:	.BYTE 1				;     "    "     low(packet_len)
NE2K_PageHeader3:	.BYTE 1				;     "    "     high(packet_len)
IP_Checksum:		.BYTE 4				; De checksum in de IP-header
;--------------------------------------/





;--- Een CODE-segment in FLASH ---------
.CSEG


;---------------------------------------
;--- NE2K_ProcessMessages
;---------------------------------------
NE2K_ProcessMessages:
	push	R16
	push	R17
	push	R20
	push	R21

	; Start de NIC
	ldi		R16, NE2K_CR
	ldi		R17, $22
	rcall	NE2K_Write

	; Wacht op een goed pakketje
;WaitForPacket:
;	sbis	$10, 2	;Eedo = $20 !!!!!DEBUG!!!!!
;	rjmp	WaitForPacket
;	;rjmp	DoneProcessMessages

	; check voor een buffer-overrun
	ldi		R16, NE2K_ISR
	rcall	NE2K_Read
	sbrc	R17, 4
	rcall	NE2K_Overrun

	; Goede packets verwerken
	sbrc	R17, 0
	rcall	NE2K_GetPacket

	; De receive buffer ring moet leeg zijn nu..
	ldi		R16, NE2K_BNRY
	rcall	NE2K_Read
	mov		R20, R17					; waarde tijdelijk bewaren..
	ldi		R16, NE2K_CR
	ldi		R17, $62
	rcall	NE2K_Write
	ldi		R16, NE2K_CURR
	rcall	NE2K_Read
	mov		R21, R17					; waarde tijdelijk bewaren..
	ldi		R16, NE2K_CR
	ldi		R17, $22
	rcall	NE2K_Write
	; check of de buffer leeg is (leeg als: R20==R21)
	cp		R20, R21
	breq	DoneProcessMessages
	rcall	NE2K_GetPacket

DoneProcessMessages:
	; reset interrupt bits	
	ldi		R16, NE2K_ISR
	ldi		R17, $FF
	rcall	NE2K_Write

	pop		R21
	pop		R20
	pop		R17
	pop		R16
	ret




;---------------------------------------; Aangepast dd. 4 maart 2004
;--- NE2000 Write
;--- input: R16 = Address (5 bits)
;---        R17 = Data (1 byte)
;---------------------------------------
NE2K_Write:
	andi	R16, NE2K_ISA_ADDR
	ori		R16, (NE2K_ISA_IOW_PIN | NE2K_ISA_IOR_PIN | NE2K_ISA_RESET_PIN) ; besturings-lijnen niet naar 0 laten gaan
	out		NE2K_ADDR_OUT, R16

	out		NE2K_DATA_OUT, R17

	ldi		R17, PORT_AS_OUTPUT
	out		NE2K_DATA_DDR, R17
	nop

	cbi		NE2K_CTRL_OUT, NE2K_ISA_IOW_PIN
	nop
	sbi		NE2K_CTRL_OUT, NE2K_ISA_IOW_PIN
	nop

	ldi		R17, PORT_AS_INPUT
	out		NE2K_DATA_DDR, R17
	ldi		R17, INPUT_PORT_PULL
	out		NE2K_DATA_OUT, R17

	ret




;---------------------------------------; Aangepast dd. 4 maart 2004
;--- NE2000 Read
;--- input:	 R16 = Address (5 bits)
;--- output: R17 = gelezen byte
;---------------------------------------
NE2K_Read:
	ldi		R17, PORT_AS_INPUT
	out		NE2K_DATA_DDR, R17
	ldi		R17, INPUT_PORT_PULL
	out		NE2K_DATA_OUT, R17

	andi	R16, NE2K_ISA_ADDR
	ori		R16, (NE2K_ISA_IOW_PIN | NE2K_ISA_IOR_PIN | NE2K_ISA_RESET_PIN)	; besturings-lijnen niet naar 0 laten gaan
	out		NE2K_ADDR_OUT, R16

	cbi		NE2K_CTRL_OUT, NE2K_ISA_IOR_PIN
	nop
	in		R17, NE2K_DATA_IN
	sbi		NE2K_CTRL_OUT, NE2K_ISA_IOR_PIN
	nop

	ret






;---------------------------------------
;--- NE2000 MsgNotInitialized
;---------------------------------------
Msg_NE2K:			.db "NE2K ", EOS_Symbol
Msg_Not:			.db "Not ", EOS_Symbol
Msg_Initialized:	.db "Initialized", EOS_Symbol

MsgNE2K:
	ldi		ZL, low(Msg_NE2K)
	ldi		ZH, high(Msg_NE2K)
	rcall	LCD_Print
	ret

MsgNot:
	ldi		ZL, low(Msg_Not)
	ldi		ZH, high(Msg_Not)
	rcall	LCD_Print
	ret

MsgInitialized:
	ldi		ZL, low(Msg_Initialized)
	ldi		ZH, high(Msg_Initialized)
	rcall	LCD_Print
	ret


;---------------------------------------; Aangepast dd. 4 maart 2004
;--- NE2000 Initialize
;---------------------------------------
NE2K_Initialize:
	ldi		R17, PORT_AS_INPUT
	out		NE2K_DATA_DDR, R17
	ldi		R17, INPUT_PORT_PULL
	out		NE2K_DATA_OUT, R17

	ldi		R17, PORT_AS_OUTPUT
	out		NE2K_ADDR_DDR, R17
	ldi		R17, INPUT_PORT_TRIS
	ori		R17, (NE2K_ISA_IOW_PIN | NE2K_ISA_IOR_PIN | NE2K_ISA_RESET_PIN)	; besturings-lijnen niet naar 0 laten gaan
	out		NE2K_ADDR_OUT, R17

	sbi		NE2K_CTRL_OUT, NE2K_ISA_IOR_PIN
	sbi		NE2K_CTRL_OUT, NE2K_ISA_IOW_PIN

	sbi		NE2K_CTRL_OUT, NE2K_ISA_RESET_PIN
	rcall	delay1ms
	rcall	delay1ms
	cbi		NE2K_CTRL_OUT, NE2K_ISA_RESET_PIN

	ldi		R16, NE2K_RESET
	rcall	NE2K_Read
	rcall	NE2K_Write
	rcall	delay5ms
	rcall	delay5ms

	; controleren op een goede reset
	rcall	MsgNE2K						; NE2K status melding op LCD..
	ldi		R16, NE2K_ISR
	rcall	NE2K_Read
	sbrs	R17, 7						; foute reset als nu geldt: bit 7 = 0
	rcall	MsgNot						; ..
	rcall	MsgInitialized				; ..melding op LCD
	rcall	LCD_NextLine

	ldi		R16, NE2K_CR
	ldi		R17, $21
	rcall	NE2K_Write

	rcall	delay1ms
	rcall	delay1ms
	
	ldi		R16, NE2K_DCR
	ldi		R17, $58
	rcall	NE2K_Write

	ldi		R16, NE2K_RBCR0
	ldi		R17, $00
	rcall	NE2K_Write

	ldi		R16, NE2K_RBCR1
	ldi		R17, $00
	rcall	NE2K_Write

	ldi		R16, NE2K_RCR
	ldi		R17, $04
	rcall	NE2K_Write

	ldi		R16, NE2K_TCR
	ldi		R17, $02
	rcall	NE2K_Write

	ldi		R16, NE2K_PSTART
	ldi		R17, NE2K_START_PAGE
	rcall	NE2K_Write

	ldi		R16, NE2K_BNRY
	ldi		R17, NE2K_START_PAGE
	rcall	NE2K_Write

	ldi		R16, NE2K_PSTOP
	ldi		R17, NE2K_STOP_PAGE
	rcall	NE2K_Write

	ldi		R16, NE2K_CR
	ldi		R17, $61
	rcall	NE2K_Write

	rcall	delay1ms
	rcall	delay1ms

	ldi		R16, NE2K_CURR
	ldi		R17, NE2K_START_PAGE
	rcall	NE2K_Write

	; Het MAC-adres naar EEPROM schrijven
	ldi		R16, NE2K_PAR0
	ldi		R17, NE2K_MAC_OCTET_1
	rcall	NE2K_Write
	mov		R16, R17
	rcall	LCD_HexByte
	ldi		R16, ':'
	rcall	LCD_LinePrintChar

	ldi		R16, NE2K_PAR1
	ldi		R17, NE2K_MAC_OCTET_2
	rcall	NE2K_Write
	mov		R16, R17
	rcall	LCD_HexByte
	ldi		R16, ':'
	rcall	LCD_LinePrintChar

	ldi		R16, NE2K_PAR2
	ldi		R17, NE2K_MAC_OCTET_3
	rcall	NE2K_Write
	mov		R16, R17
	rcall	LCD_HexByte
	ldi		R16, ':'
	rcall	LCD_LinePrintChar

	ldi		R16, NE2K_PAR3
	ldi		R17, NE2K_MAC_OCTET_4
	rcall	NE2K_Write
	mov		R16, R17
	rcall	LCD_HexByte
	ldi		R16, ':'
	rcall	LCD_LinePrintChar

	ldi		R16, NE2K_PAR4
	ldi		R17, NE2K_MAC_OCTET_5
	rcall	NE2K_Write
	mov		R16, R17
	rcall	LCD_HexByte
	ldi		R16, ':'
	rcall	LCD_LinePrintChar

	ldi		R16, NE2K_PAR5
	ldi		R17, NE2K_MAC_OCTET_6
	rcall	NE2K_Write
	mov		R16, R17
	rcall	LCD_HexByte
	rcall	LCD_NextLine

	ldi		R16, NE2K_CR
	ldi		R17, $21
	rcall	NE2K_Write

	ldi		R16, NE2K_DCR
	ldi		R17, $58
	rcall	NE2K_Write

	ldi		R16, NE2K_CR
	ldi		R17, $22
	rcall	NE2K_Write

	ldi		R16, NE2K_ISR
	ldi		R17, $FF
	rcall	NE2K_Write

	ldi		R16, NE2K_IMR
	ldi		R17, $11
	rcall	NE2K_Write

	ldi		R16, NE2K_TCR
	ldi		R17, $00
	rcall	NE2K_Write
	ret

Bleep:
	sbi		LED_PORT, LED_PIN			; LED aan !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	rcall	delay1ms
	cbi		LED_PORT, LED_PIN			; LED uit !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


;---------------------------------------; geporteerd dd. 5 maart 2004
;--- NE2000 Overrun
;---------------------------------------
NE2K_Overrun:
	push	R21
	push	R20
	push	R17
	push	R16

	ldi		R16, NE2K_CR
	rcall	NE2K_Read
	mov		R20, R17					; waarde tijdelijk bewaren

	ldi		R16, NE2K_CR
	ldi		R17, $21
	rcall	NE2K_Write

	rcall	delay1ms
	rcall	delay1ms

	ldi		R16, NE2K_RBCR0
	ldi		R17, $00
	rcall	NE2K_Write

	ldi		R16, NE2K_RBCR1
	ldi		R17, $00
	rcall	NE2K_Write

	; packet opnieuw verzenden nodig?
	ldi		R17, $00					; resend niet nodig als standaard markeren
	sts		NE2K_Resend, R17

	mov		R21, R20					; R21 = hulp1
	andi	R21, $04
	tst		R21
	brne	doneResend					; resend is niet nodig..

	ldi		R16, NE2K_ISR
	rcall	NE2K_Read
	andi	R17, $08+$02
	tst		R17
	brne	doneResend					; resend is niet nodig..

	ldi		R17, $01					; resend is nodig.
	sts		NE2K_Resend, R17
doneResend:

	ldi		R16, NE2K_TCR
	ldi		R17, $02
	rcall	NE2K_Write

	ldi		R16, NE2K_CR
	ldi		R17, $22
	rcall	NE2K_Write

	ldi		R16, NE2K_BNRY
	ldi		R17, NE2K_START_PAGE
	rcall	NE2K_Write

	ldi		R16, NE2K_CR
	ldi		R17, $62
	rcall	NE2K_Write

	ldi		R16, NE2K_CURR
	ldi		R17, NE2K_START_PAGE
	rcall	NE2K_Write

	ldi		R16, NE2K_CR
	ldi		R17, $22
	rcall	NE2K_Write

	ldi		R16, NE2K_ISR
	ldi		R17, $10
	rcall	NE2K_Write

	ldi		R16, NE2K_TCR
	ldi		R17, $00
	rcall	NE2K_Write

	pop		R16
	pop		R17
	pop		R20
	pop		R21
	ret


;---------------------------------------; geporteerd dd. 5 maart 2004
;--- NE2000 GetPacket
;---------------------------------------
NE2K_GetPacket:
	push	R16
	push	R17
	push	ZL
	push	ZH
	push	XL
	push	XH
	push	YL
	push	YH

	ldi		R16, NE2K_CR
	ldi		R17, $1A
	rcall	NE2K_Write

	ldi		R16, NE2K_CR_DMAWRITE
	rcall	NE2K_Read
	sts		NE2K_PageHeader0, R17
	ldi		R16, NE2K_CR_DMAWRITE
	rcall	NE2K_Read
	sts		NE2K_PageHeader1, R17
	ldi		R16, NE2K_CR_DMAWRITE
	rcall	NE2K_Read
	sts		NE2K_PageHeader2, R17
	mov		YL, R17						; Y = RxLen = PageHeader3*256 + PageHeader2
	ldi		R16, NE2K_CR_DMAWRITE
	rcall	NE2K_Read
	sts		NE2K_PageHeader3, R17
	mov		YH, R17						; Y = RxLen = PageHeader3*256 + PageHeader2

	; Vul de buffer met maximaal 300 bytes, vergeet de evt. rest..
	ldi		XL, low(300)				; teller 
	ldi		XH, high(300)
	ldi		ZL, low(NE2K_Packet)		; destination
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, 1
processByte:
	ldi		R16, NE2K_CR_DMAWRITE
	rcall	NE2K_Read

	tst		XL
	breq	nextByte
	sbiw	XL, 1						; teller--
	breq	nextByte
	; copy de byte in R17 naar de Packet-buffer in SRAM
	st		Z+, R17						; dest.++
	
nextByte:
	sbiw	YL, 1						; RxLen--
	breq	doneCopyPacket
	rjmp	processByte
doneCopyPacket:

	; check ISR
	andi	R17, $40
	brne	checkedISR
	ldi		R16, NE2K_ISR
	rcall	NE2K_Read
checkedISR:
	ldi		R16, NE2K_ISR
	ldi		R17, $FF
	rcall	NE2K_Write

	; Process ARP Packet
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, EthPacketType0
	ld		R17, Z+
	cpi		R17, $08
	brne	ProcessUDP_ICMP
	ld		R17, Z
	cpi		R17, $06
	brne	ProcessUDP_ICMP
	
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, ARP_hwtype+1
	ld		R17, Z
	cpi		R17, $01
	brne	ProcessUDP_ICMP

	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, ARP_prtype+1
	ld		R17, Z
	cpi		R17, $00
	brne	ProcessUDP_ICMP

	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, ARP_hwlen
	ld		R17, Z
	cpi		R17, $06
	brne	ProcessUDP_ICMP

	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, ARP_prlen
	ld		R17, Z
	cpi		R17, $04
	brne	ProcessUDP_ICMP

	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, ARP_op+1
	ld		R17, Z
	cpi		R17, $01
	brne	ProcessUDP_ICMP

	; IP-adres controleren..
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, ARP_tipaddr0
	ld		R17, Z
	cpi		R17, NE2K_IP_OCTET_1
	brne	ProcessUDP_ICMP
	;
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, ARP_tipaddr1
	ld		R17, Z
	cpi		R17, NE2K_IP_OCTET_2
	brne	ProcessUDP_ICMP
	;
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, ARP_tipaddr2
	ld		R17, Z
	cpi		R17, NE2K_IP_OCTET_3
	brne	ProcessUDP_ICMP
	;
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, ARP_tipaddr3
	ld		R17, Z
	cpi		R17, NE2K_IP_OCTET_4
	brne	ProcessUDP_ICMP

	rcall	NE2K_ARP					; ARP-Packet ontvangen
	rjmp	doneProcessing
	
	; Process UDP/ICMP Packet
ProcessUDP_ICMP:
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, EthPacketType0
	ld		R17, Z+
	cpi		R17, $08
	brne	doneProcessing
	ld		R17, Z
	cpi		R17, $00
	brne	doneProcessing

	; IP-adres controleren..
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, IP_destaddr0
	ld		R17, Z
	cpi		R17, NE2K_IP_OCTET_1
	brne	doneProcessing
	;
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, IP_destaddr1
	ld		R17, Z
	cpi		R17, NE2K_IP_OCTET_2
	brne	doneProcessing
	;
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, IP_destaddr2
	ld		R17, Z
	cpi		R17, NE2K_IP_OCTET_3
	brne	doneProcessing
	;
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, IP_destaddr3
	ld		R17, Z
	cpi		R17, NE2K_IP_OCTET_4
	brne	doneProcessing

	; ICMP of UDP packet?
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, IP_proto
	ld		R17, Z
	cpi		R17, $01 ; ICMP
	brne	CheckUDP
	rcall	NE2K_ICMP					; ICMP-Packet ontvangen
	rjmp	doneProcessing
CheckUDP:
	cpi		R17, $11 ; UDP
	brne	doneProcessing
	rcall	NE2K_UDP					; UDP-Packet ontvangen

doneProcessing:
	pop		YH
	pop		YL
	pop		XH
	pop		XL
	pop		ZH
	pop		ZL
	pop		R17
	pop		R16
	ret




;---------------------------------------
;--- NE2K_SetIPAddress
;---------------------------------------
NE2K_SetIPAddress:
	; X register = src
	; Y register = dest
	push	R17
	push	R20
	push	ZL
	push	ZH
	push	XL
	push	XH
	push	YL
	push	YH

	; IP_destaddr := IP_srcaddr
	ldi		XL, low(NE2K_Packet)
	ldi		XH, high(NE2K_Packet)
	adiw	XL, IP_srcaddr0
	;
	ldi		YL, low(NE2K_Packet)
	ldi		YH, high(NE2K_Packet)
	adiw	YL, IP_destaddr0
	;
	ld		R17, X+
	st		Y+, R17
	ld		R17, X+
	st		Y+, R17
	ld		R17, X+
	st		Y+, R17
	ld		R17, X
	st		Y, R17
	; ethenet module IP-adres wordt het srcaddress
	ldi		YL, low(NE2K_Packet)
	ldi		YH, high(NE2K_Packet)
	adiw	YL, IP_srcaddr0
	;
	ldi		R17, NE2K_IP_OCTET_1
	st		Y+, R17 
	ldi		R17, NE2K_IP_OCTET_2
	st		Y+, R17 
	ldi		R17, NE2K_IP_OCTET_3
	st		Y+, R17 
	ldi		R17, NE2K_IP_OCTET_4
	st		Y, R17 

	; MAC adres dest.adres := MAC-src.
	ldi		XL, low(NE2K_Packet)
	ldi		XH, high(NE2K_Packet)
	adiw	XL, EthPacketSrc0
	;
	ldi		YL, low(NE2K_Packet)
	ldi		YH, high(NE2K_Packet)
	adiw	YL, EthPacketDest0
	;
	ld		R17, X+
	st		Y+, R17
	ld		R17, X+
	st		Y+, R17
	ld		R17, X+
	st		Y+, R17
	ld		R17, X+
	st		Y+, R17
	ld		R17, X+
	st		Y+, R17
	ld		R17, X+
	st		Y+, R17
	; ethenet module MAC-adres wordt het srcaddress
	ldi		YL, low(NE2K_Packet)
	ldi		YH, high(NE2K_Packet)
	adiw	YL, EthPacketSrc0
	;
	ldi		R17, NE2K_MAC_OCTET_1
	st		Y+, R17 
	ldi		R17, NE2K_MAC_OCTET_2
	st		Y+, R17 
	ldi		R17, NE2K_MAC_OCTET_3
	st		Y+, R17 
	ldi		R17, NE2K_MAC_OCTET_4
	st		Y+, R17 
	ldi		R17, NE2K_MAC_OCTET_5
	st		Y+, R17 
	ldi		R17, NE2K_MAC_OCTET_6
	st		Y, R17 

	; De IP-header checksum uitrekenen
;	ldi		YL, low(NE2K_Packet)
;	ldi		YH, high(NE2K_Packet)
;	adiw	YL, IP_hdr_cksum0
;	clr		R17
;	st		Y+, R17
;	st		Y, R17 
	;
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, IP_vers_len
	ld		R17, Z
	andi	R17, $0F						; R17 := aantal 32b words in header
	lsl		R17
	lsl		R17								; R17 := aantal bytes in header
	ldi		R20, IP_vers_len-1
	add		R17, R20
	inc		R17
	;
	SetVar32b IP_Checksum, $00000000
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, IP_vers_len
	ldi		R20, IP_vers_len
nextCS:
	ld		XH, Z+							; X := [Z]
	ld		XL, Z+
	com		XH								; X := not X
	com		XL
	Add16bToVar32b IP_Checksum, XL, XH		; IP_Checksum += X
	inc		R20
	cp		R20, R17
	brlo	nextCS

	lds		XL, IP_Checksum+2				; X := hwrd(IP_Checksum)
	lds		XH, IP_Checksum+3
	Add16bToVar16b IP_Checksum, XL, XH		; lwrd(IP_Checksum) += X
	ldi		YL, low(NE2K_Packet)
	ldi		YH, high(NE2K_Packet)
	adiw	YL, IP_hdr_cksum0
	lds		R17, IP_Checksum+1
	st		Y+, R17
	lds		R17, IP_Checksum
	st		Y+, R17

	pop		YH
	pop		YL
	pop		XH
	pop		XL
	pop		ZH
	pop		ZL
	pop		R20
	pop		R17
	ret




;---------------------------------------
;--- NE2K_ARP
;---------------------------------------
NE2K_ARP:
	; Start de NIC
	ldi		R16, NE2K_CR
	ldi		R17, $22
	rcall	NE2K_Write

	; load beginning page for transmit buffer
	ldi		R16, NE2K_TPSR
	ldi		R17, $40
	rcall	NE2K_Write

	; set start address for remote DMA operation
	ldi		R16, NE2K_RSAR0
	ldi		R17, $00
	rcall	NE2K_Write
	ldi		R16, NE2K_RSAR1
	ldi		R17, $40
	rcall	NE2K_Write

	; reset interrupt bits	
	ldi		R16, NE2K_ISR
	ldi		R17, $FF
	rcall	NE2K_Write

	; load data byte count for remote DMA
	ldi		R16, NE2K_RBCR0
	ldi		R17, $3C
	rcall	NE2K_Write
	ldi		R16, NE2K_RBCR1
	ldi		R17, $00
	rcall	NE2K_Write

	; do remote write operation
	ldi		R16, NE2K_CR
	ldi		R17, $12
	rcall	NE2K_Write

	; write destination MAC address
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, EthPacketSrc0
	ldi		R20, 6
NextDstByte:
	ldi		R16, NE2K_CR_DMAWRITE
	ld		R17, Z+
	rcall	NE2K_Write
	dec		R20
	brne	NextDstByte

	; write source address
	ldi		R16, NE2K_CR_DMAWRITE
	ldi		R17, NE2K_MAC_OCTET_1
	rcall	NE2K_Write
	ldi		R16, NE2K_CR_DMAWRITE
	ldi		R17, NE2K_MAC_OCTET_2
	rcall	NE2K_Write
	ldi		R16, NE2K_CR_DMAWRITE
	ldi		R17, NE2K_MAC_OCTET_3
	rcall	NE2K_Write
	ldi		R16, NE2K_CR_DMAWRITE
	ldi		R17, NE2K_MAC_OCTET_4
	rcall	NE2K_Write
	ldi		R16, NE2K_CR_DMAWRITE
	ldi		R17, NE2K_MAC_OCTET_5
	rcall	NE2K_Write
	ldi		R16, NE2K_CR_DMAWRITE
	ldi		R17, NE2K_MAC_OCTET_6
	rcall	NE2K_Write

	; ARP target IP address
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, ARP_op+1
	ldi		R17, $02
	st		Z, R17

	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, EthPacketType0
	ldi		R20, 10
NextTarget:
	ldi		R16, NE2K_CR_DMAWRITE
	ld		R17, Z+
	rcall	NE2K_Write
	dec		R20
	brne	NextTarget

	; write ethernet module mac address
	ldi		R16, NE2K_CR_DMAWRITE
	ldi		R17, NE2K_MAC_OCTET_1
	rcall	NE2K_Write
	ldi		R16, NE2K_CR_DMAWRITE
	ldi		R17, NE2K_MAC_OCTET_2
	rcall	NE2K_Write
	ldi		R16, NE2K_CR_DMAWRITE
	ldi		R17, NE2K_MAC_OCTET_3
	rcall	NE2K_Write
	ldi		R16, NE2K_CR_DMAWRITE
	ldi		R17, NE2K_MAC_OCTET_4
	rcall	NE2K_Write
	ldi		R16, NE2K_CR_DMAWRITE
	ldi		R17, NE2K_MAC_OCTET_5
	rcall	NE2K_Write
	ldi		R16, NE2K_CR_DMAWRITE
	ldi		R17, NE2K_MAC_OCTET_6
	rcall	NE2K_Write

	; write ethernet module IP-address
	ldi		R16, NE2K_CR_DMAWRITE
	ldi		R17, NE2K_IP_OCTET_1
	rcall	NE2K_Write
	ldi		R16, NE2K_CR_DMAWRITE
	ldi		R17, NE2K_IP_OCTET_2
	rcall	NE2K_Write
	ldi		R16, NE2K_CR_DMAWRITE
	ldi		R17, NE2K_IP_OCTET_3
	rcall	NE2K_Write
	ldi		R16, NE2K_CR_DMAWRITE
	ldi		R17, NE2K_IP_OCTET_4
	rcall	NE2K_Write

	; write remote mac address
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, EthPacketSrc0
	ldi		R20, 6
NextRMAC:
	ldi		R16, NE2K_CR_DMAWRITE
	ld		R17, Z+
	rcall	NE2K_Write
	dec		R20
	brne	NextRMAC

	; write remote IP address
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, ARP_sipaddr
	ldi		R20, 4
NextRIP:
	ldi		R16, NE2K_CR_DMAWRITE
	ld		R17, Z+
	rcall	NE2K_Write
	dec		R20
	brne	NextRIP

	; write som pad characters to fill out the packet to the minimum length
	ldi		R20, $12
	ldi		R17, $00
NextPadding:
	ldi		R16, NE2K_CR_DMAWRITE
	rcall	NE2K_Write
	dec		R20
	brne	NextPadding

	; make sure the DMA operation has succesfully completed
DMAComplete:
	ldi		R16, NE2K_ISR
	rcall	NE2K_Read
	andi	R17, $40
	brne	DMAComplete

	; load numbers of bytes to be transmitted
	ldi		R16, NE2K_TBCR0
	ldi		R17, $3C
	rcall	NE2K_Write
	ldi		R16, NE2K_TBCR1
	ldi		R17, $00
	rcall	NE2K_Write

	; send the contents of the transmit buffer onto the network
	ldi		R16, NE2K_CR
	ldi		R17, $24
	rcall	NE2K_Write
	ret


;---------------------------------------
;--- NE2K_ICMP
;---------------------------------------
NE2K_ICMP:
	ret


;---------------------------------------
;--- NE2K_UDP
;---------------------------------------
NE2K_UDP:
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, UDP_destport0
UDP_CheckPort7:
	ld		R17, Z+
	cpi		R17, $00
	brne	UDP_CheckPort5000
	ld		R17, Z
	cpi		R17, $07
	brne	UDP_CheckPort5000
	;
	rjmp	DoneNE2K_UDP				; tijdelijk geen packets retourneren

UDP_CheckPort5000:
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, UDP_destport0
	ld		R17, Z+
	cpi		R17, $13					; (poort) $1388 = 5000
	brne	DoneNE2K_UDP
	ld		R17, Z
	cpi		R17, $88
	brne	DoneNE2K_UDP

UDP_GotIt:
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, UDP_data
	ld		temp, Z
	;	
	rcall	LCD_LinePrintChar			; ontvangen byte afbeelden op LCD

DoneNE2K_UDP:
	ret


;---------------------------------------
;--- NE2K_ECHOPacket
;---------------------------------------
NE2K_ECHOPacket:
	; Start de NIC
	ldi		R16, NE2K_CR
	ldi		R17, $22
	rcall	NE2K_Write

	; load beginning page for transmit buffer
	ldi		R16, NE2K_TPSR
	ldi		R17, $40
	rcall	NE2K_Write

	; set start address for remote DMA operation
	ldi		R16, NE2K_RSAR0
	ldi		R17, $00
	rcall	NE2K_Write
	ldi		R16, NE2K_RSAR1
	ldi		R17, $40
	rcall	NE2K_Write

	; reset interrupt bits	
	ldi		R16, NE2K_ISR
	ldi		R17, $FF
	rcall	NE2K_Write

	; load data byte count for remote DMA
	lds		R17, NE2K_PageHeader2
	subi	R17, 4
	mov		XL, R17							; lowbyte bewaren in XL
	ldi		R16, NE2K_RBCR0
	rcall	NE2K_Write

	lds		R17, NE2K_PageHeader3
	mov		XH, R17							; highbyte in XH
	ldi		R16, NE2K_RBCR1
	rcall	NE2K_Write

	; do remote write operation
	ldi		R16, NE2K_CR
	ldi		R17, $12
	rcall	NE2K_Write

	; De waarde in reg.X bepaalt het aantal te schrijven bytes
	adiw	XL, 1
	ldi		ZL, low(NE2K_Packet)
	ldi		ZH, high(NE2K_Packet)
	adiw	ZL, EthPacketDest0
EchoLoop:
	ld		R17, Z+
	ldi		R16, NE2K_CR_DMAWRITE
	rcall	NE2K_Write
	;
	sbiw	XL, 1
	brne	EchoLoop

	; make sure the DMA operation has succesfully completed
EchoDMAComplete:
	ldi		R16, NE2K_ISR
	rcall	NE2K_Read
	andi	R17, $40
	brne	EchoDMAComplete

	lds		R17, NE2K_PageHeader2
	subi	R17, 4
	ldi		R16, NE2K_TBCR0
	rcall	NE2K_Write
	lds		R17, NE2K_PageHeader3
	ldi		R16, NE2K_TBCR1
	rcall	NE2K_Write

	; transmit the packet
	ldi		R16, NE2K_CR
	ldi		R17, $24
	rcall	NE2K_Write
	ret

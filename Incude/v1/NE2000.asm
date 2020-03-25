
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
; Page 0 readable registers
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
; Page 0 writable registers
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
; Page 1 registers
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
; Page 2 registers
; ... not implemented ...
; Page 3 registers
; ... not implemented ...
; other special locations
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
.equ NE2K_STOP_PAGE		= 0x80			; 0x4600-0x7fff
;--------------------------------------/



;--- Hardcoded IP-address -------------\
.equ NE2K_IP_OCTET_1	= 192
.equ NE2K_IP_OCTET_2	= 168
.equ NE2K_IP_OCTET_3	= 2
.equ NE2K_IP_OCTET_4	= 65
; which UDP port number should i listen on?
.equ NE2K_LISTEN_PORT	= 987
;--------------------------------------/



;--- ISA Connectie --------------------\
.equ NE2K_DATA_OUT	= PORTD
.equ NE2K_DATA_IN	= PIND
.equ NE2K_DATA_DDR	= DDRD
.equ NE2K_ADDR_OUT	= PORTA
.equ NE2K_ADDR_DDR	= DDRA
.equ NE2K_ISA_ADDR	= 0b00011111
.equ NE2K_ISA_IOR	= 0b00100000
.equ NE2K_ISA_IOW	= 0b01000000
.equ NE2K_ISA_RESET	= 0b10000000
;; LED
;.equ LED_PORT		= PORTB
;.equ LED_PIN		= PB0
;.equ LED_DDR		= DDRB
;--------------------------------------/





;--- Een EEPROM-segment ---------------\
.ESEG
txtICMP:	.db	"ICMP", EOS_Symbol
txtTCP:		.db	"TCP", EOS_Symbol
;--------------------------------------/


;--- Een DATA-segment in SRAM ---------\
.DSEG
NE2K_MAC_Addr:		.BYTE 6				; my hardware ethernet address
NE2K_IP_Addr:		.BYTE 4				; my ip address
NE2K_Peer_MAC_Addr:	.BYTE 6				; my partner's hardware ethernet address
NE2K_Peer_IP_Addr:	.BYTE 4				; my partner's ip address
;--------------------------------------/





;--- Een CODE-segment in FLASH ---------
.CSEG

;---------------------------------------
;--- NE2000 ProcessMessages
;---------------------------------------
NE2K_ProcessMessages:
	rcall	NE2K_Read_Packet
	ret


;---------------------------------------
;--- NE2000 Write
;--- input: R16 = Address (5 bits)
;---        R17 = Data (1 byte)
;---------------------------------------
NE2K_Write:
	push r18
	push r19
	; set both address and data ports for output
	ldi r18, PORT_AS_OUTPUT
	out NE2K_ADDR_DDR, r18
	out NE2K_DATA_DDR, r18
	; set data lines
	out NE2K_DATA_OUT, r17
	; set address lines, plus read/write strobes
	mov r18, r16
	andi r18, NE2K_ISA_ADDR
	ori r18, NE2K_ISA_IOR
	mov r19, r18
	ori r18, NE2K_ISA_IOW
	out NE2K_ADDR_OUT, r18				; IOW high
	rcall	delay1us
;	nop
;	nop
;	nop
;	nop
	out NE2K_ADDR_OUT, r19 				; IOW low
	rcall	delay1us
;	nop
;	nop
;	nop
;	nop
	out NE2K_ADDR_OUT, r18 				; IOW high
	pop r19
	pop r18
	ret


;---------------------------------------
;--- NE2000 Read
;--- input:	 R16 = Address (5 bits)
;--- output: R17 = gelezen byte
;---------------------------------------
NE2K_Read:
	push r18
	push r19
	; set address port for output
	ldi r18, PORT_AS_OUTPUT
	out NE2K_ADDR_DDR, r18
	; set data port for input
	ldi r18, PORT_AS_INPUT
	out NE2K_DATA_DDR, r18
	; set address lines, plus read/write strobes
	mov r18, r16
	andi r18, NE2K_ISA_ADDR
	ori r18, NE2K_ISA_IOW
	mov r19, r18
	ori r18, NE2K_ISA_IOR
	out NE2K_ADDR_OUT, r18 				; IOR high
	rcall	delay1us
;	nop
;	nop
;	nop
;	nop
	out NE2K_ADDR_OUT, r19 				; IOR low
	rcall	delay1us
;	nop
;	nop
;	nop
;	nop
	in r17, NE2K_DATA_IN
	out NE2K_ADDR_OUT, r18 				; IOR high
	pop r19
	pop r18
	ret


;---------------------------------------
;--- NE2000 Hard Reset
;---------------------------------------
NE2K_Hard_Reset:
	; set, then clear, the ISA RESET line, forcing a hard reset of the card
	push r18
	; set address port for output
	ldi r18, PORT_AS_OUTPUT
	out NE2K_ADDR_DDR, r18
	; reset line high
	ldi r18, NE2K_ISA_RESET | NE2K_ISA_IOR | NE2K_ISA_IOW
	out NE2K_ADDR_OUT, r18
	rcall delay100ms ; is this the right delay? i have no idea, but it works ok
	; reset line low
	ldi r18, NE2K_ISA_IOR | NE2K_ISA_IOW
	out NE2K_ADDR_OUT, r18
	rcall delay100ms ; another arbitrary delay
	pop r18
	ret


;;---------------------------------------
;;--- NE2000 Soft Reset
;;---------------------------------------
;NE2K_Soft_Reset:
;	; untested. i saw this in someone's driver.
;	push r16
;	push r17
;	ldi r16, NE2K_RESET
;	ldi r16, 0xff
;	rcall NE2K_Write
;	rcall delay25ms;
;	pop r17
;	pop r16
;	ret


;---------------------------------------
;--- NE2000 Initialize
;--- follow the initialization sequence described on page 19 of
;--- DP8390D.pdf (er, i mean "sort of" follow). lots of modifications,
;--- taken mostly from the linux driver. comments indicate interesting
;--- deviations in cheung's driver, the national semiconductor sample
;--- driver, and the linux driver,
;---------------------------------------
NE2K_Initialize:
	push r16
	push r17
	push r18
	push r30
	push r31
	; my step 0a: force a hardware reset on the card
	rcall NE2K_Hard_Reset
	; my step 0b: read mac address from the card's onboard eeprom
	rcall NE2K_Read_MAC_EEPROM			; read the mac address from the eeprom
	; step 1: program command register for page 0
	; cheung, ns 0x21
	ldi r16, NE2K_CR
	ldi r17, NE2K_CR_PAGE0 | NE2K_CR_STOP | NE2K_CR_NODMA
	rcall NE2K_Write
	; cheung does a soft reset here...
	; step 2: initialize data configuration register
	; cheung 0x48, ns 0x58
	ldi r16, NE2K_DCR
	ldi r17, NE2K_DCR_BYTEDMA | NE2K_DCR_FIFO8 | NE2K_DCR_NOLPBK
	rcall NE2K_Write
	; step 3: clear remote byte count registers
	; cheung, ns 0
	ldi r16, NE2K_RBCR0
	ldi r17, 0
	rcall NE2K_Write
	ldi r16, NE2K_RBCR1
	ldi r17, 0
	rcall NE2K_Write
	; step 4: initialize recieve configuration register
	; cheung: 0x0c, ns: 0, linux: 0x20
	ldi r16, NE2K_RCR
	;ldi r17, NE2K_RCR_BCAST
	ldi r17, NE2K_RCR_MONITOR			; disable reception for now
	rcall NE2K_Write
	; step 5: place the NIC in loopback mode (hey - don't i also have to set
	; a bit in DCR in order to go into loopback mode? hmm...)
	ldi r16, NE2K_TCR
	ldi r17, NE2K_TCR_INTLPBK
	rcall NE2K_Write
	; step 5 and a half: initialize the transmit buffer start page
	ldi r16, NE2K_TPSR
	ldi r17, NE2K_TRANSMIT_BUFFER
	rcall NE2K_Write
	; step 6: initialize receive buffer ring (256 byte blocks)
	; cheung: start=0x40, stop=0x76 (or 0x7c?)
	; ns: start=0x26, stop=0x40
	; linux: 0x26/0x40 or 0x46/0x80 (NE1SM or NESM)
	ldi r16, NE2K_PSTART
	ldi r17, NE2K_START_PAGE
	rcall NE2K_Write
	ldi r16, NE2K_BNRY
	ldi r17, NE2K_START_PAGE
	rcall NE2K_Write
	ldi r16, NE2K_PSTOP
	ldi r17, NE2K_STOP_PAGE
	rcall NE2K_Write
	; step 7: clear interrupt status register
	; cheung: performs this step earlier (after step #3)
	ldi r16, NE2K_ISR
	ldi r17, 0xff
	rcall NE2K_Write
	; step 8: initialize the interrupt mask register
	; cheung: 0 (out of order - after #7)
	; ns: 0x0b
	ldi r16, NE2K_IMR
	ldi r17, 0 							; no interrupts, please
	rcall NE2K_Write
	; step 9a: go to register page 1
	ldi r16, NE2K_CR
	ldi r17, NE2K_CR_PAGE1 | NE2K_CR_STOP | NE2K_CR_NODMA
	rcall NE2K_Write
	; step 9b: initialize hardware address
	; (what?! shouldn't this already be set from EEPROM?)
	ldi r30,low(NE2K_MAC_Addr) 			; Load Z register low
	ldi r31,high(NE2K_MAC_Addr) 		; Load Z register high
	ldi r16, NE2K_PAR0
	ld r17, Z+
	rcall NE2K_Write
	ldi r16, NE2K_PAR1
	ld r17, Z+
	rcall NE2K_Write
	ldi r16, NE2K_PAR2
	ld r17, Z+
	rcall NE2K_Write
	ldi r16, NE2K_PAR3
	ld r17, Z+
	rcall NE2K_Write
	ldi r16, NE2K_PAR4
	ld r17, Z+
	rcall NE2K_Write
	ldi r16, NE2K_PAR5
	ld r17, Z+
	rcall NE2K_Write
	; step 9c: initialize multicast address (i don't care about multicast)
	; ... not implemented ...
	; step 9d: initialize CURRent pointer
	ldi r16, NE2K_CURR
	ldi r17, NE2K_START_PAGE
	rcall NE2K_Write
	; step 10: put NIC in START mode
	ldi r16, NE2K_CR
	ldi r17, NE2K_CR_PAGE0 | NE2K_CR_START | NE2K_CR_NODMA
	rcall NE2K_Write
	; step 11: initialize transmit control register (disable loopback mode)
	ldi r16, NE2K_TCR
	ldi r17, NE2K_TCR_NOLPBK
	rcall NE2K_Write
	; should i re-set DCR here to cancel loopback?
	; my step 12: initialize recieve configuration register so that we can
	; get packets
	ldi r16, NE2K_RCR
	ldi r17, NE2K_RCR_BCAST
	rcall NE2K_Write
	; cheung reads the mac address from eeprom here. seems too late to me!
	pop r31
	pop r30
	pop r18
	pop r17
	pop r16
	ret


;---------------------------------------
;--- NE2000 Read MAC EEPROM
;--- read the mac address from the onboard EEPROM.
;--- store the 6-byte value into the designated RAM location (NE2K_MAC_Addr).
;--- copied functionality from linux ne.c driver initialization code.
;--- apparently the mac address from the nic's onboard eeprom is mapped to
;--- locations 0x0000 - 0x001f. i wish i had a spec sheet which told me these
;--- things. it is a pain in the neck to have to infer these facts by reading
;--- somebody else's sourcecode.
;---------------------------------------
NE2K_Read_MAC_EEPROM:
	push r16
	push r17
	push r30
	push r31
	ldi r30,low(NE2K_MAC_Addr) 			; Load Z register low
	ldi r31,high(NE2K_MAC_Addr) 		; Load Z register high
	; set register page 0
	ldi r16, NE2K_CR
	ldi r17, NE2K_CR_PAGE0 | NE2K_CR_STOP | NE2K_CR_NODMA
	rcall NE2K_Write
	; select byte wide transfers
	ldi r16, NE2K_DCR
	ldi r17, NE2K_DCR_BYTEDMA | NE2K_DCR_FIFO8 | NE2K_DCR_NOLPBK
	rcall NE2K_Write
	ldi r16, NE2K_RBCR0
	ldi r17, 0
	rcall NE2K_Write
	ldi r16, NE2K_RBCR1
	ldi r17, 0
	rcall NE2K_Write
	ldi r16, NE2K_IMR
	ldi r17, 0
	rcall NE2K_Write
	ldi r16, NE2K_ISR
	ldi r17, 0xff
	rcall NE2K_Write
	ldi r16, NE2K_RCR
	ldi r17, NE2K_RCR_MONITOR 			; receive off
	rcall NE2K_Write
	ldi r16, NE2K_TCR
	ldi r17, NE2K_TCR_INTLPBK 			; transmit off
	rcall NE2K_Write
	ldi r16, NE2K_RBCR0
	ldi r17, 32 						; intend to read 32 bytes
	rcall NE2K_Write
	ldi r16, NE2K_RBCR1
	ldi r17, 0
	rcall NE2K_Write
	ldi r16, NE2K_RSAR0
	ldi r17, 0 							; low byte of start address (0x0000)
	rcall NE2K_Write
	ldi r16, NE2K_RSAR1
	ldi r17, 0 							; high byte of start address
	rcall NE2K_Write
	ldi r16, NE2K_CR
	ldi r17, NE2K_CR_PAGE0 | NE2K_CR_START | NE2K_CR_DMAREAD
	rcall NE2K_Write
	ldi r16, NE2K_DATAPORT
	rcall NE2K_Read	; for some reason, 2 reads are required, otherwise you get duplicate values.
	rcall NE2K_Read	; the comments in the linux driver talk about values being "doubled up", but
	st Z+, r17		; i don't know why. whatever - it works this way and i don't have time to investigate :)
	ldi r16, NE2K_DATAPORT
	rcall NE2K_Read
	rcall NE2K_Read
	st Z+, r17
	ldi r16, NE2K_DATAPORT
	rcall NE2K_Read
	rcall NE2K_Read
	st Z+, r17
	ldi r16, NE2K_DATAPORT
	rcall NE2K_Read
	rcall NE2K_Read
	st Z+, r17
	ldi r16, NE2K_DATAPORT
	rcall NE2K_Read
	rcall NE2K_Read
	st Z+, r17
	ldi r16, NE2K_DATAPORT
	rcall NE2K_Read
	rcall NE2K_Read
	st Z+, r17
	; end (abort) the DMA transfer
	ldi r16, NE2K_CR
	ldi r17, NE2K_CR_PAGE0 | NE2K_CR_START | NE2K_CR_NODMA
	rcall NE2K_Write
	pop r31
	pop r30
	pop r17
	pop r16
	ret


;---------------------------------------
;--- NE2000 Read Packet
;--- workhorse loop for processing network traffic.
;---------------------------------------
NE2K_Read_Packet:
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15
	push r16
	push r17
	push r18
	push r19
	push r20
	push r30
	push r31
ne2k_read_packet_start:
	; goto register page 1
	ldi r16, NE2K_CR
	ldi r17, NE2K_CR_PAGE1 | NE2K_CR_START | NE2K_CR_NODMA
	rcall NE2K_Write
	; read the CURRent pointer
	ldi r16, NE2K_CURR
	rcall NE2K_Read
	mov r10, r17 ; copy CURR into r10
	; goto register page 0
	ldi r16, NE2K_CR
	ldi r17, NE2K_CR_PAGE0 | NE2K_CR_START | NE2K_CR_NODMA
	rcall NE2K_Write
	; read the boundary pointer
	ldi r16, NE2K_BNRY
	rcall NE2K_Read
	mov r11, r17 						; copy BNRY into r11
	cp r10, r11 						; compare CURR and BNRY
	brne ne2k_read_packet_data 			; if not equal, then there is data waiting to be read from the receive buffer ring.
	rjmp ne2k_read_packet_end 			; otherwise the receive buffer is empty, so we have nothing to do here.
	; there is data in the NIC's rx buffer which we need to read out
ne2k_read_packet_data:
	ldi r16, NE2K_RBCR0
	ldi r17, 0xff 						; i don't know how many bytes i intend
	rcall NE2K_Write 					; to read, so just set this to the maximum
	ldi r16, NE2K_RBCR1
	ldi r17, 0xff
	rcall NE2K_Write
	ldi r16, NE2K_RSAR0
	ldi r17, 0 							; low byte of start address (0)
	rcall NE2K_Write
	ldi r16, NE2K_RSAR1
	mov r17, r11 						; high byte of start address (BNRY)
	rcall NE2K_Write
	ldi r16, NE2K_CR 					; begin the dma read
	ldi r17, NE2K_CR_PAGE0 | NE2K_CR_START | NE2K_CR_DMAREAD
	rcall NE2K_Write
	ldi r16, NE2K_DATAPORT 				; all dma reads come out of this location
	; the first 6 bytes are not part of the actual received ethernet packet.
	; instead they contain some status information about the packet from
	; the dp8390 chip. (see page 11 of the dp8390d spec)
	rcall NE2K_Read
	mov r12, r17						 ; receive status code (same structure as
	; RSR - the receive status register)
	rcall NE2K_Read
	mov r13, r17 						; next packet pointer
	rcall NE2K_Read
	mov r14, r17 						; receive byte count low
	rcall NE2K_Read
	mov r15, r17 						; receive byte count high
	; i probably should check that the status code is "good", but for now
	; just assume that it is ok.
	; i probably should check that the length is reasonable, but for now
	; let's just assume it is ok.
	; now start reading the actual ethernet frame. (refer to Stevens "TCP/IP
	; Illustrated Volume 1", page 23, for a nice diagram of the ethernet
	; frame)
	;--- ETHERNET II FRAME ---------------------
	;--- Preamble (8 bytes)
	;--- Destination MAC Address (6 bytes)
	;--- Source MAC Address (6 bytes)
	;--- Type (2 bytes)
	;--- Data (46-1500 bytes)
	;--- FCS (Frame Check Sequence) (4 bytes)
	rcall NE2K_Read 					; destination mac address
	rcall NE2K_Read 					; i'm not paying attention to this,	since
	rcall NE2K_Read 					; the card should have already discarded
	rcall NE2K_Read 					; packets not meant for me or broadcast
	rcall NE2K_Read
	rcall NE2K_Read
	; the next 6 bytes are the source mac address. save this for my reply
	ldi r30,low(NE2K_Peer_MAC_Addr) 	; Load Z register low
	ldi r31,high(NE2K_Peer_MAC_Addr)	; Load Z register high
	rcall NE2K_Read
	st Z+, r17
	rcall NE2K_Read
	st Z+, r17
	rcall NE2K_Read
	st Z+, r17
	rcall NE2K_Read
	st Z+, r17
	rcall NE2K_Read
	st Z+, r17
	rcall NE2K_Read
	st Z+, r17
	; figure out if this is an 802.3 or Ethernet frame
	rcall NE2K_Read
	ldi r18, 0x06 						; if this byte is 0x06 or higher, it
	cp r17, r18 						; must be a "type" field, since a
	brsh ne2k_read_packet_eth			; "length" field cannot be 0x0600 (1536) or higher.
										; fallthrough: 802.3 frame (longer header)
	; Presence of a SNAP-header is indicated by DSAP & SSAP values of 170 ($AA),
	; a control value of 3 (unnumbered information),
	; and an organizatio code of 0.
	;--- LLC HEADER (logical Link Control) ------
	rcall NE2K_Read 					; length low byte (ignore)
	rcall NE2K_Read 					; DSAP (Destination Service Access Point)
	ldi r18, 0xaa
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	rcall NE2K_Read 					; SSAP (Source Service Access Point)
	ldi r18, 0xaa
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	rcall NE2K_Read 					; Control
	ldi r18, 0x03
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	;--- SNAP HEADER (Sub Network Access Protocol)
	rcall NE2K_Read 					; organization code 1
	ldi r18, 0
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	rcall NE2K_Read 					; organization code 2
	ldi r18, 0
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	rcall NE2K_Read 					; organization code 3
	ldi r18, 0
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	rcall NE2K_Read 					; Ether Type
ne2k_read_packet_eth:
	; look at the "type" field in the ethernet frame. the types i understand are 0x0800 (IP) and 0x0806 (ARP)
	; $0800 = Internet IP (IPv4)
	; $0805 = X.25 Level 3
	; $0806 = ARP
	; $6003 = DEC DECNET Phase IV
	; $6004 = DEC LAT
	; $6005 = DEC Diagnostic Protocol
	; $809B = Appletalk
	; $80D5 = IBM SNA Service on Ethernet
	; $8137-$8138 = Novell
	ldi r18, 0x08 						; type high byte
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	rcall NE2K_Read						; type low byte
	ldi r18, 0x00 						; 0x0800: IP
	cp r17, r18
	breq ne2k_read_packet_ip
	ldi r18, 0x06 						; 0x0806: ARP
	cp r17, r18
	breq ne2k_read_packet_arp
	; fallthrough: some other type which i don't recognize
	rjmp ne2k_read_packet_cleanup
ne2k_read_packet_ip:
	rjmp ne2k_read_packet_ip2 			; do a long jump
ne2k_read_packet_arp:
	; decode an ARP packet, and respond appropriately.
	; see Stevens p.56
	; confirm hardware type 0x0001
	rcall NE2K_Read 					; hardware type high byte
	ldi r18, 0x00
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	rcall NE2K_Read						; hardware type low byte
	ldi r18, 0x01
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	; confirm protocol type 0x0800
	rcall NE2K_Read 					; protocol type high byte
	ldi r18, 0x08
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	rcall NE2K_Read 					; protocol type low byte
	ldi r18, 0x00
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	; confirm hardware size 6
	rcall NE2K_Read
	ldi r18, 6
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	; confirm protocol size 4
	rcall NE2K_Read
	ldi r18, 4
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	; confirm op code 0x0001 (ARP request)
	rcall NE2K_Read
	ldi r18, 0x00
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	rcall NE2K_Read
	ldi r18, 0x01
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	; ignore sender's hardware address (we already recorded it)
	rcall NE2K_Read
	rcall NE2K_Read
	rcall NE2K_Read
	rcall NE2K_Read
	rcall NE2K_Read
	rcall NE2K_Read
	; record sender's IP address
	ldi r30,low(NE2K_Peer_IP_Addr) 		; Load Z register low
	ldi r31,high(NE2K_Peer_IP_Addr) 	; Load Z register high
	rcall NE2K_Read
	st Z+, r17
	rcall NE2K_Read
	st Z+, r17
	rcall NE2K_Read
	st Z+, r17
	rcall NE2K_Read
	st Z+, r17
	; ignore target hardware address (meaningless for this packet type)
	rcall NE2K_Read
	rcall NE2K_Read
	rcall NE2K_Read
	rcall NE2K_Read
	rcall NE2K_Read
	rcall NE2K_Read
	; compare target IP address to our own. if its a match, then we should
	; reply with an ARP reply. if it doesn't match, then this packet was
	; meant for someone else, so we can ignore it.
	ldi r30,low(NE2K_IP_Addr) 			; Load Z register low
	ldi r31,high(NE2K_IP_Addr) 			; Load Z register high
	ld r18, Z+ 							; read first octet of my IP address
	rcall NE2K_Read 					; read first octet of target IP address
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	ld r18, Z+ 							; read next octet of my IP address
	rcall NE2K_Read 					; read next octet of target IP address
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	ld r18, Z+ 							; read next octet of my IP address
	rcall NE2K_Read 					; read next octet of target IP address
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	ld r18, Z+ 							; read next octet of my IP address
	rcall NE2K_Read 					; read next octet of target IP address
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	; fallthrough: the target IP address is the same as my IP address.
	; goodie! i've read all there is to read from this packet.
	; end (abort) the DMA transfer
	ldi r16, NE2K_CR
	ldi r17, NE2K_CR_PAGE0 | NE2K_CR_START | NE2K_CR_NODMA
	rcall NE2K_Write
	; update the BNRY (recive buffer ring boundary) pointer.
	ldi r16, NE2K_BNRY
	mov r17, r13						; next packet pointer
	rcall NE2K_Write
	; now send an ARP reply packet.
	; rcall send_arp_reply
	; ****
	; ... i should test to make sure the card is not transmitting. otherwise
	; i might stomp over the data to be transmitted ...
	; ****
	; set the remote byte count to 60 (arp packets are 60 bytes)
	ldi r16, NE2K_RBCR0
	ldi r17, 60
	rcall NE2K_Write
	ldi r16, NE2K_RBCR1
	ldi r17, 0
	rcall NE2K_Write
	ldi r16, NE2K_RSAR0
	ldi r17, 0 							; low byte of start address
	rcall NE2K_Write
	ldi r16, NE2K_RSAR1
	ldi r17, NE2K_TRANSMIT_BUFFER 		; high byte of start address
	rcall NE2K_Write
	; begin DMA write
	ldi r16, NE2K_CR
	ldi r17, NE2K_CR_PAGE0 | NE2K_CR_START | NE2K_CR_DMAWRITE
	rcall NE2K_Write
	ldi r16, NE2K_DATAPORT
	; destination hardware address
	ldi r30,low(NE2K_Peer_MAC_Addr) 	; Load Z register low
	ldi r31,high(NE2K_Peer_MAC_Addr)	; Load Z register high
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	; source hardware address
	ldi r30,low(NE2K_MAC_Addr) 			; Load Z register low
	ldi r31,high(NE2K_MAC_Addr) 		; Load Z register high
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	; "Ethernet" (not 802.3) type 0x0806 (=ARP)
	ldi r17, 0x08
	rcall NE2K_Write
	ldi r17, 0x06
	rcall NE2K_Write
	; hardware type 0x0001
	ldi r17, 0x00
	rcall NE2K_Write
	ldi r17, 0x01
	rcall NE2K_Write
	; protocol type 0x0800
	ldi r17, 0x08
	rcall NE2K_Write
	ldi r17, 0x00
	rcall NE2K_Write
	; hardware size 6
	ldi r17, 6
	rcall NE2K_Write
	; protocol size 4
	ldi r17, 4
	rcall NE2K_Write
	; op 0x0002 (ARP reply)
	ldi r17, 0x00
	rcall NE2K_Write
	ldi r17, 0x02
	rcall NE2K_Write
	; source hardware address
	ldi r30,low(NE2K_MAC_Addr) 			; Load Z register low
	ldi r31,high(NE2K_MAC_Addr) 		; Load Z register high
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	; source ip address
	ldi r30,low(NE2K_IP_Addr) 			; Load Z register low
	ldi r31,high(NE2K_IP_Addr) 			; Load Z register high
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	; target hardware address
	ldi r30,low(NE2K_Peer_MAC_Addr) 	; Load Z register low
	ldi r31,high(NE2K_Peer_MAC_Addr)	; Load Z register high
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	; target ip address
	ldi r30,low(NE2K_Peer_IP_Addr) 		; Load Z register low
	ldi r31,high(NE2K_Peer_IP_Addr) 	; Load Z register high
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	ld r17, Z+
	rcall NE2K_Write
	; 18 bytes of padding
	ldi r17, 0
	rcall NE2K_Write
	rcall NE2K_Write
	rcall NE2K_Write
	rcall NE2K_Write
	rcall NE2K_Write
	rcall NE2K_Write
	rcall NE2K_Write
	rcall NE2K_Write
	rcall NE2K_Write
	rcall NE2K_Write
	rcall NE2K_Write
	rcall NE2K_Write
	rcall NE2K_Write
	rcall NE2K_Write
	rcall NE2K_Write
	rcall NE2K_Write
	rcall NE2K_Write
	rcall NE2K_Write
	; ****
	; ... do i need wait for dma to end??? ...
	; (see PCtoNIC from natsemi demo driver)
	; ****
	; end the DMA transfer
	ldi r16, NE2K_CR
	ldi r17, NE2K_CR_PAGE0 | NE2K_CR_START | NE2K_CR_NODMA
	rcall NE2K_Write
	; how many bytes to send
	ldi r16, NE2K_TBCR0
	ldi r17, 60
	rcall NE2K_Write
	ldi r16, NE2K_TBCR1
	ldi r17, 0
	rcall NE2K_Write
	; starting where
	ldi r16, NE2K_TPSR
	ldi r17, NE2K_TRANSMIT_BUFFER
	rcall NE2K_Write
	; issue transmit command!
	ldi r16, NE2K_CR
	ldi r17, NE2K_CR_PAGE0 | NE2K_CR_START | NE2K_CR_NODMA | NE2K_CR_TRANSMIT
	rcall NE2K_Write
	rjmp ne2k_read_packet_cleanup
ne2k_read_packet_ip2:
	; decode an IP packet, and respond appropriately
	; first process the IP header (Stevens p.34)
	; read version and length
	;--- IP Header structure ------------------------
	; Version (4 bits)
	; IHL (Internet Header Length) (4 bits)
	; Type Of Service (8 bits)
	; Total Length (16 bits)
	; Identification (16 bits)
	; Flags (3 bits) (bit0=reserved =0, bit1=DF (0=May Fragment, 1=Do not fragment), bit2=MF (0=Last fragment, 1=More fragments))
	; Fragment Offset (13 bits)
	; Time To Live (8 bits)
	; Protocol (8 bits)
	; Header Checksum (16 bits)
	; Source Address (32 bits)
	; Destination Address (32 bits)
	; Options (0 to 11 32-bit dwords)
	; Padding (aanvullen met $00, dword aligned)
	;
	; Mogelijke waarden voor het Version veld (4 bits) zijn:
	;   	0                Reserved
	;  	  1-3                Unassigned
	;    	4       IP       Internet Protocol
	;    	5       ST       ST Datagram Mode
	;    	6       SIP      Simple Internet Protocol
	;    	7       TP/IX    TP/IX: The Next Internet
	;    	8       PIP      The P Internet Protocol
	;    	9       TUBA     TUBA
	;	10-14                Unassigned
	;	   15                Reserved
	;
	rcall NE2K_Read 					; version (4 bits) + header length (4 bits)
	mov r20, r17						; store the header length in r20
	andi r20, 0x0f 						; mask out the version part
	andi r17, 0xf0 						; mask out the length part
	ldi r18, 0x40 						; IPv4 is the only version we accept
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	rcall NE2K_Read 					; ignore TOS
	rcall NE2K_Read 					; ignore total length
	rcall NE2K_Read
	rcall NE2K_Read 					; ignore identification number
	rcall NE2K_Read
	rcall NE2K_Read 					; ignore fragmentation stuff
	rcall NE2K_Read
	rcall NE2K_Read 					; ignore TTL
	rcall NE2K_Read 					; read protocol
	mov r19, r17 						; save for later in r19
	rcall NE2K_Read 					; ignore checksum
	rcall NE2K_Read
	; record sender's IP address
	ldi r30,low(NE2K_Peer_IP_Addr) 		; Load Z register low
	ldi r31,high(NE2K_Peer_IP_Addr) 	; Load Z register high
	rcall NE2K_Read
	st Z+, r17
	rcall NE2K_Read
	st Z+, r17
	rcall NE2K_Read
	st Z+, r17
	rcall NE2K_Read
	st Z+, r17
	; compare destination IP address to our own. if its a match, then this packet
	; is for us. otherwise, this belongs to someone else.
	ldi r30,low(NE2K_IP_Addr)			; Load Z register low
	ldi r31,high(NE2K_IP_Addr) 			; Load Z register high
	ld r18, Z+ 							; read first octet of my IP address
	rcall NE2K_Read 					; read first octet of target IP address
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	ld r18, Z+ 							; read next octet of my IP address
	rcall NE2K_Read 					; read next octet of target IP address
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	ld r18, Z+ 							; read next octet of my IP address
	rcall NE2K_Read 					; read next octet of target IP address
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	ld r18, Z+ 							; read next octet of my IP address
	rcall NE2K_Read 					; read next octet of target IP address
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	; fallthrough: the destination IP address is the same as my IP address.goodie!
	; skip over any "options" in the ip header
	subi r20, 5 ; 5 = size of ip header without any options (in 32-bit words)
	ldi r17, 0
ne2k_read_packet_header1:
	cp r20, r17
	breq ne2k_read_packet_header2
	subi r20, 1
	rcall NE2K_Read 					; read 4-byte option field
	rcall NE2K_Read
	rcall NE2K_Read
	rcall NE2K_Read
	rjmp ne2k_read_packet_header1
ne2k_read_packet_header2:
	; we have now advanced the read pointer up to the first byte of
	; the "data" portion of the IP packet
	; ok, now look back at the protocol field and jump to the right
	; code to handle the packet type
	ldi r18, 1 							; icmp
	cp r19, r18
	breq ne2k_read_packet_icmp
	ldi r18, 6 							; tcp
	cp r19, r18
	breq ne2k_read_packet_tcp
	ldi r18, 17 						; udp
	cp r19, r18
	breq ne2k_read_packet_udp
	; fallthrough: unrecognized protocol field (don't expect to get here)
	rjmp ne2k_read_packet_cleanup
ne2k_read_packet_icmp:
	; ... icmp not implemented ...
	;--- ICMP HEADER ------------------------------
	; Type (8 bits)
	; Code (8 bits)
	; Checksum (16 bits)
	; ...de rest van de header is anders per 'Type'/'Code'
	; http://www.faqs.org/rfcs/rfc792.html
	;
	;Type    Name                                    Reference
	;----    -------------------------               ---------
	;  0     Echo Reply                               [RFC792]
	;  1     Unassigned                                  [JBP]
	;  2     Unassigned                                  [JBP]
	;  3     Destination Unreachable                  [RFC792]
	;  4     Source Quench                            [RFC792]
	;  5     Redirect                                 [RFC792]
	;  6     Alternate Host Address                      [JBP]
	;  7     Unassigned                                  [JBP]
	;  8     Echo                                     [RFC792]
	;  9     Router Advertisement                    [RFC1256]
	; 10     Router Selection                        [RFC1256]
	; 11     Time Exceeded                            [RFC792]
	; 12     Parameter Problem                        [RFC792]
	; 13     Timestamp                                [RFC792]
	; 14     Timestamp Reply                          [RFC792]
	; 15     Information Request                      [RFC792]
	; 16     Information Reply                        [RFC792]
	; 17     Address Mask Request                     [RFC950]
	; 18     Address Mask Reply                       [RFC950]
	; 19     Reserved (for Security)                    [Solo]
	; 20-29  Reserved (for Robustness Experiment)        [ZSu]
	; 30     Traceroute                              [RFC1393]
	; 31     Datagram Conversion Error               [RFC1475]
	; 32     Mobile Host Redirect              [David Johnson]
	; 33     IPv6 Where-Are-You                 [Bill Simpson]
	; 34     IPv6 I-Am-Here                     [Bill Simpson]
	; 35     Mobile Registration Request        [Bill Simpson]
	; 36     Mobile Registration Reply          [Bill Simpson]
	; 37-255 Reserved                                    [JBP]
	;
	;Type    Name                                    Reference
	;----    -------------------------               ---------
	;  0     Echo Reply                               [RFC792]
	;        Codes
	;            0  No Code
	;  1     Unassigned                                  [JBP]
	;  2     Unassigned                                  [JBP]
	;  3     Destination Unreachable                  [RFC792]
	;        Codes
	;            0  Net Unreachable
	;            1  Host Unreachable
	;            2  Protocol Unreachable
	;            3  Port Unreachable
	;            4  Fragmentation Needed and Don't Fragment was Set
	;            5  Source Route Failed
	;            6  Destination Network Unknown
	;            7  Destination Host Unknown
	;            8  Source Host Isolated
	;            9  Communication with Destination Network is
	;               Administratively Prohibited
	;           10  Communication with Destination Host is
	;               Administratively Prohibited
	;           11  Destination Network Unreachable for Type of Service
	;           12  Destination Host Unreachable for Type of Service
	;  4     Source Quench                            [RFC792]
	;        Codes
	;            0  No Code
	;  5     Redirect                                 [RFC792]
	;        Codes
	;            0  Redirect Datagram for the Network (or subnet)
	;            1  Redirect Datagram for the Host
	;            2  Redirect Datagram for the Type of Service and Network
	;            3  Redirect Datagram for the Type of Service and Host
	;  6     Alternate Host Address                      [JBP]
	;        Codes
	;            0  Alternate Address for Host
	;  7     Unassigned                                  [JBP]
	;  8     Echo                                     [RFC792]
	;        Codes
	;            0  No Code
	;  9     Router Advertisement                    [RFC1256]
	;        Codes
	;            0  No Code
	; 10     Router Selection                        [RFC1256]
	;        Codes
	;            0  No Code
	; 11     Time Exceeded                            [RFC792]
	;        Codes
	;            0  Time to Live exceeded in Transit
	;            1  Fragment Reassembly Time Exceeded
	; 12     Parameter Problem                        [RFC792]
	;        Codes
	;            0  Pointer indicates the error
	;            1  Missing a Required Option        [RFC1108]
	;            2  Bad Length
	; 13     Timestamp                                [RFC792]
	;        Codes
	;            0  No Code
	; 14     Timestamp Reply                          [RFC792]
	;        Codes
	;            0  No Code
	; 15     Information Request                      [RFC792]
	;        Codes
	;            0  No Code
	; 16     Information Reply                        [RFC792]
	;        Codes
	;            0  No Code
	; 17     Address Mask Request                     [RFC950]
	;        Codes
	;            0  No Code
	; 18     Address Mask Reply                       [RFC950]
	;        Codes
	;            0  No Code
	; 19     Reserved (for Security)                    [Solo]
	; 20-29  Reserved (for Robustness Experiment)        [ZSu]
	; 30     Traceroute                              [RFC1393]
	; 31     Datagram Conversion Error               [RFC1475]
	; 32     Mobile Host Redirect              [David Johnson]
	; 33     IPv6 Where-Are-You                 [Bill Simpson]
	; 34     IPv6 I-Am-Here                     [Bill Simpson]
	; 35     Mobile Registration Request        [Bill Simpson]
	; 36     Mobile Registration Reply          [Bill Simpson]
	;
	rcall	LCD_Clear
	rcall	LCD_Home
	ldi		ZL, low(txtICMP)
	ldi		ZH, high(txtICMP)
	rcall	LCD_Print
;*	ldi r16, 0
;*	ldi r17, 0
;*	rcall move_cursor
;*	ldi r16, 'i'
;*	rcall print_to_lcd
;*	ldi r16, 'c'
;*	rcall print_to_lcd
;*	ldi r16, 'm'
;*	rcall print_to_lcd
;*	ldi r16, 'p'
;*	rcall print_to_lcd
;*	ldi r16, '!'
;*	rcall print_to_lcd
	ldi r16, NE2K_DATAPORT
	rjmp ne2k_read_packet_cleanup
ne2k_read_packet_tcp:
	; ... tcp not implemented ...
	;
	; Source Port (16 bits)
	; Destination Port (16 bits)
	; Sequence Number (32 bits)
	; Acknowledgement Number (32 bits)
	; Data Offset (4 bits)
	; Reserved (6 bits)
	; Control Bits (6 bits)
	; Window (16 bits)
	; Checksum (16 bits)
	; Urgent Pointer (16 bits)
	; Options (24 bits)
	; Padding (resterende bits op 0, dword aligned)
	;
	; Data Offset:
	;	Het aantal 32-bit dwords in de header
	; Control Bits:
	;	URG	Urgent Pointer (1=Urgent Pointer wordt gebruikt, 0=niet gebruikt)
	;	ACK	Acknowledgement Number (1=gebruikt, 0=niet gebruikt)
	;	PSH	Initieert een Push function
	;	RST	Forceert een Reset van de connectie
	;	SYN	Synchroniseert sequencing counters voor de connectie. 
	;		Als dit bit gezet is dan verzoekt een segment het openen van een connectie
	;	FIN	Geen verdere data. Sluit de connectie.
	;
	; zie: blz. 173 MS TCP/IP boek. (RFC793)
	;
	rcall	LCD_Clear
	rcall	LCD_Home
	ldi		ZL, low(txtTCP)
	ldi		ZH, high(txtTCP)
	rcall	LCD_Print
;*	ldi r16, 0
;*	ldi r17, 0
;*	rcall move_cursor
;*	ldi r16, 't'
;*	rcall print_to_lcd
;*	ldi r16, 'c'
;*	rcall print_to_lcd
;*	ldi r16, 'p'
;*	rcall print_to_lcd
;*	ldi r16, '!'
;*	rcall print_to_lcd
	ldi r16, NE2K_DATAPORT
	rjmp ne2k_read_packet_cleanup
ne2k_read_packet_udp:
	;--- UDP HEADER -----------------------------
	; Source Port (16 bits)
	; Destination Port (16 bits)
	; Length (incl. header+data) (16 bits)
	; Checksum (16 bits)
	rcall NE2K_Read 					; ignore source portnumber
	rcall NE2K_Read
	rcall NE2K_Read 					; test destination port number
	ldi r18, high(NE2K_LISTEN_PORT)
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	rcall NE2K_Read
	ldi r18, low(NE2K_LISTEN_PORT)
	cpse r17, r18
	rjmp ne2k_read_packet_cleanup
	rcall NE2K_Read 					; udp length into Z-register
	mov		ZL, r17
	rcall NE2K_Read
	mov		ZH, r17
	rcall NE2K_Read 					; ignore udp checksum
	rcall NE2K_Read

	; het Z-register bevat de lengte van het UDP-packet incl. header & data.
	; Bepaal de lengte van de data in het packet.
	sbiw	ZL, 8 ; header lengte
DisplayUDPPacketData:
	ldi r16, NE2K_DATAPORT				; read a byte from the packet
	rcall NE2K_Read
	mov temp, r17
	rcall	LCD_LinePrintChar
	sbiw	ZL, 1						; volgende data byte afbeelden
	brne	DisplayUDPPacketData
;*	; now we're finally at the interesting part - the text string to print
;*	; onto the LCD screen.
;*	ldi r18, 255 ; start at row #-1
;*ne2k_read_packet_printloop1:
;*	inc r18 ; go to next row
;*	cpi r18, 4 ; if we've moved below the end of the screen...
;*	breq ne2k_read_packet_printloop3 ; ...exit the loop
;*	ldi r19, 0 ; go back to column #0
;*	mov r16, r18
;*	mov r17, r19
;*	rcall move_cursor ; issue carriage return instruction
;*ne2k_read_packet_printloop2:
;*	inc r19 ; increment column pointer
;*	cpi r19, 21 ; if we've moved off the right of the screen...
;*	breq ne2k_read_packet_printloop1 ; ...do a carriage return
;*	ldi r16, NE2K_DATAPORT ; read a byte from the packet
;*	rcall NE2K_Read
;*	mov r16, r17
;*	rcall print_to_lcd ; print it on the screen
;*	rjmp ne2k_read_packet_printloop2 ; loop

ne2k_read_packet_printloop3:
	; voila - the data is on the lcd screen. ignore whatever may be left.
	rjmp ne2k_read_packet_cleanup
ne2k_read_packet_cleanup:
	; end (abort) the DMA transfer
	ldi r16, NE2K_CR
	ldi r17, NE2K_CR_PAGE0 | NE2K_CR_START | NE2K_CR_NODMA
	rcall NE2K_Write
	; update the BNRY (recive buffer ring boundary) pointer.
	; r13 = next packet pointer from NIC packet header.
	; note: there seem to be 2 ways of setting this pointer. you can
	; set it to one less than the next packet pointer, or equal
	; to the next packet pointer. it seems simpler to make it equal -
	; i'm not sure why you would want to do it the other way.
	ldi r16, NE2K_BNRY
	mov r17, r13; next packet pointer
	rcall NE2K_Write
	; LED even laten knipperen
	sbi		LED_PORT, LED_PIN			; LED aan
	rcall delay100ms
	cbi		LED_PORT, LED_PIN			; LED uit
ne2k_read_packet_end:
	pop r31
	pop r30
	pop r20
	pop r19
	pop r18
	pop r17
	pop r16
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	ret


;---------------------------------------
;--- NE2000 Establish IP-Address
;---------------------------------------
NE2K_Establish_IP_Address:
	; stick our hardcoded IP address into the proper spot in the microcontroller's RAM
	; TBD: replace this routine with a DHCP or BOOTP client!
	;
	; DHCP gebruikt UDP voor transport van packets.
	; DHCP server port = 67 (zenden naar deze poort)
	; DHCP client port = 68 (ontvangen over deze poort)
	; ....
	;
	push r16
	push r30
	push r31
	ldi r30,low(NE2K_IP_Addr) 			; Load Z register low
	ldi r31,high(NE2K_IP_Addr) 			; Load Z register high
	ldi r16, NE2K_IP_OCTET_1
	st Z+, r16
	ldi r16, NE2K_IP_OCTET_2
	st Z+, r16
	ldi r16, NE2K_IP_OCTET_3
	st Z+, r16
	ldi r16, NE2K_IP_OCTET_4
	st Z+, r16
	pop r31
	pop r30
	pop r16
	ret










;---------------------------------------
;--- LCD
;---------------------------------------
Display_MAC_Address:
	push	temp
	push	temp2
	push	temp3
	push	temp4	
	ldi		temp2, 0
	ldi		temp3, 0
	rcall	LCD_SetCursorXY
	ldi		temp4, 5
	ldi		ZL, low(NE2K_MAC_Addr)
	ldi		ZH, high(NE2K_MAC_Addr)
MAC_Next:
	ld		temp, Z+
	rcall	LCD_HexByte
	ldi		temp, ':'
	rcall	LCD_LinePrintChar
	dec		temp4
	brne	MAC_Next
	ld		temp, Z+
	rcall	LCD_HexByte
	pop		temp4
	pop		temp3
	pop		temp2
	pop		temp
	ret


;---------------------------------------
Display_IP_Address:
	push	temp
	push	temp2
	push	temp3
	push	temp4	
	ldi		temp2, 0
	ldi		temp3, 1
	rcall	LCD_SetCursorXY
	ldi		temp4, 3
	ldi		ZL, low(NE2K_IP_Addr)
	ldi		ZH, high(NE2K_IP_Addr)
IP_Next:
	ld		temp, Z+
	rcall	LCD_DecByte ;LCD_HexByte
	ldi		temp, '.'
	rcall	LCD_LinePrintChar
	dec		temp4
	brne	IP_Next
	ld		temp, Z+
	rcall	LCD_DecByte ;LCD_HexByte
	pop		temp4
	pop		temp3
	pop		temp2
	pop		temp
	ret

;--- AVR ATMega32 applicatie
.include "m32def.inc"

;-----------------------------------------------------------------------------------
;--- AVR ATMega32 Interrupt "vector" tabel
;-----------------------------------------------------------------------------------
.CSEG
.org $0000		; RESET Vector Address
				rjmp RESET
.org INT0addr	; External Interrupt0 Vector Address
				reti
.org INT1addr	; External Interrupt1 Vector Address
				reti
.org INT2addr	; External Interrupt2 Vector Address
				reti
.org OC2addr	; Output Compare2 Interrupt Vector Address
				reti
.org OVF2addr	; Overflow2 Interrupt Vector Address
				reti
.org ICP1addr	; Input Capture1 Interrupt Vector Address
				reti
.org OC1Aaddr	; Output Compare1A Interrupt Vector Address
				reti
.org OC1Baddr	; Output Compare1B Interrupt Vector Address
				reti
.org OVF1addr	; Overflow1 Interrupt Vector Address
				reti
.org OC0addr	; Output Compare0 Interrupt Vector Address
				reti
.org OVF0addr	; Overflow0 Interrupt Vector Address
				reti
.org SPIaddr	; SPI Interrupt Vector Address
				reti
.org URXCaddr	; USART Receive Complete Interrupt Vector Address
				reti
.org UDREaddr	; USART Data Register Empty Interrupt Vector Address
				reti
.org UTXCaddr	; USART Transmit Complete Interrupt Vector Address
				reti
.org ADCCaddr	; ADC Interrupt Vector Address
				reti
.org ERDYaddr	; EEPROM Interrupt Vector Address
				reti
.org ACIaddr	; Analog Comparator Interrupt Vector Address
				reti
.org TWSIaddr   ; Irq. vector address for Two-Wire Interface
				reti
.org SPMRaddr	; Store Program Memory Ready Interrupt Vector Address
				reti
;-----------------------------------------------------------------------------------



;-----------------------------------------------------------------------------------
;--- TWI definities
.include "M32_TWI.asm"


;-----------------------------------------------------------------------------------
My_BufferWrite:
	TWI_Buffer_Write R20
	ret

;-----------------------------------------------------------------------------------
My_Message:
	ldi		ZL, low(Message)
	ldi		ZH, high(Message)
do:	lpm
	mov		R20, R0
	cpi		R20, '$'
	breq	done
	adiw	ZL, 1
	push	ZL
	push	ZH
	rcall	My_BufferWrite
	pop		ZH
	pop		ZL
	rjmp	do
done:
	ret
Message: .db "AVR-team UJE $"





;-----------------------------------------------------------------------------------
RESET:
	Initialize_TWI						; TWI hardware poort/pinnen & I/O-buffers instellen
	
	; de TWI prescale en bitrate instellen
	Set_TWI_Clock 7372800, 100000		; CK=7372800Hz, SCL=100KHz

	; een slave-adres instellen voor deze master (wordt niet gebruikt in deze opstelling)
	ldi		R20, $20
	Set_TWI_SlaveAddress R20

	; een tellertje om af te beelden op LCD
	clr		R21

main_loop:
	;--- wat data versturen naar slave met adres $30: "UJE AVR team 255"
	; eerst de bytes in de buffer plaatsen..(niet meer dan de buffer-grootte)
	;* Tekst
	rcall	My_Message
	;* LCD CMD Print Decimaal
	ldi		R20, $07
	rcall	My_BufferWrite
	mov		R20, R21
	rcall	My_BufferWrite
	ldi		R20, $00
	rcall	My_BufferWrite
	;* CrLf
	ldi		R20, $0D
	rcall	My_BufferWrite
	ldi		R20, $0A
	rcall	My_BufferWrite

	; dan de data versturen naar adres $30
	ldi		R20, $30
	TWI_Transmit R20

	;--- een tijdje wachten -----------
	; 255*255*255=255^3=16581375 timerticks
	; 255^3/7372800=2.24899 seconden
	clr		R17
	clr		R18
	clr		R19
w1:	dec		R19
	brne	w1
	dec		R18
	brne	w1
	dec		R17
	brne	w1
	;----------------------------------

	rjmp	main_loop



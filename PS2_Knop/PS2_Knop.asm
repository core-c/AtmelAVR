;*************************************************************************************
;***
;***  Een AT-Keyboard PS/2 Knop implementatie.
;***
;*************************************************************************************

;--- Include files ---------------------
.include "8535def.inc"					; AVR AT90S8535 constanten




;--- CONSTANTEN -----------------------\
.equ CK 	= 7372800					; AVR clock frequentie (VERPLICHT hier te definieren)
;--------------------------------------/


;--- Compiler Directives --------------\  Geef aan welke units men wil gebruiken:
.equ Link_AVR_Core				= 1		; "AVR_Core.asm"		altijd ingelinkt.
.equ Link_AVR_16				= 0		; "AVR_16.asm"
.equ Link_AVR_Delay				= 1		; "AVR_Delay.asm"
.equ Link_AVR_Buffer			= 1		; "AVR_Buffer.asm"
.equ Link_AVR_LED				= 0		; "AVR_LED.asm"
.equ Link_8535_EEPROM			= 0		; "8535_EEPROM.asm"
.equ Link_8535_AC				= 0		; "8535_AC.asm"
.equ Link_8535_ADC				= 0		; "8535_ADC.asm"
.equ Link_8535_Timer0			= 1		; "8535_Timer0.asm"
.equ Link_8535_Timer1			= 0		; "8535_Timer1.asm"
.equ Link_8535_Timer2			= 0		; "8535_Timer2.asm"
.equ Link_8535_Timers			= 0		; "8535_Timers.asm"		gebruikt: 8535_Timer0,8535_Timer1 & 8535_Timer2
.equ Link_8535_UART				= 0		; "8535_UART.asm"
.equ Link_LCD_HD44780			= 0		; "LCD_HD44780.asm"		gebruikt: AVR_Delay
.equ Link_AVR_String			= 0		; "AVR_String.asm"		gebruikt: AVR_16
										;						zelf nog inlinken: 8535_UART en/of LCD_HD44780
;---------------------------------------
;included "LinkedUnits.asm" regelt de rest..:-)
;--------------------------------------/







;--- REGISTER ALIASSEN ----------------\
.def BitCount					= R1	; de teller voor het aantal te verwerken bits
.def tmp						= R16	; tijdelijk register #0
.def tmp1						= R17	; tijdelijk register #1
.def DownUp						= R18	; knop INgedrukt, of UITgedrukt ($00 of $FF)
.def DataByte					= R19	; de ontvangen byte van de host
.def Parity						= R20	; de berekende pariteit
;--------------------------------------/



.CSEG									;--- Het begin van het CODE-segment ----
;--- De AVR-AT90S8535 vector-tabel ----\
.org $0000								; Het begin van de vector-tabel op adres 0 van het RAM
	rjmp RESET							; Reset Handler
	rjmp Button_Interrupt				; External Interrupt0 Vector Address
	reti								; External Interrupt1 Vector Address
	reti								; Timer2 compare match Vector Address
	reti								; Timer2 overflow Vector Address
	reti								; Timer1 Input Capture Vector Address
	reti								; Timer1 Output Compare A Interrupt Vector Address
	reti								; Timer1 Output Compare B Interrupt Vector Address
	reti								; Overflow1 Interrupt Vector Address
	reti								; Overflow0 Interrupt Vector Address
	reti								; SPI Interrupt Vector Address
	reti								; UART Receive Complete Interrupt Vector Address
	reti								; UART Data Register Empty Interrupt Vector Address
	reti								; UART Transmit Complete Interrupt Vector Address
	reti								; ADC Conversion Complete Interrupt Vector Address
	reti								; EEPROM Write Complete Interrupt Vector Address
	reti								; Analog Comparator Interrupt Vector Address
;--------------------------------------/


;--- Ron's Macro's & Subroutines ------\
.include "LinkedUnits.asm"				; interne compiler-directives verwerking en unit-linking
;--------------------------------------/

.include "Keyboard.asm"					; PS/2 toetsenbord routine's












RESET:
	cli										; interrupts uitschakelen
	StackPointer_Initialize					; stack-pointer instellen op einde RAM

	rcall	KBD_Initialize					; de knop initialiseren

	sei										; interrupts inschakelen

MainLoop:
	; controleer de bus-bezetting.
	; Als de host/PC een commando wil zenden, dan zal deze de bus bezetten.
	; Indien een bus-bezetting wordt geconstateerd, dan het commando ontvangen en verwerken.

	;---------------------------------------
	;   Check_The_Bus(onContinue:label)
	Check_The_Bus MainLoop
	
	;---------------------------------------
	; Ontvang een byte van de host/PC
	;   GetByte(data:register; onError:label)
	GetByte DataByte, Host_Cancelled

	;---------------------------------------
	; Verwerk het host-commando
	;   Process_Command;(HostCommand:register)
	Process_Command DataByte

	; blijft 'ie nou hangen.? ;)....
	rjmp MainLoop




;-------------------------------------------
;--- de host breekt zijn verzending af
;-------------------------------------------
Host_Cancelled:
	rjmp MainLoop

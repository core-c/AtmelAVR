;---------------------------------------------------------------------------------
;---
;---  EEPROM constanten en macro's						Ron Driessen
;---  AVR AT90S8535										2005
;---
;---------------------------------------------------------------------------------




;---------------------------------------------------------------------------------
;--- EECR	- EEPROM Control Register
;---
;---	bit  7        6        5        4        3        2        1        0
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	|        |        |        |        |  EERIE |  EEMWE |  EEWE  |  EERE  |
;---	+--------+--------+--------+--------+--------+--------+--------+--------+
;---	Bits 7..4						Reserved Bits
;---	Bit 3		EERIE				EEPROM Ready Interrupt Enable
;---	Bit 2		EEMWE				EEPROM Master Write Enable
;---	Bit 1		EEWE				EEPROM Write Enable
;---	Bit 0		EERE				EEPROM Read Enable
;---
;---------------------------------------------------------------------------------


;--------------------------------------------
;--- EEPROM Ready Interrupt Enable
;--------------------------------------------
.equ EEPROM_INTERRUPTENABLE_READY	= (1<<EERIE)





;---------------------------------------------------------------------------------
;--- Macro's
;---------------------------------------------------------------------------------

;--------------------------------------------
;--- Naam:			Disable_Interrupt_EEPROMReady
;--- Beschrijving:	Interrupt uitschakelen voor EEPROM-Ready
;--------------------------------------------
.MACRO Disable_Interrupt_EEPROMReady
	cbi		EECR, EERIE
.ENDMACRO

;--------------------------------------------
;--- Naam:			Enable_Interrupt_EEPROMReady
;--- Beschrijving:	Interrupt inschakelen voor EEPROM-Ready
;--------------------------------------------
.MACRO Enable_Interrupt_EEPROMReady
	sbi		EECR, EERIE
.ENDMACRO



;--------------------------------------------
;--- Naam:			EEPROM_Read
;--- Beschrijving:	Een byte uit EEPROM-geheugen lezen
;---				invoer: registers "AddressH" & "AddressL" bevatten het adres in EEPROM-geheugen
;---				uitvoer: register "Value" bevat de gelezen byte
;--------------------------------------------
.MACRO EEPROM_Read;(Value, AddressH,AddressL:register)
	; Write-Enable bit moet eerst 0 zijn.
	; ..er mag nl. geen schrijf-actie bezig zijn.
_0:	sbic	EECR, EEWE
	rjmp	_0
	; Het adres instellen in het EEPROM Address Register.
	; 512 Bytes = > 9 bits adres (b8-0).
	out		EEARL, @2
	out		EEARH, @1
	; Read-Enable signaal geven
	sbi		EECR, EERE
	; wacht tot het EERE bit is gewist
_1:	sbic	EECR, EERE
	rjmp	_1
	; lees de byte
	in		@0, EEDR
.ENDMACRO

;--------------------------------------------
;--- Naam:			EEPROM_Write
;--- Beschrijving:	Een byte naar EEPROM-geheugen schrijven
;---				invoer:	registers "AddressH" & "AddressL" bevatten het adres in EEPROM-geheugen
;---						register "Value" bevat de te schrijven byte-waarde
;--------------------------------------------
.MACRO EEPROM_Write;(AddressH,AddressL, Value: register)
	; Write-Enable bit moet eerst 0 zijn.
	; ..er mag nl. geen schrijf-actie bezig zijn.
_0:	sbic	EECR, EEWE
	rjmp	_0
	; Het adres instellen in het EEPROM Address Register.
	; 512 Bytes = > 9 bits adres (b8-0).
	out		EEARL, @1
	out		EEARH, @0
	; Data in register "Value" schrijven naar het EEPROM Data-Register
	out		EEDR, @2
	; Globale interrupts uitschakelen
	cli
	; Master-Write-Enable signaal geven
	sbi		EECR, EEMWE
	; Write-Enable signaal geven
	sbi		EECR, EEWE
	; Globale interrupts inschakelen
	sei
.ENDMACRO

;-------------------------------------------------------------------------------
;
; Commando's voor aansturing van de I2C-Master hebben hetvolgende formaat:
;	offset 0:	1 byte		Aantal data bytes in het command-record (X)
;	offset 1:	1 byte		SlaveAddress (==0 als het een CMD voor de master betreft)
;	offset 2:	X bytes		Data voor de betreffende I2C-Slave
;
; Een commando is dus altijd tenminste 3 bytes in lengte.
; Als een SlaveAddress met de waarde $00 is opgegeven, betreft het een commando
; wat enkel voor de master is bestemd (bv. de bus-snelheid verhogen).
; Een lijst met alle Master-Commands:
;	$01, $00, CharFindSlaves		Zoek slaves op de I2C-bus
;	$01, $00, CharBusSpeedDown		I2C-Bus snelheid verlagen
;	$01, $00, CharBusSpeedUp		I2C-Bus snelheid verhogen
;
;-------------------------------------------------------------------------------


;-------------------------------------------
;--- Verwerk ontvangen commando's voor de master
; input: bytes in RS232_IN_Buffer
; output: bytes in TWI_OUT_Buffer
;------------------------------------------\
Process_Master_Commands:
	push	R16
	push	R21								; SlaveAddress byte
	push	R22								; aantal data bytes in commando-record
	; Bytes ontvangen in de RS232_IN_Buffer?
	lds		R22, RS232_IN_BytesInBuffer		; R22 = aantal bytes nu in buffer
	cpi		R22, 0							; 0 bytes in de buffer
	breq	Done_Master_Commands			; ?
	; De eerste byte bevat het aantal data-bytes dat volgt op de CMD-"header"
	rcall	PeekByteFrom_RS232_IN_Buffer	; Peek uit de buffer het aantal data-bytes in het CMD
	; verwerk dit binnenkomende CMD pas als alle bytes ervan binnen zijn..
	inc		R16								; aantal data-bytes + CMD-byte
	inc		R16								; + Address-byte = length(CMD-record)
	; Is het hele CMD nu binnen?
	cp		R22, R16
	brlo	Done_Master_Commands			; nog even wachten op ontvangst van meer data..
	; Nu geldt: Er is een compleet CMD binnen in de buffer.
	; Lees en verwerk het CMD.

	; Lees het aantal data-bytes in het CMD-record
	rcall	LoadByteFrom_RS232_IN_Buffer	; laad de waarde met het aantal data-bytes in dit commando
	brcs	Done_Master_Commands			; fout?
	mov		R22, R16
	; Lees de adres-byte
	rcall	LoadByteFrom_RS232_IN_Buffer	; laad de SlaveAddress-byte (==MasterAddress nu)
	brcs	Done_Master_Commands			; fout?
	mov		TWI_Address, R16
	; bekijk of het een commando voor de master zelf betreft..
	cpi		TWI_Address, MasterAddress
	brne	ExecSlaveCommand				; nee: iets voor een slave..
	; ja: een commando voor de master; Verwerk het nu..
;ExecMasterCommand:
	; Lees het commando voor de master..
	rcall	LoadByteFrom_RS232_IN_Buffer	; laad de commando data-byte
	brcs	Done_Master_Commands			; fout?
CMD_FindSlaves:
	cpi		R16, CharFindSlaves
	brne	CMD_BusSpeed_Down
	rcall	TWI_FindSlaves					; slaves zoeken
	rjmp	Done_Master_Commands
CMD_BusSpeed_Down:
	cpi		R16, CharBusSpeedDown
	brne	CMD_BusSpeed_Up
	rcall	BusSpeed_Down					; bus-snelheid omlaag
	rjmp	Done_Master_Commands
CMD_BusSpeed_Up:
	cpi		R16, CharBusSpeedUp
	brne	Done_Master_Commands
	rcall	BusSpeed_Up						; bus-snelheid omhoog
	rjmp	Done_Master_Commands

ExecSlaveCommand:
	; Er is een commando voor een slave ontvangen..
	; R22 bevat het aantal data bytes
	rcall	TWI_WriteToSlave				; R22 data-bytes schrijven naar de slave..
Done_Master_Commands:


	;--- Eventueel (via I2C) ontvangen bytes naar de COM-poort doorsturen voor afbeelden op PC..
Check_Input:
	; Is er input in de invoer-buffer?
	rcall	LoadByteFrom_TWI_IN_Buffer
	brcs	Done_Input						; buffer lezen was mislukt als de carry-flag gezet is
	; register R16 bevat de uit de invoer-buffer gelezen byte
	; De byte gelezen van de I2C-slave nu schrijven naar de RS232-poort
	rcall	UART_transmit
	rjmp	Check_Input						; meer bytes te lezen?
Done_Input:

	pop		R22
	pop		R21
	pop		R16
	ret
;------------------------------------------/

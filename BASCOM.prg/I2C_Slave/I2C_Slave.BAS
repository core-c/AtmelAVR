Rem ;**** A P P L I C A T I O N   N O T E   A V R 3 0 2 ************************

$regfile = "8535def.dat"
$crystal = 7372800                                          ''De clock-frequentie van onze AT90S8535 I2C slave

Rem ;**** Global TWI Constants ****
Const Devadr = &H30                                         ''Slave device address
Const Devadrm = &H7F                                        ''Slave multi address mask
Const Pinmask = &H14                                        ''<=> (1<<PD4)+(1<<PD2)

Rem ;*** mijn eigen variabelen
Dim Carryflag As Bit                                        '' Een variabele als
Dim Carryflag2 As Bit                                       ''... ik weet t anders ook niet ...
Dim Slaveaddressed As Bit                                   ''1=slave is geadresseerd, 0=niet geadresseerd
Dim Slaveread As Bit                                        ''1=read, 0=write
Dim Temp As Byte
Dim Etemp As Byte
Dim Temp2 As Byte

Rem ;**** Global Register Variables ****
Rem twidata Alias R18                                        '' TWI data register
Rem Twiadr Alias R19                                         '' TWI address and direction register
Rem Twistat Alias R20                                        '' TWI temporary SREG storage
Dim Twidata As Byte
Dim Twiadr As Byte
''Dim Twistat As Byte   ''TWIStat is niet nodig, want bascom bewaart het SREG zelf al.


Dim Onthouden As Byte                                       '' deze waarde teruggeven als de I2C-master om een (slave)schrijf-actie vraagt



Rem ;**** Interrupt Vectors ****
''on RESET Main_Program                                      '' Reset handle
On Int0 Int0_interrupt_handler                              '' INT0 handle
On Ovf0 Ovf0_interrupt_handler                              '' Timer 0 overflow handle




Rem ;***************************************************************************
Rem ;*
Rem ;* FUNCTION
Rem ;* TWI_init
Rem ;*
Rem ;* DESCRIPTION
Rem ;* Initialization of interrupts and port used by the TWI interface
Rem ;* and waits for the first start condition.
Rem ;*
Rem ;* USAGE
Rem ;* Jump to this code directly after a reset.
Rem ;*
Rem ;* RETURN
Rem ;* none
Rem ;*
Rem ;* NOTE
Rem ;* Code size can be reduced by 12 instructions (words) if no transfer
Rem ;* is started on the TWI bus (bus free), before the interrupt
Rem ;* initialization is finished. If this can be ensured, remove the
Rem ;* "Wait for TWI Start Condition" part and replace it with a "sei"
Rem ;* instruction.
Rem ;*
Rem ;***************************************************************************
''Reset:          '' De RESET-vector ingang (begin van het BASCOM-prg.)
Twi_init:
Rem ;**** PORT Initialization ****

Rem ; Initialize PD2 (INT0) for open colector operation (SDA in/out)
Rem ; Initialize PD4 (T0) for open colector operation (SCL in/out)
   ''Ddrd =(0 << Ddd4) +(0 << Ddd2)
   ''Portd =(0 << Pd4) +(0 << Pd2)
   Config Portd = &B11101011                                ''pin D2 & D4 als Input
   Portd.4 = 0                                              '' TRI-State inschakelen
   Portd.2 = 0                                              '' TRI-State


Rem ;**** Interrupt Initialization ****

Rem ; Set INT0 to generate an interrupt on falling edge
   ''Mcucr =(1 << Isc01) +(0 << Isc00)
   Config Int0 = Falling
Rem ; Enable INT0
   ''Gimsk =(1 << Int0)
Rem ; Set clock to count on falling edge of T0
   ''Tccr0 =(1 << Cs02) +(1 << Cs01) +(0 << Cs00)
   Config Timer0 = Counter , Edge = Falling

   Enable Interrupts


Rem ;***************************************************
Rem ;* Wait for TWI Start Condition (13 intstructions) *
Rem ;***************************************************
Do_start_w:                                                 '' Do
   Do
      Temp = Pind                                           ''    sample SDA & SCL
      Temp = Temp Xor &HFF                                  ''   invert
      Temp = Temp And Pinmask                               '' mask SDA and SCL
   Loop Until Temp <> 0                                     '' while (!(SDA && SCL))

   Temp = Pind And Pinmask                                  '' sample SDA & SCL

Do_start_w2:                                                '' Do
   Etemp = Pind And Pinmask                                 '' new sample SDA & SCL
   While Etemp = Temp                                       '' while no change
      Etemp = Pind And Pinmask                              '' new sample SDA & SCL
   Wend
   If Etemp.2 <> 0 Then                                     '' if SDA no changed to low
      Goto Do_start_w                                       '' Repeat
   End If

   ''rcall TWI_get_adr ; call(!) interrupt handle (New transfer)
   Gosub Twi_get_adr


Rem ;***************************************************************************
Rem ;*
Rem ;* PROGRAM
Rem ;* main - Test of TWI slave implementation
Rem ;*
Rem ;***************************************************************************

Main:
   Goto Main                                                ''  Loop Forever

End

















Rem ;***************************************************************************
Rem ;*
Rem ;* INTERRUPT
Rem ;* EXT_INT0 / TWI_wakeup
Rem ;*
Rem ;* DESCRIPTION
Rem ;* Detects the start condition and handles the data transfer on
Rem ;* the TWI bus.
Rem ;*
Rem ;* Received data is stored in the r0 register and r0 is transmitted
Rem ;* during a master read transfer.
Rem ;*
Rem ;* NOTE
Rem ;* This interrupt code, in some cases, jumps to code parts in the
Rem ;* TIM0_OVF / TWI_skip section to reduce code size.
Rem ;*
Rem ;***************************************************************************

Int0_interrupt_handler:                                     '' INT0 handle
''   Twistat = Sreg                                           '' store SREG


Rem ;*************************
Rem ;* Get TWI Slave Address *
Rem ;*************************
Twi_get_adr:
   Twiadr = 1                                               '' initialize address register
   Bitwait Pind.4 , Reset                                   '' wait for SCL low
   Goto First_ga

Do_ga:
   Bitwait Pind.4 , Reset                                   '' wait for SCL low

   Temp = Twiadr And Devadrm
   If Temp = Devadr Then
      Slaveaddressed = 1
   Else
      Slaveaddressed = 0
   End If

First_ga:
   '' carry-flag op 1
   Carryflag = 1
   Bitwait Pind.4 , Set                                     '' wait for SCL high
   If Pind.2 = 0 Then                                       '' if SDA low
      '' carry-flag wissen
      Carryflag = 0
   End If

   Carryflag2 = Twiadr.7                                    '' rol TWIadr (bit 7 in carry)
   Shift Twiadr , Left , 1                                  '' "   "      (1 naar links schuiven)
   Twiadr = Twiadr Or Carryflag                             '' "   "      (carry naar bit 0)
   Carryflag = Carryflag2                                   '' "   "

   If Carryflag = 0 Then
      Goto Do_ga
   End If

   Bitwait Pind.4 , Reset                                   '' wait for SCL low


Rem ;**** Check Address ****
   If Slaveaddressed = 1 Then                               ''; if T flag set (device addressed)
      Goto Twi_adr_ack                                      ''acknowledge address
   Else
      Goto Twi_adr_miss                                     ''goto address miss handle
   End If



Rem ;**** Acknowledge Address ****
Twi_adr_ack:
   Ddrd.2 = 1                                               ''assert acknowledge on SDA
   Bitwait Pind.4 , Set                                     '' wait for SCL high



Rem ;**** Check Transfer Direction ****
   Slaveread = Twiadr.0
   Shift Twiadr , Right , 1
   If Slaveread = 0 Then
      Goto Twi_master_write
   End If



Rem ;*******************************
Rem ;* Transmit Data (master read) *
Rem ;*******************************
Twi_master_read:

Rem ;**** Load Data (handle outgoing data) ****

Rem ;! INSERT USER CODE HERE !
Rem ;!NOTE! If the user code is more than ONE instruction then wait
Rem ; states MUST be inserted as shown in description.

   Twidata = Onthouden                                      ''insert data in "serial" register (user code example)
   Carryflag = 1

   Carryflag2 = Twidata.7                                   '' rol TWIdata (bit 7 in carry)
   Shift Twidata , Left , 1                                 '' "   "      (1 naar links schuiven)
   Twidata = Twidata Or Carryflag                           '' "   "      (carry naar bit 0)
   Carryflag = Carryflag2                                   '' "   "

   Bitwait Pind.4 , Reset                                   '' wait for SCL low



Rem ;**** Transmitt data ****
   If Carryflag = 1 Then                                    '' if current data bit high
      Ddrd.2 = 0                                            '' release SDA
   Else
      Ddrd.2 = 1                                            '' force SDA
   End If

                                                            ''If Data Register Not Empty
   Carryflag = Twidata.7                                    '' lsl TWIdata (bit 7 in carry)
   Shift Twidata , Left , 1                                 '' "   "      (1 naar links schuiven)

Loop_mr:
   Bitwait Pind.4 , Set                                     '' wait for SCL high
   Bitwait Pind.4 , Reset                                   '' wait for SCL low

   If Carryflag = 1 Then                                    '' if current data bit high
      Ddrd.2 = 0                                            '' release SDA

      Carryflag = Twidata.7                                 '' lsl TWIdata (bit 7 in carry)
      Shift Twidata , Left , 1                              '' "   "      (1 naar links schuiven)

      If Twidata <> 0 Then                                  '' if data register not empty
         Goto Loop_mr
      Else
         Goto Done_mr
      End If
   Else
      Ddrd.2 = 1                                            '' force SDA

      If Twidata <> 0 Then                                  '' if data register not empty
         Goto Loop_mr
      End If
   End If

Done_mr:
   Bitwait Pind.4 , Set                                     '' wait for SCL high
   Bitwait Pind.4 , Reset                                   '' wait for SCL low
   Ddrd.2 = 0                                               '' release SDA



Rem ;**** Read Acknowledge from Master ****
   Bitwait Pind.4 , Set                                     '' wait for SCL high

   Carryflag = Pind.2                                       '' read acknowledge
   If Carryflag = 0 Then
      Goto Twi_master_read                                  '' if ack transfer (next) data
   End If

   Bitwait Pind.4 , Reset                                   '' wait for SCL low

   Goto Twi_wait_cond                                       '' goto wait condition (rep. start or stop)



Rem ;*******************************
Rem ;* Receive Data (master write) *
Rem ;*******************************
Twi_master_write:
   Bitwait Pind.4 , Reset                                   '' wait for SCL low

   Ddrd.2 = 0                                               '' remove acknowledge from SDA

   Bitwait Pind.4 , Set                                     '' wait for SCL high

   Temp = Pind                                              '' sample SDA (first bit) and SCL
   Temp = Temp And Pinmask                                  '' mask out SDA and SCL

Do_mw:                                                      '' do
   Etemp = Pind                                             ''new sample
   Etemp = Etemp And Pinmask                                '' mask out SDA and SCL
   If Etemp = Temp Then
      Goto Do_mw                                            '' while no change
   End If

   If Etemp.4 = 0 Then                                      '' if SCL changed to low
      Goto Receive_data
   End If

   If Etemp.2 = 0 Then                                      '' if SDA changed to low
      Goto Twi_get_adr
   End If
   Goto Twi_stop

Receive_data:                                               '' set TWIdata MSB to zero
   Twidata = 2
   If Temp.2 <> 0 Then                                      '' if SDA sample is one
      Twidata = 3                                           '' set TWIdata MSB to one
   End If

Do_rd:                                                      '' Do
   Bitwait Pind.4 , Reset                                   '' wait for SCL low

   Carryflag = 1                                            '' set carry
   Bitwait Pind.4 , Set                                     '' wait for SCL high
   If Pind.2 = 0 Then                                       '' if SDA low
      Carryflag = 0                                         '' clear carry
   End If

   Carryflag2 = Twidata.7                                   '' rol TWIdata (bit 7 in carry)
   Shift Twidata , Left , 1
   If Carryflag = 1 Then                                    '' carry naar bit 0
      Twidata = Twidata Or &B00000001
   End If
   Carryflag = Carryflag2

   If Carryflag = 0 Then                                    '' while register not full
      Goto Do_rd
   End If



Rem ;**** Acknowledge Data ****
Twi_dat_ack:
   Bitwait Pind.4 , Reset                                   '' wait for SCL low
   Ddrd.2 = 1                                               '' assert acknowledge on SDA
   Bitwait Pind.4 , Set                                     '' wait for SCL high
   '' ; (acknowledge is removed later)



Rem ;**** Store Data (handle incoming data) ****

Rem ; insert wait states here if nessesary
Rem ; Sbi Ddrd , Ddd4 ;(start Wait State)
'' DDRD.4 = 1

Rem ;! INSERT USER CODE HERE !
Rem ;!NOTE! If the user code is more than TWO instructions then wait
Rem ; states MUST be inserted as shown in description.

   Onthouden = Twidata                                      '' Store data receved in "serial" register (user code example)

Rem ; (end wait state)
Rem ; cbi DDRD,DDD4 ; (end wait state)
'' DDRD.4 = 0

   Goto Twi_master_write                                    '' Start on next transfer






Rem ;***************************************************************************
Rem ;*
Rem ;* INTERRUPT
Rem ;* TIM0_OVF / TWI_skip
Rem ;*
Rem ;* DESCRIPTION
Rem ;* This interrupt handles a "address miss". If the slave device is
Rem ;* not addressed by a master, it will not acknowledge the address.
Rem ;*
Rem ;* Instead of waiting for a new start condition in a "busy loop"
Rem ;* the slave set up the counter to count 8 falling edges on SCL and
Rem ;* returns from the current interrupt. This "skipping" of data
Rem ;* do not occupies any processor time. When 8 egdes are counted, a
Rem ;* timer overflow interrupt handling routine (this one) will check
Rem ;* the next condition that accure. If it                    's a stop condition
Rem ;* the transfer ends, if it                                 's a repeated start condition a jump
Rem ;* to the TWI_wakeup interrupt will read the new address. If a new
Rem ;* transfer is initiated the "skipping" process is repeated.
Rem ;*
Rem ;***************************************************************************

Ovf0_interrupt_handler:                                     '' (timer 0 Overflow Handle )
''   Twistat = Sreg                                           '' store SREG

Twi_adr_miss:
Rem ;**** Drop Acknowledge ****

   Bitwait Pind.4 , Set                                     '' wait for SCL high
   Bitwait Pind.4 , Reset                                   '' wait for SCL low

Rem ; disable timer 0 overflow interrupt
   ''Timsk =(0<<TOIE0)
   Disable Ovf0                                             ''

Rem ; enable external interrupt request 0
   ''Gimsk =(1<<INT0)
   Enable Int0                                              ''


Rem ;************************
Rem ;* Wait for a Condition *
Rem ;************************

Twi_wait_cond:
   Bitwait Pind.4 , Set                                     '' wait for SCL high

   Temp = Pind                                              '' sample SDA (first bit) and SCL
   Temp = Temp And Pinmask                                  '' mask out SDA and SCL
Do_wc:                                                      '' ; Do
   Etemp = Pind                                             '' new sample
   Etemp = Etemp And Pinmask                                '' mask out SDA and SCL
   If Etemp = Temp Then                                     '' while no change
      Goto Do_wc
   End If

   If Etemp.4 = 0 Then                                      '' if SCL changed to low
      Goto Twi_skip_byte                                    '' goto skip byte
   End If
   If Etemp.2 = 0 Then                                      '' if SDA changed to low
      Goto Twi_get_adr                                      '' goto repeated start
   End If
                                                            '' ; goto transfer stop

Rem ;*************************
Rem ;* Handle Stop Condition *
Rem ;*************************
Twi_stop:
Rem ;! Set INT0 to generate an interrupt on low level,
Rem ;! then set INT0 to generate an interrupt on falling edge.
Rem ;! This will clear the EXT_INT0 request flag.

   ''Mcucr =(0 << Isc01) +(0 << Isc00)
   ''Mcucr =(1 << Isc01) +(0 << Isc00)
   Config Int0 = Low Level
   Config Int0 = Falling

''   Sreg = Twistat                                           '' Restore Sreg
   Return                                                   '' return from interrupt


Rem ;****************
Rem ;* Skip byte(s) *
Rem ;****************
Twi_skip_byte:
   Tcnt0 = -7                                               '' set counter initial value
   ''Timsk =(1 << Toie0)                                      '' enable timer 0 overflow interrupt
   Enable Ovf0                                              ''

   ''Gimsk =(0 << Int0)                                       '' disable external interrupt request 0
   Disable Int0                                             ''


''   Sreg = Twistat                                           '' Restore Sreg
   Return                                                   '' reti, return from interrupt



Rem ;**** End of File ****
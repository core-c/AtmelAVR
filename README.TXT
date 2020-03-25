

test01	-	10 bit PWM. 16-bit timer1 met Overflow- & Compare-Interrupts.
test02	-	8 bit PWM. 16-bit timer1 met Overflow- & Compare-Interrupts.
test03	-	losse UART implementatie voor een 7.3728MHz clock en een 19200 buadrate
test04	-	een UART implementatie (7.3728MHz clock, 19200 baud)
		mèt (via UART instelbaar) 8-bit PWM
test05	-	een UART implementatie (7.324MHz clock, 19200 baud)
		mèt (via UART instelbaar) 8-bit PWM
		èn  een externe IRQ0 implementatie   (updated)

test06	-	Een 4-bit LCD-Display aansturing
test06-8	Een 8-bit LCD-Display aansturing
TEST06-8-2	Een 8-bit LCD-Display aansturing
		èn  zelf-gedefinieerde tekens afbeelden
		èn  ADC-samples als meter afbeelden op ADC

test07	-	Een software-matige 2- tm 16-bits PWM generator		(y)
test08	-	Een hardware-matige  8-bits PWM  op de 16-bits Timer1	(y)
test09	-	Een hardware-matige  9-bits PWM  op de 16-bits Timer1	(y)
test10	-	Een hardware-matige 10-bits PWM  op de 16-bits Timer1	(y)
test13	-	Een software-matige  8-bits PWM  op de 8-bits Timer2
test14	-	Een hardware-matige  8-bits PWM  op de 8-bits Timer2


test15	-	Een dimmende LED demo
test20	-	Een dimmende LED demo 
		mèt  een schakelaar om de timer te stoppen/starten.
test21	-	Een dimmende LED's demo voor 3 LED's
		mèt  2 HW-PWM's op Timer1
		èn  1 SW-PWM op Timer2
		mèt  een schakelaar om de dimmer te pauzeren/starten.

test25	-	Een AT-Keyboard implementatie
		mèt  variabelen in SRAM
		èn  locale labels in een macro/subroutine
test25_2	zoals test25...
		mèt  scancode buffer èn ASCII-code buffer in SRAM
		èn  interrupt-handler tijdsduur-uitvoer korter gemaakt (decoderen scancodes gebeurt nu buiten de handler; Zelfs goed bij lagere CK)
		èn  LED (knipperend tijdens init, daarna continue aan)

test26	-	3 HW PWM's
		èn  PWM-DutyCycle instelbaar via PC-COMPort

test30	-	3 HW PWM's
		èn   PWM-DutyCycle instelbaar via PC-COMPort input
		èn   ADC input schrijven naar PC-COMPort
		met  roterende invoerbuffer voor RS232
test31	-	3 HW PWM's
		èn  PWM-DutyCycle instelbaar via PC-COMPort input
		èn  ADC input schrijven naar PC-COMPort
		met  roterende invoerbuffer voor RS232
		èn  TimerCounter0 als PostScaler in gebruik (op 10Hz precíes)

test40	-	Een servo aansturing.
		1ms tot 2ms durende pulzen

test50	-	Een RC-ontvanger test
		mèt  ICP (Input Capture Pin) om servo input te timen
test51	-	Een RC-ontvanger test 2




TEST_I2C	Een master I2C implementatie
		Ontvangt via RS232 een byte, en zendt deze byte via TWI naar de slave op adres $30
		(beter is: TWI_Master)

I2C_Slave	Een slave I2C implementatie
		Ontvangt via TWI (adres $30) een byte, en zendt deze byte naar de LCD
		Als er een '?' wordt ontvangen, dan het laatst ontvangen teken terugzenden.
		(beter is: TWI_Slave)



TWI_Master	De I2C/TWI Master implementatie
		Ontvangt via RS232 data van de PC (hiervoor is het Delphi-programma LCD_I2C_Slave.exe).
		De data wordt als LCD UserCommand verstuurd naar de I2C-Slave op adres $30.
		Dmv. de UserCommands kan alle ingebouwde LCD functionaliteit benut worden.

TWI_Slave	De I2C/TWI Slave implementatie
		De slave op adres $30 ontvangt van de I2C-bus de LCD UserCommands.
		Deze UserCommands spreken de ingebouwde functionaliteit van het LCD aan.
		! Het Delphi-programma LCD_I2C_Slave.exe is om die zgn. userCommands te sturen over RS232 naar de master.


TWI_Master_02	Deze 2 prg's horen bij elkaar
TWI_Slave_02

TEST_I2C	Deze horen ook bij elkaar
I2C_Slave_ASM
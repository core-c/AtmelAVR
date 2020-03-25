cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TWI_Slave\"
C:
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TWI_Slave\twi_slave.map"
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TWI_Slave\twi_slave.lst"
"C:\Program Files\Atmel\AvrAssembler\avrasm2.exe" -fI  -o "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TWI_Slave\twi_slave.hex" -d "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TWI_Slave\twi_slave.obj" -e "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TWI_Slave\twi_slave.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TWI_Slave" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -m "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TWI_Slave\twi_slave.map"  "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TWI_Slave\TWI_Slave.asm"

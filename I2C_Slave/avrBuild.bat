cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\I2C_Slave\"
C:
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\I2C_Slave\i2c_slave.map"
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\I2C_Slave\i2c_slave.lst"
"C:\Program Files\Atmel\AvrAssembler\avrasm2.exe" -fI  -o "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\I2C_Slave\i2c_slave.hex" -d "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\I2C_Slave\i2c_slave.obj" -e "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\I2C_Slave\i2c_slave.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\I2C_Slave" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -m "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\I2C_Slave\i2c_slave.map"  "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\I2C_Slave\I2C_Slave.asm"

cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TWI_Master\"
C:
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TWI_Master\twi_master.map"
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TWI_Master\twi_master.lst"
"C:\Program Files\Atmel\AvrAssembler\avrasm2.exe" -fI  -o "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TWI_Master\twi_master.hex" -d "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TWI_Master\twi_master.obj" -e "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TWI_Master\twi_master.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TWI_Master" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -m "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TWI_Master\twi_master.map"  "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TWI_Master\TWI_Master.asm"

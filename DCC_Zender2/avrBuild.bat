cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender2\"
C:
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender2\dcc_zender2.map"
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender2\dcc_zender2.lst"
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm2.exe" -fI  -o "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender2\dcc_zender2.hex" -d "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender2\dcc_zender2.obj" -e "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender2\dcc_zender2.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender2" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes"  "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender2\DCC_Zender2.asm"

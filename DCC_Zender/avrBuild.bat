cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender\"
C:
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender\dcc_zender.map"
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender\dcc_zender.lst"
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm2.exe" -fI  -o "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender\dcc_zender.hex" -d "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender\dcc_zender.obj" -e "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender\dcc_zender.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes"  "c:\program files\atmel\avr tools\avrstudio4\stoel\dcc_zender\dcc_zender.asm"

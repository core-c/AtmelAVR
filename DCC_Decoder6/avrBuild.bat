cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder6\"
C:
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder6\dcc_decoder6.map"
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder6\dcc_decoder6.lst"
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm2.exe" -fI  -o "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder6\dcc_decoder6.hex" -d "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder6\dcc_decoder6.obj" -e "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder6\dcc_decoder6.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder6" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes"  "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder6\DCC_Decoder6.asm"

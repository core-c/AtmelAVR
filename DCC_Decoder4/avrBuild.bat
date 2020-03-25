cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder4\"
C:
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder4\dcc_decoder4.map"
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder4\dcc_decoder4.lst"
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm2.exe" -fI  -o "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder4\dcc_decoder4.hex" -d "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder4\dcc_decoder4.obj" -e "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder4\dcc_decoder4.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder4" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes"  "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder4\DCC_Decoder4.asm"

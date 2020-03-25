cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder5\"
C:
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder5\dcc_decoder5.map"
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder5\dcc_decoder5.lst"
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm2.exe" -fI  -o "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder5\dcc_decoder5.hex" -d "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder5\dcc_decoder5.obj" -e "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder5\dcc_decoder5.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder5" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes"  "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder5\DCC_Decoder5.asm"

cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder\"
C:
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder\dcc_decoder.map"
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder\dcc_decoder.lst"
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm2.exe" -fI  -o "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder\dcc_decoder.hex" -d "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder\dcc_decoder.obj" -e "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder\dcc_decoder.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes"  "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder\DCC_Decoder.asm"

cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder2\"
C:
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder2\dcc_decoder2.map"
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder2\dcc_decoder2.lst"
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm2.exe" -fI  -o "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder2\dcc_decoder2.hex" -d "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder2\dcc_decoder2.obj" -e "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder2\dcc_decoder2.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Decoder2" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes"  "c:\program files\atmel\avr tools\avrstudio4\stoel\dcc_decoder2\dcc_decoder2.asm"

cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender_v2\"
C:
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender_v2\dcc_zender_v2.map"
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender_v2\dcc_zender_v2.lst"
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm2.exe" -fI  -o "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender_v2\dcc_zender_v2.hex" -d "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender_v2\dcc_zender_v2.obj" -e "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender_v2\dcc_zender_v2.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender_v2" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes"  "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Zender_v2\DCC_Zender_v2.asm"

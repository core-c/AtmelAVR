cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST25_2\"
C:
del test25_2.map
del test25_2.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST25_2\TEST25_2.asm" -o "test25_2.hex" -d "test25_2.obj" -e "test25_2.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST25_2" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test25_2.map"

cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST25\"
C:
del test25.map
del test25.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST25\TEST25.asm" -o "test25.hex" -d "test25.obj" -e "test25.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST25" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test25.map"

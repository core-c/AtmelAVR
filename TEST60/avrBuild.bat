cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST60\"
C:
del test60.map
del test60.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST60\TEST60.asm" -o "test60.hex" -d "test60.obj" -e "test60.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST60" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test60.map"

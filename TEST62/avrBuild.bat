cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST62\"
C:
del test62.map
del test62.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST62\TEST62.asm" -o "test62.hex" -d "test62.obj" -e "test62.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST62" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test62.map"

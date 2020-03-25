cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST06-8-2\"
C:
del test06-8-2.map
del test06-8-2.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST06-8-2\TEST06-8-2.asm" -o "test06-8-2.hex" -d "test06-8-2.obj" -e "test06-8-2.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST06-8-2" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test06-8-2.map"

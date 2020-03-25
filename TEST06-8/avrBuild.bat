cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST06-8\"
C:
del test06-8.map
del test06-8.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST06-8\TEST06-8.asm" -o "test06-8.hex" -d "test06-8.obj" -e "test06-8.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST06-8" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test06-8.map"

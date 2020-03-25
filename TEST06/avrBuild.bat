cd "C:\Program Files\Atmel\Stoel\TEST06\"
C:
del test06.map
del test06.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\Stoel\TEST06\TEST06.asm" -o "test06.hex" -d "test06.obj" -e "test06.eep" -I "C:\Program Files\Atmel\Stoel\TEST06" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test06.map"

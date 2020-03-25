cd "C:\Program Files\Atmel\Stoel\TEST50\"
C:
del test50.map
del test50.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\Stoel\TEST50\TEST50.asm" -o "test50.hex" -d "test50.obj" -e "test50.eep" -I "C:\Program Files\Atmel\Stoel\TEST50" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test50.map"

cd "C:\Program Files\Atmel\Stoel\test26\"
C:
del test26.map
del test26.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\Stoel\test26\test26.asm" -o "test26.hex" -d "test26.obj" -e "test26.eep" -I "C:\Program Files\Atmel\Stoel\test26" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test26.map"

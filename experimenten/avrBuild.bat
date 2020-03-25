cd "C:\Program Files\Atmel\Stoel\experimenten\"
C:
del test00.map
del test00.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\Stoel\experimenten\test00.asm" -o "test00.hex" -d "test00.obj" -e "test00.eep" -I "C:\Program Files\Atmel\Stoel\experimenten" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test00.map"

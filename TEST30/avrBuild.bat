cd "C:\Program Files\Atmel\Stoel\TEST30\"
C:
del test30.map
del test30.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\Stoel\TEST30\TEST30.asm" -o "test30.hex" -d "test30.obj" -e "test30.eep" -I "C:\Program Files\Atmel\Stoel\TEST30" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test30.map"

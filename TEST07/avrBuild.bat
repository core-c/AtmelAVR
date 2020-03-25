cd "C:\Program Files\Atmel\Stoel\TEST07\"
C:
del test07.map
del test07.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\Stoel\TEST07\TEST07.asm" -o "test07.hex" -d "test07.obj" -e "test07.eep" -I "C:\Program Files\Atmel\Stoel\TEST07" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test07.map"

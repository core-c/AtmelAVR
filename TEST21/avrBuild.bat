cd "C:\Program Files\Atmel\Stoel\TEST21\"
C:
del test21.map
del test21.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\Stoel\TEST21\TEST21.asm" -o "test21.hex" -d "test21.obj" -e "test21.eep" -I "C:\Program Files\Atmel\Stoel\TEST21" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test21.map"

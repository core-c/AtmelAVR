cd "C:\Program Files\Atmel\Stoel\TEST31\"
C:
del test31.map
del test31.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\Stoel\TEST31\TEST31.asm" -o "test31.hex" -d "test31.obj" -e "test31.eep" -I "C:\Program Files\Atmel\Stoel\TEST31" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test31.map"

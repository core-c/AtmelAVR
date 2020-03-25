cd "C:\Program Files\Atmel\Stoel\TEST05\"
C:
del test05.map
del test05.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\Stoel\TEST05\TEST05.asm" -o "test05.hex" -d "test05.obj" -e "test05.eep" -I "C:\Program Files\Atmel\Stoel\TEST05" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test05.map"

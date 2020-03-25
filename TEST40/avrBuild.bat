cd "C:\Program Files\Atmel\Stoel\TEST40\"
C:
del test40.map
del test40.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\Stoel\TEST40\TEST40.asm" -o "test40.hex" -d "test40.obj" -e "test40.eep" -I "C:\Program Files\Atmel\Stoel\TEST40" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test40.map"

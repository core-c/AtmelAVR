cd "C:\Program Files\Atmel\Stoel\TEST20\"
C:
del test20.map
del test20.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\Stoel\TEST20\TEST20.asm" -o "test20.hex" -d "test20.obj" -e "test20.eep" -I "C:\Program Files\Atmel\Stoel\TEST20" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test20.map"

cd "C:\Program Files\Atmel\Stoel\TEST15\"
C:
del test15.map
del test15.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\Stoel\TEST15\TEST15.asm" -o "test15.hex" -d "test15.obj" -e "test15.eep" -I "C:\Program Files\Atmel\Stoel\TEST15" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test15.map"

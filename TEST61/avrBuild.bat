cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST61\"
C:
del test61.map
del test61.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST61\TEST61.asm" -o "test61.hex" -d "test61.obj" -e "test61.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\TEST61" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "test61.map"

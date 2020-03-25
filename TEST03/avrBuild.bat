cd "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST03\"
E:
del test03.map
del test03.lst
"E:\Program Files\AVR Studio\AvrAssembler\avrasm32.exe" -fI "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST03\TEST03.asm" -o "test03.hex" -d "test03.obj" -e "test03.eep" -I "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST03" -I "E:\Program Files\AVR Studio\AvrAssembler\AppNotes" -w  -m "test03.map" -l "test03.lst"

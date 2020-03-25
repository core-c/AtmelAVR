cd "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST08\"
E:
del test08.map
del test08.lst
"E:\Program Files\AVR Studio\AvrAssembler\avrasm32.exe" -fI "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST08\TEST08.asm" -o "test08.hex" -d "test08.obj" -e "test08.eep" -I "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST08" -I "E:\Program Files\AVR Studio\AvrAssembler\AppNotes" -w  -m "test08.map" -l "test08.lst"

cd "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST10\"
E:
del test10.map
del test10.lst
"E:\Program Files\AVR Studio\AvrAssembler\avrasm32.exe" -fI "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST10\TEST10.asm" -o "test10.hex" -d "test10.obj" -e "test10.eep" -I "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST10" -I "E:\Program Files\AVR Studio\AvrAssembler\AppNotes" -w  -m "test10.map" -l "test10.lst"

cd "E:\Program Files\AVR Studio\AvrStudio4\HCore\test00\"
E:
del test00.map
del test00.lst
"E:\Program Files\AVR Studio\AvrAssembler\avrasm32.exe" -fI "E:\Program Files\AVR Studio\AvrStudio4\HCore\test00\test00.asm" -o "test00.hex" -d "test00.obj" -e "test00.eep" -I "E:\Program Files\AVR Studio\AvrStudio4\HCore\test00" -I "E:\Program Files\AVR Studio\AvrAssembler\AppNotes" -w 

cd "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST09\"
E:
del test09.map
del test09.lst
"E:\Program Files\AVR Studio\AvrAssembler\avrasm32.exe" -fI "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST09\TEST09.asm" -o "test09.hex" -d "test09.obj" -e "test09.eep" -I "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST09" -I "E:\Program Files\AVR Studio\AvrAssembler\AppNotes" -w  -m "test09.map" -l "test09.lst"

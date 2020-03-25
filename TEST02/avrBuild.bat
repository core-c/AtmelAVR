cd "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST02\"
E:
del test02.map
del test02.lst
"E:\Program Files\AVR Studio\AvrAssembler\avrasm32.exe" -fI "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST02\TEST02.asm" -o "test02.hex" -d "test02.obj" -e "test02.eep" -I "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST02" -I "E:\Program Files\AVR Studio\AvrAssembler\AppNotes" -w  -m "test02.map" -l "test02.lst"

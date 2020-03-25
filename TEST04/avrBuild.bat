cd "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST04\"
E:
del test04.map
del test04.lst
"E:\Program Files\AVR Studio\AvrAssembler\avrasm32.exe" -fI "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST04\TEST04.asm" -o "test04.hex" -d "test04.obj" -e "test04.eep" -I "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST04" -I "E:\Program Files\AVR Studio\AvrAssembler\AppNotes" -w  -m "test04.map" -l "test04.lst"

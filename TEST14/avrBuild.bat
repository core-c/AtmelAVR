cd "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST14\"
E:
del test14.map
del test14.lst
"E:\Program Files\Atmel\AVRStudio\AvrAssembler\avrasm32.exe" -fI "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST14\TEST14.asm" -o "test14.hex" -d "test14.obj" -e "test14.eep" -I "E:\Program Files\AVR Studio\AvrStudio4\HCore\TEST14" -I "E:\Program Files\Atmel\AVRStudio\AvrAssembler\Appnotes" -w  -m "test14.map" -l "test14.lst"

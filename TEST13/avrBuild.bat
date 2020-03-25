cd "E:\Program Files\Atmel\AVRStudio\AvrStudio4\HCore\TEST13\"
E:
del test13.map
del test13.lst
"E:\Program Files\Atmel\AVRStudio\AvrAssembler\avrasm32.exe" -fI "E:\Program Files\Atmel\AVRStudio\AvrStudio4\HCore\TEST13\TEST13.asm" -o "test13.hex" -d "test13.obj" -e "test13.eep" -I "E:\Program Files\Atmel\AVRStudio\AvrStudio4\HCore\TEST13" -I "E:\Program Files\Atmel\AVRStudio\AvrAssembler\Appnotes" -w  -m "test13.map" -l "test13.lst"

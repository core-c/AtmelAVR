cd "E:\Program Files\Atmel\AVRStudio\AvrStudio4\HCore\TEST50\"
E:
del test50.map
del test50.lst
"E:\Program Files\Atmel\AVRStudio\AvrAssembler\avrasm32.exe" -fI "E:\Program Files\Atmel\AVRStudio\AvrStudio4\HCore\TEST50\TEST50.asm" -o "test50.hex" -d "test50.obj" -e "test50.eep" -I "E:\Program Files\Atmel\AVRStudio\AvrStudio4\HCore\TEST50" -I "E:\Program Files\Atmel\AVRStudio\AvrAssembler\AppNotes" -w  -m "test50.map"

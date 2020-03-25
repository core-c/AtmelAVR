cd "E:\Program Files\Atmel\AVRStudio\AvrStudio4\HCore\TEST30\"
E:
del test30.map
del test30.lst
"E:\Program Files\Atmel\AVRStudio\AvrAssembler\avrasm32.exe" -fI "E:\Program Files\Atmel\AVRStudio\AvrStudio4\HCore\TEST30\TEST30.asm" -o "test30.hex" -d "test30.obj" -e "test30.eep" -I "E:\Program Files\Atmel\AVRStudio\AvrStudio4\HCore\TEST30" -I "E:\Program Files\Atmel\AVRStudio\AvrAssembler\AppNotes" -w 

cd "E:\Program Files\AVR Studio\AvrStudio4\HCore\UART_HalfDuplex\UART_HalfDuplex\"
E:
del uart_halfduplex.map
del uart_halfduplex.lst
"E:\Program Files\AVR Studio\AvrAssembler\avrasm32.exe" -fI "E:\Program Files\AVR Studio\AvrStudio4\HCore\UART_HalfDuplex\UART_HalfDuplex\UART_HalfDuplex.asm" -o "uart_halfduplex.hex" -d "uart_halfduplex.obj" -e "uart_halfduplex.eep" -I "E:\Program Files\AVR Studio\AvrStudio4\HCore\UART_HalfDuplex\UART_HalfDuplex" -I "E:\Program Files\AVR Studio\AvrAssembler\AppNotes" -w  -m "uart_halfduplex.map" -l "uart_halfduplex.lst"

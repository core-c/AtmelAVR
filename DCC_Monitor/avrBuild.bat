cd "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Monitor\"
C:
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Monitor\dcc_monitor.map"
del "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Monitor\dcc_monitor.lst"
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm2.exe" -fI  -o "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Monitor\dcc_monitor.hex" -d "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Monitor\dcc_monitor.obj" -e "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Monitor\dcc_monitor.eep" -I "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Monitor" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes"  "C:\Program Files\Atmel\AVR Tools\AvrStudio4\Stoel\DCC_Monitor\DCC_Monitor.asm"

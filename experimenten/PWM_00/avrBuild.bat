cd "C:\Program Files\Atmel\Stoel\PWM_00\"
C:
del pwm_00.map
del pwm_00.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\Stoel\PWM_00\PWM_00.asm" -o "pwm_00.hex" -d "pwm_00.obj" -e "pwm_00.eep" -I "C:\Program Files\Atmel\Stoel\PWM_00" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "pwm_00.map"

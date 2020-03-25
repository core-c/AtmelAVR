cd "C:\Program Files\Atmel\Stoel\PWM_01\"
C:
del pwm_01.map
del pwm_01.lst
"C:\Program Files\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Program Files\Atmel\Stoel\PWM_01\PWM_01.asm" -o "pwm_01.hex" -d "pwm_01.obj" -e "pwm_01.eep" -I "C:\Program Files\Atmel\Stoel\PWM_01" -I "C:\Program Files\Atmel\AVR Tools\AvrAssembler\AppNotes" -w  -m "pwm_01.map"

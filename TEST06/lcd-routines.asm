;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                 LCD-Routinen                ;;
;;                 ============                ;;
;;              (c)andreas-s@web.de            ;;
;;                                             ;;
;; 4bit-Interface                              ;;
;; DB4-DB7:       PD0-PD3                      ;;
;; RS:            PD4                          ;;
;; E:             PD5                          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 
 
 ;sendet ein Datenbyte an das LCD
lcd_data:
           mov temp2, temp1             ;"Sicherungskopie" für
                                        ;die Übertragung des 2.Nibbles
           swap temp1                   ;Vertauschen
           andi temp1, 0b00001111       ;oberes Nibble auf Null setzen
           sbr temp1, 1<<4              ;entspricht 0b00010000
           out PORTD, temp1             ;ausgeben
           rcall lcd_enable             ;Enable-Routine aufrufen
                                        ;2. Nibble, kein swap da es schon
                                        ;an der richtigen stelle ist
           andi temp2, 0b00001111       ;obere Hälfte auf Null setzen 
           sbr temp2, 1<<4              ;entspricht 0b00010000
           out PORTD, temp2             ;ausgeben
           rcall lcd_enable             ;Enable-Routine aufrufen
           rcall delay50us              ;Delay-Routine aufrufen
           ret                          ;zurück zum Hauptprogramm

 ;sendet einen Befehl an das LCD
lcd_command:                            ;wie lcd_data, nur ohne RS zu setzen
           mov temp2, temp1
           swap temp1
           andi temp1, 0b00001111
           out PORTD, temp1
           rcall lcd_enable
           andi temp2, 0b00001111
           out PORTD, temp2
           rcall lcd_enable
           rcall delay50us
           ret

 ;erzeugt den Enable-Puls
lcd_enable:
           sbi PORTD, 5                 ;Enable high
           nop                          ;3 Taktzyklen warten
           nop
           nop
           cbi PORTD, 5                 ;Enable wieder low
           ret                          ;Und wieder zurück                     

 ;Pause nach jeder Übertragung
delay50us:                              ;50us Pause
           ldi  temp1, $42
delay50us_:dec  temp1
           brne delay50us_
           ret                          ;wieder zurück

 ;Längere Pause für manche Befehle
delay5ms:                               ;5ms Pause
           ldi  temp1, $21
WGLOOP0:   ldi  temp2, $C9
WGLOOP1:   dec  temp2
           brne WGLOOP1
           dec  temp1
           brne WGLOOP0
           ret                          ;wieder zurück

 ;Initialisierung: muss ganz am Anfang des Programms aufgerufen werden
lcd_init:
           ldi	temp3,50
powerupwait:
           rcall	delay5ms
           dec	temp3
           brne	powerupwait
           ldi temp1, 0b00000011        ;muss 3mal hintereinander gesendet
           out PORTD, temp1             ;werden zur Initialisierung
           rcall lcd_enable             ;1
           rcall delay5ms
           rcall lcd_enable             ;2
           rcall delay5ms
           rcall lcd_enable             ;und 3!
           rcall delay5ms
           ldi temp1, 0b00000010        ;4bit-Modus einstellen
           out PORTD, temp1
           rcall lcd_enable
           rcall delay5ms
           ldi temp1, 0b00101000        ;noch was einstellen...
           rcall lcd_command
           ldi temp1, 0b00001100        ;...nochwas...
           rcall lcd_command
           ldi temp1, 0b00000100        ;endlich fertig
           rcall lcd_command
           ret

 ;Sendet den Befehl zur Löschung des Displays
lcd_clear:
           ldi temp1, 0b00000001   ;Display löschen
           rcall lcd_command
           rcall delay5ms
           ret


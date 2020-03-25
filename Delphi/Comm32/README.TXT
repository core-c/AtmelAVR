--------------------------------------------------------------------
Copyright (C) 1997 by D3K, The Artisan Of Ware. All rights reserved.
Copyright (C) 1997 by M. Cocco. All rights reserved.
E-mail: d3k@mdnet.it
URL   : * new * http://mdlive.com/d3k/
--------------------------------------------------------------------
Other freeware components we developed:
  - TD3KBitmappedLabel v1.0
      A scrolling lavel with definable bitmap font for various
      special effects (led display, power bars,...)
  - TTTFToVectorConverter v2.05
      Converts TTF character's outlines to polylines.
Freeware Delphi Written Applications:
  - Font Name Changer v1.0 Beta 
      Need to install two fonts that have the same "type face" name ?
      No problem. Simple change the typeface name!
Coming soon:
  - TFLXPlayer component
      FLC/FLI animation player for Delphi 2.0. Powerful!
  - TTTFToVectorConverter v3.0
      Adds support for typographic values (baseline, ascent, descent...)
  - TD3KBitmappedLabel v2.0
      Adds support for blinking and fixes some (rare) problems.
--------------------------------------------------------------------

TCommPortDriver is an invisible component for Delphi 2.0.
It has been developed up on request of Mark Kuhnke (he found my 
email address in the Delphi EXchange Expert's Area).

It is released as FreeWare. You can use it in commercial
and non-commercial applications provided that a simple acknowledgement
is placed somewhere (help file, about box, readme.xxx, ...).

TCommPortDriver features:
 - supports Delphi 2.0 only (uses Win32 API - COMDRV16.ZIP also available)
 - is invisible at run time
 - can handle only first four COM ports (COM1/2/3/4)
 - supports all standard baud rates from 110 to 115200
 - adjustable COM settings (baud rate, byte size, stop bits, parity, handshaking)
 - supports NONE, XON/XOFF, RTS/CTS, XON/XOFF + RTS/CTS handshakings
 - send data by calling SendData()/SendString() methods
 - receive data asyncronously by providing an event to be called when data is available
 - supports variable sized in/out data buffers

! Full source code included !

Enjoy!

----------------------------------------------------------------------

HOW TO :

- Install TCommPortDriver:

Warnings: you must install this component before opening the demo !
          if you open the demo app before doing this, Delphi will
          remove the component declarations from the source code
          and the demo will no longer work !

- To install this component follow the usual steps.
  1. Select <Component|Install...>
  2. Select <Add...> button from the "Install components" dialog box
  3. Select <Browse...> button from the "Add Module" dialog box
  4. Select "CommDrv.pas" and then <OK>
  5. Select <OK> from the <"Install components" dialog box
  6. Delphi will now recompile the components library
  7. All done ! You can find the TCommPortDriver component in the
     component palette ("System" tab)

- Now you can open the demo app (ComTest.DPR) and run it.

If you have throuble feel free to send to d3k@mdnet.it

Hi by M. Cocco (aka Dr Kokko)

-----------------------------------------------------------------------------


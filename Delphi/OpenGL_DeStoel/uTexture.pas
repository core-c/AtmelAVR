unit uTexture;
interface

Type
    // Targa (.TGA) file-header
    TTargaHeader = packed record
      bIDFieldSize : Byte;                // Characters in ID field
      bClrMapType : Byte;                 // Color map type
      bImageType : Byte;                  // Image type
      lClrMapSpec : array[0..4] of Byte;  // Color map specification
      wXOrigin : Integer;                 // X origin
      wYOrigin : Integer;                 // Y origin
      wWidth : Integer;                   // Bitmap width
      wHeight : Integer;                  // Bitmap height
      bBitsPixel : Byte;                  // Bits per pixel
      bImageDescriptor : Byte;            // Image descriptor
    end;




implementation


(*
// TGA-file laden tbv. een texture.
// Ondersteund worden: 24-bit, 32-bit, uncompressed & RLE-compressed TGA-files.
function TGA_LoadData(FileName : string) : Integer;
var ty : array[0..1] of Byte;
    inf : array[0..4] of Byte;
    imageBits : Integer;
    imageSize : As Long, s As Long
Dim ff As Long
Dim temp As Byte
Dim compressedRLE As Boolean, uncompressed As Boolean
Dim pixelCount As GLuint
Dim curPixel  As GLuint '' huidige pixel die we lezen van de file
Dim curByte As GLuint   '' huidige byte die we schrijven als image-data
Dim colorBuffer() As GLubyte
Dim chunkHeader As GLubyte
Dim I As Long, J As Long
Dim s1, s2 As String ''debug.print code

begin
end;
*)




(*
Public Function load_TGA_data(FileName As String) As Integer
Dim ty(2) As Byte
Dim inf(5) As Byte
Dim imageBits As Integer, imageSize As Long, s As Long
Dim ff As Long
Dim temp As Byte
Dim compressedRLE As Boolean, uncompressed As Boolean
Dim pixelCount As GLuint
Dim curPixel  As GLuint '' huidige pixel die we lezen van de file
Dim curByte As GLuint   '' huidige byte die we schrijven als image-data
Dim colorBuffer() As GLubyte
Dim chunkHeader As GLubyte
Dim I As Long, J As Long
Dim s1, s2 As String ''debug.print code
''
    ff = FreeFile
    Open FileName For Binary As ff
    Get ff, , ty
    Get ff, 13, inf
    ''
    uncompressed = (ty(2) = 2)
    compressedRLE = (ty(2) = 10)
    'If Not ty(1) = 0 And Not ty(2) = 2 Then GoTo Hell
    If Not (ty(1) = 0 And (uncompressed Or compressedRLE)) Then GoTo Hell
    ''
    pWidth = CLng(inf(0) + inf(1) * 256)
    pHeight = CLng(inf(2) + inf(3) * 256)
    imageBits = CInt(inf(4))
    pixelCount = pWidth * pHeight
    imageSize = (imageBits / 8) * pixelCount
    If Not (imageBits = 32 Or imageBits = 24) Then GoTo Hell
    ''DEBUG PRINT---------------
    If imageBits = 32 Then s1 = " (+Alpha)"
    If compressedRLE Then s2 = " Compressed"
    Debug.Print "loading" & s2 & " TGA texture @(" & CStr(pWidth) & "," & CStr(pHeight) & ")" & s1 & " : " & FileName
    ''DEBUG PRINT---------------
    ''
    ReDim pData(0 To imageSize - 1) ''geheugen reserveren
    If uncompressed Then
        Get ff, , pData
        Close ff
        '' Rood en Blauw swappen
        Select Case imageBits
        Case 24
            swapRB (3)
        Case 32
            swapRB (4)
        End Select
    Else ''compressedRLE
        Debug.Print "LOADING COMPRESSED-RLE .RAW FILE"
        curPixel = 0
        curByte = 0
        ReDim colorBuffer(0 To (imageBits / 8) - 1)
        Do
            chunkHeader = 0
            Get ff, , chunkHeader
            If chunkHeader < 128 Then
                chunkHeader = chunkHeader + 1
                '' lees-pixel loop
                For I = 0 To chunkHeader - 1
                    Get ff, , colorBuffer
                    pData(curByte) = colorBuffer(2)         '' schrijf de 'R' Byte
                    pData(curByte + 1) = colorBuffer(1)     '' schrijf de 'G' Byte
                    pData(curByte + 2) = colorBuffer(0)     '' schrijf de 'B' Byte
                    If imageBits / 8 = 4 Then ''een 32bpp plaatje?
                        pData(curByte + 3) = colorBuffer(3) '' schrijf de 'A' Byte
                    End If
                    curByte = curByte + (imageBits / 8)     '' verhoog de Byte-Counter met het aantal Bytes-Per-Pixel
                    curPixel = curPixel + 1
                Next
            Else
                chunkHeader = chunkHeader - 127
                Get ff, , colorBuffer
                '' Start de loop
                For I = 0 To chunkHeader - 1
                    pData(curByte) = colorBuffer(2)         '' schrijf de 'R' Byte
                    pData(curByte + 1) = colorBuffer(1)     '' schrijf de 'G' Byte
                    pData(curByte + 2) = colorBuffer(0)     '' schrijf de 'B' Byte
                    If imageBits / 8 = 4 Then ''een 32bpp plaatje?
                        pData(curByte + 3) = colorBuffer(3) '' schrijf de 'A' Byte
                    End If
                    curByte = curByte + (imageBits / 8)     '' verhoog de Byte-Counter met het aantal Bytes-Per-Pixel
                    curPixel = curPixel + 1
                Next
            End If
        Loop While curPixel < pixelCount
        ReDim colorBuffer(0)
    End If
    ''
    load_TGA_data = imageBits
    Close ff
    Exit Function
Hell:
    Close ff
    load_TGA_data = 0
    Debug.Print "Geen geldige (24- of 32-bits) .TGA-file opgegeven aan ""load_TGA_data"" maar een " & CStr(imageBits) & "-bit afbeelding."
End Function
*)




end.

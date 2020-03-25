unit u3DCalc;
interface
uses OpenGL12, Math;

type
    // Een vector
    TVector3f = record
      X, Y, Z: GLFloat;
    end;

    // Een matrix
    TMatrix4x4 = array[0..3,0..3] of GLFloat;


function CreateVector(X,Y,Z: GLFloat): TVector3f;
function AddVector(A,B: TVector3f): TVector3f;
function CrossProduct(A,B: TVector3f): TVector3f;

function CreateMatrix(M00, M01, M02, M03,
                      M10, M11, M12, M13,
                      M20, M21, M22, M23,
                      M30, M31, M32, M33: GLFloat) : TMatrix4x4;
function IdentityMatrix : TMatrix4x4;
function CreateTranslationMatrix(X,Y,Z: GLFloat) : TMatrix4x4;
function CreateRotationXMatrix(Degrees: GLFloat) : TMatrix4x4;
function CreateRotationYMatrix(Degrees: GLFloat) : TMatrix4x4;
function CreateRotationZMatrix(Degrees: GLFloat) : TMatrix4x4;

function MultiplyMatrixMatrix(M0, M1: TMatrix4x4) : TMatrix4x4;
function MultiplyVertexMatrix(V: TVector3f; M: TMatrix4x4) : TVector3f;

implementation


// Maak een vector van 3 opgegeven coördinaten
function CreateVector(X,Y,Z: GLFloat): TVector3f;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
end;



// Tel 2 vectoren bij elkaar op
function AddVector(A,B: TVector3f): TVector3f;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
  Result.Z := A.Z + B.Z;
end;


// een crossproduct berekenen van 2 vectoren (de normaal).
// Resultaat is een vector die loodrecht wijst in de richting van beide vectoren A & B.
function CrossProduct(A,B: TVector3f): TVector3f;
begin
  Result.X := (A.Y * B.Z) - (A.Z * B.Y);
  Result.Y := (A.Z * B.X) - (A.X * B.Z);
  Result.Z := (A.X * B.Y) - (A.Y * B.X);
end;




// Een 4x4-matrix opbouwen
function CreateMatrix(M00, M01, M02, M03,
                      M10, M11, M12, M13,
                      M20, M21, M22, M23,
                      M30, M31, M32, M33: GLFloat) : TMatrix4x4;
begin
  // De 1e rij
  Result[0,0] := M00;
  Result[0,1] := M01;
  Result[0,2] := M02;
  Result[0,3] := M03;
  // De 2e rij
  Result[1,0] := M10;
  Result[1,1] := M11;
  Result[1,2] := M12;
  Result[1,3] := M13;
  // De 3e rij
  Result[2,0] := M20;
  Result[2,1] := M21;
  Result[2,2] := M22;
  Result[2,3] := M23;
  // De 4e rij
  Result[3,0] := M30;
  Result[3,1] := M31;
  Result[3,2] := M32;
  Result[3,3] := M33;
end;


// resulteer een 4x4 identity-matrix
function IdentityMatrix : TMatrix4x4;
begin
  Result := CreateMatrix(1,0,0,0,
                         0,1,0,0,
                         0,0,1,0,
                         0,0,0,1);
end;


function CreateTranslationMatrix(X,Y,Z: GLFloat) : TMatrix4x4;
begin
  Result := CreateMatrix(1,0,0,X,
                         0,1,0,Y,
                         0,0,1,Z,
                         0,0,0,1);
end;


// Een 4x4-matrix opbouwen voor een rotatie om de X-as
function CreateRotationXMatrix(Degrees: GLFloat) : TMatrix4x4;
var Angle: GLFloat;
begin
  Angle := DegToRad(Degrees);
  Result := CreateMatrix(1,          0,           0, 0,
                         0, cos(Angle), -sin(Angle), 0,
                         0, sin(Angle),  cos(Angle), 0,
                         0,          0,           0, 1)
end;

// Een 4x4-matrix opbouwen voor een rotatie om de Y-as
function CreateRotationYMatrix(Degrees: GLFloat) : TMatrix4x4;
var Angle: GLFloat;
begin
  Angle := DegToRad(Degrees);
  Result := CreateMatrix( cos(Angle),  0,  sin(Angle), 0,
                                   0,  1,           0, 0,
                         -sin(Angle),  0,  cos(Angle), 0,
                                   0,  0,           0, 1)
end;

// Een 4x4-matrix opbouwen voor een rotatie om de Z-as
function CreateRotationZMatrix(Degrees: GLFloat) : TMatrix4x4;
var Angle: GLFloat;
begin
  Angle := DegToRad(Degrees);
  Result := CreateMatrix(cos(Angle), -sin(Angle), 0, 0,
                         sin(Angle),  cos(Angle), 0, 0,
                                  0,           0, 0, 0,
                                  0,           0, 0, 1)
end;


// 2 4x4-matrices met elkaar vermenigvuldigen
function MultiplyMatrixMatrix(M0, M1: TMatrix4x4) : TMatrix4x4;
var row,col: integer;
begin
  for row:=0 to 3 do
    for col:=0 to 3 do
      Result[row,col] := M0[row,0] * M1[0,col] +
                         M0[row,1] * M1[1,col] +
                         M0[row,2] * M1[2,col] +
                         M0[row,3] * M1[3,col]
end;


// Een vector met een matrix en resulteer een vector voor het getransformeerde punt
// (!! De onderste rij van de matrix wordt genegeerd in deze routine !!)
function MultiplyVertexMatrix(V: TVector3f; M: TMatrix4x4) : TVector3f;
begin
  Result.X := V.X * M[0,0]  +  V.Y * M[1,0]  +  V.Z * M[2,0]  +  M[3,0];
  Result.Y := V.X * M[0,1]  +  V.Y * M[1,1]  +  V.Z * M[2,1]  +  M[3,1];
  Result.Z := V.X * M[0,2]  +  V.Y * M[1,2]  +  V.Z * M[2,2]  +  M[3,2];
end;



end.

unit Unit2;
interface
uses
  OpenGL12, GLUT, Math, u3DCalc;

(*
   Berekeningen mbt. de positionering van de stoel:
   De 3 motoren hebben ònder elk een vast scharnierpunt. De relatieve positie
   van de 3 scharnierpunten blijft gelijk.
   Het bovenste scharnierpunt van elke motor is verschuifbaar.
   Omdat het onderste vlak gelijk blijft qua afmetingen en (absolute) positie
   is dit hèt aanknopingspunt om de berekeningen te starten.

   Afmetingen van het onderste (grijze) vlak:
   Ik heb opgemeten de lengte van zijde B (20.5 cm),
                    de lengte van zijde 1-2 (45 cm)  =>  A = 45/2 = 22.5 cm

              0             stelling van Piet: C² = A² + B²  =>
              .                                C = 30.4 cm
             /|\
          C / | \           punt X wordt op de oorsprong geprojecteerd.
           /  |  \          => punt 1 krijgt de coordinaten (-A,0,0)
          /  B|   \            punt 2 valt op (A,0,0)
      1  /____|____\  2        punt 0 (0,0,-B) (!negatieve Z-as loopt van je af)
           A  X

   Afmetingen van het bovenste (gele) vlak:
   Bovenop het gele vlak is de stoel geplaatst. In ruststand is dit vlak
   horizontaal geplaatst. De 3 motoren hebben boven alle 3 een scharnierpunt wat
   nìet vastligt. Ik ga ervan uit dat we de plaatsing/rotatie van het bovenste
   vlak weten, en dat we de motoren in de juiste stand moeten rekenen.
   Om de coördinaten van het getransformeerde (gele) vlak te bepalen, moeten we
   een omgekeerde berekening maken.



 ! Mbv. een joystick kan het bovenste vlak gedraaid worden:
   knop 1 indrukken en bewegen = links/rechtsom
   knop 2 indrukken en bewegen = voor/achterover

 ! Als de stoel in ruststand is, en de stoel zelf horizontaal geplaatst is, dan
   is de voorste motor in een hoek van 9.67° voorover gekanteld.

 ! Voor het gemak komen de in OpenGL gebruikte coördinaten overeen met
   "real-life" meters. ;-)

*)
{$J+}  //typed constants gebruik toestaan

{--- Gegevens/afmetingen van de stoel -----------------------------------------}
const
    // De onderste, vaste scharnierpunten van de motoren
    punt0 : TVector3f = (X:0.0;    Y:0.0; Z:-0.205);        // voor
    punt1 : TVector3f = (X:-0.225; Y:0.0; Z:0.0);           // links
    punt2 : TVector3f = (X:0.225;  Y:0.0; Z:0.0);           // rechts
    // De bovenste, verplaatsbare scharnierpunten van de motoren
    punt3 : TVector3f = (X:0.0;    Y:0.0; Z:-0.205-0.075);  // voor
    punt4 : TVector3f = (X:0.225;  Y:0.0; Z:0.0);           // rechts
    punt5 : TVector3f = (X:-0.225; Y:0.0; Z:0.0);           // links

    Plateau_Dikte = 0.05;   // dikte van het plateau waarop de stoel staat
    Engine_AsDikte = 0.02;  // de dikte van een motor-as (2 cm)
    // de volgende 2 waarden dienen nog te worden opgemeten
    Engine_AsMinLengte = 0.20;  // lengte van motor-as als deze helemaal in is.
    Engine_AsMaxLengte = 0.60;  // lengte van motor-as als deze helemaal uit is.

type
    // een record met eigenschappen voor een motor
    TEngine = record
      AsLengteRuststand : single;
      AsLengte : single;
      RustPunt : TVector3f;
    end;
var
    Engine : array[0..2] of TEngine;


{--- Perspectief parameters ---------------------------------------------------}
const
    // De perspectief parameters
    nearDistance: GLFloat = 0.1;    // near plane
    viewDistance: GLFloat = 5.0;    // far plane
    FOV: GLFloat = 60.0;            // hoek van FOV voor camera (blz 126)
    aspectRatio: GLFloat = 300/300; // verhouding Width & Height van het scherm
var
    is3D: boolean;                  // true=perspectief, false=orthogonaal


{--- Materiaal defenities -----------------------------------------------------}
type
    // een definitie van een materiaal-record met eigenschappen die we gebruiken
    TMaterial = record
      Diffuse   : array[0..3] of GLfloat;
      Specular  : array[0..3] of GLfloat;
      Emission  : array[0..3] of GLfloat;
      Shininess : GLFloat;
    end;

const
    // Materialen
    Materials : array[0..4] of TMaterial =
               (
                ( // 0 rood
                  Diffuse:(0.5, 0.0, 0.0, 0.00);
                  Specular:(1.0, 0.7, 0.7, 0.00);
                  Emission:(0.1, 0.1, 0.1, 0.00);
                  Shininess:20.00 ),
                ( // 1 blauw
                  Diffuse:(0.0, 0.0, 0.5, 0.00);
                  Specular:(0.7, 0.7, 1.0, 0.00);
                  Emission:(0.1, 0.1, 0.1, 0.00);
                  Shininess:50.00 ),
                ( // 2 groen
                  Diffuse:(0.0, 0.5, 0.0, 0.00);
                  Specular:(0.7, 1.0, 0.7, 0.00);
                  Emission:(0.1, 0.1, 0.1, 0.00);
                  Shininess:50.00 ),
                ( // 3 grijs
                  Diffuse:(0.5, 0.5, 0.5, 0.00);
                  Specular:(1.0, 1.0, 1.0, 0.00);
                  Emission:(0.1, 0.1, 0.1, 0.00);
                  Shininess:20.00 ),
                ( // 4 geel
                  Diffuse:(0.5, 0.5, 0.0, 0.00);
                  Specular:(1.0, 1.0, 0.7, 0.00);
                  Emission:(0.1, 0.1, 0.1, 0.00);
                  Shininess:20.00 )
               );
    rood  = 0;
    blauw = 1;
    groen = 2;
    grijs = 3;
    geel  = 4;


{--- De stoel en/of Camera0 bewegen mbv. een MotionFunc-callback routine ------}
const
    // De gevoeligheid bij roteren van de stoel mbv. de MotionFunc-callback
    motionSensitivity = 1;     // hoe kleiner de waarde, hoe sneller de beweging
type
    TMotion = record
      inMotion: boolean;
      // coordinaten van laatste muisklik in window (tbv. MotionFunc)
      lastX, lastY: integer;
    end;
var
    Motion_Stoel,
    Motion_Camera0: TMotion;


{------------------------------------------------------------------------------}
const
    // Lichten
    Light0_Position : array[0..3] of GLfloat = ( 0.0, 0.0, 0.0, 1.00 );   //relatief 0,0,0 tov camera-lens
//    Light0_Direction : array[0..3] of GLfloat  = (0.0, -1.0, 0.0, 0.0); //recht naar beneden
    Light0_Ambient : array[0..3] of GLfloat  = (0.4, 0.4, 0.4, 1.0);

    // Het camera-standpunt
    camDistance: GLFloat = 1.0;    //instelbaar
    camHeight: GLFloat = 0.4;
    Camera0_Position : TVector3f = (X:0.0;  Y:0.2; Z:1.0);
    Camera0_Rotation : TVector3f = (X:12.0; Y:0.0; Z:0.0);

    // De positie en rotatie van de hele scene
    Scene_Position : TVector3f = (X:0.0; Y:0.0; Z:0.0);
    Scene_Rotation : TVector3f = (X:0.0; Y:0.0; Z:0.0);

    // De positie en rotatie van de stoel (gele vlak)
    Stoel_Position : TVector3f = (X:0.0; Y:0.44; Z:-0.29);
    Stoel_Rotation : TVector3f = (X:0.0; Y:0.0; Z:0.0);

var
    useJoystickButtons : boolean;


{--- De defenities van de opgenomen procedures en functies --------------------}
{OpenGL GLUT callback routines}
procedure display; stdcall;
procedure reshape(w,h: GLint); stdcall;
procedure special(key, x, y: GLint); stdcall;
procedure keyboard(key: char; x, y: GLint); stdcall;
procedure joystick(buttonMask: GLUint; x, y, z: GLint); stdcall;
procedure timer(value: GLint); stdcall;
procedure mouse(button, state, x, y: GLint); stdcall;
procedure motion(x, y: GLint); stdcall;

procedure init;
procedure SetupCamera;
procedure SetupMaterial(i: integer);
procedure SetupLights;
procedure ResetTransformation;

procedure DrawChair;
procedure DrawEngines;
procedure RecalculateEngines;


implementation
{ $R *.RES}



procedure display;
begin
  // het scherm wissen
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  // de camera-positie instellen
  SetupCamera;
  // rotatie & positie van de scene instellen
  glRotatef(Scene_Rotation.X, 1.0, 0.0, 0.0);
  glRotatef(Scene_Rotation.Y, 0.0, 1.0, 0.0);
  glRotatef(Scene_Rotation.Z, 0.0, 0.0, 1.0);
  glTranslatef(Scene_Position.X, Scene_Position.Y, Scene_Position.Z);
  // de stoel tekenen
  DrawChair;

  // display-buffers wisselen
  glFlush();
  glutSwapBuffers();
end;


procedure reshape(w,h: GLint);
begin
  aspectRatio := w/h;
  glViewport(0,0,w,h);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  gluPerspective(FOV, aspectRatio, nearDistance, viewDistance);
{  glFrustum(-0.7*aspectRatio,0.7*aspectRatio, -5,5, 0.1,1.0);}
{  if w<=h then gluOrtho2D(0.0,1.0, 0.0,aspectRatio)
          else gluOrtho2D(0.0,aspectRatio, 0.0,1.0);}
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  // een licht maken dat in de lens van de camera hangt  (rel.pos=0,0,0)
  // en overal rondom schijnt (geen spotlight).
  // Als de camera beweegt, gaat het licht mee met de camera.
  glLightfv(GL_LIGHT0, GL_POSITION, @Light0_Position);
  // het scherm opnieuw afbeelden tijdens een form-resize
  display; {glutPostRedisplay();}
end;


procedure special(key, x, y: GLint);
var doRedisplay: boolean;
begin
  doRedisplay := true;
  case key of
    101 {Arrow_Up} : // de camera bovenom draaien om de stoel
        camDistance := camDistance - 0.05;    //inzoomen
    103 {Arrow_Down} : // de camera onderom draaien om de stoel
        camDistance := camDistance + 0.05;    //uitzoomen

(*    100 {Arrow_Left} : // de camera linksom draaien om de stoel
        Camera0_Rotation[1] := Camera0_Rotation[1] - 1.0;
    102 {Arrow_Right} : // de camera rechtsom draaien om de stoel
        Camera0_Rotation[1] := Camera0_Rotation[1] + 1.0;*)

    104 {Page_Up} : // de camera hoger plaatsen
        camHeight := camHeight + 0.1;
    105 {Page_Down} : // de camera lager plaatsen
        camHeight := camHeight - 0.1;

    106 {Home} : // de camera en stoel in beginstand plaatsen
        ResetTransformation;
  else
    doRedisplay := false;
  end;
  if doRedisplay then glutPostRedisplay();
end;


procedure keyboard(key: char; x, y: GLint);
begin
  case key of
    #27 : halt(1); {stop het programma}
    'P','p' : is3D := not is3D; {perspectief/orthogonaal toggle}
    'J','j' : useJoystickButtons := not useJoystickButtons;
  end;
end;


procedure joystick(buttonMask: GLUint; x, y, z: GLint);
const maxRotation = 45.0;  //45° naar links èn 45° naar rechts mogelijk
      scaler = 1000/maxRotation;
var recalculate: boolean;
begin
  recalculate := false;
  // De joystick levert waarden voor x,y & z die in het bereik[-1000..1000] liggen
  if useJoystickButtons then begin
    if (buttonMask and GLUT_JOYSTICK_BUTTON_A)>0 then begin
      Stoel_Rotation.Z := -x/scaler; //links/rechtsom kantelen
      recalculate := true;
    end;
    if (buttonMask and GLUT_JOYSTICK_BUTTON_B)>0 then begin
      Stoel_Rotation.X := y/scaler;  //voor/achterover kantelen
      recalculate := true;
    end;
  end else begin
    Stoel_Rotation.X := y/scaler;  //voor/achterover kantelen
    Stoel_Rotation.Z := -x/scaler; //links/rechtsom kantelen
    recalculate := true;
  end;
  // motor-standen indien nodig herberekenen
  if recalculate then begin
    RecalculateEngines;
    glutPostRedisplay();
  end;
end;


procedure mouse(button, state, x, y: GLint);
begin
  case button of
    GLUT_LEFT_BUTTON : begin
        case state of
          GLUT_DOWN : begin
              // begin met bewegen van de stoel
              with Motion_Stoel do begin
                inMotion := true;
                // Als de linker muisknop gedrukt is,
                // dan de positie van de cursor bewaren tbv. de MotionFunc callback....
                lastX := x;
                lastY := y;
              end;
            end;
          GLUT_UP : begin
              // stop met bewegen van de stoel
              Motion_Stoel.inMotion := false;
            end;
        end;
      end;
    GLUT_MIDDLE_BUTTON : begin
      end;
    GLUT_RIGHT_BUTTON : begin
        case state of
          GLUT_DOWN : begin
              // begin met bewegen van de camera0
              with Motion_Camera0 do begin
                inMotion := true;
                // Als de rechter muisknop gedrukt is,
                // dan de positie van de cursor bewaren tbv. de MotionFunc callback....
                lastX := x;
                lastY := y;
              end;
            end;
          GLUT_UP : begin
              // stop met bewegen van de stoel
              Motion_Camera0.inMotion := false;
            end;
        end;
      end;
  end;
end;


procedure motion(x, y: GLint);
var deltaX, deltaY: integer;
begin
  // bepaal of we de stoel bewegen
  with Motion_Stoel do
    if inMotion then begin
      deltaX := x - lastX;
      deltaY := y - lastY;
      lastX := x;
      lastY := y;
      {De rotatie om de Y-as}
      Scene_Rotation.Y := Scene_Rotation.Y + deltaX/motionSensitivity;
      {De rotatie om de X-as}
      Scene_Rotation.X := Scene_Rotation.X - deltaY/motionSensitivity;
    end;

  // bepaal of we de camera bewegen
  with Motion_Camera0 do
    if inMotion then begin
      deltaX := x - lastX;
      deltaY := y - lastY;
      lastX := x;
      lastY := y;
      {De rotatie om de Y-as}
      Camera0_Rotation.Y := Camera0_Rotation.Y - deltaX/motionSensitivity;
      {De rotatie om de X-as}
      Camera0_Rotation.X := Camera0_Rotation.X - deltaY/motionSensitivity;
    end;

  glutPostRedisplay();
end;


procedure timer(value: GLint);
begin
(*
  Camera0_Rotation.X := Camera0_Rotation.X + 0.0;
  Camera0_Rotation.Y := Camera0_Rotation.Y + 1.0;
  Camera0_Rotation.Z := Camera0_Rotation.Z + 0.0;
*)
  //
  {glutTimerFunc( 10, timer, value);}
  glutPostRedisplay();
end;










{------------------------------------------------------------------------------}
procedure init();
begin
  // Lichten instellen
  SetupLights;
  // Geen alpha kanaal gebruiken, alleen RGB
  glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_FALSE);
  glClearColor(0.0, 0.0, 0.0, 0.0);

  // De diepte-buffer
  glDepthFunc(GL_LESS);
  glDepthRange(0.0, 1.0);
  glDepthMask(GL_TRUE);
  glEnable(GL_DEPTH_TEST);

  // Backface-culling
  glFrontFace(GL_CCW);
  glCullFace(GL_BACK);
  glEnable(GL_CULL_FACE);

  glDisable(GL_BLEND);
  glEnable(GL_NORMALIZE); // bij deze kleine 3D-scene mag het wel, toch snel genoeg dan....

  glLineStipple(3, $3333);
  glEnable(GL_LINE_STIPPLE);

  //Mijn variabelen initialiseren
  Motion_Stoel.inMotion := false;
  Motion_Camera0.inMotion := false;
  // de lengte van een motor-as in ruststand
  Engine[0].AsLengteRuststand := 0.4463; // de voorste motor
  Engine[0].AsLengte := 0.4463;
  Engine[0].RustPunt := punt3;
  Engine[1].AsLengteRuststand := 0.44;
  Engine[1].AsLengte := 0.44;
  Engine[1].RustPunt := punt5;
  Engine[2].AsLengteRuststand := 0.44;
  Engine[2].AsLengte := 0.44;
  Engine[2].RustPunt := punt4;
  // afbeelden in perspectief
  is3D := true;
  // sturen als de joystick-knoppen zijn gedrukt (toggle met 'J')
  useJoystickButtons := true;
end;


procedure SetupCamera;
begin
  glLoadIdentity();
  {de positie van de camera}
  Camera0_Position.X := 0.0;
  Camera0_Position.Y := camHeight;
  Camera0_Position.Z := -camDistance;
  {rotatie van de camera}
  glRotatef(-Camera0_Rotation.X, 1.0,0.0,0.0);
  glRotatef(-Camera0_Rotation.Y, 0.0,1.0,0.0);
  glRotatef(-Camera0_Rotation.Z, 0.0,0.0,1.0);
  // De camera positioneren
  gluLookAt(Camera0_Position.X, Camera0_Position.Y, Camera0_Position.Z, // Hier staat de camera
            Scene_Position.X,   Scene_Position.Y,   Scene_Position.Z,   // De camera kijkt naar dit punt
            0.0,1.0,0.0);                                               // De bovenkant van de camera wijst in richting positieve Y-as
end;


procedure SetupMaterial(i: integer);
begin
  glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, @Materials[i].Diffuse);
  glMaterialfv(GL_FRONT, GL_SPECULAR, @Materials[i].Specular);
  glMaterialfv(GL_FRONT, GL_EMISSION, @Materials[i].Emission);
  glMaterialf(GL_FRONT, GL_SHININESS, Materials[i].Shininess);
end;


procedure SetupLights;
begin
  glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER, integer(GL_TRUE));
  glLightModeli(GL_LIGHT_MODEL_TWO_SIDE, integer(GL_FALSE));
  glLightModelfv(GL_LIGHT_MODEL_AMBIENT, @Light0_Ambient);
//  glLightfv(GL_LIGHT0, GL_POSITION, @Light0_Position);
//  glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, @Light0_Direction);
//  glLightf(GL_LIGHT0, GL_QUADRATIC_ATTENUATION, 0.0);
//  glLightf(GL_LIGHT0, GL_SPOT_CUTOFF, 60.0);

  glShadeModel({GL_FLAT}GL_SMOOTH);
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
end;


// De camera0- en Stoel-transformatie resetten naar de beginstand
procedure ResetTransformation;
begin
  camDistance := 1.0;
  camHeight := 0.4;
  {de positie van de camera}
  Camera0_Position.X := 0.0;
  Camera0_Position.Y := camHeight;
  Camera0_Position.Z := -camDistance;
  {rotatie van de camera}
  Camera0_Rotation.X := 12.0;
  Camera0_Rotation.Y := 0.0;
  Camera0_Rotation.Z := 0.0;

  {de positie van de stoel}
  Stoel_Position.X := 0.0;
  Stoel_Position.Y := 0.44;
  Stoel_Position.Z := 0.0;
  {rotatie van de stoel}
  Stoel_Rotation.X := 0.0;
  Stoel_Rotation.Y := 0.0;
  Stoel_Rotation.Z := 0.0;

  {de positie van de scene}
  Scene_Position.X := 0.0;
  Scene_Position.Y := 0.0;
  Scene_Position.Z := 0.0;
  {rotatie van de scene}
  Scene_Rotation.X := 0.0;
  Scene_Rotation.Y := 0.0;
  Scene_Rotation.Z := 0.0;

  {De motoren}
  Engine[0].AsLengte := Engine[0].AsLengteRuststand;
  Engine[1].AsLengte := Engine[1].AsLengteRuststand;
  Engine[2].AsLengte := Engine[2].AsLengteRuststand;

  glutPostRedisplay();
end;










{------------------------------------------------------------------------------}
procedure DrawLine(A,B: TVector3f; StippleSize: integer; StippleMask: word);
begin
  glLineStipple(StippleSize, StippleMask);
  glDisable(GL_LIGHTING);
  glBegin(GL_LINES);
    glVertex3f(A.X, A.Y, A.Z);
    glVertex3f(B.X, B.Y, B.Z);
  glEnd();
  glEnable(GL_LIGHTING);
end;


procedure DrawTriangle(A,B,C: TVector3f; aHeight: GLFloat);
var V, PA,PB,PC: TVector3f;
begin
  { De 3 accent-punten bepalen na verschuiving van aHeight }
  V := CreateVector(0.0, aHeight, 0.0);
  PA := AddVector(A, V);
  PB := AddVector(B, V);
  PC := AddVector(C, V);

  { De boven- & onderkant tekenen }
  glBegin(GL_TRIANGLES);
    // het richtvlak            //           0
    glVertex3f(A.X, A.Y, A.Z);  //0         /\
    glVertex3f(B.X, B.Y, B.Z);  //1        /  \
    glVertex3f(C.X, C.Y, C.Z);  //2    1  /____\  2
    // de onderkant
    glVertex3f(PA.X, PA.Y, PA.Z);
    glVertex3f(PC.X, PC.Y, PC.Z);
    glVertex3f(PB.X, PB.Y, PB.Z);
  glEnd();

  { ClockWise en CounterClockWise (CW & CCW) checken }
//@  if aHeight<0 then glFrontFace(GL_CCW) else glFrontFace(GL_CW);
  // De zijkanten tekenen
  glBegin(GL_QUADS);
    // een zijkant
    glVertex3f(A.X, A.Y, A.Z);
    glVertex3f(PA.X, PA.Y, PA.Z);
    glVertex3f(PB.X, PB.Y, PB.Z);
    glVertex3f(B.X, B.Y, B.Z);
    // een zijkant
    glVertex3f(B.X, B.Y, B.Z);
    glVertex3f(PB.X, PB.Y, PB.Z);
    glVertex3f(PC.X, PC.Y, PC.Z);
    glVertex3f(C.X, C.Y, C.Z);
    // een zijkant
    glVertex3f(C.X, C.Y, C.Z);
    glVertex3f(PC.X, PC.Y, PC.Z);
    glVertex3f(PA.X, PA.Y, PA.Z);
    glVertex3f(A.X, A.Y, A.Z);
  glEnd();
//@  glFrontFace(GL_CCW);  // Backface-culling resetten op CounterClockWise
end;

(*
procedure DrawLines;
var M, Mt: TMatrix4x4;
    A,B: TVector3f;
begin
  glPushMatrix();

    glTranslatef(Stoel_Position.X, Stoel_Position.Y, Stoel_Position.Z/2);
    glRotatef(Stoel_Rotation.X, 1.0, 0.0, 0.0);
    glRotatef(Stoel_Rotation.Y, 0.0, 1.0, 0.0);
    glRotatef(Stoel_Rotation.Z, 0.0, 0.0, 1.0);
    glTranslatef(Stoel_Position.X, Stoel_Position.Y, -Stoel_Position.Z/2);

    M := CreateTranslationMatrix(Stoel_Position.X, Stoel_Position.Y, Stoel_Position.Z/2);
    Mt := CreateRotationXMatrix(Stoel_Rotation.X);
    M := MultiplyMatrixMatrix(M, Mt);
    Mt := CreateRotationYMatrix(Stoel_Rotation.Y);
    M := MultiplyMatrixMatrix(M, Mt);
    Mt := CreateRotationZMatrix(Stoel_Rotation.Z);
    M := MultiplyMatrixMatrix(M, Mt);
    Mt := CreateTranslationMatrix(Stoel_Position.X, Stoel_Position.Y, -Stoel_Position.Z/2);
    M := MultiplyMatrixMatrix(M, Mt);

    glColor3f(1.0, 0.4, 1.0);
    A := punt5;
    B := MultiplyVertexMatrix(punt5, M);
    DrawLine(A,B, 3,$5555);

    A := punt4;
    B := MultiplyVertexMatrix(punt4, M);
    DrawLine(A,B, 3,$5555);

  glPopMatrix();
end;
*)



procedure DrawChair;
const dikte = Plateau_Dikte;  //dikte van het plateau waarop de stoel staat
var A,B: TVector3f;
begin
  {glShadeModel(GL_FLAT);}
  // de matrix bewaren ivm. stoel-"child"-onderdelen (engines ed.)
  glPushMatrix();
    // grijs materiaal kiezen
    SetupMaterial(grijs);
    // het onderste, vaste, plateau van de stoel-constructie tekenen
    DrawTriangle(punt0, punt1, punt2, -dikte);
  glPopMatrix();

  glPushMatrix();
    // rotatie & positie van de stoel instellen
    //NB! De stoel kantelt voor/achterover nìet om lijn 4-5 maar om het
    //midden (in Z-richting) van de driehoek (daarom transleren pos/2)
    //De driehoek wordt even voor z'n halve lengte naar achter geplaatst,
    //vervolgens geroteerd, en daarna weer terug geplaatst een halve lengte.
    glTranslatef(Stoel_Position.X, Stoel_Position.Y, Stoel_Position.Z/2);
    glRotatef(Stoel_Rotation.X, 1.0, 0.0, 0.0);
    glRotatef(Stoel_Rotation.Y, 0.0, 1.0, 0.0);
    glRotatef(Stoel_Rotation.Z, 0.0, 0.0, 1.0);
    glTranslatef(0.0, 0.0, -Stoel_Position.Z/2);
    // geel materiaal kiezen
    SetupMaterial(geel);
    // het bovenste, veranderlijke, plateau waar de stoel op bevestigd is
    DrawTriangle(punt3, punt4, punt5, dikte);

    //--- 3 hulp-lijnen tekenen van stoel-plateau naar motor-assen
    glPushMatrix();
      glColor3f(0.4, 0.4, 0.4);
      A := punt3;
      B := AddVector(punt3, CreateVector(0.0, 0.0, -0.20));
      DrawLine(A,B, 3,$5555);
      A := punt4;
      B := AddVector(punt4, CreateVector(0.20, 0.0, 0.0));
      DrawLine(A,B, 3,$5555);
      A := punt5;
      B := AddVector(punt5, CreateVector(-0.20, 0.0, 0.0));
      DrawLine(A,B, 3,$5555);
    glPopMatrix();
  glPopMatrix();

  // De motoren tekenen
  DrawEngines;
(*
  // Nog wat hulplijnen tekenen
  DrawLines;
*)
end;


procedure DrawEngines;
const dikte = Engine_AsDikte;
      hulplijn_Boven = 0.5;  hulplijn_Onder = 0.3;
var qObj: PGLUquadricObj;
    A,B: TVector3f;
begin
  glDisable(GL_CULL_FACE);
  {glShadeModel(GL_SMOOTH);}
  // een cyliner definiëren
  qObj := gluNewQuadric();
  gluQuadricNormals(qObj, GLU_SMOOTH);

  //--- De voorste motor tekenen -----------------------------------------------
  // blauw materiaal kiezen
  SetupMaterial(blauw);
  glPushMatrix();
    glTranslatef( punt0.X, -punt0.Y, punt0.Z );
    // de voorste motor staat onder een hoek van 9.67° voorover
    glRotatef(-90.0-9.67, 1.0, 0.0, 0.0); // draai om de X-as => Y:=-Z, Z:=Y
    // een cyliner tekenen
    gluCylinder(qObj,dikte,dikte,Engine[0].AsLengte,8,1);
  glPopMatrix();
  //--- een hulp-lijn tekenen door de motor-as
  glPushMatrix();
    glRotatef(-9.67, 1.0, 0.0, 0.0); // draai om de X-as => Y:=-Z, Z:=Y
    glColor3f(0.8, 0.8, 1.0);
    A := AddVector(punt0, CreateVector(0.0, -hulplijn_Onder, 0.0));
    B := AddVector(punt0, CreateVector(0.0, hulplijn_Boven+Engine[0].AsLengte, 0.0));
    DrawLine(A,B, 3,$3333);
  glPopMatrix();


  //--- De motor links-achter tekenen ------------------------------------------
  // groen materiaal kiezen
  SetupMaterial(groen);
  glPushMatrix();
    glTranslatef( punt1.X, punt1.Y, punt1.Z );
    glRotatef(-90.0, 1.0, 0.0, 0.0);
    // een cyliner tekenen
    gluCylinder(qObj,dikte,dikte,Engine[1].AsLengte,8,1);
  glPopMatrix();
  //--- een hulp-lijn tekenen door de motor-as
  glPushMatrix();
    glColor3f(0.8, 1.0, 0.8);
    A := AddVector(punt1, CreateVector(0.0, -hulplijn_Onder, 0.0));
    B := AddVector(punt1, CreateVector(0.0, hulplijn_Boven+Engine[1].AsLengte, 0.0));
    DrawLine(A,B, 3,$3333);
  glPopMatrix();


  //--- De motor rechts-achter tekenen -----------------------------------------
  // rood materiaal kiezen
  SetupMaterial(rood);
  glPushMatrix();
    glTranslatef( punt2.X, punt2.Y, punt2.Z );
    glRotatef(-90.0, 1.0, 0.0, 0.0);
    // een cyliner tekenen
    gluCylinder(qObj,dikte,dikte,Engine[2].AsLengte,8,1);
  glPopMatrix();
  //--- een hulp-lijn tekenen door de motor-as
  glPushMatrix();
    glColor3f(1.0, 0.8, 0.8);
    A := AddVector(punt2, CreateVector(0.0, -hulplijn_Onder, 0.0));
    B := AddVector(punt2, CreateVector(0.0, hulplijn_Boven+Engine[2].AsLengte, 0.0));
    DrawLine(A,B, 3,$3333);
  glPopMatrix();

  glEnable(GL_CULL_FACE);
end;


// De positie van de motoren herberekenen als de stoel beweegt
procedure RecalculateEngines;
var delta0, delta1, delta2: single;
begin
  // Het links/rechtsom kantelen.
  // Bij een positieve hoek moet motor2 (rood, rechts) omhoog en M1 omlaag.
  // De motoren achter (M1 & M2) staan 45 cm uit elkaar; De helft = 22.5 cm. (kantelpunt)
  // Er geldt: afstand omhoog/omlaag = tan(Stoel_Rotation[2])*22.5cm
  delta2 := tan(DegToRad(Stoel_Rotation.Z))*0.225;
  delta1 := -delta2;

  // Het voor/achterover kantelen.
  // Bij een positieve hoek moet motor0 (voor) omhoog en M1 & M2 omlaag.
  // De motoren voor en achter (M0 & M1/M2) staan boven 28 cm uit elkaar;
  // De helft = 14 cm. (kantelpunt)
  // Er geldt: afstand omhoog/omlaag = tan(Stoel_Rotation[0])*14cm
  delta0 := tan(DegToRad(Stoel_Rotation.X))*0.14;
  delta1 := delta1 - delta0;
  delta2 := delta2 - delta0;

  // De motor-standen aanpassen
  Engine[0].AsLengte := Engine[0].AsLengteRuststand + delta0;
  Engine[1].AsLengte := Engine[1].AsLengteRuststand + delta1;
  Engine[2].AsLengte := Engine[2].AsLengteRuststand + delta2;
end;


end.


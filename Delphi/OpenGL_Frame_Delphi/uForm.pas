unit uForm;
interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs,
  OpenGL, ExtCtrls, AppEvnts;

{$J+} //Typed-Constants gebruik toestaan

{--- Perspectief parameters ---------------------------------------------------}
const
  NearDistance : GLFloat = 0.1;     // near plane
  ViewDistance : GLFloat = 5.0;     // far plane
  FOV          : GLFloat = 60.0;    // hoek van FOV voor camera (blz 126)
  AspectRatio  : GLFloat = 300/300; // verhouding Width & Height van het scherm



{--- Form-class ---------------------------------------------------------------}
type
  TfGL = class(TForm)
    pGL: TPanel;
    pControls: TPanel;
    ApplicationEvents: TApplicationEvents;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pGLResize(Sender: TObject);
    procedure ApplicationEventsIdle(Sender: TObject; var Done: Boolean);      //OpenGL-panel resize
  private
    {De handles naar het window, de Device- & Render-Context}
    HandleWnd : HWND;
    HandleDC : HDC;
    HandleRC : HGLRC;
  public
    procedure OpenGL_Initialize;  {OpenGL activeren in het panel}
    procedure OpenGL_Finalize;    {OpenGL deactiveren voor het venster}
    procedure AppGL_Setup;        {OpenGL instellingen voor dit programma}
    procedure AppGL_Paint;        {De paint-routine voor deze applicatie}
    procedure AppGL_Resize;       {De resize-routine voor deze applicatie}
  end;

var
  fGL: TfGL;



implementation
{$R *.dfm}

{--- OpenGL -------------------------------------------------------------------}
procedure TfGL.OpenGL_Initialize;
var PFD : TPIXELFORMATDESCRIPTOR;
    PixelFormat : GLint;
begin
  {De handle naar de Device-Context bepalen}
  HandleWnd := pGL.Handle;  // De window-handle van het panel
  HandleDC := GetDC(HandleWnd);
  if HandleDC = 0 then begin
    ShowMessage('Er is geen handle naar de Device-Context !!');
    halt(1);
  end;

  {Een te gebruiken pixelformat beschrijven}
  ZeroMemory(@PFD, SizeOf(PIXELFORMATDESCRIPTOR));
  with PFD do begin
    nSize := SizeOf(PIXELFORMATDESCRIPTOR);
    nVersion := 1;
    dwFlags := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
    iPixelType := PFD_TYPE_RGBA;
    cColorBits := 32;  // 32-bit kleurdiepte
    cDepthBits := 16;  // 16-bit Z-buffer
    iLayerType := PFD_MAIN_PLANE;
  end;

  {Probeer het beste pixelformat te vinden welke deze Device-Context ondersteund.
   En wat het meest overeenkomt met het opgegeven pixelformat}
  PixelFormat := ChoosePixelFormat(HandleDC, @PFD);
  if PixelFormat = 0 then begin
    ShowMessage('Er kan geen PixelFormat vastgesteld worden voor de Device-Context !!');
    halt(2);
  end;

  {Stel het PixelFormat van de Device-Context in op het gevonden PixelFormat}
  if (not SetPixelFormat(HandleDC, PixelFormat, @PFD)) then begin
    ShowMessage('Het gekozen PixelFormat kan niet ingesteld worden voor de Device-Context !!');
    halt(3);
  end;

  {Een Render-Context maken voor OpenGL}
  HandleRC := wglCreateContext(HandleDC);
  if HandleRC = 0 then begin
    ShowMessage('Er kan geen Render-Context gemaakt worden voor de Device-Context !!');
    halt(4);
  end;

  {De Render-Context actief maken als huidige OpenGL-RC}
  if (not wglMakeCurrent(HandleDC, HandleRC)) then begin
    ShowMessage('De Render-Context kan niet gebruikt worden door OpenGL !!');
    halt(4);
  end;
end;


procedure TfGL.OpenGL_Finalize;
begin
  {Geen enkele Render-Context als huidige instellen tijdens wissen van een RC}
  if (not wglMakeCurrent(HandleDC, 0)) then begin
    ShowMessage('De Render-Context kan niet inactief worden gemaakt !!');
    {halt(5);}
  end;

  {De Render-Context vrijgeven/wissen}
  if (not wglDeleteContext(HandleRC)) then begin
    ShowMessage('De Render-Context kan niet worden vrijgegeven !!');
    HandleRC := 0;
    {halt(6);}
  end;

  {De Device-Context vrijgeven/wissen}
  if ((HandleDC > 0) and (ReleaseDC(HandleWnd, HandleDC) = 0)) then begin
    ShowMessage('De Device-Context kan niet worden vrijgegeven !!');
    HandleDC := 0;
    {halt(7);}
  end;
end;





{--- Applicatie ---------------------------------------------------------------}
procedure TfGL.AppGL_Setup;
begin
  // Geen alpha kanaal gebruiken, alleen RGB
  glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_FALSE);
  // Een zwarte achtergrond-kleur gebruiken
  glClearColor(0.0, 0.0, 0.0, 0.0);

  // De Z-buffer voor diepte
  glDepthFunc(GL_LESS);
  glDepthRange(0.0, 1.0);
  glDepthMask(GL_TRUE);
  glEnable(GL_DEPTH_TEST);

  // Backface-culling
  glFrontFace(GL_CCW);
  glCullFace(GL_BACK);
  glEnable(GL_CULL_FACE);
(*
  glDisable(GL_BLEND);
  glEnable(GL_NORMALIZE); // bij deze kleine 3D-scene mag het wel, toch snel genoeg dan....
*)
end;


procedure TfGL.AppGL_Resize;
begin
  AspectRatio := pGL.Width/pGL.Height;
  glViewport(0,0,pGL.Width,pGL.Height);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  gluPerspective(FOV, AspectRatio, NearDistance, ViewDistance);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  // Het scherm opnieuw afbeelden tijdens een resize van het form
  AppGL_Paint;
end;


procedure TfGL.AppGL_Paint;
begin
  // het scherm wissen
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  //teken de hele scene


  // display-buffers wisselen
  glFlush();
  SwapBuffers(HandleDC);
end;





{--- Form ---------------------------------------------------------------------}
procedure TfGL.FormCreate(Sender: TObject);
begin
  OpenGL_Initialize;
end;


procedure TfGL.FormShow(Sender: TObject);
begin
  AppGL_Setup;
end;


procedure TfGL.FormPaint(Sender: TObject);
begin
  AppGL_Paint;
end;


procedure TfGL.FormDestroy(Sender: TObject);
begin
  OpenGL_Finalize;
end;


procedure TfGL.pGLResize(Sender: TObject);
begin
  AppGL_Resize;
end;






{--- Application Events -------------------------------------------------------}
procedure TfGL.ApplicationEventsIdle(Sender: TObject; var Done: Boolean);
begin
  AppGL_Paint;
end;

end.

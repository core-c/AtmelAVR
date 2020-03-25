program Blending;
uses
  OpenGL12 in 'OpenGL12.pas',
  GLUT in 'GLUT.pas',
  u3DCalc in 'u3DCalc.pas',
  Unit2 in 'Unit2.pas',
  uTexture in 'uTexture.pas';

begin
  InitOpenGLFromLibrary('OpenGL32.dll', 'GLu32.dll');
{  glutInit(ParamCount, CmdLine);}
  glutInitDisplayMode(GLUT_DOUBLE or GLUT_RGB);
  glutInitWindowSize(300,300);
  glutInitWindowPosition(100,100);
  glutCreateWindow('De OpenGL Stoel....');
  init;
  glutDisplayFunc( display );
  glutReshapeFunc( reshape );
  glutSpecialFunc( special );
  glutKeyboardFunc( keyboard );
  glutMouseFunc( mouse );
  glutMotionFunc( motion );
  glutJoystickFunc( joystick, 100 );
  {glutTimerFunc( 100, timer, 0);}
  glutMainLoop();
  halt(0);
end.


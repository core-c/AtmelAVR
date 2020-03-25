unit GLUT;
interface
uses
  OpenGL12;

(* Copyright (c) Mark J. Kilgard, 1994, 1995, 1996, 1998.

   This program is freely distributable without licensing fees  and is
   provided without guarantee or warrantee expressed or  implied. This
   program is -not- in the public domain. *)

(* GLUT 3.7 now tries to avoid including <windows.h>
   to avoid name space pollution, but Win32's <GL/gl.h>
   needs APIENTRY and WINGDIAPI defined properly. *)

type wchar_t = Char;
   {$define _WCHAR_T_DEFINED}


type TglutDisplayProc = procedure; stdcall;
     TglutReshapeProc = procedure(width, height: GLint); stdcall;
     TglutKeyboardProc = procedure(key : char; x, y: GLint); stdcall;
     TglutMouseProc = procedure(button, state, x, y: GLint); stdcall;
     TglutMotionProc = procedure(x, y: GLint); stdcall;
     TglutPassiveMotionProc = procedure(x, y: GLint); stdcall;
     TglutEntryProc = procedure(state: GLint); stdcall;
     TglutVisibilityProc = procedure(state: GLint); stdcall;
     TglutIdleProc = procedure; stdcall;
     TglutTimerProc = procedure(value: GLint); stdcall;
     TglutMenuStateProc = procedure(state: GLint); stdcall;
     TglutSpecialProc = procedure(key, x, y: GLint); stdcall;
     TglutSpaceballMotionProc = procedure(x, y, z: GLint); stdcall;
     TglutSpaceballRotateProc = procedure(x, y, z: GLint); stdcall;
     TglutSpaceballButtonProc = procedure(button, state: GLint); stdcall;
     TglutButtonBoxProc = procedure(button, state: GLint); stdcall;
     TglutDialsProc = procedure(dial, value: GLint); stdcall;
     TglutTabletMotionProc = procedure(x, y: GLint); stdcall;
     TglutTabletButtonProc = procedure(button, state, x, y: GLint); stdcall;
     TglutMenuStatusProc = procedure(status, x, y: GLint); stdcall;
     TglutOverlayDisplayProc = procedure; stdcall;
     TglutWindowStatusProc = procedure(state: GLint); stdcall;
     TglutKeyboardUpProc = procedure(key: Char; x, y: GLint); stdcall;
     TglutSpecialUpProc = procedure(key, x, y: GLint); stdcall;
     TglutJoystickProc = procedure(buttonMask: GLUint; x, y, z: GLint); stdcall;







const
// {$ ifndef GLUT_API_VERSION}  { allow this to be overriden }
   GLUT_API_VERSION =         3;
// {$ endif}

// {$ ifndef GLUT_XLIB_IMPLEMENTATION}  { Allow this to be overriden. }
   GLUT_XLIB_IMPLEMENTATION = 13;
// {$ endif}

{ Display mode bit masks. }
  GLUT_RGB          =         0;
  GLUT_RGBA         =         GLUT_RGB;
  GLUT_INDEX        =         1;
  GLUT_SINGLE       =         0;
  GLUT_DOUBLE       =         2;
  GLUT_ACCUM        =         4;
  GLUT_ALPHA        =         8;
  GLUT_DEPTH        =         16;
  GLUT_STENCIL      =         32;
{ if (GLUT_API_VERSION >= 2) }
  GLUT_MULTISAMPLE  =         128;
  GLUT_STEREO	    =         256;
{ endif }
{ if (GLUT_API_VERSION >= 3) }
  GLUT_LUMINANCE    =         512;
{ endif }

{ Mouse buttons. }
  GLUT_LEFT_BUTTON  =         0;
  GLUT_MIDDLE_BUTTON =        1;
  GLUT_RIGHT_BUTTON =         2;

{ Mouse button  state. }
  GLUT_DOWN         = 0;
  GLUT_UP	    = 1;

{ if (GLUT_API_VERSION >= 2) }
{ function keys }
  GLUT_KEY_F1	    = 1;
  GLUT_KEY_F2	    = 2;
  GLUT_KEY_F3	    = 3;
  GLUT_KEY_F4	    = 4;
  GLUT_KEY_F5	    = 5;
  GLUT_KEY_F6	    = 6;
  GLUT_KEY_F7	    = 7;
  GLUT_KEY_F8	    = 8;
  GLUT_KEY_F9	    = 9;
  GLUT_KEY_F10	    = 10;
  GLUT_KEY_F11	    = 11;
  GLUT_KEY_F12	    = 12;
{ directional keys }
  GLUT_KEY_LEFT	    = 100;
  GLUT_KEY_UP	    = 101;
  GLUT_KEY_RIGHT    = 102;
  GLUT_KEY_DOWN	    = 103;
  GLUT_KEY_PAGE_UP  = 104;
  GLUT_KEY_PAGE_DOWN = 105;
  GLUT_KEY_HOME	    = 106;
  GLUT_KEY_END	    = 107;
  GLUT_KEY_INSERT   = 108;
{ endif }

{ Entry/exit  state. }
  GLUT_LEFT	    = 0;
  GLUT_ENTERED	    = 1;

{ Menu usage  state. }
  GLUT_MENU_NOT_IN_USE = 0;
  GLUT_MENU_IN_USE     = 1;

{ Visibility  state. }
  GLUT_NOT_VISIBLE = 0;
  GLUT_VISIBLE	   = 1;

{ Window status  state. }
  GLUT_HIDDEN =         	0;
  GLUT_FULLY_RETAINED =	        1;
  GLUT_PARTIALLY_RETAINED =	2;
  GLUT_FULLY_COVERED =		3;

{/* Color index component selection values. */}
  GLUT_RED =			0;
  GLUT_GREEN =			1;
  GLUT_BLUE =			2;

{/* Layers for use. */}
  GLUT_NORMAL =			0;
  GLUT_OVERLAY =		1;












//      #if defined(_WIN32)
//      /* Stroke font constants (use these in GLUT program). */
//      #define GLUT_STROKE_ROMAN		((void*)0)
//      #define GLUT_STROKE_MONO_ROMAN		((void*)1)
//
//      /* Bitmap font constants (use these in GLUT program). */
//      #define GLUT_BITMAP_9_BY_15		((void*)2)
//      #define GLUT_BITMAP_8_BY_13		((void*)3)
//      #define GLUT_BITMAP_TIMES_ROMAN_10	((void*)4)
//      #define GLUT_BITMAP_TIMES_ROMAN_24	((void*)5)
//       #if (GLUT_API_VERSION >= 3)
//       #define GLUT_BITMAP_HELVETICA_10	((void*)6)
//       #define GLUT_BITMAP_HELVETICA_12	((void*)7)
//       #define GLUT_BITMAP_HELVETICA_18	((void*)8)
//       #endif
//      #else
//      /* Stroke font opaque addresses (use constants instead in source code). */
//      extern void *glutStrokeRoman;
//      extern void *glutStrokeMonoRoman;
//
//      /* Stroke font constants (use these in GLUT program). */
//      #define GLUT_STROKE_ROMAN		(&glutStrokeRoman)
//      #define GLUT_STROKE_MONO_ROMAN		(&glutStrokeMonoRoman)
//
//      /* Bitmap font opaque addresses (use constants instead in source code). */
//      extern void *glutBitmap9By15;
//      extern void *glutBitmap8By13;
//      extern void *glutBitmapTimesRoman10;
//      extern void *glutBitmapTimesRoman24;
//      extern void *glutBitmapHelvetica10;
//      extern void *glutBitmapHelvetica12;
//      extern void *glutBitmapHelvetica18;
//
//      /* Bitmap font constants (use these in GLUT program). */
//      #define GLUT_BITMAP_9_BY_15		(&glutBitmap9By15)
//      #define GLUT_BITMAP_8_BY_13		(&glutBitmap8By13)
//      #define GLUT_BITMAP_TIMES_ROMAN_10	(&glutBitmapTimesRoman10)
//      #define GLUT_BITMAP_TIMES_ROMAN_24	(&glutBitmapTimesRoman24)
//        #if (GLUT_API_VERSION >= 3)
//        #define GLUT_BITMAP_HELVETICA_10	(&glutBitmapHelvetica10)
//        #define GLUT_BITMAP_HELVETICA_12	(&glutBitmapHelvetica12)
//        #define GLUT_BITMAP_HELVETICA_18	(&glutBitmapHelvetica18)
//        #endif
//      #endif








const
{/* glutGet parameters. */}
  GLUT_WINDOW_X	=	           	100;
  GLUT_WINDOW_Y =			101;
  GLUT_WINDOW_WIDTH =                   102;
  GLUT_WINDOW_HEIGHT =                  103;
  GLUT_WINDOW_BUFFER_SIZE =		104;
  GLUT_WINDOW_STENCIL_SIZE =            105;
  GLUT_WINDOW_DEPTH_SIZE =		106;
  GLUT_WINDOW_RED_SIZE =		107;
  GLUT_WINDOW_GREEN_SIZE =		108;
  GLUT_WINDOW_BLUE_SIZE	=               109;
  GLUT_WINDOW_ALPHA_SIZE =		110;
  GLUT_WINDOW_ACCUM_RED_SIZE =          111;
  GLUT_WINDOW_ACCUM_GREEN_SIZE =	112;
  GLUT_WINDOW_ACCUM_BLUE_SIZE =         113;
  GLUT_WINDOW_ACCUM_ALPHA_SIZE =	114;
  GLUT_WINDOW_DOUBLEBUFFER =            115;
  GLUT_WINDOW_RGBA =       		116;
  GLUT_WINDOW_PARENT =                  117;
  GLUT_WINDOW_NUM_CHILDREN =            118;
  GLUT_WINDOW_COLORMAP_SIZE =           119;
{ if (GLUT_API_VERSION >= 2)}
  GLUT_WINDOW_NUM_SAMPLES =		120;
  GLUT_WINDOW_STEREO =                  121;
{ endif }
{ if (GLUT_API_VERSION >= 3) }
  GLUT_WINDOW_CURSOR =    		122;
{ endif }
  GLUT_SCREEN_WIDTH =                   200;
  GLUT_SCREEN_HEIGHT =                  201;
  GLUT_SCREEN_WIDTH_MM =                202;
  GLUT_SCREEN_HEIGHT_MM	=               203;
  GLUT_MENU_NUM_ITEMS = 		300;
  GLUT_DISPLAY_MODE_POSSIBLE =          400;
  GLUT_INIT_WINDOW_X =       		500;
  GLUT_INIT_WINDOW_Y =                  501;
  GLUT_INIT_WINDOW_WIDTH =		502;
  GLUT_INIT_WINDOW_HEIGHT =		503;
  GLUT_INIT_DISPLAY_MODE =		504;
{ if (GLUT_API_VERSION >= 2) }
  GLUT_ELAPSED_TIME =     		700;
{ endif }

{ if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 13) }
  GLUT_WINDOW_FORMAT_ID	=         	123;
{ endif }


{ if (GLUT_API_VERSION >= 2) }
{/* glutDeviceGet parameters. */}
  GLUT_HAS_KEYBOARD =		        600;
  GLUT_HAS_MOUSE =		        601;
  GLUT_HAS_SPACEBALL =		        602;
  GLUT_HAS_DIAL_AND_BUTTON_BOX =	603;
  GLUT_HAS_TABLET	=		604;
  GLUT_NUM_MOUSE_BUTTONS =	        605;
  GLUT_NUM_SPACEBALL_BUTTONS =	        606;
  GLUT_NUM_BUTTON_BOX_BUTTONS =	        607;
  GLUT_NUM_DIALS =		        608;
  GLUT_NUM_TABLET_BUTTONS =             609;
{ endif }


{ if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 13) }
 GLUT_DEVICE_IGNORE_KEY_REPEAT =        610;
 GLUT_DEVICE_KEY_REPEAT =               611;
 GLUT_HAS_JOYSTICK =		        612;
 GLUT_OWNS_JOYSTICK =		        613;
 GLUT_JOYSTICK_BUTTONS =		614;
 GLUT_JOYSTICK_AXES =	              	615;
 GLUT_JOYSTICK_POLL_RATE =		616;
{ endif }


{ if (GLUT_API_VERSION >= 3) }
{/* glutLayerGet parameters. */}
  GLUT_OVERLAY_POSSIBLE =       800;
  GLUT_LAYER_IN_USE =		801;
  GLUT_HAS_OVERLAY =		802;
  GLUT_TRANSPARENT_INDEX =      803;
  GLUT_NORMAL_DAMAGED =		804;
  GLUT_OVERLAY_DAMAGED =	805;

{ if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 9) }
    {/* glutVideoResizeGet parameters. */}
     GLUT_VIDEO_RESIZE_POSSIBLE	=       900;
     GLUT_VIDEO_RESIZE_IN_USE =	        901;
     GLUT_VIDEO_RESIZE_X_DELTA =	902;
     GLUT_VIDEO_RESIZE_Y_DELTA =	903;
     GLUT_VIDEO_RESIZE_WIDTH_DELTA =	904;
     GLUT_VIDEO_RESIZE_HEIGHT_DELTA =	905;
     GLUT_VIDEO_RESIZE_X =		906;
     GLUT_VIDEO_RESIZE_Y =		907;
     GLUT_VIDEO_RESIZE_WIDTH =		908;
     GLUT_VIDEO_RESIZE_HEIGHT =         909;
{ endif }

{/* glutUseLayer parameters. */}
//  GLUT_NORMAL =                 0;
//  GLUT_OVERLAY =                1;

{/* glutGetModifiers return mask. */}
  GLUT_ACTIVE_SHIFT =           1;
  GLUT_ACTIVE_CTRL =            2;
  GLUT_ACTIVE_ALT =             4;

{/* glutSetCursor parameters. */}
{/* Basic arrows. */}
  GLUT_CURSOR_RIGHT_ARROW =		0;
  GLUT_CURSOR_LEFT_ARROW =		1;
{/* Symbolic cursor shapes. */}
  GLUT_CURSOR_INFO =        		2;
  GLUT_CURSOR_DESTROY =         	3;
  GLUT_CURSOR_HELP =            	4;
  GLUT_CURSOR_CYCLE =           	5;
  GLUT_CURSOR_SPRAY =           	6;
  GLUT_CURSOR_WAIT =            	7;
  GLUT_CURSOR_TEXT =            	8;
  GLUT_CURSOR_CROSSHAIR	=       	9;
{/* Directional cursors. */}
  GLUT_CURSOR_UP_DOWN =  		10;
  GLUT_CURSOR_LEFT_RIGHT =		11;
{/* Sizing cursors. */}
  GLUT_CURSOR_TOP_SIDE =		12;
  GLUT_CURSOR_BOTTOM_SIDE =		13;
  GLUT_CURSOR_LEFT_SIDE	=               14;
  GLUT_CURSOR_RIGHT_SIDE =		15;
  GLUT_CURSOR_TOP_LEFT_CORNER =         16;
  GLUT_CURSOR_TOP_RIGHT_CORNER =	17;
  GLUT_CURSOR_BOTTOM_RIGHT_CORNER =	18;
  GLUT_CURSOR_BOTTOM_LEFT_CORNER =	19;
{/* Inherit from parent window. */}
  GLUT_CURSOR_INHERIT =		100;
{/* Blank cursor. */}
  GLUT_CURSOR_NONE =		101;
{/* Fullscreen crosshair (if available). */}
  GLUT_CURSOR_FULL_CROSSHAIR =	102;
{ endif }





const GLut32 = 'GLut32.dll';

{/* GLUT initialization sub-API. */}
procedure glutInit(argcp: pGLint; const argv); STDCALL; EXTERNAL GLut32;
procedure glutInitDisplayMode(mode: word); STDCALL; EXTERNAL GLut32;
{ if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 9) }
procedure glutInitDisplayString(const stringy: PChar); STDCALL; EXTERNAL GLut32;
{ endif }
procedure glutInitWindowPosition(x, y: GLint); STDCALL; EXTERNAL GLut32;
procedure glutInitWindowSize(width, height: GLint); STDCALL; EXTERNAL GLut32;
procedure glutMainLoop(); STDCALL; EXTERNAL GLut32;

{/* GLUT window sub-API. */}
function glutCreateWindow(const title: PChar): GLint; STDCALL; EXTERNAL GLut32;
function glutCreateSubWindow(win, x, y, width, height: GLint): GLint; STDCALL; EXTERNAL GLut32;
procedure glutDestroyWindow(win: GLint); STDCALL; EXTERNAL GLut32;
procedure glutPostRedisplay(); STDCALL; EXTERNAL GLut32;
{ if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 11) }
procedure glutPostWindowRedisplay(win: GLint); STDCALL; EXTERNAL GLut32;
{ endif }
procedure glutSwapBuffers(); STDCALL; EXTERNAL GLut32;
function glutGetWindow(): GLint; STDCALL; EXTERNAL GLut32;
procedure glutSetWindow(win: GLint); STDCALL; EXTERNAL GLut32;
procedure glutSetWindowTitle(const title: PChar); STDCALL; EXTERNAL GLut32;
procedure glutSetIconTitle(const title: PChar); STDCALL; EXTERNAL GLut32;
procedure glutPositionWindow(x, y: GLint); STDCALL; EXTERNAL GLut32;
procedure glutReshapeWindow(width, height: GLint); STDCALL; EXTERNAL GLut32;
procedure glutPopWindow(); STDCALL; EXTERNAL GLut32;
procedure glutPushWindow(); STDCALL; EXTERNAL GLut32;
procedure glutIconifyWindow(); STDCALL; EXTERNAL GLut32;
procedure glutShowWindow(); STDCALL; EXTERNAL GLut32;
procedure glutHideWindow(); STDCALL; EXTERNAL GLut32;
{ if (GLUT_API_VERSION >= 3) }
procedure glutFullScreen(); STDCALL; EXTERNAL GLut32;
procedure glutSetCursor(cursor: GLint); STDCALL; EXTERNAL GLut32;
{ if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 9) }
procedure glutWarpPointer(x, y: GLint); STDCALL; EXTERNAL GLut32;
{ endif }
{/* GLUT overlay sub-API. */}
procedure glutEstablishOverlay(); STDCALL; EXTERNAL GLut32;
procedure glutRemoveOverlay(); STDCALL; EXTERNAL GLut32;
procedure glutUseLayer(layer: GLenum); STDCALL; EXTERNAL GLut32;
procedure glutPostOverlayRedisplay(); STDCALL; EXTERNAL GLut32;
{ if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 11) }
procedure glutPostWindowOverlayRedisplay(win: GLint); STDCALL; EXTERNAL GLut32;
{ endif }
procedure glutShowOverlay(); STDCALL; EXTERNAL GLut32;
procedure glutHideOverlay(); STDCALL; EXTERNAL GLut32;
{ endif }

{/* GLUT menu sub-API. */}
function glutCreateMenu(): GLint; STDCALL; EXTERNAL GLut32;     {!!! debug !!!}
procedure glutDestroyMenu(menu: GLint); STDCALL; EXTERNAL GLut32;
function glutGetMenu(): GLint; STDCALL; EXTERNAL GLut32;
procedure glutSetMenu(menu: GLint); STDCALL; EXTERNAL GLut32;
procedure glutAddMenuEntry(const llabel: PChar; value: GLint); STDCALL; EXTERNAL GLut32;
procedure glutAddSubMenu(const llabel: PChar; submenu: GLint); STDCALL; EXTERNAL GLut32;
procedure glutChangeToMenuEntry(item: GLint; const llabel: PChar; value: GLint); STDCALL; EXTERNAL GLut32;
procedure glutChangeToSubMenu(item: GLint; const llabel: PChar; submenu: GLint); STDCALL; EXTERNAL GLut32;
procedure glutRemoveMenuItem(item: GLint); STDCALL; EXTERNAL GLut32;
procedure glutAttachMenu(button: GLint); STDCALL; EXTERNAL GLut32;
procedure glutDetachMenu(button: GLint); STDCALL; EXTERNAL GLut32;


{/* GLUT window callback sub-API. */}
procedure glutDisplayFunc(fn: TglutDisplayProc); STDCALL; EXTERNAL GLut32;
procedure glutReshapeFunc(fn: TglutReshapeProc); STDCALL; EXTERNAL GLut32;
procedure glutKeyboardFunc(fn: TglutKeyboardProc); STDCALL; EXTERNAL GLut32;
procedure glutMouseFunc(fn: TglutMouseProc); STDCALL; EXTERNAL GLut32;
procedure glutMotionFunc(fn: TglutMotionProc); STDCALL; EXTERNAL GLut32;
procedure glutPassiveMotionFunc(fn: TglutPassiveMotionProc); STDCALL; EXTERNAL GLut32;
procedure glutEntryFunc(fn: TglutEntryProc); STDCALL; EXTERNAL GLut32;
procedure glutVisibilityFunc(fn: TglutVisibilityProc); STDCALL; EXTERNAL GLut32;
procedure glutIdleFunc(fn: TglutIdleProc); STDCALL; EXTERNAL GLut32;
procedure glutTimerFunc(millis: GLUint; fn: TglutTimerProc; value: GLint); STDCALL; EXTERNAL GLut32;
procedure glutMenuStateFunc(fn: TglutMenuStateProc); STDCALL; EXTERNAL GLut32;
{ if (GLUT_API_VERSION >= 2) }
procedure glutSpecialFunc(fn: TglutSpecialProc); STDCALL; EXTERNAL GLut32;
procedure glutSpaceballMotionFunc(fn: TglutSpaceballMotionProc); STDCALL; EXTERNAL GLut32;
procedure glutSpaceballRotateFunc(fn: TglutSpaceballRotateProc); STDCALL; EXTERNAL GLut32;
procedure glutSpaceballButtonFunc(fn: TglutSpaceballButtonProc); STDCALL; EXTERNAL GLut32;
procedure glutButtonBoxFunc(fn: TglutButtonBoxProc); STDCALL; EXTERNAL GLut32;
procedure glutDialsFunc(fn: TglutDialsProc); STDCALL; EXTERNAL GLut32;
procedure glutTabletMotionFunc(fn: TglutTabletMotionProc); STDCALL; EXTERNAL GLut32;
procedure glutTabletButtonFunc(fn: TglutTabletButtonProc); STDCALL; EXTERNAL GLut32;
{ if (GLUT_API_VERSION >= 3) }
procedure glutMenuStatusFunc(fn: TglutMenuStatusProc); STDCALL; EXTERNAL GLut32;
procedure glutOverlayDisplayFunc(fn: TglutOverlayDisplayProc); STDCALL; EXTERNAL GLut32;
{ if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 9) }
procedure glutWindowStatusFunc(fn: TglutWindowStatusProc); STDCALL; EXTERNAL GLut32;
{ endif }
{ if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 13) }
procedure glutKeyboardUpFunc(fn: TglutKeyboardUpProc); STDCALL; EXTERNAL GLut32;
procedure glutSpecialUpFunc(fn: TglutSpecialUpProc); STDCALL; EXTERNAL GLut32;
procedure glutJoystickFunc(fn: TglutJoystickProc; pollInterval: GLint); STDCALL; EXTERNAL GLut32;
{ endif }
{ endif }
{ endif }


{/* GLUT color index sub-API. */}
procedure glutSetColor(dummy: GLint; red, green, blue: GLfloat); STDCALL; EXTERNAL GLut32;
function glutGetColor(ndx, component: GLint): GLfloat; STDCALL; EXTERNAL GLut32;
procedure glutCopyColormap(win: GLint); STDCALL; EXTERNAL GLut32;

{/* GLUT state retrieval sub-API. */}
function glutGet(gtype: GLenum): GLint; STDCALL; EXTERNAL GLut32;
function glutDeviceGet(gdtype: GLenum): GLint; STDCALL; EXTERNAL GLut32;
{ if (GLUT_API_VERSION >= 2) }
{/* GLUT extension support sub-API */}
function glutExtensionSupported(const name: PChar): GLint; STDCALL; EXTERNAL GLut32;
{ endif }
{ if (GLUT_API_VERSION >= 3) }
function glutGetModifiers(): GLint; STDCALL; EXTERNAL GLut32;
function glutLayerGet(Ltype: GLenum): GLint; STDCALL; EXTERNAL GLut32;
{ endif }

{/* GLUT font sub-API */}
procedure glutBitmapCharacter(const pointer; character: GLint); STDCALL; EXTERNAL GLut32;
function glutBitmapWidth(const pointer; character: GLint): GLint; STDCALL; EXTERNAL GLut32;
procedure glutStrokeCharacter(const pointer; character: GLint); STDCALL; EXTERNAL GLut32;
function glutStrokeWidth(const pointer; character: GLint): GLint; STDCALL; EXTERNAL GLut32;
{ if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 9) }
function glutBitmapLength(const pointer; const Bstring: PChar): GLint; STDCALL; EXTERNAL GLut32;
function glutStrokeLength(const pointer; const Bstring: PChar): GLint; STDCALL; EXTERNAL GLut32;
{ endif }

{/* GLUT pre-built models sub-API */}
procedure glutWireSphere(radius: GLdouble; slices, stacks: GLint); STDCALL; EXTERNAL GLut32;
procedure glutSolidSphere(radius: GLdouble; slices, stacks: GLint); STDCALL; EXTERNAL GLut32;
procedure glutWireCone(base, height: GLdouble; slices, stacks: GLint); STDCALL; EXTERNAL GLut32;
procedure glutSolidCone(base, height: GLdouble; slices, stacks: GLint); STDCALL; EXTERNAL GLut32;
procedure glutWireCube(size: GLdouble); STDCALL; EXTERNAL GLut32;
procedure glutSolidCube(size: GLdouble); STDCALL; EXTERNAL GLut32;
procedure glutWireTorus(innerRadius, outerRadius: GLdouble; sides, rings: GLint); STDCALL; EXTERNAL GLut32;
procedure glutSolidTorus(innerRadius, outerRadius: GLdouble; sides, rings: GLint); STDCALL; EXTERNAL GLut32;
procedure glutWireDodecahedron(); STDCALL; EXTERNAL GLut32;
procedure glutSolidDodecahedron(); STDCALL; EXTERNAL GLut32;
procedure glutWireTeapot(size: GLdouble); STDCALL; EXTERNAL GLut32;
procedure glutSolidTeapot(size: GLdouble); STDCALL; EXTERNAL GLut32;
procedure glutWireOctahedron(); STDCALL; EXTERNAL GLut32;
procedure glutSolidOctahedron(); STDCALL; EXTERNAL GLut32;
procedure glutWireTetrahedron(); STDCALL; EXTERNAL GLut32;
procedure glutSolidTetrahedron(); STDCALL; EXTERNAL GLut32;
procedure glutWireIcosahedron(); STDCALL; EXTERNAL GLut32;
procedure glutSolidIcosahedron(); STDCALL; EXTERNAL GLut32;

{ if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 9) }
{/* GLUT video resize sub-API. */}
function glutVideoResizeGet(param: GLenum): GLint; STDCALL; EXTERNAL GLut32;
procedure glutSetupVideoResizing(); STDCALL; EXTERNAL GLut32;
procedure glutStopVideoResizing(); STDCALL; EXTERNAL GLut32;
procedure glutVideoResize(x, y, width, height: GLint); STDCALL; EXTERNAL GLut32;
procedure glutVideoPan(x, y, width, height: GLint); STDCALL; EXTERNAL GLut32;
{/* GLUT debugging sub-API. */}
procedure glutReportErrors(); STDCALL; EXTERNAL GLut32;
{ endif }


const
{ if (GLUT_API_VERSION >= 4 || GLUT_XLIB_IMPLEMENTATION >= 13) }
{/* GLUT device control sub-API. */}
{/* glutSetKeyRepeat modes. */}
  GLUT_KEY_REPEAT_OFF =		0;
  GLUT_KEY_REPEAT_ON =		1;
  GLUT_KEY_REPEAT_DEFAULT =	2;

{/* Joystick button masks. */}
  GLUT_JOYSTICK_BUTTON_A =	1;
  GLUT_JOYSTICK_BUTTON_B =	2;
  GLUT_JOYSTICK_BUTTON_C =	4;
  GLUT_JOYSTICK_BUTTON_D =	8;

procedure glutIgnoreKeyRepeat(ignore: GLint); STDCALL; EXTERNAL GLut32;
procedure glutSetKeyRepeat(repeatMode: GLint); STDCALL; EXTERNAL GLut32;
procedure glutForceJoystickFunc(); STDCALL; EXTERNAL GLut32;

const
{/* GLUT game mode sub-API. */}
{/* glutGameModeGet. */}
  GLUT_GAME_MODE_ACTIVE =          0;
  GLUT_GAME_MODE_POSSIBLE =        1;
  GLUT_GAME_MODE_WIDTH =           2;
  GLUT_GAME_MODE_HEIGHT =          3;
  GLUT_GAME_MODE_PIXEL_DEPTH =     4;
  GLUT_GAME_MODE_REFRESH_RATE =    5;
  GLUT_GAME_MODE_DISPLAY_CHANGED = 6;

procedure glutGameModeString(const GMstring: PChar); STDCALL; EXTERNAL GLut32;
function glutEnterGameMode(): GLint; STDCALL; EXTERNAL GLut32;
procedure glutLeaveGameMode(); STDCALL; EXTERNAL GLut32;
function glutGameModeGet(mode: GLenum): GLint; STDCALL; EXTERNAL GLut32;
{ endif }

{ endif }


IMPLEMENTATION

end.



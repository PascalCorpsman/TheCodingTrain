(******************************************************************************)
(*                                                                            *)
(* Author      : Uwe Schächterle (Corpsman)                                   *)
(*                                                                            *)
(* This file is part of repo "TheCodingTrain"                                 *)
(*                                                                            *)
(*  See the file license.md, located under:                                   *)
(*  https://github.com/PascalCorpsman/Software_Licenses/blob/main/license.md  *)
(*  for details about the license.                                            *)
(*                                                                            *)
(*               It is not allowed to change or remove this text from any     *)
(*               source file of the project.                                  *)
(*                                                                            *)
(******************************************************************************)
Unit Unit1;

{$MODE objfpc}{$H+}
{$DEFINE DebuggMode}

Interface

Uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls,
  OpenGlcontext,
  dglOpenGL,
  ucube3x3,
  uvectormath, lcltype
  ;

Type

  { TForm1 }

  TForm1 = Class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    CheckBox5: TCheckBox;
    CheckBox6: TCheckBox;
    OpenDialog1: TOpenDialog;
    OpenGLControl1: TOpenGLControl;
    SaveDialog1: TSaveDialog;
    Timer1: TTimer;
    Procedure Button1Click(Sender: TObject);
    Procedure Button2Click(Sender: TObject);
    Procedure Button3Click(Sender: TObject);
    Procedure Button4Click(Sender: TObject);
    Procedure Button5Click(Sender: TObject);
    Procedure Button6Click(Sender: TObject);
    Procedure Button7Click(Sender: TObject);
    Procedure Button8Click(Sender: TObject);
    Procedure Button9Click(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure OpenGLControl1MakeCurrent(Sender: TObject; Var Allow: boolean);
    Procedure OpenGLControl1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    Procedure OpenGLControl1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    Procedure OpenGLControl1Paint(Sender: TObject);
    Procedure OpenGLControl1Resize(Sender: TObject);
    Procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    Procedure Render(SelectMode: Boolean);
    Procedure FinishAnimation;
  End;

Const
  ROT_SENSITIVITY = 0.5; // Empfindlichkeit der Maus beim Drehen
  EyeX = 10;
  EyeY = 10;
  EyeZ = 10;
  ver = 1.02;
  AnimSpeed = 2.5;

Var
  Form1: TForm1;
  Initialized: Boolean = false; // Wenn True dann ist OpenGL initialisiert
  Cube: TCube;
  MousePos: TPoint;

Implementation

{$R *.lfm}

{ TForm1 }

Procedure Tform1.FinishAnimation;
Begin
  // Ende Erkannt
  caption := '3d Cube, by Corpsman, ver. ' + FloattostrF(ver, fffixed, 4, 2);
  ProgramState := pswait;
  Button5.Visible := true;
  Button9.Visible := false;
  CheckBox5.Visible := false;
  CheckBox6.Visible := false;
  CheckBox1.visible := true;
  CheckBox2.visible := true;
  showmessage('Now the cube should be solved.');
End;

Var
  allowcnt: Integer = 0;

Procedure TForm1.OpenGLControl1MakeCurrent(Sender: TObject; Var Allow: boolean);
Const
  LAmbient: Array[0..3] Of Single = (1, 1, 1, 1);
  LDiffuse: Array[0..3] Of Single = (1, 1, 1, 1);
  LPos: Array[0..3] Of Single = (eyex, eyey, eyez, 1);
Begin
  If allowcnt > 2 Then Begin
    exit;
  End;
  inc(allowcnt);
  // Sollen Dialoge beim Starten ausgeführt werden ist hier der Richtige Zeitpunkt
  If allowcnt = 1 Then Begin
    // Init dglOpenGL.pas , Teil 2
    ReadExtensions; // Anstatt der Extentions kann auch nur der Core geladen werden. ReadOpenGLCore;
    ReadImplementationProperties;
  End;
  (*
  Man bedenke, jedesmal wenn der Renderingcontext neu erstellt wird, müssen sämtliche Graphiken neu Geladen werden.
  Bei Nutzung der TOpenGLGraphikengine, bedeutet dies, das hier ein clear durchgeführt werden mus !!
  *)
  glEnable(GL_DEPTH_TEST); // Tiefentest
  glDepthFunc(gl_less);
  glEnable(GL_CULL_FACE);
  glCullFace(gl_back); // -- Default
  glPolygonMode(GL_FRONT, GL_FILL); // -- Default
  glClearColor(0.0, 0.0, 0.0, 0.0);
  // Licht
  glLightfv(GL_LIGHT0, GL_AMBIENT, @LAmbient);
  glLightfv(GL_Light1, GL_DIFFUSE, @LDiffuse);
  glLightfv(GL_LIGHT0, GL_POSITION, @Lpos);
  glEnable(GL_LIGHT0);
  // Der Anwendung erlauben zu Rendern.
  Initialized := True;
  OpenGLControl1Resize(Nil);
  Form1.Invalidate;
End;

Procedure TForm1.OpenGLControl1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Var
  c: Integer;
  p: Tpoint;
Begin
  MousePos := point(x, y);
  If (ssright In shift) And Not CheckBox5.checked Then Begin
    Case ProgramState Of
      psMakeFirstLevel, psMakeSecondLevel, psMakeThirdLevel: Begin
          AnimCount := 0;
        End;
    End;
  End;
  // Farbe anpassen
  If (CheckBox2.Checked Or CheckBox1.Checked) And (ProgramState = psWait) Then Begin
    // Rendern des Cubes
    Render(true);
    // Read the Element Color = ID
    glReadPixels(x, OpenGLControl1.height - 1 - y, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, @C);
    // Calculate to RGB
    C := C And $FF;
    // Wenn etwas angeklickt wurde
    Case c Of
      // Auf eine Fläche des Würfels wurde gedrückt
      17..105: Begin
          If CheckBox2.checked Then Begin
            p := ColorToCubePos(c);
            If ssleft In shift Then
              Cube[p.x, p.y] := (Cube[p.x, p.y] + 1) Mod 6
            Else
              Cube[p.x, p.y] := (Cube[p.x, p.y] + 5) Mod 6;
          End;
        End;
      // Auf ein Pfeil wurde gedrückt
      150..168: Begin
          If CheckBox1.checked Then Begin
            StartAutoAnim(IndexToJob(ColorToArrowID(c)));
          End;
        End;
    End;
  End;
End;

Procedure TForm1.OpenGLControl1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
Var
  roty, rotx: single;
Begin
  If (ssleft In shift) Then Begin
    rotY := (x - MousePos.X) * ROT_SENSITIVITY;
    rotX := (y - MousePos.Y) * ROT_SENSITIVITY;
    MousePos := point(x, y);
    glPushMatrix();
    glLoadIdentity();
    glRotatef(rotY, 0.0, 1.0, 0.0);
    If (ssright In Shift) Then
      glRotatef(rotX, 1.0, 0.0, 0.0)
    Else
      glRotatef(-rotx, 0.0, 0.0, 1.0);
    glMultMatrixf(@RotMatrix);
    glGetFloatv(GL_MODELVIEW_MATRIX, @RotMatrix);
    glPopMatrix();
  End;
End;

Procedure Tform1.Render(SelectMode: Boolean);
Var
  b: Boolean;
Begin
  If Not Initialized Then Exit;
  // Licht an oder aus
  glcolor4f(1, 1, 1, 1);
  b := CheckBox3.Checked And (Not SelectMode);
  If b Then Begin
    glEnable(gl_lighting);
  End
  Else Begin
    gldisable(gl_lighting);
  End;
  // Render Szene
  glClear(GL_COLOR_BUFFER_BIT Or GL_DEPTH_BUFFER_BIT);
  glLoadIdentity();
  // Kamera Positionieren
  gluLookAt(EyeX, EyeY, EyeZ, 0, 0, 0, 0, 1, 0);
  glColor4f(1, 1, 1, 1); // Reset der Farbe
  // Drehung des Würfels
  glMultMatrixf(@RotMatrix);
  glpushmatrix;
  glScalef(2, 2, 2);
  Case ProgramState Of
    psWait: Begin
        DrawCube(cube, checkbox1.checked, SelectMode, CheckBox4.Checked);
      End;
    psAnim: Begin
        AnimCount := AnimCount + AnimSpeed;
        DrawJobAnim(cube, Animjob, AnimCount, CheckBox4.Checked, false);
        If AnimCount >= 100 Then Begin
          DoJob(AnimJob, cube);
          ProgramState := pswait;
        End;
      End;
    psMakeFirstLevel, psMakeSecondLevel, psMakeThirdLevel: Begin
        If high(GlobalToDoList) <> -1 Then Begin
          AnimCount := AnimCount + AnimSpeed;
          DrawJobAnim(cube, GlobalToDoList[0], AnimCount, CheckBox4.Checked, Checkbox6.checked);
          If AnimCount >= 100 Then Begin
            //
            If CheckBox5.Checked Then Begin
              Button9.Click;
            End;
          End;
        End
        Else Begin
          FinishAnimation;
        End;
      End;
    psFinish: Begin
        FinishAnimation;
      End;
  End;
  glpopmatrix;
  If Not SelectMode Then
    OpenGLControl1.SwapBuffers;
End;

Procedure TForm1.OpenGLControl1Paint(Sender: TObject);
Begin
  Render(false);
End;

Procedure TForm1.OpenGLControl1Resize(Sender: TObject);
Begin
  If Initialized Then Begin
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glViewport(0, 0, OpenGLControl1.Width, OpenGLControl1.Height);
    gluPerspective(45.0, OpenGLControl1.Width / OpenGLControl1.Height, 0.1, 100.0);
    glMatrixMode(GL_MODELVIEW);
  End;
End;

Procedure TForm1.FormCreate(Sender: TObject);
Begin
  // Init dglOpenGL.pas , Teil 1
  If Not InitOpenGl Then Begin
    showmessage('Error, could not init dglOpenGL.pas');
    Halt;
  End;
  (*
  60 - FPS entsprechen
  0.01666666 ms
  Ist Interval auf 16 hängt das gesamte system, bei 17 nicht.
  Generell sollte die Interval Zahl also dynamisch zum Rechenaufwand, mindestens aber immer 17 sein.
  *)
  randomize;
  Timer1.Interval := 40; // 25 FPS reichen vollkommen aus.
  RotMatrix := identitymatrix4x4;
  cube := ClearCube();
  Form1.caption := '3d Cube, by Corpsman, ver. ' + FloattostrF(ver, fffixed, 4, 2);
  Button9.visible := false;
  checkbox5.visible := false;
  checkbox6.visible := false;
  Opendialog1.initialdir := extractfilepath(application.exename);
  savedialog1.initialdir := extractfilepath(application.exename);
End;

Procedure TForm1.Button7Click(Sender: TObject);
Begin
  close;
End;

Procedure TForm1.Button1Click(Sender: TObject);
Begin
  Cube := ClearCube();
  FinishAnimation;
End;

Procedure TForm1.Button2Click(Sender: TObject);
Var
  f: Textfile;
  x, y: integer;
Begin
  If Savedialog1.execute Then Begin
    assignfile(f, savedialog1.filename);
    rewrite(f);
    For y := 0 To 8 Do
      For x := 0 To 5 Do
        Writeln(f, inttostr(Cube[x, y]));
    closefile(f);
  End;
End;

Procedure TForm1.Button3Click(Sender: TObject);
Var
  f: Textfile;
  x, y: integer;
  s: String;
Begin
  If Opendialog1.execute Then Begin
    //    inFinding := false;
    Form1.caption := '3d Cube, by Corpsman, ver. ' + FloattostrF(ver, fffixed, 4, 2);
    //    Button6.visible := false;
    assignfile(f, opendialog1.filename);
    reset(f);
    For y := 0 To 8 Do
      For x := 0 To 5 Do Begin
        readln(f, s);
        Cube[x, y] := strtoint(S);
      End;
    closefile(f);
    //    draw;
  End;
End;

Procedure TForm1.Button4Click(Sender: TObject);
Var
  x: integer;
Begin
  // Random Cube
  For x := 0 To 20 Do Begin
    DoJob(IndexToJob(random(18)), cube);
  End;
End;

Procedure TForm1.Button5Click(Sender: TObject);
Begin
  // Checken ob der Cube Lösbar ist
  If Not Checkcube(cube) Then
    If ID_NO = application.messagebox('It seems not to be a normal cube, try to get the solution anyway ?', 'Question', MB_YESNO + MB_ICONINFORMATION) Then
      exit;
  // Wenn er Lösbar ist, oder es uns egal ist ob er Lösbar ist...
  setlength(GlobalToDoList, 0); // Erst Mal Löschen aller Alten Jobs
  AnimCount := 0;
  BerechneToDoNexteEbene(cube, GlobalToDoList);
  If high(GlobalToDoList) <> -1 Then Begin
    caption := inttostr(high(GlobalToDoList) + 1) + ' Steps to get to the next Level';
    CheckBox1.visible := false;
    CheckBox2.visible := false;
    CheckBox5.Visible := true;
    CheckBox6.Visible := true;
    button9.visible := true;
    button5.visible := false;
    button9.SetFocus;
  End;
End;

Procedure TForm1.Button6Click(Sender: TObject);
Begin
  application.Messagebox(pchar(
    '3d Cube was written to get a free 32 Bit version of the cube problem.' + #13 +
    'The programmer used this programm to test his own skills.' + #13 +
    'This programm is free with no garanty.' + #13 + #13 +
    'If you cann''t complet your cube with it, maybe you did the wrong turn.' + #13 + #13 +
    'Support under : www.Corpsman.de' + #13 +
    'since ver. 1.02 ported to OpenGL' + #13 +
    'Introduction:' + #13 +
    'Use the mouse (left and right button) to rotate the cube.' + #13 +
    'Restart animation with right mouse button.'
    ), 'Info', MB_ICONINFORMATION + MB_OK);
End;

Procedure TForm1.Button8Click(Sender: TObject);
Begin
  RotMatrix := IdentityMatrix4x4;
End;

Procedure TForm1.Button9Click(Sender: TObject);
Var
  i: Integer;
Begin
  If High(GlobalToDoList) <> -1 Then Begin
    AnimCount := 0;
    DoJob(GlobalToDoList[0], cube);
    For i := 1 To high(GlobalToDoList) Do Begin
      GlobalToDoList[i - 1] := GlobalToDoList[i];
    End;
    SetLength(GlobalToDoList, high(GlobalToDoList));
    // Weiter schalten ..
    If high(GlobalToDoList) = -1 Then Begin
      BerechneToDoNexteEbene(cube, GlobalToDoList);
    End;
    caption := inttostr(high(GlobalToDoList) + 1) + ' Steps to get to the next Level';
  End;
End;

Procedure TForm1.Timer1Timer(Sender: TObject);
{$IFDEF DebuggMode}
Var
  i: Cardinal;
  p: Pchar;
{$ENDIF}
Begin
  If Initialized Then Begin
    OpenGLControl1.OnPaint(Nil);
{$IFDEF DebuggMode}
    i := glGetError();
    If i <> 0 Then Begin
      p := gluErrorString(i);
      showmessage('OpenGL Error (' + inttostr(i) + ') occured.' + #13#13 +
        'OpenGL Message : "' + p + '"'#13#13 +
        'Applikation will be terminated.');
      Timer1.Enabled := false;
      close;
    End;
{$ENDIF}
  End;
End;

End.


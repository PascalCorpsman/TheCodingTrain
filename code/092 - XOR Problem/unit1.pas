Unit Unit1;

{$MODE objfpc}{$H+}
{$DEFINE DebuggMode}

Interface

Uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls,
  OpenGlcontext,
  (*
   * Kommt ein Linkerfehler wegen OpenGL dann: sudo apt-get install freeglut3-dev
   *)
  dglOpenGL // http://wiki.delphigl.com/index.php/dglOpenGL.pas
  //  , opengl_graphikengine // Die OpenGLGraphikengine ist eine Eigenproduktion von www.Corpsman.de, und kann getrennt geladen werden.
  , uopengl_ascii_font
  , uneuralnetwork
  //, unn
  , uvectormath
  ;
Const
  AbsolutMapHeight = 1;
  ROT_SENSITIVITY: Single = 0.5;
  Dim = 100; // Anzahl Stützpunkte [0..1[

Type

  { TForm1 }

  TForm1 = Class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    CheckBox1: TCheckBox;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    OpenGLControl1: TOpenGLControl;
    ScrollBar1: TScrollBar;
    Timer1: TTimer;
    Procedure Button1Click(Sender: TObject);
    Procedure Button2Click(Sender: TObject);
    Procedure Button3Click(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure OpenGLControl1MakeCurrent(Sender: TObject; Var Allow: boolean);
    Procedure OpenGLControl1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    Procedure OpenGLControl1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    Procedure OpenGLControl1Paint(Sender: TObject);
    Procedure OpenGLControl1Resize(Sender: TObject);
    Procedure ScrollBar1Change(Sender: TObject);
    Procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
    mx, my: Integer;
    data: Array[0..Dim, 0..Dim] Of Single;
    FNormals: Array[0..Dim, 0..Dim] Of TVector3;
    brain: TNeuralNetwork;
    RotMatrix: Array[0..3, 0..3] Of Single;
    IterationsPerFram: integer;
    Procedure RefreshData();
    Procedure Train();
    Procedure Plot_Data();
    Procedure Rotate(dx, dy, dz: single);
    Procedure CreateNet();
  public
    { public declarations }
  End;

Var
  Form1: TForm1;
  Initialized: Boolean = false; // Wenn True dann ist OpenGL initialisiert

Implementation

{$R *.lfm}

{ TForm1 }

Var
  allowcnt: Integer = 0;

Procedure TForm1.OpenGLControl1MakeCurrent(Sender: TObject; Var Allow: boolean);
// Lichtersachen
Const
  LAmbient: Array[0..3] Of Single = (1, 1, 1, 1);
  Lpos: Array[0..3] Of Single = (3, 6, -3, 1);
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
  If allowcnt = 2 Then Begin // Dieses If Sorgt mit dem obigen dafür, dass der Code nur 1 mal ausgeführt wird.

    glEnable(GL_DEPTH_TEST); // Tiefentest
    glDepthFunc(gl_less);
    //glenable(GL_CULL_FACE);
    glLightfv(GL_LIGHT0, GL_AMBIENT, @LAmbient);
    glLightfv(GL_LIGHT0, GL_POSITION, @Lpos);
    glEnable(GL_LIGHT0);
    glEnable(gl_lighting);
    Create_ASCII_Font();
    // Der Anwendung erlauben zu Rendern.
    Initialized := True;
    OpenGLControl1Resize(Nil);
  End;
  Form1.Invalidate;
End;

Procedure TForm1.OpenGLControl1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Begin
  mx := x;
  my := y;
End;

Procedure TForm1.OpenGLControl1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
Var
  rotx, roty: Single;
Begin
  If ssleft In shift Then Begin
    rotY := (x - mX) * ROT_SENSITIVITY;
    rotX := (y - mY) * ROT_SENSITIVITY;
    mX := x;
    mY := y;
    If ssright In shift Then Begin
      Rotate(rotx, 0, roty);
    End
    Else Begin
      Rotate(rotx, roty, 0);
    End;
  End;
End;

Procedure TForm1.OpenGLControl1Paint(Sender: TObject);
Begin
  If Not Initialized Then Exit;
  // Render Szene
  glClearColor(0.0, 0.0, 0.0, 0.0);
  glClear(GL_COLOR_BUFFER_BIT Or GL_DEPTH_BUFFER_BIT);
  glLoadIdentity();
  gluLookAt(0, 1.5, -3, 0, 0, 0, 0, 1, 0);
  glMultMatrixf(@RotMatrix[0, 0]);
  glScalef(2 / dim, 1, 2 / dim);
  glTranslatef(-dim / 2, 0, -dim / 2);
  Train();
  RefreshData();
  Plot_Data();
  glScalef(dim / 2, 1, dim / 2);
  OpenGL_ASCII_Font.BillboardTextout(v3(0, 0, 0), 0.1, '0/0');
  OpenGL_ASCII_Font.BillboardTextout(v3(2, 0, 0), 0.1, '1/0');
  OpenGL_ASCII_Font.BillboardTextout(v3(2, 0, 2), 0.1, '1/1');
  OpenGL_ASCII_Font.BillboardTextout(v3(0, 0, 2), 0.1, '0/1');
  OpenGLControl1.SwapBuffers;
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

Procedure TForm1.ScrollBar1Change(Sender: TObject);
Begin
  Label2.Caption := format('Learnrate %0.3f', [ScrollBar1.Position * 0.5 / 100]);
  brain.LearnRate := ScrollBar1.Position * 0.5 / 100;
End;

Procedure TForm1.FormCreate(Sender: TObject);
Begin
  system.Randomize;
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
  Timer1.Interval := 17;
  CreateNet();
  RefreshData();
  Button1.Click;
  edit1.text := '100';
  IterationsPerFram := 100;
  ScrollBar1.Position := 20;
  ScrollBar1Change(Nil);
End;

Procedure TForm1.CreateNet();
Begin
  // Idee: https://www.youtube.com/watch?v=188B6k_F9jU

  //Das geht zwar aber das NN schwingt manchmal in einem ungültigen Zustand, wie kommen wir da raus ?
  (*
   * Wie unter : https://www.youtube.com/watch?v=188B6k_F9jU&list=PLRqwX-V7Uu6aCibgK1PTWWu9by6XFdCfh&index=19
   * zu sehen ist, ist es durchaus normal das ein 2 2 1 Netzwerk beim Erlernen des XOR "hängen" bleiben kann
   * ein 2 3 1 Netzwerk reduziert diese Hängenbleib tendenz bereits deutlich, bei einem 2 4 1 konnte das verhalten nicht
   * mehr beobachtet werden.
   *)
//  brain := TSimpleNeuralNetwork.Create(2, 4, 1);
  brain := TNeuralNetwork.Create([2, 4, 1]);
End;

Procedure TForm1.Button1Click(Sender: TObject);
Var
  i, j: Integer;
Begin
  For i := 0 To 3 Do Begin
    For j := 0 To 3 Do Begin
      If i = j Then Begin
        RotMatrix[i, j] := 1;
      End
      Else Begin
        RotMatrix[i, j] := 0;
      End;
    End;
  End;
End;

Procedure TForm1.Button2Click(Sender: TObject);
Var
  a, b: TVector3;
  s: Single;
Begin
  s := a * b;
  brain.Free;
  CreateNet();
  ScrollBar1Change(Nil);
End;

Procedure TForm1.Button3Click(Sender: TObject);
Begin
  IterationsPerFram := strtointdef(edit1.text, 100);
End;

Procedure TForm1.Timer1Timer(Sender: TObject);
{$IFDEF DebuggMode}
Var
  i: Cardinal;
  p: Pchar;
{$ENDIF}
Begin
  If Initialized Then Begin
    OpenGLControl1.Invalidate;
{$IFDEF DebuggMode}
    i := glGetError();
    If i <> 0 Then Begin
      Timer1.Enabled := false;
      p := gluErrorString(i);
      showmessage('OpenGL Error (' + inttostr(i) + ') occured.' + LineEnding + LineEnding +
        'OpenGL Message : "' + p + '"' + LineEnding + LineEnding +
        'Applikation will be terminated.');
      close;
    End;
{$ENDIF}
  End;
End;

Procedure TForm1.RefreshData();
  Procedure CalcNormals();
  Var
    fNs: Array[0..Dim - 1, 0..2 * Dim - 1] Of TVector3; // Berechnung der Normalen Pro Dreieck
    i, j: integer;
    s, a, b, c, d1, d2: TVector3;
  Begin
    // 1. Berechnen der Normalen Pro Dreieck
    For i := 1 To Dim Do Begin
      For j := 1 To Dim Do Begin
        // Pro Quadrat gibt es immer 2 Dreiecke
        // Dreieck 1 hat die Eckunkte [i-1/j-1],[i/j-1],[i-1/j]
        a := v3(i - 1, data[i - 1, j - 1] * AbsolutMapHeight, j - 1);
        b := v3(i, data[i, j - 1] * AbsolutMapHeight, j - 1);
        c := v3(i - 1, data[i - 1, j] * AbsolutMapHeight, j);
        d1 := a - b;
        d2 := c - b;
        fNs[i - 1, (j - 1) * 2] := normv3(d1.Cross(d2)); // Kreuzproduct
        // Dreieck 2 hat die Eckunkte [i-1/j],[i/j-1],[i/j]
        a := v3(i - 1, data[i - 1, j] * AbsolutMapHeight, j);
        b := v3(i, data[i, j - 1] * AbsolutMapHeight, j - 1);
        c := v3(i, data[i, j] * AbsolutMapHeight, j);
        d1 := a - b;
        d2 := c - b;
        fNs[i - 1, (j - 1) * 2 + 1] := normv3(d1.Cross(d2)); // Kreuzproduct
      End;
    End;
    // 2. Umrechnen der Dreiecksnormalen auf VertexNormale
    // 2.1 Alle Punkte die auf dem Rand Liegen
    For i := 0 To Dim Do Begin
      // TODO: Das hier fehlt noch !!
      FNormals[i, 0] := v3(0, 1, 0); // Oben
      FNormals[i, Dim] := v3(0, 1, 0); // Unten
      FNormals[0, i] := v3(0, 1, 0); // Links
      FNormals[Dim, i] := v3(0, 1, 0); // Rechts
    End;
    // 2.2 Alle Punkte im Inneren
    For i := 1 To Dim - 1 Do Begin
      For j := 1 To Dim - 1 Do Begin
        // Jeder Vertex hat eine Gemittelte Normale aus 6 Seitenflächen
        s := fNs[i - 1, (j - 1) * 2 + 1] +
          fNs[i - 1, (j) * 2] +
          fNs[i - 1, (j) * 2 + 1] +
          fNs[i, (j - 1) * 2] +
          fNs[i, (j - 1) * 2 + 1] +
          fNs[i, (j) * 2 - 1];
        FNormals[i, j] := normv3(s);
      End;
    End;
  End;
Var
  i, j: Integer;
  g, input: TVectorN;
Begin
  // 1. Neue Ergebnisse des Brain übernehmen
  For i := 0 To Dim Do Begin
    For j := 0 To dim Do Begin
      input := VN([i / dim, j / dim]);
      g := brain.predict(input);
      data[i, j] := g[0];
    End;
  End;
  // 2. Normalen Berechnen
  CalcNormals();
End;

Procedure TForm1.Train();
Type
  TTrainingData = Record
    input, target: TVectorN;
  End;
Var
  trainData: Array[0..3] Of TTrainingData;
  i, j: integer;
Begin
  // XOR
  traindata[0].input := VN([0, 0]);
  traindata[0].target := VN([0]);
  traindata[1].input := VN([1, 0]);
  traindata[1].target := VN([1]);
  traindata[2].input := VN([0, 1]);
  traindata[2].target := VN([1]);
  traindata[3].input := VN([1, 1]);
  traindata[3].target := VN([0]);
  // }
  {// Not XOR
  traindata[0].input := VN([0, 0]);
  traindata[0].target := VN([1]);
  traindata[1].input := VN([1, 0]);
  traindata[1].target := VN([0]);
  traindata[2].input := VN([0, 1]);
  traindata[2].target := VN([0]);
  traindata[3].input := VN([1, 1]);
  traindata[3].target := VN([1]);
  // }
  {// AND
  traindata[0].input := VN([0, 0]);
  traindata[0].target := VN([0]);
  traindata[1].input := VN([1, 0]);
  traindata[1].target := VN([0]);
  traindata[2].input := VN([0, 1]);
  traindata[2].target := VN([0]);
  traindata[3].input := VN([1, 1]);
  traindata[3].target := VN([1]);
  // }
  {// OR
  traindata[0].input := VN([0, 0]);
  traindata[0].target := VN([0]);
  traindata[1].input := VN([1, 0]);
  traindata[1].target := VN([1]);
  traindata[2].input := VN([0, 1]);
  traindata[2].target := VN([1]);
  traindata[3].input := VN([1, 1]);
  traindata[3].target := VN([1]);
  // }

  For i := 0 To IterationsPerFram - 1 Do Begin
    j := random(4);
    brain.Train(traindata[j].input, traindata[j].target);
  End;
End;

Procedure TForm1.Plot_Data();
Var
  i, j: Integer;
Begin
  glPushMatrix;
  If CheckBox1.Checked Then Begin // Switch to Wireframe Mode
    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
  End;
  glcolor3f(1, 1, 1);
  For i := 1 To Dim Do Begin
    glBegin(GL_TRIANGLE_STRIP);
    glNormal3fv(@FNormals[i - 1, 0]); // -- Gourogh Shading
    glTexCoord2f((i - 1) / Dim, 0);
    glVertex3f(i - 1, data[i - 1, 0] * AbsolutMapHeight, 0);
    glNormal3fv(@FNormals[i, 0]); // -- Gourogh Shading
    glTexCoord2f(i / Dim, 0);
    glVertex3f(i, data[i, 0] * AbsolutMapHeight, 0);
    For j := 1 To Dim Do Begin
      //      glNormal3fv(@fNormals[i - 1, (j - 1) * 2]); -- Flat-Shaded (dann Zugriff auf fNs aus CalcNormals)
      glNormal3fv(@FNormals[i - 1, j]); // -- Gourogh Shading
      glTexCoord2f((i - 1) / Dim, j / Dim);
      glVertex3f(i - 1, data[i - 1, j] * AbsolutMapHeight, j);
      //      glNormal3fv(@fNormals[i - 1, (j - 1) * 2 + 1]); -- Flat-Shaded (dann Zugriff auf fNs aus CalcNormals)
      glNormal3fv(@FNormals[i, j]); // -- Gourogh Shading
      glTexCoord2f(i / Dim, j / Dim);
      glVertex3f(i, data[i, j] * AbsolutMapHeight, j);
    End;
    glend();
  End;
  If CheckBox1.Checked Then Begin // Restore Normal Mode
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
  End;
  glPopMatrix;
End;

Procedure TForm1.Rotate(dx, dy, dz: single);
Begin
  // Wieso die Rotation selber Rechnen, wenn OpenGL das machen kann ;)
  glPushMatrix();
  glLoadIdentity();
  // Normalerweise müsste hier noch ein translate Pos stehen, unser Objekt ist aber in [0,0,0] daher fällt das weg
  glRotatef(dx, 1.0, 0.0, 0.0);
  glRotatef(dy, 0.0, 1.0, 0.0);
  glRotatef(dz, 0.0, 0.0, 1.0);
  // Normalerweise müsste hier noch ein - translate Pos stehen, unser Objekt ist aber in [0,0,0] daher fällt das weg
  glMultMatrixf(@RotMatrix[0, 0]);
  glGetFloatv(GL_MODELVIEW_MATRIX, @RotMatrix[0, 0]);
  glPopMatrix;
End;

End.


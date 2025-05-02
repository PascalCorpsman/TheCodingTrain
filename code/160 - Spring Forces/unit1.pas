Unit Unit1;

{$MODE objfpc}{$H+}

Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs
  , uparticle
  , uspring
  , uvectormath;

Type

  { TForm1 }

  TForm1 = Class(TForm)
    Procedure FormCloseQuery(Sender: TObject; Var CanClose: Boolean);
    Procedure FormCreate(Sender: TObject);
    Procedure FormDestroy(Sender: TObject);
    Procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    Procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    Procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    Procedure FormPaint(Sender: TObject);
  private
    FrameRateCounterTime: QWord;
    FrameRateCounter: integer;
    Closing: Boolean;
    particles: Array Of TParticle;
    Springs: Array Of TSpring;
    spacing: Single;
    k: single;
    gravity: TVector2;
    MouseIsPressed: Boolean;
    mouseX, MouseY: integer;
  public

  End;

Var
  Form1: TForm1;

Implementation

{$R *.lfm}

{ TForm1 }

Procedure TForm1.FormCloseQuery(Sender: TObject; Var CanClose: Boolean);
Begin
  Closing := true;
End;

Procedure TForm1.FormCreate(Sender: TObject);
Const
  ParticleCount = 12;
Var
  i: Integer;
  a, b: TParticle;
Begin
  Closing := false;
  FrameRateCounterTime := GetTickCount64;
  FrameRateCounter := 0;
  // Setup
  spacing := 50;
  k := 0.1;
  setlength(particles, ParticleCount);
  setlength(Springs, ParticleCount - 1);
  For i := 0 To ParticleCount - 1 Do Begin
    particles[i] := TParticle.Create(400, i * spacing);
    If i <> 0 Then Begin
      a := particles[i];
      b := particles[i - 1];
      Springs[i - 1] := TSpring.Create(k, spacing, a, b);
    End;
  End;
  particles[0].locked := true;
  gravity := v2(0, 0.1);
End;

Procedure TForm1.FormDestroy(Sender: TObject);
Var
  i: Integer;
Begin
  For i := 0 To high(particles) Do
    particles[i].Free;
End;

Procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Begin
  MouseIsPressed := ssleft In shift;
  mouseX := x;
  MouseY := y;
End;

Procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
Begin
  MouseIsPressed := ssleft In shift;
  mouseX := x;
  MouseY := y;
End;

Procedure TForm1.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Begin
  MouseIsPressed := ssleft In shift;
  mouseX := x;
  MouseY := y;
End;

Procedure TForm1.FormPaint(Sender: TObject);
Var
  n: QWord;
  i: Integer;
  tail: TParticle;
  a: Array Of TPoint;
Begin
  // Draw
  canvas.Brush.Color := RGBToColor(112, 50, 126);
  canvas.Brush.Style := bsSolid;
  Canvas.Pen.Width := 1;
  canvas.Rectangle(-1, -1, Width + 1, Height + 1);
  For i := 0 To high(Springs) Do Begin
    Springs[i].Update();
    // Springs[i].Show(Canvas);
  End;
  For i := 0 To high(particles) Do Begin
    particles[i].ApplyForce(gravity);
    particles[i].Update();
    // particles[i].Show(Canvas);
  End;
  // Start Draw es bezier
  a := Nil;
  SetLength(a, length(particles) + 2);
  a[0] := point(round(particles[0].position.x), round(particles[0].position.y));
  For i := 0 To high(particles) Do Begin
    a[i + 1] := point(round(particles[i].position.x), round(particles[i].position.y));
  End;
  a[high(a)] := point(round(particles[high(particles)].position.x), round(particles[high(particles)].position.y));
  Canvas.Pen.Color := clWhite;
  Canvas.Pen.Width := 8;
  Canvas.PolyBezier(a, false, true);
  // End draw as bezier

  tail := particles[high(particles)];
  If MouseIsPressed Then Begin
    tail.Position := v2(mouseX, MouseY);
    tail.velocity := v2(0, 0);
  End;

  inc(FrameRateCounter);
  n := GetTickCount64;
  If FrameRateCounterTime + 1000 <= n Then Begin
    FrameRateCounterTime := n;
    caption := format('Framerate: %d FPS', [FrameRateCounter]);
    FrameRateCounter := 0;
  End;
  If Not Closing Then Begin
    sleep(10); // Limit Framerate to ~100 FPS
    Invalidate;
  End;
End;

End.


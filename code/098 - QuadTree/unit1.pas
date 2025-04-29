Unit Unit1;

{$MODE objfpc}{$H+}

Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  uquadtree, uquadtree_common;

Type

  { TForm1 }

  TForm1 = Class(TForm)
    Button1: TButton;
    Label1: TLabel;
    Label2: TLabel;
    PaintBox1: TPaintBox;
    Procedure Button1Click(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure FormDestroy(Sender: TObject);
    Procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    Procedure PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    Procedure PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    Procedure PaintBox1Paint(Sender: TObject);
  private
    qt: TQuadTree;
    mdown: Boolean;
    m1down: TPoint;
    m2down: TPoint;
    pts: TQuadTreePointArray;
  public

  End;

Var
  Form1: TForm1;

Implementation

{$R *.lfm}

Uses math;

Var
  RandomState: integer = 0;
  RandomOut2: Double;

Procedure Boxmuller(g1, g2: Double; Out s1, s2: Double);
Var
  r: double;
Begin
  r := g1 * g1 + g2 * g2;
  If (r <= 1.0) And (r <> 0) Then Begin
    s1 := sqrt(-2 * ln(r) / r) * g1;
    s2 := sqrt(-2 * ln(r) / r) * g2;
  End
  Else Begin // Eigentlich darf nun nichts geschehen, aber wir bilden dann einfach auf 0 ab ;)
    s1 := 0;
    s2 := 0;
  End;
End;

Function nextGaussian: Single;
Var
  in1, in2, out1: Double;
Begin
  Case RandomState Of
    0: Begin
        // Zwei Normal Verteilte Zahlen zwischen -0.5 und 0.5
        in1 := (random(10000) - 5000) / 5000;
        in2 := (random(10000) - 5000) / 5000;
        Boxmuller(in1, in2, out1, RandomOut2);
        result := out1;
        RandomState := 1;
      End;
    1: Begin
        result := RandomOut2;
        RandomState := 0;
      End;
  End;
End;

{ TForm1 }

Procedure TForm1.FormCreate(Sender: TObject);
Var
  i, x, y: Integer;
Begin
  label2.caption := '';
  caption := '98 - Quadtree';
  Randomize;
  qt := TQuadTree.Create(rect(0, 0, PaintBox1.Width, PaintBox1.Height), 4);
  //  For i := 0 To 500 - 1 Do Begin
  //    qt.insert(point(random(PaintBox1.Width), random(PaintBox1.Height)));
  //  End;
  For i := 0 To 300 - 1 Do Begin
    x := round(nextGaussian * PaintBox1.Width / 6 + PaintBox1.Width / 2);
    y := round(nextGaussian * PaintBox1.Height / 6 + PaintBox1.Height / 2);
    qt.insert(point(x, y));
  End;
  PaintBox1.Invalidate;
End;

Procedure TForm1.Button1Click(Sender: TObject);
Begin
  mdown := false;
  m1down := Point(-1, -1);
  m2down := Point(-1, -1);
  pts := Nil;
  qt.Free;
  qt := TQuadTree.Create(rect(0, 0, PaintBox1.Width, PaintBox1.Height), 4);
  PaintBox1.Invalidate;
End;

Procedure TForm1.FormDestroy(Sender: TObject);
Begin
  If assigned(qt) Then qt.free;
  qt := Nil;
End;

Procedure TForm1.PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Begin
  If ssLeft In Shift Then Begin
    qt.Insert(point(x, y));
    PaintBox1.Invalidate;
  End;
  mdown := false;
  If ssright In shift Then Begin
    mdown := true;
    m1down := point(x, y);
    m2down := point(x, y);
    PaintBox1.Invalidate;
  End;
End;

Procedure TForm1.PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
Begin
  If ssLeft In Shift Then Begin
    qt.Insert(point(x, y));
    PaintBox1.Invalidate;
  End;
  If ssright In shift Then Begin
    m2down := point(x, y);
    PaintBox1.Invalidate;
  End;
End;

Procedure TForm1.PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Begin
  If mdown Then Begin
    mdown := false;
    m2down := point(x, y);
    pts := qt.Query(rect(
      min(m1down.X, m2down.x),
      min(m1down.Y, m2down.Y),
      max(m1down.X, m2down.x),
      max(m1down.Y, m2down.Y)
      ));
    label2.caption := format('Found %d points', [length(pts)]);
    PaintBox1.Invalidate;
  End;
End;

Procedure TForm1.PaintBox1Paint(Sender: TObject);
Const
  Stroke = 1;
Var
  i: Integer;

  Procedure Point(x, y: single);
  Begin
    PaintBox1.Canvas.Ellipse(round(x) - Stroke, round(y) - Stroke, round(x) + Stroke, round(y) + Stroke);
  End;

Begin
  PaintBox1.Canvas.Brush.Color := clBlack;
  PaintBox1.Canvas.Brush.Style := bsSolid;
  PaintBox1.Canvas.Rectangle(-1, -1, PaintBox1.Width, PaintBox1.Height);

  If assigned(qt) Then qt.show(PaintBox1.Canvas);
  If m1down.X <> -1 Then Begin
    PaintBox1.Canvas.Brush.Style := bsClear;
    PaintBox1.Canvas.Pen.Color := clGreen;
    PaintBox1.Canvas.Rectangle(m1down.X, m1down.y, m2down.X, m2down.y);
  End;

  PaintBox1.Canvas.Brush.Color := clRed;
  PaintBox1.Canvas.Brush.Style := bsSolid;
  PaintBox1.Canvas.Pen.Color := clred;
  For i := 0 To high(pts) Do Begin
    point(pts[i].X, pts[i].y);
  End;
End;

End.


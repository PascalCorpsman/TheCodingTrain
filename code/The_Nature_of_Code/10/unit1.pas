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

Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  uperceptron, upoint, ushared, unn, unnMath;

Type

  { TForm1 }

  TForm1 = Class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Label1: TLabel;
    Memo1: TMemo;
    PaintBox1: TPaintBox;
    Procedure Button1Click(Sender: TObject);
    Procedure Button2Click(Sender: TObject);
    Procedure Button3Click(Sender: TObject);
    Procedure Button4Click(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
  private
    Brain_10_2: TPerceptron;
    Brain: TNeuralNetwork;
    points: Array Of Point;
  public

  End;

Var
  Form1: TForm1;

Implementation

{$R *.lfm}

{ TForm1 }

Procedure TForm1.Button1Click(Sender: TObject);
Const
  Dim = 3;
  trcount = 1;
Var
  w, i, j: Integer;
  inp: TFloatArray;
  px, py: Single;
  x1, y1: single;
Begin
  // 10.2
  // Ein Neuron, das trainiert wird
  PaintBox1.Canvas.Brush.Color := clWhite;
  PaintBox1.Canvas.Rectangle(-1, -1, 201, 201);
  For i := 0 To 99 Do Begin
    points[i].Show(PaintBox1.Canvas);
  End;
  x1 := -1;
  y1 := f(x1);
  px := map(-1, 1, x1, 0, 200);
  py := map(-1, 1, y1, 200, 0);
  PaintBox1.Canvas.MoveTo(round(px), round(py));
  x1 := 1;
  y1 := f(x1);
  px := map(-1, 1, x1, 0, 200);
  py := map(-1, 1, y1, 200, 0);
  PaintBox1.Canvas.LineTo(round(px), round(py));
  w := 0;
  For j := 0 To trcount - 1 Do Begin
    For i := 0 To 99 Do Begin
      inp := points[i].inputs;
      Brain_10_2.Train(inp, points[i].l);
      If j = trcount - 1 Then Begin
        PaintBox1.canvas.brush.Color := clGreen;
        If Brain_10_2.Guess(inp) <> points[i].L Then Begin
          PaintBox1.canvas.brush.Color := clred;
        End
        Else Begin
          inc(w);
        End;
        px := points[i].Pixelx();
        py := points[i].Pixely();
        PaintBox1.canvas.Ellipse(round(px - dim), round(py - dim), round(px + dim), round(py + dim));
      End;
    End;
  End;
  label1.caption := inttostr(w);
End;

Procedure TForm1.Button2Click(Sender: TObject);
Const
  Dim = 3;
  trcount = 1;
Var
  w, i, j: Integer;
  inp: TFloatArray;
  px, py: Single;
  x1, y1: single;
Begin
  // 10.3
  // Ein Neuron das Trainiert wird und bei dem man zusehen kann, was das Perzeptron gerade denkt wo die Linie ist
  PaintBox1.Canvas.Brush.Color := clWhite;
  PaintBox1.Canvas.Rectangle(-1, -1, 201, 201);
  For i := 0 To 99 Do Begin
    points[i].Show(PaintBox1.Canvas);
  End;
  x1 := -1;
  y1 := f(x1);
  px := map(-1, 1, x1, 0, 200);
  py := map(-1, 1, y1, 200, 0);
  PaintBox1.Canvas.MoveTo(round(px), round(py));
  x1 := 1;
  y1 := f(x1);
  px := map(-1, 1, x1, 0, 200);
  py := map(-1, 1, y1, 200, 0);
  PaintBox1.Canvas.LineTo(round(px), round(py));
  w := 0;
  // Anzeigen was das Netzwerk gerade denkt
  PaintBox1.Canvas.Pen.Color := clred;
  px := -1;
  py := Brain_10_2.guessY(px);
  px := map(-1, 1, px, 0, 200);
  py := map(-1, 1, py, 200, 0);
  PaintBox1.Canvas.MoveTo(round(px), round(py));
  px := 1;
  py := Brain_10_2.guessY(px);
  px := map(-1, 1, px, 0, 200);
  py := map(-1, 1, py, 200, 0);
  PaintBox1.Canvas.LineTo(round(px), round(py));
  PaintBox1.Canvas.Pen.Color := clBlack;
  For j := 0 To trcount - 1 Do Begin
    For i := 0 To 99 Do Begin
      inp := points[i].inputs;
      Brain_10_2.Train(inp, points[i].l);
      If j = trcount - 1 Then Begin
        PaintBox1.canvas.brush.Color := clGreen;
        If Brain_10_2.Guess(inp) <> points[i].L Then Begin
          PaintBox1.canvas.brush.Color := clred;
        End
        Else Begin
          inc(w);
        End;
        px := points[i].Pixelx();
        py := points[i].Pixely();
        PaintBox1.canvas.Ellipse(round(px - dim), round(py - dim), round(px + dim), round(py + dim));
      End;
    End;
  End;
  label1.caption := inttostr(w);
End;

Procedure TForm1.Button3Click(Sender: TObject);
Var
  a, b, c: TMatrix;
Begin
  (*
   *  ( 1 -2  3)  (1 4)    (4 -3)
   *  ( 0  1 -1)* (0 2)  = (-1 3)
   *              (1 -1)
   *)
  a := Matrix(2, 3);
  b := Matrix(3, 2);
  a[0, 0] := 1;
  a[0, 1] := -2;
  a[0, 2] := 3;
  a[1, 0] := 0;
  a[1, 1] := 1;
  a[1, 2] := -1;
  b[0, 0] := 1;
  b[0, 1] := 4;
  b[1, 0] := 0;
  b[1, 1] := 2;
  b[2, 0] := 1;
  b[2, 1] := -1;
  c := a * b;
  Memo1.Text := Plot(a) + LineEnding + Plot(b) + LineEnding + Plot(c);
End;

Procedure TForm1.Button4Click(Sender: TObject);
Var
  nn: TNeuralNetwork;
  r,v: TVector;
Begin
  // 10.13
  nn := TNeuralNetwork.Create([2, 2, 1]);
  v := Vector([1, 0]);
  r := nn.Predict(v);
End;

Procedure TForm1.FormCreate(Sender: TObject);
Var
  i: Integer;
Begin
  system.Randomize;
  // Init 10.2 , 10.3
  Brain_10_2 := TPerceptron.Create(3);
  setlength(points, 100);
  For i := 0 To 99 Do Begin
    points[i] := Point.Create;
  End;
  // Init 10.5
  Brain := TNeuralNetwork.Create([3, 3, 1]);
End;

End.


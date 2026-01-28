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
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs;

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
  public

  End;

  TLayout = (LEFT, CENTER, RIGHT);

  TShape = (POINTS, LINES, TRIANGLES, TRIANGLE_FAN, TRIANGLE_STRIP, QUADS, QUAD_STRIP, TESS);

Var
  Form1: TForm1;

  MouseIsPressed: Boolean;
  mouseX, MouseY: integer;

  (*
   * Functions to directly emulate NodeJS ;)
   *)
Procedure Background(aColor: TColor);
Procedure BeginShape(aShape: TShape = TESS);
Procedure Circle(x, y, dim: integer);
Procedure CreateCanvas(aWidth, aHeight: Integer);
Procedure EndShape(); // TODO: Optionaler Parameter fehlt noch ( https://p5js.org/reference/p5/endShape/ )
Procedure Fill(aValue: Byte);
Procedure FrameRate(aFrameRate: Integer);
Function Height: integer;
Procedure Line(x1, y1, x2, y2: integer);
Procedure noFill;
Procedure noLoop;
Procedure Point(x, y: Single);
Procedure rectMode(aMode: TLayout);
Procedure Square(x, y, dim: integer);
Procedure Stroke(aValue: Byte);
Procedure Stroke(R, G, B: Byte);
Procedure StrokeWeight(aValue: integer);
Procedure TextSize(aSize: integer);
Procedure TextAlign(aHorizontal, aVertical: TLayout);
Procedure Text(aValue, X, Y: integer); overload;
Procedure Text(aValue: String; X, Y: integer); overload;
Procedure Triangle(x1, y1, x2, y2, x3, y3: Single);
Procedure Vertex(x, y: Single);
Function Width: integer;

Implementation

{$R *.lfm}

Uses uapplication;

Var
  VirtualCanvas: TBitmap;
  FrameRateDelay: integer = 10; // default 100 FPS
  TextHorAlignment: TLayout;
  TextVertAlignment: TLayout;
  rectDrawMode: TLayout;
  NoLoopCalled: Boolean = false;
  ShapePoints: Array Of TPoint = Nil;
  Shape: TShape = TESS;

Procedure Circle(x, y, dim: integer);
Begin
  x := x - dim Div 2;
  y := y - dim Div 2;
  VirtualCanvas.canvas.Ellipse(x, y, x + dim + 1, y + dim + 1);
End;

Procedure CreateCanvas(aWidth, aHeight: Integer);
Begin
  VirtualCanvas.Width := aWidth;
  VirtualCanvas.Height := aHeight;
  form1.Width := aWidth;
  form1.Height := aHeight;
  form1.Constraints.MinWidth := aWidth;
  form1.Constraints.MaxWidth := aWidth;
  form1.Constraints.MinHeight := aHeight;
  form1.Constraints.MaxHeight := aHeight;
End;

Procedure StrokeWeight(aValue: integer);
Begin
  VirtualCanvas.Canvas.Pen.Width := aValue;
End;

Procedure TextSize(aSize: integer);
Begin
  VirtualCanvas.canvas.Font.Size := aSize;
End;

Procedure TextAlign(aHorizontal, aVertical: TLayout);
Begin
  TextHorAlignment := aHorizontal;
  TextVertAlignment := aVertical;
End;

Procedure BeginShape(aShape: TShape);
Begin
  setlength(ShapePoints, 0);
  Shape := aShape;
End;

Procedure Vertex(x, y: Single);
Begin
  setlength(ShapePoints, high(ShapePoints) + 2);
  ShapePoints[high(ShapePoints)] := classes.point(round(x), round(y));
End;

Procedure EndShape;
Begin
  Case shape Of
    TESS: Begin
        VirtualCanvas.Canvas.Polygon(ShapePoints);
      End;
  End;
End;

Procedure Fill(aValue: Byte);
Begin
  VirtualCanvas.canvas.Font.color := aValue + (aValue Shl 8) + (aValue Shl 16);
  VirtualCanvas.canvas.Brush.Color := aValue + (aValue Shl 8) + (aValue Shl 16);
End;

Procedure noFill;
Begin
  VirtualCanvas.canvas.Brush.Style := bsClear;
End;

Procedure Square(x, y, dim: integer);
Begin
  Case rectDrawMode Of
    LEFT: x := x - dim;
    CENTER: Begin
        x := x - dim Div 2;
        y := y - dim Div 2;
      End;
  End;
  VirtualCanvas.canvas.Rectangle(x, y, x + dim, y + dim);
  VirtualCanvas.canvas.Pixels[x + dim - 1, y + dim - 1] := VirtualCanvas.canvas.Pen.Color;
End;

Procedure Line(x1, y1, x2, y2: integer);
Begin
  VirtualCanvas.canvas.Line(x1, y1, x2, y2);
End;

Procedure noLoop;
Begin
  NoLoopCalled := true;
End;

Procedure Point(x, y: Single);
Var
  pw: integer;
  bc: TColor;
  ax, ay: Integer;
Begin
  ax := round(x);
  ay := round(y);
  If VirtualCanvas.canvas.Pen.Width = 1 Then Begin
    VirtualCanvas.canvas.pixels[ax, ay] := VirtualCanvas.canvas.Pen.Color;
  End
  Else Begin
    pw := VirtualCanvas.canvas.Pen.Width;
    VirtualCanvas.canvas.Pen.Width := 1;
    bc := VirtualCanvas.canvas.Brush.Color;
    VirtualCanvas.canvas.Brush.Color := VirtualCanvas.canvas.Pen.Color;
    VirtualCanvas.canvas.Ellipse(ax - pw Div 2, ay - pw Div 2, ax + pw Div 2, ay + pw Div 2);
    VirtualCanvas.canvas.Brush.Color := bc;
    VirtualCanvas.canvas.Pen.Width := pw;
  End;
End;

Procedure rectMode(aMode: TLayout);
Begin
  rectDrawMode := aMode;
End;

Procedure Stroke(aValue: Byte);
Begin
  Stroke(avalue, avalue, avalue);
End;

Procedure Stroke(R, G, B: Byte);
Begin
  VirtualCanvas.canvas.Pen.Color := r + (g Shl 8) + (b Shl 16);
End;

Procedure Text(aValue, X, Y: integer);
Begin
  Text(inttostr(aValue), x, y);
End;

Procedure Text(aValue: String; X, Y: integer);
Var
  w, h: Integer;
Begin
  w := VirtualCanvas.Canvas.TextWidth(aValue);
  h := VirtualCanvas.Canvas.TextHeight(aValue);
  Case TextHorAlignment Of
    LEFT: x := x - w;
    CENTER: x := x - w Div 2;
    // RIGHT: -- Nichts
  End;
  Case TextVertAlignment Of
    LEFT: y := y - h; // TODO: das muss bestimmt anders heißen
    CENTER: y := y - h Div 2;
    // RIGHT: -- Nichts
  End;
  VirtualCanvas.Canvas.Brush.Style := bsClear; // Seems not right here ..
  VirtualCanvas.Canvas.TextOut(x, y, aValue);
End;

Procedure Triangle(x1, y1, x2, y2, x3, y3: Single);
Var
  pts: Array[0..2] Of TPoint;
Begin
  pts[0] := classes.point(round(x1), round(y1));
  pts[1] := classes.point(round(x2), round(y2));
  pts[2] := classes.point(round(x3), round(y3));
  VirtualCanvas.Canvas.Polygon(pts);
End;

Function Width: integer;
Begin
  result := form1.Height;
End;

Function Height: integer;
Begin
  result := form1.Width;
End;

Procedure FrameRate(aFrameRate: Integer);
Begin
  If aFrameRate = 0 Then Begin
    FrameRateDelay := 0;
  End
  Else Begin
    FrameRateDelay := 1000 Div aFrameRate;
  End;
End;

Procedure Background(aColor: TColor);
Begin
  VirtualCanvas.canvas.Brush.Color := aColor;
  VirtualCanvas.canvas.Rectangle(-VirtualCanvas.Canvas.Pen.Width, -VirtualCanvas.Canvas.Pen.Width, form1.Width + VirtualCanvas.Canvas.Pen.Width, form1.Height + VirtualCanvas.Canvas.Pen.Width);
End;

{ TForm1 }

Procedure TForm1.FormCloseQuery(Sender: TObject; Var CanClose: Boolean);
Begin
  Closing := true;
End;

Procedure TForm1.FormCreate(Sender: TObject);
Begin
  Randomize;
  VirtualCanvas := TBitmap.Create;
  setup;
End;

Procedure TForm1.FormDestroy(Sender: TObject);
Begin
  VirtualCanvas.free;
  VirtualCanvas := Nil;
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
  n, b: QWord;
Begin
  If Closing Then exit;
  draw();
  canvas.Draw(0, 0, VirtualCanvas);
  If NoLoopCalled Then exit;
  inc(FrameRateCounter);
  n := GetTickCount64;
  If FrameRateCounterTime + 1000 <= n Then Begin
    FrameRateCounterTime := n;
    caption := format('Framerate: %d FPS', [FrameRateCounter]);
    FrameRateCounter := 0;
  End;
  // Restart Drawing..
  b := GetTickCount64;
  While b + FrameRateDelay > GetTickCount64 Do Begin
    sleep(1); // Limit Framerate to ~100 FPS
    Application.ProcessMessages;
  End;
  Invalidate;
End;

End.


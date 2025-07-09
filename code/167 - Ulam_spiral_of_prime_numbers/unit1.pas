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

Var
  Form1: TForm1;

  MouseIsPressed: Boolean;
  mouseX, MouseY: integer;

  (*
   * Functions to directly emulate NodeJS ;)
   *)
Procedure Background(aColor: TColor);
Procedure Circle(x, y, dim: integer);
Procedure CreateCanvas(aWidth, aHeight: Integer);
Procedure Fill(aValue: Byte);
Function Height: integer;
Procedure Line(x1, y1, x2, y2: integer);
Procedure noLoop;
Procedure Point(x, y: integer);
Procedure rectMode(aMode: TLayout);
Procedure square(x, y, dim: integer);
Procedure Stroke(aValue: Byte);
Procedure TextSize(aSize: integer);
Procedure TextAlign(aHorizontal, aVertical: TLayout);
Procedure Text(aValue, X, Y: integer); overload;
Procedure Text(aValue: String; X, Y: integer); overload;
Function Width: integer;
Procedure FrameRate(aFrameRate: Integer);

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

Procedure Fill(aValue: Byte);
Begin
  VirtualCanvas.canvas.Font.color := aValue + (aValue Shl 8) + (aValue Shl 16);
  VirtualCanvas.canvas.Brush.Color := aValue + (aValue Shl 8) + (aValue Shl 16);
End;

Procedure square(x, y, dim: integer);
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

Procedure Point(x, y: integer);
Begin
  VirtualCanvas.canvas.pixels[x, y] := VirtualCanvas.canvas.Pen.Color;
End;

Procedure rectMode(aMode: TLayout);
Begin
  rectDrawMode := aMode;
End;

Procedure Stroke(aValue: Byte);
Begin
  VirtualCanvas.canvas.Pen.Color := aValue + (aValue Shl 8) + (aValue Shl 16);
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
  VirtualCanvas.canvas.Rectangle(-1, -1, form1.Width + 1, form1.Height + 1);
End;

{ TForm1 }

Procedure TForm1.FormCloseQuery(Sender: TObject; Var CanClose: Boolean);
Begin
  Closing := true;
End;

Procedure TForm1.FormCreate(Sender: TObject);
Begin
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


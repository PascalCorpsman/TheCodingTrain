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
Unit uNodeJs;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, Graphics, IntfGraphics;

Type
  TLayout = (LEFT, CENTER, RIGHT);

  TShape = (POINTS, LINES, TRIANGLES, TRIANGLE_FAN, TRIANGLE_STRIP, QUADS, QUAD_STRIP, TESS);

  { TNodeJsImage }

  TNodeJsImage = Class
  private
    fImage: TLazIntfImage;
    fPixels: Array Of Byte; // RGBA
    Function getHeight: integer;
    Function getPixels(index: integer): byte;
    Function getWidth: integer;
  public
    Property Width: integer read getWidth;
    Property Height: integer read getHeight;

    Property Pixels[index: integer]: byte read getPixels;
    Constructor Create; virtual;
    Destructor Destroy; override;

    Function get(x, y: Single): TColor;

    Procedure LoadPixels();
  End;

  { TDocument }

  TDocument = Class
  private
    Function getTitle: String;
    Procedure setTitle(AValue: String);
  published
    Property Title: String read getTitle write setTitle;
  End;

Var
  ShowFrameRate: Boolean = false; // This is not NodeJs, this is for debugging !!
  MouseIsPressed: Boolean;
  mouseX, MouseY: integer;
  Document: TDocument;
  (*
   * Functions to directly emulate NodeJS ;)
   *)
Procedure Background(aColor: TColor);
Procedure BeginShape(aShape: TShape = TESS);
Function Brightness(aColor: TColor): Byte;
Procedure Circle(x, y, dim: integer);
Procedure CreateCanvas(aWidth, aHeight: Integer);
Procedure EndShape(); // TODO: Optionaler Parameter fehlt noch ( https://p5js.org/reference/p5/endShape/ )
Procedure Fill(aValue: Byte);
Procedure FrameRate(aFrameRate: Integer);
Function Height: integer;
Procedure Line(x1, y1, x2, y2: Single);
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
Function LoadImage(Filename: String): TNodeJsImage;

Implementation

Uses unit1, Math;

Var
  TextHorAlignment: TLayout;
  TextVertAlignment: TLayout;
  rectDrawMode: TLayout;
  ShapePoints: Array Of TPoint = Nil;
  Shape: TShape = TESS;

Function Brightness(aColor: TColor): Byte;
Var
  r, g, b: Byte;
Begin
  r := aColor And $FF;
  g := (aColor Shr 8) And $FF;
  b := (aColor Shr 16) And $FF;
  result := min(255, max(0,
    round(
    0.2126 * R + 0.7152 * g + 0.0722 * b
    )));
End;

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

Procedure Line(x1, y1, x2, y2: Single);
Begin
  VirtualCanvas.canvas.Line(round(x1), round(y1), round(x2), round(y2));
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
  result := form1.Width;
End;

Function LoadImage(Filename: String): TNodeJsImage;
Var
  jp: TJPEGImage;
  Image: TBitmap;
Begin
  Result := TNodeJsImage.Create;
  If Not FileExists(Filename) Then exit;
  Image := TBitmap.Create;
  Case lowercase(ExtractFileExt(Filename)) Of
    '.jpg': Begin
        jp := TJPEGImage.Create;
        jp.LoadFromFile(Filename);
        Image.Assign(jp);
        jp.free;
      End;
    '.bmp': Begin
        Image.LoadFromFile(Filename);
      End;
  End;
  result.fImage := image.CreateIntfImage;
  image.free;
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

{ TNodeJsImage }

Function TNodeJsImage.getPixels(index: integer): byte;
Begin
  result := 0;
  If (index < 0) Or (index > high(fPixels)) Then exit;
  result := fPixels[index];
End;

Function TNodeJsImage.getHeight: integer;
Begin
  result := fImage.Height;
End;

Function TNodeJsImage.getWidth: integer;
Begin
  result := fImage.Width;
End;

Constructor TNodeJsImage.Create;
Begin
  Inherited Create;
  fImage := Nil;
  fPixels := Nil;
End;

Destructor TNodeJsImage.Destroy;
Begin
  If assigned(fImage) Then fImage.Free;
  fImage := Nil;
End;

Function TNodeJsImage.get(x, y: Single): TColor;
Var
  yy, xx: integer;
Begin
  result := clBlack;
  If Not assigned(fImage) Then exit;
  xx := round(x);
  yy := round(y);
  If (xx < 0) Or (xx >= fImage.Width) Or
    (yy < 0) Or (yy >= fImage.Height) Then exit;
  result := FPColorToTColor(fImage.Colors[xx, yy]);
End;

Procedure TNodeJsImage.LoadPixels;
Var
  r, g, b: Byte;
  i, j, index: Integer;
  col: TColor;
Begin
  setlength(fPixels, fImage.Width * fImage.Height * 4);
  For i := 0 To fImage.Width - 1 Do Begin
    For j := 0 To fImage.Height - 1 Do Begin
      index := (i + j * fImage.Width) * 4;
      col := get(i, j);
      r := Col And $FF;
      g := (Col Shr 8) And $FF;
      b := (Col Shr 16) And $FF;
      fPixels[index + 0] := r;
      fPixels[index + 1] := g;
      fPixels[index + 2] := B;
      fPixels[index + 3] := 0; // TODO: Alpha-Channel
    End;
  End;
End;

{ TDocument }

Function TDocument.getTitle: String;
Begin
  result := form1.Caption;
End;

Procedure TDocument.setTitle(AValue: String);
Begin
  form1.Caption := AValue;
End;

Initialization
  Document := TDocument.Create;

Finalization
  Document.free;
  Document := Nil;

End.


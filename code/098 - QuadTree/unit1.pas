Unit Unit1;

{$MODE objfpc}{$H+}

Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  uquadtree;

Type

  { TForm1 }

  TForm1 = Class(TForm)
    Label1: TLabel;
    PaintBox1: TPaintBox;
    Procedure FormCreate(Sender: TObject);
    Procedure FormDestroy(Sender: TObject);
    Procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    Procedure PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    Procedure PaintBox1Paint(Sender: TObject);
  private
    qt: TQuadTree;
  public

  End;

Var
  Form1: TForm1;

Implementation

{$R *.lfm}

{ TForm1 }

Procedure TForm1.FormCreate(Sender: TObject);
//Var
//  i: Integer;
Begin
  caption := '98 - Quadtree';
  Randomize;
  qt := TQuadTree.Create(rect(0, 0, PaintBox1.Width, PaintBox1.Height), 4);
  //  For i := 0 To 500 - 1 Do Begin
  //    qt.insert(point(random(PaintBox1.Width), random(PaintBox1.Height)));
  //  End;
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
End;

Procedure TForm1.PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
Begin
  If ssLeft In Shift Then Begin
    qt.Insert(point(x, y));
    PaintBox1.Invalidate;
  End;
End;

Procedure TForm1.PaintBox1Paint(Sender: TObject);
Begin
  PaintBox1.Canvas.Brush.Color := clBlack;
  PaintBox1.Canvas.Brush.Style := bsSolid;
  PaintBox1.Canvas.Rectangle(-1, -1, PaintBox1.Width, PaintBox1.Height);

  If assigned(qt) Then qt.show(PaintBox1.Canvas);
End;

End.


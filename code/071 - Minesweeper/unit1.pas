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
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  uminesweeper;

Type

  { TForm1 }

  TForm1 = Class(TForm)
    Label1: TLabel;
    PaintBox1: TPaintBox;
    Procedure FormCreate(Sender: TObject);
    Procedure PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    Procedure PaintBox1Paint(Sender: TObject);
  private
    grid: TField;
    GameFinished: Boolean;
  public

  End;

Var
  Form1: TForm1;

Implementation

{$R *.lfm}

Const
  GridColumns = 20;
  GridRows = 20;
  TotalBeeCount = 10;

  { TForm1 }

Procedure TForm1.FormCreate(Sender: TObject);
Begin
  (*
   * History: 0.01 - Initialversion
   *)
  // TODO: Add "markers / Flags"
  caption := 'Minesweeper ver. 0.01';
  Randomize;
  grid := Nil;
  PaintBox1.Invalidate;
  GameFinished := false;
End;

Procedure TForm1.PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Begin
  x := x Div GridColumns;
  y := y Div GridRows;
  // Init Game ;)
  If (grid = Nil) Or GameFinished Then Begin
    GameFinished := false;
    grid := MakeField(GridColumns, GridRows, TotalBeeCount, x, y);
  End;
  PaintBox1.Invalidate;
  // Click on Cell x,y
  If RevealFieldCoordinate(grid, x, y) Then Begin
    showmessage('Game over');
    GameFinished := true;
  End;
  If GameSolved(grid) Then Begin
    showmessage('You solved it.');
    GameFinished := true;
  End;
End;

Procedure TForm1.PaintBox1Paint(Sender: TObject);
Begin
  If assigned(grid) Then Begin
    RenderFieldToCanvas(PaintBox1.Canvas, grid,
      PaintBox1.Width Div GridColumns,
      PaintBox1.Height Div GridRows
      );
  End
  Else Begin
    // Leeres Grid malen ?
    RenderEmptyFieldToCanvas(PaintBox1.Canvas, GridColumns, GridRows,
      PaintBox1.Width Div GridColumns,
      PaintBox1.Height Div GridRows
      );
  End;
End;

End.


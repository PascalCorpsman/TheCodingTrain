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
Unit uminesweeper;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, Graphics;

Type
  TCell = Record
    bee: Boolean;
    revealed: Boolean;
    neighborCount: integer;
  End;

  TField = Array Of Array Of TCell;

Function MakeField(cols, rows: integer; TotalBeeCount: integer; IgnoreX, IgnoreY: integer): TField;
Procedure RenderFieldToCanvas(Const aCanvas: TCanvas; Const aField: TField; CellWidth, CellHeight: integer);
Procedure RenderEmptyFieldToCanvas(Const aCanvas: TCanvas; Colums, Rows, CellWidth, CellHeight: integer);

Function RevealFieldCoordinate(Var aField: TField; x, y: Integer): Boolean;
Function GameSolved(Const aField: TField): Boolean;

Implementation

Uses math;

Function RGB(r, g, b: Byte): TColor;
Begin
  result := r Or (g Shl 8) Or (b Shl 16);
End;

Function MakeField(cols, rows: integer; TotalBeeCount: integer; IgnoreX,
  IgnoreY: integer): TField;
Var
  x, y, total, yOff, xOff: Integer;
Begin
  result := Nil;
  setlength(result, cols, rows);
  // 1. Fill
  For x := 0 To cols - 1 Do Begin
    For y := 0 To rows - 1 Do Begin
      result[x, y].bee := false;
      result[x, y].revealed := false;
      result[x, y].neighborCount := 0;
    End;
  End;
  total := 0;
  While total < min(TotalBeeCount, cols * rows - 1) Do Begin
    x := random(cols);
    y := random(rows);
    If (Not result[x, y].bee) And
      Not ((IgnoreX = x) And (IgnoreY = y))
      Then Begin
      result[x, y].bee := true;
      inc(total);
    End;
  End;
  // 2. Calculate the "neighbour" numbers
  For x := 0 To cols - 1 Do Begin
    For y := 0 To rows - 1 Do Begin
      If result[x, y].bee Then Begin
        result[x, y].neighborCount := -1; // Egal wird bei "bee's" nicht ausgewertet
      End
      Else Begin
        total := 0;
        For xOff := -1 To 1 Do Begin
          For yOff := -1 To 1 Do Begin
            If (x + xOff >= 0) And (x + xOff < cols) And
              (y + yOff >= 0) And (y + yOff < rows) Then Begin
              If result[x + xOff, y + yOff].bee Then inc(total);
            End;
          End;
        End;
        result[x, y].neighborCount := total;
      End;
    End;
  End;
End;

Procedure RenderFieldToCanvas(Const aCanvas: TCanvas; Const aField: TField;
  CellWidth, CellHeight: integer);
Var
  j, i: Integer;
  s: String;
Begin
  aCanvas.Pen.Color := clBlack;
  For i := 0 To high(aField) Do Begin
    For j := 0 To high(aField[i]) Do Begin
      If aField[i, j].revealed Then Begin
        aCanvas.Brush.Color := rgb(200, 200, 200);
      End
      Else Begin
        aCanvas.Brush.Color := clWhite;
      End;
      aCanvas.Rectangle(i * CellWidth, j * CellHeight, (i + 1) * CellWidth, (j + 1) * CellHeight);
      If aField[i, j].revealed Then Begin
        If aField[i, j].bee Then Begin
          aCanvas.Brush.Color := clWhite;
          aCanvas.Ellipse(
            i * CellWidth + CellWidth Div 4,
            j * CellHeight + CellHeight Div 4,
            (i + 1) * CellWidth - CellWidth Div 4,
            (j + 1) * CellHeight - CellHeight Div 4
            );
        End
        Else Begin
          If aField[i, j].neighborCount > 0 Then Begin
            s := inttostr(aField[i, j].neighborCount);
            aCanvas.TextOut(
              i * CellWidth + (CellWidth - aCanvas.TextWidth(s)) Div 2,
              j * CellHeight + (CellHeight - aCanvas.TextHeight(s)) Div 2,
              s
              );
          End;
        End;
      End;
    End;
  End;
End;

Procedure RenderEmptyFieldToCanvas(Const aCanvas: TCanvas; Colums, Rows,
  CellWidth, CellHeight: integer);
Var
  j, i: Integer;
Begin
  aCanvas.Pen.Color := clBlack;
  For i := 0 To Colums - 1 Do Begin
    For j := 0 To Rows - 1 Do Begin
      aCanvas.Brush.Color := clWhite;
      aCanvas.Rectangle(i * CellWidth, j * CellHeight, (i + 1) * CellWidth, (j + 1) * CellHeight);
    End;
  End;
End;

Procedure RevealNeighbours(Var aField: TField; x, y: Integer);
Var
  i, j: Integer;
Begin
  If (x < 0) Or (x > high(aField)) Or
    (y < 0) Or (y > high(aField[x])) Then exit;
  If aField[x, y].revealed Then exit;
  aField[x, y].revealed := true;

  If aField[x, y].neighborCount = 0 Then Begin
    For i := -1 To 1 Do Begin
      For j := -1 To 1 Do Begin
        RevealNeighbours(aField, i + x, j + y);
      End;
    End;
  End;
End;

Function RevealFieldCoordinate(Var aField: TField; x, y: Integer): Boolean;
Begin
  result := false;
  If aField[x, y].revealed Then exit;
  If aField[x, y].bee Then Begin // Hit Bee -> Lost
    aField[x, y].revealed := true;
    result := true;
    exit;
  End;
  If aField[x, y].neighborCount = 0 Then Begin
    RevealNeighbours(aField, x, y);
  End
  Else Begin
    aField[x, y].revealed := true;
  End;
End;

Function GameSolved(Const aField: TField): Boolean;
Var
  i, j: Integer;
Begin
  result := true;
  For i := 0 To high(aField) Do Begin
    For j := 0 To high(aField[i]) Do Begin
      If (Not aField[i, j].revealed) And (Not aField[i, j].bee) Then Begin
        result := false;
        exit;
      End;
    End;
  End;
End;

End.


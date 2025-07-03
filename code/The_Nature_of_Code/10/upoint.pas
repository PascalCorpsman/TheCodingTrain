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
Unit upoint;

{$MODE objfpc}{$H+}

Interface

Uses
  Classes, SysUtils, Graphics, ushared;

Type

  { Point }

  Point = Class
  private
    x, y, bias: Single;
  public // 32:11
    L: integer;

    Function Pixelx(): Single;
    Function Pixely(): Single;

    Constructor Create();
    Function inputs(): TFloatArray;
    Procedure Show(Const Canvas: tcanvas);
  End;

Function f(x: Single): Single;

Implementation

Const
  dim = 6;

Function f(x: Single): Single;
Begin
  // Y = mx + b
  result := 0.89 * x - 0.1;
End;

{ Point }

Function Point.Pixelx(): Single;
Begin
  result := map(-1, 1, x, 0, 200);
End;

Function Point.Pixely(): Single;
Begin
  result := map(-1, 1, y, 200, 0);
End;

Constructor Point.Create();
Begin
  x := (random(1000) - 500) / 500;
  y := (random(1000) - 500) / 500;
  bias := 1;
  If (y > f(x)) Then
    L := 1
  Else
    l := -1;
End;

Function Point.inputs(): TFloatArray;
Begin
  setlength(Result, 3);
  result[0] := x;
  result[1] := y;
  result[2] := bias;
End;

Procedure Point.Show(Const Canvas: tcanvas);
Var
  px, py: Single;
Begin
  If l = 1 Then Begin
    canvas.Brush.Color := clWhite;
  End
  Else Begin
    canvas.Brush.Color := clBlack;
  End;
  px := Pixelx;
  py := Pixely;
  canvas.Ellipse(round(px - dim), round(py - dim), round(px + dim), round(py + dim));
End;

End.


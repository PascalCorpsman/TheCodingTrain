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
Unit uquadtree_common;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils;

Type

  TCircle = Record
    x, y, r: Single;
  End;

  TQuadTreePoint = Record
    x, y: Single;
    UserData: Pointer;
  End;

  TQuadTreePointArray = Array Of TQuadTreePoint;

  (*
   * x,y = Mittelpunkt
   * w,h = Ausbreitung vom Mittelpunkt
   *)

  { TQuadRect }

  TQuadRect = Object
    x, y, w, h: Single;
    Function Contains(aPoint: TQuadTreePoint): Boolean;
    Function Intersects(Const aRange: TQuadRect): Boolean;
  End;

Function QuadRect(x, y, w, h: Single): TQuadRect;
Operator := (aRect: TRect): TQuadRect;
Operator := (aPoint: TPoint): TQuadTreePoint;

Implementation

Uses math;

Operator := (aRect: TRect): TQuadRect;
Begin
  Result.x := (aRect.left + aRect.Right) / 2;
  Result.y := (aRect.Top + aRect.Bottom) / 2;
  Result.w := (max(aRect.Right, aRect.left) - min(aRect.Right, aRect.Left)) / 2;
  Result.h := (max(aRect.Bottom, aRect.top) - min(aRect.Bottom, aRect.Top)) / 2;
End;

Operator := (aPoint: TPoint): TQuadTreePoint;
Begin
  result.x := aPoint.X;
  result.y := aPoint.Y;
  result.UserData := Nil;
End;

Function TQuadRect.Contains(aPoint: TQuadTreePoint): Boolean;
Begin
  result :=
    (aPoint.X >= self.x - self.w) And
    (aPoint.X <= self.x + self.w) And
    (aPoint.Y >= self.y - self.h) And
    (aPoint.Y <= self.y + self.h);
End;

Function TQuadRect.Intersects(Const aRange: TQuadRect): Boolean;
Begin
  result := Not (
    (aRange.x - aRange.w > self.x + Self.w) Or
    (aRange.x + aRange.w < self.x - Self.w) Or
    (aRange.y - aRange.h > self.y + Self.h) Or
    (aRange.y + aRange.h < self.y - Self.h)
    );
End;


Function QuadRect(x, y, w, h: Single): TQuadRect;
Begin
  result.x := x;
  result.y := y;
  result.w := w;
  result.h := h;
End;

End.


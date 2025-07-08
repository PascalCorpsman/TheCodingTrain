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
Unit uapplication;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, Graphics;

Procedure setup();
Procedure Draw();

Var
  MouseIsPressed: Boolean;
  mouseX, MouseY: integer;

Implementation

Uses Unit1;

Const
  stepsize = 5;

Var
  px, py, x, y: integer;
  step: integer = 1;
  state: integer = 0;
  numSteps: integer = 1;
  turnCOunter: integer = 0;
  totalsteps: integer;

Function isPrime(value: integer): Boolean;
Var
  i: Integer;
Begin
  result := true;
  If value = 1 Then result := false;
  If value = 2 Then exit;
  For i := 2 To trunc(sqrt(value)) + 1 Do Begin
    If value Mod i = 0 Then Begin
      result := false;
      exit;
    End;
  End;
End;

Procedure setup();
Var
  cols, rows: integer;
Begin
  form1.caption := 'Coding challenge 167';
  CreateCanvas(500, 500);

  cols := Width Div stepsize;
  rows := Height Div stepsize;
  totalsteps := cols * rows;

  x := Width Div 2;
  y := height Div 2;
  px := x;
  py := y;
  Background(0);
End;

Procedure Draw();
Begin
  fill(255);
  stroke(255);
  While step <= totalsteps Do Begin
    If (isPrime(step)) Then Begin
      circle(x, y, stepsize Div 2);
      //      Point(x, y);
    End;
    line(x, y, px, py);
    px := x;
    py := y;
    Case state Of
      0: x := x + stepsize;
      1: y := y - stepsize;
      2: x := x - stepsize;
      3: y := y + stepsize;
    End;
    If step Mod numSteps = 0 Then Begin
      state := (state + 1) Mod 4;
      turnCOunter := turnCounter + 1;
      If turnCOunter Mod 2 = 0 Then Begin
        numSteps := numSteps + 1;
      End;
    End;
    step := step + 1;
  End; // end while
  If step > totalsteps Then Begin
    noLoop();
  End;
  //FrameRate(1);
End;

End.


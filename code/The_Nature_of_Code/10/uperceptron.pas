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
Unit uperceptron;

{$MODE objfpc}{$H+}

Interface

Uses
  Classes, SysUtils, ushared;

Type

  { TPerceptron }

  TPerceptron = Class
  private
    Weights: TFloatArray;
    lr: Single; // LearnRate
  public
    Constructor Create(n: integer);
    Destructor Destroy(); override;
    Function Guess(Inputs: TFloatArray): integer;
    Procedure Train(Inputs: TFloatArray; Target: integer);
    Function Guessy(x: single): Single;
  End;

Implementation

Function Sign(Value: Single): Integer;
Begin
  If value >= 0 Then
    result := 1
  Else
    result := -1;
End;

{ TPerceptron }

Constructor TPerceptron.Create(n: integer);
Var
  i: Integer;
Begin
  Inherited create();
  setlength(Weights, n);
  For i := 0 To n Do Begin
    Weights[i] := (random(1000) / 1000) - 0.5;
  End;
  lr := 0.01;
End;

Destructor TPerceptron.Destroy();
Begin

End;

Function TPerceptron.Guess(Inputs: TFloatArray): integer;
Var
  f: Single;
  i: Integer;
Begin
  f := 0;
  For i := 0 To 1 Do Begin
    f := f + Inputs[i] * Weights[i];
  End;
  // Der Bias
  f := f + Weights[2];
  result := Sign(f);
End;

Procedure TPerceptron.Train(Inputs: TFloatArray; Target: integer);
Var
  g, e, i: integer;
Begin
  g := Guess(Inputs);
  E := Target - g;

  // Tune All the Weights
  For i := 0 To high(Weights) Do Begin
    Weights[i] := Weights[i] + e * Inputs[i] * lr;
  End;
End;

Function TPerceptron.Guessy(x: single): Single;
Var
  w0, w1, w2: Single;
Begin
  (*
   * Das Perceptron versucht die Formen:
   *  W0*x + W1*y + W2*1 = 0 zu "Erraten"
   * Löst man das nach y auf erhählt man die unten stehende Formel in die man
   * dann x einsetzen kann
   *)

  w0 := Weights[0];
  w1 := Weights[1];
  w2 := Weights[2];
  result := -(w2 / w1) * 1 - (w0 / w1) * x;
End;

End.


Unit uengine;

{$MODE objfpc}{$H+}

Interface

Uses
  Classes, SysUtils;

Type

  TField = Array[0..2, 0..2] Of integer; // Empty, Human, Ai

Const

  Draw = 0; // Draw game no winner
  Unknown = -2; // Winner not yet known (game is ongoing)
  Empty = 0; // Field is empty
  Human = 1; // Human, field is set by humar
  Ai = -1; // Ai, field is set by ai

  Weak_AI_Strength = 1;
  Strong_AI_Strength = 9;

  (*
   * Let the calculate the position of the next turn
   * Searchdepth is the strength
   * return is the position, where the AI would set its mark
   *)
Function ComputerMove(field: TField; SearchDepth: integer): Tpoint;

(*
 * Result is Unknown, Human, Ai, Draw
 *)
Function GetWinner(field: TField): integer;

Implementation

Function GetWinner(field: TField): integer;
Var
  b: Boolean;
  i, j: Integer;
Begin
  result := Unknown;
  // 1. Alle Felder sind belegt
  b := true;
  For i := 0 To 2 Do Begin
    For j := 0 To 2 Do Begin
      If field[i, j] = Empty Then Begin
        b := false;
        break;
      End;
    End;
    If Not b Then break;
  End;
  If b Then Begin // Kein Zug mehr Möglich => mindestens Unentschieden
    result := Draw;
  End;
  // Prüfen auf Sieger
  For i := 0 To 2 Do Begin
    // Senkrechte
    If (field[i, 0] <> Empty) And (field[i, 0] = field[i, 1]) And (field[i, 0] = field[i, 2]) Then Begin
      result := field[i, 0];
      break;
    End;
    // Waagrechte
    If (field[0, i] <> Empty) And (field[0, i] = field[1, i]) And (field[0, i] = field[2, i]) Then Begin
      result := field[0, i];
      break;
    End;
  End;
  // The diagonals
  If (Field[1, 1] <> Empty) Then Begin
    If ((field[0, 0] = field[1, 1]) And (field[0, 0] = field[2, 2])) Or
      ((field[2, 0] = field[1, 1]) And (field[2, 0] = field[0, 2])) Then Begin
      result := field[1, 1];
    End;
  End;
End;

Function getEmptyFieldCount(field: TField): integer;
Var
  i, j: integer;
Begin
  result := 0;
  For i := 0 To 2 Do Begin
    For j := 0 To 2 Do Begin
      If field[i, j] = Empty Then inc(result);
    End;
  End;
End;

Function alphabeta(field: TField; player, treeDepth, alpha, beta: integer): integer;
Var
  i, results, Winner, j: integer;
Begin
  winner := GetWinner(field);
  If Winner <> Unknown Then Begin
    result := -Winner;
    exit;
  End;
  If (treeDepth = 0) Then Begin // If we are not allowed to search any further
    result := Unknown;
    exit;
  End;
  For i := 0 To 2 Do Begin
    For j := 0 To 2 Do Begin
      If field[i, j] = Empty Then Begin
        field[i, j] := player;
        results := alphabeta(field, -player, treeDepth - 1, alpha, beta);
        field[i, j] := Empty;
        If player = Ai Then Begin
          If results > alpha Then alpha := results;
          If alpha >= beta Then Begin
            result := beta;
            exit;
          End;
        End
        Else Begin
          If results < beta Then beta := results;
          If beta <= alpha Then Begin
            result := alpha;
            exit;
          End;
        End;
      End;
    End;
  End;
  If player = Ai Then
    result := alpha
  Else
    result := beta;
End;

Function ComputerMove(field: TField; SearchDepth: integer): Tpoint;
Var
  i, j, bestMove, results: integer;
  choices: Array[0..8] Of TPoint;
  choicesCnt: integer;
Begin
  bestMove := Unknown;
  // If the board is empty start in the middle as this is the best chance to win.
  If (getEmptyFieldCount(field) = 9) Then Begin
    result := point(1, 1);
    exit;
  End;
  choicesCnt := 0;
  For i := 0 To 2 Do Begin
    For j := 0 To 2 Do Begin
      If field[i, j] = Empty Then Begin
        field[i, j] := Ai;
        results := alphabeta(field, Human, SearchDepth, -2, 2);
        //Das benutzte Feld wieder frei machen (Empty besitzt es mehr)
        field[i, j] := Empty;
        //Wenn das aktuelle Ergebnis besser ist als das letzte...
        If results > bestMove Then Begin
          bestMove := results;
          choices[0] := point(i, j);
          choicesCnt := 1;
        End
        Else Begin
          If results = bestMove Then Begin
            choices[choicesCnt] := point(i, j);
            choicesCnt := choicesCnt + 1;
          End;
        End;
      End;
    End;
  End;
  (*
   * Return the best calculated choice for the AI, if multiple choose a random
   *)
  If choicesCnt = 0 Then Begin
    Raise Exception.Create('Failure in algorithm.');
  End;
  If choicesCnt > 1 Then Begin
    result := choices[random(choicesCnt)];
  End
  Else Begin
    result := choices[0];
  End;
End;

End.


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
Unit unnMath;

{$MODE objfpc}{$H+}

Interface

Uses
  Classes, SysUtils;

Type
  (*
   * Mathematische Beschreibung einer Matrix ist Row x Col
   * eine 2 x 3 Matrix ist also:   (a b c)
   *                               (d e f)
   *)
  TMatrix = Array Of Array Of Single; // !! ACHTUNG, die Matrix Speichert sich intern row, col => d.h. [y,x]

  TMapFunction = Function(x: Single): Single;

  TVector = Array Of Single;

Function Matrix(rows, cols: integer): TMatrix; // Erstellt eine Matrix gefüllt mit 0en
Procedure Randomize(Var M: TMatrix); // Initialisiert mit Zufallszahlen von [-1 .. 1[
Function Transpose(Const M: TMatrix): TMatrix;
Function Hadamard(Const A: TMatrix; Const b: TMatrix): TMatrix; // Kompenentenweise Multiplikation

Procedure MapMatrix(Var M: TMatrix; MapFunction: TMapFunction); // Wendet die Funktion Mapfunktion auf alle Elemente einer Matrix an
Function MapMatrix2(Const M: TMatrix; MapFunction: TMapFunction): TMatrix; // Wendet die Funktion Mapfunktion auf alle Elemente einer Matrix an

Function Plot(Const V: TVector): String; // Gibt einen Formatierten String aus wie oben
Function Plot(Const M: TMatrix): String; // Gibt einen Formatierten String aus wie oben

// Scalare Operanden
Operator * (Const A: TMatrix; Const b: Single): TMatrix;
Operator * (Const A: Single; Const b: TMatrix): TMatrix;
Operator + (Const A: TMatrix; Const b: Single): TMatrix;
// Elementwise Operanden
Operator + (Const A: TMatrix; Const b: TMatrix): TMatrix;
Operator - (Const A: TMatrix; Const b: TMatrix): TMatrix;
// Operator * (Const A: TMatrix; Const b: TMatrix): TMatrix; // Komponentenweise Multiplikation = Hadamard Produkt
// Matrix Product
Operator * (Const A: TMatrix; Const b: TMatrix): TMatrix;

Function Vector(data: Array Of Single): TVector;
Function VectorToMatrix(Const V: TVector): TMatrix;
Function MatrixToVector(Const M: TMatrix): TVector;

Implementation

Function Vector(data: Array Of Single): TVector;
Var
  i: Integer;
Begin
  setlength(result, length(data));
  For i := 0 To high(data) Do Begin
    result[i] := data[i];
  End;
End;

Function VectorToMatrix(Const V: TVector): TMatrix;
Var
  i: Integer;
Begin
  setlength(result, length(V), 1);
  For i := 0 To high(v) Do Begin
    result[i, 0] := v[i];
  End;
End;

Function MatrixToVector(Const M: TMatrix): TVector;
Var
  i, c, j: Integer;
Begin
  setlength(result, length(m) * length(m[0]));
  c := 0;
  For i := 0 To high(m[0]) Do Begin
    For j := 0 To high(m) Do Begin
      result[c] := m[j, i];
      inc(c);
    End;
  End;
End;

Operator + (Const A: TMatrix; Const b: Single): TMatrix;
Var
  i, j: integer;
Begin
  setlength(result, length(a), length(a[0]));
  For j := 0 To high(a) Do Begin
    For i := 0 To high(a[j]) Do Begin
      result[j, i] := a[j, i] + b;
    End;
  End;
End;

Operator + (Const A: TMatrix; Const b: TMatrix): TMatrix;
Var
  i, j: integer;
Begin
  If (length(a) <> length(b)) Or
    (length(a[0]) <> length(b[0])) Then Raise Exception.Create('Operator Matrix + Matrix, invalid dimension.');
  setlength(result, length(a), length(a[0]));
  For j := 0 To high(a) Do Begin
    For i := 0 To high(a[j]) Do Begin
      result[j, i] := a[j, i] + b[j, i];
    End;
  End;
End;

Operator - (Const A: TMatrix; Const b: TMatrix): TMatrix;
Var
  i, j: integer;
Begin
  If (length(a) <> length(b)) Or
    (length(a[0]) <> length(b[0])) Then Raise Exception.Create('Operator Matrix + Matrix, invalid dimension.');
  setlength(result, length(a), length(a[0]));
  For j := 0 To high(a) Do Begin
    For i := 0 To high(a[j]) Do Begin
      result[j, i] := a[j, i] - b[j, i];
    End;
  End;
End;

Function Plot(Const V: TVector): String;
Var
  i: integer;
Begin
  result := '(';
  For i := 0 To high(v) Do Begin
    result := result + format('%3.1f', [v[i]]);
    If i <> high(v) Then
      result := result + ' ';
  End;
  result := result + ')';
End;

Function Plot(Const M: TMatrix): String;
Var
  i, j: integer;
Begin
  result := '';
  For j := 0 To high(m) Do Begin
    If j <> 0 Then result := result + LineEnding;
    result := result + '(';
    For i := 0 To high(m[j]) Do Begin
      result := result + format('%3.1f', [m[j, i]]);
      If i <> high(m[j]) Then
        result := result + '/';
    End;
    result := result + ')';
  End;
End;

Operator * (Const A: TMatrix; Const b: Single): TMatrix;
Var
  i, j: integer;
Begin
  setlength(result, length(a), length(a[0]));
  For j := 0 To high(a) Do Begin
    For i := 0 To high(a[j]) Do Begin
      result[j, i] := a[j, i] * b;
    End;
  End;
End;

Operator * (Const A: Single; Const b: TMatrix): TMatrix;
Begin
  result := b * a;
End;

Function Hadamard(Const A: TMatrix; Const b: TMatrix): TMatrix;
Var
  i, j: integer;
Begin
  If (length(a) <> length(b)) Or
    (length(a[0]) <> length(b[0])) Then Raise Exception.Create('Operator Matrix * Matrix, invalid dimension.');
  setlength(result, length(a), length(a[0]));
  For j := 0 To high(a) Do Begin
    For i := 0 To high(a[j]) Do Begin
      result[j, i] := a[j, i] * b[j, i];
    End;
  End;
End;

Operator * (Const A: TMatrix; Const b: TMatrix): TMatrix;
Var
  i, j, k: Integer;
  sum: Single;
Begin
  If length(a[0]) <> length(b) Then Begin
    Raise Exception.Create('Operator Matrix dot Matrix, invalid dimension');
  End;
  setlength(result, length(a), length(b[0]));
  For j := 0 To high(result) Do
    For i := 0 To high(result[0]) Do Begin
      // Dot procukt of values in Col
      sum := 0;
      For k := 0 To high(a[0]) Do Begin
        sum := sum + a[j, k] * b[k, i];
      End;
      result[j, i] := sum;
    End;
End;

Function Matrix(rows, cols: integer): TMatrix;
Var
  j, i: Integer;
Begin
  setlength(result, rows, cols);
  For j := 0 To rows - 1 Do Begin
    For i := 0 To cols - 1 Do Begin
      result[j, i] := 0;
    End;
  End;
End;

Procedure Randomize(Var M: TMatrix);
Var
  j, i: Integer;
Begin
  For j := 0 To high(M) Do Begin
    For i := 0 To high(M[j]) Do Begin
      M[j, i] := (random(1000) / 1000) * 2 - 1;
    End;
  End;
End;

Function Transpose(Const M: TMatrix): TMatrix;
Var
  i, j: Integer;
Begin
  setlength(result, length(m[0]), length(m));
  For j := 0 To high(m) Do
    For i := 0 To high(m[0]) Do Begin
      result[i, j] := m[j, i];
    End;
End;

Procedure MapMatrix(Var M: TMatrix; MapFunction: TMapFunction);
Var
  i, j: integer;
Begin
  For j := 0 To high(m) Do
    For i := 0 To high(m[0]) Do Begin
      M[j, i] := MapFunction(m[j, i]);
    End;
End;

Function MapMatrix2(Const M: TMatrix; MapFunction: TMapFunction): TMatrix;
Var
  i, j: integer;
Begin
  setlength(result, length(m), length(m[0]));
  For j := 0 To high(m) Do
    For i := 0 To high(m[0]) Do Begin
      result[j, i] := MapFunction(m[j, i]);
    End;
End;

End.


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
Unit ushared;

{$MODE objfpc}{$H+}

Interface

Uses
  Classes, SysUtils;

Type
  TFloatArray = Array Of Single;

Function map(vmin, vmax, v: Single; rmin, rmax: Single): Single;

Implementation

Function map(vmin, vmax, v: Single; rmin, rmax: Single): Single;
Begin
  If (vmax - vmin = 0) Then Begin // Div by 0 abfangen
    result := rmin;
    exit;
  End
  Else Begin
    result := ((((v - vmin) * (rmax - rmin)) / (vmax - vmin)) + rmin);
  End;
End;

End.


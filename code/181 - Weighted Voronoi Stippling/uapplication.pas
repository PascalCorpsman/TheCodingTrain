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
  Classes, SysUtils, Graphics, uvectormath;

Procedure setup();
Procedure Draw();

Implementation

Uses uNodeJs;

Var
  points: TVector2Array;
  Voronoi: TVoronoi;
  Gloria: TNodeJsImage;

  (*
   * Returns the index of the Voronoi Polygon that contains the coordinate x, y
   *)

Function delaunayfind(x, y: integer; i: integer = -1): Integer;
Var
  ii: Integer;
Begin
  result := -1;
  If i <> -1 Then Begin
    If PointInPolygon(v2(x, y), Voronoi[i]) Then Begin
      result := i;
      exit;
    End;
  End;
  For ii := 0 To high(Voronoi) Do Begin
    If PointInPolygon(v2(x, y), Voronoi[ii]) Then Begin
      result := ii;
      exit;
    End;
  End;
End;

Procedure setup();
Var
  x, y, i: Integer;
  col: TColor;
Begin
  Document.Title := 'Coding Challenge 181: Weighted Voronoi Stippling';
  gloria := LoadImage('gloria_pickle.jpg');
  gloria.LoadPixels();
  CreateCanvas(gloria.Width, gloria.Height);
  points := Nil;
  i := 0;
  While i < 1000 Do Begin // In the Video this is 10000, but thats really slow, if set this to 10000, change lerp to 1 to get a faster result !
    x := Random(Width);
    y := Random(Height);
    col := gloria.get(x, y);
    // The orig image from the video seem to have a alpha channel, and
    // brightness of transparent seems to be 0
    // In order to get the same results, we filter here for clWhite
    If Brightness(clwhite - col) > 3 Then Begin
      If random(240) > Brightness(col) Then
        points.Push(v2(x, y));
    End
    Else
      dec(i);
    inc(i);
  End;
  // Gloria.free; --> This creates a Memory Leak, as we do not have a "Close" method, but gives access to the image from the Draw function
  Voronoi := PointsToVoronoiPolygons(points, v2(0, 0), v2(Width - 1, Height - 1));
  // noLoop;
End;

Procedure Draw();
Var
  centroids: TVector2Array;
  weights: TVectorN;
  v0: TVector2;
  newdelauanyIndex, j, i, index, delauanyIndex: Integer;
  weight, bright: Single;
  r, g, b: Byte;
Begin
  Background(clWhite);
  // { -- Disable Rendering the Dots
  For v0 In points Do Begin
    Stroke(0);
    strokeweight(4);
    Point(v0.x, v0.y);
  End;
  // }
  { -- Disable Rendering the Voronoi diagram ;)
  For j := 0 To high(Voronoi) Do Begin
    stroke(0);
    StrokeWeight(1);
    noFill();
    BeginShape();
    For i := 0 To high(Voronoi[j]) Do Begin
      Vertex(Voronoi[j, i].x, Voronoi[j, i].y);
    End;
    EndShape();
  End;
  // }
  centroids := Nil;
  weights := Nil;
  setlength(centroids, length(Voronoi));
  setlength(weights, length(Voronoi));
  weights.Fill(0);
  delauanyIndex := -1;
  For i := 0 To Width - 1 Do Begin
    For j := 0 To Height - 1 Do Begin
      newdelauanyIndex := delaunayfind(i, j, delauanyIndex);
      If newdelauanyIndex = -1 Then Continue;
      delauanyIndex := newdelauanyIndex;
      index := (i + j * Width) * 4;
      r := Gloria.Pixels[index + 0];
      g := Gloria.Pixels[index + 1];
      b := Gloria.Pixels[index + 2];
      bright := (r + g + b) / 3;
      weight := 1 - bright / 255;
      centroids[delauanyIndex].x := centroids[delauanyIndex].x + i * weight;
      centroids[delauanyIndex].y := centroids[delauanyIndex].y + j * weight;
      weights[delauanyIndex] := weights[delauanyIndex] + weight;
    End;
  End;
  For i := 0 To high(centroids) Do Begin
    If weights[i] <> 0 Then Begin
      centroids[i] := centroids[i] / weights[i];
    End
    Else Begin
      centroids[i] := points[i];
    End;
  End;

  // Lerp Points to "centroid" and recalculate the Voronoi Polygons
  For i := 0 To high(centroids) Do Begin
    Points[i].lerp(centroids[i], 0.1);
  End;
  Voronoi := PointsToVoronoiPolygons(points, v2(0, 0), v2(Width - 1, Height - 1));
End;

End.


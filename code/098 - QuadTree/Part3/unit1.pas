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

(*
 * Set / not set this define to see the differences in FPS ;)
 *)
{.$DEFINE QuadTreeVersion}

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, uparticle
{$IFDEF QuadTreeVersion}
  , uquadtree
  , uquadtree_common
{$ENDIF}
  ;


Type

  { TForm1 }

  TForm1 = Class(TForm)
    PaintBox1: TPaintBox;
    Procedure FormCloseQuery(Sender: TObject; Var CanClose: Boolean);
    Procedure FormCreate(Sender: TObject);
    Procedure FormDestroy(Sender: TObject);
    Procedure PaintBox1Paint(Sender: TObject);
  private
    Particles: Array Of TParticle;
    OnCloseFired: Boolean;
    FrameRateCounterTime: QWord;
    FrameRateCounter: integer;
{$IFDEF QuadTreeVersion}
    qTree: TQuadTree;
{$ENDIF}
  public

  End;

Var
  Form1: TForm1;

Implementation

{$R *.lfm}

Const
  ParticleRadius = 4;

  { TForm1 }

Procedure TForm1.FormCreate(Sender: TObject);
Var
  i: Integer;
Begin
  Randomize;
  OnCloseFired := false;
  Particles := Nil;
  setlength(Particles, 4000); // Trim this value to get a "low" framerate on your computer, after that enable the QuadTreeVersion define to see the improfment
  // setlength(Particles, 1000);
  For i := 0 To high(Particles) Do Begin
    Particles[i] := TParticle.Create(random(PaintBox1.Width), random(PaintBox1.Height), ParticleRadius);
  End;
  FrameRateCounterTime := GetTickCount64;
  FrameRateCounter := 0;
{$IFDEF QuadTreeVersion}
  qTree := TQuadTree.Create(Rect(0, 0, PaintBox1.Width, PaintBox1.Height), 4);
{$ENDIF}
  PaintBox1.Invalidate;
End;

Procedure TForm1.FormDestroy(Sender: TObject);
Begin
{$IFDEF QuadTreeVersion}
  qTree.free;
  qTree := Nil;
{$ENDIF}
End;

Procedure TForm1.FormCloseQuery(Sender: TObject; Var CanClose: Boolean);
Begin
  OnCloseFired := true;
End;

Procedure TForm1.PaintBox1Paint(Sender: TObject);
Var
  i, j: Integer;
  n: QWord;
{$IFDEF QuadTreeVersion}
  pp: TQuadTreePoint;
  others: TQuadTreePointArray;
  circle: TCircle;
  other: TParticle;
{$ENDIF}
Begin
  PaintBox1.Canvas.Brush.Color := clBlack;
  PaintBox1.Canvas.Brush.Style := bsSolid;
  PaintBox1.Canvas.Rectangle(-1, -1, PaintBox1.Width + 1, PaintBox1.Height + 1);
{$IFDEF QuadTreeVersion}
  qTree.Clear();
{$ENDIF}
  For i := 0 To high(Particles) Do Begin
    Particles[i].Move();
    Particles[i].Render(PaintBox1.Canvas);
    Particles[i].SetHighLight(false);
{$IFDEF QuadTreeVersion}
    pp := Particles[i].point;
    pp.UserData := @Particles[i];
    qTree.Insert(pp);
{$ENDIF}
  End;
  // -- "Slow" version without Quadtree
  For i := 0 To high(Particles) Do Begin
{$IFDEF QuadTreeVersion}
    circle.x := Particles[i].Point().x;
    circle.y := Particles[i].Point().Y;
    circle.r := ParticleRadius * 2;
    others := qTree.Query(Circle);
    For j := 0 To high(others) Do Begin
      other := TParticle(others[j].UserData^);
      If Particles[i] <> other Then Begin
        If Particles[i].intersects(other) Then Begin
          Particles[i].SetHighLight(true);
        End;
      End;
    End;
{$ELSE}
    For j := 0 To high(Particles) Do Begin
      If i <> j Then Begin
        If Particles[i].intersects(Particles[j]) Then Begin
          Particles[i].SetHighLight(true);
        End;
      End;
    End;
{$ENDIF}
  End;
  inc(FrameRateCounter);
  n := GetTickCount64;
  If FrameRateCounterTime + 1000 <= n Then Begin
    FrameRateCounterTime := n;
    caption := format('Framerate: %d FPS, using %d particles', [FrameRateCounter, length(Particles)])
{$IFDEF QuadTreeVersion}
    + ' using a quadtree'
{$ENDIF}
    ;
    FrameRateCounter := 0;
  End;
  If Not OnCloseFired Then
    Invalidate;
End;

End.


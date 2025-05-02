Unit uspring;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, Graphics
  , uparticle
  , uvectormath
  ;

Type

  { TSpring }

  TSpring = Class
  private
    k, restlength: Single;
    a, b: TParticle;
  public
    Constructor Create(ak, aRestlength: Single; aA, aB: TParticle); virtual;
    Procedure Update();
    Procedure Show(Const aCanvas: TCanvas);
  End;

Implementation

{ TSpring }

Constructor TSpring.Create(ak, aRestlength: Single; aA, aB: TParticle);
Begin
  Inherited create();
  k := ak;
  restlength := aRestlength;
  a := aA;
  b := aB;
End;

Procedure TSpring.Update;
Var
  Force: TVector2;
  x: Single;
Begin
  force := b.Position - a.Position;
  x := LenV2(force) - restlength;
  force := NormV2(force);
  force := k * x * force;
  a.ApplyForce(Force);
  Force := -1 * Force;
  b.ApplyForce(Force);
End;

Procedure TSpring.Show(Const aCanvas: TCanvas);
Begin
  aCanvas.Pen.Width := 4;
  aCanvas.Pen.Color := clWhite;
  acanvas.Line(
    round(a.Position.x)
    , round(a.Position.y)
    , round(b.Position.x)
    , round(b.Position.y)
    );
End;

End.


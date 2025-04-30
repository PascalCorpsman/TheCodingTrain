Unit uparticle;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, Graphics;

Type

  { TParticle }

  TParticle = Class
  private
    fx, fy, fr: Single;
    fhighlight: Boolean;
  public
    Constructor Create(x, y, r: Single);
    Procedure Move();
    Procedure Render(Const aCanvas: tcanvas);
    Function intersects(Const other: TParticle): Boolean;
    Procedure SetHighLight(aValue: Boolean);
    Function Point(): TPoint;
  End;

Implementation

{ TParticle }

Constructor TParticle.Create(x, y, r: Single);
Begin
  fx := x;
  fy := y;
  fr := r;
  fhighlight := false;
End;

Procedure TParticle.Move;
Begin
  fx := fx + random(3) - 1;
  fy := fy + random(3) - 1;

End;

Procedure TParticle.Render(Const aCanvas: tcanvas);
Begin
  aCanvas.Brush.Style := bsSolid;
  If fhighlight Then Begin
    aCanvas.Brush.Color := clWhite;
    aCanvas.Pen.Color := clWhite;
  End
  Else Begin
    aCanvas.Brush.Color := clGray;
    aCanvas.Pen.Color := clGray;
  End;
  aCanvas.Ellipse(
    round(fx - fr),
    round(fy - fr),
    round(fx + fr),
    round(fy + fr)
    );
End;

Function TParticle.intersects(Const other: TParticle): Boolean;
Var
  d: Single;
Begin
  d := sqrt(sqr(fx - other.fx) + sqr(fy - other.fy));
  result := d < (fr + other.fr);
End;

Procedure TParticle.SetHighLight(aValue: Boolean);
Begin
  fhighlight := aValue;
End;

Function TParticle.Point(): TPoint;
Begin
  result.x := round(fx);
  result.Y := round(fy);
End;

End.


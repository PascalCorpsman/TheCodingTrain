Unit uparticle;

{$MODE ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, Graphics, uvectormath;

Type

  { TParticle }

  TParticle = Class
  private
    Acceleration: TVector2;
    mass: Single;
  public
    locked: Boolean;
    Velocity: TVector2;
    position: TVector2;

    Constructor Create(x, y: Single); virtual;
    Procedure Show(Const aCanvas: TCanvas);
    Procedure ApplyForce(aForce: TVector2);
    Procedure Update();
  End;

Implementation

{ TParticle }

Constructor TParticle.Create(x, y: Single);
Begin
  Inherited create();
  Locked := false;
  Acceleration := v2(0, 0);
  Velocity := v2(0, 0);
  position := v2(x, y);
  mass := 1;
End;

Procedure TParticle.Show(Const aCanvas: TCanvas);
Const
  diam = 16;
Begin
  aCanvas.Brush.Color := RGBToColor(45, 197, 244);
  aCanvas.Brush.Style := bsSolid;
  aCanvas.Pen.Color := clwhite;
  aCanvas.Pen.Width := 2;
  aCanvas.Ellipse(
    round(position.x - diam / 2)
    , round(position.y - diam / 2)
    , round(position.x + diam / 2)
    , round(position.y + diam / 2)
    );
End;

Procedure TParticle.ApplyForce(aForce: TVector2);
Begin
  aForce := aForce / mass;
  Acceleration := Acceleration + aForce;
End;

Procedure TParticle.Update;
Begin
  If Locked Then exit;
  Velocity := Velocity * 0.99;
  Velocity := Velocity + Acceleration;
  position := position + Velocity;
  Acceleration := Acceleration * 0;
End;

End.


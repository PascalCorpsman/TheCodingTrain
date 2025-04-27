Unit uquadtree;

{$MODE ObjFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}

Interface

Uses
  Classes, SysUtils, Graphics;

Type

  (*
   * x,y = Mittelpunkt
   * w,h = Ausbreitung vom Mittelpunkt
   *)
  TQuadRect = Record
    x, y, w, h: Single;
Function Contains(aPoint: TPoint): Boolean;
  End;

  { TQuadTree }

  TQuadTree = Class
  private
    fdivided: Boolean;
    fboundary: TQuadRect;
    fCapacity: integer;
    fPoints: Array Of TPoint;
    fNorthWest: TQuadTree;
    fNorthEast: TQuadTree;
    fSouthWest: TQuadTree;
    fSouthEast: TQuadTree;
    Procedure Subdivide;
  public
    Constructor Create(aBoundary: TRect; aCapacity: integer); overload; virtual;
    Constructor Create(aBoundary: TQuadRect; aCapacity: integer); overload; virtual;
    Destructor Destroy(); override;
    Function Insert(aPoint: TPoint): Boolean;
    Procedure Show(Const aCanvas: TCanvas);
  End;

Implementation

Uses math;

Function TQuadRect.Contains(aPoint: TPoint): Boolean;
Begin
  result :=
    (aPoint.X >= self.x - self.w) And
    (aPoint.X <= self.x + self.w) And
    (aPoint.Y >= self.y - self.h) And
    (aPoint.Y <= self.y + self.h);
End;

Function QuadRect(x, y, w, h: Single): TQuadRect;
Begin
  result.x := x;
  result.y := y;
  result.w := w;
  result.h := h;
End;

{ TQuadTree }

Constructor TQuadTree.Create(aBoundary: TRect; aCapacity: integer);
Begin
  (*
   * Umrechnen Trect nach TQuadRect
   *)
  fboundary.x := (aBoundary.left + aBoundary.Right) / 2;
  fboundary.y := (aBoundary.Top + aBoundary.Bottom) / 2;
  fboundary.w := (max(aBoundary.Right, aBoundary.left) - min(aBoundary.Right, aBoundary.Left)) / 2;
  fboundary.h := (max(aBoundary.Bottom, aBoundary.top) - min(aBoundary.Bottom, aBoundary.Top)) / 2;
  fCapacity := aCapacity;
  fPoints := Nil;
  fNorthWest := Nil;
  fNorthEast := Nil;
  fSouthWest := Nil;
  fSouthEast := Nil;
  fdivided := false;

End;

Constructor TQuadTree.Create(aBoundary: TQuadRect; aCapacity: integer);
Begin
  fboundary := aBoundary;
  fCapacity := aCapacity;
  fPoints := Nil;
  fNorthWest := Nil;
  fNorthEast := Nil;
  fSouthWest := Nil;
  fSouthEast := Nil;
  fdivided := false;
End;

Destructor TQuadTree.Destroy();
Begin
  If fdivided Then Begin
    fNorthWest.free;
    fNorthEast.free;
    fSouthWest.free;
    fSouthEast.free;
  End;
  fdivided := false;
  Inherited Destroy();
End;

Procedure TQuadTree.Subdivide;
Var
  x, y, w, h: Single;
Begin
  x := fboundary.x;
  y := fboundary.y;
  w := fboundary.w / 2;
  h := fboundary.h / 2;

  fNorthWest := TQuadTree.create(QuadRect(x - w, y - h, w, h), fCapacity);
  fNorthEast := TQuadTree.create(QuadRect(x + w, y - h, w, h), fCapacity);
  fSouthWest := TQuadTree.create(QuadRect(x - w, y + h, w, h), fCapacity);
  fSouthEast := TQuadTree.create(QuadRect(x + w, y + h, w, h), fCapacity);
  fdivided := true;
End;

Function TQuadTree.Insert(aPoint: TPoint): Boolean;
Begin
  result := false;
  If Not fboundary.Contains(aPoint) Then exit;
  If length(fPoints) < fCapacity Then Begin
    setlength(fPoints, high(fPoints) + 2);
    fPoints[high(fPoints)] := aPoint;
    result := true;
  End
  Else Begin
    If Not fdivided Then Begin
      subdivide;
    End;
    result := fNorthWest.Insert(aPoint);
    If result Then exit;
    result := fNorthEast.Insert(aPoint);
    If result Then exit;
    result := fSouthWest.Insert(aPoint);
    If result Then exit;
    result := fSouthEast.Insert(aPoint);
    If result Then exit;
  End;
End;

Procedure TQuadTree.Show(Const aCanvas: TCanvas);
Const
  Stroke = 2;

  Procedure Point(x, y: integer);
  Begin
    aCanvas.Ellipse(x - Stroke, y - Stroke, x + Stroke, y + Stroke);
  End;

Var
  i: Integer;
Begin
  aCanvas.Brush.Style := bsClear;
  aCanvas.Pen.Color := clWhite;
  aCanvas.Rectangle(
    round(fboundary.x - fboundary.w),
    round(fboundary.y - fboundary.h),
    round(fboundary.x + fboundary.w),
    round(fboundary.y + fboundary.h)
    );
  If fdivided Then Begin
    fNorthWest.Show(aCanvas);
    fNorthEast.Show(aCanvas);
    fSouthWest.Show(aCanvas);
    fSouthEast.Show(aCanvas);
  End;
  aCanvas.Brush.Style := bsSolid;
  aCanvas.Brush.Color := clWhite;
  aCanvas.Pen.Color := clWhite;
  For i := 0 To high(fPoints) Do Begin
    Point(fPoints[i].x, fPoints[i].y);
  End;

End;

End.


Unit uquadtree;

{$MODE ObjFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}
{$MODESWITCH TypeHelpers}

Interface

Uses
  Classes, SysUtils, Graphics;

Type

  TPointArray = Array Of TPoint;

  (*
   * x,y = Mittelpunkt
   * w,h = Ausbreitung vom Mittelpunkt
   *)

  { TQuadRect }

  TQuadRect = Record
    x, y, w, h: Single;
Function Contains(aPoint: TPoint): Boolean;
Function Intersects(Const aRange: TQuadRect): Boolean;
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
    Function Query(aRange: TRect): TPointArray;
  End;

Implementation

Uses math;

Operator := (aRect: TRect): TQuadRect;
Begin
  Result.x := (aRect.left + aRect.Right) / 2;
  Result.y := (aRect.Top + aRect.Bottom) / 2;
  Result.w := (max(aRect.Right, aRect.left) - min(aRect.Right, aRect.Left)) / 2;
  Result.h := (max(aRect.Bottom, aRect.top) - min(aRect.Bottom, aRect.Top)) / 2;
End;

Function TQuadRect.Contains(aPoint: TPoint): Boolean;
Begin
  result :=
    (aPoint.X >= self.x - self.w) And
    (aPoint.X <= self.x + self.w) And
    (aPoint.Y >= self.y - self.h) And
    (aPoint.Y <= self.y + self.h);
End;

Function TQuadRect.Intersects(Const aRange: TQuadRect): Boolean;
Begin
  result := Not (
    (aRange.x - aRange.w > self.x + Self.w) Or
    (aRange.x + aRange.w < self.x - Self.w) Or
    (aRange.y - aRange.h > self.y + Self.h) Or
    (aRange.y + aRange.h < self.y - Self.h)
    );
End;

Function QuadRect(x, y, w, h: Single): TQuadRect;
Begin
  result.x := x;
  result.y := y;
  result.w := w;
  result.h := h;
End;

Type

  { TPointArrayHelper }

  TPointArrayHelper = Type Helper For TPointArray
    Procedure Concat(Const aData: TPointArray);
  End;

  { TPointArrayHelper }

Procedure TPointArrayHelper.Concat(Const aData: TPointArray);
Var
  len, i: integer;
Begin
  If Not assigned(adata) Then exit;
  len := length(self);
  setlength(self, len + length(aData));
  For i := 0 To high(aData) Do Begin
    self[i + len] := aData[i];
  End;
End;

{ TQuadTree }

Constructor TQuadTree.Create(aBoundary: TRect; aCapacity: integer);
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

Destructor TQuadTree.Destroy;
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
  Stroke = 1;

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

Function TQuadTree.Query(aRange: TRect): TPointArray;
Var
  tmp: TQuadRect;
  i: Integer;
Begin
  result := Nil;
  tmp := aRange;
  If Not fboundary.Intersects(tmp) Then exit;
  For i := 0 To high(fPoints) Do Begin
    If tmp.Contains(fPoints[i]) Then Begin
      setlength(result, high(result) + 2);
      result[high(result)] := fPoints[i];
    End;
  End;
  If fdivided Then Begin
    result.Concat(fNorthWest.Query(aRange));
    result.Concat(fNorthEast.Query(aRange));
    result.Concat(fSouthWest.Query(aRange));
    result.Concat(fSouthEast.Query(aRange));
  End;
End;

End.


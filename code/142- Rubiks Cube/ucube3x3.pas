Unit ucube3x3;

{$MODE objfpc}{$H+}

Interface

Uses
  Classes, SysUtils, Graphics, uopengl_graphikengine, dglopengl,
  uvectormath, ugraphics, math, dialogs;

Const

  CubeColors: Array[0..5] Of TColor = (clwhite, clred, clblue, $000080FF, clgreen, clyellow);
  //  CubeColors: Array[0..5] Of TColor = (clwhite, $000080FF, clblue, $009314FF, clgreen, clpurple);// Claudia Farben
  GridCol = $C0C0C0; // Farbe des Grid der SubWürfel

Type

  TProgramState = (psAnim, psWait, psMakeFirstLevel, psMakeSecondLevel, psMakeThirdLevel, psFinish);

  TCube = Array[0..5] Of Array[0..8] Of 0..5; // Der Würfeldatentyp

  TJob = (x1, xm1, x2, xm2, x3, xm3, // Die Verschiedenen Job Arten
    Y1, Ym1, Y2, Ym2, Y3, Ym3,
    Z1, Zm1, Z2, Zm2, Z3, Zm3);

  Tltodo = Array Of TJob;

Var
  RotMatrix: TMatrix4x4;
  ProgramState: TProgramState = pswait;
  AnimJob: TJob;
  AnimCount: Single = 0;
  GlobalToDoList: Tltodo;

Procedure DrawJobAnim(Const Cube: TCube; Job: TJob; Count: Single; Grid, RenderArrows: Boolean); // Rendert einen Würfel Job, Count in [0..99] 0 = Ausgangsstellung, 99 = Fertig
Procedure DrawCube(Const Cube: TCube; RenderArrows, RenderIDs, Grid: Boolean); // Rendert einen Cube mit oder ohne ID's
Function ClearCube(): TCube; // Liefert einen Sauberen Leeren Würfel.
Function ColorToCubePos(Const Color: TColor): Tpoint; // Wandelt eine Farbe in eine TCube Position um
Function ColorToArrowID(Const Color: TColor): Integer; // Wandelt eine Farbe in eine Pfeil ID um
Procedure StartAutoAnim(Job: TJob); // Startet die Automatische Animation des Jobs
Procedure DoJob(Job: TJob; Var Cube: TCube); // Führt einen Job aus
Function IndexToJob(Index: Integer): TJob;
Function Checkcube(Const Cube: TCube): Boolean;
// Schaltet durch die Einzelnen Berechnungen durch
Procedure BerechneToDoNexteEbene(Const Cube: TCube; Var ToDoList: TLtodo);
// Die Solve Stufen
Procedure PreSolve(Const Cube: TCube; Var ToDoList: TLtodo); // Sollte es schon Fertige Ebenen geben werden diese hier nach oben gedreht
// Dreht die 1. Ebene Hin
Procedure MakeFirstLevel(Const Cube: TCube; Var ToDoList: TLtodo);
// Dreht die 2. Ebene Hin
Procedure MakeSecondLevel(Const Cube: TCube; Var ToDoList: TLtodo);
// Dreht die 3. Ebene Hin
Procedure MakeThirdLevel(Const Cube: TCube; Var ToDoList: TLtodo);

Implementation

Type
  Tkante = Record
    fx, sx: 0..5;
    fy, sy: 0..9;
  End;

  TKantenfarbe = Record
    fc, sc: 0..5;
  End;

  Tecke = Record
    fx, sx, tx: 0..5;
    fy, sy, ty: 0..9;
  End;

  TEckenfarbe = Record
    fc, sc, tc: 0..5;
  End;

Var
  Kanten: Array[0..11] Of TKante;
  KantenFarbe: Array[0..11] Of TKantenfarbe;
  Ecken: Array[0..7] Of TEcke;
  Eckenfarbe: Array[0..7] Of TEckenfarbe;

Procedure BerechneToDoNexteEbene(Const Cube: TCube; Var ToDoList: TLtodo);
Var
  b: Boolean;
Begin
  b := true;
  // Wir suchen so lange bis wir was zu tun haben ..
  While b Do Begin
    Case ProgramState Of
      psWait: Begin
          // Wenn es einen "Pre" Job gibt
          PreSolve(cube, ToDoList);
          // Liste für die 1. Ebene
          MakeFirstLevel(cube, ToDoList);
          ProgramState := psMakeFirstLevel;
        End;
      // Start Sortieren Ebene 2
      psMakeFirstLevel: Begin
          MakeSecondLevel(cube, ToDoList);
          ProgramState := psMakeSecondLevel;
        End;
      // Start Sortieren Ebene 3
      psMakeSecondLevel: Begin
          MakeThirdLevel(cube, ToDoList);
          ProgramState := psMakeThirdLevel;
        End;
      psMakeThirdLevel: Begin
          b := false;
          ProgramState := psFinish;
        End;
    End;
    // Wir haben was zu tun bekommen, also abbrechen
    If High(ToDoList) <> -1 Then Begin
      b := false;
    End;
  End;
End;

// Mit dieser Procedure werden schritte wie X1 dann Xm1 gelöscht

Procedure Optimize(Var lt: Tltodo); // Fertig !!
Label
  nomal;
Var
  x, y: Integer;
  c: Boolean;
Begin
  nomal:
  c := false;
  x := 0;
  While x < high(lt) Do Begin
    // Alle hin her Drehungen werden entfernt !!
    If ((lt[x] = x1) And (lt[x + 1] = xm1)) Or ((lt[x] = x2) And (lt[x + 1] = xm2)) Or ((lt[x] = x3) And (lt[x + 1] = xm3)) Or
      ((lt[x] = xm1) And (lt[x + 1] = x1)) Or ((lt[x] = xm2) And (lt[x + 1] = x2)) Or ((lt[x] = xm3) And (lt[x + 1] = x3)) Or
      ((lt[x] = y1) And (lt[x + 1] = ym1)) Or ((lt[x] = y2) And (lt[x + 1] = ym2)) Or ((lt[x] = y3) And (lt[x + 1] = ym3)) Or
      ((lt[x] = ym1) And (lt[x + 1] = y1)) Or ((lt[x] = ym2) And (lt[x + 1] = y2)) Or ((lt[x] = ym3) And (lt[x + 1] = y3)) Or
      ((lt[x] = z1) And (lt[x + 1] = zm1)) Or ((lt[x] = z2) And (lt[x + 1] = zm2)) Or ((lt[x] = z3) And (lt[x + 1] = zm3)) Or
      ((lt[x] = zm1) And (lt[x + 1] = z1)) Or ((lt[x] = zm2) And (lt[x + 1] = z2)) Or ((lt[x] = zm3) And (lt[x + 1] = z3)) Then Begin
      For y := x + 2 To high(lt) Do
        lt[y - 2] := lt[Y];
      setlength(lt, high(lt) - 1);
      c := True;
    End;
    // Alles Dreifache muß noch raus und durch ein Einfaches in die andere Richtung ersetzt werden !!
    If x < high(lt) - 1 Then
      If (LT[x] = lt[x + 1]) And (lt[x] = Lt[x + 2]) Then Begin
        For y := x + 3 To high(lt) Do
          lt[y - 2] := lt[Y];
        setlength(lt, high(lt) - 1);
        Case lt[x] Of
          xm1: lt[x] := x1;
          xm2: lt[x] := x2;
          xm3: lt[x] := x3;
          zm1: lt[x] := z1;
          zm2: lt[x] := z2;
          zm3: lt[x] := z3;
          ym3: lt[x] := y3;
          ym2: lt[x] := y2;
          ym1: lt[x] := y1;
          x3: lt[x] := xm3;
          x2: lt[x] := xm2;
          x1: lt[x] := xm1;
          z3: lt[x] := zm3;
          z2: lt[x] := zm2;
          z1: lt[x] := zm1;
          y1: lt[x] := ym1;
          y2: lt[x] := ym2;
          y3: lt[x] := ym3;
        End;
        c := true;
      End;
    inc(x);
  End;
  If C Then Goto nomal;
End;

// Diese function wird benötigt um die Ecken zu finden !!

Function Sametribble(f1, f2, f3, s1, s2, s3: Integer): boolean;
Var
  b: 0..5;
Begin
  result := true;
  // Erst sortieren der Werte sonst ist ein vergleichen nahezu unmöglich !!
  If F2 > F3 Then Begin
    b := f2;
    f2 := f3;
    f3 := b;
  End;
  If F1 > F2 Then Begin
    b := f2;
    f2 := f1;
    f1 := b;
  End;
  If F2 > F3 Then Begin
    b := f2;
    f2 := f3;
    f3 := b;
  End;
  If s2 > s3 Then Begin
    b := s2;
    s2 := s3;
    s3 := b;
  End;
  If s1 > s2 Then Begin
    b := s2;
    s2 := s1;
    s1 := b;
  End;
  If s2 > s3 Then Begin
    b := s2;
    s2 := s3;
    s3 := b;
  End;
  // Erst sortieren der Werte sonst ist ein vergleichen nahezu unmöglich !!
  If (F1 <> s1) Or (F2 <> s2) Or (F3 <> s3) Then result := false;
End;

Function IndexToJob(Index: Integer): TJob;
Begin
  Result := xm1; // Index = 0
  Case Index Of
    1: result := xm2;
    2: result := xm3;
    3: result := zm1;
    4: result := zm2;
    5: result := zm3;
    6: result := ym3;
    7: result := ym2;
    8: result := ym1;
    9: result := x3;
    10: result := x2;
    11: result := x1;
    12: result := z3;
    13: result := z2;
    14: result := z1;
    15: result := y1;
    16: result := y2;
    17: result := y3;
  End;
End;

Procedure StartAutoAnim(Job: TJob);
Begin
  AnimCount := 0;
  AnimJob := job;
  ProgramState := psAnim;
End;

(*
Die Ergebnisse liegen im Interval [17 .. 105]
*)

Function CubePosToColor(x, y: integer): TColor;
Begin
  inc(x);
  inc(y);
  // Da x und y in [0 .. 8] kann man es mit shifts einfach zusammenfrickeln ;)
  result := (x Shl 4) Or y;
End;

Function ColorToCubePos(Const Color: TColor): Tpoint;
Begin
  result.x := (($F0 And Color) Shr 4) - 1;
  result.y := ($F And Color) - 1;
End;

Function ArrowIDToColor(ID: Integer): TColor;
Begin
  result := id + 150;
End;

Function ColorToArrowID(Const Color: TColor): Integer;
Begin
  result := (Color And $FF) - 150;
End;

Function ClearCube(): TCube;
Var
  x, y: integer;
Begin
  For x := 0 To 5 Do
    For y := 0 To 8 Do
      result[x, y] := x;
End;

Procedure DrawSubCube(Pos: TVector3; ColorX, ColorY, ColorZ: TColor; RenderIDs, Grid: Boolean);
Var
  x, y, z: Trgb;
  b: Boolean;
Begin
  x := ColorToRGB(colorx);
  y := ColorToRGB(colory);
  z := ColorToRGB(colorz);
  b := glIsEnabled(gl_lighting);
  glpushmatrix;
  glTranslatef(pos.x, pos.y, pos.z);
  // Der Deckel und Boden
  glcolor4ub(y.r, y.g, y.b, 255);
  If b Then Begin
    glColorMaterial(GL_FRONT, GL_DIFFUSE);
    glenable(GL_COLOR_MATERIAL);
  End;
  (*
  Eine Normale pro Quad = Flat Shading
  *)
  glbegin(GL_QUADS);
  glNormal3f(0, 1, 0);
  glvertex3f(-0.5, 0.5, 0.5);
  glvertex3f(0.5, 0.5, 0.5);
  glvertex3f(0.5, 0.5, -0.5);
  glvertex3f(-0.5, 0.5, -0.5);
  glNormal3f(0, -1, 0);
  glvertex3f(-0.5, -0.5, -0.5);
  glvertex3f(0.5, -0.5, -0.5);
  glvertex3f(0.5, -0.5, 0.5);
  glvertex3f(-0.5, -0.5, 0.5);
  glend;
  If b Then
    gldisable(GL_COLOR_MATERIAL);
  // Links und Rechts
  glcolor4ub(x.r, x.g, x.b, 255);
  If b Then Begin
    glColorMaterial(GL_FRONT, GL_DIFFUSE);
    glenable(GL_COLOR_MATERIAL);
  End;
  glbegin(GL_QUADS);
  glNormal3f(-1, 0, 0);
  glvertex3f(-0.5, -0.5, 0.5);
  glvertex3f(-0.5, 0.5, 0.5);
  glvertex3f(-0.5, 0.5, -0.5);
  glvertex3f(-0.5, -0.5, -0.5);
  glNormal3f(1, 0, 0);
  glvertex3f(0.5, -0.5, -0.5);
  glvertex3f(0.5, 0.5, -0.5);
  glvertex3f(0.5, 0.5, 0.5);
  glvertex3f(0.5, -0.5, 0.5);
  glend;
  If b Then
    gldisable(GL_COLOR_MATERIAL);
  // Vorne und Hinten
  glcolor4ub(z.r, z.g, z.b, 255);
  If b Then Begin
    glColorMaterial(GL_FRONT, GL_DIFFUSE);
    glenable(GL_COLOR_MATERIAL);
  End;
  glbegin(GL_QUADS);
  glNormal3f(0, 0, -1);
  glvertex3f(-0.5, 0.5, -0.5);
  glvertex3f(0.5, 0.5, -0.5);
  glvertex3f(0.5, -0.5, -0.5);
  glvertex3f(-0.5, -0.5, -0.5);
  glNormal3f(0, 0, 1);
  glvertex3f(-0.5, -0.5, 0.5);
  glvertex3f(0.5, -0.5, 0.5);
  glvertex3f(0.5, 0.5, 0.5);
  glvertex3f(-0.5, 0.5, 0.5);
  glend;
  If b Then Begin
    gldisable(GL_COLOR_MATERIAL);
    gldisable(gl_lighting); // Grid ohne Licht
  End;
  // Das Grid
  // Grid immer ohne Licht !!
  If Grid And Not RenderIDs Then Begin
    z := ColorToRGB(GridCol);
    glColor4ub(z.r, z.g, z.b, 255);
    glLineWidth(5);
    glbegin(gl_line_loop);
    glvertex3f(-0.5, 0.5, -0.5);
    glvertex3f(0.5, 0.5, -0.5);
    glvertex3f(0.5, 0.5, 0.5);
    glvertex3f(-0.5, 0.5, 0.5);
    glend;
    glbegin(gl_line_loop);
    glvertex3f(-0.5, -0.5, -0.5);
    glvertex3f(0.5, -0.5, -0.5);
    glvertex3f(0.5, -0.5, 0.5);
    glvertex3f(-0.5, -0.5, 0.5);
    glend;
    glbegin(gl_lines);
    glvertex3f(-0.5, 0.5, -0.5);
    glvertex3f(-0.5, -0.5, -0.5);
    glvertex3f(0.5, 0.5, -0.5);
    glvertex3f(0.5, -0.5, -0.5);
    glvertex3f(0.5, 0.5, 0.5);
    glvertex3f(0.5, -0.5, 0.5);
    glvertex3f(-0.5, 0.5, 0.5);
    glvertex3f(-0.5, -0.5, 0.5);
    glend;
    glLineWidth(1);
  End;
  glcolor4f(1, 1, 1, 1);
  glPopMatrix;
  // Licht wieder an, wenn es vorher an war
  If b Then Begin
    glenable(gl_lighting);
  End;
End;

// Waagrecht liegende Pfeile Richtung Positive Z-Achse

Procedure RenderZArrow(Pos: Tvector3; ID: Integer; RenderIDs: Boolean);
Var
  c: TColor;
  z: TRGB;
Begin
  glpushmatrix;
  glTranslatef(pos.x, pos.y, pos.z);
  // Die Farbe Bestimmen
  If RenderIDs Then Begin
    c := ArrowIDToColor(id);
  End
  Else Begin
    c := $404040;
  End;
  z := ColorToRGB(c);
  glcolor4ub(z.r, z.g, z.b, 255);
  // Der Eigentliche Pfeil
  glBegin(GL_TRIANGLE_FAN);
  glnormal3f(0, 1, 0);
  glvertex3f(0, 0, 0);
  glvertex3f(-0.25, 0, 0.5);
  glvertex3f(-0.25, 0, 0);
  glvertex3f(-0.5, 0, 0);
  glvertex3f(0, 0, -0.5);
  glvertex3f(0.5, 0, 0);
  glvertex3f(0.25, 0, 0);
  glvertex3f(0.25, 0, 0.5);
  glvertex3f(-0.25, 0, 0.5);
  glend;
  glcolor4f(1, 1, 1, 1);
  If Not RenderIDs Then Begin
    c := $C0C0C0;
    z := ColorToRGB(c);
    glcolor4ub(z.r, z.g, z.b, 255);
    glLineWidth(3);
    glBegin(GL_Line_Loop);
    glvertex3f(-0.25, 0, 0.5);
    glvertex3f(-0.25, 0, 0);
    glvertex3f(-0.5, 0, 0);
    glvertex3f(0, 0, -0.5);
    glvertex3f(0.5, 0, 0);
    glvertex3f(0.25, 0, 0);
    glvertex3f(0.25, 0, 0.5);
    glvertex3f(-0.25, 0, 0.5);
    glend;
    glLineWidth(1);
  End;
  glPopMatrix;
End;

// Waagrecht Liegende Pfeile Richtung Positive X-Achse

Procedure RenderXArrow(Pos: Tvector3; ID: Integer; RenderIDs: Boolean);
Var
  c: TColor;
  z: TRGB;
Begin
  glpushmatrix;
  glTranslatef(pos.x, pos.y, pos.z);
  // Die Farbe Bestimmen
  If RenderIDs Then Begin
    c := ArrowIDToColor(id);
  End
  Else Begin
    c := $404040;
  End;
  z := ColorToRGB(c);
  glcolor4ub(z.r, z.g, z.b, 255);
  // Der Eigentliche Pfeil
  glBegin(GL_TRIANGLE_FAN);
  glnormal3f(0, 1, 0);
  glvertex3f(0, 0, 0);
  glvertex3f(0, 0, 0.25);
  glvertex3f(0, 0, 0.5);
  glvertex3f(0.5, 0, 0);
  glvertex3f(0, 0, -0.5);
  glvertex3f(0, 0, -0.25);
  glvertex3f(-0.5, 0, -0.25);
  glvertex3f(-0.5, 0, 0.25);
  glvertex3f(0, 0, 0.25);
  glend;
  glcolor4f(1, 1, 1, 1);
  If Not RenderIDs Then Begin
    c := $C0C0C0;
    z := ColorToRGB(c);
    glcolor4ub(z.r, z.g, z.b, 255);
    glLineWidth(3);
    glBegin(GL_Line_Loop);
    glvertex3f(0, 0, 0.25);
    glvertex3f(0, 0, 0.5);
    glvertex3f(0.5, 0, 0);
    glvertex3f(0, 0, -0.5);
    glvertex3f(0, 0, -0.25);
    glvertex3f(-0.5, 0, -0.25);
    glvertex3f(-0.5, 0, 0.25);
    glvertex3f(0, 0, 0.25);
    glend;
    glLineWidth(1);
  End;
  glPopMatrix;
End;

// Senkrecht Stehende Pfeile Richtung Positive X-Achse

Procedure RenderYArrow(Pos: Tvector3; ID: Integer; RenderIDs: Boolean);
Var
  c: TColor;
  z: TRGB;
Begin
  glpushmatrix;
  glTranslatef(pos.x, pos.y, pos.z);
  // Die Farbe Bestimmen
  If RenderIDs Then Begin
    c := ArrowIDToColor(id);
  End
  Else Begin
    c := $404040;
  End;
  z := ColorToRGB(c);
  glcolor4ub(z.r, z.g, z.b, 255);
  // Der Eigentliche Pfeil
  glBegin(GL_TRIANGLE_FAN);
  glnormal3f(0, 1, 0);
  glvertex3f(0, 0, 0);
  glvertex3f(0, 0.25, 0);
  glvertex3f(0, 0.5, 0);
  glvertex3f(0.5, 0, 0);
  glvertex3f(0, -0.5, 0);
  glvertex3f(0, -0.25, 0);
  glvertex3f(-0.5, -0.25, 0);
  glvertex3f(-0.5, 0.25, 0);
  glvertex3f(0, 0.25, 0);
  glend;
  glcolor4f(1, 1, 1, 1);
  If Not RenderIDs Then Begin
    c := $C0C0C0;
    z := ColorToRGB(c);
    glcolor4ub(z.r, z.g, z.b, 255);
    glLineWidth(3);
    glBegin(GL_Line_Loop);
    glvertex3f(0, 0.25, 0);
    glvertex3f(0, 0.5, 0);
    glvertex3f(0.5, 0, 0);
    glvertex3f(0, -0.5, 0);
    glvertex3f(0, -0.25, 0);
    glvertex3f(-0.5, -0.25, 0);
    glvertex3f(-0.5, 0.25, 0);
    glvertex3f(0, 0.25, 0);
    glend;
    glLineWidth(1);
  End;
  glPopMatrix;
End;

Procedure DrawCube(Const Cube: TCube; RenderArrows, RenderIDs, Grid: Boolean);
Var
  b: Boolean;
Begin
  If RenderIDs Then Begin
    // Rendern des Cubes anhand der Spezifikation auf dem Bild
    // clnone für nicht benötigte Seiten
    // die Array Pos wird in Farbe Codiert
    // 1. Ebene
    DrawSubCube(v3(-1, 1, -1), CubePosToColor(4, 2), CubePosToColor(0, 0), CubePosToColor(3, 0), RenderIDs, grid);
    DrawSubCube(v3(-1, 1, 0), CubePosToColor(4, 1), CubePosToColor(0, 3), clnone, RenderIDs, grid);
    DrawSubCube(v3(-1, 1, 1), CubePosToColor(4, 0), CubePosToColor(0, 6), CubePosToColor(1, 0), RenderIDs, grid);
    DrawSubCube(v3(0, 1, -1), clnone, CubePosToColor(0, 1), CubePosToColor(3, 1), RenderIDs, grid);
    DrawSubCube(v3(0, 1, 0), clnone, CubePosToColor(0, 4), clnone, RenderIDs, grid);
    DrawSubCube(v3(0, 1, 1), clnone, CubePosToColor(0, 7), CubePosToColor(1, 1), RenderIDs, grid);
    DrawSubCube(v3(1, 1, -1), CubePosToColor(2, 2), CubePosToColor(0, 2), CubePosToColor(3, 2), RenderIDs, grid);
    DrawSubCube(v3(1, 1, 0), CubePosToColor(2, 1), CubePosToColor(0, 5), clnone, RenderIDs, grid);
    DrawSubCube(v3(1, 1, 1), CubePosToColor(2, 0), CubePosToColor(0, 8), CubePosToColor(1, 2), RenderIDs, grid);
    // 2. Ebene
    DrawSubCube(v3(-1, 0, -1), CubePosToColor(4, 5), clnone, CubePosToColor(3, 3), RenderIDs, grid);
    DrawSubCube(v3(-1, 0, 0), CubePosToColor(4, 4), clnone, clnone, RenderIDs, grid);
    DrawSubCube(v3(-1, 0, 1), CubePosToColor(4, 3), clnone, CubePosToColor(1, 3), RenderIDs, grid);
    DrawSubCube(v3(0, 0, -1), clnone, clnone, CubePosToColor(3, 4), RenderIDs, grid);
    //  DrawSubCube(v3(0, 0, 0), clnone, clnone, clnone); // Diesen Unterwürfel gibt es nicht ;)
    DrawSubCube(v3(0, 0, 1), clnone, clnone, CubePosToColor(1, 4), RenderIDs, grid);
    DrawSubCube(v3(1, 0, -1), CubePosToColor(2, 5), clnone, CubePosToColor(3, 5), RenderIDs, grid);
    DrawSubCube(v3(1, 0, 0), CubePosToColor(2, 4), clnone, clnone, RenderIDs, grid);
    DrawSubCube(v3(1, 0, 1), CubePosToColor(2, 3), clnone, CubePosToColor(1, 5), RenderIDs, grid);
    // 3. Ebene
    DrawSubCube(v3(-1, -1, -1), CubePosToColor(4, 8), CubePosToColor(5, 0), CubePosToColor(3, 6), RenderIDs, grid);
    DrawSubCube(v3(-1, -1, 0), CubePosToColor(4, 7), CubePosToColor(5, 3), clnone, RenderIDs, grid);
    DrawSubCube(v3(-1, -1, 1), CubePosToColor(4, 6), CubePosToColor(5, 6), CubePosToColor(1, 6), RenderIDs, grid);
    DrawSubCube(v3(0, -1, -1), clnone, CubePosToColor(5, 1), CubePosToColor(3, 7), RenderIDs, grid);
    DrawSubCube(v3(0, -1, 0), clnone, CubePosToColor(5, 4), clnone, RenderIDs, grid);
    DrawSubCube(v3(0, -1, 1), clnone, CubePosToColor(5, 7), CubePosToColor(1, 7), RenderIDs, grid);
    DrawSubCube(v3(1, -1, -1), CubePosToColor(2, 8), CubePosToColor(5, 2), CubePosToColor(3, 8), RenderIDs, grid);
    DrawSubCube(v3(1, -1, 0), CubePosToColor(2, 7), CubePosToColor(5, 5), clnone, RenderIDs, grid);
    DrawSubCube(v3(1, -1, 1), CubePosToColor(2, 6), CubePosToColor(5, 8), CubePosToColor(1, 8), RenderIDs, grid);
  End
  Else Begin
    // Rendern des Cubes anhand der Spezifikation auf dem Bild
    // clnone für nicht benötigte Seiten
    // 1. Ebene
    DrawSubCube(v3(-1, 1, -1), CubeColors[cube[4, 2]], CubeColors[cube[0, 0]], CubeColors[cube[3, 0]], RenderIDs, grid);
    DrawSubCube(v3(-1, 1, 0), CubeColors[cube[4, 1]], CubeColors[cube[0, 3]], clnone, RenderIDs, grid);
    DrawSubCube(v3(-1, 1, 1), CubeColors[cube[4, 0]], CubeColors[cube[0, 6]], CubeColors[cube[1, 0]], RenderIDs, grid);
    DrawSubCube(v3(0, 1, -1), clnone, CubeColors[cube[0, 1]], CubeColors[cube[3, 1]], RenderIDs, grid);
    DrawSubCube(v3(0, 1, 0), clnone, CubeColors[cube[0, 4]], clnone, RenderIDs, grid);
    DrawSubCube(v3(0, 1, 1), clnone, CubeColors[cube[0, 7]], CubeColors[cube[1, 1]], RenderIDs, grid);
    DrawSubCube(v3(1, 1, -1), CubeColors[cube[2, 2]], CubeColors[cube[0, 2]], CubeColors[cube[3, 2]], RenderIDs, grid);
    DrawSubCube(v3(1, 1, 0), CubeColors[cube[2, 1]], CubeColors[cube[0, 5]], clnone, RenderIDs, grid);
    DrawSubCube(v3(1, 1, 1), CubeColors[cube[2, 0]], CubeColors[cube[0, 8]], CubeColors[cube[1, 2]], RenderIDs, grid);
    // 2. Ebene
    DrawSubCube(v3(-1, 0, -1), CubeColors[cube[4, 5]], clnone, CubeColors[cube[3, 3]], RenderIDs, grid);
    DrawSubCube(v3(-1, 0, 0), CubeColors[cube[4, 4]], clnone, clnone, RenderIDs, grid);
    DrawSubCube(v3(-1, 0, 1), CubeColors[cube[4, 3]], clnone, CubeColors[cube[1, 3]], RenderIDs, grid);
    DrawSubCube(v3(0, 0, -1), clnone, clnone, CubeColors[cube[3, 4]], RenderIDs, grid);
    //  DrawSubCube(v3(0, 0, 0), clnone, clnone, clnone, RenderIDs, grid);  // Diesen Unterwürfel gibt es nicht ;)
    DrawSubCube(v3(0, 0, 1), clnone, clnone, CubeColors[cube[1, 4]], RenderIDs, grid);
    DrawSubCube(v3(1, 0, -1), CubeColors[cube[2, 5]], clnone, CubeColors[cube[3, 5]], RenderIDs, grid);
    DrawSubCube(v3(1, 0, 0), CubeColors[cube[2, 4]], clnone, clnone, RenderIDs, grid);
    DrawSubCube(v3(1, 0, 1), CubeColors[cube[2, 3]], clnone, CubeColors[cube[1, 5]], RenderIDs, grid);
    // 3. Ebene
    DrawSubCube(v3(-1, -1, -1), CubeColors[cube[4, 8]], CubeColors[cube[5, 0]], CubeColors[cube[3, 6]], RenderIDs, grid);
    DrawSubCube(v3(-1, -1, 0), CubeColors[cube[4, 7]], CubeColors[cube[5, 3]], clnone, RenderIDs, grid);
    DrawSubCube(v3(-1, -1, 1), CubeColors[cube[4, 6]], CubeColors[cube[5, 6]], CubeColors[cube[1, 6]], RenderIDs, grid);
    DrawSubCube(v3(0, -1, -1), clnone, CubeColors[cube[5, 1]], CubeColors[cube[3, 7]], RenderIDs, grid);
    DrawSubCube(v3(0, -1, 0), clnone, CubeColors[cube[5, 4]], clnone, RenderIDs, grid);
    DrawSubCube(v3(0, -1, 1), clnone, CubeColors[cube[5, 7]], CubeColors[cube[1, 7]], RenderIDs, grid);
    DrawSubCube(v3(1, -1, -1), CubeColors[cube[2, 8]], CubeColors[cube[5, 2]], CubeColors[cube[3, 8]], RenderIDs, grid);
    DrawSubCube(v3(1, -1, 0), CubeColors[cube[2, 7]], CubeColors[cube[5, 5]], clnone, RenderIDs, grid);
    DrawSubCube(v3(1, -1, 1), CubeColors[cube[2, 6]], CubeColors[cube[5, 8]], CubeColors[cube[1, 8]], RenderIDs, grid);
  End;
  // Anzeigen der 18 Pfeile
  If RenderArrows Then Begin
    // Pfeile immer ohne Licht !!
    b := glIsEnabled(gl_lighting);
    If b Then
      glDisable(GL_LIGHTING);
    glDisable(GL_CULL_FACE);
    RenderZarrow(v3(-1, 1.5, -2), 0, RenderIDs);
    RenderZarrow(v3(0, 1.5, -2), 1, RenderIDs);
    RenderZarrow(v3(1, 1.5, -2), 2, RenderIDs);
    RenderZarrow(v3(-1, -1.5, 2), 11, RenderIDs);
    RenderZarrow(v3(0, -1.5, 2), 10, RenderIDs);
    RenderZarrow(v3(1, -1.5, 2), 9, RenderIDs);
    RenderXArrow(v3(-2, 1.5, -1), 17, RenderIDs);
    RenderXArrow(v3(-2, 1.5, 0), 16, RenderIDs);
    RenderXArrow(v3(-2, 1.5, 1), 15, RenderIDs);
    RenderXArrow(v3(2, -1.5, -1), 6, RenderIDs);
    RenderXArrow(v3(2, -1.5, 0), 7, RenderIDs);
    RenderXArrow(v3(2, -1.5, 1), 8, RenderIDs);
    RenderYArrow(v3(2, 1, -1.5), 3, RenderIDs);
    RenderYArrow(v3(2, 0, -1.5), 4, RenderIDs);
    RenderYArrow(v3(2, -1, -1.5), 5, RenderIDs);
    RenderYArrow(v3(-2, 1, 1.5), 14, RenderIDs);
    RenderYArrow(v3(-2, 0, 1.5), 13, RenderIDs);
    RenderYArrow(v3(-2, -1, 1.5), 12, RenderIDs);
    glenable(GL_CULL_FACE);
    If b Then
      glenable(GL_LIGHTING);
  End;
End;

Procedure DrawJobAnim(Const Cube: TCube; Job: TJob; Count: Single; Grid, RenderArrows: Boolean);
Const
  RenderIDs = false;
Var
  progress: Single;
  b: Boolean;
Begin
  count := min(100, max(count, 0));
  // Umdrehen der Achsenrichtung
  Case Job Of
    xm1, xm2, xm3,
      Y1, Y2, Y3,
      Zm1, Zm2, Zm3: Begin
        count := -count;
      End;
  End;
  // Anzeigen der 18 Pfeile
  If RenderArrows Then Begin
    // Pfeile immer ohne Licht !!
    b := glIsEnabled(gl_lighting);
    If b Then
      glDisable(GL_LIGHTING);
    glDisable(GL_CULL_FACE);
    Case job Of
      xm1: RenderZarrow(v3(-1, 1.5, -2), 0, RenderIDs);
      xm2: RenderZarrow(v3(0, 1.5, -2), 1, RenderIDs);
      xm3: RenderZarrow(v3(1, 1.5, -2), 2, RenderIDs);
      x1: RenderZarrow(v3(-1, -1.5, 2), 11, RenderIDs);
      x2: RenderZarrow(v3(0, -1.5, 2), 10, RenderIDs);
      x3: RenderZarrow(v3(1, -1.5, 2), 9, RenderIDs);
      y3: RenderXArrow(v3(-2, 1.5, -1), 17, RenderIDs);
      y2: RenderXArrow(v3(-2, 1.5, 0), 16, RenderIDs);
      y1: RenderXArrow(v3(-2, 1.5, 1), 15, RenderIDs);
      ym3: RenderXArrow(v3(2, -1.5, -1), 6, RenderIDs);
      ym2: RenderXArrow(v3(2, -1.5, 0), 7, RenderIDs);
      ym1: RenderXArrow(v3(2, -1.5, 1), 8, RenderIDs);
      zm1: RenderYArrow(v3(2, 1, -1.5), 3, RenderIDs);
      zm2: RenderYArrow(v3(2, 0, -1.5), 4, RenderIDs);
      zm3: RenderYArrow(v3(2, -1, -1.5), 5, RenderIDs);
      z1: RenderYArrow(v3(-2, 1, 1.5), 14, RenderIDs);
      z2: RenderYArrow(v3(-2, 0, 1.5), 13, RenderIDs);
      z3: RenderYArrow(v3(-2, -1, 1.5), 12, RenderIDs);
    End;
    glenable(GL_CULL_FACE);
    If b Then
      glenable(GL_LIGHTING);
  End;
  // Skallieren auf Gradmaß
  progress := (90 * count) / 100;
  Case Job Of
    x1, xm1: Begin
        // 1. Ebene
        DrawSubCube(v3(0, 1, -1), clnone, CubeColors[cube[0, 1]], CubeColors[cube[3, 1]], RenderIDs, grid);
        DrawSubCube(v3(0, 1, 0), clnone, CubeColors[cube[0, 4]], clnone, RenderIDs, grid);
        DrawSubCube(v3(0, 1, 1), clnone, CubeColors[cube[0, 7]], CubeColors[cube[1, 1]], RenderIDs, grid);
        DrawSubCube(v3(1, 1, -1), CubeColors[cube[2, 2]], CubeColors[cube[0, 2]], CubeColors[cube[3, 2]], RenderIDs, grid);
        DrawSubCube(v3(1, 1, 0), CubeColors[cube[2, 1]], CubeColors[cube[0, 5]], clnone, RenderIDs, grid);
        DrawSubCube(v3(1, 1, 1), CubeColors[cube[2, 0]], CubeColors[cube[0, 8]], CubeColors[cube[1, 2]], RenderIDs, grid);
        // 2. Ebene
        DrawSubCube(v3(0, 0, -1), clnone, clnone, CubeColors[cube[3, 4]], RenderIDs, grid);
        //  DrawSubCube(v3(0, 0, 0), clnone, clnone, clnone, RenderIDs, grid);  // Diesen Unterwürfel gibt es nicht ;)
        DrawSubCube(v3(0, 0, 1), clnone, clnone, CubeColors[cube[1, 4]], RenderIDs, grid);
        DrawSubCube(v3(1, 0, -1), CubeColors[cube[2, 5]], clnone, CubeColors[cube[3, 5]], RenderIDs, grid);
        DrawSubCube(v3(1, 0, 0), CubeColors[cube[2, 4]], clnone, clnone, RenderIDs, grid);
        DrawSubCube(v3(1, 0, 1), CubeColors[cube[2, 3]], clnone, CubeColors[cube[1, 5]], RenderIDs, grid);
        // 3. Ebene
        DrawSubCube(v3(0, -1, -1), clnone, CubeColors[cube[5, 1]], CubeColors[cube[3, 7]], RenderIDs, grid);
        DrawSubCube(v3(0, -1, 0), clnone, CubeColors[cube[5, 4]], clnone, RenderIDs, grid);
        DrawSubCube(v3(0, -1, 1), clnone, CubeColors[cube[5, 7]], CubeColors[cube[1, 7]], RenderIDs, grid);
        DrawSubCube(v3(1, -1, -1), CubeColors[cube[2, 8]], CubeColors[cube[5, 2]], CubeColors[cube[3, 8]], RenderIDs, grid);
        DrawSubCube(v3(1, -1, 0), CubeColors[cube[2, 7]], CubeColors[cube[5, 5]], clnone, RenderIDs, grid);
        DrawSubCube(v3(1, -1, 1), CubeColors[cube[2, 6]], CubeColors[cube[5, 8]], CubeColors[cube[1, 8]], RenderIDs, grid);
        // Die zu rotierende Ebene
        glpushmatrix;
        glRotatef(progress, 1, 0, 0);
        DrawSubCube(v3(-1, 1, -1), CubeColors[cube[4, 2]], CubeColors[cube[0, 0]], CubeColors[cube[3, 0]], RenderIDs, grid);
        DrawSubCube(v3(-1, 1, 0), CubeColors[cube[4, 1]], CubeColors[cube[0, 3]], clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, 1, 1), CubeColors[cube[4, 0]], CubeColors[cube[0, 6]], CubeColors[cube[1, 0]], RenderIDs, grid);
        DrawSubCube(v3(-1, 0, -1), CubeColors[cube[4, 5]], clnone, CubeColors[cube[3, 3]], RenderIDs, grid);
        DrawSubCube(v3(-1, 0, 0), CubeColors[cube[4, 4]], clnone, clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, 0, 1), CubeColors[cube[4, 3]], clnone, CubeColors[cube[1, 3]], RenderIDs, grid);
        DrawSubCube(v3(-1, -1, -1), CubeColors[cube[4, 8]], CubeColors[cube[5, 0]], CubeColors[cube[3, 6]], RenderIDs, grid);
        DrawSubCube(v3(-1, -1, 0), CubeColors[cube[4, 7]], CubeColors[cube[5, 3]], clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, -1, 1), CubeColors[cube[4, 6]], CubeColors[cube[5, 6]], CubeColors[cube[1, 6]], RenderIDs, grid);
        glpopmatrix;
      End;
    x2, xm2: Begin
        // 1. Ebene
        DrawSubCube(v3(-1, 1, -1), CubeColors[cube[4, 2]], CubeColors[cube[0, 0]], CubeColors[cube[3, 0]], RenderIDs, grid);
        DrawSubCube(v3(-1, 1, 0), CubeColors[cube[4, 1]], CubeColors[cube[0, 3]], clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, 1, 1), CubeColors[cube[4, 0]], CubeColors[cube[0, 6]], CubeColors[cube[1, 0]], RenderIDs, grid);
        DrawSubCube(v3(1, 1, -1), CubeColors[cube[2, 2]], CubeColors[cube[0, 2]], CubeColors[cube[3, 2]], RenderIDs, grid);
        DrawSubCube(v3(1, 1, 0), CubeColors[cube[2, 1]], CubeColors[cube[0, 5]], clnone, RenderIDs, grid);
        DrawSubCube(v3(1, 1, 1), CubeColors[cube[2, 0]], CubeColors[cube[0, 8]], CubeColors[cube[1, 2]], RenderIDs, grid);
        // 2. Ebene
        DrawSubCube(v3(-1, 0, -1), CubeColors[cube[4, 5]], clnone, CubeColors[cube[3, 3]], RenderIDs, grid);
        DrawSubCube(v3(-1, 0, 0), CubeColors[cube[4, 4]], clnone, clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, 0, 1), CubeColors[cube[4, 3]], clnone, CubeColors[cube[1, 3]], RenderIDs, grid);
        DrawSubCube(v3(1, 0, -1), CubeColors[cube[2, 5]], clnone, CubeColors[cube[3, 5]], RenderIDs, grid);
        DrawSubCube(v3(1, 0, 0), CubeColors[cube[2, 4]], clnone, clnone, RenderIDs, grid);
        DrawSubCube(v3(1, 0, 1), CubeColors[cube[2, 3]], clnone, CubeColors[cube[1, 5]], RenderIDs, grid);
        // 3. Ebene
        DrawSubCube(v3(-1, -1, -1), CubeColors[cube[4, 8]], CubeColors[cube[5, 0]], CubeColors[cube[3, 6]], RenderIDs, grid);
        DrawSubCube(v3(-1, -1, 0), CubeColors[cube[4, 7]], CubeColors[cube[5, 3]], clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, -1, 1), CubeColors[cube[4, 6]], CubeColors[cube[5, 6]], CubeColors[cube[1, 6]], RenderIDs, grid);
        DrawSubCube(v3(1, -1, -1), CubeColors[cube[2, 8]], CubeColors[cube[5, 2]], CubeColors[cube[3, 8]], RenderIDs, grid);
        DrawSubCube(v3(1, -1, 0), CubeColors[cube[2, 7]], CubeColors[cube[5, 5]], clnone, RenderIDs, grid);
        DrawSubCube(v3(1, -1, 1), CubeColors[cube[2, 6]], CubeColors[cube[5, 8]], CubeColors[cube[1, 8]], RenderIDs, grid);
        // Die zu rotierende Ebene
        glpushmatrix;
        glRotatef(progress, 1, 0, 0);
        DrawSubCube(v3(0, 1, -1), clnone, CubeColors[cube[0, 1]], CubeColors[cube[3, 1]], RenderIDs, grid);
        DrawSubCube(v3(0, 1, 0), clnone, CubeColors[cube[0, 4]], clnone, RenderIDs, grid);
        DrawSubCube(v3(0, 1, 1), clnone, CubeColors[cube[0, 7]], CubeColors[cube[1, 1]], RenderIDs, grid);
        DrawSubCube(v3(0, 0, -1), clnone, clnone, CubeColors[cube[3, 4]], RenderIDs, grid);
        //  DrawSubCube(v3(0, 0, 0), clnone, clnone, clnone, RenderIDs, grid);  // Diesen Unterwürfel gibt es nicht ;)
        DrawSubCube(v3(0, 0, 1), clnone, clnone, CubeColors[cube[1, 4]], RenderIDs, grid);
        DrawSubCube(v3(0, -1, -1), clnone, CubeColors[cube[5, 1]], CubeColors[cube[3, 7]], RenderIDs, grid);
        DrawSubCube(v3(0, -1, 0), clnone, CubeColors[cube[5, 4]], clnone, RenderIDs, grid);
        DrawSubCube(v3(0, -1, 1), clnone, CubeColors[cube[5, 7]], CubeColors[cube[1, 7]], RenderIDs, grid);
        glpopmatrix;
      End;
    x3, xm3: Begin
        // 1. Ebene
        DrawSubCube(v3(-1, 1, -1), CubeColors[cube[4, 2]], CubeColors[cube[0, 0]], CubeColors[cube[3, 0]], RenderIDs, grid);
        DrawSubCube(v3(-1, 1, 0), CubeColors[cube[4, 1]], CubeColors[cube[0, 3]], clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, 1, 1), CubeColors[cube[4, 0]], CubeColors[cube[0, 6]], CubeColors[cube[1, 0]], RenderIDs, grid);
        DrawSubCube(v3(0, 1, -1), clnone, CubeColors[cube[0, 1]], CubeColors[cube[3, 1]], RenderIDs, grid);
        DrawSubCube(v3(0, 1, 0), clnone, CubeColors[cube[0, 4]], clnone, RenderIDs, grid);
        DrawSubCube(v3(0, 1, 1), clnone, CubeColors[cube[0, 7]], CubeColors[cube[1, 1]], RenderIDs, grid);
        // 2. Ebene
        DrawSubCube(v3(-1, 0, -1), CubeColors[cube[4, 5]], clnone, CubeColors[cube[3, 3]], RenderIDs, grid);
        DrawSubCube(v3(-1, 0, 0), CubeColors[cube[4, 4]], clnone, clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, 0, 1), CubeColors[cube[4, 3]], clnone, CubeColors[cube[1, 3]], RenderIDs, grid);
        DrawSubCube(v3(0, 0, -1), clnone, clnone, CubeColors[cube[3, 4]], RenderIDs, grid);
        //  DrawSubCube(v3(0, 0, 0), clnone, clnone, clnone, RenderIDs, grid);  // Diesen Unterwürfel gibt es nicht ;)
        DrawSubCube(v3(0, 0, 1), clnone, clnone, CubeColors[cube[1, 4]], RenderIDs, grid);
        // 3. Ebene
        DrawSubCube(v3(-1, -1, -1), CubeColors[cube[4, 8]], CubeColors[cube[5, 0]], CubeColors[cube[3, 6]], RenderIDs, grid);
        DrawSubCube(v3(-1, -1, 0), CubeColors[cube[4, 7]], CubeColors[cube[5, 3]], clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, -1, 1), CubeColors[cube[4, 6]], CubeColors[cube[5, 6]], CubeColors[cube[1, 6]], RenderIDs, grid);
        DrawSubCube(v3(0, -1, -1), clnone, CubeColors[cube[5, 1]], CubeColors[cube[3, 7]], RenderIDs, grid);
        DrawSubCube(v3(0, -1, 0), clnone, CubeColors[cube[5, 4]], clnone, RenderIDs, grid);
        DrawSubCube(v3(0, -1, 1), clnone, CubeColors[cube[5, 7]], CubeColors[cube[1, 7]], RenderIDs, grid);
        // Die zu rotierende Ebene
        glpushmatrix;
        glRotatef(progress, 1, 0, 0);
        DrawSubCube(v3(1, 1, -1), CubeColors[cube[2, 2]], CubeColors[cube[0, 2]], CubeColors[cube[3, 2]], RenderIDs, grid);
        DrawSubCube(v3(1, 1, 0), CubeColors[cube[2, 1]], CubeColors[cube[0, 5]], clnone, RenderIDs, grid);
        DrawSubCube(v3(1, 1, 1), CubeColors[cube[2, 0]], CubeColors[cube[0, 8]], CubeColors[cube[1, 2]], RenderIDs, grid);
        DrawSubCube(v3(1, 0, -1), CubeColors[cube[2, 5]], clnone, CubeColors[cube[3, 5]], RenderIDs, grid);
        DrawSubCube(v3(1, 0, 0), CubeColors[cube[2, 4]], clnone, clnone, RenderIDs, grid);
        DrawSubCube(v3(1, 0, 1), CubeColors[cube[2, 3]], clnone, CubeColors[cube[1, 5]], RenderIDs, grid);
        DrawSubCube(v3(1, -1, -1), CubeColors[cube[2, 8]], CubeColors[cube[5, 2]], CubeColors[cube[3, 8]], RenderIDs, grid);
        DrawSubCube(v3(1, -1, 0), CubeColors[cube[2, 7]], CubeColors[cube[5, 5]], clnone, RenderIDs, grid);
        DrawSubCube(v3(1, -1, 1), CubeColors[cube[2, 6]], CubeColors[cube[5, 8]], CubeColors[cube[1, 8]], RenderIDs, grid);
        glpopmatrix;
      End;
    Y3, Ym3: Begin
        // 1. Ebene
        DrawSubCube(v3(-1, 1, 0), CubeColors[cube[4, 1]], CubeColors[cube[0, 3]], clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, 1, 1), CubeColors[cube[4, 0]], CubeColors[cube[0, 6]], CubeColors[cube[1, 0]], RenderIDs, grid);
        DrawSubCube(v3(0, 1, 0), clnone, CubeColors[cube[0, 4]], clnone, RenderIDs, grid);
        DrawSubCube(v3(0, 1, 1), clnone, CubeColors[cube[0, 7]], CubeColors[cube[1, 1]], RenderIDs, grid);
        DrawSubCube(v3(1, 1, 0), CubeColors[cube[2, 1]], CubeColors[cube[0, 5]], clnone, RenderIDs, grid);
        DrawSubCube(v3(1, 1, 1), CubeColors[cube[2, 0]], CubeColors[cube[0, 8]], CubeColors[cube[1, 2]], RenderIDs, grid);
        // 2. Ebene
        DrawSubCube(v3(-1, 0, 0), CubeColors[cube[4, 4]], clnone, clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, 0, 1), CubeColors[cube[4, 3]], clnone, CubeColors[cube[1, 3]], RenderIDs, grid);
        //  DrawSubCube(v3(0, 0, 0), clnone, clnone, clnone, RenderIDs, grid);  // Diesen Unterwürfel gibt es nicht ;)
        DrawSubCube(v3(0, 0, 1), clnone, clnone, CubeColors[cube[1, 4]], RenderIDs, grid);
        DrawSubCube(v3(1, 0, 0), CubeColors[cube[2, 4]], clnone, clnone, RenderIDs, grid);
        DrawSubCube(v3(1, 0, 1), CubeColors[cube[2, 3]], clnone, CubeColors[cube[1, 5]], RenderIDs, grid);
        // 3. Ebene
        DrawSubCube(v3(-1, -1, 0), CubeColors[cube[4, 7]], CubeColors[cube[5, 3]], clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, -1, 1), CubeColors[cube[4, 6]], CubeColors[cube[5, 6]], CubeColors[cube[1, 6]], RenderIDs, grid);
        DrawSubCube(v3(0, -1, 0), clnone, CubeColors[cube[5, 4]], clnone, RenderIDs, grid);
        DrawSubCube(v3(0, -1, 1), clnone, CubeColors[cube[5, 7]], CubeColors[cube[1, 7]], RenderIDs, grid);
        DrawSubCube(v3(1, -1, 0), CubeColors[cube[2, 7]], CubeColors[cube[5, 5]], clnone, RenderIDs, grid);
        DrawSubCube(v3(1, -1, 1), CubeColors[cube[2, 6]], CubeColors[cube[5, 8]], CubeColors[cube[1, 8]], RenderIDs, grid);
        // Die zu rotierende Ebene
        glpushmatrix;
        glRotatef(progress, 0, 0, 1);
        DrawSubCube(v3(0, 1, -1), clnone, CubeColors[cube[0, 1]], CubeColors[cube[3, 1]], RenderIDs, grid);
        DrawSubCube(v3(1, 1, -1), CubeColors[cube[2, 2]], CubeColors[cube[0, 2]], CubeColors[cube[3, 2]], RenderIDs, grid);
        DrawSubCube(v3(-1, 1, -1), CubeColors[cube[4, 2]], CubeColors[cube[0, 0]], CubeColors[cube[3, 0]], RenderIDs, grid);
        DrawSubCube(v3(-1, 0, -1), CubeColors[cube[4, 5]], clnone, CubeColors[cube[3, 3]], RenderIDs, grid);
        DrawSubCube(v3(1, 0, -1), CubeColors[cube[2, 5]], clnone, CubeColors[cube[3, 5]], RenderIDs, grid);
        DrawSubCube(v3(-1, -1, -1), CubeColors[cube[4, 8]], CubeColors[cube[5, 0]], CubeColors[cube[3, 6]], RenderIDs, grid);
        DrawSubCube(v3(1, -1, -1), CubeColors[cube[2, 8]], CubeColors[cube[5, 2]], CubeColors[cube[3, 8]], RenderIDs, grid);
        DrawSubCube(v3(0, -1, -1), clnone, CubeColors[cube[5, 1]], CubeColors[cube[3, 7]], RenderIDs, grid);
        DrawSubCube(v3(0, 0, -1), clnone, clnone, CubeColors[cube[3, 4]], RenderIDs, grid);
        glpopmatrix;
      End;
    Y2, Ym2: Begin
        // 1. Ebene
        DrawSubCube(v3(-1, 1, -1), CubeColors[cube[4, 2]], CubeColors[cube[0, 0]], CubeColors[cube[3, 0]], RenderIDs, grid);
        DrawSubCube(v3(-1, 1, 1), CubeColors[cube[4, 0]], CubeColors[cube[0, 6]], CubeColors[cube[1, 0]], RenderIDs, grid);
        DrawSubCube(v3(0, 1, -1), clnone, CubeColors[cube[0, 1]], CubeColors[cube[3, 1]], RenderIDs, grid);
        DrawSubCube(v3(0, 1, 1), clnone, CubeColors[cube[0, 7]], CubeColors[cube[1, 1]], RenderIDs, grid);
        DrawSubCube(v3(1, 1, -1), CubeColors[cube[2, 2]], CubeColors[cube[0, 2]], CubeColors[cube[3, 2]], RenderIDs, grid);
        DrawSubCube(v3(1, 1, 1), CubeColors[cube[2, 0]], CubeColors[cube[0, 8]], CubeColors[cube[1, 2]], RenderIDs, grid);
        // 2. Ebene
        DrawSubCube(v3(-1, 0, -1), CubeColors[cube[4, 5]], clnone, CubeColors[cube[3, 3]], RenderIDs, grid);
        DrawSubCube(v3(-1, 0, 1), CubeColors[cube[4, 3]], clnone, CubeColors[cube[1, 3]], RenderIDs, grid);
        DrawSubCube(v3(0, 0, -1), clnone, clnone, CubeColors[cube[3, 4]], RenderIDs, grid);
        DrawSubCube(v3(0, 0, 1), clnone, clnone, CubeColors[cube[1, 4]], RenderIDs, grid);
        DrawSubCube(v3(1, 0, -1), CubeColors[cube[2, 5]], clnone, CubeColors[cube[3, 5]], RenderIDs, grid);
        DrawSubCube(v3(1, 0, 1), CubeColors[cube[2, 3]], clnone, CubeColors[cube[1, 5]], RenderIDs, grid);
        // 3. Ebene
        DrawSubCube(v3(-1, -1, -1), CubeColors[cube[4, 8]], CubeColors[cube[5, 0]], CubeColors[cube[3, 6]], RenderIDs, grid);
        DrawSubCube(v3(-1, -1, 1), CubeColors[cube[4, 6]], CubeColors[cube[5, 6]], CubeColors[cube[1, 6]], RenderIDs, grid);
        DrawSubCube(v3(0, -1, -1), clnone, CubeColors[cube[5, 1]], CubeColors[cube[3, 7]], RenderIDs, grid);
        DrawSubCube(v3(0, -1, 1), clnone, CubeColors[cube[5, 7]], CubeColors[cube[1, 7]], RenderIDs, grid);
        DrawSubCube(v3(1, -1, -1), CubeColors[cube[2, 8]], CubeColors[cube[5, 2]], CubeColors[cube[3, 8]], RenderIDs, grid);
        DrawSubCube(v3(1, -1, 1), CubeColors[cube[2, 6]], CubeColors[cube[5, 8]], CubeColors[cube[1, 8]], RenderIDs, grid);
        // Die zu rotierende Ebene
        glpushmatrix;
        glRotatef(progress, 0, 0, 1);
        DrawSubCube(v3(-1, 1, 0), CubeColors[cube[4, 1]], CubeColors[cube[0, 3]], clnone, RenderIDs, grid);
        DrawSubCube(v3(0, 1, 0), clnone, CubeColors[cube[0, 4]], clnone, RenderIDs, grid);
        DrawSubCube(v3(1, 1, 0), CubeColors[cube[2, 1]], CubeColors[cube[0, 5]], clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, 0, 0), CubeColors[cube[4, 4]], clnone, clnone, RenderIDs, grid);
        //  DrawSubCube(v3(0, 0, 0), clnone, clnone, clnone, RenderIDs, grid);  // Diesen Unterwürfel gibt es nicht ;)
        DrawSubCube(v3(1, 0, 0), CubeColors[cube[2, 4]], clnone, clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, -1, 0), CubeColors[cube[4, 7]], CubeColors[cube[5, 3]], clnone, RenderIDs, grid);
        DrawSubCube(v3(0, -1, 0), clnone, CubeColors[cube[5, 4]], clnone, RenderIDs, grid);
        DrawSubCube(v3(1, -1, 0), CubeColors[cube[2, 7]], CubeColors[cube[5, 5]], clnone, RenderIDs, grid);
        glpopmatrix;
      End;
    Y1, Ym1: Begin
        // 1. Ebene
        DrawSubCube(v3(-1, 1, -1), CubeColors[cube[4, 2]], CubeColors[cube[0, 0]], CubeColors[cube[3, 0]], RenderIDs, grid);
        DrawSubCube(v3(-1, 1, 0), CubeColors[cube[4, 1]], CubeColors[cube[0, 3]], clnone, RenderIDs, grid);
        DrawSubCube(v3(0, 1, -1), clnone, CubeColors[cube[0, 1]], CubeColors[cube[3, 1]], RenderIDs, grid);
        DrawSubCube(v3(0, 1, 0), clnone, CubeColors[cube[0, 4]], clnone, RenderIDs, grid);
        DrawSubCube(v3(1, 1, -1), CubeColors[cube[2, 2]], CubeColors[cube[0, 2]], CubeColors[cube[3, 2]], RenderIDs, grid);
        DrawSubCube(v3(1, 1, 0), CubeColors[cube[2, 1]], CubeColors[cube[0, 5]], clnone, RenderIDs, grid);
        // 2. Ebene
        DrawSubCube(v3(-1, 0, -1), CubeColors[cube[4, 5]], clnone, CubeColors[cube[3, 3]], RenderIDs, grid);
        DrawSubCube(v3(-1, 0, 0), CubeColors[cube[4, 4]], clnone, clnone, RenderIDs, grid);
        DrawSubCube(v3(0, 0, -1), clnone, clnone, CubeColors[cube[3, 4]], RenderIDs, grid);
        //  DrawSubCube(v3(0, 0, 0), clnone, clnone, clnone, RenderIDs, grid);  // Diesen Unterwürfel gibt es nicht ;)
        DrawSubCube(v3(1, 0, -1), CubeColors[cube[2, 5]], clnone, CubeColors[cube[3, 5]], RenderIDs, grid);
        DrawSubCube(v3(1, 0, 0), CubeColors[cube[2, 4]], clnone, clnone, RenderIDs, grid);
        // 3. Ebene
        DrawSubCube(v3(-1, -1, -1), CubeColors[cube[4, 8]], CubeColors[cube[5, 0]], CubeColors[cube[3, 6]], RenderIDs, grid);
        DrawSubCube(v3(-1, -1, 0), CubeColors[cube[4, 7]], CubeColors[cube[5, 3]], clnone, RenderIDs, grid);
        DrawSubCube(v3(0, -1, -1), clnone, CubeColors[cube[5, 1]], CubeColors[cube[3, 7]], RenderIDs, grid);
        DrawSubCube(v3(0, -1, 0), clnone, CubeColors[cube[5, 4]], clnone, RenderIDs, grid);
        DrawSubCube(v3(1, -1, -1), CubeColors[cube[2, 8]], CubeColors[cube[5, 2]], CubeColors[cube[3, 8]], RenderIDs, grid);
        DrawSubCube(v3(1, -1, 0), CubeColors[cube[2, 7]], CubeColors[cube[5, 5]], clnone, RenderIDs, grid);
        // Die zu rotierende Ebene
        glpushmatrix;
        glRotatef(progress, 0, 0, 1);
        DrawSubCube(v3(-1, 1, 1), CubeColors[cube[4, 0]], CubeColors[cube[0, 6]], CubeColors[cube[1, 0]], RenderIDs, grid);
        DrawSubCube(v3(0, 1, 1), clnone, CubeColors[cube[0, 7]], CubeColors[cube[1, 1]], RenderIDs, grid);
        DrawSubCube(v3(1, 1, 1), CubeColors[cube[2, 0]], CubeColors[cube[0, 8]], CubeColors[cube[1, 2]], RenderIDs, grid);
        DrawSubCube(v3(-1, 0, 1), CubeColors[cube[4, 3]], clnone, CubeColors[cube[1, 3]], RenderIDs, grid);
        DrawSubCube(v3(0, 0, 1), clnone, clnone, CubeColors[cube[1, 4]], RenderIDs, grid);
        DrawSubCube(v3(1, 0, 1), CubeColors[cube[2, 3]], clnone, CubeColors[cube[1, 5]], RenderIDs, grid);
        DrawSubCube(v3(-1, -1, 1), CubeColors[cube[4, 6]], CubeColors[cube[5, 6]], CubeColors[cube[1, 6]], RenderIDs, grid);
        DrawSubCube(v3(0, -1, 1), clnone, CubeColors[cube[5, 7]], CubeColors[cube[1, 7]], RenderIDs, grid);
        DrawSubCube(v3(1, -1, 1), CubeColors[cube[2, 6]], CubeColors[cube[5, 8]], CubeColors[cube[1, 8]], RenderIDs, grid);
        glpopmatrix;
      End;
    Z1, Zm1: Begin
        // 2. Ebene
        DrawSubCube(v3(-1, 0, -1), CubeColors[cube[4, 5]], clnone, CubeColors[cube[3, 3]], RenderIDs, grid);
        DrawSubCube(v3(-1, 0, 0), CubeColors[cube[4, 4]], clnone, clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, 0, 1), CubeColors[cube[4, 3]], clnone, CubeColors[cube[1, 3]], RenderIDs, grid);
        DrawSubCube(v3(0, 0, -1), clnone, clnone, CubeColors[cube[3, 4]], RenderIDs, grid);
        //  DrawSubCube(v3(0, 0, 0), clnone, clnone, clnone, RenderIDs, grid);  // Diesen Unterwürfel gibt es nicht ;)
        DrawSubCube(v3(0, 0, 1), clnone, clnone, CubeColors[cube[1, 4]], RenderIDs, grid);
        DrawSubCube(v3(1, 0, -1), CubeColors[cube[2, 5]], clnone, CubeColors[cube[3, 5]], RenderIDs, grid);
        DrawSubCube(v3(1, 0, 0), CubeColors[cube[2, 4]], clnone, clnone, RenderIDs, grid);
        DrawSubCube(v3(1, 0, 1), CubeColors[cube[2, 3]], clnone, CubeColors[cube[1, 5]], RenderIDs, grid);
        // 3. Ebene
        DrawSubCube(v3(-1, -1, -1), CubeColors[cube[4, 8]], CubeColors[cube[5, 0]], CubeColors[cube[3, 6]], RenderIDs, grid);
        DrawSubCube(v3(-1, -1, 0), CubeColors[cube[4, 7]], CubeColors[cube[5, 3]], clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, -1, 1), CubeColors[cube[4, 6]], CubeColors[cube[5, 6]], CubeColors[cube[1, 6]], RenderIDs, grid);
        DrawSubCube(v3(0, -1, -1), clnone, CubeColors[cube[5, 1]], CubeColors[cube[3, 7]], RenderIDs, grid);
        DrawSubCube(v3(0, -1, 0), clnone, CubeColors[cube[5, 4]], clnone, RenderIDs, grid);
        DrawSubCube(v3(0, -1, 1), clnone, CubeColors[cube[5, 7]], CubeColors[cube[1, 7]], RenderIDs, grid);
        DrawSubCube(v3(1, -1, -1), CubeColors[cube[2, 8]], CubeColors[cube[5, 2]], CubeColors[cube[3, 8]], RenderIDs, grid);
        DrawSubCube(v3(1, -1, 0), CubeColors[cube[2, 7]], CubeColors[cube[5, 5]], clnone, RenderIDs, grid);
        DrawSubCube(v3(1, -1, 1), CubeColors[cube[2, 6]], CubeColors[cube[5, 8]], CubeColors[cube[1, 8]], RenderIDs, grid);
        // Die zu rotierende Ebene
        glpushmatrix;
        glRotatef(progress, 0, 1, 0);
        DrawSubCube(v3(-1, 1, -1), CubeColors[cube[4, 2]], CubeColors[cube[0, 0]], CubeColors[cube[3, 0]], RenderIDs, grid);
        DrawSubCube(v3(-1, 1, 0), CubeColors[cube[4, 1]], CubeColors[cube[0, 3]], clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, 1, 1), CubeColors[cube[4, 0]], CubeColors[cube[0, 6]], CubeColors[cube[1, 0]], RenderIDs, grid);
        DrawSubCube(v3(0, 1, -1), clnone, CubeColors[cube[0, 1]], CubeColors[cube[3, 1]], RenderIDs, grid);
        DrawSubCube(v3(0, 1, 0), clnone, CubeColors[cube[0, 4]], clnone, RenderIDs, grid);
        DrawSubCube(v3(0, 1, 1), clnone, CubeColors[cube[0, 7]], CubeColors[cube[1, 1]], RenderIDs, grid);
        DrawSubCube(v3(1, 1, -1), CubeColors[cube[2, 2]], CubeColors[cube[0, 2]], CubeColors[cube[3, 2]], RenderIDs, grid);
        DrawSubCube(v3(1, 1, 0), CubeColors[cube[2, 1]], CubeColors[cube[0, 5]], clnone, RenderIDs, grid);
        DrawSubCube(v3(1, 1, 1), CubeColors[cube[2, 0]], CubeColors[cube[0, 8]], CubeColors[cube[1, 2]], RenderIDs, grid);
        glpopmatrix;
      End;
    Z2, Zm2: Begin
        // 1. Ebene
        DrawSubCube(v3(-1, 1, -1), CubeColors[cube[4, 2]], CubeColors[cube[0, 0]], CubeColors[cube[3, 0]], RenderIDs, grid);
        DrawSubCube(v3(-1, 1, 0), CubeColors[cube[4, 1]], CubeColors[cube[0, 3]], clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, 1, 1), CubeColors[cube[4, 0]], CubeColors[cube[0, 6]], CubeColors[cube[1, 0]], RenderIDs, grid);
        DrawSubCube(v3(0, 1, -1), clnone, CubeColors[cube[0, 1]], CubeColors[cube[3, 1]], RenderIDs, grid);
        DrawSubCube(v3(0, 1, 0), clnone, CubeColors[cube[0, 4]], clnone, RenderIDs, grid);
        DrawSubCube(v3(0, 1, 1), clnone, CubeColors[cube[0, 7]], CubeColors[cube[1, 1]], RenderIDs, grid);
        DrawSubCube(v3(1, 1, -1), CubeColors[cube[2, 2]], CubeColors[cube[0, 2]], CubeColors[cube[3, 2]], RenderIDs, grid);
        DrawSubCube(v3(1, 1, 0), CubeColors[cube[2, 1]], CubeColors[cube[0, 5]], clnone, RenderIDs, grid);
        DrawSubCube(v3(1, 1, 1), CubeColors[cube[2, 0]], CubeColors[cube[0, 8]], CubeColors[cube[1, 2]], RenderIDs, grid);
        // 3. Ebene
        DrawSubCube(v3(-1, -1, -1), CubeColors[cube[4, 8]], CubeColors[cube[5, 0]], CubeColors[cube[3, 6]], RenderIDs, grid);
        DrawSubCube(v3(-1, -1, 0), CubeColors[cube[4, 7]], CubeColors[cube[5, 3]], clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, -1, 1), CubeColors[cube[4, 6]], CubeColors[cube[5, 6]], CubeColors[cube[1, 6]], RenderIDs, grid);
        DrawSubCube(v3(0, -1, -1), clnone, CubeColors[cube[5, 1]], CubeColors[cube[3, 7]], RenderIDs, grid);
        DrawSubCube(v3(0, -1, 0), clnone, CubeColors[cube[5, 4]], clnone, RenderIDs, grid);
        DrawSubCube(v3(0, -1, 1), clnone, CubeColors[cube[5, 7]], CubeColors[cube[1, 7]], RenderIDs, grid);
        DrawSubCube(v3(1, -1, -1), CubeColors[cube[2, 8]], CubeColors[cube[5, 2]], CubeColors[cube[3, 8]], RenderIDs, grid);
        DrawSubCube(v3(1, -1, 0), CubeColors[cube[2, 7]], CubeColors[cube[5, 5]], clnone, RenderIDs, grid);
        DrawSubCube(v3(1, -1, 1), CubeColors[cube[2, 6]], CubeColors[cube[5, 8]], CubeColors[cube[1, 8]], RenderIDs, grid);
        // Die zu rotierende Ebene
        glpushmatrix;
        glRotatef(progress, 0, 1, 0);
        DrawSubCube(v3(-1, 0, -1), CubeColors[cube[4, 5]], clnone, CubeColors[cube[3, 3]], RenderIDs, grid);
        DrawSubCube(v3(-1, 0, 0), CubeColors[cube[4, 4]], clnone, clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, 0, 1), CubeColors[cube[4, 3]], clnone, CubeColors[cube[1, 3]], RenderIDs, grid);
        DrawSubCube(v3(0, 0, -1), clnone, clnone, CubeColors[cube[3, 4]], RenderIDs, grid);
        //  DrawSubCube(v3(0, 0, 0), clnone, clnone, clnone, RenderIDs, grid);  // Diesen Unterwürfel gibt es nicht ;)
        DrawSubCube(v3(0, 0, 1), clnone, clnone, CubeColors[cube[1, 4]], RenderIDs, grid);
        DrawSubCube(v3(1, 0, -1), CubeColors[cube[2, 5]], clnone, CubeColors[cube[3, 5]], RenderIDs, grid);
        DrawSubCube(v3(1, 0, 0), CubeColors[cube[2, 4]], clnone, clnone, RenderIDs, grid);
        DrawSubCube(v3(1, 0, 1), CubeColors[cube[2, 3]], clnone, CubeColors[cube[1, 5]], RenderIDs, grid);
        glpopmatrix;
      End;
    Z3, Zm3: Begin
        // 1. Ebene
        DrawSubCube(v3(-1, 1, -1), CubeColors[cube[4, 2]], CubeColors[cube[0, 0]], CubeColors[cube[3, 0]], RenderIDs, grid);
        DrawSubCube(v3(-1, 1, 0), CubeColors[cube[4, 1]], CubeColors[cube[0, 3]], clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, 1, 1), CubeColors[cube[4, 0]], CubeColors[cube[0, 6]], CubeColors[cube[1, 0]], RenderIDs, grid);
        DrawSubCube(v3(0, 1, -1), clnone, CubeColors[cube[0, 1]], CubeColors[cube[3, 1]], RenderIDs, grid);
        DrawSubCube(v3(0, 1, 0), clnone, CubeColors[cube[0, 4]], clnone, RenderIDs, grid);
        DrawSubCube(v3(0, 1, 1), clnone, CubeColors[cube[0, 7]], CubeColors[cube[1, 1]], RenderIDs, grid);
        DrawSubCube(v3(1, 1, -1), CubeColors[cube[2, 2]], CubeColors[cube[0, 2]], CubeColors[cube[3, 2]], RenderIDs, grid);
        DrawSubCube(v3(1, 1, 0), CubeColors[cube[2, 1]], CubeColors[cube[0, 5]], clnone, RenderIDs, grid);
        DrawSubCube(v3(1, 1, 1), CubeColors[cube[2, 0]], CubeColors[cube[0, 8]], CubeColors[cube[1, 2]], RenderIDs, grid);
        // 2. Ebene
        DrawSubCube(v3(-1, 0, -1), CubeColors[cube[4, 5]], clnone, CubeColors[cube[3, 3]], RenderIDs, grid);
        DrawSubCube(v3(-1, 0, 0), CubeColors[cube[4, 4]], clnone, clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, 0, 1), CubeColors[cube[4, 3]], clnone, CubeColors[cube[1, 3]], RenderIDs, grid);
        DrawSubCube(v3(0, 0, -1), clnone, clnone, CubeColors[cube[3, 4]], RenderIDs, grid);
        //  DrawSubCube(v3(0, 0, 0), clnone, clnone, clnone, RenderIDs, grid);  // Diesen Unterwürfel gibt es nicht ;)
        DrawSubCube(v3(0, 0, 1), clnone, clnone, CubeColors[cube[1, 4]], RenderIDs, grid);
        DrawSubCube(v3(1, 0, -1), CubeColors[cube[2, 5]], clnone, CubeColors[cube[3, 5]], RenderIDs, grid);
        DrawSubCube(v3(1, 0, 0), CubeColors[cube[2, 4]], clnone, clnone, RenderIDs, grid);
        DrawSubCube(v3(1, 0, 1), CubeColors[cube[2, 3]], clnone, CubeColors[cube[1, 5]], RenderIDs, grid);
        // Die zu rotierende Ebene
        glpushmatrix;
        glRotatef(progress, 0, 1, 0);
        DrawSubCube(v3(-1, -1, -1), CubeColors[cube[4, 8]], CubeColors[cube[5, 0]], CubeColors[cube[3, 6]], RenderIDs, grid);
        DrawSubCube(v3(-1, -1, 0), CubeColors[cube[4, 7]], CubeColors[cube[5, 3]], clnone, RenderIDs, grid);
        DrawSubCube(v3(-1, -1, 1), CubeColors[cube[4, 6]], CubeColors[cube[5, 6]], CubeColors[cube[1, 6]], RenderIDs, grid);
        DrawSubCube(v3(0, -1, -1), clnone, CubeColors[cube[5, 1]], CubeColors[cube[3, 7]], RenderIDs, grid);
        DrawSubCube(v3(0, -1, 0), clnone, CubeColors[cube[5, 4]], clnone, RenderIDs, grid);
        DrawSubCube(v3(0, -1, 1), clnone, CubeColors[cube[5, 7]], CubeColors[cube[1, 7]], RenderIDs, grid);
        DrawSubCube(v3(1, -1, -1), CubeColors[cube[2, 8]], CubeColors[cube[5, 2]], CubeColors[cube[3, 8]], RenderIDs, grid);
        DrawSubCube(v3(1, -1, 0), CubeColors[cube[2, 7]], CubeColors[cube[5, 5]], clnone, RenderIDs, grid);
        DrawSubCube(v3(1, -1, 1), CubeColors[cube[2, 6]], CubeColors[cube[5, 8]], CubeColors[cube[1, 8]], RenderIDs, grid);
        glpopmatrix;
      End;
  End;
End;

Procedure InitCubeCalculationVars;
Var
  x: Integer;
Begin
  // Erstellen der Array's für die Koordinaten der Kanten, und Ecken
  Kanten[0].fx := 0;
  Kanten[0].fy := 1;
  Kanten[0].sx := 3;
  Kanten[0].sy := 1;
  Kanten[1].fx := 0;
  Kanten[1].fy := 5;
  Kanten[1].sx := 2;
  Kanten[1].sy := 1;
  Kanten[2].fx := 0;
  Kanten[2].fy := 7;
  Kanten[2].sx := 1;
  Kanten[2].sy := 1;
  Kanten[3].fx := 0;
  Kanten[3].fy := 3;
  Kanten[3].sx := 4;
  Kanten[3].sy := 1;
  Kanten[4].fx := 4;
  Kanten[4].fy := 5;
  Kanten[4].sx := 3;
  Kanten[4].sy := 3;
  Kanten[5].fx := 3;
  Kanten[5].fy := 5;
  Kanten[5].sx := 2;
  Kanten[5].sy := 5;
  Kanten[6].fx := 2;
  Kanten[6].fy := 3;
  Kanten[6].sx := 1;
  Kanten[6].sy := 5;
  Kanten[7].fx := 1;
  Kanten[7].fy := 3;
  Kanten[7].sx := 4;
  Kanten[7].sy := 3;
  Kanten[8].fx := 3;
  Kanten[8].fy := 7;
  Kanten[8].sx := 5;
  Kanten[8].sy := 1;
  Kanten[9].fx := 2;
  Kanten[9].fy := 7;
  Kanten[9].sx := 5;
  Kanten[9].sy := 5;
  Kanten[10].fx := 1;
  Kanten[10].fy := 7;
  Kanten[10].sx := 5;
  Kanten[10].sy := 7;
  Kanten[11].fx := 4;
  Kanten[11].fy := 7;
  Kanten[11].sx := 5;
  Kanten[11].sy := 3;
  Ecken[0].fx := 0;
  Ecken[0].fy := 0;
  Ecken[0].sx := 3;
  Ecken[0].sy := 0;
  Ecken[0].tx := 4;
  Ecken[0].ty := 2;
  Ecken[1].fx := 0;
  Ecken[1].fy := 2;
  Ecken[1].sx := 3;
  Ecken[1].sy := 2;
  Ecken[1].tx := 2;
  Ecken[1].ty := 2;
  Ecken[2].fx := 0;
  Ecken[2].fy := 8;
  Ecken[2].sx := 2;
  Ecken[2].sy := 0;
  Ecken[2].tx := 1;
  Ecken[2].ty := 2;
  Ecken[3].fx := 0;
  Ecken[3].fy := 6;
  Ecken[3].sx := 1;
  Ecken[3].sy := 0;
  Ecken[3].tx := 4;
  Ecken[3].ty := 0;
  Ecken[4].fx := 4;
  Ecken[4].fy := 8;
  Ecken[4].sx := 3;
  Ecken[4].sy := 6;
  Ecken[4].tx := 5;
  Ecken[4].ty := 0;
  Ecken[5].fx := 3;
  Ecken[5].fy := 8;
  Ecken[5].sx := 2;
  Ecken[5].sy := 8;
  Ecken[5].tx := 5;
  Ecken[5].ty := 2;
  Ecken[6].fx := 2;
  Ecken[6].fy := 6;
  Ecken[6].sx := 1;
  Ecken[6].sy := 8;
  Ecken[6].tx := 5;
  Ecken[6].ty := 8;
  Ecken[7].fx := 1;
  Ecken[7].fy := 6;
  Ecken[7].sx := 4;
  Ecken[7].sy := 6;
  Ecken[7].tx := 5;
  Ecken[7].ty := 6;
  // Erstellen der Array's für die Koordinaten der Kanten, und Ecken
  // Erstellen der Array's für die Kanten und Ecken Farben
  KantenFarbe[0].fc := 2;
  KantenFarbe[0].sc := 5;
  KantenFarbe[1].fc := 1;
  KantenFarbe[1].sc := 5;
  KantenFarbe[2].fc := 4;
  KantenFarbe[2].sc := 5;
  KantenFarbe[3].fc := 2;
  KantenFarbe[3].sc := 5;
  KantenFarbe[4].fc := 3;
  KantenFarbe[4].sc := 4;
  KantenFarbe[5].fc := 2;
  KantenFarbe[5].sc := 3;
  KantenFarbe[6].fc := 2;
  KantenFarbe[6].sc := 1;
  KantenFarbe[7].fc := 1;
  KantenFarbe[7].sc := 4;
  KantenFarbe[8].fc := 0;
  KantenFarbe[8].sc := 4;
  KantenFarbe[9].fc := 0;
  KantenFarbe[9].sc := 1;
  KantenFarbe[10].fc := 0;
  KantenFarbe[10].sc := 2;
  KantenFarbe[11].fc := 0;
  KantenFarbe[11].sc := 3;
  For x := 0 To 7 Do Begin
    eckenfarbe[x].fc := Ecken[x].fx;
    eckenfarbe[x].sc := Ecken[x].sx;
    eckenfarbe[x].tc := Ecken[x].tx;
  End;
  // Erstellen der Array's für die Kanten und Ecken Farben

End;

// Rotieren der Ebene Index um die X Achse !!

Procedure XRot(Index: integer; Var Cb: Tcube); // Fertig !
(*
1,2,3 = Rotieren der Ebenen gegen den Uhrzeigersinn
-1,-2,-3 = Rotieren der Ebenen mit dem Uhrzeigersinn
*)
Var
  x1, x2, x3: integer;
Begin
  Case index Of
    -3: Begin
        Xrot(3, CB);
        Xrot(3, CB);
        Xrot(3, CB);
      End;
    -2: Begin
        Xrot(2, CB);
        Xrot(2, CB);
        Xrot(2, CB);
      End;
    -1: Begin
        Xrot(1, cb);
        Xrot(1, cb);
        Xrot(1, cb);
      End;
    1: Begin
        // Rotieren der Seitlichen Ebene
        x1 := CB[0, 0];
        x2 := CB[0, 3];
        x3 := CB[0, 6];
        CB[0, 0] := CB[3, 6];
        CB[0, 3] := CB[3, 3];
        CB[0, 6] := CB[3, 0];
        CB[3, 6] := CB[5, 6];
        CB[3, 3] := CB[5, 3];
        CB[3, 0] := CB[5, 0];
        CB[5, 6] := CB[1, 0];
        CB[5, 3] := CB[1, 3];
        CB[5, 0] := CB[1, 6];
        CB[1, 6] := X3;
        CB[1, 3] := X2;
        CB[1, 0] := X1;
        // Rotieren der Seitlichen Ebene
        // Rotieren der Seitenfläche
        x1 := CB[4, 0];
        x2 := CB[4, 1];
        CB[4, 0] := CB[4, 2];
        CB[4, 1] := CB[4, 5];
        CB[4, 2] := CB[4, 8];
        CB[4, 5] := CB[4, 7];
        CB[4, 7] := CB[4, 3];
        CB[4, 8] := CB[4, 6];
        CB[4, 3] := x2;
        CB[4, 6] := x1;
        // Rotieren der Seitenfläche
      End;
    2: Begin
        // Rotieren der Mittleren Ebene
        x1 := CB[0, 1];
        x2 := CB[0, 4];
        x3 := CB[0, 7];
        CB[0, 1] := CB[3, 7];
        CB[0, 4] := CB[3, 4];
        CB[0, 7] := CB[3, 1];
        CB[3, 7] := CB[5, 7];
        CB[3, 4] := CB[5, 4];
        CB[3, 1] := CB[5, 1];
        CB[5, 7] := CB[1, 1];
        CB[5, 4] := CB[1, 4];
        CB[5, 1] := CB[1, 7];
        CB[1, 7] := X3;
        CB[1, 4] := X2;
        CB[1, 1] := X1;
        // Rotieren der Mittleren Ebene
      End;
    3: Begin
        // Rotieren der Seitlichen Ebene
        x1 := CB[0, 2];
        x2 := CB[0, 5];
        x3 := CB[0, 8];
        CB[0, 2] := CB[3, 8];
        CB[0, 5] := CB[3, 5];
        CB[0, 8] := CB[3, 2];
        CB[3, 8] := CB[5, 8];
        CB[3, 5] := CB[5, 5];
        CB[3, 2] := CB[5, 2];
        CB[5, 8] := CB[1, 2];
        CB[5, 5] := CB[1, 5];
        CB[5, 2] := CB[1, 8];
        CB[1, 8] := X3;
        CB[1, 5] := X2;
        CB[1, 2] := X1;
        // Rotieren der Seitlichen Ebene
        // Rotieren der Seitenfläche
        x1 := CB[2, 0];
        x2 := CB[2, 1];
        CB[2, 0] := CB[2, 2];
        CB[2, 1] := CB[2, 5];
        CB[2, 2] := CB[2, 8];
        CB[2, 5] := CB[2, 7];
        CB[2, 7] := CB[2, 3];
        CB[2, 8] := CB[2, 6];
        CB[2, 3] := x2;
        CB[2, 6] := x1;
        // Rotieren der Seitenfläche
      End;
  End;
End;

// Rotieren der Ebene Index um die Y Achse !!

Procedure YRot(Index: Integer; Var CB: TCube); // Fertig !!
(*
1,2,3 = Rotieren der Ebenen gegen den Uhrzeigersinn
-1,-2,-3 = Rotieren der Ebenen mit dem Uhrzeigersinn
*)
Var
  x1, x2, x3: Integer;
Begin
  Case index Of
    -3: Begin
        yrot(3, cb);
        yrot(3, cb);
        yrot(3, cb);
      End;
    -2: Begin
        yrot(2, cb);
        yrot(2, cb);
        yrot(2, cb);
      End;
    -1: Begin
        yrot(1, cb);
        yrot(1, cb);
        yrot(1, cb);
      End;
    1: Begin
        // Rotieren der Seitlichen Ebene
        x1 := CB[0, 6];
        x2 := CB[0, 7];
        x3 := CB[0, 8];
        CB[0, 6] := CB[4, 6];
        CB[0, 7] := CB[4, 3];
        CB[0, 8] := CB[4, 0];
        CB[4, 6] := CB[5, 8];
        CB[4, 3] := CB[5, 7];
        CB[4, 0] := CB[5, 6];
        CB[5, 8] := CB[2, 0];
        CB[5, 7] := CB[2, 3];
        CB[5, 6] := CB[2, 6];
        CB[2, 0] := X1;
        CB[2, 3] := X2;
        CB[2, 6] := X3;
        // Rotieren der Seitlichen Ebene
        // Rotieren der Seitenfläche
        x1 := CB[1, 0];
        x2 := CB[1, 1];
        CB[1, 0] := CB[1, 6];
        CB[1, 1] := CB[1, 3];
        CB[1, 3] := CB[1, 7];
        CB[1, 6] := CB[1, 8];
        CB[1, 7] := CB[1, 5];
        CB[1, 8] := CB[1, 2];
        CB[1, 5] := x2;
        CB[1, 2] := x1;
        // Rotieren der Seitenfläche
      End;
    2: Begin
        // Rotieren der Mittleren Ebene
        x1 := CB[0, 3];
        x2 := CB[0, 4];
        x3 := CB[0, 5];
        CB[0, 3] := CB[4, 7];
        CB[0, 4] := CB[4, 4];
        CB[0, 5] := CB[4, 1];
        CB[4, 7] := CB[5, 5];
        CB[4, 4] := CB[5, 4];
        CB[4, 1] := CB[5, 3];
        CB[5, 5] := CB[2, 1];
        CB[5, 4] := CB[2, 4];
        CB[5, 3] := CB[2, 7];
        CB[2, 1] := X1;
        CB[2, 4] := X2;
        CB[2, 7] := X3;
        // Rotieren der Mittleren Ebene
      End;
    3: Begin
        // Rotieren der Seitlichen Ebene
        x1 := CB[0, 0];
        x2 := CB[0, 1];
        x3 := CB[0, 2];
        CB[0, 0] := CB[4, 8];
        CB[0, 1] := CB[4, 5];
        CB[0, 2] := CB[4, 2];
        CB[4, 8] := CB[5, 2];
        CB[4, 5] := CB[5, 1];
        CB[4, 2] := CB[5, 0];
        CB[5, 2] := CB[2, 2];
        CB[5, 1] := CB[2, 5];
        CB[5, 0] := CB[2, 8];
        CB[2, 2] := X1;
        CB[2, 5] := X2;
        CB[2, 8] := X3;
        // Rotieren der Seitlichen Ebene
        // Rotieren der Seitenfläche
        x1 := CB[3, 0];
        x2 := CB[3, 1];
        CB[3, 0] := CB[3, 6];
        CB[3, 1] := CB[3, 3];
        CB[3, 3] := CB[3, 7];
        CB[3, 6] := CB[3, 8];
        CB[3, 7] := CB[3, 5];
        CB[3, 8] := CB[3, 2];
        CB[3, 5] := x2;
        CB[3, 2] := x1;
        // Rotieren der Seitenfläche
      End;
  End;
End;

// Rotieren der Ebene Index um die Z Achse  !!

Procedure ZRot(Index: integer; Var Cb: Tcube); // Fertig !
(*
1,2,3 = Rotieren der Ebenen gegen den Uhrzeigersinn
-1,-2,-3 = Rotieren der Ebenen mit dem Uhrzeigersinn
*)
Var
  x1, x2, x3: Integer;
Begin
  Case index Of
    -3: Begin
        zrot(3, cb);
        zrot(3, cb);
        zrot(3, cb);
      End;
    -2: Begin
        zrot(2, cb);
        zrot(2, cb);
        zrot(2, cb);
      End;
    -1: Begin
        zrot(1, cb);
        zrot(1, cb);
        zrot(1, cb);
      End;
    1: Begin
        // Rotieren der Seitlichen Ebene
        x1 := CB[1, 0];
        x2 := CB[1, 1];
        x3 := CB[1, 2];
        CB[1, 0] := CB[4, 2];
        CB[1, 1] := CB[4, 1];
        CB[1, 2] := CB[4, 0];
        CB[4, 2] := CB[3, 2];
        CB[4, 1] := CB[3, 1];
        CB[4, 0] := CB[3, 0];
        CB[3, 2] := CB[2, 0];
        CB[3, 1] := CB[2, 1];
        CB[3, 0] := CB[2, 2];
        CB[2, 0] := X1;
        CB[2, 1] := X2;
        CB[2, 2] := X3;
        // Rotieren der Seitlichen Ebene
        // Rotieren der Seitenfläche
        x1 := CB[0, 0];
        x2 := CB[0, 1];
        CB[0, 0] := CB[0, 2];
        CB[0, 1] := CB[0, 5];
        CB[0, 2] := CB[0, 8];
        CB[0, 5] := CB[0, 7];
        CB[0, 8] := CB[0, 6];
        CB[0, 7] := CB[0, 3];
        CB[0, 6] := x1;
        CB[0, 3] := x2;
        // Rotieren der Seitenfläche
      End;
    2: Begin
        // Rotieren der Mittleren Ebene
        x1 := CB[1, 3];
        x2 := CB[1, 4];
        x3 := CB[1, 5];
        CB[1, 3] := CB[4, 5];
        CB[1, 4] := CB[4, 4];
        CB[1, 5] := CB[4, 3];
        CB[4, 5] := CB[3, 5];
        CB[4, 4] := CB[3, 4];
        CB[4, 3] := CB[3, 3];
        CB[3, 5] := CB[2, 3];
        CB[3, 4] := CB[2, 4];
        CB[3, 3] := CB[2, 5];
        CB[2, 3] := X1;
        CB[2, 4] := X2;
        CB[2, 5] := X3;
        // Rotieren der Mittleren Ebene
      End;
    3: Begin
        // Rotieren der Seitlichen Ebene
        x1 := CB[1, 6];
        x2 := CB[1, 7];
        x3 := CB[1, 8];
        CB[1, 6] := CB[4, 8];
        CB[1, 7] := CB[4, 7];
        CB[1, 8] := CB[4, 6];
        CB[4, 8] := CB[3, 8];
        CB[4, 7] := CB[3, 7];
        CB[4, 6] := CB[3, 6];
        CB[3, 8] := CB[2, 6];
        CB[3, 7] := CB[2, 7];
        CB[3, 6] := CB[2, 8];
        CB[2, 6] := X1;
        CB[2, 7] := X2;
        CB[2, 8] := X3;
        // Rotieren der Seitlichen Ebene
        // Rotieren der Seitenfläche
        x1 := CB[5, 0];
        x2 := CB[5, 1];
        CB[5, 0] := CB[5, 2];
        CB[5, 1] := CB[5, 5];
        CB[5, 2] := CB[5, 8];
        CB[5, 5] := CB[5, 7];
        CB[5, 8] := CB[5, 6];
        CB[5, 7] := CB[5, 3];
        CB[5, 6] := x1;
        CB[5, 3] := x2;
        // Rotieren der Seitenfläche
      End;
  End;
End;

Procedure DoJob(Job: TJob; Var Cube: TCube); // Führt einen Job aus
Begin
  Case job Of
    xm1: XRot(-1, Cube);
    xm2: XRot(-2, Cube);
    xm3: XRot(-3, Cube);
    zm1: ZROT(-1, Cube);
    zm2: ZROT(-2, Cube);
    zm3: ZROT(-3, Cube);
    ym3: YRot(-3, Cube);
    ym2: YRot(-2, Cube);
    ym1: YRot(-1, Cube);
    x3: XRot(3, Cube);
    x2: XRot(2, Cube);
    x1: XRot(1, Cube);
    z3: ZROT(3, Cube);
    z2: ZROT(2, Cube);
    z1: ZROT(1, Cube);
    y1: YRot(1, Cube);
    y2: YRot(2, Cube);
    y3: YRot(3, Cube);
  End;
End;

// Hier wird geprüft ob alle Felder und Farbkombinationen im Cube Real sind !!

Function Checkcube(Const Cube: TCube): Boolean;
Var
  x, y, C0, C1, C2, C3, C4, C5: Integer;
  c: Array[0..5] Of Boolean;
  K: Array[0..11] Of Boolean;
  w: Tcube;
  e: Array[0..7] Of -1..7;
  r: Array[0..7] Of boolean;
  n: boolean;
Begin
  //  setlength(ltodo, 0);
  Result := true;
  // Überprüfen ob von Jeder Farbe auch nur 9 existieren
  c0 := 0;
  c1 := 0;
  c2 := 0;
  c3 := 0;
  c4 := 0;
  c5 := 0;
  For x := 0 To 5 Do
    For y := 0 To 8 Do
      Case Cube[x, y] Of
        0: inc(c0);
        1: inc(c1);
        2: inc(c2);
        3: inc(c3);
        4: inc(c4);
        5: inc(c5);
      End;
  If (C0 <> 9) Or (C1 <> 9) Or (C2 <> 9) Or (C3 <> 9) Or (C4 <> 9) Or (C5 <> 9) Then Begin // Wenn eines der C <> 9 dann Error
    Result := false;
    showmessage('From every color there had to be 9 fields.');
    exit;
  End;
  // Überprüfen ob von Jeder Farbe auch nur 9 existieren
  // Überprüfen ob die Mittleren Felder Richtig sind
  For x := 0 To 5 Do
    c[x] := false;
  For x := 0 To 5 Do Begin
    If c[Cube[x, 4]] Then Begin
      Result := false;
      Showmessage('The middle colors have to be different.');
      exit;
    End;
    c[Cube[x, 4]] := true;
  End;
  // Überprüfen ob die Mittleren Felder Richtig sind
  // Nachschauen ob die Kantenstücke Realistische Farben haben
  For x := 0 To 11 Do
    K[x] := false;
  For x := 0 To 11 Do
    For y := 0 To 11 Do Begin
      If (Kantenfarbe[y].fc = Cube[KAnten[x].fx, KAnten[x].fy]) And
        (Kantenfarbe[y].sc = Cube[KAnten[x].sx, KAnten[x].sy]) Then Begin
        If k[y] Then Begin
          Result := false;
          Showmessage('The colors of the middle edges have to be different.');
          exit;
        End
        Else
          k[y] := true;
      End;
      If (Kantenfarbe[y].sc = Cube[KAnten[x].fx, KAnten[x].fy]) And
        (Kantenfarbe[y].fc = Cube[KAnten[x].sx, KAnten[x].sy]) Then Begin
        If k[y] Then Begin
          Result := false;
          Showmessage('The colors of the middle edges have to be different.');
          exit;
        End
        Else
          k[y] := true;
      End;
    End;
  For x := 0 To 11 Do
    If Not (k[x]) Then Begin
      Result := false;
      Showmessage('The colors of the middle edges have to be different.');
      exit;
    End;
  // Nachschauen ob die Kantenstücke Realistische Farben haben
  // Nachschauen ob die Eckstücke Realistische Farben haben
  For x := 0 To 7 Do Begin
    r[x] := false;
    e[x] := -1;
  End;
  // Suchen der Position der Ecken !!
  For x := 0 To 7 Do
    For y := 0 To 7 Do
      If Sametribble(Cube[ecken[x].fx, ecken[x].fy], Cube[ecken[x].sx, ecken[x].sy], Cube[ecken[x].tx, ecken[x].ty],
        eckenfarbe[y].fc, eckenfarbe[y].sc, eckenfarbe[Y].tc) Then
        If E[y] = -1 Then
          e[y] := x
        Else Begin
          Result := false;
          Showmessage('The colors of the corners have to be different.');
          exit;
        End;
  For c0 := 0 To 7 Do Begin
    //    setlength(ltodo, 0);
    // Erstellen einer Kopie des Würfels, auf diser wird dann gearbeitet
    For x := 0 To 5 Do
      For y := 0 To 8 Do
        w[x, y] := Cube[x, y];
    Case c0 Of
      0: Begin // Hindrehen der Ecken null und dann auswerten !!
          n := false;
          Case e[c0] Of
            1: DoJob(z1, w);
            2: Begin
                DoJob(z1, w);
                DoJob(z1, w);
              End;
            3: DoJob(zm1, w);
            4: DoJob(x1, w);
            5: Begin
                DoJob(z3, w);
                DoJob(x1, w);
              End;
            6: Begin
                DoJob(z3, w);
                DoJob(z3, w);
                DoJob(x1, w);
              End;
            7: Begin
                DoJob(x1, w);
                DoJob(x1, w);
              End;
          End;
          // nun Auswerten der Ecke 0
          c1 := w[Ecken[c0].fx, Ecken[c0].fy];
          c2 := w[Ecken[c0].sx, Ecken[c0].sy];
          c3 := w[Ecken[c0].tx, Ecken[c0].ty];
          If (C1 = Eckenfarbe[C0].fc) And
            (C2 = Eckenfarbe[C0].sc) And
            (C3 = Eckenfarbe[C0].tc) Then n := true;
          If (C3 = Eckenfarbe[C0].fc) And
            (C1 = Eckenfarbe[C0].sc) And
            (C2 = Eckenfarbe[C0].tc) Then n := true;
          If (C2 = Eckenfarbe[C0].fc) And
            (C3 = Eckenfarbe[C0].sc) And
            (C1 = Eckenfarbe[C0].tc) Then n := true;
          If N Then
            If r[c0] Then Begin
              result := false;
              showmessage('The colors of the corners have to be different.');
              exit;
            End
            Else
              r[c0] := true;
        End;
      1: Begin
          n := false;
          Case e[c0] Of
            0: DoJob(zm1, w);
            2: DoJob(z1, w);
            3: Begin
                DoJob(zm1, w);
                DoJob(zm1, w);
              End;
            4: Begin
                DoJob(ym3, w);
                DoJob(ym3, w);
              End;
            5: DoJob(x3, w);
            6: Begin
                DoJob(x3, w);
                DoJob(x3, w);
              End;
            7: Begin
                DoJob(z3, w);
                DoJob(x3, w);
                DoJob(x3, w);
              End;
          End;
          // nun Auswerten der Ecke 1
          c1 := w[Ecken[c0].fx, Ecken[c0].fy];
          c2 := w[Ecken[c0].sx, Ecken[c0].sy];
          c3 := w[Ecken[c0].tx, Ecken[c0].ty];
          If (C1 = Eckenfarbe[C0].fc) And
            (C2 = Eckenfarbe[C0].sc) And
            (C3 = Eckenfarbe[C0].tc) Then n := true;
          If (C3 = Eckenfarbe[C0].fc) And
            (C1 = Eckenfarbe[C0].sc) And
            (C2 = Eckenfarbe[C0].tc) Then n := true;
          If (C2 = Eckenfarbe[C0].fc) And
            (C3 = Eckenfarbe[C0].sc) And
            (C1 = Eckenfarbe[C0].tc) Then n := true;
          If N Then
            If r[c0] Then Begin
              result := false;
              showmessage('The colors of the corners have to be different.');
              exit;
            End
            Else
              r[c0] := true;
        End;
      2: Begin
          n := false;
          Case e[c0] Of
            0: Begin
                DoJob(zm1, w);
                DoJob(zm1, w);
              End;
            1: DoJob(zm1, w);
            3: DoJob(z1, w);
            4: Begin
                DoJob(x1, w);
                DoJob(zm1, w);
                DoJob(zm1, w);
              End;
            5: Begin
                DoJob(x3, w);
                DoJob(x3, w);
              End;
            6: DoJob(xm3, w);
            7: Begin
                DoJob(z3, w);
                DoJob(xm3, w);
              End;
          End;
          // nun Auswerten der Ecke 2
          c1 := w[Ecken[c0].fx, Ecken[c0].fy];
          c2 := w[Ecken[c0].sx, Ecken[c0].sy];
          c3 := w[Ecken[c0].tx, Ecken[c0].ty];
          If (C1 = Eckenfarbe[C0].fc) And
            (C2 = Eckenfarbe[C0].sc) And
            (C3 = Eckenfarbe[C0].tc) Then n := true;
          If (C3 = Eckenfarbe[C0].fc) And
            (C1 = Eckenfarbe[C0].sc) And
            (C2 = Eckenfarbe[C0].tc) Then n := true;
          If (C2 = Eckenfarbe[C0].fc) And
            (C3 = Eckenfarbe[C0].sc) And
            (C1 = Eckenfarbe[C0].tc) Then n := true;
          If N Then
            If r[c0] Then Begin
              result := false;
              showmessage('The colors of the corners have to be different.');
              exit;
            End
            Else
              r[c0] := true;
        End;
      3: Begin
          n := false;
          Case e[c0] Of
            0: DoJob(z1, w);
            1: Begin
                DoJob(zm1, w);
                DoJob(zm1, w);
              End;
            2: DoJob(zm1, w);
            4: Begin
                DoJob(x1, w);
                DoJob(x1, w);
              End;
            5: Begin
                DoJob(z3, w);
                DoJob(x1, w);
                DoJob(x1, w);
              End;
            6: Begin
                DoJob(ym1, w);
                DoJob(ym1, w);
              End;
            7: DoJob(xm1, w);
          End;
          // nun Auswerten der Ecke 3
          c1 := w[Ecken[c0].fx, Ecken[c0].fy];
          c2 := w[Ecken[c0].sx, Ecken[c0].sy];
          c3 := w[Ecken[c0].tx, Ecken[c0].ty];
          If (C1 = Eckenfarbe[C0].fc) And
            (C2 = Eckenfarbe[C0].sc) And
            (C3 = Eckenfarbe[C0].tc) Then n := true;
          If (C3 = Eckenfarbe[C0].fc) And
            (C1 = Eckenfarbe[C0].sc) And
            (C2 = Eckenfarbe[C0].tc) Then n := true;
          If (C2 = Eckenfarbe[C0].fc) And
            (C3 = Eckenfarbe[C0].sc) And
            (C1 = Eckenfarbe[C0].tc) Then n := true;
          If N Then
            If r[c0] Then Begin
              result := false;
              showmessage('The colors of the corners have to be different.');
              exit;
            End
            Else
              r[c0] := true;
        End;
      4: Begin
          n := false;
          Case e[c0] Of
            0: DoJob(xm1, w);
            1: Begin
                DoJob(z1, w);
                DoJob(xm1, w);
              End;
            2: Begin
                DoJob(zm1, w);
                DoJob(zm1, w);
                DoJob(xm1, w);
              End;
            3: Begin
                DoJob(zm1, w);
                DoJob(xm1, w);
              End;
            5: DoJob(z3, w);
            6: Begin
                DoJob(z3, w);
                DoJob(z3, w);
              End;
            7: DoJob(zm3, w);
          End;
          // nun Auswerten der Ecke 4
          c1 := w[Ecken[c0].fx, Ecken[c0].fy];
          c2 := w[Ecken[c0].sx, Ecken[c0].sy];
          c3 := w[Ecken[c0].tx, Ecken[c0].ty];
          If (C1 = Eckenfarbe[C0].fc) And
            (C2 = Eckenfarbe[C0].sc) And
            (C3 = Eckenfarbe[C0].tc) Then n := true;
          If (C3 = Eckenfarbe[C0].fc) And
            (C1 = Eckenfarbe[C0].sc) And
            (C2 = Eckenfarbe[C0].tc) Then n := true;
          If (C2 = Eckenfarbe[C0].fc) And
            (C3 = Eckenfarbe[C0].sc) And
            (C1 = Eckenfarbe[C0].tc) Then n := true;
          If N Then
            If r[c0] Then Begin
              result := false;
              showmessage('The colors of the corners have to be different.');
              exit;
            End
            Else
              r[c0] := true;
        End;
      5: Begin
          n := false;
          Case e[c0] Of
            0: Begin
                DoJob(xm1, w);
                DoJob(zm3, w);
              End;
            1: DoJob(xm3, w);
            2: Begin
                DoJob(xm3, w);
                DoJob(xm3, w);
              End;
            3: Begin
                DoJob(z1, w);
                DoJob(xm3, w);
                DoJob(xm3, w);
              End;
            4: DoJob(zm3, w);
            6: DoJob(z3, w);
            7: Begin
                DoJob(zm3, w);
                DoJob(zm3, w);
              End;
          End;
          // nun Auswerten der Ecke 4
          c1 := w[Ecken[c0].fx, Ecken[c0].fy];
          c2 := w[Ecken[c0].sx, Ecken[c0].sy];
          c3 := w[Ecken[c0].tx, Ecken[c0].ty];
          If (C1 = Eckenfarbe[C0].fc) And
            (C2 = Eckenfarbe[C0].sc) And
            (C3 = Eckenfarbe[C0].tc) Then n := true;
          If (C3 = Eckenfarbe[C0].fc) And
            (C1 = Eckenfarbe[C0].sc) And
            (C2 = Eckenfarbe[C0].tc) Then n := true;
          If (C2 = Eckenfarbe[C0].fc) And
            (C3 = Eckenfarbe[C0].sc) And
            (C1 = Eckenfarbe[C0].tc) Then n := true;
          If N Then
            If r[c0] Then Begin
              result := false;
              showmessage('The colors of the corners have to be different.');
              exit;
            End
            Else
              r[c0] := true;
        End;
      6: Begin
          n := false;
          Case e[c0] Of
            0: Begin
                DoJob(zm1, w);
                DoJob(xm3, w);
                DoJob(xm3, w);
              End;
            1: Begin
                DoJob(xm3, w);
                DoJob(xm3, w);
              End;
            2: DoJob(x3, w);
            3: Begin
                DoJob(y1, w);
                DoJob(y1, w);
              End;
            4: Begin
                DoJob(zm3, w);
                DoJob(zm3, w);
              End;
            5: DoJob(zm3, w);
            7: DoJob(z3, w);
          End;
          // nun Auswerten der Ecke 4
          c1 := w[Ecken[c0].fx, Ecken[c0].fy];
          c2 := w[Ecken[c0].sx, Ecken[c0].sy];
          c3 := w[Ecken[c0].tx, Ecken[c0].ty];
          If (C1 = Eckenfarbe[C0].fc) And
            (C2 = Eckenfarbe[C0].sc) And
            (C3 = Eckenfarbe[C0].tc) Then n := true;
          If (C3 = Eckenfarbe[C0].fc) And
            (C1 = Eckenfarbe[C0].sc) And
            (C2 = Eckenfarbe[C0].tc) Then n := true;
          If (C2 = Eckenfarbe[C0].fc) And
            (C3 = Eckenfarbe[C0].sc) And
            (C1 = Eckenfarbe[C0].tc) Then n := true;
          If N Then
            If r[c0] Then Begin
              result := false;
              showmessage('The colors of the corners have to be different.');
              exit;
            End
            Else
              r[c0] := true;
        End;
      7: Begin
          n := false;
          Case e[c0] Of
            0: Begin
                DoJob(xm1, w);
                DoJob(xm1, w);
              End;
            1: Begin
                DoJob(z1, w);
                DoJob(xm1, w);
                DoJob(xm1, w);
              End;
            2: Begin
                DoJob(y1, w);
                DoJob(y1, w);
              End;
            3: DoJob(x1, w);
            4: DoJob(z3, w);
            5: Begin
                DoJob(zm3, w);
                DoJob(zm3, w);
              End;
            6: DoJob(zm3, w);
          End;
          // nun Auswerten der Ecke 4
          c1 := w[Ecken[c0].fx, Ecken[c0].fy];
          c2 := w[Ecken[c0].sx, Ecken[c0].sy];
          c3 := w[Ecken[c0].tx, Ecken[c0].ty];
          If (C1 = Eckenfarbe[C0].fc) And
            (C2 = Eckenfarbe[C0].sc) And
            (C3 = Eckenfarbe[C0].tc) Then n := true;
          If (C3 = Eckenfarbe[C0].fc) And
            (C1 = Eckenfarbe[C0].sc) And
            (C2 = Eckenfarbe[C0].tc) Then n := true;
          If (C2 = Eckenfarbe[C0].fc) And
            (C3 = Eckenfarbe[C0].sc) And
            (C1 = Eckenfarbe[C0].tc) Then n := true;
          If N Then
            If r[c0] Then Begin
              result := false;
              showmessage('The colors of the corners have to be different.');
              exit;
            End
            Else
              r[c0] := true;
        End;
    End;
  End;
  For x := 0 To 7 Do
    If Not (r[x]) Then Begin
      result := false;
      showmessage('The colors of the corners have to be different.');
      exit;
    End;
  //  setlength(ltodo, 0);
  // Nachschauen ob die Eckstücke Realistische Farben haben
End;

Procedure PreSolve(Const Cube: TCube; Var ToDoList: TLtodo);

  Procedure adddo(job: Tjob);
  Begin
    setlength(ToDoList, high(ToDoList) + 2);
    ToDoList[high(ToDoList)] := job;
  End;

Var
  x, b: Integer;
Begin
  setlength(ToDoList, 0);
  b := -1;
  //  setlength(ltodo, 0);
    // Falls eine Ebene Irgendwie schon stimmt wird sie hier nach oben gedreht !!
  For x := 0 To 5 Do
    If (Cube[x, 0] = Cube[x, 4]) And
      (Cube[x, 1] = Cube[x, 4]) And
      (Cube[x, 2] = Cube[x, 4]) And
      (Cube[x, 3] = Cube[x, 4]) And
      (Cube[x, 5] = Cube[x, 4]) And
      (Cube[x, 6] = Cube[x, 4]) And
      (Cube[x, 7] = Cube[x, 4]) And
      (Cube[x, 8] = Cube[x, 4]) Then Begin
      b := x;
      Break;
    End;
  // eine ganze Fläche stimmt nun werden die seitenkanten dazu überprüft, stimmen diese auch wird gehandelt ansonsten mit b:=-1; raussprung !
  Case b Of
    1: Begin
        If Not ((Cube[0, 6] = Cube[0, 7]) And
          (Cube[0, 6] = Cube[0, 8]) And
          (Cube[2, 0] = Cube[2, 3]) And
          (Cube[2, 3] = Cube[2, 6]) And
          (Cube[5, 6] = Cube[5, 7]) And
          (Cube[5, 6] = Cube[5, 8]) And
          (Cube[4, 6] = Cube[4, 3]) And
          (Cube[4, 6] = Cube[4, 0])) Then b := -1;
      End;
    2: Begin
        If Not ((Cube[0, 8] = Cube[0, 5]) And
          (Cube[0, 8] = Cube[0, 2]) And
          (Cube[1, 2] = Cube[1, 5]) And
          (Cube[1, 2] = Cube[1, 8]) And
          (Cube[5, 8] = Cube[5, 5]) And
          (Cube[5, 8] = Cube[5, 2]) And
          (Cube[3, 8] = Cube[3, 5]) And
          (Cube[3, 8] = Cube[3, 2])) Then b := -1;
      End;
    3: Begin
        If Not ((Cube[0, 0] = Cube[0, 1]) And
          (Cube[0, 0] = Cube[0, 2]) And
          (Cube[2, 2] = Cube[2, 5]) And
          (Cube[2, 2] = Cube[2, 8]) And
          (Cube[5, 0] = Cube[5, 1]) And
          (Cube[5, 0] = Cube[5, 2]) And
          (Cube[4, 2] = Cube[4, 5]) And
          (Cube[4, 2] = Cube[4, 8])) Then b := -1;
      End;
    4: Begin
        If Not ((Cube[0, 0] = Cube[0, 3]) And
          (Cube[0, 0] = Cube[0, 6]) And
          (Cube[3, 0] = Cube[3, 3]) And
          (Cube[3, 0] = Cube[3, 6]) And
          (Cube[5, 0] = Cube[5, 3]) And
          (Cube[5, 0] = Cube[5, 6]) And
          (Cube[1, 0] = Cube[1, 3]) And
          (Cube[1, 0] = Cube[1, 6])) Then b := -1;
      End;
    5: Begin
        If Not ((Cube[1, 6] = Cube[1, 7]) And
          (Cube[1, 6] = Cube[1, 8]) And
          (Cube[2, 6] = Cube[2, 7]) And
          (Cube[2, 6] = Cube[2, 8]) And
          (Cube[3, 6] = Cube[3, 7]) And
          (Cube[3, 6] = Cube[3, 8]) And
          (Cube[4, 6] = Cube[4, 7]) And
          (Cube[4, 6] = Cube[4, 8])) Then b := -1;
      End;
  End;
  // Schauen ob die Ebene erst an die Mittelstücke angepasst werden muß !!
  Case b Of
    1: Begin
        If cube[0, 7] = Cube[2, 4] Then adddo(y1);
        If cube[0, 7] = Cube[5, 4] Then Begin
          adddo(y1);
          adddo(y1);
        End;
        If cube[0, 7] = Cube[4, 4] Then adddo(ym1);
      End;
    2: Begin
        If Cube[0, 5] = Cube[3, 4] Then
          adddo(xm3);
        If Cube[0, 5] = Cube[5, 4] Then Begin
          adddo(xm3);
          adddo(xm3);
        End;
        If Cube[0, 5] = Cube[1, 4] Then adddo(x3);
      End;
    3: Begin
        If Cube[0, 1] = Cube[4, 4] Then adddo(ym3);
        If Cube[0, 1] = Cube[5, 4] Then Begin
          adddo(ym3);
          adddo(ym3);
        End;
        If Cube[0, 1] = Cube[2, 4] Then adddo(y3);
      End;
    4: Begin
        If Cube[0, 3] = Cube[1, 4] Then adddo(x1);
        If Cube[0, 3] = Cube[5, 4] Then Begin
          adddo(x1);
          adddo(x1);
        End;
        If Cube[0, 3] = Cube[3, 4] Then adddo(xm1);
      End;
    5: Begin
        If Cube[1, 7] = Cube[2, 4] Then adddo(z3);
        If Cube[1, 7] = Cube[3, 4] Then Begin
          adddo(z3);
          adddo(z3);
        End;
        If Cube[1, 7] = Cube[4, 4] Then adddo(zm3);
      End;
  End;
  Case b Of
    1..5: Begin
        //        lStep := 0;
        Case b Of // hindrehen der Richtigen Ebene auf die Ebene 0
          1: Begin
              adddo(xm1);
              adddo(xm2);
              adddo(xm3);
            End;
          2: Begin
              adddo(ym1);
              adddo(ym2);
              adddo(ym3);
            End;
          3: Begin
              adddo(x1);
              adddo(x2);
              adddo(x3);
            End;
          4: Begin
              adddo(y1);
              adddo(y2);
              adddo(y3);
            End;
          5: Begin
              adddo(xm1);
              adddo(xm2);
              adddo(xm3);
              adddo(xm1);
              adddo(xm2);
              adddo(xm3);
            End;
        End;
      End;
  End;
  Optimize(ToDoList);
End;

// Hindrehen der Ersten Ebene ist Fertig, aber noch nicht 100 % ig getestet !!

Procedure MakeFirstLevel(Const Cube: TCube; Var ToDoList: TLtodo);

  Procedure AddToDo(jb: Tjob; Var cb: TCube);
  Begin
    setlength(ToDoList, high(ToDoList) + 2);
    ToDoList[high(ToDoList)] := jb;
    DoJob(jb, cb);
  End;

Label
  MacheKante0, MacheKante1, MacheKante2, MacheKante3,
    MacheEcke0, MacheEcke1, MacheEcke2, MacheEcke3;
Var
  B: TCube;
  x, y, i: Integer;
  r: Boolean;
Begin
  // Übertragen in zwischenspeicher
  For x := 0 To 5 Do
    For y := 0 To 8 Do
      b[x, y] := Cube[x, y];
  (* Übernehmen der bisherigen Dodoliste *)
  For i := 0 To high(ToDoList) Do Begin
    DoJob(ToDoList[i], b);
  End;
  (* Start mit dem Hin sortieren *)
  y := -1;
  // KI für die Erste EBENE
  // Kante 0
  MacheKante0:
  // Schauen ob der Block zufällig richtig liegt !!
  r := true;
  If b[0, 4] <> b[0, 1] Then r := false;
  If b[3, 4] <> b[3, 1] Then r := false;
  // Schauen ob der Block zufällig richtig liegt !!
  If Not R Then Begin // Die Kante ist noch nicht auf ihrem Platz und mus nun gesucht und hingebracht werden !!
    // Suchen der Position der Kante !!
    For x := 0 To 11 Do Begin
      If (b[Kanten[x].fx, Kanten[x].fy] = B[0, 4]) And
        (b[Kanten[x].sx, Kanten[x].sy] = B[3, 4]) Then Begin
        y := x;
      End;
      If (b[Kanten[x].fx, Kanten[x].fy] = B[3, 4]) And
        (b[Kanten[x].sx, Kanten[x].sy] = B[0, 4]) Then Begin
        y := X;
      End;
    End;
    // In y Steht die Kanten nummer der Gesuchten Kante
    Case Y Of
      0..3: Begin
          If b[0, 4] = b[Kanten[y].fx, Kanten[y].fy] Then Begin // die Kante ist schon Richtig mus nur noch hingedreht werden !!
            Case Y Of
              1: AddToDo(Z1, b);
              2: Begin
                  AddToDo(Z1, b);
                  AddToDo(Z1, b);
                End;
              3: AddToDo(Zm1, b);
            End;
          End
          Else Begin // Die Kante liegt oben mus aber erst noch gedreht werden !!
            Case Y Of // und wird gleichzeitig positioniert!!
              0: Begin
                  AddToDo(zm1, b);
                  AddToDo(xm3, b);
                  AddToDo(ym3, b);
                End;
              1: Begin
                  AddToDo(xm3, b);
                  AddToDo(ym3, b);
                End;
              2: Begin
                  AddToDo(zm1, b);
                  AddToDo(xm1, b);
                  AddToDo(y3, b);
                End;
              3: Begin
                  AddToDo(xm1, b);
                  AddToDo(y3, b);
                End;
            End;
          End;
        End;
      // Die Kanten werden nach oben gedreht und dann über einen Rausspring zu MacheKante0: erledigt !!
      4..11: Begin
          Case y Of
            4: AddToDo(y3, b);
            5: AddToDo(ym3, b);
            6: addtodo(xm3, b);
            7: AddToDo(xm1, b);
            8: Begin
                AddToDo(ym3, b);
                AddToDo(ym3, b);
              End;
            9: Begin
                AddToDo(x3, b);
                AddToDo(x3, b);
              End;
            10: Begin
                AddToDo(ym1, b);
                AddToDo(ym1, b);
              End;
            11: Begin
                AddToDo(x1, b);
                AddToDo(x1, b);
              End;
          End;
          Goto Machekante0;
        End;
    End;
  End;
  // Kante 0 Ende
  // Kante 1 Anfang
  MacheKante1:
  // Schauen ob der Block zufällig richtig liegt !!
  r := true;
  If b[0, 4] <> b[0, 5] Then r := false;
  If b[2, 4] <> b[2, 1] Then r := false;
  // Schauen ob der Block zufällig richtig liegt !!
  If Not R Then Begin // Die Kante ist noch nicht auf ihrem Platz und mus nun gesucht und hingebracht werden !!
    // Suchen der Position der Kante !!
    For x := 1 To 11 Do Begin
      If (b[Kanten[x].fx, Kanten[x].fy] = B[0, 4]) And
        (b[Kanten[x].sx, Kanten[x].sy] = B[2, 4]) Then Begin
        y := x;
      End;
      If (b[Kanten[x].fx, Kanten[x].fy] = B[2, 4]) And
        (b[Kanten[x].sx, Kanten[x].sy] = B[0, 4]) Then Begin
        y := X;
      End;
    End;
    // In y Steht die Kanten nummer der Gesuchten Kante
    Case Y Of
      1..3: Begin
          If b[Kanten[y].fx, Kanten[y].fy] = B[0, 4] Then Begin // Die Kante liegt richtig mus nur noch rübergedreht werden
            Case y Of
              2: Begin
                  AddToDo(Y1, b);
                  AddToDo(Y1, b);
                  AddToDo(Z3, b);
                  AddToDo(X3, b);
                  AddToDo(X3, b);
                End;
              3: Begin
                  AddToDo(x1, b);
                  AddToDo(Y1, b);
                  AddToDo(Y1, b);
                  AddToDo(Xm3, b);
                End;
            End;
          End
          Else Begin // Die Kante muß gekippt und gedreht werden
            Case y Of
              1: Begin
                  AddToDo(XM3, b);
                  AddToDo(Zm2, b);
                  AddToDo(xm3, b);
                  AddToDo(Z2, b);
                End;
              2: Begin
                  AddToDo(Y1, b);
                  AddToDo(Xm3, b);
                End;
              3: Begin
                  AddToDo(Zm2, b);
                  AddToDo(X1, b);
                  AddToDo(Z2, b);
                  AddToDo(Xm3, b);
                End;
            End;
          End;
        End;
      4..11: Begin // Kante liegt nicht in der Ersten Ebene -> wird hochgedreht und dann von Vorne mit Machekante1
          Case Y Of // Hochdrehen der Kanten auf 1, 2 oder 3
            4: Addtodo(X1, b);
            5: Addtodo(x3, b);
            6: Addtodo(Xm3, b);
            7: Addtodo(xm1, b);
            8: Begin
                Addtodo(ZM3, b);
                Addtodo(x3, b);
                Addtodo(x3, b);
              End;
            9: Begin
                Addtodo(x3, b);
                Addtodo(x3, b);
              End;
            10: Begin
                Addtodo(Z3, b);
                Addtodo(Z3, b);
              End;
            11: Begin
                Addtodo(X1, b);
                Addtodo(X1, b);
              End;
          End;
          Goto Machekante1;
        End;
    End;
  End;
  // Kante 1 Ende
  // Kante 2 Anfang
  MacheKante2:
  // Schauen ob der Block zufällig richtig liegt !!
  r := true;
  If b[0, 4] <> b[0, 7] Then r := false;
  If b[1, 4] <> b[1, 1] Then r := false;
  // Schauen ob der Block zufällig richtig liegt !!
  If Not R Then Begin // Die Kante ist noch nicht auf ihrem Platz und mus nun gesucht und hingebracht werden !!
    // Suchen der Position der Kante !!
    For x := 2 To 11 Do Begin
      If (b[Kanten[x].fx, Kanten[x].fy] = B[0, 4]) And
        (b[Kanten[x].sx, Kanten[x].sy] = B[1, 4]) Then Begin
        y := x;
      End;
      If (b[Kanten[x].fx, Kanten[x].fy] = B[1, 4]) And
        (b[Kanten[x].sx, Kanten[x].sy] = B[0, 4]) Then Begin
        y := X;
      End;
    End;
    // In y Steht die Kanten nummer der Gesuchten Kante
    Case Y Of
      2, 3: Begin // Die Kante ist schon oben
          Case Y Of
            2: Begin // Kante Liegt auf alle Fälle Falsch und mus gedreht werden !!
                Addtodo(ym1, b);
                Addtodo(zm1, b);
                Addtodo(xm1, b);
                Addtodo(Z1, b);
              End;
            3: Begin // Herausfinden ob die Kante Richtigliegt und handeln
                If b[Kanten[3].fx, Kanten[3].fy] = b[0, 4] Then Begin // Kante Liegt richtig mus nur reingedreht werden
                  Addtodo(X1, b);
                  Addtodo(Zm1, b);
                  Addtodo(Xm1, b);
                  Addtodo(Z1, b);
                End
                Else Begin // Kante mus reingedreht und gekippt werden
                  Addtodo(X1, b);
                  Addtodo(Y1, b);
                End;
              End;
          End;
        End;
      4..11: Begin // Die Kante ist irgendwo und wird hochgedreht auf Kante 2 oder 3 danach nochmal
          Case y Of
            4: Addtodo(x1, b);
            5: Begin
                Addtodo(Zm2, b);
                Addtodo(Ym1, b);
                Addtodo(Z2, b);
              End;
            6: Addtodo(Ym1, b);
            7: Addtodo(Y1, b);
            8: Begin
                Addtodo(zm3, b);
                Addtodo(zm3, b);
                Addtodo(Ym1, b);
                Addtodo(Ym1, b);
              End;
            9: Begin
                Addtodo(zm3, b);
                Addtodo(Ym1, b);
                Addtodo(Ym1, b);
              End;
            10: Begin
                Addtodo(Ym1, b);
                Addtodo(Ym1, b);
              End;
            11: Begin
                Addtodo(Z3, b);
                Addtodo(Ym1, b);
                Addtodo(Ym1, b);
              End;
          End;
          Goto macheKante2;
        End;
    End;
  End;
  // Kante 2 Ende
  // Kante 3 Anfang
  MacheKante3:
  // Schauen ob der Block zufällig richtig liegt !!
  r := true;
  If b[0, 4] <> b[0, 3] Then r := false;
  If b[4, 4] <> b[4, 1] Then r := false;
  // Schauen ob der Block zufällig richtig liegt !!
  If Not R Then Begin // Die Kante ist noch nicht auf ihrem Platz und mus nun gesucht und hingebracht werden !!
    // Suchen der Position der Kante !!
    For x := 3 To 11 Do Begin
      If (b[Kanten[x].fx, Kanten[x].fy] = B[0, 4]) And
        (b[Kanten[x].sx, Kanten[x].sy] = B[4, 4]) Then Begin
        y := x;
      End;
      If (b[Kanten[x].fx, Kanten[x].fy] = B[4, 4]) And
        (b[Kanten[x].sx, Kanten[x].sy] = B[0, 4]) Then Begin
        y := X;
      End;
    End;
    // In y Steht die Kanten nummer der Gesuchten Kante
    Case Y Of
      3: Begin // Ecke ist schon Richtig muß aber gekippt werden !!
          Addtodo(Z2, b);
          Addtodo(X1, b);
          Addtodo(Zm2, b);
          Addtodo(X1, b);
        End;
      4..11: Begin
          Case y Of
            4: Addtodo(X1, b);
            5: Begin
                Addtodo(z2, b);
                Addtodo(X1, b);
                Addtodo(Zm2, b);
              End;
            6: Begin
                Addtodo(zm2, b);
                Addtodo(Xm1, b);
                Addtodo(Z2, b);
              End;
            7: Addtodo(Xm1, b);
            8: Begin
                Addtodo(z3, b);
                Addtodo(x1, b);
                Addtodo(x1, b);
              End;
            9: Begin
                Addtodo(Z3, b);
                Addtodo(Z3, b);
                Addtodo(x1, b);
                Addtodo(x1, b);
              End;
            10: Begin
                Addtodo(Zm3, b);
                Addtodo(x1, b);
                Addtodo(x1, b);
              End;
            11: Begin
                Addtodo(x1, b);
                Addtodo(x1, b);
              End;
          End;
          Goto MacheKAnte3;
        End;
    End;
  End;
  // Kante 3 Ende
  // Ecke 0 Anfang
  MacheEcke0:
  // Schauen ob der Block zufällig richtig liegt !!
  r := true;
  If b[0, 4] <> b[0, 0] Then r := false;
  If b[3, 4] <> b[3, 0] Then r := false;
  If b[4, 4] <> b[4, 2] Then r := false;
  // Schauen ob der Block zufällig richtig liegt !!
  If Not R Then Begin // Die Kante ist noch nicht auf ihrem Platz und mus nun gesucht und hingebracht werden !!
    // Suchen der Position der Kante !!
    For x := 0 To 7 Do
      If Sametribble(b[ecken[x].fx, ecken[x].fy], b[ecken[x].sx, ecken[x].sy],
        b[ecken[x].tx, ecken[x].ty],
        b[0, 4], b[4, 4], b[3, 4]) Then Begin
        y := x;
        break;
      End;
    // In y Steht die Ecken nummer der Gesuchten Ecke
    Case Y Of
      0: Begin // Die Ecke liegt schon richtig muß aber gedreht werden !!
          If b[4, 2] = B[0, 4] Then Begin // zwei möglichkeiten wie die Ecke gekippt werden muß
            Addtodo(Xm1, b);
            Addtodo(Zm3, b);
            Addtodo(X1, b);
            Addtodo(Z3, b);
            Addtodo(Xm1, b);
            Addtodo(Zm3, b);
            Addtodo(X1, b);
          End
          Else Begin // zwei möglichkeiten wie die Ecke gekippt werden muß
            Addtodo(Xm1, b);
            Addtodo(Z3, b);
            Addtodo(X1, b);
            Addtodo(Zm3, b);
            Addtodo(Xm1, b);
            Addtodo(Z3, b);
            Addtodo(X1, b);
          End;
        End;
      1..7: Begin
          Case y Of // drehen der Ecke von EckeY in die ecke 0
            1: Begin
                Addtodo(xm3, b);
                Addtodo(xm1, b);
                Addtodo(Z3, b);
                Addtodo(X3, b);
                Addtodo(X1, b);
              End;
            2: Begin
                Addtodo(X3, b);
                Addtodo(Xm1, b);
                Addtodo(Z3, b);
                Addtodo(Z3, b);
                Addtodo(Xm3, b);
                Addtodo(X1, b);
              End;
            3: Begin
                Addtodo(x1, b);
                Addtodo(Z3, b);
                Addtodo(Xm1, b);
                Addtodo(Xm1, b);
                Addtodo(Z3, b);
                Addtodo(Z3, b);
                Addtodo(X1, b);
              End;
            4: Begin
                Addtodo(zm3, b);
                Addtodo(xm1, b);
                Addtodo(Z3, b);
                Addtodo(X1, b);
              End;
            5: Begin
                Addtodo(xm1, b);
                Addtodo(Z3, b);
                Addtodo(X1, b);
              End;
            6: Begin
                Addtodo(xm1, b);
                Addtodo(Z3, b);
                Addtodo(Z3, b);
                Addtodo(X1, b);
              End;
            7: Begin
                Addtodo(Z3, b);
                Addtodo(xm1, b);
                Addtodo(Z3, b);
                Addtodo(Z3, b);
                Addtodo(X1, b);
              End;
          End;
          Goto Macheecke0;
        End;
    End;
  End;
  // Ecke 0 Ende
  // Ecke 1 Anfang
  MacheEcke1:
  // Schauen ob der Block zufällig richtig liegt !!
  r := true;
  If b[0, 4] <> b[0, 2] Then r := false;
  If b[2, 4] <> b[2, 2] Then r := false;
  If b[3, 4] <> b[3, 2] Then r := false;
  // Schauen ob der Block zufällig richtig liegt !!
  If Not R Then Begin // Die Kante ist noch nicht auf ihrem Platz und mus nun gesucht und hingebracht werden !!
    // Suchen der Position der Kante !!
    For x := 1 To 7 Do
      If Sametribble(b[ecken[x].fx, ecken[x].fy], b[ecken[x].sx, ecken[x].sy],
        b[ecken[x].tx, ecken[x].ty],
        b[0, 4], b[2, 4], b[3, 4]) Then Begin
        y := x;
        break;
      End;
    // In y Steht die Ecken nummer der Gesuchten Ecke
    Case Y Of
      1: Begin // Die Ecke liegt richtig muß aber noch gedreht werden !!
          If b[3, 2] = b[0, 4] Then Begin // Zwei möglichkeiten wie die Ecke gedreht werden muß !!
            Addtodo(xm3, b);
            Addtodo(Zm3, b);
            Addtodo(X3, b);
            Addtodo(Z3, b);
            Addtodo(Xm3, b);
            Addtodo(Zm3, b);
            Addtodo(X3, b);
          End
          Else Begin // Zwei möglichkeiten wie die Ecke gedreht werden muß !!
            Addtodo(xm3, b);
            Addtodo(Z3, b);
            Addtodo(X3, b);
            Addtodo(Zm3, b);
            Addtodo(Xm3, b);
            Addtodo(Z3, b);
            Addtodo(X3, b);
          End;
        End;
      2..7: Begin
          Case y Of
            2: Begin
                Addtodo(X3, b);
                Addtodo(zm3, b);
                Addtodo(xm3, b);
                Addtodo(xm3, b);
                Addtodo(Z3, b);
                Addtodo(z3, b);
                Addtodo(X3, b);
              End;
            3: Begin
                Addtodo(x1, b);
                Addtodo(xm3, b);
                Addtodo(z3, b);
                Addtodo(z3, b);
                Addtodo(xm1, b);
                Addtodo(x3, b);
              End;
            4: Begin
                Addtodo(xm3, b);
                Addtodo(zm3, b);
                Addtodo(x3, b);
              End;
            5: Begin
                Addtodo(Z3, b);
                Addtodo(xm3, b);
                Addtodo(zm3, b);
                Addtodo(x3, b);
              End;
            6: Begin
                Addtodo(Z3, b);
                Addtodo(Z3, b);
                Addtodo(xm3, b);
                Addtodo(zm3, b);
                Addtodo(x3, b);
              End;
            7: Begin
                Addtodo(xm3, b);
                Addtodo(z3, b);
                Addtodo(z3, b);
                Addtodo(x3, b);
              End;
          End;
          Goto MacheEcke1;
        End;
    End;
  End;
  // Ecke 1 Ende
  // Ecke 2 Anfang
  MacheEcke2:
  // Schauen ob der Block zufällig richtig liegt !!
  r := true;
  If b[0, 4] <> b[0, 8] Then r := false;
  If b[2, 4] <> b[2, 0] Then r := false;
  If b[1, 4] <> b[1, 2] Then r := false;
  // Schauen ob der Block zufällig richtig liegt !!
  If Not R Then Begin // Die Kante ist noch nicht auf ihrem Platz und mus nun gesucht und hingebracht werden !!
    // Suchen der Position der Kante !!
    For x := 2 To 7 Do
      If Sametribble(b[ecken[x].fx, ecken[x].fy], b[ecken[x].sx, ecken[x].sy],
        b[ecken[x].tx, ecken[x].ty],
        b[0, 4], b[2, 4], b[1, 4]) Then Begin
        y := x;
        break;
      End;
    // In y Steht die Ecken nummer der Gesuchten Ecke
    Case y Of
      2: Begin // Ecke liegt richtig mus nur noch gekippt werden !!
          If b[0, 4] = b[2, 0] Then Begin // Zwei möglichkeiten wie gekippt werden muß
            Addtodo(x3, b);
            Addtodo(zm3, b);
            Addtodo(xm3, b);
            Addtodo(z3, b);
            Addtodo(X3, b);
            Addtodo(zm3, b);
            Addtodo(xm3, b);
          End
          Else Begin // Zwei möglichkeiten wie gekippt werden muß
            Addtodo(X3, b);
            Addtodo(Z3, b);
            Addtodo(xm3, b);
            Addtodo(zm3, b);
            Addtodo(x3, b);
            Addtodo(z3, b);
            Addtodo(xm3, b);
          End;
        End;
      3..7: Begin
          Case y Of
            3: Begin
                Addtodo(x1, b);
                Addtodo(x3, b);
                Addtodo(z3, b);
                Addtodo(xm1, b);
                Addtodo(xm3, b);
              End;
            4: Begin
                Addtodo(x3, b);
                Addtodo(z3, b);
                Addtodo(z3, b);
                Addtodo(xm3, b);
              End;
            5: Begin
                Addtodo(z3, b);
                Addtodo(x3, b);
                Addtodo(z3, b);
                Addtodo(z3, b);
                Addtodo(xm3, b);
              End;
            6: Begin
                Addtodo(zm3, b);
                Addtodo(x3, b);
                Addtodo(z3, b);
                Addtodo(xm3, b);
              End;
            7: Begin
                Addtodo(x3, b);
                Addtodo(z3, b);
                Addtodo(xm3, b);
              End;
          End;
          Goto MacheEcke2;
        End;
    End;
  End;
  // Ecke 2 Ende
  // Ecke 3 Anfang
  MacheEcke3:
  // Schauen ob der Block zufällig richtig liegt !!
  r := true;
  If b[0, 4] <> b[0, 6] Then r := false;
  If b[1, 4] <> b[1, 0] Then r := false;
  If b[4, 4] <> b[4, 0] Then r := false;
  // Schauen ob der Block zufällig richtig liegt !!
  If Not R Then Begin // Die Kante ist noch nicht auf ihrem Platz und mus nun gesucht und hingebracht werden !!
    // Suchen der Position der Kante !!
    For x := 3 To 7 Do
      If Sametribble(b[ecken[x].fx, ecken[x].fy], b[ecken[x].sx, ecken[x].sy],
        b[ecken[x].tx, ecken[x].ty],
        b[0, 4], b[4, 4], b[1, 4]) Then Begin
        y := x;
        break;
      End;
    // In y Steht die Ecken nummer der Gesuchten Ecke
    Case y Of
      3: Begin // Ecke liegt richtig wird nur noch geckippt
          If B[0, 4] = B[4, 0] Then Begin // es gibt zwei möglichkeiten die Ecke zu drehen
            Addtodo(x1, b);
            Addtodo(z3, b);
            Addtodo(xm1, b);
            Addtodo(zm3, b);
            Addtodo(x1, b);
            Addtodo(z3, b);
            Addtodo(xm1, b);
          End
          Else Begin // es gibt zwei möglichkeiten die Ecke zu drehen
            Addtodo(x1, b);
            Addtodo(zm3, b);
            Addtodo(xm1, b);
            Addtodo(z3, b);
            Addtodo(x1, b);
            Addtodo(zm3, b);
            Addtodo(xm1, b);
          End;
        End;
      4..7: Begin
          Case y Of
            4: Begin
                Addtodo(zm3, b);
                Addtodo(x1, b);
                Addtodo(zm3, b);
                Addtodo(zm3, b);
                Addtodo(xm1, b);
              End;
            5: Begin
                Addtodo(x1, b);
                Addtodo(zm3, b);
                Addtodo(zm3, b);
                Addtodo(xm1, b);
              End;
            6: Begin
                Addtodo(x1, b);
                Addtodo(zm3, b);
                Addtodo(xm1, b);
              End;
            7: Begin
                Addtodo(z3, b);
                Addtodo(x1, b);
                Addtodo(zm3, b);
                Addtodo(xm1, b);
              End;
          End;
          Goto macheecke3;
        End;
    End;
  End;
  // Ecke 3 Ende
  Optimize(ToDoList);
End;

// Hindrehen der Zweiten Ebene , Fertig !

Procedure MakeSecondLevel(Const Cube: TCube; Var ToDoList: TLtodo);

  Procedure AddToDo(jb: Tjob; Var cb: TCube);
  Begin
    setlength(ToDoList, high(ToDoList) + 2);
    ToDoList[high(ToDoList)] := jb;
    DoJob(jb, cb);
  End;

Label
  MacheKante4, MacheKante5, MacheKante6, MacheKante7;
Var
  B: TCube;
  i, x, y: Integer;
  r: Boolean;
  //  BLtodo: Tltodo;
Begin
  //  Setlength(bltodo, 0);
      // Übertragen in zwischenspeicher
  For x := 0 To 5 Do
    For y := 0 To 8 Do
      b[x, y] := Cube[x, y];
  (* Übernehmen der bisherigen Dodoliste *)
  For i := 0 To high(ToDoList) Do Begin
    DoJob(ToDoList[i], b);
  End;
  y := -1;
  // Kante 4 Anfang
  MacheKante4:
  // Schauen ob der Block zufällig richtig liegt !!
  r := true;
  If b[4, 4] <> b[4, 5] Then r := false;
  If b[3, 4] <> b[3, 3] Then r := false;
  // Schauen ob der Block zufällig richtig liegt !!
  If Not R Then Begin // Die Kante ist noch nicht auf ihrem Platz und mus nun gesucht und hingebracht werden !!
    // Suchen der Position der Kante !!
    For x := 4 To 11 Do Begin
      If (b[Kanten[x].fx, Kanten[x].fy] = B[3, 4]) And
        (b[Kanten[x].sx, Kanten[x].sy] = B[4, 4]) Then Begin
        y := x;
      End;
      If (b[Kanten[x].fx, Kanten[x].fy] = B[4, 4]) And
        (b[Kanten[x].sx, Kanten[x].sy] = B[3, 4]) Then Begin
        y := X;
      End;
    End;
    // In y Steht die Kanten nummer der Gesuchten Kante
    Case y Of
      4..7: Begin // Kante liegt auf der zweiten Ebene mus rausgedreht werden und wird dann wichtig verarbeitet !!
          Case y Of
            4: Begin
                Addtodo(z3, b);
                Addtodo(ym3, b);
                Addtodo(zm3, b);
                Addtodo(y3, b);
                Addtodo(zm3, b);
                Addtodo(xm1, b);
                Addtodo(z3, b);
                Addtodo(x1, b);
              End;
            5: Begin // Kante liegt auf der zweiten Ebene mus rausgedreht werden und wird dann wichtig verarbeitet !!
                Addtodo(zm3, b);
                Addtodo(y3, b);
                Addtodo(z3, b);
                Addtodo(ym3, b);
                Addtodo(z3, b);
                Addtodo(xm3, b);
                Addtodo(zm3, b);
                Addtodo(x3, b);
              End;
            6: Begin // Kante liegt auf der zweiten Ebene mus rausgedreht werden und wird dann wichtig verarbeitet !!
                Addtodo(zm3, b);
                Addtodo(x3, b);
                Addtodo(z3, b);
                Addtodo(xm3, b);
                Addtodo(z3, b);
                Addtodo(y1, b);
                Addtodo(zm3, b);
                Addtodo(ym1, b);
              End;
            7: Begin // Kante liegt auf der zweiten Ebene mus rausgedreht werden und wird dann wichtig verarbeitet !!
                Addtodo(z3, b);
                Addtodo(x1, b);
                Addtodo(zm3, b);
                Addtodo(xm1, b);
                Addtodo(zm3, b);
                Addtodo(ym1, b);
                Addtodo(z3, b);
                Addtodo(y1, b);
              End;
          End;
          Goto macheKante4;
        End;
      8: Begin // Es gibt immer zwei möglichkeiten die Kante reinzubringen, einmal drehen , oder direct hoch
          If B[4, 4] = b[3, 7] Then Begin // Ecke wirde auf Kante 11 Gedreht und hochgenommen
            Addtodo(z3, b);
            Addtodo(z3, b);
            Addtodo(ym3, b);
            Addtodo(zm3, b);
            Addtodo(y3, b);
            Addtodo(zm3, b);
            Addtodo(xm1, b);
            Addtodo(z3, b);
            Addtodo(x1, b);
          End
          Else Begin // Ecke kann direkt hochgebracht werden !!
            Addtodo(zm3, b);
            Addtodo(xm1, b);
            Addtodo(z3, b);
            Addtodo(x1, b);
            Addtodo(z3, b);
            Addtodo(ym3, b);
            Addtodo(zm3, b);
            Addtodo(y3, b);
          End;
        End;
      9: Begin
          If B[4, 4] = b[2, 7] Then Begin
            Addtodo(Zm3, b);
            Addtodo(ym3, b);
            Addtodo(zm3, b);
            Addtodo(y3, b);
            Addtodo(zm3, b);
            Addtodo(xm1, b);
            Addtodo(z3, b);
            Addtodo(x1, b);
          End
          Else Begin
            Addtodo(xm1, b);
            Addtodo(z3, b);
            Addtodo(x1, b);
            Addtodo(z3, b);
            Addtodo(ym3, b);
            Addtodo(zm3, b);
            Addtodo(y3, b);
          End;
        End;
      10: Begin
          If b[4, 4] = b[1, 7] Then Begin
            addtodo(ym3, b);
            addtodo(zm3, b);
            addtodo(y3, b);
            addtodo(zm3, b);
            addtodo(xm1, b);
            addtodo(z3, b);
            addtodo(x1, b);
          End
          Else Begin
            addtodo(z3, b);
            Addtodo(xm1, b);
            Addtodo(z3, b);
            Addtodo(x1, b);
            Addtodo(z3, b);
            Addtodo(ym3, b);
            Addtodo(zm3, b);
            Addtodo(y3, b);
          End;
        End;
      11: Begin
          If b[4, 4] = b[4, 7] Then Begin
            Addtodo(z3, b);
            Addtodo(ym3, b);
            Addtodo(zm3, b);
            Addtodo(y3, b);
            Addtodo(zm3, b);
            Addtodo(xm1, b);
            Addtodo(z3, b);
            Addtodo(x1, b);
          End
          Else Begin
            Addtodo(zm3, b);
            Addtodo(zm3, b);
            Addtodo(xm1, b);
            Addtodo(z3, b);
            Addtodo(x1, b);
            Addtodo(z3, b);
            Addtodo(ym3, b);
            Addtodo(zm3, b);
            Addtodo(y3, b);
          End;
        End;
    End;
  End;
  // Kante 4 Ende
  // Kante 5 Anfang
  MacheKante5:
  // Schauen ob der Block zufällig richtig liegt !!
  r := true;
  If b[2, 4] <> b[2, 5] Then r := false;
  If b[3, 4] <> b[3, 5] Then r := false;
  // Schauen ob der Block zufällig richtig liegt !!
  If Not R Then Begin // Die Kante ist noch nicht auf ihrem Platz und mus nun gesucht und hingebracht werden !!
    // Suchen der Position der Kante !!
    For x := 5 To 11 Do Begin
      If (b[Kanten[x].fx, Kanten[x].fy] = B[3, 4]) And
        (b[Kanten[x].sx, Kanten[x].sy] = B[2, 4]) Then Begin
        y := x;
      End;
      If (b[Kanten[x].fx, Kanten[x].fy] = B[2, 4]) And
        (b[Kanten[x].sx, Kanten[x].sy] = B[3, 4]) Then Begin
        y := X;
      End;
    End;
    // In y Steht die Kanten nummer der Gesuchten Kante
    Case y Of
      5..7: Begin // Rausdrehen der Kante auf die 3. Ebene
          Case y Of
            5: Begin
                Addtodo(y3, b);
                Addtodo(z3, b);
                Addtodo(ym3, b);
                Addtodo(z3, b);
                Addtodo(xm3, b);
                Addtodo(zm3, b);
                Addtodo(x3, b);
              End;
            6: Begin
                Addtodo(y1, b);
                Addtodo(zm3, b);
                Addtodo(ym1, b);
                Addtodo(zm3, b);
                Addtodo(x3, b);
                Addtodo(z3, b);
                Addtodo(xm3, b);
              End;
            7: Begin
                Addtodo(x1, b);
                Addtodo(zm3, b);
                Addtodo(xm1, b);
                Addtodo(zm3, b);
                Addtodo(ym1, b);
                Addtodo(z3, b);
                Addtodo(y1, b);
              End;
          End;
          Goto MacheKante5;
        End;
      8: Begin // Es gibt immer zwei möglichkeiten die Kante reinzubringen, einmal drehen , oder direct hoch
          If B[3, 4] = b[3, 7] Then Begin
            addtodo(Z3, b);
            addtodo(xm3, b);
            addtodo(zm3, b);
            addtodo(x3, b);
            addtodo(zm3, b);
            addtodo(Y3, b);
            addtodo(z3, b);
            addtodo(Ym3, b);
          End
          Else Begin
            addtodo(zm3, b);
            addtodo(zm3, b);
            addtodo(y3, b);
            addtodo(z3, b);
            addtodo(ym3, b);
            addtodo(z3, b);
            addtodo(xm3, b);
            addtodo(zm3, b);
            addtodo(x3, b);
          End;
        End;
      9: Begin
          If b[3, 4] = b[2, 7] Then Begin
            addtodo(Z3, b);
            addtodo(Z3, b);
            addtodo(xm3, b);
            addtodo(zm3, b);
            addtodo(x3, b);
            addtodo(zm3, b);
            addtodo(Y3, b);
            addtodo(z3, b);
            addtodo(Ym3, b);
          End
          Else Begin
            addtodo(zm3, b);
            addtodo(y3, b);
            addtodo(z3, b);
            addtodo(ym3, b);
            addtodo(z3, b);
            addtodo(xm3, b);
            addtodo(zm3, b);
            addtodo(x3, b);
          End;
        End;
      10: Begin
          If b[3, 4] = B[1, 7] Then Begin
            addtodo(Zm3, b);
            addtodo(xm3, b);
            addtodo(zm3, b);
            addtodo(x3, b);
            addtodo(zm3, b);
            addtodo(Y3, b);
            addtodo(z3, b);
            addtodo(Ym3, b);
          End
          Else Begin
            addtodo(y3, b);
            addtodo(z3, b);
            addtodo(ym3, b);
            addtodo(z3, b);
            addtodo(xm3, b);
            addtodo(zm3, b);
            addtodo(x3, b);
          End;
        End;
      11: Begin
          If B[3, 4] = B[4, 7] Then Begin
            addtodo(xm3, b);
            addtodo(zm3, b);
            addtodo(x3, b);
            addtodo(zm3, b);
            addtodo(Y3, b);
            addtodo(z3, b);
            addtodo(Ym3, b);
          End
          Else Begin
            addtodo(z3, b);
            addtodo(y3, b);
            addtodo(z3, b);
            addtodo(ym3, b);
            addtodo(z3, b);
            addtodo(xm3, b);
            addtodo(zm3, b);
            addtodo(x3, b);
          End;
        End;
    End;
  End;
  // Kante 5 Ende
  // Kante 6 Anfang
  MacheKante6:
  // Schauen ob der Block zufällig richtig liegt !!
  r := true;
  If b[2, 4] <> b[2, 3] Then r := false;
  If b[1, 4] <> b[1, 5] Then r := false;
  // Schauen ob der Block zufällig richtig liegt !!
  If Not R Then Begin // Die Kante ist noch nicht auf ihrem Platz und mus nun gesucht und hingebracht werden !!
    // Suchen der Position der Kante !!
    For x := 6 To 11 Do Begin
      If (b[Kanten[x].fx, Kanten[x].fy] = B[1, 4]) And
        (b[Kanten[x].sx, Kanten[x].sy] = B[2, 4]) Then Begin
        y := x;
      End;
      If (b[Kanten[x].fx, Kanten[x].fy] = B[2, 4]) And
        (b[Kanten[x].sx, Kanten[x].sy] = B[1, 4]) Then Begin
        y := X;
      End;
    End;
    // In y Steht die Kanten nummer der Gesuchten Kante
    Case y Of
      6, 7: Begin
          Case y Of // Rausdrehen der Kante auf die 3. Ebene
            6: Begin
                addtodo(x3, b);
                addtodo(z3, b);
                addtodo(xm3, b);
                addtodo(z3, b);
                addtodo(y1, b);
                addtodo(zm3, b);
                addtodo(ym1, b);
              End;
            7: Begin
                addtodo(x1, b);
                addtodo(zm3, b);
                addtodo(xm1, b);
                addtodo(zm3, b);
                addtodo(ym1, b);
                addtodo(z3, b);
                addtodo(y1, b);
              End;
          End;
          Goto machekante6;
        End;
      8: Begin
          If B[2, 4] = b[3, 7] Then Begin
            addtodo(y1, b);
            addtodo(zm3, b);
            addtodo(ym1, b);
            addtodo(zm3, b);
            addtodo(x3, b);
            addtodo(z3, b);
            addtodo(xm3, b);
          End
          Else Begin
            addtodo(z3, b);
            addtodo(x3, b);
            addtodo(z3, b);
            addtodo(xm3, b);
            addtodo(z3, b);
            addtodo(y1, b);
            addtodo(zm3, b);
            addtodo(ym1, b);
          End;
        End;
      9: Begin
          If b[2, 4] = b[2, 7] Then Begin
            addtodo(z3, b);
            addtodo(y1, b);
            addtodo(zm3, b);
            addtodo(ym1, b);
            addtodo(zm3, b);
            addtodo(x3, b);
            addtodo(z3, b);
            addtodo(xm3, b);
          End
          Else Begin
            addtodo(zm3, b);
            addtodo(zm3, b);
            addtodo(x3, b);
            addtodo(z3, b);
            addtodo(xm3, b);
            addtodo(z3, b);
            addtodo(y1, b);
            addtodo(zm3, b);
            addtodo(ym1, b);
          End;
        End;
      10: Begin
          If b[2, 4] = b[1, 7] Then Begin
            addtodo(z3, b);
            addtodo(z3, b);
            addtodo(y1, b);
            addtodo(zm3, b);
            addtodo(ym1, b);
            addtodo(zm3, b);
            addtodo(x3, b);
            addtodo(z3, b);
            addtodo(xm3, b);
          End
          Else Begin
            addtodo(zm3, b);
            addtodo(x3, b);
            addtodo(z3, b);
            addtodo(xm3, b);
            addtodo(z3, b);
            addtodo(y1, b);
            addtodo(zm3, b);
            addtodo(ym1, b);
          End;
        End;
      11: Begin
          If b[2, 4] = b[4, 7] Then Begin
            addtodo(zm3, b);
            addtodo(y1, b);
            addtodo(zm3, b);
            addtodo(ym1, b);
            addtodo(zm3, b);
            addtodo(x3, b);
            addtodo(z3, b);
            addtodo(xm3, b);
          End
          Else Begin
            addtodo(x3, b);
            addtodo(z3, b);
            addtodo(xm3, b);
            addtodo(z3, b);
            addtodo(y1, b);
            addtodo(zm3, b);
            addtodo(ym1, b);
          End;
        End;
    End;
  End;
  // Kante 6 Ende
  // Kante 7 Anfang
  MacheKante7:
  // Schauen ob der Block zufällig richtig liegt !!
  r := true;
  If b[1, 4] <> b[1, 3] Then r := false;
  If b[4, 4] <> b[4, 3] Then r := false;
  // Schauen ob der Block zufällig richtig liegt !!
  If Not R Then Begin // Die Kante ist noch nicht auf ihrem Platz und mus nun gesucht und hingebracht werden !!
    // Suchen der Position der Kante !!
    For x := 7 To 11 Do Begin
      If (b[Kanten[x].fx, Kanten[x].fy] = B[1, 4]) And
        (b[Kanten[x].sx, Kanten[x].sy] = B[4, 4]) Then Begin
        y := x;
      End;
      If (b[Kanten[x].fx, Kanten[x].fy] = B[4, 4]) And
        (b[Kanten[x].sx, Kanten[x].sy] = B[1, 4]) Then Begin
        y := X;
      End;
    End;
    // In y Steht die Kanten nummer der Gesuchten Kante
    Case y Of
      7: Begin // Rausdrehen in die 3. Ebene
          Addtodo(zm3, b);
          Addtodo(ym1, b);
          Addtodo(z3, b);
          Addtodo(y1, b);
          Addtodo(z3, b);
          Addtodo(x1, b);
          Addtodo(zm3, b);
          Addtodo(xm1, b);
          Goto machekante7;
        End;
      8: Begin
          If b[1, 4] = b[3, 7] Then Begin
            Addtodo(zm3, b);
            Addtodo(x1, b);
            Addtodo(zm3, b);
            Addtodo(xm1, b);
            Addtodo(zm3, b);
            Addtodo(ym1, b);
            Addtodo(z3, b);
            Addtodo(y1, b);
          End
          Else Begin
            Addtodo(ym1, b);
            Addtodo(z3, b);
            Addtodo(y1, b);
            Addtodo(z3, b);
            Addtodo(x1, b);
            Addtodo(zm3, b);
            Addtodo(xm1, b);
          End;
        End;
      9: Begin
          If b[1, 4] = B[2, 7] Then Begin
            Addtodo(x1, b);
            Addtodo(zm3, b);
            Addtodo(xm1, b);
            Addtodo(zm3, b);
            Addtodo(ym1, b);
            Addtodo(z3, b);
            Addtodo(y1, b);
          End
          Else Begin
            Addtodo(z3, b);
            Addtodo(ym1, b);
            Addtodo(z3, b);
            Addtodo(y1, b);
            Addtodo(z3, b);
            Addtodo(x1, b);
            Addtodo(zm3, b);
            Addtodo(xm1, b);
          End;
        End;
      10: Begin
          If B[1, 4] = b[1, 7] Then Begin
            Addtodo(z3, b);
            Addtodo(x1, b);
            Addtodo(zm3, b);
            Addtodo(xm1, b);
            Addtodo(zm3, b);
            Addtodo(ym1, b);
            Addtodo(z3, b);
            Addtodo(y1, b);
          End
          Else Begin
            Addtodo(z3, b);
            Addtodo(z3, b);
            Addtodo(ym1, b);
            Addtodo(z3, b);
            Addtodo(y1, b);
            Addtodo(z3, b);
            Addtodo(x1, b);
            Addtodo(zm3, b);
            Addtodo(xm1, b);
          End;
        End;
      11: Begin
          If b[1, 4] = b[4, 7] Then Begin
            addtodo(zm3, b);
            Addtodo(zm3, b);
            Addtodo(x1, b);
            Addtodo(zm3, b);
            Addtodo(xm1, b);
            Addtodo(zm3, b);
            Addtodo(ym1, b);
            Addtodo(z3, b);
            Addtodo(y1, b);
          End
          Else Begin
            addtodo(zm3, b);
            Addtodo(ym1, b);
            Addtodo(z3, b);
            Addtodo(y1, b);
            Addtodo(z3, b);
            Addtodo(x1, b);
            Addtodo(zm3, b);
            Addtodo(xm1, b);
          End;
        End;
    End;
  End;
  // Kante 7 Ende
  Optimize(ToDoList);
End;

// Hindrehen der Dritten Ebene , Fertig !

Procedure MakeThirdLevel(Const Cube: TCube; Var ToDoList: TLtodo);
  Procedure AddToDo(jb: Tjob; Var cb: TCube);
  Begin
    setlength(ToDoList, high(ToDoList) + 2);
    ToDoList[high(ToDoList)] := jb;
    DoJob(jb, cb);
  End;

Label
  MacheKanten, KantenKippen, MacheEcken;
Var
  B: TCube;
  i, x, y: Integer;
  pk8, pk9, pk10, pk11: 8..12;
  pe4, pe5, pe6, pe7: 4..8;
  k8r, k9r, k10r, k11r: Boolean;
  e4r, e5r, e6r, e7r: 1..3;
Begin
  // Übertragen in zwischenspeicher
  For x := 0 To 5 Do
    For y := 0 To 8 Do
      b[x, y] := Cube[x, y];
  (* Übernehmen der bisherigen Dodoliste *)
  For i := 0 To high(ToDoList) Do Begin
    DoJob(ToDoList[i], b);
  End;
  pk8 := 12;
  pk9 := 12;
  pk10 := 12;
  pk11 := 12;
  Machekanten:
  // Die Dritte Ebene ist ein klein wenig schwieriger !! sie hat leider 256 Möglichkeiten die müssen intelligent gelöst werden !!
  // Zuerst werden die positionen der 4 Kanten gesucht !!!
  For x := 8 To 11 Do Begin
    // Position von kante 8
    If (b[Kanten[x].fx, Kanten[x].fy] = B[5, 4]) And (b[Kanten[x].sx, Kanten[x].sy] = B[3, 4]) Then pk8 := x;
    If (b[Kanten[x].fx, Kanten[x].fy] = B[3, 4]) And (b[Kanten[x].sx, Kanten[x].sy] = B[5, 4]) Then pk8 := X;
    // Position von kante 9
    If (b[Kanten[x].fx, Kanten[x].fy] = B[5, 4]) And (b[Kanten[x].sx, Kanten[x].sy] = B[2, 4]) Then pk9 := x;
    If (b[Kanten[x].fx, Kanten[x].fy] = B[2, 4]) And (b[Kanten[x].sx, Kanten[x].sy] = B[5, 4]) Then pk9 := X;
    // Position von kante 10
    If (b[Kanten[x].fx, Kanten[x].fy] = B[5, 4]) And (b[Kanten[x].sx, Kanten[x].sy] = B[1, 4]) Then pk10 := x;
    If (b[Kanten[x].fx, Kanten[x].fy] = B[1, 4]) And (b[Kanten[x].sx, Kanten[x].sy] = B[5, 4]) Then pk10 := X;
    // Position von kante 11
    If (b[Kanten[x].fx, Kanten[x].fy] = B[5, 4]) And (b[Kanten[x].sx, Kanten[x].sy] = B[4, 4]) Then pk11 := x;
    If (b[Kanten[x].fx, Kanten[x].fy] = B[4, 4]) And (b[Kanten[x].sx, Kanten[x].sy] = B[5, 4]) Then pk11 := X;
  End;
  // Zuerst werden die positionen der 4 Kanten gesucht !!!
  // nun müssen diese Intelligent hingedreht werden !!
  // Erst mal schauen ob vielleicht durch einen kleinen Dreh eine oder mehr als eine Kante richtig gestellt werden kann !!
  If (pk8 <> 8) And (pk9 <> 9) And (pk10 <> 10) And (pk11 <> 11) Then Begin
    If (PK8 = 9) And (pk9 = 10) Then Begin
      Addtodo(z3, b);
      Goto macheKanten;
    End;
    If (PK8 = 10) And (pk9 = 11) Then Begin
      Addtodo(z3, b);
      Addtodo(z3, b);
      Goto macheKanten;
    End;
    If (PK9 = 10) And (pk10 = 11) Then Begin
      Addtodo(z3, b);
      Goto macheKanten;
    End;
    If (PK9 = 11) And (pk10 = 8) Then Begin
      Addtodo(z3, b);
      Addtodo(z3, b);
      Goto macheKanten;
    End;
    If (PK10 = 11) And (pk11 = 8) Then Begin
      Addtodo(z3, b);
      Goto macheKanten;
    End;
    If (PK10 = 8) And (pk11 = 9) Then Begin
      Addtodo(z3, b);
      Addtodo(z3, b);
      Goto macheKanten;
    End;
    // Wenn gar nicths der Oberen anspricht dann wird der Cube einfach eins weitergedreht, spätestens das stellt irgendwann eine Kante Richtig !!
    addtodo(zm3, b);
    Goto macheKanten;
  End;
  If pk8 = 8 Then Begin
    If (pk9 <> 9) And (pk10 <> 10) And (pk11 <> 11) Then Begin
      // Rotieren kante 9,10,11 , Fertig !
      If Pk9 = 10 Then Begin // Rotieren der drei , so das 10 -> 9 , Fertig !
        addtodo(xm2, b);
        addtodo(z3, b);
        addtodo(x2, b);
        addtodo(z3, b);
        addtodo(z3, b);
        addtodo(xm2, b);
        addtodo(z3, b);
        addtodo(x2, b);
      End
      Else Begin // Rotieren der drei , so das 11 -> 9 , Fertig !
        addtodo(xm2, b);
        addtodo(zm3, b);
        addtodo(x2, b);
        addtodo(zm3, b);
        addtodo(zm3, b);
        addtodo(xm2, b);
        addtodo(zm3, b);
        addtodo(x2, b);
      End;
      Goto macheKanten;
    End;
    If (Pk9 = 9) And (pk10 <> 10) Then Begin
      // Tauschen 10,11 , Fertig !
      addtodo(z3, b);
      addtodo(x1, b);
      addtodo(ym3, b);
      addtodo(z3, b);
      addtodo(y3, b);
      addtodo(zm3, b);
      addtodo(xm1, b);
      Goto macheKanten;
    End;
    If (Pk10 = 10) And (pk9 <> 9) Then Begin
      // Tauschen 9,11 , Fertig !
      addtodo(xm2, b);
      addtodo(z3, b);
      addtodo(x2, b);
      addtodo(z3, b);
      addtodo(z3, b);
      addtodo(xm2, b);
      addtodo(z3, b);
      addtodo(x2, b);
      addtodo(z3, b);
      addtodo(y1, b);
      addtodo(x1, b);
      addtodo(z3, b);
      addtodo(xm1, b);
      addtodo(zm3, b);
      addtodo(ym1, b);
      Goto macheKanten;
    End;
    If (Pk11 = 11) And (pk10 <> 10) Then Begin
      // Tauschen 10,9 , Fertig !
      addtodo(z3, b);
      addtodo(y1, b);
      addtodo(x1, b);
      addtodo(z3, b);
      addtodo(xm1, b);
      addtodo(zm3, b);
      addtodo(ym1, b);
      Goto macheKanten;
    End;
  End;
  If pk9 = 9 Then Begin
    If (pk8 <> 8) And (pk10 <> 10) And (pk11 <> 11) Then Begin
      // Rotieren kante 8,10,11 , Fertig !
      If Pk8 = 10 Then Begin
        // Rotieren der drei , so das 10 -> 8 , Fertig !
        addtodo(y2, b);
        addtodo(z3, b);
        addtodo(ym2, b);
        addtodo(z3, b);
        addtodo(z3, b);
        addtodo(y2, b);
        addtodo(z3, b);
        addtodo(ym2, b);
      End
      Else Begin
        // Rotieren der drei , so das 11 -> 8 , Fertig !
        addtodo(y2, b);
        addtodo(zm3, b);
        addtodo(ym2, b);
        addtodo(zm3, b);
        addtodo(zm3, b);
        addtodo(y2, b);
        addtodo(zm3, b);
        addtodo(ym2, b);
      End;
      Goto macheKanten;
    End;
    If (Pk10 = 10) And (pk8 <> 8) Then Begin
      // Tauschen 8,11 , Ferig !
      addtodo(z3, b);
      addtodo(ym3, b);
      addtodo(xm3, b);
      addtodo(z3, b);
      addtodo(x3, b);
      addtodo(zm3, b);
      addtodo(y3, b);
      Goto macheKanten;
    End;
    If (Pk11 = 11) And ((pk10 <> 10)) Then Begin
      // Tauschen 10,8 , Fertig !
      addtodo(y2, b);
      addtodo(zm3, b);
      addtodo(ym2, b);
      addtodo(zm3, b);
      addtodo(zm3, b);
      addtodo(y2, b);
      addtodo(zm3, b);
      addtodo(ym2, b);
      addtodo(z3, b);
      addtodo(ym3, b);
      addtodo(xm3, b);
      addtodo(z3, b);
      addtodo(x3, b);
      addtodo(zm3, b);
      addtodo(y3, b);
      Goto macheKanten;
    End;
  End;
  If pk10 = 10 Then Begin
    If (pk8 <> 8) And (pk9 <> 9) And (pk11 <> 11) Then Begin
      // Rotieren kante 8,9,11 , Fertig !
      If Pk8 = 9 Then Begin
        // Rotieren der drei , so das 9 -> 8 , Fertig !
        Addtodo(x2, b);
        Addtodo(z3, b);
        Addtodo(xm2, b);
        Addtodo(z3, b);
        Addtodo(z3, b);
        Addtodo(x2, b);
        Addtodo(z3, b);
        Addtodo(xm2, b);
      End
      Else Begin
        // Rotieren der drei , so das 11 -> 8 , Fertig !
        Addtodo(x2, b);
        Addtodo(zm3, b);
        Addtodo(xm2, b);
        Addtodo(zm3, b);
        Addtodo(zm3, b);
        Addtodo(x2, b);
        Addtodo(zm3, b);
        Addtodo(xm2, b);
      End;
      Goto macheKanten;
    End;
    If (PK11 = 11) And (pk8 <> 8) Then Begin
      // Tauschen 8,9 , Fertig !
      Addtodo(z3, b);
      Addtodo(xm3, b);
      Addtodo(y1, b);
      Addtodo(z3, b);
      Addtodo(ym1, b);
      Addtodo(zm3, b);
      Addtodo(x3, b);
      Goto macheKanten;
    End;
  End;
  If pk11 = 11 Then Begin
    If (pk8 <> 8) And (pk9 <> 9) And (pk10 <> 10) Then Begin
      // Rotieren kante 8,9,10 , Fertig !
      If pk8 = 9 Then Begin
        // Rotieren der drei , so das 9 -> 8 , Fertig !
        Addtodo(ym2, b);
        Addtodo(z3, b);
        Addtodo(y2, b);
        Addtodo(z3, b);
        Addtodo(z3, b);
        Addtodo(ym2, b);
        Addtodo(z3, b);
        Addtodo(y2, b);
      End
      Else Begin
        // Rotieren der drei , so das 10 -> 8 , Feritg !
        Addtodo(ym2, b);
        Addtodo(zm3, b);
        Addtodo(y2, b);
        Addtodo(zm3, b);
        Addtodo(zm3, b);
        Addtodo(ym2, b);
        Addtodo(zm3, b);
        Addtodo(y2, b);
      End;
      Goto macheKanten;
    End;
  End;
  // Ab hier sind alle Kannten Richtig !!
  // Nun müssen die Kanten gekippt werden !!
  KantenKippen:
  k8r := Not (b[3, 7] = b[3, 4]); // Wenn True dann muß gekippt werden !!
  k9r := Not (b[2, 7] = b[2, 4]); // Wenn True dann muß gekippt werden !!
  k10r := Not (b[1, 7] = b[1, 4]); // Wenn True dann muß gekippt werden !!
  k11r := Not (b[4, 7] = b[4, 4]); // Wenn True dann muß gekippt werden !!
  If k8r Then Begin // anfagnen des drehens mit k8r
    addtodo(ym3, b);
    addtodo(zm2, b);
    addtodo(ym3, b);
    addtodo(zm2, b);
    addtodo(ym3, b);
    addtodo(zm2, b);
    addtodo(ym3, b);
    addtodo(zm2, b);
    Goto KantenKippen;
  End;
  If k9r Then Begin // anfagnen des drehens mit k9r
    //Drehen so das k9 auf k8 und dann korrigieren danach wieder zurückdrehen
    addtodo(z3, b);
    addtodo(ym3, b);
    addtodo(zm2, b);
    addtodo(ym3, b);
    addtodo(zm2, b);
    addtodo(ym3, b);
    addtodo(zm2, b);
    addtodo(ym3, b);
    addtodo(zm2, b);
    addtodo(zm3, b);
    Goto KantenKippen;
  End;
  If k10r Then Begin // anfagnen des drehens mit k10r
    //Drehen so das k10 auf k8 und dann korrigieren danach wieder zurückdrehen
    addtodo(z3, b);
    addtodo(z3, b);
    addtodo(ym3, b);
    addtodo(zm2, b);
    addtodo(ym3, b);
    addtodo(zm2, b);
    addtodo(ym3, b);
    addtodo(zm2, b);
    addtodo(ym3, b);
    addtodo(zm2, b);
    addtodo(zm3, b);
    addtodo(zm3, b);
    Goto KantenKippen;
  End;
  If k11r Then Begin // anfangen des drehens mit k10r
    //Drehen so das k11 auf k8 und dann korrigieren danach wieder zurückdrehen
    addtodo(zm3, b);
    addtodo(ym3, b);
    addtodo(zm2, b);
    addtodo(ym3, b);
    addtodo(zm2, b);
    addtodo(ym3, b);
    addtodo(zm2, b);
    addtodo(ym3, b);
    addtodo(zm2, b);
    addtodo(z3, b);
    Goto KantenKippen;
  End;
  // Suchen wo K8 und dann hindrehen des unteren Ringes mit Z3 oder Zm3 so das alle Kanten Stimmen !!!
  For x := 8 To 11 Do Begin
    // Position von kante 8
    If (b[Kanten[x].fx, Kanten[x].fy] = B[5, 4]) And (b[Kanten[x].sx, Kanten[x].sy] = B[3, 4]) Then pk8 := x;
    If (b[Kanten[x].fx, Kanten[x].fy] = B[3, 4]) And (b[Kanten[x].sx, Kanten[x].sy] = B[5, 4]) Then pk8 := X;
  End;
  Case pk8 Of
    9: addtodo(z3, b);
    10: Begin
        addtodo(zm3, b);
        addtodo(zm3, b);
      End;
    11: addtodo(zm3, b);
  End;
  // Nun müssen die Ecken an ihre Plätze geraten !!
  // Als erstes Herausfinden wo die Ecken gerade sind !!
  MacheEcken:
  pe4 := 8;
  pe5 := 8;
  pe6 := 8;
  pe7 := 8;
  For x := 4 To 7 Do Begin
    If Sametribble(b[ecken[x].fx, ecken[x].fy], b[ecken[x].sx, ecken[x].sy], b[ecken[x].tx, ecken[x].ty],
      b[4, 4], b[3, 4], b[5, 4]) Then
      pe4 := x;
    If Sametribble(b[ecken[x].fx, ecken[x].fy], b[ecken[x].sx, ecken[x].sy], b[ecken[x].tx, ecken[x].ty],
      b[3, 4], b[2, 4], b[5, 4]) Then
      pe5 := x;
    If Sametribble(b[ecken[x].fx, ecken[x].fy], b[ecken[x].sx, ecken[x].sy], b[ecken[x].tx, ecken[x].ty],
      b[2, 4], b[1, 4], b[5, 4]) Then
      pe6 := x;
    If Sametribble(b[ecken[x].fx, ecken[x].fy], b[ecken[x].sx, ecken[x].sy], b[ecken[x].tx, ecken[x].ty],
      b[1, 4], b[4, 4], b[5, 4]) Then
      pe7 := x;
  End;
  If Pe4 <> 4 Then
    Case pe4 Of
      5: Begin
          If Pe7 <> 7 Then Begin
            // Rotieren Ecke 4,5,7 so das 5 - > 4 , Fertig !
            addtodo(x1, b);
            addtodo(zm1, b);
            addtodo(x1, b);
            addtodo(x1, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(x1, b);
            addtodo(x1, b);
            addtodo(z1, b);
            addtodo(xm1, b);
            addtodo(z3, b);
            addtodo(x1, b);
            addtodo(zm1, b);
            addtodo(x1, b);
            addtodo(x1, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(x1, b);
            addtodo(x1, b);
            addtodo(z1, b);
            addtodo(xm1, b);
            addtodo(zm3, b);
          End
          Else Begin
            // Rotieren Ecke 4,5,6 so das 5 - > 4 , Fertig !
            Addtodo(ym3, b);
            Addtodo(zm1, b);
            Addtodo(ym3, b);
            Addtodo(ym3, b);
            Addtodo(zm1, b);
            Addtodo(zm1, b);
            Addtodo(ym3, b);
            Addtodo(ym3, b);
            Addtodo(z1, b);
            Addtodo(y3, b);
            Addtodo(z3, b);
            Addtodo(ym3, b);
            Addtodo(zm1, b);
            Addtodo(ym3, b);
            Addtodo(ym3, b);
            Addtodo(zm1, b);
            Addtodo(zm1, b);
            Addtodo(ym3, b);
            Addtodo(ym3, b);
            Addtodo(z1, b);
            Addtodo(y3, b);
            Addtodo(zm3, b);
          End;
          Goto macheEcken;
        End;
      6: Begin
          If Pe7 <> 7 Then Begin
            // Rotieren Ecke 4,7,6 so das 6 - > 4 , Fertig !
            addtodo(y1, b);
            addtodo(zm1, b);
            addtodo(y1, b);
            addtodo(y1, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(y1, b);
            addtodo(y1, b);
            addtodo(z1, b);
            addtodo(ym1, b);
            addtodo(z3, b);
            addtodo(y1, b);
            addtodo(zm1, b);
            addtodo(y1, b);
            addtodo(y1, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(y1, b);
            addtodo(y1, b);
            addtodo(z1, b);
            addtodo(ym1, b);
            addtodo(zm3, b);
          End
          Else Begin
            // Rotieren Ecke 4,6,5 so das 6 - > 4 , Fertig !
            addtodo(z3, b);
            addtodo(ym3, b);
            addtodo(zm1, b);
            addtodo(ym3, b);
            addtodo(ym3, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(ym3, b);
            addtodo(ym3, b);
            addtodo(z1, b);
            addtodo(y3, b);
            addtodo(zm3, b);
            addtodo(ym3, b);
            addtodo(zm1, b);
            addtodo(ym3, b);
            addtodo(ym3, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(ym3, b);
            addtodo(ym3, b);
            addtodo(z1, b);
            addtodo(y3, b);
          End;
          Goto MacheEcken;
        End;
      7: Begin
          If Pe6 <> 6 Then Begin
            // Rotieren Ecke 4,6,7 so das 7 -> 4 , Fertig !
            addtodo(z3, b);
            addtodo(y1, b);
            addtodo(zm1, b);
            addtodo(y1, b);
            addtodo(y1, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(y1, b);
            addtodo(y1, b);
            addtodo(z1, b);
            addtodo(ym1, b);
            addtodo(zm3, b);
            addtodo(y1, b);
            addtodo(zm1, b);
            addtodo(y1, b);
            addtodo(y1, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(y1, b);
            addtodo(y1, b);
            addtodo(z1, b);
            addtodo(ym1, b);
          End
          Else Begin
            // Rotieren Ecke 4,5,7 so das 7 - > 4 , Fertig !
            addtodo(z3, b);
            addtodo(x1, b);
            addtodo(zm1, b);
            addtodo(x1, b);
            addtodo(x1, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(x1, b);
            addtodo(x1, b);
            addtodo(z1, b);
            addtodo(xm1, b);
            addtodo(zm3, b);
            addtodo(x1, b);
            addtodo(zm1, b);
            addtodo(x1, b);
            addtodo(x1, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(x1, b);
            addtodo(x1, b);
            addtodo(z1, b);
            addtodo(xm1, b);
          End;
          Goto macheecken;
        End;
    End;
  If Pe5 <> 5 Then
    Case pe5 Of
      4: Begin
          If Pe7 <> 7 Then Begin
            // Rotieren Ecke 4,5,7 so das 4 - > 5 , Fertig !
            addtodo(z3, b);
            addtodo(x1, b);
            addtodo(zm1, b);
            addtodo(x1, b);
            addtodo(x1, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(x1, b);
            addtodo(x1, b);
            addtodo(z1, b);
            addtodo(xm1, b);
            addtodo(zm3, b);
            addtodo(x1, b);
            addtodo(zm1, b);
            addtodo(x1, b);
            addtodo(x1, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(x1, b);
            addtodo(x1, b);
            addtodo(z1, b);
            addtodo(xm1, b);
          End
          Else Begin
            // Rotieren Ecke 4,5,6 so das 4 - > 5 , Fertig !
            addtodo(z3, b);
            addtodo(ym3, b);
            addtodo(zm1, b);
            addtodo(ym3, b);
            addtodo(ym3, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(ym3, b);
            addtodo(ym3, b);
            addtodo(z1, b);
            addtodo(y3, b);
            addtodo(zm3, b);
            addtodo(ym3, b);
            addtodo(zm1, b);
            addtodo(ym3, b);
            addtodo(ym3, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(ym3, b);
            addtodo(ym3, b);
            addtodo(z1, b);
            addtodo(y3, b);
          End;
          Goto macheecken;
        End;
      6: Begin
          If Pe4 <> 4 Then Begin
            // Rotieren Ecke 4,5,6 so das 6 - > 5 , Fertig !
            Addtodo(ym3, b);
            Addtodo(zm1, b);
            Addtodo(ym3, b);
            Addtodo(ym3, b);
            Addtodo(zm1, b);
            Addtodo(zm1, b);
            Addtodo(ym3, b);
            Addtodo(ym3, b);
            Addtodo(z1, b);
            Addtodo(y3, b);
            Addtodo(z3, b);
            Addtodo(ym3, b);
            Addtodo(zm1, b);
            Addtodo(ym3, b);
            Addtodo(ym3, b);
            Addtodo(zm1, b);
            Addtodo(zm1, b);
            Addtodo(ym3, b);
            Addtodo(ym3, b);
            Addtodo(z1, b);
            Addtodo(y3, b);
            Addtodo(zm3, b);
          End
          Else Begin
            // Rotieren Ecke 5,6,7 so das 6 - > 5 , Fertig !
            addtodo(xm3, b);
            addtodo(zm1, b);
            addtodo(xm3, b);
            addtodo(xm3, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(xm3, b);
            addtodo(xm3, b);
            addtodo(z1, b);
            addtodo(x3, b);
            addtodo(z3, b);
            addtodo(xm3, b);
            addtodo(zm1, b);
            addtodo(xm3, b);
            addtodo(xm3, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(xm3, b);
            addtodo(xm3, b);
            addtodo(z1, b);
            addtodo(x3, b);
            addtodo(zm3, b);
          End;
          Goto macheecken;
        End;
      7: Begin
          If Pe4 <> 4 Then Begin
            // Rotieren Ecke 4,5,7 so das 7 - > 5 , Fertig !
            addtodo(x1, b);
            addtodo(zm1, b);
            addtodo(x1, b);
            addtodo(x1, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(x1, b);
            addtodo(x1, b);
            addtodo(z1, b);
            addtodo(xm1, b);
            addtodo(z3, b);
            addtodo(x1, b);
            addtodo(zm1, b);
            addtodo(x1, b);
            addtodo(x1, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(x1, b);
            addtodo(x1, b);
            addtodo(z1, b);
            addtodo(xm1, b);
            addtodo(zm3, b);
          End
          Else Begin
            // Rotieren Ecke 5,6,7 so das 7 - > 5 , Fertig !
            addtodo(z3, b);
            addtodo(xm3, b);
            addtodo(zm1, b);
            addtodo(xm3, b);
            addtodo(xm3, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(xm3, b);
            addtodo(xm3, b);
            addtodo(z1, b);
            addtodo(x3, b);
            addtodo(zm3, b);
            addtodo(xm3, b);
            addtodo(zm1, b);
            addtodo(xm3, b);
            addtodo(xm3, b);
            addtodo(zm1, b);
            addtodo(zm1, b);
            addtodo(xm3, b);
            addtodo(xm3, b);
            addtodo(z1, b);
            addtodo(x3, b);
          End;
          Goto macheecken;
        End;
    End;
  // Theoretisch gehört hier noch etwas reingeproggt das die Ecken 6,7 ausrichtet
  // Aber der Programmierer ist der Meinung das diese Fälle eh nie auftreten können
  // da sie durch die obigen ausreichen abgedeckt werden !!
  // Nun müssen die Ecken gedreht werden !!
  e4r := 1; // Eins = Ecke liegt sauber und Richtig !!
  e5r := 1; // Zwei = Kippen in die eine Richtung !!
  e6r := 1; // drei = Kippen in die andere Richtung !!
  e7r := 1;
  If b[5, 0] = b[4, 4] Then e4r := 2;
  If b[5, 0] = b[3, 4] Then e4r := 3;
  If b[5, 2] = b[3, 4] Then e5r := 2;
  If b[5, 2] = b[2, 4] Then e5r := 3;
  If b[5, 8] = b[2, 4] Then e6r := 2;
  If b[5, 8] = b[1, 4] Then e6r := 3;
  If b[5, 6] = b[1, 4] Then e7r := 2;
  If b[5, 6] = b[4, 4] Then e7r := 3;
  // Es sind auf Alle Fälle immer 3 Ecken oder Keine Falsch !!
  // Das Prinzip = Alle Ecken werden auf Ecke 4 Hingerdeht und dann gekippt und dann
  // wieder auf ihre Position gedreht.
  Case e4r Of
    2: Begin
        addtodo(xm1, b);
        addtodo(ym3, b);
        addtodo(x1, b);
        addtodo(y3, b);
        addtodo(xm1, b);
        addtodo(ym3, b);
        addtodo(x1, b);
        addtodo(y3, b);
      End;
    3: Begin
        addtodo(ym3, b);
        addtodo(xm1, b);
        addtodo(y3, b);
        addtodo(x1, b);
        addtodo(ym3, b);
        addtodo(xm1, b);
        addtodo(y3, b);
        addtodo(x1, b);
      End;
  End;
  Case e5r Of
    2: Begin
        addtodo(z3, b);
        addtodo(xm1, b);
        addtodo(ym3, b);
        addtodo(x1, b);
        addtodo(y3, b);
        addtodo(xm1, b);
        addtodo(ym3, b);
        addtodo(x1, b);
        addtodo(y3, b);
        addtodo(zm3, b);
      End;
    3: Begin
        addtodo(z3, b);
        addtodo(ym3, b);
        addtodo(xm1, b);
        addtodo(y3, b);
        addtodo(x1, b);
        addtodo(ym3, b);
        addtodo(xm1, b);
        addtodo(y3, b);
        addtodo(x1, b);
        addtodo(zm3, b);
      End;
  End;
  Case e6r Of
    2: Begin
        addtodo(z3, b);
        addtodo(z3, b);
        addtodo(xm1, b);
        addtodo(ym3, b);
        addtodo(x1, b);
        addtodo(y3, b);
        addtodo(xm1, b);
        addtodo(ym3, b);
        addtodo(x1, b);
        addtodo(y3, b);
        addtodo(zm3, b);
        addtodo(zm3, b);
      End;
    3: Begin
        addtodo(z3, b);
        addtodo(z3, b);
        addtodo(ym3, b);
        addtodo(xm1, b);
        addtodo(y3, b);
        addtodo(x1, b);
        addtodo(ym3, b);
        addtodo(xm1, b);
        addtodo(y3, b);
        addtodo(x1, b);
        addtodo(zm3, b);
        addtodo(zm3, b);
      End;
  End;
  Case e7r Of
    2: Begin
        addtodo(zm3, b);
        addtodo(xm1, b);
        addtodo(ym3, b);
        addtodo(x1, b);
        addtodo(y3, b);
        addtodo(xm1, b);
        addtodo(ym3, b);
        addtodo(x1, b);
        addtodo(y3, b);
        addtodo(z3, b);
      End;
    3: Begin
        addtodo(zm3, b);
        addtodo(ym3, b);
        addtodo(xm1, b);
        addtodo(y3, b);
        addtodo(x1, b);
        addtodo(ym3, b);
        addtodo(xm1, b);
        addtodo(y3, b);
        addtodo(x1, b);
        addtodo(z3, b);
      End;
  End;
  Optimize(ToDoList);
End;

Initialization
  InitCubeCalculationVars; // Initialisiert diverse Konstanten, welche für die Berechnungen notwendig sind

End.


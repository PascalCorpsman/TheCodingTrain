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

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, uengine;

Const
  boarder = 10;

Type

  { TForm1 }

  TForm1 = Class(TForm)
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    Procedure FormCreate(Sender: TObject);
    Procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    Procedure FormPaint(Sender: TObject);
    Procedure MenuItem11Click(Sender: TObject);
    Procedure MenuItem12Click(Sender: TObject);
    Procedure MenuItem4Click(Sender: TObject);
    Procedure MenuItem5Click(Sender: TObject);
    Procedure MenuItem7Click(Sender: TObject);
    Procedure MenuItem8Click(Sender: TObject);
    Procedure MenuItem9Click(Sender: TObject);
  private
    fField: TField;
    fSearchDepth: integer;
    fturn: integer;
    Procedure RenderField(field: TField);
    Function ClearField(): TField;
    Procedure Do_AI_Move();

  public

  End;

Var
  Form1: TForm1;

Implementation

{$R *.lfm}

Uses math;

(*
 * True, wenn der Punkt innerhalb der Elippse um middle liegt (Achtung W und H sind Durchmesser entlang der Achsen)
 *)

Function PointInEllipse(P: TPoint; middle_x, middle_y, w, h: integer): Boolean; // TODO: Braucht noch ne Ordentliche Implementierung, so nimmt es immer den kleineren inneren "Kreis"
Var
  i, j: integer;
Begin
  i := middle_x - p.X;
  j := middle_y - p.Y;
  result := sqr(min(w, h) / 2) - sqr(i) - sqr(j) >= 0;
End;

Function WinnerToString(value: Integer): String;
Begin
  Case value Of
    Draw: result := 'No one';
    Human: result := 'Player';
    AI: result := 'Ai';
    Unknown: result := '---';
  End;
End;

{ TForm1 }

Procedure TForm1.FormCreate(Sender: TObject);
Begin
  (*
   * Historie: 0.01 = Initialversion
   *)
  Randomize;
  caption := 'TicTacToe ver. 0.01';
  Constraints.MinHeight := 300;
  Constraints.MinWidth := 300;
  fField := ClearField();
  Invalidate;
  fturn := Unknown;
  MenuItem5.Checked := true; // Default Strong
End;

Procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Var
  i, j, w, h, ww, hh: Integer;
Begin
  If fturn = Human Then Begin
    w := ClientRect.Width;
    h := ClientRect.Height;
    For i := 0 To 2 Do Begin
      For j := 0 To 2 Do Begin
        ww := (w - 2 * boarder) Div 3;
        hh := (h - 2 * boarder) Div 3;
        If PointInEllipse(Point(x, y),
          i * ww + ww Div 2 + boarder,
          j * hh + hh Div 2 + boarder,
          round(ww * 0.75), round(hh * 0.75)
          ) Then Begin
          If fField[i, j] = Empty Then Begin
            fField[i, j] := Human;
            Invalidate;
            If GetWinner(fField) = Unknown Then Begin
              do_AI_Move();
            End
            Else Begin
              showmessage(WinnerToString(GetWinner(fField)) + ' wins.');
              fturn := Unknown;
            End;
            exit;
          End;
        End;
      End;
    End;
  End;
End;

Procedure TForm1.FormPaint(Sender: TObject);
Begin
  RenderField(fField);
End;

Procedure TForm1.MenuItem11Click(Sender: TObject);
Begin
  // Colors
  MenuItem11.Checked := true;
  Invalidate;
End;

Procedure TForm1.MenuItem12Click(Sender: TObject);
Begin
  // Dot / Cross
  MenuItem12.Checked := true;
  Invalidate;
End;

Procedure TForm1.MenuItem4Click(Sender: TObject);
Begin
  // Set Weak
  MenuItem4.Checked := true;
End;

Procedure TForm1.MenuItem5Click(Sender: TObject);
Begin
  // Set Strong
  MenuItem5.Checked := true;
End;

Procedure TForm1.MenuItem7Click(Sender: TObject);
Begin
  // Human first
  fField := ClearField;
  If MenuItem4.Checked Then Begin
    fSearchDepth := Weak_AI_Strength;
  End
  Else Begin
    fSearchDepth := Strong_AI_Strength;
  End;
  fturn := Human;
  Invalidate;
End;

Procedure TForm1.MenuItem8Click(Sender: TObject);
Begin
  // AI first
  fField := ClearField;
  If MenuItem4.Checked Then Begin
    fSearchDepth := Weak_AI_Strength;
  End
  Else Begin
    fSearchDepth := Strong_AI_Strength;
  End;
  Do_AI_Move();
  Invalidate;
End;

Procedure TForm1.MenuItem9Click(Sender: TObject);
Begin
  // Close
  Close;
End;

Procedure TForm1.RenderField(field: TField);

  Procedure RenderDot(Const C: TCanvas; x, y, w, h: integer; State: Integer);
  Begin
    c.Pen.Color := clblack;
    c.Brush.Color := clGray;
    c.Ellipse(x - w Div 2, y - h Div 2, x + w Div 2, y + h Div 2);
    Case State Of
      Ai: Begin
          If MenuItem11.Checked Then Begin
            // Colors
            c.Brush.Color := clRed;
            c.Ellipse(x - w Div 2, y - h Div 2, x + w Div 2, y + h Div 2);
          End
          Else Begin
            // Cross
            c.Pen.Width := 5;
            c.Line(x - w Div 4, y - h Div 4, x + w Div 4, y + h Div 4);
            c.Line(x - w Div 4, y + h Div 4, x + w Div 4, y - h Div 4);
            c.Pen.Width := 1;
          End;
        End;
      Human: Begin
          If MenuItem11.Checked Then Begin
            // Colors
            c.Brush.Color := clYellow;
            c.Ellipse(x - w Div 2, y - h Div 2, x + w Div 2, y + h Div 2);
          End
          Else Begin
            // Dot
            c.Pen.Width := 5;
            c.Ellipse(x - w Div 4, y - h Div 4, x + w Div 4, y + h Div 4);
            c.Pen.Width := 1;
          End;
        End;
    End
  End;

Var
  bm: TBitmap;
  ww, w, h, i, j, hh: integer;
Begin
  bm := TBitmap.Create;
  bm.Width := ClientRect.Width;
  bm.Height := ClientRect.Height;
  w := ClientRect.Width;
  h := ClientRect.Height;
  // Clear
  bm.Canvas.Brush.Color := clWhite;
  bm.Canvas.Rectangle(-1, -1, w + 1, h + 1);
  // Render Board
  bm.Canvas.Pen.Color := clBlack;
  bm.Canvas.Brush.Color := clGreen;
  bm.Canvas.Rectangle(boarder, boarder, w - boarder, h - boarder);
  // Render the "Dots"
  For i := 0 To 2 Do Begin
    For j := 0 To 2 Do Begin
      ww := (w - 2 * boarder) Div 3;
      hh := (h - 2 * boarder) Div 3;
      RenderDot(bm.canvas,
        i * ww + ww Div 2 + boarder,
        j * hh + hh Div 2 + boarder,
        round(ww * 0.75), round(hh * 0.75), Field[i, j]);
    End;
  End;
  canvas.Draw(0, 0, bm);
  bm.free;
End;

Function TForm1.ClearField(): TField;
Var
  i, j: Integer;
Begin
  For i := 0 To 2 Do
    For j := 0 To 2 Do
      result[i, j] := Empty;
End;

Procedure TForm1.Do_AI_Move();
Var
  p: TPoint;
Begin
  p := ComputerMove(fField, fSearchDepth);
  fField[p.x, p.y] := AI;
  Invalidate;

  // Nach der AI ist der User wieder dran
  If GetWinner(fField) = Unknown Then Begin
    fturn := Human;
  End
  Else Begin
    showmessage(WinnerToString(GetWinner(fField)) + ' wins.');
    fturn := Unknown;
  End;
End;

End.


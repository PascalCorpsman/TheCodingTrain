(******************************************************************************)
(* Linear_Cell                                                     ??.??.???? *)
(*                                                                            *)
(* Version     : 0.01                                                         *)
(*                                                                            *)
(* Author      : Uwe Schächterle (Corpsman)                                   *)
(*                                                                            *)
(* Support     : www.Corpsman.de                                              *)
(*                                                                            *)
(* Description : <Module_description>                                         *)
(*                                                                            *)
(* License     : See the file license.md, located under:                      *)
(*  https://github.com/PascalCorpsman/Software_Licenses/blob/main/license.md  *)
(*  for details about the license.                                            *)
(*                                                                            *)
(*               It is not allowed to change or remove this text from any     *)
(*               source file of the project.                                  *)
(*                                                                            *)
(* Warranty    : There is no warranty, neither in correctness of the          *)
(*               implementation, nor anything other that could happen         *)
(*               or go wrong, use at your own risk.                           *)
(*                                                                            *)
(* Known Issues: none                                                         *)
(*                                                                            *)
(* History     : 0.01 - Initial version                                       *)
(*                                                                            *)
(******************************************************************************)
Unit Unit1;

{$MODE objfpc}{$H+}

Interface

Uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Menus;

Type

  { TForm1 }

  TForm1 = Class(TForm)
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    MenuItem1: TMenuItem;
    PaintBox1: TPaintBox;
    PopupMenu1: TPopupMenu;
    SaveDialog1: TSaveDialog;
    Shape1: TShape;
    Shape10: TShape;
    Shape11: TShape;
    Shape12: TShape;
    Shape13: TShape;
    Shape14: TShape;
    Shape15: TShape;
    Shape16: TShape;
    Shape17: TShape;
    Shape18: TShape;
    Shape19: TShape;
    Shape2: TShape;
    Shape20: TShape;
    Shape21: TShape;
    Shape22: TShape;
    Shape23: TShape;
    Shape24: TShape;
    Shape25: TShape;
    Shape26: TShape;
    Shape27: TShape;
    Shape28: TShape;
    Shape29: TShape;
    Shape3: TShape;
    Shape30: TShape;
    Shape31: TShape;
    Shape32: TShape;
    Shape4: TShape;
    Shape5: TShape;
    Shape6: TShape;
    Shape7: TShape;
    Shape8: TShape;
    Shape9: TShape;
    Procedure Button1Click(Sender: TObject);
    Procedure Edit1KeyPress(Sender: TObject; Var Key: char);
    Procedure Edit2Change(Sender: TObject);
    Procedure FormCloseQuery(Sender: TObject; Var CanClose: boolean);
    Procedure FormCreate(Sender: TObject);
    Procedure FormShow(Sender: TObject);
    Procedure MenuItem1Click(Sender: TObject);
    Procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    Procedure PaintBox1Paint(Sender: TObject);
    Procedure PaintBox1Resize(Sender: TObject);
    Procedure Shape26MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { private declarations }
    ShowOnce: Boolean;
  public
    { public declarations }
  End;

Var
  Form1: TForm1;
  b: Tbitmap;

Implementation

{$R *.lfm}

{ TForm1 }

Procedure TForm1.Edit1KeyPress(Sender: TObject; Var Key: char);
Var
  h: Integer;
  i: Integer;
  s: TShape;
Begin
  If key = #13 Then Begin
    h := strtointdef(edit1.text, 0);
    For i := 25 To 32 Do Begin
      s := TShape(FindComponent('Shape' + inttostr(i)));
      If (h And (1 Shl (i - 25))) <> 0 Then Begin
        s.Brush.Color := clblack;
        s.Pen.Color := clwhite;
      End
      Else Begin
        s.Brush.Color := clwhite;
        s.Pen.Color := clblack;
      End;
      s.Invalidate;
    End;
  End;
End;

Procedure TForm1.Edit2Change(Sender: TObject);
Begin
  button2.Click;
End;

Procedure TForm1.FormCloseQuery(Sender: TObject; Var CanClose: boolean);
Begin
  b.free;
End;

Procedure TForm1.Button1Click(Sender: TObject);
Var
  s: Integer;

  Function Get(x, y: integer): integer;
  Begin
    If b.Canvas.Pixels[x * s, y * s] = clblack Then
      result := 1
    Else
      result := 0;
  End;

  Procedure set_(x, y: integer; v: Boolean);
  Begin
    If s = 1 Then Begin
      If v Then
        b.Canvas.Pixels[x, y] := clblack
      Else
        b.Canvas.Pixels[x, y] := clwhite;
    End
    Else Begin
      If v Then
        b.Canvas.Brush.Color := clblack
      Else
        b.Canvas.Brush.Color := clwhite;
      b.Canvas.Pen.Color := b.Canvas.Brush.Color;
      b.Canvas.Rectangle(x * s, y * s, (x + 1) * s, (y + 1) * s);
{$IFDEF Linux}
      b.Canvas.pixels[(x + 1) * s - 1, (y + 1) * s - 1] := b.Canvas.Brush.Color;
{$ENDIF}
    End;
  End;

Var
  d, i, j: integer;
  regel: Array[0..7] Of integer;
  nline, aline: Array Of integer; // Die Zeilen müssen gecached und Breiter berechnet werden, da sonst am Rand Aliaseffekte entstehen..
  line_off: integer;
Begin
  s := strtointdef(edit2.text, 0);
  d := StrToIntdef(edit3.text, 10);
  For i := 0 To 7 Do Begin
    If TShape(FindComponent('Shape' + inttostr(i + 25))).canvas.Brush.Color = clblack Then
      regel[i] := 1
    Else
      regel[i] := 0;
  End;
  If s < 1 Then exit;
  aline := Nil;
  nline := Nil;
  setlength(aline, (b.Width Div s) + 2 * (b.Height Div s) + 4); // In jeder zeile wächste der Datensatz um 1 Element, also + 2* height und noch auf beiden Seiten 2 als Reserve
  setlength(nline, (b.Width Div s) + 2 * (b.Height Div s) + 4);
  // Erzeugen der Initialen "Alten Neuen Zeile"
  For i := 0 To high(aline) Do Begin
    nline[i] := 0;
  End;
  line_off := (b.Height Div s) + 2;
  For i := 0 To b.Width Div s Do Begin
    nline[i + line_off] := get(i, 0);
  End;
  // Die Eigentliche Simulation
  For j := 1 To b.Height Div s Do Begin
    // n -> a
    For i := 0 To high(aline) Do Begin
      aline[i] := nline[i];
    End;
    // n neu erstellen
    For i := 1 To high(aline) - 1 Do Begin
      nline[i] := regel[aline[i - 1] * 4 + aline[i] * 2 + aline[i + 1]];
    End;
    // den Sichtbaren Teil aus n visualisieren
    For i := 0 To b.Width Div s Do Begin
      set_(i, j, nline[i + line_off] = 1);
    End;
    // Anzeigen und ein kleines bischen warten
    If d > 0 Then Begin
      PaintBox1.OnPaint(Nil);
      Application.ProcessMessages;
      sleep(d);
    End;
  End;
  // Wurde nicht während der Simulation angezeigt, machen wir das hier zum Schluss definitiv
  If d = 0 Then
    PaintBox1.OnPaint(Nil);
End;

Procedure TForm1.FormCreate(Sender: TObject);
Begin
  Constraints.MinWidth := Width;
  Constraints.MinHeight := Height;
  caption := 'Linear cell automate ver. 0.01 by Corpsman, www.Corpsman.de';
  b := Tbitmap.create;
  ShowOnce := true;
  PaintBox1Resize(self);
End;

Procedure TForm1.FormShow(Sender: TObject);
Var
  c: Char;
Begin
  If ShowOnce Then Begin
    ShowOnce := false;
    c := #13;
    Edit1.text := '126';
    Edit2.text := '8';
    Edit3.text := '10';
    Edit1KeyPress(edit1, c);
    Button2.Click;
    PaintBox1MouseDown(Nil, mbLeft, [ssLeft], PaintBox1.Width Div 2, 0);
  End;
End;

Procedure TForm1.MenuItem1Click(Sender: TObject);
Begin
  If SaveDialog1.Execute Then Begin
    b.SaveToFile(SaveDialog1.FileName);
  End;
End;

Procedure TForm1.PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Var
  size: integer;
Begin
  If ssleft In shift Then Begin
    size := strtointdef(edit2.text, 0);
    If size > 0 Then Begin
      x := x Div size;
      y := 0; // y div size;
      x := x * size;
      y := y * size;
      If b.Canvas.Pixels[x, y] = clblack Then Begin
        b.Canvas.Pen.Color := clwhite;
        b.Canvas.Brush.Color := clwhite;
      End
      Else Begin
        b.Canvas.Pen.Color := clblack;
        b.Canvas.Brush.Color := clblack;
      End;
      If size <> 1 Then Begin
        b.Canvas.Rectangle(x, y, x + size, y + size);
{$IFDEF Linux}
        b.Canvas.pixels[x + size - 1, y + size - 1] := b.Canvas.Brush.Color;
{$ENDIF}
      End
      Else Begin
        b.Canvas.Pixels[x, y] := b.Canvas.Pen.Color;
      End;
      PaintBox1.Invalidate;
    End;
  End;
End;

Procedure TForm1.PaintBox1Paint(Sender: TObject);
Begin
  PaintBox1.Canvas.Draw(0, 0, b);
End;

Procedure TForm1.PaintBox1Resize(Sender: TObject);
Begin
  b.Width := PaintBox1.Width;
  b.Height := PaintBox1.Height;
  b.canvas.Pen.Color := clwhite;
  b.canvas.Brush.Color := clwhite;
  b.Canvas.Rectangle(0, 0, b.Width, b.Height);
  PaintBox1.Invalidate;
End;

Procedure TForm1.Shape26MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Var
  i, h: integer;
  s: TShape;
Begin
  // Einlesen der Shapes und umrechnen in die Numerische Konstante (bin to dez)
  If TShape(Sender).Brush.Color = clblack Then Begin
    TShape(Sender).Brush.Color := clwhite;
    TShape(Sender).Pen.Color := clblack;
  End
  Else Begin
    TShape(Sender).Brush.Color := clblack;
    TShape(Sender).Pen.Color := clwhite;
  End;
  TShape(Sender).Invalidate;
  h := 0;
  For i := 25 To 32 Do Begin
    s := TShape(FindComponent('Shape' + inttostr(i)));
    If s.Brush.Color = clblack Then Begin
      h := h + 1 Shl (i - 25);
    End;
  End;
  edit1.text := inttostr(h);
End;

End.


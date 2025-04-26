Unit Unit1;

{$MODE ObjFPC}{$H+}

Interface

Uses
  LCLIntf, LCLType, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, math;

Type
  TForm1 = Class(TForm)
    RadioGroup1: TRadioGroup;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    PaintBox1: TPaintBox;
    Label1: TLabel;
    Button4: TButton;
    Procedure Button2Click(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure Button1Click(Sender: TObject);
    Procedure FormPaint(Sender: TObject);
    Procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    Procedure Button3Click(Sender: TObject);
    Procedure RadioGroup1Click(Sender: TObject);
    Procedure Button4Click(Sender: TObject);
    Procedure FormCloseQuery(Sender: TObject; Var CanClose: Boolean);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  End;

Var
  Form1: TForm1;
  bet, stop: boolean;
  Punkte: Array[0..7] Of Tpoint;
  Between: Tpoint;
  Punktcount: integer;

Implementation

{$R *.lfm}

Procedure paintpoint(x, y: integer; Color: Tcolor);
Begin
  With form1.paintbox1.canvas Do Begin
    PIXELS[x, y] := Color;
    PIXELS[x - 1, y] := Color;
    PIXELS[x + 1, y] := Color;
    PIXELS[x, y - 1] := Color;
    PIXELS[x, y + 1] := Color;
  End;
End;

Procedure loeschen;
Begin
  With form1.paintbox1.canvas Do Begin
    Brush.style := bssolid;
    brush.color := clwhite;
    rectangle(0, 0, form1.paintbox1.width, form1.paintbox1.height);
  End;
End;

Procedure TForm1.Button2Click(Sender: TObject);
Begin
  close;
End;

Procedure TForm1.FormCreate(Sender: TObject);
Var
  x: integer;
Begin
  bet := true;
  Punktcount := 0;
  For x := 0 To high(punkte) - 1 Do Begin
    punkte[x].x := 0;
    punkte[x].y := 0;
  End;
  Label1.caption := 'Bitte Ecke ' + inttostr(punktcount + 1) + 'setzen';
  label1.Left := width - label1.width - 20;
End;

Procedure TForm1.Button1Click(Sender: TObject);
Var
  x: integer;
  b: Tpoint;
  c: Currency;
Begin
  With Paintbox1.canvas Do Begin
    button1.enabled := false;
    randomize;
    Brush.style := bssolid;
    brush.color := clwhite;
    c := 0;
    rectangle(0, 0, paintbox1.width, paintbox1.height);
    Moveto(punkte[0].x, punkte[0].y);
    Stop := false;
    Case Radiogroup1.itemindex Of
      0: Begin
          While Not (stop) Do Begin
            application.ProcessMessages;
            c := c + 1;
            x := random(3);
            b := punkte[x];
            between.x := ((b.x + between.x) Div 2);
            between.y := ((b.y + between.y) Div 2);
            pixels[between.x, between.y] := clblack;
          End;
        End;
      1: Begin
          While Not (stop) Do Begin
            application.ProcessMessages;
            c := c + 1;
            x := random(4);
            b := punkte[x];
            Between.x := round(between.x + ((b.x - between.x) * 0.53));
            Between.y := round(between.y + ((b.y - between.y) * 0.53));
            pixels[between.x, between.y] := clblack;
          End;
        End;
      2: Begin
          While Not (stop) Do Begin
            application.ProcessMessages;
            c := c + 1;
            x := random(5);
            b := punkte[x];
            Between.x := round(between.x + ((b.x - between.x) * 0.62));
            Between.y := round(between.y + ((b.y - between.y) * 0.62));
            pixels[between.x, between.y] := clblack;
          End;
        End;
      3: Begin
          While Not (stop) Do Begin
            application.ProcessMessages;
            c := c + 1;
            x := random(6);
            b := punkte[x];
            Between.x := round(between.x + ((b.x - between.x) * 0.67));
            Between.y := round(between.y + ((b.y - between.y) * 0.67));
            pixels[between.x, between.y] := clblack;
          End;
        End;
      4: Begin
          While Not (stop) Do Begin
            application.ProcessMessages;
            c := c + 1;
            x := random(7);
            b := punkte[x];
            Between.x := round(between.x + ((b.x - between.x) * 0.6975));
            Between.y := round(between.y + ((b.y - between.y) * 0.6975));
            pixels[between.x, between.y] := clblack;
          End;
        End;
      5: Begin
          While Not (stop) Do Begin
            application.ProcessMessages;
            c := c + 1;
            x := random(8);
            b := punkte[x];
            Between.x := round(between.x + ((b.x - between.x) * 0.72));
            Between.y := round(between.y + ((b.y - between.y) * 0.72));
            pixels[between.x, between.y] := clblack;
          End;
        End;
    End;
    TextOut(15, Paintbox1.height - 25, floattostr(c) + ' gezeichnete Punkte');
    button1.enabled := True;
  End;
End;

Procedure TForm1.FormPaint(Sender: TObject);
Begin
  If bet Then loeschen;
  bet := false;

End;

Procedure TForm1.PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Var
  c: integer;
Begin
  loeschen;
  If ssright In shift Then Begin
    between.x := x;
    between.y := y;
    paintpoint(x, y, clblue);
    For c := 0 To punktcount Do
      paintpoint(punkte[c].x, punkte[c].y, clred);
    exit;
  End;
  If ssleft In shift Then Begin
    Punkte[punktcount].x := x;
    Punkte[punktcount].y := y;
    paintpoint(between.x, between.y, clblue);
    For c := 0 To punktcount Do
      paintpoint(punkte[c].x, punkte[c].y, clred);
    inc(punktcount);
    If (punktcount - 2) > RadioGroup1.itemindex Then punktcount := 0;
  End;
  Label1.caption := 'Bitte Ecke ' + inttostr(punktcount + 1) + 'setzen';
End;

Procedure TForm1.Button3Click(Sender: TObject);
Var
  w, x: integer;
  g: Tpoint;
Begin
  Loeschen;
  Stop := true;
  g.x := paintbox1.width Div 2;
  g.y := paintbox1.height Div 2;
  w := min(g.x, g.y) - 10;
  Case Radiogroup1.itemindex Of
    0: Begin
        For X := 0 To 2 Do Begin
          Punkte[x].x := g.x - round(w * sin(degtorad(X * 120)));
          Punkte[x].y := g.y - round(w * cos(degtorad(X * 120)));
        End;
      End;
    1: Begin
        For X := 0 To 3 Do Begin
          Punkte[x].x := g.x - round(w * sin(degtorad(X * 90)));
          Punkte[x].y := g.y - round(w * cos(degtorad(X * 90)));
        End;
      End;
    2: Begin
        For X := 0 To 4 Do Begin
          Punkte[x].x := g.x - round(w * sin(degtorad(X * 72)));
          Punkte[x].y := g.y - round(w * cos(degtorad(X * 72)));
        End;
      End;
    3: Begin
        For X := 0 To 5 Do Begin
          Punkte[x].x := g.x - round(w * sin(degtorad(X * 60)));
          Punkte[x].y := g.y - round(w * cos(degtorad(X * 60)));
        End;
      End;
    4: Begin
        For X := 0 To 6 Do Begin
          Punkte[x].x := g.x - round(w * sin(degtorad(X * 51.42)));
          Punkte[x].y := g.y - round(w * cos(degtorad(X * 51.42)));
        End;
      End;
    5: Begin
        For X := 0 To 7 Do Begin
          Punkte[x].x := g.x - round(w * sin(degtorad(X * 45)));
          Punkte[x].y := g.y - round(w * cos(degtorad(X * 45)));
        End;
      End;
  End;
  For x := 0 To Radiogroup1.itemindex + 2 Do Begin
    Paintbox1.Canvas.pixels[punkte[x].x, punkte[x].y] := clred;
    Paintbox1.Canvas.pixels[punkte[x].x - 1, punkte[x].y] := clred;
    Paintbox1.Canvas.pixels[punkte[x].x + 1, punkte[x].y] := clred;
    Paintbox1.Canvas.pixels[punkte[x].x, punkte[x].y - 1] := clred;
    Paintbox1.Canvas.pixels[punkte[x].x, punkte[x].y + 1] := clred;
  End;
End;

Procedure TForm1.RadioGroup1Click(Sender: TObject);
Begin
  loeschen;
End;

Procedure TForm1.Button4Click(Sender: TObject);
Begin
  Stop := true;
End;

Procedure TForm1.FormCloseQuery(Sender: TObject; Var CanClose: Boolean);
Begin
  stop := true;
End;

End.

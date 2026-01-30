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
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, uNodeJs;

Type

  { TForm1 }

  TForm1 = Class(TForm)
    Procedure FormCloseQuery(Sender: TObject; Var CanClose: Boolean);
    Procedure FormCreate(Sender: TObject);
    Procedure FormDestroy(Sender: TObject);
    Procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    Procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    Procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    Procedure FormPaint(Sender: TObject);
  private
    FrameRateCounterTime: QWord;
    FrameRateCounter: integer;
    Closing: Boolean;
  public

  End;

Var
  Form1: TForm1;

  (*
   * Helper variables to Emulate NodeJs, do not directly access, use uNodeJs.pas !
   *)
Var
  VirtualCanvas: TBitmap; // This
  NoLoopCalled: Boolean = false;
  FrameRateDelay: integer = 10; // default 100 FPS

Implementation

{$R *.lfm}

Uses uapplication;

{ TForm1 }

Procedure TForm1.FormCloseQuery(Sender: TObject; Var CanClose: Boolean);
Begin
  Closing := true;
End;

Procedure TForm1.FormCreate(Sender: TObject);
Begin
  Randomize;
  VirtualCanvas := TBitmap.Create;
  setup;
End;

Procedure TForm1.FormDestroy(Sender: TObject);
Begin
  VirtualCanvas.free;
  VirtualCanvas := Nil;
End;

Procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Begin
  MouseIsPressed := ssleft In shift;
  mouseX := x;
  MouseY := y;
End;

Procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
Begin
  MouseIsPressed := ssleft In shift;
  mouseX := x;
  MouseY := y;
End;

Procedure TForm1.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Begin
  MouseIsPressed := ssleft In shift;
  mouseX := x;
  MouseY := y;
End;

Procedure TForm1.FormPaint(Sender: TObject);
Var
  n, b: QWord;
Begin
  If Closing Then exit;
  draw();
  canvas.Draw(0, 0, VirtualCanvas);
  If NoLoopCalled Then exit;
  inc(FrameRateCounter);
  n := GetTickCount64;
  If FrameRateCounterTime + 1000 <= n Then Begin
    FrameRateCounterTime := n;
    If ShowFrameRate Then Begin
      caption := format('Framerate: %d FPS', [FrameRateCounter]);
    End;
    FrameRateCounter := 0;
  End;
  // Restart Drawing..
  b := GetTickCount64;
  While b + FrameRateDelay > GetTickCount64 Do Begin
    sleep(1); // Limit Framerate to ~100 FPS
    Application.ProcessMessages;
  End;
  Invalidate;
End;

End.


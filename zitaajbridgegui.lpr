program ZitaAJBridgeGUI;

{$mode objfpc}{$H+}

uses
  {$DEFINE UseCThreads} // remove if not applicable
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces,
  Forms,
  FormMain;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.


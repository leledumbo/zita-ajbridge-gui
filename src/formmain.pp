unit FormMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, IniPropStorage, PairSplitter, AJBridgeProcessThread;

type

  { TMainForm }

  TMainForm = class(TForm)
    PSMain: TIniPropStorage;
    PSLR: TPairSplitter;
    PSLRLeft: TPairSplitterSide;
    PSLRRight: TPairSplitterSide;
    GBDevices: TGroupBox;
    LBDevices: TListBox;
    BtnRefresh: TButton;
    PanelConnection: TPanel;
    PSTB: TPairSplitter;
    PSTBTop: TPairSplitterSide;
    PSTBBottom: TPairSplitterSide;
    GBConnSettings: TGroupBox;
    PForms: TPanel;
    RBZitaA2J: TRadioButton;
    RBZitaJ2A: TRadioButton;
    LblJackName: TLabel;
    EditJackClientName: TEdit;
    LblSampleRate: TLabel;
    EditSampleRate: TEdit;
    LblPeriod: TLabel;
    EditPeriod: TEdit;
    NoFrag: TLabel;
    EditNoFrag: TEdit;
    LblNoChannel: TLabel;
    EditNoChannel: TEdit;
    LblResamplingQuality: TLabel;
    EditResamplingQuality: TEdit;
    LblLatencyAdjustment: TLabel;
    EditLatencyAdjustment: TEdit;
    CBForce16Bit: TCheckBox;
    CBPrintTrace: TCheckBox;
    PButtons: TPanel;
    BtnConnect: TButton;
    GBLog: TGroupBox;
    MemoLog: TMemo;
    procedure BtnRefreshClick(Sender: TObject);
    procedure BtnConnectClick(Sender: TObject);
    procedure WriteToMemo(const Output: String);
    procedure HandleException(e: Exception);
    procedure MemoLogChange(Sender: TObject);
    procedure LBDevicesSelectionChange(Sender: TObject; User: boolean);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    procedure ClearDevices;
    procedure GetDevices;
    procedure FillForm(const ADeviceIndex: Integer);
    procedure ResetConnectButton(Sender: TObject);
  public
    { public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  AlsaHelper;

{$R *.lfm}

{ TMainForm }

procedure TMainForm.BtnRefreshClick(Sender: TObject);
begin
  if MessageDlg('Are you sure?','This will disconnect all currently connected devices',
    mtConfirmation,[mbOK,mbCancel],0) = mrOK
  then
    GetDevices;
end;

procedure TMainForm.BtnConnectClick(Sender: TObject);
var
  LProcessThread: TAJBridgeProcessThread;
  LProcess: TAJBridgeProcess;
  LDeviceIndex: Integer;
begin
  LDeviceIndex := LBDevices.ItemIndex;
  if LDeviceIndex >= 0 then begin
    LProcess := LBDevices.Items.Objects[LDeviceIndex] as TAJBridgeProcess;

    if not LProcess.Running then begin
      with LProcess do begin
        IsA2J := RBZitaA2J.Checked;
        JackClientName := EditJackClientName.Text;
        SampleRate := StrToIntDef(EditSampleRate.Text,0);
        PeriodSize := StrToIntDef(EditPeriod.Text,0);
        NoOfFragments := StrToIntDef(EditNoFrag.Text,0);
        NoOfChannels := StrToIntDef(EditNoChannel.Text,0);
        ResamplingQuality := StrToIntDef(EditResamplingQuality.Text,0);
        LatencyAdjustment := StrToIntDef(EditLatencyAdjustment.Text,0);
        Force16Bit := CBForce16Bit.Checked;
        PrintTraceInfo := CBPrintTrace.Checked;
      end;

      LProcessThread := TAJBridgeProcessThread.Create(LProcess, @WriteToMemo,@HandleException,@ResetConnectButton);
      LProcessThread.Start;
      BtnConnect.Caption := '&Disconnect';
    end else begin
      LProcess.ExecutorThread.Terminate;
      BtnConnect.Caption := '&Connect';
    end;
  end else begin
    MessageDlg('Error','Please select a device',mtError,[mbOK],0);
  end;
end;

procedure TMainForm.WriteToMemo(const Output: String);
begin
  MemoLog.Text := MemoLog.Text + Output;
end;

procedure TMainForm.HandleException(e: Exception);
begin
  MemoLog.Text := MemoLog.Text + e.ClassName + ': ' + e.Message;
end;

procedure TMainForm.MemoLogChange(Sender: TObject);
begin
  MemoLog.SelStart := Length(MemoLog.Text);
end;

procedure TMainForm.LBDevicesSelectionChange(Sender: TObject; User: boolean);
begin
  FillForm(LBDevices.ItemIndex);
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  ClearDevices;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  GetDevices;
end;

procedure TMainForm.ClearDevices;
var
  i: Integer;
  LProcess: TAJBridgeProcess;
begin
  // clear existing processes
  for i := 0 to LBDevices.Items.Count - 1 do begin
    LProcess := LBDevices.Items.Objects[i] as TAJBridgeProcess;
    if Assigned(LProcess.ExecutorThread) then begin
      LProcess.ExecutorThread.Terminate;
      LProcess.ExecutorThread.WaitFor;
    end;
    LProcess.Free;
  end;
  LBDevices.Items.Clear;
end;

procedure TMainForm.GetDevices;
var
  Devices: TStrings;
  i: Integer;
  LProcess: TAJBridgeProcess;
begin
  if AlsaHelper.GetDeviceList(Devices) then begin
    ClearDevices;
    for i := 0 to Devices.Count - 1 do begin
      LProcess := TAJBridgeProcess.Create(nil);
      with LProcess do begin
        ALSADevice := Devices.ValueFromIndex[i];
        // default values
        JackClientName := 'zita-a2j';
        SampleRate := 48000;
        PeriodSize := 256;
        NoOfFragments := 2;
        NoOfChannels := 2;
        ResamplingQuality := 48;
        LatencyAdjustment := 0;
      end;
      LBDevices.Items.AddObject(Devices.Names[i],LProcess);
    end;
  end else
    MessageDlg('Error',AlsaHelper.GetLastErrorMsg,mtError,[mbOK],0);
  FreeAndNil(Devices);
end;

procedure TMainForm.FillForm(const ADeviceIndex: Integer);
var
  LProcess: TAJBridgeProcess;
begin
  if (0 <= ADeviceIndex) and (ADeviceIndex < LBDevices.Count) then begin
    LProcess := LBDevices.Items.Objects[ADeviceIndex] as TAJBridgeProcess;
    with LProcess do begin
      RBZitaA2J.Checked          := IsA2J;
      EditJackClientName.Text    := JackClientName;
      EditSampleRate.Text        := IntToStr(SampleRate);
      EditPeriod.Text            := IntToStr(PeriodSize);
      EditNoFrag.Text            := IntToStr(NoOfFragments);
      EditNoChannel.Text         := IntToStr(NoOfChannels);
      EditResamplingQuality.Text := IntToStr(ResamplingQuality);
      EditLatencyAdjustment.Text := IntToStr(LatencyAdjustment);
      CBForce16Bit.Checked       := Force16Bit;
      CBPrintTrace.Checked       := PrintTraceInfo;
      if Running then
        BtnConnect.Caption := '&Disconnect'
      else
        BtnConnect.Caption := '&Connect';
    end;
  end;
end;

procedure TMainForm.ResetConnectButton(Sender: TObject);
begin
  BtnConnect.Caption := '&Connect';
end;

end.


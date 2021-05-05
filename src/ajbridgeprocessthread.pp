unit AJBridgeProcessThread;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process;

const
  MaxSampleRate = 192000;
  MaxPeriodSize = 1024;

type

  TAJBridgeProcessThread = class;

  { TAJBridgeProcess }

  TAJBridgeProcess = class(TProcess)
  private
    FExecutorThread: TAJBridgeProcessThread;
    FIsA2J: Boolean;
    FJackClientName: String;
    FALSADevice: String;
    FSampleRate: LongWord;
    FPeriodSize: Word;
    FNoOfFragments: Byte;
    FNoOfChannels: Byte;
    FResamplingQuality: Byte;
    FLatencyAdjustment: Byte;
    FForce16Bit: Boolean;
    FPrintTraceInfo: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Execute; override;
    property ExecutorThread: TAJBridgeProcessThread read FExecutorThread;
    property IsA2J: Boolean read FIsA2J write FIsA2J;
    property JackClientName: String read FJackClientName write FJackClientName;
    property ALSADevice: String read FALSADevice write FALSADevice;
    property SampleRate: LongWord read FSampleRate write FSampleRate;
    property PeriodSize: Word read FPeriodSize write FPeriodSize;
    property NoOfFragments: Byte read FNoOfFragments write FNoOfFragments;
    property NoOfChannels: Byte read FNoOfChannels write FNoOfChannels;
    property ResamplingQuality: Byte read FResamplingQuality write FResamplingQuality;
    property LatencyAdjustment: Byte read FLatencyAdjustment write FLatencyAdjustment;
    property Force16Bit: Boolean read FForce16Bit write FForce16Bit;
    property PrintTraceInfo: Boolean read FPrintTraceInfo write FPrintTraceInfo;
  end;

  { TAJBridgeProcessThread }

  TOnOutput = procedure (const Output: String) of object;
  TOnException = procedure (e: Exception) of object;

  TAJBridgeProcessThread = class(TThread)
  private
    FProcess: TAJBridgeProcess;
    FOnOutput: TOnOutput;
    FOnException: TOnException;
    FCurrentOutput: String;
    FCurrentException: Exception;
    procedure SyncOutput;
    procedure SyncException;
  public
    constructor Create(AProcess: TAJBridgeProcess; AOnOutput: TOnOutput;
      AOnException: TOnException; AOnTerminate: TNotifyEvent);
    procedure Execute; override;
    property Process: TAJBridgeProcess read FProcess;
  end;

implementation

uses
  StrUtils;

{ TAJBridgeProcess }

constructor TAJBridgeProcess.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Parameters.Delimiter := ' ';
  Parameters.StrictDelimiter := true;
end;

procedure TAJBridgeProcess.Execute;
begin
  Parameters.Clear;
  if FALSADevice <> EmptyStr then begin
    Parameters.Add('-d');
    Parameters.Add(FALSADevice);
  end else
    raise EProcess.Create('ALSA device may not be empty');

  Executable := IfThen(FIsA2J,'zita-a2j','zita-j2a');

  if FJackClientName <> EmptyStr then begin
    Parameters.Add('-j');
    Parameters.Add(FJackClientName);
  end;

  Parameters.Add('-r');
  Parameters.Add(IntToStr(FSampleRate));

  Parameters.Add('-p');
  Parameters.Add(IntToStr(FPeriodSize));

  Parameters.Add('-n');
  Parameters.Add(IntToStr(FNoOfFragments));

  Parameters.Add('-c');
  Parameters.Add(IntToStr(FNoOfChannels));

  Parameters.Add('-Q');
  Parameters.Add(IntToStr(FResamplingQuality));

  if FIsA2J then Parameters.Add('-I') else Parameters.Add('-O');
  Parameters.Add(IntToStr(FLatencyAdjustment));

  if FForce16Bit then begin
    Parameters.Add('-L');
  end;

  if FPrintTraceInfo then begin
    Parameters.Add('-v');
  end;

  inherited Execute;
end;

{ TAJBridgeProcessThread }

constructor TAJBridgeProcessThread.Create(AProcess: TAJBridgeProcess;
  AOnOutput: TOnOutput; AOnException: TOnException; AOnTerminate: TNotifyEvent);
begin
  if not Assigned(AProcess) then raise EProcess.Create('Nil process instance');
  FProcess := AProcess;
  FOnOutput := AOnOutput;
  FOnException := AOnException;
  OnTerminate := AOnTerminate;
  FreeOnTerminate := true;
  AProcess.FExecutorThread := Self;
  inherited Create(true);
end;

procedure TAJBridgeProcessThread.Execute;

  procedure CheckOutput;
  var
    BytesAvail: DWord;
    Output: String;
  begin
    repeat
      BytesAvail := FProcess.Output.NumBytesAvailable;
      if BytesAvail > 0 then begin
        SetLength(Output,BytesAvail);
        FProcess.Output.Read(Output[1],BytesAvail);
        FCurrentOutput := Output;
        Synchronize(@SyncOutput);
      end;
    until BytesAvail <= 0;
    Sleep(1);
  end;

begin
  FProcess.Options := [poUsePipes,poStderrToOutPut];
  try
    FProcess.Execute;
    FCurrentOutput := 'Executing:' + FProcess.Executable + ' '
                    + FProcess.Parameters.DelimitedText + LineEnding;
    Synchronize(@SyncOutput);
    while not Terminated and FProcess.Running do begin
      CheckOutput;
    end;
    if not Terminated then
      CheckOutput;
    FProcess.Terminate(0);
    FProcess.FExecutorThread := nil;
  except
    on e: Exception do begin
      FCurrentException := e;
      Synchronize(@SyncException);
    end;
  end;
end;

procedure TAJBridgeProcessThread.SyncOutput;
begin
  if Assigned(FOnOutput) then FOnOutput(FCurrentOutput);
end;

procedure TAJBridgeProcessThread.SyncException;
begin
  if Assigned(FOnException) then FOnException(FCurrentException);
end;

end.


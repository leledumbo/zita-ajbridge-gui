unit AlsaHelper;

{$mode objfpc}{$H+}

interface

uses
  Classes;

function GetDeviceList(out Devices: TStrings): Boolean;
function GetLastErrorMsg: String;

implementation

uses
  SysUtils,ASoundLib;

const
  ENOENT = 2;

var
  LastErrorMsg: String;

procedure error(const FmtStr: String; Args: array of const);
begin
  LastErrorMsg := Format(FmtStr,Args);
end;

procedure error(const FmtStr: String); inline;
begin
  error(FmtStr,[]);
end;

function GetDeviceList(out Devices: TStrings): Boolean;
label
  next_card;
var
  handle: Psnd_ctl_t;
  card, err, dev, idx: LongInt;
  info: Psnd_ctl_card_info_t;
  pcminfo: Psnd_pcm_info_t;
  name: String;
  count: LongWord;
begin
  Result := false;
  Devices := TStringList.Create;

  card := -1;
  if (snd_card_next(@card) < 0) or (card < 0) then begin
    error('no soundcards found...');
    exit;
  end;

  snd_ctl_card_info_malloc(@info);
  snd_pcm_info_malloc(@pcminfo);

  while card >= 0 do begin
    name := Format('hw:%d',[card]);

    err := snd_ctl_open(@handle, @name[1], 0);
    if err < 0 then begin
      error('control open (%i): %s',[card, snd_strerror(err)]);
      goto next_card;
    end;

    err := snd_ctl_card_info(handle, info);
    if err < 0 then begin
      error('control hardware info (%d): %s',[card, snd_strerror(err)]);
      snd_ctl_close(handle);
      goto next_card;
    end;

    dev := -1;
    while true do begin
      if snd_ctl_pcm_next_device(handle, @dev) < 0 then
        error('snd_ctl_pcm_next_device');
      if dev < 0 then
        break;

      snd_pcm_info_set_device(pcminfo, dev);
      snd_pcm_info_set_subdevice(pcminfo, 0);
      snd_pcm_info_set_stream(pcminfo, SND_PCM_STREAM_CAPTURE);

      err := snd_ctl_pcm_info(handle, pcminfo);
      if err < 0 then begin
        if err <> -ENOENT then
          error('control digital audio info (%d): %s',[card, snd_strerror(err)]);
        continue;
      end;

      Devices.Values[Format('card %d: %s [%s], device %d: %s [%s]',[
        card, snd_ctl_card_info_get_id(info), snd_ctl_card_info_get_name(info),
        dev,
        snd_pcm_info_get_id(pcminfo),
        snd_pcm_info_get_name(pcminfo)
      ])] := Format('hw:%d',[card]);

      count := snd_pcm_info_get_subdevices_count(pcminfo);

      //Devices.Add(Format('  Subdevices: %d/%d', [snd_pcm_info_get_subdevices_avail(pcminfo), count]));

      for idx := 0 to LongInt(count) - 1 do begin
        snd_pcm_info_set_subdevice(pcminfo, idx);

        err := snd_ctl_pcm_info(handle, pcminfo);
        if err < 0 then begin
          error('control digital audio playback info (%d): %s',[card, snd_strerror(err)]);
        end else begin
          Devices.Values[Format('  Subdevice #%d: %s', [idx, snd_pcm_info_get_subdevice_name(pcminfo)])] := Format('hw:%d,%d',[card,idx]);
        end;
      end;
    end;

    snd_ctl_close(handle);
next_card:
    if snd_card_next(@card) < 0 then begin
      error('snd_card_next');
      break;
    end;
  end;

  snd_ctl_card_info_free(info);
  snd_pcm_info_free(pcminfo);
  Result := true;
end;

function GetLastErrorMsg: String;
begin
  Result := LastErrorMsg;
end;

initialization
  LastErrorMsg := '';

end.

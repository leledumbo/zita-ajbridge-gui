{  Free Pascal port by Nikolay Nikolov <nickysn@users.sourceforge.net>  }

{**
 * \file include/pcm.h
 * \brief Application interface library for the ALSA driver
 * \author Jaroslav Kysela <perex@perex.cz>
 * \author Abramo Bagnara <abramo@alsa-project.org>
 * \author Takashi Iwai <tiwai@suse.de>
 * \date 1998-2001
 *
 * Application interface library for the ALSA driver.
 * See the \ref pcm page for more details.
 *}
{*
 *   This library is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Lesser General Public License as
 *   published by the Free Software Foundation; either version 2.1 of
 *   the License, or (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Lesser General Public License for more details.
 *
 *   You should have received a copy of the GNU Lesser General Public
 *   License along with this library; if not, write to the Free Software
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
 *
 *}

function snd_pcm_abort(pcm: Psnd_pcm_t): cint; inline;
begin
  Result := snd_pcm_set_nonblock(pcm, 2);
end;

procedure snd_pcm_pack_audio_tstamp_config(data: Pcuint;
                        config: Psnd_pcm_audio_tstamp_config_t); inline;
begin
  data^ := (config^.report_delay shl 4) or config^.type_requested;
end;

procedure snd_pcm_unpack_audio_tstamp_report(data: cuint; accuracy: cuint;
                        report: Psnd_pcm_audio_tstamp_report_t); inline;
begin
  data := data shr 16;
  with report^ do
  begin
    valid := data and 1;
    actual_type := (data shr 1) and $F;
    accuracy_report := (data shr 5) and 1;
    accuracy := accuracy;
  end;
end;

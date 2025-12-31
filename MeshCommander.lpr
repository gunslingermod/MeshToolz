program MeshCommander;

uses CommandsParser, sysutils, commandsstorage, CommandsHelpers, TempBuffer, interfaces;

var
  g_models_slots:TSlotsContainer;

function ExecuteCmd(cmd:string):string;
var
  s:TModelSlot;
  tmpstr:string;
  cmdres:TCommandResult;
begin
  result:='';
  tmpstr:='';
  s:=g_models_slots.TryGetSlotRefByString(cmd, tmpstr);
  if s=nil then begin
    result:='!slot not recognized';
    exit;
  end;
  cmdres:=s.ExecuteCmd(tmpstr);
  result:=cmdres.GetDescription();
  if not cmdres.IsSuccess() then begin
    result:='!'+result;
  end else if cmdres.IsWarning() then begin
    result:='#'+result;
  end;
end;

function TryLoadOgf(filename:string):boolean;
var
  cmdres:TCommandResult;
begin
  cmdres:=g_models_slots.GetModelSlotById(0).ExecuteCmd(':loadfromfile('+filename+')');
  result:=cmdres.IsSuccess();
end;

procedure ProcessScriptFile(filename:string);
var
  f:textfile;
  cmd, res:string;
  lineid:integer;
begin
  assignfile(f, filename);
  reset(f);
  lineid:=0;
  try
    while not eof(f) do begin
      readln(f, cmd);
      lineid:=lineid+1;

      res:=TrimLeft(cmd);
      if length(cmd)=0 then continue;
      if (length(cmd)>=2) and (cmd[1]='/') and (cmd[2]='/') then continue;

      res:=ExecuteCmd(cmd);

      if length(res)>0 then begin
        if res[1] = '!' then begin
          writeln('ERROR (line '+inttostr(lineid)+') : ', PAnsiChar(@res[2]));
          break;
        end else if res[1] = '#'  then begin
          writeln('WARNING (line '+inttostr(lineid)+') : ', PAnsiChar(@res[2]));
        end else begin
          writeln(res);
        end;
      end;
    end;
  finally
    closefile(f);
  end;
end;

var
  cmd, res:string;
begin
  g_models_slots:=TSlotsContainer.Create();
  cmd:='';
  DecimalSeparator{%H-} := '.';

  writeln('OGFCommander by GUNSLINGER Mod Team');
  writeln('Build: '+{$INCLUDE %DATE%});
  writeln;

  if ParamCount > 0 then begin
    if TryLoadOgf(ParamStr(1)) then begin
      writeln('Loaded model file '+ParamStr(1));
    end else begin
      ProcessScriptFile(ParamStr(1));
      exit;
    end;
  end;

  try
    if length(cmd)=0 then begin
      write('>> ');
      readln(cmd);
    end;

    repeat
      if length(trim(cmd)) > 0 then begin
        res:=ExecuteCmd(cmd);
        if length(res)>0 then begin
          if res[1] = '!' then begin
            writeln('ERROR: ', PAnsiChar(@res[2]));
          end else if res[1] = '#'  then begin
            writeln('WARNING: ', PAnsiChar(@res[2]));
          end else begin
            writeln(res);
          end;
        end;
      end;
      write('>> ');
      readln(cmd);
    until (cmd = 'quit');
  finally
    g_models_slots.Free;
  end;
end.


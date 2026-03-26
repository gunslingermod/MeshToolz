program MeshCommander;

uses CommandsParser, sysutils, commandsstorage, CommandsHelpers, TempBuffer,
  interfaces, selectionarea, variables;

var
  g_models_slots:TSlotsContainer;
  g_vars:TCommanderVarStorage;

function preprocess_cmd(cmd:string; var preprocessed_out:string):boolean;
var
  i:integer;
  in_var:boolean;
  varname, vartext:string;
  c:char;
begin
  result:=false;
  in_var:=false;
  varname:='';
  for i:=1 to length(cmd) do begin
    c:=cmd[i];
    if c = '%' then begin
      if in_var then begin
        if length(varname)=0 then begin
          preprocessed_out:=preprocessed_out+'%';
          in_var:=false;
        end else if g_vars.GetStringValue(varname, vartext) then begin
          preprocessed_out:=preprocessed_out+vartext;
          in_var:=false;
        end else begin
          break;
        end;
      end else begin
        varname:='';
        in_var := true;
      end;
    end else begin
      if not in_var then begin
        preprocessed_out:=preprocessed_out+c;
      end else begin
        varname:=varname+c;
      end;
    end;
  end;

  result:=not in_var;
end;

function ExecuteCmd(cmd:string):string;
var
  s:TModelSlot;
  tmpstr, varname, varval:string;
  cmd_preprocessed:string;
  cmdres:TCommandResult;
  sep:integer;
const
  CMD_SET_VAR = 'set ';
  CMD_SET_CONST = 'const ';
  CMD_UNSET_VAR = 'unset ';
begin
  result:='';
  tmpstr:='';
  cmd_preprocessed:='';
  if not preprocess_cmd(cmd, cmd_preprocessed) then begin
    result:='!command preprocessing failed';
  end else if leftstr(cmd_preprocessed, length(CMD_SET_VAR)) = CMD_SET_VAR then begin
    cmd_preprocessed:=trim(rightstr(cmd_preprocessed, length(cmd_preprocessed)-length(CMD_SET_VAR)));
    sep:=pos('=', cmd_preprocessed);
    if sep <= 0 then begin
      result:='!can''t extract variable value';
    end else begin
      varname:=trim(leftstr(cmd_preprocessed, sep-1));
      varval:=trim(rightstr(cmd_preprocessed, length(cmd_preprocessed)-sep));
      if not g_vars.SetStringVar(varname, varval) then begin
        result:='!can''t set value "'+varval+'" for variable "'+varname+'"';
      end;
    end;
  end else if leftstr(cmd_preprocessed, length(CMD_SET_CONST)) = CMD_SET_CONST then begin
    cmd_preprocessed:=trim(rightstr(cmd_preprocessed, length(cmd_preprocessed)-length(CMD_SET_CONST)));
    sep:=pos('=', cmd_preprocessed);
    if sep <= 0 then begin
      result:='!can''t extract constant value';
    end else begin
      varname:=trim(leftstr(cmd_preprocessed, sep-1));
      varval:=trim(rightstr(cmd_preprocessed, length(cmd_preprocessed)-sep));
      if not g_vars.SetStringConst(varname, varval) then begin
        result:='!can''t set value "'+varval+'" for constant "'+varname+'"';
      end;
    end;
  end else if leftstr(cmd_preprocessed, length(CMD_UNSET_VAR)) = CMD_UNSET_VAR then begin
    cmd_preprocessed:=trim(rightstr(cmd_preprocessed, length(cmd_preprocessed)-length(CMD_SET_VAR)));
    if not g_vars.ResetVar(cmd_preprocessed) then begin
      result:='!variable unset failed';
    end;
  end else begin
    s:=g_models_slots.TryGetSlotRefByString(cmd_preprocessed, tmpstr);
    if s=nil then begin
      result:='!slot not recognized';
    end else begin
      cmdres:=s.ExecuteCmd(tmpstr);
      result:=cmdres.GetDescription();
      if not cmdres.IsSuccess() then begin
        result:='!'+result;
      end else if cmdres.IsWarning() then begin
        result:='#'+result;
      end;
    end;
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
  g_vars:=TCommanderVarStorage.Create();
  g_models_slots:=TSlotsContainer.Create();
  cmd:='';
  DecimalSeparator{%H-} := '.';

  writeln('OGFCommander by Sin!');
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
    g_vars.Free;
  end;
end.


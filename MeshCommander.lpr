program MeshCommander;

uses CommandsParser, sysutils;

var
  g_models_slots:TSlotsContainer;

function ExecuteCmd(cmd:string):string;
var
  s:TModelSlot;
  tmpstr:string;
begin
  result:='';
  tmpstr:='';
  s:=g_models_slots.TryGetSlotRefByString(cmd, tmpstr);
  if s=nil then begin
    result:='!slot not recognized';
    exit;
  end;
  result:=s.ExecuteCmd(tmpstr);
end;

var
  cmd, res:string;
begin
  g_models_slots:=TSlotsContainer.Create();
  cmd:='';
  DecimalSeparator{%H-} := '.';

  writeln('OGFCommander by GUNSLINGER Mod team');
  writeln;

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
            writeln('ERROR:', PAnsiChar(@res[2]));
          end else if res[1] = '#'  then begin
            writeln('WARNING:', PAnsiChar(@res[2]));
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


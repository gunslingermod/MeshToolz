unit variables;

{$mode ObjFPC}{$H+}

interface

type
TCommanderVarType = (CommanderVarTypeNone, CommanderVarTypeString);

TCommanderVar = record
  is_const:boolean;
  vartype:TCommanderVarType;
  name:string;
  value:string;
end;

{ TCommanderVarStorage }

TCommanderVarStorage = class
protected
  _vars:array of TCommanderVar;
  function _FindVarByName(name:string):integer;
public
  constructor Create;
  destructor Destroy; override;

  function SetStringVar(name:string; value:string):boolean;
  function SetStringConst(name:string; value:string):boolean;
  function ResetVar(name:string):boolean;
  function GetStringValue(name:string; var value:string):boolean;
end;


implementation

{ TCommanderVarStorage }

function TCommanderVarStorage._FindVarByName(name: string): integer;
var
  i:integer;
begin
  result:=-1;
  for i:=0 to length(_vars)-1 do begin
    if name = _vars[i].name then begin
      result:=i;
      break;
    end;
  end;
end;

constructor TCommanderVarStorage.Create;
begin
  setlength(_vars, 0);
end;

destructor TCommanderVarStorage.Destroy;
begin
  setlength(_vars, 0);
  inherited Destroy;
end;

function TCommanderVarStorage.SetStringVar(name: string; value: string): boolean;
var
  idx:integer;
begin
  result:=false;
  idx:=_FindVarByName(name);
  if idx < 0 then begin
    idx:=length(_vars);
    setlength(_vars, idx+1);
    _vars[idx].name:=name;
    _vars[idx].is_const:=false;
    _vars[idx].value:=value;
    _vars[idx].vartype:=CommanderVarTypeString;
    result:=true;
  end else if not _vars[idx].is_const then begin
    _vars[idx].value:=value;
    _vars[idx].vartype:=CommanderVarTypeString;
    result:=true;
  end;
end;

function TCommanderVarStorage.SetStringConst(name: string; value: string): boolean;
var
  idx:integer;
begin
  result:=false;
  idx:=_FindVarByName(name);
  if idx < 0 then begin
    idx:=length(_vars);
    setlength(_vars, idx+1);
    _vars[idx].name:=name;
    _vars[idx].is_const:=true;
    _vars[idx].value:=value;
    _vars[idx].vartype:=CommanderVarTypeString;
    result:=true;
  end;
end;

function TCommanderVarStorage.ResetVar(name: string): boolean;
var
  idx:integer;
begin
  result:=false;
  idx:=_FindVarByName(name);
  if (idx >= 0) and (not _vars[idx].is_const) then begin
    _vars[idx].vartype:=CommanderVarTypeNone;
    result:=true;
  end;
end;

function TCommanderVarStorage.GetStringValue(name: string; var value: string): boolean;
var
  idx:integer;
begin
  result:=false;
  idx:=_FindVarByName(name);
  if idx >= 0 then begin
    value:=_vars[idx].value;
    result:=true;
  end;
end;

end.


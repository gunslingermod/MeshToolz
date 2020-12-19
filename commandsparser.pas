unit CommandsParser;

{$mode objfpc}{$H+}

interface

uses
  ogf_parser;

type
TModelSlotsContainer = class;

TSlotId = integer;

{ TModelSlot }

TModelSlot = class
  _data:TOgfParser;
  _id:TSlotId;
  _container:TModelSlotsContainer;

  function _CmdStatus():string;
  function _CmdLoadFromFile(path:string):string;
  function _CmdSaveToFile(path:string):string;
  function _CmdUnload(path:string):string;
public
  constructor Create(id:TSlotId; container:TModelSlotsContainer);
  destructor Destroy; override;
  function Id():TSlotId;

  function ExecuteCmd(cmd:string):string;
end;

{ TModelSlotsContainer }

TModelSlotsContainer = class
  _slots:array of TModelSlot;
public
  constructor Create();
  destructor Destroy(); override;
  function GetSlotById(id:TSlotId):TModelSlot;
  function TryGetSlotRefByString(in_string:string; var rest_string:string):TModelSlot;
end;

implementation
uses sysutils, strutils;

function IsNumberChar(chr:AnsiChar):boolean;
begin
  result:= (chr >= '0') and (chr <= '9');
end;

function IsAlphabeticChar(chr:AnsiChar):boolean;
begin
  result:= ((chr >= 'a') and (chr <= 'z')) or ((chr >= 'A') and (chr <= 'Z'));
end;

function ExtractAlphabeticString(var inoutstr:string):string;
begin
  inoutstr:=TrimLeft(inoutstr);
  result:='';
  while (length(inoutstr) > 0) and (IsAlphabeticChar(inoutstr[1])) do begin
    result:=result+inoutstr[1];
    inoutstr:=rightstr(inoutstr, length(inoutstr)-1);
  end;
end;

function ExtractProcArgs(instr:string; var args:string):boolean;
begin
  result:=false;
  instr:=trim(instr);
  if (length(instr)<2) or (instr[1]<>'(') or (instr[length(instr)]<>')') then exit;

  args:=midstr(instr, 2, length(instr)-2);
  result:=true;
end;

function ExtractNumericString(var inoutstr:string):string;
begin
  inoutstr:=TrimLeft(inoutstr);
  result:='';
  while (length(inoutstr) > 0) and (IsNumberChar(inoutstr[1])) do begin
    result:=result+inoutstr[1];
    inoutstr:=rightstr(inoutstr, length(inoutstr)-1);
  end;
end;

{ TModelSlot }

function TModelSlot._CmdStatus(): string;
begin
  if not _data.Loaded then begin
    result:='slot doesn''t contain loaded data';
  end else begin
    result:='slot is in use';
  end;
end;

function TModelSlot._CmdLoadFromFile(path: string): string;
begin
  if _data.Loaded() then begin
    result:='!Slot is not empty. Unload data first';
    exit;
  end;

  if _data.LoadFromFile(path) then begin
    result:='';
  end else begin
    result:='!Can''t load model from file "'+path+'"';
  end;
end;

function TModelSlot._CmdSaveToFile(path: string): string;
begin
  result:='';

  if not _data.Loaded() then begin
    result:='!Slot is empty';
    exit;
  end;

  if not _data.SaveToFile(path) then begin
    result:='!Can''t save model to "'+path+'"';
  end;
end;

function TModelSlot._CmdUnload(path: string): string;
begin
  if not _data.Loaded() then begin
    result:='!Slot is empty';
    exit;
  end;

  _data.Reset;
  result:='';
end;

constructor TModelSlot.Create(id: TSlotId; container: TModelSlotsContainer);
begin
  _id:=id;
  _data:=TOgfParser.Create();
  _container:=container;
end;

destructor TModelSlot.Destroy;
begin
  _data.Free();
  inherited Destroy;
end;

function TModelSlot.Id(): TSlotId;
begin
  result:=_id;
end;

function TModelSlot.ExecuteCmd(cmd: string): string;
const
  PROC_LOADFROMFILE:string='loadfromfile';
  PROC_SAVETOFILE:string='savetofile';
  PROC_UNLOAD:string='unload';
  PROC_INFO:string='info';
var
  args:string;
  opcode:char;
  proccode:string;
begin
  cmd:=TrimLeft(cmd);
  if length(trim(cmd))=0 then begin
    result:=_CmdStatus();
    exit;
  end;

  args:='';
  opcode:=cmd[1];
  cmd:=rightstr(cmd, length(cmd)-1);

  if opcode = '.' then begin
    proccode:=ExtractAlphabeticString(cmd);
    if not ExtractProcArgs(cmd, args) then begin
      result:='!can''t parse arguments to call procedure "'+proccode+'"';
    end else if lowercase(proccode)=PROC_LOADFROMFILE then begin
      result:=_CmdLoadFromFile(args);
    end else if lowercase(proccode)=PROC_SAVETOFILE then begin
      result:=_CmdSaveToFile(args);
    end else if lowercase(proccode)=PROC_UNLOAD then begin
      result:=_CmdUnload(args);
    end else if lowercase(proccode)=PROC_INFO then begin
      result:=_CmdStatus();
    end else begin
      result:='!can''t find procedure "'+proccode+'"';
    end;
  end else begin
    result:='!slot does not support requested operation';
  end;
end;

{ TModelSlotsContainer }

constructor TModelSlotsContainer.Create();
begin
  setlength(_slots, 0);
end;

destructor TModelSlotsContainer.Destroy();
var
  i:integer;
begin
  for i:=0 to length(_slots)-1 do begin
    _slots[i].Free;
  end;
  setlength(_slots, 0);
  inherited Destroy();
end;

function TModelSlotsContainer.GetSlotById(id: TSlotId): TModelSlot;
var
  i:integer;
begin
   for i:=0 to length(_slots)-1 do begin
     if _slots[i].Id() = id then begin
       result:=_slots[i];
       exit;
     end;
   end;

   setlength(_slots, length(_slots)+1);
   result:=TModelSlot.Create(id, self);
   _slots[length(_slots)-1]:=result;
end;

function TModelSlotsContainer.TryGetSlotRefByString(in_string: string; var rest_string: string): TModelSlot;
const
  SLOT_REF_KEY='model';
var
  id_str:string;
  idx:integer;
begin
  result:=nil;
  in_string:=TrimLeft(in_string);
  if leftstr(in_string, length(SLOT_REF_KEY))=SLOT_REF_KEY then begin
    rest_string:=TrimLeft(rightstr(in_string, length(in_string)-length(SLOT_REF_KEY)));
    id_str:=ExtractNumericString(rest_string);
    id_str:='0'+id_str;
    idx:=strtointdef(id_str, 0);
    result:=GetSlotById(idx)
  end;
end;

end.


unit CommandsParser;

{$mode objfpc}{$H+}

interface

uses
  ogf_parser;

type
TSlotsContainer = class;

TSlotId = integer;

TTempBufferType = (TTempTypeNone, TTempTypeString);

{ TTempBuffer }

TTempBuffer = class
  _cur_type:TTempBufferType;
  _buffer_string:string;
public
  constructor Create;
  destructor Destroy; override;

  procedure Clear();
  function GetCurrentType():TTempBufferType;
  function GetString(var outstr:string):boolean;
  procedure SetString(s:string);
end;

{ TModelSlot }

TModelSlot = class
  _data:TOgfParser;
  _id:TSlotId;
  _container:TSlotsContainer;

  function _CmdInfo():string;
  function _CmdLoadFromFile(path:string):string;
  function _CmdSaveToFile(path:string):string;
  function _CmdUnload():string;

  function _ProcessChildrenCommands(child_id:integer; cmd:string):string;
  function _CmdChildInfo(child_id:integer):string;
public
  constructor Create(id:TSlotId; container:TSlotsContainer);
  destructor Destroy; override;
  function Id():TSlotId;

  function ExecuteCmd(cmd:string):string;
end;

{ TSlotsContainer }

TSlotsContainer = class
  _model_slots:array of TModelSlot;
  _temp_buffer:TTempBuffer;
public
  constructor Create();
  destructor Destroy(); override;
  function GetModelSlotById(id:TSlotId):TModelSlot;
  function GetTempBuffer():TTempBuffer;
  function TryGetSlotRefByString(in_string:string; var rest_string:string):TModelSlot;
end;

implementation
uses sysutils, strutils;

const
  OPCODE_CALL:char=':';
  OPCODE_INDEX:char='.';

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

{ TTempBuffer }

constructor TTempBuffer.Create;
begin
  Clear();
end;

destructor TTempBuffer.Destroy;
begin
  inherited Destroy;
end;

procedure TTempBuffer.Clear();
begin
  _cur_type:=TTempTypeNone;
end;

function TTempBuffer.GetCurrentType(): TTempBufferType;
begin
  result:=_cur_type;
end;

function TTempBuffer.GetString(var outstr: string): boolean;
begin
  if _cur_type = TTempTypeString then begin
    result:=true;
    outstr:=_buffer_string;
  end else begin
    result:=false;
  end;
end;

procedure TTempBuffer.SetString(s: string);
begin
  _cur_type:=TTempTypeString;
  _buffer_string:=s;
end;

{ TModelSlot }

function TModelSlot._CmdInfo(): string;
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

function TModelSlot._CmdUnload(): string;
begin
  if not _data.Loaded() then begin
    result:='!Slot is empty';
    exit;
  end;

  _data.Reset;
  result:='';
end;

function TModelSlot._ProcessChildrenCommands(child_id: integer; cmd: string): string;
var
  opcode:char;
  args:string;
  proccode:string;
const
  PROC_INFO:string='info';
begin
  if not _data.Loaded() then begin
    result:='!please load model first';
  end else if abs(child_id) >= _data.GetChildrenCount() then begin
    result:='!child id #'+inttostr(child_id)+' out of bounds, total children count: '+inttostr(_data.GetChildrenCount());
  end else begin
    if child_id < 0 then begin
      child_id:=_data.GetChildrenCount() - child_id;
    end;

    if length(trim(cmd))=0 then begin
      result:=_CmdChildInfo(child_id);
    end else begin
      args:='';
      opcode:=cmd[1];
      cmd:=rightstr(cmd, length(cmd)-1);

      if opcode = OPCODE_CALL then begin
        proccode:=ExtractAlphabeticString(cmd);
        if not ExtractProcArgs(cmd, args) then begin
          result:='!can''t parse arguments to call procedure "'+proccode+'"';
        end else if lowercase(proccode)=PROC_INFO then begin
          result:=_CmdChildInfo(child_id);
        end else begin
          result:='!unknown procedure "'+proccode+'"';
        end;
      end else begin
        result:='!unsupported opcode "'+opcode+'"';
      end;
    end;
  end;
end;

function TModelSlot._CmdChildInfo(child_id: integer): string;
begin
  if not _data.Loaded() then begin
    result:='!please load model first';
  end else if child_id >= _data.GetChildrenCount() then begin
    result:='!child id #'+inttostr(child_id)+' out of bounds, total children count: '+inttostr(_data.GetChildrenCount());
  end else begin
    result:='Info for child #'+inttostr(child_id)+':'+chr($0d)+chr($0a);
    result:=result+'Texture: '+_data.GetChild(child_id).GetTextureData().texture+chr($0d)+chr($0a);
    result:=result+'Shader: '+_data.GetChild(child_id).GetTextureData().shader+chr($0d)+chr($0a);
    result:=result+'Vertices count:'+inttostr(_data.GetChild(child_id).GetVerticesCount())+chr($0d)+chr($0a);
    result:=result+'Tris count:'+inttostr(_data.GetChild(child_id).GetTrisCountTotal())+chr($0d)+chr($0a);
    result:=result+'Current link type:'+inttostr(_data.GetChild(child_id).GetCurrentLinkType())+chr($0d)+chr($0a);
  end;
end;

constructor TModelSlot.Create(id: TSlotId; container: TSlotsContainer);
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

  PROP_CHILD:string='child';
var
  args:string;
  opcode:char;
  proccode, propname:string;
  i:integer;
begin
  cmd:=TrimLeft(cmd);
  if length(trim(cmd))=0 then begin
    result:=_CmdInfo();
    exit;
  end;

  args:='';
  opcode:=cmd[1];
  cmd:=rightstr(cmd, length(cmd)-1);

  if opcode = OPCODE_CALL then begin
    proccode:=ExtractAlphabeticString(cmd);
    if not ExtractProcArgs(cmd, args) then begin
      result:='!can''t parse arguments to call procedure "'+proccode+'"';
    end else if lowercase(proccode)=PROC_LOADFROMFILE then begin
      result:=_CmdLoadFromFile(args);
    end else if not _data.Loaded() then begin
      result:='!please load model first';
    end else if lowercase(proccode)=PROC_SAVETOFILE then begin
      result:=_CmdSaveToFile(args);
    end else if lowercase(proccode)=PROC_UNLOAD then begin
      result:=_CmdUnload();
    end else if lowercase(proccode)=PROC_INFO then begin
      result:=_CmdInfo();
    end else begin
      result:='!unknown procedure "'+proccode+'"';
    end;
  end else if opcode = OPCODE_INDEX then begin
    propname:=ExtractAlphabeticString(cmd);

    if not _data.Loaded() then begin
      result:='!please load model first';
    end else if lowercase(propname)=PROP_CHILD then begin
      args:=ExtractNumericString(cmd);
      i:=strtointdef(args, -1);
      if i<0 then begin
        result:='!invalid child id "'+args+'"';
      end else begin
        result:=_ProcessChildrenCommands(i, cmd);
      end;
    end else begin
      result:='!unknown procedure "'+propname+'"';
    end;
  end else begin
    result:='!unsupported opcode "'+opcode+'"';
  end;
end;

{ TSlotsContainer }

constructor TSlotsContainer.Create();
begin
  setlength(_model_slots, 0);
  _temp_buffer:=TTempBuffer.Create();
end;

destructor TSlotsContainer.Destroy();
var
  i:integer;
begin
  _temp_buffer.Free;
  for i:=0 to length(_model_slots)-1 do begin
    _model_slots[i].Free;
  end;
  setlength(_model_slots, 0);
  inherited Destroy();
end;

function TSlotsContainer.GetModelSlotById(id: TSlotId): TModelSlot;
var
  i:integer;
begin
   for i:=0 to length(_model_slots)-1 do begin
     if _model_slots[i].Id() = id then begin
       result:=_model_slots[i];
       exit;
     end;
   end;

   setlength(_model_slots, length(_model_slots)+1);
   result:=TModelSlot.Create(id, self);
   _model_slots[length(_model_slots)-1]:=result;
end;

function TSlotsContainer.GetTempBuffer(): TTempBuffer;
begin
  result:=_temp_buffer;
end;

function TSlotsContainer.TryGetSlotRefByString(in_string: string; var rest_string: string): TModelSlot;
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
    result:=GetModelSlotById(idx)
  end;
end;

end.


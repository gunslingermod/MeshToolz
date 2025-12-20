unit CommandsParser;

{$mode objfpc}{$H+}

interface

uses
  ogf_parser, basedefs;

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
  function _CmdPasteMeshFromTempBuf():string;

  function _CmdRemoveCollapsedMeshes():string;
  function _CmdSkeletonUniformScale(cmd:string):string;

  function _CmdPropChildMesh(cmd:string):string;
  function _CmdPropSkeleton(cmd:string):string;

  function _ProcessMeshesCommands(child_id:integer; cmd:string):string;
  function _CmdMeshInfo(child_id:integer):string;
  function _CmdMeshSetTexture(child_id:integer; args:string):string;
  function _CmdMeshSetShader(child_id:integer; args:string):string;
  function _CmdMeshCopy(child_id:integer):string;
  function _CmdMeshInsert(child_id:integer):string;
  function _CmdMeshRemove(child_id:integer):string;
  function _CmdMeshMove(child_id:integer; cmd:string):string;
  function _CmdMeshScale(child_id:integer; cmd:string):string;
  function _CmdMeshRebind(child_id:integer; cmd:string):string;
  function _CmdMeshBonestats(child_id:integer):string;
  function _CmdMeshFilterBone(child_id:integer; cmd:string):string;

  function _ProcessBonesCommands(bone_id:integer; cmd:string):string;
  function _CmdBoneInfo(bone_id:integer):string;

  function _ProcessIKDataCommands(bone_id:integer; cmd:string):string;
  function _CmdIKDataInfo(bone_id:integer):string;
  function _CmdIKDataCopy(bone_id:integer):string;
  function _CmdIKDataPaste(bone_id:integer):string;

public
  constructor Create(id:TSlotId; container:TSlotsContainer);
  destructor Destroy; override;
  function Id():TSlotId;

  function ExecuteCmd(cmd:string):string;
  function ExtractBoneIdFromString(var inoutstr:string; var boneid:TBoneId):boolean;
  function GetBoneNameById(boneid:TBoneId):string;
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

  ARGUMENTS_SEPARATOR:char=',';
  ARGUMENT_INVERSE:char='!';

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

function ExtractNumericString(var inoutstr:string; allow_negative:boolean):string;
begin
  inoutstr:=TrimLeft(inoutstr);
  result:='';

  if allow_negative and (length(inoutstr) > 0) and (inoutstr[1]='-') then begin
    result:=result+'-';
    inoutstr:=rightstr(inoutstr, length(inoutstr)-1);
  end;

  while (length(inoutstr) > 0) and (IsNumberChar(inoutstr[1])) do begin
    result:=result+inoutstr[1];
    inoutstr:=rightstr(inoutstr, length(inoutstr)-1);
  end;
end;

function ExtractFloatFromString(var inoutstr:string; var fout:single):boolean;
var
  separator_found:boolean;
  tmpstr, numstr:string;
  sign:single;
const
  SEPARATOR:char='.';
begin
  result:=false;
  tmpstr:=TrimLeft(inoutstr);
  if length(tmpstr) = 0 then exit;

  if tmpstr[1]='-' then begin
    sign:=-1;
    tmpstr:=TrimLeft(rightstr(tmpstr, length(tmpstr)-1));
    if length(tmpstr) = 0 then exit;
  end else begin
    sign:=1;
  end;
  if length(tmpstr) = 0 then exit;

  separator_found:=false;
  numstr:='';
  while (length(tmpstr) > 0) and (IsNumberChar(tmpstr[1]) or ((tmpstr[1] = SEPARATOR) and (separator_found = false)) ) do begin
    if (tmpstr[1] = SEPARATOR) then begin
      separator_found:=true;
    end;
    numstr:=numstr+tmpstr[1];
    tmpstr:=rightstr(tmpstr, length(tmpstr)-1);
  end;

  try
    fout:=sign*strtofloat(numstr);
    inoutstr:=tmpstr;
    result:=true;
  except
    result:=false;
  end;
end;

function ExtractABNString(var inoutstr:string):string;
begin
  inoutstr:=TrimLeft(inoutstr);
  result:='';
  while (length(inoutstr) > 0) and (IsAlphabeticChar(inoutstr[1]) or IsNumberChar(inoutstr[1]) or (inoutstr[1]='_')) do begin
    result:=result+inoutstr[1];
    inoutstr:=rightstr(inoutstr, length(inoutstr)-1);
  end;
end;

function SplitString(instr:string; var out_left:string; var out_right:string; sep:char):boolean;
var
  i:integer;
begin
  result:=false;
  i:=Pos(sep, instr);
  if i > 0 then begin
    result:=true;
    out_left:=leftstr(instr, i-1);
    out_right:=rightstr(instr, length(instr)-i);
  end;
end;

function ExtractFVector3(var inoutstr:string; var v:FVector3):boolean;
var
  tmpstr:string;
  tmpv:FVector3;
begin
  result:=false;
  set_zero(tmpv{%H-});
  tmpstr:=trimleft(inoutstr);

  if not ExtractFloatFromString(tmpstr, tmpv.x) then exit;
  tmpstr:=trimleft(tmpstr);
  if (length(tmpstr)=0) or (tmpstr[1]<>ARGUMENTS_SEPARATOR) then exit;
  tmpstr:=rightstr(tmpstr, length(tmpstr)-1);

  if not ExtractFloatFromString(tmpstr, tmpv.y) then exit;
  tmpstr:=trimleft(tmpstr);
  if (length(tmpstr)=0) or (tmpstr[1]<>ARGUMENTS_SEPARATOR) then exit;
  tmpstr:=rightstr(tmpstr, length(tmpstr)-1);

  if not ExtractFloatFromString(tmpstr, tmpv.z) then exit;

  inoutstr:=tmpstr;
  v:=tmpv;
  result:=true;
end;

type
TIndexFilter = packed record
  name:string;
  value:string;
  inverse:boolean;
end;

TFilterMode = (FILTER_MODE_EXACT, FILTER_MODE_BEGINWITH);

TIndexFilters = array of TIndexFilter;

procedure InitFilters(var f:TIndexFilters);
begin
  setlength(f, 0);
end;

procedure PushFilter(var f:TIndexFilters; name:string; defval:string='');
var
  l:integer;
begin
  l:=length(f);
  setlength(f, l+1);
  f[l].name:=name;
  f[l].value:=defval;
end;

function IsMatchFilter(str:string; filter:TIndexFilter; mode:TFilterMode):boolean;
begin
  result:=false;
  case mode of
    FILTER_MODE_EXACT: result:=(length(filter.value)=0) or (str = filter.value);
    FILTER_MODE_BEGINWITH: result:=(length(filter.value)=0) or (leftstr(str, length(filter.value)) = filter.value);
  end;
  if filter.inverse then result:=not result;
end;

procedure ClearFilters(var f:TIndexFilters);
begin
  setlength(f, 0);
end;

function ExtractIndexFilter(var inoutstr:string; var filters:TIndexFilters; var filters_count:integer):boolean;
var
  filters_str:string;
  rest_part:string;
  filter_name, filter_value:string;
  tmp, i:integer;
  inverse:boolean;
begin
  result:=false;
  inoutstr:=trim(inoutstr);
  filters_str:='';
  rest_part:='';
  if (length(inoutstr) < 2) or (inoutstr[1]<>'[') or not SplitString(inoutstr, filters_str, rest_part, ']') then exit;
  result:=true;
  inoutstr:=rest_part;
  filters_count:=0;
  filters_str:=trimleft(rightstr(filters_str, length(filters_str)-1));
  while (filters_count>=0) and (length(filters_str)>0) do begin
    tmp:=filters_count;
    filters_count:=-1;

    // Extract filter name
    filters_str:=TrimLeft(filters_str);
    filter_name:=ExtractABNString(filters_str);
    filters_str:=TrimLeft(filters_str);
    if (length(filter_name) = 0) or (length(filters_str)=0) or ((filters_str[1]<>':') and (filters_str[1]<>ARGUMENT_INVERSE)) then break;

    inverse:=(filters_str[1]=ARGUMENT_INVERSE);

    // Get rid of ':'
    filters_str:=trimleft(rightstr(filters_str, length(filters_str)-1));
    if (length(filters_str) = 0) then break;

    // Extract filter value
    filter_value:='';
    if not SplitString(filters_str, filter_value, rest_part, ',') then begin
      filter_value:=filters_str;
      filters_str:='';
    end else begin
      filters_str:=trimleft(rest_part);
    end;

    // Find filter by extracted name and set extracted value to filter
    for i:=0 to length(filters)-1 do begin
      if filters[i].name = filter_name then begin
        filters[i].value:=filter_value;
        filters[i].inverse:=inverse;
        filter_name:='';
        filter_value:='';
      end;
    end;

    if length(filter_name) = 0 then begin
      // All seems to be OK
      filters_count:=tmp+1;
    end else begin
      // Filter not found, exiting
      filters_count:=-1;
      break;
    end;
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

/////////////////////////////////// COMMON /////////////////////////////////////

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

/////////////////////////////////// MESHES /////////////////////////////////////

function TModelSlot._ProcessMeshesCommands(child_id: integer; cmd: string): string;
var
  opcode:char;
  args:string;
  proccode:string;
const
  PROC_INFO:string='info';
  PROC_SETTEXTURE:string='settexture';
  PROC_SETSHADER:string='setshader';
  PROC_REMOVE:string='remove';
  PROC_COPY:string='copy';
  PROC_PASTE:string='paste';
  PROC_MOVE:string='move';
  PROC_SCALE:string='scale'; //mirror if negative
  PROC_REBIND:string='rebind';
  PROC_BONESTATS:string='bonestats';
  PROC_FILTERBONE:string='filterbone';
  PROC_CHANGELINK:string='changelinktype';
  PROC_GETOPTIMALLINKTYPE:string='getoptimallinktype';
begin
  if (not _data.Loaded()) or (_data.Meshes()=nil) then begin
    result:='!please load model first';
  end else if abs(child_id) >= _data.Meshes().Count() then begin
    result:='!child id #'+inttostr(child_id)+' out of bounds, total children count: '+inttostr(_data.Meshes().Count());
  end else begin
    if child_id < 0 then begin
      child_id:=_data.Meshes().Count() - child_id;
    end;

    if length(trim(cmd))=0 then begin
      result:=_CmdMeshInfo(child_id);
    end else begin
      args:='';
      opcode:=cmd[1];
      cmd:=rightstr(cmd, length(cmd)-1);

      if opcode = OPCODE_CALL then begin
        proccode:=ExtractAlphabeticString(cmd);
        if not ExtractProcArgs(cmd, args) then begin
          result:='!can''t parse arguments to call procedure "'+proccode+'"';
        end else if lowercase(proccode)=PROC_INFO then begin
          result:=_CmdMeshInfo(child_id);
        end else if lowercase(proccode)=PROC_SETTEXTURE then begin
          result:=_CmdMeshSetTexture(child_id, args);
        end else if lowercase(proccode)=PROC_SETSHADER then begin
          result:=_CmdMeshSetShader(child_id, args);
        end else if lowercase(proccode)=PROC_REMOVE then begin
          result:=_CmdMeshRemove(child_id);
        end else if lowercase(proccode)=PROC_COPY then begin
          result:=_CmdMeshCopy(child_id);
        end else if lowercase(proccode)=PROC_PASTE then begin
          result:=_CmdMeshInsert(child_id);
        end else if lowercase(proccode)=PROC_MOVE then begin
          result:=_CmdMeshMove(child_id, args);
        end else if lowercase(proccode)=PROC_SCALE then begin
          result:=_CmdMeshScale(child_id, args);
        end else if lowercase(proccode)=PROC_REBIND then begin
          result:=_CmdMeshRebind(child_id, args);
        end else if lowercase(proccode)=PROC_BONESTATS then begin
          result:=_CmdMeshBonestats(child_id);
        end else if lowercase(proccode)=PROC_FILTERBONE then begin
          result:=_CmdMeshFilterBone(child_id, args);
        end else begin
          result:='!unknown procedure "'+proccode+'"';
        end;
      end else begin
        result:='!unsupported opcode "'+opcode+'"';
      end;
    end;
  end;
end;

function TModelSlot._CmdMeshInfo(child_id: integer): string;
begin
  if not _data.Loaded() or (_data.Meshes()=nil) then begin
    result:='!please load model first';
  end else if child_id >= _data.Meshes().Count() then begin
    result:='!child id #'+inttostr(child_id)+' out of bounds, total children count: '+inttostr(_data.Meshes().Count());
  end else begin
    result:='Info for child mesh #'+inttostr(child_id)+':'+chr($0d)+chr($0a);
    result:=result+'- Texture: '+_data.Meshes.Get(child_id).GetTextureData().texture+chr($0d)+chr($0a);
    result:=result+'- Shader: '+_data.Meshes.Get(child_id).GetTextureData().shader+chr($0d)+chr($0a);
    result:=result+'- Vertices count:'+inttostr(_data.Meshes.Get(child_id).GetVerticesCount())+chr($0d)+chr($0a);
    result:=result+'- Tris count:'+inttostr(_data.Meshes.Get(child_id).GetTrisCountTotal())+chr($0d)+chr($0a);
    result:=result+'- Current link type:'+inttostr(_data.Meshes.Get(child_id).GetCurrentLinkType())+chr($0d)+chr($0a);
  end;
end;

function TModelSlot._CmdMeshSetTexture(child_id: integer; args: string): string;
var
  texdata:TOgfTextureData;
  shader, texture:string;
begin
  if not _data.Loaded() or (_data.Meshes()=nil) then begin
    result:='!please load model first';
  end else if child_id >= _data.Meshes().Count() then begin
    result:='!child id #'+inttostr(child_id)+' out of bounds, total children count: '+inttostr(_data.Meshes().Count());
  end else begin
    shader:=_data.Meshes().Get(child_id).GetTextureData().shader;
    texture:=_data.Meshes().Get(child_id).GetTextureData().texture;
    texdata:=_data.Meshes().Get(child_id).GetTextureData();
    texdata.texture:=trim(args);
    if _data.Meshes().Get(child_id).SetTextureData(texdata) then begin
      result:='texture successfully updated for mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+')';
    end else begin
      result:='!can''t update texture for mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+')';
    end;
  end;
end;

function TModelSlot._CmdMeshSetShader(child_id: integer; args: string): string;
var
  texdata:TOgfTextureData;
  shader, texture:string;
begin
  if not _data.Loaded() or (_data.Meshes()=nil) then begin
    result:='!please load model first';
  end else if child_id >= _data.Meshes().Count() then begin
    result:='!child id #'+inttostr(child_id)+' out of bounds, total children count: '+inttostr(_data.Meshes().Count());
  end else begin
    shader:=_data.Meshes().Get(child_id).GetTextureData().shader;
    texture:=_data.Meshes().Get(child_id).GetTextureData().texture;
    texdata:=_data.Meshes().Get(child_id).GetTextureData();
    texdata.shader:=trim(args);
    if _data.Meshes().Get(child_id).SetTextureData(texdata) then begin
      result:='shader successfully updated for mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+')';
    end else begin
      result:='!can''t update shader for mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+')';
    end;
  end;
end;

function TModelSlot._CmdMeshCopy(child_id: integer): string;
var
  shader, texture:string;
  s:string;
begin
  if not _data.Loaded() or (_data.Meshes()=nil) then begin
    result:='!please load model first';
  end else if child_id >= _data.Meshes().Count() then begin
    result:='!child id #'+inttostr(child_id)+' out of bounds, total children count: '+inttostr(_data.Meshes().Count());
  end else begin
    shader:=_data.Meshes().Get(child_id).GetTextureData().shader;
    texture:=_data.Meshes().Get(child_id).GetTextureData().texture;
    s:=_data.Meshes().Get(child_id).Serialize();
    if length(s) = 0 then begin
      result:='!cannot serialize mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+'), buffer cleared';
      _container.GetTempBuffer().Clear();
    end else begin
      _container.GetTempBuffer().SetString(s);
      result:='mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+') successfully saved to temp buffer';
    end;
  end;
end;

function TModelSlot._CmdMeshInsert(child_id: integer): string;
var
  s:string;
  meshid:integer;
  shader, texture:string;
begin
  if not _data.Loaded() or (_data.Meshes()=nil) then begin
    result:='!please load model first';
  end else if child_id >= _data.Meshes().Count()+1 then begin
    result:='!child id #'+inttostr(child_id)+' out of bounds, total children count: '+inttostr(_data.Meshes().Count());
  end else begin
    s:='';
    if _container.GetTempBuffer().GetString(s) then begin
      meshid:=_data.Meshes().Insert(s, child_id);
      if (meshid < 0) or (meshid<>child_id) then begin
        result:='!unable to insert data from temp buffer as a mesh';
      end else begin
        shader:=_data.Meshes().Get(meshid).GetTextureData().shader;
        texture:=_data.Meshes().Get(meshid).GetTextureData().texture;
        result:='mesh #'+inttostr(meshid)+' ('+texture+' : '+shader+') successfully inserted';
      end;
    end else begin
      result:='!can''t extract data from temp buffer, unsupported format?';
    end;
  end;
end;

function TModelSlot._CmdPasteMeshFromTempBuf(): string;
var
  s:string;
  meshid:integer;
  shader, texture:string;
begin
  if not _data.Loaded() or (_data.Meshes()=nil) then begin
    result:='!please load model first';
  end else begin
    s:='';
    if _container.GetTempBuffer().GetString(s) then begin
      meshid:=_data.Meshes().Append(s);
      if meshid < 0 then begin
        result:='!unable to append data from temp buffer as a mesh';
      end else begin
        shader:=_data.Meshes().Get(meshid).GetTextureData().shader;
        texture:=_data.Meshes().Get(meshid).GetTextureData().texture;
        result:='mesh #'+inttostr(meshid)+' ('+texture+' : '+shader+') successfully appended';
      end;
    end else begin
      result:='!can''t extract data from temp buffer, unsupported format?';
    end;
  end;
end;

function TModelSlot._CmdRemoveCollapsedMeshes(): string;
var
  i:integer;
  shader, texture:string;
begin
  if not _data.Loaded() or (_data.Meshes()=nil) then begin
    result:='!please load model first';
  end else begin
    result:='';
    for i:=_data.Meshes().Count()-1 downto 0 do begin
      shader:=_data.Meshes().Get(i).GetTextureData().shader;
      texture:=_data.Meshes().Get(i).GetTextureData().texture;

      if _data.Meshes().Get(i).GetVerticesCount() = 0 then begin;
        if not _data.Meshes().Remove(i) then begin
          result:='!'+result+'Failed to remove mesh #'+inttostr(i)+' ('+texture+' : '+shader+')'+chr($0d)+chr($0a);
        end else begin
          result:=result+'Removed collapses mesh #'+inttostr(i)+' ('+texture+' : '+shader+')'+chr($0d)+chr($0a);
        end;
      end;
    end;
  end;
end;

function TModelSlot._CmdMeshRemove(child_id: integer): string;
var
  shader, texture:string;
begin
  if not _data.Loaded() or (_data.Meshes()=nil) then begin
    result:='!please load model first';
  end else if child_id >= _data.Meshes().Count() then begin
    result:='!child id #'+inttostr(child_id)+' out of bounds, total children count: '+inttostr(_data.Meshes().Count());
  end else begin
    shader:=_data.Meshes().Get(child_id).GetTextureData().shader;
    texture:=_data.Meshes().Get(child_id).GetTextureData().texture;
    if not _data.Meshes().Remove(child_id) then begin
      result:='!remove operation failed for mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+')';
    end else begin
      result:='successfully removed mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+')';
    end;
  end;
end;

function TModelSlot._CmdMeshMove(child_id: integer; cmd: string): string;
var
  v:FVector3;
  shader, texture:string;
begin
  if not _data.Loaded() or (_data.Meshes()=nil) then begin
    result:='!please load model first';
  end else if child_id >= _data.Meshes().Count() then begin
    result:='!child id #'+inttostr(child_id)+' out of bounds, total children count: '+inttostr(_data.Meshes().Count());
  end else begin
    set_zero(v{%H-});
    if not ExtractFVector3(cmd, v) then begin
      result:='!cannot extract vector argument';
    end else begin
      shader:=_data.Meshes().Get(child_id).GetTextureData().shader;
      texture:=_data.Meshes().Get(child_id).GetTextureData().texture;
      cmd:=TrimLeft(cmd);
      if length(cmd)>0 then begin
        result:='!invalid arguments count, expected 3 floats';
      end else begin
        if not _data.Meshes().Get(child_id).Move(v) then begin
          result:='!move operation failed for mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+')';
        end else begin
          result:='mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+') successfully moved';
        end;
      end;
    end;
  end;
end;

function TModelSlot._CmdMeshScale(child_id: integer; cmd: string): string;
var
  v:FVector3;
  shader, texture:string;
begin
  if not _data.Loaded() or (_data.Meshes()=nil) then begin
    result:='!please load model first';
  end else if child_id >= _data.Meshes().Count() then begin
    result:='!child id #'+inttostr(child_id)+' out of bounds, total children count: '+inttostr(_data.Meshes().Count());
  end else begin
    set_zero(v{%H-});
    if not ExtractFVector3(cmd, v) then begin
      result:='!cannot extract vector argument';
    end else begin
      shader:=_data.Meshes().Get(child_id).GetTextureData().shader;
      texture:=_data.Meshes().Get(child_id).GetTextureData().texture;
      cmd:=TrimLeft(cmd);
      if length(cmd)>0 then begin
        result:='!invalid arguments count, expected 3 floats';
      end else begin
        if not _data.Meshes().Get(child_id).Scale(v) then begin
          result:='!scale operation failed for mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+')';
        end else begin
          result:='mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+') successfully scaled';
        end;
      end;
    end;
  end;
end;

function TModelSlot._CmdMeshRebind(child_id: integer; cmd: string): string;
var
  dest_boneid,  src_boneid:TBoneID;
  shader, texture:string;
  flag:boolean;
  vcnt:integer;
begin
  result:='';
  if not _data.Loaded() or (_data.Meshes()=nil) then begin
    result:='!please load model first';
  end else if child_id >= _data.Meshes().Count() then begin
    result:='!child id #'+inttostr(child_id)+' out of bounds, total children count: '+inttostr(_data.Meshes().Count());
  end else begin
    src_boneid:=INVALID_BONE_ID;
    dest_boneid:=INVALID_BONE_ID;
    if not ExtractBoneIdFromString(cmd, dest_boneid) then begin
      result:='!can''t extract target bone id';
    end else begin
      cmd:=TrimLeft(cmd);
      if (length(cmd) > 0) and (cmd[1]=ARGUMENTS_SEPARATOR) then begin
        cmd:=TrimLeft(rightstr(cmd, length(cmd)-1));
        flag:=ExtractBoneIdFromString(cmd, src_boneid);
        cmd:=TrimLeft(cmd);
        if (not flag) then begin
          result:='!can''t extract source bone id';
        end else if (length(cmd)>0) then begin
          result:='!the procedure expects 1 or 2 argument(s)';
        end;
      end;

      if (length(result) = 0) then begin
        shader:=_data.Meshes().Get(child_id).GetTextureData().shader;
        texture:=_data.Meshes().Get(child_id).GetTextureData().texture;
        vcnt:= _data.Meshes().Get(child_id).GetVerticesCountForBoneID(src_boneid);
        if vcnt = 0 then begin
          result:='#mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+') contains no vertices binded with '+GetBoneNameById(src_boneid);
        end else if not _data.Meshes().Get(child_id).RebindVertices(dest_boneid, src_boneid) then begin
          result:='!failed to rebind vertices of mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+') from '+GetBoneNameById(src_boneid)+' to '+GetBoneNameById(dest_boneid);
        end else begin
          result:=inttostr(vcnt)+' vertices of mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+') are successfully rebinded from '+GetBoneNameById(src_boneid)+' to '+GetBoneNameById(dest_boneid);
        end;
      end;
    end;
  end;
end;

function TModelSlot._CmdMeshBonestats(child_id: integer): string;
var
  i, vcnt:integer;
  shader, texture:string;
  found:boolean;
  s:TOgfSkeleton;
begin
  result:='';
  if not _data.Loaded() or (_data.Meshes()=nil) then begin
    result:='!please load model first';
  end else if child_id >= _data.Meshes().Count() then begin
    result:='!child id #'+inttostr(child_id)+' out of bounds, total children count: '+inttostr(_data.Meshes().Count());
  end else begin
    s:=_data.Skeleton();
    if s = nil then begin
      result:='!model has no skeleton';
    end else begin
      shader:=_data.Meshes().Get(child_id).GetTextureData().shader;
      texture:=_data.Meshes().Get(child_id).GetTextureData().texture;
      result:='mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+') is assigned to the following bones:'+chr($0d)+chr($0a);
      found:=false;
      for i:=0 to s.GetBonesCount()-1 do begin
        vcnt:= _data.Meshes().Get(child_id).GetVerticesCountForBoneID(i);
        if vcnt > 0 then begin
          found:=true;
          result:=result+'- '+GetBoneNameById(i)+' (vertices: '+inttostr(vcnt)+')'+chr($0d)+chr($0a);
        end;
      end;

      if not found then begin
        result:='#mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+') is NOT assigned to any valid bone';
      end;
    end;
  end;
end;

function TModelSlot._CmdMeshFilterBone(child_id: integer; cmd: string): string;
var
  boneid:TBoneID;
  shader, texture:string;
  inverse:boolean;
begin
  result:='';
  if not _data.Loaded() or (_data.Meshes()=nil) then begin
    result:='!please load model first';
  end else if child_id >= _data.Meshes().Count() then begin
    result:='!child id #'+inttostr(child_id)+' out of bounds, total children count: '+inttostr(_data.Meshes().Count());
  end else begin
    boneid:=INVALID_BONE_ID;

    inverse:=false;
    cmd:=trimleft(cmd);
    if (length(cmd)>0) and (cmd[1]=ARGUMENT_INVERSE) then begin
      inverse:=true;
      cmd:=trimleft(rightstr(cmd, length(cmd)-1));
    end;

    if ExtractBoneIdFromString(cmd, boneid) then begin
      shader:=_data.Meshes().Get(child_id).GetTextureData().shader;
      texture:=_data.Meshes().Get(child_id).GetTextureData().texture;

      if length(trimleft(cmd))>0 then begin
        result:='!procedure expects 1 argument';
      end else begin
        if not inverse and (_data.Meshes().Get(child_id).GetVerticesCountForBoneID(boneid) = 0) then begin
          result:='#no vertices of mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+') are assigned to bone '+GetBoneNameById(boneid);
        end;

        if _data.Meshes().Get(child_id).RemoveVerticesForBoneId(boneid, inverse) then begin
          if _data.Meshes().Get(child_id).GetVerticesCount() = 0 then begin
            result:='#mesh is fully collapsed (no vertices found), please remove it'+chr($0d)+chr($0a);
          end;
          result:=result+'successfully removed vertices of mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+') assigned to bone '+GetBoneNameById(boneid);
        end else begin
          result:='!error filtering vertices of mesh #'+inttostr(child_id)+' ('+texture+' : '+shader+') assigned to bone '+GetBoneNameById(boneid);
        end;

      end;
    end else begin
      result:='!can''t extract bone id';
    end;
  end;
end;

/////////////////////////////////// BONES //////////////////////////////////////
function TModelSlot.ExtractBoneIdFromString(var inoutstr:string; var boneid:TBoneId):boolean;
var
  tmpid, tmpstr:string;
  tmp_num, i:integer;
begin
  result:=false;

  if not result then begin
    // Пробуем извлечь ID по имени кости
    tmpstr:=inoutstr;
    tmpid:=ExtractABNString(tmpstr);
    tmpstr:=TrimLeft(tmpstr);
    tmpid:=trim(tmpid);

    for i:=0 to _data.Skeleton().GetBonesCount()-1 do begin
      if _data.Skeleton().GetBoneName(i) = tmpid then begin
        result:=true;
        tmp_num:=i;
        break;
      end;
    end;
  end;

  if not result then begin
    // Пробуем извлечь ID напрямую
    tmpstr:=inoutstr;
    tmpid:=ExtractNumericString(tmpstr, true);
    tmpstr:=TrimLeft(tmpstr);
    tmp_num:=strtointdef(tmpid, -2);
    if (tmp_num <> -2) then begin
      result:=(_data.Skeleton().GetBonesCount() > tmp_num);
    end;
  end;

  if result then begin
    inoutstr:=tmpstr;
    boneid:=tmp_num;
  end;
end;

function TModelSlot.GetBoneNameById(boneid: TBoneId): string;
var
  s:TOgfSkeleton;
begin
  result:='[none]';
  if not _data.Loaded() then exit;
  s:=_data.Skeleton();
  if s = nil then exit;

  if boneid = INVALID_BONE_ID then begin
    result:='[all]';
    exit;
  end;

  if (boneid<s.GetBonesCount()) then begin
    result:=s.GetBoneName(boneid);
  end;
end;

function TModelSlot._ProcessBonesCommands(bone_id: integer; cmd: string): string;
var
  opcode:char;
  args:string;
  proccode:string;
  propname:string;
const
  PROC_INFO:string='info';

  PROP_IKDATA:string='ikdata';
begin
  if (not _data.Loaded()) or (_data.Skeleton()=nil) then begin
    result:='!please load model first';
  end else if abs(bone_id) >= _data.Skeleton().GetBonesCount() then begin
    result:='!bone id #'+inttostr(bone_id)+' out of bounds, total bones count: '+inttostr(_data.Meshes().Count());
  end else begin
    if bone_id < 0 then begin
      bone_id:=_data.Skeleton().GetBonesCount() - bone_id;
    end;

    if length(trim(cmd))=0 then begin
      result:=_CmdBoneInfo(bone_id);
    end else begin
      args:='';
      opcode:=cmd[1];
      cmd:=rightstr(cmd, length(cmd)-1);
      if opcode = OPCODE_CALL then begin
        proccode:=ExtractAlphabeticString(cmd);
        if not ExtractProcArgs(cmd, args) then begin
          result:='!can''t parse arguments to call procedure "'+proccode+'"';
        end else if lowercase(proccode)=PROC_INFO then begin
          result:=_CmdBoneInfo(bone_id);
        end else begin
          result:='!unknown procedure "'+proccode+'"';
        end;
      end else if opcode = OPCODE_INDEX then begin
        propname:=ExtractAlphabeticString(cmd);
        if not _data.Loaded() then begin
          result:='!please load model first';
        end else if propname = PROP_IKDATA then begin
          result:=_ProcessIKDataCommands(bone_id, cmd)
        end else begin
          result:='!unknown property "'+propname+'"';
        end;
      end else begin
        result:='!unsupported opcode "'+opcode+'"';
      end;
    end;
  end;
end;

function TModelSlot._CmdBoneInfo(bone_id: integer): string;
begin
  if not _data.Loaded() or (_data.Skeleton()=nil) then begin
    result:='!please load model first';
  end else if bone_id >= _data.Skeleton().GetBonesCount() then begin
    result:='!bone id #'+inttostr(bone_id)+' out of bounds, total bones count: '+inttostr(_data.Skeleton().GetBonesCount());
  end else begin
    result:='Info for bone #'+inttostr(bone_id)+':'+chr($0d)+chr($0a);
    result:=result+'- Name: '+_data.Skeleton().GetBoneName(bone_id)+chr($0d)+chr($0a);
    result:=result+'- Parent: '+_data.Skeleton().GetParentBoneName(bone_id);
  end;
end;

function TModelSlot._ProcessIKDataCommands(bone_id: integer; cmd: string): string;
var
  opcode:char;
  args:string;
  proccode:string;
const
  PROC_INFO:string='info';
  PROC_COPYIKDATA:string='copy';
  PROC_PASTEIKDATA:string='paste';
begin
  if not _data.Loaded() or (_data.Skeleton()=nil) then begin
    result:='!please load model first';
  end else if bone_id >= _data.Skeleton().GetBonesCount() then begin
    result:='!bone id #'+inttostr(bone_id)+' out of bounds, total bones count: '+inttostr(_data.Skeleton().GetBonesCount());
  end else begin
    if bone_id < 0 then begin
      bone_id:=_data.Skeleton().GetBonesCount() - bone_id;
    end;

    if length(trim(cmd))=0 then begin
      result:=_CmdIKDataInfo(bone_id);
    end else begin
      args:='';
      opcode:=cmd[1];
      cmd:=rightstr(cmd, length(cmd)-1);
          if opcode = OPCODE_CALL then begin
        proccode:=ExtractAlphabeticString(cmd);
        if not ExtractProcArgs(cmd, args) then begin
          result:='!can''t parse arguments to call procedure "'+proccode+'"';
        end else if lowercase(proccode)=PROC_INFO then begin
          result:=_CmdIKDataInfo(bone_id);
        end else if lowercase(proccode)=PROC_COPYIKDATA then begin
          result:=_CmdIKDataCopy(bone_id);
        end else if lowercase(proccode)=PROC_PASTEIKDATA then begin
          result:=_CmdIKDataPaste(bone_id);
        end else begin
          result:='!unknown procedure "'+proccode+'"';
        end;
      end else begin
        result:='!unsupported opcode "'+opcode+'"';
      end;
    end;
  end;
end;

function ShapeTypeById(shape:word):string;
begin
  if shape = OGF_SHAPE_TYPE_BOX then begin
    result:='BOX';
  end else if shape = OGF_SHAPE_TYPE_CYLINDER then begin
    result:='CYLINDER';
  end else if shape = OGF_SHAPE_TYPE_INVALID then begin
    result:='INVALID';
  end else if shape = OGF_SHAPE_TYPE_SPHERE then begin
    result:='SPHERE';
  end else if shape = OGF_SHAPE_TYPE_NONE then begin
    result:='NONE';
  end else begin
    result:='[unknown]';
  end;
end;

function TModelSlot._CmdIKDataInfo(bone_id: integer): string;
begin
  if not _data.Loaded() or (_data.Skeleton()=nil) then begin
    result:='!please load model first';
  end else if bone_id >= _data.Skeleton().GetBonesCount() then begin
    result:='!bone id #'+inttostr(bone_id)+' out of bounds, total bones count: '+inttostr(_data.Skeleton().GetBonesCount());
  end else begin
    result:='IKData info for bone #'+inttostr(bone_id)+' ('+_data.Skeleton().GetBoneName(bone_id)+'):'+chr($0d)+chr($0a);
    result:=result+'- Shape type: '+ShapeTypeById(_data.Skeleton().GetOgfShape(bone_id).shape_type);
  end;
end;

function TModelSlot._CmdIKDataCopy(bone_id: integer): string;
var
  s:string;
begin
  if not _data.Loaded() or (_data.Skeleton()=nil) then begin
    result:='!please load model first';
  end else if bone_id >= _data.Skeleton().GetBonesCount() then begin
    result:='!bone id #'+inttostr(bone_id)+' out of bounds, total bones count: '+inttostr(_data.Skeleton().GetBonesCount());
  end else begin
    s:=_data.Skeleton().CopySerializedBoneIKData(bone_id);
    if length(s)=0 then begin
      result:='!failed to serialize data';
    end else begin
      _container.GetTempBuffer().SetString(s);
      result:='data successfully copied to temp buffer';
    end;
  end;
end;

function TModelSlot._CmdIKDataPaste(bone_id: integer): string;
var
  s:string;
begin
  if not _data.Loaded() or (_data.Skeleton()=nil) then begin
    result:='!please load model first';
  end else if bone_id >= _data.Skeleton().GetBonesCount() then begin
    result:='!bone id #'+inttostr(bone_id)+' out of bounds, total bones count: '+inttostr(_data.Skeleton().GetBonesCount());
  end else begin
    if not _container.GetTempBuffer().GetString(s) then begin
      result:='!failed to extract data from temp buffer';
    end else if not _data.Skeleton().PasteSerializedBoneIKData(bone_id, s) then begin
      result:='!failed to paste serialized data';
    end else begin
      result:='data successfully pasted';
    end;
  end;
end;

function TModelSlot._CmdSkeletonUniformScale(cmd: string): string;
var
  k:single;
begin
  if not ExtractFloatFromString(cmd, k) then begin
    result:='!procedure expects a floating-point argument';
  end else if length(trim(cmd)) > 0 then begin
    result:='!procedure expects 1 argument';
  end else if not _data.Loaded() or (_data.Skeleton()=nil) then begin
    result:='!please load model first';
  end else begin
    if not _data.Skeleton().UniformScale(k) then begin
      result:='!error scaling skeleton';
    end else begin
      result:='skeleton successfully scaled';
    end;
  end;
end;

/////////////////////////////////// CORE ///////////////////////////////////////

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

/////////////////////////// COMMAND PROCESSORS /////////////////////////////////

function TModelSlot._CmdPropChildMesh(cmd: string): string;
var
  filters:TIndexFilters;
  i:integer;
  tmpstr:string;
  args:string;
const
  FILTER_TEXTURE_NAME='texture';
  FILTER_SHADER_NAME='shader';
begin
  result:='';

  InitFilters(filters{%H-});
  PushFilter(filters, FILTER_TEXTURE_NAME);
  PushFilter(filters, FILTER_SHADER_NAME);
  i:=0;
  if ExtractIndexFilter(cmd,filters,i) then begin
    if i < 0 then begin
      result:='!invalid filter rule';
    end else begin
      result:='';

      // We use reverse order because current child could disappear or new child in the end could appear while executing command
      for i:=_data.Meshes().Count()-1 downto 0 do begin
        if IsMatchFilter(_data.Meshes().Get(i).GetTextureData().texture, filters[0], FILTER_MODE_EXACT) and IsMatchFilter(_data.Meshes().Get(i).GetTextureData().shader, filters[1], FILTER_MODE_EXACT) then begin
          tmpstr:=_ProcessMeshesCommands(i, cmd);
          if (length(tmpstr)>0) then begin
            if tmpstr[1]='!' then begin
              result:=result+'!mesh'+inttostr(i)+': '+tmpstr+chr($0d)+chr($0a);
            end else if tmpstr[1]='#' then begin
              result:=result+'#mesh'+inttostr(i)+': '+tmpstr+chr($0d)+chr($0a);
            end else begin
              result:=result+'mesh'+inttostr(i)+': '+tmpstr+chr($0d)+chr($0a);
            end;
          end;
        end;
      end;

      if length(result) = 0 then begin
        result:='#the specified filter doesn''t match any item, no action performed';
      end;
    end;
  end else begin
    args:=ExtractNumericString(cmd, false);
    i:=strtointdef(args, -1);
    if i<0 then begin
      result:='!invalid child id "'+args+'"';
    end else begin
      result:=_ProcessMeshesCommands(i, cmd);
    end;
  end;

  ClearFilters(filters);
end;

function TModelSlot._CmdPropSkeleton(cmd: string): string;
var
  filters:TIndexFilters;
  i:integer;
  tmpstr:string;
  args:string;
const
  FILTER_BONE_NAME='bonename';
  FILTER_BONE_ID='boneid';
begin
  result:='';

  InitFilters(filters{%H-});
  PushFilter(filters, FILTER_BONE_NAME);
  PushFilter(filters, FILTER_BONE_ID);
  i:=0;
  if ExtractIndexFilter(cmd,filters,i) then begin
    if i < 0 then begin
      result:='!invalid filter rule';
    end else begin
      result:='';

      // We use reverse order because current child could disappear or new child in the end could appear while executing command
      for i:=_data.Skeleton().GetBonesCount()-1 downto 0 do begin
        if IsMatchFilter(_data.Skeleton().GetBoneName(i), filters[0], FILTER_MODE_EXACT) and IsMatchFilter(inttostr(i), filters[1], FILTER_MODE_EXACT) then begin
          tmpstr:=_ProcessBonesCommands(i, cmd);
          if (length(tmpstr)>0) then begin
            if tmpstr[1]='!' then begin
              result:=result+'!bone'+inttostr(i)+': '+tmpstr+chr($0d)+chr($0a);
            end else if tmpstr[1]='#' then begin
              result:=result+'bone'+inttostr(i)+': '+tmpstr+chr($0d)+chr($0a);
            end else begin
              result:=result+'bone'+inttostr(i)+': '+tmpstr+chr($0d)+chr($0a);
            end;
          end;
        end;
      end;

      if length(result) = 0 then begin
        result:='#the specified filter doesn''t match any item, no action performed';
      end;
    end;
  end else begin
    args:=ExtractNumericString(cmd, false);
    i:=strtointdef(args, -1);
    if i<0 then begin
      result:='!invalid bone id "'+args+'"';
    end else begin
      result:=_ProcessBonesCommands(i, cmd);
    end;
  end;

  ClearFilters(filters);
end;

function TModelSlot.ExecuteCmd(cmd: string): string;
const
  PROC_LOADFROMFILE:string='loadfromfile';
  PROC_SAVETOFILE:string='savetofile';
  PROC_UNLOAD:string='unload';
  PROC_INFO:string='info';
  PROC_PASTEMESH:string='pastemesh';
  PROC_REMCOLLAPSED:string='removecollapsedmeshes';
  PROC_UNIFORMSCALE:string='uniformscaleskeleton';

  PROP_CHILD:string='mesh';
  PROP_BONE:string='bone';
  PROP_SKELETON:string='skeleton';

var
  args:string;
  opcode:char;
  proccode, propname:string;

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
    end else if lowercase(proccode)=PROC_PASTEMESH then begin
      result:=_CmdPasteMeshFromTempBuf();
    end else if lowercase(proccode)=PROC_REMCOLLAPSED then begin
      result:=_CmdRemoveCollapsedMeshes();
    end else if lowercase(proccode)=PROC_UNIFORMSCALE then begin
      result:=_CmdSkeletonUniformScale(args);
    end else begin
      result:='!unknown procedure "'+proccode+'"';
    end;
  end else if opcode = OPCODE_INDEX then begin
    propname:=ExtractAlphabeticString(cmd);

    if not _data.Loaded() then begin
      result:='!please load model first';
    end else if lowercase(propname)=PROP_CHILD then begin
      result:=_CmdPropChildMesh(cmd);
    end else if (lowercase(propname)=PROP_SKELETON) or (lowercase(propname)=PROP_BONE) then begin
      result:=_CmdPropSkeleton(cmd);
    end else begin
      result:='!unknown property "'+propname+'"';
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
    id_str:=ExtractNumericString(rest_string, false);
    id_str:='0'+id_str;
    idx:=strtointdef(id_str, 0);
    result:=GetModelSlotById(idx)
  end;
end;

end.


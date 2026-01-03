unit CommandsParser;

{$mode objfpc}{$H+}

interface

uses
  ogf_parser, basedefs, tempbuffer, commandsstorage, SelectionArea, CommandsHelpers;

type
TSlotsContainer = class;

TSlotId = integer;

{ TSlotFilteringCommands }
TModelSlot = class;
TSlotFilteringCommands = class(TFilteringCommands)
  _slot:TModelSlot;
public
  constructor Create(slot:TModelSlot);
end;

{ TChildrenCommands }

TChildrenCommands = class(TSlotFilteringCommands)
public
  constructor Create(slot:TModelSlot);
  function GetFilteringItemTypeName(item_id:integer):string; override;
  function GetFilteringItemsCount():integer; override;
  function CheckFiltersForItem(item_id:integer; filters:TIndexFilters):boolean; override;
end;

{ TBonesCommands }

TBonesCommands = class(TSlotFilteringCommands)
public
  constructor Create(slot:TModelSlot);
  function GetFilteringItemTypeName(item_id:integer):string; override;
  function GetFilteringItemsCount():integer; override;
  function CheckFiltersForItem(item_id:integer; filters:TIndexFilters):boolean; override;
end;


{ TModelSlot }

TModelSlot = class
  _data:TOgfParser;
  _id:TSlotId;
  _container:TSlotsContainer;
  _selectionarea:TSelectionArea;

  _commands_selection:TCommandsStorage;
  _commands_upperlevel:TCommandsStorage;
  _commands_mesh:TCommandsStorage;
  _commands_children:TChildrenCommands;
  _commands_skeleton:TCommandsStorage;
  _commands_bones:TBonesCommands;
  _commands_ikdata:TBonesCommands;

  function _CmdSetPivot(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSelectionSphere(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSelectionBox(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSelectionClear(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSelectionInfo(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSelectionTestPoint(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSelectionInverse(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;


  function _IsModelLoadedPrecondition(args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _IsModelNotLoadedPrecondition(args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _IsModelHasSkeletonPrecondition(args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;

  function ExtractBoneIdFromString(var inoutstr:string; var boneid:TBoneId):boolean;
  function GetBoneNameById(boneid: TBoneId): string;

  function _CmdLoadFromFile(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSaveToFile(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdUnload(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdInfo(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdClipboardMode(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;

  function _CmdPasteMeshFromTempBuf(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdRemoveCollapsedMeshes(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;


  function _CmdChildInfo(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdChildSetTexture(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdChildSetShader(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdChildRemove(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdChildCopy(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdChildPasteData(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdChildMoveAll(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdChildRotateAll(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdChildScaleAll(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdChildMoveSelected(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdChildRotateSelected(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdChildScaleSelected(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdChildRebindAll(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdChildRebindSelected(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdChildBonestats(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdChildFilterBone(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _cmdChildSaveToFile(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _cmdChildLodLevelSelect(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _cmdChildLodLevelsRemove(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;

  function _CmdSkeletonUniformScale(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdBoneInfo(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdIKDataInfo(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdIKDataCopy(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdIKDataPaste(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;

public
  constructor Create(id:TSlotId; container:TSlotsContainer);
  destructor Destroy; override;
  function SlotId():TSlotId;
  function Data():TOgfParser;

  function ExecuteCmd(cmd:string):TCommandResult;
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
uses sysutils, strutils, ChunkedFileParser;

const
  BUFFER_TYPE_CHILDMESH:integer=100;
  BUFFER_TYPE_BONEIKDATA:integer=101;

{ TSlotFilteringCommands }

constructor TSlotFilteringCommands.Create(slot: TModelSlot);
begin
  inherited Create(true);
  _slot:=slot;
end;

{ TChildrenCommands }

constructor TChildrenCommands.Create(slot: TModelSlot);
begin
  inherited;

  RegisterFilter('texture');
  RegisterFilter('shader');

  //TODO: Filter by ID - exact and in range
  // RegisterFilter('id');
end;

function TChildrenCommands.GetFilteringItemTypeName(item_id: integer): string;
begin
  result:='child';
end;

function TChildrenCommands.GetFilteringItemsCount(): integer;
begin
  result:=0;

  if _slot.Data()<> nil then begin
    if _slot.Data().Meshes()<>nil then begin
      result:=_slot.Data().Meshes().Count();
    end;
  end;
end;

function TChildrenCommands.CheckFiltersForItem(item_id: integer; filters:TIndexFilters): boolean;
begin
  result:= IsMatchFilter(_slot.Data().Meshes().Get(item_id).GetTextureData().texture, filters[0], FILTER_MODE_EXACT)
       and IsMatchFilter(_slot.Data().Meshes().Get(item_id).GetTextureData().shader,  filters[1], FILTER_MODE_EXACT)
end;

{ TBonesCommands }

constructor TBonesCommands.Create(slot: TModelSlot);
begin
  inherited;

  RegisterFilter('bonename');
  RegisterFilter('id');
end;

function TBonesCommands.GetFilteringItemTypeName(item_id: integer): string;
begin
  result:='bone';
end;

function TBonesCommands.GetFilteringItemsCount(): integer;
begin
  result:=0;
  if _slot.Data()<>nil then begin
    if _slot.Data().Skeleton()<>nil then begin
      result:=_slot.Data().Skeleton().GetBonesCount();
    end;
  end;
end;

function TBonesCommands.CheckFiltersForItem(item_id: integer; filters:TIndexFilters): boolean;
begin
  result:=IsMatchFilter(_slot.Data().Skeleton().GetBoneName(item_id), filters[0], FILTER_MODE_EXACT)
       and IsMatchFilter(inttostr(item_id), filters[1], FILTER_MODE_EXACT)
end;


{ TModelSlot }

//////////////////////////////////////////////////////// Preconditions ////////////////////////////////////////////////////
function TModelSlot._IsModelLoadedPrecondition(args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
begin
  result:=true;
  if not _data.Loaded() then begin
    result_description.SetDescription('Slot is empty. Load data first');
    result:=false;
  end;
end;

function TModelSlot._IsModelNotLoadedPrecondition(args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
begin
  result:=true;
  if _data.Loaded() then begin
    result_description.SetDescription('Slot is not empty. Unload data first');
    result:=false;
  end;
end;

function TModelSlot._IsModelHasSkeletonPrecondition(args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
begin
  result:=true;
  if not _data.Loaded() then begin
    result_description.SetDescription('Slot is empty. Load data first');
    result:=false;
  end else if _data.Skeleton()=nil then begin
    result_description.SetDescription('Loaded model has no skeleton');
    result:=false;
  end;
end;

//////////////////////////////////////////////////////// Helper functions ////////////////////////////////////////////////////
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

//////////////////////////////////////////////////////// Selection //////////////////////////////////////////////////////////

function TModelSlot._CmdSetPivot(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  v:FVector3;
begin
  result:=false;
  set_zero(v{%H-});
  if not ExtractFVector3(args, v) then begin
    result_description.SetDescription('can''t extract vector from argument');
  end else begin
    args:=TrimLeft(args);
    if length(args)>0 then begin
      result_description.SetDescription('invalid arguments count, expected 3 numbers')
    end else begin
      _selectionarea.SetPivot(v);
      result:=true;
    end;
  end;
end;

function TModelSlot._CmdSelectionSphere(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  v:FVector3;
  r:single;
begin
  result:=false;
  set_zero(v{%H-});
  if not ExtractFVector3(args, v) then begin
    result_description.SetDescription('can''t extract center point vector from arguments');
    exit;
  end;
  args:=TrimLeft(args);
  if (length(args)=0) or (args[1]<>COMMANDS_ARGUMENTS_SEPARATOR) then begin
    result_description.SetDescription('procedure expects 4 numbers as arguments');
    exit;
  end;

  args:=trim(rightstr(args, length(args)-1));
  if not ExtractFloatFromString(args, r) then begin
    result_description.SetDescription('can''t extract radius from arguments');
    exit;
  end;

  args:=TrimLeft(args);
  if length(args)<>0 then begin
    result_description.SetDescription('invalid arguments count, expected 4 numbers')
  end else begin
    _selectionarea.SetSelectionAreaAsSphere(v, r);
    result:=true;
  end;
end;

function TModelSlot._CmdSelectionBox(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  p1, p2:FVector3;
begin
  result:=false;
  set_zero(p1);
  set_zero(p2);
  if not ExtractFVector3(args, p1) then begin
    result_description.SetDescription('can''t extract 1st point vector from arguments');
    exit;
  end;
  args:=TrimLeft(args);
  if (length(args)=0) or (args[1]<>COMMANDS_ARGUMENTS_SEPARATOR) then begin
    result_description.SetDescription('procedure expects 6 numbers as arguments');
    exit;
  end;

  args:=trim(rightstr(args, length(args)-1));
  if not ExtractFVector3(args, p2) then begin
    result_description.SetDescription('can''t extract 2nd point vector from arguments');
    exit;
  end;

  args:=TrimLeft(args);
  if length(args)<>0 then begin
    result_description.SetDescription('invalid arguments count, expected 6 numbers')
  end else begin
    _selectionarea.SetSelectionAreaAsBox(p1, p2);
    result:=true;
  end;
end;

function TModelSlot._CmdSelectionClear(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
begin
  _selectionarea.ResetSelectionArea();
  result:=true;
end;

function TModelSlot._CmdSelectionInfo(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
begin
  result_description.SetDescription(_selectionarea.Info());
  result:=true;
end;

function TModelSlot._CmdSelectionTestPoint(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  v:FVector3;
begin
  result:=false;
  set_zero(v);
  if not ExtractFVector3(args, v) then begin
    result_description.SetDescription('can''t extract point coordinates from arguments');
    exit;
  end;

  args:=TrimLeft(args);
  if length(args)<>0 then begin
    result_description.SetDescription('invalid arguments count, expected 3 numbers')
  end else begin
    if _selectionarea.IsPointInSelection(v) then begin
      result_description.SetDescription('Point is inside the selected area');
    end else begin
      result_description.SetDescription('Point is outside the selected area');
    end;
    result:=true;
  end;

end;

function TModelSlot._CmdSelectionInverse(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
begin
  result:=true;
  _selectionarea.InverseSelectedArea();
end;

//////////////////////////////////////////////////////// Actions //////////////////////////////////////////////////////////
function TModelSlot._CmdLoadFromFile(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  path:string;
begin
  result:=false;

  path:=args;
  if (length(path)>0) and ((path[1] = '"') or (path[1] = '''')) then begin
    path:=rightstr(path, length(path)-1);
  end;
  if (length(path)>0) and ((path[length(path)] = '"') or (path[length(path)] = '''')) then begin
    path:=leftstr(path, length(path)-1);
  end;

  result:=_data.LoadFromFile(path);
  if not result then begin
    result_description.SetDescription('Can''t load model from file "'+path+'"');
  end;
end;

function TModelSlot._CmdSaveToFile(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  path:string;
begin
  result:=false;

  path:=args;
  if (length(path)>0) and ((path[1] = '"') or (path[1] = '''')) then begin
    path:=rightstr(path, length(path)-1);
  end;
  if (length(path)>0) and ((path[length(path)] = '"') or (path[length(path)] = '''')) then begin
    path:=leftstr(path, length(path)-1);
  end;

  result:=_data.SaveToFile(path);
  if not result then begin
    result_description.SetDescription('Can''t save model to "'+path+'"');
  end;
end;

function TModelSlot._CmdUnload(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
begin
  result:=false;

  _data.Reset;
  result:=true;
end;

function TModelSlot._CmdInfo(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
begin
  if not _data.Loaded then begin
    result_description.SetDescription('slot doesn''t contain loaded data');
  end else begin
    result_description.SetDescription('slot is in use');
  end;
  result:=true;
end;

function TModelSlot._CmdClipboardMode(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  i:integer;
begin
  result:=false;
  i:=strtointdef(trim(args), -1);
  if (i<0) or (i>1) then begin
    result_description.SetDescription('0 or 1 expected');
  end else begin
    if i = 0 then begin
      result_description.SetDescription('clipboard mode disabled, copy and paste operations use internal storage');
      _container.GetTempBuffer().SwitchClipboardMode(false);
    end else if i = 1 then begin
      result_description.SetDescription('clipboard mode enabled, copy and paste operations use system clipboard');
      _container.GetTempBuffer().SwitchClipboardMode(true);
    end;
    result:=true;
  end;
end;

function TModelSlot._CmdPasteMeshFromTempBuf(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject ): boolean;
var
  s:string;
  meshid:integer;
  shader, texture:string;
begin
  s:='';
  result:=false;
  if _container.GetTempBuffer().GetData(s, BUFFER_TYPE_CHILDMESH) then begin
    meshid:=_data.Meshes().Append(s);
    if meshid < 0 then begin
      result_description.SetDescription('unable to append data from temp buffer as a mesh');
    end else begin
      shader:=_data.Meshes().Get(meshid).GetTextureData().shader;
      texture:=_data.Meshes().Get(meshid).GetTextureData().texture;
      result_description.SetDescription('mesh #'+inttostr(meshid)+' ('+texture+' : '+shader+') successfully appended');
      result:=true;
    end;
  end else begin
    result_description.SetDescription('invalid data in the temp buffer?');
  end;
end;

function TModelSlot._CmdRemoveCollapsedMeshes(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  i:integer;
  shader, texture:string;
  r:string;
begin
  result:=true;
  r:='';
  for i:=_data.Meshes().Count()-1 downto 0 do begin
    shader:=_data.Meshes().Get(i).GetTextureData().shader;
    texture:=_data.Meshes().Get(i).GetTextureData().texture;

    if _data.Meshes().Get(i).GetVerticesCount() = 0 then begin;
      if not _data.Meshes().Remove(i) then begin
        r:=r+'Failed to remove collapsed mesh #'+inttostr(i)+' ('+texture+' : '+shader+')'+chr($0d)+chr($0a);
        result:=false;
      end else begin
        r:=r+'Removed collapsed mesh #'+inttostr(i)+' ('+texture+' : '+shader+')'+chr($0d)+chr($0a);
      end;
    end;
  end;
  result_description.SetDescription(r);
end;

function TModelSlot._CmdSkeletonUniformScale(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject ): boolean;
var
  k:single;
begin
  result:=false;
  if not ExtractFloatFromString(args, k) then begin
    result_description.SetDescription('procedure expects a floating-point argument');
  end else if length(trim(args)) > 0 then begin
    result_description.SetDescription('procedure expects 1 argument');
  end else begin
    if not _data.Skeleton().UniformScale(k) then begin
      result_description.SetDescription('error scaling skeleton');
    end else begin
      result_description.SetDescription('skeleton successfully scaled');
      result:=true;
    end;
  end;
end;

function TModelSlot._CmdBoneInfo(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  r:string;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    r:='Info for bone #'+inttostr(idx)+':'+chr($0d)+chr($0a);
    r:=r+'- Name: '+_data.Skeleton().GetBoneName(idx)+chr($0d)+chr($0a);
    r:=r+'- Parent: '+_data.Skeleton().GetParentBoneName(idx);
    result_description.SetDescription(r);
    result:=true;
  end;
end;

function TModelSlot._CmdIKDataInfo(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  r:string;
  shape_type_id:word;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    r:='IKData info for bone #'+inttostr(idx)+' ('+_data.Skeleton().GetBoneName(idx)+'):'+chr($0d)+chr($0a);

    shape_type_id:=_data.Skeleton().GetOgfShape(idx).shape_type;
    r:=r+'- Shape type: '+inttostr(shape_type_id)+' ('+ShapeTypeById(shape_type_id)+')';

    result_description.SetDescription(r);
    result:=true;
  end;
end;

function TModelSlot._CmdIKDataCopy(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  s:string;
  idx:integer;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    s:=_data.Skeleton().SerializeBoneIKData(idx);
    if length(s)=0 then begin
      result_description.SetDescription('failed to serialize ikdata for bone #'+inttostr(idx));
    end else begin
      _container.GetTempBuffer().SetData(s, BUFFER_TYPE_BONEIKDATA);
      result_description.SetDescription('data successfully copied to temp buffer');
      result:=true;
    end;
  end;
end;

function TModelSlot._CmdIKDataPaste(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  s:string;
  idx:integer;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    if not _container.GetTempBuffer().GetData(s, BUFFER_TYPE_BONEIKDATA) then begin
      result_description.SetDescription('invalid data in the temp buffer');
    end else if not _data.Skeleton().DeserializeBoneIKData(idx, s) then begin
      result_description.SetDescription('failed to paste serialized data');
    end else begin
      result_description.SetDescription('ikdata successfully pasted');
      result:=true;
    end;
  end;
end;

function TModelSlot._CmdChildInfo(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  r:string;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    if (idx >=0) and (idx < _data.Meshes.Count()) then begin
      r:='Child mesh #'+inttostr(idx)+':'+chr($0d)+chr($0a);
      r:=r+'- Texture: '+_data.Meshes.Get(idx).GetTextureData().texture+chr($0d)+chr($0a);
      r:=r+'- Shader: '+_data.Meshes.Get(idx).GetTextureData().shader+chr($0d)+chr($0a);
      r:=r+'- Vertices count:'+inttostr(_data.Meshes.Get(idx).GetVerticesCount())+chr($0d)+chr($0a);
      r:=r+'- Tris count:'+inttostr(_data.Meshes.Get(idx).GetTrisCountTotal())+chr($0d)+chr($0a);
      r:=r+'- Current link type:'+inttostr(_data.Meshes.Get(idx).GetCurrentLinkType())+chr($0d)+chr($0a);
      r:=r+'- Progressive LOD levels count: '+inttostr(_data.Meshes.Get(idx).GetLodLevels());

      result_description.SetDescription(r);
      result:=true;
    end;
  end;
end;

function TModelSlot._CmdChildSetTexture(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  texdata:TOgfTextureData;
  shader, texture:string;
  idx:integer;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    shader:=_data.Meshes().Get(idx).GetTextureData().shader;
    texture:=_data.Meshes().Get(idx).GetTextureData().texture;
    texdata:=_data.Meshes().Get(idx).GetTextureData();
    texdata.texture:=trim(args);
    if _data.Meshes().Get(idx).SetTextureData(texdata) then begin
      result_description.SetDescription('texture successfully updated for mesh #'+inttostr(idx)+' ('+texture+' : '+shader+')');
      result:=true;
    end else begin
      result_description.SetDescription('can''t update texture for mesh #'+inttostr(idx)+' ('+texture+' : '+shader+')');
    end;
  end;
end;

function TModelSlot._CmdChildSetShader(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  texdata:TOgfTextureData;
  shader, texture:string;
  idx:integer;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    shader:=_data.Meshes().Get(idx).GetTextureData().shader;
    texture:=_data.Meshes().Get(idx).GetTextureData().texture;
    texdata:=_data.Meshes().Get(idx).GetTextureData();
    texdata.shader:=trim(args);
    if _data.Meshes().Get(idx).SetTextureData(texdata) then begin
      result_description.SetDescription('texture shader updated for mesh #'+inttostr(idx)+' ('+texture+' : '+shader+')');
      result:=true;
    end else begin
      result_description.SetDescription('can''t update shader for mesh #'+inttostr(idx)+' ('+texture+' : '+shader+')');
    end;
  end;
end;

function TModelSlot._CmdChildRemove(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  shader, texture:string;
  idx:integer;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    shader:=_data.Meshes().Get(idx).GetTextureData().shader;
    texture:=_data.Meshes().Get(idx).GetTextureData().texture;
    if not _data.Meshes().Remove(idx) then begin
      result_description.SetDescription('remove operation failed for mesh #'+inttostr(idx)+' ('+texture+' : '+shader+')');
    end else begin
      result_description.SetDescription('successfully removed mesh #'+inttostr(idx)+' ('+texture+' : '+shader+')');
      result:=true;
    end;
  end;
end;

function TModelSlot._CmdChildCopy(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  shader, texture:string;
  s:string;
  idx:integer;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    shader:=_data.Meshes().Get(idx).GetTextureData().shader;
    texture:=_data.Meshes().Get(idx).GetTextureData().texture;
    s:=_data.Meshes().Get(idx).Serialize();
    if length(s) = 0 then begin
      result_description.SetDescription('cannot serialize mesh #'+inttostr(idx)+' ('+texture+' : '+shader+'), buffer cleared');
      _container.GetTempBuffer().Clear();
    end else begin
      _container.GetTempBuffer().SetData(s, BUFFER_TYPE_CHILDMESH);
      result_description.SetDescription('mesh #'+inttostr(idx)+' ('+texture+' : '+shader+') successfully saved to temp buffer');
      result:=true;
    end;
  end;
end;

function TModelSlot._CmdChildPasteData(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  shader, texture:string;
  s:string;
  meshid:integer;
  idx:integer;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    s:='';
    if _container.GetTempBuffer().GetData(s, BUFFER_TYPE_CHILDMESH) then begin
      meshid:=_data.Meshes().Insert(s, idx);
      if (meshid < 0) or (meshid<>idx) then begin
        result_description.SetDescription('can''t paste data as a mesh');
      end else begin
        shader:=_data.Meshes().Get(meshid).GetTextureData().shader;
        texture:=_data.Meshes().Get(meshid).GetTextureData().texture;
        result_description.SetDescription('mesh #'+inttostr(meshid)+' ('+texture+' : '+shader+') successfully inserted');
        result:=true;
      end;
    end else begin
      result_description.SetDescription('invalid data in the temp buffer');
    end;
  end;
end;

function TModelSlot._CmdChildMoveAll(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  original_sa:TSelectionArea;
begin
  original_sa:=_selectionarea;
  _selectionarea:=TSelectionArea.Create();
  try
    _selectionarea.SetPivot(original_sa.GetPivot());
    _selectionarea.ResetSelectionArea();
    _selectionarea.InverseSelectedArea();
    result:=_CmdChildMoveSelected(args, cmd, result_description, userdata);
  finally
    FreeAndNil(_selectionarea);
    _selectionarea:=original_sa;
  end;
end;

function TModelSlot._CmdChildRotateAll(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  original_sa:TSelectionArea;
begin
  original_sa:=_selectionarea;
  _selectionarea:=TSelectionArea.Create();
  try
    _selectionarea.SetPivot(original_sa.GetPivot());
    _selectionarea.ResetSelectionArea();
    _selectionarea.InverseSelectedArea();
    result:=_CmdChildRotateSelected(args, cmd, result_description, userdata);
  finally
    FreeAndNil(_selectionarea);
    _selectionarea:=original_sa;
  end;
end;

function TModelSlot._CmdChildScaleAll(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  original_sa:TSelectionArea;
begin
  original_sa:=_selectionarea;
  _selectionarea:=TSelectionArea.Create();
  try
    _selectionarea.SetPivot(original_sa.GetPivot());
    _selectionarea.ResetSelectionArea();
    _selectionarea.InverseSelectedArea();
    result:=_CmdChildScaleSelected(args, cmd, result_description, userdata);
  finally
    FreeAndNil(_selectionarea);
    _selectionarea:=original_sa;
  end;
end;


type
  TVertexSelectionCallbackData = record
    selection_area:TSelectionArea;
    vcnt:integer;
  end;
  pTVertexSelectionCallbackData = ^TVertexSelectionCallbackData;

function VertexSelectionCallback(vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; userdata:pointer):boolean;
var
  cbdata:pTVertexSelectionCallbackData;
begin
  result:=false;
  if (userdata = nil) or (data = nil) then exit;
  cbdata:=pTVertexSelectionCallbackData(userdata);
  result:=cbdata^.selection_area.IsPointInSelection(data^.pos);
  if result then begin
    cbdata^.vcnt:=cbdata^.vcnt+1;
  end;
end;

function TModelSlot._CmdChildMoveSelected(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  v:FVector3;
  shader, texture:string;
  idx:integer;
  cbdata:TVertexSelectionCallbackData;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    set_zero(v{%H-});
     if not ExtractFVector3(args, v) then begin
       result_description.SetDescription('cannot parse vector components from argument');
     end else begin
       shader:=_data.Meshes().Get(idx).GetTextureData().shader;
       texture:=_data.Meshes().Get(idx).GetTextureData().texture;
       args:=TrimLeft(args);
       if length(args)>0 then begin
         result_description.SetDescription('invalid arguments count, expected 3 numbers')
       end else begin
         cbdata.selection_area:=_selectionarea;
         cbdata.vcnt:=0;
         if not _data.Meshes().Get(idx).Move(v, @VertexSelectionCallback, @cbdata) then begin
           result_description.SetDescription('move operation failed for mesh #'+inttostr(idx)+' ('+texture+' : '+shader+')');
         end else if cbdata.vcnt = 0 then begin
           result_description.SetDescription('no vertices were found in the selection area');
           result_description.SetWarningFlag(true);
           result:=true;
         end else begin
           result_description.SetDescription(inttostr(cbdata.vcnt) +' vertices of mesh #'+inttostr(idx)+' ('+texture+' : '+shader+') successfully moved');
           result:=true;
         end;
       end;
     end;
  end;
end;

function TModelSlot._CmdChildRotateSelected(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  amount:single;
  axis:TOgfRotationAxis;
  shader, texture:string;
  cbdata:TVertexSelectionCallbackData;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    if not ExtractFloatFromString(args, amount) then begin
      result_description.SetDescription('cannot extract argument #1 (rotation angle in degrees)');
      exit;
    end;

    args:=trimleft(args);
    if (length(args)=0) or (args[1]<>COMMANDS_ARGUMENTS_SEPARATOR) then begin
      result_description.SetDescription('procedure expects 2 arguments');
      exit;
    end;


    args:=trim(rightstr(args, length(args)-1));
    if (length(args)=0) then begin
      result_description.SetDescription('cannot extract argument #2 (rotation axis)');
      exit;
    end;

    if (args[1]='x') or (args[1]='X') then begin
      axis:=OgfRotationAxisX;
    end else if (args[1]='y') or (args[1]='Y') then begin
      axis:=OgfRotationAxisY;
    end else if (args[1]='z') or (args[1]='Z') then begin
      axis:=OgfRotationAxisZ;
    end else begin
      result_description.SetDescription('rotation axis must be a letter (X, Y or Z)');
      exit;
    end;

    amount:=amount*pi/180;
    cbdata.selection_area:=_selectionarea;
    cbdata.vcnt:=0;
    if not _data.Meshes().Get(idx).RotateUsingStandartAxis(amount, axis, _selectionarea.GetPivot(), @VertexSelectionCallback, @cbdata) then begin
      result_description.SetDescription('rotate operation failed for mesh #'+inttostr(idx)+' ('+texture+' : '+shader+')');
    end else if cbdata.vcnt = 0 then begin
      result_description.SetDescription('no vertices were found in the selection area');
      result_description.SetWarningFlag(true);
      result:=true;
    end else begin
      shader:=_data.Meshes().Get(idx).GetTextureData().shader;
      texture:=_data.Meshes().Get(idx).GetTextureData().texture;

      result_description.SetDescription(inttostr(cbdata.vcnt) +' vertices of vertices of mesh #'+inttostr(idx)+' ('+texture+' : '+shader+') successfully rotated');
      result:=true;
    end;

  end;
end;

function TModelSlot._CmdChildScaleSelected(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  v:FVector3;
  shader, texture:string;
  idx:integer;
  cbdata:TVertexSelectionCallbackData;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    set_zero(v{%H-});
     if not ExtractFVector3(args, v) then begin
       result_description.SetDescription('cannot parse vector components from argument');
     end else begin
       shader:=_data.Meshes().Get(idx).GetTextureData().shader;
       texture:=_data.Meshes().Get(idx).GetTextureData().texture;
       args:=TrimLeft(args);
       if length(args)>0 then begin
         result_description.SetDescription('invalid arguments count, expected 3 floats');
       end else begin
         cbdata.selection_area:=_selectionarea;
         cbdata.vcnt:=0;;
         if not _data.Meshes().Get(idx).Scale(v, _selectionarea.GetPivot(), @VertexSelectionCallback, @cbdata) then begin
           result_description.SetDescription('scale operation failed for mesh #'+inttostr(idx)+' ('+texture+' : '+shader+')');
         end else if cbdata.vcnt = 0 then begin
           result_description.SetDescription('no vertices were found in the selection area');
           result_description.SetWarningFlag(true);
           result:=true;
         end else begin
           result_description.SetDescription(inttostr(cbdata.vcnt) +' vertices of vertices of mesh #'+inttostr(idx)+' ('+texture+' : '+shader+') successfully scaled');
           result:=true;
         end;
       end;
     end;
  end;
end;

type
  TVertexSelectiveBindCallbackData = record
    selection_area:TSelectionArea;
    weight:single;
    src_boneid:TBoneID;
    vcnt:integer;
  end;
  pTVertexSelectiveBindCallbackData = ^TVertexSelectiveBindCallbackData;

function VertexSelectiveBindCallback(vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; target_boneid:cardinal; userdata:pointer):boolean;
var
  cbdata:pTVertexSelectiveBindCallbackData;
  i:integer;
  bone:TVertexBone;
  value:single;
  target_idx:integer;
begin
  result:=false;
  if (userdata = nil) or (data = nil) then exit;
  cbdata:=pTVertexSelectiveBindCallbackData(userdata);
  result:=cbdata^.selection_area.IsPointInSelection(data^.pos);
  if result then begin
    if (cbdata^.src_boneid = INVALID_BONE_ID) then begin
      // no need to replace any specific bones not specified - just adjust weight of target_boneid or add it by replace binding with the lowest weight
      // weight must be from 0 to 1 in this case!
      target_idx:=0;
      for i:=0 to links.TotalLinkedBonesCount()-1 do begin
        bone:=links.GetBoneParams(i);
        if bone.bone_id = target_boneid then begin
          target_idx:=i;
          break;
        end else if bone.weight < links.GetBoneParams(target_idx).weight then begin
          target_idx:=i;
        end;
      end;

      bone:=links.GetBoneParams(target_idx);
      bone.weight:=cbdata^.weight;
      bone.bone_id:=target_boneid;
      links.SetBoneParams(target_idx, bone, false);

      for i:=0 to links.TotalLinkedBonesCount()-1 do begin
        if i = target_idx then continue;
        bone:=links.GetBoneParams(target_idx);
        if bone.bone_id = target_boneid then begin
          bone.weight:=0;
          links.SetBoneParams(target_idx, bone, false);
        end;
      end;

      links.NormalizeWeights(target_idx);
    end else begin
      // both src_boneid and target_boneid both present - we need to replace src_boneid links to target_boneid links
      // if weight >= 0 - also adjust it at the moment of replacing
      value:=cbdata^.weight;
      target_idx:=-1;
      for i:=0 to links.TotalLinkedBonesCount()-1 do begin
        bone:=links.GetBoneParams(i);
        if bone.bone_id = cbdata^.src_boneid then begin
          bone.bone_id:=target_boneid;
          if cbdata^.weight >= 0 then begin
            bone.weight:=value;
          end;
          links.SetBoneParams(i, bone, false);
          if target_idx < 0 then begin
            target_idx:=i;
            value:=0;
          end;
        end;
      end;

      // Normalize weights if something has been changed
      if target_idx>=0 then begin
        links.NormalizeWeights(target_idx);
      end else begin
        result:=false;
      end;
    end;
  end;

  if result then begin
    cbdata^.vcnt:=cbdata^.vcnt+1;
  end;
end;

function TModelSlot._CmdChildRebindSelected(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  dest_boneid,  src_boneid:TBoneID;
  weight: single;
  shader, texture:string;
  idx:integer;
  cbdata:TVertexSelectiveBindCallbackData;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    result_description.SetDescription('');
    src_boneid:=INVALID_BONE_ID;
    dest_boneid:=INVALID_BONE_ID;
    weight:=-1;
    if not ExtractBoneIdFromString(args, dest_boneid) then begin
      result_description.SetDescription('can''t extract target bone id from argument #1');
      exit;
    end;

    args:=TrimLeft(args);
    if (length(args) > 0) and (args[1]=COMMANDS_ARGUMENTS_SEPARATOR) then begin
      args:=trim(rightstr(args, length(args)-1));
      if (length(args) > 0) and (args[1]=COMMANDS_ARGUMENTS_SEPARATOR) then begin
        // weight omitted - we should use already assigned; just parse 3rd arg
      end else if not ExtractFloatFromString(args, weight) then begin
        result_description.SetDescription('can''t extract argument # 2(weight) from arguments');
        exit;
      end else if (weight<0) or (weight > 1) then begin
        result_description.SetDescription('weight must be a number between 0 and 1; if you don''t need weight - just omit it in the command)');
        exit;
      end;
    end else if (length(args) = 0) then begin
      // 1-arg syntax used, use by default the full weight
      weight:=1;
    end else begin
      result_description.SetDescription('please use comma between arguments #1 and #2');
      exit;
    end;

    args:=TrimLeft(args);
    if (length(args) > 0) and (args[1]=COMMANDS_ARGUMENTS_SEPARATOR) then begin
      args:=TrimLeft(rightstr(args, length(args)-1));
      if (not ExtractBoneIdFromString(args, src_boneid)) then begin
        result_description.SetDescription('can''t extract source bone id from argument #3');
        exit;
      end;
    end else if (length(args) > 0) then begin
      result_description.SetDescription('please use comma between arguments #2 and #3');
      exit;
    end;

    args:=TrimLeft(args);
    if length(args) > 0 then begin
      result_description.SetDescription('the procedure expects 1, 2 or 3 argument(s)');
      exit;
    end;

    if (length(result_description.GetDescription()) = 0) then begin
      shader:=_data.Meshes().Get(idx).GetTextureData().shader;
      texture:=_data.Meshes().Get(idx).GetTextureData().texture;
      cbdata.selection_area:=_selectionarea;
      cbdata.src_boneid:=src_boneid;
      cbdata.weight:=weight;
      cbdata.vcnt:=0;
      if not _data.Meshes().Get(idx).BindVerticesToBone(dest_boneid, @VertexSelectiveBindCallback, @cbdata) then begin
        result_description.SetDescription('failed to rebind vertices of mesh #'+inttostr(idx)+' ('+texture+' : '+shader+') from '+GetBoneNameById(src_boneid)+' to '+GetBoneNameById(dest_boneid));
      end else begin
        if cbdata.vcnt = 0 then begin
          result_description.SetDescription('no vertices were found in the selection area');
          result_description.SetWarningFlag(true);
        end else begin
          result_description.SetDescription(inttostr(cbdata.vcnt)+' vertices of mesh #'+inttostr(idx)+' ('+texture+' : '+shader+') are successfully binded to '+GetBoneNameById(dest_boneid));
        end;
        result:=true;
      end;
    end;
  end;
end;

function TModelSlot._CmdChildRebindAll(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  original_sa:TSelectionArea;
begin
  original_sa:=_selectionarea;
  _selectionarea:=TSelectionArea.Create();
  try
    _selectionarea.SetPivot(original_sa.GetPivot());
    _selectionarea.ResetSelectionArea();
    _selectionarea.InverseSelectedArea();
    result:=_CmdChildRebindSelected(args, cmd, result_description, userdata);
  finally
    FreeAndNil(_selectionarea);
    _selectionarea:=original_sa;
  end;
end;

function TModelSlot._CmdChildBonestats(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  i, vcnt:integer;
  shader, texture:string;
  found:boolean;
  s:TOgfSkeleton;
  idx:integer;
  r:string;
begin
  result:=true;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    shader:=_data.Meshes().Get(idx).GetTextureData().shader;
    texture:=_data.Meshes().Get(idx).GetTextureData().texture;
    r:='mesh #'+inttostr(idx)+' ('+texture+' : '+shader+') is assigned to the following bones:'+chr($0d)+chr($0a);
    found:=false;
    s:=_data.Skeleton();
    for i:=0 to s.GetBonesCount()-1 do begin
      vcnt:= _data.Meshes().Get(idx).GetVerticesCountForBoneID(i);
      if vcnt > 0 then begin
        found:=true;
        r:=r+'- '+GetBoneNameById(i)+' (vertices: '+inttostr(vcnt)+')'+chr($0d)+chr($0a);
      end;
    end;

    result_description.SetDescription(r);
    if not found then begin
      result_description.SetDescription('mesh #'+inttostr(idx)+' ('+texture+' : '+shader+') is NOT assigned to any valid bone');
    end;

  end;
end;


type
  TChildVertexFilterCallbackData = record
    boneid:TBoneID;
    inverse_flag:boolean;
    flagged_vertices_count:integer;
  end;
  pTChildVertexFilterCallbackData = ^TChildVertexFilterCallbackData;

function ChildRemoveVerticesForBoneIdCallback(vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; userdata:pointer):boolean;
var
  cbdata:pTChildVertexFilterCallbackData;
begin
  cbdata:=pTChildVertexFilterCallbackData(userdata);
  result:=(links.GetWeightForBoneId(cbdata^.boneid)>0);
  if cbdata^.inverse_flag then begin
    result:=not result;
  end;

  if result then begin
    cbdata^.flagged_vertices_count:=cbdata^.flagged_vertices_count+1;
  end;
end;

function TModelSlot._CmdChildFilterBone(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  boneid:TBoneID;
  cbdata:TChildVertexFilterCallbackData;
  shader, texture:string;
  inverse:boolean;
  idx:integer;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    boneid:=INVALID_BONE_ID;

    inverse:=false;
    args:=trimleft(args);
    if (length(args)>0) and (args[1]=COMMANDS_ARGUMENT_INVERSE) then begin
      inverse:=true;
      args:=trimleft(rightstr(args, length(args)-1));
    end;

    if ExtractBoneIdFromString(args, boneid) then begin
      shader:=_data.Meshes().Get(idx).GetTextureData().shader;
      texture:=_data.Meshes().Get(idx).GetTextureData().texture;
      if length(trimleft(args))>0 then begin
        result_description.SetDescription('procedure expects 1 argument');
      end else begin
        cbdata.boneid:=boneid;
        cbdata.flagged_vertices_count:=0;
        cbdata.inverse_flag:=inverse;
        if not _data.Meshes().Get(idx).RemoveVertices(@ChildRemoveVerticesForBoneIdCallback, @cbdata) then begin
          result_description.SetDescription('error filtering vertices of mesh #'+inttostr(idx)+' ('+texture+' : '+shader+')');
        end else if cbdata.flagged_vertices_count = 0 then begin
          result_description.SetDescription('no vertices of mesh #'+inttostr(idx)+' ('+texture+' : '+shader+') were removed');
          result_description.SetWarningFlag(true);
          result:=true;
        end else begin
          result_description.SetDescription('successfully removed '+inttostr(cbdata.flagged_vertices_count)+' vertices of mesh #'+inttostr(idx)+' ('+texture+' : '+shader+')');
          if _data.Meshes().Get(idx).GetVerticesCount() = 0 then begin
            result_description.SetDescription(result_description.GetDescription()+chr($0d)+chr($0a)+'mesh is fully collapsed (no vertices left), please remove it'+chr($0d)+chr($0a));
          end;
          result:=true;
        end;
      end;
    end else begin
      result_description.SetDescription('can''t extract bone id');
    end;
  end;
end;

function TModelSlot._cmdChildSaveToFile(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  path:string;
  s:string;
  idx:integer;
  m:TChunkedMemory;
begin
  result:=false;

  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    path:=args;
    if (length(path)>0) and ((path[1] = '"') or (path[1] = '''')) then begin
      path:=rightstr(path, length(path)-1);
    end;
    if (length(path)>0) and ((path[length(path)] = '"') or (path[length(path)] = '''')) then begin
      path:=leftstr(path, length(path)-1);
    end;

    m:=TChunkedMemory.Create();
    try
      s:=_data.Meshes().Get(idx).Serialize();
      if m.LoadFromString(s) then begin
        result:=m.SaveToFile(args);
      end;
    finally
      FreeAndNil(m);
    end;

    if not result then begin
      result_description.SetDescription('Can''t save child to "'+path+'"');
    end;
  end;
end;

function TModelSlot._cmdChildLodLevelSelect(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx, lvl, maxlevel:integer;
  r:string;
begin
  result:=false;
  r:='';
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    args:=trim(args);
    maxlevel:=_data.Meshes().Get(idx).GetLodLevels()-1;
    lvl:=strtointdef(args, -1);
    if (lvl<0) or (lvl>maxlevel) then begin
      r:='expected number from 0 to '+inttostr(maxlevel);
    end else begin
      if not _data.Meshes().Get(idx).AssignLodLevel(lvl) then begin
        r:='lof level assignment failed';
      end else begin
        result:=true;
      end;
    end;
    result_description.SetDescription(r);
  end;
end;

function TModelSlot._cmdChildLodLevelsRemove(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  r:string;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    result:=_data.Meshes().Get(idx).RemoveUnactiveLodsData();
    if not result then begin
      result_description.SetDescription('Error while removing lods');
    end;
  end;
end;

constructor TModelSlot.Create(id: TSlotId; container: TSlotsContainer);
begin
  _id:=id;
  _data:=TOgfParser.Create();
  _container:=container;
  _selectionarea:=TSelectionArea.Create();

  _commands_selection:=TCommandsStorage.Create(true);
  _commands_selection.DoRegister(TCommandSetup.Create('pivotpoint', nil, @_CmdSetPivot, 'set pivot point for rotation / scaling commands'), CommandItemTypeCall);
  _commands_selection.DoRegister(TCommandSetup.Create('sphere', nil, @_CmdSelectionSphere, 'set spherical selection, expects 4 numbers (center point x,y,z and sphere radius)'), CommandItemTypeCall);
  _commands_selection.DoRegister(TCommandSetup.Create('box', nil, @_CmdSelectionBox, 'set box selection, expects 6 numbers (box left-down and right-up points)'), CommandItemTypeCall);
  _commands_selection.DoRegister(TCommandSetup.Create('reset', nil, @_CmdSelectionClear, 'reset selection'), CommandItemTypeCall);
  _commands_selection.DoRegister(TCommandSetup.Create('inverse', nil, @_CmdSelectionInverse, 'inverse selected area'), CommandItemTypeCall);
  _commands_selection.DoRegister(TCommandSetup.Create('testpoint', nil, @_CmdSelectionTestPoint, 'check if point from arguments is in selected area'), CommandItemTypeCall);
  _commands_selection.DoRegister(TCommandSetup.Create('info', nil, @_CmdSelectionInfo, 'show current selection info'), CommandItemTypeCall);

  _commands_upperlevel:=TCommandsStorage.Create(true);
    _commands_mesh:=TCommandsStorage.Create(true);
      _commands_children:=TChildrenCommands.Create(self);
    _commands_skeleton:=TCommandsStorage.Create(true);
      _commands_bones:=TBonesCommands.Create(self);
      _commands_ikdata:=TBonesCommands.Create(self);

  _commands_upperlevel.DoRegisterPropertyWithSubcommand(TPropertyWithSubcommandsSetup.Create('selection', nil, _commands_selection, 'control pivot point and selection area'));
  _commands_upperlevel.DoRegisterPropertyWithSubcommand(TPropertyWithSubcommandsSetup.Create('mesh', @_IsModelLoadedPrecondition, _commands_mesh, 'access group of properties and procedures associated with model''s mesh'));
  _commands_upperlevel.DoRegisterPropertyWithSubcommand(TPropertyWithSubcommandsSetup.Create('skeleton', @_IsModelLoadedPrecondition, _commands_skeleton, 'access group of properties and procedures associated with model''s mesh'));

  _commands_upperlevel.DoRegister(TCommandSetup.Create('loadfromfile', @_IsModelNotLoadedPrecondition, @_CmdLoadFromFile, 'load OGF data to selected model slot, expects file path'), CommandItemTypeCall);
  _commands_upperlevel.DoRegister(TCommandSetup.Create('savetofile', @_IsModelLoadedPrecondition, @_CmdSaveToFile, 'save data from selected model slot to OGF, expects file path'), CommandItemTypeCall);
  _commands_upperlevel.DoRegister(TCommandSetup.Create('unload', @_IsModelLoadedPrecondition, @_CmdUnload, 'clear selected model slot'), CommandItemTypeCall);
  _commands_upperlevel.DoRegister(TCommandSetup.Create('info', @_IsModelLoadedPrecondition, @_CmdInfo, 'display selected slot info'), CommandItemTypeCall);
  _commands_upperlevel.DoRegister(TCommandSetup.Create('setclipboardmode', nil, @_CmdClipboardMode, 'switches temp buffer between internal storage and system clipboard (globally for all slots)'), CommandItemTypeCall);

  _commands_mesh.DoRegisterPropertyWithSubcommand(TPropertyWithSubcommandsSetup.Create('child', @_IsModelLoadedPrecondition, _commands_children, 'array of sub-meshes with different textures'));
  _commands_mesh.DoRegister(TCommandSetup.Create('pastechild', @_IsModelLoadedPrecondition, @_CmdPasteMeshFromTempBuf, 'paste child previously copied into temp buffer'), CommandItemTypeCall);
  _commands_mesh.DoRegister(TCommandSetup.Create('removecollapsedchildren', @_IsModelLoadedPrecondition, @_CmdRemoveCollapsedMeshes, 'remove all children without real mesh (without vertices)'), CommandItemTypeCall);

  _commands_children.DoRegister(TCommandSetup.Create('info', @_IsModelLoadedPrecondition, @_CmdChildInfo, 'show info'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('settexture', @_IsModelLoadedPrecondition, @_CmdChildSetTexture, 'change assigned shader, expects string argument'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('setshader', @_IsModelLoadedPrecondition, @_CmdChildSetShader, 'change assigned shader, expects string argument'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('remove', @_IsModelLoadedPrecondition, @_CmdChildRemove, 'remove the selected child'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('copy', @_IsModelLoadedPrecondition, @_CmdChildCopy, 'copy child into temp buffer'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('paste', @_IsModelLoadedPrecondition, @_CmdChildPasteData, 'insert new child with data from the temp buffer, expects index for new child'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('moveselected', @_IsModelLoadedPrecondition, @_CmdChildMoveSelected, 'move the entire child, expects 3 numbers (offsets for x,y,z axis)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('scaleselected', @_IsModelLoadedPrecondition, @_CmdChildScaleSelected, 'scale selected part of the child using previously selected pivot point, expects 3 numbers (scaling factor for x,y z axis, negative means mirroring)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('rotateselected', @_IsModelLoadedPrecondition, @_CmdChildRotateSelected, 'rotate selected part of the child, expects a numbers (angle in degrees) and axis letter (x, y or z)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('rebindselected', @_IsModelLoadedPrecondition, @_CmdChildRebindSelected, 'link child vertices in the selection; arg 1 - new bone, arg 2  (optional, omittable) - weight, arg3 - old bone to inbind (optional)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('move', @_IsModelLoadedPrecondition, @_CmdChildMoveAll, 'move selected part of the child, expects 3 numbers (offsets for x,y,z axis)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('rotate', @_IsModelLoadedPrecondition, @_CmdChildRotateAll, 'rotate the entire child, expects a numbers (angle in degrees) and axis letter (x, y or z)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('scale', @_IsModelLoadedPrecondition, @_CmdChildScaleAll, 'scale the entire child using previously selected pivot point, expects 3 numbers (scaling factor for x,y z axis, negative means mirroring)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('rebind', @_IsModelLoadedPrecondition, @_CmdChildRebindAll, 'link child vertices; arg 1 - new bone, arg 2 (optional, omittable) - weight, arg3 - old bone to inbind (optional)'), CommandItemTypeCall);

  _commands_children.DoRegister(TCommandSetup.Create('bonestats', @_IsModelLoadedPrecondition, @_CmdChildBonestats, 'display bones linked with the selected mesh'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('filterbone', @_IsModelLoadedPrecondition, @_CmdChildFilterBone, 'remove all vertices that has no link with the selected bone'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('savetofile', @_IsModelLoadedPrecondition, @_cmdChildSaveToFile, 'save selected child to file (expects file name)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('selectlodlevel', @_IsModelLoadedPrecondition, @_cmdChildLodLevelSelect, 'select lod level, expects number'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('removelodlevels', @_IsModelLoadedPrecondition, @_cmdChildLodLevelsRemove, 'remove all LOD levels except selected'), CommandItemTypeCall);



  _commands_skeleton.DoRegisterPropertyWithSubcommand(TPropertyWithSubcommandsSetup.Create('bone', @_IsModelHasSkeletonPrecondition, _commands_bones, 'access array of bones'));
  _commands_skeleton.DoRegisterPropertyWithSubcommand(TPropertyWithSubcommandsSetup.Create('ikdata', @_IsModelHasSkeletonPrecondition, _commands_ikdata, 'access array of bones'' IK Data'));
  _commands_skeleton.DoRegister(TCommandSetup.Create('uniformscale', @_IsModelHasSkeletonPrecondition, @_CmdSkeletonUniformScale, 'scale skeleton using previously selected pivot point, expects a number (scaling factor, negative means mirroring)'), CommandItemTypeCall);

  _commands_bones.DoRegister(TCommandSetup.Create('info', @_IsModelHasSkeletonPrecondition, @_CmdBoneInfo, 'display info associated with the selected bone'), CommandItemTypeCall);

  _commands_ikdata.DoRegister(TCommandSetup.Create('info', @_IsModelHasSkeletonPrecondition, @_CmdIKDataInfo, 'display IK data info associated with the selected bone'), CommandItemTypeCall);
  _commands_ikdata.DoRegister(TCommandSetup.Create('copy', @_IsModelHasSkeletonPrecondition, @_CmdIKDataCopy, 'copy IK data info of the selected bone to temp buffer'), CommandItemTypeCall);
  _commands_ikdata.DoRegister(TCommandSetup.Create('paste', @_IsModelHasSkeletonPrecondition, @_CmdIKDataPaste, 'replace IK data of the selected bone with data from temp buffer' ), CommandItemTypeCall);

end;

destructor TModelSlot.Destroy;
begin

  FreeAndNil(_commands_ikdata);
  FreeAndNil(_commands_children);
  FreeAndNil(_commands_skeleton);
  FreeAndNil(_commands_mesh);
  FreeAndNil(_commands_upperlevel);
  FreeAndNil(_selectionarea);
  FreeAndNil(_data);
  inherited Destroy;
end;

function TModelSlot.SlotId(): TSlotId;
begin
  result:=_id;
end;

function TModelSlot.Data(): TOgfParser;
begin
  result:=_data;
end;


function TModelSlot.ExecuteCmd(cmd: string): TCommandResult;
begin
  result:=_commands_upperlevel.Execute(cmd, nil);
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
     if _model_slots[i].SlotId() = id then begin
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


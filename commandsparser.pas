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

{ TAnimationsCommands }

TAnimationsCommands = class(TSlotFilteringCommands)
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
  _commands_animations:TAnimationsCommands;
  _commands_mmarks:TCommandsStorage;

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
  function _IsAnimationsLoadedPrecondition(args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;

  function ExtractBoneIdFromString(var inoutstr:string; var boneid:TBoneId):boolean;
  function GetBoneNameById(boneid: TBoneId): string;

  function _CmdLoadFromFile(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdLoadAnimsFromFile(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
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
  function _CmdChildRemoveSelected(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdChildSplitSelected(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;

  function _CmdSkeletonUniformScale(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSkeletonHierarchy(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSkeletonAddBone(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdBoneInfo(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdBoneReparent(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdBoneRename(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdBoneSetBindTransform(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdBoneBindPoseMove(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;

  function _CmdAnimInfo(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimKeyInfo(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimAddMotionMark(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimResetMotionMarks(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;

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

  RegisterFilter('name');
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

{ TAnimationsCommands }

constructor TAnimationsCommands.Create(slot: TModelSlot);
begin
  inherited;

  RegisterFilter('name');
end;

function TAnimationsCommands.GetFilteringItemTypeName(item_id: integer): string;
begin
  result:='animation';
end;

function TAnimationsCommands.GetFilteringItemsCount(): integer;
begin
  result:=0;
  if _slot.Data()<>nil then begin
    if _slot.Data().Animations()<>nil then begin
      result:=_slot.Data().Animations().AnimationsCount();
    end;
  end;
end;

function TAnimationsCommands.CheckFiltersForItem(item_id: integer; filters: TIndexFilters): boolean;
begin
  result:=IsMatchFilter(_slot.Data().Animations().GetAnimationParams(item_id).name, filters[0], FILTER_MODE_EXACT);
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

function TModelSlot._IsAnimationsLoadedPrecondition(args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
begin
  result:=true;
  if not _data.Loaded() then begin
    result_description.SetDescription('Slot is empty. Load data first');
    result:=false;
  end else if _data.Skeleton()=nil then begin
    result_description.SetDescription('Loaded model has no skeleton');
    result:=false;
  end else if _data.Animations()=nil then begin
    result_description.SetDescription('No animations loaded');
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

  // Try to extract bone ID using argument as bone name
  tmpstr:=inoutstr;
  tmpid:=ExtractABNString(tmpstr);
  tmpstr:=TrimLeft(tmpstr);
  tmpid:=trim(tmpid);

  tmp_num:=_data.Skeleton().GetBoneIdxByName(tmpid);

  if tmp_num = INVALID_BONE_ID then begin
    // Try to extract the index itself
    // Index in the output can be invalid! Check it before using!
    tmpstr:=inoutstr;
    tmpid:=ExtractNumericString(tmpstr, true);
    tmpstr:=TrimLeft(tmpstr);
    tmp_num:=strtointdef(tmpid, -2);
    if (tmp_num <> -2) then begin
      result:=(_data.Skeleton().GetBonesCount() > tmp_num);
    end;
  end else begin
    result:=true;
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
  argsparser:TCommandsArgumentsParser;
begin
  result:=false;
  set_zero(v{%H-});
  argsparser:=TCommandsArgumentsParser.Create();
  try
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'X component of new pivot position');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Y component of new pivot position');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Z component of new pivot position');
    if argsparser.Parse(args) and argsparser.GetAsSingle(0, v.x) and argsparser.GetAsSingle(1, v.y) and argsparser.GetAsSingle(2, v.z) then begin
      _selectionarea.SetPivot(v);
      result:=true;
    end else begin
      result_description.SetDescription(argsparser.GetLastErr());
      if length(result_description.GetDescription())=0 then begin
        result_description.SetDescription('can''t get parsed arguments');
      end;
    end;

  finally
    FreeAndNil(argsparser);
  end;
end;

function TModelSlot._CmdSelectionSphere(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  v:FVector3;
  r:single;
  argsparser:TCommandsArgumentsParser;
begin
  result:=false;
  argsparser:=TCommandsArgumentsParser.Create();
  try
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'X coordinate of sphere center');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Y coordinate of sphere center');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Z coordinate of sphere center');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'radius of the sphere');
    if argsparser.Parse(args) and
       argsparser.GetAsSingle(0, v.x) and
       argsparser.GetAsSingle(1, v.y) and
       argsparser.GetAsSingle(2, v.z) and
       argsparser.GetAsSingle(3, r)
    then begin
      _selectionarea.SetSelectionAreaAsSphere(v, r);
      result:=true;
    end else begin
      result_description.SetDescription(argsparser.GetLastErr());
      if length(result_description.GetDescription())=0 then begin
        result_description.SetDescription('can''t get parsed arguments');
      end;
    end;
  finally
    FreeAndNil(argsparser);
  end;
end;

function TModelSlot._CmdSelectionBox(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  p1, p2:FVector3;
  argsparser:TCommandsArgumentsParser;
begin
  result:=false;
  argsparser:=TCommandsArgumentsParser.Create();
  try
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'X coordinate of the 1st point');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Y coordinate of the 1st point');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Z coordinate of the 1st point');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'X coordinate of the 2nd point');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Y coordinate of the 2nd point');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Z coordinate of the 2nd point');
    if argsparser.Parse(args) and
       argsparser.GetAsSingle(0, p1.x) and
       argsparser.GetAsSingle(1, p1.y) and
       argsparser.GetAsSingle(2, p1.z) and
       argsparser.GetAsSingle(3, p2.x) and
       argsparser.GetAsSingle(4, p2.y) and
       argsparser.GetAsSingle(5, p2.z)
    then begin
      _selectionarea.SetSelectionAreaAsBox(p1, p2);
      result:=true;
    end else begin
      result_description.SetDescription(argsparser.GetLastErr());
      if length(result_description.GetDescription())=0 then begin
        result_description.SetDescription('can''t get parsed arguments');
      end;
    end;
  finally
    FreeAndNil(argsparser);
  end;
end;

function TModelSlot._CmdSelectionClear(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
begin
  _selectionarea.ResetSelectionArea();
  result:=true;
end;

type
  TVertexCounterCallbackData = record
    selection_area:TSelectionArea;
    vcnt:integer;
  end;
  pTVertexCounterCallbackData = ^TVertexCounterCallbackData;

function VertexCounterCallback(vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; userdata:pointer):boolean;
var
  cbdata:pTVertexCounterCallbackData;
begin
  result:=true;
  if (userdata = nil) or (data = nil) then exit;
  cbdata:=pTVertexCounterCallbackData(userdata);
  if cbdata^.selection_area.IsPointInSelection(data^.pos) then begin
    cbdata^.vcnt:=cbdata^.vcnt+1;
  end;
end;

function TModelSlot._CmdSelectionInfo(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  r:string;
  r_bones:string;
  i:integer;
  cbdata:TVertexCounterCallbackData;
  v:FVector3;
begin
  r:=_selectionarea.Info();

  if _data.Loaded() then begin
    cbdata.selection_area:=_selectionarea;
    cbdata.vcnt:=0;

    for i:=0 to _data.Meshes().Count()-1 do begin
      _data.Meshes().Get(i).IterateVertices(@VertexCounterCallback, @cbdata);
    end;

    r:=r+chr($0d)+chr($0a)+'Selected vertices count: '+inttostr(cbdata.vcnt);

    r_bones:='';
    for i:=0 to _data.Skeleton().GetBonesCount()-1 do begin
      if data.Skeleton().GetGlobalBonePositionInPose(i, '', -1, v) and _selectionarea.IsPointInSelection(v) then begin
        if length(r_bones)=0 then begin
          r_bones:=r_bones+chr($0d)+chr($0a)+'Selected bones:'+chr($0d)+chr($0a);
        end;
        r_bones:=r_bones+'- '+_data.Skeleton().GetBoneName(i)+' ('+floattostr(v.x)+', '+floattostr(v.y)+', '+floattostr(v.z)+')'+chr($0d)+chr($0a);
      end;
    end;
  end;


  result_description.SetDescription(r+r_bones);
  result:=true;
end;

function TModelSlot._CmdSelectionTestPoint(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  v:FVector3;
  argsparser:TCommandsArgumentsParser;
begin
  result:=false;

  argsparser:=TCommandsArgumentsParser.Create();
  try
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'point X coordinate');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'point Y coordinate');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'point Z coordinate');
    if argsparser.Parse(args) and
       argsparser.GetAsSingle(0, v.x) and
       argsparser.GetAsSingle(1, v.y) and
       argsparser.GetAsSingle(2, v.z)
    then begin
      if _selectionarea.IsPointInSelection(v) then begin
        result_description.SetDescription('Point is inside the selected area');
      end else begin
        result_description.SetDescription('Point is outside the selected area');
      end;
      result:=true;
    end else begin
      result_description.SetDescription(argsparser.GetLastErr());
      if length(result_description.GetDescription())=0 then begin
        result_description.SetDescription('can''t get parsed arguments');
      end;
    end;

  finally
    FreeAndNil(argsparser);
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

function TModelSlot._CmdLoadAnimsFromFile(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
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

  if _data.Animations().AnimationsCount()>0 then begin
    result_description.SetDescription('animations are already loaded, use merge command to load more');
  end else begin
    result:=_data.Animations().LoadFromFile(path);
    if not result then begin
      result_description.SetDescription('Can''t load animations from file "'+path+'"');
    end;
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
      result_description.SetDescription('child #'+inttostr(meshid)+' ('+texture+' : '+shader+') successfully appended');
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
        r:=r+'Failed to remove collapsed child #'+inttostr(i)+' ('+texture+' : '+shader+')'+chr($0d)+chr($0a);
        result:=false;
      end else begin
        r:=r+'Removed collapsed child #'+inttostr(i)+' ('+texture+' : '+shader+')'+chr($0d)+chr($0a);
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
  obb:FObb;
  shape:TOgfBoneShape;
  v1, v2:FVector3;
  n:single;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    r:='Info for bone #'+inttostr(idx)+':'+chr($0d)+chr($0a);
    r:=r+'- Name: '+_data.Skeleton().GetBoneName(idx)+chr($0d)+chr($0a);
    r:=r+'- Parent: '+_data.Skeleton().GetBoneParentName(idx)+chr($0d)+chr($0a);
    r:=r+'- Material: '+data.Skeleton().GetBoneMaterial(idx)+chr($0d)+chr($0a);

    if  _data.Skeleton().GetGlobalBonePositionInPose(idx, '', -1, v1) then begin
      r:=r+'- Bind position: '+floattostr(v1.x)+', '+floattostr(v1.y)+', '+floattostr(v1.z)+chr($0d)+chr($0a);
    end;

    if data.Skeleton().GetBoneBindTransformInParentSpace(idx, v1, v2) then begin
      r:=r+'- Offset: '+floattostr(v1.x)+', '+floattostr(v1.y)+', '+floattostr(v1.z)+chr($0d)+chr($0a);
      r:=r+'- Rotate: '+floattostr(v2.x)+', '+floattostr(v2.y)+', '+floattostr(v2.z)+chr($0d)+chr($0a);
    end;

    if data.Skeleton().GetBoneMassParams(idx, v1, n) then begin
      r:=r+'- Center of mass: '+floattostr(v1.x)+', '+floattostr(v1.y)+', '+floattostr(v1.z)+chr($0d)+chr($0a);
      r:=r+'- Mass: '+floattostr(n)+chr($0d)+chr($0a);
    end;

    if data.Skeleton().GetBoneShape(idx, shape) then begin
      r:=r+'- Shape type: '+inttostr(shape.shape_type)+' ('+ShapeTypeById(shape.shape_type)+')'+chr($0d)+chr($0a);
    end;

    if data.Skeleton().GetBoneBoundingBox(idx, obb) then begin
      r:=r+'- OBB Halfsize: '+floattostr(obb.m_halfsize.x)+', '+floattostr(obb.m_halfsize.y)+', '+floattostr(obb.m_halfsize.z)+chr($0d)+chr($0a);
      r:=r+'- OBB Translate: '+floattostr(obb.m_translate.x)+', '+floattostr(obb.m_translate.y)+', '+floattostr(obb.m_translate.z)+chr($0d)+chr($0a);
      r:=r+'- OBB Rotation Matrix: '+chr($0d)+chr($0a);
      r:=r+'( '+floattostr(obb.m_rotate.i.x)+', '+floattostr(obb.m_rotate.i.y)+', '+floattostr(obb.m_rotate.i.z)+' )'+chr($0d)+chr($0a);
      r:=r+'( '+floattostr(obb.m_rotate.j.x)+', '+floattostr(obb.m_rotate.j.y)+', '+floattostr(obb.m_rotate.j.z)+' )'+chr($0d)+chr($0a);
      r:=r+'( '+floattostr(obb.m_rotate.k.x)+', '+floattostr(obb.m_rotate.k.y)+', '+floattostr(obb.m_rotate.k.z)+' )'+chr($0d)+chr($0a);
    end;

    result_description.SetDescription(r);
    result:=true;
  end;
end;

type
TSkeletonHierarchyCallbackData = record
  skeleton:TOgfSkeleton;
  parent_bonename:string;
  headerstr:string;
  resstr:string;
  cb:TBonesIterationCallback;
end;
pSkeletonHierarchyCallbackData = ^TSkeletonHierarchyCallbackData;

function SkeletonHierarchyCallback(bone_id:integer; bone_data:pTBoneUnitedData; userdata:pointer):boolean;
var
  cbdata:pSkeletonHierarchyCallbackData;
  new_data:TSkeletonHierarchyCallbackData;

begin
  result:=true;
  if (userdata = nil) or (bone_data = nil) then exit;

  cbdata:=pSkeletonHierarchyCallbackData(userdata);

  if cbdata^.parent_bonename = bone_data^.parent_name then begin
    cbdata^.resstr:= cbdata^.resstr+cbdata^.headerstr+bone_data^.name+chr($0a)+chr($0d);

    new_data.headerstr:=cbdata^.headerstr;
    new_data.headerstr:=StringReplace(new_data.headerstr,'-',' ',[rfReplaceAll])+'|-- ';
    new_data.parent_bonename:=bone_data^.name;
    new_data.resstr:='';
    new_data.skeleton:=cbdata^.skeleton;
    new_data.cb:=cbdata^.cb;

    new_data.skeleton.IterateBones(new_data.cb, @new_data);

    cbdata^.resstr:=cbdata^.resstr+new_data.resstr;
  end;
end;


function TModelSlot._CmdSkeletonHierarchy(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  cbdata:TSkeletonHierarchyCallbackData;
begin
  result:=true;

  cbdata.headerstr:='';
  cbdata.parent_bonename:='';
  cbdata.resstr:='';
  cbdata.skeleton:=_data.Skeleton();
  cbdata.cb:=@SkeletonHierarchyCallback;

  _data.Skeleton().IterateBones(@SkeletonHierarchyCallback, @cbdata);
  result_description.SetDescription(cbdata.resstr);
end;

function TModelSlot._CmdSkeletonAddBone(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  argsparser:TCommandsArgumentsParser;
  new_bone_name:string;
  parent_bone_s:string;
  parent_bone_id:TBoneID;
  pos, dir:FVector3;
  is_global:boolean;
  newidx:TBoneID;
begin
  result:=false;

  parent_bone_id:=INVALID_BONE_ID;
    argsparser:=TCommandsArgumentsParser.Create();
  try
    argsparser.RegisterArgument(TCommandsArgumentsParserArgABNString, false, 'new bone name');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgABNString, true, 'parent bone');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, true, 'X coordinate of the new bone');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, true, 'Y coordinate of the new bone');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, true, 'Z coordinate of the new bone');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, true, 'heading of the new bone');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, true, 'pitch of the new bone');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, true, 'bank of the new bone');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgBool, true, 'global coordinates space flag');
        if argsparser.Parse(args) and
       argsparser.GetAsString(0, new_bone_name) and
       argsparser.GetAsString(1, parent_bone_s, '') and
       argsparser.GetAsSingle(2, pos.x, 0) and
       argsparser.GetAsSingle(3, pos.y, 0) and
       argsparser.GetAsSingle(4, pos.z, 0) and
       argsparser.GetAsSingle(5, dir.x, 0) and
       argsparser.GetAsSingle(6, dir.y, 0) and
       argsparser.GetAsSingle(7, dir.z, 0) and
       argsparser.GetAsBool(8, is_global, true)
    then begin
      if _data.Skeleton().GetBoneIdxByName(new_bone_name) <> INVALID_BONE_ID then begin
        result_description.SetDescription('Bone "'+new_bone_name+'" is already exists in the skeleton, please use unique name');
      end else if (length(parent_bone_s) > 0) and not ExtractBoneIdFromString(parent_bone_s, parent_bone_id) then begin
        result_description.SetDescription('Can''t find the specidied parent bone');
      end else begin
        newidx:=_data.Skeleton().AddBone(new_bone_name, parent_bone_id, pos, dir, is_global, true);
          result:=(newidx <> INVALID_BONE_ID);
        if result then begin
          result_description.SetDescription('Bone "'+new_bone_name+'" successfully created with bone id =  '+inttostr(newidx));
        end else begin
          result_description.SetDescription('Error while creating bone "'+new_bone_name+'"');
        end;
      end;
      end else begin
      result_description.SetDescription(argsparser.GetLastErr());
      if length(result_description.GetDescription())=0 then begin
        result_description.SetDescription('can''t get parsed arguments');
      end;
    end;
    finally
    FreeAndNil(argsparser);
  end;
end;

function TModelSlot._CmdBoneReparent(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  preserve_pos:boolean;
  boneids:string;
  new_parent_bone_id:TBoneId;
begin
  result:=false;
  preserve_pos:=true;
  new_parent_bone_id:=INVALID_BONE_ID;

  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgABNString, false, 'bone name or index');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgBool, true, 'preserve global bone position');
      if argsparser.Parse(args) and
         argsparser.GetAsString(0, boneids) and
         argsparser.GetAsBool(1, preserve_pos, true)
      then begin
        if not ExtractBoneIdFromString(boneids, new_parent_bone_id) then begin
          result_description.SetDescription('invalid parent bone ID');
        end else begin
          if not _data.Skeleton().ReparentBone(idx, new_parent_bone_id, preserve_pos) then begin
            result_description.SetDescription('error while reparenting bone '+_data.Skeleton().GetBoneName(idx));
          end else begin
            result_description.SetDescription('bone '+_data.Skeleton().GetBoneName(idx)+' successfully reparented');
            result:=true;
          end;
        end;
      end else begin
        result_description.SetDescription(argsparser.GetLastErr());
        if length(result_description.GetDescription())=0 then begin
          result_description.SetDescription('can''t get parsed arguments');
        end;
      end;
    finally
      FreeAndNil(argsparser);
    end;
  end;
end;

function TModelSlot._CmdBoneRename(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  new_name, old_name:string;
  argsparser:TCommandsArgumentsParser;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgABNString, false, 'new bone name');
      if argsparser.Parse(args) and argsparser.GetAsString(0, new_name) then begin
        old_name:=_data.Skeleton().GetBoneName(idx);
        if (_data.Skeleton().GetBoneIdxByName(new_name) <> INVALID_BONE_ID) then begin
          result_description.SetDescription('bone with name '+new_name+' already present in the skeleton');
        end else if _data.Skeleton().RenameBone(old_name, new_name) then begin
          result_description.SetDescription('bone '+old_name+' successfully renamed to '+new_name);
          result:=true;
        end else begin
          result_description.SetDescription('error while renaming bone '+old_name+' to '+new_name);
        end;
      end else begin
        result_description.SetDescription(argsparser.GetLastErr());
        if length(result_description.GetDescription())=0 then begin
          result_description.SetDescription('can''t get parsed arguments');
        end;
      end;

    finally
      FreeAndNil(argsparser);
    end;
  end;
end;

function TModelSlot._CmdBoneSetBindTransform(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;

  offset, rotate:FVector3;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'X component of offset vector');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Y component of offset vector');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Z component of offset vector');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'X component of rotation vector');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Y component of rotation vector');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Z component of rotation vector');
      if argsparser.Parse(args) and
         argsparser.GetAsSingle(0, offset.x) and
         argsparser.GetAsSingle(1, offset.y) and
         argsparser.GetAsSingle(2, offset.z) and
         argsparser.GetAsSingle(3, rotate.x) and
         argsparser.GetAsSingle(4, rotate.y) and
         argsparser.GetAsSingle(5, rotate.z)
      then begin
        if _data.Skeleton().ForceSetBoneBindPoseTransform(idx, offset, rotate) then begin
          result_description.SetDescription('bind transform successfully changed for bone '+_data.Skeleton().GetBoneName(idx));
          result:=true;
        end else begin
          result_description.SetDescription('can''t change bind transform for bone '+_data.Skeleton().GetBoneName(idx));
        end;
      end else begin
        result_description.SetDescription(argsparser.GetLastErr());
        if length(result_description.GetDescription())=0 then begin
          result_description.SetDescription('can''t get parsed arguments');
        end;
      end;
    finally
      FreeAndNil(argsparser);
    end;
  end;
end;

function TModelSlot._CmdBoneBindPoseMove(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;

  v:FVector3;
  is_absolute_coords:boolean;
  recalc_anims:boolean;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'X component of movement vector');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Y component of movement vector');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Z component of movement vector');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgBool, true, 'absolute coordinates flag');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgBool, true, 'recalculate coordinates in animations');

      if argsparser.Parse(args) and
         argsparser.GetAsSingle(0, v.x) and
         argsparser.GetAsSingle(1, v.y) and
         argsparser.GetAsSingle(2, v.z) and
         argsparser.GetAsBool(3, is_absolute_coords, false) and
         argsparser.GetAsBool(4, recalc_anims, true)
      then begin
        if _data.Skeleton().MoveBoneInBindPose(idx, v, is_absolute_coords, recalc_anims) then begin
          result_description.SetDescription('bind pose position successfully changed for bone '+_data.Skeleton().GetBoneName(idx));
          result:=true;
        end else begin
          result_description.SetDescription('failed to change bind pose position for bone '+_data.Skeleton().GetBoneName(idx));
        end;
      end else begin
        result_description.SetDescription(argsparser.GetLastErr());
        if length(result_description.GetDescription())=0 then begin
          result_description.SetDescription('can''t get parsed arguments');
        end;
      end;
    finally
      FreeAndNil(argsparser);
    end;
  end;
end;

function TModelSlot._CmdAnimInfo(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  animdata:TOgfMotionDefData;
  r:string;
  marks_cnt:integer;
  mark:TOgfMotionMark;
  interval:TOgfMotionMarkInterval;
  i,j:integer;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    args:=trim(args);
    animdata:=_data.Animations().GetAnimationParams(idx);

    if length(animdata.name)>0 then begin
      r:='Animation #'+inttostr(idx)+':'+chr($0d)+chr($0a);
      r:=r+'- Name: '+animdata.name+chr($0d)+chr($0a);
      r:=r+'- Frames count: '+inttostr(_data.Animations().GetAnimationFramesCount(animdata.name))+chr($0d)+chr($0a);
      r:=r+'- Motion ID: '+inttostr(animdata.motion_id)+chr($0d)+chr($0a);
      r:=r+'- Flags: '+inttostr(animdata.flags)+chr($0d)+chr($0a);
      r:=r+'- Speed: '+floattostr(animdata.speed)+chr($0d)+chr($0a);
      r:=r+'- Power: '+floattostr(animdata.power)+chr($0d)+chr($0a);
      r:=r+'- Accrue: '+floattostr(animdata.accrue)+chr($0d)+chr($0a);
      r:=r+'- Falloff: '+floattostr(animdata.falloff)+chr($0d)+chr($0a);
      r:=r+'- Bone or part: '+inttostr(animdata.bone_or_part)+chr($0d)+chr($0a);
      marks_cnt:=animdata.marks.Count();
      r:=r+'- Marks: '+inttostr(marks_cnt)+chr($0d)+chr($0a);
      if marks_cnt>0 then begin
        for i:=0 to marks_cnt-1 do begin
          mark:=animdata.marks.Get(idx);
          if mark<>nil then begin
            r:=r+'- Mark #'+inttostr(i)+' ('+mark.GetName()+')'+chr($0d)+chr($0a);
            for j:=0 to mark.GetIntervalsCount()-1 do begin;
              interval:=mark.GetInterval(j);
              r:=r+'  + Interval #'+inttostr(j)+': from '+floattostr(interval.start)+' to '+floattostr(interval.finish)+chr($0d)+chr($0a);
            end;
          end;
        end;
      end;
      result_description.SetDescription(r);
      result:=true;
    end;

  end;

end;

function TModelSlot._CmdAnimKeyInfo(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  keyid:integer;
  bonename:string;
  defs:TOgfMotionDefData;
  frames_count:integer;
  key:TMotionKey;
  i:integer;
  s,r:string;
  pos:FVector3;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    defs:=_data.Animations().GetAnimationParams(idx);
    frames_count:=_data.Animations().GetAnimationFramesCount(defs.name);

    keyid:=strtointdef(ExtractNumericString(args, false), -1);
    if keyid<0 then begin
      result_description.SetDescription('first argument is an index of key');
      exit;
    end else if keyid > frames_count then begin
      result_description.SetDescription('animation '+defs.name+' has only '+inttostr(frames_count)+' frames');
      exit;
    end;

    args:=trim(args);
    if (length(args)=0) then begin
      bonename:='';
    end else if (args[1]=COMMANDS_ARGUMENTS_SEPARATOR) then begin
      args:=trim(rightstr(args, length(args)-1));
      bonename:=args;
      if length(bonename)=0 then begin
        result_description.SetDescription('bone name expected in optional second argument');
        exit;
      end;
    end else begin
      result_description.SetDescription('can''t extract 2nd argument');
      exit;
    end;

    r:='';
    for i:=0 to _data.Skeleton().GetBonesCount()-1 do begin
      s:=_data.Skeleton().GetBoneName(i);
      if length(s)>0 then begin
        if (length(bonename)=0) or (s=bonename) then begin
          if _data.Animations().GetAnimationKeyForBone(defs.name, s, keyid, key) then begin
            r:=r+'Bone '+s+' data in key '+inttostr(keyid)+':'+chr($0d)+chr($0a);
            r:=r+'- Local position: '+floattostr(key.T.x)+', '+floattostr(key.T.y)+', '+floattostr(key.T.z)+chr($0d)+chr($0a);

            if _data.Skeleton().GetGlobalBonePositionInPose(i, defs.name, keyid, pos) then begin
              r:=r+'- Global position: '+floattostr(pos.x)+', '+floattostr(pos.y)+', '+floattostr(pos.z)+chr($0d)+chr($0a);
            end;
            result:=true;
          end;
        end;
      end;
    end;
    result_description.SetDescription(r);
  end;
end;

function TModelSlot._CmdAnimAddMotionMark(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  name:string;
  interval:TOgfMotionMarkInterval;
  animdata:TOgfMotionDefData;
  t:single;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgABNString, false, 'name of motion mark');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'start time of marked interval');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'end time of marked interval');

      if argsparser.Parse(args) and
         argsparser.GetAsString(0, name) and
         argsparser.GetAsSingle(1, interval.start) and
         argsparser.GetAsSingle(2, interval.finish)
      then begin
        if interval.start > interval.finish then begin
          t:=interval.start;
          interval.start:=interval.finish;
          interval.finish:=t;
        end;
        animdata:=_data.Animations().GetAnimationParams(idx);
        if animdata.marks<>nil then begin
          result:=animdata.marks.Add(name, interval)>=0;
          if result then begin
            result_description.SetDescription('Successfully added new motion mark interval '+name+' to '+animdata.name);
          end;
        end;

      end else begin
        result_description.SetDescription(argsparser.GetLastErr());
        if length(result_description.GetDescription())=0 then begin
          result_description.SetDescription('can''t get parsed arguments');
        end;
      end;

    finally
    end;

  end;
end;


function TModelSlot._CmdAnimResetMotionMarks(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  animdata:TOgfMotionDefData;
 begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    animdata:=_data.Animations().GetAnimationParams(idx);
    if animdata.marks<>nil then begin
      animdata.marks.Reset;
      result_description.SetDescription('motion marks successfully reset for '+animdata.name);
      result:=true;
    end;
  end;
end;


function TModelSlot._CmdChildInfo(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  r:string;
  cbdata:TVertexCounterCallbackData;
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
      r:=r+'- Progressive LOD levels count: '+inttostr(_data.Meshes.Get(idx).GetLodLevels())+chr($0d)+chr($0a);

      cbdata.selection_area:=_selectionarea;
      cbdata.vcnt:=0;
      _data.Meshes.Get(idx).IterateVertices(@VertexCounterCallback, @cbdata);
      r:=r+'- Selected vertices count: '+inttostr(cbdata.vcnt);

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
      result_description.SetDescription('texture successfully updated for child #'+inttostr(idx)+' ('+texture+' : '+shader+')');
      result:=true;
    end else begin
      result_description.SetDescription('can''t update texture for child #'+inttostr(idx)+' ('+texture+' : '+shader+')');
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
      result_description.SetDescription('texture shader updated for child #'+inttostr(idx)+' ('+texture+' : '+shader+')');
      result:=true;
    end else begin
      result_description.SetDescription('can''t update shader for child #'+inttostr(idx)+' ('+texture+' : '+shader+')');
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
      result_description.SetDescription('remove operation failed for child #'+inttostr(idx)+' ('+texture+' : '+shader+')');
    end else begin
      result_description.SetDescription('successfully removed child #'+inttostr(idx)+' ('+texture+' : '+shader+')');
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
      result_description.SetDescription('cannot serialize child #'+inttostr(idx)+' ('+texture+' : '+shader+'), buffer cleared');
      _container.GetTempBuffer().Clear();
    end else begin
      _container.GetTempBuffer().SetData(s, BUFFER_TYPE_CHILDMESH);
      result_description.SetDescription('child #'+inttostr(idx)+' ('+texture+' : '+shader+') successfully saved to temp buffer');
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
        result_description.SetDescription('child #'+inttostr(meshid)+' ('+texture+' : '+shader+') successfully inserted');
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
           result_description.SetDescription('move operation failed for child #'+inttostr(idx)+' ('+texture+' : '+shader+')');
         end else if cbdata.vcnt = 0 then begin
           result_description.SetDescription('no vertices were found in the selection area');
           result_description.SetWarningFlag(true);
           result:=true;
         end else begin
           result_description.SetDescription(inttostr(cbdata.vcnt) +' vertices of child #'+inttostr(idx)+' ('+texture+' : '+shader+') successfully moved');
           result:=true;
         end;
       end;
     end;
  end;
end;

function TModelSlot._CmdChildRotateSelected(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  amount:single;
  s:string;
  axis:TOgfRotationAxis;
  shader, texture:string;
  cbdata:TVertexSelectionCallbackData;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'rotation angle in degrees');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgABNString, false, 'rotation axis');

      if argsparser.Parse(args) and
         argsparser.GetAsSingle(0, amount) and
         argsparser.GetAsString(1, s)
      then begin
         if (s='x') or (s='X') then begin
           axis:=OgfRotationAxisX;
         end else if (s='y') or (s='Y') then begin
           axis:=OgfRotationAxisY;
         end else if (s='z') or (s='Z') then begin
           axis:=OgfRotationAxisZ;
         end else begin
           result_description.SetDescription('rotation axis must be a letter (X, Y or Z)');
           exit;
         end;

         amount:=amount*pi/180;
         cbdata.selection_area:=_selectionarea;
         cbdata.vcnt:=0;
         if not _data.Meshes().Get(idx).RotateUsingStandartAxis(amount, axis, _selectionarea.GetPivot(), @VertexSelectionCallback, @cbdata) then begin
           result_description.SetDescription('rotate operation failed for child #'+inttostr(idx)+' ('+texture+' : '+shader+')');
         end else if cbdata.vcnt = 0 then begin
           result_description.SetDescription('no vertices were found in the selection area');
           result_description.SetWarningFlag(true);
           result:=true;
         end else begin
           shader:=_data.Meshes().Get(idx).GetTextureData().shader;
           texture:=_data.Meshes().Get(idx).GetTextureData().texture;

           result_description.SetDescription(inttostr(cbdata.vcnt) +' vertices of vertices of child #'+inttostr(idx)+' ('+texture+' : '+shader+') successfully rotated');
           result:=true;
         end;
      end else begin
        result_description.SetDescription(argsparser.GetLastErr());
        if length(result_description.GetDescription())=0 then begin
          result_description.SetDescription('can''t get parsed arguments');
        end;
      end;


    finally
      FreeAndNil(argsparser);
    end;
  end;
end;

function TModelSlot._CmdChildScaleSelected(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  argsparser:TCommandsArgumentsParser;
  v:FVector3;
  shader, texture:string;
  idx:integer;
  cbdata:TVertexSelectionCallbackData;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'X component of scaling vector');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Y component of scaling vector');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Z component of scaling vector');

      if argsparser.Parse(args) and
         argsparser.GetAsSingle(0, v.x) and
         argsparser.GetAsSingle(1, v.y) and
         argsparser.GetAsSingle(2, v.z)
      then begin
        shader:=_data.Meshes().Get(idx).GetTextureData().shader;
        texture:=_data.Meshes().Get(idx).GetTextureData().texture;
        cbdata.selection_area:=_selectionarea;
        cbdata.vcnt:=0;
        if not _data.Meshes().Get(idx).Scale(v, _selectionarea.GetPivot(), @VertexSelectionCallback, @cbdata) then begin
          result_description.SetDescription('scale operation failed for child #'+inttostr(idx)+' ('+texture+' : '+shader+')');
        end else if cbdata.vcnt = 0 then begin
          result_description.SetDescription('no vertices of child #'+inttostr(idx)+' ('+texture+' : '+shader+') were found in the selection area');
          result_description.SetWarningFlag(true);
          result:=true;
        end else begin
          result_description.SetDescription(inttostr(cbdata.vcnt) +' vertices of vertices of child #'+inttostr(idx)+' ('+texture+' : '+shader+') successfully scaled');
          result:=true;
        end;
      end else begin
        result_description.SetDescription(argsparser.GetLastErr());
        if length(result_description.GetDescription())=0 then begin
          result_description.SetDescription('can''t get parsed arguments');
        end;
      end;
    finally
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
  dest_bone_s, src_bone_s:string;
  weight: single;
  shader, texture:string;
  idx:integer;
  cbdata:TVertexSelectiveBindCallbackData;
  argsparser:TCommandsArgumentsParser;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    src_boneid:=INVALID_BONE_ID;
    dest_boneid:=INVALID_BONE_ID;
    weight:=-1;

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgABNString, false, 'target (new) bone');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, true, 'weight');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgABNString, true, 'source (old) bone');

      if argsparser.Parse(args) and
         argsparser.GetAsString(0, dest_bone_s) and
         argsparser.GetAsSingle(1, weight, 1) and
         argsparser.GetAsString(2, src_bone_s)
      then begin
        if not ExtractBoneIdFromString(dest_bone_s, dest_boneid) then begin
          result_description.SetDescription('incorrect target bone specified');
        end else if (weight<0) or (weight > 1) then begin
          result_description.SetDescription('weight must be a number between 0 and 1; if you don''t need weight - just omit it in the command)');
        end else if (length(src_bone_s) > 0) and (not ExtractBoneIdFromString(src_bone_s, src_boneid)) then begin
          result_description.SetDescription('incorrect source bone specified');
        end else begin
          shader:=_data.Meshes().Get(idx).GetTextureData().shader;
          texture:=_data.Meshes().Get(idx).GetTextureData().texture;
          cbdata.selection_area:=_selectionarea;
          cbdata.src_boneid:=src_boneid;
          cbdata.weight:=weight;
          cbdata.vcnt:=0;
          if not _data.Meshes().Get(idx).BindVerticesToBone(dest_boneid, @VertexSelectiveBindCallback, @cbdata) then begin
            result_description.SetDescription('failed to rebind vertices of child #'+inttostr(idx)+' ('+texture+' : '+shader+') from '+GetBoneNameById(src_boneid)+' to '+GetBoneNameById(dest_boneid));
          end else begin
            if cbdata.vcnt = 0 then begin
              result_description.SetDescription('no vertices were found in the selection area');
              result_description.SetWarningFlag(true);
            end else begin
              result_description.SetDescription(inttostr(cbdata.vcnt)+' vertices of child #'+inttostr(idx)+' ('+texture+' : '+shader+') are successfully binded to '+GetBoneNameById(dest_boneid));
            end;
            result:=true;
          end;
        end;

      end else begin
        result_description.SetDescription(argsparser.GetLastErr());
        if length(result_description.GetDescription())=0 then begin
          result_description.SetDescription('can''t get parsed arguments');
        end;
      end;

    finally
      FreeAndNil(argsparser);
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
    r:='child #'+inttostr(idx)+' ('+texture+' : '+shader+') is assigned to the following bones:'+chr($0d)+chr($0a);
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
      result_description.SetDescription('child #'+inttostr(idx)+' ('+texture+' : '+shader+') is NOT assigned to any valid bone');
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
          result_description.SetDescription('error filtering vertices of child #'+inttostr(idx)+' ('+texture+' : '+shader+')');
        end else if cbdata.flagged_vertices_count = 0 then begin
          result_description.SetDescription('no vertices of child #'+inttostr(idx)+' ('+texture+' : '+shader+') were removed');
          result_description.SetWarningFlag(true);
          result:=true;
        end else begin
          result_description.SetDescription('successfully removed '+inttostr(cbdata.flagged_vertices_count)+' vertices of child #'+inttostr(idx)+' ('+texture+' : '+shader+')');
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

function TModelSlot._CmdChildRemoveSelected(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx, newidx:integer;
  r:string;
  cbdata:TVertexSelectionCallbackData;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    cbdata.selection_area:=_selectionarea;
    cbdata.vcnt:=0;
    result:=_data.Meshes().Get(idx).RemoveVertices(@VertexSelectionCallback, @cbdata);

    if not result then begin
      result_description.SetDescription('remove operation failed');
    end else if cbdata.vcnt=0 then begin
      result_description.SetDescription('selection area is empty');
      result_description.SetWarningFlag(true);
      result:=true;
    end else begin
      r:='';
      if _data.Meshes().Get(idx).GetVerticesCount() = 0 then begin
        r:='mesh is fully collapsed (no vertices left), please remove it'+chr($0d)+chr($0a);
        result_description.SetWarningFlag(true);
      end;
      r:=r+inttostr(cbdata.vcnt)+ ' vertices successfully removed';
      result_description.SetDescription(r);

      result:=true;
    end;
  end;

end;

function TModelSlot._CmdChildSplitSelected(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx, newidx:integer;
  r:string;
  cbdata_cnt:TVertexCounterCallbackData;
  cbdata_sel:TVertexSelectionCallbackData;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    cbdata_cnt.vcnt:=0;
    cbdata_cnt.selection_area:=_selectionarea;
    _data.Meshes().Get(idx).IterateVertices(@VertexCounterCallback, @cbdata_cnt);

    if cbdata_cnt.vcnt=0 then begin
      result_description.SetDescription('selection area is empty');
    end else if cbdata_cnt.vcnt = _data.Meshes().Get(idx).GetVerticesCount() then begin
      result_description.SetDescription('the whole child mesh is selected');
    end else begin
      r:=_data.Meshes().Get(idx).Serialize();
      newidx:=_data.Meshes().Append(r);
      if newidx<0 then begin
        result_description.SetDescription('error while copying source child');
      end else begin
        _selectionarea.InverseSelectedArea();
        try
          cbdata_sel.selection_area:=_selectionarea;
          cbdata_sel.vcnt:=0;

          result:=_data.Meshes().Get(newidx).RemoveVertices(@VertexSelectionCallback, @cbdata_sel);
        finally
          _selectionarea.InverseSelectedArea();
        end;

        if not result then begin
          _data.Meshes().Remove(newidx);
          result_description.SetDescription('can''t filter selected vertices in new child, aborting');
        end else begin
          cbdata_sel.selection_area:=_selectionarea;
          cbdata_sel.vcnt:=0;

          result:=_data.Meshes().Get(idx).RemoveVertices(@VertexSelectionCallback, @cbdata_sel);
          if not result then begin
            result_description.SetDescription('can''t remove vertices from source child');
          end else begin
            result_description.SetDescription(inttostr(cbdata_sel.vcnt)+' vertices successfully extracted into child #'+inttostr(newidx));
          end;
        end;
      end;

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
      _commands_animations:=TAnimationsCommands.Create(self);
      _commands_mmarks:=TCommandsStorage.Create(true);

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
  _commands_children.DoRegister(TCommandSetup.Create('copy', @_IsModelLoadedPrecondition, @_CmdChildCopy, 'copy child into temp buffer'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('paste', @_IsModelLoadedPrecondition, @_CmdChildPasteData, 'insert new child with data from the temp buffer, expects index for new child'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('move', @_IsModelLoadedPrecondition, @_CmdChildMoveAll, 'move selected part of the child, expects 3 numbers (offsets for x,y,z axis)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('rotate', @_IsModelLoadedPrecondition, @_CmdChildRotateAll, 'rotate the entire child, expects a numbers (angle in degrees) and axis letter (x, y or z)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('scale', @_IsModelLoadedPrecondition, @_CmdChildScaleAll, 'scale the entire child using previously selected pivot point, expects 3 numbers (scaling factor for x,y z axis, negative means mirroring)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('rebind', @_IsModelLoadedPrecondition, @_CmdChildRebindAll, 'link child vertices; arg 1 - new bone, arg 2 (optional, omittable) - weight, arg3 - old bone to inbind (optional)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('remove', @_IsModelLoadedPrecondition, @_CmdChildRemove, 'remove the selected child'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('moveselected', @_IsModelLoadedPrecondition, @_CmdChildMoveSelected, 'move the entire child, expects 3 numbers (offsets for x,y,z axis)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('scaleselected', @_IsModelLoadedPrecondition, @_CmdChildScaleSelected, 'scale selected part of the child using previously selected pivot point, expects 3 numbers (scaling factor for x,y z axis, negative means mirroring)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('rotateselected', @_IsModelLoadedPrecondition, @_CmdChildRotateSelected, 'rotate selected part of the child, expects a numbers (angle in degrees) and axis letter (x, y or z)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('rebindselected', @_IsModelLoadedPrecondition, @_CmdChildRebindSelected, 'link child vertices in the selection; arg 1 - new bone, arg 2  (optional, omittable) - weight, arg3 - old bone to inbind (optional)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('removeselected', @_IsModelLoadedPrecondition, @_CmdChildRemoveSelected, 'remove selected part of child'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('splitselected', @_IsModelLoadedPrecondition, @_CmdChildSplitSelected, 'extract selected part of child into a new child'), CommandItemTypeCall);

  _commands_children.DoRegister(TCommandSetup.Create('bonestats', @_IsModelLoadedPrecondition, @_CmdChildBonestats, 'display bones linked with the selected mesh'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('filterbone', @_IsModelLoadedPrecondition, @_CmdChildFilterBone, 'remove all vertices that has no link with the selected bone'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('savetofile', @_IsModelLoadedPrecondition, @_cmdChildSaveToFile, 'save selected child to file (expects file name)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('selectlodlevel', @_IsModelLoadedPrecondition, @_cmdChildLodLevelSelect, 'select lod level, expects number'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('removelodlevels', @_IsModelLoadedPrecondition, @_cmdChildLodLevelsRemove, 'remove all LOD levels except selected'), CommandItemTypeCall);



  _commands_skeleton.DoRegisterPropertyWithSubcommand(TPropertyWithSubcommandsSetup.Create('bone', @_IsModelHasSkeletonPrecondition, _commands_bones, 'access array of bones'));
  _commands_skeleton.DoRegister(TCommandSetup.Create('uniformscale', @_IsModelHasSkeletonPrecondition, @_CmdSkeletonUniformScale, 'scale skeleton using previously selected pivot point, expects a number (scaling factor, negative means mirroring)'), CommandItemTypeCall);
  _commands_skeleton.DoRegister(TCommandSetup.Create('loadomf', @_IsModelHasSkeletonPrecondition, @_CmdLoadAnimsFromFile, 'load animations from file'), CommandItemTypeCall);
  _commands_skeleton.DoRegister(TCommandSetup.Create('hierarchy', @_IsModelHasSkeletonPrecondition, @_CmdSkeletonHierarchy, 'display bones hierarchy'), CommandItemTypeCall);
  _commands_skeleton.DoRegister(TCommandSetup.Create('addbone', @_IsModelHasSkeletonPrecondition, @_CmdSkeletonAddBone, 'add a new bone, arguments - new bone name, parent bone, optional X, Y, Z, H, P, B, is in global space flag'), CommandItemTypeCall);

  _commands_bones.DoRegister(TCommandSetup.Create('info', @_IsModelHasSkeletonPrecondition, @_CmdBoneInfo, 'display info associated with the selected bone'), CommandItemTypeCall);
  _commands_bones.DoRegister(TCommandSetup.Create('rename', @_IsModelHasSkeletonPrecondition, @_CmdBoneRename, 'rename bone, expects 1 argument - new bone name'), CommandItemTypeCall);
  _commands_bones.DoRegister(TCommandSetup.Create('reparent', @_IsModelHasSkeletonPrecondition, @_CmdBoneReparent, 'change bone parent; arg 1 - new parent, arg 2 (optional) - preserve bone global position (1, default) or not (0)'), CommandItemTypeCall);
  _commands_bones.DoRegister(TCommandSetup.Create('setbindtransform', @_IsModelHasSkeletonPrecondition, @_CmdBoneSetBindTransform, 'directly change bone transform of bind pose (dangerous function, can break anims); args #1, #2, #3 - new offset X,Y,Z; args #4, #5, #6 - new rotation X,Y,Z'), CommandItemTypeCall);
  _commands_bones.DoRegister(TCommandSetup.Create('move', @_IsModelHasSkeletonPrecondition, @_CmdBoneBindPoseMove, 'move bone changing its bind position; args 1,2,3 - x,y,z components of move, arg 4 (optional) - absolute (1) or relative (0, default) movement, arg 5 (optional) - recalculate anims (1, default) or not (0)'), CommandItemTypeCall);

  _commands_skeleton.DoRegisterPropertyWithSubcommand(TPropertyWithSubcommandsSetup.Create('animation', @_IsAnimationsLoadedPrecondition, _commands_animations, 'access group of properties and procedures associated with loaded animations'));
  _commands_animations.DoRegister(TCommandSetup.Create('info', @_IsAnimationsLoadedPrecondition, @_CmdAnimInfo, 'display animations info'), CommandItemTypeCall);
  _commands_animations.DoRegister(TCommandSetup.Create('keyinfo', @_IsAnimationsLoadedPrecondition, @_CmdAnimKeyInfo, 'show bone parameters is specific key; arg 1 - key index, arg 2 (optional) - bone name'), CommandItemTypeCall);


  _commands_animations.DoRegisterPropertyWithSubcommand(TPropertyWithSubcommandsSetup.Create('marks', @_IsAnimationsLoadedPrecondition, _commands_mmarks, 'access group of properties and procedures associated with motion marks'));
  _commands_mmarks.DoRegister(TCommandSetup.Create('add', @_IsAnimationsLoadedPrecondition, @_CmdAnimAddMotionMark, 'add new interval, expects 3 arguments (mark name, interval start, interval end)'), CommandItemTypeCall);
  _commands_mmarks.DoRegister(TCommandSetup.Create('reset', @_IsAnimationsLoadedPrecondition, @_CmdAnimResetMotionMarks, 'reset marks for selected animation'), CommandItemTypeCall);

end;

destructor TModelSlot.Destroy;
begin
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


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
  function CheckFiltersForItem(item_id:integer; filters:TIndexFilters; var filter_passed:boolean):boolean; override;
end;

{ TBonesCommands }

TBonesCommands = class(TSlotFilteringCommands)
public
  constructor Create(slot:TModelSlot);
  function GetFilteringItemTypeName(item_id:integer):string; override;
  function GetFilteringItemsCount():integer; override;
  function CheckFiltersForItem(item_id:integer; filters:TIndexFilters; var filter_passed:boolean):boolean; override;
end;

{ TAnimationsCommands }

TAnimationsCommands = class(TSlotFilteringCommands)
public
  constructor Create(slot:TModelSlot);
  function GetFilteringItemTypeName(item_id:integer):string; override;
  function GetFilteringItemsCount():integer; override;
  function CheckFiltersForItem(item_id:integer; filters:TIndexFilters; var filter_passed:boolean):boolean; override;
end;

TParsedBonesExpressionMode = (ParsedBoneExpressionModeDefault, ParsedBoneExpressionModeAnd, ParsedBoneExpressionModeOr);

{ TParsedBonesExpression }

TParsedBonesExpression = class
  _ids:array of TBoneID;
  _inversed: array of boolean;
  _mode:TParsedBonesExpressionMode;
public
  constructor Create();
  destructor Destroy; override;

  procedure AddParsed(boneid:TBoneId; is_inversed:boolean);
  function ParsedCount():integer;
  function GetParsedBoneId(parsedid:integer):TBoneID;
  function IsParsedBoneIdInversed(parsedid:integer):boolean;

  function GetMode():TParsedBonesExpressionMode;
  procedure SetMode(m:TParsedBonesExpressionMode);

  function IsLinksMatch(links:TVertexBones):boolean;
  function IsBoneIdMatches(boneid:TBoneID):boolean;
  function GetBoneIdIndexInParsed(boneid:TBoneID):integer;
end;

{ TModelSlot }

TModelSlot = class
  _data:TOgfParser;
  _id:TSlotId;
  _container:TSlotsContainer;
  _selectionarea:TSelectionArea;
  _iksolver:TOgfIKSolverBase;

  _commands_selection:TCommandsStorage;
  _commands_upperlevel:TCommandsStorage;
  _commands_mesh:TCommandsStorage;
  _commands_children:TChildrenCommands;
  _commands_skeleton:TCommandsStorage;
  _commands_bones:TBonesCommands;
  _commands_animbones:TBonesCommands;
  _commands_animations:TAnimationsCommands;
  _commands_mmarks:TCommandsStorage;
  _commands_iksolver:TCommandsStorage;

  function _CmdSetPivot(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSelectionSphere(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSelectionBox(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSelectionClear(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSelectionInfo(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSelectionTestPoint(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSelectionInverse(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSelectionSelectPickVertices(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSelectionSelectPickElement(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;

  function _IsModelLoadedPrecondition(args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _IsModelNotLoadedPrecondition(args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _IsModelHasSkeletonPrecondition(args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _IsAnimationsLoadedPrecondition(args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;

  function ExtractBoneIdFromString(var inoutstr:string; var boneid:TBoneId):boolean;
  function ExtractMultipleBoneIdsFromString(var inoutstr:string; out_data:TParsedBonesExpression):boolean;
  function GetBoneNameById(boneid: TBoneId): string;
  function CheckAndCorrectFrameId(var frameid:integer; anim_name:string):boolean;
  function ReplaceWildcards(s:string; arg:TCommandIndexArg):string;

  function _CmdLoadFromFile(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdLoadAnimsFromFile(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSaveToFile(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdSaveAnimsToFile(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdMergeAnimsWithFile(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdUnload(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdInfo(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdClipboardMode(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;

  function _CmdMeshInfo(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdPasteMeshFromTempBuf(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdRemoveCollapsedMeshes(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAddMotionRef(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdResetMotionRefs(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdCalcMeshBounds(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdCopyMeshBounds(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdPasteMeshBounds(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;


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
  function _CmdBoneBindPoseRotateAroundSelf(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdBoneCopySettings(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdBoneApplySettings(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdBoneGenerateShape(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdBoneSetMaterial(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;

  function _CmdAnimInfo(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimSetAccrue(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimSetFalloff(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimSetPower(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimSetSpeed(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimSetFlags(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimRemove(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimRename(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;

  function _CmdAnimKeyInfo(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimKeyPoseCopy(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimBindPoseCopy(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimKeyPosePaste(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimTrackDuplicate(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimTrackCopy(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimTrackPaste(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimTrackSetLength(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimAddMotionMark(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimResetMotionMarks(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimIkRefPose(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;

  function _CmdIKSolverReset(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdIKSolverSimpleLimb(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;

  function _CmdAnimBoneMove(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimBoneRotate(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimBoneSetOrientation(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimBoneSetPosition(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimBoneAim(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimBoneAimToBone(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimBoneFollow(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimBoneCopyKeyToKeys(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimBoneSlerpKeys(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;
  function _CmdAnimBoneApplyDiff(var args:string; cmd:TCommandSetup; result_description:TCommandResult; userdata:TObject):boolean;

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
uses sysutils, strutils, ChunkedFileParser, Math;

const
  BUFFER_TYPE_CHILDMESH:integer=100;
  BUFFER_TYPE_BONEDATA:integer=101;
  BUFFER_TYPE_SKELETONPOSE:integer=102;
  BUFFER_TYPE_SKELETONTRACK:integer=103;
  BUFFER_TYPE_MODELBLIMITS:integer=104;

{ TParsedBonesExpression }

constructor TParsedBonesExpression.Create();
begin
  setlength(_ids, 0);
  setlength(_inversed, 0);
  _mode:=ParsedBoneExpressionModeDefault;
end;

destructor TParsedBonesExpression.Destroy;
begin
  setlength(_ids, 0);
  setlength(_inversed, 0);
  inherited Destroy;
end;

procedure TParsedBonesExpression.AddParsed(boneid: TBoneId; is_inversed: boolean);
var
  i:integer;
begin
  i:=length(_ids);
  setlength(_ids, i+1);
  setlength(_inversed, i+1);

  _ids[i]:=boneid;
  _inversed[i]:=is_inversed;
end;

function TParsedBonesExpression.ParsedCount(): integer;
begin
  result:=length(_ids);
end;

function TParsedBonesExpression.GetParsedBoneId(parsedid: integer): TBoneID;
begin
  result:=INVALID_BONE_ID;
  if (parsedid>=0) and (parsedid < length(_ids)) then begin
    result:=_ids[parsedid];
  end;
end;

function TParsedBonesExpression.IsParsedBoneIdInversed(parsedid: integer): boolean;
begin
  result:=false;
  if (parsedid>=0) and (parsedid < length(_inversed)) then begin
    result:=_inversed[parsedid];
  end;
end;

function TParsedBonesExpression.GetMode(): TParsedBonesExpressionMode;
begin
  result:=_mode;
end;

procedure TParsedBonesExpression.SetMode(m: TParsedBonesExpressionMode);
begin
  _mode:=m;
end;

function TParsedBonesExpression.IsLinksMatch(links: TVertexBones): boolean;
var
  mode:TParsedBonesExpressionMode;
  boneid:TBoneID;
  matches_filter:boolean;
  i:integer;
begin
  mode:=GetMode();

  if (mode = ParsedBoneExpressionModeOr) then begin
    result:=false;
  end else if (mode = ParsedBoneExpressionModeAnd) then begin
    result:=true;
  end else begin
    result:=true;
    exit;
  end;

  for i:=0 to ParsedCount()-1 do begin
    boneid:=GetParsedBoneId(i);
    if boneid= INVALID_BONE_ID then continue;

    matches_filter:=links.GetWeightForBoneId(boneid)>0;
    if IsParsedBoneIdInversed(i) then begin
      matches_filter:=not matches_filter;
    end;

    if matches_filter and (mode = ParsedBoneExpressionModeOr) then begin
      result:=true;
      break;
    end else if not matches_filter and (mode = ParsedBoneExpressionModeAnd) then begin
      result:=false;
      break;
    end;
  end;

end;

function TParsedBonesExpression.IsBoneIdMatches(boneid: TBoneID): boolean;
var
  links:TVertexBones;
  bone:TVertexBone;
begin
  result:=false;
  links:=TVertexBones.Create();
  try
    bone.bone_id:=boneid;
    bone.weight:=1.0;
    if links.AddBone(bone, false) then begin
      result:=IsLinksMatch(links);
    end;
  finally
    FreeAndNil(links);
  end;
end;

function TParsedBonesExpression.GetBoneIdIndexInParsed(boneid: TBoneID): integer;
var
  i:integer;
begin
  result:=-1;

  for i:=0 to length(_ids)-1 do begin
    if _ids[i]=boneid then begin
      result:=i;
      break;
    end;
  end;
end;

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

function TChildrenCommands.CheckFiltersForItem(item_id: integer; filters:TIndexFilters; var filter_passed:boolean): boolean;
begin
  filter_passed:= IsMatchFilter(_slot.Data().Meshes().Get(item_id).GetTextureData().texture, filters[0], FILTER_MODE_EXACT)
              and IsMatchFilter(_slot.Data().Meshes().Get(item_id).GetTextureData().shader,  filters[1], FILTER_MODE_EXACT);
  result:=true;
end;

{ TBonesCommands }

constructor TBonesCommands.Create(slot: TModelSlot);
begin
  inherited;

  RegisterFilter('name');
  RegisterFilter('id');
  RegisterFilter('expr');
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

function TBonesCommands.CheckFiltersForItem(item_id: integer; filters:TIndexFilters; var filter_passed:boolean): boolean;
var
  parsed_bones:TParsedBonesExpression;
  expr:string;
begin
  result:=true;
  filter_passed:=IsMatchFilter(_slot.Data().Skeleton().GetBoneName(item_id), filters[0], FILTER_MODE_EXACT)
             and IsMatchFilter(inttostr(item_id), filters[1], FILTER_MODE_EXACT);

  expr:=filters[2].value;
  if filter_passed and (length(expr)>0) then begin
    parsed_bones:=TParsedBonesExpression.Create();
    try
      if _slot.ExtractMultipleBoneIdsFromString(expr, parsed_bones) then begin
        filter_passed:=parsed_bones.IsBoneIdMatches(item_id);
        if filters[2].inverse then begin
          filter_passed:=not filter_passed;
        end;
      end else begin
        filter_passed:=false;
        result:=false;
      end;
    finally
      FreeAndNil(parsed_bones);
    end;
  end;

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

function TAnimationsCommands.CheckFiltersForItem(item_id: integer; filters: TIndexFilters; var filter_passed:boolean): boolean;
begin
  result:=true;
  filter_passed:=IsMatchFilter(_slot.Data().Animations().GetAnimationParams(item_id).name, filters[0], FILTER_MODE_EXACT);
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
  tmp_num:integer;
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

function TModelSlot.ExtractMultipleBoneIdsFromString(var inoutstr: string; out_data: TParsedBonesExpression): boolean;
var
  inversed:boolean;
  c:char;
  boneid:TBoneID;
  mode:TParsedBonesExpressionMode;
  wait_boolop:boolean;
begin
  result:=false;

  inversed:=false;
  inoutstr:=TrimLeft(inoutstr);
  mode:=ParsedBoneExpressionModeDefault;
  wait_boolop:=false;

  while(length(inoutstr) > 0) do begin
    c:=inoutstr[1];
    if c = '&' then begin
      if not wait_boolop then begin
        result:=false;
        break;
      end;

      if (mode <> ParsedBoneExpressionModeDefault) and (mode <> ParsedBoneExpressionModeAnd) then begin
        result:=false;
        break;
      end;
      mode:=ParsedBoneExpressionModeAnd;
      out_data.SetMode(mode);

      inversed:=false;
      wait_boolop:=false;
      AdvanceString(inoutstr, 1);
      inoutstr:=TrimLeft(inoutstr);
      continue;
    end else if c = '|' then begin
      if not wait_boolop then begin
        result:=false;
        break;
      end;

      if (mode <> ParsedBoneExpressionModeDefault) and (mode <> ParsedBoneExpressionModeOr) then begin
        result:=false;
        break;
      end;
      mode:=ParsedBoneExpressionModeOr;
      out_data.SetMode(mode);

      inversed:=false;
      wait_boolop:=false;
      AdvanceString(inoutstr, 1);
      inoutstr:=TrimLeft(inoutstr);
      continue;
    end else if c = COMMANDS_ARGUMENTS_SEPARATOR then begin
      break;
    end else if wait_boolop then begin
      result:=false;
      break;
    end else if c = COMMANDS_ARGUMENT_INVERSE then begin
      inversed:=true;
      AdvanceString(inoutstr, 1);
    end;

    inoutstr:=TrimLeft(inoutstr);
    if ExtractBoneIdFromString(inoutstr, boneid) and (boneid<>INVALID_BONE_ID) then begin
      out_data.AddParsed(boneid, inversed);
      wait_boolop:=true;
      result:=true;
    end else begin
      result:=false;
      break;
    end;
  end;


  if result and (out_data.GetMode() = ParsedBoneExpressionModeDefault) then begin
    out_data.SetMode(ParsedBoneExpressionModeOr);
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

function TModelSlot.CheckAndCorrectFrameId(var frameid: integer; anim_name: string): boolean;
var
  frames_cnt:integer;
begin
  frames_cnt:=_data.Animations().GetAnimationFramesCount(anim_name);

  if (frameid < 0) then begin
    frameid:=frames_cnt+frameid;
  end;

  result:=(frameid >= 0) and (frameid < frames_cnt);
end;

function TModelSlot.ReplaceWildcards(s: string; arg: TCommandIndexArg): string;
var
  wildcard_text:string;
begin
  if arg.GetWildcardText(wildcard_text) then begin
    result:=StringReplace(s, '*', wildcard_text, [rfReplaceAll]);
  end else begin
    result:=s;
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
  _selectionarea.ResetSelection();
  result:=true;
end;

type
  TVertexCounterCallbackData = record
    selection_area:TSelectionArea;
    vcnt:integer;
    child_id:integer;
  end;
  pTVertexCounterCallbackData = ^TVertexCounterCallbackData;

function VertexCounterCallback(vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; userdata:pointer):boolean;
var
  cbdata:pTVertexCounterCallbackData;
begin
  result:=true;
  if (userdata = nil) or (data = nil) then exit;
  cbdata:=pTVertexCounterCallbackData(userdata);
  if cbdata^.selection_area.IsVertexInSelection(cbdata^.child_id, vertex_id, data^.pos) then begin
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
      cbdata.child_id:=i;
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
      if not _selectionarea.IsSpatialSelectionModeActive() then begin
        result_description.SetDescription('Please activate spatial selection mode first');
      end else if _selectionarea.IsPointInSelection(v) then begin
        result_description.SetDescription('Point is inside the selected area');
      end else begin
        result_description.SetDescription('Point is not in the selected area');
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
  _selectionarea.InverseSelection();
end;

type
  TVertexPickingCallbackData = record
    selection_area:TSelectionArea;
    verts:array of integer;
    childs:array of integer;
    child_id:integer;
  end;
  pTVertexPickingCallbackData = ^TVertexPickingCallbackData;

function VertexPickingCallback(vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; userdata:pointer):boolean;
var
  cbdata:pTVertexPickingCallbackData;
  i:integer;
begin
  result:=true;
  if (userdata = nil) or (data = nil) then exit;
  cbdata:=pTVertexPickingCallbackData(userdata);

  if cbdata^.selection_area.IsPointInSelection(data^.pos) then begin
    i:=length(cbdata^.verts);
    setlength(cbdata^.verts, i+1);
    setlength(cbdata^.childs, i+1);
    cbdata^.verts[i]:=vertex_id;
    cbdata^.childs[i]:=cbdata^.child_id;
  end;
end;

function TModelSlot._CmdSelectionSelectPickVertices(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  p1, p2:FVector3;
  mode:string;
  argsparser:TCommandsArgumentsParser;
  _stashedselection:TSelectionArea;

  cbdata:TVertexPickingCallbackData;
  i:integer;

begin
  result:=false;
  if not _data.Loaded() then exit;

  argsparser:=TCommandsArgumentsParser.Create();
  try
    argsparser.RegisterArgument(TCommandsArgumentsParserArgABNString, true, 'mode');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, true, 'point X coordinate');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, true, 'point Y coordinate');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, true, 'point Z coordinate');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, true, 'sphere radius or box second point X coordinate');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, true, 'box second point Y coordinate');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, true, 'box second point Z coordinate');
    if argsparser.Parse(args) and
       argsparser.GetAsString(0, mode, '') and
       argsparser.GetAsSingle(1, p1.x, 0) and
       argsparser.GetAsSingle(2, p1.y, 0) and
       argsparser.GetAsSingle(3, p1.z, 0) and
       argsparser.GetAsSingle(4, p2.x, 0) and
       argsparser.GetAsSingle(5, p2.y, 0) and
       argsparser.GetAsSingle(6, p2.z, 0)
    then begin
      _stashedselection:=nil;
      if mode = 'box' then begin
        if _selectionarea.IsVertsSelectionModeActive() then begin
          _stashedselection:=_selectionarea;
          _selectionarea:=TSelectionArea.Create();
        end;
        _selectionarea.SetSelectionAreaAsBox(p1, p2);
      end else if mode = 'sphere' then begin
        if _selectionarea.IsVertsSelectionModeActive() then begin
          _stashedselection:=_selectionarea;
          _selectionarea:=TSelectionArea.Create();
        end;
        _selectionarea.SetSelectionAreaAsSphere(p1, p2.x);
      end;

      if _selectionarea.IsSpatialSelectionModeActive() then begin
        cbdata.selection_area:=_selectionarea;
        setlength(cbdata.childs, 0);
        setlength(cbdata.verts, 0);

        for i:=0 to _data.Meshes().Count()-1 do begin
          cbdata.child_id:=i;
          _data.Meshes().Get(i).IterateVertices(@VertexPickingCallback, @cbdata);
        end;

        if length(cbdata.verts)>0 then begin
          for i:=0 to length(cbdata.verts)-1 do begin
            if _stashedselection<>nil then begin
              _stashedselection.AddVertexToSelectionList(cbdata.childs[i], cbdata.verts[i]);
            end else begin
              _selectionarea.AddVertexToSelectionList(cbdata.childs[i], cbdata.verts[i]);
            end;
          end;
          result:=true;
        end else begin
          result_description.SetDescription('no vertices were picked from the selected area');
          result_description.SetWarningFlag(true);
          result:=true;
        end;
      end else begin
        result_description.SetDescription('please select an area before picking vertices');
      end;

      if _stashedselection<>nil then begin
        FreeAndNil(_selectionarea);
        _selectionarea:=_stashedselection;
      end;
    end;

  finally
    FreeAndNil(argsparser);
  end;
end;

type
  TElementsPickingCallbackData = record
    selection_area:TSelectionArea;
    child_id:integer;
    result_verts_count:integer;
  end;
  pTElementsPickingCallbackData = ^TElementsPickingCallbackData;

function ElementsPickingVertexSelectionCallback(vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; userdata:pointer):boolean;
var
  cbdata:pTElementsPickingCallbackData;
begin
  result:=false;
  if (userdata = nil) or (data = nil) then exit;
  cbdata:=pTElementsPickingCallbackData(userdata);

  result:=cbdata^.selection_area.IsVertexInSelection(cbdata^.child_id, vertex_id, data^.pos);
end;

function ElementsPickingVertexResultCallback(vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; userdata:pointer):boolean;
var
  cbdata:pTElementsPickingCallbackData;
  i:integer;
begin
  result:=true;
  if (userdata = nil) or (data = nil) then exit;
  cbdata:=pTElementsPickingCallbackData(userdata);

  cbdata^.result_verts_count:=cbdata^.result_verts_count+1;
  cbdata^.selection_area.AddVertexToSelectionList(cbdata^.child_id, vertex_id);
end;

function TModelSlot._CmdSelectionSelectPickElement(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  sel_cbdata:TElementsPickingCallbackData;
  i:integer;
  last_cnt, cur_cnt:integer;
  s:string;
begin
  result:=false;
  if _data.Loaded() then begin
    // Spatial mode not allowed because the 1st iterarion of the cycle will change selection type to vertex
    if _selectionarea.IsVertsSelectionModeActive() then begin
      sel_cbdata.selection_area:=_selectionarea;
      sel_cbdata.result_verts_count:=0;

      last_cnt:=0;
      s:='';
      for i:=0 to _data.Meshes().Count()-1 do begin
        sel_cbdata.child_id:=i;
        _data.Meshes().Get(i).IterateAllVerticesOfTheSelectedElements(@ElementsPickingVertexSelectionCallback, @ElementsPickingVertexResultCallback, @sel_cbdata);

        cur_cnt:=sel_cbdata.result_verts_count - last_cnt;
        if cur_cnt = _data.Meshes().Get(i).GetVerticesCount() then begin
          if length(s)>0 then begin
            s:=s+chr($0d)+chr($0a);
          end;
          s:=s+'all '+inttostr(cur_cnt)+' vertices of child #'+inttostr(i)+' were selected';
        end;

        last_cnt:=sel_cbdata.result_verts_count;
      end;

      result:=true;
      if length(s)>0 then begin
        result_description.SetDescription(s);
        result_description.SetWarningFlag(true);
      end else if sel_cbdata.result_verts_count = 0 then begin
        result_description.SetDescription('selection is empty');
        result_description.SetWarningFlag(true);
        _selectionarea.ResetSelection();
      end;
    end else begin
      result_description.SetDescription('please pick some vertices into the selection first');
    end;
  end;
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

function TModelSlot._CmdSaveAnimsToFile(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  path:string;
  r:string;
begin
  result:=false;
  r:='';

  path:=args;
  if (length(path)>0) and ((path[1] = '"') or (path[1] = '''')) then begin
    path:=rightstr(path, length(path)-1);
  end;
  if (length(path)>0) and ((path[length(path)] = '"') or (path[length(path)] = '''')) then begin
    path:=leftstr(path, length(path)-1);
  end;

  if _data.IsAnimationsEmbedded() then begin
    if not _data.SplitEmbeddedMotionsIntoSeparateSource() then begin
      r:=r+'Splitting motions into the separate source failed'+chr($0d)+chr($0a);
    end else begin
      r:=r+'Motions successfully splitted, don''t forget to set up motion refs!'+chr($0d)+chr($0a);
      result:=_data.Animations().SaveToFile(path);
    end;
  end else begin
    result:=_data.Animations().SaveToFile(path);
  end;

  if not result then begin
    r:=r+'Can''t save motions to "'+path+'"';
  end;
  result_description.SetDescription(r);
end;

function TModelSlot._CmdMergeAnimsWithFile(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  path:string;
  s_data:string;
  second:TOgfParser;
  i:integer;
begin
  result:=false;

  path:=args;
  if (length(path)>0) and ((path[1] = '"') or (path[1] = '''')) then begin
    path:=rightstr(path, length(path)-1);
  end;
  if (length(path)>0) and ((path[length(path)] = '"') or (path[length(path)] = '''')) then begin
    path:=leftstr(path, length(path)-1);
  end;

  if _data.Animations().AnimationsCount()=0 then begin
    result:=_data.Animations().LoadFromFile(path);
    if not result then begin
      result_description.SetDescription('Can''t load animations from file "'+path+'"');
    end;

  end else begin
    s_data:=_data.Serialize();
    if length(s_data)>0 then begin
      try
        second:=TOgfParser.Create();
        if not second.Deserialize(s_data) then begin
          result_description.SetDescription('model deserialization failed');
        end else begin
          second.Animations().Reset();
          if not second.Animations().LoadFromFile(path) then begin
            result_description.SetDescription('can''t load source OMF');
          end else begin
            if not _data.Animations().MergeContainers(second.Animations()) then begin
              result_description.SetDescription('Merging animations failed');
            end else begin
              result:=true;
            end;
          end;
        end;
      finally
        FreeAndNil(second);
      end;
    end;
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

function TModelSlot._CmdMeshInfo(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  bb:TOgfBBox;
  bs:TOgfBSphere;
  s:string;
begin
  bb:=_data.GetModelBBox();
  bs:=_data.GetModelBSphere();
  s:='';

  s:=s+'Bounding box:'+chr($0d)+chr($0a);
  s:=s+'- min: '+StringFromVector(bb.min)+chr($0d)+chr($0a);
  s:=s+'- max: '+StringFromVector(bb.max)+chr($0d)+chr($0a);

  s:=s+'Bounding sphere:'+chr($0d)+chr($0a);
  s:=s+'- center: '+StringFromVector(bs.c)+chr($0d)+chr($0a);
  s:=s+'- radius: '+floattostr(bs.r)+chr($0d)+chr($0a);


  result_description.SetDescription(s);
  result:=true;
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
  v1:FVector3;
  bonedata:TBoneUnitedData;
  i:integer;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    if not _data.Skeleton().GetBoneUnitedData(idx, bonedata) then exit;

    r:='Info for bone #'+inttostr(idx)+':'+chr($0d)+chr($0a);
    r:=r+'- Name: '+bonedata.name+chr($0d)+chr($0a);
    r:=r+'- Parent: '+bonedata.parent_name+chr($0d)+chr($0a);
    r:=r+'- Material: '+bonedata.material+chr($0d)+chr($0a);

    v1:=v_mul(bonedata.orientation, 180/pi);
    r:=r+'- Offset: '+StringFromVector(bonedata.offset)+chr($0d)+chr($0a);
    r:=r+'- Rotate: '+StringFromVector(v1)+chr($0d)+chr($0a);

    if  _data.Skeleton().GetGlobalBonePositionInPose(idx, '', -1, v1) then begin
      r:=r+'- Bind position in global space: '+StringFromVector(v1)+chr($0d)+chr($0a);
    end;

    r:=r+'- Center of mass: '+StringFromVector(bonedata.center_of_mass)+chr($0d)+chr($0a);
    r:=r+'- Mass: '+floattostr(bonedata.mass)+chr($0d)+chr($0a);

    r:=r+'- Shape type: '+inttostr(bonedata.shape.shape_type)+' ('+ShapeTypeById(bonedata.shape.shape_type)+')'+chr($0d)+chr($0a);
    r:=r+'- Shape flags: '+inttostr(bonedata.shape.flags)+chr($0d)+chr($0a);
    if bonedata.shape.shape_type = OGF_SHAPE_TYPE_BOX then begin
      r:=r+'- Box halfsize: '+StringFromVector(bonedata.shape.box.m_halfsize)+chr($0d)+chr($0a);
      r:=r+'- Box translate: '+StringFromVector(bonedata.shape.box.m_translate)+chr($0d)+chr($0a);
      r:=r+'- Box rotate: '+chr($0d)+chr($0a);
      r:=r+StringFromVector(bonedata.shape.box.m_rotate.i)+chr($0d)+chr($0a);
      r:=r+StringFromVector(bonedata.shape.box.m_rotate.j)+chr($0d)+chr($0a);
      r:=r+StringFromVector(bonedata.shape.box.m_rotate.k)+chr($0d)+chr($0a);
    end else if bonedata.shape.shape_type = OGF_SHAPE_TYPE_SPHERE then begin
      r:=r+'- Sphere center: '+StringFromVector(bonedata.shape.sphere.p)+chr($0d)+chr($0a);
      r:=r+'- Sphere radius: '+floattostr(bonedata.shape.sphere.r)+chr($0d)+chr($0a);
    end else if bonedata.shape.shape_type = OGF_SHAPE_TYPE_CYLINDER then begin
      r:=r+'- Cylinder center: '+StringFromVector(bonedata.shape.cylinder.m_center)+chr($0d)+chr($0a);
      r:=r+'- Cylinder direction: '+StringFromVector(bonedata.shape.cylinder.m_direction)+chr($0d)+chr($0a);
      r:=r+'- Cylinder radius: '+floattostr(bonedata.shape.cylinder.m_radius)+chr($0d)+chr($0a);
      r:=r+'- Cylinder height: '+floattostr(bonedata.shape.cylinder.m_height)+chr($0d)+chr($0a);
    end;

    r:=r+'- Joint type: '+inttostr(bonedata.ikdata.jointtype)+chr($0d)+chr($0a);
    r:=r+'- Joint IK flags: '+inttostr(bonedata.ikdata.ik_flags)+chr($0d)+chr($0a);
    r:=r+'- Joint limits:'+chr($0d)+chr($0a);
    for i:=0 to length(bonedata.ikdata.limits) do begin
      r:=r+inttostr(i)+': ('+floattostr(bonedata.ikdata.limits[i].limit.x)+', '+floattostr(bonedata.ikdata.limits[i].limit.y)+'), spring = '+floattostr(bonedata.ikdata.limits[i].spring_factor)+', damping = '+floattostr(bonedata.ikdata.limits[i].damping_factor)+chr($0d)+chr($0a);
    end;
    r:=r+'- Joint spring factor: '+floattostr(bonedata.ikdata.spring_factor)+chr($0d)+chr($0a);
    r:=r+'- Joint damping factor: '+floattostr(bonedata.ikdata.damping_factor)+chr($0d)+chr($0a);
    r:=r+'- Joint break force: '+floattostr(bonedata.ikdata.break_force)+chr($0d)+chr($0a);
    r:=r+'- Joint break torque: '+floattostr(bonedata.ikdata.break_torque)+chr($0d)+chr($0a);
    r:=r+'- Joint friction: '+floattostr(bonedata.ikdata.friction)+chr($0d)+chr($0a);

    r:=r+'- Bone OBB Halfsize: '+StringFromVector(bonedata.obb.m_halfsize)+chr($0d)+chr($0a);
    r:=r+'- Bone OBB Translate: '+StringFromVector(bonedata.obb.m_translate)+chr($0d)+chr($0a);
    r:=r+'- Bone OBB Rotation Matrix: '+chr($0d)+chr($0a);
    r:=r+StringFromVector(bonedata.obb.m_rotate.i)+chr($0d)+chr($0a);
    r:=r+StringFromVector(bonedata.obb.m_rotate.j)+chr($0d)+chr($0a);
    r:=r+StringFromVector(bonedata.obb.m_rotate.k)+chr($0d)+chr($0a);

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
        dir:=v_mul(dir, pi/180);

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
      argsparser.RegisterArgument(TCommandsArgumentsParserArgABNStringWithWildcard, false, 'new bone name');
      if argsparser.Parse(args) and argsparser.GetAsString(0, new_name) then begin
        new_name:=ReplaceWildcards(new_name, userdata as TCommandIndexArg);
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
  fix_children:boolean;
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
      argsparser.RegisterArgument(TCommandsArgumentsParserArgBool, true, 'fix children');

      if argsparser.Parse(args) and
         argsparser.GetAsSingle(0, v.x) and
         argsparser.GetAsSingle(1, v.y) and
         argsparser.GetAsSingle(2, v.z) and
         argsparser.GetAsBool(3, is_absolute_coords, false) and
         argsparser.GetAsBool(4, fix_children, false)
      then begin
        if _iksolver<>nil then begin
          result_description.SetDescription('IK doesn''t supported when changing bind pose, please reset IK solver!');
        end else if _data.Skeleton().MoveBone(idx, v, '', -1, is_absolute_coords, fix_children, nil) then begin
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

function TModelSlot._CmdBoneBindPoseRotateAroundSelf(var args: string;cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  is_global:boolean;
  v:FVector3;
  mode:TOgfBoneRotationMode;

begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'X component of rotation vector');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Y component of rotation vector');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Z component of rotation vector');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgBool, true, 'is global space axis');

      if argsparser.Parse(args) and
         argsparser.GetAsSingle(0, v.x) and
         argsparser.GetAsSingle(1, v.y) and
         argsparser.GetAsSingle(2, v.z) and
         argsparser.GetAsBool(3, is_global, false)
      then begin
        if is_global then begin
          mode:=BoneRotationGlobalAroundSelf;
        end else begin
          mode:=BoneRotationLocal;
        end;

        v:=v_mul(v, pi/180);
        if _iksolver<>nil then begin
          result_description.SetDescription('IK doesn''t supported when changing bind pose, please reset IK solver!');
        end else if _data.Skeleton().RotateBone(idx, v, '', -1, mode, nil) then begin
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

function TModelSlot._CmdBoneCopySettings(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  s:string;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    s:=_data.Skeleton().CopyBoneParameters(idx);
    if length(s)=0 then begin
      result_description.SetDescription('can''t serialize bone data');
    end else begin
      _container.GetTempBuffer().SetData(s, BUFFER_TYPE_BONEDATA);
      result:=true;
    end;
  end;

end;

function TModelSlot._CmdBoneApplySettings(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  s:string;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    if not _container.GetTempBuffer().GetData(s, BUFFER_TYPE_BONEDATA) then begin
      result_description.SetDescription('can''t get data from the temp buffer');
    end else if not _data.Skeleton().ApplyBoneParameters(idx, s) then begin
      result_description.SetDescription('can''t apply data from the temp buffer');
    end else begin
      result:=true;
    end;
  end;

end;

function TModelSlot._CmdBoneGenerateShape(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;

  t:string;
  shape:TOgfBoneShape;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgABNString, false, 'shape type');

      if argsparser.Parse(args) and
         argsparser.GetAsString(0, t, 'box')
      then begin

        if t = 'box' then begin
          shape:=_data.GenerateBoneShapeAABB(idx);
          if shape.shape_type = OGF_SHAPE_TYPE_BOX then begin
            if not (_data.Skeleton().SetBoneShape(idx, shape)) then begin
              result_description.SetDescription('can''t set result shape');
            end else begin
              result:=true;
            end;
            shape.box.m_halfsize:=v_mul(shape.box.m_halfsize, 0.95);
            _data.Skeleton().SetBoneObb(idx, shape.box);
          end else if shape.shape_type = OGF_SHAPE_TYPE_NONE then begin
            result_description.SetWarningFlag(true);
            result_description.SetDescription('no linked mesh for shape generation for bone #'+inttostr(idx));
            _data.Skeleton().SetBoneShape(idx, shape);
            result:=true;
          end else begin
            result_description.SetDescription('AABB shape generation failed for bone #'+inttostr(idx));
          end;

        end else if t = 'none' then begin
          _data.Skeleton().GetBoneShape(idx, shape);
          shape.shape_type:=OGF_SHAPE_TYPE_NONE;
          if not (_data.Skeleton().SetBoneShape(idx, shape)) then begin
            result_description.SetDescription('can''t set shape');
          end else begin
            result:=true;
          end;
        end else begin
          result_description.SetDescription('unknown shape type: '+t);
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

function TModelSlot._CmdBoneSetMaterial(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  material:string;
  argsparser:TCommandsArgumentsParser;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgAnyString, false, 'material name');
      if argsparser.Parse(args) and argsparser.GetAsString(0, material) then begin
        if _data.Skeleton().SetBoneMaterial(idx, material) then begin
          result:=true;
        end else begin
          result_description.SetDescription('error while assigning material name for bone #'+inttostr(idx));
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

function TModelSlot._CmdAnimSetAccrue(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  value:single;
  defs:TOgfMotionDefData;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    defs:=_data.Animations().GetAnimationParams(idx);
    if length(defs.name)=0 then exit;

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'new value');
      if argsparser.Parse(args) and
         argsparser.GetAsSingle(0, value)
      then begin
        defs.accrue:=value;
        if not _data.Animations().UpdateAnimationParams(idx, defs) then begin
          result_description.SetDescription('can''t update animation params');
        end else begin
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
  end
end;

function TModelSlot._CmdAnimSetFalloff(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  value:single;
  defs:TOgfMotionDefData;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    defs:=_data.Animations().GetAnimationParams(idx);
    if length(defs.name)=0 then exit;

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'new value');
      if argsparser.Parse(args) and
         argsparser.GetAsSingle(0, value)
      then begin
        defs.falloff:=value;
        if not _data.Animations().UpdateAnimationParams(idx, defs) then begin
          result_description.SetDescription('can''t update animation params');
        end else begin
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
  end
end;

function TModelSlot._CmdAnimSetPower(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  value:single;
  defs:TOgfMotionDefData;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    defs:=_data.Animations().GetAnimationParams(idx);
    if length(defs.name)=0 then exit;

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'new value');
      if argsparser.Parse(args) and
         argsparser.GetAsSingle(0, value)
      then begin
        defs.power:=value;
        if not _data.Animations().UpdateAnimationParams(idx, defs) then begin
          result_description.SetDescription('can''t update animation params');
        end else begin
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
  end
end;

function TModelSlot._CmdAnimSetSpeed(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  value:single;
  defs:TOgfMotionDefData;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    defs:=_data.Animations().GetAnimationParams(idx);
    if length(defs.name)=0 then exit;

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'new value');
      if argsparser.Parse(args) and
         argsparser.GetAsSingle(0, value)
      then begin
        defs.speed:=value;
        if not _data.Animations().UpdateAnimationParams(idx, defs) then begin
          result_description.SetDescription('can''t update animation params');
        end else begin
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
  end
end;

function TModelSlot._CmdAnimSetFlags(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  value:integer;
  defs:TOgfMotionDefData;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    defs:=_data.Animations().GetAnimationParams(idx);
    if length(defs.name)=0 then exit;

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'new value');
      if argsparser.Parse(args) and
         argsparser.GetAsInt(0, value)
      then begin
        defs.flags:=value;
        if not _data.Animations().UpdateAnimationParams(idx, defs) then begin
          result_description.SetDescription('can''t update animation params');
        end else begin
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
  end
end;

function TModelSlot._CmdAnimRemove(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  defs:TOgfMotionDefData;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();
    defs:=_data.Animations().GetAnimationParams(idx);
    if length(defs.name)=0 then exit;

    if _data.Animations().DeleteAnimation(defs.name) then begin
      result:=true;
    end else begin
      result_description.SetDescription('error while removing animation '+defs.name);
    end;
  end;
end;

function TModelSlot._CmdAnimRename(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  defs:TOgfMotionDefData;
  newname:string;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    defs:=_data.Animations().GetAnimationParams(idx);
    if length(defs.name)=0 then exit;

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgABNStringWithWildcard, false, 'new name for the animation');
      if argsparser.Parse(args) and
         argsparser.GetAsString(0, newname)
      then begin
        newname:=ReplaceWildcards(newname, userdata as TCommandIndexArg);

        if _data.Animations().GetAnimationIdByName(newname) >=0 then begin
          result_description.SetDescription('name '+newname+' already in use');
        end else begin
          if _data.Animations().RenameAnimation(defs.name, newname) then begin
            result_description.SetDescription('motion '+defs.name+' successfully renamed to '+newname);
            result:=true;
          end else begin
            result_description.SetDescription('error while duplicating '+defs.name);
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

function TModelSlot._CmdAnimKeyInfo(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  keyid:integer;
  bones_s, r, s:string;
  defs:TOgfMotionDefData;
  parsed_bones:TParsedBonesExpression;
  i:integer;
  key:TMotionKey;
  pos:FVector3;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    argsparser:=TCommandsArgumentsParser.Create();
    parsed_bones:=TParsedBonesExpression.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'frame index');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgAnyString, true, 'bones expression');

      if argsparser.Parse(args) and
         argsparser.GetAsInt(0, keyid) and
         argsparser.GetAsString(1, bones_s, '')
      then begin
        defs:=_data.Animations().GetAnimationParams(idx);

        if not CheckAndCorrectFrameId(keyid, defs.name) then begin
          result_description.SetDescription('invalid frame index');
        end else if (length(bones_s) > 0) and not ExtractMultipleBoneIdsFromString(bones_s, parsed_bones) then begin
          result_description.SetDescription('invalid bones expression');
        end else begin
          r:='';
          for i:=0 to _data.Skeleton().GetBonesCount()-1 do begin
            s:=_data.Skeleton().GetBoneName(i);
            if length(s)>0 then begin
              if (parsed_bones.ParsedCount()=0) or parsed_bones.IsBoneIdMatches(i) then begin
                if _data.Animations().GetAnimationKeyForBone(defs.name, s, keyid, key) then begin
                  r:=r+'Bone '+s+' data in key '+inttostr(keyid)+':'+chr($0d)+chr($0a);
                  r:=r+'- Local position: '+floattostr(key.T.x)+', '+floattostr(key.T.y)+', '+floattostr(key.T.z)+chr($0d)+chr($0a);
                  r:=r+'- Local rotation: '+floattostr(key.Q.x)+', '+floattostr(key.Q.y)+', '+floattostr(key.Q.z)+', '+floattostr(key.Q.w)+chr($0d)+chr($0a);

                  if _data.Skeleton().GetGlobalBonePositionInPose(i, defs.name, keyid, pos) then begin
                    r:=r+'- Global position: '+floattostr(pos.x)+', '+floattostr(pos.y)+', '+floattostr(pos.z)+chr($0d)+chr($0a);
                  end;
                end;
              end;
            end;
          end;
          if length(r)=0 then begin
            r:='no bones match the specified expression';
            result_description.SetWarningFlag(true);
          end;
          result_description.SetDescription(r);
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
      FreeAndNil(parsed_bones);
    end;
  end
end;

function TModelSlot._CmdAnimKeyPoseCopy(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  frameid:integer;
  defs:TOgfMotionDefData;
  pose:TOgfSkeletonPose;
  bones_s:string;
  s:string;
  parsed_bones:TParsedBonesExpression;
  i, cnt:integer;
  bonename:string;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    defs:=_data.Animations().GetAnimationParams(idx);
    if length(defs.name)=0 then exit;


    argsparser:=TCommandsArgumentsParser.Create();
    pose:=TOgfSkeletonPose.Create();
    parsed_bones:=TParsedBonesExpression.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'frame index');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgAnyString, true, 'bones');
      if argsparser.Parse(args) and
         argsparser.GetAsInt(0, frameid) and
         argsparser.GetAsString(1, bones_s)
      then begin
        if not CheckAndCorrectFrameId(frameid, defs.name) then begin
          result_description.SetDescription('invalid frame index');
        end else if not _data.Skeleton().GetSkeletonPose(defs.name, frameid, pose) then begin
          result_description.SetDescription('can''t get skeleton pose');
        end else if (length(bones_s)>0) and not ExtractMultipleBoneIdsFromString(bones_s, parsed_bones) then begin
          result_description.SetDescription('can''t parse bones');
        end else begin
          cnt:=0;
          for i:=0 to _data.Skeleton().GetBonesCount()-1 do begin
            if (parsed_bones.ParsedCount() > 0) and not parsed_bones.IsBoneIdMatches(i) then begin
              bonename:=_data.Skeleton().GetBoneName(i);
              pose.ForgetBone(bonename);
            end else begin
              cnt := cnt+1;
            end;
          end;

          if cnt = 0 then begin
            result_description.SetDescription('no bones matched the expression, nothing copied');
            result_description.SetWarningFlag(true);
            result:=true;
          end else begin
            s:=pose.Serialize();
            if length(s)=0 then begin
              result_description.SetDescription('can''t serialize pose');
            end else begin
              _container.GetTempBuffer().SetData(s, BUFFER_TYPE_SKELETONPOSE);
              result_description.SetDescription('pose of '+inttostr(cnt)+' bone(s) saved into the temp buffer');
              result:=true;
            end;
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
      FreeAndNil(pose);
      FreeAndNil(parsed_bones);
    end;
  end;
end;

function TModelSlot._CmdAnimBindPoseCopy(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  pose:TOgfSkeletonPose;
  bones_s:string;
  s:string;
  parsed_bones:TParsedBonesExpression;
  i, cnt:integer;
  bonename:string;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    argsparser:=TCommandsArgumentsParser.Create();
    pose:=TOgfSkeletonPose.Create();
    parsed_bones:=TParsedBonesExpression.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgAnyString, true, 'bones');
      if argsparser.Parse(args) and
         argsparser.GetAsString(0, bones_s)
      then begin
        if not _data.Skeleton().GetSkeletonPose('', -1, pose) then begin
          result_description.SetDescription('can''t get skeleton pose');
        end else if (length(bones_s)>0) and not ExtractMultipleBoneIdsFromString(bones_s, parsed_bones) then begin
          result_description.SetDescription('can''t parse bones');
        end else begin
          cnt:=0;
          for i:=0 to _data.Skeleton().GetBonesCount()-1 do begin
            if (parsed_bones.ParsedCount() > 0) and not parsed_bones.IsBoneIdMatches(i) then begin
              bonename:=_data.Skeleton().GetBoneName(i);
              pose.ForgetBone(bonename);
            end else begin
              cnt := cnt+1;
            end;
          end;

          if cnt = 0 then begin
            result_description.SetDescription('no bones matched the expression, nothing copied');
            result_description.SetWarningFlag(true);
            result:=true;
          end else begin
            s:=pose.Serialize();
            if length(s)=0 then begin
              result_description.SetDescription('can''t serialize pose');
            end else begin
              _container.GetTempBuffer().SetData(s, BUFFER_TYPE_SKELETONPOSE);
              result_description.SetDescription('pose of '+inttostr(cnt)+' bone(s) saved into the temp buffer');
              result:=true;
            end;
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
      FreeAndNil(pose);
      FreeAndNil(parsed_bones);
    end;
  end;
end;

function TModelSlot._CmdAnimKeyPosePaste(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  frameid_first, frameid_last:integer;
  defs:TOgfMotionDefData;
  pose:TOgfSkeletonPose;
  s:string;
  cnt, i:integer;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    defs:=_data.Animations().GetAnimationParams(idx);
    if length(defs.name)=0 then exit;

    if not _container.GetTempBuffer().GetData(s, BUFFER_TYPE_SKELETONPOSE) then begin
      result_description.SetDescription('can''t get serialized pose from the temp buffer');
      exit;
    end;

    argsparser:=TCommandsArgumentsParser.Create();
    pose:=TOgfSkeletonPose.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'first frame index');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, true, 'last frame index');
      if argsparser.Parse(args) and
         argsparser.GetAsInt(0, frameid_first) and
         argsparser.GetAsInt(1, frameid_last, frameid_first)
      then begin
        if not CheckAndCorrectFrameId(frameid_first, defs.name) then begin
          result_description.SetDescription('invalid first frame index');
        end else if not CheckAndCorrectFrameId(frameid_last, defs.name) then begin
          result_description.SetDescription('invalid last frame index');
        end else if not pose.Deserialize(s) then begin
          result_description.SetDescription('can''t deserialize pose');
        end else begin
          for i:=frameid_first to frameid_last do begin
            if i=frameid_first then begin
              cnt:=_data.Skeleton().SetSkeletonPose(defs.name, i, pose);
              if cnt = 0 then begin
                result_description.SetDescription('can''t set pose for any bone');
                break;
              end;
            end else if _data.Skeleton().SetSkeletonPose(defs.name, i, pose) <> cnt then begin
              result_description.SetDescription('set bones count for frame #'+inttostr(i)+' differs from previous, aborting operation');
              break;
            end;
          end;

          if length(result_description.GetDescription()) = 0 then begin
            result_description.SetDescription('pose set for '+inttostr(cnt)+' bone(s)');
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
      FreeAndNil(pose);
    end;
  end;
end;

function TModelSlot._CmdAnimTrackDuplicate(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  defs:TOgfMotionDefData;
  newname:string;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    defs:=_data.Animations().GetAnimationParams(idx);
    if length(defs.name)=0 then exit;

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgABNStringWithWildcard, false, 'name of the duplicated animation');
      if argsparser.Parse(args) and
         argsparser.GetAsString(0, newname)
      then begin
        newname:=ReplaceWildcards(newname, userdata as TCommandIndexArg);

        if _data.Animations().GetAnimationIdByName(newname) >=0 then begin
          result_description.SetDescription('name '+newname+' already in use');
        end else begin
          if _data.Animations().DuplicateAnimation(defs.name, newname) then begin
            result_description.SetDescription('motion '+defs.name+' successfully duplicated as '+newname);
            result:=true;
          end else begin
            result_description.SetDescription('error while duplicating '+defs.name);
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

function TModelSlot._CmdAnimTrackCopy(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  defs:TOgfMotionDefData;
  first_key_id:integer;
  last_key_id:integer;
  poses:TOgfSkeletonPoseSeq;
  pose:TOgfSkeletonPose;
  s:string;

  parsed_bones:TParsedBonesExpression;
  bones_s, bonename:string;
  boneid:TBoneID;
  i,j:integer;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    defs:=_data.Animations().GetAnimationParams(idx);
    if length(defs.name)=0 then exit;

    argsparser:=TCommandsArgumentsParser.Create();
    parsed_bones:=TParsedBonesExpression.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, true, 'first frame index to copy');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, true, 'last frame index to copy');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgAnyString, true, 'bones');
      if argsparser.Parse(args) and
         argsparser.GetAsInt(0, first_key_id, 0) and
         argsparser.GetAsInt(1, last_key_id, -1) and
         argsparser.GetAsString(2, bones_s, '')
      then begin
        poses:=TOgfSkeletonPoseSeq.Create();
        try
          if not CheckAndCorrectFrameId(first_key_id, defs.name) then begin
            result_description.SetDescription('invalid first frame index');
          end else if not CheckAndCorrectFrameId(last_key_id, defs.name) then begin
            result_description.SetDescription('invalid last frame index');
          end else if (length(bones_s) > 0) and not ExtractMultipleBoneIdsFromString(bones_s, parsed_bones) then begin
            result_description.SetDescription('can''t parse bones expression');
          end else if not  _data.Skeleton().GetSkeletonPosesSequence(defs.name, first_key_id, last_key_id, poses) then begin
            result_description.SetDescription('can''t get frames data');
          end else begin
            if (parsed_bones.ParsedCount()>0) then begin
              for i:=0 to poses.Count()-1 do begin
                pose:=poses.Get(i);
                for j:=pose.BonesCount()-1 downto 0 do begin
                  bonename:=pose.GetBonename(j);
                  boneid:=_data.Skeleton().GetBoneIdxByName(bonename);

                  if (boneid = INVALID_BONE_ID) or (not parsed_bones.IsBoneIdMatches(boneid)) then begin
                    pose.ForgetBone(bonename);
                  end;
                end;
              end;
            end;

            s:=poses.Serialize();
            if length(s)=0 then begin
              result_description.SetDescription('can''t serialize data');
            end else begin
              _container.GetTempBuffer().SetData(s, BUFFER_TYPE_SKELETONTRACK);
              result:=true;
            end;
          end;
        finally
          FreeAndNil(poses);
        end;

      end else begin
        result_description.SetDescription(argsparser.GetLastErr());
        if length(result_description.GetDescription())=0 then begin
          result_description.SetDescription('can''t get parsed arguments');
        end;
      end;
    finally
      FreeAndNil(argsparser);
      FreeAndNil(parsed_bones);
    end;
  end;
end;

function TModelSlot._CmdAnimTrackPaste(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  defs:TOgfMotionDefData;
  first_key_id:integer;
  is_insert_mode:boolean;
  poses:TOgfSkeletonPoseSeq;
  s:string;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    defs:=_data.Animations().GetAnimationParams(idx);
    if length(defs.name)=0 then exit;

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'first frame index to paste');
      argsparser.RegisterArgument(TCommandsArgumentsParserArgBool, true, 'insert mode (default true)');
      if argsparser.Parse(args) and
         argsparser.GetAsInt(0, first_key_id, -1) and
         argsparser.GetAsBool(1, is_insert_mode, true)
      then begin
        poses:=TOgfSkeletonPoseSeq.Create();
        try
          if not CheckAndCorrectFrameId(first_key_id, defs.name) then begin
            result_description.SetDescription('invalid frame index');
          end else if not _container.GetTempBuffer().GetData(s, BUFFER_TYPE_SKELETONTRACK) then begin
            result_description.SetDescription('can''t get data from temp buffer');
          end else if not poses.Deserialize(s) then begin
            result_description.SetDescription('can''t deserialize data');
          end else if not _data.Skeleton().PasteSkeletonPosesSequence(defs.name, first_key_id, is_insert_mode, poses) then begin
            result_description.SetDescription('can''t paste data');
          end else begin
            result:=true;
          end;
        finally
          FreeAndNil(poses);
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

function TModelSlot._CmdAnimTrackSetLength(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  defs:TOgfMotionDefData;
  newlen:integer;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    defs:=_data.Animations().GetAnimationParams(idx);
    if length(defs.name)=0 then exit;

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'new animation length');
      if argsparser.Parse(args) and
         argsparser.GetAsInt(0, newlen)
      then begin
        if _data.Animations().ChangeAnimationFramesCount(defs.name, newlen) then begin
          result_description.SetDescription('length of '+defs.name+' successfully changed to '+inttostr(newlen));
          result:=true;
        end else begin
          result_description.SetDescription('error while changing length of '+defs.name);
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
      FreeAndNil(argsparser);
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

function TModelSlot._CmdAnimIkRefPose(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  idx:integer;
  argsparser:TCommandsArgumentsParser;
  defs:TOgfMotionDefData;
  frame:integer;
  pose:TOgfSkeletonPose;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    defs:=_data.Animations().GetAnimationParams(idx);
    if length(defs.name)=0 then exit;

    argsparser:=TCommandsArgumentsParser.Create();
    try
      argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'reference frame index');
      if argsparser.Parse(args) and
         argsparser.GetAsInt(0, frame)
      then begin
        pose:=TOgfSkeletonPose.Create();
        try
          if _iksolver=nil then begin
            result_description.SetDescription('IK solver currently is not set');
          end else if not CheckAndCorrectFrameId(frame, defs.name) then begin
            result_description.SetDescription('invalid frame index');
          end else if not _data.Skeleton().GetSkeletonPose(defs.name, frame, pose) then begin
            result_description.SetDescription('can''t get reference pose for IK solver');
          end else if _iksolver.SetReferencePose(pose) then begin
            result:=true;
          end else begin
            result_description.SetDescription('IK solver rejected reference pose');
          end;
        finally
          FreeAndNil(pose);
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

function TModelSlot._CmdIKSolverReset(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
begin
  result:=true;
  FreeAndNil(_iksolver);
end;

function TModelSlot._CmdIKSolverSimpleLimb(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  bonename:string;
  argsparser:TCommandsArgumentsParser;
  accuracy:single;
  initial_step, minimal_step:single;
  boneid:TBoneID;
  iksolver:TOgfSimpleGrandparentIKSolver;
  grandparent_flags_s:string;
  parent_flags_s:string;
  grandparent_flags:TOgfSimpleGrandparentIKSolverFlags;
  parent_flags:TOgfSimpleGrandparentIKSolverFlags;
begin
  result:=false;

  argsparser:=TCommandsArgumentsParser.Create();
  try
    argsparser.RegisterArgument(TCommandsArgumentsParserArgABNString, false, 'target bone');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgABNString, true, 'parent restriction flags (xyz)');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgABNString, true, 'grandparent restriction flags (xyz)');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, true, 'initial step');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, true, 'minimal step');
    argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, true, 'accuracy');


    if argsparser.Parse(args) and
       argsparser.GetAsString(0, bonename) and
       argsparser.GetAsString(1, parent_flags_s, '') and
       argsparser.GetAsString(2, grandparent_flags_s, '') and
       argsparser.GetAsSingle(3, initial_step, 0.1*pi/180) and
       argsparser.GetAsSingle(4, minimal_step, 0.000001) and
       argsparser.GetAsSingle(5, accuracy, 0.0001)
    then begin
      grandparent_flags:=TOgfSimpleGrandparentIKSolver.GetFlagsFromString(grandparent_flags_s);
      parent_flags:=TOgfSimpleGrandparentIKSolver.GetFlagsFromString(parent_flags_s);

      if not ExtractBoneIdFromString(bonename, boneid) or (boneid = INVALID_BONE_ID) then begin
        result_description.SetDescription('invalid target bone');
      end else begin
        iksolver:=TOgfSimpleGrandparentIKSolver.Create(_data.Skeleton(), boneid, parent_flags, grandparent_flags, initial_step, minimal_step, accuracy);
        if iksolver.IsProperlyConfigured() then begin
          FreeAndNil(_iksolver);
          _iksolver:=iksolver;
          result:=true;
        end else begin
          FreeAndNil(iksolver);
          result_description.SetDescription('invalid configuration passed');
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

function TModelSlot._CmdAddMotionRef(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
begin
  result:=false;
  if _data.IsAnimationsEmbedded() then begin
    result_description.SetDescription('OGF has embeded animations, please split them before operating with motion refs');
  end else begin
   args:=trim(args);
    if _data.AddMotionRef(args) >= 0 then begin
      result_description.SetDescription('Motion ref entry "'+args+'" successfully added');
      result:=true;
    end else begin
      result_description.SetDescription('Failed to add motion ref entry "'+args+'"');
    end;

  end;
end;

function TModelSlot._CmdResetMotionRefs(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
begin
  result:=false;
  if _data.IsAnimationsEmbedded() then begin
    result_description.SetDescription('OGF has embeded animations, please split them before operating with motion refs');
   end else begin
    _data.ResetMotionRefs();
    result_description.SetDescription('Motion refs reset');
    result:=true;
  end;
end;

function TModelSlot._CmdCalcMeshBounds(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
begin
  result:=_data.CalculateBounds();
  if not result then begin
    result_description.SetDescription('Bounds calculation failed');
  end;
end;

function TModelSlot._CmdCopyMeshBounds(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
   i:integer;
   serialized:string;
   bb:TOgfBBox;
   bs:TOgfBSphere;
begin
  bb:=_data.GetModelBBox();
  bs:=_data.GetModelBSphere();
  serialized:='';
  for i:=0 to sizeof(bb)-1 do begin
    serialized:=serialized+PAnsiChar(@bb)[i];
  end;
  for i:=0 to sizeof(bs)-1 do begin
    serialized:=serialized+PAnsiChar(@bs)[i];
  end;
  _container.GetTempBuffer().SetData(serialized, BUFFER_TYPE_MODELBLIMITS);
  result:=true;
end;

function TModelSlot._CmdPasteMeshBounds(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  serialized:string;
  bb:TOgfBBox;
  bs:TOgfBSphere;
begin
  result:=false;
  if _container.GetTempBuffer().GetData(serialized, BUFFER_TYPE_MODELBLIMITS) then begin
    if length(serialized) = sizeof(bb)+sizeof(bs) then begin
      bb:=pTOgfBBox(PAnsiChar(serialized))^;
      bs:=pTOgfBSphere(@PAnsiChar(serialized)[sizeof(bb)])^;
      _data.SetModelBBox(bb);
      _data.SetModelBSphere(bs);
      result:=true;
    end else begin
      result_description.SetDescription('invalid size of data from temp buffer');
    end;
  end else begin
    result_description.SetDescription('can''t get data from temp buffer');
  end;
end;

function TModelSlot._CmdAnimBoneMove(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  bone_idx, anim_idx:integer;
  upper_ud:TObject;
  argsparser:TCommandsArgumentsParser;
  startframe, endframe, i:integer;
  v:FVector3;
  is_absolute_coords:boolean;
  fixed_children:boolean;
  def:TOgfMotionDefData;
  cnt:integer;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    bone_idx:=(userdata as TCommandIndexArg).Get();
    upper_ud:=TObject((userdata as TCommandIndexArg).GetUserdata());
    if upper_ud = nil then exit;
    if (upper_ud <> nil) and (upper_ud is TCommandIndexArg) then begin
      anim_idx:=(upper_ud.Create as TCommandIndexArg).Get();
      def:=_data.Animations().GetAnimationParams(anim_idx);
      if length(def.name)=0 then exit;

      argsparser:=TCommandsArgumentsParser.Create();
      try
        argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'X coordinate');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Y coordinate');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Z coordinate');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, true, 'first frame index');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, true, 'last frame index');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgBool, true, 'absolute position flag');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgBool, true, 'fixed children flag');

        if argsparser.Parse(args) and
           argsparser.GetAsSingle(0, v.x) and
           argsparser.GetAsSingle(1, v.y) and
           argsparser.GetAsSingle(2, v.z) and
           argsparser.GetAsInt(3, startframe, -1) and
           argsparser.GetAsInt(4, endframe, startframe) and
           argsparser.GetAsBool(5, is_absolute_coords, false) and
           argsparser.GetAsBool(6, fixed_children, false)
        then begin

          if not CheckAndCorrectFrameId(startframe, def.name) then begin
            result_description.SetDescription('invalid first frame index');
          end else if not CheckAndCorrectFrameId(endframe, def.name) then begin
            result_description.SetDescription('invalid last frame index');
          end else if (_iksolver <> nil) and (not _iksolver.IsTransformAllowedForBone(bone_idx)) then begin
            result_description.SetDescription('current IK solver prohibits direct operations on bone #'+inttostr(bone_idx));
          end else begin
            if startframe>endframe then begin
              cnt:=startframe;
              startframe:=endframe;
              endframe:=cnt;
            end;

            cnt:=0;
            for i:=startframe to endframe do begin
              if _data.Skeleton().MoveBone(bone_idx, v, def.name, i, is_absolute_coords, fixed_children, _iksolver) then begin
                cnt:=cnt+1;
              end;
            end;

            if cnt = 0 then begin
              result:=startframe > endframe;
              if result then result_description.SetWarningFlag(true);
              result_description.SetDescription('no frames affected');
            end else if cnt <> endframe-startframe+1 then begin
              result_description.SetDescription('modified only '+inttostr(cnt)+' frames from '+inttostr(endframe - startframe + 1));
              result_description.SetWarningFlag(true);
              result:=true;
            end else begin
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
end;

function TModelSlot._CmdAnimBoneRotate(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  bone_idx, anim_idx:integer;
  upper_ud:TObject;
  argsparser:TCommandsArgumentsParser;
  startframe, endframe, i:integer;
  is_global:boolean;
  v:FVector3;
  def:TOgfMotionDefData;
  cnt:integer;
  mode:TOgfBoneRotationMode;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    bone_idx:=(userdata as TCommandIndexArg).Get();
    upper_ud:=TObject((userdata as TCommandIndexArg).GetUserdata());
    if upper_ud = nil then exit;
    if (upper_ud <> nil) and (upper_ud is TCommandIndexArg) then begin
      anim_idx:=(upper_ud.Create as TCommandIndexArg).Get();
      def:=_data.Animations().GetAnimationParams(anim_idx);
      if length(def.name)=0 then exit;

      argsparser:=TCommandsArgumentsParser.Create();
      try
        argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'X coordinate');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Y coordinate');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'Z coordinate');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, true, 'start frame index');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, true, 'end frame index');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgBool, true, 'use global space axis');

        if argsparser.Parse(args) and
           argsparser.GetAsSingle(0, v.x) and
           argsparser.GetAsSingle(1, v.y) and
           argsparser.GetAsSingle(2, v.z) and
           argsparser.GetAsInt(3, startframe, -1) and
           argsparser.GetAsInt(4, endframe, startframe) and
           argsparser.GetAsBool(5, is_global, false)
        then begin
          if is_global then begin
            mode:=BoneRotationGlobalAroundSelf;
          end else begin
            mode:=BoneRotationLocal;
          end;

          if not CheckAndCorrectFrameId(startframe, def.name) then begin
            result_description.SetDescription('invalid start frame index');
          end else if not CheckAndCorrectFrameId(endframe, def.name) then begin
            result_description.SetDescription('invalid end frame index');
          end else if (_iksolver <> nil) and (not _iksolver.IsTransformAllowedForBone(bone_idx)) then begin
            result_description.SetDescription('current IK solver prohibits direct operations on bone #'+inttostr(bone_idx));
          end else begin
            v:=v_mul(v, pi/180);

            cnt:=0;
            for i:=startframe to endframe do begin
              if _data.Skeleton().RotateBone(bone_idx, v, def.name, i, mode, _iksolver) then begin
                cnt:=cnt+1;
              end;
            end;

            if cnt = 0 then begin
              result:=startframe > endframe;
              if result then result_description.SetWarningFlag(true);
              result_description.SetDescription('no frames affected');
            end else if cnt <> endframe-startframe+1 then begin
              result_description.SetDescription('modified only '+inttostr(cnt)+' frames');
              result_description.SetWarningFlag(true);
              result:=true;
            end else begin
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
end;

function TModelSlot._CmdAnimBoneSetOrientation(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  bone_idx, anim_idx:integer;
  upper_ud:TObject;
  argsparser:TCommandsArgumentsParser;

  target:FVector3;
  startframe, endframe, i:integer;

  def:TOgfMotionDefData;
  cnt:integer;
  parent_bone_idx:TBoneID;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    bone_idx:=(userdata as TCommandIndexArg).Get();
    upper_ud:=TObject((userdata as TCommandIndexArg).GetUserdata());
    if upper_ud = nil then exit;
    if (upper_ud <> nil) and (upper_ud is TCommandIndexArg) then begin
      anim_idx:=(upper_ud.Create as TCommandIndexArg).Get();
      def:=_data.Animations().GetAnimationParams(anim_idx);
      if length(def.name)=0 then exit;

      argsparser:=TCommandsArgumentsParser.Create();
      try
        argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'target X coordinate');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'target Y coordinate');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'target Z coordinate');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'first frame index');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, true, 'last frame index');

        if argsparser.Parse(args) and
           argsparser.GetAsSingle(0, target.x) and
           argsparser.GetAsSingle(1, target.y) and
           argsparser.GetAsSingle(2, target.z) and
           argsparser.GetAsInt(3, startframe) and
           argsparser.GetAsInt(4, endframe, startframe)
        then begin
          parent_bone_idx:=_data.Skeleton().GetBoneParentIdx(bone_idx);
          target:=v_mul(target, pi/180);

          if not CheckAndCorrectFrameId(startframe, def.name) then begin
            result_description.SetDescription('invalid first frame index');
          end else if not CheckAndCorrectFrameId(endframe, def.name) then begin
            result_description.SetDescription('invalid last frame index');
          end else if parent_bone_idx = INVALID_BONE_ID then begin
            result_description.SetDescription('bone #'+inttostr(bone_idx) +' must have parent to perforn aim operation');
          end else if (_iksolver <> nil) and (not _iksolver.IsTransformAllowedForBone(parent_bone_idx)) then begin
            result_description.SetDescription('current IK solver prohibits direct operations on bone #'+inttostr(parent_bone_idx));
          end else begin
            if startframe > endframe then begin
              cnt:=startframe;
              startframe:=endframe;
              endframe:=cnt;
            end;

            cnt:=0;
            for i:=startframe to endframe do begin
              if _data.Skeleton().SetBoneOrientation(bone_idx, target, def.name, i, _iksolver) then begin
                cnt:=cnt+1;
              end;
            end;

            if cnt = 0 then begin
              result:=startframe > endframe;
              if result then result_description.SetWarningFlag(true);
              result_description.SetDescription('no frames affected');
            end else if cnt <> endframe-startframe+1 then begin
              result_description.SetDescription('modified only '+inttostr(cnt)+' frames');
              result_description.SetWarningFlag(true);
              result:=true;
            end else begin
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
end;

function TModelSlot._CmdAnimBoneSetPosition(var args: string;cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  bone_idx, anim_idx:integer;
  upper_ud:TObject;
  argsparser:TCommandsArgumentsParser;

  target:FVector3;
  startframe, endframe, i:integer;

  def:TOgfMotionDefData;
  cnt:integer;
  parent_bone_idx:TBoneID;
  is_global:boolean;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    bone_idx:=(userdata as TCommandIndexArg).Get();
    upper_ud:=TObject((userdata as TCommandIndexArg).GetUserdata());
    if upper_ud = nil then exit;
    if (upper_ud <> nil) and (upper_ud is TCommandIndexArg) then begin
      anim_idx:=(upper_ud.Create as TCommandIndexArg).Get();
      def:=_data.Animations().GetAnimationParams(anim_idx);
      if length(def.name)=0 then exit;

      argsparser:=TCommandsArgumentsParser.Create();
      try
        argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'target X coordinate');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'target Y coordinate');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'target Z coordinate');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'first frame index');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, true, 'last frame index');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgBool, true, 'is global');

        if argsparser.Parse(args) and
           argsparser.GetAsSingle(0, target.x) and
           argsparser.GetAsSingle(1, target.y) and
           argsparser.GetAsSingle(2, target.z) and
           argsparser.GetAsInt(3, startframe) and
           argsparser.GetAsInt(4, endframe, startframe) and
           argsparser.GetAsBool(5, is_global, false)
        then begin
          parent_bone_idx:=_data.Skeleton().GetBoneParentIdx(bone_idx);

          if not CheckAndCorrectFrameId(startframe, def.name) then begin
            result_description.SetDescription('invalid first frame index');
          end else if not CheckAndCorrectFrameId(endframe, def.name) then begin
            result_description.SetDescription('invalid last frame index');
          end else if parent_bone_idx = INVALID_BONE_ID then begin
            result_description.SetDescription('bone #'+inttostr(bone_idx) +' must have parent to perforn aim operation');
          end else if (_iksolver <> nil) and (not _iksolver.IsTransformAllowedForBone(parent_bone_idx)) then begin
            result_description.SetDescription('current IK solver prohibits direct operations on bone #'+inttostr(parent_bone_idx));
          end else begin
            if startframe > endframe then begin
              cnt:=startframe;
              startframe:=endframe;
              endframe:=cnt;
            end;

            cnt:=0;
            for i:=startframe to endframe do begin
              if _data.Skeleton().SetBonePosition(bone_idx, target, def.name, i, is_global, _iksolver) then begin
                cnt:=cnt+1;
              end;
            end;

            if cnt = 0 then begin
              result:=startframe > endframe;
              if result then result_description.SetWarningFlag(true);
              result_description.SetDescription('no frames affected');
            end else if cnt <> endframe-startframe+1 then begin
              result_description.SetDescription('modified only '+inttostr(cnt)+' frames');
              result_description.SetWarningFlag(true);
              result:=true;
            end else begin
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
end;

function TModelSlot._CmdAnimBoneAim(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  bone_idx, anim_idx:integer;
  upper_ud:TObject;
  argsparser:TCommandsArgumentsParser;

  target:FVector3;
  startframe, endframe, i:integer;

  def:TOgfMotionDefData;
  cnt:integer;
  parent_bone_idx:TBoneID;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    bone_idx:=(userdata as TCommandIndexArg).Get();
    upper_ud:=TObject((userdata as TCommandIndexArg).GetUserdata());
    if upper_ud = nil then exit;
    if (upper_ud <> nil) and (upper_ud is TCommandIndexArg) then begin
      anim_idx:=(upper_ud.Create as TCommandIndexArg).Get();
      def:=_data.Animations().GetAnimationParams(anim_idx);
      if length(def.name)=0 then exit;

      argsparser:=TCommandsArgumentsParser.Create();
      try
        argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'target X coordinate');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'target Y coordinate');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, false, 'target Z coordinate');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'first frame index');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, true, 'last frame index');

        if argsparser.Parse(args) and
           argsparser.GetAsSingle(0, target.x) and
           argsparser.GetAsSingle(1, target.y) and
           argsparser.GetAsSingle(2, target.z) and
           argsparser.GetAsInt(3, startframe) and
           argsparser.GetAsInt(4, endframe, startframe)
        then begin
          parent_bone_idx:=_data.Skeleton().GetBoneParentIdx(bone_idx);

          if not CheckAndCorrectFrameId(startframe, def.name) then begin
            result_description.SetDescription('invalid first frame index');
          end else if not CheckAndCorrectFrameId(endframe, def.name) then begin
            result_description.SetDescription('invalid last frame index');
          end else if parent_bone_idx = INVALID_BONE_ID then begin
            result_description.SetDescription('bone #'+inttostr(bone_idx) +' must have parent to perforn aim operation');
          end else if (_iksolver <> nil) and (not _iksolver.IsTransformAllowedForBone(parent_bone_idx)) then begin
            result_description.SetDescription('current IK solver prohibits direct operations on bone #'+inttostr(parent_bone_idx));
          end else begin
            if startframe > endframe then begin
              cnt:=startframe;
              startframe:=endframe;
              endframe:=cnt;
            end;

            cnt:=0;
            for i:=startframe to endframe do begin
              if _data.Skeleton().AimBone(bone_idx, target, def.name, i, _iksolver) then begin
                cnt:=cnt+1;
              end;
            end;

            if cnt = 0 then begin
              result:=startframe > endframe;
              if result then result_description.SetWarningFlag(true);
              result_description.SetDescription('no frames affected');
            end else if cnt <> endframe-startframe+1 then begin
              result_description.SetDescription('modified only '+inttostr(cnt)+' frames');
              result_description.SetWarningFlag(true);
              result:=true;
            end else begin
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
end;

function TModelSlot._CmdAnimBoneAimToBone(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  bone_idx, anim_idx:integer;
  upper_ud:TObject;
  argsparser:TCommandsArgumentsParser;

  target_bone:string;
  target_bone_id:TBoneID;
  target_bone_frame_id:integer;

  target:FVector3;
  startframe, endframe, i:integer;

  def:TOgfMotionDefData;
  cnt:integer;
  parent_bone_idx:TBoneID;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    bone_idx:=(userdata as TCommandIndexArg).Get();
    upper_ud:=TObject((userdata as TCommandIndexArg).GetUserdata());
    if upper_ud = nil then exit;
    if (upper_ud <> nil) and (upper_ud is TCommandIndexArg) then begin
      anim_idx:=(upper_ud.Create as TCommandIndexArg).Get();
      def:=_data.Animations().GetAnimationParams(anim_idx);
      if length(def.name)=0 then exit;

      argsparser:=TCommandsArgumentsParser.Create();
      try
        argsparser.RegisterArgument(TCommandsArgumentsParserArgABNStringWithWildcard, false, 'target bone');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'first frame index');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, true, 'last frame index');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, true, 'frame id with target bone position');

        if argsparser.Parse(args) and
           argsparser.GetAsString(0, target_bone) and
           argsparser.GetAsInt(1, startframe) and
           argsparser.GetAsInt(2, endframe, startframe) and
           argsparser.GetAsInt(3, target_bone_frame_id, -1)
        then begin
          parent_bone_idx:=_data.Skeleton().GetBoneParentIdx(bone_idx);
          target_bone:=ReplaceWildcards(target_bone, userdata as TCommandIndexArg);

          if not CheckAndCorrectFrameId(startframe, def.name) then begin
            result_description.SetDescription('invalid first frame index');
          end else if not CheckAndCorrectFrameId(endframe, def.name) then begin
             result_description.SetDescription('invalid last frame index');
          end else if not ExtractBoneIdFromString(target_bone, target_bone_id) or (target_bone_id = INVALID_BONE_ID) then begin
            result_description.SetDescription('invalid target bone');
          end else if parent_bone_idx = INVALID_BONE_ID then begin
            result_description.SetDescription('bone #'+inttostr(bone_idx) +' must have parent to perforn aim operation');
          end else if (_iksolver <> nil) and (not _iksolver.IsTransformAllowedForBone(parent_bone_idx)) then begin
            result_description.SetDescription('current IK solver prohibits direct operations on bone #'+inttostr(parent_bone_idx));
          end else begin
            cnt:=0;
            if target_bone_frame_id >= 0 then begin
              _data.Skeleton().GetGlobalBonePositionInPose(target_bone_id, def.name, target_bone_frame_id, target);
            end;

            for i:=startframe to endframe do begin
              if target_bone_frame_id < 0 then begin
                if not _data.Skeleton().GetGlobalBonePositionInPose(target_bone_id, def.name, i, target) then continue;
              end;

              if _data.Skeleton().AimBone(bone_idx, target, def.name, i, _iksolver) then begin
                cnt:=cnt+1;
              end;
            end;

            if cnt = 0 then begin
              result:=startframe > endframe;
              if result then result_description.SetWarningFlag(true);
              result_description.SetDescription('no frames affected');
            end else if cnt <> endframe-startframe+1 then begin
              result_description.SetDescription('modified only '+inttostr(cnt)+' frames');
              result_description.SetWarningFlag(true);
              result:=true;
            end else begin
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
end;

function TModelSlot._CmdAnimBoneFollow(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  bone_idx, anim_idx:integer;
  upper_ud:TObject;
  argsparser:TCommandsArgumentsParser;

  src_bone_idx:TBoneID;
  src_bone_name:string;
  srcframe, startframe, endframe, i:integer;

  def:TOgfMotionDefData;
  cnt:integer;
  step:integer;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    bone_idx:=(userdata as TCommandIndexArg).Get();
    upper_ud:=TObject((userdata as TCommandIndexArg).GetUserdata());
    if upper_ud = nil then exit;
    if (upper_ud <> nil) and (upper_ud is TCommandIndexArg) then begin
      anim_idx:=(upper_ud.Create as TCommandIndexArg).Get();
      def:=_data.Animations().GetAnimationParams(anim_idx);
      if length(def.name)=0 then exit;

      argsparser:=TCommandsArgumentsParser.Create();
      try
        argsparser.RegisterArgument(TCommandsArgumentsParserArgAnyString, false, 'source bone');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'source frame index');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'first target frame index');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, true, 'last target frame index');

        if argsparser.Parse(args) and
           argsparser.GetAsString(0, src_bone_name) and
           argsparser.GetAsInt(1, srcframe) and
           argsparser.GetAsInt(2, startframe) and
           argsparser.GetAsInt(3, endframe, startframe)
        then begin
          src_bone_name:=ReplaceWildcards(src_bone_name, userdata as TCommandIndexArg);
          if not ExtractBoneIdFromString(src_bone_name, src_bone_idx) then begin
            result_description.SetDescription('invalid source bone');
          end else if not CheckAndCorrectFrameId(srcframe, def.name) then begin
            result_description.SetDescription('invalid source frame id');
          end else if not CheckAndCorrectFrameId(startframe, def.name) then begin
            result_description.SetDescription('invalid first target frame index');
          end else if not CheckAndCorrectFrameId(endframe, def.name) then begin
            result_description.SetDescription('invalid last target frame index');
          end else if (_iksolver <> nil) and (not _iksolver.IsTransformAllowedForBone(bone_idx)) then begin
            result_description.SetDescription('current IK solver prohibits direct operations on bone #'+inttostr(bone_idx));
          end else begin

            if startframe > endframe then begin
              step:=-1;
            end else begin
              step:=1;
            end;

            cnt:=0;
            i:=startframe;
            while (true)  do begin
              if _data.Skeleton().FollowBone(bone_idx, def.name, src_bone_idx, srcframe, i, _iksolver) then begin
                cnt:=cnt+1;
              end;

              if i = endframe then break;
              i:=i+step;
            end;


            if cnt = 0 then begin
              result:=startframe <> endframe;
              if result then result_description.SetWarningFlag(true);
              result_description.SetDescription('no frames affected');
            end else if cnt <> abs(endframe-startframe)+1 then begin
              result_description.SetDescription('modified only '+inttostr(cnt)+' frames');
              result_description.SetWarningFlag(true);
              result:=true;
            end else begin
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
end;

function TModelSlot._CmdAnimBoneCopyKeyToKeys(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  bone_idx, anim_idx:integer;
  upper_ud:TObject;
  argsparser:TCommandsArgumentsParser;
  srcframe, startframe, endframe:integer;

  def:TOgfMotionDefData;
  key:TMotionKey;
  bonename:string;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    bone_idx:=(userdata as TCommandIndexArg).Get();
    upper_ud:=TObject((userdata as TCommandIndexArg).GetUserdata());
    if upper_ud = nil then exit;
    if (upper_ud <> nil) and (upper_ud is TCommandIndexArg) then begin
      anim_idx:=(upper_ud.Create as TCommandIndexArg).Get();
      def:=_data.Animations().GetAnimationParams(anim_idx);
      if length(def.name)=0 then exit;

      argsparser:=TCommandsArgumentsParser.Create();
      try
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'source frame index');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, true, 'start target frame index');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, true, 'end target frame index');

        if argsparser.Parse(args) and
           argsparser.GetAsInt(0, srcframe) and
           argsparser.GetAsInt(1, startframe, -1) and
           argsparser.GetAsInt(2, endframe, startframe)
        then begin
          bonename:=_data.Skeleton().GetBoneName(bone_idx);

          if not CheckAndCorrectFrameId(srcframe, def.name) then begin
            result_description.SetDescription('invalid source frame index');
          end else if not CheckAndCorrectFrameId(startframe, def.name) then begin
            result_description.SetDescription('invalid start target frame index');
          end else if not CheckAndCorrectFrameId(endframe, def.name) then begin
            result_description.SetDescription('invalid end target frame index');
          end else if not _data.Animations().GetAnimationKeyForBone(def.name, bonename, srcframe, key) then begin
            result_description.SetDescription('can''t get source key');
          end else if not _data.Animations().SetAnimationMultiframeKeyForBone(def.name, bonename, startframe, endframe, key) then begin
            result_description.SetDescription('key assigning failed');
          end else begin
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
end;

function TModelSlot._CmdAnimBoneSlerpKeys(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  bone_idx, anim_idx:integer;
  upper_ud:TObject;
  argsparser:TCommandsArgumentsParser;
  startframe, endframe:integer;
  calc_pos:boolean;
  calc_rot:boolean;
  factor:single;

  def:TOgfMotionDefData;
  key:TMotionKey;
  cnt:integer;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    bone_idx:=(userdata as TCommandIndexArg).Get();
    upper_ud:=TObject((userdata as TCommandIndexArg).GetUserdata());
    if upper_ud = nil then exit;
    if (upper_ud <> nil) and (upper_ud is TCommandIndexArg) then begin
      anim_idx:=(upper_ud.Create as TCommandIndexArg).Get();
      def:=_data.Animations().GetAnimationParams(anim_idx);
      if length(def.name)=0 then exit;

      argsparser:=TCommandsArgumentsParser.Create();
      try
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'start frame index');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'end frame index');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgBool, true, 'interpolate position');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgBool, true, 'interpolate rotation');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgSingle, true, 'power of time factor');

        if argsparser.Parse(args) and
           argsparser.GetAsInt(0, startframe) and
           argsparser.GetAsInt(1, endframe) and
           argsparser.GetAsBool(2, calc_pos, true) and
           argsparser.GetAsBool(3, calc_rot, true) and
           argsparser.GetAsSingle(4, factor, 1)
        then begin

          if not CheckAndCorrectFrameId(startframe, def.name) then begin
            result_description.SetDescription('invalid start frame index')
          end else if not CheckAndCorrectFrameId(endframe, def.name) then begin
            result_description.SetDescription('invalid end frame index')
          end else if factor <=0 then begin
            result_description.SetDescription('power of time factor must be greater than zero');
          end else begin
            cnt:=_data.Skeleton().InterpolateBone(bone_idx, def.name, startframe, endframe, calc_pos, calc_rot, factor, _iksolver);
            if cnt > 0 then begin
              result:=true;
              if cnt < abs(startframe-endframe)-2 then begin
                result_description.SetWarningFlag(true);
                result_description.SetDescription('interpolated only '+inttostr(cnt)+' frames of '+inttostr(abs(startframe-endframe)-2));
              end;
            end else begin
              result_description.SetDescription('key interpolation failed for bone '+_data.Skeleton().GetBoneName(bone_idx));
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
end;

function TModelSlot._CmdAnimBoneApplyDiff(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  bone_idx, anim_idx:integer;
  upper_ud:TObject;
  argsparser:TCommandsArgumentsParser;
  startframe, endframe, targetframe, sourceframe:integer;
  correct_pos, correct_rot:boolean;

  def:TOgfMotionDefData;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    bone_idx:=(userdata as TCommandIndexArg).Get();
    upper_ud:=TObject((userdata as TCommandIndexArg).GetUserdata());
    if upper_ud = nil then exit;
    if (upper_ud <> nil) and (upper_ud is TCommandIndexArg) then begin
      anim_idx:=(upper_ud.Create as TCommandIndexArg).Get();
      def:=_data.Animations().GetAnimationParams(anim_idx);
      if length(def.name)=0 then exit;

      argsparser:=TCommandsArgumentsParser.Create();
      try
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'target transform frame index');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'source transform frame index');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, false, 'start frame index to modify');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgInteger, true, 'end frame index to modify');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgBool, true, 'correct position');
        argsparser.RegisterArgument(TCommandsArgumentsParserArgBool, true, 'correct rotation');

        if argsparser.Parse(args) and
           argsparser.GetAsInt(0, targetframe) and
           argsparser.GetAsInt(1, sourceframe) and
           argsparser.GetAsInt(2, startframe) and
           argsparser.GetAsInt(3, endframe, startframe) and
           argsparser.GetAsBool(4, correct_pos, true) and
           argsparser.GetAsBool(5, correct_rot, true)
        then begin
          if not CheckAndCorrectFrameId(targetframe, def.name) then begin
            result_description.SetDescription('invalid target frame index');
          end else if not CheckAndCorrectFrameId(sourceframe, def.name) then begin
            result_description.SetDescription('invalid source frame index');
          end else if not CheckAndCorrectFrameId(startframe, def.name) then begin
             result_description.SetDescription('invalid start frame index');
          end else if not CheckAndCorrectFrameId(endframe, def.name) then begin
             result_description.SetDescription('invalid end frame index');
          end else begin
            if _data.Skeleton().ApplyDiff(bone_idx, def.name, targetframe, sourceframe, startframe, endframe, correct_pos, correct_rot, _iksolver) then begin
              result:=true;
            end else begin
              result_description.SetDescription('diff applying failed for bone '+_data.Skeleton().GetBoneName(bone_idx));
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
      cbdata.child_id:=idx;
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
    args:=ReplaceWildcards(args, userdata as TCommandIndexArg);
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
    args:=ReplaceWildcards(args, userdata as TCommandIndexArg);
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
    _selectionarea.ResetSelection();
    _selectionarea.InverseSelection();
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
    _selectionarea.ResetSelection();
    _selectionarea.InverseSelection();
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
    _selectionarea.ResetSelection();
    _selectionarea.InverseSelection();
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
    child_id:integer;
  end;
  pTVertexSelectionCallbackData = ^TVertexSelectionCallbackData;

function VertexSelectionCallback(vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; userdata:pointer):boolean;
var
  cbdata:pTVertexSelectionCallbackData;
begin
  result:=false;
  if (userdata = nil) or (data = nil) then exit;
  cbdata:=pTVertexSelectionCallbackData(userdata);
  result:=cbdata^.selection_area.IsVertexInSelection(cbdata^.child_id, vertex_id, data^.pos);
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
         cbdata.child_id:=idx;
         if not _data.Meshes().Get(idx).Move(v, @VertexSelectionCallback, @cbdata) then begin
           result_description.SetDescription('move operation failed for child #'+inttostr(idx)+' ('+texture+' : '+shader+')');
         end else if cbdata.vcnt = 0 then begin
           result_description.SetDescription('no vertices were found in the selection');
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
         cbdata.child_id:=idx;
         shader:=_data.Meshes().Get(idx).GetTextureData().shader;
         texture:=_data.Meshes().Get(idx).GetTextureData().texture;

         if not _data.Meshes().Get(idx).RotateUsingStandartAxis(amount, axis, _selectionarea.GetPivot(), @VertexSelectionCallback, @cbdata) then begin
           result_description.SetDescription('rotate operation failed for child #'+inttostr(idx)+' ('+texture+' : '+shader+')');
         end else if cbdata.vcnt = 0 then begin
           result_description.SetDescription('no vertices were found in the selection area for child #'+inttostr(idx)+' ('+texture+' : '+shader+')');
           result_description.SetWarningFlag(true);
           result:=true;
         end else begin
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
        cbdata.child_id:=idx;
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
    src_boneids:TParsedBonesExpression;
    vcnt:integer;
    child_id:integer;
  end;
  pTVertexSelectiveBindCallbackData = ^TVertexSelectiveBindCallbackData;

function VertexSelectiveBindCallback(vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; target_boneid:cardinal; userdata:pointer):boolean;
var
  cbdata:pTVertexSelectiveBindCallbackData;
  i:integer;
  bone, bone2:TVertexBone;
  value:single;
  target_idx:integer;
begin
  result:=false;
  if (userdata = nil) or (data = nil) then exit;
  cbdata:=pTVertexSelectiveBindCallbackData(userdata);
  if cbdata^.selection_area.IsVertexInSelection(cbdata^.child_id, vertex_id, data^.pos) then begin
    if (cbdata^.src_boneids.ParsedCount() = 0) then begin
      // no need to replace any specific bones - just adjust weight of target_boneid or add it by replace binding with the lowest weight
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
        bone:=links.GetBoneParams(i);
        if bone.bone_id = target_boneid then begin
          bone.weight:=0;
          links.SetBoneParams(target_idx, bone, false);
        end;
      end;

      links.NormalizeWeights(target_idx);
      result:=true;
    end else begin
      // both source expression and target_boneid are present
      // for every vertex with links that matched expression we need to replace every boneid which match the expression
      // if weight >= 0 - set a full new weigth at the moment of the 1st replacing, the next replaces will make corresponding weights zero
      // if weight == 0 - need to accumulate the full weigth in the single links entry
      if cbdata^.src_boneids.IsLinksMatch(links) then begin
        result:=true;
        value:=cbdata^.weight;
        target_idx:=-1;
        for i:=0 to links.TotalLinkedBonesCount()-1 do begin
          bone:=links.GetBoneParams(i);
          if cbdata^.src_boneids.IsBoneIdMatches(bone.bone_id) then begin
            bone.bone_id:=target_boneid;
            if cbdata^.weight >= 0 then begin
              // weight is explicitely specified in the command, so the 1st occurence will get the full weight, the next occurences will get zero weight
              bone.weight:=value;
              value:=0;
            end else if (target_idx >=0) and (bone.weight>0) then begin
              // weight is omitted in the command, so we need to accumulate all weights inside the single link entry
              bone2:=links.GetBoneParams(target_idx);
              bone2.weight:=bone2.weight+bone.weight;
              links.SetBoneParams(target_idx, bone2, false);
              bone.weight:=0;
            end;
            links.SetBoneParams(i, bone, false);


            if target_idx < 0 then begin
              // Remember found 1st index
              target_idx:=i;
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
  end;

  if result then begin
    cbdata^.vcnt:=cbdata^.vcnt+1;
  end;
end;

function TModelSlot._CmdChildRebindSelected(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  dest_boneid:TBoneID;
  src_boneids:TParsedBonesExpression;

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
    dest_boneid:=INVALID_BONE_ID;
    weight:=-1;

    argsparser:=TCommandsArgumentsParser.Create();
    src_boneids:=TParsedBonesExpression.Create();
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
        end else if (length(src_bone_s) > 0) and (not ExtractMultipleBoneIdsFromString(src_bone_s, src_boneids)) then begin
          result_description.SetDescription('incorrect source expression specified');
        end else begin
          shader:=_data.Meshes().Get(idx).GetTextureData().shader;
          texture:=_data.Meshes().Get(idx).GetTextureData().texture;
          cbdata.selection_area:=_selectionarea;
          cbdata.src_boneids:=src_boneids;
          cbdata.weight:=weight;
          cbdata.vcnt:=0;
          cbdata.child_id:=idx;
          if not _data.Meshes().Get(idx).BindVerticesToBone(dest_boneid, @VertexSelectiveBindCallback, @cbdata) then begin
            result_description.SetDescription('failed to rebind vertices of child #'+inttostr(idx)+' ('+texture+' : '+shader+') to '+GetBoneNameById(dest_boneid));
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
      FreeAndNil(src_boneids);
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
    _selectionarea.ResetSelection();
    _selectionarea.InverseSelection();
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
    parsed_bones:TParsedBonesExpression;
    flagged_vertices_count:integer;
  end;
  pTChildVertexFilterCallbackData = ^TChildVertexFilterCallbackData;

function ChildRemoveVerticesForBoneIdCallback(vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; userdata:pointer):boolean;
var
  cbdata:pTChildVertexFilterCallbackData;
begin
  cbdata:=pTChildVertexFilterCallbackData(userdata);
  result:=cbdata^.parsed_bones.IsLinksMatch(links);

  if result then begin
    cbdata^.flagged_vertices_count:=cbdata^.flagged_vertices_count+1;
  end;
end;

function TModelSlot._CmdChildFilterBone(var args: string; cmd: TCommandSetup; result_description: TCommandResult; userdata: TObject): boolean;
var
  cbdata:TChildVertexFilterCallbackData;
  parsed_bones:TParsedBonesExpression;
  shader, texture:string;
  idx:integer;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    parsed_bones:=TParsedBonesExpression.Create();

    try
      if ExtractMultipleBoneIdsFromString(args, parsed_bones) then begin
        shader:=_data.Meshes().Get(idx).GetTextureData().shader;
        texture:=_data.Meshes().Get(idx).GetTextureData().texture;
        if length(trimleft(args))>0 then begin
          result_description.SetDescription('procedure expects 1 argument (bone or expression)');
        end else begin
          cbdata.flagged_vertices_count:=0;
          cbdata.parsed_bones:=parsed_bones;
          if _data.Meshes().Get(idx).GetVerticesCount() = 0 then begin
            result_description.SetDescription('child #'+inttostr(idx)+' ('+texture+' : '+shader+') is collapsed - skipping');
            result_description.SetWarningFlag(true);
            result:=true;
          end else if not _data.Meshes().Get(idx).RemoveVertices(@ChildRemoveVerticesForBoneIdCallback, @cbdata) then begin
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
        result_description.SetDescription('can''t parse bones');
      end;
    finally
      FreeAndNil(parsed_bones);
    end

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
  idx:integer;
  r:string;
  cbdata:TVertexSelectionCallbackData;
begin
  result:=false;
  if userdata is TCommandIndexArg then begin
    idx:=(userdata as TCommandIndexArg).Get();

    cbdata.selection_area:=_selectionarea;
    cbdata.vcnt:=0;
    cbdata.child_id:=idx;
    result:=_data.Meshes().Get(idx).RemoveVertices(@VertexSelectionCallback, @cbdata);
    _selectionarea.RemoveAllChildVerticesFromSelectionList(idx);

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
    cbdata_cnt.child_id:=idx;
    _data.Meshes().Get(idx).IterateVertices(@VertexCounterCallback, @cbdata_cnt);

    if cbdata_cnt.vcnt=0 then begin
      result_description.SetDescription('selection area is empty');
    end else if cbdata_cnt.vcnt = _data.Meshes().Get(idx).GetVerticesCount() then begin
      result_description.SetDescription('the whole child mesh is selected');
    end else begin
      r:=_data.Meshes().Get(idx).Serialize();
      newidx:=_data.Meshes().Insert(r, idx+1);
      if newidx<0 then begin
        result_description.SetDescription('error while copying source child');
      end else begin
        _selectionarea.InverseSelection();
        try
          cbdata_sel.selection_area:=_selectionarea;
          cbdata_sel.vcnt:=0;
          cbdata_sel.child_id:=idx; // vertex indices in new mesh are same as in the original, so just use the original child id

          result:=_data.Meshes().Get(newidx).RemoveVertices(@VertexSelectionCallback, @cbdata_sel);
          _selectionarea.AddAllChildVerticesToSelectionList(newidx, _data.Meshes().Get(newidx).GetVerticesCount());
        finally
          _selectionarea.InverseSelection();
        end;

        if not result then begin
          _data.Meshes().Remove(newidx);
          result_description.SetDescription('can''t filter selected vertices in new child, aborting');
        end else begin
          cbdata_sel.selection_area:=_selectionarea;
          cbdata_sel.vcnt:=0;
          cbdata_sel.child_id:=idx;

          result:=_data.Meshes().Get(idx).RemoveVertices(@VertexSelectionCallback, @cbdata_sel);
          _selectionarea.RemoveAllChildVerticesFromSelectionList(idx);
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
  _iksolver:=nil;

  _commands_selection:=TCommandsStorage.Create(true);
  _commands_selection.DoRegister(TCommandSetup.Create('pivotpoint', nil, @_CmdSetPivot, 'set pivot point for rotation / scaling commands'), CommandItemTypeCall);
  _commands_selection.DoRegister(TCommandSetup.Create('sphere', nil, @_CmdSelectionSphere, 'set spherical selection, expects 4 numbers (center point x,y,z and sphere radius)'), CommandItemTypeCall);
  _commands_selection.DoRegister(TCommandSetup.Create('box', nil, @_CmdSelectionBox, 'set box selection, expects 6 numbers (box left-down and right-up points)'), CommandItemTypeCall);
  _commands_selection.DoRegister(TCommandSetup.Create('reset', nil, @_CmdSelectionClear, 'reset selection'), CommandItemTypeCall);
  _commands_selection.DoRegister(TCommandSetup.Create('inverse', nil, @_CmdSelectionInverse, 'inverse selection'), CommandItemTypeCall);
  _commands_selection.DoRegister(TCommandSetup.Create('testpoint', nil, @_CmdSelectionTestPoint, 'check if point from arguments is in selected area'), CommandItemTypeCall);
  _commands_selection.DoRegister(TCommandSetup.Create('pickverts', nil, @_CmdSelectionSelectPickVertices, 'pick vertices and append to selection; arg 1 - type ("box" or "sphere"), the next args are area selection parameters; if no args used - uses previously selected area; changes selection type from area to list of vertices'), CommandItemTypeCall);
  _commands_selection.DoRegister(TCommandSetup.Create('meshelement', nil, @_CmdSelectionSelectPickElement, 'expand the selection to minimal independent element which match the selected vertices'), CommandItemTypeCall);
  _commands_selection.DoRegister(TCommandSetup.Create('info', nil, @_CmdSelectionInfo, 'show current selection info'), CommandItemTypeCall);

  _commands_upperlevel:=TCommandsStorage.Create(true);
    _commands_mesh:=TCommandsStorage.Create(true);
      _commands_children:=TChildrenCommands.Create(self);
    _commands_skeleton:=TCommandsStorage.Create(true);
      _commands_bones:=TBonesCommands.Create(self);
      _commands_iksolver:=TCommandsStorage.Create(true);
      _commands_animations:=TAnimationsCommands.Create(self);
        _commands_mmarks:=TCommandsStorage.Create(true);
        _commands_animbones:=TBonesCommands.Create(self);


  _commands_upperlevel.DoRegisterPropertyWithSubcommand(TPropertyWithSubcommandsSetup.Create('selection', nil, _commands_selection, 'control pivot point and selection area'));
  _commands_upperlevel.DoRegisterPropertyWithSubcommand(TPropertyWithSubcommandsSetup.Create('mesh', @_IsModelLoadedPrecondition, _commands_mesh, 'access group of properties and procedures associated with model''s mesh'));
  _commands_upperlevel.DoRegisterPropertyWithSubcommand(TPropertyWithSubcommandsSetup.Create('skeleton', @_IsModelLoadedPrecondition, _commands_skeleton, 'access group of properties and procedures associated with model''s mesh'));

  _commands_upperlevel.DoRegister(TCommandSetup.Create('loadfromfile', @_IsModelNotLoadedPrecondition, @_CmdLoadFromFile, 'load OGF data to selected model slot, expects file path'), CommandItemTypeCall);
  _commands_upperlevel.DoRegister(TCommandSetup.Create('savetofile', @_IsModelLoadedPrecondition, @_CmdSaveToFile, 'save data from selected model slot to OGF, expects file path'), CommandItemTypeCall);
  _commands_upperlevel.DoRegister(TCommandSetup.Create('unload', @_IsModelLoadedPrecondition, @_CmdUnload, 'clear selected model slot'), CommandItemTypeCall);
  _commands_upperlevel.DoRegister(TCommandSetup.Create('info', @_IsModelLoadedPrecondition, @_CmdInfo, 'display selected slot info'), CommandItemTypeCall);
  _commands_upperlevel.DoRegister(TCommandSetup.Create('setclipboardmode', nil, @_CmdClipboardMode, 'switches temp buffer between internal storage and system clipboard (globally for all slots)'), CommandItemTypeCall);

  _commands_mesh.DoRegister(TCommandSetup.Create('info', @_IsModelLoadedPrecondition, @_CmdMeshInfo, 'show info'), CommandItemTypeCall);
  _commands_mesh.DoRegisterPropertyWithSubcommand(TPropertyWithSubcommandsSetup.Create('child', @_IsModelLoadedPrecondition, _commands_children, 'array of sub-meshes with different textures'));
  _commands_mesh.DoRegister(TCommandSetup.Create('pastechild', @_IsModelLoadedPrecondition, @_CmdPasteMeshFromTempBuf, 'paste child previously copied into temp buffer'), CommandItemTypeCall);
  _commands_mesh.DoRegister(TCommandSetup.Create('removecollapsedchildren', @_IsModelLoadedPrecondition, @_CmdRemoveCollapsedMeshes, 'remove all children without real mesh (without vertices)'), CommandItemTypeCall);
  _commands_mesh.DoRegister(TCommandSetup.Create('calcbounds', @_IsModelLoadedPrecondition, @_CmdCalcMeshBounds, 'calculate mesh bounding box and sphere'), CommandItemTypeCall);
  _commands_mesh.DoRegister(TCommandSetup.Create('copybounds', @_IsModelLoadedPrecondition, @_CmdCopyMeshBounds, 'copy mesh bounding box and sphere parameters'), CommandItemTypeCall);
  _commands_mesh.DoRegister(TCommandSetup.Create('pastebounds', @_IsModelLoadedPrecondition, @_CmdPasteMeshBounds, 'paste mesh bounding box and sphere parameters'), CommandItemTypeCall);


  _commands_children.DoRegister(TCommandSetup.Create('info', @_IsModelLoadedPrecondition, @_CmdChildInfo, 'show info'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('settexture', @_IsModelLoadedPrecondition, @_CmdChildSetTexture, 'change assigned shader, expects string argument'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('setshader', @_IsModelLoadedPrecondition, @_CmdChildSetShader, 'change assigned shader, expects string argument'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('copy', @_IsModelLoadedPrecondition, @_CmdChildCopy, 'copy child into temp buffer'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('paste', @_IsModelLoadedPrecondition, @_CmdChildPasteData, 'insert new child with data from the temp buffer, expects index for new child'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('move', @_IsModelLoadedPrecondition, @_CmdChildMoveAll, 'move selected part of the child, expects 3 numbers (offsets for x,y,z axis)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('rotate', @_IsModelLoadedPrecondition, @_CmdChildRotateAll, 'rotate the entire child, expects a numbers (angle in degrees) and axis letter (x, y or z)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('scale', @_IsModelLoadedPrecondition, @_CmdChildScaleAll, 'scale the entire child using previously selected pivot point, expects 3 numbers (scaling factor for x,y z axis, negative means mirroring)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('rebind', @_IsModelLoadedPrecondition, @_CmdChildRebindAll, 'link child vertices; arg 1 - new bone, arg 2 (optional, omittable) - weight, arg3 - old bone to unbind (optional)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('remove', @_IsModelLoadedPrecondition, @_CmdChildRemove, 'remove the selected child'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('moveselected', @_IsModelLoadedPrecondition, @_CmdChildMoveSelected, 'move the entire child, expects 3 numbers (offsets for x,y,z axis)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('scaleselected', @_IsModelLoadedPrecondition, @_CmdChildScaleSelected, 'scale selected part of the child using previously selected pivot point, expects 3 numbers (scaling factor for x,y z axis, negative means mirroring)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('rotateselected', @_IsModelLoadedPrecondition, @_CmdChildRotateSelected, 'rotate selected part of the child, expects a numbers (angle in degrees) and axis letter (x, y or z)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('rebindselected', @_IsModelLoadedPrecondition, @_CmdChildRebindSelected, 'link child vertices in the selection; arg 1 - new bone, arg 2  (optional, omittable) - weight, arg3 - old bone to inbind (optional)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('removeselected', @_IsModelLoadedPrecondition, @_CmdChildRemoveSelected, 'remove selected part of child'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('splitselected', @_IsModelLoadedPrecondition, @_CmdChildSplitSelected, 'extract selected part of child into a new child'), CommandItemTypeCall);
  // add 'selectvertsbybone' command to select vertices linked with the bone
  // add variables, calls, gotos

  _commands_children.DoRegister(TCommandSetup.Create('bonestats', @_IsModelLoadedPrecondition, @_CmdChildBonestats, 'display bones linked with the selected mesh'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('filterbone', @_IsModelLoadedPrecondition, @_CmdChildFilterBone, 'remove all vertices that has no link with the specified bone(s)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('savetofile', @_IsModelLoadedPrecondition, @_cmdChildSaveToFile, 'save selected child to file (expects file name)'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('selectlodlevel', @_IsModelLoadedPrecondition, @_cmdChildLodLevelSelect, 'select lod level, expects number'), CommandItemTypeCall);
  _commands_children.DoRegister(TCommandSetup.Create('removelodlevels', @_IsModelLoadedPrecondition, @_cmdChildLodLevelsRemove, 'remove all LOD levels except selected'), CommandItemTypeCall);

  _commands_skeleton.DoRegisterPropertyWithSubcommand(TPropertyWithSubcommandsSetup.Create('bone', @_IsModelHasSkeletonPrecondition, _commands_bones, 'access array of bones'));
  _commands_skeleton.DoRegister(TCommandSetup.Create('uniformscale', @_IsModelHasSkeletonPrecondition, @_CmdSkeletonUniformScale, 'scale skeleton (pivot point currently is always zero), expects a number (scaling factor)'), CommandItemTypeCall);
  _commands_skeleton.DoRegister(TCommandSetup.Create('loadomf', @_IsModelHasSkeletonPrecondition, @_CmdLoadAnimsFromFile, 'load animations from the specified file'), CommandItemTypeCall);
  _commands_skeleton.DoRegister(TCommandSetup.Create('saveomf', @_IsModelHasSkeletonPrecondition, @_CmdSaveAnimsToFile, 'save animations to the specified file'), CommandItemTypeCall);
  _commands_skeleton.DoRegister(TCommandSetup.Create('mergeomf', @_IsModelHasSkeletonPrecondition, @_CmdMergeAnimsWithFile, 'loads additional animations from the specified file'), CommandItemTypeCall);
  _commands_skeleton.DoRegister(TCommandSetup.Create('hierarchy', @_IsModelHasSkeletonPrecondition, @_CmdSkeletonHierarchy, 'display bones hierarchy'), CommandItemTypeCall);
  _commands_skeleton.DoRegister(TCommandSetup.Create('addbone', @_IsModelHasSkeletonPrecondition, @_CmdSkeletonAddBone, 'add a new bone, arguments - new bone name, parent bone, optional X, Y, Z, H, P, B, is in global space flag'), CommandItemTypeCall);
  _commands_skeleton.DoRegister(TCommandSetup.Create('addmotionref', @_IsModelLoadedPrecondition, @_CmdAddMotionRef, 'add motion ref to the file from argument, requires animations to be stored in the separate OMF'), CommandItemTypeCall);
  _commands_skeleton.DoRegister(TCommandSetup.Create('resetmotionrefs', @_IsModelLoadedPrecondition, @_CmdResetMotionRefs, 'reset all motion refs, requires animations to be stored in the separate OMF'), CommandItemTypeCall);

  _commands_bones.DoRegister(TCommandSetup.Create('info', @_IsModelHasSkeletonPrecondition, @_CmdBoneInfo, 'display info associated with the selected bone'), CommandItemTypeCall);
  _commands_bones.DoRegister(TCommandSetup.Create('rename', @_IsModelHasSkeletonPrecondition, @_CmdBoneRename, 'rename bone, expects 1 argument - new bone name'), CommandItemTypeCall);
  _commands_bones.DoRegister(TCommandSetup.Create('reparent', @_IsModelHasSkeletonPrecondition, @_CmdBoneReparent, 'change bone parent; arg 1 - new parent, arg 2 (optional) - preserve bone global position (1, default) or not (0)'), CommandItemTypeCall);
  _commands_bones.DoRegister(TCommandSetup.Create('setbindtransform', @_IsModelHasSkeletonPrecondition, @_CmdBoneSetBindTransform, 'directly change bone transform of bind pose (dangerous function, can break anims); args #1, #2, #3 - new offset X,Y,Z; args #4, #5, #6 - new rotation X,Y,Z'), CommandItemTypeCall);
  _commands_bones.DoRegister(TCommandSetup.Create('move', @_IsModelHasSkeletonPrecondition, @_CmdBoneBindPoseMove, 'move bone changing its bind position; args 1,2,3 - x,y,z components of move, arg 4 (optional) - absolute (1) or relative (0, default) movement, arg 5 (optional) - fixed children (1) or not (0, default)'), CommandItemTypeCall);
  _commands_bones.DoRegister(TCommandSetup.Create('rotate', @_IsModelHasSkeletonPrecondition, @_CmdBoneBindPoseRotateAroundSelf, 'rotate bone changing its bind pose; args 1,2,3 - x,y,z components, 4 - is global (1) or local (0, default) axis used'), CommandItemTypeCall);
  _commands_bones.DoRegister(TCommandSetup.Create('copysettings', @_IsModelHasSkeletonPrecondition, @_CmdBoneCopySettings, 'copy bone settings into temp buffer, no arguments'), CommandItemTypeCall);
  _commands_bones.DoRegister(TCommandSetup.Create('applysettings', @_IsModelHasSkeletonPrecondition, @_CmdBoneApplySettings, 'apply previously copied bone settings, no arguments'), CommandItemTypeCall);
  _commands_bones.DoRegister(TCommandSetup.Create('generateshape', @_IsModelHasSkeletonPrecondition, @_CmdBoneGenerateShape, 'generate shape for bone, argument is shape type ("box" (default), "none")'), CommandItemTypeCall);
  _commands_bones.DoRegister(TCommandSetup.Create('setmaterial', @_IsModelHasSkeletonPrecondition, @_CmdBoneSetMaterial, 'set bone material, argument is material name'), CommandItemTypeCall);

  _commands_skeleton.DoRegisterPropertyWithSubcommand(TPropertyWithSubcommandsSetup.Create('animation', @_IsAnimationsLoadedPrecondition, _commands_animations, 'access group of properties and procedures associated with loaded animations'));
  _commands_animations.DoRegister(TCommandSetup.Create('info', @_IsAnimationsLoadedPrecondition, @_CmdAnimInfo, 'display animations info'), CommandItemTypeCall);
  _commands_animations.DoRegister(TCommandSetup.Create('keyinfo', @_IsAnimationsLoadedPrecondition, @_CmdAnimKeyInfo, 'show bone parameters is specific key; arg 1 - key index, arg 2 (optional) - bones'), CommandItemTypeCall);
  _commands_animations.DoRegister(TCommandSetup.Create('copykey', @_IsAnimationsLoadedPrecondition, @_CmdAnimKeyPoseCopy, 'copy pose in the specified frame, argument 1 is frame id, argument 2 (optional) is bones'), CommandItemTypeCall);
  _commands_animations.DoRegister(TCommandSetup.Create('copybindposekey', @_IsAnimationsLoadedPrecondition, @_CmdAnimBindPoseCopy, 'copy bind pose, argument (optional) is bones'), CommandItemTypeCall);
  _commands_animations.DoRegister(TCommandSetup.Create('pastekey', @_IsAnimationsLoadedPrecondition, @_CmdAnimKeyPosePaste, 'paste previosly copied skeleton pose into the specified frames, arg 1 is first frame id, arg2 (optional) is last frame id'), CommandItemTypeCall);
  _commands_animations.DoRegister(TCommandSetup.Create('copytrack', @_IsAnimationsLoadedPrecondition, @_CmdAnimTrackCopy, 'copy track, arg 1 - start frame id, arg 2 - last frame id to copy, arg3 - bones (optional)'), CommandItemTypeCall);
  _commands_animations.DoRegister(TCommandSetup.Create('pastetrack', @_IsAnimationsLoadedPrecondition, @_CmdAnimTrackPaste, 'paste previously copied track, arg 1 - start frame index to paste, arg 2 - overwrite (0) or insert new (1, default) frames'), CommandItemTypeCall);
  _commands_animations.DoRegister(TCommandSetup.Create('duplicate', @_IsAnimationsLoadedPrecondition, @_CmdAnimTrackDuplicate, 'duplicate motion, argument is name for the copy'), CommandItemTypeCall);
  _commands_animations.DoRegister(TCommandSetup.Create('rename', @_IsAnimationsLoadedPrecondition, @_CmdAnimRename, 'rename animation, argument is new name'), CommandItemTypeCall);
  _commands_animations.DoRegister(TCommandSetup.Create('remove', @_IsAnimationsLoadedPrecondition, @_CmdAnimRemove, 'remove animation, no arguments'), CommandItemTypeCall);
  _commands_animations.DoRegister(TCommandSetup.Create('setikrefpose', @_IsAnimationsLoadedPrecondition, @_CmdAnimIkRefPose, 'set frame as IK solver reference pose, argument is frame index'), CommandItemTypeCall);
  _commands_animations.DoRegister(TCommandSetup.Create('setlength', @_IsAnimationsLoadedPrecondition, @_CmdAnimTrackSetLength, 'set new frames count for animation, argument is new frames count'), CommandItemTypeCall);
  _commands_animations.DoRegister(TCommandSetup.Create('setaccrue', @_IsAnimationsLoadedPrecondition, @_CmdAnimSetAccrue, 'set animation accrue parameter value, argument is a number'), CommandItemTypeCall);
  _commands_animations.DoRegister(TCommandSetup.Create('setfalloff', @_IsAnimationsLoadedPrecondition, @_CmdAnimSetFalloff, 'set animation falloff parameter value, argument is a number'), CommandItemTypeCall);
  _commands_animations.DoRegister(TCommandSetup.Create('setpower', @_IsAnimationsLoadedPrecondition, @_CmdAnimSetPower, 'set animation power parameter value, argument is a number'), CommandItemTypeCall);
  _commands_animations.DoRegister(TCommandSetup.Create('setspeed', @_IsAnimationsLoadedPrecondition, @_CmdAnimSetSpeed, 'set animation speed parameter value, argument is a number'), CommandItemTypeCall);
  _commands_animations.DoRegister(TCommandSetup.Create('setflags', @_IsAnimationsLoadedPrecondition, @_CmdAnimSetFlags, 'set animation flags, argument is a number'), CommandItemTypeCall);

  _commands_animations.DoRegisterPropertyWithSubcommand(TPropertyWithSubcommandsSetup.Create('marks', @_IsAnimationsLoadedPrecondition, _commands_mmarks, 'access group of properties and procedures associated with motion marks'));
  _commands_mmarks.DoRegister(TCommandSetup.Create('add', @_IsAnimationsLoadedPrecondition, @_CmdAnimAddMotionMark, 'add new interval, expects 3 arguments (mark name, interval start, interval end)'), CommandItemTypeCall);
  _commands_mmarks.DoRegister(TCommandSetup.Create('reset', @_IsAnimationsLoadedPrecondition, @_CmdAnimResetMotionMarks, 'reset marks for selected animation'), CommandItemTypeCall);

  _commands_skeleton.DoRegisterPropertyWithSubcommand(TPropertyWithSubcommandsSetup.Create('iksolver', @_IsAnimationsLoadedPrecondition, _commands_iksolver, 'access group of properties and procedures associated with inverse kinematics solver'));
  _commands_iksolver.DoRegister(TCommandSetup.Create('reset', @_IsAnimationsLoadedPrecondition, @_CmdIKSolverReset, 'reset current settings of inverse kinematics solver'), CommandItemTypeCall);
  _commands_iksolver.DoRegister(TCommandSetup.Create('simplelimb', @_IsAnimationsLoadedPrecondition, @_CmdIKSolverSimpleLimb, 'activate simple 2-bones limb IK solver, arguments - target (child) bone, parent restriction flags (xyz or empty string), grandparent restriction flags, initial step, minimal step, accuracy'), CommandItemTypeCall);

  _commands_animations.DoRegisterPropertyWithSubcommand(TPropertyWithSubcommandsSetup.Create('bone', @_IsAnimationsLoadedPrecondition, _commands_animbones, 'access array of bones keys'));
  _commands_animbones.DoRegister(TCommandSetup.Create('move', @_IsModelHasSkeletonPrecondition, @_CmdAnimBoneMove, 'move bone to change its key position, arguments: X, Y, Z coordinates, start frame index, end frame index, absolute coordinates flag; fixed children flag'), CommandItemTypeCall);
  _commands_animbones.DoRegister(TCommandSetup.Create('rotate', @_IsModelHasSkeletonPrecondition, @_CmdAnimBoneRotate, 'rotate bone, arguments: X, Y, Z rotation components, start frame index, end frame index, is global (1) or local (0, default) axis used'), CommandItemTypeCall);
  _commands_animbones.DoRegister(TCommandSetup.Create('setposition', @_IsModelHasSkeletonPrecondition, @_CmdAnimBoneSetPosition, 'set bone position, arguments: X, Y, Z rotation components, start frame index, end frame index, is global (1) or local (0) coordinates'), CommandItemTypeCall);
  _commands_animbones.DoRegister(TCommandSetup.Create('setorientation', @_IsModelHasSkeletonPrecondition, @_CmdAnimBoneSetOrientation, 'set bone orientation, arguments: X, Y, Z rotation components, start frame index, end frame index'), CommandItemTypeCall);
  _commands_animbones.DoRegister(TCommandSetup.Create('aim', @_IsModelHasSkeletonPrecondition, @_CmdAnimBoneAim, 'aim bone to the specified target, arguments: X, Y, Z global coordinates of target, start frame index, end frame index'), CommandItemTypeCall);
  _commands_animbones.DoRegister(TCommandSetup.Create('aimtobone', @_IsModelHasSkeletonPrecondition, @_CmdAnimBoneAimToBone, 'aim bone to the specified target bone, arguments: target bone, start frame index, end frame index, target bone position frame index (optional, current frame will be used if not specified)'), CommandItemTypeCall);
  _commands_animbones.DoRegister(TCommandSetup.Create('followbone', @_IsModelHasSkeletonPrecondition, @_CmdAnimBoneFollow, 'folow for the other bone as if it was a parent in a source key, args: source bone, source frame index, first target frame index, last target frame index'), CommandItemTypeCall);
  _commands_animbones.DoRegister(TCommandSetup.Create('clonekey', @_IsModelHasSkeletonPrecondition, @_CmdAnimBoneCopyKeyToKeys, 'replace bone keys with data from another bone key, arguments: source key id, first target key id, last target key id'), CommandItemTypeCall);
  _commands_animbones.DoRegister(TCommandSetup.Create('interpolate', @_IsModelHasSkeletonPrecondition, @_CmdAnimBoneSlerpKeys, 'interpolate between two keys, arguments: first key id, last key id, interpolate position (default is true), interpolate rotation (default is true), time factor power (default is 1) '), CommandItemTypeCall);
  _commands_animbones.DoRegister(TCommandSetup.Create('applydiff', @_IsModelHasSkeletonPrecondition, @_CmdAnimBoneApplyDiff, 'apply difference between two transforms to frames; arg 1 - target frame, arg2 - source frame, arg 3 - start frame, arg4 - last frame, optional args 5(and 6) - move (1, default) position (and rotation) or not (0)'), CommandItemTypeCall);

end;

destructor TModelSlot.Destroy;
begin
  FreeAndNil(_iksolver);
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


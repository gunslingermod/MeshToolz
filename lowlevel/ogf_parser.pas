unit ogf_parser;

{$mode objfpc}{$H+}

interface

uses
  ChunkedFileParser, basedefs;

type
  TBoneID = word;

  TOgfVertexCommonData = packed record
    pos:FVector3;
    norm:FVector3;
    tang:FVector3;
    binorm:FVector3;
  end;
  pTOgfVertexCommonData = ^TOgfVertexCommonData;

  TOgfVertex1link = packed record
    spatial:TOgfVertexCommonData;
    uv:FVector2;
    bone_id:cardinal
  end;
  pTOgfVertex1link = ^TOgfVertex1link;

  TOgfVertex2link = packed record
    bone0:TBoneID;
    bone1:TBoneID; // weight of THIS bone is stored in weight1
    spatial:TOgfVertexCommonData;
    weight1: single;
    uv:FVector2;
  end;
  pTOgfVertex2link = ^TOgfVertex2link;

  TOgfVertex3link = packed record
    bones:array [0..2] of TBoneID;
    spatial:TOgfVertexCommonData;
    weights:array [0..1] of single;
    uv:FVector2;
  end;
  pTOgfVertex3link = ^TOgfVertex3link;

  TOgfVertex4link = packed record
    bones:array [0..3] of TBoneID;
    spatial:TOgfVertexCommonData;
    weights:array [0..2] of single;
    uv:FVector2;
  end;
  pTOgfVertex4link = ^TOgfVertex4link;

  TOgfBBox = packed record
    min:FVector3;
    max:FVector3;
  end;

  TOgfBSphere = packed record
    c:FVector3;
    r:single;
  end;

  TOgfHeader = packed record
    format_version:byte;
    ogf_type:byte;
    shader_id:word;
    bb:TOgfBBox;
    bs:TOgfBSphere;
  end;
  pTOgfHeader = ^TOgfHeader;

  TVertexBone = packed record
    bone_id:TBoneID;
    weight:single;
  end;

  TOgfMotionKeyQR = packed record
    x:smallint;
    y:smallint;
    z:smallint;
    w:smallint;
  end;

  TOgfMotionKeyQT8 = packed record
    x1:shortint;
    y1:shortint;
    z1:shortint;
  end;

  TOgfMotionKeyQT16 = packed record
    x1:smallint;
    y1:smallint;
    z1:smallint;
  end;

  TOgfMotionMarkInterval = packed record
    start:single;
    finish:single;
  end;

  { TVertexBones }

  TVertexBones = class
  private
    _bones:array of TVertexBone;

    procedure _SortByWeights();
  public
    // Common
    constructor Create();
    destructor Destroy; override;
    procedure Reset();

    // Specific
    function AddBone(bone:TVertexBone; normalize_weights:boolean):boolean;
    function GetBoneParams(idx:integer):TVertexBone;
    function SetBoneParams(idx:integer; bone:TVertexBone; normalize_weights:boolean):boolean;
    function GetWeightForBoneId(var bone:TVertexBone):boolean; overload;
    function GetWeightForBoneId(bone_id:TBoneID):single; overload;

    function TotalLinkedBonesCount():integer;
    function SimplifiedLinkedBonesCount():integer;
    procedure SimplifyLinks();
    function ChangeLinkType(new_links_count:integer):boolean;
    procedure NormalizeWeights(except_bone_idx:integer=-1);
  end;

  { TOgfVertsContainer }
  TVertexFilterItem = packed record
    need_remove:boolean;
    new_id:cardinal;
  end;
  TVertexFilterItems = array of TVertexFilterItem;

  TOgfVertsContainer = class
  private
    _link_type:cardinal;
    _verts_count:cardinal;
    _raw_data:array of byte;
    function _GetVertexDataPtr(id:cardinal):pTOgfVertexCommonData;
    function _GetVertexUvDataPtr(id:cardinal):pFVector2;
    function _GetVertexBindings(id:cardinal; bindings_out:TVertexBones):boolean;
    function _SetVertexBindings(id:cardinal; bindings_in:TVertexBones):boolean;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):boolean;
    function Serialize():string;
    // Specific
    function MoveVertices(offset:FVector3):boolean;
    function ScaleVertices(factors:FVector3):boolean;
    function RebindVerticesToNewBone(new_bone_index:TBoneID; old_bone_index:TBoneID):boolean;
    function GetVerticesCountForBoneID(boneid:TBoneID; ignorezeroweights:boolean):integer;
    function IsVertexAssignedToBoneID(vertexid:cardinal; boneid:TBoneID; ignorezeroweights:boolean):boolean;

    function GetCurrentLinkType():cardinal;
    function GetVerticesCount():cardinal;
    function CalculateOptimalLinkType():cardinal;
    function ChangeLinkType(new_link_type:cardinal):boolean;

    function FilterVertices(var filter:TVertexFilterItems):boolean;
  end;

  TOgfSlideWindowItem = packed record
    offset:cardinal;
    num_tris:word;
    num_verts:word;
  end;
  pTOgfSlideWindowItem=^TOgfSlideWindowItem;

  { TOgfSwiContainer }

  TOgfSwiContainer = class
  private
    _selected_level:integer;
    _lods:array of TOgfSlideWindowItem;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):boolean;
    function Serialize():string;

    // Specific
    function GetLodLevelsCount():integer;
    function SelectLodLevel(level_id:integer):boolean;
    function GetSelectedLodLevel():integer;
    function GetLodLevelParams(level_id:integer=-1):TOgfSlideWindowItem;
  end;

  TOgfVertexIndex = word;
  TOgfTriangle = packed record
    v1:TOgfVertexIndex;
    v2:TOgfVertexIndex;
    v3:TOgfVertexIndex;
  end;
  pTOgfTriangle = ^TOgfTriangle;

  { TOgfTrisContainer }

  TOgfTrisContainer = class
  private
    _tris:array of TOgfTriangle;
    _current_lod_params:TOgfSlideWindowItem;

    function _GetTriangleIdByOffset(offset:integer):integer;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):boolean;
    function Serialize():string;

    // Specific
    function IsLodAssigned():boolean;
    function AssignLod(params:TOgfSlideWindowItem):boolean;
    function AssignedLodParams():TOgfSlideWindowItem;
    function TrisCountTotal():integer;
    function TrisCountInCurrentLod():integer;

    function FilterVertices(var filter:TVertexFilterItems):boolean;
  end;

  TOgfTextureData = record
    texture:string;
    shader:string;
  end;

  { TOgfTextureDataContainer }

  TOgfTextureDataContainer = class
  private
    _loaded:boolean;
    _data:TOgfTextureData;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):boolean;
    function Serialize():string;

    // Specific
    function GetTextureData():TOgfTextureData;
    function SetTextureData(data:TOgfTextureData):boolean;
  end;

  { TOgfChild }

  TOgfChild = class
  private
    _loaded:boolean;
    _hdr:TOgfHeader;
    _texture:TOgfTextureDataContainer;
    _verts:TOgfVertsContainer;
    _tris:TOgfTrisContainer;
    _swr:TOgfSwiContainer;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):boolean;
    function Serialize():string;

    // Specific
    function GetTextureData():TOgfTextureData;
    function SetTextureData(data:TOgfTextureData):boolean;

    function GetCurrentLinkType():cardinal;
    function GetVerticesCount():cardinal;
    function GetTrisCountTotal():cardinal;
    function GetTrisCountInCurrentLod():cardinal;

    function CalculateOptimalLinkType():cardinal;
    function ChangeLinkType(new_link_type:cardinal):boolean;
    function RebindVertices(target_boneid:TBoneID; source_boneid:TBoneID):boolean;
    function GetVerticesCountForBoneId(boneid:TBoneID):integer;

    function FilterVertices(var filter:TVertexFilterItems):boolean;
    function RemoveVerticesForBoneId(boneid:TBoneID; remove_all_except_selected:boolean):boolean;

    function Scale(v:FVector3):boolean;
    function Move(v:FVector3):boolean;

  end;

  { TOgfChildrenContainer }

  TOgfChildrenContainer = class
    _loaded:boolean;
    _children:array of TOgfChild;

    function _IsValidIndex(index:integer):boolean;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):boolean;
    function Serialize():string;

    // Specific
    function Count():integer;
    function Get(id:integer):TOgfChild;
    function Remove(id:integer):boolean;
    function Append(data:string):integer;
    function Insert(data:string; index:integer):integer;
    function Replace(id:integer; data:string):boolean;
  end;


  { TOgfBone }

  TOgfBone = class
    _name:string;
    _parent_name:string;
    _obb:FObb;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):integer;
    function Serialize():string;

    //Specific
    function GetName():string;
    function GetParentName():string;
    function GetOBB():FObb;
    function Rename(name:string):boolean;

    function UniformScale(k:single):boolean;
  end;

  { TOgfBoneShape }

  TOgfBoneShape = packed record
    shape_type:word;
    flags:word;
    box:FObb;
    sphere:FSphere;
    cylinder:FCylinder;
  end;
  pTOgfBoneShape = ^TOgfBoneShape;

  { TOgfJointLimit }

  TOgfJointLimit = packed record
    limit:FVector2;
    spring_factor:single;
    damping_factor:single;
  end;
  pTOgfJointLimit = ^TOgfJointLimit;

  { TOgfJointIKData }

  TOgfJointIKData = class
    _type:cardinal;
    _limits:array [0..2] of TOgfJointLimit;
    _spring_factor:single;
    _damping_factor:single;
    _ik_flags:cardinal;
    _break_force:single;
    _break_torque:single;
    _friction:single;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset; virtual;
    function Loaded():boolean;
    function Deserialize(rawdata:string; version:cardinal):integer;
    function Serialize(version:cardinal):string;
  end;

  { TOgfBoneIKData }

  TOgfBoneIKData = class
    _version:cardinal;
    _material:string;
    _shape:TOgfBoneShape;
    _ikdata:TOgfJointIKData;
    _rest_rotate:FVector3;
    _rest_offset:FVector3;
    _mass:single;
    _center_of_mass:FVector3;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):integer;
    function Serialize():string;

    // Specific
    function GetShape():TOgfBoneShape;
    function MoveShape(v:FVector3):boolean;
    function SerializeShape():string;
    function DeserializeShape(s:string):boolean;

    function UniformScale(k:single):boolean;
  end;

  { TOgfBonesIKDataContainer }

  TOgfBonesIKDataContainer = class
    _loaded:boolean;
    _ik_data:array of TOgfBoneIKData;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):boolean;
    function Serialize():string;

    // Specific
    function Count():integer;
    function Get(i:integer):TOgfBoneIKData;

    function UniformScale(k:single):boolean;
  end;

  { TOgfBonesContainer }

  TOgfBonesContainer = class
    _loaded:boolean;
    _bones:array of TOgfBone;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):boolean;
    function Serialize():string;

    // Specific
    function Count():integer;
    function Bone(i:integer):TOgfBone;

    function UniformScale(k:single):boolean;
  end;

  { TOgfSkeleton }

  TOgfSkeletonData = packed record
    bones:TOgfBonesContainer;
    ik:TOgfBonesIKDataContainer;
  end;

  TOgfSkeleton = class
    _loaded:boolean;
    _data:TOgfSkeletonData;
  public
    constructor Create();
    procedure Reset;
    function Loaded():boolean;
    destructor Destroy(); override;

    function Build(desc:TOgfBonesContainer; ik:TOgfBonesIKDataContainer):boolean;

    function GetBonesCount():integer;
    function GetBoneName(id:integer):string;
    function GetParentBoneName(id:integer):string;
    function GetOgfShape(boneid:integer):TOgfBoneShape;

    function CopySerializedBoneIKData(id:integer):string;
    function PasteSerializedBoneIKData(id:integer; s:string):boolean;

    function UniformScale(k:single):boolean;
  end;

  { TOgfUserdataContainer }

  TOgfUserdataContainer = class
    _loaded:boolean;
    _script:string;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):boolean;
    function Serialize():string;
  end;

  { TOgfLodRefsContainer }

  TOgfLodRefsContainer = class
    _loaded:boolean;
    _lodref:string;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):boolean;
    function Serialize():string;
  end;

  { TOgfMotionBoneTrack }

  TOgfMotionBoneTrack = class
    _loaded:boolean;
    _rot_keys_present:boolean;
    _trans_keys_present:boolean;
    _is16bittransform:boolean;

    _frames_count:integer;

    _rot_keys_rawdata:array of byte;
    _trans_keys_rawdata:array of byte;

    _sizeT:FVector3;
    _initT:FVector3;

  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string; frames_count:cardinal):integer;
    function Serialize():string;
  end;

  { TOgfMotionTrack }

  TOgfMotionTrack = class
    _loaded:boolean;
    _name:string;
    _length:cardinal;
    _bone_tracks:array of TOgfMotionBoneTrack;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):boolean;
    function Serialize():string;
  end;


  { TOgfMotionTracksContainer }

  TOgfMotionTracksContainer = class
    _loaded:boolean;
    _motions:array of TOgfMotionTrack;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):boolean;
    function Serialize():string;
  end;

   { TOgfMotionBoneParams }

   TOgfMotionBoneParams = class
     _loaded:boolean;
     _name:string;
     _idx:cardinal;
   public
     // Common
     constructor Create;
     destructor Destroy; override;
     procedure Reset;
     function Loaded():boolean;
     function Deserialize(rawdata:string):integer;
     function Serialize():string;
   end;

   { TOgfMotionBonePart }

   TOgfMotionBonePart = class
     _loaded:boolean;
     _name:string;
     _bones_params:array of TOgfMotionBoneParams;
   public
     // Common
     constructor Create;
     destructor Destroy; override;
     procedure Reset;
     function Loaded():boolean;
     function Deserialize(rawdata:string):integer;
     function Serialize():string;
   end;



   { TOgfMotionMark }

   TOgfMotionMark = class
     _loaded:boolean;
     _name:string;
     _intervals: array of TOgfMotionMarkInterval;
   public
     // Common
     constructor Create;
     destructor Destroy; override;
     procedure Reset;
     function Loaded():boolean;
     function Deserialize(rawdata:string):integer;
     function Serialize():string;
   end;

   { TOgfMotionMarks }

   TOgfMotionMarks = class
     _loaded:boolean;
     _marks:array of TOgfMotionMark;
   public
     // Common
     constructor Create;
     destructor Destroy; override;
     procedure Reset;
     function Loaded():boolean;
     function Deserialize(rawdata:string):integer;
     function Serialize():string;
   end;

   { TOgfMotionDef }

   TOgfMotionDef = class
     _loaded:boolean;
     _name:string;
     _flags:cardinal;
     _bone_or_part:word;
     _motion_id:word;
     _speed:single;
     _power:single;
     _accrue:single;
     _falloff:single;
     _marks:TOgfMotionMarks;
   public
     // Common
     constructor Create;
     destructor Destroy; override;
     procedure Reset;
     function Loaded():boolean;
     function Deserialize(rawdata:string; version:cardinal):integer;
     function Serialize():string;
   end;

  { TOgfMotionParamsContainer }

  TOgfMotionParamsContainer = class
    _loaded:boolean;
    _version:word;
    _bone_parts:array of TOgfMotionBonePart;
    _defs: array of TOgfMotionDef;

  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):boolean;
    function Serialize():string;
  end;

  { TOgfAnimationsParser }

  TOgfAnimationsParser = class
    _loaded:boolean;
    _original_data:string;

    _tracks:TOgfMotionTracksContainer;
    _params:TOgfMotionParamsContainer;

    function _UpdateChunk(id:word; data:string):boolean;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):boolean;
    function Serialize():string;

    // Specific
    procedure Sanitize();
  end;

 { TOgfParser }

 TOgfParser = class
 private
   _loaded:boolean;
   _original_data:string;

   _children:TOgfChildrenContainer;
   _bone_names:TOgfBonesContainer;
   _ikdata:TOgfBonesIKDataContainer;
   _userdata:TOgfUserdataContainer;
   _lodref:TOgfLodRefsContainer;
   _skeleton:TOgfSkeleton;

   function _UpdateChunk(id:word; data:string):boolean;
 public
   // Common
   constructor Create;
   destructor Destroy; override;
   procedure Reset;
   function Loaded():boolean;
   function Deserialize(rawdata:string):boolean;
   function Serialize():string;

   // Specific
   function LoadFromFile(fname:string):boolean;
   function SaveToFile(fname:string):boolean;
   function LoadFromMem(addr:pointer; sz:cardinal):boolean;

   function ReloadOriginal():boolean; // reload from original data and forget all modifications
   function UpdateOriginal():boolean; // update original data with modifications

   function Meshes():TOgfChildrenContainer;
   function Skeleton():TOgfSkeleton;
end;

const
  INVALID_BONE_ID: TBoneID = $FFFF;

  OGF_LINK_TYPE_INVALID : cardinal = 0;
  OGF_LINK_TYPE_1 : cardinal = 1;
  OGF_LINK_TYPE_2 : cardinal = 2;
  OGF_LINK_TYPE_3 : cardinal = 3;
  OGF_LINK_TYPE_4 : cardinal = 4;
  OGF_VERTEXFORMAT_FVF_1L : cardinal = $12071980;
  OGF_VERTEXFORMAT_FVF_2L : cardinal = 2*$12071980;
  OGF_VERTEXFORMAT_FVF_3L : cardinal = 3*$12071980;
  OGF_VERTEXFORMAT_FVF_4L : cardinal = 4*$12071980;

  CHUNK_OGF_HEADER:word=1;
  CHUNK_OGF_TEXTURE:word=2;
  CHUNK_OGF_VERTICES:word=3;
  CHUNK_OGF_INDICES:word=4;
  CHUNK_OGF_SWIDATA:word=6;
  CHUNK_OGF_CHILDREN:word=9;
  CHUNK_OGF_S_BONE_NAMES:word=13;
  CHUNK_OGF_S_IKDATA:word=16;
  CHUNK_OGF_S_USERDATA:word=17;
  CHUNK_OGF_S_LODS:word=23;

  OGF_JOINT_TYPE_RIGID:cardinal = 0;
  OGF_JOINT_TYPE_CLOTH:cardinal = 1;
  OGF_JOINT_TYPE_JOINT:cardinal = 2;
  OGF_JOINT_TYPE_WHEEL:cardinal = 3;
  OGF_JOINT_TYPE_NONE:cardinal = 4;
  OGF_JOINT_TYPE_SLIDER:cardinal = 5;
  OGF_JOINT_TYPE_INVALID:cardinal = $FFFFFFFF;

  OGF_SHAPE_TYPE_NONE:word=0;
  OGF_SHAPE_TYPE_BOX:word=1;
  OGF_SHAPE_TYPE_SPHERE:word=2;
  OGF_SHAPE_TYPE_CYLINDER:word=3;
  OGF_SHAPE_TYPE_INVALID:word=$FFFF;

  OGF_JOINT_IK_VERSION_0:cardinal = 0;
  OGF_JOINT_IK_VERSION_1:cardinal = 1;

  MOTION_FLAG_T_KEY_PRESENT:byte = 1;
  MOTION_FLAG_R_KEY_ABSENT:byte = 2;
  MOTION_FLAG_T_KEY_16BIT:byte = 4;

implementation
uses sysutils, FastCrc;

function SerializeVector3(v:FVector3):string;
begin
  result:=SerializeFloat(v.x)+SerializeFloat(v.y)+SerializeFloat(v.z);
end;

function SerializeVector2(v:FVector2):string;
begin
  result:=SerializeFloat(v.x)+SerializeFloat(v.y);
end;

function ShapeMove(var s:TOgfBoneShape; v:FVector3):boolean;
begin
  result:=false;
  if s.shape_type = OGF_SHAPE_TYPE_BOX then begin
    s.box.m_translate.x:=s.box.m_translate.x+v.x;
    s.box.m_translate.y:=s.box.m_translate.y+v.y;
    s.box.m_translate.z:=s.box.m_translate.z+v.z;
    result:=true;
  end else if s.shape_type = OGF_SHAPE_TYPE_SPHERE then begin
    s.sphere.p.x:=s.sphere.p.x+s.box.m_translate.x+v.x;
    s.sphere.p.y:=s.sphere.p.y+s.box.m_translate.y+v.y;
    s.sphere.p.z:=s.sphere.p.z+s.box.m_translate.z+v.z;
    result:=true;
  end else if s.shape_type = OGF_SHAPE_TYPE_CYLINDER then begin
    s.cylinder.m_center.x:=s.cylinder.m_center.x+v.x;
    s.cylinder.m_center.y:=s.cylinder.m_center.y+v.y;
    s.cylinder.m_center.z:=s.cylinder.m_center.z+v.z;
    result:=true;
  end;
end;

function ShapeUniformScale(var s:TOgfBoneShape; k:single):boolean;
begin
  result:=false;

  if s.shape_type = OGF_SHAPE_TYPE_BOX then begin
    uniform_scale(s.box, k);
    result:=true;
  end else if s.shape_type = OGF_SHAPE_TYPE_SPHERE then begin
    uniform_scale(s.sphere, k);
    result:=true;
  end else if s.shape_type = OGF_SHAPE_TYPE_CYLINDER then begin
    uniform_scale(s.cylinder, k);
    result:=true;
  end else if s.shape_type = OGF_SHAPE_TYPE_NONE then begin;
    result:=true;
  end;
end;

{ TOgfMotionMark }

constructor TOgfMotionMark.Create;
begin
  _loaded:=false;
  _name:='';
  setlength(_intervals, 0);
  Reset();
end;

destructor TOgfMotionMark.Destroy;
begin
  inherited Destroy;
end;

procedure TOgfMotionMark.Reset;
begin
  _loaded:=false;
  _name:='';
  setlength(_intervals, 0);
end;

function TOgfMotionMark.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfMotionMark.Deserialize(rawdata: string): integer;
var
  sz:integer;
  cnt:integer;
  i:integer;
  initial_len:integer;
begin
  result:=0;
  Reset();

  try
    initial_len:=length(rawdata);

    if not DeserializeTermString(rawdata, _name) then exit;

    sz:=sizeof(cardinal);
    if length(rawdata)<sz then exit;
    cnt:=PCardinal(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;
    setlength(_intervals, cnt);



    for i:=0 to cnt-1 do begin
      sz:=sizeof(single);
      if length(rawdata)<sz then exit;
      _intervals[i].start:=PSingle(PAnsiChar(rawdata))^;
      if not AdvanceString(rawdata, sz) then exit;

      sz:=sizeof(single);
      if length(rawdata)<sz then exit;
      _intervals[i].finish:=PSingle(PAnsiChar(rawdata))^;
      if not AdvanceString(rawdata, sz) then exit;
    end;

    result:=initial_len - length(rawdata);
  finally
    if result>0 then begin
      _loaded:=true;
    end else begin
      Reset;
    end;
  end;
end;

function TOgfMotionMark.Serialize(): string;
var
  i:integer;
begin
  result:='';
  if not _loaded then exit;
  result:=result+_name+chr($0d)+chr($0a);
  result:=result+SerializeCardinal(length(_intervals));
  for i:=0 to length(_intervals)-1 do begin
    result:=result+SerializeFloat(_intervals[i].start);
    result:=result+SerializeFloat(_intervals[i].finish);
  end;
end;

{ TOgfMotionMarks }

constructor TOgfMotionMarks.Create;
begin
  _loaded:=false;
  setlength(_marks, 0);
  Reset;
end;

destructor TOgfMotionMarks.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TOgfMotionMarks.Reset;
var
  i:integer;
begin
  _loaded:=false;
  for i:=0 to length(_marks)-1 do begin
    _marks[i].Free();
  end;
  setlength(_marks, 0);
end;

function TOgfMotionMarks.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfMotionMarks.Deserialize(rawdata: string): integer;
var
  sz:integer;
  cnt:integer;
  i:integer;
  initial_len:integer;
begin
  result:=0;
  Reset();

  try
    initial_len:=length(rawdata);

    sz:=sizeof(cardinal);
    if length(rawdata)<sz then exit;
    cnt:=PCardinal(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    setlength(_marks, cnt);
    for i:=0 to cnt-1 do begin
      _marks[i]:=TOgfMotionMark.Create;
    end;

    for i:=0 to cnt-1 do begin
      sz:=_marks[i].Deserialize(rawdata);
      if sz<=0 then exit;
      if not AdvanceString(rawdata, sz) then exit;
    end;

    result:=initial_len - length(rawdata);
  finally
    if result>0 then begin
      _loaded:=true;
    end else begin
      Reset;
    end;
  end;

end;

function TOgfMotionMarks.Serialize(): string;
var
  i:integer;
begin
  result:='';
  if not _loaded then exit;
  result:=result+SerializeCardinal(length(_marks));

  for i:=0 to length(_marks)-1 do begin
    result:=result+_marks[i].Serialize();
  end;
end;

{ TOgfMotionDef }

constructor TOgfMotionDef.Create;
begin
  _loaded:=false;
  _marks:=TOgfMotionMarks.Create();
  Reset();
end;

destructor TOgfMotionDef.Destroy;
begin
  Reset();
  FreeAndNil(_marks);
  inherited Destroy;
end;

procedure TOgfMotionDef.Reset;
var
  i:integer;
begin
  _loaded:=false;
  _marks.Reset;

  _name:='';
  _flags:=0;
  _bone_or_part:=0;
  _motion_id:=0;
  _speed:=1;
  _power:=1;
  _accrue:=2;
  _falloff:=2;
end;

function TOgfMotionDef.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfMotionDef.Deserialize(rawdata: string; version: cardinal): integer;
var
  initial_len: integer;
  sz:integer;
begin
  result:=0;
  Reset();

  try
    initial_len:=length(rawdata);
    if not DeserializeZStringAndSplit(rawdata, _name) then exit;

    sz:=sizeof(cardinal);
    if length(rawdata)<sz then exit;
    _flags:=PCardinal(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    sz:=sizeof(word);
    if length(rawdata)<sz then exit;
    _bone_or_part:=PWord(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    sz:=sizeof(word);
    if length(rawdata)<sz then exit;
    _motion_id:=PWord(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    sz:=sizeof(single);
    if length(rawdata)<sz then exit;
    _speed:=PSingle(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    sz:=sizeof(single);
    if length(rawdata)<sz then exit;
    _power:=PSingle(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    sz:=sizeof(single);
    if length(rawdata)<sz then exit;
    _accrue:=PSingle(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    sz:=sizeof(single);
    if length(rawdata)<sz then exit;
    _falloff:=PSingle(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    if version>=4 then begin
      sz:=_marks.Deserialize(rawdata);
      if sz <=0 then exit;
      if not AdvanceString(rawdata, sz) then exit;
    end;
    result:=initial_len - length(rawdata);
  finally
    if result>0 then begin
      _loaded:=true;
    end else begin
      Reset;
    end;
  end;
end;

function TOgfMotionDef.Serialize(): string;
begin
  result:='';
  if not _loaded then exit;

  result:=result+_name+chr(0);
  result:=result+SerializeCardinal(_flags);
  result:=result+SerializeWord(_bone_or_part);
  result:=result+SerializeWord(_motion_id);
  result:=result+SerializeFloat(_speed);
  result:=result+SerializeFloat(_power);
  result:=result+SerializeFloat(_accrue);
  result:=result+SerializeFloat(_falloff);
  result:=result+_marks.Serialize(); // for version <4 returns an empty string

end;

{ TOgfMotionBoneParams }

constructor TOgfMotionBoneParams.Create;
begin
  Reset();
end;

destructor TOgfMotionBoneParams.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TOgfMotionBoneParams.Reset;
begin
  _loaded:=false;
  _name:='';
  _idx:=0;
end;

function TOgfMotionBoneParams.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfMotionBoneParams.Deserialize(rawdata: string): integer;
var
  initial_len:integer;
  sz:cardinal;
begin
  result:=0;
  Reset();

  try
    initial_len:=length(rawdata);
    if not DeserializeZStringAndSplit(rawdata, _name) then exit;
    sz:=sizeof(cardinal);
    if length(rawdata)<sz then exit;
    _idx:=(PCardinal(PAnsiChar(rawdata))^) and $FFFF;
    if not AdvanceString(rawdata, sz) then exit;
    result:=initial_len - length(rawdata);
  finally
    if result>0 then begin
      _loaded:=true;
    end else begin
      Reset;
    end;
  end;
end;

function TOgfMotionBoneParams.Serialize(): string;
begin
  result:='';
  if not _loaded then exit;

  result:=result+_name+chr(0);
  result:=result+SerializeCardinal(_idx);
end;

{ TOgfMotionBonePart }

constructor TOgfMotionBonePart.Create;
begin
  setlength(_bones_params, 0);
  _loaded:=false;
  _name:='';
  Reset();
end;

destructor TOgfMotionBonePart.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TOgfMotionBonePart.Reset;
var
  i:integer;
begin
  _loaded:=false;
  _name:='';
  for i:=0 to length(_bones_params)-1 do begin
    _bones_params[i].Free;
  end;
  setlength(_bones_params, 0);
end;

function TOgfMotionBonePart.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfMotionBonePart.Deserialize(rawdata: string): integer;
var
  initial_len:integer;
  sz:integer;
  bones_cnt:word;
  i:integer;
begin
  result:=0;
  Reset();

  try
    initial_len:=length(rawdata);
    if not DeserializeZStringAndSplit(rawdata, _name) then exit;

    sz:=sizeof(word);
    if length(rawdata)<sz then exit;
    bones_cnt:=PWord(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    setlength(_bones_params, bones_cnt);
    for i:=0 to bones_cnt-1 do begin
      _bones_params[i]:=TOgfMotionBoneParams.Create();
    end;

    for i:=0 to bones_cnt-1 do begin
      sz:=_bones_params[i].Deserialize(rawdata);
      if sz <= 0 then exit;
      if not AdvanceString(rawdata, sz) then exit;
    end;

    result:=initial_len - length(rawdata);
  finally
    if result>0 then begin
      _loaded:=true;
    end else begin
      Reset;
    end;
  end;
end;

function TOgfMotionBonePart.Serialize(): string;
var
  i:integer;
begin
  result:='';
  if not _loaded then exit;

  result:=result+_name+chr(0);
  result:=result+SerializeWord(length(_bones_params));

  for i:=0 to length(_bones_params)-1 do begin
    result:=result+_bones_params[i].Serialize();
  end;

end;


{ TOgfMotionParamsContainer }

constructor TOgfMotionParamsContainer.Create;
begin
  _loaded:=false;
  _version:=0;
  setlength(_bone_parts, 0);
  setlength(_defs, 0);
  Reset();
end;

destructor TOgfMotionParamsContainer.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TOgfMotionParamsContainer.Reset;
var
  i:integer;
begin
  _loaded:=false;
  _version:=0;

  for i:=0 to length(_bone_parts)-1 do begin
    _bone_parts[i].Free;
  end;
  setlength(_bone_parts, 0);

  for i:=0 to length(_defs)-1 do begin
    _defs[i].Free;
  end;
  setlength(_defs, 0);
end;

function TOgfMotionParamsContainer.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfMotionParamsContainer.Deserialize(rawdata: string): boolean;
var
  sz, cnt, i:integer;
begin
  result:=false;
  Reset();

  try
    sz:=sizeof(word);
    if length(rawdata)<sz then exit;
    _version:=PWord(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    if _version<>4 then exit;

    sz:=sizeof(word);
    if length(rawdata)<sz then exit;
    cnt:=PWord(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    setlength(_bone_parts, cnt);
    for i:=0 to cnt-1 do begin
      _bone_parts[i]:=TOgfMotionBonePart.Create();
    end;

    for i:=0 to cnt-1 do begin
      sz:=_bone_parts[i].Deserialize(rawdata);
      if sz <= 0 then exit;
      if not AdvanceString(rawdata, sz) then exit;
    end;

    sz:=sizeof(word);
    if length(rawdata)<sz then exit;
    cnt:=PWord(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    setlength(_defs, cnt);
    for i:=0 to cnt-1 do begin
      _defs[i]:=TOgfMotionDef.Create();
    end;

    for i:=0 to cnt-1 do begin
      sz:=_defs[i].Deserialize(rawdata, _version);
      if sz <= 0 then exit;
      if not AdvanceString(rawdata, sz) then exit;
    end;

    result:=true;
  finally
    if result then begin
      _loaded:=true;
    end else begin
      Reset;
    end;
  end;
end;

function TOgfMotionParamsContainer.Serialize(): string;
var
  i:integer;
begin
  result:='';
  if not _loaded then exit;

  result:=result+SerializeWord(_version);
  result:=result+SerializeWord(length(_bone_parts));
  for i:=0 to length(_bone_parts)-1 do begin
    result:=result+_bone_parts[i].Serialize();
  end;

  result:=result+SerializeWord(length(_defs));
  for i:=0 to length(_defs)-1 do begin
    result:=result+_defs[i].Serialize();
  end;

end;

{ TOgfMotionBoneTrack }

constructor TOgfMotionBoneTrack.Create;
begin
  Reset();
end;

destructor TOgfMotionBoneTrack.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TOgfMotionBoneTrack.Reset;
begin
  _loaded:=false;
  _is16bittransform:=false;
  _rot_keys_present:=false;
  _trans_keys_present:=false;
  _frames_count:=0;
  setlength(_rot_keys_rawdata, 0);
  setlength(_trans_keys_rawdata, 0);
end;

function TOgfMotionBoneTrack.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfMotionBoneTrack.Deserialize(rawdata: string; frames_count: cardinal): integer;
var
  flags:byte;
  total:integer;
  sz:integer;
begin
  result:=0;
  total:=0;
  Reset();
  _frames_count:=frames_count;

  try
    sz:=sizeof(byte);
    if length(rawdata) < sz then exit;
    flags:=PByte(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;
    total:=total+sz;

    _rot_keys_present:=(flags and MOTION_FLAG_R_KEY_ABSENT) = 0;
    _trans_keys_present:=(flags and MOTION_FLAG_T_KEY_PRESENT) <> 0;
    _is16bittransform:=(flags and MOTION_FLAG_T_KEY_16BIT)<>0;

    if _rot_keys_present then begin
      sz:=sizeof(cardinal); // rot crc
      if not AdvanceString(rawdata, sz) then exit;
      total:=total+sz;

      sz:=frames_count*sizeof(TOgfMotionKeyQR);
    end else begin
      sz:=sizeof(TOgfMotionKeyQR);
    end;

    if length(rawdata) < sz then exit;
    setlength(_rot_keys_rawdata, sz);
    Move(PAnsiChar(rawdata)^, _rot_keys_rawdata[0], sz);
    if not AdvanceString(rawdata, sz) then exit;
    total:=total+sz;

    if _trans_keys_present then begin
      sz:=sizeof(cardinal); //trans crc
      if not AdvanceString(rawdata, sz) then exit;
      total:=total+sz;

      if _is16bittransform then begin
        sz:=frames_count*sizeof(TOgfMotionKeyQT16);
      end else begin
        sz:=frames_count*sizeof(TOgfMotionKeyQT8);
      end;

      if length(rawdata) < sz then exit;
      setlength(_trans_keys_rawdata, sz);
      Move(PAnsiChar(rawdata)^, _trans_keys_rawdata[0], sz);
      if not AdvanceString(rawdata, sz) then exit;
      total:=total+sz;

      sz:=sizeof(FVector3);
      if length(rawdata) < sz then exit;
      _sizeT:=pFVector3(PAnsiChar(rawdata))^;
      if not AdvanceString(rawdata, sz) then exit;
      total:=total+sz;
    end;

    sz:=sizeof(FVector3);
    if length(rawdata) < sz then exit;
    _initT:=pFVector3(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;
    total:=total+sz;

    result:=total;
  finally
    if result>0 then begin
      _loaded:=true;
    end else begin
      Reset;
    end;
  end;

end;

function TOgfMotionBoneTrack.Serialize(): string;
var
  flags:byte;
  crc:cardinal;
begin
  result:='';
  if not Loaded() then exit;

  flags:=0;
  if not _rot_keys_present then begin
    flags:=flags or MOTION_FLAG_R_KEY_ABSENT;
  end;
  if _trans_keys_present then begin
    flags:=flags or MOTION_FLAG_T_KEY_PRESENT;
  end;
  if _is16bittransform then begin
    flags:=flags or MOTION_FLAG_T_KEY_16BIT;
  end;
  result:=result+SerializeByte(flags);

  if _rot_keys_present then begin
     crc:=GetMemCRC32(@_rot_keys_rawdata[0], length(_rot_keys_rawdata));
     result:=result+SerializeCardinal(crc);
  end;
  result:=result+SerializeBlock(@_rot_keys_rawdata[0], length(_rot_keys_rawdata));

  if _trans_keys_present then begin
    crc:=GetMemCRC32(@_trans_keys_rawdata[0], length(_trans_keys_rawdata));
    result:=result+SerializeCardinal(crc);
  end;
  result:=result+SerializeBlock(@_trans_keys_rawdata[0], length(_trans_keys_rawdata));
  if _trans_keys_present then begin
    result:=result+SerializeVector3(_sizeT);
  end;
  result:=result+SerializeVector3(_initT);
end;

{ TOgfMotionTrack }

constructor TOgfMotionTrack.Create;
begin
  setlength(_bone_tracks, 0);
  _loaded:=false;
  _length:=0;
  _name:='';
  Reset();
end;

destructor TOgfMotionTrack.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TOgfMotionTrack.Reset;
var
  i:integer;
begin
  _loaded:=false;
  _name:='';
  _length:=0;
  for i:=0 to length(_bone_tracks)-1 do begin
    _bone_tracks[i].Free;
  end;
  setlength(_bone_tracks, 0);
end;

function TOgfMotionTrack.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfMotionTrack.Deserialize(rawdata: string): boolean;
var
  i, sz:integer;
begin
  result:=false;
  Reset();

  try
    if not DeserializeZStringAndSplit(rawdata, _name) then exit;
    sz:=sizeof(cardinal);
    if length(rawdata)<sz then exit;
    _length:=PCardinal(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    while length(rawdata)>0 do begin
      i:=length(_bone_tracks);
      setlength(_bone_tracks, i+1);
      _bone_tracks[i]:=TOgfMotionBoneTrack.Create();
      sz:=_bone_tracks[i].Deserialize(rawdata, _length);

      if sz <= 0 then begin
         _bone_tracks[i].Free();
         setlength(_bone_tracks, i);
         break;
      end else begin
         if not AdvanceString(rawdata, sz) then exit;
      end;
    end;

    result:=(length(_bone_tracks)>0);
  finally
    if result then begin
      _loaded:=true;
    end else begin
      Reset;
    end;
  end;

end;

function TOgfMotionTrack.Serialize(): string;
var
  i:integer;
begin
  result:='';
  if not Loaded() then exit;

  result:=result+_name+chr(0);
  result:=result+SerializeCardinal(_length);

  for i:=0 to length(_bone_tracks)-1 do begin
    result:=result+_bone_tracks[i].Serialize();
  end;

end;

{ TOgfMotionTracksContainer }

constructor TOgfMotionTracksContainer.Create;
begin
  setlength(_motions, 0);
  _loaded:=false;
  Reset();
end;

destructor TOgfMotionTracksContainer.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TOgfMotionTracksContainer.Reset;
var
  i:integer;
begin
  for i:=0 to length(_motions)-1 do begin
    _motions[i].Free;
  end;
  setlength(_motions, 0);
  _loaded:=false;
end;

function TOgfMotionTracksContainer.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfMotionTracksContainer.Deserialize(rawdata: string): boolean;
var
  mem:TChunkedMemory;
  chunk:TChunkedOffset;
  data:string;
  cnt:cardinal;
  i:integer;
begin
  result:=false;
  Reset();

  mem:=TChunkedMemory.Create();
  try
    if not mem.LoadFromString(rawdata) then exit;

    chunk:=mem.FindSubChunk(0);
    if chunk = INVALID_CHUNK then exit;

    if not mem.EnterSubChunk(chunk) then exit;
    data:=mem.GetCurrentChunkRawDataAsString();

    if length(data) < sizeof(cardinal) then exit;
    cnt:= PCardinal(PAnsiChar(data))^;
    if not mem.LeaveSubChunk() then exit;

    setlength(_motions, cnt);
    for i:=0 to length(_motions)-1 do begin
      _motions[i]:=TOgfMotionTrack.Create();
    end;

    for i:=0 to length(_motions)-1 do begin
      chunk:=mem.FindSubChunk(i+1);
      if chunk = INVALID_CHUNK then exit;
      if not mem.EnterSubChunk(chunk) then exit;
      data:=mem.GetCurrentChunkRawDataAsString();
      if not _motions[i].Deserialize(data) then exit;
      if not mem.LeaveSubChunk() then exit;
    end;

    result:=true;
  finally
    if result then begin
      _loaded:=true;
    end else begin
      Reset;
    end;

    mem.Free;
  end;
end;

function TOgfMotionTracksContainer.Serialize(): string;
var
  i:integer;
  data:string;
begin
  result:='';
  if not Loaded() then exit;

  i:=length(_motions);
  data:=SerializeCardinal(i);
  result:=result+SerializeChunkHeader(0, length(data), 0)+data;

  for i:=0 to length(_motions)-1 do begin
    data:=_motions[i].Serialize();
    result:=result+SerializeChunkHeader(i+1, length(data), 0)+data;
  end;
  result:=result;
end;

{ TOgfChildrenContainer }

function TOgfChildrenContainer._IsValidIndex(index:integer): boolean;
begin
  result:=(index >= 0) and (index < length(_children));
end;

constructor TOgfChildrenContainer.Create;
begin
  _loaded:=false;
  setlength(_children, 0);
  Reset();
end;

destructor TOgfChildrenContainer.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TOgfChildrenContainer.Reset;
var
  i:integer;
begin
  _loaded:=false;
  for i:=0 to length(_children)-1 do begin
    _children[i].Free;
  end;
  setlength(_children, 0);
end;

function TOgfChildrenContainer.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfChildrenContainer.Deserialize(rawdata: string): boolean;
var
  i:integer;
  mem:TChunkedMemory;
  chunk:TChunkedOffset;
  data:string;
begin
  result:=false;
  Reset();

  mem:=TChunkedMemory.Create();
  try
    if not mem.LoadFromString(rawdata) then exit;

    i:=0;
    while true do begin
      chunk:=mem.FindSubChunk(i);
      if chunk = INVALID_CHUNK then break;

      result:=false;
      setlength(_children, i+1);
      _children[i]:=TOgfChild.Create();
      if not mem.EnterSubChunk(chunk) then break;
      data:=mem.GetCurrentChunkRawDataAsString();
      if not _children[i].Deserialize(data) then break;
      if not mem.LeaveSubChunk() then break;
      result:=true;
      i:=i+1
    end;
  finally
    if result then begin
      _loaded:=true;
    end else begin
      Reset;
    end;

    mem.Free;
  end;
end;

function TOgfChildrenContainer.Serialize(): string;
var
  i:integer;
  data:string;
begin
  result:='';
  if not Loaded then exit;

  for i:=0 to length(_children)-1 do begin
    data:=_children[i].Serialize();
    if length(data) = 0 then begin
      result:='';
      break;
    end;

    result:=result+SerializeChunkHeader(i, length(data), 0)+data;
  end;
end;

function TOgfChildrenContainer.Count(): integer;
begin
  result:=0;
  if not Loaded() then exit;

  result:=length(_children);
end;

function TOgfChildrenContainer.Get(id: integer): TOgfChild;
begin
  result:=nil;
  if not Loaded() or not _IsValidIndex(id) then exit;

  result:=_children[id];
end;

function TOgfChildrenContainer.Remove(id: integer): boolean;
var
  i:integer;
begin
  result:=false;
  if not Loaded() or not _IsValidIndex(id) then exit;

  _children[id].Free();
  for i:=id to length(_children)-2 do begin
    _children[i]:=_children[i+1]
  end;
  setlength(_children, length(_children)-1);

  result:=true;
end;

function TOgfChildrenContainer.Append(data: string): integer;
var
  child:TOgfChild;
  i:integer;
begin
  result:=-1;
  if not Loaded() then exit;

  child:=TOgfChild.Create();
  if not child.Deserialize(data) then begin
    child.Free;
  end else begin
    i:=length(_children);
    setlength(_children, i+1);
    _children[i]:=child;
    result:=i;
  end;
end;

function TOgfChildrenContainer.Insert(data: string; index: integer): integer;
var
  child:TOgfChild;
  i, oldlen:integer;
begin
  result:=-1;
  if not Loaded() then exit;
  if (index < 0) or (index > length(_children)) then exit;

  child:=TOgfChild.Create();
  if not child.Deserialize(data) then begin
    child.Free;
  end else begin
    oldlen:=length(_children);
    setlength(_children, oldlen+1);
    for i:=oldlen-1 downto index do begin
      _children[i+1]:=_children[i];
    end;
    _children[index]:=child;
    result:=index;
  end;
end;

function TOgfChildrenContainer.Replace(id: integer; data: string): boolean;
begin
  result:=false;
  if not Loaded() or (length(_children)<=id) then exit;

  result:=_children[id].Deserialize(data);
end;

{ TOgfSkeleton }

constructor TOgfSkeleton.Create();
begin
  Reset;
end;

procedure TOgfSkeleton.Reset;
begin
  _loaded:=false;
  _data.ik:=nil;
  _data.bones:=nil;
end;

function TOgfSkeleton.Loaded(): boolean;
begin
  result:=_loaded;
end;

destructor TOgfSkeleton.Destroy();
begin
  Reset();
  inherited Destroy();
end;


function TOgfSkeleton.Build(desc: TOgfBonesContainer; ik: TOgfBonesIKDataContainer): boolean;
begin
  result:=false;
  if desc.Count()<>ik.Count() then exit;
  Reset();
  _data.ik:=ik;
  _data.bones:=desc;

  _loaded:=true;
  result:=true;
end;

function TOgfSkeleton.GetBonesCount(): integer;
begin
  if not Loaded() then begin
    result:=0;
    exit;
  end;

  result:=_data.bones.Count();
end;

function TOgfSkeleton.GetBoneName(id: integer): string;
var
  b:TOgfBone;
begin
  result:='';
  if not Loaded() then exit;
  b:=_data.bones.Bone(id);
  if b=nil then exit;
  result:=b.GetName();
end;

function TOgfSkeleton.GetParentBoneName(id: integer): string;
var
  b:TOgfBone;
begin
  result:='';
  if not Loaded() then exit;
  b:=_data.bones.Bone(id);
  if b=nil then exit;
  result:=b.GetParentName();
end;

function TOgfSkeleton.GetOgfShape(boneid: integer): TOgfBoneShape;
var
  boneik:TOgfBoneIKData;
begin
  result.shape_type:=OGF_SHAPE_TYPE_INVALID;
  boneik:=_data.ik.Get(boneid);
  if boneik<>nil then begin
    result:=boneik.GetShape();
  end;
end;

function TOgfSkeleton.CopySerializedBoneIKData(id: integer): string;
var
  ikd:TOgfBoneIKData;
begin
  result:='';
  if not Loaded() then exit;
  ikd:=_data.ik.Get(id);
  if ikd=nil then exit;
  result:=ikd.Serialize();
end;

function TOgfSkeleton.PasteSerializedBoneIKData(id: integer; s: string): boolean;
var
  ikd:TOgfBoneIKData;
begin
  result:=false;
  if not Loaded() then exit;
  ikd:=_data.ik.Get(id);
  if ikd=nil then exit;
  result:=(ikd.Deserialize(s)>0);
end;

function TOgfSkeleton.UniformScale(k: single): boolean;
begin
  result:=false;
  if not Loaded() then exit;
  result:= _data.bones.UniformScale(k) and _data.ik.UniformScale(k);
end;


{ TOgfLodRefsContainer }

constructor TOgfLodRefsContainer.Create;
begin
  Reset();
end;

destructor TOgfLodRefsContainer.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TOgfLodRefsContainer.Reset;
begin
  _loaded:=false;
  _lodref:='';
end;

function TOgfLodRefsContainer.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfLodRefsContainer.Deserialize(rawdata: string): boolean;
begin
  result:=false;
  Reset;
  if not DeserializeTermString(rawdata, _lodref) then exit;
  _loaded:=true;
  result:=true;
end;

function TOgfLodRefsContainer.Serialize(): string;
begin
  result:='';
  if not Loaded() then exit;
  result:=result+_lodref+chr($0d)+chr($0a);
end;

{ TOgfUserdataContainer }

constructor TOgfUserdataContainer.Create;
begin
  Reset();
end;

destructor TOgfUserdataContainer.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TOgfUserdataContainer.Reset;
begin
  _loaded:=false;
  _script:='';
end;

function TOgfUserdataContainer.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfUserdataContainer.Deserialize(rawdata: string): boolean;
begin
  result:=false;
  Reset;
  if not DeserializeZStringAndSplit(rawdata, _script) then exit;
  result:=true;
end;

function TOgfUserdataContainer.Serialize(): string;
begin
  result:='';
  if not Loaded() then exit;
  result:=result+_script+chr(0);
end;

{ TOgfBonesIKDataContainer }

constructor TOgfBonesIKDataContainer.Create;
begin
  _loaded:=false;
  setlength(_ik_data, 0);
  Reset();
end;

destructor TOgfBonesIKDataContainer.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TOgfBonesIKDataContainer.Reset;
var
  i:integer;
begin
  for i:=0 to length(_ik_data)-1 do begin
    _ik_data[i].Free;
  end;
  setlength(_ik_data, 0);
  _loaded:=false;
end;

function TOgfBonesIKDataContainer.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfBonesIKDataContainer.Deserialize(rawdata: string): boolean;
var
  i, cnt:integer;
begin
  result:=false;
  Reset();

  repeat
    i:=length(_ik_data);
    setlength(_ik_data, i+1);
    _ik_data[i]:=TOgfBoneIKData.Create();
    cnt:=_ik_data[i].Deserialize(rawdata);
    if (cnt<0) or not AdvanceString(rawdata, cnt) then begin
      Reset();
      break;
    end;
    if length(rawdata) = 0 then begin
      result:=true;
    end;
  until result;

  _loaded:=result;
end;

function TOgfBonesIKDataContainer.Serialize(): string;
var
  i:integer;
begin
  result:='';
  if not Loaded() then exit;

  for i:=0 to length(_ik_data)-1 do begin
    result:=result+_ik_data[i].Serialize();
  end;
end;

function TOgfBonesIKDataContainer.Count(): integer;
begin
  if Loaded() then begin
    result:=length(_ik_data);
  end else begin
    result:=0;
  end;
end;

function TOgfBonesIKDataContainer.Get(i: integer): TOgfBoneIKData;
begin
  result:=nil;
  if not Loaded() or (i<0) or (i >= length(_ik_data)) then exit;
  result:=_ik_data[i];
end;

function TOgfBonesIKDataContainer.UniformScale(k: single): boolean;
var
  i:integer;
begin
  result:=Loaded();
  if not result then exit;

  for i:=0 to length(_ik_data)-1 do begin
    result:=result and _ik_data[i].UniformScale(k);
  end;
end;

{ TOgfJointIKData }

constructor TOgfJointIKData.Create;
begin
  Reset();
end;

destructor TOgfJointIKData.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TOgfJointIKData.Reset;
var
  i:integer;
begin
  _type:=OGF_JOINT_TYPE_INVALID;
  _ik_flags:=0;

  _spring_factor:=0;
  _damping_factor:=0;
  _break_force:=0;
  _break_torque:=0;
  _friction:=0;

  for i:=0 to length(_limits)-1 do begin
    _limits[i].damping_factor:=0;
    _limits[i].spring_factor:=0;
    set_zero(_limits[i].limit);
  end;
end;

function TOgfJointIKData.Loaded(): boolean;
begin
  result:=(_type<>OGF_JOINT_TYPE_INVALID);
end;

function TOgfJointIKData.Deserialize(rawdata: string; version: cardinal): integer;
var
  sz:integer;
  i,j:integer;
  ptr:PAnsiChar;
begin
  result:=-1;
  Reset();

  sz:=sizeof(_type) +sizeof(_limits)+sizeof(_spring_factor)+sizeof(_damping_factor)+sizeof(_ik_flags)+sizeof(_break_force)+sizeof(_break_torque);
  if version > OGF_JOINT_IK_VERSION_0 then begin
    sz:=sz+sizeof(_friction);
  end;
  if length(rawdata)<sz then exit;

  ptr:=PAnsiChar(@rawdata[1]);
  i:=0;

  _type:=pcardinal(@ptr[i])^;
  i:=i+sizeof(_type);

  for j:=0 to length(_limits)-1 do begin
    _limits[j]:=pTOgfJointLimit(@ptr[i])^;
    i:=i+sizeof(_limits[j]);
  end;

  _spring_factor:=psingle(@ptr[i])^;
  i:=i+sizeof(_spring_factor);

  _damping_factor:=psingle(@ptr[i])^;
  i:=i+sizeof(_damping_factor);

  _ik_flags:=pcardinal(@ptr[i])^;
  i:=i+sizeof(_ik_flags);

  _break_force:=psingle(@ptr[i])^;
  i:=i+sizeof(_break_force);

  _break_torque:=psingle(@ptr[i])^;
  i:=i+sizeof(_break_torque);

  if version > OGF_JOINT_IK_VERSION_0 then begin
    _friction:=psingle(@ptr[i])^;
    i:=i+sizeof(_friction);
  end;

  assert(sz = i);
  result:=sz;
end;

function TOgfJointIKData.Serialize(version: cardinal): string;
var
  i:integer;
begin
  result:='';
  if not Loaded() then exit;

  result:=result+SerializeCardinal(_type);
  for i:=0 to length(_limits)-1 do begin
    result:=result+SerializeVector2(_limits[i].limit);
    result:=result+SerializeFloat(_limits[i].spring_factor);
    result:=result+SerializeFloat(_limits[i].damping_factor);
  end;

  result:=result+SerializeFloat(_spring_factor);
  result:=result+SerializeFloat(_damping_factor);
  result:=result+SerializeCardinal(_ik_flags);
  result:=result+SerializeFloat(_break_force);
  result:=result+SerializeFloat(_break_torque);
  if version > OGF_JOINT_IK_VERSION_0 then begin
    result:=result+SerializeFloat(_friction);
  end;
end;

{ TOgfBoneIKData }

constructor TOgfBoneIKData.Create;
begin
  _ikdata:=TOgfJointIKData.Create;
  Reset();
end;

destructor TOgfBoneIKData.Destroy;
begin
  Reset();
  FreeAndNil(_ikdata);
  inherited Destroy;
end;

procedure TOgfBoneIKData.Reset;
begin
  _version:=$FFFFFFFF;
  _material:='';
  _shape.shape_type:=OGF_SHAPE_TYPE_INVALID;
  _shape.flags:=0;
  set_zero(_shape.box);
  set_zero(_shape.sphere);
  set_zero(_shape.cylinder);
  _ikdata.Reset();
  set_zero(_rest_rotate);
  set_zero(_rest_offset);
  _mass:=0;
  set_zero(_center_of_mass);
end;

function TOgfBoneIKData.Loaded(): boolean;
begin
  result:=(_version <> $FFFFFFFF);
end;

function TOgfBoneIKData.Deserialize(rawdata: string): integer;
var
  sz, total:integer;
begin
  result:=-1;
  total:=0;

  Reset();

  if length(rawdata)<sizeof(_version) then exit;
  _version:=pcardinal(@rawdata[1])^;
  if not AdvanceString(rawdata, sizeof(_version)) then exit;
  total:=total+sizeof(_version);

  if not DeserializeZStringAndSplit(rawdata, _material) then exit;
  total:=total+length(_material)+1;

  if length(rawdata)<sizeof(_shape) then exit;
  _shape:=pTOgfBoneShape(@rawdata[1])^;
  if not AdvanceString(rawdata, sizeof(_shape)) then exit;
  total:=total+sizeof(_shape);

  sz:=_ikdata.Deserialize(rawdata, _version);
  if sz < 0 then exit;
  if not AdvanceString(rawdata, sz) then exit;
  total:=total+sz;

  if length(rawdata)<sizeof(_rest_rotate) then exit;
  _rest_rotate:=pFVector3(@rawdata[1])^;
  if not AdvanceString(rawdata, sizeof(_rest_rotate)) then exit;
  total:=total+sizeof(_rest_rotate);

  if length(rawdata)<sizeof(_rest_offset) then exit;
  _rest_offset:=pFVector3(@rawdata[1])^;
  if not AdvanceString(rawdata, sizeof(_rest_offset)) then exit;
  total:=total+sizeof(_rest_offset);

  if length(rawdata)<sizeof(_mass) then exit;
  _mass:=pSingle(@rawdata[1])^;
  if not AdvanceString(rawdata, sizeof(_mass)) then exit;
  total:=total+sizeof(_mass);

  if length(rawdata)<sizeof(_center_of_mass) then exit;
  _center_of_mass:=pFVector3(@rawdata[1])^;
  if not AdvanceString(rawdata, sizeof(_center_of_mass)) then exit;
  total:=total+sizeof(_center_of_mass);

  result:=total;
end;

function TOgfBoneIKData.Serialize(): string;
var
  t:string;
begin
  result:='';
  if not Loaded() then exit;
  t:=_ikdata.Serialize(_version);
  if length(t) = 0 then exit;

  result:=result+SerializeCardinal(_version);
  result:=result+_material+chr(0);
  result:=result+SerializeBlock(@_shape, sizeof(_shape));
  result:=result+t;
  result:=result+SerializeBlock(@_rest_rotate, sizeof(_rest_rotate));
  result:=result+SerializeBlock(@_rest_offset, sizeof(_rest_offset));
  result:=result+SerializeFloat(_mass);
  result:=result+SerializeBlock(@_center_of_mass, sizeof(_center_of_mass));
end;

function TOgfBoneIKData.GetShape(): TOgfBoneShape;
begin
  result:=_shape;
end;

function TOgfBoneIKData.MoveShape(v: FVector3): boolean;
begin
  result:=false;
  if not Loaded() then exit;

  if _shape.shape_type = OGF_SHAPE_TYPE_NONE then begin
    result:=true
  end else begin
    result:=ShapeMove(_shape, v);
  end;
end;

function TOgfBoneIKData.SerializeShape(): string;
var
  i:integer;
begin
  result:='';
  if not Loaded() then exit;

  for i:=0 to sizeof(_shape)-1 do begin
    result:= result+PAnsiChar(@_shape)[i];
  end;
end;

function TOgfBoneIKData.DeserializeShape(s: string): boolean;
begin
  result:=false;
  if length(s) <> sizeof(_shape) then exit;
  if not Loaded() then exit;
  _shape:=pTOgfBoneShape(@s[1])^;
  result:=true;
end;

function TOgfBoneIKData.UniformScale(k: single): boolean;
begin
  result:=Loaded();
  if not result then exit;
  result:= ShapeUniformScale(_shape, k);
  if not result then exit;

  uniform_scale(_rest_offset, k);
  uniform_scale(_center_of_mass, k);
end;

{ TOgfBone }

constructor TOgfBone.Create;
begin
  Reset;
end;

destructor TOgfBone.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TOgfBone.Reset;
begin
  _name:='';
  _parent_name:='';
  set_zero(_obb);
end;

function TOgfBone.Loaded(): boolean;
begin
  result:=length(_name)>0;
end;

function TOgfBone.Deserialize(rawdata: string): integer;
var
  name, parent:string;
begin
  result:=-1;

  Reset;
  if not DeserializeZStringAndSplit(rawdata, name) then exit;
  if not DeserializeZStringAndSplit(rawdata, parent) then exit;
  if length(rawdata) < sizeof(_obb) then exit;
  _name:=name;
  _parent_name:=parent;
  _obb:=pFObb(@rawdata[1])^;

  result:=length(name)+length(parent)+2+sizeof(_obb);
end;

function TOgfBone.Serialize(): string;
var
  i:integer;
begin
  result:='';
  if not Loaded() then exit;

  result:=result+_name+chr(0);
  result:=result+_parent_name+chr(0);

  for i:=0 to sizeof(_obb)-1 do begin
    result:=result+PAnsiChar(@_obb)[i];
  end;
end;

function TOgfBone.GetName(): string;
begin
  result:=_name;
end;

function TOgfBone.GetParentName(): string;
begin
  result:=_parent_name;
end;

function TOgfBone.GetOBB(): FObb;
begin
  result:=_obb;
end;

function TOgfBone.Rename(name: string): boolean;
begin
  _name:=name;
  result:=true;
end;

function TOgfBone.UniformScale(k: single): boolean;
begin
  result:=false;
  if not Loaded() then exit;
  uniform_scale(_obb, k);
  result:=true;
end;

{ TOgfBonesContainer }

constructor TOgfBonesContainer.Create;
begin
  setlength(_bones, 0);
  _loaded:=false;
  Reset();
end;

destructor TOgfBonesContainer.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TOgfBonesContainer.Reset;
var
  i:integer;
begin
  for i:=0 to length(_bones)-1 do begin
    _bones[i].Free;
  end;
  setlength(_bones, 0);
  _loaded:=false;
end;

function TOgfBonesContainer.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfBonesContainer.Deserialize(rawdata: string): boolean;
var
  cnt, i, sz:integer;
  err:boolean;
begin
  result:=false;
  Reset;

  if length(rawdata) < sizeof(cnt) then exit;

  cnt:=pcardinal(@rawdata[1])^;
  setlength(_bones, cnt);
  if not AdvanceString(rawdata, sizeof(cnt)) then exit;

  err:=false;
  for i:=0 to cnt-1 do begin
    _bones[i]:=TOgfBone.Create();
    sz:=_bones[i].Deserialize(rawdata);
    if (sz<0) or not AdvanceString(rawdata, sz) then begin
       err:=true;
      break;
    end;
  end;
  if not err then begin
    _loaded:=true;
    result:=true;
  end;
end;

function TOgfBonesContainer.Serialize(): string;
var
  i:integer;
  bone_str:string;
begin
  result:='';
  if not Loaded() then exit;

  result:=result+SerializeCardinal(length(_bones));
  for i:=0 to length(_bones)-1 do begin
    bone_str:=_bones[i].Serialize();
    if length(bone_str) = 0 then begin
      result:='';
      exit;
    end;
    result:=result+bone_str;
  end;
end;

function TOgfBonesContainer.Count(): integer;
begin
  if Loaded() then begin
    result:=length(_bones);
  end else begin
    result:=0;
  end;
end;

function TOgfBonesContainer.Bone(i: integer): TOgfBone;
begin
  result:=nil;
  if not Loaded() or (i<0) or (i >= Count()) then exit;
  result:=_bones[i];
end;

function TOgfBonesContainer.UniformScale(k: single): boolean;
var
  i:integer;
begin
  result:=Loaded();
  if not result then exit;

  for i:=0 to length(_bones)-1 do begin
    result:=result and _bones[i].UniformScale(k);
    if not result then break;
  end;
end;

{ TOgfFacesContainer }

function TOgfTrisContainer.IsLodAssigned(): boolean;
begin
  result:=(_current_lod_params.num_verts > 0) and (_current_lod_params.num_tris > 0);
end;

function TOgfTrisContainer._GetTriangleIdByOffset(offset: integer): integer;
begin
  result:=offset*sizeof(TOgfVertexIndex);
  if result mod sizeof(TOgfTriangle) <> 0 then begin
    result:=-1;
  end else begin
    result:=result div sizeof(TOgfTriangle);
  end;
end;

constructor TOgfTrisContainer.Create;
begin
  Reset();
end;

destructor TOgfTrisContainer.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TOgfTrisContainer.Reset;
begin
  _current_lod_params.num_tris:=0;
  _current_lod_params.num_verts:=0;
  _current_lod_params.offset:=0;
  setlength(_tris, 0);
end;

function TOgfTrisContainer.Loaded(): boolean;
begin
  result:=length(_tris)>0;
end;

function TOgfTrisContainer.Deserialize(rawdata: string): boolean;
var
  total_components_count, total_data_size, tris_components_count:cardinal;
  tris_count:integer;
  i:integer;
begin
  result:=false;
  assert(sizeof(TOgfTriangle) mod sizeof(TOgfVertexIndex) = 0, 'Invalid Triangle declaration');

  Reset();
  if length(rawdata) < sizeof(total_components_count) then exit;
  total_components_count:=pcardinal(@rawdata[1])^;
  if total_components_count = 0 then exit;
  total_data_size:=sizeof(TOgfVertexIndex)*total_components_count;
  if cardinal(length(rawdata)) < sizeof(total_components_count) + total_data_size then exit;

  tris_components_count:=(sizeof(TOgfTriangle) div sizeof(TOgfVertexIndex));
  if total_components_count mod tris_components_count <> 0 then exit;
  tris_count:=total_components_count div tris_components_count;

  setlength(_tris, tris_count);
  for i:=0 to length(_tris)-1 do begin
    _tris[i]:=pTOgfTriangle(@rawdata[sizeof(tris_count)+i*sizeof(TOgfTriangle)+1])^
  end;
  result:=true;
end;

function TOgfTrisContainer.Serialize(): string;
var
  tris_components_count, total_components_count:cardinal;
  i:integer;
begin
  result:='';
  assert(sizeof(TOgfTriangle) mod sizeof(TOgfVertexIndex) = 0, 'Invalid Triangle declaration');

  if not Loaded() then exit;
  tris_components_count:=(sizeof(TOgfTriangle) div sizeof(TOgfVertexIndex));
  total_components_count:=tris_components_count*cardinal(length(_tris));

  result:=result+SerializeCardinal(total_components_count);
  for i:=0 to length(_tris)-1 do begin
    result:=result+SerializeWord(_tris[i].v1);
    result:=result+SerializeWord(_tris[i].v2);
    result:=result+SerializeWord(_tris[i].v3);
  end;
end;

function TOgfTrisContainer.AssignLod(params: TOgfSlideWindowItem): boolean;
var
  tri_id:integer;
begin
  result:=false;
  if not Loaded() then exit;
  tri_id:=_GetTriangleIdByOffset(params.offset);
  if (tri_id < 0) or (tri_id+params.num_tris > length(_tris)) then exit;
  _current_lod_params:=params;
  result:=true;
end;

function TOgfTrisContainer.AssignedLodParams(): TOgfSlideWindowItem;
begin
  result:=_current_lod_params;
end;

function TOgfTrisContainer.TrisCountTotal(): integer;
begin
  result:=length(_tris);
end;

function TOgfTrisContainer.TrisCountInCurrentLod(): integer;
begin
  if not Loaded() then begin
    result:=0;
  end else if IsLodAssigned() then begin
    result:=_current_lod_params.num_tris;
  end else begin
    result:=TrisCountTotal();
  end;
end;

function TOgfTrisContainer.FilterVertices(var filter: TVertexFilterItems): boolean;
var
  i, newi:integer;
begin
  result:=false;

  if not Loaded() then exit;

  // Filtering vertices is prohibited for models with SWR - we will need to edit all sliding windows
  if IsLodAssigned() then exit;

  newi:=0;
  for i:=0 to length(_tris)-1 do begin
    if not ((filter[_tris[i].v1].need_remove) or (filter[_tris[i].v2].need_remove) or (filter[_tris[i].v3].need_remove)) then begin
      _tris[newi].v1:=filter[_tris[i].v1].new_id;
      _tris[newi].v2:=filter[_tris[i].v2].new_id;
      _tris[newi].v3:=filter[_tris[i].v3].new_id;
      newi:=newi+1;
    end;
  end;
  setlength(_tris, newi);

  result:=true;
end;

{ TOgfSwiContainer }

constructor TOgfSwiContainer.Create;
begin
  Reset();
end;

destructor TOgfSwiContainer.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TOgfSwiContainer.Reset;
begin
  SetLength(_lods, 0);
  _selected_level:=0;
end;

function TOgfSwiContainer.Loaded(): boolean;
begin
  result:=length(_lods)>0;
end;

function TOgfSwiContainer.Deserialize(rawdata: string): boolean;
type TOgfSwiHeader = packed record
  reserved1:cardinal;
  reserved2:cardinal;
  reserved3:cardinal;
  reserved4:cardinal;
  lods_count:cardinal
end;
pTOgfSwiHeader = ^TOgfSwiHeader;
var
  phdr:pTOgfSwiHeader;
  i:integer;
begin
  result:=false;
  Reset();
  if length(rawdata) < sizeof(TOgfSwiHeader) then exit;
  phdr:=pTOgfSwiHeader(@rawdata[1]);
  if phdr^.lods_count = 0 then exit;
  if phdr^.lods_count * sizeof(TOgfSlideWindowItem) + sizeof(TOgfSwiHeader) > cardinal(length(rawdata)) then exit;
  setlength(_lods, phdr^.lods_count);
  for i:=0 to length(_lods)-1 do begin
    _lods[i]:=pTOgfSlideWindowItem(@rawdata[sizeof(TOgfSwiHeader) +i*sizeof(TOgfSlideWindowItem)+1])^;
  end;
  result:=true;
end;

function TOgfSwiContainer.Serialize(): string;
var
  i:integer;
begin
  result:='';
  if not Loaded() then exit;
  result:=result+SerializeCardinal(0);
  result:=result+SerializeCardinal(0);
  result:=result+SerializeCardinal(0);
  result:=result+SerializeCardinal(0);
  result:=result+SerializeCardinal(length(_lods));
  for i:=0 to length(_lods)-1 do begin
    result:=result+SerializeCardinal(_lods[i].offset);
    result:=result+SerializeWord(_lods[i].num_tris);
    result:=result+SerializeWord(_lods[i].num_verts);
  end;
end;

function TOgfSwiContainer.GetLodLevelsCount(): integer;
begin
  result:=length(_lods);
end;

function TOgfSwiContainer.SelectLodLevel(level_id: integer): boolean;
begin
  result:=false;
  if not Loaded() then exit;
  if level_id >= GetLodLevelsCount() then exit;
  _selected_level:=level_id;
  result:=true;
end;

function TOgfSwiContainer.GetSelectedLodLevel(): integer;
begin
  result:=_selected_level;
end;

function TOgfSwiContainer.GetLodLevelParams(level_id: integer): TOgfSlideWindowItem;
begin
  result.num_tris:=0;
  result.num_verts:=0;
  result.offset:=0;
  if not Loaded() then exit;
  if level_id < 0 then level_id := _selected_level;
  if level_id >= GetLodLevelsCount() then exit;
  result:=_lods[level_id];
end;

{ TVertexBones }

procedure TVertexBones.NormalizeWeights(except_bone_idx: integer);
var
  scaler:single;
  full_weights:single;
  i:integer;
begin
  if except_bone_idx >= length(_bones) then except_bone_idx:=-1;

  if (except_bone_idx >= 0) and (_bones[except_bone_idx].weight >= 1) then begin
    _bones[except_bone_idx].weight:=1;
    for i:=0 to length(_bones)-1 do begin
      if i <> except_bone_idx then begin
        _bones[i].weight:=0;
      end;
    end;
  end else begin
    full_weights:=0;
    for i:=0 to length(_bones)-1 do begin
      if (i = except_bone_idx) then continue;
      full_weights:=full_weights+_bones[i].weight;
    end;

    if except_bone_idx > 0 then begin
      scaler:=1-_bones[except_bone_idx].weight;
    end else begin
      scaler:=1;
    end;

    for i:=0 to length(_bones)-1 do begin
      if (i = except_bone_idx) or (_bones[i].weight = 0) then continue;
      _bones[i].weight := scaler * _bones[i].weight / full_weights;
    end;
  end;
end;

procedure TVertexBones._SortByWeights();
var
  i, j, maxi:integer;
  tmp:TVertexBone;
begin
  for i:=0 to length(_bones)-1 do begin
    maxi:=i;
    for j:=i+1 to length(_bones)-1 do begin
      if _bones[j].weight > _bones[maxi].weight then begin
        maxi:=j;
      end;
      tmp:=_bones[i];
      _bones[i]:=_bones[maxi];
      _bones[maxi]:=tmp;
    end;
  end;
end;

constructor TVertexBones.Create();
begin
  Reset();
end;

destructor TVertexBones.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TVertexBones.Reset();
begin
  setlength(_bones, 0);
end;


function TVertexBones.AddBone(bone: TVertexBone; normalize_weights: boolean): boolean;
var
  idx:integer;
begin
  idx:=length(_bones);
  setlength(_bones, idx+1);
  result:=SetBoneParams(idx, bone, normalize_weights);
end;

function TVertexBones.GetBoneParams(idx: integer): TVertexBone;
begin
  if idx >= length(_bones) then begin
    result.bone_id:=INVALID_BONE_ID;
    result.weight:=0;
  end else begin
    result:=_bones[idx];
  end;
end;

function TVertexBones.SetBoneParams(idx: integer; bone: TVertexBone; normalize_weights: boolean): boolean;
begin
  result:=false;
  if idx >= length(_bones) then exit;
  _bones[idx]:=bone;
  if normalize_weights then begin
    NormalizeWeights(idx);
  end;
  result:=true;
end;

function TVertexBones.GetWeightForBoneId(var bone: TVertexBone): boolean;
var
  i:integer;
begin
  result:=false;
  bone.weight:=0;
  for i:=0 to length(_bones)-1 do begin
    if _bones[i].bone_id = bone.bone_id then begin
      bone.weight:=bone.weight+_bones[i].weight;
    end;
  end;
end;

function TVertexBones.GetWeightForBoneId(bone_id: TBoneID): single;
var
  bone:TVertexBone;
begin
  bone.bone_id:=bone_id;
  bone.weight:=0;
  GetWeightForBoneId(bone);
  result:=bone.weight;
end;

function TVertexBones.TotalLinkedBonesCount(): integer;
begin
  result:=length(_bones);
end;

function TVertexBones.SimplifiedLinkedBonesCount(): integer;
var
  i,j:integer;
  excess_bones_count:cardinal;
begin
  excess_bones_count:=0;
  for i:=0 to length(_bones)-1 do begin
    if _bones[i].weight = 0 then begin
      excess_bones_count:=excess_bones_count+1;
      continue;
    end;

    for j:=0 to i-1 do begin
      if (_bones[i].bone_id = _bones[j].bone_id) and (_bones[j].weight > 0) then begin
        excess_bones_count:=excess_bones_count+1;
        break;
      end;
    end;
  end;

  result:=length(_bones) - excess_bones_count;
end;

procedure TVertexBones.SimplifyLinks();
var
  tmp_bones: array of TVertexBone;
  i, j, new_count:integer;
  skip:boolean;
begin
  if length(_bones) = 0 then exit;

  new_count:=0;
  setlength(tmp_bones{%H-}, length(_bones));

  for i:=0 to length(_bones)-1 do begin
    if _bones[i].weight = 0 then continue;
    skip:=false;

    for j:=0 to new_count-1 do begin
      if _bones[i].bone_id = tmp_bones[j].bone_id then begin
        tmp_bones[j].weight:=tmp_bones[j].weight+_bones[i].weight;
        skip:=true;
        break;
      end;
    end;

    if not skip then begin
      tmp_bones[new_count]:=_bones[i];
      new_count:=new_count+1;
    end;
  end;

  setlength(_bones, new_count);
  for i:=0 to new_count-1 do begin
    _bones[i]:=tmp_bones[i];
  end;

  setlength(tmp_bones, 0);
end;

function TVertexBones.ChangeLinkType(new_links_count: integer): boolean;
var
  b:TVertexBone;
begin
  result:=false;
  if new_links_count = length(_bones) then begin
    exit;
  end;

  SimplifyLinks();
  _SortByWeights();
  if new_links_count > length(_bones) then begin
    b.weight:=0;
    if length(_bones) > 0 then begin
      b.bone_id:=_bones[0].bone_id;
    end else begin
      b.bone_id:=0;
    end;

    while new_links_count <> length(_bones) do begin
      AddBone(b, false);
    end;
  end else if new_links_count < length(_bones) then begin
    SetLength(_bones, new_links_count);
    NormalizeWeights();
  end;

  result:=true;
end;

{ TOgfTextureDataContainer }

constructor TOgfTextureDataContainer.Create;
begin
  Reset();
end;

destructor TOgfTextureDataContainer.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TOgfTextureDataContainer.Reset;
begin
  _loaded:=false;
  _data.shader:='';
  _data.texture:='';
end;

function TOgfTextureDataContainer.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfTextureDataContainer.Deserialize(rawdata: string): boolean;
var
  i:integer;
  tex_name, shader_name:string;
begin
  result:=false;
  Reset();
  if not DeserializeZStringAndSplit(rawdata, tex_name) then exit;
  if not DeserializeZStringAndSplit(rawdata, shader_name) then exit;
  _data.texture:=tex_name;
  _data.shader:=shader_name;
  _loaded:=true;
  result:=true;
end;

function TOgfTextureDataContainer.Serialize(): string;
begin
  result:='';
  if not Loaded() then exit;
  result:=_data.texture+chr(0)+_data.shader+chr(0);
end;

function TOgfTextureDataContainer.GetTextureData(): TOgfTextureData;
begin
  result:=_data;
end;

function TOgfTextureDataContainer.SetTextureData(data: TOgfTextureData): boolean;
begin
  _loaded:=true;
  _data:=data;
  result:=true;
end;

{ TOgfChild }

constructor TOgfChild.Create;
begin
  _loaded:=false;
  _verts:=TOgfVertsContainer.Create();
  _texture:=TOgfTextureDataContainer.Create();
  _tris:=TOgfTrisContainer.Create();
  _swr:=TOgfSwiContainer.Create();
  Reset();
end;

destructor TOgfChild.Destroy;
begin
  Reset();
  FreeAndNil(_texture);
  FreeAndNil(_verts);
  FreeAndNil(_tris);
  FreeAndNil(_swr);
  inherited Destroy;
end;

procedure TOgfChild.Reset;
begin
  _loaded:=false;
  _verts.Reset;
  _texture.Reset;
  _tris.Reset;
  _swr.Reset;
end;

function TOgfChild.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfChild.Deserialize(rawdata: string): boolean;
var
  r:TChunkedMemory;
  offset:TChunkedOffset;
  tmp:string;
begin
  result:=false;
  Reset();
  r:=TChunkedMemory.Create();
  try
    r.LoadFromString(rawdata);

    // Parse header
    offset:=r.FindSubChunk(CHUNK_OGF_HEADER);
    if offset = INVALID_CHUNK then exit;
    if not r.EnterSubChunk(offset) then exit;
    tmp:=r.GetCurrentChunkRawDataAsString();
    if length(tmp)<>sizeof(TOgfHeader) then exit;
    _hdr:=pTOgfHeader(@tmp[1])^;
    if not r.LeaveSubChunk() then exit;

    // Parse texture
    offset:=r.FindSubChunk(CHUNK_OGF_TEXTURE);
    if offset = INVALID_CHUNK then exit;
    if not r.EnterSubChunk(offset) then exit;
    tmp:=r.GetCurrentChunkRawDataAsString();
    if not _texture.Deserialize(tmp) then exit;
    if not r.LeaveSubChunk() then exit;

    // Parse vertices
    offset:=r.FindSubChunk(CHUNK_OGF_VERTICES);
    if offset = INVALID_CHUNK then exit;
    if not r.EnterSubChunk(offset) then exit;
    tmp:=r.GetCurrentChunkRawDataAsString();
    if not _verts.Deserialize(tmp) then exit;
    if not r.LeaveSubChunk() then exit;

    // Parse faces
    offset:=r.FindSubChunk(CHUNK_OGF_INDICES);
    if offset = INVALID_CHUNK then exit;
    if not r.EnterSubChunk(offset) then exit;
    tmp:=r.GetCurrentChunkRawDataAsString();
    if not _tris.Deserialize(tmp) then exit;
    if not r.LeaveSubChunk() then exit;

    // Parse SWR if present
    offset:=r.FindSubChunk(CHUNK_OGF_SWIDATA);
    if offset <> INVALID_CHUNK then begin
      if not r.EnterSubChunk(offset) then exit;
      tmp:=r.GetCurrentChunkRawDataAsString();
      if not _swr.Deserialize(tmp) then exit;
      if not r.LeaveSubChunk() then exit;
      if not _swr.SelectLodLevel(0) then exit;
      if not _tris.AssignLod(_swr.GetLodLevelParams(0)) then exit;
    end;

    _loaded:=true;
    result:=true;
  finally
    FreeAndNil(r);
    if not result then Reset;
  end;
end;

function TOgfChild.Serialize(): string;
var
  tmpchr:PAnsiChar;
  tmpstr:string;
  i:integer;
begin
  result:='';
  if not Loaded() then exit;

  result:=result+SerializeChunkHeader(CHUNK_OGF_HEADER, sizeof(_hdr));
  tmpchr:=PAnsiChar(@_hdr);
  for i:=0 to sizeof(_hdr)-1 do begin
    result:=result+tmpchr[i];
  end;

  tmpstr:=_texture.Serialize();
  result:=result+SerializeChunkHeader(CHUNK_OGF_TEXTURE, length(tmpstr))+tmpstr;

  tmpstr:=_verts.Serialize();
  result:=result+SerializeChunkHeader(CHUNK_OGF_VERTICES, length(tmpstr))+tmpstr;

  tmpstr:=_tris.Serialize();
  result:=result+SerializeChunkHeader(CHUNK_OGF_INDICES, length(tmpstr))+tmpstr;

  if _swr.Loaded() then begin
    tmpstr:=_swr.Serialize();
    result:=result+SerializeChunkHeader(CHUNK_OGF_SWIDATA, length(tmpstr))+tmpstr;
  end;
end;

function TOgfChild.GetTextureData(): TOgfTextureData;
begin
  result.shader:='';
  result.texture:='';
  if not Loaded() then exit;
  result:=_texture.GetTextureData();
end;

function TOgfChild.SetTextureData(data: TOgfTextureData): boolean;
begin
  result:=false;
  if not Loaded() then exit;
  result:=_texture.SetTextureData(data);
end;

function TOgfChild.GetCurrentLinkType(): cardinal;
begin
  if not Loaded() then begin
    result:=OGF_LINK_TYPE_INVALID;
  end else begin
    result:=_verts.GetCurrentLinkType();
  end;
end;

function TOgfChild.GetVerticesCount(): cardinal;
begin
  if not Loaded() then begin
    result:=0;
  end else begin
    result:=_verts.GetVerticesCount();
  end;
end;

function TOgfChild.GetTrisCountInCurrentLod(): cardinal;
begin
  if not Loaded() then begin
    result:=0;
  end else begin
    result:=_tris.TrisCountInCurrentLod();
  end;
end;

function TOgfChild.GetTrisCountTotal(): cardinal;
begin
  if not Loaded() then begin
    result:=0;
  end else begin
    result:=_tris.TrisCountTotal();
  end;
end;

function TOgfChild.CalculateOptimalLinkType(): cardinal;
begin
  if not Loaded() then begin
    result:=OGF_LINK_TYPE_INVALID;
  end else begin
    result:=_verts.CalculateOptimalLinkType();
  end;
end;

function TOgfChild.ChangeLinkType(new_link_type: cardinal): boolean;
begin
  if not Loaded() then begin
    result:=false;
  end else begin
    result:=_verts.ChangeLinkType(new_link_type);
  end;
end;

function TOgfChild.RebindVertices(target_boneid: TBoneID; source_boneid: TBoneID): boolean;
begin
  result:=_verts.RebindVerticesToNewBone(target_boneid, source_boneid);
end;

function TOgfChild.GetVerticesCountForBoneId(boneid: TBoneID): integer;
begin
  result:=_verts.GetVerticesCountForBoneID(boneid, true);
end;

function TOgfChild.FilterVertices(var filter: TVertexFilterItems): boolean;
begin
  result:=false;

  if not Loaded() then exit;

  // TODO: remove all SWR LODS before filtering
  if (_swr.GetLodLevelsCount()>0) then exit;

  if not _verts.FilterVertices(filter) then exit;
  if not _tris.FilterVertices(filter) then exit;

  result:=true;
end;

function TOgfChild.RemoveVerticesForBoneId(boneid: TBoneID; remove_all_except_selected: boolean): boolean;
var
  filter:TVertexFilterItems;
  i:integer;
begin
  result:=false;
  if not Loaded() or (_verts.GetVerticesCount() = 0) then exit;

  filter:=nil;
  try
    setlength(filter, _verts.GetVerticesCount());
    for i:=0 to _verts.GetVerticesCount()-1 do begin
      if remove_all_except_selected then begin
        filter[i].need_remove:=not _verts.IsVertexAssignedToBoneID(i, boneid, true);
      end else begin
        filter[i].need_remove:=_verts.IsVertexAssignedToBoneID(i, boneid, true);
      end;
    end;

    result:=FilterVertices(filter);
  finally
    setlength(filter, 0);
  end;
end;

function TOgfChild.Scale(v: FVector3): boolean;
begin
  if not Loaded() then begin
    result:=false;
  end else begin
    result:=_verts.ScaleVertices(v);
  end;
end;

function TOgfChild.Move(v: FVector3): boolean;
begin
  if not Loaded() then begin
    result:=false;
  end else begin
    result:=_verts.MoveVertices(v);
  end;
end;

{ TOgfVertsContainer }
type
TOgfVertsHeader = packed record
  link_type:cardinal;
  count:cardinal;
end;
pTOgfVertsHeader = ^TOgfVertsHeader;

function TOgfVertsContainer._GetVertexDataPtr(id: cardinal): pTOgfVertexCommonData;
var
  pos:cardinal;
  pvert1link:pTOgfVertex1link;
  pvert2link:pTOgfVertex2link;
  pvert3link:pTOgfVertex3link;
  pvert4link:pTOgfVertex4link;
begin
  result:=nil;
  if not Loaded() then exit;
  if id >= _verts_count then exit;

  if _link_type = OGF_LINK_TYPE_1 then begin
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex1link);
    pvert1link:=@_raw_data[pos];
    result:=@pvert1link^.spatial;
  end else if _link_type = OGF_LINK_TYPE_2 then begin
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex2link);
    pvert2link:=@_raw_data[pos];
    result:=@pvert2link^.spatial;
  end else if _link_type = OGF_LINK_TYPE_3 then begin
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex3link);
    pvert3link:=@_raw_data[pos];
    result:=@pvert3link^.spatial;
  end else if _link_type = OGF_LINK_TYPE_4 then begin
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex4link);
    pvert4link:=@_raw_data[pos];
    result:=@pvert4link^.spatial;
  end;
end;

function TOgfVertsContainer._GetVertexUvDataPtr(id: cardinal): pFVector2;
var
  pos:cardinal;
  pvert1link:pTOgfVertex1link;
  pvert2link:pTOgfVertex2link;
  pvert3link:pTOgfVertex3link;
  pvert4link:pTOgfVertex4link;
begin
  result:=nil;
  if not Loaded() then exit;
  if id >= _verts_count then exit;

  if _link_type = OGF_LINK_TYPE_1 then begin
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex1link);
    pvert1link:=@_raw_data[pos];
    result:=@pvert1link^.uv;
  end else if _link_type = OGF_LINK_TYPE_2 then begin
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex2link);
    pvert2link:=@_raw_data[pos];
    result:=@pvert2link^.uv;
  end else if _link_type = OGF_LINK_TYPE_3 then begin
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex3link);
    pvert3link:=@_raw_data[pos];
    result:=@pvert3link^.uv;
  end else if _link_type = OGF_LINK_TYPE_4 then begin
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex4link);
    pvert4link:=@_raw_data[pos];
    result:=@pvert4link^.uv;
  end;
end;

function TOgfVertsContainer._GetVertexBindings(id: cardinal; bindings_out: TVertexBones): boolean;
var
  pos:cardinal;
  pvert1link:pTOgfVertex1link;
  pvert2link:pTOgfVertex2link;
  pvert3link:pTOgfVertex3link;
  pvert4link:pTOgfVertex4link;
  bone:TVertexBone;
  i:integer;
  w_total:single;
begin
  result:=false;
  if not Loaded() then exit;
  if id >= _verts_count then exit;

  if _link_type = OGF_LINK_TYPE_1 then begin
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex1link);
    pvert1link:=@_raw_data[pos];
    bindings_out.Reset();

    bone.bone_id:=pvert1link^.bone_id;
    bone.weight:=1.0;
    bindings_out.AddBone(bone, false);

    result:=true;
  end else if _link_type = OGF_LINK_TYPE_2 then begin
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex2link);
    pvert2link:=@_raw_data[pos];
    bindings_out.Reset();

    bone.bone_id:=pvert2link^.bone0;
    bone.weight:=1 - pvert2link^.weight1;
    bindings_out.AddBone(bone, false);

    bone.bone_id:=pvert2link^.bone1;
    bone.weight:=pvert2link^.weight1;
    bindings_out.AddBone(bone, false);

    result:=true;
  end else if _link_type = OGF_LINK_TYPE_3 then begin
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex3link);
    pvert3link:=@_raw_data[pos];
    w_total:=0;
    bindings_out.Reset();
    for i:=0 to length(pvert3link^.bones)-1 do begin
      bone.bone_id:=pvert3link^.bones[i];
      if i<length(pvert3link^.weights) then begin
        bone.weight:=pvert3link^.weights[i];
        w_total:=w_total+bone.weight;
      end else begin
        bone.weight:=1-w_total;
        if bone.weight < 0 then bone.weight:=0;
      end;
      bindings_out.AddBone(bone, false);
    end;
    result:=true;
  end else if _link_type = OGF_LINK_TYPE_4 then begin
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex4link);
    pvert4link:=@_raw_data[pos];
    w_total:=0;
    bindings_out.Reset();
    for i:=0 to length(pvert4link^.bones)-1 do begin
      bone.bone_id:=pvert4link^.bones[i];
      if i<length(pvert4link^.weights) then begin
        bone.weight:=pvert4link^.weights[i];
        w_total:=w_total+bone.weight;
      end else begin
        bone.weight:=1-w_total;
        if bone.weight < 0 then bone.weight:=0;
      end;
      bindings_out.AddBone(bone, false);
    end;
    result:=true;
  end;
end;

function TOgfVertsContainer._SetVertexBindings(id: cardinal; bindings_in: TVertexBones): boolean;
var
  pos:cardinal;
  i:integer;
  bone:TVertexBone;
  pvert1link:pTOgfVertex1link;
  pvert2link:pTOgfVertex2link;
  pvert3link:pTOgfVertex3link;
  pvert4link:pTOgfVertex4link;
begin
  result:=false;
  if not Loaded() then exit;
  if id >= _verts_count then exit;
  if cardinal(bindings_in.TotalLinkedBonesCount())<>_link_type then exit;

  if _link_type = OGF_LINK_TYPE_1 then begin
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex1link);
    pvert1link:=@_raw_data[pos];
    pvert1link^.bone_id:=bindings_in.GetBoneParams(0).bone_id;
    result:=true;
  end else if _link_type = OGF_LINK_TYPE_2 then begin
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex2link);
    pvert2link:=@_raw_data[pos];
    bone:=bindings_in.GetBoneParams(0);
    pvert2link^.bone0:=bone.bone_id;
    bone:=bindings_in.GetBoneParams(1);
    pvert2link^.bone1:=bone.bone_id;
    pvert2link^.weight1:=bone.weight;
    result:=true;
  end else if _link_type = OGF_LINK_TYPE_3 then begin
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex3link);
    pvert3link:=@_raw_data[pos];
    for i:=0 to bindings_in.TotalLinkedBonesCount()-1 do begin
      bone:=bindings_in.GetBoneParams(i);
      pvert3link^.bones[i]:=bone.bone_id;
      if i<length(pvert3link^.weights) then begin
        pvert3link^.weights[i]:=bone.weight;
      end;
    end;
    result:=true;
  end else if _link_type = OGF_LINK_TYPE_4 then begin
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex4link);
    pvert4link:=@_raw_data[pos];
    for i:=0 to bindings_in.TotalLinkedBonesCount()-1 do begin
      bone:=bindings_in.GetBoneParams(i);
      pvert4link^.bones[i]:=bone.bone_id;
      if i<length(pvert4link^.weights) then begin
        pvert4link^.weights[i]:=bone.weight;
      end;
    end;
    result:=true;
  end;
end;

procedure TOgfVertsContainer.Reset;
begin
  _link_type:=OGF_LINK_TYPE_INVALID;
  setlength(_raw_data, 0);
  _verts_count:=0;
end;

constructor TOgfVertsContainer.Create;
begin
  Reset();
end;

destructor TOgfVertsContainer.Destroy;
begin
  Reset();
  inherited Destroy;
end;

function TOgfVertsContainer.Loaded(): boolean;
begin
  result:=_link_type<>OGF_LINK_TYPE_INVALID;
end;

function TOgfVertsContainer.Serialize(): string;
var
  i:integer;
begin
  result:='';
  if not Loaded() then exit;

  for i:=0 to length(_raw_data)-1 do begin
    result:=result+chr(_raw_data[i]);
  end;
end;

function TOgfVertsContainer.MoveVertices(offset: FVector3): boolean;
var
  i:integer;
  v:pTOgfVertexCommonData;
begin
  result:=false;
  if not Loaded() then exit;

  result:=true;
  for i:=0 to _verts_count-1 do begin
    v:=_GetVertexDataPtr(i);
    if v = nil then begin
      result:=false;
      break;
    end;
    v^.pos.x:=v^.pos.x+offset.x;
    v^.pos.y:=v^.pos.y+offset.y;
    v^.pos.z:=v^.pos.z+offset.z;
  end;
end;

function TOgfVertsContainer.ScaleVertices(factors:FVector3): boolean;
var
  i:integer;
  v:pTOgfVertexCommonData;
begin
  result:=false;
  if not Loaded() then exit;

  result:=true;
  for i:=0 to _verts_count-1 do begin
    v:=_GetVertexDataPtr(i);
    if v = nil then begin
      result:=false;
      break;
    end;
    v^.pos.x:=v^.pos.x*factors.x;
    v^.pos.y:=v^.pos.y*factors.y;
    v^.pos.z:=v^.pos.z*factors.z;
  end;
end;

function TOgfVertsContainer.RebindVerticesToNewBone(new_bone_index: TBoneID; old_bone_index: TBoneID): boolean;
var
  i, j:integer;
  b:TVertexBones;
  bone:TVertexBone;
begin
  result:=false;
  if not Loaded() then exit;

  b:=TVertexBones.Create();
  try
    if old_bone_index = INVALID_BONE_ID then begin
      if (GetCurrentLinkType()<>OGF_LINK_TYPE_1) and not ChangeLinkType(OGF_LINK_TYPE_1) then exit;

      bone.bone_id:=new_bone_index;
      bone.weight:=1;
      b.AddBone(bone, false);
    end;

    for i:=0 to _verts_count-1 do begin
      if old_bone_index <> INVALID_BONE_ID then begin
        if not _GetVertexBindings(i, b) then exit;
        for j:=0 to b.TotalLinkedBonesCount()-1 do begin
          bone:=b.GetBoneParams(j);
          if bone.bone_id = old_bone_index then begin
            bone.bone_id:=new_bone_index;
            if not b.SetBoneParams(j, bone, false) then exit;
          end;
        end;
      end;
      if not _SetVertexBindings(i, b) then exit;
    end;
    result:=true;
  finally
    FreeAndNil(b);
  end;
end;

function TOgfVertsContainer.GetVerticesCountForBoneID(boneid: TBoneID; ignorezeroweights: boolean): integer;
var
  i,j:integer;
  b:TVertexBones;
  bone:TVertexBone;
begin
  result:=0;
  if not Loaded() then exit;
  if boneid = INVALID_BONE_ID then begin
    result:=_verts_count;
    exit;
  end;

  b:=TVertexBones.Create();
  try
    for i:=0 to _verts_count-1 do begin
      if not _GetVertexBindings(i, b) then continue;
      for j:=0 to b.TotalLinkedBonesCount()-1 do begin
        bone:=b.GetBoneParams(j);
        if (bone.bone_id = boneid) and (not ignorezeroweights or (bone.weight > 0)) then begin
          result:=result+1;
          break;
        end;
      end;
    end;

  finally
    FreeAndNil(b);
  end;
end;

function TOgfVertsContainer.IsVertexAssignedToBoneID(vertexid: cardinal; boneid: TBoneID; ignorezeroweights: boolean): boolean;
var
  i:integer;
  b:TVertexBones;
  bone:TVertexBone;
begin
  result:=false;
  if not Loaded() or (vertexid >= _verts_count) then exit;
  if (boneid = INVALID_BONE_ID) then exit;

  b:=TVertexBones.Create();
  try
    if _GetVertexBindings(vertexid, b) then begin
      for i:=0 to b.TotalLinkedBonesCount()-1 do begin
        bone:=b.GetBoneParams(i);
        if (bone.bone_id = boneid) and (not ignorezeroweights or (bone.weight > 0)) then begin
          result:=true;
          break;
        end;
      end;
    end;
  finally
    FreeAndNil(b);
  end;
end;

function TOgfVertsContainer.GetCurrentLinkType(): cardinal;
begin
  result:=_link_type;
end;

function TOgfVertsContainer.GetVerticesCount(): cardinal;
begin
  if Loaded() then begin
    result:=_verts_count;
  end else begin
    result:=0;
  end;
end;

function TOgfVertsContainer.CalculateOptimalLinkType(): cardinal;
var
  i:cardinal;
  links:integer;
  b:TVertexBones;
begin
  result:=OGF_LINK_TYPE_INVALID;
  if not Loaded() then exit;
  if _verts_count = 0 then exit;

  result:=OGF_LINK_TYPE_1;
  b:=TVertexBones.Create();
  try
    for i:=0 to _verts_count-1 do begin
      if _GetVertexBindings(i, b) then begin
        links:=b.SimplifiedLinkedBonesCount();
        if cardinal(links) > result then result:=links;
      end;
    end;
  finally
    FreeAndNil(b);
  end;
end;

function TOgfVertsContainer.ChangeLinkType(new_link_type: cardinal): boolean;
var
  b:TVertexBones;
  new_data:array of byte;
  phdr:pTOgfVertsHeader;
  bone:TVertexBone;
  pvert1link:pTOgfVertex1link;
  pvert2link:pTOgfVertex2link;
  pvert3link:pTOgfVertex3link;
  pvert4link:pTOgfVertex4link;
  i,j:integer;
  v_common:pTOgfVertexCommonData;
  v_uv:pFVector2;
begin
  result:=false;

  if not Loaded() then exit;
  if _verts_count = 0 then exit;
  if new_link_type = _link_type then exit;

  b:=TVertexBones.Create();
  setlength(new_data{%H-}, 0);
  try
    if new_link_type = OGF_LINK_TYPE_1 then begin
      setlength(new_data, sizeof(TOgfVertsHeader)+sizeof(TOgfVertex1link)*_verts_count);
      pvert1link:=@new_data[sizeof(TOgfVertsHeader)];
      for i:=0 to _verts_count-1 do begin
        v_common:=_GetVertexDataPtr(i);
        v_uv:=_GetVertexUvDataPtr(i);
        if (v_common = nil) or (v_uv = nil) then exit;
        if not _GetVertexBindings(i, b) then exit;
        if not b.ChangeLinkType(new_link_type) then exit;
        pvert1link[i].spatial:=v_common^;
        pvert1link[i].uv:=v_uv^;

        pvert1link[i].bone_id:=b.GetBoneParams(0).bone_id;
      end;
    end else if new_link_type = OGF_LINK_TYPE_2 then begin
      setlength(new_data, sizeof(TOgfVertsHeader)+sizeof(TOgfVertex2link)*_verts_count);
      pvert2link:=@new_data[sizeof(TOgfVertsHeader)];
      for i:=0 to _verts_count-1 do begin
        v_common:=_GetVertexDataPtr(i);
        v_uv:=_GetVertexUvDataPtr(i);
        if (v_common = nil) or (v_uv = nil) then exit;
        if not _GetVertexBindings(i, b) then exit;
        if not b.ChangeLinkType(new_link_type) then exit;
        pvert2link[i].spatial:=v_common^;
        pvert2link[i].uv:=v_uv^;

        pvert2link[i].bone0:=b.GetBoneParams(0).bone_id;
        pvert2link[i].bone1:=b.GetBoneParams(1).bone_id;
        pvert2link[i].weight1:=b.GetBoneParams(1).weight;
      end;
    end else if new_link_type = OGF_LINK_TYPE_3 then begin
      setlength(new_data, sizeof(TOgfVertsHeader)+sizeof(TOgfVertex3link)*_verts_count);
      pvert3link:=@new_data[sizeof(TOgfVertsHeader)];
      for i:=0 to _verts_count-1 do begin
        v_common:=_GetVertexDataPtr(i);
        v_uv:=_GetVertexUvDataPtr(i);
        if (v_common = nil) or (v_uv = nil) then exit;
        if not _GetVertexBindings(i, b) then exit;
        if not b.ChangeLinkType(new_link_type) then exit;
        pvert3link[i].spatial:=v_common^;
        pvert3link[i].uv:=v_uv^;

        for j:=0 to new_link_type-1 do begin
          pvert3link[i].bones[j]:=b.GetBoneParams(j).bone_id;
          if j<new_link_type-1 then begin
            pvert3link[i].weights[j]:=b.GetBoneParams(j).weight;
          end;
        end;
      end;
    end else if new_link_type = OGF_LINK_TYPE_4 then begin
      setlength(new_data, sizeof(TOgfVertsHeader)+sizeof(TOgfVertex4link)*_verts_count);
      pvert4link:=@new_data[sizeof(TOgfVertsHeader)];
      for i:=0 to _verts_count-1 do begin
        v_common:=_GetVertexDataPtr(i);
        v_uv:=_GetVertexUvDataPtr(i);
        if (v_common = nil) or (v_uv = nil) then exit;
        if not _GetVertexBindings(i, b) then exit;
        if not b.ChangeLinkType(new_link_type) then exit;
        pvert4link[i].spatial:=v_common^;
        pvert4link[i].uv:=v_uv^;

        for j:=0 to new_link_type-1 do begin
          pvert4link[i].bones[j]:=b.GetBoneParams(j).bone_id;
          if j<new_link_type-1 then begin
            pvert4link[i].weights[j]:=b.GetBoneParams(j).weight;
          end;
        end;
      end;
    end;

    if length(new_data) > 0 then begin
      // Update header
      phdr:=@new_data[0];
      phdr^.count:=_verts_count;
      phdr^.link_type:=new_link_type;
      // replace with new data
      setlength(_raw_data, length(new_data));
      Move(new_data[0], _raw_data[0], length(new_data));
      _link_type:=new_link_type;
      result:=true;
    end;
  finally
    setlength(new_data, 0);
    FreeAndNil(b);
  end;
end;

function TOgfVertsContainer.FilterVertices(var filter: TVertexFilterItems): boolean;
var
  i, cursor, links, newcount:cardinal;
  new_data:array of byte;
  pvertex:pbyte;
  sz:cardinal;
  h:TOgfVertsHeader;
begin
  result:=false;
  if not Loaded() or (_verts_count=0) or (cardinal(length(filter)) <> _verts_count) then exit;

  links:=GetCurrentLinkType();
  if (links<>OGF_LINK_TYPE_1) and (links<>OGF_LINK_TYPE_2) and (links<>OGF_LINK_TYPE_3) and (links<>OGF_LINK_TYPE_4) then exit;

  new_data:=nil;
  setlength(new_data, length(_raw_data));
  h:=pTOgfVertsHeader(@_raw_data[0])^;
  cursor:=sizeof(TOgfVertsHeader);
  newcount:=0;
  for i:=0 to _verts_count-1 do begin
    if not filter[i].need_remove then begin
      if (links=OGF_LINK_TYPE_1) then begin
        pvertex:=@_raw_data[sizeof(TOgfVertsHeader)+i*sizeof(TOgfVertex1link)];
        sz:=sizeof(TOgfVertex1link);
      end else if (links=OGF_LINK_TYPE_2) then begin
        pvertex:=@_raw_data[sizeof(TOgfVertsHeader)+i*sizeof(TOgfVertex2link)];
        sz:=sizeof(TOgfVertex2link);
      end else if (links=OGF_LINK_TYPE_3) then begin
        pvertex:=@_raw_data[sizeof(TOgfVertsHeader)+i*sizeof(TOgfVertex3link)];
        sz:=sizeof(TOgfVertex3link);
      end else if (links=OGF_LINK_TYPE_4) then begin
        pvertex:=@_raw_data[sizeof(TOgfVertsHeader)+i*sizeof(TOgfVertex4link)];
        sz:=sizeof(TOgfVertex4link);
      end;

      Move(pvertex^, new_data[cursor], sz);
      cursor:=cursor+sz;
      filter[i].new_id:=newcount;
      newcount:=newcount+1;
    end else begin
      filter[i].new_id:=$FFFFFFFF;
    end;
  end;
  h.count:=newcount;
  pTOgfVertsHeader(@new_data[0])^:=h;
  Move(new_data[0], _raw_data[0], cursor);
  setlength(_raw_data, cursor);
  _verts_count:=newcount;

  setlength(new_data, 0);
  result:=true;
end;

function TOgfVertsContainer.Deserialize(rawdata: string): boolean;
var
  phdr:pTOgfVertsHeader;
  i:integer;
  raw_data_sz:cardinal;
begin
  result:=false;
  Reset();
  raw_data_sz:=length(rawdata);
  if raw_data_sz < sizeof(TOgfVertsHeader) then exit;
  phdr:=@rawdata[1];
  if phdr^.count = 0 then exit;

  if (phdr^.link_type = OGF_LINK_TYPE_1) or (phdr^.link_type = OGF_VERTEXFORMAT_FVF_1L) then begin
    if sizeof(TOgfVertsHeader) + phdr^.count*sizeof(TOgfVertex1link) <> raw_data_sz then exit;
    _link_type:=OGF_LINK_TYPE_1;
  end else if (phdr^.link_type = OGF_LINK_TYPE_2) or (phdr^.link_type = OGF_VERTEXFORMAT_FVF_2L) then begin
    if sizeof(TOgfVertsHeader) + phdr^.count*sizeof(TOgfVertex2link) <> raw_data_sz then exit;
    _link_type:=OGF_LINK_TYPE_2;
  end else if (phdr^.link_type = OGF_LINK_TYPE_3) or (phdr^.link_type = OGF_VERTEXFORMAT_FVF_3L) then begin
    if sizeof(TOgfVertsHeader) + phdr^.count*sizeof(TOgfVertex3link) <> raw_data_sz then exit;
    _link_type:=OGF_LINK_TYPE_3;
  end else if (phdr^.link_type = OGF_LINK_TYPE_4) or (phdr^.link_type = OGF_VERTEXFORMAT_FVF_4L) then begin
    if sizeof(TOgfVertsHeader) + phdr^.count*sizeof(TOgfVertex4link) <> raw_data_sz then exit;
    _link_type:=OGF_LINK_TYPE_4;
  end else begin
    exit;
  end;

  _verts_count:=phdr^.count;
  setlength(_raw_data, length(rawdata));
  for i:=1 to length(rawdata) do begin
    _raw_data[i-1]:=byte(rawdata[i]);
  end;
  result:=true;
end;


{ TOgfAnimationsParser }

constructor TOgfAnimationsParser.Create;
begin
  _loaded:=false;
  _original_data:='';
  _tracks:=TOgfMotionTracksContainer.Create();
  _params:=TOgfMotionParamsContainer.Create();
  Reset();
end;

destructor TOgfAnimationsParser.Destroy;
begin
  Reset();
  _params.Free();
  _tracks.Free();
  inherited Destroy;
end;

procedure TOgfAnimationsParser.Reset;
begin
  _loaded:=false;
  _original_data:='';
  _tracks.Reset();
  _params.Reset();
end;

function TOgfAnimationsParser.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfAnimationsParser.Deserialize(rawdata: string): boolean;
begin

end;

function TOgfAnimationsParser.Serialize(): string;
begin

end;

procedure TOgfAnimationsParser.Sanitize();
begin
  // compare count of animations in tracks and defs, correct if needed
  // compare animation names in tracks and defs, correct (using values from defs)
  // check if bone count & names corresponds with bones in the model
  // check bones indices in anims
end;

{ TOgfParser }

constructor TOgfParser.Create;
begin
  _loaded:=false;
  _original_data:='';

  _children:=TOgfChildrenContainer.Create();
  _bone_names:=TOgfBonesContainer.Create();
  _ikdata:=TOgfBonesIKDataContainer.Create();
  _userdata:=TOgfUserdataContainer.Create();
  _lodref:=TOgfLodRefsContainer.Create();

  _skeleton:=TOgfSkeleton.Create();

  Reset();
end;

destructor TOgfParser.Destroy;
begin
  Reset();
  _skeleton.Free();
  _children.Free();
  _bone_names.Free();
  _ikdata.Free();
  _userdata.Free();
  _lodref.Free();

  inherited Destroy;
end;

procedure TOgfParser.Reset;
begin
  _loaded:=false;
  _original_data:='';

  _children.Reset();
  _bone_names.Reset();
  _ikdata.Reset();
  _userdata.Reset();
  _lodref.Reset();
end;

function TOgfParser.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfParser.Deserialize(rawdata: string): boolean;
var
  mem:TChunkedMemory;
  chunk:TChunkedOffset;
  r:boolean;
begin
  result:=false;
  Reset();

  mem:=TChunkedMemory.Create();
  mem.LoadFromString(rawdata);
  try
    while true do begin
      chunk:=mem.FindSubChunk(CHUNK_OGF_CHILDREN);
      if (chunk = INVALID_CHUNK) or not mem.EnterSubChunk(chunk) then break;
      r:=_children.Deserialize(mem.GetCurrentChunkRawDataAsString());
      mem.LeaveSubChunk();
      if not r then break;

      chunk:=mem.FindSubChunk(CHUNK_OGF_S_BONE_NAMES);
      if (chunk = INVALID_CHUNK) or not mem.EnterSubChunk(chunk) then break;
      r:=_bone_names.Deserialize(mem.GetCurrentChunkRawDataAsString());
      mem.LeaveSubChunk();
      if not r then break;

      chunk:=mem.FindSubChunk(CHUNK_OGF_S_IKDATA);
      if (chunk = INVALID_CHUNK) or not mem.EnterSubChunk(chunk) then break;
      r:=_ikdata.Deserialize(mem.GetCurrentChunkRawDataAsString());
      mem.LeaveSubChunk();
      if not r then break;

      chunk:=mem.FindSubChunk(CHUNK_OGF_S_USERDATA);
      if (chunk <> INVALID_CHUNK) and mem.EnterSubChunk(chunk) then begin;
        r:=_userdata.Deserialize(mem.GetCurrentChunkRawDataAsString());
        mem.LeaveSubChunk();
        if not r then break;
      end;

      chunk:=mem.FindSubChunk(CHUNK_OGF_S_LODS);
      if (chunk <> INVALID_CHUNK) and mem.EnterSubChunk(chunk) then begin
        r:=_lodref.Deserialize(mem.GetCurrentChunkRawDataAsString());
        mem.LeaveSubChunk();
        if not r then break;
      end;

      if not _skeleton.Build(_bone_names, _ikdata) then exit;

      _original_data:=rawdata;
      result:=true;
      break;
    end;

  finally
    mem.Free;
  end;

  if result then begin
    _loaded:=true;
  end else begin
    Reset;
  end;
end;

function TOgfParser.Serialize(): string;
begin
  result:='';
  if not Loaded() then exit;
  if not UpdateOriginal() then exit;
  result:=_original_data;
end;

function TOgfParser.LoadFromFile(fname: string): boolean;
var
  mem:TChunkedMemory;
begin
  result:=false;
  mem:=TChunkedMemory.Create();
  try
    if not mem.LoadFromFile(fname, 0) then exit;
    result:=Deserialize(mem.GetCurrentChunkRawDataAsString());
  finally
    mem.Free;
  end;
end;

function TOgfParser.SaveToFile(fname: string): boolean;
var
  data:string;
  f:THandle;
begin
  result:=false;
  if not Loaded() then exit;

  data:=Serialize();
  if length(data) = 0 then exit;

  f:=FileCreate(fname, fmOpenReadWrite);
  if f = THandle(-1) then exit;

  try
    if length(data) = FileWrite(f, data[1], length(data)) then begin;
      result:=true
    end;
  finally
    FileClose(f);
  end;
end;

function TOgfParser.LoadFromMem(addr: pointer; sz: cardinal): boolean;
var
  s:string;
  i:integer;
begin
  result:=false;
  if sz = 0 then exit;

  s:='';
  for i:=0 to sz-1 do begin
    s:=s+PAnsiChar(addr)[i];
  end;
  result:=Deserialize(s);
end;

function TOgfParser.ReloadOriginal(): boolean;
begin
  result:=false;
  if not Loaded then exit;
  result:=Deserialize(_original_data);
end;

function TOgfParser._UpdateChunk(id: word; data: string): boolean;
var
  chunk:TChunkedOffset;
  mem:TChunkedMemory;
begin
  result:=false;
  mem:=TChunkedMemory.Create;
  try
    if not mem.LoadFromString(_original_data) then exit;
    chunk:=mem.FindSubChunk(id);
    if (chunk=INVALID_CHUNK) or (not mem.EnterSubChunk(chunk)) then begin
      result:=(length(data)=0);
    end else begin
      if mem.ReplaceCurrentRawDataWithString(data) and mem.LeaveSubChunk() then begin
        _original_data:=mem.GetCurrentChunkRawDataAsString();
        result:=true;
      end;
    end;
  finally
    mem.Free;
  end;
end;

function TOgfParser.UpdateOriginal(): boolean;
var
  children:string;
  bone_names:string;
  ikdata:string;
  userdata:string;
  lodref:string;
begin
  result:=false;
  if not Loaded() then exit;

  children:=_children.Serialize();
  bone_names:=_bone_names.Serialize();
  ikdata:=_ikdata.Serialize();
  userdata:=_userdata.Serialize();
  lodref:=_lodref.Serialize();

  if not _UpdateChunk(CHUNK_OGF_CHILDREN, children) then exit;
  if not _UpdateChunk(CHUNK_OGF_S_BONE_NAMES, bone_names) then exit;
  if not _UpdateChunk(CHUNK_OGF_S_IKDATA, ikdata) then exit;
  if not _UpdateChunk(CHUNK_OGF_S_USERDATA, userdata) then exit;
  if not _UpdateChunk(CHUNK_OGF_S_LODS, lodref) then exit;

  result:=true;

end;

function TOgfParser.Meshes(): TOgfChildrenContainer;
begin
  result:=nil;
  if not Loaded() then exit;

  result:=_children;
end;

function TOgfParser.Skeleton(): TOgfSkeleton;
begin
  result:=nil;
  if not Loaded() then exit;

  result:=_skeleton;
end;


end.


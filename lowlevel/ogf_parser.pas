unit ogf_parser;

{$mode objfpc}{$H+}

interface

uses
  ChunkedFileParser, basedefs;

type
  TBoneID = word;
  pTBoneID = ^TBoneID;

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

  TMotionKey = packed record
    Q:Fquaternion;
    T:FVector3;
  end;

  TOgfMotionKeyQR = packed record
    x:smallint;
    y:smallint;
    z:smallint;
    w:smallint;
  end;
  pTOgfMotionKeyQR = ^TOgfMotionKeyQR;

  TOgfMotionKeyQT8 = packed record
    x1:shortint;
    y1:shortint;
    z1:shortint;
  end;
  pTOgfMotionKeyQT8 = ^TOgfMotionKeyQT8;

  TOgfMotionKeyQT16 = packed record
    x1:smallint;
    y1:smallint;
    z1:smallint;
  end;
  pTOgfMotionKeyQT16 = ^TOgfMotionKeyQT16;

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

  TVerticesIterationCallback = function (vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; userdata:pointer):boolean;
  TOgfVertsContainer = class
  private
    _link_type:cardinal;
    _verts_count:cardinal;
    _raw_data:array of byte;
    function _GetVertexDataPtr(id:cardinal):pTOgfVertexCommonData;
    function _GetVertexUvDataPtr(id:cardinal):pFVector2;
    function _GetVertexBindings(id:cardinal; bindings_out:TVertexBones):boolean;
    function _SetVertexBindings(id:cardinal; bindings_in:TVertexBones):boolean;
    function _FilterVertices(var filter:TVertexFilterItems):boolean;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):boolean;
    function Serialize():string;
    // Specific
    function MoveVertices(offset:FVector3; selection_callback:TVerticesIterationCallback; userdata:pointer):boolean;
    function ScaleVertices(factors:pFVector3; pivot_point:pFVector3; selection_callback:TVerticesIterationCallback; userdata:pointer):boolean;
    function RotateVertices(m:pFMatrix3x3; pivot_point:pFVector3; selection_callback:TVerticesIterationCallback; userdata:pointer):boolean;
    function RebindVerticesToNewBone(new_bone_index:TBoneID; old_bone_index:TBoneID):boolean;
    function GetVerticesCountForBoneID(boneid:TBoneID; ignorezeroweights:boolean):integer;
    function IsVertexAssignedToBoneID(vertexid:cardinal; boneid:TBoneID; ignorezeroweights:boolean):boolean;

    function GetCurrentLinkType():cardinal;
    function GetVerticesCount():cardinal;
    function CalculateOptimalLinkType():cardinal;
    function ChangeLinkType(new_link_type:cardinal):boolean;

    procedure IterateVertices(cb:TVerticesIterationCallback; userdata:pointer);
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
    _lods:array of TOgfSlideWindowItem;

    procedure _ResetWithSingleReplacement(w:TOgfSlideWindowItem);
    function _UpdateLodLevelData(idx:integer; swi:TOgfSlideWindowItem):boolean;
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
    function GetLodLevelParams(level_id:integer):TOgfSlideWindowItem;
  end;

  TOgfVertexIndex = word;
  TOgfTriangle = packed record
    v1:TOgfVertexIndex;
    v2:TOgfVertexIndex;
    v3:TOgfVertexIndex;
  end;
  pTOgfTriangle = ^TOgfTriangle;

  TTrisRemapIndices = array of integer;
  { TOgfTrisContainer }

  TOgfTrisContainer = class
  private
    _tris:array of TOgfTriangle;
    _current_lod_params:TOgfSlideWindowItem;

    function _GetTriangleIdByOffset(offset:integer):integer;
    procedure _RemoveAllTrisNotInCurrentLod();
    function _FilterVertices(var filter:TVertexFilterItems; swr_data:TOgfSwiContainer):boolean;
    function _CorrectSwi(swi:TOgfSlideWindowItem; remap:TTrisRemapIndices):TOgfSlideWindowItem;
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
    function GetTriangle(idx:integer; for_current_lod:boolean; var t:TOgfTriangle):boolean;
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

  TOgfRotationAxis = (OgfRotationAxisX, OgfRotationAxisY, OgfRotationAxisZ);

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

    function GetLodLevels():integer;
    function AssignLodLevel(level:integer):boolean;
    function RemoveUnactiveLodsData():boolean;

    function CalculateOptimalLinkType():cardinal;
    function ChangeLinkType(new_link_type:cardinal):boolean;
    function RebindVertices(target_boneid:TBoneID; source_boneid:TBoneID):boolean;
    function GetVerticesCountForBoneId(boneid:TBoneID):integer;

    function FilterVertices(var filter:TVertexFilterItems):boolean;

    procedure IterateVertices(cb:TVerticesIterationCallback; userdata:pointer);
    function RemoveVertices(cb:TVerticesIterationCallback; userdata:pointer):boolean; // true returned from cb will mark the vertex to be removed

    function Scale(v:FVector3; pivot_point:FVector3; selection_callback:TVerticesIterationCallback; userdata:pointer):boolean;
    function Move(v:FVector3; selection_callback:TVerticesIterationCallback; userdata:pointer):boolean;
    function RotateUsingStandartAxis(amount_radians:single; rotation_axis:TOgfRotationAxis; pivot_point:FVector3; selection_callback:TVerticesIterationCallback; userdata:pointer):boolean;

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

    function SerializeBoneIKData(id:integer):string;
    function DeserializeBoneIKData(id:integer; s:string):boolean;

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

    function _GetFrameData(idx:integer; var pqr:pointer; var pqt:pointer):boolean; //returns ptrs to internal data. CHECK IF QRs and QTs keys present before changing!

    procedure _GetCurrentTransLimits(var min_limit:FVector3; var max_limit:FVector3);
    function _CheckTransWithinLimits(trans:FVector3; var new_min:FVector3; var new_max:FVector3; use_internal_current_limits:boolean=true):boolean;
    function _RebuildTransKeysForNewLimits(min_limit:FVector3; max_limit:FVector3):boolean;

    function _CheckRKeySameWith(qr:pTOgfMotionKeyQR; q:pFquaternion):boolean;
    function _CheckT8KeySameWith(qt:pTOgfMotionKeyQT8; v:pFVector3):boolean;
    function _CheckT16KeySameWith(qt:pTOgfMotionKeyQT16; v:pFVector3):boolean;

    procedure _CreateTransKeysFromInit();
  public
    // Common
    constructor Create; overload;
    constructor Create(default_key:TMotionKey; frames_count:integer); overload;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string; frames_count:cardinal):integer;
    function Serialize():string;


    function FramesCount():integer;
    function GetKey(idx:integer; var key:TMotionKey):boolean;
    function SetKey(idx:integer; key:TMotionKey):boolean;

    function ChangeFramesCount(new_frames_count:integer):boolean;

    function Copy(from:TOgfMotionBoneTrack):boolean;
    function MergeWithTrack(second:TOgfMotionBoneTrack):boolean;
  end;

  { TOgfMotionTrack }

  TOgfMotionTrack = class
    _loaded:boolean;
    _name:string; // no need to expose - engine uses name from MotionDefs, so use it!
    _frames_count:cardinal;
    _bone_tracks:array of TOgfMotionBoneTrack;

    function _SwapBones(idx1:integer; idx2:integer):boolean;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):boolean;
    function Serialize():string;

    function AddBone(default_key:TMotionKey):integer;
    function RemoveBone(track_bone_idx:integer):boolean;
    function ChangeFramesCount(new_frames_count:integer):boolean;
    function GetFramesCount():integer;
    procedure SetName(name:string);  // no getter by design - use names from MotionDefs!

    function GetBoneKey(track_bone_idx:integer; key_idx:integer; var k:TMotionKey):boolean;
    function SetBoneKey(track_bone_idx:integer; key_idx:integer; k:TMotionKey):boolean;

    function Copy(from:TOgfMotionTrack):boolean;
    function MergeWithTrack(second:TOgfMotionTrack):boolean;

  end;


  { TOgfMotionTracksContainer }

  TOgfMotionTracksContainer = class
    _loaded:boolean;
    _motions:array of TOgfMotionTrack;

    function _CopyDataIntoNewTrack(track:TOgfMotionTrack; new_name:string):integer;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):boolean;
    function Serialize():string;

    function MotionTracksCount():integer;
    function GetMotionTrack(idx:integer):TOgfMotionTrack;

    function DuplicateTrack(idx:integer; new_name:string):integer;
    function RemoveTrack(idx:integer):boolean;
  end;

   { TOgfMotionBoneParams }

   TOgfMotionBoneParams = class
     _loaded:boolean;
     _name:string;
     _idx_in_track:cardinal;
     procedure _SetIdxInTracks(new_idx_in_tracks:integer);
   public
     // Common
     constructor Create; overload;
     constructor Create(name:string; idx_in_tracks:integer); overload;
     destructor Destroy; override;
     procedure Reset;
     function Loaded():boolean;
     function Deserialize(rawdata:string):integer;
     function Serialize():string;

     function GetName():string;
     function GetIdxInTracks():integer;
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

     function GetName():string;
     function GetBonesCount():integer;
     function GetBoneByLocalIndex(n:integer):TOgfMotionBoneParams;
     function GetBoneLocalIndexByName(name:string):integer;
     function AddBone(name:string; idx_in_track:integer):integer;
     function RemoveBone(n:integer):boolean;
   end;

   { TOgfMotionMark }

   TOgfMotionMark = class
     _loaded:boolean;
     _name:string;
     _intervals: array of TOgfMotionMarkInterval;
   public
     // Common
     constructor Create;
     constructor Create(second:TOgfMotionMark);
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

     procedure CopyFrom(second:TOgfMotionMarks);
   end;

   { TOgfMotionDef }

   TOgfMotionDefData = record
     name:string;
     flags:cardinal;
     bone_or_part:word;
     motion_id:word;
     speed:single;
     power:single;
     accrue:single;
     falloff:single;
     marks:TOgfMotionMarks;
   end;

   TOgfMotionDef = class
     _loaded:boolean;
     _data:TOgfMotionDefData;
   public
     // Common
     constructor Create;
     destructor Destroy; override;
     procedure Reset;
     function Loaded():boolean;
     function Deserialize(rawdata:string; version:cardinal):integer;
     function Serialize():string;

     function GetData():TOgfMotionDefData;
     procedure SetData(d:TOgfMotionDefData);
   end;

  { TOgfMotionParamsContainer }

  TOgfMotionParamsContainer = class
    _loaded:boolean;
    _bone_parts:array of TOgfMotionBonePart;
    _defs: array of TOgfMotionDef;


    function _SwapTracksBonesIdx(idx1:integer; idx2:integer):boolean;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):boolean;
    function Serialize():string;

    //Specific
    function MotionsDefsCount():integer;
    function GetMotionDefByIdx(idx:integer):TOgfMotionDefData;
    function UpdateMotionDefsForIdx(idx:integer; data:TOgfMotionDefData):boolean;
    function GetMotionIdxForName(name:string):integer;
    function AddMotionDef(data:TOgfMotionDefData):integer;
    function RemoveMotionDef(idx:integer):boolean;

    function GetBonePartsCount():integer;
    function GetBonePart(idx:integer):TOgfMotionBonePart;
    function GetTotalBonesCount():integer;
    function FindBoneIdxsByName(name:string; var bone_part_idx:integer; var local_bone_idx_in_part:integer):boolean;
    function AddBone(name:string; idx_in_tracks:integer; bone_part_idx:integer):boolean;
    function GetBone(bone_part_idx:integer; local_bone_idx_in_part:integer):TOgfMotionBoneParams;
    function GetBoneByIdxInTrack(idx_in_tracks:integer):TOgfMotionBoneParams;
    function RemoveBone(bone_part_idx:integer; local_bone_idx_in_part:integer):boolean;
  end;

  { TOgfBaseFileParser }

  TOgfBaseFileParser = class
  protected
    _loaded:boolean;
    _source:TChunkedMemory;
    _owns_source:boolean;

    function _UpdateChunk(id:word; data:string):boolean;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset; virtual;                                 // For deserialized data only, not source
    function Loaded():boolean;

    function Deserialize(rawdata:string):boolean; virtual; abstract;
    function Serialize():string;                              // performs UpdateSource and serialization

    procedure ResetSource(new_source:TChunkedMemory); virtual;
    function ReloadFromSource():boolean;                      // forget all modifications, reload from source
    function UpdateSource():boolean; virtual; abstract;       // apply all modifications to source

    function LoadFromFile(fname:string):boolean;
    function SaveToFile(fname:string):boolean;
    function LoadFromMem(addr:pointer; sz:cardinal):boolean;
    function LoadFromChunkedMem(mem:TChunkedMemory):boolean;  // doesn't copy mem, stores reference!

  end;

  { TOgfAnimationsParser }

  TOgfAnimationsParser = class(TOgfBaseFileParser)
    _tracks:TOgfMotionTracksContainer;
    _params:TOgfMotionParamsContainer;


    function _GetMotionTrackByName(name:string):TOgfMotionTrack;
    function _SwapIdxInTracksForBones(idx1:integer; idx2:integer):boolean;
    function _GenerateAnimationName(target_name:string):string;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset; override;
    function Deserialize(rawdata:string):boolean; override;
    function UpdateSource():boolean; override;

    procedure Sanitize(skeleton:TOgfSkeleton);

    function AnimationsCount():integer;
    function GetAnimationParams(idx:integer):TOgfMotionDefData;
    function GetAnimationIdByName(name:string):integer;
    function UpdateAnimationParams(idx:integer; d:TOgfMotionDefData):boolean;

    function AddBone(name:string; default_key:TMotionKey; part_id:integer=0):boolean;
    function RemoveBone(name:string):boolean;

    function ChangeAnimationFramesCount(anim_name:string; new_frames_count:integer):boolean;
    function GetAnimationFramesCount(anim_name:string):integer;

    function GetAnimationKeyForBone(anim_name:string; bone_name:string; key_idx:integer; var k:TMotionKey):boolean;
    function SetAnimationKeyForBone(anim_name:string; bone_name:string; key_idx:integer; k:TMotionKey):boolean;

    function DuplicateAnimation(old_name:string; new_name:string):boolean;
    function MergeAnimations(name_of_new:string; name_of_first:string; name_of_second:string):boolean;
    function DeleteAnimation(name:string):boolean;

    function MergeContainers(source_to_merge:TOgfAnimationsParser):boolean;
  end;

 { TOgfParser }

 TOgfParser = class(TOgfBaseFileParser)
 private
   _children:TOgfChildrenContainer;
   _bone_names:TOgfBonesContainer;
   _ikdata:TOgfBonesIKDataContainer;
   _userdata:TOgfUserdataContainer;
   _lodref:TOgfLodRefsContainer;
   _skeleton:TOgfSkeleton;
   _animations:TOgfAnimationsParser;

 public
   // Common
   constructor Create;
   destructor Destroy; override;
   procedure Reset; override;
   function Deserialize(rawdata:string):boolean; override;
   function UpdateSource():boolean; override;
   procedure ResetSource(new_source:TChunkedMemory); override;

   function Meshes():TOgfChildrenContainer;
   function Skeleton():TOgfSkeleton;
   function Animations():TOgfAnimationsParser;
end;

function QrToQuat(pqr:pTOgfMotionKeyQR):Fquaternion;
function Qt8ToT(pqt:pTOgfMotionKeyQT8; size_tr:pFVector3; init_tr:pFVector3):FVector3;
function Qt16ToT(pqt:pTOgfMotionKeyQT16; size_tr:pFVector3; init_tr:pFVector3):FVector3;

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
  CHUNK_OGF_S_MOTIONS:word=14;
  CHUNK_OGF_S_SMPARAMS:word=15;
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

  MT_SKELETON_GEOMDEF_PM = 4;
  MT_SKELETON_GEOMDEF_ST = 5;

implementation
uses sysutils, FastCrc, math;

const EPS:single = 0.00001;

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

constructor TOgfMotionMark.Create(second: TOgfMotionMark);
var
  i:integer;
begin
  Create();
  _loaded:=second._loaded;
  if _loaded then begin
     setlength(_intervals, length(second._intervals));
     _name:=second._name;
     for i:=0 to length(_intervals)-1 do begin
       _intervals[i]:=second._intervals[i];
     end;
  end;
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

procedure TOgfMotionMarks.CopyFrom(second: TOgfMotionMarks);
var
  i:integer;
begin
  if second = self then exit;
  Reset();
  if second = nil then exit;
  if not second.Loaded() then exit;

  _loaded:=true;
  setlength(_marks, length(second._marks));
  for i:=0 to length(_marks)-1 do begin
    _marks[i]:=TOgfMotionMark.Create(second._marks[i]);
  end;
end;

{ TOgfMotionDef }

constructor TOgfMotionDef.Create;
begin
  _loaded:=false;
  _data.marks:=TOgfMotionMarks.Create();
  Reset();
end;

destructor TOgfMotionDef.Destroy;
begin
  Reset();
  FreeAndNil(_data.marks);
  inherited Destroy;
end;

procedure TOgfMotionDef.Reset;
var
  i:integer;
begin
  _loaded:=false;
  _data.marks.Reset;

  _data.name:='';
  _data.flags:=0;
  _data.bone_or_part:=0;
  _data.motion_id:=0;
  _data.speed:=1;
  _data.power:=1;
  _data.accrue:=2;
  _data.falloff:=2;
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
    if not DeserializeZStringAndSplit(rawdata, _data.name) then exit;

    sz:=sizeof(cardinal);
    if length(rawdata)<sz then exit;
    _data.flags:=PCardinal(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    sz:=sizeof(word);
    if length(rawdata)<sz then exit;
    _data.bone_or_part:=PWord(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    sz:=sizeof(word);
    if length(rawdata)<sz then exit;
    _data.motion_id:=PWord(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    sz:=sizeof(single);
    if length(rawdata)<sz then exit;
    _data.speed:=PSingle(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    sz:=sizeof(single);
    if length(rawdata)<sz then exit;
    _data.power:=PSingle(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    sz:=sizeof(single);
    if length(rawdata)<sz then exit;
    _data.accrue:=PSingle(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    sz:=sizeof(single);
    if length(rawdata)<sz then exit;
    _data.falloff:=PSingle(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    if version>=4 then begin
      sz:=_data.marks.Deserialize(rawdata);
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

  result:=result+_data.name+chr(0);
  result:=result+SerializeCardinal(_data.flags);
  result:=result+SerializeWord(_data.bone_or_part);
  result:=result+SerializeWord(_data.motion_id);
  result:=result+SerializeFloat(_data.speed);
  result:=result+SerializeFloat(_data.power);
  result:=result+SerializeFloat(_data.accrue);
  result:=result+SerializeFloat(_data.falloff);
  result:=result+_data.marks.Serialize(); // for version <4 returns an empty string because not loaded

end;

function TOgfMotionDef.GetData(): TOgfMotionDefData;
begin
  result:=_data;
end;

procedure TOgfMotionDef.SetData(d: TOgfMotionDefData);
var
  my_marks:TOgfMotionMarks;
begin
  _loaded:=true;
  if d.marks<>_data.marks then begin
    my_marks:=_data.marks;
    my_marks.CopyFrom(d.marks);
    _data:=d;
    _data.marks:=my_marks;
  end else begin
    _data:=d;
  end;
end;

{ TOgfMotionBoneParams }

constructor TOgfMotionBoneParams.Create;
begin
  Reset();
end;

constructor TOgfMotionBoneParams.Create(name: string; idx_in_tracks: integer);
begin
  Create();
  _idx_in_track:=idx_in_tracks;
  _name:=name;
  _loaded:=true;
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
  _idx_in_track:=0;
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
    _idx_in_track:=(PCardinal(PAnsiChar(rawdata))^) and $FFFF;
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
  result:=result+SerializeCardinal(_idx_in_track);
end;

function TOgfMotionBoneParams.GetName(): string;
begin
  result:='';
  if not _loaded then exit;

  result:=_name;
end;

function TOgfMotionBoneParams.GetIdxInTracks(): integer;
begin
  result:=-1;
  if not _loaded then exit;

  result:=_idx_in_track;
end;

procedure TOgfMotionBoneParams._SetIdxInTracks(new_idx_in_tracks: integer);
begin
  _idx_in_track:=new_idx_in_tracks;
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

function TOgfMotionBonePart.GetName(): string;
begin
  result:='';
  if not _loaded then exit;

  result:=_name;
end;

function TOgfMotionBonePart.GetBonesCount(): integer;
begin
  result:=0;
  if not _loaded then exit;
  result:=length(_bones_params);
end;

function TOgfMotionBonePart.GetBoneByLocalIndex(n: integer): TOgfMotionBoneParams;
begin
  result:=nil;
  if not _loaded then exit;
  if (n>=0) and (n<length(_bones_params)) then begin
    result:=_bones_params[n];
  end;
end;

function TOgfMotionBonePart.GetBoneLocalIndexByName(name: string): integer;
var
  i:integer;
begin
  result:=-1;
  if not _loaded then exit;

  for i:=0 to length(_bones_params)-1 do begin
    if _bones_params[i].Loaded() and (_bones_params[i]._name = name) then begin
      result:=i;
      break;
    end;
  end;
end;

function TOgfMotionBonePart.AddBone(name: string; idx_in_track: integer): integer;
var
  i, target_pos:integer;
  cmpres:integer;
begin
  // bones are in alphabetical order, so find an appropriate place
  result:=-1;
  i:=0;
  target_pos:=length(_bones_params);
  for i:=0 to length(_bones_params)-1 do begin
    cmpres:= CompareStr(name, _bones_params[i].GetName());
    if cmpres = 0 then begin
      exit;
    end else if cmpres < 0 then begin
      target_pos:=i;
      break;
    end;
  end;

  setlength(_bones_params, length(_bones_params)+1);
  for i:=length(_bones_params)-1 downto target_pos+1 do begin
    _bones_params[i]:=_bones_params[i-1];
  end;
  _bones_params[target_pos]:=TOgfMotionBoneParams.Create(name, idx_in_track);
  result:=target_pos;
end;

function TOgfMotionBonePart.RemoveBone(n: integer): boolean;
var
  i:integer;
begin
  result:=false;
  if not _loaded then exit;

  if (n>=0) and (n < length(_bones_params)) then begin
    _bones_params[n].Free;

    for i:=n to length(_bones_params)-2 do begin
      _bones_params[i]:=_bones_params[i+1];
    end;

    setlength(_bones_params, length(_bones_params)-1);
    result:=true;
  end;
end;


{ TOgfMotionParamsContainer }

function TOgfMotionParamsContainer._SwapTracksBonesIdx(idx1: integer; idx2: integer): boolean;
var
  bone1, bone2:TOgfMotionBoneParams;
begin
  result:=false;
  if not Loaded() then exit;

  bone1:=GetBoneByIdxInTrack(idx1);
  if (bone1 = nil) or (bone1.GetIdxInTracks()<>idx1) then exit;

  bone2:=GetBoneByIdxInTrack(idx2);
  if (bone2 = nil) or (bone1.GetIdxInTracks()<>idx2) then exit;

  bone2._SetIdxInTracks(idx1);
  bone1._SetIdxInTracks(idx2);

  result:=true;
end;

constructor TOgfMotionParamsContainer.Create;
begin
  _loaded:=false;
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
  version:word;
begin
  result:=false;
  Reset();

  try
    sz:=sizeof(word);
    if length(rawdata)<sz then exit;
    version:=PWord(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    if ((version>4) or (version < 3)) then exit;

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
      sz:=_defs[i].Deserialize(rawdata, version);
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
  version:word;
  marks:TOgfMotionMarks;
begin
  result:='';
  if not Loaded() then exit;

  version:=3;
  if MotionsDefsCount() = 0 then exit;
  for i:=0 to MotionsDefsCount()-1 do begin
    marks:=GetMotionDefByIdx(i).marks;
    if (marks<>nil) and (marks.Loaded()) then begin
      version:=4;
      break;
    end;
  end;


  result:=result+SerializeWord(version);
  result:=result+SerializeWord(length(_bone_parts));
  for i:=0 to length(_bone_parts)-1 do begin
    result:=result+_bone_parts[i].Serialize();
  end;

  result:=result+SerializeWord(length(_defs));
  for i:=0 to length(_defs)-1 do begin
    result:=result+_defs[i].Serialize();
  end;

end;

function TOgfMotionParamsContainer.MotionsDefsCount(): integer;
begin
  result:=0;
  if not Loaded() then exit;

  result:=length(_defs);
end;

function TOgfMotionParamsContainer.GetMotionDefByIdx(idx: integer): TOgfMotionDefData;
begin
  if (idx < 0) or (idx >= MotionsDefsCount()) then begin
    result.motion_id:=$FFFF;
    result.name:='';

    result.accrue:=0;
    result.falloff:=0;
    result.speed:=0;
    result.power:=0;
    result.bone_or_part:=0;
    result.flags:=0;
    result.marks:=nil;
  end else begin
    result:=_defs[idx].GetData();
  end;
end;

function TOgfMotionParamsContainer.UpdateMotionDefsForIdx(idx: integer; data: TOgfMotionDefData): boolean;
begin
  if (idx < 0) or (idx >= MotionsDefsCount()) then begin
    result:=false;
  end else begin
    _defs[idx].SetData(data);
    result:=true;
  end;
end;

function TOgfMotionParamsContainer.GetMotionIdxForName(name: string): integer;
var
  i:integer;
begin
  result:=-1;
  for i:=0 to length(_defs)-1 do begin
    if _defs[i].GetData().name = name then begin
      result:=i;
      break;
    end;
  end;
end;

function TOgfMotionParamsContainer.AddMotionDef(data: TOgfMotionDefData): integer;
var
  i:integer;
begin
  result:=-1;
  if not Loaded() then exit;

  i:=length(_defs);
  setlength(_defs, i+1);

  _defs[i]:=TOgfMotionDef.Create();
  _defs[i].SetData(data);

  result:=i;
end;

function TOgfMotionParamsContainer.RemoveMotionDef(idx: integer): boolean;
var
  i:integer;
begin
  result:=false;
  if not Loaded() then exit;
  if (idx < 0) or (idx >= MotionsDefsCount()) then exit;

  _defs[idx].Free;
  for i:=idx to length(_defs)-2 do begin
    _defs[idx]:=_defs[idx+1];
  end;
  setlength(_defs, length(_defs)-1);
  result:=true;
end;

function TOgfMotionParamsContainer.GetBonePartsCount(): integer;
begin
  result:=0;
  if not Loaded() then exit;
  result:=length(_bone_parts);
end;

function TOgfMotionParamsContainer.GetBonePart(idx: integer): TOgfMotionBonePart;
begin
  result:=nil;
  if not Loaded() then exit;
  if (idx >= 0) and (idx < length(_bone_parts)) then begin
    result:=_bone_parts[idx];
  end;
end;

function TOgfMotionParamsContainer.GetTotalBonesCount(): integer;
var
  i:integer;
begin
  result:=0;
  if not Loaded() then exit;
  for i:=0 to length(_bone_parts)-1 do begin
    result:=result+_bone_parts[i].GetBonesCount();
  end;
end;

function TOgfMotionParamsContainer.FindBoneIdxsByName(name: string; var bone_part_idx: integer; var local_bone_idx_in_part: integer): boolean;
var
  i, idx:integer;
begin
  result:=false;
  if not Loaded() then exit;

  for i:=0 to length(_bone_parts)-1 do begin
    idx:=_bone_parts[i].GetBoneLocalIndexByName(name);
    if idx >= 0 then begin
      result:=true;
      bone_part_idx:=i;
      local_bone_idx_in_part:=idx;
      break;
    end;
  end;
end;

function TOgfMotionParamsContainer.AddBone(name: string; idx_in_tracks: integer; bone_part_idx: integer): boolean;
var
  i,j:integer;
  part:TOgfMotionBonePart;
  params:TOgfMotionBoneParams;
begin
  result:=false;
  if not Loaded() then exit;
  if GetBonePartsCount() <= bone_part_idx then exit;

  //Check if we already have bone with such ID or name in tracks
  for i:=0 to GetBonePartsCount()-1 do begin
    part:=GetBonePart(i);
    for j:=0 to part.GetBonesCount()-1 do begin
      params:=part.GetBoneByLocalIndex(j);
      if (params<>nil) and (params.GetIdxInTracks() = idx_in_tracks) or (params.GetName() = name) then begin
        result:=false;
        exit;
      end;
    end;
  end;

  result:=(_bone_parts[bone_part_idx].AddBone(name, idx_in_tracks)>=0);
end;

function TOgfMotionParamsContainer.GetBone(bone_part_idx: integer; local_bone_idx_in_part: integer): TOgfMotionBoneParams;
begin
  result:=nil;
  if not Loaded() then exit;

  if (bone_part_idx >= 0) and (bone_part_idx < length(_bone_parts)) then begin
    result:=_bone_parts[bone_part_idx].GetBoneByLocalIndex(local_bone_idx_in_part);
  end;
end;

function TOgfMotionParamsContainer.GetBoneByIdxInTrack(idx_in_tracks: integer): TOgfMotionBoneParams;
var
  i,j:integer;
  part:TOgfMotionBonePart;
  bone:TOgfMotionBoneParams;
begin
  result:=nil;
  if not Loaded() then exit;

  for i:=0 to GetBonePartsCount()-1 do begin
    part:=GetBonePart(i);
    for j:=0 to part.GetBonesCount()-1 do begin
      bone:=part.GetBoneByLocalIndex(j);
      if (bone<>nil) and (bone.GetIdxInTracks() = idx_in_tracks) then begin
        result:=bone;
        exit;
      end;
    end;
  end;

end;

function TOgfMotionParamsContainer.RemoveBone(bone_part_idx: integer; local_bone_idx_in_part: integer): boolean;
begin
  result:=false;
  if not Loaded() then exit;

  if (bone_part_idx >= 0) and (bone_part_idx < length(_bone_parts)) then begin
    result:=_bone_parts[bone_part_idx].RemoveBone(local_bone_idx_in_part);
  end;
end;

{ TOgfMotionBoneTrack }
function TOgfMotionBoneTrack._GetFrameData(idx: integer; var pqr: pointer; var pqt: pointer): boolean;
var
  real_idx:integer;
begin
  result:=false;
  if not Loaded then exit;
  if (idx<0) or (idx>=_frames_count) then exit;

  real_idx:=idx;
  if not _rot_keys_present then begin
    real_idx:=0;
  end;
  pqr:= @_rot_keys_rawdata[real_idx*sizeof(TOgfMotionKeyQR)];

  real_idx:=idx;
  if not _trans_keys_present then begin
    real_idx:=0;
  end;

  if _is16bittransform then begin
    pqt:= @_trans_keys_rawdata[real_idx*sizeof(TOgfMotionKeyQT16)];
  end else begin
    pqt:= @_trans_keys_rawdata[real_idx*sizeof(TOgfMotionKeyQT8)];
  end;

  result:=true;
end;

procedure TOgfMotionBoneTrack._GetCurrentTransLimits(var min_limit: FVector3; var max_limit: FVector3);
var
  min8:TOgfMotionKeyQT8;
  max8:TOgfMotionKeyQT8;
  min16:TOgfMotionKeyQT16;
  max16:TOgfMotionKeyQT16;

begin
  if _trans_keys_present then begin
    min_limit:=_initT;
    max_limit:=_initT;

    if _is16bittransform then begin
      min16.x1:=-32767;
      min16.y1:=-32767;
      min16.z1:=-32767;

      max16.x1:=32767;
      max16.y1:=32767;
      max16.z1:=32767;

      min_limit:=Qt16ToT(@min16, @_sizeT, @_initT);
      max_limit:=Qt16ToT(@max16, @_sizeT, @_initT);
    end else begin
      min8.x1:=-127;
      min8.y1:=-127;
      min8.z1:=-127;

      max8.x1:=127;
      max8.y1:=127;
      max8.z1:=127;

      min_limit:=Qt8ToT(@min8, @_sizeT, @_initT);
      max_limit:=Qt8ToT(@max8, @_sizeT, @_initT);
    end;
  end else begin
    min_limit:=_initT;
    max_limit:=_initT;
  end;
end;

function TOgfMotionBoneTrack._CheckTransWithinLimits(trans: FVector3; var new_min: FVector3; var new_max: FVector3; use_internal_current_limits: boolean): boolean;
begin
  if use_internal_current_limits then begin
    _GetCurrentTransLimits(new_min, new_max);
  end;

  result:=true;

  if trans.x<new_min.x then begin
    new_min.x:=trans.x;
    result:=false;
  end;

  if trans.y<new_min.y then begin
    new_min.y:=trans.y;
    result:=false;
  end;

  if trans.z<new_min.z then begin
    new_min.z:=trans.z;
    result:=false;
  end;

  if trans.x>new_max.x then begin
    new_max.x:=trans.x;
    result:=false;
  end;

  if trans.y>new_max.y then begin
    new_max.y:=trans.y;
    result:=false;
  end;

  if trans.z>new_max.z then begin
    new_max.z:=trans.z;
    result:=false;
  end;
end;

function clamp(x:single; min:integer; max:integer):integer;
begin
  if x < min then begin
    result:=min;
  end else if x > max then begin
    result:=max;
  end else begin
    result:=floor(x);
  end;
end;

function TOgfMotionBoneTrack._RebuildTransKeysForNewLimits(min_limit: FVector3; max_limit: FVector3): boolean;
var
  d:FVector3;
  d2:FVector3;
  new_initt:FVector3;
  new_sizet:FVector3;
  i:integer;

  pqr, pqt:pointer;
  trans:FVector3;

  new_data:array of TOgfMotionKeyQT16;
  qt_value:single;
begin
  result:=false;
  if not _loaded then exit;
  if not _trans_keys_present then exit;
  if min_limit.x > max_limit.x then exit;
  if min_limit.y > max_limit.y then exit;
  if min_limit.z > max_limit.z then exit;

  d:=v_sub(@max_limit, @min_limit);
  d2:=v_mul(@d, 0.5);
  new_initt:=v_add(@min_limit, @d2);
  new_sizet:=v_mul(@d2, 1/32767);

  setlength(new_data, _frames_count);

  try
    for i:=0 to _frames_count-1 do begin
      if not _GetFrameData(i, pqr, pqt) then exit;

      if _is16bittransform then begin
        trans:=Qt16ToT(pqt, @_sizeT, @_initT);
      end else begin
        trans:=Qt8ToT(pqt, @_sizeT, @_initT);
      end;

      if    (trans.x<min_limit.x) or (trans.x>max_limit.x)
         or (trans.y<min_limit.y) or (trans.y>max_limit.y)
         or (trans.z<min_limit.z) or (trans.z>max_limit.z)
      then begin
        exit;
      end;

      trans:=v_sub(@trans, @new_initt);

      if abs(d.x)>EPS then begin
        qt_value:= trans.x / new_sizet.x;
        new_data[i].x1:=clamp(qt_value, -32767, 32767);
      end else begin
        new_data[i].x1:=0;
      end;

      if abs(d.y)>EPS then begin
        qt_value:= trans.y / new_sizet.y;
        new_data[i].y1:=clamp(qt_value, -32767, 32767);
      end else begin
        new_data[i].y1:=0;
      end;

      if abs(d.z)>EPS then begin
        qt_value:= trans.z / new_sizet.z;
        new_data[i].z1:=clamp(qt_value, -32767, 32767);
      end else begin
        new_data[i].z1:=0;
      end;
    end;

    setlength(_trans_keys_rawdata, _frames_count * sizeof(TOgfMotionKeyQT16));
    for i:=0 to _frames_count-1 do begin
      pTOgfMotionKeyQT16(@(_trans_keys_rawdata[0]))[i]:=new_data[i];
    end;
    _is16bittransform:=true;
    _initT:=new_initt;
    _sizeT:=new_sizet;


    result:=true;
  finally
    setlength(new_data, 0);
  end;
end;

function TOgfMotionBoneTrack._CheckRKeySameWith(qr: pTOgfMotionKeyQR; q: pFquaternion): boolean;
var
  q2:Fquaternion;
begin
  q2:=QrToQuat(qr);
  result:= (abs(q^.w-q2.w) < EPS) and (abs(q^.x-q2.x) < EPS) and (abs(q^.y-q2.y) < EPS) and (abs(q^.y-q2.y) < EPS);
end;

function TOgfMotionBoneTrack._CheckT8KeySameWith(qt: pTOgfMotionKeyQT8; v: pFVector3): boolean;
var
  v2:FVector3;
begin
  v2:=Qt8ToT(qt, @_sizeT, @_initT);
  result:=(abs(v^.x-v2.x) < EPS) and (abs(v^.y-v2.y) < EPS) and (abs(v^.z-v2.z) < EPS);
end;

function TOgfMotionBoneTrack._CheckT16KeySameWith(qt: pTOgfMotionKeyQT16; v: pFVector3): boolean;
var
  v2:FVector3;
begin
  v2:=Qt16ToT(qt, @_sizeT, @_initT);
  result:=(abs(v^.x-v2.x) < EPS) and (abs(v^.y-v2.y) < EPS) and (abs(v^.z-v2.z) < EPS);
end;

procedure TOgfMotionBoneTrack._CreateTransKeysFromInit();
var
  t_data:array of TOgfMotionKeyQT16;
  qt:TOgfMotionKeyQT16;
  i:integer;
begin
  if _trans_keys_present then exit;

  // create array of keys same with initial, force 16-bit
  setlength(t_data, _frames_count);
  // the coordinate is same for all keys, so just set 0 to all QRs
  qt.x1:=0;
  qt.y1:=0;
  qt.z1:=0;
  for i:=0 to _frames_count-1 do begin
    t_data[i]:=qt;
  end;
  setlength(_trans_keys_rawdata, _frames_count*sizeof(TOgfMotionKeyQT16));
  Move(t_data[0], _trans_keys_rawdata[0], _frames_count*sizeof(TOgfMotionKeyQT16));
  set_zero(_sizeT);
  setlength(t_data, 0);
  _trans_keys_present:=true;
  _is16bittransform:=true;
end;

constructor TOgfMotionBoneTrack.Create;
begin
  Reset();
end;

constructor TOgfMotionBoneTrack.Create(default_key: TMotionKey; frames_count: integer);
var
  pqr:pTOgfMotionKeyQR;
const
  KEY_Quant:integer=32767;
begin
  Create();

  _rot_keys_present:=false;
  setlength(_rot_keys_rawdata, sizeof(TOgfMotionKeyQR));

  pqr:=pTOgfMotionKeyQR(@_rot_keys_rawdata[0]);
  pqr^.w:= clamp(default_key.q.w * KEY_Quant, -KEY_Quant, KEY_Quant);
  pqr^.x:= clamp(default_key.q.x * KEY_Quant, -KEY_Quant, KEY_Quant);
  pqr^.y:= clamp(default_key.q.y * KEY_Quant, -KEY_Quant, KEY_Quant);
  pqr^.z:= clamp(default_key.q.z * KEY_Quant, -KEY_Quant, KEY_Quant);


  _trans_keys_present:=false;
  _is16bittransform:=true;
  setlength(_trans_keys_rawdata, sizeof(TOgfMotionKeyQT16));
  pTOgfMotionKeyQT16(@_trans_keys_rawdata[0])^.x1:=0;
  pTOgfMotionKeyQT16(@_trans_keys_rawdata[0])^.y1:=0;
  pTOgfMotionKeyQT16(@_trans_keys_rawdata[0])^.z1:=0;
  set_zero(_sizeT);
  _initT:=default_key.T;

  _frames_count:=frames_count;
  _loaded:=true;
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
    end else begin
      // set fake zero first frame (like with rotation) to make key calculations easier
      if _is16bittransform then begin
        setlength(_trans_keys_rawdata, sizeof(TOgfMotionKeyQT16));
      end else begin
        setlength(_trans_keys_rawdata, sizeof(TOgfMotionKeyQT8));
      end;
      FillChar(_trans_keys_rawdata[0], length(_trans_keys_rawdata), 0);
      set_zero(_sizeT);
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
    result:=result+SerializeBlock(@_trans_keys_rawdata[0], length(_trans_keys_rawdata));
    result:=result+SerializeVector3(_sizeT);
  end;
  result:=result+SerializeVector3(_initT);
end;

function QrToQuat(pqr:pTOgfMotionKeyQR):Fquaternion;
const
  KEY_QuantI: single = 1/32767;
begin
  result.x:=pqr^.x * KEY_QuantI;
  result.y:=pqr^.y * KEY_QuantI;
  result.z:=pqr^.z * KEY_QuantI;
  result.w:=pqr^.w * KEY_QuantI;
end;

function Qt8ToT(pqt:pTOgfMotionKeyQT8; size_tr:pFVector3; init_tr:pFVector3):FVector3;
var
  dx, dy, dz:single;
begin
  dx:=pqt^.x1;
  dy:=pqt^.y1;
  dz:=pqt^.z1;

  result.x:=dx*size_tr^.x+init_tr^.x;
  result.y:=dy*size_tr^.y+init_tr^.y;
  result.z:=dz*size_tr^.z+init_tr^.z;
end;

function Qt16ToT(pqt:pTOgfMotionKeyQT16; size_tr:pFVector3; init_tr:pFVector3):FVector3;
var
  dx, dy, dz:single;
begin
  dx:=pqt^.x1;
  dy:=pqt^.y1;
  dz:=pqt^.z1;

  result.x:=dx*size_tr^.x+init_tr^.x;
  result.y:=dy*size_tr^.y+init_tr^.y;
  result.z:=dz*size_tr^.z+init_tr^.z;
end;

function TOgfMotionBoneTrack.FramesCount(): integer;
begin
  result:=_frames_count;
end;

function TOgfMotionBoneTrack.GetKey(idx: integer; var key: TMotionKey): boolean;
var
  pqr, pqt:pointer;
begin
  result:=false;
  if not Loaded() then exit;
  if not _GetFrameData(idx, pqr, pqt) then exit;

  key.Q:=QrToQuat(pqr);

  if _is16bittransform then begin
    key.T:=Qt16ToT(pqt, @_sizeT, @_initT);
  end else begin
    key.T:=Qt8ToT(pqt, @_sizeT, @_initT);
  end;

  result:=true;
end;

function TOgfMotionBoneTrack.SetKey(idx: integer; key: TMotionKey): boolean;
var
  pqr:pTOgfMotionKeyQR;
  pqt8:pTOgfMotionKeyQT8;
  pqt16:pTOgfMotionKeyQT16;
  r_data:array of TOgfMotionKeyQR;
  i:integer;

  is_same:boolean;
  min_limit, max_limit:FVector3;

  trans:FVector3;
  qt_value:single;
const
  KEY_Quant16:integer=32767;
  KEY_Quant8:integer=127;

begin
  result:=false;
  if not Loaded() then exit;
  if (idx < 0) or (idx >= _frames_count) then exit;

  if not _rot_keys_present then begin
    is_same:=_CheckRKeySameWith(@_rot_keys_rawdata[0], @key.Q);
    if not is_same then begin
      // need to create array of keys same with initial
      setlength(r_data, _frames_count);
      for i:=0 to _frames_count-1 do begin
        r_data[i]:=pTOgfMotionKeyQR(@_rot_keys_rawdata[0])^;
      end;
      setlength(_rot_keys_rawdata, _frames_count*sizeof(TOgfMotionKeyQR));
      Move(r_data[0], _rot_keys_rawdata[0], _frames_count*sizeof(TOgfMotionKeyQR));
      setlength(r_data, 0);
      _rot_keys_present:=true;
    end;
  end;

  if _rot_keys_present then begin
    pqr:=@(pTOgfMotionKeyQR(@_rot_keys_rawdata[0]))[idx];
    pqr^.w:= clamp(key.q.w * KEY_Quant16, -KEY_Quant16, KEY_Quant16);
    pqr^.x:= clamp(key.q.x * KEY_Quant16, -KEY_Quant16, KEY_Quant16);
    pqr^.y:= clamp(key.q.y * KEY_Quant16, -KEY_Quant16, KEY_Quant16);
    pqr^.z:= clamp(key.q.z * KEY_Quant16, -KEY_Quant16, KEY_Quant16);
  end;

  if not _trans_keys_present then begin
    is_same:= (_is16bittransform and _CheckT16KeySameWith(@_trans_keys_rawdata[0], @key.T)) or (not _is16bittransform and _CheckT8KeySameWith(@_trans_keys_rawdata[0], @key.T));
    if not is_same then begin
      _CreateTransKeysFromInit();
    end;
  end;

  if _trans_keys_present then begin
    if not _CheckTransWithinLimits(key.T, min_limit, max_limit) then begin
      _RebuildTransKeysForNewLimits(min_limit, max_limit);
    end;

    trans:=v_sub(@key.T, @_initT);

    if _is16bittransform then begin
      pqt16:=@(pTOgfMotionKeyQT16(@_trans_keys_rawdata[0]))[idx];

      if abs(_sizeT.x) * KEY_Quant16 > EPS  then begin
        qt_value:= trans.x / _sizeT.x;
        pqt16^.x1:=clamp(qt_value, -KEY_Quant16, KEY_Quant16);
      end else begin
        pqt16^.x1:=0;
      end;

      if abs(_sizeT.y) * KEY_Quant16 > EPS then begin
        qt_value:= trans.y / _sizeT.y;
        pqt16^.y1:=clamp(qt_value, -KEY_Quant16, KEY_Quant16);
      end else begin
        pqt16^.y1:=0;
      end;

      if abs(_sizeT.z) * KEY_Quant16 > EPS then begin
        qt_value:= trans.z / _sizeT.z;
        pqt16^.z1:=clamp(qt_value, -KEY_Quant16, KEY_Quant16)
      end else begin
        pqt16^.z1:=0;
      end;
    end else begin
      pqt8:=@(pTOgfMotionKeyQT8(@_trans_keys_rawdata[0]))[idx];

      if abs(_sizeT.x) * KEY_Quant8 > EPS then begin
        qt_value:= trans.x / _sizeT.x;
        pqt8^.x1:=clamp(qt_value, -KEY_Quant8, KEY_Quant8);
      end else begin
        pqt8^.x1:=0;
      end;

      if abs(_sizeT.y) * KEY_Quant8 > EPS then begin
        qt_value:= trans.y / _sizeT.y;
        pqt8^.y1:=clamp(qt_value, -KEY_Quant8, KEY_Quant8);
      end else begin
        pqt8^.y1:=0;
      end;

      if abs(_sizeT.z) * KEY_Quant8 > EPS then begin
        qt_value:= trans.z / _sizeT.z;
        pqt8^.z1:=clamp(qt_value, -KEY_Quant8, KEY_Quant8)
      end else begin
        pqt8^.z1:=0;
      end;
    end;

  end;

  result:=true;
end;

function TOgfMotionBoneTrack.ChangeFramesCount(new_frames_count: integer): boolean;
var
  i:integer;
  pqr:pTOgfMotionKeyQR;
  pqt:pointer;
  pqt8:pTOgfMotionKeyQT8;
  pqt16:pTOgfMotionKeyQT16;
begin
  result:=false;
  if not Loaded() then exit;

  if _rot_keys_present then begin
    setlength(_rot_keys_rawdata, new_frames_count*sizeof(TOgfMotionKeyQR));
  end;

  if _trans_keys_present then begin
    if _is16bittransform then begin
      setlength(_trans_keys_rawdata, new_frames_count*sizeof(TOgfMotionKeyQT16));
    end else begin
      setlength(_trans_keys_rawdata, new_frames_count*sizeof(TOgfMotionKeyQT8));
    end;
  end;

  if new_frames_count > _frames_count then begin
    // copy QR and QT of the last frame to new frames
    if _rot_keys_present then begin
      if not _GetFrameData(_frames_count-1, pqr, pqt) then exit;
      for i:=_frames_count to new_frames_count-1 do begin
        pTOgfMotionKeyQR(@_rot_keys_rawdata[i*sizeof(TOgfMotionKeyQR)])^:=pqr^;
      end;
    end;

    if _trans_keys_present then begin
      if not _GetFrameData(_frames_count-1, pqr, pqt) then exit;
      for i:=_frames_count to new_frames_count-1 do begin
        if _is16bittransform then begin
          pqt16:=pqt;
          pTOgfMotionKeyQT16(@_trans_keys_rawdata[i*sizeof(TOgfMotionKeyQT16)])^:=pqt16^;
        end else begin
          pqt8:=pqt;
          pTOgfMotionKeyQT8(@_trans_keys_rawdata[i*sizeof(TOgfMotionKeyQT8)])^:=pqt8^;
        end;
      end;
    end;
  end;

  if new_frames_count <= 1 then begin
    _trans_keys_present:=false;
    _rot_keys_present:=false;
  end;


  _frames_count:=new_frames_count;
  result:=true;
end;

function TOgfMotionBoneTrack.Copy(from: TOgfMotionBoneTrack): boolean;
begin
  result:=false;
  Reset();

  _loaded:=from._loaded;
  _rot_keys_present:=from._rot_keys_present;
  _trans_keys_present:=from._trans_keys_present;
  _is16bittransform:=from._is16bittransform;
  _frames_count:=from._frames_count;
  _sizeT:=from._sizeT;
  _initT:=from._initT;

  setlength(_rot_keys_rawdata, length(from._rot_keys_rawdata));
  Move(from._rot_keys_rawdata[0], _rot_keys_rawdata[0], length(from._rot_keys_rawdata));

  setlength(_trans_keys_rawdata, length(from._trans_keys_rawdata));
  Move(from._trans_keys_rawdata[0], _trans_keys_rawdata[0], length(from._trans_keys_rawdata));

  result:=true;
end;

function TOgfMotionBoneTrack.MergeWithTrack(second: TOgfMotionBoneTrack): boolean;
var
  i:integer;
  min_limit, max_limit:FVector3;
  k:TMotionKey;
  within_limits:boolean;
  old_frames_count:integer;
begin
  result:=false;
  if not Loaded() then exit;
  if not second.Loaded() then exit;



  // Determine new translation limits
  _GetCurrentTransLimits(min_limit, max_limit);
  within_limits:=true;
  for i:=0 to second.FramesCount()-1 do begin
    if not second.GetKey(i, k) then exit;
    within_limits:=_CheckTransWithinLimits(k.T, min_limit, max_limit, false) and within_limits;
  end;

  // Recalculate QTs if limits are changed
  if not within_limits then begin
    // Automatically means there is a motion, so we definitely need keys
    if not _trans_keys_present then begin
      _CreateTransKeysFromInit();
    end;
    if not _RebuildTransKeysForNewLimits(min_limit, max_limit) then exit;
  end;

  old_frames_count:=FramesCount();
  if not ChangeFramesCount(old_frames_count+second.FramesCount()) then exit;
  for i:=0 to second.FramesCount()-1 do begin
    if not second.GetKey(i, k) or not SetKey(old_frames_count+i, k) then begin
      ChangeFramesCount(old_frames_count);
      exit;
    end;
  end;

  result:=true;
end;

{ TOgfMotionTrack }

function TOgfMotionTrack._SwapBones(idx1: integer; idx2: integer): boolean;
var
  tmp:TOgfMotionBoneTrack;
begin
  result:=false;
  if not Loaded() then exit;
  if (idx1<0) or (idx1>=length(_bone_tracks)) then exit;
  if (idx2<0) or (idx2>=length(_bone_tracks)) then exit;

  tmp:=_bone_tracks[idx1];
  _bone_tracks[idx1]:=_bone_tracks[idx2];
  _bone_tracks[idx2]:=tmp;

  result:=true;
end;

constructor TOgfMotionTrack.Create;
begin
  setlength(_bone_tracks, 0);
  _loaded:=false;
  _frames_count:=0;
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
  _frames_count:=0;
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
    _frames_count:=PCardinal(PAnsiChar(rawdata))^;
    if not AdvanceString(rawdata, sz) then exit;

    while length(rawdata)>0 do begin
      i:=length(_bone_tracks);
      setlength(_bone_tracks, i+1);
      _bone_tracks[i]:=TOgfMotionBoneTrack.Create();
      sz:=_bone_tracks[i].Deserialize(rawdata, _frames_count);

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
  result:=result+SerializeCardinal(_frames_count);

  for i:=0 to length(_bone_tracks)-1 do begin
    result:=result+_bone_tracks[i].Serialize();
  end;

end;

function TOgfMotionTrack.AddBone(default_key: TMotionKey): integer;
var
  i:integer;
begin
  result:=-1;
  if not Loaded() then exit;

  i:=length(_bone_tracks);
  setlength(_bone_tracks, i+1);
  _bone_tracks[i]:=TOgfMotionBoneTrack.Create(default_key, _frames_count);

  result:=i;
end;

function TOgfMotionTrack.RemoveBone(track_bone_idx:integer): boolean;
var
  i:integer;
begin
  result:=false;
  if not Loaded() then exit;

  if (track_bone_idx>=0) and (track_bone_idx < length(_bone_tracks)) then begin
    _bone_tracks[track_bone_idx].Free();
    for i:=track_bone_idx to length(_bone_tracks)-2 do begin
      _bone_tracks[i]:=_bone_tracks[i+1];
    end;
    setlength(_bone_tracks, length(_bone_tracks)-1);
  end;
end;

function TOgfMotionTrack.ChangeFramesCount(new_frames_count: integer): boolean;
var
  i:integer;
begin
  result:=false;
  if not Loaded() then exit;

  result:=true;
  for i:=0 to length(_bone_tracks)-1 do begin
    result:=_bone_tracks[i].ChangeFramesCount(new_frames_count) and result;
  end;

  if result then begin
    _frames_count:=new_frames_count;
  end;
end;

function TOgfMotionTrack.GetFramesCount(): integer;
begin
  result:=_frames_count;
end;

procedure TOgfMotionTrack.SetName(name: string);
begin
  _name:=name;
end;

function TOgfMotionTrack.GetBoneKey(track_bone_idx: integer; key_idx: integer; var k: TMotionKey): boolean;
begin
  result:=false;
  if not Loaded() then exit;
  if (track_bone_idx>=0) and (track_bone_idx < length(_bone_tracks)) then begin
    result:=_bone_tracks[track_bone_idx].GetKey(key_idx, k);
  end;
end;

function TOgfMotionTrack.SetBoneKey(track_bone_idx: integer; key_idx: integer; k: TMotionKey): boolean;
begin
  result:=false;
  if not Loaded() then exit;

  if (track_bone_idx>=0) and (track_bone_idx < length(_bone_tracks)) then begin
    result:=_bone_tracks[track_bone_idx].SetKey(key_idx, k);
  end;
end;

function TOgfMotionTrack.Copy(from: TOgfMotionTrack): boolean;
var
  i:integer;
begin
  result:=false;
  Reset();

  _name:=from._name;
  _loaded:=from._loaded;
  _frames_count:=from._frames_count;


  setlength(_bone_tracks, length(from._bone_tracks));
  for i:=0 to length(_bone_tracks)-1 do begin
    _bone_tracks[i]:=nil;
  end;

  for i:=0 to length(_bone_tracks)-1 do begin
    _bone_tracks[i]:=TOgfMotionBoneTrack.Create();
    if not _bone_tracks[i].Copy(from._bone_tracks[i]) then begin
      Reset();
      exit;
    end;
  end;

  result:=true;
end;

function TOgfMotionTrack.MergeWithTrack(second: TOgfMotionTrack): boolean;
var
  i:integer;
begin
  result:=false;
  if not Loaded() then exit;
  if not second.Loaded() then exit;
  if length(_bone_tracks)<>length(second._bone_tracks) then exit;

  _frames_count:=_frames_count+second._frames_count;
  result:=true;
  for i:=0 to length(_bone_tracks)-1 do begin
    result:= _bone_tracks[i].MergeWithTrack(second._bone_tracks[i]) and result;
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

function TOgfMotionTracksContainer.MotionTracksCount(): integer;
begin
  result:=0;
  if not Loaded() then exit;

  result:=length(_motions);
end;

function TOgfMotionTracksContainer.GetMotionTrack(idx: integer): TOgfMotionTrack;
begin
  result:=nil;
  if not Loaded() then exit;

  if (idx >= 0) and (idx < length(_motions)) then begin
    result:=_motions[idx];
  end;
end;

function TOgfMotionTracksContainer._CopyDataIntoNewTrack(track: TOgfMotionTrack; new_name: string): integer;
var
  i:integer;
  new_track:TOgfMotionTrack;
begin
  result:=-1;
  if not Loaded() then exit();

  new_track:=TOgfMotionTrack.Create();

  try
    if new_track.Copy(track) then begin
      new_track.SetName(new_name);

      i:=length(_motions);
      setlength(_motions, i+1);
      _motions[i]:=new_track;

      result:=i;
    end;
  finally
    if result < 0 then begin
      FreeAndNil(new_track);
    end;
  end;
end;

function TOgfMotionTracksContainer.DuplicateTrack(idx: integer; new_name: string): integer;
var
  i:integer;
begin
  result:=-1;
  if not Loaded() then exit();

  if (idx >= 0) and (idx < length(_motions)) then begin
    result:=_CopyDataIntoNewTrack(_motions[idx], new_name);
  end;
end;

function TOgfMotionTracksContainer.RemoveTrack(idx: integer): boolean;
var
  i:integer;
begin
  result:=false;
  if not Loaded() then exit();
  if (idx >= 0) and (idx < length(_motions)) then begin
    _motions[idx].Free;
    for i:=idx to length(_motions)-2 do begin
      _motions[idx]:=_motions[idx+1];
    end;
    setlength(_motions, length(_motions)-1);

    result:=true;
  end;
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

function TOgfSkeleton.SerializeBoneIKData(id: integer): string;
var
  ikd:TOgfBoneIKData;
begin
  result:='';
  if not Loaded() then exit;
  ikd:=_data.ik.Get(id);
  if ikd=nil then exit;
  result:=ikd.Serialize();
end;

function TOgfSkeleton.DeserializeBoneIKData(id: integer; s: string): boolean;
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

procedure TOgfTrisContainer._RemoveAllTrisNotInCurrentLod();
var
  i, start:integer;
begin
  if IsLodAssigned() then begin
    start:=_GetTriangleIdByOffset(_current_lod_params.offset);

    for i:=0 to _current_lod_params.num_tris-1 do begin
      _tris[i]:=_tris[start+i];
    end;
    setlength(_tris, _current_lod_params.num_tris);
    _current_lod_params.offset:=0;
    _current_lod_params.num_tris:=0;
    _current_lod_params.num_verts:=0;
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

  if (params.offset = 0) and (params.num_tris = TrisCountTotal()) then begin
    // This "lod level" consists from the full model, so we can assume there is no "lod" at all
    _current_lod_params.num_tris:=0;
    _current_lod_params.num_verts:=0;
    _current_lod_params.offset:=0;
    result:=true;
  end else begin
    tri_id:=_GetTriangleIdByOffset(params.offset);
    if (tri_id < 0) or (tri_id+params.num_tris > length(_tris)) then exit;
    _current_lod_params:=params;
    result:=true;
  end;
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

function TOgfTrisContainer.GetTriangle(idx: integer; for_current_lod: boolean; var t: TOgfTriangle): boolean;
var
  lod_start_idx:integer;
begin
  result:=false;
  if not Loaded() then exit;

  if not for_current_lod or not IsLodAssigned() then begin
    if (idx<0) or (idx>=length(_tris)) then exit;
    t:=_tris[idx];
    result:=true;
  end else begin
    if (idx<0) or (idx>=_current_lod_params.num_tris) then exit;
    lod_start_idx:=_GetTriangleIdByOffset(_current_lod_params.offset);
    t:=_tris[idx+lod_start_idx];
    result:=true;
  end;
end;

function TOgfTrisContainer._FilterVertices(var filter: TVertexFilterItems; swr_data: TOgfSwiContainer): boolean;
var
  i, newi:integer;
  tris_remap_indices:TTrisRemapIndices;
  swi:TOgfSlideWindowItem;
begin
  result:=false;

  if not Loaded() then exit;

  if swr_data <> nil then begin
    setlength(tris_remap_indices, length(_tris));
    for i:=0 to length(tris_remap_indices)-1 do begin
      tris_remap_indices[i]:=-1; // by default mark tris as deleted
    end;
  end;

  newi:=0;
  for i:=0 to length(_tris)-1 do begin
    if not ((filter[_tris[i].v1].need_remove) or (filter[_tris[i].v2].need_remove) or (filter[_tris[i].v3].need_remove)) then begin
      _tris[newi].v1:=filter[_tris[i].v1].new_id;
      _tris[newi].v2:=filter[_tris[i].v2].new_id;
      _tris[newi].v3:=filter[_tris[i].v3].new_id;

      if swr_data <> nil then begin
        tris_remap_indices[i]:=newi;
      end;

      newi:=newi+1;
    end;
  end;

  if IsLodAssigned() then begin
    swi:=_CorrectSwi(_current_lod_params, tris_remap_indices);
    AssignLod(swi);
  end;

  if swr_data <> nil then begin
    for i:=swr_data.GetLodLevelsCount()-1 downto 0 do begin
      swi:=swr_data.GetLodLevelParams(i);
      swi:=_CorrectSwi(swi, tris_remap_indices);
      swr_data._UpdateLodLevelData(i, swi);
    end;
  end;

  setlength(tris_remap_indices, 0);
  setlength(_tris, newi);

  result:=true;
end;

function TOgfTrisContainer._CorrectSwi(swi: TOgfSlideWindowItem; remap: TTrisRemapIndices): TOgfSlideWindowItem;
var
  i, idx:integer;
  start:integer;
  minvertexid, maxvertexid:cardinal;
  search_for_start:boolean;
begin
  minvertexid:=$FFFFFFFF;
  maxvertexid:=0;


  start:=_GetTriangleIdByOffset(swi.offset);
  search_for_start:=true;
  result.num_tris:=0;
  result.num_verts:=0;
  result.offset:=0;
  for i:=0 to swi.num_tris-1 do begin
    idx:=i+start;
    if remap[idx] >=0 then begin
      if search_for_start then begin
        search_for_start:=false;
        result.offset:=(remap[idx] * sizeof(TOgfTriangle)) div sizeof(TOgfVertexIndex);
      end;
      result.num_tris:=result.num_tris+1;

      if _tris[remap[idx]].v1 > maxvertexid then maxvertexid:=_tris[remap[idx]].v1;
      if _tris[remap[idx]].v2 > maxvertexid then maxvertexid:=_tris[remap[idx]].v2;
      if _tris[remap[idx]].v3 > maxvertexid then maxvertexid:=_tris[remap[idx]].v3;

      if _tris[remap[idx]].v1 < minvertexid then minvertexid:=_tris[remap[idx]].v1;
      if _tris[remap[idx]].v2 < minvertexid then minvertexid:=_tris[remap[idx]].v2;
      if _tris[remap[idx]].v3 < minvertexid then minvertexid:=_tris[remap[idx]].v3;
    end;
  end;

  if result.num_tris>0 then begin
    result.num_verts:=maxvertexid - minvertexid+1;
  end;

end;

{ TOgfSwiContainer }

procedure TOgfSwiContainer._ResetWithSingleReplacement(w: TOgfSlideWindowItem);
begin
  SetLength(_lods, 1);
  _lods[0]:=w;
end;

function TOgfSwiContainer._UpdateLodLevelData(idx: integer; swi: TOgfSlideWindowItem): boolean;
var
  i:integer;
begin
  result:=false;
  if not Loaded() then exit;

  if (idx<0) or (idx>=length(_lods)) then exit;
  _lods[idx]:=swi;
  result:=true;

  if (swi.num_tris = 0) or (swi.num_verts=0) then begin
    for i:=idx to length(_lods)-2 do begin
      _lods[i]:=_lods[i+1];
    end;
    setlength(_lods, length(_lods)-1);
  end;
end;

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

function TOgfSwiContainer.GetLodLevelParams(level_id: integer): TOgfSlideWindowItem;
begin
  result.num_tris:=0;
  result.num_verts:=0;
  result.offset:=0;
  if not Loaded() then exit;
  if (level_id < 0) then begin
    level_id:=0;
  end;
  if (level_id >= GetLodLevelsCount()) then begin
    level_id:=GetLodLevelsCount()-1;
  end;
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

    if except_bone_idx >= 0 then begin
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
  result:=bone.weight<>0;
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

function TOgfChild.GetLodLevels(): integer;
begin
  result:=0;

  if Loaded() and _swr.Loaded() then begin
    result:=_swr.GetLodLevelsCount();
  end;
end;

function TOgfChild.AssignLodLevel(level: integer): boolean;
begin
  result:=false;
  if not Loaded then exit;
  if not _swr.Loaded() then exit;
  if (level<0) or (level>=_swr.GetLodLevelsCount()) then exit;
  result:=_tris.AssignLod(_swr.GetLodLevelParams(level));
end;

function TOgfChild.RemoveUnactiveLodsData(): boolean;
var
  filters:TVertexFilterItems;
  i:integer;
  t:TOgfTriangle;
  w:TOgfSlideWindowItem;
begin
  result:=false;
  if not Loaded() then exit;

  result:=true;
  if not _swr.Loaded() then exit;
  if not _tris.IsLodAssigned() then exit;

  result:=false;
  w:=_tris.AssignedLodParams();
  setlength(filters, GetVerticesCount());
  try
    // iterate over all tris from the selected lod level, create filter map of used vertices
    for i:=0 to length(filters)-1 do begin
      filters[i].need_remove:=true;
    end;

    for i:=0 to GetTrisCountInCurrentLod()-1 do begin
      if not _tris.GetTriangle(i, true, t) then exit;
      filters[t.v1].need_remove:=false;
      filters[t.v2].need_remove:=false;
      filters[t.v3].need_remove:=false;
    end;

    // execute filter vertices using filtering map
    if not _verts._FilterVertices(filters) then exit;
    // kill unused tris outside sliding window
    _tris._RemoveAllTrisNotInCurrentLod();
    //remap vertices indices in tris
    if not _tris._FilterVertices(filters, nil) then exit;

    // modify swr data
    if _hdr.ogf_type = MT_SKELETON_GEOMDEF_PM then begin
      _hdr.ogf_type:=MT_SKELETON_GEOMDEF_ST;
      _swr.Reset;
    end else begin
      w.offset:=0;
      _swr._ResetWithSingleReplacement(w);
    end;
    result:=true;
  finally
    setlength(filters, 0)
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

  if not _verts._FilterVertices(filter) then exit;
  if not _tris._FilterVertices(filter, _swr) then exit;

  result:=true;
end;

procedure TOgfChild.IterateVertices(cb: TVerticesIterationCallback; userdata: pointer);
begin
  if not Loaded() or (_verts.GetVerticesCount() = 0) then exit;
  _verts.IterateVertices(cb, userdata);
end;

type
 TRemovingVerticesIterationCbData = record
   usercb:TVerticesIterationCallback;
   userdata:pointer;
   filter:TVertexFilterItems;
 end;
 pTRemovingVerticesIterationCbData = ^TRemovingVerticesIterationCbData;

function RemovingVerticesIterationCb(vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; userdata:pointer):boolean;
var
  cbdata:pTRemovingVerticesIterationCbData;
begin
  cbdata:=pTRemovingVerticesIterationCbData(userdata);
  if cbdata^.usercb<>nil then begin
   cbdata^.filter[vertex_id].need_remove:=cbdata^.usercb(vertex_id, data, uv, links, cbdata^.userdata);
  end else begin
    cbdata^.filter[vertex_id].need_remove:=true;
  end;
  result:=true;
end;

function TOgfChild.RemoveVertices(cb: TVerticesIterationCallback; userdata: pointer): boolean;
var
  filter:TVertexFilterItems;
  cbdata:TRemovingVerticesIterationCbData;
begin
  result:=false;
  if not Loaded() or (_verts.GetVerticesCount() = 0) then exit;
  setlength(filter,_verts.GetVerticesCount());

  try
    // Iterate over all vertices and execute callback to decide which vertices are to remove
    cbdata.filter:=filter;
    cbdata.usercb:=cb;
    cbdata.userdata:=userdata;
    _verts.IterateVertices(@RemovingVerticesIterationCb, @cbdata);

    // Perform filtering
    result:=FilterVertices(filter);
  finally
    setlength(filter, 0);
  end;
end;

function TOgfChild.Scale(v: FVector3; pivot_point: FVector3; selection_callback: TVerticesIterationCallback; userdata: pointer): boolean;
begin
  if not Loaded() then begin
    result:=false;
  end else begin
    result:=_verts.ScaleVertices(@v, @pivot_point, selection_callback, userdata);
  end;
end;

function TOgfChild.Move(v: FVector3; selection_callback: TVerticesIterationCallback; userdata: pointer): boolean;
begin
  if not Loaded() then begin
    result:=false;
  end else begin
    result:=_verts.MoveVertices(v, selection_callback, userdata);
  end;
end;

function TOgfChild.RotateUsingStandartAxis(amount_radians: single; rotation_axis: TOgfRotationAxis; pivot_point: FVector3; selection_callback: TVerticesIterationCallback; userdata: pointer): boolean;
var
  m:FMatrix3x3;
  c,s:single;
begin
  if not Loaded() then begin
    result:=false;
  end else begin
    set_zero(m);
    c:=cos(amount_radians);
    s:=sin(amount_radians);

    case rotation_axis of
      OgfRotationAxisX: begin
        m.i.x:=1;
        m.j.y:=c;
        m.j.z:=-s;
        m.k.y:=s;
        m.k.z:=c;
      end;
      OgfRotationAxisY: begin
        m.i.x:=c;
        m.i.z:=s;
        m.j.y:=1;
        m.k.x:=-s;
        m.k.z:=c;
      end;
      OgfRotationAxisZ: begin
        m.i.x:=c;
        m.i.y:=-s;
        m.j.x:=s;
        m.j.y:=c;
        m.k.z:=1;
      end;
    end;
    result:=_verts.RotateVertices(@m, @pivot_point, selection_callback, userdata);
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

function TOgfVertsContainer.MoveVertices(offset: FVector3; selection_callback: TVerticesIterationCallback; userdata: pointer): boolean;
var
  i:integer;
  v:pTOgfVertexCommonData;
  puv:pFVector2;
  b:TVertexBones;
begin
  result:=false;
  if not Loaded() then exit;

  result:=true;
  b:=TVertexBones.Create();
  try
    for i:=0 to _verts_count-1 do begin
      v:=_GetVertexDataPtr(i);
      if v = nil then begin
        result:=false;
        continue;
      end;

      if selection_callback<>nil then begin
        puv:=_GetVertexUvDataPtr(i);
        if (puv = nil) or not _GetVertexBindings(i, b) then begin
          result:=false;
          continue;
        end;

        if not selection_callback(i, v, puv, b, userdata) then continue;
      end;

      v^.pos.x:=v^.pos.x+offset.x;
      v^.pos.y:=v^.pos.y+offset.y;
      v^.pos.z:=v^.pos.z+offset.z;
    end;

  finally
    FreeAndNil(b);
  end;
end;

function TOgfVertsContainer.ScaleVertices(factors: pFVector3; pivot_point: pFVector3; selection_callback: TVerticesIterationCallback; userdata: pointer): boolean;
var
  i:integer;
  v:pTOgfVertexCommonData;
  puv:pFVector2;
  b:TVertexBones;
begin
  result:=false;
  if not Loaded() then exit;

  result:=true;
  b:=TVertexBones.Create();
  try
    for i:=0 to _verts_count-1 do begin
      v:=_GetVertexDataPtr(i);
      if v = nil then begin
        result:=false;
        continue;
      end;

      if selection_callback<>nil then begin
        puv:=_GetVertexUvDataPtr(i);
        if (puv = nil) or not _GetVertexBindings(i, b) then begin
          result:=false;
          continue;
        end;

        if not selection_callback(i, v, puv, b, userdata) then continue;
      end;

      v_sub(@v^.pos, pivot_point);
      v^.pos.x:=v^.pos.x*factors^.x;
      v^.pos.y:=v^.pos.y*factors^.y;
      v^.pos.z:=v^.pos.z*factors^.z;
      v_add(@v^.pos, pivot_point)
    end;

  finally
    FreeAndNil(b);
  end;
end;

function TOgfVertsContainer.RotateVertices(m: pFMatrix3x3; pivot_point: pFVector3; selection_callback: TVerticesIterationCallback; userdata: pointer): boolean;
var
  i:integer;
  v:pTOgfVertexCommonData;
  puv:pFVector2;
  b:TVertexBones;
begin
  result:=false;
  if not Loaded() then exit;

  result:=true;
  b:=TVertexBones.Create();
  try
    for i:=0 to _verts_count-1 do begin
      v:=_GetVertexDataPtr(i);
      if v = nil then begin
        result:=false;
        continue;
      end;

      if selection_callback<>nil then begin
        puv:=_GetVertexUvDataPtr(i);
        if (puv = nil) or not _GetVertexBindings(i, b) then begin
          result:=false;
          continue;
        end;

        if not selection_callback(i, v, puv, b, userdata) then continue;
      end;

      v^.pos:=v_sub(@v^.pos, pivot_point);
      v^.pos:=m_mul(m, @v^.pos);
      v^.pos:=v_add(@v^.pos, pivot_point)
    end;

  finally
    FreeAndNil(b);
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

function TOgfVertsContainer._FilterVertices(var filter: TVertexFilterItems): boolean;
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

procedure TOgfVertsContainer.IterateVertices(cb: TVerticesIterationCallback; userdata: pointer);
var
  pvertex:pbyte;
  i:integer;

  puv:pFVector2;
  pdata:pTOgfVertexCommonData;
  links:cardinal;
  b:TVertexBones;
begin
  if not Loaded() or (_verts_count=0) then exit;
  links:=GetCurrentLinkType();
  if (links<>OGF_LINK_TYPE_1) and (links<>OGF_LINK_TYPE_2) and (links<>OGF_LINK_TYPE_3) and (links<>OGF_LINK_TYPE_4) then exit;

  b:=TVertexBones.Create();
  try
    for i:=0 to _verts_count-1 do begin
      b.Reset();
      if not _GetVertexBindings(i, b) then continue;

      if (links=OGF_LINK_TYPE_1) then begin
        pvertex:=@_raw_data[sizeof(TOgfVertsHeader)+i*sizeof(TOgfVertex1link)];
        pdata:=@pTOgfVertex1link(pvertex)^.spatial;
        puv:=@pTOgfVertex1link(pvertex)^.uv;
        if not cb(i, pdata, puv, b, userdata) then break;
      end else if (links=OGF_LINK_TYPE_2) then begin
        pvertex:=@_raw_data[sizeof(TOgfVertsHeader)+i*sizeof(TOgfVertex2link)];
        pdata:=@pTOgfVertex2link(pvertex)^.spatial;
        puv:=@pTOgfVertex2link(pvertex)^.uv;
        if not cb(i, pdata, puv, b, userdata) then break;
      end else if (links=OGF_LINK_TYPE_3) then begin
        pvertex:=@_raw_data[sizeof(TOgfVertsHeader)+i*sizeof(TOgfVertex3link)];
        pdata:=@pTOgfVertex3link(pvertex)^.spatial;
        puv:=@pTOgfVertex3link(pvertex)^.uv;
        if not cb(i, pdata, puv, b, userdata) then break;
      end else if (links=OGF_LINK_TYPE_4) then begin
        pvertex:=@_raw_data[sizeof(TOgfVertsHeader)+i*sizeof(TOgfVertex4link)];
        pdata:=@pTOgfVertex4link(pvertex)^.spatial;
        puv:=@pTOgfVertex4link(pvertex)^.uv;
        if not cb(i, pdata, puv, b, userdata) then break;
      end;
    end;
  finally
    FreeAndNil(b);
  end;
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

{ TOgfBaseFileParser }

function TOgfBaseFileParser._UpdateChunk(id: word; data: string): boolean;
var
  chunk:TChunkedOffset;
begin
  result:=false;
  // no need to check if loaded - we are operating just with source

  chunk:=_source.FindSubChunk(id);
  if (chunk=INVALID_CHUNK) or (not _source.EnterSubChunk(chunk)) then begin
    result:=(length(data)=0);
  end else begin
    if _source.ReplaceCurrentRawDataWithString(data) and _source.LeaveSubChunk() then begin
      result:=true;
    end;
  end;
end;

constructor TOgfBaseFileParser.Create;
begin
  _loaded:=false;
  _owns_source:=true;
  _source:=TChunkedMemory.Create();
end;

destructor TOgfBaseFileParser.Destroy;
begin
  if _owns_source then begin
    _source.Free();
  end;
  _loaded:=false;

  inherited Destroy;
end;

procedure TOgfBaseFileParser.Reset;
begin
  _loaded:=false;
end;

procedure TOgfBaseFileParser.ResetSource(new_source: TChunkedMemory);
begin
  if _owns_source then begin
    _source.Free();
  end;

  if new_source = nil then begin
    _owns_source:=true;
    _source:=TChunkedMemory.Create();
  end else begin
    _owns_source:=false;
    _source:=new_source;
  end;
end;

function TOgfBaseFileParser.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfBaseFileParser.Serialize(): string;
begin
  result:='';
  if not Loaded() then exit;
  if not UpdateSource() then exit;
  result:=_source.GetCurrentChunkRawDataAsString();
end;

function TOgfBaseFileParser.ReloadFromSource(): boolean;
begin
  result:=false;
  if not Loaded then exit;
  result:=Deserialize(_source.GetCurrentChunkRawDataAsString());
end;

function TOgfBaseFileParser.LoadFromFile(fname: string): boolean;
begin
  result:=false;
  ResetSource(nil);

  try
    if not _source.LoadFromFile(fname, 0) then exit;
    result:=Deserialize(_source.GetCurrentChunkRawDataAsString());
  except
    result:=false;
  end;

  if not result then Reset();
end;

function TOgfBaseFileParser.SaveToFile(fname: string): boolean;
begin
  result:=false;
  if not Loaded() then exit;
  if not UpdateSource() then exit;
  result:=_source.SaveToFile(fname);
end;

function TOgfBaseFileParser.LoadFromMem(addr: pointer; sz: cardinal): boolean;
var
  s:string;
  i:integer;
begin
  result:=false;
  if sz = 0 then exit;

  // TODO: optimize, no real need to re-construct data into string
  s:='';
  for i:=0 to sz-1 do begin
    s:=s+PAnsiChar(addr)[i];
  end;

  ResetSource(nil);
  _source.LoadFromString(s);
  result:=Deserialize(_source.GetCurrentChunkRawDataAsString());

  if not result then Reset();
end;

function TOgfBaseFileParser.LoadFromChunkedMem(mem: TChunkedMemory): boolean;
begin
  result:=false;
  ResetSource(nil);
  _source.Free();
  _source:=mem;
  _owns_source:=false;

  result:=Deserialize(mem.GetCurrentChunkRawDataAsString());

  if not result then begin
    Reset();
  end;
end;

{ TOgfAnimationsParser }

function TOgfAnimationsParser._GetMotionTrackByName(name: string): TOgfMotionTrack;
var
  anim_id:integer;
begin
  result:=nil;
  if not Loaded() then exit;

  anim_id:=GetAnimationIdByName(name);
  if anim_id < 0 then exit;

  result:=_tracks.GetMotionTrack(anim_id);
end;

function TOgfAnimationsParser._SwapIdxInTracksForBones(idx1: integer; idx2: integer): boolean;
var
  i,j:integer;
  track:TOgfMotionTrack;
begin
  result:=false;
  if _params._SwapTracksBonesIdx(idx1, idx2) then begin
    for i:=0 to _tracks.MotionTracksCount()-1 do begin
      track:=_tracks.GetMotionTrack(i);
      if track<>nil then begin
        if not track._SwapBones(idx1, idx2) then begin
          //revert
          for j:=0 to i-1 do begin
            track:=_tracks.GetMotionTrack(j);
            if track<>nil then begin
              track._SwapBones(idx1, idx2)
            end;
          end;
          _params._SwapTracksBonesIdx(idx1, idx2);
          exit;
        end;
      end;
    end;
  end;
  result:=true;
end;

function TOgfAnimationsParser._GenerateAnimationName(target_name: string): string;
var
  i:integer;
  new_name:string;
begin
  i:=1;
  new_name:=target_name;
  while (true) do begin
    if GetAnimationIdByName(new_name) < 0 then begin
      result:=new_name;
      exit;
    end;
    new_name:=target_name+inttostr(i);
    i:=i+1;
  end;

end;

constructor TOgfAnimationsParser.Create;
begin
  inherited;
  _tracks:=TOgfMotionTracksContainer.Create();
  _params:=TOgfMotionParamsContainer.Create();
end;

destructor TOgfAnimationsParser.Destroy;
begin
  _params.Free();
  _tracks.Free();
  inherited Destroy;
end;

procedure TOgfAnimationsParser.Reset;
begin
  _tracks.Reset();
  _params.Reset();
  inherited Reset;
end;

function TOgfAnimationsParser.Deserialize(rawdata: string): boolean;
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
    chunk:=mem.FindSubChunk(CHUNK_OGF_S_SMPARAMS);
    if (chunk = INVALID_CHUNK) or not mem.EnterSubChunk(chunk) then exit;
    r:=_params.Deserialize(mem.GetCurrentChunkRawDataAsString());
    mem.LeaveSubChunk();
    if not r then exit;

    chunk:=mem.FindSubChunk(CHUNK_OGF_S_MOTIONS);
    if (chunk = INVALID_CHUNK) or not mem.EnterSubChunk(chunk) then exit;
    r:=_tracks.Deserialize(mem.GetCurrentChunkRawDataAsString());
    mem.LeaveSubChunk();
    if not r then exit;

    Sanitize(nil);

    result:=true;
  finally
    mem.Free;

    if result then begin
      _loaded:=true;
    end else begin
      Reset;
    end;
  end;
end;

function TOgfAnimationsParser.UpdateSource(): boolean;
var
  params:string;
  tracks:string;
begin
  result:=false;
  if not Loaded() then exit;
  params:=_params.Serialize();
  tracks:=_tracks.Serialize();

  if not _UpdateChunk(CHUNK_OGF_S_SMPARAMS, params) then exit;
  if not _UpdateChunk(CHUNK_OGF_S_MOTIONS, tracks) then exit;

  result:=true;

end;

procedure TOgfAnimationsParser.Sanitize(skeleton: TOgfSkeleton);
var
 i, j, n:integer;
 is_broken:boolean;
 used_motion_ids:array of word;
 def:TOgfMotionDefData;
begin
  // count of animations in tracks and defs should be equal
  if _params.MotionsDefsCount() > _tracks.MotionTracksCount() then begin
    // remove extra defs
    for i:=_params.MotionsDefsCount()-1  downto _tracks.MotionTracksCount() do begin
      _params.RemoveMotionDef(i);
    end;
  end else if _params.MotionsDefsCount() < _tracks.MotionTracksCount() then begin
    // remove extra tracks
    for i:=_tracks.MotionTracksCount()-1  downto _params.MotionsDefsCount() do begin
      _tracks.RemoveTrack(i);
    end;
  end;

  // Check if motion_ids in defs matches its indices
  setlength(used_motion_ids, _params.MotionsDefsCount());
  for i:=0 to length(used_motion_ids)-1 do begin
    used_motion_ids[i]:=$FFFF;
  end;

  is_broken:=false;
  for i:=0 to _params.MotionsDefsCount()-1 do begin
    def:=_params.GetMotionDefByIdx(i);
    if length(def.name) > 0 then begin
      if def.motion_id >= _params.MotionsDefsCount() then begin
        is_broken:=true;
      end else begin
        for j:=0 to i-1 do begin
          if used_motion_ids[j]=def.motion_id then begin
            is_broken:=true;
            break;
          end;
        end;
        used_motion_ids[i]:=def.motion_id;
      end;

      if is_broken then begin
        break;
      end;
    end;
  end;
  setlength(used_motion_ids, 0);

  if is_broken then begin
    // motion indices in defs are broken, try to restore
    for i:=0 to _params.MotionsDefsCount()-1 do begin
      def:=_params.GetMotionDefByIdx(i);
      if length(def.name) > 0 then begin
        def.motion_id:=i;
        _params.UpdateMotionDefsForIdx(i, def);
      end;
    end;
  end;

  // compare animation names in tracks and defs, correct using values from defs
  for i:=0 to _params.MotionsDefsCount()-1 do begin
    def:=_params.GetMotionDefByIdx(i);
    if length(def.name) > 0 then begin
      _tracks.GetMotionTrack(def.motion_id).SetName(def.name);
    end;
  end;



  // check if GetBoneByIdxInTrack returns bone for every id ?
  // check if bone count & names corresponds with bones in the model
  // check bones indices in anims
end;

function TOgfAnimationsParser.RemoveBone(name: string): boolean;
var
  i, j:integer;
  removed_idx, cur_idx:integer;

  part_id, bone_id:integer;
  bone, part_bone:TOgfMotionBoneParams;
  track:TOgfMotionTrack;
  part:TOgfMotionBonePart;
begin
  result:=false;
  if not Loaded() then exit;

  if _params.FindBoneIdxsByName(name, part_id, bone_id) then begin
     bone:=_params.GetBone(part_id, bone_id);
     if bone<>nil then begin
       // remove from tracks
       for i:=0 to _tracks.MotionTracksCount()-1 do begin
         track:=_tracks.GetMotionTrack(i);
         if track<>nil then begin
           track.RemoveBone(bone.GetIdxInTracks());
         end;
       end;

       // remap indices
       removed_idx:=bone.GetIdxInTracks();
       for i:=0 to _params.GetBonePartsCount()-1 do begin
         part:=_params.GetBonePart(i);
         if part <> nil then begin
           for j:=0 to part.GetBonesCount()-1 do begin
             part_bone:=part.GetBoneByLocalIndex(j);

             if (part_bone <> nil) then begin
               cur_idx:=part_bone.GetIdxInTracks();
               if (cur_idx > removed_idx) then begin
                 part_bone._SetIdxInTracks(cur_idx-1);
               end;
             end;
           end;
         end;
       end;

       // remove from defs
       result:=_params.RemoveBone(part_id, bone_id);
     end;
  end;
end;

function TOgfAnimationsParser.GetAnimationFramesCount(anim_name: string): integer;
var
  track:TOgfMotionTrack;
begin
  result:=0;
  track:=_GetMotionTrackByName(anim_name);
  if track = nil then exit;
  result:=track.GetFramesCount();
end;

function TOgfAnimationsParser.GetAnimationKeyForBone(anim_name: string; bone_name: string; key_idx: integer; var k: TMotionKey): boolean;
var
  track:TOgfMotionTrack;
  part_id, bone_id, bone_id_in_track:integer;
  bone:TOgfMotionBoneParams;
begin
  result:=false;
  track:=_GetMotionTrackByName(anim_name);
  if track = nil then exit;

  if _params.FindBoneIdxsByName(bone_name, part_id, bone_id) then begin
    bone:=_params.GetBone(part_id, bone_id);
    if bone<>nil then begin
      bone_id_in_track:=bone.GetIdxInTracks();
      result:=track.GetBoneKey(bone_id_in_track, key_idx, k);
    end;
  end;
end;

function TOgfAnimationsParser.SetAnimationKeyForBone(anim_name: string; bone_name: string; key_idx: integer; k: TMotionKey): boolean;
var
  track:TOgfMotionTrack;
  part_id, bone_id, bone_id_in_track:integer;
  bone:TOgfMotionBoneParams;
begin
  result:=false;
  track:=_GetMotionTrackByName(anim_name);
  if track = nil then exit;

  if _params.FindBoneIdxsByName(bone_name, part_id, bone_id) then begin
    bone:=_params.GetBone(part_id, bone_id);
    if bone<>nil then begin
      bone_id_in_track:=bone.GetIdxInTracks();
      result:=track.SetBoneKey(bone_id_in_track, key_idx, k);
    end;
  end;
end;

function TOgfAnimationsParser.DuplicateAnimation(old_name: string; new_name: string): boolean;
var
  old_idx, new_idx, i:integer;
  def:TOgfMotionDefData;
begin
  result:=false;
  if not Loaded() then exit;

  old_idx:=GetAnimationIdByName(old_name);
  if old_idx < 0 then exit;

  def:=_params.GetMotionDefByIdx(old_idx);
  if def.name<>old_name then exit;

  new_idx:=_tracks.DuplicateTrack(old_idx, new_name);
  if new_idx < 0 then exit;

  def.name:=new_name;
  def.motion_id:=new_idx;
  i:=_params.AddMotionDef(def);

  if i < 0 then begin
    _tracks.RemoveTrack(new_idx);
  end else begin
    result:=true;
  end;
end;

function TOgfAnimationsParser.MergeAnimations(name_of_new: string; name_of_first: string; name_of_second: string): boolean;
var
  new_track, second_track:TOgfMotionTrack;
begin
  result:=false;

  second_track:=_GetMotionTrackByName(name_of_second);
  if second_track = nil then exit;

  if not DuplicateAnimation(name_of_first, name_of_new) then exit;

  new_track:=_GetMotionTrackByName(name_of_new);
  if new_track = nil then exit;

  result:=new_track.MergeWithTrack(second_track);
  if not result then begin
    DeleteAnimation(name_of_new);
  end;
end;

function TOgfAnimationsParser.DeleteAnimation(name: string): boolean;
var
  idx:integer;
begin
  result:=false;
  idx:=GetAnimationIdByName(name);
  if idx < 0 then exit;

  result:=true;
  result:=_tracks.RemoveTrack(idx) and result;
  result:=_params.RemoveMotionDef(idx) and result;
end;

type
  TAnimationTrackBonesRemapInfo = record
    target_idx:integer;
    source_idx:integer;
    bone_name:string;
  end;

function TOgfAnimationsParser.MergeContainers(source_to_merge: TOgfAnimationsParser): boolean;
var
  ap2:TOgfAnimationsParser;
  remap:array of TAnimationTrackBonesRemapInfo;
  i, j:integer;
  bone, bone2:TOgfMotionBoneParams;

  part_idx, bone_idx, idx:integer;
  need_remap:boolean;
  need_free_ap2:boolean;
  data:string;
  def:TOgfMotionDefData;
  track:TOgfMotionTrack;

begin
  result:=false;
  if not Loaded() then exit;
  if not source_to_merge.Loaded() then exit;

  // Let's check if second container has all bones with appropriate indices
  setlength(remap, _params.GetTotalBonesCount());
  need_remap:=false;
  need_free_ap2:=false;
  try
    for i:=0 to length(remap)-1 do begin
      bone:=_params.GetBoneByIdxInTrack(i);
      if bone = nil then exit;
      if bone.GetIdxInTracks()<>i then exit;
      remap[i].bone_name:=bone.GetName();
      remap[i].target_idx:=bone.GetIdxInTracks();

      if not source_to_merge._params.FindBoneIdxsByName(remap[i].bone_name, part_idx, bone_idx) then exit;
      bone2:=source_to_merge._params.GetBone(part_idx, bone_idx);
      if bone2 = nil then exit;

      remap[i].source_idx:=bone2.GetIdxInTracks();
      if remap[i].source_idx < 0 then exit;
      if not need_remap and (remap[i].source_idx <> remap[i].target_idx) then begin
        need_remap:=true;
      end;
    end;

    if need_remap then begin
      // Create duplicate for remap
      ap2:=TOgfAnimationsParser.Create();
      need_free_ap2:=true;
      data:=source_to_merge.Serialize();
      if not ap2.Deserialize(data) then exit;

      for i:=0 to ap2._params.GetTotalBonesCount()-1 do begin
        bone:=_params.GetBoneByIdxInTrack(i);
        if bone = nil then exit;
        idx:=bone.GetIdxInTracks();
        if idx < 0 then exit;

        // find new index in table
        for j:=0 to length(remap)-1 do begin
          if remap[j].source_idx = idx then begin
            if remap[j].source_idx<>remap[j].target_idx then begin
              ap2._SwapIdxInTracksForBones(remap[j].source_idx, remap[j].target_idx);
            end;
            break;
          end;
        end;
      end;

      // Check if all correct now
      for i:=0 to length(remap)-1 do begin
        if not ap2._params.FindBoneIdxsByName(remap[i].bone_name, part_idx, bone_idx) then exit;
        bone:=_params.GetBone(part_idx, bone_idx);
        if bone = nil then exit;

        if bone.GetIdxInTracks() <> remap[i].target_idx then exit;
      end;
    end else if self = source_to_merge then begin
      ap2:=TOgfAnimationsParser.Create();
      need_free_ap2:=true;
      data:=source_to_merge.Serialize();
      if not ap2.Deserialize(data) then exit;
    end else begin
      ap2:=source_to_merge;
    end;

    // Merge tracks and info
    for i:=0 to ap2._params.MotionsDefsCount()-1 do begin
      def:=ap2._params.GetMotionDefByIdx(i);
      if def.motion_id<>$FFFF then begin
        track:=ap2._tracks.GetMotionTrack(def.motion_id);

        if track<>nil then begin
           def.name:=_GenerateAnimationName(def.name);
           idx:=_tracks._CopyDataIntoNewTrack(track, def.name);
           if idx >= 0 then begin
             def.motion_id:=idx;

             if _params.AddMotionDef(def) < 0 then begin
               _tracks.RemoveTrack(idx);
             end;
           end;
        end;
      end;
    end;

    result:=true;
  finally
    setlength(remap, 0);
    if need_free_ap2 then begin
      FreeAndNil(ap2);
    end;
  end;
end;

function TOgfAnimationsParser.ChangeAnimationFramesCount(anim_name: string; new_frames_count: integer): boolean;
var
  track:TOgfMotionTrack;
begin
  result:=false;
  track:=_GetMotionTrackByName(anim_name);
  if track = nil then exit;
  result:=track.ChangeFramesCount(new_frames_count);
end;

function TOgfAnimationsParser.AnimationsCount(): integer;
begin
  result:=0;
  if not Loaded() then exit;

  result:=_params.MotionsDefsCount();
end;

function TOgfAnimationsParser.GetAnimationParams(idx: integer): TOgfMotionDefData;
begin
  // if not loaded - returns default MotionDef
  result:=_params.GetMotionDefByIdx(idx);
end;

function TOgfAnimationsParser.GetAnimationIdByName(name: string): integer;
begin
  result:=-1;
  if not Loaded() then exit;

  result:=_params.GetMotionIdxForName(name);
end;

function TOgfAnimationsParser.UpdateAnimationParams(idx: integer; d: TOgfMotionDefData): boolean;
begin
  result:=false;
  if not Loaded() then exit;

  result:=_params.UpdateMotionDefsForIdx(idx, d);
end;

function TOgfAnimationsParser.AddBone(name: string; default_key: TMotionKey; part_id: integer): boolean;
var
  i, j:integer;
  boneid_new, boneid_old, bonepart_id:integer;
  track:TOgfMotionTrack;
begin
  result:=false;
  if not Loaded() then exit;
  if _params.FindBoneIdxsByName(name, bonepart_id, boneid_new) then exit;
  if _params.GetBonePartsCount() <= part_id then exit;

  boneid_old:=-1;
  boneid_new:=-1;

  for i:=0 to _tracks.MotionTracksCount()-1 do begin
    track:=_tracks.GetMotionTrack(i);
    if track<>nil then begin
      boneid_new:=track.AddBone(default_key);
      if i > 0 then begin
        if boneid_new<>boneid_old then begin
          //revert changes
          track.RemoveBone(boneid_new);
          for j:=0 to i-1 do begin
            track:=_tracks.GetMotionTrack(j);
            track.RemoveBone(boneid_old);
          end;
          exit;
        end;
      end;
      boneid_old:=boneid_new;
    end;
  end;

  result:=_params.AddBone(name, boneid_new, part_id);
end;

{ TOgfParser }

constructor TOgfParser.Create;
begin
  inherited;

  _children:=TOgfChildrenContainer.Create();
  _bone_names:=TOgfBonesContainer.Create();
  _ikdata:=TOgfBonesIKDataContainer.Create();
  _userdata:=TOgfUserdataContainer.Create();
  _lodref:=TOgfLodRefsContainer.Create();

  _skeleton:=TOgfSkeleton.Create();
  _animations:=TOgfAnimationsParser.Create();
end;

destructor TOgfParser.Destroy;
begin
  _animations.Free();
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
  _animations.Free();
  _animations:=TOgfAnimationsParser.Create();

  _children.Reset();
  _bone_names.Reset();
  _ikdata.Reset();
  _userdata.Reset();
  _lodref.Reset();

  inherited Reset;
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
      chunk:=mem.FindSubChunk(CHUNK_OGF_CHILDREN);
      if (chunk = INVALID_CHUNK) or not mem.EnterSubChunk(chunk) then exit;
      r:=_children.Deserialize(mem.GetCurrentChunkRawDataAsString());
      mem.LeaveSubChunk();
      if not r then exit;

      chunk:=mem.FindSubChunk(CHUNK_OGF_S_BONE_NAMES);
      if (chunk = INVALID_CHUNK) or not mem.EnterSubChunk(chunk) then exit;
      r:=_bone_names.Deserialize(mem.GetCurrentChunkRawDataAsString());
      mem.LeaveSubChunk();
      if not r then exit;

      chunk:=mem.FindSubChunk(CHUNK_OGF_S_IKDATA);
      if (chunk = INVALID_CHUNK) or not mem.EnterSubChunk(chunk) then exit;
      r:=_ikdata.Deserialize(mem.GetCurrentChunkRawDataAsString());
      mem.LeaveSubChunk();
      if not r then exit;

      chunk:=mem.FindSubChunk(CHUNK_OGF_S_USERDATA);
      if (chunk <> INVALID_CHUNK) and mem.EnterSubChunk(chunk) then begin
        r:=_userdata.Deserialize(mem.GetCurrentChunkRawDataAsString());
        mem.LeaveSubChunk();
        if not r then exit;
      end;

      chunk:=mem.FindSubChunk(CHUNK_OGF_S_LODS);
      if (chunk <> INVALID_CHUNK) and mem.EnterSubChunk(chunk) then begin
        r:=_lodref.Deserialize(mem.GetCurrentChunkRawDataAsString());
        mem.LeaveSubChunk();
        if not r then exit;
      end;

      if not _skeleton.Build(_bone_names, _ikdata) then exit;

      if _animations.LoadFromChunkedMem(mem) then begin
        _animations.ResetSource(_source);
      end else begin
        _animations.Free();
        _animations:=TOgfAnimationsParser.Create();
      end;

      result:=true;
  finally
    mem.Free;

    if result then begin
      _loaded:=true;
    end else begin
      Reset;
    end;
  end;
end;

function TOgfParser.UpdateSource(): boolean;
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

  if _animations.Loaded() then begin
    _animations.UpdateSource();
  end;

  result:=true;

end;

procedure TOgfParser.ResetSource(new_source: TChunkedMemory);
begin
  if _animations.Loaded() then begin
    _animations.ResetSource(new_source);
  end;
  inherited ResetSource(new_source);
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

function TOgfParser.Animations(): TOgfAnimationsParser;
begin
  result:=nil;
  if not Loaded() then exit;

  result:=_animations;
end;


end.


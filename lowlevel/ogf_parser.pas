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
  pTOgfBBox = ^TOgfBBox;

  TOgfBSphere = packed record
    c:FVector3;
    r:single;
  end;
  pTOgfBSphere = ^TOgfBSphere;

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
    _is_normalized:boolean;

    procedure _SortByWeights();
    procedure SimplifyLinks();
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
    function ChangeLinkType(new_links_count:integer):boolean;
    procedure NormalizeWeights(except_bone_idx:integer=-1);
    function ExportSortedData(var out_bones:TVertexBones):boolean;
  end;

  { TOgfVertsContainer }
  TVertexFlaggedItem = packed record
    is_flagged:boolean;
    new_id:cardinal;
  end;
  TVertexFlaggedItems = array of TVertexFlaggedItem;

  TVerticesIterationCallback = function (vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; userdata:pointer):boolean;
  TVerticesBindCallback = function (vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; target_boneid:cardinal; userdata:pointer):boolean;
  TOgfVertsContainer = class
  private
    _link_type:cardinal;
    _verts_count:cardinal;
    _raw_data:array of byte;
    function _GetVertexDataPtr(id:cardinal):pTOgfVertexCommonData;
    function _GetVertexUvDataPtr(id:cardinal):pFVector2;
    function _GetVertexBindings(id:cardinal; bindings_out:TVertexBones):boolean;
    function _SetVertexBindings(id:cardinal; bindings_in:TVertexBones):boolean;
    function _FilterVertices(var filter:TVertexFlaggedItems):boolean;
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
    function BindVerticesToBone(new_bone_index:TBoneID; selection_callback:TVerticesBindCallback; userdata:pointer):boolean; // if callback is specified - set target TVertexBones and return true to apply changes; if not - the procedure will bind all vertices to specified boneid with weight 1.0

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
    function _FilterVertices(var filter:TVertexFlaggedItems; swr_data:TOgfSwiContainer):boolean;
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
    function MarkIndependentElementsForSelectedVertices(var selected:TVertexFlaggedItems):integer;
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
    function GetVerticesCountForBoneId(boneid:TBoneID):integer;
    function GetTrisCountTotal():cardinal;
    function GetTrisCountInCurrentLod():cardinal;

    function GetLodLevels():integer;
    function AssignLodLevel(level:integer):boolean;
    function RemoveUnactiveLodsData():boolean;

    function CalculateOptimalLinkType():cardinal;
    function ChangeLinkType(new_link_type:cardinal):boolean;
    function BindVerticesToBone(target_boneid:TBoneID; selection_callback:TVerticesBindCallback; userdata:pointer):boolean;
    function FilterVertices(var filter:TVertexFlaggedItems):boolean;

    procedure IterateVertices(cb:TVerticesIterationCallback; userdata:pointer);
    function RemoveVertices(cb:TVerticesIterationCallback; userdata:pointer):boolean; // true returned from cb will mark the vertex to be removed

    procedure IterateAllVerticesOfTheSelectedElements(cb_selection:TVerticesIterationCallback; cb_result:TVerticesIterationCallback; userdata:pointer);

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
    function Split(id:integer; var filter:TVertexFlaggedItems):integer;
  end;

  TOgfAnimationsParser = class;
  { TOgfBone }

  TOgfBone = class
    _name:string;
    _parent_name:string;
    _obb:FObb;

    procedure _SetName(name:string);
    procedure _SetParentName(name:string);
    procedure _InitDefault(name:string; parent_name:string);
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
    function SetOBB(obb:FObb):boolean;
    procedure MoveObb(var delta:FVector3);
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
  TOgfJointIKDataRawData = record
    jointtype:cardinal;
    limits:array [0..2] of TOgfJointLimit;
    spring_factor:single;
    damping_factor:single;
    ik_flags:cardinal;
    break_force:single;
    break_torque:single;
    friction:single;
  end;

  TOgfJointIKData = class
    _data:TOgfJointIKDataRawData;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset; virtual;
    function Loaded():boolean;
    function Deserialize(rawdata:string; version:cardinal):integer;
    function Serialize():string;

    function GetData():TOgfJointIKDataRawData;
    procedure SetData(d:TOgfJointIKDataRawData);
    class function GetDefault():TOgfJointIKDataRawData;
  end;

  { TOgfJointData }

  TOgfJointData = class
    _loaded:boolean;
    _material:string;
    _shape:TOgfBoneShape;
    _ikdata:TOgfJointIKData;
    _rest_rotate:FVector3;
    _rest_offset:FVector3;
    _mass:single;
    _center_of_mass:FVector3;

    // Transformation matrix for temp work & calculations
    // assign just from TOgfSkeleton before actual bone calculations
    _wrk_transform:FMatrix4x4;
    _wrk_key:TMotionKey;

    procedure _AssignWrkKey(key:TMotionKey);
    procedure _AssignWrkTransform(var m:FMatrix4x4);
    procedure _AssignBindWrkPose();
    procedure _GetWrkTransform(var m:FMatrix4x4);
    procedure _GetWrkKey(var key:TMotionKey);

    procedure _InitDefault(offset:FVector3; rotate:FVector3);
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string):integer;
    function Serialize():string;

    // Specific
    function IKData():TOgfJointIKData;
    function GetShape():TOgfBoneShape;
    function MoveShape(v:FVector3):boolean;
    function SetShape(shape:TOgfBoneShape):boolean;
    function SerializeShape():string;
    function DeserializeShape(s:string):boolean;
    function GetMaterial():string;
    procedure SetMaterial(matname:string);
    procedure GetBindTransformData(var offset:FVector3; var rotate:FVector3);
    procedure GetBindTransformData(var m:FMatrix4x4);
    procedure SetBindTransformData(offset:FVector3; rotate:FVector3); overload;
    procedure SetBindTransformData(var m:FMatrix4x4); overload;

    procedure GetMassParams(var center:FVector3; var mass:single);
    procedure SetMassParams(center:FVector3; mass:single);
    procedure MoveMassCenter(delta:FVector3);
    procedure MoveJointPosition(delta:FVector3);

    function UniformScale(k:single):boolean;
  end;

  { TOgfJointsDataContainer }

  TOgfJointsDataContainer = class
    _loaded:boolean;
    _data:array of TOgfJointData;

    function _RegisterJoint(joint:TOgfJointData):TBoneId;
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
    function Get(i:integer):TOgfJointData;

    function UniformScale(k:single):boolean;
  end;

  { TOgfBonesContainer }

  TOgfBonesContainer = class
    _loaded:boolean;
    _bones:array of TOgfBone;

    function _RegisterBone(b:TOgfBone):TBoneId;
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


  { TBoneUnitedData }

  TBoneUnitedData = record
    id:TBoneID;
    parent_id:TBoneID;
    name:string;
    parent_name:string;
    material:string;
    offset:FVector3;
    orientation:FVector3;
    obb:FObb;
    shape:TOgfBoneShape;
    mass:single;
    center_of_mass:FVector3;
    ikdata:TOgfJointIKDataRawData;
  end;
  pTBoneUnitedData=^TBoneUnitedData;

  TBonesIterationCallback = function (bone_id:integer; bone_data:pTBoneUnitedData; userdata:pointer):boolean;
  { TOgfSkeleton }

  TOgfSkeletonData = packed record
    bones:TOgfBonesContainer;
    joints:TOgfJointsDataContainer;
  end;

  TOgfBoneData = record
    bone:TOgfBone;
    joint:TOgfJointData;
  end;

  TOgfSkeletonBonePoseDataMode = (OgfSkeletonBonePoseDataModeNone, OgfSkeletonBonePoseDataModeKey, OgfSkeletonBonePoseDataModeTransform);
  TOgfSkeletonBonePoseData = record
    name:string;
    mode:TOgfSkeletonBonePoseDataMode;
    calculated:boolean;
    key:TMotionKey;
    transform:FMatrix4x4;
  end;

  { TOgfSkeletonPose }

  TOgfSkeletonPose = class
    _bones:array of TOgfSkeletonBonePoseData;
    function _IdxByName(name:string):integer;
    procedure _Calc(i:integer);
  public
    constructor Create();
    procedure Reset();

    procedure SetBone(bonename:string; var key:TMotionKey; force:boolean = false);
    procedure SetBone(bonename:string; var transform:FMatrix4x4; force:boolean = false);
    function GetBoneKey(bonename:string; var key:TMotionKey):boolean;
    function GetBoneTransform(bonename:string; var transform:FMatrix4x4):boolean;
    function GetPreviouslySetBoneDataType(bonename:string):TOgfSkeletonBonePoseDataMode;

    function ForgetBone(bonename:string):boolean;
    function GetBonename(idx:integer):string;
    function BonesCount():integer;
    function Serialize():string;
    function Deserialize(var s:string):boolean;
    procedure CopyTo(dest:TOgfSkeletonPose);

    destructor Destroy(); override;
  end;

  { TOgfSkeletonPoseSeq }

  TOgfSkeletonPoseSeq = class
    _poses:array of TOgfSkeletonPose;
  public
    constructor Create();
    procedure Reset();
    destructor Destroy(); override;

    function Count():integer;
    function Get(i:integer):TOgfSkeletonPose;
    procedure Add(pose:TOgfSkeletonPose);

    function Serialize():string;
    function Deserialize(var s:string):boolean;
  end;


  TOgfIkSolvingResult = (IKSolveSuccess, IKSolveNotNeeded, IKSolveFailed);

  { TOgfIKSolverBase }
  TOgfSkeleton = class;
  TOgfIKSolverBase = class
    _skeleton: TOgfSkeleton;
  public
    constructor Create(skeleton: TOgfSkeleton);
    function IsProperlyConfigured():boolean; virtual; abstract;
    function IsTransformAllowedForBone(bone_id:TBoneID):boolean; virtual; abstract;
    function IsIkSolveNeededForBoneTransform(bone_id:TBoneID):boolean; virtual; abstract;
    function IsHandlerBone(bone_id:TBoneID):boolean; virtual; abstract;
    function SolveIK(bone_id:TBoneID; new_transform:FMatrix4x4):TOgfIkSolvingResult; virtual; abstract;
    function SetReferencePose(pose:TOgfSkeletonPose):boolean; virtual; abstract;
  end;

  TOgfSimpleGrandparentIKSolverDtVectors = array of FVector3;
  TOgfSimpleGrandparentIKSolverFlags = cardinal;

  { TOgfSimpleGrandparentIKSolver }

  TOgfSimpleGrandparentIKSolver = class(TOgfIKSolverBase)
    _target_bone:TBoneID;
    _last_solved_pose:TOgfSkeletonPose;
    _initial_step:single;
    _minimal_step:single;
    _accuracy:single;
    _parent_bone_flags:TOgfSimpleGrandparentIKSolverFlags;
    _grandparent_bone_flags:TOgfSimpleGrandparentIKSolverFlags;

    procedure _FillDtVectors(var v:TOgfSimpleGrandparentIKSolverDtVectors; dt:single; flags:TOgfSimpleGrandparentIKSolverFlags);

    function _IsRotationPossible(skeleton: TOgfSkeleton; child_id: TBoneID; point: FVector3; target_distance: single):boolean;
    procedure _ApplyRotation(skeleton: TOgfSkeleton; bone:TOgfBoneData; dv:FVector3);
    function _RotateParentToPlaceChildOnDistanceToPoint(skeleton: TOgfSkeleton; child_id:TBoneID; point:FVector3; target_distance:single; flags:TOgfSimpleGrandparentIKSolverFlags; var last_metric:single):boolean;
    function _CalcRotationMetric(skeleton: TOgfSkeleton; measure_bone_id:TBoneID; rotating_bone_id:TBoneID; target_point:FVector3; target_distance:single; dv:FVector3):single;
  public
    constructor Create(skeleton: TOgfSkeleton; target_bone:TBoneID; parent_bone_flags:TOgfSimpleGrandparentIKSolverFlags; grandparent_bone_flags:TOgfSimpleGrandparentIKSolverFlags; initial_step:single; minimal_step:single; accuracy:single);
    destructor Destroy; override;
    function SetReferencePose(pose:TOgfSkeletonPose):boolean; override;
    function IsProperlyConfigured():boolean; override;
    function IsTransformAllowedForBone(bone_id:TBoneID):boolean; override;
    function IsHandlerBone(bone_id:TBoneID):boolean; override;
    function IsIkSolveNeededForBoneTransform(bone_id:TBoneID):boolean; override;
    function SolveIK(bone_id:TBoneID; new_transform:FMatrix4x4):TOgfIkSolvingResult; override;
    class function GetFlagsFromString(s:string):TOgfSimpleGrandparentIKSolverFlags;
  end;

  TOgfBoneRotationMode = (BoneRotationLocal, BoneRotationGlobalAroundSelf);
  TOgfAnimationBonesSyncFlags = cardinal;

  { TOgfSkeleton }

  TOgfSkeleton = class
    _loaded:boolean;
    _data:TOgfSkeletonData;
    _animations:TOgfAnimationsParser;

    function _Build(desc:TOgfBonesContainer; ik:TOgfJointsDataContainer):boolean;

    function _GetBone(id:TBoneID):TOgfBoneData;
    function _GetBoneByName(name:string; var output:TOgfBoneData):boolean;

    function _SetKeyPoseForWork(anim_name:string; key_id:integer):boolean;
    function _SetBindPoseForWork():boolean;
    function _GetWrkPose(pose:TOgfSkeletonPose):boolean;
    function _SetWrkPose(pose:TOgfSkeletonPose):integer; // count of bones were set

    function _GetWrkBoneLocalTransform(idx:TBoneID; var m:FMatrix4x4):boolean;
    function _GetWrkBoneSpaceToGlobalSpaceMatrix(idx:TBoneID; var m:FMatrix4x4):boolean;
    function _GetGlobalSpaceToWrkBoneSpaceMatrix(idx:TBoneID; var m:FMatrix4x4):boolean;
    function _ConvertGlobalCoordinatesIntoWrkBoneSpace(bone_idx:TBoneID; in_v:FVector3; var out_v:FVector3):boolean;
    function _ConvertGlobalCoordinatesIntoParentSpaceOfWrkBone(child_bone_idx:TBoneID; in_v:FVector3; var out_v:FVector3):boolean;

    // get transform which 'root' bone with in_m transform will have after bone with idx become its parent
    function _ConvertTransformFromGlobalIntoWrkBoneSpace(bone_idx:TBoneID; in_m:FMatrix4x4; var out_m:FMatrix4x4):boolean;
    function _ConvertTransformFromGlobalIntoParentSpaceOfWrkBone(child_bone_idx:TBoneID; in_m:FMatrix4x4; var out_m:FMatrix4x4):boolean;

    // get transform which bone which has parent with bone_idx will have after unparenting
    function _ConvertTransformFromWrkBoneSpaceIntoGlobal(bone_idx:TBoneID; in_m:FMatrix4x4; var out_m:FMatrix4x4):boolean;
    function _ConvertTransformFromParentSpaceOfWrkBoneIntoGlobal(child_bone_idx:TBoneID; in_m:FMatrix4x4; var out_m:FMatrix4x4):boolean;

    function _GetWrkBoneTransformRelativeToBindPose(bone_idx:TBoneID; var m:FMatrix4x4):boolean;

    function _TryToUseAlreadyCalculatedKey(anim_name:string; bone_name:string; key_idx:integer; var transform:FMatrix4x4; var out_key:TMotionKey):boolean;
    function _SetTransformKeyForAnimBone(anim_name:string; bone_name:string; key_idx:integer; transform:FMatrix4x4):boolean;
    function _SetKeyForAnimBone(anim_name:string; bone_name:string; key_idx:integer; key:TMotionKey):boolean;

    function _AimChildBoneTo(bone_idx:TBoneID; global_target_pos:FVector3):boolean;
    function _SolveIKAndSetKey(bone_idx:TBoneID; new_transform:FMatrix4x4; anim_name:string; key_idx:integer; iksolver:TOgfIKSolverBase):TOgfIkSolvingResult;
  public
    constructor Create();
    procedure Reset;
    function Loaded():boolean;
    destructor Destroy(); override;
    procedure IterateBones(cb:TBonesIterationCallback; userdata:pointer);
    function ForceSetBoneBindPoseTransform(bone_idx:TBoneId; offset:FVector3; rotate:FVector3):boolean; // Use it only if you completely understand what you do!

    procedure AssignAnimations(animations:TOgfAnimationsParser);


    // Bone parameters getters
    function GetBonesCount():integer;
    function GetBoneIdxByName(name:string):TBoneID; overload;
    function GetBoneName(idx:TBoneID):string;
    function GetBoneParentName(idx:TBoneID):string;
    function IsBoneHasSuchParentOrGrandParent(idx:TBoneID; idx_to_check_if_parent:TBoneID):boolean;
    function GetBoneParentIdx(idx:TBoneID):TBoneId;
    function GetBoneMaterial(idx:TBoneID):string;
    function GetBoneMassParams(idx:TBoneID; var center:FVector3; var mass:single):boolean;
    function GetBoneShape(idx:TBoneID; var shape:TOgfBoneShape):boolean;
    function GetBoneBoundingBox(idx:TBoneID; var obb:FObb):boolean;
    function GetBoneUnitedData(idx:TBoneID; var data:TBoneUnitedData):boolean;

    //-1 in key_idx means bind pose for the next group of functions
    function GetGlobalBonePositionInPose(bone_idx:TBoneId; anim_name:string; key_idx:integer; var position:FVector3): boolean;
    function GetGlobalSpaceToBoneSpaceMatrixInPose(bone_idx:TBoneId; anim_name:string; key_idx:integer; var m:FMatrix4x4): boolean;
    function GetBoneSpaceToGlobalSpaceMatrixInPose(bone_idx:TBoneId; anim_name:string; key_idx:integer; var m:FMatrix4x4): boolean;
    function GetSkeletonPose(anim_name:string; key_idx:integer; pose:TOgfSkeletonPose):boolean;
    function SetSkeletonPose(anim_name:string; key_idx:integer; pose:TOgfSkeletonPose):integer;

    function GetSkeletonPosesSequence(anim_name:string; first_key_idx:integer; last_key_idx:integer; poses:TOgfSkeletonPoseSeq):boolean;
    function PasteSkeletonPosesSequence(anim_name:string; first_key_idx:integer; insert_mode:boolean; poses:TOgfSkeletonPoseSeq):boolean;

    function GetBoneBindTransformInParentSpace(idx:TBoneID; var offset:FVector3; var rotate:FVector3):boolean;
    function MoveBone(idx:TBoneID; v:FVector3; anim_name:string; key_idx:integer; is_absolute:boolean; fixed_children:boolean; iksolver:TOgfIKSolverBase):boolean;
    function RotateBone(idx:TBoneID; v:FVector3; anim_name:string; key_idx:integer; mode:TOgfBoneRotationMode; iksolver:TOgfIKSolverBase):boolean;
    function FollowBone(bone_idx:TBoneID; anim_name:string; source_bone_idx:TBoneID; source_key_idx:integer; target_key_idx:integer; iksolver:TOgfIKSolverBase):boolean;
    function AimBone(bone_idx:TBoneID; target:FVector3; anim_name:string; key_idx:integer; iksolver:TOgfIKSolverBase):boolean;
    function SetBoneOrientation(bone_idx:TBoneID; orientation:FVector3; anim_name:string; key_idx:integer; iksolver:TOgfIKSolverBase):boolean;
    function SetBonePosition(bone_idx:TBoneID; position:FVector3; anim_name:string; key_idx:integer; is_global:boolean; iksolver:TOgfIKSolverBase):boolean;
    function InterpolateBone(bone_idx:TBoneID; anim_name:string; first_key_idx:integer; last_key_idx: integer; calc_pos:boolean; calc_rot:boolean; factor:single; iksolver:TOgfIKSolverBase):integer;
    function ApplyDiff(bone_idx:TBoneID; anim_name:string; targetframe:integer; sourceframe:integer; startframe:integer; endframe:integer; correct_position:boolean; correct_rotation:boolean; iksolver:TOgfIKSolverBase):boolean;

    function SyncAnimsBones(sync_flags:TOgfAnimationBonesSyncFlags):boolean;
    function AddBone(name:string; parent_id:TBoneId; pos:FVector3; dir:FVector3; is_in_global_space:boolean; force_bind_pose:boolean):TBoneId;
    function RenameBone(old_name:string; new_name:string):boolean;
    function ReparentBone(idx:TBoneID; new_parent_idx:TBoneID; preserve_global_pos:boolean):boolean;
    function SetBoneShape(idx:TBoneID; shape:TOgfBoneShape):boolean;
    function SetBoneObb(idx:TBoneID; obb:FObb):boolean;
    function SetBoneMassCenter(idx:TBoneID; c:FVector3):boolean;
    function SetBoneMaterial(idx:TBoneID; material:string):boolean;

    function CopyBoneParameters(idx:TBoneID):string;
    function ApplyBoneParameters(idx:TBoneID; s:string): boolean;

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

  { TOgfMotionRefs }

  TOgfMotionRefs = class
    _loaded:boolean;
    _refs:array of string;
    _chunk_id:word;
  public
    // Common
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    function Loaded():boolean;
    function Deserialize(rawdata:string; chunk_id:word):boolean;
    function Serialize():string;
    function GetChunkId():word;
    function AddRef(filename:string):integer;
    function RefsCount():integer;
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

    procedure _Optimize();
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
    function SlerpBetweenKeys(start_idx:integer; end_idx:integer; factor:single; pos:boolean; rot:boolean):boolean;

    function MakeStatic(key:TMotionKey):boolean;

    function ChangeFramesCount(new_frames_count:integer):boolean;

    function Copy(from:TOgfMotionBoneTrack):boolean;
    function MergeWithTrack(second:TOgfMotionBoneTrack):boolean;

    class procedure KeysSlerp(var k_out:TMotionKey; k1:TMotionKey; k2:TMotionKey; tm:single; pos:boolean; rot:boolean);
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
    function MakeBoneStatic(track_bone_idx:integer; k:TMotionKey):boolean;
    function InterpolateBoneKeys(track_bone_idx:integer; start_key_idx:integer; end_key_idx:integer; factor:single; pos:boolean; rot:boolean):boolean;

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
     procedure _SetName(new_name:string);
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

     function GetName():string;
     procedure SetName(name:string);
     function GetIntervalsCount():integer;
     function GetInterval(idx:integer):TOgfMotionMarkInterval;
     procedure AddInterval(interval:TOgfMotionMarkInterval);
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
     function Serialize(force_v4:boolean):string;

     procedure CopyFrom(second:TOgfMotionMarks);

     function Count():integer;
     function Get(idx:integer):TOgfMotionMark;
     function Add(mark_name:string; interval:TOgfMotionMarkInterval):integer;
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
     function Serialize(force_v4:boolean):string;

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
    function _SplitCommonSource():boolean;
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

    function IsBonePresent(name:string):boolean;
    function AddBone(name:string; default_key:TMotionKey; part_id:integer=0):boolean;
    function RemoveBone(name:string):boolean;
    function RenameBone(old_name:string; new_name:string):boolean;

    function RegisteredBonesCount():integer;
    function GetRegisteredBoneName(idx:integer):string;

    function ChangeAnimationFramesCount(anim_name:string; new_frames_count:integer):boolean;
    function GetAnimationFramesCount(anim_name:string):integer;

    function GetAnimationKeyForBone(anim_name:string; bone_name:string; key_idx:integer; var k:TMotionKey):boolean;
    function SetAnimationKeyForBone(anim_name:string; bone_name:string; key_idx:integer; k:TMotionKey):boolean;
    function SetAnimationMultiframeKeyForBone(anim_name:string; bone_name:string; start_key:integer; end_key:integer; k:TMotionKey):boolean;
    function InterpotateAnimationKeysForBone(anim_name:string; bone_name:string; start_key:integer; end_key:integer; factor:single; pos:boolean; rot:boolean):boolean;

    function DuplicateAnimation(old_name:string; new_name:string):boolean;
    function RenameAnimation(old_name:string; new_name:string):boolean;
    function MergeAnimations(name_of_new:string; name_of_first:string; name_of_second:string):boolean;
    function DeleteAnimation(name:string):boolean;

    function MergeContainers(source_to_merge:TOgfAnimationsParser):boolean;
  end;

 { TOgfParser }

 TOgfParser = class(TOgfBaseFileParser)
 private
   _header:TOgfHeader;

   _children:TOgfChildrenContainer;
   _bone_names:TOgfBonesContainer;
   _joints:TOgfJointsDataContainer;
   _userdata:TOgfUserdataContainer;
   _lodref:TOgfLodRefsContainer;
   _skeleton:TOgfSkeleton;
   _animations:TOgfAnimationsParser;
   _motionrefs:TOgfMotionRefs;

   function _DeserializeHeader(rawdata:string):boolean;
   function _SerializeHeader():string;
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

   function GenerateBoneShapeAABB(boneid:TBoneID):TOgfBoneShape;
   function CalculateBounds():boolean;
   function GetModelBBox():TOgfBBox;
   function GetModelBSphere():TOgfBSphere;
   procedure SetModelBBox(bb:TOgfBBox);
   procedure SetModelBSphere(bs:TOgfBSphere);

   function IsAnimationsEmbedded():boolean;
   function SplitEmbeddedMotionsIntoSeparateSource():boolean;
   function AddMotionRef(filename:string):integer;
   procedure ResetMotionRefs();
end;

function QrToQuat(pqr:pTOgfMotionKeyQR):Fquaternion;
function Qt8ToT(pqt:pTOgfMotionKeyQT8; size_tr:pFVector3; init_tr:pFVector3):FVector3;
function Qt16ToT(pqt:pTOgfMotionKeyQT16; size_tr:pFVector3; init_tr:pFVector3):FVector3;
function TransformToMotionKey(var transform:FMatrix4x4):TMotionKey;

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
  CHUNK_OGF_S_MOTION_REFS:word=19;
  CHUNK_OGF_S_LODS:word=23;
  CHUNK_OGF_S_MOTION_REFS2:word=24;

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

  MT_SKELETON_ANIM = 3;
  MT_SKELETON_RIGID = 10;


  SIMPLE_GP_IKSOLVER_FLAG_DISABLE_X_AXIS:TOgfSimpleGrandparentIKSolverFlags = 1;
  SIMPLE_GP_IKSOLVER_FLAG_DISABLE_Y_AXIS:TOgfSimpleGrandparentIKSolverFlags = 2;
  SIMPLE_GP_IKSOLVER_FLAG_DISABLE_Z_AXIS:TOgfSimpleGrandparentIKSolverFlags = 4;

  OGF_ANIMATION_SYNC_ADD_TO_ANIM:TOgfAnimationBonesSyncFlags=1;
  OGF_ANIMATION_SYNC_REMOVE_FROM_SKELETON:TOgfAnimationBonesSyncFlags=2;
  OGF_ANIMATION_SYNC_FULL:TOgfAnimationBonesSyncFlags = 3;

implementation
uses sysutils, FastCrc, math;

const

EPS:single = 0.00001;
KEY_Quant16:integer=32767;
KEY_Quant8:integer=127;
KEY_QuantI: single = 1/32767;

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
    s.sphere.p.x:=s.sphere.p.x+v.x;
    s.sphere.p.y:=s.sphere.p.y+v.y;
    s.sphere.p.z:=s.sphere.p.z+v.z;
    result:=true;
  end else if s.shape_type = OGF_SHAPE_TYPE_CYLINDER then begin
    s.cylinder.m_center.x:=s.cylinder.m_center.x+v.x;
    s.cylinder.m_center.y:=s.cylinder.m_center.y+v.y;
    s.cylinder.m_center.z:=s.cylinder.m_center.z+v.z;
    result:=true;
  end;
end;

function ShapeUniformScale(var s:TOgfBoneShape; k:single):boolean;
var
  pp:FVector3;
begin
  result:=false;

  set_zero(pp);

  if s.shape_type = OGF_SHAPE_TYPE_BOX then begin
    uniform_scale(s.box, k, pp);
    result:=true;
  end else if s.shape_type = OGF_SHAPE_TYPE_SPHERE then begin
    uniform_scale(s.sphere, k, pp);
    result:=true;
  end else if s.shape_type = OGF_SHAPE_TYPE_CYLINDER then begin
    uniform_scale(s.cylinder, k, pp);
    result:=true;
  end else if s.shape_type = OGF_SHAPE_TYPE_NONE then begin;
    result:=true;
  end;
end;

function CorrectAlmostZeroOrOnes(var val:single):boolean;
const
  DT_EPS:single = 0.000001;
begin
  result:=false;
  if abs(val)<DT_EPS then begin
    val:=0;
    result:=true;
  end else if abs(1-val)<DT_EPS then begin
    val:=1;
    result:=true;
  end;
end;

procedure CorrectAlmostZeroOrOnesInRot(var m:FMatrix4x4);
var
  r:boolean;
begin
  r:=false;
  r:=r or CorrectAlmostZeroOrOnes(m.i.x); r:=r or CorrectAlmostZeroOrOnes(m.i.y); r:=r or CorrectAlmostZeroOrOnes(m.i.z);
  r:=r or CorrectAlmostZeroOrOnes(m.j.x); r:=r or CorrectAlmostZeroOrOnes(m.j.y); r:=r or CorrectAlmostZeroOrOnes(m.j.z);
  r:=r or CorrectAlmostZeroOrOnes(m.k.x); r:=r or CorrectAlmostZeroOrOnes(m.k.y); r:=r or CorrectAlmostZeroOrOnes(m.k.z);
end;

function IsRotSame(var m1:FMatrix4x4; var m2:FMatrix4x4):boolean;
const
  CHECK_EPD:single = 0.00003;
begin
  result:=(abs(m1.i.x-m2.i.x) < CHECK_EPD) and (abs(m1.i.y-m2.i.y) < CHECK_EPD) and (abs(m1.i.z-m2.i.z) < CHECK_EPD)
      and (abs(m1.j.x-m2.j.x) < CHECK_EPD) and (abs(m1.j.y-m2.j.y) < CHECK_EPD) and (abs(m1.j.z-m2.j.z) < CHECK_EPD)
      and (abs(m1.k.x-m2.k.x) < CHECK_EPD) and (abs(m1.k.y-m2.k.y) < CHECK_EPD) and (abs(m1.k.z-m2.k.z) < CHECK_EPD);
end;

function IsRotSame(var q1:Fquaternion; var q2:Fquaternion):boolean;
const
  CHECK_DELTA:single = 0.00003;
begin
  result:=(abs(q1.w-q2.w) < CHECK_DELTA) and (abs(q1.x-q2.x) < CHECK_DELTA) and (abs(q1.y-q2.y) < CHECK_DELTA) and (abs(q1.z-q2.z) < CHECK_DELTA);
end;

function IsPosSame(var v1:FVector3; var v2:FVector3):boolean;
const
  CHECK_DELTA:single = 0.00001;
begin
  result:=(abs(v1.x-v2.x) < CHECK_DELTA) and (abs(v1.y-v2.y) < CHECK_DELTA) and (abs(v1.z-v2.z) < CHECK_DELTA);
end;

{ TOgfSkeletonPoseSeq }

constructor TOgfSkeletonPoseSeq.Create();
begin
  setlength(_poses, 0);
end;

procedure TOgfSkeletonPoseSeq.Reset();
var
  i:integer;
begin
  for i:=0 to length(_poses)-1 do begin
    FreeAndNil(_poses[i]);
  end;

  setlength(_poses, 0);
end;

destructor TOgfSkeletonPoseSeq.Destroy();
begin
  Reset();
  inherited Destroy();
end;

function TOgfSkeletonPoseSeq.Count(): integer;
begin
  result:=length(_poses);
end;

function TOgfSkeletonPoseSeq.Get(i: integer): TOgfSkeletonPose;
begin
  result:=nil;
  if (i<0) or (i>=Count()) then exit;

  result:=_poses[i];
end;

procedure TOgfSkeletonPoseSeq.Add(pose: TOgfSkeletonPose);
var
  i:integer;
begin
  i:=length(_poses);
  setlength(_poses, i+1);
  _poses[i]:=pose;
end;

function TOgfSkeletonPoseSeq.Serialize(): string;
var
  pose_s:string;
  i:integer;
  res:string;
begin
  result:='';

  res:=SerializeCardinal(Count());

  for i:=0 to Count()-1 do begin
    pose_s:=Get(i).Serialize();
    if length(pose_s)=0 then exit;

    res:=res+SerializeCardinal(length(pose_s));
    res:=res+pose_s;
  end;

  result:=res;
end;

function TOgfSkeletonPoseSeq.Deserialize(var s: string): boolean;
var
  pose:TOgfSkeletonPose;
  pose_s:string;
  i:integer;
  cnt:cardinal;
  sz:cardinal;
  isok:boolean;
begin
  result:=false;
  Reset();

  if length(s) < sizeof(cnt) then exit;
  cnt:=PCardinal(PAnsiChar(s))^;
  if not AdvanceString(s, sizeof(cnt)) then exit;

  isok:=true;
  for i:=0 to cnt-1 do begin
    if length(s) < sizeof(sz) then begin
      isok:=false;
      break;
    end;

    sz:=PCardinal(PAnsiChar(s))^;
    if not AdvanceString(s, sizeof(sz)) or (length(s)<sz) then begin
      isok:=false;
      break;
    end;

    pose_s:=leftstr(s, sz);
    if not AdvanceString(s, sz) then begin
      isok:=false;
      break;
    end;

    pose:=TOgfSkeletonPose.Create();
    if not pose.Deserialize(pose_s) then begin
      FreeAndNil(pose);
      isok:=false;
      break;
    end;
    Add(pose);
  end;

  if not isok then begin
    Reset();
  end else begin
    result:=true;
  end;
end;

{ TOgfSimpleGrandparentIKSolver }

procedure TOgfSimpleGrandparentIKSolver._FillDtVectors(var v: TOgfSimpleGrandparentIKSolverDtVectors; dt: single; flags: TOgfSimpleGrandparentIKSolverFlags);
var
  i:integer;
  dt2, dt3:single;
begin
  setlength(v, 0);

  if (flags and SIMPLE_GP_IKSOLVER_FLAG_DISABLE_X_AXIS) = 0 then begin
    i:=length(v);
    setlength(v, i+2);
    v[i]  :=v_set( dt, 0, 0);
    v[i+1]:=v_set(-dt, 0, 0);
  end;

  if (flags and SIMPLE_GP_IKSOLVER_FLAG_DISABLE_Y_AXIS) = 0 then begin
    i:=length(v);
    setlength(v, i+2);
    v[i]  :=v_set(0,  dt, 0);
    v[i+1]:=v_set(0, -dt, 0);
  end;

  if (flags and SIMPLE_GP_IKSOLVER_FLAG_DISABLE_Z_AXIS) = 0 then begin
    i:=length(v);
    setlength(v, i+2);
    v[i]  :=v_set(0, 0,  dt);
    v[i+1]:=v_set(0, 0, -dt);
  end;

  dt2:= sqrt(dt*dt/2);
  if ((flags and SIMPLE_GP_IKSOLVER_FLAG_DISABLE_X_AXIS) = 0) and ((flags and SIMPLE_GP_IKSOLVER_FLAG_DISABLE_Y_AXIS) = 0) then begin
    i:=length(v);
    setlength(v, i+4);
    v[i]  :=v_set( dt2,  dt2, 0);
    v[i+1]:=v_set( dt2, -dt2, 0);
    v[i+2]:=v_set(-dt2,  dt2, 0);
    v[i+3]:=v_set(-dt2, -dt2, 0);
  end;

  if ((flags and SIMPLE_GP_IKSOLVER_FLAG_DISABLE_X_AXIS) = 0) and ((flags and SIMPLE_GP_IKSOLVER_FLAG_DISABLE_Z_AXIS) = 0) then begin
    i:=length(v);
    setlength(v, i+4);
    v[i]  :=v_set( dt2, 0,  dt2);
    v[i+1]:=v_set( dt2, 0, -dt2);
    v[i+2]:=v_set(-dt2, 0,  dt2);
    v[i+3]:=v_set(-dt2, 0, -dt2);
  end;

  if ((flags and SIMPLE_GP_IKSOLVER_FLAG_DISABLE_Y_AXIS) = 0) and ((flags and SIMPLE_GP_IKSOLVER_FLAG_DISABLE_Z_AXIS) = 0) then begin
    i:=length(v);
    setlength(v, i+4);
    v[i]  :=v_set(0, dt2, dt2);
    v[i+1]:=v_set(0, dt2,-dt2);
    v[i+2]:=v_set(0,-dt2, dt2);
    v[i+3]:=v_set(0,-dt2,-dt2);
  end;

  if  ((flags and SIMPLE_GP_IKSOLVER_FLAG_DISABLE_X_AXIS) = 0) and ((flags and SIMPLE_GP_IKSOLVER_FLAG_DISABLE_Y_AXIS) = 0) and ((flags and SIMPLE_GP_IKSOLVER_FLAG_DISABLE_Z_AXIS) = 0) then begin
    dt3:=sqrt(dt*dt - dt2*dt2);

    i:=length(v);
    setlength(v, i+8);
    v[i]  :=v_set(dt3,  dt3,  dt3);
    v[i+1]:=v_set(dt3,  dt3, -dt3);
    v[i+2]:=v_set(dt3, -dt3,  dt3);
    v[i+3]:=v_set(dt3, -dt3, -dt3);
    v[i+4]:=v_set(-dt3,  dt3,  dt3);
    v[i+5]:=v_set(-dt3,  dt3, -dt3);
    v[i+6]:=v_set(-dt3, -dt3,  dt3);
    v[i+7]:=v_set(-dt3, -dt3, -dt3);
  end;

end;

function TOgfSimpleGrandparentIKSolver._IsRotationPossible(skeleton: TOgfSkeleton; child_id: TBoneID; point: FVector3; target_distance: single): boolean;
var
  child_bone, parent_bone:TOgfBoneData;
  parent_name:string;
  parent_id:TBoneID;

  bone_len, parent_distance_to_target:single;
  m_child, m_parent:FMatrix4x4;
  gp_child, gp_parent:FVector3;
  v_child, v_target:FVector3;
begin
  result:=false;

  child_bone:=_skeleton._GetBone(child_id);
  if child_bone.joint = nil then exit;

  parent_name:=child_bone.bone.GetParentName();
  if length(parent_name)=0 then exit;
  parent_id:=_skeleton.GetBoneIdxByName(parent_name);
  if parent_id = INVALID_BONE_ID then exit;
  parent_bone:=_skeleton._GetBone(parent_id);
  if parent_bone.joint = nil then exit;

  if not skeleton._GetWrkBoneSpaceToGlobalSpaceMatrix(child_id, m_child) then exit;
  if not skeleton._GetWrkBoneSpaceToGlobalSpaceMatrix(parent_id, m_parent) then exit;

  m_get_translation(m_child, gp_child);
  m_get_translation(m_parent, gp_parent);
  v_child:=v_sub(gp_child, gp_parent);
  v_target:=v_sub(point, gp_parent);

  bone_len:=v_magnitude(v_child);
  parent_distance_to_target:=v_magnitude(v_target);


  if parent_distance_to_target-_accuracy > bone_len + target_distance then exit;
  if bone_len-_accuracy > parent_distance_to_target + target_distance then exit;
  if target_distance-_accuracy > parent_distance_to_target + bone_len then exit;

  result:=true;
end;

procedure TOgfSimpleGrandparentIKSolver._ApplyRotation(skeleton: TOgfSkeleton; bone: TOgfBoneData; dv: FVector3);
var
  dm, m:FMatrix4x4;
begin
  m_setXYZ(dm, dv);
  bone.joint._GetWrkTransform(m);
  m:=m_mul(m, dm);
  bone.joint._AssignWrkTransform(m);
end;

function TOgfSimpleGrandparentIKSolver._RotateParentToPlaceChildOnDistanceToPoint(skeleton: TOgfSkeleton; child_id: TBoneID; point: FVector3; target_distance: single; flags: TOgfSimpleGrandparentIKSolverFlags; var last_metric: single): boolean;
var
  dv:FVector3;
  dt:single;

  child_bone, parent_bone:TOgfBoneData;
  parent_name:string;
  parent_id:TBoneID;

  metric, n:single;

  vectors:TOgfSimpleGrandparentIKSolverDtVectors;
  m, old_m:FMatrix4x4;
  i, metric_i:integer;

  rot_vector:FVector3;
begin
  result:=false;

  child_bone:=_skeleton._GetBone(child_id);
  if child_bone.joint = nil then exit;

  parent_name:=child_bone.bone.GetParentName();
  if length(parent_name)=0 then exit;
  parent_id:=_skeleton.GetBoneIdxByName(parent_name);
  if parent_id = INVALID_BONE_ID then exit;
  parent_bone:=_skeleton._GetBone(parent_id);
  if parent_bone.joint = nil then exit;

  set_zero(dv);
  last_metric:=_CalcRotationMetric(skeleton, child_id, parent_id, point, target_distance, dv);

  if not _IsRotationPossible(skeleton, child_id, point, target_distance) then begin
    result:=(last_metric <= _accuracy); // calculation error doesn't allow us to make a good triangle
    exit;
  end;

  // Check cached results - probably we already calculated a better pose at the previous iteration
  if _last_solved_pose.GetBoneTransform(parent_name, m) then begin
    parent_bone.joint._GetWrkTransform(old_m);

    parent_bone.joint._AssignWrkTransform(m);
    metric:=_CalcRotationMetric(skeleton, child_id, parent_id, point, target_distance, dv);

    if metric < last_metric then begin
      // Ok, previously calculated pose is better than initial, use it
      last_metric:=metric;
    end else begin
      // No luck, rollback to initial pose
      parent_bone.joint._AssignWrkTransform(old_m);
    end;
  end;

  // Even if metric is below accuracy, we'll still try to improve the final pose
  dt:= _initial_step;
  _FillDtVectors(vectors, dt, flags);

  set_zero(rot_vector);

  while (not result) and (dt > _minimal_step) do begin
    metric:=last_metric;
    metric_i:=-1;

    for i:=0 to length(vectors)-1 do begin
      dv:=v_add(rot_vector, vectors[i]);
      n:=_CalcRotationMetric(skeleton, child_id, parent_id, point, target_distance, dv);
      if n < metric then begin
        metric_i:=i;
        metric:=n;
      end;
    end;

    if (metric >= last_metric) or (metric_i < 0) then begin
      dt:=dt * 0.5;
      if (dt > _minimal_step) then begin
        _FillDtVectors(vectors, dt, flags);
      end else begin
        result:= (last_metric <= _accuracy);
      end;
    end else begin
      rot_vector:=v_add(rot_vector, vectors[metric_i]);
      last_metric:=metric;
    end;
  end;

  _ApplyRotation(skeleton, parent_bone, rot_vector);
end;

function TOgfSimpleGrandparentIKSolver._CalcRotationMetric(skeleton: TOgfSkeleton; measure_bone_id: TBoneID; rotating_bone_id: TBoneID; target_point: FVector3; target_distance: single; dv: FVector3): single;
var
  old_m, m:FMatrix4x4;
  has_rot:boolean;

  rotating_bone:TOgfBoneData;
  pos:FVector3;
  cur_dist:single;
begin
  has_rot:=(abs(dv.x) > EPS) or (abs(dv.y) > EPS) or (abs(dv.z) > EPS);

  if has_rot then begin
    rotating_bone:=skeleton._GetBone(rotating_bone_id);
    rotating_bone.joint._GetWrkTransform(old_m);
    _ApplyRotation(skeleton, rotating_bone, dv);
  end;

  skeleton._GetWrkBoneSpaceToGlobalSpaceMatrix(measure_bone_id, m);
  m_get_translation(m, pos);

  cur_dist:=distance_between(target_point, pos);
  result:=abs(target_distance - cur_dist);

  if has_rot then begin
    rotating_bone.joint._AssignWrkTransform(old_m);
  end;
end;

constructor TOgfSimpleGrandparentIKSolver.Create(skeleton: TOgfSkeleton; target_bone: TBoneID; parent_bone_flags: TOgfSimpleGrandparentIKSolverFlags; grandparent_bone_flags: TOgfSimpleGrandparentIKSolverFlags; initial_step: single; minimal_step: single; accuracy: single);
begin
  inherited Create(skeleton);
  _target_bone:=target_bone;
  _last_solved_pose:=TOgfSkeletonPose.Create();
  _accuracy:=accuracy;
  _initial_step:=initial_step;
  _minimal_step:=minimal_step;
  _grandparent_bone_flags:=grandparent_bone_flags;
  _parent_bone_flags:=parent_bone_flags;

end;

destructor TOgfSimpleGrandparentIKSolver.Destroy;
begin
  FreeAndNil(_last_solved_pose);
  inherited Destroy;
end;

function TOgfSimpleGrandparentIKSolver.SetReferencePose(pose: TOgfSkeletonPose): boolean;
begin
  pose.CopyTo(_last_solved_pose);
  result:=true;
end;

function TOgfSimpleGrandparentIKSolver.IsProperlyConfigured(): boolean;
var
  bone, parent_bone, grandparent_bone:TOgfBoneData;

  parent_name, grandparent_name:string;
  parent_id, grandparent_id:TBoneID;
begin
  result:=false;

  if _accuracy <= 0 then exit;
  if _initial_step <= 0 then exit;

  bone:=_skeleton._GetBone(_target_bone);
  if bone.joint = nil then exit;

  parent_name:=bone.bone.GetParentName();
  if length(parent_name)=0 then exit;
  parent_id:=_skeleton.GetBoneIdxByName(parent_name);
  if parent_id = INVALID_BONE_ID then exit;
  parent_bone:=_skeleton._GetBone(parent_id);
  if parent_bone.joint = nil then exit;

  grandparent_name:=parent_bone.bone.GetParentName();
  if length(grandparent_name) = 0 then exit;
  grandparent_id:=_skeleton.GetBoneIdxByName(grandparent_name);
  if grandparent_id = INVALID_BONE_ID then exit;
  grandparent_bone:=_skeleton._GetBone(grandparent_id);
  if grandparent_bone.joint = nil then exit;

  result:=true;
end;

function TOgfSimpleGrandparentIKSolver.IsTransformAllowedForBone(bone_id: TBoneID): boolean;
var
  bone:TOgfBoneData;
  parent_name:string;
  parent_id:TBoneID;
begin
  result:=false;
  if not IsProperlyConfigured() then exit;

  if bone_id = _target_bone then begin
    result:=true;
  end else begin
    bone:=_skeleton._GetBone(_target_bone);
    if bone.joint = nil then exit;

    parent_name:=bone.bone.GetParentName();
    if length(parent_name)=0 then exit;
    parent_id:=_skeleton.GetBoneIdxByName(parent_name);
    if parent_id = bone_id then exit;

    result:=true;
  end;
end;

function TOgfSimpleGrandparentIKSolver.IsHandlerBone(bone_id: TBoneID): boolean;
begin
  result:=(bone_id = _target_bone);
end;

function TOgfSimpleGrandparentIKSolver.IsIkSolveNeededForBoneTransform(bone_id: TBoneID): boolean;
begin
  result:=false;
  if not IsTransformAllowedForBone(bone_id) then exit;

  if (_target_bone <> bone_id) and not _skeleton.IsBoneHasSuchParentOrGrandParent(_target_bone, bone_id) then exit;

  result:=true;
end;

function TOgfSimpleGrandparentIKSolver.SolveIK(bone_id: TBoneID; new_transform: FMatrix4x4): TOgfIkSolvingResult;
var
  target_bone, parent_bone, grandparent_bone, bone:TOgfBoneData;
  parent_id, grandparent_id:TBoneID;
  parent_name, grandparent_name:string;

  gm_child, gm_parent, gm_grandparent:FMatrix4x4;
  gp_child, gp_parent, gp_grandparent:FVector3;
  parent_limb_len:single;

  target_point, v:FVector3;
  m:FMatrix4x4;
  res:boolean;
  last_metric:single;

  k:TMotionKey;
begin
  result:=IKSolveNotNeeded;
  bone:=_skeleton._GetBone(bone_id);
  if bone.joint = nil then exit;

  if not IsIkSolveNeededForBoneTransform(bone_id) then exit;

  // This IK Solver operates using 3 bones: target (child), parent and grandparent
  // So, we need to check if we have all of them
  // We have to perform these checks on every call because user can edit skeleton structure at any moment
  result:=IKSolveFailed;
  target_bone:=_skeleton._GetBone(_target_bone);
  if target_bone.joint = nil then exit;

  parent_name:=target_bone.bone.GetParentName();
  if length(parent_name)=0 then exit;
  parent_id:=_skeleton.GetBoneIdxByName(parent_name);
  if parent_id = INVALID_BONE_ID then exit;
  parent_bone:=_skeleton._GetBone(parent_id);
  if parent_bone.joint = nil then exit;

  grandparent_name:=parent_bone.bone.GetParentName();
  if length(grandparent_name) = 0 then exit;
  grandparent_id:=_skeleton.GetBoneIdxByName(grandparent_name);
  if grandparent_id = INVALID_BONE_ID then exit;
  grandparent_bone:=_skeleton._GetBone(grandparent_id);
  if grandparent_bone.joint = nil then exit;


  if not _skeleton._GetWrkBoneSpaceToGlobalSpaceMatrix(_target_bone, gm_child) then exit;
  if not _skeleton._GetWrkBoneSpaceToGlobalSpaceMatrix(parent_id, gm_parent) then exit;
  if not _skeleton._GetWrkBoneSpaceToGlobalSpaceMatrix(grandparent_id, gm_grandparent) then exit;

  m_get_translation(gm_child, gp_child);
  m_get_translation(gm_parent, gp_parent);
  m_get_translation(gm_grandparent, gp_grandparent);

  v:=v_sub(gp_parent, gp_grandparent);

  v:=v_sub(gp_child, gp_parent);
  parent_limb_len:=v_magnitude(v);

  res:=false;
  if bone_id = _target_bone then begin
    m_get_translation(new_transform, target_point);

    if _RotateParentToPlaceChildOnDistanceToPoint(_skeleton, parent_id, target_point, parent_limb_len, _grandparent_bone_flags, last_metric) then begin
      res:=_RotateParentToPlaceChildOnDistanceToPoint(_skeleton, bone_id, target_point, 0, _parent_bone_flags, last_metric);
      if not res then begin
        // WTF?! parent rotated to provide a good distance, but child can't be properly oriented?!
        // Strange, but try just to aim child to target position

        //res:=_skeleton._AimChildBoneTo(bone_id, target_point);
      end;

      if res then begin
        parent_bone.joint._GetWrkTransform(m);
        _last_solved_pose.SetBone(parent_name, m);

        grandparent_bone.joint._GetWrkTransform(m);
        _last_solved_pose.SetBone(grandparent_name, m);
      end;


      // get current child offset to prevent increasing calculation error
      target_bone.joint._GetWrkTransform(m);
      m_get_translation(m, v);

      // set child target_bone position & orientation
      if not _skeleton._ConvertTransformFromGlobalIntoParentSpaceOfWrkBone(bone_id, new_transform, m) then exit;
      m_translate_over(m, v);

      target_bone.joint._AssignWrkTransform(m);
    end;
  end else begin
    // bone_id matches an ancestor of _target_bone
    // Need to preserve child position
    if not _skeleton._ConvertTransformFromGlobalIntoParentSpaceOfWrkBone(bone_id, new_transform, m) then exit;
    bone.joint._AssignWrkTransform(m);

    if _RotateParentToPlaceChildOnDistanceToPoint(_skeleton, parent_id, gp_child, parent_limb_len, _grandparent_bone_flags, last_metric) then begin
      res:=_RotateParentToPlaceChildOnDistanceToPoint(_skeleton, _target_bone, gp_child, 0, _parent_bone_flags, last_metric);
      if not res then begin
        res:=_skeleton._AimChildBoneTo(bone_id, target_point);
      end;

      if res then begin
        parent_bone.joint._GetWrkTransform(m);
        _last_solved_pose.SetBone(parent_name, m);

        grandparent_bone.joint._GetWrkTransform(m);
        _last_solved_pose.SetBone(grandparent_name, m);
      end;

      // get current child offset to prevent increasing calculation error
      target_bone.joint._GetWrkTransform(m);
      m_get_translation(m, v);

      // set child target_bone position & orientation
      if not _skeleton._ConvertTransformFromGlobalIntoParentSpaceOfWrkBone(_target_bone, gm_child, m) then exit;
      m_translate_over(m, v);

      target_bone.joint._AssignWrkTransform(m);
    end;
  end;

  if res then begin
    result:=IKSolveSuccess;
  end;
end;

class function TOgfSimpleGrandparentIKSolver.GetFlagsFromString(s: string): TOgfSimpleGrandparentIKSolverFlags;
begin
  s:=lowercase(s);
  result:=0;
  if pos('x', s)>0 then begin
    result:=result or SIMPLE_GP_IKSOLVER_FLAG_DISABLE_X_AXIS;
  end;
  if pos('y', s)>0 then begin
    result:=result or SIMPLE_GP_IKSOLVER_FLAG_DISABLE_Y_AXIS;
  end;
  if pos('z', s)>0 then begin
    result:=result or SIMPLE_GP_IKSOLVER_FLAG_DISABLE_Z_AXIS;
  end;
end;

{ TOgfIKSolverBase }

constructor TOgfIKSolverBase.Create(skeleton: TOgfSkeleton);
begin
  _skeleton:=skeleton;
end;

{ TOgfMotionRefs }

constructor TOgfMotionRefs.Create;
begin
  Reset();
end;

destructor TOgfMotionRefs.Destroy;
begin
  inherited Destroy;
end;

procedure TOgfMotionRefs.Reset;
begin
  _loaded:=false;
  setlength(_refs, 0);
end;

function TOgfMotionRefs.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfMotionRefs.Deserialize(rawdata: string; chunk_id: word): boolean;
var
  s:string;
  i,j:integer;
  cnt:cardinal;
  item:string;
begin
  Reset();
  result:=false;
  _chunk_id:=chunk_id;

  if chunk_id = CHUNK_OGF_S_MOTION_REFS then begin
    if not DeserializeZStringAndSplit(rawdata, s) then exit;
    item:='';
    for i:=1 to length(s) do begin
      if (i=length(s)) or (s[i]=',') then begin
        if (i=length(s)) then begin
          item:=item+s[i];
        end;

        item:=trim(item);
        if length(item)=0 then continue;

        j:=length(_refs);
        setlength(_refs, j+1);
        _refs[j]:=item;

        item:='';
      end else begin
        item:=item+s[i];
      end;
    end;


    _loaded:=true;
  end else if chunk_id = CHUNK_OGF_S_MOTION_REFS2 then begin
    if length(rawdata) < sizeof(cardinal) then exit;
    cnt:= pcardinal(@PAnsiChar(rawdata)[0])^;
    AdvanceString(rawdata, sizeof(cardinal));

    for i:=0 to cnt-1 do begin
      if not DeserializeZStringAndSplit(rawdata, item) then exit;
      j:=length(_refs);
      setlength(_refs, j+1);
      _refs[j]:=item;
    end;

    _loaded:=true;
  end;

  result:=_loaded;
end;

function TOgfMotionRefs.Serialize(): string;
var
  i:integer;
begin
  result:='';
  if not Loaded() then exit;

  if _chunk_id = CHUNK_OGF_S_MOTION_REFS then begin
    for i:=0 to length(_refs)-1 do begin
      result:=result+_refs[i];
      if i<length(_refs)-1 then begin
        result:=result+',';
      end else begin
        result:=result+chr(0);
      end;
    end;
  end else if _chunk_id = CHUNK_OGF_S_MOTION_REFS2 then begin
    result:=result+SerializeCardinal(length(_refs));
    for i:=0 to length(_refs)-1 do begin
      result:=result+_refs[i]+chr(0);
    end;
  end;
end;

function TOgfMotionRefs.GetChunkId(): word;
begin
  result:=INVALID_CHUNK;
  if not Loaded() then exit;

  result:=_chunk_id;
end;

function TOgfMotionRefs.AddRef(filename: string): integer;
var
  i:integer;
begin
  i:=length(_refs);
  setlength(_refs, i+1);
  _refs[i]:=filename;

  if not Loaded() then begin
    _chunk_id:=CHUNK_OGF_S_MOTION_REFS2;
    _loaded:=true;
  end;
  result:=i;
end;

function TOgfMotionRefs.RefsCount(): integer;
begin
  result:=0;
  if not Loaded() then exit;

  result:=length(_refs);
end;

{ TOgfSkeletonPose }

function TOgfSkeletonPose._IdxByName(name: string): integer;
var
  i:integer;
begin
  result:=-1;
  for i:=0 to length(_bones)-1 do begin
    if _bones[i].name = name then begin
      result:=i;
      break;
    end;
  end;
end;

procedure TOgfSkeletonPose._Calc(i: integer);
begin
  if (i < 0) or (i >= length(_bones)) then exit;
  if _bones[i].calculated then exit;

  if _bones[i].mode = OgfSkeletonBonePoseDataModeKey then begin
    m_rotation(_bones[i].transform, _bones[i].key.Q);
    m_translate_over(_bones[i].transform, _bones[i].key.T);
    CorrectAlmostZeroOrOnesInRot(_bones[i].transform);
    _bones[i].calculated:=true;
  end else if _bones[i].mode = OgfSkeletonBonePoseDataModeTransform then begin
    CorrectAlmostZeroOrOnesInRot(_bones[i].transform);
    q_rotation(_bones[i].key.Q, _bones[i].transform);
    m_get_translation(_bones[i].transform, _bones[i].key.T);
    _bones[i].calculated:=true;
  end;
end;

constructor TOgfSkeletonPose.Create();
begin
  Reset();
end;

procedure TOgfSkeletonPose.Reset();
begin
  setlength(_bones, 0);
end;

procedure TOgfSkeletonPose.SetBone(bonename: string; var transform: FMatrix4x4; force: boolean);
var
  idx:integer;
  new_transform:FMatrix4x4;
  is_new:boolean;
begin
  idx:=_IdxByName(bonename);
  is_new:=false;
  if idx<0 then begin
    idx:=length(_bones);
    setlength(_bones, idx+1);
    _bones[idx].name:=bonename;
  end else if not force then begin
    _Calc(idx);
    if IsRotSame(transform, _bones[idx].transform) then exit;
  end;

  _bones[idx].mode:=OgfSkeletonBonePoseDataModeTransform;
  _bones[idx].calculated:=false;
  _bones[idx].transform:=transform;
end;

procedure TOgfSkeletonPose.SetBone(bonename: string; var key: TMotionKey; force: boolean);
var
  idx:integer;
  new_transform:FMatrix4x4;
  is_new:boolean;
begin
  idx:=_IdxByName(bonename);
  is_new:=false;
  if idx<0 then begin
    idx:=length(_bones);
    setlength(_bones, idx+1);
    _bones[idx].name:=bonename;
  end else if not force then begin
    _Calc(idx);
    m_rotation(new_transform, key.Q);
    if IsRotSame(new_transform, _bones[idx].transform) then exit;
  end;

  _bones[idx].mode:=OgfSkeletonBonePoseDataModeKey;
  _bones[idx].calculated:=false;
  _bones[idx].key:=key;
end;

function TOgfSkeletonPose.GetBoneKey(bonename: string; var key: TMotionKey): boolean;
var
  idx:integer;
begin
  result:=false;
  idx:=_IdxByName(bonename);
  if idx>=0 then begin
    if (_bones[idx].mode<>OgfSkeletonBonePoseDataModeKey) and (not _bones[idx].calculated) then begin
      _Calc(idx);
    end;

    key:=_bones[idx].key;
    result:=true;
  end;
end;

function TOgfSkeletonPose.GetBoneTransform(bonename: string; var transform: FMatrix4x4): boolean;
var
  idx:integer;
begin
  result:=false;
  idx:=_IdxByName(bonename);
  if idx>=0 then begin
    if (_bones[idx].mode<>OgfSkeletonBonePoseDataModeTransform) and (not _bones[idx].calculated) then begin
      _Calc(idx);
    end;

    transform:=_bones[idx].transform;
    result:=true;
  end;
end;

function TOgfSkeletonPose.GetPreviouslySetBoneDataType(bonename: string): TOgfSkeletonBonePoseDataMode;
var
  idx:integer;
begin
  result:=OgfSkeletonBonePoseDataModeNone;
  idx:=_IdxByName(bonename);
  if idx>=0 then begin
    result:=_bones[idx].mode;
  end;
end;

function TOgfSkeletonPose.ForgetBone(bonename: string): boolean;
var
  idx:integer;
begin
  result:=false;
  idx:=_IdxByName(bonename);
  if idx>=0 then begin
    _bones[idx] := _bones[length(_bones)-1];
    setlength(_bones, length(_bones)-1);

    result:=true;
  end;
end;

function TOgfSkeletonPose.GetBonename(idx: integer): string;
begin
  result:='';
  if (idx>=0) and (idx < length(_bones)) then begin
    result:=_bones[idx].name;
  end;
end;

function TOgfSkeletonPose.BonesCount(): integer;
begin
  result:=length(_bones);
end;

function TOgfSkeletonPose.Serialize(): string;
var
  i:integer;
begin
  result:='';

  result:=result+SerializeCardinal(length(_bones));
  for i:=0 to length(_bones)-1 do begin
    result:=result+_bones[i].name;
    result:=result+chr(0);
    result:=result+SerializeCardinal(cardinal(_bones[i].mode));
    if _bones[i].mode = OgfSkeletonBonePoseDataModeKey then begin
      result:=result+SerializeFloat(_bones[i].key.Q.x);
      result:=result+SerializeFloat(_bones[i].key.Q.y);
      result:=result+SerializeFloat(_bones[i].key.Q.z);
      result:=result+SerializeFloat(_bones[i].key.Q.w);
      result:=result+SerializeFloat(_bones[i].key.T.x);
      result:=result+SerializeFloat(_bones[i].key.T.y);
      result:=result+SerializeFloat(_bones[i].key.T.z);
    end else if _bones[i].mode = OgfSkeletonBonePoseDataModeTransform then begin
      result:=result+SerializeFloat(_bones[i].transform.i.x);
      result:=result+SerializeFloat(_bones[i].transform.i.y);
      result:=result+SerializeFloat(_bones[i].transform.i.z);
      result:=result+SerializeFloat(_bones[i].transform.i.w);

      result:=result+SerializeFloat(_bones[i].transform.j.x);
      result:=result+SerializeFloat(_bones[i].transform.j.y);
      result:=result+SerializeFloat(_bones[i].transform.j.z);
      result:=result+SerializeFloat(_bones[i].transform.j.w);

      result:=result+SerializeFloat(_bones[i].transform.k.x);
      result:=result+SerializeFloat(_bones[i].transform.k.y);
      result:=result+SerializeFloat(_bones[i].transform.k.z);
      result:=result+SerializeFloat(_bones[i].transform.k.w);

      result:=result+SerializeFloat(_bones[i].transform.c.x);
      result:=result+SerializeFloat(_bones[i].transform.c.y);
      result:=result+SerializeFloat(_bones[i].transform.c.z);
      result:=result+SerializeFloat(_bones[i].transform.c.w);
    end;
  end;
end;

function TOgfSkeletonPose.Deserialize(var s: string): boolean;
var
  cnt, mode:cardinal;
  i:integer;
begin
  result:=false;
  Reset();

  if length(s) < sizeof(cardinal) then exit;
  cnt:=PCardinal(PAnsiChar(s))^;
  if not AdvanceString(s, sizeof(cnt)) then exit;

  setlength(_bones, cnt);
  for i:=0 to cnt-1 do begin
    _bones[i].calculated:=false;
    _bones[i].mode:=OgfSkeletonBonePoseDataModeNone;

    if not DeserializeZStringAndSplit(s, _bones[i].name) then exit;
    if length(s) < sizeof(cardinal) then exit;
    mode:=PCardinal(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;

    if TOgfSkeletonBonePoseDataMode(mode) = OgfSkeletonBonePoseDataModeKey then begin
      if length(s) < sizeof(_bones[i].key) then exit;
      _bones[i].key.Q.x:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].key.Q.y:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].key.Q.z:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].key.Q.w:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].key.T.x:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].key.T.y:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].key.T.z:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].mode:=OgfSkeletonBonePoseDataModeKey;
    end else if TOgfSkeletonBonePoseDataMode(mode) = OgfSkeletonBonePoseDataModeTransform then begin
      if length(s) < sizeof(_bones[i].transform) then exit;

      _bones[i].transform.i.x:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].transform.i.y:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].transform.i.z:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].transform.i.w:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;

      _bones[i].transform.j.x:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].transform.j.y:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].transform.j.z:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].transform.j.w:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;

      _bones[i].transform.k.x:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].transform.k.y:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].transform.k.z:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].transform.k.w:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;

      _bones[i].transform.c.x:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].transform.c.y:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].transform.c.z:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].transform.c.w:=PSingle(PAnsiChar(s))^; if not AdvanceString(s, sizeof(single)) then exit;
      _bones[i].mode:=OgfSkeletonBonePoseDataModeTransform;
    end;
  end;

  result:=true;
end;

procedure TOgfSkeletonPose.CopyTo(dest: TOgfSkeletonPose);
var
  i:integer;
begin
  dest.Reset();
  for i:=0 to length(_bones)-1 do begin
    dest.SetBone(_bones[i].name, _bones[i].key);
  end;
end;

destructor TOgfSkeletonPose.Destroy();
begin
  Reset();
  inherited Destroy();
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

function TOgfMotionMark.GetName(): string;
begin
  if _loaded then begin
    result:=_name;
  end else begin
    result:='';
  end;
end;

procedure TOgfMotionMark.SetName(name: string);
begin
  _name:=name;
end;

function TOgfMotionMark.GetIntervalsCount(): integer;
begin
  if _loaded then begin
    result:=length(_intervals);
  end else begin
    result:=0;
  end;
end;

function TOgfMotionMark.GetInterval(idx: integer): TOgfMotionMarkInterval;
begin
  result.start:=0;
  result.finish:=0;
  if not _loaded then exit;
  if (idx>=0) and (idx < length(_intervals)) then begin
    result:=_intervals[idx];
  end;
end;

procedure TOgfMotionMark.AddInterval(interval: TOgfMotionMarkInterval);
var
  i:integer;
begin
  i:=length(_intervals);
  setlength(_intervals, i+1);
  _intervals[i]:=interval;
  _loaded:=true;
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

function TOgfMotionMarks.Serialize(force_v4: boolean): string;
var
  i:integer;
begin
  result:='';
  if not _loaded then begin
    if force_v4 then begin
      result:=result+SerializeCardinal(0);
    end;
    exit;
  end;


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

function TOgfMotionMarks.Count(): integer;
begin
  result:=length(_marks);
end;

function TOgfMotionMarks.Get(idx: integer): TOgfMotionMark;
begin
  result:=nil;

  if (idx >= 0) and (idx < length(_marks)) then begin
    result:=_marks[idx];
  end;
end;

function TOgfMotionMarks.Add(mark_name: string; interval: TOgfMotionMarkInterval): integer;
var
  i:integer;
begin
  result:=-1;

  for i:=0 to length(_marks)-1 do begin
    if _marks[i].GetName() = mark_name then begin
      _marks[i].AddInterval(interval);
      result:=i;
      break;
    end;
  end;

  if result<0 then begin
    i:=length(_marks);
    setlength(_marks, i+1);
    _marks[i]:=TOgfMotionMark.Create();
    _marks[i].AddInterval(interval);
    _marks[i].SetName(mark_name);
    result:=i;
  end;


  if result>=0 then begin
    _loaded:=true;
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

function TOgfMotionDef.Serialize(force_v4: boolean): string;
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
  result:=result+_data.marks.Serialize(force_v4); // for version <4 returns an empty string because not loaded

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

procedure TOgfMotionBoneParams._SetName(new_name: string);
begin
  _name:=new_name;
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
    result:=result+_defs[i].Serialize(version>=4);
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
  data:TOgfMotionDefData;
  motionid:integer;
begin
  result:=false;
  if not Loaded() then exit;
  if (idx < 0) or (idx >= MotionsDefsCount()) then exit;

  motionid:=_defs[idx].GetData().motion_id;
  _defs[idx].Free;
  for i:=idx to length(_defs)-2 do begin
    _defs[i]:=_defs[i+1];
  end;
  setlength(_defs, length(_defs)-1);

  for i:=0 to length(_defs)-1 do begin
    data:=_defs[i].GetData();
    if data.motion_id>=motionid then begin
      data.motion_id:=data.motion_id-1;
      _defs[i].SetData(data);
    end;
  end;

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
      min16.x1:=-KEY_Quant16;
      min16.y1:=-KEY_Quant16;
      min16.z1:=-KEY_Quant16;

      max16.x1:=KEY_Quant16;
      max16.y1:=KEY_Quant16;
      max16.z1:=KEY_Quant16;

      min_limit:=Qt16ToT(@min16, @_sizeT, @_initT);
      max_limit:=Qt16ToT(@max16, @_sizeT, @_initT);
    end else begin
      min8.x1:=-KEY_Quant8;
      min8.y1:=-KEY_Quant8;
      min8.z1:=-KEY_Quant8;

      max8.x1:=KEY_Quant8;
      max8.y1:=KEY_Quant8;
      max8.z1:=KEY_Quant8;

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

  d:=v_sub(max_limit, min_limit);
  d2:=v_mul(d, 0.5);
  new_initt:=v_add(min_limit, d2);
  new_sizet:=v_mul(d2, 1/KEY_Quant16);

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

      trans:=v_sub(trans, new_initt);

      if abs(d.x)>EPS then begin
        qt_value:= trans.x / new_sizet.x;
        new_data[i].x1:=clamp(qt_value, -KEY_Quant16, KEY_Quant16);
      end else begin
        new_data[i].x1:=0;
      end;

      if abs(d.y)>EPS then begin
        qt_value:= trans.y / new_sizet.y;
        new_data[i].y1:=clamp(qt_value, -KEY_Quant16, KEY_Quant16);
      end else begin
        new_data[i].y1:=0;
      end;

      if abs(d.z)>EPS then begin
        qt_value:= trans.z / new_sizet.z;
        new_data[i].z1:=clamp(qt_value, -KEY_Quant16, KEY_Quant16);
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

procedure TOgfMotionBoneTrack._Optimize();
var
  can_simplify_rot, can_simplify_trans, is_same:boolean;
  k, k_first:TMotionKey;
  i:integer;
begin
  if not _rot_keys_present and not _trans_keys_present then exit;
  if _frames_count = 0 then exit;

  can_simplify_rot:=true;
  can_simplify_trans:=true;
  for i:=0 to _frames_count-1 do begin;
    if not GetKey(i, k) then exit;
    if i = 0 then begin
      k_first:=k;
    end else begin
      if _rot_keys_present then begin
        is_same := (abs(k.Q.x - k_first.Q.x) < EPS)
               and (abs(k.Q.y - k_first.Q.y) < EPS)
               and (abs(k.Q.z - k_first.Q.z) < EPS)
               and (abs(k.Q.w - k_first.Q.w) < EPS);
        can_simplify_rot:= can_simplify_rot and is_same;
      end;


      if _trans_keys_present then begin;
        is_same := (abs(k.T.x - k_first.T.x) < EPS)
               and (abs(k.T.y - k_first.T.y) < EPS)
               and (abs(k.T.z - k_first.T.z) < EPS);
        can_simplify_trans:=can_simplify_trans and is_same
      end;
    end;
  end;

  if _rot_keys_present and can_simplify_rot then begin
    _rot_keys_present := false;
    setlength(_rot_keys_rawdata, sizeof(TOgfMotionKeyQR));
  end;

  if _trans_keys_present and can_simplify_trans then begin
    _trans_keys_present:=false;

    _is16bittransform:=true;
    setlength(_trans_keys_rawdata, sizeof(TOgfMotionKeyQT16));
    FillChar(_trans_keys_rawdata[0], length(_trans_keys_rawdata), 0);
    set_zero(_sizeT);
    _initT:=k_first.T;
  end;

end;

constructor TOgfMotionBoneTrack.Create;
begin
  Reset();
end;

constructor TOgfMotionBoneTrack.Create(default_key: TMotionKey; frames_count: integer);
var
  pqr:pTOgfMotionKeyQR;
begin
  Create();

  _rot_keys_present:=false;
  setlength(_rot_keys_rawdata, sizeof(TOgfMotionKeyQR));

  pqr:=pTOgfMotionKeyQR(@_rot_keys_rawdata[0]);
  pqr^.w:= clamp(default_key.q.w * KEY_Quant16, -KEY_Quant16, KEY_Quant16);
  pqr^.x:= clamp(default_key.q.x * KEY_Quant16, -KEY_Quant16, KEY_Quant16);
  pqr^.y:= clamp(default_key.q.y * KEY_Quant16, -KEY_Quant16, KEY_Quant16);
  pqr^.z:= clamp(default_key.q.z * KEY_Quant16, -KEY_Quant16, KEY_Quant16);


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

  _Optimize();

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

function TransformToMotionKey(var transform: FMatrix4x4): TMotionKey;
begin
  m_get_translation(transform, result.T);
  q_rotation(result.Q, transform);
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

    trans:=v_sub(key.T, _initT);

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

function TOgfMotionBoneTrack.SlerpBetweenKeys(start_idx: integer; end_idx: integer; factor: single; pos: boolean; rot: boolean): boolean;
var
  i:integer;
  k1, k2, kr:TMotionKey;
  tm:single;
begin
  result:=false;
  if (start_idx<0) or (start_idx>=FramesCount()) then exit;
  if (end_idx<0) or (end_idx>=FramesCount()) then exit;


  if abs(start_idx - end_idx)<2 then begin
    result:=true;
    exit;
  end;

  if start_idx > end_idx then begin
    i:=start_idx;
    start_idx:=end_idx;
    end_idx:=i;
  end;

  if not GetKey(start_idx, k1) then exit;
  if not GetKey(end_idx, k2) then exit;

  result:=true;
  for i:=start_idx+1 to end_idx-1 do begin
    tm:= (i-start_idx)/(end_idx-start_idx);
    tm:=power(tm, factor);

    if GetKey(i, kr) then begin
      KeysSlerp(kr, k1, k2, tm, pos, rot);
      result:=SetKey(i, kr) and result;
    end else begin
      result:=false;
    end;
  end;
end;

function TOgfMotionBoneTrack.MakeStatic(key: TMotionKey): boolean;
var
  l:integer;
  pqr:pTOgfMotionKeyQR;
begin
  result:=false;
  l:=FramesCount();

  Reset();

  _loaded:=true;
  _is16bittransform:=true;
  _rot_keys_present:=false;
  _trans_keys_present:=false;
  _frames_count:=l;

  setlength(_rot_keys_rawdata, sizeof(TOgfMotionKeyQR));
  pqr:=pTOgfMotionKeyQR(@_rot_keys_rawdata[0]);
  pqr^.w:= clamp(key.q.w * KEY_Quant16, -KEY_Quant16, KEY_Quant16);
  pqr^.x:= clamp(key.q.x * KEY_Quant16, -KEY_Quant16, KEY_Quant16);
  pqr^.y:= clamp(key.q.y * KEY_Quant16, -KEY_Quant16, KEY_Quant16);
  pqr^.z:= clamp(key.q.z * KEY_Quant16, -KEY_Quant16, KEY_Quant16);

  setlength(_trans_keys_rawdata, sizeof(TOgfMotionKeyQT16));
  FillChar(_trans_keys_rawdata[0], length(_trans_keys_rawdata), 0);
  set_zero(_sizeT);
  _initT:=key.T;

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

class procedure TOgfMotionBoneTrack.KeysSlerp(var k_out: TMotionKey; k1: TMotionKey; k2: TMotionKey; tm: single; pos: boolean; rot: boolean);
var
  dt:FVector3;
begin
  if rot then begin
    if (abs(k1.Q.x - k2.Q.x)>EPS) or (abs(k1.Q.y - k2.Q.y)>EPS) or (abs(k1.Q.z - k2.Q.z)>EPS) or (abs(k1.Q.w - k2.Q.w)>EPS) then begin
      q_slerp(k_out.Q, k1.Q, k2.Q, tm);
    end else begin
      k_out.Q:=k1.Q;
    end;
  end;

  if pos then begin
    dt:=v_sub(k2.T, k1.T);
    if (abs(dt.x)>EPS) or (abs(dt.y)>EPS) or (abs(dt.z)>EPS) then begin
      dt:=v_mul(dt, tm);
      k_out.T:=v_add(k1.T, dt);
    end else begin
      k_out.T:=k1.T;
    end;
  end;
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

function TOgfMotionTrack.MakeBoneStatic(track_bone_idx: integer; k: TMotionKey): boolean;
begin
  result:=false;
  if not Loaded() then exit;

  if (track_bone_idx>=0) and (track_bone_idx < length(_bone_tracks)) then begin
    result:=_bone_tracks[track_bone_idx].MakeStatic(k);
  end;
end;

function TOgfMotionTrack.InterpolateBoneKeys(track_bone_idx: integer; start_key_idx: integer; end_key_idx: integer; factor: single; pos: boolean;  rot: boolean): boolean;
begin
  result:=false;
  if not Loaded() then exit;

  if (track_bone_idx>=0) and (track_bone_idx < length(_bone_tracks)) then begin
    result:=_bone_tracks[track_bone_idx].SlerpBetweenKeys(start_key_idx, end_key_idx, factor, pos, rot);
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
  i, l:integer;
begin
  result:=false;
  if not Loaded() then exit();
  l:=length(_motions);
  if (idx >= 0) and (idx < l) then begin
    _motions[idx].Free;
    for i:=idx to l-2 do begin
      _motions[i]:=_motions[i+1];
    end;
    setlength(_motions, l-1);

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

function TOgfChildrenContainer.Split(id: integer; var filter: TVertexFlaggedItems): integer;
var
  data:string;
  isok:boolean;
  i:integer;
begin
  result:=-1;
  if not Loaded() or (length(_children)<=id) then exit;

  if length(filter)<>_children[id].GetVerticesCount() then exit;
  data:=_children[id].Serialize();
  result:=Insert(data, id+1);
  if result>=0 then begin
    isok:=_children[id].FilterVertices(filter);
    for i:=0 to length(filter)-1 do begin
      filter[i].is_flagged:=not filter[i].is_flagged;
      isok:=_children[id+1].FilterVertices(filter) and isok;
      if not isok then begin
        result:=-1;
      end;
    end;
  end;
end;

{ TOgfSkeleton }

constructor TOgfSkeleton.Create();
begin
  Reset;
end;

procedure TOgfSkeleton.Reset;
begin
  _loaded:=false;
  _data.joints:=nil;
  _data.bones:=nil;
  _animations:=nil;
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


function TOgfSkeleton._Build(desc: TOgfBonesContainer; ik: TOgfJointsDataContainer): boolean;
begin
  result:=false;
  if desc.Count()<>ik.Count() then exit;
  Reset();
  _data.joints:=ik;
  _data.bones:=desc;

  _SetBindPoseForWork();

  _loaded:=true;
  result:=true;
end;

procedure TOgfSkeleton.AssignAnimations(animations: TOgfAnimationsParser);
begin
  _animations:=animations;
end;

function TOgfSkeleton.GetBonesCount(): integer;
begin
  if not Loaded() then begin
    result:=0;
    exit;
  end;

  result:=_data.bones.Count();
end;

function TOgfSkeleton._GetBone(id: TBoneID): TOgfBoneData;
begin
  result.bone:=nil;
  result.joint:=nil;
  if not Loaded() then exit;

  result.bone:=_data.bones.Bone(id);
  result.joint:=_data.joints.Get(id);
end;

function TOgfSkeleton._GetBoneByName(name: string; var output: TOgfBoneData): boolean;
var
  idx:integer;
begin
  result:=false;
  idx:=GetBoneIdxByName(name);
  if idx >= 0 then begin
    output.bone:=_data.bones.Bone(idx);
    output.joint:=_data.joints.Get(idx);
    result:=true;
  end;
end;

function TOgfSkeleton._SetKeyPoseForWork(anim_name: string; key_id: integer): boolean;
var
  key:TMotionKey;
  anim_idx:integer;
  b:TOgfBoneData;
  i:integer;
  name:string;
begin
  result:=false;
  if not Loaded() then exit;
  if _animations=nil then exit;;
  anim_idx := _animations.GetAnimationIdByName(anim_name);
  if anim_idx < 0 then exit;

  for i:=0 to GetBonesCount()-1 do begin
    b:=_GetBone(i);
    name:=b.bone.GetName();
    if _animations.GetAnimationKeyForBone(anim_name,name,key_id, key) then begin
      b.joint._AssignWrkKey(key);
    end;
  end;
  result:=true;
end;

function TOgfSkeleton._SetBindPoseForWork(): boolean;
var
  i:integer;
  b:TOgfBoneData;
begin
  result:=false;
  if not Loaded() then exit;

  for i:=0 to GetBonesCount()-1 do begin
    b:=_GetBone(i);
    if b.joint<>nil then begin;
      b.joint._AssignBindWrkPose();
    end;
  end;
  result:=true;
end;

function TOgfSkeleton._GetWrkPose(pose: TOgfSkeletonPose): boolean;
var
  b:TOgfBoneData;
  i:integer;
  key:TMotionKey;
begin
  result:=false;
  if not Loaded() then exit;

  pose.Reset();

  for i:=0 to GetBonesCount()-1 do begin
    b:=_GetBone(i);
    if b.bone = nil then continue;
    b.joint._GetWrkKey(key);
    pose.SetBone(b.bone.GetName(), key);
  end;
  result:=true;
end;

function TOgfSkeleton._SetWrkPose(pose: TOgfSkeletonPose): integer;
var
  i:integer;
  b:TOgfBoneData;
  m:FMatrix4x4;
  k:TMotionKey;
  name:string;
  datatype: TOgfSkeletonBonePoseDataMode;
begin
  result:=0;
  if not Loaded() then exit;

  for i:=0 to GetBonesCount()-1 do begin
    b:=_GetBone(i);
    if b.bone = nil then continue;

    name:=b.bone.GetName();
    datatype:=pose.GetPreviouslySetBoneDataType(name);
    if (datatype = OgfSkeletonBonePoseDataModeKey) and pose.GetBoneKey(name, k) then begin
      b.joint._AssignWrkKey(k);
      result:=result+1;
    end else if (datatype = OgfSkeletonBonePoseDataModeTransform) and pose.GetBoneTransform(name, m) then begin
      b.joint._AssignWrkTransform(m);
      result:=result+1;
    end;
  end;
end;

function TOgfSkeleton._GetWrkBoneLocalTransform(idx: TBoneID; var m: FMatrix4x4): boolean;
var
  b:TOgfBoneData;
begin
  result:=false;
  b:=_GetBone(idx);
  if b.joint=nil then exit;

  b.joint._GetWrkTransform(m);
  result:=true;
end;

function TOgfSkeleton._GetWrkBoneSpaceToGlobalSpaceMatrix(idx: TBoneID; var m: FMatrix4x4): boolean;
var
  parent_transform, my_transform:FMatrix4x4;
  b:TOgfBoneData;
  parentid:TBoneId;

begin
  result:=false;
  if Loaded() and (idx<>INVALID_BONE_ID) and (idx<GetBonesCount()) then begin
    b:=_GetBone(idx);
    parentid:=GetBoneParentIdx(idx);

    if parentid<>INVALID_BONE_ID then begin
      b.joint._GetWrkTransform(my_transform);
      if _GetWrkBoneSpaceToGlobalSpaceMatrix(parentid, parent_transform) then begin
        m:=m_mul(parent_transform, my_transform);
        result:=true;
      end;
    end else begin
      b.joint._GetWrkTransform(m);
      result:=true;
    end;
  end;
end;

function TOgfSkeleton._GetGlobalSpaceToWrkBoneSpaceMatrix(idx: TBoneID; var m: FMatrix4x4): boolean;
var
  parent_transform, my_transform:FMatrix4x4;
  b:TOgfBoneData;
  parentid:TBoneId;
begin
  result:=false;
  if Loaded() and (idx<>INVALID_BONE_ID) and (idx<GetBonesCount()) then begin
    b:=_GetBone(idx);
    parentid:=GetBoneParentIdx(idx);
    if parentid<>INVALID_BONE_ID then begin
      b.joint._GetWrkTransform(my_transform);
      if _GetGlobalSpaceToWrkBoneSpaceMatrix(parentid, parent_transform) then begin
        my_transform:=m_invert43(my_transform);
        m:=m_mul(my_transform, parent_transform);
        result:=true;
      end;
    end else begin
      b.joint._GetWrkTransform(m);
      m:=m_invert43(m);
      result:=true;
    end;
  end;
end;

function TOgfSkeleton._ConvertGlobalCoordinatesIntoWrkBoneSpace(bone_idx: TBoneID; in_v: FVector3; var out_v: FVector3): boolean;
var
  m, out_m:FMatrix4x4;
begin
 // TODO: vector multiplying instead of matrix multiplying in _ConvertTransformFromGlobalIntoParentSpaceOfWrkBone?
  result:=false;

  m_identity(m);
  m_translate_over(m, in_v);

  if _ConvertTransformFromGlobalIntoWrkBoneSpace(bone_idx, m, out_m) then begin
    m_get_translation(out_m, out_v);
    result:=true;
  end;
end;

function TOgfSkeleton._ConvertGlobalCoordinatesIntoParentSpaceOfWrkBone(child_bone_idx: TBoneID; in_v: FVector3; var out_v: FVector3): boolean;
var
  parent_bone_idx:TBoneID;
begin
  result:=false;
  parent_bone_idx:=GetBoneParentIdx(child_bone_idx);
  if parent_bone_idx = INVALID_BONE_ID then begin
    // no parent bone, so parent is already global space; no need to convert
    out_v:=in_v;
  end else begin
    result:=_ConvertGlobalCoordinatesIntoWrkBoneSpace(parent_bone_idx, in_v, out_v);
  end;
end;

function TOgfSkeleton._ConvertTransformFromGlobalIntoWrkBoneSpace(bone_idx: TBoneID; in_m: FMatrix4x4; var out_m: FMatrix4x4): boolean;
var
  m:FMatrix4x4;
begin
  result:=false;
  if not _GetGlobalSpaceToWrkBoneSpaceMatrix(bone_idx, m) then exit;
  out_m:=m_mul(m, in_m);
  result:=true;
end;

function TOgfSkeleton._ConvertTransformFromGlobalIntoParentSpaceOfWrkBone(child_bone_idx: TBoneID; in_m: FMatrix4x4; var out_m: FMatrix4x4): boolean;
var
  parent_bone_idx:TBoneID;
begin
  result:=false;
  parent_bone_idx:=GetBoneParentIdx(child_bone_idx);
  if parent_bone_idx = INVALID_BONE_ID then begin
    // no parent bone, so parent is already global space; no need to convert
    out_m:=in_m;
  end else begin
    result:=_ConvertTransformFromGlobalIntoWrkBoneSpace(parent_bone_idx, in_m, out_m);
  end;
end;

function TOgfSkeleton._ConvertTransformFromWrkBoneSpaceIntoGlobal(bone_idx: TBoneID; in_m: FMatrix4x4; var out_m: FMatrix4x4): boolean;
var
  m:FMatrix4x4;
begin
  result:=false;
  if not _GetGlobalSpaceToWrkBoneSpaceMatrix(bone_idx, m) then exit;
  m:=m_invert43(m);
  out_m:=m_mul(m, in_m);
  result:=true;
end;

function TOgfSkeleton._ConvertTransformFromParentSpaceOfWrkBoneIntoGlobal(child_bone_idx: TBoneID; in_m: FMatrix4x4; var out_m: FMatrix4x4): boolean;
var
  parent_bone_idx:TBoneID;
begin
  result:=false;
  parent_bone_idx:=GetBoneParentIdx(child_bone_idx);
  if parent_bone_idx = INVALID_BONE_ID then begin
    // no parent bone, so parent is already global space; no need to convert
    out_m:=in_m;
    result:=true;
  end else begin
    result:=_ConvertTransformFromWrkBoneSpaceIntoGlobal(parent_bone_idx, in_m, out_m);
  end;
end;

function TOgfSkeleton._GetWrkBoneTransformRelativeToBindPose(bone_idx: TBoneID; var m: FMatrix4x4): boolean;
var
  bone:TOgfBoneData;
  wrk_transform, bind_transform,bind_transform_inv:FMatrix4x4;
begin
  result:=false;
  if not _GetWrkBoneLocalTransform(bone_idx, wrk_transform) then exit;

  bone:=_GetBone(bone_idx);
  if bone.joint = nil then exit;
  bone.joint.GetBindTransformData(bind_transform);
  bind_transform_inv:=m_invert43(bind_transform);

  m:=m_mul(bind_transform_inv, wrk_transform);
  result:=true;
end;

function TOgfSkeleton._TryToUseAlreadyCalculatedKey(anim_name: string; bone_name: string; key_idx: integer; var transform: FMatrix4x4;  var out_key: TMotionKey): boolean;
var
  old_t:FMatrix4x4;
  old_key:TMotionKey;
  i:integer;
begin
  result:=false;
  for i:=0 to 2 do begin
    case i of
      0: if not _animations.GetAnimationKeyForBone(anim_name, bone_name, key_idx, old_key) then continue;
      1: if not _animations.GetAnimationKeyForBone(anim_name, bone_name, key_idx-1, old_key) then continue;
      2: if not _animations.GetAnimationKeyForBone(anim_name, bone_name, key_idx+1, old_key) then continue;
    else
      break;
    end;

    m_rotation(old_t, old_key.Q);
    CorrectAlmostZeroOrOnesInRot(old_t);

    if IsRotSame(transform, old_t) then begin
      out_key.Q:=old_key.Q;
      m_get_translation(transform, out_key.T);
      result:=true;
      break;
    end;
  end;
end;

function TOgfSkeleton._SetTransformKeyForAnimBone(anim_name: string; bone_name: string; key_idx: integer; transform: FMatrix4x4): boolean;
var
  key:TMotionKey;
begin
  CorrectAlmostZeroOrOnesInRot(transform);
  if not _TryToUseAlreadyCalculatedKey(anim_name, bone_name, key_idx, transform, key) then begin
    key:=TransformToMotionKey(transform);
  end;
  result:=_animations.SetAnimationKeyForBone(anim_name, bone_name, key_idx, key);
end;

function TOgfSkeleton._SetKeyForAnimBone(anim_name: string; bone_name: string; key_idx: integer; key: TMotionKey): boolean;
var
  t:FMatrix4x4;
  old_key:TMotionKey;
begin
  m_rotation(t, key.Q);
  m_translate_over(t, key.T);
  CorrectAlmostZeroOrOnesInRot(t);
  if _TryToUseAlreadyCalculatedKey(anim_name, bone_name, key_idx, t, old_key) then begin
    result:=_animations.SetAnimationKeyForBone(anim_name, bone_name, key_idx, old_key);
  end else begin
    result:=_animations.SetAnimationKeyForBone(anim_name, bone_name, key_idx, key);
  end;
end;

function TOgfSkeleton._AimChildBoneTo(bone_idx: TBoneID; global_target_pos: FVector3): boolean;
var
  bone, parent_bone:TOgfBoneData;
  parent_idx:TBoneID;
  parent_name:string;
  local_target_pos, local_current_pos, parent_pos:FVector3;
  mrot:FMatrix4x4;
begin
  // rotate PARENT bone in grandparent's space to make CHILD point to target


  result:=false;
  if not Loaded() then exit;
  bone:=_GetBone(bone_idx);
  if bone.bone = nil then exit;

  parent_name:=bone.bone.GetParentName();
  if length(parent_name)=0 then exit;

  parent_idx:=GetBoneIdxByName(parent_name);
  if parent_idx=INVALID_BONE_ID then exit;

  parent_bone:=_GetBone(parent_idx);
  if parent_bone.bone = nil then exit;


  // Set parent's rotation to zero
  parent_bone.joint._GetWrkTransform(mrot);
  m_get_translation(mrot, parent_pos);
  m_identity(mrot);
  m_translate_over(mrot, parent_pos);
  parent_bone.joint._AssignWrkTransform(mrot);

  // Get translation of child (when parent rotation is 0)
  bone.joint._GetWrkTransform(mrot);
  m_get_translation(mrot, local_current_pos);

  // Calculate target orientation in parent's space (as if parent currently won't add rotation)
  if not _ConvertGlobalCoordinatesIntoWrkBoneSpace(parent_idx, global_target_pos, local_target_pos) then exit;
  mrot:=rotation_between(local_current_pos, local_target_pos);
  mrot:=m_invert43(mrot);
  m_translate_over(mrot, parent_pos);

  parent_bone.joint._AssignWrkTransform(mrot);
  result:=true;
end;

function TOgfSkeleton._SolveIKAndSetKey(bone_idx: TBoneID;new_transform: FMatrix4x4; anim_name: string; key_idx: integer; iksolver: TOgfIKSolverBase): TOgfIkSolvingResult;
var
  pose:TOgfSkeletonPose;
begin
  if (iksolver<>nil) and not iksolver.IsTransformAllowedForBone(bone_idx) then begin
    result:=IKSolveFailed;
  end else if (iksolver=nil) or not iksolver.IsIkSolveNeededForBoneTransform(bone_idx) then begin
    result:=IKSolveNotNeeded;
  end else begin
    result:=IKSolveFailed;

    if not _SetKeyPoseForWork(anim_name, key_idx) then exit;
    result:= iksolver.SolveIK(bone_idx, new_transform);

    if result = IKSolveSuccess then begin
      pose:=TOgfSkeletonPose.Create();
      try
        if _GetWrkPose(pose) then begin;
          SetSkeletonPose(anim_name, key_idx, pose);
        end else begin
          result:=IKSolveFailed;
        end;
      finally
        FreeAndNil(pose);
      end;
    end;
  end;
end;

function TOgfSkeleton.GetBoneIdxByName(name: string): TBoneID;
var
  bone:TOgfBone;
  i:integer;
begin
  result:=INVALID_BONE_ID;
  if not Loaded() then exit;

  for i:=0 to GetBonesCount()-1 do begin
    bone:=_data.bones.Bone(i);
    if bone.GetName() = name then begin
      result:=i;
      break;
    end;
  end;
end;

function TOgfSkeleton.GetBoneName(idx: TBoneID): string;
begin
  result:='';
  if Loaded() and (idx<>INVALID_BONE_ID) and (idx<GetBonesCount()) then begin
    result:=_GetBone(idx).bone.GetName();
  end;
end;

function TOgfSkeleton.RenameBone(old_name: string; new_name: string): boolean;
var
  idx:TBoneID;
  bone:TOgfBone;
  i:integer;
begin
  result:=false;
  if not Loaded() then exit;
  // check if we already have bone with new name
  idx:=GetBoneIdxByName(new_name);
  if idx <> INVALID_BONE_ID then exit;

  idx:=GetBoneIdxByName(old_name);
  if idx = INVALID_BONE_ID then exit;

  bone:=_GetBone(idx).bone;
  if bone<>nil then begin
    bone._SetName(new_name);
    for i:=0 to GetBonesCount()-1 do begin
      bone:=_GetBone(i).bone;
      if bone<>nil then begin
        if bone.GetParentName() = old_name then begin
          bone._SetParentName(new_name);
        end;
      end;
    end;
    result:=true;

    if (_animations<>nil) and (_animations.Loaded()) and (_animations.AnimationsCount() > 0) then begin
      result:=_animations.RenameBone(old_name, new_name);
    end;
  end;
end;

function TOgfSkeleton.ReparentBone(idx: TBoneID; new_parent_idx: TBoneID; preserve_global_pos: boolean): boolean;
var
  bone:TOgfBoneData;
  m:FMatrix4x4;
  new_parent:TOgfBoneData;
  new_parent_name:string;

  i,j:integer;
  def:TOgfMotionDefData;

  m2:FMatrix4x4;
begin
  result:=false;
  if Loaded() and (idx<>INVALID_BONE_ID) and (idx<GetBonesCount()) then begin
    bone:=_GetBone(idx);
    if bone.bone = nil then exit;

    if (new_parent_idx = INVALID_BONE_ID) or (new_parent_idx = idx) then begin
      new_parent.bone:=nil;
      new_parent.joint:=nil;
      new_parent_name:='';
    end else begin
      new_parent:=_GetBone(new_parent_idx);
      if new_parent.bone = nil then exit;
      new_parent_name:=new_parent.bone.GetName();
    end;

    if (preserve_global_pos) and (length(bone.bone.GetParentName())<>0) then begin
      if (_animations<>nil) and (_animations.Loaded()) then begin
        for i:=0 to _animations.AnimationsCount()-1 do begin
          def:=_animations.GetAnimationParams(i);
          if length(def.name)=0 then continue;
          for j:=0 to _animations.GetAnimationFramesCount(def.name)-1 do begin
            _SetKeyPoseForWork(def.name, j);
            if not _GetWrkBoneSpaceToGlobalSpaceMatrix(idx, m) then continue;
            _animations.SetAnimationKeyForBone(def.name, bone.bone.GetName(), j, TransformToMotionKey(m));
          end;
        end;
      end;

      // Unparent the bone
      _SetBindPoseForWork();
      if not _GetWrkBoneSpaceToGlobalSpaceMatrix(idx, m) then exit;
      bone.joint.SetBindTransformData(m);
      bone.bone._SetParentName('');
    end;

    // Bone transform is in global space now
    if (preserve_global_pos) and (length(new_parent_name)<>0) then begin
      if (_animations<>nil) and (_animations.Loaded()) then begin
        for i:=0 to _animations.AnimationsCount()-1 do begin
          def:=_animations.GetAnimationParams(i);
          if length(def.name)=0 then continue;
          for j:=0 to _animations.GetAnimationFramesCount(def.name)-1 do begin
            _SetKeyPoseForWork(def.name, j);
            bone.joint._GetWrkTransform(m);

            new_parent.joint._GetWrkTransform(m2);
            if not _ConvertTransformFromGlobalIntoWrkBoneSpace(new_parent_idx, m, m) then continue;

            _animations.SetAnimationKeyForBone(def.name, bone.bone.GetName(), j, TransformToMotionKey(m));
          end;
        end;
      end;

      _SetBindPoseForWork();
      bone.joint._GetWrkTransform(m);
      if not _ConvertTransformFromGlobalIntoWrkBoneSpace(new_parent_idx, m, m) then exit;
      bone.joint.SetBindTransformData(m);
      bone.bone._SetParentName(new_parent_name);
    end;

    result:=true;
  end;
end;

function TOgfSkeleton.SetBoneShape(idx: TBoneID; shape: TOgfBoneShape): boolean;
var
  b:TOgfBoneData;
begin
  result:=false;
  if Loaded() and (idx<>INVALID_BONE_ID) and (idx<GetBonesCount()) then begin
    b:=_GetBone(idx);
    if b.joint<>nil then begin
      result:=b.joint.SetShape(shape);
    end;
  end;
end;

function TOgfSkeleton.SetBoneObb(idx: TBoneID; obb: FObb): boolean;
var
  b:TOgfBoneData;
begin
  result:=false;
  if Loaded() and (idx<>INVALID_BONE_ID) and (idx<GetBonesCount()) then begin
    b:=_GetBone(idx);
    if b.joint<>nil then begin
      result:=b.bone.SetOBB(obb);
    end;
  end;
end;

function TOgfSkeleton.SetBoneMassCenter(idx: TBoneID; c: FVector3): boolean;
var
  b:TOgfBoneData;
  co:fvector3;
  mo:single;
begin
  result:=false;
  if Loaded() and (idx<>INVALID_BONE_ID) and (idx<GetBonesCount()) then begin
    b:=_GetBone(idx);
    if b.joint<>nil then begin
      b.joint.GetMassParams(co, mo);
      b.joint.SetMassParams(c, mo);
      result:=true;
    end;
  end;
end;

function TOgfSkeleton.SetBoneMaterial(idx: TBoneID; material: string): boolean;
var
  b:TOgfBoneData;
begin
  result:=false;
  if Loaded() and (idx<>INVALID_BONE_ID) and (idx<GetBonesCount()) then begin
    b:=_GetBone(idx);
    if b.joint<>nil then begin
      b.joint.SetMaterial(material);
      result:=true;
    end;
  end;
end;

function TOgfSkeleton.CopyBoneParameters(idx: TBoneID): string;
var
  bone:TOgfBoneData;
  s1, s2:string;
begin
  result:='';
  if not Loaded() then exit;

  bone:=_GetBone(idx);
  if (bone.bone = nil) or (bone.joint=nil) then exit;

  s1:=bone.bone.Serialize();
  if length(s1)=0 then exit;

  s2:=bone.joint.Serialize();
  if length(s2)=0 then exit;

  result:=s1+s2;
end;

function TOgfSkeleton.ApplyBoneParameters(idx: TBoneID; s: string): boolean;
var
  name, parent:string;
  bone:TOgfBoneData;
  i:integer;
begin
  result:=false;
  if not Loaded() then exit;

  bone:=_GetBone(idx);
  if (bone.bone = nil) or (bone.joint=nil) then exit;

  name:=bone.bone.GetName();
  parent:=bone.bone.GetParentName();

  i:=bone.bone.Deserialize(s);
  bone.bone._SetName(name);
  bone.bone._SetParentName(parent);

  if i <= 0 then exit;
  if not AdvanceString(s, i) then exit;

  i:=bone.joint.Deserialize(s);
  if i <= 0 then exit;

  result:=true;
end;


function TOgfSkeleton.GetBoneParentName(idx: TBoneID): string;
begin
  result:='';
  if Loaded() and (idx<>INVALID_BONE_ID) and (idx<GetBonesCount()) then begin
    result:=_GetBone(idx).bone.GetParentName();
  end;
end;

function TOgfSkeleton.IsBoneHasSuchParentOrGrandParent(idx: TBoneID; idx_to_check_if_parent: TBoneID): boolean;
var
  current_parent_idx:TBoneID;
begin
  result:=false;

  current_parent_idx:=GetBoneParentIdx(idx);
  if current_parent_idx <> INVALID_BONE_ID then begin
    if current_parent_idx = idx_to_check_if_parent then begin
      result:=true;
    end else begin
      result:=IsBoneHasSuchParentOrGrandParent(current_parent_idx, idx_to_check_if_parent);
    end
  end;
end;

function TOgfSkeleton.GetBoneParentIdx(idx: TBoneID): TBoneId;
var
  parent_name:string;
begin
  result:=INVALID_BONE_ID;
  parent_name:=GetBoneParentName(idx);
  if length(parent_name) = 0 then exit;
  result:=GetBoneIdxByName(parent_name);
end;

function TOgfSkeleton.GetBoneMaterial(idx: TBoneID): string;
begin
  result:='';
  if Loaded() and (idx<>INVALID_BONE_ID) and (idx<GetBonesCount()) then begin
    result:=_GetBone(idx).joint.GetMaterial();
  end;
end;

function TOgfSkeleton.GetGlobalBonePositionInPose(bone_idx: TBoneId; anim_name: string; key_idx: integer; var position: FVector3): boolean;
var
  m:FMatrix4x4;
begin
  result:=false;
  if not GetBoneSpaceToGlobalSpaceMatrixInPose(bone_idx, anim_name, key_idx, m) then exit;

  position.x:=m.c.x;
  position.y:=m.c.y;
  position.z:=m.c.z;
  result:=true;
end;

function TOgfSkeleton.GetGlobalSpaceToBoneSpaceMatrixInPose(bone_idx: TBoneId; anim_name: string; key_idx: integer; var m: FMatrix4x4): boolean;
begin
  result:=false;
  if not Loaded() then exit;

  if key_idx=-1 then begin
    if not _SetBindPoseForWork() then exit;
  end else begin
    if not _SetKeyPoseForWork(anim_name, key_idx) then exit;
  end;

  result:=_GetGlobalSpaceToWrkBoneSpaceMatrix(bone_idx, m);
end;

function TOgfSkeleton.GetBoneSpaceToGlobalSpaceMatrixInPose(bone_idx: TBoneId; anim_name: string; key_idx: integer; var m: FMatrix4x4): boolean;
begin
  result:=false;
  if not Loaded() then exit;

  if key_idx=-1 then begin
    if not _SetBindPoseForWork() then exit;
  end else begin
    if not _SetKeyPoseForWork(anim_name, key_idx) then exit;
  end;

  result:=_GetWrkBoneSpaceToGlobalSpaceMatrix(bone_idx, m);
end;

function TOgfSkeleton.GetSkeletonPose(anim_name: string; key_idx: integer; pose: TOgfSkeletonPose): boolean;
begin
  result:=false;
  if key_idx = -1 then begin
    if not _SetBindPoseForWork() then exit;
  end else begin
    if not _SetKeyPoseForWork(anim_name, key_idx) then exit;
  end;

  result:=_GetWrkPose(pose);
end;

function TOgfSkeleton.SetSkeletonPose(anim_name: string; key_idx: integer; pose: TOgfSkeletonPose): integer;
var
  i:integer;
  anim_id:integer;
  bone:TOgfBoneData;
  bone_name:string;
  k:TMotionKey;
begin
  result:=0;
  if (_animations = nil) or not _animations.Loaded() then exit;

  anim_id:=_animations.GetAnimationIdByName(anim_name);
  if anim_id < 0 then exit;

  if not _SetKeyPoseForWork(anim_name, key_idx) then exit;
  result:=_SetWrkPose(pose);

  for i:=0 to GetBonesCount()-1 do begin
    bone:=_GetBone(i);
    if bone.joint = nil then continue;
    bone_name:=bone.bone.GetName();

    bone.joint._GetWrkKey(k);
    _SetKeyForAnimBone(anim_name, bone_name, key_idx, k);
  end;
end;

function TOgfSkeleton.GetSkeletonPosesSequence(anim_name: string; first_key_idx: integer; last_key_idx: integer; poses: TOgfSkeletonPoseSeq): boolean;
var
  pose:TOgfSkeletonPose;
  i:integer;
begin
  result:=false;
  poses.Reset();

  if _animations.GetAnimationIdByName(anim_name)<0 then exit;
  if (first_key_idx < 0) or (first_key_idx >= _animations.GetAnimationFramesCount(anim_name)) then exit;
  if (last_key_idx < 0) or (last_key_idx >= _animations.GetAnimationFramesCount(anim_name)) then exit;

  if last_key_idx < first_key_idx then begin
    i:=last_key_idx;
    last_key_idx:=first_key_idx;
    first_key_idx:=i;
  end;

  result:=true;
  for i:=first_key_idx to last_key_idx  do begin
    pose:=TOgfSkeletonPose.Create();
    if GetSkeletonPose(anim_name, i, pose) then begin
      poses.Add(pose);
    end else begin
      FreeAndNil(pose);
      result:=false;
      break;
    end;
  end;
end;

function TOgfSkeleton.PasteSkeletonPosesSequence(anim_name: string; first_key_idx: integer; insert_mode: boolean; poses: TOgfSkeletonPoseSeq): boolean;
var
  i, oldlen, newlen, poseslen:integer;
  pose:TOgfSkeletonPose;
begin
  result:=false;
  if _animations.GetAnimationIdByName(anim_name)<0 then exit;

  oldlen:=_animations.GetAnimationFramesCount(anim_name);
  if (first_key_idx < 0) or (first_key_idx >= oldlen) then exit;

  poseslen:=poses.Count();
  if insert_mode then begin
    newlen:=oldlen+poseslen;
    _animations.ChangeAnimationFramesCount(anim_name, newlen);

    pose:=TOgfSkeletonPose.Create();
    try
      for i:=oldlen-1 downto first_key_idx do begin
        if not GetSkeletonPose(anim_name, i, pose) then exit;
        if SetSkeletonPose(anim_name, i+poseslen, pose)<>pose.BonesCount() then exit;
      end;
    finally
      FreeAndNil(pose);
    end;
  end else if first_key_idx + poseslen >= oldlen then begin
    _animations.ChangeAnimationFramesCount(anim_name, first_key_idx + poseslen);
  end;

  for i:=0 to poseslen-1 do begin
    pose:=poses.Get(i);
    SetSkeletonPose(anim_name, first_key_idx+i, pose);
  end;

  result:=true;
end;


function TOgfSkeleton.GetBoneBindTransformInParentSpace(idx: TBoneID; var offset: FVector3; var rotate: FVector3): boolean;
begin
  result:=false;
  if Loaded() and (idx<>INVALID_BONE_ID) and (idx<GetBonesCount()) then begin
    _GetBone(idx).joint.GetBindTransformData(offset, rotate);
    result:=true;
  end;
end;

function TOgfSkeleton.MoveBone(idx: TBoneID; v: FVector3; anim_name: string; key_idx: integer; is_absolute: boolean; fixed_children: boolean;  iksolver: TOgfIKSolverBase): boolean;
var
  b, child_bone:TOgfBoneData;
  original_matrix, temp_matrix, new_matrix, child_matrix, global_matrix:FMatrix4x4;
  position:FVector3;

  i:integer;

  ikres:TOgfIkSolvingResult;
begin
  result:=false;
  if Loaded() and (idx<>INVALID_BONE_ID) and (idx<GetBonesCount()) then begin
      b:=_GetBone(idx);
      if b.joint=nil then exit;


      if key_idx = -1 then begin
        if not _SetBindPoseForWork() then exit;
      end else begin
        if not _SetKeyPoseForWork(anim_name, key_idx) then exit;
      end;

      b.joint._GetWrkTransform(original_matrix);
      if not _GetWrkBoneSpaceToGlobalSpaceMatrix(idx, temp_matrix) then exit;
      m_get_translation(temp_matrix, position);

      // Get target position in global space
      if is_absolute then begin;
        m_translate_over(temp_matrix, v);
      end else begin
        position:=v_add(position, v);
        m_translate_over(temp_matrix, position);
      end;

      if (length(b.bone.GetParentName())> 0) then begin
        if not _ConvertTransformFromGlobalIntoParentSpaceOfWrkBone(idx, temp_matrix, new_matrix) then exit;
      end else begin
        new_matrix:=temp_matrix;
      end;


      if fixed_children then begin
        for i:=0 to GetBonesCount()-1 do begin
          if i = idx then continue;
          child_bone:=_GetBone(i);
          if (child_bone.bone<>nil) and (child_bone.bone.GetParentName() = b.bone.GetName()) then begin
            b.joint._AssignWrkTransform(original_matrix);
            if not _GetWrkBoneSpaceToGlobalSpaceMatrix(i, child_matrix) then continue;
            b.joint._AssignWrkTransform(new_matrix);
            if not _ConvertTransformFromGlobalIntoWrkBoneSpace(idx, child_matrix, child_matrix) then exit;
            if key_idx = -1 then begin
              child_bone.joint.SetBindTransformData(child_matrix);
            end else begin
              _SetTransformKeyForAnimBone(anim_name, child_bone.bone.GetName(), key_idx, child_matrix);
            end;
          end;
        end;
      end;

      result:=true;

      if key_idx = -1 then begin
        b.joint.SetBindTransformData(new_matrix);
        // TODO: correct OBB, center of mass and shape?

      end else begin
        if not _ConvertTransformFromParentSpaceOfWrkBoneIntoGlobal(idx, new_matrix, global_matrix) then exit;
        ikres:=_SolveIKAndSetKey(idx, global_matrix, anim_name, key_idx, iksolver);
        if ikres = IKSolveNotNeeded then begin
          result:=_SetTransformKeyForAnimBone(anim_name, b.bone.GetName(), key_idx, new_matrix);
        end else if ikres = IKSolveFailed then begin
          result:=false;
        end;
      end;
  end;
end;

function TOgfSkeleton.RotateBone(idx: TBoneID; v: FVector3; anim_name: string; key_idx: integer; mode: TOgfBoneRotationMode; iksolver: TOgfIKSolverBase): boolean;
var
  b:TOgfBoneData;

  rot_matrix:FMatrix4x4;
  original_matrix, new_matrix, global_matrix, toglo,toloc:FMatrix4x4;
  pos,vz:FVector3;

  ikres:TOgfIkSolvingResult;
begin
  result:=false;
  if Loaded() and (idx<>INVALID_BONE_ID) and (idx<GetBonesCount()) then begin
      b:=_GetBone(idx);
      if b.joint=nil then exit;

      if key_idx = -1 then begin
        if not _SetBindPoseForWork() then exit;
      end else begin
        if not _SetKeyPoseForWork(anim_name, key_idx) then exit;
      end;

      m_setXYZ(rot_matrix, v);

      if mode = BoneRotationLocal then begin
        b.joint._GetWrkTransform(original_matrix);
        new_matrix:=m_mul(original_matrix, rot_matrix);
      end else begin
        // After unparenting, bone with idx will have toglo transform
        if not _GetWrkBoneSpaceToGlobalSpaceMatrix(idx, toglo) then exit;

        // Save bone translation
        m_get_translation(toglo, pos);

        // Move bone position to world's pivot point
        set_zero(vz);
        m_translate_over(toglo, vz);

        // Rotate bone in global coordinates
        new_matrix:=m_mul(rot_matrix, toglo);

        // Restore translation
        m_translate_over(new_matrix, pos);

        // Get transform which the bone will have after parenting
        if not _ConvertTransformFromGlobalIntoParentSpaceOfWrkBone(idx, new_matrix, new_matrix) then exit;
      end;

      result:=true;

      if key_idx = -1 then begin
        b.joint.SetBindTransformData(new_matrix);
      end else begin
        if not _ConvertTransformFromParentSpaceOfWrkBoneIntoGlobal(idx, new_matrix, global_matrix) then exit;
        ikres:=_SolveIKAndSetKey(idx, global_matrix, anim_name, key_idx, iksolver);
        if ikres = IKSolveNotNeeded then begin
          result:=_SetTransformKeyForAnimBone(anim_name, b.bone.GetName(), key_idx, new_matrix);
        end else if ikres = IKSolveFailed then begin
          result:=false;
        end;
      end;
  end;
end;

function TOgfSkeleton.FollowBone(bone_idx: TBoneID; anim_name: string; source_bone_idx: TBoneID; source_key_idx: integer; target_key_idx: integer; iksolver: TOgfIKSolverBase): boolean;
var
  old_parent_name :string;
  old_parent_idx:TBoneID;
  bone, source_bone:TOgfBoneData;
  m_global:FMatrix4x4;
  m:FMatrix4x4;
  iksolveresult:TOgfIkSolvingResult;
begin
  if source_key_idx = target_key_idx then begin
    result:=true;
    exit;
  end;

  result:=false;

  bone:=_GetBone(bone_idx);
  if bone.bone = nil then exit;
  source_bone:=_GetBone(source_bone_idx);
  if source_bone.bone = nil then exit;
  if IsBoneHasSuchParentOrGrandParent(bone_idx, source_bone_idx) then exit;

  old_parent_idx:=INVALID_BONE_ID;
  old_parent_name:=bone.bone.GetParentName();
  if length(old_parent_name) > 0 then begin
    old_parent_idx:=GetBoneIdxByName(old_parent_name);
  end;

  // temporarily reparent to source bone in source key, remember bone transform
  if not _SetKeyPoseForWork(anim_name, source_key_idx) then exit;
  if not _GetWrkBoneSpaceToGlobalSpaceMatrix(bone_idx, m_global) then exit;
  if not _ConvertTransformFromGlobalIntoWrkBoneSpace(source_bone_idx, m_global, m) then exit;
  bone.bone._SetParentName(source_bone.bone.GetName());

  try
    //go to target key pose, apply the same transform to the bone
    if not _SetKeyPoseForWork(anim_name, target_key_idx) then exit;
    bone.joint._AssignWrkTransform(m);

    //calculate new matrix of the bone when it's parented to the source and reparent the bone back using new transform
    if not _GetWrkBoneSpaceToGlobalSpaceMatrix(bone_idx, m_global) then exit;

    if old_parent_idx<>INVALID_BONE_ID then begin
      if not _ConvertTransformFromGlobalIntoWrkBoneSpace(old_parent_idx, m_global, m) then exit;
    end;

    bone.bone._SetParentName(old_parent_name);
    iksolveresult:=_SolveIKAndSetKey(bone_idx, m_global, anim_name, target_key_idx, iksolver);
    if iksolveresult = IKSolveNotNeeded then begin
      if not _SetTransformKeyForAnimBone(anim_name, bone.bone.GetName(), target_key_idx, m) then exit;
      result:=true;
    end else if iksolveresult = IKSolveSuccess then begin
      result:=true;
    end;

  finally
    bone.bone._SetParentName(old_parent_name);
  end;
end;

function TOgfSkeleton.AimBone(bone_idx: TBoneID; target: FVector3; anim_name: string; key_idx: integer; iksolver: TOgfIKSolverBase): boolean;
var
  bone:TOgfBoneData;
  parent_name:string;
  parent_id:TBoneID;
  m, global_matrix:FMatrix4x4;

  ikres:TOgfIkSolvingResult;
begin
  result:=false;
  bone:=_GetBone(bone_idx);
  if bone.bone = nil then exit;
  parent_name:=bone.bone.GetParentName();
  if length(parent_name) = 0 then exit;
  parent_id:=GetBoneIdxByName(parent_name);
  if parent_id = INVALID_BONE_ID then exit;

  if not _SetKeyPoseForWork(anim_name, key_idx) then exit;
  if not _AimChildBoneTo(bone_idx, target) then exit;
  if not _GetWrkBoneLocalTransform(parent_id, m) then exit;

  result:=true;
  if not _ConvertTransformFromParentSpaceOfWrkBoneIntoGlobal(parent_id, m, global_matrix) then exit;
  ikres:=_SolveIKAndSetKey(parent_id, global_matrix, anim_name, key_idx, iksolver);
  if ikres = IKSolveNotNeeded then begin
    _SetTransformKeyForAnimBone(anim_name, parent_name, key_idx, m);
  end else if ikres = IKSolveFailed then begin
    result:=false;
  end;
end;

function TOgfSkeleton.SetBoneOrientation(bone_idx: TBoneID; orientation: FVector3; anim_name: string; key_idx: integer; iksolver: TOgfIKSolverBase): boolean;
var
  bone:TOgfBoneData;
  m, m_old, global_matrix:FMatrix4x4;
  pos:FVector3;

  ikres:TOgfIkSolvingResult;
begin
  result:=false;
  bone:=_GetBone(bone_idx);
  if bone.bone = nil then exit;

  if not _SetKeyPoseForWork(anim_name, key_idx) then exit;
  if not _GetWrkBoneLocalTransform(bone_idx, m_old) then exit;

  m_setXYZ(m, orientation);
  m_get_translation(m_old, pos);
  m_translate_over(m, pos);

  result:=true;
  if not _ConvertTransformFromParentSpaceOfWrkBoneIntoGlobal(bone_idx, m, global_matrix) then exit;
  ikres:=_SolveIKAndSetKey(bone_idx, global_matrix, anim_name, key_idx, iksolver);
  if ikres = IKSolveNotNeeded then begin
    _SetTransformKeyForAnimBone(anim_name, bone.bone.GetName(), key_idx, m);
  end else if ikres = IKSolveFailed then begin
    result:=false;
  end;
end;

function TOgfSkeleton.SetBonePosition(bone_idx: TBoneID; position: FVector3;anim_name: string; key_idx: integer; is_global: boolean;iksolver: TOgfIKSolverBase): boolean;
var
  bone:TOgfBoneData;
  m, m_old, global_matrix:FMatrix4x4;
  pos:FVector3;

  ikres:TOgfIkSolvingResult;
begin
  result:=false;
  bone:=_GetBone(bone_idx);
  if bone.bone = nil then exit;

  if not _SetKeyPoseForWork(anim_name, key_idx) then exit;

  if is_global then begin
    if not _ConvertGlobalCoordinatesIntoParentSpaceOfWrkBone(bone_idx, position, pos) then exit;
    if not _GetWrkBoneLocalTransform(bone_idx, m) then exit;
    m_translate_over(m, pos);
  end else begin
    if not _GetWrkBoneLocalTransform(bone_idx, m) then exit;
    m_translate_over(m, position);
  end;

  result:=true;
  if not _ConvertTransformFromParentSpaceOfWrkBoneIntoGlobal(bone_idx, m, global_matrix) then exit;
  ikres:=_SolveIKAndSetKey(bone_idx, global_matrix, anim_name, key_idx, iksolver);
  if ikres = IKSolveNotNeeded then begin
    _SetTransformKeyForAnimBone(anim_name, bone.bone.GetName(), key_idx, m);
  end else if ikres = IKSolveFailed then begin
    result:=false;
  end;
end;

function TOgfSkeleton.InterpolateBone(bone_idx: TBoneID; anim_name: string; first_key_idx: integer; last_key_idx: integer; calc_pos: boolean; calc_rot: boolean; factor: single; iksolver: TOgfIKSolverBase): integer;
var
  bone:TOgfBoneData;
  m1, m2, m:FMatrix4x4;
  pos1, pos2, pos, dt, dtc:FVector3;
  i, cstep:integer;
  tm:single;

  first_key,last_key,k:TMotionKey;
begin
  result:=0;
  bone:=_GetBone(bone_idx);
  if bone.bone = nil then exit;

  if (iksolver <> nil) and not (iksolver.IsProperlyConfigured and iksolver.IsTransformAllowedForBone(bone_idx)) then begin
    exit;
  end;

  if (iksolver = nil) or (not iksolver.IsIkSolveNeededForBoneTransform(bone_idx)) then begin
    if _animations.InterpotateAnimationKeysForBone(anim_name, bone.bone.GetName(), first_key_idx, last_key_idx, factor, calc_pos, calc_rot) then begin
      result:=abs(last_key_idx - first_key_idx);
    end;
  end else begin
    if first_key_idx <= last_key_idx then begin
      cstep:=1;
    end else begin
      cstep:=-1;
    end;

    if iksolver.IsHandlerBone(bone_idx) then begin
      // Interpolate rotation with usual metod
      if _animations.InterpotateAnimationKeysForBone(anim_name, bone.bone.GetName(), first_key_idx, last_key_idx, factor, calc_pos, calc_rot) then begin

      // now we need to interpolate global position
      if not _SetKeyPoseForWork(anim_name, first_key_idx) then exit;
      if not _GetWrkBoneSpaceToGlobalSpaceMatrix(bone_idx, m1) then exit;
      m_get_translation(m1, pos1);

      if not _SetKeyPoseForWork(anim_name, last_key_idx) then exit;
      if not _GetWrkBoneSpaceToGlobalSpaceMatrix(bone_idx, m2) then exit;
      m_get_translation(m2, pos2);

      if not IsPosSame(pos2, pos1) and (abs(last_key_idx - first_key_idx) > 1) then begin
          dt:=v_sub(pos2, pos1);
          i:=first_key_idx+cstep;
          while i <> last_key_idx do begin
              tm:= (i-first_key_idx)/(last_key_idx-first_key_idx);
              tm:=power(tm, factor);

              dtc:=v_mul(dt, tm);
              pos:=v_add(pos1, dtc);
              if not _SetKeyPoseForWork(anim_name, i) then exit;
              if not _GetWrkBoneSpaceToGlobalSpaceMatrix(bone_idx, m) then exit;
              m_translate_over(m, pos);
              if _SolveIKAndSetKey(bone_idx, m, anim_name, i, iksolver)<>IKSolveFailed then begin
                result:=result+1;
              end;

              i:=i+cstep;
            end;
          end;
      end;
    end else begin
      // need interpolate local position
      if not _animations.GetAnimationKeyForBone(anim_name, bone.bone.GetName(), first_key_idx,first_key) then exit;
      if not _animations.GetAnimationKeyForBone(anim_name, bone.bone.GetName(), last_key_idx,last_key) then exit;


      calc_rot:=calc_rot and not IsRotSame(first_key.Q, last_key.Q);
      calc_pos:=calc_pos and not IsPosSame(first_key.T, last_key.T);
      if (calc_rot or calc_pos) and (abs(last_key_idx - first_key_idx) > 1) then begin
        i:=first_key_idx+cstep;
        while i <> last_key_idx do begin
          tm:= (i-first_key_idx)/(last_key_idx-first_key_idx);
          tm:=power(tm, factor);

          TOgfMotionBoneTrack.KeysSlerp(k, first_key, last_key, tm, calc_pos, calc_rot);
          if _SetKeyPoseForWork(anim_name, i) then begin
            bone.joint._AssignWrkKey(k);
            if _GetWrkBoneSpaceToGlobalSpaceMatrix(bone_idx, m) then begin
              if _SolveIKAndSetKey(bone_idx, m, anim_name, i, iksolver)<>IKSolveFailed then begin
                result:=result+1;
              end;
            end;
          end;

          i:=i+cstep;
        end;
      end;
    end;
  end;
end;

function TOgfSkeleton.ApplyDiff(bone_idx: TBoneID; anim_name: string; targetframe: integer; sourceframe: integer; startframe: integer; endframe: integer; correct_position: boolean; correct_rotation: boolean; iksolver: TOgfIKSolverBase): boolean;
var
  transform_target, transform_source, transform_diff, m, global_matrix:FMatrix4x4;
  pos_target, pos_source, pos_diff, pos:FVector3;

  i:integer;
  bone:TOgfBoneData;
  ikres:TOgfIkSolvingResult;
begin
  result:=false;

  bone:=_GetBone(bone_idx);
  if bone.joint = nil then exit;

  if startframe > endframe then begin
    i:=startframe;
    startframe:=endframe;
    endframe:=i;
  end;

  if not _SetKeyPoseForWork(anim_name, targetframe) then exit;
  bone.joint._GetWrkTransform(transform_target);
  if not _SetKeyPoseForWork(anim_name, sourceframe) then exit;
  bone.joint._GetWrkTransform(transform_source);

  m_get_translation(transform_target, pos_target);
  m_get_translation(transform_source, pos_source);
  pos_diff:=v_sub(pos_target, pos_source);

  m:=m_invert43(transform_source);
  transform_diff:=m_mul(m, transform_target);

  for i:=startframe to endframe do begin
    if not _SetKeyPoseForWork(anim_name, i) then exit;
    bone.joint._GetWrkTransform(m);
    m_get_translation(m, pos);

    if correct_rotation then begin
      m:=m_mul(m, transform_diff);
    end;

    if correct_position then begin
      pos:=v_add(pos, pos_diff);
    end;
    m_translate_over(m, pos);

    if not _ConvertTransformFromParentSpaceOfWrkBoneIntoGlobal(bone_idx, m, global_matrix) then exit;
    ikres:=_SolveIKAndSetKey(bone_idx, global_matrix, anim_name, i, iksolver);
    if ikres = IKSolveNotNeeded then begin
      _SetTransformKeyForAnimBone(anim_name, bone.bone.GetName(), i, m);
    end else if ikres = IKSolveFailed then begin
      break;
    end;

    if i = endframe then begin
      result:=true;
    end;
  end;
end;

function TOgfSkeleton.SyncAnimsBones(sync_flags: TOgfAnimationBonesSyncFlags): boolean;
var
  i:integer;
  bonedata:TOgfBoneData;
  key:TMotionKey;
  transform:FMatrix4x4;
  bonename:string;
begin
  result:=false;
  if not Loaded() then exit;
  if not _animations.Loaded() then exit;

  if sync_flags and OGF_ANIMATION_SYNC_ADD_TO_ANIM <> 0 then begin;
    // Add missed skeleton bones to animations
    for i:=0 to GetBonesCount()-1 do begin
      bonedata:=_GetBone(i);
      if bonedata.bone<>nil then begin
        bonename:=bonedata.bone.GetName();
        if not _animations.IsBonePresent(bonename) then begin
          bonedata.joint.GetBindTransformData(transform);
          CorrectAlmostZeroOrOnesInRot(transform);
          key:=TransformToMotionKey(transform);
          _animations.AddBone(bonename, key);
        end;
      end;
    end;
  end;

  if sync_flags and OGF_ANIMATION_SYNC_REMOVE_FROM_SKELETON <> 0 then begin;
    // Remove extra bones from the skeleton
    for i:=_animations.RegisteredBonesCount()-1 downto 0 do begin
      bonename:=_animations.GetRegisteredBonename(i);
      if length(bonename)>0 then begin
        if GetBoneIdxByName(bonename) = INVALID_BONE_ID then begin
          _animations.RemoveBone(bonename);
        end;
      end;
    end;
  end;

  result:=true;
end;

function TOgfSkeleton.AddBone(name: string; parent_id: TBoneId; pos: FVector3; dir: FVector3; is_in_global_space: boolean; force_bind_pose:boolean): TBoneId;
var
  parent_bone:TOgfBoneData;
  joint:TOgfJointData;
  bone:TOgfBone;
  m:FMatrix4x4;
  parent_name:string;
  i,j:integer;
  newidx:integer;
  key:TMotionKey;
begin
  result:=INVALID_BONE_ID;
  if GetBoneIdxByName(name) <> INVALID_BONE_ID then exit;

  parent_name:='';
  parent_bone.bone:=nil;
  parent_bone.joint:=nil;
  if parent_id <> INVALID_BONE_ID then begin
    parent_bone:=_GetBone(parent_id);
    if parent_bone.bone = nil then exit;
    parent_name:=parent_bone.bone.GetName();
  end;

  if force_bind_pose then begin
    _SetBindPoseForWork();
  end;

  if (is_in_global_space) and (parent_bone.bone<>nil) then begin
    m_setXYZ(m, dir);
    m_translate_over(m, pos);
    if not _ConvertTransformFromGlobalIntoWrkBoneSpace(parent_id, m, m) then exit;

    m_getXYZi(m, dir);
    m_get_translation(m, pos);
  end;

  joint:=TOgfJointData.Create();
  joint._InitDefault(pos, dir);

  bone:=TOgfBone.Create();
  bone._InitDefault(name, parent_name);

  i:=_data.bones._RegisterBone(bone);
  j:=_data.joints._RegisterJoint(joint);

  if (i=j) and (i<>INVALID_BONE_ID) then begin
    newidx:=i;
  end else begin
    exit;
  end;

  if (_animations<>nil) and (_animations.Loaded()) then begin
    m_setXYZ(m, dir);
    m_translate_over(m, pos);
    key:=TransformToMotionKey(m);
    if not _animations.AddBone(name, key) then exit;
  end;

  result:=newidx;
end;


function TOgfSkeleton.GetBoneMassParams(idx: TBoneID; var center: FVector3; var mass: single): boolean;
begin
  result:=false;
  if Loaded() and (idx<>INVALID_BONE_ID) and (idx<GetBonesCount()) then begin
    _GetBone(idx).joint.GetMassParams(center, mass);
    result:=true;
  end;
end;

function TOgfSkeleton.GetBoneShape(idx: TBoneID; var shape: TOgfBoneShape): boolean;
begin
  result:=false;
  if Loaded() and (idx<>INVALID_BONE_ID) and (idx<GetBonesCount()) then begin
    shape:=_GetBone(idx).joint.GetShape();
    result:=true;
  end;
end;

function TOgfSkeleton.GetBoneBoundingBox(idx: TBoneID; var obb: FObb): boolean;
begin
  result:=false;
  if Loaded() and (idx<>INVALID_BONE_ID) and (idx<GetBonesCount()) then begin
    obb:=_GetBone(idx).bone.GetOBB();
    result:=true;
  end;
end;

function TOgfSkeleton.GetBoneUnitedData(idx: TBoneID; var data: TBoneUnitedData): boolean;
var
  b:TOgfBoneData;
begin
  result:=false;
  if Loaded() and (idx<>INVALID_BONE_ID) and (idx<GetBonesCount()) then begin
    b:=_GetBone(idx);

    data.id:=idx;
    data.name:=b.bone.GetName();
    data.parent_name:=b.bone.GetParentName();

    data.parent_id:=INVALID_BONE_ID;
    if length(data.parent_name) > 0 then begin
      data.parent_id:=GetBoneIdxByName(data.parent_name);
    end;

    data.material:=b.joint.GetMaterial();
    data.obb:=b.bone.GetOBB();
    data.shape:=b.joint.GetShape();
    b.joint.GetMassParams(data.center_of_mass, data.mass);
    b.joint.GetBindTransformData(data.offset, data.orientation);

    if b.joint.IKData()<>nil then begin
      data.ikdata:=b.joint.IKData().GetData();
    end else begin
      data.ikdata.jointtype:=OGF_JOINT_TYPE_INVALID;
    end;

    result:=true;
  end;
end;

procedure TOgfSkeleton.IterateBones(cb: TBonesIterationCallback; userdata: pointer);
var
  i:integer;
  data:TBoneUnitedData;
begin
  if not Loaded() then exit;
  for i:=0 to GetBonesCount()-1 do begin
    if GetBoneUnitedData(i, data) then begin
      if not cb(i, @data, userdata) then exit;
    end;
  end;
end;

function TOgfSkeleton.ForceSetBoneBindPoseTransform(bone_idx: TBoneId; offset: FVector3; rotate: FVector3): boolean;
var
  b:TOgfBoneData;
begin
  result:=false;
  if not Loaded() then exit;
  b:=_GetBone(bone_idx);
  if b.joint<>nil then begin
    b.joint.SetBindTransformData(offset, rotate);
    result:=true;
  end;
end;

function TOgfSkeleton.UniformScale(k: single): boolean;
begin
  result:=false;
  if not Loaded() then exit;
  result:= _data.bones.UniformScale(k) and _data.joints.UniformScale(k);
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
  if not DeserializeTermString(rawdata, _lodref) then _lodref:=rawdata;
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

{ TOgfJointsDataContainer }

function TOgfJointsDataContainer._RegisterJoint(joint: TOgfJointData): TBoneId;
var
  i:integer;
begin
  _loaded:=true;
  i:=length(_data);
  setlength(_data, i+1);
  _data[i]:=joint;

  result:=i;
end;

constructor TOgfJointsDataContainer.Create;
begin
  _loaded:=false;
  setlength(_data, 0);
  Reset();
end;

destructor TOgfJointsDataContainer.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TOgfJointsDataContainer.Reset;
var
  i:integer;
begin
  for i:=0 to length(_data)-1 do begin
    _data[i].Free;
  end;
  setlength(_data, 0);
  _loaded:=false;
end;

function TOgfJointsDataContainer.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfJointsDataContainer.Deserialize(rawdata: string): boolean;
var
  i, cnt:integer;
begin
  result:=false;
  Reset();

  repeat
    i:=length(_data);
    setlength(_data, i+1);
    _data[i]:=TOgfJointData.Create();
    cnt:=_data[i].Deserialize(rawdata);
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

function TOgfJointsDataContainer.Serialize(): string;
var
  i:integer;
begin
  result:='';
  if not Loaded() then exit;

  for i:=0 to length(_data)-1 do begin
    result:=result+_data[i].Serialize();
  end;
end;

function TOgfJointsDataContainer.Count(): integer;
begin
  if Loaded() then begin
    result:=length(_data);
  end else begin
    result:=0;
  end;
end;

function TOgfJointsDataContainer.Get(i: integer): TOgfJointData;
begin
  result:=nil;
  if not Loaded() or (i<0) or (i >= length(_data)) then exit;
  result:=_data[i];
end;

function TOgfJointsDataContainer.UniformScale(k: single): boolean;
var
  i:integer;
begin
  result:=Loaded();
  if not result then exit;

  for i:=0 to length(_data)-1 do begin
    result:=result and _data[i].UniformScale(k);
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
  _data.jointtype:=OGF_JOINT_TYPE_INVALID;
  _data.ik_flags:=0;

  _data.spring_factor:=0;
  _data.damping_factor:=0;
  _data.break_force:=0;
  _data.break_torque:=0;
  _data.friction:=0;

  for i:=0 to length(_data.limits)-1 do begin
    _data.limits[i].damping_factor:=0;
    _data.limits[i].spring_factor:=0;
    set_zero(_data.limits[i].limit);
  end;
end;

function TOgfJointIKData.Loaded(): boolean;
begin
  result:=(_data.jointtype<>OGF_JOINT_TYPE_INVALID);
end;

function TOgfJointIKData.Deserialize(rawdata: string; version: cardinal): integer;
var
  sz:integer;
  i,j:integer;
  ptr:PAnsiChar;
begin
  result:=-1;
  Reset();

  sz:=sizeof(_data.jointtype) +sizeof(_data.limits)+sizeof(_data.spring_factor)+sizeof(_data.damping_factor)+sizeof(_data.ik_flags)+sizeof(_data.break_force)+sizeof(_data.break_torque);
  if version > OGF_JOINT_IK_VERSION_0 then begin
    sz:=sz+sizeof(_data.friction);
  end;
  if length(rawdata)<sz then exit;

  ptr:=PAnsiChar(@rawdata[1]);
  i:=0;

  _data.jointtype:=pcardinal(@ptr[i])^;
  i:=i+sizeof(_data.jointtype);

  for j:=0 to length(_data.limits)-1 do begin
    _data.limits[j]:=pTOgfJointLimit(@ptr[i])^;
    i:=i+sizeof(_data.limits[j]);
  end;

  _data.spring_factor:=psingle(@ptr[i])^;
  i:=i+sizeof(_data.spring_factor);

  _data.damping_factor:=psingle(@ptr[i])^;
  i:=i+sizeof(_data.damping_factor);

  _data.ik_flags:=pcardinal(@ptr[i])^;
  i:=i+sizeof(_data.ik_flags);

  _data.break_force:=psingle(@ptr[i])^;
  i:=i+sizeof(_data.break_force);

  _data.break_torque:=psingle(@ptr[i])^;
  i:=i+sizeof(_data.break_torque);

  if version > OGF_JOINT_IK_VERSION_0 then begin
    _data.friction:=psingle(@ptr[i])^;
    i:=i+sizeof(_data.friction);
  end else begin
    _data.friction:=1;
  end;

  assert(sz = i);
  result:=sz;
end;

function TOgfJointIKData.Serialize(): string;
var
  i:integer;
begin
  result:='';
  if not Loaded() then exit;

  result:=result+SerializeCardinal(_data.jointtype);
  for i:=0 to length(_data.limits)-1 do begin
    result:=result+SerializeVector2(_data.limits[i].limit);
    result:=result+SerializeFloat(_data.limits[i].spring_factor);
    result:=result+SerializeFloat(_data.limits[i].damping_factor);
  end;

  result:=result+SerializeFloat(_data.spring_factor);
  result:=result+SerializeFloat(_data.damping_factor);
  result:=result+SerializeCardinal(_data.ik_flags);
  result:=result+SerializeFloat(_data.break_force);
  result:=result+SerializeFloat(_data.break_torque);
  result:=result+SerializeFloat(_data.friction);
end;

function TOgfJointIKData.GetData(): TOgfJointIKDataRawData;
begin
  result:=_data;
end;

procedure TOgfJointIKData.SetData(d: TOgfJointIKDataRawData);
begin
  _data:=d;
end;

class function TOgfJointIKData.GetDefault(): TOgfJointIKDataRawData;
var
  i:integer;
begin
  result.jointtype:=OGF_JOINT_TYPE_RIGID;
  result.spring_factor:=1;
  result.damping_factor:=1;
  result.ik_flags:=0;
  result.break_force:=0;
  result.break_torque:=0;
  result.friction:=0;

  for i:=0 to length(result.limits)-1 do begin
    result.limits[i].limit.x:=0;
    result.limits[i].limit.y:=0;
    result.limits[i].damping_factor:=1;
    result.limits[i].spring_factor:=1;
  end;
end;

{ TOgfJointData }

procedure TOgfJointData._AssignWrkKey(key: TMotionKey);
var
  new_t:FMatrix4x4;
begin
  m_rotation(new_t, key.Q);
  CorrectAlmostZeroOrOnesInRot(new_t);

  if IsRotSame(new_t, _wrk_transform) then begin
    _wrk_key.T:=key.T;
    m_translate_over(_wrk_transform, key.T);
  end else begin
    _wrk_key:=key;
    _wrk_transform:=new_t;
    m_translate_over(_wrk_transform, key.T);
  end;
end;

procedure TOgfJointData._AssignWrkTransform(var m: FMatrix4x4);
var
  t:FVector3;
begin
  CorrectAlmostZeroOrOnesInRot(m);
  if IsRotSame(m, _wrk_transform) then begin
    m_get_translation(m, t);
    m_translate_over(_wrk_transform, t);
    _wrk_key.T:=t;
  end else begin
    _wrk_transform:=m;
    _wrk_key:=TransformToMotionKey(_wrk_transform);
  end;
end;

procedure TOgfJointData._AssignBindWrkPose();
var
  m:FMatrix4x4;
begin
  GetBindTransformData(m);
  _AssignWrkTransform(m);
end;

procedure TOgfJointData._GetWrkTransform(var m: FMatrix4x4);
begin
  m:=_wrk_transform;
end;

procedure TOgfJointData._GetWrkKey(var key: TMotionKey);
begin
  key:=_wrk_key;
end;

constructor TOgfJointData.Create;
begin
  _ikdata:=TOgfJointIKData.Create;
  Reset();
end;

destructor TOgfJointData.Destroy;
begin
  Reset();
  FreeAndNil(_ikdata);
  inherited Destroy;
end;

procedure TOgfJointData.Reset;
begin
  _loaded:=false;
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

procedure TOgfJointData._InitDefault(offset: FVector3; rotate: FVector3);
begin
  Reset();

  _material:='default_object';
  _shape.shape_type:=OGF_SHAPE_TYPE_NONE;
  _rest_offset:=offset;
  _rest_rotate:=rotate;
  _ikdata.SetData(TOgfJointIKData.GetDefault());
  _mass:=10;
  _loaded:=true;
end;

function TOgfJointData.Loaded(): boolean;
begin
  result:=_loaded;
end;

function TOgfJointData.Deserialize(rawdata: string): integer;
var
  sz, total:integer;
  version:cardinal;
begin
  result:=-1;
  total:=0;

  Reset();
  _loaded:=true;

  if length(rawdata)<sizeof(cardinal) then exit;
  version:=pcardinal(@rawdata[1])^;
  if not AdvanceString(rawdata, sizeof(version)) then exit;
  total:=total+sizeof(version);

  if not DeserializeZStringAndSplit(rawdata, _material) then exit;
  total:=total+length(_material)+1;

  if length(rawdata)<sizeof(_shape) then exit;
  _shape:=pTOgfBoneShape(@rawdata[1])^;
  if not AdvanceString(rawdata, sizeof(_shape)) then exit;
  total:=total+sizeof(_shape);

  sz:=_ikdata.Deserialize(rawdata, version);
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

function TOgfJointData.Serialize(): string;
var
  t:string;
begin
  result:='';
  if not Loaded() then exit;
  t:=_ikdata.Serialize();
  if length(t) = 0 then exit;

  result:=result+SerializeCardinal(1); //version
  result:=result+_material+chr(0);
  result:=result+SerializeBlock(@_shape, sizeof(_shape));
  result:=result+t;
  result:=result+SerializeBlock(@_rest_rotate, sizeof(_rest_rotate));
  result:=result+SerializeBlock(@_rest_offset, sizeof(_rest_offset));
  result:=result+SerializeFloat(_mass);
  result:=result+SerializeBlock(@_center_of_mass, sizeof(_center_of_mass));
end;

function TOgfJointData.IKData: TOgfJointIKData;
begin
  result:=nil;
  if not Loaded() then exit;

  result:=_ikdata;
end;

function TOgfJointData.GetShape(): TOgfBoneShape;
begin
  result:=_shape;
end;

function TOgfJointData.MoveShape(v: FVector3): boolean;
begin
  result:=false;
  if not Loaded() then exit;

  if _shape.shape_type = OGF_SHAPE_TYPE_NONE then begin
    result:=true
  end else begin
    result:=ShapeMove(_shape, v);
  end;
end;

function TOgfJointData.SetShape(shape: TOgfBoneShape): boolean;
begin
  result:=false;
  if not Loaded() then exit;
  _shape:=shape;
  result:=true;
end;

function TOgfJointData.SerializeShape(): string;
var
  i:integer;
const
  HEADER:string = 'OgfShape';
begin
  result:='';
  if not Loaded() then exit;
  result:=result+HEADER;
  for i:=0 to sizeof(_shape)-1 do begin
    result:= result+PAnsiChar(@_shape)[i];
  end;
end;

function TOgfJointData.DeserializeShape(s: string): boolean;
const
  HEADER:string = 'OgfShape';
begin
  result:=false;
  if length(s) <> sizeof(_shape)+length(HEADER) then exit;
  if not Loaded() then exit;
  if leftstr(s, length(HEADER)) = HEADER then begin
    _shape:=pTOgfBoneShape(@s[length(HEADER)+1])^;
    result:=true;
  end;
end;

function TOgfJointData.GetMaterial(): string;
begin
  result:=_material;
end;

procedure TOgfJointData.SetMaterial(matname: string);
begin
  _material:=matname;
end;

procedure TOgfJointData.GetBindTransformData(var offset: FVector3;
  var rotate: FVector3);
begin
  offset:=_rest_offset;
  rotate:=_rest_rotate;
end;

procedure TOgfJointData.GetBindTransformData(var m: FMatrix4x4);
begin
  m_setXYZ(m, _rest_rotate);
  m_translate_over(m, _rest_offset);
end;

procedure TOgfJointData.SetBindTransformData(offset: FVector3; rotate: FVector3);
begin
  _rest_offset:=offset;
  _rest_rotate:=rotate;
end;

procedure TOgfJointData.SetBindTransformData(var m: FMatrix4x4);
begin
  m_getXYZi(m, _rest_rotate);
  m_get_translation(m, _rest_offset);
end;

procedure TOgfJointData.GetMassParams(var center: FVector3; var mass: single);
begin
  center:=_center_of_mass;
  mass:=_mass;
end;

procedure TOgfJointData.SetMassParams(center: FVector3; mass: single);
begin
  _mass:=mass;
  _center_of_mass:=center;
end;

procedure TOgfJointData.MoveMassCenter(delta: FVector3);
begin
  _center_of_mass:=v_add(_center_of_mass, delta);
end;

procedure TOgfJointData.MoveJointPosition(delta: FVector3);
begin
  _rest_offset:=v_add(_rest_offset, delta);
end;

function TOgfJointData.UniformScale(k: single): boolean;
begin
  result:=Loaded();
  if not result then exit;
  result:= ShapeUniformScale(_shape, k);
  if not result then exit;

  uniform_scale(_rest_offset, k);
  uniform_scale(_center_of_mass, k);
end;

{ TOgfBone }

procedure TOgfBone._SetName(name: string);
begin
  _name:=name;
end;

procedure TOgfBone._SetParentName(name: string);
begin
  _parent_name:=name;
end;

procedure TOgfBone._InitDefault(name: string; parent_name: string);
begin
  Reset();
  _SetName(name);
  _SetParentName(parent_name);
end;

procedure TOgfBone.MoveObb(var delta: FVector3);
begin
  _obb.m_translate:=v_add(_obb.m_translate, delta);
end;

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

function TOgfBone.SetOBB(obb: FObb): boolean;
begin
  _obb:=obb;
  result:=true;
end;

function TOgfBone.Rename(name: string): boolean;
begin
  _name:=name;
  result:=true;
end;

function TOgfBone.UniformScale(k: single): boolean;
var
  pp:FVector3;
begin
  result:=false;
  if not Loaded() then exit;
  uniform_scale(_obb, k, pp);
  result:=true;
end;

{ TOgfBonesContainer }

function TOgfBonesContainer._RegisterBone(b: TOgfBone): TBoneId;
var
  i:integer;
begin
  _loaded:=true;
  i:=length(_bones);
  setlength(_bones, i+1);
  _bones[i]:=b;
  result:=i;
end;

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

function TOgfTrisContainer.MarkIndependentElementsForSelectedVertices(
  var selected: TVertexFlaggedItems): integer;
var
  marked:integer;
  i:integer;
begin
  result:=0;

  for i:=0 to length(selected)-1 do begin
    if selected[i].is_flagged then begin
      result:=result+1;
    end;
  end;

  repeat
    marked:=0;
    for i:=0 to length(_tris)-1 do begin
      if (selected[_tris[i].v1].is_flagged) or (selected[_tris[i].v2].is_flagged) or (selected[_tris[i].v3].is_flagged) then begin
        if not (selected[_tris[i].v1].is_flagged) then begin
          selected[_tris[i].v1].is_flagged:=true;
          marked:=marked+1;
        end;

        if not (selected[_tris[i].v2].is_flagged) then begin
          selected[_tris[i].v2].is_flagged:=true;
          marked:=marked+1;
        end;

        if not (selected[_tris[i].v3].is_flagged) then begin
          selected[_tris[i].v3].is_flagged:=true;
          marked:=marked+1;
        end;
      end;
    end;

    result:=result+marked;
  until (marked = 0);
end;

function TOgfTrisContainer._FilterVertices(var filter: TVertexFlaggedItems; swr_data: TOgfSwiContainer): boolean;
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
    if not ((filter[_tris[i].v1].is_flagged) or (filter[_tris[i].v2].is_flagged) or (filter[_tris[i].v3].is_flagged)) then begin
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
  if _is_normalized then exit;
  if length(_bones) = 1 then begin
    _bones[0].weight:=1;
    exit;
  end;

  if except_bone_idx >= length(_bones) then except_bone_idx:=-1;

  if (except_bone_idx >= 0) and (_bones[except_bone_idx].weight >= 1) then begin
    for i:=0 to length(_bones)-1 do begin
      _bones[i].weight:=0;
    end;
    _bones[except_bone_idx].weight:=1;
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

  _is_normalized:=true;
end;

function TVertexBones.ExportSortedData(var out_bones: TVertexBones): boolean;
var
  i:integer;
begin
  result:=false;
  if out_bones = nil then exit;

  out_bones.Reset();
  for i:=0 to TotalLinkedBonesCount()-1 do begin
    out_bones.AddBone(GetBoneParams(i), false);
  end;
  out_bones._SortByWeights();
  out_bones.NormalizeWeights(); //for sure
  result:=true;
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
  _is_normalized:=false;
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
  _is_normalized:=false;
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
    if abs(_bones[i].weight) < EPS then continue;
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

  _is_normalized:=false;
  NormalizeWeights();

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
    _is_normalized:=false;
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
  filters:TVertexFlaggedItems;
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
      filters[i].is_flagged:=true;
    end;

    for i:=0 to GetTrisCountInCurrentLod()-1 do begin
      if not _tris.GetTriangle(i, true, t) then exit;
      filters[t.v1].is_flagged:=false;
      filters[t.v2].is_flagged:=false;
      filters[t.v3].is_flagged:=false;
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

function TOgfChild.BindVerticesToBone(target_boneid: TBoneID; selection_callback: TVerticesBindCallback; userdata: pointer): boolean;
begin
  result:=_verts.BindVerticesToBone(target_boneid, selection_callback, userdata);
end;

function TOgfChild.GetVerticesCountForBoneId(boneid: TBoneID): integer;
begin
  result:=_verts.GetVerticesCountForBoneID(boneid, true);
end;

function TOgfChild.FilterVertices(var filter: TVertexFlaggedItems): boolean;
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
 TUserFlaggingVerticesIterationCbData = record
   usercb:TVerticesIterationCallback;
   userdata:pointer;
   filter:TVertexFlaggedItems;
 end;
 pTUserFlaggingVerticesIterationCbData = ^TUserFlaggingVerticesIterationCbData;

function UserFlaggingVerticesIterationCb(vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; userdata:pointer):boolean;
var
  cbdata:pTUserFlaggingVerticesIterationCbData;
begin
  cbdata:=pTUserFlaggingVerticesIterationCbData(userdata);
  if cbdata^.usercb<>nil then begin
   cbdata^.filter[vertex_id].is_flagged:=cbdata^.usercb(vertex_id, data, uv, links, cbdata^.userdata);
  end else begin
    cbdata^.filter[vertex_id].is_flagged:=true;
  end;
  result:=true;
end;

function ReportFlaggedVerticesIterationCb(vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; userdata:pointer):boolean;
var
  cbdata:pTUserFlaggingVerticesIterationCbData;
begin
  result:=true;
  cbdata:=pTUserFlaggingVerticesIterationCbData(userdata);
  if cbdata^.usercb<>nil then begin
    if cbdata^.filter[vertex_id].is_flagged then begin
      result:=cbdata^.usercb(vertex_id, data, uv, links, cbdata^.userdata);
    end;
  end;
end;

function TOgfChild.RemoveVertices(cb: TVerticesIterationCallback; userdata: pointer): boolean;
var
  filter:TVertexFlaggedItems;
  cbdata:TUserFlaggingVerticesIterationCbData;
begin
  result:=false;
  if not Loaded() or (_verts.GetVerticesCount() = 0) then exit;
  setlength(filter,_verts.GetVerticesCount());

  try
    // Iterate over all vertices and execute callback to decide which vertices are to remove
    cbdata.filter:=filter;
    cbdata.usercb:=cb;
    cbdata.userdata:=userdata;
    _verts.IterateVertices(@UserFlaggingVerticesIterationCb, @cbdata);

    // Perform filtering
    result:=FilterVertices(filter);
  finally
    setlength(filter, 0);
  end;
end;

procedure TOgfChild.IterateAllVerticesOfTheSelectedElements(cb_selection: TVerticesIterationCallback; cb_result: TVerticesIterationCallback; userdata: pointer);
var
  filter:TVertexFlaggedItems;
  cbdata:TUserFlaggingVerticesIterationCbData;
  cnt:integer;
begin
  if (@cb_selection = nil) or (cb_result = nil) then exit;

  if not Loaded() or (_verts.GetVerticesCount() = 0) then exit;
  setlength(filter,_verts.GetVerticesCount());

  // Iterate over all vertices and get the list of user-selected vertices
  cbdata.filter:=filter;
  cbdata.usercb:=cb_selection;
  cbdata.userdata:=userdata;
  _verts.IterateVertices(@UserFlaggingVerticesIterationCb, @cbdata);

  // Select all vertices for provided elements
  _tris.MarkIndependentElementsForSelectedVertices(filter);

  // Iterate over all selected vertices and report them to the user
  cbdata.usercb:=cb_result;
  _verts.IterateVertices(@ReportFlaggedVerticesIterationCb, @cbdata);
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

  bindings_sorted:TVertexBones;
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
  end else begin
    bindings_sorted:=TVertexBones.Create();
    try
      if not bindings_in.ExportSortedData(bindings_sorted) then exit;

      if _link_type = OGF_LINK_TYPE_2 then begin
        pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex2link);
        pvert2link:=@_raw_data[pos];
        bone:=bindings_sorted.GetBoneParams(0);
        pvert2link^.bone0:=bone.bone_id;
        bone:=bindings_sorted.GetBoneParams(1);
        pvert2link^.bone1:=bone.bone_id;
        pvert2link^.weight1:=bone.weight;
        result:=true;
      end else if _link_type = OGF_LINK_TYPE_3 then begin
        pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex3link);
        pvert3link:=@_raw_data[pos];
        for i:=0 to bindings_sorted.TotalLinkedBonesCount()-1 do begin
          bone:=bindings_sorted.GetBoneParams(i);
          pvert3link^.bones[i]:=bone.bone_id;
          if i<length(pvert3link^.weights) then begin
            pvert3link^.weights[i]:=bone.weight;
          end;
        end;
        result:=true;
      end else if _link_type = OGF_LINK_TYPE_4 then begin
        pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertex4link);
        pvert4link:=@_raw_data[pos];
        for i:=0 to bindings_sorted.TotalLinkedBonesCount()-1 do begin
          bone:=bindings_sorted.GetBoneParams(i);
          pvert4link^.bones[i]:=bone.bone_id;
          if i<length(pvert4link^.weights) then begin
            pvert4link^.weights[i]:=bone.weight;
          end;
        end;
        result:=true;
      end;
    finally
      FreeAndNil(bindings_sorted);
    end;
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

      v^.pos:=v_sub(v^.pos, pivot_point^);
      v^.pos.x:=v^.pos.x*factors^.x;
      v^.pos.y:=v^.pos.y*factors^.y;
      v^.pos.z:=v^.pos.z*factors^.z;
      v^.pos:=v_add(v^.pos, pivot_point^)
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

      v^.pos:=v_sub(v^.pos, pivot_point^);
      v^.pos:=m_mul(m^, v^.pos);
      v^.pos:=v_add(v^.pos, pivot_point^);

      v^.norm:=m_mul(m^, v^.norm);
      v^.binorm:=m_mul(m^, v^.binorm);
      v^.tang:=m_mul(m^, v^.tang);
    end;

  finally
    FreeAndNil(b);
  end;
end;

function TOgfVertsContainer.BindVerticesToBone(new_bone_index: TBoneID; selection_callback: TVerticesBindCallback; userdata: pointer): boolean;
var
  i,j,k:integer;
  b:TVertexBones;
  v:pTOgfVertexCommonData;
  puv:pFVector2;
  bone:TVertexBone;
begin
  result:=false;
  if not Loaded() then exit;

  result:=true;
  b:=TVertexBones.Create();
  try
    for i:=0 to _verts_count-1 do begin
      if not _GetVertexBindings(i, b) then begin
        result:=false;
        continue;
      end;

      if selection_callback<>nil then begin
        puv:=_GetVertexUvDataPtr(i);
        v:=_GetVertexDataPtr(i);
        if (v=nil) or (puv=nil) then begin
          result:=false;
        end else if selection_callback(i, v, puv, b, new_bone_index, userdata) then begin
          b.NormalizeWeights();
          if not _SetVertexBindings(i, b) then begin
            result:=false;
          end;
        end;
      end else begin
        // Replace the 1st bone, set zero weights for the others
        k:=b.TotalLinkedBonesCount();
        b.Reset();
        bone.bone_id:=new_bone_index;
        bone.weight:=1;
        for j:=0 to k-1 do begin
          b.AddBone(bone, false);
          bone.weight:=0;
        end;
        if not _SetVertexBindings(i, b) then begin
          result:=false;
        end;
      end;
    end;
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

function TOgfVertsContainer._FilterVertices(var filter: TVertexFlaggedItems): boolean;
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
    if not filter[i].is_flagged then begin
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

function TOgfAnimationsParser._SplitCommonSource(): boolean;
var
  chunk:TChunkedOffset;
  rawdata, data:string;
begin
  result:=false;
  if _owns_source then exit;

  rawdata:='';
  chunk:=_source.FindSubChunk(CHUNK_OGF_S_SMPARAMS);
  if (chunk = INVALID_CHUNK) or not _source.EnterSubChunk(chunk) then exit;
  data:=_source.GetCurrentChunkRawDataAsString();
  rawdata:=rawdata+SerializeChunkHeader(CHUNK_OGF_S_SMPARAMS, length(data))+data;
  if not _source.RemoveCurrentChunk() then exit;

  chunk:=_source.FindSubChunk(CHUNK_OGF_S_MOTIONS);
  if (chunk = INVALID_CHUNK) or not _source.EnterSubChunk(chunk) then exit;
  data:=_source.GetCurrentChunkRawDataAsString();
  rawdata:=rawdata+SerializeChunkHeader(CHUNK_OGF_S_MOTIONS, length(data))+data;
  if not _source.RemoveCurrentChunk() then exit;

  _source:=TChunkedMemory.Create();
  _owns_source:=true;
  if not _source.LoadFromString(rawdata) then exit;

  result:=true;
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
 i, j:integer;
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

function TOgfAnimationsParser.RenameBone(old_name: string; new_name: string): boolean;
var
  part_id, bone_id:integer;
  bone:TOgfMotionBoneParams;

begin
  result:=false;
  if not Loaded() then exit;
  if _params.FindBoneIdxsByName(new_name, part_id, bone_id) then exit;

  if _params.FindBoneIdxsByName(old_name, part_id, bone_id) then begin
    bone:=_params.GetBone(part_id, bone_id);
    if bone<>nil then begin
      bone._SetName(new_name);
      result:=true;
    end;
  end;
end;

function TOgfAnimationsParser.RegisteredBonesCount(): integer;
begin
  result:=0;
  if not Loaded() then exit;
  result:=_params.GetTotalBonesCount();
end;

function TOgfAnimationsParser.GetRegisteredBoneName(idx: integer): string;
var
  bone:TOgfMotionBoneParams;
begin
  result:='';
  if (idx>=0) and (idx < _params.GetTotalBonesCount()) then begin
     bone:=_params.GetBoneByIdxInTrack(idx);
     if bone <> nil then begin
       result:=bone.GetName();
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

function TOgfAnimationsParser.SetAnimationMultiframeKeyForBone(anim_name: string; bone_name: string; start_key: integer; end_key: integer; k: TMotionKey): boolean;
var
  track:TOgfMotionTrack;
  bone:TOgfMotionBoneParams;
  part_id, bone_id, bone_id_in_track:integer;
  i:integer;
begin
  result:=false;
  track:=_GetMotionTrackByName(anim_name);
  if track = nil then exit;
  if (start_key > end_key) then exit;
  if (start_key < 0) then exit;
  if (end_key >= track.GetFramesCount()) then exit;

  if not _params.FindBoneIdxsByName(bone_name, part_id, bone_id) then exit;
  bone:=_params.GetBone(part_id, bone_id);
  if bone=nil then exit;
  bone_id_in_track:=bone.GetIdxInTracks();

  if (start_key = 0) and (end_key >= track.GetFramesCount()-1) then begin
    result:=track.MakeBoneStatic(bone_id_in_track, k);
  end else begin
    result:=true;
    for i:=start_key to end_key do begin
      result:=track.SetBoneKey(bone_id_in_track, i, k) and result;
    end;
  end;
end;

function TOgfAnimationsParser.InterpotateAnimationKeysForBone(anim_name: string; bone_name: string; start_key: integer; end_key: integer; factor: single; pos: boolean; rot: boolean): boolean;
var
  track:TOgfMotionTrack;
  bone:TOgfMotionBoneParams;
  part_id, bone_id:integer;
begin
  result:=false;
  if not Loaded() then exit;

  track:=_GetMotionTrackByName(anim_name);
  if (start_key < 0) then exit;
  if (end_key >= track.GetFramesCount()) then exit;

  if _params.FindBoneIdxsByName(bone_name, part_id, bone_id) then begin
    bone:=_params.GetBone(part_id, bone_id);
    if bone<>nil then begin
      result:=track.InterpolateBoneKeys(bone.GetIdxInTracks(), start_key, end_key, factor, pos, rot);
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

function TOgfAnimationsParser.RenameAnimation(old_name: string; new_name: string): boolean;
var
  idx:integer;
  def:TOgfMotionDefData;
  track:TOgfMotionTrack;
begin
  result:=false;
  if not Loaded() then exit;

  if GetAnimationIdByName(new_name) >=0 then exit;
  idx:=GetAnimationIdByName(old_name);
  if idx < 0 then exit;

  def:=_params.GetMotionDefByIdx(idx);
  if def.name<>old_name then exit;

  track:=_tracks.GetMotionTrack(def.motion_id);
  if track = nil then exit;

  track.SetName(new_name);

  def.name:=new_name;
  result:=_params.UpdateMotionDefsForIdx(idx, def);

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
  i, j:integer;
  data:TOgfMotionDefData;
  track:TOgfMotionTrack;
begin
  result:=false;
  idx:=GetAnimationIdByName(name);
  if idx < 0 then exit;

  result:=true;
  result:=_tracks.RemoveTrack(idx) and result;
  result:=_params.RemoveMotionDef(idx) and result;

{$IFDEF Debug}
  for i:=0 to _params.MotionsDefsCount-1 do begin
    data:=_params.GetMotionDefByIdx(i);
    for j:=0 to _tracks.MotionTracksCount()-1 do begin;
      track:=_tracks.GetMotionTrack(j);
      if track<>nil then begin
        if track._name = data.name then begin
          if data.motion_id<>j then begin
            // oops
            data.motion_id:=j;
            _params.UpdateMotionDefsForIdx(i, data);
          end;
        end;
      end;
    end;
  end;
{$ENDIF}
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

function TOgfAnimationsParser.IsBonePresent(name: string): boolean;
var
  part_id, bone_id:integer;
begin
  result:=false;
  if not Loaded() then exit;
  result:= _params.FindBoneIdxsByName(name, part_id, bone_id);
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

function TOgfParser._DeserializeHeader(rawdata: string): boolean;
begin
  result:=false;
  if length(rawdata)<>sizeof(TOgfHeader) then exit;
  _header:=pTOgfHeader(@PAnsiChar(rawdata)[0])^;
  result:=true;
end;

function TOgfParser._SerializeHeader(): string;
var
  tmpchr:PAnsiChar;
  i:integer;
begin
  result:='';
  tmpchr:=PAnsiChar(@_header);
  for i:=0 to sizeof(_header)-1 do begin
    result:=result+tmpchr[i];
  end;
end;

constructor TOgfParser.Create;
begin
  inherited;

  _children:=TOgfChildrenContainer.Create();
  _bone_names:=TOgfBonesContainer.Create();
  _joints:=TOgfJointsDataContainer.Create();
  _userdata:=TOgfUserdataContainer.Create();
  _lodref:=TOgfLodRefsContainer.Create();
  _motionrefs:=TOgfMotionRefs.Create();

  _skeleton:=TOgfSkeleton.Create();
  _animations:=TOgfAnimationsParser.Create();
end;

destructor TOgfParser.Destroy;
begin
  _skeleton.Free();
  _animations.Free();
  _children.Free();
  _bone_names.Free();
  _joints.Free();
  _userdata.Free();
  _lodref.Free();
  _motionrefs.Free();

  inherited Destroy;
end;

procedure TOgfParser.Reset;
begin
  _skeleton.Reset();
  _animations.Free();
  _animations:=TOgfAnimationsParser.Create();

  _children.Reset();
  _bone_names.Reset();
  _joints.Reset();
  _userdata.Reset();
  _lodref.Reset();
  _motionrefs.Reset();

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
      chunk:=mem.FindSubChunk(CHUNK_OGF_HEADER);
      if (chunk = INVALID_CHUNK) or not mem.EnterSubChunk(chunk) then exit;
      r:=_DeserializeHeader(mem.GetCurrentChunkRawDataAsString());
      mem.LeaveSubChunk();
      if not r then exit;

      if (_header.ogf_type<>MT_SKELETON_ANIM) and (_header.ogf_type<>MT_SKELETON_RIGID) then exit;

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
      r:=_joints.Deserialize(mem.GetCurrentChunkRawDataAsString());
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

      if not _skeleton._Build(_bone_names, _joints) then exit;

      chunk:=mem.FindSubChunk(CHUNK_OGF_S_MOTION_REFS);
      if (chunk <> INVALID_CHUNK) and mem.EnterSubChunk(chunk) then begin
        _motionrefs.Deserialize(mem.GetCurrentChunkRawDataAsString(), CHUNK_OGF_S_MOTION_REFS);
        mem.LeaveSubChunk();
        if not r then exit;
      end else begin
        chunk:=mem.FindSubChunk(CHUNK_OGF_S_MOTION_REFS2);
        if (chunk <> INVALID_CHUNK) and mem.EnterSubChunk(chunk) then begin
          _motionrefs.Deserialize(mem.GetCurrentChunkRawDataAsString(), CHUNK_OGF_S_MOTION_REFS2);
          mem.LeaveSubChunk();
          if not r then exit;
        end;
      end;

      if _motionrefs.Loaded() then begin
        _animations.Free();
        _animations:=TOgfAnimationsParser.Create();
      end else if _animations.LoadFromChunkedMem(mem) then begin
        _animations.ResetSource(_source);
      end else begin
        _animations.Free();
        _animations:=TOgfAnimationsParser.Create();
      end;
      _skeleton.AssignAnimations(_animations);

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
  header:string;
  children:string;
  bone_names:string;
  ikdata:string;
  userdata:string;
  lodref:string;
  motionrefs:string;

  rawstr:string;
  offset:TChunkedOffset;
begin
  result:=false;
  if not Loaded() then exit;

  children:=_children.Serialize();
  bone_names:=_bone_names.Serialize();
  ikdata:=_joints.Serialize();
  userdata:=_userdata.Serialize();
  lodref:=_lodref.Serialize();
  motionrefs:=_motionrefs.Serialize();

  if (length(motionrefs)>0) or ((_animations.Loaded() and (_animations.AnimationsCount()>0) and IsAnimationsEmbedded() )) then begin
    _header.ogf_type:=MT_SKELETON_ANIM;
  end else begin
    _header.ogf_type:=MT_SKELETON_RIGID;
  end;

  header:=_SerializeHeader();

  if not _UpdateChunk(CHUNK_OGF_HEADER, header) then exit;
  if not _UpdateChunk(CHUNK_OGF_CHILDREN, children) then exit;
  if not _UpdateChunk(CHUNK_OGF_S_BONE_NAMES, bone_names) then exit;
  if not _UpdateChunk(CHUNK_OGF_S_IKDATA, ikdata) then exit;
  if not _UpdateChunk(CHUNK_OGF_S_USERDATA, userdata) then exit;
  if not _UpdateChunk(CHUNK_OGF_S_LODS, lodref) then exit;

  if length(motionrefs)>0 then begin
    if _source.FindSubChunk(_motionrefs.GetChunkId())<>INVALID_CHUNK then begin
      if not _UpdateChunk(_motionrefs.GetChunkId(), motionrefs) then exit;
    end else begin
      rawstr:=_source.GetCurrentChunkRawDataAsString();
      rawstr:=rawstr+SerializeChunkHeader(_motionrefs.GetChunkId(), length(motionrefs))+motionrefs;
      _source.LoadFromString(rawstr);
    end;
  end else if _animations.Loaded() then begin
    _animations.UpdateSource();
  end else begin
    offset:=_source.FindSubChunk(CHUNK_OGF_S_MOTION_REFS2);
    if offset = INVALID_CHUNK then begin
      offset:=_source.FindSubChunk(CHUNK_OGF_S_MOTION_REFS);
    end;

    if (offset<>INVALID_CHUNK) and _source.EnterSubChunk(offset) then begin
      _source.RemoveCurrentChunk();
    end;
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

type
TAABBShapeGeneratorCbData = record
  valid:boolean;
  vcnt:integer;
  boneid:integer;
  mins, maxs: FVector3;
  bone_transform:FMatrix4x4;

end;
pTAABBShapeGeneratorCbData = ^TAABBShapeGeneratorCbData;

function AABBShapeGeneratorCb(vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; userdata:pointer):boolean;
var
  cb_data:pTAABBShapeGeneratorCbData;
  bonespace_coords:FVector3;
begin
  cb_data:=pTAABBShapeGeneratorCbData(userdata);

  if links.GetWeightForBoneId(cb_data^.boneid)>0 then begin
    cb_data^.vcnt:=cb_data^.vcnt+1;

    bonespace_coords.x := cb_data^.bone_transform.i.x * data^.pos.x + cb_data^.bone_transform.j.x * data^.pos.y + cb_data^.bone_transform.k.x * data^.pos.z + cb_data^.bone_transform.c.x;
    bonespace_coords.y := cb_data^.bone_transform.i.y * data^.pos.x + cb_data^.bone_transform.j.y * data^.pos.y + cb_data^.bone_transform.k.y * data^.pos.z + cb_data^.bone_transform.c.y;
    bonespace_coords.z := cb_data^.bone_transform.i.z * data^.pos.x + cb_data^.bone_transform.j.z * data^.pos.y + cb_data^.bone_transform.k.z * data^.pos.z + cb_data^.bone_transform.c.z;

    if not cb_data^.valid then begin
      cb_data^.valid:=true;
      cb_data^.mins:=bonespace_coords;
      cb_data^.maxs:=bonespace_coords;
    end else begin
      if cb_data^.mins.x > bonespace_coords.x  then cb_data^.mins.x := bonespace_coords.x;
      if cb_data^.mins.y > bonespace_coords.y  then cb_data^.mins.y := bonespace_coords.y;
      if cb_data^.mins.z > bonespace_coords.z  then cb_data^.mins.z := bonespace_coords.z;

      if cb_data^.maxs.x < bonespace_coords.x  then cb_data^.maxs.x := bonespace_coords.x;
      if cb_data^.maxs.y < bonespace_coords.y  then cb_data^.maxs.y := bonespace_coords.y;
      if cb_data^.maxs.z < bonespace_coords.z  then cb_data^.maxs.z := bonespace_coords.z;
    end;
  end;

  result:=true;
end;

function TOgfParser.GenerateBoneShapeAABB(boneid: TBoneID): TOgfBoneShape;
var
  i:integer;
  child:TOgfChild;
  cb_data:TAABBShapeGeneratorCbData;
  v:FVector3;
begin
  result.shape_type:=OGF_SHAPE_TYPE_INVALID;
  result.flags:=0;

  if not Loaded() then exit;

  if not _skeleton._SetBindPoseForWork() then exit;
  if not _skeleton._GetGlobalSpaceToWrkBoneSpaceMatrix(boneid, cb_data.bone_transform)  then exit;

  cb_data.valid:=false;
  cb_data.boneid:=boneid;
  cb_data.vcnt:=0;

  for i:=0 to _children.Count()-1 do begin
    child:=_children.Get(i);
    child.IterateVertices(@AABBShapeGeneratorCb, @cb_data);
  end;

  skeleton.GetBoneShape(boneid, result);
  if cb_data.vcnt = 0 then begin
    result.shape_type:=OGF_SHAPE_TYPE_NONE;
  end else if cb_data.valid then begin
    result.shape_type:=OGF_SHAPE_TYPE_BOX;
    m_identity(result.box.m_rotate);
    v:=v_sub(cb_data.maxs, cb_data.mins);
    v:=v_mul(v, 0.5);
    result.box.m_halfsize:=v;
    v:=v_add(cb_data.maxs, cb_data.mins);
    v:=v_mul(v, 0.5);
    result.box.m_translate:=v;
  end;
end;


type
TMeshBoundsCalcCbData = record
  valid:boolean;
  mins, maxs: FVector3;
end;
pTMeshBoundsCalcCbData = ^TMeshBoundsCalcCbData;

function MeshBoundsCalcCb(vertex_id:integer; data:pTOgfVertexCommonData; uv:pFVector2; links:TVertexBones; userdata:pointer):boolean;
var
  cb_data:pTMeshBoundsCalcCbData;
begin
  cb_data:=pTMeshBoundsCalcCbData(userdata);

  if not cb_data^.valid then begin
    cb_data^.valid:=true;
    cb_data^.mins:=data^.pos;
    cb_data^.maxs:=data^.pos;
  end else begin
    if cb_data^.mins.x > data^.pos.x  then cb_data^.mins.x := data^.pos.x;
    if cb_data^.mins.y > data^.pos.y  then cb_data^.mins.y := data^.pos.y;
    if cb_data^.mins.z > data^.pos.z  then cb_data^.mins.z := data^.pos.z;
    if cb_data^.maxs.x < data^.pos.x  then cb_data^.maxs.x := data^.pos.x;
    if cb_data^.maxs.y < data^.pos.y  then cb_data^.maxs.y := data^.pos.y;
    if cb_data^.maxs.z < data^.pos.z  then cb_data^.maxs.z := data^.pos.z;
  end;

  result:=true;
end;

function TOgfParser.CalculateBounds(): boolean;
var
  i:integer;
  child:TOgfChild;
  cb_data:TMeshBoundsCalcCbData;
  r, c:FVector3;
begin
  result:=false;
  if not Loaded() then exit;

  cb_data.valid:=false;

  for i:=0 to _children.Count()-1 do begin
    child:=_children.Get(i);
    child.IterateVertices(@MeshBoundsCalcCb, @cb_data);
  end;

  if cb_data.valid then begin
    _header.bb.max:=cb_data.maxs;
    _header.bb.min:=cb_data.mins;

    r:=v_sub(cb_data.maxs,cb_data.mins);
    r:=v_mul(r, 0.5);

    c:=v_add(cb_data.maxs,cb_data.mins);
    c:=v_mul(c, 0.5);
    _header.bs.c:=c;
    _header.bs.r:=v_magnitude(r);

    result:=true;
  end;
end;

function TOgfParser.GetModelBBox(): TOgfBBox;
begin
  result:=_header.bb;
end;

function TOgfParser.GetModelBSphere(): TOgfBSphere;
begin
  result:=_header.bs;
end;

procedure TOgfParser.SetModelBBox(bb: TOgfBBox);
begin
  _header.bb:=bb;
end;

procedure TOgfParser.SetModelBSphere(bs: TOgfBSphere);
begin
  _header.bs:=bs;
end;


function TOgfParser.IsAnimationsEmbedded(): boolean;
begin
  result:=false;
  if not Loaded() then exit;
  if _animations=nil then exit;
  result:=_source = _animations._source;
end;

function TOgfParser.SplitEmbeddedMotionsIntoSeparateSource(): boolean;
begin
  result:=false;
  if not Loaded() then exit;
  if not IsAnimationsEmbedded() then exit;

  result:=_animations._SplitCommonSource() and not IsAnimationsEmbedded();
end;

function TOgfParser.AddMotionRef(filename: string): integer;
begin
  result:=-1;
  if not Loaded() then exit;
  if IsAnimationsEmbedded() then exit;
  result:=_motionrefs.AddRef(filename);
end;

procedure TOgfParser.ResetMotionRefs();
begin
  _motionrefs.Reset;
end;


end.



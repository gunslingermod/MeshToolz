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

    function GetCurrentLinkType():cardinal;
    function GetVerticesCount():cardinal;
    function CalculateOptimalLinkType():cardinal;
    function ChangeLinkType(new_link_type:cardinal):boolean;
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
  end;

 { TOgfParser }

 TOgfParser = class
 private
   _loaded:boolean;
   _children:array of TOgfChild;
   _bone_names_s:string;
   _ikdata_s:string;
   _userdata:string;
   _lodref:string;
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
   function LoadFromMem(addr:pointer; sz:cardinal):boolean;
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
  CHUNK_OGF_S_BONE_NAMES:word=13;

implementation
uses sysutils;

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

{ TOgfBonesContainer }

constructor TOgfBonesContainer.Create;
begin
  setlength(_bones, 0);
  _loaded:=false;
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
    bone.weight:=1 - pvert2link^.bone1;
    bindings_out.AddBone(bone, false);

    bone.bone_id:=pvert2link^.bone1;
    bone.weight:=pvert2link^.bone1;
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
    for i:=0 to _verts_count-1 do begin
      if not _GetVertexBindings(i, b) then exit;
      for j:=0 to b.TotalLinkedBonesCount()-1 do begin
        bone:=b.GetBoneParams(i);
        if bone.bone_id = old_bone_index then begin
          bone.bone_id:=new_bone_index;
          if not b.SetBoneParams(i, bone, false) then exit;
        end;
      end;
      if not _SetVertexBindings(i, b) then exit;
    end;
    result:=true;
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

function TOgfVertsContainer.Deserialize(rawdata: string): boolean;
var
  phdr:pTOgfVertsHeader;
  i:integer;
  raw_data_sz:cardinal;
begin
  result:=false;
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

{ TOgfParser }

constructor TOgfParser.Create;
begin

end;

destructor TOgfParser.Destroy;
begin
  inherited Destroy;
end;

procedure TOgfParser.Reset;
begin

end;

function TOgfParser.Loaded(): boolean;
begin

end;

function TOgfParser.Deserialize(rawdata: string): boolean;
begin

end;

function TOgfParser.Serialize(): string;
begin

end;

function TOgfParser.LoadFromFile(fname: string): boolean;
begin

end;

function TOgfParser.LoadFromMem(addr: pointer; sz: cardinal): boolean;
begin

end;


end.


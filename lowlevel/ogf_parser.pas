unit ogf_parser;

{$mode objfpc}{$H+}

interface

uses
  ChunkedFileParser, basedefs;

const
  OGF_VERTEX_CONTAINER_NOT_LOADED : cardinal = 0;

  OGF_LINK_TYPE_RIGID : cardinal = 1;
  OGF_VERTEXFORMAT_FVF_1L : cardinal = $12071980;

  CHUNK_OGF_HEADER:word=1;
  CHUNK_OGF_TEXTURE:word=2;
  CHUNK_OGF_VERTICES:word=3;
  CHUNK_OGF_INDICES:word=4;
  CHUNK_OGF_SWIDATA:word=6;

type
  TOgfVertexCommonData = packed record
    pos:FVector3;
    norm:FVector3;
    tang:FVector3;
    binorm:FVector3;
  end;
  pTOgfVertexCommonData = ^TOgfVertexCommonData;

  TOgfVertexRigid = packed record
    spatial:TOgfVertexCommonData;
    uv:FVector2;
    bone_id:cardinal
  end;
  pTOgfVertexRigid = ^TOgfVertexRigid;

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

  { TVertexBindings }

  TVertexBindings = class
  private
    _bone_ids: array of word;
  public
    constructor Create();
    destructor Destroy; override;
    procedure Reset();
    function BonesCount():integer;
    function AddBone(id:word):boolean;
    function GetBoneID(index:integer):word;
    function SetBoneID(index:integer; id:word):boolean;
  end;

  { TOgfVertsContainer }

  TOgfVertsContainer = class
  private
    _link_type:cardinal;
    _verts_count:cardinal;
    _raw_data:array of byte;
    function _GetVertexDataPtr(id:cardinal):pTOgfVertexCommonData;
    function _GetVertexBindings(id:cardinal; bindings_out:TVertexBindings):boolean;
    function _SetVertexBindings(id:cardinal; bindings_in:TVertexBindings):boolean;
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
    function RebindVerticesToNewBone(new_bone_index:integer; old_bone_index:integer=-1):boolean; // -1 means all bones
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
  end;

 { TOgfParser }

 TOgfParser = class
 private
   _loaded:boolean;
   _children:array of TOgfChild;
 public
   // Common
   constructor Create;
   destructor Destroy; override;
   procedure Reset;
   function Loaded():boolean;

   function LoadFromFile(fname:string):boolean;
end;

implementation
uses sysutils;

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
  total_components_count, total_data_size:cardinal;
  tris_components_count, tris_count:integer;
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
  total_components_count:=tris_components_count*length(_tris);

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

{ TVertexBindings }

constructor TVertexBindings.Create();
begin
  Reset();
end;

destructor TVertexBindings.Destroy;
begin
  Reset();
  inherited Destroy;
end;

procedure TVertexBindings.Reset();
begin
  setlength(_bone_ids, 0);
end;

function TVertexBindings.BonesCount(): integer;
begin
  result:=length(_bone_ids);
end;

function TVertexBindings.AddBone(id: word):boolean;
var
  i:integer;
begin
  result:=false;
  for i:=0 to length(_bone_ids)-1 do begin
    if _bone_ids[i] = id then exit;
  end;
  setlength(_bone_ids, length(_bone_ids)+1);
  _bone_ids[length(_bone_ids)-1]:=id;
end;

function TVertexBindings.GetBoneID(index: integer): word;
begin
  if index >= length(_bone_ids) then begin
    result:=$FFFF;
    exit;
  end;
  result:=_bone_ids[index];
end;

function TVertexBindings.SetBoneID(index: integer; id: word): boolean;
var
  i:integer;
begin
  result:=false;
  if index >= length(_bone_ids) then exit;
  for i:=0 to length(_bone_ids)-1 do begin
    if (i<>index) and (_bone_ids[i] = id) then exit;
  end;
  _bone_ids[index]:=id;
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
  i:=Pos(chr(0), rawdata);
  if i<=0 then exit;
  tex_name:=leftstr(rawdata, i-1);
  rawdata:=rightstr(rawdata, length(rawdata)-i);
  i:=Pos(chr(0), rawdata);
  shader_name:=leftstr(rawdata, i-1);
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
  prigidvert:pTOgfVertexRigid;
begin
  result:=nil;
  if not Loaded() then exit;
  if id >= _verts_count then exit;

  if _link_type = OGF_LINK_TYPE_RIGID then begin
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertexRigid);
    prigidvert:=@_raw_data[pos];
    result:=@prigidvert^.spatial;
  end;
end;

function TOgfVertsContainer._GetVertexBindings(id: cardinal; bindings_out: TVertexBindings): boolean;
var
  pos:cardinal;
  prigidvert:pTOgfVertexRigid;
begin
  result:=false;
  if not Loaded() then exit;
  if id >= _verts_count then exit;

  if _link_type = OGF_LINK_TYPE_RIGID then begin
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertexRigid);
    prigidvert:=@_raw_data[pos];
    bindings_out.Reset();
    bindings_out.AddBone(prigidvert^.bone_id);
    result:=true;
  end;
end;

function TOgfVertsContainer._SetVertexBindings(id: cardinal; bindings_in: TVertexBindings): boolean;
var
  pos:cardinal;
  prigidvert:pTOgfVertexRigid;
begin
  result:=false;
  if not Loaded() then exit;
  if id >= _verts_count then exit;

  if _link_type = OGF_LINK_TYPE_RIGID then begin
    if bindings_in.BonesCount()<>1 then exit;
    pos:=sizeof(TOgfVertsHeader)+id*sizeof(TOgfVertexRigid);
    prigidvert:=@_raw_data[pos];
    prigidvert^.bone_id:=bindings_in.GetBoneID(0);
    result:=true;
  end;
end;

procedure TOgfVertsContainer.Reset;
begin
  _link_type:=OGF_VERTEX_CONTAINER_NOT_LOADED;
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
  result:=_link_type<>OGF_VERTEX_CONTAINER_NOT_LOADED;
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

function TOgfVertsContainer.RebindVerticesToNewBone(new_bone_index: integer; old_bone_index: integer): boolean;
var
  i, j:integer;
  b:TVertexBindings;
begin
  result:=false;
  if not Loaded() then exit;

  b:=TVertexBindings.Create();
  try
    for i:=0 to _verts_count-1 do begin
      if old_bone_index < 0 then begin
        b.Reset();
        b.AddBone(new_bone_index);
      end else begin
        if not _GetVertexBindings(i, b) or (b.BonesCount()<=0) then exit;
        for j:=0 to b.BonesCount()-1 do begin
          if b.GetBoneID(j)=old_bone_index then begin
            if not b.SetBoneID(j, new_bone_index) then exit;
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

  if (phdr^.link_type = OGF_LINK_TYPE_RIGID) or (phdr^.link_type = OGF_VERTEXFORMAT_FVF_1L) then begin
    if sizeof(TOgfVertsHeader) + phdr^.count*sizeof(TOgfVertexRigid) <> raw_data_sz then exit;
    _link_type:=OGF_LINK_TYPE_RIGID;
    _verts_count:=phdr^.count;
    setlength(_raw_data, length(rawdata));
    for i:=1 to length(rawdata) do begin
      _raw_data[i-1]:=byte(rawdata[i]);
    end;
    result:=true;
  end else begin
    exit;
  end;
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

function TOgfParser.LoadFromFile(fname: string): boolean;
begin

end;


end.


unit ogf_parser_tests;

{$mode objfpc}{$H+}

interface


function BonesLinksContainerTest():boolean;
function VertexContainerTest():boolean;
function TextureContainerTest():boolean;
function OgfChildRebuildTest():boolean;

function RunAllTests():boolean;

implementation
uses ChunkedFileParser, ogf_parser, basedefs, sysutils;

const
  TEST_OGF_IN_NAME:string='test_data\test_in.ogf';
  TEST_OGF_OUT_NAME:string='test_data\test_out.ogf';

  TEST_OMF_IN_NAME:string='test_data\test_omf_in.omf';
  TEST_OMF_OUT_NAME:string='test_data\test_omf_out.omf';

  TEST_OMF_MMARKS_IN_NAME:string='test_data\test_omf_mmarks_in.omf';
  TEST_OMF_MMARKS_OUT_NAME:string='test_data\test_omf_mmarks_out.omf';

procedure PrintTestResult(test_name:string; result:boolean);
var
  res_str:string;
begin
  if result then res_str:='passed' else res_str:='FAILED';
  writeln('[RESULT] Test "'+test_name+'" is '+res_str);
end;

function BonesLinksContainerTest(): boolean;
var
  bones:TVertexBones;
  bone:TVertexBone;
  i, tmpi:integer;
const
  EPS = 0.00001;
begin
  result:=false;
  bones:=TVertexBones.Create();
  try
    // Add 3 3 different bone with the same weight without normalization
    tmpi:=3;
    for i:=1 to tmpi do begin
      bone.bone_id:=i;
      bone.weight:=1;
      bones.AddBone(bone, false);
    end;
    if (bones.TotalLinkedBonesCount()<>tmpi) or (bones.SimplifiedLinkedBonesCount()<>tmpi) then exit;
    for i:=0 to bones.TotalLinkedBonesCount()-1 do begin
      bone:=bones.GetBoneParams(i);
      if bone.weight<>1 then exit;
    end;

    //Check normalization - all bones must have the same values
    bones.NormalizeWeights();
    for i:=0 to bones.TotalLinkedBonesCount()-1 do begin
      bone:=bones.GetBoneParams(i);
      if abs(bone.weight - (1/tmpi)) > EPS then exit;
    end;

    // Add bone with normalization of other bones
    bone.bone_id:=tmpi+1;
    bone.weight:=0.5;
    bones.AddBone(bone, true);
    for i:=0 to bones.TotalLinkedBonesCount()-1 do begin
      bone:=bones.GetBoneParams(i);
      if bone.bone_id = tmpi+1 then begin
        if bone.weight<>0.5 then exit;
      end else begin
        if abs(bone.weight - (1/(tmpi*2))) > EPS then exit;
      end;
    end;

    // Add bone with the same ID without normalization
    bone.bone_id:=1;
    bone.weight:=0.2;
    bones.AddBone(bone, false);
    if (bones.TotalLinkedBonesCount()<>tmpi+2) then exit;
    for i:=0 to bones.TotalLinkedBonesCount()-1 do begin
      bone:=bones.GetBoneParams(i);
      if i = tmpi then begin
        if bone.weight<>0.5 then exit;
      end else if i = tmpi+1 then begin
        if abs(bone.weight-0.2) > EPS then exit;
      end else begin
        if abs(bone.weight - (1/(tmpi*2))) > EPS then exit;
      end;
    end;

    // Check simplification
    if (bones.SimplifiedLinkedBonesCount()<>tmpi+1) then exit;
    bones.SimplifyLinks();
    if (bones.TotalLinkedBonesCount()<>tmpi+1) or (bones.SimplifiedLinkedBonesCount()<>tmpi+1) then exit;
    if abs(bones.GetWeightForBoneId(1) - (0.2+1/(tmpi*2))) > EPS then exit;

    //Normalize
    bones.NormalizeWeights();
    if abs(bones.GetWeightForBoneId(1) - (0.2+1/(tmpi*2))/1.2) > EPS then exit;

    // Add bone with "rigid" link - must replace all weights after normalization
    bone.bone_id:=tmpi+2;
    bone.weight:=1;
    bones.AddBone(bone, true);
    if bones.SimplifiedLinkedBonesCount() <> 1 then exit;
    bones.SimplifyLinks();
    if bones.SimplifiedLinkedBonesCount() <> bones.TotalLinkedBonesCount() then exit;

    //Check change link type
    bone.bone_id:=0;
    bone.weight:=0.5;
    bones.AddBone(bone, true);
    bone.bone_id:=1;
    bone.weight:=0.5;
    bones.AddBone(bone, true);
    if bones.TotalLinkedBonesCount()<>3 then exit;
    bones.ChangeLinkType(2);
    if bones.TotalLinkedBonesCount()<>2 then exit;
    if (bones.GetBoneParams(0).bone_id<>1) or (abs(bones.GetBoneParams(0).weight-2/3)>EPS) then exit;
    if (bones.GetBoneParams(1).bone_id<>0) or (abs(bones.GetBoneParams(1).weight-1/3)>EPS) then exit;

    result:=true;
  finally
    bones.Free;
    PrintTestResult('BonesLinksContainerTest', result);
  end;
end;

function VertexContainerTest():boolean;
var
  f:TChunkedMemory;
  vc:TOgfVertsContainer;
  offset:FVector3;
  data:string;
const
  CHUNK_PATH:string='9:0:3';
begin
  result:=false;
  f:=TChunkedMemory.Create();
  vc:=TOgfVertsContainer.Create();
  try
    if not f.LoadFromFile(TEST_OGF_IN_NAME, 0) then exit;
    if not f.NavigateToChunk(CHUNK_PATH) then exit;
    data:=f.GetCurrentChunkRawDataAsString();
    if not vc.Deserialize(data) then exit;
    offset.x:=0;
    offset.y:=-1;
    offset.z:=0;
    if not vc.MoveVertices(offset) then exit;
    data:=vc.Serialize();
    if not f.ReplaceCurrentRawDataWithString(data) then exit;
    if not f.SaveToFile(TEST_OGF_OUT_NAME) then exit;
    result:=true;
  finally
    vc.Free;
    f.Free;
    DeleteFile(TEST_OGF_OUT_NAME);
    PrintTestResult('VertexContainerTest', result);
  end;
end;

function TextureContainerTest():boolean;
var
  f:TChunkedMemory;
  tc:TOgfTextureDataContainer;
  td, td_new:TOgfTextureData;
  data:string;
const
  MOD_STR:string='_modified';
  CHUNK_PATH:string='9:0:2';
begin
  result:=false;
  f:=TChunkedMemory.Create();
  tc:=TOgfTextureDataContainer.Create();
  try
    // Load, modify shader & texture and save modified file
    if not f.LoadFromFile(TEST_OGF_IN_NAME, 0) then exit;
    if not f.NavigateToChunk(CHUNK_PATH) then exit;
    data:=f.GetCurrentChunkRawDataAsString();
    if not tc.Deserialize(data) then exit;
    td:=tc.GetTextureData();
    td.shader:=td.shader+MOD_STR;
    td.texture:=td.texture+MOD_STR;
    tc.SetTextureData(td);
    data:=tc.Serialize();
    if not f.ReplaceCurrentRawDataWithString(data) then exit;
    if not f.SaveToFile(TEST_OGF_OUT_NAME) then exit;


    // Load modified and check if the data is equal
    if not f.LoadFromFile(TEST_OGF_OUT_NAME, 0) then exit;
    if not f.NavigateToChunk(CHUNK_PATH) then exit;
    data:=f.GetCurrentChunkRawDataAsString();
    if not tc.Deserialize(data) then exit;
    td_new:=tc.GetTextureData();
    if (td_new.shader<>td.shader) or (td_new.texture<>td.texture) then exit;

    result:=true;
  finally
    tc.Free;
    f.Free;
    DeleteFile(TEST_OGF_OUT_NAME);
    PrintTestResult('TextureContainerTest', result);
  end;
end;

function OgfChildRebuildTest():boolean;
var
  f:TChunkedMemory;
  child:TOgfChild;
  data_new, data:string;
  td:TOgfTextureData;
const
  CHUNK_PATH:string='9:0';
begin
  result:=false;
  f:=TChunkedMemory.Create();
  child:=TOgfChild.Create();
  try
    if not f.LoadFromFile(TEST_OGF_IN_NAME, 0) then exit;
    if not f.NavigateToChunk(CHUNK_PATH) then exit;
    data:=f.GetCurrentChunkRawDataAsString();
    if not child.Deserialize(data) then exit;
    td:=child.GetTextureData();
    if not child.SetTextureData(td) then exit;
    data_new:=child.Serialize();
    if not f.ReplaceCurrentRawDataWithString(data_new) then exit;
    if not f.SaveToFile(TEST_OGF_OUT_NAME) then exit;

    if data <> data_new then exit;
    result:=true;
  finally
    child.Free;
    f.Free;
    DeleteFile(TEST_OGF_OUT_NAME);
    PrintTestResult('OgfChildRebuildTest', result);
  end;
end;

function OgfChildSimplifyLinksTest():boolean;
var
  f:TChunkedMemory;
  child:TOgfChild;
  data_new, data:string;
  newlink:cardinal;

const
  CHUNK_PATH:string='9:0';
begin
  result:=false;
  f:=TChunkedMemory.Create();
  child:=TOgfChild.Create();
  try
    if not f.LoadFromFile(TEST_OGF_IN_NAME, 0) then exit;
    if not f.NavigateToChunk(CHUNK_PATH) then exit;
    data:=f.GetCurrentChunkRawDataAsString();
    if not child.Deserialize(data) then exit;

    newlink:=child.CalculateOptimalLinkType();
    if (newlink=OGF_LINK_TYPE_INVALID) or (newlink = child.GetCurrentLinkType()) then exit;
    if not child.ChangeLinkType(newlink) then exit;
    if newlink<>child.GetCurrentLinkType() then exit;

    data_new:=child.Serialize();
    if not f.ReplaceCurrentRawDataWithString(data_new) then exit;
    if not f.SaveToFile(TEST_OGF_OUT_NAME) then exit;

    if not child.Deserialize(data_new) then exit;
    if newlink<>child.GetCurrentLinkType() then exit;

    result:=true;
  finally
    child.Free;
    f.Free;
    DeleteFile(TEST_OGF_OUT_NAME);
    PrintTestResult('OgfChildSimplifyLinksTest', result);
  end;
end;

function OgfBoneTest():boolean;
var
  f:TChunkedMemory;
  bones:TOgfBonesContainer;
  data_new, data_old:string;
const
  CHUNK_PATH:string='13';
begin
  result:=false;
  f:=TChunkedMemory.Create();
  bones:=TOgfBonesContainer.Create();
  try
    if not f.LoadFromFile(TEST_OGF_IN_NAME, 0) then exit;
    if not f.NavigateToChunk(CHUNK_PATH) then exit;
    data_old:=f.GetCurrentChunkRawDataAsString();
    if not bones.Deserialize(data_old) then exit;

    data_new:=bones.Serialize();
    if not f.ReplaceCurrentRawDataWithString(data_new) then exit;
    if not f.SaveToFile(TEST_OGF_OUT_NAME) then exit;
    if data_new <> data_old then exit;
    if data_new <> f.GetCurrentChunkRawDataAsString() then exit;

    result:=true;
  finally
    bones.Free;
    f.Free;
    DeleteFile(TEST_OGF_OUT_NAME);
    PrintTestResult('OgfBoneContainerTest', result);
  end;
end;

function OgfIKDataTest():boolean;
var
  f:TChunkedMemory;
  ik:TOgfBonesIKDataContainer;
  data_new, data_old:string;
const
  CHUNK_PATH:string='16';
begin
  result:=false;
  f:=TChunkedMemory.Create();
  ik:=TOgfBonesIKDataContainer.Create();
  try
    if not f.LoadFromFile(TEST_OGF_IN_NAME, 0) then exit;
    if not f.NavigateToChunk(CHUNK_PATH) then exit;
    data_old:=f.GetCurrentChunkRawDataAsString();
    if not ik.Deserialize(data_old) then exit;

    data_new:=ik.Serialize();
    if not f.ReplaceCurrentRawDataWithString(data_new) then exit;
    if not f.SaveToFile(TEST_OGF_OUT_NAME) then exit;
    if data_new <> data_old then exit;
    if data_new <> f.GetCurrentChunkRawDataAsString() then exit;

    result:=true;
  finally
    ik.Free;
    f.Free;
    DeleteFile(TEST_OGF_OUT_NAME);
    PrintTestResult('OgfIKDataTest', result);
  end;
end;

function OgfChildrenContainerTest():boolean;
var
  f:TChunkedMemory;
  children:TOgfChildrenContainer;
  data_new, data_old:string;
const
  CHUNK_PATH:string='9';
begin
  result:=false;
  f:=TChunkedMemory.Create();
  children:=TOgfChildrenContainer.Create();
  try
    if not f.LoadFromFile(TEST_OGF_IN_NAME, 0) then exit;
    if not f.NavigateToChunk(CHUNK_PATH) then exit;
    data_old:=f.GetCurrentChunkRawDataAsString();
    if not children.Deserialize(data_old) then exit;

    data_new:=children.Serialize();
    if not f.ReplaceCurrentRawDataWithString(data_new) then exit;
    if not f.SaveToFile(TEST_OGF_OUT_NAME) then exit;
    if data_new<>data_old then exit;
    if data_new <> f.GetCurrentChunkRawDataAsString() then exit;

    result:=true;
  finally
    children.Free;
    f.Free;
    DeleteFile(TEST_OGF_OUT_NAME);
    PrintTestResult('OgfChildrenContainerTest', result);
  end;
end;

function OgfModelParserTest():boolean;
var
  p:TOgfParser;
  data_new, data_old:string;
  f:TChunkedMemory;
begin
  result:=false;
  p:=TOgfParser.Create();
  f:=TChunkedMemory.Create();
  try
    if not f.LoadFromFile(TEST_OGF_IN_NAME, 0) then exit;
    data_old:=f.GetCurrentChunkRawDataAsString();

    if not p.LoadFromFile(TEST_OGF_IN_NAME) then exit;
    data_new:=p.Serialize();
    if length(data_new) = 0 then exit;

    if not f.LoadFromString(data_new) then exit;
    if not f.SaveToFile(TEST_OGF_OUT_NAME) then exit;
    if data_new <> data_old then exit;

    result:=true;
  finally
    p.Free;
    f.Free;
    DeleteFile(TEST_OGF_OUT_NAME);
    PrintTestResult('OgfModelParserTest', result);
  end;
end;

function OgfMotionTracksContainerTest():boolean;
var
  f:TChunkedMemory;
  container:TOgfMotionTracksContainer;
  data_old:string;
  data_new:string;
const
  CHUNK_PATH:string='14';
begin
  result:=false;
  f:=TChunkedMemory.Create();
  container:=TOgfMotionTracksContainer.Create();
  try
    if not f.LoadFromFile(TEST_OMF_IN_NAME, 0) then exit;
    if not f.NavigateToChunk(CHUNK_PATH) then exit;
    data_old:=f.GetCurrentChunkRawDataAsString();
    if not container.Deserialize(data_old) then exit;

    data_new:=container.Serialize();
    if not f.ReplaceCurrentRawDataWithString(data_new) then exit;
    if not f.SaveToFile(TEST_OMF_OUT_NAME) then exit;
    if data_new<>data_old then exit;
    if data_new <> f.GetCurrentChunkRawDataAsString() then exit;
    result:=true;
  finally
    container.Free;
    f.Free;
    DeleteFile(TEST_OMF_OUT_NAME);
    PrintTestResult('OgfMotionTracksContainerTest', result);
  end;

end;

function OgfMotionParamsContainerTest():boolean;
var
  f:TChunkedMemory;
  container:TOgfMotionParamsContainer;
  data_old:string;
  data_new:string;
const
  CHUNK_PATH:string='15';
begin
  result:=false;
  f:=TChunkedMemory.Create();
  container:=TOgfMotionParamsContainer.Create();
  try
    if not f.LoadFromFile(TEST_OMF_IN_NAME, 0) then exit;
    if not f.NavigateToChunk(CHUNK_PATH) then exit;
    data_old:=f.GetCurrentChunkRawDataAsString();
    if not container.Deserialize(data_old) then exit;

    data_new:=container.Serialize();
    if not f.ReplaceCurrentRawDataWithString(data_new) then exit;
    if not f.SaveToFile(TEST_OMF_OUT_NAME) then exit;
    if data_new<>data_old then exit;
    if data_new <> f.GetCurrentChunkRawDataAsString() then exit;
    result:=true;
  finally
    container.Free;
    f.Free;
    DeleteFile(TEST_OMF_OUT_NAME);
    PrintTestResult('OgfMotionParamsContainerTest', result);
  end;
end;

function OgfMotionsMmarksCopyTest():boolean;
var
  f:TChunkedMemory;
  container:TOgfMotionParamsContainer;
  data_old:string;
  data_new:string;

  motionid:integer;
  mdef:TOgfMotionDefData;
  mmarks:TOgfMotionMarks;
const
  CHUNK_PATH:string='15';
begin
  result:=false;
  f:=TChunkedMemory.Create();
  container:=TOgfMotionParamsContainer.Create();
  mmarks:=TOgfMotionMarks.Create();
  try
    if not f.LoadFromFile(TEST_OMF_MMARKS_IN_NAME, 0) then exit;
    if not f.NavigateToChunk(CHUNK_PATH) then exit;
    data_old:=f.GetCurrentChunkRawDataAsString();
    if not container.Deserialize(data_old) then exit;

    motionid:=container.GetMotionIdxForName('f1_throw_end');
    if motionid <0 then exit;
    mdef:=container.GetMotionDefByIdx(motionid);
    if length(mdef.name)=0 then exit;
    mmarks.CopyFrom(mdef.marks);
    mdef.marks.CopyFrom(mmarks);
    if not container.UpdateMotionDefsForIdx(motionid, mdef) then exit;

    data_new:=container.Serialize();
    if not f.ReplaceCurrentRawDataWithString(data_new) then exit;
    if not f.SaveToFile(TEST_OMF_OUT_NAME) then exit;
    if data_new<>data_old then exit;
    if data_new <> f.GetCurrentChunkRawDataAsString() then exit;
    result:=true;
  finally
    container.Free;
    mmarks.Free;
    f.Free;
    DeleteFile(TEST_OMF_OUT_NAME);
    PrintTestResult('OgfMotionsMmarksCopyTest', result);
  end;
end;

function OgfMotionsParserTest():boolean;
var
  p:TOgfAnimationsParser;
  data_new, data_old:string;
  f:TChunkedMemory;
begin
  result:=false;
  p:=TOgfAnimationsParser.Create();
  f:=TChunkedMemory.Create();
  try
    if not f.LoadFromFile(TEST_OMF_IN_NAME, 0) then exit;
    data_old:=f.GetCurrentChunkRawDataAsString();

    if not p.LoadFromChunkedMem(f) then exit;
    data_new:=p.Serialize();
    if length(data_new) = 0 then exit;

    if not f.LoadFromString(data_new) then exit;
    if not f.SaveToFile(TEST_OMF_OUT_NAME) then exit;
    if data_new <> data_old then exit;

    result:=true;
  finally
    p.Free;
    f.Free;
    DeleteFile(TEST_OGF_OUT_NAME);
    PrintTestResult('OgfMotionsParserTest', result);
  end;
end;

function RunAllTests():boolean;
begin
  result:=true;
  if not BonesLinksContainerTest() then result:=false;
  if not VertexContainerTest() then result:=false;
  if not TextureContainerTest() then result:=false;
  if not OgfChildRebuildTest() then result:=false;
  if not OgfChildSimplifyLinksTest() then result:=false;
  if not OgfBoneTest() then result:=false;
  if not OgfIKDataTest() then result:=false;
  if not OgfChildrenContainerTest() then result:=false;
  if not OgfModelParserTest() then result:=false;
  if not OgfMotionTracksContainerTest() then result:=false;
  if not OgfMotionParamsContainerTest() then result:=false;
  if not OgfMotionsMmarksCopyTest() then  result:=false;
  if not OgfMotionsParserTest() then  result:=false;

end;

end.


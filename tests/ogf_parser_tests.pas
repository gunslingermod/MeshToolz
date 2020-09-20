unit ogf_parser_tests;

{$mode objfpc}{$H+}

interface

function VertexContainerTest():boolean;
function TextureContainerTest():boolean;
function OgfChildRebuildTest():boolean;

function RunAllTests():boolean;

implementation
uses ChunkedFileParser, ogf_parser, basedefs, sysutils;

const
  TEST_OGF_IN_NAME:string='test_data\test_in.ogf';
  TEST_OGF_OUT_NAME:string='test_data\test_out.ogf';


procedure PrintTestResult(test_name:string; result:boolean);
var
  res_str:string;
begin
  if result then res_str:='passed' else res_str:='FAILED';
  writeln('[RESULT] Test "'+test_name+'" is '+res_str);
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

function RunAllTests():boolean;
begin
  result:=true;
  if not VertexContainerTest() then result:=false;
  if not TextureContainerTest() then result:=false;
  if not OgfChildRebuildTest() then result:=false;
end;

end.


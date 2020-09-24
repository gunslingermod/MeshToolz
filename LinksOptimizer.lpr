program LinksOptimizer;

uses ogf_parser, ChunkedFileParser, sysutils;


procedure SimplifyVertexLinks(fname:string; fname_out:string);
var
  f:TChunkedMemory;
  child:TOgfChild;
  child_id, newlink:cardinal;
  data:string;
  need_update_data:boolean;
begin
  f:=TChunkedMemory.Create();
  child:=TOgfChild.Create;

  try
    if not f.LoadFromFile(fname, 0) then exit;
    child_id:=0;

    while f.NavigateToChunk('9:'+inttostr(child_id)) do begin
      data:=f.GetCurrentChunkRawDataAsString();
      need_update_data:=false;
      if not child.Deserialize(data) then exit;
      newlink:=child.CalculateOptimalLinkType();
      writeln(child.GetTextureData().texture+' ('+child.GetTextureData().shader+') : '+inttostr(child.GetCurrentLinkType())+' -> ' + inttostr(newlink));
      if (newlink=OGF_LINK_TYPE_INVALID) or  (newlink<>child.GetCurrentLinkType()) then begin
        need_update_data:=child.ChangeLinkType(newlink)
      end;

      if need_update_data then begin
        data:=child.Serialize();
        f.ReplaceCurrentRawDataWithString(data);
      end;

      child_id:=child_id+1;
      f.ResetSelectedSubChunk();
    end;
    f.SaveToFile(fname_out);
  finally
    child.Free;
    f.Free;
  end;

end;

begin
  if ParamCount>0 then begin;
    SimplifyVertexLinks(ParamStr(1), ParamStr(1));
    writeln('Done!');
    readln();
  end;
end.


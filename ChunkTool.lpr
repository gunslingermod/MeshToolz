program ChunkTool;

uses
  sysutils,
  ChunkedFileParser;

procedure Log(text:string; iserror:boolean);
begin
  if iserror then text:='[ERROR] '+text;
  writeln(text);
end;

function SaveToFile(raw_data:string; var f:file):boolean;
begin
  result:=false;
  try
    rewrite(f, 1);
    BlockWrite(f, PAnsiChar(raw_data)[0], length(raw_data));
    closefile(f);
    result:=true;
  except
    result:=false;
  end;
end;

function ReadFromFile(var raw_data:string; var f:file):boolean;
var
  sz:int64;
  i:integer;
  arr:array of byte;
begin
  result:=false;
  try
    reset(f, 1);
    try
      sz:=FileSize(f);
      if sz = 0 then exit;
      setlength(arr, sz);
      BlockRead(f, arr[0], sz);
      for i:=0 to length(arr)-1 do begin
        raw_data:=raw_data+chr(arr[i]);
      end;
      result:=true;
    finally
      setlength(arr,0);
      closefile(f);
    end;
  except
    result:=false;
  end;
end;

procedure Main();
var
  f:TChunkedMemory;
  f_buf:file;
  action, chunked_file, chain, buffer_file:string;

  raw_data:string;
begin
  if ParamCount < 4 then begin
    Log('Usage:', false);
    Log('ChunkTool <action> <chunked_file> <chain> <buffer_file>', false);
    exit;
  end;

  action:=ParamStr(1);
  chunked_file:=ParamStr(2);
  chain:=ParamStr(3);
  buffer_file:=ParamStr(4);
  assignfile(f_buf, buffer_file);

  f:=TChunkedMemory.Create();
  try
    if not f.LoadFromFile(chunked_file, 0) then begin
      Log('Can''t read from file '+chunked_file, true);
      exit;
    end;

    if not f.NavigateToChunk(chain) then begin
      Log('Can''t navigate to chunk '+chain, true);
      exit;
    end;

    if action = 'dump' then begin
      raw_data:=f.GetCurrentChunkRawDataAsString();
      if not SaveToFile(raw_data, f_buf) then begin
        Log('Can''t save to dump file '+buffer_file, true);
        exit;
      end;

    end else if action = 'rewrite' then begin
      if not ReadFromFile(raw_data, f_buf) then begin
        Log('Can''t read from file '+buffer_file, true);
        exit;
      end;
      if not f.ReplaceCurrentRawDataWithString(raw_data) then begin
        Log('Can''t replace selected chunk data', true);
        exit;
      end;
      if not f.SaveToFile(chunked_file) then begin
        Log('Can''t update file '+chunked_file, true);
        exit;
      end;

    end else if action = 'append' then begin
      if not ReadFromFile(raw_data, f_buf) then begin
        Log('Can''t read from file '+buffer_file, true);
        exit;
      end;
      raw_data:=f.GetCurrentChunkRawDataAsString()+raw_data;
      if not f.ReplaceCurrentRawDataWithString(raw_data) then begin
        Log('Can''t replace selected chunk data', true);
        exit;
      end;
      if not f.SaveToFile(chunked_file) then begin
        Log('Can''t update file '+chunked_file, true);
        exit;
      end;

    end else if action = 'reindex' then begin
      if not f.ChangeIdOfCurrentChunk(strtoint(ParamStr(4))) then begin
        Log('Can''t change index', true);
        exit;
      end;
      if not f.SaveToFile(chunked_file) then begin
        Log('Can''t update file '+chunked_file, true);
        exit;
      end;

    end else if action = 'remove' then begin
      if buffer_file = 'true' then begin
        if not f.RemoveCurrentChunk() then begin
          Log('Can''t remove', true);
          exit;
        end;
        if not f.SaveToFile(chunked_file) then begin
          Log('Can''t update file '+chunked_file, true);
          exit;
        end;
      end else begin
          Log('Please confirm removing by entering "true" as 4th parameter', true);
          exit;
      end;
    end else begin
      Log('Unknown action '+action, true);
    end;

  finally
    FreeAndNil(f);
  end;
end;

begin
  Main();
end.


unit ChunkedFileParser;

{$mode objfpc}{$H+}

interface
type
  TChunkedOffset = cardinal;
  TChunkId = word;

  { TChunkedMemory }
  TChunkedMemory = class
    _loaded:boolean;
    _data:array of byte;
    _parent_chunks:array of TChunkedOffset; // цепочка родительских чанков (как смещения от начала области) до текущего

    procedure _Reset();
    function _RemainsCount(offset:TChunkedOffset):cardinal;
    function _GetCurPos():TChunkedOffset;
  public
    constructor Create();
    destructor Destroy(); override;
    function LoadFromFile(path:string; non_chunked_header_size:cardinal):boolean;
    function SaveToFile(path:string):boolean;
    function FindSubChunk(id:TChunkId):TChunkedOffset;
    function EnterSubChunk(offset:TChunkedOffset):boolean;
    function LeaveSubChunk():boolean;
    function GetCurrentChunkRawDataAsString():string;
    function ReplaceCurrentRawDataWithString(new_data:string):boolean;

    function NavigateToChunk(chain:string):boolean;
    function ChangeIdOfCurrentChunk(new_id:TChunkId):boolean;
    function RemoveCurrentChunk():boolean;
  end;

  TChunkHeader = packed record
    id:TChunkId;
    flags:word;
    sz:cardinal;
  end;
  pTChunkHeader = ^TChunkHeader;

const
  INVALID_CHUNK:TChunkedOffset=$FFFFFFFF;

implementation
uses SysUtils;

{ TChunkedMemory }

procedure TChunkedMemory._Reset();
begin
  setlength(_data, 0);
  setlength(_parent_chunks, 0);
  _loaded:=false;
end;

function TChunkedMemory._RemainsCount(offset: TChunkedOffset): cardinal;
var
  start, sz:cardinal;
  hdr:pTChunkHeader;
begin
  result:=0;
  if not _loaded then exit;

  start:=0;
  sz:=length(_data);

  if length(_parent_chunks) > 0 then begin
    start:=_parent_chunks[length(_parent_chunks)-1]+sizeof(TChunkHeader);
    if offset < start then exit;
    offset:=offset-start;
    hdr:=@_data[_parent_chunks[length(_parent_chunks)-1]];
    sz:=hdr^.sz;
  end;

  if (offset >= sz) then exit;
  result:=sz-offset;
end;

function TChunkedMemory._GetCurPos(): TChunkedOffset;
begin
  result:=0;
  if not _loaded then exit;

  if length(_parent_chunks) > 0 then begin
    result:=_parent_chunks[length(_parent_chunks)-1]+sizeof(TChunkHeader);
  end;
end;

constructor TChunkedMemory.Create();
begin
  _Reset();
end;

destructor TChunkedMemory.Destroy();
begin
  _Reset();
  inherited Destroy();
end;

function TChunkedMemory.LoadFromFile(path: string; non_chunked_header_size: cardinal): boolean;
var
  f:THandle;
  sz:int64;
begin
  result:=false;
  _Reset();
  f:=FileOpen(path, fmOpenRead);
  if f = THandle(-1) then exit;
  try
    sz:=FileSeek(f, 0, 2);
    if (sz<$ffffffff) and (sz >= int64(non_chunked_header_size)+sizeof(TChunkHeader)) then begin
      FileSeek(f, non_chunked_header_size, 0);
      setlength(_data, sz - non_chunked_header_size);
      FileRead(f, _data[0], length(_data));
      _loaded:=true;
      result:=true;
    end;
  finally
    FileClose(f);
  end;
end;

function TChunkedMemory.SaveToFile(path: string): boolean;
var
  f:THandle;
begin
  result:=false;
  f:=FileCreate(path);
  if f = THandle(-1) then exit;
  try
    FileWrite(f, _data[0], length(_data));
    result:=true;
  finally
    FileClose(f);
  end;
end;

function TChunkedMemory.FindSubChunk(id: TChunkId): TChunkedOffset;
var
  curpos:TChunkedOffset;
  tmp_pos:integer;
  data_sz:cardinal;
  hdr:pTChunkHeader;
begin
  result:=INVALID_CHUNK;
  if not _loaded then exit;

  curpos:=_GetCurPos();
  if (_RemainsCount(curpos) < sizeof(TChunkHeader)) then exit;

  hdr:=@_data[curpos];
  data_sz:=length(_data);
  while(hdr^.id <> id) do begin
    tmp_pos:=curpos+sizeof(TChunkHeader)+hdr^.sz;
    if (tmp_pos >= data_sz - sizeof(TChunkHeader)) then exit;
    curpos:=cardinal(tmp_pos);
    hdr:=@_data[curpos];
  end;

  if hdr^.sz > _RemainsCount(curpos) then exit;
  result:=curpos;
end;

function TChunkedMemory.EnterSubChunk(offset: TChunkedOffset): boolean;
var
  hdr:pTChunkHeader;
  curpos:TChunkedOffset;
begin
  result:=false;
  if _RemainsCount(offset) < sizeof(TChunkHeader) then exit;

  curpos:=_GetCurPos();
  if curpos+sizeof(TChunkHeader) >= cardinal(length(_data)) then exit;

  hdr:=@_data[offset];
  if hdr^.sz > _RemainsCount(offset) then exit;
  setlength(_parent_chunks, length(_parent_chunks)+1);
  _parent_chunks[length(_parent_chunks)-1]:=offset;

  result:=true;
end;

function TChunkedMemory.LeaveSubChunk(): boolean;
begin
  result:=false;
  if length(_parent_chunks) > 0 then begin
    setlength(_parent_chunks, length(_parent_chunks)-1);
    result:=true;
  end;
end;

function TChunkedMemory.GetCurrentChunkRawDataAsString(): string;
var
  i:cardinal;
  cur_ofs:TChunkedOffset;
begin
  result:='';
  if not _loaded then exit;
  cur_ofs:=_GetCurPos();

  for i:=1 to _RemainsCount(cur_ofs) do begin
    result:=result+char(_data[cur_ofs+i-1]);
  end;
end;

function TChunkedMemory.ReplaceCurrentRawDataWithString(new_data: string): boolean;
var
  old_data:string;
  new_buf:array of byte;
  delta, i:integer;
  cur_ofs:TChunkedOffset;
  hdr:pTChunkHeader;
begin
  result:=false;
  if not _loaded then exit;
  cur_ofs:=_GetCurPos();

  old_data:=GetCurrentChunkRawDataAsString();
  delta:=length(new_data)-length(old_data);

  setlength(new_buf, length(_data)+delta);
  Move(_data[0], new_buf[0], cur_ofs);
  Move(PAnsiChar(new_data)[0], new_buf[cur_ofs], length(new_data));
  Move(_data[cur_ofs+cardinal(length(old_data))], new_buf[cur_ofs+cardinal(length(new_data))], length(_data)-cur_ofs-cardinal(length(old_data)));

  setlength(_data, length(new_buf));
  Move(new_buf[0], _data[0], length(new_buf));

  setlength(new_buf, 0);

  if length(_parent_chunks) > 0 then begin
    for i:=0 to length(_parent_chunks) - 1 do begin
      hdr:=@_data[_parent_chunks[i]];
      hdr^.sz:=int64(hdr^.sz)+delta;
    end;
  end;
  result:=true;
end;


function GetNextSubStr(var data:string; var buf:string; separator:char=char($00)):boolean;
var p, i:integer;
begin
  p:=0;
  for i:=1 to length(data) do begin
    if data[i]=separator then begin
      p:=i;
      break;
    end;
  end;

  if p>0 then begin
    buf:=leftstr(data, p-1);
    buf:=trim(buf);
    data:=rightstr(data, length(data)-p);
    data:=trim(data);
    result:=true;
  end else begin
    if trim(data)<>'' then begin
      buf:=trim(data);
      data:='';
      result:=true;
    end else result:=false;
  end;
end;

function TChunkedMemory.NavigateToChunk(chain: string): boolean;
var
  chunk_id_str:string;
  i:integer;
  ofs:TChunkedOffset;
begin
  result:=false;
  if not _loaded then exit;

  chunk_id_str:='';
  while GetNextSubStr(chain, chunk_id_str, ':') do begin
    ofs:=INVALID_CHUNK;
    if chunk_id_str[1] ='o' then begin
      chunk_id_str:=rightstr(chunk_id_str, length(chunk_id_str)-1);
      i:=strtointdef(chunk_id_str, -1);
      if i>=0 then begin
        ofs:=_GetCurPos();
        ofs:=ofs+cardinal(i);
      end;
    end else begin
      i:=strtointdef(chunk_id_str, -1);
      if (i>=0) and (i < $FFFF) then begin
        ofs:=FindSubChunk(i);
      end;
    end;

    if ofs = INVALID_CHUNK then exit;
    if not EnterSubChunk(ofs) then exit;
  end;
  result:=true;
end;

function TChunkedMemory.ChangeIdOfCurrentChunk(new_id: TChunkId): boolean;
var
  hdr:pTChunkHeader;
begin
  result:=false;
  if not _loaded then exit;
  if length(_parent_chunks) = 0 then exit;
  hdr:=@_data[_parent_chunks[length(_parent_chunks)-1]];
  hdr^.id:=new_id;
  result:=true;
end;

function TChunkedMemory.RemoveCurrentChunk(): boolean;
var
  old_data:string;
  new_buf:array of byte;
  delta, i:integer;
  cur_ofs:TChunkedOffset;
  hdr:pTChunkHeader;
begin
  result:=false;
  if not _loaded then exit;
  if length(_parent_chunks) = 0 then exit;

  cur_ofs:=_GetCurPos();

  old_data:=GetCurrentChunkRawDataAsString();
  delta:=-length(old_data)-sizeof(TChunkHeader);

  setlength(new_buf, length(_data)+delta);
  Move(_data[0], new_buf[0], cur_ofs);
  Move(_data[cur_ofs+cardinal(length(old_data))], new_buf[cur_ofs-cardinal(sizeof(TChunkHeader))], length(_data)-cur_ofs-cardinal(length(old_data)));

  setlength(_data, length(new_buf));
  Move(new_buf[0], _data[0], length(new_buf));
  setlength(new_buf, 0);

  setlength(_parent_chunks, length(_parent_chunks)-1);

  if length(_parent_chunks) > 0 then begin
    for i:=0 to length(_parent_chunks) - 1 do begin
      hdr:=@_data[_parent_chunks[i]];
      hdr^.sz:=int64(hdr^.sz)+delta;
    end;
  end;
  result:=true;
end;

end.


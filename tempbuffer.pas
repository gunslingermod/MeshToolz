unit TempBuffer;

{$mode objfpc}{$H+}

interface

type
TTempBufferType = (TTempTypeNone, TTempTypeString);

{ TTempBuffer }

TTempBuffer = class
  _cur_type:TTempBufferType;
  _buffer_string:string;
public
  constructor Create;
  destructor Destroy; override;

  procedure Clear();
  function GetCurrentType():TTempBufferType;
  function GetString(var outstr:string):boolean;
  procedure SetString(s:string);
end;

implementation

{ TTempBuffer }

constructor TTempBuffer.Create;
begin
  Clear();
end;

destructor TTempBuffer.Destroy;
begin
  inherited Destroy;
end;

procedure TTempBuffer.Clear();
begin
  _cur_type:=TTempTypeNone;
end;

function TTempBuffer.GetCurrentType(): TTempBufferType;
begin
  result:=_cur_type;
end;

function TTempBuffer.GetString(var outstr: string): boolean;
begin
  if _cur_type = TTempTypeString then begin
    result:=true;
    outstr:=_buffer_string;
  end else begin
    result:=false;
  end;
end;

procedure TTempBuffer.SetString(s: string);
begin
  _cur_type:=TTempTypeString;
  _buffer_string:=s;
end;

end.


unit TempBuffer;

{$mode objfpc}{$H+}

interface

const
  BUFFER_TYPE_NONE = 0;
  BUFFER_TYPE_ANY = -1;
  BUFFER_TYPE_STRING = 1;

type
{ TTempBuffer }

TTempBuffer = class
  _cur_type:integer;
  _buffer_string:string;
  _clipboard_mode:boolean;
public
  constructor Create;
  destructor Destroy; override;

  procedure Clear();
  function GetCurrentType():integer;
  function GetData(var outstr:string; expected_type:integer = BUFFER_TYPE_ANY):boolean;
  procedure SetData(s:string; datatype:integer=BUFFER_TYPE_STRING);
  procedure SwitchClipboardMode(en:boolean);
end;

implementation
uses Clipbrd;

{ TTempBuffer }

constructor TTempBuffer.Create;
begin
  Clear();
  _clipboard_mode:=false;
end;

destructor TTempBuffer.Destroy;
begin
  inherited Destroy;
end;

procedure TTempBuffer.Clear();
begin
  _cur_type:=BUFFER_TYPE_NONE;
  _buffer_string:='';
end;

function TTempBuffer.GetCurrentType(): integer;
begin
  result:=_cur_type;
end;

function TTempBuffer.GetData(var outstr: string; expected_type: integer): boolean;
begin
  if _clipboard_mode then begin
     result:=true;
     outstr:=Clipboard.AsText;
  end else if (expected_type = BUFFER_TYPE_ANY) or (_cur_type = expected_type) then begin
    result:=true;
    outstr:=_buffer_string;
  end else begin
    result:=false;
  end;
end;

procedure TTempBuffer.SetData(s: string; datatype: integer);
begin
  if _clipboard_mode then begin
    Clipboard.AsText:=s;
  end else begin
    _cur_type:=datatype;
    _buffer_string:=s;
  end;
end;

procedure TTempBuffer.SwitchClipboardMode(en: boolean);
begin
  if en <> _clipboard_mode then begin
    Clear;
    _clipboard_mode:=en;
  end;
end;

end.


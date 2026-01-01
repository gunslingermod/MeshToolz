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
uses Clipbrd, sysutils, strutils;

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

function stringtobytehex(s:string):string;
var
  i:integer;
  b:byte;
begin
  result:='';
  for i:=1 to length(s) do begin
    b:=byte(s[i]);
    result:=result+inttohex(b,2);
  end;
end;

function bytehextostring(s:string; var outstr:string):boolean;
var
  c:char;
  b:byte;
  nibble:byte;
  i:integer;
  r:string;
begin
  if length(s) mod 2 <>0 then begin
    result:=false;
    exit;
  end;

  result:=true;
  r:='';
  b:=0;

  for i:=1 to length(s) do begin
    c:=s[i];
    case c of
      '0':nibble:=0;
      '1':nibble:=1;
      '2':nibble:=2;
      '3':nibble:=3;
      '4':nibble:=4;
      '5':nibble:=5;
      '6':nibble:=6;
      '7':nibble:=7;
      '8':nibble:=8;
      '9':nibble:=9;
      'a','A':nibble:=10;
      'b','B':nibble:=11;
      'c','C':nibble:=12;
      'd','D':nibble:=13;
      'e','E':nibble:=14;
      'f','F':nibble:=15;
    else
      begin
        result:=false;
        break;
      end;
    end;

    if i mod 2 = 0 then begin
      b:=b or nibble;
      r:=r+chr(b);
    end else begin
      b:=nibble shl 4;
    end;
  end;

  if result then begin
    outstr:=r;
  end;
end;

function TTempBuffer.GetData(var outstr: string; expected_type: integer): boolean;
var
  s:string;
begin
  if _clipboard_mode then begin
     result:=bytehextostring(Clipboard.AsText, s);
     if result then begin
       outstr:=s;
     end;
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
    Clipboard.AsText:=stringtobytehex(s);
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


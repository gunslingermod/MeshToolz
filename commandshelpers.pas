unit CommandsHelpers;

{$mode objfpc}{$H+}

interface
uses basedefs;

function IsNumberChar(chr:AnsiChar):boolean;
function IsAlphabeticChar(chr:AnsiChar):boolean;
function ExtractAlphabeticString(var inoutstr:string):string;
function ExtractProcArgs(instr:string; var args:string):boolean;
function ExtractNumericString(var inoutstr:string; allow_negative:boolean):string;
function ExtractFloatFromString(var inoutstr:string; var fout:single):boolean;
function ExtractABNString(var inoutstr:string):string;
function SplitString(instr:string; var out_left:string; var out_right:string; sep:char):boolean;
function ExtractFVector3(var inoutstr:string; var v:FVector3):boolean;

type
TIndexFilter = packed record
  name:string;
  value:string;
  inverse:boolean;
end;

TFilterMode = (FILTER_MODE_EXACT, FILTER_MODE_BEGINWITH);
TIndexFilters = array of TIndexFilter;


TCommandsArgumentsParserArgType = (
  TCommandsArgumentsParserArgAnyString,
  TCommandsArgumentsParserArgABNString,
  TCommandsArgumentsParserArgNumericString,
  TCommandsArgumentsParserArgInteger,
  TCommandsArgumentsParserArgSingle,
  TCommandsArgumentsParserArgBool
);

TCommandArgumentParams = record
  argtype: TCommandsArgumentsParserArgType;
  is_optional:boolean;
  description:string;
end;

TCommandArgumentParseResult = record
  rawstr:string;
  asinteger:integer;
  assingle:single;
  asbool:boolean;

  present:boolean;
end;

{ TCommandsArgumentsParser }

TCommandsArgumentsParser = class
  _params:array of TCommandArgumentParams;
  _results:array of TCommandArgumentParseResult;
  _lasterror:string;
public
  constructor Create();
  destructor Destroy(); override;

  function RegisterArgument(argtype: TCommandsArgumentsParserArgType; is_optional:boolean; description:string=''):integer;
  function Parse(args:string):boolean;
  function Get(idx:integer; ignore_errors:boolean):TCommandArgumentParseResult;
  function GetAsInt(idx:integer; var output:integer; default_for_optionals:integer=0):boolean;
  function GetAsSingle(idx:integer; var output:single; default_for_optionals:single=0):boolean;
  function GetAsString(idx:integer; var output:string; default_for_optionals:string=''):boolean;
  function GetAsBool(idx:integer; var output:Boolean; default_for_optionals:boolean=false):boolean;
  function GetLastErr():string;
end;

procedure InitFilters(var f:TIndexFilters);
procedure PushFilter(var f:TIndexFilters; name:string; defval:string='');
function IsMatchFilter(str:string; filter:TIndexFilter; mode:TFilterMode):boolean;
procedure ClearFilters(var f:TIndexFilters);
function ExtractIndexFilter(var inoutstr:string; var filters:TIndexFilters; var filters_count:integer):boolean;


const
   COMMANDS_ARGUMENTS_SEPARATOR:char=',';
   COMMANDS_ARGUMENT_INVERSE:char='!';


implementation
uses sysutils, strutils;


function IsNumberChar(chr:AnsiChar):boolean;
begin
  result:= (chr >= '0') and (chr <= '9');
end;

function IsAlphabeticChar(chr:AnsiChar):boolean;
begin
  result:= ((chr >= 'a') and (chr <= 'z')) or ((chr >= 'A') and (chr <= 'Z'));
end;

function ExtractAlphabeticString(var inoutstr:string):string;
begin
  inoutstr:=TrimLeft(inoutstr);
  result:='';
  while (length(inoutstr) > 0) and (IsAlphabeticChar(inoutstr[1])) do begin
    result:=result+inoutstr[1];
    inoutstr:=rightstr(inoutstr, length(inoutstr)-1);
  end;
end;

function ExtractProcArgs(instr:string; var args:string):boolean;
begin
  result:=false;
  instr:=trim(instr);
  if (length(instr)<2) or (instr[1]<>'(') or (instr[length(instr)]<>')') then exit;

  args:=midstr(instr, 2, length(instr)-2);
  result:=true;
end;

function ExtractNumericString(var inoutstr:string; allow_negative:boolean):string;
begin
  inoutstr:=TrimLeft(inoutstr);
  result:='';

  if allow_negative and (length(inoutstr) > 0) and (inoutstr[1]='-') then begin
    result:=result+'-';
    inoutstr:=rightstr(inoutstr, length(inoutstr)-1);
  end;

  while (length(inoutstr) > 0) and (IsNumberChar(inoutstr[1])) do begin
    result:=result+inoutstr[1];
    inoutstr:=rightstr(inoutstr, length(inoutstr)-1);
  end;
end;

function ExtractFloatFromString(var inoutstr:string; var fout:single):boolean;
var
  separator_found:boolean;
  tmpstr, numstr:string;
  sign:single;
const
  SEPARATOR:char='.';
begin
  result:=false;
  tmpstr:=TrimLeft(inoutstr);
  if length(tmpstr) = 0 then exit;

  if tmpstr[1]='-' then begin
    sign:=-1;
    tmpstr:=TrimLeft(rightstr(tmpstr, length(tmpstr)-1));
    if length(tmpstr) = 0 then exit;
  end else begin
    sign:=1;
  end;
  if length(tmpstr) = 0 then exit;

  separator_found:=false;
  numstr:='';
  while (length(tmpstr) > 0) and (IsNumberChar(tmpstr[1]) or ((tmpstr[1] = SEPARATOR) and (separator_found = false)) ) do begin
    if (tmpstr[1] = SEPARATOR) then begin
      separator_found:=true;
    end;
    numstr:=numstr+tmpstr[1];
    tmpstr:=rightstr(tmpstr, length(tmpstr)-1);
  end;

  try
    fout:=sign*strtofloat(numstr);
    inoutstr:=tmpstr;
    result:=true;
  except
    result:=false;
  end;
end;

function ExtractABNString(var inoutstr:string):string;
begin
  inoutstr:=TrimLeft(inoutstr);
  result:='';
  while (length(inoutstr) > 0) and (IsAlphabeticChar(inoutstr[1]) or IsNumberChar(inoutstr[1]) or (inoutstr[1]='_')) do begin
    result:=result+inoutstr[1];
    inoutstr:=rightstr(inoutstr, length(inoutstr)-1);
  end;
end;

function SplitString(instr:string; var out_left:string; var out_right:string; sep:char):boolean;
var
  i:integer;
begin
  result:=false;
  i:=Pos(sep, instr);
  if i > 0 then begin
    result:=true;
    out_left:=leftstr(instr, i-1);
    out_right:=rightstr(instr, length(instr)-i);
  end;
end;

function ExtractFVector3(var inoutstr:string; var v:FVector3):boolean;
var
  tmpstr:string;
  tmpv:FVector3;
begin
  result:=false;
  set_zero(tmpv{%H-});
  tmpstr:=trimleft(inoutstr);

  if not ExtractFloatFromString(tmpstr, tmpv.x) then exit;
  tmpstr:=trimleft(tmpstr);
  if (length(tmpstr)=0) or (tmpstr[1]<>COMMANDS_ARGUMENTS_SEPARATOR) then exit;
  tmpstr:=rightstr(tmpstr, length(tmpstr)-1);

  if not ExtractFloatFromString(tmpstr, tmpv.y) then exit;
  tmpstr:=trimleft(tmpstr);
  if (length(tmpstr)=0) or (tmpstr[1]<>COMMANDS_ARGUMENTS_SEPARATOR) then exit;
  tmpstr:=rightstr(tmpstr, length(tmpstr)-1);

  if not ExtractFloatFromString(tmpstr, tmpv.z) then exit;

  inoutstr:=tmpstr;
  v:=tmpv;
  result:=true;
end;

procedure InitFilters(var f:TIndexFilters);
begin
  setlength(f, 0);
end;

procedure PushFilter(var f:TIndexFilters; name:string; defval:string='');
var
  l:integer;
begin
  l:=length(f);
  setlength(f, l+1);
  f[l].name:=name;
  f[l].value:=defval;
end;

function IsMatchFilter(str:string; filter:TIndexFilter; mode:TFilterMode):boolean;
var
  val:string;
begin
  result:=false;
  val:=filter.value;
  if (length(val)>0) and (val[length(val)]='*') then begin
    val:=leftstr(val, length(val)-1);
    mode:=FILTER_MODE_BEGINWITH;
  end;

  case mode of
    FILTER_MODE_EXACT: result:=(length(val)=0) or (str = val);
    FILTER_MODE_BEGINWITH: result:=(length(val)=0) or (leftstr(str, length(val)) = val);
  end;
  if filter.inverse then result:=not result;
end;

procedure ClearFilters(var f:TIndexFilters);
begin
  setlength(f, 0);
end;

function ExtractIndexFilter(var inoutstr:string; var filters:TIndexFilters; var filters_count:integer):boolean;
var
  filters_str:string;
  rest_part:string;
  filter_name, filter_value:string;
  tmp, i:integer;
  inverse:boolean;
begin
  result:=false;
  inoutstr:=trim(inoutstr);
  filters_str:='';
  rest_part:='';
  if (length(inoutstr) < 2) or (inoutstr[1]<>'[') or not SplitString(inoutstr, filters_str, rest_part, ']') then exit;
  result:=true;
  inoutstr:=rest_part;
  filters_count:=0;
  filters_str:=trimleft(rightstr(filters_str, length(filters_str)-1));
  while (filters_count>=0) and (length(filters_str)>0) do begin
    tmp:=filters_count;
    filters_count:=-1;

    // Extract filter name
    filters_str:=TrimLeft(filters_str);
    filter_name:=ExtractABNString(filters_str);
    filters_str:=TrimLeft(filters_str);
    if (length(filter_name) = 0) or (length(filters_str)=0) or ((filters_str[1]<>':') and (filters_str[1]<>COMMANDS_ARGUMENT_INVERSE)) then break;

    inverse:=(filters_str[1]=COMMANDS_ARGUMENT_INVERSE);

    // Get rid of ':'
    filters_str:=trimleft(rightstr(filters_str, length(filters_str)-1));
    if (length(filters_str) = 0) then break;

    // Extract filter value
    filter_value:='';
    if not SplitString(filters_str, filter_value, rest_part, ',') then begin
      filter_value:=filters_str;
      filters_str:='';
    end else begin
      filters_str:=trimleft(rest_part);
    end;

    // Find filter by extracted name and set extracted value to filter
    for i:=0 to length(filters)-1 do begin
      if filters[i].name = filter_name then begin
        filters[i].value:=filter_value;
        filters[i].inverse:=inverse;
        filter_name:='';
        filter_value:='';
      end;
    end;

    if length(filter_name) = 0 then begin
      // All seems to be OK
      filters_count:=tmp+1;
    end else begin
      // Filter not found, exiting
      filters_count:=-1;
      break;
    end;
  end;
end;

{ TCommandsArgumentsParser }

constructor TCommandsArgumentsParser.Create();
begin
  setlength(_params, 0);
  setlength(_results, 0);
  _lasterror:='';
end;

destructor TCommandsArgumentsParser.Destroy();
begin
  setlength(_params, 0);
  setlength(_results, 0);
  inherited Destroy();
end;

function TCommandsArgumentsParser.RegisterArgument(
  argtype: TCommandsArgumentsParserArgType; is_optional: boolean;
  description: string): integer;
var
  i:integer;
begin
  result:=-1;

  i:=length(_params);
  if not is_optional and (i > 0) and _params[i-1].is_optional then begin
    exit;
  end;


  setlength(_params, length(_params)+1);
  _params[i].is_optional:=is_optional;
  _params[i].argtype:=argtype;
  _params[i].description:=description;
end;

function TCommandsArgumentsParser.Parse(args: string): boolean;
var
  i, j:integer;
  cmdstr:string;
  argval:string;
begin
  result:=false;
  _lasterror:='';
  setlength(_results, length(_params));
  for i:=0 to length(_results)-1 do begin
    _results[i].present:=false;
  end;

  cmdstr:=trim(args);

  i:=0;
  while i < length(_params) do begin
    if i = length(_params)-1 then begin
      if length(cmdstr)>0 then begin
        _results[i].rawstr:=trim(cmdstr);
        _results[i].present:=true;
        cmdstr:='';
        i:=i+1;
      end;

    end else if not SplitString(cmdstr, argval, cmdstr, COMMANDS_ARGUMENTS_SEPARATOR) then begin
      if length(args)>0 then begin
        _results[i].rawstr:=trim(cmdstr);
        _results[i].present:=true;
        i:=i+1;
      end;
      break;

    end else begin
      _results[i].rawstr:=trim(argval);
      _results[i].present:=true;
    end;
    cmdstr:=trim(cmdstr);
    i:=i+1;
  end;

  if i < length(_params) then begin
    // some args not parsed, i - index if the 1st non-parsed arg
    if not _params[i].is_optional then begin
      _lasterror:='can''t extract mandatory argument #'+inttostr(i+1);
      if length (_params[i].description) > 0 then begin
        _lasterror:=_lasterror+' ('+_params[i].description+')';
      end;
      exit;
    end;
  end;

  i:=0;
  while (i < length(_results)) and (_results[i].present) do begin
    if not _params[i].is_optional and (length(_results[i].rawstr) = 0) then begin
      _lasterror:='mandatory argument #'+inttostr(i+1);
      if length (_params[i].description) > 0 then begin
        _lasterror:=_lasterror+' ('+_params[i].description+')';
      end;
      _lasterror:=_lasterror+' can''t be empty';
      exit;
    end;

    case _params[i].argtype of
      TCommandsArgumentsParserArgABNString: begin
        for j:=1 to length(_results[i].rawstr) do begin
          if not (IsAlphabeticChar(_results[i].rawstr[j]) or IsNumberChar(_results[i].rawstr[j]) or (_results[i].rawstr[j]='_')) then begin
            _lasterror:='';
            if _params[i].is_optional then begin
              _lasterror:=_lasterror+'optional ';
            end;
           _lasterror:=_lasterror+'argument #'+inttostr(i+1);
             if length (_params[i].description) > 0 then begin
               _lasterror:=_lasterror+' ('+_params[i].description+')';
             end;
             _lasterror:=_lasterror+' should be a string created from alphabetic or numeric chars only';
            exit;
          end;
        end;
      end;

      TCommandsArgumentsParserArgNumericString: begin
        for j:=1 to length(_results[i].rawstr) do begin
          if not IsNumberChar(_results[i].rawstr[j]) then begin
            _lasterror:='';
            if _params[i].is_optional then begin
              _lasterror:=_lasterror+'optional ';
            end;
           _lasterror:=_lasterror+'argument #'+inttostr(i+1);
             if length (_params[i].description) > 0 then begin
               _lasterror:=_lasterror+' ('+_params[i].description+')';
             end;
             _lasterror:=_lasterror+' should contain digits only';
            exit;
          end;
        end;
      end;

      TCommandsArgumentsParserArgInteger:begin
        try
          _results[i].asinteger:=strtoint(_results[i].rawstr);
        except
           _lasterror:='';
           if _params[i].is_optional then begin
             _lasterror:=_lasterror+'optional ';
           end;
          _lasterror:=_lasterror+'argument #'+inttostr(i+1);
           if length (_params[i].description) > 0 then begin
             _lasterror:=_lasterror+' ('+_params[i].description+')';
           end;
           _lasterror:=_lasterror+' should be a valid integer number';
           exit;
        end;
      end;

      TCommandsArgumentsParserArgSingle:begin
        try
          _results[i].assingle:=StrToFloat(_results[i].rawstr);
        except
           _lasterror:='';
           if _params[i].is_optional then begin
             _lasterror:=_lasterror+'optional ';
           end;
          _lasterror:=_lasterror+'argument #'+inttostr(i+1);
           if length (_params[i].description) > 0 then begin
             _lasterror:=_lasterror+' ('+_params[i].description+')';
           end;
           _lasterror:=_lasterror+' should be a valid floating-point value';
           exit;
        end;
      end;

      TCommandsArgumentsParserArgBool:begin
        if (lowercase(_results[i].rawstr)='true') or (_results[i].rawstr='1') then begin
          _results[i].asbool:=true;
        end else if (lowercase(_results[i].rawstr)='false') or (_results[i].rawstr='0') then begin
          _results[i].asbool:=false;
        end else begin
          _lasterror:='';
          if _params[i].is_optional then begin
            _lasterror:=_lasterror+'optional ';
          end;
         _lasterror:=_lasterror+'argument #'+inttostr(i+1);
           if length (_params[i].description) > 0 then begin
             _lasterror:=_lasterror+' ('+_params[i].description+')';
           end;
           _lasterror:=_lasterror+' should be a valid boolean value';
           exit;
        end;
      end;
    end;
    i:=i+1;
  end;

  result:=true;
end;

function TCommandsArgumentsParser.Get(idx: integer; ignore_errors: boolean): TCommandArgumentParseResult;
begin
  if (not ignore_errors and (length(_lasterror)>0)) or (idx < 0) or (idx >= length(_results)) then begin
    result.present:=false;
  end else begin
    result:=_results[idx];
  end;
end;

function TCommandsArgumentsParser.GetAsInt(idx: integer; var output: integer; default_for_optionals: integer): boolean;
var
  r:TCommandArgumentParseResult;
begin
  result:=false;
  if length(_lasterror)>0 then exit;
  r:=Get(idx, true);
  if not r.present then begin
    if _params[idx].is_optional then begin
      result:=true;
      output:=default_for_optionals;
    end else begin
      exit;
    end;
  end else if _params[idx].argtype = TCommandsArgumentsParserArgInteger then begin;
     output:=r.asinteger;
     result:=true;
  end;
end;

function TCommandsArgumentsParser.GetAsSingle(idx: integer; var output: single; default_for_optionals: single): boolean;
var
  r:TCommandArgumentParseResult;
begin
  result:=false;
  if length(_lasterror)>0 then exit;
  r:=Get(idx, true);
  if not r.present then begin
    if _params[idx].is_optional then begin
      result:=true;
      output:=default_for_optionals;
    end else begin
      exit;
    end;
  end else if _params[idx].argtype = TCommandsArgumentsParserArgSingle then begin;
     output:=r.assingle;
     result:=true;
  end;
end;

function TCommandsArgumentsParser.GetAsString(idx: integer; var output: string; default_for_optionals: string): boolean;
var
  r:TCommandArgumentParseResult;
begin
  result:=false;
  if length(_lasterror)>0 then exit;
  r:=Get(idx, true);
  if not r.present then begin
    if _params[idx].is_optional then begin
      result:=true;
      output:=default_for_optionals;
    end else begin
      exit;
    end;
  end else if (_params[idx].argtype = TCommandsArgumentsParserArgABNString) or
     (_params[idx].argtype = TCommandsArgumentsParserArgNumericString) or
     (_params[idx].argtype = TCommandsArgumentsParserArgAnyString)
  then begin
     output:=r.rawstr;
     result:=true;
  end;
end;

function TCommandsArgumentsParser.GetAsBool(idx: integer; var output: Boolean; default_for_optionals: boolean): boolean;
var
  r:TCommandArgumentParseResult;
begin
  result:=false;
  if length(_lasterror)>0 then exit;
  r:=Get(idx, true);
  if not r.present then begin
    if _params[idx].is_optional then begin
      result:=true;
      output:=default_for_optionals;
    end else begin
      exit;
    end;
  end else if _params[idx].argtype = TCommandsArgumentsParserArgBool then begin;
     output:=r.asbool;
     result:=true;
  end;
end;

function TCommandsArgumentsParser.GetLastErr(): string;
begin
  result:=_lasterror;
end;


end.


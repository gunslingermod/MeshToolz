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

end.


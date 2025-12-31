unit commandsstorage;

{$mode objfpc}{$H+}

interface
uses CommandsHelpers;

type

{ TCommandResult }

TCommandResult = class
  _description:string;
  _is_success:boolean;
  _is_warning:boolean;
  _result_object:TObject;
public
  constructor Create();
  procedure Reset();
  function GetDescription():string;
  procedure SetDescription(s:string);
  function IsSuccess():boolean;
  function IsWarning():boolean;
  procedure SetSuccess(flag:boolean);
  procedure SetWarningFlag(flag:boolean);

  procedure SetResultObject(o:TObject);
  function GetResultObject():TObject;
end;

TCommandPrecondition = function (args:string; result_description:TCommandResult; userdata:TObject):boolean of object;
TCommandAction = function (var args:string; result_description:TCommandResult; userdata:TObject):boolean of object;


{ TCommandSetup }

TCommandSetup = class
  _name:string;
  _precondition:TCommandPrecondition;
  _action:TCommandAction;
public
  constructor Create(name:string; precondition:TCommandPrecondition; action:TCommandAction);
  function GetName():string;
  function Execute(var args:string; result_description:TCommandResult; userdata:TObject):boolean;
end;


TCommandItemType = (CommandItemTypeCall, CommandItemTypeProperty);

{ TCommandsStorage }

TCommandsStorage = class
  _default_action:TCommandAction;
  _calls:array of TCommandSetup;
  _properties:array of TCommandSetup;

  _result_desc:TCommandResult;

  function _CmdEnumerateCalls(var args:string; result_description:TCommandResult; userdata:TObject):boolean; virtual;
  function _CmdEnumerateProps(var args:string; result_description:TCommandResult; userdata:TObject):boolean; virtual;
  function _CmdEnumerateAll(var args:string; result_description:TCommandResult; userdata:TObject):boolean; virtual;
public
  constructor Create(default_help:boolean);
  destructor Destroy();override;

  procedure SetDefaultAction(act:TCommandAction);
  function Find(name:string; itemtype:TCommandItemType):TCommandSetup;
  function DoRegister(act:TCommandSetup; itemtype:TCommandItemType):boolean;
  function Execute(var args:string; userdata:TObject):TCommandResult;
end;

{ TCommandArg }

TCommandArg = class
  _userdata:pointer;
public
  constructor Create(userdata:pointer);
  function GetUserdata():pointer;
end;

{ TCommandIndexArg }

TCommandIndexArg = class(TCommandArg)
  _value:integer;
public
  constructor Create(value:integer; userdata:pointer);
  function Get():integer;
end;

{ TFilteringCommands }

TFilteringCommands = class(TCommandsStorage)
  _filters:TIndexFilters;

  function _CmdEnumerateFilters(var args:string; result_description:TCommandResult; userdata:TObject):boolean; virtual;
  function _CmdEnumerateAll(var args:string; result_description:TCommandResult; userdata:TObject):boolean; override;
public
  constructor Create(default_help:boolean);
  destructor Destroy(); override;
  procedure RegisterFilter(name:string; defval:string='');
  function FilteringExecute(var args:string; userdata:TObject):TCommandResult;

  function GetFilteringItemTypeName(item_id:integer):string; virtual; abstract;
  function GetFilteringItemsCount():integer; virtual; abstract;
  function CheckFiltersForItem(item_id:integer):boolean; virtual; abstract;
end;

implementation
uses strutils, sysutils;

const
  OPCODE_CALL:char=':';
  OPCODE_INDEX:char='.';

{ TCommandArg }

constructor TCommandArg.Create(userdata: pointer);
begin
  _userdata:=userdata;
end;

function TCommandArg.GetUserdata(): pointer;
begin
  result:=_userdata;
end;

{ TCommandSetup }

constructor TCommandSetup.Create(name: string; precondition: TCommandPrecondition; action: TCommandAction);
begin
 _name:=name;
 _precondition:=precondition;
 _action:=action;
end;

function TCommandSetup.GetName(): string;
begin
  result:=_name;
end;

function TCommandSetup.Execute(var args: string; result_description: TCommandResult; userdata: TObject): boolean;
var
  precond_ok:boolean;
begin
  result:=true;
  if _precondition<>nil then begin
    result:=_precondition(args, result_description, userdata);
  end;

  if not result then begin
    if length(result_description.GetDescription()) = 0 then begin
      result_description.SetDescription('precondition failed for "'+_name+'"');
    end;
  end else begin
    result:=_action(args, result_description, userdata);

    if not result and (length(result_description.GetDescription()) = 0) then begin
      result_description.SetDescription('action execution failed for "'+_name+'"');
    end;
  end;

  result_description.SetSuccess(result);
end;

{ TCommandResult }

constructor TCommandResult.Create();
begin
  Reset();
end;

procedure TCommandResult.Reset();
begin
  _is_success:=false;
  _is_warning:=false;
  _description:='';
  _result_object:=nil;
end;

function TCommandResult.GetDescription(): string;
begin
  result:=_description;
end;

procedure TCommandResult.SetDescription(s: string);
begin
  _description:=s;
end;

function TCommandResult.IsSuccess(): boolean;
begin
  result:=_is_success;
end;

function TCommandResult.IsWarning(): boolean;
begin
  result:=_is_warning;
end;

procedure TCommandResult.SetSuccess(flag: boolean);
begin
  _is_success:=flag;
end;

procedure TCommandResult.SetWarningFlag(flag: boolean);
begin
  _is_warning:=flag;
end;

procedure TCommandResult.SetResultObject(o: TObject);
begin
  _result_object:=o;
end;

function TCommandResult.GetResultObject(): TObject;
begin
  result:=_result_object;
end;

{ TCommandsStorage }

function TCommandsStorage._CmdEnumerateCalls(var args: string; result_description: TCommandResult; userdata: TObject): boolean;
var
  i:integer;
  r:string;
begin
  r:='';

  if length(_calls)>0 then begin
    r:=r+'Registered procedures:'+chr($0d)+chr($0a);
    for i:=0 to length(_calls)-1 do begin
      r:=r+'  '+_calls[i].GetName()+chr($0d)+chr($0a);
    end;
  end;

  result_description.SetDescription(r);
  result:=true;
end;

function TCommandsStorage._CmdEnumerateProps(var args: string; result_description: TCommandResult; userdata: TObject): boolean;
var
  i:integer;
  r:string;
begin
  r:='';

  if length(_properties)>0 then begin
    r:=r+'Registered properties:'+chr($0d)+chr($0a);
    for i:=0 to length(_properties)-1 do begin
      r:=r+'  '+_properties[i].GetName()+chr($0d)+chr($0a);
    end;
  end;

  result_description.SetDescription(r);
  result:=true;
end;

function TCommandsStorage._CmdEnumerateAll(var args: string; result_description: TCommandResult; userdata: TObject): boolean;
var
  r:string;
begin
  r:=chr($0d)+chr($0a);
  _CmdEnumerateProps(args, result_description, userdata);
  r:=r+result_description.GetDescription();
  _CmdEnumerateCalls(args, result_description, userdata);
  r:=r+result_description.GetDescription();

  result_description.SetDescription(r);
  result:=true;
end;

constructor TCommandsStorage.Create(default_help: boolean);
begin
  _default_action:=nil;
  setlength(_calls, 0);
  setlength(_properties, 0);
  _result_desc:=TCommandResult.Create();

  if default_help then begin
//    DoRegister(TCommandSetup.Create('help', nil, @_CmdEnumerateProps), CommandItemTypeProperty);
//    DoRegister(TCommandSetup.Create('help', nil, @_CmdEnumerateCalls), CommandItemTypeCall);
    _default_action:=@_CmdEnumerateAll;
  end;
end;

destructor TCommandsStorage.Destroy();
var
  i:integer;
begin
  for i:=0 to length(_calls)-1 do begin
    FreeAndNil(_calls[i]);
  end;
  for i:=0 to length(_properties)-1 do begin
    FreeAndNil(_properties[i]);
  end;
  FreeAndNil(_default_action);
  FreeAndNil(_result_desc);

  inherited Destroy();
end;

procedure TCommandsStorage.SetDefaultAction(act: TCommandAction);
begin
  FreeAndNil(_default_action);
  _default_action:=act;
end;

function TCommandsStorage.Find(name: string; itemtype: TCommandItemType): TCommandSetup;
var
  i:integer;
begin
  result:=nil;

  if itemtype = CommandItemTypeCall then begin
    for i:=0 to length(_calls)-1 do begin
      if lowercase(_calls[i].GetName()) = lowercase(name) then begin
        result:=_calls[i];
      end;
    end;
  end else if itemtype = CommandItemTypeProperty then begin
    for i:=0 to length(_properties)-1 do begin
      if lowercase(_properties[i].GetName()) = lowercase(name) then begin
        result:=_properties[i];
      end;
    end;
  end;
end;

function TCommandsStorage.DoRegister(act: TCommandSetup; itemtype: TCommandItemType): boolean;
var
  i:integer;
begin
  result:=false;
  if length(act.GetName()) = 0 then exit;

  if Find(act.GetName(), itemtype)=nil then begin
    if itemtype = CommandItemTypeCall then begin
      i:=length(_calls);
      setlength(_calls, i+1);
      _calls[i]:=act;
    end else if itemtype = CommandItemTypeProperty then begin
      i:=length(_properties);
      setlength(_properties, i+1);
      _properties[i]:=act;
    end;
  end;
end;

function TCommandsStorage.Execute(var args: string; userdata: TObject): TCommandResult;
var
  opcode:char;
  i:integer;
  name:string;
  extracted_args:string;
  cmd:TCommandSetup;
begin
  args:=TrimLeft(args);
  _result_desc.Reset();
  _result_desc.SetSuccess(false);

  if length(args)=0 then begin
    if _default_action<>nil then begin
      _result_desc.SetSuccess(true);
      _default_action(args, _result_desc, userdata);
    end;

  end else begin
    opcode:=args[1];
    args:=rightstr(args, length(args)-1);

    if opcode = OPCODE_CALL then begin
      name:=ExtractAlphabeticString(args);
      if (length(name)>0) and not ExtractProcArgs(args, extracted_args) then begin
        _result_desc.SetDescription('can''t parse call arguments');
      end else begin
        if length(name) = 0 then begin
          _CmdEnumerateCalls(args, _result_desc, nil);
          _result_desc.SetSuccess(false);
        end else begin
          args:=extracted_args;
          cmd:=Find(name, CommandItemTypeCall);
          if cmd = nil then begin
            _result_desc.SetDescription('unknown procedure "'+name+'"');
          end else begin
            cmd.Execute(args, _result_desc, userdata);
          end;
        end;
      end;
    end else if opcode = OPCODE_INDEX then begin
      name:=ExtractAlphabeticString(args);
      if length(name) = 0 then begin
        _CmdEnumerateProps(args, _result_desc, nil);
        _result_desc.SetSuccess(false);
      end else begin
        cmd:=Find(name, CommandItemTypeProperty);
        if cmd = nil then begin
          _result_desc.SetDescription('unknown property "'+name+'"');
        end else begin
          cmd.Execute(args, _result_desc, userdata);
        end;
      end;
    end else begin
      _result_desc.SetDescription('unsupported opcode "'+opcode+'")');
    end;
  end;

  result:=_result_desc;
end;

{ TCommandIndexArg }

constructor TCommandIndexArg.Create(value: integer; userdata: pointer);
begin
  inherited Create(userdata);
   _value:=value;
end;

function TCommandIndexArg.Get(): integer;
begin
   result:=_value;
end;

{ TFilteringCommands }

function TFilteringCommands._CmdEnumerateFilters(var args: string; result_description: TCommandResult; userdata: TObject): boolean;
var
  i:integer;
  r:string;
begin
  r:='';

  if length(_filters)>0 then begin
    r:=r+'Registered filters:'+chr($0d)+chr($0a);
    for i:=0 to length(_filters)-1 do begin
      r:=r+'  '+_filters[i].name+chr($0d)+chr($0a);
    end;
  end;

  result_description.SetDescription(r);
  result:=true;
end;

function TFilteringCommands._CmdEnumerateAll(var args: string; result_description: TCommandResult; userdata: TObject): boolean;
var
  r:string;
begin
  if userdata is TCommandIndexArg then begin
    result:=inherited _CmdEnumerateAll(args, result_description, userdata);
  end else begin
    r:='Multi-value property, use index for direct access to single value or [] to apply filters and process a group of values'+chr($0d)+chr($0a);

    inherited _CmdEnumerateAll(args, result_description, userdata);
    r:=r+result_description.GetDescription();
    _CmdEnumerateFilters(args, result_description, userdata);
    r:=r+result_description.GetDescription();
    result_description.SetDescription(r);
    result:=true;
  end;
end;

constructor TFilteringCommands.Create(default_help: boolean);
begin
  inherited;
  InitFilters(_filters);
end;

destructor TFilteringCommands.Destroy();
begin
  ClearFilters(_filters);
  inherited Destroy();
end;

procedure TFilteringCommands.RegisterFilter(name: string; defval: string);
begin
  PushFilter(_filters, name, defval);
end;

function TFilteringCommands.FilteringExecute(var args: string; userdata: TObject): TCommandResult;
var
  i:integer;
  tmpstr, r:string;
  cnt:integer;
  indexarg:TCommandIndexArg;

begin
  result:=TCommandResult.Create();

  try
    result.Reset();
    result.SetSuccess(false);

    if ExtractIndexFilter(args, _filters, i) then begin
      if i < 0 then begin
        result.SetDescription('invalid filter rule');
      end else begin
        r:='';

        // We use reverse order because current child could disappear or new child in the end could appear while executing command
        cnt:=0;
        result.SetSuccess(true);
        for i:=GetFilteringItemsCount()-1 downto 0 do begin
          if CheckFiltersForItem(i) then begin
            cnt:=cnt+1;
            indexarg:=TCommandIndexArg.Create(i, userdata);
            tmpstr:=args;
            try
              Execute(tmpstr, indexarg);
            finally
              FreeAndNil(indexarg);
            end;

            if not _result_desc.IsSuccess() then begin
              result.SetSuccess(false);
              if length(_result_desc.GetDescription())>0 then begin;
                r:=r+'!' +GetFilteringItemTypeName(i)+inttostr(i)+': '+_result_desc.GetDescription()+chr($0d)+chr($0a);
              end;
            end else if _result_desc.IsWarning() then begin
              result.SetWarningFlag(true);
              if length(_result_desc.GetDescription())>0 then begin;
                r:=r+'#'+GetFilteringItemTypeName(i)+inttostr(i)+': '+_result_desc.GetDescription()+chr($0d)+chr($0a);
              end;
            end else if length(_result_desc.GetDescription())>0 then begin;
                r:=r+GetFilteringItemTypeName(i)+inttostr(i)+': '+_result_desc.GetDescription()+chr($0d)+chr($0a);
            end;
          end;
        end;

        if cnt = 0 then begin
          result.SetWarningFlag(true);
          result.SetDescription('the specified filter doesn''t match any item, no action performed');
        end else begin
          result.SetDescription(r);
        end;
      end;
    end else begin
      tmpstr:=ExtractNumericString(args, false);
      if length(tmpstr)=0 then begin
        if _default_action<>nil then begin
          _default_action(args, result, userdata);
        end;

        if length(trim(args)) = 0 then begin
          result.SetSuccess(true);
        end else begin
          result.SetDescription('invalid syntax.'+chr($0d)+chr($0a)+result.GetDescription());
          result.SetSuccess(false);
        end;

      end else begin
        i:=strtointdef(tmpstr, $FFFFFFFF);
        if i<0 then begin
          i:=GetFilteringItemsCount()+i;
        end;

        if (i<0) or (i >= GetFilteringItemsCount()) then begin
          result.SetDescription('invalid index "'+inttostr(i)+'", expected number from 0 to '+inttostr(GetFilteringItemsCount()-1));

        end else begin
          indexarg:=TCommandIndexArg.Create(i, userdata);
          try
            Execute(args, indexarg);
          finally
            FreeAndNil(indexarg);
          end;

          result.SetDescription(_result_desc.GetDescription());
          result.SetWarningFlag(_result_desc.IsWarning());
          result.SetSuccess(_result_desc.IsSuccess());
        end;
      end;
    end;

  finally
    FreeAndNil(_result_desc);
    _result_desc:=result;
  end;
end;

end.


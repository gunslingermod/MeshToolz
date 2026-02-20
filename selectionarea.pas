unit SelectionArea;

{$mode objfpc}{$H+}

interface
uses basedefs;

type
  TSelectionTypes = (SelectionTypeNone, SelectionTypeSphere, SelectionTypeBox, SelectionTypeVertices);

  { TSelectionArea }

  TSelectionArea = class
    _pivot_point:FVector3;
    _inverted:boolean;


    _selectiontype:TSelectionTypes;
    _center:FVector3;
    _radius:single;

    _p1, _p2:FVector3;

    _ids:array of cardinal;

    function _GetSelectionTypeString():string;

    procedure _RemoveSelectedId(idx:integer);
    function _GetInternalVertexId(child_id:cardinal; vertex_id:integer):cardinal;

  public
    constructor Create();
    destructor Destroy(); override;

    procedure SetPivot(pivot_point:FVector3);
    function GetPivot():FVector3;
    function IsPointInSelection(point:FVector3):boolean;
    function IsVertexInSelectionList(child_id: cardinal; vertexid:cardinal):boolean;
    function IsVertexInSelection(child_id: cardinal; vertexid:cardinal; position:FVector3):boolean;

    procedure SetSelectionAreaAsSphere(center:FVector3; radius:single);
    procedure SetSelectionAreaAsBox(p1:FVector3; p2:FVector3);
    procedure AddVerticesToSelectionList(child_id:cardinal; vertices:array of integer);
    procedure AddVertexToSelectionList(child_id:cardinal; vertex:integer);
    procedure RemoveVerticesFromSelectionList(child_id:cardinal; vertices:array of integer);
    procedure RemoveAllChildVerticesFromSelectionList(child_id:cardinal);
    procedure AddAllChildVerticesToSelectionList(child_id:cardinal; child_vertices_count:integer);

    function IsSpatialSelectionModeActive():boolean;
    function IsVertsSelectionModeActive():boolean;

    procedure ResetSelection();
    procedure InverseSelection();

    function Info():string;
  end;

implementation
uses strutils, sysutils;

{ TSelectionArea }

function TSelectionArea._GetSelectionTypeString(): string;
begin
  if _selectiontype = SelectionTypeSphere then begin
    result:='SPHERE';
  end else if _selectiontype = SelectionTypeBox then begin
    result:='BOX';
  end else if _selectiontype = SelectionTypeVertices then begin
    result:='VERTICES';
  end else begin
    result:='NONE';
  end;
end;

procedure TSelectionArea._RemoveSelectedId(idx: integer);
var
  len:integer;
begin
  len:=length(_ids);
  if (idx >= 0) and (idx < len) then begin
    _ids[idx]:=_ids[len-1];
    setlength(_ids, len-1);
  end;
end;

function TSelectionArea._GetInternalVertexId(child_id: cardinal; vertex_id: integer): cardinal;
begin
  result:=(child_id shl 16) or (vertex_id and $FFFF);
end;

constructor TSelectionArea.Create();
begin
  _selectiontype:=SelectionTypeNone;
  set_zero(_pivot_point);
  _inverted:=false;
end;

destructor TSelectionArea.Destroy();
begin
  setlength(_ids, 0);
  inherited Destroy();
end;

procedure TSelectionArea.SetPivot(pivot_point: FVector3);
begin
  _pivot_point:=pivot_point;
end;

function TSelectionArea.GetPivot(): FVector3;
begin
  result:=_pivot_point;
end;

function max(n1:single; n2:single):single;
begin
  if n1>n2 then begin
    result:=n1;
  end else begin
    result:=n2;
  end;
end;

function min(n1:single; n2:single):single;
begin
  if n1<n2 then begin
    result:=n1;
  end else begin
    result:=n2;
  end;
end;

function TSelectionArea.IsPointInSelection(point: FVector3): boolean;
begin
  result:=false;
  if _selectiontype = SelectionTypeSphere then begin
    result:= distance_between(_center, point) < _radius;
  end else if _selectiontype = SelectionTypeBox then begin
    result:=(point.x<=max(_p1.x, _p2.x))
        and (point.x>=min(_p1.x, _p2.x))
        and (point.y<=max(_p1.y, _p2.y))
        and (point.y>=min(_p1.y, _p2.y))
        and (point.z<=max(_p1.z, _p2.z))
        and (point.z>=min(_p1.z, _p2.z));
  end else if _selectiontype = SelectionTypeNone then begin
    result:=false;
  end else begin
    exit;
  end;

  if _inverted then begin
    result:=not result;
  end;
end;

function TSelectionArea.IsVertexInSelectionList(child_id: cardinal; vertexid: cardinal): boolean;
var
  i:integer;
  id:cardinal;
begin
  result:=false;
  id:=_GetInternalVertexId(child_id, vertexid);

  if _selectiontype=SelectionTypeVertices then begin
    for i:=0 to length(_ids)-1 do begin
      if id = _ids[i] then begin
        result:=true;
        break;
      end;
    end;

    if _inverted then begin
      result:=not result;
    end;
  end;
end;

function TSelectionArea.IsVertexInSelection(child_id: cardinal; vertexid: cardinal; position: FVector3): boolean;
begin
  result:=IsPointInSelection(position) or IsVertexInSelectionList(child_id, vertexid);
end;

procedure TSelectionArea.SetSelectionAreaAsSphere(center: FVector3; radius: single);
begin
  ResetSelection();
  _selectiontype:=SelectionTypeSphere;
  _center:=center;
  _radius:=radius;
end;

procedure TSelectionArea.SetSelectionAreaAsBox(p1: FVector3; p2: FVector3);
begin
  ResetSelection();
  _selectiontype:=SelectionTypeBox;
  _p1:=p1;
  _p2:=p2;
end;

procedure TSelectionArea.AddVerticesToSelectionList(child_id: cardinal; vertices: array of integer);
var
  i:integer;
  oldlen:integer;
begin
  if _selectiontype<>SelectionTypeVertices then begin
    ResetSelection();
    _selectiontype:=SelectionTypeVertices;
  end;

  oldlen:=length(_ids);
  setlength(_ids, oldlen+length(vertices));
  for i:=0 to length(vertices)-1 do begin
    _ids[oldlen+i]:=_GetInternalVertexId(child_id, vertices[i]);
  end;
end;

procedure TSelectionArea.AddVertexToSelectionList(child_id: cardinal; vertex: integer);
var
  i:integer;
begin
  if _selectiontype<>SelectionTypeVertices then begin
    ResetSelection();
    _selectiontype:=SelectionTypeVertices;
  end;

  i:=length(_ids);
  setlength(_ids, i+1);
  _ids[i]:=_GetInternalVertexId(child_id, vertex);
end;

procedure TSelectionArea.RemoveVerticesFromSelectionList(child_id: cardinal; vertices: array of integer);
var
  i, j:integer;
  id:cardinal;
begin
  if _selectiontype=SelectionTypeVertices then begin
    for i:=0 to length(vertices)-1 do begin
      id:=_GetInternalVertexId(child_id, vertices[i]);
      for j:=0 to length(_ids)-1 do begin
        if _ids[j]=id then begin
          _RemoveSelectedId(j);
        end;
      end;
    end;
  end;
end;

procedure TSelectionArea.RemoveAllChildVerticesFromSelectionList(child_id: cardinal);
var
  i:integer;
begin
  if _selectiontype=SelectionTypeVertices then begin
    for i:=0 to length(_ids)-1 do begin
      if _ids[i] shr 16 = child_id then begin
        _RemoveSelectedId(i);
      end;
    end;
  end;
end;

procedure TSelectionArea.AddAllChildVerticesToSelectionList(child_id: cardinal; child_vertices_count: integer);
var
  i:integer;
  id:cardinal;
  oldlen:integer;
begin
  if _selectiontype<>SelectionTypeVertices then begin
    ResetSelection();
    _selectiontype:=SelectionTypeVertices;
  end;
  RemoveAllChildVerticesFromSelectionList(child_id);

  oldlen:=length(_ids);
  setlength(_ids, oldlen+child_vertices_count);
  for i:=0 to child_vertices_count-1 do begin
    id:=_GetInternalVertexId(child_id, i);
    _ids[oldlen+i]:=id;
  end;
end;

function TSelectionArea.IsSpatialSelectionModeActive(): boolean;
begin
  result:=(_selectiontype=SelectionTypeBox) or (_selectiontype = SelectionTypeSphere);
end;

function TSelectionArea.IsVertsSelectionModeActive(): boolean;
begin
  result:=(_selectiontype=SelectionTypeVertices);
end;

procedure TSelectionArea.ResetSelection();
begin
  _selectiontype:=SelectionTypeNone;
  _inverted:=false;
  setlength(_ids, 0);
end;

procedure TSelectionArea.InverseSelection();
begin
  _inverted:=not _inverted;
end;

function TSelectionArea.Info(): string;
begin
  result:='';
  result:=result+'Pivot point: '+floattostr(_pivot_point.x)+', '+floattostr(_pivot_point.y)+', '+floattostr(_pivot_point.z)+chr($0d)+chr($0a);
  result:=result+'Selection area type: '+ _GetSelectionTypeString()+chr($0d)+chr($0a);

  if _selectiontype = SelectionTypeSphere then begin
    result:=result+'- Center point: '+floattostr(_center.x)+', '+floattostr(_center.y)+', '+floattostr(_center.z)+chr($0d)+chr($0a);
    result:=result+'- Radius: '+floattostr(_radius)+chr($0d)+chr($0a);
    result:=result+'- Inverted: '+booltostr(_inverted, true);
  end else if _selectiontype = SelectionTypeBox then begin
    result:=result+'- Point1: '+floattostr(_p1.x)+', '+floattostr(_p1.y)+', '+floattostr(_p1.z)+chr($0d)+chr($0a);
    result:=result+'- Point2: '+floattostr(_p2.x)+', '+floattostr(_p2.y)+', '+floattostr(_p2.z)+chr($0d)+chr($0a);
    result:=result+'- Inverted: '+booltostr(_inverted, true);
  end else if _selectiontype = SelectionTypeVertices then begin
    result:=result+'- Total vertices count (including possible dups): '+inttostr(length(_ids))+chr($0d)+chr($0a);
    result:=result+'- Inverted: '+booltostr(_inverted, true);
  end;
end;

end.


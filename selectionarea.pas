unit SelectionArea;

{$mode objfpc}{$H+}

interface
uses basedefs;

type
  TSelectionTypes = (SelectionTypeNone, SelectionTypeSphere, SelectionTypeBox);

  { TSelectionArea }

  TSelectionArea = class
    _pivot_point:FVector3;
    _inverted:boolean;


    _selectiontype:TSelectionTypes;
    _center:FVector3;
    _radius:single;

    _p1, _p2:FVector3;

    function _GetSelectionTypeString():string;

  public
    constructor Create();

    procedure SetPivot(pivot_point:FVector3);
    function GetPivot():FVector3;
    function IsPointInSelection(point:FVector3):boolean;

    procedure SetSelectionAreaAsSphere(center:FVector3; radius:single);
    procedure SetSelectionAreaAsBox(p1:FVector3; p2:FVector3);
    procedure ResetSelectionArea();

    procedure InverseSelectedArea();

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
  end else begin
    result:='NONE';
  end;
end;

constructor TSelectionArea.Create();
begin
  _selectiontype:=SelectionTypeNone;
  set_zero(_pivot_point);
  _inverted:=false;
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

procedure TSelectionArea.SetSelectionAreaAsSphere(center: FVector3; radius: single);
begin
  ResetSelectionArea();
  _selectiontype:=SelectionTypeSphere;
  _center:=center;
  _radius:=radius;
end;

procedure TSelectionArea.SetSelectionAreaAsBox(p1: FVector3; p2: FVector3);
begin
  ResetSelectionArea();
  _selectiontype:=SelectionTypeBox;
  _p1:=p1;
  _p2:=p2;
end;

procedure TSelectionArea.ResetSelectionArea();
begin
  _selectiontype:=SelectionTypeNone;
  _inverted:=false;
end;

procedure TSelectionArea.InverseSelectedArea();
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
  end;
end;

end.


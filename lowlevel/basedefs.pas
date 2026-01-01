unit basedefs;

{$mode objfpc}{$H+}

interface

type
  FVector2 = packed record
    x:single;
    y:single;
  end;
  pFVector2 = ^FVector2;

  FVector3 = packed record
    x:single;
    y:single;
    z:single;
  end;
  pFVector3 = ^FVector3;

  FSphere = packed record
    p:FVector3;
    r:single;
  end;
  pFSphere = ^FSphere;

  FCylinder = packed record
    m_center:FVector3;
    m_direction:FVector3;
    m_height:single;
    m_radius:single;
  end;
  pFCylinder = ^FCylinder;

  FMatrix3x3 = packed record
    i:FVector3;
    j:FVector3;
    k:FVector3;
  end;
  pFMatrix3x3 = ^FMatrix3x3;

  FObb = packed record
    m_rotate:FMatrix3x3;
    m_translate:FVector3;
    m_halfsize:FVector3;
  end;
  pFObb = ^FObb;

  Fquaternion = packed record
    x:single;
    y:single;
    z:single;
    w:single;
  end;
  pFquaternion = ^Fquaternion;

  procedure set_zero(var v:FVector2); overload;
  procedure set_zero(var v:FVector3); overload;
  procedure set_zero(var s:FSphere); overload;
  procedure set_zero(var c:FCylinder); overload;
  procedure set_zero(var m:FMatrix3x3); overload;
  procedure set_zero(var o:FObb); overload;

  procedure uniform_scale(var v:FVector3; k:single); overload;
  procedure uniform_scale(var s:FSphere; k:single); overload;
  procedure uniform_scale(var c:FCylinder; k:single); overload;
  procedure uniform_scale(var o:FObb; k:single); overload;

  function v_add(v1:pFVector3; v2:pFVector3):FVector3;
  function v_sub(v1:pFVector3; v2:pFVector3):FVector3;
  function v_mul(v:pFVector3; n:single):FVector3;

  function m_mul(m:pFMatrix3x3; v:pFVector3):FVector3;

  function distance_between(point1:pFVector3; point2:pFVector3):single;

implementation

procedure set_zero(var v: FVector2);
begin
  v.x:=0;
  v.y:=0;
end;

procedure set_zero(var v: FVector3);
begin
  v.x:=0;
  v.y:=0;
  v.z:=0;
end;

procedure set_zero(var s: FSphere);
begin
  set_zero(s.p);
  s.r:=0;
end;

procedure set_zero(var c: FCylinder);
begin
  set_zero(c.m_center);
  set_zero(c.m_direction);
  c.m_height:=0;
  c.m_radius:=0;;
end;

procedure set_zero(var m: FMatrix3x3);
begin
  set_zero(m.i);
  set_zero(m.j);
  set_zero(m.k);
end;

procedure set_zero(var o: FObb);
begin
  set_zero(o.m_rotate);
  set_zero(o.m_translate);
  set_zero(o.m_halfsize);
end;

procedure uniform_scale(var v: FVector3; k: single);
begin
  v.x:=v.x*k;
  v.y:=v.y*k;
  v.z:=v.z*k;
end;

procedure uniform_scale(var s: FSphere; k: single);
begin
  uniform_scale(s.p, k);
  s.r:=s.r*k;
end;

procedure uniform_scale(var c: FCylinder; k: single);
begin
  uniform_scale(c.m_center, k);
  c.m_height:=c.m_height*k;
  c.m_radius:=c.m_radius*k;
end;

procedure uniform_scale(var o: FObb; k: single);
begin
  uniform_scale(o.m_halfsize, k);
  uniform_scale(o.m_translate, k);
end;

function v_add(v1:pFVector3; v2:pFVector3):FVector3;
begin
  result.x:=v1^.x+v2^.x;
  result.y:=v1^.y+v2^.y;
  result.z:=v1^.z+v2^.z;
end;

function v_sub(v1:pFVector3; v2:pFVector3):FVector3;
begin
  result.x:=v1^.x-v2^.x;
  result.y:=v1^.y-v2^.y;
  result.z:=v1^.z-v2^.z;
end;

function v_mul(v:pFVector3; n:single):FVector3;
begin
  result.x:=v^.x*n;
  result.y:=v^.y*n;
  result.z:=v^.z*n;
end;

function m_mul(m: pFMatrix3x3; v: pFVector3): FVector3;
begin
  result.x:=m^.i.x*v^.x+m^.i.y*v^.y+m^.i.z*v^.z;
  result.y:=m^.j.x*v^.x+m^.j.y*v^.y+m^.j.z*v^.z;
  result.z:=m^.k.x*v^.x+m^.k.y*v^.y+m^.k.z*v^.z;
end;

function distance_between(point1: pFVector3; point2: pFVector3): single;
var
  dx, dy, dz:single;
begin
  dx:=point2^.x-point1^.x;
  dy:=point2^.y-point1^.y;
  dz:=point2^.z-point1^.z;

  result:=sqrt(dx*dx+dy*dy+dz*dz);
end;

end.


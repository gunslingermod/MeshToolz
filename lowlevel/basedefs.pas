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

end.


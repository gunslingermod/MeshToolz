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

  procedure set_zero(var v:FVector3); overload;
  procedure set_zero(var m:FMatrix3x3); overload;
  procedure set_zero(var o:FObb); overload;

implementation

procedure set_zero(var v: FVector3);
begin
  v.x:=0;
  v.y:=0;
  v.z:=0;
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

end.


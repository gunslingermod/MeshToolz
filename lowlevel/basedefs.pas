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

  FMatrix4x4 = packed record
    i:Fquaternion;
    j:Fquaternion;
    k:Fquaternion;
    c:Fquaternion;
  end;
  pFMatrix4x4 = ^FMatrix4x4;

  procedure set_zero(var v:FVector2); overload;
  procedure set_zero(var v:FVector3); overload;
  procedure set_zero(var s:FSphere); overload;
  procedure set_zero(var c:FCylinder); overload;
  procedure set_zero(var m:FMatrix3x3); overload;
  procedure set_zero(var m:FMatrix4x4); overload;
  procedure set_zero(var o:FObb); overload;
  procedure set_zero(var q:Fquaternion); overload;

  procedure m_identity(var m:FMatrix3x3); overload;
  procedure m_identity(var m:FMatrix4x4); overload;

  function m_same(var m1:FMatrix4x4; var m2:FMatrix4x4):boolean;

  procedure uniform_scale(var v:FVector3; k:single); overload;
  procedure uniform_scale(var s:FSphere; k:single); overload;
  procedure uniform_scale(var c:FCylinder; k:single); overload;
  procedure uniform_scale(var o:FObb; k:single); overload;

  function v_add(var v1:FVector3; var v2:FVector3):FVector3;
  function v_sub(var v1:FVector3; var v2:FVector3):FVector3;
  function v_mul(var v:FVector3; n:single):FVector3;
  function v_crossproduct(var v1:FVector3; var v2:FVector3):FVector3;
  function v_dotproduct(var v1:FVector3; var v2:FVector3):single;
  function v_magnitude(var v:FVector3):single;
  function v_angle_between(var v1:FVector3; var v2:FVector3):single;
  function v_normalize(var v:FVector3):FVector3;

  function m_mul(var m:FMatrix3x3; var v:FVector3):FVector3; overload;
  function m_mul(var m:FMatrix4x4; n:single):FMatrix4x4; overload;
  function m_mul(var m:FMatrix4x4; var q:Fquaternion):Fquaternion; overload;
  function m_mul(var m1:FMatrix4x4; var m2:FMatrix4x4):FMatrix4x4; overload;
  function m_mul4x3(var m1:FMatrix4x4; var m2:FMatrix4x4):FMatrix4x4; overload;

  procedure m_setHPB(var m:FMatrix4x4; h:single; p:single; b:single);
  procedure m_getHPB(var m:FMatrix4x4; var h:single; var p:single; var b:single);
  procedure m_setXYZ(var m:FMatrix4x4; var v:FVector3);
  procedure m_getXYZ(var m:FMatrix4x4; var v:FVector3);
  procedure m_getXYZi(var m:FMatrix4x4; var v:FVector3);
  procedure m_translate_over(var m:FMatrix4x4; var v:FVector3);
  procedure m_get_translation(var m:FMatrix4x4; var v:FVector3);
  function m_invert43(var m:FMatrix4x4):FMatrix4x4;
  procedure m_rotation(var m:FMatrix4x4; var q:Fquaternion);
  procedure q_rotationYawPitchRoll(var q:Fquaternion; var ypr:FVector3);
  procedure q_rotation(var q:Fquaternion; var m:FMatrix4x4);
  procedure q_set(var q:Fquaternion; x:single; y:single; z:single; w:single);
  procedure q_scale(var q:Fquaternion; n:single);
  procedure q_slerp(var r:Fquaternion; q0:Fquaternion; q1:Fquaternion; tm:single);


  function distance_between(var point1:FVector3; var point2:FVector3):single;
  function rotation_between(var src:FVector3; var dst:FVector3):FMatrix4x4;

implementation
uses math;

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

procedure set_zero(var m: FMatrix4x4);
begin
  set_zero(m.i);
  set_zero(m.j);
  set_zero(m.k);
  set_zero(m.c);
end;

procedure set_zero(var o: FObb);
begin
  m_identity(o.m_rotate);
  set_zero(o.m_translate);
  set_zero(o.m_halfsize);
end;

procedure set_zero(var q: Fquaternion);
begin
  q.x:=0;
  q.y:=0;
  q.z:=0;
  q.w:=0;
end;

procedure m_identity(var m: FMatrix3x3);
begin
  set_zero(m);
  m.i.x:=1;
  m.j.y:=1;
  m.k.z:=1;
end;

procedure m_identity(var m: FMatrix4x4);
begin
  m.i.x:=1;
  m.j.y:=1;
  m.k.z:=1;
  m.c.w:=1;
end;

function m_same(var m1: FMatrix4x4; var m2: FMatrix4x4): boolean;
var
  EPS:single = 0.000001;
begin
  result:= (abs(m1.i.x - m2.i.x) < EPS) and (abs(m1.i.y - m2.i.y) < EPS) and (abs(m1.i.z - m2.i.z) < EPS) and (abs(m1.i.w - m2.i.w) < EPS)
       and (abs(m1.j.x - m2.j.x) < EPS) and (abs(m1.j.y - m2.j.y) < EPS) and (abs(m1.j.z - m2.j.z) < EPS) and (abs(m1.j.w - m2.j.w) < EPS)
       and (abs(m1.k.x - m2.k.x) < EPS) and (abs(m1.k.y - m2.k.y) < EPS) and (abs(m1.k.z - m2.k.z) < EPS) and (abs(m1.k.w - m2.k.w) < EPS)
       and (abs(m1.c.x - m2.c.x) < EPS) and (abs(m1.c.y - m2.c.y) < EPS) and (abs(m1.c.z - m2.c.z) < EPS) and (abs(m1.c.w - m2.c.w) < EPS);
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

function v_add(var v1: FVector3; var v2: FVector3): FVector3;
begin
  result.x:=v1.x+v2.x;
  result.y:=v1.y+v2.y;
  result.z:=v1.z+v2.z;
end;

function v_sub(var v1: FVector3; var v2: FVector3): FVector3;
begin
  result.x:=v1.x-v2.x;
  result.y:=v1.y-v2.y;
  result.z:=v1.z-v2.z;
end;

function v_mul(var v: FVector3; n: single): FVector3;
begin
  result.x:=v.x*n;
  result.y:=v.y*n;
  result.z:=v.z*n;
end;

function v_crossproduct(var v1: FVector3; var v2: FVector3): FVector3;
begin
  result.x:=v1.y * v2.z - v1.z * v2.y;
  result.y:=v1.z * v2.x - v1.x * v2.z;
  result.z:=v1.x * v2.y - v1.y * v2.x;
end;

function v_dotproduct(var v1: FVector3; var v2: FVector3): single;
begin
  result:=v1.x*v2.x + v1.y*v2.y + v1.z*v2.z;
end;

function v_magnitude(var v: FVector3): single;
begin
  result:= sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
end;

function v_angle_between(var v1: FVector3; var v2: FVector3): single;
var
  mag1, mag2, angle_cos:single;
const
  EPS: single = 0.000001;
begin
  result:=0;
  mag1:=v_magnitude(v1);
  mag2:=v_magnitude(v2);

  if ( mag1 < EPS) or (mag2 < EPS) then exit;

  angle_cos := v_dotproduct(v1, v2) / (mag1*mag2);
  if ( angle_cos < -1 ) then begin
    angle_cos := -1;
  end else if ( angle_cos > 1) then begin
    angle_cos := 1;
  end;

  result:=arccos(angle_cos);
end;

function v_normalize(var v: FVector3): FVector3;
var
  mag:single;
begin
  mag:=v_magnitude(v);
  mag:=1/mag;
  result:=v_mul(v, mag);
end;

function m_mul(var m: FMatrix3x3; var v: FVector3): FVector3;
begin
  result.x:=m.i.x*v.x+m.i.y*v.y+m.i.z*v.z;
  result.y:=m.j.x*v.x+m.j.y*v.y+m.j.z*v.z;
  result.z:=m.k.x*v.x+m.k.y*v.y+m.k.z*v.z;
end;

function m_mul(var m: FMatrix4x4; n: single): FMatrix4x4;
begin
  result:=m;

  q_scale(m.i, n);
  q_scale(m.j, n);
  q_scale(m.k, n);
  q_scale(m.c, n);
end;

function m_mul(var m: FMatrix4x4; var q: Fquaternion): Fquaternion;
begin
  result.x:=m.i.x*q.x + m.i.y*q.y + m.i.z*q.z + m.i.w*q.w;
  result.y:=m.j.x*q.x + m.j.y*q.y + m.j.z*q.z + m.j.w*q.w;
  result.z:=m.k.x*q.x + m.k.y*q.y + m.k.z*q.z + m.k.w*q.w;
  result.w:=m.c.x*q.x + m.c.y*q.y + m.c.z*q.z + m.c.w*q.w;
end;

function m_mul(var m1: FMatrix4x4; var m2: FMatrix4x4): FMatrix4x4;
begin
  result.i.x := m1.i.x * m2.i.x + m1.j.x * m2.i.y + m1.k.x * m2.i.z + m1.c.x * m2.i.w;
  result.i.y := m1.i.y * m2.i.x + m1.j.y * m2.i.y + m1.k.y * m2.i.z + m1.c.y * m2.i.w;
  result.i.z := m1.i.z * m2.i.x + m1.j.z * m2.i.y + m1.k.z * m2.i.z + m1.c.z * m2.i.w;
  result.i.w := m1.i.w * m2.i.x + m1.j.w * m2.i.y + m1.k.w * m2.i.z + m1.c.w * m2.i.w;

  result.j.x := m1.i.x * m2.j.x + m1.j.x * m2.j.y + m1.k.x * m2.j.z + m1.c.x * m2.j.w;
  result.j.y := m1.i.y * m2.j.x + m1.j.y * m2.j.y + m1.k.y * m2.j.z + m1.c.y * m2.j.w;
  result.j.z := m1.i.z * m2.j.x + m1.j.z * m2.j.y + m1.k.z * m2.j.z + m1.c.z * m2.j.w;
  result.j.w := m1.i.w * m2.j.x + m1.j.w * m2.j.y + m1.k.w * m2.j.z + m1.c.w * m2.j.w;

  result.k.x := m1.i.x * m2.k.x + m1.j.x * m2.k.y + m1.k.x * m2.k.z + m1.c.x * m2.k.w;
  result.k.y := m1.i.y * m2.k.x + m1.j.y * m2.k.y + m1.k.y * m2.k.z + m1.c.y * m2.k.w;
  result.k.z := m1.i.z * m2.k.x + m1.j.z * m2.k.y + m1.k.z * m2.k.z + m1.c.z * m2.k.w;
  result.k.w := m1.i.w * m2.k.x + m1.j.w * m2.k.y + m1.k.w * m2.k.z + m1.c.w * m2.k.w;

  result.c.x := m1.i.x * m2.c.x + m1.j.x * m2.c.y + m1.k.x * m2.c.z + m1.c.x * m2.c.w;
  result.c.y := m1.i.y * m2.c.x + m1.j.y * m2.c.y + m1.k.y * m2.c.z + m1.c.y * m2.c.w;
  result.c.z := m1.i.z * m2.c.x + m1.j.z * m2.c.y + m1.k.z * m2.c.z + m1.c.z * m2.c.w;
  result.c.w := m1.i.w * m2.c.x + m1.j.w * m2.c.y + m1.k.w * m2.c.z + m1.c.w * m2.c.w;
end;

function m_mul4x3(var m1: FMatrix4x4; var m2: FMatrix4x4): FMatrix4x4;
begin
  result.i.x := m1.i.x * m2.i.x + m1.j.x * m2.i.y + m1.k.x * m2.i.z;
  result.i.y := m1.i.y * m2.i.x + m1.j.y * m2.i.y + m1.k.y * m2.i.z;
  result.i.z := m1.i.z * m2.i.x + m1.j.z * m2.i.y + m1.k.z * m2.i.z;
  result.i.w := 0;

  result.j.x := m1.i.x * m2.j.x + m1.j.x * m2.j.y + m1.k.x * m2.j.z;
  result.j.y := m1.i.y * m2.j.x + m1.j.y * m2.j.y + m1.k.y * m2.j.z;
  result.j.z := m1.i.z * m2.j.x + m1.j.z * m2.j.y + m1.k.z * m2.j.z;
  result.j.w := 0;

  result.k.x := m1.i.x * m2.k.x + m1.j.x * m2.k.y + m1.k.x * m2.k.z;
  result.k.y := m1.i.y * m2.k.x + m1.j.y * m2.k.y + m1.k.y * m2.k.z;
  result.k.z := m1.i.z * m2.k.x + m1.j.z * m2.k.y + m1.k.z * m2.k.z;
  result.k.w := 0;

  result.c.x := m1.i.x * m2.c.x + m1.j.x * m2.c.y + m1.k.x * m2.c.z + m1.c.x;
  result.c.y := m1.i.y * m2.c.x + m1.j.y * m2.c.y + m1.k.y * m2.c.z + m1.c.y;
  result.c.z := m1.i.z * m2.c.x + m1.j.z * m2.c.y + m1.k.z * m2.c.z + m1.c.z;
  result.c.w := 1;
end;

procedure m_setHPB(var m: FMatrix4x4; h: single; p: single; b: single);
var
  sh,sp,sb,ch,cp,cb:single;
  cc, cs,sc,ss:single;
begin
  sh := sin(h); ch := cos(h);
  sp := sin(p); cp := cos(p);
  sb := sin(b); cb := cos(b);

  cc := ch*cb; cs := ch*sb; sc := sh*cb; ss := sh*sb;

  m.i.x := cc-sp*ss; m.i.y := -cp*sb; m.i.z := sp*cs+sc; m.i.w:=0;
  m.j.x := sp*sc+cs; m.j.y :=  cp*cb; m.j.z := ss-sp*cc; m.j.w:=0;
  m.k.x := -cp*sh;   m.k.y :=  sp;    m.k.z := cp*ch;    m.k.w:=0;
  m.c.x:=0;          m.c.y:=0;        m.c.z:=0;          m.c.w:=1;

end;

procedure m_getHPB(var m: FMatrix4x4; var h: single; var p: single; var b: single);
var
  cy:single;
const
  EPS = 0.00001;
begin
  cy := sqrt(m.j.y*m.j.y + m.i.y*m.i.y);
  if (cy > EPS) then begin
      h := -arctan2(m.k.x, m.k.z);
      p := -arctan2(-m.k.y, cy);
      b := -arctan2(m.i.y, m.j.y);
  end else begin
      h := -arctan2(-m.i.z, m.i.x);
      p := -arctan2(-m.k.y, cy);
      b := 0;
 end;
end;

procedure m_setXYZ(var m: FMatrix4x4; var v: FVector3);
begin
  m_setHPB(m, -v.y, -v.x, -v.z);
end;

procedure m_getXYZ(var m: FMatrix4x4; var v: FVector3);
begin
  m_getHPB(m, v.y, v.x, v.z);
end;

procedure m_getXYZi(var m: FMatrix4x4; var v: FVector3);
begin
  m_getXYZ(m, v);
  v:=v_mul(v, -1);
end;

procedure m_translate_over(var m: FMatrix4x4; var v: FVector3);
begin
  m.c.x:=v.x;
  m.c.y:=v.y;
  m.c.z:=v.z;
end;

procedure m_get_translation(var m: FMatrix4x4; var v: FVector3);
begin
  v.x:=m.c.x;
  v.y:=m.c.y;
  v.z:=m.c.z;
end;

function m_invert43(var m: FMatrix4x4): FMatrix4x4;
var
  detinv:single;
begin

  detinv := ( m.i.x * ( m.j.y * m.k.z - m.j.z * m.k.y ) -
              m.i.y * ( m.j.x * m.k.z - m.j.z * m.k.x ) +
              m.i.z * ( m.j.x * m.k.y - m.j.y * m.k.x ) );

 detinv := 1 / detinv;

 result.i.x :=  detinv * ( m.j.y * m.k.z - m.j.z * m.k.y );
 result.i.y := -detinv * ( m.i.y * m.k.z - m.i.z * m.k.y );
 result.i.z :=  detinv * ( m.i.y * m.j.z - m.i.z * m.j.y );
 result.i.w := 0;

 result.j.x := -detinv * ( m.j.x * m.k.z - m.j.z * m.k.x );
 result.j.y :=  detinv * ( m.i.x * m.k.z - m.i.z * m.k.x );
 result.j.z := -detinv * ( m.i.x * m.j.z - m.i.z * m.j.x );
 result.j.w := 0;

 result.k.x :=  detinv * ( m.j.x * m.k.y - m.j.y * m.k.x );
 result.k.y := -detinv * ( m.i.x * m.k.y - m.i.y * m.k.x );
 result.k.z :=  detinv * ( m.i.x * m.j.y - m.i.y * m.j.x );
 result.k.w := 0;

 result.c.x := -( m.c.x * result.i.x + m.c.y * result.j.x + m.c.z * result.k.x );
 result.c.y := -( m.c.x * result.i.y + m.c.y * result.j.y + m.c.z * result.k.y );
 result.c.z := -( m.c.x * result.i.z + m.c.y * result.j.z + m.c.z * result.k.z );
 result.c.w := 1;
end;

procedure m_rotation(var m: FMatrix4x4; var q: Fquaternion);
var
  xx,yy,zz,xy,xz,yz,wx,wy,wz:single;
begin
  xx := q.x*q.x; yy := q.y*q.y; zz := q.z*q.z;
  xy := q.x*q.y; xz := q.x*q.z; yz := q.y*q.z;
  wx := q.w*q.x; wy := q.w*q.y; wz := q.w*q.z;

  m.i.x := 1 - 2 * ( yy + zz ); m.i.y :=     2 * ( xy - wz ); m.i.z :=     2 * ( xz + wy ); m.i.w := 0;
  m.j.x :=     2 * ( xy + wz ); m.j.y := 1 - 2 * ( xx + zz ); m.j.z :=     2 * ( yz - wx ); m.j.w := 0;
  m.k.x :=     2 * ( xz - wy ); m.k.y :=     2 * ( yz + wx ); m.k.z := 1 - 2 * ( xx + yy ); m.k.w := 0;
  m.c.x := 0;                   m.c.y := 0;                   m.c.z := 0;                   m.c.w := 1;
end;

procedure q_rotationYawPitchRoll(var q: Fquaternion; var ypr: FVector3);
var
  sy,cy,sp,cp,sr,cr:single;
begin
  sy := sin(ypr.x * 0.5);
  cy := cos(ypr.x * 0.5);
  sp := sin(ypr.y * 0.5);
  cp := cos(ypr.y * 0.5);
  sr := sin(ypr.z * 0.5);
  cr := cos(ypr.z * 0.5);

  q.x := sr * cp * cy - cr * sp * sy;
  q.y := cr * sp * cy + sr * cp * sy;
  q.z := cr * cp * sy - sr * sp * cy;
  q.w := cr * cp * cy + sr * sp * sy;
end;

procedure q_rotation(var q: Fquaternion; var m: FMatrix4x4);
var
  trace,s:single;
  biggest:integer;
const
  BIGGEST_I: integer = 0;
  BIGGEST_E: integer = 1;
  BIGGEST_A: integer = 2;

  TRACE_QZERO_TOLERANCE:single = 0.1;
begin
  trace := M.i.x + M.j.y + M.k.z;

  if (trace > 0) then begin
    s := sqrt(trace + 1);
    q.w := s * 0.5;
    s := 0.5 / s;
    q.x := (M.k.y - M.j.z) * s;
    q.y := (M.i.z - M.k.x) * s;
    q.z := (M.j.x - M.i.y) * s;
  end else begin
    if (M.i.x > M.j.y) then begin
      if (M.k.z > M.i.x) then begin
        biggest := BIGGEST_I;
      end else begin
        biggest := BIGGEST_A;
      end;
    end else begin
      if (M.k.z > M.i.x) then begin
        biggest := BIGGEST_I;
      end else begin
        biggest := BIGGEST_E;
      end;
    end;

    if biggest = BIGGEST_A then begin
      s := sqrt( M.i.x - (M.j.y + M.k.z) + 1);
      if (s > TRACE_QZERO_TOLERANCE) then begin
        q.x := s * 0.5;
        s := 0.5 / s;
        q.w := (M.k.y - M.j.z) * s;
        q.y := (M.i.y + M.j.x) * s;
        q.z := (M.i.z + M.k.x) * s;
      end else begin
        // I
        s := sqrt( M.k.z - (M.i.x + M.j.y) + 1);
        if (s > TRACE_QZERO_TOLERANCE) then begin
          q.z := s * 0.5;
          s := 0.5 / s;
          q.w := (M.j.x - M.i.y) * s;
          q.x := (M.k.x + M.i.z) * s;
          q.y := (M.k.y + M.j.z) * s;
        end else begin
          // E
          s := sqrt( M.j.y - (M.k.z + M.i.x) + 1);
          if (s > TRACE_QZERO_TOLERANCE) then begin
            q.y := s * 0.5;
            s := 0.5 / s;
            q.w := (M.i.z - M.k.x) * s;
            q.z := (M.j.z + M.k.y) * s;
            q.x := (M.j.x + M.i.y) * s;
          end;
        end;
      end;

    end else if biggest = BIGGEST_E then begin
      s := sqrt( M.j.y - (M.k.z + M.i.x) + 1);
      if (s > TRACE_QZERO_TOLERANCE) then begin
        q.y := s * 0.5;
        s := 0.5 / s;
        q.w := (M.i.z - M.k.x) * s;
        q.z := (M.j.z + M.k.y) * s;
        q.x := (M.j.x + M.i.y) * s;
      end else begin
        // I
        s := sqrt( M.k.z - (M.i.x + M.j.y) + 1);
        if (s > TRACE_QZERO_TOLERANCE) then begin
          q.z := s * 0.5;
          s := 0.5 / s;
          q.w := (M.j.x - M.i.y) * s;
          q.x := (M.k.x + M.i.z) * s;
          q.y := (M.k.y + M.j.z) * s;
        end else begin
          // A
          s := sqrt( M.i.x - (M.j.y + M.k.z) + 1);
          if (s > TRACE_QZERO_TOLERANCE) then begin
            q.x := s * 0.5;
            s := 0.5 / s;
            q.w := (M.k.y - M.j.z) * s;
            q.y := (M.i.y + M.j.x) * s;
            q.z := (M.i.z + M.k.x) * s;
          end;
        end;
      end;

    end else if biggest = BIGGEST_I then begin
      s := sqrt( M.k.z - (M.i.x + M.j.y) + 1);
      if (s > TRACE_QZERO_TOLERANCE) then begin
        q.z := s * 0.5;
        s := 0.5 / s;
        q.w := (M.j.x - M.i.y) * s;
        q.x := (M.k.x + M.i.z) * s;
        q.y := (M.k.y + M.j.z) * s;
      end else begin
        // A
        s := sqrt( M.i.x - (M.j.y + M.k.z) + 1);
        if (s > TRACE_QZERO_TOLERANCE) then begin
          q.x := s * 0.5;
          s := 0.5 / s;
          q.w := (M.k.y - M.j.z) * s;
          q.y := (M.i.y + M.j.x) * s;
          q.z := (M.i.z + M.k.x) * s;
        end else begin
          // E
          s := sqrt( M.j.y - (M.k.z + M.i.x) + 1);
          if (s > TRACE_QZERO_TOLERANCE) then begin
            q.y := s * 0.5;
            s := 0.5 / s;
            q.w := (M.i.z - M.k.x) * s;
            q.z := (M.j.z + M.k.y) * s;
            q.x := (M.j.x + M.i.y) * s;
	  end;
        end;
      end;
    end;
  end;
end;

procedure q_set(var q: Fquaternion; x: single; y: single; z: single; w: single);
begin
  q.x:=x;
  q.y:=y;
  q.z:=z;
  q.w:=w;
end;

procedure q_scale(var q: Fquaternion; n: single);
begin
  q.x:=q.x*n;
  q.y:=q.y*n;
  q.z:=q.z*n;
  q.w:=q.w*n;
end;

function distance_between(var point1: FVector3; var point2: FVector3): single;
var
  dx, dy, dz:single;
begin
  dx:=point2.x-point1.x;
  dy:=point2.y-point1.y;
  dz:=point2.z-point1.z;

  result:=sqrt(dx*dx+dy*dy+dz*dz);
end;

function rotation_between(var src: FVector3; var dst: FVector3): FMatrix4x4;
var
  v:FVector3;
  c,k:single;
const
  EPS:single=0.000001;
begin
  src:=v_normalize(src);
  dst:=v_normalize(dst);

  v:=v_crossproduct(src, dst);
  c:=v_dotproduct(src, dst);

  m_identity(result);
  if abs(c-1) < EPS then begin
    // vectors are almost the same
  end else if abs(c+1) < EPS then begin
    //vectors are collinear and have opposite directions
    m_mul(result, -1);
  end else begin
    k := 1/(1 + c);

    result.i.x:=v.x * v.x * k + c;     result.i.y:=v.x * v.y * k + v.z;   result.i.z:=v.x * v.z * k - v.y;
    result.j.x:=v.y * v.x * k - v.z;   result.j.y:=v.y * v.y * k + c;     result.j.z:=v.y * v.z * k + v.x;
    result.k.x:=v.z * v.x * k + v.y;   result.k.y:=v.z * v.y * k - v.x;   result.k.z:=v.z * v.z * k + c;


    {result.i.x:=v.x * v.x * k + c;     result.i.y:=v.y * v.x * k - v.z;   result.i.z:=v.z * v.x * k + v.y;
    result.j.x:=v.x * v.y * k + v.z;   result.j.y:=v.y * v.y * k + c;     result.j.z:=v.z * v.y * k - v.x;
    result.k.x:=v.x * v.z * k - v.y;   result.k.y:=v.y * v.z * k + v.x;   result.k.z:=v.z * v.z * k + c; }
  end;
end;

procedure q_slerp(var r: Fquaternion; q0: Fquaternion; q1: Fquaternion; tm: single);
var
  Scale0,Scale1,sign,cosom:single;
  omega,i_sinom,t_omega:single;
const
  EPS: single = 0.00001;
begin
  cosom := (q0.w * q1.w) + (q0.x * q1.x) + (q0.y * q1.y) + (q0.z * q1.z);
  if (cosom < 0) then begin
    cosom := -cosom;
    sign := -1;
  end else begin
    sign := 1;
  end;

  if ( (1 - cosom) > EPS ) then begin
    omega := arccos(cosom);
    i_sinom := 1 / sin(omega);
    t_omega := tm*omega;
    Scale0 := sin(omega - t_omega) * i_sinom;
    Scale1 := sin(t_omega) * i_sinom;
  end else begin
    Scale0 := 1 - tm;
    Scale1 := tm;
  end;
  Scale1 := Scale1 * sign;

  r.x := Scale0 * q0.x + Scale1 * q1.x;
  r.y := Scale0 * q0.y + Scale1 * q1.y;
  r.z := Scale0 * q0.z + Scale1 * q1.z;
  r.w := Scale0 * q0.w + Scale1 * q1.w;

end;

end.


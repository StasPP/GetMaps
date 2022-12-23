unit AsphyreMath;
//---------------------------------------------------------------------------
// AsphyreMath.pas                                      Modified: 25-Ago-2005
// Copyright (c) 2000 - 2005  Afterwarp Interactive              Version 1.02
//---------------------------------------------------------------------------
// Changes since v1.00:
//  + Added directive for automatic inlining for Delphi 2005.
//    Please let me know if there are any problems with this.
//  * Fixed VecAngle3 and VecAngle4 routines for parallel vectors.
//    Thanks to Steffen Norgaard for pointing this!
//---------------------------------------------------------------------------
// The contents of this file are subject to the Mozilla Public License
// Version 1.1 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS"
// basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
// License for the specific language governing rights and limitations
// under the License.
//--------------------------------------------------------------------------
interface

//--------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, Math, AsphyreDef;

//---------------------------------------------------------------------------
{$IFDEF VER170}
{$INLINE AUTO} // Enable auto-inline in Delphi 2005
{$ENDIF}

//--------------------------------------------------------------------------
type
 TPoint3 = record
  x, y, z: Single;
 end;

//---------------------------------------------------------------------------
 PVector4 = ^TVector4;
 TVector4 = record
 case Integer of
  0: (x, y, z, w: Single);
  1: (v: TPoint3; w_reserved: Single);
 end;

//---------------------------------------------------------------------------
 TMatrix3 = array[0..2, 0..2] of Single;
 PMatrix4 = ^TMatrix4;
 TMatrix4 = array[0..3, 0..3] of Single;

//---------------------------------------------------------------------------
 TQuadPoints3 = array[0..3] of TPoint3;

//--------------------------------------------------------------------------
const
 ZeroVector4: TVector4 = (x: 0.0; y: 0.0; z: 0.0; w: 1.0);
 VecAxisX4  : TVector4 = (x: 1.0; y: 0.0; z: 0.0; w: 1.0);
 VecAxisY4  : TVector4 = (x: 0.0; y: 1.0; z: 0.0; w: 1.0);
 VecAxisZ4  : TVector4 = (x: 0.0; y: 0.0; z: 1.0; w: 1.0);

 IdentityMatrix: TMatrix4 = ((1.0, 0.0, 0.0, 0.0), (0.0, 1.0, 0.0, 0.0),
  (0.0, 0.0, 1.0, 0.0), (0.0, 0.0, 0.0, 1.0));

 ZeroMatrix: TMatrix4 = ((0.0, 0.0, 0.0, 0.0), (0.0, 0.0, 0.0, 0.0),
  (0.0, 0.0, 0.0, 0.0), (0.0, 0.0, 0.0, 0.0));

 ZeroVector3: TPoint3 = (x: 0.0; y: 0.0; z: 0.0);
 VecAxisX3  : TPoint3 = (x: 1.0; y: 0.0; z: 0.0);
 VecAxisY3  : TPoint3 = (x: 0.0; y: 1.0; z: 0.0);
 VecAxisZ3  : TPoint3 = (x: 0.0; y: 0.0; z: 1.0);

 IdentityQuaternion: TVector4 = (x: 0.0; y: 0.0; z: 0.0; w: 1.0);

//--------------------------------------------------------------------------
function Point3(x, y, z: Real): TPoint3;
function QuadPoints3(const p0, p1, p2, p3: TPoint3): TQuadPoints3;

//--------------------------------------------------------------------------
// compose TVector4 with three given components
function Vector3(x, y, z: Single): TVector4;

// compose TVector4 with four given components
function Vector4(x, y, z, w: Single): TVector4;

// convert 3-variable to 4-variable vector
function Vec3to4(const Point: TPoint3): TVector4;

// convert 4-variable to 3-variable vector (dividing by W)
function Vec4to3(const Vector: TVector4): TPoint3;

// convert 4-variable to 3-variable vector (ignore W component)
function Vec4to3NoW(const Vector: TVector4): TPoint3;

// vector negation
function VecNeg4(const v: TVector4): TVector4;

// vector magnitude
function VecAbs4(const v: TVector4): Real;

// vector multiplication by a scalar
function VecScale4(const v: TVector4; k: Real): TVector4;

// verifies if the vector is zero vector
function IsZeroVec4(const v: TVector4): Boolean;

// verifies whether two vectors match
function SameVec4(const a, b: TVector4): Boolean;

// vector normalization
function VecNorm4(const v: TVector4): TVector4;

// vector addition
function VecAdd4(const a, b: TVector4): TVector4;

// vector substraction
function VecSub4(const a, b: TVector4): TVector4;

// vector from second point to the first one
function VecToFrom4(const a, b: TVector4): TVector4;

// distance between two points
function VecDist4(const a, b: TVector4): Real;

// vector dot product
function VecDot4(const a, b: TVector4): Real;

// angle between two vectors [0..pi]
function VecAngle4(const a, b: TVector4): Real;

// projected vector parallel to n
function VecParallel4(const v, n: TVector4): TVector4;

// projected vector perpendicular to n
function VecPerp4(const v, n: TVector4): TVector4;

// vector cross product
function VecCross4(const a, b: TVector4): TVector4;

// vector string representation
function VecStr4(const v: TVector4): string;

//--------------------------------------------------------------------------
// vector negation
function VecNeg3(const v: TPoint3): TPoint3;

// vector magnitude
function VecAbs3(const v: TPoint3): Real;

// vector multiplication by a scalar
function VecScale3(const v: TPoint3; k: Real): TPoint3;

// verifies if the vector is zero vector
function IsZeroVec3(const v: TPoint3): Boolean;

// vector normalization
function VecNorm3(const v: TPoint3): TPoint3;

// vector addition
function VecAdd3(const a, b: TPoint3): TPoint3;

// vector substraction
function VecSub3(const a, b: TPoint3): TPoint3;

// vector from second point to the first one
function VecToFrom3(const a, b: TPoint3): TPoint3;

// distance between two points
function VecDist3(const a, b: TPoint3): Real;

// vector dot product
function VecDot3(const a, b: TPoint3): Real;

// angle between two vectors [0..pi]
function VecAngle3(const a, b: TPoint3): Real;

// projected vector parallel to n
function VecParallel3(const v, n: TPoint3): TPoint3;

// projected vector perpendicular to n
function VecPerp3(const v, n: TPoint3): TPoint3;

// vector cross product
function VecCross3(const a, b: TPoint3): TPoint3;

// vector string representation
function VecStr3(const v: TPoint3): string;

function SameVec3(const a, b: TPoint3; const Epsilon: Real = 0.000001): Boolean;

//--------------------------------------------------------------------------
// returns the 3x3 sub-matrix, excluding lines "i" and "j"
function SubMatrix3(const m: TMatrix4; i, j: Integer): TMatrix3;

// returns the determinant of the 3x3 matrix
function MatDtm3(const m: TMatrix3): Real;

// returns true if two matrices are similar
function SameMatrix(const a, b: TMatrix4): Boolean;

// matrix transposition
function MatTrans(const m: TMatrix4): TMatrix4;

// multiplying a matrix with a scalar
function MatScalar(const m: TMatrix4; k: Real): TMatrix4;

// matrix addition
function MatAdd(const a, b: TMatrix4): TMatrix4;

// matrix substraction
function MatSub(const a, b: TMatrix4): TMatrix4;

// multiplying two matrices
function MatMul(const a, b: TMatrix4): TMatrix4;

// matrix string representation
function MatStr(const m: TMatrix4): string;

// multiplying a vector and a matrix
function MatVecMul(const v: TVector4; const m: TMatrix4): TVector4;

// rotating about the x-axis in 3D
function MatRotateX(Angle: Real): TMatrix4;

// rotating about the y-axis in 3D
function MatRotateY(Angle: Real): TMatrix4;

// rotating about the z-axis in 3D
function MatRotateZ(Angle: Real): TMatrix4;

// rotating about an arbitrary axis in 3D
function MatRotate(const n: TVector4; Theta: Real): TMatrix4;

// scaling along cardinal axes
function MatScale(const k: TVector4): TMatrix4;

// reflection
function MatReflect(const n: TVector4): TMatrix4;

// translation matrix
function MatTransl(const n: TVector4): TMatrix4;

// the determinant of the matrix
function MatDtm(const m: TMatrix4): Real;

// perspective projection
function MatProject(d: Real): TMatrix4;

// the inverse matrix
function MatInverse(const m: TMatrix4): TMatrix4;

// convert 4D matrix to 3D matrix
function Vec4Dto3D(const v: TVector4): TVector4;

// returns a matrix for looking at the specified location
function MatrixLookAtLH(const Origin, Target, Roof: TVector4): TMatrix4;

//--------------------------------------------------------------------------
// Magnitude of quaternion
function QuaternionAbs(const q: TVector4): Real;

// Conjugate of quaternion
function QuaternionConj(const q: TVector4): TVector4;

// The inverse of quaternion
function QuaternionInv(const q: TVector4): TVector4;

// Quaternion multiplication (Cross Product)
function QuaternionMul(const q1, q2: TVector4): TVector4;

// Quaternion difference
function QuaternionDif(const q1, q2: TVector4): TVector4;

// Quaternion 'dot product'
function QuaternionDot(const q1, q2: TVector4): Real;

// The normalization of a quaternion
function QuaternionNorm(const q: TVector4): TVector4;

// Multiplying a quaternion by a scalar
function QuaternionScale(const q: TVector4; k: Real): TVector4;

// Interpolation between two quaternions
function QuaternionSlerp(const q1, q2: TVector4; Theta: Single): TVector4;

//--------------------------------------------------------------------------
// convert euler angles to matrix
function EulerToMatrix3(const EulerMtx: TPoint3): TMatrix3;

// convert matrix to euler angles
function MatrixToEuler3(const Matrix: TMatrix3): TPoint3;

// convert quaternion to matrix
function QuaternionToMatrix3(const q: TVector4): TMatrix3;

// convert matrix to quaternion
function MatrixToQuaternion3(const Matrix: TMatrix3): TVector4;

//--------------------------------------------------------------------------
implementation

//--------------------------------------------------------------------------
const
 AsphyreEpsilon = 0.0000001;

//--------------------------------------------------------------------------
function Point3(x, y, z: Real): TPoint3;
begin
 Result.x:= x;
 Result.y:= y;
 Result.z:= z;
end;

//---------------------------------------------------------------------------
function QuadPoints3(const p0, p1, p2, p3: TPoint3): TQuadPoints3;
begin
 Result[0]:= p0;
 Result[1]:= p1;
 Result[2]:= p2;
 Result[3]:= p3;
end;

//--------------------------------------------------------------------------
function Vector3(x, y, z: Single): TVector4;
begin
 Result.x:= x;
 Result.y:= y;
 Result.z:= z;
 Result.w:= 1.0;
end;

//--------------------------------------------------------------------------
function Vector4(x, y, z, w: Single): TVector4;
begin
 Result.x:= x;
 Result.y:= y;
 Result.z:= z;
 Result.w:= w;
end;

//--------------------------------------------------------------------------
function Vec3to4(const Point: TPoint3): TVector4;
begin
 Result.x:= Point.x;
 Result.y:= Point.y;
 Result.z:= Point.z;
 Result.w:= 1.0;
end;

//--------------------------------------------------------------------------
function Vec4to3(const Vector: TVector4): TPoint3;
begin
 Result.x:= Vector.x / Vector.w;
 Result.y:= Vector.y / Vector.w;
 Result.z:= Vector.z / Vector.w;
end;

//--------------------------------------------------------------------------
function Vec4to3NoW(const Vector: TVector4): TPoint3;
begin
 Result.x:= Vector.x;
 Result.y:= Vector.y;
 Result.z:= Vector.z;
end;

//--------------------------------------------------------------------------
function VecStr4(const v: TVector4): string;
begin
 Result:= '(x: ' + Format('%1.2f', [v.x]) + ', y: ' + Format('%1.2f', [v.y]) +
  ', z: ' + Format('%1.2f', [v.z]) + ')';
end;

//--------------------------------------------------------------------------
function SameVec4(const a, b: TVector4): Boolean;
begin
 Result:= (Abs(a.x - b.x) < AsphyreEpsilon)and
  (Abs(a.y - b.y) < AsphyreEpsilon)and(Abs(a.z - b.z) < AsphyreEpsilon);
end;

//--------------------------------------------------------------------------
function VecNeg4(const v: TVector4): TVector4;
begin
 Result.x:= -v.x;
 Result.y:= -v.y;
 Result.z:= -v.z;
 Result.w:= v.w;
end;

//--------------------------------------------------------------------------
function VecAbs4(const v: TVector4): Real;
begin
 Result:= Sqrt(Sqr(v.x) + Sqr(v.y) + Sqr(v.z));
end;

//--------------------------------------------------------------------------
function VecScale4(const v: TVector4; k: Real): TVector4;
begin
 Result.x:= v.x * k;
 Result.y:= v.y * k;
 Result.z:= v.z * k;
 Result.w:= v.w;
end;

//--------------------------------------------------------------------------
function IsZeroVec4(const v: TVector4): Boolean;
begin
 Result:= (v.x = 0.0)and(v.y = 0.0)and(v.z = 0.0);
end;

//--------------------------------------------------------------------------
function VecNorm4(const v: TVector4): TVector4;
begin
 if (not IsZeroVec4(v)) then
  Result:= VecScale4(v, 1.0 / VecAbs4(v))
   else Result:= ZeroVector4;
end;

//--------------------------------------------------------------------------
function VecAdd4(const a, b: TVector4): TVector4;
begin
 Result.x:= a.x + b.x;
 Result.y:= a.y + b.y;
 Result.z:= a.z + b.z;
 Result.w:= 1.0;
end;

//--------------------------------------------------------------------------
function VecSub4(const a, b: TVector4): TVector4;
begin
 Result.x:= a.x - b.x;
 Result.y:= a.y - b.y;
 Result.z:= a.z - b.z;
 Result.w:= 1.0;
end;

//--------------------------------------------------------------------------
function VecToFrom4(const a, b: TVector4): TVector4;
begin
 Result:= VecSub4(a, b);
end;

//--------------------------------------------------------------------------
function VecDist4(const a, b: TVector4): Real;
begin
 Result:= VecAbs4(VecSub4(b, a));
end;

//--------------------------------------------------------------------------
function VecDot4(const a, b: TVector4): Real;
begin
 Result:= (a.x * b.x) + (a.y * b.y) + (a.z * b.z);
end;

//--------------------------------------------------------------------------
function VecAngle4(const a, b: TVector4): Real;
var
 v: Real;
begin
 v:= VecDot4(a, b) / (VecAbs4(a) * VecAbs4(b));

 if (v < -1.0) then v:= -1.0
  else if (v > 1.0) then v:= 1.0;

 Result:= ArcCos(v);
end;

//--------------------------------------------------------------------------
function VecParallel4(const v, n: TVector4): TVector4;
begin
 Result:= VecScale4(n, VecDot4(v, n) / Sqr(VecAbs4(n)));
end;

//--------------------------------------------------------------------------
function VecPerp4(const v, n: TVector4): TVector4;
begin
 Result:= VecSub4(v, VecParallel4(v, n));
end;

//--------------------------------------------------------------------------
function VecCross4(const a, b: TVector4): TVector4;
begin
 Result.x:= (a.y * b.z) - (a.z * b.y);
 Result.y:= (a.z * b.x) - (a.x * b.z);
 Result.z:= (a.x * b.y) - (a.y * b.x);
 Result.w:= 1.0;
end;

//--------------------------------------------------------------------------
function VecStr3(const v: TPoint3): string;
begin
 Result:= '(x: ' + Format('%1.2f', [v.x]) + ', y: ' + Format('%1.2f', [v.y]) +
  ', z: ' + Format('%1.2f', [v.z]) + ')';
end;

//--------------------------------------------------------------------------
function VecNeg3(const v: TPoint3): TPoint3;
begin
 Result.x:= -v.x;
 Result.y:= -v.y;
 Result.z:= -v.z;
end;

//--------------------------------------------------------------------------
function VecAbs3(const v: TPoint3): Real;
begin
 Result:= Sqrt(Sqr(v.x) + Sqr(v.y) + Sqr(v.z));
end;

//--------------------------------------------------------------------------
function VecScale3(const v: TPoint3; k: Real): TPoint3;
begin
 Result.x:= v.x * k;
 Result.y:= v.y * k;
 Result.z:= v.z * k;
end;

//--------------------------------------------------------------------------
function IsZeroVec3(const v: TPoint3): Boolean;
begin
 Result:= (v.x = 0.0)and(v.y = 0.0)and(v.z = 0.0);
end;

//--------------------------------------------------------------------------
function VecNorm3(const v: TPoint3): TPoint3;
begin
 if (not IsZeroVec3(v)) then
  Result:= VecScale3(v, 1.0 / VecAbs3(v))
   else Result:= ZeroVector3;
end;

//--------------------------------------------------------------------------
function VecAdd3(const a, b: TPoint3): TPoint3;
begin
 Result.x:= a.x + b.x;
 Result.y:= a.y + b.y;
 Result.z:= a.z + b.z;
end;

//--------------------------------------------------------------------------
function VecSub3(const a, b: TPoint3): TPoint3;
begin
 Result.x:= a.x - b.x;
 Result.y:= a.y - b.y;
 Result.z:= a.z - b.z;
end;

//--------------------------------------------------------------------------
function VecToFrom3(const a, b: TPoint3): TPoint3;
begin
 Result:= VecSub3(a, b);
end;

//--------------------------------------------------------------------------
function VecDist3(const a, b: TPoint3): Real;
begin
 Result:= VecAbs3(VecSub3(b, a));
end;

//--------------------------------------------------------------------------
function VecDot3(const a, b: TPoint3): Real;
begin
 Result:= (a.x * b.x) + (a.y * b.y) + (a.z * b.z);
end;

//--------------------------------------------------------------------------
function VecAngle3(const a, b: TPoint3): Real;
var
 v: Real;
begin
 v:= VecDot3(a, b) / (VecAbs3(a) * VecAbs3(b));

 if (v < -1.0) then v:= -1.0
  else if (v > 1.0) then v:= 1.0;

 Result:= ArcCos(v);
end;

//--------------------------------------------------------------------------
function VecParallel3(const v, n: TPoint3): TPoint3;
begin
 Result:= VecScale3(n, VecDot3(v, n) / Sqr(VecAbs3(n)));
end;

//--------------------------------------------------------------------------
function VecPerp3(const v, n: TPoint3): TPoint3;
begin
 Result:= VecSub3(v, VecParallel3(v, n));
end;

//--------------------------------------------------------------------------
function VecCross3(const a, b: TPoint3): TPoint3;
begin
 Result.x:= (a.y * b.z) - (a.z * b.y);
 Result.y:= (a.z * b.x) - (a.x * b.z);
 Result.z:= (a.x * b.y) - (a.y * b.x);
end;

//--------------------------------------------------------------------------
function SameVec3(const a, b: TPoint3; const Epsilon: Real = 0.000001): Boolean;
begin
 Result:= (Abs(a.x - b.x) < Epsilon)and(Abs(a.y - b.y) < Epsilon)and
  (Abs(a.z - b.z) < Epsilon);
end;

//--------------------------------------------------------------------------
function SubMatrix3(const m: TMatrix4; i, j: Integer): TMatrix3;
var
 iOut, jOut: Integer;
 iIn, jIn: Integer;
begin
 for iOut:= 0 to 2 do
  for jOut:= 0 to 2 do
   begin
    iIn:= iOut;
    if (iOut >= i) then Inc(iIn);

    jIn:= jOut;
    if (jOut >= j) then Inc(jIn);

    Result[iOut, jOut]:= m[iIn, jIn];
   end;
end;

//--------------------------------------------------------------------------
function MatDtm3(const m: TMatrix3): Real;
begin
 Result:= m[0, 0] * (m[1, 1] * m[2, 2] - m[2, 1] * m[1, 2]) - m[0, 1] *
  (m[1, 0] * m[2, 2] - m[2, 0] * m[1, 2]) + m[0, 2] * (m[1, 0] * m[2, 1] -
  m[2, 0] * m[1, 1]);
end;

//--------------------------------------------------------------------------
function SameMatrix(const a, b: TMatrix4): Boolean;
var
 i, j: Integer;
begin
 for j:= 0 to 3 do
  for i:= 0 to 3 do
   if (a[j, i] <> b[j, i]) then
    begin
     Result:= False;
     Exit;
    end;

 Result:= True;
end;

//--------------------------------------------------------------------------
function MatTrans(const m: TMatrix4): TMatrix4;
var
 i, j: Integer;
begin
 for i:= 0 to 3 do
  for j:= 0 to 3 do
   Result[i, j]:= m[j, i];
end;

//--------------------------------------------------------------------------
function MatScalar(const m: TMatrix4; k: Real): TMatrix4;
var
 i, j: Integer;
begin
 for i:= 0 to 3 do
  for j:= 0 to 3 do
   Result[i, j]:= m[i, j] * k;
end;

//--------------------------------------------------------------------------
function MatAdd(const a, b: TMatrix4): TMatrix4;
var
 i, j: Integer;
begin
 for i:= 0 to 3 do
  for j:= 0 to 3 do
   Result[i, j]:= a[i, j] + b[i, j];
end;

//--------------------------------------------------------------------------
function MatSub(const a, b: TMatrix4): TMatrix4;
var
 i, j: Integer;
begin
 for i:= 0 to 3 do
  for j:= 0 to 3 do
   Result[i, j]:= a[i, j] - b[i, j];
end;

//--------------------------------------------------------------------------
function MatMul(const a, b: TMatrix4): TMatrix4;
var
 i, j, k: Integer;
 Aux: Real;
begin
 for i:= 0 to 3 do
  for j:= 0 to 3 do
   begin
    Aux:= 0.0;
    for k:= 0 to 3 do
     Aux:= Aux + (a[i, k] * b[k, j]);

    Result[i, j]:= Aux;
   end;
end;

//--------------------------------------------------------------------------
function MatStr(const m: TMatrix4): string;
var
 s: string;
 i, j: Integer;
begin
 s:= '{';
 for i:= 0 to 3 do
  begin
   s:= s + '(';
   for j:= 0 to 3 do
    begin
     s:= s + Format('%1.2f', [m[i, j]]);
     if (j < 2) then s:= s + ', ';
    end;
   s:= s + ')';
  end;
 Result:= s + '}';
end;

//--------------------------------------------------------------------------
function MatVecMul(const v: TVector4; const m: TMatrix4): TVector4;
begin
 Result.x:= (v.x * m[0, 0]) + (v.y * m[1, 0]) + (v.z * m[2, 0]) + (v.w * m[3, 0]);
 Result.y:= (v.x * m[0, 1]) + (v.y * m[1, 1]) + (v.z * m[2, 1]) + (v.w * m[3, 1]);
 Result.z:= (v.x * m[0, 2]) + (v.y * m[1, 2]) + (v.z * m[2, 2]) + (v.w * m[3, 2]);
 Result.w:= (v.x * m[0, 3]) + (v.y * m[1, 3]) + (v.z * m[2, 3]) + (v.w * m[3, 3]);
end;

//--------------------------------------------------------------------------
function MatRotateX(Angle: Real): TMatrix4;
begin
 Result:= IdentityMatrix;
 Result[1, 1]:= Cos(Angle);
 Result[1, 2]:= Sin(Angle);
 Result[2, 1]:= -Sin(Angle);
 Result[2, 2]:= Cos(Angle);
end;

//--------------------------------------------------------------------------
function MatRotateY(Angle: Real): TMatrix4;
begin
 Result:= IdentityMatrix;
 Result[0, 0]:= Cos(Angle);
 Result[0, 2]:= -Sin(Angle);
 Result[2, 0]:= Sin(Angle);
 Result[2, 2]:= Cos(Angle);
end;

//--------------------------------------------------------------------------
function MatRotateZ(Angle: Real): TMatrix4;
begin
 Result:= IdentityMatrix;
 Result[0, 0]:= Cos(Angle);
 Result[0, 1]:= Sin(Angle);
 Result[1, 0]:= -Sin(Angle);
 Result[1, 1]:= Cos(Angle);
end;

//--------------------------------------------------------------------------
function MatRotate(const n: TVector4; Theta: Real): TMatrix4;
var
 CosTh, iCosTh, SinTh: Real;
 xy, xz, yz, xSin, ySin, zSin: Real;
begin
 CosTh := Cos(Theta);
 iCosTh:= 1.0 - CosTh;
 SinTh := Sin(Theta);
 xy    := n.x * n.y * iCosTh;
 xz    := n.x * n.z * iCosTh;
 yz    := n.y * n.z * iCosTh;
 xSin  := n.x * SinTh;
 ySin  := n.y * SinTh;
 zSin  := n.z * SinTh;

 Result:= IdentityMatrix;
 Result[0, 0]:= (Sqr(n.x) * iCosTh) + CosTh;
 Result[0, 1]:= xy + zSin;
 Result[0, 2]:= xz - ySin;
 Result[1, 0]:= xy - zSin;
 Result[1, 1]:= (Sqr(n.y) * iCosTh) + CosTh;
 Result[1, 2]:= yz + xSin;
 Result[2, 0]:= xz + ySin;
 Result[2, 1]:= yz - xSin;
 Result[2, 2]:= (Sqr(n.z) * iCosTh) + CosTh;
end;

//--------------------------------------------------------------------------
function MatScale(const k: TVector4): TMatrix4;
begin
 Result:= IdentityMatrix;
 Result[0, 0]:= k.x;
 Result[1, 1]:= k.y;
 Result[2, 2]:= k.z;
 Result[3, 3]:= k.w;
end;

//--------------------------------------------------------------------------
function MatReflect(const n: TVector4): TMatrix4;
var
 xy, yz, xz: Real;
begin
 xy:= -2.0 * n.x * n.y;
 xz:= -2.0 * n.x * n.z;
 yz:= -2.0 * n.y * n.z;

 Result:= IdentityMatrix;
 Result[0, 0]:= 1.0 - (2.0 * Sqr(n.x));
 Result[0, 1]:= xy;
 Result[0, 2]:= xz;
 Result[1, 0]:= xy;
 Result[1, 1]:= 1.0 - (2.0 * Sqr(n.y));
 Result[1, 2]:= yz;
 Result[2, 0]:= xz;
 Result[2, 1]:= yz;
 Result[2, 2]:= 1.0 - (2.0 * Sqr(n.z));
end;

//--------------------------------------------------------------------------
function MatTransl(const n: TVector4): TMatrix4;
begin
 Result:= IdentityMatrix;
 Result[3, 0]:= n.x;
 Result[3, 1]:= n.y;
 Result[3, 2]:= n.z;
end;

//--------------------------------------------------------------------------
function MatProject(d: Real): TMatrix4;
begin
 Result:= IdentityMatrix;
 Result[2, 3]:= 1.0 / d;
 Result[3, 3]:= 0.0;
end;

//--------------------------------------------------------------------------
function MatDtm(const m: TMatrix4): Real;
var
 Aux : TMatrix3;
 Dtm : Real;
 Sign: Integer;
 i   : Integer;
begin
 Sign  := 1;
 Result:= 0;
 for i:= 0 to 3 do
  begin
   Aux:= SubMatrix3(m, i, 0);
   Dtm:= MatDtm3(Aux);

   Result:= Result + (Sign * m[i, 0] * Dtm);

   Sign:= -Sign;
  end;
end;

//--------------------------------------------------------------------------
function MatInverse(const m: TMatrix4): TMatrix4;
var
 Dtm4: Real;
 i, j: Integer;
 Sign: Integer;
 Aux : TMatrix3;
begin
 Dtm4:= MatDtm(m);
 if (Dtm4 = 0.0) then
  begin
   Result:= IdentityMatrix;
   Exit;
  end;

 for i:= 0 to 3 do
  for j:= 0 to 3 do
   begin
    Sign:= 1 - ((i + j) mod 2) * 2;
    Aux := SubMatrix3(m, i, j);
    Result[j, i]:= (Sign * MatDtm3(Aux)) / Dtm4;
   end;
end;

//--------------------------------------------------------------------------
function Vec4Dto3D(const v: TVector4): TVector4;
begin
 Result.x:= v.x / v.w;
 Result.y:= v.y / v.w;
 Result.z:= v.z / v.w;
end;

//--------------------------------------------------------------------------
function MatrixLookAtLH(const Origin, Target, Roof: TVector4): TMatrix4;
var
 xAxis, yAxis, zAxis: TVector4;
begin
 zAxis:= VecNorm4(VecSub4(Target, Origin));
 xAxis:= VecNorm4(VecCross4(Roof, zAxis));
 yAxis:= VecCross4(zAxis, xAxis);

 Result[0, 0]:= xAxis.x;
 Result[0, 1]:= yAxis.x;
 Result[0, 2]:= zAxis.x;
 Result[0, 3]:= 0.0;

 Result[1, 0]:= xAxis.y;
 Result[1, 1]:= yAxis.y;
 Result[1, 2]:= zAxis.y;
 Result[1, 3]:= 0.0;

 Result[2, 0]:= xAxis.z;
 Result[2, 1]:= yAxis.z;
 Result[2, 2]:= zAxis.z;
 Result[2, 3]:= 0.0;

 Result[3, 0]:= -VecDot4(xAxis, Origin);
 Result[3, 1]:= -VecDot4(yAxis, Origin);
 Result[3, 2]:= -VecDot4(zAxis, Origin);
 Result[3, 3]:= 1.0;
end;

//--------------------------------------------------------------------------
function EulerToMatrix3(const EulerMtx: TPoint3): TMatrix3;
var
 CosH, SinH: Double;
 CosP, SinP: Double;
 CosB, SinB: Double;
begin
 CosH:= Cos(EulerMtx.x);
 SinH:= Sin(EulerMtx.x);
 CosP:= Cos(EulerMtx.y);
 SinP:= Sin(EulerMtx.y);
 CosB:= Cos(EulerMtx.z);
 SinB:= Sin(EulerMtx.z);

 Result[0, 0]:= (CosH * CosB) + (SinH * SinP * SinB);
 Result[0, 1]:= (-CosH * SinB) + (SinH * SinP * CosB);
 Result[0, 2]:= SinH * CosP;
 Result[1, 0]:= SinB * CosP;
 Result[1, 1]:= CosB * CosP;
 Result[1, 2]:= -SinP;
 Result[2, 0]:= (-SinH * CosB) + (CosH * SinP * SinB);
 Result[2, 1]:= (SinB * SinH) + (CosH * SinP * CosB);
 Result[2, 2]:= CosH * CosP;
end;

//--------------------------------------------------------------------------
function MatrixToEuler3(const Matrix: TMatrix3): TPoint3;
const
 PiHalf = Pi / 2.0;
var
 sp: Single;
 h, p, b: Single;
begin
 // Extract pitch from m23, being careful for domain errors with ArcSin().
 // We could have values slightly out of range due to floating point arithmetic.
 sp:= -Matrix[1, 2];
 if (sp <= -1.0) then
  begin
   p:= -PiHalf;
  end else
 if (sp > 1.0) then
  begin
   p:= PiHalf;
  end else p:= ArcSin(sp);

 // Check for the Gimbal lock case, giving a slight tolerance
 // for numerical imprecision.
 if (1.0 - sp > AsphyreEpsilon) then
  begin
   // We are looking straight up or down.
   // Slam bank to zero and just set heading.
   b:= 0.0;
   h:= ArcTan2(-Matrix[2, 0], Matrix[0, 0]);
  end else
  begin
   // Compute heading from m13 and m33.
   h:= ArcTan2(Matrix[0, 2], Matrix[2, 2]);

   // Compute bank from m21 and m22.
   b:= ArcTan2(Matrix[1, 0], Matrix[1, 1]);
  end;

 Result:= Point3(h, p, b);
end;

//--------------------------------------------------------------------------
function QuaternionToMatrix3(const q: TVector4): TMatrix3;
begin
 Result[0, 0]:= 1.0 - (2.0 * q.y * q.y) - (2.0 * q.z * q.z);
 Result[0, 1]:= (2.0 * q.x * q.y) + (2.0 * q.w * q.z);
 Result[0, 2]:= (2.0 * q.x * q.z) - (2.0 * q.w * q.y);
 Result[1, 0]:= (2.0 * q.x * q.y) - (2.0 * q.w * q.z);
 Result[1, 1]:= 1.0 - (2.0 * q.x * q.x) - (2.0 * q.z * q.z);
 Result[1, 2]:= (2.0 * q.y * q.z) + (2.0 * q.w * q.x);
 Result[2, 0]:= (2.0 * q.x * q.z) + (2.0 * q.w * q.y);
 Result[2, 1]:= (2.0 * q.y * q.z) - (2.0 * q.w * q.x);
 Result[2, 2]:= 1.0 - (2.0 * q.x * q.x) - (2.0 * q.y * q.y);
end;

//--------------------------------------------------------------------------
function MatrixToQuaternion3(const Matrix: TMatrix3): TVector4;
var
 Aux  : TVector4;
 Max  : Single;
 Index: Integer;
 High : Double;
 Mult : Double;
begin
 // Determine wich of w, x, y, z has the largest absolute value.
 Aux.w:= Matrix[0, 0] + Matrix[1, 1] + Matrix[2, 2];
 Aux.x:= Matrix[0, 0] - Matrix[1, 1] - Matrix[2, 2];
 Aux.y:= Matrix[1, 1] - Matrix[0, 0] - Matrix[2, 2];
 Aux.z:= Matrix[2, 2] - Matrix[0, 0] - Matrix[1, 1];

 Index:= 0;
 Max  := Aux.w;
 if (Aux.x > Max) then
  begin
   Max  := Aux.x;
   Index:= 1;
  end;
 if (Aux.y > Max) then
  begin
   Max  := Aux.y;
   Index:= 2;
  end;
 if (Aux.z > Max) then
  begin
   Max  := Aux.z;
   Index:= 3;
  end;

 // Performe square root and division.
 High:= Sqrt(Max + 1.0) * 0.5;
 Mult:= 0.25 / High;

 // Apply table to compute quaternion values.
 case Index of
  0: begin
      Result.w:= High;
      Result.x:= (Matrix[1, 2] - Matrix[2, 1]) * Mult;
      Result.y:= (Matrix[2, 0] - Matrix[0, 2]) * Mult;
      Result.z:= (Matrix[0, 1] - Matrix[1, 0]) * Mult;
     end;
  1: begin
      Result.x:= High;
      Result.w:= (Matrix[1, 2] - Matrix[2, 1]) * Mult;
      Result.z:= (Matrix[2, 0] + Matrix[0, 2]) * Mult;
      Result.y:= (Matrix[0, 1] + Matrix[1, 0]) * Mult;
     end;
  2: begin
      Result.y:= High;
      Result.z:= (Matrix[1, 2] + Matrix[2, 1]) * Mult;
      Result.w:= (Matrix[2, 0] - Matrix[0, 2]) * Mult;
      Result.x:= (Matrix[0, 1] + Matrix[1, 0]) * Mult;
     end;
  else
   begin
    Result.z:= High;
    Result.y:= (Matrix[1, 2] + Matrix[2, 1]) * Mult;
    Result.x:= (Matrix[2, 0] + Matrix[0, 2]) * Mult;
    Result.w:= (Matrix[0, 1] - Matrix[1, 0]) * Mult;
   end;
 end;

end;

//--------------------------------------------------------------------------
function QuaternionAbs(const q: TVector4): Real;
begin
 Result:= Sqrt(Sqr(q.x) + Sqr(q.y) + Sqr(q.z) + Sqr(q.w));
end;

//--------------------------------------------------------------------------
function QuaternionConj(const q: TVector4): TVector4;
begin
 Result.w:= q.w;
 Result.v:= VecNeg3(q.v);
end;

//--------------------------------------------------------------------------
function QuaternionInv(const q: TVector4): TVector4;
var
 Aux : Real;
 Conj: TVector4;
begin
 Conj:= QuaternionConj(q);
 Aux:= QuaternionAbs(Conj);
 Result.x:= Conj.x / Aux;
 Result.y:= Conj.y / Aux;
 Result.z:= Conj.z / Aux;
 Result.w:= Conj.w / Aux;
end;

//--------------------------------------------------------------------------
function QuaternionMul(const q1, q2: TVector4): TVector4;
begin
 Result.w:= (q1.w * q2.w) - (q1.x * q2.x) - (q1.y * q2.y) - (q1.z * q2.z);
 Result.x:= (q1.w * q2.x) + (q1.x * q2.w) + (q1.z * q2.y) - (q1.y * q2.z);
 Result.y:= (q1.w * q2.y) + (q1.y * q2.w) + (q1.x * q2.z) - (q1.z * q2.x);
 Result.z:= (q1.w * q2.z) + (q1.z * q2.w) + (q1.y * q2.x) - (q1.x * q2.y);
end;

//--------------------------------------------------------------------------
function QuaternionDif(const q1, q2: TVector4): TVector4;
begin
 Result:= QuaternionMul(QuaternionInv(q1), q2);
end;

//--------------------------------------------------------------------------
function QuaternionDot(const q1, q2: TVector4): Real;
begin
 Result:= (q1.w * q2.w) + (q1.x * q2.x) + (q1.y * q2.y) + (q1.z * q2.z);
end;

//--------------------------------------------------------------------------
function QuaternionNorm(const q: TVector4): TVector4;
var
 Aux: Real;
begin
 Aux:= QuaternionAbs(q);
 Result.x:= q.x / Aux;
 Result.y:= q.y / Aux;
 Result.z:= q.z / Aux;
 Result.w:= q.w / Aux;
end;

//--------------------------------------------------------------------------
function QuaternionScale(const q: TVector4; k: Real): TVector4;
begin
 Result.w:= q.w * k;
 Result.v:= VecScale3(q.v, k);
end;

//--------------------------------------------------------------------------
function QuaternionSlerp(const q1, q2: TVector4; Theta: Single): TVector4;
var
 CosOmega, SinOmega: Real;
 q: TVector4;
 Omega: Real;
 Coef0, Coef1: Single;
begin
 // Compute the "cosine of the angle" between the quaternions,
 // using the dot product.
 CosOmega:= q1.x * q2.x + q1.y * q2.y + q1.z * q2.z + q1.w * q2.w;

 // If negative dot, negate one of the input
 // quaterions to take the shorter 4D "arc".
 q:= q2;
 if (CosOmega < 0) then
  begin
   CosOmega:= -CosOmega;
   q.x:= -q2.x;
   q.y:= -q2.y;
   q.z:= -q2.z;
   q.w:= -q2.w;
  end;

 // Check if they are very close together to protect against divide-by-zero.
 Coef0:= 1.0 - Theta;
 Coef1:= Theta;
 if (1.0 - CosOmega > AsphyreEpsilon) then
  begin
   // Spherical interpolation.
   Omega:= ArcCos(CosOmega);
   SinOmega:= Sin(Omega);
   Coef0:= Sin((1.0 - Theta) * Omega) / SinOmega;
   Coef1:= Sin(Theta * Omega) / SinOmega;
  end;

 // Interpolate. 
 Result.x:= (Coef0 * q1.x) + (Coef1 * q.x);
 Result.y:= (Coef0 * q1.y) + (Coef1 * q.y);
 Result.z:= (Coef0 * q1.z) + (Coef1 * q.z);
 Result.w:= (Coef0 * q1.w) + (Coef1 * q.w);
end;

//--------------------------------------------------------------------------
end.

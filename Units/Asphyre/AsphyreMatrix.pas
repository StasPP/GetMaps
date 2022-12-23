unit AsphyreMatrix;
//---------------------------------------------------------------------------
// AsphyreMatrix.pas                                    Modified: 25-Ago-2005
// Copyright (c) 2000 - 2005  Afterwarp Interactive               Version 1.0
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

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, Math, AsphyreDef, AsphyreMath;

//---------------------------------------------------------------------------
type
 TAsphyreMatrix = class
 private
  FRawMtx: TMatrix4;

 public
  property RawMtx: TMatrix4 read FRawMtx write FRawMtx;

  //---------------------------------------------------------------------------
  // OBJECT-related functions
  //---------------------------------------------------------------------------
  // Load Idendity matrix effectively resetting previous matrix.
  procedure LoadIdentity();

  // Load Zero matrix (you won't probably use this :))
  procedure LoadZero();

  // Translate the matrix by the offset (this moves the object!)
  procedure Translate(dx, dy, dz: Real); overload;
  procedure Translate(const Point: TPoint3); overload;
  procedure Translate(const Vector: TVector4); overload;

  // Rotate the matrix around specific axis (this rotates object around
  // the global axes).
  procedure RotateX(Phi: Real);
  procedure RotateY(Phi: Real);
  procedure RotateZ(Phi: Real);

  // Rotate the matrix around its local axis (this rotates object around
  // the local axes).
  procedure RotateXLocal(Phi: Real);
  procedure RotateYLocal(Phi: Real);
  procedure RotateZLocal(Phi: Real);

  // Multiplies the current matrix with the specified one.
  procedure Multiply(const SrcMtx: TMatrix4); overload;
  procedure Multiply(Source: TAsphyreMatrix); overload;

  //---------------------------------------------------------------------------
  // CAMERA-related functions
  //---------------------------------------------------------------------------

  // Positions the camera so it looks directly at the specified position.
  procedure LookAt(const Origin, Target, Roof: TPoint3);

  // Perspective Projection with Field of View in Y-axis
  procedure PerspectiveFOVY(FieldOfView, AspectRatio, MinRange, MaxRange: Real);
  // Perspective Projection with Field of View in X-axis
  procedure PerspectiveFOVX(FieldOfView, AspectRatio, MinRange, MaxRange: Real);
  // Perspective Projection with View Volume
  procedure PerspectiveVOL(Width, Height, MinRange, MaxRange: Real);
  // Perspective Projection with Axis Boundaries
  procedure PerspectiveBDS(Left, Right, Top, Bottom, MinRange, MaxRange: Real);

  // Orthogonal Projection with View Volume
  procedure OrthogonalVOL(Width, Height, MinRange, MaxRange: Real);
  // Orthogonal Projection with Axis Boundaries
  procedure OrthogonalBDS(Left, Right, Top, Bottom, MinRange, MaxRange: Real);

  constructor Create();
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
const
 Grad2Rad = Pi / 180.0;

//---------------------------------------------------------------------------
constructor TAsphyreMatrix.Create();
begin
 inherited;

 LoadIdentity();
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.LoadIdentity();
begin
 FRawMtx:= IdentityMatrix;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.LoadZero();
begin
 FRawMtx:= ZeroMatrix;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.Translate(dx, dy, dz: Real);
begin
 FRawMtx:= MatMul(FRawMtx, MatTransl(Vector3(dx, dy, dz)));
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.Translate(const Point: TPoint3);
begin
 Translate(Point.x, Point.y, Point.z);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.Translate(const Vector: TVector4);
begin
 FRawMtx:= MatMul(FRawMtx, MatTransl(Vector));
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.RotateX(Phi: Real);
begin
 FRawMtx:= MatMul(FRawMtx, MatRotateX(Phi));
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.RotateY(Phi: Real);
begin
 FRawMtx:= MatMul(FRawMtx, MatRotateY(Phi));
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.RotateZ(Phi: Real);
begin
 FRawMtx:= MatMul(FRawMtx, MatRotateZ(Phi));
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.RotateXLocal(Phi: Real);
var
 Vec: TVector4;
begin
 Vec.x:= FRawMtx[0, 0];
 Vec.y:= FRawMtx[0, 1];
 Vec.z:= FRawMtx[0, 2];
 Vec.w:= 1.0;

 FRawMtx:= MatMul(FRawMtx, MatRotate(Vec, Phi));
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.RotateYLocal(Phi: Real);
var
 Vec: TVector4;
begin
 Vec.x:= FRawMtx[1, 0];
 Vec.y:= FRawMtx[1, 1];
 Vec.z:= FRawMtx[1, 2];
 Vec.w:= 1.0;

 FRawMtx:= MatMul(FRawMtx, MatRotate(Vec, Phi));
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.RotateZLocal(Phi: Real);
var
 Vec: TVector4;
begin
 Vec.x:= FRawMtx[2, 0];
 Vec.y:= FRawMtx[2, 1];
 Vec.z:= FRawMtx[2, 2];
 Vec.w:= 1.0;

 FRawMtx:= MatMul(FRawMtx, MatRotate(Vec, Phi));
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.Multiply(const SrcMtx: TMatrix4);
begin
 FRawMtx:= MatMul(FRawMtx, SrcMtx);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMatrix.Multiply(Source: TAsphyreMatrix);
begin
 Multiply(Source.RawMtx);
end;

//--------------------------------------------------------------------------
procedure TAsphyreMatrix.LookAt(const Origin, Target, Roof: TPoint3);
begin
 FRawMtx:= MatrixLookAtLH(Vec3to4(Origin), Vec3to4(Target), Vec3to4(Roof));
end;

//--------------------------------------------------------------------------
procedure TAsphyreMatrix.PerspectiveFOVY(FieldOfView, AspectRatio, MinRange,
 MaxRange: Real);
var
 xScale, yScale, zCoef: Real;
begin
 yScale:= Cot((FieldOfView * Grad2Rad) / 2.0);
 xScale:= AspectRatio * yScale;
 zCoef := MaxRange / (MaxRange - MinRange);

 FRawMtx:= ZeroMatrix;

 FRawMtx[0, 0]:= xScale;
 FRawMtx[1, 1]:= yScale;
 FRawMtx[2, 2]:= zCoef;
 FRawMtx[2, 3]:= 1.0;
 FRawMtx[3, 2]:= -MinRange * zCoef;
end;

//--------------------------------------------------------------------------
procedure TAsphyreMatrix.PerspectiveFOVX(FieldOfView, AspectRatio, MinRange,
 MaxRange: Real);
var
 xScale, yScale, zCoef: Real;
begin
 xScale:= Cot((FieldOfView * Grad2Rad) / 2.0);
 yScale:= xScale * 1.0 / AspectRatio;
 zCoef := MaxRange / (MaxRange - MinRange);

 FRawMtx:= ZeroMatrix;

 FRawMtx[0, 0]:= xScale;
 FRawMtx[1, 1]:= yScale;
 FRawMtx[2, 2]:= zCoef;
 FRawMtx[2, 3]:= 1.0;
 FRawMtx[3, 2]:= -MinRange * zCoef;
end;

//--------------------------------------------------------------------------
procedure TAsphyreMatrix.PerspectiveVOL(Width, Height, MinRange,
 MaxRange: Real);
begin
 FRawMtx:= ZeroMatrix;

 FRawMtx[0, 0]:= (2.0 * MinRange) / Width;
 FRawMtx[1, 1]:= (2.0 * MinRange) / Height;
 FRawMtx[2, 2]:= MaxRange / (MaxRange - MinRange);
 FRawMtx[2, 3]:= 1.0;
 FRawMtx[3, 2]:= MinRange * MaxRange / (MinRange - MaxRange);
end;

//--------------------------------------------------------------------------
procedure TAsphyreMatrix.PerspectiveBDS(Left, Right, Top, Bottom, MinRange,
 MaxRange: Real);
begin
 FRawMtx:= ZeroMatrix;

 FRawMtx[0, 0]:= (2.0 * MinRange) / (Right - Left);
 FRawMtx[1, 1]:= (2.0 * MinRange) / (Top - Bottom);

 FRawMtx[2, 0]:= (Left + Right) / (Left - Right);
 FRawMtx[2, 1]:= (Top + Bottom) / (Bottom - Top);
 FRawMtx[2, 2]:= MaxRange / (MaxRange - MinRange);
 FRawMtx[2, 3]:= 1.0;
 FRawMtx[3, 2]:= MinRange * MaxRange / (MinRange - MaxRange);
end;

//--------------------------------------------------------------------------
procedure TAsphyreMatrix.OrthogonalVOL(Width, Height, MinRange, MaxRange: Real);
begin
 FRawMtx:= ZeroMatrix;
 
 FRawMtx[0, 0]:= 2.0 / Width;
 FRawMtx[1, 1]:= 2.0 / Height;
 FRawMtx[2, 2]:= 1.0 / (MaxRange - MinRange);
 FRawMtx[2, 3]:= MinRange / (MinRange - MaxRange);
 FRawMtx[3, 3]:= 1.0;
end;

//--------------------------------------------------------------------------
procedure TAsphyreMatrix.OrthogonalBDS(Left, Right, Top, Bottom, MinRange,
 MaxRange: Real);
begin
 FRawMtx:= ZeroMatrix;

 FRawMtx[0, 0]:= 2.0 / (Right - Left);
 FRawMtx[1, 1]:= 2.0 / (Top - Bottom);
 FRawMtx[2, 2]:= 1.0 / (MaxRange - MinRange);
 FRawMtx[2, 3]:= MinRange / (MinRange - MaxRange);
 FRawMtx[3, 0]:= (Left + Right) / (Left - Right);
 FRawMtx[3, 1]:= (Top + Bottom) / (Bottom - Top);
 FRawMtx[3, 2]:= MinRange / (MinRange - MaxRange);
 FRawMtx[3, 3]:= 1.0;
end;

//---------------------------------------------------------------------------
end.

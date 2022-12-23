unit AsphyreCameras;
//---------------------------------------------------------------------------
// AsphyreCameras.pas                                   Modified: 25-Ago-2005
// Copyright (c) 2000 - 2005  Afterwarp Interactive              Version 1.02
//---------------------------------------------------------------------------
// Changes since v1.00:
//  * Changed the way perspective correction is set.
//  + Added additional methods for Orthogonal and Perspective projections.
//
// Changes since v1.01:
//  * Switched to TAsphyreMatrix for both view and projection matrices.
//  * Moved helper routines to TAsphyreMatrix for more generic usage.
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
 Types, Classes, SysUtils, Math, AsphyreDef, AsphyreMath, AsphyreMatrix;

//--------------------------------------------------------------------------
type
 TAsphyreCamera = class(TComponent)
 private
  FView: TAsphyreMatrix;
  FProj: TAsphyreMatrix;

  function GetViewMtx(): TMatrix4;
  procedure SetViewMtx(const Value: TMatrix4);
  function GetProjMtx(): TMatrix4;
  procedure SetProjMtx(const Value: TMatrix4);
 public
  // high-level view matrix
  property View: TAsphyreMatrix read FView;

  // high-level projection matrix
  property Proj: TAsphyreMatrix read FProj;

  // low-level view and projection matrices
  property ViewMtx: TMatrix4 read GetViewMtx write SetViewMtx;
  property ProjMtx: TMatrix4 read GetProjMtx write SetProjMtx;

  constructor Create(AOwner: TComponent); override;
  destructor Destroy(); override;
 end;

//--------------------------------------------------------------------------
implementation

//--------------------------------------------------------------------------
constructor TAsphyreCamera.Create(AOwner: TComponent);
begin
 inherited;

 FView:= TAsphyreMatrix.Create();
 FProj:= TAsphyreMatrix.Create();
 FProj.PerspectiveFOVY(45.0, 480.0 / 640.0, 1.0, 100000.0);
end;

//--------------------------------------------------------------------------
destructor TAsphyreCamera.Destroy();
begin
 FProj.Free();
 FView.Free();

 inherited;
end;

//--------------------------------------------------------------------------
function TAsphyreCamera.GetViewMtx(): TMatrix4;
begin
 Result:= FView.RawMtx;
end;

//--------------------------------------------------------------------------
procedure TAsphyreCamera.SetViewMtx(const Value: TMatrix4);
begin
 FView.RawMtx:= Value;
end;

//--------------------------------------------------------------------------
function TAsphyreCamera.GetProjMtx(): TMatrix4;
begin
 Result:= FProj.RawMtx;
end;

//--------------------------------------------------------------------------
procedure TAsphyreCamera.SetProjMtx(const Value: TMatrix4);
begin
 FProj.RawMtx:= Value;
end;

//--------------------------------------------------------------------------
end.


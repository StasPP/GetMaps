unit DXMeshes;
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
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Windows, Types, Classes, SysUtils, Direct3D9, DXBase, AsphyreDef,
 AsphyreMath, AsphyrePrimitives, AsphyreMeshes;

//---------------------------------------------------------------------------
type
//---------------------------------------------------------------------------
// Basic Abstract Mesh
//---------------------------------------------------------------------------
 TDXMesh = class
 private
  FLoaded     : Boolean;
  VertexBuffer: IDirect3DVertexBuffer9;
  IndexBuffer : IDirect3DIndexBuffer9;
  TexCount    : Integer;

  function CreateVertexBuffer(): Boolean;
  function CreateIndexBuffer(): Boolean;
 protected
  VertexFVFType: Cardinal;
  VertexFVFSize: Integer;

  VertexCount : Integer;
  Primitives  : Integer;

  function UploadVertexBuffer(Vertices, Normals: TPoints3;
   TexCoord: TPoints2): Boolean; virtual; abstract;
  function UploadIndexBuffer(Faces: TFaces3): Boolean; virtual;
  function LockVBuffer(out MemAddr: Pointer): Boolean;
  procedure UnlockVBuffer();
  function TexFVF(): Cardinal;
 public
  property Loaded: Boolean read FLoaded;

  function LoadFromMesh(Source: TAsphyreMesh; AMultiTexture: Boolean): Boolean;
  procedure Release();
  function Draw(const WorldMtx: TMatrix4): Boolean;

  constructor Create(ATexCount: Integer); dynamic;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
// Simple Mesh: Position, Normal, Tex
//---------------------------------------------------------------------------
 TDXTexturedMesh = class(TDXMesh)
 protected
  function UploadVertexBuffer(Vertices, Normals: TPoints3;
   TexCoord: TPoints2): Boolean; override;
 public
  constructor Create(ATexCount: Integer); override;
 end;

//---------------------------------------------------------------------------
// Environment-mapped Mesh: Position, Normal, Tex(3)
//---------------------------------------------------------------------------
 TDXEnvironmentMesh = class(TDXMesh)
 protected
  function UploadVertexBuffer(Vertices, Normals: TPoints3;
   TexCoord: TPoints2): Boolean; override;
 public
  constructor Create(ATexCount: Integer); override;
 end;

 //---------------------------------------------------------------------------
implementation

//--------------------------------------------------------------------------
type
 PTexCoord2 = ^TTexCoord2;
 TTexCoord2 = record
  u, v: Single;
 end;

//--------------------------------------------------------------------------
 PTexCoord3 = ^TTexCoord3;
 TTexCoord3 = record
  u, v, w: Single;
 end;

//--------------------------------------------------------------------------
 PTexturedMeshFVF = ^TTexturedMeshFVF;
 TTexturedMeshFVF = record
  Vertex : TD3DVector;
  Normal : TD3DVector;
  TexAddr: Cardinal;
 end;

//---------------------------------------------------------------------------
constructor TDXMesh.Create(ATexCount: Integer);
begin
 inherited Create();

 FLoaded := False;
 TexCount:= ATexCount;
end;

//---------------------------------------------------------------------------
destructor TDXMesh.Destroy();
begin
 Release();

 inherited;
end;

//---------------------------------------------------------------------------
function TDXMesh.TexFVF(): Cardinal;
begin
 Result:= 0;
 case TexCount of
  1: Result:= D3DFVF_TEX1;
  2: Result:= D3DFVF_TEX2;
  3: Result:= D3DFVF_TEX3;
  4: Result:= D3DFVF_TEX4;
  5: Result:= D3DFVF_TEX5;
  6: Result:= D3DFVF_TEX6;
  7: Result:= D3DFVF_TEX7;
  8: Result:= D3DFVF_TEX8;
 end;
end;

//--------------------------------------------------------------------------
function TDXMesh.CreateVertexBuffer(): Boolean;
var
 BufSize: Integer;
begin
 // how many bytes VertexBuffer occupies?
 BufSize:= VertexCount * VertexFVFSize;

 // create a Direct3D-compatible vertex buffer
 Result:= Succeeded(Direct3DDevice.CreateVertexBuffer(BufSize,
  D3DUSAGE_WRITEONLY, VertexFVFType, D3DPOOL_MANAGED, VertexBuffer, nil));
end;

//--------------------------------------------------------------------------
function TDXMesh.CreateIndexBuffer(): Boolean;
var
 BufSize: Integer;
 IndexCount: Integer;
begin
 // how many points are stored in index buffer?
 IndexCount:= Primitives * 3; // 3 pts per face

 // how many bytes does the index buffer occupy?
 BufSize:= IndexCount * SizeOf(Word);

 // create a Direct3D-compatible index buffer
 Result:= Succeeded(Direct3DDevice.CreateIndexBuffer(BufSize,
  D3DUSAGE_WRITEONLY, D3DFMT_INDEX16, D3DPOOL_MANAGED, IndexBuffer, nil));
end;

//---------------------------------------------------------------------------
function TDXMesh.LockVBuffer(out MemAddr: Pointer): Boolean;
begin
 // lock the existing Vertex buffer
 Result:= Succeeded(VertexBuffer.Lock(0, 0, MemAddr, 0));
end;

//---------------------------------------------------------------------------
procedure TDXMesh.UnlockVBuffer();
begin
 VertexBuffer.Unlock();
end;

//--------------------------------------------------------------------------
function TDXMesh.UploadIndexBuffer(Faces: TFaces3): Boolean;
var
 i: Integer;
 pData : Pointer;
 iPoint: PWord;
 MyFace: TFace3;
begin
 // lock the contents of Index buffer
 Result:= Succeeded(IndexBuffer.Lock(0, 0, pData, 0));
 if (not Result) then Exit;

 // overwrite the contents of index buffer
 iPoint:= pData;
 for i:= 0 to Faces.Count - 1 do
  begin
   // retreive a single face
   MyFace:= Faces[i];
   // 1st point
   iPoint^:= MyFace.Index[0];
   Inc(iPoint);
   // 2nd point
   iPoint^:= MyFace.Index[1];
   Inc(iPoint);
   // 3rd point
   iPoint^:= MyFace.Index[2];
   Inc(iPoint);
  end;

 // unlock index buffer
 IndexBuffer.Unlock();
end;

//---------------------------------------------------------------------------
procedure TDXMesh.Release();
begin
 if (IndexBuffer <> nil) then IndexBuffer:= nil;
 if (VertexBuffer <> nil) then VertexBuffer:= nil;

 FLoaded:= False;
end;

//---------------------------------------------------------------------------
function TDXMesh.LoadFromMesh(Source: TAsphyreMesh;
 AMultiTexture: Boolean): Boolean;
begin
 // (1) Release previously loaded mesh.
 if (FLoaded) then Release();

 // (2) Check model for consistency.
 with Source do
  begin
   if (Vertices.Count < 1)or(Faces.Count < 1)or(Normals.Count <> Vertices.Count)or
    (Vertices.Count > $10000)or(Faces.Count > $FFFF) then
     begin
      Result:= False;
      Exit;
     end;

   // -> primitive & vertex count
   VertexCount:= Vertices.Count;
   Primitives := Faces.Count;
  end;

 // (3) Create vertex buffer.
 Result:= CreateVertexBuffer();
 if (not Result) then Exit;

 // (4) Upload vertex buffer.
 Result:= UploadVertexBuffer(Source.Vertices, Source.Normals, Source.TexCoord);
 if (not Result) then Exit;

 // (5) Create index buffer.
 Result:= CreateIndexBuffer();
 if (not Result) then Exit;

 // (6) Upload index buffer.
 Result:= UploadIndexBuffer(Source.Faces);

 // (7) Set status to [Loaded]
 FLoaded:= Result;
end;

//--------------------------------------------------------------------------
function TDXMesh.Draw(const WorldMtx: TMatrix4): Boolean;
begin
 with Direct3DDevice do
  begin
   // set world transformation
   SetTransform(D3DTS_WORLD, D3DMatrix(WorldMtx));

   // set the stream source our vertex buffer
   Result:= Succeeded(SetStreamSource(0, VertexBuffer, 0, VertexFVFSize));
   if (not Result) then Exit;

   // set indices from our index buffer
   Result:= Succeeded(SetIndices(IndexBuffer));
   if (not Result) then Exit;

   // disable vertex shader
   Result:= Succeeded(SetVertexShader(nil));
   if (not Result) then Exit;

   // set flexible vertex format
   Result:= Succeeded(SetFVF(VertexFVFType));
   if (not Result) then Exit;

   // draw indexed primitives
   Result:= Succeeded(DrawIndexedPrimitive(D3DPT_TRIANGLELIST, 0, 0,
    VertexCount, 0, Primitives));
  end;
end;

//---------------------------------------------------------------------------
constructor TDXTexturedMesh.Create(ATexCount: Integer);
var
 Index: Integer;
begin
 inherited;

 VertexFVFType:= D3DFVF_XYZ or D3DFVF_NORMAL or TexFVF();
 for Index:= 0 to TexCount - 1 do
  VertexFVFType:= VertexFVFType or D3DFVF_TEXCOORDSIZE2(Index);

 VertexFVFSize:= (SizeOf(TTexturedMeshFVF) - SizeOf(Cardinal)) +
  (TexCount * SizeOf(TTexCoord2));
end;

//---------------------------------------------------------------------------
function TDXTexturedMesh.UploadVertexBuffer(Vertices, Normals: TPoints3;
 TexCoord: TPoints2): Boolean;
var
 Vertex  : PTexturedMeshFVF;
 TexPoint: PTexCoord2;
 Index   : Integer;
 TexIndx : Integer;
 SrcIndex: Integer;
 VertexCount: Integer;
begin
 // (1) Lock vertex buffer.
 Result:= LockVBuffer(Pointer(Vertex));
 if (not Result) then Exit;

 // (2) Update the vertex buffer.
 VertexCount:= Vertices.Count;
 for Index:= 0 to VertexCount - 1 do
  begin
   Vertex.Vertex:= D3DPoint(Vertices[Index]);
   Vertex.Normal:= D3DPoint(Normals[Index]);
   // texture coordinates
   TexPoint:= @Vertex.TexAddr;
   for TexIndx:= 0 to TexCount - 1 do
    begin
     SrcIndex:= (VertexCount * TexIndx) + Index;
     if (SrcIndex >= TexCoord.Count) then SrcIndex:= Index;
     if (SrcIndex < TexCoord.Count) then
      begin
       TexPoint.u:= TexCoord[SrcIndex].x;
       TexPoint.v:= TexCoord[SrcIndex].y;
      end else
      begin
       TexPoint.u:= 0.0;
       TexPoint.v:= 0.0;
      end;
     Inc(TexPoint);
    end; // for

   Inc(Integer(Vertex), VertexFVFSize);
  end;

 // (3) Unlock vertex buffer.
 UnlockVBuffer();
end;

//---------------------------------------------------------------------------
constructor TDXEnvironmentMesh.Create(ATexCount: Integer);
var
 Index: Integer;
begin
 inherited;

 VertexFVFType:= D3DFVF_XYZ or D3DFVF_NORMAL or TexFVF();
 for Index:= 0 to TexCount - 1 do
  VertexFVFType:= VertexFVFType or D3DFVF_TEXCOORDSIZE3(Index);

 VertexFVFSize:= (SizeOf(TTexturedMeshFVF) - SizeOf(Cardinal)) +
  (TexCount * SizeOf(TTexCoord3));
end;

//---------------------------------------------------------------------------
function TDXEnvironmentMesh.UploadVertexBuffer(Vertices, Normals: TPoints3;
 TexCoord: TPoints2): Boolean;
var
 Vertex  : PTexturedMeshFVF;
 TexPoint: PTexCoord3;
 Index   : Integer;
 TexIndx : Integer;
 SrcIndex: Integer;
 VertexCount: Integer;
begin
 // (1) Lock vertex buffer.
 Result:= LockVBuffer(Pointer(Vertex));
 if (not Result) then Exit;

 // (2) Update the vertex buffer.
 VertexCount:= Vertices.Count;
 for Index:= 0 to VertexCount - 1 do
  begin
   Vertex.Vertex:= D3DPoint(Vertices[Index]);
   Vertex.Normal:= D3DPoint(Normals[Index]);
   // texture coordinates
   TexPoint:= @Vertex.TexAddr;
   for TexIndx:= 0 to TexCount - 1 do
    begin
     SrcIndex:= (VertexCount * TexIndx) + Index;
     if (SrcIndex >= TexCoord.Count) then SrcIndex:= Index;
     if (SrcIndex < TexCoord.Count) then
      begin
       TexPoint.u:= TexCoord[SrcIndex].x;
       TexPoint.v:= TexCoord[SrcIndex].y;
       TexPoint.w:= 0.0;
      end else
      begin
       TexPoint.u:= 0.0;
       TexPoint.v:= 0.0;
       TexPoint.w:= 0.0;
      end;
     Inc(TexPoint);
    end; // for

   Inc(Integer(Vertex), VertexFVFSize);
  end;

 // (3) Unlock vertex buffer.
 UnlockVBuffer();
end;

//---------------------------------------------------------------------------
end.


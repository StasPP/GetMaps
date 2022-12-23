unit AsphyreMeshes;
//---------------------------------------------------------------------------
// AsphyreMeshes.pas                                    Modified: 11-Oct-2005
// Mesh Storage implementation                                    Version 1.0
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
 Types, Classes, SysUtils, AsphyreDef, AsphyreMath, AsphyrePrimitives;

//---------------------------------------------------------------------------
type
 TAsphyreMesh = class
 private
  FInitialized: Boolean;

  FVertices: TPoints3;
  FNormals : TPoints3;
  FTexCoord: TPoints2;
  FFaces   : TFaces3;
 public
  property Initialized: Boolean read FInitialized;

  property Vertices: TPoints3 read FVertices;
  property Normals : TPoints3 read FNormals;
  property TexCoord: TPoints2 read FTexCoord;
  property Faces   : TFaces3 read FFaces;

  procedure FindNormals();
  procedure Centralize();
  procedure Rescale(Factor: Real);
  procedure InvertNormals();

  function SaveToStream(Stream: TStream): Boolean;
  function LoadFromStream(Stream: TStream): Boolean;
  function SaveToFile(Filename: string): Boolean;
  function LoadFromFile(Filename: string): Boolean;

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
const
 MeshFileID: Cardinal = $4853454D; // 'MESH', 4853454Dh

//---------------------------------------------------------------------------
constructor TAsphyreMesh.Create();
begin
 inherited;

 FVertices:= TPoints3.Create();
 FNormals := TPoints3.Create();
 FTexCoord:= TPoints2.Create();
 FFaces   := TFaces3.Create();

 FInitialized:= False;
end;

//---------------------------------------------------------------------------
destructor TAsphyreMesh.Destroy();
begin
 FFaces.Free();
 FTexCoord.Free();
 FNormals.Free();
 FVertices.Free();

 inherited;
end;

//--------------------------------------------------------------------------
function TAsphyreMesh.SaveToStream(Stream: TStream): Boolean;
begin
 Result:= True;

 try
  // MeshID, 4 bytes
  Stream.WriteBuffer(MeshFileID, SizeOf(Cardinal));

  // VertexCount, 4 bytes
  // VertexData, VertexCount * 12 bytes
  FVertices.SaveToStream(Stream);

  // NormalCount, 4 bytes
  // NormalData, NormalCount * 12 bytes
  FNormals.SaveToStream(Stream);

  // TexCoordCount, 4 bytes
  // TexCoordData, TexCoordCount * 8 bytes
  FTexCoord.SaveToStream(Stream);

  // FaceCount, 4 bytes
  // FaceData, FaceCount * 18 bytes
  FFaces.SaveToStream(Stream);
 except
  Result:= False;
 end;
end;

//--------------------------------------------------------------------------
function TAsphyreMesh.LoadFromStream(Stream: TStream): Boolean;
var
 FileID: Cardinal;
begin
 Result:= True;

 try
  // MeshID
  Stream.ReadBuffer(FileID, SizeOf(Cardinal));
  if (FileID <> MeshFileID) then
   begin
    Result:= False;
    Exit;
   end;

  // VertexCount
  // VertexData
  FVertices.LoadFromStream(Stream);

  // NormalCount
  // NormalData
  FNormals.LoadFromStream(Stream);

  // TexCoordCount
  // TexCoordData
  FTexCoord.LoadFromStream(Stream);

  // FaceCount
  // FaceData
  FFaces.LoadFromStream(Stream);
 except
  Result:= False;
 end;
end;

//--------------------------------------------------------------------------
function TAsphyreMesh.SaveToFile(Filename: string): Boolean;
var
 Stream: TFileStream;
begin
 Stream:= TFileStream.Create(Filename, fmCreate or fmShareExclusive);

 try
  Result:= SaveToStream(Stream);
 finally
  Stream.Free();
 end;
end;

//--------------------------------------------------------------------------
function TAsphyreMesh.LoadFromFile(Filename: string): Boolean;
var
 Stream: TFileStream;
begin
 Stream:= TFileStream.Create(Filename, fmOpenRead or fmShareDenyWrite);

 try
  Result:= LoadFromStream(Stream);
 finally
  Stream.Free();
 end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.FindNormals();
begin
 FNormals.RemoveAll();
 FNormals.FindNormals(FFaces, FVertices);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.Centralize();
begin
 FVertices.Centralize();
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.Rescale(Factor: Real);
begin
 FVertices.Rescale(Factor);
end;

//---------------------------------------------------------------------------
procedure TAsphyreMesh.InvertNormals();
begin
 FNormals.Invert();
end;

//---------------------------------------------------------------------------
end.

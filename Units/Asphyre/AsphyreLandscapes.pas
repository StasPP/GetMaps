unit AsphyreLandscapes;
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
 Windows, Types, Classes, SysUtils, AsphyreDef, Direct3D9, DXBase, Math,
 AsphyrePrimitives, AsphyreMeshes, AsphyreBmp, AsphyreMath;

//---------------------------------------------------------------------------
type
 TTileTexture = record
  Tiled : TPoint2; // # of times the texture tiles
  Offset: TPoint2; // initial displacement
 end;

//---------------------------------------------------------------------------
 TAsphyreLandscape = class(TComponent)
 private
  FCols  : Integer;
  FRows  : Integer;
  FWidth : Real;
  FHeight: Real;
  FDepth : Real;

  FMesh       : TAsphyreMesh;
  FHeights    : array of array of Real;
  FTileTexture: array of TTileTexture;

  procedure CreateVertices();
  procedure CreateFaces();
  procedure CreateNormals;
  procedure CreateTexCoords();

  function GetHeight(X, Y: Integer): Real;
  procedure SetHeight(X, Y: Integer; Value: Real);

  function GetTileTex(TextureNum: Integer): TTileTexture;
  procedure SetTileTex(TextureNum: Integer; Value: TTileTexture);

  function GetNormal(Index0, Index1, Index2: Integer): TPoint3;

  procedure SetMaxSize(const Index: Integer; const Value: Real);
  procedure SetSize(const Index, Value: Integer);

  function GetTextureCount(): Integer;
 public
  // landscape mesh
  property Mesh: TAsphyreMesh read FMesh;

  // textures parametes
  property Textures[TextureNum: Integer]: TTileTexture read GetTileTex write SetTileTex;

  // heights values
  property Heights[X, Y: Integer]: Real read GetHeight write SetHeight;

  property TextureCount: Integer read GetTextureCount;

  // add new texture
  function InsertTexture(): Integer;

  // set heights from image
  procedure SetHeights(Image: TBitmapEx);

  procedure UpdateHeights();

  // create the mesh
  procedure UpdateMesh();

  constructor Create(AOwner: TComponent); override;
  destructor Destroy(); override;
 published
  property Cols  : Integer index 0 read FCols write SetSize;
  property Rows  : Integer index 1 read FRows write SetSize;
  property Width : Real index 0 read FWidth write SetMaxSize;
  property Height: Real index 1 read FHeight write SetMaxSize;
  property Depth : Real index 2 read FDepth write SetMaxSize;
 end;

 function TileTex(Tiled, Offset: TPoint2): TTileTexture;
 
//---------------------------------------------------------------------------
implementation

//--------------------------------------------------------------------------
const
 VertexType = D3DFVF_XYZ or D3DFVF_NORMAL or D3DFVF_TEX1;

//--------------------------------------------------------------------------
type
 PVertexRecord = ^TVertexRecord;
 TVertexRecord = record
  Vertex: TD3DVector;
  Normal: TD3DVector;
  u, v  : Single;
 end;

//---------------------------------------------------------------------------
function TileTex(Tiled, Offset: TPoint2): TTileTexture;
begin
 Result.Tiled:= Tiled;
 Result.Offset:= Offset;
end;

//---------------------------------------------------------------------------
constructor TAsphyreLandscape.Create(AOwner: TComponent);
begin
 inherited;

 FMesh  := TAsphyreMesh.Create();
 FWidth := 8.0;
 FHeight:= 8.0;
 FDepth := 0.0;
 FCols  := 8;
 FRows  := 8;

 UpdateHeights();

 SetLength(FTileTexture, 1);
 FTileTexture[0].Tiled.X := 1.0;
 FTileTexture[0].Tiled.Y := 1.0;
 FTileTexture[0].Offset.X:= 0.0;
 FTileTexture[0].Offset.Y:= 0.0;
end;

//---------------------------------------------------------------------------
destructor TAsphyreLandscape.Destroy();
begin
 FMesh.Free();
// SetLength(FHeights, 0);
 SetLength(FTileTexture, 0);

 inherited;
end;

//---------------------------------------------------------------------------
function TAsphyreLandscape.GetTextureCount(): Integer;
begin
 Result:= Length(FHeights);
end;

//---------------------------------------------------------------------------
procedure TAsphyreLandscape.UpdateHeights();
var
 i, j: Integer;
begin
 if (Length(FHeights) <> FRows)or(Length(FHeights[0]) <> FCols) then
  begin
   // update heights size
   SetLength(FHeights, FRows);
   for i:= 0 to FRows - 1 do
    SetLength(FHeights[i], FCols);

   for j:= 0 to FRows - 1 do
    for i:= 0 to FCols - 1 do
     FHeights[j][i]:= 0;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreLandscape.SetSize(const Index, Value: Integer);
var
 Val: Integer;
begin
 Val:= Value;
 if (Val < 2) then Val:= 2;

 case Index of
  0: FCols:= Val;
  1: FRows:= Val;
 end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreLandscape.SetMaxSize(const Index: Integer; const Value: Real);
begin
 case Index of
  0: if (Value <> 0.0) then FWidth := Value;
  1: if (Value <> 0.0) then FHeight:= Value;
  2: FDepth:= Value;
 end;
end;

//---------------------------------------------------------------------------
function TAsphyreLandscape.GetHeight(X, Y: Integer): Real;
begin
 Result:= -1;
 if (Y < 0)or(Y > Length(FHeights) - 1) then Exit;
 if (X < 0)or(X > Length(FHeights[Y]) - 1) then Exit;

 UpdateHeights();
 Result:= FHeights[Y, X];
end;

//---------------------------------------------------------------------------
procedure TAsphyreLandscape.SetHeight(X, Y: Integer; Value: Real);
begin
 UpdateHeights();

 if (Y < 0)or(Y > Length(FHeights) - 1) then Exit;
 if (X < 0)or(X > Length(FHeights[Y]) - 1) then Exit;


 if (Value < 0.0) then Value:= 0.0;
 if (Value > 1.0) then Value:= 1.0;
 FHeights[Y, X]:= Value;
end;

//---------------------------------------------------------------------------
procedure TAsphyreLandscape.SetHeights(Image: TBitmapEx);
var
 i, j: Integer;
 Size: TPoint;
begin
 UpdateHeights();

 Size.X:= Min(FCols, Image.Width);
 Size.Y:= Min(FRows, Image.Height);

 for j:= 0 to Size.Y - 1 do
  for i:= 0 to Size.X - 1 do
   FHeights[j][i]:= Image.Grayshade[i, j];
end;

//---------------------------------------------------------------------------
function TAsphyreLandscape.GetTileTex(TextureNum: Integer): TTileTexture;
begin
 if (TextureNum < 0)or(TextureNum > Length(FTileTexture) - 1) then
  begin
   Result.Tiled.X:= 0.0;
   Result.Tiled.Y:= 0.0;
   Result.Offset.X:= 0.0;
   Result.Offset.Y:= 0.0;
   Exit;
  end;

 Result:= FTileTexture[TextureNum];
end;

//---------------------------------------------------------------------------
procedure TAsphyreLandscape.SetTileTex(TextureNum: Integer; Value: TTileTexture);
begin
 if (TextureNum < 0)or(TextureNum > Length(FTileTexture) - 1) then Exit;

 FTileTexture[TextureNum]:= Value;
end;

//---------------------------------------------------------------------------
function TAsphyreLandscape.InsertTexture(): Integer;
var
 Index: Integer;
begin
 Result:= -1;
 if (Length(FTileTexture) > 8) then Exit;

 // add dummy texture
 Index:= Length(FTileTexture);
 SetLength(FTileTexture, Index + 1);
 FTileTexture[Index].Tiled.X:= 1.0;
 FTileTexture[Index].Tiled.Y:= 1.0;
 FTileTexture[Index].Offset.X:= 0.0;
 FTileTexture[Index].Offset.Y:= 0.0;
 Result:= Index;
end;

//---------------------------------------------------------------------------
procedure TAsphyreLandscape.CreateTexCoords();
var
 i, j, k: Integer;
 XPos: Real;
 YPos: Real;
begin
 // remove previous data
 FMesh.TexCoord.RemoveAll();

 // create texture coordinates
 for k:= 0 to Length(FTileTexture) - 1 do
  for j:= 0 to FRows - 1 do
   for i:= 0 to FCols - 1 do
    begin
     // calculate texture coordinates
     XPos:= ((i / (FCols - 1)) * FTileTexture[k].Tiled.X) + FTileTexture[k].Offset.X;
     YPos:= ((j / (FRows - 1)) * FTileTexture[k].Tiled.Y) + FTileTexture[k].Offset.Y;

     // add texture coordinate
     FMesh.TexCoord.Add(Point2(XPos, YPos));
    end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreLandscape.CreateNormals();
var
 i: Integer;
 FaceIndex: Integer;
 Index    : Integer;
 Normal, Vec0, Vec1: TPoint3;
begin
 // remove previous data
 FMesh.Normals.RemoveAll();

 // create normals as an average of all faces
 for i:= 0 to FMesh.Vertices.Count - 1 do
  begin
   Normal:= ZeroVector3;
   Vec0  := FMesh.Vertices[i];

   for FaceIndex:= 0 to FMesh.Faces.Count - 1 do
    for Index:= 0 to 2 do
     begin
      Vec1:= FMesh.Vertices[FMesh.Faces[FaceIndex].Index[Index]];
      if (SameVec3(Vec0, Vec1)) then
       Normal:= VecAdd3(Normal, FMesh.Faces[FaceIndex].Normal);
     end;
   FMesh.Normals.Add(VecNorm3(Normal));
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreLandscape.CreateVertices();
var
 i, j: Integer;
 XPos: Real;
 YPos: Real;
 ZPos: Real;
begin
 // remove previous data
 FMesh.Vertices.RemoveAll();

 // create vertices
 for j:= 0 to FRows - 1 do
  for i:= 0 to FCols - 1 do
   begin
    // get values of vertex
    XPos:= (FWidth / (FCols - 1)) * i;
    YPos:= (FHeight / (FRows - 1)) * j;
    ZPos:= FDepth * FHeights[j][i];

    // add vertex
    FMesh.Vertices.Add(Point3(XPos, ZPos, -YPos));
   end;
end;

//---------------------------------------------------------------------------
function TAsphyreLandscape.GetNormal(Index0, Index1, Index2: Integer): TPoint3;
var
 p0, p1, p2, Vec0, Vec1, CrossProd: TPoint3;
begin
  // get vertices
  p0:= FMesh.Vertices.Point[Index0];
  p1:= FMesh.Vertices.Point[Index1];
  p2:= FMesh.Vertices.Point[Index2];

  // calculate vectors
  Vec0:= VecSub3(p2, p0);
  Vec1:= VecSub3(p2, p1);

  CrossProd:= VecCross3(Vec0, Vec1);
  Result:= VecNorm3(CrossProd);
end;

//---------------------------------------------------------------------------
procedure TAsphyreLandscape.CreateFaces();
var
 i, j: Integer;
 MyFace : TFace3;
 VertexA: Word;
 VertexB: Word;
 VertexC: Word;
 VertexD: Word;
begin
 // remove previous data
 FMesh.Faces.RemoveAll();

 // create faces
 for j:= 0 to FRows - 2 do
  for i:= 0 to FCols - 2 do
   begin
    // calculate vertices
    VertexA:= (j * (FCols)) + i;
    VertexB:= (j * (FCols)) + (i + 1);
    VertexC:= ((j + 1) * (FCols)) + i;
    VertexD:= ((j + 1) * (FCols)) + (i + 1);

    // add index to first triangle
    MyFace.Index[0]:= VertexA;   //A
    MyFace.Index[1]:= VertexB;   //B
    MyFace.Index[2]:= VertexC;   //C
    MyFace.Normal:= GetNormal(VertexA, VertexB, VertexC);
    FMesh.Faces.Add(MyFace);

    // add index to second triangle
    MyFace.Index[0]:= VertexB;   //B
    MyFace.Index[1]:= VertexD;   //D
    MyFace.Index[2]:= VertexC;   //C
    MyFace.Normal:= GetNormal(VertexB, VertexD, VertexC);
    FMesh.Faces.Add(MyFace);
   end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreLandscape.UpdateMesh();
begin
 // step 1. create vertices
 CreateVertices();

 // step 2. create texture coordinates
 CreateTexCoords();

 // step 3. create faces
 CreateFaces();

 // step 4. create normals
 CreateNormals();

 // step 5. centralize landscape
 FMesh.Centralize();

 // step 6. find normals
 if (FMesh.Normals.Count = 0) then FMesh.FindNormals();
end;

//---------------------------------------------------------------------------
end.

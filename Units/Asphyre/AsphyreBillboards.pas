unit AsphyreBillboards;
//---------------------------------------------------------------------------
// AsphyreBillboards.pas                                Modified: 10-Oct-2005
// Billboarding implementation                                   Version 1.01
//---------------------------------------------------------------------------
//  Changes since v1.00:
//    * Fixed billboard orientation (it was mirrored & flipped by default).
//      Thanks to Steffen Norgaard for the fix!
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
 Windows, Types, Classes, SysUtils, AsphyreDef, AsphyreMath, BBTypes,
 AsphyrePrimitivesEx, AsphyreImages, AsphyreDevices, Direct3D9, DXBase,
 AsphyreCameras;

//---------------------------------------------------------------------------
type
 TBBPoints = array[0..3] of TVector4;

//---------------------------------------------------------------------------
 TAsphyreBB = class(TAsphyreDeviceSubscriber)
 private
  VertexBuffer: IDirect3DVertexBuffer9;
  IndexBuffer : IDirect3DIndexBuffer9;
  FVertexCache: Integer;
  ShadowBuffer: Pointer;
  DepthIndex  : array of Integer;
  LostBuffers : Boolean;

  CacheImage  : TAsphyreImage;
  CacheTexNum : Integer;
  CacheBlendOp: Cardinal;
  CachedQuads : Integer;

  FBillboards : TBillboards;
  FVectors    : TVectorList4;
  PostVectors : TVectorList4;
  FInitialized: Boolean;
  FDepthOrdering: Boolean;

  function CreateVertexBuffer(): Boolean;
  function CreateIndexBuffer(): Boolean;
  function AllocateBuffers(): Boolean;
  procedure ReleaseBuffers();
  procedure SetVertexCache(const Value: Integer);
  function UploadVertexBuffer(): Boolean;
  function UploadIndexBuffer(): Boolean;
  function RenderBuffers(): Boolean;
  procedure ResetCache();
  procedure SetDrawFx(DrawFx: Cardinal);
  procedure RequestCache(Image: TAsphyreImage; TexNum: Integer;
   BlendOp: Cardinal);
  procedure AddToCache(const Points: TBBPoints; const TexCoord: TPoint4;
   const Diffuse: TColor4; Image: TAsphyreImage; TexNum: Integer;
   BlendOp: Cardinal);
  procedure SetTransform(const ProjMtx: TMatrix4);
  procedure InitDepthIndex();
  procedure SortDepthIndex();
 protected
  function HandleNotice(Msg: Cardinal): Boolean; override;
 public
  property Billboards : TBillboards read FBillboards;
  property Vectors    : TVectorList4 read FVectors;
  property Initialized: Boolean read FInitialized;

  procedure Draw(const Point: TPoint3; const Size: TPoint2; Image: TAsphyreImage;
   const Colors: TColor4; TexCoord: TTexCoord; DrawFx: Cardinal); overload;

  procedure Draw(const Point: TPoint3; Size: Real; Image: TAsphyreImage;
   Pattern: Integer); overload;

  function Render(Camera: TAsphyreCamera): Boolean;

  function Initialize(): Boolean;
  procedure Finalize();

  constructor Create(AOwner: TComponent); override;
  destructor Destroy(); override;
 published
  property VertexCache  : Integer read FVertexCache write SetVertexCache;
  property DepthOrdering: Boolean read FDepthOrdering write FDepthOrdering;
 end;

//---------------------------------------------------------------------------
implementation

//----------------------------------------------------------------------------
const
 VertexType = D3DFVF_XYZ or D3DFVF_DIFFUSE or D3DFVF_TEX1;

//--------------------------------------------------------------------------
type
//--------------------------------------------------------------------------
 PVertexRecord = ^TVertexRecord;
 TVertexRecord = record
  Point  : TD3DVector;
  Diffuse: Longword;
  u, v   : Single;
 end;

//---------------------------------------------------------------------------
constructor TAsphyreBB.Create(AOwner: TComponent);
begin
 inherited;

 FBillboards := TBillboards.Create();
 FVectors    := TVectorList4.Create();
 PostVectors := TVectorList4.Create();
 FVertexCache:= 2048;
 ShadowBuffer:= nil;
 LostBuffers := False;
 FInitialized:= False;
 FDepthOrdering:= True;
end;

//---------------------------------------------------------------------------
destructor TAsphyreBB.Destroy();
begin
 if (FInitialized) then Finalize();
 
 PostVectors.Free();
 FVectors.Free();
 FBillboards.Free();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreBB.SetVertexCache(const Value: Integer);
begin
 if (not FInitialized) then
  begin
   FVertexCache:= Value;

   if (FVertexCache and $03 > 0) then
    Inc(FVertexCache, 4 - (FVertexCache and $03));

   if (FVertexCache < 512) then FVertexCache:= 512;
   if (FVertexCache > $10000) then FVertexCache:= $10000;
  end;
end;

//--------------------------------------------------------------------------
function TAsphyreBB.CreateVertexBuffer(): Boolean;
var
 BufSize: Integer;
begin
 // how many bytes VertexBuffer occupies?
 BufSize:= FVertexCache * SizeOf(TVertexRecord);

 // create a Direct3D-compatible vertex buffer
 Result:= Succeeded(Direct3DDevice.CreateVertexBuffer(BufSize,
  D3DUSAGE_WRITEONLY or D3DUSAGE_DYNAMIC, VertexType, D3DPOOL_DEFAULT,
  VertexBuffer, nil));
end;

//--------------------------------------------------------------------------
function TAsphyreBB.CreateIndexBuffer(): Boolean;
var
 BufSize   : Integer;
 IndexCount: Integer;
begin
 // how many points are stored in index buffer?
 IndexCount:= (FVertexCache div 4) * 6; // 6 values/quad

 // how many bytes does the index buffer occupy?
 BufSize:= IndexCount * SizeOf(Word);

 // create a Direct3D-compatible index buffer
 Result:= Succeeded(Direct3DDevice.CreateIndexBuffer(BufSize,
  D3DUSAGE_WRITEONLY or D3DUSAGE_DYNAMIC, D3DFMT_INDEX16, D3DPOOL_DEFAULT,
  IndexBuffer, nil));
end;

//---------------------------------------------------------------------------
function TAsphyreBB.AllocateBuffers(): Boolean;
begin
 // reset cache info
 CachedQuads := 0;
 CacheImage  := nil;
 CacheTexNum := -1;
 CacheBlendOp:= High(Cardinal);

 Result:= CreateVertexBuffer();

 if (Result) then
  Result:= CreateIndexBuffer();
end;

//---------------------------------------------------------------------------
procedure TAsphyreBB.ReleaseBuffers();
begin
 if (IndexBuffer <> nil) then IndexBuffer:= nil;
 if (VertexBuffer <> nil) then VertexBuffer:= nil;
end;

//---------------------------------------------------------------------------
function TAsphyreBB.HandleNotice(Msg: Cardinal): Boolean;
begin
 Result:= True;

 case Msg of
  msgDeviceInitialize:
   Result:= Initialize();

  msgDeviceFinalize:
   Finalize();

  msgDeviceLost:
   begin
    ReleaseBuffers();
    LostBuffers:= True;
   end;

  msgDeviceRecovered:
   begin
    if (LostBuffers) then
     begin
      Result:= AllocateBuffers();
      if (not Result) then Finalize();
      LostBuffers:= False;
     end;
   end;
 end;
end;

//---------------------------------------------------------------------------
function TAsphyreBB.Initialize(): Boolean;
begin
 if (FInitialized) then
  begin
   Result:= False;
   Exit;
  end;

 Result:= AllocateBuffers();

 if (Result) then
  ShadowBuffer:= AllocMem(FVertexCache * SizeOf(TVertexRecord));

 FInitialized:= Result; 
end;

//---------------------------------------------------------------------------
procedure TAsphyreBB.Finalize();
begin
 ReleaseBuffers();

 if (ShadowBuffer <> nil) then
  begin
   FreeMem(ShadowBuffer);
   ShadowBuffer:= nil;
  end;

 FInitialized:= False;
end;

//---------------------------------------------------------------------------
function TAsphyreBB.UploadVertexBuffer(): Boolean;
var
 MemAddr: Pointer;
 BufSize: Integer;
begin
 // (1) How many bytes to transfer?
 BufSize:= CachedQuads * SizeOf(TVertexRecord) * 4;

 // (2) Lock Vertex Buffer.
 Result:= Succeeded(VertexBuffer.Lock(0, BufSize, MemAddr, D3DLOCK_DISCARD));
 if (not Result) then Exit;

 // (3) Upload Vertex information.
 Move(ShadowBuffer^, MemAddr^, BufSize);

 // (4) Unlock Vertex Buffer.
 VertexBuffer.Unlock();
end;

//---------------------------------------------------------------------------
function TAsphyreBB.UploadIndexBuffer(): Boolean;
var
 MemAddr: Pointer;
 BufSize: Integer;
 pIndex : PWord;
 vIndex : Integer;
 i      : Integer;
begin
 // (1) How many bytes to transfer?
 BufSize:= CachedQuads * SizeOf(Word) * 6;

 // (2) Lock Index Buffer.
 Result:= Succeeded(IndexBuffer.Lock(0, BufSize, MemAddr, D3DLOCK_DISCARD));
 if (not Result) then Exit;

 // (3) Upload indices.
 pIndex:= MemAddr;
 vIndex:= 0;
 for i:= 0 to CachedQuads - 1 do
  begin
   // 1st triangle (0-1-3)
   pIndex^:= vIndex;
   Inc(pIndex);
   pIndex^:= vIndex + 1;
   Inc(pIndex);
   pIndex^:= vIndex + 3;
   Inc(pIndex);
   // 2nd triangle (1-2-3)
   pIndex^:= vIndex + 1;
   Inc(pIndex);
   pIndex^:= vIndex + 2;
   Inc(pIndex);
   pIndex^:= vIndex + 3;
   Inc(pIndex);
   // next 4 indices
   Inc(vIndex, 4);
  end;

 // (4) Unlock Index Buffer.
 IndexBuffer.Unlock();
end;

//---------------------------------------------------------------------------
function TAsphyreBB.RenderBuffers(): Boolean;
begin
 with Direct3DDevice do
  begin
   // (1) Use our vertex buffer for displaying primitives.
   Result:= Succeeded(SetStreamSource(0, VertexBuffer, 0, SizeOf(TVertexRecord)));
   if (not Result) then Exit;

   // (2) Use our index buffer to indicate the vertices of our primitives.
   Result:= Succeeded(SetIndices(IndexBuffer));
   if (not Result) then Exit;

   // (3) Disable the vertex shader.
   Result:= Succeeded(SetVertexShader(nil));
   if (not Result) then Exit;

   // (4) Set the flexible vertex format of our vertex buffer.
   Result:= Succeeded(SetFVF(VertexType));
   if (not Result) then Exit;

   // (5) Draw indexed primitives.
   Result:= Succeeded(DrawIndexedPrimitive(D3DPT_TRIANGLELIST, 0, 0,
    CachedQuads * 4, 0, CachedQuads * 2));
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreBB.ResetCache();
begin
 if (CachedQuads > 0) then
  begin
   UploadVertexBuffer();
   UploadIndexBuffer();
   RenderBuffers();
  end;

 CachedQuads:= 0;
end;

//---------------------------------------------------------------------------
procedure TAsphyreBB.SetDrawFx(DrawFx: Cardinal);
const
 CoefD3D: array[TBlendCoef] of Cardinal = (D3DBLEND_ZERO, D3DBLEND_ONE,
  D3DBLEND_SRCCOLOR, D3DBLEND_INVSRCCOLOR, D3DBLEND_SRCALPHA,
  D3DBLEND_INVSRCALPHA, D3DBLEND_DESTALPHA, D3DBLEND_INVDESTALPHA,
  D3DBLEND_DESTCOLOR, D3DBLEND_INVDESTCOLOR, D3DBLEND_SRCALPHASAT);
 BlendOpD3D: array[TBlendOp] of Cardinal = (D3DBLENDOP_ADD,
  D3DBLENDOP_REVSUBTRACT, D3DBLENDOP_SUBTRACT, D3DBLENDOP_MIN, D3DBLENDOP_MAX);
var
 SrcCoef : TBlendCoef;
 DestCoef: TBlendCoef;
 BlendOp : TBlendOp;
begin
 if (Direct3DDevice = nil) then Exit;
 Fx2Blend(DrawFx, SrcCoef, DestCoef, BlendOp);

 with Direct3DDevice do
  begin
   if (SrcCoef <> bcOne)or(DestCoef <> bcZero)or(BlendOp <> boAdd) then
    begin
     SetRenderState(D3DRS_ALPHABLENDENABLE, iTrue);
     SetRenderState(D3DRS_ALPHATESTENABLE, iTrue);
     SetRenderState(D3DRS_SRCBLEND,  CoefD3D[SrcCoef]);
     SetRenderState(D3DRS_DESTBLEND, CoefD3D[DestCoef]);
     SetRenderState(D3DRS_BLENDOP,   BlendOpD3D[BlendOp]);
    end else
    begin
     SetRenderState(D3DRS_ALPHABLENDENABLE, iFalse);
     SetRenderState(D3DRS_ALPHATESTENABLE, iFalse);
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreBB.RequestCache(Image: TAsphyreImage; TexNum: Integer;
 BlendOp: Cardinal);
begin
 // -> check if cache is capable of storing another 4 vertices
 if ((CachedQuads * 4) + 4 > FVertexCache) then ResetCache();

 // -> update blending op
 if (CacheBlendOp = High(Cardinal))or(CacheBlendOp <> BlendOp) then
  begin
   ResetCache();

   SetDrawFx(BlendOp);
   CacheBlendOp:= BlendOp;
  end;

 // -> update cache texture
 if (CacheImage = nil)or(CacheImage <> Image)or(CacheTexNum <> TexNum) then
  begin
   ResetCache();
   
   if (Image <> nil)and(TexNum <> -1) then Image.Activate(0, TexNum) else
    Direct3DDevice.SetTexture(0, nil);

   CacheImage := Image;
   CacheTexNum:= TexNum;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreBB.AddToCache(const Points: TBBPoints;
 const TexCoord: TPoint4; const Diffuse: TColor4; Image: TAsphyreImage;
 TexNum: Integer; BlendOp: Cardinal);
var
 vRec: PVertexRecord;
 i   : Integer;
begin
 RequestCache(Image, TexNum, BlendOp);

 // obtain the pointer to the next set of vertices
 vRec:= Pointer(Integer(ShadowBuffer) + (CachedQuads * 4 * SizeOf(TVertexRecord)));

 // dump the points to the buffer
 for i:= 0 to 3 do
  begin
   vRec.Point  := D3DPoint(Vec4to3NoW(Points[i]));
   vRec.Diffuse:= Diffuse[i];
   vRec.u      := TexCoord[i].x;
   vRec.v      := TexCoord[i].y;
   Inc(vRec);
  end;

 // increase the number of stored quads
 Inc(CachedQuads);
end;

//---------------------------------------------------------------------------
procedure TAsphyreBB.Draw(const Point: TPoint3; const Size: TPoint2;
 Image: TAsphyreImage; const Colors: TColor4; TexCoord: TTexCoord;
 DrawFx: Cardinal);
var
 Billboard: TBillboard;
begin
 // default billboard attributes
 Billboard.Size   := Size;
 Billboard.Diffuse:= Colors;
 Billboard.BlendOp:= DrawFx;
 Billboard.Image  := Image;

 // billboard image attributes
 Image.SelectTexture(TexCoord, Billboard.TexCoord, Billboard.TexNum);

 // add billboard to the list
 FBillboards.Add(Billboard);
 FVectors.Add(Point);
end;

//---------------------------------------------------------------------------
procedure TAsphyreBB.Draw(const Point: TPoint3; Size: Real;
 Image: TAsphyreImage; Pattern: Integer);
begin
 Draw(Point, Point2(Size, Size), Image, clWhite4, tPattern(Pattern), fxBlend);
end;

//---------------------------------------------------------------------------
procedure TAsphyreBB.SetTransform(const ProjMtx: TMatrix4);
begin
 with Direct3DDevice do
  begin
   SetTransform(D3DTS_WORLD, D3DMatrix(IdentityMatrix));
   SetTransform(D3DTS_VIEW, D3DMatrix(IdentityMatrix));
   SetTransform(D3DTS_PROJECTION, D3DMatrix(ProjMtx));
  end; 
end;

//---------------------------------------------------------------------------
procedure TAsphyreBB.InitDepthIndex();
var
 i: Integer;
begin
 SetLength(DepthIndex, PostVectors.Count);

 for i:= 0 to Length(DepthIndex) - 1 do
  DepthIndex[i]:= i;
end;

//---------------------------------------------------------------------------
procedure TAsphyreBB.SortDepthIndex();

procedure QuickSort(Left, Right: Integer);
var
 i, j, Aux: Integer;
 z: Single;
begin
 i:= Left;
 j:= Right;
 z:= PostVectors[DepthIndex[(Left + Right) shr 1]].z;

 repeat
  // TO-DO: Somewhen this caused access violation. I'm not sure
  // whether I fixed this or not.
  while (PostVectors[DepthIndex[i]].z < z)and(i < Right) do Inc(i);
  while (z < PostVectors[DepthIndex[j]].z)and(j > Left) do Dec(j);

  if (i <= j) then
   begin
    Aux:= DepthIndex[i];
    DepthIndex[i]:= DepthIndex[j];
    DepthIndex[j]:= Aux;
    
    Inc(i);
    Dec(j);
   end;
 until (i > j);

 if (Left < j) then QuickSort(Left, j);
 if (i < Right) then QuickSort(i, Right);
end;

begin // SortDepthIndex()
 if (Length(DepthIndex) < 3) then Exit;

 QuickSort(0, Length(DepthIndex) - 1);
end;

//---------------------------------------------------------------------------
function TAsphyreBB.Render(Camera: TAsphyreCamera): Boolean;
var
 Index : Integer;
 Root  : TVector4;
 Points: TBBPoints;
 Size2 : TPoint2;
 Billboard: TBillboard;
 i: Integer;
 Aux: Cardinal;
begin
 Result:= True;
 
 // clean up & exit, if cannot render
 if (LostBuffers)or(not Initialized)or(FBillboards.Count < 1) then
  begin
   FVectors.RemoveAll();
   FBillboards.RemoveAll();
   Result:= False;
   Exit;
  end;

 //==========================================================================
 // In the following code, we try to disable any Direct3D states that might
 // affect or disrupt the correct function of Billboard routines.
 //==========================================================================
 // turn off lighting
 Direct3DDevice.GetRenderState(D3DRS_LIGHTING, Aux);
 if (Aux <> Cardinal(False)) then
  Direct3DDevice.SetRenderState(D3DRS_LIGHTING, Cardinal(False));

 // turn off culling
 Direct3DDevice.GetRenderState(D3DRS_CULLMODE, Aux);
 if (Aux <> D3DCULL_NONE) then
  Direct3DDevice.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);

 // enable depth-testing
 Direct3DDevice.SetRenderState(D3DRS_ZENABLE, D3DZB_TRUE);

 for i:= 0 to 7 do
  begin
   // disable any texture coordinates effects
   Direct3DDevice.SetTextureStageState(i, D3DTSS_TEXCOORDINDEX, i);
   // disable texture coordinate transformation
   Direct3DDevice.SetTextureStageState(i, D3DTSS_TEXTURETRANSFORMFLAGS, D3DTTFF_DISABLE);
   // disable secondary texture
   Direct3DDevice.SetTexture(i, nil);
  end;

 Direct3DDevice.SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
 Direct3DDevice.SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);

 // set hardware transforms
 SetTransform(Camera.ProjMtx);

 // transform billboard positions
 PostVectors.RemoveAll();
 PostVectors.Transform(FVectors, Camera.ViewMtx);

 // prepare a Depth-Index buffer for displaying billboards
 InitDepthIndex();

 // sort the Depth-Index to display billboards properly
 if (FDepthOrdering) then SortDepthIndex();

 // render the billboards from back to front
 for i:= Length(DepthIndex) - 1 downto 0 do
  begin
   Index:= DepthIndex[i];

   // retreive the current billboard
   Billboard:= FBillboards[Index];

   // retreive the billboard's root
   Root:= PostVectors[Index];

   if (Root.z > 0.0) then
    begin
     // find the half-size of the billboard
     Size2.x:= Billboard.Size.x * 0.5;
     Size2.y:= Billboard.Size.y * 0.5;

     // calculate the quad vertices
     Points[3]:= VecAdd4(Root, Vector3(-Size2.x, -Size2.y, 0.0));
     Points[2]:= VecAdd4(Root, Vector3( Size2.x, -Size2.y, 0.0));
     Points[1]:= VecAdd4(Root, Vector3( Size2.x,  Size2.y, 0.0));
     Points[0]:= VecAdd4(Root, Vector3(-Size2.x,  Size2.y, 0.0));

     // add billboard to rendering queque
     AddToCache(Points, Billboard.TexCoord, Billboard.Diffuse, Billboard.Image,
      Billboard.TexNum, Billboard.BlendOp);
    end;
  end;

 // clean up rendering queque
 FVectors.RemoveAll();
 FBillboards.RemoveAll();

 // reset the cache
 ResetCache();

 CacheImage  := nil;
 CacheTexNum := -1;
 CacheBlendOp:= High(Cardinal);
end;

//---------------------------------------------------------------------------
end.


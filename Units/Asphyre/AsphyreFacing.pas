unit AsphyreFacing;
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
 Windows, Types, Classes, SysUtils, AsphyreDef, AsphyreMath, Direct3D9,
 DXBase, AsphyrePrimitivesEx, AsphyreImages, AsphyreDevices, FacingTypes,
 AsphyreCameras;

//---------------------------------------------------------------------------
type
 TAsphyreFacing = class(TAsphyreDeviceSubscriber)
 private
  FPrimitives   : TFacingPrimitives;
  FVertexCache  : Integer;
  FDepthOrdering: Boolean;

  VertexBuffer: IDirect3DVertexBuffer9;
  IndexBuffer : IDirect3DIndexBuffer9;
  ShadowBuffer: Pointer;
  LostBuffers : Boolean;
  FInitialized: Boolean;

  CacheImage  : TAsphyreImage;
  CacheTexNum : Integer;
  CacheBlendOp: Cardinal;
  CachedQuads : Integer;

  procedure SetVertexCache(const Value: Integer);
  function CreateVertexBuffer(): Boolean;
  function CreateIndexBuffer(): Boolean;
  function AllocateBuffers(): Boolean;
  procedure ReleaseBuffers();

  function UploadVertexBuffer(): Boolean;
  function UploadIndexBuffer(): Boolean;
  function RenderBuffers(): Boolean;
  procedure ResetCache();
  procedure RequestCache(Image: TAsphyreImage; TexNum: Integer;
   DrawFx: Cardinal);
  procedure AddToCache(const Prim: TFacingPrimitive);
  procedure SetTransform(const ViewMtx, ProjMtx: TMatrix4);
  procedure SetDrawFx(DrawFx: Cardinal);
 protected
  function HandleNotice(Msg: Cardinal): Boolean; override;
 public
  property Initialized: Boolean read FInitialized;
  property Primitives: TFacingPrimitives read FPrimitives;

  procedure Draw(const Points: TQuadPoints3; Image: TAsphyreImage;
   const Colors: TColor4; TexCoord: TTexCoord; BlendOp: Cardinal);

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
constructor TAsphyreFacing.Create(AOwner: TComponent);
begin
 inherited;

 FPrimitives   := TFacingPrimitives.Create();

 FVertexCache  := 2048;
 FDepthOrdering:= True;
end;

//---------------------------------------------------------------------------
destructor TAsphyreFacing.Destroy();
begin
 if (FInitialized) then Finalize();
 FPrimitives.Free();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFacing.SetVertexCache(const Value: Integer);
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
function TAsphyreFacing.CreateVertexBuffer(): Boolean;
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
function TAsphyreFacing.CreateIndexBuffer(): Boolean;
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
function TAsphyreFacing.AllocateBuffers(): Boolean;
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
procedure TAsphyreFacing.ReleaseBuffers();
begin
 if (IndexBuffer <> nil) then IndexBuffer:= nil;
 if (VertexBuffer <> nil) then VertexBuffer:= nil;
end;

//---------------------------------------------------------------------------
function TAsphyreFacing.HandleNotice(Msg: Cardinal): Boolean;
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
function TAsphyreFacing.Initialize(): Boolean;
begin
 Result:= AllocateBuffers();

 if (Result) then
  ShadowBuffer:= AllocMem(FVertexCache * SizeOf(TVertexRecord));

 FInitialized:= Result; 
end;

//---------------------------------------------------------------------------
procedure TAsphyreFacing.Finalize();
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
function TAsphyreFacing.UploadVertexBuffer(): Boolean;
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
function TAsphyreFacing.UploadIndexBuffer(): Boolean;
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
function TAsphyreFacing.RenderBuffers(): Boolean;
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
procedure TAsphyreFacing.ResetCache();
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
procedure TAsphyreFacing.SetDrawFx(DrawFx: Cardinal);
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
procedure TAsphyreFacing.RequestCache(Image: TAsphyreImage; TexNum: Integer;
 DrawFx: Cardinal);
begin
 // -> check if cache is capable of storing another 4 vertices
 if ((CachedQuads * 4) + 4 > FVertexCache) then ResetCache();

 // -> update blending op
 if (CacheBlendOp = High(Cardinal))or(CacheBlendOp <> DrawFx) then
  begin
   ResetCache();

   SetDrawFx(DrawFx);
   CacheBlendOp:= DrawFx;
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
procedure TAsphyreFacing.AddToCache(const Prim: TFacingPrimitive);
var
 vRec: PVertexRecord;
 i   : Integer;
begin
 RequestCache(Prim.Image, Prim.TexNum, Prim.BlendOp);

 // obtain the pointer to the next set of vertices
 vRec:= Pointer(Integer(ShadowBuffer) + (CachedQuads * 4 * SizeOf(TVertexRecord)));

 // dump the points to the buffer
 for i:= 0 to 3 do
  begin
   vRec.Point  := D3DPoint(Prim.Points[i]);
   vRec.Diffuse:= Prim.Colors[i];
   vRec.u      := Prim.TexCoord[i].x;
   vRec.v      := Prim.TexCoord[i].y;
   Inc(vRec);
  end;

 // increase the number of stored quads
 Inc(CachedQuads);
end;

//---------------------------------------------------------------------------
procedure TAsphyreFacing.SetTransform(const ViewMtx, ProjMtx: TMatrix4);
begin
 with Direct3DDevice do
  begin
   SetTransform(D3DTS_WORLD, D3DMatrix(IdentityMatrix));
   SetTransform(D3DTS_VIEW, D3DMatrix(ViewMtx));
   SetTransform(D3DTS_PROJECTION, D3DMatrix(ProjMtx));
  end; 
end;

//---------------------------------------------------------------------------
procedure TAsphyreFacing.Draw(const Points: TQuadPoints3; Image: TAsphyreImage;
 const Colors: TColor4; TexCoord: TTexCoord; BlendOp: Cardinal);
var
 Primitive: TFacingPrimitive;
begin
 // default facing attributes
 Primitive.Points := Points;
 Primitive.Colors := Colors;
 Primitive.BlendOp:= BlendOp;
 Primitive.Image  := Image;

 // primitive texture coordinates
 Image.SelectTexture(TexCoord, Primitive.TexCoord, Primitive.TexNum);

 // add primitive to the list
 FPrimitives.Add(Primitive);
end;

//---------------------------------------------------------------------------
function TAsphyreFacing.Render(Camera: TAsphyreCamera): Boolean;
var
 Index: Integer;
 i: Integer;
 Aux: Cardinal;
begin
 // clean up & exit, if cannot render
 if (LostBuffers)or(not Initialized)or(FPrimitives.Count < 1) then
  begin
   FPrimitives.RemoveAll();
   Result:= False;
   Exit;
  end;

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

 with Direct3DDevice do
  begin
   SetRenderState(D3DRS_ALPHATESTENABLE, iTrue);
   SetRenderState(D3DRS_ALPHAREF, $04);
   SetRenderState(D3DRS_ALPHAFUNC, D3DCMP_GREATEREQUAL);
  end;

 for i:= 0 to 7 do
  begin
   // disable any texture coordinates effects
   Direct3DDevice.SetTextureStageState(i, D3DTSS_TEXCOORDINDEX, i);
   // disable texture coordinate transformation
   Direct3DDevice.SetTextureStageState(i, D3DTSS_TEXTURETRANSFORMFLAGS, D3DTTFF_DISABLE);
   // disable secondary texture
   Direct3DDevice.SetTexture(i, nil);
  end;

 // set hardware transforms
 SetTransform(Camera.ViewMtx, Camera.ProjMtx);

 // transform facing mid-points
 if (FDepthOrdering) then
  FPrimitives.TransformMidPoints(Camera.ViewMtx);

 // prepare a Depth-Index buffer for displaying facing primitives
 FPrimitives.UpdateFaceIndex();

 // sort the Depth-Index to display transparent facing primitives properly
 if (FDepthOrdering) then FPrimitives.SortFaceIndex();

 // render facing primitives from back to front
 for i:= FPrimitives.Count - 1 downto 0 do
// for i:= 0 to FPrimitives.Count - 1 do
  begin
   Index:= FPrimitives.FaceIndex[i];

   // add the primitive to cache
   AddToCache(FPrimitives[Index]);
  end;

 // clean up rendering queque
 FPrimitives.RemoveAll();

 // reset the cache
 ResetCache();

 CacheImage  := nil;
 CacheTexNum := -1;
 CacheBlendOp:= High(Cardinal);
 Result:= True;
end;

//---------------------------------------------------------------------------
end.

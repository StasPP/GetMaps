unit Asphyre2D;
//---------------------------------------------------------------------------
// Asphyre2D.pas                                        Modified: 31-Oct-2005
// Hardware-accelerated 2D implementation                         Version 1.0
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
 Windows, Types, Classes, SysUtils, Direct3D9, DXBase, DXTextures,
 AsphyreDef, AsphyreConv, AsphyreDevices, AsphyreImages;

//---------------------------------------------------------------------------
type
 TPrimitiveType = (cptPoints, cptLines, cptTriangles, cptNone);

//---------------------------------------------------------------------------
 TAsphyre2D = class(TAsphyreDeviceSubscriber)
 private
  Initialized : Boolean;
  BuffersLost : Boolean;
  FVertexCache: Integer;

  VertexBuffer: IDirect3DVertexBuffer9;
  IndexBuffer : IDirect3DIndexBuffer9;
  VertexAmount: Integer;
  IndexAmount : Integer;
  Primitives  : Integer;
  VertexArray : Pointer;
  IndexArray  : Pointer;
  PrimType    : TPrimitiveType;
  CachedImage : TDXBaseTexture;
  CachedTexNum: Integer;
  CachedDrawFx: Cardinal;

  AfterFlush: Boolean;
  FAntialias: Boolean;
  FDithering: Boolean;

  FCacheStall  : Integer;
  FBufIndices  : Integer;
  FBufVertices : Integer;
  FAlphaTesting: Boolean;

  procedure SetVertexCache(const Value: Integer);
  function CreateVertexBuffer(): Boolean;
  function CreateIndexBuffer(): Boolean;
  function AllocateBuffers(): Boolean;
  procedure ReleaseBuffers();
  procedure PrepareVertexArray();
  function UploadIndexBuffer(): Boolean;
  function UploadVertexBuffer(): Boolean;
  function PrepareDraw(): Boolean;
  function BufferDraw(): Boolean;
  procedure ResetCache();
  procedure UnFlush();
  function GetClipRect(): TRect;
  procedure SetClipRect(const Value: TRect);
  procedure SetAntialias(const Value: Boolean);
  procedure SetDithering(const Value: Boolean);
  procedure SetDrawFx(DrawFx: Cardinal);
  procedure RequestCache(PType: TPrimitiveType; Vertices, Indices: Integer;
   Image: TDXBaseTexture; TexNum: Integer; DrawFx: Cardinal);
  function NextVertexEntry(): Pointer;
  procedure AddVIndex(Index: Integer);
  procedure BufferLine(const p0, p1: TPoint2; Color0, Color1: Longword;
   DrawFx: Cardinal);
  procedure BufferPoint(const Point: TPoint2; Color: Longword;
   DrawFx: Cardinal);
  procedure BufferQuad(const Quad: TPoint4; const Colors: TColor4;
   DrawFx: Cardinal);
  procedure BufferTri(x0, y0, x1, y1, x2, y2: Real; Color, DrawFx: Cardinal);
  procedure BufferTex(const Quad, TexCoord: TPoint4; const Colors: TColor4;
   Image: TDXBaseTexture; TexNum: Integer; DrawFx: Cardinal);
   procedure SetAlphaTesting(const Value: Boolean);
  function Initialize(): Boolean;
  function Finalize(): Boolean;
 protected
  function HandleNotice(Msg: Cardinal): Boolean; override;
 public
  property CacheStall : Integer read FCacheStall;
  property BufVertices: Integer read FBufVertices;
  property BufIndices : Integer read FBufIndices;

  property ClipRect: TRect read GetClipRect write SetClipRect;

  procedure PutPixel(const Point: TPoint2; Color: Cardinal;
   DrawFx: Cardinal); overload;
  procedure PutPixel(x, y: Single; Color: Cardinal; DrawFx: Cardinal); overload;
  procedure Line(const Src, Dest: TPoint2; Color0, Color1: Cardinal;
   DrawFx: Cardinal); overload;
  procedure Line(x0, y0, x1, y1: Single; Color0, Color1: Cardinal;
   DrawFx: Cardinal); overload;
  procedure Line(const Src, Dest: TPoint; Color0, Color1: Cardinal;
   DrawFx: Cardinal); overload;
  procedure FillQuad(const Points: TPoint4; const Colors: TColor4;
   DrawFx: Cardinal);
  procedure TexMap(Image: TDXBaseTexture; const Points: TPoint4;
   const Colors: TColor4; const TexCoord: TTexCoord; DrawFx: Cardinal);
  procedure Quad(const Points: TPoint4; const Colors: TColor4; DrawFx: Cardinal);

  procedure Triangle(x0, y0, x1, y1, x2, y2: Real; Color, DrawFx: Cardinal);
  procedure FillEllipse(CenterX, CenterY, RadiusX, RadiusY: Real; Color,
   DrawFx: Cardinal);

  procedure Flush();

  constructor Create(AOwner: TComponent); override;
  destructor Destroy(); override;
 published
  property AlphaTesting: Boolean read FAlphaTesting write SetAlphaTesting;
  property VertexCache: Integer read FVertexCache write SetVertexCache;
  property Antialias: Boolean read FAntialias write SetAntialias;
  property Dithering: Boolean read FDithering write SetDithering;
 end;

//---------------------------------------------------------------------------
implementation

//----------------------------------------------------------------------------
const
 VertexType = D3DFVF_XYZRHW or D3DFVF_DIFFUSE or D3DFVF_TEX1;

//--------------------------------------------------------------------------
type
 PVertexRecord = ^TVertexRecord;
 TVertexRecord = record
  Vertex: TD3DVector;
  rhw   : Single;
  Color : Longword;
  u, v  : Single;
 end;

//---------------------------------------------------------------------------
constructor TAsphyre2D.Create(AOwner: TComponent);
begin
 inherited;

 Initialized  := False;
 BuffersLost  := False;
 FVertexCache := 4096;
 FAntialias   := True;
 FDithering   := False;
 FAlphaTesting:= True;
end;

//---------------------------------------------------------------------------
destructor TAsphyre2D.Destroy();
begin
 if (Initialized) then Finalize();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.SetAlphaTesting(const Value: Boolean);
begin
 if (not Initialized) then
  FAlphaTesting:= Value;
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.SetVertexCache(const Value: Integer);
begin
 if (not Initialized) then
  begin
   FVertexCache:= Value;

   if (FVertexCache and $03 > 0) then
    Inc(FVertexCache, 4 - (FVertexCache and $03));

   if (FVertexCache < 512) then FVertexCache:= 512;
   if (FVertexCache > $10000) then FVertexCache:= $10000;
  end;
end;

//--------------------------------------------------------------------------
function TAsphyre2D.CreateVertexBuffer(): Boolean;
begin
 Result:= Succeeded(Direct3DDevice.CreateVertexBuffer(FVertexCache *
  SizeOf(TVertexRecord), D3DUSAGE_WRITEONLY or D3DUSAGE_DYNAMIC, VertexType,
  D3DPOOL_DEFAULT, VertexBuffer, nil));
end;

//--------------------------------------------------------------------------
function TAsphyre2D.CreateIndexBuffer(): Boolean;
begin
 Result:= Succeeded(Direct3DDevice.CreateIndexBuffer(FVertexCache *
  SizeOf(Word), D3DUSAGE_WRITEONLY or D3DUSAGE_DYNAMIC, D3DFMT_INDEX16,
  D3DPOOL_DEFAULT, IndexBuffer, nil));
end;

//---------------------------------------------------------------------------
function TAsphyre2D.AllocateBuffers(): Boolean;
begin
 Result:= CreateVertexBuffer();
 if (Result) then Result:= CreateIndexBuffer();

 VertexAmount:= 0;
 IndexAmount := 0;
 PrimType    := cptNone;
 Primitives  := 0;

 CachedImage := nil;
 CachedTexNum:= -2;
 CachedDrawFx:= High(Cardinal);
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.ReleaseBuffers();
begin
 if (IndexBuffer <> nil) then IndexBuffer:= nil;
 if (VertexBuffer <> nil) then VertexBuffer:= nil;
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.PrepareVertexArray();
var
 Entry: PVertexRecord;
 Index: Integer;
begin
 Entry:= VertexArray;
 for Index:= 0 to FVertexCache - 1 do
  begin
   FillChar(Entry^, SizeOf(TVertexRecord), 0);

   Entry.Vertex.z:= 0.0;
   Entry.rhw     := 1.0;

   Inc(Entry);
  end;
end;

//---------------------------------------------------------------------------
function TAsphyre2D.Initialize(): Boolean;
begin
 Result:= not Initialized;

 if (Result) then
  Result:= AllocateBuffers();

 if (Result) then
  begin
   VertexArray:= AllocMem(FVertexCache * SizeOf(TVertexRecord));
   IndexArray := AllocMem(FVertexCache * SizeOf(Word));
   PrepareVertexArray();
  end;

 AfterFlush:= True;
 Initialized:= Result;
end;

//---------------------------------------------------------------------------
function TAsphyre2D.Finalize(): Boolean;
begin
 ReleaseBuffers();

 if (VertexArray <> nil) then
  begin
   FreeMem(VertexArray);
   VertexArray:= nil;
  end;

 if (IndexArray <> nil) then
  begin
   FreeMem(IndexArray);
   IndexArray:= nil;
  end;

 Result:= True;
 Initialized:= False;
end;

//---------------------------------------------------------------------------
function TAsphyre2D.UploadVertexBuffer(): Boolean;
var
 MemAddr: Pointer;
 BufSize: Integer;
begin
 BufSize:= VertexAmount * SizeOf(TVertexRecord);
 Result:= Succeeded(VertexBuffer.Lock(0, BufSize, MemAddr, D3DLOCK_DISCARD));

 if (Result) then
  begin
   Move(VertexArray^, MemAddr^, BufSize);
   Result:= Succeeded(VertexBuffer.Unlock());
  end;
end;

//---------------------------------------------------------------------------
function TAsphyre2D.UploadIndexBuffer(): Boolean;
var
 MemAddr: Pointer;
 BufSize: Integer;
begin
 BufSize:= IndexAmount * SizeOf(Word);
 Result:= Succeeded(IndexBuffer.Lock(0, BufSize, MemAddr, D3DLOCK_DISCARD));

 if (Result) then
  begin
   Move(IndexArray^, MemAddr^, BufSize);
   Result:= Succeeded(IndexBuffer.Unlock());
  end;
end;

//---------------------------------------------------------------------------
function TAsphyre2D.PrepareDraw(): Boolean;
begin
 with Direct3DDevice do
  begin
   // (1) Use our vertex buffer for displaying primitives.
   Result:= Succeeded(SetStreamSource(0, VertexBuffer, 0,
    SizeOf(TVertexRecord)));

   // (2) Use our index buffer to indicate the vertices of our primitives.
   if (Result) then
    Result:= Succeeded(SetIndices(IndexBuffer));

   // (3) Disable vertex shader.
   if (Result) then
    Result:= Succeeded(SetVertexShader(nil));

   // (4) Set the flexible vertex format of our vertex buffer.
   if (Result) then
    Result:= Succeeded(SetFVF(VertexType));
  end;
end;

//--------------------------------------------------------------------------
function TAsphyre2D.BufferDraw(): Boolean;
var
 Primitive: TD3DPrimitiveType;
begin
 // (1) POINTS are rendered as Non-Indexed
 if (PrimType = cptPoints) then
  begin
   Result:= Succeeded(Direct3DDevice.DrawPrimitive(D3DPT_POINTLIST, 0,
    Primitives));
   Exit;
  end;

 // (2) What primitives are we talking about?
 Primitive:= D3DPT_TRIANGLELIST;
 if (PrimType = cptLines) then Primitive:= D3DPT_LINELIST;

 // (3) Render INDEXED primitives.
 Result:= Succeeded(Direct3DDevice.DrawIndexedPrimitive(Primitive, 0, 0,
  VertexAmount, 0, Primitives));
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.ResetCache();
begin
 // (1) Flush the cache, if needed.
 if (VertexAmount > 0)and(Primitives > 0)and(not BuffersLost) then
  begin
   if (UploadVertexBuffer())and(UploadIndexBuffer())and(PrepareDraw()) then
    BufferDraw();

   Inc(FCacheStall);
  end;

 // (2) Reset buffer info.
 VertexAmount:= 0;
 IndexAmount := 0;
 PrimType    := cptNone;
 Primitives  := 0;
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.UnFlush();
var
 i: Integer;
begin
 if (Direct3DDevice = nil)or(not Initialized) then Exit;

 VertexAmount:= 0;
 IndexAmount := 0;
 PrimType    := cptNone;
 Primitives  := 0;

 CachedImage := nil;
 CachedTexNum:= -2;
 CachedDrawFx:= High(Cardinal);

 with Direct3DDevice do
  begin
   //========================================================================
   // In the following code, we try to disable any Direct3D states that might
   // affect or disrupt our behavior.
   //========================================================================
   SetRenderState(D3DRS_LIGHTING,  iFalse);
   SetRenderState(D3DRS_CULLMODE,  D3DCULL_NONE);
   SetRenderState(D3DRS_ZENABLE,   D3DZB_FALSE);
   SetRenderState(D3DRS_FOGENABLE, iFalse);

   SetRenderState(D3DRS_ALPHAFUNC, D3DCMP_GREATEREQUAL);
   SetRenderState(D3DRS_ALPHAREF, $00000001);
   SetRenderState(D3DRS_ALPHATESTENABLE, iFalse);

   for i:= 0 to 7 do
    begin
     SetTextureStageState(i, D3DTSS_TEXCOORDINDEX, 0);
     SetTextureStageState(i, D3DTSS_TEXTURETRANSFORMFLAGS, D3DTTFF_DISABLE);

     SetTexture(i, nil);

     SetTextureStageState(i, D3DTSS_COLORARG1, D3DTA_TEXTURE);
     SetTextureStageState(i, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);

     SetTextureStageState(i, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
     SetTextureStageState(i, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
    end;

   //==========================================================================
   // Update user-specified states.
   //==========================================================================
   SetRenderState(D3DRS_DITHERENABLE, Cardinal(FDithering));

   if (FAntialias) then
    begin
     SetSamplerState(0, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR);
     SetSamplerState(0, D3DSAMP_MINFILTER, D3DTEXF_LINEAR);
     end else
    begin
     SetSamplerState(0, D3DSAMP_MAGFILTER, D3DTEXF_POINT);
     SetSamplerState(0, D3DSAMP_MINFILTER, D3DTEXF_POINT);
    end;
  end;

 AfterFlush  := False;
 FCacheStall := 0;
 FBufVertices:= 0;
 FBufIndices := 0;
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.Flush();
begin
 if (Initialized) then
  begin
   ResetCache();
   AfterFlush:= True;
  end;
end;

//---------------------------------------------------------------------------
function TAsphyre2D.HandleNotice(Msg: Cardinal): Boolean;
begin
 Result:= True;
 
 case Msg of
  msgDeviceInitialize:
   Result:= Initialize();

  msgDeviceFinalize:
   Result:= Finalize();

  msgDeviceLost:
   if (Initialized) then
    begin
     ReleaseBuffers();
     BuffersLost:= True;
    end;

  msgDeviceRecovered:
   if (Initialized) then
    begin
     if (not AllocateBuffers()) then Finalize();
     BuffersLost:= False;
    end;

  msgEndScene, msgMultiCanvasBegin:
   Flush();
 end;
end;

//---------------------------------------------------------------------------
function TAsphyre2D.GetClipRect(): TRect;
var
 vp: TD3DViewport9;
begin
 if (Direct3DDevice = nil)or(Failed(Direct3DDevice.GetViewport(vp))) then
  begin
   Result:= Rect(0, 0, 0, 0);
   Exit;
  end;

 Result.Left  := vp.X;
 Result.Top   := vp.Y;
 Result.Right := vp.X + vp.Width;
 Result.Bottom:= vp.Y + vp.Height;
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.SetClipRect(const Value: TRect);
var
 vp: TD3DViewport9;
begin
 if (Direct3DDevice <> nil) then
  begin
   ResetCache();

   vp.X:= Value.Left;
   vp.Y:= Value.Top;
   vp.Width := (Value.Right - Value.Left);
   vp.Height:= (Value.Bottom - Value.Top);
   vp.MinZ:= 0.0;
   vp.MaxZ:= 1.0;

   Direct3DDevice.SetViewport(vp);
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.SetDithering(const Value: Boolean);
begin
 FDithering:= Value;

 if (Initialized) then
  begin
   ResetCache();
   Direct3DDevice.SetRenderState(D3DRS_DITHERENABLE, Cardinal(FDithering));
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.SetAntialias(const Value: Boolean);
begin
 FAntialias:= Value;

 if (Initialized) then
  begin
   ResetCache();

   if (FAntialias) then
    begin
     Direct3DDevice.SetSamplerState(0, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR);
     Direct3DDevice.SetSamplerState(0, D3DSAMP_MINFILTER, D3DTEXF_LINEAR);
     end else
    begin
     Direct3DDevice.SetSamplerState(0, D3DSAMP_MAGFILTER, D3DTEXF_POINT);
     Direct3DDevice.SetSamplerState(0, D3DSAMP_MINFILTER, D3DTEXF_POINT);
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.SetDrawFx(DrawFx: Cardinal);
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
     
     if (FAlphaTesting) then
      SetRenderState(D3DRS_ALPHATESTENABLE, iTrue);

     SetRenderState(D3DRS_SRCBLEND,  CoefD3D[SrcCoef]);
     SetRenderState(D3DRS_DESTBLEND, CoefD3D[DestCoef]);
     SetRenderState(D3DRS_BLENDOP,   BlendOpD3D[BlendOp]);
    end else
    begin
     SetRenderState(D3DRS_ALPHABLENDENABLE, iFalse);
     if (FAlphaTesting) then
      SetRenderState(D3DRS_ALPHATESTENABLE, iFalse);
    end;

   if (DrawFx and $10000000 > 0) then
    begin
     SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
     SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
    end else
    begin
     SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
     SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.RequestCache(PType: TPrimitiveType; Vertices,
 Indices: Integer; Image: TDXBaseTexture; TexNum: Integer; DrawFx: Cardinal);
begin
 // step 1. UnFlush, if needed
 if (AfterFlush) then UnFlush();

 // step 2. enough buffer space?
 if (VertexAmount + Vertices > FVertexCache)or
  (IndexAmount + Indices > FVertexCache)or((PType <> PrimType)and(PrimType <> cptNone)) then ResetCache();

 // step 3. need to update DrawOp?
 if (DrawFx = High(Cardinal))or(CachedDrawFx <> DrawFx) then
  begin
   ResetCache();
   SetDrawFx(DrawFx);
   CachedDrawFx:= DrawFx;
  end;

 // step 4. need to update texture?
 if (CachedTexNum = -2)or(CachedImage <> Image)or(CachedTexNum <> TexNum) then
  begin
   ResetCache();

   if (Image <> nil)and(TexNum <> -1) then Image.Activate(0, TexNum)
    else Direct3DDevice.SetTexture(0, nil);

   CachedImage := Image;
   CachedTexNum:= TexNum;
  end;

 // step 5. update cache type
 PrimType:= PType;
end;

//---------------------------------------------------------------------------
function TAsphyre2D.NextVertexEntry(): Pointer;
begin
 Result:= Pointer(Integer(VertexArray) + (VertexAmount * SizeOf(TVertexRecord)));
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.AddVIndex(Index: Integer);
var
 Entry: PWord;
begin
 Entry:= Pointer(Integer(IndexArray) + (IndexAmount * SizeOf(Word)));
 Entry^:= Index;

 Inc(IndexAmount);
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.BufferPoint(const Point: TPoint2; Color: Longword;
 DrawFx: Cardinal);
var
 Entry: PVertexRecord;
begin
 // (1) Validate cache.
 RequestCache(cptPoints, 1, 1, nil, -1, DrawFx);

 // (2) Add new vertex.
 Entry:= NextVertexEntry();
 Entry.Vertex.x:= Point.x;
 Entry.Vertex.y:= Point.y;
 Entry.Color   := Color;

 // (3) Update amounts.
 Inc(VertexAmount);
 Inc(Primitives);

 // (4) Update statitics.
 Inc(FBufVertices);
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.BufferLine(const p0, p1: TPoint2; Color0,
 Color1: Longword; DrawFx: Cardinal);
var
 Entry: PVertexRecord;
begin
 // (1) Validate cache.
 RequestCache(cptLines, 2, 2, nil, -1, DrawFx);

 // (2) Add indices.
 AddVIndex(VertexAmount);
 AddVIndex(VertexAmount + 1);

 // (3) Add vertices.
 // -> 1st point
 Entry:= NextVertexEntry();
 Entry.Vertex.x:= p0.x;
 Entry.Vertex.y:= p0.y;
 Entry.Color   := Color0;
 Inc(VertexAmount);
 // -> 2nd point
 Entry:= NextVertexEntry();
 Entry.Vertex.x:= p1.x;
 Entry.Vertex.y:= p1.y;
 Entry.Color   := Color1;
 Inc(VertexAmount);

 // (4) Update primitive count.
 Inc(Primitives);

 // (5) Update statitics.
 Inc(FBufVertices, 2);
 Inc(FBufIndices, 2);
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.BufferQuad(const Quad: TPoint4; const Colors: TColor4;
 DrawFx: Cardinal);
var
 Entry: PVertexRecord;
 Index: Integer;
begin
 // (1) Diffuse color used?
 if ((Colors[0] and Colors[1] and Colors[2] and Colors[3]) <> $FFFFFFFF) then
  DrawFx:= DrawFx or $10000000;

 // (2) Validate cache.
 RequestCache(cptTriangles, 4, 6, nil, -1, DrawFx);

 // (3) Add indices.
 AddVIndex(VertexAmount);
 AddVIndex(VertexAmount + 1);
 AddVIndex(VertexAmount + 3);
 AddVIndex(VertexAmount + 1);
 AddVIndex(VertexAmount + 2);
 AddVIndex(VertexAmount + 3);

 // (4) Add vertices.
 for Index:= 0 to 3 do
  begin
   Entry:= NextVertexEntry();
   Entry.Vertex.x:= Quad[Index].x;
   Entry.Vertex.y:= Quad[Index].y;
   Entry.Color   := DisplaceRB(Colors[Index]);
   Inc(VertexAmount);
  end;

 // (5) Update primitive count.
 Inc(Primitives, 2);

 // (6) Update statitics.
 Inc(FBufVertices, 4);
 Inc(FBufIndices, 6);
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.BufferTri(x0, y0, x1, y1, x2, y2: Real; Color,
 DrawFx: Cardinal);
var
 Entry: PVertexRecord;
begin
 // (1) Validate cache.
 RequestCache(cptTriangles, 3, 3, nil, -1, DrawFx);

 // (2) Add indices.
 AddVIndex(VertexAmount);
 AddVIndex(VertexAmount + 1);
 AddVIndex(VertexAmount + 2);

 // (3) Prepare color
 Color:= DisplaceRB(Color);

 // (4) Add vertices.
 Entry:= NextVertexEntry();
 Entry.Vertex.x:= x0;
 Entry.Vertex.y:= y0;
 Entry.Color   := Color;
 Inc(VertexAmount);

 Entry:= NextVertexEntry();
 Entry.Vertex.x:= x1;
 Entry.Vertex.y:= y1;
 Entry.Color   := Color;
 Inc(VertexAmount);

 Entry:= NextVertexEntry();
 Entry.Vertex.x:= x2;
 Entry.Vertex.y:= y2;
 Entry.Color   := Color;
 Inc(VertexAmount);

 // (5) Update primitive count.
 Inc(Primitives);

 // (6) Update statitics.
 Inc(FBufVertices, 3);
 Inc(FBufIndices, 3);
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.BufferTex(const Quad, TexCoord: TPoint4;
 const Colors: TColor4; Image: TDXBaseTexture; TexNum: Integer;
 DrawFx: Cardinal);
var
 Entry: PVertexRecord;
 Index: Integer;
begin
 // (1) Diffuse color used?
 if ((Colors[0] and Colors[1] and Colors[2] and Colors[3]) <> $FFFFFFFF) then
  DrawFx:= DrawFx or $10000000;

 // (2) Validate cache.
 RequestCache(cptTriangles, 4, 6, Image, TexNum, DrawFx);

 // (3) Add indices.
 AddVIndex(VertexAmount);
 AddVIndex(VertexAmount + 1);
 AddVIndex(VertexAmount + 3);
 AddVIndex(VertexAmount + 1);
 AddVIndex(VertexAmount + 2);
 AddVIndex(VertexAmount + 3);

 // (4) Add vertices.
 for Index:= 0 to 3 do
  begin
   Entry:= NextVertexEntry();

   Entry.Vertex.x:= Quad[Index].x - 0.5;
   Entry.Vertex.y:= Quad[Index].y - 0.5;
   Entry.Color   := DisplaceRB(Colors[Index]);
   Entry.u       := TexCoord[Index].x;
   Entry.v       := TexCoord[Index].y;

   Inc(VertexAmount);
  end;

 // (5) Update primitive count.
 Inc(Primitives, 2);

 // (6) Update statitics.
 Inc(FBufVertices, 4);
 Inc(FBufIndices, 6);
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.PutPixel(const Point: TPoint2; Color: Cardinal;
 DrawFx: Cardinal);
begin
 BufferPoint(Point, DisplaceRB(Color), DrawFx);
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.PutPixel(x, y: Single; Color: Cardinal;
 DrawFx: Cardinal);
begin
 BufferPoint(Point2(x, y), DisplaceRB(Color), DrawFx);
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.Line(const Src, Dest: TPoint2; Color0,
 Color1: Cardinal; DrawFx: Cardinal);
begin
 BufferLine(Src, Dest, DisplaceRB(Color0), DisplaceRB(Color1), DrawFx);
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.Line(x0, y0, x1, y1: Single; Color0, Color1: Cardinal;
 DrawFx: Cardinal);
begin
 BufferLine(Point2(x0, y0), Point2(x1, y1), DisplaceRB(Color0),
  DisplaceRB(Color1), DrawFx);
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.Line(const Src, Dest: TPoint; Color0,
 Color1: Cardinal; DrawFx: Cardinal);
begin
 Line(Src.X, Src.Y, Dest.X, Dest.Y, Color0, Color1, DrawFx);
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.FillQuad(const Points: TPoint4; const Colors: TColor4;
 DrawFx: Cardinal);
begin
 BufferQuad(Points, Colors, DrawFx);
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.Triangle(x0, y0, x1, y1, x2, y2: Real; Color,
 DrawFx: Cardinal);
begin
 BufferTri(x0, y0, x1, y1, x2, y2, Color, DrawFx);
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.FillEllipse(CenterX, CenterY, RadiusX, RadiusY: Real;
 Color, DrawFx: Cardinal);
const
 Pi2 = Pi * 2.0;
var
 Steps: Integer; 
 Approx: Real;
 i: Integer;
 Alpha0, Alpha1: Real;
 Pt0, Pt1: TPoint2;
begin
 Approx:= Pi2 * Sqrt((Sqr(RadiusX) + Sqr(RadiusY)) * 0.5);
 Steps := Round(Sqrt(Approx) * 2);
 if (Steps < 3) then Exit;

 for i:= 0 to Steps - 1 do
  begin
   Alpha0:= i * Pi2 / Steps;
   Alpha1:= (i + 1) * Pi2 / Steps;

   Pt0.X:= CenterX + (Cos(Alpha0) * RadiusX);
   Pt0.Y:= CenterY + (Sin(Alpha0) * RadiusY);
   Pt1.X:= CenterX + (Cos(Alpha1) * RadiusX);
   Pt1.Y:= CenterY + (Sin(Alpha1) * RadiusY);

   BufferTri(Pt0.X, Pt0.y, Pt1.x, Pt1.y, CenterX, CenterY, Color, DrawFx);
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.TexMap(Image: TDXBaseTexture; const Points: TPoint4;
 const Colors: TColor4; const TexCoord: TTexCoord; DrawFx: Cardinal);
var
 TexPts: TPoint4;
 u0, v0, u1, v1: Real;
 TexNum: Integer;
begin
 if (Image is TAsphyreImage) then
  begin
   if (not TAsphyreImage(Image).SelectTexture(TexCoord, TexPts,
    TexNum)) then Exit;
  end else
  begin
   if (TexCoord.w < 1)or(TexCoord.h < 1) then
    begin
     TexPts[0]:= Point2(0.0, 0.0);
     TexPts[1]:= Point2(1.0, 0.0);
     TexPts[2]:= Point2(1.0, 1.0);
     TexPts[3]:= Point2(0.0, 1.0);
    end else
    begin
     u0:= TexCoord.x / Image.Size.X;
     v0:= TexCoord.y / Image.Size.Y;
     u1:= TexCoord.w / Image.Size.X;
     v1:= TexCoord.h / Image.Size.Y;

     TexPts[0]:= Point2(u0, v0);
     TexPts[1]:= Point2(u1, v0);
     TexPts[2]:= Point2(u1, v1);
     TexPts[3]:= Point2(u0, v1);
    end;
   TexNum:= 0;
  end;

 BufferTex(Points, TexPts, Colors, Image, TexNum, DrawFx);
end;

//---------------------------------------------------------------------------
procedure TAsphyre2D.Quad(const Points: TPoint4; const Colors: TColor4;
 DrawFx: Cardinal);
var
 MyPts: TPoint4;
begin
 MyPts:= Points;

 // last pixel fix -> not very good implementation :(
 if (MyPts[0].y = MyPts[1].y)and(MyPts[2].y = MyPts[3].y)and
  (MyPts[0].x = MyPts[3].x)and(MyPts[1].x = MyPts[2].x) then
  begin
   MyPts[1].x:= MyPts[1].x - 1.0;
   MyPts[2].x:= MyPts[2].x - 1.0;
   MyPts[2].y:= MyPts[2].y - 1.0;
   MyPts[3].y:= MyPts[3].y - 1.0;
  end;

 Line(MyPts[0], MyPts[1], Colors[0], Colors[1], DrawFx);
 Line(MyPts[1], MyPts[2], Colors[1], Colors[2], DrawFx);
 Line(MyPts[2], MyPts[3], Colors[2], Colors[3], DrawFx);
 Line(MyPts[3], MyPts[0], Colors[3], Colors[0], DrawFx);
end;

//---------------------------------------------------------------------------
end.


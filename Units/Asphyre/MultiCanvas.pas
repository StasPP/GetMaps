unit MultiCanvas;
//---------------------------------------------------------------------------
// MultiCanvas.pas                                      Modified: 04-Jan-2006
// 2D multi-texturing implementation                              Version 1.0
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
 DXTextures, AsphyreDevices, AsphyreImages, AsphyreConv, Vectors2;

//---------------------------------------------------------------------------
type
 TStageEffect = (seModulate, seModulate2x, seModulate4x, seAdd, seAddSigned,
  seAddSigned2x, seSubstract, seAddSmooth, seBlendNextAlpha, seBlendPrevAlpha,
  seDotProduct);

//---------------------------------------------------------------------------
 TMultiCanvas = class(TAsphyreDeviceSubscriber)
 private
  VertexBuf : Pointer;
  FScheluded: Integer;
  ColorUsed : Boolean;
  EffectIndx: Integer;
  FAntialias: Boolean;
  FOnWork   : TNotifyEvent;
  Working   : Boolean;

  procedure PrepareVertexBuf();
  function GetMaxStages(): Integer;
  procedure SetAntialias(const Value: Boolean);
  procedure BeginRender();
  procedure EndRender();
 public
  property MaxStages: Integer read GetMaxStages;
  property Scheduled: Integer read FScheluded;
  property Antialias: Boolean read FAntialias write SetAntialias;

  procedure SetEffect(DrawFx: Cardinal);

  function UseImage(Image: TDXBaseTexture; const TexCoord: TTexCoord): Boolean;
  procedure UseEffect(Effect: TStageEffect);
  procedure UseColors(const Colors: TColor4);
  procedure SetCoords(const Points: TPoint4);

  procedure Work();
  procedure WorkWith(Event: TNotifyEvent);

  constructor Create(AOwner: TComponent); override;
  destructor Destroy(); override;
 published
  property OnWork: TNotifyEvent read FOnWork write FOnWork;
 end;

//---------------------------------------------------------------------------
implementation

//----------------------------------------------------------------------------
const
 VertexType = D3DFVF_XYZRHW or D3DFVF_DIFFUSE or D3DFVF_TEX8;
 WrapIndex: array[0..3] of Integer = (0, 1, 3, 2);

//--------------------------------------------------------------------------
type
 PVertexRecord = ^TVertexRecord;
 TVertexRecord = record
  Vector: TD3DVector;
  rhw   : Single;
  Color : Longword;
  TexPt : array[0..7] of TPoint2;
 end;

//---------------------------------------------------------------------------
constructor TMultiCanvas.Create(AOwner: TComponent);
begin
 inherited;

 VertexBuf:= AllocMem(SizeOf(TVertexRecord) * 4);
 PrepareVertexBuf();

 FScheluded:= 0;
 ColorUsed := False;
 EffectIndx:= 0;
 FAntialias:= True;
 Working   := False;
end;

//---------------------------------------------------------------------------
destructor TMultiCanvas.Destroy();
begin
 FreeMem(VertexBuf);

 inherited;
end;

//---------------------------------------------------------------------------
function TMultiCanvas.GetMaxStages(): Integer;
begin
 Result:= DeviceCaps.MaxTextureBlendStages;

 if (Int64(Result) > DeviceCaps.MaxSimultaneousTextures) then
  Result:= DeviceCaps.MaxSimultaneousTextures;
end;

//---------------------------------------------------------------------------
procedure TMultiCanvas.PrepareVertexBuf();
var
 Vertex: PVertexRecord;
 i: Integer;
begin
 Vertex:= VertexBuf;

 for i:= 0 to 3 do
  begin
   Vertex.rhw:= 1.0;
   Vertex.Vector.z:= 0.0;
   Inc(Vertex);
  end;
end;

//---------------------------------------------------------------------------
procedure TMultiCanvas.SetEffect(DrawFx: Cardinal);
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
procedure TMultiCanvas.BeginRender();
var
 i: Integer;
 MyDev: TAsphyreDevice;
begin
 if (Direct3DDevice = nil) then Exit;

 MyDev:= Device;
 if (MyDev <> nil) then MyDev.BroadcastMsg(msgMultiCanvasBegin);

 with Direct3DDevice do
  begin
   // update the states that may disrupt our behavior
   SetRenderState(D3DRS_LIGHTING,  iFalse);
   SetRenderState(D3DRS_CULLMODE,  D3DCULL_NONE);
   SetRenderState(D3DRS_ZENABLE,   D3DZB_FALSE);
   SetRenderState(D3DRS_FOGENABLE, iFalse);

   for i:= 0 to DeviceCaps.MaxTextureBlendStages - 1 do
    begin
     SetTextureStageState(i, D3DTSS_TEXCOORDINDEX, 0);
     SetTextureStageState(i, D3DTSS_TEXTURETRANSFORMFLAGS, D3DTTFF_DISABLE);

     SetTexture(i, nil);

     if (i > 0) then
      begin
       SetTextureStageState(i, D3DTSS_COLORARG1, D3DTA_TEXTURE);
       SetTextureStageState(i, D3DTSS_COLORARG2, D3DTA_CURRENT);
       SetTextureStageState(i, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
       SetTextureStageState(i, D3DTSS_ALPHAARG2, D3DTA_CURRENT);
      end else
      begin
       SetTextureStageState(i, D3DTSS_COLORARG1, D3DTA_TEXTURE);
       SetTextureStageState(i, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
       SetTextureStageState(i, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
       SetTextureStageState(i, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
      end;
    end;
  end;

 // update antialiasing settings
 SetAntialias(FAntialias);

 EffectIndx:= 0;
 FScheluded:= 0;
 Working   := True;
end;

//---------------------------------------------------------------------------
function TMultiCanvas.UseImage(Image: TDXBaseTexture;
 const TexCoord: TTexCoord): Boolean;
var
 TexNum: Integer;
 TexPts: TPoint4;
 Vertex: PVertexRecord;
 u0, v0, u1, v1: Real;
 i: Integer;
begin
 if (Direct3DDevice = nil)or(FScheluded > 7) then
  begin
   Result:= False;
   Exit;
  end;

 if (Image is TAsphyreImage) then
  begin
   Result:= TAsphyreImage(Image).SelectTexture(TexCoord, TexPts, TexNum);
   if (not Result) then Exit;
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

 Vertex:= VertexBuf;
 for i:= 0 to 3 do
  begin
   Vertex.TexPt[FScheluded].x:= TexPts[WrapIndex[i]].x;
   Vertex.TexPt[FScheluded].y:= TexPts[WrapIndex[i]].y;
   Inc(Vertex);
  end;

 Result:= Image.Activate(FScheluded, TexNum);
 if (Result) then Inc(FScheluded);
end;

//---------------------------------------------------------------------------
procedure TMultiCanvas.UseColors(const Colors: TColor4);
var
 Vertex: PVertexRecord;
 i: Integer;
begin
 Vertex:= VertexBuf;

 for i:= 0 to 3 do
  begin
   Vertex.Color:= DisplaceRB(Colors[WrapIndex[i]]);
   Inc(Vertex);
  end;

 ColorUsed:= True;
end;

//---------------------------------------------------------------------------
procedure TMultiCanvas.SetCoords(const Points: TPoint4);
var
 Vertex: PVertexRecord;
 i: Integer;
begin
 Vertex:= VertexBuf;

 for i:= 0 to 3 do
  begin
   Vertex.Vector.x:= Points[WrapIndex[i]].x - 0.5;
   Vertex.Vector.y:= Points[WrapIndex[i]].y - 0.5;
   Inc(Vertex);
  end;
end;

//---------------------------------------------------------------------------
procedure TMultiCanvas.UseEffect(Effect: TStageEffect);
const
 Effect2D3D: array[TStageEffect] of Cardinal = (D3DTOP_MODULATE,
  D3DTOP_MODULATE2X, D3DTOP_MODULATE4X, D3DTOP_ADD, D3DTOP_ADDSIGNED,
  D3DTOP_ADDSIGNED2X, D3DTOP_SUBTRACT, D3DTOP_ADDSMOOTH,
  D3DTOP_BLENDTEXTUREALPHA, D3DTOP_BLENDCURRENTALPHA, D3DTOP_DOTPRODUCT3);
begin
 if (Direct3DDevice = nil)or(EffectIndx > 6) then Exit;

 with Direct3DDevice do
  begin
   SetTextureStageState(EffectIndx + 1, D3DTSS_COLOROP, Effect2D3D[Effect]);
   SetTextureStageState(EffectIndx + 1, D3DTSS_ALPHAOP, Effect2D3D[Effect]);
  end;

 Inc(EffectIndx);
end;

//---------------------------------------------------------------------------
procedure TMultiCanvas.EndRender();
begin
 if (Direct3DDevice = nil)or(FScheluded < 1)or(not Working) then Exit;

 with Direct3DDevice do
  begin
   if (not ColorUsed) then
    begin
     SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
     SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
    end else
    begin
     SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
     SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
    end;

   SetVertexShader(nil);
   SetFVF(VertexType);
   DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, VertexBuf^, SizeOf(TVertexRecord));
  end;

 EffectIndx:= 0;
 FScheluded:= 0;
 Working   := False; 
end;

//---------------------------------------------------------------------------
procedure TMultiCanvas.SetAntialias(const Value: Boolean);
var
 i: Integer;
begin
 FAntialias:= Value;

 if (Direct3DDevice <> nil) then
  begin
   for i:= 0 to MaxStages - 1 do
    if (FAntialias) then
     begin
      Direct3DDevice.SetSamplerState(i, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR);
      Direct3DDevice.SetSamplerState(i, D3DSAMP_MINFILTER, D3DTEXF_LINEAR);
      end else
     begin
      Direct3DDevice.SetSamplerState(i, D3DSAMP_MAGFILTER, D3DTEXF_POINT);
      Direct3DDevice.SetSamplerState(i, D3DSAMP_MINFILTER, D3DTEXF_POINT);
     end;
  end;
end;

//---------------------------------------------------------------------------
procedure TMultiCanvas.WorkWith(Event: TNotifyEvent);
begin
 if (Direct3DDevice = nil)or(not Assigned(Event)) then Exit;

 BeginRender();
 Event(Self);
 EndRender();
end;

//---------------------------------------------------------------------------
procedure TMultiCanvas.Work();
begin
 WorkWith(FOnWork);
end;

//---------------------------------------------------------------------------
end.

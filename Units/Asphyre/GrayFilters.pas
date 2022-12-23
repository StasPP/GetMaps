unit GrayFilters;
//---------------------------------------------------------------------------
// GrayFilter.pas                                       Modified: 23-Dec-2005
// Grayscale "dot-product" Filter                                 Version 1.0
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
 Types, Classes, SysUtils, Direct3D9, DXBase, DXTextures, AsphyreDef, 
 AsphyreImages;

//---------------------------------------------------------------------------
type
 TGrayFilter = class
 private
  VertexBuf : Pointer;
  FAntialias: Boolean;

  procedure PrepareVertexBuf();
  procedure SetupAntialias();
  procedure PrepareStates();
  procedure SetCoords(const Points: TPoint4);
  procedure SetupImage(Image: TDXBaseTexture; const TexCoord: TTexCoord);
  procedure ApplyFilter();
 public
  property Antialias: Boolean read FAntialias write FAntialias;

  procedure Filter(Source: TDXBaseTexture; const Points: TPoint4;
   const TexCoord: TTexCoord);

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//----------------------------------------------------------------------------
const
 VertexType = D3DFVF_XYZRHW or D3DFVF_TEX1;
 WrapIndex: array[0..3] of Integer = (0, 1, 3, 2);

//--------------------------------------------------------------------------
type
 PVertexRecord = ^TVertexRecord;
 TVertexRecord = record
  Vector: TD3DVector;
  rhw   : Single;
  TexPt : TPoint2;
 end;

//---------------------------------------------------------------------------
constructor TGrayFilter.Create();
begin
 inherited;

 VertexBuf:= AllocMem(SizeOf(TVertexRecord) * 4);
 PrepareVertexBuf();

 FAntialias:= True;
end;

//---------------------------------------------------------------------------
destructor TGrayFilter.Destroy();
begin
 FreeMem(VertexBuf);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGrayFilter.PrepareVertexBuf();
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
procedure TGrayFilter.SetupImage(Image: TDXBaseTexture;
 const TexCoord: TTexCoord);
var
 TexNum: Integer;
 TexPts: TPoint4;
 Vertex: PVertexRecord;
 u0, v0, u1, v1: Real;
 i: Integer;
begin
 if (not (Image is TAsphyreImage)) then
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
  end else TAsphyreImage(Image).SelectTexture(TexCoord, TexPts, TexNum);

 Vertex:= VertexBuf;
 for i:= 0 to 3 do
  begin
   Vertex.TexPt.x:= TexPts[WrapIndex[i]].x;
   Vertex.TexPt.y:= TexPts[WrapIndex[i]].y;
   Inc(Vertex);
  end;

 Image.Activate(0, TexNum);
end;

//---------------------------------------------------------------------------
procedure TGrayFilter.SetupAntialias();
begin
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

//---------------------------------------------------------------------------
procedure TGrayFilter.PrepareStates();
{var
 color: TD3DCOLOR;}
begin
 with Direct3DDevice do
  begin
   SetRenderState(D3DRS_ALPHABLENDENABLE, iFalse);
   SetRenderState(D3DRS_ALPHATESTENABLE,  iFalse);

   SetRenderState(D3DRS_TEXTUREFACTOR, $FFFFFFFF);

   SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
   SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_TFACTOR);
   SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
   SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_TFACTOR);

   SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_DOTPRODUCT3);
   SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_ADD);

   SetTextureStageState(1, D3DTSS_COLORARG1, D3DTA_CURRENT);
   SetTextureStageState(1, D3DTSS_COLORARG2, D3DTA_CURRENT);
   SetTextureStageState(1, D3DTSS_ALPHAARG1, D3DTA_CURRENT);
   SetTextureStageState(1, D3DTSS_ALPHAARG2, D3DTA_CURRENT);
   SetTexture(1, nil);
  end;
end;

//---------------------------------------------------------------------------
procedure TGrayFilter.SetCoords(const Points: TPoint4);
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
procedure TGrayFilter.ApplyFilter();
begin
 with Direct3DDevice do
  begin
   SetVertexShader(nil);
   SetFVF(VertexType);
   DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, VertexBuf^, SizeOf(TVertexRecord));
  end;
end;

//---------------------------------------------------------------------------
procedure TGrayFilter.Filter(Source: TDXBaseTexture; const Points: TPoint4;
 const TexCoord: TTexCoord);
begin
 if (Direct3DDevice = nil) then Exit;

 SetupAntialias();
 PrepareStates();
 SetCoords(Points);
 SetupImage(Source, TexCoord);
 ApplyFilter();
end;

//---------------------------------------------------------------------------
end.

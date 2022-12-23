unit AsphyreStates;
//---------------------------------------------------------------------------
// AsphyreStates.pas                                    Modified: 11-Oct-2005
// Rendering state attributes                                     Version 1.0
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
 Windows, Classes, SysUtils, AsphyreDef, Direct3D9, DXBase;

//---------------------------------------------------------------------------
type
 TDeviceState = class(TComponent)
 private
  FAntialiasedTextures: Boolean;
  FSpecularLighting   : Boolean;
  FAntialiasedLines   : Boolean;
  FImageDithering     : Boolean;
  FDepthBuffer        : Boolean;
  FLighting           : Boolean;
  FMipMapping         : Boolean;

  procedure SetAntialias(ValueAA, ValueMip: Boolean);
  procedure SetDithering(Value: Boolean);
  procedure SetDepthBuffer(Value: Boolean);
  procedure SetSmoothLines(Value: Boolean);
  procedure SetLighting(Value: Boolean);
  procedure SetSpecular(Value: Boolean);
  procedure SetParam(const Index: Integer; const Value: Boolean);
  function GetViewport(): TRect;
  procedure SetViewport(const Value: TRect);
 public
  property Viewport: TRect read GetViewport write SetViewport;

  procedure Update();

  constructor Create(AOwner: TComponent); override;
 published
  property AntialiasedTextures: Boolean index 0 read FAntialiasedTextures write SetParam;
  property ImageDithering     : Boolean index 1 read FImageDithering write SetParam;
  property DepthBuffer        : Boolean index 2 read FDepthBuffer write SetParam;
  property AntialiasedLines   : Boolean index 3 read FAntialiasedLines write SetParam;
  property Lighting           : Boolean index 4 read FLighting write SetParam;
  property MipMapping         : Boolean index 5 read FMipMapping write SetParam;
  property SpecularLighting   : Boolean index 6 read FSpecularLighting write SetParam;
 end;


//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TDeviceState.Create(AOwner: TComponent);
begin
 inherited;

 FAntialiasedTextures:= True;
 FImageDithering     := True;
 FDepthBuffer        := True;
 FAntialiasedLines   := True;
 FMipMapping         := True;
 FSpecularLighting   := True;
end;

//---------------------------------------------------------------------------
procedure TDeviceState.SetAntialias(ValueAA, ValueMip: Boolean);
var
 Index: Integer;
begin
 for Index:= 0 to 7 do
  begin
   if (ValueAA) then
    begin
     Direct3DDevice.SetSamplerState(Index, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR);
     Direct3DDevice.SetSamplerState(Index, D3DSAMP_MINFILTER, D3DTEXF_LINEAR);
     end else
    begin
     Direct3DDevice.SetSamplerState(Index, D3DSAMP_MAGFILTER, D3DTEXF_POINT);
     Direct3DDevice.SetSamplerState(Index, D3DSAMP_MINFILTER, D3DTEXF_POINT);
    end;

   if (ValueMip) then
    begin
     if (ValueAA) then
      Direct3DDevice.SetSamplerState(Index, D3DSAMP_MIPFILTER, D3DTEXF_LINEAR)
       else Direct3DDevice.SetSamplerState(Index, D3DSAMP_MIPFILTER, D3DTEXF_POINT);
    end else
    begin
     Direct3DDevice.SetSamplerState(Index, D3DSAMP_MIPFILTER, D3DTEXF_NONE);
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TDeviceState.SetDithering(Value: Boolean);
begin
 Direct3DDevice.SetRenderState(D3DRS_DITHERENABLE, Cardinal(Value));
end;

//---------------------------------------------------------------------------
procedure TDeviceState.SetDepthBuffer(Value: Boolean);
var
 Aux: Cardinal;
begin
 // retreive current Z-Buffer state
 Direct3DDevice.GetRenderState(D3DRS_ZENABLE, Aux);

 // verify if the state needs to be updated
 if (Aux = D3DZB_TRUE)and(not Value) then
  Direct3DDevice.SetRenderState(D3DRS_ZENABLE, D3DZB_FALSE);

 if (Aux = D3DZB_FALSE)and(Value) then
  Direct3DDevice.SetRenderState(D3DRS_ZENABLE, D3DZB_TRUE);
end;

//---------------------------------------------------------------------------
procedure TDeviceState.SetSmoothLines(Value: Boolean);
begin
 Direct3DDevice.SetRenderState(D3DRS_ANTIALIASEDLINEENABLE, Cardinal(Value));
end;

//---------------------------------------------------------------------------
procedure TDeviceState.SetLighting(Value: Boolean);
begin
 Direct3DDevice.SetRenderState(D3DRS_LIGHTING, Cardinal(Value));
end;

//---------------------------------------------------------------------------
procedure TDeviceState.SetSpecular(Value: Boolean);
begin
 Direct3DDevice.SetRenderState(D3DRS_SPECULARENABLE, Cardinal(Value));
end;

//---------------------------------------------------------------------------
procedure TDeviceState.SetParam(const Index: Integer; const Value: Boolean);
begin
 case Index of
  0: FAntialiasedTextures:= Value;
  1: FImageDithering     := Value;
  2: FDepthBuffer        := Value;
  3: FAntialiasedLines   := Value;
  4: FLighting           := Value;
  5: FMipMapping         := Value;
  6: FSpecularLighting   := Value;
 end;

 if (Direct3DDevice <> nil) then
  case Index of
   0: SetAntialias(FAntialiasedTextures, FMipMapping);
   1: SetDithering(FImageDithering);
   2: SetDepthBuffer(FDepthBuffer);
   3: SetSmoothLines(FAntialiasedLines);
   4: SetLighting(FLighting);
   5: SetAntialias(FAntialiasedTextures, FMipMapping);
   6: SetSpecular(FSpecularLighting);
  end;
end;

//---------------------------------------------------------------------------
procedure TDeviceState.Update();
begin
 SetAntialias(FAntialiasedTextures, FMipMapping);
 SetDithering(FImageDithering);
 SetDepthBuffer(FDepthBuffer);
 SetSmoothLines(FAntialiasedLines);
 SetLighting(FLighting);
 SetSpecular(FSpecularLighting);
end;

//---------------------------------------------------------------------------
function TDeviceState.GetViewport(): TRect;
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
procedure TDeviceState.SetViewport(const Value: TRect);
var
 vp: TD3DViewport9;
begin
 if (Direct3DDevice = nil) then Exit;

 vp.X:= Value.Left;
 vp.Y:= Value.Top;
 vp.Width := (Value.Right - Value.Left);
 vp.Height:= (Value.Bottom - Value.Top);
 vp.MinZ:= 0.0;
 vp.MaxZ:= 1.0;

 Direct3DDevice.SetViewport(vp);
end;

//---------------------------------------------------------------------------
end.

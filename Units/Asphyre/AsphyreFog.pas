unit AsphyreFog;
//---------------------------------------------------------------------------
// AsphyreFog.pas                                       Modified: 10-Oct-2005
// Asphyre 3D fog implementation using Direct3D                   Version 1.0
//--------------------------------------------------------------------------
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
 Types, Classes, SysUtils, Graphics, Math, AsphyreDef, Direct3D9,
 DXBase, AsphyreConv;

//--------------------------------------------------------------------------
type
 TFogMode = (fmLinear, fmExp, fmExp2);

//--------------------------------------------------------------------------
 TFogType = (ftPixel, ftVertex);

//--------------------------------------------------------------------------
 TAsphyreFog = class(TComponent)
 private
  FColor   : TColor;
  FDensity : Real;
  FFogMode : TFogMode;
  FFogStart: Real;
  FFogEnd  : Real;
  FFogType : TFogType;

  procedure SetFogAttr(const Index: Integer; const Value: Real);
 public
  procedure Enable();
  procedure Disable();

  constructor Create(AOwner: TComponent); override;
 published
  property Color   : TColor read FColor write FColor;
  property Density : Real read FDensity write FDensity;
  property FogMode : TFogMode read FFogMode write FFogMode;
  property FogStart: Real index 0 read FFogStart write SetFogAttr;
  property FogEnd  : Real index 1 read FFogEnd write SetFogAttr;
  property FogType : TFogType read FFogType write FFogType;
 end;

//--------------------------------------------------------------------------
implementation

//--------------------------------------------------------------------------
constructor TAsphyreFog.Create(AOwner: TComponent);
begin
 inherited;

 FColor   := clWhite;
 FDensity := 0.67;
 FFogMode := fmLinear;
 FFogStart:= 0.5;
 FFogEnd  := 0.8;
 FFogType := ftPixel;
end;

//--------------------------------------------------------------------------
procedure TAsphyreFog.SetFogAttr(const Index: Integer; const Value: Real);
begin
 case Index of
  0: FFogStart:= Value;
  1: FFogEnd  := Value;
 end;
end;

//--------------------------------------------------------------------------
procedure TAsphyreFog.Enable();
var
 D3DMode: Cardinal;
 Aux    : Single;
begin
 if (Direct3DDevice = nil) then Exit;

 D3DMode:= D3DFOG_NONE;
 case FFogMode of
  fmLinear: D3DMode:= D3DFOG_LINEAR;
  fmExp   : D3DMode:= D3DFOG_EXP;
  fmExp2  : D3DMode:= D3DFOG_EXP2;
 end;


 with Direct3DDevice do
  begin
   // Enable fog blending
   SetRenderState(D3DRS_FOGENABLE, Cardinal(True));

   // Set the fog color
   SetRenderState(D3DRS_FOGCOLOR, DisplaceRB(FColor));

   // Pixel vs Vertex FOG
   if (FFogType = ftPixel) then
    begin
     SetRenderState(D3DRS_FOGTABLEMODE, D3DMode);
    end else
    begin // VERTEX FOG
     SetRenderState(D3DRS_FOGVERTEXMODE, D3DMode);
    end;

   // Start & End (Linear) vs Density (Exp/2)
   if (FFogMode = fmLinear) then
    begin
     Aux:= FFogStart;
     SetRenderState(D3DRS_FOGSTART, PCardinal(@Aux)^);

     Aux:= FFogEnd;
     SetRenderState(D3DRS_FOGEND, PCardinal(@Aux)^);
    end else
    begin
     Aux:= FDensity;
     SetRenderState(D3DRS_FOGDENSITY, PCardinal(@Aux)^);
    end;
  end; // with
end;

//--------------------------------------------------------------------------
procedure TAsphyreFog.Disable();
begin
 if (Direct3DDevice <> nil) then
  Direct3DDevice.SetRenderState(D3DRS_FOGENABLE, Cardinal(False));
end;

//--------------------------------------------------------------------------
end.

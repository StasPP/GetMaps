unit AsphyreLights;
//---------------------------------------------------------------------------
// AsphyreLights.pas                                    Modified: 10-Oct-2005
// Multiple light sources implementation                          Version 1.0
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

//--------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, Direct3D9, DXBase, AsphyreDef, AsphyreMath;

//--------------------------------------------------------------------------
type
 TLightType = (ltOmni, ltDirectional, ltSpot);

//--------------------------------------------------------------------------
 TAsphyreLight = class
 private
  FEnabled  : Boolean;
  FDiffuse  : Longword;
  FSpecular : Longword;
  FAmbient  : Longword;
  FOrigin   : TPoint3;
  FTarget   : TPoint3;
  FRange    : Real;
  FTheta    : Real;
  FPhi      : Real;
  FLightType: TLightType;
  FIndex    : Integer;
 public
  property Enabled  : Boolean read FEnabled write FEnabled;
  property LightType: TLightType read FLightType write FLightType;
  property Diffuse  : Longword read FDiffuse write FDiffuse;
  property Specular : Longword read FSpecular write FSpecular;
  property Ambient  : Longword read FAmbient write FAmbient;
  property Origin   : TPoint3 read FOrigin write FOrigin;
  property Target   : TPoint3 read FTarget write FTarget;
  property Range    : Real read FRange write FRange;
  property Theta    : Real read FTheta write FTheta;
  property Phi      : Real read FPhi write FPhi;

  property Index    : Integer read FIndex write FIndex;

  procedure Update();

  constructor Create();
 end;

//--------------------------------------------------------------------------
 TAsphyreLights = class(TComponent)
 private
  Data: array of TAsphyreLight;

  function GetItem(Num: Integer): TAsphyreLight;
  procedure SetItem(Num: Integer; const Value: TAsphyreLight);
  function GetCount(): Integer;
 public
  property Count: Integer read GetCount;
  property Items[Num: Integer]: TAsphyreLight read GetItem write SetItem; default;

  function Add(): TAsphyreLight;
  function Find(Light: TAsphyreLight): Integer;
  procedure Remove(Num: Integer);
  procedure RemoveAll();

  procedure Update();

  destructor Destroy(); override;
 end;

//--------------------------------------------------------------------------
implementation

//--------------------------------------------------------------------------
constructor TAsphyreLight.Create();
begin
 inherited;

 FIndex   := -1;
 FEnabled := True;
 FDiffuse := $FFFFFF;
 FSpecular:= $202020;
 FAmbient := $202020;
 FOrigin  := Point3(0.0, 0.0, 0.0);
 FTarget  := Point3(0.0, 0.0, 1.0);
 FRange   := 1000.0;
 FTheta   := pi / 8.0;
 FPhi     := pi / 6.0;
end;

//--------------------------------------------------------------------------
procedure TAsphyreLight.Update();
var
 MyLight: TD3DLight9;
begin
 if (Direct3DDevice = nil) then Exit;
 
 FillChar(MyLight, SizeOf(TD3DLight9), 0);

 case LightType of
  ltOmni       : MyLight._Type:= D3DLIGHT_POINT;
  ltDirectional: MyLight._Type:= D3DLIGHT_DIRECTIONAL;
  ltSpot       : MyLight._Type:= D3DLIGHT_SPOT;
 end;

 MyLight.Diffuse  := D3DColor(Diffuse);
 MyLight.Specular := D3DColor(Specular);
 MyLight.Ambient  := D3DColor(Ambient);
 MyLight.Position := D3DPoint(Origin);
 MyLight.Direction:= D3DPoint(VecNorm3(VecToFrom3(Target, Origin)));
 MyLight.Range    := Range;
 MyLight.Falloff  := 1.0;
 MyLight.Attenuation0:= 1.0;
 MyLight.Attenuation1:= 0.0;
 MyLight.Attenuation2:= 0.0;
 MyLight.Theta    := Theta;
 MyLight.Phi      := Phi;

 with Direct3DDevice do
  begin
   SetLight(Index, MyLight);
   LightEnable(Index, Enabled);
  end;
end;

//--------------------------------------------------------------------------
destructor TAsphyreLights.Destroy();
begin
 RemoveAll();

 inherited;
end;

//--------------------------------------------------------------------------
function TAsphyreLights.GetItem(Num: Integer): TAsphyreLight;
begin
 Result:= Data[Num];
end;

//--------------------------------------------------------------------------
procedure TAsphyreLights.SetItem(Num: Integer; const Value: TAsphyreLight);
begin
 Data[Num]:= Value;
end;

//--------------------------------------------------------------------------
function TAsphyreLights.GetCount(): Integer;
begin
 Result:= Length(Data);
end;

//--------------------------------------------------------------------------
function TAsphyreLights.Add(): TAsphyreLight;
var
 Index: Integer;
begin
 Index:= Length(Data);
 SetLength(Data, Index + 1);

 Data[Index]:= TAsphyreLight.Create();
 Data[Index].Index:= Index;
 Result:= Data[Index];
end;

//--------------------------------------------------------------------------
procedure TAsphyreLights.Remove(Num: Integer);
var
 i: Integer;
begin
 if (Num < 0)or(Num >= Length(Data)) then Exit;

 Data[Num].Free();

 for i:= Num to Length(Data) - 2 do
  begin
   Data[i]:= Data[i + 1];
   Data[i].Index:= i;
  end;

 SetLength(Data, Length(Data) - 1);
end;

//--------------------------------------------------------------------------
procedure TAsphyreLights.RemoveAll();
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  begin
   Data[i].Free();
   Data[i]:= nil;
  end;

 SetLength(Data, 0);  
end;

//--------------------------------------------------------------------------
procedure TAsphyreLights.Update();
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  Data[i].Update();
end;

//--------------------------------------------------------------------------
function TAsphyreLights.Find(Light: TAsphyreLight): Integer;
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  if (Data[i] = Light) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= -1;   
end;

//--------------------------------------------------------------------------
end.

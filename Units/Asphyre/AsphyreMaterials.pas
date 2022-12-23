unit AsphyreMaterials;
//---------------------------------------------------------------------------
// AsphyreMaterials.pas                                 Modified: 10-Oct-2005
// Mesh material implementation                                   Version 1.0
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
 Windows, Types, Classes, SysUtils, Direct3D9, DXBase, AsphyreDef;

//--------------------------------------------------------------------------
type
 TAsphyreMaterial = class
 private
  FDiffuse  : Longword;
  FSpecular : Longword;
  FAmbient  : Longword;
  FEmissive : Longword;
  FShininess: Real;

 public
  property Diffuse  : Longword read FDiffuse write FDiffuse;
  property Specular : Longword read FSpecular write FSpecular;
  property Ambient  : Longword read FAmbient write FAmbient;
  property Emissive : Longword read FEmissive write FEmissive;
  property Shininess: Real read FShininess write FShininess;

  procedure Activate();

  constructor Create();
 end;

//--------------------------------------------------------------------------
 TAsphyreMaterials = class(TComponent)
 private
  Data: array of TAsphyreMaterial;
  FActiveMaterial: Integer;

  function GetMaterial(Num: Integer): TAsphyreMaterial;
  function GetCount(): Integer;
  procedure SetActiveMaterial(const Value: Integer);
 public
  property Count: Integer read GetCount;
  property Material[Num: Integer]: TAsphyreMaterial read GetMaterial; default;
  property ActiveMaterial: Integer read FActiveMaterial write SetActiveMaterial;

  function Add(): TAsphyreMaterial;
  function Find(Material: TAsphyreMaterial): Integer;
  procedure Remove(Num: Integer);
  procedure RemoveAll();

  constructor Create(AOwner: TComponent); override;
  destructor Destroy(); override;
 end;

//--------------------------------------------------------------------------
implementation

//--------------------------------------------------------------------------
constructor TAsphyreMaterial.Create();
begin
 inherited;

 FDiffuse  := $FFFFFFFF;
 FAmbient  := $FFFFFFFF;
 FSpecular := $FFFFFFFF;
 FEmissive := $FF000000;
 FShininess:= 20.0;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMaterial.Activate();
var
 Material: TD3DMaterial9;
begin
 if (Direct3DDevice = nil) then Exit;

 // initialize material properties
 Material.Ambient := D3DColor(Ambient);
 Material.Diffuse := D3DColor(Diffuse);
 Material.Emissive:= D3DColor(Emissive);
 if (Specular and $FFFFFF > 0) then
  begin
   Material.Power   := Shininess;
   Material.Specular:= D3DColor(Specular);
  end else
  begin
   Material.Power:= 0.0;
   Material.Specular:= D3DColor($00000000);
  end;

 // update Direct3D material
 Direct3DDevice.SetMaterial(Material);
end;

//--------------------------------------------------------------------------
constructor TAsphyreMaterials.Create(AOwner: TComponent);
begin
 inherited;

 FActiveMaterial:= -1;
end;

//--------------------------------------------------------------------------
destructor TAsphyreMaterials.Destroy();
begin
 RemoveAll();

 inherited;
end;

//--------------------------------------------------------------------------
procedure TAsphyreMaterials.SetActiveMaterial(const Value: Integer);
begin
 if (Value >= 0)and(Value < Length(Data)) then
  begin
   FActiveMaterial:= Value;
   Data[Value].Activate();
  end else FActiveMaterial:= -1; 
end;

//--------------------------------------------------------------------------
function TAsphyreMaterials.GetMaterial(Num: Integer): TAsphyreMaterial;
begin
 if (Num >= 0)and(Num < Length(Data)) then Result:= Data[Num] else Result:= nil;
end;

//--------------------------------------------------------------------------
function TAsphyreMaterials.GetCount(): Integer;
begin
 Result:= Length(Data);
end;

//--------------------------------------------------------------------------
function TAsphyreMaterials.Add(): TAsphyreMaterial;
var
 Index: Integer;
begin
 Index:= Length(Data);
 SetLength(Data, Index + 1);

 Data[Index]:= TAsphyreMaterial.Create();
 Result:= Data[Index];

 // activate the material, if no material is active
 if (ActiveMaterial = -1) then ActiveMaterial:= Index;
end;

//--------------------------------------------------------------------------
procedure TAsphyreMaterials.Remove(Num: Integer);
var
 i: Integer;
begin
 if (Num < 0)or(Num >= Length(Data)) then Exit;

 Data[Num].Free();

 for i:= Num to Length(Data) - 2 do
  Data[i]:= Data[i + 1];

 SetLength(Data, Length(Data) - 1);

 // update the currently active material
 if (ActiveMaterial = Num) then ActiveMaterial:= 0;
end;

//--------------------------------------------------------------------------
procedure TAsphyreMaterials.RemoveAll();
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  begin
   Data[i].Free();
   Data[i]:= nil;
  end;

 SetLength(Data, 0);
 FActiveMaterial:= -1;
end;

//--------------------------------------------------------------------------
function TAsphyreMaterials.Find(Material: TAsphyreMaterial): Integer;
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  if (Data[i] = Material) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= -1;
end;

//--------------------------------------------------------------------------
end.

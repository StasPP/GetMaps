unit DXTextures;
//---------------------------------------------------------------------------
// DXTextures.pas                                       Modified: 27-Sep-2005
// Direct3D Texture Framework for Asphyre                         Version 2.0
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
 Windows, Types, Classes, SysUtils, AsphyreDef, Direct3D9, DXBase;

//---------------------------------------------------------------------------
// Cube Map Face constants to be passed as Tag value
//---------------------------------------------------------------------------
const
 cmfTop    = 0;
 cmfBottom = 1;
 cmfLeft   = 2;
 cmfRight  = 3;
 cmfFront  = 4;
 cmfBack   = 5;

//---------------------------------------------------------------------------
type
 TDXTextureState = (tsNotReady, tsReady, tsLost, tsFailure);

//---------------------------------------------------------------------------
 TDXTextureBehavior = (tbManaged, tbUnmanaged, tbDynamic, tbRTarget);

//---------------------------------------------------------------------------
 TDXLockFlags = (lfNormal, lfReadOnly, lfWriteOnly);

//---------------------------------------------------------------------------
 TDXAccessInfo = record
  Bits  : Pointer;
  Pitch : Integer;
  Format: TColorFormat;
 end; 

//---------------------------------------------------------------------------
 TDXBaseTexture = class
 private
  FSize: TPoint;
  FMipmapping: Boolean;

  procedure SetMipMapping(const Value: Boolean);
  procedure SetSize(const Value: TPoint);
 protected
  FState: TDXTextureState;
  FFormat: TD3DFormat;
  FBehavior: TDXTextureBehavior;

  function Prepare(): Boolean; virtual;
  function MakeReady(): Boolean; virtual; abstract;
  procedure MakeNotReady(); virtual; abstract;
  function RetreiveUsage(): Cardinal; virtual; abstract;
 public
  property Size: TPoint read FSize write SetSize;
  property State: TDXTextureState read FState;
  property Format: TD3DFormat read FFormat;
  property Behavior: TDXTextureBehavior read FBehavior;
  property MipMapping: Boolean read FMipmapping write SetMipMapping;

  //-------------------------------------------------------------------------
  // ChangeState()
  //
  // Attempts to change the state of texture. The outcome will be reflected
  // in State property.
  //-------------------------------------------------------------------------
  procedure ChangeState(NewState: TDXTextureState);

  //-------------------------------------------------------------------------
  // Activates the texture at the specified Stage. Tag property may control
  // additional parameters (like "which" texture to activate, etc.)
  //-------------------------------------------------------------------------
  function Activate(Stage: Cardinal; Tag: Integer): Boolean; virtual; abstract;

  //-------------------------------------------------------------------------
  // Lock the entire texture for direct access.
  //-------------------------------------------------------------------------
  function Lock(Tag: Integer; Flags: TDXLockFlags;
   out Access: TDXAccessInfo): Boolean; virtual; abstract;

  //-------------------------------------------------------------------------
  // Lock the specific area of texture for direct access.
  //-------------------------------------------------------------------------
  function LockRect(Tag: Integer; const LockArea: TRect; Flags: TDXLockFlags;
   out Access: TDXAccessInfo): Boolean; virtual; abstract;

  //-------------------------------------------------------------------------
  // Unlock previously locked texture.
  //-------------------------------------------------------------------------
  function Unlock(Tag: Integer): Boolean; virtual; abstract;

  constructor Create(); dynamic;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
// Single texture implementation.
//---------------------------------------------------------------------------
 TDXMonoTexture = class(TDXBaseTexture)
 private
  FTexture9: IDirect3DTexture9;
 protected
  function RetreiveUsage(): Cardinal; override;
  function MakeReady(): Boolean; override;
  procedure MakeNotReady(); override;
 public
  property Texture9: IDirect3DTexture9 read FTexture9;

  function Lock(Tag: Integer; Flags: TDXLockFlags;
   out Access: TDXAccessInfo): Boolean; override;
  function LockRect(Tag: Integer; const LockArea: TRect; Flags: TDXLockFlags;
   out Access: TDXAccessInfo): Boolean; override;
  function Unlock(Tag: Integer): Boolean; override;

  function Activate(Stage: Cardinal; Tag: Integer): Boolean; override;

  constructor Create(); override;
 end;

//---------------------------------------------------------------------------
// Multiple textures implementation.
//  -> Managed behavior is forced.
//  -> TAG is a texture number in Lock / Unlock / Activate operations.
//---------------------------------------------------------------------------
 TDXMultiTexture = class(TDXBaseTexture)
 private
  Textures: array of IDirect3DTexture9;
  FTextureCount: Integer;

  procedure SetTextureCount(const Value: Integer);
  function GetTexture(Num: Integer): IDirect3DTexture9;
 protected
  function RetreiveUsage(): Cardinal; override;
  function MakeReady(): Boolean; override;
  procedure MakeNotReady(); override;
 public
  property Texture[Num: Integer]: IDirect3DTexture9 read GetTexture;
  property TextureCount: Integer read FTextureCount write SetTextureCount;

  function Lock(Tag: Integer; Flags: TDXLockFlags;
   out Access: TDXAccessInfo): Boolean; override;
  function LockRect(Tag: Integer; const LockArea: TRect; Flags: TDXLockFlags;
   out Access: TDXAccessInfo): Boolean; override;
  function Unlock(Tag: Integer): Boolean; override;

  function Activate(Stage: Cardinal; Tag: Integer): Boolean; override;

  constructor Create(); override;
 end;

//---------------------------------------------------------------------------
// Cubemap implementation.
//  -> TAG indicates texture cube face in Lock / Unlock operations.
//---------------------------------------------------------------------------
 TDXCubeTexture = class(TDXBaseTexture)
 private
  FTexture9: IDirect3DCubeTexture9;
 protected
  function RetreiveUsage(): Cardinal; override;
  function MakeReady(): Boolean; override;
  procedure MakeNotReady(); override;
 public
  property Texture9: IDirect3DCubeTexture9 read FTexture9;

  function Lock(Tag: Integer; Flags: TDXLockFlags;
   out Access: TDXAccessInfo): Boolean; override;
  function LockRect(Tag: Integer; const LockArea: TRect; Flags: TDXLockFlags;
   out Access: TDXAccessInfo): Boolean; override;
  function Unlock(Tag: Integer): Boolean; override;

  function Activate(Stage: Cardinal; Tag: Integer): Boolean; override;

  constructor Create(); override;
 end;

//---------------------------------------------------------------------------
function DXCubeMapFace(Face: Integer): TD3DCubemapFaces;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
function DXCubeMapFace(Face: Integer): TD3DCubemapFaces;
begin
 case Face of
  cmfTop   : Result:= D3DCUBEMAP_FACE_POSITIVE_Y;
  cmfBottom: Result:= D3DCUBEMAP_FACE_NEGATIVE_Y;
  cmfLeft  : Result:= D3DCUBEMAP_FACE_NEGATIVE_X;
  cmfRight : Result:= D3DCUBEMAP_FACE_POSITIVE_X;
  cmfFront : Result:= D3DCUBEMAP_FACE_POSITIVE_Z;
  cmfBack  : Result:= D3DCUBEMAP_FACE_NEGATIVE_Z;
  else Result:= TD3DCubemapFaces(0);
 end;
end;

//---------------------------------------------------------------------------
constructor TDXBaseTexture.Create();
begin
 inherited;

 FSize      := Point(256, 256);
 FState     := tsNotReady;
 FBehavior  := tbManaged;
 FMipMapping:= True;
 FFormat    := D3DFMT_UNKNOWN;
end;

//---------------------------------------------------------------------------
destructor TDXBaseTexture.Destroy();
begin
 if (FState <> tsNotReady) then ChangeState(tsNotReady);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TDXBaseTexture.SetSize(const Value: TPoint);
begin
 if (FState = tsNotReady) then FSize:= Value;
end;

//---------------------------------------------------------------------------
procedure TDXBaseTexture.SetMipMapping(const Value: Boolean);
begin
 if (FState = tsNotReady) then FMipMapping:= Value;
end;

//---------------------------------------------------------------------------
function TDXBaseTexture.Prepare(): Boolean;
begin
 Result:= True;
end;

//---------------------------------------------------------------------------
procedure TDXBaseTexture.ChangeState(NewState: TDXTextureState);
begin
 if (FState = tsNotReady)and(NewState = tsReady) then
  begin
   if (Prepare())and(MakeReady()) then FState:= tsReady;
  end else
 if (NewState = tsNotReady) then
  begin
   if (FState = tsReady) then MakeNotReady();
   FState:= tsNotReady;
  end else
 if (FState = tsReady)and(NewState = tsLost)and(FBehavior <> tbManaged) then
  begin
   MakeNotReady();
   FState:= tsLost;
  end else
 if (FState = tsLost)and(NewState = tsReady) then
  begin
   if (MakeReady()) then
    FState:= tsReady else FState:= tsFailure;
  end else
 if (FState = tsFailure)and(NewState = tsReady) then
  begin
   if (MakeReady()) then FState:= tsReady;
  end;
end;

//---------------------------------------------------------------------------
constructor TDXMonoTexture.Create();
begin
 inherited;

 FTexture9:= nil;
end;

//---------------------------------------------------------------------------
function TDXMonoTexture.RetreiveUsage(): Cardinal;
begin
 Result:= 0;

 if (FMipMapping) then
  Result:= Result or D3DUSAGE_AUTOGENMIPMAP;

 case FBehavior of
  tbDynamic: Result:= Result or D3DUSAGE_DYNAMIC;
  tbRTarget: Result:= Result or D3DUSAGE_RENDERTARGET;
 end;
end;

//---------------------------------------------------------------------------
function TDXMonoTexture.MakeReady(): Boolean;
var
 Res   : Integer;
 Pool  : TD3DPool;
 Usage : Cardinal;
 Levels: Integer;
begin
 // (1) Determine texture POOL.
 Pool:= D3DPOOL_DEFAULT;
 if (FBehavior = tbManaged) then Pool:= D3DPOOL_MANAGED;

 // (2) Apply MipMapping request.
 if (FMipMapping) then
  begin
   Usage := D3DUSAGE_AUTOGENMIPMAP;
   Levels:= 0;
  end else
  begin
   Usage := 0;
   Levels:= 1;
  end;

 // (3) Determine texture USAGE.
 case FBehavior of
  tbDynamic: Usage:= Usage or D3DUSAGE_DYNAMIC;
  tbRTarget: Usage:= Usage or D3DUSAGE_RENDERTARGET;
 end;

 // (4) Attempt to create the texture.
 Res:= Direct3DDevice.CreateTexture(FSize.X, FSize.Y, Levels, Usage, FFormat,
  Pool, FTexture9, nil);
 Result:= (Succeeded(Res));
end;

//---------------------------------------------------------------------------
procedure TDXMonoTexture.MakeNotReady();
begin
 if (FTexture9 <> nil) then FTexture9:= nil;
end;

//---------------------------------------------------------------------------
function TDXMonoTexture.Lock(Tag: Integer; Flags: TDXLockFlags;
 out Access: TDXAccessInfo): Boolean;
var
 LockedRect: TD3DLocked_Rect;
 Usage: Cardinal;
begin
 // (1) Verify conditions.
 if (FTexture9 = nil) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Determine USAGE.
 Usage:= 0;
 if (Flags = lfReadOnly) then Usage:= D3DLOCK_READONLY;
 if (Flags = lfWriteOnly)and(FBehavior = tbDynamic) then
  Usage:= D3DLOCK_DISCARD;

 // (3) Lock the entire texture.
 Result:= Succeeded(FTexture9.LockRect(0, LockedRect, nil, Usage));

 // (4) Return access information.
 if (Result) then
  begin
   Access.Bits  := LockedRect.pBits;
   Access.Pitch := LockedRect.Pitch;
   Access.Format:= D3DToFormat(FFormat);
  end; 
end;

//---------------------------------------------------------------------------
function TDXMonoTexture.LockRect(Tag: Integer; const LockArea: TRect;
 Flags: TDXLockFlags; out Access: TDXAccessInfo): Boolean;
var
 LockedRect: TD3DLocked_Rect;
 Usage: Cardinal;
begin
 // (1) Verify conditions.
 if (FTexture9 = nil) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Determine USAGE.
 Usage:= 0;
 if (Flags = lfReadOnly) then Usage:= D3DLOCK_READONLY;
 if (Flags = lfWriteOnly)and(FBehavior = tbDynamic) then
  Usage:= D3DLOCK_DISCARD;

 // (3) Lock the region of texture.
 Result:= Succeeded(FTexture9.LockRect(0, LockedRect, @LockArea, Usage));

 // (4) Return access information.
 if (Result) then
  begin
   Access.Bits  := LockedRect.pBits;
   Access.Pitch := LockedRect.Pitch;
   Access.Format:= D3DToFormat(FFormat);
  end; 
end;

//---------------------------------------------------------------------------
function TDXMonoTexture.Unlock(Tag: Integer): Boolean;
begin
 Result:= (FTexture9 <> nil)and(Succeeded(FTexture9.UnlockRect(0)));
end;

//---------------------------------------------------------------------------
function TDXMonoTexture.Activate(Stage: Cardinal; Tag: Integer): Boolean;
begin
 Result:= (FTexture9 <> nil)and(Succeeded(Direct3DDevice.SetTexture(Stage,
  FTexture9)));
end;

//---------------------------------------------------------------------------
constructor TDXMultiTexture.Create();
begin
 inherited;

 FTextureCount:= 1;
 FBehavior:= tbManaged;
end;

//---------------------------------------------------------------------------
procedure TDXMultiTexture.SetTextureCount(const Value: Integer);
begin
 if (FState = tsNotReady) then FTextureCount:= Value;
 if (FTextureCount < 0) then FTextureCount:= 0;
end;

//---------------------------------------------------------------------------
function TDXMultiTexture.GetTexture(Num: Integer): IDirect3DTexture9;
begin
 if (Num >= 0)and(Num < Length(Textures)) then
  Result:= Textures[Num] else Result:= nil;
end;

//---------------------------------------------------------------------------
function TDXMultiTexture.RetreiveUsage(): Cardinal;
begin
 Result:= 0;
 if (FMipMapping) then Result:= D3DUSAGE_AUTOGENMIPMAP;
end;

//---------------------------------------------------------------------------
function TDXMultiTexture.MakeReady(): Boolean;
var
 Usage : Cardinal;
 Levels: Cardinal;
 i, Res: Integer;
begin
 Result:= True;

 // (1) USAGE & Mip-map Levels
 if (FMipMapping) then
  begin
   Usage := D3DUSAGE_AUTOGENMIPMAP;
   Levels:= 0;
  end else
  begin
   Usage := 0;
   Levels:= 1;
  end;

 // (2) Initialize texture array.
 SetLength(Textures, FTextureCount);
 for i:= 0 to Length(Textures) - 1 do
  Textures[i]:= nil;

 // (3) Create Direct3D textures.
 for i:= 0 to Length(Textures) - 1 do
  begin
   Res:= Direct3DDevice.CreateTexture(FSize.X, FSize.Y, Levels, Usage, FFormat,
    D3DPOOL_MANAGED, Textures[i], nil);
   if (Failed(Res)) then
    begin
     // -> Release textures that were created successfully.
     MakeNotReady();
     Result:= False;
     Break;
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TDXMultiTexture.MakeNotReady();
var
 i: Integer;
begin
 for i:= 0 to Length(Textures) - 1 do
  if (Textures[i] <> nil) then Textures[i]:= nil;

 SetLength(Textures, 0);
end;

//---------------------------------------------------------------------------
function TDXMultiTexture.Lock(Tag: Integer; Flags: TDXLockFlags;
 out Access: TDXAccessInfo): Boolean;
var
 LockedRect: TD3DLocked_Rect;
 Usage: Cardinal;
begin
 // (1) Verify conditions.
 if (Tag < 0)or(Tag >= Length(Textures))or(Textures[Tag] = nil) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Determine USAGE.
 Usage:= 0;
 if (Flags = lfReadOnly) then Usage:= D3DLOCK_READONLY;

 // (3) Lock the entire texture.
 Result:= Succeeded(Textures[Tag].LockRect(0, LockedRect, nil, Usage));

 // (4) Return access information.
 if (Result) then
  begin
   Access.Bits  := LockedRect.pBits;
   Access.Pitch := LockedRect.Pitch;
   Access.Format:= D3DToFormat(FFormat);
  end; 
end;

//---------------------------------------------------------------------------
function TDXMultiTexture.LockRect(Tag: Integer; const LockArea: TRect;
 Flags: TDXLockFlags; out Access: TDXAccessInfo): Boolean;
var
 LockedRect: TD3DLocked_Rect;
 Usage: Cardinal;
begin
 // (1) Verify conditions.
 if (Tag < 0)or(Tag >= Length(Textures))or(Textures[Tag] = nil) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Determine USAGE.
 Usage:= 0;
 if (Flags = lfReadOnly) then Usage:= D3DLOCK_READONLY;

 // (3) Lock the entire texture.
 Result:= Succeeded(Textures[Tag].LockRect(0, LockedRect, @LockArea, Usage));

 // (4) Return access information.
 if (Result) then
  begin
   Access.Bits  := LockedRect.pBits;
   Access.Pitch := LockedRect.Pitch;
   Access.Format:= D3DToFormat(FFormat);
  end; 
end;

//---------------------------------------------------------------------------
function TDXMultiTexture.Unlock(Tag: Integer): Boolean;
begin
 Result:= (Tag >= 0)and(Tag < Length(Textures))and(Textures[Tag] <> nil)and
  (Succeeded(Textures[Tag].UnlockRect(0)));
end;

//---------------------------------------------------------------------------
function TDXMultiTexture.Activate(Stage: Cardinal; Tag: Integer): Boolean;
begin
 Result:= (Tag >= 0)and(Tag < Length(Textures))and(Textures[Tag] <> nil)and
  (Succeeded(Direct3DDevice.SetTexture(Stage, Textures[Tag])));
end;

//---------------------------------------------------------------------------
constructor TDXCubeTexture.Create();
begin
 inherited;

 FTexture9:= nil;
end;

//---------------------------------------------------------------------------
function TDXCubeTexture.RetreiveUsage(): Cardinal;
begin
 Result:= 0;
 if (FMipMapping) then Result:= D3DUSAGE_AUTOGENMIPMAP;

 case FBehavior of
  tbDynamic: Result:= Result or D3DUSAGE_DYNAMIC;
  tbRTarget: Result:= Result or D3DUSAGE_RENDERTARGET;
 end;
end;

//---------------------------------------------------------------------------
function TDXCubeTexture.MakeReady(): Boolean;
var
 Res   : Integer;
 Pool  : TD3DPool;
 Usage : Cardinal;
 Levels: Integer;
 Length: Integer;
begin
 // (1) Determine texture POOL.
 Pool:= D3DPOOL_DEFAULT;
 if (FBehavior = tbManaged) then Pool:= D3DPOOL_MANAGED;

 // (2) Apply MipMapping request.
 if (FMipMapping) then
  begin
   Usage := D3DUSAGE_AUTOGENMIPMAP;
   Levels:= 0;
  end else
  begin
   Usage := 0;
   Levels:= 1;
  end;

 // (3) Determine texture USAGE.
 case FBehavior of
  tbDynamic: Usage:= Usage or D3DUSAGE_DYNAMIC;
  tbRTarget: Usage:= Usage or D3DUSAGE_RENDERTARGET;
 end;

 // (4) Determine texture size (need to be square).
 Length:= FSize.X;
 if (FSize.Y > Length) then Length:= FSize.Y;

 // (5) Attempt to create the texture.
 Res:= Direct3DDevice.CreateCubeTexture(Length, Levels, Usage, FFormat, Pool,
  FTexture9, nil);
 Result:= (Succeeded(Res));
end;

//---------------------------------------------------------------------------
procedure TDXCubeTexture.MakeNotReady();
begin
 if (FTexture9 <> nil) then FTexture9:= nil;
end;

//---------------------------------------------------------------------------
function TDXCubeTexture.Lock(Tag: Integer; Flags: TDXLockFlags;
 out Access: TDXAccessInfo): Boolean;
var
 LockedRect: TD3DLocked_Rect;
 Usage: Cardinal;
begin
 // (1) Verify conditions.
 if (FTexture9 = nil) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Determine USAGE.
 Usage:= 0;
 if (Flags = lfReadOnly) then Usage:= D3DLOCK_READONLY;
 if (Flags = lfWriteOnly)and(FBehavior = tbDynamic) then
  Usage:= D3DLOCK_DISCARD;

 // (3) Lock the entire texture.
 Result:= Succeeded(FTexture9.LockRect(DXCubeMapFace(Tag), 0, LockedRect, nil,
  Usage));

 // (4) Return access information.
 if (Result) then
  begin
   Access.Bits  := LockedRect.pBits;
   Access.Pitch := LockedRect.Pitch;
   Access.Format:= D3DToFormat(FFormat);
  end; 
end;

//---------------------------------------------------------------------------
function TDXCubeTexture.LockRect(Tag: Integer; const LockArea: TRect;
 Flags: TDXLockFlags; out Access: TDXAccessInfo): Boolean;
var
 LockedRect: TD3DLocked_Rect;
 Usage: Cardinal;
begin
 // (1) Verify conditions.
 if (FTexture9 = nil) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Determine USAGE.
 Usage:= 0;
 if (Flags = lfReadOnly) then Usage:= D3DLOCK_READONLY;
 if (Flags = lfWriteOnly)and(FBehavior = tbDynamic) then
  Usage:= D3DLOCK_DISCARD;

 // (3) Lock the entire texture.
 Result:= Succeeded(FTexture9.LockRect(DXCubeMapFace(Tag), 0, LockedRect,
  @LockArea, Usage));

 // (4) Return access information.
 if (Result) then
  begin
   Access.Bits  := LockedRect.pBits;
   Access.Pitch := LockedRect.Pitch;
   Access.Format:= D3DToFormat(FFormat);
  end; 
end;

//---------------------------------------------------------------------------
function TDXCubeTexture.Unlock(Tag: Integer): Boolean;
begin
 Result:= (FTexture9 <> nil)and(Succeeded(FTexture9.UnlockRect(DXCubeMapFace(Tag), 0)));
end;

//---------------------------------------------------------------------------
function TDXCubeTexture.Activate(Stage: Cardinal; Tag: Integer): Boolean;
begin
 Result:= (FTexture9 <> nil)and(Succeeded(Direct3DDevice.SetTexture(Stage,
  FTexture9)));
end;

//---------------------------------------------------------------------------
end.


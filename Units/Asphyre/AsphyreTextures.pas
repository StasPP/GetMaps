unit AsphyreTextures;
//---------------------------------------------------------------------------
// AsphyreTextures.pas                                  Modified: 02-Jan-2006
// Copyright (c) 2000 - 2006  Afterwarp Interactive              Version 1.22
//---------------------------------------------------------------------------
// Changes since v1.00:
//  * Modified image loading mechanism to avoid copying too much data by
//    removing Upload routine and passing pixel information directly.
//
// Changes since v1.02:
//  * Switched to new DXTextures.pas and using states instead of
//    regular initialization.
//  * The texture format is specified with Qualtiy and Alpha-Level settings.
//  + You can specify whether to use Depth-Buffer in render targets.
//  + Full control for render target creation. You can also specify the
//    number of render targets created (since usually a pair is used).
//  + New method: RenderOn greatly simplifies the process of drawing on the
//    specified render target.
//
// Changes since v1.2:
//  + Added dynamic-texture support
//  + Added TDynamicTexture class and TAsphyreTextures.AddDynamic method.
//  * Renamed TAsphyreRenderTarget to TRenderTarget.
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
 Windows, Types, Classes, SysUtils, Math, Graphics, AsphyreDef, AsphyreDb,
 AsphyreConv, AsphyreBmpLoad, Direct3D9, DXBase, DXTextures, AsphyreDevices;

//---------------------------------------------------------------------------
type
 TAsphyreTexture = class(TDXMonoTexture)
 private
  FQuality: TAsphyreQuality;
  FAlphaLevel: TAlphaLevel;

  function UploadFromImage(Image: TBitmap): Boolean;
 protected
  function Prepare(): Boolean; override;
 public
  property Quality: TAsphyreQuality read FQuality write FQuality;
  property AlphaLevel: TAlphaLevel read FAlphaLevel write FAlphaLevel;

  function LoadFromFile(const Filename: string): Boolean;
  function LoadFromStream(Stream: TStream; Format: TImageFormat): Boolean;
  function LoadFromASDb(const Key: string; ASDb: TASDb): Boolean;

  constructor Create(); override;
 end;

//---------------------------------------------------------------------------
 TDynamicTexture = class(TDXMonoTexture)
 private
  ForcedFormat: TD3DFormat;
 protected
  function Prepare(): Boolean; override;
 public
  function Initialize(Width, Height: Integer; Format: TD3DFormat): Boolean;

  function DynamicLock(out Info: TDXAccessInfo): Boolean;
  procedure DynamicUnlock();

  constructor Create(); override;
 end;

//---------------------------------------------------------------------------
 TRenderTarget = class(TDXMonoTexture)
 private
  DepthSurface: IDirect3DSurface9;
  PrevTarget  : IDirect3DSurface9;
  PrevDepthBuf: IDirect3DSurface9;
  FQuality    : TAsphyreQuality;
  FAlphaLevel : TAlphaLevel;
  FUseNative  : Boolean;
  FDepthBuffer: Boolean;

  procedure SetDepthBuffer(const Value: Boolean);
 protected
  function Prepare(): Boolean; override;
  function MakeReady(): Boolean; override;
  procedure MakeNotReady(); override;
 public
  property Quality: TAsphyreQuality read FQuality write FQuality;
  property AlphaLevel: TAlphaLevel read FAlphaLevel write FAlphaLevel;

  //-------------------------------------------------------------------------
  // Determines whether to use the native surface format, ignoring
  // the quality and alpha levels.
  //-------------------------------------------------------------------------
  property UseNative: Boolean read FUseNative write FUseNative;

  //-------------------------------------------------------------------------
  // Determines whether to associate a depth-buffer with this render target.
  //-------------------------------------------------------------------------
  property DepthBuffer: Boolean read FDepthBuffer write SetDepthBuffer;

  //-------------------------------------------------------------------------
  // Begin rendering on this render target. Saves previous rendering state.
  //-------------------------------------------------------------------------
  function BeginRender(): Boolean;

  //-------------------------------------------------------------------------
  // Finish rendering here. Restores previous rendering state.
  //-------------------------------------------------------------------------
  procedure EndRender();

  constructor Create(); override;
 end;

//---------------------------------------------------------------------------
 TAsphyreTextures = class(TAsphyreDeviceSubscriber)
 private
  Data: array of TDXBaseTexture;

  function GetCount(): Integer;
  function GetTexture(Num: Integer): TDXBaseTexture;
  procedure NotifyState(NewState: TDXTextureState);
 protected
  function HandleNotice(Msg: Cardinal): Boolean; override;
 public
  property Count: Integer read GetCount;
  property Texture[Num: Integer]: TDXBaseTexture read GetTexture; default;

  //-------------------------------------------------------------------------
  // Generic texture operations.
  //-------------------------------------------------------------------------
  function Add(Tex: TDXBaseTexture): Integer;
  function Find(Tex: TDXBaseTexture): Integer;
  procedure Remove(Index: Integer);
  procedure RemoveAll();

  //-------------------------------------------------------------------------
  // Image texture operations.
  //-------------------------------------------------------------------------
  function AddTexture(): TAsphyreTexture; overload;
  function AddTexture(const Filename: string;
   Quality: TAsphyreQuality; AlphaLevel: TAlphaLevel): Boolean; overload;
  function AddTexture(const Key: string; ASDb: TASDb;
   Quality: TAsphyreQuality; AlphaLevel: TAlphaLevel): Boolean; overload;

  //-------------------------------------------------------------------------
  // Render Target operations.
  //-------------------------------------------------------------------------
  function AddRenderTargets(Amount, Width, Height: Integer;
   UseNative: Boolean; Quality: TAsphyreQuality; AlphaLevel: TAlphaLevel;
   DepthBuffer: Boolean): Boolean; overload;

  function AddRenderTargets(Amount, Width, Height: Integer;
   Quality: TAsphyreQuality; AlphaLevel: TAlphaLevel): Boolean; overload;

  function AddRenderTargets(Amount, Width, Height: Integer): Boolean; overload;

  function RenderOn(Index: Integer; Event: TNotifyEvent; Bkgrnd: Cardinal;
   FillBk: Boolean): Boolean;

  //-------------------------------------------------------------------------
  // Dynamic Textures operations.
  //-------------------------------------------------------------------------
  function AddDynamic(Amount, Width, Height: Integer;
   Format: TD3DFormat): Boolean;

  constructor Create(AOwner: TComponent); override;
  destructor Destroy(); override;
 published
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TAsphyreTexture.Create();
begin
 inherited;

 FBehavior  := tbManaged;
 FQuality   := aqHigh;
 FAlphaLevel:= alFull;
end;

//---------------------------------------------------------------------------
function TAsphyreTexture.Prepare(): Boolean;
begin
 FFormat:= DXApproxFormat(FQuality, FAlphaLevel, RetreiveUsage());
 Result:= (FFormat <> D3DFMT_UNKNOWN);
end;

//---------------------------------------------------------------------------
function TAsphyreTexture.UploadFromImage(Image: TBitmap): Boolean;
var
 Index : Integer;
 Access: TDXAccessInfo;
 Source: Pointer;
 LineConv: TLineConvFunc;
begin
 if (Image.PixelFormat <> pf32bit) then Image.PixelFormat:= pf32bit;

 // (1) Lock the texture.
 Result:= Lock(-1, lfWriteOnly, Access);
 if (not Result) then Exit;

 // (2) Retreive scanline conversion function.
 LineConv:= GetLineConv32toX(Access.Format);

 // (3) Apply pixel conversion.
 for Index:= 0 to Size.Y - 1 do
  begin
   Source:= Image.Scanline[Index];
   LineConv(Source, Access.Bits, Size.X);
   Inc(Integer(Access.Bits), Access.Pitch);
  end;

 // (4) Unlock the texture.
 Result:= Unlock(-1);
end;

//---------------------------------------------------------------------------
function TAsphyreTexture.LoadFromFile(const Filename: string): Boolean;
var
 Image: TBitmap;
begin
 // (1) Load source image.
 Image:= TBitmap.Create();
 Result:= LoadBitmap(FileName, Image, ifAuto);
 if (not Result) then
  begin
   Image.Free();
   Exit;
  end;

 // (2) Define texture parameters.
 Size:= Point(Image.Width, Image.Height);

 // (3) Attempt to change the state.
 ChangeState(tsReady);
 if (FState <> tsReady) then
  begin
   Image.Free();
   Exit;
  end;

 // (4) Upload pixel data.
 Result:= UploadFromImage(Image);

 // (5) Release the bitmap memory.
 Image.Free();
end;

//---------------------------------------------------------------------------
function TAsphyreTexture.LoadFromStream(Stream: TStream;
 Format: TImageFormat): Boolean;
var
 Image: TBitmap;
begin
 // (1) Load source image.
 Image:= TBitmap.Create();
 Result:= LoadBitmap(Stream, Image, Format);
 if (not Result) then
  begin
   Image.Free();
   Exit;
  end;

 // (2) Define texture size.
 Size:= Point(Image.Width, Image.Height);

 // (3) Attempt to change the state.
 ChangeState(tsReady);
 if (FState <> tsReady) then
  begin
   Image.Free();
   Exit;
  end;

 // (4) Upload pixel data.
 Result:= UploadFromImage(Image);

 // (5) Release the bitmap memory.
 Image.Free();
end;

//---------------------------------------------------------------------------
function TAsphyreTexture.LoadFromASDb(const Key: string; ASDb: TASDb): Boolean;
var
 Image: TBitmap;
begin
 // (1) Make sure ASDb is up-to-date.
 Result:= ASDb.UpdateOnce();
 if (not Result) then Exit;

 // (2) Load source image.
 Image:= TBitmap.Create();
 Result:= LoadBitmap(Key, Image, ASDb);
 if (not Result) then
  begin
   Image.Free();
   Exit;
  end;

 // (3) Define texture size.
 Size:= Point(Image.Width, Image.Height);

 // (4) Attempt to change the state.
 ChangeState(tsReady);
 if (FState <> tsReady) then
  begin
   Image.Free();
   Exit;
  end;

 // (5) Upload pixel data.
 Result:= UploadFromImage(Image);

 // (6) Release the bitmap memory.
 Image.Free();
end;

//---------------------------------------------------------------------------
constructor TDynamicTexture.Create();
begin
 inherited;

 FBehavior:= tbDynamic;
end;

//---------------------------------------------------------------------------
function TDynamicTexture.Prepare(): Boolean;
begin
 FFormat:= ForcedFormat;
 Result:= True;
end;

//---------------------------------------------------------------------------
function TDynamicTexture.Initialize(Width, Height: Integer;
 Format: TD3DFormat): Boolean;
begin
 if (State = tsReady) then ChangeState(tsNotReady);
 
 Size:= Point(Width, Height);
 ForcedFormat:= Format;

 ChangeState(tsReady);
 Result:= (State = tsReady);
end;

//---------------------------------------------------------------------------
function TDynamicTexture.DynamicLock(out Info: TDXAccessInfo): Boolean;
begin
 Result:= Lock(-1, lfWriteOnly, Info);
end;

//---------------------------------------------------------------------------
procedure TDynamicTexture.DynamicUnlock();
begin
 Unlock(-1);
end;

//---------------------------------------------------------------------------
constructor TRenderTarget.Create();
begin
 inherited;

 FBehavior   := tbRTarget;
 MipMapping  := False;
 FQuality    := aqHigh;
 FAlphaLevel := alFull;
 FUseNative  := False;
 FDepthBuffer:= False;

 DepthSurface:= nil;
 PrevTarget  := nil;
 PrevDepthBuf:= nil;
end;

//---------------------------------------------------------------------------
procedure TRenderTarget.SetDepthBuffer(const Value: Boolean);
begin
 if (FState = tsNotReady) then FDepthBuffer:= Value;
end;

//---------------------------------------------------------------------------
function TRenderTarget.Prepare(): Boolean;
begin
 if (not FUseNative) then
  FFormat:= DXApproxFormat(FQuality, FAlphaLevel, RetreiveUsage())
   else FFormat:= PresentParams.BackBufferFormat;

 Result:= (FFormat <> D3DFMT_UNKNOWN);
end;
                              
//---------------------------------------------------------------------------
function TRenderTarget.MakeReady(): Boolean;
begin
 Result:= inherited MakeReady();
 if (not Result) then Exit;

 // create Depth-Buffer, if necessary
 if (FDepthBuffer) then
  with Direct3DDevice, PresentParams do
   begin
    Result:= Succeeded(CreateDepthStencilSurface(Size.X, Size.Y,
     AutoDepthStencilFormat, MultiSampleType, MultiSampleQuality, True,
     DepthSurface, nil));
   end;
end;

//---------------------------------------------------------------------------
procedure TRenderTarget.MakeNotReady();
begin
 if (DepthSurface <> nil) then DepthSurface:= nil;
 if (PrevTarget <> nil) then PrevTarget:= nil;
 if (PrevDepthBuf <> nil) then PrevDepthBuf:= nil;

 inherited MakeNotReady();
end;

//---------------------------------------------------------------------------
function TRenderTarget.BeginRender(): Boolean;
var
 Surface: IDirect3DSurface9;
begin
 // (1) Verify conditions.
 Result:= (State = tsReady);
 if (not Result) then Exit;

 // (2) Retreive the target surface.
 Result:= Succeeded(Texture9.GetSurfaceLevel(0, Surface));
 if (not Result) then Exit;

 // (3) Retreive previous render target.
 Result:= Succeeded(Direct3DDevice.GetRenderTarget(0, PrevTarget));
 if (not Result) then Exit;

 // (4) Retreive previous depth-stencil buffer.
 if (FDepthBuffer) then
  begin
   Result:= Succeeded(Direct3DDevice.GetDepthStencilSurface(PrevDepthBuf));
   if (not Result) then Exit;
  end;

 // (5) Set new render target.
 Result:= Succeeded(Direct3DDevice.SetRenderTarget(0, Surface));
 if (not Result) then Exit;

 // (6) Set new depth-buffer.
 if (FDepthBuffer) then
  begin
   Result:= Succeeded(Direct3DDevice.SetDepthStencilSurface(DepthSurface));
   if (not Result) then Exit;
  end; 

 // (7) Release previously obtained surface.
 Surface:= nil;
end;

//---------------------------------------------------------------------------
procedure TRenderTarget.EndRender();
begin
 if (PrevTarget <> nil) then
  begin
   Direct3DDevice.SetRenderTarget(0, PrevTarget);
   PrevTarget:= nil;
  end;

 if (PrevDepthBuf <> nil) then
  begin
   Direct3DDevice.SetDepthStencilSurface(PrevDepthBuf);
   PrevDepthBuf:= nil;
  end;
end;

//---------------------------------------------------------------------------
constructor TAsphyreTextures.Create(AOwner: TComponent);
begin
 inherited;

 SetLength(Data, 0);
end;

//---------------------------------------------------------------------------
destructor TAsphyreTextures.Destroy();
begin
 RemoveAll();

 inherited;
end;

//---------------------------------------------------------------------------
function TAsphyreTextures.GetCount(): Integer;
begin
 Result:= Length(Data);
end;

//---------------------------------------------------------------------------
function TAsphyreTextures.GetTexture(Num: Integer): TDXBaseTexture;
begin
 if (Num >= 0)and(Num < Length(Data)) then
  Result:= Data[Num] else Result:= nil;
end;

//---------------------------------------------------------------------------
function TAsphyreTextures.Find(Tex: TDXBaseTexture): Integer;
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  if (Data[i] = Tex) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= -1;
end;

//---------------------------------------------------------------------------
procedure TAsphyreTextures.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= Length(Data)) then Exit;

 Data[Index].Free();
 for i:= Index to Length(Data) - 2 do
  Data[i]:= Data[i + 1];

 SetLength(Data, Length(Data) - 1);
end;

//---------------------------------------------------------------------------
procedure TAsphyreTextures.RemoveAll;
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  if (Data[i] <> nil) then
   begin
    Data[i].Free();
    Data[i]:= nil;
   end;

 SetLength(Data, 0);
end;

//---------------------------------------------------------------------------
function TAsphyreTextures.Add(Tex: TDXBaseTexture): Integer;
var
 Index: Integer;
begin
 Index:= Length(Data);
 SetLength(Data, Index + 1);

 Data[Index]:= Tex;
 Result:= Index;
end;

//---------------------------------------------------------------------------
function TAsphyreTextures.AddTexture(): TAsphyreTexture;
var
 Index: Integer;
begin
 Index:= Add(TAsphyreTexture.Create());
 Result:= TAsphyreTexture(Data[Index]);
end;

//---------------------------------------------------------------------------
procedure TAsphyreTextures.NotifyState(NewState: TDXTextureState);
var
 Index: Integer;
begin
 for Index:= 0 to Length(Data) - 1 do
  if (Data[Index] <> nil) then
   Data[Index].ChangeState(NewState);
end;

//---------------------------------------------------------------------------
function TAsphyreTextures.HandleNotice(Msg: Cardinal): Boolean;
begin
 Result:= True;

 case Msg of
  msgDeviceFinalize:
   RemoveAll();

  msgDeviceLost:
   NotifyState(tsLost);

  msgDeviceRecovered:
   NotifyState(tsReady);
 end;
end;

//---------------------------------------------------------------------------
function TAsphyreTextures.AddTexture(const Filename: string;
 Quality: TAsphyreQuality; AlphaLevel: TAlphaLevel): Boolean;
var
 Image: TAsphyreTexture;
begin
 Image:= AddTexture();
 Image.Quality:= Quality;
 Image.AlphaLevel:= AlphaLevel;

 Result:= Image.LoadFromFile(Filename);
 if (not Result) then Remove(Find(Image));
end;

//---------------------------------------------------------------------------
function TAsphyreTextures.AddTexture(const Key: string; ASDb: TASDb;
 Quality: TAsphyreQuality; AlphaLevel: TAlphaLevel): Boolean;
var
 Image: TAsphyreTexture;
begin
 Image:= AddTexture();
 Image.Quality:= Quality;
 Image.AlphaLevel:= AlphaLevel;

 Result:= Image.LoadFromASDb(Key, ASDb);
 if (not Result) then Remove(Find(Image));
end;

//---------------------------------------------------------------------------
function TAsphyreTextures.AddRenderTargets(Amount, Width, Height: Integer;
 UseNative: Boolean; Quality: TAsphyreQuality; AlphaLevel: TAlphaLevel;
 DepthBuffer: Boolean): Boolean;
var
 Target: TRenderTarget;
 Index : Integer;
begin
 Result:= False;
 
 for Index:= 0 to Amount - 1 do
  begin
   Target:= TRenderTarget.Create();
   Target.Size       := Point(Width, Height);
   Target.UseNative  := UseNative;
   Target.Quality    := Quality;
   Target.AlphaLevel := AlphaLevel;
   Target.DepthBuffer:= DepthBuffer;

   Target.ChangeState(tsReady);
   Result:= (Target.State = tsReady);
   if (not Result) then
    begin
     Target.Free();
     Break;
    end;

   Add(Target);
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreTextures.AddRenderTargets(Amount, Width, Height: Integer;
 Quality: TAsphyreQuality; AlphaLevel: TAlphaLevel): Boolean;
begin
 Result:= AddRenderTargets(Amount, Width, Height, False, Quality,
  AlphaLevel, False);
end;

//---------------------------------------------------------------------------
function TAsphyreTextures.AddRenderTargets(Amount, Width,
 Height: Integer): Boolean;
begin
 Result:= AddRenderTargets(Amount, Width, Height, True, aqHigh, alFull, True);
end;

//---------------------------------------------------------------------------
function TAsphyreTextures.RenderOn(Index: Integer;
 Event: TNotifyEvent; Bkgrnd: Cardinal; FillBk: Boolean): Boolean;
var
 Target: TRenderTarget;
begin
 // (1) Verify conditions.
 Result:= (Index >= 0)and(Index < Length(Data))and
  (Data[Index] is TRenderTarget);
 if (not Result) then Exit;

 // (2) Retreive render target.
 Target:= TRenderTarget(Data[Index]);

 // (3) Begin rendering.
 Result:= Target.BeginRender();
 if (not Result) then Exit;

 // (4) Clear render target.
 if (FillBk) then
  begin
   Result:= Device.Clear(Bkgrnd, Target.DepthBuffer);
   if (not Result) then Exit;
  end;

 // (5) Begin the scene.
 Result:= Device.BeginScene();
 if (not Result) then Exit;

 // (6) Call rendering event.
 Event(Self);

 // (7) End the scene.
 Device.EndScene();

 // (8) Finish rendering.
 Target.EndRender();
end;

//---------------------------------------------------------------------------
function TAsphyreTextures.AddDynamic(Amount, Width, Height: Integer;
 Format: TD3DFormat): Boolean;
var
 Texture: TDynamicTexture;
 Index  : Integer;
begin
 Result:= False;

 for Index:= 0 to Amount - 1 do
  begin
   Texture:= TDynamicTexture.Create();
   Result:= Texture.Initialize(Width, Height, Format);
   if (not Result) then
    begin
     Texture.Free();
     Break;
    end;

   Add(Texture);
  end;
end;

//---------------------------------------------------------------------------
end.

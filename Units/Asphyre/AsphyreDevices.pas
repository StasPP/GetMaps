unit AsphyreDevices;
//---------------------------------------------------------------------------
// AsphyreDevices.pas                                   Modified: 24-Sep-2005
// Asphyre Device manipulation                                    Version 2.0
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
 Windows, Types, Classes, SysUtils, Forms, Direct3D9, DXBase, AsphyreConv,
 AsphyreSubsc;

//---------------------------------------------------------------------------
const
 msgDeviceInitialize = $100;
 msgDeviceFinalize   = $101;
 msgDeviceLost       = $102;
 msgDeviceRecovered  = $103;
 msgBeginScene       = $104;
 msgEndScene         = $105;
 msgMonoCanvasBegin  = $200;
 msgMultiCanvasBegin = $201;

//---------------------------------------------------------------------------
type
 TInitializeEvent = procedure(Sender: TObject; var Success: Boolean) of object;

//---------------------------------------------------------------------------
 TBitDepth = (bdLow, bdHigh);

//---------------------------------------------------------------------------
 TAsphyreDevice = class(TAsphyrePublisher)
 private
  FWidth   : Integer;
  FHeight  : Integer;
  FBitDepth: TBitDepth;
  FRefresh : Integer;
  FWindowed: Boolean;
  FVSync   : Boolean;

  NotifiedLost : Boolean;
  FHardwareTL  : Boolean;
  FDepthBuffer : Boolean;
  FWindowHandle: THandle;
  FInitialized : Boolean;

  FOnFinalize  : TNotifyEvent;
  FOnInitialize: TInitializeEvent;
  FOnRender    : TNotifyEvent;

  procedure SetBitDepth(const Value: TBitDepth);
  procedure SetRefresh(const Value: Integer);
  procedure SetSize(const Index, Value: Integer);
  procedure SetState(const Index: Integer; const Value: Boolean);
  procedure RefreshPresentParams();
  procedure SetWindowHandle(const Value: THandle);
  procedure SetDepthBuffer(const Value: Boolean);
 public
  property Initialized: Boolean read FInitialized;

  function Initialize(): Boolean;
  function Finalize(): Boolean;

  procedure BroadcastMsg(Msg: Cardinal);

  function Clear(Color: Cardinal): Boolean; overload;
  function Clear(Color: Cardinal; ClearZBuf: Boolean): Boolean; overload;
  function BeginScene(): Boolean;
  function EndScene(): Boolean;
  function Reset(): Boolean;

  function Render(Bkgrnd: Cardinal; FillBk: Boolean): Boolean;
  function RenderWith(Event: TNotifyEvent; Bkgrnd: Cardinal;
   FillBk: Boolean): Boolean;
  function Flip(): Boolean;

  constructor Create(AOwner: TComponent); override;
  destructor Destroy(); override;
 published
  property Width   : Integer index 0 read FWidth write SetSize;
  property Height  : Integer index 1 read FHeight write SetSize;
  property BitDepth: TBitDepth read FBitDepth write SetBitDepth;
  property Refresh : Integer read FRefresh write SetRefresh;
  property Windowed: Boolean index 0 read FWindowed write SetState;
  property VSync   : Boolean index 1 read FVSync write SetState;

  property HardwareTL  : Boolean index 2 read FHardwareTL write SetState;
  property DepthBuffer : Boolean read FDepthBuffer write SetDepthBuffer;
  property WindowHandle: THandle read FWindowHandle write SetWindowHandle;

  property OnInitialize: TInitializeEvent read FOnInitialize write FOnInitialize;
  property OnFinalize  : TNotifyEvent read FOnFinalize write FOnFinalize;
  property OnRender    : TNotifyEvent read FOnRender write FOnRender;
 end;

//---------------------------------------------------------------------------
 TAsphyreDeviceSubscriber = class(TAsphyreSubscriber)
 private
  function GetDevice(): TAsphyreDevice;
 protected
  function PublisherClass(): TAsphyrePublisherClass; override;
  function FindHelper(HelperClass: TComponentClass): TComponent;
 published
  property Device: TAsphyreDevice read GetDevice;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TAsphyreDevice.Create(AOwner: TComponent);
begin
 inherited;

 FWidth   := 640;
 FHeight  := 480;
 FBitDepth:= bdHigh;
 FRefresh := 0;
 FWindowed:= True;
 FVSync   := False;

 FHardwareTL  := True;
 FDepthBuffer := False;
 FWindowHandle:= 0;
 FInitialized := False;
end;

//---------------------------------------------------------------------------
destructor TAsphyreDevice.Destroy();
begin
 if (FInitialized) then Finalize();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreDevice.SetWindowHandle(const Value: THandle);
begin
 if (not FInitialized) then FWindowHandle:= Value;
end;

//---------------------------------------------------------------------------
procedure TAsphyreDevice.SetDepthBuffer(const Value: Boolean);
begin
 if (not FInitialized) then FDepthBuffer:= Value;
end;

//---------------------------------------------------------------------------
procedure TAsphyreDevice.SetRefresh(const Value: Integer);
begin
 if (not FInitialized) then FRefresh:= Value;
end;

//---------------------------------------------------------------------------
procedure TAsphyreDevice.SetBitDepth(const Value: TBitDepth);
begin
 if (not FInitialized) then FBitDepth:= Value;
end;

//---------------------------------------------------------------------------
procedure TAsphyreDevice.SetState(const Index: Integer; const Value: Boolean);
begin
 case Index of
  0: FWindowed:= Value;
  1: FVSync   := Value;
  2: FHardwareTL:= Value;
 end;

 if (FInitialized) then Reset();
end;

//---------------------------------------------------------------------------
procedure TAsphyreDevice.SetSize(const Index, Value: Integer);
begin
 case Index of
  0: FWidth := Value;
  1: FHeight:= Value;
 end;

 if (FInitialized) then Reset();
end;

//---------------------------------------------------------------------------
procedure TAsphyreDevice.RefreshPresentParams();
begin
 FillChar(PresentParams, SizeOf(TD3DPresentParameters), 0);

 with PresentParams do
  begin
   Windowed:= Self.FWindowed;

   if (FWindowHandle = 0) then
    begin
     if (Assigned(Owner))and(Owner is TCustomForm) then
      hDeviceWindow:= TCustomForm(Owner).Handle;
    end else hDeviceWindow:= FWindowHandle;

   BackBufferWidth := FWidth;
   BackBufferHeight:= FHeight;
   SwapEffect      := D3DSWAPEFFECT_DISCARD;
   MultiSampleType := D3DMULTISAMPLE_NONE;
//   BackBufferCount:= 2;

   if (not FWindowed) then
    BackBufferFormat:= DXBestBackFormat(FBitDepth = bdHigh, FWidth, FHeight,
     FRefresh)
     else BackBufferFormat:= DXGetDisplayFormat();

   FullScreen_RefreshRateInHz:= FRefresh;
   PresentationInterval:= D3DPRESENT_INTERVAL_IMMEDIATE;
   if (FVSync) then PresentationInterval:= D3DPRESENT_INTERVAL_ONE;

   if (FDepthBuffer) then
    begin
     EnableAutoDepthStencil:= True;
     Flags:= D3DPRESENTFLAG_DISCARD_DEPTHSTENCIL;

     AutoDepthStencilFormat:= DXBestDepthFormat(FBitDepth = bdHigh,
      BackBufferFormat);
    end;
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreDevice.Initialize(): Boolean;
var
 Res: Integer;
begin
 Result:= False;

 // (1) Verify conditions.
 if (FInitialized)or(Direct3D <> nil)or(Direct3DDevice <> nil) then Exit;

 // (2) Create Direct3D object.
 Direct3D:= Direct3DCreate9(D3D_SDK_VERSION);
 if (Direct3D = nil) then Exit;

 // (3) Setup present parameters.
 RefreshPresentParams();

 // (4) Attempt to use hardware vertex processing.
 if (FHardwareTL) then
  begin
   Res:= Direct3D.CreateDevice(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL,
    PresentParams.hDeviceWindow, D3DCREATE_HARDWARE_VERTEXPROCESSING,
    @PresentParams, Direct3DDevice);
  end else Res:= D3D_OK; // for the next call

 // -> if FAILED, try software vertex processing
 if (Failed(Res))or(not FHardwareTL) then
  Res:= Direct3D.CreateDevice(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL,
   PresentParams.hDeviceWindow, D3DCREATE_SOFTWARE_VERTEXPROCESSING,
   @PresentParams, Direct3DDevice);

 // -> if STILL FAILED, then we cannot proceed
 Result:= Succeeded(Res);

 // (5) Retreive device capabilities.
 if (Result) then
  Result:= Succeeded(Direct3DDevice.GetDeviceCaps(DeviceCaps));

 // (6) Mark that we have not lost the device.
 NotifiedLost:= False;

 // (7) Change status to [DeviceActive]
 FInitialized:= Result;
 if (Result) then
  begin
   // (8) Broadcast InitDevice notification to subscribed components.
   Result:= Notify(msgDeviceInitialize);
   if (not Result) then Finalize();

   // (9) Call notification events.
   if (Assigned(FOnInitialize)) then
    begin
     FOnInitialize(Self, Result);
     if (not Result) then Finalize();
    end;
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreDevice.Finalize(): Boolean;
begin
 Result:= True;

 // (1) Verify conditions.
 if (not FInitialized) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Call notification event.
 if (Assigned(FOnFinalize)) then FOnFinalize(Self);

 // (3) Broadcast finalize notification to subscribed components.
 Notify(msgDeviceFinalize);

 // (4) Release Direct3D objects.
 if (Direct3DDevice <> nil) then Direct3DDevice:= nil;
 if (Direct3D <> nil) then Direct3D:= nil;

 // (5) Change status to [not DeviceActive]
 FInitialized:= False;
end;

//---------------------------------------------------------------------------
function TAsphyreDevice.Reset(): Boolean;
begin
 if (not FInitialized) then
  begin
   Result:= False;
   Exit;
  end;

 Notify(msgDeviceLost);

 // configure the device
 RefreshPresentParams();

 // try resetting the device
 Result:= Succeeded(Direct3DDevice.Reset(PresentParams));
 if (Result) then
  Notify(msgDeviceRecovered);
end;

//---------------------------------------------------------------------------
function TAsphyreDevice.Flip(): Boolean;
var
 Res: Integer;
begin
 // (1) Verify conditions.
 if (not FInitialized) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Present the scene.
 Res:= Direct3DDevice.Present(nil, nil, 0, nil);

 // (3) Device has been lost?
 if (Res = D3DERR_DEVICELOST) then
  begin
   // notify everyone that we've lost our device
   if (not NotifiedLost) then
    begin
     Notify(msgDeviceLost);
     NotifiedLost:= True;
    end;

   // can the device be restored?
   Res:= Direct3DDevice.TestCooperativeLevel();

   // try to restore the device
   if (Res = D3DERR_DEVICENOTRESET) then
    begin
     Res:= Direct3DDevice.Reset(PresentParams);
     if (Succeeded(Res))and(NotifiedLost) then
      begin
       Notify(msgDeviceRecovered);
       NotifiedLost:= False;
      end;
    end;
  end;

 // (4) Driver error? try resetting...
 if (Res = D3DERR_DRIVERINTERNALERROR) then
  begin
   Res:= Direct3DDevice.Reset(PresentParams);
   // if cannot reset the device - we're done, finalize the device
   if (Failed(Res)) then Finalize();
  end;

 // (5) Verify the result.
 Result:= Succeeded(Res);
end;

//---------------------------------------------------------------------------
function TAsphyreDevice.Clear(Color: Cardinal; ClearZBuf: Boolean): Boolean;
var
 Flags: Cardinal;
begin
 Flags:= D3DCLEAR_TARGET;
 if (ClearZBuf) then Flags:= Flags or D3DCLEAR_ZBUFFER;

 Result:= Succeeded(Direct3DDevice.Clear(0, nil, Flags,
  DisplaceRB(Color), 1.0, 0));
end;

//---------------------------------------------------------------------------
function TAsphyreDevice.Clear(Color: Cardinal): Boolean;
begin
 Result:= Clear(Color, FDepthBuffer);
end;

//---------------------------------------------------------------------------
function TAsphyreDevice.BeginScene(): Boolean;
begin
 Result:= Succeeded(Direct3DDevice.BeginScene());
 if (Result) then Notify(msgBeginScene);
end;

//---------------------------------------------------------------------------
function TAsphyreDevice.EndScene(): Boolean;
begin
 Notify(msgEndScene);
 Result:= Succeeded(Direct3DDevice.EndScene());
end;

//---------------------------------------------------------------------------
function TAsphyreDevice.Render(Bkgrnd: Cardinal; FillBk: Boolean): Boolean;
begin
 Result:= False;

 // (1) Verify conditions.
 if (not FInitialized)or(not Assigned(FOnRender)) then Exit;

 // (2) Fill the back buffer.
 if ((FillBk)and(not Clear(Bkgrnd)))or(not BeginScene()) then Exit;

 // (3) Call Render event.
 FOnRender(Self);

 // (4) Finish the rendering.
 Result:= EndScene();
end;

//---------------------------------------------------------------------------
function TAsphyreDevice.RenderWith(Event: TNotifyEvent; Bkgrnd: Cardinal;
  FillBk: Boolean): Boolean;
begin
 Result:= False;

 // (1) Verify conditions.
 if (not FInitialized) then Exit;

 // (2) Fill the back buffer.
 if ((FillBk)and(not Clear(Bkgrnd)))or(not BeginScene()) then Exit;

 // (3) Call the event.
 Event(Self);

 // (4) Finish the rendering.
 Result:= EndScene();
end;

//---------------------------------------------------------------------------
procedure TAsphyreDevice.BroadcastMsg(Msg: Cardinal);
begin
 Notify(Msg);
end;

//---------------------------------------------------------------------------
function TAsphyreDeviceSubscriber.FindHelper(HelperClass: TComponentClass): TComponent;
var
 Index: Integer;
begin
 Result:= nil;

 if (Assigned(Owner))and(csDesigning in ComponentState) then
  for Index:= 0 to Owner.ComponentCount - 1 do
   if (Owner.Components[Index] is HelperClass) then
    begin
     Result:= Owner.Components[Index];
     Break;
    end;
end;

//---------------------------------------------------------------------------
function TAsphyreDeviceSubscriber.PublisherClass(): TAsphyrePublisherClass;
begin
 Result:= TAsphyreDevice;
end;

//---------------------------------------------------------------------------
function TAsphyreDeviceSubscriber.GetDevice(): TAsphyreDevice;
begin
 Result:= TAsphyreDevice(Publisher);
end;

//---------------------------------------------------------------------------
end.

unit AsphyreJoystick;
//---------------------------------------------------------------------------
// AsphyreJoystick.pas                                  Modified: 10-Oct-2005
// Copyright (c) 2000 - 2005  Afterwarp Interactive              Version 1.03
//---------------------------------------------------------------------------
//  Changes since version 1.00:
//    + Added automatic initialization on Update()
//
//  Changes since version 1.01:
//    + Added Foreground option which tells whether to use foreground or
//      background mode.
//
//  Changes since version 1.02:
//    * All functions that returned error code before now return Boolean.
//      This is because DirectX provides its own debugging and errors are
//      based on context anyway.
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
 Windows, Types, Classes, SysUtils, Forms, DirectInput, DXBase, AsphyreDef;

//---------------------------------------------------------------------------
type
 TAsphyreJoystick = class
 private
  FInitialized: Boolean;
  FInputDevice: IDirectInputDevice8;
  FJoyState   : TDIJoyState2;
  FButtonCount: Integer;
  FAxisCount  : Integer;
  FPOVCount   : Integer;
  FDeviceCaps : TDIDevCaps;
  FForeground : Boolean;

  procedure SetForeground(const Value: Boolean);
 public
  property Initialized: Boolean read FInitialized;
  property InputDevice: IDirectInputDevice8 read FInputDevice;
  property DeviceCaps : TDIDevCaps read FDeviceCaps;
  property JoyState   : TDIJoyState2 read FJoyState;
  property Foreground : Boolean read FForeground write SetForeground;

  property ButtonCount: Integer read FButtonCount;
  property AxisCount  : Integer read FAxisCount;
  property POVCount   : Integer read FPOVCount;

  function Initialize(ddi: PDIDeviceInstance; hWnd: Integer): Boolean;
  procedure Finalize();

  function Poll(): Boolean;

  constructor Create();
  destructor Destroy(); override;
 published
 end;

//---------------------------------------------------------------------------
 TAsphyreJoysticks = class(TComponent)
 private
  Data: array of TAsphyreJoystick;
  FForeground : Boolean;
  FInitialized: Boolean;

  function CheckDirectInput(): Boolean;
  function GetCount(): Integer;
  function GetItem(Num: Integer): TAsphyreJoystick;
  procedure ReleaseJoysticks();
 protected
  function AddJoy(): TAsphyreJoystick;
 public
  property Foreground : Boolean read FForeground write FForeground;
  property Initialized: Boolean read FInitialized;
  property Count: Integer read GetCount;
  property Items[Num: Integer]: TAsphyreJoystick read GetItem; default;

  function Update(): Boolean;
  function Initialize(): Boolean;
  procedure Finalize();

  constructor Create(AOwner: TComponent); override;
  destructor Destroy(); override;
 end;


//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
type
 PClassRef = ^TClassRef;
 TClassRef = record
  ClassRef: TObject;
  Success : Boolean;
 end;

//---------------------------------------------------------------------------
function AxisEnumCallback(var ddoi: TDIDeviceObjectInstance;
 Ref: Pointer): Boolean; stdcall;
var
 DIPropRange: TDIPropRange;
 ClassRef   : PClassRef;
 Res        : Integer;
begin
 // (1) Retreive caller's class reference.
 ClassRef:= Ref;

 // (2) Configure the axis.
 DIPropRange.diph.dwSize:= SizeOf(TDIPropRange);
 DIPropRange.diph.dwHeaderSize:= SizeOf(TDIPropHeader);
 DIPropRange.diph.dwHow:= DIPH_BYID;
 DIPropRange.diph.dwObj:= ddoi.dwType;

 // -> use range [-32768..32767]
 DIPropRange.lMin:= Low(SmallInt);
 DIPropRange.lMax:= High(SmallInt);

 // (3) Set axis properties.
 Res:= TAsphyreJoystick(ClassRef.ClassRef).InputDevice.SetProperty(DIPROP_RANGE,
  DIPropRange.diph);
 if (Res <> DI_OK) then
  begin
   Result:= DIENUM_STOP;
   ClassRef.Success:= False;
  end else Result:= DIENUM_CONTINUE;
end;

//---------------------------------------------------------------------------
function JoyEnumCallback(ddi: PDIDeviceInstance; Ref: Pointer): Boolean; stdcall;
var
 ClassRef: PClassRef;
 Joystick: TAsphyreJoystick;
begin
 // (1) Retreive caller's class reference.
 ClassRef:= Ref;

 // (2) Create new TJoystick class.
 Joystick:= TAsphyreJoysticks(ClassRef.ClassRef).AddJoy();

 // (3) Initialize the created joystick.
 ClassRef.Success:= Joystick.Initialize(ddi,
  TCustomForm(TAsphyreJoysticks(ClassRef.ClassRef).Owner).Handle);
 if (not ClassRef.Success) then
  Result:= DIENUM_STOP else Result:= DIENUM_CONTINUE;
end;

//---------------------------------------------------------------------------
constructor TAsphyreJoystick.Create();
begin
 inherited;

 FInitialized:= False;
 FForeground := True;
end;

//---------------------------------------------------------------------------
destructor TAsphyreJoystick.Destroy();
begin
 if (FInitialized) then Finalize();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreJoystick.SetForeground(const Value: Boolean);
begin
 if (not FInitialized) then FForeground:= Value;
end;

//---------------------------------------------------------------------------
function TAsphyreJoystick.Initialize(ddi: PDIDeviceInstance;
 hWnd: Integer): Boolean;
var
 ClassRef: TClassRef;
 Flags: Cardinal;
begin
 // (1) Verify conditions.
 if (DirectInput8 = nil) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Create input device.
 Result:= Succeeded(DirectInput8.CreateDevice(ddi.guidInstance,
  FInputDevice, nil));
 if (not Result) then Exit;

 // (3) Set data format.
 Result:= Succeeded(FInputDevice.SetDataFormat(c_dfDIJoystick2));
 if (not Result) then
  begin
   FInputDevice:= nil;
   Exit;
  end;

 // (4) Prepare cooperative flags.
 Flags:= DISCL_FOREGROUND or DISCL_EXCLUSIVE;
 if (not FForeground) then Flags:= DISCL_BACKGROUND or DISCL_NONEXCLUSIVE;

 // (5) Set joystick cooperative level.
 Result:= Succeeded(FInputDevice.SetCooperativeLevel(hWnd, Flags));
 if (not Result) then
  begin
   FInputDevice:= nil;
   Exit;
  end;

 // (6) Enumerate joystick axes.
 ClassRef.ClassRef:= Self;
 ClassRef.Success := True;
 Result:= Succeeded(FInputDevice.EnumObjects(@AxisEnumCallback, @ClassRef,
  DIDFT_AXIS))and(ClassRef.Success);
 if (not Result) then
  begin
   FInputDevice:= nil;
   Exit;
  end;

 // (7) Get device capabilities.
 FillChar(FDeviceCaps, SizeOf(TDIDevCaps), 0);
 FDeviceCaps.dwSize:= SizeOf(TDIDevCaps);
 Result:= Succeeded(FInputDevice.GetCapabilities(FDeviceCaps));
 if (not Result) then
  begin
   FInputDevice:= nil;
   Exit;
  end;

 // (8) Retreive useful info.
 FButtonCount:= FDeviceCaps.dwButtons;
 FAxisCount  := FDeviceCaps.dwAxes;
 FPOVCount   := FDeviceCaps.dwPOVs;

 // (9) Set status to [Initialized].
 FInitialized:= True;
end;

//---------------------------------------------------------------------------
procedure TAsphyreJoystick.Finalize();
begin
 if (FInputDevice <> nil) then
  begin
   FInputDevice.Unacquire();
   FInputDevice:= nil;
  end;

 FInitialized:= False;
end;

//---------------------------------------------------------------------------
function TAsphyreJoystick.Poll(): Boolean;
var
 Res: Integer;
begin
 Result:= True;
 
 // (1) Attempt polling Joystick.
 Res:= FInputDevice.Poll();

 // failures?
 if (Res <> DI_OK)and(Res <> DI_NOEFFECT) then
  begin
   // we can handle Lost Input & Non-Acquired problems
   if (Res <> DIERR_INPUTLOST)and(Res <> DIERR_NOTACQUIRED) then
    begin
     Result:= False;
     Exit;
    end;

   // Acquire the device!
   Result:= Succeeded(FInputDevice.Acquire());
   if (Result) then
    begin
     Res:= FInputDevice.Poll();
     if (Res <> DI_OK)and(Res <> DI_NOEFFECT) then
      begin
       Result:= False;
       Exit;
      end;
    end else Exit;
  end;

 // (2) Retreive joystick state.
 Res:= FInputDevice.GetDeviceState(SizeOf(TDIJoyState2), @FJoyState);
 if (Res <> DI_OK) then
  begin
   // we can handle Lost Input & Non-Acquired problems
   if (Res <> DIERR_INPUTLOST)and(Res <> DIERR_NOTACQUIRED) then
    begin
     Result:= False;
     Exit;
    end;

   // Again, try to acquire the device.
   Result:= Succeeded(FInputDevice.Acquire());
   if (Result) then
    begin
     Result:= Succeeded(FInputDevice.GetDeviceState(SizeOf(TDIJoyState2),
      @FJoyState));
     if (not Result) then Exit;
    end;
  end;
end;

//---------------------------------------------------------------------------
constructor TAsphyreJoysticks.Create(AOwner: TComponent);
begin
 inherited;

 FForeground := True;
 FInitialized:= False;

 if (not (Owner is TCustomForm)) then
  raise Exception.Create(ClassName + ': This component''s must be dropped on the form!');
end;

//---------------------------------------------------------------------------
destructor TAsphyreJoysticks.Destroy();
begin
 if (FInitialized) then Finalize();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreJoysticks.ReleaseJoysticks();
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
function TAsphyreJoysticks.CheckDirectInput(): Boolean;
begin
 Result:= (DirectInput8 <> nil)or(Succeeded(DirectInput8Create(hInstance,
  DIRECTINPUT_VERSION, IID_IDirectInput8, DirectInput8, nil)));
end;

//---------------------------------------------------------------------------
function TAsphyreJoysticks.GetCount(): Integer;
begin
 Result:= Length(Data);
end;

//---------------------------------------------------------------------------
function TAsphyreJoysticks.GetItem(Num: Integer): TAsphyreJoystick;
begin
 if (Num >= 0)and(Num < Length(Data)) then Result:= Data[Num] else Result:= nil;
end;

//---------------------------------------------------------------------------
function TAsphyreJoysticks.AddJoy(): TAsphyreJoystick;
var
 Index: Integer;
begin
 Index:= Length(Data);
 SetLength(Data, Length(Data) + 1);

 Data[Index]:= TAsphyreJoystick.Create();
 Data[Index].Foreground:= FForeground;
 Result:= Data[Index];
end;

//---------------------------------------------------------------------------
function TAsphyreJoysticks.Initialize(): Boolean;
var
 ClassRef: TClassRef;
begin
 // (1) Verify that DirectInput interface exists.
 Result:= CheckDirectInput();
 if (not Result) then Exit;

 // (2) Release any previously created joysticks.
 ReleaseJoysticks();

 // (3) Enumerate joysticks.
 ClassRef.ClassRef:= Self;
 ClassRef.Success := False;
 Result:= Succeeded(DirectInput8.EnumDevices(DI8DEVCLASS_GAMECTRL,
  @JoyEnumCallback, @ClassRef, DIEDFL_ATTACHEDONLY))and(ClassRef.Success);
 if (not Result) then ReleaseJoysticks();

 // (4) Set status to [Initialized]
 FInitialized:= Result;
end;

//---------------------------------------------------------------------------
procedure TAsphyreJoysticks.Finalize();
begin
 ReleaseJoysticks();
 FInitialized:= False;
end;

//---------------------------------------------------------------------------
function TAsphyreJoysticks.Update(): Boolean;
var
 i: Integer;
begin
 Result:= True;

 if (not FInitialized) then
  begin
   Result:= Initialize();
   if (not Result) then Exit;
  end;

 for i:= 0 to Length(Data) - 1 do
  if (Data[i] <> nil)and(Data[i].Initialized) then
   begin
    Result:= Data[i].Poll();
    if (not Result) then Break;
   end;
end;

//---------------------------------------------------------------------------
end.

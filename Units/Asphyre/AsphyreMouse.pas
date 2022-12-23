unit AsphyreMouse;
//---------------------------------------------------------------------------
// AsphyreMouse.pas                                     Modified: 10-Oct-2005
// Copyright (c) 2000 - 2005  Afterwarp Interactive              Version 1.01
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
 TAsphyreMouse = class(TComponent)
 private
  FInitialized: Boolean;
  FExclusive  : Boolean;
  FInputDevice: IDirectInputDevice8;
  FForeground : Boolean;
  FBufferSize : Integer;
  FDisplace   : TPoint;
  MEvent      : THandle;
  MBClick     : array[0..7] of Integer;
  MBRelease   : array[0..7] of Integer;
  FClearOnUpdate: Boolean;

  function CheckDirectInput(): Boolean;
  procedure SetForeground(const Value: Boolean);
  procedure SetExclusive(const Value: Boolean);
  procedure SetBufferSize(const Value: Integer);
  function GetPressed(Button: Integer): Boolean;
  function GetReleased(Button: Integer): Boolean;
  procedure ClearButtons();
 public
  property Initialized: Boolean read FInitialized;
  property InputDevice: IDirectInputDevice8 read FInputDevice;
  property Displace: TPoint read FDisplace;

  property Pressed[Button: Integer]: Boolean read GetPressed;
  property Released[Button: Integer]: Boolean read GetReleased;

  function Initialize(): Boolean;
  procedure Finalize();
  function Update(): Boolean;

  constructor Create(AOwner: TComponent); override;
  destructor Destroy(); override;
 published
  property Foreground: Boolean read FForeground write SetForeground;
  property BufferSize: Integer read FBufferSize write SetBufferSize;
  property Exclusive : Boolean read FExclusive write SetExclusive;
  property ClearOnUpdate: Boolean read FClearOnUpdate write FClearOnUpdate;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TAsphyreMouse.Create(AOwner: TComponent);
begin
 inherited;

 if (not (AOwner is TCustomForm)) then
  raise Exception.Create('This component must be dropped onto the form!');

 FForeground:= True;
 FBufferSize:= 256;
 FClearOnUpdate:= False;
 FInitialized:= False;
 FExclusive  := True;

 FDisplace:= Point(0, 0);
end;

//---------------------------------------------------------------------------
destructor TAsphyreMouse.Destroy();
begin
 if (FInitialized) then Finalize();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMouse.SetForeground(const Value: Boolean);
begin
 if (not FInitialized) then FForeground:= Value;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMouse.SetExclusive(const Value: Boolean);
begin
 if (not FInitialized) then FExclusive:= Value;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMouse.SetBufferSize(const Value: Integer);
begin
 if (not FInitialized) then FBufferSize:= Value;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMouse.ClearButtons();
var
 i: Integer;
begin
 for i:= 0 to 7 do
  begin
   MBClick[i]:= 0;
   MBRelease[i]:= 0;
  end; 
end;

//---------------------------------------------------------------------------
function TAsphyreMouse.CheckDirectInput(): Boolean;
begin
 Result:= (DirectInput8 <> nil)or(Succeeded(DirectInput8Create(hInstance,
  DIRECTINPUT_VERSION, IID_IDirectInput8, DirectInput8, nil)));
end;

//---------------------------------------------------------------------------
function TAsphyreMouse.Initialize(): Boolean;
var
 DIProp: TDIPropDWord;
 Flags : Cardinal;
begin
 // (1) Verify conditions.
 if (FInitialized) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Verify that DirectInput interface exists.
 Result:= CheckDirectInput();
 if (not Result) then Exit;

 // (3) Create Mouse device.
 Result:= Succeeded(DirectInput8.CreateDevice(GUID_SysMouse, FInputDevice, nil));
 if (not Result) then Exit;

 // (4) Set Keyboard data format.
 Result:= Succeeded(FInputDevice.SetDataFormat(c_dfDIMouse));
 if (not Result) then
  begin
   FInputDevice:= nil;
   Exit;
  end;

 // (5) Define device flags.
 Flags:= DISCL_FOREGROUND;
 if (not FForeground) then Flags:= DISCL_BACKGROUND;
 if (FExclusive) then Flags:= Flags or DISCL_EXCLUSIVE
  else Flags:= Flags or DISCL_NONEXCLUSIVE;

 // (6) Set cooperative level.
 Result:= Succeeded(FInputDevice.SetCooperativeLevel(TCustomForm(Owner).Handle,
  Flags));
 if (not Result) then
  begin
   FInputDevice:= nil;
   Exit;
  end;

 // (7) Create a new event.
 MEvent:= CreateEvent(nil, False, False, nil);
 if (MEvent = 0) then
  begin
   FInputDevice:= nil;
   Result:= False;
   Exit;
  end;

 // (8) Set the recently created event for mouse notifications.
 Result:= Succeeded(FInputDevice.SetEventNotification(MEvent));
 if (not Result) then
  begin
   FInputDevice:= nil;
   Exit;
  end;

 // (9) Setup property info for mouse buffer size.
 FillChar(DIProp, SizeOf(DIProp), 0);
 with DIProp do
  begin
   diph.dwSize:= SizeOf(TDIPropDWord);
   diph.dwHeaderSize:= SizeOf(TDIPropHeader);
   diph.dwObj:= 0;
   diph.dwHow:= DIPH_DEVICE;
   dwData:= FBufferSize;
  end;

 // (10) Update mouse buffer size.
 Result:= Succeeded(FInputDevice.SetProperty(DIPROP_BUFFERSIZE, DIProp.diph));
 if (not Result) then
  begin
   FInputDevice:= nil;
   Exit;
  end;

 ClearButtons();
 FInitialized:= True;
end;

//---------------------------------------------------------------------------
procedure TAsphyreMouse.Finalize();
begin
 if (FInputDevice <> nil) then
  begin
   FInputDevice.Unacquire();
   FInputDevice:= nil;
  end;

 FInitialized:= False;
end;

//---------------------------------------------------------------------------
function TAsphyreMouse.Update(): Boolean;
var
 Res: Integer;
 EvCount: Cardinal;
 ObjData: TDIDeviceObjectData;
 EvClick: Integer;
 BtnIndx: Integer;
 EvRelease: Integer;
begin
 Result:= True;

 // (1) Verify initial conditions.
 if (not FInitialized) then
  begin
   Result:= Initialize();
   if (not Result) then Exit;
  end;

 FDisplace:= Point(0, 0);
 if (FClearOnUpdate) then ClearButtons();

 repeat
  EvCount:= 1;

  // (2) Retreive Mouse Data.
  Res:= FInputDevice.GetDeviceData(SizeOf(TDIDeviceObjectData), @ObjData,
   EvCount, 0);
  if (Res <> DI_OK)and(Res <> DI_BUFFEROVERFLOW) then
   begin
    if (Res <> DIERR_INPUTLOST)and(Res <> DIERR_NOTACQUIRED) then
     begin
      Result:= False;
      Exit;
     end;

    // -> attempt acquiring mouse
    Res:= FInputDevice.Acquire();
    if (Res = DI_OK) then
     begin
      // acquired successfully, attempt retreiving data again
      Res:= FInputDevice.GetDeviceData(SizeOf(TDIDeviceObjectData), @ObjData,
       EvCount, 0);
      if (Res <> DI_OK)and(Res <> DI_BUFFEROVERFLOW) then
       begin
        Result:= False;
        Exit;
       end;
     end else
     begin
      Result:= False;
      Exit;
     end;
   end; // if (Res <> DI_OK)

  // (3) Verify if there's anything in mouse buffer.
  if (EvCount < 1) then Break;

  // (4) Determine event type.
  case ObjData.dwOfs of
   DIMOFS_X: Inc(FDisplace.X, Integer(ObjData.dwData));
   DIMOFS_Y: Inc(FDisplace.Y, Integer(ObjData.dwData));

   DIMOFS_BUTTON0..DIMOFS_BUTTON7:
    begin
     // -> determine click - release type
     EvClick  := 0;
     EvRelease:= 1;
     if ((ObjData.dwData and $80) = $80) then
      begin
       EvClick  := 1;
       EvRelease:= 0;
      end;

     BtnIndx:= ObjData.dwOfs - DIMOFS_BUTTON0;
     MBClick[BtnIndx]  := EvClick;
     MBRelease[BtnIndx]:= EvRelease;
    end;
  end;
 until (EvCount < 1);
end;

//---------------------------------------------------------------------------
function TAsphyreMouse.GetPressed(Button: Integer): Boolean;
begin
 if (Button >= 0)and(Button < 8) then
  Result:= (MBClick[Button] > 0) else Result:= False;
end;

//---------------------------------------------------------------------------
function TAsphyreMouse.GetReleased(Button: Integer): Boolean;
begin
 if (Button >= 0)and(Button < 8) then
  Result:= (MBRelease[Button] > 0) else Result:= False;
end;

//---------------------------------------------------------------------------
end.

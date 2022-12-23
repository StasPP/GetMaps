unit GuiBasic;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, Controls, Forms, AsphyreDef, AsphyreCanvas,
 AsphyreImages, AsphyreFonts, AsphyreDevices, AsphyreDb, GuiTypes, GuiControls,
 GuiTaskbar;

//---------------------------------------------------------------------------
type
 TGuiBase = class(TAsphyreDeviceSubscriber)
 private
  FCanvas: TAsphyreCanvas;
  FFonts : TAsphyreFonts;
  FImages: TAsphyreImages;

  PrevMouseDown: TMouseEvent;
  PrevMouseUp  : TMouseEvent;
  PrevMouseMove: TMouseMoveEvent;
  PrevKeyDown  : TKeyEvent;
  PrevKeyUp    : TKeyEvent;
  PrevKeyPress : TKeyPressEvent;
  PrevClick    : TNotifyEvent;
  PrevDblClick : TNotifyEvent;

  FTaskBar: TGuiTaskBar;
  FActive : Boolean;

  procedure SaveEvents();
  function CheckUnique(): Boolean;

  procedure OwnerMouseDown(Sender: TObject; Button: TMouseButton;
   Shift: TShiftState; X, Y: Integer);
  procedure OwnerMouseUp(Sender: TObject; Button: TMouseButton;
   Shift: TShiftState; X, Y: Integer);
  procedure OwnerMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  procedure OwnerKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  procedure OwnerKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  procedure OwnerKeyPress(Sender: TObject; var Key: Char);
  procedure OwnerClick(Sender: TObject);
  procedure OwnerDblClick(Sender: TObject);

  procedure SetCanvas(const Value: TAsphyreCanvas);
  procedure SetFonts(const Value: TAsphyreFonts);
  procedure SetImages(const Value: TAsphyreImages);
  function GetCtrl(const Name: string): TGuiControl;
 protected
  procedure Notification(AComponent: TComponent; Operation: TOperation); override;
 public
  property Taskbar: TGuiTaskBar read FTaskBar;
  property Active : Boolean read FActive write FActive;
  property Ctrl[const Name: string]: TGuiControl read GetCtrl;

  procedure Update();
  procedure Draw();

  constructor Create(AOwner: TComponent); override;
  destructor Destroy(); override;
 published
  property Canvas: TAsphyreCanvas read FCanvas write SetCanvas;
  property Images: TAsphyreImages read FImages write SetImages;
  property Fonts : TAsphyreFonts read FFonts write SetFonts;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 StreamEx, GuiRegistry;

//---------------------------------------------------------------------------
constructor TGuiBase.Create(AOwner: TComponent);
begin
 inherited;

 // (1) Verify if the owner is valid.
 if (not (AOwner is TCustomForm)) then
  raise Exception.Create(ClassName + ': Owner must be TCustomForm.');

 // (2) Verify if the component is unique.
 if (not CheckUnique()) then
  raise Exception.Create(ClassName + ': Only one instance of this component is allowed.');

 // (3) Save the events.
 if (not (csDesigning in ComponentState)) then SaveEvents();

 // (4) Search for relevant components.
 Canvas:= TAsphyreCanvas(FindHelper(TAsphyreCanvas));
 Images:= TAsphyreImages(FindHelper(TAsphyreImages));
 Fonts := TAsphyreFonts(FindHelper(TAsphyreFonts));

 FActive  := True;
 FTaskBar:= TGuiTaskBar.Create(nil);
end;

//---------------------------------------------------------------------------
destructor TGuiBase.Destroy();
begin
 FTaskBar.Free();

 inherited;
end;

//---------------------------------------------------------------------------
function TGuiBase.GetCtrl(const Name: string): TGuiControl;
begin
 Result:= FTaskbar.Ctrl[Name];
end;

//---------------------------------------------------------------------------
procedure TGuiBase.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
 inherited;

 case Operation of
  opInsert:
   begin
    if (AComponent is TAsphyreCanvas)and(not Assigned(FCanvas)) then
     Canvas:= TAsphyreCanvas(AComponent);

    if (AComponent is TAsphyreImages)and(not Assigned(FImages)) then
     Images:= TAsphyreImages(AComponent);

    if (AComponent is TAsphyreFonts)and(not Assigned(FFonts)) then
     Fonts:= TAsphyreFonts(AComponent);
   end;

  opRemove:
   begin
    if (AComponent = FCanvas) then Canvas:= nil;
    if (AComponent = FImages) then Images:= nil;
    if (AComponent = FFonts) then Fonts:= nil;
   end;
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiBase.SetCanvas(const Value: TAsphyreCanvas);
begin
 FCanvas:= Value;
 GuiCanvas:= FCanvas;
end;

//---------------------------------------------------------------------------
procedure TGuiBase.SetFonts(const Value: TAsphyreFonts);
begin
 FFonts:= Value;
 GuiFonts:= FFonts;
end;

//---------------------------------------------------------------------------
procedure TGuiBase.SetImages(const Value: TAsphyreImages);
begin
 FImages:= Value;
 GuiImages:= FImages;
end;

//---------------------------------------------------------------------------
procedure TGuiBase.OwnerMouseDown(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Integer);
begin
 if (Assigned(PrevMouseDown)) then PrevMouseDown(Sender, Button, Shift, X, Y);
 if (FActive) then FTaskbar.MouseDown(Button, Shift, X, Y);
end;

//---------------------------------------------------------------------------
procedure TGuiBase.OwnerMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
 if (Assigned(PrevMouseMove)) then PrevMouseMove(Sender, Shift, X, Y);
 if (FActive) then FTaskbar.MouseMove(Shift, X, Y);
end;

//---------------------------------------------------------------------------
procedure TGuiBase.OwnerMouseUp(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Integer);
begin
 if (Assigned(PrevMouseUp)) then PrevMouseUp(Sender, Button, Shift, X, Y);
 if (FActive) then FTaskbar.MouseUp(Button, Shift, X, Y);
end;

//---------------------------------------------------------------------------
procedure TGuiBase.OwnerKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
 if (Assigned(PrevKeyDown)) then PrevKeyDown(Sender, Key, Shift);
 if (FActive) then FTaskbar.KeyDown(Key, Shift);
end;

//---------------------------------------------------------------------------
procedure TGuiBase.OwnerKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
 if (Assigned(PrevKeyUp)) then PrevKeyUp(Sender, Key, Shift);
 if (FActive) then FTaskbar.KeyUp(Key, Shift);
end;

//---------------------------------------------------------------------------
procedure TGuiBase.OwnerKeyPress(Sender: TObject; var Key: Char);
begin
 if (Assigned(PrevKeyPress)) then PrevKeyPress(Sender, Key);
 if (FActive) then FTaskbar.KeyPress(Key);
end;

//---------------------------------------------------------------------------
procedure TGuiBase.OwnerClick(Sender: TObject);
begin
 if (Assigned(PrevClick)) then PrevClick(Sender);
 FTaskbar.Click();
end;

//---------------------------------------------------------------------------
procedure TGuiBase.OwnerDblClick(Sender: TObject);
begin
 if (Assigned(PrevDblClick)) then PrevDblClick(Sender);
 FTaskbar.DblClick();
end;

//---------------------------------------------------------------------------
procedure TGuiBase.SaveEvents();
begin
 with Owner as TForm do
  begin
   PrevMouseDown:= OnMouseDown;
   PrevMouseUp  := OnMouseUp;
   PrevMouseMove:= OnMouseMove;
   PrevKeyDown  := OnKeyDown;
   PrevKeyUp    := OnKeyUp;
   PrevKeyPress := OnKeyPress;
   PrevClick    := OnClick;
   PrevDblClick := OnDblClick;

   OnMouseDown  := OwnerMouseDown;
   OnMouseUp    := OwnerMouseUp;
   OnMouseMove  := OwnerMouseMove;
   OnKeyDown    := OwnerKeyDown;
   OnKeyUp      := OwnerKeyUp;
   OnKeyPress   := OwnerKeyPress;
   OnClick      := OwnerClick;
   OnDblClick   := OwnerDblClick;
  end;
end;

//---------------------------------------------------------------------------
function TGuiBase.CheckUnique(): Boolean;
var
 i: Integer;
begin
 Result:= True;

 for i:= 0 to Owner.ComponentCount - 1 do
  if (Owner.Components[i] is TGuiBase)and(Owner.Components[i] <> Self) then
   begin
    Result:= False;
    Break;
   end;
end;

//---------------------------------------------------------------------------
procedure TGuiBase.Draw();
var
 PrevRect: TRect;
begin
 if (not FActive) then Exit;

 // (1) Since TAsphyreDevice is handled by owner, update GuiDevice.
 if (guiDevice <> Device) then guiDevice:= Device;

 // (2) Set default clipping rectangle.
 PrevRect:= guiCanvas.ClipRect;
 guiCanvas.ClipRect:= Bounds(0, 0, guiDevice.Width, guiDevice.Height);

 // (3) Set the size of taskbar.
 FTaskbar.Left:= 0;
 FTaskbar.Top := 0;
 FTaskbar.Width := guiDevice.Width;
 FTaskbar.Height:= guiDevice.Height;

 // (3) Draw GUI controls.
 FTaskbar.Draw();

 // (4) Reset clipping rectangle.
 guiCanvas.ClipRect:= PrevRect;
end;

//---------------------------------------------------------------------------
procedure TGuiBase.Update();
begin
 if (not FActive) then Exit;
 FTaskBar.Update();
end;

//---------------------------------------------------------------------------
end.

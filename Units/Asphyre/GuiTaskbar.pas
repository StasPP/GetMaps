unit GuiTaskbar;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, Controls, AsphyreDef, GuiTypes, GuiComponents,
 GuiControls, AsphyreDb;

//---------------------------------------------------------------------------
type
 TGuiTaskbar = class(TGuiControl)
 private
  FMousePos : TPoint;
  LastButton: TMouseButtonType;
  LastShift : TShiftState;
  LastOver  : TGuiControl;
  LastClick : TGuiControl;
  ClickLevel: Integer;

  procedure ListObjectNames(Control: TGuiControl; Strings: TStrings);
 protected
  procedure DoMouseEvent(const MousePos: TPoint; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TShiftState); override;
  procedure DoKeyEvent(Key: Integer; Event: TKeyEventType;
   Shift: TShiftState); override;
 public
  property MousePos: TPoint read FMousePos;

  function FindCtrlAt(const Point: TPoint): TGuiControl; override;

  procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure MouseMove(Shift: TShiftState; X, Y: Integer);
  procedure KeyDown(Key: Word; Shift: TShiftState);
  procedure KeyUp(Key: Word; Shift: TShiftState);
  procedure KeyPress(Key: Char);
  procedure Click();
  procedure DblClick();

  procedure MakeObjectList(Strings: TStrings);

  // Clears LastOver and LastClick references since the control is
  // being deleted.
  procedure RemoveRef();

  function SaveToFile(const Filename: string): Boolean;
  function LoadFromFile(const Filename: string): Boolean;
  function LoadFromASDb(const Key: string; ASDb: TASDb): Boolean;

  constructor Create(AOwner: TGuiControl); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 GuiForms;

//---------------------------------------------------------------------------
constructor TGuiTaskbar.Create(AOwner: TGuiControl);
begin
 inherited;

 Visible   := True;
 Enabled   := True;
 FMousePos := Point(0, 0);
 LastOver  := nil;
 ClickLevel:= 0;

 FCtrlHolder:= True;
end;

//---------------------------------------------------------------------------
function TGuiTaskbar.FindCtrlAt(const Point: TPoint): TGuiControl;
begin
 Result:= inherited FindCtrlAt(Point);
 if (Result = Self) then Result:= nil;
 if (guiDesign) then
  begin
   while (Result <> nil)and(Result.Owner <> nil)and(not Result.Owner.CtrlHolder) do
    Result:= Result.Owner;
  end;  
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.MouseDown(Button: TMouseButton; Shift: TShiftState;
 X, Y: Integer);
begin
 FMousePos := Point(X, Y);
 LastButton:= Button2Gui(Button);
 LastShift := Shift;
 AcceptMouse(FMousePos, mseDown, LastButton, LastShift);
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
 FMousePos := Point(X, Y);
 LastButton:= btnNone;
 LastShift := Shift;
 AcceptMouse(FMousePos, mseMove, LastButton, LastShift);
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.MouseUp(Button: TMouseButton; Shift: TShiftState;
 X, Y: Integer);
begin
 FMousePos := Point(X, Y);
 LastButton:= Button2Gui(Button);
 LastShift := Shift;
 AcceptMouse(FMousePos, mseUp, LastButton, LastShift);
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.Click();
begin
 AcceptMouse(FMousePos, mseClick, LastButton, LastShift);
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.DblClick();
begin
 AcceptMouse(FMousePos, mseDblClick, LastButton, LastShift);
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.KeyPress(Key: Char);
begin
 AcceptKey(Byte(Key), kbdPress, []);
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.KeyDown(Key: Word; Shift: TShiftState);
begin
 AcceptKey(Byte(Key), kbdDown, Shift);
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.KeyUp(Key: Word; Shift: TShiftState);
begin
 AcceptKey(Byte(Key), kbdUp, Shift);
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.DoMouseEvent(const MousePos: TPoint;
 Event: TMouseEventType; Button: TMouseButtonType; Shift: TShiftState);
var
 CtrlOver : TGuiControl;
 EventCtrl: TGuiControl;
begin
 if (Button = btnRight)and(guiDesign) then Exit;

 // (1) Find the control pointed by the mouse.
 CtrlOver:= FindCtrlAt(MousePos);

 // (2) Whom to send mouse event?
 EventCtrl:= CtrlOver;
 if (LastClick <> nil) then EventCtrl:= LastClick;

 // (3) Check whether a user pressed mouse button.
 if (Event = mseDown)and(CtrlOver <> nil) then
  begin
   if (ClickLevel <= 0) then
    begin
     CtrlOver.SetFocus();
     LastClick:= CtrlOver;
    end;

   if (LastClick is TGuiForm) then LastClick.SetFocus();
   Inc(ClickLevel);
  end;

 // (4) Verify if the user released mouse button.
 if (Event = mseUp) then
  begin
   Dec(ClickLevel);
   if (ClickLevel <= 0) then LastClick:= nil;
  end;

 // (5) Notify control pointed by the mouse that it is being ENTERED
 if (ClickLevel <= 0)and(LastOver <> CtrlOver) then
  begin
   if (CtrlOver <> nil) then CtrlOver.AcceptMouse(MousePos, mseEnter, Button,
    Shift);
  end;

 // (6) Send the mouse event
 if (EventCtrl <> nil)and(EventCtrl.Enabled) then
  EventCtrl.AcceptMouse(MousePos, Event, Button, Shift);

 // (7) Notify control no longer pointed by the mouse, that it is LEFT
 if (ClickLevel <= 0)and(LastOver <> CtrlOver) then
  begin
   if (LastOver <> nil) then LastOver.AcceptMouse(MousePos, mseLeave, Button,
    Shift);
   LastOver:= CtrlOver;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.DoKeyEvent(Key: Integer; Event: TKeyEventType;
 Shift: TShiftState);
begin
 if (FocusIndex >= 0)and(FocusIndex < ControlCount) then
  Control[FocusIndex].AcceptKey(Key, Event, Shift);
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.ListObjectNames(Control: TGuiControl; Strings: TStrings);
var
 Index: Integer;
begin
 if (not Control.CtrlHolder) then Exit;
 
 for Index:= 0 to Control.ControlCount - 1 do
  begin
   Strings.Add(Control[Index].Name + ':' + Control[Index].NameOfClass);
   ListObjectNames(Control[Index], Strings);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.MakeObjectList(Strings: TStrings);
begin
 ListObjectNames(Self, Strings);
end;

//---------------------------------------------------------------------------
procedure TGuiTaskbar.RemoveRef();
begin
 LastOver:= nil;
 LastClick:= nil;
end;

//---------------------------------------------------------------------------
function TGuiTaskbar.SaveToFile(const Filename: string): Boolean;
var
 Stream: TFileStream;
begin
 try
  Stream:= TFileStream.Create(Filename, fmCreate or fmShareExclusive);
 except
  Result:= False;
  Exit;
 end;

 try
  Result:= SaveToStream(Stream);
 finally
  Stream.Free();
 end;
end;

//---------------------------------------------------------------------------
function TGuiTaskbar.LoadFromFile(const Filename: string): Boolean;
var
 Stream: TFileStream;
begin
 try
  Stream:= TFileStream.Create(Filename, fmOpenRead or fmShareDenyWrite);
 except
  Result:= False;
  Exit;
 end;

 try
  Result:= LoadFromStream(Stream);
 finally
  Stream.Free();
 end;
end;

//---------------------------------------------------------------------------
function TGuiTaskbar.LoadFromASDb(const Key: string; ASDb: TASDb): Boolean;
var
 Stream: TMemoryStream;
begin
 Result:= ASDb.UpdateOnce();
 if (not Result) then Exit;

 Stream:= TMemoryStream.Create();
 Result:= ASDb.ReadStream(Key, Stream);
 if (not Result) then
  begin
   Stream.Free();
   Exit;
  end;

 Stream.Seek(0, soFromBeginning);
 Result:= LoadFromStream(Stream);

 Stream.Free();  
end;

//---------------------------------------------------------------------------
end.

unit GuiControls;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, AsphyreDef, GuiTypes, GuiComponents;

//---------------------------------------------------------------------------
type
 TGuiControl = class(TGuiComponent)
 private
  Controls: array of TGuiControl;

  FName : string;
  FOwner: TGuiControl;

  FOnMouse: TGuiMouseEvent;
  FOnKey  : TGuiKeyEvent;
  FOnClick: TNotifyEvent;
  FOnDblClick: TNotifyEvent;
  FMouseOver : Boolean;
  FOnMouseEnter: TNotifyEvent;
  FOnMouseLeave: TNotifyEvent;

  FFont    : TGuiFont;
  FBkgrnd  : TGuiFill;
  FBorder  : TGuiFill;
  FSelected: TGuiFill;
  FDrawFx  : Cardinal;
  FDisabledFont: TGuiFont;

  function GetControlCount(): Integer;
  function GetControl(Index: Integer): TGuiControl;
  function FindControl(const Name: string): TGuiControl;
  function GetCtrl(Name: string): TGuiControl;
  function GetRootCtrl(): TGuiControl;
  function GetFocused(): Boolean;
  procedure ToFront(Index: Integer);
  procedure ToBack(Index: Integer);
  function GetVisibleRect(): TRect;
  function GetVirtualRect(): TRect;
  procedure PasteProps(Stream: TStream; Master: TGuiComponent);

  procedure PasteFromStream(Control: TGuiControl; Stream: TStream);
  procedure CopyToStream(Control: TGuiControl; Stream: TStream);

  procedure PasteFromClipboardEx(Control: TGuiControl; Stream: TStream;
   Master: TGuiControl);
  function PasteFromClipboard(Stream: TStream): Boolean;
  function CopyToClipboard(Stream: TStream): Boolean;
 protected
  FocusIndex : Integer;
  FCtrlHolder: Boolean;

  property OnMouse: TGuiMouseEvent read FOnMouse write FOnMouse;
  property OnKey  : TGuiKeyEvent read FOnKey write FOnKey;
  property OnClick: TNotifyEvent read FOnClick write FOnClick;
  property OnDblClick: TNotifyEvent read FOnDblClick write FOnDblClick;
  property OnMouseEnter: TNotifyEvent read FOnMouseEnter write FOnMouseEnter;
  property OnMouseLeave: TNotifyEvent read FOnMouseLeave write FOnMouseLeave;

  property Font    : TGuiFont read FFont;
  property Bkgrnd  : TGuiFill read FBkgrnd;
  property Border  : TGuiFill read FBorder;
  property Selected: TGuiFill read FSelected;
  property DisabledFont: TGuiFont read FDisabledFont;

  function Screen2Local(const Point: TPoint): TPoint;
  procedure FocusSomething();

  procedure DoUpdate(); virtual;
  procedure DoPaint(); virtual;
  procedure DoShow(); override;
  procedure DoHide(); override;

  procedure DoMouseEvent(const MousePos: TPoint; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TShiftState); virtual;
  procedure DoKeyEvent(Key: Integer; Event: TKeyEventType;
   Shift: TShiftState); virtual;

  procedure SelfDescribe(); override;
  procedure DescribeDefault(Name: string);
  function ReadProp(Tag: Integer): Variant; override;
  procedure WriteProp(Tag: Integer; const Value: Variant); override;
  function ReadPropFill(Tag: Integer): TGuiFill; override;
  procedure WritePropFill(Tag: Integer; Value: TGuiFill); override;
  function ReadPropFont(Tag: Integer): TGuiFont; override;
  procedure WritePropFont(Tag: Integer; Value: TGuiFont); override;
 public
  property Name : string read FName write FName;
  property Owner: TGuiControl read FOwner;
  property MouseOver: Boolean read FMouseOver;
  property Focused  : Boolean read GetFocused;
  property DrawFx   : Cardinal read FDrawFx write FDrawFx;

  property CtrlHolder: Boolean read FCtrlHolder;
  // the first control in the tree
  property RootCtrl : TGuiControl read GetRootCtrl;

  property ControlCount: Integer read GetControlCount;
  property Control[Index: Integer]: TGuiControl read GetControl; default;
  property Ctrl[Name: string]: TGuiControl read GetCtrl;

  // The rectangle that covers this entire control in screen space
  property VisibleRect: TRect read GetVisibleRect;

  // The rectangle to draw on the screen (will be clipped with VisibleRect rect)
  property VirtualRect: TRect read GetVirtualRect;

  function Link(Control: TGuiControl): Integer;
  procedure Unlink(Control: TGuiControl);
  function IndexOf(Control: TGuiControl): Integer;
  procedure ReleaseAll();

  procedure AcceptMouse(const MousePos: TPoint; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TShiftState);
  procedure AcceptKey(Key: Integer; Event: TKeyEventType; Shift: TShiftState);

  function FindCtrlAt(const Point: TPoint): TGuiControl; virtual;
  procedure BringToFront();
  procedure SentToBack();
  procedure SetFocus(); virtual;

  procedure Update();
  procedure Draw();

  function LoadFromStream(Stream: TStream): Boolean;
  function SaveToStream(Stream: TStream): Boolean;

  function CopyToString(out Text: string): Boolean;
  function PasteFromString(const Text: string): Boolean;

  constructor Create(AOwner: TGuiControl); virtual;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 GuiTaskbar, GuiForms, StreamEx, GuiRegistry, AsphyreBase64;

//------------------------------------------------------------------------------
function MakeGuiName(Master: TGuiControl; const ClassName: string): string;
var
 Num: Integer;
begin
 if (Pos('tgui', LowerCase(ClassName)) = 1) then
  begin
   Result:= Copy(ClassName, 5, Length(ClassName) - 4);
  end else Result:= ClassName;

 Num:= 1;
 while (Master.Ctrl[Result + IntToStr(Num)] <> nil) do Inc(Num);
 Result:= Result + IntToStr(Num);
end;

//---------------------------------------------------------------------------
constructor TGuiControl.Create(AOwner: TGuiControl);
begin
 inherited Create();

 FOwner:= AOwner;
 FName := '';

 FMouseOver:= False;
 FCtrlHolder:= False;

 FDrawFx  := fxNone;
 FFont    := TGuiFont.Create();
 FBkgrnd  := TGuiFill.Create();
 FBorder  := TGuiFill.Create();
 FSelected:= TGuiFill.Create();
 FDisabledFont:= TGuiFont.Create();

 if (FOwner <> nil) then FOwner.Link(Self);
 FocusIndex:= -1;
end;

//---------------------------------------------------------------------------
destructor TGuiControl.Destroy();
begin
 if (FOwner <> nil) then
  FOwner.Unlink(Self);

 ReleaseAll();

 FDisabledFont.Free();
 FSelected.Free();
 FBorder.Free();
 FBkgrnd.Free();
 FFont.Free();

 inherited;
end;

//---------------------------------------------------------------------------
function TGuiControl.GetControlCount(): Integer;
begin
 Result:= Length(Controls);
end;

//---------------------------------------------------------------------------
function TGuiControl.GetControl(Index: Integer): TGuiControl;
begin
 if (Index >= 0)and(Index < Length(Controls)) then
  Result:= Controls[Index] else Result:= nil;
end;

//---------------------------------------------------------------------------
function TGuiControl.IndexOf(Control: TGuiControl): Integer;
var
 i: Integer;
begin
 for i:= 0 to Length(Controls) - 1 do
  if (Controls[i] = Control) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= -1;
end;

//---------------------------------------------------------------------------
function TGuiControl.Link(Control: TGuiControl): Integer;
var
 Index: Integer;
begin
 Index:= IndexOf(Control);
 if (Index <> -1) then
  begin
   Result:= Index;
   Exit;
  end;

 Index:= Length(Controls);
 SetLength(Controls, Index + 1);

 Controls[Index]:= Control;
 Result:= Index;

 if (FocusIndex = -1) then FocusIndex:= Index;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.Unlink(Control: TGuiControl);
var
 Index, i: Integer;
begin
 Index:= IndexOf(Control);
 if (Index = -1) then Exit;

 if (FocusIndex = Index) then FocusIndex:= -1;

 for i:= Index to Length(Controls) - 2 do
  Controls[i]:= Controls[i + 1];

 SetLength(Controls, Length(Controls) - 1);

 if (FocusIndex = -1) then FocusSomething();
end;

//---------------------------------------------------------------------------
procedure TGuiControl.ReleaseAll();
var
 i  : Integer;
 Aux: TGuiControl;
begin
 for i:= Length(Controls) - 1 downto 0 do
  begin
   Aux:= Controls[i];
   Controls[i]:= nil;
   Aux.Free();
  end;

 SetLength(Controls, 0);
end;

//---------------------------------------------------------------------------
function TGuiControl.FindControl(const Name: string): TGuiControl;
var
 Index: Integer;
begin
 Result:= nil;

 if (Name = LowerCase(Self.Name)) then
  begin
   Result:= Self;
   Exit;
  end;

 for Index:= 0 to Length(Controls) - 1 do
  begin
   if (Name = LowerCase(Controls[Index].Name)) then
    begin
     Result:= Controls[Index];
     Break;
    end;

   Result:= Controls[Index].FindControl(Name);
   if (Result <> nil) then Break;
  end;
end;

//---------------------------------------------------------------------------
function TGuiControl.GetCtrl(Name: string): TGuiControl;
begin
 Name:= LowerCase(Name);
 Result:= FindControl(Name);
end;

//---------------------------------------------------------------------------
function TGuiControl.GetRootCtrl(): TGuiControl;
begin
 Result:= Self;
 while (Result.Owner <> nil) do Result:= Result.Owner;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.FocusSomething();
var
 i: Integer;
begin
 FocusIndex:= -1;
 for i:= 0 to Length(Controls) - 1 do
  if (Controls[i].Visible)and(Controls[i].Enabled) then
   begin
    FocusIndex:= i;
    Break;
   end; 
end;

//---------------------------------------------------------------------------
procedure TGuiControl.DoHide();
begin
 if (Owner <> nil)and(Owner.FocusIndex = Owner.IndexOf(Self)) then
  Owner.FocusSomething();
end;

//---------------------------------------------------------------------------
procedure TGuiControl.DoShow();
begin
 if (Owner <> nil)and(Owner.FocusIndex = -1) then
  Owner.FocusSomething();
end;

//---------------------------------------------------------------------------
function TGuiControl.GetFocused(): Boolean;
begin
 if (Owner = nil) then
  begin
   Result:= True;
   Exit;
  end;

 Result:= (Owner.FocusIndex = Owner.IndexOf(Self))and(Owner.Focused);
end;

//---------------------------------------------------------------------------
procedure TGuiControl.SetFocus();
begin
 if (Owner <> nil) then
  begin
   Owner.FocusIndex:= Owner.IndexOf(Self);
   Owner.SetFocus();
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.ToFront(Index: Integer);
var
 Aux: TGuiControl;
 i: Integer;
begin
 if (FocusIndex = Index) then FocusIndex:= 0;
 Aux:= Controls[Index];

 for i:= Index downto 1 do
  Controls[i]:= Controls[i - 1];

 Controls[0]:= Aux;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.ToBack(Index: Integer);
var
 Aux: TGuiControl;
 i: Integer;
begin
 if (FocusIndex = Index) then FocusIndex:= Length(Controls) - 1;
 Aux:= Controls[Index];

 for i:= Index to Length(Controls) - 2 do
  Controls[i]:= Controls[i + 1];

 Controls[Length(Controls) - 1]:= Aux;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.BringToFront();
begin
 if (FOwner <> nil) then
  FOwner.ToFront(FOwner.IndexOf(Self));
end;

//---------------------------------------------------------------------------
procedure TGuiControl.SentToBack();
begin
 if (FOwner <> nil) then
  FOwner.ToBack(FOwner.IndexOf(Self));
end;

//---------------------------------------------------------------------------
function TGuiControl.GetVisibleRect(): TRect;
var
 OwnerSurface: TRect;
 MySurface: TRect;
begin
 if (FOwner = nil) then
  begin
   Result:= ClientRect;
   Exit;
  end;

 // Retreive owner VisibleRect
 OwnerSurface:= Owner.VisibleRect;

 // Calculate our theoretical VisibleRect, in absolute space
 MySurface:= MoveRect(ClientRect, Owner.VirtualRect.TopLeft);

 // The intersection of both rectangles is our result
 Result:= ShortRect(MySurface, OwnerSurface);
end;

//---------------------------------------------------------------------------
function TGuiControl.GetVirtualRect(): TRect;
begin
 if (FOwner = nil) then
  begin
   Result:= ClientRect;
   Exit;
  end;

 Result:= MoveRect(ClientRect, Owner.VirtualRect.TopLeft);
end;

//---------------------------------------------------------------------------
function TGuiControl.FindCtrlAt(const Point: TPoint): TGuiControl;
var
 Allowed: Boolean;
 Index: Integer;
 Aux: TGuiControl;
begin
 // First, let's check if we can be selected ourselves.
 Allowed:= (Visible)or(guiDesign);
 if (not Allowed)or(not PointInRect(Point, VisibleRect)) then
  begin
   Result:= nil;
   Exit;
  end;

 Result:= Self;

 // Now that we *are* pointed, let's check if one of our own
 // controls is pointed by.
 for Index:= 0 to Length(Controls) - 1 do
  begin
   Aux:= Controls[Index].FindCtrlAt(Point);
   if (Aux <> nil) then
    begin
     Result:= Aux;
     Break;
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.DoUpdate();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiControl.DoPaint();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiControl.DoKeyEvent(Key: Integer; Event: TKeyEventType;
 Shift: TShiftState);
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiControl.DoMouseEvent(const MousePos: TPoint;
 Event: TMouseEventType; Button: TMouseButtonType; Shift: TShiftState);
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiControl.Update();
var
 i: Integer;
begin
 DoUpdate();

 for i:= 0 to Length(Controls) - 1 do
  Controls[i].Update();
end;

//---------------------------------------------------------------------------
procedure TGuiControl.Draw();
var
 MySurface: TRect;
 PrevRect: TRect;
 i: Integer;
begin
 MySurface:= GetVisibleRect();
 if (MySurface.Bottom <= MySurface.Top)or(MySurface.Right <= MySurface.Left) then Exit;

 // save previous clipping rectangle
 PrevRect:= guiCanvas.ClipRect;

 // apply own clipping rectangle
 guiCanvas.ClipRect:= MySurface;

 // call painter event
 DoPaint();

 // restore previous clipping rectangle
 guiCanvas.ClipRect:= PrevRect;

 // draw all owned controls
 for i:= Length(Controls) - 1 downto 0 do
  if (Controls[i].Visible)or(guiDesign) then
   Controls[i].Draw();
end;

//---------------------------------------------------------------------------
procedure TGuiControl.AcceptMouse(const MousePos: TPoint; Event: TMouseEventType;
 Button: TMouseButtonType; Shift: TShiftState);
begin
 DoMouseEvent(MousePos, Event, Button, Shift);

 if (Assigned(FOnMouse)) then FOnMouse(Self, MousePos, Event, Button, Shift);
 if (Event = mseClick)and(Enabled)and(Assigned(FOnClick))and
  (PointInRect(MousePos, VirtualRect)) then FOnClick(Self);
 if (Event = mseDblClick)and(Enabled)and(Assigned(FOnDblClick))and
  (PointInRect(MousePos, VirtualRect)) then FOnDblClick(Self);
 if (Event = mseEnter) then
  begin
   FMouseOver:= True;
   if (Assigned(FOnMouseEnter)) then FOnMouseEnter(Self);
  end; 
 if (Event = mseLeave) then
  begin
   FMouseOver:= False;
   if (Assigned(FOnMouseLeave)) then FOnMouseLeave(Self);
  end; 
end;

//---------------------------------------------------------------------------
procedure TGuiControl.AcceptKey(Key: Integer; Event: TKeyEventType;
 Shift: TShiftState);
begin
 if (FocusIndex >= 0)and(FocusIndex < ControlCount) then
  begin
   Control[FocusIndex].AcceptKey(Key, Event, Shift);
  end else
  begin
   DoKeyEvent(Key, Event, Shift);
   if (Assigned(FOnKey)) then FOnKey(Self, Key, Event, Shift);
  end; 
end;

//---------------------------------------------------------------------------
procedure TGuiControl.SelfDescribe();
begin
 inherited;

 FNameOfClass:= 'TGuiControl';
 FDescOfClass:= 'TGuiControl generic class';

 IncludeProp('Name',   ptString, $80000, 'The unique name of control');
 IncludeProp('DrawFx', ptDrawOp, $80001, 'Drawing effect used with this control');
end;

//---------------------------------------------------------------------------
procedure TGuiControl.DescribeDefault(Name: string);
begin
 Name:= LowerCase(Name);

 if (Name = 'font') then
  IncludeProp('Font', ptFont, $80002, 'The font of the displayed text');

 if (Name = 'bkgrnd') then
  IncludeProp('Bkgrnd', ptFill, $80003, 'How to fill the background of this control');

 if (Name = 'border') then
  IncludeProp('Border', ptFill, $80004, 'The fill style of control''s border');

 if (Name = 'selected') then
  IncludeProp('Selected', ptFill, $80005, 'How to fill the control when it''s selected');

 if (Name = 'disabledfont') then
  IncludeProp('DisabledFont', ptFont, $80006, 'The text font when the control is disabled');
end;

//---------------------------------------------------------------------------
function TGuiControl.ReadProp(Tag: Integer): Variant;
begin
 case Tag of
  $80000: Result:= FName;
  $80001: Result:= FDrawFx;
  else Result:= inherited ReadProp(Tag);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.WriteProp(Tag: Integer; const Value: Variant);
begin
 case Tag of
  $80000: Name  := Value;
  $80001: DrawFx:= Value;
  else inherited WriteProp(Tag, Value);
 end;
end;

//---------------------------------------------------------------------------
function TGuiControl.ReadPropFill(Tag: Integer): TGuiFill;
begin
 case Tag of
  $80003: Result:= Bkgrnd;
  $80004: Result:= Border;
  $80005: Result:= Selected;
  else Result:= inherited ReadPropFill(Tag);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.WritePropFill(Tag: Integer; Value: TGuiFill);
begin
 case Tag of
  $80003: Bkgrnd.Assign(Value);
  $80004: Border.Assign(Value);
  $80005: Selected.Assign(Value);
  else inherited WritePropFill(Tag, Value);
 end;
end;

//---------------------------------------------------------------------------
function TGuiControl.ReadPropFont(Tag: Integer): TGuiFont;
begin
 case Tag of
  $80002: Result:= Font;
  $80006: Result:= FDisabledFont;
  else Result:= inherited ReadPropFont(Tag);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.WritePropFont(Tag: Integer; Value: TGuiFont);
begin
 case Tag of
  $80002: Font.Assign(Value);
  $80006: FDisabledFont.Assign(Value);
  else inherited WritePropFont(Tag, Value);
 end;
end;

//---------------------------------------------------------------------------
function TGuiControl.Screen2Local(const Point: TPoint): TPoint;
var
 Surf: TRect;
begin
 Surf:= GetVirtualRect();
 
 Result.X:= Point.X - Surf.Left;
 Result.Y:= Point.Y - Surf.Top;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.PasteProps(Stream: TStream; Master: TGuiComponent);
var
 Count, Index: Integer;
 Field: string;
 PropType: TPropertyType;
 NewName: string;
begin
 Stream.ReadBuffer(Count, SizeOf(Integer));

 for Index:= 0 to Count - 1 do
  begin
   Field:= stReadString(Stream);
   Stream.ReadBuffer(PropType, SizeOf(TPropertyType));

   if (PropType <> ptFill)and(PropType <> ptFont) then
    begin
     if (PropType = ptString)and(LowerCase(Field) = 'name') then
      begin
       NewName:= stReadString(Stream);
       if (TGuiControl(Master).Ctrl[NewName] <> nil) then
        begin
         Prop[Field]:= MakeGuiName(TGuiControl(Master), ClassName);
        end else Prop[Field]:= NewName;
      end else Prop[Field]:= stReadString(Stream);
    end else
    begin
     case PropType of
      ptFill: PropFill[Field].ReadFromStream(Stream);
      ptFont: PropFont[Field].ReadFromStream(Stream);
     end; // case
    end; // if
  end; // for

 Left:= Left + guiPosGrid.X;
 Top := Top + guiPosGrid.Y;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.CopyToStream(Control: TGuiControl; Stream: TStream);
var
 Count, Index: Integer;
begin
 if (Control = nil) then Control:= Self;

 Count:= Control.ControlCount;
 if (not Control.CtrlHolder) then Count:= 0;
 
 Stream.WriteBuffer(Count, SizeOf(Integer));

 for Index:= 0 to Count - 1 do
  begin
   stWriteString(Stream, Control[Index].NameOfClass);
   Control[Index].WriteProps(Stream);
   CopyToStream(Control[Index], Stream);
  end;
end;

//---------------------------------------------------------------------------
function TGuiControl.CopyToClipboard(Stream: TStream): Boolean;
var
 Count: Integer;
begin
 Result:= True;
 
 try
  Count:= 1;
  Stream.WriteBuffer(Count, SizeOf(Integer));

  stWriteString(Stream, NameOfClass);
  WriteProps(Stream);
  CopyToStream(Self, Stream);
 except
  Result:= False;
 end;  
end;

//---------------------------------------------------------------------------
procedure TGuiControl.PasteFromStream(Control: TGuiControl; Stream: TStream);
var
 Count, Index: Integer;
 CtrlName: string;
 NewCtrl: TGuiControl;
begin
 if (Control = nil) then Control:= Self;

 Stream.ReadBuffer(Count, SizeOf(Integer));

 for Index:= 0 to Count - 1 do
  begin
   CtrlName:= stReadString(Stream);
   NewCtrl:= MasterRegistry.NewControl(CtrlName, Control);
   if (NewCtrl <> nil) then NewCtrl.ReadProps(Stream) else Break;
   PasteFromStream(NewCtrl, Stream);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiControl.PasteFromClipboardEx(Control: TGuiControl;
 Stream: TStream; Master: TGuiControl);
var
 Count, Index: Integer;
 CtrlName: string;
 NewCtrl: TGuiControl;
begin
 if (Control = nil) then Control:= Self;

 Stream.ReadBuffer(Count, SizeOf(Integer));

 for Index:= 0 to Count - 1 do
  begin
   CtrlName:= stReadString(Stream);
   NewCtrl:= MasterRegistry.NewControl(CtrlName, Control);

   if (NewCtrl <> nil) then
    NewCtrl.PasteProps(Stream, Master) else Break;
   PasteFromClipboardEx(NewCtrl, Stream, Master);
  end;
end;

//---------------------------------------------------------------------------
function TGuiControl.LoadFromStream(Stream: TStream): Boolean;
begin
 Result:= True;

 try
  PasteFromStream(nil, Stream);
 except
  Result:= False;
 end;
end;

//---------------------------------------------------------------------------
function TGuiControl.SaveToStream(Stream: TStream): Boolean;
begin
 Result:= True;

 try
  CopyToStream(nil, Stream);
 except
  Result:= False;
 end;
end;

//---------------------------------------------------------------------------
function TGuiControl.PasteFromClipboard(Stream: TStream): Boolean;
begin
 Result:= True;

 try
  PasteFromClipboardEx(Self, Stream, RootCtrl);
 except
  Result:= False;
 end;
end;

//---------------------------------------------------------------------------
function TGuiControl.CopyToString(out Text: string): Boolean;
var
 Stream: TMemoryStream;
begin
 Stream:= TMemoryStream.Create();

 Result:= CopyToClipboard(Stream);
 if (not Result) then
  begin
   Stream.Free();
   Exit;
  end;

 Text:= Base64String(Stream.Memory, Stream.Size);
 Stream.Free();
end;

//---------------------------------------------------------------------------
function TGuiControl.PasteFromString(const Text: string): Boolean;
var
 Stream: TMemoryStream;
begin
 Stream:= TMemoryStream.Create();
 Stream.SetSize(Round(Length(Text) * 3 / 4) + 1);
 Stream.SetSize(Base64Binary(Text, Stream.Memory));

 Result:= PasteFromClipboard(Stream);
 Stream.Free();
end;

//---------------------------------------------------------------------------
end.


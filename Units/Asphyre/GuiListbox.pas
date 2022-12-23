unit GuiListbox;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, Math, AsphyreDef, GuiTypes, GuiControls,
 GuiScroll, AsphyreFonts, TypesEx;

//---------------------------------------------------------------------------
type
 TGuiListBox = class(TGuiControl)
 private
  FItems : TStrings;
  FScroll: TGuiScroll;
  FIndexed  : TGuiFill;
  FItemSize : Integer;
  FItemIndex: Integer;
  TopIndex  : Integer;
  OverIndex : Integer;
  FOnChange : TNotifyEvent;
  FBorderColor: Cardinal;
  FIndexedFont: TGuiFont;
  FTextAdjust : Integer;

  procedure SetBorderColor(const Value: Cardinal);
  procedure DrawItem(Index: Integer; const ItemRect: TRect; Current,
   Pointed: Boolean);
  procedure ScrollMouseEnter(Sender: TObject);
  function GetScrlArrow(): Longword;
  function GetScrlButton(): TGuiFill;
  function GetScrlFill(): TGuiFill;
  function GetScrlPressed(): TGuiFill;
  procedure SetScrlArrow(const Value: Longword);
 protected
  procedure DoPaint(); override;
  procedure DoMouseEvent(const MousePos: TPoint; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TShiftState); override;
  procedure SelfDescribe(); override;
  function ReadProp(Tag: Integer): Variant; override;
  procedure WriteProp(Tag: Integer; const Value: Variant); override;
  function ReadPropFill(Tag: Integer): TGuiFill; override;
  procedure WritePropFill(Tag: Integer; Value: TGuiFill); override;
  function ReadPropFont(Tag: Integer): TGuiFont; override;
  procedure WritePropFont(Tag: Integer; Value: TGuiFont); override;
 public
  property Scroll: TGuiScroll read FScroll;
  property Items : TStrings read FItems;
  property ItemSize  : Integer read FItemSize write FItemSize;
  property Indexed   : TGuiFill read FIndexed;
  property ItemIndex : Integer read FItemIndex write FItemIndex;
  property TextAdjust: Integer read FTextAdjust write FTextAdjust;
  property OnChange  : TNotifyEvent read FOnChange write FOnChange;

  property ScrollButton : TGuiFill read GetScrlButton;
  property ScrollFill   : TGuiFill read GetScrlFill;
  property ScrollPressed: TGuiFill read GetScrlPressed;
  property ScrollArrow  : Longword read GetScrlArrow write SetScrlArrow;

  property IndexedFont: TGuiFont read FIndexedFont;
  property BorderColor: Cardinal read FBorderColor write SetBorderColor;

  property DisabledFont;
  property Font;
  property Bkgrnd;
  property Selected;

  procedure ScrollDown();

  constructor Create(AOwner: TGuiControl); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TGuiListBox.Create(AOwner: TGuiControl);
begin
 inherited;

 FItems  := TStringList.Create();
 FIndexed:= TGuiFill.Create();
 FIndexedFont:= TGuiFont.Create();
 FScroll := TGuiScroll.Create(Self);
 FScroll.Width:= 16;
 FScroll.OnMouseEnter:= ScrollMouseEnter;
 FScroll.Theta:= 1.0;

 Bkgrnd.Color4 := cColor4($FFF3E7E4, $FFF5E4DF, $FFFFF3EF, $FFFFFFFF);
 Bkgrnd.Visible:= True;

 Selected.Color1($FFF7DFD6);
 Selected.Visible:= True;

 FBorderColor:= $FFB99D7F;

 Indexed.Color1($FFE7C3AE);
 Indexed.Visible:= True;

 Font.Color0:= $FFC56A31;
 Font.Color1:= $FFC56A31;

 FIndexedFont.Color0:= $FFC65B1F;
 FIndexedFont.Color1:= $FFC65B1F;

 DisabledFont.Color0:= $FF5F6B70;
 DisabledFont.Color1:= $FF5F6B70;

 FItems.Text:= 'Item 1'#10'Item 2'#10'Item 3';

 FItemSize  := 18;
 FItemIndex := -1;
 FTextAdjust:= 0;

 Width := 200;
 Height:= 150;
 TopIndex := 0;
 OverIndex:= -1;
 FCtrlHolder:= False;
end;

//---------------------------------------------------------------------------
destructor TGuiListBox.Destroy();
begin
 FIndexedFont.Free();
 FIndexed.Free();
 FItems.Free();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.SetBorderColor(const Value: Cardinal);
begin
 FBorderColor:= Value;
 FScroll.BorderColor:= Value;
end;

//---------------------------------------------------------------------------
procedure TGuiListbox.DrawItem(Index: Integer; const ItemRect: TRect;
 Current, Pointed: Boolean);
var
 MyFont: TAsphyreFont;
 Inside: TRect;
 st    : string;
 yPos  : Integer;
 Source: TGuiFont;
begin
 Inside:= ShrinkRect(ItemRect, 1, 1);

 if (Pointed)and(Selected.Visible)and(not Current)and(not guiDesign) then
  begin
   if (Selected.Visible) then
    guiCanvas.FillQuad(pRect4(Inside), Selected.Color4, DrawFx);

   if (FBorderColor shr 24 > 0) then
    guiCanvas.Quad(pRect4(Inside), cColor4(FBorderColor), DrawFx);
  end;

 if (Indexed.Visible)and(Current)and(Enabled) then
  begin
   if (Indexed.Visible) then
    guiCanvas.FillQuad(pRect4(Inside), Indexed.Color4, DrawFx);

   if (FBorderColor shr 24 > 0) then
    guiCanvas.Quad(pRect4(Inside), cColor4(FBorderColor), DrawFx);
  end;

 Source:= Font;
 if (Current) then Source:= IndexedFont;
 if (not Enabled) then Source:= DisabledFont;

 MyFont:= Source.Setup();
 if (MyFont <> nil) then
  begin
   st:= FItems[Index];
   yPos:= Inside.Top + (((Inside.Bottom - Inside.Top) - Round(MyFont.TextHeight(st))) div 2);

   Source.TextOut(FItems[Index], ItemRect.Left + 4, yPos + FTextAdjust);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.DoPaint();
var
 ClientRect, ElemRect: TRect;
 i, ElemCount, ScrollAmount: Integer;
 PaintRect: TRect;
begin
 PaintRect:= VirtualRect;

 FScroll.DrawFx:= DrawFx;

 ElemCount:= (Height - 2) div FItemSize;
 if (ElemCount > FItems.Count) then ElemCount:= FItems.Count;

 FScroll.Visible:= (ElemCount < FItems.Count);
 if (FScroll.Visible) then
  begin
   ScrollAmount:= FItems.Count - ElemCount;
   FScroll.ArrowInc:= 1.0 / ScrollAmount;
   FScroll.PageInc := 4.0 / ScrollAmount;

   TopIndex:= Round(FScroll.Theta * ScrollAmount);
  end;

 if (TopIndex + ElemCount > FItems.Count) then
  TopIndex:= Max(FItems.Count - ElemCount, 0);

 ClientRect:= PaintRect;

 if (FScroll.Visible) then
  ClientRect.Right:= PaintRect.Right - (FScroll.Width - 1);

 if (Bkgrnd.Visible) then
  guiCanvas.FillQuad(pRect4(ClientRect), Bkgrnd.Color4, DrawFx);

 if (FBorderColor shr 24 > 0) then
  guiCanvas.Quad(pRect4(ClientRect), cColor4(FBorderColor), DrawFx);

 if (FItemIndex >= FItems.Count) then FItemIndex:= -1;
 for i:= 0 to ElemCount - 1 do
  begin
   ElemRect:= Bounds(ClientRect.Left + 1, ClientRect.Top + 1 + (FItemSize * i),
    (ClientRect.Right - ClientRect.Left) - 2, FItemSize);

   DrawItem(i + TopIndex, ElemRect, (FItemIndex = i + TopIndex),
    (OverIndex = i + TopIndex));
  end;

 // update scrollbar
 FScroll.Left  := Width - FScroll.Width;
 FScroll.Top   := 0;
 FScroll.Height:= Height;
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.ScrollDown();
begin
 FScroll.Theta:= 1.0;
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.DoMouseEvent(const MousePos: TPoint;
 Event: TMouseEventType; Button: TMouseButtonType; Shift: TShiftState);
var
 vRect: TRect;
begin
 vRect:= VirtualRect;

 OverIndex:= (((MousePos.Y - vRect.Top) - 1) div FItemSize) + TopIndex;
 if (OverIndex >= FItems.Count) then OverIndex:= -1;

 if (Event = mseDown)and(OverIndex <> -1)and(Button = btnLeft) then
  begin
   FItemIndex:= OverIndex;
   if (Assigned(OnChange)) then OnChange(Self);
  end;

 if (Event = mseLeave)or(not Enabled) then OverIndex:= -1; 
end;

//---------------------------------------------------------------------------
procedure TGuiListBox.ScrollMouseEnter(Sender: TObject);
begin
 OverIndex:= -1;
end;

//---------------------------------------------------------------------------
function TGuiListbox.GetScrlButton(): TGuiFill;
begin
 Result:= FScroll.Button;
end;

//---------------------------------------------------------------------------
function TGuiListbox.GetScrlPressed(): TGuiFill;
begin
 Result:= FScroll.Pressed;
end;

//---------------------------------------------------------------------------
function TGuiListbox.GetScrlFill(): TGuiFill;
begin
 Result:= FScroll.Scroll;
end;

//---------------------------------------------------------------------------
function TGuiListbox.GetScrlArrow(): Longword;
begin
 Result:= FScroll.ArrowColor;
end;

//---------------------------------------------------------------------------
procedure TGuiListbox.SetScrlArrow(const Value: Longword);
begin
 FScroll.ArrowColor:= Value;
end;

//---------------------------------------------------------------------------
procedure TGuiListbox.SelfDescribe();
begin
 inherited;
 
 FNameOfClass:= 'TGuiListBox';
 FDescOfClass:= 'TGuiListBox is a simple set of multiple selectable strings';

 DescribeDefault('bkgrnd');
 DescribeDefault('selected');
 DescribeDefault('font');

 IncludeProp('Items',         ptStrings, $A000, 'The list of displayed strings');
 IncludeProp('ItemSize',      ptInteger, $A001, 'The size of individual item in the list');
 IncludeProp('Indexed',       ptFill,    $A002, 'The fill-style of a selected item');
 IncludeProp('ItemIndex',     ptInteger, $A003, 'The index of currently selected item');
 IncludeProp('TextAdjust',    ptInteger, $A004, 'The vertical text adjustment');
 IncludeProp('IndexedFont',   ptFont,    $A005, 'The font to be used with the selected item');
 IncludeProp('BorderColor',   ptColor,   $A006, 'The color of control''s border');
 IncludeProp('ScrollButton',  ptFill,    $A007, 'The fill-style of scrollbar''s buttons');
 IncludeProp('ScrollFill',    ptFill,    $A008, 'The fill-style of scrollbar''s scrolling area');
 IncludeProp('ScrollPressed', ptFill,    $A009, 'The fill-style scrollbar''s pressed buttons');
 IncludeProp('ScrollArrow',   ptColor,   $A00A, 'The color of scrollbar''s arrows');
end;

//---------------------------------------------------------------------------
function TGuiListbox.ReadProp(Tag: Integer): Variant;
begin
 case Tag of
  $A000: Result:= FItems.Text;
  $A001: Result:= FItemSize;
  $A003: Result:= FItemIndex;
  $A004: Result:= FTextAdjust;
  $A006: Result:= FBorderColor;
  $A00A: Result:= FScroll.ArrowColor;
  else Result:= inherited ReadProp(Tag);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiListbox.WriteProp(Tag: Integer; const Value: Variant);
begin
 case Tag of
  $A000: FItems.Text:= Value;
  $A001: ItemSize   := Value;
  $A003: ItemIndex  := Value;
  $A004: TextAdjust := Value;
  $A006: BorderColor:= Value;
  $A00A: FScroll.ArrowColor:= Value;
  else inherited WriteProp(Tag, Value);
 end;
end;

//---------------------------------------------------------------------------
function TGuiListbox.ReadPropFill(Tag: Integer): TGuiFill;
begin
 case Tag of
  $A002: Result:= FIndexed;
  $A007: Result:= FScroll.Button;
  $A008: Result:= FScroll.Scroll;
  $A009: Result:= FScroll.Pressed;
  else Result:= inherited ReadPropFill(Tag);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiListbox.WritePropFill(Tag: Integer; Value: TGuiFill);
begin
 case Tag of
  $A002: FIndexed.Assign(Value);
  $A007: FScroll.Button.Assign(Value);
  $A008: FScroll.Scroll.Assign(Value);
  $A009: FScroll.Pressed.Assign(Value);
  else inherited WritePropFill(Tag, Value);
 end;
end;

//---------------------------------------------------------------------------
function TGuiListbox.ReadPropFont(Tag: Integer): TGuiFont;
begin
 case Tag of
  $A005: Result:= FIndexedFont;
  else Result:= inherited ReadPropFont(Tag);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiListbox.WritePropFont(Tag: Integer; Value: TGuiFont);
begin
 case Tag of
  $A005: FIndexedFont.Assign(Value);
  else inherited WritePropFont(Tag, Value);
 end;
end;

//---------------------------------------------------------------------------
end.

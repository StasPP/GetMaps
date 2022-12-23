unit GuiEdit;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Windows, Types, Classes, SysUtils, Graphics, Controls, Math, TypesEx,
 AsphyreDef, AsphyreFonts, GuiTypes, GuiControls, Clipbrd;

//---------------------------------------------------------------------------
type
 TGuiEdit = class(TGuiControl)
 private
  Ticks: Integer;
  FText: string;
  FViewPos   : Integer;
  FTextAdjust: Integer;
  FSelIndex  : Integer;
  FSelector  : TGuiFill;
  FBlinkTicks: Integer;
  FOnChange  : TNotifyEvent;
  FReadOnly  : Boolean;
  FMaxLength : Integer;
  FTabOrder  : Integer;

  procedure SetViewPos(const Value: Integer);
  procedure SetText(const Value: string);
  procedure SetSelIndex(const Value: Integer);
  procedure DrawSelector(const vRect: TRect; vFont: TAsphyreFont);
  function CharRect(Index: Integer): TRect;
  function NeedToScroll(): Boolean;
  procedure ScrollToRight(Index: Integer);
  procedure ScrollToLeft(Index: Integer);
  procedure SelectChar(const MousePos: TPoint);
  procedure StripWrong(var Text: string);
  procedure SetMaxLength(const Value: Integer);
  procedure SetTabOrder(const Value: Integer);
  procedure PutLastTabOrder();
  procedure FocusNextTabOrder();
 protected
  procedure DoPaint(); override;
  procedure DoUpdate(); override;
  procedure DoKeyEvent(Key: Integer; Event: TKeyEventType;
   Shift: TShiftState); override;
  procedure DoMouseEvent(const MousePos: TPoint; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TShiftState); override;
  procedure SelfDescribe(); override;
  function ReadProp(Tag: Integer): Variant; override;
  procedure WriteProp(Tag: Integer; const Value: Variant); override;
  function ReadPropFill(Tag: Integer): TGuiFill; override;
  procedure WritePropFill(Tag: Integer; Value: TGuiFill); override;
 public
  property Text      : string read FText write SetText;
  property ViewPos   : Integer read FViewPos write SetViewPos;
  property TextAdjust: Integer read FTextAdjust write FTextAdjust;
  property SelIndex  : Integer read FSelIndex write SetSelIndex;
  property Selector  : TGuiFill read FSelector;
  property BlinkTicks: Integer read FBlinkTicks write FBlinkTicks;
  property ReadOnly  : Boolean read FReadOnly write FReadOnly;
  property MaxLength : Integer read FMaxLength write SetMaxLength;
  property TabOrder  : Integer read FTabOrder write SetTabOrder;

  property OnChange  : TNotifyEvent read FOnChange write FOnChange;

  property OnClick;
  property OnDblClick;
  property OnMouse;
  property OnKey;
  property OnMouseEnter;
  property OnMouseLeave;

  property Font;
  property Bkgrnd;
  property Border;
  property DisabledFont;

  constructor Create(AOwner: TGuiControl); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
const
 TextChars = [#32..#255];

//---------------------------------------------------------------------------
constructor TGuiEdit.Create(AOwner: TGuiControl);
begin
 inherited;

 FSelector:= TGuiFill.Create();
 FSelector.Visible:= True;
 FSelector.Color1($80D67563);

 Bkgrnd.Color4 := cColor4($FFF3E7E4, $FFF5E4DF, $FFFFF3EF, $FFFFFFFF);
 Bkgrnd.Visible:= True;

 Selected.Color4 := cColor4($FFFFFFFF, $FFFFFFFF, $FFFFD5D5, $FFFFD5D5);
 Selected.Visible:= True;

 Border.Color1($FFB99D7F);
 Border.Visible:= True;

 Font.Color0:= $FFC56A31;
 Font.Color1:= $FFC56A31;

 DisabledFont.Color0:= $FF5F6B70;
 DisabledFont.Color1:= $FF5F6B70;

 Width := 100;
 Height:= 20;

 FText:= 'Some text';
 Ticks:= 0;

 FTextAdjust:= 0;
 FBlinkTicks:= 8;
 FReadOnly  := False;
 FMaxLength := 0;

 PutLastTabOrder();
end;

//---------------------------------------------------------------------------
destructor TGuiEdit.Destroy();
begin
 FSelector.Free();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.SetViewPos(const Value: Integer);
var
 vFont: TAsphyreFont;
 mSize: Integer;
begin
 FViewPos:= Value;

 // make validation
 vFont:= Font.Setup();
 if (vFont <> nil) then
  begin
   mSize:= 4 + Round(vFont.TextWidth(FText)) + (Height div 2);

   if (FViewPos > mSize - Width) then FViewPos:= mSize - Width;
   if (FViewPos < 0) then FViewPos:= 0;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.SetSelIndex(const Value: Integer);
begin
 FSelIndex:= Value;
 if (FSelIndex < 0) then FSelIndex:= 0;
 if (FSelIndex > Length(FText) + 1) then FSelIndex:= Length(FText) + 1;
end;

//---------------------------------------------------------------------------
function TGuiEdit.CharRect(Index: Integer): TRect;
var
 vFont: TAsphyreFont;
 TextBefore: string;
 TextAfter : string;
 sLeft, sRight: Integer;
begin
 // (1) Retreive the used font
 vFont:= Font.Setup();
 if (vFont = nil) then
  begin
   Result:= Rect(0, 0, 0, 0);
   Exit;
  end;

 // (2) Extract part of text prior to selector
 TextBefore:= '';
 TextAfter := '';
 if (Index > 0) then TextBefore:= Copy(FText, 1, Index);
 if (Index >= 0) then TextAfter := Copy(FText, 1, Index + 1);

 // (3) Determine selected position
 sLeft := 2 + Round(vFont.TextWidth(TextBefore));
 if (TextAfter <> '')and(Index < Length(FText)) then
  sRight:= 2 + Round(vFont.TextWidth(TextAfter) - vFont.Interleave)
   else sRight:= sLeft + (Height div 2);

 // (4) Determine selected rectangle
 Result.Left  := sLeft;
 Result.Right := sRight;
 Result.Top   := 2;
 Result.Bottom:= Height - 2;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.ScrollToRight(Index: Integer);
var
 ChRect: TRect;
begin
 ChRect:= CharRect(Index);
 if (ChRect.Right <= ChRect.Left)and(ChRect.Right = 0) then Exit;

 ViewPos:= ChRect.Right - Width + 2;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.ScrollToLeft(Index: Integer);
var
 ChRect: TRect;
begin
 ChRect:= CharRect(Index);
 if (ChRect.Right <= ChRect.Left)and(ChRect.Right = 0) then Exit;

 ViewPos:= ChRect.Left - 2;
end;

//---------------------------------------------------------------------------
function TGuiEdit.NeedToScroll(): Boolean;
var
 ChRect, PaintRect, CutRect: TRect;
begin
 ChRect:= CharRect(FSelIndex);
 if (ChRect.Right <= ChRect.Left)and(ChRect.Right = 0) then
  begin
   Result:= False;
   Exit;
  end;

 PaintRect:= VirtualRect;
 CutRect:= ShortRect(MoveRect(ChRect, Point(PaintRect.Left - FViewPos, 0)),
  PaintRect);
 Result:= (CutRect.Right - CutRect.Left) < (ChRect.Right - ChRect.Left);
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.SelectChar(const MousePos: TPoint);
var
 i, Search: Integer;
 ChRect, vRect, PaintRect: TRect;
 RelPoint: TPoint;
begin
 PaintRect:= VirtualRect;
 RelPoint.X:= MousePos.X - PaintRect.Left;
 RelPoint.Y:= MousePos.Y - PaintRect.Top;

 Search:= Length(FText);
 for i:= 0 to Length(Text) do
  begin
   ChRect:= CharRect(i);
   if (ChRect.Right <= ChRect.Left)and(ChRect.Right = 0) then Exit;

   vRect:= MoveRect(ChRect, Point(-FViewPos, 0));
   if (PointInRect(RelPoint, vRect)) then
    begin
     Search:= i;
     Break;
    end;
  end;

 FSelIndex:= Search;
 if (NeedToScroll()) then
  begin
   if (MousePos.X >= Width div 2) then ScrollToRight(FSelIndex)
    else ScrollToLeft(FSelIndex);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.DoUpdate();
begin
 Inc(Ticks);
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.DrawSelector(const vRect: TRect; vFont: TAsphyreFont);
var
 sLeft, sRight: Integer;
 TextBefore: string;
 TextAfter : string;
 SelRect   : TRect;
begin
 // (1) Extract part of text prior to selector
 TextBefore:= '';
 TextAfter := '';
 if (FSelIndex > 0) then TextBefore:= Copy(FText, 1, FSelIndex);
 if (FSelIndex >= 0) then TextAfter := Copy(FText, 1, FSelIndex + 1);

 // (2) Determine selector position
 sLeft := 2 + Round(vFont.TextWidth(TextBefore)) - FViewPos;
 if (TextAfter <> '')and(FSelIndex < Length(FText)) then
  sRight:= 2 + Round(vFont.TextWidth(TextAfter) - vFont.Interleave) - FViewPos
   else sRight:= sLeft + (Height div 2);

 // (3) Determine selector rectangle
 SelRect.Left  := sLeft + vRect.Left;
 SelRect.Right := sRight + vRect.Left;
 SelRect.Top   := FTextAdjust + vRect.Top + 2;
 SelRect.Bottom:= FTextAdjust + vRect.Bottom - 2;

 // (4) Cut selector rectangle with visible rectangle
 SelRect:= ShortRect(SelRect, vRect);

 // (5) Draw selector, if it is visible
 if (SelRect.Right > SelRect.Left)and(SelRect.Bottom > SelRect.Top) then
  begin
   if (FBlinkTicks = 0)or((Ticks div FBlinkTicks) and $01 = 0) then
   guiCanvas.FillQuad(pRect4(SelRect), FSelector.Color4, fxBlend);
  end; 
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.DoPaint();
var
 PaintRect: TRect;
 TextRect : TRect;
 vFont    : TAsphyreFont;
 TextTop  : Integer;
 PrevRect : TRect;
 SrcFont  : TGuiFont;
begin
 // retreive drawing rectangle
 PaintRect:= VirtualRect;

 // control background
 if (Bkgrnd.Visible) then
  guiCanvas.FillQuad(pRect4(PaintRect), Bkgrnd.Color4, DrawFx);

 // text output
 SrcFont:= Font;
 if (not Enabled) then SrcFont:= DisabledFont;

 vFont:= SrcFont.Setup();
 if (vFont <> nil) then
  begin
   TextRect:= ShortRect(ShrinkRect(PaintRect, 2, 2), VisibleRect);
   if (TextRect.Right > TextRect.Left)and(TextRect.Bottom > TextRect.Top) then
    begin
     PrevRect:= guiCanvas.ClipRect;
     guiCanvas.ClipRect:= TextRect;
     // -> vertical position
     TextTop:= Round(vFont.TextHeight(FText));
     if (TextTop > 0) then
      TextTop:= ((PaintRect.Bottom - PaintRect.Top) - TextTop) div 2;

     SrcFont.TextOut(FText, PaintRect.Left + 2 - FViewPos, PaintRect.Top +
      TextTop + FTextAdjust);
     guiCanvas.ClipRect:= PrevRect;

     if (Focused)and(not guiDesign)and(Enabled) then
      DrawSelector(PaintRect, vFont);
    end;
  end;

 if (Bkgrnd.Visible) then
  guiCanvas.Quad(RectExtrude(PaintRect), ExchangeColors(Bkgrnd.Color4), DrawFx);

 // control border
 if (Border.Visible) then
  guiCanvas.Quad(pRect4(PaintRect), Border.Color4, DrawFx);
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.StripWrong(var Text: string);
var
 i: Integer;
begin
 Text:= Trim(Text);

 for i:= Length(Text) downto 1 do
  if (not (Text[i] in TextChars)) then Delete(Text, i, 1);
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.DoKeyEvent(Key: Integer; Event: TKeyEventType;
 Shift: TShiftState);
var
 Ch: Char;
 Clipboard: TClipboard;
 AddTx: string;
begin
 if (Event = kbdDown) then
  begin
   case Key of
    VK_RIGHT:
     begin
      if (FSelIndex < Length(FText)) then Inc(FSelIndex);
      if (NeedToScroll()) then ScrollToRight(FSelIndex);
     end;
    VK_LEFT:
     begin
      if (FSelIndex > 0) then Dec(FSelIndex);
      if (NeedToScroll()) then ScrollToLeft(FSelIndex);
     end;
    VK_BACK:
     if (not FReadOnly) then
      begin
       Delete(FText, FSelIndex, 1);

       if (FSelIndex > 0) then Dec(FSelIndex);
       if (NeedToScroll()) then ScrollToRight(FSelIndex);

       if (Assigned(FOnChange)) then FOnChange(Self);
      end;
    VK_DELETE:
     if (not FReadOnly) then
      begin
       Delete(FText, FSelIndex + 1, 1);
       if (Assigned(FOnChange)) then FOnChange(Self);
      end;

    VK_HOME:
     begin
      FSelIndex:= 0;
      if (NeedToScroll()) then ScrollToLeft(FSelIndex);
     end;

    VK_END:
     begin
      FSelIndex:= Length(FText);
      if (NeedToScroll()) then ScrollToRight(FSelIndex);
     end;
   end;

   if (Key = Byte('V'))and(ssCtrl in Shift)and(not FReadOnly) then
    begin
     Clipboard:= TClipboard.Create();

     AddTx:= Clipboard.AsText;
     StripWrong(AddTx);

     Insert(AddTx, FText, FSelIndex + 1);
     Inc(FSelIndex, Length(AddTx));

     if (FMaxLength > 0)and(Length(FText) > FMaxLength) then
      begin
       FText:= Copy(FText, 1, FMaxLength);
       if (FSelIndex > Length(FText)) then FSelIndex:= Length(FText);
      end;

     if (NeedToScroll()) then ScrollToRight(FSelIndex);

     Clipboard.Free();

     if (Assigned(FOnChange)) then FOnChange(Self);
    end;

   Exit;
  end else if (Event <> kbdPress)or(FReadOnly) then Exit;

 Ch:= Char(Key);

 if (Ch in TextChars)and((FMaxLength < 1)or(Length(FText) < FMaxLength)) then
  begin
   if (FText = '')or(FSelIndex >= Length(FText)) then FText:= FText + Ch
    else Insert(Ch, FText, FSelIndex + 1);

   Inc(FSelIndex);
   if (NeedToScroll()) then ScrollToRight(FSelIndex);

   if (Assigned(FOnChange)) then FOnChange(Self);
  end;

 if (Ch = #9) then
  FocusNextTabOrder();
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.SetText(const Value: string);
var
 Changed: Boolean;
begin
 Changed:= (Value <> FText);
 FText:= Value;

 if (FMaxLength > 0)and(Length(FText) > FMaxLength) then
  FText:= Copy(FText, 1, FMaxLength);

 FSelIndex:= Length(FText);
 if (NeedToScroll()) then ScrollToRight(FSelIndex);

 if (Changed)and(Assigned(OnChange)) then OnChange(Self);
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.SetMaxLength(const Value: Integer);
begin
 FMaxLength:= Value;

 if (FMaxLength > 0)and(Length(FText) > FMaxLength) then
  begin
   FText:= Copy(FText, 1, FMaxLength);
   if (FSelIndex > Length(FText)) then FSelIndex:= Length(FText);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.DoMouseEvent(const MousePos: TPoint;
 Event: TMouseEventType; Button: TMouseButtonType; Shift: TShiftState);
begin
 if (Event = mseDown)and(Button = btnLeft) then SelectChar(MousePos);
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.SetTabOrder(const Value: Integer);
var
 i: Integer;
begin
 FTabOrder:= Value;

 if (Owner <> nil) then
  for i:= Owner.ControlCount - 1 downto 0 do
   if (Owner[i] <> Self)and(Owner[i] is TGuiEdit)and
    (TGuiEdit(Owner[i]).TabOrder = FTabOrder) then
    TGuiEdit(Owner[i]).TabOrder:= FTabOrder + 1;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.PutLastTabOrder();
var
 i: Integer;
begin
 FTabOrder:= 0;

 if (Owner <> nil) then
  for i:= 0 to Owner.ControlCount - 1 do
   if (Owner[i] <> Self)and(Owner[i] is TGuiEdit)and
    (TGuiEdit(Owner[i]).TabOrder >= FTabOrder) then
    FTabOrder:= TGuiEdit(Owner[i]).TabOrder + 1;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.FocusNextTabOrder();
var
 i: Integer;
 BestCtrl : TGuiControl;
 BestDelta: Integer;
 TestDelta: Integer;
begin
 if (Owner = nil) then Exit;

 // (1) Find next control to be selected.
 BestCtrl := nil;
 BestDelta:= High(Integer);
 for i:= 0 to Owner.ControlCount - 1 do
  if (Owner[i] <> Self)and(Owner[i] is TGuiEdit) then
   begin
    TestDelta:= TGuiEdit(Owner[i]).TabOrder - FTabOrder;
    if (TestDelta > 0)and(TestDelta < BestDelta) then
     begin
      BestCtrl := Owner[i];
      BestDelta:= TestDelta;
     end;
   end;

 // (2) If no control was found (we are the last?), look for the first control.
 if (BestCtrl = nil) then
  begin
   BestDelta:= High(Integer);
   for i:= 0 to Owner.ControlCount - 1 do
    if (Owner[i] is TGuiEdit)and(TGuiEdit(Owner[i]).TabOrder < BestDelta) then
     begin
      BestCtrl := Owner[i];
      BestDelta:= TGuiEdit(Owner[i]).TabOrder;
     end; 
  end;

 // (3) If a new control was found, let it have the focus.
 if (BestCtrl <> nil) then BestCtrl.SetFocus(); 
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.SelfDescribe();
begin
 inherited;
 
 FNameOfClass:= 'TGuiEdit';
 FDescOfClass:= 'TGuiEdit is a simple box with editable text.';

 DescribeDefault('bkgrnd');
 DescribeDefault('border');
 DescribeDefault('font');
 DescribeDefault('disabledfont');

 IncludeProp('Text',         ptString,  $A000, 'The initial text');
 IncludeProp('ReadOnly',     ptBoolean, $A001, 'Whether the text can be edited by user');
 IncludeProp('TextAdjust',   ptInteger, $A002, 'The vertical adjustment of visible text');
 IncludeProp('BlinkTicks',   ptInteger, $A003, 'The interval at which the selector blinks');
 IncludeProp('Selector',     ptFill,    $A004, 'The visible style of text selector');
 IncludeProp('MaxLength',    ptInteger, $A005, 'The maximum length of editable text');
 IncludeProp('TabOrder',     ptInteger, $A006, 'The order in which this control is selected by TAB key');
end;

//---------------------------------------------------------------------------
function TGuiEdit.ReadProp(Tag: Integer): Variant;
begin
 case Tag of
  $A000: Result:= FText;
  $A001: Result:= FReadOnly;
  $A002: Result:= FTextAdjust;
  $A003: Result:= FBlinkTicks;
  $A005: Result:= FMaxLength;
  $A006: Result:= FTabOrder;
  else Result:= inherited ReadProp(Tag);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.WriteProp(Tag: Integer; const Value: Variant);
begin
 case Tag of
  $A000: Text      := Value;
  $A001: ReadOnly  := Value;
  $A002: TextAdjust:= Value;
  $A003: BlinkTicks:= Value;
  $A005: MaxLength := Value;
  $A006: TabOrder  := Value;
  else inherited WriteProp(Tag, Value);
 end;
end;

//---------------------------------------------------------------------------
function TGuiEdit.ReadPropFill(Tag: Integer): TGuiFill;
begin
 case Tag of
  $A004: Result:= FSelector;
  else Result:= inherited ReadPropFill(Tag);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiEdit.WritePropFill(Tag: Integer; Value: TGuiFill);
begin
 case Tag of
  $A004: FSelector.Assign(Value);
  else inherited WritePropFill(Tag, Value);
 end;
end;

//---------------------------------------------------------------------------
end.

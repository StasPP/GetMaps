unit GuiCheckBox;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, AsphyreDef, AsphyreFonts, GuiTypes, GuiControls,
 TypesEx;

//---------------------------------------------------------------------------
type
 TGuiCheckBox = class(TGuiControl)
 private
  FCheckColor: Cardinal;
  FTextAdjust: Integer;
  ClickedOver: Boolean;
  FHorizSpace: Integer;
  FChecked: Boolean;
  FCaption: string;
  FOnChange: TNotifyEvent;

  procedure DrawChecked(const Rect: TRect);
  procedure SetChecked(const Value: Boolean);
 protected
  procedure DoPaint(); override;
  procedure DoMouseEvent(const MousePos: TPoint; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TShiftState); override;
  procedure SelfDescribe(); override;
  function ReadProp(Tag: Integer): Variant; override;
  procedure WriteProp(Tag: Integer; const Value: Variant); override;
 public
  property CheckColor: Cardinal read FCheckColor write FCheckColor;
  property TextAdjust: Integer read FTextAdjust write FTextAdjust;
  property HorizSpace: Integer read FHorizSpace write FHorizSpace;
  property Checked : Boolean read FChecked write SetChecked;
  property Caption : string read FCaption write FCaption;
  property OnChange: TNotifyEvent read FOnChange write FOnChange;

  property Font;
  property Border;
  property Bkgrnd;
  property Selected;
  property DisabledFont;

  property OnClick;
  property OnDblClick;
  property OnKey;
  property OnMouse;
  property OnMouseEnter;
  property OnMouseLeave;

  constructor Create(AOwner: TGuiControl); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TGuiCheckBox.Create(AOwner: TGuiControl);
begin
 inherited;

 Bkgrnd.Color4 := cColor4($FFFFFFFF, $FFFCFCFC, $FFDEE5E6, $FFE6EBEC);
 Bkgrnd.Visible:= True;

 Border.Color1($FFB99D7F);
 Border.Visible:= True;

 Selected.Color4 := cColor4($80FFCFDE, $80FB6399, $80F8307D, $80FB6395);
 Selected.Visible:= True;

 Font.Color0:= $FFC56A31;
 Font.Color1:= $FFC56A31;

 FCheckColor:= $FFBD4F62;
 FTextAdjust:= 0;
 ClickedOver:= False;

 FChecked:= True;
 FCaption:= 'TGuiCheckBox';
 FHorizSpace:= 0;

 Width := 100;
 Height:= 15;
end;

//---------------------------------------------------------------------------
destructor TGuiCheckBox.Destroy();
begin

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiCheckBox.DrawChecked(const Rect: TRect);
var
 i, j: Integer;
 aWidth, aHeight, WidthLine, Aux: Integer;
begin
 aWidth := Rect.Right - Rect.Left;
 aHeight:= Rect.Bottom - Rect.Top;
 WidthLine:= 2;

 // draw first part of checked
 Aux:= aHeight - 1;
 for i:= 0 to (aWidth div 3) - 1 do
  begin
   for j:= 0 to WidthLine do
    guiCanvas.PutPixel(Rect.Left - i + 1, Rect.Top + Aux - j - 1, FCheckColor, DrawFx);

   Dec(Aux);
   if (Aux < WidthLine) then Break;
  end;

 // draw second part of checked
 Aux:= aHeight - 1;
 for i:= (aWidth div 3) - 1 to aWidth do
  begin
   for j:= 0 to WidthLine do
    guiCanvas.PutPixel(Rect.Left + i + 1, Rect.Top + Aux - j, FCheckColor, DrawFx);

   Dec(Aux);
   if (Aux < WidthLine) then Break;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiCheckBox.DoPaint();
var
 PaintRect: TRect;
 CheckTop : Integer;
 CheckRect: TRect;
 TextLeft : Integer;
 TextTop  : Integer;
 vFont    : TAsphyreFont;
 BlendOp  : Cardinal;
 SrcFont  : TGuiFont;
begin
 PaintRect:= VirtualRect;

 CheckTop:= ((PaintRect.Bottom - PaintRect.Top) - 13) div 2;
 CheckRect:= Bounds(PaintRect.Left + CheckTop, PaintRect.Top + CheckTop, 13, 13);

 if (Bkgrnd.Visible) then
  if (not ClickedOver) then
   guiCanvas.FillQuad(pRect4(CheckRect), Bkgrnd.Color4, DrawFx)
    else guiCanvas.FillQuad(pRect4(CheckRect), ExchangeColors(Bkgrnd.Color4),
     DrawFx);

 if (Border.Visible) then
  guiCanvas.Quad(pRect4(CheckRect), Border.Color4, DrawFx);

 if (FChecked) then
  DrawChecked(Bounds(PaintRect.Left + 3 + CheckTop, PaintRect.Top + 3 +
   CheckTop, 7, 7));

 if (ClickedOver)and(Selected.Visible)and(not guiDesign) then
  begin
   BlendOp:= DrawFx;
   if (BlendOp = fxNone) then BlendOp:= fxBlend;
   guiCanvas.Quad(pRect4(ShrinkRect(CheckRect, 1, 1)), Selected.Color4, BlendOp);
   guiCanvas.Quad(pRect4(ShrinkRect(CheckRect, 2, 2)), Selected.Color4, BlendOp);
  end;

 TextLeft:= PaintRect.Left + CheckTop + 15 + FHorizSpace;

 SrcFont:= Font;
 if (not Enabled) then SrcFont:= DisabledFont;

 vFont:= SrcFont.Setup();
 if (vFont <> nil) then
  begin
   TextTop:= Round((PaintRect.Top + PaintRect.Bottom -
    vFont.TextHeight(FCaption)) / 2) + FTextAdjust;
   SrcFont.TextOut(FCaption, TextLeft, TextTop);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiCheckBox.DoMouseEvent(const MousePos: TPoint;
 Event: TMouseEventType; Button: TMouseButtonType; Shift: TShiftState);
begin
 if (Event = mseDown)and(Button = btnLeft)and(PointInRect(MousePos,
  VirtualRect)) then ClickedOver:= True;
 if (Event = mseUp)and(Button = btnLeft)and(ClickedOver) then
  begin
   ClickedOver:= False;
   if (PointInRect(MousePos, VirtualRect)) then Checked:= not Checked;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiCheckBox.SetChecked(const Value: Boolean);
var
 Changed: Boolean;
begin
 Changed := (FChecked <> Value);
 FChecked:= Value;
 if (Changed)and(Assigned(FOnChange)) then FOnChange(Self);
end;

//---------------------------------------------------------------------------
procedure TGuiCheckBox.SelfDescribe();
begin
 inherited;

 FNameOfClass:= 'TGuiCheckBox';
 FDescOfClass:= 'This component represents a simple checkable box';

 DescribeDefault('bkgrnd');
 DescribeDefault('border');
 DescribeDefault('selected');
 DescribeDefault('font');
 DescribeDefault('disabledfont');

 IncludeProp('Checked',      ptBoolean,   $A000, 'Whether this box is checked or not');
 IncludeProp('Caption',      ptString,    $A001, 'The caption for this check button');
 IncludeProp('TextAdjust',   ptInteger,   $A002, 'The vertical adjustment of visible caption');
 IncludeProp('CheckColor',   ptColor,     $A003, 'The color of inner circle for checked state');
 IncludeProp('HorizSpace',   ptInteger,   $A004, 'The horizontal space between check box and caption text');
end;

//---------------------------------------------------------------------------
function TGuiCheckBox.ReadProp(Tag: Integer): Variant;
begin
 case Tag of
  $A000: Result:= FChecked;
  $A001: Result:= FCaption;
  $A002: Result:= FTextAdjust;
  $A003: Result:= FCheckColor;
  $A004: Result:= FHorizSpace;
  else Result:= inherited ReadProp(Tag);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiCheckBox.WriteProp(Tag: Integer; const Value: Variant);
begin
 case Tag of
  $A000: Checked    := Value;
  $A001: Caption    := Value;
  $A002: TextAdjust := Value;
  $A003: CheckColor := Value;
  $A004: HorizSpace := Value;
  else inherited WriteProp(Tag, Value);
 end;
end;

//---------------------------------------------------------------------------
end.

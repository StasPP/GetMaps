unit GuiRadioButton;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, AsphyreDef, AsphyreFonts, GuiTypes, GuiControls;

//---------------------------------------------------------------------------
type
 TGuiRadioButton = class(TGuiControl)
 private
  FCheckColor : Cardinal;
  FBorderColor: Cardinal;
  FOverColor  : Cardinal;
  FTextAdjust : Integer;
  FHorizSpace : Integer;
  FGroupIndex : Integer;
  ClickedOver : Boolean;
  FChecked: Boolean;
  FCaption: string;
  FOnChange: TNotifyEvent;

  procedure UncheckOthers();
  procedure SetChecked(const Value: Boolean);
 protected
  procedure DoPaint(); override;
  procedure DoMouseEvent(const MousePos: TPoint; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TShiftState); override;
  procedure SelfDescribe(); override;
  function ReadProp(Tag: Integer): Variant; override;
  procedure WriteProp(Tag: Integer; const Value: Variant); override;
 public
  property Checked: Boolean read FChecked write SetChecked;
  property Caption: string read FCaption write FCaption;
  property BorderColor: Cardinal read FBorderColor write FBorderColor;
  property CheckColor : Cardinal read FCheckColor write FCheckColor;
  property TextAdjust : Integer read FTextAdjust write FTextAdjust;
  property HorizSpace : Integer read FHorizSpace write FHorizSpace;
  property GroupIndex : Integer read FGroupIndex write FGroupIndex;
  property OverColor  : Cardinal read FOverColor write FOverColor;
  property OnChange   : TNotifyEvent read FOnChange write FOnChange;

  property Bkgrnd;
  property Font;
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
constructor TGuiRadioButton.Create(AOwner: TGuiControl);
begin
 inherited;

 FCheckColor := $FFD82F3A;
 FBorderColor:= $FFB99D7F;
 FOverColor  := $80FC97B2;

 Bkgrnd.Color4 := cColor4($FFFFFFFF, $FFFCFCFC, $FFDEE5E6, $FFE6EBEC);
 Bkgrnd.Visible:= True;

 DrawFx:= fxBlend;
 FChecked:= False;

 Font.Color0:= $FFC56A31;
 Font.Color1:= $FFC56A31;

 FTextAdjust:= 0;
 FHorizSpace:= 2;
 FGroupIndex:= 0;

 FCaption:= 'TGuiRadioButton';
 Width := 120;
 Height:= 15;

 ClickedOver:= False;
end;

//---------------------------------------------------------------------------
destructor TGuiRadioButton.Destroy();
begin

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiRadioButton.DoPaint();
var
 PaintRect: TRect;
 Diameter : Integer;
 Middle : TPoint;
 Radius : Integer;
 vFont  : TAsphyreFont;
 TexTop : Integer;
 SrcFont: TGuiFont;
begin
 PaintRect:= VirtualRect;

 Diameter:= (PaintRect.Bottom - PaintRect.Top) - 2;
 Radius  := Diameter div 2;
 Middle.X:= PaintRect.Left + 1 + Radius;
 Middle.Y:= PaintRect.Top + 1 + Radius;

 if (Bkgrnd.Visible) then
  begin
   if (not ClickedOver) then
    guiCanvas.FillCircle(Middle.X, Middle.Y, Radius, Bkgrnd.Color4, DrawFx)
     else guiCanvas.FillCircle(Middle.X, Middle.Y, Radius,
      ExchangeColors(Bkgrnd.Color4), DrawFx);
  end; 

 guiCanvas.SmoothCircle(Middle.X, Middle.Y, Radius, FBorderColor, DrawFx);
 guiCanvas.SmoothCircle(Middle.X, Middle.Y, Radius - 0.15, FBorderColor, DrawFx);

 if (ClickedOver)and(not FChecked) then
  begin
   guiCanvas.SmoothCircle(Middle.X, Middle.Y, Radius * 0.8,
    FOverColor, DrawFx);
   guiCanvas.SmoothCircle(Middle.X, Middle.Y, (Radius * 0.8) - 0.5,
    FOverColor, DrawFx);
   guiCanvas.SmoothCircle(Middle.X, Middle.Y, (Radius * 0.8) - 1.0,
    FOverColor, DrawFx);
   guiCanvas.SmoothCircle(Middle.X, Middle.Y, (Radius * 0.8) - 1.5,
    FOverColor, DrawFx);
  end;

 if (FChecked) then
  begin
   guiCanvas.FillCircle(Middle.X, Middle.Y, Radius div 3, FCheckColor, DrawFx);
   guiCanvas.SmoothCircle(Middle.X, Middle.Y, Radius div 3, FCheckColor, DrawFx);
  end;

 SrcFont:= Font;
 if (not Enabled) then SrcFont:= DisabledFont;

 vFont:= SrcFont.Setup();
 if (vFont <> nil) then
  begin
   TexTop:= Round(((PaintRect.Bottom - PaintRect.Top) -
    vFont.TextHeight(FCaption)) / 2) + FTextAdjust;

   SrcFont.TextOut(FCaption, PaintRect.Left + Diameter + 2 + FHorizSpace,
    PaintRect.Top + TexTop);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiRadioButton.UncheckOthers();
var
 i: Integer;
begin
 if (Owner = nil) then Exit;

 for i:= 0 to Owner.ControlCount - 1 do
  if (Owner[i] <> Self)and(Owner[i] is TGuiRadioButton)and
   (TGuiRadioButton(Owner[i]).GroupIndex = FGroupIndex) then
   TGuiRadioButton(Owner[i]).Checked:= False;
end;

//---------------------------------------------------------------------------
procedure TGuiRadioButton.SetChecked(const Value: Boolean);
var
 Changed: Boolean;
begin
 Changed := (FChecked <> Value);
 FChecked:= Value;
 if (FChecked) then UncheckOthers();
 if (Changed)and(Assigned(FOnChange)) then FOnChange(Self);
end;

//---------------------------------------------------------------------------
procedure TGuiRadioButton.DoMouseEvent(const MousePos: TPoint;
 Event: TMouseEventType; Button: TMouseButtonType; Shift: TShiftState);
begin
 if (Event = mseDown)and(Button = btnLeft)and(PointInRect(MousePos,
  VirtualRect)) then ClickedOver:= True;
 if (Event = mseUp)and(Button = btnLeft)and(ClickedOver) then
  begin
   ClickedOver:= False;
   Checked:= Checked or (PointInRect(MousePos, VirtualRect));
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiRadioButton.SelfDescribe();
begin
 inherited;

 FNameOfClass:= 'TGuiRadioButton';
 FDescOfClass:= 'This component represents a simple radio button';

 DescribeDefault('bkgrnd');
 DescribeDefault('font');
 DescribeDefault('disabledfont');

 IncludeProp('Checked',      ptBoolean,   $A000, 'Whether the radio button is checked or not');
 IncludeProp('Caption',      ptString,    $A001, 'The caption for this radio button');
 IncludeProp('TextAdjust',   ptInteger,   $A002, 'The vertical adjustment of visible caption');
 IncludeProp('BorderColor',  ptColor,     $A003, 'The color of radio button''s outer border');
 IncludeProp('CheckColor',   ptColor,     $A004, 'The color of inner circle for checked state');
 IncludeProp('OverColor',    ptColor,     $A005, 'The color of inner circle for pressed button');
 IncludeProp('HorizSpace',   ptInteger,   $A006, 'The horizontal space between outer circe and caption text');
 IncludeProp('GroupIndex',   ptInteger,   $A007, 'The group to which this button belongs');
end;

//---------------------------------------------------------------------------
function TGuiRadioButton.ReadProp(Tag: Integer): Variant;
begin
 case Tag of
  $A000: Result:= FChecked;
  $A001: Result:= FCaption;
  $A002: Result:= FTextAdjust;
  $A003: Result:= FBorderColor;
  $A004: Result:= FCheckColor;
  $A005: Result:= FOverColor;
  $A006: Result:= FHorizSpace;
  $A007: Result:= FGroupIndex;
  else Result:= inherited ReadProp(Tag);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiRadioButton.WriteProp(Tag: Integer; const Value: Variant);
begin
 case Tag of
  $A000: Checked    := Value;
  $A001: Caption    := Value;
  $A002: TextAdjust := Value;
  $A003: BorderColor:= Value;
  $A004: CheckColor := Value;
  $A005: OverColor  := Value;
  $A006: HorizSpace := Value;
  $A007: GroupIndex := Value;
  else inherited WriteProp(Tag, Value);
 end;
end;

//---------------------------------------------------------------------------
end.

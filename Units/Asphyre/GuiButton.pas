unit GuiButton;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, AsphyreDef, AsphyreFonts, GuiTypes, GuiControls,
 TypesEx, Math;

//---------------------------------------------------------------------------
type
 TGuiButton = class(TGuiControl)
 private
  FOutFill: TGuiFill;
  FCaption: string;
  ClickedOver: Boolean;
  FImageIndex: Integer;
  FDisabledGlyph: Integer;
  FClickedGlyph : Integer;
  FNormalGlyph  : Integer;
  FGlyphWidth   : Integer;
  FGlyphHeight  : Integer;
  FGlyphPosition: TGlyphPosition;
  FGlyphSpacer  : Integer;

 protected
  procedure DoPaint(); override;
  procedure DoMouseEvent(const MousePos: TPoint; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TShiftState); override;
  procedure SelfDescribe(); override;
  function ReadProp(Tag: Integer): Variant; override;
  procedure WriteProp(Tag: Integer; const Value: Variant); override;
  function ReadPropFill(Tag: Integer): TGuiFill; override;
  procedure WritePropFill(Tag: Integer; Value: TGuiFill); override;
 public
  property Caption: string read FCaption write FCaption;
  property OutFill: TGuiFill read FOutFill;
  property ImageIndex: Integer read FImageIndex write FImageIndex;
  property NormalGlyph  : Integer read FNormalGlyph write FNormalGlyph;
  property DisabledGlyph: Integer read FDisabledGlyph write FDisabledGlyph;
  property ClickedGlyph : Integer read FClickedGlyph write FClickedGlyph;
  property GlyphPosition: TGlyphPosition read FGlyphPosition write FGlyphPosition;
  property GlyphSpacer  : Integer read FGlyphSpacer write FGlyphSpacer;

  property GlyphWidth : Integer read FGlyphWidth write FGlyphWidth;
  property GlyphHeight: Integer read FGlyphHeight write FGlyphHeight;

  property Font;
  property DisabledFont;
  property Bkgrnd;
  property Border;

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
constructor TGuiButton.Create(AOwner: TGuiControl);
begin
 inherited;

 FOutFill:= TGuiFill.Create();

 FOutFill.Visible:= True;
 FOutFill.Color4 := cColor4($FFF6DBD0, $FFF7DFD6, $FFFCF1ED, $FFF7DFD6);

 Bkgrnd.Color4 := cColor4($FFFCFCFC, $FFFBFCFC, $FFE1E8E9, $FFE5EBEB);
 Bkgrnd.Visible:= True;

 Border.Color1($FFB99D7F);
 Border.Visible:= True;

 Font.Color0:= $FFC65D21;
 Font.Color1:= $FFC65D21;

 Font.Color0:= $FFC65D21;
 Font.Color1:= $FFC65D21;

 DisabledFont.Color0:= $FF5F6B70;
 DisabledFont.Color1:= $FF5F6B70;

 ClickedOver := False;
 FImageIndex   := -1;
 FNormalGlyph  := 0;
 FDisabledGlyph:= 1;
 FClickedGlyph := 0;
 FGlyphPosition:= gpLeft;
 FGlyphSpacer  := 4;
 FGlyphWidth   := 18;
 FGlyphHeight  := 18;

 FCaption:= 'Button1';
 Width:= 90;
 Height:= 24;
end;

//---------------------------------------------------------------------------
destructor TGuiButton.Destroy();
begin
 FOutFill.Free();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiButton.DoPaint();
var
 MainRect : TRect;
 PaintRect: TRect;
 TextLeft : Integer;
 BkColor  : TColor4;
 TextTop  : Integer;
 vFont    : TAsphyreFont;
 GlyphLeft: Integer;
 GlyphTop : Integer;
 DataSize : TPoint;
 TextSize : TPoint;
 BlendOp  : Cardinal;
 SrcFont  : TGuiFont;
 Pattern  : Integer;
begin
 PaintRect:= VirtualRect;
 MainRect := PaintRect;
 if (FOutFill.Visible) then
  begin
   guiCanvas.Quad(pRect4(PaintRect), FOutFill.Color4, DrawFx);
   MainRect:= ShrinkRect(PaintRect, 1, 1);
  end;

 if (Bkgrnd.Visible) then
  begin
   BkColor:= Bkgrnd.Color4;
   if (ClickedOver) then BkColor:= ExchangeColors(BkColor);

   guiCanvas.FillQuad(pRect4(MainRect), BkColor, DrawFx);

   guiCanvas.Line(MainRect.Right - 1, MainRect.Top + 1, MainRect.Right - 1,
    MainRect.Bottom - 1, BkColor[2], BkColor[2], DrawFx);
   guiCanvas.Line(MainRect.Left + 1, MainRect.Bottom - 1, MainRect.Right - 1,
    MainRect.Bottom - 1, BkColor[2], BkColor[2], DrawFx);

   guiCanvas.Line(MainRect.Left + 1, MainRect.Top + 1, MainRect.Left + 1,
    MainRect.Bottom - 1, BkColor[0], BkColor[0], DrawFx);
   guiCanvas.Line(MainRect.Left + 1, MainRect.Top + 1, MainRect.Right - 1,
    MainRect.Top + 1, BkColor[0], BkColor[0], DrawFx);
  end;

 if (Border.Visible) then
  guiCanvas.Quad(pRect4(MainRect), Border.Color4, DrawFx);

 SrcFont:= Font;
 if (not Enabled) then SrcFont:= DisabledFont;

 vFont:= SrcFont.Setup();
 if (vFont <> nil) then
  begin
   TextSize.X:= Ceil(vFont.TextWidth(FCaption));
   TextSize.Y:= Ceil(vFont.TextHeight(FCaption));
   DataSize:= TextSize;
   if (FImageIndex <> -1) then
    case FGlyphPosition of
     gpLeft, gpRight:
      DataSize.X:= DataSize.X + FGlyphSpacer + FGlyphWidth;
     gpTop, gpBottom:
      DataSize.Y:= DataSize.Y + FGlyphSpacer + FGlyphHeight;
     end;

   TextLeft := (MainRect.Left + MainRect.Right - DataSize.X) div 2;
   TextTop  := (MainRect.Top + MainRect.Bottom - DataSize.Y) div 2;
   GlyphLeft:= TextLeft;
   GlyphTop := TextTop;

   if (FImageIndex <> -1) then
    case FGlyphPosition of
     gpLeft:
      begin
       Inc(TextLeft, FGlyphSpacer + FGlyphWidth);
       GlyphTop:= (MainRect.Top + MainRect.Bottom - FGlyphHeight) div 2
      end;
     gpTop:
      begin
       Inc(TextTop, FGlyphSpacer + FGlyphHeight);
       GlyphLeft:= (MainRect.Left + MainRect.Right - FGlyphWidth) div 2;
      end;
     gpRight:
      begin
       Inc(GlyphLeft, FGlyphSpacer + TextSize.X);
       GlyphTop:= (MainRect.Top + MainRect.Bottom - FGlyphHeight) div 2
      end;
     gpBottom:
      begin
       Inc(GlyphTop,  FGlyphSpacer + TextSize.Y);
       GlyphLeft:= (MainRect.Left + MainRect.Right - FGlyphWidth) div 2;
      end;
    end;

   Pattern:= FNormalGlyph;
   if (ClickedOver) then
    begin
     Inc(TextLeft);
     Inc(TextTop);
     Inc(GlyphLeft);
     Inc(GlyphTop);
     Pattern:= FClickedGlyph;
    end;
   if (not Enabled) then Pattern:= FDisabledGlyph; 

   BlendOp:= DrawFx;
   if (BlendOp = fxNone) then BlendOp:= fxBlend;

   vFont.TextOut(FCaption, TextLeft, TextTop, SrcFont.Color0, SrcFont.Color1,
    BlendOp);

   if (FImageIndex <> -1)and(guiImages.Count >= FImageIndex) then
    guiCanvas.TexMap(guiImages[FImageIndex], pBounds4(GlyphLeft, GlyphTop,
     FGlyphWidth, FGlyphHeight), clWhite4, tPattern(Pattern), BlendOp);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiButton.DoMouseEvent(const MousePos: TPoint;
 Event: TMouseEventType; Button: TMouseButtonType; Shift: TShiftState);
begin
 if (Event = mseDown)and(Button = btnLeft) then ClickedOver:= True;
 if (Event = mseUp)and(Button = btnLeft) then
  begin
   ClickedOver:= False;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiButton.SelfDescribe();
begin
 inherited;
 
 FNameOfClass:= 'TGuiButton';
 FDescOfClass:= 'This component is a clickable button.';

 DescribeDefault('bkgrnd');
 DescribeDefault('border');
 DescribeDefault('font');
 DescribeDefault('disabledfont');

 IncludeProp('OutFill',      ptFill,    $A000, 'The fill style of outer border');

 IncludeProp('Caption',       ptString,  $A001, 'The caption of the button');
 IncludeProp('ImageIndex',    ptInteger, $A002, 'The index of glyph image');
 IncludeProp('NormalGlyph',   ptInteger, $A003, 'The number of sub-image for normal state');
 IncludeProp('DisabledGlyph', ptInteger, $A004, 'The sub-image number for disabled state');
 IncludeProp('ClickedGlyph',  ptInteger, $A005, 'The sub-image number for clicked glyph');
 IncludeProp('GlyphSpacer',   ptInteger, $A006, 'The space between glyph and the text');
 IncludeProp('GlyphWidth',    ptInteger, $A007, 'The width of button glyph');
 IncludeProp('GlyphHeight',   ptInteger, $A008, 'The height of button glyph');
 IncludeProp('GlyphPosition', ptGlyphPosition, $A009, 'The position of the glyph in relation to text');
end;

//---------------------------------------------------------------------------
function TGuiButton.ReadProp(Tag: Integer): Variant;
begin
 case Tag of
  $A001: Result:= FCaption;
  $A002: Result:= FImageIndex;
  $A003: Result:= FNormalGlyph;
  $A004: Result:= FDisabledGlyph;
  $A005: Result:= FClickedGlyph;
  $A006: Result:= FGlyphSpacer;
  $A007: Result:= FGlyphWidth;
  $A008: Result:= FGlyphHeight;
  $A009: Result:= Integer(FGlyphPosition);
  else Result:= inherited ReadProp(Tag);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiButton.WriteProp(Tag: Integer; const Value: Variant);
begin
 case Tag of
  $A001: Caption      := Value;
  $A002: ImageIndex   := Value;
  $A003: NormalGlyph  := Value;
  $A004: DisabledGlyph:= Value;
  $A005: ClickedGlyph := Value;
  $A006: GlyphSpacer  := Value;
  $A007: GlyphWidth   := Value;
  $A008: GlyphHeight  := Value;
  $A009: GlyphPosition:= TGlyphPosition(Integer(Value));
  else inherited WriteProp(Tag, Value);
 end;
end;

//---------------------------------------------------------------------------
function TGuiButton.ReadPropFill(Tag: Integer): TGuiFill;
begin
 case Tag of
  $A000: Result:= FOutFill;
  else Result:= inherited ReadPropFill(Tag);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiButton.WritePropFill(Tag: Integer; Value: TGuiFill);
begin
 case Tag of
  $A000: FOutFill.Assign(Value);
  else inherited WritePropFill(Tag, Value);
 end;
end;

//---------------------------------------------------------------------------
end.

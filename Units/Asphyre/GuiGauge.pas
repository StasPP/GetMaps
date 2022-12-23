unit GuiGauge;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, AsphyreDef, AsphyreFonts, GuiTypes, GuiControls,
 TypesEx;

//---------------------------------------------------------------------------
type
 TGuiGauge = class(TGuiControl)
 private
  FTheta   : Integer;
  FMinValue: Integer;
  FMaxValue: Integer;
  FShowText: Boolean;
  FCaption : string;
  FAlignment: TGuiTextAlign;

 protected
  procedure DoPaint(); override;
  procedure SelfDescribe(); override;
  function ReadProp(Tag: Integer): Variant; override;
  procedure WriteProp(Tag: Integer; const Value: Variant); override;
 public
  property Theta    : Integer read FTheta write FTheta;
  property MinValue : Integer read FMinValue write FMinValue;
  property MaxValue : Integer read FMaxValue write FMaxValue;
  property ShowText : Boolean read FShowText write FShowText;
  property Caption  : string read FCaption write FCaption;
  property Alignment: TGuiTextAlign read FAlignment write FAlignment;

  property Bkgrnd;
  property Border;
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
constructor TGuiGauge.Create(AOwner: TGuiControl);
begin
 inherited;

 Border.Color1($FFB99D7F);
 Border.Visible:= True;

 Bkgrnd.Color4   := cColor4($FFFFEAD5, $FFFFEAD5, $FFFFFFFF, $FFFFFFFF);
 Bkgrnd.Visible  := True;
 Selected.Color4 := cColor4($FFFFEEDD, $FFFFEEDD, $FFFFAE5E, $FFFFAE5E);
 Selected.Visible:= True;

 Font.Color0:= $FFC56A31;
 Font.Color1:= $FFC56A31;

 FTheta    := 50;
 FMinValue := 0;
 FMaxValue := 100;
 FShowText := True;
 FCaption  := 'Gauge';
 FAlignment:= gtaAlignLeft;

 DisabledFont.Color0:= $FF5F6B70;
 DisabledFont.Color1:= $FF5F6B70;

 Width := 120;
 Height:= 20;
end;

//---------------------------------------------------------------------------
destructor TGuiGauge.Destroy();
begin

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiGauge.DoPaint();
var
 PaintRect: TRect;
 Width, vSize, iLeft, iTop: Integer;
 SelRect: TRect;
 st: string;
 MyFont: TAsphyreFont;
 SrcFont: TGuiFont;
begin
 PaintRect:= VirtualRect;

 if (Bkgrnd.Visible) then
  begin
   guiCanvas.FillQuad(pRect4(PaintRect), Bkgrnd.Color4, DrawFx);
   guiCanvas.Quad(pRect4(ShrinkRect(PaintRect, 1, 1)),
    ExchangeColors(Bkgrnd.Color4), DrawFx);
  end;

 if (Selected.Visible) then
  begin
   Width:= (PaintRect.Right - PaintRect.Left) - 2;
   vSize:= ((FTheta - FMinValue) * Width) div (FMaxValue - FMinValue);

   if (vSize > 0) then
    begin
     SelRect:= Bounds(PaintRect.Left + 1, PaintRect.Top, vSize,
      PaintRect.Bottom - PaintRect.Top);
     guiCanvas.FillQuad(pRect4(SelRect), Selected.Color4, DrawFx);
     guiCanvas.Line(SelRect.Right - 1, SelRect.Top, SelRect.Right - 1, SelRect.Bottom,
      Selected.Colors[2], Selected.Colors[2], DrawFx);
     guiCanvas.Line(SelRect.Left, SelRect.Top, SelRect.Left, SelRect.Bottom,
      Selected.Colors[0], Selected.Colors[0], DrawFx);
    end;
  end;

 if (FShowText) then
  begin
   Width:= PaintRect.Right - PaintRect.Left;
   vSize:= PaintRect.Bottom - PaintRect.Top;
   st:= IntToStr(FTheta);
   if (FCaption <> '') then st:= FCaption + ': ' + st;

   SrcFont:= Font;
   if (not Enabled) then SrcFont:= DisabledFont;

   MyFont:= SrcFont.Setup();
   if (MyFont <> nil) then
    begin
     iLeft:= PaintRect.Left + 5;
     if (FAlignment = gtaCenter) then
      iLeft:= PaintRect.Left + ((Width - Round(MyFont.TextWidth(st))) div 2);
     if (FAlignment = gtaAlignRight) then
      iLeft:= PaintRect.Right - Round(MyFont.TextWidth(st)) - 5;

     iTop := PaintRect.Top + ((vSize - Round(MyFont.TextHeight(st))) div 2);

     MyFont.TextOut(st, iLeft, iTop, SrcFont.Color0, SrcFont.Color1, fxBlend);
    end;
  end;

 if (Border.Visible) then
  guiCanvas.Quad(pRect4(PaintRect), Border.Color4, DrawFx);
end;

//---------------------------------------------------------------------------
procedure TGuiGauge.SelfDescribe();
begin
 inherited;
 
 FNameOfClass:= 'TGuiGauge';
 FDescOfClass:= 'This component is a simple progress bar';

 DescribeDefault('bkgrnd');
 DescribeDefault('border');
 DescribeDefault('selected');
 DescribeDefault('font');
 DescribeDefault('disabledfont');

 IncludeProp('Caption',   ptString,    $A000, 'The caption of gauge');
 IncludeProp('Theta',     ptInteger,   $A001, 'The current position of gauge');
 IncludeProp('MinValue',  ptInteger,   $A002, 'The minimal allowed value for the gauge');
 IncludeProp('MaxValue',  ptInteger,   $A003, 'The maximum allowed value for the gauge');
 IncludeProp('ShowText',  ptBoolean,   $A004, 'The visible style of text selector');
 IncludeProp('Alignment', ptAlignment, $A005, 'The alignment of gauge''s caption');
end;

//---------------------------------------------------------------------------
function TGuiGauge.ReadProp(Tag: Integer): Variant;
begin
 case Tag of
  $A000: Result:= FCaption;
  $A001: Result:= FTheta;
  $A002: Result:= FMinValue;
  $A003: Result:= FMaxValue;
  $A004: Result:= FShowText;
  $A005: Result:= Integer(FAlignment);
  else Result:= inherited ReadProp(Tag);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiGauge.WriteProp(Tag: Integer; const Value: Variant);
begin
 case Tag of
  $A000: Caption  := Value;
  $A001: Theta    := Value;
  $A002: MinValue := Value;
  $A003: MaxValue := Value;
  $A004: ShowText := Value;
  $A005: Alignment:= TGuiTextAlign(Integer(Value));
  else inherited WriteProp(Tag, Value);
 end;
end;

//---------------------------------------------------------------------------
end.

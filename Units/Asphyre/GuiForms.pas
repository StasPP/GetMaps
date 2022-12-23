unit GuiForms;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, Controls, AsphyreDef, AsphyreFonts, GuiTypes,
 GuiControls;

//---------------------------------------------------------------------------
type
 TGuiForm = class(TGuiControl)
 private
  FCaptSize    : Integer;
  FCaption     : string;
  FCaptActive  : TGuiFill;
  FCaptUnactive: TGuiFill;
  FIconFill    : TGuiFill;
  FIconIndex   : Integer;
  FIconPattern : Integer;
  FIconWidth   : Integer;
  FIconHeight  : Integer;
  FCaptAdjust  : Integer;
  FFontActive  : TGuiFont;
  FFontUnactive: TGuiFont;
  DragClick    : TPoint;
  DragInit     : TPoint;
  Dragging     : Boolean;
  FShadowSize  : Integer;
  FShadowColor : Cardinal;
  FImageIndex  : Integer;
  FImagePattern: Integer;
 protected
  procedure DoMouseEvent(const MousePos: TPoint; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TShiftState); override;
  procedure DoPaint(); override;

  procedure SelfDescribe(); override;
  function ReadProp(Tag: Integer): Variant; override;
  procedure WriteProp(Tag: Integer; const Value: Variant); override;
  function ReadPropFill(Tag: Integer): TGuiFill; override;
  procedure WritePropFill(Tag: Integer; Value: TGuiFill); override;
  function ReadPropFont(Tag: Integer): TGuiFont; override;
  procedure WritePropFont(Tag: Integer; Value: TGuiFont); override;
 public
  property CaptSize: Integer read FCaptSize write FCaptSize;
  property Caption : string read FCaption write FCaption;

  property CaptAdjust  : Integer read FCaptAdjust write FCaptAdjust;
  property CaptActive  : TGuiFill read FCaptActive;
  property CaptUnactive: TGuiFill read FCaptUnactive;
  property FontActive  : TGuiFont read FFontActive;
  property FontUnactive: TGuiFont read FFontUnactive;

  property IconFill    : TGuiFill read FIconFill;
  property IconIndex   : Integer read FIconIndex write FIconIndex;
  property IconPattern : Integer read FIconPattern write FIconPattern;
  property IconWidth   : Integer read FIconWidth write FIconWidth;
  property IconHeight  : Integer read FIconHeight write FIconHeight;

  property ImageIndex  : Integer read FImageIndex write FImageIndex;
  property ImagePattern: Integer read FImagePattern write FImagePattern;

  property ShadowSize  : Integer read FShadowSize write FShadowSize;
  property ShadowColor : Cardinal read FShadowColor write FShadowColor;

  property Bkgrnd;
  property Border;

  procedure SetFocus(); override;

  constructor Create(AOwner: TGuiControl); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TGuiForm.Create(AOwner: TGuiControl);
begin
 inherited;

 FCaptActive  := TGuiFill.Create();
 FCaptUnactive:= TGuiFill.Create();
 FIconFill    := TGuiFill.Create();
 FFontActive  := TGuiFont.Create();
 FFontUnactive:= TGuiFont.Create();

 FCaptActive.Color4  := cColor4($FFFFFFFF, $FFFFFFFF, $FFF7D3C6, $FFF7D3C6);
 FCaptUnactive.Color4:= cColor4($FFE8DFDC, $FFE8DFDC, $FFE0C2B7, $FFE0C2B7);

 FIconFill.Visible:= True;
 FIconFill.Color1($FFE59F79);

 Bkgrnd.Color1($FFf7DFD6);
 Bkgrnd.Visible:= True;
 Border.Color1($FFFFFFFF);
 Border.Visible:= True;

 FFontActive.Color0:= $FFCE5D29;
 FFontActive.Color1:= $FFCE5D29;
 FFontActive.Style := [];

 FFontUnactive.Color0:= $FFB34624;
 FFontUnactive.Color1:= $FFB34624;
 FFontUnactive.Style := [];

 FCaption   := 'TGuiForm';
 FCaptSize  := 20;
 FCaptAdjust:= 0;
 FIconWidth := 12;
 FIconHeight:= 12;

 FShadowSize := 4;
 FShadowColor:= $40000000;

 FIconIndex  := -1;
 FIconpattern:= 0;

 FImageIndex  := -1;
 FImagePattern:= 0;

 Width := 300;
 Height:= 200;

 FCtrlHolder:= True;

 Dragging:= False;
end;

//---------------------------------------------------------------------------
destructor TGuiForm.Destroy();
begin
 FFontUnactive.Free();
 FFontActive.Free();
 FIconFill.Free();
 FCaptUnactive.Free();
 FCaptActive.Free();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiForm.DoPaint();
var
 PaintRect: TRect;
 IconLeft, IconTop, CaptLeft, BlockSize: Integer;
 TopRect, vRect: TRect;
 GuiFont: TGuiFont;
 UsedFont: TAsphyreFont;
 Text: string;
begin
 // retreive drawing rectangle
 PaintRect:= VirtualRect;

 // shorten PaintRect by excluding shadow area
 Dec(PaintRect.Right, FShadowSize);
 Dec(PaintRect.Bottom, FShadowSize);

 // caption rectangle
 TopRect:= Bounds(PaintRect.Left, PaintRect.Top, Width - FShadowSize,
  CaptSize);

 // render caption
 if (FCaptSize > 0) then
  begin
   if (FCaptActive.Visible)and(Focused) then
    GuiCanvas.FillQuad(pRect4(TopRect), FCaptActive.Color4, DrawFx);

   if (FCaptUnactive.Visible)and(not Focused) then
    GuiCanvas.FillQuad(pRect4(TopRect), FCaptUnactive.Color4, DrawFx);

   if (Border.Visible) then
    GuiCanvas.Quad(pRect4(TopRect), Border.Color4, DrawFx);

   IconTop := (FCaptSize - FIconHeight) div 2;
   IconLeft:= IconTop;

   if (FIconFill.Visible)or(FIconIndex <> -1) then
    with GuiCanvas do
     begin
      if (FIconIndex = -1) then
       begin
        FillRect(IconLeft + PaintRect.Left, IconTop + PaintRect.Top,
         FIconWidth, FIconHeight div 3, FIconFill.Colors[0], DrawFx);
        FrameRect(IconLeft + PaintRect.Left, IconTop + PaintRect.Top,
         FIconWidth, FIconHeight, FIconFill.Colors[0], DrawFx);
       end else
       begin
        TexMap(guiImages[FIconIndex], pBounds4(IconLeft + PaintRect.Left,
         IconTop + PaintRect.Top, FIconWidth, FIconHeight), clWhite4,
         tPattern(FIconPattern), DrawFx);
       end;
     end;

   GuiFont:= FFontActive;
   if (not Focused) then GuiFont:= FFontUnactive;
   UsedFont:= GuiFont.Setup();
   if (UsedFont <> nil) then
    begin
     CaptLeft:= (IconLeft * 2) + FIconWidth;
     if (not FIconFill.Visible) then CaptLeft:= 4;

     Text:= FCaption;
     if (UsedFont.TextWidth(Text) > Width - (FShadowSize + CaptLeft)) then
      begin
       while (UsedFont.TextWidth(Text + '...') > Width - (CaptLeft +
        FShadowSize))and(Length(Text) > 0) do Delete(Text, Length(Text), 1);

       Text:= Text + '...';
      end;

     GuiFont.TextOut(Text, CaptLeft + PaintRect.Left, PaintRect.Top +
      FCaptAdjust + (FCaptSize - Round(UsedFont.TextHeight(Text))) div 2);
    end;
  end;

 // render content window
 if (CaptSize > 0) then
  vRect:= Bounds(PaintRect.Left, TopRect.Bottom - 1, Width - FShadowSize,
   (Height - (FCaptSize + FShadowSize)) + 1)
  else vRect:= Bounds(PaintRect.Left, PaintRect.Top, Width - FShadowSize,
   Height - FShadowSize);

 if (Bkgrnd.Visible) then
  guiCanvas.FillQuad(pRect4(vRect), Bkgrnd.Color4, DrawFx);

 if (FImageIndex <> -1)and(guiImages[FImageIndex] <> nil) then
  guiCanvas.TexMap(guiImages[FImageIndex], pRect4(vRect), Bkgrnd.Color4,
   tPattern(FImagePattern), DrawFx);

 if (Border.Visible) then
  guiCanvas.Quad(pRect4(vRect), Border.Color4, DrawFx);

 // display shadow
 if (FShadowSize > 0) then
  begin
   BlockSize:= (PaintRect.Bottom - PaintRect.Top) - FShadowSize;
   guiCanvas.FillQuad(pBounds4(PaintRect.Right, PaintRect.Top + FShadowSize,
    FShadowSize, BlockSize), cColor4(FShadowColor), fxBlend);

   BlockSize:= (PaintRect.Right - PaintRect.Left);
   guiCanvas.FillQuad(pBounds4(PaintRect.Left + FShadowSize, PaintRect.Bottom,
    BlockSize, FShadowSize), cColor4(FShadowColor), fxBlend);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiForm.DoMouseEvent(const MousePos: TPoint;
 Event: TMouseEventType; Button: TMouseButtonType; Shift: TShiftState);
var
 Pt: TPoint;
 Drag: Boolean;
begin
 Pt:= Screen2Local(MousePos);
 Drag:= (Pt.X >= 0)and(Pt.X < Width)and(Pt.Y >= 0)and(Pt.Y < FCaptSize)and
  (Button = btnLeft)and(Event = mseDown);
 if (Drag)and(not Dragging) then
  begin
   DragInit := Point(Left, Top);
   DragClick:= MousePos;
   Dragging := True;
  end;

 if (Dragging)and(Button = btnLeft)and(Event = mseUp) then Dragging:= False;
 if (Dragging)and(Event = mseMove) then
  begin
   Left:= DragInit.X + (MousePos.X - DragClick.X);
   Top := DragInit.Y + (MousePos.Y - DragClick.Y);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiForm.SelfDescribe();
begin
 inherited;
 
 FNameOfClass:= 'TGuiForm';
 FDescOfClass:= 'TGuiForm represents a standard window.';

 DescribeDefault('bkgrnd');
 DescribeDefault('border');

 IncludeProp('Caption',      ptString,  $A000, 'Windows'' caption');
 IncludeProp('CaptSize',     ptInteger, $A001, 'The height of window''s caption');
 IncludeProp('CaptAdjust',   ptInteger, $A002, 'The vertical adjustment of caption text');

 IncludeProp('CaptActive',   ptFill,    $A003, 'The caption''s fill style in focused window');
 IncludeProp('CaptUnactive', ptFill,    $A004, 'The caption''s fill style in non-focused window');

 IncludeProp('FontActive',   ptFont,    $A005, 'The caption''s font style in focused window');
 IncludeProp('FontUnactive', ptFont,    $A006, 'The caption''s font style in non-focused window');

 IncludeProp('IconFill',     ptFill,    $A007, 'The fill style of simple window''s icon');

 IncludeProp('IconIndex',    ptInteger, $A008, 'The index of window''s icon');
 IncludeProp('IconPattern',  ptInteger, $A009, 'The patern number of window''s icon');
 IncludeProp('IconWidth',    ptInteger, $A00A, 'The width of window''s icon in pixels');
 IncludeProp('IconHeight',   ptInteger, $A00B, 'The height of window''s icon in pixels');

 IncludeProp('ImageIndex',   ptInteger, $A00C, 'The image index of window''s background');
 IncludeProp('ImagePattern', ptInteger, $A00D, 'The pattern number of window''s background image');

 IncludeProp('ShadowSize',   ptInteger, $A00E, 'The size of window''s shadow (in pixels)');
 IncludeProp('ShadowColor',  ptColor,   $A00F, 'The color of window''s shadow');
end;

//---------------------------------------------------------------------------
function TGuiForm.ReadProp(Tag: Integer): Variant;
begin
 case Tag of
  $A000: Result:= FCaption;
  $A001: Result:= FCaptSize;
  $A002: Result:= FCaptAdjust;
  $A008: Result:= FIconIndex;
  $A009: Result:= FIconPattern;
  $A00A: Result:= FIconWidth;
  $A00B: Result:= FIconHeight;
  $A00C: Result:= FImageIndex;
  $A00D: Result:= FImagePattern;
  $A00E: Result:= FShadowSize;
  $A00F: Result:= FShadowColor;
  else Result:= inherited ReadProp(Tag);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiForm.WriteProp(Tag: Integer; const Value: Variant);
begin
 case Tag of
  $A000: Caption     := Value;
  $A001: CaptSize    := Value;
  $A002: CaptAdjust  := Value;
  $A008: IconIndex   := Value;
  $A009: IconPattern := Value;
  $A00A: IconWidth   := Value;
  $A00B: IconHeight  := Value;
  $A00C: ImageIndex  := Value;
  $A00D: ImagePattern:= Value;
  $A00E: ShadowSize  := Value;
  $A00F: ShadowColor := Value;
  else inherited WriteProp(Tag, Value);
 end;
end;

//---------------------------------------------------------------------------
function TGuiForm.ReadPropFill(Tag: Integer): TGuiFill;
begin
 case Tag of
  $A003: Result:= FCaptActive;
  $A004: Result:= FCaptUnactive;
  $A007: Result:= FIconFill;
  else Result:= inherited ReadPropFill(Tag);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiForm.WritePropFill(Tag: Integer; Value: TGuiFill);
begin
 case Tag of
  $A003: FCaptActive.Assign(Value);
  $A004: FCaptUnactive.Assign(Value);
  $A007: FIconFill.Assign(Value);
  else inherited WritePropFill(Tag, Value);
 end;
end;

//---------------------------------------------------------------------------
function TGuiForm.ReadPropFont(Tag: Integer): TGuiFont;
begin
 case Tag of
  $A005: Result:= FFontActive;
  $A006: Result:= FFontUnactive;
  else Result:= inherited ReadPropFont(Tag);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiForm.WritePropFont(Tag: Integer; Value: TGuiFont);
begin
 case Tag of
  $A005: FFontActive.Assign(Value);
  $A006: FFontUnactive.Assign(Value);
  else inherited WritePropFont(Tag, Value);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiForm.SetFocus();
begin
 BringToFront();
 
 inherited;
end;

//---------------------------------------------------------------------------
end.

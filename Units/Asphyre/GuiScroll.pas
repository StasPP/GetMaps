unit GuiScroll;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, Math, AsphyreDef, GuiTypes, GuiControls;

//---------------------------------------------------------------------------
type
 TGuiScroll = class(TGuiControl)
 private
  FButton    : TGuiFill;
  FArrowColor: Longword;
  FScroll    : TGuiFill;
  FPressed   : TGuiFill;
  Pressed1   : Boolean;
  Pressed2   : Boolean;
  APressed   : Boolean;
  ClickPos   : TPoint;
  ClickTheta : Real;
  FTheta     : Real;
  FArrowInc  : Real;
  FPageInc   : Real;
  FOnChange  : TNotifyEvent;
  FBorderColor: Cardinal;

  procedure DrawTopArrow(Rect: TRect; Pressed: Boolean);
  procedure DrawBottomArrow(Rect: TRect; Pressed: Boolean);
  procedure DrawAnchor(Rect: TRect; Pressed: Boolean);
 protected
  procedure DoPaint(); override;
  procedure DoMouseEvent(const MousePos: TPoint; Event: TMouseEventType;
   Button: TMouseButtonType; Shift: TShiftState); override;
 public
  property Button  : TGuiFill read FButton;
  property Scroll  : TGuiFill read FScroll;
  property Pressed : TGuiFill read FPressed;
  property ArrowColor: Longword read FArrowColor write FArrowColor;
  property Theta   : Real read FTheta write FTheta;
  property ArrowInc: Real read FArrowInc write FArrowInc;
  property PageInc : Real read FPageInc write FPageInc;
  property OnChange: TNotifyEvent read FOnChange write FOnChange;
  property BorderColor: Cardinal read FBorderColor write FBorderColor;

  property OnMouseEnter;
  property OnMouseLeave;

  constructor Create(AOwner: TGuiControl); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TGuiScroll.Create(AOwner: TGuiControl);
begin
 inherited;

 FButton := TGuiFill.Create();
 FPressed:= TGuiFill.Create();
 FScroll := TGuiFill.Create();

 Width := 16;
 Height:= 100;
 FTheta:= 0.5;

 Pressed1 := False;
 Pressed2 := False;
 APressed := False;
 FArrowInc:= 0.1;
 FPageInc := 0.25;

 FBorderColor:= $FFB99D7F;

 Button.Color4 := cColor4($FFFFFFFF, $FFFCFCFC, $FFE6EBEC, $FFDEE5E6);
 Button.Visible:= True;

 FPressed.Color4 := cColor4($FFDEE5E6, $FFE6EBEC, $FFFFFFFF, $FFFCFCFC);
 FPressed.Visible:= True;

 FScroll.Color1($FFEBBCB3);
 FScroll.Visible:= True;

 FArrowColor:= $FFC56A31;
end;

//---------------------------------------------------------------------------
destructor TGuiScroll.Destroy();
begin
 FScroll.Free();
 FPressed.Free();
 FButton.Free();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiScroll.DrawTopArrow(Rect: TRect; Pressed: Boolean);
var
 bColor: TColor4;
 w1, w2, w3, w6: Integer;
begin
 if (Button.Visible) then
  begin
   bColor:= Button.Color4;
   if (Pressed) then bColor:= FPressed.Color4;

   guiCanvas.FillQuad(pRect4(Rect), bColor, DrawFx);
   guiCanvas.Line(Rect.TopLeft, Point(Rect.Left, Rect.Bottom - 1),
    bColor[0], bColor[0], DrawFx);
   guiCanvas.Line(Rect.TopLeft, Point(Rect.Right - 1, Rect.Top),
    bColor[0], bColor[0], DrawFx);
   guiCanvas.Line(Point(Rect.Left + 1, Rect.Bottom - 1), Point(Rect.Right - 1,
    Rect.Bottom - 1), bColor[2], bColor[2], DrawFx);
   guiCanvas.Line(Point(Rect.Right - 1, Rect.Top + 1), Point(Rect.Right - 1,
    Rect.Bottom - 1), bColor[2], bColor[2], DrawFx);

   if (Pressed) then
    begin
     Inc(Rect.Left);
     Inc(Rect.Top);
     Inc(Rect.Right);
     Inc(Rect.Bottom);
    end;

   w1:= Rect.Right - Rect.Left;
   w2:= (Rect.Right - Rect.Left) div 2;
   w3:= (Rect.Right - Rect.Left) div 3;
   w6:= (Rect.Right - Rect.Left) div 6;
   guiCanvas.Triangle(Rect.Left + w6, Rect.Top + w2, Rect.Left + w2,
    Rect.Top + w6, Rect.Right - w6, Rect.Top + w2, FArrowColor, DrawFx);

   guiCanvas.FillQuad(pBounds4(Rect.Left + ((w1 - w3) div 2), Rect.Top + w2,
    w3, w3), cColor4(FArrowColor), DrawFx);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiScroll.DrawBottomArrow(Rect: TRect; Pressed: Boolean);
var
 bColor: TColor4;
 w1, w2, w3, w6: Integer;
begin
 if (Button.Visible) then
  begin
   bColor:= Button.Color4;
   if (Pressed) then bColor:= FPressed.Color4;

   guiCanvas.FillQuad(pRect4(Rect), bColor, DrawFx);
   guiCanvas.Line(Rect.TopLeft, Point(Rect.Left, Rect.Bottom - 1),
    bColor[0], bColor[0], DrawFx);
   guiCanvas.Line(Rect.TopLeft, Point(Rect.Right - 1, Rect.Top),
    bColor[0], bColor[0], DrawFx);
   guiCanvas.Line(Point(Rect.Left + 1, Rect.Bottom - 1), Point(Rect.Right - 1,
    Rect.Bottom - 1), bColor[2], bColor[2], DrawFx);
   guiCanvas.Line(Point(Rect.Right - 1, Rect.Top + 1), Point(Rect.Right - 1,
    Rect.Bottom - 1), bColor[2], bColor[2], DrawFx);

   if (Pressed) then
    begin
     Inc(Rect.Left);
     Inc(Rect.Top);
     Inc(Rect.Right);
     Inc(Rect.Bottom);
    end;

   w1:= Rect.Right - Rect.Left;
   w2:= (Rect.Right - Rect.Left) div 2;
   w3:= (Rect.Right - Rect.Left) div 3;
   w6:= (Rect.Right - Rect.Left) div 6;
   guiCanvas.Triangle(Rect.Right - w6 - 1, Rect.Top + w2, Rect.Left + w2,
    Rect.Bottom - w6 - 1, Rect.Left + w6 + 1, Rect.Top + w2, FArrowColor,
    DrawFx);

   guiCanvas.FillQuad(pBounds4(Rect.Left + ((w1 - w3) div 2), Rect.Top + w3 - 1,
    w3, w3), cColor4(FArrowColor), DrawFx);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiScroll.DrawAnchor(Rect: TRect; Pressed: Boolean);
var
 bColor: TColor4;
begin
 if (Button.Visible) then
  begin
   bColor:= Button.Color4;
   if (Pressed) then bColor:= FPressed.Color4;

   guiCanvas.FillQuad(pRect4(Rect), bColor, DrawFx);
   guiCanvas.Line(Rect.TopLeft, Point(Rect.Left, Rect.Bottom - 1),
    bColor[0], bColor[0], DrawFx);
   guiCanvas.Line(Rect.TopLeft, Point(Rect.Right - 1, Rect.Top),
    bColor[0], bColor[0], DrawFx);
   guiCanvas.Line(Point(Rect.Left + 1, Rect.Bottom - 1), Point(Rect.Right - 1, Rect.Bottom - 1),
    bColor[2], bColor[2], DrawFx);
   guiCanvas.Line(Point(Rect.Right - 1, Rect.Top + 1), Point(Rect.Right - 1, Rect.Bottom - 1),
    bColor[2], bColor[2], DrawFx);
  end;

 if (FBorderColor shr 24 > 0) then
  begin
   Dec(Rect.Left);
   Dec(Rect.Top);
   Inc(Rect.Right);
   Inc(Rect.Bottom);
   GuiCanvas.Quad(pRect4(Rect), cColor4(FBorderColor), DrawFx);
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiScroll.DoPaint();
var
 ArrowSize : Integer;
 PaintRect : TRect;
 ArrowRect : TRect;
 ScrollRect: TRect;
 AnchorArea: Integer;
 AnchorPos : Integer;
 AnchorRect: TRect;
begin
 PaintRect:= VirtualRect;

 if (FBorderColor shr 24 > 0) then
  guiCanvas.Quad(pRect4(PaintRect), cColor4(FBorderColor), DrawFx);

 ArrowSize:= (PaintRect.Right - PaintRect.Left) - 2;

 ScrollRect:= PaintRect;
 ScrollRect.Top   := PaintRect.Top + ArrowSize + 1;
 ScrollRect.Bottom:= PaintRect.Bottom - (ArrowSize + 1);

 if (FScroll.Visible) then
  guiCanvas.FillQuad(pRect4(ScrollRect), FScroll.Color4, DrawFx);

 if (FBorderColor shr 24 > 0) then
  guiCanvas.Quad(pRect4(ScrollRect), cColor4(FBorderColor), DrawFx);

 ArrowRect:= Bounds(PaintRect.Left + 1, PaintRect.Top + 1, ArrowSize, ArrowSize);
 DrawTopArrow(ArrowRect, Pressed1);

 ArrowRect:= Bounds(PaintRect.Left + 1, PaintRect.Bottom - (ArrowSize + 1),
  ArrowSize, ArrowSize);
 DrawBottomArrow(ArrowRect, Pressed2);

 AnchorArea:= (PaintRect.Bottom - PaintRect.Top) - (4 + (ArrowSize * 3));
 AnchorPos := PaintRect.Top + 2 + ArrowSize + Round(FTheta * AnchorArea);
 AnchorRect:= Bounds(PaintRect.Left + 1, AnchorPos, ArrowSize, ArrowSize);
 DrawAnchor(AnchorRect, APressed);
end;

//---------------------------------------------------------------------------
procedure TGuiScroll.DoMouseEvent(const MousePos: TPoint;
 Event: TMouseEventType; Button: TMouseButtonType; Shift: TShiftState);
var
 PaintRect : TRect;
 ArrowSize : Integer;
 AnchorArea: Integer;
 AnchorPos : Integer;
 Rect1, Rect2, Rect3, sRect: TRect;
 FOldTheta: Real;
begin
 PaintRect:= VirtualRect;
 ArrowSize:= (PaintRect.Right - PaintRect.Left) - 2;

 Rect1:= Bounds(PaintRect.Left + 1, PaintRect.Top + 1, ArrowSize, ArrowSize);
 Rect2:= Bounds(PaintRect.Left + 1, PaintRect.Bottom - (ArrowSize + 1),
  ArrowSize, ArrowSize);

 AnchorArea:= (PaintRect.Bottom - PaintRect.Top) - (4 + (ArrowSize * 3));
 AnchorPos := PaintRect.Top + 2 + ArrowSize + Round(FTheta * AnchorArea);
 Rect3     := Bounds(PaintRect.Left + 1, AnchorPos, ArrowSize, ArrowSize);

 sRect:= PaintRect;
 sRect.Top   := PaintRect.Top + ArrowSize + 1;
 sRect.Bottom:= PaintRect.Bottom - (ArrowSize + 1);

 if (Event = mseDown)and(Button = btnLeft) then
  begin
   Pressed1:= PointInRect(MousePos, Rect1);
   Pressed2:= PointInRect(MousePos, Rect2);
   APressed:= PointInRect(MousePos, Rect3);

   FOldTheta:= FTheta;
   if (Pressed1) then FTheta:= FTheta - FArrowInc;
   if (Pressed2) then FTheta:= FTheta + FArrowInc;

   if (PointInRect(MousePos, sRect))and(not APressed) then
    begin
     if (MousePos.Y > Rect3.Bottom) then FTheta:= FTheta + FPageInc;
     if (MousePos.Y < Rect3.Top) then FTheta:= FTheta - FPageInc;
    end;

   FTheta:= Max(Min(Theta, 1.0), 0.0);
   ClickPos:= MousePos;
   CLickTheta:= FTheta;

   if (FTheta <> FOldTheta)and(Assigned(FOnChange)) then FOnChange(Self);
  end;

 if (Event = mseMove)and(APressed) then
  begin
   if (Abs(MousePos.X - ClickPos.X) < Width * 4) then
    begin
     FTheta:= ClickTheta + ((MousePos.Y - ClickPos.Y) / AnchorArea);
     FTheta:= Max(Min(Theta, 1.0), 0.0);
    end else FTheta:= ClickTheta; 

   if (Assigned(FOnChange)) then FOnChange(Self);
  end;

 if (Event = mseUp)and(Button = btnLeft) then
  begin
   Pressed1:= False;
   Pressed2:= False;
   APressed:= False;
  end;
end;

//---------------------------------------------------------------------------
end.

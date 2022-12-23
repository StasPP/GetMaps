unit GuiPaint;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, AsphyreDef, GuiTypes, GuiControls;

//---------------------------------------------------------------------------
type
 TGuiPaintEvent = procedure(Sender: TObject; const PaintRect: TRect) of
  object;
  
//---------------------------------------------------------------------------
 TGuiPaint = class(TGuiControl)
 private
  FOnPaint: TGuiPaintEvent;

 protected
  procedure DoPaint(); override;
  procedure SelfDescribe(); override;
 public
  property OnPaint: TGuiPaintEvent read FOnPaint write FOnPaint;

  property Border;
  property Bkgrnd;

  property OnClick;
  property OnDblClick;
  property OnMouse;
  property OnKey;
  property OnMouseEnter;
  property OnMouseLeave;

  constructor Create(AOwner: TGuiControl); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TGuiPaint.Create(AOwner: TGuiControl);
begin
 inherited;

 Border.Color1($FFB99D7F);
 Border.Visible:= True;

 Bkgrnd.Color1($FFFFFFFF);
 Bkgrnd.Visible:= True;

 Width := 120;
 Height:= 120;
end;

//---------------------------------------------------------------------------
procedure TGuiPaint.DoPaint();
var
 PaintRect: TRect;
begin
 PaintRect:= VirtualRect;

 if (Bkgrnd.Visible) then
  guiCanvas.FillQuad(pRect4(PaintRect), Bkgrnd.Color4, DrawFx);

 if (Assigned(FOnPaint)) then
  FOnPaint(Self, PaintRect); 

 if (Border.Visible) then
  guiCanvas.Quad(pRect4(PaintRect), Border.Color4, DrawFx);
end;

//---------------------------------------------------------------------------
procedure TGuiPaint.SelfDescribe();
begin
 inherited;
 
 FNameOfClass:= 'TGuiPaint';
 FDescOfClass:= 'This component can be used to paint on.';

 DescribeDefault('bkgrnd');
 DescribeDefault('border');
end;

//---------------------------------------------------------------------------
end.

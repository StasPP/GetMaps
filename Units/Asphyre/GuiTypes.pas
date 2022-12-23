unit GuiTypes;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, Graphics, Controls, Math, AsphyreDef, AsphyreCanvas,
 AsphyreImages, AsphyreFonts, AsphyreStates, AsphyreDevices;

//---------------------------------------------------------------------------
type
 TMouseEventType = (mseDown, mseUp, mseMove, mseClick, mseDblClick, mseEnter,
  mseLeave);

//---------------------------------------------------------------------------
 TMouseButtonType = (btnLeft, btnRight, btnMiddle, btnNone);

//---------------------------------------------------------------------------
 TKeyEventType = (kbdDown, kbdUp, kbdPress);

//---------------------------------------------------------------------------
 TGuiMouseEvent = procedure(Sender: TObject; const MousePos: TPoint;
  Event: TMouseEventType; Button: TMouseButtonType;
  Shift: TShiftState) of object;

//---------------------------------------------------------------------------
 TGuiKeyEvent = procedure(Sender: TObject; Key: Integer; Event: TKeyEventType;
  Shift: TShiftState) of object;

//---------------------------------------------------------------------------
 TGuiTextAlign = (gtaAlignLeft, gtaAlignRight, gtaCenter, gtaJustify);

//---------------------------------------------------------------------------
 TGlyphPosition = (gpLeft, gpRight, gpTop, gpBottom);

//---------------------------------------------------------------------------
 TGuiFont = class(TPersistent)
 private
  FFontIndex : Integer;
  FColor0    : Longword;
  FColor1    : Longword;
  FSize      : Real;
  FStyle     : TFontStylesFx;
  FInterleave: Real;
 public
  property FontIndex: Integer read FFontIndex write FFontIndex;

  property Size : Real read FSize write FSize;
  property Style: TFontStylesFx read FStyle write FStyle;

  property Color0: Longword read FColor0 write FColor0;
  property Color1: Longword read FColor1 write FColor1;

  property Interleave: Real read FInterleave write FInterleave;

  function Setup(): TAsphyreFont;
  procedure TextOut(const Text: string; x, y: Real);

  procedure Assign(Source: TPersistent); override;
  procedure AssignTo(Dest: TPersistent); override;

  procedure WriteToStream(Stream: TStream);
  procedure ReadFromStream(Stream: TStream);

  constructor Create();
 end;

//---------------------------------------------------------------------------
 TGuiFill = class(TPersistent)
 private
  FVisible: Boolean;
  FColor4 : TColor4;

  function GetColor(Num: Integer): Longword;
  procedure SetColor(Num: Integer; const Value: Longword);
 public
  property Colors[Num: Integer]: Longword read GetColor write SetColor; default;
  property Visible: Boolean read FVisible write FVisible;
  property Color4 : TColor4 read FColor4 write FColor4;

  procedure Color1(Color: Cardinal);

  procedure Assign(Source: TPersistent); override;
  procedure AssignTo(Dest: TPersistent); override;

  procedure WriteToStream(Stream: TStream);
  procedure ReadFromStream(Stream: TStream);

  constructor Create();
 end;

//---------------------------------------------------------------------------
 TPropertyType = (ptInteger, ptReal, ptString, ptBoolean, ptFill, ptFont,
  ptDrawOp, ptAlignment, ptColor, ptStrings, ptGlyphPosition, ptUnknown);

//---------------------------------------------------------------------------
 TPropertyRec = record
  Name : string;
  Desc : string;
  PType: TPropertyType;
  Tag  : Integer;
 end;

//---------------------------------------------------------------------------
 TObjectProc = procedure of object;

//---------------------------------------------------------------------------
 TGuiObject = class
 private
  Props : array of TPropertyRec;

  function GetPropertyDesc(Num: Integer): string;
  function GetPropertyName(Num: Integer): string;
  function GetPropertyType(Num: Integer): TPropertyType;
  function GetPropertyCount(): Integer;
  function FindProp(Name: string): Integer;
  function GetProp(const Name: string): Variant;
  procedure SetProp(const Name: string; const Value: Variant);
  function GetPropFill(const Name: string): TGuiFill;
  procedure SetPropFill(const Name: string; const Value: TGuiFill);
  function GetPropFont(const Name: string): TGuiFont;
  procedure SetPropFont(const Name: string; const Value: TGuiFont);
  function GetPropertyNum(const Name: string): Integer;
 protected
  FNameOfClass: string;
  FDescOfClass: string;

  function IncludeProp(const Name: string; PType: TPropertyType; Tag: Integer;
   const Desc: string): Integer;
  procedure SelfDescribe(); virtual;

  function ReadProp(Tag: Integer): Variant; virtual;
  procedure WriteProp(Tag: Integer; const Value: Variant); virtual;

  function ReadPropFill(Tag: Integer): TGuiFill; virtual;
  procedure WritePropFill(Tag: Integer; Value: TGuiFill); virtual;

  function ReadPropFont(Tag: Integer): TGuiFont; virtual;
  procedure WritePropFont(Tag: Integer; Value: TGuiFont); virtual;
 public
  // class description
  property NameOfClass: string read FNameOfClass;
  property DescOfClass: string read FDescOfClass;

  // property description
  property PropertyCount: Integer read GetPropertyCount;
  property PropertyType[Num: Integer]: TPropertyType read GetPropertyType;
  property PropertyName[Num: Integer]: string read GetPropertyName;
  property PropertyDesc[Num: Integer]: string read GetPropertyDesc;
  property PropertyNum[const Name: string]: Integer read GetPropertyNum;

  // property access
  property Prop[const Name: string]: Variant read GetProp write SetProp; default;
  property PropFill[const Name: string]: TGuiFill read GetPropFill write SetPropFill;
  property PropFont[const Name: string]: TGuiFont read GetPropFont write SetPropFont;

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
// Globalized access to key Asphyre components
//---------------------------------------------------------------------------
var
 guiFonts : TAsphyreFonts  = nil;
 guiImages: TAsphyreImages = nil;
 guiCanvas: TAsphyreCanvas = nil;
 guiDevice: TAsphyreDevice = nil;

 guiPosGrid: TPoint = (X: 1; Y: 1); // for moving GUI components
 guiDesign : Boolean = False;       // whether GUI is in DESIGN mode

//---------------------------------------------------------------------------
function Button2Gui(Button: TMouseButton): TMouseButtonType;
function ShortRect(const Rect1, Rect2: TRect): TRect;
function MoveRect(const Rect: TRect; const Point: TPoint): TRect;
function ExchangeColors(const Colors: TColor4): TColor4;
function RectExtrude(const Rect: TRect): TPoint4;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
function Button2Gui(Button: TMouseButton): TMouseButtonType;
begin
 Result:= btnNone;
 case Button of
  mbLeft  : Result:= btnLeft;
  mbRight : Result:= btnRight;
  mbMiddle: Result:= btnMiddle;
 end;
end;

//---------------------------------------------------------------------------
function ShortRect(const Rect1, Rect2: TRect): TRect;
begin
 Result.Left  := Max(Rect1.Left, Rect2.Left);
 Result.Top   := Max(Rect1.Top, Rect2.Top);
 Result.Right := Min(Rect1.Right, Rect2.Right);
 Result.Bottom:= Min(Rect1.Bottom, Rect2.Bottom);
end;

//---------------------------------------------------------------------------
function MoveRect(const Rect: TRect; const Point: TPoint): TRect;
begin
 Result.Left  := Rect.Left   + Point.X;
 Result.Top   := Rect.Top    + Point.Y;
 Result.Right := Rect.Right  + Point.X;
 Result.Bottom:= Rect.Bottom + Point.Y;
end;

//---------------------------------------------------------------------------
function ExchangeColors(const Colors: TColor4): TColor4;
begin
 Result[0]:= Colors[3];
 Result[1]:= Colors[2];
 Result[2]:= Colors[1];
 Result[3]:= Colors[0];
end;

//---------------------------------------------------------------------------
function RectExtrude(const Rect: TRect): TPoint4;
begin
 Result:= pBounds4(Rect.Left + 1, Rect.Top + 1, (Rect.Right - Rect.Left) - 2,
  (Rect.Bottom - Rect.Top) - 2);
end;

//---------------------------------------------------------------------------
constructor TGuiFont.Create();
begin
 inherited;

 FFontIndex := 0;
 FColor0    := $FFA0A0A0;
 FColor1    := $FFFFFFFF;
 FSize      := 1.0;
 FStyle     := [];
 FInterleave:= 0.0;
end;

//---------------------------------------------------------------------------
procedure TGuiFont.Assign(Source: TPersistent);
begin
 if (Source is TGuiFont) then
  begin
   FFontIndex := TGuiFont(Source).FontIndex;
   FColor0    := TGuiFont(Source).Color0;
   FColor1    := TGuiFont(Source).Color1;
   FSize      := TGuiFont(Source).Size;
   FStyle     := TGuiFont(Source).Style;
   FInterleave:= TGuiFont(Source).Interleave;
  end else inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiFont.AssignTo(Dest: TPersistent);
begin
 if (Dest is TGuiFont) then
  begin
   TGuiFont(Dest).FontIndex := FFontIndex;
   TGuiFont(Dest).Color0    := FColor0;
   TGuiFont(Dest).Color1    := FColor1;
   TGuiFont(Dest).Size      := FSize;
   TGuiFont(Dest).Style     := FStyle;
   TGuiFont(Dest).Interleave:= FInterleave;
  end else inherited;
end;

//---------------------------------------------------------------------------
function TGuiFont.Setup(): TAsphyreFont;
begin
 Result:= nil;
 if (guiFonts <> nil)and(guiCanvas <> nil)and(FFontIndex >= 0)and(FFontIndex < guiFonts.Count) then
  begin
   guiFonts[FFontIndex].Scale:= FSize;
   guiFonts[FFontIndex].Style:= FStyle;
   guiFonts[FFontIndex].Interleave:= FInterleave;
   Result:= guiFonts[FFontIndex];
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiFont.TextOut(const Text: string; x, y: Real);
begin
 if (Setup() <> nil) then
  guiFonts[FFontIndex].TextOut(Text, x, y, FColor0, FColor1, fxBlend);
end;

//---------------------------------------------------------------------------
procedure TGuiFont.WriteToStream(Stream: TStream);
begin
 Stream.WriteBuffer(FFontIndex,  SizeOf(Integer));
 Stream.WriteBuffer(FColor0,     SizeOf(Longword));
 Stream.WriteBuffer(FColor1,     SizeOf(Longword));
 Stream.WriteBuffer(FSize,       SizeOf(Real));
 Stream.WriteBuffer(FStyle,      SizeOf(TFontStylesFx));
 Stream.WriteBuffer(FInterleave, SizeOf(Real));
end;

//---------------------------------------------------------------------------
procedure TGuiFont.ReadFromStream(Stream: TStream);
begin
 Stream.ReadBuffer(FFontIndex,  SizeOf(Integer));
 Stream.ReadBuffer(FColor0,     SizeOf(Longword));
 Stream.ReadBuffer(FColor1,     SizeOf(Longword));
 Stream.ReadBuffer(FSize,       SizeOf(Real));
 Stream.ReadBuffer(FStyle,      SizeOf(TFontStylesFx));
 Stream.ReadBuffer(FInterleave, SizeOf(Real));
end;

//---------------------------------------------------------------------------
constructor TGuiFill.Create();
begin
 inherited;

 FColor4[0]:= $FFD0D0D0;
 FColor4[1]:= $FFD0D0D0;
 FColor4[2]:= $FFD0D0D0;
 FColor4[3]:= $FFD0D0D0;
 FVisible  := True;
end;

//---------------------------------------------------------------------------
function TGuiFill.GetColor(Num: Integer): Longword;
begin
 if (Num >= 0)and(Num <= 3) then Result:= FColor4[Num] else Result:= 0;
end;

//---------------------------------------------------------------------------
procedure TGuiFill.SetColor(Num: Integer; const Value: Longword);
begin
 if (Num >= 0)and(Num <= 3) then FColor4[Num]:= Value;
end;

//---------------------------------------------------------------------------
procedure TGuiFill.Color1(Color: Cardinal);
var
 i: Integer;
begin
 for i:= 0 to 3 do
  FColor4[i]:= Color;
end;

//---------------------------------------------------------------------------
procedure TGuiFill.Assign(Source: TPersistent);
begin
 if (Source is TGuiFill) then
  begin
   FVisible:= TGuiFill(Source).Visible;
   FColor4 := TGuiFill(Source).Color4;
  end else inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiFill.AssignTo(Dest: TPersistent);
begin
 if (Dest is TGuiFill) then
  begin
   TGuiFill(Dest).Visible:= FVisible;
   TGuiFill(Dest).Color4 := FColor4;
  end else inherited;
end;

//---------------------------------------------------------------------------
procedure TGuiFill.WriteToStream(Stream: TStream);
begin
 Stream.WriteBuffer(FColor4, SizeOf(TColor4));
 Stream.WriteBuffer(FVisible, SizeOf(Boolean));
end;

//---------------------------------------------------------------------------
procedure TGuiFill.ReadFromStream(Stream: TStream);
begin
 Stream.ReadBuffer(FColor4, SizeOf(TColor4));
 Stream.ReadBuffer(FVisible, SizeOf(Boolean));
end;

//---------------------------------------------------------------------------
constructor TGuiObject.Create();
begin
 inherited;

 SetLength(Props, 0);
 SelfDescribe();
end;

//---------------------------------------------------------------------------
destructor TGuiObject.Destroy();
begin
 SetLength(Props, 0);

 inherited;
end;

//---------------------------------------------------------------------------
function TGuiObject.IncludeProp(const Name: string; PType: TPropertyType;
 Tag: Integer; const Desc: string): Integer;
var
 Index: Integer;
begin
 Index:= Length(Props);
 SetLength(Props, Index + 1);

 Props[Index].Name := Name;
 Props[Index].PType:= PType;
 Props[Index].Desc := Desc;
 Props[Index].Tag  := Tag;

 Result:= Index;
end;

//---------------------------------------------------------------------------
function TGuiObject.GetPropertyName(Num: Integer): string;
begin
 if (Num >= 0)or(Num < Length(Props)) then
  Result:= Props[Num].Name else Result:= '[Name: INVALID #]';
end;

//---------------------------------------------------------------------------
function TGuiObject.GetPropertyType(Num: Integer): TPropertyType;
begin
 if (Num >= 0)or(Num < Length(Props)) then
  Result:= Props[Num].PType else Result:= ptUnknown;
end;

//---------------------------------------------------------------------------
function TGuiObject.GetPropertyDesc(Num: Integer): string;
begin
 if (Num >= 0)or(Num < Length(Props)) then
  Result:= Props[Num].Desc else Result:= '[Desc: INVALID #]';
end;

//---------------------------------------------------------------------------
function TGuiObject.GetPropertyCount(): Integer;
begin
 Result:= Length(Props);
end;

//---------------------------------------------------------------------------
procedure TGuiObject.SelfDescribe();
begin
 FNameOfClass:= 'TGuiObject';
 FDescOfClass:= 'Unknown TGuiObject-compliant';

 inherited;
end;

//---------------------------------------------------------------------------
function TGuiObject.GetProp(const Name: string): Variant;
var
 Index: Integer;
begin
 Result:= 0;

 Index:= FindProp(Name);
 if (Index <> -1) then
  Result:= ReadProp(Props[Index].Tag);
end;

//---------------------------------------------------------------------------
procedure TGuiObject.SetProp(const Name: string; const Value: Variant);
var
 Index: Integer;
begin
 Index:= FindProp(Name);
 if (Index <> -1) then
  WriteProp(Props[Index].Tag, Value);
end;

//---------------------------------------------------------------------------
function TGuiObject.GetPropFill(const Name: string): TGuiFill;
var
 Index: Integer;
begin
 Result:= nil;

 Index:= FindProp(Name);
 if (Index <> -1) then
  Result:= ReadPropFill(Props[Index].Tag);
end;

//---------------------------------------------------------------------------
procedure TGuiObject.SetPropFill(const Name: string; const Value: TGuiFill);
var
 Index: Integer;
begin
 Index:= FindProp(Name);
 if (Index <> -1) then
  WritePropFill(Props[Index].Tag, Value);
end;

//---------------------------------------------------------------------------
function TGuiObject.GetPropFont(const Name: string): TGuiFont;
var
 Index: Integer;
begin
 Result:= nil;

 Index:= FindProp(Name);
 if (Index <> -1) then
  Result:= ReadPropFont(Props[Index].Tag);
end;

//---------------------------------------------------------------------------
procedure TGuiObject.SetPropFont(const Name: string; const Value: TGuiFont);
var
 Index: Integer;
begin
 Index:= FindProp(Name);
 if (Index <> -1) then
  WritePropFont(Props[Index].Tag, Value);
end;

//---------------------------------------------------------------------------
function TGuiObject.FindProp(Name: string): Integer;
var
 i: Integer;
begin
 Name:= LowerCase(Name);

 for i:= 0 to Length(Props) - 1 do
  if (Name = LowerCase(Props[i].Name)) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= -1;
end;

//---------------------------------------------------------------------------
function TGuiObject.ReadProp(Tag: Integer): Variant;
begin
 Result:= 0;
end;

//---------------------------------------------------------------------------
procedure TGuiObject.WriteProp(Tag: Integer; const Value: Variant);
begin
 // no code
end;

//---------------------------------------------------------------------------
function TGuiObject.ReadPropFill(Tag: Integer): TGuiFill;
begin
 Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TGuiObject.WritePropFill(Tag: Integer; Value: TGuiFill);
begin
 // no code
end;

//---------------------------------------------------------------------------
function TGuiObject.ReadPropFont(Tag: Integer): TGuiFont;
begin
 Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TGuiObject.WritePropFont(Tag: Integer; Value: TGuiFont);
begin
 // no code
end;

//---------------------------------------------------------------------------
function TGuiObject.GetPropertyNum(const Name: string): Integer;
begin
 Result:= FindProp(Name);
end;

//---------------------------------------------------------------------------
end.


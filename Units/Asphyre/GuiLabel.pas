unit GuiLabel;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, AsphyreDef, GuiTypes, GuiControls, AsphyreFonts;

//---------------------------------------------------------------------------
type
 TGuiLabel = class(TGuiControl)
 private
  Words: TStrings;
  FText: string;
  
  FWordWrap   : Boolean;
  FAlignment  : TGuiTextAlign;
  FTextAdjust : Integer;
  FLineSpacing: Real;
  FProgressive: Boolean;
  FShowDelay  : Integer;
  ShowCounter : Integer;
  ShowAmount  : Integer;

  function ExtractWord(const InStr: string; var Step: Integer;
   out Text: string): Boolean;
  procedure SplitText();
  procedure SetText(const Value: string);
  function EstimateLength(vFont: TAsphyreFont): Real;
  function EstimatePart(vFont: TAsphyreFont; From, Amount: Integer): Real;
  function TermWord(Index: Integer): Boolean;
  function NextLine(vFont: TAsphyreFont; Size: Integer; var Step: Integer;
   out First, Amount: Integer; out TermLine: Boolean): Boolean;
  procedure DrawSimpleText(const PaintRect: TRect; vFont: TAsphyreFont);
  procedure DrawText(const PaintRect: TRect; vFont: TAsphyreFont);
 protected
  procedure DoPaint(); override;
  procedure DoUpdate(); override;
  procedure SelfDescribe(); override;
  function ReadProp(Tag: Integer): Variant; override;
  procedure WriteProp(Tag: Integer; const Value: Variant); override;
 public
  property Text: string read FText write SetText;
  property WordWrap   : Boolean read FWordWrap write FWordWrap;
  property Alignment  : TGuiTextAlign read FAlignment write FAlignment;
  property TextAdjust : Integer read FTextAdjust write FTextAdjust;
  property LineSpacing: Real read FLineSpacing write FLineSpacing;
  property Progressive: Boolean read FProgressive write FProgressive;
  property ShowDelay  : Integer read FShowDelay write FShowDelay;

  property Font;
  property Bkgrnd;
  property Border;
  property DisabledFont;

  property OnClick;
  property OnDblClick;
  property OnMouse;
  property OnKey;
  property OnMouseEnter;
  property OnMouseLeave;

  procedure ResetAnim();

  constructor Create(AOwner: TGuiControl); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TGuiLabel.Create(AOwner: TGuiControl);
begin
 inherited;

 Words:= TStringList.Create();

 Font.Color0:= $FFC56A31;
 Font.Color1:= $FFC56A31;

 DisabledFont.Color0:= $FF5F6B70;
 DisabledFont.Color1:= $FF5F6B70;

 Bkgrnd.Color1($FFFFFFFF);
 Bkgrnd.Visible:= False;

 Border.Color1($FFB99D7F);
 Border.Visible:= False;

 Width := 100;
 Height:= 20;
 FWordWrap:= False;
 FTextAdjust:= 0;
 FLineSpacing:= 0.0;
 FProgressive:= False;
 FShowDelay  := 2;

 DrawFx:= fxBlend;
 FAlignment:= gtaAlignLeft;

 Text:= //'TGuiLabel';
 #0#0#0#0'The 0xFF800080contents of this file are subject to the 0xFF000080Mozilla ' +
  'Public License Version 1.1 (the "License"); you may not use this file ' +
  'except in compliance with the 0xFF008000License.'#10 + ' '#0#0#0#0'You may obtain a copy of the ' +
  'License at 0xFF808080http://www.mozilla.org/MPL/';
end;

//---------------------------------------------------------------------------
destructor TGuiLabel.Destroy();
begin
 Words.Free();

 inherited;
end;

//---------------------------------------------------------------------------
function TGuiLabel.ExtractWord(const InStr: string; var Step: Integer;
 out Text: string): Boolean;
const
 TextSet = [#33..#126];
 StripChars = [' ', #13, #8];
var
 InitPos, TextLength: Integer;
begin
 // (1) Skip unused characters.
 while (Step <= Length(InStr))and(InStr[Step] in StripChars) do Inc(Step);

 // (2) Are we at the end of the line?
 if (Step > Length(InStr)) then
  begin
   Result:= False;
   Exit;
  end;

 // (3) Find the word length.
 InitPos:= Step;
 TextLength:= 0;

 while (Step <= Length(InStr))and(not (InStr[Step] in StripChars)) do
  begin
   Inc(Step);
   Inc(TextLength);
  end;

 // (4) Extract the found word.
 Text:= Copy(InStr, InitPos, TextLength);
 Result:= (TextLength > 0);
end;

//---------------------------------------------------------------------------
procedure TGuiLabel.SplitText();
var
 Step: Integer;
 TextWord, FullText: string;
begin
 Words.Clear();

 if (FProgressive) then FullText:= Copy(FText, 1, ShowAmount)
  else FullText:= FText;

 Step:= 1;
 while (ExtractWord(FullText, Step, TextWord)) do Words.Add(TextWord);
end;

//---------------------------------------------------------------------------
procedure TGuiLabel.SetText(const Value: string);
begin
 FText:= Value;

 ShowCounter:= 0;
 ShowAmount := 0;
 
 SplitText();
end;

//---------------------------------------------------------------------------
function TGuiLabel.EstimateLength(vFont: TAsphyreFont): Real;
var
 i: Integer;
begin
 Result:= 0.0;

 for i:= 0 to Words.Count - 1 do
  Result:= Result + vFont.TextWidth(Words[i]);
end;

//---------------------------------------------------------------------------
function TGuiLabel.EstimatePart(vFont: TAsphyreFont; From,
 Amount: Integer): Real;
var
 i: Integer;
begin
 Result:= 0.0;

 for i:= 0 to Amount - 1 do
  Result:= Result + vFont.TextWidth(Words[i + From]);
end;

//---------------------------------------------------------------------------
function TGuiLabel.TermWord(Index: Integer): Boolean;
var
 i: Integer;
begin
 Result:= False;
 for i:= 1 to Length(Words[Index]) do
  begin
   Result:= Result or (Words[Index][i] = #10);
   if (Result) then Break;
  end; 
end;

//---------------------------------------------------------------------------
function TGuiLabel.NextLine(vFont: TAsphyreFont; Size: Integer;
 var Step: Integer; out First, Amount: Integer; out TermLine: Boolean): Boolean;
var
 Acc, Added: Real;
begin
 Acc:= 0.0;
 First:= Step;
 Amount:= 0;
 TermLine:= False;
 while (Step < Words.Count)and(not TermLine) do
  begin
   TermLine:= (Step < Words.Count)and(TermWord(Step))and(First <> Step);
   Added:= vFont.TextWidth(Words[Step]);
   if (Step < Words.Count - 1) then
    Added:= Added + vFont.TextWidth(#32);
   if (Acc + Added >= Size) then Break;

   Acc:= Acc + Added;
   Inc(Step);
   Inc(Amount);
  end;

 Result:= (Amount > 0)and(Step < Words.Count); 
end;

//---------------------------------------------------------------------------
procedure TGuiLabel.DrawSimpleText(const PaintRect: TRect; vFont: TAsphyreFont);
var
 vWidth, vHeight: Integer;
 tWidth, tHeight: Integer;
 xPos, xInc: Real;
 yPos: Integer;
 i: Integer;
 SrcFont: TGuiFont;
begin
 vWidth := PaintRect.Right - PaintRect.Left;
 vHeight:= PaintRect.Bottom - PaintRect.Top;

 tWidth := Round(vFont.TextWidth(FText));
 tHeight:= Round(vFont.TextHeight(FText));

 yPos:= PaintRect.Top + ((vHeight - tHeight) div 2) + FTextAdjust;

 SrcFont:= Font;
 if (not Enabled) then SrcFont:= DisabledFont;

 case FAlignment of
  gtaAlignLeft:
   vFont.TextOut(FText, PaintRect.Left + 4, yPos, SrcFont.Color0,
    SrcFont.Color1, DrawFx);
  gtaAlignRight:
   vFont.TextOut(FText, PaintRect.Right - 4 - Round(vFont.TextWidth(FText)),
    yPos, SrcFont.Color0, SrcFont.Color1, DrawFx);
  gtaCenter:
   vFont.TextOut(FText, PaintRect.Left + ((vWidth - tWidth) div 2), yPos,
    SrcFont.Color0, SrcFont.Color1, DrawFx);
  gtaJustify:
   begin
    xPos:= PaintRect.Left + 4;
    xInc:= 0.0;
    if (Words.Count > 1) then
     xInc:= ((vWidth - 8) - EstimateLength(vFont)) / (Words.Count - 1);

    for i:= 0 to Words.Count - 1 do
     begin
      vFont.TextOut(Words[i], xPos, yPos, SrcFont.Color0,
       SrcFont.Color1, DrawFx);
      xPos:= xPos + xInc + vFont.TextWidth(Words[i]);
     end; 
   end;
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiLabel.DrawText(const PaintRect: TRect; vFont: TAsphyreFont);
var
 Size: Integer;
 xPos, yPos, xInc: Real;
 Step, i: Integer;
 LastLine, TermLine: Boolean;
 First, Amount: Integer;
 FullText: string;
 SrcFont: TGuiFont;
begin
 if (Words.Count < 1) then Exit;

 SrcFont:= Font;
 if (not Enabled) then SrcFont:= DisabledFont;

 Size:= PaintRect.Right - PaintRect.Left;
 yPos:= PaintRect.Top + FTextAdjust;
 Step:= 0;
 repeat
  // extract next amount of words for the line
  LastLine:= not NextLine(vFont, Size, Step, First, Amount, TermLine);

  if (Alignment = gtaJustify)and(not LastLine)and(not TermLine) then
   begin // justified text
    xPos:= PaintRect.Left + 4;
    xInc:= 0.0;
    if (Amount > 1) then
     xInc:= ((Size - 8) - EstimatePart(vFont, First, Amount)) / (Amount - 1);

    // draw as if it was justified text
    for i:= 0 to Amount - 1 do
     begin
      vFont.TextOut(Words[i + First], xPos, yPos, SrcFont.Color0,
       SrcFont.Color1, DrawFx);
      xPos:= xPos + xInc + vFont.TextWidth(Words[i + First]);
     end;
   end else
   begin // unjustified text
    // -> create a full-string to allow TAsphyreFont blank spacing
    FullText:= '';
    for i:= 0 to Amount - 1 do
     begin
      FullText:= FullText + Words[i + First];
      if (i < Amount - 1) then FullText:= FullText + #32;
     end;

    // -> draw as if it was simple text 
    case FAlignment of
     gtaAlignLeft, gtaJustify:
      vFont.TextOut(FullText, PaintRect.Left + 4, yPos, SrcFont.Color0,
       SrcFont.Color1, DrawFx);
     gtaAlignRight:
      vFont.TextOut(FullText, PaintRect.Right - 4 -
       Round(vFont.TextWidth(FullText)), yPos, SrcFont.Color0,
       SrcFont.Color1, DrawFx);
     gtaCenter:
      vFont.TextOut(FullText, PaintRect.Left + ((Size -
       vFont.TextWidth(FullText)) / 2), yPos, SrcFont.Color0,
       SrcFont.Color1, DrawFx);
    end; // case
   end;

  yPos:= yPos + vFont.FontImage.VisibleSize.Y + FLineSpacing;
 until (LastLine)or(yPos >= PaintRect.Bottom);
end;

//---------------------------------------------------------------------------
procedure TGuiLabel.DoPaint();
var
 PaintRect: TRect;
 vFont: TAsphyreFont;
begin
 PaintRect:= VirtualRect;

 if (Bkgrnd.Visible) then
  guiCanvas.FillQuad(pRect4(PaintRect), Bkgrnd.Color4, DrawFx);

 if (Enabled) then vFont:= Font.Setup()
  else vFont:= DisabledFont.Setup();
 if (vFont <> nil) then
  begin
   if (FWordWrap) then DrawText(PaintRect, vFont)
    else DrawSimpleText(PaintRect, vFont);
  end;

 if (Border.Visible) then
  guiCanvas.Quad(pRect4(PaintRect), Border.Color4, DrawFx);
end;

//---------------------------------------------------------------------------
procedure TGuiLabel.DoUpdate();
begin
 if (FProgressive) then
  begin
   Inc(ShowCounter);
   if (ShowCounter >= FShowDelay) then
    begin
     ShowCounter:= 0;
     Inc(ShowAmount);
     SplitText();
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiLabel.ResetAnim();
begin
 ShowAmount := 0;
 ShowCounter:= 0;
end;

//---------------------------------------------------------------------------
procedure TGuiLabel.SelfDescribe();
begin
 inherited;

 FNameOfClass:= 'TGuiLabel';
 FDescOfClass:= 'TGuiLabel is an advanced component that displays text.';

 DescribeDefault('bkgrnd');
 DescribeDefault('border');
 DescribeDefault('font');
 DescribeDefault('disabledfont');

 IncludeProp('Text',         ptString,    $A000, 'The text that will be displayed');
 IncludeProp('WordWrap',     ptBoolean,   $A001, 'Whether the text can be wrapped to appear on multiple lines.');
 IncludeProp('TextAdjust',   ptInteger,   $A002, 'The vertical adjustment of visible text');
 IncludeProp('Alignment',    ptAlignment, $A003, 'The horizontal alignment of text');
 IncludeProp('LineSpacing',  ptInteger,   $A004, 'The space in pixels between text lines');
 IncludeProp('Progressive',  ptBoolean,   $A005, 'Whether to show text as if it was typed by machine');
 IncludeProp('ShowDelay',    ptInteger,   $A006, 'The typing delay for displaying progressive text');
end;

//---------------------------------------------------------------------------
function TGuiLabel.ReadProp(Tag: Integer): Variant;
begin
 case Tag of
  $A000: Result:= FText;
  $A001: Result:= FWordWrap;
  $A002: Result:= FTextAdjust;
  $A003: Result:= FAlignment;
  $A004: Result:= FLineSpacing;
  $A005: Result:= FProgressive;
  $A006: Result:= FShowDelay;
  else Result:= inherited ReadProp(Tag);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiLabel.WriteProp(Tag: Integer; const Value: Variant);
begin
 case Tag of
  $A000: Text       := Value;
  $A001: WordWrap   := Value;
  $A002: TextAdjust := Value;
  $A003: Alignment  := Value;
  $A004: LineSpacing:= Value;
  $A005: Progressive:= Value;
  $A006: ShowDelay  := Value;
  else inherited WriteProp(Tag, Value);
 end;
end;

//---------------------------------------------------------------------------
end.

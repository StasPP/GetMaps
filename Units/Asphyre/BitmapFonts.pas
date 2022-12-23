unit BitmapFonts;
//---------------------------------------------------------------------------
// BitmapFonts.pas                                      Modified: 19-Ago-2005
// Bitmap Font generic implementation                             Version 1.4
//---------------------------------------------------------------------------
//  Changes since v1.3:
//    - Removed TextOutEx due to incompatibilities with new TBitmapEx.
//
//  Changes since v1.31:
//    * Changed to work with new ImageDrawing class
//    + Added font width and height
//    + Added TextOutEx again :)
//    + Added ability to load Asphyre fonts from stream
//---------------------------------------------------------------------------
// The contents of this file are subject to the Mozilla Public License
// Version 1.1 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS"
// basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
// License for the specific language governing rights and limitations
// under the License.
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Windows, Types, Classes, Graphics, Math, AsphyreDef, ImageDrawing, pxfm;

//---------------------------------------------------------------------------
type
 TBitmapFont = class
 private
  FImage: TBitmap;
  Sizes : array of TPoint;

  FFirstLetter: Integer;
  FLetterCount: Integer;
  FInterleave : Integer;
  FFontSize   : TPoint;

  function GetLetterSize(Index: Integer): TPoint;
  procedure SetLetterSize(Index: Integer; const Value: TPoint);
  procedure SetLetterCount(const Value: Integer);
 public
  property Image: TBitmap read FImage;

  property FirstLetter: Integer read FFirstLetter write FFirstLetter;
  property LetterCount: Integer read FLetterCount write SetLetterCount;
  property FontSize   : TPoint read FFontSize write FFontSize;
  property Interleave : Integer read FInterleave write FInterleave;
  property LetterSize[Index: Integer]: TPoint read GetLetterSize write SetLetterSize;

  function TextWidth(const Text: string): Integer;
  function TextHeight(const Text: string): Integer;

  procedure TextOut(const Text: string; Dest: TBitmap; x, y: Integer;
   Color0, Color1: Cardinal); overload;
  procedure TextOut(const Text: string; Dest: TBitmap; x, y: Integer;
   Color: Cardinal); overload;
  procedure TextOutEx(const Text: string; DestDC: THandle; x, y: Integer;
   Color0, Color1: Cardinal); overload;
  procedure TextOutEx(const Text: string; DestDC: THandle; x, y: Integer;
   Color: Cardinal); overload;

  function LoadFromStream(Stream: TStream; out PxFm: TPxFm): Boolean;
  procedure LoadGapless(Image: TBitmap; const PatSize, TexSize: TPoint;
   TexCount: Integer);

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TBitmapFont.Create();
begin
 inherited;

 FImage:= TBitmap.Create();
 SetLength(Sizes, 0);
 FFirstLetter:= 32;
 FLetterCount:= 0;
 FFontSize:= Point(0, 0);
end;

//---------------------------------------------------------------------------
destructor TBitmapFont.Destroy();
begin
 SetLength(Sizes, 0);
 FImage.Free();
 FImage:= nil;

 inherited;
end;

//---------------------------------------------------------------------------
function TBitmapFont.GetLetterSize(Index: Integer): TPoint;
begin
 if (Index >= 0)and(Index < Length(Sizes)) then
  begin
   Result:= Sizes[Index];
  end else Result:= Point(0, 0);
end;

//---------------------------------------------------------------------------
procedure TBitmapFont.SetLetterSize(Index: Integer; const Value: TPoint);
begin
 if (Index >= 0)and(Index < Length(Sizes)) then
  Sizes[Index]:= Value;
end;

//---------------------------------------------------------------------------
procedure TBitmapFont.SetLetterCount(const Value: Integer);
begin
 FLetterCount:= Value;
 if (FLetterCount < 0) then FLetterCount:= 0;

 SetLength(Sizes, FLetterCount);
end;

//---------------------------------------------------------------------------
function TBitmapFont.TextWidth(const Text: string): Integer;
var
 Index  : Integer;
 Pattern: Integer;
 Size   : Integer;
begin
 Size:= 0;
 for Index:= 1 to Length(Text) do
  begin
   Pattern:= Byte(Text[Index]) - Byte(FFirstLetter);
   if (Pattern >= 0)and(Pattern < FLetterCount) then
    Inc(Size, Sizes[Pattern].X + FInterleave);
  end;

 Result:= Size;
end;

//---------------------------------------------------------------------------
function TBitmapFont.TextHeight(const Text: string): Integer;
var
 Index  : Integer;
 Pattern: Integer;
 Size   : Integer;
begin
 Size:= 0;
 for Index:= 1 to Length(Text) do
  begin
   Pattern:= Byte(Text[Index]) - Byte(FFirstLetter);

   if (Pattern >= 0)and(Pattern < FLetterCount) then
    Size:= Max(Size, Sizes[Pattern].Y);
  end;

 Result:= Size;
end;

//---------------------------------------------------------------------------
procedure TBitmapFont.TextOut(const Text: string; Dest: TBitmap; x, y: Integer;
 Color0, Color1: Cardinal);
var
 Index  : Integer;
 Pattern: Integer;
 xPos   : Integer;
begin
 if (FImage.Width = 0)or(FImage.Height = 0) then Exit;

 xPos:= x;
 for Index:= 1 to Length(Text) do
  begin
   Pattern:= Byte(Text[Index]) - FFirstLetter;
   if (Pattern >= 0)and(Pattern < FLetterCount) then
    begin
     ImageDraw(Dest, FImage, FFontSize, xPos, y, Pattern, Color0, Color1);
     Inc(xPos, Sizes[Pattern].x + FInterleave);
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TBitmapFont.TextOut(const Text: string; Dest: TBitmap; x, y: Integer;
 Color: Cardinal);
begin
 TextOut(Text, Dest, x, y, Color, Color);
end;

//---------------------------------------------------------------------------
procedure TBitmapFont.TextOutEx(const Text: string; DestDC: THandle; x,
 y: Integer; Color0, Color1: Cardinal);
var
 Index  : Integer;
 Pattern: Integer;
 xPos   : Integer;
begin
 if (FImage.Width = 0)or(FImage.Height = 0) then Exit;

 xPos:= x;
 for Index:= 1 to Length(Text) do
  begin
   Pattern:= Byte(Text[Index]) - FFirstLetter;
   if (Pattern >= 0)and(Pattern < FLetterCount) then
    begin
     ImageDrawDC(DestDC, FImage, FFontSize, xPos, y, Pattern, Color0, Color1);
     Inc(xPos, Sizes[Pattern].x + FInterleave);
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TBitmapFont.TextOutEx(const Text: string; DestDC: THandle; x,
 y: Integer; Color: Cardinal);
begin
 TextOutEx(Text, DestDC, x, y, Color, Color);
end;

//---------------------------------------------------------------------------
function TBitmapFont.LoadFromStream(Stream: TStream; out PxFm: TPxFm): Boolean;
var
 i: Integer;
begin
 // step 1. read font size data
 try
  // -> letter information
  Stream.ReadBuffer(FFirstLetter, SizeOf(Integer));
  Stream.Seek(8, soFromCurrent); // skip padding and spacing
  Stream.ReadBuffer(FLetterCount, SizeOf(Integer));

  // -> individual letter sizes
  SetLength(Sizes, FLetterCount);
  for i:= 0 to FLetterCount - 1 do
   Stream.ReadBuffer(Sizes[i], SizeOf(TPoint));

 except
  Result:= False;
  Exit;
 end;

 // step 2. read pixel data
 Result:= ReadBitmapPxFm(Stream, FImage, PxFm);

 // step 3. extract font size data
 FFontSize.X:= PxFm.PatternWidth;
 FFontSize.Y:= PxFm.PatternHeight;
end;

//---------------------------------------------------------------------------
procedure TBitmapFont.LoadGapless(Image: TBitmap; const PatSize,
 TexSize: TPoint; TexCount: Integer);
var
 VDepth : Integer;
 TexIndx: Integer;
 Index  : Integer;
 VIndex : Integer;
begin
 VDepth:= (TexSize.Y div PatSize.Y) * PatSize.Y;

 FImage.Width := Image.Width;
 FImage.Height:= VDepth * TexCount;
 if (FImage.PixelFormat <> pf32bit) then FImage.PixelFormat:= pf32bit;
 if (Image.PixelFormat <> pf32bit) then Image.PixelFormat:= pf32bit;

 VIndex:= 0;
 for TexIndx:= 0 to TexCount - 1 do
  for Index:= 0 to TexSize.Y - 1 do
   if (Index < VDepth) then
    begin
     Move(Image.Scanline[Index]^, FImage.Scanline[VIndex]^, TexSize.X * 4);
     Inc(VIndex);
    end;
end;

//---------------------------------------------------------------------------
end.


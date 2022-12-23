unit AsphyreConv2;
//---------------------------------------------------------------------------
// AsphyreConv.pas                                      Modified: 27-Sep-2005
// Pixel Format conversion                                        Version 1.2
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
 Windows, Direct3D9, AsphyreDef;

//---------------------------------------------------------------------------
type
 TLineConvFunc = procedure(Source, Dest: Pointer; Count: Integer); stdcall;

//---------------------------------------------------------------------------
// GetLineConv32toX()
//
// Returns a highly optimized line conversion function which is able
// to convert A8R8G8B8 (32-bit) format to any other.
//---------------------------------------------------------------------------
function GetLineConv32toX(Dest: TColorFormat): TLineConvFunc;

//---------------------------------------------------------------------------
// LineConvXto32()
//
// This routine converts line with the given format to A8R8G8B8 (32-bit).
//---------------------------------------------------------------------------
procedure LineConvXto32(Source, Dest: Pointer; Count: Integer;
 SrcFmt: TColorFormat);

//---------------------------------------------------------------------------
// PixelXto32()
//
// Converts a pixel from any kind of format to A8R8G8B8 (32-bit).
//---------------------------------------------------------------------------
function PixelXto32(Source: Pointer; SrcFmt: TColorFormat): Longword;

//---------------------------------------------------------------------------
// Pixel32toX()
//
// Converts a pixel from A8R8G8B8 (32-bit) format to any other.
//---------------------------------------------------------------------------
procedure Pixel32toX(Source: Longword; Dest: Pointer; DestFmt: TColorFormat);

//---------------------------------------------------------------------------
// PixelConv()
//
// Converts between any kind of two pixel formats.
//---------------------------------------------------------------------------
procedure PixelConv(Source, Dest: Pointer; SrcFormat, DestFormat: TColorFormat);

//---------------------------------------------------------------------------
function DisplaceRB(Color: Cardinal): Cardinal; stdcall;

//---------------------------------------------------------------------------
procedure LineConvMasked(Source, Dest: Pointer; Count, Tolerance: Integer;
 ColorMask: Cardinal);

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
type
 PRealColor = ^TRealColor;
 TRealColor = record
  r, g, b, a: Real;
 end;

//---------------------------------------------------------------------------
{$include include\bitconv32.inc}

//---------------------------------------------------------------------------
// A8R8G8B8 (32-bit) -> R3G3B2 (8-bit)
//---------------------------------------------------------------------------
function PixelA8R8G8B8_R3G3B2(Color: Longword): Byte; stdcall;
const
 x1 = 0; a1 = 8; r1 = 8;  g1 = 8;  b1 = 8;
         r2 = 3; g2 = 3;  b2 = 2;
begin
 {$DEFINE PxInDWORD} {$DEFINE PxOutBYTE}
 {$INCLUDE include\pixasm.inc}
end;

//---------------------------------------------------------------------------
// A8R8G8B8 (32-bit) -> R5G6B5 (16-bit)
//---------------------------------------------------------------------------
function PixelA8R8G8B8_R5G6B5(Color: Longword): Word; stdcall;
const
 x1 = 0; a1 = 8; r1 = 8;  g1 = 8;  b1 = 8;
         r2 = 5;  g2 = 6;  b2 = 5;
begin
 {$DEFINE PxInDWORD} {$DEFINE PxOutWORD}
 {$INCLUDE include\pixasm.inc}
end;

//---------------------------------------------------------------------------
// A8R8G8B8 (32-bit) -> X1R5G5B5 (16-bit)
//---------------------------------------------------------------------------
function PixelA8R8G8B8_X1R5G5B5(Color: Longword): Word; stdcall;
const
 x1 = 0; a1 = 8; r1 = 8;  g1 = 8;  b1 = 8;
         r2 = 5; g2 = 5;  b2 = 5;
begin
 {$DEFINE PxInDWORD} {$DEFINE PxOutWORD}
 {$INCLUDE include\pixasm.inc}
end;

//---------------------------------------------------------------------------
// A8R8G8B8 (32-bit) -> X4R4G4B4 (16-bit)
//---------------------------------------------------------------------------
function PixelA8R8G8B8_X4R4G4B4(Color: Longword): Word; stdcall;
const
 x1 = 0; a1 = 8; r1 = 8;  g1 = 8;  b1 = 8;
         r2 = 4; g2 = 4;  b2 = 4;
begin
 {$DEFINE PxInDWORD} {$DEFINE PxOutWORD}
 {$INCLUDE include\pixasm.inc}
end;

//---------------------------------------------------------------------------
// A8R8G8B8 (32-bit) -> A1R5G5B5 (16-bit)
//---------------------------------------------------------------------------
function PixelA8R8G8B8_A1R5G5B5(Color: Longword): Word; stdcall;
const
 x1 = 0; a1 = 8; r1 = 8;  g1 = 8;  b1 = 8;
 a2 = 1; r2 = 5; g2 = 5;  b2 = 5;
begin
 {$DEFINE PxInDWORD} {$DEFINE PxALPHA} {$DEFINE PxOutWORD}
 {$INCLUDE include\pixasm.inc}
end;

//---------------------------------------------------------------------------
// A8R8G8B8 (32-bit) -> A4R4G4B4 (16-bit)
//---------------------------------------------------------------------------
function PixelA8R8G8B8_A4R4G4B4(Color: Longword): Word; stdcall;
const
 x1 = 0; a1 = 8; r1 = 8;  g1 = 8;  b1 = 8;
 a2 = 4; r2 = 4;  g2 = 4;  b2 = 4;
begin
 {$DEFINE PxInDWORD} {$DEFINE PxALPHA} {$DEFINE PxOutWORD}
 {$INCLUDE include\pixasm.inc}
end;

//---------------------------------------------------------------------------
// A8R8G8B8 (32-bit) -> A8R3G3B2 (16-bit)
//---------------------------------------------------------------------------
function PixelA8R8G8B8_A8R3G3B2(Color: Longword): Word; stdcall;
const
 x1 = 0; a1 = 8; r1 = 8;  g1 = 8;  b1 = 8;
 a2 = 8; r2 = 3; g2 = 3;  b2 = 2;
begin
 {$DEFINE PxInDWORD} {$DEFINE PxALPHA} {$DEFINE PxOutWORD}
 {$INCLUDE include\pixasm.inc}
end;

//---------------------------------------------------------------------------
// A8R8G8B8 (32-bit) -> A2R2G2B2 (8-bit)
//---------------------------------------------------------------------------
function PixelA8R8G8B8_A2R2G2B2(Color: Longword): Byte; stdcall;
const
 x1 = 0; a1 = 8; r1 = 8;  g1 = 8;  b1 = 8;
 a2 = 2; r2 = 2; g2 = 2;  b2 = 2;
begin
 {$DEFINE PxInDWORD} {$DEFINE PxALPHA} {$DEFINE PxOutBYTE}
 {$INCLUDE include\pixasm.inc}
end;

//---------------------------------------------------------------------------
// line A8R8G8B8 (32-bit) -> R3G3B2 (8-bit)
//---------------------------------------------------------------------------
procedure LineA8R8G8B8_R3G3B2(Source, Dest: Pointer; Count: Integer); stdcall;
const
 x1 = 0; a1 = 8; r1 = 8;  g1 = 8;  b1 = 8;
         r2 = 3;  g2 = 3;  b2 = 2;
begin
 {$DEFINE PxInDWORD} {$DEFINE PxOutBYTE}
 {$INCLUDE include\lineasm.inc}
end;

//---------------------------------------------------------------------------
// line A8R8G8B8 (32-bit) -> R5G6B5 (16-bit)
//---------------------------------------------------------------------------
procedure LineA8R8G8B8_R5G6B5(Source, Dest: Pointer; Count: Integer); stdcall;
const
 x1 = 0; a1 = 8; r1 = 8;  g1 = 8;  b1 = 8;
         r2 = 5;  g2 = 6;  b2 = 5;
begin
 {$DEFINE PxInDWORD} {$DEFINE PxOutWORD}
 {$INCLUDE include\lineasm.inc}
end;

//---------------------------------------------------------------------------
// line A8R8G8B8 (32-bit) -> X1R5G5B5 (16-bit)
//---------------------------------------------------------------------------
procedure LineA8R8G8B8_X1R5G5B5(Source, Dest: Pointer; Count: Integer); stdcall;
const
 x1 = 0; a1 = 8; r1 = 8;  g1 = 8;  b1 = 8;
         r2 = 5;  g2 = 5;  b2 = 5;
begin
 {$DEFINE PxInDWORD} {$DEFINE PxOutWORD}
 {$INCLUDE include\lineasm.inc}
end;

//---------------------------------------------------------------------------
// line A8R8G8B8 (32-bit) -> X4R4G4B4 (16-bit)
//---------------------------------------------------------------------------
procedure LineA8R8G8B8_X4R4G4B4(Source, Dest: Pointer; Count: Integer); stdcall;
const
 x1 = 0; a1 = 8; r1 = 8;  g1 = 8;  b1 = 8;
         r2 = 4;  g2 = 4;  b2 = 4;
begin
 {$DEFINE PxInDWORD} {$DEFINE PxOutWORD}
 {$INCLUDE include\lineasm.inc}
end;

//---------------------------------------------------------------------------
// line A8R8G8B8 (32-bit) -> A1R5G5B5 (16-bit)
//---------------------------------------------------------------------------
procedure LineA8R8G8B8_A1R5G5B5(Source, Dest: Pointer; Count: Integer); stdcall;
const
 x1 = 0; a1 = 8; r1 = 8;  g1 = 8;  b1 = 8;
 a2 = 1; r2 = 5;  g2 = 5;  b2 = 5;
begin
 {$DEFINE PxInDWORD} {$DEFINE PxALPHA} {$DEFINE PxOutWORD}
 {$INCLUDE include\lineasm.inc}
end;

//---------------------------------------------------------------------------
// line A8R8G8B8 (32-bit) -> A4R4G4B4 (16-bit)
//---------------------------------------------------------------------------
procedure LineA8R8G8B8_A4R4G4B4(Source, Dest: Pointer; Count: Integer); stdcall;
const
 x1 = 0; a1 = 8; r1 = 8;  g1 = 8;  b1 = 8;
 a2 = 4; r2 = 4;  g2 = 4;  b2 = 4;
begin
 {$DEFINE PxInDWORD} {$DEFINE PxALPHA} {$DEFINE PxOutWORD}
 {$INCLUDE include\lineasm.inc}
end;

//---------------------------------------------------------------------------
// line A8R8G8B8 (32-bit) -> A8R3G3B2 (16-bit)
//---------------------------------------------------------------------------
procedure LineA8R8G8B8_A8R3G3B2(Source, Dest: Pointer; Count: Integer); stdcall;
const
 x1 = 0; a1 = 8; r1 = 8;  g1 = 8;  b1 = 8;
 a2 = 8; r2 = 3;  g2 = 3;  b2 = 2;
begin
 {$DEFINE PxInDWORD} {$DEFINE PxALPHA} {$DEFINE PxOutWORD}
 {$INCLUDE include\lineasm.inc}
end;

//---------------------------------------------------------------------------
// line A8R8G8B8 (32-bit) -> A2R2G2B2 (8-bit)
//---------------------------------------------------------------------------
procedure LineA8R8G8B8_A2R2G2B2(Source, Dest: Pointer; Count: Integer); stdcall;
const
 x1 = 0; a1 = 8; r1 = 8;  g1 = 8;  b1 = 8;
 a2 = 2; r2 = 2;  g2 = 2;  b2 = 2;
begin
 {$DEFINE PxInDWORD} {$DEFINE PxALPHA} {$DEFINE PxOutBYTE}
 {$INCLUDE include\lineasm.inc}
end;

//---------------------------------------------------------------------------
procedure Line32Move(Source, Dest: Pointer; Count: Integer); stdcall;
begin
 Move(Source^, Dest^, Count * SizeOf(Longword));
end;

//---------------------------------------------------------------------------
procedure Line24x32(Source, Dest: Pointer; Count: Integer); stdcall;
var
 InPx : PLongword;
 OutPx: PLongword;
 Index: Integer;
begin
 InPx := Source;
 OutPx:= Dest;
 for Index:= 0 to Count - 1 do
  begin
   OutPx^:= $FF000000 or InPx^;
   Inc(InPx);
   Inc(OutPx);
  end;
end;


//---------------------------------------------------------------------------
procedure Line32to8Alpha(Source, Dest: Pointer; Count: Integer); stdcall;
var
 DestPtr: PByte;
 SrcPtr : PLongword;
 Index  : Integer;
begin
 SrcPtr := Source;
 DestPtr:= Dest;
 for Index:= 0 to Count - 1 do
  begin
   DestPtr^:= SrcPtr^ shr 24;

   Inc(SrcPtr);
   Inc(DestPtr);
  end;
end;

//---------------------------------------------------------------------------
procedure Line8to32Alpha(Source, Dest: Pointer; Count: Integer); stdcall;
var
 SrcPtr : PByte;
 DestPtr: PLongword;
 Index  : Integer;
begin
 SrcPtr := Source;
 DestPtr:= Dest;
 for Index:= 0 to Count - 1 do
  begin
   DestPtr^:= (Longword(Byte(SrcPtr^)) shl 24) or $FFFFFF;

   Inc(SrcPtr);
   Inc(DestPtr);
  end;
end;

//---------------------------------------------------------------------------
function PixelXto32(Source: Pointer; SrcFmt: TColorFormat): Longword;
const
 bAnd: array[0..8] of Longword = (0, 1, 3, 7, 15, 31, 63, 127, 255);
var
 Px: Longword;
 Bits: Word;
 RedBits, GreenBits, BlueBits, AlphaBits: Integer;
 Red, Green, Blue, Alpha: Longword;
begin
 Px:= 0;
 Move(Source^, Px, Format2Bytes[SrcFmt]);

 Bits:= Format2Bits[SrcFmt];

 RedBits:= Bits and $F;
 Red  := BitConv32[RedBits, Px and bAnd[RedBits]];

 GreenBits:= (Bits shr 4) and $F;
 Green:= BitConv32[GreenBits, (Px shr RedBits) and bAnd[GreenBits]];

 BlueBits:= (Bits shr 8) and $F;
 Blue:= BitConv32[BlueBits, (Px shr (RedBits + GreenBits)) and bAnd[BlueBits]];

 AlphaBits:= (Bits shr 12) and $F;
 Alpha:= BitConv32[AlphaBits, (Px shr (RedBits + GreenBits + BlueBits)) and bAnd[AlphaBits]];

 Result:= Red or (Green shl 8) or (Blue shl 16) or (Alpha shl 24);
end;

//---------------------------------------------------------------------------
procedure Pixel32toX(Source: Longword; Dest: Pointer; DestFmt: TColorFormat);
begin
 case DestFmt of
  COLOR_R3G3B2  : PByte(Dest)^:= PixelA8R8G8B8_R3G3B2(Source);
  COLOR_R5G6B5  : PWord(Dest)^:= PixelA8R8G8B8_R5G6B5(Source);
  COLOR_X1R5G5B5: PWord(Dest)^:= PixelA8R8G8B8_X1R5G5B5(Source);
  COLOR_X4R4G4B4: PWord(Dest)^:= PixelA8R8G8B8_X4R4G4B4(Source);
  COLOR_A1R5G5B5: PWord(Dest)^:= PixelA8R8G8B8_A1R5G5B5(Source);
  COLOR_A4R4G4B4: PWord(Dest)^:= PixelA8R8G8B8_A4R4G4B4(Source);
  COLOR_A8R3G3B2: PWord(Dest)^:= PixelA8R8G8B8_A8R3G3B2(Source);
  COLOR_A2R2G2B2: PByte(Dest)^:= PixelA8R8G8B8_A2R2G2B2(Source);
  COLOR_X8R8G8B8: PLongword(Dest)^:= Source or $FF000000;
  COLOR_A8R8G8B8: PLongword(Dest)^:= Source;
  COLOR_A8      : PByte(Dest)^:= Source shr 24;
 end;
end;

//---------------------------------------------------------------------------
procedure PixelConv(Source, Dest: Pointer; SrcFormat, DestFormat: TColorFormat);
var
 Pix: Cardinal;
begin
 Pix:= PixelXto32(Source, SrcFormat);
 Pixel32toX(Pix, Dest, DestFormat);
end;

//---------------------------------------------------------------------------
procedure LineConvXto32(Source, Dest: Pointer; Count: Integer;
 SrcFmt: TColorFormat);
var
 i, ReadInc: Integer;
 Read: Pointer;
 Write: PLongword;
begin
 if (SrcFmt = COLOR_X8R8G8B8) then
  begin
   Line24x32(Source, Dest, Count);
  end else
 if (SrcFmt = COLOR_A8R8G8B8) then
  begin
   Move(Source^, Dest^, Count * 4);
   Exit;
  end else
 if (SrcFmt = COLOR_A8) then
  begin
   Line8to32Alpha(Source, Dest, Count);
   Exit;
  end;

 Read:= Source;
 ReadInc:= Format2Bytes[SrcFmt];
 Write:= Dest;

 for i:= 0 to Count - 1 do
  begin
   Write^:= PixelXto32(Read, SrcFmt);
   Inc(Write);
   Inc(Integer(Read), ReadInc);
  end;
end;

//---------------------------------------------------------------------------
function GetLineConv32toX(Dest: TColorFormat): TLineConvFunc;
begin
 case Dest of
  COLOR_R3G3B2  : Result:= LineA8R8G8B8_R3G3B2;
  COLOR_R5G6B5  : Result:= LineA8R8G8B8_R5G6B5;
  COLOR_X1R5G5B5: Result:= LineA8R8G8B8_X1R5G5B5;
  COLOR_X4R4G4B4: Result:= LineA8R8G8B8_X4R4G4B4;
  COLOR_A1R5G5B5: Result:= LineA8R8G8B8_A1R5G5B5;
  COLOR_A4R4G4B4: Result:= LineA8R8G8B8_A4R4G4B4;
  COLOR_A8R3G3B2: Result:= LineA8R8G8B8_A8R3G3B2;
  COLOR_A2R2G2B2: Result:= LineA8R8G8B8_A2R2G2B2;
  COLOR_X8R8G8B8: Result:= Line24x32;
  COLOR_A8R8G8B8: Result:= Line32Move;
  COLOR_A8      : Result:= Line32to8Alpha;
  else Result:= nil;
 end;
end;

//---------------------------------------------------------------------------
function DisplaceRB(Color: Cardinal): Cardinal; stdcall;
asm
 mov eax, Color
 mov ecx, eax
 mov edx, eax
 and eax, 0FF00FF00h
 and edx, 0000000FFh
 shl edx, 16
 or eax, edx
 mov edx, ecx
 shr edx, 16
 and edx, 0000000FFh
 or eax, edx
 mov Result, eax
end;

//---------------------------------------------------------------------------
function Color2Real(Color: Longword): TRealColor;
begin
 Result.r:= (Color and $FF) / 255.0;
 Result.g:= ((Color shr 8) and $FF) / 255.0;
 Result.b:= ((Color shr 16) and $FF) / 255.0;
 Result.a:= ((Color shr 24) and $FF) / 255.0;
end;

//---------------------------------------------------------------------------
function Real2Color(Pix: TRealColor): Longword;
begin
 Result:= Round(Pix.r * 255.0) + (Round(Pix.g * 255.0) shl 8) +
  (Round(Pix.b * 255.0) shl 16) + (Round(Pix.a * 255.0) shl 24);
end;

//---------------------------------------------------------------------------
function Linear2Sine(Alpha: Real): Real;
const
 PiHalf = Pi / 2.0;
begin
 Result:= (Sin((Alpha * Pi) - PiHalf) + 1.0) / 2.0;
end;

//---------------------------------------------------------------------------
procedure LineConvMasked(Source, Dest: Pointer; Count, Tolerance: Integer;
 ColorMask: Cardinal);
const
 Delta2Dist = 57.73502692;
 DeltaMin = 0.025;
var
 InPx, OutPx: PLongword;
 Color, cMask: TRealColor;
 i: Integer;
 Delta, DeltaMax: Real;
begin
 InPx:= Source;
 OutPx:= Dest;
 cMask:= Color2Real(DisplaceRB(ColorMask));

 DeltaMax:= (Abs(Tolerance) / Delta2Dist) + DeltaMin;

 for i:= 0 to Count - 1 do
  begin
   // retreive real color
   Color:= Color2Real(DisplaceRB(InPx^));

   // calculate the difference (in %)
   Delta:= Sqrt(Sqr(Color.r - cMask.r) + Sqr(Color.g - cMask.g) + Sqr(Color.b - cMask.b));

   // based on distance, find the specified alpha-channel
   Color.a:= 1.0;
   if (Delta <= DeltaMax) then
    Color.a:= Linear2Sine(Delta / DeltaMax);

   // write final pixel
   OutPx^:= DisplaceRB(Real2Color(Color));

   // advance in pixel list
   Inc(InPx);
   Inc(OutPx);
  end;
end;

//---------------------------------------------------------------------------
end.

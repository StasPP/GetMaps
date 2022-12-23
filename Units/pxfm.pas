unit pxfm;
//---------------------------------------------------------------------------
// pxfm.pas                                             Modified: 12-Oct-2005
// Asphyre Pixel Format (pxfm)                                   Version 1.01
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
 Types, Classes, SysUtils, Graphics, AsphyreDef, AsphyreConv2;

//---------------------------------------------------------------------------
type
//---------------------------------------------------------------------------
// PXFM Structure
//---------------------------------------------------------------------------
 TPxFm = packed record
  Format       : TColorFormat;
  PatternWidth : Integer;
  PatternHeight: Integer;
  VisibleWidth : Integer;
  VisibleHeight: Integer;
  PatternCount : Integer;
  TextureWidth : Integer;
  TextureHeight: Integer;
  TextureCount : Integer;
 end;

//---------------------------------------------------------------------------
// WriteBitmapPxFm()
//
// Saves bitmap and the specified PxFm structure in the stream.
//---------------------------------------------------------------------------
function WriteBitmapPxFm(Stream: TStream; Source: TBitmap; PxFm: TPxFm): Boolean;

//---------------------------------------------------------------------------
// ReadBitmapPxFm()
//
// Load PxFm structure and then attempt to load pixel data to the specified
// bitmap, applying scanline conversion if necessary.
//
// NOTICE: This function removes the vertical gaps in textures providing
// linear access to the image.
//---------------------------------------------------------------------------
function ReadBitmapPxFm(Stream: TStream; Dest: TBitmap; out PxFm: TPxFm): Boolean;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
function WriteBitmapPxFm(Stream: TStream; Source: TBitmap; PxFm: TPxFm): Boolean;
var
 LineConv: TLineConvFunc;
 AuxMem  : Pointer;
 AuxSize : Integer;
 Index   : Integer;
begin
 Result:= True;

 // (1) Write PxFm header to the stream.
 if (Stream.Write(PxFm, SizeOf(PxFm)) <> SizeOf(PxFm)) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Retreive pixel conversion function.
 LineConv:= GetLineConv32toX(PxFm.Format);

 // (3) Allocate auxiliary memory for pixel conversion.
 AuxSize:= PxFm.TextureWidth * Format2Bytes[PxFm.Format];
 AuxMem := AllocMem(AuxSize);

 // (4) Convert pixel data and write it to the stream.
 try
  for Index:= 0 to Source.Height - 1 do
   begin
    LineConv(Source.ScanLine[Index], AuxMem, PxFm.TextureWidth);
    Stream.WriteBuffer(AuxMem^, AuxSize);
   end;
 except
  Result:= False;
 end;

 // (5) Release auxiliary memory.
 FreeMem(AuxMem);
end;

//---------------------------------------------------------------------------
function ReadBitmapPxFm(Stream: TStream; Dest: TBitmap; out PxFm: TPxFm): Boolean;
var
 Index  : Integer;
 AuxMem : Pointer;
 AuxSize: Integer;
 VDepth : Integer;
 TexIndx: Integer;
 VIndex : Integer;
begin
 Result:= True;

 // (1) Load PxFm header.
 if (Stream.Read(PxFm, SizeOf(PxFm)) <> SizeOf(PxFm)) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Real vertical depth (excludes the gap).
 VDepth:= (PxFm.TextureHeight div PxFm.PatternHeight) * PxFm.PatternHeight;

 // (3) Apply bitmap size.
 Dest.Width := PxFm.TextureWidth;
 Dest.Height:= VDepth * PxFm.TextureCount;
 if (Dest.PixelFormat <> pf32bit) then Dest.PixelFormat:= pf32bit;

 // (4) Allocate auxiliary memory.
 AuxSize:= Dest.Width * Format2Bytes[PxFm.Format];
 AuxMem := AllocMem(AuxSize);

 // (5) Load pixel data.
 VIndex:= 0;
 for TexIndx:= 0 to PxFm.TextureCount - 1 do
  for Index:= 0 to PxFm.TextureHeight - 1 do
   begin
    if (Stream.Read(AuxMem^, AuxSize) <> AuxSize) then
     begin
      Result:= False;
      Break;
     end;

    if (Index < VDepth) then
     begin
      LineConvXto32(AuxMem, Dest.Scanline[VIndex], Dest.Width, PxFm.Format);
      Inc(VIndex);
     end;
   end;

 // (6) Release auxiliary memory.
 FreeMem(AuxMem);
end;

//---------------------------------------------------------------------------
end.

unit AsphyreBmpLoad;
//---------------------------------------------------------------------------
// AsphyreBmpLoad.pas                                   Modified: 17-Oct-2005
// Generic Bitmap loading for Asphyre                            Version 1.01
//---------------------------------------------------------------------------
// Changes since v1.0:
//   * ColorFmtBytes[] to Format2Bytes[] in line 162.
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
 Types, Classes, SysUtils, Graphics, AsphyreDef, AsphyreTGA, AsphyreJPG,
 AsphyrePNG, AsphyreDb, AsphyreConv2;

//---------------------------------------------------------------------------
type
 TImageFormat = (ifBMP, ifTGA, ifJPEG, ifPNG, ifAuto);

//---------------------------------------------------------------------------
// LoadBitmap()
//
// Loads generalized image format from stream or file.
//---------------------------------------------------------------------------
function LoadBitmap(Stream: TStream; Dest: TBitmap;
 Format: TImageFormat): Boolean; overload;
function LoadBitmap(const FileName: string; Dest: TBitmap;
 Format: TImageFormat = ifAuto): Boolean; overload;
function LoadBitmap(const Key: string; Dest: TBitmap;
 ASDb: TASDb): Boolean; overload;

//---------------------------------------------------------------------------
// SaveBitmap()
//
// Saves bitmap to generalized image format with default/recommended options.
//---------------------------------------------------------------------------
function SaveBitmap(Stream: TStream; Source: TBitmap;
 Format: TImageFormat): Boolean; overload;
function SaveBitmap(const FileName: string; Source: TBitmap;
 Format: TImageFormat = ifAuto): Boolean; overload;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
function FormatFromName(const FileName: string): TImageFormat;
var
 ext: string;
begin
 Result:= ifBmp;
 ext:= ExtractFileExt(FileName);

 if (SameText(ext, '.tga')) then Result:= ifTGA;
 if (SameText(ext, '.jpg'))or(SameText(ext, '.jpeg')) then Result:= ifJPEG;
 if (SameText(ext, '.png')) then Result:= ifPNG;
end;

//---------------------------------------------------------------------------
function LoadBitmap(Stream: TStream; Dest: TBitmap;
 Format: TImageFormat): Boolean; overload;
begin
 case Format of
  // Windows Bitmap
  ifBMP:
   begin
    Result:= True;
    try
     Dest.LoadFromStream(Stream);
    except
     Result:= False;
    end;
   end;
  // Truevision TARGA
{  ifTGA:
   Result:= LoadTGAtoBMP(Stream, Dest);}
  // JPEG
  ifJPEG:
   Result:= LoadJPGtoBMP(Stream, Dest);
  // Portable Network Graphics
  ifPNG:
   Result:= LoadPNGtoBMP(Stream, Dest);
  else
   Result:= False;
 end;
end;

//---------------------------------------------------------------------------
function LoadBitmap(const FileName: string; Dest: TBitmap;
 Format: TImageFormat): Boolean; overload;
begin
 if (Format = ifAuto) then
  Format:= FormatFromName(FileName);

 case Format of
  // Windows Bitmap
  ifBMP:
   begin
    Result:= True;
    try
     Dest.LoadFromFile(FileName);
    except
     Result:= False;
    end;
   end;
  // Truevision TARGA
{  ifTGA:
   Result:= LoadTGAtoBMP(FileName, Dest);}
  // JPEG
  ifJPEG:
   Result:= LoadJPGtoBMP(FileName, Dest);
  // Portable Network Graphics
  ifPNG:
   Result:= LoadPNGtoBMP(FileName, Dest);
  else
   Result:= False;
 end;
end;

//---------------------------------------------------------------------------
function LoadPxFm(const Key: string; Dest: TBitmap; ASDb: TASDb): Boolean;
var
 Index   : Integer;
 TexSize : TPoint;
 TexCount: Integer;
 Stream  : TStream;
 InFormat: TColorFormat;
 AuxMem  : Pointer;
 AuxSize : Integer;
begin
 // Step 1. Load source record
 Stream:= TMemoryStream.Create();
 Result:= ASDb.ReadStream(Key, Stream);
 if (not Result) then
  begin
   Stream.Free();
   Exit;
  end;

 // Step 2. Load pixel data 
 Stream.Seek(0, soFromBeginning);
 try
  Stream.ReadBuffer(InFormat, SizeOf(TColorFormat));
  Stream.Seek(20, soFromCurrent); // PatternSize, VisibleSize and PatternCount
  Stream.ReadBuffer(TexSize,  SizeOf(TPoint));
  Stream.ReadBuffer(TexCount, SizeOf(Integer));
 except
  Result:= False;
  Stream.Free();
  Exit;
 end;

 // Step 3. Allocate auxiliary memory
 AuxSize:= TexSize.X * Format2Bytes[InFormat];
 AuxMem := AllocMem(AuxSize);

 // Step 4. Define bitmap parameters
 Dest.Width := TexSize.X;
 Dest.Height:= TexSize.Y * TexCount;
 if (Dest.PixelFormat <> pf32bit) then Dest.PixelFormat:= pf32bit;

 // Step 5. Read scanline data
 for Index:= 0 to Dest.Height - 1 do
  begin
   Stream.Read(AuxMem^, AuxSize);
   LineConvXto32(AuxMem, Dest.ScanLine[Index], TexSize.X, InFormat);
  end;

 // Step 6. Release the allocated memory and stream
 FreeMem(AuxMem);
 Stream.Free();
end;

//---------------------------------------------------------------------------
function LoadFromASDb(const Key: string; Dest: TBitmap; ASDb: TASDb): Boolean;
var
 Stream: TStream;
begin
 Stream:= TMemoryStream.Create();

 Result:= ASDb.ReadStream(Key, Stream);
 if (not Result) then
  begin
   Stream.Free();
   Exit;
  end;

 Stream.Seek(0, soFromBeginning);
 Result:= LoadBitmap(Stream, Dest, FormatFromName(Key));

 Stream.Free();
end;

//---------------------------------------------------------------------------
function LoadBitmap(const Key: string; Dest: TBitmap;
 ASDb: TASDb): Boolean; overload;
var
 Index: Integer;
begin
 // (1) Update ASDb archive.
 Result:= ASDb.UpdateOnce();
 if (not Result) then Exit;

 // (2) Find record index.
 Index:= ASDb.RecordNum[Key];
 if (Index = -1) then
  begin
   Result:= False;
   Exit;
  end;

 // (3) Determine whether record is PXFM or embedded image
 if (ASDb.RecordType[Index] = recGraphics) then
  Result:= LoadPxFm(Key, Dest, ASDb) else Result:= LoadFromASDb(Key, Dest, ASDb);
end;

//---------------------------------------------------------------------------
function SaveBitmap(Stream: TStream; Source: TBitmap;
 Format: TImageFormat): Boolean; overload;
begin
 case Format of
  // Windows Bitmap
  ifBMP:
   begin
    Result:= True;
    try
     Source.SaveToStream(Stream);
    except
     Result:= False;
    end;
   end;
  // Truevision TARGA
  {ifTGA:
   Result:= SaveBMPtoTGA(Stream, Source, [tfCompressed]);}
  // JPEG
  ifJPEG:
   Result:= SaveBMPtoJPG(Stream, Source, [jfProgressive], 90);
  // Portable Network Graphics
  ifPNG:
   Result:= SaveBMPtoPNG(Stream, Source, 9);
  else
   Result:= False;
 end;
end;

//---------------------------------------------------------------------------
function SaveBitmap(const FileName: string; Source: TBitmap;
 Format: TImageFormat): Boolean; overload;
begin
 if (Format = ifAuto) then
  Format:= FormatFromName(FileName);

 case Format of
  // Windows Bitmap
  ifBMP:
   begin
    Result:= True;
    try
     Source.SaveToFile(FileName);
    except
     Result:= False;
    end;
   end;
  // Truevision TARGA
{  ifTGA:
   Result:= SaveBMPtoTGA(FileName, Source, [tfCompressed]);}
  // JPEG
  ifJPEG:
   Result:= SaveBMPtoJPG(FileName, Source, [jfProgressive], 87);
  // Portable Network Graphics
  ifPNG:
   Result:= SaveBMPtoPNG(FileName, Source, 9);
  else
   Result:= False;
 end;
end;

//---------------------------------------------------------------------------
end.

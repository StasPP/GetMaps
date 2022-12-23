unit AsphyreImages;
//---------------------------------------------------------------------------
// AsphyreImages.pas                                    Modified: 03-Oct-2005
// Copyright (c) 2000 - 2005  Afterwarp Interactive               Version 1.2
//---------------------------------------------------------------------------
// Changes since v1.00:
//  * In "LoadFromFile" method TextureCount was not set correctly. Fixed.
//    Thanks to Cashchin for reporting this bug!
//
// Changes since v1.04:
//  * The image was blurred when ViewSize differed from PatternSize by
//    non-even value (e.g. 1). To fix this, changed all floating-point
//    divisions by integer ones.
//  + Added Image access by Name (non case-sensitive)
//  * Fixed LoadFromStream memory leak when stream error is encountered
//  * Improved the performance when loading images
//  + Added support for loading images in different pixel formats
//  * When no pixel conversion is needed, the images are loaded directly
//    to the video memory now (loading will be faster now!)
//
// Changes since v1.1:
//  * VisibleSize can now be changed in run-time in case additional
//    padding is required after the image has been added to ASDb.
//
// Changes since v1.11:
//  * AddFromFile method fixed to update image name from key.
//
// Changes since v1.12:
//  * Now using new version of DXTextures.pas
//  * New format heuristics: Quality and Alpha-Level.
//  + Pixels property added for direct access.
//  * Better Lost Device handling, although unnecessary.
//  * Replaced all error codes by Booleans, since errors are usually
//    context-specific.
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
 Windows, Types, Classes, SysUtils, Math, Graphics, DXBase, Direct3D9,
 AsphyreDef, AsphyreBmpLoad, AsphyreDb, AsphyreConv, ImageFx, DXTextures,
 AsphyreDevices;

//---------------------------------------------------------------------------
type
 TImageASDbLoadEvent = procedure(Sender: TObject; const Key: string;
  Index: Integer; var Accept: Boolean; var Name: string;
  var Quality: TAsphyreQuality; var AlphaLevel: TAlphaLevel) of object;

//---------------------------------------------------------------------------
 TAsphyreImage = class(TDXMultiTexture)
 private
  FName: string;
  FQuality: TAsphyreQuality;
  FAlphaLevel: TAlphaLevel;

  FImagesInRow: Integer;
  FImagesInCol: Integer;
  FImagesInTex: Integer;

  FVisibleSize : TPoint;
  FPatternSize : TPoint;
  FPatternCount: Integer;

  procedure SetQuality(const Value: TAsphyreQuality);
  procedure SetAlphaLevel(const Value: TAlphaLevel);
  procedure SetSize(const Index: Integer; const Value: TPoint);
  procedure SetPatternCount(const Value: Integer);
  function UpdateInfo(): Boolean;
  function FormatMatch(Source, Dest: TColorFormat): Boolean;
  function GetPixel(X, Y, Num: Integer): Cardinal;
  procedure SetPixel(X, Y, Num: Integer; const Value: Cardinal);
 protected
  function Prepare(): Boolean; override;
 public
  //-------------------------------------------------------------------------
  // The name of individual image. Should be unique, although this is the
  // responsibility of the programmer.
  //
  // Note: When loading from ASDb, this name is set automatically to match
  // record key.
  //-------------------------------------------------------------------------
  property Name: string read FName write FName;

  //-------------------------------------------------------------------------
  // The desired quality of image. The pixel format will be choosen to
  // correspond the level of quality specified here.
  //-------------------------------------------------------------------------
  property Quality: TAsphyreQuality read FQuality write SetQuality;

  //-------------------------------------------------------------------------
  // The desired alpha-channel support. The pixel format will be choosen to
  // comply with the requirements of alpha-channel.
  //-------------------------------------------------------------------------
  property AlphaLevel: TAlphaLevel read FAlphaLevel write SetAlphaLevel;

  //-------------------------------------------------------------------------
  // Direct access to image pixel data.
  //-------------------------------------------------------------------------
  property Pixels[X, Y, Num: Integer]: Cardinal read GetPixel write SetPixel;

  //-------------------------------------------------------------------------
  // Information about how many patterns are placed in a single texture.
  //-------------------------------------------------------------------------
  property ImagesInRow: Integer read FImagesInRow;
  property ImagesInCol: Integer read FImagesInCol;
  property ImagesInTex: Integer read FImagesInTex;

  //-------------------------------------------------------------------------
  // Pattern characteristics.
  //-------------------------------------------------------------------------
  property VisibleSize : TPoint index 0 read FVisibleSize write SetSize;
  property PatternSize : TPoint index 1 read FPatternSize write SetSize;
  property PatternCount: Integer read FPatternCount write SetPatternCount;

  function SelectTexture(TexCoord: TTexCoord; out Points: TPoint4;
   out TexNum: Integer): Boolean;

  function LoadFromBitmap(Source: TBitmap; NeedMasked: Boolean;
   MaskedColor: Longword; Tolerance: Integer): Boolean;

  function LoadFromFile(const Filename: string; NeedMasked: Boolean;
   MaskedColor: Longword; Tolerance: Integer): Boolean;

  function LoadFromStream(Stream: TStream): Boolean;
  function LoadFromASDb(const Key: string; ASDb: TASDb): Boolean;

  constructor Create(); override;
 end;

//---------------------------------------------------------------------------
 TAsphyreImages = class(TAsphyreDeviceSubscriber)
 private
  Data: array of TAsphyreImage;
  FMipMapping: Boolean;
  FOnASDbLoad: TImageASDbLoadEvent;

  function GetCount(): Integer;
  function GetItem(Num: Integer): TAsphyreImage;
  function FindByName(Name: string): TAsphyreImage;
  function GetImage(const Name: string): TAsphyreImage;
 protected
  function HandleNotice(Msg: Cardinal): Boolean; override;
 public
  property Count: Integer read GetCount;
  property Item[Num: Integer]: TAsphyreImage read GetItem; default;
  property Image[const Name: string]: TAsphyreImage read GetImage;

  //-------------------------------------------------------------------------
  // Add new image to the list *without* initializing it.
  //-------------------------------------------------------------------------
  function Add(): TAsphyreImage;

  //-------------------------------------------------------------------------
  // Finds an existing image in the list and returns its index.
  //-------------------------------------------------------------------------
  function Find(Image: TAsphyreImage): Integer; overload;
  function Find(Name: string): Integer; overload;

  //-------------------------------------------------------------------------
  // Removes the image from the list at the specified index.
  //-------------------------------------------------------------------------
  procedure Remove(Index: Integer);

  //-------------------------------------------------------------------------
  // Add and load animated image from ASDb archive.
  //-------------------------------------------------------------------------
  function AddFromASDb(const Key: string; ASDb: TASDb;
   Quality: TAsphyreQuality; AlphaLevel: TAlphaLevel): Boolean;

  //-------------------------------------------------------------------------
  // Add and load animated image from external file.
  //-------------------------------------------------------------------------
  function AddFromFile(const Filename: string; const VisibleSize,
   PatternSize, TextureSize: TPoint; Quality: TAsphyreQuality;
   AlphaLevel: TAlphaLevel; NeedMasked: Boolean; MaskedColor: Longword;
   Tolerance: Integer): Boolean;

  //-------------------------------------------------------------------------
  // Removes any loaded images from the list.
  //-------------------------------------------------------------------------
  procedure RemoveAll();

  //-------------------------------------------------------------------------
  // Loads any supported images from the ASDb archive.
  // Optionally, calls OnASDbLoad event to confirm every loadable image.
  //-------------------------------------------------------------------------
  function LoadFromASDb(ASDb: TASDb): Boolean;

  constructor Create(AOwner: TComponent); override;
  destructor Destroy(); override;
 published
  // confirmation event called by LoadFromASDb
  property OnASDbLoad : TImageASDbLoadEvent read FOnASDbLoad write FOnASDbLoad;

  // whether to turn automatic Mipmap generation for every image
  property MipMappping: Boolean read FMipMapping write FMipMapping;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TAsphyreImage.Create();
begin
 inherited;

 FName:= '[unnamed]';
 FQuality:= aqHigh;
 FAlphaLevel:= alFull;

 FVisibleSize := Point(0, 0);
 FPatternSize := Point(0, 0);
 FPatternCount:= 0;
end;

//---------------------------------------------------------------------------
procedure TAsphyreImage.SetQuality(const Value: TAsphyreQuality);
begin
 if (FState = tsNotReady) then FQuality:= Value;
end;

//---------------------------------------------------------------------------
procedure TAsphyreImage.SetAlphaLevel(const Value: TAlphaLevel);
begin
 if (FState = tsNotReady) then FAlphaLevel:= Value;
end;

//---------------------------------------------------------------------------
procedure TAsphyreImage.SetSize(const Index: Integer; const Value: TPoint);
begin
 case Index of
  0: FVisibleSize:= Value;
  1: if (FState = tsNotReady) then FPatternSize:= Value;
 end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreImage.SetPatternCount(const Value: Integer);
begin
 if (FState = tsNotReady) then FPatternCount:= Value;
end;

//---------------------------------------------------------------------------
function TAsphyreImage.GetPixel(X, Y, Num: Integer): Cardinal;
var
 Access: TDXAccessInfo;
 PPixel: Pointer;
begin
 // (1) Lock the desired texture.
 if (not Lock(Num, lfReadOnly, Access)) then
  begin
   Result:= 0;
   Exit;
  end;

 // (2) Get pointer to the requested pixel. 
 PPixel:= Pointer(Integer(Access.Bits) + (Access.Pitch * Y) +
  (X * Format2Bytes[Access.Format]));

 // (3) Apply format conversion.
 Result:= DisplaceRB(PixelXto32(PPixel, Access.Format));

 // (4) Unlock the texture.
 Unlock(Num);
end;

//---------------------------------------------------------------------------
procedure TAsphyreImage.SetPixel(X, Y, Num: Integer; const Value: Cardinal);
var
 Access: TDXAccessInfo;
 PPixel: Pointer;
begin
 // (1) Lock the desired texture.
 if (not Lock(Num, lfWriteOnly, Access)) then Exit;

 // (2) Get pointer to the requested pixel.
 PPixel:= Pointer(Integer(Access.Bits) + (Access.Pitch * Y) +
  (X * Format2Bytes[Access.Format]));

 // (3) Apply format conversion.
 Pixel32toX(DisplaceRB(Value), PPixel, Access.Format);

 // (4) Unlock the texture.
 Unlock(Num);
end;

//---------------------------------------------------------------------------
function TAsphyreImage.UpdateInfo(): Boolean;
begin
 Result:= True;

 // validate pattern size
 if (FPatternSize.X < 1) then FPatternSize.X:= Size.X;
 if (FPatternSize.Y < 1) then FPatternSize.Y:= Size.Y;

 // validate visible size
 if (FVisibleSize.X < 1) then FVisibleSize.X:= Size.X;
 if (FVisibleSize.Y < 1) then FVisibleSize.Y:= Size.Y;

 // check if the specified values appear correct
 if (Size.X < 1)or(Size.Y < 1)or(FPatternSize.X > Size.X)or
  (FPatternSize.Y > Size.Y)or(FVisibleSize.X > FPatternSize.X)or
  (FVisibleSize.Y > FPatternSize.Y) then
  begin
   Result:= False;
   Exit;
  end;

 // calculate the remaining values
 FImagesInRow:= Size.X div FPatternSize.X;
 FImagesInCol:= Size.Y div FPatternSize.Y;
 FImagesInTex:= FImagesInRow * FImagesInCol;

 if (FPatternCount < 1) then
  FPatternCount:= FImagesInTex * TextureCount;
end;

//---------------------------------------------------------------------------
function TAsphyreImage.Prepare(): Boolean;
begin
 // (1) Update image information.
 Result:= UpdateInfo();

 // (2) Determine pixel format.
 if (Result) then
  begin
   FFormat:= DXApproxFormat(FQuality, FAlphaLevel, RetreiveUsage());
   Result := (FFormat <> D3DFMT_UNKNOWN);
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreImage.LoadFromBitmap(Source: TBitmap; NeedMasked: Boolean;
 MaskedColor: Longword; Tolerance: Integer): Boolean;
var
 Target  : TBitmap;
 Index   : Integer;
 ScanIndx: Integer;
 LineConv: TLineConvFunc;
 AuxMem  : Pointer;
 Access  : TDXAccessInfo;
begin
 Result:= True;
 
 // (1) Prepare the image by tiling it on texture.
 Target:= TBitmap.Create();
 TileBitmap(Target, Source, Size, PatternSize, PatternSize, NeedMasked,
  MaskedColor, Tolerance);

 // (2) Self-Initialize.
 TextureCount:= Ceil(Target.Height / Size.Y);
 ChangeState(tsReady);
 if (FState <> tsReady) then
  begin
   Result:= False;
   Target.Free();
   Exit;
  end;

 // (3) Retreive pixel format conversion function.
 LineConv:= GetLineConv32toX(D3DToFormat(FFormat));

 // (4) Upload pixel data with conversion.
 for Index:= 0 to TextureCount - 1 do
  begin
   // 4.1: lock the texture
   if (not Lock(Index, lfWriteOnly, Access)) then
    begin
     Result:= False;
     Break;
    end;

   // 4.2: upload scanline data
   for ScanIndx:= 0 to Size.Y - 1 do
    begin
     // -> pointer to a single scanline
     AuxMem:= Target.Scanline[(Index * Size.Y) + ScanIndx];

     // -> apply scanline conversion
     LineConv(AuxMem, Access.Bits, Size.X);

     // -> adjust pointers
     Inc(Integer(Access.Bits), Access.Pitch);
    end;

   // 4.3: unlock the texture
   Unlock(Index);
  end;

 // (5) Release the memory.
 Target.Free();
end;

//---------------------------------------------------------------------------
function TAsphyreImage.LoadFromFile(const Filename: string; NeedMasked: Boolean;
 MaskedColor: Longword; Tolerance: Integer): Boolean;
var
 Bmp: TBitmap;
begin
 Bmp:= TBitmap.Create();
 Result:= LoadBitmap(FileName, Bmp, ifAuto);
 if (not Result) then
  begin
   Bmp.Free();
   Exit;
  end;

 Result:= LoadFromBitmap(Bmp, NeedMasked, MaskedColor, Tolerance);
 Bmp.Free();
end;

//---------------------------------------------------------------------------
function TAsphyreImage.FormatMatch(Source, Dest: TColorFormat): Boolean;
const
 Format32 = [COLOR_X8R8G8B8, COLOR_A8R8G8B8];
 Format16 = [COLOR_X4R4G4B4, COLOR_A4R4G4B4];
begin
 Result:= (Source = Dest)or((Source in Format16)and(Dest in Format16))or
  ((Source in Format32)and(Dest in Format32));
end;

//---------------------------------------------------------------------------
function TAsphyreImage.LoadFromStream(Stream: TStream): Boolean;
var
 InFormat : TColorFormat;
 ATexSize : TPoint;
 ATexCount: Integer;
 Access   : TDXAccessInfo;
 Index    : Integer;
 ScanIndx : Integer;
 LineConv : TLineConvFunc;
 AuxMem32 : Pointer;
 AuxMemIn : Pointer;
 SizeIn   : Integer;
 Size32   : Integer;
begin
 Result:= True;

 // (1) Load texture information.
 try
  Stream.ReadBuffer(InFormat,      SizeOf(TColorFormat));
  Stream.ReadBuffer(FPatternSize,  SizeOf(TPoint));
  Stream.ReadBuffer(FVisibleSize,  SizeOf(TPoint));
  Stream.ReadBuffer(FPatternCount, SizeOf(Integer));
  Stream.ReadBuffer(ATexSize,      SizeOf(TPoint));
  Stream.ReadBuffer(ATexCount,     SizeOf(Integer));

  Size:= ATexSize;
  TextureCount:= ATexCount;
 except
  Result:= False;
  Exit;
 end;

 // (2) Self-initialize.
 ChangeState(tsReady);
 if (FState <> tsReady) then
  begin
   Result:= False;
   Exit;
  end;

 // (3) Retreive pixel format conversion function.
 LineConv:= GetLineConv32toX(D3DToFormat(FFormat));

 // (4) Allocate temporary memory, if necessary.
 SizeIn:= Size.X * Format2Bytes[InFormat];
 Size32:= Size.X * 4;
 AuxMem32:= nil;
 AuxMemIn:= nil;
 if (not FormatMatch(InFormat, D3DToFormat(FFormat))) then
  begin
   if (InFormat <> COLOR_A8R8G8B8) then AuxMemIn:= AllocMem(SizeIn);
   AuxMem32:= AllocMem(Size32);
  end;

 // (5) Read pixel information.
 for Index:= 0 to ATexCount - 1 do
  begin
   // 5.1: lock the texture
   if (not Lock(Index, lfWriteOnly, Access)) then
    begin
     Result:= False;
     Break;
    end;

   // 5.2: upload scanline data
   for ScanIndx:= 0 to Size.Y - 1 do
    begin
     // 5.2.1: read a single scanline
     if (AuxMem32 <> nil) then
      begin
       // -> apply scanline conversion
       if (AuxMemIn <> nil) then
        begin // --> X to 32-bit to Y (indirect)
         if (Stream.Read(AuxMemIn^, SizeIn) <> SizeIn) then
          begin
           Result:= False;
           Break;
          end;

         // convert X to 32-bit
         LineConvXto32(AuxMemIn, AuxMem32, Size.X, InFormat);

         // convert 32-bit to Y
         LineConv(AuxMem32, Access.Bits, Size.X);
        end else
        begin // --> 32-bit to X (semi-direct)
         if (Stream.Read(AuxMem32^, Size32) <> Size32) then
          begin
           Result:= False;
           Break;
          end;

         LineConv(AuxMem32, Access.Bits, Size.X);
        end;
      end else
      begin
       // -> read directly to video memory
       if (Stream.Read(Access.Bits^, SizeIn) <> SizeIn) then
        begin
         Result:= False;
         Break;
        end;
      end;

     // -> adjust pointers
     Inc(Integer(Access.Bits), Access.Pitch);
    end;

   // (6) Unlock the texture.
   if (Result) then Unlock(Index);

   if (not Result) then Break;
  end;

 // (7) Release the memory.
 if (AuxMemIn <> nil) then FreeMem(AuxMemIn);
 if (AuxMem32 <> nil) then FreeMem(AuxMem32);

 // (8) Update the state, in case of error.
 if (not Result) then ChangeState(tsNotReady);
end;

//---------------------------------------------------------------------------
function TAsphyreImage.LoadFromASDb(const Key: string; ASDb: TASDb): Boolean;
var
 Stream: TMemoryStream;
begin
 Stream:= TMemoryStream.Create();

 // (1) Make sure ASDb is up-to-date.
 Result:= ASDb.UpdateOnce();
 if (not Result) then Exit;

 // (2) Read the requested record as stream.
 Result:= ASDb.ReadStream(Key, Stream);
 if (not Result) then
  begin
   Stream.Free();
   Exit;
  end;

 // (3) Load graphics data from stream.
 Stream.Seek(0, soFromBeginning);
 Result:= LoadFromStream(Stream);

 // (4) Release the stream.
 Stream.Free();
end;

//---------------------------------------------------------------------------
function TAsphyreImage.SelectTexture(TexCoord: TTexCoord;
 out Points: TPoint4; out TexNum: Integer): Boolean;
var
 Index  : Integer;
 AddSize: TPoint;
 Source : TPoint;
 u1, v1 : Real;
 u2, v2 : Real;
begin
 // (1) Verify conditions.
 if (FState = tsNotReady)or(TextureCount < 1)or(FPatternCount < 1) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Clip pattern into the valid range.
 if (TexCoord.Pattern < 0) then TexCoord.Pattern:= 0;
 if (TexCoord.Pattern > FPatternCount - 1) then
  TexCoord.Pattern:= FPatternCount - 1;

 // (3) Texture number & pattern index in this texture.
 TexNum:= TexCoord.Pattern div FImagesInTex;
 Index := TexCoord.Pattern mod FImagesInTex;
 
 // (4) Centered information.
 AddSize.X:= (PatternSize.X - VisibleSize.X) div 2;
 AddSize.Y:= (PatternSize.Y - VisibleSize.Y) div 2;

 // (5) Source coordinates.
 Source.X:= ((Index mod FImagesInRow) * PatternSize.X) +
  Round(TexCoord.x) + AddSize.X;
 Source.Y:= (((Index div FImagesInRow) mod FImagesInCol) * PatternSize.Y) +
  Round(TexCoord.y) + AddSize.Y;

 // (6) u/v coordinates in range [0..1]
 u1:= Source.X / Size.X;
 v1:= Source.Y / Size.Y;
 if (TexCoord.w > 0) then
  u2:= ((Source.X + TexCoord.w) / Size.X)
   else u2:= ((Source.X + VisibleSize.X) / Size.X);

 if (TexCoord.h > 0) then
  v2:= ((Source.Y + TexCoord.h) / Size.Y)
   else v2:= ((Source.Y + VisibleSize.Y) / Size.Y);

 // (7) Mirror & flip effects.
 if (TexCoord.Mirror) then
  begin
   Points[0].x:= u2;
   Points[1].x:= u1;
   Points[3].x:= u2;
   Points[2].x:= u1;
  end else
  begin
   Points[0].x:= u1;
   Points[1].x:= u2;
   Points[3].x:= u1;
   Points[2].x:= u2;
  end;

 if (TexCoord.Flip) then
  begin
   Points[0].y:= v2;
   Points[1].y:= v2;
   Points[3].y:= v1;
   Points[2].y:= v1;
  end else
  begin
   Points[0].y:= v1;
   Points[1].y:= v1;
   Points[3].y:= v2;
   Points[2].y:= v2;
  end;

 Result:= True; 
end;

//---------------------------------------------------------------------------
constructor TAsphyreImages.Create(AOwner: TComponent);
begin
 inherited;

 SetLength(Data, 0);
end;

//---------------------------------------------------------------------------
destructor TAsphyreImages.Destroy();
begin
 RemoveAll();

 inherited;
end;

//---------------------------------------------------------------------------
function TAsphyreImages.GetCount(): Integer;
begin
 Result:= Length(Data);
end;

//---------------------------------------------------------------------------
function TAsphyreImages.GetItem(Num: Integer): TAsphyreImage;
begin
 if (Num >= 0)and(Num < Length(Data)) then
  Result:= Data[Num] else Result:= nil;
end;

//---------------------------------------------------------------------------
function TAsphyreImages.Add(): TAsphyreImage;
var
 Index: Integer;
begin
 Index:= Length(Data);
 SetLength(Data, Index + 1);

 Data[Index]:= TAsphyreImage.Create();
 Data[Index].Mipmapping:= FMipmapping;
 Result:= Data[Index];
end;

//---------------------------------------------------------------------------
function TAsphyreImages.Find(Image: TAsphyreImage): Integer;
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  if (Data[i] = Image) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= -1;
end;

//---------------------------------------------------------------------------
function TAsphyreImages.Find(Name: string): Integer;
var
 i: Integer;
begin
 Name:= LowerCase(Name);

 Result:= -1;
 for i:= 0 to Length(Data) - 1 do
  if (Name = LowerCase(Data[i].FName)) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreImages.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= Length(Data)) then Exit;

 Data[Index].Free();
 for i:= Index to Length(Data) - 2 do
  Data[i]:= Data[i + 1];

 SetLength(Data, Length(Data) - 1);
end;

//---------------------------------------------------------------------------
procedure TAsphyreImages.RemoveAll();
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  if (Data[i] <> nil) then
   begin
    Data[i].Free();
    Data[i]:= nil;
   end;

 SetLength(Data, 0);
end;

//---------------------------------------------------------------------------
function TAsphyreImages.HandleNotice(Msg: Cardinal): Boolean;
var
 i: Integer;
begin
 Result:= True;

 case Msg of
  msgDeviceLost:
   begin
    for i:= 0 to Length(Data) - 1 do
     if (Data[i].State = tsReady) then
      Data[i].ChangeState(tsLost);
   end;

  msgDeviceRecovered:
   begin
    for i:= 0 to Length(Data) - 1 do
     if (Data[i].State = tsLost) then
      Data[i].ChangeState(tsReady);
   end;

  msgDeviceFinalize: RemoveAll();
 end;
end;

//---------------------------------------------------------------------------
function TAsphyreImages.AddFromASDb(const Key: string; ASDb: TASDb;
 Quality: TAsphyreQuality; AlphaLevel: TAlphaLevel): Boolean;
var
 Image: TAsphyreImage;
 Index: Integer;
begin
 // (1) Make sure ASDb is up-to-date.
 Result:= ASDb.UpdateOnce();
 if (not Result) then Exit;

 // (2) Find the specified record
 Index:= ASDb.RecordNum[Key];
 if (Index = -1) then
  begin
   Result:= False;
   Exit;
  end;

 Image := nil;

 // (3) If the record is valid, load the image
 if (ASDb.RecordType[Index] = recGraphics) then
  begin // -> Animated Image
   Image:= Add();
   Image.Name:= Key;
   Image.Quality:= Quality;
   Image.AlphaLevel:= AlphaLevel;
   Result:= Image.LoadFromASDb(Key, ASDb);
  end else Result:= False;

 // (4) Remove the image, if it was created by mistake.
 if (not Result)and(Image <> nil) then Remove(Find(Image));
end;

//---------------------------------------------------------------------------
function TAsphyreImages.AddFromFile(const Filename: string;
 const VisibleSize, PatternSize, TextureSize: TPoint;
 Quality: TAsphyreQuality; AlphaLevel: TAlphaLevel; NeedMasked: Boolean;
 MaskedColor: Longword; Tolerance: Integer): Boolean;
var
 Image: TAsphyreImage;
begin
 Image:= Add();
 Image.Quality    := Quality;
 Image.AlphaLevel := AlphaLevel;
 Image.PatternSize:= PatternSize;
 Image.Size       := TextureSize;
 Image.VisibleSize:= VisibleSize;

 Result:= Image.LoadFromFile(Filename, NeedMasked, MaskedColor, Tolerance);
 if (not Result)and(Image <> nil) then Remove(Find(Image));
end;

//---------------------------------------------------------------------------
function TAsphyreImages.LoadFromASDb(ASDb: TASDb): Boolean;
var
 Index  : Integer;
 Accept : Boolean;
 Name   : string;
 Quality: TAsphyreQuality;
 NewImage: TAsphyreImage;
 AlphaLevel: TAlphaLevel;
begin
 // (1) Make sure ASDb is up-to-date.
 Result:= ASDb.UpdateOnce();
 if (not Result) then Exit;

 // (2) Attempt to load all compatible and accepted records
 for Index:= 0 to ASDb.RecordCount - 1 do
  if (ASDb.RecordType[Index] = recGraphics) then
   begin
    // -> suggested parameters
    Accept := True;
    Name   := ASDb.RecordKey[Index];
    Quality:= aqHigh;
    AlphaLevel:= alFull;

    // -> call confirm event
    if (Assigned(OnASDbLoad)) then
     OnASDbLoad(Self, ASDb.RecordKey[Index], Length(Data), Accept, Name,
      Quality, AlphaLevel);

    // -> add the image and load it from ASDb
    if (Accept) then
     begin
      Result:= AddFromASDb(ASDb.RecordKey[Index], ASDb, Quality, AlphaLevel);
      if (not Result) then Break;

      // assuming that new image is added to the end of the list
      NewImage:= Data[Length(Data) - 1];
      NewImage.FName:= Name;
     end;
   end;
end;

//---------------------------------------------------------------------------
function TAsphyreImages.FindByName(Name: string): TAsphyreImage;
var
 i: Integer;
begin
 Name:= LowerCase(Name);

 Result:= nil;
 for i:= 0 to Length(Data) - 1 do
  if (Name = LowerCase(Data[i].FName)) then
   begin
    Result:= Data[i];
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TAsphyreImages.GetImage(const Name: string): TAsphyreImage;
begin
 Result:= FindByName(Name);
end;

//---------------------------------------------------------------------------
end.

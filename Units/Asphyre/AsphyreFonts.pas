unit AsphyreFonts;
//---------------------------------------------------------------------------
// AsphyreFonts.pas                                     Modified: 03-Oct-2005
// Bitmap fonts w/effects                                         Version 2.1
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
 Types, Classes, SysUtils, AsphyreDef, AsphyreImages, Asphyre2D,
 AsphyreCanvas, AsphyreDb, AsphyreDevices;

//---------------------------------------------------------------------------
type
 TFontASDbLoadEvent = procedure(Sender: TObject; const Key: string;
  Index: Integer; var Accept: Boolean; var Name: string;
  var Quality: TAsphyreQuality; var AlphaLevel: TAlphaLevel) of object;

//---------------------------------------------------------------------------
 TFontStyleFx = (feBold, feItalic, feShadow, feEmboss);
 TFontStylesFx = set of TFontStyleFx;

//---------------------------------------------------------------------------
 TAsphyreFonts = class;

//---------------------------------------------------------------------------
 TAsphyreFont = class
 private
  Sizes : array of TPoint;
  FOwner: TAsphyreFonts;
  FStyle: TFontStylesFx;
  FScale: Real;

  FTextTags : Boolean;
  FFontImage: TAsphyreImage;
  Spacing   : Integer;

  FIsLoaded   : Boolean;
  FFirstLetter: Char;
  FInterleave : Real;
  FLetterCount: Integer;
  FFontName   : string;
  FBlankSpacing: Real;

  FShadowIntensity: Real;
  FShadowColor    : Cardinal;

  FEmbossStrength : Real;
  FEmbossColor    : Cardinal;
  FShadowDistance : Real;

  function GetLetterSize(lNum: Integer): TPoint;
  function GetTextSize(const Text: string): TPoint2;
 public
  // determines if the font has been loaded properly
  property IsLoaded : Boolean read FIsLoaded;
  property FontName : string read FFontName write FFontName;
  property Owner    : TAsphyreFonts read FOwner;

  property FirstLetter: Char read FFirstLetter;
  property LetterCount: Integer read FLetterCount;
  property LetterSize[lNum: Integer]: TPoint read GetLetterSize;

  property FontImage : TAsphyreImage read FFontImage;

  property TextSize[const Text: string]: TPoint2 read GetTextSize;

  constructor Create(AOwner: TAsphyreFonts);
  destructor Destroy(); override;

  //-------------------------------------------------------------------------
  // Draws the text on the screen at the specified coordinates, with
  // gradient colors and draw operation.
  //-------------------------------------------------------------------------
  procedure TextOut(const Text: string; x, y: Real; Color0, Color1: Cardinal;
   DrawFx: Cardinal); overload;

  //-------------------------------------------------------------------------
  // Simplified text output routine.
  //-------------------------------------------------------------------------
  procedure TextOut(const Text: string; x, y: Real; Color: Cardinal); overload;

  //-------------------------------------------------------------------------
  // Estimates the text Width without painting it.
  //-------------------------------------------------------------------------
  function TextWidth(const Text: string): Real;

  //-------------------------------------------------------------------------
  // Estimates the text Height without painting it.
  //-------------------------------------------------------------------------
  function TextHeight(const Text: string): Real;

  //-------------------------------------------------------------------------
  // Loads the font from ASDb archive
  //-------------------------------------------------------------------------
  function LoadFromASDb(const Key: string; ASDb: TASDb;
   Quality: TAsphyreQuality; AlphaLevel: TAlphaLevel): Boolean;

  //-------------------------------------------------------------------------
  // Releases all resources occupied by this font.
  //-------------------------------------------------------------------------
  procedure Unload();
 published
  // Determines how big the text will be drawn; Default is 1.0
  property Scale: Real read FScale write FScale;

  // Customizable font style.
  property Style: TFontStylesFx read FStyle write FStyle;

  //-------------------------------------------------------------------------
  // Enable this to allow text color tags. Default is FALSE
  //
  // Format is:
  //  1st Color: #$[color_8_chars]
  //  2nd Color: &$[color_8_chars]
  //
  // Example (use this in "TextOut"):
  //  "The next color is #$FF00FF00Green&$FFFF0000 and Blue.
  //-------------------------------------------------------------------------
  property TextTags: Boolean read FTextTags write FTextTags;

  //-------------------------------------------------------------------------
  // The spacing between individual letters; Default is 0.0
  //-------------------------------------------------------------------------
  property Interleave: Real read FInterleave write FInterleave;

  //-------------------------------------------------------------------------
  // How dark the shadow is (0.0 - opaque, 1.0 - dark). Default is 0.5
  //-------------------------------------------------------------------------
  property ShadowIntensity: Real read FShadowIntensity write FShadowIntensity;

  //-------------------------------------------------------------------------
  // Shadow Color. Default is $000000 (black)
  //-------------------------------------------------------------------------
  property ShadowColor: Cardinal read FShadowColor write FShadowColor;

  //-------------------------------------------------------------------------
  // Shadow Distance multiplier. Default is 1.0
  //-------------------------------------------------------------------------
  property ShadowDistance: Real read FShadowDistance write FShadowDistance;

  //-------------------------------------------------------------------------
  // How strong the emboss is (0.0 - weak, 1.0 - strong). Default is 0.8
  //-------------------------------------------------------------------------
  property EmbossStrength: Real read FEmbossStrength write FEmbossStrength;

  //-------------------------------------------------------------------------
  // Emboss Color. Default is $000000 (black)
  //-------------------------------------------------------------------------
  property EmbossColor: Cardinal read FEmbossColor write FEmbossColor;

  //-------------------------------------------------------------------------
  // This defines how many space to allocate for non-present characters.
  // The default is 0.5, which is half of maximum letter size.
  //-------------------------------------------------------------------------
  property BlankSpacing: Real read FBlankSpacing write FBlankSpacing;
 end;

//---------------------------------------------------------------------------
 TAsphyreFonts = class(TAsphyreDeviceSubscriber)
 private
  FCanvas    : TAsphyreCanvas;
  Fonts      : array of TAsphyreFont;
  NameIndex  : Integer;
  FOnASDbLoad: TFontASDbLoadEvent;

  function GetItem(Index: Integer): TAsphyreFont;
  function GetCount(): Integer;
  function UniqueName(): string;
  function GetFont(Name: string): TAsphyreFont;
 protected
  procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  function HandleNotice(Msg: Cardinal): Boolean; override;
 public
  property Count: Integer read GetCount;
  property Items[Index: Integer]: TAsphyreFont read GetItem; default;
  property Font[Name: string]: TAsphyreFont read GetFont;

  constructor Create(AOwner: TComponent); override;
  destructor Destroy(); override;

  //-------------------------------------------------------------------------
  // Add new font to the list *without* initializing or loading it.
  //-------------------------------------------------------------------------
  function Add(): TAsphyreFont;

  //-------------------------------------------------------------------------
  // Finds an existing font in the list and returns its index.
  //-------------------------------------------------------------------------
  function Find(Font: TAsphyreFont): Integer; overload;
  function Find(Name: string): Integer; overload;

  //-------------------------------------------------------------------------
  // Removes the font from the list at the specified index.
  //-------------------------------------------------------------------------
  procedure Remove(Index: Integer);

  //-------------------------------------------------------------------------
  // Removes any loaded fonts from the list.
  //-------------------------------------------------------------------------
  procedure RemoveAll();

  //-------------------------------------------------------------------------
  // Add and load font from ASDb archive.
  //-------------------------------------------------------------------------
  function AddFromASDb(const Key: string; ASDb: TASDb;
   Quality: TAsphyreQuality; AlphaLevel: TAlphaLevel): Boolean;

  //-------------------------------------------------------------------------
  // Loads any supported fonts from the ASDb archive.
  // Optionally, calls OnASDbLoad event to confirm every loadable font.
  //-------------------------------------------------------------------------
  function LoadFromASDb(ASDb: TASDb): Boolean;
 published
  property OnASDbLoad: TFontASDbLoadEvent read FOnASDbLoad write FOnASDbLoad;
  property Canvas: TAsphyreCanvas read FCanvas write FCanvas;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TAsphyreFont.Create(AOwner: TAsphyreFonts);
begin
 inherited Create();

 FOwner      := AOwner;
 FFontImage  := nil;

 FFirstLetter:= #32;
 FInterleave := 0.0;
 FLetterCount:= 0;
 FScale      := 1.0;
 FBlankSpacing:= 0.3;

 FIsLoaded:= False;
 FFontName:= '';
 FTextTags:= True;
 Spacing  := 0;

 FStyle:= [];

 FShadowIntensity:= 0.5;
 FShadowColor    := $000000;
 FShadowDistance := 1.0;

 FEmbossStrength := 0.8;
 FEmbossColor    := $000000;
end;

//---------------------------------------------------------------------------
destructor TAsphyreFont.Destroy();
begin
 Unload();

 inherited;
end;

//---------------------------------------------------------------------------
function TAsphyreFont.GetTextSize(const Text: string): TPoint2;
var
 Index  : Integer;
 Pattern: Integer;
 Size   : TPoint2;
 Height : Real;
 Delta  : Real;
begin
 Size:= Point2(0.0, 0.0);
 if (not FIsLoaded) then
  begin
   Result:= Size;
   Exit;
  end;

 Index:= 1;
 while (Index <= Length(Text)) do
  begin
   // check for text tags
   if (FTextTags) then
    begin
     if (Text[Index] = '#')and(Index < Length(Text) - 10)and
      (Text[Index + 1] = '$') then Inc(Index, 10);

     if (Text[Index] = '&')and(Index < Length(Text) - 10)and
      (Text[Index + 1] = '$') then Inc(Index, 10);

     if (Text[Index] = '0')and(Index < Length(Text) - 10)and
      (Text[Index + 1] = 'x') then Inc(Index, 10);
    end;

   // convert "letter" to actual pattern number
   Pattern:= Integer(Text[Index]) - Integer(FFirstLetter);

   // if the pattern value is valid, add its "letter size" to the size variable
   if (Pattern >= 0)and(Pattern < FLetterCount) then
    begin
     Delta := (Sizes[Pattern].X + Spacing + FInterleave) * FScale;
     Height:= Sizes[Pattern].Y * FScale;
     if (Size.y < Height) then Size.y:= Height;
    end else
    begin
     Delta:= ((FFontImage.VisibleSize.X * FBlankSpacing) + FInterleave) * FScale;
    end;

   // increase the size
   Size.x:= Size.x + Delta;

   // advance in text string
   Inc(Index);
  end;

 Result:= Size;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.TextOut(const Text: string; x, y: Real; Color0,
 Color1: Cardinal; DrawFx: Cardinal);
var
 Index  : Integer;
 Pattern: Integer;
 xPos   : Real;
 MyColor: TColor4;
 xColor : string;
 Points : TPoint4;
 pSize  : TPoint;
 Canvas : TAsphyreCanvas;
 Shift  : TPoint2;
 AuxCol : Cardinal;
begin
 if (not FIsLoaded) then Exit;

 if (not Assigned(Owner)) then
  raise Exception.Create(ClassName + ': Unassigned Owner property.');

 if (not Assigned(Owner.Canvas)) then
  raise Exception.Create(ClassName + ': Unassigned Owner.Canvas property.');

 Canvas := Owner.Canvas;
 MyColor:= cColor4(Color0, Color0, Color1, Color1);
 Index  := 1;
 xPos   := x;
 PSize  := FFontImage.VisibleSize;
 while (Index <= Length(Text)) do
  begin
   // check for text tags
   if (FTextTags) then
    begin
     // -> 1st color
     if (Text[Index] = '#')and(Index < Length(Text) - 10)and
      (Text[Index + 1] = '$') then
      begin
       Inc(Index);
       xColor:= Copy(Text, Index, 9);
       Color0:= Cardinal(StrToIntDef(xColor, Color0));
       MyColor:= cColor4(Color0, Color0, Color1, Color1);
       Inc(Index, 9);
      end;

     // -> 2nd color
     if (Text[Index] = '&')and(Index < Length(Text) - 10)and
      (Text[Index + 1] = '$') then
      begin
       Inc(Index);
       xColor:= Copy(Text, Index, 9);
       Color1:= Cardinal(StrToIntDef(xColor, Color1));
       MyColor:= cColor4(Color0, Color0, Color1, Color1);
       Inc(Index, 9);
      end;

     // -> both colors
     if (Text[Index] = '0')and(Index < Length(Text) - 10)and
      (Text[Index + 1] = 'x') then
      begin
       Inc(Index);
       xColor:= Copy(Text, Index, 9);
       Color1:= Cardinal(StrToIntDef(xColor, Color1));
       Color0:= Color1;
       MyColor:= cColor4(Color0, Color0, Color1, Color1);
       Inc(Index, 9);
      end;
    end;

   // convert "letter" to actual pattern number
   Pattern:= Integer(Text[Index]) - Integer(FFirstLetter);

   // if the pattern value is valid, add its "letter size" to the size variable
   if (Pattern >= 0)and(Pattern < FLetterCount) then
    begin
     Points:= pBounds4s(Trunc(xPos), Trunc(y), pSize.X, pSize.Y, FScale);

     // -> italic font style
     if (feItalic in FStyle) then
      begin
       Points[0].x:= Trunc(Points[0].x + (pSize.X / 8.0));
       Points[1].x:= Trunc(Points[1].x + (pSize.X / 8.0));
       Points[2].x:= Trunc(Points[2].x - (pSize.X / 8.0));
       Points[3].x:= Trunc(Points[3].x - (pSize.X / 8.0));
      end;

     // -> draw shadow
     if (feShadow in FStyle) then
      begin
       Shift:= Point2(2.0, 2.0);
       if (feBold in FStyle) then Shift:= Point2(3.0, 2.0);
       Shift.x:= Shift.x * FScale * FShadowDistance;
       Shift.y:= Shift.y * FScale * FShadowDistance;

       AuxCol:= (Round(FShadowIntensity * 255.0) shl 24) or (FShadowColor and $FFFFFF);
       Canvas.TexMap(FFontImage, pShift4(Points, Shift), cColor4(AuxCol),
        tPattern(Pattern), DrawFx);
      end;

     // -> emboss: shift font by 2 pixels to left-top
     if (feEmboss in FStyle) then
      begin
       Points:= pShift4(Points, Point2(-1.0, -1.0));
      end;

     // -> draw normal letter
     Canvas.TexMap(FFontImage, Points, MyColor, tPattern(Pattern), DrawFx);

     // -> bold: expand letters
     if (feBold in FStyle) then
      begin
       Canvas.TexMap(FFontImage, pShift4(Points, Point2(-1.0, 0.0)), MyColor,
        tPattern(Pattern), DrawFx);

       Canvas.TexMap(FFontImage, pShift4(Points, Point2(1.0, 0.0)), MyColor,
        tPattern(Pattern), DrawFx);
      end;

     // emboss: draw dark image on top
     if (feEmboss in FStyle) then
      begin
       if (feBold in FStyle) then
        AuxCol:= Round(FEmbossStrength * 255.0 * 0.65) else
         AuxCol:= Round(FEmbossStrength * 255.0);

       AuxCol:= (AuxCol shl 24) or (FEmbossColor and $FFFFFF);

       if (feBold in FStyle) then
        begin
         Canvas.TexMap(FFontImage, pShift4(Points, Point2(1.0, 1.0)),
          cColor4(AuxCol), tPattern(Pattern), DrawFx);
         Canvas.TexMap(FFontImage, pShift4(Points, Point2(0.0, 1.0)),
          cColor4(AuxCol), tPattern(Pattern), DrawFx);
         Canvas.TexMap(FFontImage, pShift4(Points, Point2(2.0, 1.0)),
          cColor4(AuxCol), tPattern(Pattern), DrawFx);
        end else
         Canvas.TexMap(FFontImage, pShift4(Points, Point2(1.0, 1.0)),
          cColor4(AuxCol), tPattern(Pattern), DrawFx);
      end;

     xPos:= xPos + ((Sizes[Pattern].X + Spacing + FInterleave) * FScale);
    end else xPos:= xPos + (((FFontImage.VisibleSize.X * FBlankSpacing) +
     FInterleave) * FScale);

   // advance in text string
   Inc(Index);
  end; // while
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.TextOut(const Text: string; x, y: Real;
 Color: Cardinal);
begin
 TextOut(Text, x, y, Color, Color, fxBlend);
end;

//---------------------------------------------------------------------------
function TAsphyreFont.TextWidth(const Text: string): Real;
begin
 Result:= TextSize[Text].x;
end;

//---------------------------------------------------------------------------
function TAsphyreFont.TextHeight(const Text: string): Real;
begin
 Result:= TextSize[Text].y;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFont.Unload();
begin
 if (Assigned(FFontImage)) then
  begin
   FFontImage.Free();
   FFontImage:= nil;
  end;

 FIsLoaded:= False;
end;

//---------------------------------------------------------------------------
function TAsphyreFont.LoadFromASDb(const Key: string; ASDb: TASDb;
 Quality: TAsphyreQuality; AlphaLevel: TAlphaLevel): Boolean;
var
 Stream: TMemoryStream;
 RecNum: Integer;
 Index : Integer;
begin
 // (1) Verify initial conditions.
 if (FIsLoaded) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Make sure ASDb is up-to-date.
 Result:= ASDb.UpdateOnce();
 if (not Result) then Exit;

 // (3) Verify record type.
 RecNum:= ASDb.RecordNum[Key];
 if (RecNum = -1)or(ASDb.RecordType[RecNum] <> recFont) then
  begin
   Result:= False;
   Exit;
  end;

 // 4. create memory stream
 Stream:= TMemoryStream.Create();

 // 5. read the specified record
 Result:= ASDb.ReadStream(Key, Stream);
 if (not Result) then
  begin
   Stream.Free();
   Exit;
  end;

 // 6. read font data
 Stream.Seek(0, soFromBeginning);
 try
  // -> letter information
  Stream.ReadBuffer(FFirstLetter, SizeOf(Integer));
  Stream.ReadBuffer(Spacing, SizeOf(LongInt));
  Stream.Seek(4, soFromCurrent); // skip reserved space
  Stream.ReadBuffer(FLetterCount, SizeOf(Integer));

  // -> individual letter sizes
  SetLength(Sizes, FLetterCount);
  for Index:= 0 to FLetterCount - 1 do
   Stream.ReadBuffer(Sizes[Index], SizeOf(TPoint));
 except
  Result:= False;
  Stream.Free();
  Exit;
 end; 

 // 7. read gfx data
 FFontImage:= TAsphyreImage.Create();
 FFontImage.Quality   := Quality;
 FFontImage.AlphaLevel:= AlphaLevel;
 FFontImage.MipMapping:= True;
 Result:= FFontImage.LoadFromStream(Stream);
 if (not Result) then
  begin
   FFontImage.Free();
   FFontImage:= nil;
  end;

 // 8. release the stream
 Stream.Free();

 // 9. change status to [IsLoaded]
 FIsLoaded:= Result;
end;

//---------------------------------------------------------------------------
function TAsphyreFont.GetLetterSize(lNum: Integer): TPoint;
begin
 Result:= Sizes[lNum];
end;

//---------------------------------------------------------------------------
constructor TAsphyreFonts.Create(AOwner: TComponent);
var
 Index: Integer;
begin
 inherited;

 // look for an existing TAsphyreDevice at design time
 if (csDesigning in ComponentState)and(Assigned(AOwner)) then
  for Index:= 0 to AOwner.ComponentCount - 1 do
   if (AOwner.Components[Index] is TAsphyreCanvas) then
    begin
     FCanvas:= TAsphyreCanvas(AOwner.Components[Index]);
     Break;
    end;

 SetLength(Fonts, 0);
end;

//---------------------------------------------------------------------------
destructor TAsphyreFonts.Destroy();
begin
 RemoveAll();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreFonts.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
 inherited;

 case Operation of
  opInsert:
   if (AComponent is TAsphyreCanvas)and(not Assigned(FCanvas)) then
    FCanvas:= TAsphyreCanvas(AComponent);

  opRemove:
   if (AComponent = FCanvas) then FCanvas:= nil;
 end;
end;
//---------------------------------------------------------------------------
function TAsphyreFonts.GetCount(): Integer;
begin
 Result:= Length(Fonts);
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.GetItem(Index: Integer): TAsphyreFont;
begin
 Result:= nil;
 if (Index >= 0)and(Index < Length(Fonts)) then Result:= Fonts[Index];
end;

//---------------------------------------------------------------------------
procedure TAsphyreFonts.RemoveAll();
var
 i: Integer;
begin
 for i:= 0 to Length(Fonts) - 1 do
  if (Assigned(Fonts[i])) then
   begin
    Fonts[i].Free();
    Fonts[i]:= nil;
   end;

 SetLength(Fonts, 0);
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.UniqueName(): string;
begin
 Result:= IntToStr(NameIndex);
 while (Length(Result) < 2) do Result:= '0' + Result;

 Result:= 'Font' + Result;

 Inc(NameIndex);
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.Add(): TAsphyreFont;
var
 Index: Integer;
begin
 Index:= Length(Fonts);
 SetLength(Fonts, Index + 1);

 Fonts[Index]:= TAsphyreFont.Create(Self);
 Fonts[Index].FFontName:= UniqueName();
 
 Result:= Fonts[Index];
end;

//---------------------------------------------------------------------------
procedure TAsphyreFonts.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= Length(Fonts)) then Exit;

 // 1. release the font
 if (Assigned(Fonts[Index])) then
  begin
   Fonts[Index].Free();
   Fonts[Index]:= nil;
  end;

 // 2. remove font from the list 
 for i:= Index to Length(Fonts) - 2 do
  begin
   Fonts[i]:= Fonts[i + 1];
//   Fonts[i].FFontIndex:= i;
  end; 

 // 3. update array size
 SetLength(Fonts, Length(Fonts) - 1);
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.Find(Font: TAsphyreFont): Integer;
var
 i: Integer;
begin
 for i:= 0 to Length(Fonts) - 1 do
  if (Fonts[i] = Font) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= -1;   
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.AddFromASDb(const Key: string; ASDb: TASDb;
 Quality: TAsphyreQuality; AlphaLevel: TAlphaLevel): Boolean;
var
 Font: TAsphyreFont;
begin
 Font:= Add();
 Font.FFontName:= Key;
 Result:= Font.LoadFromASDb(Key, ASDb, Quality, AlphaLevel);
 if (not Result) then Remove(Find(Font));
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.GetFont(Name: string): TAsphyreFont;
var
 i: Integer;
begin
 Name:= LowerCase(Name);

 Result:= nil;
 for i:= 0 to Length(Fonts) - 1 do
  if (Assigned(Fonts[i]))and(LowerCase(Fonts[i].FontName) = Name) then
   begin
    Result:= Fonts[i];
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.Find(Name: string): Integer;
var
 i: Integer;
begin
 Name:= LowerCase(Name);

 Result:= -1;
 for i:= 0 to Length(Fonts) - 1 do
  if (Assigned(Fonts[i]))and(LowerCase(Fonts[i].FontName) = Name) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.HandleNotice(Msg: Cardinal): Boolean;
begin
 Result:= True;
 if (Msg = msgDeviceFinalize) then RemoveAll();
end;

//---------------------------------------------------------------------------
function TAsphyreFonts.LoadFromASDb(ASDb: TASDb): Boolean;
var
 Index  : Integer;
 Accept : Boolean;
 Name   : string;
 Quality: TAsphyreQuality;
 NewFont: TAsphyreFont;
 AlphaLevel: TAlphaLevel;
begin
 // (1) Make sure ASDb is up-to-date.
 Result:= ASDb.UpdateOnce();
 if (not Result) then Exit;

 // (2) Attempt to load all compatible and accepted records
 for Index:= 0 to ASDb.RecordCount - 1 do
  if (ASDb.RecordType[Index] = recFont) then
   begin
    // -> suggested parameters
    Accept := True;
    Name   := ASDb.RecordKey[Index];
    Quality:= aqHigh;
    AlphaLevel:= alFull;

    // -> call confirm event
    if (Assigned(OnASDbLoad)) then
     OnASDbLoad(Self, ASDb.RecordKey[Index], Length(Fonts), Accept, Name,
      Quality, AlphaLevel);

    // -> add the font and load it from ASDb
    if (Accept) then
     begin
      NewFont:= Add();

      Result:= NewFont.LoadFromASDb(ASDb.RecordKey[Index], ASDb, Quality,
       AlphaLevel);
      if (not Result) then Break;

      NewFont.FFontName:= Name;
     end;
   end;
end;

//---------------------------------------------------------------------------
end.

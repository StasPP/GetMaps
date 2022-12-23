unit AsphyreLoader;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, AsphyreDef, AsphyreDevices, AsphyreImages,
 AsphyreFonts, AsphyreDb, LibXmlParser;

//---------------------------------------------------------------------------
type
 TResourceLoadEvent = procedure(Sender: TObject;
  const ResName: string) of object;

//---------------------------------------------------------------------------
 TParseTagEvent = procedure(const Tag: string; Parser: TXMLParser) of object;

//---------------------------------------------------------------------------
 TAsphyreLoader = class(TAsphyreDeviceSubscriber)
 private
  FFonts  : TAsphyreFonts;
  FImages : TAsphyreImages;
  FArchive: TASDb;

  FOnLoad  : TResourceLoadEvent;
  FOnUnload: TResourceLoadEvent;
  FXMLDescFile: string;

  function ParseGroup(const GroupName: string; Event: TParseTagEvent): Boolean;
  procedure LoadTagEvent(const Tag: string; Parser: TXMLParser);
  procedure UnloadTagEvent(const Tag: string; Parser: TXMLParser);
 public
  function Load(const GroupName: string): Boolean;
  procedure Unload(const GroupName: string);

  constructor Create(AOwner: TComponent); override;
 published
  property Images : TAsphyreImages read FImages write FImages;
  property Fonts  : TAsphyreFonts read FFonts write FFonts;
  property Archive: TASDb read FArchive write FArchive;

  property XMLDescFile: string read FXMLDescFile write FXMLDescFile;

  property OnLoad: TResourceLoadEvent read FOnLoad write FOnLoad;
  property OnUnload: TResourceLoadEvent read FOnUnload write FOnUnload;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
function Str2Quality(const Text: string): TAsphyreQuality;
begin
 Result:= aqHigh;

 if (Text = 'medium') then Result:= aqMedium;
 if (Text = 'low') then Result:= aqLow;
end;

//---------------------------------------------------------------------------
function Str2AlphaLevel(const Text: string): TAlphaLevel;
begin
 Result:= alFull;

 if (Text = 'exclusive') then Result:= alExclusive;
 if (Text = 'mask') then Result:= alMask;
 if (Text = 'none') then Result:= alNone;
end;

//---------------------------------------------------------------------------
constructor TAsphyreLoader.Create(AOwner: TComponent);
begin
 inherited;

 FImages := TAsphyreImages(FindHelper(TAsphyreImages));
 FFonts  := TAsphyreFonts(FindHelper(TAsphyreFonts));
 FArchive:= TASDb(FindHelper(TASDb));
end;

//---------------------------------------------------------------------------
function TAsphyreLoader.ParseGroup(const GroupName: string;
 Event: TParseTagEvent): Boolean;
var
 TagName: string;
 Parser : TXMLParser;
 Level  : Integer;
 Text   : string;
begin
 // (1) Load XML file.
 Result:= (FXMLDescFile <> '') and (LoadTextFile(FXMLDescFile, Text));
 if (not Result) then Exit;

 // (2) Put the loaded file to XML parser.
 Parser:= TXMLParser.Create();
 Parser.LoadFromBuffer(PChar(Text));

 // (3) Parse the XML file.
 Parser.Normalize:= False;
 Parser.StartScan();

 Level:= 0;
 while (Parser.Scan()) do
  case Parser.CurPartType of
   ptEmptyTag:
    if (Level = 2) then
     Event(LowerCase(Parser.CurName), Parser);

   ptStartTag:
    begin
     TagName:= LowerCase(Parser.CurName);
     if (TagName = 'asphyre')and(Level = 0) then Inc(Level);
     if (TagName = 'group')and(Level = 1) then
      begin
       if (Parser.CurAttr.Value('name') = GroupName) then Inc(Level);
      end;
     if (Level = 2) then
      Event(LowerCase(Parser.CurName), Parser);
    end;
   ptEndTag:
    begin
     TagName:= LowerCase(Parser.CurName);
     if (TagName = 'asphyre')and(Level = 1) then Dec(Level);
     if (TagName = 'group')and(Level = 2) then Dec(Level);
    end;
  end;

 Parser.Free();
end;

//---------------------------------------------------------------------------
function TAsphyreLoader.Load(const GroupName: string): Boolean;
begin
 Result:= ParseGroup(GroupName, LoadTagEvent);
end;

//---------------------------------------------------------------------------
procedure TAsphyreLoader.LoadTagEvent(const Tag: string; Parser: TXMLParser);
var
 Name   : string;
 Source : string;
 Key    : string;
 Quality: TAsphyreQuality;
 ALevel : TAlphaLevel;
 Image  : TAsphyreImage;
 Font   : TAsphyreFont;
begin
 if ((Tag <> 'image')and(Tag <> 'font'))or(not Assigned(FArchive)) then Exit;

 Name  := Parser.CurAttr.Value('name');
 Source:= Parser.CurAttr.Value('source');
 Key   := Parser.CurAttr.Value('key');

 if (Length(Name) < 1) then Name:= Key;

 Quality:= Str2Quality(LowerCase(Parser.CurAttr.Value('quality')));
 ALevel := Str2AlphaLevel(LowerCase(Parser.CurAttr.Value('alphalevel')));

 if (FArchive.FileName <> Source) then
  begin
   FArchive.FileName:= ExtractFilePath(FXMLDescFile) + ExtractFileName(Source);
   FArchive.OpenMode:= opReadOnly;
   if (not FArchive.Update()) then Exit;
  end;

 if (Tag = 'image')and(Assigned(FImages)) then
  begin
   Image:= FImages.Add();
   Image.Name:= Name;
   Image.Quality:= Quality;
   Image.AlphaLevel:= ALevel;
   if (not Image.LoadFromASDb(Key, FArchive)) then
    begin
     FImages.Remove(FImages.Find(Image));
     Exit;
    end; 

   if (Assigned(FOnLoad)) then
    FOnLoad(Self, ExtractFileName(Source) + '\' + Key);
  end;

 if (Tag = 'font')and(Assigned(FFonts)) then
  begin
   Font:= FFonts.Add();
   Font.FontName:= Name;
   if (not Font.LoadFromASDb(Key, FArchive, Quality, ALevel)) then
    begin
     FFonts.Remove(FFonts.Find(Font));
     Exit;
    end; 

   if (Assigned(FOnLoad)) then
    FOnLoad(Self, ExtractFileName(Source) + '\' + Key);
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreLoader.UnloadTagEvent(const Tag: string; Parser: TXMLParser);
var
 Name: string;
 Key : string;
begin
 if ((Tag <> 'image')and(Tag <> 'font'))or(not Assigned(FArchive)) then Exit;

 Name:= Parser.CurAttr.Value('name');
 Key := Parser.CurAttr.Value('key');

 if (Length(Name) < 1) then Name:= Key;

 if (Tag = 'image')and(Assigned(FImages)) then
  begin
   FImages.Remove(FImages.Find(Name));
   if (Assigned(FOnUnload)) then FOnUnload(Self, Name);
  end;

 if (Tag = 'font')and(Assigned(FFonts)) then
  begin
   FFonts.Remove(FFonts.Find(Name));
   if (Assigned(FOnUnload)) then FOnUnload(Self, Name);
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreLoader.Unload(const GroupName: string);
begin
 ParseGroup(GroupName, UnloadTagEvent);
end;

//---------------------------------------------------------------------------
end.


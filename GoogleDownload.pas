unit GoogleDownload;

/////// 512 x 512 tiles only
/////// 2017 Shevchuk Stanislav

interface

 uses IdBaseComponent, IdComponent, IdTCPConnection, JPeG,
      IdTCPClient, IdHTTP, GeoClasses, GeoFunctions, GeoFiles, GeoString,
      Math, SysUtils, Graphics, ExtCtrls, Classes, GraphicEx,
      IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL;

 type TBLRect = Record
   B, L :array[1..4] of Double;
 end;

 ///// GOOGLE

 function GetGoogleStaticMapURL( B,L: double; MapStyle, GoogleKey :string;
                                    ZoomLevel: integer):string;

 procedure GetGoogleStaticMap( URL:string; var Image:TImage);

 function GetBLBounds(B,L: Double; ZoomLevel:Integer):TBLRect;

 procedure GetNextBLUp (B,L: Double; ZoomLevel:Integer; var NewB, NewL : Double);
 procedure GetNextBLDown (B,L: Double; ZoomLevel:Integer; var NewB, NewL : Double);
 procedure GetNextBLLeft (B,L: Double; ZoomLevel:Integer; var NewB, NewL : Double);
 procedure GetNextBLRight (B,L: Double; ZoomLevel:Integer; var NewB, NewL : Double);


 //// YANDEX
 ///
 procedure GetYandexStaticMap( URL:string; YStyle: string; var Image:TImage);
 function GetYandexStaticMapURL( B,L: double; MapStyle, YaKey, YaLang :string;
                                    ZoomLevel: integer):string;

 function YandexGetBLBounds(B,L: Double; ZoomLevel:Integer):TBLRect;

 procedure YandexGetNextBLUp (B,L: Double; ZoomLevel:Integer; var NewB, NewL : Double);
 procedure YandexGetNextBLDown (B,L: Double; ZoomLevel:Integer; var NewB, NewL : Double);
 procedure YandexGetNextBLLeft (B,L: Double; ZoomLevel:Integer; var NewB, NewL : Double);
 procedure YandexGetNextBLRight (B,L: Double; ZoomLevel:Integer; var NewB, NewL : Double);

const
  GoogleTileScales: array [0..20] of double = (156412, 78206, 39103, 19551, 9776, 4888,
                                      2444, 1222, 610.984, 305.492, 152.746,
                                      76.373, 38.187, 19.093, 9.547, 4.773,
                                      2.387, 1.193, 0.596, 0.298, 0.149);

{  YandexTileScales: array [0..20] of double = (156412, 78206, 39103, 19551, 9776, 4888,
                                      2444, 1222, 610.984, 305.492, 152.746,
                                      76.373, 38.187, 19.093, 9.547, 4.773,
                                      2.387, 1.193, 0.596, 0.298, 0.149); }   {????}
implementation

procedure GetYandexStaticMap(URL:String; YStyle: string; var Image: TImage);
var
  StreamData :TMemoryStream;
  JPEGImage  : TJPEGImage;
  PNGImage :  TPNGGraphic;
  IdHttp:TIdHttp;
  IOS : TIdSSLIOHandlerSocketOpenSSL;
begin

//// SAT = JPG ELSE = PNG

  IdHttp := TIdHttp.Create(nil);
  IOS := TIdSSLIOHandlerSocketOpenSSL.Create(IdHttp);

  IdHTTP.Request.BasicAuthentication := False;
  IOS.SSLOptions.Mode := sslmClient;
  IOS.SSLOptions.Method := sslvSSLv23;
  IdHttp.IOHandler := IOS;

  IdHttp.ConnectTimeout := 3000;
  IdHttp.readTimeout := 3000;

  IdHTTP.ProxyParams.ProxyPort := 8080;
  IdHttp.request.useragent :=
  'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0; MAAU)';

  StreamData := TMemoryStream.Create;
  JPEGImage  := TJPEGImage.Create;
  PNGImage   := TPNGGraphic.Create;
  try                     
    try
     Idhttp.Get(Url, StreamData); //Send the request and get the image
     StreamData.Seek(0,soFromBeginning);
     if Pos('sat',YStyle) <> 0 then
     begin
       JPEGImage.LoadFromStream(StreamData);//load the image in a Stream
       Image.Picture.Assign(JPEGImage);//Load the image in a Timage component
     end
        else
        begin
          Image.Picture.Bitmap.Width := 256;
          Image.Picture.Bitmap.Height := 256;
          try
            PngImage.LoadFromStream(StreamData);
          except
            PngImage.Width := 256;
            PngImage.Height := 256;
            PngImage.Canvas.Textout(10,10,'NO DATA');
          end;
          Image.Picture.Bitmap.Assign(PngImage);
        end;
     
    Except
      On E : Exception Do
      begin   
       Image.Picture.Bitmap.Width := 256;
       Image.Picture.Bitmap.Height := 256;
       Image.Picture.Bitmap.Canvas.Brush.Style := BsClear;
       Image.Picture.Bitmap.Canvas.Rectangle(5,5,250,250);
       Image.Picture.Bitmap.Canvas.Textout(10,10,'Exception:');
       Image.Picture.Bitmap.Canvas.Textout(10,25,E.Message);
       
      end;
    End;
  finally
    StreamData.free;
    JPEGImage.Free;
    PNGImage.Free;
  end;

  IdHttp.Free;
end;

procedure GetGoogleStaticMap(URL:String; var Image: TImage);
var
  StreamData :TMemoryStream;
  JPEGImage  : TJPEGImage;
  IdHttp:TIdHttp;

begin

  IdHttp := TIdHttp.Create(nil);

  IdHTTP.ProxyParams.ProxyPort := 8080;
  IdHttp.request.useragent :=
  'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0; MAAU)';

  StreamData := TMemoryStream.Create;
  JPEGImage  := TJPEGImage.Create;
  try
    try

     Idhttp.Get(Url, StreamData); //Send the request and get the image
     StreamData.Seek(0,soFromBeginning);
     JPEGImage.LoadFromStream(StreamData);//load the image in a Stream
     Image.Picture.Assign(JPEGImage);//Load the image in a Timage component
    Except On E : Exception Do
      begin
       Image.Picture.Bitmap.Width := 512;
       Image.Picture.Bitmap.Height := 512;
       Image.Picture.Bitmap.Canvas.Brush.Style := BsClear;
       Image.Picture.Bitmap.Canvas.Rectangle(10,10,502,502);
       Image.Picture.Bitmap.Canvas.Textout(20,20,'Exception:');
       Image.Picture.Bitmap.Canvas.Textout(20,35,E.Message);
      end;
    End;
  finally
    StreamData.free;
    JPEGImage.Free;
  end;

  IdHttp.Free;
end;

function GetGoogleStaticMapURL(B, L: double; MapStyle,
  GoogleKey: string; ZoomLevel: integer): string;
var DS :Char;

begin
  DS := DecimalSeparator;
  DecimalSeparator :='.';

  Result :='http://maps.google.com/maps/api/staticmap?' +
  'center='+ Format('%.11f',[B])+',' + Format('%.11f',[L])+
  '&zoom=' + IntTostr(ZoomLevel) +
  '&size=512x542' +
  '&maptype='+MapStyle +
  '&format=jpg' +
  '&sensor=false'+
  '&scale=1';

  if GoogleKey<>'' then
      Result := Result+'&key='+GoogleKey;

  DecimalSeparator := DS;
end;

function GetBLBounds(B,L: Double; ZoomLevel:Integer):TBLRect;
var X, Y :Double;
    NewX, NewY :Double;
    Scale :Double;
    WGS :Integer;
begin

  //// Coordinates for Points of Image: (0,0) (512,0) (0,512) (512,512)

  WGS  := FindDatum('WGS84');

  PVMtoUTM  (WGS, B, L, Y, X);
  Scale := GoogleTileScales[ZoomLevel];

  NewY := Y + Scale*256 + Scale*15;   {Copyright zone}
  NewX := X - Scale*256;
  UTMToPVM(WGS,  NewY, NewX, Result.B[1], Result.L[1]);

  NewY := Y + Scale*256 + Scale*15;   {Copyright zone}
  NewX := X + Scale*256;
  UTMToPVM(WGS,  NewY, NewX, Result.B[2], Result.L[2]);

  NewY := Y - Scale*256 + Scale*15;   {Copyright zone}
  NewX := X - Scale*256;
  UTMToPVM(WGS,  NewY, NewX, Result.B[3], Result.L[3]);

  NewY := Y - Scale*256 + Scale*15;   {Copyright zone}
  NewX := X + Scale*256;
  UTMToPVM(WGS,  NewY, NewX, Result.B[4], Result.L[4]);
end;

//////////////////////// NEXT To --------------------------

procedure GetNextBLUp (B,L: Double; ZoomLevel:Integer; var NewB, NewL : Double);
var WGS : Integer;
    X, Y :Double;
    NewX, NewY :Double;
    Scale : Double;
begin
    WGS  := FindDatum('WGS84');

    PVMtoUTM  (WGS, B, L, Y, X);
    Scale := GoogleTileScales[ZoomLevel];

    NewY := Y + Scale*512;
    NewX := X;

    UTMToPVM(WGS, NewY, NewX, NewB, NewL);
end;

procedure GetNextBLDown (B,L: Double; ZoomLevel:Integer; var NewB, NewL : Double);
var WGS : Integer;
    X, Y :Double;
    NewX, NewY :Double;
    Scale : Double;
begin
    WGS  := FindDatum('WGS84');

    PVMtoUTM  (WGS, B, L, Y, X);
    Scale := GoogleTileScales[ZoomLevel];

    NewY := Y - Scale*512;
    NewX := X;

    UTMToPVM(WGS, NewY, NewX, NewB, NewL);
end;

procedure GetNextBLLeft (B,L: Double; ZoomLevel:Integer; var NewB, NewL : Double);
var WGS : Integer;
    X, Y :Double;
    NewX, NewY :Double;
    Scale : Double;
begin
    WGS  := FindDatum('WGS84');

    PVMtoUTM  (WGS, B, L, Y, X);
    Scale := GoogleTileScales[ZoomLevel];

    NewY := Y;
    NewX := X - Scale*512;

    UTMToPVM(WGS, NewY, NewX, NewB, NewL);
end;

procedure GetNextBLRight (B,L: Double; ZoomLevel:Integer; var NewB, NewL : Double);
var WGS : Integer;
    X, Y :Double;
    NewX, NewY :Double;
    Scale : Double;
begin
    WGS  := FindDatum('WGS84');

    PVMtoUTM  (WGS, B, L, Y, X);
    Scale := GoogleTileScales[ZoomLevel];

    NewY := Y;
    NewX := X + Scale*512;

    UTMToPVM(WGS, NewY, NewX, NewB, NewL);
end;

/////////////////////////////////////////////////////------------

function GetYandexStaticMapURL(B, L: double; MapStyle,
  YaKey, YaLang: string; ZoomLevel: integer): string;
var DS :Char;
    WGS: Integer;
    b1, b2, db, l1, l2, x, y, x2, y2, Scale: Double;
    YZone : Integer;
    YAZone: boolean;
begin

  WGS  := FindDatum('WGS84');
  YZone := 0;
  YaZone := True;
  Scale := GoogleTileScales[ZoomLevel];

  GeoToUTM(WGS, B, L, B > 0, Y, X, YZone, YaZone);

  X2 := X + Scale*128;
  Y2 := Y + Scale*128;
  X := X - Scale*128;
  Y := Y - Scale*128 - Scale*70;

  // showmessage(IntTostr(trunc(x2-x))+ ', '+IntTostr(trunc(y2-y)));

  UTMToGeo(WGS,  Y,  X,  B > 0, YZone, B1, L1);
  UTMToGeo(WGS,  Y2, X2, B > 0, YZone, B2, L2);

  // dB := (B2 - B1)*23/326;  {35/256}
  //showmessage(Format('%.7f',[L2 - L1])+ ', '+Format('%.7f',[B2 - B1]));

  DS := DecimalSeparator;
  DecimalSeparator :='.';

  Result :='https://static-maps.yandex.ru/1.x/';

 { if B1 < 59 then
  Result := Result +
  '?bbox='+ Format('%.7f',[L2])+',' + Format('%.7f',[B2])+ '~'+
            Format('%.7f',[L1])+',' + Format('%.7f',[B1])
      else }
     //  Result := Result + '?ll='+ Format('%.7f',[L])+',' + Format('%.7f',[B-dB])+
     //    '&z=' + IntTostr(ZoomLevel-1) ;

  Result := Result + '?ll='+ Format('%.7f',[(L2+L1)/2])+',' + Format('%.7f',[(B2+B1)/2])+
               '&z=' + IntTostr(ZoomLevel-1) ;// '&spn=' + Format('%.7f',[Abs(L2-L1)/2])+','+ Format('%.7f',[Abs(B2-B1)/2]);


  Result := Result + '&size=256,326' +  '&l=' + MapStyle;

//  '&z=' + IntTostr(ZoomLevel) +

  if (MapStyle <> 'sat')and(YaLang<>'') then
      Result := Result+'&lang='+YaLang;

  if YaKey<>'' then
      Result := Result+'&key='+YaKey;

  DecimalSeparator := DS;
end;

function YandexGetBLBounds(B,L: Double; ZoomLevel:Integer):TBLRect;
var X, Y :Double;
    NewX, NewY :Double;
    Scale :Double;
    WGS :Integer;
    YZone : Integer;
    YAZone: boolean;
begin

  //// Coordinates for Points of Image: (0,0) (512,0) (0,512) (512,512)

  WGS  := FindDatum('WGS84');
  YZone := 0;
  YaZone := True;

  // PVMtoUTM  (WGS, B, L, Y, X);
  GeoToUTM(WGS, B, L, B > 0, Y, X, YZone, YaZone);

  Scale := GoogleTileScales[ZoomLevel];

  NewY := Y + Scale*128 + Scale*35;   {Copyright zone}
  NewX := X - Scale*128;
  UTMToGeo(WGS,  NewY, NewX, B > 0, YZone, Result.B[1], Result.L[1]);

  NewY := Y + Scale*128 + Scale*35;   {Copyright zone}
  NewX := X + Scale*128;
  UTMToGeo(WGS,  NewY, NewX, B > 0, YZone, Result.B[2], Result.L[2]);

  NewY := Y - Scale*128 + Scale*35;   {Copyright zone}
  NewX := X - Scale*128;
  UTMToGeo(WGS,  NewY, NewX, B > 0, YZone, Result.B[3], Result.L[3]);

  NewY := Y - Scale*128 + Scale*35;   {Copyright zone}
  NewX := X + Scale*128;
  UTMToGeo(WGS,  NewY, NewX, B > 0, YZone, Result.B[4], Result.L[4]);
end;

//////////////////////// NEXT To --------------------------

procedure YandexGetNextBLUp (B,L: Double; ZoomLevel:Integer; var NewB, NewL : Double);
var WGS : Integer;
    X, Y :Double;
    NewX, NewY :Double;
    Scale : Double;
    YZone : Integer;
    YAZone: boolean;
begin

  WGS  := FindDatum('WGS84');
  YZone := 0;
  YaZone := True;
  // PVMtoUTM  (WGS, B, L, Y, X);
  GeoToUTM(WGS, B, L, B > 0, Y, X, YZone, YaZone);


   // PVMtoUTM  (WGS, B, L, Y, X);
    Scale := GoogleTileScales[ZoomLevel];

    NewY := Y + Scale*128;
    NewX := X;

  UTMToGeo(WGS,  NewY, NewX, B > 0, YZone, NewB, NewL);
end;

procedure YandexGetNextBLDown (B,L: Double; ZoomLevel:Integer; var NewB, NewL : Double);
var WGS : Integer;
    X, Y :Double;
    NewX, NewY :Double;
    Scale : Double;
    YZone : Integer;
    YAZone: boolean;
begin

  WGS  := FindDatum('WGS84');
  YZone := 0;
  YaZone := True;

  GeoToUTM(WGS, B, L, B > 0, Y, X, YZone, YaZone);
    Scale := GoogleTileScales[ZoomLevel];

    NewY := Y - Scale*128;
    NewX := X;

 UTMToGeo(WGS,  NewY, NewX, B > 0, YZone, NewB, NewL);
end;

procedure YandexGetNextBLLeft (B,L: Double; ZoomLevel:Integer; var NewB, NewL : Double);
var WGS : Integer;
    X, Y :Double;
    NewX, NewY :Double;
    Scale : Double;
    YZone : Integer;
    YAZone: boolean;
begin

  WGS  := FindDatum('WGS84');
  YZone := 0;
  YaZone := True;

  GeoToUTM(WGS, B, L, B > 0, Y, X, YZone, YaZone);
    Scale := GoogleTileScales[ZoomLevel];

    NewY := Y;
    NewX := X - Scale*128;

 UTMToGeo(WGS,  NewY, NewX, B > 0, YZone, NewB, NewL);
end;

procedure YandexGetNextBLRight (B,L: Double; ZoomLevel:Integer; var NewB, NewL : Double);
var WGS : Integer;
    X, Y :Double;
    NewX, NewY :Double;
    Scale : Double;
    YZone : Integer;
    YAZone: boolean;
begin

  WGS  := FindDatum('WGS84');
  YZone := 0;
  YaZone := True;

  GeoToUTM(WGS, B, L, B > 0, Y, X, YZone, YaZone);
    Scale := GoogleTileScales[ZoomLevel];

    NewY := Y;
    NewX := X + Scale*128;

  UTMToGeo(WGS,  NewY, NewX, B > 0, YZone, NewB, NewL);
end;

/////////////////////////////////////////////////////------------

end.
 
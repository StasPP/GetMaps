unit TestForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdHTTP, JPEG, ExtCtrls, GeoClasses, GeoFunctions, GeoFiles, GeoString, Math,
  GetGoogle, GoogleDownload, AsdbMap, ComCtrls;

type
  TTestFm = class(TForm)
    Imagemap: TImage;
    Imagemap2: TImage;
    Shape1: TShape;
    Shape2: TShape;
    Shape3: TShape;
    Shape4: TShape;
    Image1: TImage;
    Shape5: TShape;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Button1: TButton;
    MSe: TComboBox;
    ZoomE: TComboBox;
    Xe: TEdit;
    Ye: TEdit;
    StaticText1: TStaticText;
    StaticText2: TStaticText;
    Sp: TCheckBox;
    Button4: TButton;
    Button2: TButton;
    Button3: TButton;
    CheckBox1: TCheckBox;
    Memo1: TMemo;
    Edit1: TEdit;
    Label3: TLabel;
    Button5: TButton;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    CheckBox2: TCheckBox;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    SaveDialog1: TSaveDialog;
    PB: TProgressBar;

   { function GetGoogleStaticMapURL( B,L: double; MapStyle, GoogleKey :string;
                                    ZoomLevel: integer):string;

    procedure GetGoogleStaticMap( URL:string;  var Image:TImage); }

    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure ImagemapMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Imagemap2MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Button1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CheckBox1Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    MyDir:String;
    ZoomA : Integer;
    GoogleKey: String;
  end;

var
  TestFm: TTestFm;
  SK42, WGS : Integer;
  Scale: Real;
  T:TTime;
  ZS: String;
  TmpDir: String;
  B, L, TX, TY, TX2, TY2 : Double;
  BLRect, BLRect2, BLRect3 : TBLRect;

const Sf: array [1..20] of double =
     (591657550.50,295828775.3,147914387.6,73957193.82,36978596.91,
     18489298.45,9244649.227,4622324.614,2311162.307,1155581.153,
     577790.5767,288895.2884,144447.6442,72223.822090,36111.911040,
     18055.955520,9027.977761,4513.988880,2256.994440,1128.497220);

      Sf2: array [0..20] of double = (156412, 78206, 39103, 19551, 9776, 4888,
                                      2444, 1222, 610.984, 305.492, 152.746,
                                      76.373, 38.187, 19.093, 9.547, 4.773,
                                      2.387, 1.193, 0.596, 0.298, 0.149);

implementation

{$R *.dfm}

var Point:TPoint;

procedure TTestFm.Button1Click(Sender: TObject);
var
  Url : string;
  B2, L2, B3, L3 : Double;
begin

  B := StrToFloat2(Xe.Text);
  L := StrToFloat2(Ye.Text);

  Url := GetGoogleStaticMapURL(B,L, MSE.Items[MSE.ItemIndex], GoogleKey, ZoomA);
  if CheckBox2.Checked then
   GetGoogleStaticMap(URL, ImageMap);

  GetNextBLRight (B, L , ZoomA, B2, L2);
  Url := GetGoogleStaticMapURL(B2,L2, MSE.Items[MSE.ItemIndex], GoogleKey, ZoomA);
  if CheckBox2.Checked then
    GetGoogleStaticMap(URL, ImageMap2);

  GetNextBLDown (B, L , ZoomA, B3, L3);
  Url := GetGoogleStaticMapURL(B3,L3, MSE.Items[MSE.ItemIndex], GoogleKey, ZoomA);
  if CheckBox2.Checked then
     GetGoogleStaticMap(URL, Image1);

  Label10.Caption := DegToDMS(B,true,5)+#13+DegToDMS(L,false,5);
  Label11.Caption := DegToDMS(B2,true,5)+#13+DegToDMS(L2,false,5);
  Label12.Caption := DegToDMS(B3,true,5)+#13+DegToDMS(L3,false,5);

  BLRect := GetBLBounds(B,L,ZoomA);
  Label4.Caption := DegToDMS(BLRect.B[1],true,5)+#13+DegToDMS(BLRect.L[1],false,5);
  Label5.Caption := DegToDMS(BLRect.B[2],true,5)+#13+DegToDMS(BLRect.L[2],false,5);
  Label6.Caption := DegToDMS(BLRect.B[3],true,5)+#13+DegToDMS(BLRect.L[3],false,5);
  Label7.Caption := DegToDMS(BLRect.B[4],true,5)+#13+DegToDMS(BLRect.L[4],false,5);

  BLRect3 := GetBLBounds(B3,L3,ZoomA);
  Label6.Caption := Label6.Caption+#13+DegToDMS(BLRect3.B[1],true,5)+#13+DegToDMS(BLRect3.L[1],false,5);
  Label7.Caption := Label7.Caption+#13+DegToDMS(BLRect3.B[2],true,5)+#13+DegToDMS(BLRect3.L[2],false,5);

  BLRect2 := GetBLBounds(B2,L2,ZoomA);
  Label8.Caption := DegToDMS(BLRect.B[2],true,5)+#13+DegToDMS(BLRect.L[2],false,5);
  Label9.Caption := DegToDMS(BLRect.B[4],true,5)+#13+DegToDMS(BLRect.L[4],false,5);
  Label14.Caption := DegToDMS(BLRect.B[1],true,5)+#13+DegToDMS(BLRect.L[1],false,5);
  Label13.Caption := DegToDMS(BLRect.B[3],true,5)+#13+DegToDMS(BLRect.L[3],false,5);


  /// For IMGS

  StaticText1.Caption := IntToStr(ZoomA);
  PVMtoUTM  (WGS, B, L, TY, TX );
  UTMToPVM(WGS, TY, TX + Scale*512, B2, L2);
  PVMtoUTM  (WGS, B2, L2, TY2, TX2 );
  Scale := Sf2[ZoomA];

  if Scale > 1 then
    ZS := IntToStr(trunc(Scale))
    else
      ZS := format('%.3f',[Scale]);

end;


procedure TTestFm.FormCreate(Sender: TObject);
var El : TEllipsoid;
begin
//IdHTTP1.ProxyParams.ProxyServer := 'http://proxyaddress';
 // idHTTP1.ProxyParams.ProxyPort := 8080;
//  idHttp1.request.useragent :=
//  'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0; MAAU)';

  Geoinit('Data\Sources.loc');
  SK42 := FindDatum('SK42');
  WGS  := FindDatum('WGS84');
  ZoomA:=10;

  MyDir := GetCurrentDir;

  TmpDir := MyDir+'\GoogleTmp';
  if DirectoryExists(TmpDir)=false then
      ForceDirectories(TmpDir);

  TX := -1;
  TY := -1;
  TX2 := -1;
  TY2 := -1;

  T := Now;
end;

procedure TTestFm.FormDestroy(Sender: TObject);
begin

  CloseAsdbContainer;
end;

procedure TTestFm.Button3Click(Sender: TObject);
var
  StreamData :TMemoryStream;
  JPEGImage  : TJPEGImage;
  Url        : string;

  AX, AY, AB, AL :double;


  Zone: Integer;
  Azone: boolean;

  Zoom, MS, XX, YY: string;
begin

  Azone := True;

  AB := StrToFloat2(Xe.Text);
  AL := StrToFloat2(Ye.Text);

  PVMtoUTM(WGS, AB, AL, AY, AX );

  Showmessage(' B: '+ DegToDMS(AB,true,5)    + ' L: '+ DegToDMS(AL,false,5)
             +' // N: '+ format('%.3f',[AY]) + ' E: ' +format('%.3f',[AX]));

  UTMToPVM(WGS, AY, AX, AB, AL);

  Showmessage(' B: '+ DegToDMS(AB,true,5)    + ' L: '+ DegToDMS(AL,false,5)
             {+' // N: '+ format('%.3f',[AY]) + ' E: ' +format('%.3f',[AX])});
  
 { Zoom := ZoomE2.Items[ZoomE2.ItemIndex];
  MS :=  MSE.Items[MSE.ItemIndex];

  XX := '1385';
  yy := '3143';


  Url        :='http://mt1.google.com/vt/lyrs=y&x=+'+XX+'+&y='+YY+'&z='+Zoom;

  StreamData := TMemoryStream.Create;
  JPEGImage  := TJPEGImage.Create;
  try
    try
     idhttp1.Get(Url, StreamData); //Send the request and get the image
     StreamData.Seek(0,soFromBeginning);
     JPEGImage.LoadFromStream(StreamData);//load the image in a Stream
     ImageMap.Picture.Assign(JPEGImage);//Load the image in a Timage component
    Except On E : Exception Do
     MessageDlg('Exception: '+E.Message,mtError, [mbOK], 0);
    End;
  finally
    StreamData.free;
    JPEGImage.Free;
  end;    }

  //// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! url = "http://mt1.google.com/vt/lyrs=y&x="+x+"&y="+y+"&z="+zoom;
end;

procedure TTestFm.Button2Click(Sender: TObject);
var
  D, M, Y, h, mi, s, msc: word;
  das: string;
  FN : string;
begin
 if SaveDialog1.Execute then
 Begin
       DecodeDate(now,y, m, d);
       Decodetime(now,h, mi, s, msc);
       das := IntTostr(y)+'-'+IntTostr(m)+'-'+IntTostr(d)+
           '_'+IntTostr(h)+'-'+ IntTostr(m) +'-'+IntTostr(s);


       CropImageToFiles(ImageMap, TmpDir, das+'_1', True);
       AddRectToBoundsList(BLRect,TmpDir, das+'_1');

       CropImageToFiles(Image1, TmpDir, das+'_3', True);
       AddRectToBoundsList(BLRect3,TmpDir, das+'_3');

       CropImageToFiles(ImageMap2, TmpDir, das+'_2', True);
       AddRectToBoundsList(BLRect2,TmpDir, das+'_2');

       FN := SaveDialog1.Filename;
       if InitAsdbContainer(FN, true) then
         PackAllToAsdb(true, nil);

     //  if InitAsdbContainer(FN, true) then
      //    PackFilesToAsdb(das+'_1', FN, TmpDir, true, PB);
       //AddGoogle(Imagemap,TmpDir, das+'_1', True);

       //ImageMap.Picture.SaveToFile(das+'_1.jpg');
       // ImageMap2.Picture.SaveToFile(das+'_2.jpg');
       // Image1.Picture.SaveToFile(das+'_3.jpg');  }
 End;
end;

procedure TTestFm.FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
 if now-T < 0.25/(24*3600) then
   exit;

  T := now;

 if ZoomA<20 then
 Begin
    Inc(ZoomA);
    Button1.Click;
 End;
end;

procedure TTestFm.FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
 if now-T < 0.25/(24*3600) then
   exit;
 T := now;

 if ZoomA>8 then //1
 Begin
    Dec(ZoomA);
    Button1.Click;
 End;
end;

procedure TTestFm.ImagemapMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var AX, AY, AB, AL:Double;
begin
 if TX <>-1 then Begin
   AX := TX + (X-256)*Scale;
   AY := TY - (Y-256-15)*Scale;

   case Sp.Checked of
     false: UTMToGeo(WGS,  AY , AX , false, AB,AL);
     true: UTMToPVM(WGS, AY, AX, AB,AL);
   end;

   Caption :=  ' B: '+ DegToDMS(AB,true,5)    + ' L: '+ DegToDMS(AL,false,5)
             +' // N: '+ format('%.3f',[AY]) + ' E: ' +format('%.3f',[AX])
             +' // 1 px = '+ ZS +' meters';
 End;

 StaticText2.Caption := ' // ImgX: '+ IntTostr(X) + ' ImgY: ' +IntTostr(Y);
end;

procedure TTestFm.Imagemap2MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var AX, AY, AB, AL:Double;
begin
 if TX2 <>-1 then Begin
   AX := TX2 + (X-256)*Scale;
   AY := TY2 - (Y-256-15)*Scale;

   case Sp.Checked of
     false: UTMToGeo(WGS,  AY , AX , false, AB,AL);
     true: UTMToPVM(WGS,AY,AX,AB,AL);
   end;

   Caption :=  ' B: '+ DegToDMS(AB,true,5)    + ' L: '+ DegToDMS(AL,false,5)
             +' // N: '+ format('%.3f',[AY]) + ' E: ' +format('%.3f',[AX])
             +' // 1 px = '+ ZS +' meters';
 End;

 StaticText2.Caption := ' // ImgX: '+ IntTostr(X) + ' ImgY: ' +IntTostr(Y);
end;

procedure TTestFm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 if key=vk_F2 then
  Begin
    setcursorpos(Mouse.CursorPos.X,300);
  End;
end;

procedure TTestFm.Button1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
if key=vk_Space then
  Begin
    setcursorpos(Mouse.CursorPos.X,300);
  End;
end;

procedure TTestFm.CheckBox1Click(Sender: TObject);
begin
 Shape1.Visible := CheckBox1.Checked;
 Shape2.Visible := CheckBox1.Checked;
 Shape3.Visible := CheckBox1.Checked;
 Shape4.Visible := CheckBox1.Checked;
 Shape5.Visible := CheckBox1.Checked;


 Label4.Visible := CheckBox1.Checked;
 Label5.Visible := CheckBox1.Checked;
 Label6.Visible := CheckBox1.Checked;
 Label7.Visible := CheckBox1.Checked;
 Label8.Visible := CheckBox1.Checked;
 Label9.Visible := CheckBox1.Checked;
 Label10.Visible := CheckBox1.Checked;
 Label11.Visible := CheckBox1.Checked;
 Label12.Visible := CheckBox1.Checked;
 Label13.Visible := CheckBox1.Checked;
 Label14.Visible := CheckBox1.Checked;

end;

procedure TTestFm.Button4Click(Sender: TObject);
var
  StreamData :TMemoryStream;
  JPEGImage  : TJPEGImage;
  Url        : string;
  Zoom, MS : string;
  DS : Char;
  Zone: integer;
  AZone: boolean;

  B2, L2,Lo, B3, L3 : Double;
begin
 {
  DS := DecimalSeparator;
  DecimalSeparator :='.';

  Zoom := IntToStr(ZoomA);//ZoomE.Items[ZoomE.ItemIndex];
  MS :=  MSE.Items[MSE.ItemIndex];

  B := StrToFloat2(Xe.Text);
  L := StrToFloat2(Ye.Text);

  Scale := 156543.03392 * cos(B * PI / 180) /POWER(2,(Zooma));



  Azone :=true;

  case Sp.Checked of
     false:  GeoToUTM(WGS, B, L, false, TY, TX, zone, Azone);
     true:
      begin
         PVMtoUTM  (WGS, B, L, zone, Azone, TY, TX );
         Scale := Sf2[ZoomA];
      end;
  end;

  AZone :=true;

  if Scale > 1 then
    ZS := IntToStr(trunc(Scale))
    else
      ZS := format('%.3f',[Scale]);

  case Sp.Checked of
     false: UTMToGeo(WGS,  TY, TX + Scale*512, false, B2,L2);
     true:  UTMToPVM(WGS,  TY, TX + Scale*512, B2, L2);
  end;

  case Sp.Checked of
     false: UTMToGeo(WGS,  TY - Scale*512, TX, false, B3,L3);
     true:  UTMToPVM(WGS,  TY - Scale*512, TX, B3, L3);
  end;

  case Sp.Checked of
     false:  GeoToUTM(WGS, B2, L2, false, TY2, TX2, zone, Azone);
     true:   PVMtoUTM  (WGS, B2, L2, zone, Azone, TY2, TX2 );
  end;



  Url :='http://maps.google.com/maps/api/staticmap?' +
  'center='+ Format('%.11f',[B])+',' + Format('%.11f',[L])+
  '&zoom='+Zoom +
  '&size=512x542' +
  '&maptype='+MS +
  '&format=jpg' +
  '&sensor=false'+
  '&scale=1';

  StreamData := TMemoryStream.Create;
  JPEGImage  := TJPEGImage.Create;
  try
    try
     idhttp1.Get(Url, StreamData); //Send the request and get the image
     StreamData.Seek(0,soFromBeginning);
     JPEGImage.LoadFromStream(StreamData);//load the image in a Stream
     ImageMap.Picture.Assign(JPEGImage);//Load the image in a Timage component
    Except On E : Exception Do
       Caption:=('Exception: '+E.Message);
    End;
  finally
    StreamData.free;
    JPEGImage.Free;
  end;

  Memo1.Lines.Add(Url);


  ////////////////////2

   Url :='http://maps.google.com/maps/api/staticmap?' +
  'center='+ Format('%.11f',[B2])+',' + Format('%.11f',[L2])+
  '&zoom='+Zoom +
  '&size=512x542' +
  '&maptype='+MS +
  '&format=jpg' +
  '&sensor=false'+
  '&scale=1';

  StreamData := TMemoryStream.Create;
  JPEGImage  := TJPEGImage.Create;
  try
    try
     idhttp1.Get(Url, StreamData); //Send the request and get the image
     StreamData.Seek(0,soFromBeginning);
     JPEGImage.LoadFromStream(StreamData);//load the image in a Stream
     ImageMap2.Picture.Assign(JPEGImage);//Load the image in a Timage component
    Except On E : Exception Do
       Caption:=('Exception: '+E.Message);
    End;
  finally
    StreamData.free;
    JPEGImage.Free;
  end;

  Memo1.Lines.Add(Url);

  //////////////////////////// 3

   Url :='http://maps.google.com/maps/api/staticmap?' +
  'center='+ Format('%.11f',[B3])+',' + Format('%.11f',[L3])+
  '&zoom='+Zoom +
  '&size=512x542' +
  '&maptype='+MS +
  '&format=jpg' +
  '&sensor=false'+
  '&scale=1';

  StreamData := TMemoryStream.Create;
  JPEGImage  := TJPEGImage.Create;
  try
    try
     idhttp1.Get(Url, StreamData); //Send the request and get the image
     StreamData.Seek(0,soFromBeginning);
     JPEGImage.LoadFromStream(StreamData);//load the image in a Stream
     Image1.Picture.Assign(JPEGImage);//Load the image in a Timage component
    Except On E : Exception Do
       Caption:=('Exception: '+E.Message);
    End;
  finally
    StreamData.free;
    JPEGImage.Free;
  end;

  Memo1.Lines.Add(Url);



  DecimalSeparator := DS;

  Caption :=  ' B: '+ DegToDMS(B,true,5)    + ' L: '+ DegToDMS(L,false,5)
             +' // E: '+ format('%.3f',[TX]) + ' N: ' +format('%.3f',[TY])
             +' // 1 px = '+ ZS +' meters';

  StaticText1.Caption:= Zoom;     }
end;

{
procedure TForm1.GetGoogleStaticMap(URL:String; var Image: TImage);

var
  StreamData :TMemoryStream;
  JPEGImage  : TJPEGImage;

  IdHttp:TIdHttp;
begin

  IdHttp := TIdHttp.Create(Form1);

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
       Caption:=('Exception: '+E.Message);
    End;
  finally
    StreamData.free;
    JPEGImage.Free;
  end;

  Memo1.Lines.Add(Url);

  IdHttp.Destroy;
end;

function TForm1.GetGoogleStaticMapURL(B, L: double; MapStyle,
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
  '&scale=1'+
  '&key='+GoogleKey;

  DecimalSeparator := DS;
end;
        }
procedure TTestFm.Button5Click(Sender: TObject);
begin
//  Wform.ShowModal;
end;

procedure TTestFm.Edit1Change(Sender: TObject);
begin
  GoogleKey := Edit1.Text;
end;

end.

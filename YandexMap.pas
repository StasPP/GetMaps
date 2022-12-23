unit YandexMap;

interface

uses AsdbMap, MapFunctions, GoogleDownload, GeoFunctions, TabFunctions,
     AbstractCanvas, AbstractDevices, AsphyreImages, AsphyreTypes, Dialogs,
     Graphics, Jpeg, ExtCtrls, SysUtils, FLoader, BasicMapObjects, RTypes,
     DrawFunctions;

type
  TYandexCell = Record
    x, y, Gx, Gy :array [1..4] of Double;
    Ycenter :TLatLong; /// Center
    Zoom    :integer;
    BLRect  :TBLRect;
  end;

  procedure AddYandex(B, L :Double);
  procedure DoMultiAddYandex;

  procedure ReComputeYandex(WFZ: Boolean);
  procedure ResetYandex;
  procedure InitYandex(B,L: Double);
  function AlreadyHasYandex(B, L: Double):integer;
  function SearchYandex(SearchB, SearchL: Double; Zoom:Integer;
           var FoundB, FoundL: Double):boolean;
  function GetYandexCursor(B,L : Double):boolean;
  procedure DrawYandexCursor(AsphCanvas:TAsphyreCanvas; AsphImages: TAsphyreImages);
  procedure DrawYandex(AsphCanvas:TAsphyreCanvas; AsphImages: TAsphyreImages);

  procedure DownloadSelectedYandex;

  procedure YandexZoomUp;
  procedure YandexZoomDown;
  procedure YandexAutoZoom(Dist:real);

const
  YandexMapStyles : Array [0..2] of string = ('map','sat',
                                               'sat,skl');
  YandexLangs: Array [0..3] of string = ('en_US','ru_RU',
                                               'uk_UA', 'tr_TR');
  YandexLangNames:  Array [0..3] of string = ('English(USA)','Russian',
                                               'Ukrainian', 'Turkish');
var
  YandexCells  :array of TYandexCell;
  YandexCount  :integer = 0;
  YandexLang   :integer = 0;
  YandexInitBL :TLatLong;
  YandexCursor :TLatLong;
  YZoomA        :integer = 10;
  YandexKey    :string = '';
  YandexStyle  :string ='sat';
  ChoosedCell  :integer;
  YandexTmpDir :String;
  YandexOZIDir :String;

  YandexMultiAddBegin, YandexMultiAddEnd : TLatLong;
  YandexMultiAddMode :Boolean;
  YandexMultiAdd     :Boolean;

  FoundList :array of TLatLong;

implementation

procedure ResetYandex;
begin
  YandexInitBL.lat  := 0;
  YandexInitBL.long := 0;
  YandexCursor.lat  := 0;
  YandexCursor.long := 0;
  YandexCount := 0;
end;

procedure InitYandex(B,L: Double);
begin
  YandexInitBL.lat  := B;
  YandexInitBL.long := L;
  YandexCursor.lat  := B;
  YandexCursor.long := L;
end;

//////

function AlreadyHasYandex(B, L: Double):integer;
var
 i:integer;
 mapC : TMyPoint;
begin
  result := -1;
  MapC := BLtoMap(B, L, UTM, South, MyZone);
  for I := 0 to YandexCount - 1 do
    if YandexCells[I].Zoom = YZoomA then
     if PointInBox(YandexCells[I].x, YandexCells[I].y, MapC.x, MapC.y) then
        result := I;

end;

function SearchYandex(SearchB, SearchL: Double; Zoom:Integer;
   var FoundB, FoundL: Double):boolean;

  function PointInGeoBox(BL: TBLRect; B, L: Double): boolean;
  begin
     result :=  IsPIn_Vector(BL.B[1], BL.L[1], BL.B[3], BL.L[3],
       BL.B[4], BL.L[4],  B, L)
       or IsPIn_Vector(BL.B[4], BL.L[4], BL.B[2], BL.L[2],
       BL.B[1], BL.L[1],  B, L);
  end;

const
  maxiter = 10000;
var
  found: boolean;
  iter : integer;
  BLR, BLA, BLB : TBLRect;
  BA, LA, BB, LB : Double;

begin
  found := false;
  iter  := 0;
  repeat
    BLR := GetBLBounds(FoundB, FoundL, Zoom);
    found := PointInGeoBox(BLR, SearchB, SearchL);

    if not found then
    Begin
        if FoundB < SearchB then
        GetNextBLUp (FoundB, FoundL, Zoom, BA, LA)
           else
              if FoundB > SearchB then
                GetNextBLDown (FoundB, FoundL, Zoom, BA, LA);
                //  else
                //    BLA := BLR;

        BLA := GetBLBounds(BA, LA, Zoom);

        found := PointInGeoBox(BLA, SearchB, SearchL);
        if found then
        begin
           FoundB := BA;
           FoundL := LA;
        end;
    End;

    if not found then
    Begin
        if FoundL < SearchL then
        GetNextBLRight (FoundB, FoundL, Zoom, BB, LB)
           else
             if FoundL > SearchL then
              GetNextBLLeft (FoundB, FoundL, Zoom, BB, LB) ;
               //  else
                 //   BLA := BLR;

        BLB := GetBLBounds(BB, LB, Zoom);

        found := PointInGeoBox(BLB, SearchB, SearchL);
        if found then
        begin
           FoundB := BB;
           FoundL := LB;
        end;
    End;

    if not found then
    Begin
      FoundB := BA;
      FoundL := LB;
    End;

    inc(iter);
  until (found) or (iter >= maxiter);
  Result := found;
end;

function GetYandexCursor(B, L : Double):boolean;
begin
  Result := SearchYandex( B, L, YZoomA, YandexCursor.lat, YandexCursor.long );
end;

procedure AddYandex(B, L: Double);
var I :integer;
    BLR : TBLRect;
begin
   // if not GetYandexCursor( B, L) then
   //   exit;
    ChoosedCell :=-1;
    if not YandexMultiAdd then
      ChoosedCell := AlreadyHasYandex(YandexCursor.lat, YandexCursor.long);

    if ChoosedCell<>-1 then
    Begin
      YandexCells[ChoosedCell]:= YandexCells[YandexCount-1];
      Dec(YandexCount);
      SetLength(Yandexcells,YandexCount);
      exit;
    End;

   if not YandexMultiAdd then
    for I := 0 to YandexCount - 1 do
    if (Abs(YandexCursor.lat - YandexCells[i].Ycenter.lat)
          < (YandexCells[I].BLRect.B[1] - YandexCells[I].BLRect.B[4])/2) and
       (Abs(YandexCursor.long - YandexCells[i].Ycenter.long) <
          (YandexCells[I].BLRect.L[4] - YandexCells[I].BLRect.L[1])/2) and
       (YZoomA = YandexCells[i].Zoom) then
      exit;

    BLR := GetBLBounds(B, L, YZoomA);

    inc(YandexCount);
    Setlength(YandexCells, YandexCount);

    YandexCells[length(YandexCells)-1].BLRect := BLR;

    YandexCells[length(YandexCells)-1].Ycenter.Lat  := B;
    YandexCells[length(YandexCells)-1].Ycenter.Long := L;

    YandexCells[length(YandexCells)-1].Gx[1] :=  BLR.B[1];
    YandexCells[length(YandexCells)-1].Gy[1] :=  BLR.L[1];
    YandexCells[length(YandexCells)-1].Gx[2] :=  BLR.B[2];
    YandexCells[length(YandexCells)-1].Gy[2] :=  BLR.L[2];
    YandexCells[length(YandexCells)-1].Gx[3] :=  BLR.B[4];
    YandexCells[length(YandexCells)-1].Gy[3] :=  BLR.L[4];
    YandexCells[length(YandexCells)-1].Gx[4] :=  BLR.B[3];
    YandexCells[length(YandexCells)-1].Gy[4] :=  BLR.L[3];

    YandexCells[length(YandexCells)-1].Zoom := YZoomA;

    if length(YandexCells)=1 then
    Begin
      YandexInitBL.lat  := B;
      YandexInitBL.long := L;
      YandexCursor := YandexInitBL;
    End;

    RecomputeYandex(false);
end;

procedure ReComputeYandex(WFZ: Boolean);
var i,j :integer;
    xx, yy:Double;
begin
   WaitForZone := WFZ;

   for I := 0 to Length(YandexCells)- 1 do
      for j := 1 to 4 do
      Begin
         if UTM then
            GeoToUTM(WGS,YandexCells[i].Gx[j],YandexCells[i].Gy[j],South, yy,xx, Myzone, WaitForZone)
               else
                   WGSToSK(YandexCells[i].Gx[j],YandexCells[i].Gy[j],0, xx,yy, MyZone, WaitForZone);

         YandexCells[i].x[j] := xx;
         YandexCells[i].y[j] := yy;
         WaitForZone := false;
      End;
end;

procedure GetFoundList;
var Lb, Le, Bb, Be : Double;

function inBox(BL :TBLRect):boolean;
begin
   result := (BL.L[4] > Lb) and (BL.B[1] >  Bb)
         and (BL.L[1] < Le) and (BL.B[4] <  Be);
end;

var   I :integer;
      cB, cL : Double;
      startB, startL, endB, endL : Double;
      BLR :TBLRect;
begin
     //GetYandexCursor(YandexCursor.lat, YandexCursor.long);

     SetLength(FoundList,0);

     Bb := YandexMultiAddBegin.lat;
     Be := YandexMultiAddEnd.lat;
     Lb := YandexMultiAddBegin.long;
     Le := YandexMultiAddEnd.long;

     if YandexMultiAddBegin.lat > YandexMultiAddEnd.lat then
     Begin
       Bb := YandexMultiAddEnd.lat;
       Be := YandexMultiAddBegin.lat;
     End;

     if YandexMultiAddBegin.long > YandexMultiAddEnd.long then
     Begin
       Lb := YandexMultiAddEnd.long;
       Le := YandexMultiAddBegin.long;
     End;

     //YandexCursor := YandexInitBL;
     StartB := YandexInitBL.lat; StartL := YandexInitBL.long;
     //YandexCursor.long;
     SearchYandex(Bb, Lb, YZoomA, StartB, StartL);
   //  Bb := StartB; Lb := StartL;


     //// ασττεπ
     cB := StartB;
     cL := StartL;
     SearchYandex(cB, cL, YZoomA, cB, cL);

     BLR := GetBLBounds(cB, cL, YZoomA);

     {startB := Bb - (BLR.B[1] - BLR.B[4])*(ZoomA-4);
     startL := Lb - (BLR.L[4] - BLR.L[1])*(ZoomA-6); }
     endB := Be + abs(BLR.B[1] - BLR.B[4])*(YZoomA-4);
     endL := Le + abs(BLR.L[4] - BLR.L[1])*(YZoomA-6);

     for I := 1 to (YZoomA-6) do
       GetNextBLDown(cB, cL, YZoomA, cB, cL);
     for I := 1 to (YZoomA-4) do
       GetNextBLLeft(cB, cL, YZoomA, cB, cL);
     startB := cB;
     StartL := cL;
     //// 1-ÿ ÿχεικΰ

     cB := startB;
     cL := startL;
     SearchYandex(cB, cL, YZoomA, cB, cL);

      repeat

       repeat
         GetNextBLRight(cB, cL, YZoomA, cB, cL);
         BLR := GetBLBounds(cB, cL, YZoomA);
         if inBox(BLR) then
         Begin
           SetLength(FoundList,Length(FoundList)+1);

           FoundList[Length(FoundList)-1].Lat := cB;
           FoundList[Length(FoundList)-1].Long := cL;
         End;
       until BLR.L[4] > endL;

       cL := startL;
       SearchYandex(cB, cL, YZoomA, cB, cL);
       GetNextBLUp(cB, cL, YZoomA, cB, cL);

      until BLR.B[1] > endB;

     YandexCursor := YandexInitBL;
end;

procedure DrawYandexCursor(AsphCanvas:TAsphyreCanvas; AsphImages: TAsphyreImages);
var
  i, j, imgN: integer;
  _C, C : Array[1..4] of TMyPoint;
  BLR : TBLRect;
  L, xmin, ymin, xmax, ymax: Double;

  Col: TColor4;

  FStart, FEnd: TMyPoint;
begin

   if YandexMultiAdd then
   BEGIN



      GetFoundList;
      Col :=  cRGB4(255,255,255,100);
      ImgN := AsphImages.IndexOf('addcell.image');
      if YandexMultiAddMode then
      for I := 0 to Length(FoundList) - 1 do
      Begin
        BLR := GetBLBounds(FoundList[I].lat, FoundList[I].long, YZoomA);
        for j := 1 to 4 do
        Begin
           _C[j] := BLToMap(BLR.B[j], BLR.L[j], UTM, South, MyZone);
           _C[j] := MapToScreen(_C[j].x ,_C[j].y);
        End;



        AsphCanvas.UseImagePx(AsphImages.Items[ImgN], pxBounds4(0, 0, 256, 256));

        AsphCanvas.TexMap(Point4( _C[1].x, _C[1].y,  _C[2].x, _C[2].y,
                                  _C[4].x, _C[4].y,  _C[3].x, _C[3].y), col);

      End;

      if YandexMultiAddMode then
         Col :=  cRGB4(0,255,0,100)
          else
            Col :=  cRGB4(255,0,0,100);

      _C[1] := BLToScreen(YandexMultiAddBegin.lat,YandexMultiAddBegin.long);
      _C[2] := BLToScreen(YandexMultiAddEnd.lat,YandexMultiAddEnd.long);
      DrawZone(AsphCanvas, _C[1].x, _C[1].y, _C[1].x, _C[2].y, _C[2].x,
                           _C[2].Y, _C[2].x, _C[1].Y, Col);


   END
    ELSE
    BEGIN

      ChoosedCell := AlreadyHasYandex(YandexCursor.lat, YandexCursor.long);

      BLR := GetBLBounds(YandexCursor.lat, YandexCursor.long, YZoomA);
      for j := 1 to 4 do
      Begin
          _C[j] := BLToMap(BLR.B[j], BLR.L[j], UTM, South, MyZone);
          _C[j] := MapToScreen(_C[j].x ,_C[j].y);
      End;

       try
          L := sqrt(sqr(_C[4].x - _C[1].x) + sqr(_C[4].y - _C[1].y));
       except
         exit
       end;

       xmin := _C[1].x;
       ymin := _C[1].y;
       xmax := _C[1].x;
       ymax := _C[1].y;

       for j := 2 to 4 do
       begin
         if _C[j].x < xmin then
           xmin := _C[j].x;
         if _C[j].y < ymin then
           ymin := _C[j].y;

         if _C[j].x > xmax then
           xmax := _C[j].x;
         if _C[j].y > ymax then
           ymax := _C[j].y;
       end;

       if (xmax<0)and(xmin<0) or (xmax > DispSize.X)and(xmin > DispSize.X) then
           exit;

       if (ymax<0)and(ymin<0) or (ymax > DispSize.Y)and(ymin > DispSize.Y) then
           exit;

       
       Col := clWhite4;
       if ChoosedCell<>-1 then
          ImgN := AsphImages.IndexOf('delcell.image')
          else
          begin
            ImgN := AsphImages.IndexOf('addcell.image');
            Col :=  cRGB4(255,255,255,100);
          end;

       AsphCanvas.UseImagePx(AsphImages.Items[ImgN], pxBounds4(0, 0, 256, 256));

       AsphCanvas.TexMap(Point4( _C[1].x, _C[1].y,  _C[2].x, _C[2].y,
                                 _C[4].x, _C[4].y,  _C[3].x, _C[3].y), Col);

  END;

end;

procedure DrawYandex(AsphCanvas:TAsphyreCanvas; AsphImages: TAsphyreImages);
var I, J, ImgN :Integer;
    L, xmin, ymin, xmax, ymax : Double;
    _C : Array[1..4] of TMyPoint;
    Col : TColor4;
    FStart, FEnd : TMyPoint;
    isCut : boolean;
begin

  if YandexCount=0 then
     exit;

  if (YandexMultiAdd)and(YandexMultiAddMode=false) then
  Begin
    FStart := BLtoMap(YandexMultiAddBegin.Lat, YandexMultiAddBegin.Long);
    FEnd := BLtoMap(YandexMultiAddEnd.Lat, YandexMultiAddEnd.Long);
  End;

  for I := 0 to Length(YandexCells) - 1 do
    Begin
       if I = ChoosedCell then
          continue;
          
       for j := 1 to 4 do
       Begin
          _C[j] := MapToScreen(YandexCells[i].x[j],YandexCells[i].y[j]);
       End;

       try
          L := sqrt(sqr(_C[4].x - _C[1].x) + sqr(_C[4].y - _C[1].y));
       except
         continue;
       end;

       {if (L < 5 * MinMap) then
         continue;

       if (L > 5 * MaxMap) then
         continue;}

       xmin := _C[1].x;
       ymin := _C[1].y;
       xmax := _C[1].x;
       ymax := _C[1].y;
       for j := 2 to 4 do
       begin
         if _C[j].x < xmin then
           xmin := _C[j].x;
         if _C[j].y < ymin then
           ymin := _C[j].y;

         if _C[j].x > xmax then
           xmax := _C[j].x;
         if _C[j].y > ymax then
           ymax := _C[j].y;
       end;

       if (xmax<0)and(xmin<0) or (xmax > DispSize.X)and(xmin > DispSize.X) then
           continue;

       if (ymax<0)and(ymin<0) or (ymax > DispSize.Y)and(ymin > DispSize.Y) then
           continue;

       if (YandexMultiAdd)and(YandexMultiAddMode=false)and(YandexCells[I].Zoom = YZoomA) then
         isCut := BoxInBox(YandexCells[I].x, YandexCells[I].y, FStart.x, FStart.y,
                  FEnd.x, FEnd.y)
           else
             isCut := false;

       if isCut then
          ImgN := AsphImages.IndexOf('delcell.image')
          else
            ImgN := AsphImages.IndexOf('okcell.image');

       AsphCanvas.UseImagePx(AsphImages.Items[ImgN], pxBounds4(0, 0, 256, 256));

       if YZoomA = YandexCells[i].Zoom then
         Col := clWhite4
              else
                Col := cRGB4(255,255,255,100);

       AsphCanvas.TexMap(Point4( _C[1].x, _C[1].y,  _C[2].x, _C[2].y,
                                 _C[3].x, _C[3].y,  _C[4].x, _C[4].y),Col);

   End;

end;


procedure DownloadSelectedYandex;

  function GetNameByTime:string;
  var  D, M, Y, h, mi, s, msc: word;
  begin
      DecodeDate(now,y, m, d);
      DecodeTime(now,h, mi, s, msc);
      result := 'Yandex_'+IntTostr(y)+'-'+IntTostr(m)+'-'+IntTostr(d)+
           '_'+IntTostr(h)+'-'+ IntTostr(mi) +'_'+ IntTostr(s)+'_';
  end;

var
  Url : string;

  SaveD: TSaveDialog;
  ImageMap :TImage;

  I, j, k :Integer;

  ImgNames, FN : String;

  SortedYandex: Array of TYandexCell;
begin
  if YandexCount = 0 then
    exit;

  ImageMap := TImage.Create(nil);
  SaveD := TSaveDialog.Create(nil);

  ImgNames := GetNameByTime;

  SetLength(SortedYandex,YandexCount);

  K := 0;
  for I := 0 to YandexCount - 1 do
     for J := 6 to 18 do
      if YandexCells[i].Zoom = J then
        begin
          SortedYandex[k] := YandexCells[i];
          inc(K);
        end;


  if SaveD.Execute then
  Begin
       FLoadGPS.Show;
       FN := SaveD.Filename;
       FLoadGPS.LCount.Visible  := true;
       FLoadGPS.Label1.Show;
       FLoadGPS.Label2.Hide;
       FLoadGPS.MapLoad.Hide;
       FLoadGPS.LCount.Caption  := IntToStr(0) + ' / ' + IntToStr(YandexCount);
       FloadGPS.ProgressBar1.Position := 0;
       FLoadGPS.Repaint;

    for I := 0 to YandexCount - 1 do
    Begin
      Url := GetYandexStaticMapURL(SortedYandex[I].Ycenter.Lat,
             SortedYandex[I].Ycenter.Long, YandexStyle, YandexKey,
             YandexLangs[YandexLang], SortedYandex[I].Zoom);

      GetYandexStaticMap(URL, YandexStyle, ImageMap);

      CropImageToFiles256(ImageMap, YandexTmpDir, ImgNames+IntTostr(I), True);
      AddRectToBoundsList(SortedYandex[I].BLRect, YandexTmpDir, ImgNames+IntTostr(I));

      FLoadGPS.LCount.Caption  := IntToStr(I) + ' / ' + IntToStr(YandexCount);
      FloadGPS.ProgressBar1.Position := trunc(I*100/(YandexCount-1));
      FloadGPS.Repaint;
    End;

       if InitAsdbContainer(FN, true) then
       begin
         PackAllToAsdb(true, nil);
         ExportAllToOzi(YandexOZIDir, YandexTmpDir);
         ResetYandex;
         LoadMaps(FN, YandexTmpDir, AsphMapImages);
       end;
  End;

  FloadGPS.Hide;


  SaveD.Free;
  ImageMap.Free;
end;

procedure YandexZoomUp;
begin
   if YZooma < 16 then
    begin
      inc(YZooma);
      inc(YZooma);
      YandexCursor := YandexInitBL;
      GetYandexCursor(CanvCursorBL.lat,CanvCursorBL.long);
    end;
end;

procedure YandexZoomDown;
begin
  if YZooma > 8 then
    Begin
      dec(YZooma);
      dec(YZooma);
      YandexCursor := YandexInitBL;
      GetYandexCursor(CanvCursorBL.lat,CanvCursorBL.long);
    End;
end;

procedure YandexAutoZoom(Dist:real);
var I:integer;
begin
  I := 8;
  YZoomA := I;
  repeat                           {256}
    if Dist >= GoogleTileScales[I]*420 then
    begin
      YZoomA := I;
      break;
    end;
    I := I +2;
  until I > 16;
  YZoomA := I;
end;

procedure DoMultiAddYandex;
var I:integer;
     Bi, Li : Double;
     FStart, FEnd : TMyPoint;
begin

  FStart := BLtoMap(YandexMultiAddBegin.Lat, YandexMultiAddBegin.Long);
  FEnd := BLtoMap(YandexMultiAddEnd.Lat, YandexMultiAddEnd.Long);

  for I := YandexCount - 1 Downto 0 do
    if YandexCells[I].Zoom = YZoomA then
      if BoxInBox(YandexCells[I].x, YandexCells[I].y, FStart.x, FStart.y,
                  FEnd.x, FEnd.y) then
      Begin
        YandexCells[I] := YandexCells[YandexCount-1];
        dec(YandexCount);
      End;

      SetLength(YandexCells,YandexCount);


   if YandexMultiAddMode then
   Begin
      GetFoundList;
      for i := 0 to Length(FoundList) - 1 do
        AddYandex(FoundList[I].lat, FoundList[I].long);

   End;


   YandexMultiAdd := false;

end;

end.

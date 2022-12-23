unit Geoid;

interface

uses Classes, SysUtils, Dialogs, GeoString, TabFunctions;

type

TGridPoint = record
  Lat, Long : Double;
  DeltaH    : Double;
end;

TGridCell = record
  A, B, C, D : TGridPoint;
end;

TGeoidGrid = record
  NameID      :String;
  Caption     :String;
  FileName    :String;
  Grid        :Array of TGridPoint;
end;

TGeoidMeta = record
  B1, B2, L1, L2 :Double;
  NameID      :String;
  Caption     :String;
  Discription :String;
  FileName    :String;
end;

function Inter4( A, B, C, D :Double; kx, ky :Double) :Double;

        ////////////////////// --- ѕќя—Ќ≈Ќ»≈   INTER4 --- //////////////////////
        //                                                                    //
        //  ÷ель: »нтерпол€ци€ значени€ внутри €чейки регул€рной сетки (GRID) //
        //                                                                    //
        //  A, B, C, D - значени€ в узлах сетки.                              //
        //                                                                    //
        //     kx                                                             //
        //   A-|----B    kx - положение (доли от 1) точки E внутри грида по x //
        //   | |    |    ky - положение (доли от 1) точки E внутри грида по y //
        //   | *--- ky                                                        //
        //   |  E   |                                                         //
        //   C------D                                                         //
        //                                                                    //
        ////////////////////////////////////////////////////////////////////////

function GetKx( A, B, E:Double): Double;    //// A, B, E - координата по x или y

procedure ResetGeoids;
procedure LoadGeoid   (FileName :String);
procedure ReLoadGeoid (FileName :String; N: Integer);
procedure DeleteGeoid (N:Integer);

procedure SaveGeoidsMeta(Dir : String);
procedure GetGeoidsMeta(Dir : String);

function FindGeoidByCaption (Caption:String): Integer;
function FindGeoid (IDName:String): Integer;
function FindGeoidMetaByCaption (Caption:String): Integer;
function FindGeoidMeta (IDName:String): Integer;

function FindCell ( GeoidN: Integer; B, L :Double):TGridCell;
function GetGeoidH( GeoidN : Integer; B, L :Double):Double;

var
  GeoidList       : Array of TGeoidGrid;
  GeoidsMetaData  : Array of TGeoidMeta;
  GeoidDir        : String;

implementation


////////////////////////////////////////////////////////////////////////////////

function Inter4( A, B, C, D :Double; kx, ky :Double) :Double;
var Ak, Ck : Double;
begin
  Ak := A + kx*(B-A);
  Ck := C + kx*(D-C);
  Result := Ak + ky*(Ck - Ak);
end;

function GetKx( A, B, E:Double): Double;
begin
  Result := 0;
  if B - A = 0 then
    exit;

  Result := (E-A)/(B-A);
end;

////////////////////////////////////////////////////////////////////////////////

procedure ResetGeoids;
begin
  SetLength(GeoidList, 0);
end;

procedure DeleteGeoid (N:Integer);
var I:Integer;
begin
  For I := N to Length(GeoidList)-2 Do
      GeoidList[I] := GeoidList[I+1];

  I := Length(GeoidList);
  SetLength(GeoidList, I-1);
end;

procedure LoadGeoid   (FileName :String);
var N :Integer;
begin
  N := Length(GeoidList);
  SetLength(GeoidList, N+1);
  ReLoadGeoid(FileName, N);
end;

const EndHeadS = 'end_of_head';
      NameIDS  = 'modelname';
      CaptionS = 'caption';
      EmptyS   = 'EMPTYSTRING';
      B1S = 'latlimit_north'; B2S = 'latlimit_south';
      L1S = 'longlimit_west'; L2S = 'longlimit_east';

procedure ReLoadGeoid (FileName :String; N: Integer);
var I, J:Integer;
    S   :TStringlist;
    Str :String;
begin
   /// Init
   S := TStringList.Create;
   S.LoadFromFile(FileName);
   I := 0;

   /// Header
   repeat
     Str := S[I];

     if Str = '' then
     begin
        Str := EmptyS;
        continue;
     end;

     GeoidList[N].FileName := FileName;

     if Pos(NameIDS, AnsiLowerCase(Str)) > 0 then
        GeoidList[N].NameID := GetCols(Str,1,GetColCount(Str,' '),' ',false);

     if Pos(CaptionS, AnsiLowerCase(Str)) > 0 then
        GeoidList[N].Caption := GetCols(Str,1,GetColCount(Str,' '),' ',false);

     inc(I);
   until (Pos(EndHeadS, Str) > 0) or (I >= S.Count - 1);

   /// Check Data
   if (GeoidList[N].NameID = '') then
   begin
     MessageDlg('No Geoid header data found!', mtError, [mbOk], 0);
     DeleteGeoid(N);
     exit;
   end;

   if (GeoidList[N].Caption = '') then
   Begin
       GeoidList[N].NameID  := GeoidList[N].FileName;
       GeoidList[N].Caption := GeoidList[N].NameID;
   End;

   inc(I);
   if (I >= S.Count - 1) then
   begin
     MessageDlg('No Geoid body data found!', mtError, [mbOk], 0);
     DeleteGeoid(N);
     exit;
   end;

   J := S.Count - I ;
   SetLength(GeoidList[N].Grid, J+1);

   /// Body
   J := 0;
   repeat
     Str := AnsiLowerCase(S[I]);

     if Str = '' then
     begin
        inc(I);
        continue;
     end;

     GeoidList[N].Grid[J].Lat    := StrToFloat2( GetCols(Str,1,1,' ',false));
     GeoidList[N].Grid[J].Long   := StrToFloat2( GetCols(Str,0,1,' ',false));
     GeoidList[N].Grid[J].DeltaH := StrToFloat2( GetCols(Str,2,1,' ',false));

     inc(I);
     inc(J);
   until (I >= S.Count - 1);

   SetLength(GeoidList[N].Grid, J+1);

   S.Free;
end;

////////////////////////////////////////////////////////////////////////////////

function FindGeoidByCaption (Caption:String): Integer;
var I:Integer;
begin
  Result := -1;
  For I := 0 To Length(GeoidList)-1 Do
  If GeoidList[I].Caption = Caption then
  Begin
    Result := I;
    Break;
  End;
end;

function FindGeoid (IDName:String): Integer;
var I:Integer;
begin
  Result := -1;
  For I := 0 To Length(GeoidList)-1 Do
  If GeoidList[I].NameID = IDName then
  Begin
    Result := I;
    Break;
  End;
end;

procedure GetGeoidsMeta(Dir : String);
  procedure AddFiles(Dir:string; var FileList:TStringList);
  var
   SearchRec : TSearchrec;
  begin
    if FindFirst(Dir + '*.*', faAnyFile, SearchRec) = 0 then
    begin
      if (SearchRec.Name<> '')
        and(SearchRec.Name <> '.')
        and(SearchRec.Name <> '..')
        and not ((SearchRec.Attr and faDirectory) = faDirectory) then
          FileList.Add(SearchRec.Name);
      while FindNext(SearchRec) = 0 do
        if (SearchRec.Name <> '')
          and(SearchRec.Name <> '.')
          and(SearchRec.Name <> '..')
          and not ((SearchRec.Attr and faDirectory) = faDirectory)  then
             FileList.Add(SearchRec.Name);
      FindClose(Searchrec);
    end;
  end;

var S, S2, S3   :TSTringList;
    I, J, K     :Integer;
    Str         :String;
    NeedRefresh :Boolean;
begin
  GeoidDir := Dir;

  S  := TSTringList.Create;
  S2 := TSTringList.Create;
  S3 := TSTringList.Create;

  AddFiles(Dir, S);
  SetLength(GeoidsMetaData, S.Count);

  if Dir[Length(Dir)] <> '\' then
     Dir := Dir + '\';

  if Fileexists(DIR+'Geoids.loc') then
  Begin
    S2.LoadFromFile(DIR+'Geoids.loc');
    // ѕроверка имен файлов

    for I := 0 To S2.Count - 2 Do
       if S2[I] = '///---' then
         S3.Add(S2[I+1]);

    K := 0;
    for I := 0 To S.Count - 1 Do
      for j := 0 To S3.Count - 1 Do
        if S[I] = S3[J] then
        begin
          inc(K);
          break;
        end;

    j := 0;
    for I := 0 To S.Count-1 Do
      if Pos ('.gdf', S[I]) > 0 then
        Inc(j);

    NeedRefresh := (K <> J) or (S3.Count <> J);

    if NeedRefresh = false then
    begin
      K := 0;
      I := 0; J := 0;
      repeat
        Inc(I);

        if I >= S2.Count -1 then
          break;
        if S2[I] = '///---' then
        begin
           J := 0;
           inc(K);
           if Length(GeoidsMetaData) < K+1 then
              SetLength(GeoidsMetaData, K);
           continue;
        end;
        Inc(J);
        Case J of
          1: GeoidsMetaData [K].FileName := S2[I];
          2: GeoidsMetaData [K].NameID   := S2[I];
          3: GeoidsMetaData [K].Caption  := S2[I];
          4: GeoidsMetaData [K].B1 :=  StrToFloat2(S2[I]);
          5: GeoidsMetaData [K].B2 :=  StrToFloat2(S2[I]);
          6: GeoidsMetaData [K].L1 :=  StrToFloat2(S2[I]);
          7: GeoidsMetaData [K].L2 :=  StrToFloat2(S2[I]);
        else
          if GeoidsMetaData [K].Discription = '' then
           GeoidsMetaData [K].Discription := S2[I]
             else
               GeoidsMetaData [K].Discription := GeoidsMetaData [K].Discription
                                                + #13#10 + S2[I];
        end;

      until I >= S2.Count -1;
      SetLength(GeoidsMetaData, K+1);

      S.Free;
      S2.Free;
      S3.Free;
      exit;
    end;
  End;


  J := 0;

  For I := 0 To S.Count-1 Do
  Begin
    if Pos ('.gdf', S[I]) > 0 then
    begin
      S2.LoadFromFile(Dir + S[I]);

      GeoidsMetaData[J].FileName := S[I];
      GeoidsMetaData[j].Discription := '';

      K := 0;
      repeat
        Str := S2[K];

        if Str = '' then
        begin
            Str := EmptyS;
            continue;
        end;

        if Pos(NameIDS, AnsiLowerCase(Str)) > 0 then
            GeoidsMetaData[j].NameID := GetCols(Str,1,GetColCount(Str,' '),' ',false);

        if Pos(CaptionS, AnsiLowerCase(Str)) > 0 then
            GeoidsMetaData[j].Caption := GetCols(Str,1,GetColCount(Str,' '),' ',false);

        if K < 50 then                                                                
            GeoidsMetaData[j].Discription := GeoidsMetaData[j].Discription + Str + #13#10;

        if Pos(B1S, AnsiLowerCase(Str)) > 0 then
            GeoidsMetaData[j].B1 := StrToFloat2(GetCols(Str,1,1,' ',false));
        if Pos(B2S, AnsiLowerCase(Str)) > 0 then
            GeoidsMetaData[j].B2 := StrToFloat2(GetCols(Str,1,1,' ',false));
        if Pos(L1S, AnsiLowerCase(Str)) > 0 then
            GeoidsMetaData[j].L1 := StrToFloat2(GetCols(Str,1,1,' ',false));
        if Pos(L2S, AnsiLowerCase(Str)) > 0 then
            GeoidsMetaData[j].L2 := StrToFloat2(GetCols(Str,1,1,' ',false));

        inc(K);
      until (Pos(EndHeadS, Str) > 0) or (K >= S2.Count - 1);

      if GeoidsMetaData[j].L2 > 180 then
         GeoidsMetaData[j].L2 := GeoidsMetaData[j].L2 - 360;

      if GeoidsMetaData[j].L1 >= 180 then
         GeoidsMetaData[j].L1 := GeoidsMetaData[j].L1 - 360;

      if GeoidsMetaData[j].Caption = '' then
      Begin
         GeoidsMetaData[j].NameID  := GeoidsMetaData[j].FileName;
         GeoidsMetaData[j].Caption := GeoidsMetaData[j].NameID;
      End;
      
      inc(j);
    end;
  End;

  SetLength(GeoidsMetaData, J);
  SaveGeoidsMeta(Dir);
  S.Free;
  S2.Free;
  S3.Free;
end;

procedure SaveGeoidsMeta(Dir : String);
var I :Integer;
    S :TStringList;
begin
   S := TStringList.Create;

   For I := 0 To Length(GeoidsMetaData)-1 Do
   begin
     S.Add('///---');
     with GeoidsMetaData[I] do
     begin
       S.Add(FileName); S.Add(NameID); S.Add(Caption);
       S.Add(FloatToStr(B1)); S.Add(FloatToStr(B2));
       S.Add(FloatToStr(L1)); S.Add(FloatToStr(L2));
       S.Add(Discription);
     end;
   end;

   if Dir[Length(Dir)] <> '\' then
     Dir := Dir + '\';

   S.SaveToFile(Dir + 'Geoids.loc');
   S.Free;
end;

function FindGeoidMetaByCaption (Caption:String): Integer;
var I:Integer;
begin
  Result := -1;
  For I := 0 To Length(GeoidsMetaData)-1 Do
  If GeoidsMetaData[I].Caption = Caption then
  Begin
    Result := I;
    Break;
  End;
end;

function FindGeoidMeta (IDName:String): Integer;
var I:Integer;
begin
  Result := -1;
  For I := 0 To Length(GeoidsMetaData)-1 Do
  If GeoidsMetaData[I].NameID = IDName then
  Begin
    Result := I;
    Break;
  End;
end;

////////////////////////////////////////////////////////////////////////////////

function EmptyCell :TGridCell;
begin
  with Result Do
  begin
    A.Lat  := 0;  A.Long := 0;   A.DeltaH := 0;
    B.Lat  := 0;  B.Long := 0;   B.DeltaH := 0;
    C.Lat  := 0;  C.Long := 0;   C.DeltaH := 0;
    D.Lat  := 0;  D.Long := 0;   D.DeltaH := 0;
  end;
end;

function FindCell ( GeoidN: Integer; B, L :Double):TGridCell;
var I, J :Integer;

begin
   J := -1;

   Result := EmptyCell;

   For I := 1 To Length(GeoidList[GeoidN].Grid)-1 Do
   Begin

     if GeoidList[GeoidN].Grid[I].Lat <> GeoidList[GeoidN].Grid[I-1].Lat then
        continue;

     if J <>-1  then
        if (GeoidList[GeoidN].Grid[I].Long >=  L) and
           (GeoidList[GeoidN].Grid[I-1].Long < L) then
           {€чейка подошла по долготе повторно}
        if (GeoidList[GeoidN].Grid[I].Lat <  B) and
           (GeoidList[GeoidN].Grid[J].Lat >= B) then
        Begin
          {широта попала в диапазон (долгота нашлась ранее)}
          if I = J then
             exit;
             
          with Result Do
          begin
            A.Lat    := GeoidList[GeoidN].Grid[J-1].Lat;
            A.Long   := GeoidList[GeoidN].Grid[J-1].Long;
            A.DeltaH := GeoidList[GeoidN].Grid[J-1].DeltaH;

            B.Lat    := GeoidList[GeoidN].Grid[J].Lat;
            B.Long   := GeoidList[GeoidN].Grid[J].Long;
            B.DeltaH := GeoidList[GeoidN].Grid[J].DeltaH;

            C.Lat    := GeoidList[GeoidN].Grid[I-1].Lat;
            C.Long   := GeoidList[GeoidN].Grid[I-1].Long;
            C.DeltaH := GeoidList[GeoidN].Grid[I-1].DeltaH;

            D.Lat    := GeoidList[GeoidN].Grid[I].Lat;
            D.Long   := GeoidList[GeoidN].Grid[I].Long;
            D.DeltaH := GeoidList[GeoidN].Grid[I].DeltaH;
          end;

          break;
        End;

     if (GeoidList[GeoidN].Grid[I].Long >=  L) and
        (GeoidList[GeoidN].Grid[I-1].Long < L) then
     begin
       {€чейка подошла по долготе, осталось найти широту}
       J := I;
     end;

   End;
end;

function IsEmptyCell(FCell :TGridCell):Boolean;
begin
   Result := (FCell.A.Lat = FCell.C.Lat) or (FCell.A.Long = FCell.B.Long) ;
end;

function GetGeoidH( GeoidN : Integer; B, L :Double):Double;
var
    FCell  :TGridCell;
    kx, ky :Double;
begin
   Result := 0;

   FCell := FindCell(GeoidN, B, L);

   if IsEmptyCell(FCell) then
      exit;

   kx := GetKx(FCell.A.Long, FCell.B.Long, L);
   ky := GetKx(FCell.A.Lat,  FCell.C.Lat,  B);

   Result := Inter4(FCell.A.DeltaH,
                    FCell.B.DeltaH,
                    FCell.C.DeltaH,
                    FCell.D.DeltaH,
                    kx, ky);
end;

end.

unit GeoClasses;
//// Шевчук С. 2016

interface
type
  TEllipsoid = record
    FileName : String;
    Name :String;
    Caption :String;
    a :Double;        //// Большая полуось
    alpha :Double;    //// Сжатие эллипсоида
  end;

  TConvertData = record
    FileName : String; 
    InputDatumName : String;
    ConvertDatumName : String;
    // Пониженный приоритет
    BadData: boolean;

   // Линейные элементы трансформирования, м
    dx: Double;
    dy: Double;
    dz: Double;

    // Угловые элементы трансформирования, в секундах
    wx: Double;
    wy: Double;
    wz: Double ;

    // Дифференциальное различие масштабов
    ms : Double;
  end;

  TDatum = record
    FileName : String;
    Name :String;
    Caption:String;
    Ellipsoid :TEllipsoid;
    ConvertData: array of TConvertData;
    Projections: array of String;
    Hidden :boolean;
  end;

  TCoordinateSystem = record
    FileName : String;
    Name : String;
    Caption: String;
    Category: String;
    DatumN : Integer;
    ProjectionType : ShortInt;
    Parameters : array of Double;
  end;

  {TGeoid = record
    name :String;
  end;}

  function FindEllipsoid(FindName: string):integer;
  function FindEllipsoidByCaption(FindName: string):integer;
  function AddEllipsoid(Ellipsoid: TEllipsoid):integer;
  function CreateEllipsoid(Name, FileName, Caption : String; a, alpha : Double):integer;
  procedure DeleteEllipsoid(EN:Integer);

  function AddDatum(Datum: TDatum):integer;
  function FindDatum(FindName: string):integer;
  function FindDatumByCaption(FindName: string):integer;
  function CreateDatum(Name, FileName, Caption, EllipsoidName : String; Hidden:Boolean): integer;
  procedure RefreshDatums;
  procedure DeleteDatum(DN:Integer);

  function AddCoordinateSystem(CS:TCoordinateSystem):integer;
  procedure AddCoorinateSystemCategory(cat:String);
  function CreateCoordinateSystem(Name, FileName, Caption, DatumName, Projection, Category : String):integer;
  function AddCoordinateSystemParameter(Name: string; Parameter: Double): boolean;
  function FindCoordinateSystem(FindName: string):integer;
  function FindCoordinateSystemByCaption(FindName: string):integer;
  procedure RefreshCoordinateSystems;
  procedure RefreshCoorinateSystemCategory;
  procedure DeleteCoordinateSystem(CSN:Integer);

  function FindProjection(FindName: string):integer;
  function FindConvertData(Datum : TDatum; FindName: string):integer;

  procedure AddToConvList(Data:TConvertData);

  procedure AddConversionProperties(DatumNumber: integer; ConvertDatumName: String;
                                    dx, dy, dz, wx, wy, wz, ms : double);
  procedure DeleteConversionProperties(DatumNumber, PropN: integer);

  procedure AddProjection(DatumNumber: integer; ProjectionName: String);

  var EllipsoidList: array of TEllipsoid;
      DatumList: array of TDatum;
      TransformationList : array of TConvertData;
      CoordinateSystemList : array of TCoordinateSystem;
      CoorinateSystemCategories : array of String;
  const
       ProjectionNames : array [0..4] of String = ('LatLon', 'ECEF', 'Gauss', 'UTM', 'UTMS');
implementation

uses GeoFiles;

//////////////// ADDs        /////////////////////////////////////////////////////////////////////////

function AddEllipsoid(EllipSoid:TEllipsoid):integer;
var I: Integer;
begin
  I:= Length(EllipsoidList);
  SetLength(EllipsoidList, I+1);
  EllipsoidList[I] := Ellipsoid;
  AddEllipsoid := I;
end;

function AddDatum(Datum:TDatum):integer;
var I: Integer;
begin
  I:= Length(DatumList);
  SetLength(DatumList, I+1);
  DatumList[I] := Datum;
  AddDatum := I;
end;

function AddCoordinateSystem(CS:TCoordinateSystem):integer;
var I: Integer;
begin
  I:= Length(CoordinateSystemList);
  SetLength(CoordinateSystemList, I+1);
  CoordinateSystemList[I] := CS;
  AddCoordinateSystem := I;
end;

procedure AddConversionProperties(DatumNumber: integer; ConvertDatumName: String;
          dx, dy, dz, wx, wy, wz, ms : double);
var i: Integer;
    GeoSk:TDatum;
begin
  try
    GeoSk := DatumList[DatumNumber];
  except
    exit;
  end;

  i := FindConvertData(GeoSk, ConvertDatumName);
  if i=-1 then
  begin
    i := Length(GeoSk.ConvertData);
    SetLength(GeoSk.ConvertData, i+1);
  end;

  GeoSk.ConvertData[i].InputDatumName := GeoSk.Name;
  GeoSk.ConvertData[i].BadData := false;

  if ConvertDatumName[length(ConvertDatumName)]='*' then
  begin
     GeoSk.ConvertData[i].BadData := true;
     ConvertDatumName:= copy(ConvertDatumName,1,length(ConvertDatumName)-1)
  end;

  GeoSk.ConvertData[i].ConvertDatumName := ConvertDatumName;
  GeoSk.ConvertData[i].dx := dx;
  GeoSk.ConvertData[i].dy := dy;
  GeoSk.ConvertData[i].dz := dz;
  GeoSk.ConvertData[i].wx := wx;
  GeoSk.ConvertData[i].wy := wy;
  GeoSk.ConvertData[i].wz := wz;
  GeoSk.ConvertData[i].ms := ms;

  AddToConvList(GeoSk.ConvertData[i]);

  DatumList[DatumNumber]:= GeoSk;
end;

procedure AddProjection(DatumNumber: integer; ProjectionName: String);
var i: Integer;
    GeoSk:TDatum;
    AlreadyHas: Boolean;
begin
  try
    GeoSk := DatumList[DatumNumber];
  except
    exit;
  end;

  AlreadyHas := false;
  for i := 0 to Length(GeoSk.Projections)-1 do
    if GeoSk.Projections[i] = ProjectionName then
       AlreadyHas := true;

  if not AlreadyHas then
  begin
    i := Length(GeoSk.Projections);
    SetLength(GeoSk.Projections, i+1);
    GeoSk.Projections[i] := ProjectionName;
  end;

  DatumList[DatumNumber]:= GeoSk;
end;

procedure AddCoorinateSystemCategory(cat:String);
var i:integer;
    already: boolean;
begin
  already := false;
  for i := 0 to length(CoorinateSystemCategories)-1 do
    if CoorinateSystemCategories[i]= cat then
    begin
      already := true;
      break;
    end;

  if not Already then
  begin
    i := length(CoorinateSystemCategories);
    Setlength(CoorinateSystemCategories, i+1);
    CoorinateSystemCategories[i] := cat
  end;
end;

procedure RefreshCoorinateSystemCategory;
var i:integer;
begin
  SetLength(CoorinateSystemCategories,0);
  for i := 0 to length(CoordinateSystemList)-1 do
    AddCoorinateSystemCategory(CoordinateSystemList[i].Category);
end;

procedure AddToConvList(Data:TConvertData);
var i, j, j2 :integer;
begin

  /// Forward  number in list
  j := -1;
  for i := 0 to length(TransformationList)-1 do
    if TransformationList[i].InputDatumName = Data.InputDatumName then
      if TransformationList[i].ConvertDatumName = Data.ConvertDatumName then
      begin
          j:= i;
          break;
      end;

  /// Reverse  number in list
  j2 :=-1;
  for i := 0 to length(TransformationList)-1 do
    if TransformationList[i].InputDatumName = Data.ConvertDatumName then
      if TransformationList[i].ConvertDatumName = Data.InputDatumName then
      begin
          j2:= i;
          break;
      end;

  if j=-1 then
  begin
     j := length(TransformationList);
     Setlength(TransformationList, j+1);
  end;

  if j2=-1 then
  begin
     j2 := length(TransformationList);
     Setlength(TransformationList, j2+1);
  end;


  //// FWD
  TransformationList[j] := Data;

  /// REW
  TransformationList[j2] := Data;
  with TransformationList[j2] do
  begin
    InputDatumName := TransformationList[j].ConvertDatumName;
    ConvertDatumName := TransformationList[j].InputDatumName;

    dx := - dx;
    dy := - dy;
    dz := - dz;

    wx := - wx;
    wy := - wy;
    wz := - wz;

    ms := -ms;
  end;

end;


function AddCoordinateSystemParameter(Name: string; Parameter: Double): boolean;
var SCN, i : integer;
begin
   AddCoordinateSystemParameter := false;
   SCN := FindCoordinateSystem(Name);

   if SCN = -1 then
     exit
   else
     try
        i := length(CoordinateSystemList[SCN].Parameters);
        SetLength(CoordinateSystemList[SCN].Parameters, i+1);
        CoordinateSystemList[SCN].Parameters[i] := Parameter;

        AddCoordinateSystemParameter := true;
     except
       AddCoordinateSystemParameter := false;
     end;
end;

/////////////// CREATEs   /////////////////////////////////////////////////////////////////////////

function CreateEllipsoid(Name, FileName, Caption : String; a, alpha : Double):integer;
var I: Integer;
    NewEllipsoid:TEllipsoid;
begin
  I :=FindEllipsoid(name);
  if I=-1 then
  Begin
    NewEllipsoid.name := name;
    NewEllipsoid.Caption := Caption;
    NewEllipsoid.FileName := FileName;
    NewEllipsoid.a:= a;
    NewEllipsoid.alpha:= alpha;
    CreateEllipsoid := AddEllipsoid(NewEllipsoid);
  End
    Else
    Begin
      EllipsoidList[I].Caption := Caption;
      EllipsoidList[I].FileName := FileName;
      EllipsoidList[I].a:= a;
      EllipsoidList[I].alpha:= alpha;
      CreateEllipsoid := I;
    End;
end;

function CreateDatum(Name, FileName, Caption, EllipsoidName : String; Hidden:Boolean):integer;
var I, j: Integer;
    NewDatum : TDatum;
begin
  CreateDatum := -1;

  j := FindEllipsoid(EllipsoidName);
  if j=-1 then exit;

  NewDatum.Name := Name;
  NewDatum.Caption := Caption;
  NewDatum.FileName:= FileName;
  NewDatum.ellipsoid := EllipsoidList[j];
  NewDatum.Hidden := Hidden;
  SetLength(NewDatum.ConvertData, 0);
  SetLength(NewDatum.Projections, 0);

  I :=FindDatum(NewDatum.Name);
  if i=-1 then
    i:= AddDatum(NewDatum)
  else
    DatumList[i]:=NewDatum;

  CreateDatum := I;
end;

function CreateCoordinateSystem(Name, FileName, Caption, DatumName, Projection, Category : String):integer;
var   i, j, p  : integer;
      NewCS : TCoordinateSystem;
begin
  CreateCoordinateSystem := -1;

  j := FindDatum(DatumName);
  p := FindProjection(Projection);

  if not((j=-1)or(p=-1)) then
  Begin

    NewCS.Name := Name;
    NewCS.FileName := FileName;
    NewCS.Caption := Caption;
    NewCS.DatumN := j;
    NewCS.ProjectionType := p;
    SetLength(NewCs.Parameters,0);
    NewCS.Category := Category;

    AddCoorinateSystemCategory(Category);

    I :=FindCoordinateSystem(NewCS.name);
    if i=-1 then
      i:= AddCoordinateSystem(NewCS)
      else
        CoordinateSystemList[i]:=NewCS;

    CreateCoordinateSystem := I;
  end;  
end;

//////////////// FINDs  /////////////////////////////////////////////////////////////////////////

function FindConvertData(Datum : TDatum; FindName: string):integer;
var I :integer;
begin
  FindConvertData := -1;
  for I:= 0 to Length(Datum.ConvertData)-1 do
    if (Datum.ConvertData[i].ConvertDatumName = FindName) or
        (Datum.ConvertData[i].BadData)and(Datum.ConvertData[i].ConvertDatumName+'*' = FindName) then
      begin
         FindConvertData := i;
         break;
      end;
end;

function FindDatum(FindName: string):integer;
var I :integer;
begin
  FindDatum:= -1;
  for I:= 0 to Length(DatumList)-1 do
    if DatumList[i].name = FindName then
      begin
         FindDatum:= i;
         break;
      end;
end;

function FindDatumByCaption(FindName: string):integer;
var I :integer;
begin
  FindDatumByCaption:= -1;
  for I:= 0 to Length(DatumList)-1 do
    if DatumList[i].Caption = FindName then
      begin
         FindDatumByCaption:= i;
         break;
      end;
end;

function FindEllipsoid(FindName: string):integer;
var I :integer;
begin
  FindEllipsoid:= -1;

  for I:= 0 to Length(EllipsoidList)-1 do
    if EllipsoidList[i].Name = FindName then
      begin
         FindEllipsoid:= i;
         break;
      end;
end;

function FindEllipsoidByCaption(FindName: string):integer;
var I :integer;
begin
  FindEllipsoidByCaption:= -1;

  for I:= 0 to Length(EllipsoidList)-1 do
    if EllipsoidList[i].Caption = FindName then
      begin
         FindEllipsoidByCaption:= i;
         break;
      end;
end;

function FindCoordinateSystem(FindName: string):integer;
var I:integer;
begin
  FindCoordinateSystem:= -1;
  for I:= 0 to Length(CoordinateSystemList)-1 do
    if CoordinateSystemList[i].Name = FindName then
      begin
         FindCoordinateSystem:= i;
         break;
      end;
end;

function FindCoordinateSystemByCaption(FindName: string):integer;
var I:integer;
begin
  FindCoordinateSystemByCaption:= -1;
  for I:= 0 to Length(CoordinateSystemList)-1 do
    if CoordinateSystemList[i].Caption = FindName then
      begin
         FindCoordinateSystemByCaption:= i;
         break;
      end;
end;

function FindProjection(FindName: string):integer;
var I:integer;
begin
  FindProjection:= -1;
  for I:= 0 to Length(ProjectionNames)-1 do
    if ProjectionNames[i] = FindName then
      begin
         FindProjection:= i;
         break;
      end;
end;

/////////////////// Refresh   ///////////////////////////////////////////////////////

procedure RefreshDatums;
var i :integer;
    Dfile: Array of String;

begin

 SetLength(TransformationList,0);
 SetLength(DFile,Length(DatumList));
 for i := 0 To Length(DatumList)-1 do
   DFile[i]:= DatumList[i].FileName;

 SetLength(DatumList,0);
 for i:= 0 To  Length(DFile)-1 do
 begin
   LoadDatumFromFile(DFile[i]);
 end;

 RefreshCoordinateSystems;
end;

procedure RefreshCoordinateSystems;
var i : integer;
    CSFile: Array of String;
begin

 SetLength(CSFile,Length(CoordinateSystemList));
 for i := 0 To Length(CoordinateSystemList)-1 do
   CSFile[i]:= CoordinateSystemList[i].FileName;

 SetLength(CoordinateSystemList,0);
 for i:= 0 to Length(CSFile)-1 do
 begin
   LoadCoordinateSystemFromFile(CSFile[i]);
 end;

 RefreshCoorinateSystemCategory;
end;

/////////////////// DELs    //////////////////////////////////////////////////////////

procedure DeleteEllipsoid(EN:Integer);
var i : integer;
begin

 for i:= EN To Length(EllipsoidList)-2  do
 begin
   EllipsoidList[i]:= EllipsoidList[i+1];
 end;
 SetLength(EllipsoidList, Length(EllipsoidList)-1);

 RefreshDatums;
end;

procedure DeleteDatum(DN:Integer);
var i : integer;
begin

 for i:= DN To Length(DatumList)-2  do
 begin
   DatumList[i]:= DatumList[i+1];
 end;
 SetLength(DatumList, Length(DatumList)-1);

 RefreshCoordinateSystems;
end;

procedure DeleteConversionProperties(DatumNumber, PropN: integer);
var i: integer;
begin

 for i:= PropN To Length(DatumList[DatumNumber].ConvertData)-2  do
 begin
   DatumList[DatumNumber].ConvertData[i]:= DatumList[DatumNumber].ConvertData[i+1];
 end;
 SetLength(DatumList[DatumNumber].ConvertData, Length(DatumList[DatumNumber].ConvertData)-1);

end;

procedure DeleteCoordinateSystem(CSN:Integer);
var i : integer;
begin

 for i:= CSN To Length(CoordinateSystemList)-2  do
 begin
   CoordinateSystemList[i]:= CoordinateSystemList[i+1];
 end;
 SetLength(CoordinateSystemList, Length(CoordinateSystemList)-1)

end;

end.
 
unit GeoTime;

interface

uses DateUtils, SysUtils, Classes, TabFunctions;

function GetLeapSecond(FileName:String; Date:TDateTime):integer;

function TimeFromDoy(Y : Integer; T: Double): TDateTime;

function TimeFromWeekSec(T: Double): TDateTime;

function GPSToUTC(T: TDateTime): TDateTime;

function UTCToGPS(T: TDateTime): TDateTime;

///// From DiffCAlc2

function DatetimeToTOW(T:TDateTime; var WeekN:integer):Double;   overload;
function DatetimeToTOW(T:TDateTime; PrecSec:Double; var WeekN:integer):Double;   overload;
function TOWToDateTime(TOW:Double; WeekN:integer):TDateTime;

function DatetimeToTOD(T:TDateTime):Double;   overload;
function TODToDateTime(TOD:Double; MDate:TDateTime):TDateTime;

function GPSTToUTC(T:TDateTime; Ls: integer):Double;

////////------------

const Leaps: array [0..17] of TDateTime = ( 29767.9999999884, 30132.9999999884,
                                          30497.9999999884, 31228.9999999884,
                                          32142.9999999884, 32873.9999999884,
                                          33238.9999999884, 33785.9999999884,
                                          34150.9999999884, 34515.9999999884,
                                          35064.9999999884, 35611.9999999884,
                                          35976.9999999884, 38533.9999999884,
                                          39629.9999999884, 41090.9999999884,
                                          42185.9999999884, 42551.9999999884);

var DateArray: array of TDateTime;

implementation

function GetLeapSecond(FileName:String; Date:TDateTime):integer;

  procedure GetLeapDatesFromFile;
  const TimeFText = 'hh:mm:ss.zzz';
        DateFText = 'YYYY-MM-DD';
  var I: integer;
      T:TDateTime;
      FormatSettings: TFormatSettings;
      S: TStringList;
  begin
     S := TStringList.Create;
     FormatSettings.ShortDateFormat := DateFText + ' ' + TimeFText;
     FormatSettings.LongTimeFormat  := FormatSettings.ShortDateFormat;

     FormatSettings.DateSeparator := GetSep(DateFText)[1];
     FormatSettings.TimeSeparator := GetSep(TimeFText)[1];

     if Pos(',',TimeFText) > 1 then
      FormatSettings.DecimalSeparator := ','
         else
           FormatSettings.DecimalSeparator := '.';

     try
       SetLength(DateArray,0);

       S.LoadFromFile(FileName);

       for I := 0 To  S.Count - 1 Do
       begin
          T := StrToDateTime(S[I], FormatSettings);
          SetLength(DateArray,Length(DateArray)+1);
          DateArray[Length(DateArray)-1] := T;
       end;

     except
       SetLength(DateArray,Length(leaps));
       for I := 0 to Length(leaps) - 1 do
          DateArray[I] := Leaps[I];
     end;
     S.Free;
  end;


var I:Integer;
begin
   if Length(DateArray) < 1 then
   Begin
      if Fileexists(FileName) then
          GetLeapDatesFromFile
       else
       begin
         SetLength(DateArray,Length(leaps));
         for I := 0 to Length(leaps) - 1 do
            DateArray[I] := Leaps[I];
       end;
   End;

   Result := 0;

   for I := 0 to Length(DateArray) - 1 do
      if Date > DateArray[I] then
         Result := I+1
           else
             break;
end;

function TimeFromDoy(Y : Integer; T: Double): TDateTime;
begin
 if Y < 70 then
    Y := Y + 2000
      else
        if Y < 1900 then
           Y := Y + 1900;

  Result := EncodeDate(Y,1,1) + T -1;
end;

function TimeFromWeekSec(T: Double): TDateTime;
begin
  Result := EncodeDate(1980,1,6) + Trunc(T)*7 + (T- Trunc(T))*1000000/86400; ///(3600*24);
end;

function GPSToUTC(T: TDateTime): TDateTime;
var ls: integer;
begin
   ls := GetLeapSecond('Data\leap.txt', T);
   Result := T - Ls/86400;
end;

function UTCToGPS(T: TDateTime): TDateTime;
var ls: integer;
begin
   ls := GetLeapSecond('Data\leap.txt', T);
   Result := T + Ls/86400;
end;

///////////////////-------------------------

function DatetimeToTOW(T:TDateTime; var WeekN:integer):Double;   overload;
var T0 :TDateTime;
    dT :Double;
const
   roundT = 1e+06;
begin
  T0 := EncodeDateTime(1980, 1, 6, 0, 0, 0, 0);
  dt := T - T0;
  WeekN := trunc(dT / 7);
  Result := (dT - WeekN*7)*86400;

  //// Убираю погрешность формата TDateTime

  Result := Round(Result * RoundT)/RoundT
end;

function DatetimeToTOW(T:TDateTime; PrecSec:Double; var WeekN:integer):Double;   overload;
var T0, T1 :TDateTime;
    Y, M, D, h, mi, s, ms : Word;
    dT :Double;
begin
  T0 := EncodeDateTime(1980, 1, 6, 0, 0, 0, 0);
  DecodeDateTime(T, Y, M, D, h, mi, s, ms);

  s  := 0;
  ms := 0;

  T1 := EncodeDateTime(Y, M, D, h, mi, s, ms);

  dt := T1 - T0;

  WeekN := trunc(dT / 7);

  Result := (dT - WeekN * 7) * 86400 + PrecSec;
end;

function TOWToDateTime(TOW:Double; WeekN:integer):TDateTime;
begin
  Result := EncodeDateTime(1980, 1, 6, 0, 0, 0, 0) + WeekN * 7 + TOW / 86400;
end;

function DatetimeToTOD(T:TDateTime):Double;   overload;
var h, m, s, z :word;
const
   roundT = 1e+06;
begin
  DecodeTime(T, h, m, s, z);
  Result := h*3600 + m*60 + s + z/1000;

  //// Убираю погрешность формата TDateTime

  Result := Round(Result * RoundT)/RoundT
end;

function TODToDateTime(TOD:Double; MDate:TDateTime):TDateTime;
var Y, M, D :word;
begin
  DecodeDate(MDate,Y,M,D);
  Result := EncodeDateTime(Y, M, D, 0, 0, 0, 0) + TOD/86400;
end;

function GPSTToUTC(T:TDateTime; Ls: integer):Double;
begin
  result := T - Ls/86400;
end;

end.

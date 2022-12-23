unit MapFunctions;

interface

uses Windows, GeoFunctions, TabFunctions, Math;

type

  TLatLong = record
      lat, long :Double
  end;

  TPosAndDist = record
      Pos, Dist, DistTo0, x, y :Double;
  end;

  TMyPoint = record
      x, y :Double;
  end;

  TIntercection = record
      x, y :Double;
      c1, c2 :Double;
      isExist, isOnBoth : boolean;
  end;

  TMy3DPoint = record
      x, y, z :Double;
  end;

  function GetLinesIntercection(x1b, y1b, x1e, y1e, x2b, y2b, x2e, y2e: Double) :TIntercection;
  function GetPosAndDist(xb, yb, xe, ye, x, y: double): TPosAndDist;
  function GetNormalPt(xb, yb, xe,ye, x, y: double; isRight: boolean;
                                Dist: double): TMyPoint;

  function BoxInBox(Rx, Ry: array of double; x1, y1, x2, y2: Double): boolean;
  function PointInBox(Rx, Ry: array of double; x, y: Double): boolean;
  function MapPointInBox(Rx, Ry: array of double; x, y: Double): boolean;
  function IsPIn_Vector(aAx, aAy, aBx, aBy, aCx, aCy, aPx, aPy: single): boolean;



  procedure SKToWGS(x, y, h: Double; var B, L: Double);
  procedure WGSToSK(B, L, H: Double; var x, y: Double; Zone: Integer;
            autozone: boolean);

  procedure AxcelScale(TimerDelta: Double);
  procedure ShiftMap(Key: Byte);

  function MapToScreen(x, y, x0, y0, FalseY0, Scale, fi : Double):TMyPoint; overload;
  function MapToScreen(x,y: Double): TMyPoint;  overload;
  function MapToScreenRound(x, y: Double): TPoint;

  function ScreenToMap(x, y, x0, y0, FalseY0, Scale, fi : Double):TMyPoint; overload;
  function ScreenToMap(x, y: Double):TMyPoint;  overload;

  function MapToBL(P:TMyPoint; isUTM, isSouth:Boolean):TLatLong;  overload;
  function MapToBL(x, y: Double):TLatLong; overload;

  function BLToMap(B, L : Double; isUTM, isSouth:Boolean; Zone: integer):TMyPoint; overload;
  function BLToMap(B, L : Double):TMyPoint; overload;
  function BLToMap(L : TLatLong):TMyPoint; overload;

  function BLToScreen(B,L:Double): TMyPoint;
  function ScreenToBL(x,y :Double) :TLatLong;

  const

  MaxMashtab = 16;
  TMashtab : Array [0.. MaxMashtab-1 ] of Integer =
                    (1, 2, 5,
                     10, 20, 50,
                     100, 200, 500,
                     1000, 2000, 5000,
                     10000, 20000, 50000, 100000);
  var

  /// Screen
  DispSize :TPoint;

   /// Map
  Center    :TMyPoint;               ShiftCenter :TMyPoint;  /// 02.11.2017
  Scale     :Double =1;
  _Scale    :Double =1;
  Fi        :Double = 0;    /// MapRotation
  _Fi        :Double = 0;
  Mashtab   :Integer = 10;
  VshiftY   :Integer = 0;
  ClickMode :integer = 1;
  MKeyShift :TMyPoint;
  MShift, CanvCursor :TPoint;
  CanvCursorBL       :TLatLong;

  /// Projection
  UTM          :Boolean = true;
  South        :Boolean = false;
  MyZone       :Integer = 14;
  WaitForZone  :Boolean = true;
  WaitForCenter:Boolean = true;
  WGS, SK      :Integer;

implementation

/// Geo

{procedure CheckMyZone(x, y:Double, UTM: Boolean);
const ZoneW = 6;

  function GetMyZoneCenter:integer;
  var Linit:integer;
      Lo   :integer;
  begin
     if UTM then
        Linit := 30
         else
           Linit := 0;
     Result := Zone*ZoneW-ZoneW/2+Linit;
  end;

  function GetMinX:integer;
  begin

  end;

  function GetMaxX:integer;
  begin

  end;

begin
 if X>MaxX then
 Begin
   inc(MyZone);
   RecomputeBasicObjects(False);
 End;

 
end; }


/// Math

function IsPIn_Vector(aAx, aAy, aBx, aBy, aCx, aCy, aPx, aPy: single): boolean;
var
  Bx, By, Cx, Cy, Px, Py : single;
  m, l : single; // мю и лямбда
begin
  Result := False;
  // переносим треугольник точкой А в (0;0).
  Bx := aBx - aAx; By := aBy - aAy;
  Cx := aCx - aAx; Cy := aCy - aAy;
  Px := aPx - aAx; Py := aPy - aAy;
  //
  m := (Px*By - Bx*Py) / (Cx*By - Bx*Cy);
  if (m >= 0) and (m <= 1) then
  begin
    l := (Px - m*Cx) / Bx;
    if (l >= 0) and ((m + l) <= 1) then
      Result := True;
  end;
end;

//// Geo

procedure SKToWGS(x, y, h: Double; var B, L: Double);
var B2, L2, H2, h1 : Double;
begin
  GaussKrugerToGeo_Kras(x, y, B2, L2, 0, MyZone*6-3, 0, MyZone*1000000 + 500000, 1);
  Geo1ToGeo2(B2, L2, 0, SK, WGS, B, L, H1);
end;

procedure WGSToSK(B, L, H: Double; var x, y: Double; Zone: Integer;
  autozone: boolean);
var Bsk, Lsk, Hsk : Double;
begin

  Geo1ToGeo2(B, L, H, WGS, SK, Bsk, Lsk, Hsk);
  GeoToGaussKruger_Kras(Bsk, Lsk, y, x, Zone, AutoZone);

  if AutoZone then
  begin
     MyZone := Zone;
  end;
end;

////// Scales

procedure AxcelScale(TimerDelta: Double);
const k = 1.5;
var Stp, ShiftStp : double;
begin
////
  _Scale  := TMashtab[Mashtab]/100;

  Stp := TimerDelta;

  if Stp > 5 then
     Stp := 5;
  if Stp < 0.25 then
     Stp := 0.25;

     Stp := 5*k/Stp;

  if Abs((Scale - _Scale)) > _Scale/100 then  //// 02.11.2017
  Begin
     Scale := Scale - (Scale - _Scale)/Stp;
     Center.x := Center.x + (ShiftCenter.x - Center.x)/Stp;
     Center.y := Center.y + (ShiftCenter.y - Center.y)/Stp;
  End
     else
     Begin
        Scale := _Scale;
        ShiftCenter := Center;
     End;

 if abs(Fi - _Fi) > 1/Stp  then
 Begin
  Fi := Fi + (_Fi - Fi)/Stp;
 End
  else
    Fi := _Fi;

 if _Fi > 2*pi then
 begin
   _Fi := _Fi - 2*PI;
   Fi  :=  Fi - 2*PI;
 end
   else
   if _Fi < 0 then
   begin
     _Fi := _Fi + 2*PI;
      Fi :=  Fi + 2*PI;
   end;

 if abs(MKeyShift.X{*Scale}) > 1  then      //// Scale {commented} at 19/06/2018
 Begin
  ShiftStp := MKeyShift.X/Stp;
  MKeyShift.X := MKeyShift.X - ShiftStp;
  Center.x := Center.x - MKeyShift.X*Scale;
 End;

 if abs(MKeyshift.Y{*Scale}) > 1  then
 Begin
  ShiftStp := MKeyShift.Y/Stp;
  MKeyShift.Y := MKeyShift.Y - ShiftStp;
  Center.y := Center.y + MKeyShift.Y*Scale;
 End;

end;

procedure ShiftMap(Key: Byte);
var dx, dy : double;
    SCenter, CurCenter : TMyPoint;
begin

  case Key of
   0: if Mashtab < MaxMashtab-1 then           //// 02.11.2017
      Begin
          CurCenter := ScreenToMap(CanvCursor.x, CanvCursor.y);
          SCenter := MapToScreen(Center.x, Center.y);

          dx := (CanvCursor.X - SCenter.x) *Cos(Fi)
               +(CanvCursor.Y - SCenter.Y) *Sin(Fi);


          dy := -(CanvCursor.X - SCenter.x) *Sin(Fi)
                +(CanvCursor.Y - SCenter.Y) *Cos(Fi);

          Inc(Mashtab);

          ShiftCenter.x := CurCenter.X - dx*TMashtab[Mashtab]/100;
          ShiftCenter.y := CurCenter.Y + dy*TMashtab[Mashtab]/100;
      End;
   1: if Mashtab > 0 then                        //// 02.11.2017
      Begin
          CurCenter := ScreenToMap(CanvCursor.x, CanvCursor.y);
          SCenter := MapToScreen(Center.x, Center.y);
          {dx := CanvCursor.X - SCenter.x;
          dy := CanvCursor.Y - SCenter.Y; }

          dx := (CanvCursor.X - SCenter.x) *Cos(Fi)
               +(CanvCursor.Y - SCenter.Y) *Sin(Fi);


          dy := -(CanvCursor.X - SCenter.x) *Sin(Fi)
                +(CanvCursor.Y - SCenter.Y) *Cos(Fi);

          Dec(Mashtab);

          ShiftCenter.x := CurCenter.X - dx*TMashtab[Mashtab]/100;
          ShiftCenter.y := CurCenter.Y + dy*TMashtab[Mashtab]/100;
      End;

   2:  mKeyShift.Y := DispSize.y *0.05;
   3:  mKeyShift.Y := -DispSize.y *0.05;
   4:  mKeyShift.X := DispSize.y*0.05;
   5:  mKeyShift.X := -DispSize.y*0.05;

 end;
end;


function GetLinesIntercection(x1b, y1b, x1e, y1e, x2b, y2b, x2e, y2e: double) :TIntercection;
var k1, k2, b1, b2, xi, yi : Double;
    vert1, vert2 : boolean;
begin
  Result.isexist := false;

  if (x1b = x1e) and (y1b = y1e) then    /// NOT A LINE (1)
    exit;

  if (x2b = x2e) and (y2b = y2e) then    /// NOT A LINE (2)
    exit;

  vert1 := false;
  vert2 := false;

  try
                             //// y = kx + b
     if x1b = x1e then
       vert1 := true
       else
       begin
         k1 := (y1e - y1b)/(x1e - x1b);
         b1 := - k1*x1b + y1b;
       end;

     if x2b = x2e then
       vert2 := true
       else
       begin
         k2 := (y2e - y2b)/(x2e - x2b);
         b2 := - k2*x2b + y2b;
       end;

     if (vert1 and vert2) or ( ((vert1= false) and (vert2 = false)) and (k1 = k2) ) then /// parallel lines
       exit;

     if vert1 then
     begin
       Result.y := k2*x1b + b1;
       Result.x := (Result.y - b2)/k2;

       Result.c1 := (Result.y - y1b)/(y1e - y1b);
       Result.c2 := (Result.x - x2b)/(x2e - x2b);
     end
       else
       if vert2 then
       begin
         Result.y := k1*x2b + b2;
         Result.x := (Result.y - b1)/k1;

         Result.c1 := (Result.x - x1b)/(x1e - x1b);
         Result.c2 := (Result.y - y2b)/(y2e - y2b);
       end
         else
         begin
            Result.x := (b2 - b1)/(k1 - k2);  /// line1 - line 2 = 0
            Result.y := k1*Result.x + b1;      /// on line 1

            Result.c1 := (Result.x - x1b)/(x1e - x1b);
            Result.c2 := (Result.x - x2b)/(x2e - x2b);
         end;

      Result.isExist := true;

  except
     Result.isExist := false;
  end;
 
end;

function GetPosAndDist(xb, yb, xe, ye, x, y: double): TPosAndDist;
var x1, y1, x2, y2, _x, _y, t, c, _y0: Double;
begin
  Result.Dist := 0;
  Result.Pos := -1;
  try
     x1 := xb;
     x2 := xe;
     y1 := yb;
     y2 := ye;

     if (x1 = x2) and (y1 = y2) then
     begin
        Result.Dist := SQRT(SQR(x-x1)+SQR(y-y1));
        exit;
     end;  


     if x1 = x2 then
     begin
       _y := y;
       _x := x1;
        c := (_y - y1) / (y2 - y1);
     end
        else
     if y1 = y2 then
     begin
       _y := y1;
       _x := x;
        c := (_x - x1) / (x2 - x1);
     end
        else
     if abs(x2-x1)> abs(y2-y1) then
     Begin
       t :=  (y2-y1)/(x2-x1);
       c := 1/t;

       _y0 := c*(x-x1) + (y-y1);

       _x := x1 + (  _y0/(t+c) );
       _y := y1 + ( t*(_x-x1) );

        c := (_x - x1) / (x2 - x1);
     End
        else
          Begin
            t := (x2-x1)/(y2-y1);
            c := 1/t;

            _y0 := (x-x1) + c*(y-y1);

            _y := y1 + (  _y0/(t+c) );
            _x := x1 + ( t*(_y-y1) );

            c := (_y - y1) / (y2 - y1);
          End;

     Result.x := _x;
     Result.y := _y;
     Result.Pos  := c;
     Result.Dist := SQRT(SQR(x-_x)+SQR(y-_y));
     Result.DistTo0 := c*SQRT(SQR(x2-x1)+SQR(y2-y1));
  except
    Result.Dist := 0;
  end;

end;

function GetNormalPt(xb, yb, xe,ye, x, y: double; isRight: boolean;
                                Dist: double): TMyPoint;
var
  a : double;
  PD :TPosandDist;
begin

   try
    PD := GetPosAndDist(xb, yb, xe, ye, x, y);
    a := arctan2(xe-xb,ye-yb);

    if isRight then
      a := a + pi/2
      else
        a:= a - pi/2;

     Result.x := PD.x + sin(a)*Dist;
     Result.y := PD.y + cos(a)*Dist;

   except
   end;

end;

function BoxInBox(Rx, Ry: array of double; x1, y1, x2, y2: Double): boolean;
var Xmin, Ymin, Xmax, Ymax, i: Double;
    j: integer;
begin

       xmin := Rx[0];
       ymin := Ry[0];
       xmax := Rx[0];
       ymax := Ry[0];

       for j := 1 to 3 do
       begin
         if Rx[j] < xmin then
           xmin := Rx[j];
         if Ry[j] < ymin then
           ymin := Ry[j];

         if Rx[j] > xmax then
           xmax := Rx[j];
         if Ry[j] > ymax then
           ymax := Ry[j];
       end;

       if x1 > x2  then
       begin
         i := x2;
         x2 := x1;
         x1 := i;
       end;

       if y1 > y2  then
       begin
         i  := y2;
         y2 := y1;
         y1 := i;
       end;

   result := ((xmin < x2) and (xmax > x1) and (ymin < y2) and (ymax > y1)) or
             ((xmin > x1) and (xmax < x2) and (ymin > y1) and (ymin < y2));


  //
 //  result := (xmin > x1) and (xmax < x2) and (ymin > y1) and (ymax < y2) ;
end;

function PointInBox(Rx, Ry: array of double; x, y: Double): boolean;
var Xmin, Ymin, Xmax, Ymax: Double;
    j: integer;
begin
     {
       xmin := Rx[1];
       ymin := Ry[1];
       xmax := Rx[1];
       ymax := Ry[1];

       for j := 1 to 3 do
       begin
         if Rx[j] < xmin then
           xmin := Rx[j];
         if Ry[j] < ymin then
           ymin := Ry[j];

         if Rx[j] > xmax then
           xmax := Rx[j];
         if Ry[j] > ymax then
           ymax := Ry[j];

       end;

      for j := 0 to 3 do
       Begin
          Rx[j] := Rx[j] - xmin;
          Ry[j] := Ry[j] - ymin;
       End;
       x := x - xmin;
       y := y - ymin;  

     result := false;
     if (x > xmin) and (x < xmax) then
     if (y > ymin) and (y < ymax) then }

      result :=  IsPIn_Vector(Rx[0], Ry[0], Rx[1], Ry[1], Rx[2], Ry[2],  x, y)
              or IsPIn_Vector(Rx[2], Ry[2], Rx[1], Ry[1], Rx[3], Ry[3],  x, y);
end;

function MapPointInBox(Rx, Ry: array of double; x, y: Double): boolean;
var Xmin, Ymin, Xmax, Ymax: Double;
    j: integer;
begin
      result :=  IsPIn_Vector(Rx[0], Ry[0], Rx[2], Ry[2], Rx[1], Ry[1],  x, y)
              or IsPIn_Vector(Rx[0], Ry[0], Rx[3], Ry[3], Rx[2], Ry[2],  x, y);
end;


////// Screen x,y to X,Y to B,L

function BLToMap(B, L : Double; isUTM, isSouth:Boolean; Zone: integer):TMyPoint; overload;
begin
   try
     if isUTM then
        GeoToUTM(WGS, B, L, isSouth, Result.y, Result.x, Zone, False)
         else
           WGSToSK(B, L, 0, Result.y, Result.x, Zone, false);
   except
     Result.x := 0;
     Result.y := 0;
   end;
end;

function BLToMap(B, L : Double):TMyPoint; overload;
begin
   try
     if UTM then
        GeoToUTM(WGS, B, L, South, Result.y, Result.x, MyZone, False)
         else
           WGSToSK(B, L, 0, Result.y, Result.x, MyZone, false);
   except
     Result.x := 0;
     Result.y := 0;
   end;
end;

function BLToMap(L : TLatLong):TMyPoint; overload;
begin
     Result :=  BLToMap(L.lat, L.long);
end;

function MapToBL(P: TMyPoint; isUTM, isSouth:Boolean):TLatLong;
begin
   try
     if isUTM then
        UTMToGeo(WGS, P.y, P.x, isSouth, Result.lat, Result.long, 0,
                 (MyZone-30)*6-3, 0, MyZone*1000000+500000, 0.9996)
         else
           SKToWGS(P.y, P.x, 0, Result.lat, Result.long);
   except
     Result.Lat := 0;
     Result.Long := 0;
   end;
end;

function ScreenToMap(x, y, x0, y0, FalseY0, Scale, fi : Double):TMyPoint;
var x2, xm, ym : double;
begin
   try
       xm :=  x - DispSize.X/2;
       ym := -y + DispSize.Y/2 + FalseY0;
       x2 := xm;

       xm := xm * Cos(fi) - ym * sin(fi);
       ym := ym * Cos(fi) + x2 * sin(fi);

       xm := xm * Scale + X0;
       ym := ym * Scale + Y0;

       Result.x := xm;
       Result.Y := ym;
   except
     Result.X := 0;
     Result.Y := 0;
   end;
end;

function ScreenToMap(x, y: Double):TMyPoint;  overload;
begin
  Result := ScreenToMap(X, Y, Center.X, Center.Y, VShiftY, Scale, fi);
end;

function MapToBL(x, y: Double):TLatLong;
var P: TMyPoint;
begin
   try
      P.x := x; P.y := y;
      Result := MapToBL(P, UTM, South);
   except
     Result.Lat := 0;
     Result.Long := 0;
   end;
end;

////////////// X,Y to Screen

function MapToScreen(x, y, x0, y0, FalseY0, Scale, fi : Double):TMyPoint;
var dx, dy, dx2, dy2 : double;
begin
   try
     dx := (x0 - x)/ Scale ;
     dy := (y0 - y)/ Scale ;

     dx2 := dx * Cos (Fi) + dy * Sin(Fi);
     dy2 :=-dx * Sin (Fi) + dy * Cos(Fi);

     Result.x := (DispSize.X div 2 - dx2);
     Result.y := DispSize.y -  (DispSize.y div 2 - dy2) + FalseY0;
   except
     Result.X := 0;
     Result.Y := 0;
   end;
end;

function MapToScreen(x,y: Double): TMyPoint;
begin
  Result := MapToScreen(x, y, Center.X, Center.Y, VShiftY, Scale, fi);
end;

function MapToScreenRound(x, y: Double): TPoint;
var Point : TMyPoint;
begin
  Point := MapToScreen(x, y);
  Result.X := round(Point.X);
  Result.Y := round(Point.Y);
end;

function BLToScreen(B,L:Double): TMyPoint;
var P : TMyPoint;
begin
  P := BLToMap(B,L);

  Result := MapToScreen(P.x,P.y);
end;

function ScreenToBL(x,y :Double) :TLatLong;
var  P  :TMyPoint;
begin
 P := ScreenToMap(x,y);
 Result := MaptoBL(P.x,P.y);

end;
//////////////////////////

end.

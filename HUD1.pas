unit HUD1;

interface

uses MapFunctions, GeoFunctions, TabFunctions, Vectors2, Classes, DrawFunctions,
     AbstractCanvas, AbstractDevices, AsphyreImages, AsphyreTypes, AsphyreFonts,
     RTypes, SysUtils;

procedure ScaleLine(AsphCanvas:TAsphyreCanvas; BigSize, isRight: Boolean;
      Msign, KmSign:String; FontN:Integer; IntColor: Cardinal);

implementation

procedure ScaleLine(AsphCanvas:TAsphyreCanvas; BigSize, isRight: Boolean;
      Msign, KmSign:String; FontN:Integer; IntColor: Cardinal);
var
    s :String;
    w :integer;
    X1, X2, Y2, FL :integer;
begin
    if Scale=0 then
         exit;

    w := trunc(TMashtab[Mashtab]/Scale);

    if isRight then
    Begin
      X1 := DispSize.X-20 - w;
      X2 := DispSize.X;
    End
      else
      Begin
        X1 := 0;
        X2 := w + 20;
      End;

    if BigSize then
    Begin
      Y2 := 20;
      Fl := 1;
    End
        else
        Begin
          Y2 := 10;
          FL := 0;
        End;


    AsphCanvas.FillRect(RECT( X1, DispSize.Y - trunc(Y2*1.5) -15, X2, DispSize.Y), IntColor);

    FatLine(AsphCanvas, X1 + 10, DispSize.Y - Y2/2 - 5, X1 + 10, DispSize.Y - 5, FL,
           false, false, $FFFFFFFF);

    FatLine(AsphCanvas, X2 - 10, DispSize.Y - Y2/2 - 5, X2 - 10, DispSize.Y - 5, FL,
           false, false, $FFFFFFFF);

    FatLine(AsphCanvas, X1 + 10, DispSize.Y - 5, X2 - 10, DispSize.Y - 5, FL, false,
           false, $FFFFFFFF);


    if TMashtab[Mashtab]<1000 then
      s := IntTostr(TMashtab[Mashtab]) + ' ' + Msign
        else
          s := IntTostr(TMashtab[Mashtab] div 1000) + ' ' + KMsign;

    w := trunc((X2-X1)/2 - AsphFonts[FontN].TextWidth(s)/2) ;

    AsphFonts[Font0].TextOut( Point2(X1 + w, DispSize.Y - Y2-15),
                              s, clWhite2, 1.0);

end;

end.

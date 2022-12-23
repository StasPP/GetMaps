unit GeoMath;

//// Шевчук С. 2016

interface
  function Sign(x :double):Integer;       ///  Знак
  function Pow(x, n :double):Double ;     ///  x^y

  const Pi = 3.14159265358979;            ///  Число Пи
  const ro = 206264.8062471;                 ///  Число угловых секунд в радиане

implementation

uses Math;

function Sign (x : double):Integer;
begin
    if ( x >= 0 ) then Sign := 1 else Sign := -1;
end;

function Pow(x, n:double):Double ;
begin
  Pow := Power(x,n);//exp(n*ln(x));
end;


end.

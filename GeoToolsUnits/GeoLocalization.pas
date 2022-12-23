unit GeoLocalization;

interface

uses GeoFunctions, GeoFiles, GeoString, GeoClasses, Math;

procedure Loc2D(Xa1, Ya1, Xa2, Ya2, Xb1, Yb1, Xb2, Yb2 :Double;
                var Scale, Beta, A, B, C, D :Double; ConstScale:Boolean);

implementation

function Ang(A :Double):Double;
begin
  while A < 0 do
    A := A + 2*pi;
  while A > 2*pi do
    A := A - 2*pi;
  Result := A;
end;

procedure Loc2D(Xa1, Ya1, Xa2, Ya2, Xb1, Yb1, Xb2, Yb2 :Double;
                var Scale, Beta, A, B, C, D :Double; ConstScale:Boolean);
var L1, L2 :Double;
begin

  L1 := Sqrt(Sqr(Xb1 - Xa1) + Sqr(Yb1 - Ya1));
  L2 := Sqrt(Sqr(Xb2 - Xa2) + Sqr(Yb2 - Ya2));

  Scale := L2/L1;

  if ConstScale then
     Scale := 1;

  Beta := arctan2(Xa1 - Xb1,Ya1 - Yb1)
           -arctan2(Xa2 - Xb2, Ya2 - Yb2);


  if abs(Beta) > pi then
   begin if beta > 0 then
     Beta := Beta - 2*pi
       else
          Beta := Beta + 2*pi
   end;

  A := Scale * Cos(Beta);
  B := Scale * Sin(Beta);

  C :=( (Xa2 - ( A*Xa1 - B*Ya1))
      + (Xb2 - ( A*Xb1 - B*Yb1)) )/2;

  D :=( (Ya2 - ( A*Ya1 + B*Xa1))
      + (Yb2 - ( A*Yb1 + B*Xb1)) )/2;

end;

end.

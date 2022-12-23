unit Vectors2;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, AsphyreDef;

//---------------------------------------------------------------------------
const
 VecUp2   : TPoint2 = (x: 0.0; y: -1.0);
 VecDown2 : TPoint2 = (x: 0.0; y: 1.0);
 VecLeft2 : TPoint2 = (x: -1.0; y: 0.0);
 VecRight2: TPoint2 = (x: 1.0; y: 0.0);
 VecZero2 : TPoint2 = (x: 0.0; y: 0.0);

//---------------------------------------------------------------------------
function VecAbs2(const v: TPoint2): Real;
function VecScale2(const v: TPoint2; Theta: Real): TPoint2;
function VecNorm2(const v: TPoint2): TPoint2;
function VecAdd2(const a, b: TPoint2): TPoint2;
function VecSub2(const a, b: TPoint2): TPoint2;
function VecMul2(const a, b: TPoint2): TPoint2;
function VecNeg2(const v: TPoint2): TPoint2;
function VecAngle2(const v: TPoint2; Alpha: Real; Theta: Real = 1.0): TPoint2;
function VecAvg2(const a, b: TPoint2; Theta: Real = 0.5): TPoint2;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
function VecAbs2(const v: TPoint2): Real;
begin
 Result:= Sqrt(Sqr(v.x) + Sqr(v.y));
end;

//---------------------------------------------------------------------------
function VecScale2(const v: TPoint2; Theta: Real): TPoint2;
begin
 Result.x:= v.x * Theta;
 Result.y:= v.y * Theta;
end;

//---------------------------------------------------------------------------
function VecNorm2(const v: TPoint2): TPoint2;
begin
 Result:= VecScale2(v, 1.0 / VecAbs2(v));
end;

//---------------------------------------------------------------------------
function VecAdd2(const a, b: TPoint2): TPoint2;
begin
 Result.x:= a.x + b.x;
 Result.y:= a.y + b.y;
end;

//---------------------------------------------------------------------------
function VecAvg2(const a, b: TPoint2; Theta: Real): TPoint2;
begin
 Result.x:= b.x + ((a.x - b.x) * Theta);
 Result.y:= b.y + ((a.y - b.y) * Theta);
end;

//---------------------------------------------------------------------------
function VecSub2(const a, b: TPoint2): TPoint2;
begin
 Result.x:= a.x - b.x;
 Result.y:= a.y - b.y;
end;

//---------------------------------------------------------------------------
function VecNeg2(const v: TPoint2): TPoint2;
begin
 Result.x:= -v.x;
 Result.y:= -v.y;
end;

//---------------------------------------------------------------------------
function VecAngle2(const v: TPoint2; Alpha: Real; Theta: Real): TPoint2;
var
 Delta: Real;
begin
 Delta:= VecAbs2(v) * Theta;

 Result.x:= Cos(Alpha) * Delta;
 Result.y:= -Sin(Alpha) * Delta;
end;

//---------------------------------------------------------------------------
function VecMul2(const a, b: TPoint2): TPoint2;
begin
 Result.x:= a.x * b.x;
 Result.y:= a.y * b.y;
end;
 
//---------------------------------------------------------------------------
end.


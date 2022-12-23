unit FacingTypes;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, Math, AsphyreDef, AsphyreMath, AsphyreImages;

//---------------------------------------------------------------------------
type
 TFacingPrimitive = record
  Points  : TQuadPoints3;
  Colors  : TColor4;
  TexCoord: TPoint4;
  BlendOp : Integer;
  Image   : TAsphyreImage;
  TexNum  : Integer;
  MidPoint: TVector4;
 end;

//---------------------------------------------------------------------------
 TFacingPrimitives = class
 private
  Data: array of TFacingPrimitive;
  Indices: array of Integer;
  DataCount: Integer;

  function GetItem(Num: Integer): TFacingPrimitive;
  procedure SetItem(Num: Integer; const Value: TFacingPrimitive);
  procedure Request(Amount: Integer);
  function GetFaceIndex(Num: Integer): Integer;
 public
  property Count: Integer read DataCount;
  property Items[Num: Integer]: TFacingPrimitive read GetItem write SetItem; default;
  property FaceIndex[Num: Integer]: Integer read GetFaceIndex;

  function Add(const Item: TFacingPrimitive): Integer;
  procedure Remove(Index: Integer);
  procedure RemoveAll();

  procedure TransformMidPoints(const Matrix: TMatrix4);
  procedure UpdateFaceIndex();
  procedure SortFaceIndex();

  constructor Create();
  destructor Destroy(); override;
 end; 

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
const
 CacheSize = 512;

//---------------------------------------------------------------------------
constructor TFacingPrimitives.Create();
begin
 inherited;

 DataCount:= 0;
end;

//---------------------------------------------------------------------------
destructor TFacingPrimitives.Destroy();
begin
 SetLength(Data, 0);
 DataCount:= 0;

 inherited;
end;

//---------------------------------------------------------------------------
function TFacingPrimitives.GetItem(Num: Integer): TFacingPrimitive;
begin
 if (Num < 0)and(Num >= DataCount) then
  begin
   FillChar(Result, SizeOf(TFacingPrimitive), 0);
  end else Result:= Data[Num];
end;

//---------------------------------------------------------------------------
procedure TFacingPrimitives.SetItem(Num: Integer; const Value: TFacingPrimitive);
begin
 if (Num >= 0)and(Num < DataCount) then Data[Num]:= Value;
end;

//---------------------------------------------------------------------------
procedure TFacingPrimitives.Request(Amount: Integer);
var
 Required: Integer;
begin
 Required:= Ceil(Amount / CacheSize) * CacheSize;
 if (Length(Data) < Required) then SetLength(Data, Required);
end;

//---------------------------------------------------------------------------
function TFacingPrimitives.Add(const Item: TFacingPrimitive): Integer;
const
 Coef4 = 1.0 / 4.0;
var
 Index, i: Integer;
 Middle  : TPoint3;
begin
 Request(DataCount + 1);

 Index:= DataCount;
 Data[Index]:= Item;

 Middle:= ZeroVector3;
 for i:= 0 to 3 do
  Middle:= VecAdd3(Middle, Item.Points[i]);

 Data[Index].MidPoint:= Vec3to4(VecScale3(Middle, Coef4));

 Inc(DataCount);
 Result:= Index;
end;

//---------------------------------------------------------------------------
procedure TFacingPrimitives.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= DataCount) then Exit;

 for i:= Index to DataCount - 2 do
  Data[i]:= Data[i + 1];

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
procedure TFacingPrimitives.RemoveAll();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
function TFacingPrimitives.GetFaceIndex(Num: Integer): Integer;
begin
 Result:= Indices[Num];
end;

//---------------------------------------------------------------------------
procedure TFacingPrimitives.UpdateFaceIndex();
var
 i: Integer;
begin
 SetLength(Indices, Length(Data));

 for i:= 0 to Length(Indices) - 1 do
  Indices[i]:= i;
end;

//---------------------------------------------------------------------------
procedure TFacingPrimitives.SortFaceIndex();

procedure QuickSort(Left, Right: Integer);
var
 i, j, Aux: Integer;
 z: Single;
begin
 i:= Left;
 j:= Right;
 z:= Data[Indices[(Left + Right) shr 1]].MidPoint.z;

 repeat
  while (Data[Indices[i]].MidPoint.z < z) do Inc(i);
  while (z < Data[Indices[j]].MidPoint.z) do Dec(j);

  if (i <= j) then
   begin
    Aux:= Indices[i];
    Indices[i]:= Indices[j];
    Indices[j]:= Aux;

    Inc(i);
    Dec(j);
   end;
 until (i > j);

 if (Left < j) then QuickSort(Left, j);
 if (i < Right) then QuickSort(i, Right);
end;

begin // SortFaceIndex()
 QuickSort(0, DataCount - 1);
end;

//---------------------------------------------------------------------------
procedure TFacingPrimitives.TransformMidPoints(const Matrix: TMatrix4);
var
 i: Integer;
begin
 for i:= 0 to DataCount - 1 do
  Data[i].MidPoint:= MatVecMul(Data[i].MidPoint, Matrix);
end;

//---------------------------------------------------------------------------
end.


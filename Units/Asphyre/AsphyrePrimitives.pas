unit AsphyrePrimitives;
//---------------------------------------------------------------------------
// AsphyrePrimitive.pas                                 Modified: 10-Oct-2005
// The implementation of several primitive lists                  Version 1.0
//---------------------------------------------------------------------------
// The contents of this file are subject to the Mozilla Public License
// Version 1.1 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS"
// basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
// License for the specific language governing rights and limitations
// under the License.
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, Math, AsphyreDef, AsphyreMath;

//---------------------------------------------------------------------------
type
 TPoints2 = class
 private
  Data: array of TPoint2;
  DataCount: Integer;

  function GetPoint(Num: Integer): TPoint2;
  procedure SetPoint(Num: Integer; const Value: TPoint2);
  procedure Request(Amount: Integer);
  function GetMemAddr(): Pointer;
 public
  property MemAddr: Pointer read GetMemAddr;
  property Count: Integer read DataCount;
  property Point[Num: Integer]: TPoint2 read GetPoint write SetPoint; default;

  function Add(const Point: TPoint2): Integer; overload;
  function Add(x, y: Real): Integer; overload;
  procedure Remove(Index: Integer);
  procedure RemoveAll();

  procedure CopyFrom(Source: TPoints2);
  procedure AddFrom(Source: TPoints2);

  procedure SaveToStream(Stream: TStream);
  procedure LoadFromStream(Stream: TStream);

  constructor Create();
  destructor Destroy(); override;
 end;

//--------------------------------------------------------------------------
 TFace3 = record
  Index : array[0..2] of Word;
  Normal: TPoint3;
 end;

//--------------------------------------------------------------------------
 TFaces3 = class
 private
  Data: array of TFace3;
  DataCount: Integer;

  function GetFace(Num: Integer): TFace3;
  procedure SetFace(Num: Integer; const Value: TFace3);
  procedure Request(Amount: Integer);
 public
  property Count: Integer read DataCount;
  property Face[Num: Integer]: TFace3 read GetFace write SetFace; default;

  function Add(const Face: TFace3): Integer;
  procedure Remove(Num: Integer);
  procedure RemoveAll();

  procedure SaveToStream(Stream: TStream);
  procedure LoadFromStream(Stream: TStream);

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TPoints3 = class
 private
  Data: array of TPoint3;
  DataCount: Integer;

  function GetPoint(Num: Integer): TPoint3;
  procedure SetPoint(Num: Integer; const Value: TPoint3);
  procedure Request(Amount: Integer);
  function GetMemAddr(): Pointer;
 public
  property MemAddr: Pointer read GetMemAddr;
  property Count: Integer read DataCount;
  property Point[Num: Integer]: TPoint3 read GetPoint write SetPoint; default;

  function Add(const Point: TPoint3): Integer; overload;
  function Add(x, y, z: Real): Integer; overload;
  procedure Remove(Index: Integer);
  procedure RemoveAll();

  procedure CopyFrom(Source: TPoints3);
  procedure AddFrom(Source: TPoints3);

  procedure SaveToStream(Stream: TStream);
  procedure LoadFromStream(Stream: TStream);

  procedure Normalize();
  procedure Centralize();
  procedure FindNormals(Faces: TFaces3; Points: TPoints3);
  procedure Rescale(Scale: Real);
  procedure Invert();

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
const
 CacheSize = 512;

//---------------------------------------------------------------------------
constructor TPoints2.Create();
begin
 inherited;

 DataCount:= 0;
end;

//---------------------------------------------------------------------------
destructor TPoints2.Destroy();
begin
 DataCount:= 0;
 SetLength(Data, 0);

 inherited;
end;

//---------------------------------------------------------------------------
function TPoints2.GetMemAddr(): Pointer;
begin
 Result:= @Data[0];
end;

//---------------------------------------------------------------------------
function TPoints2.GetPoint(Num: Integer): TPoint2;
begin
 if (Num >= 0)and(Num < DataCount) then Result:= Data[Num]
  else Result:= Point2(0.0, 0.0);
end;

//---------------------------------------------------------------------------
procedure TPoints2.SetPoint(Num: Integer; const Value: TPoint2);
begin
 if (Num >= 0)and(Num < DataCount) then Data[Num]:= Value;
end;

//---------------------------------------------------------------------------
procedure TPoints2.Request(Amount: Integer);
var
 Required: Integer;
begin
 Required:= Ceil(Amount / CacheSize) * CacheSize;
 if (Length(Data) < Required) then SetLength(Data, Required);
end;

//---------------------------------------------------------------------------
function TPoints2.Add(const Point: TPoint2): Integer;
var
 Index: Integer;
begin
 Index:= DataCount;
 Request(DataCount + 1);

 Data[Index]:= Point;
 Inc(DataCount);

 Result:= Index;
end;

//---------------------------------------------------------------------------
function TPoints2.Add(x, y: Real): Integer;
begin
 Result:= Add(Point2(x, y));
end;

//---------------------------------------------------------------------------
procedure TPoints2.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= DataCount) then Exit;

 for i:= Index to DataCount - 2 do
  Data[i]:= Data[i + 1];

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
procedure TPoints2.RemoveAll();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
procedure TPoints2.CopyFrom(Source: TPoints2);
var
 i: Integer;
begin
 Request(Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i]:= Source.Data[i];

 DataCount:= Source.DataCount;
end;

//---------------------------------------------------------------------------
procedure TPoints2.AddFrom(Source: TPoints2);
var
 i: Integer;
begin
 Request(DataCount + Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i + DataCount]:= Source.Data[i];

 Inc(DataCount, Source.DataCount);
end;

//---------------------------------------------------------------------------
procedure TPoints2.SaveToStream(Stream: TStream);
begin
 Stream.WriteBuffer(DataCount, SizeOf(Integer));
 Stream.WriteBuffer(Data[0], DataCount * SizeOf(TPoint2));
end;

//---------------------------------------------------------------------------
procedure TPoints2.LoadFromStream(Stream: TStream);
begin
 Stream.ReadBuffer(DataCount, SizeOf(Integer));

 Request(DataCount);
 Stream.ReadBuffer(Data[0], DataCount * SizeOf(TPoint2));
end;

//--------------------------------------------------------------------------
constructor TFaces3.Create();
begin
 inherited;

 SetLength(Data, 0);
end;

//--------------------------------------------------------------------------
destructor TFaces3.Destroy();
begin
 SetLength(Data, 0);

 inherited;
end;

//--------------------------------------------------------------------------
function TFaces3.GetFace(Num: Integer): TFace3;
begin
 Result:= Data[Num];
end;

//--------------------------------------------------------------------------
procedure TFaces3.SetFace(Num: Integer; const Value: TFace3);
begin
 Data[Num]:= Value;
end;

//--------------------------------------------------------------------------
procedure TFaces3.Request(Amount: Integer);
var
 Required: Integer;
begin
 Required:= Ceil(Amount / CacheSize) * CacheSize;
 if (Required > Length(Data)) then SetLength(Data, Required);
end;

//--------------------------------------------------------------------------
function TFaces3.Add(const Face: TFace3): Integer;
var
 Index: Integer;
begin
 Request(DataCount + 1);

 Index:= DataCount;
 Data[Index]:= Face;
 Inc(DataCount);

 Result:= Index;
end;

//--------------------------------------------------------------------------
procedure TFaces3.Remove(Num: Integer);
var
 i: Integer;
begin
 if (Num < 0)or(Num >= DataCount) then Exit;

 for i:= Num to DataCount - 2 do
  Data[i]:= Data[i + 1];

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
procedure TFaces3.RemoveAll();
begin
 DataCount:= 0;
end;

//--------------------------------------------------------------------------
procedure TFaces3.SaveToStream(Stream: TStream);
begin
 Stream.WriteBuffer(DataCount, SizeOf(Integer));
 Stream.WriteBuffer(Data[0], DataCount * SizeOf(TFace3));
end;

//--------------------------------------------------------------------------
procedure TFaces3.LoadFromStream(Stream: TStream);
begin
 Stream.ReadBuffer(DataCount, SizeOf(Integer));

 Request(DataCount);
 Stream.ReadBuffer(Data[0], DataCount * SizeOf(TFace3));
end;

//---------------------------------------------------------------------------
constructor TPoints3.Create();
begin
 inherited;

 DataCount:= 0;
end;

//---------------------------------------------------------------------------
destructor TPoints3.Destroy();
begin
 DataCount:= 0;
 SetLength(Data, 0);

 inherited;
end;

//---------------------------------------------------------------------------
function TPoints3.GetMemAddr(): Pointer;
begin
 if (DataCount > 0) then Result:= @Data[0] else Result:= nil;
end;

//---------------------------------------------------------------------------
function TPoints3.GetPoint(Num: Integer): TPoint3;
begin
 if (Num >= 0)and(Num < DataCount) then Result:= Data[Num]
  else Result:= ZeroVector3;
end;

//---------------------------------------------------------------------------
procedure TPoints3.SetPoint(Num: Integer; const Value: TPoint3);
begin
 if (Num >= 0)and(Num < DataCount) then Data[Num]:= Value;
end;

//---------------------------------------------------------------------------
procedure TPoints3.Request(Amount: Integer);
var
 Required: Integer;
begin
 Required:= Ceil(Amount / CacheSize) * CacheSize;
 if (Length(Data) < Required) then SetLength(Data, Required);
end;

//---------------------------------------------------------------------------
function TPoints3.Add(const Point: TPoint3): Integer;
var
 Index: Integer;
begin
 Index:= DataCount;
 Request(DataCount + 1);

 Data[Index]:= Point;
 Inc(DataCount);

 Result:= Index;
end;

//---------------------------------------------------------------------------
function TPoints3.Add(x, y, z: Real): Integer;
begin
 Result:= Add(Point3(x, y, z));
end;

//---------------------------------------------------------------------------
procedure TPoints3.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= DataCount) then Exit;

 for i:= Index to DataCount - 2 do
  Data[i]:= Data[i + 1];

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
procedure TPoints3.RemoveAll();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
procedure TPoints3.CopyFrom(Source: TPoints3);
var
 i: Integer;
begin
 Request(Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i]:= Source.Data[i];

 DataCount:= Source.DataCount;
end;

//---------------------------------------------------------------------------
procedure TPoints3.AddFrom(Source: TPoints3);
var
 i: Integer;
begin
 Request(DataCount + Source.DataCount);

 for i:= 0 to Source.DataCount - 1 do
  Data[i + DataCount]:= Source.Data[i];

 Inc(DataCount, Source.DataCount);
end;

//--------------------------------------------------------------------------
procedure TPoints3.SaveToStream(Stream: TStream);
begin
 Stream.WriteBuffer(DataCount, SizeOf(Integer));
 Stream.WriteBuffer(Data[0], DataCount * SizeOf(TPoint3));
end;

//--------------------------------------------------------------------------
procedure TPoints3.LoadFromStream(Stream: TStream);
begin
 Stream.ReadBuffer(DataCount, SizeOf(Integer));

 Request(DataCount);
 Stream.ReadBuffer(Data[0], DataCount * SizeOf(TPoint3));
end;

//--------------------------------------------------------------------------
procedure TPoints3.Normalize();
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  Data[i]:= VecNorm3(Data[i]);
end;

//--------------------------------------------------------------------------
procedure TPoints3.Rescale(Scale: Real);
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  Data[i]:= VecScale3(Data[i], Scale);
end;

//---------------------------------------------------------------------------
procedure TPoints3.Invert();
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  Data[i]:= VecNeg3(Data[i]);
end;

//--------------------------------------------------------------------------
procedure TPoints3.Centralize();
var
 i: Integer;
 MinPoint: TPoint3;
 MaxPoint: TPoint3;
 Middle  : TPoint3;
begin
 if (DataCount < 1) then Exit;

 MinPoint:= Point3(High(Integer), High(Integer), High(Integer));
 MaxPoint:= Point3(Low(Integer), Low(Integer), Low(Integer));

 for i:= 0 to DataCount - 1 do
  begin
   MinPoint.x:= Min(MinPoint.x, Data[i].x);
   MinPoint.y:= Min(MinPoint.y, Data[i].y);
   MinPoint.z:= Min(MinPoint.z, Data[i].z);

   MaxPoint.x:= Max(MaxPoint.x, Data[i].x);
   MaxPoint.y:= Max(MaxPoint.y, Data[i].y);
   MaxPoint.z:= Max(MaxPoint.z, Data[i].z);
  end;

 Middle.x:= (MinPoint.x + MaxPoint.x) / 2.0;
 Middle.y:= (MinPoint.y + MaxPoint.y) / 2.0;
 Middle.z:= (MinPoint.z + MaxPoint.z) / 2.0;

 for i:= 0 to DataCount - 1 do
  Data[i]:= VecSub3(Data[i], Middle);
end;

//--------------------------------------------------------------------------
procedure TPoints3.FindNormals(Faces: TFaces3; Points: TPoints3);
var
 i, Index0, Index1, Index2, FaceIndex, Index: Integer;
 p0, p1, p2, Vec0, Vec1, Normal, CrossProd: TPoint3;
 MyFace: TFace3;
 FaceAreas: array of Real;
begin
 DataCount:= 0;
 Request(Points.Count);

 // for each face, find the following:
 //   1) Face Normal
 //   2) Face Area (as weight for Vertex Normal calculation)
 SetLength(FaceAreas, Faces.Count);
 for i:= 0 to Faces.Count - 1 do
  begin
   MyFace:= Faces[i];

   Index0:= MyFace.Index[0];
   Index1:= MyFace.Index[1];
   Index2:= MyFace.Index[2];

   p0:= Points[Index0];
   p1:= Points[Index1];
   p2:= Points[Index2];

   Vec0:= VecSub3(p2, p0);
   Vec1:= VecSub3(p2, p1);

   CrossProd:= VecCross3(Vec0, Vec1);
   MyFace.Normal:= VecNorm3(CrossProd);
   Faces[i]:= MyFace;

   FaceAreas[i]:= VecAbs3(CrossProd) * 0.5;
  end;

 // create normals as an average of all faces
 for i:= 0 to Points.Count - 1 do
  begin
   Normal:= ZeroVector3;
   Vec0  := Points[i];

   for FaceIndex:= 0 to Faces.Count - 1 do
    for Index:= 0 to 2 do
     begin
      Vec1:= Points[Faces[FaceIndex].Index[Index]];
      if (SameVec3(Vec0, Vec1)) then
       Normal:= VecAdd3(Normal, VecScale3(Faces[FaceIndex].Normal, FaceAreas[FaceIndex]));
     end;  

   Data[i]:= VecNorm3(Normal);
  end;

 DataCount:= Points.Count;
end;

//---------------------------------------------------------------------------
end.


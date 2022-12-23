unit ClassesEx;
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
 Types, Classes, SysUtils;

//---------------------------------------------------------------------------
const
 PointInvalid: TPoint = (X: Low(Integer); Y: Low(Integer));
 InvalidIndex   = -1;
 InvalidNum     = Low(Integer);
 IntInfinity    = High(Integer);
 IntNegInfinity = High(Integer);

//---------------------------------------------------------------------------
type
 TPointItem = record
  Pt   : TPoint;
  Alpha: Integer;
  Beta : Integer;
  ID   : Integer;
 end;

//---------------------------------------------------------------------------
 TPointList = class(TCollectionItem)
 private
  Data : array of TPointItem;
  IDNum: Integer;
  FTag: Integer;

  function CountPoints(): Integer;
  function GetItem(Num: Integer): TPoint;
  procedure SetItem(Num: Integer; const Value: TPoint);
  function GetItemID(ID: Integer): TPointItem;
  function GetAlpha(Num: Integer): Integer;
  function GetBeta(Num: Integer): Integer;
  procedure SetAlpha(Num: Integer; const Value: Integer);
  procedure SetBeta(Num: Integer; const Value: Integer);
  function GetAlphaSum(): Integer;
  function GetBetaSum(): Integer;
  function GetCenterPoint(): TPoint;
  procedure SetTag(const Value: Integer);
 protected
  function UniqueID(): Integer;

 public
  // default TPoint access
  property Items[Num: Integer]: TPoint read GetItem write SetItem; default;
  // point value access
  property Alpha[Num: Integer]: Integer read GetAlpha write SetAlpha;
  property Beta[Num: Integer]: Integer read GetBeta write SetBeta;

  property ItemID[ID: Integer]: TPointItem read GetItemID;

  // statistic routines
  property Count   : Integer read CountPoints;
  property AlphaSum: Integer read GetAlphaSum;
  property BetaSum : Integer read GetBetaSum;
  property CenterPoint: TPoint read GetCenterPoint;

  property Tag: Integer read FTag write SetTag;

  constructor Create(); reintroduce; overload;
  constructor Create(Collection: TCollection); overload; override;
  destructor Destroy(); override;

  procedure Clear();

  function Insert(Pt: TPoint; Alpha, Beta: Integer): Integer; overload;
  function Insert(Pt: TPoint; Alpha: Integer): Integer; overload;
  function Insert(Pt: TPoint): Integer; overload;

  function InsertUnique(Pt: TPoint; Alpha, Beta: Integer): Integer; overload;
  function InsertUnique(Pt: TPoint): Integer; overload;

  function FindByID(ID: Integer): Integer;
  function Find(Pt: TPoint; Alpha, Beta: Integer): Integer; overload;
  function Find(Pt: TPoint; Alpha: Integer): Integer; overload;
  function Find(Pt: TPoint): Integer; overload;
  function FindY(Y: Integer): Integer;
  function FindX(X: Integer): Integer;
  function FindBack(Pt: TPoint): Integer;

  procedure InsertUniqueFrom(Source: TPointList);

  procedure Remove(Num: Integer);
  procedure RemoveID(ID: Integer);
 end;

//---------------------------------------------------------------------------
 TPointGroup = class(TCollection)
 private
  function GetItem(Index: Integer): TPointList;
  procedure SetItem(Index: Integer; const Value: TPointList);
 protected
 public
  property Items[Index: Integer]: TPointList read GetItem write SetItem; default;

  function Add(): TPointList;
  function AddItem(Item: TPointList; Index: Integer): TPointList;
  function Insert(Index: Integer): TPointList;

  constructor Create();
 end;

//---------------------------------------------------------------------------
 TIntegers = class(TCollectionItem)
 private
  Data: array of Integer;

  function GetItem(Num: Integer): Integer;
  procedure SetItem(Num: Integer; const Value: Integer);
  function GetCount(): Integer;
  function GetIntAvg(): Integer;
  function GetIntSum(): Integer;
  function GetIntMax(): Integer;
  function GetIntMin(): Integer;
 public
  property Items[Num: Integer]: Integer read GetItem write SetItem; default;
  property Count: Integer read GetCount;

  property IntSum: Integer read GetIntSum;
  property IntAvg: Integer read GetIntAvg;
  property IntMax: Integer read GetIntMax;
  property IntMin: Integer read GetIntMin;

  function Insert(const Value: Integer): Integer;
  procedure Remove(Num: Integer);
  procedure Clear();
  // tries to find the element or returns InvalidIndex otherwise
  function Find(const Value: Integer): Integer;

  // inserts the element if it doesn't exist in the list
  procedure Include(const Value: Integer);
  procedure Exclude(const Value: Integer);
  function Exists(const Value: Integer): Boolean;
  procedure Serie(Count: Integer);
  procedure Shuffle();

  procedure InsertFrom(Source: TIntegers);
  procedure CopyFrom(Source: TIntegers);

  // adds elements from other list
  procedure JoinFrom(Source: TIntegers);

  constructor Create(); reintroduce; overload;
  constructor Create(Collection: TCollection); overload; override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TIntGroup = class(TCollection)
 private
  function GetItem(Index: Integer): TIntegers;
  procedure SetItem(Index: Integer; const Value: TIntegers);
 protected
 public
  property Items[Index: Integer]: TIntegers read GetItem write SetItem; default;

  function Add(): TIntegers;
  function AddItem(Item: TIntegers; Index: Integer): TIntegers;
  function Insert(Index: Integer): TIntegers;

  constructor Create();
 end;

//---------------------------------------------------------------------------
implementation
uses
 Math;

//---------------------------------------------------------------------------
constructor TPointList.Create();
begin
 inherited Create(nil);

 Clear();
 IDNum:= High(Integer);
 FTag:= 0;
end;


//---------------------------------------------------------------------------
constructor TPointList.Create(Collection: TCollection);
begin
 inherited;

 Clear();
 IDNum:= High(Integer);
 FTag:= 0;
end;

//---------------------------------------------------------------------------
destructor TPointList.Destroy();
begin
 Clear();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TPointList.Clear();
begin
 SetLength(Data, 0);
end;

//---------------------------------------------------------------------------
function TPointList.CountPoints(): Integer;
begin
 Result:= Length(Data);
end;

//---------------------------------------------------------------------------
function TPointList.GetItem(Num: Integer): TPoint;
begin
 if (Num >= 0)and(Num < Length(Data)) then Result:= Data[Num].Pt
  else Result:= PointInvalid;
end;

//---------------------------------------------------------------------------
procedure TPointList.SetItem(Num: Integer; const Value: TPoint);
begin
 if (Num >= 0)and(Num < Length(Data)) then Data[Num].Pt:= Value;
end;

//---------------------------------------------------------------------------
function TPointList.UniqueID(): Integer;
begin
 Result:= IDNum;
 Dec(IDNum);
end;

//---------------------------------------------------------------------------
function TPointList.Insert(Pt: TPoint; Alpha, Beta: Integer): Integer;
var
 Index: Integer;
begin
 Index:= Length(Data);
 SetLength(Data, Index + 1);

 Data[Index].ID   := UniqueID();
 Data[Index].Pt   := Pt;
 Data[Index].Alpha:= Alpha;
 Data[Index].Beta := Beta;

 Result:= Index;
end;

//---------------------------------------------------------------------------
function TPointList.Insert(Pt: TPoint; Alpha: Integer): Integer;
begin
 Result:= Insert(Pt, Alpha, 0);
end;

//---------------------------------------------------------------------------
function TPointList.Insert(Pt: TPoint): Integer;
begin
 Result:= Insert(Pt, 0, 0);
end;

//---------------------------------------------------------------------------
function TPointList.GetItemID(ID: Integer): TPointItem;
var
 Index: Integer;
begin
 Index:= FindByID(ID);
 if (Index <> InvalidIndex) then Result:= Data[Index]
  else FillChar(Result, SizeOf(TPointItem), 0);
end;

//---------------------------------------------------------------------------
function TPointList.GetAlpha(Num: Integer): Integer;
begin
 if (Num >= 0)and(Num < Length(Data)) then Result:= Data[Num].Alpha else Result:= 0;
end;

//---------------------------------------------------------------------------
function TPointList.GetBeta(Num: Integer): Integer;
begin
 if (Num >= 0)and(Num < Length(Data)) then Result:= Data[Num].Beta else Result:= 0;
end;

//---------------------------------------------------------------------------
procedure TPointList.SetAlpha(Num: Integer; const Value: Integer);
begin
 if (Num >= 0)and(Num < Length(Data)) then Data[Num].Alpha:= Value;
end;

//---------------------------------------------------------------------------
procedure TPointList.SetBeta(Num: Integer; const Value: Integer);
begin
 if (Num >= 0)and(Num < Length(Data)) then Data[Num].Beta:= Value;
end;

//---------------------------------------------------------------------------
function TPointList.FindByID(ID: Integer): Integer;
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  if (Data[i].ID = ID) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= InvalidIndex;
end;

//---------------------------------------------------------------------------
procedure TPointList.Remove(Num: Integer);
var
 i: Integer;
begin
 if (Num < 0)or(Num >= Length(Data)) then Exit;

 for i:= Num to Length(Data) - 2 do
  Data[i]:= Data[i + 1];

 SetLength(Data, Length(Data) - 1);
end;

//---------------------------------------------------------------------------
procedure TPointList.RemoveID(ID: Integer);
var
 Index: Integer;
begin
 Index:= FindByID(ID);
 if (Index <> InvalidIndex) then Remove(Index);
end;

//---------------------------------------------------------------------------
function TPointList.Find(Pt: TPoint; Alpha, Beta: Integer): Integer;
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  if (Data[i].Pt.X = Pt.X)and(Data[i].Pt.Y = Pt.Y)and(Data[i].Alpha = Alpha)and(Data[i].Beta = Beta) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= InvalidIndex;
end;

//---------------------------------------------------------------------------
function TPointList.Find(Pt: TPoint; Alpha: Integer): Integer;
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  if (Data[i].Pt.X = Pt.X)and(Data[i].Pt.Y = Pt.Y)and(Data[i].Alpha = Alpha) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= InvalidIndex;
end;

//---------------------------------------------------------------------------
function TPointList.FindX(X: Integer): Integer;
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  if (Data[i].Pt.X = X) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= InvalidIndex;
end;

//---------------------------------------------------------------------------
function TPointList.FindY(Y: Integer): Integer;
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  if (Data[i].Pt.Y = Y) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= InvalidIndex;
end;

//---------------------------------------------------------------------------
function TPointList.Find(Pt: TPoint): Integer;
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  if (Data[i].Pt.X = Pt.X)and(Data[i].Pt.Y = Pt.Y) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= InvalidIndex;
end;

//---------------------------------------------------------------------------
function TPointList.FindBack(Pt: TPoint): Integer;
var
 i: Integer;
begin
 for i:= Length(Data) - 1 downto 0 do
  if (Data[i].Pt.X = Pt.X)and(Data[i].Pt.Y = Pt.Y) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= InvalidIndex;
end;

//---------------------------------------------------------------------------
function TPointList.InsertUnique(Pt: TPoint; Alpha, Beta: Integer): Integer;
var
 Index: Integer;
begin
 Index:= Find(Pt, Alpha, Beta);

 if (Index = InvalidIndex) then Index:= Insert(Pt, Alpha, Beta);

 Result:= Index;
end;

//---------------------------------------------------------------------------
function TPointList.InsertUnique(Pt: TPoint): Integer;
var
 Index: Integer;
begin
 Index:= Find(Pt);

 if (Index = InvalidIndex) then Index:= Insert(Pt);

 Result:= Index;
end;

//---------------------------------------------------------------------------
function TPointList.GetAlphaSum(): Integer;
var
 i: Integer;
begin
 Result:= 0;
 for i:= 0 to Length(Data) - 1 do
  Inc(Result, Data[i].Alpha);
end;

//---------------------------------------------------------------------------
function TPointList.GetBetaSum(): Integer;
var
 i: Integer;
begin
 Result:= 0;
 for i:= 0 to Length(Data) - 1 do
  Inc(Result, Data[i].Beta);
end;

//---------------------------------------------------------------------------
function TPointList.GetCenterPoint(): TPoint;
var
 i, x, y, Total: Integer;
begin
 Total:= CountPoints();
 if (Total < 1) then
  begin
   Result:= Point(0, 0);
   Exit;
  end; 

 x:= 0; y:= 0;
 for i:= 0 to Length(Data) - 1 do
  begin
   Inc(x, Data[i].Pt.X);
   Inc(Y, Data[i].Pt.Y);
  end;

 Result:= Point(x div Total, y div Total);
end;

//---------------------------------------------------------------------------
procedure TPointList.SetTag(const Value: Integer);
begin
 FTag:= Value;
end;

//---------------------------------------------------------------------------
procedure TPointList.InsertUniqueFrom(Source: TPointList);
var
 i: Integer;
begin
 for i:= 0 to Source.Count - 1 do
  if (Find(Source[i], Source.Alpha[i], Source.Beta[i]) = InvalidIndex) then
   Insert(Source[i], Source.Alpha[i], Source.Beta[i]);
end;

//---------------------------------------------------------------------------
constructor TPointGroup.Create();
begin
 inherited Create(TPointList);
end;

//---------------------------------------------------------------------------
function TPointGroup.GetItem(Index: Integer): TPointList;
begin
 Result:= TPointList(inherited GetItem(Index));
end;

//---------------------------------------------------------------------------
procedure TPointGroup.SetItem(Index: Integer; const Value: TPointList);
begin
 inherited SetItem(Index, Value);
end;

//---------------------------------------------------------------------------
function TPointGroup.Add(): TPointList;
begin
 Result:= TPointList(inherited Add());
end;

//---------------------------------------------------------------------------
function TPointGroup.AddItem(Item: TPointList; Index: Integer): TPointList;
begin
 if (Item = nil) then Result:= TPointList.Create(Self)
  else Result:= Item;

 if (Assigned(Result)) then
  begin
   Result.Collection:= Self;
   if (Index < 0) then Index:= Count - 1;
   Result.Index:= Index;
  end;
end;

//---------------------------------------------------------------------------
function TPointGroup.Insert(Index: Integer): TPointList;
begin
 Result:= AddItem(nil, Index);
end;

//---------------------------------------------------------------------------
constructor TIntegers.Create();
begin
 inherited Create(nil);

 SetLength(Data, 0);
end;

//---------------------------------------------------------------------------
constructor TIntegers.Create(Collection: TCollection);
begin
 inherited;

 SetLength(Data, 0);
end;

//---------------------------------------------------------------------------
destructor TIntegers.Destroy();
begin
 SetLength(Data, 0);

 inherited;
end;

//---------------------------------------------------------------------------
function TIntegers.GetItem(Num: Integer): Integer;
begin
 if (Num >= 0)and(Num < Length(Data)) then
   Result:= Data[Num] else Result:= 0;
end;

//---------------------------------------------------------------------------
procedure TIntegers.SetItem(Num: Integer; const Value: Integer);
var
 PrevSize, NewSize, i: Integer;
begin
 PrevSize:= Length(Data);
 if (Length(Data) <= Num) then
  begin
   NewSize:= Num + 1;
   SetLength(Data, NewSize);
   for i:= PrevSize to NewSize - 2 do Data[i]:= 0;
  end;

 Data[Num]:= Value;
end;

//---------------------------------------------------------------------------
function TIntegers.Insert(const Value: Integer): Integer;
var
 Index: Integer;
begin
 Index:= Length(Data);
 SetLength(Data, Index + 1);

 Data[Index]:= Value;
 Result:= Index;
end;

//---------------------------------------------------------------------------
function TIntegers.Find(const Value: Integer): Integer;
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  if (Data[i] = Value) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= InvalidIndex;
end;

//---------------------------------------------------------------------------
procedure TIntegers.Include(const Value: Integer);
begin
 if (Find(Value) = InvalidIndex) then Insert(Value);
end;

//---------------------------------------------------------------------------
function TIntegers.GetCount(): Integer;
begin
 Result:= Length(Data);
end;

//---------------------------------------------------------------------------
procedure TIntegers.Remove(Num: Integer);
var
 i: Integer;
begin
 if (Num < 0)or(Num >= Length(Data)) then Exit;

 for i:= Num to Length(Data) - 2 do
  Data[i]:= Data[i + 1];

 SetLength(Data, Length(Data) - 1);
end;

//---------------------------------------------------------------------------
procedure TIntegers.Exclude(const Value: Integer);
var
 Index: Integer;
begin
 Index:= Find(Value);
 if (Index <> InvalidIndex) then Remove(Index);
end;

//---------------------------------------------------------------------------
function TIntegers.Exists(const Value: Integer): Boolean;
begin
 Result:= (Find(Value) <> InvalidIndex);
end;

//---------------------------------------------------------------------------
function TIntegers.GetIntSum(): Integer;
var
 i: Integer;
begin
 Result:= 0;
 for i:= 0 to Length(Data) - 1 do
  Inc(Result, Data[i]);
end;

//---------------------------------------------------------------------------
function TIntegers.GetIntAvg(): Integer;
begin
 if (Length(Data) > 0) then
  Result:= GetIntSum() div Length(Data)
   else Result:= 0;
end;

//---------------------------------------------------------------------------
procedure TIntegers.JoinFrom(Source: TIntegers);
var
 i: Integer;
begin
 for i:= 0 to Source.Count - 1 do
  if (Find(Source[i]) = InvalidIndex) then Include(Source[i]);
end;

//---------------------------------------------------------------------------
procedure TIntegers.InsertFrom(Source: TIntegers);
var
 i: Integer;
begin
 for i:= 0 to Source.Count - 1 do Insert(Source[i]);
end;

//---------------------------------------------------------------------------
procedure TIntegers.CopyFrom(Source: TIntegers);
begin
 Clear();
 InsertFrom(Source);
end;

//---------------------------------------------------------------------------
procedure TIntegers.Clear();
begin
 SetLength(Data, 0);
end;

//---------------------------------------------------------------------------
function TIntegers.GetIntMax(): Integer;
var
 i: Integer;
begin
 if (Length(Data) < 1) then
  begin
   Result:= 0;
   Exit;
  end;

 Result:= Data[0];
 for i:= 1 to Length(Data) - 1 do
  Result:= Max(Result, Data[i]);
end;

//---------------------------------------------------------------------------
function TIntegers.GetIntMin(): Integer;
var
 i: Integer;
begin
 if (Length(Data) < 1) then
  begin
   Result:= 0;
   Exit;
  end;

 Result:= Data[0];
 for i:= 1 to Length(Data) - 1 do
  Result:= Min(Result, Data[i]);
end;

//---------------------------------------------------------------------------
procedure TIntegers.Shuffle();
var
 i, Aux, Indx: Integer;
begin
 for i:= Length(Data) - 1 downto 1 do
  begin
   Indx:= Random(i);

   Aux:= Data[i];
   Data[i]:= Data[Indx];
   Data[Indx]:= Aux;
  end;
end;

//---------------------------------------------------------------------------
procedure TIntegers.Serie(Count: Integer);
var
 i: Integer;
begin
 SetLength(Data, Count);

 for i:= 0 to Length(Data) - 1 do
  Data[i]:= i;
end;

//---------------------------------------------------------------------------
constructor TIntGroup.Create();
begin
 inherited Create(TIntegers);
end;

//---------------------------------------------------------------------------
function TIntGroup.GetItem(Index: Integer): TIntegers;
begin
 Result:= TIntegers(inherited GetItem(Index));
end;

//---------------------------------------------------------------------------
procedure TIntGroup.SetItem(Index: Integer; const Value: TIntegers);
begin
 inherited SetItem(Index, Value);
end;

//---------------------------------------------------------------------------
function TIntGroup.Add(): TIntegers;
begin
 Result:= TIntegers(inherited Add());
end;

//---------------------------------------------------------------------------
function TIntGroup.AddItem(Item: TIntegers; Index: Integer): TIntegers;
begin
 if (Item = nil) then Result:= TIntegers.Create(Self)
  else Result:= Item;

 if (Assigned(Result)) then
  begin
   Result.Collection:= Self;
   if (Index < 0) then Index:= Count - 1;
   Result.Index:= Index;
  end;
end;

//---------------------------------------------------------------------------
function TIntGroup.Insert(Index: Integer): TIntegers;
begin
 Result:= AddItem(nil, Index);
end;

//---------------------------------------------------------------------------
end.

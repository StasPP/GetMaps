unit BBTypes;
//---------------------------------------------------------------------------
// BBTypes.pas                                          Modified: 10-Oct-2005
// Billboard storage type implementation                          Version 1.0
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
 Types, Classes, SysUtils, Math, AsphyreDef, AsphyreMath, AsphyreImages;

//---------------------------------------------------------------------------
type
//---------------------------------------------------------------------------
// Heavy-weight billboard record
//---------------------------------------------------------------------------
 TBillboard = record
  Size    : TPoint2;
  TexCoord: TPoint4;
  Diffuse : TColor4;
  BlendOp : Integer;
  Image   : TAsphyreImage;
  TexNum  : Integer;
 end;

//---------------------------------------------------------------------------
 TBillboards = class
 private
  Data: array of TBillboard;
  DataCount: Integer;

  function GetItem(Num: Integer): TBillboard;
  procedure SetItem(Num: Integer; const Value: TBillboard);
  procedure Request(Amount: Integer);
 public
  property Count: Integer read DataCount;
  property Items[Num: Integer]: TBillboard read GetItem write SetItem; default;

  function Add(const Item: TBillboard): Integer;
  procedure Remove(Index: Integer);
  procedure RemoveAll();

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
const
 CacheSize = 512;

//---------------------------------------------------------------------------
constructor TBillboards.Create();
begin
 inherited;

 DataCount:= 0;
end;

//---------------------------------------------------------------------------
destructor TBillboards.Destroy();
begin
 SetLength(Data, 0);
 DataCount:= 0;

 inherited;
end;

//---------------------------------------------------------------------------
function TBillboards.GetItem(Num: Integer): TBillboard;
begin
 if (Num < 0)and(Num >= DataCount) then
  begin
   FillChar(Result, SizeOf(TBillboard), 0);
  end else Result:= Data[Num];
end;

//---------------------------------------------------------------------------
procedure TBillboards.SetItem(Num: Integer; const Value: TBillboard);
begin
 if (Num >= 0)and(Num < DataCount) then Data[Num]:= Value;
end;

//---------------------------------------------------------------------------
procedure TBillboards.Request(Amount: Integer);
var
 Required: Integer;
begin
 Required:= Ceil(Amount / CacheSize) * CacheSize;
 if (Length(Data) < Required) then SetLength(Data, Required);
end;

//---------------------------------------------------------------------------
function TBillboards.Add(const Item: TBillboard): Integer;
var
 Index: Integer;
begin
 Request(DataCount + 1);

 Index:= DataCount;
 Data[Index]:= Item;

 Inc(DataCount);
 Result:= Index;
end;

//---------------------------------------------------------------------------
procedure TBillboards.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= DataCount) then Exit;

 for i:= Index to DataCount - 2 do
  Data[i]:= Data[i + 1];

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
procedure TBillboards.RemoveAll();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
end.


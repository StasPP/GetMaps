unit NetBufs;
//---------------------------------------------------------------------------
// Network Cacheable Buffers                                      Version 1.0
// (c) 2005  Yuriy Kotsarenko (lifepower@mail333.com)   Modified: 29-Jan-2005
//---------------------------------------------------------------------------
//   Description:
//
// This unit implements TNetBufs class which manages a list of memory buffers
// that can be used to store network packets. A number of such buffers is
// already allocated and kept in memory to prevent continuous memory
// reallocation and thus reducing memory fragmentation. Also, this class
// allocates more buffers than currently requested to reduce the number of
// subsequent allocations.
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
 Types, Classes, SysUtils, Math;

//---------------------------------------------------------------------------
type
 PNetBuffer = ^TNetBuffer;
 TNetBuffer = record
  Host  : string[31];
  Port  : Integer;
  MsgID : Integer;
  sTime : TDateTime;
  sCount: Integer;
  Packet: Longword;
 end; 

//---------------------------------------------------------------------------
 TNetBufs = class
 private
  Data: array of PNetBuffer;
  DataCount: Integer;
  FBufferSize: Integer;

  procedure Precache(Req: Integer);
  procedure SetBufferSize(const Value: Integer);
  function GetItem(Num: Integer): PNetBuffer;
 public
  property BufferSize: Integer read FBufferSize write SetBufferSize;
  property Items[Num: Integer]: PNetBuffer read GetItem; default;
  property Count: Integer read DataCount;

  function Add(): Integer;
  procedure Remove(Num: Integer);
  procedure Clear();

  function FindByID(MsgID: Integer): Integer;
  procedure RemoveID(MsgID: Integer);

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
const
 CacheSize = 32;

//---------------------------------------------------------------------------
constructor TNetBufs.Create();
begin
 inherited;

 FBufferSize:= 512;
 DataCount:= 0;
 SetLength(Data, 0);
 Precache(1);
end;

//---------------------------------------------------------------------------
destructor TNetBufs.Destroy();
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  begin
   FreeMem(Data[i]);
   Data[i]:= nil;
  end;
 SetLength(Data, 0);
 DataCount:= 0;

 inherited;
end;

//---------------------------------------------------------------------------
procedure TNetBufs.Precache(Req: Integer);
var
 Amount, Cached, i: Integer;
begin
 Amount:= Ceil(Req / CacheSize) * CacheSize;
 Cached:= Length(Data);

 if (Cached < Amount) then
  begin
   SetLength(Data, Amount);

   for i:= Cached to Amount - 1 do
    Data[i]:= AllocMem(FBufferSize);
  end;
end;

//---------------------------------------------------------------------------
procedure TNetBufs.SetBufferSize(const Value: Integer);
var
 i: Integer;
begin
 FBufferSize:= Value;
 if (FBufferSize < 512) then FBufferSize:= 512;

 for i:= 0 to Length(Data) - 1 do
  ReallocMem(Data[i], FBufferSize);
end;

//---------------------------------------------------------------------------
function TNetBufs.GetItem(Num: Integer): PNetBuffer;
begin
 if (Num < 0)or(Num >= DataCount) then
  begin
   Result:= nil;
   Exit;
  end;

 Result:= Data[Num];  
end;

//---------------------------------------------------------------------------
procedure TNetBufs.Clear();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
function TNetBufs.Add(): Integer;
var
 Index: Integer;
begin
 Precache(DataCount + 1);

 Index:= DataCount;
 Inc(DataCount);

 Result:= Index;
end;

//---------------------------------------------------------------------------
procedure TNetBufs.Remove(Num: Integer);
var
 i: Integer;
begin
 if (Num < 0)or(Num >= DataCount) then Exit;

 for i:= Num to DataCount - 2 do
  Move(Data[i + 1]^, Data[i]^, FBufferSize);

 Dec(DataCount); 
end;

//---------------------------------------------------------------------------
function TNetBufs.FindByID(MsgID: Integer): Integer;
var
 i: Integer;
begin
 for i:= 0 to DataCount - 1 do
  if (Data[i].MsgID = MsgID) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= -1;   
end;

//---------------------------------------------------------------------------
procedure TNetBufs.RemoveID(MsgID: Integer);
var
 Index: Integer;
begin
 Index:= FindByID(MsgID);
 if (Index <> -1) then Remove(Index);
end;

//---------------------------------------------------------------------------
end.

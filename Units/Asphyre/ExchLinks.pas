unit ExchLinks;
//---------------------------------------------------------------------------
// Link Repository for NetExchange                                Version 1.0
// Copyright (c) 2005 - 2006  Afterwarp Interactive
// (http://www.afterwarp.net)
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
 Windows, Types, Classes, SysUtils, ExchTypes;

//---------------------------------------------------------------------------
type
 TReceiveStatus = (rsNone, rsPartial, rsComplete);

//---------------------------------------------------------------------------
 PNetLink = ^TNetLink;
 TNetLink = record
  // link information
  LinkHost  : Cardinal;
  LinkPort  : Integer;
  MessageID : Cardinal;
  LinkStatus: TLinkStatus;
  LastAction: Cardinal;

  // input information
//  InPacket: TExchPacket;
  InBuffer: packed array[0..MaxDataSize - 1] of Byte;
  LastIn  : Cardinal;

  // output information
  OutPacket: TExchPacket;
  OutBuffer: packed array[0..MaxDataSize - 1] of Byte;
  LastOut  : Cardinal;
 end;

//---------------------------------------------------------------------------
 TNetLinks = class
 private
  Data: array of TNetLink;

  function GetCount(): Integer;
  function GetLink(Num: Integer): PNetLink;
 public
  property Count: Integer read GetCount;
  property Link[Num: Integer]: PNetLink read GetLink; default;

  function Find(Host: Cardinal; Port: Integer): Integer;
  procedure Remove(Num: Integer);
  procedure RemoveAll();

  function OpenLink(Host: Cardinal; Port: Integer): Integer;
  procedure CloseLink(Host: Cardinal; Port: Integer);

  procedure LinkPutFirst(Num: Integer; Source: Pointer; Size: Integer);
  function LinkPutNext(Num: Integer): Boolean;
  function LinkGet(Num: Integer; InPacket: PExchPacket): TReceiveStatus;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
function TNetLinks.GetCount(): Integer;
begin
 Result:= Length(Data);
end;

//---------------------------------------------------------------------------
function TNetLinks.GetLink(Num: Integer): PNetLink;
begin
 if (Num >= 0)and(Num < Length(Data)) then
  Result:= @Data[Num] else Result:= nil;
end;

//---------------------------------------------------------------------------
function TNetLinks.Find(Host: Cardinal; Port: Integer): Integer;
var
 i: Integer;
begin
 Result:= -1;
 for i:= 0 to Length(Data) - 1 do
  if (Host = Data[i].LinkHost)and(Port = Data[i].LinkPort) then
   begin
    Result:= i;
    Break;
   end;
end;

//---------------------------------------------------------------------------
procedure TNetLinks.Remove(Num: Integer);
var
 i: Integer;
begin
 if (Num < 0)or(Num >= Length(Data)) then Exit;

 for i:= Num to Length(Data) - 2 do
  Data[i]:= Data[i + 1];

 SetLength(Data, Length(Data) - 1);
end;

//---------------------------------------------------------------------------
procedure TNetLinks.RemoveAll();
begin
 SetLength(Data, 0);
end;

//---------------------------------------------------------------------------
function TNetLinks.OpenLink(Host: Cardinal; Port: Integer): Integer;
var
 Index: Integer;
 Ticks: Longword;
begin
 Index:= Find(Host, Port);
 if (Index = -1) then
  begin
   Index:= Length(Data);
   SetLength(Data, Index + 1);
  end;

 FillChar(Data[Index], SizeOf(TNetLink), 0);
 Data[Index].LinkHost:= Host;
 Data[Index].LinkPort:= Port;

 Ticks:= GetTickCount;
 Data[Index].LastAction:= Ticks;
 Data[Index].LastIn := Ticks;
 Data[Index].LastOut:= Ticks;

// Data[Index].InPacket.BodyOfs := -1; // no input available
 Data[Index].OutPacket.BodyOfs:= -1; // no output available

 Result:= Index;
end;

//---------------------------------------------------------------------------
procedure TNetLinks.CloseLink(Host: Cardinal; Port: Integer);
begin
 Remove(Find(Host, Port));
end;

//---------------------------------------------------------------------------
procedure TNetLinks.LinkPutFirst(Num: Integer; Source: Pointer; Size: Integer);
var
 Link: PNetLink;
begin
 Link:= @Data[Num];

 if (Size > MaxDataSize)or((Size > 0)and(Source = nil))or(Size < 0) then
  begin
   Link.LinkStatus:= lsBroken;
   Exit;
  end;

 if (Size > 0) then Move(Source^, Link.OutBuffer, Size);

 Link.OutPacket.PhysSize:= Size;
 Link.OutPacket.BodyOfs := 0;

 if (Size > 0)and(Size <= BufferSize) then
  begin
   Link.OutPacket.BodySize:= Size;
   Move(Link.OutBuffer, Link.OutPacket.MsgBody, Size);
  end;
 if (Size > BufferSize) then
  begin
   Link.OutPacket.BodySize:= BufferSize;
   Move(Link.OutBuffer, Link.OutPacket.MsgBody, BufferSize);
  end;
end;

//---------------------------------------------------------------------------
function TNetLinks.LinkPutNext(Num: Integer): Boolean;
var
 Link: PNetLink;
 MemIn: Pointer;
begin
 Link:= @Data[Num];

 Result:= (Link.OutPacket.BodyOfs = -1);
 if (not Result) then Exit;

 with Link^ do
  begin
   Inc(OutPacket.BodyOfs, OutPacket.BodySize);

   Result:= (OutPacket.BodyOfs < OutPacket.PhysSize);
   if (not Result) then
    begin
     OutPacket.BodyOfs:= -1;
     Exit;
    end;

   OutPacket.BodySize:= BufferSize;
   if (OutPacket.BodySize + OutPacket.BodyOfs > OutPacket.PhysSize) then
    OutPacket.BodySize:= OutPacket.PhysSize - OutPacket.BodyOfs;

   Move(OutBuffer[OutPacket.BodyOfs], OutPacket.MsgBody, OutPacket.BodySize);
  end;
end;

//---------------------------------------------------------------------------
function TNetLinks.LinkGet(Num: Integer; InPacket: PExchPacket): TReceiveStatus;
var
 Link: PNetLink;
begin
 Link:= @Data[Num];

 if (InPacket.BodyOfs = -1)or(InPacket.BodySize < 1) then
  begin
   Result:= rsNone;
   Exit;
  end;

 with Link^ do
  begin
   Move(InPacket.MsgBody, InBuffer[InPacket.BodyOfs], InPacket.BodySize);
   Inc(InPacket.BodyOfs, InPacket.BodySize);
   if (InPacket.BodyOfs >= InPacket.BodySize) then
    begin
     InPacket.BodyOfs:= -1;
     Result:= rsComplete;
    end else Result:= rsPartial;
  end;
end;

//---------------------------------------------------------------------------
{procedure TNetLinks.RecvData(Num: Integer; MemAddr: Pointer; Offset,
 Amount, Size: Integer);
var
 Link: PNetLink;
 Dest: Pointer;
begin
 Link:= @Data[Num];

 if (Link.InOffset < Link.InSize) then
  begin
   Dest:= Pointer(Integer(Link.InMemAddr) + Offset);
   Move(MemAddr^, Dest^, Amount);
   Link.InOffset:= Offset + Amount;
  end else
  begin
   if (Link.InBufSize < Size) then ReallocMem(Link.InMemAddr, Size);

   Link.InSize:= Size;
   Move(MemAddr^, Link.InMemAddr^, Amount);
   Link.InOffset:= Offset + Amount;
  end;
end;}

//---------------------------------------------------------------------------
end.


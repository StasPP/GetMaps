unit NetExch;
//---------------------------------------------------------------------------
// NetExch.pas                                                    Version 1.0
// Asynchronous Internet Communication                  Modified: 15-Sep-2005
// Copyright (c) 2005  Afterwarp Interactive (www.afterwarp.com)
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
 Windows, Types, Classes, SysUtils, AsphyreDef, ExtCtrls, AsphyreNet,
 ExchTypes, ExchLinks;

//---------------------------------------------------------------------------
type
 TAcceptEvent = procedure(Sender: TObject; Address: Cardinal; Port: Integer;
  var Accept: Boolean) of object;

 TReceiveEvent = procedure(Sender: TObject; Address: Cardinal; Port: Integer;
  Data: Pointer; Size: Integer) of object;

 TSendEvent = procedure(Sender: TObject; Address: Cardinal; Port: Integer;
  var Data: Pointer; var Size: Integer) of object;

 TTimeoutEvent = procedure(Sender: TObject; Address: Cardinal;
  Port: Integer) of object;

//---------------------------------------------------------------------------
 TNetExchange = class(TAsphyreUDP)
 private
  FFragmentSize: Integer;
  FSendDelay: Cardinal;
  FIdleDelay: Cardinal;
  FWaitDelay: Cardinal;
  FSelfTimer: Boolean;
  FTimeout  : Cardinal;

  FOnSend: TSendEvent;
  FOnAccept : TAcceptEvent;
  FOnReceive: TReceiveEvent;
  FOnTimeout: TTimeoutEvent;

  FLinks: TNetLinks;

  procedure SendMsg(LinkNum: Integer);
 protected
  procedure Receive(Data: Pointer; Size: Integer; Addr: Longword;
   Port: Integer); override;
 public
  property Links: TNetLinks read FLinks;

  constructor Create(AOwner: TComponent); override;
  destructor Destroy(); override;

  // This routine begins the communication to the remote machine.
  procedure Hail(Address: Longword; Port: Integer);

  // This routine updates the message queque
  procedure Update();

  procedure Links2List(List: TStrings); 
 published
  // The minimum amount of milliseconds between consecutive OnSend events.
  property SendDelay: Cardinal read FSendDelay write FSendDelay;

  // The minimum amount of milliseconds to wait for empty message.
  property IdleDelay: Cardinal read FIdleDelay write FIdleDelay;

  // The amount of milliseconds to wait before re-transmitting the message.
  property WaitDelay: Cardinal read FWaitDelay write FWaitDelay;

  // Time in milliseconds when the link is considered dead. If no answer
  // is received within this time, the link will be closed and OnTimeout
  // event will occur.
  property Timeout: Cardinal read FTimeout write FTimeout;

  // This event occurs when a new connection has just been made. You can
  // set 'Accept' to FALSE to ignore the message and avoid creating this
  // connection.
  // Notice that when Accept is FALSE, this event may occur multiple times
  // before the client gives up.
  property OnAccept: TAcceptEvent read FOnAccept write FOnAccept;

  property OnReceive: TReceiveEvent read FOnReceive write FOnReceive;
  property OnSend: TSendEvent read FOnSend write FOnSend;

  // This event occurs when no answer was received during 'Timeout'
  // milliseconds and is being closed.
  property OnTimeout: TTimeoutEvent read FOnTimeout write FOnTimeout;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
function TimeDistance(Time1, Time2: Cardinal): Cardinal;
begin
 Result:= Time2 - Time1;
 if (High(Cardinal) - Result < Result) then
  Result:= High(Cardinal) - Result;
end;

//---------------------------------------------------------------------------
constructor TNetExchange.Create(AOwner: TComponent);
begin
 inherited;

 FFragmentSize:= 1024;
 FSendDelay:= 200;
 FSelfTimer:= True;

 FIdleDelay:= 100;
 FTimeout  := 4000;
 FWaitDelay:= 1000;

 FLinks:= TNetLinks.Create();
end;

//---------------------------------------------------------------------------
destructor TNetExchange.Destroy();
begin
 FLinks.Free();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TNetExchange.Hail(Address: Longword; Port: Integer);
var
 Data : Pointer;
 Size : Integer;
 Index: Integer;
begin
 Data:= nil;
 Size:= 0;

 if (Assigned(FOnSend)) then FOnSend(Self, Address, Port, Data, Size);
 if (Data = nil)or(Size = 0) then
  begin
   Size:= 0;
   Data:= nil;
  end;

 Index:= Links.OpenLink(Address, Port);
 Links.LinkPutFirst(Index, Data, Size);

 SendMsg(Index);
end;

//---------------------------------------------------------------------------
procedure TNetExchange.SendMsg(LinkNum: Integer);
var
 Link: PNetLink;
begin
 Link:= Links[LinkNum];
 Link.OutPacket.MessageID:= Link.MessageID;

 Send(Link.LinkHost, Link.LinkPort, @Link.OutPacket, HeaderSize +
  Link.OutPacket.BodySize);
  
 Link.LastOut:= GetTickCount;
 Link.LinkStatus:= lsSentWaiting;
end;

//---------------------------------------------------------------------------
procedure TNetExchange.Receive(Data: Pointer; Size: Integer;
 Addr: Longword; Port: Integer);
var
 Index: Integer;
 Link : PNetLink;
 Ticks: Cardinal;
 InMsg: PExchPacket;
 RecvS: TReceiveStatus;
 OutData: Pointer;
 OutSize: Integer;
 Accept : Boolean;
begin
 Ticks:= GetTickCount;
 InMsg:= Data;

 // (1) Find the incoming link.
 Index:= Links.Find(Addr, Port);
 Link := Links[Index];

 // (2) Validate message and link status
 if (Index = -1)and(InMsg.MessageID <> 0) then Exit;
 if (Link <> nil)and(Link.MessageID >= InMsg.MessageID) then Exit;
 if (Size <> HeaderSize + InMsg.BodySize) then Exit;

 // (3) Create a new link, if this is the first packet
 if (Index = -1) then
  begin
   Accept:= True;
   if (Assigned(FOnAccept)) then FOnAccept(Self, Addr, Port, Accept);
   if (not Accept) then Exit;

   Index:= Links.OpenLink(Addr, Port);
   Link := Links[Index];
  end;

 // (4) Update the link
 Link.MessageID:= InMsg.MessageID + 1;
 Link.LastIn:= Ticks;

 // (5) Check if we need to keep sending fragmented message
 if (Links.LinkPutNext(Index)) then
  begin
   // Keep sending the fragmented message
   SendMsg(Index);
   Exit;
  end;

 // (6) Receive incoming message
 RecvS:= Links.LinkGet(Index, InMsg);
 if (RecvS = rsPartial) then 
  begin
   // Answer with empty message, ask for next fragment.
   Links.LinkPutFirst(Index, nil, 0);
   SendMsg(Index);
   Exit;
  end;

 // (7) Trigger receive event right away.
 if (RecvS = rsComplete)and(Assigned(FOnReceive)) then
  FOnReceive(Self, Addr, Port, @Link.InBuffer, InMsg.PhysSize);

 // (8) What to do next?
 if (FSendDelay < 1)or(TimeDistance(Ticks, Link.LastAction) >= FSendDelay) then
  begin
   Link.LastAction:= Ticks;

   OutData:= nil;
   OutSize:= 0;

   // Request for send now!
   if (Assigned(FOnSend)) then
    begin
     FOnSend(Self, Addr, Port, OutData, OutSize);

     if (OutData = nil)or(OutSize < 1) then
      begin
       OutData:= nil;
       OutSize:= 0;
      end;
    end;

   Links.LinkPutFirst(Index, OutData, OutSize);
   if (OutSize > 0) then SendMsg(Index) else Link.LinkStatus:= lsEmptySleep;

   Exit;
  end;

 // (9) We can't send data so quickly
 Link.LinkStatus:= lsReadyHold;
end;

//---------------------------------------------------------------------------
procedure TNetExchange.Update();
var
 i: Integer;
 Link: PNetLink;
 Ticks: Cardinal;
 OutData: Pointer;
 OutSize: Integer;
begin
 Ticks:= GetTickCount;

 for i:= Links.Count - 1 downto 0 do
  begin
   Link:= Links[i];
   if (Link.LinkStatus = lsEmptySleep)and(TimeDistance(Ticks,
    Link.LastAction) >= FIdleDelay) then
    begin
     SendMsg(i);
     Continue;
    end;
   if (Link.LinkStatus = lsSentWaiting)and(TimeDistance(Ticks,
    Link.LastOut) >= FWaitDelay) then
    begin
     SendMsg(i);
     Continue;
    end;
   if (Link.LinkStatus = lsReadyHold)and(TimeDistance(Ticks,
    Link.LastAction) >= FSendDelay) then
    begin
     Link.LastAction:= Ticks;

     OutData:= nil;
     OutSize:= 0;

     // Request for send now!
     if (Assigned(FOnSend)) then
      FOnSend(Self, Link.LinkHost, Link.LinkPort, OutData, OutSize);

     Links.LinkPutFirst(i, OutData, OutSize);
     if (OutData = nil)or(OutSize < 1) then
      begin
       OutData:= nil;
       OutSize:= 0;
      end;

     if (OutSize > 0) then SendMsg(i) else Link.LinkStatus:= lsEmptySleep;
    end;
   if (TimeDistance(Ticks, Link.LastIn) >= FTimeout) then
    begin
     if (Assigned(FOnTimeout)) then
      FOnTimeout(Self, Link.LinkHost, Link.LinkPort);

     Links.Remove(i);
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TNetExchange.Links2List(List: TStrings);
var
 i: Integer;
 Link: PNetLink;
 st: string;
begin
 List.Clear();
 for i:= 0 to Links.Count - 1 do
  begin
   Link:= Links[i];
   st:= '[' + AddrToStr(Link.LinkHost) + ': ' + IntToStr(Link.LinkPort) +
    '] id: ' + IntToStr(Link.MessageID);

   if (Link.OutPacket.BodyOfs + Link.OutPacket.BodySize < Link.OutPacket.PhysSize) then
    st:= st + ' <<- ' + IntToStr((Link.OutPacket.BodyOfs * 100) div Link.OutPacket.PhysSize) + '%';

   List.Add(st);
  end;
end;

//---------------------------------------------------------------------------
end.

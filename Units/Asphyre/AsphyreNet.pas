unit AsphyreNet;
//---------------------------------------------------------------------------
// Asphyre UDP protocol implementation                            Version 1.0
// Copyright (c) 2005  Afterwarp Interactive (http://www.afterwarp.com)
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
 Windows, Types, Classes, SysUtils, Messages, Forms, ExtCtrls, Math, WinSock,
 AsphyreDef, AsphyreData, PackedNums, NetBufs, NetLinks;

//---------------------------------------------------------------------------
const
 WM_SOCKET = WM_USER + 427;

//---------------------------------------------------------------------------
type
 TWSEvent = record
  Msg     : Longword;
  hSocket : THandle;
  sEvent  : Word;
  sError  : Word;
  Reserved: Longword;
 end;

//---------------------------------------------------------------------------
 TAsphyreUDP = class(TComponent)
 private
  hWindow : THandle;
  wSession: TWSAdata;
  hSocket : TSocket;

  FInitialized: Boolean;
  FLocalPort  : Integer;

  StringBuf: array[0..511] of Char; // null-terminated string buffer
  AuxBuf   : Pointer;
  
  FBytesReceived: Integer;
  FBytesSent: Integer;

  procedure SetLocalPort(const Value: Integer);
  function InitSock(): Boolean;
  procedure DoneSock();
  procedure WindowEvent(var Msg: TMessage);
  procedure SocketEvent(var Msg: TWSEvent); message WM_SOCKET;
  function GetLocalIP(): string;
  procedure SockReceive();
 protected
  function Send(Address: Longword; Port: Integer; Data: Pointer;
   Size: Integer): Boolean;
  procedure Receive(Data: Pointer; Size: Integer; Addr: Longword;
   Port: Integer); virtual;
  function DoInitialize(): Boolean; virtual;
  procedure DoFinalize(); virtual;
 public
  property Initialized: Boolean read FInitialized;
  property LocalIP: string read GetLocalIP;

  property BytesReceived: Integer read FBytesReceived;
  property BytesSent: Integer read FBytesSent;

  constructor Create(AOwner: TComponent); override;
  destructor Destroy(); override;

  function Initialize(): Boolean;
  procedure Finalize();

  function AddrToStr(Address: Longword): string;
  function Str2Addr(const Address: string): Longword;

  // This function resolves the host of the given IP address.
  // It may take a while to execute.
  function ResolveAddr(Address: Longword): string;
 published
  property LocalPort: Integer read FLocalPort write SetLocalPort;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
const
 WSAVerRequisite = $101;
 BufferSize      = 8192;

//---------------------------------------------------------------------------
constructor TAsphyreUDP.Create(AOwner: TComponent);
begin
 inherited;

 FInitialized:= False;
 FLocalPort  := 8876;
 hSocket     := INVALID_SOCKET;
 // create a window handle that will receive network events
 hWindow     := Classes.AllocateHWND(WindowEvent);
end;

//---------------------------------------------------------------------------
destructor TAsphyreUDP.Destroy();
begin
 if (FInitialized) then Finalize();
 Classes.DeallocateHWnd(hWindow);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreUDP.SetLocalPort(const Value: Integer);
begin
 if (not FInitialized) then
  begin
   FLocalPort:= Value;
   if (FLocalPort < 0) then FLocalPort:= 0;
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreUDP.InitSock(): Boolean;
var
 SockAddr: TSockAddrIn;
 dwOpt   : Longword;
begin
 // (1) Create WinSock version 1.01.
 Result:= (WSAStartup(WSAVerRequisite, wSession) = 0);
 if (not Result) then Exit;

 // (2) Create datagram socket.
 hSocket:= Socket(PF_INET, SOCK_DGRAM, 0);
 Result := (hSocket <> INVALID_SOCKET);
 if (not Result) then
  begin
   WSACleanup();
   Exit;
  end;

 // (3) Allow broadcasting.
 dwOpt:= Longword(True);
 SetSockOpt(hSocket, SOL_SOCKET, SO_BROADCAST, @dwOpt, SizeOf(dwOpt));

 // (4) Bind socket to the specified port.
 FillChar(SockAddr, SizeOf(TSockAddrIn), 0);
 SockAddr.sin_port  := FLocalPort;
 SockAddr.sin_family:= AF_INET;
 Result:= (Bind(hSocket, SockAddr, SizeOf(SockAddr)) = 0);
 if (not Result) then
  begin
   CloseSocket(hSocket);
   WSACleanup();
   Exit;
  end;

 // (5) Retreive local port.
 dwOpt:= SizeOf(SockAddr);
 GetSockName(hSocket, SockAddr, Integer(dwOpt));
 FLocalPort:= SockAddr.sin_port;

 // (6) Configure async mode.
 Result:= (WSAAsyncSelect(hSocket, hWindow, WM_SOCKET, FD_READ or FD_CLOSE) = 0);
 if (not Result) then
  begin
   CloseSocket(hSocket);
   WSACleanup();
   Exit;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreUDP.DoneSock();
begin
 if (hSocket <> INVALID_SOCKET) then CloseSocket(hSocket);
 WSACleanup();
end;

//---------------------------------------------------------------------------
function TAsphyreUDP.DoInitialize(): Boolean;
begin
 Result:= True;
end;

//---------------------------------------------------------------------------
procedure TAsphyreUDP.DoFinalize();
begin
 // no code
end;

//---------------------------------------------------------------------------
function TAsphyreUDP.Initialize(): Boolean;
begin
 // (1) If previously initialized - finalize first.
 if (FInitialized) then Finalize();

 // (2) Create UDP socket.
 Result:= InitSock();
 if (not Result) then Exit;

 // (3) Initialize derived class.
 Result:= DoInitialize();
 if (not Result) then Exit;

 // (3) Allocate message buffer.
 AuxBuf:= AllocMem(BufferSize);

 // (4) Initialize variables.
 FBytesSent    := 0;
 FBytesReceived:= 0;
 FInitialized  := True;
end;

//---------------------------------------------------------------------------
procedure TAsphyreUDP.Finalize();
begin
 if (FInitialized) then
  begin
   DoFinalize();
   DoneSock();

   if (AuxBuf <> nil) then
    begin
     FreeMem(AuxBuf);
     AuxBuf:= nil;
    end;

   FInitialized:= False;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreUDP.WindowEvent(var Msg: TMessage);
begin
 if (Msg.Msg <> WM_SOCKET) then Exit;

 try
  Dispatch(Msg);
 except
  Application.HandleException(Self);
 end;
end;

//---------------------------------------------------------------------------
function TAsphyreUDP.Str2Addr(const Address: string): Longword;
var
 Addr: Longword;
 HostEnt: PHostEnt;
begin
 StrPCopy(@StringBuf, Address);

 // check if the host is an IP address
 Addr:= inet_addr(StringBuf);
 if (Addr = Longword(INADDR_NONE)) then
  begin // not an IP, assume it's a DNS name
   HostEnt:= GetHostByName(StringBuf);
   if (HostEnt <> nil) then
    begin
     Result:= PLongword(HostEnt.h_addr_list^)^;
    end else Result:= Longword(INADDR_NONE);
  end else Result:= Addr;
end;

//---------------------------------------------------------------------------
function TAsphyreUDP.AddrToStr(Address: Longword): string;
var
 s : ShortString;
 pb: PByte;
begin
 pb:= @Address;
 s:= IntToStr(pb^) + '.';
 Inc(pb);
 s:= s + IntToStr(pb^) + '.';
 Inc(pb);
 s:= s + IntToStr(pb^) + '.';
 Inc(pb);
 s:= s + IntToStr(pb^);

 Result:= s;
end;

//---------------------------------------------------------------------------
function TAsphyreUDP.ResolveAddr(Address: Longword): string;
var
 HostEnt: PHostEnt;
begin
 HostEnt:= GetHostByAddr(@Address, 4, AF_INET);
 if (HostEnt <> nil) then Result:= HostEnt.h_name
  else Result:= AddrToStr(Longword(INADDR_NONE));
end;

//---------------------------------------------------------------------------
procedure TAsphyreUDP.SocketEvent(var Msg: TWSEvent);
begin
 if (Msg.sError <> 0) then Exit;

 case Msg.sEvent of
  FD_READ : SockReceive();
  FD_CLOSE: if (FInitialized) then Finalize();
 end;
end;

//---------------------------------------------------------------------------
function TAsphyreUDP.GetLocalIP(): string;
type
 PInAddrs = ^TInAddrs;
 TInAddrs = array[WORD] of PInAddr;
var
 HostEnt: PHostEnt;
 Index  : Integer;
 InAddp : PInAddrs;
begin
 Result:= '127.0.0.1';

 GetHostName(StringBuf, SizeOf(StringBuf));
 HostEnt:= GetHostByName(StringBuf);
 if (HostEnt = nil) then Exit;

 Index:= 0;
 InAddp:= PInAddrs(HostEnt.h_addr_list);
 while (InAddp[Index] <> nil) do
  begin
   Result:= AddrToStr(InAddp[Index].S_addr);
   Inc(Index);
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreUDP.Receive(Data: Pointer; Size: Integer; Addr: Longword;
 Port: Integer);
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TAsphyreUDP.SockReceive();
var
 SockAddr: TSockAddrIn;
 InBytes : Integer;
 AddrLen : Integer;
begin
 AddrLen:= SizeOf(TSockAddrIn);
 FillChar(SockAddr, AddrLen, 0);
 SockAddr.sin_family:= AF_INET;
 SockAddr.sin_port  := FLocalPort;

 // read the entire buffer
 InBytes:= RecvFrom(hSocket, AuxBuf^, BufferSize, 0, SockAddr, AddrLen);
 if (InBytes < 1) then Exit;

 Inc(FBytesReceived, InBytes);

 // call receive method
 Receive(AuxBuf, InBytes, SockAddr.sin_addr.S_addr, SockAddr.sin_port);
end;

//---------------------------------------------------------------------------
function TAsphyreUDP.Send(Address: Longword; Port: Integer; Data: Pointer;
 Size: Integer): Boolean;
var
 SockAddr: TSockAddrIn;
begin
 // prepare datagram info
 FillChar(SockAddr, SizeOf(TSockAddrIn), 0);
 SockAddr.sin_family:= AF_INET;
 SockAddr.sin_addr.S_addr:= Address;
 SockAddr.sin_port:= Port;

 // send datagram
 Result:= (SendTo(hSocket, Data^, Size, 0, SockAddr, SizeOf(TSockAddrIn)) >= 0);
 if (Result) then
  Inc(FBytesSent, Size);
end;

//---------------------------------------------------------------------------
end.

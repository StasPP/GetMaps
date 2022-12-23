unit ExchTypes;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, AsphyreDef;

//---------------------------------------------------------------------------
const
 BufferSize  = 4096;
 MaxDataSize = 1048576;

//---------------------------------------------------------------------------
type
 PExchPacket = ^TExchPacket;
 TExchPacket = packed record
  MessageID: Longword; // unique ID of the message
  MiscFlags: Byte;     // message flags

  PhysSize : LongInt;  // physical data size (compressed?)
  BodySize : Word;     // physical size of transmitted part
  BodyOfs  : LongInt;  // the offset of transmitted part

  MsgBody  : packed array[0..BufferSize - 1] of Byte;
 end;

//---------------------------------------------------------------------------
 TLinkStatus = (
  lsBroken,      // the link is broken/invalid (due to error)
  lsEmptySleep,  // holding empty message and waiting minimal "empty" time
  lsReadyHold,   // not holding and waiting minimal time
  lsSentWaiting  // sent message, waiting for answer
 );

//---------------------------------------------------------------------------
const
 HeaderSize = SizeOf(TExchPacket) - BufferSize;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
end.

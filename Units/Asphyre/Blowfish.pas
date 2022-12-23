unit Blowfish;
//---------------------------------------------------------------------------
// Blowfish.pas                                         Modified: 15-Oct-2005
// 64-bit Block Standard Encryption (up to 448-bit key)           Version 1.0
//---------------------------------------------------------------------------
// Based on original code by Dave Barton, 2001
// Adapted and modified by Afterwarp Interactive, October 2005
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
 SysUtils;

//---------------------------------------------------------------------------
// BlowfishEncode()
//
// Encrypts the specified data block. KeySize must be between 1 and 56.
//---------------------------------------------------------------------------
procedure BlowfishEncode(MemAddr: Pointer; Count: Integer; Key: Pointer;
 KeySize: Integer; Subkey0, Subkey1: Longword);

//---------------------------------------------------------------------------
// BlowfishDecode()
//
// Decrypts the specified data block. KeySize must be between 1 and 56.
//---------------------------------------------------------------------------
procedure BlowfishDecode(MemAddr: Pointer; Count: Integer; Key: Pointer;
 KeySize: Integer; Subkey0, Subkey1: Longword);

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
{$i include\Blowfish.inc}
{$R-}

//---------------------------------------------------------------------------
type
 TBlowfishData = record
  InitBlock: array[0..7] of Byte;
  LastBlock: array[0..7] of Byte;
  SBoxM: array[0..3,0..255] of Longword;
  PBoxM: array[0..17] of Longword;
 end;

//---------------------------------------------------------------------------
 TBlowfishIV = array[0..1] of Longword;

//---------------------------------------------------------------------------
function BF_F(Data: TBlowfishData; xL: Longword): Longword;
{$IFDEF VER170}inline;{$ENDIF}
begin
 Result:= (((Data.SBoxM[0, (xL shr 24) and $FF] + Data.SBoxM[1, (xL shr 16) and
  $FF]) xor Data.SBoxM[2, (xL shr 8) and $FF]) + Data.SBoxM[3, xL and $FF]);
end;

//---------------------------------------------------------------------------
procedure BFDoRound(Data: TBlowfishData; var xL, xR: Longword; RNum: Integer);
{$IFDEF VER170}inline;{$ENDIF}
begin
 xL:= xL xor BF_F(Data,xR) xor Data.PBoxM[RNum];
end;

//---------------------------------------------------------------------------
procedure XorBlock8(Source0, Source1, Dest: PByteArray);
{$IFDEF VER170}inline;{$ENDIF}
var
 i: Integer;
begin
 for i:= 0 to 7 do
  Dest[i]:= Source0[i] xor Source1[i];
end;

//---------------------------------------------------------------------------
procedure BlowfishBurn(var Data: TBlowfishData);
begin
 FillChar(Data, Sizeof(Data), 0);
end;

//---------------------------------------------------------------------------
procedure BlowfishEncryptECB(var Data: TBlowfishData; InData, OutData: Pointer);
var
 xL, xR: Longword;
begin
 Move(InData^, xL, 4);
 Move(Pointer(Integer(InData) + 4)^, xR, 4);
 
 xL:= (xL shr 24) or ((xL shr 8) and $FF00) or ((xL shl 8) and $FF0000) or
  (xL shl 24);
 xR:= (xR shr 24) or ((xR shr 8) and $FF00) or ((xR shl 8) and $FF0000) or
  (xR shl 24);
 xL:= xL xor Data.PBoxM[0];
 
 BFDoRound(Data, xR, xL, 1);
 BFDoRound(Data, xL, xR, 2);
 BFDoRound(Data, xR, xL, 3);
 BFDoRound(Data, xL, xR, 4);
 BFDoRound(Data, xR, xL, 5);
 BFDoRound(Data, xL, xR, 6);
 BFDoRound(Data, xR, xL, 7);
 BFDoRound(Data, xL, xR, 8);
 BFDoRound(Data, xR, xL, 9);
 BFDoRound(Data, xL, xR, 10);
 BFDoRound(Data, xR, xL, 11);
 BFDoRound(Data, xL, xR, 12);
 BFDoRound(Data, xR, xL, 13);
 BFDoRound(Data, xL, xR, 14);
 BFDoRound(Data, xR, xL, 15);
 BFDoRound(Data, xL, xR, 16);

 xR:= xR xor Data.PBoxM[17];
 xL:= (xL shr 24) or ((xL shr 8) and $FF00) or ((xL shl 8) and $FF0000) or
  (xL shl 24);
 xR:= (xR shr 24) or ((xR shr 8) and $FF00) or ((xR shl 8) and $FF0000) or
  (xR shl 24);

 Move(xR, OutData^, 4);
 Move(xL, Pointer(Integer(OutData) + 4)^, 4);
end;

//---------------------------------------------------------------------------
procedure BlowfishDecryptECB(var Data: TBlowfishData; InData, OutData: Pointer);
var
 xL, xR: Longword;
begin
 Move(InData^, xL, 4);
 Move(Pointer(Integer(InData) + 4)^, xR, 4);

 xL:= (xL shr 24) or ((xL shr 8) and $FF00) or ((xL shl 8) and $FF0000) or
  (xL shl 24);
 xR:= (xR shr 24) or ((xR shr 8) and $FF00) or ((xR shl 8) and $FF0000) or
  (xR shl 24);
 xL:= xL xor Data.PBoxM[17];

 BFDoRound(Data, xR, xL, 16);
 BFDoRound(Data, xL, xR, 15);
 BFDoRound(Data, xR, xL, 14);
 BFDoRound(Data, xL, xR, 13);
 BFDoRound(Data, xR, xL, 12);
 BFDoRound(Data, xL, xR, 11);
 BFDoRound(Data, xR, xL, 10);
 BFDoRound(Data, xL, xR, 9);
 BFDoRound(Data, xR, xL, 8);
 BFDoRound(Data, xL, xR, 7);
 BFDoRound(Data, xR, xL, 6);
 BFDoRound(Data, xL, xR, 5);
 BFDoRound(Data, xR, xL, 4);
 BFDoRound(Data, xL, xR, 3);
 BFDoRound(Data, xR, xL, 2);
 BFDoRound(Data, xL, xR, 1);

 xR:= xR xor Data.PBoxM[0];
 xL:= (xL shr 24) or ((xL shr 8) and $FF00) or ((xL shl 8) and $FF0000) or
  (xL shl 24);
 xR:= (xR shr 24) or ((xR shr 8) and $FF00) or ((xR shl 8) and $FF0000) or
  (xR shl 24);

 Move(xR, OutData^, 4);
 Move(xL, Pointer(Integer(OutData) + 4)^, 4);
end;

//---------------------------------------------------------------------------
procedure BlowfishInit(out Data: TBlowfishData; Key: Pointer;
 KeySize: Integer; const IV: TBlowfishIV);
var
 i, k : integer;
 Acc  : Longword;
 KeyB : PByteArray;
 Block: array[0..7] of Byte;
begin
 Move(SBox, Data.SBoxM, SizeOf(SBox));
 Move(PBox, Data.PBoxM, SizeOf(PBox));

 KeyB:= Key;
 with Data do
  begin
   Move(IV, InitBlock, 8);
   Move(IV, LastBlock, 8);

   k:= 0;
   for i:= 0 to 17 do
    begin
     Acc:= KeyB[(k + 3) mod KeySize];
     Inc(Acc, (KeyB[(k + 2) mod KeySize] shl 8));
     Inc(Acc, (KeyB[(k + 1) mod KeySize] shl 16));
     Inc(Acc, Acc + (KeyB[k] shl 24));

     PBoxM[i]:= PBoxM[i] xor Acc;
     k:= (k + 4) mod KeySize;
    end;

   FillChar(Block, Sizeof(Block), 0);
   for i:= 0 to 8 do
    begin
     BlowfishEncryptECB(Data, @Block, @Block);
     PBoxM[i * 2]:= Block[3] + (Block[2] shl 8) + (Block[1] shl 16) +
      (Block[0] shl 24);
     PBoxM[(i * 2) + 1]:= Block[7] + (Block[6] shl 8) + (Block[5] shl 16) +
      (Block[4] shl 24);
    end;

   for k:= 0 to 3 do
    for i:= 0 to 127 do
     begin
      BlowfishEncryptECB(Data, @Block, @Block);
      SBoxM[k, i * 2]:= Block[3] + (Block[2] shl 8) + (Block[1] shl 16) +
       (Block[0] shl 24);
      SBoxM[k, (i * 2) + 1]:= Block[7] + (Block[6] shl 8) + (Block[5] shl 16) +
       (Block[4] shl 24);
     end;
  end;
end;

//---------------------------------------------------------------------------
procedure BlowfishEncryptCBC(var Data: TBlowfishData; InData, OutData: Pointer);
begin
 XorBlock8(InData, @Data.LastBlock, OutData);
 BlowfishEncryptECB(Data, OutData, OutData);
 Move(OutData^, Data.LastBlock, 8);
end;

//---------------------------------------------------------------------------
procedure BlowfishDecryptCBC(var Data: TBlowfishData; InData, OutData: Pointer);
var
 AuxBlock: array[0..7] of byte;
begin
 Move(InData^, AuxBlock, 8);
 BlowfishDecryptECB(Data, InData, OutData);
 XorBlock8(OutData, @Data.LastBlock, OutData);
 Move(AuxBlock, Data.LastBlock,8);
end;

//---------------------------------------------------------------------------
procedure BlowfishEncode(MemAddr: Pointer; Count: Integer; Key: Pointer;
 KeySize: Integer; Subkey0, Subkey1: Longword);
var
 Data: TBlowfishData;
 IV: TBlowfishIV;
 i: Integer;
begin
 IV[0]:= Subkey0;
 IV[1]:= Subkey1;
 BlowfishInit(Data, Key, KeySize, IV);

 for i:= 0 to (Count div 8) - 1 do
  begin
   BlowfishEncryptCBC(Data, MemAddr, MemAddr);
   Inc(Integer(MemAddr), 8);
  end;

 BlowfishBurn(Data);
end;

//---------------------------------------------------------------------------
procedure BlowfishDecode(MemAddr: Pointer; Count: Integer; Key: Pointer;
 KeySize: Integer; Subkey0, Subkey1: Longword);
var
 Data: TBlowfishData;
 IV: TBlowfishIV;
 i: Integer;
begin
 IV[0]:= Subkey0;
 IV[1]:= Subkey1;
 BlowfishInit(Data, Key, KeySize, IV);

 for i:= 0 to (Count div 8) - 1 do
  begin
   BlowfishDecryptCBC(Data, MemAddr, MemAddr);
   Inc(Integer(MemAddr), 8);
  end;

 BlowfishBurn(Data);
end;

//---------------------------------------------------------------------------
end.

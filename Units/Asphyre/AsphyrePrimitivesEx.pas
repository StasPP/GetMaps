unit AsphyrePrimitivesEx;
//---------------------------------------------------------------------------
// AsphyrePrimitivesEx.pas                              Modified: 10-Oct-2005
// Efficient 3D vector list implementation                        Version 1.0
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
 TVectorList4 = class
 private
  NativeAddr : Pointer;
  AlignedAddr: Pointer;
  Capacity   : Integer;
  DataCount  : Integer;

  procedure Request(Amount: Integer);
  procedure Recapacitate(Amount: Integer);
  function GetItemPtr(Num: Integer): Pointer;
  function GetItem(Num: Integer): TVector4;
  procedure SetItem(Num: Integer; const Value: TVector4);
 public
  // the pointer to the first element in the list. 16-byte aligned.
  property MemAddr: Pointer read ALignedAddr;

  // # of elements in the list.
  property Count  : Integer read DataCount;

  // access to individual element
  property Items[Num: Integer]: TVector4 read GetItem write SetItem; default;

  function Add(const Vector: TVector4): Integer; overload;
  function Add(const Point: TPoint3): Integer; overload;
  function Add(x, y, z: Single): Integer; overload;

  procedure Remove(Index: Integer);
  procedure RemoveAll();

  procedure CopyFrom(Source: TVectorList4);
  procedure AddFrom(Source: TVectorList4);

  procedure Transform(Source: TVectorList4; const Mtx: TMatrix4);

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
const
 VectorCache = 512;

//---------------------------------------------------------------------------
// BatchTransform1 -- A modified version of BatchMultiply4 which makes
// an additional assumption about the vectors in vin: if each vector's
// 4th element (the homogenous coordinate w) is assumed to be 1.0 (as is
// the case for 3D vertices), we can eliminate a move, a shuffle and a
// multiply instruction.
//
// Performance: 17 cycles/vector
//---------------------------------------------------------------------------
procedure bTransform(Source, Dest: Pointer; Count: Integer; const Mtx: TMatrix4);
var
 MtxMem: Pointer;
 AlignedMatrix: ^TMatrix4;
begin
 MtxMem:= AllocMem(SizeOf(TMatrix4) + 16);
 AlignedMatrix:= Pointer(Integer(MtxMem) + (16 - (Integer(MtxMem) and $0F)));
 AlignedMatrix^:= Mtx;

 asm
  push esi
  push edi

  mov esi, Source
  mov edi, Dest
  mov ecx, Count

  // load columns of matrix into xmm4-7
  mov edx, AlignedMatrix
  movaps xmm4, [edx]
  movaps xmm5, [edx + $10]
  movaps xmm6, [edx + $20]
  movaps xmm7, [edx + $30]

@TransLoop:

  // process x (hiding the prefetches in the delays)
  movss  xmm1, [esi + $00]
  movss  xmm3, [esi + $10]
  shufps xmm1, xmm1, $00
  prefetchnta  [edi + $30]
  shufps xmm3, xmm3, $00
  mulps  xmm1, xmm4
  prefetchnta  [esi + $30]
  mulps  xmm3, xmm4

  // process y
  movss  xmm0, [esi + $04]
  movss  xmm2, [esi + $14]
  shufps xmm0, xmm0, $00
  shufps xmm2, xmm2, $00
  mulps  xmm0, xmm5
  mulps  xmm2, xmm5
  addps  xmm1, xmm0
  addps  xmm3, xmm2

  // process z (hiding some pointer arithmetic between
  // the multiplies)
  movss  xmm0, [esi + $08]
  movss  xmm2, [esi + $18]
  shufps xmm0, xmm0, $00
  shufps xmm2, xmm2, $00
  mulps  xmm0, xmm6
  add    esi, 32 // size of TVector4
  mulps  xmm2, xmm6
  add    edi, 32 // size of TVector4
  addps  xmm1, xmm0
  addps  xmm3, xmm2

  // process w
  addps xmm1, xmm7
  addps xmm3, xmm7

  // write output vectors to memory and loop
  movaps [edi - $20], xmm1
  movaps [edi - $10], xmm3
  dec ecx
  jnz @TransLoop

  pop edi
  pop esi
 end;
end;

//---------------------------------------------------------------------------
procedure MoveFast32(Source, Dest: Pointer; Count: Integer); stdcall;
asm
 // Preserve EDI, ESI, ESP, EBP, and EBX registers.
 // Freely modify the EAX, ECX, and EDX registers.
 push esi
 push edi

 mov ecx, Count
 mov esi, Source
 mov edi, Dest

@CopyLoop:
 mov eax, [esi]
 mov [edi], eax
 dec ecx
 jnz @CopyLoop

 pop edi
 pop esi
end;


//---------------------------------------------------------------------------
constructor TVectorList4.Create();
begin
 inherited;

 NativeAddr := nil;
 AlignedAddr:= nil;
 Capacity   := 0;
 DataCount  := 0;
end;

//---------------------------------------------------------------------------
destructor TVectorList4.Destroy();
begin
 if (NativeAddr <> nil) then
  begin
   FreeMem(NativeAddr);
   NativeAddr := nil;
   AlignedAddr:= nil;
   Capacity   := 0;
   DataCount  := 0;
  end;

 inherited;
end;

//---------------------------------------------------------------------------
procedure TVectorList4.Request(Amount: Integer);
var
 Required: Integer;
begin
 Required:= Ceil(Amount / VectorCache) * VectorCache;
 if (Capacity < Required) then Recapacitate(Required);
end;

//---------------------------------------------------------------------------
procedure TVectorList4.Recapacitate(Amount: Integer);
var
 NewAddr   : Pointer;
 NewAligned: Pointer;
begin
 // allocate the requested amount of memory
 GetMem(NewAddr, (Amount * SizeOf(TVector4)) + 16);

 // align the memory address to 16-byte
 NewAligned:= Pointer(Integer(NewAddr) + ($10 - (Integer(NewAddr) and $0F)));

 // copy the contents of old buffer to the new one
 if (DataCount > 0) then
  MoveFast32(AlignedAddr, NewAligned, (DataCount * SizeOf(TVector4)) shr 2);

 // release the previously allocated memory
 if (NativeAddr <> nil) then FreeMem(NativeAddr);

 // update memory pointers
 NativeAddr := NewAddr;
 AlignedAddr:= NewAligned;

 // update the capacity
 Capacity:= Amount;
end;

//---------------------------------------------------------------------------
function TVectorList4.GetItemPtr(Num: Integer): Pointer;
begin
 if (Num < 0)or(Num >= DataCount) then
  begin
   Result:= nil;
   Exit;
  end;

 Result:= Pointer(Integer(AlignedAddr) + (Num * SizeOf(TVector4)));
end;

//---------------------------------------------------------------------------
function TVectorList4.GetItem(Num: Integer): TVector4;
var
 pVec: PVector4;
begin
 pVec:= GetItemPtr(Num);
 if (pVec = nil) then
  begin
   Result:= ZeroVector4;
   Exit;
  end;

 Result:= pVec^;
end;

//---------------------------------------------------------------------------
procedure TVectorList4.SetItem(Num: Integer; const Value: TVector4);
var
 pVec: PVector4;
begin
 pVec:= GetItemPtr(Num);
 if (pVec = nil) then Exit;

 pVec^:= Value;
end;

//---------------------------------------------------------------------------
function TVectorList4.Add(const Vector: TVector4): Integer;
var
 Index: Integer;
 pVec : PVector4;
begin
 Index:= DataCount;
 Request(DataCount + 1);
 Inc(DataCount);

 pVec:= GetItemPtr(Index);
 pVec^:= Vector;

 Result:= Index;
end;

//---------------------------------------------------------------------------
function TVectorList4.Add(x, y, z: Single): Integer;
begin
 Result:= Add(Vector3(x, y, z));
end;

//---------------------------------------------------------------------------
function TVectorList4.Add(const Point: TPoint3): Integer;
begin
 Result:= Add(Vec3to4(Point));
end;

//---------------------------------------------------------------------------
procedure TVectorList4.Remove(Index: Integer);
var
 Source: Pointer;
 Dest  : Pointer;
 Amount: Integer;
begin
 if (Index < 0)or(Index >= DataCount) then Exit;

 Amount:= (DataCount - Index) - 1;
 if (Amount > 0) then
  begin
   Source:= GetItemPtr(Index + 1);
   Dest  := GetItemPtr(Index);

   MoveFast32(Source, Dest, (Amount * SizeOf(TVector4)) shr 2);
  end;

 Dec(DataCount);
end;

//---------------------------------------------------------------------------
procedure TVectorList4.RemoveAll();
begin
 DataCount:= 0;
end;

//---------------------------------------------------------------------------
procedure TVectorList4.CopyFrom(Source: TVectorList4);
begin
 Request(Source.Count);

 MoveFast32(Source.MemAddr, AlignedAddr, (Source.Count * SizeOf(TVector4)) shr 2);
 DataCount:= Source.Count;
end;

//---------------------------------------------------------------------------
procedure TVectorList4.AddFrom(Source: TVectorList4);
var
 DestAddr: Pointer;
begin
 Request(DataCount + Source.Count);

 DestAddr:= GetItemPtr(DataCount);
 MoveFast32(Source.MemAddr, DestAddr, (Source.Count * SizeOf(TVector4)) shr 2);

 Inc(DataCount, Source.Count);
end;

//---------------------------------------------------------------------------
procedure TVectorList4.Transform(Source: TVectorList4; const Mtx: TMatrix4);
var
 i    : Integer;
 Dest : PVector4;
 Src  : PVector4;
 Index: Integer;
// NewCount: Integer;
begin
 Index:= DataCount;

 Request(DataCount + Source.Count);
 Inc(DataCount, Source.Count);

 Src := Source.MemAddr;
 Dest:= GetItemPtr(Index);
 for i:= 0 to Source.Count - 1 do
  begin
   Dest^:= MatVecMul(Src^, Mtx);

   Inc(Src);
   Inc(Dest);
  end;

{ NewCount:= Ceil(Source.Count / 2.0);
 bTransform(Src, Dest, NewCount, Mtx);}
end;

//---------------------------------------------------------------------------
end.

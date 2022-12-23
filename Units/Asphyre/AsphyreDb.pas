unit AsphyreDb;
//---------------------------------------------------------------------------
// AsphyreDb.pas                                        Modified: 16-Oct-2005
// Asphyre Secure Database (ASDb) implementation                  Version 1.0
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
 Windows, Classes, Math, SysUtils, StreamEx, AsphyreData, Blowfish, AsphyreMD5;

//---------------------------------------------------------------------------
const
 ASDbSignature = $62445341; // 'ASDb'

 // record type enumerations
 recUnknown    = 0;
 recGraphics   = 1;
 recFile       = 2;
 recFont       = 3;

//---------------------------------------------------------------------------
type
 PASDbHeader = ^TASDbHeader;
 TASDbHeader = packed record 
  Signature  : Longword; // signature ('ASDb' = 62445341h)
  RecordCount: Longword; // number of records in the archive
  TableOffset: Longword; // table offset
 end;

//---------------------------------------------------------------------------
{
 ASDb Table structure:
  Key Name      -  4+ bytes (dword: length; [length-bytes]: string chars)
  Offset        -  unsigned dword

 ASDb Record structure:
  RecordType    -  word

  OrigSize      -  unsigned dword
  PhysSize      -  unsigned dword
  DateTime      -  double (unsigned qword)

  Checksum      -  16 bytes (MD5 message-digest)

  Encoding      -  word
  IV            -  unsigned qword (8 bytes) as IV

  DataBlock     -  DataSize bytes
}

//---------------------------------------------------------------------------
 TRecordInfo = record
  Key       : string;    // record unique identifier
  Offset    : Longword;  // record offset in archive
  RecordType: Cardinal;  // type of the record (generic, file, graphics, etc)
  OrigSize  : Cardinal;  // original data size
  PhysSize  : Cardinal;  // physical data size
  DateTime  : TDateTime; // record date & time

  Checksum  : array[0..3] of Longword; // MD5 message-digest

  Secure    : Boolean;   // whether record is encrypted
  InitBlock : array[0..1] of Longword;
 end;

//---------------------------------------------------------------------------
 TOpenModes = (opUpdate, opOverwrite, opReadOnly);

//---------------------------------------------------------------------------
 TASDb = class(TComponent)
 private
  FUpdatedOnce: Boolean;
  FFileSize : Cardinal;
  FFileName : string;
  FOpenMode : TOpenModes;
  FRecords  : array of TRecordInfo;
  ASDbHeader: TASDbHeader;

  PassBlock : array[0..56] of Byte;
  FPassSize : Integer;

  function GetRecordDate(Num: Integer): TDateTime;
  function GetRecordCount(): Integer;
  function GetRecordPhysSize(Num: Integer): Integer;
  function GetRecordKey(Num: Integer): string;
  function GetRecordNum(Key: string): Integer;
  function GetRecordOrigSize(Num: Integer): Integer;
  procedure SetFileName(const Value: string);
  function CreateEmtpyFile(): Boolean;
  function GetRecordType(Num: Integer): Integer;
  function GetRecordSecure(Num: Integer): Boolean;
  function GetPassword(): Pointer;

  function ReadASDbHeader(Stream: TStream; ASDbHeader: PASDbHeader): Boolean;
  function ReadASDbInfo(Stream: TStream): Boolean;
  function WriteRecordTable(): Boolean;

  function CompressData(Source: Pointer; SourceSize: Cardinal;
   out Data: Pointer; out DataSize: Cardinal): Boolean;
  function DecompressData(Source: Pointer; SourceSize: Cardinal;
   out Data: Pointer; DataSize: Cardinal): Boolean;
    function GetRecordChecksum(Num: Integer): Pointer;
 public
  //=========================================================================
  // PUBLIC Properties
  //=========================================================================
  property UpdatedOnce: Boolean read FUpdatedOnce;

  property FileSize: Cardinal read FFileSize;
  property Password: Pointer read GetPassword;
  property PassSize: Integer read FPassSize;

  property RecordCount: Integer read GetRecordCount;
  property RecordKey[Num: Integer]: string read GetRecordKey;
  property RecordPhysSize[Num: Integer]: Integer read GetRecordPhysSize;
  property RecordOrigSize[Num: Integer]: Integer read GetRecordOrigSize;
  property RecordNum[Key: string]: Integer read GetRecordNum;
  property RecordType[Num: Integer]: Integer read GetRecordType;
  property RecordDate[Num: Integer]: TDateTime read GetRecordDate;
  property RecordSecure[Num: Integer]: Boolean read GetRecordSecure;
  property RecordChecksum[Num: Integer]: Pointer read GetRecordChecksum;

  //=========================================================================
  // PUBLIC Methods
  //=========================================================================

  // updates the password used to decode records
  procedure SetPassword(MemAddr: Pointer; Size: Integer);

  // removes the stored password and replaces it with zeros
  procedure BurnPassword();

  // writes the specific record to ASDb archive
  function WriteRecord(const Key: string; Source: Pointer;
   SourceSize: Cardinal; RecordType: Integer): Boolean;

  // writes the entire stream to ASDb archive
  function WriteStream(const Key: string; Stream: TStream;
   RecordType: Integer): Boolean;

  function WriteString(const Key, Text: string;
   RecordType: Integer): Boolean;

  // reads the specified record from ASDb archive
  // NOTE: this method allocates memory which needs to be freed by FreeMem
  function ReadRecord(const Key: string; out Data: Pointer;
   out DataSize: Cardinal): Boolean;

  // reads the record and stores it in the stream
  function ReadStream(const Key: string; Stream: TStream): Boolean;

  // reads ASDb record contents as a text string
  function ReadString(const Key: string; out Text: string): Boolean;

  // removes the record from archive
  function RemoveRecord(const Key: string): Boolean;

  // changes the key of the record without physically moving it
  function RenameRecord(const Key, NewKey: string): Boolean;

  // switches the positions of two records
  function SwitchRecords(Index1, Index2: Integer): Boolean;

  // sorts the records by type not affecting order of items with the same type
  function SortRecords(): Boolean;

  constructor Create(AOwner: TComponent); override;

  // updates the list of ASDb records
  function Update(): Boolean;

  // updates the record list only once
  function UpdateOnce(): Boolean;

 published
  // The name of the archive
  property FileName: string read FFileName write SetFileName;

  // open mode (e.g. WriteBuffer-only)
  property OpenMode: TOpenModes read FOpenMode write FOpeNmode;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
const
 // A record name returned when invalid index is specified
 invRecordName = '[invalid-record-#]';

 // When using compression, a temporary buffer is used to store the final
 // output. Under certain circumstances, the output data size is bigger than
 // the original. For these cases, output buffer is created slightly bigger
 // than the original. The additional percentage added is specified below.
 BufferGrow    = 5; // default: 5 (in %)

 // For the same purpose as BufferGrow, this value is simply added to the
 // buffer size previously increased by BufferGrow (for very short buffers).
 BufferGrowAdd = 256; // default: 256

 // In original record position, this offset determines where record data
 // is allocated. This is used for ReadRecord method to get directly to
 // record data. Also used for removing records.
 DataOffset    = 44;

 // Temporary archive name to be used when deleting or overwriting records
 TempFilename  = 'asdb.tmp';

//---------------------------------------------------------------------------
constructor TASDb.Create(AOwner: TComponent);
begin
 inherited;

 FUpdatedOnce:= False;
 FFileSize:= 0;
 FFileName:= '';
 FOpenMode:= opUpdate;
 FPassSize:= 0;

 SetLength(FRecords, 0);
 FillChar(ASDbHeader, SizeOf(TASDbHeader), 0);
 FillChar(PassBlock, SizeOf(PassBlock), 0);
end;

//---------------------------------------------------------------------------
function TASDb.GetPassword(): Pointer;
begin
 Result:= @PassBlock;
end;

//---------------------------------------------------------------------------
procedure TASDb.BurnPassword();
begin
 FillChar(PassBlock, SizeOf(PassBlock), 0);
 FPassSize:= 0;
end;

//---------------------------------------------------------------------------
procedure TASDb.SetPassword(MemAddr: Pointer; Size: Integer);
begin
 // erase previously stored password
 BurnPassword();

 // validate key sizes
 if (Size < 1) then Exit;
 if (Size > 56) then Size:= 56;

 // store a new key
 Move(MemAddr^, PassBlock, Size);
 FPassSize:= Size;
end;

//---------------------------------------------------------------------------
function TASDb.GetRecordCount(): Integer;
begin
 Result:= Length(FRecords);
end;

//---------------------------------------------------------------------------
function TASDb.GetRecordPhysSize(Num: Integer): Integer;
begin
 if (Num >= 0)and(Num < Length(FRecords)) then
  begin
   Result:= FRecords[Num].PhysSize;
  end else Result:= 0;
end;

//---------------------------------------------------------------------------
function TASDb.GetRecordOrigSize(Num: Integer): Integer;
begin
 if (Num >= 0)and(Num < Length(FRecords)) then
  begin
   Result:= FRecords[Num].OrigSize;
  end else Result:= 0;
end;

//---------------------------------------------------------------------------
function TASDb.GetRecordType(Num: Integer): Integer;
begin
 if (Num >= 0)and(Num < Length(FRecords)) then
  begin
   Result:= FRecords[Num].RecordType;
  end else Result:= 0;
end;

//---------------------------------------------------------------------------
function TASDb.GetRecordKey(Num: Integer): string;
begin
 if (Num >= 0)and(Num < Length(FRecords)) then
  begin
   Result:= FRecords[Num].Key;
  end else Result:= invRecordName;
end;

//---------------------------------------------------------------------------
function TASDb.GetRecordDate(Num: Integer): TDateTime;
begin
 if (Num >= 0)and(Num < Length(FRecords)) then
  begin
   Result:= FRecords[Num].DateTime;
  end else Result:= Now();
end;

//---------------------------------------------------------------------------
function TASDb.GetRecordSecure(Num: Integer): Boolean;
begin
 if (Num >= 0)and(Num < Length(FRecords)) then
  begin
   Result:= FRecords[Num].Secure;
  end else Result:= False;
end;

//---------------------------------------------------------------------------
function TASDb.GetRecordChecksum(Num: Integer): Pointer;
begin
 if (Num >= 0)and(Num < Length(FRecords)) then
  begin
   Result:= @FRecords[Num].Checksum;
  end else Result:= nil;
end;

//---------------------------------------------------------------------------
procedure TASDb.SetFileName(const Value: string);
begin
 FFileName:= Value;
 FUpdatedOnce:= False;
end;

//---------------------------------------------------------------------------
function TASDb.GetRecordNum(Key: string): Integer;
var
 i: Integer;
begin
 Key:= LowerCase(Key);

 for i:= 0 to Length(FRecords) - 1 do
  if (LowerCase(FRecords[i].Key) = Key) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= -1;
end;

//---------------------------------------------------------------------------
function TASDb.CreateEmtpyFile(): Boolean;
var
 fs: TStream;
begin
 // prepare empty header
 FillChar(ASDbHeader, SizeOf(TASDbHeader), 0);
 ASDbHeader.Signature:= ASDbSignature;
 ASDbHeader.RecordCount:= 0;
 // offset to non-existant table
 ASDbHeader.TableOffset:= SizeOf(TASDbHeader);

 // create file stream
 try
  fs:= TFileStream.Create(FFileName, fmCreate or fmShareExclusive);
 except
  Result:= False;
  Exit;
 end;

 // write header
 Result:= True;
 try
  fs.WriteBuffer(ASDbHeader, SizeOf(ASDbHeader));
 except
  Result:= False;
 end;

 // free file stream
 fs.Free();

 // file size
 FFileSize:= SizeOf(ASDbHeader);

 // assume no records exist
 SetLength(FRecords, 0);
end;

//---------------------------------------------------------------------------
function TASDb.ReadASDbHeader(Stream: TStream; ASDbHeader: PASDbHeader): Boolean;
begin
 if (Stream = nil) then
  begin
   Result:= False;
   Exit;
  end;

 Result:= True;
 try
  // read ASDb Header
  Stream.Seek(0, soFromBeginning);
  Stream.ReadBuffer(ASDbHeader^, SizeOf(TASDbHeader));
 except
  Result:= False;
 end;
end;

//---------------------------------------------------------------------------
function TASDb.ReadASDbInfo(Stream: TStream): Boolean;
var
 i: Integer;
 NoStream: Boolean;
begin
 // release records
 SetLength(FRecords, 0);
 NoStream:= (Stream = nil);

 if (NoStream) then
  begin
   // open the specified file
   try
    Stream:= TFileStream.Create(FFileName, fmOpenRead or fmShareDenyWrite);
   except
    Result:= False;
    Exit;
   end;
  end;

 // read & validate ASDbHeader
 Result:= ReadASDbHeader(Stream, @ASDbHeader);
 if (not Result) then
  begin
   if (NoStream) then Stream.Free();
   Exit;
  end;

 // retreive file size
 FFileSize:= Stream.Size;

 // seek record table in archive
 Stream.Seek(ASDbHeader.TableOffset, soFromBeginning);

 // specify record count
 SetLength(FRecords, ASDbHeader.RecordCount);

 // read record names and positions
 try
  for i:= 0 to Length(FRecords) - 1 do
   begin
    // read record name
    FRecords[i].Key:= stReadString(Stream);
    FRecords[i].Offset:= stReadLongword(Stream);
   end;
 except
  Result:= False;
 end;

 // check for Read errors
 if (not Result) then
  begin
   // no records are saved on error
   SetLength(FRecords, 0);
   if (NoStream) then Stream.Free();
   Exit;
  end;

 // check if any records exist in archive
 if (ASDbHeader.RecordCount < 1) then
  begin
   if (NoStream) then Stream.Free();
   Exit;
  end;

 // read record detailed information
 try
  for i:= 0 to Length(FRecords) - 1 do
   begin
    // seek record's position
    Stream.Seek(FRecords[i].Offset, soFromBeginning);

    // record type
    FRecords[i].RecordType:= stReadWord(Stream);

    // basic info
    FRecords[i].OrigSize:= stReadLongword(Stream);
    FRecords[i].PhysSize:= stReadLongword(Stream);
    FRecordS[i].DateTime:= stReadDouble(Stream);

    // MD5 message-digest of record's contents
    Stream.ReadBuffer(FRecords[i].Checksum, SizeOf(FRecords[i].Checksum));

    // security information
    FRecords[i].Secure:= Boolean(stReadWord(Stream));
    Stream.ReadBuffer(FRecords[i].InitBlock, SizeOf(FRecords[i].InitBlock));
   end; // for
 except
  Result:= False;
 end;

 // release stream's memory
 if (NoStream) then Stream.Free();
end;

//---------------------------------------------------------------------------
function TASDb.Update(): Boolean;
begin
 Result:= True;
 
 // act depending of opening mode
 case FOpenMode of
  // create new file
  opOverwrite:
   Result:= CreateEmtpyFile();

  // open file for reading
  opReadOnly:
   Result:= ReadASDbInfo(nil);

  // open file for update
  opUpdate:
   begin
    if (FileExists(FFileName)) then Result:= ReadASDbInfo(nil)
     else Result:= CreateEmtpyFile();
   end;
 end;

 FUpdatedOnce:= Result;
end;

//---------------------------------------------------------------------------
function TASDb.UpdateOnce(): Boolean;
begin
 Result:= FUpdatedOnce;
 if (not Result) then Result:= Update();
end;

//---------------------------------------------------------------------------
function TASDb.CompressData(Source: Pointer; SourceSize: Cardinal;
 out Data: Pointer; out DataSize: Cardinal): Boolean;
var
 CodeBuf   : Pointer;
 BufferSize: Cardinal;
begin
 Result:= True;

 // guaranteed buffer size
 BufferSize:= Ceil((SourceSize * (100 + BufferGrow)) / 100) + BufferGrowAdd;

 // allocate encoding buffer
 GetMem(CodeBuf, BufferSize);

 // inflate the buffer
 DataSize:= AsphyreData.CompressData(Source, CodeBuf, SourceSize, BufferSize,
  clHighest);
 if (DataSize = 0) then
  begin
   FreeMem(CodeBuf);
   Result:= False;
   Exit;
  end;

 // allocate real data container
 GetMem(Data, DataSize);

 // copy the compressed data
 Move(CodeBuf^, Data^, DataSize);

 // release encoding buffer
 FreeMem(CodeBuf);
end;

//---------------------------------------------------------------------------
function TASDb.DecompressData(Source: Pointer; SourceSize: Cardinal;
 out Data: Pointer; DataSize: Longword): Boolean;
var
 OutSize: Integer;
begin
 Result:= True;

 // allocate output buffer
 GetMem(Data, DataSize);

 // decompress the data stream
 OutSize:= AsphyreData.DecompressData(Source, Data, SourceSize, DataSize);
 if (OutSize = 0)or(Int64(OutSize) <> DataSize) then
  begin
   FreeMem(Data);
   Data:= nil;
   Result:= False;
  end;
end;

//---------------------------------------------------------------------------
function TASDb.WriteRecordTable(): Boolean;
var
 Stream: TFileStream;
 i: Integer;
begin
 Result:= True;

 // (1) OPEN THE ARCHIVE for *writing*
 try
  Stream:= TFileStream.Create(FFileName, fmOpenWrite or fmShareExclusive);
 except
  Result:= False;
  Exit;
 end;

 try
  // (2) go to the position of record table
  Stream.Seek(ASDbHeader.TableOffset, soFromBeginning);

  // (3) flush the record table
  for i:= 0 to Length(FRecords) - 1 do
   begin
    stWriteString(Stream, FRecords[i].Key);
    stWriteLongword(Stream, FRecords[i].Offset);
   end;
 except
  Result:= False;
 end;

 // (4) release the file stream
 Stream.Free();
end;

//---------------------------------------------------------------------------
function TASDb.WriteRecord(const Key: string; Source: Pointer;
 SourceSize: Cardinal; RecordType: Integer): Boolean;
var
 Data: Pointer;
 DataSize: Cardinal;
 i, NewIndex: Integer;
 Stream: TStream;
 RecordOffset: Cardinal;
 Subkeys: array[0..1] of Longword;
 Checksum: array[0..3] of Longword;
 CurDate: TDateTime;
begin
 Result := False;
 CurDate:= Now();

 // (1) verify open mode
 if (FOpenMode = opReadOnly) then Exit;

 // (2) if the record exists, remove it
 if (GetRecordNum(Key) <> -1) then RemoveRecord(Key);

 // (3) calculate checksum and digest
 MD5Checksum(Source, SourceSize, @Checksum);

 // (4) compress input data
 Result:= CompressData(Source, SourceSize, Data, DataSize);
 if (not Result) then Exit;

 // (5) Apply security
 if (FPassSize > 0) then
  begin
   // -> generate random IV keys
   Subkeys[0]:= Round(Random * High(Longword));
   Subkeys[1]:= Round(Random * High(Longword));
   // -> encrypt compressed data
   BlowfishEncode(Data, DataSize, @PassBlock, FPassSize, Subkeys[0], Subkeys[1]);
  end else
  begin
   Subkeys[0]:= 0;
   Subkeys[1]:= 0;
  end;

 // (6) OPEN THE ARCHIVE for reading & writing
 try
  Stream:= TFileStream.Create(FFileName, fmOpenReadWrite or fmShareExclusive);
 except
  Result:= False;
  Exit;
 end;

 // (7) update ASDb info, in case it has been changed
 Result:= ReadASDbInfo(Stream);
 if (not Result) then
  begin
   Stream.Free();
   Exit;
  end;

 // (8) if the record still exists, we cannot proceed
 if (GetRecordNum(Key) <> -1) then
  begin
   Stream.Free();
   Result:= False;
   Exit;
  end;

 // (9) write the ENTIRE RECORD
 try
  // seek the record table position and write the record there!
  RecordOffset:= ASDbHeader.TableOffset;
  Stream.Seek(RecordOffset, soFromBeginning);

  // RECORD TYPE
  stWriteWord(Stream, RecordType);
  // ORIGINAL SIZE
  stWriteLongword(Stream, SourceSize);
  // PHYSICAL SIZE
  stWriteLongword(Stream, DataSize);
  // DATE & TIME
  stWriteDouble(Stream, CurDate);

  // Checksum: MD5 message-digest
  Stream.WriteBuffer(Checksum, SizeOf(Checksum));

  // Security Information
  stWriteWord(Stream, Word(FPassSize > 0));
  Stream.WriteBuffer(Subkeys, SizeOf(Subkeys));

  // RECORD DATA
  Stream.WriteBuffer(Data^, DataSize);
 except
  Result:= False;
  FreeMem(Data);
  Stream.Free();
  Exit;
 end;

 // (10) add new record to the record list
 NewIndex:= Length(FRecords);
 SetLength(FRecords, NewIndex + 1);
 FRecords[NewIndex].Key:= Key;
 Move(Checksum, FRecords[NewIndex].Checksum, SizeOf(Checksum));
 FRecords[NewIndex].RecordType:= RecordType;
 FRecords[NewIndex].OrigSize:= SourceSize;
 FRecords[NewIndex].PhysSize:= DataSize;
 FRecords[NewIndex].Offset  := RecordOffset;
 FRecords[NewIndex].DateTime:= CurDate;
 FRecords[NewIndex].Secure  := (FPassSize > 0);
 FRecords[NewIndex].InitBlock[0]:= Subkeys[0];
 FRecords[NewIndex].InitBlock[1]:= Subkeys[1];

 // (11) update ASDb Header information
 ASDbHeader.TableOffset:= Stream.Position;
 ASDbHeader.RecordCount:= ASDbHeader.RecordCount + 1;

 try
  // (12) rewrite entire RECORD TABLE
  for i:= 0 to Length(FRecords) - 1 do
   begin
    stWriteString(Stream, FRecords[i].Key);
    stWriteLongword(Stream, FRecords[i].Offset);
   end;

 // (13) write down ASDb HEADER
 Stream.Seek(0, soFromBeginning);
 Stream.WriteBuffer(ASDbHeader, SizeOf(TASDbHeader));
 except
  Result:= False;
 end;

 // (14) Release the stream and memory
 FreeMem(Data);
 Stream.Free();
end;

//---------------------------------------------------------------------------
function TASDb.WriteStream(const Key: string; Stream: TStream;
 RecordType: Integer): Boolean;
var
 Data: Pointer;
 DataSize, ReadBytes: Integer;
begin
 Result:= False;

 // verify open mode
 if (FOpenMode = opReadOnly) then Exit;

 // allocate memory for stream data
 DataSize:= Stream.Size - Stream.Position;
 Data:= AllocMem(DataSize);

 // read the stream data
 ReadBytes:= Stream.Read(Data^, DataSize);
 if (ReadBytes <> DataSize) then
  begin
   FreeMem(Data);
   Exit;
  end;

 // write the data to ASDb
 Result:= WriteRecord(Key, Data, DataSize, RecordType);

 // free the unused memory
 FreeMem(Data);
end;

//---------------------------------------------------------------------------
function TASDb.WriteString(const Key, Text: string; RecordType: Integer): Boolean;
begin
 if (Length(Text) < 1) then
  begin
   Result:= False;
   Exit;
  end;

 Result:= WriteRecord(Key, @Text[1], Length(Text), RecordType);
end;

//---------------------------------------------------------------------------
function TASDb.ReadRecord(const Key: string; out Data: Pointer;
 out DataSize: Cardinal): Boolean;
var
 PreBuf: Pointer;
 PreSize: Cardinal;
 PreRelease: Boolean;
 Index: Integer;
 Stream: TStream;
 Checksum: array[0..3] of Longword;
begin
 Result:= False;

 // (1) OPEN archive
 try
  Stream:= TFileStream.Create(FFileName, fmOpenRead or fmShareDenyWrite);
 except
  Exit;
 end;

 // (2) update ASDb info, in case it has been changed
 Result:= ReadASDbInfo(Stream);
 if (not Result) then
  begin
   Stream.Free();
   Exit;
  end;

 // (3) find record index
 Index:= GetRecordNum(Key);
 if (Index = -1) then
  begin
   Stream.Free();
   Result:= False;
   Exit;
  end;

 // assign data size
 DataSize:= FRecords[Index].OrigSize;

 // (4) create temporary buffers
 PreSize:= FRecords[Index].PhysSize;
 GetMem(PreBuf, PreSize);
 PreRelease:= True;

 // (5) read the ENTIRE RECORD
 try
  // seek the record position in the file
  Stream.Seek(FRecords[Index].Offset + DataOffset, soFromBeginning);

  // read record data
  Stream.ReadBuffer(PreBuf^, PreSize);
 except
  Result:= False;
  FreeMem(PreBuf);
  Stream.Free();
  Exit;
 end;

 // close the file stream
 Stream.Free();

 // (6) Apply security
 if (FRecords[Index].Secure)and(FPassSize > 0) then
  begin
   BlowfishDecode(PreBuf, PreSize, @PassBlock, FPassSize,
    FRecords[Index].InitBlock[0], FRecords[Index].InitBlock[1]);
  end;

 // (7) decompress the data stream
 Result:= DecompressData(PreBuf, PreSize, Data, DataSize);
 if (not Result) then
  begin
   FreeMem(PreBuf);
   Exit;
  end;

 // (8) release buffers
 if (PreRelease) then FreeMem(PreBuf);

 // (9) checksum verification
 MD5Checksum(Data, DataSize, @Checksum);
 Result:= CompareMem(@Checksum, @FRecords[Index].Checksum, SizeOf(Checksum));
end;

//---------------------------------------------------------------------------
function TASDb.ReadStream(const Key: string; Stream: TStream): Boolean;
var
 Data: Pointer;
 DataSize, BytesWritten: Cardinal;
begin
 // read the record data
 Result:= ReadRecord(Key, Data, DataSize);

 // write the record data to stream
 if (Result) then
  begin
   BytesWritten:= Stream.Write(Data^, DataSize);
   Result:= (BytesWritten = DataSize);

   // free the unused memory
   FreeMem(Data);
  end;
end;

//---------------------------------------------------------------------------
function TASDb.ReadString(const Key: string; out Text: string): Boolean;
var
 Data: Pointer;
 Size: Cardinal;
begin
 Result:= ReadRecord(Key, Data, Size);
 if (Result) then
  begin
   if (Size > 0) then
    begin
     SetLength(Text, Size);
     Move(Data^, (@Text[1])^, Size);
     FreeMem(Data);
    end else Text:= '';
  end;
end;

//---------------------------------------------------------------------------
function TASDb.RemoveRecord(const Key: string): Boolean;
var
 InStream, OutStream: TFileStream;
 NewHeader: TASDbHeader;
 NewRecords: array of TRecordInfo;
 i, Index, NewIndex: Integer;
 Data: Pointer;
 DataSize: Cardinal;
begin
 SetLength(NewRecords, 0);
 Data:= nil;

 // (1) Update record list
 Result:= Update();
 if (not Result) then Exit;

 // (2) retreive record index
 Index:= GetRecordNum(Key);
 if (Index = -1) then
  begin
   Result:= False;
   Exit;
  end; 

 // (3) OPEN THE SOURCE for reading & writing
 try
  InStream:= TFileStream.Create(FFileName, fmOpenReadWrite or fmShareDenyWrite);
 except
  Exit;
 end;

 // (4) OPEN THE DESTINATION for writing
 try
  OutStream:= TFileStream.Create(TempFilename, fmCreate);
 except
  Exit;
 end;

 // (5) update ASDb info, in case it has been changed
 Result:= ReadASDbInfo(InStream);
 if (not Result) then
  begin
   InStream.Free();
   OutStream.Free();
   Exit;
  end;

 // (6) create NEW HEADER
 Move(ASDbHeader, NewHeader, SizeOf(TASDbHeader));
 NewHeader.RecordCount:= ASDbHeader.RecordCount - 1;

 // (7) Write temporary ASDb header
 try
  OutStream.WriteBuffer(NewHeader, SizeOf(TASDbHeader));
 except
  Result:= False;
  InStream.Free();
  OutStream.Free();
  Exit;
 end;

 // (8) Completely rewrite RECORD LIST
 for i:= 0 to Length(FRecords) - 1 do
  if (i <> Index) then
   begin
    // create a copy of previous record
    NewIndex:= Length(NewRecords);
    SetLength(NewRecords, NewIndex + 1);
    NewRecords[NewIndex]:= FRecords[i];

    // update record offset
    NewRecords[NewIndex].Offset:= OutStream.Position;

    // allocate temporary buffers
    DataSize:= NewRecords[NewIndex].PhysSize + DataOffset;
    ReallocMem(Data, DataSize);

    // read the whole record block
    try
     InStream.Seek(FRecords[i].Offset, soFromBeginning);
     InStream.ReadBuffer(Data^, DataSize);
    except
     InStream.Free();
     OutStream.Free();
     FreeMem(Data);
     Result:= False;
     Exit;
    end;

    // write the whole record block
    try
     OutStream.WriteBuffer(Data^, DataSize);
    except
     InStream.Free();
     OutStream.Free();
     FreeMem(Data);
     Result:= False;
     Exit;
    end;
   end; // rewrite records

 // the record table follows, update ASDb header
 NewHeader.TableOffset:= OutStream.Position;

 // (9) write NEW RECORD table (and update the current one)
 SetLength(FRecords, Length(NewRecords));
 try
  for i:= 0 to Length(NewRecords) - 1 do
   begin
    // write record info
    stWriteString(OutStream, NewRecords[i].Key);
    stWriteLongword(OutStream, NewRecords[i].Offset);

    // update the record table
    FRecords[i]:= NewRecords[i];
   end;

  // (10) write updated ASDb header
  OutStream.Seek(0, soFromBeginning);
  OutStream.WriteBuffer(NewHeader, SizeOf(TASDbHeader));
 except
  Result:= False;
  InStream.Free();
  OutStream.Free();
  Exit;
 end;

 // update file size
 FFileSize:= OutStream.Size;

 // (11) Release allocated buffers
 if (Data <> nil) then FreeMem(Data);
 InStream.Free();
 OutStream.Free();

 // (12) Switch between temporary file and real one
 try
  DeleteFile(FFileName);
  RenameFile(TempFilename, FFileName);
 except
  Result:= False;
 end;
end;

//---------------------------------------------------------------------------
function TASDb.RenameRecord(const Key, NewKey: string): Boolean;
var
 Index: Integer;
begin
 // (1) Check the validity of OpenMode.
 if (FOpenMode in [opOverwrite, opReadonly]) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Refresh record list.
 Result:= ReadASDbInfo(nil);
 if (not Result) then Exit;

 // (3) Check the validity of specified keys.
 Index:= GetRecordNum(Key);
 if (Index = -1)or(GetRecordNum(NewKey) <> -1) then
  begin
   Result:= False;
   Exit;
  end;

 // (4) Modify record table.
 FRecords[Index].Key:= NewKey;

 // (5) Write new record table.
 Result:= WriteRecordTable();
end;

//---------------------------------------------------------------------------
function TASDb.SwitchRecords(Index1, Index2: Integer): Boolean;
var
 Aux: TRecordInfo;
begin
 // (1) Check the validity of OpenMode.
 if (FOpenMode in [opOverwrite, opReadonly]) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Refresh record list.
 Result:= ReadASDbInfo(nil);
 if (not Result) then Exit;

 // (3) Validate indexes with updated list.
 if (Index1 < 0)or(Index2 < 0)or(Index1 >= Length(FRecords))or
  (Index2 >= Length(FRecords)) then
  begin
   Result:= False;
   Exit;
  end;

 // (4) Exchange two records.
 Aux:= FRecords[Index1];
 FRecords[Index1]:= FRecords[Index2];
 FRecords[Index2]:= Aux;

 // (5) Write new record table.
 Result:= WriteRecordTable();
end;

//---------------------------------------------------------------------------
function TASDb.SortRecords(): Boolean;
var
 i, j: Integer;
 Aux: TRecordInfo;
begin
 for i:= 0 to Length(FRecords) - 2 do
  for j:= 0 to Length(FRecords) - i - 2 do
   if (FRecords[j].RecordType > FRecords[j + 1].RecordType) then
    begin
     Aux:= FRecords[j];
     FRecords[j]:= FRecords[j + 1];
     FRecords[j + 1]:= Aux;
    end;

 Result:= WriteRecordTable();
end;

//---------------------------------------------------------------------------
end.

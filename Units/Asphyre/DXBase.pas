unit DXBase;
//---------------------------------------------------------------------------
// DXBase.pas                                           Modified: 27-Sep-2005
// Direct3D base framework for Asphyre                            Version 2.0
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
 Windows, Types, Classes, SysUtils, Direct3D9, DirectInput, AsphyreDef,
 AsphyreMath;

//---------------------------------------------------------------------------
// Global Direct3D9 Access. This is initialized automatically and provided
// for programmer's convenience. In the case of failure, this variable will
// be set to NIL.
//---------------------------------------------------------------------------
var
 Direct3D      : IDirect3D9 = nil;
 Direct3DDevice: IDirect3DDevice9 = nil;
 PresentParams : TD3DPresentParameters;
 DeviceCaps    : TD3DCaps9;
 DirectInput8  : IDirectInput8    = nil;

//---------------------------------------------------------------------------
// DXBestBackFormat()
//
// Attempts to find the best back-buffer format for full-screen mode, that
// complies with the requested attributes.
//---------------------------------------------------------------------------
function DXBestBackFormat(HighDepth: Boolean; Width, Height,
 Refresh: Integer): TD3DFormat;

//---------------------------------------------------------------------------
// DXGetDisplayFormat()
//
// Retreives the current display format.
// In case of failure, D3DFMT_UNKNOWN is returned.
//---------------------------------------------------------------------------
function DXGetDisplayFormat(): TD3DFormat;

//---------------------------------------------------------------------------
// DXGetDisplayFormat()
//
// Attempts to find an available format for depth-buffer, based on specified
// preference.
//
// NOTICE: The availability of stencil buffer is *NOT* guaranteed!
//---------------------------------------------------------------------------
function DXBestDepthFormat(HighDepth: Boolean;
 BackFormat: TD3DFormat): TD3DFormat;

//---------------------------------------------------------------------------
// DXApproxFormat()
//
// Determines the best format that complies with the requested quality and
// alpha configuration.
//---------------------------------------------------------------------------
function DXApproxFormat(Quality: TAsphyreQuality;
 AlphaLevel: TAlphaLevel; Usage: Cardinal): TD3DFormat;

//---------------------------------------------------------------------------
// FormatToD3D()
//
// Converts Asphyre-compliant color format to Direct3D pixel format.
//---------------------------------------------------------------------------
function FormatToD3D(Format: TColorFormat): TD3DFormat;

//---------------------------------------------------------------------------
// D3DToFormat()
//
// Converts Direct3D pixel format to Asphyre-compliant color format.
//---------------------------------------------------------------------------
function D3DToFormat(Fmt: TD3DFormat): TColorFormat;

//---------------------------------------------------------------------------
// D3DColor()
//
// Returns Direct3D representation of the specified color.
//---------------------------------------------------------------------------
function D3DColor(Color: Longword): TD3DColorValue;

//---------------------------------------------------------------------------
// D3DPoint()
//
// Returns Direct3D representation of the specified 3D point/vector.
//---------------------------------------------------------------------------
function D3DPoint(const Point: TPoint3): TD3DVector;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
const
 BackFormats: array[0..4] of TD3DFormat = (
  {  0 } D3DFMT_A8R8G8B8,
  {  1 } D3DFMT_X8R8G8B8,
  {  2 } D3DFMT_A1R5G5B5,
  {  3 } D3DFMT_X1R5G5B5,
  {  4 } D3DFMT_R5G6B5);

//---------------------------------------------------------------------------
 TextureFormats: array[0..9] of TD3DFormat = (
  {  0 } D3DFMT_A8R8G8B8,
  {  1 } D3DFMT_X8R8G8B8,
  {  2 } D3DFMT_A1R5G5B5,
  {  3 } D3DFMT_X1R5G5B5,
  {  4 } D3DFMT_A4R4G4B4,
  {  5 } D3DFMT_X4R4G4B4,
  {  6 } D3DFMT_A8R3G3B2,
  {  7 } D3DFMT_R3G3B2,
  {  8 } D3DFMT_R5G6B5,
  {  9 } D3DFMT_A8);

//---------------------------------------------------------------------------
 DepthFormats: array[0..5] of TD3DFormat = (
  {  0 } D3DFMT_D24S8,
  {  1 } D3DFMT_D24X8,
  {  2 } D3DFMT_D24X4S4,
  {  3 } D3DFMT_D15S1,
  {  4 } D3DFMT_D32,
  {  5 } D3DFMT_D16);

//---------------------------------------------------------------------------
function DXBestBackFormat(HighDepth: Boolean; Width, Height,
 Refresh: Integer): TD3DFormat;
const
 LowFormats : array[0..4] of Longword = (4, 2, 3, 0, 1);
 HighFormats: array[0..4] of Longword = (0, 1, 4, 2, 3);
var
 Mode  : TD3DDisplayMode;
 Index : Integer;
 Format: TD3DFormat;
 ModeCount: Integer;
 ModeIndex: Integer;
 FormatIndex: ^Longword;
begin
 Result:= D3DFMT_UNKNOWN;

 // determine what search list to use
 FormatIndex:= @LowFormats[0];
 if (HighDepth) then FormatIndex:= @HighFormats[0];

 // use the selected search list to look for formats
 for Index:= 0 to 4 do
  begin
   // retreive next format in the list
   Format:= BackFormats[FormatIndex^];

   // cycle through all supported modes for this format
   ModeCount:= Direct3D.GetAdapterModeCount(D3DADAPTER_DEFAULT, Format);
   for ModeIndex:= 0 to ModeCount - 1 do
    begin
     // check if the mode is available
     if (Succeeded(Direct3D.EnumAdapterModes(D3DADAPTER_DEFAULT, Format,
      ModeIndex, Mode))) then
      begin
       if (Integer(Mode.Width) = Width)and(Integer(Mode.Height) = Height)and
        ((Integer(Mode.RefreshRate) = Refresh)or(Refresh = 0)) then
        begin
         Result:= Mode.Format;
         Exit;
        end;
      end;
    end;

   Inc(FormatIndex);
  end;
end;

//---------------------------------------------------------------------------
function DXGetDisplayFormat(): TD3DFormat;
var
 Mode: TD3DDisplayMode;
begin
 Result:= D3DFMT_UNKNOWN;

 if (Succeeded(Direct3D.GetAdapterDisplayMode(D3DADAPTER_DEFAULT, Mode))) then
  Result:= Mode.Format;
end;

//--------------------------------------------------------------------------
function DXBestDepthFormat(HighDepth: Boolean;
 BackFormat: TD3DFormat): TD3DFormat;
const
 HighFormats: array[0..5] of Integer = (4, 0, 2, 1, 3, 5);
 LowFormats : array[0..5] of Integer = (5, 3, 4, 0, 2, 1);
var
 FormatIndex: ^Longword;
 Index: Integer;
begin
 // determine the search list
 FormatIndex:= @LowFormats[0];
 if (HighDepth) then FormatIndex:= @HighFormats[0];

 // go through the search list
 for Index:= 0 to 5 do
  begin
   if (Succeeded(Direct3D.CheckDeviceFormat(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL,
    BackFormat, D3DUSAGE_DEPTHSTENCIL, D3DRTYPE_SURFACE,
    DepthFormats[FormatIndex^]))) then
    begin
     Result:= DepthFormats[FormatIndex^];
     Exit;
    end;

   Inc(FormatIndex);
  end;

 Result:= D3DFMT_UNKNOWN;
end;

//--------------------------------------------------------------------------
function DXTexFormatAvail(Format: TD3DFormat; Usage: Cardinal): Boolean;
begin
 Result:= Succeeded(Direct3D.CheckDeviceFormat(D3DADAPTER_DEFAULT,
  D3DDEVTYPE_HAL, PresentParams.BackBufferFormat, Usage, D3DRTYPE_TEXTURE,
  Format));
end;

//--------------------------------------------------------------------------
function DXSearchTexFormat(FirstIndex: PInteger; Count: Integer;
 Usage: Cardinal): TD3DFormat;
var
 i: Integer;
 ReadIndex: PInteger;
begin
 ReadIndex:= FirstIndex;
 for i:= 0 to Count - 1 do
  begin
   if (DXTexFormatAvail(TextureFormats[ReadIndex^], Usage)) then
    begin
     Result:= TextureFormats[ReadIndex^];
     Exit;
    end;

   Inc(ReadIndex);
  end;

 Result:= D3DFMT_UNKNOWN;
end;

//--------------------------------------------------------------------------
function DXApproxFormat(Quality: TAsphyreQuality;
 AlphaLevel: TAlphaLevel; Usage: Cardinal): TD3DFormat;
const
 AlphaExclusive: array[0..4] of Integer = (9, 6, 0, 4, 2);
 AlphaFull_low : array[0..3] of Integer = (4, 0, 2, 6);
 AlphaFull_med : array[0..3] of Integer = (4, 0, 6, 2);
 AlphaFull_high: array[0..3] of Integer = (0, 4, 6, 2);
 AlphaMasked   : array[0..3] of Integer = (2, 4, 0, 6);
 AlphaNo_low   : array[0..4] of Integer = (7, 8, 3, 5, 1);
 AlphaNo_med   : array[0..4] of Integer = (8, 1, 3, 5, 7);
 AlphaNo_high  : array[0..4] of Integer = (1, 8, 3, 5, 7);
begin
 Result:= D3DFMT_UNKNOWN;

 case AlphaLevel of
  // -> NO Alpha-Channel
  alNone:
   begin
    case Quality of
     aqLow   : Result:= DXSearchTexFormat(@AlphaNo_low[0],  5, Usage);
     aqMedium: Result:= DXSearchTexFormat(@AlphaNo_med[0],  5, Usage);
     aqHigh  : Result:= DXSearchTexFormat(@AlphaNo_high[0], 5, Usage);
    end;
   end;
  // -> BOOL Alpha-Channel
  alMask:
   Result:= DXSearchTexFormat(@AlphaMasked[0], 4, Usage);
  // -> FULL Alpha-Channel
  alFull:
   begin
    case Quality of
     aqLow   : Result:= DXSearchTexFormat(@AlphaFull_low[0],  4, Usage);
     aqMedium: Result:= DXSearchTexFormat(@AlphaFull_med[0],  4, Usage);
     aqHigh  : Result:= DXSearchTexFormat(@AlphaFull_high[0], 4, Usage);
    end;
   end;
  // -> EXCLUSIVE Alpha-Channel
  alExclusive:
   Result:= DXSearchTexFormat(@AlphaExclusive[0], 5, Usage);
 end;
end;

//--------------------------------------------------------------------------
function FormatToD3D(Format: TColorFormat): TD3DFormat;
begin
 Result:= D3DFMT_UNKNOWN;
 case Format of
  COLOR_R3G3B2  : Result:= D3DFMT_R3G3B2;
  COLOR_R5G6B5  : Result:= D3DFMT_R5G6B5;
  COLOR_X8R8G8B8: Result:= D3DFMT_X8R8G8B8;
  COLOR_X1R5G5B5: Result:= D3DFMT_X1R5G5B5;
  COLOR_X4R4G4B4: Result:= D3DFMT_X4R4G4B4;
  COLOR_A8R8G8B8: Result:= D3DFMT_A8R8G8B8;
  COLOR_A1R5G5B5: Result:= D3DFMT_A1R5G5B5;
  COLOR_A4R4G4B4: Result:= D3DFMT_A4R4G4B4;
  COLOR_A8R3G3B2: Result:= D3DFMT_A8R3G3B2;
  COLOR_A8      : Result:= D3DFMT_A8;
 end;
end;

//---------------------------------------------------------------------------
function D3DToFormat(Fmt: TD3DFormat): TColorFormat;
begin
 Result:= COLOR_UNKNOWN;
 case Fmt of
  D3DFMT_R3G3B2  : Result:= COLOR_R3G3B2;
  D3DFMT_R5G6B5  : Result:= COLOR_R5G6B5;
  D3DFMT_X8R8G8B8: Result:= COLOR_X8R8G8B8;
  D3DFMT_X1R5G5B5: Result:= COLOR_X1R5G5B5;
  D3DFMT_X4R4G4B4: Result:= COLOR_X4R4G4B4;
  D3DFMT_A8R8G8B8: Result:= COLOR_A8R8G8B8;
  D3DFMT_A1R5G5B5: Result:= COLOR_A1R5G5B5;
  D3DFMT_A4R4G4B4: Result:= COLOR_A4R4G4B4;
  D3DFMT_A8R3G3B2: Result:= COLOR_A8R3G3B2;
  D3DFMT_A8      : Result:= COLOR_A8;
 end;
end;

//--------------------------------------------------------------------------
function D3DColor(Color: Longword): TD3DColorValue;
begin
 Result.r:= (Color and $FF) / 255.0;
 Result.g:= ((Color shr 8) and $FF) / 255.0;
 Result.b:= ((Color shr 16) and $FF) / 255.0;
 Result.a:= ((Color shr 24) and $FF) / 255.0;
end;

//--------------------------------------------------------------------------
function D3DPoint(const Point: TPoint3): TD3DVector;
begin
 Result.x:= Point.x;
 Result.y:= Point.y;
 Result.z:= Point.z;
end;

//---------------------------------------------------------------------------
end.

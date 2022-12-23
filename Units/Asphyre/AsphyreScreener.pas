unit AsphyreScreener;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Windows, Types, Classes, SysUtils, Direct3D9, DXBase, AsphyreDef,
 AsphyreBmpLoad, AsphyreBmp;

//---------------------------------------------------------------------------
type
//---------------------------------------------------------------------------
 TAsphyreScreener = class(TComponent)
 private
  FFileName: string;
  FAutoInc : Boolean;

  function FindName(): string;
 public
  function Take(): Boolean;

  constructor Create(AOwner: TComponent); override;
 published
  property FileName: string read FFileName write FFileName;
  property AutoInc : Boolean read FAutoInc write FAutoInc;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TAsphyreScreener.Create(AOwner: TComponent);
begin
 inherited;

 FFileName:= 'screen.jpg';
 FAutoInc := True;
end;

//---------------------------------------------------------------------------
function TAsphyreScreener.FindName: string;
var
 i, pPos: Integer;
 FileBase: string;
 FileExt : string;
begin
 if (FAutoInc) then
  begin
   pPos:= Pos('.', FFileName);
   if (pPos <> 0) then
    begin
     FileBase:= Copy(FFileName, 1, pPos - 1);
     FileExt := Copy(FFileName, pPos, (Length(FFileName) - pPos) + 1);
    end else
    begin
     FileBase:= FFileName;
     FileExt := '.jpg';
    end; 

   i:= 0;
   repeat
    Result:= IntToStr(i);
    while (Length(Result) < 3) do Result:= '0' + Result;
    Result:= FileBase + Result + FileExt;
    Inc(i);
   until (not FileExists(Result)); 
  end else Result:= FFileName;
end;

//---------------------------------------------------------------------------
function TAsphyreScreener.Take(): Boolean;
var
 Mode: TD3DDisplayMode;
 Surface: IDirect3DSurface9;
 Image: TBitmapEx;
 Index: Integer;
 LockedRect: TD3DLocked_Rect;
 Source: Pointer;
begin
 // (1) Verify initial conditions.
 if (Direct3DDevice = nil)or(Direct3D = nil) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Retreive current display mode.
 Result:= Succeeded(Direct3D.GetAdapterDisplayMode(D3DADAPTER_DEFAULT, Mode));
 if (not Result) then Exit;

 // (3) Create off-screen surface to contain screenshot.
 Result:= Succeeded(Direct3DDevice.CreateOffscreenPlainSurface(Mode.Width,
  Mode.Height, D3DFMT_A8R8G8B8, D3DPOOL_SYSTEMMEM, Surface, nil));
 if (not Result) then Exit;

 // (4) Retreive front-buffer data.
 Result:= Succeeded(Direct3DDevice.GetFrontBufferData(0, Surface));
 if (not Result) then
  begin
   Surface:= nil;
   Exit;
  end;

 // (5) Lock our off-screen surface to get direct access to pixel data.
 Result:= Succeeded(Surface.LockRect(LockedRect, nil, D3DLOCK_READONLY));
 if (not Result) then
  begin
   Surface:= nil;
   Exit;
  end;

 // (6) Create a standard windows bitmap.
 Image:= TBitmapEx.Create();
 Image.SetSize(Mode.Width, Mode.Height);

 // (7) Copy scanline data to windows bitmap.
 for Index:= 0 to Image.Height - 1 do
  begin
   Source:= Pointer(Integer(LockedRect.pBits) + (LockedRect.Pitch * Index));
   Move(Source^, Image.Scanline[Index]^, Image.Width * 4);
  end;

 // (8) Unlock and release the surface
 Surface.UnlockRect();
 Surface:= nil;

 // (9) Save the bitmap to disk.
 Image.SetAlpha(255);
 Result:= SaveBitmap(FindName(), Image, ifAuto);

 // (10) Release windows bitmap.
 Image.Free();
end;

//---------------------------------------------------------------------------
end.

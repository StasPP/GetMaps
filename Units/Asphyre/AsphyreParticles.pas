unit AsphyreParticles;
//---------------------------------------------------------------------------
// AsphyreParticles.pas                                 Modified: 01-Jan-2006
// Extreme Particle Engine                                        Version 1.0
//
// NOTICE: This unit and its component are deprecated and may no longer be
// supported in the next releases.
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
 Types, Classes, Controls, Graphics, Math, AsphyreDef, AsphyreImages,
 AsphyreCanvas, AsphyreDevices, Vectors2;

//---------------------------------------------------------------------------
type
 TAsphyreParticles = class; // this class is defined below

//---------------------------------------------------------------------------
 TAsphyreParticle = class
 private
  FOwner: TAsphyreParticles;

  FPrev: TAsphyreParticle;
  FNext: TAsphyreParticle;

  FAccel   : TPoint2;
  FPosition: TPoint2;
  FVelocity: TPoint2;

  FZOrder : Integer;
  FCurLife: Integer;
  FMaxLife: Integer;

  procedure SetOwner(const Value: TAsphyreParticles);

  procedure SetNext(const Value: TAsphyreParticle);
  procedure SetPrev(const Value: TAsphyreParticle);

  procedure SetZOrder(const Value: Integer);
 protected
  // links previous and next objects leaving this object unconnected
  procedure Unlink();
 public
  property Owner: TAsphyreParticles read FOwner write SetOwner;

  property Prev: TAsphyreParticle read FPrev write SetPrev;
  property Next: TAsphyreParticle read FNext write SetNext;

  property ZOrder: Integer read FZOrder write SetZOrder;

  property Position: TPoint2 read FPosition write FPosition;
  property Velocity: TPoint2 read FVelocity write FVelocity;
  property Accel   : TPoint2 read FAccel write FAccel;

  property CurLife: Integer read FCurLife write FCurLife;
  property MaxLife: Integer read FMaxLife write FMaxLife;

  function Move(): Boolean; virtual;
  procedure Draw(); virtual; abstract;

  constructor Create(AOwner: TAsphyreParticles; AZOrder: Integer); virtual;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TImageParticle = class(TAsphyreParticle)
 private
  FDrawOp: Cardinal;
  FColors: TColor4;
  FSize  : TPoint2;
  FImageIndex: Integer;

  FMiddle  : TPoint2;
  FAngle   : Real;
  FAngleVel: Real;

  procedure SetImageIndex(const Value: Integer);
 protected
  procedure DrawEx(Canvas: TAsphyreCanvas); virtual;
 public
  property ImageIndex: Integer read FImageIndex write SetImageIndex;

  property Size  : TPoint2 read FSize write FSize;
  property DrawOp: Cardinal read FDrawOp write FDrawOp;
  property Colors: TColor4 read FColors write FColors;

  property Middle: TPoint2 read FMiddle write FMiddle;

  property Angle   : Real read FAngle write FAngle;
  property AngleVel: Real read FAngleVel write FAngleVel;

  function Move(): Boolean; override;
  procedure Draw(); override;

  constructor Create(AOwner: TAsphyreParticles; AOrderIndex: Integer); override;
 end;

//---------------------------------------------------------------------------
 TAsphyreParticles = class(TAsphyreDeviceSubscriber)
 private
  FCanvas: TAsphyreCanvas;
  FImages: TAsphyreImages;

  function GetCount(): Integer;
 protected
  ListHead, ListTail: TAsphyreParticle;

  procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  function Linked(Obj: TAsphyreParticle): Boolean;
  procedure Insert(Obj: TAsphyreParticle); virtual;
  procedure UnlinkObj(Obj: TAsphyreParticle); virtual;
 public
  property Count: Integer read GetCount;

  constructor Create(AOwner: TComponent); override;

  procedure Clear();
  procedure Update();
  procedure Render();

  function CreateImage(ImageNum: Integer; const Position: TPoint2; Cycle,
   DrawOp: Integer): TImageParticle; overload;
 published
  property Canvas: TAsphyreCanvas read FCanvas write FCanvas;
  property Images: TAsphyreImages read FImages write FImages;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TAsphyreParticle.Create(AOwner: TAsphyreParticles; AZOrder: Integer);
begin
 inherited Create();

 FPrev:= nil;
 FNext:= nil;
 FZOrder:= AZOrder;
 FOwner:= AOwner;

 FPosition:= Point2(0, 0);
 FVelocity:= Point2(0, 0);
 FAccel   := Point2(0, 0);
 FCurLife:= 0;
 FMaxLife:= 1;

 if (Assigned(FOwner)) then FOwner.Insert(Self);
end;

//---------------------------------------------------------------------------
destructor TAsphyreParticle.Destroy();
begin
 Unlink();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticle.SetPrev(const Value: TAsphyreParticle);
var
 UnPrev: TAsphyreParticle;
begin
 // (1) Determine previous forward link.
 UnPrev:= nil;
 if (FPrev <> nil)and(FPrev.Next = Self) then UnPrev:= FPrev;
 // (2) Update the link.
 FPrev:= Value;
 // (3) Remove previous forward link.
 if (UnPrev <> nil) then UnPrev.Next:= nil;
 // (4) Insert forward link.
 if (FPrev <> nil)and(FPrev.Next <> Self) then FPrev.Next:= Self;
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticle.SetNext(const Value: TAsphyreParticle);
var
 UnNext: TAsphyreParticle;
begin
 // (1) Determine previous backward link.
 UnNext:= nil;
 if (FNext <> nil)and(FNext.Prev = Self) then UnNext:= FNext;
 // (2) Update the link.
 FNext:= Value;
 // (3) Remove previous backward link.
 if (UnNext <> nil) then UnNext.Prev:= nil;
 // (4) Insert backward link.
 if (FNext <> nil)and(FNext.Prev <> Self) then FNext.Prev:= Self;
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticle.Unlink();
var
 WasPrev, WasNext: TAsphyreParticle;
begin
 // (1) Unlink the object from its owner.
 if (Assigned(FOwner)) then FOwner.UnlinkObj(Self);

 // (2) Unlink previous node.
 WasPrev:= FPrev;
 WasNext:= FNext;
 FPrev:= nil;
 FNext:= nil;

 if (WasPrev = nil) then
  begin
   if (WasNext <> nil) then WasNext.Prev:= nil;
  end else WasPrev.Next:= WasNext;
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticle.SetOwner(const Value: TAsphyreParticles);
begin
 // (1) Unlink the node.
 Unlink();

 // (2) Change owner.
 FOwner:= Value;

 // (3) Re-insert the node.
 if (Assigned(FOwner)) then FOwner.Insert(Self);
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticle.SetZOrder(const Value: Integer);
begin
 // (1) Unlink the node.
 Unlink();
 // (2) Update z-order.
 FZOrder:= Value;
 // (3) Re-insert the node.
 if (Assigned(FOwner)) then FOwner.Insert(Self);
end;

//---------------------------------------------------------------------------
function TAsphyreParticle.Move(): Boolean;
begin
 FVelocity.X:= FVelocity.X + FAccel.X;
 FVelocity.Y:= FVelocity.Y + FAccel.Y;

 FPosition.X:= FPosition.X + FVelocity.X;
 FPosition.Y:= FPosition.Y + FVelocity.Y;

 Inc(FCurLife);
 Result:= FCurLife < FMaxLife;
end;

//---------------------------------------------------------------------------
constructor TImageParticle.Create(AOwner: TAsphyreParticles; AOrderIndex: Integer);
begin
 inherited;

 FColors    := clWhite4;
 FDrawOp    := fxBlend;
 FImageIndex:= -1;
 FSize      := Point2(1.0, 1.0);

 FMiddle    := Point2(0.0, 0.0);
 FAngle     := Random * Pi * 2.0;
 FAngleVel  := 0;
end;

//---------------------------------------------------------------------------
procedure TImageParticle.SetImageIndex(const Value: Integer);
var
 Image: TAsphyreImage;
begin
 // attempt to retreive image parameters
 if (FImageIndex = -1)and(Value >= 0)and(Assigned(Owner)) then
  begin
   Image:= Owner.Images[Value];
   if (Assigned(Image)) then
    begin
     FSize:= Point2(Image.VisibleSize.x, Image.VisibleSize.y);
     FMiddle:= Point2(FSize.X / 2.0, FSize.Y / 2.0);
    end;
  end;

 FImageIndex:= Value;
end;

//---------------------------------------------------------------------------
function TImageParticle.Move(): Boolean;
begin
 // 1. update angle
 FAngle:= FAngle + FAngleVel;
 while (FAngle > Pi * 2) do FAngle:= FAngle - (Pi * 2);

 // 2. move the particle
 Result:= inherited Move();
end;

//---------------------------------------------------------------------------
procedure TImageParticle.Draw();
var
 Canvas: TAsphyreCanvas;
 Device: TAsphyreDevice;
begin
 // 1. acquire objects
 Device:= nil;
 Canvas:= nil;
 if (Assigned(Owner)) then
  begin
   Device:= Owner.Device;
   Canvas:= Owner.Canvas;
  end;

 // 2. check if the device is valid
 if (Device = nil)or(Canvas = nil) then Exit;

 // 3. check and/or update position
 if (not OverlapRect(Bounds(Floor(FPosition.x - Middle.x), Floor(FPosition.y -
  Middle.y), Ceil(Size.x) + 1, Ceil(Size.y) + 1), Bounds(0, 0,
  Device.Width, Device.Height))) then Exit;

 // 5. call render routine
 DrawEx(Canvas);
end;

//---------------------------------------------------------------------------
procedure TImageParticle.DrawEx(Canvas: TAsphyreCanvas);
var
 Image  : TAsphyreImage;
 Pattern: Integer;
begin
 // 1. attempt to retreive the image
 Image:= nil;
 if (Assigned(Owner))and(Assigned(Owner.Images)) then Image:= Owner.Images[ImageIndex];

 // 2. check if the image is valid
 if (Image = nil) then Exit;

 // 3. find the specific pattern and the 256-based angle
 Pattern:= 0;
 if (FMaxLife > 0) then
  Pattern:= (FCurLife * Image.PatternCount) div FMaxLife;

 // 4. finally render it on the screen
 Canvas.TexMap(Image, pRotate4(FPosition, FSize, FMiddle, FAngle, 1.0),
  FColors, AsphyreDef.tPattern(Pattern), FDrawOp);
end;

//---------------------------------------------------------------------------
constructor TAsphyreParticles.Create(AOwner: TComponent);
begin
 inherited;

 ListHead:= nil;
 ListTail:= nil;

 FImages:= TAsphyreImages(FindHelper(TAsphyreImages));
 FCanvas:= TAsphyreCanvas(FindHelper(TAsphyreCanvas));
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticles.Notification(AComponent: TComponent;
 Operation: TOperation);
begin
 inherited;

 case Operation of
  opInsert:
   begin
    if (AComponent is TAsphyreImages)and(not Assigned(FImages)) then
     FImages:= TAsphyreImages(AComponent);

    if (AComponent is TAsphyreCanvas)and(not Assigned(FCanvas)) then
     FCanvas:= TAsphyreCanvas(AComponent);
   end;

  opRemove:
   begin
    if (AComponent = FImages) then FImages:= nil;
    if (AComponent = FCanvas) then FCanvas:= nil;
   end;
 end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticles.Clear();
var
 Aux, Prev: TAsphyreParticle;
begin
 Aux:= ListTail;
 while (Aux <> nil) do
  begin
   Prev:= Aux.Prev;
   Aux.Free();
   Aux:= Prev;
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreParticles.GetCount(): Integer;
var
 Aux: TAsphyreParticle;
begin
 Result:= 0;
 Aux:= ListHead;
 while (Aux <> nil) do
  begin
   Inc(Result);
   Aux:= Aux.Next;
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreParticles.Linked(Obj: TAsphyreParticle): Boolean;
var
 Aux0, Aux1: TAsphyreParticle;
begin
 // 1. validate initial object
 Result:= False;
 if (Obj = nil) then Exit;

 // 2. start from opposite ends
 Aux0:= ListHead;
 Aux1:= ListTail;

 // 3. do bi-directional search
 while (Aux0 <> nil)or(Aux1 <> nil) do
  begin
   // 3 (a). compare the objects
   if (Aux0 = Obj)or(Aux1 = Obj) then
    begin
     Result:= True;
     Exit;
    end;

   // 3 (b). advance in the list
   if (Aux0 <> nil) then Aux0:= Aux0.Next;
   if (Aux1 <> nil) then Aux1:= Aux1.Prev;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticles.Insert(Obj: TAsphyreParticle);
var
 OIndex: Integer;
 Aux: TAsphyreParticle;
begin
 // 1. do not accept NULL objects
 if (Obj = nil) then Exit;

 // 2. retreive order index
 OIndex:= Obj.ZOrder;

 // 3. check if the particle is already linked into the list
 if(Linked(Obj)) then Exit;

 // 4. if no items available - create a first element
 if (ListHead = nil) then
  begin
   Obj.Prev:= nil;
   Obj.Next:= nil;
   ListHead:= Obj;
   ListTail:= ListHead;
   Exit;
  end;

 // 5. insert BEFORE first element
 if (OIndex <= ListHead.ZOrder) then
  begin
   Obj.Prev:= nil;
   Obj.Next:= ListHead;
   ListHead:= Obj;
   Exit;
  end;

 // 6. insert AFTER first element
 if (OIndex >= ListTail.ZOrder) then
  begin
   Obj.Next:= nil;
   ListTail.Next:= Obj;
   ListTail:= Obj;
   Exit;
  end;

 // 7. search using either fordward or backward method
 if (Abs(Int64(ListHead.ZOrder) - OIndex) < Abs(Int64(ListTail.ZOrder) - OIndex)) then
  begin
   // 7 (a) I. forward search
   Aux:= ListHead;
   while (Aux.Next.ZOrder < OIndex) do Aux:= Aux.Next;

   // 7 (a) II. update links
   Obj.Next:= Aux.Next;
   Obj.Prev:= Aux;
  end else
  begin
   // 7 (b) I. backward search
   Aux:= ListTail;
   while (Aux.Prev.ZOrder > OIndex) do Aux:= Aux.Prev;

   // 7 (b) II. update links
   Obj.Prev:= Aux.Prev;
   Obj.Next:= Aux;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticles.UnlinkObj(Obj: TAsphyreParticle);
begin
 if (ListTail = Obj) then ListTail:= ListTail.Prev;

 if (ListHead = Obj) then
  begin 
   ListHead:= nil;
   if (Obj.Next <> nil) then ListHead:= Obj.Next;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticles.Update();
var
 Aux, pNext: TAsphyreParticle;
 PForward: Boolean;
begin
 // 1. decide random direction for processing
 PForward:= Random(2) = 0;
 Aux:= ListHead;
 if (not PForward) then Aux:= ListTail;

 // 2. update all particles
 while (Aux <> nil) do
  begin
   // 2 (a). determine next particle
   pNext:= Aux.Next;
   if (not PForward) then pNext:= Aux.Prev;

   // 2 (b). move current particle
   if (not Aux.Move()) then Aux.Free();

   // 2 (c). advance in the list
   Aux:= pNext;
  end; // while
end;

//---------------------------------------------------------------------------
function TAsphyreParticles.CreateImage(ImageNum: Integer;
 const Position: TPoint2; Cycle, DrawOp: Integer): TImageParticle;
var
 Aux: TImageParticle;
begin
 Aux:= TImageParticle.Create(Self, ImageNum);
 Aux.Position  := Position;
 Aux.ImageIndex:= ImageNum;
 Aux.DrawOp    := DrawOp;
 Aux.Angle     := Random * Pi * 2.0;
 Aux.MaxLife   := Cycle;

 Result:= Aux;
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticles.Render();
var
 Aux: TAsphyreParticle;
begin
 Aux:= ListHead;

 while (Aux <> nil) do
  begin
   Aux.Draw();
   Aux:= Aux.Next;
  end;
end;

//---------------------------------------------------------------------------
end.

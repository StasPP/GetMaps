unit AsphyreParticles3D;
//---------------------------------------------------------------------------
// AsphyreParticles3D.pas                               Modified: 12-Oct-2005
// Particle effects in 3D                                        Version 1.01
//---------------------------------------------------------------------------
//  Changes since v1.0:
//    * Pattern calculation fix, thanks to Steffen Norgaard!
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
 Types, Classes, AsphyreDef, AsphyreMath, AsphyreBillboards, AsphyreFacing,
 AsphyreImages;

//---------------------------------------------------------------------------
type
 TAsphyreParticles3D = class; // this class is defined below

//---------------------------------------------------------------------------
 TAsphyreParticle3D = class
 private
  FOwner: TAsphyreParticles3D;

  FNext : TAsphyreParticle3D;

  FAccel   : TPoint3;
  FPosition: TPoint3;
  FVelocity: TPoint3;

  FCurRange: Integer;
  FMaxRange: Integer;

  procedure SetOwner(const Value: TAsphyreParticles3D);
 public
  property Owner: TAsphyreParticles3D read FOwner write SetOwner;
  property Next : TAsphyreParticle3D read FNext write FNext;

  property Position: TPoint3 read FPosition write FPosition;
  property Velocity: TPoint3 read FVelocity write FVelocity;
  property Accel   : TPoint3 read FAccel write FAccel;

  property CurRange: Integer read FCurRange write FCurRange;
  property MaxRange: Integer read FMaxRange write FMaxRange;

  function Move(): Boolean; virtual;
  procedure Render(); virtual; abstract;

  constructor Create(AOwner: TAsphyreParticles3D); virtual;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
// Animated particle implementation
//---------------------------------------------------------------------------
 TAsphyreParticleBB = class(TAsphyreParticle3D)
 private
  FImageIndex: Integer;
  FSize      : TPoint2;
  FColors    : TColor4;
  FBlendOp   : Cardinal;
  FAnimSpeed : Real;

 public
  property ImageIndex: Integer read FImageIndex write FImageIndex;
  property Size      : TPoint2 read FSize write FSize;
  property Colors    : TColor4 read FColors write FColors;
  property BlendOp   : Cardinal read FBlendOp write FBlendOp;
  property AnimSpeed : Real read FAnimSpeed write FAnimSpeed;

  procedure Render(); override;

  constructor Create(AOwner: TAsphyreParticles3D); override;
 end;

//---------------------------------------------------------------------------
// Animated "facing" particle
//---------------------------------------------------------------------------
 TAsphyreParticleFc = class(TAsphyreParticleBB)
 private
  FVecA: TPoint3;
  FVecB: TPoint3;

 public
  property VecA: TPoint3 read FVecA write FVecA;
  property VecB: TPoint3 read FVecB write FVecB;

  procedure Render(); override;
 end;

 //---------------------------------------------------------------------------
 TAsphyreParticles3D = class(TComponent)
 private
  ListHead  : TAsphyreParticle3D;
  FAsphyreBB: TAsphyreBB;
  FImages   : TAsphyreImages;
  FAsphyreFacing: TAsphyreFacing;

  function GetCount(): Integer;
  function Linked(Obj: TAsphyreParticle3D): Boolean;
  procedure Insert(Obj: TAsphyreParticle3D); virtual;
  procedure UnlinkObj(Obj: TAsphyreParticle3D); virtual;
 protected
  procedure Notification(AComponent: TComponent; Operation: TOperation); override;
 public
  property Count: Integer read GetCount;

  constructor Create(AOwner: TComponent); override;

  procedure RemoveAll();
  procedure Update();
  procedure Render();

  function CreateParticleBB(const Point: TPoint3; const Size: TPoint2;
   ImageIndex, Lifespan: Integer): TAsphyreParticleBB;
  function CreateParticleFC(const Point, VecA, VecB: TPoint3; ImageIndex,
   Lifespan: Integer): TAsphyreParticleFC;
 published
  property AsphyreBB: TAsphyreBB read FAsphyreBB write FAsphyreBB;
  property AsphyreFacing: TAsphyreFacing read FAsphyreFacing write FAsphyreFacing;
  property Images   : TAsphyreImages read FImages write FImages;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TAsphyreParticle3D.Create(AOwner: TAsphyreParticles3D);
begin
 inherited Create();

 FOwner   := AOwner;

 FNext    := nil;

 FPosition:= ZeroVector3;
 FVelocity:= ZeroVector3;
 FAccel   := ZeroVector3;
 FCurRange:= 0;
 FMaxRange:= 1;

 if (Assigned(FOwner)) then FOwner.Insert(Self);
end;

//---------------------------------------------------------------------------
destructor TAsphyreParticle3D.Destroy();
begin
 if (Assigned(FOwner)) then
  FOwner.UnlinkObj(Self);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticle3D.SetOwner(const Value: TAsphyreParticles3D);
begin
 if (Assigned(FOwner)) then FOwner.UnlinkObj(Self);
 FOwner:= Value;
 if (Assigned(FOwner)) then FOwner.Insert(Self);
end;

//---------------------------------------------------------------------------
function TAsphyreParticle3D.Move(): Boolean;
begin
 FVelocity:= VecAdd3(FVelocity, FAccel);
 FPosition:= VecAdd3(FPosition, FVelocity);
 Inc(FCurRange);

 Result:= (FCurRange < FMaxRange);
end;

//---------------------------------------------------------------------------
constructor TAsphyreParticleBB.Create(AOwner: TAsphyreParticles3D);
begin
 inherited;

 FImageIndex:= -1;
 FSize      := Point2(1.0, 1.0);
 FColors    := clWhite4;
 FBlendOp   := fxBlend;
 FAnimSpeed := 1.0;
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticleBB.Render();
var
 Image  : TAsphyreImage;
 Pattern: Integer;
begin
 // step 1. retreive the billboard image
 Image:= nil;
 if (Assigned(FOwner))and(Assigned(FOwner.Images)) then
  Image:= FOwner.Images[FImageIndex];

 // step 2. verify if the image is valid
 if (Image = nil) then Exit;

 // step 3. calculate pattern index
 Pattern:= Trunc((FCurRange * Image.PatternCount * FAnimSpeed) / FMaxRange);

 // step 4. render the billboard
 if (Assigned(FOwner))and(Assigned(FOwner.AsphyreBB)) then
  FOwner.AsphyreBB.Draw(FPosition, FSize, Image, FColors, tPattern(Pattern), FBlendOp);
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticleFc.Render();
var
 Points : TQuadPoints3;
 Image  : TAsphyreImage;
 Pattern: Integer;
begin
 // step 1. retreive the billboard image
 Image:= nil;
 if (Assigned(FOwner))and(Assigned(FOwner.Images)) then
  Image:= FOwner.Images[FImageIndex];

 // step 2. verify if the image is valid
 if (Image = nil) then Exit;

 // step 3. calculate pattern index
 Pattern:= Trunc((FCurRange * Image.PatternCount * FAnimSpeed) / FMaxRange);

 // step 4. particle orientation
 Points[0]:= VecSub3(FPosition, VecScale3(VecAdd3(FVecA, FVecB), 0.5));
 Points[1]:= VecAdd3(FPosition, VecScale3(VecSub3(FVecB, FVecA), 0.5));
 Points[2]:= VecAdd3(FPosition, VecScale3(VecAdd3(FVecA, FVecB), 0.5));
 Points[3]:= VecAdd3(FPosition, VecScale3(VecSub3(FVecA, FVecB), 0.5));

 // step 4. render the billboard
 if (Assigned(FOwner))and(Assigned(FOwner.AsphyreFacing)) then
  FOwner.AsphyreFacing.Draw(Points, Image, FColors, tPattern(Pattern), FBlendOp);
end;

//---------------------------------------------------------------------------
constructor TAsphyreParticles3D.Create(AOwner: TComponent);
var
 i: Integer;
begin
 inherited;

 if (csDesigning in ComponentState)and(Assigned(AOwner)) then
  for i:= 0 to AOwner.ComponentCount - 1 do
   begin
    if (AOwner.Components[i] is TAsphyreFacing) then
     FAsphyreFacing:= TAsphyreFacing(AOwner.Components[i]);

    if (AOwner.Components[i] is TAsphyreBB) then
     FAsphyreBB:= TAsphyreBB(AOwner.Components[i]);

    if (AOwner.Components[i] is TAsphyreImages) then
     FImages:= TAsphyreImages(AOwner.Components[i]);
   end;

 ListHead:= nil;
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticles3D.Notification(AComponent: TComponent; Operation: TOperation);
begin
 inherited;

 case Operation of
  opInsert:
   begin
    if (AComponent is TAsphyreFacing)and(not Assigned(FAsphyreFacing)) then
     FAsphyreFacing:= TAsphyreFacing(AComponent);

    if (AComponent is TAsphyreBB)and(not Assigned(FAsphyreBB)) then
     FAsphyreBB:= TAsphyreBB(AComponent);

    if (AComponent is TAsphyreImages)and(not Assigned(FImages)) then
     FImages:= TAsphyreImages(AComponent);
   end;

  opRemove:
   begin
    if (AComponent = FAsphyreFacing) then FAsphyreFacing:= nil;
    if (AComponent = FAsphyreBB) then FAsphyreBB:= nil;
    if (AComponent = FImages) then FImages:= nil;
   end;
 end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticles3D.RemoveAll();
var
 Aux, Temp: TAsphyreParticle3D;
begin
 Aux:= ListHead;
 while (Aux <> nil) do
  begin
   Temp:= Aux;
   Aux:= Aux.Next;
   Temp.Free();
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreParticles3D.GetCount(): Integer;
var
 Aux: TAsphyreParticle3D;
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
function TAsphyreParticles3D.Linked(Obj: TAsphyreParticle3D): Boolean;
var
 Aux: TAsphyreParticle3D;
begin
 Result:= False;
 if (Obj = nil)or(ListHead = nil) then Exit;

 Aux:= ListHead;
 while (Aux <> nil) do
  begin
   if (Aux = Obj) then
    begin
     Result:= True;
     Exit;
    end;

   Aux:= Aux.Next;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticles3D.Insert(Obj: TAsphyreParticle3D);
begin
 if (Obj = nil)or(Linked(Obj)) then Exit;

 Obj.Next:= ListHead;
 ListHead:= Obj;
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticles3D.UnlinkObj(Obj: TAsphyreParticle3D);
var
 Prev, Aux: TAsphyreParticle3D;
begin
 if (ListHead = Obj) then
  begin
   ListHead:= ListHead.Next;
   Exit;
  end;

 Prev:= ListHead;
 Aux := ListHead.Next;
 while (Aux <> nil) do
  begin
   if (Aux = Obj) then
    begin
     Prev.Next:= Aux.Next;
     Exit;
    end else
    begin
     Prev:= Aux;
     Aux:= Aux.Next;
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticles3D.Update();
var
 Aux, Next: TAsphyreParticle3D;
begin
 Aux:= ListHead;
 while (Aux <> nil) do
  begin
   Next:= Aux.Next;
   if (not Aux.Move()) then Aux.Free();
   Aux:= Next;
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreParticles3D.Render();
var
 Aux: TAsphyreParticle3D;
begin
 Aux:= ListHead;
 while (Aux <> nil) do
  begin
   Aux.Render();
   Aux:= Aux.Next;
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreParticles3D.CreateParticleBB(const Point: TPoint3;
 const Size: TPoint2; ImageIndex, Lifespan: Integer): TAsphyreParticleBB;
var
 Aux: TAsphyreParticleBB;
begin
 if (not Assigned(FAsphyreBB))or(not Assigned(FImages)) then
  begin
   Result:= nil;
   Exit;
  end;

 Aux:= TAsphyreParticleBB.Create(Self);
 Aux.Position  := Point;
 Aux.Size      := Size;
 Aux.ImageIndex:= ImageIndex;
 Aux.MaxRange  := Lifespan;

 Result:= Aux;
end;

//---------------------------------------------------------------------------
function TAsphyreParticles3D.CreateParticleFC(const Point, VecA, VecB: TPoint3;
 ImageIndex, Lifespan: Integer): TAsphyreParticleFC;
var
 Aux: TAsphyreParticleFC;
begin
 if (not Assigned(FAsphyreFacing))or(not Assigned(FImages)) then
  begin
   Result:= nil;
   Exit;
  end;

 Aux:= TAsphyreParticleFc.Create(Self);
 Aux.Position  := Point;
 Aux.VecA      := VecA;
 Aux.VecB      := VecB;
 Aux.ImageIndex:= ImageIndex;
 Aux.BlendOp   := fxBlend;
 Aux.MaxRange  := Lifespan;

 Result:= Aux;
end;

//---------------------------------------------------------------------------
end.

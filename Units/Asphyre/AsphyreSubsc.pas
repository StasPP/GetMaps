unit AsphyreSubsc;
//---------------------------------------------------------------------------
// AsphyreSubscr.pas                                    Modified: 24-Sep-2005
// Asphyre Publisher/Subscriber pattern implementation            Version 1.0
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
 Types, Classes, SysUtils, AsphyreDef;

//---------------------------------------------------------------------------
type
 TAsphyreSubscriber = class;

//---------------------------------------------------------------------------
 TAsphyrePublisherClass = class of TAsphyrePublisher;

//---------------------------------------------------------------------------
 TAsphyrePublisher = class(TComponent)
 private
  Data: array of TAsphyreSubscriber;
 protected
  procedure Subscribe(Obj: TAsphyreSubscriber);
  procedure Unsubscribe(Obj: TAsphyreSubscriber);
  function FindSubscriber(Obj: TAsphyreSubscriber): Integer;

  function Notify(Msg: Cardinal): Boolean;
 public

  constructor Create(AOwner: TComponent); override;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TAsphyreSubscriber = class(TComponent)
 private
  FPublisher: TAsphyrePublisher;

  procedure SetPublisher(const Value: TAsphyrePublisher);
  procedure SearchForPublisher();
 protected
  function HandleNotice(Msg: Cardinal): Boolean; virtual;
  function PublisherClass(): TAsphyrePublisherClass; virtual;

  procedure Notification(AComponent: TComponent;
   Operation: TOperation); override;
 public

  constructor Create(AOwner: TComponent); override;
  destructor Destroy(); override;
 published
  property Publisher: TAsphyrePublisher read FPublisher write SetPublisher;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TAsphyrePublisher.Create(AOwner: TComponent);
begin
 inherited;

 SetLength(Data, 0);
end;

//---------------------------------------------------------------------------
destructor TAsphyrePublisher.Destroy();
var
 i: Integer;
begin
 // Removing association with objects that are linked to us.
 // This is done by directly accessing FPublisher variable to prevent
 // circular infinite loop.
 for i:= 0 to Length(Data) - 1 do
  Data[i].FPublisher:= nil;

 inherited;
end;

//---------------------------------------------------------------------------
function TAsphyrePublisher.FindSubscriber(Obj: TAsphyreSubscriber): Integer;
var
 i: Integer;
begin
 Result:= -1;
 for i:= 0 to Length(Data) - 1 do
  if (Data[i] = Obj) then
   begin
    Result:= i;
    Break;
   end; 
end;

//---------------------------------------------------------------------------
procedure TAsphyrePublisher.Subscribe(Obj: TAsphyreSubscriber);
var
 Index: Integer;
begin
 // verify if the object is already subscribed
 Index:= FindSubscriber(Obj);
 if (Index <> -1) then Exit;

 // add object to subscription list
 Index:= Length(Data);
 SetLength(Data, Index + 1);

 Data[Index]:= Obj;
end;

//---------------------------------------------------------------------------
procedure TAsphyrePublisher.Unsubscribe(Obj: TAsphyreSubscriber);
var
 i, Index: Integer;
begin
 // find the object to be unsubscribed
 Index:= FindSubscriber(Obj);
 if (Index = -1) then Exit;

 // remove the object from the list
 for i:= Index to Length(Data) - 2 do
  Data[i]:= Data[i + 1];

 SetLength(Data, Length(Data) - 1);
end;

//---------------------------------------------------------------------------
function TAsphyrePublisher.Notify(Msg: Cardinal): Boolean;
var
 i: Integer;
begin
 Result:= True;

 for i:= 0 to Length(Data) - 1 do
  begin
   Result:= Data[i].HandleNotice(Msg);
   if (not Result) then Break;
  end;
end;

//---------------------------------------------------------------------------
constructor TAsphyreSubscriber.Create(AOwner: TComponent);
begin
 inherited;

 SearchForPublisher();
end;

//---------------------------------------------------------------------------
destructor TAsphyreSubscriber.Destroy();
begin
 if (FPublisher <> nil) then FPublisher.Unsubscribe(Self);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreSubscriber.Notification(AComponent: TComponent;
 Operation: TOperation);
begin
 inherited;

 case Operation of
  opInsert:
   begin
    if (AComponent is PublisherClass())and(not Assigned(FPublisher)) then
     Publisher:= TAsphyrePublisher(AComponent);
   end;

  opRemove:
   begin
    if (AComponent = FPublisher) then FPublisher:= nil;
   end;
 end;
end;

//---------------------------------------------------------------------------
function TAsphyreSubscriber.PublisherClass(): TAsphyrePublisherClass;
begin
 Result:= TAsphyrePublisher;
end;

//---------------------------------------------------------------------------
procedure TAsphyreSubscriber.SetPublisher(const Value: TAsphyrePublisher);
begin
 if (FPublisher <> nil)and(FPublisher <> Value) then
  FPublisher.Unsubscribe(Self);

 FPublisher:= Value;

 if (FPublisher <> nil) then FPublisher.Subscribe(Self);
end;

//---------------------------------------------------------------------------
procedure TAsphyreSubscriber.SearchForPublisher();
var
 i: Integer;
 PubClass: TAsphyrePublisherClass;
begin
 if (not (csDesigning in ComponentState)) then Exit;

 PubClass:= PublisherClass();

 for i:= 0 to Owner.ComponentCount - 1 do
  if (Owner.Components[i] is PubClass) then
   begin
    Publisher:= TAsphyrePublisher(Owner.Components[i]);
    Break;
   end;
end;

//---------------------------------------------------------------------------
function TAsphyreSubscriber.HandleNotice(Msg: Cardinal): Boolean;
begin
 Result:= True;
end;

//---------------------------------------------------------------------------
end.

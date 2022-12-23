unit AsphyreScript;
//---------------------------------------------------------------------------
// AsphyreScript.pas                                    Modified: 04-Jan-2006
// Asphyre Entity Script                                          Version 1.0
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
 Types, Classes, SysUtils;

//---------------------------------------------------------------------------
type
 TScriptClass = class of TScript;

//---------------------------------------------------------------------------
 TScript = class
 private
  FParent: TScript;

  FHead: TScript;
  FNext: TScript;

  FTicks: Integer;
  FLife : Integer;
  FViewOrder: Integer;

  ChildList : array of TScript;
  ChildCount: Integer;
  FMarker: Integer;

  function Linked(Sub: TScript): Boolean;
  procedure Link(Sub: TScript);
  procedure Unlink(Sub: TScript);
  procedure InitChildList();
  procedure QuickSort(Left, Right: Integer);
  procedure SortChildList();
 protected
  procedure DoUpdate(); virtual;
  procedure DoDraw(); virtual;
 public
  property Parent: TScript read FParent;

  property Head: TScript read FHead write FHead;
  property Next: TScript read FNext write FNext;

  property ViewOrder: Integer read FViewOrder write FViewOrder;
  property Marker: Integer read FMarker write FMarker;

  property Ticks: Integer read FTicks write FTicks;
  property Life : Integer read FLife write FLife;

  function Update(): Boolean;
  procedure Draw();
  procedure Clear();
  procedure DrawChild(Marker: Integer);

  constructor Create(AParent: TScript); virtual;
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
var
 Script: TScript = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
constructor TScript.Create(AParent: TScript);
begin
 inherited Create();

 FParent:= AParent;

 FHead:= nil;
 FNext:= nil;

 FTicks:= 0;
 FLife := 0;
 FMarker:= -1;

 if (Assigned(FParent)) then FParent.Link(Self);
end;

//---------------------------------------------------------------------------
destructor TScript.Destroy();
begin
 Clear();
 if (FParent <> nil) then FParent.Unlink(Self);

 inherited;
end;

//---------------------------------------------------------------------------
procedure TScript.Clear();
var
 Aux, Next: TScript;
begin
 Aux:= FHead;
 FHead:= nil;

 while (Aux <> nil) do
  begin
   Next:= Aux.Next;

   Aux.Free();
   Aux:= Next;
  end;
end;

//---------------------------------------------------------------------------
function TScript.Linked(Sub: TScript): Boolean;
var
 Aux: TScript;
begin
 Aux:= FHead;
 Result:= (Sub = FHead)and(Sub <> nil);
 
 while (Aux <> nil)and(not Result) do
  begin
   Aux:= Aux.Next;
   Result:= (Aux = Sub);
  end;
end;

//---------------------------------------------------------------------------
procedure TScript.Link(Sub: TScript);
begin
 if (not Linked(Sub)) then
  begin
   Sub.Next:= FHead;
   FHead:= Sub;
  end;
end;

//---------------------------------------------------------------------------
procedure TScript.Unlink(Sub: TScript);
var
 Prev, Aux: TScript;
begin
 if (FHead = Sub)or(FHead = nil) then
  begin
   FHead:= Sub.Next;
   Exit;
  end;

 Prev:= FHead;
 Aux:= FHead.Next;

 while (Aux <> nil) do
  begin
   if (Aux = Sub) then
    begin
     Prev.Next:= Aux.Next;
     Break;
    end;

   Prev:= Aux;
   Aux:= Aux.Next;
  end;
end;

//---------------------------------------------------------------------------
procedure TScript.DoUpdate();
begin
end;

//---------------------------------------------------------------------------
function TScript.Update(): Boolean;
var
 Aux, Next: TScript;
begin
 Aux:= FHead;
 while (Aux <> nil) do
  begin
   Next:= Aux.Next;

   if (not Aux.Update()) then Aux.Free();
   Aux:= Next;
  end;

 DoUpdate();

 Inc(FTicks);
 Result:= (FTicks < FLife);
end;

//---------------------------------------------------------------------------
procedure TScript.DoDraw();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TScript.InitChildList();
var
 Aux: TScript;
 Amount, Index: Integer;
begin
 Amount:= 0;

 Aux:= FHead;
 while (Aux <> nil) do
  begin
   if (Aux.Marker = -1) then Inc(Amount);
   Aux:= Aux.Next;
  end;

 if (Length(ChildList) < Amount) then SetLength(ChildList, Amount);

 Index:= 0;
 Aux:= FHead;
 while (Aux <> nil) do
  begin
   if (Aux.Marker = -1) then
    begin
     ChildList[Index]:= Aux;
     Inc(Index);
    end; 
   Aux:= Aux.Next;
  end;

 ChildCount:= Amount; 
end;

//---------------------------------------------------------------------------
procedure TScript.QuickSort(Left, Right: Integer);
var
 i, j: Integer;
 Aux: TScript;
 z: Integer;
begin
 i:= Left;
 j:= Right;
 z:= ChildList[(Left + Right) shr 1].ViewOrder;

 repeat
  while (ChildList[i].ViewOrder < z) do Inc(i);
  while (z < ChildList[j].ViewOrder) do Dec(j);

  if (i <= j) then
   begin
    Aux:= ChildList[i];
    ChildList[i]:= ChildList[j];
    ChildList[j]:= Aux;

    Inc(i);
    Dec(j);
   end;
 until (i > j);

 if (Left < j) then QuickSort(Left, j);
 if (i < Right) then QuickSort(i, Right);
end;

//---------------------------------------------------------------------------
procedure TScript.SortChildList();
begin
 QuickSort(0, ChildCount - 1);
end;

//---------------------------------------------------------------------------
procedure TScript.Draw();
var
 i: Integer;
begin
 DoDraw();

 InitChildList();
 if (ChildCount > 0) then
  begin
   SortChildList();

   for i:= 0 to ChildCount - 1 do
    ChildList[i].Draw();
  end;
end;

//---------------------------------------------------------------------------
procedure TScript.DrawChild(Marker: Integer);
var
 Aux: TScript;
begin
 Aux:= FHead;
 while (Aux <> nil) do
  begin
   if (Aux.Marker = Marker) then Aux.Draw();
   Aux:= Aux.Next;
  end; 
end;

//---------------------------------------------------------------------------
initialization
 Script:= TScript.Create(nil);

//---------------------------------------------------------------------------
finalization
 Script.Free();

//---------------------------------------------------------------------------
end.

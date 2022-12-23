unit GuiRegistry;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Windows, Types, Classes, SysUtils, GuiControls, GuiTypes;

//---------------------------------------------------------------------------
type
 TGuiRegistry = class(TComponent)
 private
  function GetCount(): Integer;
  function GetCtrlName(Num: Integer): string;
  function FindControl(Name: string): Integer;
 public
  property Count: Integer read GetCount;
  property CtrlName[Num: Integer]: string read GetCtrlName;

  function NewControl(const Name: string; Owner: TGuiControl): TGuiControl;
 end;

//---------------------------------------------------------------------------
var
 MasterRegistry: TGuiRegistry = nil;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 GuiForms, GuiEdit, GuiLabel, GuiListBox, GuiRadioButton, GuiCheckBox,
 GuiButton, GuiGauge, GuiPaint;

//---------------------------------------------------------------------------
const
 ControlCount = 9;
 ControlNames: array[0..(ControlCount - 1)] of string = ('TGuiForm',
  'TGuiEdit', 'TGuiLabel', 'TGuiListBox', 'TGuiRadioButton', 'TGuiCheckBox',
  'TGuiButton', 'TGuiGauge', 'TGuiPaint');

//---------------------------------------------------------------------------
function TGuiRegistry.NewControl(const Name: string; Owner: TGuiControl): TGuiControl;
var
 Index: Integer;
begin
 Result:= nil;

 Index:= FindControl(Name);
 case Index of
  0: Result:= TGuiForm.Create(Owner);
  1: Result:= TGuiEdit.Create(Owner);
  2: Result:= TGuiLabel.Create(Owner);
  3: Result:= TGuiListBox.Create(Owner);
  4: Result:= TGuiRadioButton.Create(Owner);
  5: Result:= TGuiCheckBox.Create(Owner);
  6: Result:= TGuiButton.Create(Owner);
  7: Result:= TGuiGauge.Create(Owner);
  8: Result:= TGuiPaint.Create(Owner);
 end;
end;

//---------------------------------------------------------------------------
function TGuiRegistry.GetCount(): Integer;
begin
 Result:= ControlCount;
end;

//---------------------------------------------------------------------------
function TGuiRegistry.GetCtrlName(Num: Integer): string;
begin
 if (Num >= 0)and(Num < ControlCount) then
  Result:= ControlNames[Num] else Result:= '';
end;

//---------------------------------------------------------------------------
function TGuiRegistry.FindControl(Name: string): Integer;
var
 i: Integer;
begin
 Name:= LowerCase(Name);

 for i:= 0 to ControlCount - 1 do
  if (Name = LowerCase(ControlNames[i])) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= -1;
end;

//---------------------------------------------------------------------------
initialization
 MasterRegistry:= TGuiRegistry.Create(nil);

//---------------------------------------------------------------------------
finalization
 if (MasterRegistry <> nil) then
  begin
   MasterRegistry.Free();
   MasterRegistry:= nil;
  end;

//---------------------------------------------------------------------------
end.


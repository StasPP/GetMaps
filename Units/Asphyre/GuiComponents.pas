unit GuiComponents;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, AsphyreDef, GuiTypes;

//---------------------------------------------------------------------------
type
 TGuiComponent = class(TGuiObject)
 private
  FClientRect: TRect;
  FTag       : Variant;
  FVisible   : Boolean;
  FEnabled   : Boolean;
  FOnResize  : TNotifyEvent;
  FOnShow    : TNotifyEvent;
  FOnHide    : TNotifyEvent;

  procedure SetClientRect(const Value: TRect);
  function GetPosition(const Index: Integer): Integer;
  procedure SetPosition(const Index, Value: Integer);
  procedure SetVisible(const Value: Boolean);
  procedure SetEnabled(const Value: Boolean);
 protected
  property OnResize: TNotifyEvent read FOnResize write FOnResize;
  property OnShow: TNotifyEvent read FOnShow write FOnShow;
  property OnHide: TNotifyEvent read FOnHide write FOnHide;

  procedure SelfDescribe(); override;
  function ReadProp(Tag: Integer): Variant; override;
  procedure WriteProp(Tag: Integer; const Value: Variant); override;

  procedure DoResize(var NewRect: TRect); virtual;
  procedure DoShow(); virtual;
  procedure DoHide(); virtual;
  procedure DoEnable(); virtual;
  procedure DoDisable(); virtual;

  procedure ReadProps(Stream: TStream);
  procedure WriteProps(Stream: TStream);
 public
  property ClientRect: TRect read FClientRect write SetClientRect;

  property Left  : Integer index 0 read FClientRect.Left write SetPosition;
  property Top   : Integer index 1 read FClientRect.Top write SetPosition;
  property Width : Integer index 2 read GetPosition write SetPosition;
  property Height: Integer index 3 read GetPosition write SetPosition;

  property Tag    : Variant read FTag write FTag;
  property Visible: Boolean read FVisible write SetVisible;
  property Enabled: Boolean read FEnabled write SetEnabled;

  procedure Show();
  procedure Hide();
  procedure MoveBy(dx, dy: Integer);
  procedure ResizeBy(dx, dy: Integer);
  procedure ApplyConstraint(const Constraint: TRect);

  constructor Create();
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
uses
 StreamEx;

//---------------------------------------------------------------------------
constructor TGuiComponent.Create();
begin
 inherited;

 FClientRect:= Bounds(0, 0, 0, 0);
 FVisible   := True;
 FEnabled   := True;
 FTag       := 0;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.DoResize(var NewRect: TRect);
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.DoShow();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.DoHide();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.DoEnable();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.DoDisable();
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.SetClientRect(const Value: TRect);
var
 NewRect: TRect;
begin
 NewRect:= Value;
 DoResize(NewRect);
 FClientRect:= NewRect;

 if (Assigned(FOnResize)) then FOnResize(Self);
end;

//---------------------------------------------------------------------------
function TGuiComponent.GetPosition(const Index: Integer): Integer;
begin
 case Index of
  2: Result:= FClientRect.Right - FClientRect.Left;
  3: Result:= FClientRect.Bottom - FClientRect.Top;
  else Result:= 0;
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.SetPosition(const Index, Value: Integer);
var
 Aux: Integer;
 NewRect: TRect;
begin
 NewRect:= FClientRect;
 case Index of
  0: begin
      Aux:= NewRect.Right - NewRect.Left;
      NewRect.Left := Value;
      NewRect.Right:= Value + Aux;
     end;
  1: begin
      Aux:= NewRect.Bottom - NewRect.Top;
      NewRect.Top   := Value;
      NewRect.Bottom:= Value + Aux;
     end;
  2: NewRect.Right := NewRect.Left + Value;
  3: NewRect.Bottom:= NewRect.Top + Value;
 end;

 DoResize(NewRect);
 FClientRect:= NewRect;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.SetVisible(const Value: Boolean);
begin
 if (FVisible <> Value) then
  begin
   FVisible:= Value;

   if (FVisible) then
    begin
     DoShow();
     if (Assigned(FOnShow)) then FOnShow(Self);
    end else
    begin
     if (Assigned(FOnHide)) then FOnHide(Self);
     DoHide();
    end;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.Show();
begin
 Visible:= True;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.Hide();
begin
 Visible:= False;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.SetEnabled(const Value: Boolean);
begin
 if (FEnabled <> Value) then
  begin
   FEnabled:= Value;
   if (FEnabled) then DoEnable() else DoDisable();
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.SelfDescribe();
begin
 FNameOfClass:= 'TGuiComponent';
 FDescOfClass:= 'TGuiComponent generic class';

 IncludeProp('Left',    ptInteger, $70000, 'The horizontal position of component in pixels');
 IncludeProp('Top',     ptInteger, $70001, 'The vertical position of component in pixels');
 IncludeProp('Width',   ptInteger, $70002, 'The horizontal size of component in pixels');
 IncludeProp('Height',  ptInteger, $70003, 'The vertical size of component in pixels');
 IncludeProp('Tag',     ptString,  $70004, 'User-defined attribute');
 IncludeProp('Visible', ptBoolean, $70005, 'Whether this component is visible or not');
 IncludeProp('Enabled', ptBoolean, $70006, 'Whether this component can receive and respond to events');
end;

//---------------------------------------------------------------------------
function TGuiComponent.ReadProp(Tag: Integer): Variant;
begin
 case Tag of
  $70000: Result:= FClientRect.Left;
  $70001: Result:= FClientRect.Top;
  $70002: Result:= FClientRect.Right - FClientRect.Left;
  $70003: Result:= FClientRect.Bottom - FClientRect.Top;
  $70004: Result:= FTag;
  $70005: Result:= FVisible;
  $70006: Result:= FEnabled;
  else Result:= inherited ReadProp(Tag);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.WriteProp(Tag: Integer; const Value: Variant);
begin
 case Tag of
  $70000: Left   := Value;
  $70001: Top    := Value;
  $70002: Width  := Value;
  $70003: Height := Value;
  $70004: FTag   := Value;
  $70005: Visible:= Value;
  $70006: Enabled:= Value;
  else inherited WriteProp(Tag, Value);
 end;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.MoveBy(dx, dy: Integer);
begin
 Left:= FClientRect.Left + dx;
 Top := FClientRect.Top + dy;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.ResizeBy(dx, dy: Integer);
begin
 Width := Width + dx;
 Height:= Height + dy;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.ApplyConstraint(const Constraint: TRect);
begin
 FClientRect:= ShortRect(FClientRect, Constraint);
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.WriteProps(Stream: TStream);
var
 Count, Index: Integer;
 Field: string;
 PropType: TPropertyType;
begin
 Count:= PropertyCount;
 Stream.WriteBuffer(Count, SizeOf(Integer));

 for Index:= 0 to Count - 1 do
  begin
   Field   := PropertyName[Index];
   PropType:= PropertyType[Index];
   stWriteString(Stream, Field);
   Stream.WriteBuffer(PropType, SizeOf(TPropertyType));
   case PropType of
    ptFill: PropFill[Field].WriteToStream(Stream);
    ptFont: PropFont[Field].WriteToStream(Stream);
    else stWriteString(Stream, Prop[Field]);
   end;
  end;
end;

//---------------------------------------------------------------------------
procedure TGuiComponent.ReadProps(Stream: TStream);
var
 Count, Index: Integer;
 Field: string;
 PropType: TPropertyType;
begin
 Stream.ReadBuffer(Count, SizeOf(Integer));

 for Index:= 0 to Count - 1 do
  begin
   Field:= stReadString(Stream);
   Stream.ReadBuffer(PropType, SizeOf(TPropertyType));
   case PropType of
    ptFill: PropFill[Field].ReadFromStream(Stream);
    ptFont: PropFont[Field].ReadFromStream(Stream);
    else Prop[Field]:= stReadString(Stream);
   end;
  end;
end;

//---------------------------------------------------------------------------
end.

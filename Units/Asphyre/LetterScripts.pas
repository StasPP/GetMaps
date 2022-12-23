unit LetterScripts;

//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, Math, AsphyreDef, AsphyreScript, ImageFx, GuiTypes;

//---------------------------------------------------------------------------
type
 TIntplType = (itLinear, itAccel, itBrake, itSine, itZero);

//---------------------------------------------------------------------------
 PLetterPoint = ^TLetterPoint;
 TLetterPoint = record
  Pos   : TPoint2;
  Size  : Real;
  Color0: Cardinal;
  Color1: Cardinal;
  Ticks : Integer;
  Block : TIntplType;
 end;

//---------------------------------------------------------------------------
 TLetterScript = class(TScript)
 private
  Data: array of TLetterPoint;

  FFontIndex: Integer;
  FBlendOp: Cardinal;
  FText: string;

  function GetCount(): Integer;
  function GetPoint(Num: Integer): PLetterPoint;
  function PointBelow(Ticks: Integer): Integer;
  function PointAbove(Ticks: Integer): Integer;
 protected
  procedure DoDraw(); override;
  procedure DoPaint(const Traj: TLetterPoint); virtual;
 public
  property Count: Integer read GetCount;
  property Point[Num: Integer]: PLetterPoint read GetPoint;

  property FontIndex: Integer read FFontIndex write FFontIndex;
  property BlendOp: Cardinal read FBlendOp write FBlendOp;
  property Text: string read FText write FText;

  function AddPt(Ticks: Integer; Block: TIntplType; const Pos: TPoint2;
   Size: Real; Color0, Color1: Cardinal): Integer;

  constructor Create(AParent: TScript); override;
 end;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
function LerpPos(const p0, p1: TPoint2; Theta: Real): TPoint2;
begin
 Result.X:= p0.X + ((p1.X - p0.X) * Theta);
 Result.Y:= p0.Y + ((p1.Y - p0.Y) * Theta);
end;

//---------------------------------------------------------------------------
constructor TLetterScript.Create(AParent: TScript);
begin
 inherited;

 FFontIndex:= 0;
 FBlendOp:= fxBlend;
end;

//---------------------------------------------------------------------------
function TLetterScript.GetCount(): Integer;
begin
 Result:= Length(Data);
end;

//---------------------------------------------------------------------------
function TLetterScript.GetPoint(Num: Integer): PLetterPoint;
begin
 if (Num >= 0)and(Num < Length(Data)) then
  Result:= @Data[Num] else Result:= nil;
end;

//---------------------------------------------------------------------------
function TLetterScript.AddPt(Ticks: Integer; Block: TIntplType;
 const Pos: TPoint2; Size: Real; Color0, Color1: Cardinal): Integer;
var
 Index: Integer;
begin
 Index:= Length(Data);
 SetLength(Data, Index + 1);

 Data[Index].Pos   := Pos;
 Data[Index].Size  := Size;
 Data[Index].Color0:= Color0;
 Data[Index].Color1:= Color1;
 Data[Index].Ticks := Ticks;
 Data[Index].Block := Block;

 Result:= Index;
end;

//---------------------------------------------------------------------------
function TLetterScript.PointBelow(Ticks: Integer): Integer;
var
 i, Index: Integer;
 Delta, NowDelta: Cardinal;
begin
 Index:= -1;
 Delta:= High(Cardinal);

 for i:= 0 to Length(Data) - 1 do
  if (Data[i].Ticks <= Ticks) then
   begin
    NowDelta:= Ticks - Data[i].Ticks;
    if (NowDelta < Delta) then
     begin
      Delta:= NowDelta;
      Index:= i;
     end;
   end;

 Result:= Index;
end;

//---------------------------------------------------------------------------
function TLetterScript.PointAbove(Ticks: Integer): Integer;
var
 i, Index: Integer;
 Delta, NowDelta: Cardinal;
begin
 Index:= -1;
 Delta:= High(Cardinal);

 for i:= 0 to Length(Data) - 1 do
  if (Data[i].Ticks >= Ticks) then
   begin
    NowDelta:= Data[i].Ticks - Ticks;
    if (NowDelta < Delta) then
     begin
      Delta:= NowDelta;
      Index:= i;
     end;
   end;

 Result:= Index;
end;

//---------------------------------------------------------------------------
procedure TLetterScript.DoPaint(const Traj: TLetterPoint);
begin
 // no code
end;

//---------------------------------------------------------------------------
procedure TLetterScript.DoDraw();
const
 PiHalf = Pi / 2.0;
var
 Below, Above: Integer;
 TrajPt: TLetterPoint;
 Theta: Real;
begin
 Below:= PointBelow(Ticks);
 Above:= PointAbove(Ticks);
 if (Below = -1)and(Above = -1) then Exit;

 if (Below = -1)or(Above = Below) then
  begin
   TrajPt:= Data[Above];
   TrajPt.Ticks:= Ticks;
  end else
 if (Above = -1)or((Below <> -1)and(Data[Below].Block = itZero)) then
  begin
   TrajPt:= Data[Below];
   TrajPt.Ticks:= Ticks;
  end else
  begin
   Theta:= (Ticks - Data[Below].Ticks) / (Data[Above].Ticks - Data[Below].Ticks);
   case Data[Below].Block of
    itSine : Theta:= (Sin((Theta * Pi) - PiHalf) + 1.0) * 0.5;
    itAccel: Theta:= Sin((Theta * PiHalf) - PiHalf) + 1.0;
    itBrake: Theta:= Sin(Theta * PiHalf);
   end;

   TrajPt.Pos := LerpPos(Data[Below].Pos, Data[Above].Pos, Theta);
   TrajPt.Size:= Data[Below].Size + ((Data[Above].Size - Data[Below].Size) * Theta);

   TrajPt.Color0:= BlendPixels(Data[Above].Color0, Data[Below].Color0,
    Round(Theta * 255.0));
   TrajPt.Color1:= BlendPixels(Data[Above].Color1, Data[Below].Color1,
    Round(Theta * 255.0));

   TrajPt.Ticks:= Ticks;
  end;

 guiFonts[FFontIndex].Scale:= TrajPt.Size;
 if (TrajPt.Color0 shr 24 > 0)or(TrajPt.Color1 > 0) then
  guiFonts[FFontIndex].TextOut(FText, Round(TrajPt.Pos.x), Round(TrajPt.Pos.y),
   TrajPt.Color0, TrajPt.Color1, FBlendOp);
end;

//---------------------------------------------------------------------------
end.

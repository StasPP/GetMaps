unit TypesEx;

interface
uses
 Types;

//---------------------------------------------------------------------------
// returns True if the given point is within the specified rectangle
//---------------------------------------------------------------------------
function PointInRect(const Point: TPoint; const Rect: TRect): Boolean;

//---------------------------------------------------------------------------
// returns True if the given rectangle is within the specified rectangle
//---------------------------------------------------------------------------
function RectInRect(const Rect1, Rect2: TRect): Boolean;

//---------------------------------------------------------------------------
// returns True if the specified rectangles overlap
//---------------------------------------------------------------------------
function OverlapRect(const Rect1, Rect2: TRect): Boolean;

//---------------------------------------------------------------------------
// shrinks the specified rectangle by the given amount
//---------------------------------------------------------------------------
function ShrinkRect(const Rect: TRect; const hIn, vIn: Integer): TRect;

//---------------------------------------------------------------------------
// moves the specified rectangle by specific amount
//---------------------------------------------------------------------------
function MoveRect(const Rect: TRect; const DeltaX, DeltaY: Integer): TRect;

//---------------------------------------------------------------------------
// moves the specified rectangle to the new position
//---------------------------------------------------------------------------
function PositionRect(const Rect: TRect; const NewPos: TPoint): TRect;

//---------------------------------------------------------------------------
// partitions one rectangle vertically into two non-overlapping rectangles
// the first rectangle has Round(Height * Theta) - 1 height
//---------------------------------------------------------------------------
procedure VPartitionRect(const Rect: TRect; const Theta: Real; out Rect1, Rect2: TRect);

//---------------------------------------------------------------------------
// partitions one rectangle horizontally into two non-overlapping rectangles
// the first rectangle has Round(Width * Theta) - 1 width
//---------------------------------------------------------------------------
procedure HPartitionRect(const Rect: TRect; const Theta: Real; out Rect1, Rect2: TRect);

//---------------------------------------------------------------------------
// partitions the rectangle like VPartitionRect does, but returns only the
// first part
//---------------------------------------------------------------------------
function VPartOfRect1(const Rect: TRect; const Theta: Real): TRect;

//---------------------------------------------------------------------------
// partitions the rectangle like VPartitionRect does, but returns only the
// second part
//---------------------------------------------------------------------------
function VPartOfRect2(const Rect: TRect; const Theta: Real): TRect;

//---------------------------------------------------------------------------
// partitions the rectangle like HPartitionRect does, but returns only the
// first part
//---------------------------------------------------------------------------
function HPartOfRect1(const Rect: TRect; const Theta: Real): TRect;

//---------------------------------------------------------------------------
// partitions the rectangle like HPartitionRect does, but returns only the
// second part
//---------------------------------------------------------------------------
function HPartOfRect2(const Rect: TRect; const Theta: Real): TRect;

//---------------------------------------------------------------------------
// shrinks the given rectangle horizontally by the specified amounts
//---------------------------------------------------------------------------
function HShrinkRect(const Rect: TRect; const LeftAmount, RightAmount: Integer): TRect;

//---------------------------------------------------------------------------
// shrinks the given rectangle vertically by the specified amounts
//---------------------------------------------------------------------------
function VShrinkRect(const Rect: TRect; const TopAmount, BottomAmount: Integer): TRect;

//---------------------------------------------------------------------------
// changes the width & height of given rectangle
//---------------------------------------------------------------------------
function ResizeRect(const Rect: TRect; const nWidth, nHeight: Integer): TRect;

//---------------------------------------------------------------------------
// multiplies the point's coordinates by the given coefficient
//---------------------------------------------------------------------------
function ScalePoint(const Pt: TPoint; const Theta: Real): TPoint;

//---------------------------------------------------------------------------
// align point to grid
//---------------------------------------------------------------------------
function AlignToGridPt(const Pt: TPoint; const GridX, GridY: Integer): TPoint;


//---------------------------------------------------------------------------
// multiplies the point's coordinates by the given coefficient
//---------------------------------------------------------------------------
function ScaleRect(const Rect: TRect; const Theta: Real): TRect;

implementation
//---------------------------------------------------------------------------
function PointInRect(const Point: TPoint; const Rect: TRect): Boolean;
begin
 Result:= (Point.X >= Rect.Left)and(Point.X <= Rect.Right)and
  (Point.Y >= Rect.Top)and(Point.Y <= Rect.Bottom);
end;

//---------------------------------------------------------------------------
function RectInRect(const Rect1, Rect2: TRect): Boolean;
begin
 Result:= (Rect1.Left >= Rect2.Left)and(Rect1.Right <= Rect2.Right)and
  (Rect1.Top >= Rect2.Top)and(Rect1.Bottom <= Rect2.Bottom);
end;
//---------------------------------------------------------------------------
function OverlapRect(const Rect1, Rect2: TRect): Boolean;
begin
 Result:= (Rect1.Left < Rect2.Right)and(Rect1.Right > Rect2.Left)and
  (Rect1.Top < Rect2.Bottom)and(Rect1.Bottom > Rect2.Top);
end;

//---------------------------------------------------------------------------
function ShrinkRect(const Rect: TRect; const hIn, vIn: Integer): TRect;
begin
 Result.Left:= Rect.Left + hIn;
 Result.Top:= Rect.Top + vIn;
 Result.Right:= Rect.Right - hIn;
 Result.Bottom:= Rect.Bottom - vIn;
end;

//---------------------------------------------------------------------------
function MoveRect(const Rect: TRect; const DeltaX, DeltaY: Integer): TRect;
begin
 Result.Left:= Rect.Left + DeltaX;
 Result.Top:= Rect.Top + DeltaY;
 Result.Right:= Rect.Right + DeltaX;
 Result.Bottom:= Rect.Bottom + DeltaY;
end;

//---------------------------------------------------------------------------
function PositionRect(const Rect: TRect; const NewPos: TPoint): TRect;
begin
 Result:= MoveRect(Rect, NewPos.X - Rect.Left, NewPos.Y - Rect.Top);
end;

//---------------------------------------------------------------------------
procedure VPartitionRect(const Rect: TRect; const Theta: Real; out Rect1, Rect2: TRect);
var
 Delta: Integer;
begin
 Delta:= Round(Abs((Rect.Bottom - Rect.Top) * Theta));

 Rect1:= Bounds(Rect.Left, Rect.Top, Abs(Rect.Right - Rect.Left), Delta - 1);
 Rect2:= Bounds(Rect.Left, Rect.Top + Delta - 1, Abs(Rect.Right - Rect.Left),
  (Rect.Bottom - Rect.Top) - Delta);
end;

//---------------------------------------------------------------------------
procedure HPartitionRect(const Rect: TRect; const Theta: Real; out Rect1, Rect2: TRect);
var
 Delta: Integer;
begin
 Delta:= Round(Abs((Rect.Right - Rect.Left) * Theta));

 Rect1:= Bounds(Rect.Left, Rect.Top, Delta - 1, Abs(Rect.Bottom - Rect.Top));
 Rect2:= Bounds(Rect.Left + Delta - 1, Rect.Top, (Rect.Right - Rect.Left) -
  Delta, Abs(Rect.Bottom - Rect.Top));
end;

//---------------------------------------------------------------------------
function VPartOfRect1(const Rect: TRect; const Theta: Real): TRect;
var
 Delta: Integer;
begin
 Delta:= Round(Abs((Rect.Bottom - Rect.Top) * Theta));

 Result:= Bounds(Rect.Left, Rect.Top, Abs(Rect.Right - Rect.Left), Delta - 1);
end;

//---------------------------------------------------------------------------
function VPartOfRect2(const Rect: TRect; const Theta: Real): TRect;
var
 Delta: Integer;
begin
 Delta:= Round(Abs((Rect.Bottom - Rect.Top) * Theta));

 Result:= Bounds(Rect.Left, Rect.Top + Delta - 1, Abs(Rect.Right - Rect.Left),
  (Rect.Bottom - Rect.Top) - Delta);
end;

//---------------------------------------------------------------------------
function HPartOfRect1(const Rect: TRect; const Theta: Real): TRect;
var
 Delta: Integer;
begin
 Delta:= Round(Abs((Rect.Right - Rect.Left) * Theta));

 Result:= Bounds(Rect.Left, Rect.Top, Delta - 1, Abs(Rect.Bottom - Rect.Top));
end;

//---------------------------------------------------------------------------
function HPartOfRect2(const Rect: TRect; const Theta: Real): TRect;
var
 Delta: Integer;
begin
 Delta:= Round(Abs((Rect.Right - Rect.Left) * Theta));

 Result:= Bounds(Rect.Left + Delta - 1, Rect.Top, (Rect.Right - Rect.Left) -
  Delta, Abs(Rect.Bottom - Rect.Top));
end;

//---------------------------------------------------------------------------
function HShrinkRect(const Rect: TRect; const LeftAmount, RightAmount: Integer): TRect;
begin
 Result.Left:= Rect.Left + LeftAmount;
 Result.Top:= Rect.Top;
 Result.Right:= Rect.Right - RightAmount;
 Result.Bottom:= Rect.Bottom;
end;

//---------------------------------------------------------------------------
function VShrinkRect(const Rect: TRect; const TopAmount, BottomAmount: Integer): TRect;
begin
 Result.Left:= Rect.Left;
 Result.Top:= Rect.Top + TopAmount;
 Result.Right:= Rect.Right;
 Result.Bottom:= Rect.Bottom - BottomAmount;
end;

//---------------------------------------------------------------------------
function ResizeRect(const Rect: TRect; const nWidth, nHeight: Integer): TRect;
begin
 Result:= Bounds(Rect.Left, Rect.Top, nWidth, nHeight);
end;

//---------------------------------------------------------------------------
function ScalePoint(const Pt: TPoint; const Theta: Real): TPoint;
begin
 Result.X:= Round(Pt.X * Theta);
 Result.Y:= Round(Pt.Y * Theta);
end;

//---------------------------------------------------------------------------
function AlignToGridPt(const Pt: TPoint; const GridX, GridY: Integer): TPoint;
begin
 Result:= Point((Pt.X div GridX) * GridX, (Pt.Y div GridY) * GridY);
end;

//---------------------------------------------------------------------------
function ScaleRect(const Rect: TRect; const Theta: Real): TRect;
begin
 Result.Left:= Round(Rect.Left * Theta);
 Result.Right:= Round(Rect.Right * Theta);
 Result.Top:= Round(Rect.Top * Theta);
 Result.Bottom:= Round(Rect.Bottom * Theta);
end;

//---------------------------------------------------------------------------
end.

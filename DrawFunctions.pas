unit DrawFunctions;

interface

uses MapFunctions, GeoFunctions, TabFunctions, Vectors2,
     AbstractCanvas, AbstractDevices, AsphyreImages, AsphyreTypes;

procedure CutLineByFrame(var x, y, x2, y2: Double);

procedure CutLineByBufferedFrame(var x, y, x2, y2: Double);

procedure FatLine(AsphCanvas:TAsphyreCanvas;x, y, x2, y2: Double; Thin: integer;
    Dash, Smooth: Boolean; Col: Cardinal);

procedure MyLine(AsphCanvas:TAsphyreCanvas;
    x, y, x2, y2: Double; Dash, Smooth: Boolean; Col: Cardinal);

procedure DrawZone(AsphCanvas:TAsphyreCanvas; x1, y1, x2, y2, x3, y3, x4, y4: Double;
                   Col:TColor4);

implementation




procedure CutLineByBufferedFrame(var x, y, x2, y2: Double);
const
 bx = 1024;
 by = 1024;
begin
  if not( (x < 0 - bx) and (x2 < 0 - bx)) then
  if not( (x > (DispSize.X + bx)) and (x2 > (DispSize.X + bx))) then
  if not( (y < 0 - by) and (y2 < 0 - by)) then
  if not( (y > DispSize.y + by) and (y2 > DispSize.y + by)) then
  if not( (abs(y-y2) < 1) and (abs(x-x2) < 1) ) then
  Begin
    if x < 0 - bx then
    begin
      if abs(x2-x) > 0 then
        y := round( ((-bx-x)/(x2-x))*(y2-y)+y)
          else
            y := y2;
      //Col := $FFFF0000;
      x := 0 - bx;
    end
      else
       if x > (DispSize.X) + bx then
       begin
          if abs(x2-x) > 0 then
              y := round((((DispSize.X)+bx-x)/(x2-x))*(y2-y)+y)
               else
                 y := y2;
          //Col := $FFFF0000;
          x := (DispSize.X) + bx;
       end;

    if x2 < 0 - bx then
    begin
      if abs(x2-x) > 0 - bx then
        y2 := round(((-bx-x)/(x2-x))*(y2-y)+y)
          else
            y2 := y;
      //Col := $FFFF0000;
      x2 := 0 - bx;
    end
      else
       if x2 > (DispSize.X)+bx then
       begin
          if abs(x2-x) > 0 then
              y2 := round((((DispSize.X)+bx-x)/(x2-x))*(y2-y)+y)
               else
                 y2 := y;
          //Col := $FFFF0000;
          x2 := (DispSize.X) + bx;
       end;

    if y < 0 - by then
    begin
      if abs(y2-y)>0 then
          x := round(((-by-y)/(y2-y))*(x2-x)+x)
          else
            x := x2;
      //Col := $FFFF0010;
      y := 0 - by;
    end
      else
       if y > DispSize.y + by then
       begin
          if abs(y2-y) > 0 then
               x := round(((DispSize.y+by-y)/(y2-y))*(x2-x)+x)
               else
                 x := x2;
         //Col := $FFFF0010;
         y := DispSize.y + by;
       end;

   if y2 < 0 - by then
    begin
      if abs(y2-y) > 0 then
          x2 := round(((-by-y)/(y2-y))*(x2-x)+x)
          else
            x2 := x;
      //Col := $FFFF0010;
      y2 := 0 - by;
    end
      else
       if y2 > DispSize.y + by then
       begin
          if abs(y2-y) > 0 then
               x2 := round(((DispSize.y+by-y)/(y2-y))*(x2-x)+x)
               else
                 x2 := x;
         //Col := $FFFF0010;
         y2 := DispSize.y + by;
       end;
  End;
end;


procedure DrawZone(AsphCanvas:TAsphyreCanvas; x1, y1, x2, y2, x3, y3, x4, y4: Double;
                   Col:TColor4);
begin
  if not( (x1 < 0) and (x2 < 0) and (x3 < 0) and (x4 < 0)) then

  if not( (x1 > (DispSize.X)) and (x2 > (DispSize.X)) and
          (x3 > (DispSize.X)) and (x4 > (DispSize.X)) ) then

  if not( (y1 < 0) and (y2 < 0)and (y3 < 0) and (x4 < 0)) then

  if not( (y1 > DispSize.y) and (y2 > DispSize.y) and
          (y3 > DispSize.y) and (y4 > DispSize.y) ) then

  if not( (abs(y1-y2) < 1) and (abs(x1-x2) < 1) and (abs(y3-y4) < 1) and (abs(x3-x4) < 1) ) then

  try

     CutLineByBufferedFrame(x1,y1,x2,y2);
     CutLineByBufferedFrame(x3,y3,x4,y4);

     AsphCanvas.FillQuad(Point4(x1, y1, x2, y2, x3, y3, x4, y4),
                        Col);
  except
  end;

end;

procedure CutLineByFrame(var x, y, x2, y2: Double);
begin
  if not( (x < 0) and (x2 < 0)) then
  if not( (x > DispSize.X) and (x2 > DispSize.X)) then
  if not( (y < 0) and (y2 < 0)) then
  if not( (y > DispSize.y) and (y2 > DispSize.y)) then
  if not( (abs(y-y2) < 1) and (abs(x-x2) < 1) ) then
  Begin
    if x < 0 then
    begin
      if abs(x2-x) > 0 then
        y := round( ((-x)/(x2-x))*(y2-y)+y)
          else
            y := y2;
      x := 0;
    end
      else
       if x > DispSize.X then
       begin
          if abs(x2-x) > 0 then
              y := round(((DispSize.X-x)/(x2-x))*(y2-y)+y)
               else
                 y := y2;
          x := DispSize.X;
       end;

    if x2 < 0 then
    begin
      if abs(x2-x) >0 then
        y2 := round(((-x)/(x2-x))*(y2-y)+y)
          else
            y2 := y;
      x2 := 0;
    end
      else
       if x2 > (DispSize.X) then
       begin
          if abs(x2-x) > 0 then
              y2 := round(((DispSize.X-x)/(x2-x))*(y2-y)+y)
               else
                 y2 := y;
          x2 := DispSize.X;
       end;

    if y < 0 then
    begin
      if abs(y2-y)>0 then
          x := round(((-y)/(y2-y))*(x2-x)+x)
          else
            x := x2;
      y := 0;
    end
      else
       if y > DispSize.y then
       begin
          if abs(y2-y) > 0 then
               x := round(((DispSize.y-y)/(y2-y))*(x2-x)+x)
               else
                 x := x2;
         y := DispSize.y;
       end;

   if y2 < 0 then
    begin
      if abs(y2-y) > 0 then
          x2 := round(((-y)/(y2-y))*(x2-x)+x)
          else
            x2 := x;
      y2 := 0;
    end
      else
       if y2 > DispSize.y then
       begin
          if abs(y2-y) > 0 then
               x2 := round(((DispSize.y-y)/(y2-y))*(x2-x)+x)
               else
                 x2 := x;
         y2 := DispSize.y;
       end;
  End;
end;

procedure FatLine(AsphCanvas:TAsphyreCanvas; x, y, x2, y2: Double; Thin: integer;
    Dash, Smooth: Boolean; Col: Cardinal);
var i, j : integer;
begin
 for I := -Thin to Thin do
   for J := -Thin to Thin do
        MyLine(AsphCanvas, x+I, y+J, x2+I, y2+J, Dash, Smooth, Col)
end;

procedure MyLine(AsphCanvas:TAsphyreCanvas; x, y, x2, y2: Double;
  Dash, Smooth: Boolean; Col: Cardinal);

  var i, l :integer;
    dx, dy :real;
  const
    dashstep = 20;
begin
  if not( (x < 0) and (x2 < 0)) then
  if not( (x > DispSize.X) and (x2 > DispSize.X)) then
  if not( (y < 0) and (y2 < 0)) then
  if not( (y > DispSize.y) and (y2 > DispSize.y)) then
  if not( (abs(y-y2) < 1) and (abs(x-x2) < 1) ) then
  Begin

   CutLineByFrame(x,y,x2,y2);

   try

    if Dash then
    Begin
       L := trunc(Sqrt (Sqr(x2-x)+sqr(y2-y)));
       if L>0 then
       BEGIN
          dx := (x2 - x)/L;
          dy := (y2 - y)/L;
          for I := 0 to L div dashstep do
          begin
            if Smooth then
                AsphCanvas.WuLine( Point2(x+i*dashstep*dx, y+i*dashstep*dy),
                Point2(x+(i+0.5)*dashstep*dx,y+(i+0.5)*dashstep*dy ), Col, Col)
            else
              AsphCanvas.Line( Point2(x+i*dashstep*dx, y+i*dashstep*dy),
                Point2(x+(i+0.5)*dashstep*dx,y+(i+0.5)*dashstep*dy ), Col, Col)
          end;
       END;
    End else
      Begin

          if Smooth then
          begin
            if not( (abs(y-y2) < 1) and (abs(x-x2) < 1) ) then
                AsphCanvas.WuLine( Point2(x, y), Point2(x2, y2), Col, Col)
          end
          else
                AsphCanvas.Line( Point2(x, y), Point2(x2, y2), Col);
      End;

   except
   end;
  End;
end;

end.

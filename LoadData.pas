unit LoadData;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Grids, ValEdit, ComCtrls, Spin, BasicMapObjects,
  LangLoader, TAbFunctions;

type
  TLoadRData = class(TForm)
    RSpacer: TRadioGroup;
    Button1: TButton;
    Button2: TButton;
    Spacer: TEdit;
    ValueList: TValueListEditor;
    StringGrid1: TStringGrid;
    Label3: TLabel;
    GroupBox2: TGroupBox;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    ComboBox1: TComboBox;
    RadioGroup2: TRadioGroup;
    ComboBox2: TComboBox;
    ListBox4: TListBox;
    Label1: TLabel;
    SpinEdit1: TSpinEdit;
    RoutesBE: TRadioGroup;
    ValueList2: TValueListEditor;
    procedure Button2Click(Sender: TObject);
    procedure RefreshRes;
    procedure RSpacerClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure RadioGroup2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ValueListKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ListBox4Click(Sender: TObject);
    procedure ComboBox2Change(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure RenameTabs(StringGrid:TStringGrid; TabNameStyle:byte);
    procedure ListBox4MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormActivate(Sender: TObject);
    procedure RoutesBEClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure OpenFile(FileName:String);
    var
    LatS, LonS, XS, YS, ZS, NordS, SouthS, NSS, EWS, WestS, EastS, NameS, FName : String;
  end;

var
  LoadRData: TLoadRData;
  var S: TStringList;
//    oldidx, idx: Longint;
//    HintX, HintY:Integer;
    
implementation

uses GeoClasses, GeoFunctions, MapperFm;
{$R *.dfm}

procedure FindCat(Cat: String; ListBox: TListBox);
var i: integer;
begin
 ListBox.Items.Clear;
 for i := 0 to Length( CoordinateSystemList)-1 do
  if CoordinateSystemList[i].Category = Cat then
    ListBox.Items.Add(CoordinateSystemList[i].Caption);
end;

procedure ClearGrid(StringGrid: TStringGrid);
var i, j: Integer;
begin
  with StringGrid do
  begin
    for i:=1 to RowCount-1 do
    for j:=0 to ColCount-1 do
      Cells[j, i]:='';
    StringGrid.RowCount := 2;
  end;
end;


function GetCols(str, sep: string; ColN, ColCount:integer): string;
  var j,stl,b :integer;
  begin

    Result:='';
    stl:=0;
    b:=1;

    for j:=1 to length(Str)+1 do
    Begin

      if ((copy(Str,j,1)=sep)or(j=length(Str)+1))and(copy(Str,j-1,1)<>sep) then
      begin

       if (stl>=ColN) and (Stl<ColN+ColCount) then
       Begin
        if result='' then
          Result:=(Copy(Str,b,j-b))
            else
              Result:=Result+' '+(Copy(Str,b,j-b));
       End;

       inc(stl);
       b:=j+1;

       if stl>ColN+ColCount then
          break;
      end;

    End;

    if result <> '' then
      for j:= 1 to length(Result)+1 do
        if ((Result[j] = '.') or (Result[j] = ','))and(Result[j]<>sep) then
           Result[j] := DecimalSeparator;
end;


procedure TLoadRData.Button2Click(Sender: TObject);
begin
 close;
end;

procedure TLoadRData.RSpacerClick(Sender: TObject);
begin
  Spacer.Enabled := RSpacer.ItemIndex = 2;
  
  RefreshRes;
end;

procedure TLoadRData.Button1Click(Sender: TObject);
begin
// Form1.CanLoad := true;
 isRoutesDatum := PageControl1.ActivePageIndex = 0;

 RoutesBEKind := RoutesBE.ItemIndex;
 //RoutesRSpacer := LoadRData.RSpacer.itemIndex;
 Case LoadRData.RSpacer.itemIndex of
     0: RoutesRSpacer := ' ';
     1: RoutesRSpacer := #$9;
     2: RoutesRSpacer := LoadRData.Spacer.Text[1];
     3: RoutesRSpacer := ';';
     4: RoutesRSpacer := ',';
 end;

 if isRoutesDatum then
 begin
   RoutesDatum := FindDatumByCaption(ComboBox1.Items[ComboBox1.ItemIndex]);
   RoutesCS := RadioGroup2.ItemIndex;
 end
  else
  begin
    RoutesCS := FindCoordinateSystemByCaption(ListBox4.Items[ListBox4.ItemIndex]);
    RoutesDatum :=  -1; //CoordinateSystemList[MainForm.RoutesCS].DatumN;
  end;

  RoutesXTab :=  StrToInt(ValueList.Cells[1,2])-1;
  RoutesYTab :=  StrToInt(ValueList.Cells[1,3])-1;
  if ValueList.RowCount = 5 then
    RoutesZTab :=  StrToInt(ValueList.Cells[1,4])-1
      else
       RoutesZTab := -1;

  RoutesNameTab := StrToInt(ValueList.Cells[1,1])-1;

  RoutesX2Tab :=  StrToInt(ValueList2.Cells[1,1])-1;
  RoutesY2Tab :=  StrToInt(ValueList2.Cells[1,2])-1;
  if ValueList2.RowCount = 4 then
   RoutesZ2Tab :=  StrToInt(ValueList2.Cells[1,3])-1
    else
       RoutesZ2Tab := -1;


  RoutesTabStart := SpinEdit1.Value;

  LoadRoutes(FName);
  close;
end;

procedure TLoadRData.ComboBox1Change(Sender: TObject);
var i, j : integer;
begin
  if ComboBox1.ItemIndex>=0 then
  Begin
     // Memo1.clear;
    //ListBox1.Clear;

    i:= FindDatumByCaption(ComboBox1.Items[ComboBox1.ItemIndex]);

    RadioGroup2.ItemIndex := 0;
    RadioGroup2.Buttons[2].Enabled := false;
    RadioGroup2.Buttons[3].Enabled := false;
    RadioGroup2.Buttons[4].Enabled := false;
    for j:=0 to length(DatumList[i].Projections)-1 Do
    begin
      if DatumList[i].Projections[j]='Gauss' then
         RadioGroup2.Buttons[2].Enabled := true;
      if DatumList[i].Projections[j]='UTM' then
      begin
         RadioGroup2.Buttons[3].Enabled := true;
         RadioGroup2.Buttons[4].Enabled := true;
      end;
    end;

  End;

end;

procedure TLoadRData.RadioGroup2Click(Sender: TObject);
begin

  case RadioGroup2.ItemIndex of
    3,4: begin
      ValueList.Keys[1] := NameS;
      ValueList.Keys[2] := EWS;
      ValueList.Keys[3] := NSS;

      if ValueList.RowCount=5 then
         ValueList.DeleteRow(4);

      ValueList2.Keys[1] := EWS;
      ValueList2.Keys[2] := NSS;

      if ValueList2.RowCount=4 then
         ValueList2.DeleteRow(3);
    end;

    2: begin
      ValueList.Keys[1] := NameS;
      ValueList.Keys[2] := EWS;
      ValueList.Keys[3] := NSS;

      if ValueList.RowCount=5 then
         ValueList.DeleteRow(4);

      ValueList2.Keys[1] := EWS;
      ValueList2.Keys[2] := NSS;

      if ValueList2.RowCount=4 then
         ValueList2.DeleteRow(3);

    end;

    1: begin
      ValueList.Keys[1] := NameS;
      ValueList.Keys[2] := XS;
      ValueList.Keys[3] := YS;

      if ValueList.RowCount<5 then
        ValueList.InsertRow(ZS, '4', true);

      ValueList2.Keys[1] := XS;
      ValueList2.Keys[2] := YS;

      if ValueList2.RowCount<4 then
         ValueList2.InsertRow(ZS, '7', true);
    end;

    0: begin
      ValueList.Keys[1] := NameS;
      ValueList.Keys[2] := LatS+#176;
      ValueList.Keys[3] := LonS+#176;

      if ValueList.RowCount = 5 then
         ValueList.DeleteRow(4);

      ValueList2.Keys[1] :=  LatS +#176;
      ValueList2.Keys[2] :=  LonS +#176;

      if ValueList2.RowCount = 4 then
         ValueList2.DeleteRow(3);
    end;
  end;
  RenameTabs(StringGrid1,RadioGroup2.ItemIndex);
  RefreshRes;
end;

procedure TLoadRData.FormActivate(Sender: TObject);
var I : Integer;
begin
 if  ComboBox1.Items.Count = 0 then
 begin

   ComboBox2.Clear;
   for i := 0 to Length(CoorinateSystemCategories)-1 do
     ComboBox2.Items.Add(CoorinateSystemCategories[i]);

   Combobox2.Sorted := true;
   ComboBox2.ItemIndex :=0;
   ComboBox2.OnChange(nil);

   for I := 0 to Length(DatumList)-1 do
     if not DatumList[i].Hidden  then
     ComboBox1.Items.Add(DatumList[i].Caption);
   ComboBox1.ItemIndex := 0;
   ComboBox1.OnChange(nil);
 end;

 {
 if MainForm.isRoutesDatum then
 begin
  for i := 0 to ComboBox1.Items.Count - 1 do
    if DatumList[MainForm.RoutesDatum].Caption = ComboBox1.Items[I] then
      ComboBox1.ItemIndex := i;
 end 
   else
     begin
       for i := 0 to ComboBox2.Items.Count - 1 do
         if CoordinateSystemList[MainForm.RoutesCS].Category = ComboBox2.Items[I] then
            ComboBox2.ItemIndex := i;
       ComboBox2.OnChange(nil);     
       for i := 0 to ListBox4.Items.Count - 1 do
         if CoordinateSystemList[MainForm.RoutesCS].Caption = ListBox4.Items[I] then
            ListBox4.ItemIndex := i;
     end;   

 SpinEdit1.Value := MainForm.RoutesTabStart;
 
 ValueList.Cells[1,1] := IntToStr(MainForm.RoutesNameTab+1);
 ValueList.Cells[1,2] := IntToStr(MainForm.RoutesXTab+1);
 ValueList.Cells[1,3] := IntToStr(MainForm.RoutesYTab+1);
 if ValueList.RowCount>4 then 
   ValueList.Cells[1,4] := IntToStr(MainForm.RoutesZTab+1);

 ValueList2.Cells[1,1] := IntToStr(MainForm.RoutesX2Tab+1);
 ValueList2.Cells[1,2] := IntToStr(MainForm.RoutesY2Tab+1);
 if ValueList2.RowCount>3 then
    ValueList2.Cells[1,3] := IntToStr(MainForm.RoutesZ2Tab+1);

 if MainForm.isRoutesDatum then
 begin
   PageControl1.ActivePageIndex:= 0;
   Combobox1.OnChange(nil);
   RadioGroup2.OnClick(nil);
 end  
    else
      begin
       PageControl1.ActivePageIndex := 1;
       ListBox4.OnClick(nil);
      end;
              }
    
 RefreshRes;
end;

procedure TLoadRData.FormCreate(Sender: TObject);
begin
    S :=TStringList.Create;
    oldidx := -1;

    LatS := '������ B, ';
    LonS := '������� L, ';
    XS := 'X, �'; YS := 'Y, �'; ZS := 'Z, �';
    NordS := '�����, �';
    SouthS:= '��, �';
    NSS := '�����/��, �';
    EWS := '�����/������, �';
    WestS := '�����, �';
    EastS := '������, �';
    NameS := '���'
end;

procedure TLoadRData.FormDestroy(Sender: TObject);
begin
  S.Destroy;
end;

procedure TLoadRData.FormShow(Sender: TObject);
begin
  RadioGroup2.OnClick(nil);
  RefreshRes;


  LatS := inf[0];
  LonS := inf[1];
  XS := inf[2]; YS := inf[3]; ZS := inf[4];
  NordS := inf[5];
  SouthS:= inf[6];
  NSS := inf[7];
  EWS := inf[8];
  WestS := inf[9];
  EastS := inf[10];
  NameS := inf[11];

  ValueList.TitleCaptions[0]:= inf[12];
  ValueList.TitleCaptions[1]:= inf[13];

  ValueList2.TitleCaptions[0]:= inf[12];
  ValueList2.TitleCaptions[1]:= inf[13];
end;

procedure TLoadRData.RefreshRes;
var i : integer;
    Sep : String;
begin
   ClearGrid(StringGrid1);

  { if TabSheet1.PageIndex = 0 then
     RenameTabs(StringGrid1,RadioGroup2.ItemIndex)
       else
         ListBox4.OnClick;   }
    
   try

   for i:= SpinEdit1.Value-1 to S.count-1 do
   Begin
     if i<0 then
       continue;
       
     if i > 3 + (SpinEdit1.Value-1) then exit;

     with StringGrid1 do
      // if i >= 4 - (SpinEdit1.Value-1) + RowCount-2 then
         RowCount := 5; //i + 2 - (SpinEdit1.Value-1);

     if StringGrid1.RowCount > 1 then
       StringGrid1.FixedRows := 1;

     case RSpacer.ItemIndex of
        0: sep:=' ';
        1: sep:=#$9;
        2: if Spacer.Text<> '' then sep := Spacer.Text[1];
        3: sep:=';';
        4: sep:=',';
     end;

     StringGrid1.Cells[0,i+1-(SpinEdit1.Value-1)] := GetCols(s[i],sep, StrToInt(ValueList.Cells[1,1])-1,1);
     StringGrid1.Cells[1,i+1-(SpinEdit1.Value-1)] := GetCols(s[i],sep, StrToInt(ValueList.Cells[1,2])-1,1);
     StringGrid1.Cells[2,i+1-(SpinEdit1.Value-1)] := GetCols(s[i],sep, StrToInt(ValueList.Cells[1,3])-1,1);
     
     if ValueList.RowCount>4 then
       StringGrid1.Cells[3,i+1-(SpinEdit1.Value-1)] := GetCols(s[i],sep, StrToInt(ValueList.Cells[1,4])-1,1);

     if RoutesBE.ItemIndex = 0 then
     begin
        if ValueList.RowCount>4 then
        begin
          StringGrid1.Cells[0,i+1-(SpinEdit1.Value-1)] := GetCols(s[i],sep, StrToInt(ValueList.Cells[1,1])-1,1);

          StringGrid1.Cells[1,i+1-(SpinEdit1.Value-1)] := GetCols(s[i],sep, StrToInt(ValueList.Cells[1,2])-1,1);
          StringGrid1.Cells[2,i+1-(SpinEdit1.Value-1)] := GetCols(s[i],sep, StrToInt(ValueList.Cells[1,3])-1,1);
          StringGrid1.Cells[3,i+1-(SpinEdit1.Value-1)] := GetCols(s[i],sep, StrToInt(ValueList.Cells[1,4])-1,1);

          StringGrid1.Cells[4,i+1-(SpinEdit1.Value-1)] := GetCols(s[i],sep, StrToInt(ValueList2.Cells[1,1])-1,1);
          StringGrid1.Cells[5,i+1-(SpinEdit1.Value-1)] := GetCols(s[i],sep, StrToInt(ValueList2.Cells[1,2])-1,1);
          StringGrid1.Cells[6,i+1-(SpinEdit1.Value-1)] := GetCols(s[i],sep, StrToInt(ValueList2.Cells[1,3])-1,1);
        end
         else
         begin
            StringGrid1.Cells[0,i+1-(SpinEdit1.Value-1)] := GetCols(s[i],sep, StrToInt(ValueList.Cells[1,1])-1,1);

            StringGrid1.Cells[1,i+1-(SpinEdit1.Value-1)] := GetCols(s[i],sep, StrToInt(ValueList.Cells[1,2])-1,1);
            StringGrid1.Cells[2,i+1-(SpinEdit1.Value-1)] := GetCols(s[i],sep, StrToInt(ValueList.Cells[1,3])-1,1);

            StringGrid1.Cells[3,i+1-(SpinEdit1.Value-1)] := GetCols(s[i],sep, StrToInt(ValueList2.Cells[1,1])-1,1);
            StringGrid1.Cells[4,i+1-(SpinEdit1.Value-1)] := GetCols(s[i],sep, StrToInt(ValueList2.Cells[1,2])-1,1);
         end;

     end;
   end;

   except
   end;

  
end;

procedure TLoadRData.RenameTabs(StringGrid: TStringGrid; TabNameStyle: byte);
var i: integer;
begin
 
  case TabNameStyle of
    4: begin
      StringGrid.Cells[0,0] := NameS;
      StringGrid.Cells[2,0] := SouthS;
      StringGrid.Cells[1,0] := WestS;

      if RoutesBE.ItemIndex = 0 then
        StringGrid.ColCount := 5
        else
          StringGrid.ColCount := 3;
      
      if StringGrid.ColCount>4 then
      begin
        StringGrid.Cells[3,0] := WestS;
        StringGrid.Cells[4,0] := SouthS;
      end;
      
     // StringGrid.Cells[3,0] := '������ ��� ��., �';
    end;

    3: begin
      StringGrid.Cells[0,0] := NameS;
      StringGrid.Cells[1,0] := EastS;
      StringGrid.Cells[2,0] := NordS;

      if RoutesBE.ItemIndex = 0 then
        StringGrid.ColCount := 5
        else
          StringGrid.ColCount := 3;

      if StringGrid.ColCount>4 then
      begin
        StringGrid.Cells[3,0] := EastS;
        StringGrid.Cells[4,0] := NordS;
      end;
    end;

    2: begin
      StringGrid.Cells[0,0] := NameS;
      StringGrid.Cells[1,0] := EastS;
      StringGrid.Cells[2,0] := NordS;

      if RoutesBE.ItemIndex = 0 then
        StringGrid.ColCount := 5
        else
          StringGrid.ColCount := 3;
          
      if StringGrid.ColCount>4 then
      begin
        StringGrid.Cells[3,0] := EastS;
        StringGrid.Cells[4,0] := NordS;
      end;
    end;

    1: begin
      StringGrid.Cells[0,0] := NameS;
      StringGrid.Cells[1,0] := XS;
      StringGrid.Cells[2,0] := YS;
      StringGrid.Cells[3,0] := ZS;

      if RoutesBE.ItemIndex = 0 then
        StringGrid.ColCount := 7
        else
          StringGrid.ColCount := 4;

      if StringGrid.ColCount>4 then
      begin
        StringGrid.Cells[4,0] := XS;
        StringGrid.Cells[5,0] := YS;
        StringGrid.Cells[6,0] := ZS;
      end;
    end;

    0: begin
      StringGrid.Cells[0,0] := NameS;
      StringGrid.Cells[1,0] := LatS+#176;
      StringGrid.Cells[2,0] := LonS+#176;

      if RoutesBE.ItemIndex = 0 then
        StringGrid.ColCount := 5
        else
          StringGrid.ColCount := 3;
          
      if StringGrid.ColCount>=4 then
      begin
         StringGrid.Cells[3,0] := LatS+#176;
         StringGrid.Cells[4,0] := LonS+#176;
      end;
    end;
  end;

  for i:= 0 to StringGrid1.ColCount-1 do
    StringGrid1.ColWidths[i] := (StringGrid1.Width - 10) div StringGrid1.ColCount;
end;

procedure TLoadRData.RoutesBEClick(Sender: TObject);
begin
 ValueList2.Visible := RoutesBE.ItemIndex = 0;
 if TabSheet1.PageIndex = 0 then
    RadioGroup2.OnClick(nil)
     else
      ListBox4.OnClick(nil);
end;

procedure TLoadRData.ValueListKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  RefreshRes;
end;

procedure TLoadRData.ListBox4Click(Sender: TObject);
var i, CoordType : integer;
begin
   if ListBox4.ItemIndex <= -1 then
    exit;
    
   i := FindCoordinateSystemByCaption(ListBox4.Items[ListBox4.ItemIndex]);
   CoordType := CoordinateSystemList[i].ProjectionType;
                
   case CoordType of
    3,4: begin
      ValueList.Keys[1] := NameS;
      ValueList.Keys[2] := EWS;
      ValueList.Keys[3] := NSS;

      if ValueList.RowCount=5 then
         ValueList.DeleteRow(4);

      ValueList2.Keys[1] := EWS;
      ValueList2.Keys[2] := NSS;

      if ValueList2.RowCount=4 then
         ValueList2.DeleteRow(3);
    end;

    2: begin
      ValueList.Keys[1] := NameS;
      ValueList.Keys[2] := EWS;
      ValueList.Keys[3] := NSS;

      if ValueList.RowCount=5 then
         ValueList.DeleteRow(4);

      ValueList2.Keys[1] := EWS;
      ValueList2.Keys[2] := NSS;

      if ValueList2.RowCount=4 then
         ValueList2.DeleteRow(3);

    end;

    1: begin
      ValueList.Keys[1] := NameS;
      ValueList.Keys[2] := XS;
      ValueList.Keys[3] := YS;

      if ValueList.RowCount<5 then
        ValueList.InsertRow(ZS, '4', true);

      ValueList2.Keys[1] := XS;
      ValueList2.Keys[2] := YS;

      if ValueList2.RowCount<4 then
         ValueList2.InsertRow(ZS, '7', true);
    end;

    0: begin
      ValueList.Keys[1] := NameS;
      ValueList.Keys[2] := LatS+#176;
      ValueList.Keys[3] := LonS+#176;

      if ValueList.RowCount = 5 then
         ValueList.DeleteRow(4);

      ValueList2.Keys[1] :=  LatS +#176;
      ValueList2.Keys[2] :=  LonS +#176;

      if ValueList2.RowCount = 4 then
         ValueList2.DeleteRow(3);
    end;
    

  end;
  RenameTabs(StringGrid1,CoordType);
end;

procedure TLoadRData.ComboBox2Change(Sender: TObject);
begin
  if ComboBox2.ItemIndex<>-1 then
    findCat(ComboBox2.Items[ComboBox2.ItemIndex],ListBox4);
  //Form2.ListBox4.Sorted :=true;
  ListBox4.ItemIndex :=0;
  ListBox4.OnClick(nil);
end;

procedure TLoadRData.PageControl1Change(Sender: TObject);
begin
  case PageControl1.ActivePageIndex of
    0: begin
         ComboBox1.OnChange(nil);
         RadioGroup2.OnClick(nil);
       end;
    1: begin
        ComboBox2.OnChange(nil);
        ListBox4.OnClick(nil);
      end;
  end;   
end;

procedure TLoadRData.ListBox4MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  idx : Longint;
begin
  with Sender as TListBox do begin
    idx := ItemAtPos(Point(x,y),True);
    if (idx < 0) or (idx = oldidx) then
      Exit;

    Application.ProcessMessages;
    Application.CancelHint;

    oldidx := idx;

    HintX := TListBox(Sender).itemRect(idx).Left;
    HintY := TListBox(Sender).itemRect(idx).Top;

    Hint := '';
    if Canvas.TextWidth(Items[idx]) > Width - 24 then
      Hint:=Items[idx];

  end;
end;

procedure TLoadRData.OpenFile(FileName: String);
begin
  if (AnsiLowerCase(Copy(FileName, Length(FileName)-3,4))='.xls')or
        (AnsiLowerCase(Copy(FileName, Length(FileName)-4,5))='.xlsx')  then
     begin
        ExcelToStringList(FileName, S);
        RSpacer.ItemIndex := 1;
     end
     else
  S.LoadFromFile(FileName);
  FName := FileName;
end;

end.

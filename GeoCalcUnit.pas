unit GeoCalcUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, GeoFunctions, GeoClasses, GeoString,
  LangLoader, MapperFm, Buttons;

type
  TGeoCalcFm = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    ComboBox1: TComboBox;
    RadioGroup2: TRadioGroup;
    TabSheet2: TTabSheet;
    ComboBox2: TComboBox;
    ListBox4: TListBox;
    LabelZ: TLabel;
    LabelY: TLabel;
    LabelX: TLabel;
    EX: TEdit;
    EY: TEdit;
    EZ: TEdit;
    Button1: TButton;
    Button2: TButton;
    Label3: TLabel;
    SpeedButton1: TSpeedButton;
    procedure RefreshPoint;
    procedure RefreshData;
    procedure FormShow(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure RadioGroup2Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure ComboBox2Change(Sender: TObject);
    procedure ListBox4Click(Sender: TObject);
    procedure EZChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure ListBox4MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure SpeedButton1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    ConvTo: shortInt;
    PointB, PointL : Double;
    procedure SetEdits(LatEdit,LongEdit :TEdit);
  end;

var
  GeoCalcFm: TGeoCalcFm;
  WGS : integer;
  Loading: Boolean;
  ReturnB : TEdit;
  ReturnL : TEdit;

implementation

uses LoadData, UGetMapPos;

{$R *.dfm}

procedure FindCat(Cat: String; ListBox: TListBox);
var i: integer;
begin
 ListBox.Items.Clear;
 for i := 0 to Length( CoordinateSystemList)-1 do
  if CoordinateSystemList[i].Category = Cat then
    ListBox.Items.Add(CoordinateSystemList[i].Caption);
end;

procedure TGeoCalcFm.Button1Click(Sender: TObject);
begin
  RefreshPoint;
  if ReturnB <> nil then
    ReturnB.Text := DEGToDMS(PointB,true,4);
  if ReturnL <> nil then
  ReturnL.Text := DEGToDMS(PointL,false,4);
  Close;
end;

procedure TGeoCalcFm.Button2Click(Sender: TObject);
begin
  Close;
end;

procedure TGeoCalcFm.ComboBox1Change(Sender: TObject);
var i, j:integer;
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

    RefreshData;

  End;
end;

procedure TGeoCalcFm.ComboBox2Change(Sender: TObject);
begin
  if ComboBox2.ItemIndex<>-1 then
    findCat(ComboBox2.Items[ComboBox2.ItemIndex],ListBox4);

  ListBox4.ItemIndex :=0;
  ListBox4.OnClick(nil);
end;

procedure TGeoCalcFm.EZChange(Sender: TObject);
begin
  if Loading then
     Exit;

  try
    RefreshPoint;
  except
  end;   
end;

procedure TGeoCalcFm.FormCreate(Sender: TObject);
begin
 Loading := true;
end;

procedure TGeoCalcFm.FormShow(Sender: TObject);
var i :integer;
begin
 Loading := true;

 WGS := FindDatum('WGS84');
 if  ComboBox1.Items.Count = 0 then
 begin

   ComboBox2.Clear;
   for i := 0 to Length(CoorinateSystemCategories)-1 do
     ComboBox2.Items.Add(CoorinateSystemCategories[i]);

   Combobox2.Sorted := true;
   ComboBox2.ItemIndex := 0;
   ComboBox2.OnChange(nil);


   for I := 0 to Length(DatumList)-1 do
   if not DatumList[i].Hidden  then
     ComboBox1.Items.Add(DatumList[i].Caption);

   if  FindDatum('WGS84') <> -1 then
     for I := 0 to ComboBox1.Items.Count - 1 do
     if ComboBox1.Items[i] = DatumList[WGS].Caption then
     begin
      ComboBox1.ItemIndex := I;
      break;
     end;

   ComboBox1.OnChange(nil);

 end;


 if PageControl1.ActivePageIndex = 0 then
   RadioGroup2.OnClick(nil)
   else
     ListBox4.OnClick(nil);

  RefreshData;

  Loading := false;

 // Button2.Caption := Settings.CancelButton.Caption;
end;

procedure TGeoCalcFm.ListBox4Click(Sender: TObject);
var i, CoordType : Integer;
begin

   if ListBox4.ItemIndex <= -1 then
    exit;

   LabelZ.Visible := false;
   EZ.Visible := false;

   i := FindCoordinateSystemByCaption(ListBox4.Items[ListBox4.ItemIndex]);
   CoordType := CoordinateSystemList[i].ProjectionType;

   LoadRData.OnShow(nil);

   case CoordType of
    3,4: begin
      LabelY.Caption := LoadRData.EWS;
      LabelX.Caption := LoadRData.NSS;
    end;

    2: begin
      LabelY.Caption := LoadRData.EWS;
      LabelX.Caption := LoadRData.NSS;
    end;

    1: begin
      LabelX.Caption  := LoadRData.XS;
      LabelY.Caption  := LoadRData.YS;
      LabelZ.Caption  := LoadRData.ZS;

      LabelZ.Visible := true;
      EZ.Visible := true;
    end;

    0: begin
      LabelX.Caption  :=   LoadRData.LatS +#176;
      LabelY.Caption  :=   LoadRData.LonS +#176;
    end;

  end;
  RefreshData;
end;

procedure TGeoCalcFm.ListBox4MouseMove(Sender: TObject; Shift: TShiftState; X,
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
//  if  ListBox4.ItemAtPos(Point(x,y),True) > 0 then
  //  ListBox4.Hint := ListBox4.Items[ ListBox4.ItemAtPos(Point(x,y),True) ];
end;

procedure TGeoCalcFm.PageControl1Change(Sender: TObject);
begin
  case PageControl1.ActivePageIndex of
    0: begin
         ComboBox1.OnChange(nil);
         RadioGroup2.OnClick(nil);
       end;
    1: begin
       // ComboBox2.OnChange(nil);
        ListBox4.OnClick(nil);
      end;
  end;
end;

procedure TGeoCalcFm.RadioGroup2Click(Sender: TObject);
var CoordType : Integer;
begin

   LabelZ.Visible := false;
   EZ.Visible := false;

   CoordType := RadioGroup2.ItemIndex;

   case CoordType of
     4: begin
      LabelY.Caption := LoadRData.WestS;
      LabelX.Caption := LoadRData.SouthS;
    end;

    3: begin
      LabelY.Caption := LoadRData.EastS;
      LabelX.Caption := LoadRData.NordS;
    end;

    2: begin
      LabelY.Caption := LoadRData.EastS;
      LabelX.Caption := LoadRData.NordS;
    end;

    1: begin
      LabelX.Caption  := LoadRData.XS;
      LabelY.Caption  := LoadRData.YS;
      LabelZ.Caption  := LoadRData.ZS;

      LabelZ.Visible := true;
      EZ.Visible := true;
    end;

    0: begin
      LabelX.Caption  :=   LoadRData.LatS +#176;
      LabelY.Caption  :=   LoadRData.LonS +#176;
    end;


  end;

  RefreshData;
//  RefreshPoint;
end;

procedure TGeoCalcFm.RefreshData;
var X2, Y2, Z2, B2, L2, H2 :Double;
    i, zone :Integer;
begin
  Loading := true;


  case PageControl1.ActivePageIndex of
     0: begin
        I := FindDatumByCaption(ComboBox1.Items[ComboBox1.ItemIndex]);

        Geo1ForceToGeo2(PointB,PointL,0,WGS,I,B2,L2,H2);

        case RadioGroup2.ItemIndex of
          0:
          begin                               /// 11-05
             EX.Text := DegToDMS(B2,true,4, false);
             EY.Text := DegToDMS(L2,false,4, false);
          end;
          1:
          begin
             GeoToECEF(I,B2,L2,H2,X2,Y2,Z2);

             EX.Text := Format('%.3f',[X2]);
             EY.Text := Format('%.3f',[Y2]);
             EZ.Text := Format('%.3f',[Z2]);
          end;
          2:  /// GK!
          begin
            GeoToGaussKruger_Kras(B2,L2,X2,Y2,zone,true);

            EX.Text := Format('%n',[X2]);
            EY.Text := Format('%n',[Y2]);
          end;
          3,4:
          begin
            GeoToUTM(I,B2,L2,RadioGroup2.ItemIndex = 4,X2,Y2,zone,true);

            EX.Text := Format('%n',[X2]);
            EY.Text := Format('%n',[Y2]);

          end;
        end

     end;

     1: begin

        i := FindCoordinateSystemByCaption(ListBox4.Items[ListBox4.ItemIndex]);

        Geo1ForceToGeo2(PointB,PointL,0,WGS,CoordinateSystemList[I].DatumN,B2,L2,H2);

        DatumToCoordinateSystem(I,B2,L2,H2,X2,Y2,Z2);
        case CoordinateSystemList[i].ProjectionType of

          0:begin
             EX.Text := DegToDMS(B2,true,4, false);
             EY.Text := DegToDMS(L2,false,4, false);

          end;
          1:begin
            EX.Text := Format('%.3f',[X2]);
            EY.Text := Format('%.3f',[Y2]);
            EZ.Text := Format('%.3f',[Z2]);
          end;
          2..4:begin
            EX.Text := Format('%n',[X2]);
            EY.Text := Format('%n',[Y2]);
          end;


        end;

     end;
  end;
  Loading := false;
end;

procedure TGeoCalcFm.RefreshPoint;
var X2, Y2, Z2, B2, L2, H2 :Double;
    i :Integer;
begin
  Loading := true;

  case PageControl1.ActivePageIndex of
     0: begin

        I := FindDatumByCaption(ComboBox1.Items[ComboBox1.ItemIndex]);

        case RadioGroup2.ItemIndex of
          0: begin
             X2 := StrToLatLon(EX.Text,true);
             Y2 := StrToLatLon(EY.Text,false);
             Z2 := StrToFloat2(EZ.Text);

             Geo1ForceToGeo2(X2,Y2,Z2,I,WGS,B2,L2,H2);

             PointB := B2;
             PointL := L2;
          end;
          1:
          begin
             X2 := StrToFloat2(EX.Text);
             Y2 := StrToFloat2(EY.Text);
             Z2 := StrToFloat2(EZ.Text);

             ECEFToGeo(I,X2,Y2,Z2,B2,L2,H2);

             Geo1ForceToGeo2(B2,L2,H2,I,WGS,B2,L2,H2);

             PointB := B2;
             PointL := L2;
          end;
          2:
          begin
             X2 := StrToFloat2(EX.Text);
             Y2 := StrToFloat2(EY.Text);

             GaussKrugerToGeo_Kras(X2,Y2,B2,L2);

             Geo1ForceToGeo2(B2,L2,H2,I,WGS,B2,L2,H2);

             PointB := B2;
             PointL := L2;
          end;
          3,4:
          begin
             X2 := StrToFloat2(EX.Text);
             Y2 := StrToFloat2(EY.Text);

             UTMToGeo(i,X2,Y2, RadioGroup2.ItemIndex = 4,B2,L2);

             Geo1ForceToGeo2(B2,L2,H2,I,WGS,B2,L2,H2);

             PointB := B2;
             PointL := L2;
          end;
        end;



     end;

     1: begin
        i := FindCoordinateSystemByCaption(ListBox4.Items[ListBox4.ItemIndex]);

        case CoordinateSystemList[i].ProjectionType of
          0: begin
             B2 := StrToLatLon(EX.Text,true);
             L2 := StrToLatLon(EY.Text,false);
             H2 := 0;
          end;
          1:
          begin
             X2 := StrToFloat2(EX.Text);
             Y2 := StrToFloat2(EY.Text);
             Z2 := StrToFloat2(EZ.Text);

             CoordinateSystemToDatum(I,X2,Y2,Z2,B2,L2,H2);
          end;
          2..4:
          begin
             X2 := StrToFloat2(EX.Text);
             Y2 := StrToFloat2(EY.Text);
             Z2 :=0;
             CoordinateSystemToDatum(I,X2,Y2,Z2,B2,L2,H2);
          end;
        end;

        Geo1ForceToGeo2(B2,L2,H2,CoordinateSystemList[I].DatumN,WGS,PointB,PointL,H2);

     end;
  end;
 Loading := false;
end;

procedure TGeoCalcFm.SetEdits(LatEdit, LongEdit: TEdit);
begin
    ReturnB := LatEdit;
    ReturnL := LongEdit;
end;

procedure TGeoCalcFm.SpeedButton1Click(Sender: TObject);
begin
  GetMapPos.ShowModal;

  PointB := StrToLatLon(GetMapPos.ResultB,true);
  PointL := StrToLatLon(GetMapPos.ResultL,false);

  OnShow(nil);
end;

end.

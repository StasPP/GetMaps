unit CoordSysFm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, GeoFunctions, GeoFiles, GeoString, GeoClasses,
  MapperFm, LangLoader;

type
  TCSForm = class(TForm)
    ComboBox2: TComboBox;
    ListBox4: TListBox;
    Button1: TButton;
    Bevel1: TBevel;
    procedure ComboBox2Change(Sender: TObject);
    procedure ListBox4Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ListBox4MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CSForm: TCSForm;
  WGS: Integer;
  FLang : String = 'Russian';
implementation

{$R *.dfm}

procedure FindCat(Cat: String; ListBox: TListBox);
var i: integer;
begin
 ListBox.Items.Clear;
 for i := 0 to Length( CoordinateSystemList)-1 do
  if CoordinateSystemList[i].Category = Cat then
    ListBox.Items.Add(CoordinateSystemList[i].Caption);
end;

procedure TCSForm.Button1Click(Sender: TObject);
begin
  if ListBox4.ItemIndex <> -1 then
     MapFm.CoordSysN := FindCoordinateSystemByCaption(ListBox4.Items[ListBox4.ItemIndex]);
  close;
end;

procedure TCSForm.ComboBox2Change(Sender: TObject);
begin
 if ComboBox2.ItemIndex<>-1 then
    findCat(ComboBox2.Items[ComboBox2.ItemIndex],ListBox4);

  ListBox4.ItemIndex :=0;
  ListBox4.OnClick(nil);
end;

procedure TCSForm.FormActivate(Sender: TObject);
var i: integer;
begin
 WGS := FindDatum('WGS84');
 if  ComboBox2.Items.Count = 0 then
 begin
   ComboBox2.Clear;
   for i := 0 to Length(CoorinateSystemCategories)-1 do
     ComboBox2.Items.Add(CoorinateSystemCategories[i]);

   Combobox2.Sorted := true;
   ComboBox2.ItemIndex := 0;
   ComboBox2.OnChange(nil);

   ListBox4.OnClick(nil);
 end;
end;

procedure TCSForm.FormShow(Sender: TObject);
begin

 if Lang<>FLang then
 Begin
   Lang :=FLang;
   OnActivate(nil);
 End;
end;

procedure TCSForm.ListBox4Click(Sender: TObject);
begin
 if ListBox4.ItemIndex <= -1 then
    exit;
  if CSForm.Visible then
    MapFm.CoordSysN := FindCoordinateSystemByCaption(ListBox4.Items[ListBox4.ItemIndex]);
end;

procedure TCSForm.ListBox4MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if  ListBox4.ItemAtPos(Point(x,y),True) > 0 then
    ListBox4.Hint := ListBox4.Items[ ListBox4.ItemAtPos(Point(x,y),True) ];
end;

end.

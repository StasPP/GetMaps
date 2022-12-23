unit NewMark;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TNewMarkerForm = class(TForm)
    MarkerName: TEdit;
    Button1: TButton;
    procedure MarkerNameKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    isOk : boolean;
    { Public declarations }
  end;

var
  NewMarkerForm: TNewMarkerForm;

implementation

{$R *.dfm}

procedure TNewMarkerForm.Button1Click(Sender: TObject);
begin
   isOk := true;
   close;
end;

procedure TNewMarkerForm.FormCreate(Sender: TObject);
begin
  MarkerName.Text := '';
  isOk := false;
end;

procedure TNewMarkerForm.FormShow(Sender: TObject);
begin
 if Top > Screen.Height - Height then
   Top := Screen.Height - Height;
 if Left > Screen.Width - Width then
    Left := Screen.Width - Width;

 MarkerName.SetFocus;   
end;

procedure TNewMarkerForm.MarkerNameKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = vk_Return then
  begin
    isOk := true;
    close;
  end;

  if Key = vk_Escape then
    close;

end;

end.

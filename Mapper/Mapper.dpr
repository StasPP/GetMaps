program Mapper;

uses
  Forms,
  GoogleDownload in '..\GoogleDownload.pas',
  AsdbMap in '..\AsdbMap.pas',
  MainFm in 'MainFm.pas' {MainForm},
  NewMark in '..\NewMark.pas' {NewMarkerForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TTestFm, TestFm);
  Application.CreateForm(TNewMarkerForm, NewMarkerForm);
  Application.Run;
end.

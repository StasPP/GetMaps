unit MapperFm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Math, GeoFunctions, GeoFiles, GeoString, GeoClasses,
  Buttons, TabFunctions, StdCtrls, MapFunctions, BasicMapObjects, LangLoader,
  YandexMap,
  DrawFunctions, RTypes, HUD1, GoogleMap, ComCtrls, Menus, MapEditor, ImgList;


type

  TMapFm = class(TForm)
    Stats: TPanel;
    Canv: TPanel;
    EX: TStaticText;
    EY: TStaticText;
    Csys: TStaticText;
    Comments: TLabel;
    Tools: TPanel;
    PC: TPageControl;
    POptions: TTabSheet;
    PGoogle: TTabSheet;
    PMapEd: TTabSheet;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    StaticText2: TStaticText;
    StaticText3: TStaticText;
    StaticText5: TStaticText;
    PopupMenu1: TPopupMenu;
    N81: TMenuItem;
    N101: TMenuItem;
    PopupMenu2: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    EZ: TStaticText;
    B2a: TSpeedButton;
    B2: TSpeedButton;
    B1: TSpeedButton;
    B4: TSpeedButton;
    OpenRoutes: TOpenDialog;
    OpenMaps: TOpenDialog;
    B5a: TSpeedButton;
    B5c: TSpeedButton;
    B4a: TSpeedButton;
    B01: TSpeedButton;
    B5: TSpeedButton;
    B5b: TSpeedButton;
    PopupMenu3: TPopupMenu;
    B5d: TSpeedButton;
    SaveM: TSaveDialog;
    JumpBase: TSpeedButton;
    JumpRoutes: TSpeedButton;
    Panel1: TPanel;
    DopPan: TPanel;
    m2: TSpeedButton;
    m3: TSpeedButton;
    AZoom: TCheckBox;
    ImageList1: TImageList;
    Image1: TImage;
    PopupMenu4: TPopupMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    Bevel1: TBevel;

    procedure FormCreate(Sender: TObject);
    procedure OnDeviceCreate(Sender: TObject; Param: Pointer; var Handled: Boolean);
    procedure TimerEvent(Sender:TObject);
    procedure RenderEvent(Sender:TObject);

    procedure ShowCurPos;
    procedure ModeButtons;

    procedure DoAZoom(isAuto:Boolean);
    procedure ForceAZoom;

    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);

    procedure CanvMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure CanvMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure CsysClick(Sender: TObject);

    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CanvMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure N81Click(Sender: TObject);
    procedure N101Click(Sender: TObject);
    procedure StaticText3Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure StaticText2Click(Sender: TObject);
    procedure B1Click(Sender: TObject);
    procedure B2aClick(Sender: TObject);
    procedure B4Click(Sender: TObject);
    procedure B4aClick(Sender: TObject);
    procedure B5cClick(Sender: TObject);
    procedure B5aClick(Sender: TObject);
    procedure PCChange(Sender: TObject);
    procedure B5dClick(Sender: TObject);

    procedure OnShowHint(var HintStr: string; var CanShow: Boolean;
        var HintInfo: THintInfo);

    procedure AddPopupItems(var PopupMenu: TPopupMenu; ItmName:String);
    procedure PopupMenuItemsClick(Sender: TObject);
    procedure B5bClick(Sender: TObject);
    procedure JumpBaseClick(Sender: TObject);
    procedure JumpRoutesClick(Sender: TObject);

    procedure ResetMs;
    procedure SetM(N:Integer);
    procedure m1Click(Sender: TObject);
    procedure m2Click(Sender: TObject);
    procedure m3Click(Sender: TObject);
    procedure MapSourceChange(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure PopupMenu2Popup(Sender: TObject);
    procedure POptionsShow(Sender: TObject);
    procedure PGoogleShow(Sender: TObject);
  private
    { Private declarations }
    procedure AppOnMessage(var MSG :TMsg; var Handled :Boolean);
  public

    procedure LoadSettings;

    var
      CoordSysN : Integer;
    { Public declarations }
  end;


var
  MapFm: TMapFm;

  idx, oldIdX: longInt;
  HintX,HintY: Integer;

  MapSource: Integer = -1;

  /// Settings
  JustStarted :Boolean = false;
  OpenGL      :Boolean = false;
  ShowMaps    :Boolean = true;
  BigCur      :Boolean = false;
  Smooth      :Boolean = true;

  MyDir       :String;

  /// Colors
  BackGroundColor :Cardinal = $FF3A3A3A;
  LinesColor      :Cardinal = $FF5D5D5D;
  ChoosedColor    :Cardinal = $FFF16161;
  ObjColor        :Cardinal = $FF0BC6F4;
  IntColor        :Cardinal = $9F0BC6F4;

  CanvMoveOnly    :boolean;
  CanvMove        :integer = 0;

implementation

uses
 Vectors2, Vectors2px, AsphyreTimer, AsphyreFactory, AsphyreTypes, AsphyreDb,
 AbstractDevices, AsphyreImages, AsphyreFonts, DX9Providers,
 AbstractCanvas, OGLProviders, LoadData, NewMark, CoordSysFm, GeoCalcUnit;

{$R *.dfm}


procedure TMapFm.AppOnMessage(var MSG: TMsg; var Handled: Boolean);
begin
  if not MapFm.Visible then
    exit;

  if not Timer.Enabled then
    exit;

  if MSG.message = WM_MOUSEWHEEL then
  Begin
    Handled := true;
    Perform(WM_MOUSEWHEEL,MSG.wParam,0);
  End;

   if MSG.message = WM_KEYDOWN then
  Begin
    Handled := true;
    Perform(WM_KEYDOWN,MSG.wParam,0);
  End;
end;

procedure TMapFm.CanvMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  MShift.X := x ;
  MShift.Y := y ;
  CanvMoveOnly := false;
  CanvMove := 0;
  GoogleMultiAdd := false;
  YandexMultiAdd := false;

  case PC.ActivePageIndex of
    0: begin


        if (ClickMode = 2) then
        begin
          ClickMode := 1;
          SetBaseBL(CanvCursorBL.Lat, CanvCursorBL.Long);
          ModeButtons;
        end;
      { WaitForCenter := false;
       A := CanvCursorBL;
       B := BLToMap(A.lat, A.long);
       A := MapToBL(B.X, B.y);
       SetBaseBL(A.Lat, A.Long);}
    end;
    1: begin
     case MapSource of

      0: begin
      if (ssLeft in Shift)or(Button = mbLeft) then
      Begin
        if (ssShift in Shift)or(m2.Flat = false) then
        Begin
          GoogleMultiAdd := true;
          GoogleMultiAddMode := true;
          GoogleMultiAddBegin := CanvCursorBL;
          GoogleMultiAddEnd := CanvCursorBL;
        End;

        if (ssCtrl in Shift)or(m3.Flat = false) then
        Begin
          GoogleMultiAdd := true;
          GoogleMultiAddMode := false;
          GoogleMultiAddBegin := CanvCursorBL;
          GoogleMultiAddEnd:= CanvCursorBL;
        End;
      End;
      end;
      1:  if (ssLeft in Shift)or(Button = mbLeft) then
      Begin
        if (ssShift in Shift)or(m2.Flat = false) then
        Begin
          YandexMultiAdd := true;
          YandexMultiAddMode := true;
          YandexMultiAddBegin := CanvCursorBL;
          YandexMultiAddEnd := CanvCursorBL;
        End;

        if (ssCtrl in Shift)or(m3.Flat = false) then
        Begin
          YandexMultiAdd := true;
          YandexMultiAddMode := false;
          YandexMultiAddBegin := CanvCursorBL;
          YandexMultiAddEnd:= CanvCursorBL;
        End;
      End;
     end;
    end;

  end;
end;

const CanvMoveMax = 25;

procedure TMapFm.CanvMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
   MapFm.SetFocus;

   CanvCursor.X  := x;
   CanvCursor.Y  := y;
   CanvCursorBL := ScreenToBL(CanvCursor.X,CanvCursor.Y);

   case PC.ActivePageIndex of
      0,2: Begin

         if (ClickMode < 6)and(ssLeft in Shift) or (ssMiddle in Shift) then
         begin
            Center.x := Center.x - ( x - MShift.X ) * Scale;
            Center.y := Center.y + ( y - MShift.Y ) * Scale;
            if {(PC.ActivePageIndex = 1)and}(ssLeft in Shift) then
            begin
              if not CanvMoveOnly then
                 CanvMove := CanvMove + abs(x - MShift.X)+abs(y - MShift.Y);
              if CanvMove > CanvMoveMax then
                 CanvMoveOnly := true;
            end;

            MShift.X := x ;
            MShift.Y := y ;
        end;

        if (ClickMode = 2) then
        begin
          WaitForCenter := false;
          SetBaseBL(CanvCursorBL.Lat, CanvCursorBL.Long);
        end;

      End;



      1: Begin

        case MapSource of

         0: begin
  ////////// GOOGLE
          if (ssLeft in Shift) and (GoogleMultiAdd) then
          Begin
            GoogleMultiAdd := false;

            if (ssShift in Shift)or(m2.Flat = false) then
            Begin
              GoogleMultiAdd := true;
              GoogleMultiAddMode := true;
              GoogleMultiAddEnd := CanvCursorBL;
            End
             else
              if (ssCtrl in Shift)or(m3.Flat = false) then
              Begin
                GoogleMultiAdd := true;
                GoogleMultiAddMode := false;
                GoogleMultiAddEnd := CanvCursorBL;
              End;
          End
            else
            if (ssLeft in Shift)or (ssMiddle in Shift)or(ssRight in Shift) then
            begin
              Center.x := Center.x - ( x - MShift.X ) * Scale;
              Center.y := Center.y + ( y - MShift.Y ) * Scale;
              if (ssLeft in Shift) then
              begin
                if not CanvMoveOnly then
                   CanvMove := CanvMove + abs(x - MShift.X)+abs(y - MShift.Y);
                if CanvMove > CanvMoveMax then
                   CanvMoveOnly := true;
              end;

              MShift.X := x ;
              MShift.Y := y ;
            end;
       end;
   //// YANDEX
       1: begin
          if (ssLeft in Shift) and (YandexMultiAdd) then
          Begin
            YandexMultiAdd := false;

            if (ssShift in Shift)or(m2.Flat = false) then
            Begin
              YandexMultiAdd := true;
              YandexMultiAddMode := true;
              YandexMultiAddEnd := CanvCursorBL;
            End
             else
              if (ssCtrl in Shift)or(m3.Flat = false) then
              Begin
                YandexMultiAdd := true;
                YandexMultiAddMode := false;
                YandexMultiAddEnd := CanvCursorBL;
              End;
          End
           else
            if (ssLeft in Shift)or (ssMiddle in Shift)or(ssRight in Shift) then
            begin
              Center.x := Center.x - ( x - MShift.X ) * Scale;
              Center.y := Center.y + ( y - MShift.Y ) * Scale;
              if (ssLeft in Shift) then
              begin
                if not CanvMoveOnly then
                   CanvMove := CanvMove + abs(x - MShift.X)+abs(y - MShift.Y);
                if CanvMove > CanvMoveMax then
                   CanvMoveOnly := true;
              end;

              MShift.X := x ;
              MShift.Y := y ;
           end;
      end;
 ///////////////// Yandex end

     end;    ///// end 0f case



     End;  //// end of 1



   end;   /// end of Active Page case

   ShowCurPos;

end;

procedure RefreshSt;
Begin
  MapFm.StaticText5.Caption := IntToStr(GoogleCount);
  if GoogleCount>30 then
     MapFm.StaticText5.Font.Color := clOlive
     else
     if GoogleCount>40 then
       MapFm.StaticText5.Font.Color := clRed
        else
          MapFm.StaticText5.Font.Color := clBlack;
End;

procedure RefreshYSt;
var I:integer;
Begin
   MapFm.StaticText5.Caption:= IntToStr(YandexCount);
  if YandexCount>30 then
      MapFm.StaticText5.Font.Color := clOlive
     else
     if YandexCount>40 then
        MapFm.StaticText5.Font.Color := clRed
        else
           MapFm.StaticText5.Font.Color := clWindowText;

End;

procedure TMapFm.AddPopupItems(var PopupMenu: TPopupMenu; ItmName:String);
var
  NewItem: TMenuItem;
begin
  NewItem := TMenuItem.Create(PopupMenu1); // create the new item
  PopupMenu.Items.Add(NewItem);// add it to the Popupmenu
  NewItem.Caption := ItmName;
  NewItem.Tag := PopupMenu.Items.Count-1;
  NewItem.OnClick := PopupMenuItemsClick;// assign it an event handler
end;

procedure TMapFm.CanvMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var SysCurPos :TPoint;
    I :Integer;
begin

  if PC.ActivePageIndex = 1 then
  Begin
    if CanvMoveOnly then
       exit;

  case Mapsource of

    0: begin

    //// GOOGLE
    ///
    if (ssLeft in Shift)or(Button = mbLeft) then
    Begin
      if (ssShift in Shift)or(m2.Flat = false) then
      Begin
        GoogleMultiAdd := true;
        GoogleMultiAddMode := true;
        GoogleMultiAddEnd := CanvCursorBL;
        DoMultiAddGoogle;
      End
      else
        if (ssCtrl in Shift)or(m3.Flat = false) then
        Begin
          GoogleMultiAdd := true;
          GoogleMultiAddMode := false;
          GoogleMultiAddEnd := CanvCursorBL;
          DoMultiAddGoogle;
        End
         else
          AddGoogle(GoogleCursor.lat, GoogleCursor.long);
    End;
    GoogleMultiAdd := false;
    RefreshST;
    end;

    //// YA

    1: begin
    if (ssLeft in Shift)or(Button = mbLeft) then
    Begin
      if (ssShift in Shift)or(m2.Flat = false) then
      Begin
        YAndexMultiAdd := true;
        YAndexMultiAddMode := true;
        YAndexMultiAddEnd := CanvCursorBL;
        DoMultiAddYAndex;
      End
      else
        if (ssCtrl in Shift)or(m3.Flat = false) then
        Begin
          YAndexMultiAdd := true;
          YAndexMultiAddMode := false;
          YAndexMultiAddEnd := CanvCursorBL;
          DoMultiAddYAndex;
        End
         else
          AddYAndex(YandexCursor.lat, YandexCursor.long);
    End;
    YandexMultiAdd := false;
    RefreshYST;
    end;



  end; /// end of case

 End;  /// End of ActivePageIndex = 1

 if PC.ActivePageIndex = 2 then
  Begin

    if ClickMode = 5 then
    if  not CanvMoveOnly then
    Begin
     if Button = mbLeft then
      GetMapsUnderPoint(CanvCursorBL.lat, CanvCursorBL.long);

     if Length(ChoosedMaps)>1 then
     Begin
       GetCursorPos(SysCurPos);
       PopupMenu3.Items.Clear;
       for I := 0 to Length(ChoosedMaps) - 1 do
         AddPopupItems(PopupMenu3,ChoosedMapsInfo[I]);

       PopupMenu3.Popup(SysCurPos.X, SysCurPos.Y);
     End;

     if MapChoosed <> -1 then
       B5D.Enabled := true
         else
           B5d.Enabled := false;
    End;
  End;

  ResetMs;
end;

procedure TMapFm.ForceAZoom;
begin
 case MapSource of
     0: Begin
       //  if isAuto then
         // GoogleAutoZoom(Canv.Height*TMashtab[Mashtab]/120)
         //  else
            GoogleAutoZoom(Canv.Height*TMashtab[Mashtab]/170);
        GoogleCursor := GoogleInitBL;
        GetGoogleCursor(CanvCursorBL.lat,CanvCursorBL.long);
        RefreshSt;
     End;

     1: Begin
      // if isAuto then
       //   YandexAutoZoom(Canv.Height*TMashtab[Mashtab]/120)
       //    else
            YAndexAutoZoom(Canv.Height*TMashtab[Mashtab]/170);
        YandexCursor := YandexInitBL;
        GetYandexCursor(CanvCursorBL.lat,CanvCursorBL.long);
        RefreshYSt;
     End;
  end;

end;

procedure TMapFm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ResetSettings;
end;

procedure TMapFm.FormCreate(Sender: TObject);
begin
// SaveLngs;

 Application.OnMessage := AppOnMessage;

 Application.HintPause := 100;
 Application.OnShowHint := OnShowHint;

 MyDir := GetCurrentDir + '\';
 GoogleTmpDir := MyDir + 'Tmp\';
 YandexTmpDir := MyDir + 'Tmp\';
 ForceDirectories(MyDir + 'Tmp\');

 if Fileexists(Mydir+'Data\Ozi.txt') then
    GoogleOziDir := MyDir + 'Ozi\';
  YandexOziDir := GoogleOziDir;

  GeoInit('Data\Sources.loc','','');
  SK := FindDatum('SK42');
  WGS := FindDatum('WGS84') ;

 JustStarted := true;

 // Enable Delphi debugger
 ReportMemoryLeaksOnShutdown:= DebugHook <> 0;

 // Set the display size
 DisplaySize:= Point2px(ClientWidth, ClientHeight);

 // Indicate that we're using DirectX 9
 OpenGL := false;
 if ParamStr(1)='-gl' then
     OpenGL := true;
     
 if OpenGL then
   Factory.UseProvider(idOpenGL)
     else
      Factory.UseProvider(idDirectX9);

 // Create Asphyre components in run-time.
 AsphDevice:= Factory.CreateDevice();
 AsphCanvas:= Factory.CreateCanvas();
 AsphImages:= TAsphyreImages.Create();
 AsphMapImages:= TAsphyreImages.Create();

 AsphFonts:= TAsphyreFonts.Create();
 AsphFonts.Images:= AsphImages;
 AsphFonts.Canvas:= AsphCanvas;

 MediaASDb:= TASDb.Create();
 MediaASDb.FileName:= ExtractFilePath(PChar(MyDir)) + 'Data\mapper.asdb';
 MediaASDb.OpenMode:= opReadOnly;

 AsphDevice.WindowHandle:= Self.Handle;
 AsphDevice.Size    := DisplaySize;
 AsphDevice.Windowed:= True;
 AsphDevice.VSync   := True;      

 EventDeviceCreate.Subscribe(OnDeviceCreate, 0);

 // Attempt to initialize Asphyre device.
 if (not AsphDevice.Initialize()) then
  begin
   ShowMessage('Failed to initialize Asphyre device.');
   Application.Terminate();
   Exit;
  end;

 // Create rendering timer.
 Timer.OnTimer  := TimerEvent;
// Timer.OnProcess:= ProcessEvent;
 Timer.Speed    := 60.0;
 Timer.MaxFPS   := 4000;
 Timer.Enabled  := False;

 ClickMode := 1;
 ModeButtons;
 CoordSysN := -1;
end;

procedure ClearDir(Const Dir:String);

  procedure AddFiles(Dir:string; var FileList:TStringList);
  var
   SearchRec : TSearchrec; //Запись для поиска
  begin
    if FindFirst(Dir + '*.*', faAnyFile, SearchRec) = 0 then
    begin
      if (SearchRec.Name<> '')
        and(SearchRec.Name <> '.')
        and(SearchRec.Name <> '..')
        and not ((SearchRec.Attr and faDirectory) = faDirectory) then
          FileList.Add(SearchRec.Name);
      while FindNext(SearchRec) = 0 do
        if (SearchRec.Name <> '')
          and(SearchRec.Name <> '.')
          and(SearchRec.Name <> '..')
          and not ((SearchRec.Attr and faDirectory) = faDirectory)  then
             FileList.Add(SearchRec.Name);
      FindClose(Searchrec);
    end;
  end;

var
 FileList : TStringList;
 I:Integer;
begin
  FileList := TStringList.Create;
  AddFiles (Dir, FileList);

    for I := 0 to FileList.Count - 1 do
    try
      DeleteFile(PChar(Dir+FileList[i]));
    except
    end;
    FileList.Destroy
end;

procedure TMapFm.FormDestroy(Sender: TObject);
begin
 Timer.Enabled:= False;
 FreeAndNil(AsphFonts);
 FreeAndNil(AsphImages);
 FreeAndNil(AsphMapImages);
 FreeAndNil(MediaASDb);
 FreeAndNil(AsphCanvas);
 FreeAndNil(AsphDevice);
 ClearDir(GoogleTmpDir+'\');
end;

procedure TMapFm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin

  if Key = VK_F2 then
    if Windowstate = wsMaximized then
    begin
      Windowstate := wsNormal;
      BorderStyle := BsSingle;
    end
      else
        Begin
          BorderStyle := BsNone;
          Windowstate := wsMaximized;
        End;

//// + - клавиши

 if (Key = 187) or (Key = 107) then
 begin
    Shiftmap(1);
    if AZoom.Checked then
      DoAZoom(false);
 end;

 if (Key = 189) or (Key = 109) then
 begin
    Shiftmap(0);
    if AZoom.Checked then
      DoAZoom(false);
 end;

//// W S A D

 if (Key = 87)  or (Key = vk_Up) then
    Shiftmap(2);

 if (Key = 83) or (Key = vk_Down) then
    Shiftmap(3);

 if (Key = 65) or (Key = vk_Left) then
    Shiftmap(4);

 if (Key = 68) or (Key = vk_Right) then
    Shiftmap(5);

 if Key = vk_Tab then
 if ClickMode=5 then
 Begin
   if MapChoosed<>-1 then
   Begin
     Inc(MapChoosed);
     if MapChoosed >= Length(MapList) then
       MapChoosed := 0;
   End;
 End;

 if Key = vk_Delete then
 if ClickMode=5 then
 Begin
   if MapChoosed<>-1 then
   Begin
     B5d.OnClick(Sender);
   End;
 End;
end;

procedure TMapFm.FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin

  if (PC.ActivePageIndex=1) and (ssShift in Shift) then
    begin
      case MapSource of
        0: GoogleZoomDown;
        1: YandexZoomDown;
      end;

    end
    else
     ShiftMap(0);

  if AZoom.Checked then
    DoAZoom(false);

   case MapSource of
        0: StaticText3.Caption := IntToStr(Zooma);
        1: StaticText3.Caption := IntToStr(YZooma);
   end;
end;

procedure TMapFm.FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  if (PC.ActivePageIndex=1) and (ssShift in Shift) then
   case MapSource of
        0: GoogleZoomUp;
        1: YandexZoomUp;
      end
    else
      ShiftMap(1);

   if (PC.ActivePageIndex=1) and (AZoom.Checked) then
     DoAZoom(false);

   case MapSource of
        0: StaticText3.Caption := IntToStr(Zooma);
        1: StaticText3.Caption := IntToStr(YZooma);
      end;
   
end;

procedure TMapFm.FormResize(Sender: TObject);
begin
  DisplaySize := Point2px(Canv.ClientWidth, Canv.ClientHeight);
  DispSize := DisplaySize;
  AsphDevice.Size := DisplaySize;
end;

procedure TMapFm.FormShow(Sender: TObject);
begin
  Timer.Enabled  := True;
  if CoordSysN=-1 then
     Csys.Caption := inf[14];
  if MapSource =-1 then
  begin
    if GoogleKey<>'' then
      PopupMenu4.Items[0].Click
       else
         PopupMenu4.Items[1].Click;
    ForceAZoom;     
  end;
end;

procedure TMapFm.Image1Click(Sender: TObject);
var P:Tpoint;
begin
  GetCursorPos(P);
  PopupMenu4.Items[0].Enabled := GoogleKey<>'';
  PopupMenu4.Popup(P.x,P.y);
end;

procedure TMapFm.JumpBaseClick(Sender: TObject);
begin
 Center.x := Base[1].x;
 Center.y := Base[1].y;

 ShiftCenter.x := Center.x;
 ShiftCenter.y := Center.y;
end;

procedure TMapFm.JumpRoutesClick(Sender: TObject);
var xmax, ymax, xmin, ymin: real;
    i, j : integer;
begin
  xmax := Base[1].x;
  ymax := Base[1].y;
  xmin := Base[1].x;
  ymin := Base[1].y;

  RecomputeRoutes(WaitForZone);

  if RouteCount > 0 then
  Begin
     xmax := Route[0].WPT[0].x;
     ymax := Route[0].WPT[0].y;
     xmin := Route[0].WPT[0].x;
     ymin := Route[0].WPT[0].y;

     for I := 0 to RouteCount - 1 do
     Begin
       for j := 0 to length(Route[i].WPT)- 1 do
       Begin
          if Route[i].WPT[j].x < xmin then
             xmin := Route[i].WPT[j].x;
          if Route[i].WPT[j].x > xmax then
             xmax := Route[i].WPT[j].x;

           if Route[i].WPT[j].y < ymin then
             ymin := Route[i].WPT[j].y;
          if Route[i].WPT[j].y > ymax then
             ymax := Route[i].WPT[j].y;
       End;
     End;
  End
    else
      exit;

  Center.x := (xmin+xmax)/2;
  Center.y := (ymin+ymax)/2;

  I := 0;
  repeat
     inc(i);
     if abs(xmin-xmax) > abs(ymin-ymax) then
       J := trunc( abs(xmin-xmax) /TMashtab[I])
         else
          J := trunc( abs(ymin-ymax) /TMashtab[I])
  until (I >= MaxMashtab-1) or (J <= Canv.Height div 100);
  Mashtab := I;


  ShiftCenter.x := Center.x;
  ShiftCenter.y := Center.y;

  

   if AZoom.Checked then
      DoAZoom(false);
end;

procedure TMapFm.LoadSettings;
begin
//
end;

procedure TMapFm.m1Click(Sender: TObject);
begin
  SetM(1);
end;

procedure TMapFm.m2Click(Sender: TObject);
begin
  SetM(2);
end;

procedure TMapFm.m3Click(Sender: TObject);
begin
  SetM(3);
end;

procedure TMapFm.MapSourceChange(Sender: TObject);
begin
 // SendMessage(Mapsource.Handle, CB_SETDROPPEDWIDTH, Mapsource.Items.Count * (ImageList1.Height+2)); 
end;

procedure TMapFm.MenuItem1Click(Sender: TObject);
begin
  Image1.Canvas.FillRect(Rect(0,0,32,32));
  ImageList1.Draw(Image1.Canvas,0,0,0);
  MapSource := 0;
    RefreshSt;
end;

procedure TMapFm.MenuItem2Click(Sender: TObject);
begin
  Image1.Canvas.FillRect(Rect(0,0,32,32));
  ImageList1.Draw(Image1.Canvas,0,0,1);
  MapSource := 1;
    RefreshYSt;
end;

procedure TMapFm.ModeButtons;
var
  i:Integer;
begin
  for i := 0 to ComponentCount-1  do
   if Components[i] is TSpeedButton  then
      if (TSpeedButton(Components[i]).Name <> 'B' + IntToStr(ClickMode)) and
         (TSpeedButton(Components[i]).Name <> 'B0' + IntToStr(ClickMode)) then
         TSpeedButton(Components[i]).Flat := True
           else
              TSpeedButton(Components[i]).Flat := False;
  ResetMs;
  DopPan.Visible := PC.ActivePageIndex = 1;          
end;

procedure TMapFm.N101Click(Sender: TObject);
begin
  case MapSource of
        0: GoogleZoomDown;
        1: YandexZoomDown;
  end;
  case MapSource of
        0: StaticText3.Caption := IntToStr(Zooma);
        1: StaticText3.Caption := IntToStr(YZooma);
  end;
  
end;

procedure TMapFm.N1Click(Sender: TObject);
begin
  GoogleStyle := GoogleMapStyles[0];
  YandexStyle := YandexMapStyles[0];

  MapFm.StaticText2.Caption := N1.Caption;
end;

procedure TMapFm.N2Click(Sender: TObject);
begin
 GoogleStyle := GoogleMapStyles[1];
 YandexStyle := YandexMapStyles[1];
 MapFm.StaticText2.Caption := N2.Caption;
end;

procedure TMapFm.N3Click(Sender: TObject);
begin
 GoogleStyle := GoogleMapStyles[2];
 YandexStyle := YandexMapStyles[2];
 MapFm.StaticText2.Caption := N3.Caption;
end;

procedure TMapFm.N4Click(Sender: TObject);
begin
  if Mapsource = 1 then
     exit;
  GoogleStyle := GoogleMapStyles[3];
  MapFm.StaticText2.Caption := N4.Caption;
end;

procedure TMapFm.N81Click(Sender: TObject);
begin
  case MapSource of
        0: GoogleZoomUp;
        1: YandexZoomUp;
  end;
  case MapSource of
        0: StaticText3.Caption := IntToStr(Zooma);
        1: StaticText3.Caption := IntToStr(YZooma);
  end;
end;

procedure TMapFm.OnDeviceCreate(Sender: TObject; Param: Pointer;
  var Handled: Boolean);
var
 Success: Boolean;
begin
 // This variable returns "Success" to Device initialization, so if you
 // set it to False, device creation will fail.
 Success:= PBoolean(Param)^;
 try
   AsphImages.RemoveAll();
   AsphMapImages.RemoveAll();
   AsphFonts.RemoveAll();

   // This image is used by our bitmap font.
   AsphImages.AddFromASDb('font0.image', MediaASDb, '', False);

   AsphImages.AddFromASDb('lock.image', MediaASDb, '', False);
   AsphImages.AddFromASDb('unlock.image', MediaASDb, '', False);
   AsphImages.AddFromASDb('flag.image', MediaASDb, '', False);
   AsphImages.AddFromASDb('flag_big.image', MediaASDb, '', False);
   AsphImages.AddFromASDb('marker1.image', MediaASDb, '', False);
   AsphImages.AddFromASDb('marker1_big.image', MediaASDb, '', False);

   AsphImages.AddFromASDb('sat.image', MediaASDb, '', False);
   AsphImages.AddFromASDb('dop.image', MediaASDb, '', False);
   AsphImages.AddFromASDb('dot.image', MediaASDb, '', False);

   AsphImages.AddFromASDb('addcell.image', MediaASDb, '', False);
   AsphImages.AddFromASDb('okcell.image', MediaASDb, '', False);
   AsphImages.AddFromASDb('delcell.image', MediaASDb, '', False);

   Font0:= AsphFonts.Insert('Data/mapper.asdb | font0.xml', 'font0.image');

   AsphFonts[Font0].Kerning:=2;

 finally
   Success:= true ;
 end;

 PBoolean(Param)^:= Success;
end;

procedure TMapFm.OnShowHint(var HintStr: string; var CanShow: Boolean;
  var HintInfo: THintInfo);
begin
 if (HintInfo.HintControl is TListBox) then
  Begin
    with HintInfo.HintControl as TListBox do
    begin
      HintInfo.HintPos := HintInfo.HintControl.ClientToScreen(Point(HintX,HintY));
      HintStr := HintStr;
    end;
  End;
  inherited;
end;

procedure TMapFm.PCChange(Sender: TObject);
begin
   ClickMode := 1;
   MapChoosed := -1;
   ModeButtons;
end;

procedure TMapFm.PGoogleShow(Sender: TObject);
begin
 if AZoom.Checked then
      ForceAZoom;
end;

procedure TMapFm.POptionsShow(Sender: TObject);
begin
 // DoAZoom(false);
end;

procedure TMapFm.PopupMenu2Popup(Sender: TObject);
begin
 N4.Enabled :=  MapSource = 0;
end;

procedure TMapFm.PopupMenuItemsClick(Sender: TObject);
begin
  with Sender as TMenuItem do
    MapChoosed := ChoosedMaps[tag];
  B5d.Enabled := MapChoosed <>-1;
end;

const SmoothScale = true;

procedure TMapFm.RenderEvent(Sender: TObject);
begin
  if not SmoothScale then
  Begin
     Scale  := TMashtab[Mashtab]/100;
     _Scale := Scale;
  End
     else
        AxcelScale(Timer.Delta);


  if ShowMaps then
    DrawMaps(AsphCanvas,AsphMapImages, Timer.Delta);

  DrawLines(AsphCanvas, LinesColor, Smooth);
  DrawRoutes(AsphCanvas, ObjColor, ObjColor, ObjColor, ChoosedColor, $FFFFFFFF, Smooth);
                         {ChoosedColor, RoutesColor, DoneColor, FrameColor}
  DrawBase(AsphCanvas,AsphImages, ChoosedColor);

  if PC.ActivePageIndex = 1 then
  Begin
    case MapSource of
      0: begin
        DrawGoogle(AsphCanvas,AsphImages);

        if GetGoogleCursor(CanvCursorBL.Lat, CanvCursorBL.Long) then
           DrawGoogleCursor(AsphCanvas, AsphImages);
      end;


      1: begin
        DrawYandex(AsphCanvas,AsphImages);

        if GetYandexCursor(CanvCursorBL.Lat, CanvCursorBL.Long) then
           DrawYandexCursor(AsphCanvas, AsphImages);
      end;

    end;
  
  End;

 ScaleLine(AsphCanvas, false, true, 'm', 'km', 0, IntColor);
end;


procedure TMapFm.ResetMs;
var i,j :integer;
begin
 for j := 1 to 4  do
 for i := 0 to ComponentCount-1  do
   if Components[i] is TSpeedButton  then
      if (TSpeedButton(Components[i]).Name = 'm' + IntToStr(j))
         then
           TSpeedButton(Components[i]).Flat := true;
end;

procedure TMapFm.SetM(N: Integer);
var i,j :integer;
begin
 for j := 1 to 4  do
 for i := 0 to ComponentCount-1  do
   if Components[i] is TSpeedButton  then
      if (TSpeedButton(Components[i]).Name = 'm' + IntToStr(j))
         then
         begin
           if J=N then
             TSpeedButton(Components[i]).Flat := false
           else
             TSpeedButton(Components[i]).Flat := true;
         end;
end;

procedure TMapFm.ShowCurPos;
var cX, cY, cZ, B, L, H :Double;
begin

   if CoordSysN < 0 then
   Begin
     EX.Caption :=  DegToDMS(CanvCursorBL.Lat,true,5);
     EY.Caption :=  DegToDMS(CanvCursorBL.Long,false,5);
   End
    else
     Begin
       Geo1ForceToGeo2(CanvCursorBL.Lat,CanvCursorBL.Long,0, WGS,
                       CoordinateSystemList[CoordSysN].DatumN, B, L, H);

       DatumToCoordinateSystem(CoordSysN,B,L,H,cX,cY,cZ);

       if EZ.Visible then
       Begin
         EZ.Hide;
         CSys.Left := EY.Left + EY.Width + 5;
       End;



       case CoordinateSystemList[CoordsysN].ProjectionType of
          0:begin
             EX.Caption := DegToDMS(cX,true, 5, false);
             EY.Caption := DegToDMS(cY,false,5, false);
          end;
          1:begin
            EX.Caption := Format('%.3f',[cX]);
            EY.Caption := Format('%.3f',[cY]);
            EZ.Caption := Format('%.3f',[cZ]);
            EZ.Show;
            CSys.Left := EZ.Left + EZ.Width + 5;
          end;
          2..4:begin
            EX.Caption := Format('%n',[cX]);
            EY.Caption := Format('%n',[cY]);
          end;
       end;
     End;

end;

procedure TMapFm.SpeedButton1Click(Sender: TObject);
begin

case MapSource of
  0: begin
    if GoogleCount = 0 then
      exit;

    DownloadSelected;
    RefreshST;
    PC.ActivePageIndex := 2;

  end;
  1:  begin
    if YandexCount = 0 then
     exit;

    DownloadSelectedYandex;
    RefreshYST;
    PC.ActivePageIndex := 2;
  end;

end;

end;

procedure TMapFm.SpeedButton2Click(Sender: TObject);
begin
case MapSource of
  0: begin
    ResetGoogle;
    RefreshST;
  end;
  1: begin
    ResetYandex;
    RefreshYST;
  end;
end;
end;

procedure TMapFm.B1Click(Sender: TObject);
var s: string;
begin
   s := TSpeedButton(Sender).Name;
   s := Copy(s, 2, length(s)-1);
   ClickMode := StrToInt(s);
   ModeButtons;
end;

procedure TMapFm.B2aClick(Sender: TObject);
begin

 Timer.Enabled := false;
 GeoCalcFm.PointB := Base[2].x;
 GeoCalcFm.PointL := Base[2].y;
 GeoCalcFm.ShowModal;
 ClickMode := 1;
 Timer.Enabled := true;
 ModeButtons;
 SetBaseBL(GeoCalcFm.PointB,GeoCalcFm.PointL);
end;

procedure TMapFm.B4aClick(Sender: TObject);
begin
  ResetRoutes;
end;

procedure TMapFm.B4Click(Sender: TObject);
var S: String;
    J: integer;
begin
 Timer.Enabled := False;
 if OpenRoutes.Execute then
  if AnsiLowerCase(Copy(OpenRoutes.FileName, Length(OpenRoutes.FileName)-3,4))='.rts' then
  Begin
    LoadRoutesFromRTS(OpenRoutes.FileName)
  End Else
  Begin
    S := OpenRoutes.FileName;
    LoadRData.OpenFile(S);

    J := Pos('\', S);
    while J > 1 do
    Begin
       S := Copy(S, J+1, Length(S)-J);
       J := Pos('\', S);
    End;

    WaitForZone := true;

    LoadRData.ShowModal;
  End;
  Timer.Enabled := True;
  JumpRoutes.Click;
  ForceAZoom;
end;

procedure TMapFm.B5aClick(Sender: TObject);
var I:Integer;
begin
 if OpenMaps.Execute then
 Begin
   for I := 0 to OpenMaps.Files.Count - 1 do
    LoadMaps(OpenMaps.Files[I], GoogleTmpDir,
         AsphMapImages, I+1,  OpenMaps.Files.count);
 End;
end;

procedure TMapFm.B5bClick(Sender: TObject);
var I, J :Integer;
    S :String;
begin
   for I := 0 to Length(MapAsdbList) - 1 do
   Begin
     S := MapAsdbList[I];

     J := Pos('\', S);
     while J > 1 do
     Begin
       S := Copy(S, J+1, Length(S)-J);
       J := Pos('\', S);
     End;

     if MessageDLG(inf[16]+ S +' ?', MtConfirmation, mbYesNo, 0) = 6 then
     begin
        if SaveM.Execute() then
          SaveToAsdb(MapAsdbList[I],SaveM.FileName);
     end
       else
         continue;



   End;
end;

procedure TMapFm.B5cClick(Sender: TObject);
begin
 ResetMaps(AsphMapImages);
end;

procedure TMapFm.B5dClick(Sender: TObject);
begin
  if  MapChoosed <>-1 then
      DeleteMap(MapChoosed);
  MapChoosed := -1;
  B5d.Enabled := false;
end;

procedure TMapFm.CsysClick(Sender: TObject);
begin
  Timer.Enabled  := False;
  CSForm.ShowModal;
  if CoordSysN <> -1 then
    Csys.Caption := CoordinateSystemList[CoordSysN].Caption;
  Timer.Enabled  := True;
end;

procedure TMapFm.DoAZoom(isAuto: Boolean);
begin

  if (PC.ActivePageIndex<>1) then
     exit;
  case MapSource of
     0: Begin
         if isAuto then
          GoogleAutoZoom(Canv.Height*TMashtab[Mashtab]/120)
           else
            GoogleAutoZoom(Canv.Height*TMashtab[Mashtab]/170);
        GoogleCursor := GoogleInitBL;
        GetGoogleCursor(CanvCursorBL.lat,CanvCursorBL.long);
        RefreshSt;
     End;

     1: Begin
       if isAuto then
          YandexAutoZoom(Canv.Height*TMashtab[Mashtab]/120)
           else
            YAndexAutoZoom(Canv.Height*TMashtab[Mashtab]/170);
        YandexCursor := YandexInitBL;
        GetYandexCursor(CanvCursorBL.lat,CanvCursorBL.long);
        RefreshYSt;
     End;
  end;



end;

procedure TMapFm.StaticText2Click(Sender: TObject);
var P: TPoint;
begin
  P := ClientToscreen(Point( 5 + StaticText2.Left, 25 + StaticText2.Top));
  PopupMenu2.Popup(P.X, P.Y);
end;

procedure TMapFm.StaticText3Click(Sender: TObject);
var P:TPoint;
begin
  P := ClientToscreen(Point(StaticText3.Left + 5, StaticText3.Top + 25));
  PopupMenu1.Popup(P.X, P.Y);
end;

procedure TMapFm.TimerEvent(Sender: TObject);
begin

  AsphDevice.Render(Canv.Handle, RenderEvent, BackGroundColor);
  Timer.Process();

end;

end.

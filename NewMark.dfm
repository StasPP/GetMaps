object NewMarkerForm: TNewMarkerForm
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'NewMarkerForm'
  ClientHeight = 37
  ClientWidth = 290
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object MarkerName: TEdit
    Left = 8
    Top = 8
    Width = 217
    Height = 21
    MaxLength = 20
    TabOrder = 0
    OnKeyDown = MarkerNameKeyDown
  end
  object Button1: TButton
    Left = 231
    Top = 6
    Width = 50
    Height = 25
    Caption = 'OK'
    TabOrder = 1
    OnClick = Button1Click
  end
end

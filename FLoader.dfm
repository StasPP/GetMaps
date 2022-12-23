object FLoadGPS: TFLoadGPS
  Left = 0
  Top = 0
  AutoSize = True
  BorderStyle = bsToolWindow
  Caption = 'Loading data...'
  ClientHeight = 49
  ClientWidth = 457
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 457
    Height = 49
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object MapLoad: TLabel
      Left = 5
      Top = 5
      Width = 131
      Height = 13
      Caption = #1047#1072#1075#1088#1091#1079#1082#1072' '#1088#1072#1089#1090#1088#1086#1074#1099#1093' '#1082#1072#1088#1090
    end
    object LCount: TLabel
      Left = 208
      Top = 5
      Width = 16
      Height = 13
      Caption = '1/1'
    end
    object Label1: TLabel
      Left = 5
      Top = 5
      Width = 73
      Height = 13
      Caption = #1057#1082#1072#1095#1080#1074#1072#1085#1080#1077'...'
      Visible = False
    end
    object Label2: TLabel
      Left = 5
      Top = 5
      Width = 79
      Height = 13
      Caption = #1050#1086#1085#1074#1077#1088#1090#1072#1094#1080#1103'...'
      Visible = False
    end
    object ProgressBar1: TProgressBar
      Left = 0
      Top = 27
      Width = 457
      Height = 22
      Align = alBottom
      TabOrder = 0
    end
  end
end

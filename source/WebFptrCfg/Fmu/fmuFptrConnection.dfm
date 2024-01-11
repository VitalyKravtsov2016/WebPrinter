object fmFptrConnection: TfmFptrConnection
  Left = 742
  Top = 255
  Width = 496
  Height = 318
  Caption = #1055#1086#1076#1082#1083#1102#1095#1077#1085#1080#1077
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    480
    279)
  PixelsPerInch = 96
  TextHeight = 13
  object gbConenctionParams: TTntGroupBox
    Left = 8
    Top = 8
    Width = 465
    Height = 265
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'WebPrinter'
    TabOrder = 0
    DesignSize = (
      465
      265)
    object lblConnectTimeout: TTntLabel
      Left = 16
      Top = 56
      Width = 143
      Height = 13
      Caption = #1058#1072#1081#1084#1072#1091#1090' '#1087#1086#1076#1082#1083#1102#1095#1077#1085#1080#1103', '#1089#1077#1082'.:'
    end
    object lblWebkassaAddress: TTntLabel
      Left = 125
      Top = 24
      Width = 34
      Height = 13
      Caption = #1040#1076#1088#1077#1089':'
    end
    object lblResultCode: TTntLabel
      Left = 104
      Top = 88
      Width = 55
      Height = 13
      Caption = #1056#1077#1079#1091#1083#1100#1090#1072#1090':'
    end
    object seConnectTimeout: TSpinEdit
      Left = 168
      Top = 56
      Width = 288
      Height = 22
      Anchors = [akLeft, akTop, akRight]
      MaxValue = 0
      MinValue = 0
      TabOrder = 1
      Value = 0
      OnChange = ModifiedClick
    end
    object edtAddress: TEdit
      Left = 168
      Top = 24
      Width = 289
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      Text = 'edtAddress'
      OnChange = ModifiedClick
    end
    object btnTestConnection: TButton
      Left = 312
      Top = 232
      Width = 145
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = #1055#1088#1086#1074#1077#1088#1080#1090#1100' '#1087#1086#1076#1082#1083#1102#1095#1077#1085#1080#1077
      TabOrder = 2
      OnClick = btnTestConnectionClick
    end
    object stResultCode: TStaticText
      Left = 168
      Top = 88
      Width = 289
      Height = 137
      Anchors = [akLeft, akTop, akRight, akBottom]
      AutoSize = False
      BorderStyle = sbsSunken
      TabOrder = 3
    end
  end
end

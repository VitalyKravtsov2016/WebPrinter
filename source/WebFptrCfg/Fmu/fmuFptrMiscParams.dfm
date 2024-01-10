object fmFptrMiscParams: TfmFptrMiscParams
  Left = 623
  Top = 224
  AutoScroll = False
  BorderIcons = [biSystemMenu]
  Caption = #1055#1088#1086#1095#1077#1077
  ClientHeight = 329
  ClientWidth = 536
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  DesignSize = (
    536
    329)
  PixelsPerInch = 96
  TextHeight = 13
  object lblAmountDecimalPlaces: TTntLabel
    Left = 8
    Top = 16
    Width = 248
    Height = 13
    Caption = #1050#1086#1083#1080#1095#1077#1089#1090#1074#1086' '#1079#1085#1072#1082#1086#1074' '#1087#1086#1089#1083#1077' '#1079#1072#1087#1103#1090#1086#1081' '#1074' '#1082#1086#1083#1080#1095#1077#1089#1090#1074#1077':'
  end
  object cbAmountDecimalPlaces: TComboBox
    Left = 264
    Top = 16
    Width = 266
    Height = 21
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    ItemHeight = 13
    TabOrder = 0
    OnChange = ModifiedClick
    Items.Strings = (
      '0'
      '2')
  end
end

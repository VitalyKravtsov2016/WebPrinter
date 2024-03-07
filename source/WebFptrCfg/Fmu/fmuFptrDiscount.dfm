object fmFptrDiscount: TfmFptrDiscount
  Left = 565
  Top = 420
  AutoScroll = False
  BorderIcons = [biSystemMenu]
  Caption = #1057#1082#1080#1076#1082#1080
  ClientHeight = 184
  ClientWidth = 436
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  DesignSize = (
    436
    184)
  PixelsPerInch = 96
  TextHeight = 13
  object lblClassCode: TLabel
    Left = 40
    Top = 48
    Width = 56
    Height = 13
    Caption = #1050#1086#1076' '#1048#1050#1055#1059':'
  end
  object chbRecDiscountOnClassCode: TCheckBox
    Left = 8
    Top = 16
    Width = 417
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = #1057#1082#1080#1076#1082#1080' '#1088#1072#1079#1088#1077#1096#1077#1085#1099' '#1085#1072' '#1090#1086#1074#1072#1088#1099' '#1089#1086' '#1089#1083#1077#1076#1091#1102#1097#1080#1084#1080' '#1082#1086#1076#1072#1084#1080' '#1048#1050#1055#1059' ('#1052#1061#1048#1050')'
    TabOrder = 0
  end
  object edtClassCode: TEdit
    Left = 112
    Top = 48
    Width = 225
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 1
    OnKeyPress = edtClassCodeKeyPress
  end
  object lbClassCodes: TListBox
    Left = 112
    Top = 80
    Width = 225
    Height = 97
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 13
    TabOrder = 2
  end
  object btnDelete: TTntButton
    Left = 344
    Top = 80
    Width = 81
    Height = 25
    Anchors = [akTop, akRight]
    Caption = #1059#1076#1072#1083#1080#1090#1100
    Enabled = False
    TabOrder = 4
    OnClick = btnDeleteClick
  end
  object btnAdd: TTntButton
    Left = 344
    Top = 48
    Width = 81
    Height = 25
    Anchors = [akTop, akRight]
    Caption = #1044#1086#1073#1072#1074#1080#1090#1100
    TabOrder = 3
    OnClick = btnAddClick
  end
end

object fmFptrCash: TfmFptrCash
  Left = 633
  Top = 280
  AutoScroll = False
  BorderIcons = [biSystemMenu]
  Caption = #1042#1085#1077#1089#1077#1085#1080#1077' '#1080' '#1074#1099#1087#1083#1072#1090#1072
  ClientHeight = 363
  ClientWidth = 384
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  DesignSize = (
    384
    363)
  PixelsPerInch = 96
  TextHeight = 13
  object lblCashInPreLine: TLabel
    Left = 8
    Top = 8
    Width = 94
    Height = 13
    Caption = #1055#1077#1088#1077#1076' '#1074#1085#1077#1089#1077#1085#1080#1077#1084':'
  end
  object lblCashinLine: TLabel
    Left = 8
    Top = 40
    Width = 52
    Height = 13
    Caption = #1042#1085#1077#1089#1077#1085#1080#1077':'
  end
  object lblCashinPostLine: TLabel
    Left = 8
    Top = 72
    Width = 86
    Height = 13
    Caption = #1055#1086#1089#1083#1077' '#1074#1085#1077#1089#1077#1085#1080#1103':'
  end
  object Bevel1: TBevel
    Left = 8
    Top = 104
    Width = 369
    Height = 50
    Anchors = [akLeft, akTop, akRight]
    Shape = bsTopLine
  end
  object lblCashoutPreLine: TLabel
    Left = 8
    Top = 120
    Width = 87
    Height = 13
    Caption = #1055#1077#1088#1077#1076' '#1074#1099#1087#1083#1072#1090#1086#1081':'
  end
  object lblCashoutLine: TLabel
    Left = 8
    Top = 152
    Width = 47
    Height = 13
    Caption = #1042#1099#1087#1083#1072#1090#1072':'
  end
  object lblCashoutPostLine: TLabel
    Left = 8
    Top = 184
    Width = 83
    Height = 13
    Caption = #1055#1086#1089#1083#1077' '#1074#1099#1087#1083#1072#1090#1099':'
  end
  object edtCashinPreLine: TEdit
    Left = 120
    Top = 8
    Width = 257
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    Text = 'edtCashinPreLine'
  end
  object edtCashinLine: TEdit
    Left = 120
    Top = 40
    Width = 257
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 1
    Text = 'edtCashinLine'
  end
  object edtCashinPostLine: TEdit
    Left = 120
    Top = 72
    Width = 257
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 2
    Text = 'edtCashinPostLine'
  end
  object edtCashoutPreLine: TEdit
    Left = 119
    Top = 120
    Width = 257
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 3
    Text = 'edtCashoutPreLine'
  end
  object edtCashoutLine: TEdit
    Left = 119
    Top = 152
    Width = 257
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 4
    Text = 'edtCashoutLine'
  end
  object edtCashoutPostLine: TEdit
    Left = 119
    Top = 184
    Width = 257
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 5
    Text = 'edtCashoutPostLine'
  end
end

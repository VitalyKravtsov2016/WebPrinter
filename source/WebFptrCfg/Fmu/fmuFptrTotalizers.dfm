object fmFptrTotalizers: TfmFptrTotalizers
  Left = 633
  Top = 280
  AutoScroll = False
  BorderIcons = [biSystemMenu]
  Caption = #1057#1095#1077#1090#1095#1080#1082#1080
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
  object lblCashInECR: TLabel
    Left = 8
    Top = 8
    Width = 88
    Height = 13
    Caption = #1053#1072#1083#1080#1095#1085#1099#1093' '#1074' '#1050#1050#1052':'
  end
  object lblCashinLine: TLabel
    Left = 8
    Top = 40
    Width = 110
    Height = 13
    Caption = #1053#1072#1079#1074#1072#1085#1080#1077' '#1076#1083#1103' '#1086#1090#1095#1077#1090#1072':'
  end
  object Bevel1: TBevel
    Left = 8
    Top = 72
    Width = 369
    Height = 9
    Anchors = [akLeft, akTop, akRight]
    Shape = bsTopLine
  end
  object lblSalesAmountCash: TLabel
    Left = 8
    Top = 88
    Width = 133
    Height = 13
    Caption = #1057#1091#1084#1084#1072' '#1087#1088#1086#1076#1072#1078', '#1085#1072#1083#1080#1095#1085#1099#1077':'
  end
  object lblSalesAmountCard: TLabel
    Left = 8
    Top = 120
    Width = 113
    Height = 13
    Caption = #1057#1091#1084#1084#1072' '#1087#1088#1086#1076#1072#1078', '#1082#1072#1088#1090#1072':'
  end
  object lblRefundAmountCash: TLabel
    Left = 8
    Top = 152
    Width = 142
    Height = 13
    Caption = #1057#1091#1084#1084#1072' '#1074#1086#1079#1088#1072#1090#1086#1074', '#1085#1072#1083#1080#1095#1085#1099#1077':'
  end
  object lblRefundAmountCard: TLabel
    Left = 8
    Top = 184
    Width = 142
    Height = 13
    Caption = #1057#1091#1084#1084#1072' '#1074#1086#1079#1088#1072#1090#1086#1074', '#1085#1072#1083#1080#1095#1085#1099#1077':'
  end
  object edtCashinECRAmount: TEdit
    Left = 160
    Top = 8
    Width = 217
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    Text = 'edtCashinECRAmount'
    OnChange = ModifiedClick
  end
  object edtCashinECRLine: TEdit
    Left = 160
    Top = 40
    Width = 217
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 1
    Text = 'edtCashinECRLine'
    OnChange = ModifiedClick
  end
  object edtSalesAmountCash: TEdit
    Left = 160
    Top = 88
    Width = 216
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 2
    Text = 'edtSalesAmountCash'
    OnChange = ModifiedClick
  end
  object edtSalesAmountCard: TEdit
    Left = 160
    Top = 120
    Width = 216
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 3
    Text = 'edtSalesAmountCard'
    OnChange = ModifiedClick
  end
  object edtRefundAmountCash: TEdit
    Left = 160
    Top = 152
    Width = 216
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 4
    Text = 'edtRefundAmountCash'
    OnChange = ModifiedClick
  end
  object edtRefundAmountCard: TEdit
    Left = 160
    Top = 184
    Width = 216
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 5
    Text = 'edtRefundAmountCard'
    OnChange = ModifiedClick
  end
end

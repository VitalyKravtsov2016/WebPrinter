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
  object lblCashinLine: TLabel
    Left = 8
    Top = 16
    Width = 125
    Height = 13
    Caption = #1057#1090#1088#1086#1082#1072' '#1085#1072#1083#1080#1095#1085#1099#1093' '#1074' '#1050#1050#1052':'
  end
  object Bevel1: TBevel
    Left = 8
    Top = 152
    Width = 369
    Height = 9
    Anchors = [akLeft, akTop, akRight]
    Shape = bsTopLine
  end
  object lblSalesAmountCash: TLabel
    Left = 8
    Top = 168
    Width = 133
    Height = 13
    Caption = #1057#1091#1084#1084#1072' '#1087#1088#1086#1076#1072#1078', '#1085#1072#1083#1080#1095#1085#1099#1077':'
  end
  object lblSalesAmountCard: TLabel
    Left = 8
    Top = 200
    Width = 113
    Height = 13
    Caption = #1057#1091#1084#1084#1072' '#1087#1088#1086#1076#1072#1078', '#1082#1072#1088#1090#1072':'
  end
  object lblRefundAmountCash: TLabel
    Left = 8
    Top = 232
    Width = 142
    Height = 13
    Caption = #1057#1091#1084#1084#1072' '#1074#1086#1079#1088#1072#1090#1086#1074', '#1085#1072#1083#1080#1095#1085#1099#1077':'
  end
  object lblRefundAmountCard: TLabel
    Left = 8
    Top = 264
    Width = 142
    Height = 13
    Caption = #1057#1091#1084#1084#1072' '#1074#1086#1079#1088#1072#1090#1086#1074', '#1085#1072#1083#1080#1095#1085#1099#1077':'
  end
  object Bevel2: TBevel
    Left = 7
    Top = 72
    Width = 369
    Height = 9
    Anchors = [akLeft, akTop, akRight]
    Shape = bsTopLine
  end
  object lblCashInAmount: TLabel
    Left = 8
    Top = 88
    Width = 88
    Height = 13
    Caption = #1057#1091#1084#1084#1072' '#1074#1085#1077#1089#1077#1085#1080#1081':'
  end
  object lblCashOutAmount: TLabel
    Left = 8
    Top = 120
    Width = 77
    Height = 13
    Caption = #1057#1091#1084#1084#1072' '#1074#1099#1087#1083#1072#1090':'
  end
  object edtCashinECRLine: TEdit
    Left = 160
    Top = 16
    Width = 217
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    Text = 'edtCashinECRLine'
    OnChange = ModifiedClick
  end
  object edtSalesAmountCash: TEdit
    Left = 160
    Top = 168
    Width = 216
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 6
    Text = 'edtSalesAmountCash'
    OnChange = ModifiedClick
  end
  object edtSalesAmountCard: TEdit
    Left = 160
    Top = 200
    Width = 216
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 7
    Text = 'edtSalesAmountCard'
    OnChange = ModifiedClick
  end
  object edtRefundAmountCash: TEdit
    Left = 160
    Top = 232
    Width = 216
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 8
    Text = 'edtRefundAmountCash'
    OnChange = ModifiedClick
  end
  object edtRefundAmountCard: TEdit
    Left = 160
    Top = 264
    Width = 216
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 9
    Text = 'edtRefundAmountCard'
    OnChange = ModifiedClick
  end
  object chbCashInECRAutoZero: TCheckBox
    Left = 8
    Top = 48
    Width = 369
    Height = 17
    Caption = #1040#1074#1090#1086#1084#1072#1090#1080#1095#1077#1089#1082#1086#1077' '#1086#1073#1085#1091#1083#1077#1085#1080#1077' '#1085#1072#1083#1080#1095#1085#1099#1093' '#1074' '#1050#1050#1052' '#1087#1086#1089#1083#1077' Z '#1086#1090#1095#1077#1090#1072
    TabOrder = 1
    OnClick = ModifiedClick
  end
  object edtCashInAmount: TEdit
    Left = 160
    Top = 88
    Width = 129
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 2
    Text = 'edtCashInAmount'
    OnChange = ModifiedClick
  end
  object edtCashOutAmount: TEdit
    Left = 160
    Top = 120
    Width = 129
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 4
    Text = 'edtCashOutAmount'
    OnChange = ModifiedClick
  end
  object btnZeroCashInAmount: TButton
    Left = 296
    Top = 88
    Width = 81
    Height = 25
    Anchors = [akTop, akRight]
    Caption = #1054#1073#1085#1091#1083#1080#1090#1100
    TabOrder = 3
    OnClick = btnZeroCashInAmountClick
  end
  object btnZeroCAshOutAmount: TButton
    Left = 296
    Top = 120
    Width = 81
    Height = 25
    Anchors = [akTop, akRight]
    Caption = #1054#1073#1085#1091#1083#1080#1090#1100
    TabOrder = 5
    OnClick = btnZeroCAshOutAmountClick
  end
end

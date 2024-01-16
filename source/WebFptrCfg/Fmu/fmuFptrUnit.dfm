object fmFptrUnit: TfmFptrUnit
  Left = 563
  Top = 269
  AutoScroll = False
  BorderIcons = [biSystemMenu]
  Caption = #1045#1076#1080#1085#1080#1094#1099' '#1080#1079#1084#1077#1088#1077#1085#1080#1103
  ClientHeight = 217
  ClientWidth = 419
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  DesignSize = (
    419
    217)
  PixelsPerInch = 96
  TextHeight = 13
  object lblUnitCode: TTntLabel
    Left = 8
    Top = 16
    Width = 128
    Height = 13
    Caption = #1050#1086#1076' '#1077#1076#1080#1085#1080#1094#1099' '#1080#1079#1084#1077#1088#1077#1085#1080#1103':'
  end
  object lblUnitName: TTntLabel
    Left = 8
    Top = 48
    Width = 159
    Height = 13
    Caption = #1053#1072#1079#1074#1072#1085#1080#1077' '#1077#1076#1080#1085#1080#1094#1099' '#1080#1079#1084#1077#1088#1077#1085#1080#1103':'
  end
  object lvUnits: TListView
    Left = 8
    Top = 88
    Width = 404
    Height = 124
    Anchors = [akLeft, akTop, akRight, akBottom]
    Columns = <
      item
        Caption = #1050#1086#1076
        Width = 100
      end
      item
        AutoSize = True
        Caption = #1053#1072#1079#1074#1072#1085#1080#1077
      end>
    ColumnClick = False
    FlatScrollBars = True
    HideSelection = False
    ReadOnly = True
    RowSelect = True
    SortType = stText
    TabOrder = 3
    ViewStyle = vsReport
  end
  object btnDelete: TTntButton
    Left = 304
    Top = 48
    Width = 105
    Height = 25
    Anchors = [akTop, akRight]
    Caption = #1059#1076#1072#1083#1080#1090#1100
    Enabled = False
    TabOrder = 2
    OnClick = btnDeleteClick
  end
  object btnAdd: TTntButton
    Left = 304
    Top = 16
    Width = 105
    Height = 25
    Anchors = [akTop, akRight]
    Caption = #1044#1086#1073#1072#1074#1080#1090#1100
    TabOrder = 1
    OnClick = btnAddClick
  end
  object edtUnitName: TEdit
    Left = 176
    Top = 48
    Width = 121
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    OnChange = ModifiedClick
  end
  object cbUnitCode: TComboBox
    Left = 176
    Top = 16
    Width = 121
    Height = 21
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    ItemHeight = 13
    TabOrder = 4
  end
end

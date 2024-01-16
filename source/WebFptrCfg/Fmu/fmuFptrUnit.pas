unit fmuFptrUnit;

interface

uses
  // VCL
  StdCtrls, Controls, ComCtrls, Classes, SysUtils,
  // Tnt
  TntClasses, TntStdCtrls, TntRegistry,
  // This
  FiscalPrinterDevice, PrinterParameters, FptrTypes, Spin, Mask;

type
  { TfmFptrUnitCode }

  TfmFptrUnit = class(TFptrPage)
    lblUnitCode: TTntLabel;
    lblUnitName: TTntLabel;
    lvUnits: TListView;
    btnDelete: TTntButton;
    btnAdd: TTntButton;
    edtUnitName: TEdit;
    cbUnitCode: TComboBox;
    procedure btnAddClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure ModifiedClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure UpdateItems;
  public
    procedure UpdatePage; override;
    procedure UpdateObject; override;
  end;

implementation

{$R *.DFM}

{ TfmFptrUnitCode }

procedure TfmFptrUnit.UpdateItems;
var
  i: Integer;
  Item: TListItem;
begin
  with lvUnits do
  begin
    Items.BeginUpdate;
    try
      Items.Clear;
		  for i := 0 to Parameters.ItemUnits.Count-1 do
      begin
        Item := Items.Add;
        Item.Caption := IntToStr(Parameters.ItemUnits[i].Code);
        Item.SubItems.Add(Parameters.ItemUnits[i].Name);
        if i = 0 then
        begin
          Item.Focused := True;
          Item.Selected := True;
        end;
      end;
      btnDelete.Enabled := Parameters.ItemUnits.Count > 0;
    finally
      Items.EndUpdate;
    end;
  end;
end;

procedure TfmFptrUnit.UpdatePage;
begin
  UpdateItems;
end;

procedure TfmFptrUnit.UpdateObject;
begin
end;

procedure TfmFptrUnit.btnAddClick(Sender: TObject);
var
  Item: TListItem;
  UnitCode: Integer;
begin
  UnitCode := Integer(cbUnitCode.Items.Objects[cbUnitCode.ItemIndex]);
  Parameters.ItemUnits.Add(UnitCode, edtUnitName.Text);

  Item := lvUnits.Items.Add;
  Item.Caption := IntToStr(UnitCode);
  Item.SubItems.Add(edtUnitName.Text);

  Item.Focused := True;
  Item.Selected := True;
  btnDelete.Enabled := True;
  Modified;
end;

procedure TfmFptrUnit.btnDeleteClick(Sender: TObject);
var
  Index: Integer;
  Item: TListItem;
begin
  Item := lvUnits.Selected;
  if Item <> nil then
  begin
    Index := Item.Index;
  	Parameters.ItemUnits[Index].Free;
    Item.Delete;
    if Index >= lvUnits.Items.Count then
      Index := lvUnits.Items.Count-1;
    if Index >= 0 then
    begin
      Item := lvUnits.Items[Index];
      Item.Focused := True;
      Item.Selected := True;
	  	Modified;
    end;
    btnDelete.Enabled := lvUnits.Items.Count > 0;
  end;
end;

procedure TfmFptrUnit.ModifiedClick(Sender: TObject);
begin
  Modified;
end;

procedure TfmFptrUnit.FormCreate(Sender: TObject);

  procedure AddUnit(UnitCode: Integer; const UnitName: WideString);
  begin
    cbUnitCode.Items.AddObject(Format('%d, %s', [UnitCode, UnitName]),
      TObject(UnitCode));
  end;

begin
  cbUnitCode.Items.BeginUpdate;
  try
    cbUnitCode.Items.Clear;
    AddUnit(1, '�����');
    AddUnit(2, '�����');
    AddUnit(3, '����������');
    AddUnit(4, '�����');
    AddUnit(5, '���������');
    AddUnit(6, '�������');
    AddUnit(7, '�����');
    AddUnit(8, '���������');
    AddUnit(9, '���������');
    AddUnit(11, '����');
    AddUnit(12, '��������');
    AddUnit(22, '���������');
    AddUnit(23, '����');
    AddUnit(26, '��������');
    AddUnit(27, '�����');
    AddUnit(28, '���');
    AddUnit(33, '�������');
    AddUnit(38, '��������');
    AddUnit(39, '�����');
    AddUnit(41, '������');
    AddUnit(42, '����');
    AddUnit(43, '�����');
    AddUnit(49, '�����');
    cbUnitCode.ItemIndex := 0;
  finally
    cbUnitCode.Items.EndUpdate;
  end;
end;

end.

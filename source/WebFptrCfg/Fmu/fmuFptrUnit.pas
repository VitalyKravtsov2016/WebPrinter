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
    AddUnit(1, 'штука');
    AddUnit(2, 'пачка');
    AddUnit(3, 'миллиграмм');
    AddUnit(4, 'грамм');
    AddUnit(5, 'килограмм');
    AddUnit(6, 'центнер');
    AddUnit(7, 'тонна');
    AddUnit(8, 'миллиметр');
    AddUnit(9, 'сантиметр');
    AddUnit(11, 'метр');
    AddUnit(12, 'километр');
    AddUnit(22, 'миллилитр');
    AddUnit(23, 'литр');
    AddUnit(26, 'комплект');
    AddUnit(27, 'сутки');
    AddUnit(28, 'час');
    AddUnit(33, 'коробка');
    AddUnit(38, 'упаковка');
    AddUnit(39, 'минут');
    AddUnit(41, 'баллон');
    AddUnit(42, 'день');
    AddUnit(43, 'мес€ц');
    AddUnit(49, 'рулон');
    cbUnitCode.ItemIndex := 0;
  finally
    cbUnitCode.Items.EndUpdate;
  end;
end;

end.

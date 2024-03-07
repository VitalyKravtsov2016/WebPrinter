unit fmuFptrDiscount;

interface

uses
  // VCL
  StdCtrls, Controls, ComCtrls, Classes, SysUtils, Spin,
  // Tnt
  TntClasses, TntStdCtrls, TntRegistry,
  // This
  FiscalPrinterDevice, PrinterParameters;

type
  { TfmFptrDiscount }

  TfmFptrDiscount = class(TFptrPage)
    chbRecDiscountOnClassCode: TCheckBox;
    edtClassCode: TEdit;
    lblClassCode: TLabel;
    lbClassCodes: TListBox;
    btnDelete: TTntButton;
    btnAdd: TTntButton;
    procedure ModifiedClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure edtClassCodeKeyPress(Sender: TObject; var Key: Char);
  public
    procedure UpdatePage; override;
    procedure UpdateObject; override;
  end;

implementation

{$R *.DFM}

{ TfmFptrPayType }

procedure TfmFptrDiscount.UpdatePage;
begin
  chbRecDiscountOnClassCode.Checked := Parameters.RecDiscountOnClassCode;
  lbClassCodes.Items := Parameters.ClassCodes;
  btnDelete.Enabled := Parameters.ClassCodes.Count > 0;
end;

procedure TfmFptrDiscount.UpdateObject;
begin
  Parameters.ClassCodes := lbClassCodes.Items;
  Parameters.RecDiscountOnClassCode := chbRecDiscountOnClassCode.Checked;
end;

procedure TfmFptrDiscount.ModifiedClick(Sender: TObject);
begin
  Modified;
end;

procedure TfmFptrDiscount.btnAddClick(Sender: TObject);
var
  Index: Integer;
  ClassCode: string;
begin
  ClassCode := edtClassCode.Text;
  if Trim(ClassCode) = '' then Exit;

  Index := lbClassCodes.Items.IndexOf(ClassCode);
  if Index = -1 then
    Index := lbClassCodes.Items.Add(ClassCode);
  lbClassCodes.ItemIndex := Index;
  btnDelete.Enabled := lbClassCodes.Items.Count > 0;
end;

procedure TfmFptrDiscount.btnDeleteClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := lbClassCodes.ItemIndex;
  if Index <> -1 then
  begin
    lbClassCodes.Items.Delete(Index);
    if Index >= lbClassCodes.Items.Count then
      Index := lbClassCodes.Items.Count-1;
    lbClassCodes.ItemIndex := Index;
    btnDelete.Enabled := lbClassCodes.Items.Count > 0;
  end;
end;

procedure TfmFptrDiscount.edtClassCodeKeyPress(Sender: TObject;
  var Key: Char);
begin
  if not (Key in ['0'..'9']) then
    Key := #0;
end;

end.

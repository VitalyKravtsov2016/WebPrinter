unit fmuFptrMiscParams;

interface

uses
  // VCL
  StdCtrls, Controls, ComCtrls, Classes, SysUtils,
  // Tnt
  TntClasses, TntStdCtrls, TntRegistry,
  // This
  FiscalPrinterDevice, PrinterParameters, FptrTypes;

type
  { TfmFptrPayType }

  TfmFptrMiscParams = class(TFptrPage)
    cbAmountDecimalPlaces: TComboBox;
    lblAmountDecimalPlaces: TTntLabel;
    procedure ModifiedClick(Sender: TObject);
  public
    procedure UpdatePage; override;
    procedure UpdateObject; override;
  end;

implementation

{$R *.DFM}

{ TfmFptrPayType }

procedure TfmFptrMiscParams.UpdatePage;
begin
  cbAmountDecimalPlaces.ItemIndex := cbAmountDecimalPlaces.Items.IndexOf(
    IntToStr(Parameters.AmountDecimalPlaces));
end;

procedure TfmFptrMiscParams.UpdateObject;
begin
  Parameters.AmountDecimalPlaces := StrToInt(cbAmountDecimalPlaces.Text);
end;

procedure TfmFptrMiscParams.ModifiedClick(Sender: TObject);
begin
  Modified;
end;

end.

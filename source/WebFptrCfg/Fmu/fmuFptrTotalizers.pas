unit fmuFptrTotalizers;

interface

uses
  // VCL
  StdCtrls, Controls, ComCtrls, Classes, SysUtils, Spin, ExtCtrls,
  // Tnt
  TntClasses, TntStdCtrls, TntRegistry,
  // This
  FiscalPrinterDevice, PrinterParameters;

type
  { TfmFptrTotalizers }

  TfmFptrTotalizers = class(TFptrPage)
    lblCashinLine: TLabel;
    edtCashinECRLine: TEdit;
    Bevel1: TBevel;
    lblSalesAmountCash: TLabel;
    edtSalesAmountCash: TEdit;
    lblSalesAmountCard: TLabel;
    edtSalesAmountCard: TEdit;
    edtRefundAmountCash: TEdit;
    lblRefundAmountCash: TLabel;
    edtRefundAmountCard: TEdit;
    lblRefundAmountCard: TLabel;
    chbCashInECRAutoZero: TCheckBox;
    procedure ModifiedClick(Sender: TObject);
  public
    procedure UpdatePage; override;
    procedure UpdateObject; override;
  end;

implementation

{$R *.DFM}

{ fmFptrCash }

procedure TfmFptrTotalizers.UpdatePage;
begin
  edtCashInECRLine.Text := Parameters.CashInECRLine;
  chbCashInECRAutoZero.Checked := Parameters.CashInECRAutoZero;
  edtSalesAmountCash.Text := CurrToStr(Parameters.SalesAmountCash);
  edtSalesAmountCard.Text := CurrToStr(Parameters.SalesAmountCard);
  edtRefundAmountCash.Text := CurrToStr(Parameters.RefundAmountCash);
  edtRefundAmountCard.Text := CurrToStr(Parameters.RefundAmountCard);
end;

procedure TfmFptrTotalizers.UpdateObject;
begin
  Parameters.CashInECRLine := edtCashInECRLine.Text;
  Parameters.CashInECRAutoZero := chbCashInECRAutoZero.Checked;
  Parameters.SalesAmountCash := StrToCurr(edtSalesAmountCash.Text);
  Parameters.SalesAmountCard := StrToCurr(edtSalesAmountCard.Text);
  Parameters.RefundAmountCash := StrToCurr(edtRefundAmountCash.Text);
  Parameters.RefundAmountCard := StrToCurr(edtRefundAmountCard.Text);
end;

procedure TfmFptrTotalizers.ModifiedClick(Sender: TObject);
begin
  Modified;
end;

end.

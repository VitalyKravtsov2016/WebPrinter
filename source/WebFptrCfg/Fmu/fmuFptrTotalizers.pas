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
    lblCashInECR: TLabel;
    edtCashinECRAmount: TEdit;
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
  edtCashInECRAmount.Text := CurrToStr(Parameters.CashInECRAmount);
  edtSalesAmountCash.Text := CurrToStr(Parameters.SalesAmountCash);
  edtSalesAmountCard.Text := CurrToStr(Parameters.SalesAmountCard);
  edtRefundAmountCash.Text := CurrToStr(Parameters.RefundAmountCash);
  edtRefundAmountCard.Text := CurrToStr(Parameters.RefundAmountCard);
end;

procedure TfmFptrTotalizers.UpdateObject;
begin
  Parameters.CashInECRLine := edtCashInECRLine.Text;
  Parameters.CashInECRAmount := StrToCurr(edtCashInECRAmount.Text);
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

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
    Bevel2: TBevel;
    lblCashInAmount: TLabel;
    lblCashOutAmount: TLabel;
    edtCashInAmount: TEdit;
    edtCashOutAmount: TEdit;
    btnZeroCashInAmount: TButton;
    btnZeroCAshOutAmount: TButton;
    procedure ModifiedClick(Sender: TObject);
    procedure btnZeroCashInAmountClick(Sender: TObject);
    procedure btnZeroCAshOutAmountClick(Sender: TObject);
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
  edtCashInAmount.Text := CurrToStr(Parameters.CashInAmount);
  edtCashOutAmount.Text := CurrToStr(Parameters.CashOutAmount);
  edtSalesAmountCash.Text := CurrToStr(Parameters.SalesAmountCash);
  edtSalesAmountCard.Text := CurrToStr(Parameters.SalesAmountCard);
  edtRefundAmountCash.Text := CurrToStr(Parameters.RefundAmountCash);
  edtRefundAmountCard.Text := CurrToStr(Parameters.RefundAmountCard);
end;

procedure TfmFptrTotalizers.UpdateObject;
begin
  Parameters.CashInECRLine := edtCashInECRLine.Text;
  Parameters.CashInECRAutoZero := chbCashInECRAutoZero.Checked;
  Parameters.CashInAmount := StrToCurr(edtCashInAmount.Text);
  Parameters.CashOutAmount := StrToCurr(edtCashOutAmount.Text);
  Parameters.SalesAmountCash := StrToCurr(edtSalesAmountCash.Text);
  Parameters.SalesAmountCard := StrToCurr(edtSalesAmountCard.Text);
  Parameters.RefundAmountCash := StrToCurr(edtRefundAmountCash.Text);
  Parameters.RefundAmountCard := StrToCurr(edtRefundAmountCard.Text);
end;

procedure TfmFptrTotalizers.btnZeroCashInAmountClick(Sender: TObject);
begin
  edtCashInAmount.Text := '0';
end;

procedure TfmFptrTotalizers.btnZeroCAshOutAmountClick(Sender: TObject);
begin
  edtCashOutAmount.Text := '0';
end;

procedure TfmFptrTotalizers.ModifiedClick(Sender: TObject);
begin
  Modified;
end;


end.

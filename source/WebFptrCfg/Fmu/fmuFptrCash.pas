unit fmuFptrCash;

interface

uses
  // VCL
  StdCtrls, Controls, ComCtrls, Classes, SysUtils, Spin, ExtCtrls,
  // Tnt
  TntClasses, TntStdCtrls, TntRegistry,
  // This
  FiscalPrinterDevice, PrinterParameters;

type
  { fmFptrCash }

  TfmFptrCash = class(TFptrPage)
    lblCashInPreLine: TLabel;
    edtCashinPreLine: TEdit;
    lblCashinLine: TLabel;
    edtCashinLine: TEdit;
    lblCashinPostLine: TLabel;
    edtCashinPostLine: TEdit;
    Bevel1: TBevel;
    lblCashoutPreLine: TLabel;
    edtCashoutPreLine: TEdit;
    lblCashoutLine: TLabel;
    edtCashoutLine: TEdit;
    lblCashoutPostLine: TLabel;
    edtCashoutPostLine: TEdit;
    procedure ModifiedClick(Sender: TObject);
  public
    procedure UpdatePage; override;
    procedure UpdateObject; override;
  end;

implementation

{$R *.DFM}

{ fmFptrCash }

procedure TfmFptrCash.UpdatePage;
begin
  edtCashinLine.Text := Parameters.CashinLine;
  edtCashinPreLine.Text := Parameters.CashinPreLine;
  edtCashinPostLine.Text := Parameters.CashinPostLine;

  edtCashoutLine.Text := Parameters.CashoutLine;
  edtCashoutPreLine.Text := Parameters.CashoutPreLine;
  edtCashoutPostLine.Text := Parameters.CashoutPostLine;
end;

procedure TfmFptrCash.UpdateObject;
begin
  Parameters.CashinLine := edtCashinLine.Text;
  Parameters.CashinPreLine := edtCashinPreLine.Text;
  Parameters.CashinPostLine := edtCashinPostLine.Text;

  Parameters.CashoutLine := edtCashoutLine.Text;
  Parameters.CashoutPreLine := edtCashoutPreLine.Text;
  Parameters.CashoutPostLine := edtCashoutPostLine.Text;
end;

procedure TfmFptrCash.ModifiedClick(Sender: TObject);
begin
  Modified;
end;

end.

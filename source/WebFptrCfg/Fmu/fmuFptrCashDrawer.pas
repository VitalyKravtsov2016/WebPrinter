unit fmuFptrCashDrawer;

interface

uses
  // VCL
  StdCtrls, Controls, ComCtrls, Classes, SysUtils,
  // Tnt
  TntClasses, TntStdCtrls, TntRegistry,
  // This
  FiscalPrinterDevice, PrinterParameters, FptrTypes;

type
  { TfmFptrCashDrawer }

  TfmFptrCashDrawer = class(TFptrPage)
    chbOpenCashDrawer: TCheckBox;
    procedure ModifiedClick(Sender: TObject);
  public
    procedure UpdatePage; override;
    procedure UpdateObject; override;
  end;

implementation

{$R *.DFM}

{ TfmFptrPayType }

procedure TfmFptrCashDrawer.UpdatePage;
begin
  chbOpenCashDrawer.Checked := Parameters.OpenCashbox;
end;

procedure TfmFptrCashDrawer.UpdateObject;
begin
  Parameters.OpenCashbox := chbOpenCashDrawer.Checked;
end;

procedure TfmFptrCashDrawer.ModifiedClick(Sender: TObject);
begin
  Modified;
end;

end.

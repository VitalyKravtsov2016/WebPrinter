unit fmuFptrPrint;

interface

uses
  // VCL
  StdCtrls, Controls, ComCtrls, Classes, SysUtils, Spin,
  // Tnt
  TntClasses, TntStdCtrls, TntRegistry,
  // This
  FiscalPrinterDevice, PrinterParameters;

type
  { TfmFptrPrint }

  TfmFptrPrint = class(TFptrPage)
    lblMessageLength: TTntLabel;
    seMessageLength: TSpinEdit;
    procedure ModifiedClick(Sender: TObject);
  public
    procedure UpdatePage; override;
    procedure UpdateObject; override;
  end;

implementation

{$R *.DFM}

{ TfmFptrPayType }

procedure TfmFptrPrint.UpdatePage;
begin
  seMessageLength.Value := Parameters.MessageLength;
end;

procedure TfmFptrPrint.UpdateObject;
begin
  Parameters.MessageLength := seMessageLength.Value;
end;

procedure TfmFptrPrint.ModifiedClick(Sender: TObject);
begin
  Modified;
end;

end.

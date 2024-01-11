unit fmuFptrConnection;

interface

uses
  // VCL
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, Spin,
  // Tnt
  TntStdCtrls,
  // This
  untUtil, PrinterParameters, FptrTypes, FiscalPrinterDevice, FileUtils,
  LogFile, WebPrinter;

type
  { TfmFptrConnection }

  TfmFptrConnection = class(TFptrPage)
    gbConenctionParams: TTntGroupBox;
    lblConnectTimeout: TTntLabel;
    lblWebkassaAddress: TTntLabel;
    seConnectTimeout: TSpinEdit;
    edtAddress: TEdit;
    btnTestConnection: TButton;
    lblResultCode: TTntLabel;
    stResultCode: TStaticText;
    procedure btnTestConnectionClick(Sender: TObject);
    procedure ModifiedClick(Sender: TObject);
  public
    procedure UpdatePage; override;
    procedure UpdateObject; override;
  end;

implementation

{$R *.dfm}

{ TfmFptrConnection }

procedure TfmFptrConnection.UpdatePage;
begin
  edtAddress.Text := Parameters.WebPrinterAddress;
  seConnectTimeout.Value := Parameters.ConnectTimeout;
end;

procedure TfmFptrConnection.UpdateObject;
begin
  Parameters.WebPrinterAddress := edtAddress.Text;
  Parameters.ConnectTimeout := seConnectTimeout.Value;
end;

procedure TfmFptrConnection.btnTestConnectionClick(Sender: TObject);
var
  Driver: TWebPrinter;
begin
  EnableButtons(False);
  stResultCode.Caption := '';
  UpdateObject;

  Driver := TWebPrinter.Create(Logger);
  try
    Driver.Address := Parameters.WebPrinterAddress;
    Driver.ConnectTimeout := Driver.ConnectTimeout;
    Driver.Connect;
    stResultCode.Caption := 'OK';
  except
    on E: Exception do
    begin
      Logger.Error(E.Message);
      stResultCode.Caption := E.Message;
    end;
  end;
  Driver.Free;
  EnableButtons(True);
end;

procedure TfmFptrConnection.ModifiedClick(Sender: TObject);
begin
  Modified;
end;

end.

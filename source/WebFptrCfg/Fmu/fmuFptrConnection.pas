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
  LogFile;

type
  { TfmFptrConnection }

  TfmFptrConnection = class(TFptrPage)
    gbConenctionParams: TTntGroupBox;
    lblConnectTimeout: TTntLabel;
    lblWebkassaAddress: TTntLabel;
    seConnectTimeout: TSpinEdit;
    edtWebkassaAddress: TEdit;
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
(*
  edtWebkassaAddress.Text := Parameters.WebkassaAddress;
  seConnectTimeout.Value := Parameters.ConnectTimeout;
*)
end;

procedure TfmFptrConnection.UpdateObject;
begin
(*
  Parameters.WebkassaAddress := edtWebkassaAddress.Text;
  Parameters.ConnectTimeout := seConnectTimeout.Value;
*)  
end;

procedure TfmFptrConnection.btnTestConnectionClick(Sender: TObject);
begin
(*
  EnableButtons(False);
  edtResultCode.Clear;
  UpdateObject;
  Driver := CreateDriver;
  try
    Driver.Connect;
    edtResultCode.Text := 'OK';
  except
    on E: Exception do
    begin
      Logger.Error(E.Message);
      edtResultCode.Text := E.Message;
    end;
  end;
  Driver.Free;
  EnableButtons(True);
*)
end;

procedure TfmFptrConnection.ModifiedClick(Sender: TObject);
begin
  Modified;
end;

end.

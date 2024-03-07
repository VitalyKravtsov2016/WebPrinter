unit duPrinterParameters;

interface

uses
  // VCL
  Windows, SysUtils, Classes, IniFiles,
  // DUnit
  TestFramework,
  // This
  LogFile, PrinterParameters, PrinterParametersX;

type
  { TParametersTest }

  TParametersTest = class(TTestCase)
  private
    FLogger: ILogFile;
    FParams: TPrinterParameters;
    procedure CheckDefaultParams;
  protected
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure CheckSaveParams;
    procedure CheckSaveUsrParams;
  end;

implementation


{ TParametersTest }

procedure TParametersTest.Setup;
begin
  FLogger := TLogFile.Create;
  FParams := TPrinterParameters.Create(FLogger);
end;

procedure TParametersTest.TearDown;
begin
  FParams.Free;
  FLogger := nil;
end;

procedure TParametersTest.CheckDefaultParams;
begin
  CheckEquals(2, FParams.VatRates.Count, 'VatRates.Count');
  CheckEquals(12, FParams.VatRates[0].Rate, 'VatRates[0].Rate');
  CheckEquals(1, FParams.VatRates[0].Code, 'VatRates[0].Code');
  CheckEquals('ÍÄÑ 12%', FParams.VatRates[0].Name, 'VatRates[0].Name');
  CheckEquals(15, FParams.VatRates[1].Rate, 'VatRates[1].Rate');
  CheckEquals(4, FParams.VatRates[1].Code, 'VatRates[1].Code');
  CheckEquals('ÍÄÑ 15%', FParams.VatRates[1].Name, 'VatRates[1].Name');

  CheckEquals(23, FParams.ItemUnits.Count, 'ItemUnits.Count');
  CheckEquals(1, FParams.ItemUnits[0].Code, 'ItemUnits[0].Code');
  CheckEquals('øòóêà', FParams.ItemUnits[0].Name, 'ItemUnits[0].Name');
  CheckEquals(0, FParams.ClassCodes.Count, 'FParams.ClassCodes.Count');
end;

procedure TParametersTest.CheckSaveParams;
begin
  FParams.SetDefaults;
  FParams.VatRates.Add(4, 15, 'ÍÄÑ 15%');

  CheckDefaultParams;

  SaveParameters(FParams, 'Device1', FLogger);
  FParams.VatRates.Clear;
  FParams.ItemUnits.Clear;

  LoadParameters(FParams, 'Device1', FLogger);
  CheckDefaultParams;

  FParams.ClassCodes.Add('823764827346');
  FParams.ClassCodes.Add('923847928347');
  FParams.ClassCodes.Add('222384782344');
  FParams.RecDiscountOnClassCode := False;
  SaveParameters(FParams, 'Device1', FLogger);
  FParams.SetDefaults;
  CheckEquals(0, FParams.ClassCodes.Count, 'FParams.ClassCodes.Count');
  LoadParameters(FParams, 'Device1', FLogger);
  CheckEquals(False, FParams.RecDiscountOnClassCode, 'FParams.RecDiscountOnClassCode');
  CheckEquals(3, FParams.ClassCodes.Count, 'FParams.ClassCodes.Count');
  CheckEquals('823764827346', FParams.ClassCodes[0], 'FParams.ClassCodes[0]');
  CheckEquals('923847928347', FParams.ClassCodes[1], 'FParams.ClassCodes[1]');
  CheckEquals('222384782344', FParams.ClassCodes[2], 'FParams.ClassCodes[2]');
end;


procedure TParametersTest.CheckSaveUsrParams;
begin
  CheckEquals(0, FParams.CashInAmount, 'FParams.CashInAmount');
  CheckEquals(0, FParams.CashOutAmount, 'FParams.CashOutAmount');
  FParams.CashInAmount := 123.45;
  FParams.CashOutAmount := 234.56;
  FParams.CashInECRAmount := 123.87;
  FParams.SalesAmountCash := 12937.98;
  FParams.SalesAmountCard := 263476.89;
  FParams.RefundAmountCash := 365.78;
  FParams.RefundAmountCard := 287346.78;

  FParams.SetDefaults;
  CheckEquals(0, FParams.CashInAmount, 'FParams.CashInAmount');
  CheckEquals(0, FParams.CashOutAmount, 'FParams.CashOutAmount');
  CheckEquals(0, FParams.CashInECRAmount, 'FParams.CashInECRAmount');
  CheckEquals(0, FParams.SalesAmountCash, 'FParams.SalesAmountCash');
  CheckEquals(0, FParams.SalesAmountCard, 'FParams.SalesAmountCard');
  CheckEquals(0, FParams.RefundAmountCash, 'FParams.RefundAmountCash');
  CheckEquals(0, FParams.RefundAmountCard, 'FParams.RefundAmountCard');

  FParams.CashInAmount := 123.45;
  FParams.CashOutAmount := 234.56;
  FParams.CashInECRAmount := 123.87;
  FParams.SalesAmountCash := 12937.98;
  FParams.SalesAmountCard := 263476.89;
  FParams.RefundAmountCash := 365.78;
  FParams.RefundAmountCard := 287346.78;

  SaveUsrParameters(FParams, 'Device1', FLogger);
  FParams.SetDefaults;
  LoadParameters(FParams, 'Device1', FLogger);
  CheckEquals(123.45, FParams.CashInAmount, 'FParams.CashInAmount');
  CheckEquals(234.56, FParams.CashOutAmount, 'FParams.CashOutAmount');
  CheckEquals(123.87, FParams.CashInECRAmount, 'FParams.CashInECRAmount');
  CheckEquals(12937.98, FParams.SalesAmountCash, 'FParams.SalesAmountCash');
  CheckEquals(263476.89, FParams.SalesAmountCard, 'FParams.SalesAmountCard');
  CheckEquals(365.78, FParams.RefundAmountCash, 'FParams.RefundAmountCash');
  CheckEquals(287346.78, FParams.RefundAmountCard, 'FParams.RefundAmountCard');
end;

initialization
  RegisterTest('', TParametersTest.Suite);


end.

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
end;


initialization
  RegisterTest('', TParametersTest.Suite);


end.

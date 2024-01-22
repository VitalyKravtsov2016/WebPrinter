program WebFptrSoTest;

{%File '..\AcceptanceTest\WebFptrSoTest.dof'}

uses
  Forms,
  TestFramework,
  GUITestRunner,
  WebPrinter in '..\..\source\WebFptrSo\Units\WebPrinter.pas',
  LogFile in '..\..\source\Shared\LogFile.pas',
  WException in '..\..\source\Shared\WException.pas',
  JsonUtils in '..\..\source\Shared\JsonUtils.pas',
  DriverError in '..\..\source\Shared\DriverError.pas',
  FileUtils in '..\..\source\Shared\FileUtils.pas',
  duPrinterParameters in 'units\duPrinterParameters.pas',
  uLkJSON in '..\..\source\Shared\uLkJSON.pas',
  duWebPrinter in 'units\duWebPrinter.pas',
  PrinterParameters in '..\..\source\Shared\PrinterParameters.pas',
  PrinterParametersReg in '..\..\source\Shared\PrinterParametersReg.pas',
  PrinterParametersX in '..\..\source\Shared\PrinterParametersX.pas',
  Opos in '..\..\source\Opos\Opos.pas',
  Oposhi in '..\..\source\Opos\Oposhi.pas',
  OPOSException in '..\..\source\Opos\OposException.pas',
  VatRate in '..\..\source\Shared\VatRate.pas',
  ReceiptItem in '..\..\source\WebFptrSo\units\ReceiptItem.pas',
  MathUtils in '..\..\source\WebFptrSo\units\MathUtils.pas',
  PrinterTypes in '..\..\source\Shared\PrinterTypes.pas',
  StringUtils in '..\..\source\Shared\StringUtils.pas',
  RegExpr in '..\..\source\Shared\RegExpr.pas',
  OposFptr in '..\..\source\Opos\OposFptr.pas',
  ItemUnit in '..\..\source\Shared\ItemUnit.pas';

{$R *.RES}

begin
  TGUITestRunner.RunTest(RegisteredTests);
end.

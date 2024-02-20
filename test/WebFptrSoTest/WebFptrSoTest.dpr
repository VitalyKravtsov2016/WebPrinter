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
  duJsonUtils in 'units\duJsonUtils.pas',
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
  ItemUnit in '..\..\source\Shared\ItemUnit.pas',
  duPrinterParameters in 'units\duPrinterParameters.pas',
  WebPrinterImpl in '..\..\source\WebFptrSo\units\WebPrinterImpl.pas',
  OposFptrhi in '..\..\source\Opos\OposFptrhi.pas',
  OposEvents in '..\..\source\Opos\OposEvents.pas',
  OposEventsRCS in '..\..\source\Opos\OposEventsRCS.pas',
  DebugUtils in '..\..\source\Shared\DebugUtils.pas',
  OposFptrUtils in '..\..\source\Opos\OposFptrUtils.pas',
  OposUtils in '..\..\source\Opos\OposUtils.pas',
  OposServiceDevice19 in '..\..\source\Opos\OposServiceDevice19.pas',
  OposSemaphore in '..\..\source\Opos\OposSemaphore.pas',
  NotifyThread in '..\..\source\Shared\NotifyThread.pas',
  VersionInfo in '..\..\source\Shared\VersionInfo.pas',
  FiscalPrinterState in '..\..\source\WebFptrSo\units\FiscalPrinterState.pas',
  CustomReceipt in '..\..\source\WebFptrSo\units\CustomReceipt.pas',
  DirectIOAPI in '..\..\source\WebFptrSo\units\DirectIOAPI.pas',
  NonfiscalDoc in '..\..\source\WebFptrSo\units\NonfiscalDoc.pas',
  ServiceVersion in '..\..\source\Shared\ServiceVersion.pas',
  DeviceService in '..\..\source\Shared\DeviceService.pas',
  CashInReceipt in '..\..\source\WebFptrSo\units\CashInReceipt.pas',
  CashOutReceipt in '..\..\source\WebFptrSo\units\CashOutReceipt.pas',
  SalesReceipt in '..\..\source\WebFptrSo\units\SalesReceipt.pas',
  TextDocument in '..\..\source\WebFptrSo\units\TextDocument.pas',
  WebFptrSO_TLB in '..\..\source\WebFptrSo\WebFptrSO_TLB.pas',
  duLogFile in 'units\duLogFile.pas',
  duWebPrinterImpl in 'units\duWebPrinterImpl.pas',
  TLVItem in '..\..\source\WebFptrSo\units\TLVItem.pas';

{$R *.RES}

begin
  TGUITestRunner.RunTest(RegisteredTests);
end.

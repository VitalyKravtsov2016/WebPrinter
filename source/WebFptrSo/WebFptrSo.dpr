library WebFptrSo;

uses
  ComServ in '..\Common\ComServ.pas',
  Opos in '..\Opos\Opos.pas',
  Oposhi in '..\Opos\Oposhi.pas',
  OposFptr in '..\Opos\OposFptr.pas',
  OposUtils in '..\Opos\OposUtils.pas',
  OposFptrhi in '..\Opos\OposFptrhi.pas',
  OposException in '..\Opos\OposException.pas',
  WException in '..\Shared\WException.pas',
  oleFiscalPrinter in 'Units\oleFiscalPrinter.pas',
  LogFile in '..\Shared\LogFile.pas',
  OposFptrUtils in '..\Opos\OposFptrUtils.pas',
  WebPrinterImpl in 'units\WebPrinterImpl.pas',
  WebFptrSO_TLB in 'WebFptrSO_TLB.pas',
  OposServiceDevice19 in '..\Opos\OposServiceDevice19.pas',
  OposEvents in '..\Opos\OposEvents.pas',
  OposSemaphore in '..\Opos\OposSemaphore.pas',
  NotifyThread in '..\Shared\NotifyThread.pas',
  VersionInfo in '..\Shared\VersionInfo.pas',
  OposEventsRCS in '..\Opos\OposEventsRCS.pas',
  DebugUtils in '..\Shared\DebugUtils.pas',
  DriverError in '..\Shared\DriverError.pas',
  JsonUtils in '..\Shared\JsonUtils.pas',
  FiscalPrinterState in 'units\FiscalPrinterState.pas',
  CustomReceipt in 'units\CustomReceipt.pas',
  TextItem in 'units\TextItem.pas',
  MathUtils in 'units\MathUtils.pas',
  NonfiscalDoc in 'units\NonfiscalDoc.pas',
  ServiceVersion in '..\Shared\ServiceVersion.pas',
  DeviceService in '..\Shared\DeviceService.pas',
  CashOutReceipt in 'units\CashOutReceipt.pas',
  CashInReceipt in 'units\CashInReceipt.pas',
  OposPOSPrinter_CCO_TLB in '..\Opos\OposPOSPrinter_CCO_TLB.pas',
  PrinterParameters in '..\Shared\PrinterParameters.pas',
  FileUtils in '..\Shared\FileUtils.pas',
  PrinterParametersX in '..\Shared\PrinterParametersX.pas',
  StringUtils in '..\Shared\StringUtils.pas',
  RegExpr in '..\Shared\RegExpr.pas',
  SalesReceipt in 'units\SalesReceipt.pas',
  ReceiptItem in 'units\ReceiptItem.pas',
  TextDocument in 'units\TextDocument.pas',
  PrinterParametersReg in '..\Shared\PrinterParametersReg.pas',
  ItemUnit in '..\Shared\ItemUnit.pas',
  OposFiscalPrinter_CCO_TLB in '..\Opos\OposFiscalPrinter_CCO_TLB.pas',
  OposDevice in '..\Opos\OposDevice.pas',
  Translation in '..\Shared\Translation.pas',
  DirectIOAPI in 'units\DirectIOAPI.pas',
  xmlParser in '..\Shared\XMLParser.pas',
  DriverContext in '..\Shared\DriverContext.pas',
  PrinterTypes in '..\Shared\PrinterTypes.pas',
  WebPrinter in 'units\WebPrinter.pas',
  VatRate in '..\Shared\VatRate.pas',
  uLkJSON in '..\Shared\uLkJSON.pas',
  TLVItem in 'units\TLVItem.pas';

exports
  DllGetClassObject,
  DllCanUnloadNow,
  DllRegisterServer,
  DllUnregisterServer;

{$R *.TLB}

{$R *.RES}

begin
end.

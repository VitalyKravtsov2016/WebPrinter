program WebFptrCfg;

uses
  Forms,
  SysUtils,
  gnugettext,
  fmuMain in 'Fmu\fmuMain.pas' {fmMain},
  fmuDevice in 'Fmu\fmuDevice.pas' {fmDevice},
  fmuPages in 'Fmu\fmuPages.pas' {fmPages},
  untUtil in 'Units\untUtil.pas',
  Oposhi in '..\Opos\Oposhi.pas',
  OposUtils in '..\Opos\OposUtils.pas',
  Opos in '..\Opos\Opos.pas',
  OposEvents in '..\Opos\OposEvents.pas',
  OPOSException in '..\Opos\OposException.pas',
  OposFptr in '..\Opos\OposFptr.pas',
  OposFptrhi in '..\Opos\OposFptrhi.pas',
  OposFptrUtils in '..\Opos\OposFptrUtils.pas',
  OposDevice in '..\Opos\OposDevice.pas',
  OposFiscalPrinter_1_12_Lib_TLB in '..\Opos\OposFiscalPrinter_1_12_Lib_TLB.pas',
  DriverError in '..\Shared\DriverError.pas',
  VersionInfo in '..\Shared\VersionInfo.pas',
  DebugUtils in '..\Shared\DebugUtils.pas',
  BaseForm in '..\Shared\BaseForm.pas',
  FileUtils in '..\Shared\FileUtils.pas',
  LogFile in '..\Shared\LogFile.pas',
  WException in '..\Shared\WException.pas',
  RegExpr in '..\Shared\RegExpr.pas',
  JsonUtils in '..\Shared\JsonUtils.pas',
  untPages in 'Units\untPages.pas',
  FptrTypes in 'Units\FptrTypes.pas',
  FiscalPrinterDevice in 'Units\FiscalPrinterDevice.pas',
  fmuFptrLog in 'Fmu\fmuFptrLog.pas' {fmFptrLog},
  StringUtils in '..\Shared\StringUtils.pas',
  fmuFptrConnection in 'Fmu\fmuFptrConnection.pas' {fmFptrConnection},
  OposEventsRCS in '..\Opos\OposEventsRCS.pas',
  OposSemaphore in '..\Opos\OposSemaphore.pas',
  ItemUnit in '..\Shared\ItemUnit.pas',
  uLkJSON in '..\Shared\uLkJSON.pas',
  OposServiceDevice19 in '..\Opos\OposServiceDevice19.pas',
  ServiceVersion in '..\Shared\ServiceVersion.pas',
  DeviceService in '..\Shared\DeviceService.pas',
  Translation in '..\Shared\Translation.pas',
  xmlParser in '..\Shared\XMLParser.pas',
  PrinterParameters in '..\Shared\PrinterParameters.pas',
  PrinterTypes in '..\Shared\PrinterTypes.pas',
  WebFptrSo_TLB in '..\WebFptrSo\WebFptrSo_TLB.pas',
  PrinterParametersX in '..\Shared\PrinterParametersX.pas',
  PrinterParametersReg in '..\Shared\PrinterParametersReg.pas',
  DriverContext in '..\Shared\DriverContext.pas',
  ReceiptItem in '..\WebFptrSo\units\ReceiptItem.pas',
  MathUtils in '..\WebFptrSo\units\MathUtils.pas',
  NotifyThread in '..\Shared\NotifyThread.pas',
  WebPrinter in '..\WebFptrSo\units\WebPrinter.pas',
  fmuFptrUnit in 'Fmu\fmuFptrUnit.pas' {fmFptrUnit},
  fmuFptrCashDrawer in 'Fmu\fmuFptrCashDrawer.pas' {fmFptrCashDrawer},
  fmuFptrPayType in 'Fmu\fmuFptrPayType.pas' {fmFptrPayType},
  VatRate in '..\Shared\VatRate.pas',
  fmuFptrVatRate in 'Fmu\fmuFptrVatRate.pas' {fmFptrVatRate};

{$R *.RES}
{$R WindowsXP.RES}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.




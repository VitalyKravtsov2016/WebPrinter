program WebFptrTst;

uses
  Forms,
  fmuMain in 'Fmu\fmuMain.pas' {fmMain},
  fmuAbout in 'Fmu\fmuAbout.pas' {fmAbout},
  fmuFptrRecTaxID in 'Fmu\fmuFptrRecTaxID.pas' {fmFptrRecTaxID},
  fmuFptrRecMessage in 'Fmu\fmuFptrRecMessage.pas' {fmFptrRecMessage},
  fmuFptrRecRefund in 'Fmu\fmuFptrRecRefund.pas' {fmFptrRecRefund},
  fmuFptrRecNotPaid in 'Fmu\fmuFptrRecNotPaid.pas' {fmFptrRecNotPaid},
  fmuFptrRecItemAdjust in 'Fmu\fmuFptrRecItemAdjust.pas' {fmFptrRecItemAdjust},
  fmuFptrRecRefundVoid in 'Fmu\fmuFptrRecRefundVoid.pas' {fmFptrRecRefundVoid},
  fmuFptrFiscalReports in 'Fmu\fmuFptrFiscalReports.pas' {fmFptrFiscalReports},
  fmuPrintRecItemRefundVoid in 'Fmu\fmuPrintRecItemRefundVoid.pas' {fmPrintRecItemRefundVoid},
  fmuFptrRecPackageAdjustVoid in 'Fmu\fmuFptrRecPackageAdjustVoid.pas' {fmFptrRecPackageAdjustVoid},
  fmuFptrRecSubtotalAdjustVoid in 'Fmu\fmuFptrRecSubtotalAdjustVoid.pas' {fmFptrRecSubtotalAdjustVoid},
  fmuFptrRecPackageAdjustment in 'Fmu\fmuFptrRecPackageAdjustment.pas' {fmFptrRecPackageAdjustment},
  fmuFptrRecSubtotalAdjustment in 'Fmu\fmuFptrRecSubtotalAdjustment.pas' {fmFptrRecSubtotalAdjustment},
  fmuFptrRecCash in 'Fmu\fmuFptrRecCash.pas' {fmFptrRecCash},
  fmuFptrRecTotal in 'Fmu\fmuFptrRecTotal.pas' {fmFptrRecTotal},
  fmuFptrNonFiscal in 'Fmu\fmuFptrNonFiscal.pas' {fmFptrNonFiscal},
  fmuFptrDriverTest in 'Fmu\fmuFptrDriverTest.pas' {fmFptrDriverTest},
  fmuFptrFiscalDocument in 'Fmu\fmuFptrFiscalDocument.pas' {fmFptrFiscalDocument},
  fmuFptrStatistics in 'Fmu\fmuFptrStatistics.pas' {fmFptrStatistics},
  fmuFptrSetVatTable in 'Fmu\fmuFptrSetVatTable.pas' {fmFptrSetVatTable},
  fmuFptrWritableProperties in 'Fmu\fmuFptrWritableProperties.pas' {fmFptrWritableProperties},
  fmuFptrSlipInsertion in 'Fmu\fmuFptrSlipInsertion.pas' {fmFptrSlipInsertion},
  fmuFptrFiscalStorage in 'Fmu\fmuFptrFiscalStorage.pas' {fmFptrFiscalStorage},
  fmuFptrReceipt in 'Fmu\fmuFptrReceipt.pas' {fmFptrReceipt},
  fmuFptrRecSubtotal in 'Fmu\fmuFptrRecSubtotal.pas' {fmFptrRecSubtotal},
  fmuFptrSetline in 'Fmu\fmuFptrSetline.pas' {fmFptrSetLine},
  fmuFptrGetData in 'Fmu\fmuFptrGetData.pas' {fmFptrGetData},
  fmuFptrProperties in 'Fmu\fmuFptrProperties.pas' {fmFptrProperties},
  fmuFptrTraining in 'Fmu\fmuFptrTraining.pas' {fmFptrTraining},
  fmuFptrDirectIO in 'Fmu\fmuFptrDirectIO.pas' {fmFptrDirectIO},
  fmuFptrDirectIOEndDay in 'Fmu\fmuFptrDirectIOEndDay.pas' {fmFptrDirectIOEndDay},
  fmuFptrInfo in 'Fmu\fmuFptrInfo.pas' {fmFptrInfo},
  fmuFptrReceiptTest in 'Fmu\fmuFptrReceiptTest.pas' {fmFptrReceiptTest},
  fmuFiscalPrinter in 'Fmu\fmuFiscalPrinter.pas' {fmFiscalPrinter},
  fmuFptrDirectIOHex in 'Fmu\fmuFptrDirectIOHex.pas' {fmFptrDirectIOHex},
  fmuPrintRecVoidItem in 'Fmu\fmuPrintRecVoidItem.pas' {fmPrintRecVoidItem},
  fmuPrintRecItemRefund in 'Fmu\fmuPrintRecItemRefund.pas' {fmPrintRecItemRefund},
  fmuFptrSetHeaderTrailer in 'Fmu\fmuFptrSetHeaderTrailer.pas' {fmFptrSetHeaderTrailer},
  fmuFptrGeneral in 'Fmu\fmuFptrGeneral.pas' {fmFptrGeneral},
  fmuFptrRecItem in 'Fmu\fmuFptrRecItem.pas' {fmFptrRecItem},
  fmuFptrTest2 in 'Fmu\fmuFptrTest2.pas' {fmFptrTest2},
  fmuFptrThreadTest in 'Fmu\fmuFptrThreadTest.pas' {fmFptrThreadTest},
  fmuFptrTest in 'Fmu\fmuFptrTest.pas' {fmFptrTest},
  fmuFptrDate in 'Fmu\fmuFptrDate.pas' {fmFptrDate},
  fmuFptrEvents in 'Fmu\fmuFptrEvents.pas' {fmFptrEvents},
  Opos in '..\Opos\Opos.pas',
  OposUtils in '..\Opos\OposUtils.pas',
  OPOSException in '..\Opos\OposException.pas',
  OposFptr in '..\Opos\OposFptr.pas',
  OposFptrhi in '..\Opos\OposFptrhi.pas',
  Oposhi in '..\Opos\Oposhi.pas',
  DirectIOAPI in '..\WebFptrSo\Units\DirectIOAPI.pas',
  OposEvents in '..\Opos\OposEvents.pas',
  OposFptrUtils in '..\Opos\OposFptrUtils.pas',
  OposDevice in '..\Opos\OposDevice.pas',
  PrinterEncoding in '..\Opos\PrinterEncoding.pas',
  OposFiscalPrinter in '..\Opos\OposFiscalPrinter.pas',
  OposFiscalPrinter_1_13_Lib_TLB in '..\Opos\OposFiscalPrinter_1_13_Lib_TLB.pas',
  OposFiscalPrinter_1_12_Lib_TLB in '..\Opos\OposFiscalPrinter_1_12_Lib_TLB.pas',
  untUtil in 'Units\untUtil.pas',
  OPOSDate in 'Units\OPOSDate.pas',
  untPages in 'units\untPages.pas',
  PrinterTest in 'Units\PrinterTest.pas',
  AlignStrings in 'Units\AlignStrings.pas',
  DriverTest in 'Units\DriverTest.pas',
  DIODescription in 'Units\DIODescription.pas',
  BaseForm in '..\Shared\BaseForm.pas',
  LogFile in '..\Shared\LogFile.pas',
  XMLParser in '..\Shared\XMLParser.pas',
  BStrUtil in '..\Shared\BStrUtil.pas',
  VersionInfo in '..\Shared\VersionInfo.pas',
  DebugUtils in '..\Shared\DebugUtils.pas',
  FileUtils in '..\Shared\FileUtils.pas',
  StringUtils in '..\Shared\StringUtils.pas',
  DriverError in '..\Shared\DriverError.pas',
  BStdUtil in '..\Shared\BStdUtil.pas',
  NotifyThread in '..\Shared\NotifyThread.pas',
  WException in '..\Shared\WException.pas',
  RegExpr in '..\Shared\RegExpr.pas',
  msxml in '..\WebFptrSo\Units\MSXML.pas',
  PrinterTypes in '..\Shared\PrinterTypes.pas',
  WebFptrSo_TLB in '..\WebFptrSo\WebFptrSo_TLB.pas',
  PrinterParameters in '..\Shared\PrinterParameters.pas',
  PrinterParametersX in '..\Shared\PrinterParametersX.pas',
  PrinterParametersReg in '..\Shared\PrinterParametersReg.pas',
  ReceiptItem in '..\WebFptrSo\units\ReceiptItem.pas',
  MathUtils in '..\WebFptrSo\units\MathUtils.pas',
  Translation in '..\Shared\Translation.pas',
  SMFiscalPrinter in '..\Opos\SMFiscalPrinter.pas',
  VatRate in '..\Shared\VatRate.pas';

{$R *.RES}
{$R WindowsXP.RES}

begin
  Application.Initialize;
  Application.Title := 'OPOS test';
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.

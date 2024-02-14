unit duOleDriver;

interface

uses
  // VCL
  Windows, SysUtils, Classes, IniFiles,
  // Tnt
  TntClasses,
  // Indy
  IdURI,
  // Opos
  Opos, Oposhi, OposFptr, OposFptrhi, OposUtils, OposFptrUtils,
  // DUnit
  TestFramework,
  // This
  LogFile, FileUtils, WebPrinter, WebPrinterImpl, DriverError, JsonUtils,
  DirectIOAPI, SMFiscalPrinter, PrinterParameters, PrinterParametersX;

type
  { TWebPrinterTest }

  TOleDriverTest = class(TTestCase)
  private
    FDriver: TSMFiscalPrinter;
    procedure OpenClaimEnable;
    procedure ClaimDevice;
    procedure EnableDevice;
    procedure OpenService;
    procedure FptrCheck(Code: Integer); overload;
    procedure FptrCheck(Code: Integer; const AText: WideString); overload;

    property Driver: TSMFiscalPrinter read FDriver;
  protected
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestPrintZreport;
    procedure TestFiscalReceipt;
    procedure TestRefundReceipt;
    procedure TestRefundReceipt2;
    procedure TestNonFiscalReceipt;
    procedure TestNonfiscalReceipt2;
  end;

implementation

const
  FptrDeviceName = 'TestDeviceName';

{ TOleDriverTest }

procedure TOleDriverTest.Setup;
var
  Logger: ILogFile;
  Params: TPrinterParameters;
begin
  Logger := TLogFile.Create;
  Params := TPrinterParameters.Create(Logger);
  try
    Logger.Enabled := True;
    Params.WebprinterAddress := 'http://fbox.ngrok.io'; // 8080 или 80
    Params.LogFileEnabled := True;
    Params.LogMaxCount := 10;
    Params.VatRates.Clear;
    Params.VatRates.Add(1, 10,  'НДС 10%');
    Params.VatRates.Add(2, 12,  'НДС 12%');
    Params.VatRates.Add(10, 15,  'НДС 15%');
    SaveParameters(Params, FptrDeviceName, Logger);
  finally
    Params.Free;
  end;

  FDriver := TSMFiscalPrinter.Create(nil);
end;

procedure TOleDriverTest.TearDown;
begin
  FDriver.Free;
end;

procedure TOleDriverTest.FptrCheck(Code: Integer);
begin
  FptrCheck(Code, '');
end;

procedure TOleDriverTest.FptrCheck(Code: Integer; const AText: WideString);
var
  Text: WideString;
begin
  if Code <> OPOS_SUCCESS then
  begin
    if Driver.ResultCode = OPOS_E_EXTENDED then
      Text := WideFormat('%s: %d, %d, %s [%s]', [AText, Driver.ResultCode,
        Driver.ResultCodeExtended, GetResultCodeExtendedText(Driver.ResultCodeExtended),
        Driver.ErrorString])
    else
      Text := WideFormat('%s: %d, %s [%s]', [AText, Driver.ResultCode,
        GetResultCodeText(Driver.ResultCode), Driver.ErrorString]);

    raise Exception.Create(Text);
  end;
end;

procedure TOleDriverTest.OpenService;
begin
  if Driver.State = OPOS_S_CLOSED then
  begin
    FptrCheck(Driver.Open(FptrDeviceName));
    if Driver.CapPowerReporting <> OPOS_PR_NONE then
    begin
      Driver.PowerNotify := OPOS_PN_ENABLED;
    end;
  end;
end;

procedure TOleDriverTest.ClaimDevice;
begin
  if Driver.Claimed then
  begin
    CheckEquals(False, Driver.Claimed, 'Driver.Claimed');
    FptrCheck(Driver.ClaimDevice(1000));
    CheckEquals(True, Driver.Claimed, 'Driver.Claimed');
  end;
end;

procedure TOleDriverTest.EnableDevice;
begin
  if not Driver.DeviceEnabled then
  begin
    Driver.DeviceEnabled := True;
    FptrCheck(Driver.ResultCode);
    CheckEquals(OPOS_SUCCESS, Driver.ResultCode, 'OPOS_SUCCESS');
    CheckEquals(True, Driver.DeviceEnabled, 'Driver.DeviceEnabled');
  end;
end;

procedure TOleDriverTest.OpenClaimEnable;
begin
  OpenService;
  ClaimDevice;
  EnableDevice;
  FptrCheck(Driver.ResetPrinter, 'ResetPrinter');
end;

procedure TOleDriverTest.TestPrintZreport;
begin
  OpenClaimEnable;
  FptrCheck(Driver.PrintZReport);
end;

const
  Barcode = '0104601662000016215d>9nB'#$1D'934x0v'#$0D;

procedure TOleDriverTest.TestFiscalReceipt;
var
  pData: Integer;
  pString: WideString;
  CashierID: WideString;
  Strings: TTntStringList;
begin
  OpenClaimEnable;
  // Read cashier ID
  Strings := TTntStringList.Create;
  try
    Strings.LastFileCharSet := csUnicode;
    Strings.LoadFromFile('CashierID.txt');
    CashierID := Strings[0];
  finally
    Strings.Free;
  end;
  Driver.SetPOSID('POS1', CashierID);
  CheckEquals(FPTR_PS_MONITOR, Driver.PrinterState);
  Driver.FiscalReceiptType := FPTR_RT_SALES;
  CheckEquals(FPTR_RT_SALES, Driver.FiscalReceiptType);

  FptrCheck(Driver.BeginFiscalReceipt(True));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT, Driver.PrinterState);

  FptrCheck(Driver.DirectIO2(30, 80, Barcode));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_BARCODE, 0, '4780000000007'));
  FptrCheck(Driver.PrintRecItem('"Item 1"'#10#13, 100, 1000, 10, 100, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_PERCENTAGE_DISCOUNT, 'Скидка бонусами', 1000, 4));

  FptrCheck(Driver.PrintRecItem('Item 2', 100, 1000, 1, 100, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, 'Скидка бонусами', 10, 4));

  FptrCheck(Driver.PrintRecItem('Item 3', 100, 1000, 2, 100, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, 'Скидка бонусами', 9, 4));

  FptrCheck(Driver.PrintRecItem('Item 4', 100, 1000, 3, 100, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, 'Скидка бонусами', 8, 4));

  FptrCheck(Driver.PrintRecTotal(400, 150, '0'));
  FptrCheck(Driver.PrintRecTotal(400, 100, '1'));
  FptrCheck(Driver.PrintRecTotal(400, 100, '2'));
  FptrCheck(Driver.PrintRecTotal(400, 100, '3'));

  CheckEquals(FPTR_PS_FISCAL_RECEIPT_ENDING, Driver.PrinterState);

  FptrCheck(Driver.EndFiscalReceipt(False));
  CheckEquals(FPTR_PS_MONITOR, Driver.PrinterState);

  pData := 0;
  pString := '';
  FptrCheck(Driver.GetData(FPTR_GD_GRAND_TOTAL, pData, pString));
  checkEquals(6300, StrToInt(pString), 'FPTR_GD_GRAND_TOTAL');

  pData := 0;
  pString := '';
  FptrCheck(Driver.GetData(FPTR_GD_RECEIPT_NUMBER, pData, pString));
  checkEquals(1, StrToInt(pString), 'FPTR_GD_RECEIPT_NUMBER');
end;

procedure TOleDriverTest.TestRefundReceipt;
const
  receipt_qr_code = 'https://ofd.soliq.uz/check?t=UZ191211501001&r=1447&c=20220309125810&s=461313663448';
begin
  OpenClaimEnable;
  Driver.SetPOSID('POS1', 'Cahier 1');
  CheckEquals(FPTR_PS_MONITOR, Driver.PrinterState);
  Driver.FiscalReceiptType := FPTR_RT_REFUND;
  CheckEquals(FPTR_RT_REFUND, Driver.FiscalReceiptType);

  FptrCheck(Driver.BeginFiscalReceipt(True));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT, Driver.PrinterState);
  FptrCheck(Driver.DirectIO2(DIO_SET_RECEIPT_JSON_FIELD, 0, 'qr_code;' + receipt_qr_code));

  //FptrCheck(Driver.DirectIO2(30, 80, '4780000000007'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_BARCODE, 0, '4780000000007'));
  FptrCheck(Driver.DirectIO2(DIO_ADD_ITEM_CODE, 0, Barcode));
  FptrCheck(Driver.PrintRecItem('"Item 1"'#10#13, 100, 1000, 0, 100, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_PERCENTAGE_DISCOUNT, 'Скидка бонусами', 1000, 4));

  FptrCheck(Driver.PrintRecItem('Item 2', 100, 1000, 1, 100, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, 'Скидка бонусами', 10, 4));

  FptrCheck(Driver.PrintRecItem('Item 3', 100, 1000, 2, 100, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, 'Скидка бонусами', 9, 4));

  FptrCheck(Driver.PrintRecItem('Item 4', 100, 1000, 3, 100, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, 'Скидка бонусами', 8, 4));

  FptrCheck(Driver.PrintRecTotal(400, 150, '0'));
  FptrCheck(Driver.PrintRecTotal(400, 100, '1'));
  FptrCheck(Driver.PrintRecTotal(400, 100, '2'));
  FptrCheck(Driver.PrintRecTotal(400, 100, '3'));

  CheckEquals(FPTR_PS_FISCAL_RECEIPT_ENDING, Driver.PrinterState);

  FptrCheck(Driver.EndFiscalReceipt(False));
  CheckEquals(FPTR_PS_MONITOR, Driver.PrinterState);
end;

procedure TOleDriverTest.TestRefundReceipt2;
const
  receipt_qr_code = 'https://ofd.soliq.uz/check?t=UZ191211501001&r=1447&c=20220309125810&s=461313663448';
begin
  OpenClaimEnable;
  Driver.SetPOSID('POS1', 'Cahier 1');
  CheckEquals(FPTR_PS_MONITOR, Driver.PrinterState);
  Driver.FiscalReceiptType := FPTR_RT_SALES;
  CheckEquals(FPTR_RT_SALES, Driver.FiscalReceiptType);

  FptrCheck(Driver.BeginFiscalReceipt(True));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT, Driver.PrinterState);
  FptrCheck(Driver.DirectIO2(DIO_SET_RECEIPT_JSON_FIELD, 0, 'qr_code;' + receipt_qr_code));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_BARCODE, 0, '4780000000007'));
  FptrCheck(Driver.DirectIO2(DIO_ADD_ITEM_CODE, 0, Barcode));
  FptrCheck(Driver.PrintRecItemRefund('"Item 1"'#10#13, 100, 1000, 0, 100, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_PERCENTAGE_DISCOUNT, 'Скидка бонусами', 1000, 4));

  FptrCheck(Driver.PrintRecTotal(400, 10, '1'));
  FptrCheck(Driver.PrintRecTotal(400, 10, '2'));
  FptrCheck(Driver.PrintRecTotal(400, 10, '3'));
  FptrCheck(Driver.PrintRecTotal(400, 150, '0'));

  CheckEquals(FPTR_PS_FISCAL_RECEIPT_ENDING, Driver.PrinterState);

  FptrCheck(Driver.EndFiscalReceipt(False));
  CheckEquals(FPTR_PS_MONITOR, Driver.PrinterState);
end;

procedure TOleDriverTest.TestNonFiscalReceipt;
const
  TextData =
  'Safe Drop Receipt                         ' + CRLF +
  '==========================================' + CRLF +
  'Emploee ID....:                     199192' + CRLF +
  'Date..........:                 12/01/2021' + CRLF +
  'Store ID......:                       UZ11' + CRLF +
  'Time..........:                      20:40' + CRLF +
  'Pos ID........:                  UZ11POS04' + CRLF +
  '' + CRLF +
  '------------------------------------------' + CRLF +
  '' + CRLF +
  '       100.00 * 20          2,000.00 UZS  ' + CRLF +
  '     1,000.00 * 13         13,000.00 UZS  ' + CRLF +
  '     5,000.00 * 25        125,000.00 UZS  ' + CRLF +
  '    10,000.00 * 11        100,000.00 UZS  ' + CRLF +
  '' + CRLF +
  '             Total:       250,000.00 UZS  ' + CRLF +
  '' + CRLF +
  '==========================================' + CRLF +
  '' + CRLF +
  'Total Local Amount:       250,000.00 UZS  ' + CRLF +
  '' + CRLF +
  '==========================================' + CRLF +
  '' + CRLF +
  'Cashier                 Store Mamager     ' + CRLF +
  'Name Surname:           Name Surname:     ' + CRLF +
  '' + CRLF +
  '' + CRLF +
  'Signature:              Signature:        ' + CRLF +
  '' + CRLF +
  '' + CRLF +
  '' + CRLF +
  '==========================================';
var
  i: Integer;
  Lines: TTntStrings;
begin
  Lines := TTntStringList.Create;
  try
    Lines.Text := TextData;

    OpenClaimEnable;
    FptrCheck(Driver.BeginNonFiscal, 'Driver.BeginNonFiscal');
    for i := 0 to Lines.Count-1 do
    begin
      FptrCheck(Driver.PrintNormal(FPTR_S_RECEIPT, Lines[i]), 'PrintNormal');
    end;
    FptrCheck(Driver.EndNonFiscal, 'Driver.EndNonFiscal');
  finally
    Lines.Free;
  end;
end;

procedure TOleDriverTest.TestNonfiscalReceipt2;
var
  i: Integer;
  Strings: TTntStringList;
begin
  Strings := TTntStringList.Create;
  try
    Strings.LastFileCharSet := csUnicode;
    Strings.LoadFromFile('UnicodeText.txt');

    OpenClaimEnable;
    FptrCheck(Driver.BeginNonFiscal, 'Driver.BeginNonFiscal');
    for i := 0 to Strings.Count-1 do
    begin
      FptrCheck(Driver.PrintNormal(FPTR_S_RECEIPT, Strings[i]), 'PrintNormal');
    end;
    FptrCheck(Driver.EndNonFiscal, 'Driver.EndNonFiscal');
  finally
    Strings.Free;
  end;
end;

initialization
  RegisterTest('', TOleDriverTest.Suite);


end.

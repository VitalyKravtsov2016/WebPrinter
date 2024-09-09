unit duWebPrinterImpl;

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
  DirectIOAPI, PrinterParametersX;

type
  { TWebPrinterTest }

  TWebPrinterImplTest = class(TTestCase)
  private
    FDriver: TWebPrinterImpl;
    procedure OpenClaimEnable;
    property Driver: TWebPrinterImpl read FDriver;
    procedure ClaimDevice;
    procedure EnableDevice;
    procedure OpenService;
    procedure FptrCheck(Code: Integer); overload;
    procedure FptrCheck(Code: Integer; const AText: WideString); overload;
    procedure PrintRefundReceipt(Amount, CashAmount, CardAmount: Currency);
    procedure PrintSalesReceipt(Amount, CashAmount, CardAmount: Currency);
    function ReadCashRegister(Number: Integer): Currency;
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
    procedure TestTotalizers;
    procedure TestZeroFiscalReceipt;
    procedure TestZeroFiscalReceipt2;
    procedure TestFiscalReceipt2;
    procedure TestOpenFiscalDay;
  end;

implementation

const
  TestDeviceName = 'DeviceName';

{ TWebPrinterImplTest }

procedure TWebPrinterImplTest.Setup;
begin
  FDriver := TWebPrinterImpl.Create(nil);
  FDriver.Params.WebprinterAddress := 'http://fbox.ngrok.io'; // 8080 или 80
  FDriver.Params.LogFileEnabled := True;
  FDriver.Params.LogMaxCount := 10;
  FDriver.Params.VatRates.Clear;
  FDriver.Params.VatRates.Add(1, 10,  'НДС 10%');
  FDriver.Params.VatRates.Add(2, 12,  'НДС 12%');
  FDriver.Params.VatRates.Add(10, 15,  'НДС 15%');
  FDriver.Params.OpenCashbox := True;
  SaveParameters(FDriver.Params, TestDeviceName, FDriver.Logger);
end;

procedure TWebPrinterImplTest.TearDown;
begin
  FDriver.Free;
end;

procedure TWebPrinterImplTest.FptrCheck(Code: Integer);
begin
  FptrCheck(Code, '');
end;

procedure TWebPrinterImplTest.FptrCheck(Code: Integer; const AText: WideString);
var
  Text: WideString;
  ResultCode: Integer;
  ErrorString: WideString;
  ResultCodeExtended: Integer;
begin
  if Code <> OPOS_SUCCESS then
  begin
    ResultCode := Driver.GetPropertyNumber(PIDX_ResultCode);
    ResultCodeExtended := Driver.GetPropertyNumber(PIDX_ResultCodeExtended);
    ErrorString := Driver.GetPropertyString(PIDXFptr_ErrorString);

    if ResultCode = OPOS_E_EXTENDED then
      Text := WideFormat('%s: %d, %d, %s [%s]', [AText, ResultCode,
        ResultCodeExtended, GetResultCodeExtendedText(ResultCodeExtended),
        ErrorString])
    else
      Text := WideFormat('%s: %d, %s [%s]', [AText, ResultCode,
        GetResultCodeText(ResultCode), ErrorString]);

    raise Exception.Create(Text);
  end;
end;

procedure TWebPrinterImplTest.OpenService;
begin
  if Driver.GetPropertyNumber(PIDX_State) = OPOS_S_CLOSED then
  begin
    FptrCheck(Driver.OpenService(OPOS_CLASSKEY_FPTR, TestDeviceName, nil));
    if Driver.GetPropertyNumber(PIDX_CapPowerReporting) <> 0 then
    begin
      Driver.SetPropertyNumber(PIDX_PowerNotify, OPOS_PN_ENABLED);
    end;
  end;
end;

procedure TWebPrinterImplTest.ClaimDevice;
begin
  if Driver.GetPropertyNumber(PIDX_Claimed) = 0 then
  begin
    CheckEquals(0, Driver.GetPropertyNumber(PIDX_Claimed),
      'GetPropertyNumber(PIDX_Claimed)');
    FptrCheck(Driver.ClaimDevice(1000));
    CheckEquals(1, Driver.GetPropertyNumber(PIDX_Claimed),
      'GetPropertyNumber(PIDX_Claimed)');
  end;
end;

procedure TWebPrinterImplTest.EnableDevice;
var
  ResultCode: Integer;
begin
  if Driver.GetPropertyNumber(PIDX_DeviceEnabled) = 0 then
  begin
    Driver.SetPropertyNumber(PIDX_DeviceEnabled, 1);
    ResultCode := Driver.GetPropertyNumber(PIDX_ResultCode);
    FptrCheck(ResultCode);

    CheckEquals(OPOS_SUCCESS, ResultCode, 'OPOS_SUCCESS');
    CheckEquals(1, Driver.GetPropertyNumber(PIDX_DeviceEnabled), 'DeviceEnabled');
  end;
end;

procedure TWebPrinterImplTest.OpenClaimEnable;
begin
  OpenService;
  ClaimDevice;
  EnableDevice;
  FptrCheck(Driver.ResetPrinter, 'ResetPrinter');
end;

procedure TWebPrinterImplTest.TestPrintZreport;
begin
  OpenClaimEnable;
  FptrCheck(Driver.PrintZReport);
end;

const
  Barcode = '0104601662000016215d>9nB'#$1D'934x0v'#$0D;

procedure TWebPrinterImplTest.TestFiscalReceipt;
var
  pData: Integer;
  pString: WideString;
begin
  OpenClaimEnable;
  Driver.SetPOSID('POS1', 'Cahier 1');
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  CheckEquals(FPTR_RT_SALES, Driver.GetPropertyNumber(PIDXFptr_FiscalReceiptType));

  FptrCheck(Driver.BeginFiscalReceipt(True));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

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

  CheckEquals(FPTR_PS_FISCAL_RECEIPT_ENDING, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  FptrCheck(Driver.EndFiscalReceipt(False));
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  pData := 0;
  pString := '';
  FptrCheck(Driver.GetData(FPTR_GD_GRAND_TOTAL, pData, pString));
  checkEquals(6300, StrToInt(pString), 'FPTR_GD_GRAND_TOTAL');

  pData := 0;
  pString := '';
  FptrCheck(Driver.GetData(FPTR_GD_RECEIPT_NUMBER, pData, pString));
  checkEquals(1, StrToInt(pString), 'FPTR_GD_RECEIPT_NUMBER');
end;

procedure TWebPrinterImplTest.TestRefundReceipt;
const
  receipt_qr_code = 'https://ofd.soliq.uz/check?t=UZ191211501001&r=1447&c=20220309125810&s=461313663448';
begin
  OpenClaimEnable;
  Driver.SetPOSID('POS1', 'Cahier 1');
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_REFUND);
  CheckEquals(FPTR_RT_REFUND, Driver.GetPropertyNumber(PIDXFptr_FiscalReceiptType));

  FptrCheck(Driver.BeginFiscalReceipt(True));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
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

  CheckEquals(FPTR_PS_FISCAL_RECEIPT_ENDING, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  FptrCheck(Driver.EndFiscalReceipt(False));
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
end;

procedure TWebPrinterImplTest.TestRefundReceipt2;
const
  receipt_qr_code = 'https://ofd.soliq.uz/check?t=UZ191211501001&r=1447&c=20220309125810&s=461313663448';
begin
  OpenClaimEnable;
  Driver.SetPOSID('POS1', 'Cahier 1');
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  CheckEquals(FPTR_RT_SALES, Driver.GetPropertyNumber(PIDXFptr_FiscalReceiptType));

  FptrCheck(Driver.BeginFiscalReceipt(True));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
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

  CheckEquals(FPTR_PS_FISCAL_RECEIPT_ENDING, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  FptrCheck(Driver.EndFiscalReceipt(False));
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
end;

procedure TWebPrinterImplTest.TestNonFiscalReceipt;
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

procedure TWebPrinterImplTest.TestNonfiscalReceipt2;
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

function TWebPrinterImplTest.ReadCashRegister(Number: Integer): Currency;
var
  pString: WideString;
begin
  pString := '';
  FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, Number, pString));
  Result := StrToInt(pString)/100;
end;

procedure TWebPrinterImplTest.TestTotalizers;
begin
  OpenClaimEnable;
  FptrCheck(FDriver.PrintZReport, 'PrintZReport');

  CheckEquals(0, ReadCashRegister(241), 'ReadCashRegister(241).0');

  FDriver.Params.SalesAmountCash := 0;
  FDriver.Params.SalesAmountCard := 0;
  FDriver.Params.RefundAmountCash := 0;
  FDriver.Params.RefundAmountCard := 0;

  PrintSalesReceipt(7623.45, 8000, 1000);
  CheckEquals(6623.45, ReadCashRegister(241), 'ReadCashRegister(241).1');

  CheckEquals(0, FDriver.Params.SalesAmountCash, 'SalesAmountCash');
  CheckEquals(0, FDriver.Params.SalesAmountCash, 'SalesAmountCash');
  CheckEquals(0, FDriver.Params.SalesAmountCard, 'SalesAmountCard');
  CheckEquals(0, FDriver.Params.RefundAmountCash, 'RefundAmountCash');
  CheckEquals(0, FDriver.Params.RefundAmountCard, 'RefundAmountCard');

  PrintRefundReceipt(93.56, 100, 50);
  CheckEquals(6623.45-43.56, ReadCashRegister(241), 'ReadCashRegister(241).2');

  CheckEquals(0, FDriver.Params.SalesAmountCash, 'SalesAmountCash');
  CheckEquals(0, FDriver.Params.SalesAmountCard, 'SalesAmountCard');
  CheckEquals(0, FDriver.Params.RefundAmountCash, 'RefundAmountCash');
  CheckEquals(0, FDriver.Params.RefundAmountCard, 'RefundAmountCard');

  FptrCheck(FDriver.PrintZReport, 'PrintZReport');
  CheckEquals(0, ReadCashRegister(241), 'ReadCashRegister(241).3');
  CheckEquals(6623.45, FDriver.Params.SalesAmountCash, 'SalesAmountCash');
  CheckEquals(1000, FDriver.Params.SalesAmountCard, 'SalesAmountCard');
  CheckEquals(43.56, FDriver.Params.RefundAmountCash, 'RefundAmountCash');
  CheckEquals(50, FDriver.Params.RefundAmountCard, 'RefundAmountCard');
end;

procedure TWebPrinterImplTest.PrintSalesReceipt(Amount, CashAmount, CardAmount: Currency);
begin
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  FptrCheck(Driver.BeginFiscalReceipt(True));
  FptrCheck(Driver.PrintRecItem('Item 1', Amount, 1000, 0, Amount, ''));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecTotal(Amount, CardAmount, '1'));
  FptrCheck(Driver.PrintRecTotal(Amount, CashAmount, '0'));
  FptrCheck(Driver.EndFiscalReceipt(False));
end;

procedure TWebPrinterImplTest.PrintRefundReceipt(Amount, CashAmount, CardAmount: Currency);
const
  receipt_qr_code = 'https://ofd.soliq.uz/check?t=UZ191211501001&r=1447&c=20220309125810&s=461313663448';
begin
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_REFUND);
  FptrCheck(Driver.BeginFiscalReceipt(True));
  FptrCheck(Driver.DirectIO2(DIO_SET_RECEIPT_JSON_FIELD, 0, 'qr_code;' + receipt_qr_code));
  FptrCheck(Driver.PrintRecItem('Item 1', Amount, 1000, 0, Amount, ''));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecTotal(Amount, CardAmount, '1'));
  FptrCheck(Driver.PrintRecTotal(Amount, CashAmount, '0'));
  FptrCheck(Driver.EndFiscalReceipt(False));
end;

procedure TWebPrinterImplTest.TestZeroFiscalReceipt;
var
  Order: TWPOrder;
begin
  OpenClaimEnable;
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  CheckEquals(FPTR_RT_SALES, Driver.GetPropertyNumber(PIDXFptr_FiscalReceiptType));

  FptrCheck(Driver.BeginFiscalReceipt(True));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  FptrCheck(Driver.PrintRecItem('Item 1', 0, 1000, 10, 0, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecTotal(0, 0, '0'));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT_ENDING, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  FptrCheck(Driver.EndFiscalReceipt(False));
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  CheckNotEquals('', Driver.Printer.RequestJson, 'Driver.Printer.RequestJson');
  WriteFileData('ZeroReceiptOrderRequest.json', Driver.Printer.RequestJson);

  Order := TWPOrder.Create;
  try
    JsonToObject(Driver.Printer.RequestJson, Order);
    CheckEquals(1, Order.products.Count, 'Order.products.Count');
    CheckEquals('Item 1', Order.products[0].name, 'Order.products[0].name');
    CheckEquals(0, Order.products[0].Price, 'Order.products[0].Price');
    CheckEquals(0, Order.products[0].Discount, 'Order.products[0].Discount');
  finally
    Order.Free;
  end;
end;

procedure TWebPrinterImplTest.TestZeroFiscalReceipt2;
var
  Order: TWPOrder;
begin
  OpenClaimEnable;
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  CheckEquals(FPTR_RT_SALES, Driver.GetPropertyNumber(PIDXFptr_FiscalReceiptType));
  Driver.SetPropertyNumber(PIDXFptr_CheckTotal, 1);
  CheckEquals(1, Driver.GetPropertyNumber(PIDXFptr_CheckTotal));

  FptrCheck(Driver.BeginFiscalReceipt(True));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  FptrCheck(Driver.PrintRecItem('Item 1', 10, 1000, 10, 10, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, 'Скидка на позицию 1', 1, 4));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, 'Скидка на позицию 2', 4, 4));
  FptrCheck(Driver.PrintRecSubtotalAdjustment(FPTR_AT_AMOUNT_DISCOUNT, 'Скидка на чек 1', 1));
  FptrCheck(Driver.PrintRecSubtotalAdjustment(FPTR_AT_AMOUNT_DISCOUNT, 'Скидка на чек 2', 4));
  FptrCheck(Driver.PrintRecTotal(0, 0, '0'));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT_ENDING, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  FptrCheck(Driver.EndFiscalReceipt(False));
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  CheckNotEquals('', Driver.Printer.RequestJson, 'Driver.Printer.RequestJson');
  WriteFileData('ZeroReceiptOrderRequest.json', Driver.Printer.RequestJson);

  Order := TWPOrder.Create;
  try
    JsonToObject(Driver.Printer.RequestJson, Order);
    CheckEquals(1, Order.products.Count, 'Order.products.Count');
    CheckEquals('Item 1', Order.products[0].name, 'Order.products[0].name');
    CheckEquals(1000, Order.products[0].Price, 'Order.products[0].Price');
    CheckEquals(1000, Order.products[0].Discount, 'Order.products[0].Discount');
  finally
    Order.Free;
  end;
end;

procedure TWebPrinterImplTest.TestFiscalReceipt2;
begin
  OpenClaimEnable;
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  FptrCheck(Driver.BeginFiscalReceipt(True));
  FptrCheck(Driver.DirectIO2(30, 72, '4'));
  FptrCheck(Driver.DirectIO2(30, 73, '1'));
  FptrCheck(Driver.PrintRecItem('PUMP 3: АИ92', 20160, 1120, 4, 18000, ''));
  FptrCheck(Driver.DirectIO2(120, 0, '02710001005000000'));
  FptrCheck(Driver.DirectIO2(106, 0, 'owner_type;0'));
  FptrCheck(Driver.DirectIO2(106, 0, 'package_code;0'));
  FptrCheck(Driver.PrintRecSubtotalAdjustment(1, 'Discount', 160));
  FptrCheck(Driver.PrintRecTotal(20000, 20000, '0'));
  FptrCheck(Driver.PrintRecMessage('Operator: ts'));
  FptrCheck(Driver.PrintRecMessage('ID:       1991 '));
  FptrCheck(Driver.DirectIO2(30, 302, '1'));
  FptrCheck(Driver.DirectIO2(30, 300, '1991'));
  FptrCheck(Driver.EndFiscalReceipt(False));
end;

procedure TWebPrinterImplTest.TestOpenFiscalDay;
begin
  OpenClaimEnable;
  //Driver.TestPrinterDate := Driver.GetPrinterDate;

  FptrCheck(Driver.PrintZReport);
  TestFiscalReceipt;
end;

initialization
  RegisterTest('', TWebPrinterImplTest.Suite);


end.

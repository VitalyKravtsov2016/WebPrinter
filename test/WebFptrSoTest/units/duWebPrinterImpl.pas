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
  DirectIOAPI, uLkJSON;

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
    procedure PrintCashInReceipt(Amount: Currency);
    procedure PrintCashOutReceipt(Amount: Currency);
    procedure PrintSalesReceipt(Amount, CashAmount, CardAmount: Currency);
    procedure PrintRefundReceipt(Amount, CashAmount, CardAmount: Currency);
  protected
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestPrintZreport;
    procedure TestFiscalReceipt;
    procedure TestRefundReceipt;
    procedure TestRefundReceipt2;
    procedure TestNonfiscalReceipt;
    procedure TestCashinReceipt;
    procedure TestCashinReceipt2;
    procedure TestCashoutReceipt;
    procedure TestCashoutReceipt2;
    procedure TestOpenFiscalDay;
    procedure TestFiscalReceipt2;
    procedure TestTotalizers;
    procedure TestTotalizers2;
    procedure TestCashInECRTotalizer;
    procedure TestDirectIO_106;
    procedure TestClassCodes;
    procedure TestZeroFiscalReceipt;
    procedure TestZeroFiscalReceipt2;
  end;

implementation

{ TWebPrinterImplTest }

procedure TWebPrinterImplTest.Setup;
begin
  FDriver := TWebPrinterImpl.Create(nil);
  FDriver.TestMode := True;
  FDriver.Printer.TestMode := True;
  FDriver.Params.WebprinterAddress := 'http://fbox.ngrok.io'; // 8080 или 80
  //FDriver.Params.LogFileEnabled := True;
  FDriver.Params.LogFileEnabled := False;
  FDriver.Params.LogMaxCount := 10;
  FDriver.Params.VatRates.Clear;
  FDriver.Params.VatRates.Add(1, 10,  'НДС 10%');
  FDriver.Params.VatRates.Add(2, 12,  'НДС 12%');
  FDriver.Params.VatRates.Add(10, 15,  'НДС 15%');
  FDriver.Params.CashInECRAutoZero := False;
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
    FptrCheck(Driver.OpenService(OPOS_CLASSKEY_FPTR, 'DeviceName', nil));
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
  Order: TWPOrder;
begin
  OpenClaimEnable;
(*
  //Driver.Params.RecDiscountOnClassCode := False;
  Driver.Params.RecDiscountOnClassCode := True;
  Driver.Params.ClassCodes.Clear;
  Driver.Params.ClassCodes.Add('04811001001000000');
*)

  Driver.SetPOSID('POS1', 'Cahier 1');
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  CheckEquals(FPTR_RT_SALES, Driver.GetPropertyNumber(PIDXFptr_FiscalReceiptType));

  FptrCheck(Driver.BeginFiscalReceipt(True));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  FptrCheck(Driver.PrintRecMessage('Message 1'));
  FptrCheck(Driver.DirectIO2(30, 80, Barcode));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_BARCODE, 0, '4780000000007'));
  FptrCheck(Driver.PrintRecItem('Item 1', 100, 1000, 10, 100, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_PERCENTAGE_DISCOUNT, 'Скидка бонусами', 1000, 4));

  FptrCheck(Driver.PrintRecItem('Item 2', 100, 1000, 1, 100, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, 'Скидка бонусами', 10, 4));

  FptrCheck(Driver.PrintRecItem('Item 3', 100, 1000, 2, 100, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, 'Скидка бонусами', 9, 4));
  FptrCheck(Driver.DirectIO2(DIO_WRITE_FS_STRING_TAG_OP, 1226, '048768768768'));

  FptrCheck(Driver.PrintRecMessage('Message 2'));
  FptrCheck(Driver.PrintRecItem('Item 4', 100, 1000, 3, 100, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, 'Скидка бонусами', 8, 4));
  FptrCheck(Driver.DirectIO2(DIO_STLV_BEGIN, 1224, ''));
  FptrCheck(Driver.DirectIO2(DIO_STLV_ADD_TAG, 1226, '827364827346'));
  FptrCheck(Driver.DirectIO2(DIO_STLV_WRITE_OP, 0, ''));

  // Скидка на чек
  FptrCheck(Driver.PrintRecSubtotalAdjustment(FPTR_AT_AMOUNT_DISCOUNT, 'Скидка на чек', 10));

  FptrCheck(Driver.PrintRecMessage('Message 3'));
  FptrCheck(Driver.PrintRecTotal(390, 90, '0'));
  FptrCheck(Driver.PrintRecTotal(390, 100, '1'));
  FptrCheck(Driver.PrintRecTotal(390, 100, '2'));
  FptrCheck(Driver.PrintRecTotal(390, 100, '3'));
  FptrCheck(Driver.PrintRecMessage('Message 4'));

  CheckEquals(FPTR_PS_FISCAL_RECEIPT_ENDING, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  FptrCheck(Driver.EndFiscalReceipt(False));
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  CheckNotEquals('', Driver.Printer.RequestJson, 'Driver.Printer.RequestJson');
  WriteFileData('OrderRequest3.json', Driver.Printer.RequestJson);

  Order := TWPOrder.Create;
  try
    JsonToObject(Driver.Printer.RequestJson, Order);


    CheckEquals(4, Order.products.Count, 'Order.products.Count');
    CheckEquals('Item 1', Order.products[0].name, 'Order.products[0].name');
    CheckEquals('Item 2', Order.products[1].name, 'Order.products[1].name');
    CheckEquals('Item 3', Order.products[2].name, 'Order.products[2].name');
    CheckEquals('Item 4', Order.products[3].name, 'Order.products[3].name');

    CheckEquals(10000, Order.products[0].Price, 'Order.products[0].Price');
    CheckEquals(10000, Order.products[1].Price, 'Order.products[1].Price');
    CheckEquals(10000, Order.products[2].Price, 'Order.products[2].Price');
    CheckEquals(10000, Order.products[3].Price, 'Order.products[3].Price');

    CheckEquals(2000, Order.products[0].Discount, 'Order.products[0].Discount');
    CheckEquals(1000, Order.products[1].Discount, 'Order.products[1].Discount');
    CheckEquals(900, Order.products[2].Discount, 'Order.products[2].Discount');
    CheckEquals(800, Order.products[3].Discount, 'Order.products[3].Discount');

    CheckEquals(4, Order.banners.Count, 'Order.banners.Count');
    CheckEquals('text', Order.banners[0]._type, 'Order.banners[0]._type');
    CheckEquals('text', Order.banners[1]._type, 'Order.banners[1]._type');
    CheckEquals('text', Order.banners[2]._type, 'Order.banners[2]._type');
    CheckEquals('text', Order.banners[3]._type, 'Order.banners[3]._type');
    CheckEquals('Message 1', Order.banners[0].data, 'Order.banners[0].data');
    CheckEquals('Message 2', Order.banners[1].data, 'Order.banners[1].data');
    CheckEquals('Message 3', Order.banners[2].data, 'Order.banners[2].data');
    CheckEquals('Message 4', Order.banners[3].data, 'Order.banners[3].data');

    CheckEquals(4, Order.products.Count, 'products.Count');
    CheckEquals('', Order.products[0].comission_info.inn, 'comission_info.inn');
    CheckEquals('', Order.products[1].comission_info.inn, 'comission_info.inn');
    CheckEquals('048768768768', Order.products[2].comission_info.inn, 'comission_info.inn');
    CheckEquals('827364827346', Order.products[3].comission_info.inn, 'comission_info.inn');
  finally
    Order.Free;
  end;
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
var
  Json: TlkJSONbase;
  Item: TlkJSONbase;
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

  Check(Driver.Printer.CreateOrderResponse.RequestJson <> '');
  Json := TlkJSON.ParseText(Driver.Printer.CreateOrderResponse.RequestJson);
  try
    Check(Json <> nil, 'Json = nil');
    CheckEquals(11, Json.Count, 'Json.Count');
    CheckEquals('1', Json.Field['number'].Value, 'number');
    CheckEquals('order', Json.Field['receipt_type'].Value, 'receipt_type');
    CheckEquals('Cahier 1', Json.Field['cashier'].Value, 'cashier');
    CheckEquals(6000, Json.Field['received_cash'].Value, 'received_cash');
    CheckEquals(9000, Json.Field['change'].Value, 'change');
    CheckEquals(3000, Json.Field['received_card'].Value, 'received_card');
    CheckEquals(1, Json.Field['products'].Count, 'products');
    Item := Json.Field['products'].Child[0];
    CheckEquals('4780000000007', Item.Field['barcode'].Value, 'barcode');
    CheckEquals('"Item 1"'#10#13, Item.Field['name'].Value, 'name');
    CheckEquals(1000, Item.Field['amount'].Value, 'amount');
    CheckEquals('шт', Item.Field['unit_name'].Value, 'unit_name');
    CheckEquals(WP_UNIT_PEACE, Item.Field['units'].Value, 'units');
  finally
    Json.Free;
  end;
end;


procedure TWebPrinterImplTest.TestNonfiscalReceipt;
var
  i: Integer;
  //Text: WideString;
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

    //Text := ReadFileData('PrintTextRequest.json');
    //CheckEquals(Text, Driver.Printer.RequestJson, 'RequestJson');
  finally
    Strings.Free;
  end;
end;

procedure TWebPrinterImplTest.TestCashinReceipt;
var
  pData: Integer;
  Text: WideString;
  pString: WideString;
begin
  Driver.Params.CashInLine := 'CashInLine';
  Driver.Params.CashInPreLine := 'CashInPreLine';
  Driver.Params.CashInPostLine := 'CashInPostLine';
  Driver.Params.CashoutLine := 'CashoutLine';
  Driver.Params.CashoutPreLine := 'CashoutPreLine';
  Driver.Params.CashoutPostLine := 'CashoutPostLine';
  Driver.Params.CashInECRLine := 'CashInECRLine';

  OpenClaimEnable;

  Driver.Printer.Info.Data.terminal_id := 'terminal_id';
  FptrCheck(Driver.SetPOSID('PosID: 2', 'CashierID: Ivanov'));

  // Check grand total
  pData := 0;
  pString := '';
  FptrCheck(Driver.GetData(FPTR_GD_GRAND_TOTAL, pData, pString));
  CheckEquals('0', pString, 'pString <> 0');

  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_CASH_IN);
  CheckEquals(FPTR_RT_CASH_IN, Driver.GetPropertyNumber(PIDXFptr_FiscalReceiptType));

  FptrCheck(Driver.BeginFiscalReceipt(True));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  FptrCheck(Driver.PrintRecMessage('Message 1'));
  FptrCheck(Driver.PrintRecMessage('Message 2'));
  FptrCheck(Driver.PrintRecCash(123.45));
  FptrCheck(Driver.PrintRecTotal(123.45, 123.45, ''));
  FptrCheck(Driver.PrintRecMessage('Message 3'));
  FptrCheck(Driver.PrintRecMessage('Message 4'));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT_ENDING, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  FptrCheck(Driver.EndFiscalReceipt(False));
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  //WriteFileData('CashIn.json', Driver.Printer.RequestJson);
  Text := ReadFileData('CashIn.json');
  CheckEquals(Text, Driver.Printer.RequestJson, 'CashIn.json');

  // Check grand total
  pData := 0;
  pString := '';
  FptrCheck(Driver.GetData(FPTR_GD_GRAND_TOTAL, pData, pString));
  CheckEquals('12345', pString, 'pString <> 12345');

  FptrCheck(Driver.PrintXReport);
  WriteFileData('CashinXReport.json', Driver.Printer.RequestJson);
  Text := ReadFileData('CashinXReport.json');
  CheckEquals(Text, Driver.Printer.RequestJson, 'CashinXReport.json');

  FptrCheck(Driver.PrintZReport);
  WriteFileData('CashinZReport.json', Driver.Printer.RequestJson);
  Text := ReadFileData('CashinZReport.json');
  CheckEquals(Text, Driver.Printer.RequestJson, 'CashinZReport.json');

  FptrCheck(Driver.PrintXReport);
  WriteFileData('CashinXReport2.json', Driver.Printer.RequestJson);
  Text := ReadFileData('CashinXReport2.json');
  CheckEquals(Text, Driver.Printer.RequestJson, 'CashinXReport2.json');
end;

procedure TWebPrinterImplTest.TestCashinReceipt2;
begin
  OpenClaimEnable;
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_CASH_IN);
  FptrCheck(Driver.BeginFiscalReceipt(True));
  FptrCheck(Driver.PrintRecCash(1.01));
  FptrCheck(Driver.PrintRecCash(2.02));
  CheckEquals(OPOS_E_ILLEGAL, Driver.PrintRecTotal(3.03, 3.03, '1'));
  CheckEquals('Invalid payment type', Driver.GetPropertyString(PIDXFptr_ErrorString), 'ErrorString');
  CheckEquals(OPOS_E_ILLEGAL, Driver.PrintRecTotal(3.03, 5, ''));
  CheckEquals('Invalid payment amount', Driver.GetPropertyString(PIDXFptr_ErrorString), 'ErrorString');
  FptrCheck(Driver.PrintRecTotal(3.03, 1.01, ''));
  FptrCheck(Driver.PrintRecTotal(3.03, 2.02, ''));
  FptrCheck(Driver.EndFiscalReceipt(False));
end;

procedure TWebPrinterImplTest.TestCashoutReceipt;
var
  Text: WideString;
begin
  Driver.Params.CashInLine := 'CashInLine';
  Driver.Params.CashInPreLine := 'CashInPreLine';
  Driver.Params.CashInPostLine := 'CashInPostLine';
  Driver.Params.CashoutLine := 'CashoutLine';
  Driver.Params.CashoutPreLine := 'CashoutPreLine';
  Driver.Params.CashoutPostLine := 'CashoutPostLine';

  OpenClaimEnable;

  Driver.Printer.Info.Data.terminal_id := 'terminal_id';
  FptrCheck(Driver.SetPOSID('PosID: 2', 'CashierID: Ivanov'));

  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_CASH_OUT);
  CheckEquals(FPTR_RT_CASH_OUT, Driver.GetPropertyNumber(PIDXFptr_FiscalReceiptType));


  FptrCheck(Driver.BeginFiscalReceipt(True));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  FptrCheck(Driver.PrintRecMessage('Message 1'));
  FptrCheck(Driver.PrintRecMessage('Message 2'));
  FptrCheck(Driver.PrintRecCash(12345));
  FptrCheck(Driver.PrintRecTotal(12345, 12345, ''));
  FptrCheck(Driver.PrintRecMessage('Message 3'));
  FptrCheck(Driver.PrintRecMessage('Message 4'));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT_ENDING, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  FptrCheck(Driver.EndFiscalReceipt(False));
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  //WriteFileData('CashOut.json', Driver.Printer.RequestJson);
  Text := ReadFileData('CashOut.json');
  CheckEquals(Text, Driver.Printer.RequestJson, 'CashOut.json');

  FptrCheck(Driver.PrintXReport);
  WriteFileData('CashoutXReport.json', Driver.Printer.RequestJson);
  Text := ReadFileData('CashoutXReport.json');
  CheckEquals(Text, Driver.Printer.RequestJson, 'CashoutXReport.json');

  FptrCheck(Driver.PrintZReport);
  WriteFileData('CashoutZReport.json', Driver.Printer.RequestJson);
  Text := ReadFileData('CashoutZReport.json');
  CheckEquals(Text, Driver.Printer.RequestJson, 'CashoutZReport.json');

  FptrCheck(Driver.PrintXReport);
  WriteFileData('CashoutXReport2.json', Driver.Printer.RequestJson);
  Text := ReadFileData('CashoutXReport2.json');
  CheckEquals(Text, Driver.Printer.RequestJson, 'CashoutXReport2.json');
end;

procedure TWebPrinterImplTest.TestCashoutReceipt2;
begin
  OpenClaimEnable;
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_CASH_OUT);
  FptrCheck(Driver.BeginFiscalReceipt(True));
  FptrCheck(Driver.PrintRecCash(1.01));
  FptrCheck(Driver.PrintRecCash(2.02));
  CheckEquals(OPOS_E_ILLEGAL, Driver.PrintRecTotal(3.03, 3.03, '1'));
  CheckEquals('Invalid payment type', Driver.GetPropertyString(PIDXFptr_ErrorString), 'ErrorString');
  CheckEquals(OPOS_E_ILLEGAL, Driver.PrintRecTotal(3.03, 5, ''));
  CheckEquals('Invalid payment amount', Driver.GetPropertyString(PIDXFptr_ErrorString), 'ErrorString');
  FptrCheck(Driver.PrintRecTotal(3.03, 1.01, ''));
  FptrCheck(Driver.PrintRecTotal(3.03, 2.02, ''));
  FptrCheck(Driver.EndFiscalReceipt(False));
end;

procedure TWebPrinterImplTest.TestOpenFiscalDay;
begin
  // if DayOpened then nothing to do
  Driver.Printer.DayOpened := True;
  Driver.Printer.OpenDayResponse.error.code := 123;
  Driver.Printer.OpenFiscalDay3;
  CheckEquals(True, Driver.Printer.DayOpened, 'Driver.Printer.DayOpened');

  // if error.code = WP_ERROR_ZREPORT_IS_ALREADY_OPEN then DayOpened = true;
  Driver.Printer.DayOpened := False;
  Driver.Printer.OpenDayResponse.error.code := WP_ERROR_ZREPORT_IS_ALREADY_OPEN;
  Driver.Printer.OpenDayResponse.error.message := 'ERROR_ZREPORT_IS_ALREADY_OPEN';
  Driver.Printer.OpenFiscalDay3;
  CheckEquals(True, Driver.Printer.DayOpened, 'Driver.Printer.DayOpened');

  // if error.code = 0 then DayOpened = true;
  Driver.Printer.DayOpened := False;
  Driver.Printer.OpenDayResponse.error.code := 0;
  Driver.Printer.OpenFiscalDay3;
  CheckEquals(True, Driver.Printer.DayOpened, 'Driver.Printer.DayOpened');

  // if error.code <> 0 then Exception must be raised
  Driver.Printer.DayOpened := False;
  Driver.Printer.OpenDayResponse.error.code := 123;
  Driver.Printer.OpenDayResponse.error.message := 'Error123';
  try
    Driver.Printer.OpenFiscalDay3;
    Fail('No exception');
  except
    on E: EDriverError do
    begin
      CheckEquals(123, E.ErrorCode, 'E.ErrorCode');
      CheckEquals('Error123', E.Message, 'E.Message');
    end;
  end;
end;


procedure TWebPrinterImplTest.TestFiscalReceipt2;
var
  Order: TWPOrder;
begin
  OpenClaimEnable;

  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  CheckEquals(FPTR_RT_SALES, Driver.GetPropertyNumber(PIDXFptr_FiscalReceiptType));

  FptrCheck(Driver.BeginFiscalReceipt(True));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  FptrCheck(Driver.PrintRecItem('Item 1', 100, 1000, 10, 100, 'шт'));
  FptrCheck(Driver.PrintRecTotal(100, 100, '0'));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT_ENDING, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  FptrCheck(Driver.EndFiscalReceipt(False));
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  CheckNotEquals('', Driver.Printer.RequestJson, 'Driver.Printer.RequestJson');
  WriteFileData('OrderRequest3.json', Driver.Printer.RequestJson);

  Order := TWPOrder.Create;
  try
    JsonToObject(Driver.Printer.RequestJson, Order);
    CheckEquals(1, Order.products.Count, 'Order.products.Count');
    CheckEquals('Item 1', Order.products[0].name, 'Order.products[0].name');
    CheckEquals(10000, Order.products[0].Price, 'Order.products[0].Price');
    CheckEquals(0, Order.products[0].Discount, 'Order.products[0].Discount');
    CheckEquals(0, Order.banners.Count, 'Order.banners.Count');
  finally
    Order.Free;
  end;
end;

procedure TWebPrinterImplTest.TestTotalizers;
var
  pString: WideString;
  DayResult: TWPDayResult;
begin
  FDriver.Params.CashInECRAmount := 123.45;
  FDriver.Params.CashInAmount := 3454.78;
  FDriver.Params.CashOutAmount := 234.32;

  FDriver.Params.SalesAmountCash := 1278.54;
  FDriver.Params.SalesAmountCard := 9123.45;
  FDriver.Params.RefundAmountCash := 8213.34;
  FDriver.Params.RefundAmountCard := 83.45;
  DayResult := FDriver.Printer.CloseDayResponse2.result.data;
  DayResult.total_sale_cash := 12345;
  DayResult.total_sale_card := 23456;
  DayResult.total_refund_cash := 34567;
  DayResult.total_refund_card := 45678;


  OpenClaimEnable;
  pString := '';
  FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, 241, pString));
  CheckEquals('12345', pString, 'DirectIO3(DIO_READ_CASH_REG, 241');

  pString := '';
  FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, 242, pString));
  CheckEquals('345478', pString, 'DirectIO3(DIO_READ_CASH_REG, 242');

  pString := '';
  FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, 243, pString));
  CheckEquals('23432', pString, 'DirectIO3(DIO_READ_CASH_REG, 242');

  pString := '';
  FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, SMFPTR_CASHREG_DAY_TOTAL_SALE_CASH, pString));
  CheckEquals('12345', pString, 'SMFPTR_CASHREG_DAY_TOTAL_SALE_CASH');

  pString := '';
  FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, SMFPTR_CASHREG_DAY_TOTAL_SALE_CARD, pString));
  CheckEquals('23456', pString, 'SMFPTR_CASHREG_DAY_TOTAL_SALE_CARD');

  pString := '';
  FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, SMFPTR_CASHREG_DAY_TOTAL_RETSALE_CASH, pString));
  CheckEquals('34567', pString, 'SMFPTR_CASHREG_DAY_TOTAL_RETSALE_CASH');

  pString := '';
  FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, SMFPTR_CASHREG_DAY_TOTAL_RETSALE_CARD, pString));
  CheckEquals('45678', pString, 'SMFPTR_CASHREG_DAY_TOTAL_RETSALE_CARD');

  pString := '';
  FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, SMFPTR_CASHREG_GRAND_TOTAL_SALE_CASH, pString));
  CheckEquals(IntToStr(127854 + 12345), pString, 'SMFPTR_CASHREG_GRAND_TOTAL_SALE_CASH');

  pString := '';
  FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, SMFPTR_CASHREG_GRAND_TOTAL_SALE_CARD, pString));
  CheckEquals(IntToStr(912345 + 23456), pString, 'SMFPTR_CASHREG_GRAND_TOTAL_SALE_CARD');

  pString := '';
  FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, SMFPTR_CASHREG_GRAND_TOTAL_RETSALE_CASH, pString));
  CheckEquals(IntToStr(821334 + 34567), pString, 'SMFPTR_CASHREG_GRAND_TOTAL_RETSALE_CASH');

  pString := '';
  FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, SMFPTR_CASHREG_GRAND_TOTAL_RETSALE_CARD, pString));
  CheckEquals(IntToStr(8345 + 45678), pString, 'SMFPTR_CASHREG_GRAND_TOTAL_RETSALE_CARD');

end;

procedure TWebPrinterImplTest.PrintCashInReceipt(Amount: Currency);
begin
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_CASH_IN);
  FptrCheck(Driver.BeginFiscalReceipt(True));
  FptrCheck(Driver.PrintRecCash(Amount));
  FptrCheck(Driver.PrintRecTotal(Amount, Amount, ''));
  FptrCheck(Driver.EndFiscalReceipt(False));
end;

procedure TWebPrinterImplTest.PrintCashOutReceipt(Amount: Currency);
begin
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_CASH_OUT);
  FptrCheck(Driver.BeginFiscalReceipt(True));
  FptrCheck(Driver.PrintRecCash(Amount));
  FptrCheck(Driver.PrintRecTotal(Amount, Amount, ''));
  FptrCheck(Driver.EndFiscalReceipt(False));
end;

procedure TWebPrinterImplTest.PrintSalesReceipt(Amount, CashAmount, CardAmount: Currency);
begin
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  FptrCheck(Driver.BeginFiscalReceipt(True));
  FptrCheck(Driver.PrintRecItem('', Amount, 1000, 0, Amount, ''));
  FptrCheck(Driver.PrintRecTotal(Amount, CardAmount, '1'));
  FptrCheck(Driver.PrintRecTotal(Amount, CashAmount, '0'));
  FptrCheck(Driver.EndFiscalReceipt(False));
end;

procedure TWebPrinterImplTest.PrintRefundReceipt(Amount, CashAmount, CardAmount: Currency);
begin
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_REFUND);
  FptrCheck(Driver.BeginFiscalReceipt(True));
  FptrCheck(Driver.PrintRecItem('', Amount, 1000, 0, Amount, ''));
  FptrCheck(Driver.PrintRecTotal(Amount, CardAmount, '1'));
  FptrCheck(Driver.PrintRecTotal(Amount, CashAmount, '0'));
  FptrCheck(Driver.EndFiscalReceipt(False));
end;

procedure TWebPrinterImplTest.TestCashInECRTotalizer;
begin
  FDriver.TestMode := False;
  FDriver.Printer.TestMode := True;

  OpenClaimEnable;
  FDriver.Params.CashInECRAmount := 0;
  PrintCashInReceipt(2123.45);
  CheckEquals(2123.45, Driver.Params.CashInECRAmount, 'CashInECRAmount');
  CheckEquals(2123.45, Driver.Params.CashInAmount, 'CashInAmount');

  PrintCashOutReceipt(123.45);
  CheckEquals(2123.45-123.45, Driver.Params.CashInECRAmount);
  CheckEquals(123.45, Driver.Params.CashOutAmount, 'CashOutAmount');

  PrintSalesReceipt(7623.45, 8000, 1000);
  CheckEquals(2123.45-123.45 + 6623.45, Driver.Params.CashInECRAmount);

  PrintRefundReceipt(93.56, 100, 50);
  CheckEquals(2123.45-123.45 + 6623.45-43.56, Driver.Params.CashInECRAmount);

  Driver.Close;
  FDriver.Params.CashInECRAmount := 0;

  OpenClaimEnable;
  PrintCashInReceipt(768.45);
  CheckEquals(2123.45 + 768.45, Driver.Params.CashInAmount, 'CashInAmount');
  CheckEquals(2123.45-123.45 + 6623.45-43.56 + 768.45, Driver.Params.CashInECRAmount);
end;

procedure TWebPrinterImplTest.TestTotalizers2;
begin
  FDriver.TestMode := False;
  FDriver.Printer.TestMode := True;

  OpenClaimEnable;
  FDriver.Params.SalesAmountCash := 0;
  FDriver.Params.SalesAmountCard := 0;
  FDriver.Params.RefundAmountCash := 0;
  FDriver.Params.RefundAmountCard := 0;

  PrintSalesReceipt(7623.45, 8000, 1000);
  CheckEquals(0, FDriver.Params.SalesAmountCash, 'SalesAmountCash');
  CheckEquals(0, FDriver.Params.SalesAmountCard, 'SalesAmountCard');
  CheckEquals(0, FDriver.Params.RefundAmountCash, 'RefundAmountCash');
  CheckEquals(0, FDriver.Params.RefundAmountCard, 'RefundAmountCard');

  FDriver.Printer.CloseDayResponse.data.total_sale_cash := 662345;
  FDriver.Printer.CloseDayResponse.data.total_sale_card := 100000;
  FDriver.Printer.CloseDayResponse.data.total_refund_cash := 0;
  FDriver.Printer.CloseDayResponse.data.total_refund_card := 0;
  FptrCheck(FDriver.PrintZReport, 'PrintZReport');
  CheckEquals(6623.45, FDriver.Params.SalesAmountCash, 'SalesAmountCash');
  CheckEquals(1000, FDriver.Params.SalesAmountCard, 'SalesAmountCard');
  CheckEquals(0, FDriver.Params.RefundAmountCash, 'RefundAmountCash');
  CheckEquals(0, FDriver.Params.RefundAmountCard, 'RefundAmountCard');

  PrintRefundReceipt(93.56, 100, 50);
  CheckEquals(6623.45, FDriver.Params.SalesAmountCash, 'SalesAmountCash');
  CheckEquals(1000, FDriver.Params.SalesAmountCard, 'SalesAmountCard');
  CheckEquals(0, FDriver.Params.RefundAmountCash, 'RefundAmountCash');
  CheckEquals(0, FDriver.Params.RefundAmountCard, 'RefundAmountCard');

  FDriver.Printer.CloseDayResponse.data.total_sale_cash := 0;
  FDriver.Printer.CloseDayResponse.data.total_sale_card := 0;
  FDriver.Printer.CloseDayResponse.data.total_refund_cash := 4356;
  FDriver.Printer.CloseDayResponse.data.total_refund_card := 5000;
  FptrCheck(FDriver.PrintZReport, 'PrintZReport');

  CheckEquals(6623.45, FDriver.Params.SalesAmountCash, 'SalesAmountCash');
  CheckEquals(1000, FDriver.Params.SalesAmountCard, 'SalesAmountCard');
  CheckEquals(43.56, FDriver.Params.RefundAmountCash, 'RefundAmountCash');
  CheckEquals(50, FDriver.Params.RefundAmountCard, 'RefundAmountCard');
end;

procedure TWebPrinterImplTest.TestDirectIO_106;
var
  Order: TWPOrder;
begin
  OpenClaimEnable;
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  FptrCheck(Driver.BeginFiscalReceipt(True));

  FptrCheck(Driver.PrintRecItem('Item 1', 100, 1000, 10, 100, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_RECITEM_JSON_FIELD, 0, 'package_code;0'));
  FptrCheck(Driver.DirectIO2(DIO_SET_RECITEM_JSON_FIELD, 0, 'package_code;1'));

  FptrCheck(Driver.PrintRecItem('Item 2', 100, 1000, 1, 100, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_RECITEM_JSON_FIELD, 0, 'package_code;1493082'));

  FptrCheck(Driver.PrintRecTotal(200, 200, '0'));
  FptrCheck(Driver.EndFiscalReceipt(False));

  CheckNotEquals('', Driver.Printer.RequestJson, 'Driver.Printer.RequestJson');
  WriteFileData('OrderRequest4.json', Driver.Printer.RequestJson);

  Order := TWPOrder.Create;
  try
    JsonToObject(Driver.Printer.RequestJson, Order);
    CheckEquals(0, Order.banners.Count, 'Order.banners.Count');
    CheckEquals(2, Order.products.Count, 'Order.products.Count');
    CheckEquals('Item 1', Order.products[0].name, 'Order.products[0].name');
    CheckEquals('Item 2', Order.products[1].name, 'Order.products[1].name');
    CheckEquals(10000, Order.products[0].Price, 'Order.products[0].Price');
    CheckEquals(10000, Order.products[1].Price, 'Order.products[1].Price');
    CheckEquals(1, Order.products[0].package_code, 'Order.products[0].package_code');
    CheckEquals(1493082, Order.products[1].package_code, 'Order.products[1].package_code');
  finally
    Order.Free;
  end;
end;

procedure TWebPrinterImplTest.TestClassCodes;
var
  Order: TWPOrder;
begin
  Driver.Params.RecDiscountOnClassCode := True;
  Driver.Params.ClassCodes.Add('04811001001000000');

  OpenClaimEnable;
  Driver.SetPOSID('POS1', 'Cahier 1');
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  FptrCheck(Driver.BeginFiscalReceipt(True));

  FptrCheck(Driver.PrintRecItem('Item 1', 100, 1000, 10, 100, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000001'));
  FptrCheck(Driver.PrintRecItem('Item 2', 100, 1000, 10, 100, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000002'));
  FptrCheck(Driver.PrintRecItem('Item 3', 100, 1000, 10, 100, 'шт'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));

  // Скидка на чек
  FptrCheck(Driver.PrintRecSubtotalAdjustment(FPTR_AT_AMOUNT_DISCOUNT, 'Скидка на чек', 10));
  FptrCheck(Driver.PrintRecTotal(290, 290, '0'));
  FptrCheck(Driver.EndFiscalReceipt(False));

  CheckNotEquals('', Driver.Printer.RequestJson, 'Driver.Printer.RequestJson');
  WriteFileData('OrderRequest5.json', Driver.Printer.RequestJson);

  Order := TWPOrder.Create;
  try
    JsonToObject(Driver.Printer.RequestJson, Order);

    CheckEquals(3, Order.products.Count, 'Order.products.Count');
    CheckEquals('Item 1', Order.products[0].name, 'Order.products[0].name');
    CheckEquals('Item 2', Order.products[1].name, 'Order.products[1].name');
    CheckEquals('Item 3', Order.products[2].name, 'Order.products[2].name');

    CheckEquals(10000, Order.products[0].Price, 'Order.products[0].Price');
    CheckEquals(10000, Order.products[1].Price, 'Order.products[1].Price');
    CheckEquals(10000, Order.products[2].Price, 'Order.products[2].Price');

    CheckEquals(0, Order.products[0].Discount, 'Order.products[0].Discount');
    CheckEquals(0, Order.products[1].Discount, 'Order.products[1].Discount');
    CheckEquals(1000, Order.products[2].Discount, 'Order.products[2].Discount');

    CheckEquals('04811001001000001', Order.products[0].class_code, 'Order.products[0].class_code');
    CheckEquals('04811001001000002', Order.products[1].class_code, 'Order.products[1].class_code');
    CheckEquals('04811001001000000', Order.products[2].class_code, 'Order.products[2].class_code');
  finally
    Order.Free;
  end;
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

initialization
  RegisterTest('', TWebPrinterImplTest.Suite);


end.

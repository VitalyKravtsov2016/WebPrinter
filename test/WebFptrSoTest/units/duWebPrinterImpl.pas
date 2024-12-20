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
  DirectIOAPI, uLkJSON, PrinterParametersX, MarkCode;

type
  { TWebPrinterTest }

  TWebPrinterImplTest = class(TTestCase)
  private
    FDriver: TWebPrinterImpl;

    procedure OpenClaimEnable;
    procedure ClaimDevice;
    procedure EnableDevice;
    procedure OpenService;
    procedure FptrCheck(Code: Integer); overload;
    procedure FptrCheck(Code: Integer; const AText: WideString); overload;
    procedure PrintCashInReceipt(Amount: Currency);
    procedure PrintCashOutReceipt(Amount: Currency);
    procedure PrintSalesReceipt(Amount, CashAmount, CardAmount: Currency);
    procedure PrintRefundReceipt(Amount, CashAmount, CardAmount: Currency);
    procedure CheckCashDrawerRequest(const Request: TWPRequest);

    property Driver: TWebPrinterImpl read FDriver;
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
    procedure TestItemPercentDiscount;
    procedure TestItemAmountDiscount;
    procedure TestErrorOnCreateOrder;
    procedure TestMarkCode;
    procedure TestValidMarkCode;
    procedure TestCheckMarkCode;
  end;

implementation

{ TWebPrinterImplTest }

procedure TWebPrinterImplTest.Setup;
begin
  FDriver := TWebPrinterImpl.Create(nil);
  FDriver.TestMode := True;
  FDriver.Printer.TestMode := True;
  FDriver.Params.WebprinterAddress := 'http://fbox.ngrok.io'; // 8080 ��� 80
  FDriver.Params.LogFileEnabled := False;
  FDriver.Params.LogMaxCount := 10;
  FDriver.Params.VatRates.Clear;
  FDriver.Params.VatRates.Add(1, 10,  '��� 10%');
  FDriver.Params.VatRates.Add(2, 12,  '��� 12%');
  FDriver.Params.VatRates.Add(10, 15,  '��� 15%');
  FDriver.Params.CashInECRAutoZero := False;
  FDriver.Params.OpenCashbox := True;
end;

procedure TWebPrinterImplTest.TearDown;
begin
  FDriver.Free;
end;

procedure TWebPrinterImplTest.CheckCashDrawerRequest(const Request: TWPRequest);
begin
  // Open cash drawer
  if Driver.Params.OpenCashbox then
  begin
    CheckEquals('', Request.Request, 'Request.Request');
    CheckEquals(True, Request.IsGetRequest, 'Request.IsGetRequest');
    CheckEquals('http://fbox.ngrok.io/print/open_cash_drawer/', Request.URL, 'Request.URL');
  end;
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
  RequestJson: WideString;
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
  FptrCheck(Driver.PrintRecItem('Item 1', 100, 1000, 10, 100, '��'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_PERCENTAGE_DISCOUNT, '������ ��������', 1000, 4));

  FptrCheck(Driver.PrintRecItem('Item 2', 100, 1000, 1, 100, '��'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, '������ ��������', 10, 4));

  FptrCheck(Driver.PrintRecItem('Item 3', 100, 1000, 2, 100, '��'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, '������ ��������', 9, 4));
  FptrCheck(Driver.DirectIO2(DIO_WRITE_FS_STRING_TAG_OP, 1226, '048768768768'));

  FptrCheck(Driver.PrintRecMessage('Message 2'));
  FptrCheck(Driver.PrintRecItem('Item 4', 100, 1000, 3, 100, '��'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, '������ ��������', 8, 4));
  FptrCheck(Driver.DirectIO2(DIO_STLV_BEGIN, 1224, ''));
  FptrCheck(Driver.DirectIO2(DIO_STLV_ADD_TAG, 1226, '827364827346'));
  FptrCheck(Driver.DirectIO2(DIO_STLV_WRITE_OP, 0, ''));

  // ������ �� ���
  FptrCheck(Driver.PrintRecSubtotalAdjustment(FPTR_AT_AMOUNT_DISCOUNT, '������ �� ���', 10));

  FptrCheck(Driver.PrintRecMessage('Message 3'));
  FptrCheck(Driver.PrintRecTotal(390, 90, '0'));
  FptrCheck(Driver.PrintRecTotal(390, 100, '1'));
  FptrCheck(Driver.PrintRecTotal(390, 100, '2'));
  FptrCheck(Driver.PrintRecTotal(390, 100, '3'));
  FptrCheck(Driver.PrintRecMessage('Message 4'));

  CheckEquals(FPTR_PS_FISCAL_RECEIPT_ENDING, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  FptrCheck(Driver.EndFiscalReceipt(False));
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  RequestJson := Driver.Printer.RequestJson;
  CheckNotEquals('', RequestJson, 'RequestJson');
  //WriteFileData('OrderRequest3.json', RequestJson);
  Order := TWPOrder.Create;
  try
    JsonToObject(RequestJson, Order);

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
  FptrCheck(Driver.PrintRecItem('"Item 1"'#10#13, 100, 1000, 0, 100, '��'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_PERCENTAGE_DISCOUNT, '������ ��������', 1000, 4));

  FptrCheck(Driver.PrintRecItem('Item 2', 100, 1000, 1, 100, '��'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, '������ ��������', 10, 4));

  FptrCheck(Driver.PrintRecItem('Item 3', 100, 1000, 2, 100, '��'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, '������ ��������', 9, 4));

  FptrCheck(Driver.PrintRecItem('Item 4', 100, 1000, 3, 100, '��'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, '������ ��������', 8, 4));

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
  FptrCheck(Driver.PrintRecItemRefund('"Item 1"'#10#13, 100, 1000, 0, 100, '��'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_PERCENTAGE_DISCOUNT, '������ ��������', 1000, 4));

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
    CheckEquals('��', Item.Field['unit_name'].Value, 'unit_name');
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
  RequestJson: WideString;
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
  RequestJson := Driver.Printer.RequestJson;
  CheckEquals(Text, RequestJson, 'CashIn.json');

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

  CheckCashDrawerRequest(Driver.Printer.Requests[1]);
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
  CheckCashDrawerRequest(Driver.Printer.Requests[1]);
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
  Driver.Params.CashInAmount := 12345;

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
  CheckCashDrawerRequest(Driver.Printer.Requests[1]);
end;

procedure TWebPrinterImplTest.TestCashoutReceipt2;
begin
  OpenClaimEnable;
  Driver.Params.CashInAmount := 3.03;
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
  CheckCashDrawerRequest(Driver.Printer.Requests[1]);
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
  RequestJson: WideString;
begin
  OpenClaimEnable;

  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  CheckEquals(FPTR_RT_SALES, Driver.GetPropertyNumber(PIDXFptr_FiscalReceiptType));

  FptrCheck(Driver.BeginFiscalReceipt(True));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  FptrCheck(Driver.PrintRecItem('Item 1', 100, 1000, 10, 100, '��'));
  FptrCheck(Driver.PrintRecTotal(100, 100, '0'));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT_ENDING, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  FptrCheck(Driver.EndFiscalReceipt(False));
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  RequestJson := Driver.Printer.RequestJson;
  CheckNotEquals('', RequestJson, 'RequestJson');
  //WriteFileData('OrderRequest3.json', RequestJson);

  Order := TWPOrder.Create;
  try
    JsonToObject(RequestJson, Order);
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
begin
  FDriver.Params.CashInAmount := 3454.78;
  FDriver.Params.CashOutAmount := 234.32;

  FDriver.Params.SalesAmountCash := 1278.54;
  FDriver.Params.SalesAmountCard := 9123.45;
  FDriver.Params.RefundAmountCash := 8213.34;
  FDriver.Params.RefundAmountCard := 83.45;
  FDriver.DayResult.total_sale_cash := 12345;
  FDriver.DayResult.total_sale_card := 23456;
  FDriver.DayResult.total_refund_cash := 123;
  FDriver.DayResult.total_refund_card := 45678;

  //123.45-1.23+3454.78-234.32


  OpenClaimEnable;
  pString := '';
  FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, 241, pString));
  CheckEquals('334268', pString, 'DirectIO3(DIO_READ_CASH_REG, 241');

  pString := '';
  FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, 242, pString));
  CheckEquals('345478', pString, 'DirectIO3(DIO_READ_CASH_REG, 242');

  pString := '';
  FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, 243, pString));
  CheckEquals('23432', pString, 'DirectIO3(DIO_READ_CASH_REG, 243');

  pString := '';
  FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, SMFPTR_CASHREG_DAY_TOTAL_SALE_CASH, pString));
  CheckEquals('12345', pString, 'SMFPTR_CASHREG_DAY_TOTAL_SALE_CASH');

  pString := '';
  FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, SMFPTR_CASHREG_DAY_TOTAL_SALE_CARD, pString));
  CheckEquals('23456', pString, 'SMFPTR_CASHREG_DAY_TOTAL_SALE_CARD');

  pString := '';
  FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, SMFPTR_CASHREG_DAY_TOTAL_RETSALE_CASH, pString));
  CheckEquals('123', pString, 'SMFPTR_CASHREG_DAY_TOTAL_RETSALE_CASH');

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
  CheckEquals(IntToStr(821334 + 123), pString, 'SMFPTR_CASHREG_GRAND_TOTAL_RETSALE_CASH');

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

  CashAmount := Amount - CardAmount;
  FDriver.DayResult.total_sale_cash := FDriver.DayResult.total_sale_cash + Round(CashAmount * 100);
  FDriver.DayResult.total_sale_card := FDriver.DayResult.total_sale_card + Round(CardAmount * 100);
end;

procedure TWebPrinterImplTest.PrintRefundReceipt(Amount, CashAmount, CardAmount: Currency);
begin
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_REFUND);
  FptrCheck(Driver.BeginFiscalReceipt(True));
  FptrCheck(Driver.PrintRecItem('', Amount, 1000, 0, Amount, ''));
  FptrCheck(Driver.PrintRecTotal(Amount, CardAmount, '1'));
  FptrCheck(Driver.PrintRecTotal(Amount, CashAmount, '0'));
  FptrCheck(Driver.EndFiscalReceipt(False));

  CashAmount := Amount - CardAmount;
  FDriver.DayResult.total_refund_cash := FDriver.DayResult.total_refund_cash + Round(CashAmount * 100);
  FDriver.DayResult.total_refund_card := FDriver.DayResult.total_refund_card + Round(CardAmount * 100);
end;

procedure TWebPrinterImplTest.TestCashInECRTotalizer;

  function GetCashAmount: Currency;
  var
    pString: WideString;
  begin
    pString := '';
    FptrCheck(FDriver.DirectIO3(DIO_READ_CASH_REG, 241, pString));
    Result := StrToInt(pString)/100;
  end;

begin
  FDriver.Params.CashInAmount := 0;
  FDriver.Params.CashOutAmount := 0;
  SaveParameters(FDriver.Params, 'DeviceName', FDriver.Logger);

  OpenClaimEnable;
  PrintCashInReceipt(2123.45);
  CheckEquals(2123.45, GetCashAmount, 'CashInECRAmount');
  CheckEquals(2123.45, Driver.Params.CashInAmount, 'CashInAmount');

  PrintCashOutReceipt(123.45);
  CheckEquals(2123.45-123.45, GetCashAmount);
  CheckEquals(123.45, Driver.Params.CashOutAmount, 'CashOutAmount');

  PrintSalesReceipt(7623.45, 8000, 1000);
  CheckEquals(2123.45-123.45 + 6623.45, GetCashAmount);

  PrintRefundReceipt(93.56, 100, 50);
  CheckEquals(2123.45-123.45 + 6623.45-43.56, GetCashAmount);

  Driver.Close;

  OpenClaimEnable;
  PrintCashInReceipt(768.45);
  CheckEquals(2123.45 + 768.45, Driver.Params.CashInAmount, 'CashInAmount');
  CheckEquals(2123.45-123.45 + 6623.45-43.56 + 768.45, GetCashAmount);
end;

procedure TWebPrinterImplTest.TestTotalizers2;
begin
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

  FDriver.Printer.CloseDayResponse.error.code := 0;
  FDriver.Printer.CloseDayResponse.is_success := True;
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
  RequestJson: WideString;
begin
  OpenClaimEnable;
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  FptrCheck(Driver.BeginFiscalReceipt(True));

  FptrCheck(Driver.PrintRecItem('Item 1', 100, 1000, 10, 100, '��'));
  FptrCheck(Driver.DirectIO2(DIO_SET_RECITEM_JSON_FIELD, 0, 'package_code;0'));
  FptrCheck(Driver.DirectIO2(DIO_SET_RECITEM_JSON_FIELD, 0, 'package_code;1'));

  FptrCheck(Driver.PrintRecItem('Item 2', 100, 1000, 1, 100, '��'));
  FptrCheck(Driver.DirectIO2(DIO_SET_RECITEM_JSON_FIELD, 0, 'package_code;1493082'));

  FptrCheck(Driver.PrintRecTotal(200, 200, '0'));
  FptrCheck(Driver.EndFiscalReceipt(False));


  RequestJson := Driver.Printer.RequestJson;
  CheckNotEquals('', RequestJson, 'RequestJson');
  //WriteFileData('OrderRequest4.json', RequestJson);

  Order := TWPOrder.Create;
  try
    JsonToObject(RequestJson, Order);
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
  RequestJson: WideString;
begin
  Driver.Params.RecDiscountOnClassCode := True;
  Driver.Params.ClassCodes.Add('04811001001000000');

  OpenClaimEnable;
  Driver.SetPOSID('POS1', 'Cahier 1');
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  FptrCheck(Driver.BeginFiscalReceipt(True));

  FptrCheck(Driver.PrintRecItem('Item 1', 100, 1000, 10, 100, '��'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000001'));
  FptrCheck(Driver.PrintRecItem('Item 2', 100, 1000, 10, 100, '��'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000002'));
  FptrCheck(Driver.PrintRecItem('Item 3', 100, 1000, 10, 100, '��'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));

  // ������ �� ���
  FptrCheck(Driver.PrintRecSubtotalAdjustment(FPTR_AT_AMOUNT_DISCOUNT, '������ �� ���', 10));
  FptrCheck(Driver.PrintRecTotal(290, 290, '0'));
  FptrCheck(Driver.EndFiscalReceipt(False));


  RequestJson := Driver.Printer.RequestJson;
  CheckNotEquals('', RequestJson, 'RequestJson');
  //WriteFileData('OrderRequest5.json', RequestJson);

  Order := TWPOrder.Create;
  try
    JsonToObject(RequestJson, Order);

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
  RequestJson: WideString;
begin
  OpenClaimEnable;
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  CheckEquals(FPTR_RT_SALES, Driver.GetPropertyNumber(PIDXFptr_FiscalReceiptType));

  FptrCheck(Driver.BeginFiscalReceipt(True));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_PACKAGE_CODE, 92, ''));
  FptrCheck(Driver.PrintRecItem('Item 1', 0, 1000, 10, 0, '��'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));


  FptrCheck(Driver.PrintRecTotal(0, 0, '0'));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT_ENDING, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  FptrCheck(Driver.EndFiscalReceipt(False));
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  RequestJson := Driver.Printer.RequestJson;
  CheckNotEquals('', RequestJson, 'RequestJson');
  //WriteFileData('ZeroReceiptOrderRequest.json', RequestJson);

  Order := TWPOrder.Create;
  try
    JsonToObject(RequestJson, Order);
    CheckEquals(1, Order.products.Count, 'Order.products.Count');
    CheckEquals('Item 1', Order.products[0].name, 'Order.products[0].name');
    CheckEquals(0, Order.products[0].price, 'Order.products[0].price');
    CheckEquals(0, Order.products[0].discount, 'Order.products[0].discount');

    CheckEquals('', Order.products[0].barcode, 'Order.products[0].barcode');
    CheckEquals(1000, Order.products[0].amount, 'Order.products[0].amount');
    CheckEquals(1, Order.products[0].units, 'Order.products[0].units'); // WP_UNIT_PEACE
    CheckEquals('', Order.products[0].unit_name, 'Order.products[0].unit_name');
    CheckEquals(0, Order.products[0].product_price, 'Order.products[0].product_price');
    CheckEquals(0, Order.products[0].vat, 'Order.products[0].vat');
    CheckEquals(15, Order.products[0].vat_percent, 'Order.products[0].vat_percent');
    CheckEquals(0, Order.products[0].discount_percent, 'Order.products[0].discount_percent');
    CheckEquals(0, Order.products[0].other, 'Order.products[0].other');
    CheckEquals(0, Order.products[0].labels.Count, 'Order.products[0].labels.Count');
    CheckEquals('04811001001000000', Order.products[0].class_code, 'Order.products[0].class_code');
    CheckEquals(92, Order.products[0].package_code, 'Order.products[0].package_code');
    CheckEquals(0, Order.products[0].owner_type, 'Order.products[0].owner_type');
    CheckEquals('', Order.products[0].comission_info.inn, 'Order.products[0].comission_info.inn');
    CheckEquals('', Order.products[0].comission_info.pinfl, 'Order.products[0].comission_info.pinfl');
  finally
    Order.Free;
  end;
end;

procedure TWebPrinterImplTest.TestZeroFiscalReceipt2;
var
  Order: TWPOrder;
  RequestJson: WideString;
begin
  OpenClaimEnable;
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  CheckEquals(FPTR_RT_SALES, Driver.GetPropertyNumber(PIDXFptr_FiscalReceiptType));
  Driver.SetPropertyNumber(PIDXFptr_CheckTotal, 1);
  CheckEquals(1, Driver.GetPropertyNumber(PIDXFptr_CheckTotal));

  FptrCheck(Driver.BeginFiscalReceipt(True));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  FptrCheck(Driver.PrintRecItem('Item 1', 10, 1000, 10, 10, '��'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, '������ �� ������� 1', 1, 4));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, '������ �� ������� 2', 4, 4));
  FptrCheck(Driver.PrintRecSubtotalAdjustment(FPTR_AT_AMOUNT_DISCOUNT, '������ �� ��� 1', 1));
  FptrCheck(Driver.PrintRecSubtotalAdjustment(FPTR_AT_AMOUNT_DISCOUNT, '������ �� ��� 2', 4));
  FptrCheck(Driver.PrintRecTotal(0, 0, '0'));
  CheckEquals(FPTR_PS_FISCAL_RECEIPT_ENDING, Driver.GetPropertyNumber(PIDXFptr_PrinterState));
  FptrCheck(Driver.EndFiscalReceipt(False));
  CheckEquals(FPTR_PS_MONITOR, Driver.GetPropertyNumber(PIDXFptr_PrinterState));

  RequestJson := Driver.Printer.RequestJson;
  CheckNotEquals('', RequestJson, 'RequestJson');
  //WriteFileData('ZeroReceiptOrderRequest2.json', RequestJson);

  Order := TWPOrder.Create;
  try
    JsonToObject(RequestJson, Order);
    CheckEquals(1, Order.products.Count, 'Order.products.Count');
    CheckEquals('Item 1', Order.products[0].name, 'Order.products[0].name');
    CheckEquals(1000, Order.products[0].Price, 'Order.products[0].Price');
    CheckEquals(1000, Order.products[0].Discount, 'Order.products[0].Discount');
    CheckEquals(0, Order.products[0].vat, 'Order.products[0].vat');
    CheckEquals(15, Order.products[0].vat_percent, 'Order.products[0].vat_percent');
  finally
    Order.Free;
  end;
end;

procedure TWebPrinterImplTest.TestItemPercentDiscount;
var
  Order: TWPOrder;
  RequestJson: WideString;
begin
  OpenClaimEnable;
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  FptrCheck(Driver.BeginFiscalReceipt(True));
  FptrCheck(Driver.PrintRecItem('Item 1', 100, 1000, 10, 100, '��'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_PERCENTAGE_DISCOUNT, '������ ��������', 1000, 4));
  FptrCheck(Driver.PrintRecTotal(90, 90, '0'));
  FptrCheck(Driver.EndFiscalReceipt(False));

  RequestJson := Driver.Printer.RequestJson;
  CheckNotEquals('', RequestJson, 'RequestJson');
  //WriteFileData('TestPercentDiscount.json', RequestJson);

  Order := TWPOrder.Create;
  try
    JsonToObject(RequestJson, Order);
    CheckEquals(1, Order.products.Count, 'Order.products.Count');
    CheckEquals('Item 1', Order.products[0].name, 'Order.products[0].name');
    CheckEquals(10000, Order.products[0].Price, 'Order.products[0].Price');
    CheckEquals(1000, Order.products[0].discount, 'Order.products[0].discount');
    CheckEquals(10, Order.products[0].discount_percent, 'Order.products[0].discount_percent');
  finally
    Order.Free;
  end;
end;

procedure TWebPrinterImplTest.TestItemAmountDiscount;
var
  Order: TWPOrder;
  RequestJson: WideString;
begin
  OpenClaimEnable;
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  FptrCheck(Driver.BeginFiscalReceipt(True));
  FptrCheck(Driver.PrintRecItem('Item 1', 289.49, 2345, 10, 123.45, '��'));
  FptrCheck(Driver.DirectIO2(DIO_SET_ITEM_CLASS_CODE, 0, '04811001001000000'));
  FptrCheck(Driver.PrintRecItemAdjustment(FPTR_AT_AMOUNT_DISCOUNT, '������ ��������', 0.34, 4));
  FptrCheck(Driver.PrintRecTotal(277.15, 300, '0'));
  FptrCheck(Driver.EndFiscalReceipt(False));

  RequestJson := Driver.Printer.RequestJson;
  CheckNotEquals('', RequestJson, 'RequestJson');
  //WriteFileData('TestPercentDiscount.json', RequestJson);

  Order := TWPOrder.Create;
  try
    JsonToObject(RequestJson, Order);
    CheckEquals(1, Order.products.Count, 'Order.products.Count');
    CheckEquals('Item 1', Order.products[0].name, 'Order.products[0].name');
    CheckEquals(28949, Order.products[0].Price, 'Order.products[0].Price');
    CheckEquals(34, Order.products[0].discount, 'Order.products[0].discount');
    CheckEquals(1, Order.products[0].discount_percent, 'Order.products[0].discount_percent');
  finally
    Order.Free;
  end;
end;

procedure TWebPrinterImplTest.TestErrorOnCreateOrder;
begin
  OpenClaimEnable;
  Driver.Printer.DayOpened := True;
  // Sale count not changed
  FptrCheck(Driver.ResetPrinter);
  Driver.Printer.TestMode := True;
  Driver.Printer.TestReadZReport := True;
  Driver.Printer.ResponseJson := ReadFileData('infoError.json');
  Driver.DayResult.total_refund_count := 0;
  Driver.DayResult.total_sale_count := 0;
  Driver.Printer.CloseDayResponse2.result.data.total_refund_count := 0;
  Driver.Printer.CloseDayResponse2.result.data.total_sale_count := 0;
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  FptrCheck(Driver.BeginFiscalReceipt(True));
  FptrCheck(Driver.PrintRecItem('Item 1', 100, 1000, 10, 100, '��'));
  FptrCheck(Driver.PrintRecTotal(100, 100, '0'));
  CheckEquals(OPOS_E_EXTENDED, Driver.EndFiscalReceipt(False), 'EndFiscalReceipt');
  CheckEquals(OPOS_E_EXTENDED, Driver.GetPropertyNumber(PIDX_ResultCode), 'ResultCode');
  CheckEquals(102, Driver.GetPropertyNumber(PIDX_ResultCodeExtended), 'ResultCodeExtended');
  CheckEquals('FISCAL_MODULE_NOT_INITIALIZED', Driver.GetPropertyString(PIDXFptr_ErrorString), 'ErrorString');
  // Sale not changed
  FptrCheck(Driver.ResetPrinter);
  Driver.Printer.TestMode := True;
  Driver.Printer.TestReadZReport := True;
  Driver.Printer.ResponseJson := ReadFileData('infoError.json');
  Driver.DayResult.total_refund_count := 0;
  Driver.DayResult.total_sale_count := 0;
  Driver.Printer.CloseDayResponse2.result.data.total_refund_count := 0;
  Driver.Printer.CloseDayResponse2.result.data.total_sale_count := 1;
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  FptrCheck(Driver.BeginFiscalReceipt(True));
  FptrCheck(Driver.PrintRecItem('Item 1', 100, 1000, 10, 100, '��'));
  FptrCheck(Driver.PrintRecTotal(100, 100, '0'));
  FptrCheck(Driver.EndFiscalReceipt(False));
end;

procedure TWebPrinterImplTest.TestMarkCode;
var
  Code: AnsiString;
const
  GS = #$1D;
begin
  // �������� (�����)
  // 00000123456789aaaaaa!ABm8wAYa
  // 00000123456789aaaaaa!
  // ���� �����-��� ������ 14 ������, �� �� ������ ����������� ����� ������ �� 14 ������
  Code := GetMarkCode('123456789');
  CheckEquals('00000123456789', Code, 'Code.1');
  // ��� ������ � �������� ����� (�� ���� ������ 21 ����)
  Code := GetMarkCode('00000123456789aaaaaa!ABm8wAYa');
  CheckEquals('00000123456789aaaaaa!', Code, 'Code.2');

  // �������� (����)
  // 010478006206026121Wia,=,93/SukmJI=24012345678
  // 010478006206026121Wia,=,
  Code := GetMarkCode('010478006206026121W-ia,=,93/SukmJI=24012345678');
  CheckEquals('010478006206026121W-ia,=,', Code, 'Code.3');

  // �������� (�������)
  // 010478006206026121123456793ABCD
  // 0104780062060261211234567
  Code := GetMarkCode('010478006206026121123456793ABCD');
  CheckEquals('0104780062060261211234567', Code, 'Code.4');

  // �������� (��������)
  // 010478006206026121123456789012393ABCD
  // 0104780062060261211234567890123
  Code := GetMarkCode('010478006206026121123456789012393ABCD');
  CheckEquals('0104780062060261211234567890123', Code, 'Code.5');

  // ���� (�������)
  // 010478006206026121123456793ABCD
  // 0104780062060261211234567

  // ��������� (��������)
  // 0105995327112039213GmniXS9lFo4X91EE0592nrV20ZwdydM+Atwcuuisf9Gnindaat3wF81ul7vBwCc=
  // 0105995327112039213GmniXS9lFo4X
  Code := GetMarkCode('0105995327112039213GmniXS9lFo4X91EE0592nrV20ZwdydM+Atwcuuisf9Gnindaat3wF81ul7vBwCc=');
  CheckEquals('0105995327112039213GmniXS9lFo4X', Code, 'Code.6');

  // �������� �������� �������������
  // 011478001424119621054969682170003324014787184
  // (01)14780014241196(21)0549696821700033(240)14787184
  Code := GetMarkCode('011478001424119621054969682170003324014787184');
  CheckEquals('011478001424119621054969682170003324014787184', Code, 'Code.7');

  // �������� �������� �������������
  // 011478001424094620001121011210CV29115528
  Code := GetMarkCode('011478001424094620001121011210CV29115528');
  CheckEquals('011478001424094620001121011210CV29115528', Code, 'Code.8');

  // ������� ������� (��������������� ��������)
  // 0107623900780341215cpa-CeayEU>BYWdxwd_91UZF092TkllMKppAZkpmTEitV717ei4m2GQpeeAfB0EaMPT5V0=
  // 0107623900780341215cpa-CeayEU>BYWdxwd_
  Code := GetMarkCode('0107623900780341215cpa-CeayEU>BYWdxwd_'#$1D'91UZF0'#$1D'92TkllMKppAZkpmTEitV717ei4m2GQpeeAfB0EaMPT5V0=');
  CheckEquals('0107623900780341215cpa-CeayEU>BYWdxwd_', Code, 'Code.9');

  // ������� ������� (��������������� ��������)
  // 010762390078034121NMroq+kni<L1nYlUa+jn'#$1D'91UZF0'#$1D'92LzZidsXkECfv+vdd6RaABCq/mM3+CrS3sCF1hWkCJJg=
  // 010762390078034121NMroq+kni<L1nYlUa+jn
  Code := GetMarkCode('010762390078034121NMroq+kni<L1nYlUa+jn'#$1D'91UZF0'#$1D'92LzZidsXkECfv+vdd6RaABCq/mM3+CrS3sCF1hWkCJJg=');
  CheckEquals('010762390078034121NMroq+kni<L1nYlUa+jn', Code, 'Code.10');

  // ���� � ��������������� ������� (��������������� ��������)
  // 010762390040598521E?Mfrf7Asahnh'#$1D'93d0Q1
  // 010762390040598521E?Mfrf7Asahnh
  Code := GetMarkCode('010762390040598521E?Mfrf7Asahnh'#$1D'93d0Q1');
  CheckEquals('010762390040598521E?Mfrf7Asahnh', Code, 'Code.11');

  // 00000047801110tuO-i/5bzhYb2ti
  // 00000047801110tuO-i/5
  Code := GetMarkCode('00000047801110tuO-i/5bzhYb2ti');
  CheckEquals('00000047801110tuO-i/5', Code, 'Code.12');
end;


procedure TWebPrinterImplTest.TestValidMarkCode;
begin
  CheckEquals(True, ValidMarkCode('123456789'));
  CheckEquals(True, ValidMarkCode('00000123456789aaaaaa!ABm8wAYa'));
  CheckEquals(True, ValidMarkCode('010478006206026121W-ia,=,93/SukmJI=24012345678'));
  CheckEquals(True, ValidMarkCode('010478006206026121123456793ABCD'));
  CheckEquals(True, ValidMarkCode('010478006206026121123456789012393ABCD'));
  CheckEquals(True, ValidMarkCode('0105995327112039213GmniXS9lFo4X91EE0592nrV20ZwdydM+Atwcuuisf9Gnindaat3wF81ul7vBwCc='));
  CheckEquals(True, ValidMarkCode('011478001424119621054969682170003324014787184'));
  CheckEquals(True, ValidMarkCode('011478001424094620001121011210CV29115528'));
  CheckEquals(True, ValidMarkCode('0107623900780341215cpa-CeayEU>BYWdxwd_'#$1D'91UZF0'#$1D'92TkllMKppAZkpmTEitV717ei4m2GQpeeAfB0EaMPT5V0='));
  CheckEquals(True, ValidMarkCode('010762390078034121NMroq+kni<L1nYlUa+jn'#$1D'91UZF0'#$1D'92LzZidsXkECfv+vdd6RaABCq/mM3+CrS3sCF1hWkCJJg='));
  CheckEquals(True, ValidMarkCode('010762390040598521E?Mfrf7Asahnh'#$1D'93d0Q1'));
  CheckEquals(True, ValidMarkCode('00000047801110tuO-i/5bzhYb2ti'));
  CheckEquals(False, ValidMarkCode('https://ofd.soliq.uz/check?t=VG343420028483&r=109550&c=20240927141756&s=500713954471'));
end;

procedure TWebPrinterImplTest.TestCheckMarkCode;
const
  ValidBarcode = '010478006206026121W-ia,=,93/SukmJI=24012345678';
  InvalidBarcode = 'https://ofd.soliq.uz/check?t=VG343420028483&r=109550&c=20240927141756&s=500713954471';
var
  ErrorString: WideString;
begin
  OpenClaimEnable;

  FptrCheck(Driver.ResetPrinter);
  Driver.SetPropertyNumber(PIDXFptr_FiscalReceiptType, FPTR_RT_SALES);
  FptrCheck(Driver.BeginFiscalReceipt(True));
  // Valid barcode
  FptrCheck(Driver.DirectIO2(30, 80, ValidBarcode));
  // Invalid barcode
  CheckEquals(OPOS_E_ILLEGAL, Driver.DirectIO2(30, 80, InvalidBarcode), 'Driver.DirectIO2');
  ErrorString := Driver.GetPropertyString(PIDXFptr_ErrorString);
  CheckEquals('Invalid markcode, ' + InvalidBarcode, ErrorString, 'ErrorString');
end;

initialization
  RegisterTest('', TWebPrinterImplTest.Suite);

end.

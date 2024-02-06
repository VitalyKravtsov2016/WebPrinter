unit duWebPrinter;

interface

uses
  // VCL
  Windows, SysUtils, Classes, IniFiles,
  // DUnit
  TestFramework,
  // This
  LogFile, FileUtils, WebPrinter, DriverError, JsonUtils;

type
  { TWebPrinterTest }

  TWebPrinterTest = class(TTestCase)
  private
    FLogger: ILogFile;
    FPrinter: TWebPrinter;
    procedure CreateOrder(Request: TWPOrder);
  protected
    procedure Setup; override;
    procedure TearDown; override;
    
    procedure CheckCreateOrder;
    procedure CheckReturnOrder;
  published
    procedure CheckInfoCommand;
    procedure CheckInfoCommand2;
    procedure CheckOpenFiscalDay;
    procedure CheckOpenFiscalDayError;
    procedure CheckCloseFiscalDay;
    procedure CheckCloseFiscalDayError;
    procedure CheckWPDateTimeToStr;
    procedure CheckPrintZReport;
    procedure CheckPrintZReportError;
    procedure CheckReadZReport;
    procedure CheckReadZReportError;
    procedure CheckOpenCashDrawer;
    procedure CheckOpenCashDrawerError;
    procedure CheckPrintLastReceipt;
    procedure CheckPrintLastReceiptError;
  end;

implementation


{ TWebPrinterTest }

procedure TWebPrinterTest.Setup;
begin
  FLogger := TLogFile.Create;
  FPrinter := TWebPrinter.Create(FLogger);
  FPrinter.RaiseErrors := False;
end;

procedure TWebPrinterTest.TearDown;
begin
  FPrinter.Free;
  FLogger := nil;
end;

procedure TWebPrinterTest.CheckInfoCommand;
var
  Data: TWPInfoResponse;
begin
  FPrinter.TestMode := True;
  FPrinter.ResponseJson := ReadFileData('infoResponse.json');
  Data := FPrinter.ReadInfo2.Data;

  CheckEquals(Data.terminal_id, 'UZ170703100189', 'terminal_id');
  CheckEquals(Data.applet_version, '0300', 'applet_version');
  CheckEquals(Data.current_receipt_seq, '836', 'current_receipt_seq');
  CheckEquals(Data.current_time, '2020-05-28 22:27:15', 'current_time');
  CheckEquals(Data.last_operation_time, '2021-09-08 19:32:39', 'last_operation_time');
  CheckEquals(Data.receipt_count, 0, 'receipt_count');
  CheckEquals(Data.receipt_max_count, 858, 'receipt_max_count');
  CheckEquals(Data.zreport_count, 38, 'zreport_count');
  CheckEquals(Data.zreport_max_count, 832, 'zreport_max_count');
  CheckEquals(Data.available_persistent_memory, 6100, 'available_persistent_memory');
  CheckEquals(Data.available_reset_memory, 1440, 'available_reset_memory');
  CheckEquals(Data.available_deselect_memory, 1440, 'available_deselect_memory');
  CheckEquals(Data.cashbox_number, 1, 'cashbox_number');
  CheckEquals(Data.is_updated, false, 'is_updated');

  FPrinter.RaiseErrors := True;
  FPrinter.ResponseJson := ReadFileData('infoError.json');
  try
    FPrinter.ReadInfo2;
    Fail('No Exception');
  except
    on E: EDriverError do
    begin
      CheckEquals(102, E.ErrorCode, 'ErrorCode');
      CheckEquals('FISCAL_MODULE_NOT_INITIALIZED', E.Message, 'Message');
    end;
  end;
end;

procedure TWebPrinterTest.CheckInfoCommand2;
var
  Data: TWPInfoResponse;
begin
  FPrinter.TestMode := True;
  FPrinter.ResponseJson := ReadFileData('infoResponse2.json');
  Data := FPrinter.ReadInfo2.Data;

  CheckEquals(Data.terminal_id, 'UZ191211501050', 'terminal_id');
  CheckEquals(Data.applet_version, '0302', 'applet_version');
  CheckEquals(Data.current_receipt_seq, '281', 'current_receipt_seq');
  CheckEquals(Data.current_time, '2024-02-05 14:34:33', 'current_time');
  CheckEquals(Data.last_operation_time, '2023-08-04 10:21:52', 'last_operation_time');
  CheckEquals(Data.receipt_count, 0, 'receipt_count');
  CheckEquals(Data.receipt_max_count, 858, 'receipt_max_count');
  CheckEquals(Data.zreport_count, 32, 'zreport_count');
  CheckEquals(Data.zreport_max_count, 832, 'zreport_max_count');
  CheckEquals(Data.available_persistent_memory, 32767, 'available_persistent_memory');
  CheckEquals(Data.available_reset_memory, 8918, 'available_reset_memory');
  CheckEquals(Data.available_deselect_memory, 8918, 'available_deselect_memory');
  CheckEquals(Data.cashbox_number, 0, 'cashbox_number');
  CheckEquals(Data.version_code, '1.15.24', 'version_code');
  CheckEquals(Data.is_updated, false, 'is_updated');
end;

procedure TWebPrinterTest.CheckOpenFiscalDay;
var
  Response: TWPOpenDayResponse;
begin
  FPrinter.TestMode := True;
  FPrinter.ResponseJson := ReadFileData('OpenFiscalDay.json');
  CheckEquals(FPrinter.ResponseJson, FPrinter.OpenFiscalDay(Now), 'OpenFiscalDay');
  Response := FPrinter.OpenFiscalDay2(Now);
  CheckEquals(True, Response.is_success, 'is_success');
  CheckEquals('2020-04-24 13:01:02', Response.data.time, 'data.time');
  CheckEquals('0300', Response.data.applet_version, 'data.applet_version');
end;

procedure TWebPrinterTest.CheckOpenFiscalDayError;
var
  Response: TWPOpenDayResponse;
begin
  FPrinter.TestMode := True;
  FPrinter.ResponseJson := ReadFileData('OpenFiscalDayError.json');
  CheckEquals(FPrinter.ResponseJson, FPrinter.OpenFiscalDay(Now), 'OpenFiscalDay');
  Response := FPrinter.OpenFiscalDay2(Now);
  CheckEquals(False, Response.is_success, 'is_success');
  CheckEquals(9327, Response.error.code, 'error.code');
  CheckEquals('ZREPORT_ALREADY_OPEN', Response.error.message, 'error.message');
end;

procedure TWebPrinterTest.CheckCloseFiscalDay;
var
  Response: TWPCloseDayResponse;
begin
  FPrinter.TestMode := True;
  FPrinter.ResponseJson := ReadFileData('CloseFiscalDay.json');
  CheckEquals(FPrinter.ResponseJson, FPrinter.CloseFiscalDay(Now), 'CloseFiscalDay');
  Response := FPrinter.CloseFiscalDay2(Now);
  CheckEquals(True, Response.is_success, 'is_success');
  CheckEquals('0300', Response.data.applet_version, 'data.applet_version');
  CheckEquals('UZ170703100597', Response.data.terminal_id, 'data.terminal_id');
  CheckEquals(3, Response.data.number, 'data.number');
  CheckEquals(20, Response.data.count, 'data.count');
  CheckEquals(20, Response.data.last_receipt_seq, 'data.last_receipt_seq');
  CheckEquals(18, Response.data.first_receipt_seq, 'data.first_receipt_seq');
  CheckEquals('2019-10-07 17:07:52', Response.data.open_time, 'data.open_time');
  CheckEquals('2019-10-09 19:16:15', Response.data.close_time, 'data.close_time');
  CheckEquals(1234, Response.data.total_refund_vat, 'data.total_refund_vat');
  CheckEquals(123, Response.data.total_refund_card, 'data.total_refund_card');
  CheckEquals(2343, Response.data.total_refund_cash, 'data.total_refund_cash');
  CheckEquals(4564, Response.data.total_refund_count, 'data.total_refund_count');
  CheckEquals(195342, Response.data.total_sale_vat, 'data.total_sale_vat');
  CheckEquals(1231, Response.data.total_sale_card, 'data.total_sale_card');
  CheckEquals(195000, Response.data.total_sale_cash, 'data.total_sale_cash');
  CheckEquals(3, Response.data.total_sale_count, 'data.total_sale_count');
end;

procedure TWebPrinterTest.CheckCloseFiscalDayError;
var
  Response: TWPCloseDayResponse;
begin
  FPrinter.TestMode := True;
  FPrinter.ResponseJson := ReadFileData('CloseFiscalDayError.json');
  CheckEquals(FPrinter.ResponseJson, FPrinter.CloseFiscalDay(Now), 'CloseFiscalDay');
  Response := FPrinter.CloseFiscalDay2(Now);
  CheckEquals(False, Response.is_success, 'is_success');
  CheckEquals(9326, Response.error.code, 'error.code');
  CheckEquals('ZREPORT_ALREADY_CLOSE', Response.error.message, 'error.message');
end;

procedure TWebPrinterTest.CheckWPDateTimeToStr;
var
  Time: TDateTime;
begin
  Time := EncodeDate(2023, 12, 28) + EncodeTime(1, 2, 3, 4);
  CheckEquals('2023-12-28 01:02:03', WPDateTimeToStr(Time));
end;

procedure TWebPrinterTest.CheckPrintZReport;
var
  Request: TWPCloseDayRequest;
  Response: TWPCloseDayResponse;
begin
  Request := TWPCloseDayRequest.Create;
  try
    FPrinter.TestMode := True;
    FPrinter.ResponseJson := ReadFileData('CloseFiscalDay.json');
    Response := FPrinter.PrintZReport(Request);
    CheckEquals(True, Response.is_success, 'is_success');
    CheckEquals('0300', Response.data.applet_version, 'data.applet_version');
    CheckEquals('UZ170703100597', Response.data.terminal_id, 'data.terminal_id');
    CheckEquals(3, Response.data.number, 'data.number');
    CheckEquals(20, Response.data.count, 'data.count');
    CheckEquals(20, Response.data.last_receipt_seq, 'data.last_receipt_seq');
    CheckEquals(18, Response.data.first_receipt_seq, 'data.first_receipt_seq');
    CheckEquals('2019-10-07 17:07:52', Response.data.open_time, 'data.open_time');
    CheckEquals('2019-10-09 19:16:15', Response.data.close_time, 'data.close_time');
    CheckEquals(1234, Response.data.total_refund_vat, 'data.total_refund_vat');
    CheckEquals(123, Response.data.total_refund_card, 'data.total_refund_card');
    CheckEquals(2343, Response.data.total_refund_cash, 'data.total_refund_cash');
    CheckEquals(4564, Response.data.total_refund_count, 'data.total_refund_count');
    CheckEquals(195342, Response.data.total_sale_vat, 'data.total_sale_vat');
    CheckEquals(1231, Response.data.total_sale_card, 'data.total_sale_card');
    CheckEquals(195000, Response.data.total_sale_cash, 'data.total_sale_cash');
    CheckEquals(3, Response.data.total_sale_count, 'data.total_sale_count');
  finally
    Request.Free;
  end;
end;

procedure TWebPrinterTest.CheckPrintZReportError;
var
  Request: TWPCloseDayRequest;
  Response: TWPCloseDayResponse;
begin
  Request := TWPCloseDayRequest.Create;
  try
    FPrinter.TestMode := True;
    FPrinter.ResponseJson := ReadFileData('CloseFiscalDayError.json');
    Response := FPrinter.PrintZReport(Request);
    CheckEquals(False, Response.is_success, 'is_success');
    CheckEquals(9326, Response.error.code, 'error.code');
    CheckEquals('ZREPORT_ALREADY_CLOSE', Response.error.message, 'error.message');
  finally
    Request.Free;
  end;
end;

procedure TWebPrinterTest.CheckReadZReport;
var
  Response: TWPCloseDayResponse;
begin
  FPrinter.TestMode := True;
  FPrinter.ResponseJson := ReadFileData('CloseFiscalDay.json');
  Response := FPrinter.ReadZReport.Result;
  CheckEquals(True, Response.is_success, 'is_success');
  CheckEquals('0300', Response.data.applet_version, 'data.applet_version');
  CheckEquals('UZ170703100597', Response.data.terminal_id, 'data.terminal_id');
  CheckEquals(3, Response.data.number, 'data.number');
  CheckEquals(20, Response.data.count, 'data.count');
  CheckEquals(20, Response.data.last_receipt_seq, 'data.last_receipt_seq');
  CheckEquals(18, Response.data.first_receipt_seq, 'data.first_receipt_seq');
  CheckEquals('2019-10-07 17:07:52', Response.data.open_time, 'data.open_time');
  CheckEquals('2019-10-09 19:16:15', Response.data.close_time, 'data.close_time');
  CheckEquals(1234, Response.data.total_refund_vat, 'data.total_refund_vat');
  CheckEquals(123, Response.data.total_refund_card, 'data.total_refund_card');
  CheckEquals(2343, Response.data.total_refund_cash, 'data.total_refund_cash');
  CheckEquals(4564, Response.data.total_refund_count, 'data.total_refund_count');
  CheckEquals(195342, Response.data.total_sale_vat, 'data.total_sale_vat');
  CheckEquals(1231, Response.data.total_sale_card, 'data.total_sale_card');
  CheckEquals(195000, Response.data.total_sale_cash, 'data.total_sale_cash');
  CheckEquals(3, Response.data.total_sale_count, 'data.total_sale_count');
end;

procedure TWebPrinterTest.CheckReadZReportError;
var
  Response: TWPCloseDayResponse;
begin
  FPrinter.TestMode := True;
  FPrinter.ResponseJson := ReadFileData('CloseFiscalDayError.json');
  Response := FPrinter.ReadZReport.Result;
  CheckEquals(False, Response.is_success, 'is_success');
  CheckEquals(9326, Response.error.code, 'error.code');
  CheckEquals('ZREPORT_ALREADY_CLOSE', Response.error.message, 'error.message');
end;

procedure TWebPrinterTest.CheckOpenCashDrawer;
var
  Response: TWPResponse;
begin
  FPrinter.TestMode := True;
  FPrinter.ResponseJson := ReadFileData('OpenCashDrawer.json');
  Response := FPrinter.OpenCashDrawer;
  CheckEquals(True, Response.is_success, 'is_success');
  CheckEquals(0, Response.error.code, 'error.code');
  CheckEquals('', Response.error.message, 'error.message');
end;

procedure TWebPrinterTest.CheckOpenCashDrawerError;
var
  Response: TWPResponse;
begin
  FPrinter.TestMode := True;
  FPrinter.ResponseJson := ReadFileData('OpenCashDrawerError.json');
  Response := FPrinter.OpenCashDrawer;
  CheckEquals(False, Response.is_success, 'is_success');
  CheckEquals(9326, Response.error.code, 'error.code');
  CheckEquals('DRAWER_ALREADY_OPENED', Response.error.message, 'error.message');
end;

procedure TWebPrinterTest.CreateOrder(Request: TWPOrder);
var
  Price: TWPPrice;
  Banner: TWPBanner;
  Product: TWPProduct;
begin
  Request.number := 1;
  Request.receipt_type := 'order';
  Product := Request.products.Add as TWPProduct;
  Product.name := 'наименование товара или услуги';
  Product.barcode := '4780000000007';
  Product.amount := 1000;
  Product.units := 1;
  Product.price := 50000;
  Product.product_price := 50000;
  Product.vat := 6000;
  Product.vat_percent := 12;
  Product.discount := 0;
  Product.discount_percent := 0;
  Product.other := 0;
  //Product.labels.Add('05367567230048c?eN1(o0029');
  Product.class_code := '04811001001000000';
  Product.package_code := 1431970;
  Product.owner_type := 1;
  Product.comission_info.inn := '123456789';
  Product.comission_info.pinfl := '12345678912345';
  Request.time := '2021-04-07 12:52:02';
  Request.cashier := 'Admin';
  Request.received_cash := 50000;
  Request.change := 0;
  Request.received_card := 0;
  Request.open_cashbox := true;
  Request.send_email := True;
  Request.email := 'ullo21113@gmail.com';
  Request.sms_phone_number := '+998909999999';
  // Banner 1
  Banner := Request.banners.Add as TWPBanner;
  Banner._type := 'text';
  Banner.data := 'Код скидки для следующий покупки ';
  // Banner 2
  Banner := Request.banners.Add as TWPBanner;
  Banner._type := 'barcode';
  Banner.data := '23423423';
  // Price
  Price := Request.prices.Add as TWPPrice;
  Price.name := 'PayMe';
  Price.price := 100000;
  Price.vat_type := 'QQS';
  Price.vat_price := 200000;
end;

procedure TWebPrinterTest.CheckCreateOrder;
var
  Request: TWPOrder;
  RequestJson: WideString;
  Response: TWPCreateOrderResponse;
begin
  Request := TWPOrder.Create;
  try
    CreateOrder(Request);
    WriteFileData('OrderRequest2.json', ObjectToJson(Request));

    FPrinter.TestMode := True;
    RequestJson := ReadFileData('OrderRequest.json');
    FPrinter.ResponseJson := ReadFileData('OrderResponse.json');
    Response := FPrinter.CreateOrder(Request);
    CheckEquals(RequestJson, FPrinter.RequestJson, 'RequestJson');
    CheckEquals(True, Response.is_success, 'is_success');
    CheckEquals(0, Response.error.code, 'error.code');
    CheckEquals('', Response.error.message, 'error.message');
    CheckEquals('UZ170703100189', Response.data.terminal_id, 'data.terminal_id');
    CheckEquals(643, Response.data.receipt_count, 'data.receipt_count');
    CheckEquals('20200518221403', Response.data.date_time, 'data.date_time');
    CheckEquals('248429044289', Response.data.fiscal_sign, 'data.fiscal_sign');
    CheckEquals('0300', Response.data.applet_version, 'data.applet_version');
    CheckEquals('https://ofd.soliq.uz/check?t=UZ170703100189&r=643&c=20200518221403&s=248429044289',
      Response.data.qr_url, 'data.qr_url');
  finally
    Request.Free;
  end;
end;

procedure TWebPrinterTest.CheckReturnOrder;
var
  Request: TWPOrder;
  RequestJson: WideString;
  Response: TWPCreateOrderResponse;
begin
  Request := TWPOrder.Create;
  try
    CreateOrder(Request);
    WriteFileData('OrderRequest2.json', ObjectToJson(Request));

    FPrinter.TestMode := True;
    RequestJson := ReadFileData('OrderRequest.json');
    FPrinter.ResponseJson := ReadFileData('OrderResponse.json');
    Response := FPrinter.ReturnOrder(Request);
    CheckEquals(RequestJson, FPrinter.RequestJson, 'RequestJson');
    CheckEquals(True, Response.is_success, 'is_success');
    CheckEquals(0, Response.error.code, 'error.code');
    CheckEquals('', Response.error.message, 'error.message');
    CheckEquals('UZ170703100189', Response.data.terminal_id, 'data.terminal_id');
    CheckEquals(643, Response.data.receipt_count, 'data.receipt_count');
    CheckEquals('20200518221403', Response.data.date_time, 'data.date_time');
    CheckEquals('248429044289', Response.data.fiscal_sign, 'data.fiscal_sign');
    CheckEquals('0300', Response.data.applet_version, 'data.applet_version');
    CheckEquals('https://ofd.soliq.uz/check?t=UZ170703100189&r=643&c=20200518221403&s=248429044289',
      Response.data.qr_url, 'data.qr_url');
  finally
    Request.Free;
  end;
end;

procedure TWebPrinterTest.CheckPrintLastReceipt;
var
  Response: TWPResponse;
begin
  FPrinter.TestMode := True;
  FPrinter.ResponseJson := ReadFileData('PrintLastReceipt.json');
  Response := FPrinter.PrintLastReceipt.result;
  CheckEquals(True, Response.is_success, 'is_success');
  CheckEquals(0, Response.error.code, 'error.code');
  CheckEquals('', Response.error.message, 'error.message');
end;

procedure TWebPrinterTest.CheckPrintLastReceiptError;
var
  Response: TWPResponse;
begin
  FPrinter.TestMode := True;
  FPrinter.ResponseJson := ReadFileData('PrintLastReceiptError.json');
  Response := FPrinter.PrintLastReceipt.result;
  CheckEquals(False, Response.is_success, 'is_success');
  CheckEquals(9326, Response.error.code, 'error.code');
  CheckEquals('ZREPORT_ALREADY_CLOSE', Response.error.message, 'error.message');
end;

initialization
  RegisterTest('', TWebPrinterTest.Suite);


end.

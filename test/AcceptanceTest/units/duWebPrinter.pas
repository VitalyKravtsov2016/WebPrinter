unit duWebPrinter;

interface

uses
  // VCL
  Windows, SysUtils, Classes, IniFiles,
  // Indy
  IdURI,
  // DUnit
  TestFramework,
  // This
  LogFile, FileUtils, WebPrinter, DriverError, JsonUtils;

type
  { TWebPrinterTest }

  TWebPrinterTest2 = class(TTestCase)
  private
    FLogger: ILogFile;
    FPrinter: TWebPrinter;
    procedure CreateOrder(Request: TWPOrder);
  protected
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure CheckInfoCommand;
    procedure CheckOpenFiscalDay;
    procedure CheckCloseFiscalDay;
    procedure CheckWPDateTimeToStr;
    procedure CheckPrintXReport;
    procedure CheckPrintZReport;
    procedure CheckReadZReport;
    procedure CheckOpenCashDrawer;
    procedure CheckCreateOrder;
    procedure CheckReturnOrder;
    procedure CheckPrintLastReceipt;
    procedure CheckParamsEncode;
  end;

implementation


{ TWebPrinterTest2 }

procedure TWebPrinterTest2.Setup;
begin
  FLogger := TLogFile.Create;
  FLogger.Enabled := True;

  FPrinter := TWebPrinter.Create(FLogger);
  FPrinter.Address := 'http://fbox.ngrok.io'; // 8080 или 80
  FPrinter.RaiseErrors := True;
end;

procedure TWebPrinterTest2.TearDown;
begin
  FPrinter.Free;
  FLogger := nil;
end;

procedure TWebPrinterTest2.CheckInfoCommand;
var
  Data: TWPInfoResponse;
begin
  Data := FPrinter.ReadInfo2.Data;
  CheckEquals(Data.terminal_id, 'UZ170703100597', 'terminal_id');
  CheckEquals(Data.applet_version, '0300', 'applet_version');
  CheckEquals(Data.receipt_count, 0, 'receipt_count');
  CheckEquals(Data.receipt_max_count, 858, 'receipt_max_count');
  CheckEquals(Data.zreport_count, 743, 'zreport_count');
  CheckEquals(Data.zreport_max_count, 832, 'zreport_max_count');
  CheckEquals(Data.available_persistent_memory, 6100, 'available_persistent_memory');
  CheckEquals(Data.available_reset_memory, 1440, 'available_reset_memory');
  CheckEquals(Data.available_deselect_memory, 1440, 'available_deselect_memory');
  CheckEquals(Data.cashbox_number, 1, 'cashbox_number');
  CheckEquals(Data.version_code, '1.15.23', 'version_code');
  CheckEquals(Data.is_updated, false, 'is_updated');
(*
  CheckEquals(Data.current_receipt_seq, '6152', 'current_receipt_seq');
  CheckEquals(Data.current_time, '2024-01-09 15:53:15', 'current_time');
  CheckEquals(Data.last_operation_time, '2024-01-09 15:40:43', 'last_operation_time');
*)
end;

procedure TWebPrinterTest2.CheckOpenFiscalDay;
var
  Data: WideString;
begin
  Data := FPrinter.OpenFiscalDay(Now);
  WriteFileData('WPOpenFiscalDay.json', Data);
end;

procedure TWebPrinterTest2.CheckCloseFiscalDay;
var
  Response: TWPCloseDayResponse;
begin
  Response := FPrinter.CloseFiscalDay2(Now);
  CheckEquals(True, Response.is_success, 'is_success');
(*
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
*)
end;

procedure TWebPrinterTest2.CheckWPDateTimeToStr;
var
  Time: TDateTime;
begin
  Time := EncodeDate(2023, 12, 28) + EncodeTime(1, 2, 3, 4);
  CheckEquals('2023-12-28 01:02:03', WPDateTimeToStr(Time));
end;

procedure TWebPrinterTest2.CheckPrintXReport;
var
  Request: TWPCloseDayRequest;
  Response: TWPCloseDayResponse;
begin
  Request := TWPCloseDayRequest.Create;
  try
    Request.Time := Now;
    Request.close_zreport := False;
    Request.name := 'X отчет';
    Response := FPrinter.PrintZReport(Request);
    CheckEquals(True, Response.is_success, 'is_success');
  finally
    Request.Free;
  end;
end;

procedure TWebPrinterTest2.CheckPrintZReport;
var
  Request: TWPCloseDayRequest;
  Response: TWPCloseDayResponse;
begin
  Request := TWPCloseDayRequest.Create;
  try
    Request.Time := Now;
    Request.close_zreport := True;
    Request.name := 'X отчет';
    Response := FPrinter.PrintZReport(Request);
    CheckEquals(True, Response.is_success, 'is_success');
  finally
    Request.Free;
  end;
end;

procedure TWebPrinterTest2.CheckReadZReport;
var
  Response: TWPCloseDayResponse;
begin
  Response := FPrinter.ReadZReport.Result;
  CheckEquals(True, Response.is_success, 'is_success');
  CheckEquals('0300', Response.data.applet_version, 'data.applet_version');
  CheckEquals('UZ170703100597', Response.data.terminal_id, 'data.terminal_id');
end;

procedure TWebPrinterTest2.CheckOpenCashDrawer;
var
  Response: TWPResponse;
begin
  Response := FPrinter.OpenCashDrawer;
  CheckEquals(True, Response.is_success, 'is_success');
  CheckEquals(0, Response.error.code, 'error.code');
  CheckEquals('', Response.error.message, 'error.message');
end;

procedure TWebPrinterTest2.CreateOrder(Request: TWPOrder);
var
  Price: TWPPrice;
  Banner: TWPBanner;
  Product: TWPProduct;
  Info: TWPInfoResponse;
begin
  Info := FPrinter.ReadInfo2.Data;

  Request.number := 1;
  Request.receipt_type := 'order';
  Product := Request.products.Add as TWPProduct;
  Product.name := 'ШОКОЛАДНАЯ ПЛИТКА MILKA';
  Product.barcode := ''; //'4780000000007';
  Product.amount := 1000;
  Product.units := 1;
  Product.price := 59000;
  Product.product_price := 59000;
  Product.vat := 0;
  Product.vat_percent := 0;
  Product.discount := 0;
  Product.discount_percent := 0;
  Product.other := 0;
  //Product.labels.Add('05367567230048c?eN1(o0029');
  Product.class_code := '04811001001000000';
  Product.package_code := 1431970;
  Product.owner_type := 1;
  Product.comission_info.inn := '123456789';
  Product.comission_info.pinfl := '12345678912345';
  Request.time := Info.current_time;
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

procedure TWebPrinterTest2.CheckCreateOrder;
var
  Request: TWPOrder;
  Response: TWPCreateOrderResponse;
begin
  Request := TWPOrder.Create;
  try
    CreateOrder(Request);
    Response := FPrinter.CreateOrder(Request);
    CheckEquals(True, Response.is_success, 'is_success');
    CheckEquals(0, Response.error.code, 'error.code');
    CheckEquals('', Response.error.message, 'error.message');
    (*
    CheckEquals('UZ170703100189', Response.data.terminal_id, 'data.terminal_id');
    CheckEquals(643, Response.data.receipt_count, 'data.receipt_count');
    CheckEquals('20200518221403', Response.data.date_time, 'data.date_time');
    CheckEquals('248429044289', Response.data.fiscal_sign, 'data.fiscal_sign');
    CheckEquals('0300', Response.data.applet_version, 'data.applet_version');
    CheckEquals('https://ofd.soliq.uz/check?t=UZ170703100189&r=643&c=20200518221403&s=248429044289',
      Response.data.qr_url, 'data.qr_url');
    *)
  finally
    Request.Free;
  end;
end;

procedure TWebPrinterTest2.CheckReturnOrder;
var
  Request: TWPOrder;
  Response: TWPCreateOrderResponse;
begin
  Request := TWPOrder.Create;
  try
    CreateOrder(Request);
    Response := FPrinter.ReturnOrder(Request);
    CheckEquals(True, Response.is_success, 'is_success');
    CheckEquals(0, Response.error.code, 'error.code');
    CheckEquals('', Response.error.message, 'error.message');

(*
    CheckEquals('UZ170703100189', Response.data.terminal_id, 'data.terminal_id');
    CheckEquals(643, Response.data.receipt_count, 'data.receipt_count');
    CheckEquals('20200518221403', Response.data.date_time, 'data.date_time');
    CheckEquals('248429044289', Response.data.fiscal_sign, 'data.fiscal_sign');
    CheckEquals('0300', Response.data.applet_version, 'data.applet_version');
    CheckEquals('https://ofd.soliq.uz/check?t=UZ170703100189&r=643&c=20200518221403&s=248429044289',
      Response.data.qr_url, 'data.qr_url');
*)      
  finally
    Request.Free;
  end;
end;

procedure TWebPrinterTest2.CheckPrintLastReceipt;
var
  Response: TWPResponse;
begin
  Response := FPrinter.PrintLastReceipt.result;
  CheckEquals(True, Response.is_success, 'is_success');
  CheckEquals(0, Response.error.code, 'error.code');
  CheckEquals('', Response.error.message, 'error.message');
end;

procedure TWebPrinterTest2.CheckParamsEncode;
begin
  CheckEquals('time=2024-01-09%2015:53:15', TIdURI.ParamsEncode('time=2024-01-09 15:53:15'));
end;

initialization
  RegisterTest('', TWebPrinterTest2.Suite);


end.

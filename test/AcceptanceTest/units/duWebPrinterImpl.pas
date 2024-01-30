unit duWebPrinterImpl;

interface

uses
  // VCL
  Windows, SysUtils, Classes, IniFiles,
  // Indy
  IdURI,
  // Opos
  Opos, Oposhi, OposFptr, OposFptrhi, OposUtils, OposFptrUtils,
  // DUnit
  TestFramework,
  // This
  LogFile, FileUtils, WebPrinter, WebPrinterImpl, DriverError, JsonUtils,
  DirectIOAPI;

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
  protected
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestPrintZreport;
    procedure TestFiscalReceipt;
    procedure TestRefundReceipt;
  end;

implementation

{ TWebPrinterImplTest }

procedure TWebPrinterImplTest.Setup;
begin
  FDriver := TWebPrinterImpl.Create(nil);
  FDriver.Params.WebprinterAddress := 'http://fbox.ngrok.io'; // 8080 ��� 80
  FDriver.Params.LogFileEnabled := True;
  FDriver.Params.LogMaxCount := 10;
  FDriver.LoadParamsEnabled := False;
  FDriver.Params.VatRates.Clear;
  FDriver.Params.VatRates.Add(1, 10,  '��� 10%');
  FDriver.Params.VatRates.Add(2, 12,  '��� 12%');
  FDriver.Params.VatRates.Add(10, 15,  '��� 15%');
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
  FptrCheck(Driver.PrintRecItem('"Item 1"'#10#13, 100, 1000, 10, 100, '��'));
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
  FptrCheck(Driver.DirectIO2(DIO_SET_RECEIPT_QRCODE, 0, receipt_qr_code));

  FptrCheck(Driver.DirectIO2(30, 80, '4780000000007'));
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

initialization
  RegisterTest('', TWebPrinterImplTest.Suite);


end.

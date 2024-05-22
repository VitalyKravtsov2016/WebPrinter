unit WebPrinterImpl;

interface

uses
  // VCL
  Classes, SysUtils, Windows, DateUtils, ActiveX, ComObj, Math, Graphics,
  // Tnt
  TntSysUtils, TntClasses,
  // Opos
  Opos, Oposhi, OposFptr, OposFptrHi, OposEvents, OposEventsRCS,
  OposException, OposFptrUtils, OposServiceDevice19, OposUtils,
  // gnugettext

  gnugettext,
  // This
  LogFile, WException, VersionInfo, DriverError, FiscalPrinterState,
  CustomReceipt, NonFiscalDoc, ServiceVersion,  PrinterParameters,
  PrinterParametersX, CashInReceipt, CashOutReceipt, SalesReceipt,
  ReceiptItem, StringUtils, DebugUtils, VatRate, FileUtils,
  PrinterTypes, DirectIOAPI, PrinterParametersReg, WebPrinter,
  WebFptrSO_TLB, MathUtils, ItemUnit, JsonUtils, uLkJSON, TLVItem;

const
  AmountDecimalPlaces = 2;
  FPTR_DEVICE_DESCRIPTION = 'WebPrinter OPOS driver';

type
  { TWebPrinterImpl }

  TWebPrinterImpl = class(TComponent, IFiscalPrinterService_1_12)
  private
    FLogger: ILogFile;
    FLines: TTntStrings;
    FTLVItems: TTLVItems;
    FPrinter: TWebPrinter;
    FReceipt: TCustomReceipt;
    FParams: TPrinterParameters;
    FOposDevice: TOposServiceDevice19;
    FPrinterState: TFiscalPrinterState;

    FTestMode: Boolean;
    FPOSID: WideString;
    FCashierID: WideString;

    procedure UpdateRecItemFields(Product: TWPProduct; Fields: TTntStrings);
    procedure UpdateReceiptFields(Order: TWPOrder; Fields: TTntStrings);
    procedure UpdateZReport;
    procedure WriteOperationTag(pData: Integer; const pString: string);
    procedure AddReportLines(Request: TWPCloseDayRequest);
    function ReadCashRegister(RegID: Integer): Currency;
    function GetReportName(const ReportName: WideString): WideString;
    function GetPOSID: WideString;
    function GetTerminalID: WideString;
    procedure RecDiscountsToItemDiscounts(Receipt: TSalesReceipt);
    procedure OpenCashDrawer;
  public
    procedure Initialize;
    procedure CheckEnabled;
    procedure CheckCapSetVatTable;
    procedure CheckState(AState: Integer);
    procedure SetPrinterState(Value: Integer);
    procedure Print(Receipt: TCashInReceipt); overload;
    procedure Print(Receipt: TCashOutReceipt); overload;
    procedure Print(Receipt: TSalesReceipt); overload;

    function DoClose: Integer;
    function DoRelease: Integer;
    function IllegalError: Integer;
    function GetPrinterState: Integer;
    function GetQuantity(Value: Integer): Double;
    function AmountToStrEq(Value: Currency): AnsiString;
    function AmountToOutStr(Value: Currency): AnsiString;
    function CreateReceipt(FiscalReceiptType: Integer): TCustomReceipt;

    property Printer: TWebPrinter read FPrinter;
    property Receipt: TCustomReceipt read FReceipt;
    property PrinterState: Integer read GetPrinterState write SetPrinterState;
  private
    FPostLine: WideString;
    FPreLine: WideString;
    FCheckTotal: Boolean;
    // boolean
    FCoverOpen: Boolean;
    FJrnEmpty: Boolean;
    FJrnNearEnd: Boolean;
    FRecEmpty: Boolean;
    FRecNearEnd: Boolean;
    FSlpEmpty: Boolean;
    FSlpNearEnd: Boolean;
    FCapSlpEmptySensor: Boolean;
    FCapSlpNearEndSensor: Boolean;
    FCapSlpPresent: Boolean;
    FCapCoverSensor: Boolean;
    FCapJrnEmptySensor: Boolean;
    FCapJrnNearEndSensor: Boolean;
    FCapRecEmptySensor: Boolean;
    FCapRecNearEndSensor: Boolean;
    FCapRecPresent: Boolean;
    FCapJrnPresent: Boolean;
    FCapAdditionalLines: Boolean;
    FCapAmountAdjustment: Boolean;
    FCapAmountNotPaid: Boolean;
    FCapCheckTotal: Boolean;
    FCapDoubleWidth: Boolean;
    FCapDuplicateReceipt: Boolean;
    FCapFixedOutput: Boolean;
    FCapHasVatTable: Boolean;
    FCapIndependentHeader: Boolean;
    FCapItemList: Boolean;
    FCapNonFiscalMode: Boolean;
    FCapOrderAdjustmentFirst: Boolean;
    FCapPercentAdjustment: Boolean;
    FCapPositiveAdjustment: Boolean;
    FCapPowerLossReport: Boolean;
    FCapPredefinedPaymentLines: Boolean;
    FCapReceiptNotPaid: Boolean;
    FCapRemainingFiscalMemory: Boolean;
    FCapReservedWord: Boolean;
    FCapSetPOSID: Boolean;
    FCapSetStoreFiscalID: Boolean;
    FCapSetVatTable: Boolean;
    FCapSlpFiscalDocument: Boolean;
    FCapSlpFullSlip: Boolean;
    FCapSlpValidation: Boolean;
    FCapSubAmountAdjustment: Boolean;
    FCapSubPercentAdjustment: Boolean;
    FCapSubtotal: Boolean;
    FCapTrainingMode: Boolean;
    FCapValidateJournal: Boolean;
    FCapXReport: Boolean;
    FCapAdditionalHeader: Boolean;
    FCapAdditionalTrailer: Boolean;
    FCapChangeDue: Boolean;
    FCapEmptyReceiptIsVoidable: Boolean;
    FCapFiscalReceiptStation: Boolean;
    FCapFiscalReceiptType: Boolean;
    FCapMultiContractor: Boolean;
    FCapOnlyVoidLastItem: Boolean;
    FCapPackageAdjustment: Boolean;
    FCapPostPreLine: Boolean;
    FCapSetCurrency: Boolean;
    FCapTotalizerType: Boolean;
    FCapPositiveSubtotalAdjustment: Boolean;
    FCapSetHeader: Boolean;
    FCapSetTrailer: Boolean;

    FAsyncMode: Boolean;
    FDuplicateReceipt: Boolean;
    FFlagWhenIdle: Boolean;
    // integer
    FCountryCode: Integer;
    FErrorLevel: Integer;
    FErrorOutID: Integer;
    FErrorState: Integer;
    FErrorStation: Integer;
    FQuantityDecimalPlaces: Integer;
    FQuantityLength: Integer;
    FSlipSelection: Integer;
    FActualCurrency: Integer;
    FContractorId: Integer;
    FDateType: Integer;
    FFiscalReceiptStation: Integer;
    FFiscalReceiptType: Integer;
    FMessageType: Integer;
    FTotalizerType: Integer;

    FAdditionalHeader: WideString;
    FAdditionalTrailer: WideString;
    FPredefinedPaymentLines: WideString;
    FReservedWord: WideString;
    FChangeDue: WideString;
    FRemainingFiscalMemory: Integer;

    function DoCloseDevice: Integer;
    function DoOpen(const DeviceClass, DeviceName: WideString;
      const pDispatch: IDispatch): Integer;
    function GetEventInterface(FDispatch: IDispatch): IOposEvents;
    function ClearResult: Integer;
    function HandleException(E: Exception): Integer;
    procedure SetDeviceEnabled(Value: Boolean);
    function HandleDriverError(E: EDriverError): TOPOSError;
  public
    function Get_OpenResult: Integer; safecall;
    function COFreezeEvents(Freeze: WordBool): Integer; safecall;
    function GetPropertyNumber(PropIndex: Integer): Integer; safecall;
    procedure SetPropertyNumber(PropIndex: Integer; Number: Integer); safecall;
    function GetPropertyString(PropIndex: Integer): WideString; safecall;
    procedure SetPropertyString(PropIndex: Integer; const Text: WideString); safecall;
    function OpenService(const DeviceClass: WideString; const DeviceName: WideString;
                         const pDispatch: IDispatch): Integer; safecall;
    function CloseService: Integer; safecall;
    function CheckHealth(Level: Integer): Integer; safecall;
    function ClaimDevice(Timeout: Integer): Integer; safecall;
    function ClearOutput: Integer; safecall;
    function DirectIO(Command: Integer; var pData: Integer; var pString: WideString): Integer; safecall;
    function DirectIO2(Command: Integer; const pData: Integer; const pString: WideString): Integer;
    function DirectIO3(Command: Integer; const pData: Integer; var pString: WideString): Integer;
    function ReleaseDevice: Integer; safecall;
    function BeginFiscalDocument(DocumentAmount: Integer): Integer; safecall;
    function BeginFiscalReceipt(PrintHeader: WordBool): Integer; safecall;
    function BeginFixedOutput(Station: Integer; DocumentType: Integer): Integer; safecall;
    function BeginInsertion(Timeout: Integer): Integer; safecall;
    function BeginItemList(VatID: Integer): Integer; safecall;
    function BeginNonFiscal: Integer; safecall;
    function BeginRemoval(Timeout: Integer): Integer; safecall;
    function BeginTraining: Integer; safecall;
    function ClearError: Integer; safecall;
    function EndFiscalDocument: Integer; safecall;
    function EndFiscalReceipt(PrintHeader: WordBool): Integer; safecall;
    function EndFixedOutput: Integer; safecall;
    function EndInsertion: Integer; safecall;
    function EndItemList: Integer; safecall;
    function EndNonFiscal: Integer; safecall;
    function EndRemoval: Integer; safecall;
    function EndTraining: Integer; safecall;
    function GetData(DataItem: Integer; out OptArgs: Integer; out Data: WideString): Integer; safecall;
    function GetDate(out Date: WideString): Integer; safecall;
    function GetTotalizer(VatID: Integer; OptArgs: Integer; out Data: WideString): Integer; safecall;
    function GetVatEntry(VatID: Integer; OptArgs: Integer; out VatRate: Integer): Integer; safecall;
    function PrintDuplicateReceipt: Integer; safecall;
    function PrintFiscalDocumentLine(const DocumentLine: WideString): Integer; safecall;
    function PrintFixedOutput(DocumentType: Integer; LineNumber: Integer; const Data: WideString): Integer; safecall;
    function PrintNormal(Station: Integer; const AData: WideString): Integer; safecall;
    function PrintPeriodicTotalsReport(const Date1: WideString; const Date2: WideString): Integer; safecall;
    function PrintPowerLossReport: Integer; safecall;
    function PrintRecItem(const Description: WideString; Price: Currency; Quantity: Integer;
                          VatInfo: Integer; UnitPrice: Currency; const UnitName: WideString): Integer; safecall;
    function PrintRecItemAdjustment(AdjustmentType: Integer; const Description: WideString;
                                    Amount: Currency; VatInfo: Integer): Integer; safecall;
    function PrintRecMessage(const Message: WideString): Integer; safecall;
    function PrintRecNotPaid(const Description: WideString; Amount: Currency): Integer; safecall;
    function PrintRecRefund(const Description: WideString; Amount: Currency; VatInfo: Integer): Integer; safecall;
    function PrintRecSubtotal(Amount: Currency): Integer; safecall;
    function PrintRecSubtotalAdjustment(AdjustmentType: Integer; const Description: WideString;
                                        Amount: Currency): Integer; safecall;
    function PrintRecTotal(Total: Currency; Payment: Currency; const Description: WideString): Integer; safecall;
    function PrintRecVoid(const Description: WideString): Integer; safecall;
    function PrintRecVoidItem(const Description: WideString; Amount: Currency; Quantity: Integer;
                              AdjustmentType: Integer; Adjustment: Currency; VatInfo: Integer): Integer; safecall;
    function PrintReport(ReportType: Integer; const StartNum: WideString; const EndNum: WideString): Integer; safecall;
    function PrintXReport: Integer; safecall;
    function PrintZReport: Integer; safecall;
    function ResetPrinter: Integer; safecall;
    function SetDate(const Date: WideString): Integer; safecall;
    function SetHeaderLine(LineNumber: Integer; const Text: WideString; DoubleWidth: WordBool): Integer; safecall;
    function SetPOSID(const POSID: WideString; const CashierID: WideString): Integer; safecall;
    function SetStoreFiscalID(const ID: WideString): Integer; safecall;
    function SetTrailerLine(LineNumber: Integer; const Text: WideString; DoubleWidth: WordBool): Integer; safecall;
    function SetVatTable: Integer; safecall;
    function SetVatValue(VatID: Integer; const VatValue: WideString): Integer; safecall;
    function VerifyItem(const ItemName: WideString; VatID: Integer): Integer; safecall;
    function PrintRecCash(Amount: Currency): Integer; safecall;
    function PrintRecItemFuel(const Description: WideString; Price: Currency; Quantity: Integer;
                              VatInfo: Integer; UnitPrice: Currency; const UnitName: WideString;
                              SpecialTax: Currency; const SpecialTaxName: WideString): Integer; safecall;
    function PrintRecItemFuelVoid(const Description: WideString; Price: Currency; VatInfo: Integer;
                                  SpecialTax: Currency): Integer; safecall;
    function PrintRecPackageAdjustment(AdjustmentType: Integer; const Description: WideString;
                                       const VatAdjustment: WideString): Integer; safecall;
    function PrintRecPackageAdjustVoid(AdjustmentType: Integer; const VatAdjustment: WideString): Integer; safecall;
    function PrintRecRefundVoid(const Description: WideString; Amount: Currency; VatInfo: Integer): Integer; safecall;
    function PrintRecSubtotalAdjustVoid(AdjustmentType: Integer; Amount: Currency): Integer; safecall;
    function PrintRecTaxID(const TaxID: WideString): Integer; safecall;
    function SetCurrency(NewCurrency: Integer): Integer; safecall;
    function GetOpenResult: Integer; safecall;
    function Open(const DeviceClass: WideString; const DeviceName: WideString;
                  const pDispatch: IDispatch): Integer; safecall;
    function Close: Integer; safecall;
    function Claim(Timeout: Integer): Integer; safecall;
    function Release1: Integer; safecall;
    function ResetStatistics(const StatisticsBuffer: WideString): Integer; safecall;
    function RetrieveStatistics(var pStatisticsBuffer: WideString): Integer; safecall;
    function UpdateStatistics(const StatisticsBuffer: WideString): Integer; safecall;
    function CompareFirmwareVersion(const FirmwareFileName: WideString; out pResult: Integer): Integer; safecall;
    function UpdateFirmware(const FirmwareFileName: WideString): Integer; safecall;
    function PrintRecItemAdjustmentVoid(AdjustmentType: Integer; const Description: WideString;
                                        Amount: Currency; VatInfo: Integer): Integer; safecall;
    function PrintRecItemVoid(const Description: WideString; Price: Currency; Quantity: Integer;
                              VatInfo: Integer; UnitPrice: Currency; const UnitName: WideString): Integer; safecall;
    function PrintRecItemRefund(const Description: WideString; Amount: Currency; Quantity: Integer;
                                VatInfo: Integer; UnitAmount: Currency; const UnitName: WideString): Integer; safecall;
    function PrintRecItemRefundVoid(const Description: WideString; Amount: Currency;
                                    Quantity: Integer; VatInfo: Integer; UnitAmount: Currency;
                                    const UnitName: WideString): Integer; safecall;
    property OpenResult: Integer read Get_OpenResult;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function EncodeString(const S: WideString): WideString;
    function DecodeString(const Text: WideString): WideString;

    property Logger: ILogFile read FLogger;
    property Params: TPrinterParameters read FParams;
    property TestMode: Boolean read FTestMode write FTestMode;
    property OposDevice: TOposServiceDevice19 read FOposDevice;
  end;

implementation

const
  BoolToInt: array [Boolean] of Integer = (0, 1);

function IntToBool(Value: Integer): Boolean;
begin
  Result := Value <> 0;
end;

function GetSystemLocaleStr: WideString;
const
  BoolToStr: array [Boolean] of WideString = ('0', '1');
begin
  Result := Format('LCID: %d, LangID: %d.%d, FarEast: %s, FarEast: %s',
    [SysLocale.DefaultLCID, SysLocale.PriLangID, SysLocale.SubLangID,
    BoolToStr[SysLocale.FarEast], BoolToStr[SysLocale.MiddleEast]]);
end;

function GetSystemVersionStr: WideString;
var
  OSVersionInfo: TOSVersionInfo;
begin
  Result := '';
  OSVersionInfo.dwOSVersionInfoSize := SizeOf(OSVersionInfo);
  if GetVersionEx(OSVersionInfo) then
  begin
    Result := Tnt_WideFormat('%d.%d.%d, Platform ID: %d', [
      OSVersionInfo.dwMajorVersion,
      OSVersionInfo.dwMinorVersion,
      OSVersionInfo.dwBuildNumber,
      OSVersionInfo.dwPlatformId]);
  end;
end;

procedure CheckAdjustmentType(AdjustmentType: Integer);
begin
  case AdjustmentType of
   FPTR_AT_AMOUNT_DISCOUNT,
   FPTR_AT_PERCENTAGE_DISCOUNT: Exit;
  else
    raiseIllegalError(Format('Invalid AdjustmentType value (%d)', [AdjustmentType]));
  end;
end;

{ TWebPrinterImpl }

constructor TWebPrinterImpl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLogger := TLogFile.Create;
  FLines := TTntStringList.Create;
  FReceipt := TCustomReceipt.Create;
  FPrinter := TWebPrinter.Create(FLogger);
  FParams := TPrinterParameters.Create(FLogger);
  FOposDevice := TOposServiceDevice19.Create(FLogger);
  FOposDevice.ErrorEventEnabled := False;
  FPrinterState := TFiscalPrinterState.Create;
  FTLVItems := TTLVItems.Create;
end;

destructor TWebPrinterImpl.Destroy;
begin
  if FOposDevice.Opened then
    Close;

  FLines.Free;
  FParams.Free;
  FReceipt.Free;
  FPrinter.Free;
  FTLVItems.Free;
  FOposDevice.Free;
  FPrinterState.Free;
  FLogger := nil;
  inherited Destroy;
end;

// Open cash drawer
procedure TWebPrinterImpl.OpenCashDrawer;
begin
  if Params.OpenCashbox then
  begin
    FPrinter.SaveState;
    try
      FPrinter.OpenCashDrawer;
    except
      on E: Exception do
      begin
        Logger.Error('Failed open cash drawer, ' + e.Message);
      end;
    end;
    FPrinter.LoadState;
  end;
end;

function TWebPrinterImpl.AmountToOutStr(Value: Currency): AnsiString;
var
  L: Int64;
begin
  L := Trunc(Value * Math.Power(10, AmountDecimalPlaces));
  Result := IntToStr(L);
end;

function TWebPrinterImpl.AmountToStrEq(Value: Currency): AnsiString;
begin
  Result := '=' + AmountToStr(Value);
end;

function TWebPrinterImpl.GetQuantity(Value: Integer): Double;
begin
  Result := Value / 1000;
end;

function TWebPrinterImpl.CreateReceipt(FiscalReceiptType: Integer): TCustomReceipt;
begin
  case FiscalReceiptType of
    FPTR_RT_CASH_IN: Result := TCashInReceipt.Create;
    FPTR_RT_CASH_OUT: Result := TCashOutReceipt.Create;

    FPTR_RT_SALES,
    FPTR_RT_GENERIC,
    FPTR_RT_SERVICE,
    FPTR_RT_SIMPLE_INVOICE:
      Result := TSalesReceipt.CreateReceipt(rtSell,
        AmountDecimalPlaces, 0);

    FPTR_RT_REFUND:
      Result := TSalesReceipt.CreateReceipt(rtRetSell,
        AmountDecimalPlaces, 0);
  else
    Result := nil;
    InvalidPropertyValue('FiscalReceiptType', IntToStr(FiscalReceiptType));
  end;
end;

procedure TWebPrinterImpl.CheckCapSetVatTable;
begin
  if not FCapSetVatTable then
    RaiseIllegalError(_('Not supported'));
end;

function TWebPrinterImpl.DoRelease: Integer;
begin
  try
    SetDeviceEnabled(False);
    OposDevice.ReleaseDevice;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.GetPrinterState: Integer;
begin
  Result := FPrinterState.State;
end;

procedure TWebPrinterImpl.SetPrinterState(Value: Integer);
begin
  FPrinterState.SetState(Value);
end;

function TWebPrinterImpl.DoClose: Integer;
begin
  try
    Result := DoCloseDevice;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

procedure TWebPrinterImpl.Initialize;
begin
  FCapSlpEmptySensor := False;
  FCapSlpNearEndSensor := False;
  FCapSlpPresent := False;
  FCapCoverSensor := False;
  FCapJrnEmptySensor := False;
  FCapJrnNearEndSensor := False;
  FCapRecEmptySensor := False;
  FCapRecNearEndSensor := False;
  FCapRecPresent := False;
  FCapJrnPresent := False;
  FCapAdditionalLines := False;
  FCapAmountAdjustment := True;
  FCapAmountNotPaid := False;
  FCapCheckTotal := True;
  FCapDoubleWidth := False;
  FCapDuplicateReceipt := False;
  FCapFixedOutput := False;
  FCapHasVatTable := False;
  FCapIndependentHeader := False;
  FCapItemList := False;
  FCapNonFiscalMode := False;
  FCapOrderAdjustmentFirst := False;
  FCapPercentAdjustment := True;
  FCapPositiveAdjustment := False;
  FCapPowerLossReport := False;
  FCapPredefinedPaymentLines := False;
  FCapReceiptNotPaid := False;
  FCapRemainingFiscalMemory := False;
  FCapReservedWord := False;
  FCapSetPOSID := True;
  FCapSetStoreFiscalID := False;
  FCapSetVatTable := True;
  FCapSlpFiscalDocument := False;
  FCapSlpFullSlip := False;
  FCapSlpValidation := False;
  FCapSubAmountAdjustment := True;
  FCapSubPercentAdjustment := True;
  FCapSubtotal := True;
  FCapTrainingMode := False;
  FCapValidateJournal := False;
  FCapXReport := True;
  FCapAdditionalHeader := False;
  FCapAdditionalTrailer := False;
  FCapChangeDue := False;
  FCapEmptyReceiptIsVoidable := True;
  FCapFiscalReceiptStation := True;
  FCapFiscalReceiptType := True;
  FCapMultiContractor := False;
  FCapOnlyVoidLastItem := False;
  FCapPackageAdjustment := True;
  FCapPostPreLine := False;
  FCapSetCurrency := False;
  FCapTotalizerType := False;
  FCapPositiveSubtotalAdjustment := False;
  FCapSetHeader := False;
  FCapSetTrailer := False;

  FAsyncMode := False;
  FDuplicateReceipt := False;
  FFlagWhenIdle := False;
  // integer
  FOposDevice.ServiceObjectVersion := GenericServiceVersion;
  FCountryCode := FPTR_CC_RUSSIA;
  FErrorLevel := FPTR_EL_NONE;
  FErrorOutID := 0;
  FErrorState := FPTR_PS_MONITOR;
  FErrorStation := FPTR_S_RECEIPT;
  SetPrinterState(FPTR_PS_MONITOR);
  FQuantityDecimalPlaces := 3;
  FQuantityLength := 10;
  FSlipSelection := FPTR_SS_FULL_LENGTH;
  FActualCurrency := FPTR_AC_RUR;
  FContractorId := FPTR_CID_SINGLE;
  FDateType := FPTR_DT_RTC;
  FFiscalReceiptStation := FPTR_RS_RECEIPT;
  FFiscalReceiptType := FPTR_RT_SALES;
  FMessageType := FPTR_MT_FREE_TEXT;
  FTotalizerType := FPTR_TT_DAY;

  FAdditionalHeader := '';
  FAdditionalTrailer := '';
  FOposDevice.PhysicalDeviceName := FPTR_DEVICE_DESCRIPTION;
  FOposDevice.PhysicalDeviceDescription := FPTR_DEVICE_DESCRIPTION;
  FOposDevice.ServiceObjectDescription := 'WebPrinter OPOS fiscal printer service. SHTRIH-M, 2022';
  FPredefinedPaymentLines := '0,1,2,3';
  FReservedWord := '';
  FChangeDue := '';
end;

function TWebPrinterImpl.IllegalError: Integer;
begin
  Result := FOposDevice.SetResultCode(OPOS_E_ILLEGAL);
end;

function TWebPrinterImpl.ClearResult: Integer;
begin
  Result := FOposDevice.ClearResult;
end;

procedure TWebPrinterImpl.CheckEnabled;
begin
  FOposDevice.CheckEnabled;
end;

procedure TWebPrinterImpl.CheckState(AState: Integer);
begin
  CheckEnabled;
  FPrinterState.CheckState(AState);
end;

function TWebPrinterImpl.DecodeString(const Text: WideString): WideString;
begin
  Result := Text;
end;

function TWebPrinterImpl.EncodeString(const S: WideString): WideString;
begin
  Result := S;
end;

function TWebPrinterImpl.BeginFiscalDocument(
  DocumentAmount: Integer): Integer;
begin
  try
    CheckEnabled;
    CheckState(FPTR_PS_MONITOR);
    SetPrinterState(FPTR_PS_FISCAL_DOCUMENT);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.BeginFiscalReceipt(PrintHeader: WordBool): Integer;
var
  AReceipt: TCustomReceipt;
begin
  try
    CheckEnabled;
    CheckState(FPTR_PS_MONITOR);

    AReceipt := CreateReceipt(FFiscalReceiptType);
    FReceipt.Free;
    FReceipt := AReceipt;
    FReceipt.BeginFiscalReceipt(PrintHeader);

    SetPrinterState(FPTR_PS_FISCAL_RECEIPT);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.BeginFixedOutput(Station,
  DocumentType: Integer): Integer;
begin
  Result := IllegalError;
end;

function TWebPrinterImpl.BeginInsertion(Timeout: Integer): Integer;
begin
  Result := IllegalError;
end;

function TWebPrinterImpl.BeginItemList(VatID: Integer): Integer;
begin
  Result := IllegalError;
end;

function TWebPrinterImpl.BeginNonFiscal: Integer;
begin
  try
    CheckEnabled;
    CheckState(FPTR_PS_MONITOR);
    SetPrinterState(FPTR_PS_NONFISCAL);
    FLines.Clear;

    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.BeginRemoval(Timeout: Integer): Integer;
begin
  Result := IllegalError;
end;

function TWebPrinterImpl.BeginTraining: Integer;
begin
  try
    CheckEnabled;
    CheckState(FPTR_PS_MONITOR);
    RaiseOposException(OPOS_E_ILLEGAL, _('Режим тренировки не поддерживается'));
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.CheckHealth(Level: Integer): Integer;
begin
  try
    CheckEnabled;
    //CheckPtr(Printer.CheckHealth(Level)); !!!
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.Claim(Timeout: Integer): Integer;
begin
  try
    FOposDevice.ClaimDevice(Timeout);
    //CheckPtr(Printer.ClaimDevice(Timeout)); !!!
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.ClaimDevice(Timeout: Integer): Integer;
begin
  Result := Claim(Timeout);
end;

function TWebPrinterImpl.ClearError: Integer;
begin
  Result := ClearResult;
end;

function TWebPrinterImpl.ClearOutput: Integer;
begin
  try
    FOposDevice.CheckClaimed;
    //CheckPtr(Printer.ClearOutput); !!!
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.Close: Integer;
begin
  Result := DoClose;
end;

function TWebPrinterImpl.CloseService: Integer;
begin
  Result := DoClose;
end;

function TWebPrinterImpl.COFreezeEvents(Freeze: WordBool): Integer;
begin
  try
    FOposDevice.FreezeEvents := Freeze;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.CompareFirmwareVersion(
  const FirmwareFileName: WideString; out pResult: Integer): Integer;
begin
  try
    CheckEnabled;
    Result := IllegalError;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.DirectIO(Command: Integer; var pData: Integer;
  var pString: WideString): Integer;
var
  i: Integer;
  TLVItem: TTLVItem;
  FieldName: WideString;
  FieldValue: WideString;
  SalesReceipt: TSalesReceipt;
begin
  try
    FOposDevice.CheckOpened;
    case Command of
      DIO_ADD_ITEM_CODE: Receipt.AddMarkCode(pString);
      DIO_SET_ITEM_BARCODE: Receipt.Barcode := pString;
      DIO_SET_ITEM_CLASS_CODE: Receipt.SetClassCode(pString);
      DIO_SET_ITEM_PACKAGE_CODE:
        Receipt.PackageCode := pData;

      DIO_SET_DRIVER_PARAMETER:
      begin
        case pData of
          DriverParameterBarcode: Receipt.AddMarkCode(pString);
        end;
      end;

      DIO_STLV_BEGIN:
      begin
        FTLVItems.Start(pData);
      end;

      // Write STLV
      DIO_STLV_WRITE:
      begin

      end;

      // Write STLV to operation
      DIO_STLV_WRITE_OP:
      begin
        for i := 0 to FTLVItems.Count-1 do
        begin
          TLVItem := FTLVItems[i];
          WriteOperationTag(TLVItem.ID, TLVItem.Data);
        end;
      end;

      DIO_STLV_ADD_TAG:
      begin
        FTLVItems.Add(pData, pString);
      end;

      DIO_WRITE_FS_STRING_TAG_OP:
      begin
        WriteOperationTag(pData, pString);
      end;
      DIO_SET_RECEIPT_QRCODE:
      begin
        Receipt.QRCode := pString;
      end;

      DIO_SET_RECITEM_JSON_FIELD:
      begin
        if Receipt is TSalesReceipt then
        begin
          SalesReceipt := Receipt as TSalesReceipt;
          FieldName := GetString(pString, 1, [';']);
          FieldValue := GetString(pString, 2, [';']);
          if FieldName <> '' then
          begin
            SalesReceipt.GetLastItem.JsonFields.Values[FieldName] := FieldValue;
          end;
        end;
      end;

      DIO_SET_RECEIPT_JSON_FIELD:
      begin
        if Receipt is TSalesReceipt then
        begin
          SalesReceipt := Receipt as TSalesReceipt;
          FieldName := GetString(pString, 1, [';']);
          FieldValue := GetString(pString, 2, [';']);
          if FieldName <> '' then
          begin
            SalesReceipt.JsonFields.Values[FieldName] := FieldValue;
          end;
        end;
      end;

      DIO_GET_RECEIPT_RESPONSE_FIELD:
      begin
        pString := GetJsonField2(FPrinter.CreateOrderResponse.ResponseJson, pString);
      end;

      DIO_GET_REQUEST_JSON_FIELD:
      begin
        pString := GetJsonField2(FPrinter.RequestJson, pString);
      end;

      DIO_GET_RESPONSE_JSON_FIELD:
      begin
        pString := GetJsonField2(FPrinter.ResponseJson, pString);
      end;

      DIO_READ_CASH_REG:
      begin
        pString := AmountToOutStr(ReadCashRegister(pData));
      end;
    end;

    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.ReadCashRegister(RegID: Integer): Currency;
var
  DayResult: TWPDayResult;
begin
  Result := 0;
  DayResult := FPrinter.CloseDayResponse2.result.data;

  case RegID of
    // 241 – накопление наличности в кассе;
    241: Result := Params.CashInECRAmount;

    // 242 – накопление внесений за смену;
    242: Result := Params.CashInAmount;

    // 243 – накопление выплат за смену;
    243: Result := Params.CashOutAmount;

    SMFPTR_CASHREG_DAY_TOTAL_SALE_CASH:
    begin
      Result := DayResult.total_sale_cash/100;
    end;

    SMFPTR_CASHREG_DAY_TOTAL_SALE_CARD:
    begin
      Result := DayResult.total_sale_card/100;
    end;

    SMFPTR_CASHREG_DAY_TOTAL_RETSALE_CASH:
    begin
      Result := DayResult.total_refund_cash/100;
    end;

    SMFPTR_CASHREG_DAY_TOTAL_RETSALE_CARD:
    begin
      Result := DayResult.total_refund_card/100;
    end;

    SMFPTR_CASHREG_GRAND_TOTAL_SALE_CASH:
    begin
      Result := DayResult.total_sale_cash/100 + Params.SalesAmountCash;
    end;

    SMFPTR_CASHREG_GRAND_TOTAL_SALE_CARD:
    begin
      Result := DayResult.total_sale_card/100 + Params.SalesAmountCard;
    end;

    SMFPTR_CASHREG_GRAND_TOTAL_RETSALE_CASH:
    begin
      Result := DayResult.total_refund_cash/100 + Params.RefundAmountCash;
    end;

    SMFPTR_CASHREG_GRAND_TOTAL_RETSALE_CARD:
    begin
      Result := DayResult.total_refund_card/100 + Params.RefundAmountCard;
    end;

    SMFPTR_CASHREG_DAY_TOTAL_SALE:
    begin
      Result := DayResult.total_sale_cash/100 + DayResult.total_sale_card/100;
    end;

    SMFPTR_CASHREG_DAY_TOTAL_RETSALE:
    begin
      Result := DayResult.total_refund_cash/100 + DayResult.total_refund_card/100;
    end;

    SMFPTR_CASHREG_GRAND_TOTAL_SALE:
    begin
      Result := DayResult.total_sale_cash/100 + DayResult.total_sale_card/100;
      Result := Result + Params.SalesAmountCash + Params.SalesAmountCard;
    end;

    SMFPTR_CASHREG_GRAND_TOTAL_RETSALE:
    begin
      Result := DayResult.total_refund_cash/100 + DayResult.total_refund_card/100;
      Result := Result + Params.RefundAmountCash + Params.RefundAmountCard;
    end;
  end;
end;

procedure TWebPrinterImpl.WriteOperationTag(pData: Integer; const pString: string);
begin
  case pData of
    1171: ; // номера контактных телефонов поставщика
    1222: ; // признак агента по предмету расчета
    1225: ; // наименование поставщика
    // ИНН поставщика '5213500887'
    1226: FReceipt.SetProviderINN(pString);
    1228: FReceipt.CustomerINN := pString;
    1008:
    begin
      if Pos('@', pString) <> 0 then
        FReceipt.CustomerEmail := pString
      else
        FReceipt.CustomerPhone := pString;
    end;
  end;
end;

function TWebPrinterImpl.DirectIO2(Command: Integer; const pData: Integer; const pString: WideString): Integer;
var
  pData2: Integer;
  pString2: WideString;
begin
  pData2 := pData;
  pString2 := pString;
  Result := DirectIO(Command, pData2, pString2);
end;

function TWebPrinterImpl.DirectIO3(Command: Integer; const pData: Integer;
  var pString: WideString): Integer;
var
  pData2: Integer;
begin
  pData2 := pData;
  Result := DirectIO(Command, pData2, pString);
end;

function TWebPrinterImpl.EndFiscalDocument: Integer;
begin
  Result := IllegalError;
end;

function TWebPrinterImpl.EndFiscalReceipt(PrintHeader: WordBool): Integer;
begin
  try
    FPrinterState.CheckState(FPTR_PS_FISCAL_RECEIPT_ENDING);

    FReceipt.EndFiscalReceipt(PrintHeader);
    FReceipt.Print(Self);

    SetPrinterState(FPTR_PS_MONITOR);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.EndFixedOutput: Integer;
begin
  Result := IllegalError;
end;

function TWebPrinterImpl.EndInsertion: Integer;
begin
  Result := IllegalError;
end;

function TWebPrinterImpl.EndItemList: Integer;
begin
  Result := IllegalError;
end;

function TWebPrinterImpl.EndNonFiscal: Integer;
var
  Text: TWPText;
  Banner: TWPBanner;
begin
  Text := TWPText.Create;
  try
    CheckEnabled;
    CheckState(FPTR_PS_NONFISCAL);
    SetPrinterState(FPTR_PS_MONITOR);


    Banner := Text.banners.Add as TWPBanner;
    Banner._type := 'text';
    Banner.data := FLines.Text;
    Banner.Cut := True;
    FPrinter.PrintText(Text);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
  Text.Free;
end;

function TWebPrinterImpl.EndRemoval: Integer;
begin
  Result := IllegalError;
end;

function TWebPrinterImpl.EndTraining: Integer;
begin
  try
    CheckEnabled;
    RaiseOposException(OPOS_E_ILLEGAL, _('Training mode is not active'));
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.Get_OpenResult: Integer;
begin
  Result := FOposDevice.OpenResult;
end;

(*
    Ftotal_sale_count: Int64;
    Ftotal_refund_count: Int64;
*)

function TWebPrinterImpl.GetData(DataItem: Integer; out OptArgs: Integer;
  out Data: WideString): Integer;
var
  Amount: Currency;
  DayResult: TWPDayResult;
begin
  try
    case DataItem of
      FPTR_GD_FIRMWARE: ;
      FPTR_GD_PRINTER_ID: Data := FPrinter.Info.Data.terminal_id;
      FPTR_GD_CURRENT_TOTAL: Data := AmountToOutStr(Receipt.GetTotal());
      FPTR_GD_DAILY_TOTAL: Data := AmountToOutStr(0);
      FPTR_GD_GRAND_TOTAL:
      begin
        DayResult := FPrinter.CloseDayResponse2.result.data;
        Amount := DayResult.total_sale_cash/100 - DayResult.total_refund_cash/100;
        Amount := Amount + Params.CashInAmount - Params.CashOutAmount;
        Data := AmountToOutStr(Amount);
      end;

      FPTR_GD_MID_VOID: Data := AmountToOutStr(0);
      FPTR_GD_NOT_PAID: Data := AmountToOutStr(0);
      FPTR_GD_RECEIPT_NUMBER:
      begin
        DayResult := FPrinter.CloseDayResponse2.result.data;
        Data := IntToStr(DayResult.total_sale_count);
      end;
      FPTR_GD_REFUND: Data := AmountToOutStr(0);
      FPTR_GD_REFUND_VOID: Data := AmountToOutStr(0);
      FPTR_GD_Z_REPORT: Data := IntToStr(FPrinter.Info.Data.zreport_count);
      FPTR_GD_FISCAL_REC: Data := AmountToOutStr(0);
      FPTR_GD_FISCAL_DOC,
      FPTR_GD_FISCAL_DOC_VOID,
      FPTR_GD_FISCAL_REC_VOID,
      FPTR_GD_NONFISCAL_DOC,
      FPTR_GD_NONFISCAL_DOC_VOID,
      FPTR_GD_NONFISCAL_REC,
      FPTR_GD_RESTART,
      FPTR_GD_SIMP_INVOICE,
      FPTR_GD_TENDER,
      FPTR_GD_LINECOUNT: Data := AmountToStr(0);
    else
      InvalidParameterValue('DataItem', IntToStr(DataItem));
    end;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.GetDate(out Date: WideString): Integer;
var
  Year, Month, Day, Hour, Minute, Second, MilliSecond: Word;
begin
  try
    case FDateType of
      FPTR_DT_RTC:
      begin
        DecodeDateTime(FPrinter.GetPrinterDate, Year, Month, Day, Hour, Minute, Second, MilliSecond);
        Date := Format('%.2d%.2d%.4d%.2d%.2d',[Day, Month, Year, Hour, Minute]);
      end;
    else
      InvalidPropertyValue('DateType', IntToStr(FDateType));
    end;

    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.GetOpenResult: Integer;
begin
  Result := FOposDevice.OpenResult;
end;

function TWebPrinterImpl.GetPropertyNumber(PropIndex: Integer): Integer;
begin
  try
    case PropIndex of
      // standard
      PIDX_Claimed                    : Result := BoolToInt[FOposDevice.Claimed];
      PIDX_DataEventEnabled           : Result := BoolToInt[FOposDevice.DataEventEnabled];
      PIDX_DeviceEnabled              : Result := BoolToInt[FOposDevice.DeviceEnabled];
      PIDX_FreezeEvents               : Result := BoolToInt[FOposDevice.FreezeEvents];
      PIDX_OutputID                   : Result := FOposDevice.OutputID;
      PIDX_ResultCode                 : Result := FOposDevice.ResultCode;
      PIDX_ResultCodeExtended         : Result := FOposDevice.ResultCodeExtended;
      PIDX_ServiceObjectVersion       : Result := FOposDevice.ServiceObjectVersion;
      PIDX_State                      : Result := FOposDevice.State;
      PIDX_BinaryConversion           : Result := FOposDevice.BinaryConversion;
      PIDX_DataCount                  : Result := FOposDevice.DataCount;
      PIDX_PowerNotify                : Result := FOposDevice.PowerNotify;
      PIDX_PowerState                 : Result := FOposDevice.PowerState;
      PIDX_CapPowerReporting          : Result := FOposDevice.CapPowerReporting;
      PIDX_CapStatisticsReporting     : Result := BoolToInt[FOposDevice.CapStatisticsReporting];
      PIDX_CapUpdateStatistics        : Result := BoolToInt[FOposDevice.CapUpdateStatistics];
      PIDX_CapCompareFirmwareVersion  : Result := BoolToInt[FOposDevice.CapCompareFirmwareVersion];
      PIDX_CapUpdateFirmware          : Result := BoolToInt[FOposDevice.CapUpdateFirmware];
      // specific
      PIDXFptr_AmountDecimalPlaces    : Result := AmountDecimalPlaces;
      PIDXFptr_AsyncMode              : Result := BoolToInt[FAsyncMode];
      PIDXFptr_CheckTotal             : Result := BoolToInt[FCheckTotal];
      PIDXFptr_CountryCode            : Result := FCountryCode;
      PIDXFptr_CoverOpen              : Result := BoolToInt[FCoverOpen];
      PIDXFptr_DayOpened              : Result := BoolToInt[FPrinter.DayOpened];
      PIDXFptr_DescriptionLength      : Result := Params.MessageLength;
      PIDXFptr_DuplicateReceipt       : Result := BoolToInt[FDuplicateReceipt];
      PIDXFptr_ErrorLevel             : Result := FErrorLevel;
      PIDXFptr_ErrorOutID             : Result := FErrorOutID;
      PIDXFptr_ErrorState             : Result := FErrorState;
      PIDXFptr_ErrorStation           : Result := FErrorStation;
      PIDXFptr_FlagWhenIdle           : Result := BoolToInt[FFlagWhenIdle];
      PIDXFptr_JrnEmpty               : Result := BoolToInt[FJrnEmpty];
      PIDXFptr_JrnNearEnd             : Result := BoolToInt[FJrnNearEnd];
      PIDXFptr_MessageLength          : Result := Params.MessageLength;
      PIDXFptr_NumHeaderLines         : Result := 0;
      PIDXFptr_NumTrailerLines        : Result := 0;
      PIDXFptr_NumVatRates            : Result := Params.VatRates.Count;
      PIDXFptr_PrinterState           : Result := FPrinterState.State;
      PIDXFptr_QuantityDecimalPlaces  : Result := FQuantityDecimalPlaces;
      PIDXFptr_QuantityLength         : Result := FQuantityLength;
      PIDXFptr_RecEmpty               : Result := BoolToInt[FRecEmpty];
      PIDXFptr_RecNearEnd             : Result := BoolToInt[FRecNearEnd];
      PIDXFptr_RemainingFiscalMemory  : Result := FRemainingFiscalMemory;
      PIDXFptr_SlpEmpty               : Result := BoolToInt[FSlpEmpty];
      PIDXFptr_SlpNearEnd             : Result := BoolToInt[FSlpNearEnd];
      PIDXFptr_SlipSelection          : Result := FSlipSelection;
      PIDXFptr_TrainingModeActive     : Result := BoolToInt[False];
      PIDXFptr_ActualCurrency         : Result := FActualCurrency;
      PIDXFptr_ContractorId           : Result := FContractorId;
      PIDXFptr_DateType               : Result := FDateType;
      PIDXFptr_FiscalReceiptStation   : Result := FFiscalReceiptStation;
      PIDXFptr_FiscalReceiptType      : Result := FFiscalReceiptType;
      PIDXFptr_MessageType                : Result := FMessageType;
      PIDXFptr_TotalizerType              : Result := FTotalizerType;
      PIDXFptr_CapAdditionalLines         : Result := BoolToInt[FCapAdditionalLines];
      PIDXFptr_CapAmountAdjustment        : Result := BoolToInt[FCapAmountAdjustment];
      PIDXFptr_CapAmountNotPaid           : Result := BoolToInt[FCapAmountNotPaid];
      PIDXFptr_CapCheckTotal              : Result := BoolToInt[FCapCheckTotal];
      PIDXFptr_CapCoverSensor             : Result := BoolToInt[FCapCoverSensor];
      PIDXFptr_CapDoubleWidth             : Result := BoolToInt[FCapDoubleWidth];
      PIDXFptr_CapDuplicateReceipt        : Result := BoolToInt[FCapDuplicateReceipt];
      PIDXFptr_CapFixedOutput             : Result := BoolToInt[FCapFixedOutput];
      PIDXFptr_CapHasVatTable             : Result := BoolToInt[FCapHasVatTable];
      PIDXFptr_CapIndependentHeader       : Result := BoolToInt[FCapIndependentHeader];
      PIDXFptr_CapItemList                : Result := BoolToInt[FCapItemList];
      PIDXFptr_CapJrnEmptySensor          : Result := BoolToInt[FCapJrnEmptySensor];
      PIDXFptr_CapJrnNearEndSensor        : Result := BoolToInt[FCapJrnNearEndSensor];
      PIDXFptr_CapJrnPresent              : Result := BoolToInt[FCapJrnPresent];
      PIDXFptr_CapNonFiscalMode           : Result := BoolToInt[FCapNonFiscalMode];
      PIDXFptr_CapOrderAdjustmentFirst    : Result := BoolToInt[FCapOrderAdjustmentFirst];
      PIDXFptr_CapPercentAdjustment       : Result := BoolToInt[FCapPercentAdjustment];
      PIDXFptr_CapPositiveAdjustment      : Result := BoolToInt[FCapPositiveAdjustment];
      PIDXFptr_CapPowerLossReport         : Result := BoolToInt[FCapPowerLossReport];
      PIDXFptr_CapPredefinedPaymentLines  : Result := BoolToInt[FCapPredefinedPaymentLines];
      PIDXFptr_CapReceiptNotPaid          : Result := BoolToInt[FCapReceiptNotPaid];
      PIDXFptr_CapRecEmptySensor          : Result := BoolToInt[FCapRecEmptySensor];
      PIDXFptr_CapRecNearEndSensor        : Result := BoolToInt[FCapRecNearEndSensor];
      PIDXFptr_CapRecPresent              : Result := BoolToInt[FCapRecPresent];
      PIDXFptr_CapRemainingFiscalMemory   : Result := BoolToInt[FCapRemainingFiscalMemory];
      PIDXFptr_CapReservedWord            : Result := BoolToInt[FCapReservedWord];
      PIDXFptr_CapSetHeader               : Result := BoolToInt[FCapSetHeader];
      PIDXFptr_CapSetPOSID                : Result := BoolToInt[FCapSetPOSID];
      PIDXFptr_CapSetStoreFiscalID        : Result := BoolToInt[FCapSetStoreFiscalID];
      PIDXFptr_CapSetTrailer              : Result := BoolToInt[FCapSetTrailer];
      PIDXFptr_CapSetVatTable             : Result := BoolToInt[FCapSetVatTable];
      PIDXFptr_CapSlpEmptySensor          : Result := BoolToInt[FCapSlpEmptySensor];
      PIDXFptr_CapSlpFiscalDocument       : Result := BoolToInt[FCapSlpFiscalDocument];
      PIDXFptr_CapSlpFullSlip             : Result := BoolToInt[FCapSlpFullSlip];
      PIDXFptr_CapSlpNearEndSensor        : Result := BoolToInt[FCapSlpNearEndSensor];
      PIDXFptr_CapSlpPresent              : Result := BoolToInt[FCapSlpPresent];
      PIDXFptr_CapSlpValidation           : Result := BoolToInt[FCapSlpValidation];
      PIDXFptr_CapSubAmountAdjustment     : Result := BoolToInt[FCapSubAmountAdjustment];
      PIDXFptr_CapSubPercentAdjustment    : Result := BoolToInt[FCapSubPercentAdjustment];
      PIDXFptr_CapSubtotal                : Result := BoolToInt[FCapSubtotal];
      PIDXFptr_CapTrainingMode            : Result := BoolToInt[FCapTrainingMode];
      PIDXFptr_CapValidateJournal         : Result := BoolToInt[FCapValidateJournal];
      PIDXFptr_CapXReport                 : Result := BoolToInt[FCapXReport];
      PIDXFptr_CapAdditionalHeader        : Result := BoolToInt[FCapAdditionalHeader];
      PIDXFptr_CapAdditionalTrailer       : Result := BoolToInt[FCapAdditionalTrailer];
      PIDXFptr_CapChangeDue               : Result := BoolToInt[FCapChangeDue];
      PIDXFptr_CapEmptyReceiptIsVoidable  : Result := BoolToInt[FCapEmptyReceiptIsVoidable];
      PIDXFptr_CapFiscalReceiptStation    : Result := BoolToInt[FCapFiscalReceiptStation];
      PIDXFptr_CapFiscalReceiptType       : Result := BoolToInt[FCapFiscalReceiptType];
      PIDXFptr_CapMultiContractor         : Result := BoolToInt[FCapMultiContractor];
      PIDXFptr_CapOnlyVoidLastItem        : Result := BoolToInt[FCapOnlyVoidLastItem];
      PIDXFptr_CapPackageAdjustment       : Result := BoolToInt[FCapPackageAdjustment];
      PIDXFptr_CapPostPreLine             : Result := BoolToInt[FCapPostPreLine];
      PIDXFptr_CapSetCurrency             : Result := BoolToInt[FCapSetCurrency];
      PIDXFptr_CapTotalizerType           : Result := BoolToInt[FCapTotalizerType];
      PIDXFptr_CapPositiveSubtotalAdjustment: Result := BoolToInt[FCapPositiveSubtotalAdjustment];
    else
      Result := 0;
    end;
  except
    on E: Exception do
    begin
      Result := 0;
      HandleException(E);
    end;
  end;
end;

function TWebPrinterImpl.GetPropertyString(PropIndex: Integer): WideString;
begin
  case PropIndex of
    // commmon
    PIDX_CheckHealthText                : Result := FOposDevice.CheckHealthText;
    PIDX_DeviceDescription              : Result := FOposDevice.PhysicalDeviceDescription;
    PIDX_DeviceName                     : Result := FOposDevice.PhysicalDeviceName;
    PIDX_ServiceObjectDescription       : Result := FOposDevice.ServiceObjectDescription;
    // specific
    PIDXFptr_ErrorString                : Result := FOposDevice.ErrorString;
    PIDXFptr_PredefinedPaymentLines     : Result := FPredefinedPaymentLines;
    PIDXFptr_ReservedWord               : Result := FReservedWord;
    PIDXFptr_AdditionalHeader           : Result := FAdditionalHeader;
    PIDXFptr_AdditionalTrailer          : Result := FAdditionalTrailer;
    PIDXFptr_ChangeDue                  : Result := FChangeDue;
    PIDXFptr_PostLine                   : Result := FPostLine;
    PIDXFptr_PreLine                    : Result := FPreLine;
  else
    Result := '';
  end;
end;

function TWebPrinterImpl.GetTotalizer(VatID, OptArgs: Integer;
  out Data: WideString): Integer;

  function ReadDailyTotal: Currency;
  var
    DayResult: TWPDayResult;
  begin
    DayResult := FPrinter.CloseDayResponse.data;
    Result := (
      DayResult.total_sale_cash +
      DayResult.total_sale_card -
      DayResult.total_refund_cash -
      DayResult.total_refund_card)/100;
  end;


  function ReadGrandTotalOnDayStart: Currency;
  begin
    Result :=
      Params.SalesAmountCash +
      Params.SalesAmountCard -
      Params.RefundAmountCash -
      Params.RefundAmountCard;
  end;

  function ReadGrossTotalizer(OptArgs: Integer): Currency;
  begin
    Result := 0;
    case OptArgs of
      FPTR_TT_DOCUMENT: Result := 0;
      FPTR_TT_DAY: Result := ReadDailyTotal;
      FPTR_TT_RECEIPT: Result := Receipt.GetTotal;
      FPTR_TT_GRAND: Result := ReadGrandTotalOnDayStart + ReadDailyTotal;
    else
      RaiseIllegalError;
    end;
  end;

begin
  try
    case VatID of
      FPTR_GT_GROSS: Data := AmountToOutStr(ReadGrossTotalizer(OptArgs));
      (*
      FPTR_GT_NET                      =  2;
      FPTR_GT_DISCOUNT                 =  3;
      FPTR_GT_DISCOUNT_VOID            =  4;
      FPTR_GT_ITEM                     =  5;
      FPTR_GT_ITEM_VOID                =  6;
      FPTR_GT_NOT_PAID                 =  7;
      FPTR_GT_REFUND                   =  8;
      FPTR_GT_REFUND_VOID              =  9;
      FPTR_GT_SUBTOTAL_DISCOUNT        =  10;
      FPTR_GT_SUBTOTAL_DISCOUNT_VOID   =  11;
      FPTR_GT_SUBTOTAL_SURCHARGES      =  12;
      FPTR_GT_SUBTOTAL_SURCHARGES_VOID =  13;
      FPTR_GT_SURCHARGE                =  14;
      FPTR_GT_SURCHARGE_VOID           =  15;
      FPTR_GT_VAT                      =  16;
      FPTR_GT_VAT_CATEGORY             =  17;
      *)
    end;

    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.GetVatEntry(VatID, OptArgs: Integer;
  out VatRate: Integer): Integer;
begin
  Result := ClearResult;
end;

function TWebPrinterImpl.Open(const DeviceClass, DeviceName: WideString;
  const pDispatch: IDispatch): Integer;
begin
  Result := DoOpen(DeviceClass, DeviceName, pDispatch);
end;

function TWebPrinterImpl.OpenService(const DeviceClass,
  DeviceName: WideString; const pDispatch: IDispatch): Integer;
begin
  Result := DoOpen(DeviceClass, DeviceName, pDispatch);
end;

function TWebPrinterImpl.PrintDuplicateReceipt: Integer;
begin
  try
    CheckEnabled;
    CheckState(FPTR_PS_MONITOR);
    FPrinter.PrintLastReceipt;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintFiscalDocumentLine(
  const DocumentLine: WideString): Integer;
begin
  Result := IllegalError;
end;

function TWebPrinterImpl.PrintFixedOutput(DocumentType, LineNumber: Integer;
  const Data: WideString): Integer;
begin
  Result := IllegalError;
end;

function TWebPrinterImpl.PrintNormal(Station: Integer;
  const AData: WideString): Integer;
begin
  try
    CheckEnabled;
    CheckState(FPTR_PS_NONFISCAL);
    FLines.Add(AData);

    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintPeriodicTotalsReport(const Date1,
  Date2: WideString): Integer;
begin
  Result := IllegalError;
end;

function TWebPrinterImpl.PrintPowerLossReport: Integer;
begin
  Result := IllegalError;
end;

function TWebPrinterImpl.PrintRecCash(Amount: Currency): Integer;
begin
  try
    FReceipt.PrintRecCash(Amount);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecItem(const Description: WideString;
  Price: Currency; Quantity, VatInfo: Integer; UnitPrice: Currency;
  const UnitName: WideString): Integer;
begin
  try
    CheckState(FPTR_PS_FISCAL_RECEIPT);
    FReceipt.PrintRecItem(Description, Price, GetQuantity(Quantity), VatInfo,
      UnitPrice, UnitName);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecItemAdjustment(AdjustmentType: Integer;
  const Description: WideString; Amount: Currency;
  VatInfo: Integer): Integer;
begin
  try
    CheckState(FPTR_PS_FISCAL_RECEIPT);
    CheckAdjustmentType(AdjustmentType);

    FReceipt.PrintRecItemAdjustment(AdjustmentType, Description, Amount, VatInfo);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecItemAdjustmentVoid(AdjustmentType: Integer;
  const Description: WideString; Amount: Currency;
  VatInfo: Integer): Integer;
begin
  try
    CheckState(FPTR_PS_FISCAL_RECEIPT);
    FReceipt.PrintRecItemAdjustmentVoid(AdjustmentType, Description,
      Amount, VatInfo);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecItemFuel(const Description: WideString;
  Price: Currency; Quantity, VatInfo: Integer; UnitPrice: Currency;
  const UnitName: WideString; SpecialTax: Currency;
  const SpecialTaxName: WideString): Integer;
begin
  try
    CheckState(FPTR_PS_FISCAL_RECEIPT);
    FReceipt.PrintRecItemFuel(Description, Price, GetQuantity(Quantity), VatInfo,
      UnitPrice, UnitName, SpecialTax, SpecialTaxName);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecItemFuelVoid(const Description: WideString;
  Price: Currency; VatInfo: Integer; SpecialTax: Currency): Integer;
begin
  try
    CheckState(FPTR_PS_FISCAL_RECEIPT);
    FReceipt.PrintRecItemFuelVoid(Description, Price, VatInfo, SpecialTax);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecItemRefund(const Description: WideString;
  Amount: Currency; Quantity, VatInfo: Integer; UnitAmount: Currency;
  const UnitName: WideString): Integer;
begin
  try
    CheckState(FPTR_PS_FISCAL_RECEIPT);
    FReceipt.PrintRecItemRefund(Description, Amount, GetQuantity(Quantity), VatInfo,
      UnitAmount, UnitName);
   Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecItemRefundVoid(
  const Description: WideString; Amount: Currency; Quantity,
  VatInfo: Integer; UnitAmount: Currency;
  const UnitName: WideString): Integer;
begin
  try
    CheckState(FPTR_PS_FISCAL_RECEIPT);
    FReceipt.PrintRecItemRefundVoid(Description, Amount, GetQuantity(Quantity), VatInfo,
      UnitAmount, UnitName);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecItemVoid(const Description: WideString;
  Price: Currency; Quantity, VatInfo: Integer; UnitPrice: Currency;
  const UnitName: WideString): Integer;
begin
  try
    CheckState(FPTR_PS_FISCAL_RECEIPT);
    FReceipt.PrintRecItemVoid(Description, Price, GetQuantity(Quantity), VatInfo,
      UnitPrice, UnitName);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecMessage(const Message: WideString): Integer;
begin
  try
    CheckEnabled;
    FReceipt.PrintRecMessage(Message);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecNotPaid(const Description: WideString;
  Amount: Currency): Integer;
begin
  try
    if not FCapReceiptNotPaid then
      RaiseOposException(OPOS_E_ILLEGAL, _('Not paid receipt is nor supported'));

    if (PrinterState <> FPTR_PS_FISCAL_RECEIPT_ENDING) and
      (PrinterState <> FPTR_PS_FISCAL_RECEIPT_TOTAL) then
      raiseExtendedError(OPOS_EFPTR_WRONG_STATE);

    FReceipt.PrintRecNotPaid(Description, Amount);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecPackageAdjustment(AdjustmentType: Integer;
  const Description, VatAdjustment: WideString): Integer;
begin
  try
    CheckState(FPTR_PS_FISCAL_RECEIPT);
    CheckAdjustmentType(AdjustmentType);

    FReceipt.PrintRecPackageAdjustment(AdjustmentType,
      Description, VatAdjustment);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecPackageAdjustVoid(AdjustmentType: Integer;
  const VatAdjustment: WideString): Integer;
begin
  try
    CheckState(FPTR_PS_FISCAL_RECEIPT);
    FReceipt.PrintRecPackageAdjustVoid(AdjustmentType, VatAdjustment);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecRefund(const Description: WideString;
  Amount: Currency; VatInfo: Integer): Integer;
begin
  try
    CheckState(FPTR_PS_FISCAL_RECEIPT);
    FReceipt.PrintRecRefund(Description, Amount, VatInfo);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecRefundVoid(const Description: WideString;
  Amount: Currency; VatInfo: Integer): Integer;
begin
  try
    CheckState(FPTR_PS_FISCAL_RECEIPT);
    FReceipt.PrintRecRefundVoid(Description, Amount, VatInfo);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecSubtotal(Amount: Currency): Integer;
begin
  try
    CheckState(FPTR_PS_FISCAL_RECEIPT);
    FReceipt.PrintRecSubtotal(Amount);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecSubtotalAdjustment(AdjustmentType: Integer;
  const Description: WideString; Amount: Currency): Integer;
begin
  try
    CheckState(FPTR_PS_FISCAL_RECEIPT);

    FReceipt.PrintRecSubtotalAdjustment(AdjustmentType, Description, Amount);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecSubtotalAdjustVoid(AdjustmentType: Integer;
  Amount: Currency): Integer;
begin
  try
    CheckState(FPTR_PS_FISCAL_RECEIPT);
    FReceipt.PrintRecSubtotalAdjustVoid(AdjustmentType, Amount);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecTaxID(const TaxID: WideString): Integer;
begin
  try
    CheckState(FPTR_PS_FISCAL_RECEIPT);
    FReceipt.PrintRecTaxID(TaxID);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecTotal(Total, Payment: Currency;
  const Description: WideString): Integer;
var
  PaymentType: Integer;
begin
  try
    if (PrinterState <> FPTR_PS_FISCAL_RECEIPT) and
      (PrinterState <> FPTR_PS_FISCAL_RECEIPT_TOTAL) then
      raiseExtendedError(OPOS_EFPTR_WRONG_STATE);

    if FCheckTotal and (FReceipt.GetTotal <> Total) then
    begin
      raiseExtendedError(OPOS_EFPTR_BAD_ITEM_AMOUNT,
        Format('App total %s, but receipt total %s', [
        AmountToStr(Total), AmountToStr(FReceipt.GetTotal)]));
    end;

    PaymentType := StrToIntDef(Description, 0);
    case PaymentType of
      0:;
      1: PaymentType := Params.PaymentType2;
      2: PaymentType := Params.PaymentType3;
      3: PaymentType := Params.PaymentType4;
    else
      PaymentType := PaymentTypeCash;
    end;

    FReceipt.PrintRecTotal(Total, Payment, IntToStr(PaymentType));
    if FReceipt.GetPayment >= FReceipt.GetTotal then
    begin
      SetPrinterState(FPTR_PS_FISCAL_RECEIPT_ENDING);
    end else
    begin
      SetPrinterState(FPTR_PS_FISCAL_RECEIPT_TOTAL);
    end;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecVoid(
  const Description: WideString): Integer;
begin
  try
    CheckEnabled;
    if (PrinterState <> FPTR_PS_FISCAL_RECEIPT) and
      (PrinterState <> FPTR_PS_FISCAL_RECEIPT_ENDING) and
      (PrinterState <> FPTR_PS_FISCAL_RECEIPT_TOTAL) then
      raiseExtendedError(OPOS_EFPTR_WRONG_STATE);

    FReceipt.PrintRecVoid(Description);
    SetPrinterState(FPTR_PS_FISCAL_RECEIPT_ENDING);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintRecVoidItem(const Description: WideString;
  Amount: Currency; Quantity, AdjustmentType: Integer;
  Adjustment: Currency; VatInfo: Integer): Integer;
begin
  try
    CheckState(FPTR_PS_FISCAL_RECEIPT);
    FReceipt.PrintRecVoidItem(Description, Amount, GetQuantity(Quantity),
      AdjustmentType, Adjustment, VatInfo);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.PrintReport(ReportType: Integer; const StartNum,
  EndNum: WideString): Integer;
begin
  Result := IllegalError;
end;

function TWebPrinterImpl.PrintXReport: Integer;
var
  Request: TWPCloseDayRequest;
begin
  Request := TWPCloseDayRequest.Create;
  try
    CheckState(FPTR_PS_MONITOR);

    Request.Time := FPrinter.GetPrinterDate;
    Request.close_zreport := False;
    Request.name := GetReportName('X ОТЧЁТ');
    AddReportLines(Request);

    FPrinter.PrintZReport(Request);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
  Request.Free;
end;

function TWebPrinterImpl.PrintZReport: Integer;
var
  Request: TWPCloseDayRequest;
  Response: TWPCloseDayResponse;
begin
  Request := TWPCloseDayRequest.Create;
  try
    CheckState(FPTR_PS_MONITOR);

    Request.Time := FPrinter.GetPrinterDate;
    Request.close_zreport := True;
    Request.name := GetReportName('Z ОТЧЁТ');
    AddReportLines(Request);

    FPrinter.RaiseErrors := False;
    try
      Response := FPrinter.PrintZReport(Request);
    finally
      FPrinter.RaiseErrors := True;
    end;
    if Response.error.code <> WP_ERROR_CURRENT_ZREPORT_IS_EMPTY then
      FPrinter.CheckForError(Response.error);

    // Clear Cash in and out
    Params.CashInAmount := 0;
    Params.CashOutAmount := 0;
    if Params.CashInECRAutoZero then
      Params.CashInECRAmount := 0;
    Params.SalesAmountCash := Params.SalesAmountCash + Response.data.total_sale_cash/100;
    Params.SalesAmountCard := Params.SalesAmountCard + Response.data.total_sale_card/100;
    Params.RefundAmountCash := Params.RefundAmountCash + Response.data.total_refund_cash/100;
    Params.RefundAmountCard := Params.RefundAmountCard + Response.data.total_refund_card/100;
    SaveUsrParameters(Params, FOposDevice.DeviceName, Logger);

    UpdateZReport;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
  Request.Free;
end;

function TWebPrinterImpl.GetReportName(const ReportName: WideString): WideString;
begin
  Result := ReportName + CRLF + GetTerminalID + CRLF +  GetPOSID;
end;

procedure TWebPrinterImpl.AddReportLines(Request: TWPCloseDayRequest);
var
  Item: TWPCurrency;
begin
  // Cashin
  Item := Request.prices.Add as TWPCurrency;
  Item.name := Params.CashInLine;
  Item.price := Round2(Params.CashInAmount * 100);
  // Cashout
  Item := Request.prices.Add as TWPCurrency;
  Item.name := Params.CashOutLine;
  Item.price := Round2(Params.CashOutAmount * 100);
  // Cash in ECR
  Item := Request.prices.Add as TWPCurrency;
  Item.name := Params.CashInECRLine;
  Item.price := Round2(Params.CashInECRAmount * 100);
  // Sales amount cash
  Item := Request.prices.Add as TWPCurrency;
  Item.name := Params.SalesAmountCashLine;
  Item.price := Round2(Params.SalesAmountCash * 100);
  // Sales amount card
  Item := Request.prices.Add as TWPCurrency;
  Item.name := Params.SalesAmountCardLine;
  Item.price := Round2(Params.SalesAmountCard * 100);
  // Refund amount cash
  Item := Request.prices.Add as TWPCurrency;
  Item.name := Params.RefundAmountCashLine;
  Item.price := Round2(Params.RefundAmountCash * 100);
  // Refund amount card
  Item := Request.prices.Add as TWPCurrency;
  Item.name := Params.RefundAmountCardLine;
  Item.price := Round2(Params.RefundAmountCard * 100);
end;

procedure TWebPrinterImpl.UpdateZReport;
begin
  FPrinter.SaveState;
  try
    FPrinter.ReadZReport;
  except
    on E: Exception do
    begin
      Logger.Error(E.Message);
    end;
  end;
  FPrinter.LoadState;
end;

function TWebPrinterImpl.Release1: Integer;
begin
  Result := DoRelease;
end;

function TWebPrinterImpl.ReleaseDevice: Integer;
begin
  Result := DoRelease;
end;

function TWebPrinterImpl.ResetPrinter: Integer;
begin
  try
    CheckEnabled;
    SetPrinterState(FPTR_PS_MONITOR);
    FReceipt.Free;
    FReceipt := TCustomReceipt.Create;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.ResetStatistics(
  const StatisticsBuffer: WideString): Integer;
begin
  Result := IllegalError;
end;

function TWebPrinterImpl.RetrieveStatistics(
  var pStatisticsBuffer: WideString): Integer;
begin
  Result := IllegalError;
end;

function TWebPrinterImpl.SetCurrency(NewCurrency: Integer): Integer;
begin
  try
    CheckEnabled;
    Result := IllegalError;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.SetDate(const Date: WideString): Integer;
begin
  try
    CheckEnabled;

    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.SetHeaderLine(LineNumber: Integer;
  const Text: WideString; DoubleWidth: WordBool): Integer;
begin
  try
    CheckEnabled;
    RaiseIllegalError('Not supported');

    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.SetPOSID(const POSID,
  CashierID: WideString): Integer;
begin
  FPOSID := POSID;
  FCashierID := CashierID;
  Result := ClearResult;
end;

procedure TWebPrinterImpl.SetPropertyNumber(PropIndex, Number: Integer);
begin
  try
    case PropIndex of
      // common
      PIDX_DeviceEnabled:
        SetDeviceEnabled(IntToBool(Number));

      PIDX_DataEventEnabled:
        FOposDevice.DataEventEnabled := IntToBool(Number);

      PIDX_PowerNotify:
      begin
        FOposDevice.PowerNotify := Number;
      end;

      PIDX_BinaryConversion:
      begin
        FOposDevice.BinaryConversion := Number;
      end;

      // Specific
      PIDXFptr_AsyncMode:
      begin
        FAsyncMode := IntToBool(Number);
      end;

      PIDXFptr_CheckTotal: FCheckTotal := IntToBool(Number);
      PIDXFptr_DateType: FDateType := Number;
      PIDXFptr_DuplicateReceipt: FDuplicateReceipt := IntToBool(Number);
      PIDXFptr_FiscalReceiptStation: FFiscalReceiptStation := Number;

      PIDXFptr_FiscalReceiptType:
      begin
        CheckState(FPTR_PS_MONITOR);
        FFiscalReceiptType := Number;
      end;
      PIDXFptr_FlagWhenIdle:
      begin
        FFlagWhenIdle := IntToBool(Number);
      end;
      PIDXFptr_MessageType:
        FMessageType := Number;
      PIDXFptr_SlipSelection:
        FSlipSelection := Number;
      PIDXFptr_TotalizerType:
        FTotalizerType := Number;
      PIDX_FreezeEvents:
      begin
        FOposDevice.FreezeEvents := Number <> 0;
      end;
    end;

    ClearResult;
  except
    on E: Exception do
      HandleException(E);
  end;
end;

procedure TWebPrinterImpl.SetPropertyString(PropIndex: Integer;
  const Text: WideString);
begin
  try
    FOposDevice.CheckOpened;
    case PropIndex of
      PIDXFptr_AdditionalHeader   : FAdditionalHeader := Text;
      PIDXFptr_AdditionalTrailer  : FAdditionalTrailer := Text;
      PIDXFptr_PostLine           : FPostLine := Text;
      PIDXFptr_PreLine            : FPreLine := Text;
      PIDXFptr_ChangeDue          : FChangeDue := Text;
    end;
    ClearResult;
  except
    on E: Exception do
      HandleException(E);
  end;
end;

function TWebPrinterImpl.SetStoreFiscalID(const ID: WideString): Integer;
begin
  try
    CheckEnabled;
    Result := IllegalError;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.SetTrailerLine(LineNumber: Integer;
  const Text: WideString; DoubleWidth: WordBool): Integer;
begin
  try
    CheckEnabled;
    RaiseIllegalError('Not supported');

    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.SetVatTable: Integer;
begin
  try
    CheckEnabled;
    CheckCapSetVatTable;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.SetVatValue(VatID: Integer;
  const VatValue: WideString): Integer;
var
  VatValueInt: Integer;
begin
  try
    CheckEnabled;
    CheckCapSetVatTable;
    // Check parameters
    if (VatID < 0)or(VatID >= Params.VatRates.Count) then
      InvalidParameterValue('VatID', IntToStr(VatID));
    VatValueInt := StrToInt(VatValue);
    if VatValueInt > 9999 then
      InvalidParameterValue('VatValue', VatValue);

    Params.VatRates[VatID].Rate := VatValueInt/100;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.UpdateFirmware(
  const FirmwareFileName: WideString): Integer;
begin
  try
    CheckEnabled;
    Result := IllegalError;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.UpdateStatistics(
  const StatisticsBuffer: WideString): Integer;
begin
  try
    CheckEnabled;
    Result := IllegalError;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.VerifyItem(const ItemName: WideString;
  VatID: Integer): Integer;
begin
  Result := IllegalError;
end;

function TWebPrinterImpl.DoOpen(const DeviceClass, DeviceName: WideString;
  const pDispatch: IDispatch): Integer;
begin
  try
    Initialize;
    FOposDevice.Open(DeviceClass, DeviceName, GetEventInterface(pDispatch));
    if not TestMode then
    begin
      LoadParameters(FParams, DeviceName, FLogger);
    end;

    Logger.MaxCount := FParams.LogMaxCount;
    Logger.Enabled := FParams.LogFileEnabled;
    Logger.FilePath := FParams.LogFilePath;
    Logger.DeviceName := DeviceName;

    FPrinter.Address := FParams.WebPrinterAddress;
    FPrinter.ConnectTimeout := FParams.ConnectTimeout;

    Logger.Debug(Logger.Separator);
    Logger.Debug('LOG START');
    Logger.Debug(FOposDevice.ServiceObjectDescription);
    Logger.Debug('ServiceObjectVersion : ' + IntToStr(FOposDevice.ServiceObjectVersion));
    Logger.Debug('File version         : ' + GetFileVersionInfoStr);
    Logger.Debug('System               : ' + GetSystemVersionStr);
    Logger.Debug('System locale        : ' + GetSystemLocaleStr);
    Logger.Debug(Logger.Separator);
    FParams.WriteLogParameters;

    FQuantityDecimalPlaces := 3;
    Result := ClearResult;
  except
    on E: Exception do
    begin
      DoCloseDevice;
      Result := HandleException(E);
    end;
  end;
end;

function TWebPrinterImpl.DoCloseDevice: Integer;
begin
  try
    Result := ClearResult;
    if not FOposDevice.Opened then Exit;

    SetDeviceEnabled(False);
    FOposDevice.Close;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
end;

function TWebPrinterImpl.GetEventInterface(FDispatch: IDispatch): IOposEvents;
begin
  Result := TOposEventsRCS.Create(FDispatch);
end;

function TWebPrinterImpl.HandleException(E: Exception): Integer;
var
  OPOSError: TOPOSError;
  OPOSException: EOPOSException;
begin
  if E is EDriverError then
  begin
    OPOSError := HandleDriverError(E as EDriverError);
    FOposDevice.HandleException(OPOSError);
    Result := OPOSError.ResultCode;
    Exit;
  end;

  if E is EOPOSException then
  begin
    OPOSException := E as EOPOSException;
    OPOSError.ErrorString := GetExceptionMessage(E);
    OPOSError.ResultCode := OPOSException.ResultCode;
    OPOSError.ResultCodeExtended := OPOSException.ResultCodeExtended;
    FOposDevice.HandleException(OPOSError);
    Result := OPOSError.ResultCode;
    Exit;
  end;

  OPOSError.ErrorString := GetExceptionMessage(E);
  OPOSError.ResultCode := OPOS_E_FAILURE;
  OPOSError.ResultCodeExtended := OPOS_SUCCESS;
  FOposDevice.HandleException(OPOSError);
  Result := OPOSError.ResultCode;
end;

function GetMaxRecLine(const RecLineCharsList: WideString): Integer;
var
  S: WideString;
  K: Integer;
  N: Integer;
begin
  K := 1;
  Result := 0;
  while true do
  begin
    S := GetString(RecLineCharsList, K, [',']);
    if S = '' then Break;
    N := StrToIntDef(S, 0);
    if N > Result then
      Result := N;
    Inc(K);
  end;
end;

procedure TWebPrinterImpl.SetDeviceEnabled(Value: Boolean);

  function IsCharacterSetSupported(const CharacterSetList: string;
    CharacterSet: Integer): Boolean;
  begin
    Result := Pos(IntToStr(CharacterSet), CharacterSetList) <> 0;
  end;

begin
  if Value <> FOposDevice.DeviceEnabled then
  begin
    if Value then
    begin
      FParams.CheckPrameters;
      if not TestMode then
      begin
        FPrinter.Connect;

        FOposDevice.PhysicalDeviceDescription := FOposDevice.PhysicalDeviceName +
          ' ' + FPrinter.DeviceDescription;
      end;
    end else
    begin
      FPrinter.Disconnect;
    end;
    FOposDevice.DeviceEnabled := Value;
  end;
end;

function TWebPrinterImpl.HandleDriverError(E: EDriverError): TOPOSError;
begin
  Result.ResultCode := OPOS_E_EXTENDED;
  Result.ErrorString := GetExceptionMessage(E);
  Result.ResultCodeExtended := E.ErrorCode;
end;

function TWebPrinterImpl.GetTerminalID: WideString;
begin
  Result := 'FM: ' + FPrinter.Info.Data.terminal_id
end;

function TWebPrinterImpl.GetPOSID: WideString;
begin
  Result := 'POS: ' + FPosID;
end;

procedure TWebPrinterImpl.Print(Receipt: TCashInReceipt);
var
  Text: TWPText;
  Line: WideString;
  Banner: TWPBanner;
  Lines: TTntStrings;
begin
  if Receipt.IsVoided then Exit;

  Text := TWPText.Create;
  Lines := TTntStringList.Create;
  try
    Lines.AddStrings(Receipt.Lines);
    Lines.Add(Params.CashInPreLine);
    Lines.Add(GetTerminalID);
    Lines.Add(GetPOSID);

    Line := AlignLines(Params.CashInLine, AmountToStrEq(Receipt.GetTotal), Params.MessageLength);
    Lines.Add(Line);
    Lines.Add(Params.CashInPostLine);

    Banner := Text.banners.Add as TWPBanner;
    Banner._type := 'text';
    Banner.data := Lines.Text;
    Banner.Cut := True;
    FPrinter.PrintText(Text);
    // Save cashin
    Params.CashInAmount := Params.CashInAmount + Receipt.GetTotal;
    Params.CashInECRAmount := Params.CashInECRAmount + Receipt.GetTotal;
    SaveUsrParameters(Params, FOposDevice.DeviceName, Logger);
    // Open cash drawer
    OpenCashDrawer;
  finally
    Text.Free;
    Lines.Free;
  end;
end;

procedure TWebPrinterImpl.Print(Receipt: TCashOutReceipt);
var
  Text: TWPText;
  Line: WideString;
  Banner: TWPBanner;
  Lines: TTntStrings;
begin
  if Receipt.IsVoided then Exit;

  Text := TWPText.Create;
  Lines := TTntStringList.Create;
  try
    Lines.AddStrings(Receipt.Lines);
    Lines.Add(Params.CashOutPreLine);
    Lines.Add(GetTerminalID);
    Lines.Add(GetPOSID);
    Line := AlignLines(Params.CashOutLine, AmountToStrEq(Receipt.GetTotal), Params.MessageLength);
    Lines.Add(Line);
    Lines.Add(Params.CashOutPostLine);

    Banner := Text.banners.Add as TWPBanner;
    Banner._type := 'text';
    Banner.data := Lines.Text;
    Banner.Cut := True;
    FPrinter.PrintText(Text);
    // Save cashout
    Params.CashOutAmount := Params.CashOutAmount + Receipt.GetTotal;
    Params.CashInECRAmount := Params.CashInECRAmount - Receipt.GetTotal;
    SaveUsrParameters(Params, FOposDevice.DeviceName, Logger);
    // Open cash drawer
    OpenCashDrawer;
  finally
    Text.Free;
    Lines.Free;
  end;
end;

procedure TWebPrinterImpl.UpdateRecItemFields(Product: TWPProduct; Fields: TTntStrings);
var
  i: Integer;
  FieldName: WideString;
  FieldValue: WideString;
begin
  for i := 0 to Fields.Count-1 do
  begin
    FieldName := Fields.Names[i];
    FieldValue := Fields.ValueFromIndex[i];

    if WideCompareText('name', FieldName) = 0 then
      Product.name := FieldValue;

    if WideCompareText('barcode', FieldName) = 0 then
      Product.barcode := FieldValue;

    if WideCompareText('amount', FieldName) = 0 then
      Product.amount := StrToInt64(FieldValue);

    if WideCompareText('units', FieldName) = 0 then
      Product.units := StrToInt(FieldValue);

    if WideCompareText('price', FieldName) = 0 then
      Product.price := StrToInt64(FieldValue);

    if WideCompareText('product_price', FieldName) = 0 then
      Product.product_price := StrToInt64(FieldValue);

    if WideCompareText('vat', FieldName) = 0 then
      Product.vat := StrToInt64(FieldValue);

    if WideCompareText('vat_percent', FieldName) = 0 then
      Product.vat_percent := StrToInt(FieldValue);

    if WideCompareText('discount', FieldName) = 0 then
      Product.discount := StrToInt64(FieldValue);

    if WideCompareText('discount_percent', FieldName) = 0 then
      Product.discount_percent := StrToInt(FieldValue);

    if WideCompareText('other', FieldName) = 0 then
      Product.other := StrToInt64(FieldValue);

    if WideCompareText('class_code', FieldName) = 0 then
      Product.class_code := FieldValue;

    if WideCompareText('package_code', FieldName) = 0 then
      Product.package_code := StrToInt(FieldValue);

    if WideCompareText('owner_type', FieldName) = 0 then
      Product.owner_type := StrToInt(FieldValue);

    if WideCompareText('comission_info.inn', FieldName) = 0 then
      Product.comission_info.inn := FieldValue;

    if WideCompareText('comission_info.pinfl', FieldName) = 0 then
      Product.comission_info.pinfl := FieldValue;
  end;
  Fields.Clear;
end;

procedure TWebPrinterImpl.UpdateReceiptFields(Order: TWPOrder; Fields: TTntStrings);
var
  i: Integer;
  FieldName: WideString;
  FieldValue: WideString;
begin
  for i := 0 to Fields.Count-1 do
  begin
    FieldName := Fields.Names[i];
    FieldValue := Fields.ValueFromIndex[i];

    if WideCompareText('qr_code', FieldName) = 0 then
      Order.qr_code := FieldValue;

    if WideCompareText('number', FieldName) = 0 then
      Order.number := StrToInt(FieldValue);

    if WideCompareText('receipt_type', FieldName) = 0 then
      Order.receipt_type := FieldValue;

    if WideCompareText('time', FieldName) = 0 then
      Order.time := FieldValue;

    if WideCompareText('cashier', FieldName) = 0 then
      Order.cashier := FieldValue;

    if WideCompareText('received_cash', FieldName) = 0 then
      Order.received_cash := StrToInt64(FieldValue);

    if WideCompareText('change', FieldName) = 0 then
      Order.change := StrToInt64(FieldValue);

    if WideCompareText('received_card', FieldName) = 0 then
      Order.received_card := StrToInt(FieldValue);

    if WideCompareText('card_type', FieldName) = 0 then
      Order.card_type := StrToInt(FieldValue);

    if WideCompareText('ppt_id', FieldName) = 0 then
      Order.ppt_id := StrToInt(FieldValue);

    if WideCompareText('open_cashbox', FieldName) = 0 then
      Order.open_cashbox := StrToBool(FieldValue);

    if WideCompareText('send_email', FieldName) = 0 then
      Order.send_email := StrToBool(FieldValue);

    if WideCompareText('email', FieldName) = 0 then
      Order.email := FieldValue;

    if WideCompareText('sms_phone_number', FieldName) = 0 then
      Order.sms_phone_number := FieldValue;
  end;
  Fields.Clear;
end;

procedure TWebPrinterImpl.Print(Receipt: TSalesReceipt);

  function GetUnitCode(const UnitName: WideString): Integer;
  var
    Item: TItemUnit;
  begin
    Result := WP_UNIT_PEACE;
    Item := Params.ItemUnits.ItemByName(UnitName);
    if Item <> nil then
      Result := Item.Code;
  end;

  function GetVatRate(VatInfo: Integer): Double;
  var
    VatRate: TVatRate;
  begin
    Result := 0;
    if not Params.VatRateEnabled then Exit;
    VatRate := Params.VatRates.ItemByCode(VatInfo);
    if VatRate <> nil then
    begin
      Result := VatRate.Rate;
    end;
  end;

var
  i: Integer;
  Order: TWPOrder;
  VatRate: Double;
  Banner: TWPBanner;
  Product: TWPProduct;
  TextItem: TRecTextItem;
  Item: TSalesReceiptItem;
  ReceiptItem: TReceiptItem;
  CashPayment: Currency;
begin
  RecDiscountsToItemDiscounts(Receipt);

  Order := TWPOrder.Create;
  try
	  Order.Number := 1;
	  Order.Receipt_type := WP_RECEIPT_TYPE_ORDER;
	  Order.Time := WPDateTimeToStr(FPrinter.GetPrinterDate);
	  Order.Cashier := FCashierID;
	  Order.Received_cash := Round2(Receipt.GetCashPayment * 100);
	  Order.Received_card := Round2(Receipt.GetCashlessPayment * 100);
    Order.card_type := 0;
    Order.ppt_id := 0;
	  Order.change := Round2(Receipt.Change * 100);
	  Order.Open_cashbox := Params.OpenCashbox and (Order.Received_cash <> 0);
	  Order.Send_email := Receipt.CustomerEmail <> '';
	  Order.Email := Receipt.CustomerEmail;
	  Order.sms_phone_number := Receipt.CustomerPhone;
    Order.qr_code := Receipt.QrCode;
    // Items
    for i := 0 to Receipt.Items.Count-1 do
    begin
      ReceiptItem := Receipt.Items[i];
      if ReceiptItem is TSalesReceiptItem then
      begin
        Item := ReceiptItem as TSalesReceiptItem;
        VatRate := GetVatRate(Item.VatInfo);

        Product := Order.products.Add as TWPProduct;
        Product.Name := Item.Description;
        Product.Amount := Round2(Item.Quantity * 1000);
        Product.Barcode := Item.Barcode;
        Product.Units := GetUnitCode(Item.UnitName);
        Product.unit_name := Item.UnitName;
        Product.Price := Round2(Item.Price * 100);
        Product.Product_price := Round2(Item.UnitPrice * 100);
        Product.vat_percent := Round(VatRate);
        Product.discount := Abs(Round2(Item.Discounts.GetTotal * 100));
        Product.vat := Round2(Item.GetVatAmount(VatRate) * 100);
        Product.discount_percent := Round(Item.GetDiscountPercent);
        Product.other := 0;
        Product.Labels.Assign(Item.MarkCodes);
        Product.Class_code := Item.ClassCode;
        Product.Package_code := Item.PackageCode;
        Product.Owner_type := 0;
        Product.Comission_info.inn := Item.ProviderINN;
        Product.Comission_info.pinfl := '';
        UpdateRecItemFields(Product, Item.JsonFields);
      end;
      // Banners
      if ReceiptItem is TRecTextItem then
      begin
        TextItem := ReceiptItem as TRecTextItem;
        Banner := Order.banners.Add as TWPBanner;
        Banner._type := 'text';
        Banner.data := TextItem.Text;
      end;
    end;
    // Apply receipt fields
    UpdateReceiptFields(Order, Receipt.JsonFields);

    if receipt.RecType in [rtSell, rtRetBuy] then
    begin
      CashPayment := Abs(Receipt.CashPayment);
      FPrinter.CreateOrder(Order);
    end else
    begin
      CashPayment := -Abs(Receipt.CashPayment);
      FPrinter.ReturnOrder(Order);
    end;
    Params.CashInECRAmount := Params.CashInECRAmount + CashPayment;
    SaveUsrParameters(Params, FOposDevice.DeviceName, Logger);
    UpdateZReport;
  finally
    Order.Free;
  end;
end;

procedure TWebPrinterImpl.RecDiscountsToItemDiscounts(Receipt: TSalesReceipt);
var
  i: Integer;
  Item: TSalesReceiptItem;
  ItemDiscount: Currency;
  ReceiptDiscount: Currency;
  Adjustment: TAdjustment;
begin
  ReceiptDiscount := Receipt.Discount;
  if ReceiptDiscount = 0 then Exit;

  for i := 0 to Receipt.Items.Count-1 do
  begin
    if Receipt.Items[i] is TSalesReceiptItem then
    begin
      Item := Receipt.Items[i] as TSalesReceiptItem;
      ItemDiscount := Abs(Item.Discounts.GetTotal);
      if (not Params.RecDiscountOnClassCode) or Params.ClassCodeDiscountEnabled(Item.GetClassCode) then
      begin
        if (ReceiptDiscount <> 0) and (Item.Price >= (ItemDiscount + ReceiptDiscount)) then
        begin
          Adjustment := Item.AddDiscount;
          Adjustment.Amount := RoundAmount(ReceiptDiscount);
          Adjustment.Total := -RoundAmount(ReceiptDiscount);
          Adjustment.VatInfo := Item.VatInfo;
          Adjustment.Description := '';
          Adjustment.AdjustmentType := FPTR_AT_AMOUNT_DISCOUNT;
          Break;
        end;
      end;
    end;
  end;
end;

end.

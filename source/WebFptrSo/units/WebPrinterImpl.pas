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
  WebFptrSO_TLB, MathUtils, ItemUnit;

const
  AmountDecimalPlaces = 2;
  FPTR_DEVICE_DESCRIPTION = 'WebPrinter OPOS driver';

type
  { TWebPrinterImpl }

  TWebPrinterImpl = class(TComponent, IFiscalPrinterService_1_12)
  private
    FLogger: ILogFile;
    FPrinter: TWebPrinter;
    FReceipt: TCustomReceipt;
    FParams: TPrinterParameters;
    FOposDevice: TOposServiceDevice19;
    FPrinterState: TFiscalPrinterState;

    FTestMode: Boolean;
    FPOSID: WideString;
    FTimeDiff: TDateTime;
    FCashierID: WideString;
    FCheckNumber: WideString;
    FLoadParamsEnabled: Boolean;
    function GetPrinterDate: TDateTime;
    procedure OpenFiscalDay;
  public
    function AmountToStr(Value: Currency): AnsiString;
    function AmountToOutStr(Value: Currency): AnsiString;
    function AmountToStrEq(Value: Currency): AnsiString;
  public
    procedure Initialize;
    procedure CheckEnabled;
    function IllegalError: Integer;
    procedure CheckState(AState: Integer);
    procedure SetPrinterState(Value: Integer);
    function DoClose: Integer;
    procedure Print(Receipt: TCashInReceipt); overload;
    procedure Print(Receipt: TCashOutReceipt); overload;
    procedure Print(Receipt: TSalesReceipt); overload;
    function GetPrinterState: Integer;
    function DoRelease: Integer;
    procedure CheckCapSetVatTable;
    function CreateReceipt(FiscalReceiptType: Integer): TCustomReceipt;
    function GetQuantity(Value: Integer): Double;

    property Receipt: TCustomReceipt read FReceipt;
    property PrinterState: Integer read GetPrinterState write SetPrinterState;
  private
    FPostLine: WideString;
    FPreLine: WideString;
    FCheckTotal: Boolean;
    // boolean
    FDayOpened: Boolean;
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
    FRecLineChars: Integer;
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
    property LoadParamsEnabled: Boolean read FLoadParamsEnabled write FLoadParamsEnabled;
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
  FReceipt := TCustomReceipt.Create;
  FPrinter := TWebPrinter.Create(FLogger);
  FParams := TPrinterParameters.Create(FLogger);
  FOposDevice := TOposServiceDevice19.Create(FLogger);
  FOposDevice.ErrorEventEnabled := False;
  FPrinterState := TFiscalPrinterState.Create;
  FLoadParamsEnabled := True;
  FTimeDiff := 0;
end;

destructor TWebPrinterImpl.Destroy;
begin
  if FOposDevice.Opened then
    Close;

  FParams.Free;
  FReceipt.Free;
  FPrinter.Free;
  FOposDevice.Free;
  FPrinterState.Free;
  inherited Destroy;
end;

function TWebPrinterImpl.GetPrinterDate: TDateTime;
begin
  Result := Now + FTimeDiff;
end;

function TWebPrinterImpl.AmountToStr(Value: Currency): AnsiString;
begin
  Result := Format('%.*f', [2, Value]);
(*
  if Params.AmountDecimalPlaces = 0 then
  begin
    Result := IntToStr(Round(Value));
  end else
  begin
    Result := Format('%.*f', [Params.AmountDecimalPlaces, Value]);
  end;
*)
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
  FDayOpened := False;
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
  FCapSetVatTable := False;
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
begin
  try
    CheckEnabled;
    CheckState(FPTR_PS_MONITOR);
    SetPrinterState(FPTR_PS_FISCAL_RECEIPT);

    FReceipt.Free;
    FReceipt := CreateReceipt(FFiscalReceiptType);
    FReceipt.BeginFiscalReceipt(PrintHeader);

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
    RaiseOposException(OPOS_E_ILLEGAL, _('����� ���������� �� ��������������'));
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
begin
  try
    FOposDevice.CheckOpened;
    case Command of
      DIO_ADD_ITEM_CODE: Receipt.AddMarkCode(pString);
      DIO_SET_ITEM_BARCODE: Receipt.Barcode := pString;
      DIO_SET_ITEM_CLASS_CODE: Receipt.SetClassCode(pString);
      DIO_SET_ITEM_PACKAGE_CODE: Receipt.PackageCode := pData;

      DIO_SET_DRIVER_PARAMETER:
      begin
        case pData of
          DriverParameterBarcode: Receipt.Barcode := pString;
        end;
      end;

      DIO_WRITE_FS_STRING_TAG_OP:
      begin
        case pData of
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
    end;

    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
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

function TWebPrinterImpl.EndFiscalDocument: Integer;
begin
  Result := IllegalError;
end;

procedure TWebPrinterImpl.OpenFiscalDay;
begin
  if not FDayOpened then
  begin
    FPrinter.OpenFiscalDay2(GetPrinterDate);
    FDayOpened := True;
  end;
end;

function TWebPrinterImpl.EndFiscalReceipt(PrintHeader: WordBool): Integer;
begin
  try
    FPrinterState.CheckState(FPTR_PS_FISCAL_RECEIPT_ENDING);
    OpenFiscalDay;

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
begin
  try
    CheckEnabled;
    CheckState(FPTR_PS_NONFISCAL);
    SetPrinterState(FPTR_PS_MONITOR);
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
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
begin
  try
    case DataItem of
      FPTR_GD_FIRMWARE: ;
      FPTR_GD_PRINTER_ID: Data := FPrinter.Info.Data.terminal_id;
      FPTR_GD_CURRENT_TOTAL: Data := AmountToOutStr(Receipt.GetTotal());
      //FPTR_GD_DAILY_TOTAL: Data := AmountToOutStr(ReadDailyTotal);
      //FPTR_GD_GRAND_TOTAL: Data := AmountToOutStr(ReadGrandTotal);
      FPTR_GD_MID_VOID: Data := AmountToOutStr(0);
      FPTR_GD_NOT_PAID: Data := AmountToOutStr(0);
      FPTR_GD_RECEIPT_NUMBER: Data := FCheckNumber;
      //FPTR_GD_REFUND: Data := AmountToOutStr(ReadRefundTotal);
      FPTR_GD_REFUND_VOID: Data := AmountToOutStr(0);
      FPTR_GD_Z_REPORT: Data := IntToStr(FPrinter.Info.Data.zreport_count);
      //FPTR_GD_FISCAL_REC: Data := AmountToOutStr(ReadSellTotal);
      FPTR_GD_FISCAL_DOC,
      FPTR_GD_FISCAL_DOC_VOID,
      FPTR_GD_FISCAL_REC_VOID,
      FPTR_GD_NONFISCAL_DOC,
      FPTR_GD_NONFISCAL_DOC_VOID,
      FPTR_GD_NONFISCAL_REC,
      FPTR_GD_RESTART,
      FPTR_GD_SIMP_INVOICE,
      FPTR_GD_TENDER,
      FPTR_GD_LINECOUNT:
        Data := AmountToStr(0);
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
        DecodeDateTime(GetPrinterDate, Year, Month, Day, Hour, Minute, Second, MilliSecond);
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
      PIDXFptr_DayOpened              : Result := BoolToInt[FDayOpened];
      PIDXFptr_DescriptionLength      : Result := FRecLineChars;
      PIDXFptr_DuplicateReceipt       : Result := BoolToInt[FDuplicateReceipt];
      PIDXFptr_ErrorLevel             : Result := FErrorLevel;
      PIDXFptr_ErrorOutID             : Result := FErrorOutID;
      PIDXFptr_ErrorState             : Result := FErrorState;
      PIDXFptr_ErrorStation           : Result := FErrorStation;
      PIDXFptr_FlagWhenIdle           : Result := BoolToInt[FFlagWhenIdle];
      PIDXFptr_JrnEmpty               : Result := BoolToInt[FJrnEmpty];
      PIDXFptr_JrnNearEnd             : Result := BoolToInt[FJrnNearEnd];
      PIDXFptr_MessageLength          : Result := FRecLineChars;
      PIDXFptr_NumHeaderLines         : Result := 0;
      PIDXFptr_NumTrailerLines        : Result := 0;
      PIDXFptr_NumVatRates            : Result := 0;
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


  function ReadGrossTotalizer(OptArgs: Integer): Currency;
  begin
    Result := 0;
    case OptArgs of
      FPTR_TT_DOCUMENT: Result := 0;
      FPTR_TT_DAY: Result := ReadDailyTotal;
      FPTR_TT_RECEIPT: Result := Receipt.GetTotal;
      //FPTR_TT_GRAND: Result := ReadGrandTotal;
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

    OpenFiscalDay;
    Request.Time := GetPrinterDate;
    Request.close_zreport := False;
    Request.name := 'X ��ר�';
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
begin
  Request := TWPCloseDayRequest.Create;
  try
    CheckState(FPTR_PS_MONITOR);

    OpenFiscalDay;
    Request.Time := GetPrinterDate;
    Request.close_zreport := True;
    Request.name := 'Z ��ר�';
    FPrinter.PrintZReport(Request);
    FDayOpened := False;
    Result := ClearResult;
  except
    on E: Exception do
      Result := HandleException(E);
  end;
  Request.Free;
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
    if FLoadParamsEnabled then
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

var
  PrinterTime: TDateTime;
begin
  if Value <> FOposDevice.DeviceEnabled then
  begin
    if Value then
    begin
      FParams.CheckPrameters;
      FPrinter.Connect;

      FDayOpened := FPrinter.ReadZReport.result.data.open_time <> '';
      PrinterTime := WPStrToDateTime(FPrinter.Info.Data.current_time);
      FTimeDiff := PrinterTime - Now;

      FOposDevice.PhysicalDeviceDescription := FOposDevice.PhysicalDeviceName +
        Format(' terminal_id: %s, applet_version: %s, version_code: %s',
        [FPrinter.Info.Data.terminal_id, FPrinter.Info.Data.applet_version,
        FPrinter.Info.Data.version_code]);
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

procedure TWebPrinterImpl.Print(Receipt: TCashInReceipt);
begin
  { !!! }
end;

procedure TWebPrinterImpl.Print(Receipt: TCashOutReceipt);
begin
  { !!! }
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
  Product: TWPProduct;
  //Adjustment: TAdjustment;
  Item: TSalesReceiptItem;
  ReceiptItem: TReceiptItem;
begin
  Order := TWPOrder.Create;
  try
	  Order.Number := 1;
	  Order.Receipt_type := WP_RECEIPT_TYPE_ORDER;
	  Order.Time := WPDateTimeToStr(GetPrinterDate);
	  Order.Cashier := FCashierID;
	  Order.Received_cash := Round2(Receipt.GetCashPayment * 100);
	  Order.Received_card := Round2(Receipt.GetCashlessPayment * 100);
	  Order.change := Round2(Receipt.Change * 100);
	  Order.Open_cashbox := Params.OpenCashbox;
	  Order.Send_email := Receipt.CustomerEmail <> '';
	  Order.Email := Receipt.CustomerEmail;
	  Order.sms_phone_number := Receipt.CustomerPhone;

    // Items
    for i := 0 to Receipt.Items.Count-1 do
    begin
      ReceiptItem := Receipt.Items[i];
      if ReceiptItem is TSalesReceiptItem then
      begin
        Item := ReceiptItem as TSalesReceiptItem;
        Product := Order.products.Add as TWPProduct;
        Product.Name := Item.Description;
        Product.Amount := Round2(Item.Quantity * 1000);
        Product.Barcode := Item.Barcode;
        Product.Units := GetUnitCode(Item.UnitName);
        Product.Price := Round2(Item.Price * 100);
        Product.Product_price := Round2(Item.UnitPrice * 100);

        VatRate := GetVatRate(Item.VatInfo);
        Product.VAT := Round2(Item.GetVatAmount(VatRate) * 100);
        Product.vat_percent := Round(VatRate);

        Product.discount := Abs(Round2((Item.Discounts.GetTotal - Item.Charges.GetTotal) * 100));
        Product.Discount_percent := Round(Item.GetDiscountPercent);
        Product.Other := 0;
        Product.Labels.Assign(Item.MarkCodes);
        Product.Class_code := Item.ClassCode;
        Product.Package_code := Item.PackageCode;
        Product.Owner_type := 0;
        Product.Comission_info.inn := '';
        Product.Comission_info.pinfl := '';
      end;
    end;
    FPrinter.CreateOrder(Order);
  finally
    Order.Free;
  end;
end;

end.

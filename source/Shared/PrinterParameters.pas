unit PrinterParameters;

interface

uses
  // VCL
  Windows, SysUtils, Classes,
  // 3'd
  TntClasses, TntStdCtrls, TntRegistry,
  // Opos
  Opos, Oposhi, OposException,
  // This
  WException, LogFile, FileUtils, VatRate, ReceiptItem, ItemUnit, StringUtils;

const
  /////////////////////////////////////////////////////////////////////////////
  // Encoding constants

  EncodingWindows       = 0;
  Encoding866           = 1;

  EncodingMin = EncodingWindows;
  EncodingMax = Encoding866;

  MinMessageLength = 24;
  MaxMessageLength = 120;
  DefMessageLength = 80;

  FiscalPrinterProgID = 'OposWebPrinter.FiscalPrinter';

  DefLogMaxCount = 10;
  DefLogFileEnabled = True;
  DefConnectTimeout = 10;
  DefWebPrinterAddress = 'http://fbox.ngrok.io';
  DefVatRateEnabled = True;
  DefCashInECRAutoZero = True;

type
  { TCashParams }

  TCashParams = record
    Line: WideString;
    PreLine: WideString;
    PostLine: WideString;
  end;

  { TPrinterParameters }

  TPrinterParameters = class(TPersistent)
  private
    FLogger: ILogFile;
    FLogMaxCount: Integer;
    FLogFileEnabled: Boolean;
    FLogFilePath: WideString;
    FWebPrinterAddress: WideString;
    FConnectTimeout: Integer;
    FPaymentType2: Integer;
    FPaymentType3: Integer;
    FPaymentType4: Integer;
    FVatRates: TVatRates;
    FItemUnits: TItemUnits;
    FVatRateEnabled: Boolean;
    FOpenCashbox: Boolean;
    FMessageLength: Integer;
    FCashIn: TCashParams;
    FCashout: TCashParams;
    FCashInAmount: Currency;
    FCashOutAmount: Currency;
    FCashInECRLine: WideString;
    FSalesAmountCash: Currency; // Âñåãî ïğîäàæ íàëè÷íûå
    FSalesAmountCard: Currency; // Âñåãî ïğîäàæ áàíêîâñêèå êàğòû
    FRefundAmountCash: Currency; // Âñåãî âîçâğàòîâ íàëè÷íûå
    FRefundAmountCard: Currency; // Âñåãî âîçâğàòîâ áàíêîâñèå êàğòû
    FClassCodes: TStrings;

    procedure SetMessageLength(const Value: Integer);
    procedure SetClassCodes(const Value: TStrings);
  public
    CashInECRAutoZero: Boolean;
    SalesAmountCashLine: WideString; // Âñåãî ïğîäàæ íàëè÷íûå
    SalesAmountCardLine: WideString; // Âñåãî ïğîäàæ áàíêîâñêèå êàğòû
    RefundAmountCashLine: WideString; // Âñåãî âîçâğàòîâ íàëè÷íûå
    RefundAmountCardLine: WideString; // Âñåãî âîçâğàòîâ áàíêîâñèå êàğòû
    RecDiscountOnClassCode: Boolean;

    constructor Create(ALogger: ILogFile);
    destructor Destroy; override;

    procedure SetDefaults;
    procedure CheckPrameters;
    procedure WriteLogParameters;
    procedure Load(const DeviceName: WideString);
    procedure Save(const DeviceName: WideString);
    procedure Assign(Source: TPersistent); override;
    function ClassCodeDiscountEnabled(const ClassCode: string): Boolean;

    property ItemUnits: TItemUnits read FItemUnits;
    property Logger: ILogFile read FLogger;
    property VatRates: TVatRates read FVatRates;
    property VatRateEnabled: Boolean read FVatRateEnabled write FVatRateEnabled;
    property ConnectTimeout: Integer read FConnectTimeout write FConnectTimeout;
    property WebPrinterAddress: WideString read FWebPrinterAddress write FWebPrinterAddress;
    property LogMaxCount: Integer read FLogMaxCount write FLogMaxCount;
    property LogFilePath: WideString read FLogFilePath write FLogFilePath;
    property LogFileEnabled: Boolean read FLogFileEnabled write FLogFileEnabled;
    property PaymentType2: Integer read FPaymentType2 write FPaymentType2;
    property PaymentType3: Integer read FPaymentType3 write FPaymentType3;
    property PaymentType4: Integer read FPaymentType4 write FPaymentType4;
    property OpenCashbox: Boolean read FOpenCashbox write FOpenCashbox;
    property MessageLength: Integer read FMessageLength write SetMessageLength;
    property CashInLine: WideString read FCashin.Line write FCashin.Line;
    property CashInPreLine: WideString read FCashin.PreLine write FCashin.PreLine;
    property CashInPostLine: WideString read FCashin.PostLine write FCashin.PostLine;
    property CashoutLine: WideString read FCashout.Line write FCashout.Line;
    property CashoutPreLine: WideString read FCashout.PreLine write FCashout.PreLine;
    property CashoutPostLine: WideString read FCashout.PostLine write FCashout.PostLine;
    property CashInAmount: Currency read FCashInAmount write FCashInAmount;
    property CashOutAmount: Currency read FCashOutAmount write FCashOutAmount;
    property CashInECRLine: WideString read FCashInECRLine write FCashInECRLine;
    property SalesAmountCash: Currency read FSalesAmountCash write FSalesAmountCash;
    property SalesAmountCard: Currency read FSalesAmountCard write FSalesAmountCard;
    property RefundAmountCash: Currency read FRefundAmountCash write FRefundAmountCash;
    property RefundAmountCard: Currency read FRefundAmountCard write FRefundAmountCard;
    property ClassCodes: TStrings read FClassCodes write SetClassCodes;
  end;

implementation

{ TPrinterParameters }

constructor TPrinterParameters.Create(ALogger: ILogFile);
begin
  inherited Create;
  FLogger := ALogger;
  FItemUnits := TItemUnits.Create;
  FVatRates := TVatRates.Create;
  FClassCodes := TStringList.Create;

  SetDefaults;
end;

destructor TPrinterParameters.Destroy;
begin
  FLogger := nil;
  FItemUnits.Free;
  FVatRates.Free;
  FClassCodes.Free;
  inherited Destroy;
end;

procedure TPrinterParameters.SetDefaults;
begin
  Logger.Debug('TPrinterParameters.SetDefaults');

  ConnectTimeout := DefConnectTimeout;
  WebPrinterAddress := DefWebPrinterAddress;

  FLogMaxCount := DefLogMaxCount;
  FLogFilePath := GetModulePath + 'Logs';
  FLogFileEnabled := DefLogFileEnabled;
  PaymentType2 := 1;
  PaymentType3 := 2;
  PaymentType4 := 3;
  MessageLength := DefMessageLength;
  // VatRates
  VatRates.Clear;
  VatRates.Add(1, 12, 'ÍÄÑ 12%'); // ÍÄÑ 12%
  VatRateEnabled := DefVatRateEnabled;
  FOpenCashbox := False;
  // Units
  ItemUnits.Clear;
  ItemUnits.Add(1, 'øòóêà');
  ItemUnits.Add(2, 'ïà÷êà');
  ItemUnits.Add(3, 'ìèëëèãğàìì');
  ItemUnits.Add(4, 'ãğàìì');
  ItemUnits.Add(5, 'êèëîãğàìì');
  ItemUnits.Add(6, 'öåíòíåğ');
  ItemUnits.Add(7, 'òîííà');
  ItemUnits.Add(8, 'ìèëëèìåòğ');
  ItemUnits.Add(9, 'ñàíòèìåòğ');
  ItemUnits.Add(11, 'ìåòğ');
  ItemUnits.Add(12, 'êèëîìåòğ');
  ItemUnits.Add(22, 'ìèëëèëèòğ');
  ItemUnits.Add(23, 'ëèòğ');
  ItemUnits.Add(26, 'êîìïëåêò');
  ItemUnits.Add(27, 'ñóòêè');
  ItemUnits.Add(28, '÷àñ');
  ItemUnits.Add(33, 'êîğîáêà');
  ItemUnits.Add(38, 'óïàêîâêà');
  ItemUnits.Add(39, 'ìèíóò');
  ItemUnits.Add(41, 'áàëëîí');
  ItemUnits.Add(42, 'äåíü');
  ItemUnits.Add(43, 'ìåñÿö');
  ItemUnits.Add(49, 'ğóëîí');

  CashinLine := 'ÂÍÅÑÅÍÎ';
  CashinPreLine := 'ÒÈÏ ÎÏÅĞÀÖÈÈ: ÂÍÅÑÅÍÈÅ';
  CashinPostLine := '';

  CashoutLine := 'ÈÇÚßÒÎ';
  CashoutPreLine := 'ÒÈÏ ÎÏÅĞÀÖÈÈ: ÈÇÚßÒÈÅ';
  CashoutPostLine := '';
  CashInAmount := 0;
  CashOutAmount := 0;

  CashInECRLine := 'ÍÀËÈ×ÍÛÕ Â ÊÀÑÑÅ';
  CashInECRAutoZero := DefCashInECRAutoZero;
  SalesAmountCash := 0;
  SalesAmountCard := 0;
  RefundAmountCash := 0;
  RefundAmountCard := 0;

  SalesAmountCashLine := 'ÂÑÅÃÎ ÏĞÎÄÀÆ ÍÀËÈ×ÍÛÅ';
  SalesAmountCardLine := 'ÂÑÅÃÎ ÏĞÎÄÀÆ ÁÀÍÊÎÂÑÊÈÅ ÊÀĞÒÛ';
  RefundAmountCashLine := 'ÂÑÅÃÎ ÂÎÇÂĞÀÒÎÂ ÍÀËÈ×ÍÛÅ';
  RefundAmountCardLine := 'ÂÑÅÃÎ ÂÎÇÂĞÀÒÎÂ ÁÀÍÊÎÂÑÊÈÅ ÊÀĞÒÛ';

  RecDiscountOnClassCode := False;
  ClassCodes.Clear;
end;

procedure TPrinterParameters.WriteLogParameters;
var
  i: Integer;
  VatRate: TVatRate;
begin
  Logger.Debug('TPrinterParameters.WriteLogParameters');
  Logger.Debug(Logger.Separator);
  Logger.Debug('ConnectTimeout: ' + IntToStr(ConnectTimeout));
  Logger.Debug('WebPrinterAddress: ' + WebPrinterAddress);
  Logger.Debug('LogMaxCount: ' + IntToStr(LogMaxCount));
  Logger.Debug('LogFilePath: ' + LogFilePath);
  Logger.Debug('LogFileEnabled: ' + BoolToStr(LogFileEnabled));
  Logger.Debug('PaymentType2: ' + IntToStr(PaymentType2));
  Logger.Debug('PaymentType3: ' + IntToStr(PaymentType3));
  Logger.Debug('PaymentType4: ' + IntToStr(PaymentType4));
  Logger.Debug('VatRateEnabled: ' + BoolToStr(VatRateEnabled));
  Logger.Debug('OpenCashbox: ' + BoolToStr(OpenCashbox));
  Logger.Debug('MessageLength: ' + IntToStr(MessageLength));

  // VatRates
  for i := 0 to VatRates.Count-1 do
  begin
    VatRate := VatRates[i];
    Logger.Debug(Format('VAT: code=%d, rate=%.2f, name="%s"', [
      VatRate.Code, VatRate.Rate, VatRate.Name]));
  end;

  Logger.Debug('CashinLine: ' + CashinLine);
  Logger.Debug('CashinPreLine: ' + CashinPreLine);
  Logger.Debug('CashinPostLine: ' + CashinPostLine);
  Logger.Debug('CashoutLine: ' + CashoutLine);
  Logger.Debug('CashoutPreLine: ' + CashoutPreLine);
  Logger.Debug('CashoutPostLine: ' + CashoutPostLine);
  Logger.Debug('CashInAmount: ' + AmountToStr(CashInAmount));
  Logger.Debug('CashOutAmount: ' + AmountToStr(CashOutAmount));
  Logger.Debug('CashInECRLine: ' + CashInECRLine);
  Logger.Debug('CashInECRAutoZero: ' + BoolToStr(CashInECRAutoZero));
  Logger.Debug('SalesAmountCash: ' + AmountToStr(SalesAmountCash));
  Logger.Debug('SalesAmountCard: ' + AmountToStr(SalesAmountCard));
  Logger.Debug('RefundAmountCash: ' + AmountToStr(RefundAmountCash));
  Logger.Debug('RefundAmountCard: ' + AmountToStr(RefundAmountCard));
  Logger.Debug('SalesAmountCashLine: ' + SalesAmountCashLine);
  Logger.Debug('SalesAmountCardLine: ' + SalesAmountCardLine);
  Logger.Debug('RefundAmountCashLine: ' + RefundAmountCashLine);
  Logger.Debug('RefundAmountCardLine: ' + RefundAmountCardLine);
  Logger.Debug('RecDiscountOnClassCode: ' + BoolToStr(RecDiscountOnClassCode));
  for i := 0 to ClassCodes.Count-1 do
  begin
    Logger.Debug(Format('ClassCode%d: %s', [i, ClassCodes[i]]));
  end;
  Logger.Debug(Logger.Separator);
end;

procedure TPrinterParameters.CheckPrameters;
begin
  if FWebPrinterAddress = '' then
    RaiseOposException(OPOS_ORS_CONFIG, 'WebPrinter address not defined');
end;

procedure TPrinterParameters.Assign(Source: TPersistent);
var
  Src: TPrinterParameters;
begin
  if Source is TPrinterParameters then
  begin
    Src := Source as TPrinterParameters;
    LogMaxCount := Src.LogMaxCount;
    LogFileEnabled := Src.LogFileEnabled;
    LogFilePath := Src.LogFilePath;
    WebPrinterAddress := Src.WebPrinterAddress;
    ConnectTimeout := Src.ConnectTimeout;
    PaymentType2 := Src.PaymentType2;
    PaymentType3 := Src.PaymentType3;
    PaymentType4 := Src.PaymentType4;
    VatRateEnabled := Src.VatRateEnabled;
    VatRates.Assign(VatRates);
    OpenCashbox := Src.OpenCashbox;
    MessageLength := Src.MessageLength;

    CashinLine := Src.CashinLine;
    CashinPreLine := Src.CashinPreLine;
    CashinPostLine := Src.CashinPostLine;
    CashoutLine := Src.CashoutLine;
    CashoutPreLine := Src.CashoutPreLine;
    CashoutPostLine := Src.CashoutPostLine;
    CashInECRLine := Src.CashInECRLine;
    SalesAmountCash := Src.SalesAmountCash;
    SalesAmountCard := Src.SalesAmountCard;
    RefundAmountCash := Src.RefundAmountCash;
    RefundAmountCard := Src.RefundAmountCard;
    CashInECRAutoZero := Src.CashInECRAutoZero;
  end else
    inherited Assign(Source);
end;

procedure TPrinterParameters.Load(const DeviceName: WideString);
begin

end;

procedure TPrinterParameters.Save(const DeviceName: WideString);
begin

end;

procedure TPrinterParameters.SetMessageLength(const Value: Integer);
begin
  if (Value >= 24)and(Value <= 120) then
    FMessageLength := Value;
end;

procedure TPrinterParameters.SetClassCodes(const Value: TStrings);
begin
  FClassCodes.Assign(Value);
end;

function TPrinterParameters.ClassCodeDiscountEnabled(const ClassCode: string): Boolean;
begin
  Result := RecDiscountOnClassCode and (ClassCodes.IndexOf(ClassCode) >= 0);
end;

end.

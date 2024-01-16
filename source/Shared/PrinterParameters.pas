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
  WException, LogFile, FileUtils, VatRate, ReceiptItem, ItemUnit;

const
  /////////////////////////////////////////////////////////////////////////////
  // Encoding constants

  EncodingWindows       = 0;
  Encoding866           = 1;

  EncodingMin = EncodingWindows;
  EncodingMax = Encoding866;

  FiscalPrinterProgID = 'OposWebPrinter.FiscalPrinter';

  DefLogMaxCount = 10;
  DefLogFileEnabled = True;
  DefConnectTimeout = 10;
  DefWebPrinterAddress = 'http://fbox.ngrok.io';
  DefVatRateEnabled = True;

type
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
  public
    constructor Create(ALogger: ILogFile);
    destructor Destroy; override;

    procedure SetDefaults;
    procedure CheckPrameters;
    procedure WriteLogParameters;
    procedure Load(const DeviceName: WideString);
    procedure Save(const DeviceName: WideString);
    procedure Assign(Source: TPersistent); override;

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
  end;

implementation

{ TPrinterParameters }

constructor TPrinterParameters.Create(ALogger: ILogFile);
begin
  inherited Create;
  FLogger := ALogger;
  FItemUnits := TItemUnits.Create;
  FVatRates := TVatRates.Create;

  SetDefaults;
end;

destructor TPrinterParameters.Destroy;
begin
  FItemUnits.Free;
  FVatRates.Free;
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
  // VatRates
  VatRates.Clear;
  VatRates.Add(1, 12, 'НДС 12%'); // НДС 12%
  VatRateEnabled := DefVatRateEnabled;
  FOpenCashbox := False;
  // Units
  ItemUnits.Clear;
  ItemUnits.Add(1, 'штука');
  ItemUnits.Add(2, 'пачка');
  ItemUnits.Add(3, 'миллиграмм');
  ItemUnits.Add(4, 'грамм');
  ItemUnits.Add(5, 'килограмм');
  ItemUnits.Add(6, 'центнер');
  ItemUnits.Add(7, 'тонна');
  ItemUnits.Add(8, 'миллиметр');
  ItemUnits.Add(9, 'сантиметр');
  ItemUnits.Add(11, 'метр');
  ItemUnits.Add(12, 'километр');
  ItemUnits.Add(22, 'миллилитр');
  ItemUnits.Add(23, 'литр');
  ItemUnits.Add(26, 'комплект');
  ItemUnits.Add(27, 'сутки');
  ItemUnits.Add(28, 'час');
  ItemUnits.Add(33, 'коробка');
  ItemUnits.Add(38, 'упаковка');
  ItemUnits.Add(39, 'минут');
  ItemUnits.Add(41, 'баллон');
  ItemUnits.Add(42, 'день');
  ItemUnits.Add(43, 'месяц');
  ItemUnits.Add(49, 'рулон');
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
  // VatRates
  for i := 0 to VatRates.Count-1 do
  begin
    VatRate := VatRates[i];
    Logger.Debug(Format('VAT: code=%d, rate=%.2f, name="%s"', [
      VatRate.Code, VatRate.Rate, VatRate.Name]));
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
  end else
    inherited Assign(Source);
end;

procedure TPrinterParameters.Load(const DeviceName: WideString);
begin

end;

procedure TPrinterParameters.Save(const DeviceName: WideString);
begin

end;

end.

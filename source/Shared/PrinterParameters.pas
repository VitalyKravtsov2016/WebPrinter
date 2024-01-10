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
  WException, LogFile, FileUtils, VatRate, ReceiptItem,
  Translation;

const
  /////////////////////////////////////////////////////////////////////////////
  // Flow control

  FLOW_CONTROL_XON      = 0;
  FLOW_CONTROL_HARDWARE = 1;
  FLOW_CONTROL_NONE     = 2;

  /////////////////////////////////////////////////////////////////////////////
  // Barcode print mode

  PrintBarcodeESCCommands  = 0;
  PrintBarcodeGraphics     = 1;
  PrintBarcodeText         = 2;
  PrintBarcodeNone         = 3;

  /////////////////////////////////////////////////////////////////////////////
  // Valid baudrates

  ValidBaudRates: array [0..9] of Integer = (
    2400,
    4800,
    9600,
    19200,
    38400,
    57600,
    115200,
    230400,
    460800,
    921600
  );

  FiscalPrinterProgID = 'OposWebPrinter.FiscalPrinter';

  // PrinterType constants
  PrinterTypePosPrinter         = 0;
  PrinterTypeWinPrinter         = 1;
  PrinterTypeEscPrinterSerial   = 2;
  PrinterTypeEscPrinterNetwork  = 3;
  PrinterTypeEscPrinterWindows  = 4;


  DefLogMaxCount = 10;
  DefLogFileEnabled = True;

  DefNumHeaderLines = 6;
  DefNumTrailerLines = 4;
  DefHeader =
    'Header line 1'#13#10 +
    'Header line 2'#13#10 +
    'Header line 3'#13#10 +
    'Header line 4'#13#10 +
    'Header line 5'#13#10 +
    'Header line 6';

  DefTrailer =
    'Trailer line 1'#13#10 +
    'Trailer line 2'#13#10 +
    'Trailer line 3'#13#10 +
    'Trailer line 4';

  DefVatRateEnabled = True;
  DefLogin = 'WebPrinter4@softit.kz';
  DefPassword = 'Kassa123';
  DefConnectTimeout = 10;
  DefWebPrinterAddress = 'https://devkkm.WebPrinter.kz/';
  DefCashboxNumber = 'SWK00032685';
  DefPrinterName = '';
  DefPrinterType = 0;
  DefFontName = '';
  DefRoundType = RoundTypeNone; // Округление позиций
  DefVATNumber = '00000';
  DefVATSeries = '00000';
  DefAmountDecimalPlaces = 2;
  DefRemoteHost = '192.168.1.87';
  DefRemotePort = 9100;
  DefByteTimeout = 500;

  DefPortName = 'COM1';
  DefBaudRate = CBR_9600;
  DefDataBits = DATABITS_8;
  DefStopBits = ONESTOPBIT;
  DefParity = NOPARITY;
  DefFlowControl = FLOW_CONTROL_NONE;
  DefReconnectPort = false;
  DefSerialTimeout = 500;
  DefDevicePollTime = 3000;
  DefTranslationName = 'KAZ';
  DefPrintBarcode = PrintBarcodeEscCommands;
  DefTranslationEnabled = false;
  DefCurrencyName = 'тг';
  DefLineSpacing = 30;
  DefPrintEnabled = True;
  DefRecLineChars = 42;
  DefRecLineHeight = 24;
  DefHeaderPrinted = false;

  /////////////////////////////////////////////////////////////////////////////
  // Header and trailer parameters

  MinHeaderLines  = 0;
  MaxHeaderLines  = 100;
  MinTrailerLines = 0;
  MaxTrailerLines = 100;

  /////////////////////////////////////////////////////////////////////////////
  // QR code size

  QRSizeSmall     = 0;
  QRSizeMedium    = 1;
  QRSizeLarge     = 2;
  QRSizeXLarge    = 3;
  QRSizeXXLarge   = 4;

  /////////////////////////////////////////////////////////////////////////////
  // Translation name

  TranslationNameRus = 'RUS';
  TranslationNameKaz = 'KAZ';

type
  { TPrinterParameters }

  TPrinterParameters = class(TPersistent)
  private
    FLogger: ILogFile;
    FHeader: TTntStringList;
    FTrailer: TTntStringList;
    FTranslations: TTranslations;
    FTranslationName: WideString;
    FTranslation: TTranslation;
    FTranslationRus: TTranslation;
    FLogMaxCount: Integer;
    FLogFileEnabled: Boolean;
    FLogFilePath: WideString;
    FNumHeaderLines: Integer;
    FNumTrailerLines: Integer;
    FWebPrinterAddress: WideString;
    FConnectTimeout: Integer;
    FVatRates: TVatRates;
    FVatRateEnabled: Boolean;
    FPaymentType2: Integer;
    FPaymentType3: Integer;
    FPaymentType4: Integer;
    FRoundType: Integer;
    FVATNumber: WideString;
    FVATSeries: WideString;
    FAmountDecimalPlaces: Integer;
    FTranslationEnabled: Boolean;

    procedure LogText(const Caption, Text: WideString);
    procedure SetHeaderText(const Text: WideString);
    procedure SetTrailerText(const Text: WideString);
    procedure SetNumHeaderLines(const Value: Integer);
    procedure SetNumTrailerLines(const Value: Integer);
    function GetHeaderText: WideString;
    function GetTrailerText: WideString;
    procedure SetAmountDecimalPlaces(const Value: Integer);
    function GetTranslation: TTranslation;
    function GetTranslationRus: TTranslation;
  public
    PortName: string;
    DataBits: Integer;
    StopBits: Integer;
    Parity: Integer;
    FlowControl: Integer;
    SerialTimeout: Integer;
    ReconnectPort: Boolean;
    PrintBarcode: Integer;
    RecLineChars: Integer;
    RecLineHeight: Integer;
    HeaderPrinted: Boolean;

    constructor Create(ALogger: ILogFile);
    destructor Destroy; override;

    procedure SetDefaults;
    procedure CheckPrameters;
    procedure WriteLogParameters;
    procedure Load(const DeviceName: WideString);
    procedure Save(const DeviceName: WideString);
    procedure Assign(Source: TPersistent); override;
    function BaudRateIndex(const Value: Integer): Integer;
    function GetTranslationText(const Text: WideString): WideString;
    function ItemByText(const ParamName: WideString): WideString;

    property Logger: ILogFile read FLogger;
    property Header: TTntStringList read FHeader;
    property Trailer: TTntStringList read FTrailer;
    property ConnectTimeout: Integer read FConnectTimeout write FConnectTimeout;
    property WebPrinterAddress: WideString read FWebPrinterAddress write FWebPrinterAddress;
    property LogMaxCount: Integer read FLogMaxCount write FLogMaxCount;
    property LogFilePath: WideString read FLogFilePath write FLogFilePath;
    property LogFileEnabled: Boolean read FLogFileEnabled write FLogFileEnabled;
    property NumHeaderLines: Integer read FNumHeaderLines write SetNumHeaderLines;
    property NumTrailerLines: Integer read FNumTrailerLines write SetNumTrailerLines;
    property VatRates: TVatRates read FVatRates;
    property VatRateEnabled: Boolean read FVatRateEnabled write FVatRateEnabled;
    property PaymentType2: Integer read FPaymentType2 write FPaymentType2;
    property PaymentType3: Integer read FPaymentType3 write FPaymentType3;
    property PaymentType4: Integer read FPaymentType4 write FPaymentType4;
    property RoundType: Integer read FRoundType write FRoundType;
    property VATSeries: WideString read FVATSeries write FVATSeries;
    property VATNumber: WideString read FVATNumber write FVATNumber;
    property HeaderText: WideString read GetHeaderText write SetHeaderText;
    property TrailerText: WideString read GetTrailerText write SetTrailerText;
    property AmountDecimalPlaces: Integer read FAmountDecimalPlaces write SetAmountDecimalPlaces;
    property Translations: TTranslations read FTranslations;
    property TranslationName: WideString read FTranslationName write FTranslationName;
    property Translation: TTranslation read GetTranslation;
    property TranslationRus: TTranslation read GetTranslationRus;
    property TranslationEnabled: Boolean read FTranslationEnabled write FTranslationEnabled;
  end;

function QRSizeToWidth(QRSize: Integer): Integer;

implementation

function QRSizeToWidth(QRSize: Integer): Integer;
begin
  Result := 0;
  case QRSize of
    QRSizeSmall     : Result := 102;
    QRSizeMedium    : Result := 153;
    QRSizeLarge     : Result := 204;
    QRSizeXLarge    : Result := 256;
    QRSizeXXLarge   : Result := 512;
  end;
end;

{ TPrinterParameters }

constructor TPrinterParameters.Create(ALogger: ILogFile);
begin
  inherited Create;
  FLogger := ALogger;
  FVatRates := TVatRates.Create;
  FHeader := TTntStringList.Create;
  FTrailer := TTntStringList.Create;
  FTranslations := TTranslations.Create;

  SetDefaults;
  Translations.Load;
end;

destructor TPrinterParameters.Destroy;
begin
  FHeader.Free;
  FTrailer.Free;
  FVatRates.Free;
  FTranslations.Free;
  inherited Destroy;
end;

procedure TPrinterParameters.SetDefaults;
begin
  Logger.Debug('TPrinterParameters.SetDefaults');

  SetNumHeaderLines(DefNumHeaderLines);
  SetNumTrailerLines(DefNumTrailerLines);

  ConnectTimeout := DefConnectTimeout;
  WebPrinterAddress := DefWebPrinterAddress;

  SetHeaderText(DefHeader);
  SetTrailerText(DefTrailer);
  FLogMaxCount := DefLogMaxCount;
  FLogFilePath := GetModulePath + 'Logs';
  FLogFileEnabled := DefLogFileEnabled;
  VatRateEnabled := DefVatRateEnabled;
  PaymentType2 := 1;
  PaymentType3 := 2;
  PaymentType4 := 3;
  VATNumber := DefVATNumber;
  VATSeries := DefVATSeries;
  AmountDecimalPlaces := DefAmountDecimalPlaces;
  // VatRates
  VatRates.Clear;
  VatRates.Add(1, 12, 'НДС 12%'); // НДС 12%

  TranslationName := DefTranslationName;
  TranslationEnabled := DefTranslationEnabled;
  RecLineChars := DefRecLineChars;
  RecLineHeight := DefRecLineHeight;
end;

procedure TPrinterParameters.LogText(const Caption, Text: WideString);
var
  i: Integer;
  Lines: TTntStrings;
begin
  Lines := TTntStringList.Create;
  try
    Lines.Text := Text;
    if Lines.Count = 1 then
    begin
      Logger.Debug(Format('%s: ''%s''', [Caption, Lines[0]]));
    end else
    begin
      for i := 0 to Lines.Count-1 do
      begin
        Logger.Debug(Format('%s.%d: ''%s''', [Caption, i, Lines[i]]));
      end;
    end;
  finally
    Lines.Free;
  end;
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
  Logger.Debug('NumHeaderLines: ' + IntToStr(NumHeaderLines));
  Logger.Debug('NumTrailerLines: ' + IntToStr(NumTrailerLines));
  LogText('Header', Header.Text);
  LogText('Trailer', Trailer.Text);
  Logger.Debug('PaymentType2: ' + IntToStr(PaymentType2));
  Logger.Debug('PaymentType3: ' + IntToStr(PaymentType3));
  Logger.Debug('PaymentType4: ' + IntToStr(PaymentType4));
  Logger.Debug('VatRateEnabled: ' + BoolToStr(VatRateEnabled));
  Logger.Debug('RoundType: ' + IntToStr(RoundType));
  Logger.Debug('VATSeries: ' + VATSeries);
  Logger.Debug('VATNumber: ' + VATNumber);
  Logger.Debug('AmountDecimalPlaces: ' + IntToStr(AmountDecimalPlaces));

  Logger.Debug('RecLineChars: ' + IntToStr(RecLineChars));
  Logger.Debug('RecLineHeight: ' + IntToStr(RecLineHeight));

  // VatRates
  for i := 0 to VatRates.Count-1 do
  begin
    VatRate := VatRates[i];
    Logger.Debug(Format('VAT: code=%d, rate=%.2f, name="%s"', [
      VatRate.Code, VatRate.Rate, VatRate.Name]));
  end;
  Logger.Debug(Logger.Separator);
end;

procedure TPrinterParameters.SetNumHeaderLines(const Value: Integer);
var
  i: Integer;
  Text: WideString;
begin
  if Value = NumHeaderLines then Exit;

  if Value in [MinHeaderLines..MaxHeaderLines] then
  begin
    Text := HeaderText;
    FNumHeaderLines := Value;

    FHeader.Clear;
    for i := 0 to Value-1 do
    begin
      FHeader.Add('');
    end;
    SetHeaderText(Text);
  end;
end;

procedure TPrinterParameters.SetNumTrailerLines(const Value: Integer);
var
  i: Integer;
  Text: WideString;
begin
  if Value = NumTrailerLines then Exit;

  if Value in [MinTrailerLines..MaxTrailerLines] then
  begin
    Text := TrailerText;
    FNumTrailerLines := Value;

    FTrailer.Clear;
    for i := 0 to Value-1 do
      FTrailer.Add('');
    SetTrailerText(Text);
  end;
end;

procedure TPrinterParameters.CheckPrameters;
begin
  if FWebPrinterAddress = '' then
    RaiseOposException(OPOS_ORS_CONFIG, 'WebPrinter address not defined');
end;

procedure TPrinterParameters.SetHeaderText(const Text: WideString);
var
  i: Integer;
  Lines: TTntStringList;
begin
  Lines := TTntStringList.Create;
  try
    Lines.Text := Text;
    for i := 0 to Lines.Count-1 do
    begin
      if i >= NumHeaderLines then Break;
      FHeader[i] := Lines[i];
    end;
  finally
    Lines.Free;
  end;
end;

procedure TPrinterParameters.SetTrailerText(const Text: WideString);
var
  i: Integer;
  Lines: TTntStringList;
begin
  Lines := TTntStringList.Create;
  try
    Lines.Text := Text;
    for i := 0 to Lines.Count-1 do
    begin
      if i >= NumTrailerLines then Break;
      FTrailer[i] := Lines[i];
    end;
  finally
    Lines.Free;
  end;
end;

function TPrinterParameters.GetHeaderText: WideString;
begin
  Result := Header.Text;
end;

function TPrinterParameters.GetTrailerText: WideString;
begin
  Result := Trailer.Text;
end;

procedure TPrinterParameters.SetAmountDecimalPlaces(const Value: Integer);
begin
  if Value in [0, 2] then
    FAmountDecimalPlaces := Value;
end;

function TPrinterParameters.BaudRateIndex(const Value: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := Low(ValidBaudRates) to High(ValidBaudRates) do
  begin
    if ValidBaudRates[i] = Value then
    begin
      Result := i;
      Break;
    end;
  end;
end;

procedure TPrinterParameters.Assign(Source: TPersistent);
var
  Src: TPrinterParameters;
begin
  if Source is TPrinterParameters then
  begin
    Src := Source as TPrinterParameters;
    Header.Assign(Src.Header);
    Trailer.Assign(Src.Trailer);
    LogMaxCount := Src.LogMaxCount;
    LogFileEnabled := Src.LogFileEnabled;
    LogFilePath := Src.LogFilePath;
    NumHeaderLines := Src.NumHeaderLines;
    NumTrailerLines := Src.NumTrailerLines;
    WebPrinterAddress := Src.WebPrinterAddress;
    ConnectTimeout := Src.ConnectTimeout;
    VatRateEnabled := Src.VatRateEnabled;
    PaymentType2 := Src.PaymentType2;
    PaymentType3 := Src.PaymentType3;
    PaymentType4 := Src.PaymentType4;
    RoundType := Src.RoundType;
    VATNumber := Src.VATNumber;
    VATSeries := Src.VATSeries;
    AmountDecimalPlaces := Src.AmountDecimalPlaces;
    VatRates.Assign(VatRates);
    RecLineChars := Src.RecLineChars;
    RecLineHeight := Src.RecLineHeight;
  end else
    inherited Assign(Source);
end;

function TPrinterParameters.GetTranslationText(
  const Text: WideString): WideString;
var
  Index: Integer;
begin
  Result := Text;
  if not TranslationEnabled then Exit;

  if GetTranslation = nil then Exit;
  if GetTranslationRus = nil then Exit;
  Index := GetTranslationRus.Items.IndexOf(Text);
  if Index <> -1 then
    Result := GetTranslation.Items[Index];
end;

function TPrinterParameters.GetTranslationRus: TTranslation;
begin
  if FTranslationRus = nil then
  begin
    FTranslationRus := Translations.Find(TranslationNameRus);
    if FTranslationRus = nil then
    begin
      FTranslationRus := Translations.Add(TranslationNameRus);
    end;
  end;
  Result := FTranslationRus;
end;

function TPrinterParameters.GetTranslation: TTranslation;
begin
  if FTranslation = nil then
  begin
    FTranslation := Translations.Find(FTranslationName);
    if FTranslation = nil then
    begin
      FTranslation := Translations.Add(FTranslationName);
    end;
  end;
  Result := FTranslation;
end;

procedure TPrinterParameters.Load(const DeviceName: WideString);
begin

end;

procedure TPrinterParameters.Save(const DeviceName: WideString);
begin

end;

function TPrinterParameters.ItemByText(const ParamName: WideString): WideString;
begin
  if AnsiCompareText(ParamName, 'VATSeries')=0 then
  begin
    Result := VATSeries;
    Exit;
  end;
  if AnsiCompareText(ParamName, 'VATNumber')=0 then
  begin
    Result := VATNumber;
    Exit;
  end;
end;

end.

unit PrinterParametersReg;

interface

uses
  // VCL
  Windows, SysUtils, Classes, Registry,
  // 3'd
  TntClasses, TntStdCtrls, TntRegistry, TntSysUtils,
  // This
  PrinterParameters, LogFile, Oposhi, WException, gnugettext,
  DriverError, VatRate, ItemUnit;

type
  { TPrinterParametersReg }

  TPrinterParametersReg = class
  private
    FLogger: ILogFile;
    FParameters: TPrinterParameters;

    procedure LoadSysParameters(const DeviceName: WideString);
    procedure LoadUsrParameters(const DeviceName: WideString);
    procedure SaveSysParameters(const DeviceName: WideString);
    procedure SaveUsrParameters(const DeviceName: WideString);
    procedure ReadVatRates(Reg: TTntRegistry; const KeyName: WideString);
    procedure ReadUnits(Reg: TTntRegistry; const KeyName: WideString);

    property Parameters: TPrinterParameters read FParameters;
  public
    constructor Create(AParameters: TPrinterParameters; ALogger: ILogFile);

    procedure Load(const DeviceName: WideString);
    procedure Save(const DeviceName: WideString);
    class function GetUsrKeyName(const DeviceName: WideString): WideString;
    class function GetSysKeyName(const DeviceName: WideString): WideString;

    property Logger: ILogFile read FLogger;
  end;

procedure DeleteParametersReg(const DeviceName: WideString; Logger: ILogFile);
procedure LoadParametersReg(Item: TPrinterParameters; const DeviceName: WideString;
  Logger: ILogFile);

procedure SaveParametersReg(Item: TPrinterParameters; const DeviceName: WideString;
  Logger: ILogFile);

procedure SaveUsrParametersReg(Item: TPrinterParameters;
  const DeviceName: WideString; Logger: ILogFile);

implementation

const
  REG_KEY_UNITS  = 'Units';
  REG_KEY_VATRATES  = 'VatRates';
  REG_KEY_PAYTYPES  = 'PaymentTypes';
  REGSTR_KEY_IBT = 'SOFTWARE\POSITIVE\POSITIVE32\Terminal';

procedure DeleteParametersReg(const DeviceName: WideString; Logger: ILogFile);
var
  Reg: TTntRegistry;
begin
  Reg := TTntRegistry.Create;
  try
    Reg.Access := KEY_ALL_ACCESS;
    Reg.RootKey := HKEY_CURRENT_USER;
    Reg.DeleteKey(TPrinterParametersReg.GetUsrKeyName(DeviceName));
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    Reg.DeleteKey(TPrinterParametersReg.GetSysKeyName(DeviceName));
  except
    on E: Exception do
      Logger.Error('TPrinterParametersReg.Save', E);
  end;
  Reg.Free;
end;

procedure LoadParametersReg(Item: TPrinterParameters; const DeviceName: WideString;
  Logger: ILogFile);
var
  Reader: TPrinterParametersReg;
begin
  Reader := TPrinterParametersReg.Create(Item, Logger);
  try
    Reader.Load(DeviceName);
    Item.Load(DeviceName);     
  finally
    Reader.Free;
  end;
end;

procedure SaveParametersReg(Item: TPrinterParameters; const DeviceName: WideString;
  Logger: ILogFile);
var
  Writer: TPrinterParametersReg;
begin
  Writer := TPrinterParametersReg.Create(Item, Logger);
  try
    Writer.Save(DeviceName);
    Item.Save(DeviceName);
  finally
    Writer.Free;
  end;
end;

procedure SaveUsrParametersReg(Item: TPrinterParameters;
  const DeviceName: WideString; Logger: ILogFile);
var
  Writer: TPrinterParametersReg;
begin
  Writer := TPrinterParametersReg.Create(Item, Logger);
  try
    Writer.SaveUsrParameters(DeviceName);
  finally
    Writer.Free;
  end;
end;

{ TPrinterParametersReg }

constructor TPrinterParametersReg.Create(AParameters: TPrinterParameters;
  ALogger: ILogFile);
begin
  inherited Create;
  FParameters := AParameters;
  FLogger := ALogger;
end;

class function TPrinterParametersReg.GetSysKeyName(const DeviceName: WideString): WideString;
begin
  Result := Tnt_WideFormat('%s\%s\%s', [OPOS_ROOTKEY, OPOS_CLASSKEY_FPTR, DeviceName]);
end;

procedure TPrinterParametersReg.Load(const DeviceName: WideString);
begin
  LoadSysParameters(DeviceName);
  LoadUsrParameters(DeviceName);
end;

procedure TPrinterParametersReg.Save(const DeviceName: WideString);
begin
  SaveUsrParameters(DeviceName);
  SaveSysParameters(DeviceName);
end;

procedure TPrinterParametersReg.LoadSysParameters(const DeviceName: WideString);
var
  KeyName: WideString;
  Reg: TTntRegistry;
begin
  Logger.Debug('TPrinterParametersReg.Load', [DeviceName]);

  Reg := TTntRegistry.Create;
  try
    Reg.Access := KEY_READ;
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    KeyName := GetSysKeyName(DeviceName);
    if Reg.OpenKey(KeyName, False) then
    begin
      if Reg.ValueExists('LogMaxCount') then
        Parameters.LogMaxCount := Reg.ReadInteger('LogMaxCount');

      if Reg.ValueExists('LogFileEnabled') then
        Parameters.LogFileEnabled := Reg.ReadBool('LogFileEnabled');

      if Reg.ValueExists('LogFilePath') then
        Parameters.LogFilePath := Reg.ReadString('LogFilePath');

      if Reg.ValueExists('WebPrinterAddress') then
        Parameters.WebPrinterAddress := Reg.ReadString('WebPrinterAddress');

      if Reg.ValueExists('ConnectTimeout') then
        Parameters.ConnectTimeout := Reg.ReadInteger('ConnectTimeout');

      if Reg.ValueExists('PaymentType2') then
        Parameters.PaymentType2 := Reg.ReadInteger('PaymentType2');

      if Reg.ValueExists('PaymentType3') then
        Parameters.PaymentType3 := Reg.ReadInteger('PaymentType3');

      if Reg.ValueExists('PaymentType4') then
        Parameters.PaymentType4 := Reg.ReadInteger('PaymentType4');

      if Reg.ValueExists('VatRateEnabled') then
        Parameters.VatRateEnabled := Reg.ReadBool('VatRateEnabled');

      if Reg.ValueExists('OpenCashbox') then
        Parameters.OpenCashbox := Reg.ReadBool('OpenCashbox');

      Reg.CloseKey;
    end;
    ReadVatRates(Reg, KeyName + '\' + REG_KEY_VATRATES);
    ReadUnits(Reg, KeyName + '\' + REG_KEY_UNITS);
  finally
    Reg.Free;
  end;
end;

procedure TPrinterParametersReg.ReadVatRates(Reg: TTntRegistry; const KeyName: WideString);
var
  i: Integer;
  Names: TTntStrings;
  VatCode: Integer;
  VatRate: Double;
  VatName: WideString;
begin
  if not Reg.OpenKey(KeyName, False) then Exit;

  Parameters.VatRates.Clear;
  Names := TTntStringList.Create;
  try
    Reg.GetKeyNames(Names);
    Reg.CloseKey;

    for i := 0 to Names.Count-1 do
    begin
      if Reg.OpenKey(KeyName, False) then
      begin
        if Reg.OpenKey(Names[i], False) then
        begin
          VatCode := Reg.ReadInteger('Code');
          VatRate := Reg.ReadFloat('Rate');
          VatName := Reg.ReadString('Name');
          try
            Parameters.VatRates.Add(VatCode, VatRate, VatName);
          except
            on E: Exception do
            begin
              Logger.Error('Failed to add VAT rate, ' + E.Message);
            end;
          end;
          Reg.CloseKey;
        end;
      end;
    end;
  finally
    Names.Free;
  end;
end;

procedure TPrinterParametersReg.ReadUnits(Reg: TTntRegistry; const KeyName: WideString);
var
  i: Integer;
  Names: TTntStrings;
  UnitCode: Integer;
  UnitName: WideString;
begin
  if not Reg.OpenKey(KeyName, False) then Exit;

  Parameters.ItemUnits.Clear;
  Names := TTntStringList.Create;
  try
    Reg.GetKeyNames(Names);
    Reg.CloseKey;

    for i := 0 to Names.Count-1 do
    begin
      if Reg.OpenKey(KeyName, False) then
      begin
        if Reg.OpenKey(Names[i], False) then
        begin
          UnitCode := Reg.ReadInteger('Code');
          UnitName := Reg.ReadString('Name');
          Parameters.ItemUnits.Add(UnitCode, UnitName);
          Reg.CloseKey;
        end;
      end;
    end;
  finally
    Names.Free;
  end;
end;

procedure TPrinterParametersReg.SaveSysParameters(const DeviceName: WideString);
var
  i: Integer;
  VatRate: TVatRate;
  ItemUnit: TItemUnit;
  Reg: TTntRegistry;
  KeyName: WideString;
begin
  Reg := TTntRegistry.Create;
  try
    Reg.Access := KEY_ALL_ACCESS;
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    KeyName := GetSysKeyName(DeviceName);
    if not Reg.OpenKey(KeyName, True) then
      raiseOpenKeyError(KeyName);

    Reg.WriteString('', FiscalPrinterProgID);
    Reg.WriteBool('LogFileEnabled', Parameters.LogFileEnabled);
    Reg.WriteString('LogFilePath', FParameters.LogFilePath);
    Reg.WriteInteger('LogMaxCount', FParameters.LogMaxCount);
    Reg.WriteString('WebPrinterAddress', FParameters.WebPrinterAddress);
    Reg.WriteInteger('ConnectTimeout', FParameters.ConnectTimeout);
    Reg.WriteInteger('PaymentType2', FParameters.PaymentType2);
    Reg.WriteInteger('PaymentType3', FParameters.PaymentType3);
    Reg.WriteInteger('PaymentType4', FParameters.PaymentType4);
    Reg.WriteBool('VatRateEnabled', FParameters.VatRateEnabled);
    Reg.WriteBool('VatRateEnabled', FParameters.VatRateEnabled);
    Reg.WriteBool('OpenCashbox', FParameters.OpenCashbox);
    Reg.CloseKey;
    // VatRates
    Reg.DeleteKey(KeyName + '\' + REG_KEY_VATRATES);
    for i := 0 to Parameters.VatRates.Count-1 do
    begin
      if Reg.OpenKey(KeyName + '\' + REG_KEY_VATRATES, True) then
      begin
        VatRate := Parameters.VatRates[i];
        if Reg.OpenKey(IntToStr(i), True) then
        begin
          Reg.WriteInteger('Code', VatRate.Code);
          Reg.WriteFloat('Rate', VatRate.Rate);
          Reg.WriteString('Name', VatRate.Name);
          Reg.CloseKey;
        end;
        Reg.CloseKey;
      end;
    end;
    // Units
    Reg.DeleteKey(KeyName + '\' + REG_KEY_UNITS);
    for i := 0 to Parameters.ItemUnits.Count-1 do
    begin
      if Reg.OpenKey(KeyName + '\' + REG_KEY_UNITS, True) then
      begin
        ItemUnit := Parameters.ItemUnits[i];
        if Reg.OpenKey(IntToStr(i), True) then
        begin
          Reg.WriteInteger('Code', ItemUnit.Code);
          Reg.WriteString('Name', ItemUnit.Name);
          Reg.CloseKey;
        end;
        Reg.CloseKey;
      end;
    end;
  finally
    Reg.Free;
  end;
end;

class function TPrinterParametersReg.GetUsrKeyName(const DeviceName: WideString): WideString;
begin
  Result := Tnt_WideFormat('%s\%s\%s', [OPOS_ROOTKEY, OPOS_CLASSKEY_FPTR, DeviceName]);
end;

procedure TPrinterParametersReg.LoadUsrParameters(const DeviceName: WideString);
begin
end;

procedure TPrinterParametersReg.SaveUsrParameters(const DeviceName: WideString);
begin
end;

end.

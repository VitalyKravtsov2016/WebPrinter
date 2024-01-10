unit PrinterParametersIni;

interface

uses
  // VCL
  Windows, SysUtils, Classes,
  // 3'd
  TntClasses, TntStdCtrls, TntRegistry, TntIniFiles, TntSysUtils,
  // This
  PrinterParameters, FileUtils, LogFile, SmIniFile, WebFptrSO_TLB;

type
  { TPrinterParametersIni }

  TPrinterParametersIni = class
  private
    FLogger: ILogFile;
    FParameters: TPrinterParameters;
    procedure LoadIni(const DeviceName: WideString);
    property Parameters: TPrinterParameters read FParameters;

    class function GetIniFileName: WideString;
    class function GetSectionName(const DeviceName: WideString): WideString;
    procedure SaveSysParameters(const DeviceName: WideString);
    procedure SaveUsrParameters(const DeviceName: WideString);

    property Logger: ILogFile read FLogger;
  public
    constructor Create(AParameters: TPrinterParameters; ALogger: ILogFile);
    procedure Load(const DeviceName: WideString);
    procedure Save(const DeviceName: WideString);
  end;

procedure DeleteParametersIni(const DeviceName: WideString);

procedure LoadParametersIni(Item: TPrinterParameters;
  const DeviceName: WideString; Logger: ILogFile);

procedure SaveParametersIni(Item: TPrinterParameters;
  const DeviceName: WideString; Logger: ILogFile);

procedure SaveUsrParametersIni(Item: TPrinterParameters;
  const DeviceName: WideString; Logger: ILogFile);

implementation

procedure DeleteParametersIni(const DeviceName: WideString);
begin
  try
    DeleteFile(TPrinterParametersIni.GetIniFileName);
  except
    on E: Exception do
      //Logger.Error('DeleteParametersIni', E);
  end;
end;

procedure LoadParametersIni(Item: TPrinterParameters;
  const DeviceName: WideString; Logger: ILogFile);
var
  Reader: TPrinterParametersIni;
begin
  Reader := TPrinterParametersIni.Create(Item, Logger);
  try
    Reader.Load(DeviceName);
    Item.Load(DeviceName);
  finally
    Reader.Free;
  end;
end;

procedure SaveParametersIni(Item: TPrinterParameters; const DeviceName: WideString;
  Logger: ILogFile);
var
  Writer: TPrinterParametersIni;
begin
  Writer := TPrinterParametersIni.Create(Item, Logger);
  try
    Writer.Save(DeviceName);
    Item.Save(DeviceName);
  finally
    Writer.Free;
  end;
end;

procedure SaveUsrParametersIni(Item: TPrinterParameters;
  const DeviceName: WideString; Logger: ILogFile);
var
  Writer: TPrinterParametersIni;
begin
  Writer := TPrinterParametersIni.Create(Item, Logger);
  try
    Writer.SaveUsrParameters(DeviceName);
  finally
    Writer.Free;
  end;
end;

{ TPrinterParametersIni }

constructor TPrinterParametersIni.Create(AParameters: TPrinterParameters;
  ALogger: ILogFile);
begin
  inherited Create;
  FParameters := AParameters;
  FLogger := ALogger;
end;

procedure TPrinterParametersIni.Load(const DeviceName: WideString);
begin
  try
    LoadIni(DeviceName);
  except
    on E: Exception do
    begin
      Logger.Error('TPrinterParametersIni.Load', E);
    end;
  end;
end;

procedure TPrinterParametersIni.Save(const DeviceName: WideString);
begin
  try
    SaveUsrParameters(DeviceName);
    SaveSysParameters(DeviceName);
  except
    on E: Exception do
      Logger.Error('TPrinterParametersIni.Save', E);
  end;
end;

class function TPrinterParametersIni.GetIniFileName: WideString;
begin
  Result := ExtractFilePath(CLSIDToFileName(Class_FiscalPrinter));
  if Result <> '' then
    Result := WideIncludeTrailingPathDelimiter(Result)
  else
    Result := GetModulePath;

  Result := Result + 'FiscalPrinter.ini';
end;

class function TPrinterParametersIni.GetSectionName(const DeviceName: WideString): WideString;
begin
  Result := 'FiscalPrinter_' + DeviceName;
end;

procedure TPrinterParametersIni.LoadIni(const DeviceName: WideString);
var
  Section: WideString;
  IniFile: TSmIniFile;
begin
  Logger.Debug('TPrinterParametersIni.Load', [DeviceName]);

  IniFile := TSmIniFile.Create(GetIniFileName);
  try
    Section := GetSectionName(DeviceName);
    if IniFile.SectionExists(Section) then
    begin
      FParameters.LogFileEnabled := IniFile.ReadBool(Section, 'LogFileEnabled', DefLogFileEnabled);
      FParameters.LogMaxCount := IniFile.ReadInteger(Section, 'LogMaxCount', DefLogMaxCount);
      FParameters.LogFilePath := IniFile.ReadString(Section, 'LogFilePath', '');
      FParameters.ConnectTimeout := IniFile.ReadInteger(Section, 'ConnectTimeout', 10);
      FParameters.WebPrinterAddress := IniFile.ReadString(Section, 'WebPrinterAddress', 'https://devkkm.WebPrinter.kz/');
    end;
  finally
    IniFile.Free;
  end;
end;

procedure TPrinterParametersIni.SaveSysParameters(const DeviceName: WideString);
var
  Section: WideString;
  IniFile: TSmIniFile;
begin
  IniFile := TSmIniFile.Create(GetIniFileName);
  try
    Section := GetSectionName(DeviceName);
    IniFile.WriteString(Section, 'LogFilePath', FParameters.LogFilePath);
    IniFile.WriteBool(Section, 'LogFileEnabled', Parameters.LogFileEnabled);
    IniFile.WriteInteger(Section, 'LogMaxCount', Parameters.LogMaxCount);
    IniFile.WriteInteger(Section, 'ConnectTimeout', FParameters.ConnectTimeout);
    IniFile.WriteString(Section, 'WebPrinterAddress', FParameters.WebPrinterAddress);
  finally
    IniFile.Free;
  end;
end;

procedure TPrinterParametersIni.SaveUsrParameters(const DeviceName: WideString);
begin
end;

end.

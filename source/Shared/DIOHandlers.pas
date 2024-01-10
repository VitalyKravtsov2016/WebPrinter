unit DIOHandlers;

interface

uses
  // VCL
  Classes, SysUtils, Graphics, Extctrls,
  // 3'd
  TntSysUtils, TntClasses,
  // This
  DIOHandler, DirectIOAPI, LogFile, PrinterParameters,
  OposUtils, OposFptrUtils, WException, gnugettext, WebPrinterImpl,
  StringUtils, PrinterTypes;

const
  ValueDelimiters = [';'];

type
  { TDIOHandler2 }

  TDIOHandler2 = class(TDIOHandler)
  private
    FPrinter: TWebPrinterImpl;
    function GetParameters: TPrinterParameters;
  public
    constructor CreateCommand(AOwner: TDIOHandlers; ACommand: Integer;
      APrinter: TWebPrinterImpl);

    property Printer: TWebPrinterImpl read FPrinter;
    property Parameters: TPrinterParameters read GetParameters;
  end;

  { TDIOBarcode }

  TDIOBarcode = class(TDIOHandler2)
  public
    procedure DirectIO(var pData: Integer; var pString: WideString); override;
  end;

  { TDIOBarcodeHex }

  TDIOBarcodeHex = class(TDIOHandler2)
  public
    procedure DirectIO(var pData: Integer; var pString: WideString); override;
  end;

  { TDIOBarcodeHex2 }

  TDIOBarcodeHex2 = class(TDIOHandler2)
  public
    procedure DirectIO(var pData: Integer; var pString: WideString); override;
  end;

  { TDIOPrintText }

  TDIOPrintText = class(TDIOHandler2)
  public
    procedure DirectIO(var pData: Integer; var pString: WideString); override;
  end;

  { TDIOPrintHeader }

  TDIOPrintHeader = class(TDIOHandler2)
  public
    procedure DirectIO(var pData: Integer; var pString: WideString); override;
  end;

  { TDIOPrintTrailer }

  TDIOPrintTrailer = class(TDIOHandler2)
  public
    procedure DirectIO(var pData: Integer; var pString: WideString); override;
  end;

  { TDIOGetDriverParameter }

  TDIOGetDriverParameter = class(TDIOHandler2)
  public
    procedure DirectIO(var pData: Integer; var pString: WideString); override;
  end;

  { TDIOSetDriverParameter }

  TDIOSetDriverParameter = class(TDIOHandler2)
  public
    procedure DirectIO(var pData: Integer; var pString: WideString); override;
  end;

  { TDIOPrintReceiptDuplicate }

  TDIOPrintReceiptDuplicate = class(TDIOHandler2)
  public
    procedure DirectIO(var pData: Integer; var pString: WideString); override;
  end;

implementation

function BoolToStr(Value: Boolean): WideString;
begin
  if Value then Result := '1'
  else Result := '0';
end;

function StrToBool(const Value: WideString): Boolean;
begin
  Result := Value <> '0';
end;

{ TDIOHandler2 }

constructor TDIOHandler2.CreateCommand(AOwner: TDIOHandlers;
  ACommand: Integer; APrinter: TWebPrinterImpl);
begin
  inherited Create(AOwner, ACommand);
  FPrinter := APrinter;
end;

function TDIOHandler2.GetParameters: TPrinterParameters;
begin
  Result := Printer.Params;
end;

{ TDIOBarcode }

procedure TDIOBarcode.DirectIO(var pData: Integer;
  var pString: WideString);
begin
  { !!! }
end;

{ TDIOBarcodeHex }

procedure TDIOBarcodeHex.DirectIO(var pData: Integer;
  var pString: WideString);
begin
  { !!! }
end;

{ TDIOBarcodeHex2 }

procedure TDIOBarcodeHex2.DirectIO(var pData: Integer;
  var pString: WideString);
begin
  { !!! }
end;

{ TDIOPrintText }

procedure TDIOPrintText.DirectIO(var pData: Integer;
  var pString: WideString);
(*
var
  Data: TTextRec;
*)  
begin
(*
  Data.Text := pString;
  Data.Station := Printer.Printer.Station;
  Data.Font := pData;
  Data.Alignment := taLeft;
  Data.Wrap := Printer.Parameters.WrapText;
  Printer.PrintText(Data);
*)
end;

{ TDIOPrintHeader }

procedure TDIOPrintHeader.DirectIO(var pData: Integer;
  var pString: WideString);
begin
  //Printer.PrintHeader; !!!
end;

{ TDIOPrintTrailer }

procedure TDIOPrintTrailer.DirectIO(var pData: Integer;
  var pString: WideString);
begin
  //Printer.PrintHeader; !!!
end;

{ TDIOGetDriverParameter }

procedure TDIOGetDriverParameter.DirectIO(var pData: Integer;
  var pString: WideString);
begin
end;

{ TDIOSetDriverParameter }

procedure TDIOSetDriverParameter.DirectIO(var pData: Integer;
  var pString: WideString);
begin

end;

{ TDIOPrintReceiptDuplicate }

procedure TDIOPrintReceiptDuplicate.DirectIO(var pData: Integer;
  var pString: WideString);
begin
  { !!! }
end;

end.

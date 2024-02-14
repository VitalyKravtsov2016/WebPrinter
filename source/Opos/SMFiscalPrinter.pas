unit SMFiscalPrinter;

interface

uses
  // VCL
  Windows, SysUtils, Variants, ComObj, ActiveX,
  // Tnt
  TntSysUtils,
  // Opos
  Opos, OposFptrUtils,
  // This
  OposFiscalPrinter_1_13_Lib_TLB, WException;

type
  { TSMFiscalPrinter }

  TSMFiscalPrinter = class(TOPOSFiscalPrinter)
  public
    procedure Check(AResultCode: Integer);
    function DirectIO2(Command: Integer; const pData: Integer; const pString: WideString): Integer;
  end;

  { FiscalPrinterError }

  FiscalPrinterError = class(WideException);

implementation

procedure TSMFiscalPrinter.Check(AResultCode: Integer);
begin
  if AResultCode <> OPOS_SUCCESS then
  begin
    raise FiscalPrinterError.Create(OposFptrGetErrorText(OleObject));
  end;
end;

function TSMFiscalPrinter.DirectIO2(Command: Integer; const pData: Integer; const pString: WideString): Integer;
var
  pData2: Integer;
  pString2: WideString;
begin
  pData2 := pData;
  pString2 := pString;
  Result := DirectIO(Command, pData2, pString2);
end;

end.


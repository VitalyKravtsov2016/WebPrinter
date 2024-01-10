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

end.


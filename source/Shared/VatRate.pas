unit VatRate;

interface

Uses
  // VCL
  Classes, SysUtils, WException, gnugettext, Math;

type
  TVatRate = class;

  { TVatRates }

  TVatRates = class(TCollection)
  private
    function GetItem(Index: Integer): TVatRate;
  public
    constructor Create;

    function ValidCode(ACode: Integer): Boolean;
    function ItemByCode(Code: Integer): TVatRate;
    function Add(ACode: Integer; ARate: Double; const AName: string): TVatRate;
    property Items[Index: Integer]: TVatRate read GetItem; default;
  end;

  { TVatRate }

  TVatRate = class(TCollectionItem)
  private
    FCode: Integer;
    FRate: Double;
    FName: WideString;
    FTotal: Currency;
  public
    constructor Create2(AOwner: TVatRates; ACode: Integer; ARate: Double;
      const AName: string);

    function GetTax(Amount: Currency): Currency;
    procedure Assign(Source: TPersistent); override;

    property Rate: Double read FRate;
    property Code: Integer read FCode;
    property Name: WideString read FName;
    property Total: Currency read FTotal write FTotal;
  end;

implementation

{ TVatRates }

constructor TVatRates.Create;
begin
  inherited Create(TVatRate);
end;

function TVatRates.ValidCode(ACode: Integer): Boolean;
begin
  Result := ItemByCode(ACode) = nil;
end;

function TVatRates.Add(ACode: Integer; ARate: Double; const AName: string): TVatRate;
begin
  if ItemByCode(ACode) <> nil then
    raise Exception.CreateFmt('Ќалогова€ ставка с кодом %d уже есть', [ACode]);
  if (ARate <= 0)or(ARate >= 100) then
    raise Exception.CreateFmt('Ќеверное значение налоговой ставки %.2f', [ARate]);
  if (AName = '') then
    raise Exception.Create('Ќазвание налоговой ставки не может быть пустым');

  Result := TVatRate.Create2(Self, ACode, ARate, AName);
end;

function TVatRates.ItemByCode(Code: Integer): TVatRate;
var
  i: Integer;
begin
  for i := 0 to Count-1 do
  begin
    Result := Items[i];
    if Result.Code = Code then Exit;
  end;
  Result := nil;
end;

function TVatRates.GetItem(Index: Integer): TVatRate;
begin
  Result := inherited Items[Index] as TVatRate;
end;

{ TVatRate }

constructor TVatRate.Create2(AOwner: TVatRates; ACode: Integer; ARate: Double;
  const AName: string);
begin
  inherited Create(AOwner);
  FCode := ACode;
  FRate := ARate;
  FName := AName;
end;

function TVatRate.GetTax(Amount: Currency): Currency;
begin
  Result := Amount * (Rate/100) / (1 + Rate/100);
  Result := Round(Result * 100) / 100;
end;

procedure TVatRate.Assign(Source: TPersistent);
var
  Src: TVatRate;
begin
  if Source is TVatRate then
  begin
    Src := Source as TVatRate;
    FCode := Src.Code;
    FRate := Src.Rate;
    FName := Src.Name;
    FTotal := Src.Total;
  end else
    inherited Assign(Source);
end;



end.

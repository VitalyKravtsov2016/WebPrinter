unit ItemUnit;

interface

Uses
  // VCL
  Classes, SysUtils, WException, gnugettext, Math;

type
  TItemUnit = class;

  { TItemUnits }

  TItemUnits = class(TCollection)
  private
    function GetItem(Index: Integer): TItemUnit;
  public
    constructor Create;

    function ItemByCode(Code: Integer): TItemUnit;
    function ItemByName(const Name: WideString): TItemUnit;
    function Add(ACode: Integer; const AName: string): TItemUnit;
    property Items[Index: Integer]: TItemUnit read GetItem; default;
  end;

  { TItemUnit }

  TItemUnit = class(TCollectionItem)
  private
    FCode: Integer;
    FName: WideString;
  public
    constructor Create2(AOwner: TItemUnits; ACode: Integer; const AName: string);
    procedure Assign(Source: TPersistent); override;

    property Code: Integer read FCode write FCode;
    property Name: WideString read FName write FName;
  end;

implementation

{ TItemUnits }

constructor TItemUnits.Create;
begin
  inherited Create(TItemUnit);
end;

function TItemUnits.Add(ACode: Integer; const AName: string): TItemUnit;
begin
  Result := TItemUnit.Create2(Self, ACode, AName);
end;

function TItemUnits.ItemByCode(Code: Integer): TItemUnit;
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

function TItemUnits.ItemByName(const Name: WideString): TItemUnit;
var
  i: Integer;
begin
  for i := 0 to Count-1 do
  begin
    Result := Items[i];
    if WideCompareText(Name, Result.Name) = 0 then Exit;
  end;
  Result := nil;
end;

function TItemUnits.GetItem(Index: Integer): TItemUnit;
begin
  Result := inherited Items[Index] as TItemUnit;
end;

{ TItemUnit }

constructor TItemUnit.Create2(AOwner: TItemUnits; ACode: Integer; const AName: string);
begin
  inherited Create(AOwner);
  FCode := ACode;
  FName := AName;
end;

procedure TItemUnit.Assign(Source: TPersistent);
var
  Src: TItemUnit;
begin
  if Source is TItemUnit then
  begin
    Src := Source as TItemUnit;
    FCode := Src.Code;
    FName := Src.Name;
  end else
    inherited Assign(Source);
end;



end.

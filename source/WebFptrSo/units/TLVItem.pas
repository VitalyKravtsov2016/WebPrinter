unit TLVItem;

interface

uses
  // This
  Classes;

type
  TTLVItem = class;

  { TTLVItems }

  TTLVItems = class(TCollection)
  private
    FID: Integer;
    function GetItem(Index: Integer): TTLVItem;
  public
    constructor Create;
    procedure Start(AID: Integer);
    function Add(AID: Integer; const AData: string): TTLVItem;

    property ID: Integer read FID;
    property Items[Index: Integer]: TTLVItem read GetItem; default;
  end;

  { TTLVItem }

  TTLVItem = class(TCollectionItem)
  public
    ID: Integer;
    Data: WideString;
  end;

implementation

{ TTLVItems }

constructor TTLVItems.Create;
begin
  inherited Create(TTLVItem);
end;

function TTLVItems.Add(AID: Integer; const AData: string): TTLVItem;
begin
  Result := TTLVItem.Create(Self);
  Result.ID := AID;
  Result.Data := AData;
end;

function TTLVItems.GetItem(Index: Integer): TTLVItem;
begin
  Result := inherited Items[Index] as TTLVItem;
end;

procedure TTLVItems.Start(AID: Integer);
begin
  Clear;
  FID := AID;
end;

end.

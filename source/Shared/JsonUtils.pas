unit JsonUtils;

interface

uses
  // VCL
  Windows, Classes, SysUtils, Variants, TypInfo, Types, ObjAuto, RTLConsts,
  // Tnt
  TntClasses,
  //
  uLkJSON;


type
  TChars = set of Char;

  { TJsonPersistent }

  TJsonPersistent = class(TPersistent)
  public
    function IsRequiredField(const Field: WideString): Boolean; virtual;
  end;

  TJsonCollection = class;

  TJsonCollectionItem = class(TJsonPersistent)
  private
    FCollection: TJsonCollection;
    FID: Integer;
    function GetIndex: Integer;
  protected
    procedure Changed(AllItems: Boolean);
    function GetOwner: TPersistent; override;
    function GetDisplayName: string; virtual;
    procedure SeTJsonCollection(Value: TJsonCollection); virtual;
    procedure SetIndex(Value: Integer); virtual;
    procedure SetDisplayName(const Value: string); virtual;
  public
    constructor Create(Collection: TJsonCollection); virtual;
    destructor Destroy; override;
    function GetNamePath: string; override;
    property Collection: TJsonCollection read FCollection write SeTJsonCollection;
    property ID: Integer read FID;
    property Index: Integer read GetIndex write SetIndex;
    property DisplayName: string read GetDisplayName write SetDisplayName;
  end;

  TJsonCollectionItemClass = class of TJsonCollectionItem;
  TJsonCollectionNotification = (cnAdded, cnExtracting, cnDeleting);

  TJsonCollection = class(TJsonPersistent)
  private
    FItemClass: TJsonCollectionItemClass;
    FItems: TList;
    FUpdateCount: Integer;
    FNextID: Integer;
    FPropName: string;
    function GetCount: Integer;
    function GetPropName: string;
    procedure InsertItem(Item: TJsonCollectionItem);
    procedure RemoveItem(Item: TJsonCollectionItem);
  protected
    procedure Added(var Item: TJsonCollectionItem); virtual; deprecated;
    procedure Deleting(Item: TJsonCollectionItem); virtual; deprecated;
    property NextID: Integer read FNextID;
    procedure Notify(Item: TJsonCollectionItem; Action: TJsonCollectionNotification); virtual;
    { Design-time editor support }
    function GetAttrCount: Integer; dynamic;
    function GetAttr(Index: Integer): string; dynamic;
    function GetItemAttr(Index, ItemIndex: Integer): string; dynamic;
    procedure Changed;
    function GetItem(Index: Integer): TJsonCollectionItem;
    procedure SetItem(Index: Integer; Value: TJsonCollectionItem);
    procedure SetItemName(Item: TJsonCollectionItem); virtual;
    procedure Update(Item: TJsonCollectionItem); virtual;
    property PropName: string read GetPropName write FPropName;
    property UpdateCount: Integer read FUpdateCount;
  public
    constructor Create(ItemClass: TJsonCollectionItemClass);
    destructor Destroy; override;
    function Owner: TPersistent;
    function Add: TJsonCollectionItem;
    procedure Assign(Source: TPersistent); override;
    procedure BeginUpdate; virtual;
    procedure Clear;
    procedure Delete(Index: Integer);
    procedure EndUpdate; virtual;
    function FindItemID(ID: Integer): TJsonCollectionItem;
    function GetNamePath: string; override;
    function Insert(Index: Integer): TJsonCollectionItem;
    property Count: Integer read GetCount;
    property ItemClass: TJsonCollectionItemClass read FItemClass;
    property Items[Index: Integer]: TJsonCollectionItem read GetItem write SetItem;
  end;

  { TJsonWriter }

  TJsonWriter = class
  private
    FStream: TStream;
    function WriteProperty(Instance: TJsonPersistent; PropInfo: PPropInfo;
      const Prefix: string): Boolean;
    procedure WriteWideString(const Value: WideString);
    procedure WriteMinStr(const LocaleStr: string;
      const UTF8Str: UTF8String);
    procedure Write(const Buf; Count: Integer);
    procedure WriteStr(Value: string);
    procedure WriteCollection(Value: TJsonCollection; const Prefix: string);
    procedure WriteProperties(Instance: TJsonPersistent; const Prefix: string);
    function IsValidProperty(Instance: TJsonPersistent;
      PropInfo: PPropInfo): Boolean;
  public
    constructor Create(AStream: TStream);
    procedure WriteObject(Instance: TJsonPersistent);
  end;

  { TJsonReader }

  TJsonReader = class
  private
    FStream: TStream;
    FLevel: Integer;

    function EOF: Boolean;
    function ReadPropName: WideString;
    function ReadWideString: WideString;
    function ReadForChars(Chars: TChars): WideString;
    function ReadForChar(ExpectedChar: Char): WideString;

    procedure ReadProperty(Instance: TJsonPersistent);
    procedure ReadPropValue(Instance: TJsonPersistent; PropInfo: Pointer);
    procedure ReadCollection(Collection: TJsonCollection);
    procedure ReadStrings(Strings: TStrings);
    function ReadChar: Char;
    function NextValue: Char;
    function EndOfClass: Boolean;
    function EndOfCollection: Boolean;
    function ReadWideString2: WideString;
    procedure SkipPropValue;
    function IsNullValue: Boolean;
  public
    constructor Create(AStream: TStream);
    procedure ReadObject(Instance: TJsonPersistent);
    procedure StepBack;
  end;

function ObjectToJson(Instance: TJsonPersistent): string;
procedure JsonToObject(const Text: string; Instance: TJsonPersistent);
procedure SetJsonField(Root: TlkJSONbase; const FieldName, FieldValue: WideString);
function GetJsonField(Root: TlkJSONbase; const FieldName: WideString): WideString;
function GetJsonField2(const JsonText, FieldName: WideString): WideString;
function UpdateJsonFields(const JsonText: WideString; Fields: TTntStrings): WideString;

implementation

const
  //CRLF = #13#10;
  //Indentation = #9;

  CRLF = '';
  Indentation = '';

function ObjectToJson(Instance: TJsonPersistent): string;
var
  Writer: TJsonWriter;
  Stream: TMemoryStream;
begin
  Result := '';
  Stream := TMemoryStream.Create;
  Writer := TJsonWriter.Create(Stream);
  try
    Writer.WriteObject(Instance);
    SetLength(Result, Stream.Size);
    Move(Stream.Memory^, Result[1], Stream.Size);
  finally
    Writer.Free;
    Stream.Free;
  end;
end;

function UpdateJsonFields(const JsonText: WideString; Fields: TTntStrings): WideString;
var
  i: Integer;
  json: TlkJSONbase;
  FieldName: WideString;
  FieldValue: WideString;
begin
  json := TlkJSON.ParseText(JsonText);
  if json = nil then Exit;

  for i := 0 to Fields.Count-1 do
  begin
    FieldName := Fields.Names[i];
    FieldValue := Fields.ValueFromIndex[i];
    SetJsonField(json, FieldName, FieldValue);
  end;
  Result := TlkJSON.GenerateText(json);
  json.Free;
end;

procedure JsonToObject(const Text: string; Instance: TJsonPersistent);
var
  Reader: TJsonReader;
  Stream: TMemoryStream;
begin
  if Length(Text) = 0 then Exit;

  Stream := TMemoryStream.Create;
  Reader := TJsonReader.Create(Stream);
  try
    Stream.Write(Text[1], Length(Text));
    Stream.Position := 0;

    Reader.ReadObject(Instance);
  finally
    Reader.Free;
    Stream.Free;
  end;
end;

function GetJsonField2(const JsonText, FieldName: WideString): WideString;
var
  json: TlkJSONbase;
begin
  Result := '';
  json := TlkJSON.ParseText(JsonText);
  if json <> nil then
  begin
    Result := GetJsonField(json, FieldName);
    json.Free;
  end;
end;


function GetJsonField(Root: TlkJSONbase; const FieldName: WideString): WideString;
var
  P: Integer;
  S: WideString;
  Field: WideString;
begin
  Result := '';
  S := FieldName;
  repeat
    P := Pos('.', S);
    if P <> 0 then
    begin
      Field := Copy(S, 1, P-1);
      S := Copy(S, P+1, Length(S));
    end else
    begin
      Field := S;
    end;
    Root := Root.Field[Field];
    if Root = nil then Exit;
  until P = 0;
  Result := Root.Value;
end;

procedure SetJsonField(Root: TlkJSONbase; const FieldName, FieldValue: WideString);
var
  P: Integer;
  S: WideString;
  Field: WideString;
begin
  S := FieldName;
  repeat
    P := Pos('.', S);
    if P <> 0 then
    begin
      Field := Copy(S, 1, P-1);
      S := Copy(S, P+1, Length(S));
    end else
    begin
      Field := S;
    end;
    Root := Root.Field[Field];
    if Root = nil then
    begin
      Exit;
    end;
  until P = 0;
  Root.Value := FieldValue;
end;

{ TJsonCollectionItem }

constructor TJsonCollectionItem.Create(Collection: TJsonCollection);
begin
  SeTJsonCollection(Collection);
end;

destructor TJsonCollectionItem.Destroy;
begin
  SeTJsonCollection(nil);
  inherited Destroy;
end;

procedure TJsonCollectionItem.Changed(AllItems: Boolean);
var
  Item: TJsonCollectionItem;
begin
  if (FCollection <> nil) and (FCollection.FUpdateCount = 0) then
  begin
    if AllItems then Item := nil else Item := Self;
    FCollection.Update(Item);
  end;
end;

function TJsonCollectionItem.GetIndex: Integer;
begin
  if FCollection <> nil then
    Result := FCollection.FItems.IndexOf(Self) else
    Result := -1;
end;

function TJsonCollectionItem.GetDisplayName: string;
begin
  Result := ClassName;
end;

function TJsonCollectionItem.GetNamePath: string;
begin
  if FCollection <> nil then
    Result := Format('%s[%d]',[FCollection.GetNamePath, Index])
  else
    Result := ClassName;
end;

function TJsonCollectionItem.GetOwner: TPersistent;
begin
  Result := FCollection;
end;

procedure TJsonCollectionItem.SeTJsonCollection(Value: TJsonCollection);
begin
  if FCollection <> Value then
  begin
    if FCollection <> nil then FCollection.RemoveItem(Self);
    if Value <> nil then Value.InsertItem(Self);
  end;
end;

procedure TJsonCollectionItem.SetDisplayName(const Value: string);
begin
  Changed(False);
end;

procedure TJsonCollectionItem.SetIndex(Value: Integer);
var
  CurIndex: Integer;
begin
  CurIndex := GetIndex;
  if (CurIndex >= 0) and (CurIndex <> Value) then
  begin
    FCollection.FItems.Move(CurIndex, Value);
    Changed(True);
  end;
end;

{ TJsonCollection }

constructor TJsonCollection.Create(ItemClass: TJsonCollectionItemClass);
begin
  FItemClass := ItemClass;
  FItems := TList.Create;
end;

destructor TJsonCollection.Destroy;
begin
  FUpdateCount := 1;
  if FItems <> nil then
    Clear;
  FItems.Free;
  inherited Destroy;
end;

function TJsonCollection.Add: TJsonCollectionItem;
begin
  Result := FItemClass.Create(Self);
  Added(Result);
end;

procedure TJsonCollection.Assign(Source: TPersistent);
var
  I: Integer;
begin
  if Source is TJsonCollection then
  begin
    BeginUpdate;
    try
      Clear;
      for I := 0 to TJsonCollection(Source).Count - 1 do
        Add.Assign(TJsonCollection(Source).Items[I]);
    finally
      EndUpdate;
    end;
    Exit;
  end;
  inherited Assign(Source);
end;

procedure TJsonCollection.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TJsonCollection.Changed;
begin
  if FUpdateCount = 0 then Update(nil);
end;

procedure TJsonCollection.Clear;
begin
  if FItems.Count > 0 then
  begin
    BeginUpdate;
    try
      while FItems.Count > 0 do
        TJsonCollectionItem(FItems.Last).Free;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TJsonCollection.EndUpdate;
begin
  Dec(FUpdateCount);
  Changed;
end;

function TJsonCollection.FindItemID(ID: Integer): TJsonCollectionItem;
var
  I: Integer;
begin
  for I := 0 to FItems.Count-1 do
  begin
    Result := TJsonCollectionItem(FItems[I]);
    if Result.ID = ID then Exit;
  end;
  Result := nil;
end;

function TJsonCollection.GetAttrCount: Integer;
begin
  Result := 0;
end;

function TJsonCollection.GetAttr(Index: Integer): string;
begin
  Result := '';
end;

function TJsonCollection.GetItemAttr(Index, ItemIndex: Integer): string;
begin
  Result := Items[ItemIndex].DisplayName;
end;

function TJsonCollection.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TJsonCollection.GetItem(Index: Integer): TJsonCollectionItem;
begin
  Result := FItems[Index];
end;

function TJsonCollection.GetNamePath: string;
var
  S, P: string;
begin
  Result := ClassName;
  if GetOwner = nil then Exit;
  S := GetOwner.GetNamePath;
  if S = '' then Exit;
  P := PropName;
  if P = '' then Exit;
  Result := S + '.' + P;
end;

function TJsonCollection.GetPropName: string;
var
  I: Integer;
  Props: PPropList;
  TypeData: PTypeData;
  Owner: TPersistent;
begin
  Result := FPropName;
  Owner := GetOwner;
  if (Result <> '') or (Owner = nil) or (Owner.ClassInfo = nil) then Exit;
  TypeData := GetTypeData(Owner.ClassInfo);
  if (TypeData = nil) or (TypeData^.PropCount = 0) then Exit;
  GetMem(Props, TypeData^.PropCount * sizeof(Pointer));
  try
    GetPropInfos(Owner.ClassInfo, Props);
    for I := 0 to TypeData^.PropCount-1 do
    begin
      with Props^[I]^ do
        if (PropType^^.Kind = tkClass) and
          (GetOrdProp(Owner, Props^[I]) = Integer(Self)) then
          FPropName := Name;
    end;
  finally
    Freemem(Props);
  end;
  Result := FPropName;
end;

function TJsonCollection.Insert(Index: Integer): TJsonCollectionItem;
begin
  Result := Add;
  Result.Index := Index;
end;

procedure TJsonCollection.InsertItem(Item: TJsonCollectionItem);
begin
  if not (Item is FItemClass) then TList.Error(@SInvalidProperty, 0);
  FItems.Add(Item);
  Item.FCollection := Self;
  Item.FID := FNextID;
  Inc(FNextID);
  SetItemName(Item);
  Notify(Item, cnAdded);
  Changed;
end;

procedure TJsonCollection.RemoveItem(Item: TJsonCollectionItem);
begin
  Notify(Item, cnExtracting);
  if Item = FItems.Last then
    FItems.Delete(FItems.Count - 1)
  else
    FItems.Remove(Item);
  Item.FCollection := nil;
  Changed;
end;

procedure TJsonCollection.SetItem(Index: Integer; Value: TJsonCollectionItem);
begin
  TJsonCollectionItem(FItems[Index]).Assign(Value);
end;

procedure TJsonCollection.SetItemName(Item: TJsonCollectionItem);
begin
end;

procedure TJsonCollection.Update(Item: TJsonCollectionItem);
begin
end;

procedure TJsonCollection.Delete(Index: Integer);
begin
  Notify(TJsonCollectionItem(FItems[Index]), cnDeleting);
  TJsonCollectionItem(FItems[Index]).Free;
end;

function TJsonCollection.Owner: TPersistent;
begin
  Result := GetOwner;
end;

procedure TJsonCollection.Added(var Item: TJsonCollectionItem);
begin
end;

procedure TJsonCollection.Deleting(Item: TJsonCollectionItem);
begin
end;

procedure TJsonCollection.Notify(Item: TJsonCollectionItem;
  Action: TJsonCollectionNotification);
begin
  case Action of
    cnAdded: Added(Item);
    cnDeleting: Deleting(Item);
  end;
end;

{ TJsonWriter }

constructor TJsonWriter.Create(AStream: TStream);
begin
  inherited Create;
  FStream := AStream;
end;

procedure TJsonWriter.WriteObject(Instance: TJsonPersistent);
begin
  WriteStr('{' + CRLF);
  WriteProperties(Instance, Indentation);
  WriteStr('}');
end;

procedure TJsonWriter.WriteProperties(Instance: TJsonPersistent; const Prefix: string);
var
  I, Count: Integer;
  PropInfo: PPropInfo;
  PropList: PPropList;
  NeedComma: Boolean;
begin
  NeedComma := False;
  Count := GetTypeData(Instance.ClassInfo)^.PropCount;
  if Count > 0 then
  begin
    GetMem(PropList, Count * SizeOf(Pointer));
    try
      GetPropInfos(Instance.ClassInfo, PropList);
      for I := 0 to Count - 1 do
      begin
        PropInfo := PropList^[I];
        if PropInfo = nil then
          Break;

        if IsStoredProp(Instance, PropInfo) then
        begin
          if IsValidProperty(Instance, PropInfo) and NeedComma then
          begin
            WriteStr(',' + CRLF);
            NeedComma := False;
          end;

          if (WriteProperty(Instance, PropInfo, Prefix)) then
          begin
            NeedComma := True;
          end;
          if (i = (Count-1)) then
          begin
            WriteStr(CRLF);
          end;
        end;
      end;
    finally
      FreeMem(PropList, Count * SizeOf(Pointer));
    end;
  end;
end;

procedure TJsonWriter.Write(const Buf; Count: Longint);
begin
  FStream.Write(Buf, Count);
end;

procedure TJsonWriter.WriteStr(Value: string);
var
  L: Integer;
begin
  L := Length(Value);
  if L > 255 then L := 255;
  Write(Value[1], L);
end;

procedure TJsonWriter.WriteCollection(Value: TJsonCollection; const Prefix: string);
var
  I: Integer;
begin
  if Value.Count = 0 then Exit;

  if Value <> nil then
  begin
    for I := 0 to Value.Count - 1 do
    begin
      WriteStr(Prefix + '{' + CRLF);
      WriteProperties(TJsonPersistent(Value.Items[I]), Prefix + Indentation);
      WriteStr(Prefix + '}');
      if i <> (Value.Count - 1) then
      begin
        WriteStr(',');
      end;
      WriteStr(CRLF);
    end;
  end;
end;

procedure TJsonWriter.WriteMinStr(const LocaleStr: string; const UTF8Str: UTF8String);
var
  L: Integer;
begin
  if LocaleStr <> UTF8Str then
  begin
    L := Length(UTF8Str);
    Write(Pointer(UTF8Str)^, L);
  end
  else
  begin
    L := Length(LocaleStr);
    Write(Pointer(LocaleStr)^, L);
  end;
end;

function EncodeJsonString(ws: WideString): WideString;
var
  i: Integer;
begin
  Result := '"';
  for i := 1 to Length(ws) do
  begin
    case ws[i] of
      '/', '\', '"': result := result + '\' + ws[i];
      #8: result := result + '\b';
      #9: result := result + '\t';
      #10: result := result + '\n';
      #13: result := result + '\r';
      #12: result := result + '\f';
    else
      if ord(ws[i]) < 32 then
        result := result + '\u' + inttohex(ord(ws[i]), 4)
      else
        result := result + ws[i];
    end;
  end;
  Result := Result + '"';
end;

function code2utf(iNumber: Integer): UTF8String;
begin
  if iNumber < 128 then Result := chr(iNumber)
  else if iNumber < 2048 then
    Result := chr((iNumber shr 6) + 192) + chr((iNumber and 63) + 128)
  else if iNumber < 65536 then
    Result := chr((iNumber shr 12) + 224) + chr(((iNumber shr 6) and
      63) + 128) + chr((iNumber and 63) + 128)
  else if iNumber < 2097152 then
    Result := chr((iNumber shr 18) + 240) + chr(((iNumber shr 12) and
      63) + 128) + chr(((iNumber shr 6) and 63) + 128) +
      chr((iNumber and 63) + 128);
end;

function DecodeJsonString(s: WideString): WideString;
var
  i, j : integer;
begin
  i := Pos('\', s);
  if (i = 0) then
    Result := s
  else
  begin
    Result := Copy(s, 1, i-1);
    j := i;
    repeat
      if (s[j] = '\') then
      begin
        inc(j);
        case s[j] of
          '\': Result := Result + '\';
          '"': Result := Result + '"';
          '''': Result := Result + '''';
          '/': Result := Result + '/';
          'b': Result := Result + #8;
          'f': Result := Result + #12;
          'n': Result := Result + #10;
          'r': Result := Result + #13;
          't': Result := Result + #9;
          'u':
            begin
              Result := Result + code2utf(StrToIntDef('$' + copy(s, j + 1, 4), 0));
              inc(j, 4);
            end;
        end;
      end
      else
        Result := Result + s[j];
      inc(j);
    until j > length(s);
  end;
end;

procedure TJsonWriter.WriteWideString(const Value: WideString);
var
  L: Integer;
  Utf8Str: UTF8String;
begin
  Utf8Str := Utf8Encode(Value);
  if Length(Utf8Str) < (Length(Value) * SizeOf(WideChar)) then
    WriteMinStr(Value, Utf8Str)
  else
  begin
    L := Length(Value);
    Write(Pointer(Value)^, L * 2);
  end;
end;

function TJsonWriter.IsValidProperty(Instance: TJsonPersistent;
  PropInfo: PPropInfo): Boolean;
var
  Value: TObject;
  Text: WideString;
  Strings: TStrings;
  PropType: PTypeInfo;
  PropName: WideString;
  Collection: TJsonCollection;
begin
  Result := False;
  PropName := PPropInfo(PropInfo)^.Name;
  PropType := PropInfo^.PropType^;
  case PropType^.Kind of
    tkString, tkLString, tkWString:
    begin
      Text := GetWideStrProp(Instance, PropInfo);
      Result := Instance.IsRequiredField(PropName) or (Text <> '');
    end;

    tkClass:
    begin
      Value := TObject(GetOrdProp(Instance, PropInfo));
      if Value = nil then Exit;

      if Value is TJsonCollection then
      begin
        Collection := Value as TJsonCollection;
        Result := Instance.IsRequiredField(PropName) or (Collection.Count > 0);
      end else
      begin
        if Value is TStrings then
        begin
          Strings :=  Value as TStrings;
          Result := Instance.IsRequiredField(PropName) or (Strings.Count > 0);
        end else
        begin
          if Value is TJsonPersistent then
          begin
            Result := True;
          end;
        end;
      end;
    end;
  else
    Result := True;
  end;
end;

function TJsonWriter.WriteProperty(Instance: TJsonPersistent; PropInfo: PPropInfo;
  const Prefix: string): Boolean;
var
  i: Integer;
  V: Variant;
  Text: WideString;
  Value: TObject;
  Strings: TStrings;
  PropType: PTypeInfo;
  PropName: WideString;
  Collection: TJsonCollection;
begin
  Result := False;
  PropName := PPropInfo(PropInfo)^.Name;
  if AnsiCompareText(PropName, '_type') = 0 then
    PropName := 'type';

  PropType := PropInfo^.PropType^;
  case PropType^.Kind of
    tkString, tkLString, tkWString:
    begin
      Text := GetWideStrProp(Instance, PropInfo);
      if Instance.IsRequiredField(PropName) or (Text <> '') then
      begin
        WriteStr(Prefix + '"' + PropName + '":');
        WriteWideString(EncodeJsonString(Text));
        Result := True;
      end;
    end;

    tkClass:
    begin
      Value := TObject(GetOrdProp(Instance, PropInfo));
      if Value = nil then Exit;

      if Value is TJsonCollection then
      begin
        Collection := Value as TJsonCollection;
        if Instance.IsRequiredField(PropName) or (Collection.Count > 0) then
        begin
          WriteStr(Prefix + '"' + PropName + '":[' + CRLF);
          WriteCollection(Collection, Prefix + Indentation);
          WriteStr(Prefix + ']');
          Result := True;
        end;
      end else
      begin
        if Value is TStrings then
        begin
          Strings :=  Value as TStrings;
          if Instance.IsRequiredField(PropName) or (Strings.Count > 0) then
          begin
            WriteStr(Prefix + '"' + PropName + '":[' + CRLF);
            for i := 0 to Strings.Count-1 do
            begin
              WriteStr(Prefix + Indentation);
              WriteWideString(EncodeJsonString(Strings[i]));
              if i <> (Strings.Count-1) then
              begin
                WriteStr(Prefix + Indentation + ',');
              end;
            end;
            WriteStr(Prefix + ']');
            Result := True;
          end;
        end else
        begin
          if Value is TJsonPersistent then
          begin
            WriteStr(Prefix + '"' + PropName + '":{' + CRLF);
            WriteProperties(TJsonPersistent(Value), Prefix + Indentation);
            WriteStr(Prefix + '}');
            Result := True;
          end;
        end;
      end;
    end;
  else
    WriteStr(Prefix + '"' + PropName + '":');
    V := GetPropValue(Instance, PropInfo);
    WriteWideString(LowerCase(VarToWideStr(V)));
    Result := True;
  end;
end;

{ TJsonReader }

constructor TJsonReader.Create(AStream: TStream);
begin
  inherited Create;
  FStream := AStream;
end;

procedure TJsonReader.ReadObject(Instance: TJsonPersistent);
begin
  FLevel := 0;
  while not EOF do
  begin
    ReadProperty(Instance);
    if FLevel = 0 then Break;
  end;
end;

function TJsonReader.EOF: Boolean;
begin
  Result := FStream.Position = FStream.Size;
end;

function TJsonReader.ReadChar: Char;
begin
  FStream.ReadBuffer(Result, 1);
  if Result = '{' then Inc(FLevel);
  if Result = '}' then Dec(FLevel);
end;

function TJsonReader.ReadForChar(ExpectedChar: Char): WideString;
var
  C: Char;
begin
  Result := '';
  while not EOF do
  begin
    C := ReadChar;
    if C = ExpectedChar then Break;
    Result := Result + C;
  end;
  Result := UTF8Decode(Result);
end;

function TJsonReader.ReadForChars(Chars: TChars): WideString;
var
  C: Char;
begin
  Result := '';
  while not EOF do
  begin
    C := ReadChar;
    if C in Chars then Break;
    Result := Result + C;
  end;
  Result := UTF8Decode(Result);
end;

function TJsonReader.ReadPropName: WideString;
begin
  ReadForChar('"');
  Result := ReadForChar('"');
  ReadForChar(':');

  if AnsiCompareText(Result, 'type') = 0 then
    Result := '_Type';
end;

function TJsonReader.ReadWideString: WideString;
begin
  Result := '';
  if IsNullValue then Exit;

  Result := ReadForChars([',', '}', ']']);
  FStream.Seek(-1, 1);

  Result := Trim(Result);
  if Length(Result) > 0 then
  begin
    if (Result[1] = '"')and(Result[Length(Result)] = '"') then
      Result := Copy(Result, 2, Length(Result)-2);
  end;
end;

function TJsonReader.ReadWideString2: WideString;
var
  C: Char;
  Prev: Char;
begin
  Result := '';
  if IsNullValue then Exit;

  Prev := #0;
  Result := '';

  ReadForChar('"');
  while not EOF do
  begin
    C := ReadChar;
    if C in [#13, #10, '}', ']'] then Break;
    if (C = '"')and(Prev <> '\') then
    begin
      Break;
    end;
    Result := Result + C;
    Prev := C;
  end;
  Result := DecodeJsonString(Result);
  Result := UTF8Decode(Result);
end;

procedure TJsonReader.SkipPropValue;
var
  C: Char;
  ALevel: Integer;
  NLevel: Integer;
begin
  ALevel := 0;
  NLevel := 0;
  while not EOF do
  begin
    C := ReadChar;
    case C of
      '[': Inc(ALevel);
      ']': Dec(ALevel);
      '{': Inc(NLevel);
      '}': Dec(NLevel);
    end;
    if (ALevel = 0)and(NLevel = 0) then
    begin
      if C = ',' then Break;
      if (C = '}') or (C = ']') then
      begin
        Break;
      end;
    end;
  end;
end;

procedure TJsonReader.StepBack;
begin
  FStream.Seek(-1, 1);
end;

procedure TJsonReader.ReadProperty(Instance: TJsonPersistent);
var
  PropName: string;
  PropInfo: PPropInfo;
begin
  while not EOF do
  begin
    if EndOfClass then Break;
    if EndOfCollection then Break;
    if IsNullValue then Break;

    PropName := ReadPropName;
    PropInfo := GetPropInfo(Instance.ClassInfo, PropName);
    if PropInfo <> nil then
    begin
      ReadPropValue(Instance, PropInfo);
    end else
    begin
      SkipPropValue;
    end;
  end;
end;

function TJsonReader.NextValue: Char;
begin
  repeat
    Result := ReadChar;
  until (Result > #$20)and(Result <= #$FF);
  FStream.Seek(-1, 1);
end;

procedure TJsonReader.ReadPropValue(Instance: TJsonPersistent; PropInfo: Pointer);
var
  Item: TObject;
  PropType: PTypeInfo;
begin
  if PPropInfo(PropInfo)^.SetProc = nil then Exit;

  PropType := PPropInfo(PropInfo)^.PropType^;
  case PropType^.Kind of
    tkInteger:
      SetOrdProp(Instance, PropInfo, StrToIntDef(ReadWideString, 0));
    tkChar:
      SetOrdProp(Instance, PropInfo, Ord(ReadWideString[1]));
    tkEnumeration:
      SetOrdProp(Instance, PropInfo, GetEnumValue(PropType, ReadWideString));
    tkFloat:
      SetFloatProp(Instance, PropInfo, StrToFloat(ReadWideString));
    tkString, tkLString:
      SetStrProp(Instance, PropInfo, ReadWideString2);
    tkWString:
      SetWideStrProp(Instance, PropInfo, ReadWideString2);
    //tkSet:
     // SetOrdProp(Instance, PropInfo, ReadSet(PropType));
    tkInt64:
      SetInt64Prop(Instance, PropInfo, StrToInt64Def(ReadWideString, 0));
    tkClass:
    begin
      Item := TObject(GetOrdProp(Instance, PropInfo));
      if NextValue = '[' then
      begin
        ReadChar;
        if Item is TJsonCollection then
        begin
          ReadCollection(TJsonCollection(Item));
        end;
        if Item is TStrings then
        begin
          ReadStrings(TStrings(Item));
        end;
      end
      else
        //SetObjectIdent(Instance, PropInfo, ReadIdent);
        ReadProperty(TJsonPersistent(GetOrdProp(Instance, PropInfo)));
      end;
  end;
end;

function TJsonReader.EndOfClass: Boolean;
begin
  Result := NextValue = '}';
  if Result then ReadChar;
end;

function TJsonReader.EndOfCollection: Boolean;
begin
  Result := NextValue = ']';
  if Result then ReadChar;
end;

function TJsonReader.IsNullValue: Boolean;
var
  C: Char;
  S: string;
begin
  Result := False;
  while not EOF do
  begin
    C := ReadChar;
    if C <> ' ' then
    begin
      FStream.Seek(-1, 1);
      Break;
    end;
  end;

  if FStream.Size >= 4 then
  begin
    SetLength(S, 4);
    FStream.ReadBuffer(S[1], 4);
    Result := S = 'null';
    if Result then Exit;

    if not Result then
    begin
      FStream.Seek(-4, 1);
    end;
  end;
end;

procedure TJsonReader.ReadCollection(Collection: TJsonCollection);
begin
  Collection.BeginUpdate;
  try
    if not EOF then Collection.Clear;

    while not EOF do
    begin
      if EndOfCollection then Break;
      ReadProperty(TJsonPersistent(Collection.Add));
    end;
  finally
    Collection.EndUpdate;
  end;
end;

procedure TJsonReader.ReadStrings(Strings: TStrings);
begin
  Strings.BeginUpdate;
  try
    if not EOF then Strings.Clear;

    while not EOF do
    begin
      if NextValue = ',' then
        ReadChar;
      if EndOfCollection then Break;

      Strings.Add(ReadWideString2);
    end;
  finally
    Strings.EndUpdate;
  end;
end;

{ TJsonPersistent }

function TJsonPersistent.IsRequiredField(const Field: WideString): Boolean;
begin
  Result := True;
end;

end.

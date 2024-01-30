unit duJsonUtils;

interface

uses
  // VCL
  Windows, SysUtils, Classes, IniFiles,
  // DUnit
  TestFramework,
  // Tnt
  TntClasses,
  // This
  JsonUtils, WebPrinter, FileUtils;

type
  { TJsonUtilsTest }

  TJsonUtilsTest = class(TTestCase)
  published
    procedure CheckUpdateJsonFields;
    procedure TestEncodeJsonString;
  end;

implementation

{ TJsonUtilsTest }

procedure TJsonUtilsTest.CheckUpdateJsonFields;
var
  Request: TWPOrder;
  Fields: TTntStrings;
  JsonText: WideString;
begin
  Request := TWPOrder.Create;
  Fields := TTntStringList.Create;
  try
    JsonText := ReadFileData('OrderRequest.json');
    JsonToObject(JsonText, Request);
    CheckEquals('+998909999999', Request.sms_phone_number, 'sms_phone_number');
    Fields.Values['sms_phone_number'] := '+79152345678';
    JsonText := UpdateJsonFields(JsonText, Fields);
    JsonToObject(JsonText, Request);
    CheckEquals('+79152345678', Request.sms_phone_number, 'sms_phone_number');
  finally
    Fields.Free;
    Request.Free;
  end;
end;

type
  { TStringTest }

  TStringTest = class(TJsonPersistent)
  private
    FLines: TStrings;
    FLine: WideString;
    procedure SetLines(const Value: TStrings);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property Line: WideString read FLine write FLine;
    property Lines: TStrings read FLines write SetLines;
  end;

procedure TJsonUtilsTest.TestEncodeJsonString;
var
  Text: WideString;
  Test: TStringTest;
const
  Barcode = '0104601662000016215d>9nB'#$1D'934x0v'#$0D;
begin
  Test := TStringTest.Create;
  try
    Test.Line := Barcode;
    Test.Lines.Add(Barcode);
    Test.Lines.Add(Barcode);

    Text := ObjectToJson(Test);
    Test.Free;
    Test := TStringTest.Create;
    JsonToObject(Text, Test);

    CheckEquals(Barcode, Test.Line, 'Test.Line');
    CheckEquals(2, Test.Lines.Count, 'Test.Lines.Count');
    CheckEquals(Barcode, Test.Lines[0], 'Test.Lines[0]');
    CheckEquals(Barcode, Test.Lines[1], 'Test.Lines[1]');
  finally
    Test.Free;
  end;
end;

procedure TStringTest.SetLines(const Value: TStrings);
begin
  FLines.Assign(Value);
end;

{ TStringTest }

constructor TStringTest.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
end;

destructor TStringTest.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

initialization
  RegisterTest('', TJsonUtilsTest.Suite);


end.

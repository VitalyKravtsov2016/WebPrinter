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

initialization
  RegisterTest('', TJsonUtilsTest.Suite);


end.

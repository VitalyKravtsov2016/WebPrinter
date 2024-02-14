unit duLogFile;

interface

uses
  // VCL
  Windows, SysUtils, Classes,
  // DUnit
  TestFramework,
  // Tnt
  TntClasses,
  // This
  LogFile, StringUtils;

type
  { TLogFileTest }

  TLogFileTest = class(TTestCase)
  published
    procedure TestLogFile;
  end;

implementation

{ TLogFileTest }

procedure TLogFileTest.TestLogFile;
var
  Text: WideString;
  Text2: WideString;
  Strings: TTntStringList;
begin
  Text := '';
  Strings := TTntStringList.Create;
  try
    Strings.LastFileCharSet := csUnicode;
    Strings.LoadFromFile('UnicodeLine.txt');
    Text := Strings[0];
  finally
    Strings.Free;
  end;

  Text2 := TLogFile.VariantToStr(Text);
  Text := '''' + Text + '''';
  CheckEquals(Text, Text2);
  CheckEquals(WideStrToHex(Text), WideStrToHex(Text2));
end;

initialization
  RegisterTest('', TLogFileTest.Suite);


end.

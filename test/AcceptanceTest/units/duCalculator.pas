unit duCalculator;

interface

uses
  // VCL
  Windows, SysUtils, Classes, IniFiles,
  // DUnit
  TestFramework,
  // This
  FileUtils, TntClasses;

type
  { TCalculator }

  TCalculator = class(TTestCase)
  published
    procedure CalcAmount;
  end;

implementation

{ TCalculator }

procedure TCalculator.CalcAmount;
var
  i: Integer;
  Text: string;
  Line: string;
  Amount: Int64;
begin
  Line := '';
  Amount := 0;
  Text := ReadFileData('Amount.txt');
  for i := 1 to Length(Text) do
  begin
    case Text[i] of
      '0'..'9': Line := Line + Text[i];
      '+':
      begin
        if Line <> '' then
          Amount := Amount + StrToInt64(Line);
        Line := '';
      end;
      '=':
      begin
        Text := Text + IntToStr(Amount);
        WriteFileData('Amount.txt', Text);
        Break;
      end;
    end;
  end;
end;

initialization
  RegisterTest('', TCalculator.Suite);


end.

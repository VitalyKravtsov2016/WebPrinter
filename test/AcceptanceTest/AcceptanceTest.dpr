program AcceptanceTest;

uses
  Forms,
  TestFramework,
  GUITestRunner,
  duWebPrinter in 'units\duWebPrinter.pas',
  WebPrinter in '..\..\source\WebFptrSo\Units\WebPrinter.pas',
  LogFile in '..\..\source\Shared\LogFile.pas',
  WException in '..\..\source\Shared\WException.pas',
  JsonUtils in '..\..\source\Shared\JsonUtils.pas',
  DriverError in '..\..\source\Shared\DriverError.pas',
  FileUtils in '..\..\source\Shared\FileUtils.pas';

{$R *.RES}

begin
  TGUITestRunner.RunTest(RegisteredTests);
end.

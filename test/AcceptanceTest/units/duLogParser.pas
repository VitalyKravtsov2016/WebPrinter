unit duLogParser;

interface

uses
  // VCL
  Windows, SysUtils, Classes, IniFiles,
  // DUnit
  TestFramework,
  // This
  FileUtils, TntClasses;

type
  { TLogParser }

  TLogParser = class(TTestCase)
  published
    procedure ParseText;
  end;

implementation

{ TLogParser }

procedure TLogParser.ParseText;
var
  i: Integer;
  Line: WideString;
  Index: Integer;
  Lines: TTntStrings;
  Report: TTntStrings;
  Total: Int64;
  CashReceipt: Int64;
  CashReceipts: Int64;
  IsRefund: Boolean;
  RecTotal: Int64;
  CashAmount: Int64;
begin
  DeleteFile('Report.txt');

  IsRefund := False;
  CashReceipt := 0;
  CashReceipts := 0;
  Lines := TTntStringList.Create;
  Report := TTntStringList.Create;
  try
    Lines.LoadFromFile('SHTRIH-M-OPOS-1_2024.08.12.log');

    for i := 0 to Lines.Count-1 do
    begin
      Line := Lines[i];

      if Pos('PrintRecItemRefund', Line) <> 0 then
      begin
        IsRefund := True;
      end;

      Index := Pos('PrintRecTotal(', Line);
      if Index <> 0 then
      begin
        Line := Copy(Line, Index+14, 100);
        Index := Pos(', ''0'')=0', Line);
        if Index <> 0 then
        begin
          Line := Copy(Line, 1, Index-1);
          Index := Pos(',', Line);
          RecTotal := StrToInt(Copy(Line, 1, Index-1))*100;
          CashAmount := StrToInt(Copy(Line, Index+2, 100))*100;

          if CashAmount > RecTotal then
            CashAmount := RecTotal;

          if IsRefund then
            CashReceipt := CashReceipt - CashAmount
          else
            CashReceipt := CashReceipt + CashAmount;
        end;
      end;

      if Pos('EndFiscalReceipt(False)=0', Line) <> 0 then
      begin
        CashReceipts := CashReceipts + CashReceipt;
        Report.Add(Format('Receipt: %d, Total: %d', [CashReceipt, CashReceipts]));
        CashReceipt := 0;
        IsRefund := False;
      end;
      Index := Pos('"Õ¿À»◊Õ€’ ¬  ¿——≈","price":', Line);
      if Index <> 0 then
      begin
        Line := Copy(Line, Index + 27, 100);
        Index := Pos('}', Line);
        Line := Copy(Line, 1, Index-1);
        Total := StrToInt64(Line);
        Report.Add('—ash total: ' + Line);
        if Total <> CashReceipts then
        begin
          Report.Add('!!!! Cash not equals');
        end;
      end;

      if Pos('BeginFiscalReceipt', line) <> 0 then
      begin
        CashReceipt := 0;
      end;

      if Pos('total_sale_cash', line) <> 0 then
      begin
        Report.add(line);
      end;

      if Pos('total_refund_card', line) <> 0 then
      begin
        Report.add(line);
      end;

      if Pos('CashInECRAmount', line) <> 0 then
      begin
        Report.add(line);
      end;

      if Pos('total_sale_count', line) <> 0 then
      begin
        Report.add(line);
      end;


    end;
    Report.SaveToFile('Report.txt');
  finally
    Lines.Free;
    Report.Free;
  end;
end;

initialization
  RegisterTest('', TLogParser.Suite);


end.

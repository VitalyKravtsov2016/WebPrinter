unit fmuFptrReceiptTest;

interface

uses
  // VCL
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Registry, CheckLst,
  // Tnt
  TntStdCtrls, TntSysUtils,
  // This
  untPages, OposFiscalPrinter, OposFptr, DriverTest, PrinterTest;

type
  { TfmFptrReceiptTest }

  TfmFptrReceiptTest = class(TPage)
    btnExecute: TTntButton;
    Memo: TTntMemo;
    cbTest: TTntComboBox;
    procedure btnExecuteClick(Sender: TObject);
  private
    FTests: TDriverTests;
    procedure AddTest(TestClass: TDriverTestClass);
    property Tests: TDriverTests read FTests;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  fmFptrReceiptTest: TfmFptrReceiptTest;

implementation

{$R *.DFM}

{ TfmFptrReceiptTest }

constructor TfmFptrReceiptTest.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTests := TDriverTests.Create;
  AddTest(TCashInTest);
  AddTest(TCashOutTest);
  AddTest(TNonFiscalReceiptTest);
  AddTest(TGenericReceiptTest);
  AddTest(TSalesReceiptTest);
  AddTest(TRefundReceiptTest);
  AddTest(TRefundReceiptTest2);
  AddTest(TEmptySalesReceipt);
  AddTest(TEmptySalesReceipt2);
  AddTest(TEmptyRefundReceipt);
  AddTest(TEmptyRefundReceipt2);
  AddTest(TReceipt2);
  AddTest(TSalesReceiptTest2);
  AddTest(TSalesReceiptTest3);
  AddTest(TSalesReceiptTest4);
  AddTest(TSalesReceiptTest5);
  AddTest(TSalesReceiptTest6);
  AddTest(TSalesReceiptTest7);
  AddTest(TSalesReceiptTest8);
  AddTest(TSalesReceiptTest9);
  AddTest(TSalesReceiptTest10);
  AddTest(TSalesReceiptTest11);
  AddTest(TSalesReceiptTest12);
  AddTest(TZeroReceipt);
  AddTest(TRoundTest);
  AddTest(TReceiptDiscountTest);
  AddTest(TReceiptDiscountTest2);
  AddTest(TDiscountCardTest);
  AddTest(TDiscountCardTest2);
  AddTest(TQRCodeTest);
  AddTest(TTestReceipt2);
  AddTest(TTestReceipt3);
  AddTest(TTestReceipt4);
  AddTest(TTestReceipt5);
  AddTest(TTestReceipt6);
  AddTest(TTestReceipt7);
  AddTest(TTestReceipt8);
  AddTest(TTestReceipt9);
  AddTest(TTestReceipt10);
  AddTest(TTestReceipt11);
  AddTest(TTestDiscountReceipt);
  AddTest(TDiscountReceipt2);
  AddTest(TDiscountReceipt3);
  AddTest(TDiscountReceipt4);
  AddTest(TDiscountReceipt5);
  AddTest(TDiscountReceipt6);
  AddTest(TDiscountReceipt7);
  AddTest(TDiscountReceipt8);
  AddTest(TRetalixReceipt);
  AddTest(THangReceiptTest);
  AddTest(TRosneftReceiptTest);
  AddTest(TZeroReceiptTest);
  AddTest(TZeroReceiptTest2);
  cbTest.ItemIndex := 0;
end;

destructor TfmFptrReceiptTest.Destroy;
begin
  FTests.Free;
  inherited Destroy;
end;

procedure TfmFptrReceiptTest.AddTest(TestClass: TDriverTestClass);
var
  Test: TDriverTest;
begin
  Test := TestClass.Create(FTests, Memo);
  cbTest.Items.Add(Format('%2d. %s', [FTests.Count, Test.GetDisplayText]));
end;

procedure TfmFptrReceiptTest.btnExecuteClick(Sender: TObject);
var
  Test: TDriverTest;
begin
  EnableButtons(False);
  try
    Test := Tests[cbTest.ItemIndex];
    Test.Memo.Clear;
    Test.Execute;
  finally
    EnableButtons(True);
  end;
end;

end.

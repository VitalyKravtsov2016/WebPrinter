unit WebPrinter;

interface

uses
  // VCL
  Windows, Classes, SysUtils,
  // Tnt
  TntClasses, TntRegistry,
  // Indy
  IdHTTP, IdSSLOpenSSL, IdHeaderList, IdURI,
  // This
  LogFile, JsonUtils, DriverError;

const
  //////////////////////////////////////////////////////////////////////////////
  // Receipt type constants

  WP_RECEIPT_TYPE_ORDER     = 'order';
  WP_RECEIPT_TYPE_PREPAID   = 'prepaid';
  WP_RECEIPT_TYPE_CREDIT    = 'credit';

  //////////////////////////////////////////////////////////////////////////////
  // PaymentType

  PaymentTypeCash             = 0;
  PaymentTypePrepaid          = 1;
  PaymentTypeCredit           = 2;

  //////////////////////////////////////////////////////////////////////////////
  (*
  # Units
  |ID|Description RU/UZB       |
  |--| ------------            |
  |1 | штук/dona               |
  |2 | пачка/pachka            |
  |3 | миллиграмм/milligramm   |
  |4 | грамм/gramm             |
  |5 | килограмм/kilogramm     |
  |6 | центнер/tsentner        |
  |7 | тонна/tonna             |
  |8 | миллиметр/millimetr     |
  |9 | сантиметр/santimetr     |
  |11| метр/metr               |
  |12| километр/kilometr       |
  |22| миллилитр/millilitr     |
  |23| литр/litr               |
  |26| комплект/set            |
  |27| сутки/tunu-kun          |
  |28| час/soat                |
  |33| коробка/quti            |
  |38| упаковка/qadoq          |
  |39| минут/daqiqa            |
  |41| баллон/ballon           |
  |42| день/kun                |
  |43| месяц/oy                |
  |49| рулон/rulon             |
  *)

  WP_UNIT_PEACE     = 1; // штук/dona
  WP_UNIT_PACK      = 2; // пачка/pachka
  WP_UNIT_MGRAMM    = 3; // пачка/pachka
  WP_UNIT_GRAMM     = 4; // грамм/gramm
  WP_UNIT_KG        = 5; // килограмм/kilogramm
  WP_UNIT_CENTNER   = 6; // центнер/tsentner
  WP_UNIT_TONNA     = 7; // тонна/tonna
  WP_UNIT_MM        = 8; // миллиметр/millimetr
  WP_UNIT_CM        = 9; // сантиметр/santimetr
  WP_UNIT_METR      = 11; // метр/metr
  WP_UNIT_KM        = 12; // километр/kilometr
  WP_UNIT_ML        = 22; // миллилитр/millilitr
  WP_UNIT_LITR      = 23; // литр/litr
  WP_UNIT_SET       = 26; // комплект/set
  WP_UNIT_DAY       = 27; // сутки/tunu-kun
  WP_UNIT_HOUR      = 28; // час/soat
  WP_UNIT_KOROBKA   = 33; // коробка/quti
  WP_UNIT_UPAKOVKA  = 38; // упаковка/qadoq
  WP_UNIT_MINUTE    = 39; // минут/daqiqa
  WP_UNIT_BALLON    = 41; // баллон/ballon
  WP_UNIT_DAY2      = 42; // день/kun
  WP_UNIT_MONTH     = 43; // месяц/oy
  WP_UNIT_RULON     = 49; // рулон/rulon

type
  { TWPError }

  TWPError = class(TJsonPersistent)
  private
    FCode: Integer;
    FMessage: WideString;
    FData: WideString;
  published
    property code: Integer read FCode write FCode;
    property message: WideString read FMessage write FMessage;
    property data: WideString read FData write FData;
  end;

  { TWPResponse }

  TWPResponse = class(TJsonPersistent)
  private
    Ferror: TWPError;
    Fis_success: Boolean;
    procedure SetError(const Value: TWPError);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property error: TWPError read FError write SetError;
    property is_success: Boolean read Fis_success write Fis_success;
  end;

  { TWPResult }

  TWPResult = class(TJsonPersistent)
  private
    FResult: TWPResponse;
    procedure SetResult(const Value: TWPResponse);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property result: TWPResponse read Fresult write SetResult;
  end;

  { TWPInfoResponse }

  TWPInfoResponse = class(TJsonPersistent)
  private
    Fterminal_id: WideString;               // Fiscal module number
    Fapplet_version: WideString;            // Fiscal module applet version;
    Fcurrent_receipt_seq: WideString;       // Current receipt seq
    Fcurrent_time: WideString;              // Current time
    Flast_operation_time: WideString;       // Last operation time
    Freceipt_count: Integer;                // Receipt count
    Freceipt_max_count: Integer;            // Receipt max count
    Fzreport_count: Integer;                // Zreport count
    Fzreport_max_count: Integer;            // Zreport_max_count
    Favailable_persistent_memory: Integer;  // Available persistent memory
    Favailable_reset_memory: Integer;       // Available reset memory
    Favailable_deselect_memory: Integer;    // Available deselect memory
    Fcashbox_number: Integer;               // Cashbox number
    Fversion_code: WideString;              // Version code
    Fis_updated: Boolean;                   // Is updated
  published
    property terminal_id: WideString read Fterminal_id write Fterminal_id;
    property applet_version: WideString read Fapplet_version write Fapplet_version;
    property current_receipt_seq: WideString read Fcurrent_receipt_seq write Fcurrent_receipt_seq;
    property current_time: WideString read Fcurrent_time write Fcurrent_time;
    property last_operation_time: WideString read Flast_operation_time write Flast_operation_time;
    property receipt_count: Integer read Freceipt_count write Freceipt_count;
    property receipt_max_count: Integer read Freceipt_max_count write Freceipt_max_count;
    property zreport_count: Integer read Fzreport_count write Fzreport_count;
    property zreport_max_count: Integer read Fzreport_max_count write Fzreport_max_count;
    property available_persistent_memory: Integer read Favailable_persistent_memory write Favailable_persistent_memory;
    property available_reset_memory: Integer read Favailable_reset_memory write Favailable_reset_memory;
    property available_deselect_memory: Integer read Favailable_deselect_memory write Favailable_deselect_memory;
    property cashbox_number: Integer read Fcashbox_number write Fcashbox_number;
    property version_code: WideString read Fversion_code write Fversion_code;
    property is_updated: Boolean read Fis_updated write Fis_updated;
  end;

  { TWPComissionInfo }

  TWPComissionInfo = class(TJsonPersistent)
  private
    Fpinfl: WideString;
    Finn: WideString;
  published
    property inn: WideString read Finn write Finn;
    property pinfl: WideString read Fpinfl write Fpinfl;
  end;

  { TWPTime }

  TWPTime = class(TJsonPersistent)
  private
    FTime: WideString;
    FVersion: WideString;
  published
    property time: WideString read FTime write FTime;
    property applet_version: WideString read FVersion write FVersion;
  end;

  { TWPOpenDayResponse }

  TWPOpenDayResponse = class(TJsonPersistent)
  private
    Fdata: TWPTime;
    Ferror: TWPError;
    Fis_success: Boolean;
    procedure SetData(const Value: TWPTime);
    procedure SetError(const Value: TWPError);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property data: TWPTime read FData write SetData;
    property error: TWPError read FError write SetError;
    property is_success: Boolean read Fis_success write Fis_success;
  end;

  { TWPProduct }

  TWPProduct = class(TJsonCollectionItem)
  private
    Fname: WideString;
    Fbarcode: WideString;
    Famount: Integer;
    Funits: Integer;
    Fprice: Integer;
    Fproduct_price: Integer;
    Fvat: Integer;
    Fvat_percent: Integer;
    Fdiscount: Integer;
    Fdiscount_percent: Integer;
    Fother: Integer;
    Flabels: TStrings;
    Fclass_code: WideString;
    Fpackage_code: Integer;
    Fowner_type: Integer;
    Fcomission_info: TWPComissionInfo;
    procedure Setcomission_info(const Value: TWPComissionInfo);
    procedure Setlabels(const Value: TStrings);
  public
    constructor Create(Collection: TJsonCollection); override;
    destructor Destroy; override;
  published
    property name: WideString read Fname write Fname;
    property barcode: WideString read Fbarcode write Fbarcode;
    property amount: Integer read Famount write Famount;
    property units: Integer read Funits write Funits;
    property price: Integer read Fprice write Fprice;
    property product_price: Integer read Fproduct_price write Fproduct_price;
    property vat: Integer read Fvat write Fvat;
    property vat_percent: Integer read Fvat_percent write Fvat_percent;
    property discount: Integer read Fdiscount write Fdiscount;
    property discount_percent: Integer read Fdiscount_percent write Fdiscount_percent;
    property other: Integer read Fother write Fother;
    property labels: TStrings read Flabels write Setlabels;
    property class_code: WideString read Fclass_code write Fclass_code;
    property package_code: Integer read Fpackage_code write Fpackage_code;
    property owner_type: Integer read Fowner_type write Fowner_type;
    property comission_info: TWPComissionInfo read Fcomission_info write Setcomission_info;
  end;

  { TWPProducts }

  TWPProducts = class(TJsonCollection)
  protected
    function GetItem(Index: Integer): TWPProduct;
  public
    property Items[Index: Integer]: TWPProduct read GetItem; default;
  end;

  { TWPBanner }

  TWPBanner = class(TJsonCollectionItem)
  private
    F_type: WideString;
    Fdata: WideString;
  published
    property _type: WideString read F_type write F_type;
    property data: WideString read Fdata write Fdata;
  end;

  { TWPBanners }

  TWPBanners = class(TJsonCollection)
  published
    function GetItem(Index: Integer): TWPBanner;
  public
    property Items[Index: Integer]: TWPBanner read GetItem; default;
  end;

  { TWPPrice }

  TWPPrice = class(TJsonCollectionItem)
  private
    Fname: WideString;
    Fprice: Integer;
    Fvat_type: WideString;
    Fvat_price: Integer;
  published
    property name: WideString read Fname write Fname;
    property price: Integer read Fprice write Fprice;
    property vat_type: WideString read Fvat_type write Fvat_type;
    property vat_price: Integer read Fvat_price write Fvat_price;
  end;

  { TWPPrices }

  TWPPrices = class(TJsonCollection)
  published
    function GetItem(Index: Integer): TWPPrice;
  public
    property Items[Index: Integer]: TWPPrice read GetItem; default;
  end;

  { TWPOrder }

  TWPOrder = class(TJsonPersistent)
  private
	  Fnumber: Integer;
	  Freceipt_type: WideString;
	  Fproducts: TWPProducts;
	  Ftime: WideString;
	  Fcashier: WideString;
	  Freceived_cash: Integer;
	  Fchange: Integer;
	  Freceived_card: Integer;
	  Fopen_cashbox: Boolean;
	  Fsend_email: Boolean;
	  Femail: WideString;
	  Fsms_phone_number: WideString;
	  Fbanners: TWPBanners;
	  Fprices: TWPPrices;
    procedure SetBanners(const Value: TWPBanners);
    procedure SetPrices(const Value: TWPPrices);
    procedure SetProducts(const Value: TWPProducts);
  public
    constructor Create;
    destructor Destroy; override;
	  property receipt_type: WideString read Freceipt_type write Freceipt_type;
  published
	  property number: Integer read Fnumber write Fnumber;
	  property products: TWPProducts read Fproducts write SetProducts;
	  property time: WideString read FTime write FTime;
	  property cashier: WideString read Fcashier write Fcashier;
	  property received_cash: Integer read Freceived_cash write Freceived_cash;
	  property change: Integer read Fchange write Fchange;
	  property received_card: Integer read Freceived_card write Freceived_card;
	  property open_cashbox: Boolean read Fopen_cashbox write Fopen_cashbox;
	  property send_email: Boolean read Fsend_email write Fsend_email;
	  property email: WideString read Femail write Femail;
	  property sms_phone_number: WideString read Fsms_phone_number write Fsms_phone_number;
	  property banners: TWPBanners read Fbanners write SetBanners;
	  property prices: TWPPrices read Fprices write SetPrices;
  end;

  { TWPCreateOrderResult }

  TWPCreateOrderResult = class(TJsonPersistent)
  private
    FReceiptCount: Integer;
    FQRURL: WideString;
    FTerminalID: WideString;
    FFiscalSign: WideString;
    FDateTime: WideString;
    FAppletVersion: WideString;
    FCashBoxNumber: WideString;
  published
    property terminal_id: WideString read FTerminalID write FTerminalID;
    property receipt_count: Integer read FReceiptCount write FReceiptCount;
    property date_time: WideString read FDateTime write FDateTime;
    property fiscal_sign: WideString read FFiscalSign write FFiscalSign;
    property applet_version: WideString read FAppletVersion write FAppletVersion;
    property qr_url: WideString read FQRURL write FQRURL;
    property cash_box_number: WideString read FCashBoxNumber write FCashBoxNumber;
  end;

  { TWPCreateOrderResponse }

  TWPCreateOrderResponse = class(TJsonPersistent)
  private
    Fdata: TWPCreateOrderResult;
    Ferror: TWPError;
    Fis_success: Boolean;
    procedure SetData(const Value: TWPCreateOrderResult);
    procedure SetError(const Value: TWPError);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property data: TWPCreateOrderResult read FData write SetData;
    property error: TWPError read FError write SetError;
    property is_success: Boolean read Fis_success write Fis_success;
  end;

  { TWPInfoCommand }

  TWPInfoCommand = class(TJsonPersistent)
  private
    FError: TWPError;
    FData: TWPInfoResponse;
    procedure SetData(const Value: TWPInfoResponse);
    procedure SetError(const Value: TWPError);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property Error: TWPError read FError write SetError;
    property Data: TWPInfoResponse read FData write SetData;
  end;

  { TWPCurrency  }

  TWPCurrency = class(TJsonCollectionItem)
  private
    FPrice: Int64;
    FName: WideString;
  published
    property name: WideString read FName write FName;
    property price: Int64 read FPrice write FPrice;
  end;

  { TWPCurrencies }

  TWPCurrencies = class(TJsonCollection)
  protected
    function GetItem(Index: Integer): TWPCurrency;
  public
    property Items[Index: Integer]: TWPCurrency read GetItem; default;
  end;

  { TWPCloseDayRequest }

  TWPCloseDayRequest = class(TJsonPersistent)
  private
    FClose: Boolean;
    FTime: TDateTime;
    FName: WideString;
    FPrices: TWPCurrencies;
    procedure SetPrices(const Value: TWPCurrencies);
  public
    constructor Create;
    destructor Destroy; override;
    property Time: TDateTime read FTime write FTime;
  published
    property name: WideString read Fname write Fname;
    property prices: TWPCurrencies read Fprices write SetPrices;
    property close_zreport: Boolean read FClose write FClose;
  end;

  { TWPDayResult }

  TWPDayResult = class(TJsonPersistent)
  private
    Ftotal_sale_count: Int64;
    Ftotal_refund_count: Int64;
    Ftotal_sale_cash: Int64;
    Ftotal_refund_vat: Int64;
    Ftotal_sale_vat: Int64;
    Ftotal_sale_card: Int64;
    Ftotal_refund_card: Int64;
    Ftotal_refund_cash: Int64;
    Flast_receipt_seq: Integer;
    Fnumber: Integer;
    Fcount: Integer;
    Ffirst_receipt_seq: Integer;
    Fapplet_version: WideString;
    Fterminal_id: WideString;
    Fopen_time: WideString;
    Fclose_time: WideString;
  published
    property applet_version: WideString read Fapplet_version write Fapplet_version;
    property terminal_id: WideString read Fterminal_id write Fterminal_id;
    property number: Integer read Fnumber write Fnumber;
    property count: Integer read Fcount write Fcount;
    property last_receipt_seq: Integer read Flast_receipt_seq write Flast_receipt_seq;
    property first_receipt_seq: Integer read Ffirst_receipt_seq write Ffirst_receipt_seq;
    property open_time: WideString read Fopen_time write Fopen_time;
    property close_time: WideString read Fclose_time write Fclose_time;
    property total_refund_vat: Int64 read Ftotal_refund_vat write Ftotal_refund_vat;
    property total_refund_card: Int64 read Ftotal_refund_card write Ftotal_refund_card;
    property total_refund_cash: Int64 read Ftotal_refund_cash write Ftotal_refund_cash;
    property total_refund_count: Int64 read Ftotal_refund_count write Ftotal_refund_count;
    property total_sale_vat: Int64 read Ftotal_sale_vat write Ftotal_sale_vat;
    property total_sale_card: Int64 read Ftotal_sale_card write Ftotal_sale_card;
    property total_sale_cash: Int64 read Ftotal_sale_cash write Ftotal_sale_cash;
    property total_sale_count: Int64 read Ftotal_sale_count write Ftotal_sale_count;
  end;


  { TWPCloseDayResponse }

  TWPCloseDayResponse = class(TJsonPersistent)
  private
    Fdata: TWPDayResult;
    Ferror: TWPError;
    Fis_success: Boolean;
    procedure SetError(const Value: TWPError);
    procedure SetData(const Value: TWPDayResult);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property data: TWPDayResult read FData write SetData;
    property error: TWPError read FError write SetError;
    property is_success: Boolean read Fis_success write Fis_success;
  end;

  { TWPCloseDayResponse2 }

  TWPCloseDayResponse2 = class(TJsonPersistent)
  private
    FResult: TWPCloseDayResponse;
    procedure SetResult(const Value: TWPCloseDayResponse);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property result: TWPCloseDayResponse read Fresult write SetResult;
  end;

  { TWPPaymentRequest }

  TWPPaymentRequest = class(TJsonPersistent)
  private
    FAmount: Int64;
    FQRCode: WideString;
  published
    property amount: Int64 read FAmount write FAmount;
    property qr_code: WideString read FQRCode write FQRCode;
  end;

  { TWPPaymentResult }

  TWPPaymentResult = class(TJsonPersistent)
  private
    FAmount: Int64;
    FDeviceID: WideString;
    FPaymentID: WideString;
    FTransactionID: WideString;
    FStatus: WideString;
    FMessage: WideString;
    FPhoneNumber: WideString;
    FInn: WideString;
    FQRCode: WideString;
    FKKMID: WideString;
  published
    property amount: Int64 read FAmount write FAmount;
    property transaction_id: WideString read FTransactionID write FTransactionID;
    property payment_id: WideString read FPaymentID write FPaymentID;
    property inn: WideString read FInn write FInn;
    property qr_code: WideString read FQRCode write FQRCode;
    property kkm_id: WideString read FKKMID write FKKMID;
    property device_id: WideString read FDeviceID write FDeviceID;
    property status: WideString read FStatus write FStatus;
    property message: WideString read FMessage write FMessage;
    property client_phone_number: WideString read FPhoneNumber write FPhoneNumber;
  end;

  { TWPPaymentResponse }

  TWPPaymentResponse = class(TJsonPersistent)
  private
    FError: TWPError;
    FSuccess: Boolean;
    FData: TWPPaymentResult;
    procedure SetData(const Value: TWPPaymentResult);
    procedure SetError(const Value: TWPError);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property error: TWPError read FError write SetError;
    property data: TWPPaymentResult read FData write SetData;
    property is_success: Boolean read FSuccess write FSuccess;
  end;

  { TWPPaymentConfirmRequest }

  TWPPaymentConfirmRequest = class(TJsonPersistent)
  private
    FQRCode: WideString;
    FPaymentID: WideString;
  published
    property qr_code: WideString read FQRCode write FQRCode;
    property payment_id: WideString read FPaymentID write FPaymentID;
  end;

  { TWPPaymentConfirmResult }

  TWPPaymentConfirmResult = class(TJsonPersistent)
  private
    FPaymentID: WideString;
    FStatus: WideString;
    Finn: WideString;
    FQRCode: WideString;
  published
    property inn: WideString read Finn write Finn;
    property payment_id: WideString read FPaymentID write FPaymentID;
    property qr_code: WideString read FQRCode write FQRCode;
    property status: WideString read FStatus write FStatus;
  end;

  { TWPPaymentConfirmResponse }

  TWPPaymentConfirmResponse = class(TJsonPersistent)
  private
    FError: TWPError;
    FSuccess: Boolean;
    FData: TWPPaymentConfirmResult;
    procedure SetError(const Value: TWPError);
    procedure SetData(const Value: TWPPaymentConfirmResult);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property error: TWPError read FError write SetError;
    property is_success: Boolean read FSuccess write FSuccess;
    property data: TWPPaymentConfirmResult read FData write SetData;
  end;

  { TWebPrinter }

  TWebPrinter = class
  private
    FLogger: ILogFile;
    FTestMode: Boolean;
    FAddress: WideString;
    FConnectTimeout: Integer;

    FRaiseErrors: Boolean;
    FTransport: TIdHTTP;
    FAnswerJson: WideString;
    FRequestJson: WideString;
    FInfo: TWPInfoCommand;
    FResponse: TWPResponse;
    FOpenDayResponse: TWPOpenDayResponse;
    FCloseDayResponse: TWPCloseDayResponse;
    FCloseDayResponse2: TWPCloseDayResponse2;
    FPaymentResponse: TWPPaymentResponse;
    FPaymentConfirmResponse: TWPPaymentConfirmResponse;
    FCreateOrderResponse: TWPCreateOrderResponse;
    FPrintLastReceipt: TWPResult;

    function GetTransport: TIdHTTP;
    function GetAddress: WideString;
    function SendJson(const AURL, Request: WideString;
      IsGetRequest: Boolean): WideString;
    procedure CheckForError(const Error: TWPError);
  public
    constructor Create(ALogger: ILogFile);
    destructor Destroy; override;

    procedure Connect;
    procedure Disconnect;
    function ReadInfo: WideString;
    function ReadInfo2: TWPInfoCommand;
    function OpenFiscalDay(Time: TDateTime): WideString;
    function OpenFiscalDay2(Time: TDateTime): TWPOpenDayResponse;
    function CloseFiscalDay(Time: TDateTime): WideString;
    function CloseFiscalDay2(Time: TDateTime): TWPCloseDayResponse;
    function PrintZReport(Request: TWPCloseDayRequest): TWPCloseDayResponse;
    function ReadZReport: TWPCloseDayResponse2;
    function OpenCashDrawer: TWPResponse;
    function PaymentClick(Request: TWPPaymentRequest): TWPPaymentResponse;
    function PaymentClickConfirm(Request: TWPPaymentConfirmRequest): TWPPaymentConfirmResponse;
    function CreateOrder(Request: TWPOrder): TWPCreateOrderResponse;
    function ReturnOrder(Request: TWPOrder): TWPCreateOrderResponse;
    function PrintLastReceipt: TWPResult;

    function GetJson(const AURL: WideString): WideString;
    function PostJson(const AURL, Request: WideString): WideString;

    property Info: TWPInfoCommand read FInfo;
    property Transport: TIdHTTP read GetTransport;
    property TestMode: Boolean read FTestMode write FTestMode;
    property Address: WideString read FAddress write FAddress;
    property RaiseErrors: Boolean read FRaiseErrors write FRaiseErrors;
    property AnswerJson: WideString read FAnswerJson write FAnswerJson;
    property RequestJson: WideString read FRequestJson write FRequestJson;
    property OpenDayResponse: TWPOpenDayResponse read FOpenDayResponse;
    property CloseDayResponse: TWPCloseDayResponse read FCloseDayResponse;
    property CloseDayResponse2: TWPCloseDayResponse2 read FCloseDayResponse2;
    property ConnectTimeout: Integer read FConnectTimeout write FConnectTimeout;
  end;

function WPDateTimeToStr(Time: TDateTime): string;

implementation

function WPDateTimeToStr(Time: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', Time);
end;

{ TWPResult }

constructor TWPResult.Create;
begin
  inherited Create;
  FResult := TWPResponse.Create;
end;

destructor TWPResult.Destroy;
begin
  FResult.Free;
  inherited Destroy;
end;

procedure TWPResult.SetResult(const Value: TWPResponse);
begin
  FResult.Assign(Value);
end;


{ TWPInfoCommand }

constructor TWPInfoCommand.Create;
begin
  inherited Create;
  FError := TWPError.Create;
  FData := TWPInfoResponse.Create;
end;

destructor TWPInfoCommand.Destroy;
begin
  FData.Free;
  FError.Free;
  inherited Destroy;
end;

procedure TWPInfoCommand.SetData(const Value: TWPInfoResponse);
begin
  FData.Assign(Value);
end;

procedure TWPInfoCommand.SetError(const Value: TWPError);
begin
  FError.Assign(Value);
end;

{ TWPOrder }

constructor TWPOrder.Create;
begin
  inherited Create;
  FProducts := TWPProducts.Create(TWPProduct);
  FBanners := TWPBanners.Create(TWPBanner);
  FPrices := TWPPrices.Create(TWPPrice);
end;

destructor TWPOrder.Destroy;
begin
  FProducts.Free;
  FBanners.Free;
  FPrices.Free;
  inherited Destroy;
end;

procedure TWPOrder.SetBanners(const Value: TWPBanners);
begin
  FBanners.Assign(Value);
end;

procedure TWPOrder.SetPrices(const Value: TWPPrices);
begin
  FPrices.Assign(Value);
end;

procedure TWPOrder.SetProducts(const Value: TWPProducts);
begin
  FProducts.Assign(Value);
end;

{ TWPProduct }

constructor TWPProduct.Create(Collection: TJsonCollection);
begin
  inherited Create(Collection);
  FLabels := TStringList.Create;
  FComission_info := TWPComissionInfo.Create;
end;

destructor TWPProduct.Destroy;
begin
  FLabels.Free;
  FComission_info.Free;
  inherited Destroy;
end;

procedure TWPProduct.Setcomission_info(const Value: TWPComissionInfo);
begin
  Fcomission_info.Assign(Value);
end;

procedure TWPProduct.Setlabels(const Value: TStrings);
begin
  Flabels.Assign(Value);
end;

{ TWPProducts }

function TWPProducts.GetItem(Index: Integer): TWPProduct;
begin
  Result := inherited Items[Index] as TWPProduct;
end;

{ TWPBanners }

function TWPBanners.GetItem(Index: Integer): TWPBanner;
begin
  Result := inherited Items[Index] as TWPBanner;
end;

{ TWPPrices }

function TWPPrices.GetItem(Index: Integer): TWPPrice;
begin
  Result := inherited Items[Index] as TWPPrice;
end;

{ TWPOpenDayResponse }

constructor TWPOpenDayResponse.Create;
begin
  inherited Create;
  Fdata := TWPTime.Create;
  Ferror := TWPError.Create;
end;

destructor TWPOpenDayResponse.Destroy;
begin
  Fdata.Free;
  Ferror.Free;
  inherited Destroy;
end;

procedure TWPOpenDayResponse.SetData(const Value: TWPTime);
begin
  FData.Assign(Value);
end;

procedure TWPOpenDayResponse.SetError(const Value: TWPError);
begin
  FError.Assign(Value);
end;

{ TWPCloseDayResponse2 }

constructor TWPCloseDayResponse2.Create;
begin
  inherited Create;
  FResult := TWPCloseDayResponse.Create;
end;

destructor TWPCloseDayResponse2.Destroy;
begin
  FResult.Free;
  inherited Destroy;
end;

procedure TWPCloseDayResponse2.SetResult(const Value: TWPCloseDayResponse);
begin
  FResult.Assign(Value);
end;

{ TWPCloseDayRequest }

constructor TWPCloseDayRequest.Create;
begin
  inherited Create;
  FPrices := TWPCurrencies.Create(TWPCurrency);
end;

destructor TWPCloseDayRequest.Destroy;
begin
  FPrices.Free;
  inherited Destroy;
end;

procedure TWPCloseDayRequest.SetPrices(const Value: TWPCurrencies);
begin
  FPrices.Assign(Value);
end;

{ TWPCurrencies }

function TWPCurrencies.GetItem(Index: Integer): TWPCurrency;
begin
  Result := inherited Items[Index] as TWPCurrency;
end;

{ TWPCloseDayResponse }

constructor TWPCloseDayResponse.Create;
begin
  inherited Create;
  Fdata := TWPDayResult.Create;
  Ferror := TWPError.Create;
end;

destructor TWPCloseDayResponse.Destroy;
begin
  Fdata.Free;
  Ferror.Free;
  inherited Destroy;
end;

procedure TWPCloseDayResponse.SetData(const Value: TWPDayResult);
begin
  FData.Assign(Value);
end;

procedure TWPCloseDayResponse.SetError(const Value: TWPError);
begin
  FError.Assign(Value);
end;

{ TWPResponse }

constructor TWPResponse.Create;
begin
  inherited Create;
  FError := TWPError.Create;
end;

destructor TWPResponse.Destroy;
begin
  FError.Free;
  inherited Destroy;
end;

procedure TWPResponse.SetError(const Value: TWPError);
begin
  FError.Assign(Value);
end;

{ TWPPaymentResponse }

constructor TWPPaymentResponse.Create;
begin
  inherited Create;
  FError := TWPError.Create;
  FData := TWPPaymentResult.Create;
end;

destructor TWPPaymentResponse.Destroy;
begin
  FData.Free;
  FError.Free;
  inherited Destroy;
end;

procedure TWPPaymentResponse.SetData(const Value: TWPPaymentResult);
begin
  FData.Assign(Value);
end;

procedure TWPPaymentResponse.SetError(const Value: TWPError);
begin
  FError.Assign(Value);
end;

{ TWPPaymentConfirmResponse }

constructor TWPPaymentConfirmResponse.Create;
begin
  inherited Create;
  FError := TWPError.Create;
  FData := TWPPaymentConfirmResult.Create;
end;

destructor TWPPaymentConfirmResponse.Destroy;
begin
  FData.Free;
  FError.Free;
  inherited Destroy;
end;

procedure TWPPaymentConfirmResponse.SetData(
  const Value: TWPPaymentConfirmResult);
begin
  FData.Assign(Value);
end;

procedure TWPPaymentConfirmResponse.SetError(const Value: TWPError);
begin
  FError.Assign(Value);
end;

{ TWPCreateOrderResponse }

constructor TWPCreateOrderResponse.Create;
begin
  inherited Create;
  FError := TWPError.Create;
  FData := TWPCreateOrderResult.Create;
end;

destructor TWPCreateOrderResponse.Destroy;
begin
  FData.Free;
  FError.Free;
  inherited Destroy;
end;

procedure TWPCreateOrderResponse.SetData(
  const Value: TWPCreateOrderResult);
begin
  FData.Assign(Value);
end;

procedure TWPCreateOrderResponse.SetError(const Value: TWPError);
begin
  FError.Assign(Value);
end;

{ TWebPrinter }

constructor TWebPrinter.Create(ALogger: ILogFile);
begin
  inherited Create;
  FLogger := ALogger;
  FAddress := 'https://devkkm.webkassa.kz/';
  FInfo := TWPInfoCommand.Create;
  FOpenDayResponse := TWPOpenDayResponse.Create;
  FCloseDayResponse := TWPCloseDayResponse.Create;
  FCloseDayResponse2 := TWPCloseDayResponse2.Create;
  FResponse := TWPResponse.Create;
  FPaymentResponse := TWPPaymentResponse.Create;
  FPaymentConfirmResponse := TWPPaymentConfirmResponse.Create;
  FCreateOrderResponse := TWPCreateOrderResponse.Create;
  FPrintLastReceipt := TWPResult.Create;
end;

destructor TWebPrinter.Destroy;
begin
  FInfo.Free;
  FResponse.Free;
  FTransport.Free;
  FOpenDayResponse.Free;
  FCloseDayResponse.Free;
  FPaymentResponse.Free;
  FPaymentConfirmResponse.Free;
  FCreateOrderResponse.Free;
  FPrintLastReceipt.Free;
  inherited Destroy;
end;

function TWebPrinter.GetAddress: WideString;
begin
  Result := FAddress;
  while IsPathDelimiter(Result, Length(Result)) do
    SetLength(Result, Length(Result)-1);
end;

function TWebPrinter.GetTransport: TIdHTTP;
begin
  if FTransport = nil then
  begin
    FTransport := TIdHTTP.Create;
    FTransport.ProtocolVersion := pv1_1;
    FTransport.Request.BasicAuthentication := False;
    FTransport.Request.UserAgent := '';
    FTransport.Request.Accept := 'application/json, */*; q=0.01';
    FTransport.Request.ContentType := 'application/json; charset=UTF-8';
    FTransport.Request.CharSet := 'utf-8';
    FTransport.ConnectTimeout := FConnectTimeout;
  end;
  Result := FTransport;
end;

function TWebPrinter.SendJson(const AURL, Request: WideString;
  IsGetRequest: Boolean): WideString;
var
  S: AnsiString;
  URL: WideString;
  Stream: TStream;
  DstStream: TStream;
  Answer: AnsiString;
begin
  URL := AURL;
  FRequestJson := UTF8Decode(Request);
  if IsGetRequest then
    FLogger.Debug('GET: ' + URL)
  else
    FLogger.Debug('POST: ' + URL);

  FLogger.Debug('=> ' + FRequestJson);

  if FTestMode then
  begin
    Result := FAnswerJson;
    FLogger.Debug('<= ' + UTF8Decode(FAnswerJson));
    Exit;
  end;

  Stream := TMemoryStream.Create;
  DstStream := TMemoryStream.Create;
  try
    try
      S := Request;
      Stream.WriteBuffer(S[1], Length(S));

      Transport.Request.Date := Now;
      if IsGetRequest then
      begin
        Transport.Get(URL, DstStream);
      end else
      begin
        Transport.Post(URL, Stream, DstStream);
      end;
      Answer := '';
      if DstStream.Size > 0 then
      begin
        DstStream.Seek(0, 0);
        SetLength(Answer, DstStream.Size);
        DstStream.ReadBuffer(Answer[1], DstStream.Size);
      end;
      Result := Answer;
      FAnswerJson := Result;
      FLogger.Debug('<= ' + UTF8Decode(Answer));
    finally
      Stream.Free;
      DstStream.Free;
    end;
  except
    on E: Exception do
    begin
      FLogger.Error(E.Message);
      raise;
    end;
  end;
end;

function TWebPrinter.GetJson(const AURL: WideString): WideString;
begin
  Result := SendJson(AURL, '', True);
end;

function TWebPrinter.PostJson(const AURL, Request: WideString): WideString;
begin
  Result := SendJson(AURL, Request, False);
end;

(*
**URL** : `/info/`
**Method** : `GET`
**Auth required** : NO
*)

procedure TWebPrinter.CheckForError(const Error: TWPError);
begin
  if FRaiseErrors and (Error.code <> 0) then
  begin
    RaiseError(Error.code, Error.message);
  end;
end;

procedure TWebPrinter.Connect;
begin
  ReadInfo2;
end;

procedure TWebPrinter.Disconnect;
begin
  Transport.Disconnect;
end;

function TWebPrinter.ReadInfo: WideString;
begin
  Result := GetJson(GetAddress + '/info/');
end;

function TWebPrinter.ReadInfo2: TWPInfoCommand;
var
  JsonText: WideString;
begin
  JsonText := ReadInfo;
  JsonToObject(JsonText, FInfo);
  CheckForError(FInfo.Error);
  Result := FInfo;
end;

(*
**URL** : `/zreport/open/`
**Method** : `GET`
**Parameter** : `time [in format yyyy-MM-dd HH:mm:ss]`
**Auth required** : NO
*)

function TWebPrinter.OpenFiscalDay(Time: TDateTime): WideString;
var
  URL: WideString;
begin
  URL := GetAddress + '/zreport/open/' + '?' +
    TIdURI.ParamsEncode(Format('time=%s', [WPDateTimeToStr(time)]));
  Result := GetJson(URL);
end;

function TWebPrinter.OpenFiscalDay2(Time: TDateTime): TWPOpenDayResponse;
var
  JsonText: WideString;
begin
  JsonText := OpenFiscalDay(Time);
  JsonToObject(JsonText, FOpenDayResponse);
  CheckForError(FOpenDayResponse.Error);
  Result := FOpenDayResponse;
end;

(*
## Close ZReport
Operation for close ZReport / Закрытие кассовой смены
**URL** : `/zreport/close/`
**Method** : `GET`
**Parameter** : `time [in format yyyy-MM-dd HH:mm:ss]`
**Auth required** : NO
*)

function TWebPrinter.CloseFiscalDay(Time: TDateTime): WideString;
begin
  Result := GetJson(GetAddress + '/zreport/close' + '?' +
    TIdURI.ParamsEncode(Format('time=%s', [WPDateTimeToStr(time)])));
end;

function TWebPrinter.CloseFiscalDay2(Time: TDateTime): TWPCloseDayResponse;
var
  JsonText: WideString;
begin
  JsonText := CloseFiscalDay(Time);
  FCloseDayResponse.is_success := False;
  JsonToObject(JsonText, FCloseDayResponse);
  CheckForError(FCloseDayResponse.Error);
  Result := FCloseDayResponse;
end;

(*
## Close ZReport with print (X report = "false")
Operation for close ZReport / Закрытие кассовой смены с напечатыванием чека
**URL** : `/zreport/close/`
**Method** : `POST`
**Parameter** : `time [in format yyyy-MM-dd HH:mm:ss]`
**Auth required** : NO
*)

function TWebPrinter.PrintZReport(Request: TWPCloseDayRequest): TWPCloseDayResponse;
var
  URL: WideString;
  JsonText: WideString;
begin
  URL := GetAddress + '/zreport/close' + '?' +
    TIdURI.ParamsEncode(Format('time=%s', [WPDateTimeToStr(Request.time)]));

  JsonText := PostJson(URL, ObjectToJson(Request));
  JsonToObject(JsonText, FCloseDayResponse);
  CheckForError(FCloseDayResponse.error);
  Result := FCloseDayResponse;
end;

(*
## ZReport Info
Operation for ZReport Info / Проверка состояния кассовой смены
**URL** : `/zreport/info/`
**Method** : `GET`
**Auth required** : NO
*)

function TWebPrinter.ReadZReport: TWPCloseDayResponse2;
var
  JsonText: WideString;
begin
  JsonText := GetJson(GetAddress + '/zreport/info/');
  JsonToObject(JsonText, FCloseDayResponse2);
  if not FCloseDayResponse2.result.is_success then
    JsonToObject(JsonText, FCloseDayResponse2.result);

  CheckForError(FCloseDayResponse2.result.error);
  Result := FCloseDayResponse2;
end;

(*
Open cash drawer API \ Открытие денежнего ящика
**URL** : `print/open_cash_drawer`
**Method** : `GET`
**Auth required** : NO

## Response

```json
{
  "data":null,
  "error": {
    "code":[code of error],
    "message":[error message],
    "data":[extra data for error]
    },
  "is_success": [is success response]
}
*)

function TWebPrinter.OpenCashDrawer: TWPResponse;
var
  JsonText: WideString;
begin
  JsonText := GetJson(GetAddress + '/print/open_cash_drawer/');
  JsonToObject(JsonText, FResponse);
  CheckForError(FResponse.error);
  Result := FResponse;
end;

(*
# CLICK PASS / Оплата через CLICK PASS
Operation for create paymen via CLICK PASS
**URL** : `/payment/click`
**Method** : `POST`
**Auth required** : NO

## Request
```json
{
  "amount": [Payment price],
  "qr_code": [Qr code from CLICK PASS],
}
```
**Content** :
```
{
	"amount":500,
	"qr_code":"880101698207133392"
}
```

## Response

json
{
 "data":{
  "status_code": [status code],
  "status": [Status message],
  "message": [click response message],
  "transaction_id": [transaction_uuid],
  "payment_id": [payment_id],
  "amount": [Price],
   "qr_code": [Qr code from CLICK PASS],
  },
  "error": {
    "code":[code of error],
    "message":[error message],
    "data":[extra data for error]
    },
  "is_success": [is success response]
}
*)

function TWebPrinter.PaymentClick(Request: TWPPaymentRequest): TWPPaymentResponse;
var
  JsonText: WideString;
begin
  JsonText := PostJson(GetAddress + '/payment/click', ObjectToJson(Request));
  JsonToObject(JsonText, FPaymentResponse);
  CheckForError(FPaymentResponse.error);
  Result := FPaymentResponse;
end;

(*
# CLICK Fiscalization check / Отправка фискального чека в Click
Operation for send fiscalization check to CLICK
**URL** : `/payment/click_confirm`
**Method** : `POST`
**Auth required** : NO
*)

function TWebPrinter.PaymentClickConfirm(Request: TWPPaymentConfirmRequest): TWPPaymentConfirmResponse;
var
  JsonText: WideString;
begin
  JsonText := PostJson(GetAddress + '/payment/click_confirm', ObjectToJson(Request));
  JsonToObject(JsonText, FPaymentConfirmResponse);
  CheckForError(FPaymentConfirmResponse.error);
  Result := FPaymentConfirmResponse;
end;

(*
## Order create
Operation for create order / Продажа, аванс, кредит
**URL** : `/order/create/`
**Method** : `POST`
**Auth required** : NO
*)

function TWebPrinter.CreateOrder(Request: TWPOrder): TWPCreateOrderResponse;
var
  JsonText: WideString;
begin
  JsonText := PostJson(GetAddress + '/order/create/', ObjectToJson(Request));
  JsonToObject(JsonText, FCreateOrderResponse);
  CheckForError(FCreateOrderResponse.error);
  Result := FCreateOrderResponse;
end;

(*
## Order refuse
Operations for refuse order / Возврат
**URL** : `/order/refuse/`
**Method** : `POST`
**Auth required** : NO
**Data constraints**
*)

function TWebPrinter.ReturnOrder(Request: TWPOrder): TWPCreateOrderResponse;
var
  JsonText: WideString;
begin
  JsonText := PostJson(GetAddress + '/order/refuse/', ObjectToJson(Request));
  JsonToObject(JsonText, FCreateOrderResponse);
  CheckForError(FCreateOrderResponse.error);
  Result := FCreateOrderResponse;
end;

(*
## Order print
Operation for print last order / Печать последнего чека
**URL** : `/order/print/`
**Method** : `GET`
**Auth required** : NO
*)

function TWebPrinter.PrintLastReceipt: TWPResult;
var
  JsonText: WideString;
begin
  JsonText := GetJson(GetAddress + '/order/print/');
  JsonToObject(JsonText, FPrintLastReceipt);
  CheckForError(FPrintLastReceipt.result.error);
  Result := FPrintLastReceipt;
end;

end.

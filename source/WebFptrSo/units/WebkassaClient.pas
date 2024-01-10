unit WebkassaClient;

interface

uses
  // VCL
  Windows, Classes, SysUtils,
  // Tnt
  TntClasses, TntRegistry,
  // Json
  uLkJSON,
  // Indy
  IdHTTP, IdSSLOpenSSL, IdHeaderList,
  // This
  LogFile, JsonUtils, DriverError;


const
  // OperationType
  OperationTypeBuy            = 0;
  OperationTypeRetBuy         = 1;
  OperationTypeSell           = 2;
  OperationTypeRetSell        = 3;

  // PaymentType
  PaymentTypeCash             = 0;
  PaymentTypeCard             = 1;
  PaymentTypeCredit           = 2;
  PaymentTypeTare             = 3;
  PaymentTypeMobile           = 4;

  // OperationType
  OperationTypeCashIn         = 0;
  OperationTypeCashOut        = 1;

  // TaxType
  TaxTypeNoTax                = 0;
  TaxTypeVAT                  = 100;

  // CashboxStatus - ������� ������ �����
  CashboxStatusCreated        = 0; // �������
  CashboxStatusActive         = 1; // �������
  CashboxStatusBlockedByFDO   = 2; // ������������� ���
  CashboxStatusDataCorrupted  = 3; // �������� ����������� ������
  CashboxStatusBlockedByTI    = 4; // ������������� ��������� �����������
  CashboxStatusUnregistered   = 5; // ����� � �����

  // RoundType - ��� ����������
  RoundTypeNone               = 0; // ��� ����������
  RoundTypeTotal              = 1; // ���������� �����
  RoundTypeItems              = 2; // ���������� �������

  // ModifiersType - ��� ������������
  ModifierTypeDiscount        = 1; // ������
  ModifierTypeCharge          = 2; // �������

  // OfdCode - ��� ���
  OfdCodeKazakhtelecom        = 1; // ������������
  OfdCodeTranstelecom         = 2; // ������������
  OfdCodeKaztranscom          = 3; // �����������

  // PaperKind - ��� ������
  PaperKind80mm               = 0; // ������, ������� 80 ��.
  PaperKind58mm               = 3; // ������, ������� 57(58) ��.
  PaperKindA4Book             = 12; // ������ ������� �4 (������� ����������)
  PaperKindA4Album            = 13; // ������ ������� �4 (��������� ����������)


  // ItemType - ��� ������
  ItemTypeText                = 0; // �����
  ItemTypePicture             = 1; // ��������
  ItemTypeQRCode              = 2; // ������ ��� QR-����

  // TextStyle - ��� �����
  TextStyleNormal             = 0; // ������� �����
  TextStyleBold               = 1; // ������ �����

  /////////////////////////////////////////////////////////////////////////////
  // Error codes

  WEBKASSA_E_UNKNOWN                  = -1; // �����������
  WEBKASSA_E_INVALID_LOGIN_PASSWORD   = 1; // �������� ����� �/��� ������
  WEBKASSA_E_TOKEN_EXPIRED            = 2; // ���� �������� ������ �����
  WEBKASSA_E_NOT_AUTHORIZED           = 3; // ������������ �� �����������
  WEBKASSA_E_OPERATION_ACCESS_DENIED  = 4; // ��� ������� � ��������
  WEBKASSA_E_ACCESS_DENIED            = 5; // ��� ������� � �����
  WEBKASSA_E_NOT_FOUND                = 6; // ����� �� �������
  WEBKASSA_E_BLOCKED                  = 7; // ����� �������������
  WEBKASSA_E_NO_CASH                  = 8; // ������������ ����� ��� �������
  WEBKASSA_E_DATA_VALIDATION          = 9; // ������ ��������� ������
  WEBKASSA_E_NOT_ACTIVATED            = 10; // ����� �� ������������
  WEBKASSA_E_DAY_END_REQUIRED         = 11; // ����������������� ����� ��������� 24 ����
  WEBKASSA_E_DAY_CLOSED               = 12; // ����� ��� �������
  WEBKASSA_E_DAY_NOT_OPENED           = 13; // �� ������� �������� �����
  WEBKASSA_E_DUPLICATE_REC_NUM        = 14; // ������������� ��� �������-���������
  WEBKASSA_E_DAY_NOT_FOUND            = 15; // ����� �� �������
  WEBKASSA_E_REC_NOT_FOUND            = 16; // ��� �� ��������������� � ������ �����
  WEBKASSA_E_DAY_72_HOUR              = 18; // ����������������� ������ � ���������� ������ ��������� 72 ����
  WEBKASSA_E_DAY_OPENED               = 1014; // ������ ����� �������

(*

	public enum ApiErrorCode
	{
		UnknownError = -1,
		WrongCredentials = 1,
		TokenExpired = 2,
		NotAuthorized = 3,
		OperationAccessDenied = 4,
		CashAccessDenied = 5,
		CashboxNotFound = 6,
		CashBlocked = 7,
		NotEnoughMoney = 8,
		ValidationError = 9,
		CashboxNotActivated = 10,
		ShiftOpenedMoreThan24Hours = 11,
		ShiftAlreadyClosed = 12,
		ShiftNotFound = 13,
		DuplicateExternalCode = 14,
		ShiftDoesNotExist = 15,
		CheckNotFound = 16,
		DiscountMarkUpCanNotBeSpecified = 17,
		OfflineModeMoreThan72Hours = 18,
		CheckWithThisExternalNumberNotFound = 19,
		OrganizationAlreadyRegistered = 1000,
		EmployeeAlreadyRegistered = 1001,
		CashboxWithThisIDIsAlreadyRegistered = 1002,
		ActivationCardAlreadyWasUsed = 1003,
		WrongActivationCardData = 1004,
		WrongOldPassword = 1005,
		DuplicatePassword = 1006,
		SumIsNotToBeFraction = 1007,
		SumCanNotBeLessZero = 1008,
		EmployeeNotFound = 1009,
		CashboxNotFoundToAccess = 1010,
		PeriodDatesIncorrect = 1011,
		IdSalemNotFound = 1011,
		IncorrectTransactionStatus = 1012,
		OfflineChecksNotSupported = 1013,
		ZReportNotFound = 1014,
		ExternalPartnerNotFound = 1015,
		InvalidValidationCode = 1016,
		CashboxYetUsedExternalSystem = 1017,
		CashboxNotUsedExternalSystem = 1018,
		CantCancelTicket = 1019,
		WrongCashboxRegistrationInformation = 1020,
		CanNotCreatePacketForNonExistentXin = 1021,
		CanNotProlongatePacketForNonExistentXin = 1022,
		ActivationCardNeverUsed = 1023,
		OrganizationIsNotServiceCenter = 1030,
		Cashbox1CActivationNotAllowed = 1031,
		CanNotActivateCashbox = 1032,
		HasNoServiceCenterRights = 1033,
		OrganizationNotFound = 1034,
		DataEarlierCashboxConnectionDateNotAllowed = 20,
		LicenseNotFound = 1404,
		MobilePacketOperationRestriction = 1024,
		ExciseNotActivated = 1025,
		CashboxHasNotServiceCenter = 1026,
		SulpakServiceTemporarilyUnavailable = 2001,
		SulpakCardNumberNotFound = 2002,
		SulpakInvalidSmsCode = 2003,
		SulpakCardNumberAlreadyPay = 2004,
		SulpakNotEnoughMoney = 2005,
		SulpakNotification = 2006,
		SulpakTicketNotificationValidationError = 2007,
		AlfaBankAuthError = 3001,
		AlfaBankServiceIsTemporarilyUnavailable = 3002
	}
}

*)



type
  TNonNullable = class;
  TPaymentByType = class;
  TPaymentsByType = class;
  TOperationTypeSummary = class;
  TJournalReportRequest = class;
  TJournalReportItem = class;
  TUploadOrderRequest = class;
  TChangeTokenRequest = class;
  TSendReceiptCommandResponse = class;
  TSendReceiptCommandRequest = class;
  TCashboxParameters = class;
  TUnitItems = class;
  TErrorItem = class;
  TErrorItems = class;
  TTicketItems = class;
  TTicketItem = class;
  TTicketModifiers = class;
  TTicketModifier = class;
  TPayments = class;
  TPayment = class;
  TCashBoxes = class;
  TCashBox = class;

  { TErrorResult }

  TErrorResult = class(TJsonPersistent)
  private
    FErrors: TErrorItems;
    procedure SetErrors(const Value: TErrorItems);
  public
    constructor Create;
    destructor Destroy; override;
    function IsTokenExpired: Boolean;
    procedure Assign(Source: TPersistent); override;
  published
    property Errors: TErrorItems read FErrors write SetErrors;
  end;

  { TErrorItems }

  TErrorItems = class(TJsonCollection)
  published
    function GetItem(Index: Integer): TErrorItem;
  public
    property Items[Index: Integer]: TErrorItem read GetItem; default;
  end;

  { TErrorItem }

  TErrorItem = class(TJsonCollectionItem)
  private
    FCode: Integer;
    FText: WideString;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Code: Integer read FCode write FCode;
    property Text: WideString read FText write FText;
  end;

  { TWebkassaCommand }

  TWebkassaCommand = class(TJsonPersistent)
  public
    function Encode: WideString; virtual; abstract;
    function GetAddress: WideString; virtual; abstract;
    procedure Decode(const JsonText: WideString); virtual; abstract;
  end;

  { TAuthRequest }

  TAuthRequest = class(TJsonPersistent)
  private
    FLogin: WideString;
    FPassword: WideString;
  published
    property Login: WideString read FLogin write FLogin;
    property Password: WideString read FPassword write FPassword;
  end;

  { TAuthResponse }

  TAuthResponse = class(TJsonPersistent)
  private
    FToken: WideString;
  published
    property Token: WideString read FToken write FToken;
  end;

  { TAuthCommand }

  TAuthCommand = class(TWebkassaCommand)
  private
    FData: TAuthResponse;
    FRequest: TAuthRequest;
    procedure SetData(const Value: TAuthResponse);
  public
    constructor Create;
    destructor Destroy; override;

    function Encode: WideString; override;
    function GetAddress: WideString; override;
    procedure Decode(const JsonText: WideString); override;

    property Request: TAuthRequest read FRequest;
  published
    property Data: TAuthResponse read FData write SetData;
  end;

  { TChangeTokenCommand }

  TChangeTokenCommand = class(TJsonPersistent)
  private
    FData: Boolean;
    FRequest: TChangeTokenRequest;
  public
    constructor Create;
    destructor Destroy; override;
    property Request: TChangeTokenRequest read FRequest;
  published
    property Data: Boolean read FData write FData;
  end;

  { TChangeTokenRequest }

  TChangeTokenRequest = class(TJsonPersistent)
  private
    FToken: WideString;
    FCashboxUniqueNumber: WideString;
    FOfdToken: Integer;
  published
    property Token: WideString read FToken write FToken;
    property CashboxUniqueNumber: WideString read FCashboxUniqueNumber write FCashboxUniqueNumber;
    property OfdToken: Integer read FOfdToken write FOfdToken;
  end;

  { TSendReceiptCommand }

  TSendReceiptCommand = class(TJsonPersistent)
  private
    FData: TSendReceiptCommandResponse;
    FRequest: TSendReceiptCommandRequest;
    procedure SetData(const Value: TSendReceiptCommandResponse);
  public
    constructor Create;
    destructor Destroy; override;
    property Request: TSendReceiptCommandRequest read FRequest;
  published
    property Data: TSendReceiptCommandResponse read FData write SetData;
  end;

  { TSendReceiptCommandRequest }

  TSendReceiptCommandRequest = class(TJsonPersistent)
  private
    FToken: WideString;
    FCashboxUniqueNumber: WideString;
    FOperationType: Integer;
    FPositions: TTicketItems;
    FTicketModifiers: TTicketModifiers;
    FPayments: TPayments;
    FChange: Currency;
    FRoundType: Integer;
    FCustomerPhone: WideString;
    FCustomerXin: WideString;
    FExternalCheckNumber: WideString;
    FCustomerEmail: WideString;
    procedure SetPayments(const Value: TPayments);
    procedure SetPositions(const Value: TTicketItems);
    procedure SetTicketModifiers(const Value: TTicketModifiers);
  public
    constructor Create;
    destructor Destroy; override;
    function IsRequiredField(const Field: WideString): Boolean; override;
  published
    property Token: WideString read FToken write FToken;
    property CashboxUniqueNumber: WideString read FCashboxUniqueNumber write FCashboxUniqueNumber;
    property OperationType: Integer read FOperationType write FOperationType;
    property Positions: TTicketItems read FPositions write SetPositions;
    property TicketModifiers: TTicketModifiers read FTicketModifiers write SetTicketModifiers;
    property Payments: TPayments read FPayments write SetPayments;
    property Change: Currency read FChange write FChange;
    property RoundType: Integer read FRoundType write FRoundType;
    property ExternalCheckNumber: WideString read FExternalCheckNumber write FExternalCheckNumber;
    property CustomerEmail: WideString read FCustomerEmail write FCustomerEmail;
    property CustomerPhone: WideString read FCustomerPhone write FCustomerPhone;
    property CustomerXin: WideString read FCustomerXin write FCustomerXin;
  end;

  { TSendReceiptCommandResponse }

  TSendReceiptCommandResponse = class(TJsonPersistent)
  private
		FCheckNumber: WideString;
		FDateTime: WideString;
		FOfflineMode: Boolean;
		FCashboxOfflineMode: Boolean;
		FCashbox: TCashboxParameters;
		FCheckOrderNumber: Integer;
		FShiftNumber: Integer;
		FEmployeeName: WideString;
		FTicketUrl: WideString;
		FTicketPrintUrl: WideString;
    procedure SetCashbox(const Value: TCashboxParameters);
  public
    constructor Create;
    destructor Destroy; override;
  published
		property CheckNumber: WideString read FCheckNumber write FCheckNumber;
		property DateTime: WideString read FDateTime write FDateTime;
		property OfflineMode: Boolean read FOfflineMode write FOfflineMode;
		property CashboxOfflineMode: Boolean read FCashboxOfflineMode write FCashboxOfflineMode;
		property Cashbox: TCashboxParameters read FCashbox write SetCashbox;
		property CheckOrderNumber: Integer read FCheckOrderNumber write FCheckOrderNumber;
		property ShiftNumber: Integer read FShiftNumber write FShiftNumber;
		property EmployeeName: WideString read FEmployeeName write FEmployeeName;
		property TicketUrl: WideString read FTicketUrl write FTicketUrl;
		property TicketPrintUrl: WideString read FTicketPrintUrl write FTicketPrintUrl;
  end;

  { TPayment }

  TPayment = class(TJsonCollectionItem)
  private
    FSum: Currency;
    FPaymentType: Integer;
  published
    property Sum: Currency read FSum write FSum;
    property PaymentType: Integer read FPaymentType write FPaymentType;
  end;

  { TPayments }

  TPayments = class(TJsonCollection)
  private
    function GetItem(Index: Integer): TPayment;
  public
    constructor Create;
    property Items[Index: Integer]: TPayment read GetItem; default;
  end;

  { TTicketModifier }

  TTicketModifier = class(TJsonCollectionItem)
  private
    FSum:	Currency;
	  FText: WideString;
	  FType: Integer;
	  FTaxType: Integer;
	  FTax:	Currency;
  published
    property Sum: Currency read FSum write FSum;
	  property Text: WideString read FText write FText;
	  property _Type: Integer read FType write FType;
	  property TaxType: Integer read FTaxType write FTaxType;
	  property Tax:	Currency read FTax write FTax;
  end;

  { TTicketModifiers }

  TTicketModifiers = class(TJsonCollection)
  private
    function GetItem(Index: Integer): TTicketModifier;
  public
    constructor Create;
    property Items[Index: Integer]: TTicketModifier read GetItem; default;
  end;

  { TTicketItem }

  TTicketItem = class(TJsonCollectionItem)
  private
    FCount: Double;
    FPrice: Currency;
    FTaxPercent: Double;
    FTax: Currency;
    FTaxType: Integer;
    FPositionName: WideString;
    FPositionCode: WideString;
    FDiscount: Currency;
    FMarkup: Currency;
    FSectionCode: Integer;
    FIsStorno: Boolean;
    FMarkupDeleted: Boolean;
    FDiscountDeleted: Boolean;
    FUnitCode: Integer;
    FMark: WideString;
    FGTIN: WideString;
    FProductld: Integer;
    FWarehouseType: Integer;
  published
    property Count: Double read FCount write FCount;
    property Price: Currency read FPrice write FPrice;
    property TaxPercent: Double read FTaxPercent write FTaxPercent;
    property Tax: Currency read FTax write FTax;
    property TaxType: Integer read FTaxType write FTaxType;
    property PositionName: WideString read FPositionName write FPositionName;
    property PositionCode: WideString read FPositionCode write FPositionCode;
    property Discount: Currency read FDiscount write FDiscount;
    property Markup: Currency read FMarkup write FMarkup;
    property SectionCode: Integer read FSectionCode write FSectionCode;
    property IsStorno: Boolean read FIsStorno write FIsStorno;
    property MarkupDeleted: Boolean read FMarkupDeleted write FMarkupDeleted;
    property DiscountDeleted: Boolean read FDiscountDeleted write FDiscountDeleted;
    property UnitCode: Integer read FUnitCode write FUnitCode;
    property Mark: WideString read FMark write FMark;
    property GTIN: WideString read FGTIN write FGTIN;
    property Productld: Integer read FProductld write FProductld;
    property WarehouseType: Integer read FWarehouseType write FWarehouseType;
  end;

  { TTicketItems }

  TTicketItems = class(TJsonCollection)
  private
    function GetItem(Index: Integer): TTicketItem;
  public
    constructor Create;
    property Items[Index: Integer]: TTicketItem read GetItem; default;
  end;

  { TSendReceiptCommandResponse }

  { TOfdInformation }

  TOfdInformation = class(TJsonPersistent)
  private
    FCode: Integer;
    FHost: WideString;
    FName: WideString;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Name: WideString read FName write FName;
    property Host: WideString read FHost write FHost;
    property Code: Integer read FCode write FCode;
  end;

  { TCashboxParameters }

  TCashboxParameters = class(TJsonPersistent)
  private
    FUniqueNumber: WideString;
    FRegistrationNumber: WideString;
    FIdentityNumber: WideString;
    FAddress: WideString;
    FOfd: TOfdInformation;
    procedure SetOfd(const Value: TOfdInformation);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published
    property UniqueNumber: WideString read FUniqueNumber write FUniqueNumber;
    property RegistrationNumber: WideString read FRegistrationNumber write FRegistrationNumber;
    property IdentityNumber: WideString read FIdentityNumber write FIdentityNumber;
    property Address: WideString read FAddress write FAddress;
    property Ofd: TOfdInformation read FOfd write SetOfd;
  end;

  { TMoneyOperationRequest }

  TMoneyOperationRequest = class(TJsonPersistent)
  private
    FToken: WideString;
    FCashboxUniqueNumber: WideString;
    FOperationType: Integer;
    FSum: Currency;
    FExternalCheckNumber: WideString;
  published
    property Token: WideString read FToken write FToken;
    property CashboxUniqueNumber: WideString read FCashboxUniqueNumber write FCashboxUniqueNumber;
    property OperationType: Integer read FOperationType write FOperationType;
    property Sum: Currency read FSum write FSum;
    property ExternalCheckNumber: WideString read FExternalCheckNumber write FExternalCheckNumber;
  end;

  { TMoneyOperationResponse }

  TMoneyOperationResponse = class(TJsonPersistent)
  private
    FOfflineMode: Boolean;
    FCashboxOfflineMode: Boolean;
    FDateTime: WideString;
    FSum: Currency;
    FCashbox: TCashboxParameters;
  public
    constructor Create;
    destructor Destroy; override;
  published
    property OfflineMode: Boolean read FOfflineMode write FOfflineMode;
    property CashboxOfflineMode: Boolean read FCashboxOfflineMode write FCashboxOfflineMode;
    property DateTime: WideString read FDateTime write FDateTime;
    property Sum: Currency read FSum write FSum;
    property Cashbox: TCashboxParameters read FCashbox write FCashbox;
  end;

  { TMoneyOperationCommand }

  TMoneyOperationCommand = class(TWebkassaCommand)
  private
    FData: TMoneyOperationResponse;
    FRequest: TMoneyOperationRequest;
    procedure setData(const Value: TMoneyOperationResponse);
  public
    constructor Create;
    destructor Destroy; override;

    function Encode: WideString; override;
    function GetAddress: WideString; override;
    procedure Decode(const JsonText: WideString); override;

    property Request: TMoneyOperationRequest read FRequest;
  published
    property Data: TMoneyOperationResponse read FData write setData;
  end;

  { TCashboxRequest }

  TCashboxRequest = class(TJsonPersistent)
  private
    FToken: WideString;
    FCashboxUniqueNumber: WideString;
  published
    property Token: WideString read FToken write FToken;
    property CashboxUniqueNumber: WideString read FCashboxUniqueNumber write FCashboxUniqueNumber;
  end;

  { TZXReportResponse }

  TZXReportResponse = class(TJsonPersistent)
  private
    FReportNumber: Int64;
    FTaxPayerName: WideString;
    FTaxpayerIN: WideString;
    FTaxPayerVAT: Boolean;
    FTaxPayerVATSeria: WideString;
    FTaxPayerVATNumber: WideString;
    FCashboxSN: WideString;
    FCashboxIN: Int64;
    FCashboxRN: WideString;
    FStartOn: WideString;
    FReportOn: WideString;
    FCloseOn: WideString;
    FCashierCode: Int64;
    FShiftNumber: Int64;
    FDocumentCount: Int64;
    FPutMoneySum: Currency;
    FTakeMoneySum: Currency;
    FControlSum: Currency;
    FOfflineMode: Boolean;
    FCashboxOfflineMode: Boolean;
    FSumInCashbox: Currency;
    FSell: TOperationTypeSummary;
    FBuy: TOperationTypeSummary;
    FReturnSell: TOperationTypeSummary;
    FReturnBuy: TOperationTypeSummary;
    FStartNonNullable: TNonNullable;
    FEndNonNullable: TNonNullable;
    FOfd: TOfdInformation;

    procedure SetBuy(const Value: TOperationTypeSummary);
    procedure SetEndNonNullable(const Value: TNonNullable);
    procedure SetOfd(const Value: TOfdInformation);
    procedure SetReturnBuy(const Value: TOperationTypeSummary);
    procedure SetReturnSell(const Value: TOperationTypeSummary);
    procedure SetSell(const Value: TOperationTypeSummary);
    procedure SetStartNonNullable(const Value: TNonNullable);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property ReportNumber: Int64 read FReportNumber write FReportNumber;
    property TaxPayerName: WideString read FTaxPayerName write FTaxPayerName;
    property TaxpayerIN: WideString read FTaxpayerIN write FTaxpayerIN;
    property TaxPayerVAT: Boolean read FTaxPayerVAT write FTaxPayerVAT;
    property TaxPayerVATSeria: WideString read FTaxPayerVATSeria write FTaxPayerVATSeria;
    property TaxPayerVATNumber: WideString read FTaxPayerVATNumber write FTaxPayerVATNumber;
    property CashboxSN: WideString read FCashboxSN write FCashboxSN;
    property CashboxIN: Int64 read FCashboxIN write FCashboxIN;
    property CashboxRN: WideString read  FCashboxRN write FCashboxRN;
    property StartOn: WideString read FStartOn write FStartOn;
    property ReportOn: WideString read FReportOn write FReportOn;
    property CloseOn: WideString read FCloseOn write FCloseOn;
    property CashierCode: Int64 read FCashierCode write FCashierCode;
    property ShiftNumber: Int64 read FShiftNumber write FShiftNumber;
    property DocumentCount: Int64 read FDocumentCount write FDocumentCount;
    property PutMoneySum: Currency read FPutMoneySum write FPutMoneySum;
    property TakeMoneySum: Currency read FTakeMoneySum write FTakeMoneySum;
    property ControlSum: Currency read FControlSum write FControlSum;
    property OfflineMode: Boolean read FOfflineMode write FOfflineMode;
    property CashboxOfflineMode: Boolean read FCashboxOfflineMode write FCashboxOfflineMode;
    property SumInCashbox: Currency read FSumInCashbox write FSumInCashbox;
    property Sell: TOperationTypeSummary read FSell write SetSell;
    property Buy: TOperationTypeSummary read FBuy write SetBuy;
    property ReturnSell: TOperationTypeSummary read FReturnSell write SetReturnSell;
    property ReturnBuy: TOperationTypeSummary read FReturnBuy write SetReturnBuy;
    property StartNonNullable: TNonNullable read FStartNonNullable write SetStartNonNullable;
    property EndNonNullable: TNonNullable read FEndNonNullable write SetEndNonNullable;
    property Ofd: TOfdInformation read FOfd write SetOfd;
  end;

  { TReportSection }

  TReportSection = class(TJsonCollectionItem)
  private
    FCode: Integer;
    FName: WideString;
  published
    property Code: Integer read FCode write FCode;
    property Name: WideString read FName write FName;
  end;

  { TOperationTypeSummary }

  TOperationTypeSummary = class(TJsonPersistent)
  private
    FPayments: TPaymentsByType;
    FDiscount: Currency;
    FMarkup: Currency;
    FTaken: Currency;
    FChange: Currency;
    FCount: Int64;
    FVAT: Currency;
    procedure SetPayments(const Value: TPaymentsByType);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property PaymentsByTypesApiModel: TPaymentsByType read FPayments write SetPayments;
    property Discount: Currency read FDiscount write FDiscount;
    property Markup: Currency read FMarkup write FMarkup;
    property Taken: Currency read FTaken write FTaken;
    property Change: Currency read FChange write FChange;
    property Count: Int64 read FCount write FCount;
    property VAT: Currency read FVAT write FVAT;
  end;

  { TPaymentsByType }

  TPaymentsByType = class(TJsonCollection)
  private
    function GetItem(Index: Integer): TPaymentByType;
    procedure SetItem(Index: Integer; const Value: TPaymentByType);
  public
    property Items[Index: Integer]: TPaymentByType read GetItem write SetItem; default;
  end;

  { TPaymentByType }

  TPaymentByType = class(TJsonCollectionItem)
  private
    FSum: Currency;
    FType: Integer;
  published
    property Sum: Currency read FSum write FSum;
    property _Type: Integer read FType write FType;
  end;

  { TNonNullable }

  TNonNullable = class(TJsonPersistent)
  private
    FSell: Currency;
    FBuy: Currency;
    FReturnSell: Currency;
    FReturnBuy: Currency;
  published
    property Sell: Currency read FSell write FSell;
    property Buy: Currency read FBuy write FBuy;
    property ReturnSell: Currency read FReturnSell write FReturnSell;
    property ReturnBuy: Currency read FReturnBuy write FReturnBuy;
  end;

  { TZXReportCommand }

  TZXReportCommand = class(TJsonPersistent)
  private
    FData: TZXReportResponse;
    FRequest: TCashboxRequest;
    procedure setData(const Value: TZXReportResponse);
  public
    constructor Create;
    destructor Destroy; override;
    property Request: TCashboxRequest read FRequest;
  published
    property Data: TZXReportResponse read FData write setData;
  end;

  { TJournalReportCommand }

  TJournalReportCommand = class(TJsonPersistent)
  private
    FData: TJsonCollection;
    FRequest: TJournalReportRequest;
    procedure setData(const Value: TJsonCollection);
  public
    constructor Create;
    destructor Destroy; override;
    property Request: TJournalReportRequest read FRequest;
  published
    property Data: TJsonCollection read FData write setData;
  end;

  { TJournalReportRequest }

  TJournalReportRequest = class(TJsonPersistent)
  private
    FToken: WideString;
    FCashboxUniqueNumber: WideString;
    FShiftNumber: Integer;
  published
    property Token: WideString read FToken write FToken;
    property CashboxUniqueNumber: WideString read FCashboxUniqueNumber write FCashboxUniqueNumber;
    property ShiftNumber: Integer read FShiftNumber write FShiftNumber;
  end;

  { TJournalReportItem }

  TJournalReportItem = class(TJsonCollectionItem)
  private
    FOperationTypeText: WideString;
    FSum: Currency;
    FDate: WideString;
    FEmployeeCode: Int64;
    FNumber: WideString;
    FIsOffline: Boolean;
    FExternalOperationld: WideString;
  published
    property OperationTypeText: WideString read FOperationTypeText write FOperationTypeText;
    property Sum: Currency read FSum write FSum;
    property Date: WideString read FDate write FDate;
    property EmployeeCode: Int64 read FEmployeeCode write FEmployeeCode;
    property Number: WideString read FNumber write FNumber;
    property IsOffline: Boolean read FIsOffline write FIsOffline;
    property ExternalOperationld: WideString read FExternalOperationld write FExternalOperationld;
  end;

  { TTokenRequest }

  TTokenRequest = class(TJsonPersistent)
  private
    FToken: WideString;
  published
    property Token: WideString read FToken write FToken;
  end;

  { TCashboxesResponse }

  TCashboxesResponse = class(TJsonPersistent)
  private
    FList: TCashBoxes;
    procedure SetList(const Value: TCashBoxes);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property List: TCashBoxes read FList write SetList;
  end;

  { TCashbox }

  TCashbox = class(TJsonCollectionItem)
  private
    FUniqueNumber: WideString;
    FRegistrationNumber: WideString;
    FIdentificationNumber: WideString;
    FName: WideString;
    FDescription: WideString;
    FIsOffline: Boolean;
    FCurrentStatus: Integer;
    FShift: Integer;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property UniqueNumber: WideString read FUniqueNumber write FUniqueNumber;
    property RegistrationNumber: WideString read FRegistrationNumber write FRegistrationNumber;
    property IdentificationNumber: WideString read FIdentificationNumber write FIdentificationNumber;
    property Name: WideString read FName write FName;
    property Description: WideString read FDescription write FDescription;
    property IsOffline: Boolean read FIsOffline write FIsOffline;
    property CurrentStatus: Integer read FCurrentStatus write FCurrentStatus;
    property Shift: Integer read FShift write FShift;
  end;

  { TCashBoxes }

  TCashBoxes = class(TJsonCollection)
  published
    function GetItem(Index: Integer): TCashBox;
    function ItemByUniqueNumber(const Value: WideString): TCashBox;
  public
    property Items[Index: Integer]: TCashBox read GetItem; default;
  end;

  { TCashboxesCommand }

  TCashboxesCommand = class(TJsonPersistent)
  private
    FData: TCashboxesResponse;
    FRequest: TTokenRequest;
    procedure setData(const Value: TCashboxesResponse);
  public
    constructor Create;
    destructor Destroy; override;
    property Request: TTokenRequest read FRequest;
  published
    property Data: TCashboxesResponse read FData write setData;
  end;

  { TShiftRequest }

  TShiftRequest = class(TJsonPersistent)
  private
    FCashboxUniqueNumber: WideString;
    FToken: WideString;
    FSkip: Integer;
    FTake: Integer;
  published
    property CashboxUniqueNumber: WideString read FCashboxUniqueNumber write FCashboxUniqueNumber;
    property Token: WideString read FToken write FToken;
    property Skip: Integer read FSkip write FSkip;
    property Take: Integer read FTake write FTake;
  end;

  { TShiftResponse }

  TShiftResponse = class(TJsonPersistent)
  private
    FCashboxUniqueNumber: WideString;
    FSkip: Integer;
    FTake: Integer;
    FTotal: Integer;
    FShifts: TJsonCollection;
    procedure SetShifts(const Value: TJsonCollection);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property CashboxUniqueNumber: WideString read FCashboxUniqueNumber write FCashboxUniqueNumber;
    property Skip: Integer read FSkip write FSkip;
    property Take: Integer read FTake write FTake;
    property Total: Integer read FTotal write FTotal;
    property Shifts: TJsonCollection read FShifts write SetShifts;
  end;

  { TShiftItem }

  TShiftItem = class(TJsonCollectionItem)
  private
    FShiftNumber: Integer;
    FOpenDate: WideString;
    FCloseDate: WideString;
  published
    property ShiftNumber: Integer read FShiftNumber write FShiftNumber;
    property OpenDate: WideString read FOpenDate write FOpenDate;
    property CloseDate: WideString read FCloseDate write FCloseDate;
  end;

  { TShiftCommand }

  TShiftCommand = class(TJsonPersistent)
  private
    FData: TShiftResponse;
    FRequest: TShiftRequest;
    procedure setData(const Value: TShiftResponse);
  public
    constructor Create;
    destructor Destroy; override;
    property Request: TShiftRequest read FRequest;
  published
    property Data: TShiftResponse read FData write setData;
  end;

  { TCashier }

  TCashier = class(TJsonCollectionItem)
  private
    FFullName: WideString;
    FEmail: WideString;
    FCashboxes: TStrings;
    procedure SetCashboxes(const Value: TStrings);
  public
    constructor Create(Collection: TJsonCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published
    property FullName: WideString read FFullName write FFullName;
    property Email: WideString read FEmail write FEmail;
    property Cashboxes: TStrings read FCashboxes write SetCashboxes;
  end;

  { TCashiers }

  TCashiers = class(TJsonCollection)
  private
    function GetItem(Index: Integer): TCashier;
  public
    constructor Create;
    function ItemByEMail(const email: WideString): TCashier;
    property Items[Index: Integer]: TCashier read GetItem; default;
  end;

  { TCashierCommand }

  TCashierCommand = class(TJsonPersistent)
  private
    FData: TCashiers;
    FRequest: TTokenRequest;
    procedure setData(const Value: TCashiers);
  public
    constructor Create;
    destructor Destroy; override;
    property Request: TTokenRequest read FRequest;
  published
    property Data: TCashiers read FData write setData;
  end;

  { TReceiptRequest }

  TReceiptRequest = class(TJsonPersistent)
  private
    FCashboxUniqueNumber: WideString;
    FToken: WideString;
    FNumber: WideString;
    FShiftNumber: Integer;
  published
    property CashboxUniqueNumber: WideString read FCashboxUniqueNumber write FCashboxUniqueNumber;
    property Token: WideString read FToken write FToken;
    property Number: WideString read FNumber write FNumber;
    property ShiftNumber: Integer read FShiftNumber write FShiftNumber;
  end;

  { TPaymentItem }

  TPaymentItem = class(TJsonCollectionItem)
  private
    FSum: Currency;
    FPaymentTypeName: WideString;
  published
    property Sum: Currency read FSum write FSum;
    property PaymentTypeName: WideString read FPaymentTypeName write FPaymentTypeName;
  end;

  { TPaymentItems }

  TPaymentItems = class(TJsonCollection)
  private
    function GetItem(Index: Integer): TPaymentItem;
  public
    constructor Create;
    property Items[Index: Integer]: TPaymentItem read GetItem; default;
  end;

  { TPositionItem }

  TPositionItem = class(TJsonCollectionItem)
  private
    FPositionName: WideString;
    FPositionCode: WideString;
    FCount: Double;
    FPrice: Currency;
    FDiscountPercent: Double;
    FDiscountTenge: Double;
    FMarkupPercent: Double;
    FMarkup: Double;
    FTaxPercent: Double;
    FTax: Double;
    FIsNds: Boolean;
    FIsStorno: Boolean;
    FMarkupDeleted: Boolean;
    FDiscountDeleted: Boolean;
    FSum: Currency;
    FUnitCode: Integer;
    FMark: WideString;
  published
    property PositionName: WideString read FPositionName write FPositionName;
    property PositionCode: WideString read FPositionCode write FPositionCode;
    property Count: Double read FCount write FCount;
    property Price: Currency read FPrice write FPrice;
    property DiscountPercent: Double read FDiscountPercent write FDiscountPercent;
    property DiscountTenge: Double read FDiscountTenge write FDiscountTenge;
    property MarkupPercent: Double read FMarkupPercent write FMarkupPercent;
    property Markup: Double read FMarkup write FMarkup;
    property TaxPercent: Double read FTaxPercent write FTaxPercent;
    property Tax: Double read FTax write FTax;
    property IsNds: Boolean read FIsNds write FIsNds;
    property IsStorno: Boolean read FIsStorno write FIsStorno;
    property MarkupDeleted: Boolean read FMarkupDeleted write FMarkupDeleted;
    property DiscountDeleted: Boolean read FDiscountDeleted write FDiscountDeleted;
    property Sum: Currency read FSum write FSum;
    property UnitCode: Integer read FUnitCode write FUnitCode;
    property Mark: WideString read FMark write FMark;
  end;

  { TPositionItems }

  TPositionItems = class(TJsonCollection)
  private
    function GetItem(Index: Integer): TPositionItem;
  public
    constructor Create;
    property Items[Index: Integer]: TPositionItem read GetItem; default;
  end;

  { TReceiptResponse }


  TReceiptResponse = class(TJsonPersistent)
  private
    FCashboxUniqueNumber: WideString;
    FCashboxRegistrationNumber: WideString;
    FCashboxIdentityNumber: WideString;
    FAddress: WideString;
    FNumber: WideString;
    FOrderNumber: Int64;
    FRegistratedOn: WideString;
    FEmployeeName: WideString;
    FEmployeeCode: Int64;
    FShiftNumber: Int64;
    FDocumentNumber: Int64;
    FOperationType: Integer;
    FOperationTypeText: WideString;
    FPayments: TPaymentItems;
    FTotal: Currency;
    FChange: Currency;
    FTaken: Currency;
    FDiscount: Currency;
    FMarkupPercent: Double;
    FMarkup: Currency;
    FTaxPercent: Double;
    FTax: Currency;
    FVATPayer: Boolean;
    FPositions: TPositionItems;
    FIsOffline: Boolean;
    FTicketUrl: WideString;
    FOfd: TOfdInformation;
    FTicketPrintUrl: WideString;
    FExternalCheckNumber: WideString;

    procedure SetPayments(const Value: TPaymentItems);
    procedure SetPositions(const Value: TPositionItems);
    procedure SetOfd(const Value: TOfdInformation);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property CashboxUniqueNumber: WideString read FCashboxUniqueNumber write FCashboxUniqueNumber;
    property CashboxRegistrationNumber: WideString read FCashboxRegistrationNumber write FCashboxRegistrationNumber;
    property CashboxIdentityNumber: WideString read FCashboxIdentityNumber write FCashboxIdentityNumber;
    property Address: WideString read FAddress write FAddress;
    property Number: WideString read FNumber write FNumber;
    property OrderNumber: Int64 read FOrderNumber write FOrderNumber;
    property RegistratedOn: WideString read FRegistratedOn write FRegistratedOn;
    property EmployeeName: WideString read FEmployeeName write FEmployeeName;
    property EmployeeCode: Int64 read FEmployeeCode write FEmployeeCode;
    property ShiftNumber: Int64 read FShiftNumber write FShiftNumber;
    property DocumentNumber: Int64 read FDocumentNumber write FDocumentNumber;
    property OperationType: Integer read FOperationType write FOperationType;
    property OperationTypeText: WideString read FOperationTypeText write FOperationTypeText;
    property Payments:	TPaymentItems read FPayments write SetPayments;
    property Total: Currency read FTotal write FTotal;
    property Change: Currency read FChange write FChange;
    property Taken: Currency read FTaken write FTaken;
    property Discount: Currency read FDiscount write FDiscount;
    property MarkupPercent: Double read FMarkupPercent write FMarkupPercent;
    property Markup: Currency read FMarkup write FMarkup;
    property TaxPercent: Double read FTaxPercent write FTaxPercent;
    property Tax: Currency read FTax write FTax;
    property VATPayer: Boolean read FVATPayer write FVATPayer;
    property Positions: TPositionItems read FPositions write SetPositions;
    property IsOffline: Boolean read FIsOffline write FIsOffline;
    property TicketUrl: WideString read FTicketUrl write FTicketUrl;
    property TicketPrintUrl: WideString read FTicketPrintUrl write FTicketPrintUrl;
    property Ofd: TOfdInformation read FOfd write SetOfd;
    property ExternalCheckNumber: WideString read FExternalCheckNumber write FExternalCheckNumber;
  end;

  { TReceiptCommand }

  TReceiptCommand = class(TJsonPersistent)
  private
    FData: TReceiptResponse;
    FRequest: TReceiptRequest;
    procedure setData(const Value: TReceiptResponse);
  public
    constructor Create;
    destructor Destroy; override;
    property Request: TReceiptRequest read FRequest;
  published
    property Data: TReceiptResponse read FData write setData;
  end;

  { TReceiptTextRequest }

  TReceiptTextRequest = class(TJsonPersistent)
  private
    FCashboxUniqueNumber: WideString;
    FExternalCheckNumber: WideString;
    FisDuplicate: Boolean;
    FpaperKind: Integer;
    FToken: WideString;
  published
    property CashboxUniqueNumber: WideString read FCashboxUniqueNumber write FCashboxUniqueNumber;
    property externalCheckNumber: WideString read FexternalCheckNumber write FexternalCheckNumber;
    property isDuplicate: Boolean read FisDuplicate write FisDuplicate;
    property paperKind: Integer read FpaperKind write FpaperKind;
    property Token: WideString read FToken write FToken;
  end;

  { TReceiptTextAnswer }

  TReceiptTextAnswer = class(TJsonPersistent)
  private
    FLines: TJsonCollection;
    procedure SetLines(const Value: TJsonCollection);
  public
    constructor Create;
    destructor Destroy; override;
    function GetText: WideString;
  published
    property Lines: TJsonCollection read FLines  write SetLines;
  end;

  { TReceiptTextItem }

  TReceiptTextItem = class(TJsonCollectionItem)
  private
    FOrder: Integer;
    FType: Integer;
    FValue: WideString;
    FStyle: Integer;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Order: Integer read FOrder write FOrder;
    property _Type: Integer read FType write FType;
    property Value: WideString read FValue write FValue;
    property Style: Integer read FStyle write FStyle;
  end;

  { TReceiptTextCommand }

  TReceiptTextCommand = class(TJsonPersistent)
  private
    FData: TReceiptTextAnswer;
    FRequest: TReceiptTextRequest;
    procedure setData(const Value: TReceiptTextAnswer);
  public
    constructor Create;
    destructor Destroy; override;
    property Request: TReceiptTextRequest read FRequest;
  published
    property Data: TReceiptTextAnswer read FData write setData;
  end;

  { TReadUnitsCommand }

  TReadUnitsCommand = class(TJsonPersistent)
  private
    FData: TUnitItems;
    FRequest: TTokenRequest;
    procedure setData(const Value: TUnitItems);
  public
    constructor Create;
    destructor Destroy; override;
    property Request: TTokenRequest read FRequest;
  published
    property Data: TUnitItems read FData write setData;
  end;

  { TUnitItem }

  TUnitItem  = class(TJsonCollectionItem)
  private
    FCode: Integer;
    FNameRu: WideString; // ������������ �� �������
    FNameKz: WideString; // ������������ �� ���������
    FNameEn: WideString; // ������������ �� ����������
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Code: Integer read FCode write FCode;
    property NameRu: WideString read FNameRu write FNameRu;
    property NameKz: WideString read FNameKz write FNameKz;
    property NameEn: WideString read FNameEn write FNameEn;
  end;

  { TUnitItems }

  TUnitItems = class(TJsonCollection)
  private
    function GetItem(Index: Integer): TUnitItem;
  public
    function ItemByCode(Code: Integer): TUnitItem;
    property Items[Index: Integer]: TUnitItem read GetItem; default;
  end;


  { TUploadOrderCommand }

  TUploadOrderCommand = class(TJsonPersistent)
  private
    FData: Boolean;
    FRequest: TUploadOrderRequest;
  public
    constructor Create;
    destructor Destroy; override;
    property Request: TUploadOrderRequest read FRequest;
  published
    property Data: Boolean read FData write FData;
  end;

  { TUploadOrderRequest }

  TUploadOrderRequest = class(TJsonPersistent)
  private
    FToken: WideString;
    FOrderNumber: WideString;
    FPositions: TJsonCollection;
	  FCustomerEmail: WideString;
	  FCustomerPhone: WideString;
    procedure SetPositions(const Value: TJsonCollection);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property Token: WideString read FToken write FToken;
    property OrderNumber: WideString read FOrderNumber write FOrderNumber;
    property Positions: TJsonCollection read FPositions write SetPositions;
	  property CustomerEmail: WideString read FCustomerEmail write FCustomerEmail;
	  property CustomerPhone: WideString read FCustomerPhone write FCustomerPhone;
  end;

  { TOrderItem }

  TOrderItem = class(TJsonCollectionItem)
  private
    FCount: Integer;
    FPrice: Currency;
    FTaxPercent: Double;
    FTaxType: Integer;
    FPositionName: WideString;
    FPositionCode: WideString;
    FDiscount: Currency;
    FMarkup: Currency;
    FSectionCode: WideString;
    FUnitCode: Integer;
  published
    property Count: Integer read FCount write FCount;
    property Price: Currency read FPrice write FPrice;
    property TaxPercent: Double read FTaxPercent write FTaxPercent;
    property TaxType: Integer read FTaxType write FTaxType;
    property PositionName: WideString read FPositionName write FPositionName;
    property PositionCode: WideString read FPositionCode write FPositionCode;
    property Discount: Currency read FDiscount write FDiscount;
    property Markup: Currency read FMarkup write FMarkup;
    property SectionCode: WideString read FSectionCode write FSectionCode;
    property UnitCode: Integer read FUnitCode write FUnitCode;
  end;

  { TWebkassaClient }

  TWebkassaClient = class
  private
    FLogger: ILogFile;
    FTransport: TIdHTTP;
    FDomainNames: TStrings;

    FLogin: WideString;
    FPassword: WideString;
    FAddress: WideString;
    FConnectTimeout: Integer;
    FCashboxNumber: WideString;

    FCommandJson: WideString;
    FAnswerJson: WideString;
    FToken: WideString;
    FTestMode: Boolean;
    FRaiseErrors: Boolean;
    FErrorResult: TErrorResult;
    FTestErrorResult: TErrorResult;
    FRegKeyName: WideString;

    function GetTransport: TIdHTTP;
    function CheckLastError: Boolean;

    property Transport: TIdHTTP read GetTransport;
    function PostJson(const AURL, Request: WideString): WideString;
  protected
    procedure HTTPHeadersAvailable(Sender: TObject;
      AHeaders: TIdHeaderList; var VContinue: Boolean);
  public
    constructor Create(ALogger: ILogFile);
    destructor Destroy; override;

    procedure Connect;
    procedure Disconnect;
    procedure SaveParams;
    procedure LoadParams;
    procedure RaiseLastError;
    function GetAddress: WideString;
    function Post(URL, Request: WideString): WideString;
    function Authenticate(Command: TAuthCommand): Boolean;
    function ChangeToken(Command: TChangeTokenCommand): Boolean;
    function SendReceipt(Command: TSendReceiptCommand): Boolean;
    function MoneyOperation(Command: TMoneyOperationCommand): Boolean;
    function ZReport(Command: TZXReportCommand): Boolean;
    function XReport(Command: TZXReportCommand): Boolean;
    function JournalReport(Command: TJournalReportCommand): Boolean;
    function ReadCashiers(Command: TCashierCommand): Boolean;
    function ReadReceipt(Command: TReceiptCommand): Boolean;
    function ReadReceiptText(Command: TReceiptTextCommand): Boolean;
    function ReadUnits(Command: TReadUnitsCommand): Boolean;
    function UploadOrder(Command: TUploadOrderCommand): Boolean;
    function ReadCashboxes(Command: TCashboxesCommand): Boolean;
    function ReadCashboxStatus(Request: TCashboxRequest): Boolean;
    function ReadShiftHistory(Command: TShiftCommand): Boolean;
    function Execute(Command: TWebkassaCommand): Boolean;

    property RegKeyName: WideString read FRegKeyName write FRegKeyName;
    property Login: WideString read FLogin write FLogin;
    property Password: WideString read FPassword write FPassword;
    property ConnectTimeout: Integer read FConnectTimeout write FConnectTimeout;
    property Token: WideString read FToken write FToken;
    property ErrorResult: TErrorResult read FErrorResult;
    property TestMode: Boolean read FTestMode write FTestMode;
    property Address: WideString read FAddress write FAddress;
    property RaiseErrors: Boolean read FRaiseErrors write FRaiseErrors;
    property AnswerJson: WideString read FAnswerJson write FAnswerJson;
    property CommandJson: WideString read FCommandJson write FCommandJson;
    property CashboxNumber: WideString read FCashboxNumber write FCashboxNumber;
    property TestErrorResult: TErrorResult read FTestErrorResult write FTestErrorResult;
  end;

function GetPaymentName(PaymentType: Integer): WideString;

implementation

function GetPaymentName(PaymentType: Integer): WideString;
begin
  case PaymentType of
    PaymentTypeCash: Result := '��������';
    PaymentTypeCard: Result := '���������� �����';
    PaymentTypeCredit: Result := '������';
    PaymentTypeTare: Result := '������ �����';
  else
    Result := '';
  end;
end;

function GetErrorText(Code: Integer): WideString;
begin
   case Code of
     -1: Result := '����������� ������';
      1: Result := '�������� ����� ��� ������';
      2: Result := '���� �������� ������ �����';
      3: Result := '������������ �� �����������';
      4: Result := '��� ������� � ��������';
      5: Result := '��� ������� � �����';
      6: Result := '����� �� �������';
      7: Result := '����� �������������';
      8: Result := '������������ ����� ��� �������';
      9: Result := '������ ��������� ������';
      10: Result := '����� �� ������������';
      11: Result := '����������������� ����� ��������� 24 ����';
      12: Result := '����� ��� �������';
      13: Result := '�� ������� �������� �����';
      14: Result := '������������� ��� �������-���������';
      15: Result := '����� �� �������';
      16: Result := '��� �� ��������������� � ������ �����';
      18: Result := '��������������c�� ������ � ���������� ������ ��������� 72 ����';
	    19: Result := '�� ������ ��� � ����� �������';
	    1000: Result := '����������� ��� ����������������';
	    1001: Result := '��������� ��� ���������������';
	    1002: Result := '����� � ����� ID ��� ����������������';
	    1003: Result := '����� ��������� ��� ���� ������������';
	    1004: Result := '�������� ������ ����� ���������';
	    1005: Result := '�������� ������ ������';
	    1006: Result := '������������� ������';
	    1007: Result := '����� �� ������ ���� �������';
	    1008: Result := '����� �� ������ ���� ������ ����';
	    1009: Result := '��������� �� ������';
	    1010: Result := '����� �� �������';
	    1011: Result := '�������� �������� ���';
   else
     Result := '����������� ������';
   end;
   Result := Format('%d, %s', [Code, Result]);
end;

(*
public enum ApiErrorCode
{
	UnknownError = -1,
	WrongCredentials = 1,
	TokenExpired = 2,
	NotAuthorized = 3,
	OperationAccessDenied = 4,
	CashAccessDenied = 5,
	CashboxNotFound = 6,
	CashBlocked = 7,
	NotEnoughMoney = 8,
	ValidationError = 9,
	CashboxNotActivated = 10,
	ShiftOpenedMoreThan24Hours = 11,
	ShiftAlreadyClosed = 12,
	ShiftNotFound = 13,
	DuplicateExternalCode = 14,
	ShiftDoesNotExist = 15,
	CheckNotFound = 16,
	DiscountMarkUpCanNotBeSpecified = 17,
	OfflineModeMoreThan72Hours = 18,
	CheckWithThisExternalNumberNotFound = 19,
	OrganizationAlreadyRegistered = 1000,
	EmployeeAlreadyRegistered = 1001,
	CashboxWithThisIDIsAlreadyRegistered = 1002,
	ActivationCardAlreadyWasUsed = 1003,
	WrongActivationCardData = 1004,
	WrongOldPassword = 1005,
	DuplicatePassword = 1006,
	SumIsNotToBeFraction = 1007,
	SumCanNotBeLessZero = 1008,
	EmployeeNotFound = 1009,
	CashboxNotFoundToAccess = 1010,
	PeriodDatesIncorrect = 1011,
	IdSalemNotFound = 1011,
	IncorrectTransactionStatus = 1012,
	OfflineChecksNotSupported = 1013,
	ZReportNotFound = 1014,
	ExternalPartnerNotFound = 1015,
	InvalidValidationCode = 1016,
	CashboxYetUsedExternalSystem = 1017,
	CashboxNotUsedExternalSystem = 1018,
	CantCancelTicket = 1019,
	WrongCashboxRegistrationInformation = 1020,
	CanNotCreatePacketForNonExistentXin = 1021,
	CanNotProlongatePacketForNonExistentXin = 1022,
	ActivationCardNeverUsed = 1023,
	OrganizationIsNotServiceCenter = 1030,
	Cashbox1CActivationNotAllowed = 1031,
	CanNotActivateCashbox = 1032,
	HasNoServiceCenterRights = 1033,
	OrganizationNotFound = 1034,
	DataEarlierCashboxConnectionDateNotAllowed = 20,
	LicenseNotFound = 1404,
	MobilePacketOperationRestriction = 1024,
	ExciseNotActivated = 1025,
	CashboxHasNotServiceCenter = 1026,
	SulpakServiceTemporarilyUnavailable = 2001,
	SulpakCardNumberNotFound = 2002,
	SulpakInvalidSmsCode = 2003,
	SulpakCardNumberAlreadyPay = 2004,
	SulpakNotEnoughMoney = 2005,
	SulpakNotification = 2006,
	SulpakTicketNotificationValidationError = 2007,
	AlfaBankAuthError = 3001,
	AlfaBankServiceIsTemporarilyUnavailable = 3002
}

*)

{ TWebkassaClient }

constructor TWebkassaClient.Create(ALogger: ILogFile);
begin
  inherited Create;
  FLogger := ALogger;
  FAddress := 'https://devkkm.webkassa.kz/';
  FErrorResult := TErrorResult.Create;
  FDomainNames := TStringList.Create;
  FRegKeyName := 'SHTRIH-M\WebKassa';
end;

destructor TWebkassaClient.Destroy;
begin
  FTransport.Free;
  FErrorResult.Free;
  FDomainNames.Free;
  inherited Destroy;
end;

procedure TWebkassaClient.SaveParams;
var
  Reg: TTntRegistry;
begin
  Reg := TTntRegistry.Create;
  try
    Reg.Access := KEY_ALL_ACCESS;
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey(RegKeyName, True) then
    begin
      Reg.WriteString('Token', Token);
    end else
    begin
      FLogger.Error('Registry key open error');
    end;
  except
    on E: Exception do
    begin
      FLogger.Error('Save params failed, ' + E.Message);
    end;
  end;
  Reg.Free;
end;

procedure TWebkassaClient.LoadParams;
var
  Reg: TTntRegistry;
begin
  Reg := TTntRegistry.Create;
  try
    Reg.Access := KEY_READ;
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey(RegKeyName, True) then
    begin
      Token := Reg.ReadString('Token');
    end;
  except
    on E: Exception do
    begin
      FLogger.Error('Read params failed, ' + E.Message);
    end;
  end;
  Reg.Free;
end;

(*
Error connecting with SSL.
error:14077438:SSL routines:SSL23_GET_SERVER_HELLO:tlsv1 alert internal error
Error connecting with SSL.
error:1409442E:SSL routines:SSL3_READ_BYTES:tlsv1 alert protocol version
Error connecting with SSL.
error:14094410:SSL routines:SSL3_READ_BYTES:sslv3 alert handshake failure
Error connecting with SSL.
error:00000006:lib(0):func(0):EVP lib

TIdSSLVersion = (sslvSSLv2, sslvSSLv23, sslvSSLv3, sslvTLSv1);
TIdSSLVersion = (sslvSSLv2, sslvSSLv23, sslvSSLv3, sslvTLSv1,sslvTLSv1_1,sslvTLSv1_2);

*)

(*
�������������� �������� ��� ����� �������� �� �����	AlternativeDomainNames,
������������� � HttpHeaders ������ �� ������, �� �������� �������� ������
�������� �������������� ���� ������ ������� Webkassa, ��������� � ������ ������,
������������ ������� ����� �������.

DefWebkassaAddress = 'https://devkkm.webkassa.kz/';
*)

procedure TWebkassaClient.HTTPHeadersAvailable(Sender: TObject;
  AHeaders: TIdHeaderList; var VContinue: Boolean);
var
  i: Integer;
  DomainName: WideString;
  DomainNames: TStrings;
  DomainNamesText: WideString;
begin
  VContinue := False;
  DomainNamesText := AHeaders.Values['AlternativeDomainNames'];
  DomainNamesText := StringReplace(DomainNamesText, ',', #13#10, []);
  DomainNames := TStringList.Create;
  try
    DomainNames.Text := DomainNamesText;
    for i := 0 to DomainNames.Count-1 do
    begin
      DomainName := DomainNames[i];
      if FDomainNames.IndexOf(DomainName) = -1 then
      begin
        FAddress := DomainName;
        FDomainNames.Add(DomainName);
        VContinue := True;
      end;
    end;
  finally
    DomainNames.Free;
  end;
end;

function TWebkassaClient.GetTransport: TIdHTTP;
var
  HandlerSocket: TIdSSLIOHandlerSocketOpenSSL;
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
    //FTransport.OnHeadersAvailable := HTTPHeadersAvailable;

    HandlerSocket := TIdSSLIOHandlerSocketOpenSSL.Create(FTransport);
    HandlerSocket.SSLOptions.Mode := sslmClient;
    HandlerSocket.SSLOptions.Method := sslvTLSv1_2;
    FTransport.IOHandler := HandlerSocket;
  end;
  Result := FTransport;
end;

procedure TWebkassaClient.Connect;
var
  Command: TAuthCommand;
begin
  if Token = '' then
  begin
    Command := TAuthCommand.Create;
    try
      Command.Request.Login := Login;
      Command.Request.Password := Password;
      if not Authenticate(Command) then
        RaiseLastError;
      FToken := Command.Data.Token;
      SaveParams;
    finally
      Command.Free;
    end;
  end;
end;

procedure TWebkassaClient.Disconnect;
begin
  FTransport.Free;
  FTransport := nil;
end;

procedure TWebkassaClient.RaiseLastError;
var
  i: Integer;
  Item: TErrorItem;
  Text: WideString;
begin
  if RaiseErrors then
  begin
    if FErrorResult.Errors.Count = 1 then
    begin
      Item := FErrorResult.Errors[0];
      RaiseError(Item.Code, Item.Text);
    end else
    begin
      Text := '';
      for i := 0 to FErrorResult.Errors.Count-1 do
      begin
        Item := FErrorResult.Errors[i];
        Text := Text + Format('%d, %s', [Item.Code, Item.Text]) + #13#10;
      end;
      RaiseError(-1, Text);
    end;
  end;
end;

function TWebkassaClient.Execute(Command: TWebkassaCommand): Boolean;
var
  JsonText: WideString;
begin
  Connect;

  JsonText := Command.Encode;
  JsonText := Post(GetAddress + Command.GetAddress, JsonText);
  Result := CheckLastError;
  if Result then
  begin
    Command.Decode(JsonText);
  end;
end;

function ChangeTokenInJson(const Request, Token: WideString): WideString;
var
  Json: TlkJSON;
  Doc: TlkJSONbase;
  Node: TlkJSONbase;
begin
  Json := TlkJSON.Create;
  try
    Doc := Json.ParseText(Request);
    Node := Doc.Field['Token'];
    if Node <> nil then
      Node.Value := Token;
    Result := Json.GenerateText(Doc);
  finally
    Json.Free;
  end;
end;

function TWebkassaClient.Post(URL, Request: WideString): WideString;
var
  RepCount: Integer;
  IsTokenExpired: Boolean;
const
  MaxConnectCount = 3;
begin
  IsTokenExpired := False;
  for RepCount := 1 to MaxConnectCount do
  begin
    if IsTokenExpired then
    begin
      Request := ChangeTokenInJson(Request, Token);
    end;
    Result := PostJson(URL, Request);
    IsTokenExpired := FErrorResult.IsTokenExpired;
    if not IsTokenExpired then Break;
    if IsTokenExpired and (RepCount = MaxConnectCount) then
      RaiseLastError;

    FToken := '';
    Connect;
  end;
end;

function TWebkassaClient.PostJson(const AURL, Request: WideString): WideString;
var
  S: AnsiString;
  URL: WideString;
  Stream: TStream;
  DstStream: TStream;
  Answer: AnsiString;
begin
  URL := AURL;
  FLogger.Debug('Post: ' + URL);
  FLogger.Debug('=> ' + UTF8Decode(Request));

  FCommandJson := Request;

  if FTestMode then
  begin
    Result := FAnswerJson;
    if FTestErrorResult <> nil then
    begin
      FErrorResult.Assign(FTestErrorResult);
      FTestErrorResult := nil;
    end;
    Exit;
  end;

  Stream := TMemoryStream.Create;
  DstStream := TMemoryStream.Create;
  try
    S := Request;
    Stream.WriteBuffer(S[1], Length(S));

    Transport.Post(URL, Stream, DstStream);
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

    if FTestErrorResult <> nil then
    begin
      FErrorResult.Assign(FTestErrorResult);
      FTestErrorResult := nil;
    end else
    begin
      FErrorResult.Errors.Clear;
      JsonToObject(Result, FErrorResult);
    end;
  finally
    Stream.Free;
    DstStream.Free;
  end;
end;

function TWebkassaClient.CheckLastError: Boolean;
begin
  Result := FErrorResult.Errors.Count = 0;
  if not Result then
    RaiseLastError;
end;

(*
4	�����������
����������� ������� � ������� Webkassa �������������� ����� ��������
��� ������ � ������. � ������ �������� ����������� ����� ������������
��������������� �������� Webkassa ���������� ��� - �����.
� ������ ������� ����� ������������ ��������������� ��� ������
(���� ������ ������� � ������� "���� ������������ ������").
����� ��������� �� ��������� �������� �����������.

������������� ������������� ��������������� (������ ������ ������) -
���������������� ������, �� �� ���� ���� � �����.
� ������ ��������� ������ � ����� 2 (���� �������� ������ �����)
��� ����������� ������ ���������� ������� ����� �����������.
� ����������� �������� ���������� ������������ ����� �����.

POST https://devkkm.webkassa.kz/api/Authorize
������ ���� �������:
{
"Login": "login@webkassa.kz",
"Password": "123"
}
������ ���� ������ ��� �������� ��������� �������:
{
"Data": {
"Token": "0b8557d0139945a582fcfee661ffad49"
}
}
������ ���� ������ � �������:
{
"Errors": [
{
"Code": 1,
"Text": "�������� ����� �/��� ������
}
]
}
*)

// api/Authorize
function TWebkassaClient.Authenticate(Command: TAuthCommand): Boolean;
var
  JsonText: WideString;
begin
  JsonText := ObjectToJson(Command.Request);
  JsonText := PostJson(GetAddress + 'api/Authorize', JsonText);
  Result := CheckLastError;
  if Result then
  begin
    JsonToObject(JsonText, Command);
  end;
end;

function TWebkassaClient.ChangeToken(Command: TChangeTokenCommand): Boolean;
var
  JsonText: WideString;
begin
  JsonText := ObjectToJson(Command.Request);
  JsonText := Post(GetAddress + 'api/Cashbox/ChangeToken', JsonText);
  Result := CheckLastError;
  if Result then
  begin
    JsonToObject(JsonText, Command);
  end;
end;

function TWebkassaClient.SendReceipt(Command: TSendReceiptCommand): Boolean;
var
  JsonText: WideString;
begin
  JsonText := ObjectToJson(Command.Request);
  JsonText := Post(GetAddress + 'api/check', JsonText);
  Result := CheckLastError;
  if Result then
  begin
    JsonToObject(JsonText, Command);
  end;
end;

(******************************************************************************

�������� � ������� ��������

������ �������� ��������� ����������� �������� (�������) �������� � �����.
��� ���������� �������� �������� ��� ������� �������� ���������� ��������� ������:
POST https://devkktn.webkassa.kz/api/MoneyOperation
������ ���� �������:
{
  "Token": "0b8557d0139945a582fcfee661ffad49",
  "CashboxUniqueNumber":	"SWK00000019",
  "OperationType": 1,
  "Sum": 1500,
  "ExternalCheckNumber" : "12345 67 8 9"
}
������ ���� ������:
{
  "Data": {
    "OfflineMode": true,
    "CashboxOfflineMode": true,
    "DateTime": "15.02.2018 17:18:29",
    "Sum": 56350,
    "Cashbox": {
      "UniqueNumber": "SWK0 0013404",
      "RegistrationNumber": "000134040000",
      "IdentityNumber": "561",
      "Address": "��. ������� 17, ��.521",
      "Ofd": {
        "Name": "�� "������������"",
        "Host": "consumer.oofd.kz",
        "Code": 1
      }
    }
  }
}
******************************************************************************)

function TWebkassaClient.MoneyOperation(Command: TMoneyOperationCommand): Boolean;
var
  JsonText: WideString;
begin
  JsonText := ObjectToJson(Command.Request);
  JsonText := Post(GetAddress + 'api/MoneyOperation', JsonText);
  Result := CheckLastError;
  if Result then
  begin
    JsonToObject(JsonText, Command);
  end;
end;

(*******************************************************************************
������ �������� ��������� ������������ �������� ����� ��� �����.
��� �������� ����� ������ ��� (���� Webkassa ��� ������ � ���������� ������)
��������� Z-����� (����� � ��������).
��� �������� ����� � ��������� Z-������ ���������� ����������� ������:

POST https://devkkm.webkassa.kz/api/ZReport

������ ���� �������:
{
  "Token": "0b8557d0139945a582fcfee661ffad49",
  "CashboxUniqueNumber": "SWK00000019"
}

������ ���� ������:
{
  "Data": {
    "ReportNuiriber": 2,
    "TaxPayerName": "�������������� ��������������� \"������ ���� ��������\"",
    "TaxpayerIN": "111111111111",
    "TaxPayerVAT": true,
    "TaxPayerVATSeria" : "12345",
    "TaxPayerVATNumber": "1234567",
    "CashboxSN" : "SWK00000019",
    "CashboxIN" : 7 646,
    "CashboxRN":	"100000000007",
    "StartOn": "25.05.2016 11:15:11",
    "ReportOn": "25.05.2016 11:33:30",
    "CloseOn": "25.05.2016 11:33:30",
    "CashierCode": 1,
    "ShiftNumber": 21,
    "DocumentCount": 2,
    " PutMoneySum" : 0 ,
    "TakeMoneySum" : 0,
    "ControlSum": 757292213,
    "OfflineMode": false,
    "CashboxOfflineMode": false,
    "SumInCashbox": 17500,
    "Sell": {
    " PaymentsByTypesApiModel" :	[
      {
      "Sum": 1050,
      "Type": 0
      }
    ] ,
    "Discount": 0,
    "Markup": 0,
    "Taken": 1050,
    "Change": 0,
    "Count" : 1,
    "VAT" : 0
    },
    "EndNonNullable" : {
    "Sell": 22690,
    "Buy": 0,
    "ReturnSell" : 0,
    "ReturnBuy" : 0
    "StartNonNullable": {
    "Sell": 21640,
    "Buy": 0,
    "ReturnSell" : 0,
    "ReturnBuy" : 0
    },
    "Ofd": {
    "Name": "�� "������������"", "Host": "consumer.oofd.kz",
    "Code": 1
    }
  }
}

*)

function TWebkassaClient.ZReport(Command: TZXReportCommand): Boolean;
var
  JsonText: WideString;
begin
  JsonText := ObjectToJson(Command.Request);
  JsonText := Post(GetAddress + 'api/zreport/extended', JsonText);
  Result := CheckLastError;
  if Result then
  begin
    JsonToObject(JsonText, Command);
  end;
end;

(*
�-�����
������ �������� ��������� �������� �� ������� ���
(�� Webkassa ��� ������ � ���������� ������) �-����� (����� ��� �������).
�-����� ����� ���������, ��������� � ������� XZReportResponse
(����������� Z-������) � ������� "�������� ����� (Z-�����)".
��� ��������� �-������ �������������� ���������� �������:
POST https://devkkm.webkassa.kz/am/XReport
������ ���� �������:
{
"CashboxUniqueNumber": " SWK00000004",
"Token": "0b8557d0139945a582fcfee661ffad49"
}
������ ���� ������:
��� ������ ������ - Xreport ������� ���������� �����, ��������� � ������� ZXReportResponse.
9.1.	������� ������
������� ������ ��� �������� ������������ �-������:
Xreport- �������� �-������
����	������������	��� ������	��������
������	�����������
Token	�����	String	��	�����, ���������� �� Webkassa.
CashboxUniqueNumber	���������/ ����� ��� ����� �����	String	��	���������� ����� �����


9.2.	�������� ������
��������� ������� �������� �������������� �-�����.
��������� �-������ ������� � ������� 6.2 (��������� ����������� Z-������ (������� XZReportResponse).
� ������ ����������� ���������� ������� ������ ���������� ��������������� ������.

*)

function TWebkassaClient.XReport(Command: TZXReportCommand): Boolean;
var
  JsonText: WideString;
begin
  JsonText := ObjectToJson(Command.Request);
  JsonText := Post(GetAddress + 'api/xreport/extended', JsonText);
  Result := CheckLastError;
  if Result then
  begin
    JsonToObject(JsonText, Command);
  end;
end;

(*
1	����������� ����� �� �����
������ �������� ��������� ��������� ������� �������� ����������� �����, ���������� ���������� � ���� �������� ��������� �� ���������� �����. ��� ��������� ����������� ����� ���������� ��������� ������:
POST https:/7devkJkm.webkassa.kz/api/Reports/ControlTape
������ ���� �������:
{
"Token": "f41�4���75�0499aa33430d5f50dfbac",
"CashboxUniqueNumber": "SWKO 0020101",
"ShiftNumber": "3"
}
������ ���� ������:
{
"Data":	[
{
" OperationTypeText" : ''������� '',
"Sum": 19500,
"Date": "01.09.2016 12:50:57",
"EmployeeCode": 1,
"Number": "2883145944",
"IsOffline": false
},
{
"OperationTypeText": "�������� ����� � �����", "Sum": 2000,
"Date": "01.09.2016 12:49:49",
"EmployeeCode" : 1,
"IsOffline": false,
"ExternalOperationld": "123456789"
>,
{
"OperationTypeText": "������� ����� �� �����", "Sum": 1500,
"Date": "01.09.2016 12:50:37",
"EmployeeCode": 1,
"IsOffline": false,
"ExternalOperationld" : "123456790"
>
3
}
*)

function TWebkassaClient.JournalReport(Command: TJournalReportCommand): Boolean;
var
  JsonText: WideString;
begin
  JsonText := ObjectToJson(Command.Request);
  JsonText := Post(GetAddress + 'api/Reports/ControlTape', JsonText);
  Result := CheckLastError;
  if Result then
  begin
    JsonToObject(JsonText, Command);
  end;
end;

(*
������ �������� ��������� ��������� ������� �������� ������ ����,
��������� ������������. ��� ��������� ������ ���� ������������ ���������� ��������� ������:
POST https://devkktn.webkassa.kz/api/Cashboxes
������ ���� �������:
{
"Token" : "f41a4aec75c0499aa33430cl5f50dfbac"
}
������ ���� ������:
{
"Data": {
"List":	[
{
"UniqueNumber": "SWK00003209", "RegistrationNumber": "654789321456",
"IdentificationNuiriber ": "85274",
"Name": "����� 123",
"Description": "����� ��� �������� �� ��������", "IsOffline": true,
"CurrentStatus": 0,
"Shift": 0
}
]
}
}

*)

function TWebkassaClient.ReadCashboxes(Command: TCashboxesCommand): Boolean;
var
  JsonText: WideString;
begin
  JsonText := ObjectToJson(Command.Request);
  JsonText := Post(GetAddress + 'api/Cashboxes', JsonText);
  Result := CheckLastError;
  if Result then
  begin
    JsonToObject(JsonText, Command);
  end;
end;

function TWebkassaClient.ReadCashboxStatus(Request: TCashboxRequest): Boolean;
var
  JsonText: WideString;
begin
  JsonText := ObjectToJson(Request);
  JsonText := Post(GetAddress + 'api/cashbox/state', JsonText);
  Result := CheckLastError;
end;

(******************************************************************************
������ ���� �������:
{
"CashboxUniqueNumber" : "SWK00060538 ",
"Token" : "be85da8a4 6f34 67cb22930cll284cc652M , "Skip": 0,
"Take": 50
}
������ ���� ������: {
"Data" : {
"CashboxUniqueNumber": "SWKO 0199538", "Skip": 0,
"Take": 50,
"Total": 14,
"Shifts": [
{
"ShiftNumber" : 1,
"OpenDate": "23.05.2017 11:43:50", "CloseDate": "05.06.2017 19:12:26"
) ,
{
"ShiftNumber" : 2,
"OpenDate": "06.06.2017 08:33:36", "CloseDate": "06.06.2017 10:27:30"
) ,
{
"ShiftNumber" : 3,
"OpenDate": "06.06.2017 11:44:12", "CloseDate": "06.06.2017 12:21:19"
} ,
{
"ShiftNumber" : 4,
"OpenDate": "06.06.2017 13:11:43", "CloseDate": "06.06.2017 13:13:31"
},
{
"ShiftNumber" : 5,
"OpenDate": "17.07.2017 08:54:29", "CloseDate": "19.07.2017 13:35:57"
},
{
"ShiftNumber" : 6,
"OpenDate": "19.07.2017 13:36:30", "CloseDate": "24.07.2017 18:12:50"
),
{
"ShiftNumber" : 7,
"OpenDate": "25.07.2017 11:15:50",
� �� �������� �������� ������� ����� "CloseDate": "26.07.2017 11:49:57"
},
{
"ShiftNumber" : 8,
"OpenDate": "26.07.2017 11:50:31",
"CloseDate": "27.07.2017 12:07:01"
) ,
{
" ShiftNumber" : 9,
"OpenDate": "27.07.2017 12:07:33",
"CloseDate": "31.07.2017 15:18:48"
} ,
{
"ShiftNumber" : 10,
"OpenDate": "31.07.2017 15:20:21",
"CloseDate": "01.08.2017 14:45:53"
},
{
"ShiftNumber" : 11,
"OpenDate": "03.08.2017 15:29:34",
"CloseDate": "04.08.2017 15:09:51"
} ,
{
"ShiftNumber" : 12,
"OpenDate": "07.08.2017 17:32:29",
"CloseDate": "07.08.2017 17:39:01"
) ,
{
"ShiftNumber" : 13,
"OpenDate": "07.08.2017 17:39:33",
"CloseDate": "09.08.2017 11:08:19"
},
{
"ShiftNumber" : 14,
"OpenDate": "09.08.2017 11:08:27"
}
3
}
}
******************************************************************************)

function TWebkassaClient.ReadShiftHistory(Command: TShiftCommand): Boolean;
var
  JsonText: WideString;
begin
  JsonText := ObjectToJson(Command.Request);
  JsonText := Post(GetAddress + 'api/ShiftHistory', JsonText);
  Result := CheckLastError;
  if Result then
  begin
    JsonToObject(JsonText, Command);
  end;
end;

(*
13	��������� ������ ��������
������ ����� ��������� �������� ������ �������� ����������� �� Webkassa. ��� ��������� ������ ���������� ��������� ������:
POST https://devkkm.webkassa.kz/api/Emplovee/List
������ ���� �������:
{
"Token" : "f41a4aec75c0499aa33430cl5f50dfbac"
}
������ ���� ������:
{
"Data": [
{
"FullName": "������ �.�.",
"Email": "pochta@pochta.com",
"Cashboxes" :	[
"SWKO 0000019",
"SWKO0000020"
]
},
{
"FullName": "������ �. �. ",
"Email": "pochtal212@pochta.com",
"Cashboxes":	[
"SWKO0000019"
]
},
{
"FullName": "������� M.H.",
"Email": "pochtaOO@pochta.com",
"Cashboxes":	[
"SWKO 00 0 002.0"
]
>
]
}

*)

function TWebkassaClient.ReadCashiers(Command: TCashierCommand): Boolean;
var
  JsonText: WideString;
begin
  JsonText := ObjectToJson(Command.Request);
  JsonText := Post(GetAddress + 'api/Employee/List', JsonText);
  Result := CheckLastError;
  if Result then
  begin
    JsonToObject(JsonText, Command);
  end;
end;

(*
14	��������� ���� �� ������
������ ������ ��������� �������� ��� �� ��� ����������� ������ (����������� ����). ��� ��������� ���� ���������� ��������� ������:
POST https: //devkkm. webkassa. kz/ ap i/Cheek/Historv By N umber
������ ���� �������:
{
"CashboxUniqueNumber": "SWKO0030586",
"Token": "6a4eaa2e5f764950blelce3712110d3d",
"Number": "445113829",
"ShiftNumber": 16
}
������ ���� ������:
{
"Data": {
"CashboxUniqueNumber": "SWK00030586",
"CashboxRegistrationNuiriber": "170420180002", "CashboxIdentityNumber": 1941,
"Address": "��. ������� 17, ��.521",
"Number" : "4 4 511382 9",
"OrderNumber": 2,
"RegistratedOn": "11.04.2019 17:42:37", "EmployeeName": "������������",
"EmployeeCode": 31,
"ShiftNumber": 16,
"DocumentNumber" : 39,
" OperationType" : 2 ,
"OperationTypeText": "�������",
"Payments":	[
{
"Sum": 5894,
"PaymentTypeName": "��������"
}
3 ,
"Total": 5894,
"Change": 0,
"Taken": 5894,
"Discount": 0,
"MarkupPercent" : 0,
"Markup" : 0,
"TaxPercent" : 12,
"Tax": 631.5,
"VATPayer": true,
"Positions" :	[
{
"PositionName": "�������",
"PositionCode" : "1",
"Count" : 1,
"Price": 5894,
"DiscountPercent": 0,
"DiscountTenge": 0,
"MarkupPercent": 0,
"Markup": 0,
"TaxPercent": 0,
"Tax": 631.5,
"IsNds": true,
"IsStorno": false,
"MarkupDeleted": false,
"DiscountDeleted": false,
"Sum": 5894,
"UnitCode": 796,
"Mark": "U1DN3ACFU7FJ"
}
] ,
"IsOffline": false,
"TicketUrl" :
"https://kkm.webkassa.kz/Ticket?chb=SWK00030586&extnum=5de5eb21-77ba-497 9- 996c-e38b7 9a991d5"
}
}

*)

function TWebkassaClient.ReadReceipt(Command: TReceiptCommand): Boolean;
var
  JsonText: WideString;
begin
  JsonText := ObjectToJson(Command.Request);
  JsonText := Post(GetAddress + 'api/Check/HistoryByNumber', JsonText);
  Result := CheckLastError;
  if Result then
  begin
    JsonToObject(JsonText, Command);
  end;
end;

function TWebkassaClient.ReadReceiptText(Command: TReceiptTextCommand): Boolean;
var
  JsonText: WideString;
begin
  JsonText := ObjectToJson(Command.Request);
  JsonText := Post(GetAddress + 'api/Ticket/PrintFormat', JsonText);
  Result := CheckLastError;
  if Result then
  begin
    JsonToObject(JsonText, Command);
  end;
end;

function TWebkassaClient.ReadUnits(Command: TReadUnitsCommand): Boolean;
var
  JsonText: WideString;
begin
  JsonText := ObjectToJson(Command.Request);
  JsonText := Post(GetAddress + 'api/references/RefUnits', JsonText);
  Result := CheckLastError;
  if Result then
  begin
    JsonToObject(JsonText, Command);
  end;
end;

function TWebkassaClient.UploadOrder(
  Command: TUploadOrderCommand): Boolean;
var
  JsonText: WideString;
begin
  JsonText := ObjectToJson(Command.Request);
  JsonText := Post(GetAddress + 'api/Courier/UploadExtemalOrder', JsonText);
  Result := CheckLastError;
  if Result then
  begin
    JsonToObject(JsonText, Command);
  end;
end;

function TWebkassaClient.GetAddress: WideString;
begin
  Result := FAddress;
  if Length(Result) > 0 then
  begin
    if Result[Length(Result)] = '\' then
      Result[Length(Result)] := '/';

    if not(Char(Result[Length(Result)]) in ['\', '/']) then
      Result := Result + '/';
  end;
end;

{ TMoneyOperationResponse }

constructor TMoneyOperationResponse.Create;
begin
  inherited Create;
  FCashbox := TCashboxParameters.Create;
end;

destructor TMoneyOperationResponse.Destroy;
begin
  FCashbox.Free;
  inherited Destroy;
end;

{ TCashboxParameters }

constructor TCashboxParameters.Create;
begin
  inherited Create;
  FOfd := TOfdInformation.Create;
end;

destructor TCashboxParameters.Destroy;
begin
  FOfd.Free;
  inherited Destroy;
end;

procedure TCashboxParameters.Assign(Source: TPersistent);
var
  Src: TCashboxParameters;
begin
  if Source is TCashboxParameters then
  begin
    Src := Source as TCashboxParameters;
    FUniqueNumber := Src.FUniqueNumber;
    FRegistrationNumber := Src.FRegistrationNumber;
    FIdentityNumber := Src.FIdentityNumber;
    FAddress := Src.FAddress;
    FOfd.Assign(Src.Ofd);
  end else
  begin
    inherited Assign(Source);
  end;
end;

procedure TCashboxParameters.SetOfd(const Value: TOfdInformation);
begin
  FOfd.Assign(Value);
end;

{ TOfdInformation }

procedure TOfdInformation.Assign(Source: TPersistent);
var
  Src: TOfdInformation;
begin
  if Source is TOfdInformation then
  begin
    Src := Source as TOfdInformation;
    FCode := Src.Code;
    FHost := Src.Host;
    FName := Src.Name;
  end;
end;

{ TMoneyOperationCommand }

constructor TMoneyOperationCommand.Create;
begin
  inherited Create;
  FData := TMoneyOperationResponse.Create;
  FRequest := TMoneyOperationRequest.Create;
end;

destructor TMoneyOperationCommand.Destroy;
begin
  FData.Free;
  FRequest.Free;
  inherited Destroy;
end;

procedure TMoneyOperationCommand.Decode(const JsonText: WideString);
begin
  JsonToObject(JsonText, Self);
end;

function TMoneyOperationCommand.Encode: WideString;
begin
  Result := ObjectToJson(Request);
end;

function TMoneyOperationCommand.GetAddress: WideString;
begin
  Result := 'api/MoneyOperation';
end;

procedure TMoneyOperationCommand.setData(const Value: TMoneyOperationResponse);
begin
  FData.Assign(Value);
end;

{ TZXReportCommand }

constructor TZXReportCommand.Create;
begin
  inherited Create;
  FData := TZXReportResponse.Create;
  FRequest := TCashboxRequest.Create;
end;

destructor TZXReportCommand.Destroy;
begin
  FData.Free;
  FRequest.Free;
  inherited Destroy;
end;

procedure TZXReportCommand.setData(const Value: TZXReportResponse);
begin
  FData.Assign(Value);
end;

{ TOperationTypeSummary }

constructor TOperationTypeSummary.Create;
begin
  inherited Create;
  FPayments := TPaymentsByType.Create(TPaymentByType);
end;

destructor TOperationTypeSummary.Destroy;
begin
  FPayments.Free;
  inherited Destroy;
end;

procedure TOperationTypeSummary.SetPayments(const Value: TPaymentsByType);
begin
  FPayments.Assign(Value);
end;

{ TZXReportResponse }

constructor TZXReportResponse.Create;
begin
  inherited Create;
  FSell := TOperationTypeSummary.Create;
  FBuy := TOperationTypeSummary.Create;
  FReturnSell := TOperationTypeSummary.Create;
  FReturnBuy := TOperationTypeSummary.Create;
  FStartNonNullable := TNonNullable.Create;
  FEndNonNullable := TNonNullable.Create;
  FOfd := TOfdInformation.Create;
end;

destructor TZXReportResponse.Destroy;
begin
  FSell.Free;
  FBuy.Free;
  FReturnSell.Free;
  FReturnBuy.Free;
  FStartNonNullable.Free;
  FEndNonNullable.Free;
  FOfd.Free;
  inherited Destroy;
end;

procedure TZXReportResponse.SetBuy(const Value: TOperationTypeSummary);
begin
  FBuy.Assign(Value);
end;

procedure TZXReportResponse.SetEndNonNullable(const Value: TNonNullable);
begin
  FEndNonNullable.Assign(Value);
end;

procedure TZXReportResponse.SetOfd(const Value: TOfdInformation);
begin
  FOfd.Assign(Value);
end;

procedure TZXReportResponse.SetReturnBuy(
  const Value: TOperationTypeSummary);
begin
  FReturnBuy.Assign(Value);
end;

procedure TZXReportResponse.SetReturnSell(
  const Value: TOperationTypeSummary);
begin
  FReturnSell.Assign(Value);
end;

procedure TZXReportResponse.SetSell(const Value: TOperationTypeSummary);
begin
  FSell.Assign(Value);
end;

procedure TZXReportResponse.SetStartNonNullable(const Value: TNonNullable);
begin
  FStartNonNullable.Assign(Value);
end;

{ TJournalReportCommand }

constructor TJournalReportCommand.Create;
begin
  inherited Create;
  FRequest := TJournalReportRequest.Create;
  FData := TJsonCollection.Create(TJournalReportItem);
end;

destructor TJournalReportCommand.Destroy;
begin
  FRequest.Free;
  FData.Free;
  inherited Destroy;
end;

procedure TJournalReportCommand.setData(const Value: TJsonCollection);
begin
  FData.Assign(Value);
end;

{ TCashboxesResponse }

constructor TCashboxesResponse.Create;
begin
  inherited Create;
  FList := TCashBoxes.Create(TCashbox);
end;

destructor TCashboxesResponse.Destroy;
begin
  FList.Free;
  inherited Destroy;
end;

procedure TCashboxesResponse.SetList(const Value: TCashBoxes);
begin
  FList.Assign(Value);
end;

{ TCashboxesCommand }

constructor TCashboxesCommand.Create;
begin
  inherited Create;
  FData := TCashboxesResponse.Create;
  FRequest := TTokenRequest.Create;
end;

destructor TCashboxesCommand.Destroy;
begin
  FData.Free;
  FRequest.Free;
  inherited Destroy;
end;

procedure TCashboxesCommand.setData(const Value: TCashboxesResponse);
begin
  FData.Assign(Value);
end;

{ TShiftResponse }

constructor TShiftResponse.Create;
begin
  inherited Create;
  FShifts := TJsonCollection.Create(TShiftItem);
end;

destructor TShiftResponse.Destroy;
begin
  FShifts.Free;
  inherited Destroy;
end;

procedure TShiftResponse.SetShifts(const Value: TJsonCollection);
begin
  FShifts.Assign(Value);
end;

{ TShiftCommand }

constructor TShiftCommand.Create;
begin
  inherited Create;
  FData := TShiftResponse.Create;
  FRequest := TShiftRequest.Create;
end;

destructor TShiftCommand.Destroy;
begin
  FData.Free;
  FRequest.Free;
  inherited Destroy;
end;

procedure TShiftCommand.setData(const Value: TShiftResponse);
begin
  FData.Assign(Value);
end;

{ TCashier }

constructor TCashier.Create(Collection: TJsonCollection);
begin
  inherited Create(Collection);
  FCashboxes := TStringList.Create;
end;

destructor TCashier.Destroy;
begin
  FCashboxes.Free;
  inherited Destroy;
end;

procedure TCashier.SetCashboxes(const Value: TStrings);
begin
  FCashboxes.Assign(Value);
end;

procedure TCashier.Assign(Source: TPersistent);
var
  Src: TCashier;
begin
  if Source is TCashier then
  begin
    Src := Source as TCashier;
    FFullName := Src.FullName;
    FEmail := Src.Email;
    FCashboxes.Assign(Src.Cashboxes);
  end else
    inherited Assign(Source);
end;

{ TCashierCommand }

constructor TCashierCommand.Create;
begin
  inherited Create;
  FRequest := TTokenRequest.Create;
  FData := TCashiers.Create;
end;

destructor TCashierCommand.Destroy;
begin
  FData.Free;
  FRequest.Free;
  inherited Destroy;
end;

procedure TCashierCommand.setData(const Value: TCashiers);
begin
  FData.Assign(Value);
end;

{ TReceiptResponse }

constructor TReceiptResponse.Create;
begin
  inherited Create;
  FOfd := TOfdInformation.Create;
  FPayments :=	TPaymentItems.Create;
  FPositions := TPositionItems.Create;
end;

destructor TReceiptResponse.Destroy;
begin
  FOfd.Free;
  FPayments.Free;
  FPositions.Free;
  inherited Destroy;
end;

procedure TReceiptResponse.SetOfd(const Value: TOfdInformation);
begin
  FOfd.Assign(Value);
end;

procedure TReceiptResponse.SetPayments(const Value: TPaymentItems);
begin
  FPayments.Assign(Value);
end;

procedure TReceiptResponse.SetPositions(const Value: TPositionItems);
begin
  FPositions.Assign(Value);
end;

{ TReceiptCommand }

constructor TReceiptCommand.Create;
begin
  inherited Create;
  FData := TReceiptResponse.Create;
  FRequest := TReceiptRequest.Create;
end;

destructor TReceiptCommand.Destroy;
begin
  FData.Free;
  FRequest.Free;
  inherited Destroy;
end;

procedure TReceiptCommand.setData(const Value: TReceiptResponse);
begin
  FData.Assign(Value);
end;

{ TReceiptTextAnswer }

constructor TReceiptTextAnswer.Create;
begin
  inherited Create;
  FLines := TJsonCollection.Create(TReceiptTextItem);
end;

destructor TReceiptTextAnswer.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

function TReceiptTextAnswer.GetText: WideString;
var
  i: Integer;
  Strings: TTntStrings;
begin
  Strings := TTntStringList.Create;
  try
    for i := 0 to Lines.Count-1 do
    begin
      Strings.Add((Lines.Items[i] as TReceiptTextItem).Value);
    end;
    Result := Strings.Text;
  finally
    Strings.Free;
  end;
end;

procedure TReceiptTextAnswer.SetLines(const Value: TJsonCollection);
begin
  FLines.Assign(Value);
end;

{ TReceiptTextCommand }

constructor TReceiptTextCommand.Create;
begin
  inherited Create;
  FData := TReceiptTextAnswer.Create;
  FRequest := TReceiptTextRequest.Create;
end;

destructor TReceiptTextCommand.Destroy;
begin
  FData.Free;
  FRequest.Free;
  inherited Destroy;
end;

procedure TReceiptTextCommand.setData(const Value: TReceiptTextAnswer);
begin
  FData.Assign(Value);
end;

{ TReadUnitsCommand }

constructor TReadUnitsCommand.Create;
begin
  inherited Create;
  FRequest := TTokenRequest.Create;
  FData := TUnitItems.Create(TUnitItem);
end;

destructor TReadUnitsCommand.Destroy;
begin
  FData.Free;
  FRequest.Free;
  inherited Destroy;
end;

procedure TReadUnitsCommand.setData(const Value: TUnitItems);
begin
  FData.Assign(Value);
end;

{ TAuthCommand }

constructor TAuthCommand.Create;
begin
  inherited Create;
  FData := TAuthResponse.Create;
  FRequest := TAuthRequest.Create;
end;

destructor TAuthCommand.Destroy;
begin
  FData.Free;
  FRequest.Free;
  inherited Destroy;
end;

function TAuthCommand.Encode: WideString;
begin
  Result := ObjectToJson(Request);
end;

procedure TAuthCommand.Decode(const JsonText: WideString);
begin
  JsonToObject(JsonText, Self);
end;

function TAuthCommand.GetAddress: WideString;
begin
  Result := 'api/Authorize';
end;

procedure TAuthCommand.SetData(const Value: TAuthResponse);
begin
  FData.Assign(Value);
end;

{ TPaymentsByType }

function TPaymentsByType.GetItem(Index: Integer): TPaymentByType;
begin
  Result := inherited Items[Index] as TPaymentByType;
end;

procedure TPaymentsByType.SetItem(Index: Integer;  const Value: TPaymentByType);
begin
  inherited Items[Index] := Value;
end;

{ TUploadOrderCommand }

constructor TUploadOrderCommand.Create;
begin
  inherited Create;
  FRequest := TUploadOrderRequest.Create;
end;

destructor TUploadOrderCommand.Destroy;
begin
  FRequest.Free;
  inherited Destroy;
end;

{ TUploadOrderRequest }

constructor TUploadOrderRequest.Create;
begin
  inherited Create;
  FPositions := TJsonCollection.Create(TOrderItem);
end;

destructor TUploadOrderRequest.Destroy;
begin
  FPositions.Free;
  inherited Destroy;
end;

procedure TUploadOrderRequest.SetPositions(const Value: TJsonCollection);
begin
  FPositions.Assign(Value);
end;

{ TChangeTokenCommand }

constructor TChangeTokenCommand.Create;
begin
  inherited Create;
  FRequest := TChangeTokenRequest.Create;
end;

destructor TChangeTokenCommand.Destroy;
begin
  FRequest.Free;
  inherited Destroy;
end;

{ TErrorResult }

procedure TErrorResult.Assign(Source: TPersistent);
var
  Src: TErrorResult;
begin
  if Source is TErrorResult then
  begin
    Src := Source as TErrorResult;
    Errors.Assign(Src.Errors);
  end;
end;

constructor TErrorResult.Create;
begin
  inherited Create;
  FErrors := TErrorItems.Create(TErrorItem);
end;

destructor TErrorResult.Destroy;
begin
  FErrors.Free;
  inherited Destroy;
end;

function TErrorResult.IsTokenExpired: Boolean;
var
  i: Integer;
  Item: TErrorItem;
begin
  Result := False;
  for i := 0 to Errors.Count-1 do
  begin
    Item := Errors.Items[i] as TErrorItem;
    Result := Item.Code = WEBKASSA_E_TOKEN_EXPIRED;
    if Result then Break;
  end;
end;

procedure TErrorResult.SetErrors(const Value: TErrorItems);
begin
  FErrors.Assign(Value);
end;

{ TSendReceiptCommand }

constructor TSendReceiptCommand.Create;
begin
  inherited Create;
  FData := TSendReceiptCommandResponse.Create;
  FRequest := TSendReceiptCommandRequest.Create;
end;

destructor TSendReceiptCommand.Destroy;
begin
  FData.Free;
  FRequest.Free;
  inherited Destroy;
end;

procedure TSendReceiptCommand.SetData(
  const Value: TSendReceiptCommandResponse);
begin
  FData.Assign(Value);
end;

{ TSendReceiptCommandRequest }

constructor TSendReceiptCommandRequest.Create;
begin
  inherited Create;
  FPositions := TTicketItems.Create;
  FTicketModifiers := TTicketModifiers.Create;
  FPayments := TPayments.Create;
end;

destructor TSendReceiptCommandRequest.Destroy;
begin
  FPositions.Free;
  FTicketModifiers.Free;
  FPayments.Free;
  inherited Destroy;
end;

function TSendReceiptCommandRequest.IsRequiredField(const Field: WideString): Boolean;
const
  RequiredFields: array [0..8] of WideString = (
  'Token', 'CashboxUniqueNumber', 'OperationType', 'Positions',
  'TicketModifiers', 'Payments', 'Change', 'RoundType', 'ExternalCheckNumber');
var
  i: Integer;
begin
  for i := Low(RequiredFields) to High(RequiredFields) do
  begin
    Result := AnsiCompareText(Field, RequiredFields[i]) = 0;
    if Result then Break;
  end;
end;

procedure TSendReceiptCommandRequest.SetPayments(const Value: TPayments);
begin
  FPayments.Assign(Value);
end;

procedure TSendReceiptCommandRequest.SetPositions(const Value: TTicketItems);
begin
  FPositions.Assign(Value);
end;

procedure TSendReceiptCommandRequest.SetTicketModifiers(
  const Value: TTicketModifiers);
begin
  FTicketModifiers.Assign(Value);
end;

{ TSendReceiptCommandResponse }

constructor TSendReceiptCommandResponse.Create;
begin
  inherited Create;
  FCashbox := TCashboxParameters.Create;
end;

destructor TSendReceiptCommandResponse.Destroy;
begin
  FCashbox.Free;
  inherited Destroy;
end;

procedure TSendReceiptCommandResponse.SetCashbox(
  const Value: TCashboxParameters);
begin
  FCashbox.Assign(Value);
end;

{ TReceiptTextItem }

procedure TReceiptTextItem.Assign(Source: TPersistent);
var
  Src: TReceiptTextItem;
begin
  if Source is TReceiptTextItem then
  begin
    Src := Source as TReceiptTextItem;

    FOrder := Src.Order;
    FType := Src._Type;
    FValue := Src.Value;
    FStyle := Src.Style;
  end;
end;

{ TUnitItems }

function TUnitItems.GetItem(Index: Integer): TUnitItem;
begin
  Result := inherited Items[Index] as TUnitItem;
end;

function TUnitItems.ItemByCode(Code: Integer): TUnitItem;
var
  i: Integer;
begin
  for i := 0 to Count-1 do
  begin
    Result := Items[i];
    if Result.Code = Code then Exit;
  end;
  Result := nil;
end;

{ TUnitItem }

procedure TUnitItem.Assign(Source: TPersistent);
var
  Src: TUnitItem;
begin
  if Source is TUnitItem then
  begin
    Src := Source as TUnitItem;
    Code := Src.Code;
    NameRu := Src.NameRu;
    NameKz := Src.NameKz;
    NameEn := Src.NameEn;
  end;
end;

(*

	public const WideString kwmbvk = "/api/authorize";
	public const WideString kwmbvl = "/api/check";
	public const WideString kwmbvm = "/api/moneyoperation";
	public const WideString kwmbvn = "/api/xreport/extended";
	public const WideString kwmbvo = "/api/zreport/extended";
	public const WideString kwmbvp = "/api/cashbox/state";
	public const WideString kwmbvq = "/api/offlineOperation";
	public const WideString kwmbvr = "/api/ping";
}

*)

{ TErrorItem }

procedure TErrorItem.Assign(Source: TPersistent);
var
  Src: TErrorItem;
begin
  if Source is TErrorItem then
  begin
    Src := Source as TErrorItem;
    FCode := Src.Code;
    FText := Src.Text;
  end else
  begin
    inherited Assign(Source);
  end;
end;

{ TErrorItems }

function TErrorItems.GetItem(Index: Integer): TErrorItem;
begin
  Result := inherited Items[Index] as TErrorItem;
end;

{ TTicketItems }

constructor TTicketItems.Create;
begin
  inherited Create(TTicketItem);
end;

function TTicketItems.GetItem(Index: Integer): TTicketItem;
begin
  Result := inherited Items[Index] as TTicketItem;
end;

{ TPayments }

constructor TPayments.Create;
begin
  inherited Create(TPayment);
end;

function TPayments.GetItem(Index: Integer): TPayment;
begin
  Result := inherited Items[Index] as TPayment;
end;

{ TTicketModifiers }

constructor TTicketModifiers.Create;
begin
  inherited Create(TTicketModifier);
end;

function TTicketModifiers.GetItem(Index: Integer): TTicketModifier;
begin
  Result := inherited Items[Index] as TTicketModifier;
end;

{ TPaymentItems }

constructor TPaymentItems.Create;
begin
  inherited Create(TPaymentItem);
end;

function TPaymentItems.GetItem(Index: Integer): TPaymentItem;
begin
  Result := inherited Items[Index] as TPaymentItem;
end;

{ TPositionItems }

constructor TPositionItems.Create;
begin
  inherited Create(TPositionItem);
end;

function TPositionItems.GetItem(Index: Integer): TPositionItem;
begin
  Result := inherited Items[Index] as TPositionItem;
end;

{ TCashbox }

procedure TCashbox.Assign(Source: TPersistent);
var
  Src: TCashbox;
begin
  if Source is TCashbox then
  begin
    Src := Source as TCashbox;
    UniqueNumber := Src.UniqueNumber;
    RegistrationNumber := src.RegistrationNumber;
    IdentificationNumber := Src.IdentificationNumber;
    Name := Src.Name;
    Description := Src.Description;
    IsOffline := Src.IsOffline;
    CurrentStatus := Src.CurrentStatus;
    Shift := SRc.Shift;
  end else
    inherited Assign(Source);
end;

{ TCashBoxes }

function TCashBoxes.GetItem(Index: Integer): TCashBox;
begin
  Result := inherited Items[Index] as TCashBox;
end;

function TCashBoxes.ItemByUniqueNumber(const Value: WideString): TCashBox;
var
  i: Integer;
begin
  for i := 0 to Count-1 do
  begin
    Result := Items[i];
    if Result.UniqueNumber = Value then Exit;
  end;
  Result := nil;
end;

{ TCashiers }

constructor TCashiers.Create;
begin
  inherited Create(TCashier);
end;

function TCashiers.GetItem(Index: Integer): TCashier;
begin
  Result := inherited Items[Index] as TCashier;
end;

function TCashiers.ItemByEMail(const email: WideString): TCashier;
var
  i: Integer;
begin
  for i := 0 to Count-1 do
  begin
    Result := Items[i];
    if AnsiCompareText(Result.Email, email) = 0 then Exit;
  end;
  Result := nil;
end;

initialization
  DecimalSeparator := '.';

end.


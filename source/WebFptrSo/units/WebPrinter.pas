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
  LogFile, JsonUtils, DriverError, uLkJSON;

const
  // ТАБЛИЦА ЗНАЧЕНИЙ, ВОЗВРАЩАЮЩАЯСЯ С ФИСКАЛЬНОГО МОДУЛЯ
  WP_SUCCESS = $9000; // Успешно
  WP_ERROR_RECEIPT_COUNT_ZERO = $9006; // Количество чеков равно нулю
  WP_ERROR_RECEIPT_INDEX_OUT_OF_BOUNDS = $9007; // Номер чека не правильный
  WP_ERROR_RECEIPT_NOT_FOUND = $9008; // Чек не найден
  WP_ERROR_DATA_SIZE_NOT_SUPPORTED = $9009; // Размер информации не поддерживается
  WP_ERROR_RECEIPT_FORMAT_INVALID = $900D; // Формат чека не правильный
  WP_ERROR_RECEIPT_TOTAL_PRICE_OVERFLOW	= $900E; // Общая сумма превышает максимального значения
  WP_ERROR_RECEIPT_TOTAL_PRICE_MISMATCH	= $900F; // Общая сумма превышает стоимость по товарным позициям
  WP_ERROR_RECEIPT_MEMORY_FULL = $9016; // Память чека заполнена
  WP_ERROR_RECEIPT_TIME_PAST = $9018; // Время чека старое
  WP_ERROR_RECEIPT_STORE_DAYS_LIMIT_EXCEEDED	= $9019; // Кол-во дней хранения чеков превышено, следует отправить чеки
  WP_ERROR_LAST_TRANSACTION_TIME_FORMAT_INVALID = $901A; // Формат времени последней транзакции ошибочна
  WP_ERROR_FIRST_RECEIPT_TRANSACTION_TIME_FORMAT_INVALID = $901B; // Формат времени чека ошибочная
  WP_ERROR_ACKNOWLEGE_WRONG_LENGTH = $901C; // Ошибка сервера ОФД по длине строк
  WP_ERROR_ACKNOWLEGE_SIGNATURE_INVALID = $901D; // Ошибка сервера ОФД по подписи чека
  WP_ERROR_ACKNOWLEGE_TERMINAL_ID_MISMATCH = $901E; // Ошибка сервера ОФД по номеру ФМ (все три позиции связаны с несанкционированным доступом к серверу ОФД)
  WP_ERROR_ZREPORT_PARTITION_INVALID = $901F;
  WP_ERROR_OPEN_CLOSE_ZREPORT_WRONG_LENGTH = $9020; // Ошибка связана с длиной строки Z-отчета
  WP_ERROR_CLOSE_ZREPORT_TIME_PAST = $9021; // Время закрытие чека старое
  WP_ERROR_ZREPORT_SPACE_IS_FULL = $9022; // Память Z-отчета заполнена
  WP_ERROR_CURRENT_TIME_FORMAT_INVALID = $9023; // Ошибка формат текущего времени
  WP_ERROR_RECEIPT_TRANSACTION_TIME_FORMAT_INVALID = $9024; // Ошибка формат времени последнего отправленного чека ошибочна
  WP_ERROR_ZREPORT_INDEX_OUT_OF_BOUNDS 	= $9026; // Номер Z-report не правильный
  WP_ERROR_LOCK_CHALLENGE_INVALID 	= $9027;
  WP_ERROR_LOCKED_FOREVER = $9028; // Фискальный модуль заблокирован
  WP_ERROR_CONFIGURE_WRONG_LENGTH = $9029;
  WP_ERROR_CONFIGURE_SIGNATURE_INVALID = $902A;
  WP_ERROR_CURRENT_ZREPORT_IS_EMPTY = $902B; // Текущий Z-report пустой
  WP_ERROR_RECEIPT_TOTAL_PRICE_ZERO	= $902C; // Общая сумма чека не может быть нулем
  WP_ERROR_ZREPORT_IS_NOT_OPEN = $902D; // Z-report не открыт
  WP_ERROR_ZREPORT_OPEN_TIME_FORMAT_INVALID	= $902E; // Формат времени открытия Z-report ошибочна
  WP_ERROR_SALE_REFUND_COUNT_OVERFLOW = $902F; // Превышено кол-во операций (продажи и возврата) в Z- отчете
  WP_ERROR_ZREPORT_IS_ALREADY_OPEN = $9030; // Z-отчет (смена) уже открыта
  WP_ERROR_NOT_ENOUGH_CASH_FOR_REFUND = $9031; // Не достаточно средств для возврата (наличка)
  WP_ERROR_NOT_ENOUGH_CARD_FOR_REFUND = $9032; // Не достаточно средств для возврата (пластик)
  WP_ERROR_NOT_ENOUGH_VAT_FOR_REFUND = $9033; // Не достаточно средств для возврата (НДС)
  WP_ERROR_OPEN_ZREPORT_TIME_PAST = $9034; // Время открытия Z- report старое
  WP_ERROR_MAINTENANCE_REQUIRED = $9035; // Требуется обслуживание со стороны ОФД


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
  public
    procedure Clear;
    procedure Assign(Source: TPersistent); override;
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
    procedure Assign(Source: TPersistent); override;
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
    procedure Assign(Source: TPersistent); override;
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
  public
    procedure Assign(Source: TPersistent); override;
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
  public
    procedure Assign(Source: TPersistent); override;
  published
    property inn: WideString read Finn write Finn;
    property pinfl: WideString read Fpinfl write Fpinfl;
  end;

  { TWPTime }

  TWPTime = class(TJsonPersistent)
  private
    FTime: WideString;
    FVersion: WideString;
  public
    procedure Assign(Source: TPersistent); override;
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
    procedure Assign(Source: TPersistent); override;
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
    Famount: Int64;
    Funits: Integer;
    Funit_name: WideString;
    Fprice: Int64;
    Fproduct_price: Int64;
    Fvat: Int64;
    Fvat_percent: Integer;
    Fdiscount: Int64;
    Fdiscount_percent: Integer;
    Fother: Int64;
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
    procedure Assign(Source: TPersistent); override;
  published
    property name: WideString read Fname write Fname;
    property barcode: WideString read Fbarcode write Fbarcode;
    property amount: Int64 read Famount write Famount;
    property units: Integer read Funits write Funits;
    property unit_name: WideString read Funit_name write Funit_name;
    property price: Int64 read Fprice write Fprice;
    property product_price: Int64 read Fproduct_price write Fproduct_price;
    property vat: Int64 read Fvat write Fvat;
    property vat_percent: Integer read Fvat_percent write Fvat_percent;
    property discount: Int64 read Fdiscount write Fdiscount;
    property discount_percent: Integer read Fdiscount_percent write Fdiscount_percent;
    property other: Int64 read Fother write Fother;
    property labels: TStrings read Flabels write Setlabels;
    property class_code: WideString read Fclass_code write Fclass_code;
    property package_code: Integer read Fpackage_code write Fpackage_code;
    property owner_type: Integer read Fowner_type write Fowner_type;
    property comission_info: TWPComissionInfo read Fcomission_info write Setcomission_info;
  end;

(*
| Name               | Type   | Description EN/RU                                                              | Example                                     |
| ------------------ | -------| ------------------------------------------------------------------------------ | ------------------------------------------- |
| number             | Integer| Forder number/Номер чека                                                       | 1                                           |
| receipt_type       | String | Receipt type/Вид продажи (продажа,аванс,кредит)                                | order,prepaid,credit                        |
|                    |        | Примечание: На авансовые и кредитные чеки QR код и фиск.признак не печатается  |                                             |
| name               | String | Product name/Наименование товара или услуги                                    | Хлеб                                        |
| barcode            | Long   | Product barcode/Штрих-код (GTIN) товара                                        | EAN-8 47800007, EAN-13 4780000000007        |
| amount             | Long   | Product amount/Количество                                                      | 1 шт. = 1000; 0,25 кг = 250                 |
| unit_name          | String | Unit name/Едииница измереня для отображаения на чеке на лат. UZ                | dona                                        |
| units              | Integr | Unit/Единица измерения                                                         | "1" - это шт. Подробности см ниже           |
| price              | Long   | Price/Сумма                                                                    | 50 тийин = 50, 1 сум = 100, 100 сум = 10000 |
| product_price      | Long   | Product price/Цена за единицу товара/услуги                                    | 50 тийин = 50, 1 сум = 100, 100 сум = 10000 |
| vat                | Long   | Nds price/Сумма НДС                                                            | 50 тийин = 50, 1 сум = 100, 100 сум = 10000 |
| vat_percent        | Integer| Nds percent/Процент НДС                                                        | 0 = 0%, 12 = 12%                            |
| discount           | Long   | Discount price/Цена cкидки                                                     | 50 тийин = 50, 1 сум = 100, 100 сум = 10000 |
| discount_percent   | Integr | Discount price percent/Процент скидки                                          | 0 = 0%, 10 = 10%, 15 = 15%, 20 = 20%        |
| other              | Long   | Other discount prices/Другая скидка                                            | 50 тийин = 50, 1 сум = 100, 100 сум = 10000 |
| labels             | String | Marking codes list/Код маркировки (значеник кода DataMatrix). К примеру если   | 05367567230048c?eN1(o0029                   |
|                    |        | кол-во товаров с маркир. будет 5 шт, то в amount указываем 1 шт                |                                             |
| class_code         | Long   | Product class code/Код ИКПУ (МХИК) (tasnif.soliq.uz)                           | 10999001001000000                           |
| package_code       | Long   | Package_code/ Код упаковки (tasnif.soliq.uz)                                   | 1520627                                     |
| owner_type         | Integer| Owner_type/ Код происхождения товара (одно значение либо 0, либо 1, либо 2     | 0,1,2                                       |
|                    |        | (0-"Куплено и продано" / 1-"Собственное производство" / 2-"Поставщик услуг")   |                                             |
| comission_info     | Long   | Sign commission check TIN, PINFL/Признак комиссионный чек ИНН, ПИНФЛ           | 123456789, 12345678912345                   |
| time               | Double | Time in format yyyy-MM-dd hh:mm:ss/Дата и время в формате yyyy-MM-dd hh:mm:ss  | 2021-09-08 22:54:59                         |
| cashier            | String | Cashier name/Имя кассира                                                       | Админ                                       |
| received_cash      | Long   | Received cash price/Оплата наличными                                           | 50 тийин = 50, 1 сум = 100, 100 сум = 10000 |
| change             | Long   | Change price/Сдача                                                             | 100                                         |
| received_card      | Long   | Received cash price/Оплата банковской картой,Payme,Click,UZUM                  | 50 тийин = 50, 1 сум = 100, 100 сум = 10000 |
| open_cashbox       | String | Open cashbox device/Открытие денежнего ящика                                   | true = open, falce = not open               |
| type               | String | Banner type - {text, barcode, qr_code}/Штрих-код, QR-код                       | barcode                                     |
| data               | String | Banner text/Рекламный текст                                                    | Скидка на следующую покупку 5%              |
| prices / name      | String | Price name/Наименование вида оплаты                                            | USD, VISA, MasterCard, Click, Payme, Uzum   |
| prices / price     | Long   | Price/Сумма                                                                    | 50 тийин = 50, 1 сум = 100, 100 сум = 10000 |
| prices / vat_type  | Long   | Vat type/Название налога и ставка                                              | НДС 15%                                     |
| prices / vat_price | Long   | Vat price/Сумма налога                                                         | 50 тийин = 50, 1 сум = 100, 100 сум = 10000 |

*)


  { TWPProducts }

  TWPProducts = class(TJsonCollection)
  protected
    function GetItem(Index: Integer): TWPProduct;
  public
    property Items[Index: Integer]: TWPProduct read GetItem; default;
  end;

  { TWPBannerStyle }

  TWPBannerStyle = class(TJsonPersistent)
  private
    Fis_bold: Boolean;
    Ffont_height: Integer;
    Ffont_width: Integer;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property font_width: Integer read Ffont_width write Ffont_width;
    property font_height: Integer read Ffont_height write Ffont_height;
    property is_bold: Boolean read Fis_bold write Fis_bold;
  end;

  { TWPBanner }

  TWPBanner = class(TJsonCollectionItem)
  private
    F_type: WideString;
    Fdata: WideString;
    Fcut: Boolean;
    Fstyle: TWPBannerStyle;
    procedure Setstyle(const Value: TWPBannerStyle);
  public
    constructor Create(Collection: TJsonCollection); override;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
    function IsRequiredField(const Field: WideString): Boolean; override;
  published
    property _type: WideString read F_type write F_type;
    property data: WideString read Fdata write Fdata;
    property cut: Boolean read Fcut write Fcut default false;
    property style: TWPBannerStyle read Fstyle write Setstyle;
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
  public
    procedure Assign(Source: TPersistent); override;
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
	  Freceived_cash: Int64;
	  Fchange: Int64;
	  Freceived_card: Integer;
    Fcard_type: Integer; // card type personal (0) or corporate (1)
    Fppt_id: Int64; // RRN number (ppt_id) in the slip response from the bank pinpad (Humo, Uzcard)
	  Fopen_cashbox: Boolean;
	  Fsend_email: Boolean;
	  Femail: WideString;
	  Fsms_phone_number: WideString;
	  Fbanners: TWPBanners;
	  Fprices: TWPPrices;
    Fqr_code: WideString;

    procedure SetBanners(const Value: TWPBanners);
    procedure SetPrices(const Value: TWPPrices);
    procedure SetProducts(const Value: TWPProducts);
    function IsOptionalField(const Field: WideString): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function IsRequiredField(const Field: WideString): Boolean; override;
  published
    property qr_code: WideString read Fqr_code write Fqr_code;
	  property number: Integer read Fnumber write Fnumber;
	  property receipt_type: WideString read Freceipt_type write Freceipt_type;
	  property products: TWPProducts read Fproducts write SetProducts;
	  property time: WideString read FTime write FTime;
	  property cashier: WideString read Fcashier write Fcashier;
	  property received_cash: Int64 read Freceived_cash write Freceived_cash;
	  property change: Int64 read Fchange write Fchange;
	  property received_card: Integer read Freceived_card write Freceived_card;
    property card_type: Integer read Fcard_type write Fcard_type;
    property ppt_id: Int64 read Fppt_id write Fppt_id;
	  property open_cashbox: Boolean read Fopen_cashbox write Fopen_cashbox;
	  property send_email: Boolean read Fsend_email write Fsend_email;
	  property email: WideString read Femail write Femail;
	  property banners: TWPBanners read Fbanners write SetBanners;
	  property prices: TWPPrices read Fprices write SetPrices;
	  property sms_phone_number: WideString read Fsms_phone_number write Fsms_phone_number;
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
  public
    procedure Assign(Source: TPersistent); override;
  published
    property terminal_id: WideString read FTerminalID write FTerminalID;
    property receipt_count: Integer read FReceiptCount write FReceiptCount;
    property date_time: WideString read FDateTime write FDateTime;
    property fiscal_sign: WideString read FFiscalSign write FFiscalSign;
    property applet_version: WideString read FAppletVersion write FAppletVersion;
    property qr_url: WideString read FQRURL write FQRURL;
    property cash_box_number: WideString read FCashBoxNumber write FCashBoxNumber;
  end;

  { TWPCommand }

  TWPCommand = class(TJsonPersistent)
  private
    FRequestJson: WideString;
    FResponseJson: WideString;
  public
    property RequestJson: WideString read FRequestJson write FRequestJson;
    property ResponseJson: WideString read FResponseJson write FResponseJson;
  end;

  { TWPRequest }

  TWPRequest = class(TJsonCollectionItem)
  private
    FURL: WideString;
    FRequest: WideString;
    FResponse: WideString;
    FIsGetRequest: Boolean;
  public
    property URL: WideString read FURL;
    property Request: WideString read FRequest;
    property Response: WideString read FResponse;
    property IsGetRequest: Boolean read FIsGetRequest;
  end;

  { TWPRequests }

  TWPRequests = class(TJsonCollection)
  protected
    function GetItem(Index: Integer): TWPRequest;
  public
    property Items[Index: Integer]: TWPRequest read GetItem; default;
  end;

  { TWPCreateOrderResponse }

  TWPCreateOrderResponse = class(TWPCommand)
  private
    Fdata: TWPCreateOrderResult;
    Ferror: TWPError;
    Fis_success: Boolean;
    procedure SetData(const Value: TWPCreateOrderResult);
    procedure SetError(const Value: TWPError);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
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
    procedure Assign(Source: TPersistent); override;
  published
    property Error: TWPError read FError write SetError;
    property Data: TWPInfoResponse read FData write SetData;
  end;

  { TWPCurrency  }

  TWPCurrency = class(TJsonCollectionItem)
  private
    FPrice: Int64;
    FName: WideString;
  public
    procedure Assign(Source: TPersistent); override;
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
    procedure Assign(Source: TPersistent); override;
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
  public
    procedure Assign(Source: TPersistent); override;
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
    procedure Assign(Source: TPersistent); override;
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
    procedure Assign(Source: TPersistent); override;
  published
    property result: TWPCloseDayResponse read Fresult write SetResult;
  end;

  { TWPPaymentRequest }

  TWPPaymentRequest = class(TJsonPersistent)
  private
    FAmount: Int64;
    FQRCode: WideString;
  public
    procedure Assign(Source: TPersistent); override;
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
  public
    procedure Assign(Source: TPersistent); override;
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
    procedure Assign(Source: TPersistent); override;
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
  public
    procedure Assign(Source: TPersistent); override;
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
  public
    procedure Assign(Source: TPersistent); override;
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
    procedure Assign(Source: TPersistent); override;
  published
    property error: TWPError read FError write SetError;
    property is_success: Boolean read FSuccess write FSuccess;
    property data: TWPPaymentConfirmResult read FData write SetData;
  end;

  { TWPText }

  TWPText = class(TJsonPersistent)
  private
    Fbanners: TWPBanners;
    procedure SetBanners(const Value: TWPBanners);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published
	  property banners: TWPBanners read Fbanners write SetBanners;
  end;

  { TWebPrinter }

  TWebPrinter = class
  private
    FLogger: ILogFile;
    FTestMode: Boolean;
    FDayOpened: Boolean;
    FTimeDiff: TDateTime;
    FAddress: WideString;
    FDayOpenTime: TDateTime;
    FConnectTimeout: Integer;

    FRaiseErrors: Boolean;
    FTransport: TIdHTTP;
    FRequestJson: WideString;
    FResponseJson: WideString;
    FInfo: TWPInfoCommand;
    FResponse: TWPResponse;
    FOpenDayResponse: TWPOpenDayResponse;
    FCloseDayResponse: TWPCloseDayResponse;
    FCloseDayResponse2: TWPCloseDayResponse2;
    FPaymentResponse: TWPPaymentResponse;
    FPaymentConfirmResponse: TWPPaymentConfirmResponse;
    FCreateOrderResponse: TWPCreateOrderResponse;
    FPrintLastReceipt: TWPResult;
    FDeviceDescription: WideString;
    FRequests: TWPRequests;

    function GetTransport: TIdHTTP;
    function GetAddress: WideString;
    function SendJson(const AURL, Request: WideString;
      IsGetRequest: Boolean): WideString;
    procedure AddRequest(URL, Request, Response: WideString;
      IsGetRequest: Boolean);
  public
    constructor Create(ALogger: ILogFile);
    destructor Destroy; override;

    procedure Clear;
    procedure Connect;
    procedure Disconnect;
    procedure OpenFiscalDay3;
    procedure CheckForError(const Error: TWPError);

    function GetPrinterDate: TDateTime;
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
    function PrintText(const Text: TWPText): TWPResponse;
    function GetJson(const AURL: WideString): WideString;
    function PostJson(const AURL, Request: WideString): WideString;

    property Info: TWPInfoCommand read FInfo;
    property Transport: TIdHTTP read GetTransport;
    property TestMode: Boolean read FTestMode write FTestMode;
    property Address: WideString read FAddress write FAddress;
    property TimeDiff: TDateTime read FTimeDiff write FTimeDiff;
    property DayOpened: Boolean read FDayOpened write FDayOpened;
    property DeviceDescription: WideString read FDeviceDescription;
    property RaiseErrors: Boolean read FRaiseErrors write FRaiseErrors;
    property RequestJson: WideString read FRequestJson write FRequestJson;
    property ResponseJson: WideString read FResponseJson write FResponseJson;
    property OpenDayResponse: TWPOpenDayResponse read FOpenDayResponse;
    property CloseDayResponse: TWPCloseDayResponse read FCloseDayResponse;
    property CloseDayResponse2: TWPCloseDayResponse2 read FCloseDayResponse2;
    property ConnectTimeout: Integer read FConnectTimeout write FConnectTimeout;
    property CreateOrderResponse: TWPCreateOrderResponse read FCreateOrderResponse;
    property Requests: TWPRequests read FRequests;
  end;

function WPDateTimeToStr(Time: TDateTime): string;
function WPStrToDateTime(const S: string): TDateTime;

implementation

function WPDateTimeToStr(Time: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', Time);
end;

function WPStrToDateTime(const S: string): TDateTime;
var
  Year, Month, Day: Word;
  Hour, Min, Sec: Word;
begin
  if Length(S) < 19 then
    raise Exception.Create('Invalid date format');

  try
    Year := StrToInt(Copy(S, 1, 4));
    Month := StrToInt(Copy(S, 6, 2));
    Day := StrToInt(Copy(S, 9, 2));
    Hour := StrToInt(Copy(S, 12, 2));
    Min := StrToInt(Copy(S, 15, 2));
    Sec := StrToInt(Copy(S, 18, 2));
    Result := EncodeDate(Year, Month, Day) + EncodeTime(Hour, Min, Sec, 0);
  except
    raise Exception.Create('Invalid date format');
  end;
end;

{ TWPResult }

procedure TWPResult.Assign(Source: TPersistent);
var
  src: TWPResult;
begin
  if source is TWPResult then
  begin
    src := source as TWPResult;
    result := src.result;
  end;
end;

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

procedure TWPInfoCommand.Assign(Source: TPersistent);
var
  src: TWPInfoCommand;
begin
  if source is TWPInfoCommand then
  begin
    src := source as TWPInfoCommand;

    Error := src.Error;
    Data := src.Data;
  end;
end;


{ TWPOrder }

procedure TWPOrder.Assign(Source: TPersistent);
var
  src: TWPOrder;
begin
  if source is TWPOrder then
  begin
    src := source as TWPOrder;

    qr_code := src.qr_code;
	  number := src.number;
	  receipt_type := src.receipt_type;
	  products := src.products;
	  time := src.time;
	  cashier := src.cashier;
	  received_cash := src.received_cash;
	  change := src.change;
	  received_card := src.received_card;
	  open_cashbox := src.open_cashbox;
	  send_email := src.send_email;
	  email := src.email;
	  banners := src.banners;
	  prices := src.prices;
	  sms_phone_number := src.sms_phone_number;
  end;
end;

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

function TWPOrder.IsOptionalField(const Field: WideString): Boolean;
var
  i: Integer;
const
  OptionalFields: array [0..6] of string = (
    'extra_info', 'send_email',
    'email', 'sms_phone_number',
    'open_cashbox', 'banners',
    'prices');
begin
  for i := Low(OptionalFields) to High(OptionalFields) do
  begin
    Result := AnsiCompareText(Field, OptionalFields[i]) = 0;
    if Result then Break;
  end;
end;

function TWPOrder.IsRequiredField(const Field: WideString): Boolean;
begin
  Result := not IsOptionalField(Field);
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

procedure TWPProduct.Assign(Source: TPersistent);
var
  Src: TWPProduct;
begin
  if Source is TWPProduct then
  begin
    Src := Source as TWPProduct;

    name := Src.name;
    barcode := Src.barcode;
    amount := Src.amount;
    units := Src.units;
    unit_name := Src.unit_name;
    price := Src.price;
    product_price := Src.product_price;
    vat := Src.vat;
    vat_percent := Src.vat_percent;
    discount := Src.discount;
    discount_percent := Src.discount_percent;
    other := Src.other;
    labels := Src.labels;
    class_code := Src.class_code;
    package_code := Src.package_code;
    owner_type := Src.owner_type;
    comission_info := Src.comission_info;
  end;
end;

procedure TWPProduct.Setcomission_info(const Value: TWPComissionInfo);
begin
  Fcomission_info.Assign(Value);
end;

procedure TWPProduct.Setlabels(const Value: TStrings);
begin
  Flabels.Assign(Value);
end;

{ TWPRequests }

function TWPRequests.GetItem(Index: Integer): TWPRequest;
begin
  Result := inherited Items[Index] as TWPRequest;
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

procedure TWPOpenDayResponse.Assign(Source: TPersistent);
var
  src: TWPOpenDayResponse;
begin
  if source is TWPOpenDayResponse then
  begin
    src := source as TWPOpenDayResponse;

    data := src.data;
    error := src.error;
    is_success := src.is_success;
  end;
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

procedure TWPCloseDayResponse2.Assign(Source: TPersistent);
begin
  if source is TWPCloseDayResponse2 then
  begin
    result := (source as TWPCloseDayResponse2).result;
  end;
end;

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

procedure TWPCloseDayRequest.Assign(Source: TPersistent);
var
  src: TWPCloseDayRequest;
begin
  if source is TWPCloseDayRequest then
  begin
    src := source as TWPCloseDayRequest;
    name := src.name;
    prices := src.prices;
    close_zreport := src.close_zreport;
  end;
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

procedure TWPCloseDayResponse.Assign(Source: TPersistent);
var
  src: TWPCloseDayResponse;
begin
  if source is TWPCloseDayResponse then
  begin
    src := source as TWPCloseDayResponse;

    data := src.data;
    error := src.error;
    is_success := src.is_success;
  end;
end;

{ TWPResponse }

procedure TWPResponse.Assign(Source: TPersistent);
var
  src: TWPResponse;
begin
  if Source is TWPResponse then
  begin
    src := Source as TWPResponse;

    error := src.error;
    is_success := src.is_success;
  end;
end;

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

procedure TWPPaymentResponse.Assign(Source: TPersistent);
var
  src: TWPPaymentResponse;
begin
  if source is TWPPaymentResponse then
  begin
    src := source as TWPPaymentResponse;

    error := src.error;
    data := src.data;
    is_success := src.is_success;
  end;
end;

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

procedure TWPPaymentConfirmResponse.Assign(Source: TPersistent);
var
  src: TWPPaymentConfirmResponse;
begin
  if source is TWPPaymentConfirmResponse then
  begin
    src := source as TWPPaymentConfirmResponse;

    error := src.error;
    is_success := src.is_success;
    data := src.data;
  end;
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

procedure TWPCreateOrderResponse.Assign(Source: TPersistent);
var
  src: TWPCreateOrderResponse;
begin
  if source is TWPCreateOrderResponse then
  begin
    src := source as TWPCreateOrderResponse;

    data := src.data;
    error := src.error;
    is_success := src.is_success;
  end;
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

{ TWPError }

procedure TWPError.Assign(Source: TPersistent);
var
  src: TWPError;
begin
  if source is TWPError then
  begin
    src := source as TWPError;

    code := src.code;
    data := src.data;
    message := src.message;
  end;
end;

procedure TWPError.Clear;
begin
  FCode := 0;
  FData := '';
  FMessage := '';
end;

{ TWPBanner }

constructor TWPBanner.Create(Collection: TJsonCollection);
begin
  inherited Create(Collection);
  //Fstyle := TWPBannerStyle.Create;
end;

destructor TWPBanner.Destroy;
begin
  Fstyle.Free;
  inherited Destroy;
end;

procedure TWPBanner.Assign(Source: TPersistent);
var
  src: TWPBanner;
begin
  if Source is TWPBanner then
  begin
    src := Source as TWPBanner;
    _type := src._type;
    data := src.data;
    cut := src.cut;
    style := src.style;
  end;
end;

function TWPBanner.IsRequiredField(const Field: WideString): Boolean;
var
  i: Integer;
const
  OptionalFields: array [0..1] of string = (
    'type', 'data');
begin
  for i := Low(OptionalFields) to High(OptionalFields) do
  begin
    Result := AnsiCompareText(Field, OptionalFields[i]) = 0;
    if Result then Break;
  end;
end;

procedure TWPBanner.Setstyle(const Value: TWPBannerStyle);
begin
  if Fstyle <> nil then
    Fstyle.Assign(Value);
end;

{ TWPPrice }

procedure TWPPrice.Assign(Source: TPersistent);
var
  src: TWPPrice;
begin
  if Source is TWPPrice then
  begin
    src := Source as TWPPrice;
    name := src.name;
    price := src.price;
    vat_type := src.vat_type;
    vat_price := src.vat_price;
  end;
end;

{ TWPCurrency }

procedure TWPCurrency.Assign(Source: TPersistent);
var
  src: TWPCurrency;
begin
  if Source is TWPCurrency then
  begin
    src := Source as TWPCurrency;

    name := src.name;
    price := src.price;
  end;
end;

{ TWPInfoResponse }

procedure TWPInfoResponse.Assign(Source: TPersistent);
var
  src: TWPInfoResponse;
begin
  if source is TWPInfoResponse then
  begin
    src := source as TWPInfoResponse;

    terminal_id := src.terminal_id;
    applet_version := src.applet_version;
    current_receipt_seq := src.current_receipt_seq;
    current_time := src.current_time;
    last_operation_time := src.last_operation_time;
    receipt_count := src.receipt_count;
    receipt_max_count := src.receipt_max_count;
    zreport_count := src.zreport_count;
    zreport_max_count := src.zreport_max_count;
    available_persistent_memory := src.available_persistent_memory;
    available_reset_memory := src.available_reset_memory;
    available_deselect_memory := src.available_deselect_memory;
    cashbox_number := src.cashbox_number;
    version_code := src.version_code;
    is_updated := src.is_updated;
  end;
end;

{ TWPComissionInfo }

procedure TWPComissionInfo.Assign(Source: TPersistent);
var
  src: TWPComissionInfo;
begin
  if source is TWPComissionInfo then
  begin
    src := source as TWPComissionInfo;

    inn := src.inn;
    pinfl := src.pinfl;
  end;
end;

{ TWPTime }

procedure TWPTime.Assign(Source: TPersistent);
var
  Src: TWPTime;
begin
  if Source is TWPTime then
  begin
    src := Source as TWPTime;

    time := src.time;
    applet_version := src.applet_version;
  end;
end;

{ TWPCreateOrderResult }

procedure TWPCreateOrderResult.Assign(Source: TPersistent);
var
  src: TWPCreateOrderResult;
begin
  if Source is TWPCreateOrderResult then
  begin
    src := source as TWPCreateOrderResult;

    terminal_id := src.terminal_id;
    receipt_count := src.receipt_count;
    date_time := src.date_time;
    fiscal_sign := src.fiscal_sign;
    applet_version := src.applet_version;
    qr_url := src.qr_url;
    cash_box_number := src.cash_box_number;
  end;
end;

{ TWPDayResult }

procedure TWPDayResult.Assign(Source: TPersistent);
var
  Src: TWPDayResult;
begin
  if source is TWPDayResult then
  begin
    src := source as TWPDayResult;

    applet_version := src.applet_version;
    terminal_id := src.terminal_id;
    number := src.number;
    count := src.count;
    last_receipt_seq := src.last_receipt_seq;
    first_receipt_seq := src.first_receipt_seq;
    open_time := src.open_time;
    close_time := src.close_time;
    total_refund_vat := src.total_refund_vat;
    total_refund_card := src.total_refund_card;
    total_refund_cash := src.total_refund_cash;
    total_refund_count := src.total_refund_count;
    total_sale_vat := src.total_sale_vat;
    total_sale_card := src.total_sale_card;
    total_sale_cash := src.total_sale_cash;
    total_sale_count := src.total_sale_count;
  end;
end;

{ TWPPaymentRequest }

procedure TWPPaymentRequest.Assign(Source: TPersistent);
var
  src: TWPPaymentRequest;
begin
  if source is TWPPaymentRequest then
  begin
    src := source as TWPPaymentRequest;

    amount := src.amount;
    qr_code := src.qr_code;
  end;
end;

{ TWPPaymentResult }

procedure TWPPaymentResult.Assign(Source: TPersistent);
var
  src: TWPPaymentResult;
begin
  if source is TWPPaymentResult then
  begin
    src := source as TWPPaymentResult;

    amount := src.amount;
    transaction_id := src.transaction_id;
    payment_id := src.payment_id;
    inn := src.inn;
    qr_code := src.qr_code;
    kkm_id := src.kkm_id;
    device_id := src.device_id;
    status := src.status;
    message := src.message;
    client_phone_number := src.client_phone_number;
  end;
end;

{ TWPPaymentConfirmRequest }

procedure TWPPaymentConfirmRequest.Assign(Source: TPersistent);
var
  src: TWPPaymentConfirmRequest;
begin
  if source is TWPPaymentConfirmRequest then
  begin
    src := source as TWPPaymentConfirmRequest;

    qr_code := src.qr_code;
    payment_id := src.payment_id;
  end;
end;

{ TWPPaymentConfirmResult }

procedure TWPPaymentConfirmResult.Assign(Source: TPersistent);
var
  src: TWPPaymentConfirmResult;
begin
  if source is TWPPaymentConfirmResult then
  begin
    src := source as TWPPaymentConfirmResult;
    inn := src.inn;
    payment_id := src.payment_id;
    qr_code := src.qr_code;
    status := src.status;
  end;
end;

{ TWPText }

constructor TWPText.Create;
begin
  inherited Create;
  FBanners := TWPBanners.Create(TWPBanner);
end;

destructor TWPText.Destroy;
begin
  FBanners.Free;
  inherited Destroy;
end;

procedure TWPText.SetBanners(const Value: TWPBanners);
begin
  banners.Assign(Value);
end;

procedure TWPText.Assign(Source: TPersistent);
begin
  if Source is TWPText then
  begin
    Banners := (Source as TWPText).Banners;
  end;
end;

{ TWebPrinter }

constructor TWebPrinter.Create(ALogger: ILogFile);
begin
  inherited Create;
  FLogger := ALogger;
  FAddress := 'https://devkkm.webkassa.kz/';
  FRaiseErrors := True;

  FInfo := TWPInfoCommand.Create;
  FOpenDayResponse := TWPOpenDayResponse.Create;
  FCloseDayResponse := TWPCloseDayResponse.Create;
  FCloseDayResponse2 := TWPCloseDayResponse2.Create;
  FResponse := TWPResponse.Create;
  FPaymentResponse := TWPPaymentResponse.Create;
  FPaymentConfirmResponse := TWPPaymentConfirmResponse.Create;
  FCreateOrderResponse := TWPCreateOrderResponse.Create;
  FPrintLastReceipt := TWPResult.Create;
  FRequests := TWPRequests.Create(TWPRequest);
end;

destructor TWebPrinter.Destroy;
begin
  FLogger := nil;
  FInfo.Free;
  FRequests.Free;
  FResponse.Free;
  FTransport.Free;
  FOpenDayResponse.Free;
  FCloseDayResponse.Free;
  FCloseDayResponse2.Free;
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
    FTransport.ConnectTimeout := FConnectTimeout * 1000;
  end;
  Result := FTransport;
end;

function IsJson(const JsonText: WideString): Boolean;
var
  Json: TlkJSON;
begin
  Json := TlkJSON.Create;
  try
    Result := Json.ParseText(JsonText) <> nil;
  finally
    Json.Free;
  end;
end;

procedure TWebPrinter.Clear;
begin
  FInfo.Error.Clear;
  FResponse.Error.Clear;
  FOpenDayResponse.error.Clear;
  FCloseDayResponse.error.Clear;
  FCloseDayResponse2.result.error.Clear;
  FPaymentResponse.error.Clear;
  FPaymentConfirmResponse.error.Clear;
  FCreateOrderResponse.error.Clear;
  FPrintLastReceipt.result.error.Clear;
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
    Result := FResponseJson;
    FLogger.Debug('<= ' + UTF8Decode(FResponseJson));
    AddRequest(AURL, Request, Result, IsGetRequest);
    Exit;
  end;

  Clear;
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
      FResponseJson := Result;
      FLogger.Debug('<= ' + UTF8Decode(Answer));
      AddRequest(AURL, Request, Answer, IsGetRequest);

      if Answer = '' then
        raise Exception.Create('Empty response received');
      if not IsJson(Answer) then
        raise Exception.Create(Answer);

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

procedure TWebPrinter.AddRequest(URL, Request, Response: WideString;
  IsGetRequest: Boolean);
const
  MaxRequestCount = 10;
var
  Item: TWPRequest;
begin
  if not TestMode then Exit;

  while Requests.Count > MaxRequestCount do
  begin
    Requests.Items[0].Free;
  end;
  Item := TWPRequest.Create(Requests);
  Item.FURL := URL;
  Item.FRequest := Request;
  Item.FResponse := Response;
  Item.FIsGetRequest := IsGetRequest;
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
  if Error.code <> 0 then
  begin
    FLogger.Error(WideFormat('%d, %s', [Error.Code, Error.message]));
  end;

  if FRaiseErrors and (Error.code <> 0) then
  begin
    RaiseError(Error.code, Error.message);
  end;
end;

procedure TWebPrinter.Connect;
begin
  ReadZReport;
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
  PrinterTime: TDateTime;
begin
  JsonText := ReadInfo;
  JsonToObject(JsonText, FInfo);
  CheckForError(FInfo.Error);
  if Info.Data.current_time <> '' then
  begin
    PrinterTime := WPStrToDateTime(Info.Data.current_time);
    FTimeDiff := PrinterTime - Now;
  end;
  FDeviceDescription := Format(' terminal_id: %s, applet_version: %s, version_code: %s',
    [Info.Data.terminal_id, Info.Data.applet_version, Info.Data.version_code]);

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
  ResponseJson: WideString;
begin
  ResponseJson := OpenFiscalDay(Time);
  JsonToObject(ResponseJson, FOpenDayResponse);
  if FOpenDayResponse.error.code = WP_ERROR_ZREPORT_IS_ALREADY_OPEN then
  begin
    FLogger.Error(WideFormat('%d, %s', [FOpenDayResponse.Error.Code, FOpenDayResponse.Error.message]));
    FOpenDayResponse.Error.Clear;
  end;
  CheckForError(FOpenDayResponse.Error);
  FDayOpened := True;
  FDayOpenTime := Time;
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
  OpenFiscalDay3;
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
  OpenFiscalDay3;

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
  if FCloseDayResponse2.result.error.code = 0 then
  begin
    FDayOpened := FCloseDayResponse2.result.data.open_time <> '';
  end;
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
  i: Integer;
  RequestJson: WideString;
  ResponseJson: WideString;
begin
  OpenFiscalDay3;

  for i := 1 to 2 do
  begin
    Request.Time := WPDateTimeToStr(GetPrinterDate);
    RequestJson := ObjectToJson(Request);
    FCreateOrderResponse.RequestJson := RequestJson;
    ResponseJson := PostJson(GetAddress + '/order/create/', RequestJson);
    FCreateOrderResponse.ResponseJson := ResponseJson;
    JsonToObject(ResponseJson, FCreateOrderResponse);
    if FCreateOrderResponse.error.code = WP_ERROR_ZREPORT_IS_NOT_OPEN then
    begin
      FDayOpened := False;
      if OpenFiscalDay2(GetPrinterDate).error.code <> 0 then Break;
    end else
    begin
      Break;
    end;
  end;
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
  i: Integer;
  RequestJson: WideString;
  responseJson: WideString;
begin
  FLogger.Debug('TWebPrinter.ReturnOrder.0');

  OpenFiscalDay3;
  for i := 1 to 2 do
  begin
    Request.Time := WPDateTimeToStr(GetPrinterDate);
    RequestJson := ObjectToJson(Request);
    FCreateOrderResponse.RequestJson := RequestJson;
    ResponseJson := PostJson(GetAddress + '/order/refuse/', RequestJson);
    FCreateOrderResponse.ResponseJson := ResponseJson;
    JsonToObject(ResponseJson, FCreateOrderResponse);
    if FCreateOrderResponse.error.code = WP_ERROR_ZREPORT_IS_NOT_OPEN then
    begin
      OpenFiscalDay2(GetPrinterDate);
    end else
    begin
      Break;
    end;
  end;
  FLogger.Debug('TWebPrinter.ReturnOrder.1');
  CheckForError(FCreateOrderResponse.error);
  Result := FCreateOrderResponse;
end;

procedure TWebPrinter.OpenFiscalDay3;
begin
  if not FDayOpened then
  begin
    if OpenFiscalDay2(GetPrinterDate).error.code <> 0 then Exit;
    FDayOpened := True;
  end;
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

(*
http://fbox.ngrok.io/print/banner POST
{"banners":
[
  {
  "type":"text",
  "data": "Safe Drop Receipt                         \r\n\r\n==========================================\r\nEmploee ID....:                     199192\r\nDate..........:                 12/01/2021\r\nStore ID......:                       UZ11\r\nTime..........:                      20:40\r\nPos ID........:                  UZ11POS04\r\n\r\n------------------------------------------\r\n\r\n       100.00 * 20          2,000.00 UZS  \r\n     1,000.00 * 13         13,000.00 UZS  \r\n     5,000.00 * 25        125,000.00 UZS  \r\n    10,000.00 * 11        100,000.00 UZS  \r\n\r\n             Total:       250,000.00 UZS  \r\n\r\n==========================================\r\n\r\nTotal Local Amount:       250,000.00 UZS  \r\n\r\n==========================================\r\n\r\nCashier                 Store Mamager     \r\nName Surname:           Name Surname:     \r\n\r\n\r\n\r\nSignature:              Signature:        \r\n\r\n\r\n\r\n========================================== "
  }
]}
{ "type": "text", "data": "R12020000000002544", "cut": true}
*)

function TWebPrinter.PrintText(const Text: TWPText): TWPResponse;
var
  JsonText: WideString;
begin
  JsonText := ObjectToJson(Text);
  JsonText := PostJson(GetAddress + '/print/banner/', JsonText);
  JsonToObject(JsonText, FResponse);
  CheckForError(FResponse.error);
  Result := FResponse;
end;

function TWebPrinter.GetPrinterDate: TDateTime;
begin
  Result := Now + FTimeDiff;
  //FLogger.Debug('GetPrinterDate: ' + WPDateTimeToStr(Result));
end;

{ TWPBannerStyle }

procedure TWPBannerStyle.Assign(Source: TPersistent);
var
  src: TWPBannerStyle;
begin
  if source is TWPBannerStyle then
  begin
    src := source as TWPBannerStyle;
    Fis_bold := src.is_bold;
    Ffont_height := src.font_height;
    Ffont_width := src.font_width;
  end;
end;

end.

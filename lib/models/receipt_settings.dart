/// Model for receipt customization settings.
///
/// These settings control how receipts appear when printed or displayed.
/// Persisted via SharedPreferences (handled by provider).
class ReceiptSettings {
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String headerText;
  final String footerText;
  final double fontSize; // 0.5 to 2.0
  final bool showLogo;
  final bool showItemBarcode;
  final bool showCashierName;
  final bool showTaxInfo;
  final String paperSize; // '58mm' or '80mm'

  const ReceiptSettings({
    this.storeName = 'TOKO KAMI',
    this.storeAddress = 'Jl. Contoh No. 123',
    this.storePhone = '021-12345678',
    this.headerText = 'Terima Kasih telah berbelanja',
    this.footerText = 'Barang yang sudah dibeli tidak dapat dikembalikan',
    this.fontSize = 1.0,
    this.showLogo = true,
    this.showItemBarcode = false,
    this.showCashierName = true,
    this.showTaxInfo = true,
    this.paperSize = '58mm',
  });

  Map<String, dynamic> toJson() => {
        'storeName': storeName,
        'storeAddress': storeAddress,
        'storePhone': storePhone,
        'headerText': headerText,
        'footerText': footerText,
        'fontSize': fontSize,
        'showLogo': showLogo,
        'showItemBarcode': showItemBarcode,
        'showCashierName': showCashierName,
        'showTaxInfo': showTaxInfo,
        'paperSize': paperSize,
      };

  factory ReceiptSettings.fromJson(Map<String, dynamic> json) =>
      ReceiptSettings(
        storeName: json['storeName'] as String? ?? 'TOKO KAMI',
        storeAddress: json['storeAddress'] as String? ?? '',
        storePhone: json['storePhone'] as String? ?? '',
        headerText: json['headerText'] as String? ?? '',
        footerText: json['footerText'] as String? ?? 'Terima Kasih',
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 1.0,
        showLogo: json['showLogo'] as bool? ?? true,
        showItemBarcode: json['showItemBarcode'] as bool? ?? false,
        showCashierName: json['showCashierName'] as bool? ?? true,
        showTaxInfo: json['showTaxInfo'] as bool? ?? true,
        paperSize: json['paperSize'] as String? ?? '58mm',
      );

  ReceiptSettings copyWith({
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? headerText,
    String? footerText,
    double? fontSize,
    bool? showLogo,
    bool? showItemBarcode,
    bool? showCashierName,
    bool? showTaxInfo,
    String? paperSize,
  }) =>
      ReceiptSettings(
        storeName: storeName ?? this.storeName,
        storeAddress: storeAddress ?? this.storeAddress,
        storePhone: storePhone ?? this.storePhone,
        headerText: headerText ?? this.headerText,
        footerText: footerText ?? this.footerText,
        fontSize: fontSize ?? this.fontSize,
        showLogo: showLogo ?? this.showLogo,
        showItemBarcode: showItemBarcode ?? this.showItemBarcode,
        showCashierName: showCashierName ?? this.showCashierName,
        showTaxInfo: showTaxInfo ?? this.showTaxInfo,
        paperSize: paperSize ?? this.paperSize,
      );
}

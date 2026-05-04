class SalesOrderLinesModel {
  final int id;
  final int customerId;
  final int salesTeamId;
  final int salesJournalId;
  final int priceListId;
  final int salesTeamUserid;
  final String salesTeamTaxIds;
  final double taxPriceAmount;
  final String applyingTaxLine;
  final int productId;
  final String productName;
  final double price;
  final double initialUnitPrice;
  final double productLineDisc;
  final double quantity;
  final String orderType;
  final int invoiceId;

  SalesOrderLinesModel({
    required this.id,
    required this.customerId,
    required this.salesTeamId,
    required this.salesJournalId,
    required this.priceListId,
    required this.salesTeamUserid,
    required this.salesTeamTaxIds,
    required this.taxPriceAmount,
    required this.applyingTaxLine,
    required this.productId,
    required this.productName,
    required this.price,
    required this.initialUnitPrice,
    required this.productLineDisc,
    required this.quantity,
    required this.orderType,
    required this.invoiceId,
  });

  SalesOrderLinesModel copyWith({
    int? id,
    int? customerId,
    int? salesTeamId,
    int? salesJournalId,
    int? priceListId,
    int? salesTeamUserid,
    String? salesTeamTaxIds,
    double? taxPriceAmount,
    String? applyingTaxLine,
    int? productId,
    String? productName,
    double? price,
    double? initialUnitPrice,
    double? productLineDisc,
    double? quantity,
    String? orderType,
    int? invoiceId,
  }) {
    return SalesOrderLinesModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      salesTeamId: salesTeamId ?? this.salesTeamId,
      salesJournalId: salesJournalId ?? this.salesJournalId,
      priceListId: priceListId ?? this.priceListId,
      salesTeamUserid: salesTeamUserid ?? this.salesTeamUserid,
      salesTeamTaxIds: salesTeamTaxIds ?? this.salesTeamTaxIds,
      taxPriceAmount: taxPriceAmount ?? this.taxPriceAmount,
      applyingTaxLine: applyingTaxLine ?? this.applyingTaxLine,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      initialUnitPrice: initialUnitPrice ?? this.initialUnitPrice,
      productLineDisc: productLineDisc ?? this.productLineDisc,
      quantity: quantity ?? this.quantity,
      orderType: orderType ?? this.orderType,
      invoiceId: invoiceId ?? this.invoiceId,
    );
  }
}

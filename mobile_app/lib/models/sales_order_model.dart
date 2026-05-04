class SalesOrderModel {
  final int id;
  final String name;
  final String dateOrder;
  final int partnerId;
  final String partnerName;
  final double amountTotal;
  final String state;

  SalesOrderModel({
    required this.id,
    required this.name,
    required this.dateOrder,
    required this.partnerId,
    required this.partnerName,
    required this.amountTotal,
    required this.state,
  });

  factory SalesOrderModel.fromJson(Map<String, dynamic> json) {
    int parsedPartnerId = 0;
    String parsedPartnerName = "Unknown Customer";

    if (json['partner_id'] is List && (json['partner_id'] as List).length > 1) {
      parsedPartnerId = (json['partner_id'][0] as num).toInt();
      parsedPartnerName = json['partner_id'][1].toString();
    } else if (json['partner_id'] is int) {
      parsedPartnerId = json['partner_id'] as int;
    }

    return SalesOrderModel(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? 'Unknown Order',
      dateOrder: json['date_order']?.toString() ?? '',
      partnerId: parsedPartnerId,
      partnerName: parsedPartnerName,
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0.0,
      state: json['state']?.toString() ?? 'draft',
    );
  }
}

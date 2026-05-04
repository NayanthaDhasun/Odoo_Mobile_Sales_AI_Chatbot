class CustomerFinancialSummaryModel {
  final int cusId;
  final double creditLimit;
  final bool partnerCreditLimit;
  final double credit;
  final double pdCheckTotal;

  CustomerFinancialSummaryModel({
    required this.cusId,
    required this.creditLimit,
    required this.partnerCreditLimit,
    required this.credit,
    required this.pdCheckTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'cusId': cusId,
      'creditLimit': creditLimit,
      'partnerCreditLimit': partnerCreditLimit,
      'credit': credit,
      'pdCheckTotal': pdCheckTotal,
    };
  }
  factory CustomerFinancialSummaryModel.fromMap(Map<String, dynamic> map) {
    return CustomerFinancialSummaryModel(
      cusId: map['cusId'] as int,
      creditLimit: (map['creditLimit'] as num).toDouble(),
      partnerCreditLimit: map['partnerCreditLimit'] as bool,
      credit: (map['credit'] as num).toDouble(),
      pdCheckTotal: (map['pdCheckTotal'] as num).toDouble(),
    );
  }
}
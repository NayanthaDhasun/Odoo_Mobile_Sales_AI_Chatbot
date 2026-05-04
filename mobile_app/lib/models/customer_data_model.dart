class CustomerDataModel {
  final int cusId;
  final int salesTeamId;
  final int journalId;
  final String name;
  final String city;
  final String reference;
  final String customer_ref;
  final double creditLimit;
  final double availableBalance;
  String orderState;
  final bool isVatCus;
  final double pdChequeReturnAmount;


  CustomerDataModel({
    required this.cusId,
    required this.salesTeamId,
    required this.journalId,
    required this.name,
    required this.city,
    required this.reference,
    required this.customer_ref,
    required this.creditLimit,
    required this.availableBalance,
    required this.orderState,
    required this.isVatCus,
    required this.pdChequeReturnAmount,
  });
}

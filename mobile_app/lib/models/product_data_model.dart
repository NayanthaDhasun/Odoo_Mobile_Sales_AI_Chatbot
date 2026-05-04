class ProductDataModel {
  final int productId;
  final String stock_quant_id;
  final String name;
  late double list_price;
  final String taxids;
  final String barcode;
  final String reference;
  late double quantity;
  final double qtyAvailable;
  String productImage;

  ProductDataModel({
    required this.productId,
    required this.stock_quant_id,
    required this.name,
    required this.list_price,
    required this.taxids,
    required this.barcode,
    required this.reference,
    required this.quantity,
    this.qtyAvailable = 0.0,
    required this.productImage,
  });
}

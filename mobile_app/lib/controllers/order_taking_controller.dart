import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_data_model.dart';
import '../models/product_data_model.dart';
import '../models/sales_order_lines_model.dart';
import '../controllers/product_controller.dart';
import '../routes/app_routes.dart';
import '../api/json_rpc_helper.dart';

class OrderTakingController extends GetxController {
  late CustomerDataModel customer;

  // Products management mapped from the ProductController
  final ProductController _productController = Get.find<ProductController>();

  // Observable ordered items
  final orderLines = <SalesOrderLinesModel>[].obs;

  // Total logic
  final orderTotal = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    // Reclaim the argument passed from the Customer View
    customer = Get.arguments as CustomerDataModel;

    // Ensure products are loaded and available for selection
    if (_productController.products.isEmpty) {
      _productController.loadProducts();
    }
  }

  void addProductLine(ProductDataModel product, double quantity) {
    if (quantity <= 0) return;

    // Check if the product is already in the order lines
    final existingIndex = orderLines.indexWhere(
      (line) => line.productId == product.productId,
    );

    if (existingIndex != -1) {
      // Update existing line
      final existing = orderLines[existingIndex];
      final newQuantity = existing.quantity + quantity;

      orderLines[existingIndex] = SalesOrderLinesModel(
        id: existing.id,
        customerId: customer.cusId,
        salesTeamId: customer.salesTeamId,
        salesJournalId: customer.journalId,
        priceListId: 1, // Fallback default
        salesTeamUserid: 1001,
        salesTeamTaxIds: 'T1',
        taxPriceAmount: (product.list_price * 0.1) * newQuantity,
        applyingTaxLine: 'Standard',
        productId: product.productId,
        productName: product.name,
        price: product.list_price * newQuantity,
        initialUnitPrice: product.list_price,
        productLineDisc: 0.0,
        quantity: newQuantity,
        orderType: 'Standard',
        invoiceId: 0,
      );
    } else {
      // Create new order line
      orderLines.add(
        SalesOrderLinesModel(
          id: DateTime.now().millisecondsSinceEpoch, // temporary ID
          customerId: customer.cusId,
          salesTeamId: customer.salesTeamId,
          salesJournalId: customer.journalId,
          priceListId: 1, // Fallback default
          salesTeamUserid: 1001,
          salesTeamTaxIds: 'T1',
          taxPriceAmount: (product.list_price * 0.1) * quantity,
          applyingTaxLine: 'Standard',
          productId: product.productId,
          productName: product.name,
          price: product.list_price * quantity,
          initialUnitPrice: product.list_price,
          productLineDisc: 0.0,
          quantity: quantity,
          orderType: 'Standard',
          invoiceId: 0,
        ),
      );
    }

    calculateTotal();
    // NOTE: Do NOT call Get.back() here.
    // The bottom sheet stays open so users can add multiple products.
    // Closing is handled by the 'Done' button inside the sheet.
  }

  void removeOrderLine(int index) {
    orderLines.removeAt(index);
    calculateTotal();
  }

  void calculateTotal() {
    double total = 0.0;
    for (var line in orderLines) {
      total += line.price;
    }
    orderTotal.value = total;
  }

  Future<void> confirmOrder() async {
    if (orderLines.isEmpty) {
      Get.snackbar(
        'Empty Order',
        'Please add at least one product line',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      // Show loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final pref = await SharedPreferences.getInstance();
      final userId = pref.getInt("user_Id");
      final password = pref.getString("password");
      final empId = pref.getInt("empId") ?? 0;

      if (userId == null || password == null) {
        Get.back(); // close dialog
        Get.snackbar(
          "Session Error",
          "Missing credentials. Please login again.",
        );
        return;
      }

      // 1. Create sale.order
      final orderId = await JsonRpcHelper.executeKw(
        userId: userId,
        password: password,
        model: 'sale.order',
        method: 'create',
        args: [
          {"partner_id": customer.cusId, "user_id": userId},
        ],
      );

      if (orderId != null && orderId is int) {
        // 2. Create sale.order.line for each product
        for (var item in orderLines) {
          await JsonRpcHelper.executeKw(
            userId: userId,
            password: password,
            model: 'sale.order.line',
            method: 'create',
            args: [
              {
                "order_id": orderId,
                "product_id": item.productId,
                "product_uom_qty": item.quantity,
                "price_unit": item.initialUnitPrice,
                "discount": item.productLineDisc,
              },
            ],
          );
        }

        Get.back(); // close loading dialog

        Get.defaultDialog(
          title: 'Order Confirmed',
          middleText:
              'The order for ${customer.name} (#$orderId) has been placed successfully!',
          textConfirm: 'Done',
          onConfirm: () {
            Get.until((route) => route.settings.name == AppRoutes.dashboard);
          },
        );
      } else {
        Get.back(); // close dialog
        Get.snackbar("Order Failed", "Failed to create order record in Odoo.");
      }
    } catch (e) {
      Get.back(); // close dialog
      Get.snackbar("Network Error", "Failed to confirm order. $e");
    }
  }
}

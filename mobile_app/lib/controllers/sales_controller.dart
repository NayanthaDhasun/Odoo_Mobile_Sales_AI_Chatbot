import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sales_order_lines_model.dart';
import '../models/sales_order_model.dart';
import '../api/json_rpc_helper.dart';

class SalesController extends GetxController {
  final isLoading = false.obs;
  final isLoadingLines = false.obs;

  final recentOrders = <SalesOrderModel>[].obs;
  final currentOrderLines = <SalesOrderLinesModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadSales();
  }

  Future<void> loadSales() async {
    isLoading.value = true;

    try {
      final pref = await SharedPreferences.getInstance();
      final userId = pref.getInt("user_Id");
      final password = pref.getString("password");

      if (userId == null || password == null) {
        Get.snackbar(
          "Session Error",
          "Missing credentials. Please login again.",
        );
        isLoading.value = false;
        return;
      }

      // Fetch Sales Orders headers for this user
      List<dynamic> stateCondition = [
        '&',
        ['user_id', '=', userId],
        '|',
        ['state', '=', 'sale'],
        ['state', '=', 'draft'],
      ];

      final salesData = await JsonRpcHelper.executeKw(
        userId: userId,
        password: password,
        model: 'sale.order',
        method: 'search_read',
        args: [stateCondition],
        kwargs: {
          'fields': [
            'id',
            'name',
            'date_order',
            'partner_id',
            'amount_total',
            'state',
          ],
          'order': 'date_order desc',
          'limit': 50, // Fetch recent 50
        },
        timeout: const Duration(seconds: 45),
      );

      if (salesData.isEmpty) {
        recentOrders.clear();
        return;
      }

      final List<SalesOrderModel> parsedOrders = [];
      for (var order in salesData) {
        if (order is Map<String, dynamic>) {
          parsedOrders.add(SalesOrderModel.fromJson(order));
        }
      }

      recentOrders.assignAll(parsedOrders);
    } catch (e) {
      debugPrint("Error fetching sales orders: $e");
      Get.snackbar("Network Error", "Failed to load sales data. $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadOrderLines(int orderId) async {
    isLoadingLines.value = true;
    currentOrderLines.clear();

    try {
      final pref = await SharedPreferences.getInstance();
      final userId = pref.getInt("user_Id");
      final password = pref.getString("password");

      if (userId == null || password == null) return;

      final salesOrderLines = await JsonRpcHelper.executeKw(
        userId: userId,
        password: password,
        model: 'sale.order.line',
        method: 'search_read',
        args: [
          [
            ['order_id', '=', orderId],
          ],
        ],
        kwargs: {
          'fields': [
            'id',
            'order_id',
            'product_id',
            'product_uom_qty',
            'price_unit',
            'price_subtotal',
            'discount',
            'tax_id',
          ],
        },
        timeout: const Duration(seconds: 30),
      );

      final List<SalesOrderLinesModel> parsedLines = [];
      for (var line in salesOrderLines) {
        if (line is Map<String, dynamic>) {
          int productId = 0;
          String productName = "Unknown Product";
          if (line['product_id'] is List &&
              (line['product_id'] as List).length > 1) {
            productId = (line['product_id'][0] as num).toInt();
            productName = line['product_id'][1].toString();
          }

          double quantity =
              (line['product_uom_qty'] as num?)?.toDouble() ?? 0.0;
          double priceUnit = (line['price_unit'] as num?)?.toDouble() ?? 0.0;
          double priceSubtotal =
              (line['price_subtotal'] as num?)?.toDouble() ?? 0.0;
          double discount = (line['discount'] as num?)?.toDouble() ?? 0.0;

          parsedLines.add(
            SalesOrderLinesModel(
              id: (line['id'] as num).toInt(),
              customerId: 0,
              salesTeamId: 0,
              salesJournalId: 0,
              priceListId: 0,
              salesTeamUserid: 0,
              salesTeamTaxIds: '',
              taxPriceAmount: 0.0,
              applyingTaxLine: 'Standard',
              productId: productId,
              productName: productName,
              price: priceSubtotal,
              initialUnitPrice: priceUnit,
              productLineDisc: discount,
              quantity: quantity,
              orderType: 'Standard',
              invoiceId: orderId,
            ),
          );
        }
      }

      currentOrderLines.assignAll(parsedLines);
    } catch (e) {
      debugPrint("Error fetching order lines: $e");
      Get.snackbar("Network Error", "Failed to load order lines. $e");
    } finally {
      isLoadingLines.value = false;
    }
  }
}

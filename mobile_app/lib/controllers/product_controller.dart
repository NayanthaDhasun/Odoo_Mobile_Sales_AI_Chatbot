import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_data_model.dart';
import '../api/json_rpc_helper.dart';

class ProductController extends GetxController {
  final isLoading = false.obs;

  final products = <ProductDataModel>[].obs;
  final filteredProducts = <ProductDataModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> loadProducts() async {
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

      List<dynamic> searchDomain = [
        '&',
        ['is_storable', '=', true],
        ['type', '=', "consu"],
      ];

      final productData = await JsonRpcHelper.executeKw(
        userId: userId,
        password: password,
        model: 'product.product',
        method: 'search_read',
        args: [searchDomain],
        kwargs: {
          'fields': [
            'id',
            'display_name',
            'list_price',
            'stock_quant_ids',
            'product_tmpl_id',
            'default_code',
            'barcode',
            'write_date',
            'active',
            'taxes_id',
            'image_1920',
            'qty_available',
          ],
        },
        timeout: const Duration(seconds: 45),
      );

      final List<ProductDataModel> loadedProducts = [];

      for (var item in productData) {
        if (item is Map<String, dynamic>) {
          double listPrice = 0.0;
          if (item['list_price'] != false && item['list_price'] != null) {
            listPrice = double.tryParse(item['list_price'].toString()) ?? 0.0;
          }

          String barcode = item['barcode'] != false
              ? item['barcode'].toString()
              : "";
          String defaultCode = item['default_code'] != false
              ? item['default_code'].toString()
              : "";
          String name = item['display_name'] != false
              ? item['display_name'].toString()
              : "";
          String taxesId = "";

          if (item['taxes_id'] != null && item['taxes_id'] is List) {
            taxesId = (item['taxes_id'] as List).join(',');
          }

          String productImage = "";
          if (item["image_1920"] != false) {
            productImage = item["image_1920"].toString();
          }

          // Generate mock stock quant id logic
          String stockQuantId = "";
          if (item['stock_quant_ids'] != null &&
              item['stock_quant_ids'] is List &&
              (item['stock_quant_ids'] as List).isNotEmpty) {
            stockQuantId = (item['stock_quant_ids'] as List).join(',');
          }

          // Real on-hand quantity from Odoo's qty_available field
          double qtyAvailable = 0.0;
          if (item['qty_available'] != null && item['qty_available'] != false) {
            qtyAvailable =
                double.tryParse(item['qty_available'].toString()) ?? 0.0;
          }

          loadedProducts.add(
            ProductDataModel(
              productId: item['id'],
              name: name,
              list_price: listPrice,
              barcode: barcode,
              quantity: qtyAvailable,
              qtyAvailable: qtyAvailable,
              stock_quant_id: stockQuantId,
              reference: defaultCode,
              taxids: taxesId,
              productImage: productImage,
            ),
          );
        }
      }

      products.assignAll(loadedProducts);
      filteredProducts.assignAll(loadedProducts);
    } catch (e) {
      debugPrint("Error fetching products: $e");
      Get.snackbar("Network Error", "Failed to load products from Odoo. $e");
    } finally {
      isLoading.value = false;
    }
  }

  void searchProducts(String query) {
    if (query.isEmpty) {
      filteredProducts.assignAll(products);
    } else {
      final lowerQuery = query.toLowerCase();
      filteredProducts.assignAll(
        products
            .where(
              (p) =>
                  p.name.toLowerCase().contains(lowerQuery) ||
                  p.barcode.toLowerCase().contains(lowerQuery) ||
                  p.reference.toLowerCase().contains(lowerQuery),
            )
            .toList(),
      );
    }
  }
}

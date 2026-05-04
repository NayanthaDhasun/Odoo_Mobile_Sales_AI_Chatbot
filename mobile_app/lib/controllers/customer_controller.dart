import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_data_model.dart';
import '../routes/app_routes.dart';
import '../api/json_rpc_helper.dart';

class CustomerController extends GetxController {
  final isLoading = false.obs;

  // Observable list
  final customers = <CustomerDataModel>[].obs;
  final filteredCustomers = <CustomerDataModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
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
        ['active', '=', true],
      ];

      final customerData = await JsonRpcHelper.executeKw(
        userId: userId,
        password: password,
        model: 'res.partner',
        method: 'search_read',
        args: [searchDomain],
        kwargs: {
          'fields': [
            'id',
            'name',
            'city',
            'ref',
            'credit_limit',
            'credit',
            'vat',
            'active',
          ],
        },
        timeout: const Duration(seconds: 30),
      );

      final List<CustomerDataModel> loadedCustomers = [];

      for (var item in customerData) {
        if (item is Map<String, dynamic>) {
          String city = item['city'] != false ? item['city'].toString() : "";
          String ref = item['ref'] != false ? item['ref'].toString() : "";
          String name = item['name'] != false ? item['name'].toString() : "";
          String customerRef = item['customer_ref'] != false
              ? item['customer_ref'].toString()
              : "";

          double creditLimit = 0.0;
          if (item['credit_limit'] != false) {
            creditLimit =
                double.tryParse(item['credit_limit'].toString()) ?? 0.0;
          }

          double credit = 0.0;
          if (item['credit'] != false) {
            credit = double.tryParse(item['credit'].toString()) ?? 0.0;
          }

          bool isVatCustomer = false;
          if (item['vat'] != false && item['vat'] != null) {
            isVatCustomer = true;
          }

          loadedCustomers.add(
            CustomerDataModel(
              cusId: item['id'],
              salesTeamId: 0, // Fallback if missing
              journalId: 0, // Fallback if missing
              name: name,
              city: city,
              reference: ref,
              customer_ref: customerRef,
              creditLimit: creditLimit,
              availableBalance: creditLimit - credit,
              orderState: 'Active',
              isVatCus: isVatCustomer,
              pdChequeReturnAmount: 0.0,
            ),
          );
        }
      }

      customers.assignAll(loadedCustomers);
      filteredCustomers.assignAll(loadedCustomers);
    } catch (e) {
      debugPrint("Error fetching customers: $e");
      Get.snackbar("Network Error", "Failed to load customers from Odoo. $e");
    } finally {
      isLoading.value = false;
    }
  }

  void searchCustomers(String query) {
    if (query.isEmpty) {
      filteredCustomers.assignAll(customers);
    } else {
      final lowerQuery = query.toLowerCase();
      filteredCustomers.assignAll(
        customers
            .where(
              (cust) =>
                  cust.name.toLowerCase().contains(lowerQuery) ||
                  cust.city.toLowerCase().contains(lowerQuery) ||
                  cust.customer_ref.toLowerCase().contains(lowerQuery) ||
                  cust.reference.toLowerCase().contains(lowerQuery),
            )
            .toList(),
      );
    }
  }

  void selectCustomerForOrder(CustomerDataModel customer) {
    Get.toNamed(AppRoutes.orderTaking, arguments: customer);
  }
}

import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class DashboardController extends GetxController {
  // Placeholder navigation functions for carts
  void navigateToCustomer() {
    Get.toNamed(AppRoutes.customerList);
  }

  void navigateToSales() {
    Get.toNamed(AppRoutes.salesList);
  }

  void navigateToInventory() {
    Get.toNamed(AppRoutes.inventory);
  }

  void logout() {
    Get.offAllNamed(AppRoutes.login);
  }
}

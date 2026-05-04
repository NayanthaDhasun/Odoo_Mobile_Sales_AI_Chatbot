import 'package:get/get.dart';
import 'app_routes.dart';

import '../views/auth/login_view.dart';
import '../views/auth/employee_validation_view.dart';
import '../bindings/auth_binding.dart';
import '../views/dashboard/dashboard_view.dart';
import '../bindings/dashboard_binding.dart';
import '../views/inventory/inventory_view.dart';
import '../bindings/inventory_binding.dart';
import '../views/sales/sales_list_view.dart';
import '../bindings/sales_binding.dart';
import '../views/customer/customer_list_view.dart';
import '../bindings/customer_binding.dart';
import '../views/customer/order_taking_view.dart';
import '../bindings/order_taking_binding.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.employeeValidation,
      page: () => const EmployeeValidationView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.inventory,
      page: () => const InventoryView(),
      binding: InventoryBinding(),
    ),
    GetPage(
      name: AppRoutes.salesList,
      page: () => const SalesListView(),
      binding: SalesBinding(),
    ),
    GetPage(
      name: AppRoutes.customerList,
      page: () => const CustomerListView(),
      binding: CustomerBinding(),
    ),
    GetPage(
      name: AppRoutes.orderTaking,
      page: () => const OrderTakingView(),
      binding: OrderTakingBinding(),
    ),
  ];
}

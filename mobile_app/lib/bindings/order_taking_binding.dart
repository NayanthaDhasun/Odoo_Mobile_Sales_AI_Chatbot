import 'package:get/get.dart';
import '../controllers/order_taking_controller.dart';
import '../controllers/product_controller.dart';

class OrderTakingBinding extends Bindings {
  @override
  void dependencies() {
    // We already have product controller lazyly initialized in bindings, but let's ensure it's available
    // for searching within the order form since it depends on it.
    Get.put<ProductController>(ProductController());
    Get.lazyPut<OrderTakingController>(() => OrderTakingController());
  }
}

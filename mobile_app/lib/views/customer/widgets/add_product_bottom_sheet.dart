import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/order_taking_controller.dart';
import '../../../controllers/product_controller.dart';
import '../../../models/product_data_model.dart';

class AddProductBottomSheet extends StatefulWidget {
  const AddProductBottomSheet({super.key});

  @override
  State<AddProductBottomSheet> createState() => _AddProductBottomSheetState();
}

class _AddProductBottomSheetState extends State<AddProductBottomSheet> {
  final ProductController productController = Get.find<ProductController>();
  final OrderTakingController orderController =
      Get.find<OrderTakingController>();
  final TextEditingController _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(symbol: 'Rs ');

  // Local state for search and quantity management
  Timer? _debounce;
  final Map<int, TextEditingController> _qtyControllers = {};

  @override
  void initState() {
    super.initState();
    productController.searchProducts(''); // Reset filter on open

    // Initialize a TextEditingController for every product,
    // pre-filling from whatever is already in the cart.
    for (final product in productController.products) {
      final existingLine = orderController.orderLines.firstWhereOrNull(
        (line) => line.productId == product.productId,
      );
      final initialText = existingLine != null && existingLine.quantity > 0
          ? existingLine.quantity.toStringAsFixed(0)
          : '';
      _qtyControllers[product.productId] = TextEditingController(
        text: initialText,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    for (var controller in _qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _filterProducts(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      productController.searchProducts(query);
    });
  }

  void _updateQuantity(ProductDataModel product, double newQty) {
    if (newQty < 0) return;

    // Ensure the controller exists (products added after initState)
    _qtyControllers.putIfAbsent(
      product.productId,
      () => TextEditingController(),
    );

    // Update the controller text
    final ctrl = _qtyControllers[product.productId]!;
    final newText = newQty > 0 ? newQty.toStringAsFixed(0) : '';
    if (ctrl.text != newText) {
      ctrl.text = newText;
      // Keep cursor at end
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
    }

    // If newQty is 0, we remove from cart
    if (newQty == 0) {
      final existingIndex = orderController.orderLines.indexWhere(
        (line) => line.productId == product.productId,
      );
      if (existingIndex != -1) {
        orderController.removeOrderLine(existingIndex);
      }
    } else {
      // Find if it exists to know whether to add or replace
      final existingLine = orderController.orderLines.firstWhereOrNull(
        (line) => line.productId == product.productId,
      );

      if (existingLine != null) {
        final existingIndex = orderController.orderLines.indexWhere(
          (line) => line.productId == product.productId,
        );

        final updatedLine = existingLine.copyWith(
          quantity: newQty,
          price: existingLine.initialUnitPrice * newQty,
          taxPriceAmount: (existingLine.initialUnitPrice * 0.1) * newQty,
        );
        orderController.orderLines[existingIndex] = updatedLine;
        orderController.calculateTotal(); // Need to recalculate total
      } else {
        // New item
        orderController.addProductLine(product, newQty);
      }
    }
  }

  void _incrementQty(ProductDataModel product) {
    final currentText = _qtyControllers[product.productId]?.text ?? '';
    final currentQty = double.tryParse(currentText) ?? 0.0;
    _updateQuantity(product, currentQty + 1);
  }

  void _decrementQty(ProductDataModel product) {
    final currentText = _qtyControllers[product.productId]?.text ?? '';
    final currentQty = double.tryParse(currentText) ?? 0.0;
    if (currentQty > 0) {
      _updateQuantity(product, currentQty - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kMainColor = Theme.of(context).colorScheme.primary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F9FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header & Search
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.search, color: kMainColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Select Products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: kMainColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterProducts,
                        decoration: InputDecoration(
                          hintText: 'Search by name or barcode...',
                          prefixIcon: Icon(Icons.search, color: kMainColor),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterProducts('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: kMainColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: kMainColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: kMainColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          Get.snackbar(
                            'Scanner',
                            'Barcode scanner feature coming soon!',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: 'Scan Barcode',
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: Obx(() {
              if (productController.isLoading.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: kMainColor),
                      const SizedBox(height: 16),
                      Text(
                        'Loading products...',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (productController.filteredProducts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No products found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: productController.filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = productController.filteredProducts[index];
                  // Observe order lines to trigger rebuilds when cart changes inside the sheet
                  return Obx(() {
                    // Just referencing orderLines.length to make it reactive without a warning
                    // ignore: unused_local_variable
                    final _ = orderController.orderLines.length;

                    final currentQtyText =
                        _qtyControllers[product.productId]?.text ?? '';
                    final isSelected =
                        currentQtyText.isNotEmpty && currentQtyText != '0';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? kMainColor.withValues(alpha: 0.5)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image Placeholder
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Color(0xFF2D3142),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        currencyFormat.format(
                                          product.list_price,
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: kMainColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'Stock: ${product.quantity.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Quantity Controls
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () =>
                                                  _decrementQty(product),
                                              borderRadius:
                                                  const BorderRadius.horizontal(
                                                    left: Radius.circular(8),
                                                  ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.remove,
                                                  size: 18,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 45,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.symmetric(
                                                  vertical: BorderSide(
                                                    color: Colors.grey[300]!,
                                                  ),
                                                ),
                                              ),
                                              child: TextField(
                                                controller:
                                                    _qtyControllers[product
                                                        .productId],
                                                keyboardType:
                                                    TextInputType.number,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                      border: InputBorder.none,
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                    ),
                                                onChanged: (val) {
                                                  final qty =
                                                      double.tryParse(val) ?? 0;
                                                  _updateQuantity(product, qty);
                                                },
                                                onSubmitted: (val) {
                                                  final qty =
                                                      double.tryParse(val) ?? 0;
                                                  _updateQuantity(product, qty);
                                                },
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () =>
                                                  _incrementQty(product),
                                              borderRadius:
                                                  const BorderRadius.horizontal(
                                                    right: Radius.circular(8),
                                                  ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.add,
                                                  size: 18,
                                                  color: kMainColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                },
              );
            }),
          ),

          // Bottom Checkout Bar (Optional inside sheet)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Obx(
                () => Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total: ${orderController.orderLines.length} items',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          currencyFormat.format(
                            orderController.orderTotal.value,
                          ),
                          style: TextStyle(
                            color: kMainColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Get.back(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

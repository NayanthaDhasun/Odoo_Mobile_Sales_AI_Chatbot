import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/staticData.dart';

/// Configuration data to pass to the validation isolate
class ValidationConfig {
  final int userId;
  final String password;
  final String baseUrl;
  final String dbName;
  final List<int> customerIds;
  final List<int> productIds;
  final SendPort sendPort;
  final RootIsolateToken rootIsolateToken;

  ValidationConfig({
    required this.userId,
    required this.password,
    required this.baseUrl,
    required this.dbName,
    required this.customerIds,
    required this.productIds,
    required this.sendPort,
    required this.rootIsolateToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'password': password,
      'baseUrl': baseUrl,
      'dbName': dbName,
      'customerIds': customerIds,
      'productIds': productIds,
      'sendPort': sendPort,
      'rootIsolateToken': rootIsolateToken,
    };
  }

  factory ValidationConfig.fromMap(Map<String, dynamic> map) {
    return ValidationConfig(
      userId: map['userId'] as int,
      password: map['password'] as String,
      baseUrl: map['baseUrl'] as String,
      dbName: map['dbName'] as String,
      customerIds: List<int>.from(map['customerIds'] as List),
      productIds: List<int>.from(map['productIds'] as List),
      sendPort: map['sendPort'] as SendPort,
      rootIsolateToken: map['rootIsolateToken'] as RootIsolateToken,
    );
  }
}

/// Result of validation process
class ValidationResult {
  final List<int> deletedCustomerIds;
  final List<int> deletedProductIds;
  final bool success;
  final String? error;

  ValidationResult({
    required this.deletedCustomerIds,
    required this.deletedProductIds,
    required this.success,
    this.error,
  });

  Map<String, dynamic> toMap() {
    return {
      'deletedCustomerIds': deletedCustomerIds,
      'deletedProductIds': deletedProductIds,
      'success': success,
      'error': error,
    };
  }

  factory ValidationResult.fromMap(Map<String, dynamic> map) {
    return ValidationResult(
      deletedCustomerIds: List<int>.from(map['deletedCustomerIds'] as List),
      deletedProductIds: List<int>.from(map['deletedProductIds'] as List),
      success: map['success'] as bool,
      error: map['error'] as String?,
    );
  }
}

/// Background Validation Service
/// Handles validation of customers and products in a separate isolate
class BackgroundValidationService {
  /// Spawn an isolate to validate customers and products in the background
  /// Returns immediately without blocking the main thread
  static Future<void> startValidation({
    required List<int> customerIds,
    required List<int> productIds,
    Function(ValidationResult)? onComplete,
  }) async {
    try {
      // Get credentials
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_Id");
      final password = prefs.getString("password");

      if (userId == null || password == null) {
        return;
      }

      // Get the root isolate token (required for platform channels in isolate)
      final rootIsolateToken = RootIsolateToken.instance;
      if (rootIsolateToken == null) {
        return;
      }

      // Create receive port to get results back
      final receivePort = ReceivePort();

      // Prepare config
      final config = ValidationConfig(
        userId: userId,
        password: password,
        baseUrl: baseUrl,
        dbName: dbName,
        customerIds: customerIds,
        productIds: productIds,
        sendPort: receivePort.sendPort,
        rootIsolateToken: rootIsolateToken,
      );

      // Spawn isolate
      await Isolate.spawn(
        _validationIsolateEntry,
        config.toMap(),
        onError: receivePort.sendPort,
        onExit: receivePort.sendPort,
      );

      // Listen for results (optional - only if callback provided)
      if (onComplete != null) {
        receivePort.listen((message) {
          if (message is Map<String, dynamic>) {
            final result = ValidationResult.fromMap(message);
            onComplete(result);
            receivePort.close();
          } else if (message == null) {
            // Isolate exited
            receivePort.close();
          }
        });
      } else {
        // Fire and forget - close port after a delay
        Future.delayed(const Duration(seconds: 1), () {
          receivePort.close();
        });
      }
    } catch (e) {}
  }

  /// Top-level isolate entry point
  /// This function runs in a separate isolate and performs validation
  @pragma('vm:entry-point')
  static Future<void> _validationIsolateEntry(
    Map<String, dynamic> configMap,
  ) async {
    final config = ValidationConfig.fromMap(configMap);
    final sendPort = config.sendPort;

    try {
      // CRITICAL: Initialize the binary messenger for platform channels
      BackgroundIsolateBinaryMessenger.ensureInitialized(
        config.rootIsolateToken,
      );

      final deletedCustomerIds = <int>[];
      final deletedProductIds = <int>[];

      // STEP 1: Validate Customers
      if (config.customerIds.isNotEmpty) {
        final nonExistingCustomerIds = await _checkNonExistingCustomers(
          config.customerIds,
          config.userId,
          config.password,
          config.baseUrl,
          config.dbName,
        );

        if (nonExistingCustomerIds.isNotEmpty) {
          deletedCustomerIds.addAll(nonExistingCustomerIds);
        }
      }

      // STEP 2: Validate Products
      if (config.productIds.isNotEmpty) {
        final nonExistingProductIds = await _checkNonExistingProducts(
          config.productIds,
          config.userId,
          config.password,
          config.baseUrl,
          config.dbName,
        );

        if (nonExistingProductIds.isNotEmpty) {
          deletedProductIds.addAll(nonExistingProductIds);
        }
      }

      // STEP 3: Store results for next app launch (optional)
      if (deletedCustomerIds.isNotEmpty || deletedProductIds.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          'last_validation_deleted_customers',
          deletedCustomerIds.length,
        );
        await prefs.setInt(
          'last_validation_deleted_products',
          deletedProductIds.length,
        );
        await prefs.setString(
          'last_validation_time',
          DateTime.now().toIso8601String(),
        );
      }

      // Send success result
      final result = ValidationResult(
        deletedCustomerIds: deletedCustomerIds,
        deletedProductIds: deletedProductIds,
        success: true,
      );

      sendPort.send(result.toMap());
    } catch (e) {
      // Send error result
      final result = ValidationResult(
        deletedCustomerIds: [],
        deletedProductIds: [],
        success: false,
        error: e.toString(),
      );

      sendPort.send(result.toMap());
    }
  }

  /// Check which customer IDs do NOT exist on the server
  static Future<List<int>> _checkNonExistingCustomers(
    List<int> customerIds,
    int userId,
    String password,
    String baseUrl,
    String dbName,
  ) async {
    try {
      if (customerIds.isEmpty) return [];

      // Call server to check which customers exist using JSON-RPC
      final body = jsonEncode({
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "service": "object",
          "method": "execute_kw",
          "args": [
            dbName,
            userId,
            password,
            'res.partner',
            'search_read',
            [
              [
                ['id', 'in', customerIds],
              ],
            ],
            {
              'fields': ['id'],
            },
          ],
        },
        "id": DateTime.now().millisecondsSinceEpoch,
      });

      final response = await http
          .post(
            Uri.parse("$baseUrl/jsonrpc"),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Customer check timeout after 30 seconds');
            },
          );

      if (response.statusCode != 200) {
        throw Exception(
          "HTTP ${response.statusCode}: ${response.reasonPhrase}",
        );
      }

      final result = jsonDecode(response.body);

      if (result['error'] != null) {
        throw Exception(result['error'].toString());
      }

      final existingCustomers = result['result'];

      // Extract existing IDs
      final existingIds = (existingCustomers as List)
          .whereType<Map<String, dynamic>>()
          .map((customer) => customer['id'] as int)
          .toSet();

      // Find non-existing IDs
      final nonExistingIds = customerIds
          .where((id) => !existingIds.contains(id))
          .toList();

      return nonExistingIds;
    } catch (e) {
      return [];
    }
  }

  /// Check which product IDs do NOT exist on the server
  static Future<List<int>> _checkNonExistingProducts(
    List<int> productIds,
    int userId,
    String password,
    String baseUrl,
    String dbName,
  ) async {
    try {
      if (productIds.isEmpty) return [];

      // Call server to check which products exist using JSON-RPC
      final body = jsonEncode({
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "service": "object",
          "method": "execute_kw",
          "args": [
            dbName,
            userId,
            password,
            'product.product',
            'search_read',
            [
              [
                '&',
                ['is_storable', '=', true],
                ['type', '=', "consu"],
                ['id', 'in', productIds],
              ],
            ],
            {
              'fields': ['id'],
            },
          ],
        },
        "id": DateTime.now().millisecondsSinceEpoch,
      });

      final response = await http
          .post(
            Uri.parse("$baseUrl/jsonrpc"),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Product check timeout after 30 seconds');
            },
          );

      if (response.statusCode != 200) {
        throw Exception(
          "HTTP ${response.statusCode}: ${response.reasonPhrase}",
        );
      }

      final result = jsonDecode(response.body);

      if (result['error'] != null) {
        throw Exception(result['error'].toString());
      }

      final existingProducts = result['result'];

      // Extract existing IDs
      final existingIds = (existingProducts as List)
          .whereType<Map<String, dynamic>>()
          .map((product) => product['id'] as int)
          .toSet();

      // Find non-existing IDs
      final nonExistingIds = productIds
          .where((id) => !existingIds.contains(id))
          .toList();

      return nonExistingIds;
    } catch (e) {
      return [];
    }
  }
}

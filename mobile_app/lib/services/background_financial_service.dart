import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/staticData.dart';

import '../models/cus_financialSummaryList_Model.dart';

/// Configuration for financial summary fetch
class FinancialSummaryConfig {
  final int userId;
  final String password;
  final String baseUrl;
  final String dbName;
  final int customerId;
  final SendPort sendPort;
  final RootIsolateToken rootIsolateToken;

  FinancialSummaryConfig({
    required this.userId,
    required this.password,
    required this.baseUrl,
    required this.dbName,
    required this.customerId,
    required this.sendPort,
    required this.rootIsolateToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'password': password,
      'baseUrl': baseUrl,
      'dbName': dbName,
      'customerId': customerId,
      'sendPort': sendPort,
      'rootIsolateToken': rootIsolateToken,
    };
  }

  factory FinancialSummaryConfig.fromMap(Map<String, dynamic> map) {
    return FinancialSummaryConfig(
      userId: map['userId'] as int,
      password: map['password'] as String,
      baseUrl: map['baseUrl'] as String,
      dbName: map['dbName'] as String,
      customerId: map['customerId'] as int,
      sendPort: map['sendPort'] as SendPort,
      rootIsolateToken: map['rootIsolateToken'] as RootIsolateToken,
    );
  }
}

/// Result of financial summary fetch
class FinancialSummaryResult {
  final CustomerFinancialSummaryModel? data;
  final bool success;
  final String? error;

  FinancialSummaryResult({this.data, required this.success, this.error});

  Map<String, dynamic> toMap() {
    return {'data': data?.toMap(), 'success': success, 'error': error};
  }

  factory FinancialSummaryResult.fromMap(Map<String, dynamic> map) {
    return FinancialSummaryResult(
      data: map['data'] != null
          ? CustomerFinancialSummaryModel.fromMap(map['data'])
          : null,
      success: map['success'] as bool,
      error: map['error'] as String?,
    );
  }
}

/// Model for customer financial summary

/// Background Financial Summary Service
class BackgroundFinancialService {
  /// Start background fetch for customer financial summary
  static Future<void> startFinancialSummaryFetch({
    required int customerId,
    Function(FinancialSummaryResult)? onComplete,
  }) async {
    try {
      // Get credentials
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_Id");
      final password = prefs.getString("password");

      if (userId == null || password == null) {
        onComplete?.call(
          FinancialSummaryResult(success: false, error: "Missing credentials"),
        );
        return;
      }

      // Get root isolate token
      final rootIsolateToken = RootIsolateToken.instance;
      if (rootIsolateToken == null) {
        onComplete?.call(
          FinancialSummaryResult(
            success: false,
            error: "Cannot initialize isolate",
          ),
        );
        return;
      }

      // Create receive port
      final receivePort = ReceivePort();

      // Prepare config
      final config = FinancialSummaryConfig(
        userId: userId,
        password: password,
        baseUrl: baseUrl,
        dbName: dbName,
        customerId: customerId,
        sendPort: receivePort.sendPort,
        rootIsolateToken: rootIsolateToken,
      );

      // Spawn isolate
      await Isolate.spawn(
        _financialSummaryIsolateEntry,
        config.toMap(),
        onError: receivePort.sendPort,
        onExit: receivePort.sendPort,
      );

      // Listen for results
      if (onComplete != null) {
        receivePort.listen((message) {
          if (message is Map<String, dynamic>) {
            final result = FinancialSummaryResult.fromMap(message);
            onComplete(result);
            receivePort.close();
          } else if (message == null) {
            receivePort.close();
          }
        });
      } else {
        Future.delayed(const Duration(seconds: 1), receivePort.close);
      }
    } catch (e) {
      onComplete?.call(
        FinancialSummaryResult(success: false, error: e.toString()),
      );
    }
  }

  /// Isolate entry point for financial summary fetch
  @pragma('vm:entry-point')
  static Future<void> _financialSummaryIsolateEntry(
    Map<String, dynamic> configMap,
  ) async {
    final config = FinancialSummaryConfig.fromMap(configMap);
    final sendPort = config.sendPort;

    try {
      // Initialize binary messenger for platform channels
      BackgroundIsolateBinaryMessenger.ensureInitialized(
        config.rootIsolateToken,
      );

      // Fetch customer data and PDC data in parallel
      final results = await Future.wait([
        _fetchCustomerData(config),
        _fetchPDCData(config),
      ]);

      final customerData = results[0] as List<dynamic>;
      final pdcTotal = results[1] as double;

      if (customerData.isEmpty) {
        sendPort.send(
          FinancialSummaryResult(
            success: true,
            error: "Customer not found",
          ).toMap(),
        );
        return;
      }

      // Parse customer data
      final item = customerData[0];
      final summary = CustomerFinancialSummaryModel(
        cusId: item["id"] as int,
        creditLimit: (item["credit_limit"] as num?)?.toDouble() ?? 0.0,
        partnerCreditLimit: item["use_partner_credit_limit"] as bool? ?? false,
        credit: (item["credit"] as num?)?.toDouble() ?? 0.0,
        pdCheckTotal: pdcTotal,
      );

      // Send success result
      sendPort.send(
        FinancialSummaryResult(data: summary, success: true).toMap(),
      );
    } catch (e) {
      sendPort.send(
        FinancialSummaryResult(success: false, error: e.toString()).toMap(),
      );
    }
  }

  /// Fetch customer financial data
  static Future<List<dynamic>> _fetchCustomerData(
    FinancialSummaryConfig config,
  ) async {
    // Use JSON-RPC
    final body = jsonEncode({
      "jsonrpc": "2.0",
      "method": "call",
      "params": {
        "service": "object",
        "method": "execute_kw",
        "args": [
          config.dbName,
          config.userId,
          config.password,
          'res.partner',
          'search_read',
          [
            [
              ['id', '=', config.customerId],
            ],
          ],
          {
            'fields': [
              'id',
              'credit_limit',
              'use_partner_credit_limit',
              'credit',
            ],
          },
        ],
      },
      "id": DateTime.now().millisecondsSinceEpoch,
    });

    final response = await http
        .post(
          Uri.parse("${config.baseUrl}/jsonrpc"),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () =>
              throw TimeoutException('Customer data fetch timeout'),
        );

    if (response.statusCode != 200) {
      throw Exception("HTTP ${response.statusCode}: ${response.reasonPhrase}");
    }

    final result = jsonDecode(response.body);

    if (result['error'] != null) {
      throw Exception(result['error'].toString());
    }

    return result['result'] as List<dynamic>;
  }

  /// Fetch PDC (Post-Dated Cheque) data
  static Future<double> _fetchPDCData(FinancialSummaryConfig config) async {
    try {
      // Use JSON-RPC
      final body = jsonEncode({
        "jsonrpc": "2.0",
        "method": "call",
        "params": {
          "service": "object",
          "method": "execute_kw",
          "args": [
            config.dbName,
            config.userId,
            config.password,
            'account.pdc',
            'search_read',
            [
              [
                ['state', '=', 'return'],
                ['partner_id', '=', config.customerId],
              ],
            ],
            {
              'fields': ['id', 'amount'],
            },
          ],
        },
        "id": DateTime.now().millisecondsSinceEpoch,
      });

      final response = await http
          .post(
            Uri.parse("${config.baseUrl}/jsonrpc"),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('PDC data fetch timeout'),
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

      final pdcData = result['result'];

      // Calculate total PDC amount
      double total = 0.0;
      if (pdcData is List && pdcData.isNotEmpty) {
        for (final item in pdcData) {
          if (item is Map && item.containsKey('amount')) {
            total += (item['amount'] as num).toDouble();
          }
        }
      }

      return total;
    } catch (e) {
      return 0.0; // Return 0 if PDC fetch fails
    }
  }
}

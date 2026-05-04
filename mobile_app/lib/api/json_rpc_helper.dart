import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/staticData.dart';
/// Generic JSON-RPC helper for Odoo
/// Replaces XML-RPC calls with JSON-RPC
///
/// Usage:
/// - For authentication: jsonRpcCall(service: 'common', method: 'authenticate', args: [...])
/// - For data operations: jsonRpcCall(service: 'object', method: 'execute_kw', args: [...])
class JsonRpcHelper {
  /// Makes a JSON-RPC call to Odoo
  ///
  /// [service]: 'common' or 'object'
  /// [method]: Odoo method name (e.g., 'execute_kw', 'login', 'authenticate')
  /// [args]: list of arguments for Odoo call
  /// [timeout]: optional timeout duration (default: 60 seconds)
  static Future<dynamic> call({
    required String service,
    required String method,
    required List<dynamic> args,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    // Check if this is a login/authenticate call that doesn't need credentials
    final bool isAuthCall = service == 'common' &&
        (method == 'login' || method == 'authenticate' || method == 'version');

    // For non-auth calls, validate credentials (optional check)
    if (!isAuthCall) {
      final pref = await SharedPreferences.getInstance();
      final userId = pref.getInt("user_Id");
      final password = pref.getString("password");

      if (userId == null || password == null) {
        throw Exception("Missing credentials in SharedPreferences");
      }
    }

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "method": "call",
      "params": {
        "service": service,
        "method": method,
        "args": args,
      },
      "id": DateTime.now().millisecondsSinceEpoch,
    });

    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/jsonrpc"),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException(
                'Request timeout after ${timeout.inSeconds} seconds',
              );
            },
          );

      if (response.statusCode != 200) {
        throw Exception(
          "HTTP ${response.statusCode}: ${response.reasonPhrase}",
        );
      }

      final result = jsonDecode(response.body);

      // Handle Odoo errors
      if (result['error'] != null) {
        final error = result['error'];
        String errorMessage = 'Unknown error';

        if (error is Map) {
          // Try to extract a meaningful error message
          errorMessage = error['data']?['message'] ??
              error['message'] ??
              error['data']?['arguments']?[0] ??
              error.toString();
        } else {
          errorMessage = error.toString();
        }

        throw Exception(errorMessage);
      }

      return result['result'];
    } on TimeoutException {
      rethrow;
    } catch (e) {
      // Log the error for debugging
      print("JSON-RPC Error - Service: $service, Method: $method, Error: $e");
      rethrow;
    }
  }

  /// Convenience method for 'object' service calls (most common)
  static Future<dynamic> executeKw({
    required int userId,
    required String password,
    required String model,
    required String method,
    required List<dynamic> args,
    Map<String, dynamic>? kwargs,
    Duration timeout = const Duration(seconds: 60),
  }) {
    final callArgs = [
      dbName,
      userId,
      password,
      model,
      method,
      args,
      if (kwargs != null) kwargs,
    ];

    return call(
      service: 'object',
      method: 'execute_kw',
      args: callArgs,
      timeout: timeout,
    );
  }

  /// Convenience method for authentication
  static Future<dynamic> authenticate({
    required String username,
    required String password,
    Duration timeout = const Duration(seconds: 30),
  }) {
    return call(
      service: 'common',
      method: 'authenticate',
      args: [dbName, username, password, {}],
      timeout: timeout,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes/app_routes.dart';
import '../../api/json_rpc_helper.dart';
import '../../constants/staticData.dart';

class AuthController extends GetxController {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordHidden = true.obs;

  // Employee Validation State
  final employees = <Map<String, dynamic>>[].obs;
  final selectedEmployee = Rxn<Map<String, dynamic>>();
  final pinController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    // Optional logic to auto-fill remembered credentials
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter email and password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      final userId = await JsonRpcHelper.call(
        service: 'common',
        method: 'login',
        args: [dbName, username, password],
        timeout: const Duration(seconds: 30),
      );

      if (userId != false && userId != null && userId is int && userId > 0) {
        final pref = await SharedPreferences.getInstance();
        await pref.setInt("user_Id", userId);
        await pref.setString("password", password);
        await pref.setString("userName", username);

        // Fetch employees immediately after setting credentials
        await fetchEmployees();

        Get.toNamed(AppRoutes.employeeValidation);
      } else {
        Get.snackbar(
          'Login Failed',
          'Invalid credentials. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Login Error',
        'Failed to connect to the server. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchEmployees() async {
    isLoading.value = true;
    try {
      final pref = await SharedPreferences.getInstance();
      final userId = pref.getInt("user_Id");
      final password = pref.getString("password");

      if (userId == null || password == null) {
        employees.clear();
        return;
      }

      List<List<dynamic>> searchCriteria = [
        // ['company_id', '=', 1],
        ['x_studio_is_mobile_user', '=', true],
      ];

      final employeeData = await JsonRpcHelper.executeKw(
        userId: userId,
        password: password,
        model: 'hr.employee',
        method: 'search_read',
        args: [searchCriteria],
        kwargs: {
          'fields': ['id', 'name', 'pin', 'user_id', 'active', 'company_id'],
        },
        timeout: const Duration(seconds: 30),
      );

      if (employeeData.isNotEmpty) {
        employees.assignAll(employeeData.cast<Map<String, dynamic>>());
      } else {
        employees.clear();
      }
    } catch (e) {
      debugPrint("Error fetching employees: $e");
      Get.snackbar(
        'Notice',
        'Failed to fetch employees. $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
  void selectEmployee(Map<String, dynamic>? emp) {
    selectedEmployee.value = emp;
    pinController.clear();
  }
  Future<void> validateEmployee() async {
    final emp = selectedEmployee.value;
    if (emp == null) {
      Get.snackbar(
        'Error',
        'Please select an employee',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (pinController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your PIN',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    final empPin = emp['pin'];
    if (empPin != false && empPin.toString() == pinController.text) {
      final pref = await SharedPreferences.getInstance();
      await pref.setBool("LoggedIn", true);
      await pref.setInt("empId", emp['id']);

      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.snackbar(
        'Access Denied',
        'Invalid PIN entered.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    pinController.dispose();
    super.onClose();
  }
}

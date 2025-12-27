import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_closing_model.dart';
import 'config.dart';

class AccountClosingApiService {
  // Get next serial number (last serial + 1)
  Future<String> getNextSerialNo(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/account_closing_get_last_serial.php');

    try {
      var response = await http.post(
        url,
        body: {'companyid': companyid},
      );

      print("Get Next Serial Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['next_serial'] ?? 'AC-0001';
        }
      }
      return 'AC-0001';
    } catch (e) {
      print("Get Serial Error: $e");
      return 'AC-0001';
    }
  }

  // Get customers
  Future<List<Map<String, dynamic>>> getCustomers(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/get_customers.php');

    try {
      var response = await http.post(
        url,
        body: {'companyid': companyid},
      );

      print("Get Customers Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> items = data['data'] ?? [];
          return items.map((item) => {
            'id': item['id']?.toString() ?? '',
            'name': item['customername']?.toString() ?? '',
            'mobile': item['mobile1']?.toString() ?? '',
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print("Get Customers Error: $e");
      return [];
    }
  }

  // Get loans by customer
  Future<List<Map<String, dynamic>>> getLoansByCustomer(BuildContext context, String customerId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/get_loans_by_customer.php');

    try {
      var response = await http.post(
        url,
        body: {
          'companyid': companyid,
          'customerid': customerId,
        },
      );

      print("Get Loans By Customer Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> items = data['data'] ?? [];
          return items.map((item) => {
            'id': item['id']?.toString() ?? '',
            'loan_no': item['loanno']?.toString() ?? '',
            'loan_amount': item['loanamount']?.toString() ?? '0.00',
            'given_amount': item['givenamount']?.toString() ?? '0.00',
            'loan_status': item['loanstatus']?.toString() ?? '',
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print("Get Loans By Customer Error: $e");
      return [];
    }
  }

  // Get loan details for closing
  Future<Map<String, dynamic>> getLoanDetailsForClosing(BuildContext context, String loanId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/get_loan_details_for_closing.php');

    try {
      var response = await http.post(
        url,
        body: {
          'companyid': companyid,
          'loanid': loanId,
        },
      );

      print("Get Loan Details Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          return {
            'loan_amount': data['loan_amount']?.toString() ?? '0.00',
            'loan_paid': data['loan_paid']?.toString() ?? '0.00',
            'balance_amount': data['balance_amount']?.toString() ?? '0.00',
            'penalty_amount': data['penalty_amount']?.toString() ?? '0.00',
            'penalty_collected': data['penalty_collected']?.toString() ?? '0.00',
            'penalty_balance': data['penalty_balance']?.toString() ?? '0.00',
          };
        }
      }
      return {};
    } catch (e) {
      print("Get Loan Details Error: $e");
      return {};
    }
  }

  // Insert account closing
  Future<String> insertAccountClosing({
    required BuildContext context,
    required String serialNo,
    required String date,
    required String customerId,
    required String customerName,
    required String loanId,
    required String loanNo,
    required String loanAmount,
    required String loanPaid,
    required String balanceAmount,
    required String penaltyAmount,
    required String penaltyCollected,
    required String penaltyBalance,
    required String discountPrinciple,
    required String discountPenalty,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    // Calculate final settlement
    double principleBalance = (double.tryParse(balanceAmount) ?? 0) - (double.tryParse(discountPrinciple) ?? 0);
    double penaltyRemaining = (double.tryParse(penaltyBalance) ?? 0) - (double.tryParse(discountPenalty) ?? 0);
    double finalSettlement = principleBalance + penaltyRemaining;

    var url = Uri.parse('$baseUrl/account_closing_insert.php');

    try {
      print("Insert Account Closing Data:");
      print("Company ID: $companyid");
      print("Serial No: $serialNo");
      print("Date: $date");
      print("Customer ID: $customerId");
      print("Customer Name: $customerName");
      print("Loan ID: $loanId");
      print("Loan No: $loanNo");
      print("Loan Amount: $loanAmount");
      print("Loan Paid: $loanPaid");
      print("Balance Amount: $balanceAmount");
      print("Penalty Amount: $penaltyAmount");
      print("Penalty Collected: $penaltyCollected");
      print("Penalty Balance: $penaltyBalance");
      print("Discount Principle: $discountPrinciple");
      print("Discount Penalty: $discountPenalty");
      print("Final Settlement: $finalSettlement");
      print("Added By: $userid");

      var response = await http.post(
        url,
        body: {
          'companyid': companyid,
          'serial_no': serialNo,
          'date': date,
          'customer_id': customerId,
          'customer_name': customerName,
          'loan_id': loanId,
          'loan_no': loanNo,
          'loan_amount': loanAmount,
          'loan_paid': loanPaid,
          'balance_amount': balanceAmount,
          'penalty_amount': penaltyAmount,
          'penalty_collected': penaltyCollected,
          'penalty_balance': penaltyBalance,
          'discount_principle': discountPrinciple,
          'discount_penalty': discountPenalty,
          'final_settlement': finalSettlement.toStringAsFixed(2),
          'addedby': userid,
        },
      );

      print("Insert Account Closing Response Status: ${response.statusCode}");
      print("Insert Account Closing Response Body: ${response.body}");

      return _handleResponse(context, response.body);
    } catch (e) {
      print("Insert Account Closing Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
    }
  }

  // Fetch all account closings
  Future<List<AccountClosingModel>> fetchAccountClosings(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/account_closing_fetch.php');

    try {
      print("Fetching account closings for company: $companyid");

      var response = await http.post(
        url,
        body: {'companyid': companyid},
      );

      print("Fetch Account Closing Response Status: ${response.statusCode}");
      print("Fetch Account Closing Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data['status'] == 'success') {
          List<dynamic> items = data['data'] ?? [];
          List<AccountClosingModel> entries = items
              .map((item) => AccountClosingModel.fromJson(item))
              .toList();
          print("Fetched ${entries.length} account closing entries");
          return entries;
        } else {
          throw Exception(data['message'] ?? 'Failed to load account closings');
        }
      } else {
        throw Exception('Failed to load account closings: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Account Closing Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading account closings: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return [];
    }
  }

  // Handle API response
  String _handleResponse(BuildContext context, String responseBody) {
    print("Raw Response: $responseBody");

    if (responseBody.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Empty response from server"),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
    }

    try {
      var message = jsonDecode(responseBody);

      if (message["status"] == "success") {
        return "Success";
      } else {
        String errorMsg = message["message"] ?? "Unknown error";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
        return "Failed";
      }
    } catch (e) {
      print("Response Parse Error: $e");

      if (responseBody.toLowerCase().contains("success")) {
        return "Success";
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Server error: ${responseBody.length > 100 ? responseBody.substring(0, 100) + '...' : responseBody}"),
            backgroundColor: Colors.red,
          ),
        );
        return "Failed";
      }
    }
  }
}
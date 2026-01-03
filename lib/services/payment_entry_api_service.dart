import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/payment_entry_model.dart';
import './ac_ledger_apiservice.dart';
import 'config.dart';

class PaymentEntryApiService {
  final ACLedgerApiService _ledgerService = ACLedgerApiService();

  // Get next serial number (last serial + 1)
  Future<String> getNextSerialNo(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/payment_entry_get_last_serial.php');

    try {
      var response = await http.post(
        url,
        body: {'companyid': companyid},
      );

      print("Get Next Serial Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['next_serial'] ?? 'PYM-0001';
        }
      }
      return 'PYM-0001';
    } catch (e) {
      print("Get Serial Error: $e");
      return 'PYM-0001';
    }
  }


  Future<double> getAccountBalance(BuildContext context, String accountId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/account_balance_fetch.php');

    try {
      var response = await http.post(
        url,
        body: {
          'companyid': companyid,
          'account_id': accountId,
        },
      );

      print("Account Balance Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          return double.tryParse(data['balance']?.toString() ?? '0') ?? 0.0;
        } else {
          throw Exception(data['message'] ?? 'Failed to get balance');
        }
      }
      throw Exception('Failed to load balance: ${response.statusCode}');
    } catch (e) {
      print("Get Account Balance Error: $e");
      return 0.0;
    }
  }

  // Get payment accounts from AC Ledger table
  Future<List<Map<String, dynamic>>> getPaymentAccounts(BuildContext context) async {
    try {
      final ledgers = await _ledgerService.fetchLedgers(context);
      // Return both id and ledgername
      return ledgers.map((ledger) => {
        'id': ledger.id,
        'name': ledger.ledgername,
        'groupname': ledger.groupname,
      }).toList();
    } catch (e) {
      print("Get Payment Accounts Error: $e");
      return [];
    }
  }

  // Insert new payment entry
  Future<String> insertPaymentEntry({
    required BuildContext context,
    required String serialNo,
    required String date,
    required String paymentAccount,
    required String paymentAccountId,
    required String cashBank,
    required String amount,
    required String description,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    // First, check account balance
    try {
      double accountBalance = await getAccountBalance(context, paymentAccountId);
      double paymentAmount = double.tryParse(amount) ?? 0.0;

      if (paymentAmount > accountBalance) {
        return "Insufficient balance! Available: ₹${accountBalance.toStringAsFixed(2)}, Required: ₹${paymentAmount.toStringAsFixed(2)}";
      }
    } catch (e) {
      print("Balance check error: $e");
      // Continue even if balance check fails (for safety)
    }

    var url = Uri.parse('$baseUrl/payment_entry_insert.php');

    try {
      print("Insert Payment Data:");
      print("Company ID: $companyid");
      print("Serial No: $serialNo");
      print("Date: $date");
      print("Payment Account: $paymentAccount");
      print("Payment Account ID: $paymentAccountId");
      print("Cash/Bank: $cashBank");
      print("Amount: $amount");
      print("Description: $description");
      print("Added By: $userid");

      var response = await http.post(
        url,
        body: {
          'companyid': companyid,
          'serial_no': serialNo,
          'date': date,
          'payment_account': paymentAccount,
          'payment_account_id': paymentAccountId,
          'cash_bank': cashBank,
          'amount': amount,
          'description': description,
          'addedby': userid,
        },
      );

      print("Insert Payment Response Status: ${response.statusCode}");
      print("Insert Payment Response Body: ${response.body}");

      return _handleResponse(context, response.body);
    } catch (e) {
      print("Insert Payment Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
    }
  }

  // Update existing payment entry
  Future<String> updatePaymentEntry({
    required BuildContext context,
    required String paymentId,
    required String serialNo,
    required String date,
    required String paymentAccount,
    required String paymentAccountId,
    required String cashBank,
    required String amount,
    required String description,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    // For update, get old amount first to compare
    try {
      // Get the existing payment to compare amounts
      var oldPayment = await getPaymentById(context, paymentId);
      if (oldPayment != null) {
        double oldAmount = double.tryParse(oldPayment.amount) ?? 0.0;
        double newAmount = double.tryParse(amount) ?? 0.0;

        // Only check balance if the amount is increasing
        if (newAmount > oldAmount) {
          double difference = newAmount - oldAmount;
          double accountBalance = await getAccountBalance(context, paymentAccountId);

          if (difference > accountBalance) {
            return "Insufficient balance! Available: ₹${accountBalance.toStringAsFixed(2)}, Additional required: ₹${difference.toStringAsFixed(2)}";
          }
        }
      }
    } catch (e) {
      print("Balance check error during update: $e");
      // Continue even if balance check fails
    }

    var url = Uri.parse('$baseUrl/payment_entry_update.php');

    try {
      print("Update Payment Data:");
      print("Payment ID: $paymentId");
      print("Company ID: $companyid");
      print("Serial No: $serialNo");
      print("Date: $date");
      print("Payment Account: $paymentAccount");
      print("Payment Account ID: $paymentAccountId");
      print("Cash/Bank: $cashBank");
      print("Amount: $amount");
      print("Description: $description");
      print("Added By: $userid");

      var response = await http.post(
        url,
        body: {
          'payment_id': paymentId,
          'companyid': companyid,
          'serial_no': serialNo,
          'date': date,
          'payment_account': paymentAccount,
          'payment_account_id': paymentAccountId,
          'cash_bank': cashBank,
          'amount': amount,
          'description': description,
          'addedby': userid,
        },
      );

      print("Update Payment Response Status: ${response.statusCode}");
      print("Update Payment Response Body: ${response.body}");

      return _handleResponse(context, response.body);
    } catch (e) {
      print("Update Payment Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
    }
  }

  // Fetch all payment entries
  Future<List<PaymentEntryModel>> fetchPaymentEntries(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/payment_entry_fetch.php');

    try {
      print("Fetching payments for company: $companyid");

      var response = await http.post(
        url,
        body: {'companyid': companyid},
      );

      print("Fetch Payment Response Status: ${response.statusCode}");
      print("Fetch Payment Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data['status'] == 'success') {
          List<dynamic> items = data['data'] ?? [];
          List<PaymentEntryModel> entries = items
              .map((item) => PaymentEntryModel.fromJson(item))
              .toList();
          print("Fetched ${entries.length} payment entries");
          return entries;
        } else {
          throw Exception(data['message'] ?? 'Failed to load payment entries');
        }
      } else {
        throw Exception('Failed to load payment entries: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Payment Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading payment entries: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return [];
    }
  }

  // Delete payment entry
  Future<String> deletePaymentEntry(BuildContext context, String paymentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/payment_entry_delete.php');

    try {
      print("Delete Payment Data:");
      print("Payment ID: $paymentId");
      print("Company ID: $companyid");

      var response = await http.post(
        url,
        body: {
          'payment_id': paymentId,
          'companyid': companyid,
        },
      );

      print("Delete Payment Response Status: ${response.statusCode}");
      print("Delete Payment Response Body: ${response.body}");

      return _handleResponse(context, response.body);
    } catch (e) {
      print("Delete Payment Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
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

      // Try to check if it's a success message in plain text
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

  // Search payment entries
  Future<List<PaymentEntryModel>> searchPaymentEntries(
      BuildContext context,
      String searchQuery
      ) async {
    try {
      final allEntries = await fetchPaymentEntries(context);

      if (searchQuery.isEmpty) {
        return allEntries;
      }

      final query = searchQuery.toLowerCase();
      return allEntries.where((entry) {
        return entry.serialNo.toLowerCase().contains(query) ||
            entry.paymentAccount.toLowerCase().contains(query) ||
            entry.cashBank.toLowerCase().contains(query) ||
            entry.description.toLowerCase().contains(query);
      }).toList();
    } catch (e) {
      print("Search Payment Error: $e");
      return [];
    }
  }

  // Get payment entry by ID
  Future<PaymentEntryModel?> getPaymentById(BuildContext context, String paymentId) async {
    try {
      final allEntries = await fetchPaymentEntries(context);
      return allEntries.firstWhere(
            (entry) => entry.id == paymentId,
        orElse: () => PaymentEntryModel(
          id: '',
          companyid: '',
          serialNo: '',
          date: '',
          paymentAccount: '',
          paymentAccountId: '',
          cashBank: 'Cash',
          amount: '0.00',
          description: '',
          addedby: '',
          createdAt: '',
        ),
      );
    } catch (e) {
      print("Get Payment By ID Error: $e");
      return null;
    }
  }

  // Get payment entries by date range
  Future<List<PaymentEntryModel>> getPaymentsByDateRange(
      BuildContext context,
      String startDate,
      String endDate
      ) async {
    try {
      final allEntries = await fetchPaymentEntries(context);
      return allEntries.where((entry) {
        return entry.date.compareTo(startDate) >= 0 &&
            entry.date.compareTo(endDate) <= 0;
      }).toList();
    } catch (e) {
      print("Get Payments By Date Range Error: $e");
      return [];
    }
  }

  // Get total payment amount
  Future<double> getTotalPaymentAmount(BuildContext context) async {
    try {
      final entries = await fetchPaymentEntries(context);
      double total = 0.0;
      for (var entry in entries) {
        total += double.tryParse(entry.amount) ?? 0.0;
      }
      return total;
    } catch (e) {
      print("Get Total Payment Amount Error: $e");
      return 0.0;
    }
  }

  // Get payment summary by cash/bank
  Future<Map<String, double>> getPaymentSummary(BuildContext context) async {
    try {
      final entries = await fetchPaymentEntries(context);
      Map<String, double> summary = {'Cash': 0.0, 'Bank': 0.0};

      for (var entry in entries) {
        String type = entry.cashBank;
        double amount = double.tryParse(entry.amount) ?? 0.0;
        summary[type] = (summary[type] ?? 0.0) + amount;
      }

      return summary;
    } catch (e) {
      print("Get Payment Summary Error: $e");
      return {'Cash': 0.0, 'Bank': 0.0};
    }
  }

  // Validate payment data before submission
  String? validatePaymentData({
    required String serialNo,
    required String date,
    required String paymentAccountId,
    required String amount,
  }) {
    if (serialNo.isEmpty) {
      return "Serial number is required";
    }
    if (date.isEmpty) {
      return "Date is required";
    }
    if (paymentAccountId.isEmpty) {
      return "Payment account is required";
    }
    if (amount.isEmpty) {
      return "Amount is required";
    }

    final amt = double.tryParse(amount);
    if (amt == null || amt <= 0) {
      return "Please enter a valid amount";
    }

    return null;
  }
}
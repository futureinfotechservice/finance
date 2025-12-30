// lib/services/customer_apiservice.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../masters/customermaster.dart';
import 'config.dart';

class loanhistory_apiservice {

// Add these methods to your collection_apiservice.dart

  Future<Map<String, dynamic>> fetchCustomerDetails(
      BuildContext context, String customerId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/customer_details.php');
    try {
      var response = await http.post(
        url,
        body: {
          'companyid': companyid,
          'customerid': customerId,
        },
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return responseData;
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load customer details: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Customer Details Error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchLoanHistoryReport({
    required BuildContext context,
    String? customerId,
    String? loanNo,
    String? fromDate,
    String? toDate,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/loan_history_report.php');

    Map<String, String> body = {'companyid': companyid};

    if (customerId != null && customerId.isNotEmpty) {
      body['customerid'] = customerId;
    }
    if (loanNo != null && loanNo.isNotEmpty) {
      body['loanno'] = loanNo;
    }
    if (fromDate != null && fromDate.isNotEmpty) {
      body['fromdate'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) {
      body['todate'] = toDate;
    }

    try {
      var response = await http.post(url, body: body);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return responseData;
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load loan history: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Loan History Error: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllCustomers(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/fetch_all_customers.php');
    try {
      var response = await http.post(
        url,
        body: {'companyid': companyid},
      );

      print("Customers Response: ${response.body}");

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          List<dynamic> items = responseData['customers'];

          List<Map<String, dynamic>> customersList = [];

          for (var item in items) {
            if (item is Map<String, dynamic>) {
              customersList.add({
                'id': item['id']?.toString() ?? '',
                'customername': item['customername']?.toString() ?? '',
                'mobile1': item['mobile1']?.toString() ?? '',
                'display': '${item['customername']?.toString() ?? ''} (${item['mobile1']?.toString() ?? ''})',
              });
            }
          }

          print("✅ Processed ${customersList.length} customers");
          return customersList;
        } else {
          print("❌ API returned error: ${responseData['message']}");
          return [];
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Fetch Customers Error: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchCustomerLoans(
      BuildContext context, String customerId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/fetch_customer_loans.php');
    try {
      var response = await http.post(
        url,
        body: {
          'companyid': companyid,
          'customerid': customerId,
        },
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          List<dynamic> items = responseData['loans'];

          List<Map<String, dynamic>> loansList = [];

          for (var item in items) {
            if (item is Map<String, dynamic>) {
              loansList.add({
                'id': item['id']?.toString() ?? '',
                'loanno': item['loanno']?.toString() ?? '',
                'loanamount': item['loanamount']?.toString() ?? '0',
                'display': item['loanno']?.toString() ?? '',
              });
            }
          }

          return loansList;
        } else {
          print("❌ API returned error: ${responseData['message']}");
          return [];
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Fetch Customer Loans Error: $e");
      return [];
    }
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class datewiseloan_apiservice {
  Future<Map<String, dynamic>> fetchDateWiseLoans({
    required String companyid,
    String? fromDate,
    String? toDate,
    String? customerId,
    String? searchQuery,
  }) async {
    var url = Uri.parse('$baseUrl/loan_fetch_datewise.php');

    Map<String, String> body = {'companyid': companyid};

    if (fromDate != null && fromDate.isNotEmpty) {
      body['fromdate'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) {
      body['todate'] = toDate;
    }
    if (customerId != null && customerId.isNotEmpty) {
      body['customerid'] = customerId;
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      body['search'] = searchQuery;
    }

    try {
      var response = await http.post(url, body: body);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to load loans: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Date Wise Loans Error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchCustomers({required String companyid}) async {
    var url = Uri.parse('$baseUrl/customer_fetch_all.php');

    try {
      var response = await http.post(
        url,
        body: {'companyid': companyid},
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to load customers: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Customers Error: $e");
      rethrow;
    }
  }
}

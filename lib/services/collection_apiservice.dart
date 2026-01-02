import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class collectionapiservice{
  Future<Map<String, dynamic>> fetchLoanForCollection(BuildContext context, String loanNo) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/collection_fetch3.php');
    try {
      var response = await http.post(
        url,
        body: {
          'companyid': companyid,
          'loanno': loanNo,
        },
      );

      print("Collection Fetch Response: ${response.body}");

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return responseData;
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load loan details: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Loan for Collection Error: $e");
      rethrow;
    }
  }

  String _handleResponse(BuildContext context, String responseBody) {
    try {
      var message = jsonDecode(responseBody);

      if (message["status"] == "success") {
        return "Success";
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message["message"] ?? "Unknown error"),
            backgroundColor: Colors.red,
          ),
        );
        return "Failed";
      }
    } catch (e) {
      print("Response Parse Error: $e");
      print("Raw Response: $responseBody");

      if (responseBody.toLowerCase().contains("success")) {
        return "Success";
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Server error"),
            backgroundColor: Colors.red,
          ),
        );
        return "Failed";
      }
    }
  }
// Add this method to collection_apiservice.dart
  Future<Map<String, dynamic>> fetchDueDatePendingReport({
    required BuildContext context,
    String? dueDate,
    String? searchQuery,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/due_date_pending_report.php');

    Map<String, String> body = {'companyid': companyid};

    if (dueDate != null && dueDate.isNotEmpty) {
      body['dueDate'] = dueDate;
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      body['search'] = searchQuery;
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
        throw Exception('Failed to load due date pending report: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Due Date Pending Report Error: $e");
      rethrow;
    }
  }


  Future<Map<String, dynamic>> fetchCollectionHistory({
    required BuildContext context,
    String? fromDate,
    String? toDate,
    String? searchQuery,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/collection_history_report.php');

    Map<String, String> body = {'companyid': companyid};

    if (fromDate != null && fromDate.isNotEmpty) {
      body['fromdate'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) {
      body['todate'] = toDate;
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      body['search'] = searchQuery;
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
        throw Exception('Failed to load collection history: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Collection History Error: $e");
      rethrow;
    }
  }


  Future<Map<String, dynamic>> fetchOutstandingReport({
    required BuildContext context,
    String? searchQuery,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/outstanding_report.php');

    Map<String, String> body = {'companyid': companyid};

    if (searchQuery != null && searchQuery.isNotEmpty) {
      body['search'] = searchQuery;
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
        throw Exception('Failed to load outstanding report: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Outstanding Report Error: $e");
      rethrow;
    }
  }

// In the recordCollection method, ensure you're sending paidamount:
  Future<String> recordCollection({
    required BuildContext context,
    required String loanId,
    required List<Map<String, dynamic>> paymentData,
    required String collectionDate,
    required String paymentMode,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    // var url = Uri.parse('$baseUrl/collection_insert1.php');
    var url = Uri.parse('$baseUrl/collection_insert3.php');
    try {
      var response = await http.post(
        url,
        body: {
          'companyid': companyid,
          'loanid': loanId,
          'paymentdata': json.encode(paymentData), // This now includes paidamount
          'collectiondate': collectionDate,
          'paymentmode': paymentMode,
          'collectedby': userid,
        },
      );

      print("Collection Insert Response: ${response.body}");
      return _handleResponse(context, response.body);
    } catch (e) {
      print("Record Collection Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
    }
  }
  // Future<String> recordCollection({
  //   required BuildContext context,
  //   required String loanId,
  //   required List<Map<String, dynamic>> paymentData,
  //   required String collectionDate,
  //   required String paymentMode,
  // }) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final companyid = prefs.getString('companyid') ?? '';
  //   final userid = prefs.getString('id') ?? '';
  //
  //   var url = Uri.parse('$baseUrl/collection_insert.php');
  //   try {
  //     var response = await http.post(
  //       url,
  //       body: {
  //         'companyid': companyid,
  //         'loanid': loanId,
  //         'paymentdata': json.encode(paymentData),
  //         'collectiondate': collectionDate,
  //         'paymentmode': paymentMode,
  //         'collectedby': userid,
  //       },
  //     );
  //
  //     print("Collection Insert Response: ${response.body}");
  //
  //     return _handleResponse(context, response.body);
  //   } catch (e) {
  //     print("Record Collection Error: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text("Error: $e"),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return "Failed";
  //   }
  // }
  Future<String> generateCollectionNo(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    try {
      var url = Uri.parse('$baseUrl/collection_generate_no.php');
      var response = await http.post(
        url,
        body: {'companyid': companyid},
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return responseData['collectionno'];
        }
      }
      return '';
    } catch (e) {
      print("Generate Collection No Error: $e");
      return '';
    }
  }

  Future<List<Map<String, dynamic>>> fetchActiveLoans(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/loan_fetch_active.php');
    try {
      var response = await http.post(
        url,
        body: {'companyid': companyid},
      );

      print("Active Loans Response: ${response.body}");

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          List<dynamic> items = responseData['loans'];

          // Properly map the items to ensure they are Maps, not functions
          List<Map<String, dynamic>> loansList = [];

          for (var item in items) {
            if (item is Map<String, dynamic>) {
              loansList.add({
                'id': item['id']?.toString() ?? '',
                'loanno': item['loanno']?.toString() ?? '',
                'customername': item['customername']?.toString() ?? '',
                'loanamount': item['loanamount']?.toString() ?? '0',
                'display': '${item['loanno']?.toString() ?? ''} - ${item['customername']?.toString() ?? ''}',
              });
            }
          }

          print("✅ Processed ${loansList.length} active loans");
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
      print("❌ Fetch Active Loans Error: $e");
      return [];
    }
  }


  Future<List<CollectionModel>> fetchCollections(BuildContext context, {String? fromDate, String? toDate}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/collection_fetch_all.php');
    Map<String, String> body = {'companyid': companyid};

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
          List<dynamic> items = responseData['collections'];
          return items.map((item) => CollectionModel.fromJson(item)).toList();
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load collections: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Collections Error: $e");
      rethrow;
    }
  }


  // Updated cash ledger report with ledger_id parameter
  Future<Map<String, dynamic>> fetchCashLedgerReport({
    required BuildContext context,
    String? fromDate,
    String? toDate,
    String? ledgerId, // Changed from customerName to ledgerId
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/cash_ledger_report.php');

    Map<String, String> body = {'companyid': companyid};

    if (fromDate != null && fromDate.isNotEmpty) {
      body['fromDate'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) {
      body['toDate'] = toDate;
    }
    if (ledgerId != null && ledgerId.isNotEmpty) {
      body['ledgerId'] = ledgerId;
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
        throw Exception('Failed to load cash ledger report: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Cash Ledger Report Error: $e");
      rethrow;
    }
  }


  Future<List<Map<String, dynamic>>> fetchAllLedgers(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/get_ledgers.php');

    try {
      var response = await http.post(
        url,
        body: {'companyid': companyid},
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          List<dynamic> items = responseData['ledgers'];
          return items.map((item) => {
            'id': item['id'].toString(),
            'ledgerName': item['ledgerName']?.toString() ?? '',
            'groupName': item['groupName']?.toString() ?? '',
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print("Fetch Ledgers Error: $e");
      return [];
    }
  }


}

class CollectionModel {
  final String id;
  final String collectionno;
  final String loanno;
  final String customername;
  final String collectiondate;
  final String totalamount;
  final String totalpenalty;
  final String paymentmode;

  CollectionModel({
    required this.id,
    required this.collectionno,
    required this.loanno,
    required this.customername,
    required this.collectiondate,
    required this.totalamount,
    required this.totalpenalty,
    required this.paymentmode,
  });

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    return CollectionModel(
      id: json['id']?.toString() ?? '',
      collectionno: json['collectionno']?.toString() ?? '',
      loanno: json['loanno']?.toString() ?? '',
      customername: json['customername']?.toString() ?? '',
      collectiondate: json['collectiondate']?.toString() ?? '',
      totalamount: json['totalamount']?.toString() ?? '0',
      totalpenalty: json['totalpenalty']?.toString() ?? '0',
      paymentmode: json['paymentmode']?.toString() ?? 'Cash',
    );
  }
}
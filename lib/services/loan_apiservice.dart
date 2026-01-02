import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class LoanApiService {

  Future<String> insertLoan({
    required BuildContext context,
    required String customerId,
    required String loanTypeId,
    required String loanAmount,
    required String givenAmount,
    required String interestAmount,
    required String loanDay,
    required String noOfWeeks,
    required String penaltyamount,
    required String paymentMode,
    required String startDate,
    required List<Map<String, dynamic>> scheduleData, // Add this parameter
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    var url = Uri.parse('$baseUrl/loan_insert2.php');

    try {
      var response = await http.post(
        url,
        body: {
          'companyid': companyid,
          'customerid': customerId,
          'loantypeid': loanTypeId,
          'loanamount': loanAmount,
          'givenamount': givenAmount,
          'interestamount': interestAmount,
          'loanday': loanDay,
          'noofweeks': noOfWeeks,
          'penaltyamount': penaltyamount,
          'paymentmode': paymentMode,
          'startdate': startDate,
          'addedby': userid,
          'schedule': json.encode(scheduleData), // Add schedule data
        },
      );

      print("Loan Insert Response: ${response.body}");

      // Log schedule data
      print("Schedule data sent: ${scheduleData.length} items");
      for (var item in scheduleData) {
        print("  Week ${item['dueNo']}: ${item['dueDate']} - ₹${item['dueAmount']}");
      }

      return _handleResponse(context, response.body);
    } catch (e) {
      print("Loan Insert Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
    }
  }
  // Future<String> insertLoan({
  //   required BuildContext context,
  //   required String customerId,
  //   required String loanTypeId,
  //   required String loanAmount,
  //   required String givenAmount,
  //   required String interestAmount,
  //   required String loanDay,
  //   required String noOfWeeks,
  //   required String paymentMode,
  //   required String startDate,
  // }) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final companyid = prefs.getString('companyid') ?? '';
  //   final userid = prefs.getString('id') ?? '';
  //
  //   var url = Uri.parse('$baseUrl/loan_insert.php');
  //
  //   try {
  //     var response = await http.post(
  //       url,
  //       body: {
  //         'companyid': companyid,
  //         'customerid': customerId,
  //         'loantypeid': loanTypeId,
  //         'loanamount': loanAmount,
  //         'givenamount': givenAmount,
  //         'interestamount': interestAmount,
  //         'loanday': loanDay,
  //         'noofweeks': noOfWeeks,
  //         'paymentmode': paymentMode,
  //         'startdate': startDate,
  //         'addedby': userid,
  //       },
  //     );
  //
  //     print("Loan Insert Response: ${response.body}");
  //
  //     return _handleResponse(context, response.body);
  //   } catch (e) {
  //     print("Loan Insert Error: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text("Error: $e"),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return "Failed";
  //   }
  // }

  Future<List<LoanModel>> fetchLoans(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/loan_fetch.php');
    try {
      var response = await http.post(
        url,
        body: {'companyid': companyid},
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          List<dynamic> items = responseData['loans'];
          return items.map((item) => LoanModel.fromJson(item)).toList();
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load loans: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Loans Error: $e");
      rethrow;
    }
  }

  Future<String> generateLoanNo(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    try {
      var url = Uri.parse('$baseUrl/loan_generate_no.php');
      var response = await http.post(
        url,
        body: {'companyid': companyid},
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return responseData['loanno'];
        }
      }
      return '';
    } catch (e) {
      print("Generate Loan No Error: $e");
      return '';
    }
  }

  Future<String> deleteLoan(BuildContext context, String loanId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/loan_delete.php');
    try {
      var response = await http.post(
        url,
        body: {
          'loanid': loanId,
          'companyid': companyid,
        },
      );

      return _handleResponse(context, response.body);
    } catch (e) {
      print("Delete Loan Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
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

  // Add fetchLoanTypes method if not already in your service
  Future<List<LoanTypeModel>> fetchLoanTypes(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/loantype_fetch.php');
    try {
      var response = await http.post(
        url,
        body: {'companyid': companyid},
      );

      print("Loan Types Response: ${response.body}");

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);

        // Check the response format
        if (responseData['status'] == 'success') {
          // Handle both formats: direct array or nested in 'loanTypes'
          List<dynamic> items;
          if (responseData['loanTypes'] != null) {
            items = responseData['loanTypes'];
          } else if (responseData is List) {
            items = responseData;
          } else {
            items = [];
          }

          return items.map((item) => LoanTypeModel.fromJson(item)).toList();
        } else {
          // Return empty list if error
          print("Error fetching loan types: ${responseData['message']}");
          return [];
        }
      } else {
        print("HTTP Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Fetch Loan Types Error: $e");
      // Return empty list instead of throwing
      return [];
    }
  }
}

class LoanModel {
  final String id;
  final String loanno;
  final String customername;
  final String loantype;
  final String loanamount;
  final String givenamount;
  final String interestamount;
  final String loanday;
  final String noofweeks;
  final String paymentmode;
  final String startdate;
  final String loanstatus;

  LoanModel({
    required this.id,
    required this.loanno,
    required this.customername,
    required this.loantype,
    required this.loanamount,
    required this.givenamount,
    required this.interestamount,
    required this.loanday,
    required this.noofweeks,
    required this.paymentmode,
    required this.startdate,
    required this.loanstatus,
  });

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      id: json['id']?.toString() ?? '',
      loanno: json['loanno']?.toString() ?? '',
      customername: json['customername']?.toString() ?? '',
      loantype: json['loantype']?.toString() ?? '',
      loanamount: json['loanamount']?.toString() ?? '0',
      givenamount: json['givenamount']?.toString() ?? '0',
      interestamount: json['interestamount']?.toString() ?? '0',
      loanday: json['loanday']?.toString() ?? '',
      noofweeks: json['noofweeks']?.toString() ?? '0',
      paymentmode: json['paymentmode']?.toString() ?? 'Cash',
      startdate: json['startdate']?.toString() ?? '',
      loanstatus: json['loanstatus']?.toString() ?? 'Active',
    );
  }
}

class LoanTypeModel {
  final String id;
  final String loantype;
  final String collectionday;
  final String noofweeks;
  final String penaltyamount;

  LoanTypeModel({
    required this.id,
    required this.loantype,
    required this.collectionday,
    required this.noofweeks,
    required this.penaltyamount,
  });

  factory LoanTypeModel.fromJson(Map<String, dynamic> json) {
    // Extract just the number from "12 Weeks" format
    String rawNoOfWeeks = json['noofweeks']?.toString() ?? '';
    String extractedWeeks = rawNoOfWeeks;

    // Extract numeric part (e.g., "12" from "12 Weeks")
    if (rawNoOfWeeks.isNotEmpty) {
      final regex = RegExp(r'(\d+)');
      final match = regex.firstMatch(rawNoOfWeeks);
      if (match != null) {
        extractedWeeks = match.group(1)!;
      }
    }

    return LoanTypeModel(
      id: json['id']?.toString() ?? '',
      loantype: json['loantype']?.toString() ?? '',
      collectionday: json['collectionday']?.toString() ?? '',
      noofweeks: extractedWeeks, // Use extracted number
      penaltyamount: json['penaltyamount']?.toString() ?? '0',
    );
  }
}
// lib/services/loantype_apiservice.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class LoanTypeModel {
  String id;
  String companyid;
  String loantype;
  String collectionday;
  String penaltyamount;
  String noofweeks;
  String addedby;

  LoanTypeModel({
    required this.id,
    required this.companyid,
    required this.loantype,
    required this.collectionday,
    required this.penaltyamount,
    required this.noofweeks,
    required this.addedby,
  });

  factory LoanTypeModel.fromJson(Map<String, dynamic> json) {
    return LoanTypeModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      loantype: json['loantype']?.toString() ?? '',
      collectionday: json['collectionday']?.toString() ?? '',
      penaltyamount: json['penaltyamount']?.toString() ?? '',
      noofweeks: json['noofweeks']?.toString() ?? '',
      addedby: json['addedby']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyid,
      'loantype': loantype,
      'collectionday': collectionday,
      'penaltyamount': penaltyamount,
      'noofweeks': noofweeks,
      'addedby': addedby,
    };
  }
}

class LoantypeApiService {

  Future<String> insertLoanType({
    required BuildContext context,
    required String loantype,
    required String collectionday,
    required String penaltyamount,
    required String noofweeks,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    var url = Uri.parse('$baseUrl/loan_type_insert.php');

    try {
      var response = await http.post(
        url,
        body: {
          'companyid': companyid,
          'loantype': loantype,
          'collectionday': collectionday,
          'penaltyamount': penaltyamount,
          'noofweeks': noofweeks,
          'addedby': userid,
        },
      );

      print("Insert Response: ${response.body}");

      return _handleResponse(context, response.body);

    } catch (e) {
      print("Insert Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
    }
  }

  Future<String> updateLoanType({
    required BuildContext context,
    required String loanTypeId,
    required String loantype,
    required String collectionday,
    required String penaltyamount,
    required String noofweeks,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    var url = Uri.parse('$baseUrl/loan_type_update.php');

    try {
      var response = await http.post(
        url,
        body: {
          'loantypeid': loanTypeId,
          'companyid': companyid,
          'loantype': loantype,
          'collectionday': collectionday,
          'penaltyamount': penaltyamount,
          'noofweeks': noofweeks,
          'addedby': userid,
        },
      );

      print("Update Response: ${response.body}");

      return _handleResponse(context, response.body);

    } catch (e) {
      print("Update Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
    }
  }

  Future<List<LoanTypeModel>> fetchLoanTypes(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/loan_type_fetch.php');

    try {
      var response = await http.post(
        url,
        body: {
          'companyid': companyid,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> items = json.decode(response.body);
        List<LoanTypeModel> loanTypes = items.map((item) =>
            LoanTypeModel.fromJson(item)).toList();
        return loanTypes;
      } else {
        throw Exception('Failed to load loan types: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading loan types: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return [];
    }
  }

  Future<String> deleteLoanType(BuildContext context, String loanTypeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/loan_type_delete.php');

    try {
      var response = await http.post(
        url,
        body: {
          'loantypeid': loanTypeId,
          'companyid': companyid,
        },
      );

      print("Delete Response: ${response.body}");

      return _handleResponse(context, response.body);

    } catch (e) {
      print("Delete Error: $e");
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

      // Try to extract success from plain text
      if (responseBody.toLowerCase().contains("success")) {
        return "Success";
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Server error: $responseBody"),
            backgroundColor: Colors.red,
          ),
        );
        return "Failed";
      }
    }
  }
}
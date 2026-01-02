// lib/services/ac_ledger_apiservice.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class ACLedgerModel {
  String id;
  String companyid;
  String ledgername;
  String groupname;
  String opening;
  String type; // Add this field

  ACLedgerModel({
    required this.id,
    required this.companyid,
    required this.ledgername,
    required this.groupname,
    required this.opening,
    required this.type, // Add this
  });

  factory ACLedgerModel.fromJson(Map<String, dynamic> json) {
    return ACLedgerModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      ledgername: json['ledgername']?.toString() ?? '',
      groupname: json['groupname']?.toString() ?? '',
      opening: json['opening']?.toString() ?? '0',
      type: json['type']?.toString() ?? 'credit', // Default to credit
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyid': companyid,
      'ledgername': ledgername,
      'groupname': groupname,
      'opening': opening,
      'type': type, // Add this
    };
  }
}

class ACLedgerApiService {

  Future<String> insertLedger({
    required BuildContext context,
    required String ledgername,
    required String groupname,
    required String opening,
    required String type, // Add this parameter
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    var url = Uri.parse('$baseUrl/ac_ledger_insert1.php');

    try {
      var response = await http.post(
        url,
        body: {
          'companyid': companyid,
          'ledgername': ledgername,
          'groupname': groupname,
          'opening': opening,
          'type': type, // Add this
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

  Future<String> updateLedger({
    required BuildContext context,
    required String ledgerId,
    required String ledgername,
    required String groupname,
    required String opening,
    required String type, // Add this parameter
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    var url = Uri.parse('$baseUrl/ac_ledger_update1.php');

    try {
      var response = await http.post(
        url,
        body: {
          'ledgerid': ledgerId,
          'companyid': companyid,
          'ledgername': ledgername,
          'groupname': groupname,
          'opening': opening,
          'type': type, // Add this
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

  Future<List<ACLedgerModel>> fetchLedgers(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/ac_ledger_fetch.php');

    try {
      var response = await http.post(
        url,
        body: {
          'companyid': companyid,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> items = json.decode(response.body);
        List<ACLedgerModel> ledgers = items.map((item) =>
            ACLedgerModel.fromJson(item)).toList();
        return ledgers;
      } else {
        throw Exception('Failed to load ledgers: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading ledgers: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return [];
    }
  }

  Future<String> deleteLedger(BuildContext context, String ledgerId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/ac_ledger_delete.php');

    try {
      var response = await http.post(
        url,
        body: {
          'ledgerid': ledgerId,
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

  // List of group types
  static final List<String> groupTypes = [
    'DUTIES AND TAXES',
    'UNSECURED LOANS',
    'SECURED LOANS',
    'SUNDRY CREDITORS OTHERS',
    'SUNDRY CREDITORS EXPENSES',
    'SUNDRY CREDITORS TRADE',
    'SUNDRY DEBTORS',
    'BANK ACCOUNTS',
    'CASH ACCOUNTS',
    'PURCHASE ACCOUNTS',
    'INDIRECT EXPENSES',
    'DIRECT EXPENSES',
    'SALES ACCOUNTS',
    'INDIRECT INCOME',
    'DIRECT INCOME',
    'CURRENT LIABILITIES',
    'CAPITAL ACCOUNT',
    'STOCK ACCOUNTS',
    'ADVANCES AND DEPOSIT',
    'CURRENT ASSETS',
    'FIXED ASSETS',
    'EXPENSE',
    'INCOME',
    'LIABILITY',
    'ASSET'
  ];

  // Add type options list
  static final List<String> typeOptions = ['Credit', 'Debit'];
}
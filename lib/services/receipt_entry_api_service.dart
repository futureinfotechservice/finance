import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/receipt_entry_model.dart';
import './ac_ledger_apiservice.dart';
import 'config.dart';

class ReceiptEntryApiService {
  final ACLedgerApiService _ledgerService = ACLedgerApiService();

  // Get next serial number (last serial + 1)
  Future<String> getNextSerialNo(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/receipt_entry_get_last_serial.php');

    try {
      var response = await http.post(
        url,
        body: {'companyid': companyid},
      );

      print("Get Next Serial Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['next_serial'] ?? 'RCP-0001';
        }
      }
      return 'RCP-0001';
    } catch (e) {
      print("Get Serial Error: $e");
      return 'RCP-0001';
    }
  }

  // Get receipt from accounts from AC Ledger table
  Future<List<Map<String, dynamic>>> getReceiptFromAccounts(BuildContext context) async {
    try {
      final ledgers = await _ledgerService.fetchLedgers(context);
      // Return both id and ledgername
      return ledgers.map((ledger) => {
        'id': ledger.id,
        'name': ledger.ledgername,
        'groupname': ledger.groupname,
      }).toList();
    } catch (e) {
      print("Get Receipt From Accounts Error: $e");
      return [];
    }
  }

  // Insert new receipt entry
  Future<String> insertReceiptEntry({
    required BuildContext context,
    required String serialNo,
    required String date,
    required String receiptFrom,
    required String receiptFromId,
    required String cashBank,
    required String amount,
    required String description,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    var url = Uri.parse('$baseUrl/receipt_entry_insert.php');

    try {
      print("Insert Receipt Data:");
      print("Company ID: $companyid");
      print("Serial No: $serialNo");
      print("Date: $date");
      print("Receipt From: $receiptFrom");
      print("Receipt From ID: $receiptFromId");
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
          'receipt_from': receiptFrom,
          'receipt_from_id': receiptFromId,
          'cash_bank': cashBank,
          'amount': amount,
          'description': description,
          'addedby': userid,
        },
      );

      print("Insert Receipt Response Status: ${response.statusCode}");
      print("Insert Receipt Response Body: ${response.body}");

      return _handleResponse(context, response.body);
    } catch (e) {
      print("Insert Receipt Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
    }
  }

  // Update existing receipt entry
  Future<String> updateReceiptEntry({
    required BuildContext context,
    required String receiptId,
    required String serialNo,
    required String date,
    required String receiptFrom,
    required String receiptFromId,
    required String cashBank,
    required String amount,
    required String description,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';
    final userid = prefs.getString('id') ?? '';

    var url = Uri.parse('$baseUrl/receipt_entry_update.php');

    try {
      print("Update Receipt Data:");
      print("Receipt ID: $receiptId");
      print("Company ID: $companyid");
      print("Serial No: $serialNo");
      print("Date: $date");
      print("Receipt From: $receiptFrom");
      print("Receipt From ID: $receiptFromId");
      print("Cash/Bank: $cashBank");
      print("Amount: $amount");
      print("Description: $description");
      print("Added By: $userid");

      var response = await http.post(
        url,
        body: {
          'receipt_id': receiptId,
          'companyid': companyid,
          'serial_no': serialNo,
          'date': date,
          'receipt_from': receiptFrom,
          'receipt_from_id': receiptFromId,
          'cash_bank': cashBank,
          'amount': amount,
          'description': description,
          'addedby': userid,
        },
      );

      print("Update Receipt Response Status: ${response.statusCode}");
      print("Update Receipt Response Body: ${response.body}");

      return _handleResponse(context, response.body);
    } catch (e) {
      print("Update Receipt Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return "Failed";
    }
  }

  // Fetch all receipt entries
  Future<List<ReceiptEntryModel>> fetchReceiptEntries(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/receipt_entry_fetch.php');

    try {
      print("Fetching receipts for company: $companyid");

      var response = await http.post(
        url,
        body: {'companyid': companyid},
      );

      print("Fetch Receipt Response Status: ${response.statusCode}");
      print("Fetch Receipt Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data['status'] == 'success') {
          List<dynamic> items = data['data'] ?? [];
          List<ReceiptEntryModel> entries = items
              .map((item) => ReceiptEntryModel.fromJson(item))
              .toList();
          print("Fetched ${entries.length} receipt entries");
          return entries;
        } else {
          throw Exception(data['message'] ?? 'Failed to load receipt entries');
        }
      } else {
        throw Exception('Failed to load receipt entries: ${response.statusCode}');
      }
    } catch (e) {
      print("Fetch Receipt Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading receipt entries: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return [];
    }
  }

  // Delete receipt entry
  Future<String> deleteReceiptEntry(BuildContext context, String receiptId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final companyid = prefs.getString('companyid') ?? '';

    var url = Uri.parse('$baseUrl/receipt_entry_delete.php');

    try {
      print("Delete Receipt Data:");
      print("Receipt ID: $receiptId");
      print("Company ID: $companyid");

      var response = await http.post(
        url,
        body: {
          'receipt_id': receiptId,
          'companyid': companyid,
        },
      );

      print("Delete Receipt Response Status: ${response.statusCode}");
      print("Delete Receipt Response Body: ${response.body}");

      return _handleResponse(context, response.body);
    } catch (e) {
      print("Delete Receipt Error: $e");
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
}
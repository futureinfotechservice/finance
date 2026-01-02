import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/config.dart';
import '../services/loanhistory_apiservice.dart';


class LoanHistoryDetailScreen extends StatefulWidget {
  const LoanHistoryDetailScreen({super.key});

  @override
  State<LoanHistoryDetailScreen> createState() => _LoanHistoryDetailScreenState();
}

class _LoanHistoryDetailScreenState extends State<LoanHistoryDetailScreen> {
  final collectionApiService = loanhistory_apiservice();

  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> customerLoans = [];
  Map<String, dynamic>? selectedCustomer;
  Map<String, dynamic>? selectedLoan;
  Map<String, dynamic>? loanData;
  List<dynamic> scheduleData = [];

  // Summary variables
  double totalLoanAmount = 0;
  double totalPaid = 0;
  double totalPenalty = 0;
  double totalPenaltyPaid = 0;

  // Controllers
  TextEditingController customerController = TextEditingController();
  TextEditingController loanController = TextEditingController();
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();

  // Checkbox states
  List<bool> selectedRows = [];

  bool isLoading = false;
  bool showSchedule = false;

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    setState(() => isLoading = true);
    try {
      final result = await collectionApiService.fetchAllCustomers(context);
      setState(() {
        customers = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load customers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchCustomerLoans(String customerId) async {
    setState(() => isLoading = true);
    try {
      final result = await collectionApiService.fetchCustomerLoans(context, customerId);
      setState(() {
        customerLoans = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load loans: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchLoanHistory() async {
    if (selectedCustomer == null || selectedLoan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select customer and loan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      loanData = null;
      scheduleData = [];
      selectedRows = [];
    });

    try {
      final response = await collectionApiService.fetchLoanHistoryReport(
        context: context,
        customerId: selectedCustomer!['id'],
        loanNo: selectedLoan!['loanno'],
        fromDate: fromDateController.text.isNotEmpty ? fromDateController.text : null,
        toDate: toDateController.text.isNotEmpty ? toDateController.text : null,
      );

      if (response['status'] == 'success') {
        setState(() {
          loanData = response['loan_data'];
          scheduleData = response['loan_data']['schedule'] ?? [];
          showSchedule = true;

          // Initialize checkbox states
          selectedRows = List.generate(scheduleData.length, (index) => false);

          // Calculate totals
          totalLoanAmount = double.tryParse(loanData?['loanamount']?.toString() ?? '0') ?? 0;
          totalPaid = double.tryParse(loanData?['total_paid']?.toString() ?? '0') ?? 0;
          totalPenalty = double.tryParse(loanData?['total_penalty_paid']?.toString() ?? '0') ?? 0;
          totalPenaltyPaid = double.tryParse(loanData?['total_penalty_received']?.toString() ?? '0') ?? 0;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load loan history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }

  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildInfoRow(String label, String value, {bool isCurrency = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 370,
          height: 47,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            isCurrency ? formatCurrency(double.tryParse(value) ?? 0) : value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  String _shouldShowPenaltyRecDate(String status, String penaltyReceiptDate) {
    // If status is "Partially Paid Penalty" or "Penalty Paid", show penalty receipt date
    if (status == 'Partially Paid Penalty' || status == 'Penalty Paid') {
      return penaltyReceiptDate.isNotEmpty ? formatDate(penaltyReceiptDate) : '-';
    }
    // Otherwise, show "-"
    return '-';
  }

  String _shouldShowRecDate(String status, String collectionDate) {
    // If status is "Partially Paid Penalty" or "Penalty Paid", don't show collection date
    if (status == 'Partially Paid Penalty' || status == 'Penalty Paid') {
      return '-';
    }
    // Otherwise, show collection date if available
    return collectionDate.isNotEmpty ? formatDate(collectionDate) : '-';
  }


  Widget _buildScheduleTable() {
    if (scheduleData.isEmpty) {
      return const Center(
        child: Text(
          'No schedule data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1200,
        child: Column(
          children: [
            // Table Header
            Container(
              height: 49,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Checkbox(
                      value: selectedRows.every((element) => element),
                      onChanged: (value) {
                        setState(() {
                          for (int i = 0; i < selectedRows.length; i++) {
                            selectedRows[i] = value ?? false;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: const Text(
                      'Due No',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: const Text(
                      'Due Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: const Text(
                      'Due Amt',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: const Text(
                      'Rec Amt',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: const Text(
                      'Rec Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: const Text(
                      'Loan Bal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: const Text(
                      'Pen Amt',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: const Text(
                      'Pen Rec',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),

                  SizedBox(
                    width: 120,
                    child: const Text(
                      'Pen Rec Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),

                  SizedBox(
                    width: 100,
                    child: const Text(
                      'Pen Bal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: const Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Table Rows
            ...scheduleData.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              final dueAmount = double.tryParse(item['dueamount']?.toString() ?? '0') ?? 0;
              final paidAmount = double.tryParse(item['paidamount']?.toString() ?? '0') ?? 0;
              final penaltyAmount = double.tryParse(item['penaltypaid']?.toString() ?? '0') ?? 0;
              final penaltyReceived = double.tryParse(item['penalty_received']?.toString() ?? '0') ?? 0;
              final penaltyBalance = double.tryParse(item['penalty_balance']?.toString() ?? '0') ?? 0;
              final loanBalance = double.tryParse(item['loan_balance']?.toString() ?? '0') ?? 0;

              final status = item['status']?.toString() ?? 'Pending';
              final isPaid = status.toLowerCase() == 'paid';

              return Container(
                height: 49,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Checkbox(
                        value: selectedRows[index],
                        onChanged: (value) {
                          setState(() {
                            selectedRows[index] = value ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      child: Text(
                        item['dueno']?.toString() ?? '',
                        style: const TextStyle(color: Color(0xFF374151)),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(
                        formatDate(item['duedate']?.toString() ?? ''),
                        style: const TextStyle(color: Color(0xFF374151)),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        formatCurrency(dueAmount),
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        paidAmount > 0 ? formatCurrency(paidAmount) : '-',
                        style: const TextStyle(color: Color(0xFF374151)),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(
                        _shouldShowRecDate(status, item['collectiondate']?.toString() ?? ''),
                        style: const TextStyle(color: Color(0xFF374151)),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        formatCurrency(loanBalance),
                        style: const TextStyle(color: Color(0xFF374151)),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        penaltyAmount > 0 ? formatCurrency(penaltyAmount) : '-',
                        style: const TextStyle(color: Color(0xFF374151)),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        penaltyReceived > 0 ? formatCurrency(penaltyReceived) : '-',
                        style: const TextStyle(color: Color(0xFF374151)),
                      ),
                    ),

                    SizedBox(
                      width: 120,
                      child: Text(
                        // Show penalty receipt date based on status
                        _shouldShowPenaltyRecDate(status, item['collectiondate']?.toString() ?? ''),
                        style: const TextStyle(color: Color(0xFF374151)),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        penaltyBalance > 0 ? formatCurrency(penaltyBalance) : '-',
                        style: const TextStyle(color: Color(0xFF374151)),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPaid ? Colors.green : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: isPaid ? Colors.white : Colors.red.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            // Summary Row
            Container(
              height: 49,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 60),
                  SizedBox(
                    width: 100,
                    child: const Text(
                      'Total:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      formatCurrency(scheduleData.fold(0.0, (sum, item) {
                        return sum + (double.tryParse(item['dueamount']?.toString() ?? '0') ?? 0);
                      })),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      formatCurrency(scheduleData.fold(0.0, (sum, item) {
                        return sum + (double.tryParse(item['paidamount']?.toString() ?? '0') ?? 0);
                      })),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  const SizedBox(width: 120),
                  SizedBox(
                    width: 100,
                    child: Text(
                      formatCurrency(scheduleData.fold(0.0, (sum, item) {
                        return sum + (double.tryParse(item['penaltypaid']?.toString() ?? '0') ?? 0);
                      })),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      formatCurrency(scheduleData.fold(0.0, (sum, item) {
                        return sum + (double.tryParse(item['penalty_received']?.toString() ?? '0') ?? 0);
                      })),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  const SizedBox(width: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                height: 130,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Loan History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'View and manage loan transaction history and payment schedules',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),

              // Filters Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Customer Name:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<Map<String, dynamic>>(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFB),
                                  ),
                                  items: customers.map((customer) {
                                    return DropdownMenuItem<Map<String, dynamic>>(
                                      value: customer,
                                      child: Text(customer['display'] ?? ''),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedCustomer = value;
                                      selectedLoan = null;
                                      loanController.clear();
                                      customerLoans = [];
                                      loanData = null;
                                      scheduleData = [];
                                      showSchedule = false;
                                    });
                                    if (value != null) {
                                      fetchCustomerLoans(value['id']);
                                    }
                                  },
                                  hint: const Text('Select Customer'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Loan No:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<Map<String, dynamic>>(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFB),
                                  ),
                                  items: customerLoans.map((loan) {
                                    return DropdownMenuItem<Map<String, dynamic>>(
                                      value: loan,
                                      child: Text(loan['display'] ?? ''),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedLoan = value;
                                    });
                                  },
                                  hint: const Text('Select Loan'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date Range:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: fromDateController,
                                        decoration: InputDecoration(
                                          hintText: 'From Date',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFF9FAFB),
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.calendar_today),
                                            onPressed: () => _selectDate(context, fromDateController),
                                          ),
                                        ),
                                        readOnly: true,
                                        onTap: () => _selectDate(context, fromDateController),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('to'),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: toDateController,
                                        decoration: InputDecoration(
                                          hintText: 'To Date',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFF9FAFB),
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.calendar_today),
                                            onPressed: () => _selectDate(context, toDateController),
                                          ),
                                        ),
                                        readOnly: true,
                                        onTap: () => _selectDate(context, toDateController),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: fetchLoanHistory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E293B),
                              minimumSize: const Size(150, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                              'Generate Report',
                              style: TextStyle(fontSize: 16,color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (loanData != null) ...[
                // Loan Details Section
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // First Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoRow(
                              'Customer Name:',
                              loanData!['customername']?.toString() ?? '',
                            ),
                            _buildInfoRow(
                              'Loan No:',
                              loanData!['loanno']?.toString() ?? '',
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Photo upload:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 365,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFD1D5DB)),
                                  ),
                                  child: Center(
                                    child: loanData!['photourl']?.toString()?.isNotEmpty == true
                                        ? Image.network(
                                      '$baseUrl/${loanData!['photourl']}',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                        : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.black),
                                          ),
                                          child: const Icon(Icons.photo),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Upload Photo',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                        const Text(
                                          'Click to browse files',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Second Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoRow(
                              'Date:',
                              formatDate(loanData!['startdate']?.toString() ?? ''),
                            ),
                            _buildInfoRow(
                              'No. of Weeks:',
                              loanData!['noofweeks']?.toString() ?? '',
                            ),
                            const SizedBox(width: 365), // Placeholder for empty space
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Third Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoRow(
                              'Loan Amount:',
                              loanData!['loanamount']?.toString() ?? '',
                              isCurrency: true,
                            ),
                            _buildInfoRow(
                              'Loan Paid:',
                              loanData!['total_paid']?.toString() ?? '0',
                              isCurrency: true,
                            ),
                            _buildInfoRow(
                              'Loan Balance:',
                              loanData!['loan_balance']?.toString() ?? '0',
                              isCurrency: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Fourth Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoRow(
                              'Penalty Amount:',
                              loanData!['total_penalty_paid']?.toString() ?? '0',
                              isCurrency: true,
                            ),
                            _buildInfoRow(
                              'Penalty Collection:',
                              loanData!['total_penalty_received']?.toString() ?? '0',
                              isCurrency: true,
                            ),
                            _buildInfoRow(
                              'Penalty Balance:',
                              loanData!['penalty_balance']?.toString() ?? '0',
                              isCurrency: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Fifth Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoRow(
                              'Discount Principle:',
                              '0',
                              isCurrency: true,
                            ),
                            _buildInfoRow(
                              'Discount Penalty:',
                              '0',
                              isCurrency: true,
                            ),
                            _buildInfoRow(
                              'Referred by:',
                              loanData!['refer']?.toString() ?? '',
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Sixth Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoRow(
                              'Referred contact:',
                              loanData!['refercontact']?.toString() ?? '',
                            ),
                            _buildInfoRow(
                              'Spouse name:',
                              loanData!['spousename']?.toString() ?? '',
                            ),
                            _buildInfoRow(
                              'Spouse number:',
                              loanData!['spousecontact']?.toString() ?? '',
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Seventh Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoRow(
                              'Mobile1:',
                              loanData!['mobile1']?.toString() ?? '',
                            ),
                            _buildInfoRow(
                              'Mobile2:',
                              loanData!['mobile2']?.toString() ?? '',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Payment Schedule Section
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Schedule',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (isLoading)
                          const Center(child: CircularProgressIndicator())
                        else
                          _buildScheduleTable(),

                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                // Export Selected functionality
                                final selectedCount = selectedRows.where((element) => element).length;
                                if (selectedCount > 0) {
                                  // Implement export logic here
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Exporting $selectedCount selected rows'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select rows to export'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(170, 50),
                                side: const BorderSide(color: Color(0xFFD1D5DB)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Export Selected',
                                style: TextStyle(color: Color(0xFF374151)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                // Print Schedule functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Printing schedule...'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E293B),
                                minimumSize: const Size(158, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Print Schedule'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

import '../services/collection_apiservice.dart';


class CollectionEntryScreen extends StatefulWidget {
  const CollectionEntryScreen({super.key});

  @override
  State<CollectionEntryScreen> createState() => _CollectionEntryScreenState();
}

class _CollectionEntryScreenState extends State<CollectionEntryScreen> {
  final collectionapiservice _apiService = collectionapiservice();

  // Form controllers
  final TextEditingController _serialNoController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _loanNoController = TextEditingController();
  final TextEditingController _loanAmountController = TextEditingController();
  final TextEditingController _loanPaidController = TextEditingController();
  final TextEditingController _loanBalanceController = TextEditingController();
  final TextEditingController _penaltyAmountController = TextEditingController();
  final TextEditingController _penaltyPaidController = TextEditingController();
  final TextEditingController _penaltyBalanceController = TextEditingController();
  final TextEditingController _totalBalanceController = TextEditingController();

  // Data
  Map<String, dynamic>? _loanData;
  List<dynamic> _paymentSchedule = [];
  Map<String, dynamic> _totals = {};
  List<Map<String, dynamic>> _selectedPayments = [];

  // UI State
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;
  String? _selectedPaymentMode = 'Cash';
  DateTime? _selectedDate;
  String? _loanId;

  final List<String> _paymentModes = ['Cash', 'Bank Transfer', 'Cheque', 'UPI'];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    _generateSerialNo();
  }

  void _generateSerialNo() {
    final now = DateTime.now();
    _serialNoController.text = 'COL${now.millisecondsSinceEpoch.toString().substring(7)}';
  }

  Future<void> _searchLoan() async {
    final loanNo = _loanNoController.text.trim();
    if (loanNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a loan number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _loanData = null;
      _paymentSchedule = [];
      _selectedPayments.clear();
    });

    try {
      final result = await _apiService.fetchLoanForCollection(context, loanNo);

      if (mounted) {
        setState(() {
          _loanData = result['loan'];
          _paymentSchedule = result['schedule'];
          _totals = result['totals'];
          _loanId = _loanData!['id'].toString();

          // Update form fields
          _customerController.text = _loanData!['customername'] ?? '';
          _loanAmountController.text = _loanData!['loanamount']?.toString() ?? '0.00';
          _loanPaidController.text = _totals['loanPaid']?.toString() ?? '0.00';
          _loanBalanceController.text = _totals['loanBalance']?.toString() ?? '0.00';
          _penaltyAmountController.text = _loanData!['penaltyamount']?.toString() ?? '0.00';
          _penaltyPaidController.text = _totals['penaltyPaid']?.toString() ?? '0.00';
          _penaltyBalanceController.text = _loanData!['penaltyamount']?.toString() ?? '0.00';
          _totalBalanceController.text = _totals['totalBalance']?.toString() ?? '0.00';

          // Initialize selected payments
          for (var payment in _paymentSchedule) {
            if (payment['status'] == 'Pending') {
              _selectedPayments.add({
                'dueno': payment['dueno'],
                'dueamount': payment['dueamount'],
                'penaltyamount': payment['penaltyamount'] ?? 0.0,
                'selected': false,
              });
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _togglePaymentSelection(int index) {
    setState(() {
      _selectedPayments[index]['selected'] = !_selectedPayments[index]['selected'];
      _updateTotals();
    });
  }

  void _updateTotals() {
    double totalDue = 0;
    double totalPenalty = 0;

    for (var payment in _selectedPayments) {
      if (payment['selected'] == true) {
        totalDue += double.parse(payment['dueamount'].toString());
        totalPenalty += double.parse(payment['penaltyamount'].toString());
      }
    }

    setState(() {
      // You can update any other totals here if needed
    });
  }

  Future<void> _recordCollection() async {
    if (_loanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please search for a loan first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedCount = _selectedPayments.where((p) => p['selected'] == true).length;
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one payment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.recordCollection(
        context: context,
        loanId: _loanId!,
        paymentData: _selectedPayments,
        collectionDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        paymentMode: _selectedPaymentMode!,
      );

      if (result == "Success" && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collection recorded successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        _resetForm();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error recording collection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    setState(() {
      _loanNoController.clear();
      _customerController.clear();
      _loanData = null;
      _paymentSchedule = [];
      _selectedPayments.clear();
      _selectedDate = DateTime.now();
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
      _generateSerialNo();
    });
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isReadOnly = false,
    String? hintText,
    Color? backgroundColor,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 47,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: TextField(
            controller: controller,
            readOnly: isReadOnly,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: const TextStyle(
                fontSize: 16,
                color: Color(0xFF999999),
              ),
              suffixIcon: suffixIcon,
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF252525),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date :',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );

            if (picked != null && picked != _selectedDate) {
              setState(() {
                _selectedDate = picked;
                _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
              });
            }
          },
          child: Container(
            height: 47,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _dateController.text.isNotEmpty
                          ? _dateController.text
                          : 'Select date',
                      style: TextStyle(
                        fontSize: 16,
                        color: _dateController.text.isNotEmpty
                            ? const Color(0xFF252525)
                            : const Color(0xFF999999),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentModeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cash/Bank :',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 47,
          decoration: BoxDecoration(
            color: const Color(0xFFD1D5DB).withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPaymentMode,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                items: _paymentModes.map((mode) {
                  return DropdownMenuItem<String>(
                    value: mode,
                    child: Text(
                      mode,
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMode = value;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentScheduleTable() {
    if (_paymentSchedule.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No payment schedule found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter a loan number and search to view payment schedule',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Schedule Report',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),

        // Table Header
        Container(
          height: 57,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Checkbox column
              SizedBox(
                width: 60,
                child: Center(
                  child: Text(
                    'Select',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),

              // Due No
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    'Due No',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),

              // Due Date
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'Due Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),

              // Due Amount
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'Due Amount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),

              // Penalty Amount
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'Penalty Amount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),

              // Status
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Table Rows
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _paymentSchedule.length,
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final payment = _paymentSchedule[index];
            final isPending = payment['status'] == 'Pending';
            final dueDate = payment['duedate']?.toString() ?? '';
            final formattedDate = dueDate.isNotEmpty
                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(dueDate))
                : '';

            return Container(
              height: 57,
              decoration: BoxDecoration(
                color: isPending ? Colors.white : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPending
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFF1F5F9),
                ),
              ),
              child: Row(
                children: [
                  // Checkbox
                  SizedBox(
                    width: 60,
                    child: Center(
                      child: isPending
                          ? Checkbox(
                        value: _selectedPayments.indexWhere((p) =>
                        p['dueno'] == payment['dueno']) != -1
                            ? _selectedPayments.firstWhere((p) =>
                        p['dueno'] == payment['dueno'])['selected']
                            : false,
                        onChanged: (value) {
                          final paymentIndex = _selectedPayments.indexWhere((p) =>
                          p['dueno'] == payment['dueno']);
                          if (paymentIndex != -1) {
                            _togglePaymentSelection(paymentIndex);
                          }
                        },
                      )
                          : const Icon(Icons.check_circle, color: Colors.green),
                    ),
                  ),

                  // Due No
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Text(
                        payment['dueno']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isPending
                              ? const Color(0xFF374151)
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),

                  // Due Date
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 14,
                          color: isPending
                              ? const Color(0xFF374151)
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),

                  // Due Amount
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        '₹${double.parse(payment['dueamount']?.toString() ?? '0').toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isPending
                              ? const Color(0xFF374151)
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),

                  // Penalty Amount
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        '₹${double.parse(payment['penaltyamount']?.toString() ?? '0').toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isPending
                              ? const Color(0xFF374151)
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),

                  // Status
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPending
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          payment['status'] ?? 'Pending',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isPending ? Colors.orange : Colors.green,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildInputField(
            label: 'Loan No :',
            controller: _loanNoController,
            hintText: 'Enter loan number',
            suffixIcon: _isSearching
                ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : IconButton(
              icon: const Icon(Icons.search),
              onPressed: _searchLoan,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildInputField(
            label: 'Customer :',
            controller: _customerController,
            isReadOnly: true,
            hintText: 'Customer will appear here',
            backgroundColor: const Color(0xFFF9FAFB),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow1() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildInputField(
            label: 'Loan Amount :',
            controller: _loanAmountController,
            isReadOnly: true,
            backgroundColor: const Color(0xFFF9FAFB),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildInputField(
            label: 'Loan Paid :',
            controller: _loanPaidController,
            isReadOnly: true,
            backgroundColor: const Color(0xFFF9FAFB),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildInputField(
            label: 'Loan Balance :',
            controller: _loanBalanceController,
            isReadOnly: true,
            backgroundColor: const Color(0xFFF9FAFB),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow2() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildInputField(
            label: 'Penalty Amount :',
            controller: _penaltyAmountController,
            isReadOnly: true,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildInputField(
            label: 'Penalty Paid :',
            controller: _penaltyPaidController,
            isReadOnly: true,
            backgroundColor: const Color(0xFFF9FAFB),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildInputField(
            label: 'Penalty Balance :',
            controller: _penaltyBalanceController,
            isReadOnly: true,
            backgroundColor: const Color(0xFFF9FAFB),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalBalanceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(child: SizedBox()),
        const SizedBox(width: 20),
        const Expanded(child: SizedBox()),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Balance :',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 47,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: Center(
                  child: Text(
                    '₹${_totalBalanceController.text}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 146,
          height: 50,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _resetForm,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 171,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading || _loanId == null ? null : _recordCollection,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text(
              'Collect Payment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 32 : 16,
            vertical: isWeb ? 32 : 16,
          ),
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isWeb ? 1271 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isWeb ? 32 : 20,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Collection Entry :',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Record loan collection and payment details',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Form
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First Row - Serial No & Date
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildInputField(
                              label: 'Serial No :',
                              controller: _serialNoController,
                              isReadOnly: true,
                              hintText: 'Auto serial number',
                              backgroundColor: const Color(0xFFD1D5DB).withOpacity(0.25),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildDateField(),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildPaymentModeDropdown(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Search Row
                      _buildSearchRow(),

                      const SizedBox(height: 20),

                      // Amount Row 1
                      _buildAmountRow1(),

                      const SizedBox(height: 20),

                      // Amount Row 2
                      _buildAmountRow2(),

                      const SizedBox(height: 20),

                      // Total Balance Row
                      _buildTotalBalanceRow(),

                      const SizedBox(height: 40),

                      // Payment Schedule Table
                      _buildPaymentScheduleTable(),

                      const SizedBox(height: 40),

                      // Action Buttons
                      _buildActionButtons(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
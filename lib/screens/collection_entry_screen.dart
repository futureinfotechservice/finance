import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/collection_apiservice.dart';
import '../services/loan_apiservice.dart';

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
  final TextEditingController _penaltyAmountController =
      TextEditingController();
  final TextEditingController _penaltyPaidController = TextEditingController();
  final TextEditingController _penaltyBalanceController =
      TextEditingController();
  final TextEditingController _totalBalanceController = TextEditingController();

  // Data
  Map<String, dynamic>? _loanData;
  List<dynamic> _paymentSchedule = [];
  Map<String, dynamic> _totals = {};
  List<Map<String, dynamic>> _selectedPayments = [];
  List<Map<String, dynamic>> _activeLoans = [];
  List<Map<String, dynamic>> _pendingPayments = [];
  String? _selectedLoanId;

  // UI State
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isLoadingLoans = true;
  String? _errorMessage;
  String? _selectedPaymentMode = 'Cash';
  DateTime? _selectedDate;
  String? _loanId;

  // Totals tracking
  double _totalSelectedAmount = 0.0;
  double _totalSelectedPenalty = 0.0;
  double _fixedPenaltyAmount = 0.0;

  final List<String> _paymentModes = ['Cash', 'Bank Transfer', 'Cheque', 'UPI'];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    _initializeData();
  }

  Future<void> _initializeData() async {
    print("=== INITIALIZING COLLECTION ENTRY DATA ===");
    try {
      await Future.wait([_generateCollectionNo(), _loadActiveLoans()]);
      print("✅ Data initialization complete");
    } catch (e) {
      print("❌ Error initializing data: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading data: $e";
        });
      }
    }
  }

  Future<void> _generateCollectionNo() async {
    try {
      final collectionNo = await _apiService.generateCollectionNo(context);
      if (mounted && collectionNo.isNotEmpty) {
        setState(() {
          _serialNoController.text = collectionNo;
        });
        print("✅ Generated Collection No: $collectionNo");
      }
    } catch (e) {
      print("❌ Error generating collection no: $e");
      if (mounted) {
        setState(() {
          _serialNoController.text =
              'COL${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
        });
      }
    }
  }

  Future<void> _loadActiveLoans() async {
    try {
      print("Loading active loans...");
      final loans = await _apiService.fetchActiveLoans(context);
      print("Received ${loans.length} active loans");

      if (mounted) {
        setState(() {
          _activeLoans = loans;
          _isLoadingLoans = false;
        });
      }
    } catch (e) {
      print("❌ Error loading active loans: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading active loans";
          _activeLoans = [];
          _isLoadingLoans = false;
        });
      }
    }
  }

  Future<void> _searchLoan() async {
    final loanId = _selectedLoanId;
    if (loanId == null || loanId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a loan first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Find the selected loan
    Map<String, dynamic>? selectedLoan;
    for (var loan in _activeLoans) {
      if (loan['id'] == loanId) {
        selectedLoan = loan;
        break;
      }
    }

    if (selectedLoan == null || selectedLoan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected loan not found in active loans list'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final loanNo = selectedLoan['loanno']?.toString() ?? '';

    if (loanNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loan number is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print("🔍 Searching for loan: $loanNo");

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _loanData = null;
      _paymentSchedule = [];
      _pendingPayments.clear();
      _selectedPayments.clear();
      _totalSelectedAmount = 0.0;
      _totalSelectedPenalty = 0.0;
      _fixedPenaltyAmount = 0.0;
    });

    try {
      final result = await _apiService.fetchLoanForCollection(context, loanNo);

      if (mounted) {
        setState(() {
          _loanData = result['loan'];
          _paymentSchedule = result['schedule'];
          _totals = result['totals'];
          _loanId = _loanData!['id'].toString();

          // Get FIXED penalty amount from loan data
          _fixedPenaltyAmount =
              double.tryParse(
                _loanData?['fixed_penalty_amount']?.toString() ?? '0',
              ) ??
              0.0;
          if (_fixedPenaltyAmount == 0) {
            // Fallback to regular penalty amount
            _fixedPenaltyAmount =
                double.tryParse(
                  _loanData?['penaltyamount']?.toString() ?? '0',
                ) ??
                0.0;
          }

          // Update form fields
          _customerController.text = _loanData!['customername'] ?? '';
          _loanAmountController.text =
              _loanData!['loanamount']?.toString() ?? '0.00';
          _loanPaidController.text = _totals['loanPaid']?.toString() ?? '0.00';
          _loanBalanceController.text =
              _totals['pendingAmount']?.toString() ??
              _totals['loanBalance']?.toString() ??
              '0.00';

          // Fixed Penalty Amount
          _penaltyAmountController.text = _fixedPenaltyAmount.toStringAsFixed(
            2,
          );
          _penaltyPaidController.text =
              _totals['penaltyPaid']?.toString() ?? '0.00';

          // Update penalty balance from pending penalty
          _penaltyBalanceController.text =
              _totals['pendingPenalty']?.toString() ?? '0.00';
          _totalBalanceController.text =
              _totals['totalBalance']?.toString() ?? '0.00';

          // Initialize pending payments with FIXED penalty calculation
          DateTime now = DateTime.now();
          _pendingPayments.clear();
          _selectedPayments.clear();

          for (var payment in _paymentSchedule) {
            if (payment['status'] == 'Pending') {
              double penaltyAmount = 0.0;
              bool isOverdue = false;

              // Check if payment is overdue - FIXED penalty amount
              if (payment['duedate'] != null) {
                DateTime dueDate = DateTime.parse(payment['duedate']);
                if (now.isAfter(dueDate)) {
                  isOverdue = true;
                  // FIXED penalty amount (not multiplied by weeks)
                  penaltyAmount = _fixedPenaltyAmount;
                }
              }

              // Add to pending payments list
              _pendingPayments.add({
                'dueno': payment['dueno'],
                'duedate': payment['duedate'],
                'dueamount': payment['dueamount'],
                'calculated_penalty': penaltyAmount,
                'status': 'Pending',
                'isOverdue': isOverdue,
              });

              // Add to selected payments for default selection
              _selectedPayments.add({
                'dueno': payment['dueno'],
                'dueamount': payment['dueamount'],
                'penaltyamount': penaltyAmount,
                // This will be 0 or fixed amount
                'selected': false,
                // Default unchecked for success payment
                'unpaid': false,
                // Default unchecked for unpaid
                'paidamount': payment['dueamount'],
                // Full amount to be paid for success
              });
            }
          }

          print("✅ Found ${_pendingPayments.length} pending payments");
          print("✅ Fixed Penalty Amount: ₹$_fixedPenaltyAmount");
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
    if (_pendingPayments.isNotEmpty) {
      // Get the last due date to calculate next weekday
      DateTime lastDueDate = _pendingPayments.last['duedate'] != null
          ? DateTime.parse(_pendingPayments.last['duedate'])
          : DateTime.now();

      // Calculate next weekday (7 days from last due date)
      DateTime nextWeekday = lastDueDate.add(const Duration(days: 7));
      String nextWeekdayStr = DateFormat('dd/MM/yyyy').format(nextWeekday);

      print("ℹ️ Next weekday for new unpaid EMI: $nextWeekdayStr");

      // You can show this info to the user if needed
      // For example, in a snackbar or info box
    }
  }
// Add this helper function to your _CollectionEntryScreenState class
  String _getNextWeekdayInfo(List<Map<String, dynamic>> pendingPayments) {
    if (pendingPayments.isEmpty) return '';

    try {
      // Get the last due date from pending payments
      DateTime? lastDueDate;
      for (var payment in pendingPayments.reversed) {
        if (payment['duedate'] != null) {
          lastDueDate = DateTime.parse(payment['duedate']);
          break;
        }
      }

      // If no due date found, use current date
      lastDueDate ??= DateTime.now();

      // Calculate next weekday (7 days from last due date)
      DateTime nextWeekday = lastDueDate.add(const Duration(days: 7));
      return DateFormat('dd/MM/yyyy').format(nextWeekday);
    } catch (e) {
      print("Error calculating next weekday: $e");
      return '';
    }
  }
  void _onLoanSelected(String? value) {
    print("🔽 Loan selected: $value");

    if (value != null && value.isNotEmpty) {
      try {
        // Find the selected loan
        Map<String, dynamic>? selectedLoan;
        for (var loan in _activeLoans) {
          if (loan['id'] == value) {
            selectedLoan = loan;
            break;
          }
        }

        if (selectedLoan == null) {
          print("❌ Selected loan not found in list");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected loan not found'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        print("✅ Selected Loan: ${selectedLoan['display']}");

        setState(() {
          _selectedLoanId = value;
          _customerController.clear();
          _loanNoController.text = selectedLoan?['loanno']?.toString() ?? '';
          _loanAmountController.text =
              selectedLoan?['loanamount']?.toString() ?? '0.00';

          // Clear other fields until search is performed
          _loanPaidController.clear();
          _loanBalanceController.clear();
          _penaltyAmountController.clear();
          _penaltyPaidController.clear();
          _penaltyBalanceController.clear();
          _totalBalanceController.clear();

          _loanData = null;
          _paymentSchedule = [];
          _pendingPayments.clear();
          _selectedPayments.clear();
          _totalSelectedAmount = 0.0;
          _totalSelectedPenalty = 0.0;
          _fixedPenaltyAmount = 0.0;
        });
      } catch (e) {
        print("❌ Error selecting loan: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting loan: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _selectedLoanId = null;
          _loanNoController.clear();
          _customerController.clear();
          _loanData = null;
          _paymentSchedule = [];
          _pendingPayments.clear();
          _selectedPayments.clear();
          _totalSelectedAmount = 0.0;
          _totalSelectedPenalty = 0.0;
          _fixedPenaltyAmount = 0.0;
        });
      }
    } else {
      setState(() {
        _selectedLoanId = null;
        _loanNoController.clear();
        _customerController.clear();
        _loanData = null;
        _paymentSchedule = [];
        _pendingPayments.clear();
        _selectedPayments.clear();
        _totalSelectedAmount = 0.0;
        _totalSelectedPenalty = 0.0;
        _fixedPenaltyAmount = 0.0;
      });
    }
  }

  void _togglePaymentSelection(int index, String type) {
    setState(() {
      if (type == 'success') {
        // Toggle success payment
        bool newSuccessValue = !_selectedPayments[index]['selected'];
        _selectedPayments[index]['selected'] = newSuccessValue;

        // If marking as success, ensure unpaid is false
        if (newSuccessValue) {
          _selectedPayments[index]['unpaid'] = false;

          // For success payments (even if overdue), penalty becomes 0
          _selectedPayments[index]['penaltyamount'] = 0.0;
          // Paid amount is full due amount
          _selectedPayments[index]['paidamount'] =
              _selectedPayments[index]['dueamount'];
        } else {
          // Restore original penalty amount if unchecked and overdue
          bool isOverdue = _pendingPayments[index]['isOverdue'] ?? false;
          _selectedPayments[index]['penaltyamount'] = isOverdue
              ? _fixedPenaltyAmount
              : 0.0;
          // Reset paid amount
          _selectedPayments[index]['paidamount'] = 0.0;
        }
      } else if (type == 'unpaid') {
        // Toggle unpaid with penalty
        bool newUnpaidValue = !_selectedPayments[index]['unpaid'];
        _selectedPayments[index]['unpaid'] = newUnpaidValue;

        // If marking as unpaid, ensure success is false
        if (newUnpaidValue) {
          _selectedPayments[index]['selected'] = false;

          // Calculate penalty amount for unpaid (only if overdue)
          bool isOverdue = _pendingPayments[index]['isOverdue'] ?? false;
          _selectedPayments[index]['penaltyamount'] = isOverdue
              ? _fixedPenaltyAmount
              : 0.0;
          // No amount paid for unpaid
          _selectedPayments[index]['paidamount'] = 0.0;
        } else {
          // If unchecking unpaid, reset values
          _selectedPayments[index]['penaltyamount'] = 0.0;
          _selectedPayments[index]['paidamount'] = 0.0;
        }
      }

      _calculateTotals();
    });
  }

  void _calculateTotals() {
    double totalDue = 0.0;
    double totalPenalty = 0.0;

    for (int i = 0; i < _selectedPayments.length; i++) {
      if (_selectedPayments[i]['selected'] == true) {
        // Payment success - include due amount only
        totalDue += double.parse(_selectedPayments[i]['dueamount'].toString());
        // Penalty is 0 for success payments (even if overdue)
      } else if (_selectedPayments[i]['unpaid'] == true) {
        // Payment unpaid - include penalty only (NO due amount)
        totalPenalty += double.parse(
          _selectedPayments[i]['penaltyamount'].toString(),
        );
        // No due amount collected for unpaid payments
      }
    }

    // Update UI totals
    setState(() {
      _totalSelectedAmount = totalDue;
      _totalSelectedPenalty = totalPenalty;

      // Update balances based on current selection
      double currentLoanBalance =
          double.tryParse(_loanBalanceController.text) ?? 0.0;
      double currentPenaltyBalance =
          double.tryParse(_penaltyBalanceController.text) ?? 0.0;

      // Loan balance reduces only when payments are marked as success
      _loanBalanceController.text = (currentLoanBalance - totalDue)
          .toStringAsFixed(2);

      // Penalty balance reduces when penalty is collected (for unpaid payments only)
      _penaltyBalanceController.text = (currentPenaltyBalance - totalPenalty)
          .toStringAsFixed(2);

      // Update total balance
      double totalBalance =
          (currentLoanBalance - totalDue) +
          (currentPenaltyBalance - totalPenalty);
      _totalBalanceController.text = totalBalance > 0
          ? totalBalance.toStringAsFixed(2)
          : '0.00';
    });

    print("📊 Updated totals - Payment: ₹$totalDue, Penalty: ₹$totalPenalty");
  }

  Future<void> _recordCollection() async {
    if (_loanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select and search for a loan first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if at least one checkbox is selected
    bool hasSelection = false;
    for (var payment in _selectedPayments) {
      if (payment['selected'] == true || payment['unpaid'] == true) {
        hasSelection = true;
        break;
      }
    }

    if (!hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one payment (Paid or Unpaid)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check for unpaid payments without penalty (not overdue)
    List<String> unpaidWithoutPenalty = [];
    for (int i = 0; i < _selectedPayments.length; i++) {
      if (_selectedPayments[i]['unpaid'] == true &&
          _selectedPayments[i]['penaltyamount'] == 0) {
        unpaidWithoutPenalty.add(
          _pendingPayments[i]['dueno']?.toString() ?? '',
        );
      }
    }

    if (unpaidWithoutPenalty.isNotEmpty) {
      // Show warning for unpaid payments that are not overdue
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Not Overdue'),
          content: Text(
            'The following payments are not overdue and will have no penalty:\n\n'
            'Due Nos: ${unpaidWithoutPenalty.join(', ')}\n\n'
            'Do you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processCollection();
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    } else {
      _processCollection();
    }
  }

  Future<void> _processCollection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare payment data for API
      List<Map<String, dynamic>> paymentData = [];

      for (int i = 0; i < _selectedPayments.length; i++) {
        final payment = _selectedPayments[i];
        final pendingPayment = _pendingPayments[i];
        final isOverdue = pendingPayment['isOverdue'] ?? false;

        if (payment['selected'] == true) {
          // SUCCESS PAYMENT: Due amount paid, penalty is 0 (even if overdue)
          paymentData.add({
            'dueno': payment['dueno'],
            'dueamount': payment['dueamount'].toString(),
            'paidamount': payment['dueamount'].toString(),
            // Full amount paid
            'penaltyamount': '0.00',
            // No penalty for overdue payments when paid
            'selected': true,
            'unpaid': false,
          });
        } else if (payment['unpaid'] == true) {
          // UNPAID: Only penalty collected if overdue, due amount jumps to last EMI
          double penaltyToSave = isOverdue ? _fixedPenaltyAmount : 0.0;

          paymentData.add({
            'dueno': payment['dueno'],
            'dueamount': payment['dueamount'].toString(),
            'paidamount': '0.00',
            // No amount paid for unpaid
            'penaltyamount': penaltyToSave.toStringAsFixed(2),
            // Fixed penalty or 0
            'selected': false,
            'unpaid': true,
          });
        }
      }

      final result = await _apiService.recordCollection(
        context: context,
        loanId: _loanId!,
        paymentData: paymentData,
        collectionDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        paymentMode: _selectedPaymentMode!,
      );

      if (result == "Success" && mounted) {
        // Show success message with details
        String successMessage = '✅ Collection recorded successfully!\n';
        successMessage +=
            'Paid Amount: ₹${_totalSelectedAmount.toStringAsFixed(2)}\n';
        successMessage +=
            'Penalty Collected: ₹${_totalSelectedPenalty.toStringAsFixed(2)}';

        bool hasUnpaid = _selectedPayments.any(
          (payment) => payment['unpaid'] == true,
        );
        bool hasUnpaidWithPenalty = _selectedPayments.any(
          (payment) =>
              payment['unpaid'] == true && payment['penaltyamount'] > 0,
        );

        if (hasUnpaidWithPenalty) {
          successMessage +=
              '\n\n⚠️ Unpaid amount(s) with penalty have been moved to new schedule entry(s)';
        } else if (hasUnpaid) {
          successMessage +=
              '\n\nℹ️ Unpaid payment(s) recorded (no penalty as not overdue)';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
        _resetForm();
      } else if (result == "Failed") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to record collection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error recording collection: $e'),
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

  void _resetForm() async {
    setState(() {
      _selectedLoanId = null;
      _customerController.clear();
      _loanNoController.clear();
      _loanAmountController.clear();
      _loanData = null;
      _paymentSchedule = [];
      _pendingPayments.clear();
      _selectedPayments.clear();
      _loanPaidController.clear();
      _loanBalanceController.clear();
      _penaltyAmountController.clear();
      _penaltyPaidController.clear();
      _penaltyBalanceController.clear();
      _totalBalanceController.clear();
      _selectedDate = DateTime.now();
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
      _totalSelectedAmount = 0.0;
      _totalSelectedPenalty = 0.0;
      _fixedPenaltyAmount = 0.0;
    });

    // Regenerate collection number
    await _generateCollectionNo();
    print("🔄 Form reset");
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
            style: const TextStyle(fontSize: 16, color: Color(0xFF252525)),
          ),
        ),
      ],
    );
  }

  Widget _buildLoanDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Loan No :',
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _isLoadingLoans
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : _activeLoans.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        'No active loans available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLoanId,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.black,
                        size: 24,
                      ),
                      hint: const Text(
                        'Select loan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF252525),
                        ),
                      ),
                      items: _activeLoans.map((loan) {
                        if (loan is Map<String, dynamic>) {
                          return DropdownMenuItem<String>(
                            value: loan['id']?.toString(),
                            child: Text(
                              loan['display']?.toString() ??
                                  loan['loanno']?.toString() ??
                                  'Unknown',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF252525),
                              ),
                            ),
                          );
                        } else {
                          return const DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              'Invalid loan data',
                              style: TextStyle(fontSize: 16, color: Colors.red),
                            ),
                          );
                        }
                      }).toList(),
                      onChanged: _onLoanSelected,
                    ),
                  ),
          ),
        ),
        if (_activeLoans.isEmpty && !_isLoadingLoans)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'No active loans found. Issue loans first.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                fontStyle: FontStyle.italic,
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
              builder: (context, child) {
                return Theme(
                  data: ThemeData.light().copyWith(
                    primaryColor: const Color(0xFF1E293B),
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF1E293B),
                    ),
                    buttonTheme: const ButtonThemeData(
                      textTheme: ButtonTextTheme.primary,
                    ),
                  ),
                  child: child!,
                );
              },
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
                    child: Text(mode, style: const TextStyle(fontSize: 16)),
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

  Widget _buildCustomerField() {
    return _buildInputField(
      label: 'Customer :',
      controller: _customerController,
      isReadOnly: true,
      hintText: 'Customer will appear here',
      backgroundColor: const Color(0xFFF9FAFB),
    );
  }

  Widget _buildSearchButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        SizedBox(
          height: 47,
          child: ElevatedButton.icon(
            onPressed: _selectedLoanId != null ? _searchLoan : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedLoanId != null
                  ? const Color(0xFF1E293B)
                  : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: _isSearching
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.search, size: 20),
            label: Text(
              _isSearching ? 'Searching...' : 'Search Loan',
              style: const TextStyle(
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

  // Widget _buildPaymentScheduleTable() {
  //   if (_pendingPayments.isEmpty) {
  //     return Container(
  //       padding: const EdgeInsets.all(40),
  //       decoration: BoxDecoration(
  //         color: const Color(0xFFF8FAFC),
  //         borderRadius: BorderRadius.circular(8),
  //         border: Border.all(color: const Color(0xFFE2E8F0)),
  //       ),
  //       child: Column(
  //         children: [
  //           Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
  //           const SizedBox(height: 16),
  //           const Text(
  //             'No payment schedule found',
  //             style: TextStyle(
  //               fontSize: 18,
  //               fontWeight: FontWeight.w500,
  //               color: Color(0xFF374151),
  //             ),
  //           ),
  //           const SizedBox(height: 8),
  //           const Text(
  //             'Select a loan and click Search to view payment schedule',
  //             style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
  //             textAlign: TextAlign.center,
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'Payment Schedule Report',
  //         style: TextStyle(
  //           fontSize: 20,
  //           fontWeight: FontWeight.w500,
  //           color: Color(0xFF374151),
  //         ),
  //       ),
  //       const SizedBox(height: 12),
  //
  //       // Table Header
  //       Container(
  //         height: 57,
  //         decoration: BoxDecoration(
  //           color: const Color(0xFFF8FAFC),
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //         child: Row(
  //           children: [
  //             // Success Payment Checkbox
  //             SizedBox(
  //               width: 80,
  //               child: Center(
  //                 child: Column(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     Text(
  //                       'Paid',
  //                       style: TextStyle(
  //                         fontSize: 14,
  //                         fontWeight: FontWeight.w600,
  //                         color: Colors.green[700],
  //                       ),
  //                     ),
  //                     const Text(
  //                       '(Full Amount)',
  //                       style: TextStyle(
  //                         fontSize: 10,
  //                         fontWeight: FontWeight.w500,
  //                         color: Colors.green,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //
  //             // Unpaid Checkbox
  //             SizedBox(
  //               width: 80,
  //               child: Center(
  //                 child: Column(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     Text(
  //                       'Unpaid',
  //                       style: TextStyle(
  //                         fontSize: 14,
  //                         fontWeight: FontWeight.w600,
  //                         color: Colors.red[700],
  //                       ),
  //                     ),
  //                     const Text(
  //                       '(Penalty Only)',
  //                       style: TextStyle(
  //                         fontSize: 10,
  //                         fontWeight: FontWeight.w500,
  //                         color: Colors.red,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //
  //             // Due No
  //             Expanded(
  //               flex: 1,
  //               child: Center(
  //                 child: Text(
  //                   'Due No',
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w600,
  //                     color: Colors.grey[700],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //
  //             // Due Date
  //             Expanded(
  //               flex: 2,
  //               child: Center(
  //                 child: Text(
  //                   'Due Date',
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w600,
  //                     color: Colors.grey[700],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //
  //             // Due Amount
  //             Expanded(
  //               flex: 2,
  //               child: Center(
  //                 child: Text(
  //                   'Due Amount',
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w600,
  //                     color: Colors.grey[700],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //
  //             // Penalty Amount
  //             Expanded(
  //               flex: 2,
  //               child: Center(
  //                 child: Column(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     Text(
  //                       'Penalty',
  //                       style: TextStyle(
  //                         fontSize: 14,
  //                         fontWeight: FontWeight.w600,
  //                         color: Colors.grey[700],
  //                       ),
  //                     ),
  //                     Text(
  //                       '(Fixed Amount)',
  //                       style: TextStyle(fontSize: 10, color: Colors.grey[700]),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //
  //             // Status
  //             Expanded(
  //               flex: 1,
  //               child: Center(
  //                 child: Text(
  //                   'Status',
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w600,
  //                     color: Colors.grey[700],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //
  //       const SizedBox(height: 8),
  //
  //       // Table Rows
  //       ListView.separated(
  //         shrinkWrap: true,
  //         physics: const NeverScrollableScrollPhysics(),
  //         itemCount: _pendingPayments.length,
  //         separatorBuilder: (context, index) => const SizedBox(height: 4),
  //         itemBuilder: (context, index) {
  //           final payment = _pendingPayments[index];
  //           final selectedPayment = _selectedPayments[index];
  //           final dueDate = payment['duedate']?.toString() ?? '';
  //           final formattedDate = dueDate.isNotEmpty
  //               ? DateFormat('dd/MM/yyyy').format(DateTime.parse(dueDate))
  //               : '';
  //
  //           final isOverdue = payment['isOverdue'] ?? false;
  //           final penaltyAmount = payment['calculated_penalty'] ?? 0.0;
  //
  //           return Container(
  //             height: 57,
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(8),
  //               border: Border.all(
  //                 color: isOverdue
  //                     ? Colors.red.withOpacity(0.3)
  //                     : const Color(0xFFE2E8F0),
  //               ),
  //             ),
  //             child: Row(
  //               children: [
  //                 // Success Payment Checkbox
  //                 SizedBox(
  //                   width: 80,
  //                   child: Center(
  //                     child: Tooltip(
  //                       message: 'Mark as Paid (Full amount, no penalty)',
  //                       child: Checkbox(
  //                         value: selectedPayment['selected'],
  //                         onChanged: (value) {
  //                           _togglePaymentSelection(index, 'success');
  //                         },
  //                         activeColor: Colors.green,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //
  //                 // Unpaid Checkbox
  //                 SizedBox(
  //                   width: 80,
  //                   child: Center(
  //                     child: Tooltip(
  //                       message:
  //                           'Mark as Unpaid (Collect penalty only if overdue, due amount moves to end)',
  //                       child: Checkbox(
  //                         value: selectedPayment['unpaid'],
  //                         onChanged: (value) {
  //                           _togglePaymentSelection(index, 'unpaid');
  //                         },
  //                         activeColor: Colors.red,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //
  //                 // Due No
  //                 Expanded(
  //                   flex: 1,
  //                   child: Center(
  //                     child: Text(
  //                       payment['dueno']?.toString() ?? '',
  //                       style: TextStyle(
  //                         fontSize: 16,
  //                         fontWeight: FontWeight.w500,
  //                         color: isOverdue
  //                             ? Colors.red
  //                             : const Color(0xFF374151),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //
  //                 // Due Date
  //                 Expanded(
  //                   flex: 2,
  //                   child: Center(
  //                     child: Column(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       children: [
  //                         Text(
  //                           formattedDate,
  //                           style: TextStyle(
  //                             fontSize: 14,
  //                             color: isOverdue
  //                                 ? Colors.red
  //                                 : const Color(0xFF374151),
  //                           ),
  //                         ),
  //                         if (isOverdue)
  //                           const Text(
  //                             '(Overdue)',
  //                             style: TextStyle(fontSize: 10, color: Colors.red),
  //                           ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //
  //                 // Due Amount
  //                 Expanded(
  //                   flex: 2,
  //                   child: Center(
  //                     child: Text(
  //                       '₹${double.parse(payment['dueamount']?.toString() ?? '0').toStringAsFixed(2)}',
  //                       style: TextStyle(
  //                         fontSize: 14,
  //                         fontWeight: FontWeight.w500,
  //                         color: isOverdue
  //                             ? Colors.red
  //                             : const Color(0xFF374151),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //
  //                 // Penalty Amount
  //                 Expanded(
  //                   flex: 2,
  //                   child: Center(
  //                     child: Column(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       children: [
  //                         Text(
  //                           '₹${penaltyAmount.toStringAsFixed(2)}',
  //                           style: TextStyle(
  //                             fontSize: 14,
  //                             fontWeight: FontWeight.w500,
  //                             color: isOverdue
  //                                 ? Colors.red
  //                                 : const Color(0xFF374151),
  //                           ),
  //                         ),
  //                         if (isOverdue && penaltyAmount > 0)
  //                           Text(
  //                             'Fixed: ₹$_fixedPenaltyAmount',
  //                             style: const TextStyle(
  //                               fontSize: 10,
  //                               color: Colors.grey,
  //                             ),
  //                           ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //
  //                 // Status
  //                 Expanded(
  //                   flex: 1,
  //                   child: Center(
  //                     child: Container(
  //                       padding: const EdgeInsets.symmetric(
  //                         horizontal: 12,
  //                         vertical: 4,
  //                       ),
  //                       decoration: BoxDecoration(
  //                         color: isOverdue
  //                             ? Colors.red.withOpacity(0.1)
  //                             : Colors.orange.withOpacity(0.1),
  //                         borderRadius: BorderRadius.circular(20),
  //                       ),
  //                       child: Column(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           Text(
  //                             isOverdue ? 'Overdue' : 'Pending',
  //                             style: TextStyle(
  //                               fontSize: 12,
  //                               fontWeight: FontWeight.w500,
  //                               color: isOverdue ? Colors.red : Colors.orange,
  //                             ),
  //                           ),
  //                           if (selectedPayment['selected'] == true)
  //                             const Text(
  //                               'Paid: Full',
  //                               style: TextStyle(
  //                                 fontSize: 10,
  //                                 color: Colors.green,
  //                                 fontWeight: FontWeight.bold,
  //                               ),
  //                             ),
  //                           if (selectedPayment['unpaid'] == true)
  //                             Text(
  //                               selectedPayment['penaltyamount'] > 0
  //                                   ? 'Unpaid: Penalty'
  //                                   : 'Unpaid: No Penalty',
  //                               style: TextStyle(
  //                                 fontSize: 10,
  //                                 color: selectedPayment['penaltyamount'] > 0
  //                                     ? Colors.red
  //                                     : Colors.orange,
  //                                 fontWeight: FontWeight.bold,
  //                               ),
  //                             ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       ),
  //
  //       // Summary Section
  //       const SizedBox(height: 20),
  //       Container(
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           color: const Color(0xFFF8FAFC),
  //           borderRadius: BorderRadius.circular(8),
  //           border: Border.all(color: const Color(0xFFE2E8F0)),
  //         ),
  //         child: Column(
  //           children: [
  //             // Penalty Info
  //             Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: Colors.yellow[50],
  //                 borderRadius: BorderRadius.circular(8),
  //                 border: Border.all(color: Colors.yellow),
  //               ),
  //               child: Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   const Icon(
  //                     Icons.info_outline,
  //                     color: Colors.orange,
  //                     size: 16,
  //                   ),
  //                   const SizedBox(width: 8),
  //                   const Text(
  //                     'Fixed Penalty Amount: ',
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w500,
  //                       color: Colors.orange,
  //                     ),
  //                   ),
  //                   Text(
  //                     '₹$_fixedPenaltyAmount',
  //                     style: const TextStyle(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.orange,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(height: 16),
  //
  //             // Totals
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       'Total Payment:',
  //                       style: TextStyle(fontSize: 14, color: Colors.grey[600]),
  //                     ),
  //                     Text(
  //                       '₹${_totalSelectedAmount.toStringAsFixed(2)}',
  //                       style: const TextStyle(
  //                         fontSize: 18,
  //                         fontWeight: FontWeight.bold,
  //                         color: Colors.green,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 Column(
  //                   crossAxisAlignment: CrossAxisAlignment.center,
  //                   children: [
  //                     Text(
  //                       'Total Penalty:',
  //                       style: TextStyle(fontSize: 14, color: Colors.grey[600]),
  //                     ),
  //                     Text(
  //                       '₹${_totalSelectedPenalty.toStringAsFixed(2)}',
  //                       style: const TextStyle(
  //                         fontSize: 18,
  //                         fontWeight: FontWeight.bold,
  //                         color: Colors.red,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 Column(
  //                   crossAxisAlignment: CrossAxisAlignment.end,
  //                   children: [
  //                     Text(
  //                       'Grand Total:',
  //                       style: TextStyle(fontSize: 14, color: Colors.grey[600]),
  //                     ),
  //                     Text(
  //                       '₹${(_totalSelectedAmount + _totalSelectedPenalty).toStringAsFixed(2)}',
  //                       style: const TextStyle(
  //                         fontSize: 20,
  //                         fontWeight: FontWeight.bold,
  //                         color: Color(0xFF1E293B),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //
  //             // Important Notes
  //             const SizedBox(height: 16),
  //             Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: Colors.blue[50],
  //                 borderRadius: BorderRadius.circular(8),
  //                 border: Border.all(color: Colors.blue),
  //               ),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Row(
  //                     children: [
  //                       const Icon(
  //                         Icons.lightbulb_outline,
  //                         color: Colors.blue,
  //                         size: 16,
  //                       ),
  //                       const SizedBox(width: 8),
  //                       const Text(
  //                         'Important Notes:',
  //                         style: TextStyle(
  //                           fontSize: 14,
  //                           fontWeight: FontWeight.w500,
  //                           color: Colors.blue,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 8),
  //                   const Text(
  //                     '• Paid (✓): Full due amount stored in paidamount column, NO penalty even if overdue',
  //                     style: TextStyle(fontSize: 12, color: Colors.blue),
  //                   ),
  //                   Text(
  //                     '• Unpaid (✓): If overdue, fixed penalty (₹$_fixedPenaltyAmount) stored in penaltypaid, due amount moves to end',
  //                     style: const TextStyle(fontSize: 12, color: Colors.blue),
  //                   ),
  //                   const Text(
  //                     '• Unpaid (✓): If NOT overdue, no penalty, payment remains pending',
  //                     style: TextStyle(fontSize: 12, color: Colors.blue),
  //                   ),
  //                   const Text(
  //                     '• Payment amounts stored in: paidamount (for paid) and penaltypaid (for penalty)',
  //                     style: TextStyle(fontSize: 12, color: Colors.blue),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }
  Widget _buildPaymentScheduleTable() {
    if (_pendingPayments.isEmpty) {
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
              'Select a loan and click Search to view payment schedule',
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

    // Calculate next weekday for unpaid EMI
    String nextWeekday = '';
    if (_pendingPayments.isNotEmpty) {
      try {
        // Get the last due date from pending payments
        DateTime? lastDueDate;
        for (var payment in _pendingPayments.reversed) {
          if (payment['duedate'] != null) {
            lastDueDate = DateTime.parse(payment['duedate']);
            break;
          }
        }

        // If no due date found, use current date
        lastDueDate ??= DateTime.now();

        // Calculate next weekday (7 days from last due date)
        DateTime nextWeekdayDate = lastDueDate.add(const Duration(days: 7));
        nextWeekday = DateFormat('dd/MM/yyyy').format(nextWeekdayDate);
      } catch (e) {
        print("Error calculating next weekday: $e");
        nextWeekday = '';
      }
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
              // Success Payment Checkbox
              SizedBox(
                width: 80,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Paid',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                      const Text(
                        '(Full Amount)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Unpaid Checkbox
              SizedBox(
                width: 80,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Unpaid',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                        ),
                      ),
                      const Text(
                        '(Penalty Only)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                    ],
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Penalty',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '(Fixed Amount)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Status
              Expanded(
                flex: 1,
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
          itemCount: _pendingPayments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final payment = _pendingPayments[index];
            final selectedPayment = _selectedPayments[index];
            final dueDate = payment['duedate']?.toString() ?? '';
            final formattedDate = dueDate.isNotEmpty
                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(dueDate))
                : '';

            final isOverdue = payment['isOverdue'] ?? false;
            final penaltyAmount = payment['calculated_penalty'] ?? 0.0;

            return Container(
              height: 57,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOverdue ? Colors.red.withOpacity(0.3) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  // Success Payment Checkbox
                  SizedBox(
                    width: 80,
                    child: Center(
                      child: Tooltip(
                        message: 'Mark as Paid (Full amount, no penalty)',
                        child: Checkbox(
                          value: selectedPayment['selected'],
                          onChanged: (value) {
                            _togglePaymentSelection(index, 'success');
                          },
                          activeColor: Colors.green,
                        ),
                      ),
                    ),
                  ),

                  // Unpaid Checkbox
                  SizedBox(
                    width: 80,
                    child: Center(
                      child: Tooltip(
                        message: 'Mark as Unpaid (Collect penalty only if overdue, due amount moves to next weekday: $nextWeekday)',
                        child: Checkbox(
                          value: selectedPayment['unpaid'],
                          onChanged: (value) {
                            _togglePaymentSelection(index, 'unpaid');
                          },
                          activeColor: Colors.red,
                        ),
                      ),
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
                          color: isOverdue ? Colors.red : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),

                  // Due Date
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 14,
                              color: isOverdue ? Colors.red : const Color(0xFF374151),
                            ),
                          ),
                          if (isOverdue)
                            const Text(
                              '(Overdue)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                              ),
                            ),
                        ],
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
                          color: isOverdue ? Colors.red : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),

                  // Penalty Amount
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '₹${penaltyAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isOverdue ? Colors.red : const Color(0xFF374151),
                            ),
                          ),
                          if (isOverdue && penaltyAmount > 0)
                            Text(
                              'Fixed: ₹$_fixedPenaltyAmount',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Status
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isOverdue
                              ? Colors.red.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isOverdue ? 'Overdue' : 'Pending',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isOverdue ? Colors.red : Colors.orange,
                              ),
                            ),
                            if (selectedPayment['selected'] == true)
                              const Text(
                                'Paid: Full',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (selectedPayment['unpaid'] == true)
                              Text(
                                selectedPayment['penaltyamount'] > 0
                                    ? 'Unpaid: Penalty'
                                    : 'Unpaid: No Penalty',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: selectedPayment['penaltyamount'] > 0 ? Colors.red : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Summary Section
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              // Penalty Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.yellow),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Fixed Penalty Amount: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      '₹$_fixedPenaltyAmount',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Next Weekday Info for Unpaid EMI
              if (nextWeekday.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.purple, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'New Unpaid EMI Date: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.purple,
                        ),
                      ),
                      Text(
                        nextWeekday,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '(Next Weekday)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),

              // Totals
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Payment:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '₹${_totalSelectedAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Total Penalty:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '₹${_totalSelectedPenalty.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Grand Total:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '₹${(_totalSelectedAmount + _totalSelectedPenalty).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Important Notes
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Important Notes:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Paid (✓): Full due amount stored in paidamount column, NO penalty even if overdue',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      '• Unpaid (✓): If overdue, collects fixed penalty (₹$_fixedPenaltyAmount), due amount moves to next weekday',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    if (nextWeekday.isNotEmpty)
                      Text(
                        '• Unpaid EMI will be scheduled for: $nextWeekday',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const Text(
                      '• Unpaid (✓): If NOT overdue, no penalty, payment remains pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      '• Payment amounts stored in: paidamount (for paid) and penaltypaid (for penalty)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

              // Unpaid Warning (if any unpaid selected but not overdue)
              if (_selectedPayments.any((p) => p['unpaid'] == true && p['penaltyamount'] == 0))
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: Some selected unpaid payments are not overdue and will have no penalty.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
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
          width: 118,
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
            onPressed:
                _isLoading ||
                    _loanId == null ||
                    (_totalSelectedAmount == 0 && _totalSelectedPenalty == 0)
                ? null
                : _recordCollection,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _loanId != null &&
                      (_totalSelectedAmount > 0 || _totalSelectedPenalty > 0)
                  ? const Color(0xFF1E293B)
                  : Colors.grey,
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
                          style: TextStyle(fontSize: 20, color: Colors.white),
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
                      // First Row - Serial No, Date, Payment Mode
                      if (isWeb)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildInputField(
                                label: 'Serial No :',
                                controller: _serialNoController,
                                isReadOnly: true,
                                hintText: 'Auto serial number',
                                backgroundColor: const Color(
                                  0xFFD1D5DB,
                                ).withOpacity(0.25),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(child: _buildDateField()),
                            const SizedBox(width: 20),
                            Expanded(child: _buildPaymentModeDropdown()),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildInputField(
                              label: 'Serial No :',
                              controller: _serialNoController,
                              isReadOnly: true,
                              hintText: 'Auto serial number',
                              backgroundColor: const Color(
                                0xFFD1D5DB,
                              ).withOpacity(0.25),
                            ),
                            const SizedBox(height: 20),
                            _buildDateField(),
                            const SizedBox(height: 20),
                            _buildPaymentModeDropdown(),
                          ],
                        ),

                      const SizedBox(height: 20),

                      // Second Row - Loan Dropdown, Customer, Search Button
                      if (isWeb)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildLoanDropdown()),
                            const SizedBox(width: 20),
                            Expanded(child: _buildCustomerField()),
                            const SizedBox(width: 20),
                            Expanded(child: _buildSearchButton()),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildLoanDropdown(),
                            const SizedBox(height: 20),
                            _buildCustomerField(),
                            const SizedBox(height: 20),
                            _buildSearchButton(),
                          ],
                        ),

                      const SizedBox(height: 20),

                      // Third Row - Loan Amount, Loan Paid, Loan Balance
                      if (isWeb)
                        Row(
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
                        )
                      else
                        Column(
                          children: [
                            _buildInputField(
                              label: 'Loan Amount :',
                              controller: _loanAmountController,
                              isReadOnly: true,
                              backgroundColor: const Color(0xFFF9FAFB),
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              label: 'Loan Paid :',
                              controller: _loanPaidController,
                              isReadOnly: true,
                              backgroundColor: const Color(0xFFF9FAFB),
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              label: 'Loan Balance :',
                              controller: _loanBalanceController,
                              isReadOnly: true,
                              backgroundColor: const Color(0xFFF9FAFB),
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),

                      // Fourth Row - Penalty Amount, Penalty Paid, Penalty Balance
                      if (isWeb)
                        Row(
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
                        )
                      else
                        Column(
                          children: [
                            _buildInputField(
                              label: 'Penalty Amount :',
                              controller: _penaltyAmountController,
                              isReadOnly: true,
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              label: 'Penalty Paid :',
                              controller: _penaltyPaidController,
                              isReadOnly: true,
                              backgroundColor: const Color(0xFFF9FAFB),
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              label: 'Penalty Balance :',
                              controller: _penaltyBalanceController,
                              isReadOnly: true,
                              backgroundColor: const Color(0xFFF9FAFB),
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),

                      // Fifth Row - Total Balance
                      if (isWeb)
                        Row(
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
                                      border: Border.all(
                                        color: const Color(0xFFD1D5DB),
                                      ),
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
                        )
                      else
                        Column(
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
                                border: Border.all(
                                  color: const Color(0xFFD1D5DB),
                                ),
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

// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../services/collection_apiservice.dart';
// import '../services/loan_apiservice.dart';
//
// class CollectionEntryScreen extends StatefulWidget {
//   const CollectionEntryScreen({super.key});
//
//   @override
//   State<CollectionEntryScreen> createState() => _CollectionEntryScreenState();
// }
//
// class _CollectionEntryScreenState extends State<CollectionEntryScreen> {
//   final collectionapiservice _apiService = collectionapiservice();
//
//   // Form controllers
//   final TextEditingController _serialNoController = TextEditingController();
//   final TextEditingController _dateController = TextEditingController();
//   final TextEditingController _customerController = TextEditingController();
//   final TextEditingController _loanNoController = TextEditingController();
//   final TextEditingController _loanAmountController = TextEditingController();
//   final TextEditingController _loanPaidController = TextEditingController();
//   final TextEditingController _loanBalanceController = TextEditingController();
//   final TextEditingController _penaltyAmountController =
//       TextEditingController();
//   final TextEditingController _penaltyPaidController = TextEditingController();
//   final TextEditingController _penaltyBalanceController =
//       TextEditingController();
//   final TextEditingController _totalBalanceController = TextEditingController();
//
//   // Data
//   Map<String, dynamic>? _loanData;
//   List<dynamic> _paymentSchedule = [];
//   Map<String, dynamic> _totals = {};
//   List<Map<String, dynamic>> _selectedPayments = [];
//   List<Map<String, dynamic>> _activeLoans = [];
//   List<Map<String, dynamic>> _pendingPayments = [];
//   String? _selectedLoanId;
//
//   // UI State
//   bool _isLoading = false;
//   bool _isSearching = false;
//   bool _isLoadingLoans = true;
//   String? _errorMessage;
//   String? _selectedPaymentMode = 'Cash';
//   DateTime? _selectedDate;
//   String? _loanId;
//
//   // Totals tracking
//   double _totalSelectedAmount = 0.0;
//   double _totalSelectedPenalty = 0.0;
//   double _fixedPenaltyAmount = 0.0;
//
//   final List<String> _paymentModes = ['Cash', 'Bank Transfer', 'Cheque', 'UPI'];
//
//   @override
//   void initState() {
//     super.initState();
//     _selectedDate = DateTime.now();
//     _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
//     _initializeData();
//   }
//
//   Future<void> _initializeData() async {
//     print("=== INITIALIZING COLLECTION ENTRY DATA ===");
//     try {
//       await Future.wait([_generateCollectionNo(), _loadActiveLoans()]);
//       print("✅ Data initialization complete");
//     } catch (e) {
//       print("❌ Error initializing data: $e");
//       if (mounted) {
//         setState(() {
//           _errorMessage = "Error loading data: $e";
//         });
//       }
//     }
//   }
//
//   Future<void> _generateCollectionNo() async {
//     try {
//       final collectionNo = await _apiService.generateCollectionNo(context);
//       if (mounted && collectionNo.isNotEmpty) {
//         setState(() {
//           _serialNoController.text = collectionNo;
//         });
//         print("✅ Generated Collection No: $collectionNo");
//       }
//     } catch (e) {
//       print("❌ Error generating collection no: $e");
//       if (mounted) {
//         setState(() {
//           _serialNoController.text =
//               'COL${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
//         });
//       }
//     }
//   }
//
//   Future<void> _loadActiveLoans() async {
//     try {
//       print("Loading active loans...");
//       final loans = await _apiService.fetchActiveLoans(context);
//       print("Received ${loans.length} active loans");
//
//       if (mounted) {
//         setState(() {
//           _activeLoans = loans;
//           _isLoadingLoans = false;
//         });
//       }
//     } catch (e) {
//       print("❌ Error loading active loans: $e");
//       if (mounted) {
//         setState(() {
//           _errorMessage = "Error loading active loans";
//           _activeLoans = [];
//           _isLoadingLoans = false;
//         });
//       }
//     }
//   }
//
//   Future<void> _searchLoan() async {
//     final loanId = _selectedLoanId;
//     if (loanId == null || loanId.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select a loan first'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
//
//     // Find the selected loan
//     Map<String, dynamic>? selectedLoan;
//     for (var loan in _activeLoans) {
//       if (loan['id'] == loanId) {
//         selectedLoan = loan;
//         break;
//       }
//     }
//
//     if (selectedLoan == null || selectedLoan.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Selected loan not found in active loans list'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
//
//     final loanNo = selectedLoan['loanno']?.toString() ?? '';
//
//     if (loanNo.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Loan number is empty'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
//
//     print("🔍 Searching for loan: $loanNo");
//
//     setState(() {
//       _isSearching = true;
//       _errorMessage = null;
//       _loanData = null;
//       _paymentSchedule = [];
//       _pendingPayments.clear();
//       _selectedPayments.clear();
//       _totalSelectedAmount = 0.0;
//       _totalSelectedPenalty = 0.0;
//       _fixedPenaltyAmount = 0.0;
//     });
//
//     try {
//       final result = await _apiService.fetchLoanForCollection(context, loanNo);
//
//       if (mounted) {
//         setState(() {
//           _loanData = result['loan'];
//           _paymentSchedule = result['schedule'];
//           _totals = result['totals'];
//           _loanId = _loanData!['id'].toString();
//
//           // Get FIXED penalty amount from loan data
//           _fixedPenaltyAmount =
//               double.tryParse(
//                 _loanData?['fixed_penalty_amount']?.toString() ?? '0',
//               ) ??
//               0.0;
//           if (_fixedPenaltyAmount == 0) {
//             // Fallback to regular penalty amount
//             _fixedPenaltyAmount =
//                 double.tryParse(
//                   _loanData?['penaltyamount']?.toString() ?? '0',
//                 ) ??
//                 0.0;
//           }
//
//           // Update form fields
//           _customerController.text = _loanData!['customername'] ?? '';
//           _loanAmountController.text =
//               _loanData!['loanamount']?.toString() ?? '0.00';
//           _loanPaidController.text = _totals['loanPaid']?.toString() ?? '0.00';
//           _loanBalanceController.text =
//               _totals['pendingAmount']?.toString() ??
//               _totals['loanBalance']?.toString() ??
//               '0.00';
//
//           // Fixed Penalty Amount
//           _penaltyAmountController.text = _fixedPenaltyAmount.toStringAsFixed(
//             2,
//           );
//           _penaltyPaidController.text =
//               _totals['penaltyPaid']?.toString() ?? '0.00';
//
//           // Update penalty balance from pending penalty
//           _penaltyBalanceController.text =
//               _totals['pendingPenalty']?.toString() ?? '0.00';
//           _totalBalanceController.text =
//               _totals['totalBalance']?.toString() ?? '0.00';
//
//           // Initialize pending payments with FIXED penalty calculation
//           DateTime now = DateTime.now();
//           _pendingPayments.clear();
//           _selectedPayments.clear();
//
//           for (var payment in _paymentSchedule) {
//             if (payment['status'] == 'Pending') {
//               double penaltyAmount = 0.0;
//               bool isOverdue = false;
//
//               // Check if payment is overdue - FIXED penalty amount
//               if (payment['duedate'] != null) {
//                 DateTime dueDate = DateTime.parse(payment['duedate']);
//                 if (now.isAfter(dueDate)) {
//                   isOverdue = true;
//                   // FIXED penalty amount (not multiplied by weeks)
//                   penaltyAmount = _fixedPenaltyAmount;
//                 }
//               }
//
//               // Add to pending payments list
//               _pendingPayments.add({
//                 'dueno': payment['dueno'],
//                 'duedate': payment['duedate'],
//                 'dueamount': payment['dueamount'],
//                 'calculated_penalty': penaltyAmount,
//                 'original_penalty': payment['penaltyamount'] ?? 0.0,
//                 'status': 'Pending',
//                 'isOverdue': isOverdue,
//               });
//
//               // Add to selected payments for default selection
//               // Initially, all payments are unchecked
//               _selectedPayments.add({
//                 'dueno': payment['dueno'],
//                 'dueamount': payment['dueamount'],
//                 'penaltyamount': penaltyAmount,
//                 // This will be 0 or fixed amount
//                 'selected': false,
//                 // Default unchecked for success payment
//                 'unpaid': false,
//                 // Default unchecked for unpaid
//               });
//             }
//           }
//
//           print("✅ Found ${_pendingPayments.length} pending payments");
//           print("✅ Fixed Penalty Amount: ₹$_fixedPenaltyAmount");
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _errorMessage = e.toString();
//         });
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSearching = false;
//         });
//       }
//     }
//   }
//
//   void _onLoanSelected(String? value) {
//     print("🔽 Loan selected: $value");
//
//     if (value != null && value.isNotEmpty) {
//       try {
//         // Find the selected loan
//         Map<String, dynamic>? selectedLoan;
//         for (var loan in _activeLoans) {
//           if (loan['id'] == value) {
//             selectedLoan = loan;
//             break;
//           }
//         }
//
//         if (selectedLoan == null) {
//           print("❌ Selected loan not found in list");
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Selected loan not found'),
//               backgroundColor: Colors.red,
//             ),
//           );
//           return;
//         }
//
//         print("✅ Selected Loan: ${selectedLoan['display']}");
//
//         setState(() {
//           _selectedLoanId = value;
//           _customerController.clear();
//           _loanNoController.text = selectedLoan?['loanno']?.toString() ?? '';
//           _loanAmountController.text =
//               selectedLoan?['loanamount']?.toString() ?? '0.00';
//
//           // Clear other fields until search is performed
//           _loanPaidController.clear();
//           _loanBalanceController.clear();
//           _penaltyAmountController.clear();
//           _penaltyPaidController.clear();
//           _penaltyBalanceController.clear();
//           _totalBalanceController.clear();
//
//           _loanData = null;
//           _paymentSchedule = [];
//           _pendingPayments.clear();
//           _selectedPayments.clear();
//           _totalSelectedAmount = 0.0;
//           _totalSelectedPenalty = 0.0;
//           _fixedPenaltyAmount = 0.0;
//         });
//       } catch (e) {
//         print("❌ Error selecting loan: $e");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error selecting loan: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         setState(() {
//           _selectedLoanId = null;
//           _loanNoController.clear();
//           _customerController.clear();
//           _loanData = null;
//           _paymentSchedule = [];
//           _pendingPayments.clear();
//           _selectedPayments.clear();
//           _totalSelectedAmount = 0.0;
//           _totalSelectedPenalty = 0.0;
//           _fixedPenaltyAmount = 0.0;
//         });
//       }
//     } else {
//       setState(() {
//         _selectedLoanId = null;
//         _loanNoController.clear();
//         _customerController.clear();
//         _loanData = null;
//         _paymentSchedule = [];
//         _pendingPayments.clear();
//         _selectedPayments.clear();
//         _totalSelectedAmount = 0.0;
//         _totalSelectedPenalty = 0.0;
//         _fixedPenaltyAmount = 0.0;
//       });
//     }
//   }
//
//   void _togglePaymentSelection(int index, String type) {
//     setState(() {
//       if (type == 'success') {
//         // Toggle success payment
//         bool newSuccessValue = !_selectedPayments[index]['selected'];
//         _selectedPayments[index]['selected'] = newSuccessValue;
//
//         // If marking as success, ensure unpaid is false
//         if (newSuccessValue) {
//           _selectedPayments[index]['unpaid'] = false;
//
//           // For success payments (even if overdue), penalty becomes 0
//           // Because when paid after overdue, no penalty is charged
//           _selectedPayments[index]['penaltyamount'] = 0.0;
//         } else {
//           // Restore original penalty amount if unchecked and overdue
//           bool isOverdue = _pendingPayments[index]['isOverdue'] ?? false;
//           _selectedPayments[index]['penaltyamount'] = isOverdue
//               ? _fixedPenaltyAmount
//               : 0.0;
//         }
//       } else if (type == 'unpaid') {
//         // Toggle unpaid with penalty
//         bool newUnpaidValue = !_selectedPayments[index]['unpaid'];
//         _selectedPayments[index]['unpaid'] = newUnpaidValue;
//
//         // If marking as unpaid, ensure success is false
//         if (newUnpaidValue) {
//           _selectedPayments[index]['selected'] = false;
//
//           // Calculate penalty amount for unpaid (only if overdue)
//           bool isOverdue = _pendingPayments[index]['isOverdue'] ?? false;
//           _selectedPayments[index]['penaltyamount'] = isOverdue
//               ? _fixedPenaltyAmount
//               : 0.0;
//         } else {
//           // If unchecking unpaid, penalty becomes 0
//           _selectedPayments[index]['penaltyamount'] = 0.0;
//         }
//       }
//
//       _calculateTotals();
//     });
//   }
//
//   void _calculateTotals() {
//     double totalDue = 0.0;
//     double totalPenalty = 0.0;
//
//     for (int i = 0; i < _selectedPayments.length; i++) {
//       if (_selectedPayments[i]['selected'] == true) {
//         // Payment success - include due amount only
//         totalDue += double.parse(_selectedPayments[i]['dueamount'].toString());
//         // Penalty is 0 for success payments (even if overdue)
//         // totalPenalty += 0.0; // Already 0
//       } else if (_selectedPayments[i]['unpaid'] == true) {
//         // Payment unpaid - include penalty only (NO due amount)
//         totalPenalty += double.parse(
//           _selectedPayments[i]['penaltyamount'].toString(),
//         );
//         // No due amount collected for unpaid payments
//       }
//     }
//
//     // Update UI totals
//     setState(() {
//       _totalSelectedAmount = totalDue;
//       _totalSelectedPenalty = totalPenalty;
//
//       // Update balances based on current selection
//       double currentLoanBalance =
//           double.tryParse(_loanBalanceController.text) ?? 0.0;
//       double currentPenaltyBalance =
//           double.tryParse(_penaltyBalanceController.text) ?? 0.0;
//
//       // Loan balance reduces only when payments are marked as success
//       _loanBalanceController.text = (currentLoanBalance - totalDue)
//           .toStringAsFixed(2);
//
//       // Penalty balance reduces when penalty is collected (for unpaid payments only)
//       _penaltyBalanceController.text = (currentPenaltyBalance - totalPenalty)
//           .toStringAsFixed(2);
//
//       // Update total balance
//       double totalBalance =
//           (currentLoanBalance - totalDue) +
//           (currentPenaltyBalance - totalPenalty);
//       _totalBalanceController.text = totalBalance > 0
//           ? totalBalance.toStringAsFixed(2)
//           : '0.00';
//     });
//
//     print("📊 Updated totals - Payment: ₹$totalDue, Penalty: ₹$totalPenalty");
//   }
//
//   Future<void> _recordCollection() async {
//     if (_loanId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select and search for a loan first'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
//
//     // Check if at least one checkbox is selected
//     bool hasSelection = false;
//     for (var payment in _selectedPayments) {
//       if (payment['selected'] == true || payment['unpaid'] == true) {
//         hasSelection = true;
//         break;
//       }
//     }
//
//     if (!hasSelection) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select at least one payment (Paid or Unpaid)'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
//
//     // Check for unpaid payments without penalty (not overdue)
//     List<String> unpaidWithoutPenalty = [];
//     for (int i = 0; i < _selectedPayments.length; i++) {
//       if (_selectedPayments[i]['unpaid'] == true &&
//           _selectedPayments[i]['penaltyamount'] == 0) {
//         unpaidWithoutPenalty.add(
//           _pendingPayments[i]['dueno']?.toString() ?? '',
//         );
//       }
//     }
//
//     if (unpaidWithoutPenalty.isNotEmpty) {
//       // Show warning for unpaid payments that are not overdue
//       await showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Payment Not Overdue'),
//           content: Text(
//             'The following payments are not overdue and will have no penalty:\n\n'
//             'Due Nos: ${unpaidWithoutPenalty.join(', ')}\n\n'
//             'Do you want to continue?',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _processCollection();
//               },
//               child: const Text('Continue'),
//             ),
//           ],
//         ),
//       );
//     } else {
//       _processCollection();
//     }
//   }
//
//   Future<void> _processCollection() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       // Prepare payment data for API
//       List<Map<String, dynamic>> paymentData = [];
//
//       for (int i = 0; i < _selectedPayments.length; i++) {
//         final payment = _selectedPayments[i];
//         final pendingPayment = _pendingPayments[i];
//         final isOverdue = pendingPayment['isOverdue'] ?? false;
//
//         if (payment['selected'] == true) {
//           // SUCCESS PAYMENT: Due amount paid, penalty is 0 (even if overdue)
//           paymentData.add({
//             'dueno': payment['dueno'],
//             'dueamount': payment['dueamount'].toString(),
//             'penaltyamount': '0.00',
//             // No penalty for overdue payments when paid
//             'selected': true,
//             'unpaid': false,
//           });
//         } else if (payment['unpaid'] == true) {
//           // UNPAID: Only penalty collected if overdue, due amount jumps to last EMI
//           double penaltyToSave = isOverdue ? _fixedPenaltyAmount : 0.0;
//
//           paymentData.add({
//             'dueno': payment['dueno'],
//             'dueamount': payment['dueamount'].toString(),
//             'penaltyamount': penaltyToSave.toStringAsFixed(2),
//             // Fixed penalty or 0
//             'selected': false,
//             'unpaid': true,
//           });
//         }
//       }
//
//       final result = await _apiService.recordCollection(
//         context: context,
//         loanId: _loanId!,
//         paymentData: paymentData,
//         collectionDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
//         paymentMode: _selectedPaymentMode!,
//       );
//
//       if (result == "Success" && mounted) {
//         // Show success message with details
//         String successMessage = '✅ Collection recorded successfully!\n';
//         successMessage +=
//             'Paid Amount: ₹${_totalSelectedAmount.toStringAsFixed(2)}\n';
//         successMessage +=
//             'Penalty Collected: ₹${_totalSelectedPenalty.toStringAsFixed(2)}';
//
//         bool hasUnpaid = _selectedPayments.any(
//           (payment) => payment['unpaid'] == true,
//         );
//         bool hasUnpaidWithPenalty = _selectedPayments.any(
//           (payment) =>
//               payment['unpaid'] == true && payment['penaltyamount'] > 0,
//         );
//
//         if (hasUnpaidWithPenalty) {
//           successMessage +=
//               '\n\n⚠️ Unpaid amount(s) with penalty have been moved to new schedule entry(s)';
//         } else if (hasUnpaid) {
//           successMessage +=
//               '\n\nℹ️ Unpaid payment(s) recorded (no penalty as not overdue)';
//         }
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(successMessage),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 5),
//           ),
//         );
//         _resetForm();
//       } else if (result == "Failed") {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('❌ Failed to record collection'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('❌ Error recording collection: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   void _resetForm() async {
//     setState(() {
//       _selectedLoanId = null;
//       _customerController.clear();
//       _loanNoController.clear();
//       _loanAmountController.clear();
//       _loanData = null;
//       _paymentSchedule = [];
//       _pendingPayments.clear();
//       _selectedPayments.clear();
//       _loanPaidController.clear();
//       _loanBalanceController.clear();
//       _penaltyAmountController.clear();
//       _penaltyPaidController.clear();
//       _penaltyBalanceController.clear();
//       _totalBalanceController.clear();
//       _selectedDate = DateTime.now();
//       _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
//       _totalSelectedAmount = 0.0;
//       _totalSelectedPenalty = 0.0;
//       _fixedPenaltyAmount = 0.0;
//     });
//
//     // Regenerate collection number
//     await _generateCollectionNo();
//     print("🔄 Form reset");
//   }
//
//   Widget _buildInputField({
//     required String label,
//     required TextEditingController controller,
//     bool isReadOnly = false,
//     String? hintText,
//     Color? backgroundColor,
//     Widget? suffixIcon,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w500,
//             color: Color(0xFF374151),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           height: 47,
//           decoration: BoxDecoration(
//             color: backgroundColor ?? Colors.white,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: const Color(0xFFD1D5DB)),
//           ),
//           child: TextField(
//             controller: controller,
//             readOnly: isReadOnly,
//             decoration: InputDecoration(
//               contentPadding: const EdgeInsets.symmetric(horizontal: 16),
//               border: InputBorder.none,
//               hintText: hintText,
//               hintStyle: const TextStyle(
//                 fontSize: 16,
//                 color: Color(0xFF999999),
//               ),
//               suffixIcon: suffixIcon,
//             ),
//             style: const TextStyle(fontSize: 16, color: Color(0xFF252525)),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildLoanDropdown() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Loan No :',
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w500,
//             color: Color(0xFF374151),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           height: 47,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: const Color(0xFFD1D5DB)),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: _isLoadingLoans
//                 ? const Center(
//                     child: Padding(
//                       padding: EdgeInsets.all(12.0),
//                       child: SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       ),
//                     ),
//                   )
//                 : _activeLoans.isEmpty
//                 ? const Center(
//                     child: Padding(
//                       padding: EdgeInsets.all(12.0),
//                       child: Text(
//                         'No active loans available',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Color(0xFF999999),
//                         ),
//                       ),
//                     ),
//                   )
//                 : DropdownButtonHideUnderline(
//                     child: DropdownButton<String>(
//                       value: _selectedLoanId,
//                       isExpanded: true,
//                       icon: const Icon(
//                         Icons.arrow_drop_down,
//                         color: Colors.black,
//                         size: 24,
//                       ),
//                       hint: const Text(
//                         'Select loan',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Color(0xFF252525),
//                         ),
//                       ),
//                       items: _activeLoans.map((loan) {
//                         if (loan is Map<String, dynamic>) {
//                           return DropdownMenuItem<String>(
//                             value: loan['id']?.toString(),
//                             child: Text(
//                               loan['display']?.toString() ??
//                                   loan['loanno']?.toString() ??
//                                   'Unknown',
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 color: Color(0xFF252525),
//                               ),
//                             ),
//                           );
//                         } else {
//                           return const DropdownMenuItem<String>(
//                             value: null,
//                             child: Text(
//                               'Invalid loan data',
//                               style: TextStyle(fontSize: 16, color: Colors.red),
//                             ),
//                           );
//                         }
//                       }).toList(),
//                       onChanged: _onLoanSelected,
//                     ),
//                   ),
//           ),
//         ),
//         if (_activeLoans.isEmpty && !_isLoadingLoans)
//           Padding(
//             padding: const EdgeInsets.only(top: 4.0),
//             child: Text(
//               'No active loans found. Issue loans first.',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.orange[700],
//                 fontStyle: FontStyle.italic,
//               ),
//             ),
//           ),
//       ],
//     );
//   }
//
//   Widget _buildDateField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Date :',
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w500,
//             color: Color(0xFF374151),
//           ),
//         ),
//         const SizedBox(height: 8),
//         GestureDetector(
//           onTap: () async {
//             final DateTime? picked = await showDatePicker(
//               context: context,
//               initialDate: _selectedDate ?? DateTime.now(),
//               firstDate: DateTime(2000),
//               lastDate: DateTime(2101),
//               builder: (context, child) {
//                 return Theme(
//                   data: ThemeData.light().copyWith(
//                     primaryColor: const Color(0xFF1E293B),
//                     colorScheme: const ColorScheme.light(
//                       primary: Color(0xFF1E293B),
//                     ),
//                     buttonTheme: const ButtonThemeData(
//                       textTheme: ButtonTextTheme.primary,
//                     ),
//                   ),
//                   child: child!,
//                 );
//               },
//             );
//
//             if (picked != null && picked != _selectedDate) {
//               setState(() {
//                 _selectedDate = picked;
//                 _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
//               });
//             }
//           },
//           child: Container(
//             height: 47,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: const Color(0xFFD1D5DB)),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: Text(
//                       _dateController.text.isNotEmpty
//                           ? _dateController.text
//                           : 'Select date',
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: _dateController.text.isNotEmpty
//                             ? const Color(0xFF252525)
//                             : const Color(0xFF999999),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const Padding(
//                   padding: EdgeInsets.only(right: 16),
//                   child: Icon(
//                     Icons.calendar_today,
//                     size: 20,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildPaymentModeDropdown() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Cash/Bank :',
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w500,
//             color: Color(0xFF374151),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           height: 47,
//           decoration: BoxDecoration(
//             color: const Color(0xFFD1D5DB).withOpacity(0.25),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: DropdownButtonHideUnderline(
//               child: DropdownButton<String>(
//                 value: _selectedPaymentMode,
//                 isExpanded: true,
//                 icon: const Icon(Icons.arrow_drop_down),
//                 items: _paymentModes.map((mode) {
//                   return DropdownMenuItem<String>(
//                     value: mode,
//                     child: Text(mode, style: const TextStyle(fontSize: 16)),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedPaymentMode = value;
//                   });
//                 },
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildCustomerField() {
//     return _buildInputField(
//       label: 'Customer :',
//       controller: _customerController,
//       isReadOnly: true,
//       hintText: 'Customer will appear here',
//       backgroundColor: const Color(0xFFF9FAFB),
//     );
//   }
//
//   Widget _buildSearchButton() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 28),
//         SizedBox(
//           height: 47,
//           child: ElevatedButton.icon(
//             onPressed: _selectedLoanId != null ? _searchLoan : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _selectedLoanId != null
//                   ? const Color(0xFF1E293B)
//                   : Colors.grey,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             icon: _isSearching
//                 ? const SizedBox(
//                     width: 16,
//                     height: 16,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Colors.white,
//                     ),
//                   )
//                 : const Icon(Icons.search, size: 20),
//             label: Text(
//               _isSearching ? 'Searching...' : 'Search Loan',
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildPaymentScheduleTable() {
//     if (_pendingPayments.isEmpty) {
//       return Container(
//         padding: const EdgeInsets.all(40),
//         decoration: BoxDecoration(
//           color: const Color(0xFFF8FAFC),
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: const Color(0xFFE2E8F0)),
//         ),
//         child: Column(
//           children: [
//             Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
//             const SizedBox(height: 16),
//             const Text(
//               'No payment schedule found',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w500,
//                 color: Color(0xFF374151),
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Select a loan and click Search to view payment schedule',
//               style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       );
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Payment Schedule Report',
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w500,
//             color: Color(0xFF374151),
//           ),
//         ),
//         const SizedBox(height: 12),
//
//         // Table Header
//         Container(
//           height: 57,
//           decoration: BoxDecoration(
//             color: const Color(0xFFF8FAFC),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Row(
//             children: [
//               // Success Payment Checkbox
//               SizedBox(
//                 width: 80,
//                 child: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'Paid',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.green[700],
//                         ),
//                       ),
//                       const Text(
//                         '(0 Penalty)',
//                         style: TextStyle(
//                           fontSize: 10,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.green,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               // Unpaid Checkbox
//               SizedBox(
//                 width: 80,
//                 child: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'Unpaid',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.red[700],
//                         ),
//                       ),
//                       const Text(
//                         '(Penalty Only)',
//                         style: TextStyle(
//                           fontSize: 10,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.red,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               // Due No
//               Expanded(
//                 flex: 1,
//                 child: Center(
//                   child: Text(
//                     'Due No',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.grey[700],
//                     ),
//                   ),
//                 ),
//               ),
//
//               // Due Date
//               Expanded(
//                 flex: 2,
//                 child: Center(
//                   child: Text(
//                     'Due Date',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.grey[700],
//                     ),
//                   ),
//                 ),
//               ),
//
//               // Due Amount
//               Expanded(
//                 flex: 2,
//                 child: Center(
//                   child: Text(
//                     'Due Amount',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.grey[700],
//                     ),
//                   ),
//                 ),
//               ),
//
//               // Penalty Amount
//               Expanded(
//                 flex: 2,
//                 child: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'Penalty',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.grey[700],
//                         ),
//                       ),
//                       Text(
//                         '(Fixed Amount)',
//                         style: TextStyle(fontSize: 10, color: Colors.grey[700]),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               // Status
//               Expanded(
//                 flex: 1,
//                 child: Center(
//                   child: Text(
//                     'Status',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.grey[700],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//
//         const SizedBox(height: 8),
//
//         // Table Rows
//         ListView.separated(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           itemCount: _pendingPayments.length,
//           separatorBuilder: (context, index) => const SizedBox(height: 4),
//           itemBuilder: (context, index) {
//             final payment = _pendingPayments[index];
//             final selectedPayment = _selectedPayments[index];
//             final dueDate = payment['duedate']?.toString() ?? '';
//             final formattedDate = dueDate.isNotEmpty
//                 ? DateFormat('dd/MM/yyyy').format(DateTime.parse(dueDate))
//                 : '';
//
//             final isOverdue = payment['isOverdue'] ?? false;
//             final penaltyAmount = payment['calculated_penalty'] ?? 0.0;
//
//             return Container(
//               height: 57,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(
//                   color: isOverdue
//                       ? Colors.red.withOpacity(0.3)
//                       : const Color(0xFFE2E8F0),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   // Success Payment Checkbox
//                   SizedBox(
//                     width: 80,
//                     child: Center(
//                       child: Tooltip(
//                         message: 'Mark as Paid (No penalty even if overdue)',
//                         child: Checkbox(
//                           value: selectedPayment['selected'],
//                           onChanged: (value) {
//                             _togglePaymentSelection(index, 'success');
//                           },
//                           activeColor: Colors.green,
//                         ),
//                       ),
//                     ),
//                   ),
//
//                   // Unpaid Checkbox
//                   SizedBox(
//                     width: 80,
//                     child: Center(
//                       child: Tooltip(
//                         message:
//                             'Mark as Unpaid (Collect fixed penalty if overdue, due amount moves to end)',
//                         child: Checkbox(
//                           value: selectedPayment['unpaid'],
//                           onChanged: (value) {
//                             _togglePaymentSelection(index, 'unpaid');
//                           },
//                           activeColor: Colors.red,
//                         ),
//                       ),
//                     ),
//                   ),
//
//                   // Due No
//                   Expanded(
//                     flex: 1,
//                     child: Center(
//                       child: Text(
//                         payment['dueno']?.toString() ?? '',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                           color: isOverdue
//                               ? Colors.red
//                               : const Color(0xFF374151),
//                         ),
//                       ),
//                     ),
//                   ),
//
//                   // Due Date
//                   Expanded(
//                     flex: 2,
//                     child: Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             formattedDate,
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: isOverdue
//                                   ? Colors.red
//                                   : const Color(0xFF374151),
//                             ),
//                           ),
//                           if (isOverdue)
//                             const Text(
//                               '(Overdue)',
//                               style: TextStyle(fontSize: 10, color: Colors.red),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   // Due Amount
//                   Expanded(
//                     flex: 2,
//                     child: Center(
//                       child: Text(
//                         '₹${double.parse(payment['dueamount']?.toString() ?? '0').toStringAsFixed(2)}',
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           color: isOverdue
//                               ? Colors.red
//                               : const Color(0xFF374151),
//                         ),
//                       ),
//                     ),
//                   ),
//
//                   // Penalty Amount
//                   Expanded(
//                     flex: 2,
//                     child: Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             '₹${penaltyAmount.toStringAsFixed(2)}',
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w500,
//                               color: isOverdue
//                                   ? Colors.red
//                                   : const Color(0xFF374151),
//                             ),
//                           ),
//                           if (isOverdue && penaltyAmount > 0)
//                             Text(
//                               'Fixed: ₹$_fixedPenaltyAmount',
//                               style: const TextStyle(
//                                 fontSize: 10,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   // Status
//                   Expanded(
//                     flex: 1,
//                     child: Center(
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: isOverdue
//                               ? Colors.red.withOpacity(0.1)
//                               : Colors.orange.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               isOverdue ? 'Overdue' : 'Pending',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w500,
//                                 color: isOverdue ? Colors.red : Colors.orange,
//                               ),
//                             ),
//                             if (selectedPayment['selected'] == true)
//                               const Text(
//                                 'Will be Paid',
//                                 style: TextStyle(
//                                   fontSize: 10,
//                                   color: Colors.green,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             if (selectedPayment['unpaid'] == true)
//                               Text(
//                                 'Will be Unpaid',
//                                 style: TextStyle(
//                                   fontSize: 10,
//                                   color: selectedPayment['penaltyamount'] > 0
//                                       ? Colors.red
//                                       : Colors.orange,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//
//         // Summary Section
//         const SizedBox(height: 20),
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: const Color(0xFFF8FAFC),
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: const Color(0xFFE2E8F0)),
//           ),
//           child: Column(
//             children: [
//               // Penalty Info
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.yellow[50],
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.yellow),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(
//                       Icons.info_outline,
//                       color: Colors.orange,
//                       size: 16,
//                     ),
//                     const SizedBox(width: 8),
//                     const Text(
//                       'Fixed Penalty Amount: ',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.orange,
//                       ),
//                     ),
//                     Text(
//                       '₹$_fixedPenaltyAmount',
//                       style: const TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.orange,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),
//
//               // Totals
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Total Payment:',
//                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                       ),
//                       Text(
//                         '₹${_totalSelectedAmount.toStringAsFixed(2)}',
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.green,
//                         ),
//                       ),
//                     ],
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Text(
//                         'Total Penalty:',
//                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                       ),
//                       Text(
//                         '₹${_totalSelectedPenalty.toStringAsFixed(2)}',
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.red,
//                         ),
//                       ),
//                     ],
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(
//                         'Grand Total:',
//                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                       ),
//                       Text(
//                         '₹${(_totalSelectedAmount + _totalSelectedPenalty).toStringAsFixed(2)}',
//                         style: const TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF1E293B),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//
//               // Important Notes
//               const SizedBox(height: 16),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.blue[50],
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.blue),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         const Icon(
//                           Icons.lightbulb_outline,
//                           color: Colors.blue,
//                           size: 16,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text(
//                           'Important Notes:',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.blue,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     const Text(
//                       '• Paid (✓): Collects due amount only, NO penalty even if overdue',
//                       style: TextStyle(fontSize: 12, color: Colors.blue),
//                     ),
//                     Text(
//                       '• Unpaid (✓): If overdue, collects fixed penalty (₹$_fixedPenaltyAmount) and due amount moves to end',
//                       style: const TextStyle(fontSize: 12, color: Colors.blue),
//                     ),
//                     const Text(
//                       '• Unpaid (✓): If NOT overdue, no penalty collected, payment remains pending',
//                       style: TextStyle(fontSize: 12, color: Colors.blue),
//                     ),
//                     const Text(
//                       '• Penalty: Fixed amount, not multiplied by weeks overdue',
//                       style: TextStyle(fontSize: 12, color: Colors.blue),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildActionButtons() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         SizedBox(
//           width: 118,
//           height: 50,
//           child: OutlinedButton(
//             onPressed: _isLoading ? null : _resetForm,
//             style: OutlinedButton.styleFrom(
//               side: const BorderSide(color: Color(0xFFD1D5DB)),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: const Text(
//               'Cancel',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: Color(0xFF374151),
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 16),
//         SizedBox(
//           width: 171,
//           height: 50,
//           child: ElevatedButton(
//             onPressed:
//                 _isLoading ||
//                     _loanId == null ||
//                     (_totalSelectedAmount == 0 && _totalSelectedPenalty == 0)
//                 ? null
//                 : _recordCollection,
//             style: ElevatedButton.styleFrom(
//               backgroundColor:
//                   _loanId != null &&
//                       (_totalSelectedAmount > 0 || _totalSelectedPenalty > 0)
//                   ? const Color(0xFF1E293B)
//                   : Colors.grey,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: _isLoading
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Colors.white,
//                     ),
//                   )
//                 : const Text(
//                     'Collect Payment',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.white,
//                     ),
//                   ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: EdgeInsets.symmetric(
//             horizontal: isWeb ? 32 : 16,
//             vertical: isWeb ? 32 : 16,
//           ),
//           child: Center(
//             child: Container(
//               constraints: BoxConstraints(
//                 maxWidth: isWeb ? 1271 : double.infinity,
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Header
//                   Container(
//                     width: double.infinity,
//                     height: 110,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF1E293B),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     padding: EdgeInsets.symmetric(
//                       horizontal: isWeb ? 32 : 20,
//                       vertical: 20,
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Text(
//                           'Collection Entry :',
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         const Text(
//                           'Record loan collection and payment details',
//                           style: TextStyle(fontSize: 20, color: Colors.white),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   // Error message
//                   if (_errorMessage != null)
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       margin: const EdgeInsets.only(bottom: 20),
//                       decoration: BoxDecoration(
//                         color: Colors.red[50],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.red),
//                       ),
//                       child: Row(
//                         children: [
//                           const Icon(Icons.error, color: Colors.red),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Text(
//                               _errorMessage!,
//                               style: const TextStyle(color: Colors.red),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                   // Form
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // First Row - Serial No, Date, Payment Mode
//                       if (isWeb)
//                         Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Expanded(
//                               child: _buildInputField(
//                                 label: 'Serial No :',
//                                 controller: _serialNoController,
//                                 isReadOnly: true,
//                                 hintText: 'Auto serial number',
//                                 backgroundColor: const Color(
//                                   0xFFD1D5DB,
//                                 ).withOpacity(0.25),
//                               ),
//                             ),
//                             const SizedBox(width: 20),
//                             Expanded(child: _buildDateField()),
//                             const SizedBox(width: 20),
//                             Expanded(child: _buildPaymentModeDropdown()),
//                           ],
//                         )
//                       else
//                         Column(
//                           children: [
//                             _buildInputField(
//                               label: 'Serial No :',
//                               controller: _serialNoController,
//                               isReadOnly: true,
//                               hintText: 'Auto serial number',
//                               backgroundColor: const Color(
//                                 0xFFD1D5DB,
//                               ).withOpacity(0.25),
//                             ),
//                             const SizedBox(height: 20),
//                             _buildDateField(),
//                             const SizedBox(height: 20),
//                             _buildPaymentModeDropdown(),
//                           ],
//                         ),
//
//                       const SizedBox(height: 20),
//
//                       // Second Row - Loan Dropdown, Customer, Search Button
//                       if (isWeb)
//                         Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Expanded(child: _buildLoanDropdown()),
//                             const SizedBox(width: 20),
//                             Expanded(child: _buildCustomerField()),
//                             const SizedBox(width: 20),
//                             Expanded(child: _buildSearchButton()),
//                           ],
//                         )
//                       else
//                         Column(
//                           children: [
//                             _buildLoanDropdown(),
//                             const SizedBox(height: 20),
//                             _buildCustomerField(),
//                             const SizedBox(height: 20),
//                             _buildSearchButton(),
//                           ],
//                         ),
//
//                       const SizedBox(height: 20),
//
//                       // Third Row - Loan Amount, Loan Paid, Loan Balance
//                       if (isWeb)
//                         Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Expanded(
//                               child: _buildInputField(
//                                 label: 'Loan Amount :',
//                                 controller: _loanAmountController,
//                                 isReadOnly: true,
//                                 backgroundColor: const Color(0xFFF9FAFB),
//                               ),
//                             ),
//                             const SizedBox(width: 20),
//                             Expanded(
//                               child: _buildInputField(
//                                 label: 'Loan Paid :',
//                                 controller: _loanPaidController,
//                                 isReadOnly: true,
//                                 backgroundColor: const Color(0xFFF9FAFB),
//                               ),
//                             ),
//                             const SizedBox(width: 20),
//                             Expanded(
//                               child: _buildInputField(
//                                 label: 'Loan Balance :',
//                                 controller: _loanBalanceController,
//                                 isReadOnly: true,
//                                 backgroundColor: const Color(0xFFF9FAFB),
//                               ),
//                             ),
//                           ],
//                         )
//                       else
//                         Column(
//                           children: [
//                             _buildInputField(
//                               label: 'Loan Amount :',
//                               controller: _loanAmountController,
//                               isReadOnly: true,
//                               backgroundColor: const Color(0xFFF9FAFB),
//                             ),
//                             const SizedBox(height: 20),
//                             _buildInputField(
//                               label: 'Loan Paid :',
//                               controller: _loanPaidController,
//                               isReadOnly: true,
//                               backgroundColor: const Color(0xFFF9FAFB),
//                             ),
//                             const SizedBox(height: 20),
//                             _buildInputField(
//                               label: 'Loan Balance :',
//                               controller: _loanBalanceController,
//                               isReadOnly: true,
//                               backgroundColor: const Color(0xFFF9FAFB),
//                             ),
//                           ],
//                         ),
//
//                       const SizedBox(height: 20),
//
//                       // Fourth Row - Penalty Amount, Penalty Paid, Penalty Balance
//                       if (isWeb)
//                         Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Expanded(
//                               child: _buildInputField(
//                                 label: 'Penalty Amount :',
//                                 controller: _penaltyAmountController,
//                                 isReadOnly: true,
//                               ),
//                             ),
//                             const SizedBox(width: 20),
//                             Expanded(
//                               child: _buildInputField(
//                                 label: 'Penalty Paid :',
//                                 controller: _penaltyPaidController,
//                                 isReadOnly: true,
//                                 backgroundColor: const Color(0xFFF9FAFB),
//                               ),
//                             ),
//                             const SizedBox(width: 20),
//                             Expanded(
//                               child: _buildInputField(
//                                 label: 'Penalty Balance :',
//                                 controller: _penaltyBalanceController,
//                                 isReadOnly: true,
//                                 backgroundColor: const Color(0xFFF9FAFB),
//                               ),
//                             ),
//                           ],
//                         )
//                       else
//                         Column(
//                           children: [
//                             _buildInputField(
//                               label: 'Penalty Amount :',
//                               controller: _penaltyAmountController,
//                               isReadOnly: true,
//                             ),
//                             const SizedBox(height: 20),
//                             _buildInputField(
//                               label: 'Penalty Paid :',
//                               controller: _penaltyPaidController,
//                               isReadOnly: true,
//                               backgroundColor: const Color(0xFFF9FAFB),
//                             ),
//                             const SizedBox(height: 20),
//                             _buildInputField(
//                               label: 'Penalty Balance :',
//                               controller: _penaltyBalanceController,
//                               isReadOnly: true,
//                               backgroundColor: const Color(0xFFF9FAFB),
//                             ),
//                           ],
//                         ),
//
//                       const SizedBox(height: 20),
//
//                       // Fifth Row - Total Balance
//                       if (isWeb)
//                         Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Expanded(child: SizedBox()),
//                             const SizedBox(width: 20),
//                             const Expanded(child: SizedBox()),
//                             const SizedBox(width: 20),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const Text(
//                                     'Total Balance :',
//                                     style: TextStyle(
//                                       fontSize: 20,
//                                       fontWeight: FontWeight.w500,
//                                       color: Color(0xFF374151),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Container(
//                                     height: 47,
//                                     decoration: BoxDecoration(
//                                       color: const Color(0xFFF9FAFB),
//                                       borderRadius: BorderRadius.circular(8),
//                                       border: Border.all(
//                                         color: const Color(0xFFD1D5DB),
//                                       ),
//                                     ),
//                                     child: Center(
//                                       child: Text(
//                                         '₹${_totalBalanceController.text}',
//                                         style: const TextStyle(
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.w500,
//                                           color: Color(0xFF374151),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         )
//                       else
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Total Balance :',
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.w500,
//                                 color: Color(0xFF374151),
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Container(
//                               height: 47,
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFFF9FAFB),
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(
//                                   color: const Color(0xFFD1D5DB),
//                                 ),
//                               ),
//                               child: Center(
//                                 child: Text(
//                                   '₹${_totalBalanceController.text}',
//                                   style: const TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w500,
//                                     color: Color(0xFF374151),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//
//                       const SizedBox(height: 40),
//
//                       // Payment Schedule Table
//                       _buildPaymentScheduleTable(),
//
//                       const SizedBox(height: 40),
//
//                       // Action Buttons
//                       _buildActionButtons(),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//

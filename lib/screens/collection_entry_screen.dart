import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
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
  final TextEditingController _penaltyAmountController = TextEditingController();
  final TextEditingController _penaltyPaidController = TextEditingController();
  final TextEditingController _penaltyBalanceController = TextEditingController();
  final TextEditingController _totalBalanceController = TextEditingController();

  // New controllers for received amounts
  final TextEditingController _dueReceivedController = TextEditingController();
  final TextEditingController _penaltyReceivedController = TextEditingController();

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
  double _totalDueReceived = 0.0;
  double _totalPenaltyReceived = 0.0;

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
      _totalDueReceived = 0.0;
      _totalPenaltyReceived = 0.0;
      _dueReceivedController.clear();
      _penaltyReceivedController.clear();
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
          _loanNoController.text = loanNo;

          // Loan amount
          double loanAmount = double.tryParse(_loanData!['loanamount']?.toString() ?? '0') ?? 0.0;
          _loanAmountController.text = loanAmount.toStringAsFixed(2);

          // Loan paid amount from totals (Rule 5: includes partial paid amount)
          double loanPaid = double.tryParse(_totals['loanPaid']?.toString() ?? '0') ?? 0.0;
          _loanPaidController.text = loanPaid.toStringAsFixed(2);

          // Calculate loan balance: loan amount - loan paid amount (Rule 5)
          double loanBalance = loanAmount - loanPaid;
          _loanBalanceController.text = loanBalance.toStringAsFixed(2);

          // Initialize penalty paid from totals
          double penaltyPaid = double.tryParse(_totals['penaltyPaid']?.toString() ?? '0') ?? 0.0;
          _penaltyPaidController.text = penaltyPaid.toStringAsFixed(2);

          // Initialize penalty balance
          double penaltyBalance = double.tryParse(_totals['pendingPenalty']?.toString() ?? '0') ?? 0.0;
          _penaltyBalanceController.text = penaltyBalance.toStringAsFixed(2);

          double totalPenaltyDue = penaltyBalance + penaltyPaid; // This shows total penalty including paid



          // Total balance (loan balance + penalty balance)
          double totalBalance = loanBalance + penaltyBalance;
          _totalBalanceController.text = totalBalance.toStringAsFixed(2);

          // Initialize pending payments with FIXED penalty calculation
          DateTime now = DateTime.now();
          _pendingPayments.clear();
          _selectedPayments.clear();

          for (var payment in _paymentSchedule) {
            // Get already received amounts
            double dueReceived = double.tryParse(payment['due_received']?.toString() ?? '0') ?? 0.0;
            double penaltyReceived = double.tryParse(payment['penalty_received']?.toString() ?? '0') ?? 0.0;
            double dueAmount = double.tryParse(payment['dueamount']?.toString() ?? '0') ?? 0.0;

            // Check if payment is fully paid (Rule 3)
            bool isDueFullyPaid = (dueReceived >= dueAmount);
            bool isPenaltyFullyPaid = (penaltyReceived >= _fixedPenaltyAmount);

            // Rule 3: Only include payments that are not fully paid
            if (!isDueFullyPaid || !isPenaltyFullyPaid) {

              double penaltyAmount = 0.0;
              bool isOverdue = false;

              // Calculate remaining amounts
              double remainingDue = dueAmount - dueReceived;
              double remainingPenalty = 0.0;

              // Check if payment is overdue - FIXED penalty amount
              if (payment['duedate'] != null) {
                DateTime dueDate = DateTime.parse(payment['duedate']);
                if (now.isAfter(dueDate)) {
                  isOverdue = true;
                  // Calculate remaining penalty
                  remainingPenalty = _fixedPenaltyAmount - penaltyReceived;
                  if (remainingPenalty > 0) {
                    penaltyAmount = remainingPenalty;
                  }
                }
              }

              // Add to pending payments list
              _pendingPayments.add({
                'dueno': payment['dueno'],
                'duedate': payment['duedate'],
                'dueamount': remainingDue, // Show remaining due amount
                'original_due': dueAmount, // Keep original due for reference
                'due_received': dueReceived, // Already received amount
                'penalty_received': penaltyReceived, // Already received penalty
                'calculated_penalty': penaltyAmount,
                'status': payment['status'],
                'isOverdue': isOverdue,
                'is_due_fully_paid': isDueFullyPaid,
                'is_penalty_fully_paid': isPenaltyFullyPaid,
              });

              // Add to selected payments
              // Rule 4: Don't default check checkboxes
              _selectedPayments.add({
                'dueno': payment['dueno'],
                'dueamount': remainingDue,
                'original_due': dueAmount,
                'penaltyamount': penaltyAmount,
                'selected': false, // Rule 4: Don't default check
                'unpaid': false, // Rule 4: Don't default check
                'paidamount': remainingDue,
                'due_received': 0.0, // Don't pre-fill
                'penalty_received': 0.0, // Don't pre-fill
                'already_received_due': dueReceived,
                'already_received_penalty': penaltyReceived,
                'is_due_fully_paid': isDueFullyPaid,
                'is_penalty_fully_paid': isPenaltyFullyPaid,
              });
            }
          }

          print("✅ Found ${_pendingPayments.length} pending/partially paid payments");
          print("✅ Fixed Penalty Amount: ₹$_fixedPenaltyAmount");
          print("✅ Loan Amount: ₹$loanAmount");
          print("✅ Loan Paid (Rule 5): ₹$loanPaid");
          print("✅ Loan Balance (Rule 5): ₹$loanBalance");
          print("✅ Penalty Info: Total Due: ₹$totalPenaltyDue, Already Paid: ₹$penaltyPaid, Remaining: ₹$penaltyBalance");

          // Count fully paid payments
          int fullyPaidCount = 0;
          for (var payment in _paymentSchedule) {
            double dueReceived = double.tryParse(payment['due_received']?.toString() ?? '0') ?? 0.0;
            double dueAmount = double.tryParse(payment['dueamount']?.toString() ?? '0') ?? 0.0;
            double penaltyReceived = double.tryParse(payment['penalty_received']?.toString() ?? '0') ?? 0.0;

            bool isDueFullyPaid = (dueReceived >= dueAmount);
            bool isPenaltyFullyPaid = (penaltyReceived >= _fixedPenaltyAmount);

            if (isDueFullyPaid && isPenaltyFullyPaid) {
              fullyPaidCount++;
            }
          }
          print("✅ Fully paid payments (excluded): $fullyPaidCount");
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
          _dueReceivedController.clear();
          _penaltyReceivedController.clear();

          _loanData = null;
          _paymentSchedule = [];
          _pendingPayments.clear();
          _selectedPayments.clear();
          _totalSelectedAmount = 0.0;
          _totalSelectedPenalty = 0.0;
          _fixedPenaltyAmount = 0.0;
          _totalDueReceived = 0.0;
          _totalPenaltyReceived = 0.0;
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
          _totalDueReceived = 0.0;
          _totalPenaltyReceived = 0.0;
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
        _totalDueReceived = 0.0;
        _totalPenaltyReceived = 0.0;
      });
    }
  }

  void _togglePaymentSelection(int index, String type) {
    // Check if partial penalty has been paid already
    double alreadyReceivedPenalty = double.tryParse(_selectedPayments[index]['already_received_penalty']?.toString() ?? '0') ?? 0.0;

    // Rule: If partial penalty paid, don't allow due amount collection
    if (type == 'success' && alreadyReceivedPenalty > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot collect due amount. Partial penalty (₹${alreadyReceivedPenalty.toStringAsFixed(2)}) already paid. You can only collect remaining penalty.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    // Check if payment is already fully paid
    bool isDueFullyPaid = _selectedPayments[index]['is_due_fully_paid'] ?? false;
    bool isPenaltyFullyPaid = _selectedPayments[index]['is_penalty_fully_paid'] ?? false;

    if (type == 'success' && isDueFullyPaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This payment is already fully paid'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (type == 'unpaid' && isPenaltyFullyPaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penalty for this payment is already fully paid'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check if trying to toggle unpaid for non-overdue payment
    if (type == 'unpaid') {
      final isOverdue = _pendingPayments[index]['isOverdue'] ?? false;
      if (!isOverdue) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unpaid option is only available for overdue payments'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    setState(() {
      if (type == 'success') {
        // Rule 2: If selecting Paid, uncheck Unpaid
        _selectedPayments[index]['unpaid'] = false;
        bool newSuccessValue = !_selectedPayments[index]['selected'];
        _selectedPayments[index]['selected'] = newSuccessValue;

        if (newSuccessValue) {
          // Auto-fill due received with remaining due amount
          _selectedPayments[index]['due_received'] = _selectedPayments[index]['dueamount'];
          // Rule 7: Reset penalty received and amount
          _selectedPayments[index]['penalty_received'] = 0.0;
          _selectedPayments[index]['penaltyamount'] = 0.0;
        } else {
          // Reset values if unchecking
          _selectedPayments[index]['due_received'] = 0.0;
          _selectedPayments[index]['penalty_received'] = 0.0;
          // Restore original penalty amount if overdue
          bool isOverdue = _pendingPayments[index]['isOverdue'] ?? false;
          if (isOverdue) {
            double alreadyReceivedPenalty = double.tryParse(_selectedPayments[index]['already_received_penalty']?.toString() ?? '0') ?? 0.0;
            _selectedPayments[index]['penaltyamount'] = _fixedPenaltyAmount - alreadyReceivedPenalty;
          }
        }

      } else if (type == 'unpaid') {
        // Rule 2: If selecting Unpaid, uncheck Paid
        _selectedPayments[index]['selected'] = false;
        bool newUnpaidValue = !_selectedPayments[index]['unpaid'];
        _selectedPayments[index]['unpaid'] = newUnpaidValue;

        if (newUnpaidValue) {
          // Auto-fill penalty received with remaining penalty
          _selectedPayments[index]['penalty_received'] = _selectedPayments[index]['penaltyamount'];
          // Rule 2: Reset due received
          _selectedPayments[index]['due_received'] = 0.0;
        } else {
          // Reset values if unchecking
          _selectedPayments[index]['due_received'] = 0.0;
          _selectedPayments[index]['penalty_received'] = 0.0;
        }
      }

      // Update totals
      _updateTotalsOnly();
    });
  }

  void _onDueReceivedChanged(int index, String value) {
    double newValue = double.tryParse(value) ?? 0.0;
    double dueAmount = double.tryParse(_selectedPayments[index]['dueamount'].toString()) ?? 0.0;

    // Validate: Cannot exceed remaining due amount
    if (newValue > dueAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Due received cannot exceed ₹${dueAmount.toStringAsFixed(2)}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _selectedPayments[index]['due_received'] = newValue;
    });

    _updateTotalsOnly();
  }

  void _onPenaltyReceivedChanged(int index, String value) {
    double newValue = double.tryParse(value) ?? 0.0;
    double penaltyAmount = double.tryParse(_selectedPayments[index]['penaltyamount'].toString()) ?? 0.0;

    // Validate: Cannot exceed remaining penalty amount
    if (newValue > penaltyAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Penalty received cannot exceed ₹${penaltyAmount.toStringAsFixed(2)}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _selectedPayments[index]['penalty_received'] = newValue;
    });

    _updateTotalsOnly();
  }

  // Add a method to check if amounts are partially paid
// Update the _getPaymentStatus method to show better status for partial penalty:
  String _getPaymentStatus(Map<String, dynamic> payment, bool isOverdue) {
    double originalDue = double.tryParse(payment['original_due']?.toString() ?? payment['dueamount'].toString()) ?? 0.0;
    double dueReceived = double.tryParse(payment['due_received']?.toString() ?? '0') ?? 0.0;
    double alreadyReceivedDue = double.tryParse(payment['already_received_due']?.toString() ?? '0') ?? 0.0;
    double totalDueReceived = dueReceived + alreadyReceivedDue;

    double penaltyAmount = double.tryParse(payment['penaltyamount'].toString()) ?? 0.0;
    double penaltyReceived = double.tryParse(payment['penalty_received']?.toString() ?? '0') ?? 0.0;
    double alreadyReceivedPenalty = double.tryParse(payment['already_received_penalty']?.toString() ?? '0') ?? 0.0;
    double totalPenaltyReceived = penaltyReceived + alreadyReceivedPenalty;

    // Check if fully paid
    bool isDueFullyPaid = payment['is_due_fully_paid'] ?? false;
    bool isPenaltyFullyPaid = payment['is_penalty_fully_paid'] ?? false;

    // Check if already has partial penalty payment
    bool hasPartialPenalty = (alreadyReceivedPenalty > 0 && alreadyReceivedPenalty < _fixedPenaltyAmount);

    if (payment['selected'] == true) {
      if (totalDueReceived == 0) {
        return 'Not Paid';
      } else if (totalDueReceived >= originalDue || isDueFullyPaid) {
        return 'Fully Paid';
      } else {
        return 'Partially Paid: ₹${totalDueReceived.toStringAsFixed(2)}/₹${originalDue.toStringAsFixed(2)}';
      }
    } else if (payment['unpaid'] == true) {
      if (totalPenaltyReceived == 0) {
        return hasPartialPenalty ? 'Partially Paid Penalty' : 'Not Paid';
      } else if (totalPenaltyReceived >= (penaltyAmount + alreadyReceivedPenalty) || isPenaltyFullyPaid) {
        return 'Penalty Paid';
      } else {
        return 'Partially Paid Penalty: ₹${totalPenaltyReceived.toStringAsFixed(2)}/₹${_fixedPenaltyAmount.toStringAsFixed(2)}';
      }
    }

    // For unselected payments, show their current status
    if (hasPartialPenalty) {
      return 'Partially Paid Penalty';
    }

    return isOverdue ? 'Overdue' : 'Pending';
  }

  void _updateTotalsOnly() {
    double totalDue = 0.0;
    double totalPenalty = 0.0;
    double totalDueReceived = 0.0;
    double totalPenaltyReceived = 0.0;

    for (int i = 0; i < _selectedPayments.length; i++) {
      // Safely convert string to double from received fields
      double dueReceived = double.tryParse(_selectedPayments[i]['due_received']?.toString() ?? '0') ?? 0.0;
      double penaltyReceived = double.tryParse(_selectedPayments[i]['penalty_received']?.toString() ?? '0') ?? 0.0;

      // Rule 6: Use received amounts for totals
      totalDueReceived += dueReceived;
      totalPenaltyReceived += penaltyReceived;

      // For display purposes (not for calculation)
      if (_selectedPayments[i]['selected'] == true) {
        totalDue += double.tryParse(_selectedPayments[i]['dueamount'].toString()) ?? 0.0;
      } else if (_selectedPayments[i]['unpaid'] == true) {
        totalPenalty += double.tryParse(_selectedPayments[i]['penaltyamount'].toString()) ?? 0.0;
      }
    }

    // Update totals - Rule 6: Use received amounts
    setState(() {
      _totalSelectedAmount = totalDue;
      _totalSelectedPenalty = totalPenalty;
      _totalDueReceived = totalDueReceived;
      _totalPenaltyReceived = totalPenaltyReceived;
      _dueReceivedController.text = totalDueReceived.toStringAsFixed(2);
      _penaltyReceivedController.text = totalPenaltyReceived.toStringAsFixed(2);
    });

    print("📊 Updated totals - Due Received: ₹$totalDueReceived, Penalty Received: ₹$totalPenaltyReceived");
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
        unpaidWithoutPenalty.add(_pendingPayments[i]['dueno']?.toString() ?? '');
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
                  'Do you want to continue?'
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
          // SUCCESS PAYMENT: Use editable due received amount
          double dueReceived = double.tryParse(payment['due_received']?.toString() ?? '0') ?? 0.0;
          double penaltyReceived = 0.0; // Rule 7: No penalty for success payments

          paymentData.add({
            'dueno': payment['dueno'],
            'dueamount': payment['original_due'].toString(), // Send original due amount
            'paidamount': dueReceived.toString(), // Save as paidamount
            'penaltyamount': '0.00', // Rule 7: No penalty
            'due_received': dueReceived.toString(), // Save in due_received column
            'penalty_received': penaltyReceived.toString(), // Save in penalty_received column
            'selected': true,
            'unpaid': false,
          });
        } else if (payment['unpaid'] == true) {
          // UNPAID: Use editable penalty received amount
          double penaltyReceived = double.tryParse(payment['penalty_received']?.toString() ?? '0') ?? 0.0;
          double dueReceived = 0.0; // Rule 2: No due amount for unpaid payments

          paymentData.add({
            'dueno': payment['dueno'],
            'dueamount': payment['original_due'].toString(), // Send original due amount
            'paidamount': '0.00', // Rule 2: No paid amount for unpaid
            'penaltyamount': penaltyReceived.toString(), // Save as penaltyamount
            'due_received': dueReceived.toString(), // Save in due_received column
            'penalty_received': penaltyReceived.toString(), // Save in penalty_received column
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
        // Calculate current values
        double currentLoanAmount = double.tryParse(_loanAmountController.text) ?? 0.0;
        double currentLoanPaid = double.tryParse(_loanPaidController.text) ?? 0.0;
        double currentPenaltyPaid = double.tryParse(_penaltyPaidController.text) ?? 0.0;

        // Add received amounts to loan paid (Rule 5)
        double newLoanPaid = currentLoanPaid + _totalDueReceived;
        _loanPaidController.text = newLoanPaid.toStringAsFixed(2);

        // Recalculate loan balance: loan amount - loan paid amount (Rule 5)
        double newLoanBalance = currentLoanAmount - newLoanPaid;
        _loanBalanceController.text = newLoanBalance.toStringAsFixed(2);

        // Update penalty paid
        double newPenaltyPaid = currentPenaltyPaid + _totalPenaltyReceived;
        _penaltyPaidController.text = newPenaltyPaid.toStringAsFixed(2);

        // Calculate penalty balance (get pending penalty from totals)
        double totalPendingPenalty = double.tryParse(_totals['pendingPenalty']?.toString() ?? '0') ?? 0.0;
        double newPenaltyBalance = totalPendingPenalty - _totalPenaltyReceived;
        if (newPenaltyBalance < 0) newPenaltyBalance = 0.0;
        _penaltyBalanceController.text = newPenaltyBalance.toStringAsFixed(2);

        // Update total balance
        double totalBalance = newLoanBalance + newPenaltyBalance;
        _totalBalanceController.text = totalBalance > 0 ? totalBalance.toStringAsFixed(2) : '0.00';

        // Show success message with details
        String successMessage = '✅ Collection recorded successfully!\n';
        successMessage += 'Due Received: ₹${_totalDueReceived.toStringAsFixed(2)}\n'; // Rule 6
        successMessage += 'Penalty Received: ₹${_totalPenaltyReceived.toStringAsFixed(2)}\n'; // Rule 6
        successMessage += 'Updated Loan Paid: ₹${newLoanPaid.toStringAsFixed(2)}\n';
        successMessage += 'Updated Loan Balance: ₹${newLoanBalance.toStringAsFixed(2)}\n';
        successMessage += 'Updated Penalty Balance: ₹${newPenaltyBalance.toStringAsFixed(2)}';

        bool hasUnpaid = _selectedPayments.any((payment) => payment['unpaid'] == true);
        bool hasUnpaidWithPenalty = _selectedPayments.any((payment) =>
        payment['unpaid'] == true && payment['penaltyamount'] > 0);

        if (hasUnpaidWithPenalty) {
          successMessage += '\n\n⚠️ Unpaid amount(s) with penalty - Due amount moved to new EMI';
        } else if (hasUnpaid) {
          successMessage += '\n\nℹ️ Unpaid payment(s) recorded (no penalty as not overdue)';
        }

        // Check for partially paid amounts
        List<String> partiallyPaid = [];
        for (int i = 0; i < _selectedPayments.length; i++) {
          final payment = _selectedPayments[i];
          if (payment['selected'] == true) {
            double dueAmount = double.tryParse(payment['dueamount'].toString()) ?? 0.0;
            double dueReceived = double.tryParse(payment['due_received']?.toString() ?? '0') ?? 0.0;
            if (dueReceived > 0 && dueReceived < dueAmount) {
              partiallyPaid.add('Due ${payment['dueno']}: ₹${dueReceived.toStringAsFixed(2)}/₹${dueAmount.toStringAsFixed(2)}');
            }
          } else if (payment['unpaid'] == true) {
            double penaltyAmount = double.tryParse(payment['penaltyamount'].toString()) ?? 0.0;
            double penaltyReceived = double.tryParse(payment['penalty_received']?.toString() ?? '0') ?? 0.0;
            if (penaltyReceived > 0 && penaltyReceived < penaltyAmount) {
              partiallyPaid.add('Due ${payment['dueno']} Penalty: ₹${penaltyReceived.toStringAsFixed(2)}/₹${penaltyAmount.toStringAsFixed(2)}');
            }
          }
        }

        if (partiallyPaid.isNotEmpty) {
          successMessage += '\n\n⚠️ Partially Paid (will remain in schedule):\n${partiallyPaid.join('\n')}';
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
      _dueReceivedController.clear();
      _penaltyReceivedController.clear();
      _selectedDate = DateTime.now();
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
      _totalSelectedAmount = 0.0;
      _totalSelectedPenalty = 0.0;
      _fixedPenaltyAmount = 0.0;
      _totalDueReceived = 0.0;
      _totalPenaltyReceived = 0.0;
    });

    // Regenerate collection number
    await _generateCollectionNo();
    print("🔄 Form reset");
  }

  String _formatAmount(dynamic amount) {
    try {
      if (amount == null) return '₹0.00';

      if (amount is double) {
        return '₹${amount.toStringAsFixed(2)}';
      } else if (amount is int) {
        return '₹${amount.toDouble().toStringAsFixed(2)}';
      } else if (amount is String) {
        // Remove currency symbol if present
        String cleanAmount = amount.replaceAll('₹', '').replaceAll(',', '').trim();

        // Try to parse the string
        double parsed = double.tryParse(cleanAmount) ?? 0.0;
        return '₹${parsed.toStringAsFixed(2)}';
      } else {
        // Try to convert to string and then parse
        double parsed = double.tryParse(amount.toString()) ?? 0.0;
        return '₹${parsed.toStringAsFixed(2)}';
      }
    } catch (e) {
      print("Error formatting amount '$amount': $e");
      return '₹0.00';
    }
  }

  // Add helper methods for status colors
  Color _getStatusColor(Map<String, dynamic> payment, bool isOverdue) {
    double originalDue = double.tryParse(payment['original_due']?.toString() ?? payment['dueamount'].toString()) ?? 0.0;
    double dueReceived = double.tryParse(payment['due_received']?.toString() ?? '0') ?? 0.0;
    double alreadyReceivedDue = double.tryParse(payment['already_received_due']?.toString() ?? '0') ?? 0.0;
    double totalDueReceived = dueReceived + alreadyReceivedDue;

    double penaltyAmount = double.tryParse(payment['penaltyamount'].toString()) ?? 0.0;
    double penaltyReceived = double.tryParse(payment['penalty_received']?.toString() ?? '0') ?? 0.0;
    double alreadyReceivedPenalty = double.tryParse(payment['already_received_penalty']?.toString() ?? '0') ?? 0.0;
    double totalPenaltyReceived = penaltyReceived + alreadyReceivedPenalty;

    if (payment['selected'] == true) {
      if (totalDueReceived == 0) return Colors.grey.withOpacity(0.1);
      if (totalDueReceived < originalDue) return Colors.orange.withOpacity(0.1);
      return Colors.green.withOpacity(0.1);
    } else if (payment['unpaid'] == true) {
      if (totalPenaltyReceived == 0) return Colors.grey.withOpacity(0.1);
      if (totalPenaltyReceived < penaltyAmount + alreadyReceivedPenalty) return Colors.orange.withOpacity(0.1);
      return Colors.red.withOpacity(0.1);
    }

    return isOverdue ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1);
  }

  Color _getStatusTextColor(Map<String, dynamic> payment, bool isOverdue) {
    double originalDue = double.tryParse(payment['original_due']?.toString() ?? payment['dueamount'].toString()) ?? 0.0;
    double dueReceived = double.tryParse(payment['due_received']?.toString() ?? '0') ?? 0.0;
    double alreadyReceivedDue = double.tryParse(payment['already_received_due']?.toString() ?? '0') ?? 0.0;
    double totalDueReceived = dueReceived + alreadyReceivedDue;

    double penaltyAmount = double.tryParse(payment['penaltyamount'].toString()) ?? 0.0;
    double penaltyReceived = double.tryParse(payment['penalty_received']?.toString() ?? '0') ?? 0.0;
    double alreadyReceivedPenalty = double.tryParse(payment['already_received_penalty']?.toString() ?? '0') ?? 0.0;
    double totalPenaltyReceived = penaltyReceived + alreadyReceivedPenalty;

    if (payment['selected'] == true) {
      if (totalDueReceived == 0) return Colors.grey;
      if (totalDueReceived < originalDue) return Colors.orange;
      return Colors.green;
    } else if (payment['unpaid'] == true) {
      if (totalPenaltyReceived == 0) return Colors.grey;
      if (totalPenaltyReceived < penaltyAmount + alreadyReceivedPenalty) return Colors.orange;
      return Colors.red;
    }

    return isOverdue ? Colors.red : Colors.orange;
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
                        '(Due Amount Only)',
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

              // Due Received header
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Due Received',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '(Editable when Paid)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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

              // Penalty Received header
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Penalty Received',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '(Editable when Unpaid)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
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
            final isUnpaidAllowed = isOverdue; // Unpaid only allowed if overdue
            final alreadyReceivedDue = payment['due_received'] ?? 0.0;
            final alreadyReceivedPenalty = payment['penalty_received'] ?? 0.0;
            bool hasPartialPenalty = (alreadyReceivedPenalty > 0 && alreadyReceivedPenalty < _fixedPenaltyAmount);
            return Container(
              height: 70,
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
                        message: 'Mark as Paid (Collect due amount only, no penalty)',
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

                  // Unpaid Checkbox (Disabled if not overdue)
                  SizedBox(
                    width: 80,
                    child: Center(
                      child: Tooltip(
                        message: isUnpaidAllowed
                            ? 'Mark as Unpaid (Collect penalty only, due amount moves to new EMI at last)'
                            : 'Unpaid option only available for overdue payments',
                        child: AbsorbPointer(
                          absorbing: !isUnpaidAllowed, // Disable interaction if not allowed
                          child: Opacity(
                            opacity: isUnpaidAllowed ? 1.0 : 0.5, // Visual feedback for disabled state
                            child: Checkbox(
                              value: selectedPayment['unpaid'],
                              onChanged: isUnpaidAllowed
                                  ? (value) {
                                _togglePaymentSelection(index, 'unpaid');
                              }
                                  : null, // null disables the checkbox
                              activeColor: Colors.red,
                              fillColor: MaterialStateProperty.resolveWith<Color>(
                                    (Set<MaterialState> states) {
                                  if (!isUnpaidAllowed) {
                                    return Colors.grey; // Grey color when disabled
                                  }
                                  return Colors.red; // Normal red when enabled
                                },
                              ),
                            ),
                          ),
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
                          if (!isUnpaidAllowed)
                            const Text(
                              '(Unpaid not allowed)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatAmount(payment['dueamount']),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isOverdue ? Colors.red : const Color(0xFF374151),
                            ),
                          ),
                          if (alreadyReceivedDue > 0)
                            Text(
                              'Remaining: ${_formatAmount(payment['dueamount'])}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                              ),
                            ),
                          if (alreadyReceivedDue > 0)
                            Text(
                              'Already paid: ${_formatAmount(alreadyReceivedDue)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Due Received
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextField(
                          controller: TextEditingController(
                            text: selectedPayment['selected'] == true
                                ? (double.tryParse(selectedPayment['due_received']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)
                                : '0.00',
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                            TextInputFormatter.withFunction(
                                  (oldValue, newValue) {
                                // Limit to 2 decimal places
                                if (newValue.text.contains('.')) {
                                  if (newValue.text.split('.')[1].length > 2) {
                                    return oldValue;
                                  }
                                }
                                return newValue;
                              },
                            ),
                          ],
                          enabled: selectedPayment['selected'] == true && !hasPartialPenalty, // Disable if partial penalty paid
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: selectedPayment['selected'] == true ? Colors.green : Colors.grey[300]!,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: selectedPayment['selected'] == true ? Colors.green : Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: selectedPayment['selected'] == true ? Colors.green : Colors.grey[300]!,
                              ),
                            ),
                            filled: true,
                            fillColor: selectedPayment['selected'] == true ? Colors.green[50] : Colors.grey[100],
                            hintText: '0.00',
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: selectedPayment['selected'] == true ? Colors.green[800] : Colors.grey[400],
                          ),
                          onChanged: (value) => _onDueReceivedChanged(index, value),
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
                            _formatAmount(penaltyAmount),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isOverdue ? Colors.red : const Color(0xFF374151),
                            ),
                          ),
                          if (penaltyAmount > 0 && alreadyReceivedPenalty > 0)
                            Text(
                              'Remaining: ${_formatAmount(penaltyAmount)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                              ),
                            ),
                          if (alreadyReceivedPenalty > 0)
                            Text(
                              'Already paid: ${_formatAmount(alreadyReceivedPenalty)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                              ),
                            ),
                          if (isOverdue && penaltyAmount > 0)
                            Text(
                              'Fixed: ${_formatAmount(_fixedPenaltyAmount)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Penalty Received
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextField(
                          controller: TextEditingController(
                            text: selectedPayment['unpaid'] == true && isUnpaidAllowed
                                ? (double.tryParse(selectedPayment['penalty_received']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)
                                : '0.00',
                          ),
                          enabled: selectedPayment['unpaid'] == true && isUnpaidAllowed,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                            TextInputFormatter.withFunction(
                                  (oldValue, newValue) {
                                if (newValue.text.contains('.')) {
                                  if (newValue.text.split('.')[1].length > 2) {
                                    return oldValue;
                                  }
                                }
                                return newValue;
                              },
                            ),
                          ],
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: selectedPayment['unpaid'] == true && isUnpaidAllowed ? Colors.red : Colors.grey[300]!,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: selectedPayment['unpaid'] == true && isUnpaidAllowed ? Colors.red : Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: selectedPayment['unpaid'] == true && isUnpaidAllowed ? Colors.red : Colors.grey[300]!,
                              ),
                            ),
                            filled: true,
                            fillColor: selectedPayment['unpaid'] == true && isUnpaidAllowed ? Colors.red[50] : Colors.grey[100],
                            hintText: '0.00',
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: selectedPayment['unpaid'] == true && isUnpaidAllowed ? Colors.red[800] : Colors.grey[400],
                          ),
                          onChanged: (value) => _onPenaltyReceivedChanged(index, value),
                        ),
                      ),
                    ),
                  ),

                  // Status
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(selectedPayment, isOverdue),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getPaymentStatus(selectedPayment, isOverdue),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _getStatusTextColor(selectedPayment, isOverdue),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (selectedPayment['selected'] == true && (double.tryParse(selectedPayment['due_received']?.toString() ?? '0') ?? 0.0) > 0)
                              const Text(
                                '(Editable)',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.green,
                                ),
                              ),
                            if (selectedPayment['unpaid'] == true && (double.tryParse(selectedPayment['penalty_received']?.toString() ?? '0') ?? 0.0) > 0)
                              const Text(
                                '(Editable)',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.red,
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

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.rule, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Payment Rules:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.check,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Paid: Collects due amount only, NO penalty even if overdue',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '✗',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Unpaid: Collects penalty only if overdue, due amount moves to new EMI',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Totals - Rule 6: Use received amounts
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Due Received:', // Rule 6
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '₹${_totalDueReceived.toStringAsFixed(2)}', // Rule 6
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
                        'Total Penalty Received:', // Rule 6
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '₹${_totalPenaltyReceived.toStringAsFixed(2)}', // Rule 6
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
                        '₹${(_totalDueReceived + _totalPenaltyReceived).toStringAsFixed(2)}', // Rule 6
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
                      '• Paid (✓): Collects due amount only, NO penalty even if overdue (Rule 7)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      '• Unpaid (✗): Collects penalty only if overdue, due amount moves to new EMI at last (Rule 1)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      '• Each EMI can have only ONE payment type (Paid OR Unpaid) (Rule 2)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '• Fully paid EMI are excluded from schedule (Rule 3)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      '• Checkboxes are not pre-selected (Rule 4)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      '• Loan balance includes partially paid amounts (Rule 5)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      '• Totals calculated from received amounts (Rule 6)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      '• Partially paid amounts will remain in schedule until fully paid',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
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
                (_totalDueReceived == 0 && _totalPenaltyReceived == 0) // Rule 6: Check received amounts
                ? null
                : _recordCollection,
            style: ElevatedButton.styleFrom(
              backgroundColor:
              _loanId != null &&
                  (_totalDueReceived > 0 || _totalPenaltyReceived > 0) // Rule 6: Check received amounts
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
                                backgroundColor: const Color(0xFFF9FAFB),
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
                              backgroundColor: const Color(0xFFF9FAFB),
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

                      // Received Amounts Row
                      if (isWeb)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildInputField(
                                label: 'Due Received :',
                                controller: _dueReceivedController,
                                isReadOnly: true,
                                backgroundColor: const Color(0xFFF9FAFB),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildInputField(
                                label: 'Penalty Received :',
                                controller: _penaltyReceivedController,
                                isReadOnly: true,
                                backgroundColor: const Color(0xFFF9FAFB),
                              ),
                            ),
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
                          children: [
                            _buildInputField(
                              label: 'Due Received :',
                              controller: _dueReceivedController,
                              isReadOnly: true,
                              backgroundColor: const Color(0xFFF9FAFB),
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              label: 'Penalty Received :',
                              controller: _penaltyReceivedController,
                              isReadOnly: true,
                              backgroundColor: const Color(0xFFF9FAFB),
                            ),
                            const SizedBox(height: 20),
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


import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../masters/customermaster.dart';
import '../services/loan_apiservice.dart';
import '../services/customer_apiservice.dart';

class LoanIssueScreen extends StatefulWidget {
  const LoanIssueScreen({super.key});

  @override
  State<LoanIssueScreen> createState() => _LoanIssueScreenState();
}

class _LoanIssueScreenState extends State<LoanIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  String? _selectedLoanTypeId;
  String? _selectedLoanTypeName;
  String? _selectedLoanDay;
  String? _selectedNoOfWeeks;
  String? _selectedPaymentMode;
  DateTime? _startDate;

  // Controllers
  final TextEditingController _loanNoController = TextEditingController();
  final TextEditingController _loanAmountController = TextEditingController();
  final TextEditingController _givenAmountController = TextEditingController();
  final TextEditingController _interestAmountController = TextEditingController();
  final TextEditingController _penaltyAmountController = TextEditingController();

  // Data
  List<CustomerMasterModel> _customers = [];
  List<LoanTypeModel> _loanTypes = [];
  List<Map<String, dynamic>> _paymentSchedule = [];

  final List<String> _loanDays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  final List<String> _paymentModes = [
    'Cash',
    'Bank Transfer',
    'Cheque',
    'UPI',
    'Credit Card',
  ];

  final LoanApiService _loanApiService = LoanApiService();
  final CustomerApiService _customerApiService = CustomerApiService();
  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _errorMessage;

  String? _selectedPaymentAccountId;
  String? _selectedPaymentAccountName;
  double _selectedAccountBalance = 0.0;
  List<PaymentAccountModel> _paymentAccounts = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _startDate = DateTime.now();
    _selectedPaymentMode = 'Cash';
    _initializeData();
  }

  Future<void> _initializeData() async {
    print("=== INITIALIZING LOAN ISSUE DATA ===");
    try {
      await Future.wait([
        _loadCustomers(),
        _loadLoanTypes(),
        _loadPaymentAccounts(), // Add this
        _generateLoanNo(),
      ]);
      print("✅ Data initialization complete");
    } catch (e) {
      print("❌ Error initializing data: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading data: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _loadPaymentAccounts() async {
    try {
      print("Loading payment accounts...");
      final accounts = await _loanApiService.fetchPaymentAccounts(context);
      print("Received ${accounts.length} payment accounts");

      if (mounted) {
        setState(() {
          _paymentAccounts = accounts;
        });
      }
    } catch (e) {
      print("❌ Error loading payment accounts: $e");
      if (mounted) {
        setState(() {
          _paymentAccounts = [];
        });
      }
    }
  }

  Future<void> _loadCustomers() async {
    try {
      print("Loading customers...");
      final customers = await _customerApiService.fetchCustomers(context);
      print("Received ${customers.length} customers");

      if (mounted) {
        setState(() {
          _customers = customers;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print("❌ Error loading customers: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading customers";
          _customers = [];
        });
      }
    }
  }

  Future<void> _loadLoanTypes() async {
    try {
      print("Loading loan types...");
      final loanTypes = await _loanApiService.fetchLoanTypes(context);
      print("Received ${loanTypes.length} loan types from API");

      // Log all loan types
      for (var type in loanTypes) {
        print("Loan Type: ${type.loantype}, ID: ${type.id}, Day: ${type.collectionday}, Weeks: ${type.noofweeks}");
      }

      // If no loan types, add test data
      // If no loan types, add test data
      if (loanTypes.isEmpty) {
        print("⚠️ No loan types found, adding test data");
        loanTypes.addAll([
          LoanTypeModel(
            id: '1',
            loantype: 'Personal Loan',
            collectionday: 'Monday',
            noofweeks: '12', // Just the number
            penaltyamount: '100',
          ),
          LoanTypeModel(
            id: '2',
            loantype: 'Business Loan',
            collectionday: 'Friday',
            noofweeks: '24', // Just the number
            penaltyamount: '200',
          ),
          LoanTypeModel(
            id: '3',
            loantype: 'Gold Loan',
            collectionday: 'Wednesday',
            noofweeks: '8', // Just the number
            penaltyamount: '50',
          ),
        ]);
        print("✅ Added ${loanTypes.length} test loan types");
      }

      if (mounted) {
        setState(() {
          _loanTypes = loanTypes;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print("❌ Error loading loan types: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading loan types";
          _loanTypes = [];
        });
      }
    }
  }

  Future<void> _generateLoanNo() async {
    try {
      final loanNo = await _loanApiService.generateLoanNo(context);
      if (mounted && loanNo.isNotEmpty) {
        setState(() {
          _loanNoController.text = loanNo;
        });
        print("✅ Generated Loan No: $loanNo");
      }
    } catch (e) {
      print("❌ Error generating loan no: $e");
      if (mounted) {
        setState(() {
          _loanNoController.text =
          'LON${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
        });
      }
    }
  }

  Future<void> _selectDate(
      BuildContext context, {
        bool isStartDate = false,
      }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_selectedDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF1E293B),
            colorScheme: const ColorScheme.light(primary: Color(0xFF1E293B)),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      print("📅 Date selected: ${DateFormat('dd/MM/yyyy').format(picked)}");
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _generatePaymentSchedule();
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  void _onLoanTypeChanged(String? value) {
    print("🔽 Loan Type changed to: $value");

    if (value != null && value.isNotEmpty) {
      try {
        final selectedType = _loanTypes.firstWhere(
              (type) => type.id == value,
        );

        print("✅ Selected Loan Type: ${selectedType.loantype}");
        print("✅ Collection Day: ${selectedType.collectionday}");
        print("✅ No. of Weeks: ${selectedType.noofweeks}");

        // Extract just the number if it's in "12 Weeks" format
        String weeksValue = selectedType.noofweeks;
        if (weeksValue.contains('Weeks') || weeksValue.contains('weeks')) {
          final regex = RegExp(r'(\d+)');
          final match = regex.firstMatch(weeksValue);
          if (match != null) {
            weeksValue = match.group(1)!;
            print("✅ Extracted weeks number: $weeksValue");
          }
        }

        setState(() {
          _selectedLoanTypeId = value;
          _selectedLoanTypeName = selectedType.loantype;
          _selectedLoanDay = selectedType.collectionday;
          _selectedNoOfWeeks = weeksValue; // Use extracted number
        });

        // Generate schedule after state update
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _generatePaymentSchedule();
        });

      } catch (e) {
        print("❌ Error selecting loan type: $e");
        setState(() {
          _selectedLoanTypeId = null;
          _selectedLoanTypeName = null;
          _selectedLoanDay = null;
          _selectedNoOfWeeks = null;
          _paymentSchedule.clear();
        });
      }
    } else {
      setState(() {
        _selectedLoanTypeId = null;
        _selectedLoanTypeName = null;
        _selectedLoanDay = null;
        _selectedNoOfWeeks = null;
        _paymentSchedule.clear();
      });
    }
  }

  void _onLoanAmountChanged(String value) {
    if (value.isNotEmpty) {
      // Calculate given amount (loan amount - interest)
      final loanAmount = double.tryParse(value) ?? 0;
      final interestAmount =
          double.tryParse(_interestAmountController.text) ?? 0;
      final givenAmount = loanAmount - interestAmount;

      if (mounted) {
        setState(() {
          _givenAmountController.text = givenAmount.toStringAsFixed(2);
        });
      }
      _generatePaymentSchedule();
    }
  }

  void _onInterestAmountChanged(String value) {
    if (value.isNotEmpty && _loanAmountController.text.isNotEmpty) {
      // Recalculate given amount
      final loanAmount = double.tryParse(_loanAmountController.text) ?? 0;
      final interestAmount = double.tryParse(value) ?? 0;
      final givenAmount = loanAmount - interestAmount;

      if (mounted) {
        setState(() {
          _givenAmountController.text = givenAmount > 0
              ? givenAmount.toStringAsFixed(2)
              : '0.00';
        });
      }
    }
  }

  void _generatePaymentSchedule() {
    print("\n=== GENERATING PAYMENT SCHEDULE ===");

    // Check all required fields
    final hasLoanDay = _selectedLoanDay != null && _selectedLoanDay!.isNotEmpty;
    final hasNoOfWeeks = _selectedNoOfWeeks != null &&
        _selectedNoOfWeeks!.isNotEmpty &&
        int.tryParse(_selectedNoOfWeeks!) != null;
    final hasLoanAmount = _loanAmountController.text.isNotEmpty &&
        double.tryParse(_loanAmountController.text) != null;
    final hasStartDate = _startDate != null;

    print("📋 Field Check:");
    print("  • Loan Day: $hasLoanDay ($_selectedLoanDay)");
    print("  • No. of Weeks: $hasNoOfWeeks ($_selectedNoOfWeeks)");
    print("  • Loan Amount: $hasLoanAmount (${_loanAmountController.text})");
    print("  • Start Date: $hasStartDate ($_startDate)");

    if (!hasLoanDay || !hasNoOfWeeks || !hasLoanAmount || !hasStartDate) {
      print("❌ Missing required fields for schedule generation");
      if (mounted) {
        setState(() {
          _paymentSchedule.clear();
        });
      }
      return;
    }

    try {
      final loanAmount = double.parse(_loanAmountController.text);
      final weeks = int.parse(_selectedNoOfWeeks!);

      print("💰 Loan Details:");
      print("  • Loan Amount: ₹$loanAmount");
      print("  • Weeks: $weeks");

      if (loanAmount <= 0 || weeks <= 0) {
        print("❌ Invalid loan amount or weeks");
        if (mounted) {
          setState(() {
            _paymentSchedule.clear();
          });
        }
        return;
      }

      final weeklyAmount = loanAmount / weeks;
      print("  • Weekly Amount: ₹${weeklyAmount.toStringAsFixed(2)}");

      final schedule = <Map<String, dynamic>>[];

      // Create a copy of start date
      DateTime currentDate = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
      );

      print("\n📅 Date Calculations:");
      print("  • Start Date: ${DateFormat('dd/MM/yyyy').format(currentDate)} (${DateFormat('EEEE').format(currentDate)})");
      print("  • Target Loan Day: $_selectedLoanDay");

      // Find the index of selected loan day
      int dayIndex = _loanDays.indexOf(_selectedLoanDay!);
      if (dayIndex == -1) {
        dayIndex = 0; // Default to Sunday if not found
        print("  ⚠️ Loan day not found in list, defaulting to Sunday");
      }

      // Convert to Dart weekday (1=Monday, 7=Sunday)
      int targetWeekday = dayIndex ;
      if (targetWeekday > 7) targetWeekday = 7;

      print("  • Target Weekday: $targetWeekday");
      print("  • Current Weekday: ${currentDate.weekday}");

      // Find first due date (next occurrence of target weekday)
      int daysToAdd = (targetWeekday - currentDate.weekday + 7) % 7;
      // if (daysToAdd == 0) daysToAdd = 7; // If same day, go to next week

      DateTime firstDueDate = currentDate.add(Duration(days: daysToAdd));
      print("  • First Due Date: ${DateFormat('dd/MM/yyyy').format(firstDueDate)} (${DateFormat('EEEE').format(firstDueDate)})");

      // Generate schedule
      print("\n📋 Payment Schedule:");
      for (int i = 1; i <= weeks; i++) {
        DateTime dueDate;
        if (i == 1) {
          dueDate = firstDueDate;
        } else {
          dueDate = firstDueDate.add(Duration(days: (i - 1) * 7));
        }

        final dayName = DateFormat('EEEE').format(dueDate);
        final formattedDate = DateFormat('yyyy-MM-dd').format(dueDate); // Format for database

        schedule.add({
          'dueNo': i,
          'dueDate': dueDate,
          'dueDateFormatted': formattedDate,
          'dueAmount': weeklyAmount,
          'status': 'Pending',
          'dayName': dayName,
        });

        print("  • Week $i: $formattedDate ($dayName) - ₹${weeklyAmount.toStringAsFixed(2)}");
      }

      print("✅ Schedule generated with ${schedule.length} entries");

      if (mounted) {
        setState(() {
          _paymentSchedule = schedule;
        });
      }

    } catch (e) {
      print("❌ Error generating schedule: $e");
      if (mounted) {
        setState(() {
          _paymentSchedule.clear();
        });
      }
    }
  }

  Widget _buildPaymentAccountDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Account :',
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
            child: _paymentAccounts.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'No payment accounts available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            )
                : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPaymentAccountId,
                isExpanded: true,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.black,
                  size: 24,
                ),
                hint: const Text(
                  'Select payment account',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF252525),
                  ),
                ),
                items: _paymentAccounts.map((account) {
                  return DropdownMenuItem<String>(
                    value: account.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          account.ledgername,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF252525),
                          ),
                        ),
                        Text(
                          'Balance: ₹${account.currentBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: account.currentBalance >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final account = _paymentAccounts.firstWhere(
                          (a) => a.id == value,
                    );
                    setState(() {
                      _selectedPaymentAccountId = value;
                      _selectedPaymentAccountName = account.ledgername;
                      _selectedAccountBalance = account.currentBalance;
                    });
                  }
                },
              ),
            ),
          ),
        ),
        if (_selectedPaymentAccountId != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Available Balance: ₹${_selectedAccountBalance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: _selectedAccountBalance >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onDateSelected,
    String hintText = 'Select date',
    Color? backgroundColor,
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
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
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
            if (picked != null && picked != selectedDate) {
              onDateSelected(picked);
            }
          },
          child: Container(
            height: 47,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(selectedDate)
                          : hintText,
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedDate != null
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

  Future<void> _issueLoan() async {
    if (_formKey.currentState!.validate()) {
      // Validate required fields
      if (_selectedCustomerId == null || _selectedCustomerId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a customer'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedLoanTypeId == null || _selectedLoanTypeId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a loan type'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_loanAmountController.text.isEmpty ||
          double.tryParse(_loanAmountController.text) == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid loan amount'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedLoanDay == null || _selectedLoanDay!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loan day is required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedNoOfWeeks == null ||
          _selectedNoOfWeeks!.isEmpty ||
          int.tryParse(_selectedNoOfWeeks!) == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Number of weeks is required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a start date'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a loan date'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Add payment account validation
      if (_selectedPaymentAccountId == null || _selectedPaymentAccountId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a payment account'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // Check if sufficient balance exists
      final loanAmount = double.tryParse(_loanAmountController.text) ?? 0;
      if (loanAmount > _selectedAccountBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Insufficient balance! Available: ₹${_selectedAccountBalance.toStringAsFixed(2)}, Required: ₹${loanAmount.toStringAsFixed(2)}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }


      setState(() {
        _isLoading = true;
      });

      // try {
      //   final result = await _loanApiService.insertLoan(
      //     context: context,
      //     customerId: _selectedCustomerId!,
      //     loanTypeId: _selectedLoanTypeId!,
      //     loanAmount: _loanAmountController.text,
      //     givenAmount: _givenAmountController.text.isEmpty
      //         ? _loanAmountController.text
      //         : _givenAmountController.text,
      //     interestAmount: _interestAmountController.text.isEmpty
      //         ? '0'
      //         : _interestAmountController.text,
      //     loanDay: _selectedLoanDay!,
      //     noOfWeeks: _selectedNoOfWeeks!,
      //     paymentMode: _selectedPaymentMode ?? 'Cash',
      //     startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
      //   );

        // if (result == "Success") {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     const SnackBar(
        //       content: Text('✅ Loan issued successfully!'),
        //       backgroundColor: Colors.green,
        //       duration: Duration(seconds: 3),
        //     ),
        //   );
        //   _resetForm();
        //   await _generateLoanNo();
        // }
      // }
      try {
        // Prepare schedule data for sending
        List<Map<String, dynamic>> scheduleDataForAPI = [];
        for (var schedule in _paymentSchedule) {
          scheduleDataForAPI.add({
            'dueNo': schedule['dueNo'],
            'dueDate': DateFormat('yyyy-MM-dd').format(schedule['dueDate']),
            'dueAmount': schedule['dueAmount'].toString(),
            'status': schedule['status'],
          });
        }

        print("📤 Sending schedule data to API: ${scheduleDataForAPI.length} items");

        final result = await _loanApiService.insertLoan(
          context: context,
          customerId: _selectedCustomerId!,
          loanTypeId: _selectedLoanTypeId!,
          loanAmount: _loanAmountController.text,
          givenAmount: _givenAmountController.text.isEmpty
              ? _loanAmountController.text
              : _givenAmountController.text,
          interestAmount: _interestAmountController.text.isEmpty
              ? '0'
              : _interestAmountController.text,
          loanDay: _selectedLoanDay!,
          noOfWeeks: _selectedNoOfWeeks!,
          penaltyamount: _penaltyAmountController.text.isEmpty
              ? '0'
              : _penaltyAmountController.text,
          paymentMode: _selectedPaymentMode ?? 'Cash',
          startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
          scheduleData: scheduleDataForAPI,
          paymentAccountId: _selectedPaymentAccountId!, // Add this
        );

        if (result == "Success") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Loan issued successfully with payment schedule!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          _resetForm();
          await _generateLoanNo();
        }
      }
    catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error issuing loan: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedCustomerId = null;
      _selectedCustomerName = null;
      _selectedLoanTypeId = null;
      _selectedLoanTypeName = null;
      _selectedLoanDay = null;
      _selectedNoOfWeeks = null;
      _selectedPaymentMode = 'Cash';
      _loanAmountController.clear();
      _givenAmountController.clear();
      _interestAmountController.clear();
      _penaltyAmountController.clear();
      _paymentSchedule.clear();
      _selectedDate = DateTime.now();
      _startDate = DateTime.now();
    });
    print("🔄 Form reset");
  }

  void _navigateToCustomerMaster() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to Customer Master'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isRequired = true,
    bool isReadOnly = false,
    VoidCallback? onTap,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    Color? backgroundColor,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
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
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 47,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: TextFormField(
              controller: controller,
              readOnly: isReadOnly,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF999999),
                ),
                suffixIcon: onTap != null
                    ? const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Colors.grey,
                )
                    : null,
              ),
              style: const TextStyle(fontSize: 16, color: Color(0xFF252525)),
              validator:
              validator ??
                      (value) {
                    if (isRequired && (value == null || value.isEmpty)) {
                      return 'This field is required';
                    }
                    if (keyboardType == TextInputType.number &&
                        value != null &&
                        value.isNotEmpty) {
                      final num = double.tryParse(value);
                      if (num == null || num <= 0) {
                        return 'Enter a valid amount';
                      }
                    }
                    return null;
                  },
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
    String hintText = 'Select option',
    Color? backgroundColor,
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
            color: backgroundColor ?? const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.black,
                  size: 24,
                ),
                hint: Text(
                  hintText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF252525),
                  ),
                ),
                items: options.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF252525),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer :',
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
            child: _customers.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'No customers available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            )
                : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCustomerId,
                isExpanded: true,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.black,
                  size: 24,
                ),
                hint: const Text(
                  'Select customer',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF252525),
                  ),
                ),
                items: _customers.map((customer) {
                  return DropdownMenuItem<String>(
                    value: customer.id,
                    child: Text(
                      '${customer.customername} (${customer.mobile1})',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF252525),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final customer = _customers.firstWhere(
                          (c) => c.id == value,
                    );
                    setState(() {
                      _selectedCustomerId = value;
                      _selectedCustomerName = customer.customername;
                    });
                  }
                },
              ),
            ),
          ),
        ),
        if (_customers.isEmpty && !_isInitialLoading)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Add customers in Customer Master first',
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

  Widget _buildLoanTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Loan Type :',
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
            child: _loanTypes.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'No loan types available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            )
                : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLoanTypeId,
                isExpanded: true,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.black,
                  size: 24,
                ),
                hint: const Text(
                  'Select loan type',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF252525),
                  ),
                ),
                items: _loanTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type.id,
                    child: Text(
                      type.loantype,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF252525),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _onLoanTypeChanged,
              ),
            ),
          ),
        ),
        if (_loanTypes.isEmpty && !_isInitialLoading)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Add loan types in Loan Type Master first',
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

  Widget _buildPaymentScheduleTable() {
    print("🔄 Building payment schedule table with ${_paymentSchedule.length} entries");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Payment Schedule Report',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            if (_paymentSchedule.isNotEmpty)
              Text(
                '${_paymentSchedule.length} weeks × ₹${_paymentSchedule.isNotEmpty ? (_paymentSchedule[0]['dueAmount'] as double).toStringAsFixed(2) : '0.00'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (_paymentSchedule.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                const Text(
                  'No payment schedule generated',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fill all required fields to generate payment schedule',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Chip(
                      label: Text('Select Loan Type'),
                      backgroundColor: Color(0xFFEFF6FF),
                    ),
                    Chip(
                      label: Text('Enter Loan Amount'),
                      backgroundColor: Color(0xFFF0F9FF),
                    ),
                    Chip(
                      label: Text('Select Start Date'),
                      backgroundColor: Color(0xFFF0FDF4),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          child: const Text(
                            'Week',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          child: const Text(
                            'Due Date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          child: const Text(
                            'Day',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          child: const Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table Rows
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _paymentSchedule.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  itemBuilder: (context, index) {
                    final schedule = _paymentSchedule[index];
                    final dueDate = schedule['dueDate'] as DateTime;
                    final dayName = schedule['dayName'] as String;
                    final amount = schedule['dueAmount'] as double;
                    final weekNo = schedule['dueNo'] as int;

                    return Container(
                      height: 60,
                      color: index.isOdd ? Colors.white : const Color(0xFFF9FAFB),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Week',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    weekNo.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(dueDate),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM yyyy').format(dueDate),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.center,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _selectedLoanDay == dayName
                                      ? const Color(0xFF1E293B).withOpacity(0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _selectedLoanDay == dayName
                                        ? const Color(0xFF1E293B)
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  dayName.substring(0, 3),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedLoanDay == dayName
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '₹${amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: schedule['status'] == 'Paid'
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      schedule['status'] ?? 'Pending',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: schedule['status'] == 'Paid'
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Footer with totals
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total ${_paymentSchedule.length} Payments',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        Text(
                          '₹${(_paymentSchedule.isNotEmpty ? (_paymentSchedule[0]['dueAmount'] as double) * _paymentSchedule.length : 0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopFirstRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildInputField(
              label: 'Loan No :',
              controller: _loanNoController,
              hintText: 'Auto-generated',
              isReadOnly: true,
              backgroundColor: const Color(0xFFF9FAFB),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildDateField(
              label: 'Date :',
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
              hintText: 'Select loan date',
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _buildCustomerDropdown(),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSecondRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildLoanTypeDropdown(),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildInputField(
              label: 'Loan Day :',
              controller: TextEditingController(text: _selectedLoanDay ?? ''),
              hintText: 'Auto-filled from loan type',
              isReadOnly: true,
              backgroundColor: const Color(0xFFF9FAFB),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _buildInputField(
              label: 'No. of Weeks :',
              controller: TextEditingController(text: _selectedNoOfWeeks ?? ''),
              hintText: 'Auto-filled from loan type',
              isReadOnly: true,
              backgroundColor: const Color(0xFFF9FAFB),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopThirdRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildInputField(
              label: 'Loan Amount :',
              controller: _loanAmountController,
              hintText: 'Enter amount',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: _onLoanAmountChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Loan amount is required';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Enter a valid loan amount';
                }
                return null;
              },
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildDateField(
              label: 'Start Date :',
              selectedDate: _startDate,
              onDateSelected: (date) {
                setState(() {
                  _startDate = date;
                  _generatePaymentSchedule();
                });
              },
              hintText: 'Select start date',
              backgroundColor: const Color(0xFFFDFEFF),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _buildInputField(
              label: 'Given Amount :',
              controller: _givenAmountController,
              hintText: 'Auto-calculated',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              isReadOnly: true,
              backgroundColor: const Color(0xFFF9FAFB),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopFourthRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildInputField(
              label: 'Penalty Amount :',
              controller: _penaltyAmountController,
              hintText: 'Enter penalty',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              backgroundColor: const Color(0xFFD9D9D9).withOpacity(0.5),
              onChanged: _onInterestAmountChanged,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildInputField(
              label: 'Interest Amount :',
              controller: _interestAmountController,
              hintText: 'Enter interest',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              backgroundColor: const Color(0xFFD9D9D9).withOpacity(0.5),
              onChanged: _onInterestAmountChanged,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _buildDropdownField(
              label: 'Cash/Bank :',
              options: _paymentModes,
              selectedValue: _selectedPaymentMode,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMode = value;
                });
              },
              hintText: 'Select mode',
              backgroundColor: const Color(0xFFD9D9D9).withOpacity(0.5),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _buildPaymentAccountDropdown(),
          ),
        ),
        const Expanded(child: SizedBox()), // Spacer
      ],
    );
  }

  Widget _buildMobileFirstRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: 'Loan No :',
          controller: _loanNoController,
          hintText: 'Auto-generated',
          isReadOnly: true,
          backgroundColor: const Color(0xFFF9FAFB),
        ),
        const SizedBox(height: 16),
        _buildDateField(
          label: 'Date :',
          selectedDate: _selectedDate,
          onDateSelected: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
          hintText: 'Select loan date',
        ),
        const SizedBox(height: 16),
        _buildCustomerDropdown(),
      ],
    );
  }

  Widget _buildMobileSecondRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLoanTypeDropdown(),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Loan Day :',
          controller: TextEditingController(text: _selectedLoanDay ?? ''),
          hintText: 'Auto-filled from loan type',
          isReadOnly: true,
          backgroundColor: const Color(0xFFF9FAFB),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'No. of Weeks :',
          controller: TextEditingController(text: _selectedNoOfWeeks ?? ''),
          hintText: 'Auto-filled from loan type',
          isReadOnly: true,
          backgroundColor: const Color(0xFFF9FAFB),
        ),
      ],
    );
  }

  Widget _buildMobileThirdRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: 'Loan Amount :',
          controller: _loanAmountController,
          hintText: 'Enter amount',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: _onLoanAmountChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Loan amount is required';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Enter a valid loan amount';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildDateField(
          label: 'Start Date :',
          selectedDate: _startDate,
          onDateSelected: (date) {
            setState(() {
              _startDate = date;
              _generatePaymentSchedule();
            });
          },
          hintText: 'Select start date',
          backgroundColor: const Color(0xFFFDFEFF),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Given Amount :',
          controller: _givenAmountController,
          hintText: 'Auto-calculated',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          isReadOnly: true,
          backgroundColor: const Color(0xFFF9FAFB),
        ),
      ],
    );
  }

  Widget _buildMobileFourthRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: 'Interest Amount :',
          controller: _interestAmountController,
          hintText: 'Enter interest',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          backgroundColor: const Color(0xFFD9D9D9).withOpacity(0.5),
          onChanged: _onInterestAmountChanged,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Cash/Bank :',
          options: _paymentModes,
          selectedValue: _selectedPaymentMode,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMode = value;
            });
          },
          hintText: 'Select mode',
          backgroundColor: const Color(0xFFD9D9D9).withOpacity(0.5),
        ),
        const SizedBox(height: 16),
        _buildPaymentAccountDropdown(),
      ],
    );
  }

  Widget _buildActionButtons(bool isWeb) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isWeb)
          SizedBox(
            width: 146,
            height: 50,
            child: ElevatedButton(
              onPressed: _navigateToCustomerMaster,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Add Customer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        const SizedBox(width: 16),

        SizedBox(
          width: isWeb ? 146 : 140,
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
          width: isWeb ? 146 : 140,
          height: 50,
          child: ElevatedButton(
            onPressed: (_customers.isEmpty || _loanTypes.isEmpty)
                ? null
                : _isLoading
                ? null
                : _issueLoan,
            style: ElevatedButton.styleFrom(
              backgroundColor: (_customers.isEmpty || _loanTypes.isEmpty)
                  ? Colors.grey
                  : const Color(0xFF1E293B),
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
              'Issue Loan',
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

    // Debug build info
    print("\n=== BUILDING LOAN ISSUE SCREEN ===");
    print("• Loan Types: ${_loanTypes.length} items");
    print("• Selected Loan Type: $_selectedLoanTypeId");
    print("• Selected Loan Day: $_selectedLoanDay");
    print("• Selected No. of Weeks: $_selectedNoOfWeeks");
    print("• Loan Amount: ${_loanAmountController.text}");
    print("• Start Date: $_startDate");
    print("• Payment Schedule: ${_paymentSchedule.length} entries");

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                        Text(
                          'Loan Issue :',
                          style: TextStyle(
                            fontSize: isWeb ? 24 : 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter loan details and generate payment schedule',
                          style: TextStyle(
                            fontSize: isWeb ? 20 : 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Debug button (optional - remove after testing)
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.orange),
                            ),
                          ),
                          TextButton(
                            onPressed: _initializeData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // First Row - Loan No, Date, Customer
                        if (isWeb)
                          _buildDesktopFirstRow()
                        else
                          _buildMobileFirstRow(),

                        const SizedBox(height: 20),

                        // Second Row - Loan Type, Loan Day, No. of Weeks
                        if (isWeb)
                          _buildDesktopSecondRow()
                        else
                          _buildMobileSecondRow(),

                        const SizedBox(height: 20),

                        // Third Row - Loan Amount, Start Date, Given Amount
                        if (isWeb)
                          _buildDesktopThirdRow()
                        else
                          _buildMobileThirdRow(),

                        const SizedBox(height: 20),

                        // Fourth Row - Interest Amount, Cash/Bank
                        if (isWeb)
                          _buildDesktopFourthRow()
                        else
                          _buildMobileFourthRow(),

                        const SizedBox(height: 40),

                        // Payment Schedule Table
                        _buildPaymentScheduleTable(),

                        const SizedBox(height: 40),

                        // Action Buttons
                        _buildActionButtons(isWeb),
                      ],
                    ),
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

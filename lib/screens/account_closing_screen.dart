import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/account_closing_api_service.dart';

class AccountClosingScreen extends StatefulWidget {
  const AccountClosingScreen({super.key});

  @override
  State<AccountClosingScreen> createState() => _AccountClosingScreenState();
}

class _AccountClosingScreenState extends State<AccountClosingScreen> {
  final _formKey = GlobalKey<FormState>();
  final AccountClosingApiService _apiService = AccountClosingApiService();
  final TextEditingController _serialNoController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _loanNoController = TextEditingController();
  final TextEditingController _loanAmountController = TextEditingController();
  final TextEditingController _loanPaidController = TextEditingController();
  final TextEditingController _balanceAmountController = TextEditingController();
  final TextEditingController _penaltyAmountController = TextEditingController();
  final TextEditingController _penaltyCollectedController = TextEditingController();
  final TextEditingController _penaltyBalanceController = TextEditingController();
  final TextEditingController _discountPrincipleController = TextEditingController();
  final TextEditingController _discountPenaltyController = TextEditingController();

  bool _isLoading = false;
  bool _customersLoaded = false;
  bool _loansLoaded = false;

  // Customer dropdown
  List<Map<String, dynamic>> _customers = [];
  Map<String, dynamic>? _selectedCustomer;

  // Loan dropdown
  List<Map<String, dynamic>> _loans = [];
  Map<String, dynamic>? _selectedLoan;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadNextSerialNo();
  }

  // void _initializeData() async {
  //   try {
  //     await _loadCustomers();
  //   } catch (e) {
  //     print("Initialize data error: $e");
  //   }
  // }

  void _initializeData() async {
    try {
      final customers = await _apiService.getCustomers(context);
      if (mounted) {
        setState(() {
          _customers = customers;
          _customersLoaded = true;
        });
      }
    } catch (e) {
      print("Load customers error: $e");
      if (mounted) {
        setState(() {
          _customersLoaded = true;
        });
      }
    }
  }

  void _loadLoansByCustomer(String customerId) async {
    try {
      final loans = await _apiService.getLoansByCustomer(context, customerId);
      if (mounted) {
        setState(() {
          _loans = loans;
          _loansLoaded = true;
          _selectedLoan = null;
          _resetLoanDetails();
        });
      }
    } catch (e) {
      print("Load loans error: $e");
      if (mounted) {
        setState(() {
          _loansLoaded = true;
          _loans = [];
        });
      }
    }
  }

  void _loadLoanDetails(String loanId) async {
    try {
      final details = await _apiService.getLoanDetailsForClosing(context, loanId);
      if (mounted && details.isNotEmpty) {
        setState(() {
          _loanAmountController.text = details['loan_amount'] ?? '0.00';
          _loanPaidController.text = details['loan_paid'] ?? '0.00';
          _balanceAmountController.text = details['balance_amount'] ?? '0.00';
          _penaltyAmountController.text = details['penalty_amount'] ?? '0.00';
          _penaltyCollectedController.text = details['penalty_collected'] ?? '0.00';
          _penaltyBalanceController.text = details['penalty_balance'] ?? '0.00';

          // Reset discount fields
          _discountPrincipleController.text = '0.00';
          _discountPenaltyController.text = '0.00';
        });
      }
    } catch (e) {
      print("Load loan details error: $e");
    }
  }

  void _loadNextSerialNo() async {
    final serialNo = await _apiService.getNextSerialNo(context);
    if (mounted) {
      setState(() {
        _serialNoController.text = serialNo;
      });
    }
  }

  void _resetLoanDetails() {
    _loanAmountController.text = '0.00';
    _loanPaidController.text = '0.00';
    _balanceAmountController.text = '0.00';
    _penaltyAmountController.text = '0.00';
    _penaltyCollectedController.text = '0.00';
    _penaltyBalanceController.text = '0.00';
    _discountPrincipleController.text = '0.00';
    _discountPenaltyController.text = '0.00';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedLoan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a loan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate discount amounts
    double balanceAmount = double.tryParse(_balanceAmountController.text) ?? 0;
    double discountPrinciple = double.tryParse(_discountPrincipleController.text) ?? 0;
    double penaltyBalance = double.tryParse(_penaltyBalanceController.text) ?? 0;
    double discountPenalty = double.tryParse(_discountPenaltyController.text) ?? 0;

    if (discountPrinciple > balanceAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Discount principle cannot exceed balance amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (discountPenalty > penaltyBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Discount penalty cannot exceed penalty balance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.insertAccountClosing(
        context: context,
        serialNo: _serialNoController.text,
        date: _dateController.text,
        customerId: _selectedCustomer!['id']?.toString() ?? '',
        customerName: _selectedCustomer!['name']?.toString() ?? '',
        loanId: _selectedLoan!['id']?.toString() ?? '',
        loanNo: _selectedLoan!['loan_no']?.toString() ?? '',
        loanAmount: _loanAmountController.text,
        loanPaid: _loanPaidController.text,
        balanceAmount: _balanceAmountController.text,
        penaltyAmount: _penaltyAmountController.text,
        penaltyCollected: _penaltyCollectedController.text,
        penaltyBalance: _penaltyBalanceController.text,
        discountPrinciple: _discountPrincipleController.text,
        discountPenalty: _discountPenaltyController.text,
      );

      if (result == "Success") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account closed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      print("Submit Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? hintText,
    bool readOnly = false,
    VoidCallback? onTap,
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
            color: backgroundColor ?? (readOnly ? const Color(0xFFF9FAFB) : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hintText,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: InputBorder.none,
              hintStyle: const TextStyle(
                fontSize: 16,
                color: Color(0xFF9CA3AF),
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF374151),
            ),
            validator: validator ?? (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return 'This field is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField({
    required String label,
    required TextEditingController controller,
    bool isRequired = true,
    bool readOnly = false,
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
            color: backgroundColor ?? (readOnly ? const Color(0xFFF9FAFB) : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  readOnly: readOnly,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    border: InputBorder.none,
                    hintStyle: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF374151),
                  ),
                  validator: (value) {
                    if (isRequired && (value == null || value.isEmpty)) {
                      return 'This field is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer :',
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                value: _selectedCustomer,
                isExpanded: true,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.black,
                  size: 24,
                ),
                hint: !_customersLoaded
                    ? const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Loading customers...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                )
                    : const Text(
                  'Enter customer name',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                items: _customers.map((customer) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: customer,
                    child: Text(
                      '${customer['name']} (${customer['mobile']})',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF374151),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (Map<String, dynamic>? value) {
                  if (value != null) {
                    setState(() {
                      _selectedCustomer = value;
                      _customerNameController.text = value['name'] ?? '';
                      _loansLoaded = false;
                      _selectedLoan = null;
                      _resetLoanDetails();
                    });
                    _loadLoansByCustomer(value['id'] ?? '');
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoanDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Loan No :',
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                value: _selectedLoan,
                isExpanded: true,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.black,
                  size: 24,
                ),
                hint: !_loansLoaded
                    ? _selectedCustomer == null
                    ? const Text(
                  'Select customer first',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                )
                    : const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Loading loans...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                )
                    : const Text(
                  'Enter loan number',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                items: _loans.map((loan) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: loan,
                    child: Text(
                      '${loan['loan_no']} - ₹${loan['given_amount']} (${loan['loan_status']})',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF374151),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (Map<String, dynamic>? value) {
                  if (value != null) {
                    setState(() {
                      _selectedLoan = value;
                      _loanNoController.text = value['loan_no'] ?? '';
                    });
                    _loadLoanDetails(value['id'] ?? '');
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _serialNoController.dispose();
    _dateController.dispose();
    _customerNameController.dispose();
    _loanNoController.dispose();
    _loanAmountController.dispose();
    _loanPaidController.dispose();
    _balanceAmountController.dispose();
    _penaltyAmountController.dispose();
    _penaltyCollectedController.dispose();
    _penaltyBalanceController.dispose();
    _discountPrincipleController.dispose();
    _discountPenaltyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Processing...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1271),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    height: 113,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Account Closing',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Close loan account and finalize payment details',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Container
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'Serial No :',
                                  controller: _serialNoController,
                                  readOnly: true,
                                  backgroundColor: const Color(0xFFF9FAFB),
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: _buildInputField(
                                  label: 'Date :',
                                  controller: _dateController,
                                  onTap: () => _selectDate(context),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Second Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildCustomerDropdown(),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: _buildLoanDropdown(),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Third Row - Loan Amounts
                          Row(
                            children: [
                              Expanded(
                                child: _buildAmountField(
                                  label: 'Loan Amount :',
                                  controller: _loanAmountController,
                                  readOnly: true,
                                  backgroundColor: const Color(0xFFF9FAFB),
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: _buildAmountField(
                                  label: 'Loan Paid :',
                                  controller: _loanPaidController,
                                  readOnly: true,
                                  backgroundColor: const Color(0xFFF9FAFB),
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: _buildAmountField(
                                  label: 'Balance Amount :',
                                  controller: _balanceAmountController,
                                  readOnly: true,
                                  backgroundColor: const Color(0xFFF9FAFB),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Fourth Row - Penalty Amounts
                          Row(
                            children: [
                              Expanded(
                                child: _buildAmountField(
                                  label: 'Penalty Amount :',
                                  controller: _penaltyAmountController,
                                  readOnly: true,
                                  backgroundColor: const Color(0xFFF9FAFB),
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: _buildAmountField(
                                  label: 'Penalty Collected :',
                                  controller: _penaltyCollectedController,
                                  readOnly: true,
                                  backgroundColor: const Color(0xFFF9FAFB),
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: _buildAmountField(
                                  label: 'Penalty Balance :',
                                  controller: _penaltyBalanceController,
                                  readOnly: true,
                                  backgroundColor: const Color(0xFFF9FAFB),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Fifth Row - Discounts
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _buildAmountField(
                                  label: 'Discount Principle :',
                                  controller: _discountPrincipleController,
                                  isRequired: false,
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: _buildAmountField(
                                  label: 'Discount Penalty :',
                                  controller: _discountPenaltyController,
                                  isRequired: false,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // Calculate final settlement
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD1D5DB)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Final Settlement Amount: ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                Text(
                                  '₹${_calculateFinalSettlement().toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 159,
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
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
                              const SizedBox(width: 32),
                              SizedBox(
                                width: 159,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9CA3AF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Close Account',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  double _calculateFinalSettlement() {
    double balanceAmount = double.tryParse(_balanceAmountController.text) ?? 0;
    double discountPrinciple = double.tryParse(_discountPrincipleController.text) ?? 0;
    double penaltyBalance = double.tryParse(_penaltyBalanceController.text) ?? 0;
    double discountPenalty = double.tryParse(_discountPenaltyController.text) ?? 0;

    double principleSettlement = balanceAmount - discountPrinciple;
    double penaltySettlement = penaltyBalance - discountPenalty;

    return principleSettlement + penaltySettlement;
  }
}
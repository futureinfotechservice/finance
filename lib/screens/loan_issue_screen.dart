import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';


class LoanIssueScreen extends StatefulWidget {
  const LoanIssueScreen({super.key});

  @override
  State<LoanIssueScreen> createState() => _LoanIssueScreenState();
}

class _LoanIssueScreenState extends State<LoanIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String? _selectedCustomer;
  String? _selectedLoanType;
  String? _selectedLoanDay;
  String? _selectedNoOfWeeks;
  String? _selectedPaymentMode;

  // Controllers
  final TextEditingController _loanNoController = TextEditingController();
  final TextEditingController _loanAmountController = TextEditingController(text: '10000');
  final TextEditingController _givenAmountController = TextEditingController(text: '9000');
  final TextEditingController _interestAmountController = TextEditingController(text: '1000');

  // Sample data
  final List<String> _customers = [
    'John Doe',
    'Jane Smith',
    'Robert Johnson',
    'Emily Davis',
    'Michael Wilson'
  ];

  final List<String> _loanTypes = [
    'Personal Loan',
    'Business Loan',
    'Home Loan',
    'Gold Loan',
    'Education Loan'
  ];

  final List<String> _loanDays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  final List<String> _noOfWeeksOptions = [
    '4 Weeks',
    '8 Weeks',
    '12 Weeks',
    '16 Weeks',
    '20 Weeks',
    '24 Weeks'
  ];

  final List<String> _paymentModes = [
    'Cash',
    'Bank Transfer',
    'Cheque',
    'UPI',
    'Credit Card'
  ];

  // Payment schedule data
  final List<Map<String, dynamic>> _paymentSchedule = [
    {'dueNo': 1, 'dueDate': '12/12/2025', 'dueAmount': '₹ 1000.00'},
    {'dueNo': 2, 'dueDate': '19/12/2025', 'dueAmount': '₹ 1000.00'},
    {'dueNo': 3, 'dueDate': '26/12/2025', 'dueAmount': '₹ 1000.00'},
    {'dueNo': 4, 'dueDate': '02/01/2026', 'dueAmount': '₹ 1000.00'},
    {'dueNo': 5, 'dueDate': '09/01/2026', 'dueAmount': '₹ 1000.00'},
    {'dueNo': 6, 'dueDate': '16/01/2026', 'dueAmount': '₹ 1000.00'},
    {'dueNo': 7, 'dueDate': '23/01/2026', 'dueAmount': '₹ 1000.00'},
    {'dueNo': 8, 'dueDate': '30/01/2026', 'dueAmount': '₹ 1000.00'},
    {'dueNo': 9, 'dueDate': '06/02/2026', 'dueAmount': '₹ 1000.00'},
    {'dueNo': 10, 'dueDate': '13/02/2026', 'dueAmount': '₹ 1000.00'},
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
                    ? const Icon(Icons.calendar_today, size: 20, color: Colors.grey)
                    : null,
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF252525),
              ),
              validator: (value) {
                if (isRequired && (value == null || value.isEmpty)) {
                  return 'This field is required';
                }
                return null;
              },
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

  Widget _buildPaymentScheduleTable() {
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
        const SizedBox(height: 8),
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
                height: 57,
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
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Due No',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Due Date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Due Amount',
                          style: TextStyle(
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
                  return Container(
                    height: 57,
                    color: index.isOdd ? Colors.white : const Color(0xFFF9FAFB),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${schedule['dueNo']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              schedule['dueDate'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              schedule['dueAmount'],
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
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _issueLoan() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loan issued successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Reset form or navigate
    }
  }

  void _cancel() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedDate = null;
      _selectedCustomer = null;
      _selectedLoanType = null;
      _selectedLoanDay = null;
      _selectedNoOfWeeks = null;
      _selectedPaymentMode = null;
    });
  }

  void _navigateToCustomerMaster() {
    // Navigate to Customer Master screen
    // You'll need to implement navigation based on your app structure
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
              hintText: 'Enter loan number',
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildInputField(
              label: 'Date :',
              controller: TextEditingController(
                text: _selectedDate != null
                    ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                    : '',
              ),
              hintText: 'Select date',
              isReadOnly: true,
              onTap: () => _selectDate(context),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _buildDropdownField(
              label: 'Customer :',
              options: _customers,
              selectedValue: _selectedCustomer,
              onChanged: (value) {
                setState(() {
                  _selectedCustomer = value;
                });
              },
              hintText: 'Select customer',
            ),
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
            child: _buildDropdownField(
              label: 'Loan Type :',
              options: _loanTypes,
              selectedValue: _selectedLoanType,
              onChanged: (value) {
                setState(() {
                  _selectedLoanType = value;
                });
              },
              hintText: 'Select loan type',
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildDropdownField(
              label: 'Loan Day :',
              options: _loanDays,
              selectedValue: _selectedLoanDay,
              onChanged: (value) {
                setState(() {
                  _selectedLoanDay = value;
                });
              },
              hintText: 'Select loan day',
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _buildDropdownField(
              label: 'No. of Weeks :',
              options: _noOfWeeksOptions,
              selectedValue: _selectedNoOfWeeks,
              onChanged: (value) {
                setState(() {
                  _selectedNoOfWeeks = value;
                });
              },
              hintText: 'Select weeks',
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
              keyboardType: TextInputType.number,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildInputField(
              label: 'Start Date :',
              controller: TextEditingController(text: '12/12/2025'),
              hintText: 'Select start date',
              isReadOnly: true,
              backgroundColor: const Color(0xFFFDFEFF),
              onTap: () => _selectDate(context),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _buildInputField(
              label: 'Given Amount :',
              controller: _givenAmountController,
              hintText: 'Enter amount',
              keyboardType: TextInputType.number,
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
              label: 'Interest Amount :',
              controller: _interestAmountController,
              hintText: 'Enter interest',
              keyboardType: TextInputType.number,
              backgroundColor: const Color(0xFFD9D9D9).withOpacity(0.5),
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
          hintText: 'Enter loan number',
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Date :',
          controller: TextEditingController(
            text: _selectedDate != null
                ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                : '',
          ),
          hintText: 'Select date',
          isReadOnly: true,
          onTap: () => _selectDate(context),
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Customer :',
          options: _customers,
          selectedValue: _selectedCustomer,
          onChanged: (value) {
            setState(() {
              _selectedCustomer = value;
            });
          },
          hintText: 'Select customer',
        ),
      ],
    );
  }

  Widget _buildMobileSecondRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownField(
          label: 'Loan Type :',
          options: _loanTypes,
          selectedValue: _selectedLoanType,
          onChanged: (value) {
            setState(() {
              _selectedLoanType = value;
            });
          },
          hintText: 'Select loan type',
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Loan Day :',
          options: _loanDays,
          selectedValue: _selectedLoanDay,
          onChanged: (value) {
            setState(() {
              _selectedLoanDay = value;
            });
          },
          hintText: 'Select loan day',
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'No. of Weeks :',
          options: _noOfWeeksOptions,
          selectedValue: _selectedNoOfWeeks,
          onChanged: (value) {
            setState(() {
              _selectedNoOfWeeks = value;
            });
          },
          hintText: 'Select weeks',
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
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Start Date :',
          controller: TextEditingController(text: '12/12/2025'),
          hintText: 'Select start date',
          isReadOnly: true,
          backgroundColor: const Color(0xFFFDFEFF),
          onTap: () => _selectDate(context),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          label: 'Given Amount :',
          controller: _givenAmountController,
          hintText: 'Enter amount',
          keyboardType: TextInputType.number,
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
          keyboardType: TextInputType.number,
          backgroundColor: const Color(0xFFD9D9D9).withOpacity(0.5),
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
            onPressed: _cancel,
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
            onPressed: _issueLoan,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
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
}
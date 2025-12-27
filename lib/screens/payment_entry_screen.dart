import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment_entry_model.dart';
import '../services/payment_entry_api_service.dart';

class PaymentEntryScreen extends StatefulWidget {
  final PaymentEntryModel? paymentEntry;
  const PaymentEntryScreen({super.key, this.paymentEntry});

  @override
  State<PaymentEntryScreen> createState() => _PaymentEntryScreenState();
}

class _PaymentEntryScreenState extends State<PaymentEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final PaymentEntryApiService _apiService = PaymentEntryApiService();
  final TextEditingController _serialNoController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isEditMode = false;
  bool _accountsLoaded = false;
  bool _initialDataLoaded = false;

  // Payment account dropdown (with id)
  List<Map<String, dynamic>> _paymentAccounts = [];
  Map<String, dynamic>? _selectedPaymentAccount;

  // Cash/Bank dropdown - fixed options
  final List<String> _cashBankOptions = ['Cash', 'Bank'];
  String _selectedCashBank = 'Cash'; // Default to Cash

  // Store payment data for edit mode
  PaymentEntryModel? _paymentData;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.paymentEntry != null;

    if (_isEditMode && widget.paymentEntry != null) {
      _paymentData = widget.paymentEntry;
      // Set the values immediately from the passed payment data
      _serialNoController.text = _paymentData!.serialNo;
      _dateController.text = _paymentData!.date;
      _selectedCashBank = _paymentData!.cashBank;
      _amountController.text = _paymentData!.amount;
      _descriptionController.text = _paymentData!.description;
    }

    _initializeData();
    if (!_isEditMode) {
      _loadNextSerialNo();
    }
  }

  // void _initializeData() async {
  //   try {
  //     await _loadPaymentAccounts();
  //   } catch (e) {
  //     print("Initialize data error: $e");
  //   }
  // }

  void _initializeData() async {
    try {
      final accounts = await _apiService.getPaymentAccounts(context);
      if (mounted) {
        setState(() {
          _paymentAccounts = accounts;
          _accountsLoaded = true;

          // If we have a payment entry to edit, find and select the matching account
          if (_isEditMode && _paymentData != null) {
            _selectAccountForEdit(accounts);
          }

          // Mark initial data as loaded
          _initialDataLoaded = true;
        });
      }
    } catch (e) {
      print("Load payment accounts error: $e");
      if (mounted) {
        setState(() {
          _accountsLoaded = true;
          _initialDataLoaded = true;
        });
      }
    }
  }

  void _selectAccountForEdit(List<Map<String, dynamic>> accounts) {
    if (_paymentData != null && _paymentData!.paymentAccountId.isNotEmpty) {
      try {
        print("Looking for payment account with ID: ${_paymentData!.paymentAccountId}");
        print("Payment account name from data: ${_paymentData!.paymentAccount}");
        print("Available accounts: ${accounts.length}");

        // Debug: Print all accounts
        for (var i = 0; i < accounts.length; i++) {
          print("Account $i: ${accounts[i]['id']} - ${accounts[i]['name']}");
        }

        // Try to find exact match by ID (compare as strings)
        final matchingAccount = accounts.firstWhere(
              (acc) => acc['id']?.toString() == _paymentData!.paymentAccountId?.toString(),
          orElse: () => {},
        );

        if (matchingAccount.isNotEmpty) {
          print("Found matching account by ID: ${matchingAccount['name']}");
          _selectedPaymentAccount = matchingAccount;
        } else if (_paymentData!.paymentAccount.isNotEmpty) {
          // If ID doesn't match, try to find by name (case insensitive)
          final nameMatch = accounts.firstWhere(
                (acc) => (acc['name']?.toString() ?? '').toLowerCase() ==
                _paymentData!.paymentAccount.toLowerCase(),
            orElse: () => {},
          );

          if (nameMatch.isNotEmpty) {
            print("Found matching account by name: ${nameMatch['name']}");
            _selectedPaymentAccount = nameMatch;
          } else if (accounts.isNotEmpty) {
            // Default to first account if no match found
            print("No matching account found, defaulting to first account");
            _selectedPaymentAccount = accounts.first;
          }
        }
      } catch (e) {
        print("Error selecting account for edit: $e");
        if (accounts.isNotEmpty) {
          _selectedPaymentAccount = accounts.first;
        }
      }
    } else if (accounts.isNotEmpty) {
      // If no payment account ID, default to first account
      _selectedPaymentAccount = accounts.first;
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

    if (_selectedPaymentAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String result;

      if (_isEditMode) {
        result = await _apiService.updatePaymentEntry(
          context: context,
          paymentId: _paymentData!.id,
          serialNo: _serialNoController.text,
          date: _dateController.text,
          paymentAccount: _selectedPaymentAccount!['name']?.toString() ?? '',
          paymentAccountId: _selectedPaymentAccount!['id']?.toString() ?? '',
          cashBank: _selectedCashBank,
          amount: _amountController.text.isNotEmpty ? _amountController.text : '0.00',
          description: _descriptionController.text,
        );
      } else {
        result = await _apiService.insertPaymentEntry(
          context: context,
          serialNo: _serialNoController.text,
          date: _dateController.text,
          paymentAccount: _selectedPaymentAccount!['name']?.toString() ?? '',
          paymentAccountId: _selectedPaymentAccount!['id']?.toString() ?? '',
          cashBank: _selectedCashBank,
          amount: _amountController.text.isNotEmpty ? _amountController.text : '0.00',
          description: _descriptionController.text,
        );
      }

      if (result == "Success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEditMode
                    ? 'Payment updated successfully!'
                    : 'Payment created successfully!'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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
            color: readOnly ? const Color(0xFFD9D9D9) : Colors.white,
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

  Widget _buildPaymentAccountDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Account :',
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
                value: _selectedPaymentAccount,
                isExpanded: true,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.black,
                  size: 24,
                ),
                hint: !_accountsLoaded
                    ? const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Loading accounts...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                )
                    : const Text(
                  'Select payment account',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                items: _paymentAccounts.map((account) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: account,
                    child: Text(
                      account['name']?.toString() ?? 'Unknown',
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
                      _selectedPaymentAccount = value;
                    });
                  }
                },
              ),
            ),
          ),
        ),
        if (_selectedPaymentAccount == null && _accountsLoaded)
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Text(
              'This field is required',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCashBankDropdown() {
    // Ensure cash/bank is set from saved data
    if (_isEditMode && _paymentData != null && !_initialDataLoaded) {
      // This will be called after accounts are loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedCashBank = _paymentData!.cashBank;
          });
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cash/Bank :',
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
              child: DropdownButton<String>(
                value: _selectedCashBank,
                isExpanded: true,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.black,
                  size: 24,
                ),
                items: _cashBankOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF374151),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedCashBank = value;
                    });
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount :',
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
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF374151),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Amount is required';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Enter valid amount';
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

  @override
  void dispose() {
    _serialNoController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
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
                        Text(
                          _isEditMode ? 'Edit Payment' : 'Payment Entry',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Record payment transactions and manage cash flow',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Container
                  Container(
                    width: double.infinity,
                    height: 531,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(0),
                    ),
                    child: Padding(
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
                                    hintText: 'Auto-generated',
                                  ),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  child: _buildInputField(
                                    label: 'Date :',
                                    controller: _dateController,
                                    onTap: () => _selectDate(context),
                                    hintText: 'Select date',
                                  ),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  child: _buildPaymentAccountDropdown(),
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),

                            // Second Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCashBankDropdown(),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  child: _buildAmountField(),
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),

                            // Description
                            _buildInputField(
                              label: 'Description :',
                              controller: _descriptionController,
                              isRequired: false,
                              hintText: 'Enter description (optional)',
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
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 159,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E293B),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      _isEditMode ? 'Update' : 'Save Payment',
                                      style: const TextStyle(
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
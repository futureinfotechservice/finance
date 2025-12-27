import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/receipt_entry_api_service.dart';
import '../models/receipt_entry_model.dart';

class ReceiptEntryScreen extends StatefulWidget {
  final ReceiptEntryModel? receiptEntry;
  const ReceiptEntryScreen({super.key, this.receiptEntry});

  @override
  State<ReceiptEntryScreen> createState() => _ReceiptEntryScreenState();
}

class _ReceiptEntryScreenState extends State<ReceiptEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final ReceiptEntryApiService _apiService = ReceiptEntryApiService();
  final TextEditingController _serialNoController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isEditMode = false;
  bool _accountsLoaded = false;
  bool _initialDataLoaded = false;

  // Receipt from dropdown (with id)
  List<Map<String, dynamic>> _receiptFromAccounts = [];
  Map<String, dynamic>? _selectedReceiptFromAccount;

  // Cash/Bank dropdown - fixed options
  final List<String> _cashBankOptions = ['Cash', 'Bank'];
  String _selectedCashBank = 'Cash'; // Default to Cash

  // Store receipt data for edit mode
  ReceiptEntryModel? _receiptData;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.receiptEntry != null;

    if (_isEditMode && widget.receiptEntry != null) {
      _receiptData = widget.receiptEntry;
      // Set the values immediately from the passed receipt data
      _serialNoController.text = _receiptData!.serialNo;
      _dateController.text = _receiptData!.date;
      _selectedCashBank = _receiptData!.cashBank;
      _amountController.text = _receiptData!.amount;
      _descriptionController.text = _receiptData!.description;
    }

    _initializeData();
    if (!_isEditMode) {
      _loadNextSerialNo();
    }
  }

  // void _initializeData() async {
  //   try {
  //     await _loadReceiptFromAccounts();
  //   } catch (e) {
  //     print("Initialize data error: $e");
  //   }
  // }

  void _initializeData() async {
    try {
      final accounts = await _apiService.getReceiptFromAccounts(context);
      if (mounted) {
        setState(() {
          _receiptFromAccounts = accounts;
          _accountsLoaded = true;

          // If we have a receipt entry to edit, find and select the matching account
          if (_isEditMode && _receiptData != null) {
            _selectAccountForEdit(accounts);
          }

          // Mark initial data as loaded
          _initialDataLoaded = true;
        });
      }
    } catch (e) {
      print("Load receipt from accounts error: $e");
      if (mounted) {
        setState(() {
          _accountsLoaded = true;
          _initialDataLoaded = true;
        });
      }
    }
  }

  void _selectAccountForEdit(List<Map<String, dynamic>> accounts) {
    if (_receiptData != null && _receiptData!.receiptFromId.isNotEmpty) {
      try {
        print("Looking for receipt from account with ID: ${_receiptData!.receiptFromId}");
        print("Receipt from name from data: ${_receiptData!.receiptFrom}");
        print("Available accounts: ${accounts.length}");

        // Try to find exact match by ID (compare as strings)
        final matchingAccount = accounts.firstWhere(
              (acc) => acc['id']?.toString() == _receiptData!.receiptFromId?.toString(),
          orElse: () => {},
        );

        if (matchingAccount.isNotEmpty) {
          print("Found matching account by ID: ${matchingAccount['name']}");
          _selectedReceiptFromAccount = matchingAccount;
        } else if (_receiptData!.receiptFrom.isNotEmpty) {
          // If ID doesn't match, try to find by name (case insensitive)
          final nameMatch = accounts.firstWhere(
                (acc) => (acc['name']?.toString() ?? '').toLowerCase() ==
                _receiptData!.receiptFrom.toLowerCase(),
            orElse: () => {},
          );

          if (nameMatch.isNotEmpty) {
            print("Found matching account by name: ${nameMatch['name']}");
            _selectedReceiptFromAccount = nameMatch;
          } else if (accounts.isNotEmpty) {
            // Default to first account if no match found
            print("No matching account found, defaulting to first account");
            _selectedReceiptFromAccount = accounts.first;
          }
        }
      } catch (e) {
        print("Error selecting account for edit: $e");
        if (accounts.isNotEmpty) {
          _selectedReceiptFromAccount = accounts.first;
        }
      }
    } else if (accounts.isNotEmpty) {
      // If no receipt from ID, default to first account
      _selectedReceiptFromAccount = accounts.first;
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

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedReceiptFromAccount = null;
      _selectedCashBank = 'Cash';
      _amountController.clear();
      _descriptionController.clear();
      if (!_isEditMode) {
        _loadNextSerialNo();
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedReceiptFromAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select receipt from account'),
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
        result = await _apiService.updateReceiptEntry(
          context: context,
          receiptId: _receiptData!.id,
          serialNo: _serialNoController.text,
          date: _dateController.text,
          receiptFrom: _selectedReceiptFromAccount!['name']?.toString() ?? '',
          receiptFromId: _selectedReceiptFromAccount!['id']?.toString() ?? '',
          cashBank: _selectedCashBank,
          amount: _amountController.text.isNotEmpty ? _amountController.text : '0.00',
          description: _descriptionController.text,
        );
      } else {
        result = await _apiService.insertReceiptEntry(
          context: context,
          serialNo: _serialNoController.text,
          date: _dateController.text,
          receiptFrom: _selectedReceiptFromAccount!['name']?.toString() ?? '',
          receiptFromId: _selectedReceiptFromAccount!['id']?.toString() ?? '',
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
                    ? 'Receipt updated successfully!'
                    : 'Receipt created successfully!'
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
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFEF4444),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 47,
          decoration: BoxDecoration(
            color: readOnly ? const Color(0xFFF9FAFB) : Colors.white,
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
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
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

  Widget _buildReceiptFromDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Receipt From:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFEF4444),
              ),
            ),
          ],
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
                value: _selectedReceiptFromAccount,
                isExpanded: true,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.black,
                  size: 20,
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
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                )
                    : const Text(
                  'Select receipt from',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                items: _receiptFromAccounts.map((account) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: account,
                    child: Text(
                      account['name']?.toString() ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (Map<String, dynamic>? value) {
                  if (value != null) {
                    setState(() {
                      _selectedReceiptFromAccount = value;
                    });
                  }
                },
              ),
            ),
          ),
        ),
        if (_selectedReceiptFromAccount == null && _accountsLoaded)
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
    if (_isEditMode && _receiptData != null && !_initialDataLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedCashBank = _receiptData!.cashBank;
          });
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Cash/Bank:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFEF4444),
              ),
            ),
          ],
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
                  size: 20,
                ),
                hint: const Text(
                  'Select cash/bank',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                items: _cashBankOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      style: const TextStyle(
                        fontSize: 14,
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
        Row(
          children: [
            const Text(
              'Amount:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFEF4444),
              ),
            ),
          ],
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
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
                      fontSize: 14,
                      color: Color(0xFF999999),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
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
      backgroundColor: const Color(0xFFF8FAFC),
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
          : Center(
        child: SingleChildScrollView(
          child: Container(
            width: 800,
            margin: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  height: 109,
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
                        _isEditMode ? 'Edit Receipt' : 'Amount Receipt Entry',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter receipt details and transaction information',
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
                                label: 'Serial No:',
                                controller: _serialNoController,
                                readOnly: true,
                                hintText: 'Enter serial number',
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              child: _buildInputField(
                                label: 'Date:',
                                controller: _dateController,
                                onTap: () => _selectDate(context),
                                hintText: 'Select date',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Second Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildReceiptFromDropdown(),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              child: _buildCashBankDropdown(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Amount
                        _buildAmountField(),

                        const SizedBox(height: 32),

                        // Description
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 152,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFD1D5DB)),
                              ),
                              child: TextFormField(
                                controller: _descriptionController,
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                expands: true,
                                decoration: const InputDecoration(
                                  hintText: 'Enter description (optional)',
                                  contentPadding: EdgeInsets.all(16),
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 360,
                              height: 47,
                              child: OutlinedButton(
                                onPressed: _resetForm,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Clear Form',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 358,
                              height: 47,
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  _isEditMode ? 'Update Receipt' : 'Submit Receipt',
                                  style: const TextStyle(
                                    fontSize: 14,
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
    );
  }
}
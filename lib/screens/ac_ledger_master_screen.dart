import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../services/ac_ledger_apiservice.dart';


class ACLedgerMasterScreen extends StatefulWidget {
  final ACLedgerModel? ledger; // For edit mode
  const ACLedgerMasterScreen({super.key, this.ledger});

  @override
  State<ACLedgerMasterScreen> createState() => _ACLedgerMasterScreenState();
}

class _ACLedgerMasterScreenState extends State<ACLedgerMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ACLedgerApiService _apiService = ACLedgerApiService();

  bool _isLoading = false;
  bool _isEditMode = false;

  final TextEditingController _ledgerNameController = TextEditingController();
  final TextEditingController _openingBalanceController = TextEditingController();
  String? _selectedGroupType;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.ledger != null;
    if (_isEditMode) {
      _loadLedgerData();
    }
  }

  void _loadLedgerData() {
    if (widget.ledger != null) {
      _ledgerNameController.text = widget.ledger!.ledgername;
      _openingBalanceController.text = widget.ledger!.opening;
      _selectedGroupType = widget.ledger!.groupname;
    }
  }

  @override
  void dispose() {
    _ledgerNameController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGroupType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a group type'),
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
        result = await _apiService.updateLedger(
          context: context,
          ledgerId: widget.ledger!.id,
          ledgername: _ledgerNameController.text,
          groupname: _selectedGroupType!,
          opening: _openingBalanceController.text.isNotEmpty ? _openingBalanceController.text : '0',
        );
      } else {
        result = await _apiService.insertLedger(
          context: context,
          ledgername: _ledgerNameController.text,
          groupname: _selectedGroupType!,
          opening: _openingBalanceController.text.isNotEmpty ? _openingBalanceController.text : '0',
        );
      }

      if (result == "Success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEditMode
                    ? 'Ledger updated successfully!'
                    : 'Ledger created successfully!'
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

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedGroupType = null;
    });
    _ledgerNameController.clear();
    _openingBalanceController.clear();
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? hintText,
  }) {
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
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
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

  Widget _buildDropdownField({
    required String label,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
    String hintText = 'Select option',
    bool isRequired = true,
  }) {
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
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
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
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                items: options.map((option) {
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
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        if (isRequired && selectedValue == null)
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

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;

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
          padding: isWeb ? const EdgeInsets.all(20.0) : const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isWeb) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 180,
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
                            _isEditMode ? 'Edit AC Ledger' : 'AC Ledger Master',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isEditMode
                                ? 'Edit existing account ledger details'
                                : 'Create new account ledger for accounting',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  Container(
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
                      children: [
                        if (!isWeb) ...[
                          Container(
                            width: double.infinity,
                            height: 110,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E293B),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isEditMode ? 'Edit AC Ledger' : 'AC Ledger Master',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isEditMode
                                      ? 'Edit existing account ledger details'
                                      : 'Create new account ledger for accounting',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Padding(
                          padding: EdgeInsets.all(isWeb ? 32.0 : 20.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputField(
                                  label: 'Ledger Name',
                                  controller: _ledgerNameController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ledger name is required';
                                    }
                                    if (value.length < 2) {
                                      return 'Ledger name must be at least 2 characters';
                                    }
                                    return null;
                                  },
                                  hintText: 'Enter ledger name',
                                ),

                                SizedBox(height: isWeb ? 32 : 24),

                                _buildDropdownField(
                                  label: 'Group Type',
                                  options: ACLedgerApiService.groupTypes,
                                  selectedValue: _selectedGroupType,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGroupType = value;
                                    });
                                  },
                                  hintText: 'Select group type',
                                ),

                                SizedBox(height: isWeb ? 32 : 24),

                                _buildInputField(
                                  label: 'Opening Balance',
                                  controller: _openingBalanceController,
                                  keyboardType: TextInputType.number,
                                  isRequired: false,
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      final amount = double.tryParse(value);
                                      if (amount == null) {
                                        return 'Enter valid amount';
                                      }
                                    }
                                    return null;
                                  },
                                  hintText: 'Enter opening balance',
                                ),

                                SizedBox(height: isWeb ? 40 : 32),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: isWeb ? 146 : 140,
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
                                          _isEditMode ? 'Update' : 'Create',
                                          style: TextStyle(
                                            fontSize: isWeb ? 24 : 20,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(width: isWeb ? 32 : 24),

                                    SizedBox(
                                      width: isWeb ? 146 : 140,
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
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontSize: isWeb ? 24 : 20,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF374151),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
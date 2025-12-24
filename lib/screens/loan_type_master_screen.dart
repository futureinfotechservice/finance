import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import
import 'package:flutter/foundation.dart' show kIsWeb;

import '../services/loantype_apiservice.dart';

class LoanTypeMasterScreen extends StatefulWidget {
  final LoanTypeModel? loanType; // For edit mode
  const LoanTypeMasterScreen({super.key, this.loanType});

  @override
  State<LoanTypeMasterScreen> createState() => _LoanTypeMasterScreenState();
}

class _LoanTypeMasterScreenState extends State<LoanTypeMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final LoantypeApiService _apiService = LoantypeApiService();

  bool _isLoading = false;
  bool _isEditMode = false;

  final TextEditingController _loanTypeController = TextEditingController();
  final TextEditingController _penaltyAmountController = TextEditingController();
  final TextEditingController _noOfWeeksController = TextEditingController(); // New controller

  String? _selectedCollectionDay;

  // Remove or keep for reference if needed elsewhere
  // final List<String> _noOfWeeksOptions = [
  //   '4 Weeks',
  //   '8 Weeks',
  //   '12 Weeks',
  //   '16 Weeks',
  //   '20 Weeks',
  //   '24 Weeks'
  // ];

  final List<String> _collectionDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.loanType != null;
    if (_isEditMode) {
      _loadLoanTypeData();
    }
  }

  void _loadLoanTypeData() {
    if (widget.loanType != null) {
      _loanTypeController.text = widget.loanType!.loantype;
      _penaltyAmountController.text = widget.loanType!.penaltyamount;

      // For No of Weeks: Extract numeric value from stored format
      final storedWeeks = widget.loanType!.noofweeks;
      // Extract only numbers from the stored value (e.g., "4 Weeks" -> "4")
      final numericValue = storedWeeks.replaceAll(RegExp(r'[^0-9]'), '');
      _noOfWeeksController.text = numericValue;

      _selectedCollectionDay = widget.loanType!.collectionday;
    }
  }

  @override
  void dispose() {
    _loanTypeController.dispose();
    _penaltyAmountController.dispose();
    _noOfWeeksController.dispose(); // Dispose the new controller
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCollectionDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select collection day'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // No longer need this check as it will be validated in the text field
    // if (_selectedNoOfWeeks == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Please select number of weeks'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    //   return;
    // }

    setState(() {
      _isLoading = true;
    });

    try {
      String result;

      if (_isEditMode) {
        result = await _apiService.updateLoanType(
          context: context,
          loanTypeId: widget.loanType!.id,
          loantype: _loanTypeController.text,
          collectionday: _selectedCollectionDay!,
          penaltyamount: _penaltyAmountController.text,
          noofweeks: _noOfWeeksController.text, // Now using the text value directly
        );
      } else {
        result = await _apiService.insertLoanType(
          context: context,
          loantype: _loanTypeController.text,
          collectionday: _selectedCollectionDay!,
          penaltyamount: _penaltyAmountController.text,
          noofweeks: _noOfWeeksController.text, // Now using the text value directly
        );
      }

      if (result == "Success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEditMode
                    ? 'Loan type updated successfully!'
                    : 'Loan type created successfully!'
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
      _selectedCollectionDay = null;
    });
    _loanTypeController.clear();
    _penaltyAmountController.clear();
    _noOfWeeksController.clear(); // Clear the weeks controller
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
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
        Container(
          height: 47,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
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
                            _isEditMode ? 'Edit Loan Type' : 'Loan Type Master',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isEditMode
                                ? 'Edit existing loan type details'
                                : 'Create new loan type configuration',
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
                                  _isEditMode ? 'Edit Loan Type' : 'Loan Type Master',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isEditMode
                                      ? 'Edit existing loan type details'
                                      : 'Create new loan type configuration',
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
                                  label: 'Loan Type :',
                                  controller: _loanTypeController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Loan type is required';
                                    }
                                    if (value.length < 2) {
                                      return 'Loan type must be at least 2 characters';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: isWeb ? 32 : 24),

                                _buildDropdownField(
                                  label: 'Collection Day :',
                                  options: _collectionDays,
                                  selectedValue: _selectedCollectionDay,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCollectionDay = value;
                                    });
                                  },
                                  hintText: 'Select collection day',
                                ),

                                SizedBox(height: isWeb ? 32 : 24),

                                _buildInputField(
                                  label: 'Penalty Amount :',
                                  controller: _penaltyAmountController,
                                  keyboardType: TextInputType.number,
                                  isRequired: false,
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      final amount = double.tryParse(value);
                                      if (amount == null) {
                                        return 'Enter valid amount';
                                      }
                                      if (amount < 0) {
                                        return 'Amount cannot be negative';
                                      }
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: isWeb ? 32 : 24),

                                // Changed from dropdown to text input field for No of Weeks
                                _buildInputField(
                                  label: 'No of Weeks :',
                                  controller: _noOfWeeksController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly, // Accepts only numbers
                                    LengthLimitingTextInputFormatter(3), // Limit to 3 digits max (999 weeks)
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Number of weeks is required';
                                    }
                                    final weeks = int.tryParse(value);
                                    if (weeks == null) {
                                      return 'Enter a valid number';
                                    }
                                    if (weeks <= 0) {
                                      return 'Weeks must be greater than 0';
                                    }
                                    if (weeks > 999) {
                                      return 'Weeks cannot exceed 999';
                                    }
                                    return null;
                                  },
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


import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:file_picker/file_picker.dart';

import '../services/customer_apiservice.dart';

class CustomerMasterModel {
  String id;
  String companyid;
  String customername;
  String gstNo;
  String address;
  String area;
  String areaid;
  String mobile1;
  String mobile2;
  String refer;
  String refercontact;
  String spousename;
  String spousecontact;
  String aadharurl;
  String photourl;
  String activestatus;

  CustomerMasterModel({
    required this.id,
    required this.companyid,
    required this.customername,
    required this.gstNo,
    required this.address,
    required this.area,
    required this.areaid,
    required this.mobile1,
    required this.mobile2,
    required this.refer,
    required this.refercontact,
    required this.spousename,
    required this.spousecontact,
    required this.aadharurl,
    required this.photourl,
    required this.activestatus,
  });

  factory CustomerMasterModel.fromJson(Map<String, dynamic> json) {
    return CustomerMasterModel(
      id: json['id']?.toString() ?? '',
      companyid: json['companyid']?.toString() ?? '',
      customername: json['customername']?.toString() ?? '',
      gstNo: json['gst_no']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      areaid: json['areaid']?.toString() ?? '',
      mobile1: json['mobile1']?.toString() ?? '',
      mobile2: json['mobile2']?.toString() ?? '',
      refer: json['refer']?.toString() ?? '',
      refercontact: json['refercontact']?.toString() ?? '',
      spousename: json['spousename']?.toString() ?? '',
      spousecontact: json['spousecontact']?.toString() ?? '',
      aadharurl: json['aadharurl']?.toString() ?? '',
      photourl: json['photourl']?.toString() ?? '',
      activestatus: json['activestatus']?.toString() ?? '1',
    );
  }
}

class CustomerMasterScreen extends StatefulWidget {
  final CustomerMasterModel? customer;
  const CustomerMasterScreen({super.key, this.customer});

  @override
  State<CustomerMasterScreen> createState() => _CustomerMasterScreenState();
}

class _CustomerMasterScreenState extends State<CustomerMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomerApiService _apiService = CustomerApiService();
  String? _aadharFilePath;
  String? _photoFilePath;
  String? _aadharFileName;
  String? _photoFileName;
  Uint8List? _aadharBytes;
  Uint8List? _photoBytes;

  bool _isLoading = false;
  bool _isEditMode = false;

  final Map<String, TextEditingController> _controllers = {
    'customerName': TextEditingController(),
    'gstNumber': TextEditingController(),
    'address': TextEditingController(),
    'area': TextEditingController(),
    'areaid': TextEditingController(),
    'mobile1': TextEditingController(),
    'mobile2': TextEditingController(),
    'referredByName': TextEditingController(),
    'referredByContact': TextEditingController(),
    'spouseName': TextEditingController(),
    'spouseNumber': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.customer != null;
    if (_isEditMode) {
      _loadCustomerData();
    }
  }

  void _loadCustomerData() {
    if (widget.customer != null) {
      _controllers['customerName']!.text = widget.customer!.customername;
      _controllers['gstNumber']!.text = widget.customer!.gstNo;
      _controllers['address']!.text = widget.customer!.address;
      _controllers['area']!.text = widget.customer!.area;
      _controllers['areaid']!.text = widget.customer!.areaid;
      _controllers['mobile1']!.text = widget.customer!.mobile1;
      _controllers['mobile2']!.text = widget.customer!.mobile2;
      _controllers['referredByName']!.text = widget.customer!.refer;
      _controllers['referredByContact']!.text = widget.customer!.refercontact;
      _controllers['spouseName']!.text = widget.customer!.spousename;
      _controllers['spouseNumber']!.text = widget.customer!.spousecontact;
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _pickAadharFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        setState(() {
          if (kIsWeb) {
            // For web
            _aadharBytes = file.bytes;
            _aadharFileName = file.name;
            _aadharFilePath = 'data:${file.extension};base64,${base64.encode(file.bytes!)}';
          } else {
            // For mobile
            _aadharFilePath = file.path!;
            _aadharFileName = file.name;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aadhar file selected: ${file.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error picking Aadhar file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickPhotoFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        setState(() {
          if (kIsWeb) {
            // For web
            _photoBytes = file.bytes;
            _photoFileName = file.name;
            _photoFilePath = 'data:${file.extension};base64,${base64.encode(file.bytes!)}';
          } else {
            // For mobile
            _photoFilePath = file.path!;
            _photoFileName = file.name;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo file selected: ${file.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error picking photo file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String result;

      if (_isEditMode) {
        result = await _apiService.updateCustomer(
          context: context,
          customerId: widget.customer!.id,
          customername: _controllers['customerName']!.text,
          mobile1: _controllers['mobile1']!.text,
          mobile2: _controllers['mobile2']!.text,
          address: _controllers['address']!.text,
          area: _controllers['area']!.text,
          areaid: _controllers['areaid']!.text,
          gstNo: _controllers['gstNumber']!.text,
          refer: _controllers['referredByName']!.text,
          refercontact: _controllers['referredByContact']!.text,
          spousename: _controllers['spouseName']!.text,
          spousecontact: _controllers['spouseNumber']!.text,
          aadharFile: _aadharFilePath,
          photoFile: _photoFilePath,
        );
      } else {
        result = await _apiService.insertCustomer(
          context: context,
          customername: _controllers['customerName']!.text,
          mobile1: _controllers['mobile1']!.text,
          mobile2: _controllers['mobile2']!.text,
          address: _controllers['address']!.text,
          area: _controllers['area']!.text,
          areaid: _controllers['areaid']!.text,
          gstNo: _controllers['gstNumber']!.text,
          refer: _controllers['referredByName']!.text,
          refercontact: _controllers['referredByContact']!.text,
          spousename: _controllers['spouseName']!.text,
          spousecontact: _controllers['spouseNumber']!.text,
          aadharFile: _aadharFilePath,
          photoFile: _photoFilePath,
        );
      }

      if (result == "Success") {
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Customer updated successfully!' : 'Customer created successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isEditMode ? 'update' : 'create'} customer'),
            backgroundColor: Colors.red,
          ),
        );
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
    required String hint,
    required TextEditingController controller,
    bool isRequired = false,
    bool isTextArea = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
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
                color: Color(0xFF2D3748),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: isTextArea ? 98 : 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: isTextArea ? 4 : 1,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 16,
                color: Color(0xFF999999),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isTextArea ? 12 : 0,
              ),
              border: InputBorder.none,
            ),
            validator: validator ?? (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return 'This field is required';
              }
              if (keyboardType == TextInputType.phone && value != null && value.isNotEmpty) {
                final phoneRegex = RegExp(r'^[0-9]{10}$');
                if (!phoneRegex.hasMatch(value)) {
                  return 'Enter valid 10-digit mobile number';
                }
              }
              if (label.contains('GST') && value != null && value.isNotEmpty) {
                final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                if (!gstRegex.hasMatch(value)) {
                  return 'Enter valid GST number';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUploadArea({
    required String label,
    required String description,
    required String fileTypes,
    required VoidCallback onTap,
    String? fileName,
    bool isRequired = false,
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
                color: Color(0xFF2D3748),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 132,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            child: fileName != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.file_present, size: 32, color: Colors.green),
                  const SizedBox(height: 8),
                  Text(
                    fileName.length > 30 ? '${fileName.substring(0, 27)}...' : fileName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A5568),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Click to change',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, size: 24, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fileTypes,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFA0AEC0),
                  ),
                ),
              ],
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
          padding: isWeb
              ? const EdgeInsets.all(20.0)
              : const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1299),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isWeb) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 88,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E293B),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditMode ? 'Edit Customer' : 'Customer Master',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isEditMode
                                ? 'Edit existing customer details'
                                : 'Create new customer record with complete details',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (!isWeb) ...[
                          Container(
                            height: 88,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E293B),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isEditMode
                                      ? 'Edit Customer'
                                      : 'Customer Master',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isEditMode
                                      ? 'Edit existing customer details'
                                      : 'Create new customer record with complete details',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Padding(
                          padding: EdgeInsets.all(isWeb ? 20.0 : 16.0),
                          child: Form(
                            key: _formKey,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isLargeScreen =
                                    constraints.maxWidth > 768;

                                return Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    if (isLargeScreen)
                                      _buildDesktopLayout()
                                    else
                                      _buildMobileLayout(),

                                    const SizedBox(height: 30),

                                    // Action Buttons
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          style: OutlinedButton.styleFrom(
                                            padding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 32,
                                              vertical: 12,
                                            ),
                                            side: BorderSide(
                                              color: Colors.grey[300]!,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF4A5568),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        ElevatedButton(
                                          onPressed: _submitForm,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                            const Color(0xFF4318D1),
                                            padding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 32,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(8),
                                            ),
                                            elevation: 2,
                                            shadowColor: const Color(
                                                0xFF4318D1)
                                                .withOpacity(0.2),
                                          ),
                                          child: Text(
                                            _isEditMode
                                                ? 'Update Customer'
                                                : 'Create Customer',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
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

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        // Row 1: Customer Name and GST
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildInputField(
                  label: 'Customer Name',
                  hint: 'Enter customer full name',
                  controller: _controllers['customerName']!,
                  isRequired: true,
                ),
              ),
            ),
            Expanded(
              child: _buildInputField(
                label: 'GST Number',
                hint: '22AAAAA0000A1Z5',
                controller: _controllers['gstNumber']!,
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        // Address (full width)
        _buildInputField(
          label: 'Address',
          hint: 'Enter complete address',
          controller: _controllers['address']!,
          isRequired: true,
          isTextArea: true,
        ),

        const SizedBox(height: 30),

        // Row 2: Area, Area ID, Mobile 1
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildInputField(
                  label: 'Area',
                  hint: 'Enter area/locality',
                  controller: _controllers['area']!,
                  isRequired: true,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildInputField(
                  label: 'Area ID',
                  hint: 'Enter area ID',
                  controller: _controllers['areaid']!,
                  isRequired: true,
                ),
              ),
            ),
            Expanded(
              child: _buildInputField(
                label: 'Mobile Number 1',
                hint: '9876543210',
                controller: _controllers['mobile1']!,
                isRequired: true,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        // Row 3: Mobile 2, Referred by Name, Referred by Contact
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildInputField(
                  label: 'Mobile Number 2',
                  hint: '9876543210',
                  controller: _controllers['mobile2']!,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildInputField(
                  label: 'Referred by Name',
                  hint: 'Enter referrer name',
                  controller: _controllers['referredByName']!,
                ),
              ),
            ),
            Expanded(
              child: _buildInputField(
                label: 'Referred by Contact',
                hint: '9876543210',
                controller: _controllers['referredByContact']!,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        // Row 4: Spouse Name and Spouse Number
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildInputField(
                  label: 'Spouse Name',
                  hint: 'Enter spouse name',
                  controller: _controllers['spouseName']!,
                ),
              ),
            ),
            Expanded(
              child: _buildInputField(
                label: 'Spouse Number',
                hint: '9876543210',
                controller: _controllers['spouseNumber']!,
                keyboardType: TextInputType.phone,
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),

        const SizedBox(height: 30),

        // Upload Sections
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildUploadArea(
                  label: 'Aadhar Upload',
                  description: 'Click to upload Aadhar document',
                  fileTypes: 'PDF, JPG, PNG up to 10MB',
                  onTap: _pickAadharFile,
                  fileName: _aadharFileName,
                ),
              ),
            ),
            Expanded(
              child: _buildUploadArea(
                label: 'Photo Upload',
                description: 'Click to upload customer photo',
                fileTypes: 'JPG, PNG up to 5MB',
                onTap: _pickPhotoFile,
                fileName: _photoFileName,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildInputField(
          label: 'Customer Name',
          hint: 'Enter customer full name',
          controller: _controllers['customerName']!,
          isRequired: true,
        ),

        const SizedBox(height: 20),

        _buildInputField(
          label: 'GST Number',
          hint: '22AAAAA0000A1Z5',
          controller: _controllers['gstNumber']!,
        ),

        const SizedBox(height: 20),

        _buildInputField(
          label: 'Address',
          hint: 'Enter complete address',
          controller: _controllers['address']!,
          isRequired: true,
          isTextArea: true,
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildInputField(
                  label: 'Area',
                  hint: 'Enter area/locality',
                  controller: _controllers['area']!,
                  isRequired: true,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _buildInputField(
                  label: 'Area ID',
                  hint: 'Enter area ID',
                  controller: _controllers['areaid']!,
                  isRequired: true,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        _buildInputField(
          label: 'Mobile Number 1',
          hint: '9876543210',
          controller: _controllers['mobile1']!,
          isRequired: true,
          keyboardType: TextInputType.phone,
        ),

        const SizedBox(height: 20),

        _buildInputField(
          label: 'Mobile Number 2',
          hint: '9876543210',
          controller: _controllers['mobile2']!,
          keyboardType: TextInputType.phone,
        ),

        const SizedBox(height: 20),

        _buildInputField(
          label: 'Referred by Name',
          hint: 'Enter referrer name',
          controller: _controllers['referredByName']!,
        ),

        const SizedBox(height: 20),

        _buildInputField(
          label: 'Referred by Contact',
          hint: '9876543210',
          controller: _controllers['referredByContact']!,
          keyboardType: TextInputType.phone,
        ),

        const SizedBox(height: 20),

        _buildInputField(
          label: 'Spouse Name',
          hint: 'Enter spouse name',
          controller: _controllers['spouseName']!,
        ),

        const SizedBox(height: 20),

        _buildInputField(
          label: 'Spouse Number',
          hint: '9876543210',
          controller: _controllers['spouseNumber']!,
          keyboardType: TextInputType.phone,
        ),

        const SizedBox(height: 30),

        _buildUploadArea(
          label: 'Aadhar Upload',
          description: 'Click to upload Aadhar document',
          fileTypes: 'PDF, JPG, PNG up to 10MB',
          onTap: _pickAadharFile,
          fileName: _aadharFileName,
        ),

        const SizedBox(height: 20),

        _buildUploadArea(
          label: 'Photo Upload',
          description: 'Click to upload customer photo',
          fileTypes: 'JPG, PNG up to 5MB',
          onTap: _pickPhotoFile,
          fileName: _photoFileName,
        ),
      ],
    );
  }
}


// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:image_picker/image_picker.dart';
//
// class CustomerMasterScreen extends StatefulWidget {
//   const CustomerMasterScreen({super.key});
//
//   @override
//   State<CustomerMasterScreen> createState() => _CustomerMasterScreenState();
// }
//
// class _CustomerMasterScreenState extends State<CustomerMasterScreen> {
//   final _formKey = GlobalKey<FormState>();
//   File? _aadharFile;
//   File? _photoFile;
//   final ImagePicker _picker = ImagePicker();
//
//   final Map<String, TextEditingController> _controllers = {
//     'customerName': TextEditingController(),
//     'gstNumber': TextEditingController(text: '22AAAAA0000A1Z5'),
//     'address': TextEditingController(),
//     'area': TextEditingController(),
//     'mobile1': TextEditingController(text: '9876543210'),
//     'mobile2': TextEditingController(text: '9876543210'),
//     'referredByName': TextEditingController(),
//     'referredByContact': TextEditingController(text: '9876543210'),
//     'spouseName': TextEditingController(),
//     'spouseNumber': TextEditingController(text: '9876543210'),
//   };
//
//   @override
//   void dispose() {
//     _controllers.forEach((key, controller) => controller.dispose());
//     super.dispose();
//   }
//
//   Future<void> _pickAadharFile() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _aadharFile = File(pickedFile.path);
//       });
//     }
//   }
//
//   Future<void> _pickPhotoFile() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _photoFile = File(pickedFile.path);
//       });
//     }
//   }
//
//   Widget _buildInputField({
//     required String label,
//     required String hint,
//     required TextEditingController controller,
//     bool isRequired = false,
//     bool isTextArea = false,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: Color(0xFF2D3748),
//               ),
//             ),
//             if (isRequired)
//               const Text(
//                 ' *',
//                 style: TextStyle(
//                   color: Colors.red,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         Container(
//           height: isTextArea ? 98 : 50,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: const Color(0xFFE2E8F0)),
//           ),
//           child: TextFormField(
//             controller: controller,
//             maxLines: isTextArea ? 4 : 1,
//             decoration: InputDecoration(
//               hintText: hint,
//               hintStyle: const TextStyle(
//                 fontSize: 16,
//                 color: Color(0xFF999999),
//               ),
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: isTextArea ? 12 : 0,
//               ),
//               border: InputBorder.none,
//             ),
//             validator: (value) {
//               if (isRequired && (value == null || value.isEmpty)) {
//                 return 'This field is required';
//               }
//               return null;
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildUploadArea({
//     required String label,
//     required String description,
//     required String fileTypes,
//     required VoidCallback onTap,
//     File? file,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: Color(0xFF2D3748),
//               ),
//             ),
//             const Text(
//               ' *',
//               style: TextStyle(
//                 color: Colors.red,
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         GestureDetector(
//           onTap: onTap,
//           child: Container(
//             width: double.infinity,
//             height: 132,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(
//                 color: const Color(0xFFE2E8F0),
//                 width: 2,
//               ),
//             ),
//             child: file != null
//                 ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.file_present, size: 32),
//                   const SizedBox(height: 8),
//                   Text(
//                     file.path.split('/').last,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: Color(0xFF4A5568),
//                     ),
//                   ),
//                 ],
//               ),
//             )
//                 : Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   width: 32,
//                   height: 32,
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.black),
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: const Icon(Icons.add, size: 24),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   description,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: Color(0xFF4A5568),
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   fileTypes,
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: Color(0xFFA0AEC0),
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
//   @override
//   Widget build(BuildContext context) {
//     final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: isWeb
//               ? const EdgeInsets.all(20.0)
//               : const EdgeInsets.all(16.0),
//           child: Center(
//             child: Container(
//               constraints: const BoxConstraints(maxWidth: 1299),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (isWeb) ...[
//                     const SizedBox(height: 20),
//                     Container(
//                       width: double.infinity,
//                       height: 88,
//                       decoration: const BoxDecoration(
//                         color: Color(0xFF1E293B),
//                         borderRadius: BorderRadius.only(
//                           topLeft: Radius.circular(8),
//                           topRight: Radius.circular(8),
//                         ),
//                       ),
//                       padding: const EdgeInsets.symmetric(horizontal: 20),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: const [
//                           Text(
//                             'Customer Master',
//                             style: TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white,
//                             ),
//                           ),
//                           SizedBox(height: 4),
//                           Text(
//                             'Create new customer record with complete details',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Color(0xFFE2E8F0),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//
//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           blurRadius: 8,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       children: [
//                         if (!isWeb) ...[
//                           Container(
//                             height: 88,
//                             width: double.infinity,
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF1E293B),
//                               borderRadius: const BorderRadius.only(
//                                 topLeft: Radius.circular(8),
//                                 topRight: Radius.circular(8),
//                               ),
//                             ),
//                             padding: const EdgeInsets.symmetric(horizontal: 20),
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: const [
//                                 Text(
//                                   'Customer Master',
//                                   style: TextStyle(
//                                     fontSize: 24,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                                 SizedBox(height: 4),
//                                 Text(
//                                   'Create new customer record with complete details',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: Color(0xFFE2E8F0),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                         Padding(
//                           padding: EdgeInsets.all(isWeb ? 20.0 : 16.0),
//                           child: Form(
//                             key: _formKey,
//                             child: LayoutBuilder(
//                               builder: (context, constraints) {
//                                 final isLargeScreen = constraints.maxWidth > 768;
//
//                                 return Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     if (isLargeScreen)
//                                       _buildDesktopLayout()
//                                     else
//                                       _buildMobileLayout(),
//
//                                     const SizedBox(height: 30),
//
//                                     // Action Buttons
//                                     Row(
//                                       mainAxisAlignment: MainAxisAlignment.end,
//                                       children: [
//                                         OutlinedButton(
//                                           onPressed: () {
//                                             // Cancel action
//                                           },
//                                           style: OutlinedButton.styleFrom(
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 32,
//                                               vertical: 12,
//                                             ),
//                                             side: BorderSide(
//                                               color: Colors.grey[300]!,
//                                             ),
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius: BorderRadius.circular(8),
//                                             ),
//                                           ),
//                                           child: const Text(
//                                             'Cancel',
//                                             style: TextStyle(
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.w500,
//                                               color: Color(0xFF4A5568),
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(width: 16),
//                                         ElevatedButton(
//                                           onPressed: () {
//                                             if (_formKey.currentState!.validate()) {
//                                               // Submit form
//                                             }
//                                           },
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor: const Color(0xFF4318D1),
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 32,
//                                               vertical: 12,
//                                             ),
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius: BorderRadius.circular(8),
//                                             ),
//                                             elevation: 2,
//                                             shadowColor: const Color(0xFF4318D1).withOpacity(0.2),
//                                           ),
//                                           child: const Text(
//                                             'Create Customer',
//                                             style: TextStyle(
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.w500,
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 );
//                               },
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDesktopLayout() {
//     return Column(
//       children: [
//         // Row 1
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.only(right: 16),
//                 child: _buildInputField(
//                   label: 'Customer Name',
//                   hint: 'Enter customer full name',
//                   controller: _controllers['customerName']!,
//                   isRequired: true,
//                 ),
//               ),
//             ),
//             Expanded(
//               child: _buildInputField(
//                 label: 'GST Number',
//                 hint: '22AAAAA0000A1Z5',
//                 controller: _controllers['gstNumber']!,
//               ),
//             ),
//           ],
//         ),
//
//         const SizedBox(height: 30),
//
//         // Address (full width)
//         _buildInputField(
//           label: 'Address',
//           hint: 'Enter complete address',
//           controller: _controllers['address']!,
//           isRequired: true,
//           isTextArea: true,
//         ),
//
//         const SizedBox(height: 30),
//
//         // Row 2
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.only(right: 16),
//                 child: _buildInputField(
//                   label: 'Area',
//                   hint: 'Enter area/locality',
//                   controller: _controllers['area']!,
//                   isRequired: true,
//                 ),
//               ),
//             ),
//             Expanded(
//               child: _buildInputField(
//                 label: 'Mobile Number 1',
//                 hint: '9876543210',
//                 controller: _controllers['mobile1']!,
//                 isRequired: true,
//               ),
//             ),
//           ],
//         ),
//
//         const SizedBox(height: 30),
//
//         // Row 3
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.only(right: 16),
//                 child: _buildInputField(
//                   label: 'Mobile Number 2',
//                   hint: '9876543210',
//                   controller: _controllers['mobile2']!,
//                 ),
//               ),
//             ),
//             Expanded(
//               child: _buildInputField(
//                 label: 'Referred by Name',
//                 hint: 'Enter referrer name',
//                 controller: _controllers['referredByName']!,
//                 isRequired: true,
//               ),
//             ),
//           ],
//         ),
//
//         const SizedBox(height: 30),
//
//         // Row 4
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.only(right: 16),
//                 child: _buildInputField(
//                   label: 'Referred by Contact',
//                   hint: '9876543210',
//                   controller: _controllers['referredByContact']!,
//                 ),
//               ),
//             ),
//             Expanded(
//               child: _buildInputField(
//                 label: 'Spouse Name',
//                 hint: 'Enter spouse name',
//                 controller: _controllers['spouseName']!,
//                 isRequired: true,
//               ),
//             ),
//           ],
//         ),
//
//         const SizedBox(height: 30),
//
//         // Row 5
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.only(right: 16),
//                 child: _buildInputField(
//                   label: 'Spouse Number',
//                   hint: '9876543210',
//                   controller: _controllers['spouseNumber']!,
//                   isRequired: true,
//                 ),
//               ),
//             ),
//             const Expanded(child: SizedBox()),
//           ],
//         ),
//
//         const SizedBox(height: 30),
//
//         // Upload Sections
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.only(right: 16),
//                 child: _buildUploadArea(
//                   label: 'Aadhar Upload',
//                   description: 'Click to upload Aadhar document',
//                   fileTypes: 'PDF, JPG, PNG up to 10MB',
//                   onTap: _pickAadharFile,
//                   file: _aadharFile,
//                 ),
//               ),
//             ),
//             Expanded(
//               child: _buildUploadArea(
//                 label: 'Photo Upload',
//                 description: 'Click to upload customer photo',
//                 fileTypes: 'JPG, PNG up to 5MB',
//                 onTap: _pickPhotoFile,
//                 file: _photoFile,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildMobileLayout() {
//     return Column(
//       children: [
//         _buildInputField(
//           label: 'Customer Name',
//           hint: 'Enter customer full name',
//           controller: _controllers['customerName']!,
//           isRequired: true,
//         ),
//
//         const SizedBox(height: 20),
//
//         _buildInputField(
//           label: 'GST Number',
//           hint: '22AAAAA0000A1Z5',
//           controller: _controllers['gstNumber']!,
//         ),
//
//         const SizedBox(height: 20),
//
//         _buildInputField(
//           label: 'Address',
//           hint: 'Enter complete address',
//           controller: _controllers['address']!,
//           isRequired: true,
//           isTextArea: true,
//         ),
//
//         const SizedBox(height: 20),
//
//         _buildInputField(
//           label: 'Area',
//           hint: 'Enter area/locality',
//           controller: _controllers['area']!,
//           isRequired: true,
//         ),
//
//         const SizedBox(height: 20),
//
//         _buildInputField(
//           label: 'Mobile Number 1',
//           hint: '9876543210',
//           controller: _controllers['mobile1']!,
//           isRequired: true,
//         ),
//
//         const SizedBox(height: 20),
//
//         _buildInputField(
//           label: 'Mobile Number 2',
//           hint: '9876543210',
//           controller: _controllers['mobile2']!,
//         ),
//
//         const SizedBox(height: 20),
//
//         _buildInputField(
//           label: 'Referred by Name',
//           hint: 'Enter referrer name',
//           controller: _controllers['referredByName']!,
//           isRequired: true,
//         ),
//
//         const SizedBox(height: 20),
//
//         _buildInputField(
//           label: 'Referred by Contact',
//           hint: '9876543210',
//           controller: _controllers['referredByContact']!,
//         ),
//
//         const SizedBox(height: 20),
//
//         _buildInputField(
//           label: 'Spouse Name',
//           hint: 'Enter spouse name',
//           controller: _controllers['spouseName']!,
//           isRequired: true,
//         ),
//
//         const SizedBox(height: 20),
//
//         _buildInputField(
//           label: 'Spouse Number',
//           hint: '9876543210',
//           controller: _controllers['spouseNumber']!,
//           isRequired: true,
//         ),
//
//         const SizedBox(height: 30),
//
//         _buildUploadArea(
//           label: 'Aadhar Upload',
//           description: 'Click to upload Aadhar document',
//           fileTypes: 'PDF, JPG, PNG up to 10MB',
//           onTap: _pickAadharFile,
//           file: _aadharFile,
//         ),
//
//         const SizedBox(height: 20),
//
//         _buildUploadArea(
//           label: 'Photo Upload',
//           description: 'Click to upload customer photo',
//           fileTypes: 'JPG, PNG up to 5MB',
//           onTap: _pickPhotoFile,
//           file: _photoFile,
//         ),
//       ],
//     );
//   }
// }
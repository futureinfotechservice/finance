import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final bool isRequired;
  final String fieldType; // "text", "phone", "email", "date", "multiline", "password", "number"
  final bool isReadOnly;
  final bool isCompact;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  /// NEW: for password
  final bool isPassword;
  final String? correctPassword; // optional -> show ✔️ if matches

  /// NEW: for number formatting
  final int? maxDigits; // Maximum digits before decimal
  final int? decimalDigits; // Number of decimal places (0 for integer)
  final bool useGrouping; // Whether to use thousand separators
  final String? currencySymbol; // Optional currency symbol

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.isRequired = false,
    this.fieldType = "text",
    this.isReadOnly = false,
    this.isCompact = false,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.isPassword = false,
    this.correctPassword,
    // NEW: Number formatting parameters
    this.maxDigits,
    this.decimalDigits = 0,
    this.useGrouping = true,
    this.currencySymbol,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _controller;
  String? _errorText;
  bool _isPasswordVisible = false;

  // NEW: For number formatting
  late NumberFormat _numberFormat;
  String _lastFormattedValue = '';

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();

    // NEW: Configure number format based on parameters
    _configureNumberFormat();

    // Add listener to validate on text change
    _controller.addListener(_validateField);

    // NEW: Add listener for number formatting
    if (widget.fieldType == "number") {
      _controller.addListener(_formatNumber);
    }
  }

  // NEW: Configure number formatting
  void _configureNumberFormat() {
    if (widget.fieldType == "number") {
      // Create pattern based on grouping preference
      String pattern = widget.useGrouping ? '#,##0' : '#0';

      // Add decimal places if needed
      if ((widget.decimalDigits ?? 0) > 0) {
        pattern += '.${'0' * (widget.decimalDigits!)}';
      } else {
        pattern += widget.decimalDigits == 0 ? '' : '.${'#' * (widget.decimalDigits!)}';
      }

      _numberFormat = NumberFormat(pattern);
    } else {
      _numberFormat = NumberFormat.decimalPattern();
    }
  }

  // NEW: Format number as user types
  void _formatNumber() {
    if (widget.fieldType != "number") return;

    final text = _controller.text;
    if (text == _lastFormattedValue) return;

    // Remove all non-digit characters except decimal point and minus sign
    String cleanText = text.replaceAll(RegExp(r'[^\d.-]'), '');

    // Handle multiple decimal points
    final decimalPoints = cleanText.split('.').length - 1;
    if (decimalPoints > 1) {
      cleanText = cleanText.substring(0, cleanText.lastIndexOf('.'));
    }

    // Handle multiple minus signs
    if (cleanText.contains('-')) {
      final minusCount = cleanText.split('-').length - 1;
      if (minusCount > 1) {
        cleanText = '-${cleanText.replaceAll('-', '')}';
      }
      // Ensure minus is only at the beginning
      if (cleanText.contains('-') && !cleanText.startsWith('-')) {
        cleanText = cleanText.replaceAll('-', '');
      }
    }

    // Limit decimal digits
    if (cleanText.contains('.')) {
      final parts = cleanText.split('.');
      if (parts[1].length > (widget.decimalDigits ?? 2)) {
        cleanText = '${parts[0]}.${parts[1].substring(0, widget.decimalDigits ?? 2)}';
      }
    }

    // Limit max digits before decimal
    if (widget.maxDigits != null) {
      String numberPart = cleanText;
      if (cleanText.startsWith('-')) {
        numberPart = cleanText.substring(1);
      }

      if (numberPart.contains('.')) {
        final parts = numberPart.split('.');
        if (parts[0].length > widget.maxDigits!) {
          numberPart = '${parts[0].substring(0, widget.maxDigits!)}.${parts[1]}';
          cleanText = cleanText.startsWith('-') ? '-$numberPart' : numberPart;
        }
      } else if (numberPart.length > widget.maxDigits!) {
        numberPart = numberPart.substring(0, widget.maxDigits!);
        cleanText = cleanText.startsWith('-') ? '-$numberPart' : numberPart;
      }
    }

    // Convert to number and format
    if (cleanText.isNotEmpty && cleanText != '.' && cleanText != '-') {
      try {
        final number = double.parse(cleanText);
        String formatted = _numberFormat.format(number);

        // Add currency symbol if specified
        if (widget.currencySymbol != null) {
          formatted = '${widget.currencySymbol} $formatted';
        }

        if (formatted != _lastFormattedValue) {
          _lastFormattedValue = formatted;
          _controller
            ..removeListener(_formatNumber)
            ..value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            )
            ..addListener(_formatNumber);
        }
      } catch (e) {
        // If parsing fails, keep the clean text
        if (cleanText != _lastFormattedValue) {
          _lastFormattedValue = cleanText;
          _controller
            ..removeListener(_formatNumber)
            ..value = TextEditingValue(
              text: cleanText,
              selection: TextSelection.collapsed(offset: cleanText.length),
            )
            ..addListener(_formatNumber);
        }
      }
    } else if (cleanText.isEmpty && _lastFormattedValue.isNotEmpty) {
      _lastFormattedValue = '';
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_validateField);
    if (widget.fieldType == "number") {
      _controller.removeListener(_formatNumber);
    }
    // Only dispose if we created the controller internally
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _validateField() {
    final text = _getRawText(); // Use raw text for validation
    String? error;

    if (widget.isRequired && text.isEmpty) {
      error = 'This field is required';
    } else if (text.isNotEmpty) {
      switch (widget.fieldType) {
        case "phone":
          error = _validatePhone(text);
          break;
        case "email":
          error = _validateEmail(text);
          break;
        case "number":
          error = _validateNumber(text);
          break;
      }
    }

    if (_errorText != error) {
      setState(() {
        _errorText = error;
      });
    }
  }

  // NEW: Get raw number without formatting for validation
  String _getRawText() {
    if (widget.fieldType != "number") {
      return _controller.text.trim();
    }

    String text = _controller.text.trim();

    // Remove currency symbol and formatting
    if (widget.currencySymbol != null) {
      text = text.replaceAll('${widget.currencySymbol} ', '');
    }

    // Remove grouping separators for validation
    final groupingSep = _numberFormat.symbols.GROUP_SEP;
    if (groupingSep.isNotEmpty) {
      text = text.replaceAll(RegExp('\\$groupingSep'), '');
    }

    return text;
  }

  String? _validatePhone(String phone) {
    // Remove any non-digit characters
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it's exactly 10 digits
    if (cleanPhone.length != 10) {
      return 'Please enter a valid 10-digit mobile number';
    }

    // Optional: Check if it starts with valid digits (6-9 as per Indian numbering)
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone)) {
      return 'Please enter a valid mobile number';
    }

    return null;
  }

  String? _validateEmail(String email) {
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // NEW: Validate number
  String? _validateNumber(String number) {
    if (number.isEmpty) return null;

    try {
      final value = double.parse(number);

      // Check for negative numbers if needed
      if (value < 0) {
        return 'Please enter a positive number';
      }

      // Check decimal places
      if (widget.decimalDigits == 0 && value % 1 != 0) {
        return 'Please enter a whole number';
      }

      return null;
    } catch (e) {
      return 'Please enter a valid number';
    }
  }

  // NEW: Get the numeric value
  double? getNumericValue() {
    if (widget.fieldType != "number") return null;

    final rawText = _getRawText();
    if (rawText.isEmpty) return null;

    try {
      return double.parse(rawText);
    } catch (e) {
      return null;
    }
  }

  OutlineInputBorder _border({Color color = const Color(0xFFD1D5DB)}) {
    return OutlineInputBorder(
      borderSide: BorderSide(color: color, width: 1.4),
      borderRadius: BorderRadius.circular(6),
    );
  }

  void _openDatePicker() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      String formatted = DateFormat('dd-MM-yyyy').format(pickedDate);
      _controller.text = formatted;
      widget.onChanged?.call(formatted);
      _validateField(); // Validate after setting date
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = _errorText != null && _errorText!.isNotEmpty;

    TextInputType inputType = TextInputType.text;
    int maxLines = 1;

    // Configure keyboard type and max lines based on field type
    switch (widget.fieldType) {
      case "phone":
        inputType = TextInputType.phone;
        break;
      case "email":
        inputType = TextInputType.emailAddress;
        break;
      case "number":
        inputType = TextInputType.numberWithOptions(
          decimal: (widget.decimalDigits ?? 0) > 0,
          signed: false,
        );
        break;
      case "multiline":
        maxLines = 4;
        inputType = TextInputType.multiline;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label != "") Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: RichText(
            text: TextSpan(
              text: widget.label,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              children: widget.isRequired
                  ? const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))]
                  : [],
            ),
          ),
        ),

        // TextField
        TextField(
          controller: _controller,
          keyboardType: inputType,
          readOnly: widget.fieldType == "date" || widget.isReadOnly,
          obscureText: widget.isPassword && !_isPasswordVisible,
          maxLines: maxLines,
          onTap: () {
            if (widget.fieldType == "date") {
              _openDatePicker();
            }
            widget.onTap?.call();
          },
          onChanged: (val) {
            _validateField(); // Validate on every change
            widget.onChanged?.call(val);
          },
          onSubmitted: (val) {
            _validateField(); // Final validation when submitted
            widget.onSubmitted?.call(val);
          },
          style: const TextStyle(fontSize: 14, color: Colors.black),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(color: Color(0xFF6B7280)),
            filled: true,
            fillColor: widget.isReadOnly ? const Color(0xFFF3F4F6) : Colors.white,
            isDense: widget.isCompact,
            contentPadding: widget.isCompact
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 13)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: hasError ? _border(color: Colors.red) : _border(),
            focusedBorder: hasError ? _border(color: Colors.red) : _border(),
            focusedErrorBorder: _border(color: Colors.red),
            errorBorder: _border(color: Colors.red),
            border: _border(),

            /// Password toggle & ✔️ check
            suffixIcon: widget.isPassword
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✔️ Password correct
                if (widget.correctPassword != null &&
                    _controller.text == widget.correctPassword)
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 20),
                // 👁 Show/Hide toggle
                IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ],
            )
                : null,
          ),
        ),

        // Error Text
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              _errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// class CustomTextField extends StatefulWidget {
//   final String label;
//   final String hintText;
//   final bool isRequired;
//   final String fieldType; // "text", "phone", "email", "date", "multiline", "password"
//   final bool isReadOnly;
//   final bool isCompact;
//   final TextEditingController? controller;
//   final ValueChanged<String>? onChanged;
//   final ValueChanged<String>? onSubmitted;
//   final VoidCallback? onTap;
//
//   /// NEW: for password
//   final bool isPassword;
//   final String? correctPassword; // optional -> show ✔️ if matches
//
//   const CustomTextField({
//     super.key,
//     required this.label,
//     required this.hintText,
//     this.isRequired = false,
//     this.fieldType = "text",
//     this.isReadOnly = false,
//     this.isCompact = false,
//     this.controller,
//     this.onChanged,
//     this.onSubmitted,
//     this.onTap,
//     this.isPassword = false,
//     this.correctPassword,
//   });
//
//   @override
//   State<CustomTextField> createState() => _CustomTextFieldState();
// }
//
// class _CustomTextFieldState extends State<CustomTextField> {
//   late TextEditingController _controller;
//   String? _errorText;
//   bool _isPasswordVisible = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = widget.controller ?? TextEditingController();
//     // Add listener to validate on text change
//     _controller.addListener(_validateField);
//   }
//
//   @override
//   void dispose() {
//     _controller.removeListener(_validateField);
//     // Only dispose if we created the controller internally
//     if (widget.controller == null) {
//       _controller.dispose();
//     }
//     super.dispose();
//   }
//
//   void _validateField() {
//     final text = _controller.text.trim();
//     String? error;
//
//     if (widget.isRequired && text.isEmpty) {
//       error = 'This field is required';
//     } else if (text.isNotEmpty) {
//       switch (widget.fieldType) {
//         case "phone":
//           error = _validatePhone(text);
//           break;
//         case "email":
//           error = _validateEmail(text);
//           break;
//       }
//     }
//
//     if (_errorText != error) {
//       setState(() {
//         _errorText = error;
//       });
//     }
//   }
//
//   String? _validatePhone(String phone) {
//     // Remove any non-digit characters
//     final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
//
//     // Check if it's exactly 10 digits
//     if (cleanPhone.length != 10) {
//       return 'Please enter a valid 10-digit mobile number';
//     }
//
//     // Optional: Check if it starts with valid digits (6-9 as per Indian numbering)
//     if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone)) {
//       return 'Please enter a valid mobile number';
//     }
//
//     return null;
//   }
//
//   String? _validateEmail(String email) {
//     final emailRegex = RegExp(
//         r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
//     );
//
//     if (!emailRegex.hasMatch(email)) {
//       return 'Please enter a valid email address';
//     }
//
//     return null;
//   }
//
//   OutlineInputBorder _border({Color color = const Color(0xFFD1D5DB)}) {
//     return OutlineInputBorder(
//       borderSide: BorderSide(color: color, width: 1.4),
//       borderRadius: BorderRadius.circular(6),
//     );
//   }
//
//   void _openDatePicker() async {
//     DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(1900),
//       lastDate: DateTime(2100),
//     );
//     if (pickedDate != null) {
//       String formatted = DateFormat('dd-MM-yyyy').format(pickedDate);
//       _controller.text = formatted;
//       widget.onChanged?.call(formatted);
//       _validateField(); // Validate after setting date
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final bool hasError = _errorText != null && _errorText!.isNotEmpty;
//
//     TextInputType inputType = TextInputType.text;
//     int maxLines = 1;
//
//     // Configure keyboard type and max lines based on field type
//     switch (widget.fieldType) {
//       case "phone":
//         inputType = TextInputType.phone;
//         break;
//       case "email":
//         inputType = TextInputType.emailAddress;
//         break;
//       case "multiline":
//         maxLines = 4;
//         inputType = TextInputType.multiline;
//         break;
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Label
//         if (widget.label != "") Padding(
//           padding: const EdgeInsets.only(bottom: 6.0),
//           child: RichText(
//             text: TextSpan(
//               text: widget.label,
//               style: const TextStyle(
//                 color: Color(0xFF374151),
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//               ),
//               children: widget.isRequired
//                   ? const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))]
//                   : [],
//             ),
//           ),
//         ),
//
//         // TextField
//         TextField(
//           controller: _controller,
//           keyboardType: inputType,
//           readOnly: widget.fieldType == "date" || widget.isReadOnly,
//           obscureText: widget.isPassword && !_isPasswordVisible,
//           maxLines: maxLines,
//           onTap: () {
//             if (widget.fieldType == "date") {
//               _openDatePicker();
//             }
//             widget.onTap?.call();
//           },
//           onChanged: (val) {
//             _validateField(); // Validate on every change
//             widget.onChanged?.call(val);
//           },
//           onSubmitted: (val) {
//             _validateField(); // Final validation when submitted
//             widget.onSubmitted?.call(val);
//           },
//           style: const TextStyle(fontSize: 14, color: Colors.black),
//           decoration: InputDecoration(
//             hintText: widget.hintText,
//             hintStyle: const TextStyle(color: Color(0xFF6B7280)),
//             filled: true,
//             fillColor: widget.isReadOnly ? const Color(0xFFF3F4F6) : Colors.white,
//             isDense: widget.isCompact,
//             contentPadding: widget.isCompact
//                 ? const EdgeInsets.symmetric(horizontal: 14, vertical: 13)
//                 : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//             enabledBorder: hasError ? _border(color: Colors.red) : _border(),
//             focusedBorder: hasError ? _border(color: Colors.red) : _border(),
//             focusedErrorBorder: _border(color: Colors.red),
//             errorBorder: _border(color: Colors.red),
//             border: _border(),
//
//             /// Password toggle & ✔️ check
//             suffixIcon: widget.isPassword
//                 ? Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // ✔️ Password correct
//                 if (widget.correctPassword != null &&
//                     _controller.text == widget.correctPassword)
//                   const Icon(Icons.check_circle,
//                       color: Colors.green, size: 20),
//                 // 👁 Show/Hide toggle
//                 IconButton(
//                   icon: Icon(
//                     _isPasswordVisible
//                         ? Icons.visibility
//                         : Icons.visibility_off,
//                     color: Colors.grey,
//                     size: 20,
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       _isPasswordVisible = !_isPasswordVisible;
//                     });
//                   },
//                 ),
//               ],
//             )
//                 : null,
//           ),
//         ),
//
//         // Error Text
//         if (hasError)
//           Padding(
//             padding: const EdgeInsets.only(top: 4, left: 4),
//             child: Text(
//               _errorText!,
//               style: const TextStyle(color: Colors.red, fontSize: 12),
//             ),
//           ),
//       ],
//     );
//   }
// }

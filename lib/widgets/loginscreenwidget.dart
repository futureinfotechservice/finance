import 'package:flutter/material.dart';

class CustomInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isPassword;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool readOnly;
  final ValueChanged<String>? onSubmitted;
  final IconData? prefixIcon;
  final bool enabled;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.onTap,
    this.textInputAction,
    this.focusNode,
    this.readOnly = false,
    this.onSubmitted,
    this.prefixIcon,
    this.enabled = true,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      readOnly: widget.readOnly,
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      onSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
      cursorColor: Colors.blueAccent,
      cursorWidth: 2.5,         // <- Width of the cursor
      cursorHeight: 20,         // <- Height of the cursor (adjust based on font size)
      cursorRadius: Radius.circular(4),
      style: TextStyle(
          fontSize: 16,
          color: theme.textTheme.bodyMedium?.color
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        hintText: widget.hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, color: Colors.grey.shade600) : null,
        suffixIcon: widget.isPassword
            ? IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade600,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        filled: true,
        fillColor: widget.enabled ? Colors.white : Colors.grey.shade100,
      ),
    );
  }
}

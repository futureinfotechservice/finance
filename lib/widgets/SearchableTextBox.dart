import 'dart:async';

import 'package:flutter/material.dart';

class SearchableTextBox extends StatefulWidget {
  final String label;
  final bool isRequired;
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String?>? onChanged;
  final VoidCallback? onAutoSubmit;
  final bool isCompact;
  final bool isReadOnly;
  final Duration submitDelay;
  final InputDecoration? decoration;
  final bool showDropdownIcon;

  const SearchableTextBox({
    super.key,
    required this.label,
    this.isRequired = false,
    required this.items,
    this.selectedItem,
    required this.onChanged,
    this.onAutoSubmit,
    this.isCompact = false,
    this.isReadOnly = false,
    this.submitDelay = const Duration(milliseconds: 300),
    this.decoration,
    this.showDropdownIcon = true,
  });

  @override
  State<SearchableTextBox> createState() => _SearchableTextBoxState();
}

class _SearchableTextBoxState extends State<SearchableTextBox> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<String> _filteredItems = [];
  Timer? _submitTimer;
  Timer? _searchTimer;

  // New variables for scan detection
  String _previousText = '';
  DateTime _lastInputTime = DateTime.now();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.selectedItem ?? '';
    _filteredItems = widget.items;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(SearchableTextBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedItem != oldWidget.selectedItem) {
      _controller.text = widget.selectedItem ?? '';
    }
    if (widget.items != oldWidget.items) {
      _filteredItems = widget.items;
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 48),
          child: Material(
            elevation: 4,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 200,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    color: Colors.black26,
                  ),
                ],
              ),
              child: _filteredItems.isEmpty
                  ? Padding(
                padding: EdgeInsets.all(16),
                child: Text('No items found'),
              )
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return ListTile(
                    title: Text(item),
                    onTap: () {
                      _selectItem(item);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) =>
            item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });

    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _selectItem(String item) {
    _controller.text = item;
    _hideOverlay();
    _focusNode.unfocus();

    widget.onChanged?.call(item);
    _triggerAutoSubmit();
  }

  void _triggerAutoSubmit() {
    // Cancel any existing timer
    _submitTimer?.cancel();

    // Start new timer for auto-submit
    _submitTimer = Timer(widget.submitDelay, () {
      if (widget.onAutoSubmit != null && _controller.text.isNotEmpty) {
        widget.onAutoSubmit!();
      }
    });
  }

  void _detectScan(String currentText) {
    final now = DateTime.now();
    final timeDiff = now.difference(_lastInputTime).inMilliseconds;

    // Detect rapid input (typical of barcode scanners)
    if (currentText.length > _previousText.length) {
      final newChars = currentText.length - _previousText.length;

      // If multiple characters are added rapidly, it's likely a scan
      if (newChars > 1 && timeDiff < 100) {
        _isScanning = true;
        print('Scan detected: $currentText');
        _triggerAutoSubmit();
      }
      // If single characters are added very rapidly (faster than human typing)
      else if (newChars == 1 && timeDiff < 50) {
        _isScanning = true;
        // Wait a bit to see if more characters come
        _submitTimer?.cancel();
        _submitTimer = Timer(Duration(milliseconds: 200), () {
          if (_isScanning) {
            print('Rapid input detected: $currentText');
            _triggerAutoSubmit();
          }
        });
      }
    }

    _previousText = currentText;
    _lastInputTime = now;
  }

  void _onTextChanged(String text) {
    // Cancel previous search timer
    _searchTimer?.cancel();

    // Start new search timer
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      _filterItems(text);
    });

    widget.onChanged?.call(text);

    // Detect scanning patterns
    _detectScan(text);

    // Additional auto-submit triggers
    if (_shouldAutoSubmit(text)) {
      _triggerAutoSubmit();
    }
  }

  bool _shouldAutoSubmit(String text) {
    // Auto-submit for common barcode patterns
    if (text.length >= 8 && text.length <= 20) {
      // Common barcode lengths
      return true;
    }

    // Auto-submit if text matches specific patterns (numbers, uppercase, etc.)
    if (_isLikelyBarcode(text)) {
      return true;
    }

    // Auto-submit on Enter key equivalent (scanners often send Enter)
    // This is handled in onFieldSubmitted

    return false;
  }

  bool _isLikelyBarcode(String text) {
    // Check if text looks like a barcode (mostly numbers, specific formats)
    if (text.isEmpty) return false;

    // Common barcode patterns
    final numericRegex = RegExp(r'^\d+$');
    final alphanumericRegex = RegExp(r'^[A-Z0-9]+$');

    return numericRegex.hasMatch(text) ||
        alphanumericRegex.hasMatch(text) ||
        text.contains('-') || // UPC with dashes
        text.length >= 10; // Long strings are likely scans
  }

  void _onFieldSubmitted(String value) {
    _hideOverlay();
    // Immediate submit on field submitted (when scanner sends Enter)
    _submitTimer?.cancel();
    if (widget.onAutoSubmit != null && value.isNotEmpty) {
      widget.onAutoSubmit!();
    }
  }

  void _onTap() {
    if (!widget.isReadOnly) {
      // Clear the field when tapped (convenient for multiple scans)
      if (_controller.text.isNotEmpty) {
        _controller.clear();
        widget.onChanged?.call('');
      }
      _showOverlay();
    }
  }

  @override
  void dispose() {
    _submitTimer?.cancel();
    _searchTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder _border({Color color = const Color(0xFFD1D5DB)}) {
      return OutlineInputBorder(
        borderSide: BorderSide(color: color, width: 1.4),
        borderRadius: BorderRadius.circular(6),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: !widget.isReadOnly,
            decoration: (widget.decoration ?? InputDecoration()).copyWith(
              filled: true,
              fillColor:
              widget.isReadOnly ? const Color(0xFFF3F4F6) : const Color(0xFFF3F4F6),
              border: _border(),
              enabledBorder: _border(),
              focusedBorder: _border(),
              disabledBorder: _border(color: const Color(0xFFD1D5DB)),
              isDense: widget.isCompact,
              contentPadding: widget.isCompact
                  ? const EdgeInsets.symmetric(horizontal: 14, vertical: 13)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              hintText: 'Scan or type product code...',
              hintStyle: TextStyle(
                color: widget.isReadOnly
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF6B7280),
              ),
              suffixIcon: widget.showDropdownIcon
                  ? Icon(
                Icons.arrow_drop_down,
                color: widget.isReadOnly
                    ? const Color(0xFF111827)
                    : const Color(0xFF374151),
              )
                  : null,
            ),
            // onChanged: _onTextChanged,
            // onFieldSubmitted: _onFieldSubmitted,
            // onTap: _onTap,
            // // Select all text when focused (convenient for scanning)
            // onTapOutside: (event) {
            //   _focusNode.unfocus();
            // },
          ),
        ),
      ],
    );
  }
}
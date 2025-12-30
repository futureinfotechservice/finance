// cash_ledger_report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/collection_apiservice.dart';

class CashLedgerReportScreen extends StatefulWidget {
  const CashLedgerReportScreen({super.key});

  @override
  State<CashLedgerReportScreen> createState() => _CashLedgerReportScreenState();
}

class _CashLedgerReportScreenState extends State<CashLedgerReportScreen> {
  final collectionapiservice _apiService = collectionapiservice();
  bool _isLoading = true;
  bool _loadingLedgers = false;
  DateTime? _fromDate;
  DateTime? _toDate;

  // Ledger dropdown
  List<Map<String, dynamic>> _ledgers = [];
  String? _selectedLedgerId;
  String? _selectedLedgerName;

  List<CashLedgerEntry> _entries = [];

  // Summary
  double _openingBalance = 0;
  double _closingBalance = 0;
  double _totalDebit = 0;
  double _totalCredit = 0;
  int _totalEntries = 0;
  String _currentLedgerName = '';

  @override
  void initState() {
    super.initState();
    _loadLedgers();
  }

  Future<void> _loadLedgers() async {
    if (!mounted) return;

    setState(() {
      _loadingLedgers = true;
    });

    try {
      final ledgers = await _apiService.fetchAllLedgers(context);

      if (mounted) {
        setState(() {
          _ledgers = ledgers;
          // Auto-select Cash ledger if available
          final cashLedger = ledgers.firstWhere(
                (ledger) => ledger['ledgerName'] == 'Cash',
            orElse: () => <String, dynamic>{},
          );

          if (cashLedger.isNotEmpty) {
            _selectedLedgerId = cashLedger['id']?.toString();
            _selectedLedgerName = cashLedger['ledgerName']?.toString();
          } else if (ledgers.isNotEmpty) {
            _selectedLedgerId = ledgers[0]['id']?.toString();
            _selectedLedgerName = ledgers[0]['ledgerName']?.toString();
          }
        });

        // Load report after selecting default ledger
        if (_selectedLedgerId != null) {
          _loadCashLedgerReport();
        }
      }
    } catch (e) {
      print("Error loading ledgers: $e");
      if (mounted) {
        setState(() {
          _loadingLedgers = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCashLedgerReport() async {
    if (!mounted) return;

    // Don't load if no ledger is selected
    if (_selectedLedgerId == null) {
      setState(() {
        _isLoading = false;
        _entries = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Format dates for API
      String? formattedFromDate;
      String? formattedToDate;

      if (_fromDate != null) {
        formattedFromDate = DateFormat('yyyy-MM-dd').format(_fromDate!);
      }
      if (_toDate != null) {
        formattedToDate = DateFormat('yyyy-MM-dd').format(_toDate!);
      }

      final response = await _apiService.fetchCashLedgerReport(
        context: context,
        fromDate: formattedFromDate,
        toDate: formattedToDate,
        ledgerId: _selectedLedgerId,
      );

      if (mounted && response['status'] == 'success') {
        List<dynamic> items = response['entries'];
        Map<String, dynamic> summaryData = response['summary'];

        List<CashLedgerEntry> entries = items.map((item) {
          return CashLedgerEntry(
            id: item['id']?.toString() ?? '',
            date: item['date']?.toString() ?? '',
            description: item['description']?.toString() ?? '',
            debit: double.tryParse(item['debit']?.toString() ?? '0') ?? 0,
            credit: double.tryParse(item['credit']?.toString() ?? '0') ?? 0,
            balance: double.tryParse(item['balance']?.toString() ?? '0') ?? 0,
            type: item['type']?.toString() ?? '',
            counterpartyName: item['counterparty_name']?.toString() ?? '',
            counterpartyId: item['counterparty_id']?.toString() ?? '',
          );
        }).toList();

        setState(() {
          _entries = entries;
          _currentLedgerName = summaryData['ledgerName']?.toString() ?? '';
          _openingBalance = double.tryParse(summaryData['openingBalance']?.toString() ?? '0') ?? 0;
          _closingBalance = double.tryParse(summaryData['closingBalance']?.toString() ?? '0') ?? 0;
          _totalDebit = double.tryParse(summaryData['totalDebit']?.toString() ?? '0') ?? 0;
          _totalCredit = double.tryParse(summaryData['totalCredit']?.toString() ?? '0') ?? 0;
          _totalEntries = int.tryParse(summaryData['totalEntries']?.toString() ?? '0') ?? 0;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${response['message'] ?? 'Unknown error'}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading cash ledger report: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _loadCashLedgerReport();
  }

  void _exportReport() {
    print('Exporting cash ledger report...');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exporting report...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _printReport() {
    print('Printing cash ledger report...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Printing report...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _fromDate) {
      setState(() {
        _fromDate = picked;
      });
      _loadCashLedgerReport();
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _toDate) {
      setState(() {
        _toDate = picked;
      });
      _loadCashLedgerReport();
    }
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      height: 132,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _currentLedgerName.isNotEmpty
                ? '$_currentLedgerName Ledger Report'
                : 'Cash Ledger Report',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.33,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comprehensive overview of all transactions and account balances',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w400,
              height: 1.56,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // Ledger Name Label
          const Text(
            'Ledger Name:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),

          const SizedBox(width: 16),

          // Ledger Dropdown - FIXED VERSION
          Container(
            width: 250,
            height: 38,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _loadingLedgers
                ? const Center(child: CircularProgressIndicator())
                : _ledgers.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'No ledgers found',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            )
                : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLedgerId,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF374151)),
                iconSize: 24,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF374151),
                ),
                hint: const Text(
                  'Select Ledger...',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF999999),
                  ),
                ),
                items: _ledgers.map<DropdownMenuItem<String>>((ledger) {
                  return DropdownMenuItem<String>(
                    value: ledger['id']?.toString(),
                    child: Text(ledger['ledgerName']?.toString() ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    // Find the selected ledger
                    Map<String, dynamic> selectedLedger;
                    try {
                      selectedLedger = _ledgers.firstWhere(
                            (ledger) => ledger['id']?.toString() == newValue,
                      );
                    } catch (e) {
                      selectedLedger = {};
                    }

                    // Update state with new selection
                    setState(() {
                      _selectedLedgerId = newValue;
                      _selectedLedgerName = selectedLedger.isNotEmpty
                          ? selectedLedger['ledgerName']?.toString()
                          : 'Unknown';
                    });

                    // Load report with new ledger
                    _loadCashLedgerReport();
                  }
                },
              ),
            ),
          ),

          const SizedBox(width: 16),

          // From Date Label
          const Text(
            'From Date:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),

          const SizedBox(width: 16),

          // From Date Picker
          Container(
            width: 152,
            height: 38,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => _selectFromDate(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: Color(0xFF374151)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fromDate != null
                          ? DateFormat('dd/MM/yyyy').format(_fromDate!)
                          : 'Select date...',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // To Date Label
          const Text(
            'To Date:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),

          const SizedBox(width: 16),

          // To Date Picker
          Container(
            width: 152,
            height: 38,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => _selectToDate(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: Color(0xFF374151)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _toDate != null
                          ? DateFormat('dd/MM/yyyy').format(_toDate!)
                          : 'Select date...',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Clear Filters Button (if any filter is active)
          if (_fromDate != null || _toDate != null)
            Container(
              width: 120,
              height: 38,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD1D5DB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: _clearFilters,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.clear_all, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Clear Filters',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_fromDate != null || _toDate != null) const SizedBox(width: 16),

          // Export Button
          Container(
            width: 139,
            height: 38,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: _exportReport,
              child: const Text(
                'Export Selected',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Print Report Button
          Container(
            width: 111,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: _printReport,
              child: const Text(
                'Print Report',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 53,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
      ),
      child: Row(
        children: [
          // S.No
          SizedBox(
            width: 80,
            child: Text(
              'S.No',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Date
          SizedBox(
            width: 120,
            child: Text(
              'Date',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Description
          Expanded(
            flex: 3,
            child: Text(
              'Description',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Debit
          SizedBox(
            width: 120,
            child: Text(
              'Debit',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Credit
          SizedBox(
            width: 120,
            child: Text(
              'Credit',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Balance
          SizedBox(
            width: 150,
            child: Text(
              'Balance',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(CashLedgerEntry entry, int index) {
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final formatDate = DateFormat('dd/MM/yyyy');

    final isOpening = entry.type == 'Opening';
    final isClosing = entry.type == 'Closing';
    final isSpecialRow = isOpening || isClosing;

    // Calculate transaction number (excluding opening/closing)
    int transactionNo = 0;
    if (!isOpening && !isClosing) {
      // Count how many non-special entries before this one
      transactionNo = _entries
          .sublist(0, index)
          .where((e) => e.type != 'Opening' && e.type != 'Closing')
          .length;
    }

    return Container(
      height: 57,
      decoration: BoxDecoration(
        color: isSpecialRow
            ? const Color(0xFFF9FAFB)
            : index % 2 == 0 ? Colors.white : const Color(0xFFF9FAFB),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // S.No
          SizedBox(
            width: 80,
            child: Text(
              isOpening ? '' : isClosing ? '' : '${transactionNo + 1}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: isSpecialRow ? FontWeight.w400 : FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
          ),

          // Date
          SizedBox(
            width: 120,
            child: Text(
              entry.date.isNotEmpty && !isSpecialRow
                  ? formatDate.format(DateTime.parse(entry.date))
                  : '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: isSpecialRow ? FontWeight.w400 : FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
          ),

          // Description
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                entry.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: isSpecialRow ? FontWeight.w400 : FontWeight.w500,
                  color: const Color(0xFF374151),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Debit
          SizedBox(
            width: 120,
            child: Text(
              entry.debit > 0 ? formatCurrency.format(entry.debit) : '-',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: isSpecialRow ? FontWeight.w400 : FontWeight.w500,
                color: entry.debit > 0 ? const Color(0xFFDC2626) : const Color(0xFF374151),
              ),
            ),
          ),

          // Credit
          SizedBox(
            width: 120,
            child: Text(
              entry.credit > 0 ? formatCurrency.format(entry.credit) : '-',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: isSpecialRow ? FontWeight.w400 : FontWeight.w500,
                color: entry.credit > 0 ? const Color(0xFF16A34A) : const Color(0xFF374151),
              ),
            ),
          ),

          // Balance
          SizedBox(
            width: 150,
            child: Text(
              formatCurrency.format(entry.balance),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: isSpecialRow ? FontWeight.w600 : FontWeight.w500,
                color: entry.balance < 0 ? const Color(0xFFDC2626) : const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Showing 1 to $_totalEntries of $_totalEntries entries',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Summary Cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Opening Balance Card
              Container(
                width: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Opening Balance',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatCurrency.format(_openingBalance),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _openingBalance < 0 ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),

              // Total Debit Card
              Container(
                width: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total Debit',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatCurrency.format(_totalDebit),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),

              // Total Credit Card
              Container(
                width: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total Credit',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF166534),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatCurrency.format(_totalCredit),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),

              // Closing Balance Card
              Container(
                width: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Closing Balance',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatCurrency.format(_closingBalance),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _closingBalance < 0 ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger Report'),
        actions: [
          IconButton(
            onPressed: _loadCashLedgerReport,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(),

            const SizedBox(height: 29),

            // Filters Section
            _buildFiltersSection(),

            const SizedBox(height: 22),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_selectedLedgerId == null)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.account_balance_wallet, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Please select a ledger to view transactions',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else if (_entries.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.account_balance_wallet, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        _selectedLedgerName != null
                            ? 'No transactions found for $_selectedLedgerName'
                            : 'No transactions found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                  // Table Container
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        _buildTableHeader(),

                        // Data Rows
                        ...List.generate(
                          _entries.length,
                              (index) => _buildDataRow(_entries[index], index),
                        ),
                      ],
                    ),
                  ),

                  // Totals and Summary Section
                  _buildTotalsSection(),
                ],
          ],
        ),
      ),
    );
  }
}

// Model for cash ledger entries
class CashLedgerEntry {
  final String id;
  final String date;
  final String description;
  final double debit;
  final double credit;
  final double balance;
  final String type;
  final String counterpartyName;
  final String counterpartyId;

  CashLedgerEntry({
    required this.id,
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.type,
    required this.counterpartyName,
    required this.counterpartyId,
  });
}
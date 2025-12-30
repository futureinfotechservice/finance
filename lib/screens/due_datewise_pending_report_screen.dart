// due_date_pending_report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/collection_apiservice.dart';

class DueDatePendingReportScreen extends StatefulWidget {
  const DueDatePendingReportScreen({super.key});

  @override
  State<DueDatePendingReportScreen> createState() => _DueDatePendingReportScreenState();
}

class _DueDatePendingReportScreenState extends State<DueDatePendingReportScreen> {
  final collectionapiservice _apiService = collectionapiservice();
  bool _isLoading = true;
  DateTime? _selectedDueDate;
  String _searchQuery = '';

  // Pagination variables
  int _currentPage = 1;
  int _totalPages = 1;
  int _perPage = 10;
  int _totalItems = 0;

  List<DueDatePendingItem> _allPendingItems = [];
  List<DueDatePendingItem> _currentPageItems = [];

  // Summary statistics
  double _totalDueAmount = 0;
  double _totalLoanBalance = 0;
  double _totalPenaltyBalance = 0;
  double _totalBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadDueDatePendingReport();
  }

  Future<void> _loadDueDatePendingReport() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Format date for API if selected
      String? formattedDate;
      if (_selectedDueDate != null) {
        formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDueDate!);
      }

      final response = await _apiService.fetchDueDatePendingReport(
        context: context,
        dueDate: formattedDate,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted && response['status'] == 'success') {
        List<dynamic> items = response['items'];
        Map<String, dynamic> summaryData = response['summary'];

        List<DueDatePendingItem> allPendingItems = items.map((item) {
          return DueDatePendingItem(
            id: item['id'].toString(),
            loanId: item['loanId'].toString(),
            loanNo: item['loanNo']?.toString() ?? '',
            customerName: item['customerName']?.toString() ?? '',
            mobile: item['mobile']?.toString() ?? '',
            dueNo: int.parse(item['dueNo']?.toString() ?? '0'),
            dueDate: item['dueDate']?.toString() ?? '',
            dueAmount: double.parse(item['dueAmount']?.toString() ?? '0'),
            loanAmount: double.parse(item['loanAmount']?.toString() ?? '0'),
            noOfWeeks: int.parse(item['noOfWeeks']?.toString() ?? '0'),
            penaltyAmount: double.parse(item['penaltyAmount']?.toString() ?? '0'),
            totalCollected: double.parse(item['totalCollected']?.toString() ?? '0'),
            totalPenaltyCollected: double.parse(item['totalPenaltyCollected']?.toString() ?? '0'),
            loanBalance: double.parse(item['loanBalance']?.toString() ?? '0'),
            penaltyBalance: double.parse(item['penaltyBalance']?.toString() ?? '0'),
            totalBalance: double.parse(item['totalBalance']?.toString() ?? '0'),
            status: item['status']?.toString() ?? 'Pending',
          );
        }).toList();

        // Calculate pagination
        _totalItems = allPendingItems.length;
        _totalPages = (_totalItems / _perPage).ceil();
        if (_totalPages == 0) _totalPages = 1;

        // Update current page if it exceeds total pages
        if (_currentPage > _totalPages) {
          _currentPage = _totalPages;
        }

        // Get items for current page
        final startIndex = (_currentPage - 1) * _perPage;
        final endIndex = startIndex + _perPage < _totalItems ? startIndex + _perPage : _totalItems;

        List<DueDatePendingItem> currentPageItems = startIndex < _totalItems
            ? allPendingItems.sublist(startIndex, endIndex)
            : [];

        // Calculate totals for current page
        double pageTotalDue = 0;
        double pageTotalLoanBal = 0;
        double pageTotalPenaltyBal = 0;
        double pageTotalBal = 0;

        for (var item in currentPageItems) {
          pageTotalDue += item.dueAmount;
          pageTotalLoanBal += item.loanBalance;
          pageTotalPenaltyBal += item.penaltyBalance;
          pageTotalBal += item.totalBalance;
        }

        setState(() {
          _allPendingItems = allPendingItems;
          _currentPageItems = currentPageItems;
          _totalDueAmount = pageTotalDue;
          _totalLoanBalance = pageTotalLoanBal;
          _totalPenaltyBalance = pageTotalPenaltyBal;
          _totalBalance = pageTotalBal;
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
            content: Text("Error loading due date pending report: $e"),
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
      _selectedDueDate = null;
      _searchQuery = '';
      _currentPage = 1;
    });
    _loadDueDatePendingReport();
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;

    setState(() {
      _currentPage = page;
    });

    // Get items for the new page
    final startIndex = (_currentPage - 1) * _perPage;
    final endIndex = startIndex + _perPage < _totalItems ? startIndex + _perPage : _totalItems;

    List<DueDatePendingItem> currentPageItems = startIndex < _totalItems
        ? _allPendingItems.sublist(startIndex, endIndex)
        : [];

    // Calculate totals for current page
    double pageTotalDue = 0;
    double pageTotalLoanBal = 0;
    double pageTotalPenaltyBal = 0;
    double pageTotalBal = 0;

    for (var item in currentPageItems) {
      pageTotalDue += item.dueAmount;
      pageTotalLoanBal += item.loanBalance;
      pageTotalPenaltyBal += item.penaltyBalance;
      pageTotalBal += item.totalBalance;
    }

    setState(() {
      _currentPageItems = currentPageItems;
      _totalDueAmount = pageTotalDue;
      _totalLoanBalance = pageTotalLoanBal;
      _totalPenaltyBalance = pageTotalPenaltyBal;
      _totalBalance = pageTotalBal;
    });
  }

  void _navigateToCollection(int index) {
    final item = _currentPageItems[index];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to collection for ${item.loanNo}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportSelected() {
    print('Exporting ${_allPendingItems.length} items');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting ${_allPendingItems.length} items...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _printReport() {
    print('Printing due date pending report...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Printing report...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
        _currentPage = 1;
      });
      _loadDueDatePendingReport();
    }
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      height: 113,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Due Date-wise Pending Report',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.33,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Comprehensive overview of penalty amounts by due date',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w400,
              height: 1.17,
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
          // Due Date Label
          Text(
            'Select Due Date:',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),

          const SizedBox(width: 16),

          // Date Picker Button with Clear option
          Container(
            width: 220,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _selectDueDate(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20, color: Color(0xFF374151)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedDueDate != null
                                ? DateFormat('dd/MM/yyyy').format(_selectedDueDate!)
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
                if (_selectedDueDate != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDueDate = null;
                        _currentPage = 1;
                      });
                      _loadDueDatePendingReport();
                    },
                    icon: const Icon(Icons.clear, size: 18),
                    padding: const EdgeInsets.all(4),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Search Field
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD1D5DB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by customer name or loan number...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  prefixIcon: const Icon(Icons.search, size: 20),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 1;
                  });
                  _loadDueDatePendingReport();
                },
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Clear Filters Button
          if (_selectedDueDate != null || _searchQuery.isNotEmpty)
            Container(
              width: 120,
              height: 40,
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

          if (_selectedDueDate != null || _searchQuery.isNotEmpty) const SizedBox(width: 16),

          // Export Selected Button
          Container(
            width: 139,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: _exportSelected,
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
            width: 127,
            height: 40,
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
    // Column widths for proper horizontal scrolling
    const columnWidths = {
      'sno': 80.0,
      'loanNo': 120.0,
      'name': 200.0,
      'mobile': 120.0,
      'dueNo': 100.0,
      'dueDate': 120.0,
      'loanAmount': 120.0,
      'weeks': 100.0,
      'dueAmount': 120.0,
      'loanBalance': 140.0,
      'penaltyBalance': 140.0,
      'totalBalance': 140.0,
      'status': 120.0,
    };

    final totalWidth = columnWidths.values.reduce((a, b) => a + b);

    return SizedBox(
      height: 68,
      child: Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
              ),
              child: Row(
                children: [
                  // S.No
                  SizedBox(
                    width: columnWidths['sno'],
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

                  // Loan No
                  SizedBox(
                    width: columnWidths['loanNo'],
                    child: Text(
                      'Loan No',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),

                  // Name
                  SizedBox(
                    width: columnWidths['name'],
                    child: Text(
                      'Customer Name',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),

                  // Mobile
                  SizedBox(
                    width: columnWidths['mobile'],
                    child: Text(
                      'Mobile',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),

                  // Due No
                  SizedBox(
                    width: columnWidths['dueNo'],
                    child: Text(
                      'Due No',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),

                  // Due Date
                  SizedBox(
                    width: columnWidths['dueDate'],
                    child: Text(
                      'Due Date',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),

                  // Loan Amount
                  SizedBox(
                    width: columnWidths['loanAmount'],
                    child: Text(
                      'Loan Amount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),

                  // No. of Weeks
                  SizedBox(
                    width: columnWidths['weeks'],
                    child: Text(
                      'Weeks',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),

                  // Due Amount
                  SizedBox(
                    width: columnWidths['dueAmount'],
                    child: Text(
                      'Due Amount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),

                  // Loan Balance
                  SizedBox(
                    width: columnWidths['loanBalance'],
                    child: Text(
                      'Loan Balance',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),

                  // Penalty Balance
                  SizedBox(
                    width: columnWidths['penaltyBalance'],
                    child: Text(
                      'Penalty Balance',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),

                  // Total Balance
                  SizedBox(
                    width: columnWidths['totalBalance'],
                    child: Text(
                      'Total Balance',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),

                  // Status
                  SizedBox(
                    width: columnWidths['status'],
                    child: Text(
                      'Status',
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(DueDatePendingItem item, int index) {
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final formatDate = DateFormat('dd/MM/yyyy');

    // Calculate actual row index (considering pagination)
    final actualIndex = ((_currentPage - 1) * _perPage) + index + 1;

    // Column widths (must match header)
    const columnWidths = {
      'sno': 80.0,
      'loanNo': 120.0,
      'name': 200.0,
      'mobile': 120.0,
      'dueNo': 100.0,
      'dueDate': 120.0,
      'loanAmount': 120.0,
      'weeks': 100.0,
      'dueAmount': 120.0,
      'loanBalance': 140.0,
      'penaltyBalance': 140.0,
      'totalBalance': 140.0,
      'status': 120.0,
    };

    final totalWidth = columnWidths.values.reduce((a, b) => a + b);

    return InkWell(
      onTap: () => _navigateToCollection(index),
      child: SizedBox(
        height: 67,
        child: Scrollbar(
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                  color: index % 2 == 0 ? Colors.white : const Color(0xFFF9FAFB),
                ),
                child: Row(
                  children: [
                    // S.No
                    SizedBox(
                      width: columnWidths['sno'],
                      child: Text(
                        '$actualIndex',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),

                    // Loan No
                    SizedBox(
                      width: columnWidths['loanNo'],
                      child: Text(
                        item.loanNo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),

                    // Customer Name
                    SizedBox(
                      width: columnWidths['name'],
                      child: Text(
                        item.customerName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),

                    // Mobile
                    SizedBox(
                      width: columnWidths['mobile'],
                      child: Text(
                        item.mobile,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),

                    // Due No
                    SizedBox(
                      width: columnWidths['dueNo'],
                      child: Text(
                        '${item.dueNo}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),

                    // Due Date
                    SizedBox(
                      width: columnWidths['dueDate'],
                      child: Text(
                        item.dueDate.isNotEmpty
                            ? formatDate.format(DateTime.parse(item.dueDate))
                            : '-',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),

                    // Loan Amount
                    SizedBox(
                      width: columnWidths['loanAmount'],
                      child: Text(
                        formatCurrency.format(item.loanAmount),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),

                    // No. of Weeks
                    SizedBox(
                      width: columnWidths['weeks'],
                      child: Text(
                        '${item.noOfWeeks}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),

                    // Due Amount
                    SizedBox(
                      width: columnWidths['dueAmount'],
                      child: Text(
                        formatCurrency.format(item.dueAmount),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),

                    // Loan Balance
                    SizedBox(
                      width: columnWidths['loanBalance'],
                      child: Text(
                        formatCurrency.format(item.loanBalance),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: item.loanBalance > 0 ? const Color(0xFFDC2626) : const Color(0xFF374151),
                        ),
                      ),
                    ),

                    // Penalty Balance
                    SizedBox(
                      width: columnWidths['penaltyBalance'],
                      child: Text(
                        formatCurrency.format(item.penaltyBalance),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: item.penaltyBalance > 0 ? const Color(0xFFDC2626) : const Color(0xFF374151),
                        ),
                      ),
                    ),

                    // Total Balance
                    SizedBox(
                      width: columnWidths['totalBalance'],
                      child: Text(
                        formatCurrency.format(item.totalBalance),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: item.totalBalance > 0 ? const Color(0xFFDC2626) : const Color(0xFF374151),
                        ),
                      ),
                    ),

                    // Status
                    SizedBox(
                      width: columnWidths['status'],
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.status == 'Overdue' ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.status,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: item.status == 'Overdue' ? const Color(0xFF991B1B) : const Color(0xFF92400E),
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
      ),
    );
  }

  Widget _buildTotalsRow() {
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // Column widths (must match header)
    const columnWidths = {
      'sno': 80.0,
      'loanNo': 120.0,
      'name': 200.0,
      'mobile': 120.0,
      'dueNo': 100.0,
      'dueDate': 120.0,
      'loanAmount': 120.0,
      'weeks': 100.0,
      'dueAmount': 120.0,
      'loanBalance': 140.0,
      'penaltyBalance': 140.0,
      'totalBalance': 140.0,
      'status': 120.0,
    };

    final totalWidth = columnWidths.values.reduce((a, b) => a + b);

    return SizedBox(
      height: 60,
      child: Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
              ),
              child: Row(
                children: [
                  // TOTALS Label
                  SizedBox(
                    width: columnWidths['sno']! + columnWidths['loanNo']! + columnWidths['name']!,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 80.0),
                      child: Text(
                        'PAGE TOTALS (${_currentPageItems.length} items)',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Mobile column
                  SizedBox(width: columnWidths['mobile']),

                  // Due No column
                  SizedBox(width: columnWidths['dueNo']),

                  // Due Date column
                  SizedBox(width: columnWidths['dueDate']),

                  // Loan Amount column
                  SizedBox(width: columnWidths['loanAmount']),

                  // Weeks column
                  SizedBox(width: columnWidths['weeks']),

                  // Total Due Amount
                  // SizedBox(
                  //   width: columnWidths['dueAmount'],
                  //   child: Text(
                  //     formatCurrency.format(_totalDueAmount),
                  //     textAlign: TextAlign.right,
                  //     style: const TextStyle(
                  //       fontFamily: 'Inter',
                  //       fontSize: 14,
                  //       fontWeight: FontWeight.w600,
                  //       color: Colors.white,
                  //     ),
                  //   ),
                  // ),

                  // // Total Loan Balance
                  // SizedBox(
                  //   width: columnWidths['loanBalance'],
                  //   child: Text(
                  //     formatCurrency.format(_totalLoanBalance),
                  //     textAlign: TextAlign.right,
                  //     style: const TextStyle(
                  //       fontFamily: 'Inter',
                  //       fontSize: 14,
                  //       fontWeight: FontWeight.w600,
                  //       color: Colors.white,
                  //     ),
                  //   ),
                  // ),

                  // // Total Penalty Balance
                  // SizedBox(
                  //   width: columnWidths['penaltyBalance'],
                  //   child: Text(
                  //     formatCurrency.format(_totalPenaltyBalance),
                  //     textAlign: TextAlign.right,
                  //     style: const TextStyle(
                  //       fontFamily: 'Inter',
                  //       fontSize: 14,
                  //       fontWeight: FontWeight.w600,
                  //       color: Colors.white,
                  //     ),
                  //   ),
                  // ),

                  // // Total Balance
                  // SizedBox(
                  //   width: columnWidths['totalBalance'],
                  //   child: Text(
                  //     formatCurrency.format(_totalBalance),
                  //     textAlign: TextAlign.right,
                  //     style: const TextStyle(
                  //       fontFamily: 'Inter',
                  //       fontSize: 14,
                  //       fontWeight: FontWeight.w600,
                  //       color: Colors.white,
                  //     ),
                  //   ),
                  // ),

                  // Status column
                  SizedBox(width: columnWidths['status']),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    // Generate page buttons
    List<Widget> pageButtons = [];

    // Show first page
    pageButtons.add(
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _currentPage == 1 ? const Color(0xFF1E293B) : Colors.transparent,
          border: Border.all(color: const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: TextButton(
          onPressed: _currentPage == 1 ? null : () => _goToPage(1),
          child: Text(
            '1',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _currentPage == 1 ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );

    // Show ellipsis if needed
    if (_currentPage > 3) {
      pageButtons.add(const SizedBox(width: 4));
      pageButtons.add(
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: const Text(
            '...',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF374151),
            ),
          ),
        ),
      );
    }

    // Show pages around current page
    for (int i = max(2, _currentPage - 1); i <= min(_totalPages - 1, _currentPage + 1); i++) {
      if (i == 1 || i == _totalPages) continue; // Skip first and last as they're handled separately

      pageButtons.add(const SizedBox(width: 4));
      pageButtons.add(
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _currentPage == i ? const Color(0xFF1E293B) : Colors.transparent,
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextButton(
            onPressed: _currentPage == i ? null : () => _goToPage(i),
            child: Text(
              '$i',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _currentPage == i ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ),
        ),
      );
    }

    // Show ellipsis if needed
    if (_currentPage < _totalPages - 2) {
      pageButtons.add(const SizedBox(width: 4));
      pageButtons.add(
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: const Text(
            '...',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF374151),
            ),
          ),
        ),
      );
    }

    // Show last page if there's more than 1 page
    if (_totalPages > 1) {
      pageButtons.add(const SizedBox(width: 4));
      pageButtons.add(
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _currentPage == _totalPages ? const Color(0xFF1E293B) : Colors.transparent,
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextButton(
            onPressed: _currentPage == _totalPages ? null : () => _goToPage(_totalPages),
            child: Text(
              '$_totalPages',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _currentPage == _totalPages ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        // Previous Button
        Container(
          width: 91,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextButton(
            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            child: const Text(
              'Previous',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Page Numbers
        ...pageButtons,

        const SizedBox(width: 8),

        // Next Button
        Container(
          width: 65,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextButton(
            onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
            child: const Text(
              'Next',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ),

        const Spacer(),

        // Entries Count
        Text(
          'Showing ${_currentPageItems.isNotEmpty ? ((_currentPage - 1) * _perPage) + 1 : 0} '
              'to ${min((_currentPage * _perPage), _totalItems)} of $_totalItems entries',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Due Date Pending Report'),
        actions: [
          IconButton(
            onPressed: _loadDueDatePendingReport,
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

            const SizedBox(height: 24),

            // Filters Section
            _buildFiltersSection(),

            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_allPendingItems.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.calendar_today, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      _selectedDueDate != null
                          ? 'No pending items for ${DateFormat('dd/MM/yyyy').format(_selectedDueDate!)}'
                          : 'Select a due date to view pending items',
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
                        _currentPageItems.length,
                            (index) => _buildDataRow(_currentPageItems[index], index),
                      ),

                      // Totals Row
                      _buildTotalsRow(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Pagination
                _buildPagination(),
              ],
          ],
        ),
      ),
    );
  }
}

// Helper function for max
int max(int a, int b) => a > b ? a : b;
int min(int a, int b) => a < b ? a : b;

// Model for due date pending items
class DueDatePendingItem {
  final String id;
  final String loanId;
  final String loanNo;
  final String customerName;
  final String mobile;
  final int dueNo;
  final String dueDate;
  final double dueAmount;
  final double loanAmount;
  final int noOfWeeks;
  final double penaltyAmount;
  final double totalCollected;
  final double totalPenaltyCollected;
  final double loanBalance;
  final double penaltyBalance;
  final double totalBalance;
  final String status;

  DueDatePendingItem({
    required this.id,
    required this.loanId,
    required this.loanNo,
    required this.customerName,
    required this.mobile,
    required this.dueNo,
    required this.dueDate,
    required this.dueAmount,
    required this.loanAmount,
    required this.noOfWeeks,
    required this.penaltyAmount,
    required this.totalCollected,
    required this.totalPenaltyCollected,
    required this.loanBalance,
    required this.penaltyBalance,
    required this.totalBalance,
    required this.status,
  });
}
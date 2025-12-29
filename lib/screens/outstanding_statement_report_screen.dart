// outstanding_report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/collection_apiservice.dart';
import '../models/outstanding_report_model.dart';

class OutstandingReportScreen extends StatefulWidget {
  const OutstandingReportScreen({super.key});

  @override
  State<OutstandingReportScreen> createState() => _OutstandingReportScreenState();
}

class _OutstandingReportScreenState extends State<OutstandingReportScreen> {
  final collectionapiservice _apiService = collectionapiservice();
  bool _isLoading = true;
  String _searchQuery = '';
  Set<int> _selectedIndices = Set<int>();
  bool _selectAll = false;

  List<OutstandingReportItem> _loans = [];
  List<OutstandingReportItem> _filteredLoans = [];

  // Summary statistics
  OutstandingSummary _summary = OutstandingSummary(
    totalLoanAmount: 0,
    totalInterestAmount: 0,
    totalPenaltyAmount: 0,
    totalCollectionAmount: 0,
    totalPenaltyCollected: 0,
    totalBalancePrincipal: 0,
    totalBalancePenalty: 0,
    totalWeeksPaid: 0,
    totalWeeksBalance: 0,
    totalLoans: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadOutstandingReport();
  }

  Future<void> _loadOutstandingReport() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.fetchOutstandingReport(
        context: context,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted) {
        if (response['status'] == 'success') {
          List<dynamic> items = response['loans'];
          Map<String, dynamic> summaryData = response['summary'];

          List<OutstandingReportItem> loans = items.map((item) {
            return OutstandingReportItem(
              id: item['id'].toString(),
              loanNo: item['loanNo']?.toString() ?? '',
              customerName: item['customerName']?.toString() ?? '',
              loanAmount: double.parse(item['loanAmount']?.toString() ?? '0'),
              interestAmount: double.parse(item['interestAmount']?.toString() ?? '0'),
              noOfWeeks: int.parse(item['noOfWeeks']?.toString() ?? '0'),
              penaltyAmount: double.parse(item['penaltyAmount']?.toString() ?? '0'),
              collectionAmount: double.parse(item['collectionAmount']?.toString() ?? '0'),
              penaltyCollected: double.parse(item['penaltyCollected']?.toString() ?? '0'),
              balancePrincipal: double.parse(item['balancePrincipal']?.toString() ?? '0'),
              balancePenalty: double.parse(item['balancePenalty']?.toString() ?? '0'),
              weeksPaid: int.parse(item['weeksPaid']?.toString() ?? '0'),
              weeksBalance: int.parse(item['weeksBalance']?.toString() ?? '0'),
              loanStatus: item['loanStatus']?.toString() ?? '',
              startDate: item['startDate']?.toString() ?? '',
            );
          }).toList();

          setState(() {
            _loans = loans;
            _filteredLoans = loans;
            _summary = OutstandingSummary(
              totalLoanAmount: double.parse(summaryData['totalLoanAmount']?.toString() ?? '0'),
              totalInterestAmount: double.parse(summaryData['totalInterestAmount']?.toString() ?? '0'),
              totalPenaltyAmount: double.parse(summaryData['totalPenaltyAmount']?.toString() ?? '0'),
              totalCollectionAmount: double.parse(summaryData['totalCollectionAmount']?.toString() ?? '0'),
              totalPenaltyCollected: double.parse(summaryData['totalPenaltyCollected']?.toString() ?? '0'),
              totalBalancePrincipal: double.parse(summaryData['totalBalancePrincipal']?.toString() ?? '0'),
              totalBalancePenalty: double.parse(summaryData['totalBalancePenalty']?.toString() ?? '0'),
              totalWeeksPaid: int.parse(summaryData['totalWeeksPaid']?.toString() ?? '0'),
              totalWeeksBalance: int.parse(summaryData['totalWeeksBalance']?.toString() ?? '0'),
              totalLoans: int.parse(summaryData['totalLoans']?.toString() ?? '0'),
            );
            _selectedIndices.clear();
            _selectAll = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading outstanding report: $e"),
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
      _searchQuery = '';
      _selectedIndices.clear();
      _selectAll = false;
    });
    _loadOutstandingReport();
  }

  void _toggleSelectAll(bool? value) {
    if (value == true) {
      setState(() {
        _selectAll = true;
        _selectedIndices = Set<int>.from(Iterable.generate(_filteredLoans.length));
      });
    } else {
      setState(() {
        _selectAll = false;
        _selectedIndices.clear();
      });
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        _selectAll = false;
      } else {
        _selectedIndices.add(index);
        if (_selectedIndices.length == _filteredLoans.length) {
          _selectAll = true;
        }
      }
    });
  }

  void _exportSelected() {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select loans to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Implement export functionality
    print('Exporting ${_selectedIndices.length} selected loans');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting ${_selectedIndices.length} loans...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _printReport() {
    // TODO: Implement print functionality
    print('Printing outstanding report...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Printing report...'),
        backgroundColor: Colors.blue,
      ),
    );
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
          Text(
            'Outstanding Statement Report',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.33,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Comprehensive overview of all outstanding loans and payment status',
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
          // Customer Name Label
          Text(
            'Customer Name:',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),

          const SizedBox(width: 16),

          // Search Field
          Expanded(
            child: Container(
              width: 375,
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
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  prefixIcon: const Icon(Icons.search, size: 20),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _loadOutstandingReport();
                },
              ),
            ),
          ),

          const SizedBox(width: 32),

          // Export Selected Button
          Container(
            width: 155,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: _exportSelected,
              child: Text(
                'Export Selected',
                style: const TextStyle(
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
              child: Text(
                'Print Report',
                style: const TextStyle(
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
      height: 68,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
      ),
      child: Row(
        children: [
          // Select All Checkbox
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Checkbox(
                  value: _selectAll,
                  onChanged: _toggleSelectAll,
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  'Select All',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),

          // S.No
          SizedBox(
            width: 60,
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
            width: 100,
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

          // Customer
          Expanded(
            flex: 2,
            child: Text(
              'Customer',
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
          Expanded(
            child: Text(
              'Loan\nAmount',
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
          Expanded(
            child: Text(
              'No. of\nWeeks',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Interest Amount
          Expanded(
            child: Text(
              'Interest\nAmount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Penalty Amount
          Expanded(
            child: Text(
              'Penalty\nAmount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Collection Amount
          Expanded(
            child: Text(
              'Collection\nAmount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Penalty Collection
          Expanded(
            child: Text(
              'Penalty\nCollection',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Balance Principle
          Expanded(
            child: Text(
              'Balance\nPrinciple',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Balance Penalty
          Expanded(
            child: Text(
              'Balance\nPenalty',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Weeks Paid
          Expanded(
            child: Text(
              'Weeks\nPaid',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Weeks Balance
          Expanded(
            child: Text(
              'Weeks\nBalance',
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

  Widget _buildDataRow(OutstandingReportItem loan, int index) {
    final isSelected = _selectedIndices.contains(index);
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Container(
      height: 57,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 100,
            child: Checkbox(
              value: isSelected,
              onChanged: (value) => _toggleSelection(index),
              visualDensity: VisualDensity.compact,
            ),
          ),

          // S.No
          SizedBox(
            width: 60,
            child: Text(
              '${index + 1}',
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
            width: 100,
            child: Text(
              loan.loanNo,
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
          Expanded(
            flex: 2,
            child: Text(
              loan.customerName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Loan Amount
          Expanded(
            child: Text(
              formatCurrency.format(loan.loanAmount),
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
          Expanded(
            child: Text(
              '${loan.noOfWeeks}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Interest Amount
          Expanded(
            child: Text(
              formatCurrency.format(loan.interestAmount),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Penalty Amount
          Expanded(
            child: Text(
              formatCurrency.format(loan.penaltyAmount),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Collection Amount
          Expanded(
            child: Text(
              formatCurrency.format(loan.collectionAmount),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Penalty Collection
          Expanded(
            child: Text(
              formatCurrency.format(loan.penaltyCollected),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Balance Principle
          Expanded(
            child: Text(
              formatCurrency.format(loan.balancePrincipal),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Balance Penalty
          Expanded(
            child: Text(
              formatCurrency.format(loan.balancePenalty),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Weeks Paid
          Expanded(
            child: Text(
              '${loan.weeksPaid}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: loan.weeksPaid > 0 ? const Color(0xFF065F46) : Color(0xFF374151),
              ),
            ),
          ),

          // Weeks Balance
          Expanded(
            child: Text(
              '${loan.weeksBalance}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: loan.weeksBalance > 0 ? const Color(0xFFDC2626) : Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsRow() {
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Container(
      height: 57,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
      ),
      child: Row(
        children: [
          // TOTALS label
          SizedBox(
            width: 160,
            child: Padding(
              padding: const EdgeInsets.only(left: 80.0),
              child: Text(
                'TOTALS',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),

          // Spacer for Loan No column
          const SizedBox(width: 100),

          // Spacer for Customer column
          const Expanded(flex: 2, child: SizedBox()),

          // Total Loan Amount
          Expanded(
            child: Text(
              formatCurrency.format(_summary.totalLoanAmount),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),

          // Spacer for No. of Weeks column
          const Expanded(child: SizedBox()),

          // Total Interest Amount
          Expanded(
            child: Text(
              formatCurrency.format(_summary.totalInterestAmount),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),

          // Total Penalty Amount
          Expanded(
            child: Text(
              formatCurrency.format(_summary.totalPenaltyAmount),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),

          // Total Collection Amount
          Expanded(
            child: Text(
              formatCurrency.format(_summary.totalCollectionAmount),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),

          // Total Penalty Collected
          Expanded(
            child: Text(
              formatCurrency.format(_summary.totalPenaltyCollected),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),

          // Total Balance Principal
          Expanded(
            child: Text(
              formatCurrency.format(_summary.totalBalancePrincipal),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),

          // Total Balance Penalty
          Expanded(
            child: Text(
              formatCurrency.format(_summary.totalBalancePenalty),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),

          // Total Weeks Paid
          Expanded(
            child: Text(
              '${_summary.totalWeeksPaid}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),

          // Total Weeks Balance
          Expanded(
            child: Text(
              '${_summary.totalWeeksBalance}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      children: [
        // Previous Button
        Container(
          width: 83,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextButton(
            onPressed: () {},
            child: Text(
              'Previous',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ),

        const SizedBox(width: 4),

        // Page 1 Button
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextButton(
            onPressed: () {},
            child: Text(
              '1',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(width: 4),

        // Next Button
        Container(
          width: 57,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextButton(
            onPressed: () {},
            child: Text(
              'Next',
              style: const TextStyle(
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
          'Showing ${_filteredLoans.isNotEmpty ? 1 : 0} to ${_filteredLoans.length} of ${_filteredLoans.length} entries',
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
        title: const Text('Outstanding Statement Report'),
        actions: [
          IconButton(
            onPressed: _loadOutstandingReport,
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
            else if (_filteredLoans.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.credit_card_off, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No outstanding loans found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else ...[
                // Table Header
                _buildTableHeader(),

                // Data Rows
                ...List.generate(
                  _filteredLoans.length,
                      (index) => _buildDataRow(_filteredLoans[index], index),
                ),

                // Totals Row
                _buildTotalsRow(),

                const SizedBox(height: 47),

                // Pagination
                _buildPagination(),
              ],
          ],
        ),
      ),
    );
  }
}
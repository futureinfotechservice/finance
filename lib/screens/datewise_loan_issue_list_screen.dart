import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/datewiseloanreport_apiservice.dart';


class LoanIssueReportItem {
  final String id;
  final String loanNo;
  final String customerId;
  final String customerName;
  final String loanTypeId;
  final String loanAmount;
  final String givenAmount;
  final String interestAmount;
  final String loanDay;
  final String noOfWeeks;
  final String paymentMode;
  final String startDate;
  final String addedBy;
  final String loanStatus;
  final String createdDate;

  LoanIssueReportItem({
    required this.id,
    required this.loanNo,
    required this.customerId,
    required this.customerName,
    required this.loanTypeId,
    required this.loanAmount,
    required this.givenAmount,
    required this.interestAmount,
    required this.loanDay,
    required this.noOfWeeks,
    required this.paymentMode,
    required this.startDate,
    required this.addedBy,
    required this.loanStatus,
    required this.createdDate,
  });
}

class DateWiseLoanIssueReportScreen extends StatefulWidget {
  const DateWiseLoanIssueReportScreen({super.key});

  @override
  State<DateWiseLoanIssueReportScreen> createState() => _DateWiseLoanIssueReportScreenState();
}

class _DateWiseLoanIssueReportScreenState extends State<DateWiseLoanIssueReportScreen> {
  final datewiseloan_apiservice _apiService = datewiseloan_apiservice();
  bool _isLoading = true;
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  String? _selectedCustomerId;
  String _searchQuery = '';

  List<LoanIssueReportItem> _loans = [];
  List<LoanIssueReportItem> _filteredLoans = [];
  List<Map<String, String>> _customers = [];

  // Summary statistics
  double _totalLoanAmount = 0;
  double _totalGivenAmount = 0;
  double _totalInterestAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load loans
      await _loadLoans();

      // Load customers for dropdown
      await _loadCustomers();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading data: $e"),
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

  Future<void> _loadLoans() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyid = prefs.getString('companyid') ?? '';

      String? fromDateStr;
      String? toDateStr;
      String? customerId = _selectedCustomerId;

      if (_selectedFromDate != null) {
        fromDateStr = DateFormat('yyyy-MM-dd').format(_selectedFromDate!);
      }
      if (_selectedToDate != null) {
        toDateStr = DateFormat('yyyy-MM-dd').format(_selectedToDate!);
      }

      // Call your API to fetch loans
      final response = await _apiService.fetchDateWiseLoans(
        companyid: companyid,
        fromDate: fromDateStr,
        toDate: toDateStr,
        customerId: customerId,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (response['status'] == 'success') {
        List<dynamic> items = response['loans'];
        List<LoanIssueReportItem> loans = items.map((item) {
          return LoanIssueReportItem(
            id: item['id'].toString(),
            loanNo: item['loanno']?.toString() ?? '',
            customerId: item['customerid']?.toString() ?? '',
            customerName: item['customername']?.toString() ?? '',
            loanTypeId: item['loantypeid']?.toString() ?? '',
            loanAmount: item['loanamount']?.toString() ?? '0',
            givenAmount: item['givenamount']?.toString() ?? '0',
            interestAmount: item['interestamount']?.toString() ?? '0',
            loanDay: item['loanday']?.toString() ?? '',
            noOfWeeks: item['noofweeks']?.toString() ?? '',
            paymentMode: item['paymentmode']?.toString() ?? '',
            startDate: item['startdate']?.toString() ?? '',
            addedBy: item['addedby']?.toString() ?? '',
            loanStatus: item['loanstatus']?.toString() ?? '',
            createdDate: item['createddate']?.toString() ?? '',
          );
        }).toList();

        // Calculate totals
        double totalLoan = 0;
        double totalGiven = 0;
        double totalInterest = 0;

        for (var loan in loans) {
          totalLoan += double.tryParse(loan.loanAmount) ?? 0;
          totalGiven += double.tryParse(loan.givenAmount) ?? 0;
          totalInterest += double.tryParse(loan.interestAmount) ?? 0;
        }

        setState(() {
          _loans = loans;
          _filteredLoans = _applySearchFilter(loans);
          _totalLoanAmount = totalLoan;
          _totalGivenAmount = totalGiven;
          _totalInterestAmount = totalInterest;
        });
      }
    } catch (e) {
      print("Load Loans Error: $e");
      rethrow;
    }
  }

  Future<void> _loadCustomers() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final companyid = prefs.getString('companyid') ?? '';

      // Call API to fetch customers
      final response = await _apiService.fetchCustomers(companyid: companyid);

      if (response['status'] == 'success') {
        List<dynamic> items = response['customers'];
        List<Map<String, String>> customers = items.map((item) {
          return {
            'id': item['id'].toString(),
            'name': item['customername']?.toString() ?? '',
            'display': '${item['customername']} (${item['mobile1'] ?? ''})',
          };
        }).toList();

        setState(() {
          _customers = customers;
        });
      }
    } catch (e) {
      print("Load Customers Error: $e");
      // Don't throw, just log the error
    }
  }

  List<LoanIssueReportItem> _applySearchFilter(List<LoanIssueReportItem> loans) {
    if (_searchQuery.isEmpty) return loans;

    final query = _searchQuery.toLowerCase();
    return loans.where((loan) {
      return loan.loanNo.toLowerCase().contains(query) ||
          loan.customerName.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? (_selectedFromDate ?? DateTime.now())
          : (_selectedToDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && mounted) {
      setState(() {
        if (isFromDate) {
          _selectedFromDate = picked;
          if (_selectedToDate != null && _selectedToDate!.isBefore(picked)) {
            _selectedToDate = null;
          }
        } else {
          _selectedToDate = picked;
        }
      });
      _loadLoans();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedFromDate = null;
      _selectedToDate = null;
      _selectedCustomerId = null;
      _searchQuery = '';
    });
    _loadLoans();
  }

  void _exportSelected() {
    // TODO: Implement export functionality
    print('Exporting loan report...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting report...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _printReport() {
    // TODO: Implement print functionality
    print('Printing loan report...');
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
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Date wise Loan Issue List',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Comprehensive overview of loan issues by date range',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w400,
              height: 1.05,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First row: Date filters
          Row(
            children: [
              // From Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From Date :',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      width: 200,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedFromDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_selectedFromDate!)
                                  : 'Select',
                              style: TextStyle(
                                color: _selectedFromDate != null ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 36),

              // To Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To Date :',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      width: 200,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedToDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_selectedToDate!)
                                  : 'Select',
                              style: TextStyle(
                                color: _selectedToDate != null ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 36),

              // Customer Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer :',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 200,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCustomerId,
                        isExpanded: true,
                        hint: Text(
                          'Select Customer',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Customers'),
                          ),
                          ..._customers.map((customer) {
                            return DropdownMenuItem<String>(
                              value: customer['id'],
                              child: Text(
                                customer['name'] ?? '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCustomerId = value;
                          });
                          _loadLoans();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Second row: Action buttons
          Row(
            children: [
              // Export Selected Button
              Container(
                width: 139,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
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
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 53,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          // S.No
          SizedBox(
            width: 100,
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

          // Loan Number
          SizedBox(
            width: 150,
            child: Text(
              'Loan Number',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Loan Date
          SizedBox(
            width: 150,
            child: Text(
              'Loan Date',
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

          // Given Amount
          Expanded(
            child: Text(
              'Given Amount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // No.of.weeks
          Expanded(
            child: Text(
              'No.of.weeks',
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

  Widget _buildDataRow(LoanIssueReportItem loan, int index) {
    final loanAmount = double.tryParse(loan.loanAmount) ?? 0;
    final givenAmount = double.tryParse(loan.givenAmount) ?? 0;
    final startDate = loan.startDate.isNotEmpty
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(loan.startDate))
        : 'N/A';

    return Container(
      height: 53,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // S.No
          SizedBox(
            width: 100,
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

          // Loan Number
          SizedBox(
            width: 150,
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

          // Loan Date
          SizedBox(
            width: 150,
            child: Text(
              startDate,
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
              '₹${loanAmount.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Given Amount
          Expanded(
            child: Text(
              '₹${givenAmount.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // No.of.weeks
          Expanded(
            child: Text(
              loan.noOfWeeks,
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

  Widget _buildTotalsRow() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          // TOTALS label
          SizedBox(
            width: 400,
            child: Padding(
              padding: const EdgeInsets.only(left: 100.0),
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

          // Total Loan Amount
          Expanded(
            child: Text(
              '₹${_totalLoanAmount.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),

          // Total Given Amount
          Expanded(
            child: Text(
              '₹${_totalGivenAmount.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),

          // Total Weeks (placeholder)
          Expanded(
            child: Text(
              '-',
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
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Previous Button
          Container(
            width: 91,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
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

          const SizedBox(width: 8),

          // Page 1 Button
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              border: Border.all(color: const Color(0xFFD1D5DB)),
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

          const SizedBox(width: 8),

          // Next Button
          Container(
            width: 65,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Date Wise Loan Issue Report'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(),

            // Filters Section
            _buildFiltersSection(),

            // Table Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 100.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_filteredLoans.isEmpty)
                    Container(
                      height: 320,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.money_off, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No loan records found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
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
                              SizedBox(
                                height: 265,
                                child: ListView.builder(
                                  itemCount: _filteredLoans.length,
                                  itemBuilder: (context, index) {
                                    return _buildDataRow(_filteredLoans[index], index);
                                  },
                                ),
                              ),

                              // Totals Row
                              _buildTotalsRow(),
                            ],
                          ),
                        ),

                        // Pagination
                        _buildPagination(),

                        // Entries Count
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Center(
                            child: Text(
                              'Showing 1 to ${_filteredLoans.length} of ${_filteredLoans.length} entries',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/collection_apiservice.dart';

class CollectionHistoryItem {
  final String id;
  final String collectionNo;
  final String loanNo;
  final String customerName;
  final String collectionDate;
  final String paymentMode;
  final String totalAmount;
  final String totalPenalty;
  final String collectedBy;
  final String mobile1;
  final String address;
  final String loanAmount;
  final String loanStatus;
  final List<CollectionDetail> details;

  CollectionHistoryItem({
    required this.id,
    required this.collectionNo,
    required this.loanNo,
    required this.customerName,
    required this.collectionDate,
    required this.paymentMode,
    required this.totalAmount,
    required this.totalPenalty,
    required this.collectedBy,
    required this.mobile1,
    required this.address,
    required this.loanAmount,
    required this.loanStatus,
    required this.details,
  });
}

class CollectionDetail {
  final String detailId;
  final int dueNo;
  final String dueReceived;
  final String penaltyReceived;
  final String createdDate;

  CollectionDetail({
    required this.detailId,
    required this.dueNo,
    required this.dueReceived,
    required this.penaltyReceived,
    required this.createdDate,
  });
}

class CollectionHistoryReportScreen extends StatefulWidget {
  const CollectionHistoryReportScreen({super.key});

  @override
  State<CollectionHistoryReportScreen> createState() => _CollectionHistoryReportScreenState();
}

class _CollectionHistoryReportScreenState extends State<CollectionHistoryReportScreen> {
  final collectionapiservice _apiService = collectionapiservice();
  bool _isLoading = true;
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  String _searchQuery = '';
  Set<int> _selectedIndices = Set<int>();
  bool _selectAll = false;

  // Summary statistics
  double _totalCashCollected = 0;
  double _totalBankCollected = 0;
  double _totalDueAmount = 0;
  double _totalPenaltyAmount = 0;

  List<CollectionHistoryItem> _collections = [];
  List<CollectionHistoryItem> _filteredCollections = [];

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? fromDateStr;
      String? toDateStr;

      if (_selectedFromDate != null) {
        fromDateStr = DateFormat('yyyy-MM-dd').format(_selectedFromDate!);
      }
      if (_selectedToDate != null) {
        toDateStr = DateFormat('yyyy-MM-dd').format(_selectedToDate!);
      }

      final response = await _apiService.fetchCollectionHistory(
          context: context,
          fromDate: fromDateStr,
          toDate: toDateStr,
          searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null
      );

      if (mounted) {
        if (response['status'] == 'success') {
          List<dynamic> items = response['collections'];
          List<CollectionHistoryItem> collections = items.map((item) {
            // Convert details
            List<CollectionDetail> details = [];
            if (item['details'] != null) {
              for (var detail in item['details']) {
                details.add(CollectionDetail(
                  detailId: detail['detail_id'].toString(),
                  dueNo: detail['dueno'],
                  dueReceived: detail['due_received']?.toString() ?? '0',
                  penaltyReceived: detail['penalty_received']?.toString() ?? '0',
                  createdDate: detail['detail_created']?.toString() ?? '',
                ));
              }
            }

            return CollectionHistoryItem(
              id: item['id'].toString(),
              collectionNo: item['collectionno']?.toString() ?? '',
              loanNo: item['loanno']?.toString() ?? '',
              customerName: item['customername']?.toString() ?? '',
              collectionDate: item['collectiondate']?.toString() ?? '',
              paymentMode: item['paymentmode']?.toString() ?? 'Cash',
              totalAmount: item['totalamount']?.toString() ?? '0',
              totalPenalty: item['totalpenalty']?.toString() ?? '0',
              collectedBy: item['collectedby']?.toString() ?? '',
              mobile1: item['mobile1']?.toString() ?? '',
              address: item['address']?.toString() ?? '',
              loanAmount: item['loanamount']?.toString() ?? '0',
              loanStatus: item['loanstatus']?.toString() ?? '',
              details: details,
            );
          }).toList();

          // Update summary from API
          Map<String, dynamic> summary = response['summary'];
          setState(() {
            _collections = collections;
            _filteredCollections = _applySearchFilter(collections);
            _totalDueAmount = double.parse(summary['totalDueAmount']?.toString() ?? '0');
            _totalPenaltyAmount = double.parse(summary['totalPenaltyAmount']?.toString() ?? '0');
            _totalCashCollected = double.parse(summary['totalCashCollected']?.toString() ?? '0');
            _totalBankCollected = double.parse(summary['totalBankCollected']?.toString() ?? '0');
            _selectedIndices.clear();
            _selectAll = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading collection history: $e"),
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

  // UPDATED: This method now works with CollectionHistoryItem
  List<CollectionHistoryItem> _applySearchFilter(List<CollectionHistoryItem> collections) {
    if (_searchQuery.isEmpty) return collections;

    final query = _searchQuery.toLowerCase();
    return collections.where((collection) {
      return collection.customerName.toLowerCase().contains(query) ||
          collection.loanNo.toLowerCase().contains(query) ||
          collection.collectionNo.toLowerCase().contains(query);
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
      _loadCollections();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedFromDate = null;
      _selectedToDate = null;
      _searchQuery = '';
      _selectedIndices.clear();
      _selectAll = false;
    });
    _loadCollections();
  }

  void _toggleSelectAll(bool? value) {
    if (value == true) {
      setState(() {
        _selectAll = true;
        _selectedIndices = Set<int>.from(Iterable.generate(_filteredCollections.length));
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
        if (_selectedIndices.length == _filteredCollections.length) {
          _selectAll = true;
        }
      }
    });
  }

  void _exportSelected() {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select collections to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Implement export functionality
    print('Exporting ${_selectedIndices.length} selected collections');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting ${_selectedIndices.length} collections...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _printReport() {
    // TODO: Implement print functionality
    print('Printing report...');
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
            'Collection History Report',
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
            'Comprehensive overview of all collection activities and payment records',
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
          // From Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'From Date:',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _selectDate(context, true),
                child: Container(
                  width: 152,
                  height: 38,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
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

          const SizedBox(width: 32),

          // To Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To Date:',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _selectDate(context, false),
                child: Container(
                  width: 152,
                  height: 38,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
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

          const SizedBox(width: 32),

          // Search - FIXED: Now properly uses the updated _applySearchFilter
          Expanded(
            child: Container(
              height: 38,
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
                    color: Color(0xFF999999),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  prefixIcon: const Icon(Icons.search, size: 20),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _filteredCollections = _applySearchFilter(_collections);
                  });
                },
              ),
            ),
          ),

          const SizedBox(width: 32),

          // Export Selected Button
          Container(
            width: 139,
            height: 38,
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
            height: 38,
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
      height: 53,
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

          // Date
          SizedBox(
            width: 90,
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

          // Customer Name
          Expanded(
            flex: 2,
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

          // Loan No
          Expanded(
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

          // Due Number
          Expanded(
            child: Text(
              'Due Number',
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
          Expanded(
            child: Text(
              'Due Amount',
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
              'Penalty Amount',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Cash/Bank
          Expanded(
            child: Text(
              'Cash/Bank',
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

  Widget _buildDataRow(CollectionHistoryItem collection, int index) {
    final isSelected = _selectedIndices.contains(index);
    final totalAmount = double.tryParse(collection.totalAmount) ?? 0;
    final totalPenalty = double.tryParse(collection.totalPenalty) ?? 0;
    final collectionDate = collection.collectionDate.isNotEmpty
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(collection.collectionDate))
        : 'N/A';

    // Get the due number(s) - show the first one or a summary
    String dueNumbers = '';
    if (collection.details.isNotEmpty) {
      if (collection.details.length == 1) {
        dueNumbers = '${collection.details.first.dueNo}';
      } else {
        // Show range if multiple
        int firstDue = collection.details.first.dueNo;
        int lastDue = collection.details.last.dueNo;
        dueNumbers = '$firstDue-$lastDue';
      }
    }

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

          // Date
          SizedBox(
            width: 90,
            child: Text(
              collectionDate,
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
              collection.customerName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Loan No
          Expanded(
            child: Text(
              collection.loanNo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Due Number
          Expanded(
            child: Text(
              dueNumbers,
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
          Expanded(
            child: Text(
              '₹${totalAmount.toStringAsFixed(2)}',
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
              '₹${totalPenalty.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Payment Mode Badge
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: collection.paymentMode.toLowerCase() == 'cash'
                      ? const Color(0xFF065F46)
                      : const Color(0xFF1E40AF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  collection.paymentMode,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsRow() {
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

          // Spacer for Customer Name and Loan No columns
          const Expanded(flex: 3, child: SizedBox()),

          // Spacer for Due Number column
          const Expanded(child: SizedBox()),

          // Total Due Amount
          Expanded(
            child: Text(
              '₹${_totalDueAmount.toStringAsFixed(2)}',
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
              '₹${_totalPenaltyAmount.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),

          // Empty cell for Payment Mode
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        // Total Cash Collected
        Container(
          width: 200,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Cash Collected',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${_totalCashCollected.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 39),

        // Total Bank Collected
        Container(
          width: 200,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Bank Collected',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${_totalBankCollected.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    return Row(
      children: [
        // Previous Button
        Container(
          width: 91,
          height: 38,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(8),
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
          width: 38,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
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
          width: 65,
          height: 38,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(8),
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
          'Showing 1 to ${_filteredCollections.length} of ${_filteredCollections.length} entries',
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
        title: const Text('Collection History Report'),
        actions: [
          IconButton(
            onPressed: _loadCollections,
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

            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_filteredCollections.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No collection records found',
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
                  _filteredCollections.length,
                      (index) => _buildDataRow(_filteredCollections[index], index),
                ),

                // Totals Row
                _buildTotalsRow(),

                const SizedBox(height: 47),

                // Summary Cards
                _buildSummaryCards(),

                const SizedBox(height: 26),

                // Pagination
                _buildPagination(),
              ],
          ],
        ),
      ),
    );
  }
}
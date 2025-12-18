import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/collection_apiservice.dart';
import '../services/loan_apiservice.dart';
import 'collection_entry_screen.dart';

class CollectionListScreen extends StatefulWidget {
  const CollectionListScreen({super.key});

  @override
  State<CollectionListScreen> createState() => _CollectionListScreenState();
}

class _CollectionListScreenState extends State<CollectionListScreen> {
  final collectionapiservice _apiService = collectionapiservice();
  List<CollectionModel> _collections = [];
  bool _isLoading = true;
  String _searchQuery = '';
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;

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

      final collections = await _apiService.fetchCollections(
        context,
        fromDate: fromDateStr,
        toDate: toDateStr,
      );

      if (mounted) {
        setState(() {
          _collections = collections;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading collections: $e"),
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
    });
    _loadCollections();
  }

  List<CollectionModel> get _filteredCollections {
    if (_searchQuery.isEmpty) return _collections;
    final query = _searchQuery.toLowerCase();
    return _collections.where((collection) {
      return collection.collectionno.toLowerCase().contains(query) ||
          collection.loanno.toLowerCase().contains(query) ||
          collection.customername.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildDateFilter() {
    return Row(
      children: [
        // From Date
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(context, true),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
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
                          : 'From Date',
                      style: TextStyle(
                        color: _selectedFromDate != null
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),
        const Text('to', style: TextStyle(color: Colors.grey)),
        const SizedBox(width: 8),

        // To Date
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(context, false),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
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
                          : 'To Date',
                      style: TextStyle(
                        color: _selectedToDate != null
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Clear Filter Button
        IconButton(
          onPressed: _clearFilters,
          icon: const Icon(Icons.clear, color: Colors.grey),
          tooltip: 'Clear filters',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection List'),
        actions: [
          IconButton(
            onPressed: _loadCollections,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Date Filter
                _buildDateFilter(),

                const SizedBox(height: 12),

                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search collections...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  onChanged: (value) {
                    if (mounted) {
                      setState(() {
                        _searchQuery = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_filteredCollections.isEmpty)
          // Empty State
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty ||
                          _selectedFromDate != null ||
                          _selectedToDate != null
                          ? 'No matching collections found'
                          : 'No collections recorded yet',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    if (_searchQuery.isEmpty &&
                        _selectedFromDate == null &&
                        _selectedToDate == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CollectionEntryScreen(),
                            ),
                          ),
                          child: const Text('Record New Collection'),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
          // Collections List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: _filteredCollections.length,
                itemBuilder: (context, index) {
                  final collection = _filteredCollections[index];
                  return _buildCollectionCard(collection);
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CollectionEntryScreen(),
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCollectionCard(CollectionModel collection) {
    final totalAmount = double.parse(collection.totalamount);
    final totalPenalty = double.parse(collection.totalpenalty);
    final collectionDate = collection.collectiondate.isNotEmpty
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(collection.collectiondate))
        : 'N/A';

    // Calculate grand total
    final grandTotal = totalAmount + totalPenalty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  collection.collectionno,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Chip(
                  label: Text(collection.paymentmode),
                  backgroundColor: Colors.blue[50],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              collection.customername,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Loan No: ${collection.loanno}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collection Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        collectionDate,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Mode',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        collection.paymentmode,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Principal Amount',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '₹${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Penalty Amount',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '₹${totalPenalty.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey[300]),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B).withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Collected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '₹${grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Implement view details functionality
                      // _showCollectionDetails(context, collection);
                    },
                    icon: const Icon(Icons.visibility_outlined, color: Color(0xFF1E293B)),
                    tooltip: 'View Details',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
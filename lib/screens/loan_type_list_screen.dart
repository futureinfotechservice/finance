import 'package:flutter/material.dart';

import '../services/loantype_apiservice.dart';
import 'loan_type_master_screen.dart';

class LoanTypeListScreen extends StatefulWidget {
  const LoanTypeListScreen({super.key});

  @override
  State<LoanTypeListScreen> createState() => _LoanTypeListScreenState();
}

class _LoanTypeListScreenState extends State<LoanTypeListScreen> {
  final LoantypeApiService _apiService = LoantypeApiService();
  List<LoanTypeModel> _loanTypes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadLoanTypes();
  }

  Future<void> _loadLoanTypes() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final loanTypes = await _apiService.fetchLoanTypes(context);
      if (mounted) {
        setState(() {
          _loanTypes = loanTypes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading loan types: $e"),
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

  Future<void> _deleteLoanType(String loanTypeId, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this loan type?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await _apiService.deleteLoanType(context, loanTypeId);
      if (result == "Success" && mounted) {
        setState(() {
          _loanTypes.removeAt(index);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Loan type deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _navigateToLoanTypeForm({LoanTypeModel? loanType}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoanTypeMasterScreen(loanType: loanType),
      ),
    );

    if (result == true && mounted) {
      await _loadLoanTypes();
    }
  }

  List<LoanTypeModel> get _filteredLoanTypes {
    if (_searchQuery.isEmpty) return _loanTypes;
    final query = _searchQuery.toLowerCase();
    return _loanTypes.where((loanType) {
      return loanType.loantype.toLowerCase().contains(query) ||
          loanType.collectionday.toLowerCase().contains(query) ||
          loanType.noofweeks.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Loan Types'),
        actions: [
          IconButton(
            onPressed: _loadLoanTypes,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search loan types...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
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
          ),

          // Loading Indicator
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_filteredLoanTypes.isEmpty)
          // Empty State
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No matching loan types found'
                          : 'No loan types yet',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    if (_searchQuery.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ElevatedButton(
                          onPressed: () => _navigateToLoanTypeForm(),
                          child: const Text('Create Loan Type'),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
          // Loan Types List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                itemCount: _filteredLoanTypes.length,
                itemBuilder: (context, index) {
                  final loanType = _filteredLoanTypes[index];
                  return _buildLoanTypeCardSimple(loanType, index);
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToLoanTypeForm(),
        backgroundColor: const Color(0xFF1E293B),
        heroTag: 'loan_type_fab',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Simple card without complex layout issues
  Widget _buildLoanTypeCardSimple(LoanTypeModel loanType, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          loanType.loantype,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Collection: ${loanType.collectionday}'),
            Text('Duration: ${loanType.noofweeks}'),
            if (loanType.penaltyamount.isNotEmpty && loanType.penaltyamount != "0")
              Text('Penalty: ₹${loanType.penaltyamount}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _navigateToLoanTypeForm(loanType: loanType),
              icon: const Icon(Icons.edit, color: Colors.blue),
            ),
            IconButton(
              onPressed: () => _deleteLoanType(loanType.id, index),
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
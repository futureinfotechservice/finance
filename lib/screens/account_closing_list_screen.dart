import 'package:flutter/material.dart';
import '../services/account_closing_api_service.dart';
import '../models/account_closing_model.dart';
import './account_closing_screen.dart';

class AccountClosingListScreen extends StatefulWidget {
  const AccountClosingListScreen({super.key});

  @override
  State<AccountClosingListScreen> createState() => _AccountClosingListScreenState();
}

class _AccountClosingListScreenState extends State<AccountClosingListScreen> {
  final AccountClosingApiService _apiService = AccountClosingApiService();
  List<AccountClosingModel> _closings = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAccountClosings();
  }

  Future<void> _loadAccountClosings() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final closings = await _apiService.fetchAccountClosings(context);
      if (mounted) {
        setState(() {
          _closings = closings;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading account closings: $e"),
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

  void _navigateToAccountClosingForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AccountClosingScreen(),
      ),
    );

    if (result == true && mounted) {
      await _loadAccountClosings();
    }
  }

  List<AccountClosingModel> get _filteredClosings {
    if (_searchQuery.isEmpty) return _closings;
    final query = _searchQuery.toLowerCase();
    return _closings.where((closing) {
      return closing.serialNo.toLowerCase().contains(query) ||
          closing.customerName.toLowerCase().contains(query) ||
          closing.loanNo.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildClosingCard(AccountClosingModel closing) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    closing.serialNo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Text(
                  closing.formattedDate,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Customer and Loan Info
            Row(
              children: [
                _buildDetailItem(
                  icon: Icons.person,
                  label: 'Customer',
                  value: closing.customerName,
                ),
                const SizedBox(width: 20),
                _buildDetailItem(
                  icon: Icons.account_balance,
                  label: 'Loan No',
                  value: closing.loanNo,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Amount Summary
            Row(
              children: [
                _buildAmountItem(
                  label: 'Loan Amount',
                  value: closing.formattedLoanAmount,
                  color: const Color(0xFF374151),
                ),
                const SizedBox(width: 20),
                _buildAmountItem(
                  label: 'Loan Paid',
                  value: closing.formattedLoanPaid,
                  color: const Color(0xFF059669),
                ),
                const SizedBox(width: 20),
                _buildAmountItem(
                  label: 'Balance',
                  value: closing.formattedBalanceAmount,
                  color: const Color(0xFFDC2626),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Penalty Summary
            Row(
              children: [
                _buildAmountItem(
                  label: 'Penalty',
                  value: closing.formattedPenaltyAmount,
                  color: const Color(0xFF92400E),
                ),
                const SizedBox(width: 20),
                _buildAmountItem(
                  label: 'Penalty Paid',
                  value: closing.formattedPenaltyCollected,
                  color: const Color(0xFF059669),
                ),
                const SizedBox(width: 20),
                _buildAmountItem(
                  label: 'Penalty Balance',
                  value: closing.formattedPenaltyBalance,
                  color: const Color(0xFFDC2626),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Discounts and Final Settlement
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settlement Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSettlementDetail(
                        label: 'Discount (Principle)',
                        value: '₹${closing.discountPrincipleValue.toStringAsFixed(2)}',
                      ),
                      const SizedBox(width: 20),
                      _buildSettlementDetail(
                        label: 'Discount (Penalty)',
                        value: '₹${closing.discountPenaltyValue.toStringAsFixed(2)}',
                      ),
                      const SizedBox(width: 20),
                      _buildSettlementDetail(
                        label: 'Final Settlement',
                        value: closing.formattedFinalSettlement,
                        isBold: true,
                        color: const Color(0xFF059669),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementDetail({
    required String label,
    required String value,
    bool isBold = false,
    Color? color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color ?? const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    double totalLoanAmount = 0;
    double totalLoanPaid = 0;
    double totalBalance = 0;
    double totalFinalSettlement = 0;

    for (var closing in _filteredClosings) {
      totalLoanAmount += closing.loanAmountValue;
      totalLoanPaid += closing.loanPaidValue;
      totalBalance += closing.balanceAmountValue;
      totalFinalSettlement += closing.finalSettlementValue;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSummaryItem(
                  label: 'Total Closings',
                  value: _filteredClosings.length.toString(),
                  color: const Color(0xFF1E293B),
                ),
                const SizedBox(width: 20),
                _buildSummaryItem(
                  label: 'Total Loan Amount',
                  value: '₹${totalLoanAmount.toStringAsFixed(2)}',
                  color: const Color(0xFF374151),
                ),
                const SizedBox(width: 20),
                _buildSummaryItem(
                  label: 'Total Loan Paid',
                  value: '₹${totalLoanPaid.toStringAsFixed(2)}',
                  color: const Color(0xFF059669),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSummaryItem(
                  label: 'Total Balance',
                  value: '₹${totalBalance.toStringAsFixed(2)}',
                  color: const Color(0xFFDC2626),
                ),
                const SizedBox(width: 20),
                _buildSummaryItem(
                  label: 'Total Settlement',
                  value: '₹${totalFinalSettlement.toStringAsFixed(2)}',
                  color: const Color(0xFF059669),
                  isBold: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Account Closings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadAccountClosings,
            icon: const Icon(Icons.refresh, color: Color(0xFF1E293B)),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by serial no, customer, or loan no...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
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
          ),

          // Info header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredClosings.length} closing${_filteredClosings.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Summary Card
          if (_filteredClosings.isNotEmpty && !_isLoading)
            _buildSummaryCard(),

          const SizedBox(height: 8),

          // Closings List
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading account closings...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
                : _filteredClosings.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No matching account closings found'
                        : 'No account closings yet',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Try a different search term'
                        : 'Close your first loan account to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_searchQuery.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ElevatedButton(
                        onPressed: _navigateToAccountClosingForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9CA3AF),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Close Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _filteredClosings.length,
              itemBuilder: (context, index) {
                final closing = _filteredClosings[index];
                return _buildClosingCard(closing);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAccountClosingForm,
        backgroundColor: const Color(0xFF9CA3AF),
        heroTag: 'account_closing_fab',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
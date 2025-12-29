import 'package:financeapp/screens/payment_entry_list_screen.dart';
import 'package:financeapp/screens/receipt_entry_list_screen.dart';
import 'package:financeapp/screens/reports_screen.dart';
import 'package:financeapp/screens/settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'CustomerListScreen.dart';
import 'ac_ledger_list_screen.dart';
import 'account_closing_list_screen.dart';
import 'cash_ledger_report_screen.dart';
import 'collection_history_report_screen.dart';
import 'collection_list_screen.dart';
import 'dashboardscreen.dart';
import 'datewise_loan_issue_list_screen.dart';
import 'due_datewise_pending_report_screen.dart';
import 'loan_history_report_screen.dart';
import 'loan_issue_screen.dart';
import 'loan_list_screen.dart';
import 'loan_type_list_screen.dart';
import 'loan_type_master_screen.dart';

// Import the new Entry screens (you'll need to create these)
import 'amount_receipt_entry_screen.dart';
import 'collection_entry_screen.dart';
import 'account_closing_screen.dart';
import 'outstanding_statement_report_screen.dart';
import 'payment_entry_screen.dart';



class CustomerManagementApp extends StatefulWidget {
  const CustomerManagementApp({super.key});

  @override
  State<CustomerManagementApp> createState() => _CustomerManagementAppState();
}

class _CustomerManagementAppState extends State<CustomerManagementApp> {
  int _selectedIndex = 0;
  int _masterSubIndex = 0; // 0: Customer Master, 1: Loan Type Master, 2: AC Ledger
  int _entrySubIndex = 0; // 0: Amount Receipt, 1: Loan Issue, 2: Collection Entry, 3: Account Closing, 4: Payment Entry
  int _reportSubIndex = 0; // 0: Loan History, 1: Outstanding Statement, 2: Collection History, 3: Cash Ledger, 4: Due Datewise Pending, 5: Datewise Loan Issue

  // Create GlobalKey for MasterSectionScreen, EntrySectionScreen and ReportSectionScreen
  final GlobalKey<_MasterSectionScreenState> _masterSectionKey = GlobalKey();
  final GlobalKey<_EntrySectionScreenState> _entrySectionKey = GlobalKey();
  final GlobalKey<_ReportSectionScreenState> _reportSectionKey = GlobalKey();

  void _switchMasterScreen(int subIndex) {
    setState(() {
      _selectedIndex = 1;
      _masterSubIndex = subIndex;
    });

    if (_masterSectionKey.currentState != null) {
      _masterSectionKey.currentState!.setState(() {
        _masterSectionKey.currentState!.masterSubIndex = subIndex;
      });
    }
  }

  void _switchEntryScreen(int subIndex) {
    setState(() {
      _selectedIndex = 2;
      _entrySubIndex = subIndex;
    });

    if (_entrySectionKey.currentState != null) {
      _entrySectionKey.currentState!.setState(() {
        _entrySectionKey.currentState!.entrySubIndex = subIndex;
      });
    }
  }

  void _switchReportScreen(int subIndex) {
    setState(() {
      _selectedIndex = 3;
      _reportSubIndex = subIndex;
    });

    if (_reportSectionKey.currentState != null) {
      _reportSectionKey.currentState!.setState(() {
        _reportSectionKey.currentState!.reportSubIndex = subIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;

    if (isWeb) {
      return Scaffold(
        body: Row(
          children: [
            // Sidebar Navigation for Web
            _buildWebSidebar(),
            // Main Content Area
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  const DashboardScreen(),
                  MasterSectionScreen(
                    key: _masterSectionKey,
                    initialSubIndex: _masterSubIndex,
                    onSubIndexChanged: (subIndex) {
                      setState(() {
                        _masterSubIndex = subIndex;
                      });
                    },
                  ),
                  EntrySectionScreen(
                    key: _entrySectionKey,
                    initialSubIndex: _entrySubIndex,
                    onSubIndexChanged: (subIndex) {
                      setState(() {
                        _entrySubIndex = subIndex;
                      });
                    },
                  ),
                  ReportSectionScreen(
                    key: _reportSectionKey,
                    initialSubIndex: _reportSubIndex,
                    onSubIndexChanged: (subIndex) {
                      setState(() {
                        _reportSubIndex = subIndex;
                      });
                    },
                  ),
                  const SettingsScreen(),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(_getScreenTitle()),
          backgroundColor: const Color(0xFF1E293B),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            const DashboardScreen(),
            MasterSectionScreen(
              key: _masterSectionKey,
              initialSubIndex: _masterSubIndex,
              onSubIndexChanged: (subIndex) {
                setState(() {
                  _masterSubIndex = subIndex;
                });
              },
            ),
            EntrySectionScreen(
              key: _entrySectionKey,
              initialSubIndex: _entrySubIndex,
              onSubIndexChanged: (subIndex) {
                setState(() {
                  _entrySubIndex = subIndex;
                });
              },
            ),
            ReportSectionScreen(
              key: _reportSectionKey,
              initialSubIndex: _reportSubIndex,
              onSubIndexChanged: (subIndex) {
                setState(() {
                  _reportSubIndex = subIndex;
                });
              },
            ),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              if (index != 1) {
                _masterSubIndex = 0; // Reset when leaving master section
              }
              if (index != 2) {
                _entrySubIndex = 0; // Reset when leaving entry section
              }
              if (index != 3) {
                _reportSubIndex = 0; // Reset when leaving report section
              }
            });
          },
          backgroundColor: const Color(0xFF1E293B),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[400],
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_special),
              label: 'Master',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_document),
              label: 'Entry',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              label: 'Settings',
              icon: Icon(Icons.settings),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildWebSidebar() {
    return Container(
      width: 240,
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          // App Title
          Container(
            padding: const EdgeInsets.all(20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finance System',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Loan Management',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.grey, height: 1),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildSidebarItem(0, Icons.dashboard, 'Dashboard'),

                // Master Section
                _buildMasterSection(),

                // Entry Section
                _buildEntrySection(),

                // Report Section
                _buildReportSection(),

                // _buildSidebarItem(4, Icons.settings, 'Settings'),
              ],
            ),
          ),

          // User Info
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: const BoxDecoration(
          //     border: Border(top: BorderSide(color: Colors.grey)),
          //   ),
          //   child: Row(
          //     children: [
          //       const CircleAvatar(
          //         radius: 20,
          //         child: Icon(Icons.person),
          //       ),
          //       const SizedBox(width: 12),
          //       const Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Text(
          //               'Admin User',
          //               style: TextStyle(
          //                 color: Colors.white,
          //                 fontWeight: FontWeight.w500,
          //               ),
          //             ),
          //             Text(
          //               'admin@example.com',
          //               style: TextStyle(
          //                 color: Colors.grey,
          //                 fontSize: 12,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //       IconButton(
          //         onPressed: () {},
          //         icon: const Icon(Icons.more_vert, color: Colors.grey),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildMasterSection() {
    final bool isMasterSelected = _selectedIndex == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isMasterSelected ? const Color(0xFF4318D1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: const Text(
          'Master',
          style: TextStyle(color: Colors.white),
        ),
        leading: const Icon(Icons.folder_special, color: Colors.white),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        initiallyExpanded: isMasterSelected,
        onExpansionChanged: (expanded) {
          if (expanded) {
            setState(() {
              _selectedIndex = 1;
            });
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: [
                _buildMasterSubItem(0, Icons.person_add, 'Customer Master'),
                _buildMasterSubItem(1, Icons.credit_card, 'Loan Type Master'),
                _buildMasterSubItem(2, Icons.account_balance, 'AC Ledger'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntrySection() {
    final bool isEntrySelected = _selectedIndex == 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isEntrySelected ? const Color(0xFF4318D1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: const Text(
          'Entry',
          style: TextStyle(color: Colors.white),
        ),
        leading: const Icon(Icons.edit_document, color: Colors.white),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        initiallyExpanded: isEntrySelected,
        onExpansionChanged: (expanded) {
          if (expanded) {
            setState(() {
              _selectedIndex = 2;
            });
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: [
                _buildEntrySubItem(0, Icons.receipt, 'Amount Receipt'),
                _buildEntrySubItem(1, Icons.monetization_on, 'Loan Issue'),
                _buildEntrySubItem(2, Icons.collections_bookmark, 'Collection Entry'),
                _buildEntrySubItem(3, Icons.account_balance_wallet, 'Account Closing'),
                _buildEntrySubItem(4, Icons.payment, 'Payment Entry'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSection() {
    final bool isReportSelected = _selectedIndex == 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isReportSelected ? const Color(0xFF4318D1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: const Text(
          'Reports',
          style: TextStyle(color: Colors.white),
        ),
        leading: const Icon(Icons.assessment, color: Colors.white),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        initiallyExpanded: isReportSelected,
        onExpansionChanged: (expanded) {
          if (expanded) {
            setState(() {
              _selectedIndex = 3;
            });
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: [
                // _buildReportSubItem(0, Icons.history, 'Loan History'),
                _buildReportSubItem(1, Icons.description, 'Outstanding Statement'),
                _buildReportSubItem(2, Icons.history_toggle_off, 'Collection History'),
                // _buildReportSubItem(3, Icons.account_balance_wallet, 'Cash Ledger'),
                // _buildReportSubItem(4, Icons.calendar_today, 'Due Datewise Pending'),
                _buildReportSubItem(5, Icons.list_alt, 'Datewise Loan Issue'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: _selectedIndex == index ? const Color(0xFF4318D1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildMasterSubItem(int subIndex, IconData icon, String label) {
    final bool isActive = _selectedIndex == 1 && _masterSubIndex == subIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF5F3DC4) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        contentPadding: const EdgeInsets.only(left: 16),
        onTap: () {
          _switchMasterScreen(subIndex);
        },
      ),
    );
  }

  Widget _buildEntrySubItem(int subIndex, IconData icon, String label) {
    final bool isActive = _selectedIndex == 2 && _entrySubIndex == subIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF5F3DC4) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        contentPadding: const EdgeInsets.only(left: 16),
        onTap: () {
          _switchEntryScreen(subIndex);
        },
      ),
    );
  }

  Widget _buildReportSubItem(int subIndex, IconData icon, String label) {
    final bool isActive = _selectedIndex == 3 && _reportSubIndex == subIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF5F3DC4) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        contentPadding: const EdgeInsets.only(left: 16),
        onTap: () {
          _switchReportScreen(subIndex);
        },
      ),
    );
  }

  String _getScreenTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return _getMasterScreenTitle();
      case 2:
        return _getEntryScreenTitle();
      case 3:
        return _getReportScreenTitle();
      case 4:
        return 'Settings';
      default:
        return 'Finance System';
    }
  }

  String _getMasterScreenTitle() {
    switch (_masterSubIndex) {
      case 0:
        return 'Customer Master';
      case 1:
        return 'Loan Type Master';
      case 2:
        return 'AC Ledger';
      default:
        return 'Master';
    }
  }

  String _getEntryScreenTitle() {
    switch (_entrySubIndex) {
      case 0:
        return 'Amount Receipt Entry';
      case 1:
        return 'Loan Issue';
      case 2:
        return 'Collection Entry';
      case 3:
        return 'Account Closing';
      case 4:
        return 'Payment Entry';
      default:
        return 'Entry';
    }
  }

  String _getReportScreenTitle() {
    switch (_reportSubIndex) {
      case 0:
        return 'Loan History Report';
      case 1:
        return 'Outstanding Statement Report';
      case 2:
        return 'Collection History Report';
      case 3:
        return 'Cash Ledger Report';
      case 4:
        return 'Due Datewise Pending Report';
      case 5:
        return 'Datewise Loan Issue List';
      default:
        return 'Reports';
    }
  }
}

// Master Section Wrapper Screen (unchanged)
class MasterSectionScreen extends StatefulWidget {
  final int initialSubIndex;
  final ValueChanged<int>? onSubIndexChanged;

  const MasterSectionScreen({
    Key? key,
    this.initialSubIndex = 0,
    this.onSubIndexChanged,
  }) : super(key: key);

  @override
  State<MasterSectionScreen> createState() => _MasterSectionScreenState();
}

class _MasterSectionScreenState extends State<MasterSectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int masterSubIndex = 0;

  @override
  void initState() {
    super.initState();
    masterSubIndex = widget.initialSubIndex;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: masterSubIndex,
    );

    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        masterSubIndex = _tabController.index;
      });

      widget.onSubIndexChanged?.call(masterSubIndex);
    }
  }

  void switchToSubScreen(int subIndex) {
    setState(() {
      masterSubIndex = subIndex;
    });

    if (_tabController.index != subIndex) {
      _tabController.animateTo(subIndex);
    }

    widget.onSubIndexChanged?.call(subIndex);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;

    if (!isWeb) {
      // Mobile: Show tabs at the top
      return Column(
        children: [
          Container(
            color: const Color(0xFF1E293B),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[400],
              isScrollable: true,
              tabs: const [
                Tab(
                  icon: Icon(Icons.person_add),
                  text: 'Customer',
                ),
                Tab(
                  icon: Icon(Icons.credit_card),
                  text: 'Loan Type',
                ),
                Tab(
                  icon: Icon(Icons.account_balance),
                  text: 'AC Ledger',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                CustomerListScreen(),
                LoanTypeListScreen(),
                ACLedgerListScreen(),
              ],
            ),
          ),
        ],
      );
    } else {
      // Web: Show selected screen
      return IndexedStack(
        index: masterSubIndex,
        children: const [
          CustomerListScreen(),
          LoanTypeListScreen(),
          ACLedgerListScreen(),
        ],
      );
    }
  }
}

// Entry Section Wrapper Screen (unchanged)
class EntrySectionScreen extends StatefulWidget {
  final int initialSubIndex;
  final ValueChanged<int>? onSubIndexChanged;

  const EntrySectionScreen({
    Key? key,
    this.initialSubIndex = 0,
    this.onSubIndexChanged,
  }) : super(key: key);

  @override
  State<EntrySectionScreen> createState() => _EntrySectionScreenState();
}

class _EntrySectionScreenState extends State<EntrySectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int entrySubIndex = 0;

  @override
  void initState() {
    super.initState();
    entrySubIndex = widget.initialSubIndex;
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: entrySubIndex,
    );

    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        entrySubIndex = _tabController.index;
      });

      widget.onSubIndexChanged?.call(entrySubIndex);
    }
  }

  void switchToSubScreen(int subIndex) {
    setState(() {
      entrySubIndex = subIndex;
    });

    if (_tabController.index != subIndex) {
      _tabController.animateTo(subIndex);
    }

    widget.onSubIndexChanged?.call(subIndex);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;

    if (!isWeb) {
      // Mobile: Show tabs at the top
      return Column(
        children: [
          Container(
            color: const Color(0xFF1E293B),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[400],
              isScrollable: true,
              tabs: const [
                Tab(
                  icon: Icon(Icons.receipt),
                  text: 'Amount Receipt',
                ),
                Tab(
                  icon: Icon(Icons.monetization_on),
                  text: 'Loan Issue',
                ),
                Tab(
                  icon: Icon(Icons.collections_bookmark),
                  text: 'Collection',
                ),
                Tab(
                  icon: Icon(Icons.account_balance_wallet),
                  text: 'Account Closing',
                ),
                Tab(
                  icon: Icon(Icons.payment),
                  text: 'Payment',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const ReceiptEntryListScreen(),
                const LoanListScreen(),
                const CollectionListScreen(),
                const AccountClosingListScreen(),
                const PaymentEntryListScreen(),
              ],
            ),
          ),
        ],
      );
    } else {
      // Web: Show selected screen
      return IndexedStack(
        index: entrySubIndex,
        children: [
          const ReceiptEntryListScreen(),
          const LoanListScreen(),
          const CollectionListScreen(),
          const AccountClosingListScreen(),
          const PaymentEntryListScreen(),
        ],
      );
    }
  }
}

// Report Section Wrapper Screen
class ReportSectionScreen extends StatefulWidget {
  final int initialSubIndex;
  final ValueChanged<int>? onSubIndexChanged;

  const ReportSectionScreen({
    Key? key,
    this.initialSubIndex = 0,
    this.onSubIndexChanged,
  }) : super(key: key);

  @override
  State<ReportSectionScreen> createState() => _ReportSectionScreenState();
}

class _ReportSectionScreenState extends State<ReportSectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int reportSubIndex = 0;

  @override
  void initState() {
    super.initState();
    reportSubIndex = widget.initialSubIndex;
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: reportSubIndex,
    );

    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        reportSubIndex = _tabController.index;
      });

      widget.onSubIndexChanged?.call(reportSubIndex);
    }
  }

  void switchToSubScreen(int subIndex) {
    setState(() {
      reportSubIndex = subIndex;
    });

    if (_tabController.index != subIndex) {
      _tabController.animateTo(subIndex);
    }

    widget.onSubIndexChanged?.call(subIndex);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;

    if (!isWeb) {
      // Mobile: Show tabs at the top
      return Column(
        children: [
          Container(
            color: const Color(0xFF1E293B),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[400],
              isScrollable: true,
              tabs: const [
                // Tab(
                //   icon: Icon(Icons.history),
                //   text: 'Loan History',
                // ),
                Tab(
                  icon: Icon(Icons.description),
                  text: 'Outstanding',
                ),
                Tab(
                  icon: Icon(Icons.history_toggle_off),
                  text: 'Collection History',
                ),
                Tab(
                  icon: Icon(Icons.account_balance_wallet),
                  text: 'Cash Ledger',
                ),
                Tab(
                  icon: Icon(Icons.calendar_today),
                  text: 'Due Datewise',
                ),
                Tab(
                  icon: Icon(Icons.list_alt),
                  text: 'Datewise Loan Issue',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                LoanHistoryReportScreen(),
                OutstandingReportScreen(),
                CollectionHistoryReportScreen(),
                CashLedgerReportScreen(),
                DueDatewisePendingReportScreen(),
                DateWiseLoanIssueReportScreen(),
              ],
            ),
          ),
        ],
      );
    } else {
      // Web: Show selected screen
      return IndexedStack(
        index: reportSubIndex,
        children: [
          LoanHistoryReportScreen(),
          OutstandingReportScreen(),
          CollectionHistoryReportScreen(),
          CashLedgerReportScreen(),
          DueDatewisePendingReportScreen(),
          DateWiseLoanIssueReportScreen(),
        ],
      );
    }
  }
}

// import 'package:financeapp/screens/payment_entry_list_screen.dart';
// import 'package:financeapp/screens/receipt_entry_list_screen.dart';
// import 'package:financeapp/screens/reports_screen.dart';
// import 'package:financeapp/screens/settings_screen.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
//
// import 'CustomerListScreen.dart';
// import 'ac_ledger_list_screen.dart';
// import 'account_closing_list_screen.dart';
// import 'collection_list_screen.dart';
// import 'dashboardscreen.dart';
// import 'loan_issue_screen.dart';
// import 'loan_list_screen.dart';
// import 'loan_type_list_screen.dart';
// import 'loan_type_master_screen.dart';
//
// // Import the new Entry screens (you'll need to create these)
// import 'amount_receipt_entry_screen.dart';
// import 'collection_entry_screen.dart';
// import 'account_closing_screen.dart';
// import 'payment_entry_screen.dart';
//
//
//
// class CustomerManagementApp extends StatefulWidget {
//   const CustomerManagementApp({super.key});
//
//   @override
//   State<CustomerManagementApp> createState() => _CustomerManagementAppState();
// }
//
// class _CustomerManagementAppState extends State<CustomerManagementApp> {
//   int _selectedIndex = 0;
//   int _masterSubIndex = 0; // 0: Customer Master, 1: Loan Type Master, 2: AC Ledger
//   int _entrySubIndex = 0; // 0: Amount Receipt, 1: Loan Issue, 2: Collection Entry, 3: Account Closing, 4: Payment Entry
//
//   // Create GlobalKey for MasterSectionScreen and EntrySectionScreen
//   final GlobalKey<_MasterSectionScreenState> _masterSectionKey = GlobalKey();
//   final GlobalKey<_EntrySectionScreenState> _entrySectionKey = GlobalKey();
//
//   void _switchMasterScreen(int subIndex) {
//     setState(() {
//       _selectedIndex = 1;
//       _masterSubIndex = subIndex;
//     });
//
//     if (_masterSectionKey.currentState != null) {
//       _masterSectionKey.currentState!.setState(() {
//         _masterSectionKey.currentState!.masterSubIndex = subIndex;
//       });
//     }
//   }
//
//   void _switchEntryScreen(int subIndex) {
//     setState(() {
//       _selectedIndex = 2;
//       _entrySubIndex = subIndex;
//     });
//
//     if (_entrySectionKey.currentState != null) {
//       _entrySectionKey.currentState!.setState(() {
//         _entrySectionKey.currentState!.entrySubIndex = subIndex;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;
//
//     if (isWeb) {
//       return Scaffold(
//         body: Row(
//           children: [
//             // Sidebar Navigation for Web
//             _buildWebSidebar(),
//             // Main Content Area
//             Expanded(
//               child: IndexedStack(
//                 index: _selectedIndex,
//                 children: [
//                   const DashboardScreen(),
//                   MasterSectionScreen(
//                     key: _masterSectionKey,
//                     initialSubIndex: _masterSubIndex,
//                     onSubIndexChanged: (subIndex) {
//                       setState(() {
//                         _masterSubIndex = subIndex;
//                       });
//                     },
//                   ),
//                   EntrySectionScreen(
//                     key: _entrySectionKey,
//                     initialSubIndex: _entrySubIndex,
//                     onSubIndexChanged: (subIndex) {
//                       setState(() {
//                         _entrySubIndex = subIndex;
//                       });
//                     },
//                   ),
//                   const ReportsScreen(),
//                   const SettingsScreen(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     } else {
//       return Scaffold(
//         appBar: AppBar(
//           title: Text(_getScreenTitle()),
//           backgroundColor: const Color(0xFF1E293B),
//         ),
//         body: IndexedStack(
//           index: _selectedIndex,
//           children: [
//             const DashboardScreen(),
//             MasterSectionScreen(
//               key: _masterSectionKey,
//               initialSubIndex: _masterSubIndex,
//               onSubIndexChanged: (subIndex) {
//                 setState(() {
//                   _masterSubIndex = subIndex;
//                 });
//               },
//             ),
//             EntrySectionScreen(
//               key: _entrySectionKey,
//               initialSubIndex: _entrySubIndex,
//               onSubIndexChanged: (subIndex) {
//                 setState(() {
//                   _entrySubIndex = subIndex;
//                 });
//               },
//             ),
//             const ReportsScreen(),
//             const SettingsScreen(),
//           ],
//         ),
//         bottomNavigationBar: BottomNavigationBar(
//           type: BottomNavigationBarType.fixed,
//           currentIndex: _selectedIndex,
//           onTap: (index) {
//             setState(() {
//               _selectedIndex = index;
//               if (index != 1) {
//                 _masterSubIndex = 0; // Reset when leaving master section
//               }
//               if (index != 2) {
//                 _entrySubIndex = 0; // Reset when leaving entry section
//               }
//             });
//           },
//           backgroundColor: const Color(0xFF1E293B),
//           selectedItemColor: Colors.white,
//           unselectedItemColor: Colors.grey[400],
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.dashboard),
//               label: 'Dashboard',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.folder_special),
//               label: 'Master',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.edit_document),
//               label: 'Entry',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.assessment),
//               label: 'Reports',
//             ),
//             BottomNavigationBarItem(
//               label: 'Settings',
//               icon: Icon(Icons.settings),
//             ),
//           ],
//         ),
//       );
//     }
//   }
//
//   Widget _buildWebSidebar() {
//     return Container(
//       width: 240,
//       color: const Color(0xFF1E293B),
//       child: Column(
//         children: [
//           // App Title
//           Container(
//             padding: const EdgeInsets.all(20),
//             child: const Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Finance System',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   'Loan Management',
//                   style: TextStyle(
//                     color: Colors.grey,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           const Divider(color: Colors.grey, height: 1),
//
//           // Navigation Items
//           Expanded(
//             child: ListView(
//               padding: const EdgeInsets.all(12),
//               children: [
//                 _buildSidebarItem(0, Icons.dashboard, 'Dashboard'),
//
//                 // Master Section
//                 _buildMasterSection(),
//
//                 // Entry Section
//                 _buildEntrySection(),
//
//                 _buildSidebarItem(3, Icons.assessment, 'Reports'),
//                 _buildSidebarItem(4, Icons.settings, 'Settings'),
//               ],
//             ),
//           ),
//
//           // User Info
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: const BoxDecoration(
//               border: Border(top: BorderSide(color: Colors.grey)),
//             ),
//             child: Row(
//               children: [
//                 const CircleAvatar(
//                   radius: 20,
//                   child: Icon(Icons.person),
//                 ),
//                 const SizedBox(width: 12),
//                 const Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Admin User',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       Text(
//                         'admin@example.com',
//                         style: TextStyle(
//                           color: Colors.grey,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: () {},
//                   icon: const Icon(Icons.more_vert, color: Colors.grey),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMasterSection() {
//     final bool isMasterSelected = _selectedIndex == 1;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 4),
//       decoration: BoxDecoration(
//         color: isMasterSelected ? const Color(0xFF4318D1) : Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ExpansionTile(
//         title: const Text(
//           'Master',
//           style: TextStyle(color: Colors.white),
//         ),
//         leading: const Icon(Icons.folder_special, color: Colors.white),
//         backgroundColor: Colors.transparent,
//         collapsedBackgroundColor: Colors.transparent,
//         initiallyExpanded: isMasterSelected,
//         onExpansionChanged: (expanded) {
//           if (expanded) {
//             setState(() {
//               _selectedIndex = 1;
//             });
//           }
//         },
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(left: 16),
//             child: Column(
//               children: [
//                 _buildMasterSubItem(0, Icons.person_add, 'Customer Master'),
//                 _buildMasterSubItem(1, Icons.credit_card, 'Loan Type Master'),
//                 _buildMasterSubItem(2, Icons.account_balance, 'AC Ledger'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEntrySection() {
//     final bool isEntrySelected = _selectedIndex == 2;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 4),
//       decoration: BoxDecoration(
//         color: isEntrySelected ? const Color(0xFF4318D1) : Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ExpansionTile(
//         title: const Text(
//           'Entry',
//           style: TextStyle(color: Colors.white),
//         ),
//         leading: const Icon(Icons.edit_document, color: Colors.white),
//         backgroundColor: Colors.transparent,
//         collapsedBackgroundColor: Colors.transparent,
//         initiallyExpanded: isEntrySelected,
//         onExpansionChanged: (expanded) {
//           if (expanded) {
//             setState(() {
//               _selectedIndex = 2;
//             });
//           }
//         },
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(left: 16),
//             child: Column(
//               children: [
//                 _buildEntrySubItem(0, Icons.receipt, 'Amount Receipt'),
//                 _buildEntrySubItem(1, Icons.monetization_on, 'Loan Issue'),
//                 _buildEntrySubItem(2, Icons.collections_bookmark, 'Collection Entry'),
//                 _buildEntrySubItem(3, Icons.account_balance_wallet, 'Account Closing'),
//                 _buildEntrySubItem(4, Icons.payment, 'Payment Entry'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSidebarItem(int index, IconData icon, String label) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 4),
//       decoration: BoxDecoration(
//         color: _selectedIndex == index ? const Color(0xFF4318D1) : Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ListTile(
//         leading: Icon(icon, color: Colors.white),
//         title: Text(
//           label,
//           style: const TextStyle(color: Colors.white),
//         ),
//         onTap: () {
//           setState(() {
//             _selectedIndex = index;
//           });
//         },
//       ),
//     );
//   }
//
//   Widget _buildMasterSubItem(int subIndex, IconData icon, String label) {
//     final bool isActive = _selectedIndex == 1 && _masterSubIndex == subIndex;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 4),
//       decoration: BoxDecoration(
//         color: isActive ? const Color(0xFF5F3DC4) : Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ListTile(
//         leading: Icon(icon, color: Colors.white),
//         title: Text(
//           label,
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 14,
//             fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
//           ),
//         ),
//         contentPadding: const EdgeInsets.only(left: 16),
//         onTap: () {
//           _switchMasterScreen(subIndex);
//         },
//       ),
//     );
//   }
//
//   Widget _buildEntrySubItem(int subIndex, IconData icon, String label) {
//     final bool isActive = _selectedIndex == 2 && _entrySubIndex == subIndex;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 4),
//       decoration: BoxDecoration(
//         color: isActive ? const Color(0xFF5F3DC4) : Colors.transparent,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ListTile(
//         leading: Icon(icon, color: Colors.white),
//         title: Text(
//           label,
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 14,
//             fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
//           ),
//         ),
//         contentPadding: const EdgeInsets.only(left: 16),
//         onTap: () {
//           _switchEntryScreen(subIndex);
//         },
//       ),
//     );
//   }
//
//   String _getScreenTitle() {
//     switch (_selectedIndex) {
//       case 0:
//         return 'Dashboard';
//       case 1:
//         return _getMasterScreenTitle();
//       case 2:
//         return _getEntryScreenTitle();
//       case 3:
//         return 'Reports';
//       case 4:
//         return 'Settings';
//       default:
//         return 'Finance System';
//     }
//   }
//
//   String _getMasterScreenTitle() {
//     switch (_masterSubIndex) {
//       case 0:
//         return 'Customer Master';
//       case 1:
//         return 'Loan Type Master';
//       case 2:
//         return 'AC Ledger';
//       default:
//         return 'Master';
//     }
//   }
//
//   String _getEntryScreenTitle() {
//     switch (_entrySubIndex) {
//       case 0:
//         return 'Amount Receipt Entry';
//       case 1:
//         return 'Loan Issue';
//       case 2:
//         return 'Collection Entry';
//       case 3:
//         return 'Account Closing';
//       case 4:
//         return 'Payment Entry';
//       default:
//         return 'Entry';
//     }
//   }
// }
//
// // Master Section Wrapper Screen (updated for 3 tabs)
// class MasterSectionScreen extends StatefulWidget {
//   final int initialSubIndex;
//   final ValueChanged<int>? onSubIndexChanged;
//
//   const MasterSectionScreen({
//     Key? key,
//     this.initialSubIndex = 0,
//     this.onSubIndexChanged,
//   }) : super(key: key);
//
//   @override
//   State<MasterSectionScreen> createState() => _MasterSectionScreenState();
// }
//
// class _MasterSectionScreenState extends State<MasterSectionScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   int masterSubIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     masterSubIndex = widget.initialSubIndex;
//     _tabController = TabController(
//       length: 3, // Changed from 2 to 3
//       vsync: this,
//       initialIndex: masterSubIndex,
//     );
//
//     _tabController.addListener(_handleTabChange);
//   }
//
//   void _handleTabChange() {
//     if (!_tabController.indexIsChanging) {
//       setState(() {
//         masterSubIndex = _tabController.index;
//       });
//
//       widget.onSubIndexChanged?.call(masterSubIndex);
//     }
//   }
//
//   void switchToSubScreen(int subIndex) {
//     setState(() {
//       masterSubIndex = subIndex;
//     });
//
//     if (_tabController.index != subIndex) {
//       _tabController.animateTo(subIndex);
//     }
//
//     widget.onSubIndexChanged?.call(subIndex);
//   }
//
//   @override
//   void dispose() {
//     _tabController.removeListener(_handleTabChange);
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;
//
//     if (!isWeb) {
//       // Mobile: Show tabs at the top
//       return Column(
//         children: [
//           Container(
//             color: const Color(0xFF1E293B),
//             child: TabBar(
//               controller: _tabController,
//               indicatorColor: Colors.white,
//               labelColor: Colors.white,
//               unselectedLabelColor: Colors.grey[400],
//               isScrollable: true, // Allow scrolling for 3 tabs
//               tabs: const [
//                 Tab(
//                   icon: Icon(Icons.person_add),
//                   text: 'Customer',
//                 ),
//                 Tab(
//                   icon: Icon(Icons.credit_card),
//                   text: 'Loan Type',
//                 ),
//                 Tab(
//                   icon: Icon(Icons.account_balance),
//                   text: 'AC Ledger',
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: const [
//                 CustomerListScreen(),
//                 LoanTypeListScreen(),
//                 ACLedgerListScreen(), // New AC Ledger screen
//               ],
//             ),
//           ),
//         ],
//       );
//     } else {
//       // Web: Show selected screen
//       return IndexedStack(
//         index: masterSubIndex,
//         children: const [
//           CustomerListScreen(),
//           LoanTypeListScreen(),
//           ACLedgerListScreen(), // New AC Ledger screen
//         ],
//       );
//     }
//   }
// }
//
// // Entry Section Wrapper Screen (unchanged)
// class EntrySectionScreen extends StatefulWidget {
//   final int initialSubIndex;
//   final ValueChanged<int>? onSubIndexChanged;
//
//   const EntrySectionScreen({
//     Key? key,
//     this.initialSubIndex = 0,
//     this.onSubIndexChanged,
//   }) : super(key: key);
//
//   @override
//   State<EntrySectionScreen> createState() => _EntrySectionScreenState();
// }
//
// class _EntrySectionScreenState extends State<EntrySectionScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   int entrySubIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     entrySubIndex = widget.initialSubIndex;
//     _tabController = TabController(
//       length: 5,
//       vsync: this,
//       initialIndex: entrySubIndex,
//     );
//
//     _tabController.addListener(_handleTabChange);
//   }
//
//   void _handleTabChange() {
//     if (!_tabController.indexIsChanging) {
//       setState(() {
//         entrySubIndex = _tabController.index;
//       });
//
//       widget.onSubIndexChanged?.call(entrySubIndex);
//     }
//   }
//
//   void switchToSubScreen(int subIndex) {
//     setState(() {
//       entrySubIndex = subIndex;
//     });
//
//     if (_tabController.index != subIndex) {
//       _tabController.animateTo(subIndex);
//     }
//
//     widget.onSubIndexChanged?.call(subIndex);
//   }
//
//   @override
//   void dispose() {
//     _tabController.removeListener(_handleTabChange);
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;
//
//     if (!isWeb) {
//       // Mobile: Show tabs at the top
//       return Column(
//         children: [
//           Container(
//             color: const Color(0xFF1E293B),
//             child: TabBar(
//               controller: _tabController,
//               indicatorColor: Colors.white,
//               labelColor: Colors.white,
//               unselectedLabelColor: Colors.grey[400],
//               isScrollable: true, // Allow scrolling for many tabs
//               tabs: const [
//                 Tab(
//                   icon: Icon(Icons.receipt),
//                   text: 'Amount Receipt',
//                 ),
//                 Tab(
//                   icon: Icon(Icons.monetization_on),
//                   text: 'Loan Issue',
//                 ),
//                 Tab(
//                   icon: Icon(Icons.collections_bookmark),
//                   text: 'Collection',
//                 ),
//                 Tab(
//                   icon: Icon(Icons.account_balance_wallet),
//                   text: 'Account Closing',
//                 ),
//                 Tab(
//                   icon: Icon(Icons.payment),
//                   text: 'Payment',
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: [
//                 const ReceiptEntryListScreen(),
//                 const LoanListScreen(), // You already have this
//                 const CollectionListScreen(),
//                 const AccountClosingListScreen(),
//                 const PaymentEntryListScreen(),
//               ],
//             ),
//           ),
//         ],
//       );
//     } else {
//       // Web: Show selected screen
//       return IndexedStack(
//         index: entrySubIndex,
//         children: [
//           const ReceiptEntryListScreen(),
//           const LoanListScreen(),
//           const CollectionListScreen(),
//           const AccountClosingListScreen(),
//           const PaymentEntryListScreen(),
//         ],
//       );
//     }
//   }
// }
//
//

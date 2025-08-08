import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
import 'package:smart_mess/services/admin_auth_service.dart';

import 'admin_home_screen.dart';
import 'admin_users_screen.dart';
import 'admin_pending_ids_screen.dart';
import 'admin_shopping_history.dart';
import 'admin_voucher_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_messing_screen.dart';
import 'admin_staff_state_screen.dart';
import 'admin_dining_member_state.dart';
import 'admin_bill_screen.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_menu_vote_screen.dart';
import 'admin_meal_state_screen.dart';
import 'transaction.dart';
import 'admin_login_screen.dart';

class PaymentsDashboard extends StatefulWidget {
  const PaymentsDashboard({super.key});

  @override
  State<PaymentsDashboard> createState() => _PaymentsDashboardState();
}

class _PaymentsDashboardState extends State<PaymentsDashboard> {
  final AdminAuthService _adminAuthService = AdminAuthService();
  bool _isLoading = true;
  String _currentUserName = "Loading...";
  Map<String, dynamic>? _currentUserData;

  int? editingIndex;
  List<TextEditingController> controllers = [];

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final isLoggedIn = await _adminAuthService.isAdminLoggedIn();
      if (!isLoggedIn) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
          );
        }
        return;
      }

      final userData = await _adminAuthService.getCurrentAdminData();
      if (mounted) {
        setState(() {
          _currentUserData = userData;
          _currentUserName = userData?['name'] ?? 'Admin';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
        );
      }
    }
  }

  final List<PaymentData> transactions = [
    PaymentData(
      amount: 3500.00,
      paymentTime: DateTime.now().subtract(const Duration(hours: 2)),
      paymentMethod: 'Bkash',
      baNo: 'BA-1234',
      rank: 'Major',
      name: 'John Smith',
    ),
    PaymentData(
      amount: 2950.00,
      paymentTime: DateTime.now().subtract(const Duration(hours: 5)),
      paymentMethod: 'Bank',
      baNo: 'BA-5678',
      rank: 'Captain',
      name: 'Sarah Johnson',
    ),
    PaymentData(
      amount: 4200.00,
      paymentTime: DateTime.now().subtract(const Duration(days: 1)),
      paymentMethod: 'Card',
      baNo: 'BA-9012',
      rank: 'Lieutenant',
      name: 'David Wilson',
    ),
    PaymentData(
      amount: 3100.00,
      paymentTime: DateTime.now().subtract(const Duration(days: 2)),
      paymentMethod: 'Cash',
      baNo: 'BA-3456',
      rank: 'Major',
      name: 'Michael Brown',
    ),
    PaymentData(
      amount: 2800.00,
      paymentTime: DateTime.now().subtract(const Duration(days: 2)),
      paymentMethod: 'Tap',
      baNo: 'BA-7890',
      rank: 'Captain',
      name: 'Emma Davis',
    ),
  ];

  String searchQuery = '';
  void _editTransaction(int index) {
    setState(() {
      editingIndex = index;
      final txn = transactions[index];
      controllers = [
        TextEditingController(text: txn.amount.toString()),
        TextEditingController(text: txn.paymentTime.toString()),
        TextEditingController(text: txn.paymentMethod),
        TextEditingController(text: txn.baNo),
        TextEditingController(text: txn.rank),
        TextEditingController(text: txn.name),
      ];
    });
  }

  void _saveTransaction(int index) {
    if (controllers.any((controller) => controller.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All fields are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(controllers[0].text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid payment amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      final DateTime paymentTime = DateTime.tryParse(controllers[1].text) ??
          transactions[index].paymentTime;
      transactions[index] = PaymentData(
        amount: amount,
        paymentTime: paymentTime,
        paymentMethod: controllers[2].text,
        baNo: controllers[3].text,
        rank: controllers[4].text,
        name: controllers[5].text,
      );
      editingIndex = null;
      controllers.clear();
    });
  }

  void _cancelEdit() {
    setState(() {
      editingIndex = null;
      controllers.clear();
    });
  }

  void _deleteTransaction(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDelete),
        content:
            Text('${AppLocalizations.of(context)!.areYouSureYouWantToDelete} this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                transactions.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await _adminAuthService.logoutAdmin();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  void _navigate(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _buildSidebarTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.blue.shade100,
      child: ListTile(
        selected: selected,
        selectedTileColor: Colors.blue.shade100,
        leading: Icon(
          icon,
          color: color ?? (selected ? Colors.blue : Colors.black),
        ),
        title: Text(title, style: TextStyle(color: color ?? Colors.black)),
      ),
    );
  }

  // Helper method to build flag toggle
  Widget _buildFlagToggle(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return GestureDetector(
          onTap: () {
            languageProvider.changeLanguage(
              languageProvider.currentLocale.languageCode == 'en' 
                ? const Locale('bn') 
                : const Locale('en')
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: CustomPaint(
              size: const Size(32, 20),
              painter: languageProvider.currentLocale.languageCode == 'en'
                  ? BangladeshFlagPainter()
                  : EnglandFlagPainter(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        if (_isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

    final filtered = transactions.where((txn) {
      final searchLower = searchQuery.toLowerCase();
      return txn.name.toLowerCase().contains(searchLower) ||
          txn.baNo.toLowerCase().contains(searchLower) ||
          txn.rank.toLowerCase().contains(searchLower) ||
          txn.paymentMethod.toLowerCase().contains(searchLower);
    }).toList();

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF002B5B), Color(0xFF1A4D8F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundImage: AssetImage('assets/me.png'),
                    radius: 30,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentUserName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_currentUserData != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _currentUserData!['role'] ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'BA: ${_currentUserData!['ba_no'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSidebarTile(
                    icon: Icons.dashboard,
                    title: AppLocalizations.of(context)!.home,
                    onTap: () => _navigate(const AdminHomeScreen()),
                  ),
                  _buildSidebarTile(
                    icon: Icons.people,
                    title: AppLocalizations.of(context)!.users,
                    onTap: () => _navigate(const AdminUsersScreen()),
                  ),
                  _buildSidebarTile(
                    icon: Icons.pending,
                    title: AppLocalizations.of(context)!.pendingIds,
                    onTap: () => _navigate(const AdminPendingIdsScreen()),
                  ),
                  _buildSidebarTile(
                    icon: Icons.history,
                    title: AppLocalizations.of(context)!.shoppingHistory,
                    onTap: () => _navigate(const AdminShoppingHistoryScreen()),
                  ),
                  _buildSidebarTile(
                    icon: Icons.receipt,
                    title: AppLocalizations.of(context)!.voucherList,
                    onTap: () => _navigate(const AdminVoucherScreen()),
                  ),
                  _buildSidebarTile(
                    icon: Icons.storage,
                    title: AppLocalizations.of(context)!.inventory,
                    onTap: () => _navigate(const AdminInventoryScreen()),
                  ),
                  _buildSidebarTile(
                    icon: Icons.food_bank,
                    title: AppLocalizations.of(context)!.messing,
                    onTap: () => _navigate(const AdminMessingScreen()),
                  ),
                  _buildSidebarTile(
                    icon: Icons.menu_book,
                    title: AppLocalizations.of(context)!.monthlyMenu,
                    onTap: () => _navigate(const EditMenuScreen()),
                  ),
                  _buildSidebarTile(
                    icon: Icons.analytics,
                    title: AppLocalizations.of(context)!.mealState,
                    onTap: () => _navigate(const AdminMealStateScreen()),
                  ),
                  _buildSidebarTile(
                    icon: Icons.thumb_up,
                    title: AppLocalizations.of(context)!.menuVote,
                    onTap: () => _navigate(const MenuVoteScreen()),
                  ),
                  _buildSidebarTile(
                    icon: Icons.receipt_long,
                    title: AppLocalizations.of(context)!.bills,
                    onTap: () => _navigate(const AdminBillScreen()),
                  ),
                  _buildSidebarTile(
                    icon: Icons.payment,
                    title: AppLocalizations.of(context)!.payments,
                    selected: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildSidebarTile(
                    icon: Icons.people_alt,
                    title: AppLocalizations.of(context)!.diningMemberState,
                    onTap: () => _navigate(const DiningMemberStatePage()),
                  ),
                  _buildSidebarTile(
                    icon: Icons.manage_accounts,
                    title: AppLocalizations.of(context)!.staffState,
                    onTap: () => _navigate(const AdminStaffStateScreen()),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                  top: 8,
                ),
                child: _buildSidebarTile(
                  icon: Icons.logout,
                  title: AppLocalizations.of(context)!.logout,
                  onTap: _logout,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.paymentsHistory,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          _buildFlagToggle(context),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.search,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    onChanged: (val) => setState(() => searchQuery = val),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final newTransaction = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InsertTransactionScreen(),
                      ),
                    );

                    if (newTransaction != null &&
                        newTransaction is PaymentData) {
                      setState(() {
                        transactions.add(newTransaction);
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: Text(AppLocalizations.of(context)!.insertTransaction),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFFF4F4F4)),
                    columns: [
                      DataColumn(
                          label: Text(AppLocalizations.of(context)!.paymentAmountBdt,
                              style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text(AppLocalizations.of(context)!.paymentTime,
                              style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text(AppLocalizations.of(context)!.paymentMethod,
                              style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text(AppLocalizations.of(context)!.baNo,
                              style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text(AppLocalizations.of(context)!.rank,
                              style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text(AppLocalizations.of(context)!.name,
                              style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text(AppLocalizations.of(context)!.actions,
                              style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: List.generate(filtered.length, (index) {
                      final txn = filtered[index];
                      final isEditing = editingIndex == index;

                      return DataRow(cells: [
                        DataCell(
                          isEditing
                              ? TextField(
                                  controller: controllers[0],
                                  decoration:
                                      const InputDecoration(isDense: true))
                              : Text('${txn.amount} BDT'),
                        ),
                        DataCell(
                          isEditing
                              ? TextField(
                                  controller: controllers[1],
                                  decoration:
                                      const InputDecoration(isDense: true))
                              : Text(txn.paymentTime.toString()),
                        ),
                        DataCell(
                          isEditing
                              ? DropdownButtonFormField<String>(
                                  value: controllers[2].text,
                                  items:
                                      ['Bank', 'Card', 'Bkash', 'Tap', 'Cash']
                                          .map((method) => DropdownMenuItem(
                                                value: method,
                                                child: Text(method),
                                              ))
                                          .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        controllers[2].text = val;
                                      });
                                    }
                                  },
                                  decoration:
                                      const InputDecoration(isDense: true),
                                )
                              : Text(txn.paymentMethod),
                        ),
                        DataCell(
                          isEditing
                              ? TextField(
                                  controller: controllers[3],
                                  decoration:
                                      const InputDecoration(isDense: true))
                              : Text(txn.baNo),
                        ),
                        DataCell(
                          isEditing
                              ? TextField(
                                  controller: controllers[4],
                                  decoration:
                                      const InputDecoration(isDense: true))
                              : Text(txn.rank),
                        ),
                        DataCell(
                          isEditing
                              ? TextField(
                                  controller: controllers[5],
                                  decoration:
                                      const InputDecoration(isDense: true))
                              : Text(txn.name),
                        ),
                        DataCell(Row(
                          children: isEditing
                              ? [
                                  IconButton(
                                    icon: const Icon(Icons.save,
                                        color: Colors.green),
                                    onPressed: () => _saveTransaction(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel,
                                        color: Colors.grey),
                                    onPressed: _cancelEdit,
                                  ),
                                ]
                              : [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _editTransaction(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteTransaction(index),
                                  ),
                                ],
                        )),
                      ]);
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}

// Flag painter classes
class EnglandFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint whitePaint = Paint()..color = Colors.white;
    final Paint redPaint = Paint()..color = Colors.red;

    // White background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), whitePaint);

    // Red cross
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.4, 0, size.width * 0.2, size.height),
        redPaint);
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.2),
        redPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class BangladeshFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint greenPaint = Paint()..color = const Color(0xFF006A4E);
    final Paint redPaint = Paint()..color = const Color(0xFFF42A41);

    // Green background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), greenPaint);

    // Red circle (offset slightly to the left)
    final double radius = size.height * 0.3;
    final Offset center = Offset(size.width * 0.4, size.height * 0.5);
    canvas.drawCircle(center, radius, redPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

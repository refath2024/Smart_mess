import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'admin_login_screen.dart';
import 'add_transaction.dart';

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

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadPaymentRequests();
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

  List<Map<String, dynamic>> paymentRequests = [];
  String searchQuery = '';

  Future<void> _loadPaymentRequests() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('payment_history').get();

      List<Map<String, dynamic>> requests = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Process each transaction in the document
        for (String key in data.keys) {
          if (key.contains('_transaction_')) {
            final transactionData = data[key] as Map<String, dynamic>;
            requests.add({
              'id': '${doc.id}_$key',
              'ba_no': transactionData['ba_no'],
              'amount': transactionData['amount'],
              'payment_method': transactionData['payment_method'],
              'rank': transactionData['rank'],
              'name': transactionData['name'],
              'status': transactionData['status'],
              'request_time': transactionData['request_time'],
              'phone_number': transactionData['phone_number'] ?? '',
              'transaction_id': transactionData['transaction_id'] ?? '',
              'account_no': transactionData['account_no'] ?? '',
              'bank_name': transactionData['bank_name'] ?? '',
              'card_number': transactionData['card_number'] ?? '',
              'expiry_date': transactionData['expiry_date'] ?? '',
              'cvv': transactionData['cvv'] ?? '',
            });
          }
        }
      }

      setState(() {
        paymentRequests = requests;
      });
    } catch (e) {
      print('Error loading payment requests: $e');
    }
  }

  Future<void> _approvePayment(Map<String, dynamic> request) async {
    try {
      final parts = request['id'].split('_');
      final baNo = parts[0];
      final transactionKey = '${parts[1]}_${parts[2]}_${parts[3]}';

      // Update payment request status
      await FirebaseFirestore.instance
          .collection('payment_history')
          .doc(baNo)
          .update({
        '$transactionKey.status': 'approved',
        '$transactionKey.approved_at': FieldValue.serverTimestamp(),
      });

      // Update bill with paid amount and recalculate total due
      final now = DateTime.now();
      final monthYear = "${_getMonthName(now.month)} ${now.year}";

      final billRef =
          FirebaseFirestore.instance.collection('Bills').doc(monthYear);

      final billDoc = await billRef.get();
      if (billDoc.exists) {
        final billData = billDoc.data() as Map<String, dynamic>;
        final userBill = billData[baNo] as Map<String, dynamic>?;

        if (userBill != null) {
          final currentPaidAmount = userBill['paid_amount']?.toDouble() ?? 0.0;
          final newPaidAmount = currentPaidAmount + request['amount'];

          // Get current bill and arrears for calculation
          final currentBill = userBill['current_bill']?.toDouble() ?? 0.0;
          final arrears = userBill['arrears']?.toDouble() ?? 0.0;

          // Calculate new total due: current_bill + arrears - paid_amount
          final newTotalDue = currentBill + arrears - newPaidAmount;

          // Determine status automatically based on total due
          String newStatus = newTotalDue <= 0 ? 'Paid' : 'Unpaid';

          await billRef.update({
            '$baNo.paid_amount': newPaidAmount,
            '$baNo.total_due': newTotalDue,
            '$baNo.bill_status': newStatus,
          });
        }
      }

      _loadPaymentRequests(); // Reload requests
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectPayment(Map<String, dynamic> request) async {
    try {
      final parts = request['id'].split('_');
      final baNo = parts[0];
      final transactionKey = '${parts[1]}_${parts[2]}_${parts[3]}';

      await FirebaseFirestore.instance
          .collection('payment_history')
          .doc(baNo)
          .update({
        '$transactionKey.status': 'rejected',
        '$transactionKey.rejected_at': FieldValue.serverTimestamp(),
      });

      _loadPaymentRequests(); // Reload requests
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  void _showPaymentDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Details - ${request['ba_no']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: ${request['name']}'),
              Text('Rank: ${request['rank']}'),
              Text('BA No: ${request['ba_no']}'),
              Text('Amount: ৳${request['amount'].toStringAsFixed(2)}'),
              Text('Method: ${request['payment_method']}'),
              Text('Status: ${request['status']}'),
              if (request['phone_number']?.isNotEmpty == true)
                Text('Phone: ${request['phone_number']}'),
              if (request['transaction_id']?.isNotEmpty == true)
                Text('Transaction ID: ${request['transaction_id']}'),
              if (request['account_no']?.isNotEmpty == true)
                Text('Account No: ${request['account_no']}'),
              if (request['bank_name']?.isNotEmpty == true)
                Text('Bank: ${request['bank_name']}'),
              if (request['card_number']?.isNotEmpty == true)
                Text('Card: ${request['card_number']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
                    : const Locale('en'));
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

        final filtered = paymentRequests.where((request) {
          final searchLower = searchQuery.toLowerCase();
          return request['name'].toLowerCase().contains(searchLower) ||
              request['ba_no'].toLowerCase().contains(searchLower) ||
              request['rank'].toLowerCase().contains(searchLower) ||
              request['payment_method'].toLowerCase().contains(searchLower);
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
                        onTap: () =>
                            _navigate(const AdminShoppingHistoryScreen()),
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
                      onPressed: _loadPaymentRequests,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const InsertTransactionScreen(),
                          ),
                        );
                        if (result != null) {
                          // Refresh payment requests after adding transaction
                          _loadPaymentRequests();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Transaction'),
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
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor:
                              WidgetStateProperty.all(const Color(0xFFF4F4F4)),
                          columns: [
                            DataColumn(
                                label: Text(
                                    AppLocalizations.of(context)!
                                        .paymentAmountBdt,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text(
                                    AppLocalizations.of(context)!.paymentTime,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text(
                                    AppLocalizations.of(context)!.paymentMethod,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text(AppLocalizations.of(context)!.baNo,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text(AppLocalizations.of(context)!.rank,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text(AppLocalizations.of(context)!.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Status',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Details',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text(
                                    AppLocalizations.of(context)!.actions,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ],
                          rows: List.generate(filtered.length, (index) {
                            final request = filtered[index];

                            return DataRow(cells: [
                              DataCell(Text(
                                  '৳${request['amount'].toStringAsFixed(2)}')),
                              DataCell(Text(request['request_time']
                                      ?.toDate()
                                      ?.toString() ??
                                  'N/A')),
                              DataCell(Text(request['payment_method'] ?? '')),
                              DataCell(Text(request['ba_no'] ?? '')),
                              DataCell(Text(request['rank'] ?? '')),
                              DataCell(Text(request['name'] ?? '')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: request['status'] == 'pending'
                                        ? Colors.orange
                                        : request['status'] == 'approved'
                                            ? Colors.green
                                            : Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    request['status']?.toUpperCase() ??
                                        'UNKNOWN',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.info,
                                      color: Colors.blue),
                                  onPressed: () => _showPaymentDetails(request),
                                ),
                              ),
                              DataCell(
                                request['status'] == 'pending'
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.check,
                                                color: Colors.green),
                                            onPressed: () =>
                                                _approvePayment(request),
                                            tooltip: 'Approve',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close,
                                                color: Colors.red),
                                            onPressed: () =>
                                                _rejectPayment(request),
                                            tooltip: 'Reject',
                                          ),
                                        ],
                                      )
                                    : Text(request['status'] == 'approved'
                                        ? 'Approved'
                                        : 'Rejected'),
                              ),
                            ]);
                          }),
                        ),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'admin_login_screen.dart';
import 'admin_users_screen.dart';
import 'admin_pending_ids_screen.dart';
import 'admin_shopping_history.dart';
import 'admin_voucher_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_messing_screen.dart';
import 'admin_staff_state_screen.dart';
import 'admin_dining_member_state.dart';
import 'admin_payment_history.dart';
import 'admin_meal_state_screen.dart';
import 'admin_bill_screen.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_menu_vote_screen.dart';
import 'admin_notification_screen.dart';
import 'admin_notification_history_screen.dart';
import 'admin_staff_login_sessions_screen.dart';
import '../../services/admin_auth_service.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
import 'staff_own_activity_log_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  Widget _buildOwnActivityLogButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.history),
        label: const Text('My Activity Log'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF002B5B),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StaffOwnActivityLogScreen(),
            ),
          );
        },
      ),
    );
  }

  final AdminAuthService _adminAuthService = AdminAuthService();

  bool _isLoading = true;
  bool _isAuthenticated = false;
  String _currentUserName = "Admin User";
  Map<String, dynamic>? _currentUserData;

  // Data variables
  int _totalDiningMembers = 0;
  int _pendingRequests = 0;
  int _paymentRequests = 0;
  Map<String, String> _todaysMenu = {};
  Map<String, String> _tomorrowsMenu = {};

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
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
            (route) => false,
          );
        }
        return;
      }

      // Get current admin data
      final userData = await _adminAuthService.getCurrentAdminData();
      if (userData != null) {
        setState(() {
          _currentUserData = userData;
          _currentUserName = userData['name'] ?? 'Admin User';
          _isAuthenticated = true;
          _isLoading = false;
        });

        // Load dashboard data
        await _loadDashboardData();
      } else {
        // User data not found, redirect to login
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      // Authentication error, redirect to login
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadDiningMembersCount(),
      _loadPendingRequestsCount(),
      _loadPaymentRequestsCount(),
      _loadMenuData(),
    ]);
  }

  Future<void> _loadDiningMembersCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user_requests')
          .where('approved', isEqualTo: true)
          .get();

      setState(() {
        _totalDiningMembers = snapshot.docs.length;
      });
    } catch (e) {
      print('Error loading dining members count: $e');
    }
  }

  Future<void> _loadPendingRequestsCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user_requests')
          .where('approved', isEqualTo: false)
          .where('rejected', isEqualTo: false)
          .get();

      setState(() {
        _pendingRequests = snapshot.docs.length;
      });
    } catch (e) {
      print('Error loading pending requests count: $e');
    }
  }

  Future<void> _loadPaymentRequestsCount() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('payment_history').get();

      int pendingCount = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        for (String key in data.keys) {
          if (key.contains('_transaction_')) {
            final transactionData = data[key] as Map<String, dynamic>;
            if (transactionData['status'] == 'pending') {
              pendingCount++;
            }
          }
        }
      }

      setState(() {
        _paymentRequests = pendingCount;
      });
    } catch (e) {
      print('Error loading payment requests count: $e');
    }
  }

  Future<void> _loadMenuData() async {
    try {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final tomorrowStr = DateFormat('yyyy-MM-dd').format(tomorrow);

      // Load today's menu
      final todayDoc = await FirebaseFirestore.instance
          .collection('monthly_menu')
          .doc(todayStr)
          .get();

      // Load tomorrow's menu
      final tomorrowDoc = await FirebaseFirestore.instance
          .collection('monthly_menu')
          .doc(tomorrowStr)
          .get();

      Map<String, String> todaysMenu = {};
      Map<String, String> tomorrowsMenu = {};

      if (todayDoc.exists) {
        final data = todayDoc.data()!;
        todaysMenu = {
          'breakfast': data['breakfast']?['item'] ?? 'Not Set',
          'lunch': data['lunch']?['item'] ?? 'Not Set',
          'dinner': data['dinner']?['item'] ?? 'Not Set',
        };
      } else {
        todaysMenu = {
          'breakfast': 'Not Set',
          'lunch': 'Not Set',
          'dinner': 'Not Set',
        };
      }

      if (tomorrowDoc.exists) {
        final data = tomorrowDoc.data()!;
        tomorrowsMenu = {
          'breakfast': data['breakfast']?['item'] ?? 'Not Set',
          'lunch': data['lunch']?['item'] ?? 'Not Set',
          'dinner': data['dinner']?['item'] ?? 'Not Set',
        };
      } else {
        tomorrowsMenu = {
          'breakfast': 'Not Set',
          'lunch': 'Not Set',
          'dinner': 'Not Set',
        };
      }

      setState(() {
        _todaysMenu = todaysMenu;
        _tomorrowsMenu = tomorrowsMenu;
      });
    } catch (e) {
      print('Error loading menu data: $e');
    }
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
          SnackBar(
              content:
                  Text('${AppLocalizations.of(context)!.logoutFailed}: $e')),
        );
      }
    }
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

  Widget _buildDemoBox(String title, String value, Color color) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.all(12),
            height: 120, // Fixed height for all boxes
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4)
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: constraints.maxWidth < 120 ? 12 : 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuCard(String title, Map<String, String> meals) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002B5B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMealItem(
                        AppLocalizations.of(context)!.breakfast,
                        meals["breakfast"] ??
                            AppLocalizations.of(context)!.notSet),
                    const SizedBox(height: 8),
                    _buildMealItem(AppLocalizations.of(context)!.lunch,
                        meals["lunch"] ?? AppLocalizations.of(context)!.notSet),
                    const SizedBox(height: 8),
                    _buildMealItem(
                        AppLocalizations.of(context)!.dinner,
                        meals["dinner"] ??
                            AppLocalizations.of(context)!.notSet),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealItem(String mealTime, String menu) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            "$mealTime:",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A4D8F),
            ),
          ),
        ),
        Expanded(
          child: Text(
            menu,
            style: TextStyle(
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF002B5B), Color(0xFF1A4D8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Send announcements, reminders, and updates to users',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                tooltip: 'Notification History',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AdminNotificationHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminNotificationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send, color: Color(0xFF002B5B)),
                  label: const Text(
                    'Send to All Users',
                    style: TextStyle(
                      color: Color(0xFF002B5B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF002B5B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminNotificationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person, color: Colors.white),
                  label: const Text(
                    'Send to Specific User',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Text(AppLocalizations.of(context)!.authenticationRequired),
        ),
      );
    }

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
                    onTap: () => Navigator.pop(context),
                    selected: true,
                  ),
                  _buildSidebarTile(
                    icon: Icons.people,
                    title: AppLocalizations.of(context)!.users,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminUsersScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.pending,
                    title: AppLocalizations.of(context)!.pendingIds,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminPendingIdsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.history,
                    title: AppLocalizations.of(context)!.shoppingHistory,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AdminShoppingHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.receipt,
                    title: AppLocalizations.of(context)!.voucherList,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminVoucherScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.storage,
                    title: AppLocalizations.of(context)!.inventory,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminInventoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.food_bank,
                    title: AppLocalizations.of(context)!.messing,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminMessingScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.menu_book,
                    title: AppLocalizations.of(context)!.monthlyMenu,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditMenuScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.analytics,
                    title: AppLocalizations.of(context)!.mealState,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminMealStateScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.thumb_up,
                    title: AppLocalizations.of(context)!.menuVote,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MenuVoteScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.receipt_long,
                    title: AppLocalizations.of(context)!.bills,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminBillScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.payment,
                    title: AppLocalizations.of(context)!.payments,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentsDashboard(),
                        ),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.people_alt,
                    title: AppLocalizations.of(context)!.diningMemberState,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DiningMemberStatePage(),
                        ),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.manage_accounts,
                    title: AppLocalizations.of(context)!.staffState,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminStaffStateScreen(),
                        ),
                      );
                    },
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
          AppLocalizations.of(context)!.adminDashboard,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Colors.white),
            onSelected: (String value) {
              if (value == 'bn') {
                Provider.of<LanguageProvider>(context, listen: false)
                    .changeLanguage(const Locale('bn'));
              } else {
                Provider.of<LanguageProvider>(context, listen: false)
                    .changeLanguage(const Locale('en'));
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'en',
                child: Row(
                  children: [
                    Text('🇺🇸'),
                    const SizedBox(width: 8),
                    Text('English'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'bn',
                child: Row(
                  children: [
                    Text('🇧🇩'),
                    const SizedBox(width: 8),
                    Text('বাংলা'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.overview,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      children: [
                        _buildDemoBox(
                            'Total Dining Members',
                            _totalDiningMembers.toString(),
                            const Color(0xFF1A4D8F)),
                        _buildDemoBox(
                            AppLocalizations.of(context)!.pendingRequests,
                            _pendingRequests.toString(),
                            const Color(0xFFE65100)),
                        _buildDemoBox(
                            'Payment Requests',
                            _paymentRequests.toString(),
                            const Color(0xFF2E7D32)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.welcomeBackAdmin,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.monitorUserActivity,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Show today's and tomorrow's meal cards first
                _buildMenuCard(
                  AppLocalizations.of(context)!.todaysMenu,
                  _todaysMenu.isNotEmpty
                      ? _todaysMenu
                      : {
                          "breakfast": AppLocalizations.of(context)!.notSet,
                          "lunch": AppLocalizations.of(context)!.notSet,
                          "dinner": AppLocalizations.of(context)!.notSet,
                        },
                ),
                _buildMenuCard(
                  AppLocalizations.of(context)!.tomorrowsMenu,
                  _tomorrowsMenu.isNotEmpty
                      ? _tomorrowsMenu
                      : {
                          "breakfast": AppLocalizations.of(context)!.notSet,
                          "lunch": AppLocalizations.of(context)!.notSet,
                          "dinner": AppLocalizations.of(context)!.notSet,
                        },
                ),
                const SizedBox(height: 16),

                // Notification, activity log, and login sessions at the end
                _buildNotificationSection(),
                const SizedBox(height: 16),
                _buildOwnActivityLogButton(context),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('My Login Sessions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AdminStaffLoginSessionsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

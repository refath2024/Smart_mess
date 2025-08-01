import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_home_screen.dart';
import 'admin_users_screen.dart';
import 'admin_shopping_history.dart';
import 'admin_voucher_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_messing_screen.dart';
import 'admin_staff_state_screen.dart';
import 'admin_dining_member_state.dart';
import 'admin_payment_history.dart';
import 'admin_bill_screen.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_menu_vote_screen.dart';
import 'admin_meal_state_screen.dart';
import 'admin_login_screen.dart';
import '../../services/admin_auth_service.dart';

class AdminPendingIdsScreen extends StatefulWidget {
  const AdminPendingIdsScreen({super.key});

  @override
  State<AdminPendingIdsScreen> createState() => _AdminPendingIdsScreenState();
}

class _AdminPendingIdsScreenState extends State<AdminPendingIdsScreen> {
  final AdminAuthService _adminAuthService = AdminAuthService();

  bool _isLoading = true;
  String _currentUserName = "Admin User";
  Map<String, dynamic>? _currentUserData;

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> pendingUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _fetchPendingUsers();
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
          _isLoading = false;
        });
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

  Future<void> _fetchPendingUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user_requests')
          .where('approved', isEqualTo: false)
          .where('rejected', isEqualTo: false)
          .get();

      final docs = snapshot.docs;

      setState(() {
        pendingUsers = docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'ba_no': data['ba_no'] ??
                data['no'] ??
                '', // Check both old and new field names
            'rank': data['rank'] ?? '',
            'name': data['name'] ?? '',
            'unit': data['unit'] ?? '',
            'email': data['email'] ?? '',
            'mobile': data['mobile'] ?? '',
            'requestedAt': data['created_at'] is Timestamp
                ? (data['created_at'] as Timestamp)
                    .toDate()
                    .toString()
                    .split(' ')[0]
                : (data['created_at'] ?? ''),
          };
        }).toList();

        filteredUsers = List.from(pendingUsers);
      });
    } catch (e) {
      debugPrint('Failed to fetch pending users: $e');
    }
  }

  void _search(String query) {
    setState(() {
      filteredUsers = pendingUsers.where((user) {
        return user.values.any(
          (value) =>
              value.toString().toLowerCase().contains(query.toLowerCase()),
        );
      }).toList();
    });
  }

  Future<void> _acceptUser(String docId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Accept'),
        content: const Text(
            'Are you sure you want to accept this user? This action will approve their application and grant them access to the system.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('user_requests')
          .doc(docId)
          .update({'approved': true, 'status': "active"});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User has been accepted.")),
      );
      await _fetchPendingUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to accept user: $e")),
      );
    }
  }

  Future<void> _rejectUser(String docId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reject'),
        content: const Text(
            'Are you sure you want to reject this user? This action will deny their application. They will be able to reapply later with updated information.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('user_requests')
          .doc(docId)
          .update({'rejected': true, 'status': "rejected"});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User has been rejected.")),
      );
      await _fetchPendingUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to reject user: $e")),
      );
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
          color: color ??
              (selected
                  ? const Color.fromARGB(255, 40, 150, 240)
                  : Colors.black),
        ),
        title: Text(title, style: TextStyle(color: color ?? Colors.black)),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
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
                    title: "Home",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminHomeScreen()),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.people,
                    title: "Users",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminUsersScreen()),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.pending,
                    title: "Pending IDs",
                    onTap: () => Navigator.pop(context),
                    selected: true,
                  ),
                  _buildSidebarTile(
                    icon: Icons.history,
                    title: "Shopping History",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const AdminShoppingHistoryScreen()),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.receipt,
                    title: "Voucher List",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminVoucherScreen()),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.storage,
                    title: "Inventory",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminInventoryScreen()),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.food_bank,
                    title: "Messing",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminMessingScreen()),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.menu_book,
                    title: "Monthly Menu",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const EditMenuScreen()),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.analytics,
                    title: "Meal State",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminMealStateScreen()),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.thumb_up,
                    title: "Menu Vote",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MenuVoteScreen()),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.receipt_long,
                    title: "Bills",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminBillScreen()),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.payment,
                    title: "Payments",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PaymentsDashboard()),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.people_alt,
                    title: "Dining Member State",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const DiningMemberStatePage()),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.manage_accounts,
                    title: "Staff State",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const AdminStaffStateScreen()),
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
                  title: "Logout",
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
        title: const Text(
          "Pending IDs",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "Search:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _search,
                      decoration: InputDecoration(
                        hintText: "Search...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowHeight: 50,
                    dataRowHeight: 60,
                    headingRowColor:
                        MaterialStateProperty.all(const Color(0xFF1A4D8F)),
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                      fontSize: 14,
                    ),
                    dataTextStyle: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                    dividerThickness: 0.5,
                    showBottomBorder: true,
                    columns: const [
                      DataColumn(label: Text("BA No")),
                      DataColumn(label: Text("Rank")),
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Unit")),
                      DataColumn(label: Text("Email")),
                      DataColumn(label: Text("Mobile")),
                      DataColumn(label: Text("Requested At")),
                      DataColumn(label: Text("Action")),
                    ],
                    rows: filteredUsers.map((user) {
                      final docId = user['id'] as String;
                      return DataRow(
                        color:
                            MaterialStateProperty.resolveWith<Color?>((states) {
                          return Colors.grey.shade100;
                        }),
                        cells: [
                          DataCell(Text(user['ba_no'] ?? '')),
                          DataCell(Text(user['rank'] ?? '')),
                          DataCell(Text(user['name'] ?? '')),
                          DataCell(Text(user['unit'] ?? '')),
                          DataCell(Text(user['email'] ?? '')),
                          DataCell(Text(user['mobile'] ?? '')),
                          DataCell(Text(user['requestedAt'] ?? '')),
                          DataCell(
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _acceptUser(docId),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text("Accept"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _rejectUser(docId),
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text("Reject"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

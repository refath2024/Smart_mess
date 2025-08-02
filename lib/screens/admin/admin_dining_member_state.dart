import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_home_screen.dart';
import 'admin_users_screen.dart';
import 'admin_pending_ids_screen.dart';
import 'admin_shopping_history.dart';
import 'admin_voucher_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_messing_screen.dart';
import 'admin_staff_state_screen.dart';
import 'admin_payment_history.dart';
import 'admin_meal_state_screen.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_menu_vote_screen.dart';
import 'admin_bill_screen.dart';
import 'add_dining_member.dart';
import 'admin_login_screen.dart';
import '../../services/admin_auth_service.dart';

class DiningMemberStatePage extends StatefulWidget {
  const DiningMemberStatePage({super.key});

  @override
  State<DiningMemberStatePage> createState() => _DiningMemberStatePageState();
}

class _DiningMemberStatePageState extends State<DiningMemberStatePage> {
  final AdminAuthService _adminAuthService = AdminAuthService();

  bool _isLoading = true;
  String _currentUserName = "Admin User";
  Map<String, dynamic>? _currentUserData;

  List<Map<String, dynamic>> members = [];
  String searchTerm = '';
  String statusFilter = 'all'; // Add status filter
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> filtered = [];

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
          _isLoading = false;
        });

        // After authentication is confirmed, fetch users from Firestore
        await _fetchUsersFromFirestore();
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

  Future<void> _fetchUsersFromFirestore() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user_requests')
          .where('approved', isEqualTo: true)
          .where('rejected', isEqualTo: false)
          .get();

      final List<Map<String, dynamic>> fetchedUsers = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        fetchedUsers.add({
          'id': doc.id,
          'no': data['ba_no'] ?? '',
          'rank': data['rank'] ?? '',
          'name': data['name'] ?? '',
          'unit': data['unit'] ?? '',
          'mobile': data['mobile'] ?? '',
          'email': data['email'] ?? '',
          'status': data['status'] ?? 'active', // Get current status
          'role': 'Dining Member',
          'isEditing': false,
          'original': {},
        });
      }

      setState(() {
        members = fetchedUsers;
        _applyFilters(); // Use the new filter method
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch users: $e')),
        );
      }
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
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  void _startEdit(Map<String, dynamic> row) {
    setState(() {
      row['original'] = Map<String, dynamic>.from(row);
      row['isEditing'] = true;
    });
  }

  void _cancelEdit(Map<String, dynamic> row) {
    setState(() {
      row['no'] = row['original']['no'];
      row['rank'] = row['original']['rank'];
      row['name'] = row['original']['name'];
      row['unit'] = row['original']['unit'];
      row['mobile'] = row['original']['mobile'];
      row['email'] = row['original']['email'];
      row['status'] = row['original']['status'];
      row['role'] = row['original']['role'];
      row['isEditing'] = false;
    });
  }

  Future<void> _deleteStaff(Map<String, dynamic> row) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "${row['name']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // Delete from Firestore
        if (row['id'] != null) {
          await FirebaseFirestore.instance
              .collection('user_requests')
              .doc(row['id'])
              .delete();
        }

        setState(() {
          members.remove(row);
          _applyFilters(); // Use the new filter method
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete member: $e')),
          );
        }
      }
    }
  }

  Future<void> _saveEdit(Map<String, dynamic> row) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Save'),
          content: const Text('Are you sure you want to save these changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // Update in Firestore
        if (row['id'] != null) {
          await FirebaseFirestore.instance
              .collection('user_requests')
              .doc(row['id'])
              .update({
            'ba_no': row['no'],
            'rank': row['rank'],
            'name': row['name'],
            'unit': row['unit'],
            'mobile': row['mobile'],
            'email': row['email'],
            'status': row['status'],
          });
        }

        setState(() {
          row['isEditing'] = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Changes saved successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save changes: $e')),
          );
        }
      }
    }
  }

  void _search(String query) {
    setState(() {
      searchTerm = query.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      filtered = members.where((m) {
        // Search filter
        final matchesSearch = searchTerm.isEmpty ||
            m.values.any(
                (value) => value.toString().toLowerCase().contains(searchTerm));

        // Status filter
        final matchesStatus =
            statusFilter == 'all' || m['status'] == statusFilter;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Widget _buildSidebarTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
    Color? color,
  }) {
    return ListTile(
      selected: selected,
      selectedTileColor: Colors.blue.shade100,
      leading:
          Icon(icon, color: color ?? (selected ? Colors.blue : Colors.black)),
      title: Text(title, style: TextStyle(color: color ?? Colors.black)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking authentication
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
                      onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AdminHomeScreen()))),
                  _buildSidebarTile(
                    icon: Icons.people,
                    title: "Users",
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
                    title: "Pending IDs",
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
                    title: "Shopping History",
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
                    title: "Voucher List",
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
                    title: "Inventory",
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
                    title: "Messing",
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
                    title: "Monthly Menu",
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
                    title: "Meal State",
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
                    title: "Menu Vote",
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
                    title: "Bills",
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
                    title: "Payments",
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
                      title: "Dining Member State",
                      selected: true,
                      onTap: () => Navigator.pop(context)),
                  _buildSidebarTile(
                    icon: Icons.manage_accounts,
                    title: "Staff State",
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
          "Dining Member State",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // First row with search and filter
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _search,
                    decoration: const InputDecoration(
                      labelText: 'Search All Text Columns',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Status',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All Status'),
                      ),
                      DropdownMenuItem(
                        value: 'active',
                        child: Text('Active Only'),
                      ),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('Inactive Only'),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          statusFilter = newValue;
                          _applyFilters();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Second row with add button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddDiningMemberForm()));

                    // Refresh data when returning from add form
                    if (result == true || result == null) {
                      await _fetchUsersFromFirestore();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add Dining Member",
                      style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width - 32,
                    ),
                    child: DataTable(
                      columnSpacing: 12, // Reduced column spacing
                      headingRowColor:
                          WidgetStateProperty.all(const Color(0xFF1A4D8F)),
                      columns: const [
                        DataColumn(
                            label: Text('BA No',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                        DataColumn(
                            label: Text('Rank',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                        DataColumn(
                            label: Text('Name',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                        DataColumn(
                            label: Text('Unit',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                        DataColumn(
                            label: Text('Mobile',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                        DataColumn(
                            label: Text('Email',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                        DataColumn(
                            label: Text('Role',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                        DataColumn(
                            label: Text('Status',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                        DataColumn(
                            label: Text('Action',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                      ],
                      rows: filtered.map((row) {
                        final bool isEditing = row['isEditing'] ?? false;
                        return DataRow(cells: [
                          DataCell(
                            SizedBox(
                              width: 80,
                              child: isEditing
                                  ? TextField(
                                      controller: TextEditingController(
                                          text: row['no']),
                                      onChanged: (value) => row['no'] = value,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.all(4),
                                      ),
                                    )
                                  : Text(row['no'] ?? '',
                                      style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: isEditing
                                  ? TextField(
                                      controller: TextEditingController(
                                          text: row['rank']),
                                      onChanged: (value) => row['rank'] = value,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.all(4),
                                      ),
                                    )
                                  : Text(row['rank'] ?? '',
                                      style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 120,
                              child: isEditing
                                  ? TextField(
                                      controller: TextEditingController(
                                          text: row['name']),
                                      onChanged: (value) => row['name'] = value,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.all(4),
                                      ),
                                    )
                                  : Text(row['name'] ?? '',
                                      style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: isEditing
                                  ? TextField(
                                      controller: TextEditingController(
                                          text: row['unit']),
                                      onChanged: (value) => row['unit'] = value,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.all(4),
                                      ),
                                    )
                                  : Text(row['unit'] ?? '',
                                      style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: isEditing
                                  ? TextField(
                                      controller: TextEditingController(
                                          text: row['mobile']),
                                      onChanged: (value) =>
                                          row['mobile'] = value,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.all(4),
                                      ),
                                    )
                                  : Text(row['mobile'] ?? '',
                                      style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 150,
                              child: isEditing
                                  ? TextField(
                                      controller: TextEditingController(
                                          text: row['email']),
                                      onChanged: (value) =>
                                          row['email'] = value,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.all(4),
                                      ),
                                    )
                                  : Text(row['email'] ?? '',
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          const DataCell(
                            SizedBox(
                              width: 100,
                              child: Text('Dining Member',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 90,
                              child: isEditing
                                  ? DropdownButton<String>(
                                      value: row['status'],
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'active',
                                          child: Text('Active',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                        DropdownMenuItem(
                                          value: 'inactive',
                                          child: Text('Inactive',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            row['status'] = newValue;
                                          });
                                        }
                                      },
                                      underline: Container(),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: row['status'] == 'active'
                                            ? Colors.green.shade100
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: row['status'] == 'active'
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                      child: Text(
                                        row['status'] == 'active'
                                            ? 'Active'
                                            : 'Inactive',
                                        style: TextStyle(
                                          color: row['status'] == 'active'
                                              ? Colors.green.shade800
                                              : Colors.orange.shade800,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isEditing) ...[
                                    IconButton(
                                      icon: const Icon(Icons.save, size: 18),
                                      color: Colors.green,
                                      onPressed: () => _saveEdit(row),
                                      tooltip: 'Save',
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(
                                          minWidth: 32, minHeight: 32),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel, size: 18),
                                      color: Colors.red,
                                      onPressed: () => _cancelEdit(row),
                                      tooltip: 'Cancel',
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(
                                          minWidth: 32, minHeight: 32),
                                    )
                                  ] else ...[
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      color: Colors.blue,
                                      onPressed: () => _startEdit(row),
                                      tooltip: 'Edit',
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(
                                          minWidth: 32, minHeight: 32),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 18),
                                      color: Colors.red,
                                      onPressed: () => _deleteStaff(row),
                                      tooltip: 'Delete',
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(
                                          minWidth: 32, minHeight: 32),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          )
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

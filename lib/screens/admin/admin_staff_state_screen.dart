import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_auth_service.dart';
import 'add_staff.dart';
import 'admin_home_screen.dart';
import 'admin_users_screen.dart';
import 'admin_pending_ids_screen.dart';
import 'admin_shopping_history.dart';
import 'admin_voucher_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_messing_screen.dart';
import 'admin_dining_member_state.dart';
import 'admin_payment_history.dart';

import 'admin_meal_state_screen.dart';
import 'admin_bill_screen.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_menu_vote_screen.dart';
import 'admin_login_screen.dart';

class AdminStaffStateScreen extends StatefulWidget {
  const AdminStaffStateScreen({super.key});

  @override
  State<AdminStaffStateScreen> createState() => _AdminStaffStateScreenState();
}

class _AdminStaffStateScreenState extends State<AdminStaffStateScreen> {
  final AdminAuthService _adminAuthService = AdminAuthService();

  bool _isLoading = true;
  String _currentUserName = "Admin User";
  Map<String, dynamic>? _currentUserData;

  List<Map<String, dynamic>> staffData = [];
  String searchTerm = '';

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

        // After authentication is confirmed, fetch staff data from Firestore
        await _loadStaffData();
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

  Future<void> _loadStaffData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('staff_state')
          .orderBy('ba_no')
          .get();

      setState(() {
        staffData = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'ba_no': data['ba_no'] ?? '',
            'rank': data['rank'] ?? '',
            'name': data['name'] ?? '',
            'unit': data['unit'] ?? '',
            'mobile': data['mobile'] ?? '',
            'email': data['email'] ?? '',
            'role': data['role'] ?? '',
            'status': data['status'] ?? 'Active',
            'isEditing': false,
            'original': {},
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load staff data: $e')),
        );
      }
    }
  }

  final List<String> _roles = [
    'PMC',
    'G2 (Mess)',
    'Mess Secretary',
    'Asst Mess Secretary',
    'RP NCO',
    'Barrack NCO',
    'Mess Sgt',
    'Asst Mess Sgt',
    'Clerk',
    'Cook',
    'Butler',
    'Waiter',
    'NC(E)',
  ];

  // Roles that can only have one person assigned
  final List<String> _uniqueRoles = [
    'PMC',
    'G2 (Mess)',
    'Mess Secretary',
    'Asst Mess Secretary',
    'RP NCO',
    'Barrack NCO',
    'Mess Sgt',
    'Asst Mess Sgt',
  ];

  // Get available roles for editing (excluding already assigned unique roles)
  List<String> _getAvailableRolesForEdit(String currentRole) {
    final existingUniqueRoles = staffData
        .where((staff) =>
            staff['role'] != currentRole &&
            _uniqueRoles.contains(staff['role']))
        .map((staff) => staff['role'] as String)
        .toSet();

    return _roles.where((role) {
      if (_uniqueRoles.contains(role)) {
        // For unique roles, only show if not already assigned or if it's the current role
        return !existingUniqueRoles.contains(role) || role == currentRole;
      } else {
        // For non-unique roles, always show
        return true;
      }
    }).toList();
  }

  // Check if a role can be edited
  bool _canEditRole(String role) {
    return role != 'PMC'; // PMC role cannot be edited
  }

  // Check if status can be edited
  bool _canEditStatus(String role) {
    return !_uniqueRoles.contains(role); // Unique roles status cannot be edited
  }

  // Check if a staff member can be deleted
  bool _canDeleteStaff(String role) {
    return role !=
        'PMC'; // PMC cannot be deleted to prevent losing admin access
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
      row['ba_no'] = row['original']['ba_no'];
      row['rank'] = row['original']['rank'];
      row['name'] = row['original']['name'];
      row['unit'] = row['original']['unit'];
      row['mobile'] = row['original']['mobile'];
      row['email'] = row['original']['email'];
      row['role'] = row['original']['role'];
      row['status'] = row['original']['status'];
      row['isEditing'] = false;
    });
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
        await FirebaseFirestore.instance
            .collection('staff_state')
            .doc(row['id'])
            .update({
          'ba_no': row['ba_no'],
          'rank': row['rank'],
          'name': row['name'],
          'unit': row['unit'],
          'mobile': row['mobile'],
          'email': row['email'],
          'role': row['role'],
          'status': row['status'],
          'updated_at': FieldValue.serverTimestamp(),
        });

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

  Future<void> _deleteStaff(Map<String, dynamic> row) async {
    // Safety check: Prevent PMC deletion
    if (row['role'] == 'PMC') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'PMC account cannot be deleted. It serves as the super admin to maintain system access.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete "${row['name']}"?'),
              const SizedBox(height: 8),
              const Text(
                'This will permanently delete:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const Text('• Staff record from database'),
              const Text('• Associated user account from all collections'),
              const Text('• Firebase authentication account (automatic)'),
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
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
      // Show loading dialog during deletion
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Deleting staff member...'),
              ],
            ),
          );
        },
      );

      try {
        // Step 1: Delete from staff_state collection
        // The Cloud Function trigger will automatically handle:
        // - Firebase Auth user deletion
        // - User document deletion from 'users' collection
        await FirebaseFirestore.instance
            .collection('staff_state')
            .doc(row['id'])
            .delete();

        // Update local state
        setState(() {
          staffData.remove(row);
        });

        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Staff member "${row['name']}" deleted successfully.\n'
                'Firebase Auth account will be automatically removed.',
              ),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete staff member: $e')),
          );
        }
      }
    }
  }

  void _navigateToAddStaff() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddNewUserForm()),
    );

    // Refresh data when returning from add form
    if (result == true || result == null) {
      await _loadStaffData();
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

    final filteredData = staffData.where((row) {
      return row.values
          .any((value) => value.toLowerCase().contains(searchTerm));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Staff State",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
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
                          builder: (context) => const AdminHomeScreen(),
                        ),
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
                    title: "Staff State",
                    selected: true,
                    onTap: () => Navigator.pop(context),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Search All Text Columns',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchTerm = value.toLowerCase();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _navigateToAddStaff,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0052CC),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text("Add Staff/Admin"),
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
                              headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFF1A4D8F)),
                              columns: const [
                                DataColumn(
                                    label: Text('BA/ID No',
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
                              rows: filteredData.map((row) {
                                final bool isEditing =
                                    row['isEditing'] ?? false;
                                final bool canEditRole =
                                    _canEditRole(row['role']);
                                final bool canEditStatus =
                                    _canEditStatus(row['role']);

                                return DataRow(cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 80,
                                      child: isEditing
                                          ? TextField(
                                              controller: TextEditingController(
                                                  text: row['ba_no']),
                                              onChanged: (value) =>
                                                  row['ba_no'] = value,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.all(4),
                                              ),
                                            )
                                          : Text(row['ba_no'] ?? '',
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 100,
                                      child: isEditing
                                          ? TextField(
                                              controller: TextEditingController(
                                                  text: row['rank']),
                                              onChanged: (value) =>
                                                  row['rank'] = value,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.all(4),
                                              ),
                                            )
                                          : Text(row['rank'] ?? '',
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 120,
                                      child: isEditing
                                          ? TextField(
                                              controller: TextEditingController(
                                                  text: row['name']),
                                              onChanged: (value) =>
                                                  row['name'] = value,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.all(4),
                                              ),
                                            )
                                          : Text(row['name'] ?? '',
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 100,
                                      child: isEditing
                                          ? TextField(
                                              controller: TextEditingController(
                                                  text: row['unit']),
                                              onChanged: (value) =>
                                                  row['unit'] = value,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.all(4),
                                              ),
                                            )
                                          : Text(row['unit'] ?? '',
                                              style: const TextStyle(
                                                  fontSize: 12)),
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
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.all(4),
                                              ),
                                            )
                                          : Text(row['mobile'] ?? '',
                                              style: const TextStyle(
                                                  fontSize: 12)),
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
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.all(4),
                                              ),
                                            )
                                          : Text(row['email'] ?? '',
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 120,
                                      child: isEditing && canEditRole
                                          ? DropdownButton<String>(
                                              value: _getAvailableRolesForEdit(
                                                          row['role'])
                                                      .contains(row['role'])
                                                  ? row['role']
                                                  : _getAvailableRolesForEdit(
                                                          row['role'])
                                                      .first,
                                              isExpanded: true,
                                              items: _getAvailableRolesForEdit(
                                                      row['role'])
                                                  .map((role) =>
                                                      DropdownMenuItem(
                                                        value: role,
                                                        child: Text(role,
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12)),
                                                      ))
                                                  .toList(),
                                              onChanged: (String? newValue) {
                                                if (newValue != null) {
                                                  setState(() {
                                                    row['role'] = newValue;
                                                  });
                                                }
                                              },
                                              underline: Container(),
                                            )
                                          : Text(row['role'] ?? '',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: canEditRole
                                                    ? Colors.black
                                                    : Colors.grey,
                                                fontWeight: _uniqueRoles
                                                        .contains(row['role'])
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              )),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 90,
                                      child: isEditing && canEditStatus
                                          ? DropdownButton<String>(
                                              value: row['status'],
                                              isExpanded: true,
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 'Active',
                                                  child: Text('Active',
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'Inactive',
                                                  child: Text('Inactive',
                                                      style: TextStyle(
                                                          fontSize: 12)),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: row['status'] == 'Active'
                                                    ? Colors.green.shade100
                                                    : Colors.orange.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color:
                                                      row['status'] == 'Active'
                                                          ? Colors.green
                                                          : Colors.orange,
                                                ),
                                              ),
                                              child: Text(
                                                row['status'] ?? 'Inactive',
                                                style: TextStyle(
                                                  color: row['status'] ==
                                                          'Active'
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
                                              icon: const Icon(Icons.save,
                                                  size: 18),
                                              color: Colors.green,
                                              onPressed: () => _saveEdit(row),
                                              tooltip: 'Save',
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(
                                                  minWidth: 32, minHeight: 32),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.cancel,
                                                  size: 18),
                                              color: Colors.red,
                                              onPressed: () => _cancelEdit(row),
                                              tooltip: 'Cancel',
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(
                                                  minWidth: 32, minHeight: 32),
                                            )
                                          ] else ...[
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  size: 18),
                                              color: Colors.blue,
                                              onPressed: () => _startEdit(row),
                                              tooltip: 'Edit',
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(
                                                  minWidth: 32, minHeight: 32),
                                            ),
                                            if (_canDeleteStaff(row['role']))
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    size: 18),
                                                color: Colors.red,
                                                onPressed: () =>
                                                    _deleteStaff(row),
                                                tooltip: 'Delete',
                                                padding:
                                                    const EdgeInsets.all(4),
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 32,
                                                        minHeight: 32),
                                              )
                                            else
                                              const IconButton(
                                                icon: Icon(Icons.delete,
                                                    size: 18),
                                                color: Colors.grey,
                                                onPressed: null,
                                                tooltip:
                                                    'PMC cannot be deleted (Super Admin protection)',
                                                padding: EdgeInsets.all(4),
                                                constraints: BoxConstraints(
                                                    minWidth: 32,
                                                    minHeight: 32),
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
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

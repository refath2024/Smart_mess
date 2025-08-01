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
        await FirebaseFirestore.instance
            .collection('staff_state')
            .doc(row['id'])
            .delete();

        setState(() {
          staffData.remove(row);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff member deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete staff member: $e')),
          );
        }
      }
    }
  }

  void _navigateToAddStaff() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddNewUserForm()),
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
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor:
                              WidgetStateProperty.all(const Color(0xFF1A4D8F)),
                          columns: const [
                            DataColumn(
                                label: Text('BA/ID No',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Rank',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Name',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Unit',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Mobile No',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Email',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Role',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Status',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Action',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                          ],
                          rows: filteredData.map((row) {
                            final bool isEditing = row['isEditing'] ?? false;
                            return DataRow(
                              cells: [
                                DataCell(isEditing
                                    ? TextField(
                                        controller: TextEditingController(
                                            text: row['ba_no']),
                                        onChanged: (val) => row['ba_no'] = val,
                                      )
                                    : Text(row['ba_no'] ?? '')),
                                DataCell(isEditing
                                    ? TextField(
                                        controller: TextEditingController(
                                            text: row['rank']),
                                        onChanged: (val) => row['rank'] = val,
                                      )
                                    : Text(row['rank'] ?? '')),
                                DataCell(isEditing
                                    ? TextField(
                                        controller: TextEditingController(
                                            text: row['name']),
                                        onChanged: (val) => row['name'] = val,
                                      )
                                    : Text(row['name'] ?? '')),
                                DataCell(isEditing
                                    ? TextField(
                                        controller: TextEditingController(
                                            text: row['unit']),
                                        onChanged: (val) => row['unit'] = val,
                                      )
                                    : Text(row['unit'] ?? '')),
                                DataCell(isEditing
                                    ? TextField(
                                        controller: TextEditingController(
                                            text: row['mobile']),
                                        onChanged: (val) => row['mobile'] = val,
                                      )
                                    : Text(row['mobile'] ?? '')),
                                DataCell(isEditing
                                    ? TextField(
                                        controller: TextEditingController(
                                            text: row['email']),
                                        onChanged: (val) => row['email'] = val,
                                      )
                                    : Text(row['email'] ?? '')),
                                DataCell(isEditing
                                    ? Container(
                                        constraints:
                                            const BoxConstraints(maxWidth: 200),
                                        child: DropdownButtonFormField<String>(
                                          value: _roles.contains(row['role'])
                                              ? row['role']
                                              : _roles.first,
                                          decoration: const InputDecoration(
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 0),
                                            border: OutlineInputBorder(),
                                          ),
                                          items: _roles
                                              .map((role) => DropdownMenuItem(
                                                    value: role,
                                                    child: Text(role),
                                                  ))
                                              .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              row['role'] = value!;
                                            });
                                          },
                                          isExpanded: true,
                                        ),
                                      )
                                    : Text(row['role'] ?? '')),
                                DataCell(
                                  isEditing
                                      ? DropdownButton<String>(
                                          value: row['status'],
                                          items: ['Active', 'Inactive']
                                              .map((status) => DropdownMenuItem(
                                                    value: status,
                                                    child: Text(status),
                                                  ))
                                              .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              row['status'] = value!;
                                            });
                                          },
                                        )
                                      : Text(row['status'] ?? ''),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!isEditing) ...[
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          color: const Color(0xFF1A4D8F),
                                          onPressed: () => _startEdit(row),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () => _deleteStaff(row),
                                        ),
                                      ] else ...[
                                        IconButton(
                                          icon: const Icon(Icons.save),
                                          color: Colors.green,
                                          onPressed: () => _saveEdit(row),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.cancel),
                                          color: Colors.grey,
                                          onPressed: () => _cancelEdit(row),
                                        ),
                                      ],
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

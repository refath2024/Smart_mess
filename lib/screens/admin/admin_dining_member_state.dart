import 'package:flutter/material.dart';
import '../login_screen.dart';
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

class DiningMemberStatePage extends StatefulWidget {
  const DiningMemberStatePage({super.key});

  @override
  State<DiningMemberStatePage> createState() => _DiningMemberStatePageState();
}

class _DiningMemberStatePageState extends State<DiningMemberStatePage> {
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      (route) => false,
    );
  }

  final List<Map<String, dynamic>> members = [
    {
      'no': 'BA-10234',
      'rank': 'Major',
      'name': 'Maj Ahmed Khan',
      'unit': '10 Signal Battalion',
      'mobile': '+880 1700-000001',
      'email': 'ahmed.khan@army.mil.bd',
      'role': 'Dining Member',
      'status': 'Active',
      'isEditing': false,
      'original': {},
    },
    {
      'no': 'BA-10235',
      'rank': 'Captain',
      'name': 'Capt Fatima Rahman',
      'unit': 'Engineering Corps',
      'mobile': '+880 1700-000002',
      'email': 'fatima.r@army.mil.bd',
      'role': 'Dining Member',
      'status': 'Active',
      'isEditing': false,
      'original': {},
    },
    {
      'no': 'BA-10236',
      'rank': 'Lieutenant',
      'name': 'Lt Karim Ali',
      'unit': 'Infantry Regiment',
      'mobile': '+880 1700-000003',
      'email': 'karim.ali@army.mil.bd',
      'role': 'Dining Member',
      'status': 'Inactive',
      'isEditing': false,
      'original': {},
    },
  ];

  String searchTerm = '';
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> filtered = [];

  @override
  void initState() {
    super.initState();
    filtered = List.from(members);
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
      row['role'] = row['original']['role'];
      row['status'] = row['original']['status'];
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
      setState(() {
        members.remove(row);
        filtered = List.from(members);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member deleted successfully')),
        );
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
      setState(() {
        row['isEditing'] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully')),
        );
      }
    }
  }

  void _search(String query) {
    setState(() {
      searchTerm = query.toLowerCase();
      filtered = members
          .where((m) => m.values.any(
              (value) => value.toString().toLowerCase().contains(searchTerm)))
          .toList();
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
                children: const [
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/me.png'),
                    radius: 30,
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      "Shoaib Ahmed Sami",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _search,
                    decoration: const InputDecoration(
                      labelText: 'Search All Text Columns',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddDiningMemberForm()));
                  },
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
                  label: const Text("Add Dining Member"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor:
                      MaterialStateProperty.all(const Color(0xFF1A4D8F)),
                  columns: const [
                    DataColumn(
                        label: Text('BA No',
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
                  rows: filtered.map((row) {
                    final bool isEditing = row['isEditing'] ?? false;
                    return DataRow(cells: [
                      DataCell(isEditing
                          ? TextField(
                              controller:
                                  TextEditingController(text: row['no']),
                            )
                          : Text(row['no'] ?? '')),
                      DataCell(isEditing
                          ? TextField(
                              controller:
                                  TextEditingController(text: row['rank']),
                            )
                          : Text(row['rank'] ?? '')),
                      DataCell(isEditing
                          ? TextField(
                              controller:
                                  TextEditingController(text: row['name']),
                            )
                          : Text(row['name'] ?? '')),
                      DataCell(isEditing
                          ? TextField(
                              controller:
                                  TextEditingController(text: row['unit']),
                            )
                          : Text(row['unit'] ?? '')),
                      DataCell(isEditing
                          ? TextField(
                              controller:
                                  TextEditingController(text: row['mobile']),
                            )
                          : Text(row['mobile'] ?? '')),
                      DataCell(isEditing
                          ? TextField(
                              controller:
                                  TextEditingController(text: row['email']),
                            )
                          : Text(row['email'] ?? '')),
                      DataCell(Text('Dining Member')),
                      DataCell(
                        isEditing
                            ? DropdownButton<String>(
                                value: row['status'],
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Active', child: Text('Active')),
                                  DropdownMenuItem(
                                      value: 'Inactive',
                                      child: Text('Inactive')),
                                ],
                                onChanged: (val) =>
                                    setState(() => row['status'] = val!),
                              )
                            : Text(row['status'] ?? ''),
                      ),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isEditing) ...[
                            IconButton(
                              icon: const Icon(Icons.save),
                              color: Colors.green,
                              onPressed: () => _saveEdit(row),
                              tooltip: 'Save',
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel),
                              color: Colors.red,
                              onPressed: () => _cancelEdit(row),
                              tooltip: 'Cancel',
                            )
                          ] else ...[
                            IconButton(
                              icon: const Icon(Icons.edit),
                              color: Colors.blue,
                              onPressed: () => _startEdit(row),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () => _deleteStaff(row),
                              tooltip: 'Delete',
                            ),
                          ]
                        ],
                      ))
                    ]);
                  }).toList(),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

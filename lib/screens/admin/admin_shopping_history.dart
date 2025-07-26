import 'package:flutter/material.dart';
import 'package:smart_mess/screens/admin/admin_login_screen.dart';

import 'admin_home_screen.dart';
import 'admin_payment_history.dart';
import 'admin_dining_member_state.dart';
import 'admin_users_screen.dart';
import 'admin_pending_ids_screen.dart';
import 'add_shopping.dart';
import 'admin_voucher_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_messing_screen.dart';
import 'admin_staff_state_screen.dart';
import 'admin_meal_state_screen.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_menu_vote_screen.dart';
import 'admin_bill_screen.dart';

class AdminShoppingHistoryScreen extends StatefulWidget {
  const AdminShoppingHistoryScreen({super.key});

//jjjj
  @override
  State<AdminShoppingHistoryScreen> createState() =>
      _AdminShoppingHistoryScreenState();
}

class _AdminShoppingHistoryScreenState
    extends State<AdminShoppingHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  Widget _editableTextField({
    required String initialValue,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      width: 100,
      child: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 5, 97, 235),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
        shadowColor: color.withOpacity(0.6),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  // Shopping data now matches the structure from HTML
  List<Map<String, dynamic>> shoppingData = [
    {
      'id': 1,
      'productName': 'Rice',
      'unitPrice': 50.0,
      'amount': 2.0,
      'totalPrice': 100.0,
      'date': '2025-07-05',
      'voucherId': 'V001',
      'isEditing': false,
      // Save original data for cancel action
      'original': {},
    },
    {
      'id': 2,
      'productName': 'Chicken',
      'unitPrice': 150.0,
      'amount': 1.5,
      'totalPrice': 225.0,
      'date': '2025-07-04',
      'voucherId': 'V002',
      'isEditing': false,
      'original': {},
    },
    {
      'id': 3,
      'productName': 'Vegetables',
      'unitPrice': 30.0,
      'amount': 4.0,
      'totalPrice': 120.0,
      'date': '2025-07-03',
      'voucherId': 'V003',
      'isEditing': false,
      'original': {},
    },
  ];

  List<Map<String, dynamic>> filteredData = [];

  @override
  void initState() {
    super.initState();
    filteredData = List.from(shoppingData);
  }

  void _search(String query) {
    setState(() {
      filteredData = shoppingData.where((entry) {
        return entry.values.any(
          (value) =>
              value.toString().toLowerCase().contains(query.toLowerCase()),
        );
      }).toList();
    });
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      (route) => false,
    );
  }

  void _startEdit(int index) {
    setState(() {
      // Backup original data for canceling edits
      filteredData[index]['original'] = Map<String, dynamic>.from(
        filteredData[index],
      );
      filteredData[index]['isEditing'] = true;
    });
  }

  void _cancelEdit(int index) {
    setState(() {
      // Restore original data
      filteredData[index] = Map<String, dynamic>.from(
        filteredData[index]['original'],
      );
      filteredData[index]['isEditing'] = false;
    });
  }

  void _saveEdit(int index) {
    setState(() {
      final entry = filteredData[index];
      // Recalculate totalPrice
      entry['totalPrice'] = (entry['unitPrice'] * entry['amount']);
      entry['isEditing'] = false;

      // Sync shoppingData (optional)
      int origIndex = shoppingData.indexWhere((e) => e['id'] == entry['id']);
      if (origIndex != -1) shoppingData[origIndex] = Map.from(entry);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Row updated successfully!')));
  }

  Future<void> _deleteRow(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
              'Are you sure you want to delete "${filteredData[index]['productName']}" from shopping history?'),
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
        final id = filteredData[index]['id'];
        filteredData.removeAt(index);
        shoppingData.removeWhere((e) => e['id'] == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shopping entry deleted successfully!')),
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
                    onTap: () => Navigator.pop(context),
                    selected: true,
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
          "Shopping History",
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
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminAddShoppingScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Add Shopping Data",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A4D8F),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                    columnSpacing: 24,
                    headingRowHeight: 56,
                    dataRowHeight: 64,
                    horizontalMargin: 12,
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFF134074),
                    ),
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontSize: 15,
                    ),
                    dataTextStyle: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                    dataRowColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.blue.shade100.withOpacity(0.4);
                      }
                      return null;
                    }),
                    columns: const [
                      DataColumn(label: Text("Index")),
                      DataColumn(label: Text("Product Name")),
                      DataColumn(label: Text("Unit Price (Per Kg/Qty)")),
                      DataColumn(label: Text("Amount (Kg/Qty)")),
                      DataColumn(label: Text("Total Price")),
                      DataColumn(label: Text("Date")),
                      DataColumn(label: Text("Voucher ID")),
                      DataColumn(label: Text("Action")),
                    ],
                    rows: List.generate(filteredData.length, (index) {
                      final entry = filteredData[index];
                      final isEditing = entry['isEditing'] as bool;

                      // Zebra striping
                      final rowColor =
                          index % 2 == 0 ? Colors.grey[100] : Colors.white;

                      return DataRow(
                        color: WidgetStateProperty.all(rowColor),
                        cells: [
                          DataCell(Text('${entry['id']}')),
                          DataCell(
                            isEditing
                                ? _editableTextField(
                                    initialValue: entry['productName'],
                                    onChanged: (val) =>
                                        entry['productName'] = val,
                                  )
                                : Text(entry['productName']),
                          ),
                          DataCell(
                            isEditing
                                ? _editableTextField(
                                    initialValue: entry['unitPrice'].toString(),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => entry['unitPrice'] =
                                        double.tryParse(val) ?? 0.0,
                                  )
                                : Text(entry['unitPrice'].toStringAsFixed(2)),
                          ),
                          DataCell(
                            isEditing
                                ? _editableTextField(
                                    initialValue: entry['amount'].toString(),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => entry['amount'] =
                                        double.tryParse(val) ?? 0.0,
                                  )
                                : Text(entry['amount'].toStringAsFixed(2)),
                          ),
                          DataCell(
                            Text(entry['totalPrice'].toStringAsFixed(2)),
                          ),
                          DataCell(
                            isEditing
                                ? _editableTextField(
                                    initialValue: entry['date'],
                                    onChanged: (val) => entry['date'] = val,
                                  )
                                : Text(entry['date']),
                          ),
                          DataCell(
                            isEditing
                                ? _editableTextField(
                                    initialValue: entry['voucherId'],
                                    onChanged: (val) =>
                                        entry['voucherId'] = val,
                                  )
                                : Text(entry['voucherId']),
                          ),
                          DataCell(
                            Row(
                              children: [
                                if (!isEditing)
                                  _actionButton(
                                    text: 'Edit',
                                    color: const Color(0xFF0052CC),
                                    onPressed: () => _startEdit(index),
                                  ),
                                if (isEditing) ...[
                                  _actionButton(
                                    text: 'Save',
                                    color: const Color(0xFF2E8B57),
                                    onPressed: () => _saveEdit(index),
                                  ),
                                  const SizedBox(width: 8),
                                  _actionButton(
                                    text: 'Cancel',
                                    color: Colors.grey.shade600,
                                    onPressed: () => _cancelEdit(index),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                _actionButton(
                                  text: 'Delete',
                                  color: const Color(0xFFCC0000),
                                  onPressed: () => _deleteRow(index),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
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

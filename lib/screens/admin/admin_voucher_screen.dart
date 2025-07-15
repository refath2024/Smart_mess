// admin_voucher_screen.dart
import 'package:flutter/material.dart';
import '../login_screen.dart';
import 'admin_home_screen.dart';
import 'admin_users_screen.dart';
import 'admin_pending_ids_screen.dart';
import 'admin_shopping_history.dart';
import 'admin_add_voucher.dart';
import 'admin_inventory_screen.dart';
import 'admin_messing_screen.dart';

class AdminVoucherScreen extends StatefulWidget {
  const AdminVoucherScreen({super.key});

  @override
  State<AdminVoucherScreen> createState() => _AdminVoucherScreenState();
}

class _AdminVoucherScreenState extends State<AdminVoucherScreen> {
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> voucherData = [
    {
      'id': 'V001',
      'date': '2025-07-01',
      'buyer': 'Lt Sami',
      'unitPrice': 100,
      'amount': 2,
      'totalPrice': 200,
      'isEditing': false,
      'original': {},
    },
    {
      'id': 'V002',
      'date': '2025-07-02',
      'buyer': 'Capt Maruf',
      'unitPrice': 120,
      'amount': 1.5,
      'totalPrice': 180,
      'isEditing': false,
      'original': {},
    },
  ];

  List<Map<String, dynamic>> filteredData = [];

  @override
  void initState() {
    super.initState();
    filteredData = List.from(voucherData);
  }

  void _startEdit(int index) {
    setState(() {
      filteredData[index]['original'] = Map<String, dynamic>.from(
        filteredData[index],
      );
      filteredData[index]['isEditing'] = true;
    });
  }

  void _cancelEdit(int index) {
    setState(() {
      filteredData[index] = Map<String, dynamic>.from(
        filteredData[index]['original'],
      );
      filteredData[index]['isEditing'] = false;
    });
  }

  void _saveEdit(int index) {
    setState(() {
      final entry = filteredData[index];
      entry['totalPrice'] = (entry['unitPrice'] * entry['amount']);
      entry['isEditing'] = false;

      int origIndex = voucherData.indexWhere((e) => e['id'] == entry['id']);
      if (origIndex != -1) voucherData[origIndex] = Map.from(entry);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Voucher updated')));
  }

  void _deleteRow(int index) {
    setState(() {
      final id = filteredData[index]['id'];
      filteredData.removeAt(index);
      voucherData.removeWhere((e) => e['id'] == id);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Voucher deleted')));
  }

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
            borderSide: const BorderSide(color: Color(0xFF0052CC)),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color.fromARGB(255, 252, 235, 235)),
      ),
    );
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
      leading: Icon(
        icon,
        color: color ?? (selected ? Colors.blue : Colors.black),
      ),
      title: Text(title, style: TextStyle(color: color ?? Colors.black)),
      onTap: onTap,
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF002B5B), Color(0xFF1A4D8F)],
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage('assets/me.png'),
                      radius: 30,
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        "Shoaib Ahmed Sami",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
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
                        Navigator.pushReplacement(
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
                      onTap: () => Navigator.pop(context),
                      selected: true,
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
                      onTap: () {},
                    ),
                    _buildSidebarTile(
                      icon: Icons.analytics,
                      title: "Meal State",
                      onTap: () {},
                    ),
                    _buildSidebarTile(
                      icon: Icons.thumb_up,
                      title: "Menu Vote",
                      onTap: () {},
                    ),
                    _buildSidebarTile(
                      icon: Icons.receipt_long,
                      title: "Bills",
                      onTap: () {},
                    ),
                    _buildSidebarTile(
                      icon: Icons.payment,
                      title: "Payments",
                      onTap: () {},
                    ),
                    _buildSidebarTile(
                      icon: Icons.people_alt,
                      title: "Dining Member State",
                      onTap: () {},
                    ),
                    _buildSidebarTile(
                      icon: Icons.manage_accounts,
                      title: "Staff State",
                      onTap: () {},
                    ),
                    _buildSidebarTile(
                      icon: Icons.restaurant,
                      title: "Cook State",
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                ),
                child: _buildSidebarTile(
                  icon: Icons.logout,
                  title: "Logout",
                  color: Colors.red,
                  onTap: _logout,
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Voucher List",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Add Voucher Button First
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminAddShoppingScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Add Voucher"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052CC),
                  foregroundColor: Colors.white,
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

            // ✅ Search Bar
            TextFormField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  filteredData = voucherData.where((entry) {
                    return entry.values.any(
                      (v) => v.toString().toLowerCase().contains(
                        value.toLowerCase(),
                      ),
                    );
                  }).toList();
                });
              },
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Search by ID, Buyer, Date...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0052CC)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ✅ Voucher Table
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFF134074),
                  ),
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  columns: const [
                    DataColumn(label: Text("Voucher ID")),
                    DataColumn(label: Text("Date")),
                    DataColumn(label: Text("Buyer")),
                    DataColumn(label: Text("Unit Price")),
                    DataColumn(label: Text("Amount")),
                    DataColumn(label: Text("Total Price")),
                    DataColumn(label: Text("Action")),
                  ],
                  rows: List.generate(filteredData.length, (index) {
                    final entry = filteredData[index];
                    final isEditing = entry['isEditing'] as bool;

                    return DataRow(
                      cells: [
                        DataCell(
                          isEditing
                              ? _editableTextField(
                                  initialValue: entry['id'],
                                  onChanged: (val) => entry['id'] = val,
                                )
                              : Text(entry['id']),
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
                                  initialValue: entry['buyer'],
                                  onChanged: (val) => entry['buyer'] = val,
                                )
                              : Text(entry['buyer']),
                        ),
                        DataCell(
                          isEditing
                              ? _editableTextField(
                                  initialValue: entry['unitPrice'].toString(),
                                  onChanged: (val) {
                                    entry['unitPrice'] =
                                        double.tryParse(val) ?? 0;
                                    entry['totalPrice'] =
                                        entry['unitPrice'] * entry['amount'];
                                    setState(() {});
                                  },
                                  keyboardType: TextInputType.number,
                                )
                              : Text('${entry['unitPrice']}'),
                        ),
                        DataCell(
                          isEditing
                              ? _editableTextField(
                                  initialValue: entry['amount'].toString(),
                                  onChanged: (val) {
                                    entry['amount'] = double.tryParse(val) ?? 0;
                                    entry['totalPrice'] =
                                        entry['unitPrice'] * entry['amount'];
                                    setState(() {});
                                  },
                                  keyboardType: TextInputType.number,
                                )
                              : Text('${entry['amount']}'),
                        ),
                        DataCell(
                          Text('${entry['totalPrice'].toStringAsFixed(2)}'),
                        ),
                        DataCell(
                          Row(
                            children: [
                              if (!isEditing)
                                _actionButton(
                                  text: "Edit",
                                  color: const Color(0xFF0052CC),
                                  onPressed: () => _startEdit(index),
                                ),
                              if (isEditing) ...[
                                _actionButton(
                                  text: "Save",
                                  color: Colors.green,
                                  onPressed: () => _saveEdit(index),
                                ),
                                const SizedBox(width: 6),
                                _actionButton(
                                  text: "Cancel",
                                  color: Colors.grey,
                                  onPressed: () => _cancelEdit(index),
                                ),
                              ],
                              const SizedBox(width: 6),
                              _actionButton(
                                text: "Delete",
                                color: Colors.red,
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
    );
  }
}

import 'package:flutter/material.dart';
import '../login_screen.dart';
import 'admin_home_screen.dart';
import 'admin_users_screen.dart';
import 'admin_pending_ids_screen.dart';
import 'admin_shopping_history.dart';
import 'admin_voucher_screen.dart';
import 'add_inventory_screen.dart';
import 'admin_messing_screen.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
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

  // Simplified inventory data
  List<Map<String, dynamic>> inventoryData = [
    {
      'id': 'I001',
      'productName': 'Cable Wire',
      'quantityHeld': 100,
      'type': 'utensils',
      'isEditing': false,
      'original': {},
    },
    {
      'id': 'I002',
      'productName': 'Rice',
      'quantityHeld': 500,
      'type': 'ration',
      'isEditing': false,
      'original': {},
    },
    {
      'id': 'I003',
      'productName': 'Fresh Milk',
      'quantityHeld': 200,
      'type': 'fresh',
      'isEditing': false,
      'original': {},
    },
  ];

  List<Map<String, dynamic>> filteredData = [];

  final TextEditingController _searchController = TextEditingController();

  final List<String> _types = ['fresh', 'utensils', 'ration'];

  @override
  void initState() {
    super.initState();
    filteredData = List.from(inventoryData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      filteredData[index]['isEditing'] = false;

      int origIndex = inventoryData.indexWhere(
        (e) => e['id'] == filteredData[index]['id'],
      );
      if (origIndex != -1)
        inventoryData[origIndex] = Map.from(filteredData[index]);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Inventory updated')));
  }

  void _deleteRow(int index) {
    setState(() {
      final id = filteredData[index]['id'];
      filteredData.removeAt(index);
      inventoryData.removeWhere((e) => e['id'] == id);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Inventory item deleted')));
  }

  Widget _editableTextField({
    required String initialValue,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      width: 140,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
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
                  children: [
                    _buildSidebarTile(
                      icon: Icons.dashboard,
                      title: "Home",
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminHomeScreen(),
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
                            builder: (_) => const AdminUsersScreen(),
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
                            builder: (_) => const AdminPendingIdsScreen(),
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
                            builder: (_) => const AdminShoppingHistoryScreen(),
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
                            builder: (_) => const AdminVoucherScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSidebarTile(
                      icon: Icons.storage,
                      title: "Inventory",
                      onTap: () => Navigator.pop(context),
                      selected: true,
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
                    // Other sidebar tiles ...
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
                  onTap: _logout,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),

      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Inventory",
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddInventoryScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text("Add Inventory Entry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052CC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            TextFormField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  filteredData = inventoryData.where((entry) {
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
                hintText: 'Search by ID, Product Name, Type...',
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

            // Inventory table
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    const Color(0xFF134074),
                  ),
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  columns: const [
                    DataColumn(label: Text("ID")),
                    DataColumn(label: Text("Product Name")),
                    DataColumn(label: Text("Quantity Held")),
                    DataColumn(label: Text("Type")),
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
                                  initialValue: entry['productName'],
                                  onChanged: (val) =>
                                      entry['productName'] = val,
                                )
                              : Text(entry['productName']),
                        ),
                        DataCell(
                          isEditing
                              ? _editableTextField(
                                  initialValue: entry['quantityHeld']
                                      .toString(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    entry['quantityHeld'] =
                                        int.tryParse(val) ?? 0;
                                    setState(() {});
                                  },
                                )
                              : Text('${entry['quantityHeld']}'),
                        ),
                        DataCell(
                          isEditing
                              ? DropdownButton<String>(
                                  value: entry['type'],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        entry['type'] = val;
                                      });
                                    }
                                  },
                                  items: _types
                                      .map(
                                        (type) => DropdownMenuItem(
                                          value: type,
                                          child: Text(
                                            type[0].toUpperCase() +
                                                type.substring(1),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                )
                              : Text(
                                  entry['type'][0].toUpperCase() +
                                      entry['type'].substring(1),
                                ),
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

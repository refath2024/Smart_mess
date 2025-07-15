import 'package:flutter/material.dart';
import 'add_staff.dart';
import 'admin_home_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_messing_screen.dart';
import 'admin_payment_history.dart';
import 'admin_pending_ids_screen.dart';
import 'admin_shopping_history.dart';
import 'admin_users_screen.dart';
import 'admin_voucher_screen.dart';
import 'cook_state.dart';

class AdminStaffStateScreen extends StatefulWidget {
  const AdminStaffStateScreen({super.key});

  @override
  State<AdminStaffStateScreen> createState() => _AdminStaffStateScreenState();
}

class _AdminStaffStateScreenState extends State<AdminStaffStateScreen> {
  final List<Map<String, String>> staffData = [
    {
      'no': '12345',
      'rank': 'Sergeant',
      'name': 'John Doe',
      'unit': 'Alpha',
      'mobile': '017xxxxxxxx',
      'email': 'john@example.com',
      'role': 'Admin',
      'status': 'Active',
    },
    {
      'no': '67890',
      'rank': 'Corporal',
      'name': 'Jane Smith',
      'unit': 'Bravo',
      'mobile': '018xxxxxxxx',
      'email': 'jane@example.com',
      'role': 'Staff',
      'status': 'Inactive',
    },
  ];

  String searchTerm = '';

  void _navigateToAddStaff() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddNewUserForm()),
    );
  }



  @override
  Widget build(BuildContext context) {
    final filteredData = staffData.where((row) {
      return row.values.any((value) => value.toLowerCase().contains(searchTerm));
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
                    ListTile(
                      leading: const Icon(Icons.dashboard),
                      title: const Text("Home"),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminHomeScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.people),
                      title: const Text("Users"),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminUsersScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.pending),
                      title: const Text("Pending IDs"),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminPendingIdsScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text("Shopping History"),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminShoppingHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.receipt),
                      title: const Text("Voucher List"),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminVoucherScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.storage),
                      title: const Text("Inventory"),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminInventoryScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.food_bank),
                      title: const Text("Messing"),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminMessingScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.menu_book),
                      title: const Text("Monthly Menu"),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.analytics),
                      title: const Text("Meal State"),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.thumb_up),
                      title: const Text("Menu Vote"),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: const Text("Bills"),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.payment),
                      title: const Text("Payments"),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaymentsDashboard(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.people_alt),
                      title: const Text("Dining Member State"),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.manage_accounts),
                      title: const Text("Staff State"),
                      selected: true,
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.restaurant_menu),
                      title: const Text("Cook State"),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CookStatePage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
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
                  ElevatedButton(
                    onPressed: _navigateToAddStaff,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Add Staffs/Admin'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('BA/ID No')),
                      DataColumn(label: Text('Rank')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Unit')),
                      DataColumn(label: Text('Mobile No')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: filteredData.map((row) {
                      return DataRow(
                        cells: [
                          DataCell(Text(row['no'] ?? '')),
                          DataCell(Text(row['rank'] ?? '')),
                          DataCell(Text(row['name'] ?? '')),
                          DataCell(Text(row['unit'] ?? '')),
                          DataCell(Text(row['mobile'] ?? '')),
                          DataCell(Text(row['email'] ?? '')),
                          DataCell(Text(row['role'] ?? '')),
                          DataCell(
                            DropdownButton<String>(
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
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.grey),
                                  onPressed: () {
                                    // Implement edit logic
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.save, color: Colors.blue),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Saved changes')),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      staffData.remove(row);
                                    });
                                  },
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

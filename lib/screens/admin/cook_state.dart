import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'admin_home_screen.dart';
import 'admin_users_screen.dart';
import 'admin_pending_ids_screen.dart';
import 'admin_shopping_history.dart';
import 'admin_voucher_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_messing_screen.dart';
import 'admin_staff_state_screen.dart' as staff_screen;
import '../login_screen.dart';
import 'admin_payment_history.dart';

class CookStatePage extends StatefulWidget {
  const CookStatePage({super.key});

  @override
  State<CookStatePage> createState() => _CookStatePageState();
}

class _CookStatePageState extends State<CookStatePage> {
  List<Map<String, dynamic>> cooks = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchCooks();
  }

  Future<void> fetchCooks() async {
    try {
      final response = await http.get(Uri.parse('https://your-domain.com/fetch_cook.php'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          cooks = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void deleteCook(String no) async {
    try {
      final response = await http.post(
        Uri.parse('https://your-domain.com/delete_cook.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'no': no}),
      );

      if (response.statusCode == 200) {
        setState(() => cooks.removeWhere((cook) => cook['no'] == no));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cook deleted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredCooks = cooks.where((cook) {
      final values = cook.values.join().toLowerCase();
      return values.contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Cook State",
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
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const staff_screen.AdminStaffStateScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.restaurant_menu),
                      title: const Text("Cook State"),
                      selected: true,
                      onTap: () => Navigator.pop(context),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: 'Search All Text Columns',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Add Cooks'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID No')),
                      DataColumn(label: Text('Rank')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Unit')),
                      DataColumn(label: Text('Mobile No')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: filteredCooks.map((cook) {
                      return DataRow(cells: [
                        DataCell(Text(cook['no']?.toString() ?? '')),
                        DataCell(Text(cook['rank']?.toString() ?? '')),
                        DataCell(Text(cook['name']?.toString() ?? '')),
                        DataCell(Text(cook['unit']?.toString() ?? '')),
                        DataCell(Text(cook['mobile']?.toString() ?? '')),
                        DataCell(Text(cook['email']?.toString() ?? '')),
                        DataCell(Text(cook['role']?.toString() ?? '')),
                        DataCell(Text(cook['status']?.toString() ?? '')),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.grey),
                              onPressed: () {},
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
                              onPressed: () => deleteCook(cook['no'].toString()),
                            ),
                          ],
                        )),
                      ]);
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

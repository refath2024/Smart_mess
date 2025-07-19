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
import 'admin_dining_member_state.dart';
import 'admin_bill_screen.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_menu_vote_screen.dart';
import 'admin_meal_state_screen.dart';

class PaymentData {
  final double amount;
  final DateTime paymentTime;
  final String paymentMethod;
  final String baNo;
  final String rank;
  final String name;

  PaymentData({
    required this.amount,
    required this.paymentTime,
    required this.paymentMethod,
    required this.baNo,
    required this.rank,
    required this.name,
  });
}

class PaymentsDashboard extends StatefulWidget {
  const PaymentsDashboard({super.key});

  @override
  State<PaymentsDashboard> createState() => _PaymentsDashboardState();
}

class _PaymentsDashboardState extends State<PaymentsDashboard> {
  int? editingIndex;
  List<TextEditingController> controllers = [];

  final List<PaymentData> transactions = [
    PaymentData(
      amount: 3500.00,
      paymentTime: DateTime.now().subtract(const Duration(hours: 2)),
      paymentMethod: 'Bkash',
      baNo: 'BA-1234',
      rank: 'Major',
      name: 'John Smith',
    ),
    PaymentData(
      amount: 2950.00,
      paymentTime: DateTime.now().subtract(const Duration(hours: 5)),
      paymentMethod: 'Bank',
      baNo: 'BA-5678',
      rank: 'Captain',
      name: 'Sarah Johnson',
    ),
    PaymentData(
      amount: 4200.00,
      paymentTime: DateTime.now().subtract(const Duration(days: 1)),
      paymentMethod: 'Card',
      baNo: 'BA-9012',
      rank: 'Lieutenant',
      name: 'David Wilson',
    ),
    PaymentData(
      amount: 3100.00,
      paymentTime: DateTime.now().subtract(const Duration(days: 2)),
      paymentMethod: 'Cash',
      baNo: 'BA-3456',
      rank: 'Major',
      name: 'Michael Brown',
    ),
    PaymentData(
      amount: 2800.00,
      paymentTime: DateTime.now().subtract(const Duration(days: 2)),
      paymentMethod: 'Tap',
      baNo: 'BA-7890',
      rank: 'Captain',
      name: 'Emma Davis',
    ),
  ];

  String searchQuery = '';

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

  void _editTransaction(int index) {
    setState(() {
      editingIndex = index;
      final txn = transactions[index];
      controllers = [
        TextEditingController(text: txn.amount.toString()),
        TextEditingController(text: txn.paymentTime.toString()),
        TextEditingController(text: txn.paymentMethod),
        TextEditingController(text: txn.baNo),
        TextEditingController(text: txn.rank),
        TextEditingController(text: txn.name),
      ];
    });
  }

  void _saveTransaction(int index) {
    // Validate required fields
    if (controllers.any((controller) => controller.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All fields are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate amount is a valid number
    final amount = double.tryParse(controllers[0].text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid payment amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      // Convert date string back to DateTime
      final DateTime paymentTime = DateTime.tryParse(controllers[1].text) ??
          transactions[index].paymentTime;

      transactions[index] = PaymentData(
        amount: amount,
        paymentTime: paymentTime,
        paymentMethod: controllers[2].text,
        baNo: controllers[3].text,
        rank: controllers[4].text,
        name: controllers[5].text,
      );
      editingIndex = null;
      controllers.clear();
    });
  }

  void _cancelEdit() {
    setState(() {
      editingIndex = null;
      controllers.clear();
    });
  }

  void _deleteTransaction(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content:
            const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                transactions.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = transactions.where((txn) {
      final searchLower = searchQuery.toLowerCase();
      return txn.name.toLowerCase().contains(searchLower) ||
          txn.baNo.toLowerCase().contains(searchLower) ||
          txn.rank.toLowerCase().contains(searchLower) ||
          txn.paymentMethod.toLowerCase().contains(searchLower);
    }).toList();

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
                      onTap: () => Navigator.pop(context),
                      selected: true,
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
          "Payments History",
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    onChanged: (val) => setState(() => searchQuery = val),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement add transaction
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Insert Transaction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                        MaterialStateProperty.all(const Color(0xFFF4F4F4)),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Payment Amount (BDT)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Payment Time',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Payment Method',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'BA No',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Rank',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: List.generate(filtered.length, (index) {
                      final txn = filtered[index];
                      final isEditing = editingIndex == index;

                      return DataRow(
                        cells: [
                          DataCell(
                            isEditing
                                ? SizedBox(
                                    width: 100,
                                    child: TextField(
                                      controller: controllers[0],
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 8),
                                      ),
                                    ),
                                  )
                                : Text('${txn.amount} BDT'),
                          ),
                          DataCell(
                            isEditing
                                ? SizedBox(
                                    width: 150,
                                    child: TextField(
                                      controller: controllers[1],
                                      readOnly: true,
                                      onTap: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.tryParse(
                                                  controllers[1].text) ??
                                              DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime.now(),
                                        );
                                        if (date != null) {
                                          final time = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.now(),
                                          );
                                          if (time != null) {
                                            final dateTime = DateTime(
                                              date.year,
                                              date.month,
                                              date.day,
                                              time.hour,
                                              time.minute,
                                            );
                                            controllers[1].text =
                                                dateTime.toString();
                                          }
                                        }
                                      },
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 8),
                                        suffixIcon: Icon(Icons.calendar_today,
                                            size: 18),
                                      ),
                                    ),
                                  )
                                : Text(txn.paymentTime.toString()),
                          ),
                          DataCell(
                            isEditing
                                ? DropdownButtonFormField<String>(
                                    value: txn.paymentMethod,
                                    items:
                                        ['Bank', 'Card', 'Bkash', 'Tap', 'Cash']
                                            .map((method) => DropdownMenuItem(
                                                  value: method,
                                                  child: Text(method),
                                                ))
                                            .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        controllers[2].text = val;
                                      }
                                    },
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  )
                                : Text(txn.paymentMethod),
                          ),
                          DataCell(
                            isEditing
                                ? TextField(
                                    controller: controllers[3],
                                    decoration: const InputDecoration(
                                      isDense: true,
                                    ),
                                  )
                                : Text(txn.baNo),
                          ),
                          DataCell(
                            isEditing
                                ? TextField(
                                    controller: controllers[4],
                                    decoration: const InputDecoration(
                                      isDense: true,
                                    ),
                                  )
                                : Text(txn.rank),
                          ),
                          DataCell(
                            isEditing
                                ? TextField(
                                    controller: controllers[5],
                                    decoration: const InputDecoration(
                                      isDense: true,
                                    ),
                                  )
                                : Text(txn.name),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isEditing) ...[
                                  IconButton(
                                    icon: const Icon(Icons.save,
                                        color: Colors.green),
                                    onPressed: () => _saveTransaction(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel,
                                        color: Colors.grey),
                                    onPressed: _cancelEdit,
                                  ),
                                ] else ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _editTransaction(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteTransaction(index),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
import 'admin_payment_history.dart';
import 'admin_bill_screen.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_menu_vote_screen.dart';

class AdminMealStateScreen extends StatefulWidget {
  const AdminMealStateScreen({Key? key}) : super(key: key);

  @override
  State<AdminMealStateScreen> createState() => _AdminMealStateScreenState();
}

class _AdminMealStateScreenState extends State<AdminMealStateScreen> {
  final TextEditingController _searchController = TextEditingController();
  late DateTime displayDate;
  List<Map<String, dynamic>> filteredRecords = [];
  int? editingIndex;
  final TextEditingController _breakfastController = TextEditingController();
  final TextEditingController _lunchController = TextEditingController();
  final TextEditingController _dinnerController = TextEditingController();
  final TextEditingController _disposalsController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    updateDisplayDate();
    filteredRecords = List.from(records);
  }

  void _filterRecords(String query) {
    setState(() {
      filteredRecords = records.where((record) {
        return record.values.any((value) =>
            value.toString().toLowerCase().contains(query.toLowerCase()));
      }).toList();
    });
  }

  void _startEditing(int index, Map<String, dynamic> record) {
    setState(() {
      editingIndex = index;
      _breakfastController.text = record['Breakfast'];
      _lunchController.text = record['Lunch'];
      _dinnerController.text = record['Dinner'];
      _disposalsController.text = record['Disposals'];
      _remarksController.text = record['Remarks'];
    });
  }

  void _saveEditing(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Save'),
        content: const Text('Are you sure you want to save the changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          records[index]['Breakfast'] = _breakfastController.text;
          records[index]['Lunch'] = _lunchController.text;
          records[index]['Dinner'] = _dinnerController.text;
          records[index]['Disposals'] = _disposalsController.text;
          records[index]['Remarks'] = _remarksController.text;
          editingIndex = null;
          _filterRecords(_searchController.text); // Refresh filtered records
        });
      }
    });
  }

  void _cancelEditing() {
    setState(() {
      editingIndex = null;
    });
  }

  void _deleteRecord(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                records.removeAt(index);
                _filterRecords(
                    _searchController.text); // Refresh filtered records
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

  void updateDisplayDate() {
    final now = DateTime.now();
    final currentTime = now.hour * 100 + now.minute; // Convert to HHMM format

    if (currentTime >= 2115) {
      // After 21:15, show day after tomorrow
      displayDate = DateTime.now().add(const Duration(days: 2));
    } else {
      // Before 21:15, show tomorrow
      displayDate = DateTime.now().add(const Duration(days: 1));
    }
  }

  // Dummy data for table
  final List<Map<String, dynamic>> records = [
    {
      'BA No': 'BA-1234',
      'Rk': 'Maj',
      'Name': 'John Smith',
      'Breakfast': 'Yes',
      'Lunch': 'No',
      'Dinner': 'Yes',
      'Disposals': 'None',
      'Remarks': 'Extra egg',
    },
    {
      'BA No': 'BA-5678',
      'Rk': 'Capt',
      'Name': 'Jane Doe',
      'Breakfast': 'No',
      'Lunch': 'Yes',
      'Dinner': 'Yes',
      'Disposals': 'SIQ',
      'Remarks': '',
    },
    {
      'BA No': 'BA-9012',
      'Rk': 'Lt',
      'Name': 'Mike Johnson',
      'Breakfast': 'Yes',
      'Lunch': 'Yes',
      'Dinner': 'No',
      'Disposals': 'Leave',
      'Remarks': 'Extra fish',
    },
  ];

  // Counting functions
  int countMealState(String meal, String state) {
    return records.where((record) => record[meal] == state).length;
  }

  int countDisposals(String type) {
    return records.where((record) => record['Disposals'] == type).length;
  }

  int countRemarksPresent() {
    return records
        .where((record) => record['Remarks'].toString().isNotEmpty)
        .length;
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
                      selected: true,
                      onTap: () => Navigator.pop(context),
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

                    // Add more sidebar items as needed
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
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
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
          "Officer Meal State",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 180, // Reduced width
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterRecords,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A4D8F),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'See Records',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Date: ${displayDate.day}/${displayDate.month}/${displayDate.year}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('BA No')),
                    DataColumn(label: Text('Rk')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Breakfast')),
                    DataColumn(label: Text('Lunch')),
                    DataColumn(label: Text('Dinner')),
                    DataColumn(label: Text('Disposals')),
                    DataColumn(label: Text('Remarks')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: filteredRecords.isEmpty
                      ? [
                          DataRow(
                              cells: List.generate(
                                  9, (index) => const DataCell(Text('-')))),
                        ]
                      : List.generate(filteredRecords.length, (index) {
                          final record = filteredRecords[index];
                          final isEditing = editingIndex == index;

                          return DataRow(cells: [
                            DataCell(Text(record['BA No'] ?? '')),
                            DataCell(Text(record['Rk'] ?? '')),
                            DataCell(Text(record['Name'] ?? '')),
                            DataCell(
                              isEditing
                                  ? DropdownButton<String>(
                                      value: _breakfastController.text,
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'Yes', child: Text('Yes')),
                                        DropdownMenuItem(
                                            value: 'No', child: Text('No')),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _breakfastController.text = value!;
                                          filteredRecords[index]['Breakfast'] =
                                              value;
                                        });
                                      },
                                    )
                                  : Text(record['Breakfast'] ?? ''),
                            ),
                            DataCell(
                              isEditing
                                  ? DropdownButton<String>(
                                      value: _lunchController.text,
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'Yes', child: Text('Yes')),
                                        DropdownMenuItem(
                                            value: 'No', child: Text('No')),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _lunchController.text = value!;
                                          filteredRecords[index]['Lunch'] =
                                              value;
                                        });
                                      },
                                    )
                                  : Text(record['Lunch'] ?? ''),
                            ),
                            DataCell(
                              isEditing
                                  ? DropdownButton<String>(
                                      value: _dinnerController.text,
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'Yes', child: Text('Yes')),
                                        DropdownMenuItem(
                                            value: 'No', child: Text('No')),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _dinnerController.text = value!;
                                          filteredRecords[index]['Dinner'] =
                                              value;
                                        });
                                      },
                                    )
                                  : Text(record['Dinner'] ?? ''),
                            ),
                            DataCell(
                              isEditing
                                  ? DropdownButton<String>(
                                      value: _disposalsController.text,
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'None', child: Text('None')),
                                        DropdownMenuItem(
                                            value: 'SIQ', child: Text('SIQ')),
                                        DropdownMenuItem(
                                            value: 'Leave',
                                            child: Text('Leave')),
                                        DropdownMenuItem(
                                            value: 'Mess Out',
                                            child: Text('Mess Out')),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _disposalsController.text = value!;
                                          filteredRecords[index]['Disposals'] =
                                              value;
                                        });
                                      },
                                    )
                                  : Text(record['Disposals'] ?? ''),
                            ),
                            DataCell(
                              isEditing
                                  ? TextField(
                                      controller: _remarksController,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter remarks',
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          filteredRecords[index]['Remarks'] =
                                              value;
                                        });
                                      },
                                    )
                                  : Text(record['Remarks'] ?? ''),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isEditing) ...[
                                    IconButton(
                                      icon: const Icon(Icons.save,
                                          color: Colors.green),
                                      onPressed: () => _saveEditing(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel,
                                          color: Colors.red),
                                      onPressed: _cancelEditing,
                                    ),
                                  ] else ...[
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Color(0xFF1A4D8F)),
                                      onPressed: () =>
                                          _startEditing(index, record),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _deleteRecord(index),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Breakfast Members: ${countMealState('Breakfast', 'Yes')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Lunch Members: ${countMealState('Lunch', 'Yes')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Dinner Members: ${countMealState('Dinner', 'Yes')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Disposals: SIQ = ${countDisposals('SIQ')}, Leave = ${countDisposals('Leave')}, Mess Out = ${countDisposals('Mess Out')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Remarks Count: ${countRemarksPresent()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
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
import 'admin_meal_state_screen.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_menu_vote_screen.dart';
import 'admin_login_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/admin_auth_service.dart';

class AdminBillScreen extends StatefulWidget {
  const AdminBillScreen({Key? key}) : super(key: key);

  @override
  State<AdminBillScreen> createState() => _AdminBillScreenState();
}

class _AdminBillScreenState extends State<AdminBillScreen> {
  final AdminAuthService _adminAuthService = AdminAuthService();

  bool _isLoading = true;
  String _currentUserName = "Admin User";
  Map<String, dynamic>? _currentUserData;

  List<Map<String, dynamic>> bills = []; // will hold bill data
  List<Map<String, dynamic>> filteredBills = [];
  String searchTerm = "";
  int? editingIndex;
  final TextEditingController _previousArrearController =
      TextEditingController();
  final TextEditingController _currentBillController = TextEditingController();

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

        // After authentication is confirmed, fetch bills
        fetchBills();
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

  void _filterBills(String query) {
    setState(() {
      filteredBills = bills.where((bill) {
        final combined =
            (bill['ba_no'] + bill['rank'] + bill['name']).toLowerCase();
        return combined.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _startEditing(int index, Map<String, dynamic> bill) {
    setState(() {
      editingIndex = index;
      _previousArrearController.text = bill['previous_arrear'].toString();
      _currentBillController.text = bill['current_bill'].toString();
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
          final previousArrear =
              double.tryParse(_previousArrearController.text) ?? 0.0;
          final currentBill =
              double.tryParse(_currentBillController.text) ?? 0.0;
          final totalDue = previousArrear + currentBill;

          bills[index]['previous_arrear'] = previousArrear;
          bills[index]['current_bill'] = currentBill;
          bills[index]['total_due'] = totalDue;
          bills[index]['bill_status'] = totalDue > 0 ? 'Unpaid' : 'Paid';

          editingIndex = null;
          _filterBills(searchTerm); // Refresh filtered bills
        });
      }
    });
  }

  void _cancelEditing() {
    setState(() {
      editingIndex = null;
    });
  }

  void _deleteBill(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content:
            const Text('Are you sure you want to delete this bill record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                bills.removeAt(index);
                _filterBills(searchTerm); // Refresh filtered bills
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

  void fetchBills() {
    // Simulated API data fetch (replace with actual logic)
    setState(() {
      bills = [
        {
          "ba_no": "123456",
          "rank": "Captain",
          "name": "Rahim",
          "bill_status": "Unpaid",
          "previous_arrear": 500,
          "current_bill": 1500,
          "total_due": 2000
        },
        {
          "ba_no": "654321",
          "rank": "Major",
          "name": "Karim",
          "bill_status": "Paid",
          "previous_arrear": 0,
          "current_bill": 1700,
          "total_due": 1700
        },
        {
          "ba_no": "789012",
          "rank": "Lieutenant",
          "name": "Ahmed",
          "bill_status": "Unpaid",
          "previous_arrear": 200,
          "current_bill": 1400,
          "total_due": 1600
        },
        // Add more dummy data as needed
      ];
      filteredBills = List.from(bills);
    });
  }

  // PDF GENERATION FUNCTION
  Future<void> _generateBillsPdf(List<Map<String, dynamic>> bills) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(
              level: 0,
              child: pw.Text('Bills Report',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.Table.fromTextArray(
            headers: [
              'BA No',
              'Rank',
              'Name',
              'Status',
              'Arrear',
              'Current Bill',
              'Total Due'
            ],
            data: bills
                .map((bill) => [
                      bill['ba_no'],
                      bill['rank'],
                      bill['name'],
                      bill['bill_status'],
                      bill['previous_arrear'].toString(),
                      bill['current_bill'].toString(),
                      bill['total_due'].toString(),
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: pw.TextStyle(fontSize: 12),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blue50),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
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

    final filteredBills = bills.where((bill) {
      final combined =
          (bill['ba_no'] + bill['rank'] + bill['name']).toLowerCase();
      return combined.contains(searchTerm.toLowerCase());
    }).toList();

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
                    selected: true,
                    onTap: () => Navigator.pop(context),
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
          "Bills",
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
            // Search bar
            Row(
              children: [
                SizedBox(
                  width: 180, // Reduced width
                  child: TextField(
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
                    onChanged: (val) {
                      setState(() => searchTerm = val);
                      _filterBills(val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (filteredBills.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No bills to export")),
                      );
                    } else {
                      await _generateBillsPdf(filteredBills);
                    }
                  },
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
                    'Export Bills',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Table
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    const Color(0xFF1A4D8F),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'BA No',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Rank',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Name',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Previous Arrear',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Current Bill',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Total Due',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Action',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  rows: filteredBills.isEmpty
                      ? [
                          DataRow(
                              cells: List.generate(
                                  8, (index) => const DataCell(Text('-')))),
                        ]
                      : List.generate(filteredBills.length, (index) {
                          final bill = filteredBills[index];
                          final isEditing = editingIndex == index;

                          return DataRow(cells: [
                            DataCell(Text(bill['ba_no'] ?? '')),
                            DataCell(Text(bill['rank'] ?? '')),
                            DataCell(Text(bill['name'] ?? '')),
                            DataCell(
                              Text(
                                bill['bill_status'] ?? '',
                                style: TextStyle(
                                  color: bill['bill_status'] == 'Paid'
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              isEditing
                                  ? SizedBox(
                                      width: 80,
                                      child: TextField(
                                        controller: _previousArrearController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.all(8),
                                        ),
                                      ),
                                    )
                                  : Text('৳${bill['previous_arrear']}'),
                            ),
                            DataCell(
                              isEditing
                                  ? SizedBox(
                                      width: 80,
                                      child: TextField(
                                        controller: _currentBillController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.all(8),
                                        ),
                                      ),
                                    )
                                  : Text('৳${bill['current_bill']}'),
                            ),
                            DataCell(Text('৳${bill['total_due']}')),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isEditing) ...[
                                    IconButton(
                                      icon: const Icon(Icons.save,
                                          color: Colors.green),
                                      onPressed: () => _saveEditing(index),
                                      tooltip: 'Save',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel,
                                          color: Colors.orange),
                                      onPressed: _cancelEditing,
                                      tooltip: 'Cancel',
                                    ),
                                  ] else ...[
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          _startEditing(index, bill),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _deleteBill(index),
                                      tooltip: 'Delete',
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
          ],
        ),
      ),
    );
  }
}

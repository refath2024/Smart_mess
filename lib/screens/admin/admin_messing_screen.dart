import 'package:flutter/material.dart';

import 'admin_home_screen.dart';
import 'admin_users_screen.dart';
import 'admin_pending_ids_screen.dart';
import 'admin_shopping_history.dart';
import 'admin_voucher_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_staff_state_screen.dart';
import 'admin_dining_member_state.dart';
import 'admin_payment_history.dart';
import 'admin_bill_screen.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_menu_vote_screen.dart';
import 'admin_meal_state_screen.dart';
import 'add_indl_entry.dart';
import 'add_misc_entry.dart';
import 'add_messing.dart';
import 'admin_login_screen.dart';
import '../../services/admin_auth_service.dart';

class AdminMessingScreen extends StatefulWidget {
  const AdminMessingScreen({super.key});

  @override
  State<AdminMessingScreen> createState() => _AdminMessingScreenState();
}

class _AdminMessingScreenState extends State<AdminMessingScreen> {
  final AdminAuthService _adminAuthService = AdminAuthService();

  bool _isLoading = true;
  String _currentUserName = "Admin User";
  Map<String, dynamic>? _currentUserData;

  TextEditingController searchController = TextEditingController();
  String currentDay = "";
  String userName = "Admin";

  // Track which row is being edited for each meal
  int? editingBreakfastIndex;
  int? editingLunchIndex;
  int? editingDinnerIndex;

  // Controllers for editing
  List<TextEditingController> breakfastControllers = [];
  List<TextEditingController> lunchControllers = [];
  List<TextEditingController> dinnerControllers = [];

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _fetchCurrentDay();
    _initControllers();
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

  List<Map<String, dynamic>> breakfastEntries = [
    {
      "id": 1,
      "ingredient_name": "Egg",
      "amount": 100,
      "total_prices": 200,
      "members": 10,
      "ingredient_price": 20,
    },
  ];
  List<Map<String, dynamic>> lunchEntries = [
    {
      "id": 2,
      "ingredient_name": "Rice",
      "amount": 500,
      "total_prices": 400,
      "members": 10,
      "ingredient_price": 40,
    },
  ];
  List<Map<String, dynamic>> dinnerEntries = [
    {
      "id": 3,
      "ingredient_name": "Chicken",
      "amount": 300,
      "total_prices": 600,
      "members": 10,
      "ingredient_price": 60,
    },
  ];

  void _initControllers() {
    breakfastControllers = List.generate(
      breakfastEntries.length,
      (i) => TextEditingController(),
    );
    lunchControllers = List.generate(
      lunchEntries.length,
      (i) => TextEditingController(),
    );
    dinnerControllers = List.generate(
      dinnerEntries.length,
      (i) => TextEditingController(),
    );
  }

  void _fetchCurrentDay() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 6));
    final weekday = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ][now.weekday - 1];
    setState(() {
      currentDay = weekday;
    });
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

  Widget _buildTable(
    String title,
    List<Map<String, dynamic>> entries,
    int? editingIndex,
    List<TextEditingController> controllers,
    Function(int) onEdit,
    Function(int) onDelete,
    Function(int) onSave,
    Function(int) onCancel,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Product Name')),
                DataColumn(label: Text('Amount (g)')),
                DataColumn(label: Text('Price')),
                DataColumn(label: Text('Members')),
                DataColumn(label: Text('Unit Price')),
                DataColumn(label: Text('Actions')),
              ],
              rows: List.generate(entries.length, (index) {
                final row = entries[index];
                final isEditing = editingIndex == index;
                if (isEditing) {
                  // Setup controllers for editing
                  final nameController = TextEditingController(
                    text: row['ingredient_name'].toString(),
                  );
                  final amountController = TextEditingController(
                    text: row['amount'].toString(),
                  );
                  final priceController = TextEditingController(
                    text: row['total_prices'].toString(),
                  );
                  final membersController = TextEditingController(
                    text: row['members'].toString(),
                  );
                  final unitPriceController = TextEditingController(
                    text: row['ingredient_price'].toString(),
                  );
                  controllers.clear();
                  controllers.addAll([
                    nameController,
                    amountController,
                    priceController,
                    membersController,
                    unitPriceController,
                  ]);
                }
                return DataRow(
                  cells: [
                    DataCell(
                      isEditing
                          ? SizedBox(
                              width: 100,
                              child: TextField(controller: controllers[0]),
                            )
                          : Text(row['ingredient_name'].toString()),
                    ),
                    DataCell(
                      isEditing
                          ? SizedBox(
                              width: 80,
                              child: TextField(
                                controller: controllers[1],
                                keyboardType: TextInputType.number,
                              ),
                            )
                          : Text(row['amount'].toString()),
                    ),
                    DataCell(
                      isEditing
                          ? SizedBox(
                              width: 80,
                              child: TextField(
                                controller: controllers[2],
                                keyboardType: TextInputType.number,
                              ),
                            )
                          : Text(row['total_prices'].toString()),
                    ),
                    DataCell(
                      isEditing
                          ? SizedBox(
                              width: 80,
                              child: TextField(
                                controller: controllers[3],
                                keyboardType: TextInputType.number,
                              ),
                            )
                          : Text(row['members'].toString()),
                    ),
                    DataCell(
                      isEditing
                          ? SizedBox(
                              width: 80,
                              child: TextField(
                                controller: controllers[4],
                                keyboardType: TextInputType.number,
                              ),
                            )
                          : Text(row['ingredient_price'].toString()),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (!isEditing)
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.grey),
                              onPressed: () => onEdit(index),
                            ),
                          if (isEditing) ...[
                            IconButton(
                              icon: const Icon(Icons.save, color: Colors.green),
                              onPressed: () => onSave(index),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.grey,
                              ),
                              onPressed: () => onCancel(index),
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => onDelete(index),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _editBreakfast(int index) {
    setState(() {
      editingBreakfastIndex = index;
    });
  }

  void _editLunch(int index) {
    setState(() {
      editingLunchIndex = index;
    });
  }

  void _editDinner(int index) {
    setState(() {
      editingDinnerIndex = index;
    });
  }

  Future<void> _saveBreakfast(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Save'),
        content: const Text('Are you sure you want to save these changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        breakfastEntries[index]['ingredient_name'] =
            breakfastControllers[0].text;
        breakfastEntries[index]['amount'] =
            int.tryParse(breakfastControllers[1].text) ??
                breakfastEntries[index]['amount'];
        breakfastEntries[index]['total_prices'] =
            int.tryParse(breakfastControllers[2].text) ??
                breakfastEntries[index]['total_prices'];
        breakfastEntries[index]['members'] =
            int.tryParse(breakfastControllers[3].text) ??
                breakfastEntries[index]['members'];
        breakfastEntries[index]['ingredient_price'] =
            int.tryParse(breakfastControllers[4].text) ??
                breakfastEntries[index]['ingredient_price'];
        editingBreakfastIndex = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Breakfast entry updated successfully')),
        );
      }
    }
  }

  Future<void> _saveLunch(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Save'),
        content: const Text('Are you sure you want to save these changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        lunchEntries[index]['ingredient_name'] = lunchControllers[0].text;
        lunchEntries[index]['amount'] =
            int.tryParse(lunchControllers[1].text) ??
                lunchEntries[index]['amount'];
        lunchEntries[index]['total_prices'] =
            int.tryParse(lunchControllers[2].text) ??
                lunchEntries[index]['total_prices'];
        lunchEntries[index]['members'] =
            int.tryParse(lunchControllers[3].text) ??
                lunchEntries[index]['members'];
        lunchEntries[index]['ingredient_price'] =
            int.tryParse(lunchControllers[4].text) ??
                lunchEntries[index]['ingredient_price'];
        editingLunchIndex = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lunch entry updated successfully')),
        );
      }
    }
  }

  Future<void> _saveDinner(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Save'),
        content: const Text('Are you sure you want to save these changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        dinnerEntries[index]['ingredient_name'] = dinnerControllers[0].text;
        dinnerEntries[index]['amount'] =
            int.tryParse(dinnerControllers[1].text) ??
                dinnerEntries[index]['amount'];
        dinnerEntries[index]['total_prices'] =
            int.tryParse(dinnerControllers[2].text) ??
                dinnerEntries[index]['total_prices'];
        dinnerEntries[index]['members'] =
            int.tryParse(dinnerControllers[3].text) ??
                dinnerEntries[index]['members'];
        dinnerEntries[index]['ingredient_price'] =
            int.tryParse(dinnerControllers[4].text) ??
                dinnerEntries[index]['ingredient_price'];
        editingDinnerIndex = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dinner entry updated successfully')),
        );
      }
    }
  }

  Future<void> _cancelBreakfast(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancel'),
        content: const Text(
            'Are you sure you want to cancel editing? Any unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        editingBreakfastIndex = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Editing cancelled')),
        );
      }
    }
  }

  Future<void> _cancelLunch(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancel'),
        content: const Text(
            'Are you sure you want to cancel editing? Any unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        editingLunchIndex = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Editing cancelled')),
        );
      }
    }
  }

  Future<void> _cancelDinner(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancel'),
        content: const Text(
            'Are you sure you want to cancel editing? Any unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        editingDinnerIndex = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Editing cancelled')),
        );
      }
    }
  }

  Future<void> _deleteBreakfast(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content:
            const Text('Are you sure you want to delete this breakfast entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        breakfastEntries.removeAt(index);
        editingBreakfastIndex = null;
        _initControllers();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Breakfast entry deleted')),
        );
      }
    }
  }

  Future<void> _deleteLunch(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content:
            const Text('Are you sure you want to delete this lunch entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        lunchEntries.removeAt(index);
        editingLunchIndex = null;
        _initControllers();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lunch entry deleted')),
        );
      }
    }
  }

  Future<void> _deleteDinner(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content:
            const Text('Are you sure you want to delete this dinner entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        dinnerEntries.removeAt(index);
        editingDinnerIndex = null;
        _initControllers();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dinner entry deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while authenticating
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                    onTap: () => Navigator.pop(context),
                    selected: true,
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
          "Messing of Today",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddIndlEntryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      label: const Text(
                        "Indl Entry",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A4D8F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 3,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddMiscEntryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.group_add, color: Colors.white),
                      label: const Text(
                        "Misc Entry",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A4D8F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 3,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddMessingScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        "Create",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A4D8F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (term) {
                    // TODO: Implement search logic
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  currentDay,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _buildTable(
                  "Breakfast Entries",
                  breakfastEntries,
                  editingBreakfastIndex,
                  breakfastControllers,
                  _editBreakfast,
                  _deleteBreakfast,
                  _saveBreakfast,
                  _cancelBreakfast,
                ),
                _buildTable(
                  "Lunch Entries",
                  lunchEntries,
                  editingLunchIndex,
                  lunchControllers,
                  _editLunch,
                  _deleteLunch,
                  _saveLunch,
                  _cancelLunch,
                ),
                _buildTable(
                  "Dinner Entries",
                  dinnerEntries,
                  editingDinnerIndex,
                  dinnerControllers,
                  _editDinner,
                  _deleteDinner,
                  _saveDinner,
                  _cancelDinner,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

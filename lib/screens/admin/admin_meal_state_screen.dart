import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
import 'meal_state_record_screen.dart';
import 'admin_login_screen.dart';
import '../../services/admin_auth_service.dart';

class AdminMealStateScreen extends StatefulWidget {
  const AdminMealStateScreen({super.key});

  @override
  State<AdminMealStateScreen> createState() => _AdminMealStateScreenState();
}

class _AdminMealStateScreenState extends State<AdminMealStateScreen> {
  final AdminAuthService _adminAuthService = AdminAuthService();

  bool _isLoading = true;
  bool _isLoadingData = false;
  String _currentUserName = "Admin User";
  Map<String, dynamic>? _currentUserData;

  final TextEditingController _searchController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> mealStateRecords = [];
  List<Map<String, dynamic>> filteredRecords = [];
  int? editingIndex;

  // Controllers for editing
  final TextEditingController _breakfastController = TextEditingController();
  final TextEditingController _lunchController = TextEditingController();
  final TextEditingController _dinnerController = TextEditingController();
  final TextEditingController _disposalTypeController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  DateTime? _disposalFromDate;
  DateTime? _disposalToDate;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _updateSelectedDate();
    _fetchMealStateData();
  }

  void _updateSelectedDate() {
    final now = DateTime.now();
    final currentTime = now.hour * 100 + now.minute;

    if (currentTime >= 2100) {
      // After 21:00, show tomorrow
      selectedDate = DateTime.now().add(const Duration(days: 1));
    } else {
      // Before 21:00, show today
      selectedDate = DateTime.now();
    }
  }

  String _formatDateForFirestore(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatDisposalDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}/${parts[0]}";
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _fetchMealStateData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final dateStr = _formatDateForFirestore(selectedDate);

      final doc = await FirebaseFirestore.instance
          .collection('user_meal_state')
          .doc(dateStr)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        mealStateRecords = [];

        for (String baNo in data.keys) {
          final userData = data[baNo] as Map<String, dynamic>;

          // Format disposal information
          String disposalInfo = 'N/A';
          String disposalFromTo = '';

          if (userData['disposal'] == true &&
              userData['disposal_type'] != null &&
              userData['disposal_type'].toString().isNotEmpty) {
            disposalInfo = userData['disposal_type'].toString();
            if (userData['disposal_from'] != null &&
                userData['disposal_to'] != null) {
              final fromDate =
                  _formatDisposalDate(userData['disposal_from'].toString());
              final toDate =
                  _formatDisposalDate(userData['disposal_to'].toString());
              if (fromDate.isNotEmpty && toDate.isNotEmpty) {
                disposalFromTo = '$fromDate - $toDate';
              }
            }
          }

          // Format remarks
          String remarks = userData['remarks'] ?? '';
          if (remarks.trim().isEmpty) {
            remarks = 'N/A';
          }

          mealStateRecords.add({
            'ba_no': baNo,
            'rank': userData['rank'] ?? '',
            'name': userData['name'] ?? '',
            'breakfast': userData['breakfast'] == true ? 'Yes' : 'No',
            'lunch': userData['lunch'] == true ? 'Yes' : 'No',
            'dinner': userData['dinner'] == true ? 'Yes' : 'No',
            'disposal_type': disposalInfo,
            'disposal_dates': disposalFromTo,
            'remarks': remarks,
            'original_data': userData, // Keep original for editing
          });
        }
      } else {
        mealStateRecords = [];
      }

      _filterRecords(_searchController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching meal state data: $e'),
          backgroundColor: Colors.red,
        ),
      );
      mealStateRecords = [];
      filteredRecords = [];
    }

    setState(() {
      _isLoadingData = false;
    });
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

  void _filterRecords(String query) {
    setState(() {
      filteredRecords = mealStateRecords.where((record) {
        return record.values.any((value) =>
            value.toString().toLowerCase().contains(query.toLowerCase()));
      }).toList();
    });
  }

  void _startEditing(int index, Map<String, dynamic> record) {
    setState(() {
      editingIndex = index;
      _breakfastController.text = record['breakfast'];
      _lunchController.text = record['lunch'];
      _dinnerController.text = record['dinner'];
      _disposalTypeController.text = record['disposal_type'];
      _remarksController.text =
          record['remarks'] == 'N/A' ? '' : record['remarks'];

      // Parse disposal dates
      if (record['disposal_dates'].toString().isNotEmpty &&
          record['disposal_dates'] != '') {
        final dates = record['disposal_dates'].toString().split(' - ');
        if (dates.length == 2) {
          try {
            // Convert from DD/MM/YYYY to DateTime
            final fromParts = dates[0].split('/');
            final toParts = dates[1].split('/');
            if (fromParts.length == 3 && toParts.length == 3) {
              _disposalFromDate = DateTime(int.parse(fromParts[2]),
                  int.parse(fromParts[1]), int.parse(fromParts[0]));
              _disposalToDate = DateTime(int.parse(toParts[2]),
                  int.parse(toParts[1]), int.parse(toParts[0]));
            }
          } catch (e) {
            _disposalFromDate = null;
            _disposalToDate = null;
          }
        }
      } else {
        _disposalFromDate = null;
        _disposalToDate = null;
      }
    });
  }

  Future<void> _saveEditing(int index) async {
    final confirmed = await showDialog<bool>(
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
    );

    if (confirmed == true) {
      setState(() {
        _isLoadingData = true;
      });

      try {
        final record = filteredRecords[index];
        final dateStr = _formatDateForFirestore(selectedDate);
        final baNo = record['ba_no'];

        // Format remarks - auto convert to N/A if empty or variations of n/a
        String finalRemarks = _remarksController.text.trim();
        if (finalRemarks.isEmpty ||
            finalRemarks.toLowerCase() == 'n/a' ||
            finalRemarks.toLowerCase() == 'na') {
          finalRemarks = 'N/A';
        }

        // Format disposal dates
        String disposalFrom = '';
        String disposalTo = '';
        if (_disposalTypeController.text != 'N/A' &&
            _disposalFromDate != null &&
            _disposalToDate != null) {
          disposalFrom = _formatDateForFirestore(_disposalFromDate!);
          disposalTo = _formatDateForFirestore(_disposalToDate!);
        }

        // Update Firebase
        await FirebaseFirestore.instance
            .collection('user_meal_state')
            .doc(dateStr)
            .update({
          '$baNo.breakfast': _breakfastController.text == 'Yes',
          '$baNo.lunch': _lunchController.text == 'Yes',
          '$baNo.dinner': _dinnerController.text == 'Yes',
          '$baNo.disposal': _disposalTypeController.text != 'N/A',
          '$baNo.disposal_type': _disposalTypeController.text == 'N/A'
              ? ''
              : _disposalTypeController.text,
          '$baNo.disposal_from': disposalFrom,
          '$baNo.disposal_to': disposalTo,
          '$baNo.remarks': finalRemarks == 'N/A' ? '' : finalRemarks,
          '$baNo.timestamp': FieldValue.serverTimestamp(),
        });

        // Refresh data
        await _fetchMealStateData();

        setState(() {
          editingIndex = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _isLoadingData = false;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      editingIndex = null;
      _disposalFromDate = null;
      _disposalToDate = null;
    });
  }

  Future<void> _deleteRecord(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoadingData = true;
      });

      try {
        final record = filteredRecords[index];
        final dateStr = _formatDateForFirestore(selectedDate);
        final baNo = record['ba_no'];

        // Delete from Firebase
        await FirebaseFirestore.instance
            .collection('user_meal_state')
            .doc(dateStr)
            .update({
          baNo: FieldValue.delete(),
        });

        // Refresh data
        await _fetchMealStateData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _isLoadingData = false;
      });
    }
  }

  // Counting functions
  int countMealState(String meal, String state) {
    return filteredRecords
        .where((record) => record[meal.toLowerCase()] == state)
        .length;
  }

  int countDisposals(String type) {
    return filteredRecords
        .where((record) =>
            record['disposal_type'].toString().toLowerCase() ==
            type.toLowerCase())
        .length;
  }

  int countRemarksPresent() {
    return filteredRecords
        .where((record) =>
            record['remarks'].toString() != 'N/A' &&
            record['remarks'].toString().trim().isNotEmpty)
        .length;
  }

  Future<void> _pickDisposalDate({required bool isFrom}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_disposalFromDate ?? selectedDate)
          : (_disposalToDate ?? selectedDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _disposalFromDate = picked;
          // If to date is before from date, clear it
          if (_disposalToDate != null && _disposalToDate!.isBefore(picked)) {
            _disposalToDate = null;
          }
        } else {
          _disposalToDate = picked;
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      await _fetchMealStateData();
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
            // Top row with search, date selector and see records button
            Row(
              children: [
                SizedBox(
                  width: 180,
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
                // Date selector
                OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MealStateRecordScreen(),
                      ),
                    );
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

            // Loading indicator or data table
            Expanded(
              child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
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
                                'Rk',
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
                                'Breakfast',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Lunch',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Dinner',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Disposals',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Remarks',
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
                          rows: filteredRecords.isEmpty
                              ? [
                                  DataRow(
                                    cells: [
                                      const DataCell(Text('No data')),
                                      const DataCell(Text('-')),
                                      const DataCell(Text('-')),
                                      const DataCell(Text('-')),
                                      const DataCell(Text('-')),
                                      const DataCell(Text('-')),
                                      const DataCell(Text('-')),
                                      const DataCell(Text('-')),
                                      const DataCell(Text('-')),
                                    ],
                                  ),
                                ]
                              : List.generate(filteredRecords.length, (index) {
                                  final record = filteredRecords[index];
                                  final isEditing = editingIndex == index;

                                  return DataRow(
                                    cells: [
                                      // BA No - not editable
                                      DataCell(Text(record['ba_no'] ?? '')),
                                      // Rank - not editable
                                      DataCell(Text(record['rank'] ?? '')),
                                      // Name - not editable
                                      DataCell(
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            record['name'] ?? '',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      // Breakfast - editable dropdown
                                      DataCell(
                                        isEditing
                                            ? DropdownButton<String>(
                                                value:
                                                    _breakfastController.text,
                                                items: const [
                                                  DropdownMenuItem(
                                                      value: 'Yes',
                                                      child: Text('Yes')),
                                                  DropdownMenuItem(
                                                      value: 'No',
                                                      child: Text('No')),
                                                ],
                                                onChanged: (value) {
                                                  setState(() {
                                                    _breakfastController.text =
                                                        value!;
                                                  });
                                                },
                                              )
                                            : Text(record['breakfast'] ?? ''),
                                      ),
                                      // Lunch - editable dropdown
                                      DataCell(
                                        isEditing
                                            ? DropdownButton<String>(
                                                value: _lunchController.text,
                                                items: const [
                                                  DropdownMenuItem(
                                                      value: 'Yes',
                                                      child: Text('Yes')),
                                                  DropdownMenuItem(
                                                      value: 'No',
                                                      child: Text('No')),
                                                ],
                                                onChanged: (value) {
                                                  setState(() {
                                                    _lunchController.text =
                                                        value!;
                                                  });
                                                },
                                              )
                                            : Text(record['lunch'] ?? ''),
                                      ),
                                      // Dinner - editable dropdown
                                      DataCell(
                                        isEditing
                                            ? DropdownButton<String>(
                                                value: _dinnerController.text,
                                                items: const [
                                                  DropdownMenuItem(
                                                      value: 'Yes',
                                                      child: Text('Yes')),
                                                  DropdownMenuItem(
                                                      value: 'No',
                                                      child: Text('No')),
                                                ],
                                                onChanged: (value) {
                                                  setState(() {
                                                    _dinnerController.text =
                                                        value!;
                                                  });
                                                },
                                              )
                                            : Text(record['dinner'] ?? ''),
                                      ),
                                      // Disposals with sub-row for dates
                                      DataCell(
                                        isEditing
                                            ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  DropdownButton<String>(
                                                    value:
                                                        _disposalTypeController
                                                            .text,
                                                    items: const [
                                                      DropdownMenuItem(
                                                          value: 'N/A',
                                                          child: Text('N/A')),
                                                      DropdownMenuItem(
                                                          value: 'SIQ',
                                                          child: Text('SIQ')),
                                                      DropdownMenuItem(
                                                          value: 'Leave',
                                                          child: Text('Leave')),
                                                    ],
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _disposalTypeController
                                                            .text = value!;
                                                        if (value == 'N/A') {
                                                          _disposalFromDate =
                                                              null;
                                                          _disposalToDate =
                                                              null;
                                                        }
                                                      });
                                                    },
                                                  ),
                                                  if (_disposalTypeController
                                                          .text !=
                                                      'N/A') ...[
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        InkWell(
                                                          onTap: () =>
                                                              _pickDisposalDate(
                                                                  isFrom: true),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(4),
                                                            decoration:
                                                                BoxDecoration(
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .grey),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4),
                                                            ),
                                                            child: Text(
                                                              _disposalFromDate !=
                                                                      null
                                                                  ? '${_disposalFromDate!.day}/${_disposalFromDate!.month}'
                                                                  : 'From',
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          10),
                                                            ),
                                                          ),
                                                        ),
                                                        const Text(' - ',
                                                            style: TextStyle(
                                                                fontSize: 10)),
                                                        InkWell(
                                                          onTap: () =>
                                                              _pickDisposalDate(
                                                                  isFrom:
                                                                      false),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(4),
                                                            decoration:
                                                                BoxDecoration(
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .grey),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4),
                                                            ),
                                                            child: Text(
                                                              _disposalToDate !=
                                                                      null
                                                                  ? '${_disposalToDate!.day}/${_disposalToDate!.month}'
                                                                  : 'To',
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          10),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              )
                                            : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                      record['disposal_type'] ??
                                                          'N/A'),
                                                  if (record['disposal_dates'] !=
                                                          null &&
                                                      record['disposal_dates']
                                                          .toString()
                                                          .isNotEmpty)
                                                    Text(
                                                      record['disposal_dates'],
                                                      style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.grey),
                                                    ),
                                                ],
                                              ),
                                      ),
                                      // Remarks - editable text field
                                      DataCell(
                                        isEditing
                                            ? SizedBox(
                                                width: 100,
                                                child: TextField(
                                                  controller:
                                                      _remarksController,
                                                  decoration:
                                                      const InputDecoration(
                                                    hintText: 'Remarks',
                                                    border:
                                                        OutlineInputBorder(),
                                                    contentPadding:
                                                        EdgeInsets.all(8),
                                                  ),
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                  maxLines: 2,
                                                ),
                                              )
                                            : SizedBox(
                                                width: 100,
                                                child: Text(
                                                  record['remarks'] ?? 'N/A',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                ),
                                              ),
                                      ),
                                      // Action buttons
                                      DataCell(
                                        isEditing
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.check,
                                                        color: Colors.green),
                                                    onPressed: () =>
                                                        _saveEditing(index),
                                                    iconSize: 20,
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.close,
                                                        color: Colors.red),
                                                    onPressed: _cancelEditing,
                                                    iconSize: 20,
                                                  ),
                                                ],
                                              )
                                            : Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit,
                                                        color: Colors.blue),
                                                    onPressed: () =>
                                                        _startEditing(
                                                            index, record),
                                                    iconSize: 20,
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red),
                                                    onPressed: () =>
                                                        _deleteRecord(index),
                                                    iconSize: 20,
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
            ),

            const SizedBox(height: 16),

            // Summary container
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
                    'Breakfast: ${countMealState('breakfast', 'Yes')}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lunch: ${countMealState('lunch', 'Yes')}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dinner: ${countMealState('dinner', 'Yes')}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SIQ: ${countDisposals('SIQ')}, Leave: ${countDisposals('Leave')}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Remarks: ${countRemarksPresent()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
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

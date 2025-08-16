import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/language_provider.dart';
import '../../services/auto_loop_service.dart';
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
import 'auto_loop_users_screen.dart';
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
  String _currentUserName =
      "Admin User"; // This is just a fallback, will be updated from Firebase
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
          content: Text(
              AppLocalizations.of(context)!.errorFetchingMealStateData +
                  ': $e'),
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
          _currentUserName =
              userData['name'] ?? AppLocalizations.of(context)!.adminUser;
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
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.logoutFailed + ': $e')),
        );
      }
    }
  }

  /// Manual Auto Loop Batch Processing
  /// This method checks existing meal states first and only processes users who don't have meal states
  Future<void> _runAutoLoopBatch() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Processing Auto Loop Batch...'),
            ],
          ),
        ),
      );

      // Run the manual auto loop batch processing
      final result = await AutoLoopService.runManualAutoLoopBatch();

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      // Show detailed results
      if (result['success']) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Auto Loop Batch Completed'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📅 Target Date: ${result['target_date']}'),
                  const SizedBox(height: 8),
                  Text('📊 Summary:'),
                  Text('  • Processed: ${result['processed']} users'),
                  Text('  • Skipped: ${result['skipped']} users'),
                  Text(
                      '  • Total Auto Loop Users: ${result['total_auto_loop_users']}'),
                  if (result['processed_users']?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    const Text('✅ Processed Users:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...result['processed_users']
                        .map<Widget>((user) => Text('  • $user')),
                  ],
                  if (result['skipped_users']?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    const Text('⏭️ Skipped Users (already have meal states):',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...result['skipped_users']
                        .map<Widget>((user) => Text('  • $user')),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Refresh meal state data to show the newly generated entries
                  _fetchMealStateData();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Auto Loop Batch Failed: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error running auto loop batch: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: Text(AppLocalizations.of(context)!.confirmSave),
        content: Text(AppLocalizations.of(context)!.confirmSaveMealState),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: Text(AppLocalizations.of(context)!.save),
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
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.recordUpdatedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.errorUpdatingRecord + ': $e'),
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
        title: Text(AppLocalizations.of(context)!.confirmDelete),
        content: Text(AppLocalizations.of(context)!.deleteRecordConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
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
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.recordDeletedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.errorDeletingRecord + ': $e'),
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

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
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
                                '${AppLocalizations.of(context)!.baNumber}: ${_currentUserData!['ba_no'] ?? ''}',
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
                        title: AppLocalizations.of(context)!.home,
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
                        title: AppLocalizations.of(context)!.users,
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
                        title: AppLocalizations.of(context)!.pendingIds,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminPendingIdsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSidebarTile(
                        icon: Icons.history,
                        title: AppLocalizations.of(context)!.shoppingHistory,
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
                        title: AppLocalizations.of(context)!.voucherList,
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
                        title: AppLocalizations.of(context)!.inventory,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminInventoryScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSidebarTile(
                        icon: Icons.food_bank,
                        title: AppLocalizations.of(context)!.messing,
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
                        title: AppLocalizations.of(context)!.monthlyMenu,
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
                        title: AppLocalizations.of(context)!.mealState,
                        selected: true,
                        onTap: () => Navigator.pop(context),
                      ),
                      _buildSidebarTile(
                        icon: Icons.thumb_up,
                        title: AppLocalizations.of(context)!.menuVote,
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
                        title: AppLocalizations.of(context)!.bills,
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
                        title: AppLocalizations.of(context)!.payments,
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
                        title: AppLocalizations.of(context)!.diningMemberState,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DiningMemberStatePage(),
                            ),
                          );
                        },
                      ),
                      _buildSidebarTile(
                        icon: Icons.manage_accounts,
                        title: AppLocalizations.of(context)!.staffState,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminStaffStateScreen(),
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
                      title: AppLocalizations.of(context)!.logout,
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
            title: Text(
              AppLocalizations.of(context)!.mealState,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            actions: [
              // Manual Auto Loop Batch Button
              IconButton(
                icon: const Icon(Icons.autorenew, color: Colors.white),
                tooltip: 'Run Auto Loop Batch',
                onPressed: _runAutoLoopBatch,
              ),
              PopupMenuButton<String>(
                icon: Container(
                  width: 32,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.white70, width: 0.5),
                  ),
                  child: languageProvider.isEnglish
                      ? CustomPaint(
                          painter: _EnglandFlagPainter(),
                          size: const Size(32, 24),
                        )
                      : CustomPaint(
                          painter: _BangladeshFlagPainter(),
                          size: const Size(32, 24),
                        ),
                ),
                onSelected: (String value) {
                  if (value == 'english') {
                    languageProvider.changeLanguage(const Locale('en'));
                  } else if (value == 'bangla') {
                    languageProvider.changeLanguage(const Locale('bn'));
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'english',
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                                color: Colors.grey.shade300, width: 0.5),
                          ),
                          child: CustomPaint(
                            painter: _EnglandFlagPainter(),
                            size: const Size(24, 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(AppLocalizations.of(context)!.english),
                        if (languageProvider.isEnglish) ...[
                          const Spacer(),
                          Icon(Icons.check,
                              color: Colors.green.shade600, size: 18),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'bangla',
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                                color: Colors.grey.shade300, width: 0.5),
                          ),
                          child: CustomPaint(
                            painter: _BangladeshFlagPainter(),
                            size: const Size(24, 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(AppLocalizations.of(context)!.bangla),
                        if (languageProvider.isBangla) ...[
                          const Spacer(),
                          Icon(Icons.check,
                              color: Colors.green.shade600, size: 18),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with search, date selector and buttons
                Column(
                  children: [
                    // First row: Search and Date
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _searchController,
                            onChanged: _filterRecords,
                            decoration: InputDecoration(
                              hintText:
                                  AppLocalizations.of(context)!.searchUsers,
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
                        Expanded(
                          flex: 1,
                          child: OutlinedButton.icon(
                            onPressed: _selectDate,
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Second row: Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MealStateRecordScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A4D8F),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.seeRecords,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Auto Loop Users Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AutoLoopUsersScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Auto Loop Users',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                              dataRowMinHeight: 60,
                              dataRowMaxHeight: editingIndex != null ? 120 : 60,
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFF1A4D8F),
                              ),
                              columns: [
                                DataColumn(
                                  label: Text(
                                    AppLocalizations.of(context)!.baNumber,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    AppLocalizations.of(context)!.rank,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    AppLocalizations.of(context)!.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    AppLocalizations.of(context)!.breakfast,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    AppLocalizations.of(context)!.lunch,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    AppLocalizations.of(context)!.dinner,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    AppLocalizations.of(context)!.disposals,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    AppLocalizations.of(context)!.remarks,
                                    style: const TextStyle(
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
                                          DataCell(Text(
                                              AppLocalizations.of(context)!
                                                  .noData)),
                                          DataCell(Text(
                                              AppLocalizations.of(context)!
                                                  .dash)),
                                          DataCell(Text(
                                              AppLocalizations.of(context)!
                                                  .dash)),
                                          DataCell(Text(
                                              AppLocalizations.of(context)!
                                                  .dash)),
                                          DataCell(Text(
                                              AppLocalizations.of(context)!
                                                  .dash)),
                                          DataCell(Text(
                                              AppLocalizations.of(context)!
                                                  .dash)),
                                          DataCell(Text(
                                              AppLocalizations.of(context)!
                                                  .dash)),
                                          DataCell(Text(
                                              AppLocalizations.of(context)!
                                                  .dash)),
                                          DataCell(Text(
                                              AppLocalizations.of(context)!
                                                  .dash)),
                                        ],
                                      ),
                                    ]
                                  : List.generate(filteredRecords.length,
                                      (index) {
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
                                                    value: _breakfastController
                                                        .text,
                                                    items: [
                                                      DropdownMenuItem(
                                                          value: 'Yes',
                                                          child: Text(
                                                              AppLocalizations.of(
                                                                      context)!
                                                                  .yes)),
                                                      DropdownMenuItem(
                                                          value: 'No',
                                                          child: Text(
                                                              AppLocalizations.of(
                                                                      context)!
                                                                  .no)),
                                                    ],
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _breakfastController
                                                            .text = value!;
                                                      });
                                                    },
                                                  )
                                                : Text(
                                                    record['breakfast'] ?? ''),
                                          ),
                                          // Lunch - editable dropdown
                                          DataCell(
                                            isEditing
                                                ? DropdownButton<String>(
                                                    value:
                                                        _lunchController.text,
                                                    items: [
                                                      DropdownMenuItem(
                                                          value: 'Yes',
                                                          child: Text(
                                                              AppLocalizations.of(
                                                                      context)!
                                                                  .yes)),
                                                      DropdownMenuItem(
                                                          value: 'No',
                                                          child: Text(
                                                              AppLocalizations.of(
                                                                      context)!
                                                                  .no)),
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
                                                    value:
                                                        _dinnerController.text,
                                                    items: [
                                                      DropdownMenuItem(
                                                          value: 'Yes',
                                                          child: Text(
                                                              AppLocalizations.of(
                                                                      context)!
                                                                  .yes)),
                                                      DropdownMenuItem(
                                                          value: 'No',
                                                          child: Text(
                                                              AppLocalizations.of(
                                                                      context)!
                                                                  .no)),
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
                                                ? Container(
                                                    width: 160,
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 4),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        // Disposal Type Dropdown
                                                        SizedBox(
                                                          width: 150,
                                                          height: 35,
                                                          child:
                                                              DropdownButtonFormField<
                                                                  String>(
                                                            value:
                                                                _disposalTypeController
                                                                    .text,
                                                            isExpanded: true,
                                                            decoration:
                                                                const InputDecoration(
                                                              contentPadding:
                                                                  EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4),
                                                              border:
                                                                  OutlineInputBorder(),
                                                              isDense: true,
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12),
                                                            items: const [
                                                              DropdownMenuItem(
                                                                  value: 'N/A',
                                                                  child: Text(
                                                                      'N/A')),
                                                              DropdownMenuItem(
                                                                  value: 'SIQ',
                                                                  child: Text(
                                                                      'SIQ')),
                                                              DropdownMenuItem(
                                                                  value:
                                                                      'Leave',
                                                                  child: Text(
                                                                      'Leave')),
                                                            ],
                                                            onChanged: (value) {
                                                              setState(() {
                                                                _disposalTypeController
                                                                        .text =
                                                                    value!;
                                                                if (value ==
                                                                    'N/A') {
                                                                  _disposalFromDate =
                                                                      null;
                                                                  _disposalToDate =
                                                                      null;
                                                                }
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                        // Date Selection (only if not N/A)
                                                        if (_disposalTypeController
                                                                .text !=
                                                            'N/A') ...[
                                                          const SizedBox(
                                                              height: 6),
                                                          // From Date
                                                          InkWell(
                                                            onTap: () =>
                                                                _pickDisposalDate(
                                                                    isFrom:
                                                                        true),
                                                            child: Container(
                                                              width: 150,
                                                              height: 28,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4),
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
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Flexible(
                                                                    child: Text(
                                                                      _disposalFromDate !=
                                                                              null
                                                                          ? '${_disposalFromDate!.day}/${_disposalFromDate!.month}/${_disposalFromDate!.year}'
                                                                          : 'From Date',
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              10),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                  const Icon(
                                                                    Icons
                                                                        .calendar_today,
                                                                    size: 12,
                                                                    color: Colors
                                                                        .grey,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 4),
                                                          // To Date
                                                          InkWell(
                                                            onTap: () =>
                                                                _pickDisposalDate(
                                                                    isFrom:
                                                                        false),
                                                            child: Container(
                                                              width: 150,
                                                              height: 28,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4),
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
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Flexible(
                                                                    child: Text(
                                                                      _disposalToDate !=
                                                                              null
                                                                          ? '${_disposalToDate!.day}/${_disposalToDate!.month}/${_disposalToDate!.year}'
                                                                          : 'To Date',
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              10),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                  const Icon(
                                                                    Icons
                                                                        .calendar_today,
                                                                    size: 12,
                                                                    color: Colors
                                                                        .grey,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  )
                                                : Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(record[
                                                              'disposal_type'] ??
                                                          'N/A'),
                                                      if (record['disposal_dates'] !=
                                                              null &&
                                                          record['disposal_dates']
                                                              .toString()
                                                              .isNotEmpty)
                                                        Text(
                                                          record[
                                                              'disposal_dates'],
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors
                                                                      .grey),
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
                                                          InputDecoration(
                                                        hintText:
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .remarks,
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
                                                      record['remarks'] ??
                                                          'N/A',
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
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.check,
                                                            color:
                                                                Colors.green),
                                                        onPressed: () =>
                                                            _saveEditing(index),
                                                        iconSize: 20,
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.close,
                                                            color: Colors.red),
                                                        onPressed:
                                                            _cancelEditing,
                                                        iconSize: 20,
                                                      ),
                                                    ],
                                                  )
                                                : Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.edit,
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
                                                            _deleteRecord(
                                                                index),
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
                        '${AppLocalizations.of(context)!.breakfast}: ${countMealState('breakfast', 'Yes')}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${AppLocalizations.of(context)!.lunch}: ${countMealState('lunch', 'Yes')}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${AppLocalizations.of(context)!.dinner}: ${countMealState('dinner', 'Yes')}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${AppLocalizations.of(context)!.siq}: ${countDisposals('SIQ')}, ${AppLocalizations.of(context)!.leave}: ${countDisposals('Leave')}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${AppLocalizations.of(context)!.remarks}: ${countRemarksPresent()}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EnglandFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Blue background
    paint.color = const Color(0xFF012169);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // White diagonal stripes
    paint.color = Colors.white;
    paint.strokeWidth = size.height * 0.15;

    // Draw diagonal white stripes
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    // White cross
    paint.strokeWidth = size.height * 0.25;
    // Vertical line
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    // Horizontal line
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);

    // Red cross
    paint.color = const Color(0xFFC8102E);
    paint.strokeWidth = size.height * 0.15;
    // Vertical line
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    // Horizontal line
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);

    // Red diagonal stripes
    paint.strokeWidth = size.height * 0.08;
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _BangladeshFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Green background
    paint.color = const Color(0xFF006A4E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Red circle
    paint.color = const Color(0xFFF42A41);
    final center =
        Offset(size.width * 0.45, size.height * 0.5); // Slightly left of center
    final radius = size.height * 0.3;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

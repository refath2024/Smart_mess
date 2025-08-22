import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/language_provider.dart';
import 'admin_home_screen.dart';
import 'admin_users_screen.dart';
import 'admin_pending_ids_screen.dart';
import 'admin_shopping_history.dart';
import 'admin_voucher_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_messing_screen.dart';
import 'admin_staff_state_screen.dart';
import 'admin_payment_history.dart';
import 'admin_meal_state_screen.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_menu_vote_screen.dart';
import 'admin_bill_screen.dart';
import 'add_dining_member.dart';
import 'admin_login_screen.dart';
import '../../services/admin_auth_service.dart';
import 'admin_all_user_login_sessions_screen.dart';
import 'admin_all_user_activity_log_screen.dart';

class DiningMemberStatePage extends StatefulWidget {
  const DiningMemberStatePage({super.key});

  @override
  State<DiningMemberStatePage> createState() => _DiningMemberStatePageState();
}

class _DiningMemberStatePageState extends State<DiningMemberStatePage> {
  final AdminAuthService _adminAuthService = AdminAuthService();

  bool _isLoading = true;
  String _currentUserName = "Admin User";
  Map<String, dynamic>? _currentUserData;

  List<Map<String, dynamic>> members = [];
  String searchTerm = '';
  String statusFilter = 'all'; // Add status filter
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> filtered = [];

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

        // After authentication is confirmed, fetch users from Firestore
        await _fetchUsersFromFirestore();
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

  Future<void> _fetchUsersFromFirestore() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user_requests')
          .where('approved', isEqualTo: true)
          .where('rejected', isEqualTo: false)
          .get();

      final List<Map<String, dynamic>> fetchedUsers = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        fetchedUsers.add({
          'id': doc.id,
          'no': data['ba_no'] ?? '',
          'rank': data['rank'] ?? '',
          'name': data['name'] ?? '',
          'unit': data['unit'] ?? '',
          'mobile': data['mobile'] ?? '',
          'email': data['email'] ?? '',
          'status': data['status'] ?? 'active', // Get current status
          'approved_by': data['approved_by'] ?? 'Admin', // Get who approved
          'role': 'Dining Member',
          'isEditing': false,
          'original': {},
        });
      }

      setState(() {
        members = fetchedUsers;
        _applyFilters(); // Use the new filter method
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${AppLocalizations.of(context)!.failedToFetchUsers}: $e')),
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
                  Text('${AppLocalizations.of(context)!.logoutFailed}: $e')),
        );
      }
    }
  }

  void _startEdit(Map<String, dynamic> row) {
    setState(() {
      row['original'] = Map<String, dynamic>.from(row);
      row['isEditing'] = true;
    });
  }

  void _cancelEdit(Map<String, dynamic> row) {
    setState(() {
      row['no'] = row['original']['no'];
      row['rank'] = row['original']['rank'];
      row['name'] = row['original']['name'];
      row['unit'] = row['original']['unit'];
      row['mobile'] = row['original']['mobile'];
      row['email'] = row['original']['email'];
      row['status'] = row['original']['status'];
      row['role'] = row['original']['role'];
      row['isEditing'] = false;
    });
  }

  Future<void> _deleteStaff(Map<String, dynamic> row) async {
    // Debug: Print ba_no before attempting to delete from user_auto_loop
    if (row['ba_no'] != null) {
      try {
        print(
            'Attempting to delete user_auto_loop document with ba_no: \'${row['ba_no']}\'');
        await FirebaseFirestore.instance
            .collection('user_auto_loop')
            .doc(row['ba_no'])
            .delete();
        print('Successfully called delete on user_auto_loop/${row['ba_no']}');
      } catch (e) {
        print('Error deleting user_auto_loop/${row['ba_no']}: $e');
      }
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmDelete),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${AppLocalizations.of(context)!.areYouSureYouWantToDelete} "${row['name']}"?'),
              const SizedBox(height: 12),
              Text(
                'Warning: This will delete any auto loop and future data for this user. Past records will remain for reference.',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // Save user details to 'deleted_user_details' before deletion
        if (row['ba_no'] != null) {
          await FirebaseFirestore.instance
              .collection('deleted_user_details')
              .doc(row['ba_no'])
              .set({
            ...row,
            'deleted_at': FieldValue.serverTimestamp(),
          });
        }

        // Delete from user_requests
        if (row['id'] != null) {
          await FirebaseFirestore.instance
              .collection('user_requests')
              .doc(row['id'])
              .delete();
        }

        // Delete from user_auto_loop where ba_no matches (document ID is ba_no)
        if (row['ba_no'] != null) {
          try {
            print(
                'Attempting to delete user_auto_loop document with ba_no: \'${row['ba_no']}\'');
            await FirebaseFirestore.instance
                .collection('user_auto_loop')
                .doc(row['ba_no'])
                .delete();
            print(
                'Successfully called delete on user_auto_loop/${row['ba_no']}');
          } catch (e) {
            print('Error deleting user_auto_loop/${row['ba_no']}: $e');
          }

          // Delete from ba_no_wise where ba_no matches (assuming doc id is ba_no)
          final baNoWiseDoc = FirebaseFirestore.instance
              .collection('ba_no_wise')
              .doc(row['ba_no']);
          final baNoWiseSnapshot = await baNoWiseDoc.get();
          if (baNoWiseSnapshot.exists) {
            await baNoWiseDoc.delete();
          }
        }

        setState(() {
          members.remove(row);
          _applyFilters();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.memberDeletedSuccessfully)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '${AppLocalizations.of(context)!.failedToDeleteMember}: $e')),
          );
        }
      }
    }
  }

  Future<void> _saveEdit(Map<String, dynamic> row) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmSave),
          content: Text(AppLocalizations.of(context)!.saveChangesQuestion),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // Track changes for activity log
        final original = row['original'] ?? {};
        final List<String> changes = [];
        for (final field in [
          'ba_no',
          'rank',
          'name',
          'unit',
          'mobile',
          'email',
          'status',
        ]) {
          final oldVal = original[field];
          final newVal = row[field == 'ba_no' ? 'no' : field];
          if (oldVal != null && oldVal.toString() != newVal.toString()) {
            changes.add('$field: "$oldVal" → "$newVal"');
          }
        }

        // Update in Firestore
        if (row['id'] != null) {
          await FirebaseFirestore.instance
              .collection('user_requests')
              .doc(row['id'])
              .update({
            'ba_no': row['no'],
            'rank': row['rank'],
            'name': row['name'],
            'unit': row['unit'],
            'mobile': row['mobile'],
            'email': row['email'],
            'status': row['status'],
          });
        }

        setState(() {
          row['isEditing'] = false;
        });

        // Log activity (admin as actor, like admin_shopping_history)
        final adminName = _currentUserData?['name'] ?? 'Admin';
        final baNo = _currentUserData?['ba_no'] ?? '';
        if (baNo.isNotEmpty && changes.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('staff_activity_log')
              .doc(baNo)
              .collection('logs')
              .add({
            'timestamp': FieldValue.serverTimestamp(),
            'actionType': 'Update Dining Member',
            'message':
                '$adminName updated dining member "${row['name']}" (BA: ${row['no']}). Changes: ${changes.join(', ')}',
            'name': adminName,
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.memberUpdatedSuccessfully)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '${AppLocalizations.of(context)!.failedToSaveChanges}: $e')),
          );
        }
      }
    }
  }

  void _search(String query) {
    setState(() {
      searchTerm = query.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      filtered = members.where((m) {
        // Search filter
        final matchesSearch = searchTerm.isEmpty ||
            m.values.any(
                (value) => value.toString().toLowerCase().contains(searchTerm));

        // Status filter
        final matchesStatus =
            statusFilter == 'all' || m['status'] == statusFilter;

        return matchesSearch && matchesStatus;
      }).toList();
    });
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
      leading:
          Icon(icon, color: color ?? (selected ? Colors.blue : Colors.black)),
      title: Text(title, style: TextStyle(color: color ?? Colors.black)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        // Show loading screen while checking authentication
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
                          title: AppLocalizations.of(context)!.home,
                          onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminHomeScreen()))),
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
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminMealStateScreen(),
                            ),
                          );
                        },
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
                          title:
                              AppLocalizations.of(context)!.diningMemberState,
                          selected: true,
                          onTap: () => Navigator.pop(context)),
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
              AppLocalizations.of(context)!.diningMemberState,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.language, color: Colors.white),
                  onSelected: (String value) {
                    if (value == 'english') {
                      Provider.of<LanguageProvider>(context, listen: false)
                          .changeLanguage(const Locale('en'));
                    } else if (value == 'bangla') {
                      Provider.of<LanguageProvider>(context, listen: false)
                          .changeLanguage(const Locale('bn'));
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'english',
                      child: Row(
                        children: [
                          Text('🇺🇸'),
                          const SizedBox(width: 8),
                          Text('English'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'bangla',
                      child: Row(
                        children: [
                          Text('🇧🇩'),
                          const SizedBox(width: 8),
                          Text('বাংলা'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // First row with search and filter
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Check if we have enough space for side-by-side layout
                    bool isWideScreen = constraints.maxWidth > 600;

                    if (isWideScreen) {
                      return Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _searchController,
                              onChanged: _search,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!
                                    .searchAllTextColumns,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.search),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: statusFilter,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!
                                    .filterByStatus,
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                              ),
                              style: const TextStyle(fontSize: 14),
                              items: [
                                DropdownMenuItem(
                                  value: 'all',
                                  child: Text(
                                      AppLocalizations.of(context)!.allStatus,
                                      style: const TextStyle(fontSize: 14)),
                                ),
                                DropdownMenuItem(
                                  value: 'active',
                                  child: Text(
                                      AppLocalizations.of(context)!.activeOnly,
                                      style: const TextStyle(fontSize: 14)),
                                ),
                                DropdownMenuItem(
                                  value: 'inactive',
                                  child: Text(
                                      AppLocalizations.of(context)!
                                          .inactiveOnly,
                                      style: const TextStyle(fontSize: 14)),
                                ),
                              ],
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    statusFilter = newValue;
                                    _applyFilters();
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Stack vertically on smaller screens, but put search and All Login Sessions button in a Row
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AdminAllUserLoginSessionsScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.security),
                                label: const Text('All Login Sessions'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF0052CC),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  textStyle: const TextStyle(fontSize: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AdminAllUserActivityLogScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.event_note),
                                label: const Text('All User Activity Logs'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF0052CC),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  textStyle: const TextStyle(fontSize: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: SizedBox(
                                    height: 48,
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: _search,
                                      decoration: InputDecoration(
                                        labelText: AppLocalizations.of(context)!
                                            .searchAllTextColumns,
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.search),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 48,
                                  child: DropdownButtonFormField<String>(
                                    value: statusFilter,
                                    decoration: InputDecoration(
                                      labelText: AppLocalizations.of(context)!
                                          .filterByStatus,
                                      border: const OutlineInputBorder(),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: 'all',
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .allStatus),
                                      ),
                                      DropdownMenuItem(
                                        value: 'active',
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .activeOnly),
                                      ),
                                      DropdownMenuItem(
                                        value: 'inactive',
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .inactiveOnly),
                                      ),
                                    ],
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          statusFilter = newValue;
                                          _applyFilters();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                // Second row with add button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AddDiningMemberForm()));

                        // Refresh data when returning from add form
                        if (result == true || result == null) {
                          await _fetchUsersFromFirestore();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0052CC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(AppLocalizations.of(context)!.addDiningMember,
                          style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width - 32,
                          ),
                          child: DataTable(
                            columnSpacing: 12, // Reduced column spacing
                            headingRowColor: WidgetStateProperty.all(
                                const Color(0xFF1A4D8F)),
                            columns: [
                              DataColumn(
                                  label: Text(
                                      AppLocalizations.of(context)!.baNumber,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              DataColumn(
                                  label: Text(
                                      AppLocalizations.of(context)!.rank,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              DataColumn(
                                  label: Text(
                                      AppLocalizations.of(context)!.name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              DataColumn(
                                  label: Text(
                                      AppLocalizations.of(context)!.unit,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              DataColumn(
                                  label: Text(
                                      AppLocalizations.of(context)!.mobile,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              DataColumn(
                                  label: Text(
                                      AppLocalizations.of(context)!.email,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              DataColumn(
                                  label: Text(
                                      AppLocalizations.of(context)!.role,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              DataColumn(
                                  label: Text(
                                      AppLocalizations.of(context)!.status,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              DataColumn(
                                  label: Text(
                                      AppLocalizations.of(context)!.approvedBy,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              DataColumn(
                                  label: Text(
                                      AppLocalizations.of(context)!.action,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                            ],
                            rows: filtered.map((row) {
                              final bool isEditing = row['isEditing'] ?? false;
                              return DataRow(cells: [
                                DataCell(
                                  SizedBox(
                                    width: 80,
                                    child: isEditing
                                        ? TextField(
                                            controller: TextEditingController(
                                                text: row['no']),
                                            onChanged: (value) =>
                                                row['no'] = value,
                                            style:
                                                const TextStyle(fontSize: 12),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.all(4),
                                            ),
                                          )
                                        : Text(row['no'] ?? '',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 100,
                                    child: isEditing
                                        ? TextField(
                                            controller: TextEditingController(
                                                text: row['rank']),
                                            onChanged: (value) =>
                                                row['rank'] = value,
                                            style:
                                                const TextStyle(fontSize: 12),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.all(4),
                                            ),
                                          )
                                        : Text(row['rank'] ?? '',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 120,
                                    child: isEditing
                                        ? TextField(
                                            controller: TextEditingController(
                                                text: row['name']),
                                            onChanged: (value) =>
                                                row['name'] = value,
                                            style:
                                                const TextStyle(fontSize: 12),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.all(4),
                                            ),
                                          )
                                        : Text(row['name'] ?? '',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 100,
                                    child: isEditing
                                        ? TextField(
                                            controller: TextEditingController(
                                                text: row['unit']),
                                            onChanged: (value) =>
                                                row['unit'] = value,
                                            style:
                                                const TextStyle(fontSize: 12),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.all(4),
                                            ),
                                          )
                                        : Text(row['unit'] ?? '',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 100,
                                    child: isEditing
                                        ? TextField(
                                            controller: TextEditingController(
                                                text: row['mobile']),
                                            onChanged: (value) =>
                                                row['mobile'] = value,
                                            style:
                                                const TextStyle(fontSize: 12),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.all(4),
                                            ),
                                          )
                                        : Text(row['mobile'] ?? '',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 150,
                                    child: isEditing
                                        ? TextField(
                                            controller: TextEditingController(
                                                text: row['email']),
                                            onChanged: (value) =>
                                                row['email'] = value,
                                            style:
                                                const TextStyle(fontSize: 12),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.all(4),
                                            ),
                                          )
                                        : Text(row['email'] ?? '',
                                            style:
                                                const TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                        AppLocalizations.of(context)!
                                            .diningMember,
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 90,
                                    child: isEditing
                                        ? DropdownButton<String>(
                                            value: row['status'],
                                            isExpanded: true,
                                            items: [
                                              DropdownMenuItem(
                                                value: 'active',
                                                child: Text(
                                                    AppLocalizations.of(
                                                            context)!
                                                        .active,
                                                    style: const TextStyle(
                                                        fontSize: 12)),
                                              ),
                                              DropdownMenuItem(
                                                value: 'inactive',
                                                child: Text(
                                                    AppLocalizations.of(
                                                            context)!
                                                        .inactive,
                                                    style: const TextStyle(
                                                        fontSize: 12)),
                                              ),
                                            ],
                                            onChanged: (String? newValue) {
                                              if (newValue != null) {
                                                setState(() {
                                                  row['status'] = newValue;
                                                });
                                              }
                                            },
                                            underline: Container(),
                                          )
                                        : Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: row['status'] == 'active'
                                                  ? Colors.green.shade100
                                                  : Colors.orange.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: row['status'] == 'active'
                                                    ? Colors.green
                                                    : Colors.orange,
                                              ),
                                            ),
                                            child: Text(
                                              row['status'] == 'active'
                                                  ? AppLocalizations.of(
                                                          context)!
                                                      .active
                                                  : AppLocalizations.of(
                                                          context)!
                                                      .inactive,
                                              style: TextStyle(
                                                color: row['status'] == 'active'
                                                    ? Colors.green.shade800
                                                    : Colors.orange.shade800,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      row['approved_by'] ?? 'Admin',
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 100,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isEditing) ...[
                                          IconButton(
                                            icon: const Icon(Icons.save,
                                                size: 18),
                                            color: Colors.green,
                                            onPressed: () => _saveEdit(row),
                                            tooltip:
                                                AppLocalizations.of(context)!
                                                    .saveTooltip,
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(
                                                minWidth: 32, minHeight: 32),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.cancel,
                                                size: 18),
                                            color: Colors.red,
                                            onPressed: () => _cancelEdit(row),
                                            tooltip:
                                                AppLocalizations.of(context)!
                                                    .cancelTooltip,
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(
                                                minWidth: 32, minHeight: 32),
                                          )
                                        ] else ...[
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                size: 18),
                                            color: Colors.blue,
                                            onPressed: () => _startEdit(row),
                                            tooltip:
                                                AppLocalizations.of(context)!
                                                    .editTooltip,
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(
                                                minWidth: 32, minHeight: 32),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                size: 18),
                                            color: Colors.red,
                                            onPressed: () => _deleteStaff(row),
                                            tooltip:
                                                AppLocalizations.of(context)!
                                                    .deleteTooltip,
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(
                                                minWidth: 32, minHeight: 32),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                )
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

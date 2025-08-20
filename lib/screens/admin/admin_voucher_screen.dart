// admin_voucher_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:smart_mess/l10n/app_localizations.dart';
import 'package:smart_mess/providers/language_provider.dart';
import 'package:smart_mess/services/admin_auth_service.dart';

import 'admin_home_screen.dart';
import 'admin_users_screen.dart';
import 'admin_pending_ids_screen.dart';
import 'admin_shopping_history.dart';
import 'add_voucher.dart';
import 'admin_staff_state_screen.dart';
import 'admin_dining_member_state.dart';
import 'admin_payment_history.dart';
import 'admin_inventory_screen.dart';
import 'admin_messing_screen.dart';
import 'admin_meal_state_screen.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_menu_vote_screen.dart';
import 'admin_bill_screen.dart';
import 'admin_login_screen.dart';

class AdminVoucherScreen extends StatefulWidget {
  const AdminVoucherScreen({super.key});

  @override
  State<AdminVoucherScreen> createState() => _AdminVoucherScreenState();
}

class _AdminVoucherScreenState extends State<AdminVoucherScreen> {
  final AdminAuthService _adminAuthService = AdminAuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String _currentUserName = "Loading...";
  Map<String, dynamic>? _currentUserData;

  // ...existing code...

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadVoucherData();
  }

  Future<void> _loadVoucherData() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('voucher').get();

      setState(() {
        voucherData = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'docId': doc.id, // Use Firebase document ID
            'buyer': data['buyer'] ?? '',
            'date': data['date'] ?? '',
            'images': [], // Keep empty for now since no Firebase Storage access
            'isEditing': false,
            'original': {},
          };
        }).toList();

        filteredData = List.from(voucherData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${AppLocalizations.of(context)!.errorLoadingVouchers}: $e')),
        );
      }
    }
  }

  Future<void> _checkAuthentication() async {
    try {
      final isLoggedIn = await _adminAuthService.isAdminLoggedIn();
      if (!isLoggedIn) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
          );
        }
        return;
      }

      final userData = await _adminAuthService.getCurrentAdminData();
      if (mounted) {
        setState(() {
          _currentUserData = userData;
          _currentUserName = userData?['name'] ?? 'Admin';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final TextEditingController _searchController = TextEditingController();

  // Voucher data loaded from Firebase
  List<Map<String, dynamic>> voucherData = [];

  List<Map<String, dynamic>> filteredData = [];

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

  void _saveEdit(int index) async {
    try {
      final docId = filteredData[index]['docId'];
      final entry = filteredData[index];
      final original = entry['original'] ?? {};

      // Prepare change log
      List<String> changes = [];
      for (final field in ['buyer', 'date']) {
        final oldVal = original[field];
        final newVal = entry[field];
        if (oldVal != null && oldVal.toString() != newVal.toString()) {
          changes.add('$field: "$oldVal" → "$newVal"');
        }
      }

      // Update in Firestore
      await _firestore.collection('voucher').doc(docId).update({
        'buyer': entry['buyer'],
        'date': entry['date'],
      });

      setState(() {
        entry['isEditing'] = false;

        int origIndex = voucherData.indexWhere(
          (e) => e['docId'] == entry['docId'],
        );
        if (origIndex != -1) {
          voucherData[origIndex] = Map.from(entry);
        }
      });

      // Log activity
      final adminName = _currentUserData?['name'] ?? 'Admin';
      final baNo = _currentUserData?['ba_no'] ?? '';
      if (baNo.isNotEmpty && changes.isNotEmpty) {
        await _firestore
            .collection('staff_activity_log')
            .doc(baNo)
            .collection('logs')
            .add({
          'timestamp': FieldValue.serverTimestamp(),
          'actionType': 'Update Voucher',
          'message':
              '$adminName updated voucher for "${entry['buyer']}". Changes: ${changes.join(', ')}',
          'name': adminName,
        });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.voucherUpdated)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
          content: Text(
              '${AppLocalizations.of(context)!.errorUpdatingVoucher}: $e')));
    }
  }

  Future<void> _deleteRow(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmDelete),
          content: Text(
              '${AppLocalizations.of(context)!.areYouSureYouWantToDelete} voucher for ${filteredData[index]['buyer']}?'),
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
        final docId = filteredData[index]['docId'];
        final entry = filteredData[index];
        final adminName = _currentUserData?['name'] ?? 'Admin';
        final baNo = _currentUserData?['ba_no'] ?? '';
        final buyer = entry['buyer'] ?? '';
        final date = entry['date'] ?? '';

        // Delete from Firestore
        await _firestore.collection('voucher').doc(docId).delete();

        setState(() {
          filteredData.removeAt(index);
          voucherData.removeWhere((e) => e['docId'] == docId);
        });

        // Log activity
        if (baNo.isNotEmpty) {
          await _firestore
              .collection('staff_activity_log')
              .doc(baNo)
              .collection('logs')
              .add({
            'timestamp': FieldValue.serverTimestamp(),
            'actionType': 'Delete Voucher',
            'message': '$adminName deleted voucher for "$buyer" (Date: $date).',
            'name': adminName,
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.voucherDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '${AppLocalizations.of(context)!.errorDeletingVoucher}: $e')),
          );
        }
      }
    }
  }

  Widget _editableTextField({
    required String initialValue,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      width: 100,
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
      child: Text(text,
          style: const TextStyle(color: Color.fromARGB(255, 252, 235, 235))),
    );
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

  @override
  Widget build(BuildContext context) {
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
                        onTap: () => Navigator.pop(context),
                        selected: true,
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
              AppLocalizations.of(context)!.voucherList,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.language, color: Colors.white),
                onSelected: (String value) {
                  if (value == 'bn') {
                    Provider.of<LanguageProvider>(context, listen: false)
                        .changeLanguage(const Locale('bn'));
                  } else {
                    Provider.of<LanguageProvider>(context, listen: false)
                        .changeLanguage(const Locale('en'));
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'en',
                    child: Row(
                      children: [
                        Text('🇺🇸'),
                        const SizedBox(width: 8),
                        Text('English'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'bn',
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
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Add Voucher Button First
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdminAddShoppingScreen(),
                          ),
                        );
                        // Refresh data when returning from add screen
                        if (result == true) {
                          _loadVoucherData();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(context)!.addVoucher),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0052CC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _loadVoucherData,
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.refresh),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ✅ Search Bar
                TextFormField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      filteredData = voucherData.where((entry) {
                        return entry.values.any(
                          (v) => v.toString().toLowerCase().contains(
                                value.toLowerCase(),
                              ),
                        );
                      }).toList();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.search,
                    hintText: AppLocalizations.of(context)!
                        .searchByVoucherIdBuyerDate,
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

                // ✅ Voucher Table
                Expanded(
                  child: filteredData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.receipt_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context)!.noVouchersFound,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!.addSomeVouchers,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFF134074),
                            ),
                            headingTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            columns: [
                              DataColumn(
                                  label: Text(
                                      AppLocalizations.of(context)!.index)),
                              DataColumn(
                                  label: Text(
                                      AppLocalizations.of(context)!.buyerName)),
                              DataColumn(
                                  label:
                                      Text(AppLocalizations.of(context)!.date)),
                              DataColumn(
                                  label: Text(
                                      AppLocalizations.of(context)!.images)),
                              DataColumn(
                                  label: Text(
                                      AppLocalizations.of(context)!.action)),
                            ],
                            rows: List.generate(filteredData.length, (index) {
                              final entry = filteredData[index];
                              final isEditing = entry['isEditing'] as bool;

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF134074),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    isEditing
                                        ? _editableTextField(
                                            initialValue: entry['buyer'],
                                            onChanged: (val) =>
                                                entry['buyer'] = val,
                                          )
                                        : Text(entry['buyer']),
                                  ),
                                  DataCell(
                                    isEditing
                                        ? _editableTextField(
                                            initialValue: entry['date'],
                                            onChanged: (val) =>
                                                entry['date'] = val,
                                          )
                                        : Text(entry['date']),
                                  ),
                                  DataCell(
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // TODO: Implement image view dialog
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(AppLocalizations.of(
                                                      context)!
                                                  .viewImagesFeatureComingSoon)),
                                        );
                                      },
                                      icon: const Icon(Icons.image),
                                      label: Text(AppLocalizations.of(context)!
                                          .viewImages),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF0052CC),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        if (!isEditing)
                                          _actionButton(
                                            text: AppLocalizations.of(context)!
                                                .edit,
                                            color: const Color(0xFF0052CC),
                                            onPressed: () => _startEdit(index),
                                          ),
                                        if (isEditing) ...[
                                          _actionButton(
                                            text: AppLocalizations.of(context)!
                                                .save,
                                            color: Colors.green,
                                            onPressed: () => _saveEdit(index),
                                          ),
                                          const SizedBox(width: 6),
                                          _actionButton(
                                            text: AppLocalizations.of(context)!
                                                .cancel,
                                            color: Colors.grey,
                                            onPressed: () => _cancelEdit(index),
                                          ),
                                        ],
                                        const SizedBox(width: 6),
                                        _actionButton(
                                          text: AppLocalizations.of(context)!
                                              .delete,
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
      },
    );
  }
}

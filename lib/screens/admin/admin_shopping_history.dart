import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:smart_mess/l10n/app_localizations.dart';
import 'package:smart_mess/providers/language_provider.dart';
import 'package:smart_mess/screens/admin/admin_login_screen.dart';
import 'package:smart_mess/services/admin_auth_service.dart';

import 'admin_home_screen.dart';
import 'admin_payment_history.dart';
import 'admin_dining_member_state.dart';
import 'admin_users_screen.dart';
import 'admin_pending_ids_screen.dart';
import 'add_shopping.dart';
import 'admin_voucher_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_messing_screen.dart';
import 'admin_staff_state_screen.dart';
import 'admin_meal_state_screen.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_menu_vote_screen.dart';
import 'admin_bill_screen.dart';

class AdminShoppingHistoryScreen extends StatefulWidget {
  const AdminShoppingHistoryScreen({super.key});

//jjjj
  @override
  State<AdminShoppingHistoryScreen> createState() =>
      _AdminShoppingHistoryScreenState();
}

class _AdminShoppingHistoryScreenState
    extends State<AdminShoppingHistoryScreen> {
  final AdminAuthService _adminAuthService = AdminAuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  String _currentUserName = "Loading...";
  Map<String, dynamic>? _currentUserData;

  final TextEditingController _searchController = TextEditingController();

  // Shopping data loaded from Firebase
  List<Map<String, dynamic>> shoppingData = [];
  List<Map<String, dynamic>> filteredData = [];

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadShoppingData();
  }

  Future<void> _loadShoppingData() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('shopping').get();
      
      setState(() {
        shoppingData = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'docId': doc.id, // Use Firebase document ID
            'productName': data['productName'] ?? '',
            'unitPrice': data['unitPrice'] ?? 0.0,
            'amount': data['amount'] ?? 0.0,
            'totalPrice': data['totalPrice'] ?? 0.0,
            'date': data['date'] ?? '',
            'voucherId': data['voucherId'] ?? '',
            'isEditing': false,
            'original': {},
          };
        }).toList();
        
        filteredData = List.from(shoppingData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorLoadingShoppingData}: $e')),
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
        style: const TextStyle(fontSize: 14),
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
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 5, 97, 235),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
        shadowColor: color.withOpacity(0.6),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  void _search(String query) {
    setState(() {
      filteredData = shoppingData.where((entry) {
        return entry.values.any(
          (value) =>
              value.toString().toLowerCase().contains(query.toLowerCase()),
        );
      }).toList();
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
          SnackBar(content: Text('${AppLocalizations.of(context)!.logoutFailed}: $e')),
        );
      }
    }
  }

  void _startEdit(int index) {
    setState(() {
      // Backup original data for canceling edits
      filteredData[index]['original'] = Map<String, dynamic>.from(
        filteredData[index],
      );
      filteredData[index]['isEditing'] = true;
    });
  }

  void _cancelEdit(int index) {
    setState(() {
      // Restore original data
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
      
      // Recalculate totalPrice
      entry['totalPrice'] = (entry['unitPrice'] * entry['amount']);
      
      // Update in Firestore
      await _firestore.collection('shopping').doc(docId).update({
        'productName': entry['productName'],
        'unitPrice': entry['unitPrice'],
        'amount': entry['amount'],
        'totalPrice': entry['totalPrice'],
        'date': entry['date'],
        'voucherId': entry['voucherId'],
      });

      setState(() {
        entry['isEditing'] = false;

        int origIndex = shoppingData.indexWhere(
          (e) => e['docId'] == filteredData[index]['docId'],
        );
        if (origIndex != -1) {
          shoppingData[origIndex] = Map.from(filteredData[index]);
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.shoppingEntryUpdated)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.errorUpdatingShoppingEntry}: $e')));
    }
  }

  Future<void> _deleteRow(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmDelete),
          content: Text(
              '${AppLocalizations.of(context)!.areYouSureYouWantToDelete} "${filteredData[index]['productName']}" from shopping history?'),
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
        
        // Delete from Firestore
        await _firestore.collection('shopping').doc(docId).delete();

        setState(() {
          filteredData.removeAt(index);
          shoppingData.removeWhere((e) => e['docId'] == docId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.shoppingEntryDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppLocalizations.of(context)!.errorDeletingShoppingEntry}: $e')),
          );
        }
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
                          builder: (context) => const AdminPendingIdsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.history,
                    title: AppLocalizations.of(context)!.shoppingHistory,
                    onTap: () => Navigator.pop(context),
                    selected: true,
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
                          builder: (context) => const AdminInventoryScreen(),
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
                          builder: (context) => const AdminMealStateScreen(),
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
                          builder: (context) => const DiningMemberStatePage(),
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
          AppLocalizations.of(context)!.shoppingHistory,
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
            languageProvider.changeLanguage(const Locale('bn'));
          } else {
            languageProvider.changeLanguage(const Locale('en'));
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminAddShoppingScreen(),
                        ),
                      );
                      // Refresh data when returning from add screen
                      if (result == true) {
                        _loadShoppingData();
                      }
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      AppLocalizations.of(context)!.addShoppingData,
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A4D8F),
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
                    onPressed: _loadShoppingData,
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
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.search,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _search,
                      decoration: InputDecoration(
                        hintText: "${AppLocalizations.of(context)!.search}...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filteredData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.noShoppingDataFound,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.addSomeShoppingEntries,
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
                    columnSpacing: 24,
                    headingRowHeight: 56,
                    dataRowHeight: 64,
                    horizontalMargin: 12,
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFF134074),
                    ),
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontSize: 15,
                    ),
                    dataTextStyle: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                    dataRowColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.blue.shade100.withOpacity(0.4);
                      }
                      return null;
                    }),
                    columns: [
                      DataColumn(label: Text(AppLocalizations.of(context)!.index)),
                      DataColumn(label: Text(AppLocalizations.of(context)!.productName)),
                      DataColumn(label: Text(AppLocalizations.of(context)!.unitPrice)),
                      DataColumn(label: Text(AppLocalizations.of(context)!.amount)),
                      DataColumn(label: Text(AppLocalizations.of(context)!.totalPrice)),
                      DataColumn(label: Text(AppLocalizations.of(context)!.date)),
                      DataColumn(label: Text(AppLocalizations.of(context)!.voucherId)),
                      DataColumn(label: Text(AppLocalizations.of(context)!.action)),
                    ],
                    rows: List.generate(filteredData.length, (index) {
                      final entry = filteredData[index];
                      final isEditing = entry['isEditing'] as bool;

                      // Zebra striping
                      final rowColor =
                          index % 2 == 0 ? Colors.grey[100] : Colors.white;

                      return DataRow(
                        color: WidgetStateProperty.all(rowColor),
                        cells: [
                          DataCell(Text('${index + 1}', style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF134074),
                          ))),
                          DataCell(
                            isEditing
                                ? _editableTextField(
                                    initialValue: entry['productName'],
                                    onChanged: (val) =>
                                        entry['productName'] = val,
                                  )
                                : Text(entry['productName']),
                          ),
                          DataCell(
                            isEditing
                                ? _editableTextField(
                                    initialValue: entry['unitPrice'].toString(),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => entry['unitPrice'] =
                                        double.tryParse(val) ?? 0.0,
                                  )
                                : Text(entry['unitPrice'].toStringAsFixed(2)),
                          ),
                          DataCell(
                            isEditing
                                ? _editableTextField(
                                    initialValue: entry['amount'].toString(),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => entry['amount'] =
                                        double.tryParse(val) ?? 0.0,
                                  )
                                : Text(entry['amount'].toStringAsFixed(2)),
                          ),
                          DataCell(
                            Text(entry['totalPrice'].toStringAsFixed(2)),
                          ),
                          DataCell(
                            isEditing
                                ? _editableTextField(
                                    initialValue: entry['date'],
                                    onChanged: (val) => entry['date'] = val,
                                  )
                                : Text(entry['date']),
                          ),
                          DataCell(
                            isEditing
                                ? _editableTextField(
                                    initialValue: entry['voucherId'],
                                    onChanged: (val) =>
                                        entry['voucherId'] = val,
                                  )
                                : Text(entry['voucherId']),
                          ),
                          DataCell(
                            Row(
                              children: [
                                if (!isEditing)
                                  _actionButton(
                                    text: AppLocalizations.of(context)!.edit,
                                    color: const Color(0xFF0052CC),
                                    onPressed: () => _startEdit(index),
                                  ),
                                if (isEditing) ...[
                                  _actionButton(
                                    text: AppLocalizations.of(context)!.save,
                                    color: const Color(0xFF2E8B57),
                                    onPressed: () => _saveEdit(index),
                                  ),
                                  const SizedBox(width: 8),
                                  _actionButton(
                                    text: AppLocalizations.of(context)!.cancel,
                                    color: Colors.grey.shade600,
                                    onPressed: () => _cancelEdit(index),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                _actionButton(
                                  text: AppLocalizations.of(context)!.delete,
                                  color: const Color(0xFFCC0000),
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
      ),
    );
      },
    );
  }
}

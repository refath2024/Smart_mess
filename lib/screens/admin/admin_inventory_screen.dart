import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:smart_mess/l10n/app_localizations.dart';
import 'package:smart_mess/providers/language_provider.dart';

import 'admin_home_screen.dart';
import 'admin_users_screen.dart';
import 'admin_pending_ids_screen.dart';
import 'admin_shopping_history.dart';
import 'admin_voucher_screen.dart';
import 'add_inventory.dart';
import 'admin_messing_screen.dart';
import 'admin_staff_state_screen.dart';
import 'admin_dining_member_state.dart';
import 'admin_payment_history.dart';
import 'admin_bill_screen.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_menu_vote_screen.dart';
import 'admin_meal_state_screen.dart';
import 'admin_login_screen.dart';
import '../../services/admin_auth_service.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  final AdminAuthService _adminAuthService = AdminAuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String _currentUserName = "Admin User";
  Map<String, dynamic>? _currentUserData;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadInventoryData();
  }

  Future<void> _loadInventoryData() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('inventory').get();
      
      setState(() {
        inventoryData = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'docId': doc.id, // Use Firebase document ID
            'productName': data['productName'] ?? '',
            'quantityHeld': data['quantityHeld'] ?? 0,
            'type': data['type'] ?? '',
            'isEditing': false,
            'original': {},
          };
        }).toList();
        
        filteredData = List.from(inventoryData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorLoadingInventory}: $e')),
        );
      }
    }
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
          SnackBar(content: Text('${AppLocalizations.of(context)!.logoutFailed}: $e')),
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

  // Inventory data loaded from Firebase
  List<Map<String, dynamic>> inventoryData = [];

  List<Map<String, dynamic>> filteredData = [];

  final TextEditingController _searchController = TextEditingController();

  final List<String> _types = ['fresh', 'utensils', 'ration'];

  String _getTranslatedType(String type) {
    switch (type) {
      case 'fresh':
        return AppLocalizations.of(context)!.fresh;
      case 'utensils':
        return AppLocalizations.of(context)!.utensils;
      case 'ration':
        return AppLocalizations.of(context)!.ration;
      default:
        return type;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      
      // Update in Firestore (no need for manual ID field)
      await _firestore.collection('inventory').doc(docId).update({
        'productName': filteredData[index]['productName'],
        'quantityHeld': filteredData[index]['quantityHeld'],
        'type': filteredData[index]['type'],
      });

      setState(() {
        filteredData[index]['isEditing'] = false;

        int origIndex = inventoryData.indexWhere(
          (e) => e['docId'] == filteredData[index]['docId'],
        );
        if (origIndex != -1) {
          inventoryData[origIndex] = Map.from(filteredData[index]);
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inventory updated')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.errorUpdatingInventory}: $e')));
    }
  }

  Future<void> _deleteRow(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmDelete),
          content: Text(
              '${AppLocalizations.of(context)!.areYouSureYouWantToDelete} "${filteredData[index]['productName']}"?'),
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
        await _firestore.collection('inventory').doc(docId).delete();

        setState(() {
          filteredData.removeAt(index);
          inventoryData.removeWhere((e) => e['docId'] == docId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.inventoryItemDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppLocalizations.of(context)!.errorDeletingInventory}: $e')),
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
      width: 140,
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
      child: Text(
        text,
        style: const TextStyle(color: Color.fromARGB(255, 252, 235, 235)),
      ),
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
                          builder: (_) => const AdminHomeScreen(),
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
                    onTap: () => Navigator.pop(context),
                    selected: true,
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
                    icon: Icons.how_to_vote,
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
          AppLocalizations.of(context)!.inventory,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(
              Icons.language,
              color: Colors.white,
            ),
            onSelected: (Locale locale) {
              languageProvider.changeLanguage(locale);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<Locale>(
                value: const Locale('en'),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(1),
                        child: Stack(
                          children: [
                            // Red cross background
                            Container(color: const Color(0xFF012169)), // Blue background
                            // White cross
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 6,
                              child: Container(height: 2, color: Colors.white),
                            ),
                            Positioned(
                              top: 0,
                              bottom: 0,
                              left: 9,
                              child: Container(width: 2, color: Colors.white),
                            ),
                            // Red cross
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 6.5,
                              child: Container(height: 1, color: const Color(0xFFCE1124)),
                            ),
                            Positioned(
                              top: 0,
                              bottom: 0,
                              left: 9.5,
                              child: Container(width: 1, color: const Color(0xFFCE1124)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.english),
                    if (languageProvider.isEnglish) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuItem<Locale>(
                value: const Locale('bn'),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(1),
                        child: Stack(
                          children: [
                            // Green background
                            Container(color: const Color(0xFF006A4E)),
                            // Red circle
                            Positioned(
                              left: 6,
                              top: 3,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF42A41),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.bangla),
                    if (languageProvider.isBangla) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
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
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddInventoryScreen()),
                    );
                    // Refresh data when returning from add screen
                    if (result == true) {
                      _loadInventoryData();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: Text(AppLocalizations.of(context)!.addInventoryEntry),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _loadInventoryData,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
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

            // Search bar
            TextFormField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  filteredData = inventoryData.where((entry) {
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
                hintText: AppLocalizations.of(context)!.searchByProductName,
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

            // Inventory table
            Expanded(
              child: filteredData.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.noInventoryItemsFound,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.addSomeInventoryItems,
                            style: TextStyle(
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
                          DataColumn(label: Text(AppLocalizations.of(context)!.index)),
                          DataColumn(label: Text(AppLocalizations.of(context)!.productName)),
                          DataColumn(label: Text(AppLocalizations.of(context)!.quantityHeld)),
                          DataColumn(label: Text(AppLocalizations.of(context)!.type)),
                          DataColumn(label: Text(AppLocalizations.of(context)!.action)),
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
                                        initialValue: entry['productName'],
                                        onChanged: (val) =>
                                            entry['productName'] = val,
                                      )
                                    : Text(entry['productName']),
                              ),
                              DataCell(
                                isEditing
                                    ? _editableTextField(
                                        initialValue:
                                            entry['quantityHeld'].toString(),
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          entry['quantityHeld'] =
                                              int.tryParse(val) ?? 0;
                                          setState(() {});
                                        },
                                      )
                                    : Text('${entry['quantityHeld']}'),
                              ),
                              DataCell(
                                isEditing
                                    ? DropdownButton<String>(
                                        value: entry['type'],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              entry['type'] = val;
                                            });
                                          }
                                        },
                                        items: _types
                                            .map(
                                              (type) => DropdownMenuItem(
                                                value: type,
                                                child: Text(
                                                  _getTranslatedType(type),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      )
                                    : Text(
                                        _getTranslatedType(entry['type']),
                                      ),
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
                                        color: Colors.green,
                                        onPressed: () => _saveEdit(index),
                                      ),
                                      const SizedBox(width: 6),
                                      _actionButton(
                                        text: AppLocalizations.of(context)!.cancel,
                                        color: Colors.grey,
                                        onPressed: () => _cancelEdit(index),
                                      ),
                                    ],
                                    const SizedBox(width: 6),
                                    _actionButton(
                                      text: AppLocalizations.of(context)!.delete,
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

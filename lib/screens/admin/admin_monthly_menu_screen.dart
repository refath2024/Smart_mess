import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/language_provider.dart';
import 'add_menu_list.dart';
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
import 'admin_bill_screen.dart';
import 'admin_home_screen.dart';
import 'admin_menu_vote_screen.dart';
import 'admin_login_screen.dart';
import '../../services/admin_auth_service.dart';

class EditMenuScreen extends StatefulWidget {
  const EditMenuScreen({super.key});

  @override
  State<EditMenuScreen> createState() => _EditMenuScreenState();
}

class _EditMenuScreenState extends State<EditMenuScreen> {
  final AdminAuthService _adminAuthService = AdminAuthService();

  bool _isLoading = true;
  String _currentUserName = "Admin User";
  Map<String, dynamic>? _currentUserData;

  List<Map<String, dynamic>> menuData = [];

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    fetchMenu();
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

  Future<void> fetchMenu() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final firestore = FirebaseFirestore.instance;

      // Get all menu documents from Firestore
      final QuerySnapshot querySnapshot = await firestore
          .collection('monthly_menu')
          .orderBy('date', descending: false)
          .get();

      final List<Map<String, dynamic>> fetchedMenuData = [];

      // Add existing menu data from Firestore
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dateId = doc.id;

        fetchedMenuData.add({
          'id': dateId,
          'date': dateId,
          'breakfast': data['breakfast']?['item'] ?? '',
          'breakfastPrice': data['breakfast']?['price']?.toString() ?? '',
          'lunch': data['lunch']?['item'] ?? '',
          'lunchPrice': data['lunch']?['price']?.toString() ?? '',
          'dinner': data['dinner']?['item'] ?? '',
          'dinnerPrice': data['dinner']?['price']?.toString() ?? '',
        });
      }

      // If no data exists, add today's date as an empty entry
      if (fetchedMenuData.isEmpty) {
        final today = DateTime.now();
        final todayId =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        fetchedMenuData.add({
          'id': todayId,
          'date': todayId,
          'breakfast': '',
          'breakfastPrice': '',
          'lunch': '',
          'lunchPrice': '',
          'dinner': '',
          'dinnerPrice': '',
        });
      }

      setState(() {
        menuData = fetchedMenuData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching menu data: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading menu data: $e')),
        );
      }
    }
  }

  void editRow(int index) async {
    final item = menuData[index];
    final breakfastController = TextEditingController(text: item['breakfast']);
    final breakfastPriceController =
        TextEditingController(text: item['breakfastPrice']);
    final lunchController = TextEditingController(text: item['lunch']);
    final lunchPriceController =
        TextEditingController(text: item['lunchPrice']);
    final dinnerController = TextEditingController(text: item['dinner']);
    final dinnerPriceController =
        TextEditingController(text: item['dinnerPrice']);

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${AppLocalizations.of(context)!.editMenuFor} ${item['date']}',
          style: const TextStyle(
            color: Color(0xFF002B5B),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildEditField(AppLocalizations.of(context)!.breakfast,
                  breakfastController, breakfastPriceController),
              const SizedBox(height: 16),
              buildEditField(AppLocalizations.of(context)!.lunch,
                  lunchController, lunchPriceController),
              const SizedBox(height: 16),
              buildEditField(AppLocalizations.of(context)!.dinner,
                  dinnerController, dinnerPriceController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.confirmCancel),
                  content: Text(AppLocalizations.of(context)!.discardChanges),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(AppLocalizations.of(context)!.no),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text(AppLocalizations.of(context)!.yes),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                Navigator.of(context).pop(false);
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.confirmSave),
                  content: Text(AppLocalizations.of(context)!.saveChanges),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(AppLocalizations.of(context)!.no),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.green),
                      child: Text(AppLocalizations.of(context)!.yes),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                Navigator.of(context).pop(true);
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      try {
        // Show loading indicator
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(AppLocalizations.of(context)!.savingChanges),
                ],
              ),
            ),
          );
        }

        final firestore = FirebaseFirestore.instance;
        final dateId = item['date'] as String;

        // Prepare data with smart NULL handling
        Map<String, dynamic> updateData = {};

        // Add breakfast data if provided
        if (breakfastController.text.isNotEmpty ||
            breakfastPriceController.text.isNotEmpty) {
          updateData['breakfast'] = {
            if (breakfastController.text.isNotEmpty)
              'item': breakfastController.text.trim(),
            if (breakfastPriceController.text.isNotEmpty)
              'price': double.tryParse(breakfastPriceController.text) ?? 0.0,
          };
        } else {
          // Remove breakfast data if both fields are empty
          updateData['breakfast'] = FieldValue.delete();
        }

        // Add lunch data if provided
        if (lunchController.text.isNotEmpty ||
            lunchPriceController.text.isNotEmpty) {
          updateData['lunch'] = {
            if (lunchController.text.isNotEmpty)
              'item': lunchController.text.trim(),
            if (lunchPriceController.text.isNotEmpty)
              'price': double.tryParse(lunchPriceController.text) ?? 0.0,
          };
        } else {
          // Remove lunch data if both fields are empty
          updateData['lunch'] = FieldValue.delete();
        }

        // Add dinner data if provided
        if (dinnerController.text.isNotEmpty ||
            dinnerPriceController.text.isNotEmpty) {
          updateData['dinner'] = {
            if (dinnerController.text.isNotEmpty)
              'item': dinnerController.text.trim(),
            if (dinnerPriceController.text.isNotEmpty)
              'price': double.tryParse(dinnerPriceController.text) ?? 0.0,
          };
        } else {
          // Remove dinner data if both fields are empty
          updateData['dinner'] = FieldValue.delete();
        }

        // Add metadata
        final dateObj =
            DateTime.tryParse(dateId.replaceAll('-', '/')) ?? DateTime.now();
        updateData['date'] = dateObj;
        updateData['lastUpdated'] = FieldValue.serverTimestamp();

        // Save to Firestore
        await firestore
            .collection('monthly_menu')
            .doc(dateId)
            .set(updateData, SetOptions(merge: true));

        // Update local data
        setState(() {
          menuData[index]['breakfast'] = breakfastController.text;
          menuData[index]['breakfastPrice'] = breakfastPriceController.text;
          menuData[index]['lunch'] = lunchController.text;
          menuData[index]['lunchPrice'] = lunchPriceController.text;
          menuData[index]['dinner'] = dinnerController.text;
          menuData[index]['dinnerPrice'] = dinnerPriceController.text;
        });

        // Dismiss loading dialog
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.menuUpdatedSuccessfully)),
          );
        }
      } catch (e) {
        // Dismiss loading dialog
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating menu: $e')),
          );
        }
      }
    }
  }

  Widget buildEditField(String title, TextEditingController nameController,
      TextEditingController priceController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.itemName,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: priceController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.price,
            prefixText: '৳',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  void deleteRow(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDelete),
        content: Text(AppLocalizations.of(context)!.deleteMenuItemConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.no),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: Text(AppLocalizations.of(context)!.yes),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Show loading indicator
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(AppLocalizations.of(context)!.deletingMenu),
                ],
              ),
            ),
          );
        }

        final dateId = menuData[index]['date'] as String;
        final firestore = FirebaseFirestore.instance;

        // Delete from Firestore
        await firestore.collection('monthly_menu').doc(dateId).delete();

        // Update local data
        setState(() {
          menuData.removeAt(index);
        });

        // Dismiss loading dialog
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.menuItemDeletedSuccessfully)),
          );
        }
      } catch (e) {
        // Dismiss loading dialog
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting menu: $e')),
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
          SnackBar(content: Text('Logout failed: $e')),
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
                        onTap: () => Navigator.pop(context),
                        selected: true,
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
              AppLocalizations.of(context)!.monthlyMenu,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.language, color: Colors.white),
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
              const SizedBox(width: 8),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.menu,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF002B5B),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.search,
                            prefixIcon: const Icon(Icons.search),
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A4D8F),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context)!.go,
                          style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddMenuListScreen(),
                          ),
                        );

                        // Refresh menu data if a new item was added
                        if (result == true) {
                          fetchMenu();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A4D8F),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context)!.create,
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    elevation: 4,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: RawScrollbar(
                        thumbVisibility: false,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: RawScrollbar(
                            thumbVisibility: false,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                headingRowColor:
                                    WidgetStateProperty.all(Colors.grey[50]),
                                dataRowMaxHeight: 80,
                                columnSpacing: 40,
                                horizontalMargin: 24,
                                columns: [
                                  DataColumn(
                                    label: Text(
                                      AppLocalizations.of(context)!.date,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF002B5B),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      AppLocalizations.of(context)!.breakfast,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF002B5B),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      AppLocalizations.of(context)!.lunch,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF002B5B),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      AppLocalizations.of(context)!.dinner,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF002B5B),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      AppLocalizations.of(context)!.actions,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF002B5B),
                                      ),
                                    ),
                                  ),
                                ],
                                rows: menuData.map((item) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(item['date'])),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(item['breakfast']),
                                            Text('৳${item['breakfastPrice']}',
                                                style: TextStyle(
                                                    color: Colors.grey[600])),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(item['lunch']),
                                            Text('৳${item['lunchPrice']}',
                                                style: TextStyle(
                                                    color: Colors.grey[600])),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(item['dinner']),
                                            Text('৳${item['dinnerPrice']}',
                                                style: TextStyle(
                                                    color: Colors.grey[600])),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () => editRow(
                                                  menuData.indexOf(item)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                              ),
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .edit,
                                                  style: const TextStyle(
                                                      color: Colors.white)),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () => deleteRow(
                                                  menuData.indexOf(item)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                              ),
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .delete,
                                                  style: const TextStyle(
                                                      color: Colors.white)),
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
                      ),
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

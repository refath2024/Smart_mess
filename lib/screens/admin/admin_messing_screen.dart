import '../../services/admin_auth_service.dart';
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
  DateTime _selectedDate = DateTime.now();

  TextEditingController searchController = TextEditingController();
  String currentDay = "";
  String userName = "Admin";

  // Messing data from Firebase
  List<Map<String, dynamic>> _breakfastEntries = [];
  List<Map<String, dynamic>> _lunchEntries = [];
  List<Map<String, dynamic>> _dinnerEntries = [];

  // Totals
  double _breakfastTotalExpended = 0.0;
  double _breakfastTotalPerMember = 0.0;
  double _lunchTotalExpended = 0.0;
  double _lunchTotalPerMember = 0.0;
  double _dinnerTotalExpended = 0.0;
  double _dinnerTotalPerMember = 0.0;

  // Track which row is being edited for each meal
  int? editingBreakfastIndex;
  int? editingLunchIndex;
  int? editingDinnerIndex;

  // Controllers for editing
  List<TextEditingController> breakfastControllers = [];
  List<TextEditingController> lunchControllers = [];
  List<TextEditingController> dinnerControllers = [];

  // Editing state
  Map<String, TextEditingController> _editingControllers = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _checkAuthentication();
    _fetchCurrentDay();
    _loadMessingData();
    _initControllers();
  }

  @override
  void dispose() {
    _editingControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
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

  Future<void> _loadMessingData() async {
    final dateStr =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    try {
      final doc = await FirebaseFirestore.instance
          .collection('messing_data')
          .doc(dateStr)
          .get();

      if (!doc.exists) {
        setState(() {
          _breakfastEntries = [];
          _lunchEntries = [];
          _dinnerEntries = [];
          _resetTotals();
        });
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      _parseMessingData(data);
    } catch (e) {
      print('Error loading messing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _parseMessingData(Map<String, dynamic> data) {
    List<Map<String, dynamic>> breakfast = [];
    List<Map<String, dynamic>> lunch = [];
    List<Map<String, dynamic>> dinner = [];

    // Parse individual entries
    for (String key in data.keys) {
      if (key.startsWith('B') && key.contains('_product_name')) {
        final number = key.split('_')[0].substring(1);
        breakfast.add(_createEntryFromData(data, 'B$number'));
      } else if (key.startsWith('L') && key.contains('_product_name')) {
        final number = key.split('_')[0].substring(1);
        lunch.add(_createEntryFromData(data, 'L$number'));
      } else if (key.startsWith('D') && key.contains('_product_name')) {
        final number = key.split('_')[0].substring(1);
        dinner.add(_createEntryFromData(data, 'D$number'));
      }
    }

    // Get totals
    final breakfastTotalExpended =
        data['breakfast_total_price_expended']?.toDouble() ?? 0.0;
    final breakfastTotalPerMember =
        data['breakfast_total_price_per_member']?.toDouble() ?? 0.0;
    final lunchTotalExpended =
        data['lunch_total_price_expended']?.toDouble() ?? 0.0;
    final lunchTotalPerMember =
        data['lunch_total_price_per_member']?.toDouble() ?? 0.0;
    final dinnerTotalExpended =
        data['dinner_total_price_expended']?.toDouble() ?? 0.0;
    final dinnerTotalPerMember =
        data['dinner_total_price_per_member']?.toDouble() ?? 0.0;

    setState(() {
      _breakfastEntries = breakfast;
      _lunchEntries = lunch;
      _dinnerEntries = dinner;
      _breakfastTotalExpended = breakfastTotalExpended;
      _breakfastTotalPerMember = breakfastTotalPerMember;
      _lunchTotalExpended = lunchTotalExpended;
      _lunchTotalPerMember = lunchTotalPerMember;
      _dinnerTotalExpended = dinnerTotalExpended;
      _dinnerTotalPerMember = dinnerTotalPerMember;
    });
  }

  Map<String, dynamic> _createEntryFromData(
      Map<String, dynamic> data, String prefix) {
    return {
      'id': prefix,
      'ingredient_name': data['${prefix}_product_name'] ?? '',
      'unit_price': data['${prefix}_unit_price']?.toDouble() ?? 0.0,
      'amount': data['${prefix}_amount_used']?.toDouble() ?? 0.0,
      'members': data['${prefix}_dining_members']?.toDouble() ?? 0.0,
      'total_prices': data['${prefix}_price_expended']?.toDouble() ?? 0.0,
      'ingredient_price': data['${prefix}_price_per_member']?.toDouble() ?? 0.0,
      'meal_type': data['${prefix}_meal_type'] ?? '',
    };
  }

  void _resetTotals() {
    _breakfastTotalExpended = 0.0;
    _breakfastTotalPerMember = 0.0;
    _lunchTotalExpended = 0.0;
    _lunchTotalPerMember = 0.0;
    _dinnerTotalExpended = 0.0;
    _dinnerTotalPerMember = 0.0;
  }

  Future<void> _recalculateAndUpdateTotals() async {
    final dateStr =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    try {
      // Calculate breakfast totals
      double breakfastTotalExpended = 0.0;
      double breakfastTotalPerMember = 0.0;
      for (var entry in _breakfastEntries) {
        final unitPrice = entry['unit_price']?.toDouble() ?? 0.0;
        final amount = entry['amount']?.toDouble() ?? 0.0;
        final members = entry['members']?.toDouble() ?? 0.0;
        final priceExpended = unitPrice * amount;
        final pricePerMember = members > 0 ? priceExpended / members : 0.0;

        breakfastTotalExpended += priceExpended;
        breakfastTotalPerMember += pricePerMember;
      }

      // Calculate lunch totals
      double lunchTotalExpended = 0.0;
      double lunchTotalPerMember = 0.0;
      for (var entry in _lunchEntries) {
        final unitPrice = entry['unit_price']?.toDouble() ?? 0.0;
        final amount = entry['amount']?.toDouble() ?? 0.0;
        final members = entry['members']?.toDouble() ?? 0.0;
        final priceExpended = unitPrice * amount;
        final pricePerMember = members > 0 ? priceExpended / members : 0.0;

        lunchTotalExpended += priceExpended;
        lunchTotalPerMember += pricePerMember;
      }

      // Calculate dinner totals
      double dinnerTotalExpended = 0.0;
      double dinnerTotalPerMember = 0.0;
      for (var entry in _dinnerEntries) {
        final unitPrice = entry['unit_price']?.toDouble() ?? 0.0;
        final amount = entry['amount']?.toDouble() ?? 0.0;
        final members = entry['members']?.toDouble() ?? 0.0;
        final priceExpended = unitPrice * amount;
        final pricePerMember = members > 0 ? priceExpended / members : 0.0;

        dinnerTotalExpended += priceExpended;
        dinnerTotalPerMember += pricePerMember;
      }

      // Update Firebase with new totals
      await FirebaseFirestore.instance
          .collection('messing_data')
          .doc(dateStr)
          .update({
        'breakfast_total_price_expended': breakfastTotalExpended,
        'breakfast_total_price_per_member': breakfastTotalPerMember,
        'lunch_total_price_expended': lunchTotalExpended,
        'lunch_total_price_per_member': lunchTotalPerMember,
        'dinner_total_price_expended': dinnerTotalExpended,
        'dinner_total_price_per_member': dinnerTotalPerMember,
      });

      // Update monthly menu prices with actual costs
      await _updateMonthlyMenuPrices(dateStr, breakfastTotalPerMember,
          lunchTotalPerMember, dinnerTotalPerMember);

      // Update local state
      setState(() {
        _breakfastTotalExpended = breakfastTotalExpended;
        _breakfastTotalPerMember = breakfastTotalPerMember;
        _lunchTotalExpended = lunchTotalExpended;
        _lunchTotalPerMember = lunchTotalPerMember;
        _dinnerTotalExpended = dinnerTotalExpended;
        _dinnerTotalPerMember = dinnerTotalPerMember;
      });
    } catch (e) {
      print('Error recalculating totals: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating totals: $e')),
        );
      }
    }
  }

  Future<void> _updateMonthlyMenuPrices(String dateStr, double breakfastPrice,
      double lunchPrice, double dinnerPrice) async {
    try {
      // Check if monthly menu document exists for this date
      final monthlyMenuDoc = await FirebaseFirestore.instance
          .collection('monthly_menu')
          .doc(dateStr)
          .get();

      if (monthlyMenuDoc.exists) {
        // Update existing document with actual prices
        final currentData = monthlyMenuDoc.data() as Map<String, dynamic>;

        await FirebaseFirestore.instance
            .collection('monthly_menu')
            .doc(dateStr)
            .update({
          'breakfast': {
            'item': currentData['breakfast']?['item'] ?? '',
            'price': breakfastPrice,
          },
          'lunch': {
            'item': currentData['lunch']?['item'] ?? '',
            'price': lunchPrice,
          },
          'dinner': {
            'item': currentData['dinner']?['item'] ?? '',
            'price': dinnerPrice,
          },
        });

        print('Updated monthly menu prices for $dateStr');
      } else {
        // Create new document with actual prices (items will be empty)
        await FirebaseFirestore.instance
            .collection('monthly_menu')
            .doc(dateStr)
            .set({
          'date': dateStr,
          'breakfast': {
            'item': '',
            'price': breakfastPrice,
          },
          'lunch': {
            'item': '',
            'price': lunchPrice,
          },
          'dinner': {
            'item': '',
            'price': dinnerPrice,
          },
        });

        print('Created monthly menu with actual prices for $dateStr');
      }
    } catch (e) {
      print('Error updating monthly menu prices: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating monthly menu prices: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadMessingData();
      _fetchCurrentDay();
    }
  }

  String _getFormattedDate() {
    return "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
  }

  List<Map<String, dynamic>> breakfastEntries = [];
  List<Map<String, dynamic>> lunchEntries = [];
  List<Map<String, dynamic>> dinnerEntries = [];

  void _initControllers() {
    breakfastControllers = List.generate(
      _breakfastEntries.length,
      (i) => TextEditingController(),
    );
    lunchControllers = List.generate(
      _lunchEntries.length,
      (i) => TextEditingController(),
    );
    dinnerControllers = List.generate(
      _dinnerEntries.length,
      (i) => TextEditingController(),
    );
  }

  void _fetchCurrentDay() {
    final now = _selectedDate;
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
          SnackBar(
              content:
                  Text('${AppLocalizations.of(context)!.logoutFailed}: $e')),
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
              headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  return const Color(0xFF1A4D8F); // Blue background for headers
                },
              ),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.hovered)) {
                    return Colors.blue.shade50;
                  }
                  return Colors.white;
                },
              ),
              columns: [
                DataColumn(
                  label: Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.unitPrice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.amount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.totalPrice,
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.activeMembers,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'Total Price per Member',
                      style: const TextStyle(
                        color: Colors.lightGreenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.action,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
              rows: List.generate(entries.length, (index) {
                final row = entries[index];
                final isEditing = editingIndex == index;

                // Calculate dynamic values
                final unitPrice = row['unit_price']?.toDouble() ?? 0.0;
                final amount = row['amount']?.toDouble() ?? 0.0;
                final members = row['members']?.toDouble() ?? 0.0;
                final priceExpended = unitPrice * amount;
                final pricePerMember =
                    members > 0 ? priceExpended / members : 0.0;

                // For editing mode, calculate dynamic values from controllers
                double editingPriceExpended = priceExpended;
                double editingPricePerMember = pricePerMember;
                if (isEditing && controllers.length >= 4) {
                  final editingUnitPrice =
                      double.tryParse(controllers[1].text) ?? 0.0;
                  final editingAmount =
                      double.tryParse(controllers[2].text) ?? 0.0;
                  final editingMembers =
                      double.tryParse(controllers[3].text) ?? 0.0;
                  editingPriceExpended = editingUnitPrice * editingAmount;
                  editingPricePerMember = editingMembers > 0
                      ? editingPriceExpended / editingMembers
                      : 0.0;
                }

                return DataRow(
                  cells: [
                    // Name
                    DataCell(
                      isEditing
                          ? SizedBox(
                              width: 120,
                              child: TextField(
                                controller: controllers[0],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.all(8),
                                ),
                              ),
                            )
                          : Text(row['ingredient_name'].toString()),
                    ),
                    // Unit Price (L/Kg)
                    DataCell(
                      isEditing
                          ? SizedBox(
                              width: 100,
                              child: TextField(
                                controller: controllers[1],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.all(8),
                                  suffixText: 'BDT',
                                ),
                              ),
                            )
                          : Text('${unitPrice.toStringAsFixed(2)} BDT'),
                    ),
                    // Amount (L/Kg)
                    DataCell(
                      isEditing
                          ? SizedBox(
                              width: 100,
                              child: TextField(
                                controller: controllers[2],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.all(8),
                                ),
                              ),
                            )
                          : Text(amount.toStringAsFixed(2)),
                    ),
                    // Price Expended (Dynamic, Non-editable)
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${(isEditing ? editingPriceExpended : priceExpended).toStringAsFixed(2)} BDT',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    // Dining Member
                    DataCell(
                      isEditing
                          ? SizedBox(
                              width: 80,
                              child: TextField(
                                controller: controllers[3],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.all(8),
                                ),
                              ),
                            )
                          : Text(members.toStringAsFixed(0)),
                    ),
                    // Total Price per Member (Dynamic, Non-editable)
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          '${(isEditing ? editingPricePerMember : pricePerMember).toStringAsFixed(2)} BDT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ),
                    // Actions
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
    final row = _breakfastEntries[index];
    final unitPrice = row['unit_price']?.toDouble() ?? 0.0;
    final amount = row['amount']?.toDouble() ?? 0.0;
    final members = row['members']?.toDouble() ?? 0.0;

    // Setup controllers for editing
    final nameController = TextEditingController(
      text: row['ingredient_name'].toString(),
    );
    final unitPriceController = TextEditingController(
      text: unitPrice.toString(),
    );
    final amountController = TextEditingController(
      text: amount.toString(),
    );
    final membersController = TextEditingController(
      text: members.toString(),
    );

    breakfastControllers.clear();
    breakfastControllers.addAll([
      nameController,
      unitPriceController,
      amountController,
      membersController,
    ]);

    // Add listeners for dynamic calculations
    unitPriceController.addListener(() {
      setState(() {});
    });
    amountController.addListener(() {
      setState(() {});
    });
    membersController.addListener(() {
      setState(() {});
    });

    setState(() {
      editingBreakfastIndex = index;
    });
  }

  void _editLunch(int index) {
    final row = _lunchEntries[index];
    final unitPrice = row['unit_price']?.toDouble() ?? 0.0;
    final amount = row['amount']?.toDouble() ?? 0.0;
    final members = row['members']?.toDouble() ?? 0.0;

    // Setup controllers for editing
    final nameController = TextEditingController(
      text: row['ingredient_name'].toString(),
    );
    final unitPriceController = TextEditingController(
      text: unitPrice.toString(),
    );
    final amountController = TextEditingController(
      text: amount.toString(),
    );
    final membersController = TextEditingController(
      text: members.toString(),
    );

    lunchControllers.clear();
    lunchControllers.addAll([
      nameController,
      unitPriceController,
      amountController,
      membersController,
    ]);

    // Add listeners for dynamic calculations
    unitPriceController.addListener(() {
      setState(() {});
    });
    amountController.addListener(() {
      setState(() {});
    });
    membersController.addListener(() {
      setState(() {});
    });

    setState(() {
      editingLunchIndex = index;
    });
  }

  void _editDinner(int index) {
    final row = _dinnerEntries[index];
    final unitPrice = row['unit_price']?.toDouble() ?? 0.0;
    final amount = row['amount']?.toDouble() ?? 0.0;
    final members = row['members']?.toDouble() ?? 0.0;

    // Setup controllers for editing
    final nameController = TextEditingController(
      text: row['ingredient_name'].toString(),
    );
    final unitPriceController = TextEditingController(
      text: unitPrice.toString(),
    );
    final amountController = TextEditingController(
      text: amount.toString(),
    );
    final membersController = TextEditingController(
      text: members.toString(),
    );

    dinnerControllers.clear();
    dinnerControllers.addAll([
      nameController,
      unitPriceController,
      amountController,
      membersController,
    ]);

    // Add listeners for dynamic calculations
    unitPriceController.addListener(() {
      setState(() {});
    });
    amountController.addListener(() {
      setState(() {});
    });
    membersController.addListener(() {
      setState(() {});
    });

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
      try {
        final entry = _breakfastEntries[index];
        final entryId = entry['id'];
        final dateStr =
            "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

        // Get values from controllers
        final productName = breakfastControllers[0].text.trim();
        final unitPrice = double.tryParse(breakfastControllers[1].text) ??
            entry['unit_price'];
        final amountUsed =
            double.tryParse(breakfastControllers[2].text) ?? entry['amount'];
        final diningMembers =
            double.tryParse(breakfastControllers[3].text) ?? entry['members'];

        // Calculate dynamic values
        final priceExpended = unitPrice * amountUsed;
        final pricePerMember =
            diningMembers > 0 ? priceExpended / diningMembers : 0.0;

        // Update Firebase document with correct field names
        await FirebaseFirestore.instance
            .collection('messing_data')
            .doc(dateStr)
            .update({
          '${entryId}_product_name': productName,
          '${entryId}_unit_price': unitPrice,
          '${entryId}_amount_used': amountUsed,
          '${entryId}_dining_members': diningMembers,
          '${entryId}_price_expended': priceExpended,
          '${entryId}_price_per_member': pricePerMember,
        });

        // Log activity for edit
        final adminData = await AdminAuthService().getCurrentAdminData();
        final adminBaNo = adminData?['ba_no'] ?? '';
        final adminName = adminData?['name'] ?? 'Unknown';
        if (adminBaNo.isNotEmpty) {
          final msg =
              '$adminName edited Breakfast entry on $dateStr: Product: $productName, Unit Price: $unitPrice, Amount Used: $amountUsed, Dining Members: $diningMembers, Price Expended: $priceExpended, Price Per Member: $pricePerMember.';
          await FirebaseFirestore.instance
              .collection('staff_activity_log')
              .doc(adminBaNo)
              .collection('logs')
              .add({
            'timestamp': FieldValue.serverTimestamp(),
            'actionType': 'Edit Breakfast Entry',
            'message': msg,
            'admin_id': adminData?['uid'] ?? '',
            'admin_name': adminName,
            'date': dateStr,
          });
        }

        // Reload data
        await _loadMessingData();

        // Recalculate and update totals
        await _recalculateAndUpdateTotals();

        setState(() {
          editingBreakfastIndex = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Breakfast entry updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating entry: $e')),
          );
        }
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
      try {
        final entry = _lunchEntries[index];
        final entryId = entry['id'];
        final dateStr =
            "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

        // Get values from controllers
        final productName = lunchControllers[0].text.trim();
        final unitPrice =
            double.tryParse(lunchControllers[1].text) ?? entry['unit_price'];
        final amountUsed =
            double.tryParse(lunchControllers[2].text) ?? entry['amount'];
        final diningMembers =
            double.tryParse(lunchControllers[3].text) ?? entry['members'];

        // Calculate dynamic values
        final priceExpended = unitPrice * amountUsed;
        final pricePerMember =
            diningMembers > 0 ? priceExpended / diningMembers : 0.0;

        // Update Firebase document with correct field names
        await FirebaseFirestore.instance
            .collection('messing_data')
            .doc(dateStr)
            .update({
          '${entryId}_product_name': productName,
          '${entryId}_unit_price': unitPrice,
          '${entryId}_amount_used': amountUsed,
          '${entryId}_dining_members': diningMembers,
          '${entryId}_price_expended': priceExpended,
          '${entryId}_price_per_member': pricePerMember,
        });

        // Log activity for edit
        final adminData = await AdminAuthService().getCurrentAdminData();
        final adminBaNo = adminData?['ba_no'] ?? '';
        final adminName = adminData?['name'] ?? 'Unknown';
        if (adminBaNo.isNotEmpty) {
          final msg =
              '$adminName edited Lunch entry on $dateStr: Product: $productName, Unit Price: $unitPrice, Amount Used: $amountUsed, Dining Members: $diningMembers, Price Expended: $priceExpended, Price Per Member: $pricePerMember.';
          await FirebaseFirestore.instance
              .collection('staff_activity_log')
              .doc(adminBaNo)
              .collection('logs')
              .add({
            'timestamp': FieldValue.serverTimestamp(),
            'actionType': 'Edit Lunch Entry',
            'message': msg,
            'admin_id': adminData?['uid'] ?? '',
            'admin_name': adminName,
            'date': dateStr,
          });
        }

        // Reload data
        await _loadMessingData();

        // Recalculate and update totals
        await _recalculateAndUpdateTotals();

        setState(() {
          editingLunchIndex = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lunch entry updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating entry: $e')),
          );
        }
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
      try {
        final entry = _dinnerEntries[index];
        final entryId = entry['id'];
        final dateStr =
            "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

        // Get values from controllers
        final productName = dinnerControllers[0].text.trim();
        final unitPrice =
            double.tryParse(dinnerControllers[1].text) ?? entry['unit_price'];
        final amountUsed =
            double.tryParse(dinnerControllers[2].text) ?? entry['amount'];
        final diningMembers =
            double.tryParse(dinnerControllers[3].text) ?? entry['members'];

        // Calculate dynamic values
        final priceExpended = unitPrice * amountUsed;
        final pricePerMember =
            diningMembers > 0 ? priceExpended / diningMembers : 0.0;

        // Update Firebase document with correct field names
        await FirebaseFirestore.instance
            .collection('messing_data')
            .doc(dateStr)
            .update({
          '${entryId}_product_name': productName,
          '${entryId}_unit_price': unitPrice,
          '${entryId}_amount_used': amountUsed,
          '${entryId}_dining_members': diningMembers,
          '${entryId}_price_expended': priceExpended,
          '${entryId}_price_per_member': pricePerMember,
        });

        // Log activity for edit
        final adminData = await AdminAuthService().getCurrentAdminData();
        final adminBaNo = adminData?['ba_no'] ?? '';
        final adminName = adminData?['name'] ?? 'Unknown';
        if (adminBaNo.isNotEmpty) {
          final msg =
              '$adminName edited Dinner entry on $dateStr: Product: $productName, Unit Price: $unitPrice, Amount Used: $amountUsed, Dining Members: $diningMembers, Price Expended: $priceExpended, Price Per Member: $pricePerMember.';
          await FirebaseFirestore.instance
              .collection('staff_activity_log')
              .doc(adminBaNo)
              .collection('logs')
              .add({
            'timestamp': FieldValue.serverTimestamp(),
            'actionType': 'Edit Dinner Entry',
            'message': msg,
            'admin_id': adminData?['uid'] ?? '',
            'admin_name': adminName,
            'date': dateStr,
          });
        }

        // Reload data
        await _loadMessingData();

        // Recalculate and update totals
        await _recalculateAndUpdateTotals();

        setState(() {
          editingDinnerIndex = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dinner entry updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating entry: $e')),
          );
        }
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
      try {
        final entry = _breakfastEntries[index];
        final entryId = entry['id'];
        final dateStr =
            "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

        // Delete specific entry fields from Firebase document
        final fieldsToDelete = {
          '${entryId}_product_name': FieldValue.delete(),
          '${entryId}_unit_price': FieldValue.delete(),
          '${entryId}_amount_used': FieldValue.delete(),
          '${entryId}_dining_members': FieldValue.delete(),
          '${entryId}_price_expended': FieldValue.delete(),
          '${entryId}_price_per_member': FieldValue.delete(),
          '${entryId}_meal_type': FieldValue.delete(),
          '${entryId}_timestamp': FieldValue.delete(),
        };

        await FirebaseFirestore.instance
            .collection('messing_data')
            .doc(dateStr)
            .update(fieldsToDelete);

        // Log activity for delete
        final adminData = await AdminAuthService().getCurrentAdminData();
        final adminBaNo = adminData?['ba_no'] ?? '';
        final adminName = adminData?['name'] ?? 'Unknown';
        if (adminBaNo.isNotEmpty) {
          final msg =
              '$adminName deleted Breakfast entry on $dateStr: Product: ${entry['product_name']}, Unit Price: ${entry['unit_price']}, Amount Used: ${entry['amount']}, Dining Members: ${entry['members']}, Price Expended: ${entry['price_expended']}, Price Per Member: ${entry['price_per_member']}.';
          await FirebaseFirestore.instance
              .collection('staff_activity_log')
              .doc(adminBaNo)
              .collection('logs')
              .add({
            'timestamp': FieldValue.serverTimestamp(),
            'actionType': 'Delete Breakfast Entry',
            'message': msg,
            'admin_id': adminData?['uid'] ?? '',
            'admin_name': adminName,
            'date': dateStr,
          });
        }

        // Reload data
        await _loadMessingData();

        // Recalculate and update totals
        await _recalculateAndUpdateTotals();

        setState(() {
          editingBreakfastIndex = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Breakfast entry deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting entry: $e')),
          );
        }
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
      try {
        final entry = _lunchEntries[index];
        final entryId = entry['id'];
        final dateStr =
            "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

        // Delete specific entry fields from Firebase document
        final fieldsToDelete = {
          '${entryId}_product_name': FieldValue.delete(),
          '${entryId}_unit_price': FieldValue.delete(),
          '${entryId}_amount_used': FieldValue.delete(),
          '${entryId}_dining_members': FieldValue.delete(),
          '${entryId}_price_expended': FieldValue.delete(),
          '${entryId}_price_per_member': FieldValue.delete(),
          '${entryId}_meal_type': FieldValue.delete(),
          '${entryId}_timestamp': FieldValue.delete(),
        };

        await FirebaseFirestore.instance
            .collection('messing_data')
            .doc(dateStr)
            .update(fieldsToDelete);

        // Log activity for delete
        final adminData = await AdminAuthService().getCurrentAdminData();
        final adminBaNo = adminData?['ba_no'] ?? '';
        final adminName = adminData?['name'] ?? 'Unknown';
        if (adminBaNo.isNotEmpty) {
          final msg =
              '$adminName deleted Lunch entry on $dateStr: Product: ${entry['product_name']}, Unit Price: ${entry['unit_price']}, Amount Used: ${entry['amount']}, Dining Members: ${entry['members']}, Price Expended: ${entry['price_expended']}, Price Per Member: ${entry['price_per_member']}.';
          await FirebaseFirestore.instance
              .collection('staff_activity_log')
              .doc(adminBaNo)
              .collection('logs')
              .add({
            'timestamp': FieldValue.serverTimestamp(),
            'actionType': 'Delete Lunch Entry',
            'message': msg,
            'admin_id': adminData?['uid'] ?? '',
            'admin_name': adminName,
            'date': dateStr,
          });
        }

        // Reload data
        await _loadMessingData();

        // Recalculate and update totals
        await _recalculateAndUpdateTotals();

        setState(() {
          editingLunchIndex = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lunch entry deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting entry: $e')),
          );
        }
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
      try {
        final entry = _dinnerEntries[index];
        final entryId = entry['id'];
        final dateStr =
            "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

        // Delete specific entry fields from Firebase document
        final fieldsToDelete = {
          '${entryId}_product_name': FieldValue.delete(),
          '${entryId}_unit_price': FieldValue.delete(),
          '${entryId}_amount_used': FieldValue.delete(),
          '${entryId}_dining_members': FieldValue.delete(),
          '${entryId}_price_expended': FieldValue.delete(),
          '${entryId}_price_per_member': FieldValue.delete(),
          '${entryId}_meal_type': FieldValue.delete(),
          '${entryId}_timestamp': FieldValue.delete(),
        };

        await FirebaseFirestore.instance
            .collection('messing_data')
            .doc(dateStr)
            .update(fieldsToDelete);

        // Log activity for delete
        final adminData = await AdminAuthService().getCurrentAdminData();
        final adminBaNo = adminData?['ba_no'] ?? '';
        final adminName = adminData?['name'] ?? 'Unknown';
        if (adminBaNo.isNotEmpty) {
          final msg =
              '$adminName deleted Dinner entry on $dateStr: Product: ${entry['product_name']}, Unit Price: ${entry['unit_price']}, Amount Used: ${entry['amount']}, Dining Members: ${entry['members']}, Price Expended: ${entry['price_expended']}, Price Per Member: ${entry['price_per_member']}.';
          await FirebaseFirestore.instance
              .collection('staff_activity_log')
              .doc(adminBaNo)
              .collection('logs')
              .add({
            'timestamp': FieldValue.serverTimestamp(),
            'actionType': 'Delete Dinner Entry',
            'message': msg,
            'admin_id': adminData?['uid'] ?? '',
            'admin_name': adminName,
            'date': dateStr,
          });
        }

        // Reload data
        await _loadMessingData();

        // Recalculate and update totals
        await _recalculateAndUpdateTotals();

        setState(() {
          editingDinnerIndex = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dinner entry deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting entry: $e')),
          );
        }
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
                        onTap: () => Navigator.pop(context),
                        selected: true,
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
              AppLocalizations.of(context)!.messing,
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
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width > 600
                              ? null
                              : (MediaQuery.of(context).size.width - 48) / 3,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddIndlEntryScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person_add,
                                color: Colors.white),
                            label: Text(
                              AppLocalizations.of(context)!.indlEntry,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A4D8F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width > 600
                              ? null
                              : (MediaQuery.of(context).size.width - 48) / 3,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddMiscEntryScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.group_add,
                                color: Colors.white),
                            label: Text(
                              AppLocalizations.of(context)!.miscEntry,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A4D8F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width > 600
                              ? null
                              : (MediaQuery.of(context).size.width - 48) / 3,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddMessingScreen(),
                                ),
                              ).then((_) => _loadMessingData());
                            },
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: Text(
                              AppLocalizations.of(context)!.create,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A4D8F),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.search,
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
                    const SizedBox(height: 16),

                    // Date selector
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            bool isNarrow = constraints.maxWidth < 400;

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!
                                            .viewingDate,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getFormattedDate(),
                                        style: const TextStyle(
                                            fontSize: 18, color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _selectDate,
                                      icon: const Icon(Icons.calendar_today),
                                      label: Text(AppLocalizations.of(context)!
                                          .changeDate),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF1A4D8F),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!
                                              .viewingDate,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _getFormattedDate(),
                                          style: const TextStyle(
                                              fontSize: 18, color: Colors.blue),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Flexible(
                                    flex: 1,
                                    child: ElevatedButton.icon(
                                      onPressed: _selectDate,
                                      icon: const Icon(Icons.calendar_today),
                                      label: Text(AppLocalizations.of(context)!
                                          .changeDate),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF1A4D8F),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
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
                      AppLocalizations.of(context)!.breakfastEntries,
                      _breakfastEntries.isNotEmpty
                          ? _breakfastEntries
                          : breakfastEntries,
                      editingBreakfastIndex,
                      breakfastControllers,
                      _editBreakfast,
                      _deleteBreakfast,
                      _saveBreakfast,
                      _cancelBreakfast,
                    ),
                    // Breakfast Summary
                    if (_breakfastEntries.isNotEmpty ||
                        breakfastEntries.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 5),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                    AppLocalizations.of(context)!
                                        .totalPriceExpended,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    '${_breakfastTotalExpended.toStringAsFixed(2)} BDT',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                    AppLocalizations.of(context)!
                                        .totalPricePerMember,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    '${_breakfastTotalPerMember.toStringAsFixed(2)} BDT',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    _buildTable(
                      AppLocalizations.of(context)!.lunchEntries,
                      _lunchEntries.isNotEmpty ? _lunchEntries : lunchEntries,
                      editingLunchIndex,
                      lunchControllers,
                      _editLunch,
                      _deleteLunch,
                      _saveLunch,
                      _cancelLunch,
                    ),
                    // Lunch Summary
                    if (_lunchEntries.isNotEmpty || lunchEntries.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 5),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                    AppLocalizations.of(context)!
                                        .totalPriceExpended,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    '${_lunchTotalExpended.toStringAsFixed(2)} BDT',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                    AppLocalizations.of(context)!
                                        .totalPricePerMember,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    '${_lunchTotalPerMember.toStringAsFixed(2)} BDT',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    _buildTable(
                      AppLocalizations.of(context)!.dinnerEntries,
                      _dinnerEntries.isNotEmpty
                          ? _dinnerEntries
                          : dinnerEntries,
                      editingDinnerIndex,
                      dinnerControllers,
                      _editDinner,
                      _deleteDinner,
                      _saveDinner,
                      _cancelDinner,
                    ),
                    // Dinner Summary
                    if (_dinnerEntries.isNotEmpty || dinnerEntries.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 5),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                    AppLocalizations.of(context)!
                                        .totalPriceExpended,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    '${_dinnerTotalExpended.toStringAsFixed(2)} BDT',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                    AppLocalizations.of(context)!
                                        .totalPricePerMember,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    '${_dinnerTotalPerMember.toStringAsFixed(2)} BDT',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

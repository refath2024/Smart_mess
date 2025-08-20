import '../../services/admin_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddIndlEntryScreen extends StatefulWidget {
  const AddIndlEntryScreen({super.key});

  @override
  State<AddIndlEntryScreen> createState() => _AddIndlEntryScreenState();
}

class _AddIndlEntryScreenState extends State<AddIndlEntryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _baNumberController = TextEditingController();
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _userData = [];
  List<Map<String, dynamic>> _filteredUserData = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _editingRowId;

  // Controllers for editing specific fields
  final Map<String, TextEditingController> _extraChitControllers = {};
  final Map<String, TextEditingController> _barChitControllers = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    // Add listeners for search functionality
    _searchController.addListener(_applyFilters);
    _baNumberController.addListener(_applyFilters);

    _loadDailyMessingData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _baNumberController.dispose();
    // Dispose all dynamic controllers
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (var controller in _extraChitControllers.values) {
      controller.dispose();
    }
    for (var controller in _barChitControllers.values) {
      controller.dispose();
    }
    _extraChitControllers.clear();
    _barChitControllers.clear();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // Reload data for the new date
      _loadDailyMessingData();
    }
  }

  void _searchData() {
    // Refresh data when search is triggered
    _loadDailyMessingData();
  }

  void _editRecord(Map<String, dynamic> record) {
    setState(() {
      _editingRowId = record['id'];
    });
  }

  Future<void> _saveRecord(Map<String, dynamic> record) async {
    if (_selectedDate == null) return;

    try {
      final dateStr = _formatDateForFirestore(_selectedDate!);
      final baNo = record['ba_number'].toString();

      // Get values from controllers with validation
      final extraChitText = _extraChitControllers[baNo]?.text ?? '0';
      final barChitText = _barChitControllers[baNo]?.text ?? '0';

      final extraChit = double.tryParse(extraChitText);
      final barChit = double.tryParse(barChitText);

      if (extraChit == null || extraChit < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid extra chit amount'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (barChit == null || barChit < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid bar chit amount'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Track changes for logging
      final List<String> changedFields = [];
      final recordIndex = _userData.indexWhere((r) => r['id'] == record['id']);
      if (recordIndex != -1) {
        if (_userData[recordIndex]['extra_chit'] != extraChit) {
          changedFields.add('extra_chit');
        }
        if (_userData[recordIndex]['bar_chit'] != barChit) {
          changedFields.add('bar_chit');
        }
        _userData[recordIndex]['extra_chit'] = extraChit;
        _userData[recordIndex]['bar_chit'] = barChit;
      }
      // Log activity if any field changed
      if (changedFields.isNotEmpty) {
        final adminData = await AdminAuthService().getCurrentAdminData();
        final adminBaNo = adminData?['ba_no'] ?? '';
        final userName = record['name'] ?? '';
        final userRank = record['rank'] ?? '';
        final baNumber = record['ba_number'] ?? '';
        final date = dateStr;
        for (final field in changedFields) {
          String itemName = field == 'extra_chit' ? 'Extra Chit' : 'Bar Chit';
          String newValue =
              field == 'extra_chit' ? extraChit.toString() : barChit.toString();
          String msg =
              'Admin ${adminData?['name'] ?? 'Unknown'} edited $itemName for user $userName (Rank: $userRank, BA: $baNumber) on $date. New value: $newValue.';
          if (adminBaNo.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('staff_activity_log')
                .doc(adminBaNo)
                .collection('logs')
                .add({
              'timestamp': FieldValue.serverTimestamp(),
              'actionType': 'Edit Individual Entry',
              'message': msg,
              'admin_id': adminData?['uid'] ?? '',
              'admin_name': adminData?['name'] ?? '',
              'user_ba_number': baNumber,
              'user_name': userName,
              'user_rank': userRank,
              'date': date,
            });
          }
        }
      }

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('daily_messing')
          .doc(dateStr)
          .set({
        baNo: {
          'extra_chit': extraChit,
          'bar': barChit,
          'updated_at': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      setState(() {
        _editingRowId = null;
      });

      _applyFilters();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDateForFirestore(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Load daily messing data for the selected date
  Future<void> _loadDailyMessingData() async {
    if (_selectedDate == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Clear existing controllers before loading new data
      _disposeControllers();

      final dateStr = _formatDateForFirestore(_selectedDate!);

      // Check if daily_messing data exists for this date
      final dailyMessingDoc = await FirebaseFirestore.instance
          .collection('daily_messing')
          .doc(dateStr)
          .get();

      if (dailyMessingDoc.exists && dailyMessingDoc.data() != null) {
        // Load existing data
        await _loadExistingDailyMessingData(dateStr, dailyMessingDoc.data()!);
      } else {
        // Generate new data for this date
        await _generateDailyMessingData(dateStr);
      }

      _applyFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading daily messing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// Load existing daily messing data from Firestore
  Future<void> _loadExistingDailyMessingData(
      String dateStr, Map<String, dynamic> data) async {
    final List<Map<String, dynamic>> loadedData = [];

    // Get all users to ensure we have complete data
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('user_requests')
        .where('approved', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .get();

    for (var userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();
      final baNo = userData['ba_no']?.toString() ?? '';

      if (baNo.isEmpty) continue;

      // Get messing data for this user (if exists)
      final userMessingData = data[baNo] as Map<String, dynamic>? ?? {};

      final record = {
        'id': userDoc.id,
        'ba_number': baNo,
        'name': userData['name'] ?? '',
        'rank': userData['rank'] ?? '',
        'meal_date': dateStr,
        'breakfast_price': userMessingData['breakfast']?.toDouble() ?? 0.0,
        'lunch_price': userMessingData['lunch']?.toDouble() ?? 0.0,
        'dinner_price': userMessingData['dinner']?.toDouble() ?? 0.0,
        'extra_chit': userMessingData['extra_chit']?.toDouble() ?? 0.0,
        'bar_chit': userMessingData['bar']?.toDouble() ?? 0.0,
      };

      loadedData.add(record);

      // Initialize controllers for editing
      _extraChitControllers[baNo] = TextEditingController(
        text: record['extra_chit'].toString(),
      );
      _barChitControllers[baNo] = TextEditingController(
        text: record['bar_chit'].toString(),
      );
    }

    setState(() {
      _userData = loadedData;
    });
  }

  /// Generate daily messing data by calculating from meal states and menu prices
  Future<void> _generateDailyMessingData(String dateStr) async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final List<Map<String, dynamic>> generatedData = [];

      // Get all active users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('user_requests')
          .where('approved', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .get();

      // Get menu prices for the selected date
      final menuDoc = await FirebaseFirestore.instance
          .collection('monthly_menu')
          .doc(dateStr)
          .get();

      final menuData = menuDoc.data();
      final breakfastPrice =
          menuData?['breakfast']?['price']?.toDouble() ?? 0.0;
      final lunchPrice = menuData?['lunch']?['price']?.toDouble() ?? 0.0;
      final dinnerPrice = menuData?['dinner']?['price']?.toDouble() ?? 0.0;

      // Get meal state data for the selected date
      final mealStateDoc = await FirebaseFirestore.instance
          .collection('user_meal_state')
          .doc(dateStr)
          .get();

      final mealStateData = mealStateDoc.data() ?? {};

      // Get existing daily messing data to preserve extra_chit and bar_chit
      final existingDailyMessingDoc = await FirebaseFirestore.instance
          .collection('daily_messing')
          .doc(dateStr)
          .get();

      final existingDailyMessingData = existingDailyMessingDoc.data() ?? {};

      // Prepare data to save to daily_messing collection
      Map<String, dynamic> dailyMessingToSave = {};

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final baNo = userData['ba_no']?.toString() ?? '';

        if (baNo.isEmpty) continue;

        // Get user's meal state for this date
        final userMealState =
            mealStateData[baNo] as Map<String, dynamic>? ?? {};

        // Calculate meal prices based on enrollment
        final userBreakfastPrice =
            (userMealState['breakfast'] == true) ? breakfastPrice : 0.0;
        final userLunchPrice =
            (userMealState['lunch'] == true) ? lunchPrice : 0.0;
        final userDinnerPrice =
            (userMealState['dinner'] == true) ? dinnerPrice : 0.0;

        // Get existing extra_chit and bar_chit values (preserve them)
        final existingUserData =
            existingDailyMessingData[baNo] as Map<String, dynamic>? ?? {};
        final existingExtraChit =
            existingUserData['extra_chit']?.toDouble() ?? 0.0;
        final existingBarChit = existingUserData['bar']?.toDouble() ?? 0.0;

        final record = {
          'id': userDoc.id,
          'ba_number': baNo,
          'name': userData['name'] ?? '',
          'rank': userData['rank'] ?? '',
          'meal_date': dateStr,
          'breakfast_price': userBreakfastPrice,
          'lunch_price': userLunchPrice,
          'dinner_price': userDinnerPrice,
          'extra_chit': existingExtraChit,
          'bar_chit': existingBarChit,
        };

        generatedData.add(record);

        // Prepare data for Firestore (preserve existing extra_chit and bar values)
        dailyMessingToSave[baNo] = {
          'breakfast': userBreakfastPrice,
          'lunch': userLunchPrice,
          'dinner': userDinnerPrice,
          'extra_chit': existingExtraChit,
          'bar': existingBarChit,
          'user_name': userData['name'] ?? '',
          'user_rank': userData['rank'] ?? '',
          'updated_at': FieldValue.serverTimestamp(),
        };

        // Initialize controllers for editing with existing values
        _extraChitControllers[baNo] =
            TextEditingController(text: existingExtraChit.toString());
        _barChitControllers[baNo] =
            TextEditingController(text: existingBarChit.toString());
      }

      // Save to daily_messing collection
      await FirebaseFirestore.instance
          .collection('daily_messing')
          .doc(dateStr)
          .set(dailyMessingToSave);

      setState(() {
        _userData = generatedData;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily messing data generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating daily messing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isRefreshing = false;
    });
  }

  /// Apply search and filter logic
  void _applyFilters() {
    setState(() {
      _filteredUserData = _userData.where((record) {
        final searchQuery = _searchController.text.toLowerCase();
        final baQuery = _baNumberController.text.toLowerCase();

        final matchesSearch = searchQuery.isEmpty ||
            record['name'].toString().toLowerCase().contains(searchQuery) ||
            record['rank'].toString().toLowerCase().contains(searchQuery);

        final matchesBaNo = baQuery.isEmpty ||
            record['ba_number'].toString().toLowerCase().contains(baQuery);

        return matchesSearch && matchesBaNo;
      }).toList();
    });
  }

  /// Refresh/Regenerate daily messing data
  Future<void> _refreshDailyMessingData() async {
    if (_selectedDate == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Refresh Daily Messing Data'),
          content: const Text(
              'This will regenerate the daily messing data based on current meal states and menu prices.\n\n'
              'Note: Extra chit and bar amounts will be preserved.\n\n'
              'Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Refresh'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final dateStr = _formatDateForFirestore(_selectedDate!);
      await _generateDailyMessingData(dateStr);
      _applyFilters();
    }
  }

  void _cancelEdit() {
    setState(() {
      _editingRowId = null;
    });

    // Reset controllers to original values
    for (var record in _userData) {
      final baNo = record['ba_number'].toString();
      if (_extraChitControllers.containsKey(baNo)) {
        _extraChitControllers[baNo]!.text = record['extra_chit'].toString();
      }
      if (_barChitControllers.containsKey(baNo)) {
        _barChitControllers[baNo]!.text = record['bar_chit'].toString();
      }
    }
  }

  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
              'Are you sure you want to delete the record for ${record['name']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _userData.removeWhere((item) => item['id'] == record['id']);
      });
      // TODO: Implement API call to delete record
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Individual Meal Entry',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Fields
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _baNumberController,
                        decoration: InputDecoration(
                          labelText: 'BA Number',
                          hintText: 'Enter BA Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.person_search),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search',
                          hintText: 'Search anything...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _selectedDate == null
                                ? 'Select Date'
                                : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _searchData,
                              icon: const Icon(Icons.search),
                              label: const Text('Search'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A4D8F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isRefreshing
                                  ? null
                                  : _refreshDailyMessingData,
                              icon: _isRefreshing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh),
                              label: Text(
                                  _isRefreshing ? 'Refreshing...' : 'Refresh'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Results Table
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_userData.isNotEmpty)
                Card(
                  elevation: 4,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFF002B5B).withValues(alpha: 0.1),
                      ),
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF002B5B),
                        fontSize: 14,
                      ),
                      columns: const [
                        DataColumn(label: Text('BA Number')),
                        DataColumn(label: Text('Rank')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Breakfast\nPrice')),
                        DataColumn(label: Text('Lunch\nPrice')),
                        DataColumn(label: Text('Dinner\nPrice')),
                        DataColumn(label: Text('Extra\nChit')),
                        DataColumn(label: Text('Bar\nChit')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _filteredUserData.map((record) {
                        final isEditing = _editingRowId == record['id'];
                        return DataRow(
                          color: isEditing
                              ? WidgetStateProperty.all(
                                  Colors.blue.withValues(alpha: 0.1))
                              : null,
                          cells: [
                            DataCell(Text(record['ba_number'].toString())),
                            DataCell(Text(record['rank'])),
                            DataCell(Text(record['name'])),
                            DataCell(Text(record['meal_date'])),
                            DataCell(Text(
                                'BDT ${record['breakfast_price'].toStringAsFixed(2)}')),
                            DataCell(Text(
                                'BDT ${record['lunch_price'].toStringAsFixed(2)}')),
                            DataCell(Text(
                                'BDT ${record['dinner_price'].toStringAsFixed(2)}')),
                            DataCell(
                              isEditing
                                  ? SizedBox(
                                      width: 100,
                                      child: TextFormField(
                                        controller: _extraChitControllers[
                                            record['ba_number']],
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.all(8),
                                          border: OutlineInputBorder(),
                                          hintText: '0.00',
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'BDT ${record['extra_chit'].toStringAsFixed(2)}'),
                            ),
                            DataCell(
                              isEditing
                                  ? SizedBox(
                                      width: 100,
                                      child: TextFormField(
                                        controller: _barChitControllers[
                                            record['ba_number']],
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.all(8),
                                          border: OutlineInputBorder(),
                                          hintText: '0.00',
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'BDT ${record['bar_chit'].toStringAsFixed(2)}'),
                            ),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isEditing) ...[
                                  IconButton(
                                    icon: const Icon(Icons.save),
                                    onPressed: () => _saveRecord(record),
                                    color: Colors.green,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel),
                                    onPressed: _cancelEdit,
                                    color: Colors.grey,
                                  ),
                                ] else ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editRecord(record),
                                    color: Colors.blue,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteRecord(record),
                                    color: Colors.red,
                                  ),
                                ],
                              ],
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

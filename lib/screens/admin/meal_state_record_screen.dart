import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../services/admin_auth_service.dart';

class MealStateRecordScreen extends StatefulWidget {
  const MealStateRecordScreen({super.key});

  @override
  State<MealStateRecordScreen> createState() => _MealStateRecordScreenState();
}

class _MealStateRecordScreenState extends State<MealStateRecordScreen> {
  final AdminAuthService _adminAuthService = AdminAuthService();
  Map<String, dynamic>? _currentUserData;

  // (removed duplicate _fetchCurrentAdminData)
  final TextEditingController _searchController = TextEditingController();
  DateTime? selectedDate = DateTime.now();
  List<Map<String, dynamic>> filteredRecords = [];
  List<Map<String, dynamic>> allRecords = [];
  int? editingIndex;
  bool _isLoading = false;

  // Controllers for editing
  final TextEditingController _breakfastController = TextEditingController();
  final TextEditingController _lunchController = TextEditingController();
  final TextEditingController _dinnerController = TextEditingController();
  final TextEditingController _disposalTypeController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  DateTime? _disposalFromDate;
  DateTime? _disposalToDate;

  void _fetchCurrentAdminData() async {
    final data = await _adminAuthService.getCurrentAdminData();
    if (mounted) {
      setState(() {
        _currentUserData = data;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCurrentAdminData();
    _fetchAllMealRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _breakfastController.dispose();
    _lunchController.dispose();
    _dinnerController.dispose();
    _disposalTypeController.dispose();
    _remarksController.dispose();
    super.dispose();
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

  Future<void> _showCreateMealStateDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateMealStateDialog(
          onMealStateCreated: () {
            _fetchAllMealRecords(); // Refresh data after creation
          },
        );
      },
    );
  }

  Future<void> _fetchAllMealRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      allRecords.clear();

      // Fetch user details from both user_requests and deleted_user_details
      final userSnapshot = await FirebaseFirestore.instance
          .collection('user_requests')
          .where('approved', isEqualTo: true)
          .get();
      final deletedUserSnapshot = await FirebaseFirestore.instance
          .collection('deleted_user_details')
          .get();

      Map<String, Map<String, dynamic>> userDataMap = {};
      for (var doc in userSnapshot.docs) {
        final userData = doc.data();
        final baNo = userData['ba_no']?.toString();
        if (baNo != null) {
          userDataMap[baNo] = userData;
        }
      }
      for (var doc in deletedUserSnapshot.docs) {
        final userData = doc.data();
        final baNo = userData['ba_no']?.toString() ?? doc.id;
        if (!userDataMap.containsKey(baNo)) {
          userDataMap[baNo] = userData;
        }
      }

      // Get all meal state documents without ordering (to avoid index requirement)
      final querySnapshot =
          await FirebaseFirestore.instance.collection('user_meal_state').get();

      for (var doc in querySnapshot.docs) {
        final dateStr = doc.id;
        final data = doc.data();

        for (String baNo in data.keys) {
          final userData = data[baNo] as Map<String, dynamic>;
          final userDetails = userDataMap[baNo];

          // Format disposal information
          String disposalInfo = 'N/A';
          String disposalFromTo = '';

          if (userData['disposal'] == true &&
              userData['disposal_type'] != null &&
              userData['disposal_type'].toString().isNotEmpty) {
            disposalInfo = userData['disposal_type'].toString();
            if (userData['disposal_from'] != null &&
                userData['disposal_to'] != null &&
                userData['disposal_from'].toString().isNotEmpty &&
                userData['disposal_to'].toString().isNotEmpty) {
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
          String remarks = userData['remarks']?.toString() ?? '';
          if (remarks.trim().isEmpty) {
            remarks = 'N/A';
          }

          allRecords.add({
            'BA No': baNo,
            'Rk': userDetails?['rank'] ?? userData['rank'] ?? '',
            'Name': userDetails?['name'] ?? userData['name'] ?? '',
            'Date': dateStr,
            'Breakfast': userData['breakfast'] == true ? 'Yes' : 'No',
            'Lunch': userData['lunch'] == true ? 'Yes' : 'No',
            'Dinner': userData['dinner'] == true ? 'Yes' : 'No',
            'Disposals': disposalInfo,
            'Disposal Dates': disposalFromTo,
            'Remarks': remarks,
            'Admin Generated': userData['admin_generated'] == true,
            'original_data': userData, // Keep original for editing
          });
        }
      }

      // Sort records by date in descending order (most recent first)
      allRecords
          .sort((a, b) => b['Date'].toString().compareTo(a['Date'].toString()));

      _filterRecords(_searchController.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching meal records: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _startEditing(int index, Map<String, dynamic> record) {
    setState(() {
      editingIndex = index;
      _breakfastController.text = record['Breakfast'];
      _lunchController.text = record['Lunch'];
      _dinnerController.text = record['Dinner'];
      _disposalTypeController.text = record['Disposals'];
      _remarksController.text =
          record['Remarks'] == 'N/A' ? '' : record['Remarks'];

      // Parse disposal dates
      if (record['Disposal Dates'].toString().isNotEmpty &&
          record['Disposal Dates'] != '') {
        final dates = record['Disposal Dates'].toString().split(' - ');
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
        _isLoading = true;
      });

      try {
        final record = filteredRecords[index];
        final dateStr = record['Date'];
        final baNo = record['BA No'];

        // Old values
        final oldBreakfast = record['Breakfast'];
        final oldLunch = record['Lunch'];
        final oldDinner = record['Dinner'];
        final oldDisposalType = record['Disposals'];
        final oldRemarks = record['Remarks'];
        final oldDisposalDates = record['Disposal Dates'];

        // New values
        final newBreakfast = _breakfastController.text;
        final newLunch = _lunchController.text;
        final newDinner = _dinnerController.text;
        final newDisposalType = _disposalTypeController.text;
        String finalRemarks = _remarksController.text.trim();
        if (finalRemarks.isEmpty ||
            finalRemarks.toLowerCase() == 'n/a' ||
            finalRemarks.toLowerCase() == 'na') {
          finalRemarks = '';
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
        String newDisposalDates = '';
        if (disposalFrom.isNotEmpty && disposalTo.isNotEmpty) {
          newDisposalDates = '$disposalFrom - $disposalTo';
        }

        // Update Firebase
        await FirebaseFirestore.instance
            .collection('user_meal_state')
            .doc(dateStr)
            .update({
          '$baNo.breakfast': newBreakfast == 'Yes',
          '$baNo.lunch': newLunch == 'Yes',
          '$baNo.dinner': newDinner == 'Yes',
          '$baNo.disposal': newDisposalType != 'N/A',
          '$baNo.disposal_type':
              newDisposalType == 'N/A' ? '' : newDisposalType,
          '$baNo.disposal_from': disposalFrom,
          '$baNo.disposal_to': disposalTo,
          '$baNo.remarks': finalRemarks,
          '$baNo.timestamp': FieldValue.serverTimestamp(),
          '$baNo.admin_generated': false, // Mark as manually edited
        });

        // Build change details
        List<String> changes = [];
        if (oldBreakfast != newBreakfast) {
          changes.add('Breakfast: $oldBreakfast → $newBreakfast');
        }
        if (oldLunch != newLunch) {
          changes.add('Lunch: $oldLunch → $newLunch');
        }
        if (oldDinner != newDinner) {
          changes.add('Dinner: $oldDinner → $newDinner');
        }
        if (oldDisposalType != newDisposalType) {
          changes.add('Disposal Type: $oldDisposalType → $newDisposalType');
        }
        if (oldRemarks != finalRemarks) {
          changes.add('Remarks: $oldRemarks → $finalRemarks');
        }
        if (oldDisposalDates != newDisposalDates) {
          changes.add('Disposal Dates: $oldDisposalDates → $newDisposalDates');
        }

        // Log activity for edit
        final adminName = _currentUserData?['name'] ?? 'Admin';
        final adminBaNo = _currentUserData?['ba_no'] ?? '';
        if (adminBaNo.isNotEmpty) {
          final details = 'Meal state edited for $baNo on $dateStr. ' +
              (changes.isNotEmpty
                  ? 'Changes: ' + changes.join('; ')
                  : 'No field changed.');
          await FirebaseFirestore.instance
              .collection('staff_activity_log')
              .doc(adminBaNo)
              .collection('logs')
              .add({
            'timestamp': FieldValue.serverTimestamp(),
            'actionType': 'Edit Meal State',
            'message': '$adminName edited meal state. $details',
            'name': adminName,
          });
        }

        // Refresh data
        await _fetchAllMealRecords();

        setState(() {
          editingIndex = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Record updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating record: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _cancelEditing() {
    if (!mounted) return;
    setState(() {
      editingIndex = null;
      _disposalFromDate = null;
      _disposalToDate = null;
      // Clear all controllers
      _breakfastController.clear();
      _lunchController.clear();
      _dinnerController.clear();
      _disposalTypeController.clear();
      _remarksController.clear();
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
        _isLoading = true;
      });

      try {
        final record = filteredRecords[index];
        final dateStr = record['Date'];
        final baNo = record['BA No'];

        // Delete from Firebase
        await FirebaseFirestore.instance
            .collection('user_meal_state')
            .doc(dateStr)
            .update({
          baNo: FieldValue.delete(),
        });

        // Log activity for delete
        final adminName = _currentUserData?['name'] ?? 'Admin';
        final adminBaNo = _currentUserData?['ba_no'] ?? '';
        if (adminBaNo.isNotEmpty) {
          final details = 'Meal state deleted for $baNo on $dateStr';
          await FirebaseFirestore.instance
              .collection('staff_activity_log')
              .doc(adminBaNo)
              .collection('logs')
              .add({
            'timestamp': FieldValue.serverTimestamp(),
            'actionType': 'Delete Meal State',
            'message': '$adminName deleted meal state. $details',
            'name': adminName,
          });
        }

        // Refresh data
        await _fetchAllMealRecords();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Record deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting record: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterRecords(String query) {
    setState(() {
      filteredRecords = allRecords.where((record) {
        // Check if the record matches the search query
        final matchesQuery = record.values.any((value) =>
            value.toString().toLowerCase().contains(query.toLowerCase()));

        // If no date is selected, only filter by query
        if (selectedDate == null) {
          return matchesQuery;
        }

        // If date is selected, filter by both query and date
        final date = _formatDateForFirestore(selectedDate!);
        final matchesDate = record['Date'] == date;

        return matchesQuery && matchesDate;
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _filterRecords(_searchController.text);
      });
    }
  }

  Future<void> _pickDisposalDate({required bool isFrom}) async {
    if (!mounted) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_disposalFromDate ?? selectedDate ?? DateTime.now())
          : (_disposalToDate ?? selectedDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _disposalFromDate = picked;
          // If to date is before from date, clear it
          if (_disposalToDate != null && _disposalToDate!.isBefore(picked)) {
            _disposalToDate = null;
          }
        } else {
          // Validate that to date is not before from date
          if (_disposalFromDate != null &&
              picked.isBefore(_disposalFromDate!)) {
            // Show warning and don't set the date
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('To date cannot be before from date'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          _disposalToDate = picked;
        }
      });
    }
  }

  // Summary calculation functions
  int get totalRecords => filteredRecords.length;

  int get adminGeneratedCount => filteredRecords
      .where((record) => record['Admin Generated'] == true)
      .length;

  int get userSubmittedCount => filteredRecords
      .where((record) => record['Admin Generated'] != true)
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Meal State Records",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _fetchAllMealRecords,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top controls row
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterRecords,
                    decoration: InputDecoration(
                      hintText: 'Search records...',
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
                SizedBox(
                  width: 200,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedDate != null
                                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                        : 'All Dates',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.calendar_today, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (selectedDate != null) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            setState(() {
                              selectedDate = null;
                              _filterRecords(_searchController.text);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.clear, size: 18),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _showCreateMealStateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Meal State'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A4D8F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Data table section
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          dataRowMinHeight: 60,
                          dataRowMaxHeight: editingIndex != null ? 200 : 60,
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFF1A4D8F),
                          ),
                          columns: const [
                            DataColumn(
                              label: Text('BA No',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Rk',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Name',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Date',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Breakfast',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Lunch',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Dinner',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Disposals',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Disposal Dates',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Remarks',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Action',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                          rows: filteredRecords.isEmpty
                              ? [
                                  const DataRow(
                                    cells: [
                                      DataCell(Text('No records found')),
                                      DataCell(Text('-')),
                                      DataCell(Text('-')),
                                      DataCell(Text('-')),
                                      DataCell(Text('-')),
                                      DataCell(Text('-')),
                                      DataCell(Text('-')),
                                      DataCell(Text('-')),
                                      DataCell(Text('-')),
                                      DataCell(Text('-')),
                                      DataCell(Text('-')),
                                    ],
                                  ),
                                ]
                              : List.generate(filteredRecords.length, (index) {
                                  final record = filteredRecords[index];
                                  final isEditing = editingIndex == index;
                                  final isAdminGenerated =
                                      record['Admin Generated'] == true;

                                  return DataRow(
                                    color: WidgetStateProperty.all(
                                      isAdminGenerated
                                          ? Colors.blue.shade50
                                          : Colors.green.shade50,
                                    ),
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            Text(record['BA No'].toString()),
                                            if (isAdminGenerated) ...[
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.admin_panel_settings,
                                                size: 16,
                                                color: Colors.blue,
                                              ),
                                            ] else ...[
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.person,
                                                size: 16,
                                                color: Colors.green,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      DataCell(Text(record['Rk'].toString())),
                                      DataCell(Text(record['Name'].toString())),
                                      DataCell(Text(record['Date'].toString())),
                                      // Breakfast cell
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
                                            : Text(
                                                record['Breakfast'].toString()),
                                      ),
                                      // Lunch cell
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
                                            : Text(record['Lunch'].toString()),
                                      ),
                                      // Dinner cell
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
                                            : Text(record['Dinner'].toString()),
                                      ),
                                      // Disposal type cell
                                      DataCell(
                                        isEditing
                                            ? DropdownButton<String>(
                                                value: _disposalTypeController
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
                                                  if (mounted) {
                                                    setState(() {
                                                      _disposalTypeController
                                                          .text = value!;
                                                      // Clear disposal dates when changing type
                                                      if (value == 'N/A') {
                                                        _disposalFromDate =
                                                            null;
                                                        _disposalToDate = null;
                                                      }
                                                    });
                                                  }
                                                },
                                              )
                                            : Text(
                                                record['Disposals'].toString()),
                                      ),
                                      // Disposal dates cell
                                      DataCell(
                                        isEditing
                                            ? Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: InkWell(
                                                          onTap: () =>
                                                              _pickDisposalDate(
                                                                  isFrom: true),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8),
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
                                                                  ? '${_disposalFromDate!.day}/${_disposalFromDate!.month}/${_disposalFromDate!.year}'
                                                                  : 'From',
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          12),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: InkWell(
                                                          onTap: () =>
                                                              _pickDisposalDate(
                                                                  isFrom:
                                                                      false),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8),
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
                                                                  ? '${_disposalToDate!.day}/${_disposalToDate!.month}/${_disposalToDate!.year}'
                                                                  : 'To',
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          12),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              )
                                            : Text(
                                                record['Disposal Dates']
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                      ),
                                      // Remarks cell
                                      DataCell(
                                        isEditing
                                            ? TextField(
                                                controller: _remarksController,
                                                decoration:
                                                    const InputDecoration(
                                                  hintText: 'Enter remarks',
                                                  border: OutlineInputBorder(),
                                                  contentPadding:
                                                      EdgeInsets.all(8),
                                                ),
                                                maxLines: 2,
                                              )
                                            : Text(
                                                record['Remarks'].toString()),
                                      ),
                                      // Action cell
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isEditing) ...[
                                              IconButton(
                                                icon: const Icon(Icons.save,
                                                    color: Colors.green),
                                                onPressed: () =>
                                                    _saveEditing(index),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.cancel,
                                                    color: Colors.red),
                                                onPressed: _cancelEditing,
                                              ),
                                            ] else ...[
                                              IconButton(
                                                icon: const Icon(Icons.edit,
                                                    color: Color(0xFF1A4D8F)),
                                                onPressed: () => _startEditing(
                                                    index, record),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    _deleteRecord(index),
                                              ),
                                            ],
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

            // Summary section
            SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Records Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total Records: $totalRecords',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Admin Generated: $adminGeneratedCount',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'User Submitted: $userSubmittedCount',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateMealStateDialog extends StatefulWidget {
  final VoidCallback onMealStateCreated;

  const CreateMealStateDialog({
    super.key,
    required this.onMealStateCreated,
  });

  @override
  State<CreateMealStateDialog> createState() => _CreateMealStateDialogState();
}

class _CreateMealStateDialogState extends State<CreateMealStateDialog> {
  DateTime selectedDate = DateTime.now();
  String? selectedUserId;
  Map<String, dynamic>? selectedUser;
  List<Map<String, dynamic>> availableUsers = [];
  bool isLoading = false;
  bool isLoadingUsers = true;
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableUsers();
  }

  String _formatDateForFirestore(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadAvailableUsers() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('user_requests')
          .where('approved', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .get();

      availableUsers = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'ba_no': data['ba_no'] ?? '',
          'name': data['name'] ?? '',
          'rank': data['rank'] ?? '',
        };
      }).toList();

      // Sort by BA number
      availableUsers.sort((a, b) => a['ba_no'].compareTo(b['ba_no']));
      filteredUsers = List.from(availableUsers);

      setState(() {
        isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        isLoadingUsers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = List.from(availableUsers);
      } else {
        filteredUsers = availableUsers.where((user) {
          final baNo = user['ba_no'].toString().toLowerCase();
          final name = user['name'].toString().toLowerCase();
          final rank = user['rank'].toString().toLowerCase();
          final searchQuery = query.toLowerCase();
          return baNo.contains(searchQuery) ||
              name.contains(searchQuery) ||
              rank.contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _createMealState() async {
    if (selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final dateStr = _formatDateForFirestore(selectedDate);
      final baNo = selectedUser!['ba_no'];

      // Check if meal state already exists for this user on this date
      final existingDoc = await FirebaseFirestore.instance
          .collection('user_meal_state')
          .doc(dateStr)
          .get();

      if (existingDoc.exists) {
        final data = existingDoc.data() as Map<String, dynamic>;
        if (data.containsKey(baNo)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Meal state already exists for this user on this date'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() {
            isLoading = false;
          });
          return;
        }
      }

      // Navigate to detailed meal entry screen
      if (mounted) {
        Navigator.of(context).pop(); // Close current dialog

        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetailedMealEntryScreen(
              selectedUser: selectedUser!,
              selectedDate: selectedDate,
              dateStr: dateStr,
            ),
          ),
        );

        if (result == true) {
          widget.onMealStateCreated();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking existing data: $e')),
        );
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Meal State'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Picker
              const Text('Date:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() {
                      selectedDate = date;
                    });
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(_formatDateForFirestore(selectedDate)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // User Selection
              const Text('Select User:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Search field
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by BA No, Name, or Rank',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _filterUsers,
              ),
              const SizedBox(height: 8),

              // User dropdown
              Container(
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isLoadingUsers
                    ? const Center(child: CircularProgressIndicator())
                    : filteredUsers.isEmpty
                        ? const Center(child: Text('No users found'))
                        : ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              final isSelected =
                                  selectedUser?['id'] == user['id'];
                              return ListTile(
                                selected: isSelected,
                                onTap: () {
                                  setState(() {
                                    selectedUser = user;
                                    selectedUserId = user['id'];
                                  });
                                },
                                title: Text(
                                  '${user['ba_no']} - ${user['name']}',
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(user['rank']),
                                trailing: isSelected
                                    ? const Icon(Icons.check,
                                        color: Colors.green)
                                    : null,
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _createMealState,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A4D8F),
            foregroundColor: Colors.white,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

class DetailedMealEntryScreen extends StatefulWidget {
  final Map<String, dynamic> selectedUser;
  final DateTime selectedDate;
  final String dateStr;

  const DetailedMealEntryScreen({
    super.key,
    required this.selectedUser,
    required this.selectedDate,
    required this.dateStr,
  });

  @override
  State<DetailedMealEntryScreen> createState() =>
      _DetailedMealEntryScreenState();
}

class _DetailedMealEntryScreenState extends State<DetailedMealEntryScreen> {
  Future<Map<String, dynamic>?> _getCurrentAdminData() async {
    final adminAuthService = AdminAuthService();
    return await adminAuthService.getCurrentAdminData();
  }

  // Meal selections
  bool breakfastSelected = false;
  bool lunchSelected = false;
  bool dinnerSelected = false;

  // Auto Loop variables
  bool _autoLoopEnabled = false;
  bool _isLoadingAutoLoop = false;
  bool _manualOverrideMode =
      false; // New: Track if admin is making a manual override

  // Disposal information
  bool disposalEnabled = false;
  String disposalType = 'SIQ';
  DateTime? disposalFromDate;
  DateTime? disposalToDate;

  // Remarks
  final TextEditingController remarksController = TextEditingController();

  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAutoLoopSettings();
  }

  Future<void> _loadAutoLoopSettings() async {
    try {
      final baNo = widget.selectedUser['ba_no'];
      final autoLoopDoc = await FirebaseFirestore.instance
          .collection('user_auto_loop')
          .doc(baNo)
          .get();

      if (autoLoopDoc.exists) {
        final loopData = autoLoopDoc.data() as Map<String, dynamic>;
        setState(() {
          _autoLoopEnabled = loopData['enabled'] ?? false;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _toggleAutoLoop(bool enabled) async {
    // If Auto Loop is currently enabled and admin toggles it off,
    // show options: Manual Override or Permanent Disable
    if (_autoLoopEnabled && !enabled) {
      final choice = await _showAutoLoopDisableOptions();

      if (choice == 'manual_override') {
        setState(() {
          _manualOverrideMode = true;
          _autoLoopEnabled =
              false; // Visually show as off, but don't update database
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Manual Override Mode: Submit different meals for today only. User\'s Auto Loop continues tomorrow.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 4),
          ),
        );
      } else if (choice == 'permanent_disable') {
        await _permanentlyDisableAutoLoop();
      }
      // If choice is null (user cancelled), do nothing
      return;
    }

    setState(() {
      _isLoadingAutoLoop = true;
    });

    try {
      if (enabled) {
        // Exit manual override mode and enable auto loop normally
        setState(() {
          _manualOverrideMode = false;
          _autoLoopEnabled = true;
        });

        // Note: If this is re-enabling a loop, it will be handled in submit function
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Auto Loop mode activated. Submit to create/update user\'s loop pattern.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error toggling auto loop: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoadingAutoLoop = false;
    });
  }

  Future<String?> _showAutoLoopDisableOptions() async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Auto Loop Options',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A4D8F),
            ),
          ),
          content: Text(
            'What would you like to do for ${widget.selectedUser['name']}?\n\n'
            '• Manual Override: Submit different meals for today only, Auto Loop continues tomorrow\n\n'
            '• Disable Auto Loop: Permanently stop the automatic meal enrollment',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('manual_override'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Manual Override'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('permanent_disable'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Disable Auto Loop'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _permanentlyDisableAutoLoop() async {
    setState(() {
      _isLoadingAutoLoop = true;
    });

    try {
      final baNo = widget.selectedUser['ba_no'];

      // Permanently disable auto loop in database
      await FirebaseFirestore.instance
          .collection('user_auto_loop')
          .doc(baNo)
          .set({
        'enabled': false,
        'updated_at': FieldValue.serverTimestamp(),
        'user_id': widget.selectedUser['id'],
        'ba_no': baNo,
        'name': widget.selectedUser['name'],
        'rank': widget.selectedUser['rank'],
        'admin_created': true,
      }, SetOptions(merge: true));

      setState(() {
        _autoLoopEnabled = false;
        _manualOverrideMode = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Auto Loop disabled permanently for ${widget.selectedUser['name']}. You can re-enable it anytime.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error disabling auto loop: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoadingAutoLoop = false;
    });
  }

  String _formatDateForFirestore(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatDisplayDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _pickDisposalDate({required bool isFrom}) async {
    if (!mounted) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (disposalFromDate ?? DateTime.now())
          : (disposalToDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          disposalFromDate = picked;
          // If to date is before from date, clear it
          if (disposalToDate != null && disposalToDate!.isBefore(picked)) {
            disposalToDate = null;
          }
        } else {
          // Validate that to date is not before from date
          if (disposalFromDate != null && picked.isBefore(disposalFromDate!)) {
            // Show warning and don't set the date
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('To date cannot be before from date'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          disposalToDate = picked;
        }
      });
    }
  }

  Future<void> _submitMealState() async {
    if (!mounted) return;

    // Check if any meal is selected - but allow Auto Loop with no meals
    if (!breakfastSelected &&
        !lunchSelected &&
        !dinnerSelected &&
        !_autoLoopEnabled &&
        !_manualOverrideMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please select at least one meal or enable Auto Loop for no-meal pattern'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Handle manual override mode - submit for today only
    if (_manualOverrideMode) {
      await _submitManualOverride();
      return;
    }

    // If auto loop is enabled, handle it differently
    if (_autoLoopEnabled) {
      await _submitAutoLoop();
    } else {
      await _submitRegular();
    }
  }

  Future<void> _submitManualOverride() async {
    final adminData = await _getCurrentAdminData();
    setState(() {
      isSubmitting = true;
    });

    try {
      final baNo = widget.selectedUser['ba_no'];
      final userName = widget.selectedUser['name'];
      final userRank = widget.selectedUser['rank'];

      // Submit only for the selected date (manual override for today)
      final mealStateData = {
        'name': userName,
        'rank': userRank,
        'breakfast': breakfastSelected,
        'lunch': lunchSelected,
        'dinner': dinnerSelected,
        'remarks': remarksController.text.trim(),
        'disposal': disposalEnabled,
        'disposal_type': disposalEnabled ? disposalType : '',
        'disposal_from': disposalEnabled && disposalFromDate != null
            ? _formatDateForFirestore(disposalFromDate!)
            : '',
        'disposal_to': disposalEnabled && disposalToDate != null
            ? _formatDateForFirestore(disposalToDate!)
            : '',
        'timestamp': FieldValue.serverTimestamp(),
        'admin_generated': true,
        'auto_loop_generated': false,
        'manual_override': true, // Mark as manual override
      };

      // Activity log for create (manual override)
      if (adminData != null && adminData['ba_no'] != null) {
        final adminName = adminData['name'] ?? 'Admin';
        final adminBaNo = adminData['ba_no'] ?? '';
        final details =
            'Created meal state for $userName ($baNo) on ${widget.dateStr}. '
            'Breakfast: ${breakfastSelected ? 'Yes' : 'No'}, '
            'Lunch: ${lunchSelected ? 'Yes' : 'No'}, '
            'Dinner: ${dinnerSelected ? 'Yes' : 'No'}, '
            'Disposal: ${disposalEnabled ? disposalType : 'N/A'}, '
            'Disposal Dates: '
            '${disposalFromDate != null ? _formatDateForFirestore(disposalFromDate!) : 'N/A'} - '
            '${disposalToDate != null ? _formatDateForFirestore(disposalToDate!) : 'N/A'}, '
            'Remarks: ${remarksController.text.trim().isEmpty ? 'N/A' : remarksController.text.trim()}';
        await FirebaseFirestore.instance
            .collection('staff_activity_log')
            .doc(adminBaNo)
            .collection('logs')
            .add({
          'timestamp': FieldValue.serverTimestamp(),
          'actionType': 'Create Meal State',
          'message': '$adminName created meal state. $details',
          'name': adminName,
        });
      }

      print('DEBUG: Starting Firestore operation for Manual Override');
      print('DEBUG: dateStr = ${widget.dateStr}');
      print('DEBUG: baNo = $baNo');
      print('DEBUG: mealStateData = $mealStateData');

      await FirebaseFirestore.instance
          .collection('user_meal_state')
          .doc(widget.dateStr)
          .set({
        baNo: mealStateData,
      }, SetOptions(merge: true)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
              'Firestore operation timed out after 30 seconds');
        },
      );

      print(
          'DEBUG: Manual Override Firestore operation completed successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Manual Override: Meals updated for ${widget.selectedUser['name']} on ${widget.dateStr}.\n'
                'Auto Loop will continue tomorrow with the original pattern.'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 4),
          ),
        );

        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting manual override: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      isSubmitting = false;
    });
  }

  Future<void> _submitAutoLoop() async {
    final adminData = await _getCurrentAdminData();
    // Validate disposal dates if disposal is enabled
    if (disposalEnabled &&
        (disposalFromDate == null ||
            disposalToDate == null ||
            disposalFromDate!.isAfter(disposalToDate!))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select valid disposal dates'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Validate dateStr before proceeding
      if (widget.dateStr.isEmpty) {
        throw Exception('Date string is empty');
      }

      // Validate dateStr format (should be YYYY-MM-DD)
      final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      if (!dateRegex.hasMatch(widget.dateStr)) {
        throw Exception(
            'Invalid date format: ${widget.dateStr}. Expected YYYY-MM-DD');
      }

      final baNo = widget.selectedUser['ba_no'];
      final userName = widget.selectedUser['name'];
      final userRank = widget.selectedUser['rank'];
      final userId = widget.selectedUser['id'];

      // Validate required data
      if (baNo == null || baNo.toString().isEmpty) {
        throw Exception('BA number is missing or empty');
      }
      if (userName == null || userName.toString().isEmpty) {
        throw Exception('User name is missing or empty');
      }

      print('DEBUG: Starting Auto Loop submission');
      print('DEBUG: dateStr = ${widget.dateStr}');
      print('DEBUG: baNo = $baNo');
      print('DEBUG: userName = $userName');
      print('DEBUG: userId = $userId');

      // Prepare meal pattern for auto loop
      final mealPattern = {
        'breakfast': breakfastSelected,
        'lunch': lunchSelected,
        'dinner': dinnerSelected,
      };

      print('DEBUG: mealPattern = $mealPattern');

      // First, save auto loop settings
      print('DEBUG: Saving auto loop settings...');
      await FirebaseFirestore.instance
          .collection('user_auto_loop')
          .doc(baNo.toString())
          .set({
        'enabled': true,
        'user_id': userId,
        'ba_no': baNo,
        'name': userName,
        'rank': userRank,
        'meal_pattern': mealPattern,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'admin_created': true,
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
              'Auto Loop settings save timed out after 15 seconds');
        },
      );

      print('DEBUG: Auto loop settings saved successfully');

      // Submit for the selected date with disposal and remarks if provided
      final mealStateData = {
        'name': userName,
        'rank': userRank,
        'breakfast': breakfastSelected,
        'lunch': lunchSelected,
        'dinner': dinnerSelected,
        'remarks': remarksController.text.trim(),
        'disposal': disposalEnabled,
        'disposal_type': disposalEnabled ? disposalType : '',
        'disposal_from': disposalEnabled && disposalFromDate != null
            ? _formatDateForFirestore(disposalFromDate!)
            : '',
        'disposal_to': disposalEnabled && disposalToDate != null
            ? _formatDateForFirestore(disposalToDate!)
            : '',
        'timestamp': FieldValue.serverTimestamp(),
        'admin_generated': true,
        'auto_loop_generated': false,
      };

      // Activity log for create (auto loop)
      if (adminData != null && adminData['ba_no'] != null) {
        final adminName = adminData['name'] ?? 'Admin';
        final adminBaNo = adminData['ba_no'] ?? '';
        final details =
            'Created meal state (Auto Loop) for $userName ($baNo) on ${widget.dateStr}. '
            'Breakfast: ${breakfastSelected ? 'Yes' : 'No'}, '
            'Lunch: ${lunchSelected ? 'Yes' : 'No'}, '
            'Dinner: ${dinnerSelected ? 'Yes' : 'No'}, '
            'Disposal: ${disposalEnabled ? disposalType : 'N/A'}, '
            'Disposal Dates: '
            '${disposalFromDate != null ? _formatDateForFirestore(disposalFromDate!) : 'N/A'} - '
            '${disposalToDate != null ? _formatDateForFirestore(disposalToDate!) : 'N/A'}, '
            'Remarks: ${remarksController.text.trim().isEmpty ? 'N/A' : remarksController.text.trim()}';
        await FirebaseFirestore.instance
            .collection('staff_activity_log')
            .doc(adminBaNo)
            .collection('logs')
            .add({
          'timestamp': FieldValue.serverTimestamp(),
          'actionType': 'Create Meal State',
          'message': '$adminName created meal state. $details',
          'name': adminName,
        });
      }

      print('DEBUG: Starting Firestore operation for Auto Loop');
      print('DEBUG: dateStr = ${widget.dateStr}');
      print('DEBUG: baNo = $baNo');
      print('DEBUG: mealStateData = $mealStateData');

      await FirebaseFirestore.instance
          .collection('user_meal_state')
          .doc(widget.dateStr)
          .set({
        baNo.toString(): mealStateData,
      }, SetOptions(merge: true)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
              'Firestore operation timed out after 30 seconds');
        },
      );

      print('DEBUG: Firestore operation completed successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Auto Loop enabled! User\'s meal pattern will be repeated daily at 21:00.\n'
                'Today\'s submission saved successfully.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating auto loop: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  Future<void> _submitRegular() async {
    final adminData = await _getCurrentAdminData();
    setState(() {
      isSubmitting = true;
    });

    try {
      final baNo = widget.selectedUser['ba_no'];

      // Validate disposal dates if disposal is enabled
      if (disposalEnabled) {
        if (disposalFromDate == null || disposalToDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select both disposal from and to dates'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() {
            isSubmitting = false;
          });
          return;
        }

        // Check if from date is before to date
        if (disposalFromDate!.isAfter(disposalToDate!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('From date cannot be after to date'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() {
            isSubmitting = false;
          });
          return;
        }
      }

      // Create meal state data
      final mealStateData = <String, dynamic>{
        baNo: {
          'breakfast': breakfastSelected,
          'lunch': lunchSelected,
          'dinner': dinnerSelected,
          'disposal': disposalEnabled,
          'disposal_type': disposalEnabled ? disposalType : '',
          'disposal_from': disposalEnabled && disposalFromDate != null
              ? _formatDateForFirestore(disposalFromDate!)
              : '',
          'disposal_to': disposalEnabled && disposalToDate != null
              ? _formatDateForFirestore(disposalToDate!)
              : '',
          'remarks': remarksController.text.trim(),
          'name': widget.selectedUser['name'],
          'rank': widget.selectedUser['rank'],
          'timestamp': FieldValue.serverTimestamp(),
          'admin_generated': true, // Admin created
        }
      };

      // Activity log for create (regular)
      if (adminData != null && adminData['ba_no'] != null) {
        final adminName = adminData['name'] ?? 'Admin';
        final adminBaNo = adminData['ba_no'] ?? '';
        final details =
            'Created meal state for ${widget.selectedUser['name']} ($baNo) on ${widget.dateStr}. '
            'Breakfast: ${breakfastSelected ? 'Yes' : 'No'}, '
            'Lunch: ${lunchSelected ? 'Yes' : 'No'}, '
            'Dinner: ${dinnerSelected ? 'Yes' : 'No'}, '
            'Disposal: ${disposalEnabled ? disposalType : 'N/A'}, '
            'Disposal Dates: '
            '${disposalFromDate != null ? _formatDateForFirestore(disposalFromDate!) : 'N/A'} - '
            '${disposalToDate != null ? _formatDateForFirestore(disposalToDate!) : 'N/A'}, '
            'Remarks: ${remarksController.text.trim().isEmpty ? 'N/A' : remarksController.text.trim()}';
        await FirebaseFirestore.instance
            .collection('staff_activity_log')
            .doc(adminBaNo)
            .collection('logs')
            .add({
          'timestamp': FieldValue.serverTimestamp(),
          'actionType': 'Create Meal State',
          'message': '$adminName created meal state. $details',
          'name': adminName,
        });
      }

      print('DEBUG: Starting Firestore operation for Regular Submit');
      print('DEBUG: dateStr = ${widget.dateStr}');
      print('DEBUG: mealStateData = $mealStateData');

      await FirebaseFirestore.instance
          .collection('user_meal_state')
          .doc(widget.dateStr)
          .set(mealStateData, SetOptions(merge: true))
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
              'Firestore operation timed out after 30 seconds');
        },
      );

      print('DEBUG: Regular Submit Firestore operation completed successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal state created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating meal state: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isSubmitting,
      onPopInvoked: (didPop) {
        if (!didPop && isSubmitting) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please wait while creating meal state...'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Meal State'),
          backgroundColor: const Color(0xFF1A4D8F),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text(
                        "Admin Auto Loop Information",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A4D8F),
                        ),
                      ),
                      content: SizedBox(
                        width: double.maxFinite,
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: const SingleChildScrollView(
                          child: Text(
                            "🔄 ADMIN AUTO LOOP MODE:\n"
                            "• As an admin, you can enable Auto Loop for users to automatically repeat their meal pattern daily at 21:00\n"
                            "• Select the user's preferred meals (breakfast, lunch, dinner) and enable Auto Loop\n"
                            "• The user's meal pattern will be automatically applied every day\n"
                            "• You can also enable Auto Loop with NO MEALS selected to automatically submit 'no meals' daily\n"
                            "• Disposal and remarks apply only to the current submission date\n"
                            "• To change the pattern: Enable Auto Loop again with new meal selections\n"
                            "• Manual submissions will override the loop for that specific day only\n"
                            "• Disable Auto Loop anytime to stop automatic meal enrollment\n"
                            "• All admin-created Auto Loops are marked as 'admin_generated: true'\n\n"
                            "📖 ADMIN EXAMPLES:\n"
                            "• Admin sets Auto Loop ON with Breakfast + Lunch for a user: User will get breakfast and lunch automatically every day\n"
                            "• Admin sets Auto Loop ON with NO MEALS selected: User will automatically be marked as 'no meals' every day\n"
                            "• If user needs dinner one day, they can submit manually with dinner included, Auto Loop continues next day\n"
                            "• Admin wants to change user's pattern to all meals: Enable Auto Loop again with all meals selected\n"
                            "• User going on leave: Admin can submit with disposal info, Auto Loop continues after leave\n\n"
                            "⚠️ IMPORTANT:\n"
                            "• Admin-created Auto Loops will be managed by the system daily at 21:00\n"
                            "• Users can see their Auto Loop status but admin has override control\n"
                            "• Use this feature to help users who have difficulty managing their meal enrollment",
                            style: TextStyle(fontSize: 13, height: 1.5),
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            "Got it",
                            style: TextStyle(
                              color: Color(0xFF1A4D8F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User and Date Info Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFF1A4D8F)),
                          const SizedBox(width: 8),
                          const Text(
                            'User Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A4D8F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('BA No: ${widget.selectedUser['ba_no']}'),
                                Text('Name: ${widget.selectedUser['name']}'),
                                Text('Rank: ${widget.selectedUser['rank']}'),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Date:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(_formatDisplayDate(widget.selectedDate)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Auto Loop Section
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.loop,
                            color: _autoLoopEnabled
                                ? const Color(0xFF1A4D8F)
                                : Colors.grey.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Auto Loop Mode',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A4D8F),
                              ),
                            ),
                          ),
                          if (_isLoadingAutoLoop)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Switch(
                              value: _autoLoopEnabled,
                              onChanged: _toggleAutoLoop,
                              activeColor: const Color(0xFF1A4D8F),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _manualOverrideMode
                            ? '🔧 Manual Override Mode - Submit meals for today only, Auto Loop continues tomorrow'
                            : _autoLoopEnabled
                                ? '✅ Auto Loop is ON - Selected meal pattern will be automatically repeated daily at 21:00'
                                : 'Enable Auto Loop to automatically repeat the meal pattern daily (can include no meals)',
                        style: TextStyle(
                          fontSize: 13,
                          color: _manualOverrideMode
                              ? Colors.blue.shade700
                              : _autoLoopEnabled
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                          fontWeight: _manualOverrideMode
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                      if (_autoLoopEnabled) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue.shade700, size: 16),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Disposal and remarks will only apply to this submission. Meal pattern will continue automatically.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Show special message when no meals are selected but Auto Loop is enabled
                        if (!breakfastSelected &&
                            !lunchSelected &&
                            !dinnerSelected) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber,
                                    color: Colors.orange.shade700, size: 16),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Auto Loop with NO MEALS: User will automatically be marked as "no meals" every day at 21:00',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Meal Selection Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.restaurant,
                              color: Color(0xFF1A4D8F)),
                          const SizedBox(width: 8),
                          const Text(
                            'Meal Selection',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A4D8F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Breakfast
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CheckboxListTile(
                          title: const Row(
                            children: [
                              Icon(Icons.free_breakfast, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Breakfast'),
                            ],
                          ),
                          value: breakfastSelected,
                          onChanged: (value) {
                            setState(() {
                              breakfastSelected = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF1A4D8F),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Lunch
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CheckboxListTile(
                          title: const Row(
                            children: [
                              Icon(Icons.lunch_dining, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Lunch'),
                            ],
                          ),
                          value: lunchSelected,
                          onChanged: (value) {
                            setState(() {
                              lunchSelected = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF1A4D8F),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Dinner
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CheckboxListTile(
                          title: const Row(
                            children: [
                              Icon(Icons.dinner_dining, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Dinner'),
                            ],
                          ),
                          value: dinnerSelected,
                          onChanged: (value) {
                            setState(() {
                              dinnerSelected = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF1A4D8F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Disposal Information Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_busy,
                              color: Color(0xFF1A4D8F)),
                          const SizedBox(width: 8),
                          const Text(
                            'Disposal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A4D8F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Disposal Enable/Disable
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SwitchListTile(
                          title: const Text('Enable Disposal'),
                          subtitle: const Text('Turn on if user will be away'),
                          value: disposalEnabled,
                          onChanged: (value) {
                            setState(() {
                              disposalEnabled = value;
                              if (!value) {
                                // Clear disposal data when disabled
                                disposalFromDate = null;
                                disposalToDate = null;
                                disposalType = 'SIQ'; // Reset to default
                              }
                            });
                          },
                          activeColor: const Color(0xFF1A4D8F),
                        ),
                      ),

                      if (disposalEnabled) ...[
                        const SizedBox(height: 16),

                        // Disposal Type
                        const Text('Disposal Type:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: disposalType,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: ['SIQ', 'Leave']
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              disposalType = value ?? 'SIQ';
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date Selection
                        const Text('Disposal Period:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _pickDisposalDate(isFrom: true),
                                icon:
                                    const Icon(Icons.calendar_today, size: 18),
                                label: Text(
                                  disposalFromDate != null
                                      ? _formatDisplayDate(disposalFromDate!)
                                      : 'From Date',
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _pickDisposalDate(isFrom: false),
                                icon:
                                    const Icon(Icons.calendar_today, size: 18),
                                label: Text(
                                  disposalToDate != null
                                      ? _formatDisplayDate(disposalToDate!)
                                      : 'To Date',
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Remarks Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.note, color: Color(0xFF1A4D8F)),
                          const SizedBox(width: 8),
                          const Text(
                            'Remarks',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A4D8F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: remarksController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter any additional remarks or notes...',
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitMealState,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A4D8F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Creating...'),
                          ],
                        )
                      : Text(
                          _manualOverrideMode
                              ? 'Submit Manual Override (Today Only)'
                              : 'Create Meal State',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ), // Scaffold closing
    ); // PopScope closing
  }

  @override
  void dispose() {
    remarksController.dispose();
    super.dispose();
  }
}

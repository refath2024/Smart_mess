import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class MealStateRecordScreen extends StatefulWidget {
  const MealStateRecordScreen({super.key});

  @override
  State<MealStateRecordScreen> createState() => _MealStateRecordScreenState();
}

class _MealStateRecordScreenState extends State<MealStateRecordScreen> {
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

  @override
  void initState() {
    super.initState();
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

      // Get all meal state documents without ordering (to avoid index requirement)
      final querySnapshot =
          await FirebaseFirestore.instance.collection('user_meal_state').get();

      for (var doc in querySnapshot.docs) {
        final dateStr = doc.id;
        final data = doc.data();

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
            'Rk': userData['rank'] ?? '',
            'Name': userData['name'] ?? '',
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

        // Format remarks - auto convert to N/A if empty or variations of n/a
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
          '$baNo.remarks': finalRemarks,
          '$baNo.timestamp': FieldValue.serverTimestamp(),
          '$baNo.admin_generated': false, // Mark as manually edited
        });

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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_disposalFromDate ?? selectedDate ?? DateTime.now())
          : (_disposalToDate ?? selectedDate ?? DateTime.now()),
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
            Row(
              children: [
                Expanded(
                  flex: 2,
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
                const SizedBox(width: 12),
                // Date selector
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
                const SizedBox(width: 12),
                // Create Meal State button
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
                                                  setState(() {
                                                    _disposalTypeController
                                                        .text = value!;
                                                  });
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
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Picker
            const Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
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
              height: 200,
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
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : null,
                            );
                          },
                        ),
            ),
          ],
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
  // Meal selections
  bool breakfastSelected = false;
  bool lunchSelected = false;
  bool dinnerSelected = false;

  // Disposal information
  bool disposalEnabled = false;
  String disposalType = 'SIQ';
  DateTime? disposalFromDate;
  DateTime? disposalToDate;

  // Remarks
  final TextEditingController remarksController = TextEditingController();

  bool isSubmitting = false;

  String _formatDateForFirestore(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatDisplayDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _pickDisposalDate({required bool isFrom}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (disposalFromDate ?? DateTime.now())
          : (disposalToDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          disposalFromDate = picked;
          // If to date is before from date, clear it
          if (disposalToDate != null && disposalToDate!.isBefore(picked)) {
            disposalToDate = null;
          }
        } else {
          disposalToDate = picked;
        }
      });
    }
  }

  Future<void> _submitMealState() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      final baNo = widget.selectedUser['ba_no'];

      // Validate disposal dates if disposal is enabled
      if (disposalEnabled &&
          (disposalFromDate == null || disposalToDate == null)) {
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

      await FirebaseFirestore.instance
          .collection('user_meal_state')
          .doc(widget.dateStr)
          .set(mealStateData, SetOptions(merge: true));

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

    setState(() {
      isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Meal State'),
        backgroundColor: const Color(0xFF1A4D8F),
        foregroundColor: Colors.white,
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
                                style: TextStyle(fontWeight: FontWeight.bold)),
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
                        const Icon(Icons.restaurant, color: Color(0xFF1A4D8F)),
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
                        const Icon(Icons.event_busy, color: Color(0xFF1A4D8F)),
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
                    SwitchListTile(
                      title: const Text('Enable Disposal'),
                      subtitle: const Text('Turn on if user will be away'),
                      value: disposalEnabled,
                      onChanged: (value) {
                        setState(() {
                          disposalEnabled = value;
                          if (!value) {
                            disposalFromDate = null;
                            disposalToDate = null;
                          }
                        });
                      },
                      activeColor: const Color(0xFF1A4D8F),
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
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              onPressed: () => _pickDisposalDate(isFrom: true),
                              icon: const Icon(Icons.calendar_today, size: 18),
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
                              onPressed: () => _pickDisposalDate(isFrom: false),
                              icon: const Icon(Icons.calendar_today, size: 18),
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
                    : const Text(
                        'Create Meal State',
                        style: TextStyle(
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
    );
  }

  @override
  void dispose() {
    remarksController.dispose();
    super.dispose();
  }
}

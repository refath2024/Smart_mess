import 'package:flutter/material.dart';

class MealStateRecordScreen extends StatefulWidget {
  const MealStateRecordScreen({super.key});

  @override
  State<MealStateRecordScreen> createState() => _MealStateRecordScreenState();
}

class _MealStateRecordScreenState extends State<MealStateRecordScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? selectedDate = DateTime.now(); // Made nullable
  List<Map<String, dynamic>> filteredRecords = [];
  int? editingIndex;
  final TextEditingController _breakfastController = TextEditingController();
  final TextEditingController _lunchController = TextEditingController();
  final TextEditingController _dinnerController = TextEditingController();
  final TextEditingController _disposalsController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  // Sample data with different dates
  final List<Map<String, dynamic>> allRecords = [
    {
      'BA No': 'BA-1234',
      'Rk': 'Maj',
      'Name': 'John Smith',
      'Date': '2025-07-20',
      'Breakfast': 'Yes',
      'Lunch': 'No',
      'Dinner': 'Yes',
      'Disposals': 'None',
      'Remarks': 'Extra egg',
    },
    {
      'BA No': 'BA-5678',
      'Rk': 'Capt',
      'Name': 'Jane Doe',
      'Date': '2025-07-20',
      'Breakfast': 'No',
      'Lunch': 'Yes',
      'Dinner': 'Yes',
      'Disposals': 'SIQ',
      'Remarks': '',
    },
    {
      'BA No': 'BA-9012',
      'Rk': 'Lt',
      'Name': 'Mike Johnson',
      'Date': '2025-07-19',
      'Breakfast': 'Yes',
      'Lunch': 'Yes',
      'Dinner': 'No',
      'Disposals': 'Leave',
      'Remarks': 'Extra fish',
    },
    {
      'BA No': 'BA-3456',
      'Rk': 'Capt',
      'Name': 'Sarah Wilson',
      'Date': '2025-07-19',
      'Breakfast': 'Yes',
      'Lunch': 'Yes',
      'Dinner': 'Yes',
      'Disposals': 'None',
      'Remarks': '',
    },
    {
      'BA No': 'BA-7890',
      'Rk': 'Maj',
      'Name': 'David Brown',
      'Date': '2025-07-18',
      'Breakfast': 'No',
      'Lunch': 'Yes',
      'Dinner': 'Yes',
      'Disposals': 'Mess Out',
      'Remarks': 'Late dinner',
    },
  ];

  @override
  void initState() {
    super.initState();
    filteredRecords = List.from(allRecords);
    _filterRecords(_searchController.text);
  }

  void _startEditing(int index, Map<String, dynamic> record) {
    setState(() {
      editingIndex = index;
      _breakfastController.text = record['Breakfast'];
      _lunchController.text = record['Lunch'];
      _dinnerController.text = record['Dinner'];
      _disposalsController.text = record['Disposals'];
      _remarksController.text = record['Remarks'];
    });
  }

  void _saveEditing(int index) {
    showDialog(
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
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          allRecords[index]['Breakfast'] = _breakfastController.text;
          allRecords[index]['Lunch'] = _lunchController.text;
          allRecords[index]['Dinner'] = _dinnerController.text;
          allRecords[index]['Disposals'] = _disposalsController.text;
          allRecords[index]['Remarks'] = _remarksController.text;
          editingIndex = null;
          _filterRecords(_searchController.text);
        });
      }
    });
  }

  void _cancelEditing() {
    setState(() {
      editingIndex = null;
    });
  }

  void _deleteRecord(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                allRecords.removeAt(index);
                _filterRecords(_searchController.text);
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
        final date =
            '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
        final matchesDate = record['Date'] == date;

        return matchesQuery && matchesDate;
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                SizedBox(
                  width: 200, // Fixed width for date section
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
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
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

                            return DataRow(
                              cells: [
                                DataCell(Text(record['BA No'].toString())),
                                DataCell(Text(record['Rk'].toString())),
                                DataCell(Text(record['Name'].toString())),
                                DataCell(Text(record['Date'].toString())),
                                DataCell(
                                  isEditing
                                      ? DropdownButton<String>(
                                          value: _breakfastController.text,
                                          items: const [
                                            DropdownMenuItem(
                                                value: 'Yes',
                                                child: Text('Yes')),
                                            DropdownMenuItem(
                                                value: 'No', child: Text('No')),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _breakfastController.text =
                                                  value!;
                                              filteredRecords[index]
                                                  ['Breakfast'] = value;
                                            });
                                          },
                                        )
                                      : Text(record['Breakfast'].toString()),
                                ),
                                DataCell(
                                  isEditing
                                      ? DropdownButton<String>(
                                          value: _lunchController.text,
                                          items: const [
                                            DropdownMenuItem(
                                                value: 'Yes',
                                                child: Text('Yes')),
                                            DropdownMenuItem(
                                                value: 'No', child: Text('No')),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _lunchController.text = value!;
                                              filteredRecords[index]['Lunch'] =
                                                  value;
                                            });
                                          },
                                        )
                                      : Text(record['Lunch'].toString()),
                                ),
                                DataCell(
                                  isEditing
                                      ? DropdownButton<String>(
                                          value: _dinnerController.text,
                                          items: const [
                                            DropdownMenuItem(
                                                value: 'Yes',
                                                child: Text('Yes')),
                                            DropdownMenuItem(
                                                value: 'No', child: Text('No')),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _dinnerController.text = value!;
                                              filteredRecords[index]['Dinner'] =
                                                  value;
                                            });
                                          },
                                        )
                                      : Text(record['Dinner'].toString()),
                                ),
                                DataCell(
                                  isEditing
                                      ? DropdownButton<String>(
                                          value: _disposalsController.text,
                                          items: const [
                                            DropdownMenuItem(
                                                value: 'None',
                                                child: Text('None')),
                                            DropdownMenuItem(
                                                value: 'SIQ',
                                                child: Text('SIQ')),
                                            DropdownMenuItem(
                                                value: 'Leave',
                                                child: Text('Leave')),
                                            DropdownMenuItem(
                                                value: 'Mess Out',
                                                child: Text('Mess Out')),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _disposalsController.text =
                                                  value!;
                                              filteredRecords[index]
                                                  ['Disposals'] = value;
                                            });
                                          },
                                        )
                                      : Text(record['Disposals'].toString()),
                                ),
                                DataCell(
                                  isEditing
                                      ? TextField(
                                          controller: _remarksController,
                                          decoration: const InputDecoration(
                                            hintText: 'Enter remarks',
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              filteredRecords[index]
                                                  ['Remarks'] = value;
                                            });
                                          },
                                        )
                                      : Text(record['Remarks'].toString()),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isEditing) ...[
                                        IconButton(
                                          icon: const Icon(Icons.save,
                                              color: Colors.green),
                                          onPressed: () => _saveEditing(index),
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
                                          onPressed: () =>
                                              _startEditing(index, record),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _deleteRecord(index),
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
          ],
        ),
      ),
    );
  }
}

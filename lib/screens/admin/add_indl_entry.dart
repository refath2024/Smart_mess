import 'package:flutter/material.dart';

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
  bool _isLoading = false;
  int? _editingRowId;

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
    }
  }

  void _searchData() {
    // TODO: Implement search functionality
    setState(() {
      _isLoading = true;
      // Simulate API call
      _userData = [
        {
          'id': 1,
          'ba_number': '12345',
          'name': 'John Doe',
          'rank': 'Captain',
          'meal_date': '2025-07-20',
          'breakfast_price': 120.00,
          'lunch_price': 150.00,
          'dinner_price': 180.00,
          'extra_chit': 50.00,
          'bar_chit': 100.00,
        },
        // Add more mock data as needed
      ];
      _isLoading = false;
    });
  }

  void _editRecord(Map<String, dynamic> record) {
    setState(() {
      _editingRowId = record['id'];
    });
  }

  void _saveRecord(Map<String, dynamic> record) {
    // TODO: Implement API call to save changes
    setState(() {
      _editingRowId = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingRowId = null;
      // TODO: Revert changes if needed
    });
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
                      ElevatedButton.icon(
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
                      rows: _userData.map((record) {
                        return DataRow(
                          cells: [
                            DataCell(Text(record['ba_number'].toString())),
                            DataCell(Text(record['rank'])),
                            DataCell(Text(record['name'])),
                            DataCell(Text(record['meal_date'])),
                            DataCell(
                              _editingRowId == record['id']
                                  ? TextFormField(
                                      initialValue:
                                          record['breakfast_price'].toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.all(8),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          record['breakfast_price'] =
                                              double.tryParse(value) ?? 0.0;
                                        });
                                      },
                                    )
                                  : Text('${record['breakfast_price']}'),
                            ),
                            DataCell(
                              _editingRowId == record['id']
                                  ? TextFormField(
                                      initialValue:
                                          record['lunch_price'].toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.all(8),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          record['lunch_price'] =
                                              double.tryParse(value) ?? 0.0;
                                        });
                                      },
                                    )
                                  : Text('${record['lunch_price']}'),
                            ),
                            DataCell(
                              _editingRowId == record['id']
                                  ? TextFormField(
                                      initialValue:
                                          record['dinner_price'].toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.all(8),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          record['dinner_price'] =
                                              double.tryParse(value) ?? 0.0;
                                        });
                                      },
                                    )
                                  : Text('${record['dinner_price']}'),
                            ),
                            DataCell(
                              _editingRowId == record['id']
                                  ? TextFormField(
                                      initialValue:
                                          record['extra_chit'].toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.all(8),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          record['extra_chit'] =
                                              double.tryParse(value) ?? 0.0;
                                        });
                                      },
                                    )
                                  : Text('${record['extra_chit']}'),
                            ),
                            DataCell(
                              _editingRowId == record['id']
                                  ? TextFormField(
                                      initialValue:
                                          record['bar_chit'].toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.all(8),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          record['bar_chit'] =
                                              double.tryParse(value) ?? 0.0;
                                        });
                                      },
                                    )
                                  : Text('${record['bar_chit']}'),
                            ),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_editingRowId == record['id']) ...[
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

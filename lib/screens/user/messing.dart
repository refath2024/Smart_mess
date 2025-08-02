import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessingScreen extends StatefulWidget {
  const MessingScreen({super.key});

  @override
  State<MessingScreen> createState() => _MessingScreenState();
}

class _MessingScreenState extends State<MessingScreen> {
  String _viewType = "Overview";
  bool _isLoading = false;

  final List<String> _months = List.generate(
    12,
    (i) => DateFormat('MMMM').format(DateTime(0, i + 1)),
  );

  late String _selectedMonth;
  late int _selectedYear;

  late String _tempSelectedMonth;
  late int _tempSelectedYear;

  // Real messing data from Firebase
  List<Map<String, dynamic>> messingData = [];
  double totalMonthlyMessing = 0.0; // Total of all meals for the month
  double totalExtraChitMessing = 0.0;
  double totalExtraChitBar = 0.0;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'en_US';

    final now = DateTime.now();
    _selectedMonth = DateFormat('MMMM').format(now);
    _selectedYear = now.year;
    _tempSelectedMonth = _selectedMonth;
    _tempSelectedYear = _selectedYear;

    _fetchMessingData();
  }

  Future<void> _fetchMessingData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Fetch all user data and filter locally to avoid composite index requirement
      final querySnapshot = await FirebaseFirestore.instance
          .collection('messing_data')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Calculate selected month index for filtering
      final selectedMonthIndex = _months.indexOf(_selectedMonth) + 1;

      List<Map<String, dynamic>> fetchedData = [];
      double monthlyMessingTotal = 0.0; // Total of all meals taken in the month

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final dateStr = data['date'] as String?;
        
        if (dateStr == null) continue;
        
        try {
          final docDate = DateTime.parse(dateStr);
          
          // Filter by selected month and year locally
          if (docDate.month == selectedMonthIndex && docDate.year == _selectedYear) {
            final meals = data['meals'] as List<dynamic>? ?? [];
            
            double dayTotal = 0.0;
            for (var meal in meals) {
              dayTotal += (meal['price'] as num?)?.toDouble() ?? 0.0;
            }
            
            fetchedData.add({
              'date': docDate,
              'meals': meals,
              'totalCost': data['totalCost'] ?? dayTotal,
              'disposal': data['disposal'] ?? false,
              'disposalType': data['disposalType'] ?? 'No',
            });

            // Add to monthly total only if not on disposal
            if (!(data['disposal'] ?? false)) {
              monthlyMessingTotal += dayTotal;
            }
          }
        } catch (e) {
          print('Error parsing date: $dateStr');
          continue;
        }
      }

      // Fetch extra chit data (these will be updated by admin)
      final extraChitDoc = await FirebaseFirestore.instance
          .collection('extra_chits')
          .doc('${user.uid}_${_selectedMonth}_$_selectedYear')
          .get();

      double extraMessing = 0.0;
      double extraBar = 0.0;

      if (extraChitDoc.exists) {
        final extraData = extraChitDoc.data()!;
        extraMessing = (extraData['extra_messing'] as num?)?.toDouble() ?? 0.0;
        extraBar = (extraData['extra_bar'] as num?)?.toDouble() ?? 0.0;
      }

      setState(() {
        messingData = fetchedData;
        totalMonthlyMessing = monthlyMessingTotal; // This is now the total for the whole month
        totalExtraChitMessing = extraMessing;
        totalExtraChitBar = extraBar;
        _isLoading = false;
      });

    } catch (e) {
      print('Error fetching messing data: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _goPressed() {
    setState(() {
      _selectedMonth = _tempSelectedMonth;
      _selectedYear = _tempSelectedYear;
    });
    _fetchMessingData(); // Fetch new data for selected month/year
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loading data for $_selectedMonth $_selectedYear'),
      ),
    );
  }

  Widget _buildSimpleTable(String title, Map<String, String> data) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Table(
          columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
          border: TableBorder.all(color: Colors.grey.shade300),
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.blue.shade100),
              children: [
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(),
              ],
            ),
            ...data.entries.map(
              (e) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(e.key),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(e.value, textAlign: TextAlign.right),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTables() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading messing data...'),
          ],
        ),
      );
    }

    // Calculate messing totals from Firebase data
    double currentMessBill = totalMonthlyMessing + totalExtraChitMessing + totalExtraChitBar;
    
    // Fixed amounts (as per requirement)
    double totalSubscriptions = 300.00;
    double totalCuttings = 100.00;
    double totalMisc = 120.00;
    double arrears = 150.00;
    
    double totalPayable = currentMessBill +
        totalSubscriptions +
        totalCuttings +
        totalMisc +
        arrears;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSimpleTable('Messing', {
            'Monthly Messing Total': totalMonthlyMessing.toStringAsFixed(2),
            'Extra Chit (Messing)': totalExtraChitMessing.toStringAsFixed(2),
            'Extra Chit (Bar)': totalExtraChitBar.toStringAsFixed(2),
            'Total Bill': currentMessBill.toStringAsFixed(2),
          }),
          const SizedBox(height: 12),
          _buildSimpleTable('Subscriptions', {
            'Orderly Pay': '50.00',
            'Mess Maintenance': '60.00',
            'Garden': '30.00',
            'Newspaper': '20.00',
            'Silver': '20.00',
            'Dish Antenna': '30.00',
            'Sports': '20.00',
            'Breakage Charge': '20.00',
            'Internet Bill': '30.00',
            'Washerman Bill': '20.00',
            'Total Bill': totalSubscriptions.toStringAsFixed(2),
          }),
          const SizedBox(height: 12),
          _buildSimpleTable('Regimental Cuttings', {
            'Regimental Cuttings': '40.00',
            'Cantt Sta Sports': '20.00',
            'Mosque': '10.00',
            'Reunion': '20.00',
            'Band': '10.00',
            'Total Bill': totalCuttings.toStringAsFixed(2),
          }),
          const SizedBox(height: 12),
          _buildSimpleTable('Miscellaneous', {
            'Misc Bills': '40.00',
            'Crest': '30.00',
            'Cleaners Bill': '50.00',
            'Total Bill': totalMisc.toStringAsFixed(2),
          }),
          const SizedBox(height: 12),
          _buildSimpleTable('Bill Payable', {
            'Current Mess Bill': currentMessBill.toStringAsFixed(2),
            'Arrears till now': arrears.toStringAsFixed(2),
            'Total Payable': totalPayable.toStringAsFixed(2),
          }),
        ],
      ),
    );
  }

  Widget _buildDetailTable() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading detailed data...'),
          ],
        ),
      );
    }

    // Sort messing data by date
    messingData.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );

    double totalBreakfast = 0,
        totalLunch = 0,
        totalDinner = 0;

    // Process each day's data to extract meal costs
    List<Map<String, dynamic>> processedData = [];
    for (var dayData in messingData) {
      double breakfast = 0, lunch = 0, dinner = 0;
      
      final meals = dayData['meals'] as List<dynamic>? ?? [];
      for (var meal in meals) {
        final mealType = meal['mealType'] as String? ?? '';
        final price = (meal['price'] as num?)?.toDouble() ?? 0.0;
        
        switch (mealType.toLowerCase()) {
          case 'breakfast':
            breakfast += price;
            break;
          case 'lunch':
            lunch += price;
            break;
          case 'dinner':
            dinner += price;
            break;
        }
      }

      if (!(dayData['disposal'] ?? false)) {
        totalBreakfast += breakfast;
        totalLunch += lunch;
        totalDinner += dinner;
      }

      processedData.add({
        'date': dayData['date'],
        'breakfast': breakfast,
        'lunch': lunch,
        'dinner': dinner,
        'disposal': dayData['disposal'] ?? false,
        'disposalType': dayData['disposalType'] ?? 'No',
      });
    }

    // Wrap horizontal and vertical scroll to avoid overflow
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.blue.shade100),
            columns: const [
              DataColumn(
                label: Text(
                  'Date',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Breakfast',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Lunch',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Dinner',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: [
              ...processedData.map((entry) {
                final date = entry['date'] as DateTime;
                final isDisposal = entry['disposal'] as bool;
                final disposalType = entry['disposalType'] as String;
                
                return DataRow(
                  color: isDisposal 
                    ? WidgetStateProperty.all(Colors.red.shade50)
                    : null,
                  cells: [
                    DataCell(Text(DateFormat('dd-MM-yyyy').format(date))),
                    DataCell(
                      Text(
                        isDisposal ? '-' : (entry['breakfast'] as double).toStringAsFixed(2),
                        style: TextStyle(
                          color: isDisposal ? Colors.red : Colors.black,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        isDisposal ? '-' : (entry['lunch'] as double).toStringAsFixed(2),
                        style: TextStyle(
                          color: isDisposal ? Colors.red : Colors.black,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        isDisposal ? '-' : (entry['dinner'] as double).toStringAsFixed(2),
                        style: TextStyle(
                          color: isDisposal ? Colors.red : Colors.black,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        isDisposal ? disposalType : 'Active',
                        style: TextStyle(
                          color: isDisposal ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              }),
              // Total row (always added)
              DataRow(
                color: WidgetStateProperty.all(Colors.blue.shade100),
                cells: [
                  const DataCell(
                    Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    Text(
                      totalBreakfast.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    Text(
                      totalLunch.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    Text(
                      totalDinner.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataCell(
                    Text(
                      'Active Days',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthYearSelector() {
    return Row(
      children: [
        DropdownButton<String>(
          value: _tempSelectedMonth,
          items: _months
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _tempSelectedMonth = val);
          },
        ),
        const SizedBox(width: 16),
        DropdownButton<int>(
          value: _tempSelectedYear,
          items: List.generate(5, (i) => DateTime.now().year - i)
              .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _tempSelectedYear = val);
          },
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _goPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF002B5B),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
          child: const Text(
            'Go',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "View: ",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _viewType,
                    items: const [
                      DropdownMenuItem(
                        value: "Overview",
                        child: Text("Overview"),
                      ),
                      DropdownMenuItem(
                        value: "Detail Breakdown",
                        child: Text("Detail Breakdown"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _viewType = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMonthYearSelector(),
              const SizedBox(height: 16),
              Expanded(
                child: _viewType == "Overview"
                    ? _buildOverviewTables()
                    : _buildDetailTable(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

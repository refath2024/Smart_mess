import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'meal_in_out_screen.dart';
import 'user_home_screen.dart';
import '../login_screen.dart';
import 'billing_screen.dart';
import 'menu_set_screen.dart';

class MessingScreen extends StatefulWidget {
  const MessingScreen({super.key});

  @override
  State<MessingScreen> createState() => _MessingScreenState();
}

class _MessingScreenState extends State<MessingScreen> {
  String _viewType = "Overview";

  final List<String> _months = List.generate(
    12,
    (i) => DateFormat('MMMM').format(DateTime(0, i + 1)),
  );

  late String _selectedMonth;
  late int _selectedYear;

  late String _tempSelectedMonth;
  late int _tempSelectedYear;

  // Demo data: last 5 days previous month + first 5 days current month
  late final List<Map<String, dynamic>> demoData;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'en_US';

    final now = DateTime.now();
    _selectedMonth = DateFormat('MMMM').format(now);
    _selectedYear = now.year;
    _tempSelectedMonth = _selectedMonth;
    _tempSelectedYear = _selectedYear;

    demoData = [];

    // Previous month details
    int prevMonth = now.month == 1 ? 12 : now.month - 1;
    int prevYear = now.month == 1 ? now.year - 1 : now.year;
    int prevMonthLastDay = DateTime(prevYear, prevMonth + 1, 0).day;

    // Add last 5 days of previous month
    for (int i = prevMonthLastDay - 4; i <= prevMonthLastDay; i++) {
      DateTime date = DateTime(prevYear, prevMonth, i);
      demoData.add({
        'date': date,
        'breakfast': 30.0 + i,
        'lunch': 50.0 + i * 0.5,
        'dinner': 45.0 + i * 0.7,
        'extras': 8.0 + i * 0.2,
        'bar': 4.0 + i * 0.1,
      });
    }

    // Add first 5 days of current month
    for (int i = 1; i <= 5; i++) {
      DateTime date = DateTime(now.year, now.month, i);
      demoData.add({
        'date': date,
        'breakfast': 40.0 + i,
        'lunch': 60.0 + i * 0.5,
        'dinner': 55.0 + i * 0.7,
        'extras': 10.0 + i * 0.2,
        'bar': 5.0 + i * 0.1,
      });
    }
  }

  void _goPressed() {
    setState(() {
      _selectedMonth = _tempSelectedMonth;
      _selectedYear = _tempSelectedYear;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing data for $_selectedMonth $_selectedYear'),
      ),
    );
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
    final filteredData = demoData.where((entry) {
      final date = entry['date'] as DateTime;
      return date.month == _months.indexOf(_selectedMonth) + 1 &&
          date.year == _selectedYear;
    }).toList();

    double totalMessing = 0;
    double totalExtras = 0;
    double totalBar = 0;
    // Fixed dummy subscription, cutting, misc amounts
    double totalSubscriptions = 300.00;
    double totalCuttings = 100.00;
    double totalMisc = 120.00;

    for (var entry in filteredData) {
      totalMessing +=
          (entry['breakfast'] + entry['lunch'] + entry['dinner']) as double;
      totalExtras += entry['extras'] as double;
      totalBar += entry['bar'] as double;
    }

    double currentMessBill = totalMessing + totalExtras + totalBar;
    double arrears = 150.00;
    double totalPayable =
        currentMessBill +
        totalSubscriptions +
        totalCuttings +
        totalMisc +
        arrears;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSimpleTable('Messing', {
            'Daily Messing': totalMessing.toStringAsFixed(2),
            'Extra Chit (Messing)': totalExtras.toStringAsFixed(2),
            'Extra Chit (Bar)': totalBar.toStringAsFixed(2),
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
    final filteredData = demoData.where((entry) {
      final date = entry['date'] as DateTime;
      return date.month == _months.indexOf(_selectedMonth) + 1 &&
          date.year == _selectedYear;
    }).toList();

    filteredData.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );

    double totalBreakfast = 0,
        totalLunch = 0,
        totalDinner = 0,
        totalExtras = 0,
        totalBar = 0;

    for (var row in filteredData) {
      totalBreakfast += row['breakfast'] as double;
      totalLunch += row['lunch'] as double;
      totalDinner += row['dinner'] as double;
      totalExtras += row['extras'] as double;
      totalBar += row['bar'] as double;
    }

    // Wrap horizontal and vertical scroll to avoid overflow
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.blue.shade100),
            columns: const [
              DataColumn(
                label: Text(
                  'Chit Date',
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
                  'Extras',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Bar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: [
              ...filteredData.map((entry) {
                final date = entry['date'] as DateTime;
                return DataRow(
                  cells: [
                    DataCell(Text(DateFormat('dd-MM-yyyy').format(date))),
                    DataCell(
                      Text((entry['breakfast'] as double).toStringAsFixed(2)),
                    ),
                    DataCell(
                      Text((entry['lunch'] as double).toStringAsFixed(2)),
                    ),
                    DataCell(
                      Text((entry['dinner'] as double).toStringAsFixed(2)),
                    ),
                    DataCell(
                      Text((entry['extras'] as double).toStringAsFixed(2)),
                    ),
                    DataCell(Text((entry['bar'] as double).toStringAsFixed(2))),
                  ],
                );
              }),
              // Total row (always added)
              DataRow(
                color: MaterialStateProperty.all(Colors.blue.shade100),
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
                  DataCell(
                    Text(
                      totalExtras.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    Text(
                      totalBar.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
      drawer: Drawer(
        child: SafeArea(
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
                  children: const [
                    CircleAvatar(
                      backgroundImage: AssetImage('assets/me.png'),
                      radius: 30,
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        "Shoaib Ahmed Sami",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _buildSidebarTile(
                      icon: Icons.home,
                      title: "Home",
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserHomeScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSidebarTile(
                      icon: Icons.fastfood,
                      title: "Meal IN/OUT",
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MealInOutScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSidebarTile(
                      icon: Icons.food_bank,
                      title: "Messing",
                      onTap: () {
                        Navigator.pop(context);
                      },
                      selected: true,
                    ),
                    _buildSidebarTile(
                      icon: Icons.menu_book,
                      title: "Menu Set",
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MenuSetScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSidebarTile(
                      icon: Icons.receipt_long,
                      title: "Billing",
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BillingScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                ),
                child: _buildSidebarTile(
                  icon: Icons.logout,
                  title: "Logout",
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Smart Mess",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
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

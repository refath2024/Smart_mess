import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

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

  // New variables for detailed daily messing data
  List<Map<String, dynamic>> dailyMessingData = [];
  String? userBaNumber;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'en_US';

    final now = DateTime.now();
    _selectedMonth = DateFormat('MMMM').format(now);
    _selectedYear = now.year;
    _tempSelectedMonth = _selectedMonth;
    _tempSelectedYear = _selectedYear;

    // Use post-frame callback to ensure widget is fully built before making Firebase calls
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMessingData();
    });
  }

  Future<void> _fetchMessingData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // First get user's BA number
      await _fetchUserBaNumber(user.uid);

      // For overview - fetch from old messing_data collection
      await _fetchOverviewData(user);

      // For detail breakdown - fetch from daily_messing collection
      await _fetchDailyMessingData();
    } catch (e) {
      print('Error fetching messing data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchMessingData,
            ),
          ),
        );
      }
    }
  }

  Future<void> _fetchUserBaNumber(String userId) async {
    try {
      // Follow the exact same logic as add_indl_entry.dart
      final userDoc = await FirebaseFirestore.instance
          .collection('user_requests')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          userBaNumber = userData['ba_no']?.toString();
          print('Found user BA number: $userBaNumber');
        }
      }

      // If not found by direct lookup, try by userId field (as backup)
      if (userBaNumber == null) {
        final userSnapshot = await FirebaseFirestore.instance
            .collection('user_requests')
            .where('userId', isEqualTo: userId)
            .where('approved', isEqualTo: true)
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          final userData = userSnapshot.docs.first.data();
          userBaNumber = userData['ba_no']?.toString();
          print('Found user BA number via userId: $userBaNumber');
        }
      }

      if (userBaNumber == null) {
        print('No BA number found for userId: $userId');
      }
    } catch (e) {
      print('Error fetching user BA number: $e');
    }
  }

  Future<void> _fetchDailyMessingData() async {
    if (userBaNumber == null) {
      print('Cannot fetch daily messing data: BA number not found');
      setState(() {
        dailyMessingData = [];
        _isLoading = false;
      });
      return;
    }

    try {
      print(
          'Fetching daily messing data for BA: $userBaNumber, Month: $_selectedMonth $_selectedYear');

      // Calculate date range for the selected month (only up to current date)
      final selectedMonthIndex = _months.indexOf(_selectedMonth) + 1;
      final startDate = DateTime(_selectedYear, selectedMonthIndex, 1);
      final endDate = DateTime(_selectedYear, selectedMonthIndex + 1, 0);
      final today = DateTime.now();

      // Only fetch up to today if we're in the current month
      final actualEndDate =
          (selectedMonthIndex == today.month && _selectedYear == today.year)
              ? today
              : endDate;

      print(
          'Date range: ${startDate.toIso8601String()} to ${actualEndDate.toIso8601String()}');

      List<Map<String, dynamic>> fetchedDailyData = [];
      double totalBreakfast = 0.0, totalLunch = 0.0, totalDinner = 0.0;
      double totalExtraChit = 0.0, totalBarChit = 0.0;

      // Iterate through each day in the date range
      for (DateTime date = startDate;
          date.isBefore(actualEndDate.add(const Duration(days: 1)));
          date = date.add(const Duration(days: 1))) {
        final dateStr =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        try {
          // Check if daily_messing data exists for this date
          final dailyDoc = await FirebaseFirestore.instance
              .collection('daily_messing')
              .doc(dateStr)
              .get();

          Map<String, dynamic>? userDayData;

          if (dailyDoc.exists && dailyDoc.data() != null) {
            // Load existing data
            final data = dailyDoc.data()!;
            userDayData = data[userBaNumber] as Map<String, dynamic>?;
          }

          // If no data exists for this date or user, generate default data
          if (userDayData == null) {
            userDayData = await _generateDefaultDataForDate(dateStr);
          }

          final breakfastPrice = userDayData['breakfast']?.toDouble() ?? 0.0;
          final lunchPrice = userDayData['lunch']?.toDouble() ?? 0.0;
          final dinnerPrice = userDayData['dinner']?.toDouble() ?? 0.0;
          final extraChit = userDayData['extra_chit']?.toDouble() ?? 0.0;
          final barChit = userDayData['bar']?.toDouble() ?? 0.0;

          // Add to totals
          totalBreakfast += breakfastPrice;
          totalLunch += lunchPrice;
          totalDinner += dinnerPrice;
          totalExtraChit += extraChit;
          totalBarChit += barChit;

          fetchedDailyData.add({
            'date': date,
            'breakfast': breakfastPrice,
            'lunch': lunchPrice,
            'dinner': dinnerPrice,
            'extra_chit': extraChit,
            'bar_chit': barChit,
            'total':
                breakfastPrice + lunchPrice + dinnerPrice + extraChit + barChit,
          });
        } catch (e) {
          print('Error fetching data for date $dateStr: $e');
          // Add zero entry for failed dates
          fetchedDailyData.add({
            'date': date,
            'breakfast': 0.0,
            'lunch': 0.0,
            'dinner': 0.0,
            'extra_chit': 0.0,
            'bar_chit': 0.0,
            'total': 0.0,
          });
        }
      }

      if (mounted) {
        setState(() {
          dailyMessingData = fetchedDailyData;
          // Update totals for overview
          totalMonthlyMessing = totalBreakfast + totalLunch + totalDinner;
          totalExtraChitMessing = totalExtraChit;
          totalExtraChitBar = totalBarChit;
          _isLoading = false;
        });
        print(
            'Successfully loaded ${fetchedDailyData.length} days of daily messing data');
      }
    } catch (e) {
      print('Error fetching daily messing data: $e');
      if (mounted) {
        setState(() {
          dailyMessingData = [];
          _isLoading = false;
        });
      }
    }
  }

  /// Generate default data for a specific date if it doesn't exist
  /// Following the exact same logic as add_indl_entry.dart
  Future<Map<String, dynamic>> _generateDefaultDataForDate(
      String dateStr) async {
    try {
      print('Generating default data for date: $dateStr, BA: $userBaNumber');

      // Get menu prices for the selected date (same as admin logic)
      final menuDoc = await FirebaseFirestore.instance
          .collection('monthly_menu')
          .doc(dateStr)
          .get();

      final menuData = menuDoc.data();
      final breakfastPrice =
          menuData?['breakfast']?['price']?.toDouble() ?? 0.0;
      final lunchPrice = menuData?['lunch']?['price']?.toDouble() ?? 0.0;
      final dinnerPrice = menuData?['dinner']?['price']?.toDouble() ?? 0.0;

      // Get meal state data for the selected date (same as admin logic)
      final mealStateDoc = await FirebaseFirestore.instance
          .collection('user_meal_state')
          .doc(dateStr)
          .get();

      final mealStateData = mealStateDoc.data() ?? {};
      final userMealState =
          mealStateData[userBaNumber] as Map<String, dynamic>? ?? {};

      // Calculate meal prices based on enrollment (same as admin logic)
      final userBreakfastPrice =
          (userMealState['breakfast'] == true) ? breakfastPrice : 0.0;
      final userLunchPrice =
          (userMealState['lunch'] == true) ? lunchPrice : 0.0;
      final userDinnerPrice =
          (userMealState['dinner'] == true) ? dinnerPrice : 0.0;

      // Default extra_chit and bar to 0.0 for new entries
      final defaultData = {
        'breakfast': userBreakfastPrice,
        'lunch': userLunchPrice,
        'dinner': userDinnerPrice,
        'extra_chit': 0.0,
        'bar': 0.0,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Save the generated data to Firestore (same as admin logic)
      await FirebaseFirestore.instance
          .collection('daily_messing')
          .doc(dateStr)
          .set({
        userBaNumber!: defaultData,
      }, SetOptions(merge: true));

      print('Generated and saved default data for $dateStr: $defaultData');
      return defaultData;
    } catch (e) {
      print('Error generating default data for date $dateStr: $e');
      // Return zero data if generation fails
      return {
        'breakfast': 0.0,
        'lunch': 0.0,
        'dinner': 0.0,
        'extra_chit': 0.0,
        'bar': 0.0,
      };
    }
  }

  Future<void> _fetchOverviewData(User user) async {
    // Keep the old logic for overview data fetching
    print(
        'Starting to fetch messing data for ${_selectedMonth} $_selectedYear');

    // Calculate selected month index for filtering
    final selectedMonthIndex = _months.indexOf(_selectedMonth) + 1;
    final startDate = DateTime(_selectedYear, selectedMonthIndex, 1);
    final endDate = DateTime(_selectedYear, selectedMonthIndex + 1, 0);

    print(
        'Date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

    // More efficient query with timeout
    final querySnapshot = await FirebaseFirestore.instance
        .collection('messing_data')
        .where('userId', isEqualTo: user.uid)
        .limit(100) // Limit results to prevent excessive data loading
        .get()
        .timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Firebase query timeout');
      },
    );

    print('Retrieved ${querySnapshot.docs.length} documents from Firebase');

    List<Map<String, dynamic>> fetchedData = [];
    double monthlyMessingTotal = 0.0;

    for (var doc in querySnapshot.docs) {
      try {
        final data = doc.data();
        final dateStr = data['date'] as String?;

        if (dateStr == null || dateStr.isEmpty) {
          print('Skipping document with null/empty date: ${doc.id}');
          continue;
        }

        DateTime docDate;
        try {
          docDate = DateTime.parse(dateStr);
        } catch (e) {
          print('Error parsing date "$dateStr" in doc ${doc.id}: $e');
          continue;
        }

        // Filter by selected month and year locally
        if (docDate.month == selectedMonthIndex &&
            docDate.year == _selectedYear) {
          final meals = data['meals'] as List<dynamic>? ?? [];

          double dayTotal = 0.0;
          for (var meal in meals) {
            if (meal is Map<String, dynamic>) {
              final price = meal['price'];
              if (price is num) {
                dayTotal += price.toDouble();
              }
            }
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
        print('Error processing document ${doc.id}: $e');
        continue;
      }
    }

    print('Processed ${fetchedData.length} documents for the selected month');

    // Fetch extra chit data with timeout and better error handling
    double extraMessing = 0.0;
    double extraBar = 0.0;

    try {
      // Convert month name to number for more consistent document ID
      final monthNum = selectedMonthIndex.toString().padLeft(2, '0');
      final docId = '${user.uid}_${monthNum}_$_selectedYear';

      print('Fetching extra chit data with document ID: $docId');

      final extraChitDoc = await FirebaseFirestore.instance
          .collection('extra_chits')
          .doc(docId)
          .get()
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Extra chit query timeout');
        },
      );

      if (extraChitDoc.exists) {
        final extraData = extraChitDoc.data();
        if (extraData != null) {
          extraMessing =
              (extraData['extra_messing'] as num?)?.toDouble() ?? 0.0;
          extraBar = (extraData['extra_bar'] as num?)?.toDouble() ?? 0.0;
          print('Found extra chit data: messing=$extraMessing, bar=$extraBar');
        }
      } else {
        print('No extra chit document found for $docId');
      }
    } catch (e) {
      print('Error fetching extra chit data: $e');
      // Continue with default values - don't let this fail the entire operation
    }

    if (mounted) {
      setState(() {
        messingData = fetchedData;
        // Only update these if we're not using daily messing data
        if (dailyMessingData.isEmpty) {
          totalMonthlyMessing = monthlyMessingTotal;
          totalExtraChitMessing = extraMessing;
          totalExtraChitBar = extraBar;
        }
      });
      print('Successfully updated UI with messing data');
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
            SizedBox(height: 8),
            Text(
              'This may take a few seconds',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (messingData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_meals,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No messing data found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'for $_selectedMonth $_selectedYear',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchMessingData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    // Calculate messing totals from Firebase data
    double currentMessBill =
        totalMonthlyMessing + totalExtraChitMessing + totalExtraChitBar;

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
            SizedBox(height: 8),
            Text(
              'Fetching daily messing breakdown...',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (dailyMessingData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_chart,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No daily messing data available',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'for $_selectedMonth $_selectedYear',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            if (userBaNumber == null) ...[
              const SizedBox(height: 8),
              Text(
                'BA Number not found in user profile',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red[400],
                    ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchMessingData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    // Calculate totals from daily messing data
    double totalBreakfast = 0,
        totalLunch = 0,
        totalDinner = 0,
        totalExtraChit = 0,
        totalBarChit = 0;

    for (var dayData in dailyMessingData) {
      totalBreakfast += dayData['breakfast'] as double;
      totalLunch += dayData['lunch'] as double;
      totalDinner += dayData['dinner'] as double;
      totalExtraChit += dayData['extra_chit'] as double;
      totalBarChit += dayData['bar_chit'] as double;
    }

    // Sort daily messing data by date
    dailyMessingData.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );

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
                  'Extra Chit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Bar Chit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: [
              ...dailyMessingData.map((entry) {
                final date = entry['date'] as DateTime;
                final breakfast = entry['breakfast'] as double;
                final lunch = entry['lunch'] as double;
                final dinner = entry['dinner'] as double;
                final extraChit = entry['extra_chit'] as double;
                final barChit = entry['bar_chit'] as double;
                final total = entry['total'] as double;

                // Check if this is a zero day (no messing)
                final isZeroDay = total == 0.0;

                return DataRow(
                  color: isZeroDay
                      ? WidgetStateProperty.all(Colors.grey.shade50)
                      : null,
                  cells: [
                    DataCell(Text(DateFormat('dd-MM-yyyy').format(date))),
                    DataCell(
                      Text(
                        breakfast == 0.0
                            ? '-'
                            : 'BDT ${breakfast.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: breakfast == 0.0 ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        lunch == 0.0 ? '-' : 'BDT ${lunch.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: lunch == 0.0 ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        dinner == 0.0
                            ? '-'
                            : 'BDT ${dinner.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: dinner == 0.0 ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        extraChit == 0.0
                            ? '-'
                            : 'BDT ${extraChit.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: extraChit == 0.0
                              ? Colors.grey
                              : Colors.green.shade700,
                          fontWeight: extraChit > 0
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        barChit == 0.0
                            ? '-'
                            : 'BDT ${barChit.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: barChit == 0.0
                              ? Colors.grey
                              : Colors.orange.shade700,
                          fontWeight:
                              barChit > 0 ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        total == 0.0 ? '-' : 'BDT ${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: total == 0.0 ? Colors.grey : Colors.black,
                          fontWeight:
                              total > 0 ? FontWeight.w500 : FontWeight.normal,
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
                      'TOTAL',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    Text(
                      'BDT ${totalBreakfast.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    Text(
                      'BDT ${totalLunch.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    Text(
                      'BDT ${totalDinner.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    Text(
                      'BDT ${totalExtraChit.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: totalExtraChit > 0
                            ? Colors.green.shade700
                            : Colors.black,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      'BDT ${totalBarChit.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: totalBarChit > 0
                            ? Colors.orange.shade700
                            : Colors.black,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      'BDT ${(totalBreakfast + totalLunch + totalDinner + totalExtraChit + totalBarChit).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
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

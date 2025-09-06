import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_payment_history_screen.dart';
import '../../services/activity_log_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  Future<void> _exportBillPdf() async {
    if (_selectedMonth == null || _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both month and year')),
      );
      return;
    }

    // Show loading dialog with cancel functionality
    bool isCancelled = false;
    late BuildContext dialogContext;

    // Show the loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context;
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 18),
                  Text('Generating your bill PDF...',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.blue[900])),
                  const SizedBox(height: 6),
                  const Text('This may take a few seconds.',
                      style: TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    backgroundColor: Colors.grey,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text('Cancel',
                        style: TextStyle(color: Colors.red)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () {
                      isCancelled = true;
                      Navigator.of(context, rootNavigator: true)
                          .pop('cancelled');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Run PDF generation asynchronously
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _userData == null) {
        if (!isCancelled)
          Navigator.of(dialogContext, rootNavigator: true).pop();
        return;
      }
      final baNo = _userData!['ba_no']?.toString();
      final name = _userData!['name'] ?? '';
      final rank = _userData!['rank'] ?? '';
      final monthYear = '${_selectedMonth!} ${_selectedYear!}';

      // DEBUG: Initial parameters
      print('🔄 PDF GENERATION START');
      print('📅 Month: $_selectedMonth, Year: $_selectedYear');
      print('👤 User - BA No: $baNo, Name: $name, Rank: $rank');
      print('📊 Current Total Due: $_totalDue');
      print('═══════════════════════════════════════');

      // --- OPTIMIZED: Get Bills collection data first (fast), then fetch real daily data ---

      double currentMessBill = 0.0;
      double arrears = 0.0;
      double totalPayable = _totalDue; // Use already-loaded total

      // Get the summarized bill data from Bills collection (FAST - 1 query)
      print('🔍 FETCHING BILLS COLLECTION DATA...');
      final billDoc = await FirebaseFirestore.instance
          .collection('Bills')
          .doc(monthYear)
          .get();

      if (billDoc.exists && baNo != null) {
        final billData = billDoc.data() as Map<String, dynamic>;
        final userBill = billData[baNo] as Map<String, dynamic>?;

        if (userBill != null) {
          currentMessBill = userBill['current_bill']?.toDouble() ?? 0.0;
          arrears = userBill['arrears']?.toDouble() ?? 0.0;
          totalPayable = userBill['total_due']?.toDouble() ?? _totalDue;

          print('✅ Bills Collection Data Found:');
          print('   💰 Current Mess Bill: $currentMessBill');
          print('   🔄 Arrears: $arrears');
          print('   💳 Total Payable: $totalPayable');
        } else {
          print('❌ No user bill data found in Bills collection for BA: $baNo');
        }
      } else {
        print('❌ Bills document not found for month: $monthYear');
      }

      // Now fetch REAL daily messing data (same as user messing screen)
      print('═══════════════════════════════════════');
      print('🔍 FETCHING DAILY MESSING DATA...');
      double totalMonthlyMessing = 0.0,
          totalExtraChitMessing = 0.0,
          totalExtraChitBar = 0.0;
      List<Map<String, dynamic>> dailyMessingData = [];

      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      final selectedMonthIndex = months.indexOf(_selectedMonth!) + 1;
      final startDate = DateTime(_selectedYear!, selectedMonthIndex, 1);
      final endDate = DateTime(_selectedYear!, selectedMonthIndex + 1, 0);
      final today = DateTime.now();
      final actualEndDate =
          (selectedMonthIndex == today.month && _selectedYear == today.year)
              ? today
              : endDate;

      print(
          '📅 Date Range: ${startDate.toString().split(' ')[0]} to ${actualEndDate.toString().split(' ')[0]}');
      print(
          '📊 Expected days to fetch: ${actualEndDate.difference(startDate).inDays + 1}');

      // Fetch real daily data (same logic as user messing screen)
      if (baNo != null) {
        int dayCount = 0;
        for (DateTime date = startDate;
            date.isBefore(actualEndDate.add(const Duration(days: 1)));
            date = date.add(const Duration(days: 1))) {
          // Check for cancellation periodically
          if (isCancelled) {
            print('🚫 PDF generation cancelled by user');
            return;
          }

          dayCount++;
          final dateStr =
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

          final dailyDoc = await FirebaseFirestore.instance
              .collection('daily_messing')
              .doc(dateStr)
              .get();

          Map<String, dynamic>? userDayData;
          if (dailyDoc.exists && dailyDoc.data() != null) {
            final data = dailyDoc.data()!;
            userDayData = data[baNo] as Map<String, dynamic>?;
          }

          if (userDayData == null) {
            userDayData = {
              'breakfast': 0.0,
              'lunch': 0.0,
              'dinner': 0.0,
              'extra_chit': 0.0,
              'bar': 0.0,
            };
            print(
                '⚠️  Day $dayCount ($dateStr): No data found - using defaults');
          } else {
            print('✅ Day $dayCount ($dateStr): Data found');
          }

          final breakfastPrice = userDayData['breakfast']?.toDouble() ?? 0.0;
          final lunchPrice = userDayData['lunch']?.toDouble() ?? 0.0;
          final dinnerPrice = userDayData['dinner']?.toDouble() ?? 0.0;
          final extraChit = userDayData['extra_chit']?.toDouble() ?? 0.0;
          final barChit = userDayData['bar']?.toDouble() ?? 0.0;

          final dayTotal =
              breakfastPrice + lunchPrice + dinnerPrice + extraChit + barChit;

          if (dayTotal > 0) {
            print(
                '   🍽️  B: $breakfastPrice, L: $lunchPrice, D: $dinnerPrice, EC: $extraChit, Bar: $barChit = Total: $dayTotal');
          }

          totalMonthlyMessing += breakfastPrice + lunchPrice + dinnerPrice;
          totalExtraChitMessing += extraChit;
          totalExtraChitBar += barChit;

          dailyMessingData.add({
            'date': date,
            'breakfast': breakfastPrice,
            'lunch': lunchPrice,
            'dinner': dinnerPrice,
            'extra_chit': extraChit,
            'bar_chit': barChit,
            'total':
                breakfastPrice + lunchPrice + dinnerPrice + extraChit + barChit,
          });
        }

        print('📊 DAILY DATA SUMMARY:');
        print('   🍽️  Total Monthly Messing: $totalMonthlyMessing');
        print('   💰 Total Extra Chit Messing: $totalExtraChitMessing');
        print('   🍺 Total Bar Chit: $totalExtraChitBar');
        print('   📝 Total Days Processed: $dayCount');
      }

      // 2. Get misc charges efficiently from misc_entry collection
      print('═══════════════════════════════════════');
      print('🔍 FETCHING MISCELLANEOUS CHARGES...');
      Map<String, double> subscriptionsData = {};
      Map<String, double> regimentalCuttingsData = {};
      Map<String, double> miscellaneousData = {};
      double totalSubscriptions = 0.0;
      double totalCuttings = 0.0;
      double totalMisc = 0.0;

      // Subscriptions
      print('📋 Fetching Subscriptions...');
      final subscriptionsDoc = await FirebaseFirestore.instance
          .collection('misc_entry')
          .doc('Subscriptions')
          .get();
      if (subscriptionsDoc.exists) {
        final data = subscriptionsDoc.data()!;
        subscriptionsData = {
          'Orderly Pay': (data['orderly_pay'] as num?)?.toDouble() ?? 0.0,
          'Mess Maintenance':
              (data['mess_maintenance'] as num?)?.toDouble() ?? 0.0,
          'Garden': (data['garden'] as num?)?.toDouble() ?? 0.0,
          'Newspaper': (data['newspaper'] as num?)?.toDouble() ?? 0.0,
          'Silver': (data['silver'] as num?)?.toDouble() ?? 0.0,
          'Dish Antenna': (data['dish_antenna'] as num?)?.toDouble() ?? 0.0,
          'Sports': (data['sports'] as num?)?.toDouble() ?? 0.0,
          'Breakage Charge':
              (data['breakage_charge'] as num?)?.toDouble() ?? 0.0,
          'Internet Bill': (data['internet_bill'] as num?)?.toDouble() ?? 0.0,
          'Washerman Bill': (data['washerman_bill'] as num?)?.toDouble() ?? 0.0,
        };
        totalSubscriptions = subscriptionsData.values.reduce((a, b) => a + b);
        print('✅ Subscriptions loaded: Total = $totalSubscriptions');
        subscriptionsData.forEach((key, value) {
          if (value > 0) print('   💰 $key: $value');
        });
      } else {
        print('❌ Subscriptions document not found');
      }

      // Regimental Cuttings
      print('📋 Fetching Regimental Cuttings...');
      final regimentalDoc = await FirebaseFirestore.instance
          .collection('misc_entry')
          .doc('Regimental Cuttings')
          .get();
      if (regimentalDoc.exists) {
        final data = regimentalDoc.data()!;
        regimentalCuttingsData = {
          'Regimental Cuttings':
              (data['regimental_cuttings'] as num?)?.toDouble() ?? 0.0,
          'Cantt Sta Sports':
              (data['cantt_sta_sports'] as num?)?.toDouble() ?? 0.0,
          'Mosque': (data['mosque'] as num?)?.toDouble() ?? 0.0,
          'Reunion': (data['reunion'] as num?)?.toDouble() ?? 0.0,
          'Band': (data['band'] as num?)?.toDouble() ?? 0.0,
        };
        totalCuttings = regimentalCuttingsData.values.reduce((a, b) => a + b);
        print('✅ Regimental Cuttings loaded: Total = $totalCuttings');
        regimentalCuttingsData.forEach((key, value) {
          if (value > 0) print('   💰 $key: $value');
        });
      } else {
        print('❌ Regimental Cuttings document not found');
      }

      // Miscellaneous
      print('📋 Fetching Miscellaneous charges...');
      final miscDoc = await FirebaseFirestore.instance
          .collection('misc_entry')
          .doc('Miscellaneous')
          .get();
      if (miscDoc.exists) {
        final data = miscDoc.data()!;
        miscellaneousData = {
          'Misc Bills': (data['miscellaneous'] as num?)?.toDouble() ?? 0.0,
          'Crest': (data['crest'] as num?)?.toDouble() ?? 0.0,
          'Cleaners Bill': (data['cleaners_bill'] as num?)?.toDouble() ?? 0.0,
        };
        totalMisc = miscellaneousData.values.reduce((a, b) => a + b);
        print('✅ Miscellaneous charges loaded: Total = $totalMisc');
        miscellaneousData.forEach((key, value) {
          if (value > 0) print('   💰 $key: $value');
        });
      } else {
        print('❌ Miscellaneous document not found');
      }

      // 4. Calculate final totals for PDF (use optimized data)
      print('═══════════════════════════════════════');
      print('📊 FINAL CALCULATIONS FOR PDF:');
      print('🍽️  Monthly Messing: $totalMonthlyMessing');
      print('💰 Extra Chit Messing: $totalExtraChitMessing');
      print('🍺 Bar Chit: $totalExtraChitBar');
      print('📋 Subscriptions Total: $totalSubscriptions');
      print('🏛️  Regimental Cuttings Total: $totalCuttings');
      print('📄 Miscellaneous Total: $totalMisc');
      print('💳 Current Mess Bill: $currentMessBill');
      print('🔄 Arrears: $arrears');
      print('💰 Total Payable: $totalPayable');
      print('═══════════════════════════════════════');

      // Check for cancellation before building PDF
      if (isCancelled) {
        print('🚫 PDF generation cancelled before building PDF');
        return;
      }

      // --- Build PDF ---
      print('🔧 BUILDING PDF DOCUMENT...');
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Mess Bill for $monthYear',
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Name: $name   |   Rank: $rank   |   BA No: $baNo'),
                pw.SizedBox(height: 12),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildOverviewTablePdf(
                              totalMonthlyMessing,
                              totalExtraChitMessing,
                              totalExtraChitBar,
                              totalSubscriptions,
                              subscriptionsData,
                              totalCuttings,
                              regimentalCuttingsData,
                              totalMisc,
                              miscellaneousData,
                              currentMessBill,
                              arrears,
                              totalPayable),
                          pw.SizedBox(height: 18),
                          pw.Text('Notes:',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.Bullet(
                              text:
                                  'Please pay your bill within 7th of the month.',
                              style: pw.TextStyle(fontSize: 8)),
                          pw.Bullet(
                              text: 'Contact: 01616859503',
                              style: pw.TextStyle(fontSize: 8)),
                          pw.Bullet(
                              text: 'Maintain a healthy diet and lifestyle.',
                              style: pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      flex: 6,
                      child: _buildDetailTablePdf(dailyMessingData),
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('User Signature',
                            style: pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: 24),
                        pw.Container(
                            width: 80, height: 0.5, color: PdfColors.black),
                      ],
                    ),
                    pw.SizedBox(width: 40),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('Mess Secretary',
                            style: pw.TextStyle(fontSize: 9)),
                        pw.SizedBox(height: 24),
                        pw.Container(
                            width: 80, height: 0.5, color: PdfColors.black),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());

      print('✅ PDF GENERATION COMPLETED SUCCESSFULLY!');
      print('═══════════════════════════════════════');
    } catch (e) {
      print('❌ PDF GENERATION ERROR: $e');
      if (!isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      // Close the dialog if it's still open and not cancelled
      if (!isCancelled) {
        try {
          Navigator.of(dialogContext, rootNavigator: true).pop();
        } catch (e) {
          // Dialog might already be closed
          print('Dialog already closed or error closing: $e');
        }
      }
    }
  }

  pw.Widget _buildOverviewTablePdf(
    double totalMonthlyMessing,
    double totalExtraChitMessing,
    double totalExtraChitBar,
    double totalSubscriptions,
    Map<String, double> subscriptionsData,
    double totalCuttings,
    Map<String, double> regimentalCuttingsData,
    double totalMisc,
    Map<String, double> miscellaneousData,
    double currentMessBill,
    double arrears,
    double totalPayable,
  ) {
    print('🔧 Building Overview Table PDF with data:');
    print('   🍽️  Monthly Messing: $totalMonthlyMessing');
    print('   💰 Extra Chit Messing: $totalExtraChitMessing');
    print('   🍺 Bar Chit: $totalExtraChitBar');
    print('   📋 Subscriptions entries: ${subscriptionsData.length}');
    print('   🏛️  Regimental entries: ${regimentalCuttingsData.length}');
    print('   📄 Misc entries: ${miscellaneousData.length}');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Messing',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              pw.Container()
            ]),
            pw.TableRow(children: [
              pw.Text('Monthly Messing Total'),
              pw.Text(totalMonthlyMessing.toStringAsFixed(2))
            ]),
            pw.TableRow(children: [
              pw.Text('Extra Chit (Messing)'),
              pw.Text(totalExtraChitMessing.toStringAsFixed(2))
            ]),
            pw.TableRow(children: [
              pw.Text('Extra Chit (Bar)'),
              pw.Text(totalExtraChitBar.toStringAsFixed(2))
            ]),
            pw.TableRow(children: [
              pw.Text('Total Bill',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(
                  (totalMonthlyMessing +
                          totalExtraChitMessing +
                          totalExtraChitBar)
                      .toStringAsFixed(2),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold))
            ]),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Subscriptions',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              pw.Container()
            ]),
            ...subscriptionsData.entries
                .map((e) => pw.TableRow(children: [
                      pw.Text(e.key),
                      pw.Text(e.value.toStringAsFixed(2))
                    ]))
                .toList(),
            pw.TableRow(children: [
              pw.Text('Total Subscription',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(totalSubscriptions.toStringAsFixed(2),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold))
            ]),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Regimental Cuttings',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              pw.Container()
            ]),
            ...regimentalCuttingsData.entries
                .map((e) => pw.TableRow(children: [
                      pw.Text(e.key),
                      pw.Text(e.value.toStringAsFixed(2))
                    ]))
                .toList(),
            pw.TableRow(children: [
              pw.Text('Total Regimental Cuttings',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(totalCuttings.toStringAsFixed(2),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold))
            ]),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Miscellaneous',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              pw.Container()
            ]),
            ...miscellaneousData.entries
                .map((e) => pw.TableRow(children: [
                      pw.Text(e.key),
                      pw.Text(e.value.toStringAsFixed(2))
                    ]))
                .toList(),
            pw.TableRow(children: [
              pw.Text('Total Miscellaneous',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(totalMisc.toStringAsFixed(2),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold))
            ]),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Bill Payable',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              pw.Container()
            ]),
            pw.TableRow(children: [
              pw.Text('Current Mess Bill'),
              pw.Text(currentMessBill.toStringAsFixed(2))
            ]),
            pw.TableRow(children: [
              pw.Text('Arrears till now'),
              pw.Text(arrears.toStringAsFixed(2))
            ]),
            pw.TableRow(children: [
              pw.Text('Total Payable',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(totalPayable.toStringAsFixed(2),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold))
            ]),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildDetailTablePdf(List<Map<String, dynamic>> dailyMessingData) {
    print(
        '🔧 Building Detail Table PDF with ${dailyMessingData.length} days of data');

    // Calculate and log summary statistics
    double totalDays = dailyMessingData.length.toDouble();
    double daysWithData = dailyMessingData
        .where((day) => (day['total'] as double) > 0)
        .length
        .toDouble();
    double totalAmount = dailyMessingData.fold(
        0.0, (sum, day) => sum + (day['total'] as double));

    print('   📊 Days with data: $daysWithData / $totalDays');
    print('   💰 Total amount in detail table: $totalAmount');

    final dataRows = dailyMessingData
        .map((day) => [
              DateFormat('dd MMM').format(day['date'] as DateTime),
              (day['breakfast'] as double).toStringAsFixed(2),
              (day['lunch'] as double).toStringAsFixed(2),
              (day['dinner'] as double).toStringAsFixed(2),
              (day['extra_chit'] as double).toStringAsFixed(2),
              (day['bar_chit'] as double).toStringAsFixed(2),
              (day['total'] as double).toStringAsFixed(2),
            ])
        .toList();
    // Calculate totals
    double totalBreakfast = 0,
        totalLunch = 0,
        totalDinner = 0,
        totalExtras = 0,
        totalBar = 0;
    for (var day in dailyMessingData) {
      totalBreakfast += (day['breakfast'] as double);
      totalLunch += (day['lunch'] as double);
      totalDinner += (day['dinner'] as double);
      totalExtras += (day['extra_chit'] as double);
      totalBar += (day['bar_chit'] as double);
    }
    dataRows.add([
      'Total',
      totalBreakfast.toStringAsFixed(2),
      totalLunch.toStringAsFixed(2),
      totalDinner.toStringAsFixed(2),
      totalExtras.toStringAsFixed(2),
      totalBar.toStringAsFixed(2),
      '',
    ]);
    return pw.Table.fromTextArray(
      headers: [
        'Date',
        'Breakfast',
        'Lunch',
        'Dinner',
        'Extras',
        'Bar',
        'Total'
      ],
      data: dataRows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.center,
      border: pw.TableBorder.all(),
    );
  }

  String? _selectedMonth;
  int? _selectedYear;
  bool _paymentSuccess = false;
  bool _isSubmitting = false;

  // Controllers for payment forms
  final Map<String, TextEditingController> _controllers = {
    'phone': TextEditingController(),
    'transactionId': TextEditingController(),
    'amount': TextEditingController(),
    'accountNo': TextEditingController(),
    'bankName': TextEditingController(),
    'cardNumber': TextEditingController(),
    'expiryDate': TextEditingController(),
    'cvv': TextEditingController(),
  };

  // User data
  Map<String, dynamic>? _userData;
  double _totalDue = 0.0;
  bool _isLoadingBill = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserData();
    await _loadCurrentBill();
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('user_requests')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadCurrentBill() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _totalDue = 0.0;
          _isLoadingBill = false;
        });
        return;
      }

      // Use the already loaded user data
      if (_userData == null) {
        setState(() {
          _totalDue = 0.0;
          _isLoadingBill = false;
        });
        return;
      }

      final baNo = _userData!['ba_no']?.toString();

      if (baNo == null) {
        setState(() {
          _totalDue = 0.0;
          _isLoadingBill = false;
        });
        return;
      }

      // Get current month's bill
      final now = DateTime.now();
      final monthYear = "${_getMonthName(now.month)} ${now.year}";

      final billDoc = await FirebaseFirestore.instance
          .collection('Bills')
          .doc(monthYear)
          .get();

      if (billDoc.exists) {
        final billData = billDoc.data() as Map<String, dynamic>;
        final userBill = billData[baNo] as Map<String, dynamic>?;

        if (userBill != null) {
          // Calculate current total due using the same logic as home screen
          final currentBill = userBill['current_bill']?.toDouble() ?? 0.0;
          final arrears = userBill['arrears']?.toDouble() ?? 0.0;
          final paidAmount = userBill['paid_amount']?.toDouble() ?? 0.0;
          final calculatedTotalDue = currentBill + arrears - paidAmount;

          setState(() {
            _totalDue = calculatedTotalDue > 0 ? calculatedTotalDue : 0.0;
            _isLoadingBill = false;
          });
        } else {
          setState(() {
            _totalDue = 0.0;
            _isLoadingBill = false;
          });
        }
      } else {
        setState(() {
          _totalDue = 0.0;
          _isLoadingBill = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading current bill: $e');
      setState(() {
        _totalDue = 0.0;
        _isLoadingBill = false;
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final int currentYear = DateTime.now().year;

  void _showPaymentModal(String method) {
    // Clear controllers
    _controllers.forEach((key, controller) => controller.clear());
    _controllers['amount']!.text = _totalDue.toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 216, 216, 216),
        title: Text(
          'Enter $method Payment Details',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Colors.black,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              if (method == 'bKash' || method == 'Tap') ...[
                _buildInputField('Phone Number',
                    controller: _controllers['phone']!),
                _buildInputField('Transaction ID',
                    controller: _controllers['transactionId']!),
                _buildInputField('Amount',
                    controller: _controllers['amount']!, isNumber: true),
              ] else if (method == 'Bank') ...[
                _buildInputField('Bank Account No',
                    controller: _controllers['accountNo']!),
                _buildInputField('Bank Name',
                    controller: _controllers['bankName']!),
                _buildInputField('Amount',
                    controller: _controllers['amount']!, isNumber: true),
              ] else if (method == 'Card') ...[
                _buildInputField('Card Number',
                    controller: _controllers['cardNumber']!),
                _buildInputField('Expiry Date',
                    controller: _controllers['expiryDate']!),
                _buildInputField('CVV',
                    controller: _controllers['cvv']!, isNumber: true),
                _buildInputField('Amount',
                    controller: _controllers['amount']!, isNumber: true),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed:
                _isSubmitting ? null : () => _submitPaymentRequest(method),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 7, 125, 21),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Submit', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _submitPaymentRequest(String method) async {
    if (_userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('User data not found'), backgroundColor: Colors.red),
      );
      return;
    }

    // Validate form
    final amount = double.tryParse(_controllers['amount']!.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid amount'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final baNo = _userData!['ba_no']?.toString();
      final timestamp = DateTime.now();

      // Create payment request data
      Map<String, dynamic> paymentData = {
        'amount': amount,
        'payment_method': method,
        'ba_no': baNo,
        'rank': _userData!['rank'],
        'name': _userData!['name'],
        'status': 'pending',
        'request_time': timestamp,
      };

      // Add method-specific details
      if (method == 'bKash' || method == 'Tap') {
        paymentData['phone_number'] = _controllers['phone']!.text;
        paymentData['transaction_id'] = _controllers['transactionId']!.text;
      } else if (method == 'Bank') {
        paymentData['account_no'] = _controllers['accountNo']!.text;
        paymentData['bank_name'] = _controllers['bankName']!.text;
      } else if (method == 'Card') {
        paymentData['card_number'] = _controllers['cardNumber']!.text;
        paymentData['expiry_date'] = _controllers['expiryDate']!.text;
        paymentData['cvv'] = _controllers['cvv']!.text;
      }

      // Get existing payment history
      final paymentHistoryRef =
          FirebaseFirestore.instance.collection('payment_history').doc(baNo);

      final paymentDoc = await paymentHistoryRef.get();

      // Create transaction entry with auto-incrementing number
      String dateKey =
          "${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}";

      Map<String, dynamic> existingData = {};
      if (paymentDoc.exists) {
        existingData = paymentDoc.data() as Map<String, dynamic>;
      }

      // Find next transaction number for this date
      int transactionNumber = 1;
      while (existingData
          .containsKey('${dateKey}_transaction_$transactionNumber')) {
        transactionNumber++;
      }

      String transactionKey = '${dateKey}_transaction_$transactionNumber';

      // Save payment request
      await paymentHistoryRef.set({
        transactionKey: paymentData,
      }, SetOptions(merge: true));

      Navigator.pop(context);
      setState(() {
        _paymentSuccess = true;
        _isSubmitting = false;
      });

      // Log activity
      await ActivityLogService.log(
        'Bill Payment Request',
        details: {
          'amount': amount,
          'method': method,
          'timestamp': timestamp.toIso8601String(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Payment request submitted! Amount: ৳${amount.toStringAsFixed(2)}"),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error submitting payment: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildInputField(String label,
      {bool isNumber = false,
      String? initialValue,
      TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller ??
            (initialValue != null
                ? TextEditingController(text: initialValue)
                : null),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white 
              : Colors.black,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white70 
                : Colors.black54,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white54 
                  : Colors.black54,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white54 
                  : Colors.black54,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.blue,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.history, size: 20),
                    label: const Text('Payment History',
                        style: TextStyle(fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color.fromARGB(255, 128, 142, 107),
                      side: const BorderSide(color: Color(0xFF002B5B)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserPaymentHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_paymentSuccess)
                Card(
                  color: Colors.green.shade50,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Payment Request Submitted!",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                  "Your payment request has been sent to admin for approval."),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Card(
                color: Colors.red.shade50,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt, color: Colors.red, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Total Due",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red)),
                            const SizedBox(height: 4),
                            _isLoadingBill
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text("৳ ${_totalDue.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Select Payment Method",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Column(
                children: [
                  _paymentMethodCard("bKash", 'assets/bkash.png'),
                  _paymentMethodCard("Bank", 'assets/bank.png'),
                  _paymentMethodCard("Tap", 'assets/Tap.png'),
                  _paymentMethodCard("Card", 'assets/card.png'),
                ],
              ),
              const SizedBox(height: 30),
              const Text("View Your Mess Bill",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedMonth,
                items: _months
                    .map((month) =>
                        DropdownMenuItem(value: month, child: Text(month)))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: "Select Month",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _selectedMonth = value),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _selectedYear,
                items: List.generate(6, (i) => currentYear - i)
                    .map((year) => DropdownMenuItem(
                        value: year, child: Text(year.toString())))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: "Select Year",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _selectedYear = value),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _exportBillPdf,
                borderRadius: BorderRadius.circular(10),
                splashColor: Colors.blue.shade100,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Export PDF",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentMethodCard(String method, String? iconPath) {
    return InkWell(
      onTap: () => _showPaymentModal(method),
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.blue.shade100,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color.fromARGB(255, 131, 144, 162), Color(0xFFE8EEF5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 6,
              offset: Offset(2, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (iconPath != null) ...[
                Image.asset(iconPath, height: 36, width: 36),
                const SizedBox(width: 16),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text("Make payment through $method"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

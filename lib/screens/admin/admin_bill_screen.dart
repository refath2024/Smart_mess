import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
import 'admin_home_screen.dart';
import 'admin_users_screen.dart';
import 'admin_pending_ids_screen.dart';
import 'admin_shopping_history.dart';
import 'admin_voucher_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_messing_screen.dart';
import 'admin_staff_state_screen.dart';
import 'admin_dining_member_state.dart';
import 'admin_payment_history.dart';
import 'admin_meal_state_screen.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_menu_vote_screen.dart';
import 'admin_login_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/admin_auth_service.dart';
import 'dart:async';

class AdminBillScreen extends StatefulWidget {
  const AdminBillScreen({super.key});

  @override
  State<AdminBillScreen> createState() => _AdminBillScreenState();
}

class _AdminBillScreenState extends State<AdminBillScreen> {
  final AdminAuthService _adminAuthService = AdminAuthService();

  bool _isLoading = true;
  bool _isGenerating = false;
  String _currentUserName = "Admin User";
  Map<String, dynamic>? _currentUserData;

  // Month and Year selection
  final List<String> _months = List.generate(
    12,
    (i) => DateFormat('MMMM').format(DateTime(0, i + 1)),
  );

  late String _selectedMonth;
  late int _selectedYear;

  List<Map<String, dynamic>> bills = [];
  List<Map<String, dynamic>> filteredBills = [];
  String searchTerm = "";

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateFormat('MMMM').format(now);
    _selectedYear = now.year;

    _checkAuthentication();
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

        // Load existing bills for current month/year
        await _loadBills();
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

  // Load bills from Firebase for selected month/year
  Future<void> _loadBills() async {
    try {
      setState(() {
        _isLoading = true;
      });

      String monthYear = '$_selectedMonth $_selectedYear';

      DocumentSnapshot billDoc = await FirebaseFirestore.instance
          .collection('Bills')
          .doc(monthYear)
          .get();

      List<Map<String, dynamic>> loadedBills = [];

      if (billDoc.exists) {
        Map<String, dynamic> data = billDoc.data() as Map<String, dynamic>;

        // Get all user data to fetch names and ranks
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('user_requests')
            .where('approved', isEqualTo: true)
            .where('status', isEqualTo: 'active')
            .get();

        Map<String, Map<String, dynamic>> userDataMap = {};
        for (var doc in userSnapshot.docs) {
          final userData = doc.data() as Map<String, dynamic>;
          final baNo = userData['ba_no']?.toString();
          if (baNo != null) {
            userDataMap[baNo] = userData;
          }
        }

        // Process bill data
        for (String baNo in data.keys) {
          final billData = data[baNo] as Map<String, dynamic>;
          final userData = userDataMap[baNo];

          loadedBills.add({
            'ba_no': baNo,
            'rank': userData?['rank'] ?? 'Unknown',
            'name': userData?['name'] ?? 'Unknown',
            'current_bill': billData['current_bill']?.toDouble() ?? 0.0,
            'arrears': billData['arrears']?.toDouble() ?? 0.0,
            'total_due': billData['total_due']?.toDouble() ?? 0.0,
            'bill_status': billData['bill_status'] ?? 'Unpaid',
          });
        }
      }

      setState(() {
        bills = loadedBills;
        filteredBills = List.from(bills);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading bills: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading bills: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Generate bills for all users
  Future<void> _generateBills() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      String monthYear = '$_selectedMonth $_selectedYear';

      // Get all active users
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('user_requests')
          .where('approved', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .get();

      Map<String, Map<String, dynamic>> newBills = {};

      // Get last month's data for arrears calculation
      DateTime currentDate =
          DateTime(_selectedYear, _months.indexOf(_selectedMonth) + 1);
      DateTime lastMonth = DateTime(currentDate.year, currentDate.month - 1);
      String lastMonthYear =
          '${DateFormat('MMMM').format(lastMonth)} ${lastMonth.year}';

      DocumentSnapshot lastMonthDoc = await FirebaseFirestore.instance
          .collection('Bills')
          .doc(lastMonthYear)
          .get();

      Map<String, double> lastMonthArrears = {};
      if (lastMonthDoc.exists) {
        Map<String, dynamic> lastMonthData =
            lastMonthDoc.data() as Map<String, dynamic>;
        for (String baNo in lastMonthData.keys) {
          final lastBillData = lastMonthData[baNo] as Map<String, dynamic>;
          if (lastBillData['bill_status'] == 'Unpaid') {
            lastMonthArrears[baNo] =
                lastBillData['total_due']?.toDouble() ?? 0.0;
          }
        }
      }

      // Generate bill for each user
      for (var userDoc in userSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final userId = userDoc.id;
        final baNo = userData['ba_no']?.toString();

        if (baNo == null) continue;

        // Calculate total payable using the same logic as user_messing_screen.dart
        double totalPayable = await _calculateUserTotalPayable(userId);
        double arrears = lastMonthArrears[baNo] ?? 0.0;
        double totalDue = totalPayable + arrears;

        newBills[baNo] = {
          'current_bill': totalPayable,
          'arrears': arrears,
          'total_due': totalDue,
          'bill_status': 'Unpaid',
          'generated_at': FieldValue.serverTimestamp(),
        };
      }

      // Save to Firebase
      await FirebaseFirestore.instance
          .collection('Bills')
          .doc(monthYear)
          .set(newBills, SetOptions(merge: true));

      // Reload bills
      await _loadBills();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Bills generated successfully for ${newBills.length} users'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error generating bills: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating bills: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  // Calculate total payable for a user (same logic as user_messing_screen.dart)
  Future<double> _calculateUserTotalPayable(String userId) async {
    try {
      // Get user's BA number
      String? userBaNumber;
      final userDoc = await FirebaseFirestore.instance
          .collection('user_requests')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        userBaNumber = userData?['ba_no']?.toString();
      }

      if (userBaNumber == null) return 0.0;

      // Calculate daily messing totals
      double totalMonthlyMessing = 0.0;
      double totalExtraChitMessing = 0.0;
      double totalExtraChitBar = 0.0;

      final selectedMonthIndex = _months.indexOf(_selectedMonth) + 1;
      final startDate = DateTime(_selectedYear, selectedMonthIndex, 1);
      final endDate = DateTime(_selectedYear, selectedMonthIndex + 1, 0);
      final today = DateTime.now();

      final actualEndDate =
          (selectedMonthIndex == today.month && _selectedYear == today.year)
              ? today
              : endDate;

      // Fetch daily messing data
      for (DateTime date = startDate;
          date.isBefore(actualEndDate.add(const Duration(days: 1)));
          date = date.add(const Duration(days: 1))) {
        final dateStr =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        try {
          final dailyDoc = await FirebaseFirestore.instance
              .collection('daily_messing')
              .doc(dateStr)
              .get();

          Map<String, dynamic>? userDayData;

          if (dailyDoc.exists && dailyDoc.data() != null) {
            final data = dailyDoc.data()!;
            userDayData = data[userBaNumber] as Map<String, dynamic>?;
          }

          if (userDayData == null) {
            userDayData =
                await _generateDefaultDataForDate(dateStr, userBaNumber);
          }

          final breakfastPrice = userDayData['breakfast']?.toDouble() ?? 0.0;
          final lunchPrice = userDayData['lunch']?.toDouble() ?? 0.0;
          final dinnerPrice = userDayData['dinner']?.toDouble() ?? 0.0;
          final extraChit = userDayData['extra_chit']?.toDouble() ?? 0.0;
          final barChit = userDayData['bar']?.toDouble() ?? 0.0;

          totalMonthlyMessing += breakfastPrice + lunchPrice + dinnerPrice;
          totalExtraChitMessing += extraChit;
          totalExtraChitBar += barChit;
        } catch (e) {
          print('Error processing date $dateStr for user $userBaNumber: $e');
        }
      }

      // Fetch miscellaneous charges
      double totalSubscriptions = 0.0;
      double totalCuttings = 0.0;
      double totalMisc = 0.0;

      try {
        // Fetch Subscriptions
        final subscriptionsDoc = await FirebaseFirestore.instance
            .collection('misc_entry')
            .doc('Subscriptions')
            .get();

        if (subscriptionsDoc.exists) {
          final data = subscriptionsDoc.data()!;
          totalSubscriptions = (data['orderly_pay'] as num?)?.toDouble() ?? 0.0;
          totalSubscriptions +=
              (data['mess_maintenance'] as num?)?.toDouble() ?? 0.0;
          totalSubscriptions += (data['garden'] as num?)?.toDouble() ?? 0.0;
          totalSubscriptions += (data['newspaper'] as num?)?.toDouble() ?? 0.0;
          totalSubscriptions += (data['silver'] as num?)?.toDouble() ?? 0.0;
          totalSubscriptions +=
              (data['dish_antenna'] as num?)?.toDouble() ?? 0.0;
          totalSubscriptions += (data['sports'] as num?)?.toDouble() ?? 0.0;
          totalSubscriptions +=
              (data['breakage_charge'] as num?)?.toDouble() ?? 0.0;
          totalSubscriptions +=
              (data['internet_bill'] as num?)?.toDouble() ?? 0.0;
          totalSubscriptions +=
              (data['washerman_bill'] as num?)?.toDouble() ?? 0.0;
        }

        // Fetch Regimental Cuttings
        final regimentalDoc = await FirebaseFirestore.instance
            .collection('misc_entry')
            .doc('Regimental Cuttings')
            .get();

        if (regimentalDoc.exists) {
          final data = regimentalDoc.data()!;
          totalCuttings =
              (data['regimental_cuttings'] as num?)?.toDouble() ?? 0.0;
          totalCuttings +=
              (data['cantt_sta_sports'] as num?)?.toDouble() ?? 0.0;
          totalCuttings += (data['mosque'] as num?)?.toDouble() ?? 0.0;
          totalCuttings += (data['reunion'] as num?)?.toDouble() ?? 0.0;
          totalCuttings += (data['band'] as num?)?.toDouble() ?? 0.0;
        }

        // Fetch Miscellaneous
        final miscDoc = await FirebaseFirestore.instance
            .collection('misc_entry')
            .doc('Miscellaneous')
            .get();

        if (miscDoc.exists) {
          final data = miscDoc.data()!;
          totalMisc = (data['miscellaneous'] as num?)?.toDouble() ?? 0.0;
          totalMisc += (data['crest'] as num?)?.toDouble() ?? 0.0;
          totalMisc += (data['cleaners_bill'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (e) {
        print('Error fetching miscellaneous charges: $e');
      }

      // Calculate total payable (same as user_messing_screen.dart logic)
      double messingBill =
          totalMonthlyMessing + totalExtraChitMessing + totalExtraChitBar;
      double currentMessBill =
          messingBill + totalSubscriptions + totalCuttings + totalMisc;

      return currentMessBill;
    } catch (e) {
      print('Error calculating total payable for user $userId: $e');
      return 0.0;
    }
  }

  // Generate default data for a date (same as user screen logic)
  Future<Map<String, dynamic>> _generateDefaultDataForDate(
      String dateStr, String userBaNumber) async {
    try {
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
      final userMealState =
          mealStateData[userBaNumber] as Map<String, dynamic>? ?? {};

      // Calculate meal prices based on enrollment
      final userBreakfastPrice =
          (userMealState['breakfast'] == true) ? breakfastPrice : 0.0;
      final userLunchPrice =
          (userMealState['lunch'] == true) ? lunchPrice : 0.0;
      final userDinnerPrice =
          (userMealState['dinner'] == true) ? dinnerPrice : 0.0;

      final defaultData = {
        'breakfast': userBreakfastPrice,
        'lunch': userLunchPrice,
        'dinner': userDinnerPrice,
        'extra_chit': 0.0,
        'bar': 0.0,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Save the generated data to Firestore
      await FirebaseFirestore.instance
          .collection('daily_messing')
          .doc(dateStr)
          .set({
        userBaNumber: defaultData,
      }, SetOptions(merge: true));

      return defaultData;
    } catch (e) {
      print('Error generating default data for date $dateStr: $e');
      return {
        'breakfast': 0.0,
        'lunch': 0.0,
        'dinner': 0.0,
        'extra_chit': 0.0,
        'bar': 0.0,
      };
    }
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
    return ListTile(
      selected: selected,
      selectedTileColor: Colors.blue.shade100,
      leading: Icon(
        icon,
        color: color ?? (selected ? Colors.blue : Colors.black),
      ),
      title: Text(title, style: TextStyle(color: color ?? Colors.black)),
      onTap: onTap,
    );
  }

  // Helper method to build flag toggle
  Widget _buildFlagToggle(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return GestureDetector(
          onTap: () {
            languageProvider.changeLanguage(
                languageProvider.currentLocale.languageCode == 'en'
                    ? const Locale('bn')
                    : const Locale('en'));
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: CustomPaint(
              size: const Size(32, 20),
              painter: languageProvider.currentLocale.languageCode == 'en'
                  ? BangladeshFlagPainter()
                  : EnglandFlagPainter(),
            ),
          ),
        );
      },
    );
  }

  void _filterBills(String query) {
    setState(() {
      filteredBills = bills.where((bill) {
        final combined =
            (bill['ba_no'] + bill['rank'] + bill['name']).toLowerCase();
        return combined.contains(query.toLowerCase());
      }).toList();
    });
  }

  // Update bill status (Paid/Unpaid)
  Future<void> _updateBillStatus(String baNo, String newStatus) async {
    try {
      String monthYear = '$_selectedMonth $_selectedYear';

      await FirebaseFirestore.instance
          .collection('Bills')
          .doc(monthYear)
          .update({
        '$baNo.bill_status': newStatus,
      });

      await _loadBills();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating bill status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Generate PDF for individual user bill
  Future<void> _generateUserBillPdf(Map<String, dynamic> billData) async {
    try {
      // Simple PDF generation for now
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'MESS BILL',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Text('BA No: ${billData['ba_no']}'),
                pw.Text('Rank: ${billData['rank']}'),
                pw.Text('Name: ${billData['name']}'),
                pw.Text('Month: $_selectedMonth $_selectedYear'),
                pw.SizedBox(height: 20),
                pw.Text(
                    'Current Bill: ৳${billData['current_bill'].toStringAsFixed(2)}'),
                pw.Text('Arrears: ৳${billData['arrears'].toStringAsFixed(2)}'),
                pw.Text(
                    'Total Due: ৳${billData['total_due'].toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        // Show loading screen while checking authentication
        if (_isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final filteredBills = bills.where((bill) {
          final combined =
              (bill['ba_no'] + bill['rank'] + bill['name']).toLowerCase();
          return combined.contains(searchTerm.toLowerCase());
        }).toList();

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
                                'BA: ${_currentUserData!['ba_no'] ?? ''}',
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
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminMessingScreen(),
                            ),
                          );
                        },
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
                        selected: true,
                        onTap: () => Navigator.pop(context),
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
              AppLocalizations.of(context)!.bills,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            actions: [
              _buildFlagToggle(context),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Month/Year selector and Generate button
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _selectedMonth,
                      items: _months
                          .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedMonth = val);
                          _loadBills();
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<int>(
                      value: _selectedYear,
                      items: List.generate(5, (i) => DateTime.now().year - i)
                          .map((y) => DropdownMenuItem(
                              value: y, child: Text(y.toString())))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedYear = val);
                          _loadBills();
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isGenerating ? null : _generateBills,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF002B5B),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                      ),
                      child: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Generate Bills',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search bar
                Row(
                  children: [
                    SizedBox(
                      width: 300,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() => searchTerm = val);
                          _filterBills(val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Total Bills: ${filteredBills.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Table
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 1010, // Total width of all columns
                        child: Column(
                          children: [
                            // Fixed Table Header
                            Container(
                              height: 56,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1A4D8F),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                children: const [
                                  SizedBox(
                                    width: 100,
                                    child: Center(
                                      child: Text(
                                        'BA No',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: Center(
                                      child: Text(
                                        'Rank',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 150,
                                    child: Center(
                                      child: Text(
                                        'Name',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: Center(
                                      child: Text(
                                        'Status',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: Center(
                                      child: Text(
                                        'Arrears',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: Center(
                                      child: Text(
                                        'Current Bill',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: Center(
                                      child: Text(
                                        'Total Due',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Center(
                                      child: Text(
                                        'Actions',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Scrollable Table Body
                            Expanded(
                              child: filteredBills.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.receipt_long,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No bills found',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Click "Generate Bills" to create bills for all users',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      child: Column(
                                        children: List.generate(
                                            filteredBills.length, (index) {
                                          final bill = filteredBills[index];
                                          final isEven = index % 2 == 0;

                                          return Container(
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: isEven
                                                  ? Colors.grey.shade50
                                                  : Colors.white,
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey.shade200,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 100,
                                                  child: Center(
                                                    child: Text(
                                                      bill['ba_no'] ?? '',
                                                      style: const TextStyle(
                                                          fontSize: 14),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 120,
                                                  child: Center(
                                                    child: Text(
                                                      bill['rank'] ?? '',
                                                      style: const TextStyle(
                                                          fontSize: 14),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 150,
                                                  child: Center(
                                                    child: Text(
                                                      bill['name'] ?? '',
                                                      style: const TextStyle(
                                                          fontSize: 14),
                                                      textAlign:
                                                          TextAlign.center,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 120,
                                                  child: Center(
                                                    child:
                                                        DropdownButton<String>(
                                                      value:
                                                          bill['bill_status'],
                                                      items: const [
                                                        DropdownMenuItem(
                                                            value: 'Paid',
                                                            child:
                                                                Text('Paid')),
                                                        DropdownMenuItem(
                                                            value: 'Unpaid',
                                                            child:
                                                                Text('Unpaid')),
                                                      ],
                                                      onChanged: (newStatus) {
                                                        if (newStatus != null) {
                                                          _updateBillStatus(
                                                              bill['ba_no'],
                                                              newStatus);
                                                        }
                                                      },
                                                      underline: Container(),
                                                      style: TextStyle(
                                                        color:
                                                            bill['bill_status'] ==
                                                                    'Paid'
                                                                ? Colors.green
                                                                : Colors.red,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 120,
                                                  child: Center(
                                                    child: Text(
                                                      '৳${bill['arrears'].toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                          fontSize: 14),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 120,
                                                  child: Center(
                                                    child: Text(
                                                      '৳${bill['current_bill'].toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                          fontSize: 14),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 120,
                                                  child: Center(
                                                    child: Text(
                                                      '৳${bill['total_due'].toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 100,
                                                  child: Center(
                                                    child: IconButton(
                                                      icon: const Icon(
                                                        Icons.picture_as_pdf,
                                                        color: Colors.red,
                                                        size: 20,
                                                      ),
                                                      onPressed: () =>
                                                          _generateUserBillPdf(
                                                              bill),
                                                      tooltip: 'Generate PDF',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Flag painter classes
class EnglandFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint whitePaint = Paint()..color = Colors.white;
    final Paint redPaint = Paint()..color = Colors.red;

    // White background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), whitePaint);

    // Red cross
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.4, 0, size.width * 0.2, size.height),
        redPaint);
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.2),
        redPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class BangladeshFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint greenPaint = Paint()..color = const Color(0xFF006A4E);
    final Paint redPaint = Paint()..color = const Color(0xFFF42A41);

    // Green background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), greenPaint);

    // Red circle (offset slightly to the left)
    final double radius = size.height * 0.3;
    final Offset center = Offset(size.width * 0.4, size.width * 0.5);
    canvas.drawCircle(center, radius, redPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/language_provider.dart';
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
import 'admin_bill_screen.dart';
import 'add_menu_set.dart';
import 'admin_login_screen.dart';
import '../../services/admin_auth_service.dart';

class MenuVoteScreen extends StatefulWidget {
  const MenuVoteScreen({super.key});

  @override
  State<MenuVoteScreen> createState() => _MenuVoteScreenState();
}

class _MenuVoteScreenState extends State<MenuVoteScreen> {
  final AdminAuthService _adminAuthService = AdminAuthService();

  bool _isLoading = true;
  String _currentUserName = "Admin User"; // This is just a fallback, will be updated from Firebase
  Map<String, dynamic>? _currentUserData;

  final TextEditingController _searchController = TextEditingController();
  String selectedDay = 'Sunday';

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
   // _filteredMealData = Map.from(mealData); // Initialize filtered data
    _getData();
    // _updateRemarks will be called in build method when context is available
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
          _currentUserName = userData['name'] ?? AppLocalizations.of(context)!.adminUser;
          _isLoading = false;
        });
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
  Future<void> _getData() async {
    // Simulate data fetching delay
   final date = DateTime.now();
   final weekIdentifier = "${date.year}-W${_getWeekNumber(date)}";
   final data = await FirebaseFirestore.instance.collection('voting_records').where((doc) => doc['selectedDay'] == selectedDay && doc['weekIdentifier'] == weekIdentifier).get();
    final totalvote = data.docs.length; // Assuming each document represents a vote
    final vote = {
      
      'breakfast': {
        'breakfast_set1': (data.docs.where((doc) => doc['selectedBreakfast'] == 'breakfast_set1').length/totalvote)/100,
        'breakfast_set2': (data.docs.where((doc) => doc['selectedBreakfast'] == 'breakfast_set2').length/totalvote)/100,
        'breakfast_set3': (data.docs.where((doc) => doc['selectedBreakfast'] == 'breakfast_set3').length/totalvote)/100,
      },
      'lunch': {
        'lunch_set1': (data.docs.where((doc) => doc['selectedLunch'] == 'lunch_set1').length/totalvote)/100,
        'lunch_set2': (data.docs.where((doc) => doc['selectedLunch'] == 'lunch_set2').length/totalvote)/100,
        'lunch_set3': (data.docs.where((doc) => doc['selectedLunch'] == 'lunch_set3').length/totalvote)/100,
      },
      'dinner': {
        'dinner_set1': (data.docs.where((doc) => doc['selectedDinner'] == 'dinner_set1').length/totalvote)/100,
        'dinner_set2': (data.docs.where((doc) => doc['selectedDinner'] == 'dinner_set2').length/totalvote)/100,
        'dinner_set3': (data.docs.where((doc) => doc['selectedDinner'] == 'dinner_set3').length/totalvote)/100,
      },
    };
   
    setState(() {
      _isLoading = false;
     mealData = vote;
    });
  }
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
  }
  // Dummy data structure for meal votes
  Map<String, Map<String, double>> mealData = {
    'Breakfast': {'breakfast_set1': 0.0, 'breakfast_set2': 0.0, 'breakfast_set3': 0.0},
      'Lunch': {'lunch_set1': 0.0, 'lunch_set2': 0.0, 'lunch_set3': 0.0},
      'Dinner': {'dinner_set1': 0.0, 'dinner_set2': 0.0, 'dinner_set3': 0.0}
    
  };

 

  final List<String> days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  // Method to get localized day name
  String getLocalizedDay(BuildContext context, String day) {
    switch (day) {
      case 'Sunday':
        return AppLocalizations.of(context)!.sunday;
      case 'Monday':
        return AppLocalizations.of(context)!.monday;
      case 'Tuesday':
        return AppLocalizations.of(context)!.tuesday;
      case 'Wednesday':
        return AppLocalizations.of(context)!.wednesday;
      case 'Thursday':
        return AppLocalizations.of(context)!.thursday;
      case 'Friday':
        return AppLocalizations.of(context)!.friday;
      case 'Saturday':
        return AppLocalizations.of(context)!.saturday;
      default:
        return day;
    }
  }

  // Method to get localized meal type name
  String getLocalizedMealType(BuildContext context, String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return AppLocalizations.of(context)!.breakfast;
      case 'Lunch':
        return AppLocalizations.of(context)!.lunch;
      case 'Dinner':
        return AppLocalizations.of(context)!.dinner;
      default:
        return mealType;
    }
  }

  // Method to get localized food item name
  String getLocalizedFoodItem(BuildContext context, String foodItem) {
    switch (foodItem) {
      case 'breakfast_set1':
        return 'Bhuna Khichuri'; // Example localized name
      case 'breakfast_set2':
        return 'Luchi with Alur dom'; // Example localized name
      case 'breakfast_set3':
        return 'Luchi with curry'; // Example localized name
      case 'lunch_set1':
        return 'Bhuna Khichuri'; // Example localized name
      case 'lunch_set2':
        return 'Luchi with Alur dom'; // Example localized name
      case 'lunch_set3':
        return 'Luchi with curry'; // Example localized name
      case 'dinner_set1':
        return 'Bhuna Khichuri'; // Example localized name
      case 'dinner_set2':
        return 'Luchi with Alur dom'; // Example localized name
      case 'dinner_set3':
        return 'Luchi with curry'; // Example localized name
     
      default:
        return foodItem;
    }
  }

  // Remarks data - this will be dynamically populated
  List<String> dynamicRemarks = [];

  // Search functionality implementation
  

  // Method to update dynamic remarks instantly
  void _updateRemarks(BuildContext context) {
    setState(() {
      dynamicRemarks = []; // Clear previous remarks

      // Localized remarks based on selectedDay
      if (selectedDay == 'Sunday') {
        dynamicRemarks = [
          AppLocalizations.of(context)!.sundayRemark1,
          AppLocalizations.of(context)!.sundayRemark2,
          AppLocalizations.of(context)!.sundayRemark3,
        ];
      } else if (selectedDay == 'Monday') {
        dynamicRemarks = [
          AppLocalizations.of(context)!.mondayRemark1,
          AppLocalizations.of(context)!.mondayRemark2,
          AppLocalizations.of(context)!.mondayRemark3,
        ];
      } else if (selectedDay == 'Tuesday') {
        dynamicRemarks = [
          AppLocalizations.of(context)!.tuesdayRemark1,
          AppLocalizations.of(context)!.tuesdayRemark2,
          AppLocalizations.of(context)!.tuesdayRemark3,
        ];
      } else if (selectedDay == 'Wednesday') {
        dynamicRemarks = [
          AppLocalizations.of(context)!.wednesdayRemark1,
          AppLocalizations.of(context)!.wednesdayRemark2,
          AppLocalizations.of(context)!.wednesdayRemark3,
        ];
      } else if (selectedDay == 'Thursday') {
        dynamicRemarks = [
          AppLocalizations.of(context)!.thursdayRemark1,
          AppLocalizations.of(context)!.thursdayRemark2,
          AppLocalizations.of(context)!.thursdayRemark3,
        ];
      } else if (selectedDay == 'Friday') {
        dynamicRemarks = [
          AppLocalizations.of(context)!.fridayRemark1,
          AppLocalizations.of(context)!.fridayRemark2,
          AppLocalizations.of(context)!.fridayRemark3,
        ];
      } else if (selectedDay == 'Saturday') {
        dynamicRemarks = [
          AppLocalizations.of(context)!.saturdayRemark1,
          AppLocalizations.of(context)!.saturdayRemark2,
          AppLocalizations.of(context)!.saturdayRemark3,
        ];
      } else {
        dynamicRemarks = [
          AppLocalizations.of(context)!.noSpecificRemarks,
          AppLocalizations.of(context)!.dataCollectionOngoing,
        ];
      }
    });
  }

  // Helper widget for sidebar tiles
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
          SnackBar(content: Text('${AppLocalizations.of(context)!.logoutFailed}: $e')),
        );
      }
    }
  }

  // Helper widget to build meal vote list with progress indicators
  Widget _buildMealVoteList(Map<String, double> meals) {
    // Sort meals by percentage in descending order
    final sortedMeals = meals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedMeals.map((meal) {
        final double percent = meal.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${getLocalizedFoodItem(context, meal.key)} (${(meal.value ).toStringAsFixed(1)}%)',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        // Ensure remarks are updated for the current day and language
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateRemarks(context);
        });
        
        // Show loading screen while authenticating
        if (_isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

      

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
                          builder: (context) => const AdminPendingIdsScreen(),
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
                          builder: (context) => const AdminInventoryScreen(),
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
                          builder: (context) => const AdminMealStateScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.thumb_up,
                    title: AppLocalizations.of(context)!.menuVote,
                    onTap: () => Navigator.pop(context),
                    selected: true,
                  ),
                  _buildSidebarTile(
                    icon: Icons.receipt_long,
                    title: AppLocalizations.of(context)!.bills,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminBillScreen(),
                        ),
                      );
                    },
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
                          builder: (context) => const DiningMemberStatePage(),
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
                          builder: (context) => const AdminStaffStateScreen(),
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
          AppLocalizations.of(context)!.menuVote,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          PopupMenuButton<Locale>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  size: const Size(24, 16),
                  painter: languageProvider.currentLocale.languageCode == 'en'
                      ? _EnglandFlagPainter()
                      : _BangladeshFlagPainter(),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
            onSelected: (Locale locale) {
              languageProvider.changeLanguage(locale);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<Locale>(
                value: const Locale('en', ''),
                child: Row(
                  children: [
                    CustomPaint(
                      size: const Size(20, 14),
                      painter: _EnglandFlagPainter(),
                    ),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.english),
                  ],
                ),
              ),
              PopupMenuItem<Locale>(
                value: const Locale('bn', ''),
                child: Row(
                  children: [
                    CustomPaint(
                      size: const Size(20, 14),
                      painter: _BangladeshFlagPainter(),
                    ),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.bangla),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Changed to SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search and Add New Set Button
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      //onChanged: _filterRecords,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchMealSets,
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
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddMenuSetScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A4D8F),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      AppLocalizations.of(context)!.addNewSet,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Day selection dropdown
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select Day: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedDay,
                        icon: const Icon(Icons.arrow_drop_down),
                        style:
                            const TextStyle(color: Colors.black, fontSize: 14),
                        items: days.map((String day) {
                          return DropdownMenuItem<String>(
                            value: day,
                            child: Text(getLocalizedDay(context, day)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedDay = newValue;
                              // Re-apply filter based on the new day
                              //_filterRecords(_searchController.text);
                              _updateRemarks(context); // Update remarks for the new day instantly
                              _getData(); // Fetch data for the selected day
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Meal Vote Statistics Section
               ...[
                Text(AppLocalizations.of(context)!.mealVoteStatistics,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // Removed Expanded from here to allow natural scrolling
                Column(
                  // Use a Column instead of ListView directly if content is not too long, or a ListView with shrinkWrap: true
                  children: mealData.entries.map((entry) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Highlighted meal time (Breakfast, Lunch, Dinner)
                            Text(
                              getLocalizedMealType(context, entry.key),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            _buildMealVoteList(entry.value),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ] ,
              // --- Horizontal Line before Remarks ---
              const SizedBox(height: 20),
              const Divider(), // Added a divider for visual separation
              const SizedBox(height: 20),
              // --- Remarks Section at the very end (scrollable into view) ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.insightsRemarks,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF002B5B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Display remarks content directly
                    dynamicRemarks.isEmpty
                        ? Text(
                            AppLocalizations.of(context)!.noRemarksAvailable,
                            style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: dynamicRemarks
                                .map(
                                  (remark) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.info_outline,
                                            size: 18, color: Colors.blueGrey),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            remark,
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}

// Custom painter for England flag
class _EnglandFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // White background
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Red cross
    paint.color = Colors.red;
    // Vertical line
    canvas.drawRect(Rect.fromLTWH(size.width * 0.4, 0, size.width * 0.2, size.height), paint);
    // Horizontal line  
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.2), paint);
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom painter for Bangladesh flag
class _BangladeshFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Green background
    paint.color = const Color(0xFF006A4E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Red circle
    paint.color = const Color(0xFFF42A41);
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.5), 
      size.height * 0.3, 
      paint
    );
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

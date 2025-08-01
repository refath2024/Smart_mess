import 'package:flutter/material.dart';
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
  String _currentUserName = "Admin User";
  Map<String, dynamic>? _currentUserData;

  final TextEditingController _searchController = TextEditingController();
  String selectedDay = 'Sunday';

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _filteredMealData = Map.from(mealData); // Initialize filtered data
    _updateRemarks(); // Initial update for remarks instantly
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

  // Dummy data structure for meal votes
  Map<String, Map<String, List<Map<String, dynamic>>>> mealData = {
    'Sunday': {
      'Breakfast': [
        {'name': 'Paratha Set', 'percentage': 45},
        {'name': 'Ruti Set', 'percentage': 35},
        {'name': 'Naan Set', 'percentage': 20},
      ],
      'Lunch': [
        {'name': 'Chicken Set', 'percentage': 50},
        {'name': 'Fish Set', 'percentage': 30},
        {'name': 'Vegetable Set', 'percentage': 20},
      ],
      'Dinner': [
        {'name': 'Biriyani Set', 'percentage': 60},
        {'name': 'Rice Set', 'percentage': 25},
        {'name': 'Khichuri Set', 'percentage': 15},
      ],
    },
    'Monday': {
      'Breakfast': [
        {'name': 'Egg Toast', 'percentage': 55},
        {'name': 'Cereal', 'percentage': 25},
        {'name': 'Fruit Salad', 'percentage': 20},
      ],
      'Lunch': [
        {'name': 'Pasta Bake', 'percentage': 40},
        {'name': 'Salad Bar', 'percentage': 35},
        {'name': 'Soup & Bread', 'percentage': 25},
      ],
      'Dinner': [
        {'name': 'Pizza', 'percentage': 70},
        {'name': 'Sandwich', 'percentage': 15},
        {'name': 'Stew', 'percentage': 15},
      ],
    },
    'Tuesday': {
      'Breakfast': [
        {'name': 'Dosa', 'percentage': 40},
        {'name': 'Idli', 'percentage': 30},
        {'name': 'Upma', 'percentage': 30},
      ],
      'Lunch': [
        {'name': 'Dal Makhani', 'percentage': 45},
        {'name': 'Paneer Butter Masala', 'percentage': 30},
        {'name': 'Mix Veg Curry', 'percentage': 25},
      ],
      'Dinner': [
        {'name': 'Chicken Curry', 'percentage': 55},
        {'name': 'Mutton Rogan Josh', 'percentage': 25},
        {'name': 'Vegetable Pulao', 'percentage': 20},
      ],
    },
    'Wednesday': {
      'Breakfast': [
        {'name': 'Pancakes', 'percentage': 60},
        {'name': 'Waffles', 'percentage': 25},
        {'name': 'Scrambled Eggs', 'percentage': 15},
      ],
      'Lunch': [
        {'name': 'Fish & Chips', 'percentage': 50},
        {'name': 'Shepherd\'s Pie', 'percentage': 30},
        {'name': 'Vegetable Lasagna', 'percentage': 20},
      ],
      'Dinner': [
        {'name': 'Beef Steak', 'percentage': 65},
        {'name': 'Grilled Salmon', 'percentage': 20},
        {'name': 'Mushroom Risotto', 'percentage': 15},
      ],
    },
    'Thursday': {
      'Breakfast': [
        {'name': 'Oatmeal', 'percentage': 40},
        {'name': 'Yogurt Parfait', 'percentage': 35},
        {'name': 'Smoothie', 'percentage': 25},
      ],
      'Lunch': [
        {'name': 'Sushi', 'percentage': 55},
        {'name': 'Ramen', 'percentage': 30},
        {'name': 'Tempura', 'percentage': 15},
      ],
      'Dinner': [
        {'name': 'Tacos', 'percentage': 60},
        {'name': 'Burritos', 'percentage': 25},
        {'name': 'Quesadillas', 'percentage': 15},
      ],
    },
    'Friday': {
      'Breakfast': [
        {'name': 'Croissant', 'percentage': 45},
        {'name': 'Muffin', 'percentage': 30},
        {'name': 'Fruit Tart', 'percentage': 25},
      ],
      'Lunch': [
        {'name': 'Pizza Slices', 'percentage': 70},
        {'name': 'Garlic Bread', 'percentage': 15},
        {'name': 'Side Salad', 'percentage': 15},
      ],
      'Dinner': [
        {'name': 'BBQ Ribs', 'percentage': 65},
        {'name': 'Grilled Chicken', 'percentage': 20},
        {'name': 'Vegetable Skewers', 'percentage': 15},
      ],
    },
    'Saturday': {
      'Breakfast': [
        {'name': 'Full English', 'percentage': 50},
        {'name': 'Continental', 'percentage': 30},
        {'name': 'Pancakes & Bacon', 'percentage': 20},
      ],
      'Lunch': [
        {'name': 'Burgers', 'percentage': 60},
        {'name': 'Hot Dogs', 'percentage': 25},
        {'name': 'Fries', 'percentage': 15},
      ],
      'Dinner': [
        {'name': 'Seafood Boil', 'percentage': 70},
        {'name': 'Steak Dinner', 'percentage': 20},
        {'name': 'Vegetarian Delight', 'percentage': 10},
      ],
    },
  };

  // Filtered meal data based on search query
  Map<String, Map<String, List<Map<String, dynamic>>>> _filteredMealData = {};

  final List<String> days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  // Remarks data - this will be dynamically populated
  List<String> dynamicRemarks = [];

  // Search functionality implementation
  void _filterRecords(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMealData = Map.from(mealData);
      } else {
        _filteredMealData = {};
        mealData.forEach((day, meals) {
          Map<String, List<Map<String, dynamic>>> filteredMeals = {};
          meals.forEach((mealTime, mealSets) {
            final filteredSets = mealSets
                .where((meal) =>
                    meal['name'].toLowerCase().contains(query.toLowerCase()))
                .toList();
            if (filteredSets.isNotEmpty) {
              filteredMeals[mealTime] = filteredSets;
            }
          });
          if (filteredMeals.isNotEmpty) {
            _filteredMealData[day] = filteredMeals;
          }
        });
      }
    });
  }

  // Method to update dynamic remarks instantly
  void _updateRemarks() {
    setState(() {
      dynamicRemarks = []; // Clear previous remarks

      // Dummy remarks based on selectedDay
      if (selectedDay == 'Sunday') {
        dynamicRemarks = [
          'Sunday dinner, Biriyani is a clear favorite, indicating a strong preference for hearty meals at the end of the week.',
          'Breakfast options on Sunday show a good mix of preferences, suggesting variety is appreciated.',
          'Lunch on Sunday could benefit from more diverse protein sources based on current vote distribution.'
        ];
      } else if (selectedDay == 'Monday') {
        dynamicRemarks = [
          'Pizza for Monday dinner received overwhelming votes; consider making it a regular special.',
          'Breakfast on Monday sees a strong preference for Egg Toast, indicating a need for quick and familiar options.',
          'Lunch options on Monday are fairly balanced, but Pasta Bake leads the preferences.'
        ];
      } else if (selectedDay == 'Tuesday') {
        dynamicRemarks = [
          'South Indian breakfast options are popular on Tuesdays.',
          'Dal Makhani is a preferred lunch item, consider its regular inclusion.',
          'Chicken Curry remains a strong contender for dinner choice.'
        ];
      } else if (selectedDay == 'Wednesday') {
        dynamicRemarks = [
          'Western breakfast is highly favored on Wednesdays.',
          'Fish & Chips stands out for lunch, a good option for variety.',
          'Beef Steak is the top pick for dinner, indicating demand for premium options.'
        ];
      } else if (selectedDay == 'Thursday') {
        dynamicRemarks = [
          'Healthy breakfast options like Oatmeal and Yogurt Parfait are well-received.',
          'Sushi is surprisingly popular for lunch, consider expanding Asian cuisine.',
          'Tacos are a clear winner for dinner; a themed night could work well.'
        ];
      } else if (selectedDay == 'Friday') {
        dynamicRemarks = [
          'Pastries are a good choice for Friday breakfast.',
          'Pizza is overwhelmingly popular for Friday lunch, consider offering more toppings.',
          'BBQ Ribs are highly demanded for Friday dinner, a good end-of-week treat.'
        ];
      } else if (selectedDay == 'Saturday') {
        dynamicRemarks = [
          'Hearty breakfast options are preferred on Saturdays.',
          'Burgers are a casual and popular lunch choice for the weekend.',
          'Seafood Boil is a top choice for Saturday dinner, indicating a preference for special meals.'
        ];
      } else {
        dynamicRemarks = [
          'No specific remarks available for $selectedDay yet.',
          'Data collection is ongoing; encourage more members to vote to gather comprehensive insights.'
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
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  // Helper widget to build meal vote list with progress indicators
  Widget _buildMealVoteList(List<Map<String, dynamic>> meals) {
    // Sort meals by percentage in descending order
    meals.sort(
        (a, b) => (b['percentage'] as int).compareTo(a['percentage'] as int));

    return Column(
      children: meals.map((meal) {
        final double percent = (meal['percentage'] as int) / 100.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${meal['name']} (${meal['percentage']}%)',
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
    // Show loading screen while authenticating
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final displayedMeals = _filteredMealData[selectedDay];

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
                    title: "Home",
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
                    title: "Users",
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
                    title: "Pending IDs",
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
                    title: "Shopping History",
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
                    title: "Voucher List",
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
                    title: "Inventory",
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
                    title: "Messing",
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
                    title: "Monthly Menu",
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
                    title: "Meal State",
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
                    title: "Menu Vote",
                    onTap: () => Navigator.pop(context),
                    selected: true,
                  ),
                  _buildSidebarTile(
                    icon: Icons.receipt_long,
                    title: "Bills",
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
                    title: "Payments",
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
                    title: "Dining Member State",
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
                    title: "Staff State",
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
                  title: "Logout",
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
        title: const Text(
          "Menu Vote",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
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
                      onChanged: _filterRecords,
                      decoration: InputDecoration(
                        hintText: 'Search meal sets...',
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
                    label: const Text(
                      'Add New Set',
                      style: TextStyle(
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
                            child: Text(day),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedDay = newValue;
                              // Re-apply filter based on the new day
                              _filterRecords(_searchController.text);
                              _updateRemarks(); // Update remarks for the new day instantly
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
              if (displayedMeals != null && displayedMeals.isNotEmpty) ...[
                const Text("Meal Vote Statistics",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // Removed Expanded from here to allow natural scrolling
                Column(
                  // Use a Column instead of ListView directly if content is not too long, or a ListView with shrinkWrap: true
                  children: displayedMeals.entries.map((entry) {
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
                              entry.key,
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
              ] else ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(
                        "No meal vote data available for the selected day or search query.",
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ),
                ),
              ],
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
                    const Text(
                      'Insights & Remarks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF002B5B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Display remarks content directly
                    dynamicRemarks.isEmpty
                        ? const Text(
                            'No specific remarks available at the moment. Please check back later.',
                            style: TextStyle(
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
  }
}

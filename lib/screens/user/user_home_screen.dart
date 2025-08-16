import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme_provider.dart';
import '../login_screen.dart';
import 'user_meal_in_out_screen.dart';
import 'user_messing_screen.dart';
import 'user_billing_screen.dart';
import 'user_menu_set_screen.dart';
import 'notification_page.dart';
import 'profile_screen.dart';
import 'help_screen.dart';
import 'change_password_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // User info storage
  String _userName = "";
  String _userEmail = "";
  bool _isLoadingUser = true;
  int _unreadNotificationCount = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  late final List<Widget> _screens;

  final List<String> _titles = [
    "Smart Mess",
    "Meal IN",
    "Messing",
    "Menu Set",
    "Billing",
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeContent(onBillingPressed: () => _onItemTapped(4)),
      const MealInOutScreen(),
      const MessingScreen(),
      const MenuSetScreen(),
      const BillingScreen(),
    ];

    _loadUserInfo();
    _loadUnreadNotificationCount();
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final unreadSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('user_id', isEqualTo: currentUser.uid)
          .where('is_read', isEqualTo: false)
          .get();

      setState(() {
        _unreadNotificationCount = unreadSnapshot.docs.length;
      });
    } catch (e) {
      debugPrint('Error loading unread notification count: $e');
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // User not logged in, set defaults
        setState(() {
          _userName = "Guest";
          _userEmail = "";
          _isLoadingUser = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('user_requests')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _userName = data['name'] ?? 'Unknown User';
          _userEmail = data['email'] ?? (user.email ?? "");
          _isLoadingUser = false;
        });
      } else {
        // If document doesn't exist, fallback
        setState(() {
          _userName = user.displayName ?? "User";
          _userEmail = user.email ?? "";
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      final user = FirebaseAuth.instance.currentUser;
      setState(() {
        _userName = "User";
        _userEmail = user?.email ?? "";
        _isLoadingUser = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        leading: _selectedIndex == 0
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: const CircleAvatar(
                    backgroundImage: AssetImage('assets/pro.png'),
                    radius: 30,
                  ),
                ),
              )
            : null,
        title: _selectedIndex == 0
            ? null
            : Text(
                _titles[_selectedIndex],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
        actions: _selectedIndex == 0
            ? [
                IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications, size: 32),
                      if (_unreadNotificationCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              _unreadNotificationCount > 99
                                  ? '99+'
                                  : '$_unreadNotificationCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationPage()),
                    );
                    // Refresh notification count after user views notifications
                    _loadUnreadNotificationCount();
                  },
                ),
              ]
            : null,
      ),
      drawer: _selectedIndex == 0
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    accountName: _isLoadingUser
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : Text(
                            _userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    accountEmail: _isLoadingUser ? null : Text(_userEmail),
                    currentAccountPicture: const CircleAvatar(
                      backgroundImage: AssetImage('assets/pro.png'),
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF002B5B),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "Account",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('My Profile'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyProfilePage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & Support'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpScreen()),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Change your password'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen()),
                      );
                    },
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "Preferences",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode),
                    title: const Text("Dark Mode"),
                    value: themeNotifier.currentTheme == ThemeMode.dark,
                    onChanged: (val) {
                      themeNotifier.toggleTheme(val);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      "Logout",
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                ],
              ),
            )
          : null,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: "Meal IN"),
          BottomNavigationBarItem(
              icon: Icon(Icons.food_bank), label: "Messing"),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book), label: "Menu Set"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Billing"),
        ],
      ),
    );
  }
}

// Update your HomeContent widget imports and class name accordingly:
class HomeContent extends StatefulWidget {
  final VoidCallback onBillingPressed;

  const HomeContent({
    super.key,
    required this.onBillingPressed,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  Map<String, dynamic>? todayMenu;
  Map<String, dynamic>? tomorrowMenu;
  bool isLoading = true;
  double _totalDue = 0.0;
  bool _isLoadingBill = true;

  @override
  void initState() {
    super.initState();
    _fetchMenuData();
    _loadCurrentBill();
  }

  String _formatDateForFirestore(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _fetchMenuData() async {
    try {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));

      final todayStr = _formatDateForFirestore(today);
      final tomorrowStr = _formatDateForFirestore(tomorrow);

      // Fetch today's menu
      final todayDoc = await FirebaseFirestore.instance
          .collection('monthly_menu')
          .doc(todayStr)
          .get();

      // Fetch tomorrow's menu
      final tomorrowDoc = await FirebaseFirestore.instance
          .collection('monthly_menu')
          .doc(tomorrowStr)
          .get();

      setState(() {
        todayMenu = todayDoc.exists ? todayDoc.data() : null;
        tomorrowMenu = tomorrowDoc.exists ? tomorrowDoc.data() : null;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching menu data: $e");
      setState(() {
        isLoading = false;
      });
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

      // Get user data to find BA number
      final userDoc = await FirebaseFirestore.instance
          .collection('user_requests')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _totalDue = 0.0;
          _isLoadingBill = false;
        });
        return;
      }

      final userData = userDoc.data()!;
      final baNo = userData['ba_no']?.toString();

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
          // Calculate current total due using the same logic
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
      debugPrint("Error loading bill data: $e");
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

  Widget _buildMenuCard(
      String mealType, Map<String, dynamic>? mealData, bool isToday) {
    final IconData mealIcon;
    final Color cardColor;

    switch (mealType.toLowerCase()) {
      case 'breakfast':
        mealIcon = Icons.free_breakfast;
        cardColor = Colors.orange.shade50;
        break;
      case 'lunch':
        mealIcon = Icons.lunch_dining;
        cardColor = Colors.green.shade50;
        break;
      case 'dinner':
        mealIcon = Icons.dinner_dining;
        cardColor = Colors.blue.shade50;
        break;
      default:
        mealIcon = Icons.restaurant;
        cardColor = Colors.grey.shade50;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor,
              cardColor.withOpacity(0.3),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Meal type icon with larger size
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  mealIcon,
                  size: 32,
                  color: _getMealTypeColor(mealType),
                ),
              ),
              const SizedBox(height: 12),

              // Meal type title
              Text(
                _capitalizeMealType(mealType),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF002B5B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Menu item and price
              if (mealData != null) ...[
                Text(
                  mealData['item'] ?? 'Not Available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '৳ ${(mealData['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Menu not available',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '৳ --',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange.shade600;
      case 'lunch':
        return Colors.green.shade600;
      case 'dinner':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _capitalizeMealType(String mealType) {
    return mealType[0].toUpperCase() + mealType.substring(1).toLowerCase();
  }

  Widget _buildMenuSection(
      String title, Map<String, dynamic>? menuData, bool isToday) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isToday ? Icons.today : Icons.event,
              color: const Color(0xFF002B5B),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002B5B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildMenuCard(
                  'breakfast',
                  menuData?['breakfast'],
                  isToday,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMenuCard(
                  'lunch',
                  menuData?['lunch'],
                  isToday,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMenuCard(
                  'dinner',
                  menuData?['dinner'],
                  isToday,
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 24),

            // Today's Menu Section
            _buildMenuSection("Today's Menu", todayMenu, true),

            const SizedBox(height: 32),

            // Tomorrow's Menu Section
            _buildMenuSection("Tomorrow's Menu", tomorrowMenu, false),

            const SizedBox(height: 24),

            // Bill Payment Card
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
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Total Due",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                          SizedBox(height: 4),
                          _isLoadingBill
                              ? SizedBox(
                                  height: 16,
                                  width: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text("৳ ${_totalDue.toStringAsFixed(0)}",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black87)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: widget.onBillingPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Pay Bill",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

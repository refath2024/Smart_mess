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
                  icon: const Icon(Icons.notifications, size: 32),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationPage()),
                    );
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
                    leading: const Icon(Icons.help),
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
class HomeContent extends StatelessWidget {
  final VoidCallback onBillingPressed;

  const HomeContent({
    super.key,
    required this.onBillingPressed,
  });

  Widget _buildMenuCard(String title, String subtitle, String imagePath) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.asset(
              'assets/$imagePath',
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center),
              ],
            ),
          )
        ],
      ),
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
            const Text(
              "Today's Menu",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildMenuCard(
                        "Breakfast", "Alu Paratha with Beef", "2.png")),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildMenuCard(
                        "Lunch", "Khichuri with Chicken", "1.png")),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildMenuCard(
                        "Dinner", "Ruti with dal and vaji", "3.png")),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Tomorrow's Menu",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildMenuCard(
                        "Breakfast", "Roti with Beef Curry", "4.png")),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildMenuCard("Lunch", "Rice with Curry", "5.png")),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildMenuCard(
                        "Dinner", "Paratha with Chicken", "6.png")),
              ],
            ),
            const SizedBox(height: 24),
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Total Due",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                          SizedBox(height: 4),
                          Text("৳ 1000",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black87)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onBillingPressed,
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

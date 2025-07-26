import 'package:flutter/material.dart';
import '../login_screen.dart';
import 'admin_home_screen.dart';
import 'admin_pending_ids_screen.dart';
import 'admin_shopping_history.dart';
import 'admin_voucher_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_messing_screen.dart';
import 'admin_staff_state_screen.dart';
import 'admin_dining_member_state.dart';
import 'admin_payment_history.dart';
import 'admin_bill_screen.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_menu_vote_screen.dart';
import 'admin_meal_state_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Improved type safety with custom type
  final List<Map<String, dynamic>> users = [
    {
      'no': 101,
      'rank': 'Lt',
      'name': 'Sami',
      'unit': '10 Sig',
      'mobile': '01700000001',
      'email': 'sami@army.mil.bd',
      'role': 'Admin',
      'status': 'Active',
    },
    {
      'no': 102,
      'rank': 'Lt',
      'name': 'Wasifa',
      'unit': '6 Sig',
      'mobile': '01700000002',
      'email': 'wasifa@pharma.bd',
      'role': 'Dining Member',
      'status': 'Inactive',
    },
    {
      'no': 103,
      'rank': 'Capt',
      'name': 'Tanvir',
      'unit': '2 Engr',
      'mobile': '01700000003',
      'email': 'tanvir@army.bd',
      'role': 'Cook',
      'status': 'Active',
    },
    {
      'no': 104,
      'rank': 'Maj',
      'name': 'Zubaer',
      'unit': 'CSE Dept',
      'mobile': '01700000004',
      'email': 'zubaer@mist.bd',
      'role': 'Admin',
      'status': 'Active',
    },
    {
      'no': 105,
      'rank': 'Lt',
      'name': 'Refath',
      'unit': '86 ISB',
      'mobile': '01700000005',
      'email': 'refath@sig.com',
      'role': 'Dining Member',
      'status': 'Inactive',
    },
    {
      'no': 106,
      'rank': 'Lt',
      'name': 'Tahmid',
      'unit': '10 Sig',
      'mobile': '01700000006',
      'email': 'tahmid@army.mil',
      'role': 'Dining Member',
      'status': 'Active',
    },
    {
      'no': 107,
      'rank': 'Capt',
      'name': 'Ayon',
      'unit': '2 Sig',
      'mobile': '01700000007',
      'email': 'ayon@army.mil',
      'role': 'Staff',
      'status': 'Active',
    },
    {
      'no': 108,
      'rank': 'Maj',
      'name': 'Adil',
      'unit': 'Logistics',
      'mobile': '01700000008',
      'email': 'adil@army.mil',
      'role': 'Staff',
      'status': 'Inactive',
    },
    {
      'no': 109,
      'rank': 'Lt Col',
      'name': 'Minhaz',
      'unit': 'HQ',
      'mobile': '01700000009',
      'email': 'minhaz@hq.army.bd',
      'role': 'Admin',
      'status': 'Active',
    },
    {
      'no': 110,
      'rank': 'Brig Gen',
      'name': 'Raiyan',
      'unit': 'Brigade',
      'mobile': '01700000010',
      'email': 'raiyan@army.bd',
      'role': 'Admin',
      'status': 'Active',
    },
    {
      'no': 111,
      'rank': 'Capt',
      'name': 'Tasin',
      'unit': '4 Engr',
      'mobile': '01700000011',
      'email': 'tasin@eng.bd',
      'role': 'Dining Member',
      'status': 'Active',
    },
    {
      'no': 112,
      'rank': 'Lt',
      'name': 'Pervez',
      'unit': '3 Sig',
      'mobile': '01700000012',
      'email': 'pervez@sig.bd',
      'role': 'Cook',
      'status': 'Inactive',
    },
    {
      'no': 113,
      'rank': 'Lt',
      'name': 'Nahid',
      'unit': '10 Sig',
      'mobile': '01700000013',
      'email': 'nahid@army.bd',
      'role': 'Dining Member',
      'status': 'Active',
    },
    {
      'no': 114,
      'rank': 'Capt',
      'name': 'Ahnaf',
      'unit': '1 Engr',
      'mobile': '01700000014',
      'email': 'ahnaf@army.bd',
      'role': 'Admin',
      'status': 'Inactive',
    },
    {
      'no': 115,
      'rank': 'Maj',
      'name': 'Faiyaz',
      'unit': '10 Sig',
      'mobile': '01700000015',
      'email': 'faiyaz@army.bd',
      'role': 'Dining Member',
      'status': 'Active',
    },
    {
      'no': 116,
      'rank': 'Col',
      'name': 'Fahim',
      'unit': 'HQ',
      'mobile': '01700000016',
      'email': 'fahim@hq.bd',
      'role': 'Admin',
      'status': 'Inactive',
    },
    {
      'no': 117,
      'rank': 'Lt',
      'name': 'Shafquat',
      'unit': '1 Sig',
      'mobile': '01700000017',
      'email': 'shafquat@army.mil',
      'role': 'Cook',
      'status': 'Active',
    },
  ];

  List<Map<String, dynamic>> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    filteredUsers = List.from(users);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) {
    setState(() {
      filteredUsers = users.where((user) {
        return user.values.any(
          (value) =>
              value.toString().toLowerCase().contains(query.toLowerCase()),
        );
      }).toList();
    });
  }

  Widget _buildStatus(String status) {
    final isActive = status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color.fromARGB(255, 69, 171, 72) : Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A4D8F), // Dark blue
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              "ID No",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Text(
              "Rank",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Text(
              "Name",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Text(
              "Unit",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Text(
              "Mobile",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Text(
              "Email",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Text(
              "Role",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Text(
              "Status",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(child: Text(user['no'].toString() ?? '')),
          Expanded(child: Text(user['rank'] ?? '')),
          Expanded(child: Text(user['name'] ?? '')),
          Expanded(child: Text(user['unit'] ?? '')),
          Expanded(child: Text(user['mobile'] ?? '')),
          Expanded(child: Text(user['email'] ?? '')),
          Expanded(child: Text(user['role'] ?? '')),
          Expanded(child: _buildStatus(user['status'] ?? '')),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final totalMembers = users.length;
    final activeMembers =
        users.where((u) => u['status']!.toLowerCase() == 'active').length;
    final diningMembers =
        users.where((u) => u['role']!.toLowerCase() == 'dining member').length;
    final activeDining = users
        .where(
          (u) =>
              u['role']!.toLowerCase() == 'dining member' &&
              u['status']!.toLowerCase() == 'active',
        )
        .length;
    final cooks = users.where((u) => u['role']!.toLowerCase() == 'cook').length;
    final staffsAdmins = totalMembers - diningMembers - cooks;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: const Color(0xFFF5F7FA),
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Member Summary",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A4D8F),
              ),
            ),
            const SizedBox(height: 8),
            Text("• Total Members = $totalMembers"),
            Text("• Total Active Members = $activeMembers"),
            Text("• Total Dining Members = $diningMembers"),
            Text("• Total Active Dining Members = $activeDining"),
            Text("• Total Cooks = $cooks"),
            Text("• Total Staffs and Admins = $staffsAdmins"),
          ],
        ),
      ),
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
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
        title: Text(
          title,
          style: TextStyle(color: color ?? Colors.black),
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    try {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => screen),
      ).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigation error: ${error.toString()}')),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                padding: EdgeInsets.zero,
                children: [
                  _buildSidebarTile(
                    icon: Icons.dashboard,
                    title: "Home",
                    onTap: () =>
                        _navigateToScreen(context, const AdminHomeScreen()),
                  ),
                  _buildSidebarTile(
                    icon: Icons.people,
                    title: "Users",
                    onTap: () => Navigator.pop(context),
                    selected: true,
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
          "Users",
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
                    "Search:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _search,
                      decoration: InputDecoration(
                        hintText: "Search All Text Columns",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1200,
                    child: ListView(
                      padding: const EdgeInsets.only(
                        bottom: 20,
                      ), // Prevent bottom clip
                      children: [
                        _buildTableHeader(),
                        const Divider(),
                        ...filteredUsers.map(_buildUserRow),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildStats(),
            ],
          ),
        ),
      ),
    );
  }
}

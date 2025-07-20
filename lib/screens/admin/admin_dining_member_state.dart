import 'package:flutter/material.dart';
import '../login_screen.dart';
import 'admin_home_screen.dart';
import 'admin_users_screen.dart';
import 'admin_pending_ids_screen.dart';
import 'admin_shopping_history.dart';
import 'admin_voucher_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_messing_screen.dart';
import 'admin_staff_state_screen.dart';
import 'admin_payment_history.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_meal_state_screen.dart';
import 'admin_bill_screen.dart';
import 'admin_menu_vote_screen.dart';

class DiningMemberData {
  final String name;
  final String rank;
  final String membershipStatus;
  final String lastMealTaken;
  final int totalMeals;
  final double monthlyBill;
  final String id;
  final String unit;
  final String phone;
  final String email;
  final String bloodGroup;
  final String joiningDate;
  final String emergencyContact;
  final String address;

  DiningMemberData({
    required this.name,
    required this.rank,
    required this.membershipStatus,
    required this.lastMealTaken,
    required this.totalMeals,
    required this.monthlyBill,
    required this.id,
    required this.unit,
    required this.phone,
    required this.email,
    required this.bloodGroup,
    required this.joiningDate,
    required this.emergencyContact,
    required this.address,
    
  });
}

class DiningMemberStatePage extends StatefulWidget {
  const DiningMemberStatePage({super.key});

  @override
  State<DiningMemberStatePage> createState() => _DiningMemberStatePageState();
}

class _DiningMemberStatePageState extends State<DiningMemberStatePage> {
  List<DiningMemberData> filteredMembers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredMembers = List.from(members);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchMembers(String query) {
    setState(() {
      filteredMembers = members.where((member) {
        final searchLower = query.toLowerCase();
        return member.name.toLowerCase().contains(searchLower) ||
            member.rank.toLowerCase().contains(searchLower) ||
            member.membershipStatus.toLowerCase().contains(searchLower) ||
            member.lastMealTaken.toLowerCase().contains(searchLower);
      }).toList();
    });
  }
  
  final List<DiningMemberData> members = [
    DiningMemberData(
      name: "Maj John Smith",
      rank: "Major",
      membershipStatus: "Active",
      lastMealTaken: "Today, Lunch",
      totalMeals: 45,
      monthlyBill: 3500.00,
      id: "BA-1234",
      unit: "10 Signal Battalion",
      phone: "+880 1700-000001",
      email: "john.smith@army.mil.bd",
      bloodGroup: "A+",
      joiningDate: "2023-01-15",
      emergencyContact: "+880 1700-000002 (Mrs. Smith)",
      address: "Officers Quarters, Dhaka Cantonment",
    ),
    DiningMemberData(
      name: "Capt Sarah Johnson",
      rank: "Captain",
      membershipStatus: "Active",
      lastMealTaken: "Today, Breakfast",
      totalMeals: 38,
      monthlyBill: 2950.00,
      id: "BA-1235",
      unit: "Engineering Corps",
      phone: "+880 1700-000003",
      email: "sarah.j@army.mil.bd",
      bloodGroup: "B+",
      joiningDate: "2023-03-20",
      emergencyContact: "+880 1700-000004 (Mr. Johnson)",
      address: "Block D, Military Housing",
      
    ),
    DiningMemberData(
      name: "Lt David Miller",
      rank: "Lieutenant",
      membershipStatus: "On Leave",
      lastMealTaken: "3 days ago, Dinner",
      totalMeals: 28,
      monthlyBill: 2100.00,
      id: "BA-1236",
      unit: "Artillery Regiment",
      phone: "+880 1700-000005",
      email: "david.m@army.mil.bd",
      bloodGroup: "O+",
      joiningDate: "2024-01-10",
      emergencyContact: "+880 1700-000006 (Mrs. Miller)",
      address: "Officers Mess, Cantonment",
      
    ),
    DiningMemberData(
      name: "WO James Wilson",
      rank: "Warrant Officer",
      membershipStatus: "Active",
      lastMealTaken: "Today, Dinner",
      totalMeals: 42,
      monthlyBill: 3200.00,
      id: "BA-1237",
      unit: "Medical Corps",
      phone: "+880 1700-000007",
      email: "james.w@army.mil.bd",
      bloodGroup: "AB+",
      joiningDate: "2023-06-05",
      emergencyContact: "+880 1700-000008 (Mrs. Wilson)",
      address: "Block B, Military Housing",
  
    ),
  ];

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
        title: Text(title, style: TextStyle(color: color ?? Colors.black)),
      ),
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
                      icon: Icons.dashboard,
                      title: "Home",
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminHomeScreen(),
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
                      onTap: () => Navigator.pop(context),
                      selected: true,
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
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                ),
                child: _buildSidebarTile(
                  icon: Icons.logout,
                  title: "Logout",
                  onTap: _logout,
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
          "Dining Member State",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF002B5B).withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard("Total Members", "42", Colors.blue),
                _buildStatCard("Active Today", "38", Colors.green),
                _buildStatCard("On Leave", "4", Colors.orange),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search Members",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF002B5B)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF002B5B)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF002B5B), width: 2),
                ),
              ),
              onChanged: (value) => _searchMembers(value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredMembers.length,
              itemBuilder: (context, index) {
                final member = filteredMembers[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    title: Text(
                      member.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(member.rank),
                    leading: CircleAvatar(
                      backgroundColor: member.membershipStatus == "Active"
                          ? Colors.green
                          : Colors.orange,
                      child: Text(
                        member.name.substring(0, 1),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Personal Information",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF002B5B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow("Number", member.id),
                            _buildDetailRow("Rank", member.rank),
                            _buildDetailRow("Name", member.name),
                            _buildDetailRow("Unit", member.unit),
                            _buildDetailRow("Mobile No", member.phone),
                            _buildDetailRow("Email", member.email),
                            _buildDetailRow("Blood Group", member.bloodGroup),
                            _buildDetailRow("Joining Date", member.joiningDate),
                            _buildDetailRow("Emergency Contact", member.emergencyContact),
                            _buildDetailRow("Address", member.address),
                            
                            const SizedBox(height: 16),
                            const Text(
                              "Dining Information",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF002B5B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow("Status", member.membershipStatus),
                            _buildDetailRow("Last Meal", member.lastMealTaken),
                            _buildDetailRow("Total Meals", member.totalMeals.toString()),
                            _buildDetailRow("Monthly Bill", "৳${member.monthlyBill.toStringAsFixed(2)}"),
                            
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

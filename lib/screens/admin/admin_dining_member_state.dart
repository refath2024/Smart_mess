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
import 'admin_dining_member_state.dart';
import 'admin_payment_history.dart';
import 'admin_meal_state_screen.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_menu_vote_screen.dart';
import 'admin_bill_screen.dart';
import 'add_user_form.dart';


class DiningMember {
  String id;
  String name;
  String rank;
  String unit;
  String phone;
  String email;
  String status;
  double monthlyBill;

  DiningMember({
    required this.id,
    required this.name,
    required this.rank,
    required this.unit,
    required this.phone,
    required this.email,
    required this.status,
    required this.monthlyBill,
  });
}

class DiningMemberStatePage extends StatefulWidget {
  const DiningMemberStatePage({super.key});

  @override
  State<DiningMemberStatePage> createState() => _DiningMemberStatePageState();
}

class _DiningMemberStatePageState extends State<DiningMemberStatePage> {
  List<DiningMember> members = [
    DiningMember(
        id: 'BA-1234',
        name: 'Maj John Smith',
        rank: 'Major',
        unit: '10 Signal Battalion',
        phone: '+880 1700-000001',
        email: 'john.smith@army.mil.bd',
        status: 'Active',
        monthlyBill: 3500.00),
    DiningMember(
        id: 'BA-1235',
        name: 'Capt Sarah Johnson',
        rank: 'Captain',
        unit: 'Engineering Corps',
        phone: '+880 1700-000003',
        email: 'sarah.j@army.mil.bd',
        status: 'Active',
        monthlyBill: 2950.00),
  ];

  int? editingIndex;
  final _searchController = TextEditingController();
  List<DiningMember> filtered = [];

  @override
  void initState() {
    super.initState();
    filtered = List.from(members);
  }

  void _startEditing(int index) {
    setState(() => editingIndex = index);
  }

  void _cancelEditing() {
    setState(() => editingIndex = null);
  }

  void _delete(int index) {
    setState(() {
      members.removeAt(index);
      filtered = List.from(members);
    });
  }

  void _save(int index, DiningMember updated) {
    setState(() {
      members[index] = updated;
      filtered = List.from(members);
      editingIndex = null;
    });
  }

  void _search(String query) {
    setState(() {
      filtered = members
          .where((m) =>
              m.name.toLowerCase().contains(query.toLowerCase()) ||
              m.rank.toLowerCase().contains(query.toLowerCase()) ||
              m.status.toLowerCase().contains(query.toLowerCase()) ||
              m.id.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
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
      leading: Icon(icon, color: color ?? (selected ? Colors.blue : Colors.black)),
      title: Text(title, style: TextStyle(color: color ?? Colors.black)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF002B5B), Color(0xFF1A4D8F)],
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage('assets/me.png'),
                      radius: 30,
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        "Shoaib Ahmed Sami",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _buildSidebarTile(icon: Icons.dashboard, title: "Home", onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminHomeScreen()))),
                    _buildSidebarTile(icon: Icons.people, title: "Users", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUsersScreen()))),
                    _buildSidebarTile(icon: Icons.pending, title: "Pending IDs", onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminPendingIdsScreen()))),
                    _buildSidebarTile(icon: Icons.history, title: "Shopping History", onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminShoppingHistoryScreen()))),
                    _buildSidebarTile(icon: Icons.receipt, title: "Voucher List", onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminVoucherScreen()))),
                    _buildSidebarTile(icon: Icons.storage, title: "Inventory", onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminInventoryScreen()))),
                    _buildSidebarTile(icon: Icons.food_bank, title: "Messing", onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminMessingScreen()))),
                    _buildSidebarTile(icon: Icons.menu_book, title: "Monthly Menu", onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const EditMenuScreen()))),
                    _buildSidebarTile(icon: Icons.analytics, title: "Meal State", onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminMealStateScreen()))),
                    _buildSidebarTile(icon: Icons.thumb_up, title: "Menu Vote", onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MenuVoteScreen()))),
                    _buildSidebarTile(icon: Icons.receipt_long, title: "Bills", onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminBillScreen()))),
                    _buildSidebarTile(icon: Icons.payment, title: "Payments", onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PaymentsDashboard()))),
                    _buildSidebarTile(icon: Icons.people_alt, title: "Dining Member State", selected: true, onTap: () => Navigator.pop(context)),
                    _buildSidebarTile(icon: Icons.manage_accounts, title: "Staff State", onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminStaffStateScreen()))),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8),
                child: _buildSidebarTile(
                  icon: Icons.logout,
                  title: "Logout",
                  color: Colors.red,
                  onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false),
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
        title: const Text("Dining Member State", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserFormPage()));
},

                  icon: const Icon(Icons.add),
                  label: const Text("Add Users"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _search,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: "Search Members",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(const Color(0xFF1A4D8F)),
                  columns: const [
                    DataColumn(label: Text('ID', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Name', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Rank', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Unit', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Phone', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Email', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Status', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Bill', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Action', style: TextStyle(color: Colors.white))),
                  ],
                  rows: List.generate(filtered.length, (index) {
                    final m = filtered[index];
                    final isEditing = editingIndex == index;
                    TextEditingController idCtrl = TextEditingController(text: m.id);
                    TextEditingController nameCtrl = TextEditingController(text: m.name);
                    TextEditingController rankCtrl = TextEditingController(text: m.rank);
                    TextEditingController unitCtrl = TextEditingController(text: m.unit);
                    TextEditingController phoneCtrl = TextEditingController(text: m.phone);
                    TextEditingController emailCtrl = TextEditingController(text: m.email);
                    TextEditingController billCtrl = TextEditingController(text: m.monthlyBill.toString());

                    return DataRow(cells: [
                      DataCell(isEditing ? TextField(controller: idCtrl) : Text(m.id)),
                      DataCell(isEditing ? TextField(controller: nameCtrl) : Text(m.name)),
                      DataCell(isEditing ? TextField(controller: rankCtrl) : Text(m.rank)),
                      DataCell(isEditing ? TextField(controller: unitCtrl) : Text(m.unit)),
                      DataCell(isEditing ? TextField(controller: phoneCtrl) : Text(m.phone)),
                      DataCell(isEditing ? TextField(controller: emailCtrl) : Text(m.email)),
                      DataCell(
                        isEditing
                            ? DropdownButton<String>(
                                value: m.status,
                                items: const [
                                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                                ],
                                onChanged: (val) => setState(() => m.status = val!),
                              )
                            : Text(m.status),
                      ),
                      DataCell(
                        isEditing
                            ? TextField(controller: billCtrl)
                            : Text(
                                '৳${m.monthlyBill.toStringAsFixed(2)}',
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                      ),
                      DataCell(Row(children: [
                        if (isEditing)
                          ...[
                            IconButton(
                                icon: Icon(Icons.save, color: Colors.green),
                                onPressed: () {
                                  _save(
                                    index,
                                    DiningMember(
                                      id: idCtrl.text,
                                      name: nameCtrl.text,
                                      rank: rankCtrl.text,
                                      unit: unitCtrl.text,
                                      phone: phoneCtrl.text,
                                      email: emailCtrl.text,
                                      status: m.status,
                                      monthlyBill: double.tryParse(billCtrl.text) ?? m.monthlyBill,
                                    ),
                                  );
                                }),
                            IconButton(icon: Icon(Icons.cancel, color: Colors.red), onPressed: _cancelEditing)
                          ]
                        else
                          ...[
                            IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => _startEditing(index)),
                            IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(index)),
                          ]
                      ]))
                    ]);
                  }),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

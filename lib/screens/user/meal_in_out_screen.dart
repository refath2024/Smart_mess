import 'package:flutter/material.dart';
import '../login_screen.dart';
import 'user_home_screen.dart';
import 'messing.dart';
import 'billing_screen.dart';
import 'menu_set_screen.dart';

class MealInOutScreen extends StatefulWidget {
  const MealInOutScreen({super.key});

  @override
  State<MealInOutScreen> createState() => _MealInOutScreenState();
}

class _MealInOutScreenState extends State<MealInOutScreen> {
  final _breakfast = ValueNotifier<bool>(false);
  final _lunch = ValueNotifier<bool>(false);
  final _dinner = ValueNotifier<bool>(false);
  final _remarksController = TextEditingController();

  bool _disposalYes = false;
  String _disposalType = 'SIQ';
  DateTime? _fromDate;
  DateTime? _toDate;

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String get _mealDate {
    final now = DateTime.now();
    final target = now.hour >= 21
        ? now.add(const Duration(days: 2))
        : now.add(const Duration(days: 1));
    return _formatDate(target);
  }

  Future<void> _pickDate({required bool isFrom}) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isFrom) {
          _fromDate = pickedDate;
          if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
            _toDate = null;
          }
        } else {
          _toDate = pickedDate;
        }
      });
    }
  }

  void _submit() {
    final data = {
      'date': _mealDate,
      'breakfast': _breakfast.value ? 'Yes' : 'No',
      'lunch': _lunch.value ? 'Yes' : 'No',
      'dinner': _dinner.value ? 'Yes' : 'No',
      'remarks': _remarksController.text.trim(),
      'disposal': _disposalYes,
      'disposalType': _disposalYes ? _disposalType : 'No',
      'from': _disposalYes ? _fromDate?.toIso8601String() : null,
      'to': _disposalYes ? _toDate?.toIso8601String() : null,
    };

    // TODO: Submit this to your backend

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Meal selection submitted')));
  }

  @override
  void dispose() {
    _breakfast.dispose();
    _lunch.dispose();
    _dinner.dispose();
    _remarksController.dispose();
    super.dispose();
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

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                      icon: Icons.home,
                      title: "Home",
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserHomeScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSidebarTile(
                      icon: Icons.fastfood,
                      title: "Meal IN/OUT",
                      onTap: () => Navigator.pop(context),
                      selected: true,
                    ),
                    _buildSidebarTile(
                      icon: Icons.food_bank,
                      title: "Messing",
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MessingScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSidebarTile(
                      icon: Icons.menu_book,
                      title: "Menu Set",
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MenuSetScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSidebarTile(
                      icon: Icons.receipt_long,
                      title: "Billing",
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BillingScreen(),
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
          "Smart Mess",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              "Select Your Meal",
              style:
                  textTheme.titleLarge ??
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text("For: $_mealDate", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),

            // Meal options
            ValueListenableBuilder<bool>(
              valueListenable: _breakfast,
              builder: (_, val, __) => CheckboxListTile(
                title: const Text("Breakfast  (Eggs, Toast, Juice)"),
                subtitle: const Text("৳ 30"),
                value: val,
                onChanged: (v) => _breakfast.value = v ?? false,
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _lunch,
              builder: (_, val, __) => CheckboxListTile(
                title: const Text("Lunch  (Rice, Chicken Curry, Salad)"),
                subtitle: const Text("৳ 150"),
                value: val,
                onChanged: (v) => _lunch.value = v ?? false,
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _dinner,
              builder: (_, val, __) => CheckboxListTile(
                title: const Text("Dinner  (Pasta, Garlic Bread, Dessert)"),
                subtitle: const Text("৳ 80"),
                value: val,
                onChanged: (v) => _dinner.value = v ?? false,
              ),
            ),
            const Divider(),

            // Remarks
            TextField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // Disposal switch
            Row(
              children: [
                const Text("Disposal? "),
                Switch(
                  value: _disposalYes,
                  onChanged: (v) => setState(() => _disposalYes = v),
                ),
              ],
            ),

            if (_disposalYes) ...[
              DropdownButtonFormField<String>(
                value: _disposalType,
                decoration: const InputDecoration(
                  labelText: 'Select Disposal Type',
                  border: OutlineInputBorder(),
                ),
                items: ['SIQ', 'Leave', 'Mess Out']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _disposalType = v!),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(isFrom: true),
                      child: Text(
                        _fromDate == null
                            ? 'From Date'
                            : _formatDate(_fromDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(isFrom: false),
                      child: Text(
                        _toDate == null ? 'To Date' : _formatDate(_toDate!),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002B5B),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "Submit",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

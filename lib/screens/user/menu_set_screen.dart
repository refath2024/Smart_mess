import 'package:flutter/material.dart';
import 'user_home_screen.dart';
import 'meal_in_out_screen.dart';
import 'messing.dart';
import 'billing_screen.dart';
import '../login_screen.dart';

class MenuSetScreen extends StatefulWidget {
  const MenuSetScreen({super.key});

  @override
  State<MenuSetScreen> createState() => _MenuSetScreenState();
}

class _MenuSetScreenState extends State<MenuSetScreen> {
  final List<String> _days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  String _selectedDay = 'Sunday';
  String? _selectedBreakfast;
  String? _selectedLunch;
  String? _selectedDinner;
  final TextEditingController _remarksController = TextEditingController();

  void _submitVote() {
    if (_selectedBreakfast == null &&
        _selectedLunch == null &&
        _selectedDinner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one meal set.")),
      );
      return;
    }

    // You can process or send the data here
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Vote Submitted"),
        content: const Text("Your vote has been submitted. Thank you."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSet({
    required String title,
    required String mealType,
    required String? selectedValue,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Column(
          children: List.generate(3, (index) {
            final setId = "${mealType}_set${index + 1}";
            final setText = "Set ${index + 1} - Dummy Meal Description";
            return RadioListTile<String>(
              title: Text(setText),
              value: setId,
              groupValue: selectedValue,
              onChanged: onChanged,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDrawerTile(
    IconData icon,
    String label,
    Widget screen, {
    bool selected = false,
  }) {
    return ListTile(
      selected: selected,
      selectedTileColor: Colors.blue.shade100,
      leading: Icon(icon, color: selected ? Colors.blue : Colors.black),
      title: Text(label),
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => screen),
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
              const Text(
                "Menu Preference Vote",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDay,
                items: _days
                    .map(
                      (day) => DropdownMenuItem(value: day, child: Text(day)),
                    )
                    .toList(),
                decoration: const InputDecoration(
                  labelText: "Select Day",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedDay = value);
                  }
                },
              ),
              const SizedBox(height: 20),
              _buildMealSet(
                title: "Breakfast",
                mealType: "breakfast",
                selectedValue: _selectedBreakfast,
                onChanged: (value) =>
                    setState(() => _selectedBreakfast = value),
              ),
              _buildMealSet(
                title: "Lunch",
                mealType: "lunch",
                selectedValue: _selectedLunch,
                onChanged: (value) => setState(() => _selectedLunch = value),
              ),
              _buildMealSet(
                title: "Dinner",
                mealType: "dinner",
                selectedValue: _selectedDinner,
                onChanged: (value) => setState(() => _selectedDinner = value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _remarksController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Remarks",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitVote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002B5B),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Submit Your Vote",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

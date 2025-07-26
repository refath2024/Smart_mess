import 'package:flutter/material.dart';

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

  Widget _buildMealRow({
    required String mealType,
    required String? selectedValue,
    required Function(String?) onChanged,
  }) {
    List<Map<String, String>> mealSets = [];

    if (mealType == "breakfast") {
      mealSets = [
        {
          'id': '${mealType}_set1',
          'title': 'Ruti, Dal & Vaji',
          'subtitle': '৳ 40',
          'image': '1.png',
        },
        {
          'id': '${mealType}_set2',
          'title': 'Paratha & Egg Curry',
          'subtitle': '৳ 50',
          'image': '2.png',
        },
        {
          'id': '${mealType}_set3',
          'title': 'Khichuri & Beef',
          'subtitle': '৳ 70',
          'image': '3.png',
        },
      ];
    } else if (mealType == "lunch") {
      mealSets = [
        {
          'id': '${mealType}_set1',
          'title': 'Rice & Fish Curry',
          'subtitle': '৳ 60',
          'image': '1.png',
        },
        {
          'id': '${mealType}_set2',
          'title': 'Rice & Chicken Curry',
          'subtitle': '৳ 70',
          'image': '2.png',
        },
        {
          'id': '${mealType}_set3',
          'title': 'Khichuri & Egg curry',
          'subtitle': '৳ 55',
          'image': '3.png',
        },
      ];
    } else if (mealType == "dinner") {
      mealSets = [
        {
          'id': '${mealType}_set1',
          'title': 'Roti & Chicken Curry',
          'subtitle': '৳ 50',
          'image': '1.png',
        },
        {
          'id': '${mealType}_set2',
          'title': 'Paratha & Mixed Veg',
          'subtitle': '৳ 45',
          'image': '2.png',
        },
        {
          'id': '${mealType}_set3',
          'title': 'Rice & Beef Curry',
          'subtitle': '৳ 75',
          'image': '3.png',
        },
      ];
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: mealSets.map((meal) {
        final isSelected = selectedValue == meal['id'];
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(meal['id']),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
              ),
              elevation: 3,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.asset(
                      'assets/${meal['image']}',
                      height: 80,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(meal['title']!,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(meal['subtitle']!),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
              const Text("Breakfast",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildMealRow(
                mealType: "breakfast",
                selectedValue: _selectedBreakfast,
                onChanged: (value) =>
                    setState(() => _selectedBreakfast = value),
              ),
              const SizedBox(height: 20),
              const Text("Lunch",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildMealRow(
                mealType: "lunch",
                selectedValue: _selectedLunch,
                onChanged: (value) => setState(() => _selectedLunch = value),
              ),
              const SizedBox(height: 20),
              const Text("Dinner",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildMealRow(
                mealType: "dinner",
                selectedValue: _selectedDinner,
                onChanged: (value) => setState(() => _selectedDinner = value),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(
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

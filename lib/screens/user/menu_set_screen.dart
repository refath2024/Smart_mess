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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Menu Preference Guidelines",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Voting Process:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "• The menu option receiving the maximum percentage of votes will be considered for implementation from the following week.",
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                "• In case of a tie between options on any day, the final decision rests with the President of the Mess Committee (PMC).",
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                "Important Notice:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "• Menu changes are not mandatory. Officer feedback serves as input for discussion in the next Mess Committee meeting.",
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                "• Final menu decisions are subject to budget constraints, ingredient availability, and committee approval.",
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                "Your participation in this democratic process helps improve mess services for all officers.",
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "UNDERSTOOD",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _submitVote() {
    if (_selectedBreakfast == null &&
        _selectedLunch == null &&
        _selectedDinner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one meal preference."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Vote Submitted Successfully",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Your menu preference has been recorded and will be considered for the next committee review. Thank you for your participation.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "ACKNOWLEDGED",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
          'title': 'Ruti, Dal & Mixed Veg',
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
          'title': 'Khichuri & Egg Curry',
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
              child: SizedBox(
                height: 160, // Fixed height for consistency
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.asset(
                        'assets/${meal['image']}',
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                meal['title']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              meal['subtitle']!,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Menu Preference Vote",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _showHelpDialog,
                    icon: const Icon(
                      Icons.help_outline,
                      color: Color(0xFF002B5B),
                      size: 24,
                    ),
                    tooltip: "Voting Guidelines",
                  ),
                ],
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
                  labelText: "Additional Comments/Suggestions",
                  hintText:
                      "Share your feedback or suggestions for mess improvement...",
                  border: OutlineInputBorder(),
                  helperText:
                      "Optional: Your suggestions will be forwarded to the Mess Committee",
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitVote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002B5B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "SUBMIT PREFERENCE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

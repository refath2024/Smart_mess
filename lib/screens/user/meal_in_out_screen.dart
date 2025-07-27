import 'package:flutter/material.dart';

class MealInOutScreen extends StatefulWidget {
  const MealInOutScreen({super.key});

  @override
  State<MealInOutScreen> createState() => _MealInOutScreenState();
}

class _MealInOutScreenState extends State<MealInOutScreen> {
  final Set<int> _selectedMeals = {}; // Updated to support multiple selections
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
      'selectedMeals': _selectedMeals.toList(),
      'remarks': _remarksController.text.trim(),
      'disposal': _disposalYes,
      'disposalType': _disposalYes ? _disposalType : 'No',
      'from': _disposalYes ? _fromDate?.toIso8601String() : null,
      'to': _disposalYes ? _toDate?.toIso8601String() : null,
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Meal selection submitted')));
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final meals = [
      {
        'label': 'Breakfast',
        'image': 'assets/1.png',
        'name': 'Bhuna Khichuri with Egg',
        'price': '৳ 30'
      },
      {
        'label': 'Lunch',
        'image': 'assets/2.png',
        'name': 'Luchi with alur dom',
        'price': '৳ 150'
      },
      {
        'label': 'Dinner',
        'image': 'assets/3.png',
        'name': 'Luchi with dal curry',
        'price': '৳ 80'
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Select Your Meal",
                    style: textTheme.titleLarge ??
                        const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.help_outline,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text(
                            "Meal Enrollment Information",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF002B5B),
                            ),
                          ),
                          content: const Text(
                            "• These are approximate bills and may vary based on your meal participation and daily market prices of fresh ingredients.\n\n"
                            "• Last time to enroll for meals is 21:00 (9:00 PM) of the current day.\n\n"
                            "• The page will automatically refresh for the next day after 21:00.\n\n"
                            "• Please ensure timely enrollment to avoid meal schedule conflicts.",
                            style: TextStyle(fontSize: 14, height: 1.5),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                "Got it",
                                style: TextStyle(
                                  color: Color(0xFF002B5B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text("For: $_mealDate", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              children: List.generate(meals.length, (index) {
                final meal = meals[index];
                final isSelected = _selectedMeals.contains(index);

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedMeals.remove(index);
                        } else {
                          _selectedMeals.add(index);
                        }
                      });
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: isSelected ? Colors.blue : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15)),
                            child: Image.asset(
                              meal['image']!,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  meal['label']!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  meal['name']!,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  meal['price']!,
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const Divider(height: 32),
            TextField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
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

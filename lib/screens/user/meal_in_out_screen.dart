import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MealInOutScreen extends StatefulWidget {
  const MealInOutScreen({super.key});

  @override
  State<MealInOutScreen> createState() => _MealInOutScreenState();
}

class _MealInOutScreenState extends State<MealInOutScreen> {
  final Set<int> _selectedMeals = {};
  final _remarksController = TextEditingController();
  bool _disposalYes = false;
  String _disposalType = 'SIQ';
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isSubmitting = false;

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String get _mealDate {
    final now = DateTime.now();
    final target =
        now.hour >= 21 ? now.add(const Duration(days: 2)) : now.add(const Duration(days: 1));
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

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to submit.")),
      );
      return;
    }
    if (_selectedMeals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one meal.")),
      );
      return;
    }
    if (_disposalYes &&
        (_fromDate == null || _toDate == null || _toDate!.isBefore(_fromDate!))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please select valid From/To dates for disposal.")));
      return;
    }

    // Get meal details with prices
    final meals = [
      {
        'label': 'Breakfast',
        'image': 'assets/1.png',
        'name': 'Bhuna Khichuri with Egg',
        'price': '৳ 30',
        'priceValue': 30.0
      },
      {
        'label': 'Lunch',
        'image': 'assets/2.png',
        'name': 'Luchi with alur dom',
        'price': '৳ 150',
        'priceValue': 150.0
      },
      {
        'label': 'Dinner',
        'image': 'assets/3.png',
        'name': 'Luchi with dal curry',
        'price': '৳ 80',
        'priceValue': 80.0
      },
    ];

    // Calculate selected meals with details and total cost
    final selectedMealDetails = _selectedMeals.map((index) {
      final meal = meals[index];
      return {
        'mealType': meal['label'] as String,
        'mealName': meal['name'] as String,
        'price': meal['priceValue'] as double,
        'priceDisplay': meal['price'] as String,
      };
    }).toList();

    final totalCost = selectedMealDetails.fold<double>(
      0.0, 
      (sum, meal) => sum + (meal['price'] as double)
    );

    final data = {
      'userId': user.uid,
      'date': _mealDate,
      'selectedMeals': _selectedMeals.toList(),
      'selectedMealDetails': selectedMealDetails,
      'totalCost': totalCost,
      'remarks': _remarksController.text.trim(),
      'disposal': _disposalYes,
      'disposalType': _disposalYes ? _disposalType : 'No',
      'from': _disposalYes ? _fromDate?.toIso8601String() : null,
      'to': _disposalYes ? _toDate?.toIso8601String() : null,
      'timestamp': FieldValue.serverTimestamp(),
    };

    setState(() {
      _isSubmitting = true;
    });
    try {
      // Store in the main meals collection
      await FirebaseFirestore.instance
          .collection('meals')
          .doc(user.uid)
          .collection('entries')
          .add(data);

      // Also store in a separate collection for easy messing calculations
      await FirebaseFirestore.instance
          .collection('messing_data')
          .doc('${user.uid}_$_mealDate')
          .set({
        'userId': user.uid,
        'date': _mealDate,
        'meals': selectedMealDetails,
        'totalCost': totalCost,
        'timestamp': FieldValue.serverTimestamp(),
        'disposal': _disposalYes,
        'disposalType': _disposalYes ? _disposalType : 'No',
        'disposalFrom': _disposalYes ? _fromDate?.toIso8601String() : null,
        'disposalTo': _disposalYes ? _toDate?.toIso8601String() : null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meal selection submitted (Total: ৳${totalCost.toStringAsFixed(0)})')),
      );
      setState(() {
        _selectedMeals.clear();
        _remarksController.clear();
        _disposalYes = false;
        _fromDate = null;
        _toDate = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  // Helper method to get meal-specific colors
  Color _getMealColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  // Helper method to get meal-specific icons
  IconData _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final meals = [
      {
        'label': 'Breakfast',
        'image': 'assets/1.png',
        'name': 'Bhuna Khichuri with Egg',
        'price': '৳ 30',
        'priceValue': 30.0
      },
      {
        'label': 'Lunch',
        'image': 'assets/2.png',
        'name': 'Luchi with alur dom',
        'price': '৳ 150',
        'priceValue': 150.0
      },
      {
        'label': 'Dinner',
        'image': 'assets/3.png',
        'name': 'Luchi with dal curry',
        'price': '৳ 80',
        'priceValue': 80.0
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
                        const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(15)),
                            child: Image.asset(
                              meal['image']! as String,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback when image is not found
                                return Container(
                                  height: 100,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _getMealColor(meal['label']! as String).withOpacity(0.7),
                                        _getMealColor(meal['label']! as String),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Icon(
                                    _getMealIcon(meal['label']! as String),
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  meal['label']! as String,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  meal['name']! as String,
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey.shade700),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  meal['price']! as String,
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
                        _fromDate == null ? 'From Date' : _formatDate(_fromDate!),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002B5B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Submit",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

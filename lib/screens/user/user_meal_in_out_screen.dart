import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MealInOutScreen extends StatefulWidget {
  const MealInOutScreen({super.key});

  @override
  State<MealInOutScreen> createState() => _MealInOutScreenState();
}

class _MealInOutScreenState extends State<MealInOutScreen> {
  final Set<String> _selectedMeals =
      {}; // Changed to String to store meal types
  final _remarksController = TextEditingController();
  bool _disposalYes = false;
  String _disposalType = 'SIQ';
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isSubmitting = false;
  bool _isLoading = true;

  // Menu data from Firebase
  List<Map<String, dynamic>> _availableMeals = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMenuData();
    });
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String get _mealDate {
    final now = DateTime.now();
    // Before 21:00: Submit for next day
    // After 21:00: Submit for day after next (next day submission is closed)
    final target = now.hour >= 21
        ? now.add(const Duration(days: 2)) // Day after next
        : now.add(const Duration(days: 1)); // Next day
    return _formatDate(target);
  }

  Future<void> _fetchMenuData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final menuDoc = await FirebaseFirestore.instance
          .collection('monthly_menu')
          .doc(_mealDate)
          .get();

      if (menuDoc.exists) {
        final data = menuDoc.data() as Map<String, dynamic>;

        _availableMeals = [];

        // Extract breakfast, lunch, dinner data
        final mealTypes = ['breakfast', 'lunch', 'dinner'];

        for (String mealType in mealTypes) {
          if (data.containsKey(mealType)) {
            final mealData = data[mealType] as Map<String, dynamic>;
            _availableMeals.add({
              'type': mealType,
              'item': mealData['item'] ?? 'No item available',
              'price': (mealData['price'] as num?)?.toDouble() ?? 0.0,
              'displayName': mealType.substring(0, 1).toUpperCase() +
                  mealType.substring(1),
            });
          }
        }
      } else {
        // Fallback data if no menu found
        _availableMeals = [
          {
            'type': 'breakfast',
            'item': 'Bhuna Khichuri with Egg',
            'price': 30.0,
            'displayName': 'Breakfast'
          },
          {
            'type': 'lunch',
            'item': 'Luchi with alur dom',
            'price': 150.0,
            'displayName': 'Lunch'
          },
          {
            'type': 'dinner',
            'item': 'Luchi with dal curry',
            'price': 80.0,
            'displayName': 'Dinner'
          },
        ];
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching menu data: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading menu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        (_fromDate == null ||
            _toDate == null ||
            _toDate!.isBefore(_fromDate!))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please select valid From/To dates for disposal.")));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get user profile data for BA number, name, and rank
      final userDoc = await FirebaseFirestore.instance
          .collection('user_requests')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw 'User profile not found. Please complete your profile first.';
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final baNo = userData['ba_no'] as String? ?? '';
      final userName = userData['name'] as String? ?? '';
      final userRank = userData['rank'] as String? ?? '';

      if (baNo.isEmpty) {
        throw 'BA number not found in profile. Please update your profile.';
      }

      // Check if data already exists for this date and user
      final existingDataDoc = await FirebaseFirestore.instance
          .collection('user_meal_state')
          .doc(_mealDate)
          .get();

      bool dataExists = false;
      if (existingDataDoc.exists) {
        final existingData = existingDataDoc.data() as Map<String, dynamic>;
        dataExists = existingData.containsKey(baNo);
      }

      if (dataExists) {
        // Show confirmation dialog for update
        final shouldUpdate = await _showUpdateConfirmationDialog();
        if (!shouldUpdate) {
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
      }

      // Prepare meal selection data
      final mealSelections = <String, bool>{
        'breakfast': _selectedMeals.contains('breakfast'),
        'lunch': _selectedMeals.contains('lunch'),
        'dinner': _selectedMeals.contains('dinner'),
      };

      // Prepare user data
      final userData_toSave = {
        'name': userName,
        'rank': userRank,
        'breakfast': mealSelections['breakfast'] ?? false,
        'lunch': mealSelections['lunch'] ?? false,
        'dinner': mealSelections['dinner'] ?? false,
        'remarks': _remarksController.text.trim(),
        'disposal': _disposalYes,
        'disposal_type': _disposalYes ? _disposalType : '',
        'disposal_from': _disposalYes ? _formatDate(_fromDate!) : '',
        'disposal_to': _disposalYes ? _formatDate(_toDate!) : '',
        'timestamp': FieldValue.serverTimestamp(),
        'admin_generated': false, // User submitted
      };

      // Save to user_meal_state collection
      await FirebaseFirestore.instance
          .collection('user_meal_state')
          .doc(_mealDate)
          .set({
        baNo: userData_toSave,
      }, SetOptions(merge: true));

      // Calculate total cost for feedback
      double totalCost = 0.0;
      for (String mealType in _selectedMeals) {
        final meal = _availableMeals.firstWhere(
          (m) => m['type'] == mealType,
          orElse: () => {'price': 0.0},
        );
        totalCost += meal['price'] as double;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dataExists
              ? 'Meal selection updated successfully! (Estimated: ৳${totalCost.toStringAsFixed(0)})'
              : 'Meal selection submitted successfully! (Estimated: ৳${totalCost.toStringAsFixed(0)})'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      setState(() {
        _selectedMeals.clear();
        _remarksController.clear();
        _disposalYes = false;
        _fromDate = null;
        _toDate = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<bool> _showUpdateConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'Data Already Exists',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002B5B),
                ),
              ),
              content: Text(
                'You have already submitted meal selection for $_mealDate.\n\nDo you want to update your selection?',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002B5B),
                  ),
                  child: const Text(
                    'Update',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
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

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading menu...'),
                  ],
                ),
              )
            : ListView(
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
                                  "• Before 21:00 (9:00 PM): You can enroll for NEXT day's meals.\n\n"
                                  "• After 21:00: You can only enroll for the DAY AFTER NEXT (next day's enrollment is closed).\n\n"
                                  "• This allows cooks adequate time to prepare meals based on enrollment numbers.\n\n"
                                  "• Please ensure timely enrollment to avoid meal schedule conflicts.",
                                  style: TextStyle(fontSize: 14, height: 1.5),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: DateTime.now().hour >= 21
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: DateTime.now().hour >= 21
                            ? Colors.orange.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: DateTime.now().hour >= 21
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DateTime.now().hour >= 21
                                ? "⚠️ After 21:00 - Submitting for: $_mealDate (Day after next)"
                                : "✅ Before 21:00 - Submitting for: $_mealDate (Next day)",
                            style: TextStyle(
                              color: DateTime.now().hour >= 21
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Professional meal cards
                  ...List.generate(_availableMeals.length, (index) {
                    final meal = _availableMeals[index];
                    final mealType = meal['type'] as String;
                    final isSelected = _selectedMeals.contains(mealType);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF002B5B)
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedMeals.remove(mealType);
                              } else {
                                _selectedMeals.add(mealType);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Meal type icon
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF002B5B)
                                            .withOpacity(0.1)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF002B5B)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Icon(
                                    _getMealIcon(mealType),
                                    color: isSelected
                                        ? const Color(0xFF002B5B)
                                        : Colors.grey.shade600,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Meal details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        meal['displayName'] as String,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF002B5B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        meal['item'] as String,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Price
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF002B5B)
                                        : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '৳ ${(meal['price'] as double).toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.green.shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Selection indicator
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? const Color(0xFF002B5B)
                                      : Colors.grey.shade400,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  const Divider(height: 32),

                  // Rest of the form remains the same
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
                      const Text(
                        "Disposal? ",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Switch(
                        value: _disposalYes,
                        onChanged: (v) => setState(() => _disposalYes = v),
                        activeColor: const Color(0xFF002B5B),
                      ),
                    ],
                  ),
                  if (_disposalYes) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _disposalType,
                      decoration: const InputDecoration(
                        labelText: 'Select Disposal Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['SIQ', 'Leave']
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _disposalType = v!),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(isFrom: true),
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              _fromDate == null
                                  ? 'From Date'
                                  : _formatDate(_fromDate!),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(isFrom: false),
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              _toDate == null
                                  ? 'To Date'
                                  : _formatDate(_toDate!),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                          : const Text(
                              "Submit Meal Selection",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

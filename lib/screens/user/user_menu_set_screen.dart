import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> _submitVote() async {
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

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Submitting your vote..."),
          ],
        ),
      ),
    );

    try {
      // Get current user information
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Get user details from users collection or staff_state collection
      String userName = "Unknown User";
      String userRole = "user";
      String baNo = "";

      try {
        // First try to get from users collection
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          userName = userData['name'] ?? currentUser.displayName ?? "Unknown User";
          userRole = userData['role'] ?? "user";
          baNo = userData['ba_no'] ?? "";
        } else {
          // Try staff_state collection if not found in users
          final staffQuery = await FirebaseFirestore.instance
              .collection('staff_state')
              .where('email', isEqualTo: currentUser.email)
              .limit(1)
              .get();
          
          if (staffQuery.docs.isNotEmpty) {
            final staffData = staffQuery.docs.first.data();
            userName = staffData['name'] ?? "Unknown User";
            userRole = staffData['role'] ?? "staff";
            baNo = staffData['ba_no'] ?? "";
          }
        }
      } catch (e) {
        debugPrint("Error fetching user details: $e");
        userName = currentUser.displayName ?? currentUser.email ?? "Unknown User";
      }

      // Generate week identifier for grouping votes
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final weekIdentifier = "${monday.year}-W${_getWeekNumber(monday)}";
      final votingPeriod = "${now.year}-${now.month.toString().padLeft(2, '0')}";

      // Create voting record data
      final votingData = {
        'userId': currentUser.uid,
        'userEmail': currentUser.email,
        'userName': userName,
        'userRole': userRole,
        'baNo': baNo,
        'selectedDay': _selectedDay,
        'selectedBreakfast': _selectedBreakfast,
        'selectedLunch': _selectedLunch,
        'selectedDinner': _selectedDinner,
        'remarks': _remarksController.text.trim(),
        'submittedAt': FieldValue.serverTimestamp(),
        'weekIdentifier': weekIdentifier,
        'votingPeriod': votingPeriod,
        'status': 'submitted',
      };

      // Store in voting_records collection
      await FirebaseFirestore.instance
          .collection('voting_records')
          .add(votingData);

      debugPrint("✅ Voting record saved successfully");
      
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text(
              "Vote Submitted Successfully",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your menu preference has been recorded and will be considered for the next committee review. Thank you for your participation.",
                ),
                const SizedBox(height: 12),
                Text(
                  "Vote Details:",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Day: $_selectedDay"),
                if (_selectedBreakfast != null) Text("Breakfast: $_selectedBreakfast"),
                if (_selectedLunch != null) Text("Lunch: $_selectedLunch"),
                if (_selectedDinner != null) Text("Dinner: $_selectedDinner"),
                if (_remarksController.text.isNotEmpty) 
                  Text("Remarks: ${_remarksController.text}"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetForm(); // Reset form after successful submission
                },
                child: const Text(
                  "ACKNOWLEDGED",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      debugPrint("❌ Error submitting vote: $e");
      
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show error dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit vote: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Get week number of the year
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  /// Reset form after successful submission
  void _resetForm() {
    setState(() {
      _selectedDay = 'Sunday';
      _selectedBreakfast = null;
      _selectedLunch = null;
      _selectedDinner = null;
      _remarksController.clear();
    });
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
          'title': 'Bhuna Khichuri',
          'subtitle': '৳ 40',
          'image': '1.png',
        },
        {
          'id': '${mealType}_set2',
          'title': 'Luchi with Alur dom',
          'subtitle': '৳ 50',
          'image': '2.png',
        },
        {
          'id': '${mealType}_set3',
          'title': 'Luchi with curry',
          'subtitle': '৳ 70',
          'image': '3.png',
        },
      ];
    } else if (mealType == "lunch") {
      mealSets = [
        {
          'id': '${mealType}_set1',
          'title': 'Bhuna Khichuri',
          'subtitle': '৳ 60',
          'image': '1.png',
        },
        {
          'id': '${mealType}_set2',
          'title': 'Luchi with Alur dom',
          'subtitle': '৳ 70',
          'image': '2.png',
        },
        {
          'id': '${mealType}_set3',
          'title': 'Luchi with curry',
          'subtitle': '৳ 55',
          'image': '3.png',
        },
      ];
    } else if (mealType == "dinner") {
      mealSets = [
        {
          'id': '${mealType}_set1',
          'title': 'Bhuna Khichuri',
          'subtitle': '৳ 50',
          'image': '1.png',
        },
        {
          'id': '${mealType}_set2',
          'title': 'Luchi with Alur dom',
          'subtitle': '৳ 45',
          'image': '2.png',
        },
        {
          'id': '${mealType}_set3',
          'title': 'Luchi with curry',
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
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          meal['title']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
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

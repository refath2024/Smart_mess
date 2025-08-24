import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/language_provider.dart';
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
import 'admin_bill_screen.dart';
import 'admin_login_screen.dart';
import '../../services/admin_auth_service.dart';
import '../../services/menu_set_service.dart';
import '../../services/voting_statistics_service.dart';

class MenuVoteScreen extends StatefulWidget {
  const MenuVoteScreen({super.key});

  @override
  State<MenuVoteScreen> createState() => _MenuVoteScreenState();
}

class _MenuVoteScreenState extends State<MenuVoteScreen> {
  final AdminAuthService _adminAuthService = AdminAuthService();

  bool _isLoading = true;
  String _currentUserName =
      "Admin User"; // This is just a fallback, will be updated from Firebase
  Map<String, dynamic>? _currentUserData;
  int _totalVoteCount = 0; // Store total vote count

  // Admin voting control state
  bool _isVotingEnabled = false;
  bool _isLoadingVotingStatus = true;

  final TextEditingController _searchController = TextEditingController();
  String selectedDay = 'Sunday';

  // Menu Set configuration state variables
  Map<String, Map<String, List<Map<String, dynamic>>>> _menuSets = {};
  bool _isLoadingMenuSets = false;
  String _menuSetSelectedDay = 'Sunday';
  String _selectedMealType = 'breakfast';

  // Controllers for 3 options
  final List<TextEditingController> _menuTitleControllers =
      List.generate(3, (index) => TextEditingController());
  final List<TextEditingController> _menuPriceControllers =
      List.generate(3, (index) => TextEditingController());
  final List<TextEditingController> _menuImageControllers =
      List.generate(3, (index) => TextEditingController());

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    // _filteredMealData = Map.from(mealData); // Initialize filtered data
    _getData();
    _debugFetchAllRecords(); // Debug: Check available data
    _loadMenuSets(); // Load menu sets
    _loadVotingStatus(); // Load admin voting control status
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Dispose menu set controllers
    for (var controller in _menuTitleControllers) {
      controller.dispose();
    }
    for (var controller in _menuPriceControllers) {
      controller.dispose();
    }
    for (var controller in _menuImageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    try {
      final isLoggedIn = await _adminAuthService.isAdminLoggedIn();

      if (!isLoggedIn) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
            (route) => false,
          );
        }

        return;
      }

      // Get current admin data
      final userData = await _adminAuthService.getCurrentAdminData();
      if (userData != null && mounted) {
        setState(() {
          _currentUserData = userData;
          _currentUserName = userData['name'] ??
              'Admin User'; // Fallback string since context might not be available
          _isLoading = false;
        });
      } else {
        // User data not found, redirect to login
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      // Authentication error, redirect to login
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _getData() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
      });

      final date = DateTime.now();
      final weekIdentifier = "${date.year}-W${_getWeekNumber(date)}";

      print('=== FETCHING VOTING DATA ===');
      print(
          'Fetching voting data for day: $selectedDay, week: $weekIdentifier');
      print('Current date: $date');

      // Try multiple query strategies to find data
      QuerySnapshot data;

      // Strategy 1: Query by day and week identifier
      data = await FirebaseFirestore.instance
          .collection('voting_records')
          .where('selectedDay', isEqualTo: selectedDay)
          .where('weekIdentifier', isEqualTo: weekIdentifier)
          .get();

      print(
          'Strategy 1 - Found ${data.docs.length} records with week identifier');

      // Strategy 2: If no data found, try just by selected day
      if (data.docs.isEmpty) {
        print('Strategy 2 - Trying query by day only...');
        data = await FirebaseFirestore.instance
            .collection('voting_records')
            .where('selectedDay', isEqualTo: selectedDay)
            .get();
        print('Strategy 2 - Found ${data.docs.length} records by day only');
      }

      // Strategy 3: If still no data, try to get any recent data
      if (data.docs.isEmpty) {
        print('Strategy 3 - Trying to get any recent voting records...');
        data = await FirebaseFirestore.instance
            .collection('voting_records')
            .orderBy('submittedAt', descending: true)
            .limit(20)
            .get();
        print('Strategy 3 - Found ${data.docs.length} recent records');

        // Filter by selected day from the recent records
        if (data.docs.isNotEmpty) {
          final filteredDocs = data.docs.where((doc) {
            final docData = doc.data() as Map<String, dynamic>?;
            return docData?['selectedDay'] == selectedDay;
          }).toList();

          // Create a new QuerySnapshot-like structure
          data = await FirebaseFirestore.instance
              .collection('voting_records')
              .where('selectedDay', isEqualTo: selectedDay)
              .get();

          print(
              'Strategy 3 - After filtering by day: ${filteredDocs.length} records');
        }
      }

      // Debug: Print document structure
      if (data.docs.isNotEmpty) {
        print('=== SAMPLE DOCUMENT ANALYSIS ===');
        final sampleDoc = data.docs.first.data() as Map<String, dynamic>?;
        if (sampleDoc != null) {
          print('Sample document structure: $sampleDoc');
          print('Document fields: ${sampleDoc.keys.toList()}');
          print('selectedDay: ${sampleDoc['selectedDay']}');
          print('selectedBreakfast: ${sampleDoc['selectedBreakfast']}');
          print('selectedLunch: ${sampleDoc['selectedLunch']}');
          print('selectedDinner: ${sampleDoc['selectedDinner']}');
          print('weekIdentifier: ${sampleDoc['weekIdentifier']}');
        }
      } else {
        print('=== NO DOCUMENTS FOUND ===');
        print('This could mean:');
        print('1. No users have voted yet');
        print('2. No votes for the selected day ($selectedDay)');
        print('3. Different week identifier format');
        print('4. Data is stored with different field names');
      }

      final totalvote = data.docs.length;

      // Initialize vote counts
      Map<String, int> breakfastCounts = {
        'breakfast_set1': 0,
        'breakfast_set2': 0,
        'breakfast_set3': 0
      };
      Map<String, int> lunchCounts = {
        'lunch_set1': 0,
        'lunch_set2': 0,
        'lunch_set3': 0
      };
      Map<String, int> dinnerCounts = {
        'dinner_set1': 0,
        'dinner_set2': 0,
        'dinner_set3': 0
      };

      // Count votes for each meal type and set
      for (var doc in data.docs) {
        final docData = doc.data() as Map<String, dynamic>?;

        if (docData == null) continue;

        // Debug: Print each document's data
        print('Document data: $docData');

        // Count breakfast votes - check multiple possible field names
        final selectedBreakfast = docData['selectedBreakfast'] ??
            docData['breakfast'] ??
            docData['breakfast_choice'];
        if (selectedBreakfast != null &&
            breakfastCounts.containsKey(selectedBreakfast)) {
          breakfastCounts[selectedBreakfast] =
              breakfastCounts[selectedBreakfast]! + 1;
        } else if (selectedBreakfast != null) {
          print('Unknown breakfast choice: $selectedBreakfast');
        }

        // Count lunch votes - check multiple possible field names
        final selectedLunch = docData['selectedLunch'] ??
            docData['lunch'] ??
            docData['lunch_choice'];
        if (selectedLunch != null && lunchCounts.containsKey(selectedLunch)) {
          lunchCounts[selectedLunch] = lunchCounts[selectedLunch]! + 1;
        } else if (selectedLunch != null) {
          print('Unknown lunch choice: $selectedLunch');
        }

        // Count dinner votes - check multiple possible field names
        final selectedDinner = docData['selectedDinner'] ??
            docData['dinner'] ??
            docData['dinner_choice'];
        if (selectedDinner != null &&
            dinnerCounts.containsKey(selectedDinner)) {
          dinnerCounts[selectedDinner] = dinnerCounts[selectedDinner]! + 1;
        } else if (selectedDinner != null) {
          print('Unknown dinner choice: $selectedDinner');
        }
      }

      // Calculate percentages
      Map<String, Map<String, double>> vote = {
        'breakfast': {},
        'lunch': {},
        'dinner': {},
      };

      if (totalvote > 0) {
        // Calculate breakfast percentages
        breakfastCounts.forEach((key, value) {
          vote['breakfast']![key] = (value / totalvote) * 100;
        });

        // Calculate lunch percentages
        lunchCounts.forEach((key, value) {
          vote['lunch']![key] = (value / totalvote) * 100;
        });

        // Calculate dinner percentages
        dinnerCounts.forEach((key, value) {
          vote['dinner']![key] = (value / totalvote) * 100;
        });
      } else {
        // No votes found, set all percentages to 0
        vote = {
          'breakfast': {
            'breakfast_set1': 0.0,
            'breakfast_set2': 0.0,
            'breakfast_set3': 0.0
          },
          'lunch': {'lunch_set1': 0.0, 'lunch_set2': 0.0, 'lunch_set3': 0.0},
          'dinner': {
            'dinner_set1': 0.0,
            'dinner_set2': 0.0,
            'dinner_set3': 0.0
          },
        };
      }

      print('Calculated vote percentages: $vote');
      print(
          'Total votes counted: Breakfast: ${breakfastCounts.values.reduce((a, b) => a + b)}, Lunch: ${lunchCounts.values.reduce((a, b) => a + b)}, Dinner: ${dinnerCounts.values.reduce((a, b) => a + b)}');

      debugPrint("🔍 Fetching dynamic voting data for day: $selectedDay");
      
      // Get voting statistics using the new service
      final votingStats = await VotingStatisticsService.getVotingStatisticsForDay(selectedDay);
      final totalVoteCount = await VotingStatisticsService.getTotalVoteCountForDay(selectedDay);
      
      // Convert the statistics to the format expected by the UI
      Map<String, Map<String, double>> formattedMealData = {};
      
      for (String mealType in ['breakfast', 'lunch', 'dinner']) {
        final percentages = votingStats[mealType]!['percentages'] as Map<String, double>;
        formattedMealData[mealType] = percentages;
      }

      debugPrint("✅ Dynamic voting data loaded successfully");
      debugPrint("   Total votes: $totalVoteCount");
      debugPrint("   Meal data: $formattedMealData");
      
      // Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _isLoading = false;
          mealData = formattedMealData;
          _totalVoteCount = totalVoteCount;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching dynamic voting data: $e");
      // Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Set default empty data on error
          mealData = {
            'breakfast': {
              'breakfast_set1': 0.0,
              'breakfast_set2': 0.0,
              'breakfast_set3': 0.0
            },
            'lunch': {'lunch_set1': 0.0, 'lunch_set2': 0.0, 'lunch_set3': 0.0},
            'dinner': {
              'dinner_set1': 0.0,
              'dinner_set2': 0.0,
              'dinner_set3': 0.0
            },
            'breakfast': {},
            'lunch': {},
            'dinner': {},
          };
          _totalVoteCount = 0;
        });
      }
    }
  }

  // Debug method to fetch all voting records
  Future<void> _debugFetchAllRecords() async {
    try {
      final allData =
          await FirebaseFirestore.instance.collection('voting_records').get();

      if (allData.docs.isNotEmpty) {
        Set<String> availableDays = {};
        Set<String> availableWeeks = {};
        Map<String, List<Map<String, dynamic>>> dayVotes = {};

        for (var doc in allData.docs) {
          final data = doc.data();
          final day = data['selectedDay'] as String?;
          final userName = data['userName'] as String? ?? 'Unknown User';
          final userEmail = data['userEmail'] as String? ?? 'No email';
          final breakfast =
              data['selectedBreakfast'] as String? ?? 'No selection';
          final lunch = data['selectedLunch'] as String? ?? 'No selection';
          final dinner = data['selectedDinner'] as String? ?? 'No selection';
          final weekId = data['weekIdentifier'] as String? ?? 'No week';
          final submittedAt = data['submittedAt']?.toString() ?? 'No timestamp';

          if (day != null) {
            availableDays.add(day);
            if (!dayVotes.containsKey(day)) {
              dayVotes[day] = [];
            }
            dayVotes[day]!.add({
              'userName': userName,
              'userEmail': userEmail,
              'breakfast': breakfast,
              'lunch': lunch,
              'dinner': dinner,
              'weekIdentifier': weekId,
              'submittedAt': submittedAt,
            });
          }

          if (data['weekIdentifier'] != null) {
            availableWeeks.add(data['weekIdentifier']);
          }
        }

        // Show debug dialog with user voting details
        _showDebugDialog(
            dayVotes, availableDays, availableWeeks, allData.docs.length);
      } else {
        // Show dialog saying no records found and add test data
        _showNoRecordsDialog();
      }
    } catch (e) {
      _showErrorDialog('Error fetching debug data: $e');
    }
  }

  void _showDebugDialog(Map<String, List<Map<String, dynamic>>> dayVotes,
      Set<String> availableDays, Set<String> availableWeeks, int totalRecords) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'User Voting Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A4D8F),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Total Records: $totalRecords | Days: ${availableDays.join(", ")} | Weeks: ${availableWeeks.join(", ")}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: DefaultTabController(
                    length: availableDays.length,
                    child: Column(
                      children: [
                        TabBar(
                          isScrollable: true,
                          labelColor: const Color(0xFF1A4D8F),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: const Color(0xFF1A4D8F),
                          tabs: availableDays
                              .map((day) => Tab(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(day),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1A4D8F),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${dayVotes[day]?.length ?? 0}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: TabBarView(
                            children: availableDays
                                .map((day) => _buildDayVotesWidget(
                                    day, dayVotes[day] ?? []))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayVotesWidget(String day, List<Map<String, dynamic>> votes) {
    if (votes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No votes for $day',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vote summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              '$day - ${votes.length} vote(s)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Individual votes
          ...votes.asMap().entries.map((entry) {
            final index = entry.key;
            final vote = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF1A4D8F),
                        radius: 16,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vote['userName'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              vote['userEmail'],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMealSelection(
                            '🥞', 'Breakfast', vote['breakfast']),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child:
                            _buildMealSelection('🍛', 'Lunch', vote['lunch']),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMealSelection(
                            '🍽️', 'Dinner', vote['dinner']),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Week: ${vote['weekIdentifier']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMealSelection(String emoji, String mealType, String selection) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            mealType,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            selection.replaceAll('_set', ' ').replaceAll('_', ' '),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showNoRecordsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.inbox_outlined, color: Colors.orange),
              SizedBox(width: 8),
              Text('No Records Found'),
            ],
          ),
          content: const Text(
            'No voting records found in the database. Would you like to add some test data for demonstration?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _addTestVotingData();
                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test data added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A4D8F),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Test Data'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Add test voting data for demonstration
  Future<void> _addTestVotingData() async {
    try {
      print('Adding test voting data...');
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final weekIdentifier = "${monday.year}-W${_getWeekNumber(monday)}";

      // Add test votes for different days
      final testVotes = [
        {
          'userId': 'test_user_1',
          'userEmail': 'test1@example.com',
          'userName': 'Test User 1',
          'selectedDay': 'Sunday',
          'selectedBreakfast': 'breakfast_set1',
          'selectedLunch': 'lunch_set2',
          'selectedDinner': 'dinner_set1',
          'weekIdentifier': weekIdentifier,
          'submittedAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': 'test_user_2',
          'userEmail': 'test2@example.com',
          'userName': 'Test User 2',
          'selectedDay': 'Sunday',
          'selectedBreakfast': 'breakfast_set2',
          'selectedLunch': 'lunch_set1',
          'selectedDinner': 'dinner_set2',
          'weekIdentifier': weekIdentifier,
          'submittedAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': 'test_user_3',
          'userEmail': 'test3@example.com',
          'userName': 'Test User 3',
          'selectedDay': 'Sunday',
          'selectedBreakfast': 'breakfast_set1',
          'selectedLunch': 'lunch_set3',
          'selectedDinner': 'dinner_set1',
          'weekIdentifier': weekIdentifier,
          'submittedAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': 'test_user_4',
          'userEmail': 'test4@example.com',
          'userName': 'Test User 4',
          'selectedDay': 'Monday',
          'selectedBreakfast': 'breakfast_set3',
          'selectedLunch': 'lunch_set2',
          'selectedDinner': 'dinner_set3',
          'weekIdentifier': weekIdentifier,
          'submittedAt': FieldValue.serverTimestamp(),
        },
      ];

      for (var vote in testVotes) {
        await FirebaseFirestore.instance.collection('voting_records').add(vote);
      }

      print('Test voting data added successfully');
    } catch (e) {
      print('Error adding test data: $e');
    }
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  // Data structure for meal votes
  // Data structure for meal votes - now dynamic based on admin configurations
  Map<String, Map<String, double>> mealData = {
    'breakfast': {
      'breakfast_set1': 0.0,
      'breakfast_set2': 0.0,
      'breakfast_set3': 0.0
    },
    'lunch': {'lunch_set1': 0.0, 'lunch_set2': 0.0, 'lunch_set3': 0.0},
    'dinner': {'dinner_set1': 0.0, 'dinner_set2': 0.0, 'dinner_set3': 0.0}
    'breakfast': {},
    'lunch': {},
    'dinner': {},
  };

  final List<String> days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  // Method to get localized day name
  String getLocalizedDay(BuildContext context, String day) {
    switch (day) {
      case 'Sunday':
        return AppLocalizations.of(context)!.sunday;
      case 'Monday':
        return AppLocalizations.of(context)!.monday;
      case 'Tuesday':
        return AppLocalizations.of(context)!.tuesday;
      case 'Wednesday':
        return AppLocalizations.of(context)!.wednesday;
      case 'Thursday':
        return AppLocalizations.of(context)!.thursday;
      case 'Friday':
        return AppLocalizations.of(context)!.friday;
      case 'Saturday':
        return AppLocalizations.of(context)!.saturday;
      default:
        return day;
    }
  }

  // Method to get localized meal type name
  String getLocalizedMealType(BuildContext context, String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return AppLocalizations.of(context)!.breakfast;
      case 'lunch':
        return AppLocalizations.of(context)!.lunch;
      case 'dinner':
        return AppLocalizations.of(context)!.dinner;
      default:
        return mealType;
    }
  }

  // Method to get localized food item name
  String getLocalizedFoodItem(BuildContext context, String foodItem) {
    switch (foodItem) {
      case 'breakfast_set1':
        return 'Bhuna Khichuri'; // Example localized name
      case 'breakfast_set2':
        return 'Luchi with Alur dom'; // Example localized name
      case 'breakfast_set3':
        return 'Luchi with curry'; // Example localized name
      case 'lunch_set1':
        return 'Bhuna Khichuri'; // Example localized name
      case 'lunch_set2':
        return 'Luchi with Alur dom'; // Example localized name
      case 'lunch_set3':
        return 'Luchi with curry'; // Example localized name
      case 'dinner_set1':
        return 'Bhuna Khichuri'; // Example localized name
      case 'dinner_set2':
        return 'Luchi with Alur dom'; // Example localized name
      case 'dinner_set3':
        return 'Luchi with curry'; // Example localized name

      default:
        return foodItem;
    }
  }

  // Search functionality implementation

  // Method to update dynamic remarks instantly
  void _updateRemarks(BuildContext context) {
    // Check if widget is still mounted before calling setState
    if (!mounted) return;

    setState(() {
      dynamicRemarks = []; // Clear previous remarks

      // Localized remarks based on selectedDay
      if (selectedDay == 'Sunday') {
        dynamicRemarks = [
          AppLocalizations.of(context)!.sundayRemark1,
          AppLocalizations.of(context)!.sundayRemark2,
          AppLocalizations.of(context)!.sundayRemark3,
        ];
      } else if (selectedDay == 'Monday') {
        dynamicRemarks = [
          AppLocalizations.of(context)!.mondayRemark1,
          AppLocalizations.of(context)!.mondayRemark2,
          AppLocalizations.of(context)!.mondayRemark3,
        ];
      } else if (selectedDay == 'Tuesday') {
        dynamicRemarks = [
          AppLocalizations.of(context)!.tuesdayRemark1,
          AppLocalizations.of(context)!.tuesdayRemark2,
          AppLocalizations.of(context)!.tuesdayRemark3,
        ];
      } else if (selectedDay == 'Wednesday') {
        dynamicRemarks = [
          AppLocalizations.of(context)!.wednesdayRemark1,
          AppLocalizations.of(context)!.wednesdayRemark2,
          AppLocalizations.of(context)!.wednesdayRemark3,
        ];
      } else if (selectedDay == 'Thursday') {
        dynamicRemarks = [
          AppLocalizations.of(context)!.thursdayRemark1,
          AppLocalizations.of(context)!.thursdayRemark2,
          AppLocalizations.of(context)!.thursdayRemark3,
        ];
      } else if (selectedDay == 'Friday') {
        dynamicRemarks = [
          AppLocalizations.of(context)!.fridayRemark1,
          AppLocalizations.of(context)!.fridayRemark2,
          AppLocalizations.of(context)!.fridayRemark3,
        ];
      } else if (selectedDay == 'Saturday') {
        dynamicRemarks = [
          AppLocalizations.of(context)!.saturdayRemark1,
          AppLocalizations.of(context)!.saturdayRemark2,
          AppLocalizations.of(context)!.saturdayRemark3,
        ];
      } else {
        dynamicRemarks = [
          AppLocalizations.of(context)!.noSpecificRemarks,
          AppLocalizations.of(context)!.dataCollectionOngoing,
        ];
      }
    });
  }
  

  // Helper method to check if there are any votes
  bool _hasAnyVotes() {
    for (var mealType in mealData.values) {
      for (var percentage in mealType.values) {
        if (percentage > 0) {
          return true;
        }
      }
    }
    return false;
  }

  // Helper widget for sidebar tiles
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

  Future<void> _logout() async {
    try {
      await _adminAuthService.logoutAdmin();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${AppLocalizations.of(context)!.logoutFailed}: $e')),
        );
      }
    }
  }

  // Helper widget to build meal vote list with progress indicators
  Widget _buildMealVoteList(Map<String, double> meals) {
    if (meals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.ballot_outlined, color: Colors.grey.shade400, size: 40),
              const SizedBox(height: 8),
              Text(
                'No votes submitted yet',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Users haven\'t voted for this meal type',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort meals by percentage in descending order
    final sortedMeals = meals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedMeals.map((meal) {
        final double percent = meal.value /
            100; // Convert percentage to 0-1 range for progress indicator
        final double percent = meal.value / 100; // Convert percentage to 0-1 range for progress indicator
        final bool isWinning = meal.value == sortedMeals.first.value && meal.value > 0;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${getLocalizedFoodItem(context, meal.key)} (${meal.value.toStringAsFixed(1)}%)',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percent.clamp(
                      0.0, 1.0), // Ensure value is between 0 and 1
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor),
                ),
              ),
            ],
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isWinning ? Colors.green.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isWinning ? Colors.green.shade300 : Colors.grey.shade300,
                width: isWinning ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        meal.key, // Now showing actual menu title from admin config (e.g., 'bread', 'parata', 'muri')
                        style: TextStyle(
                          fontSize: 14, 
                          fontWeight: isWinning ? FontWeight.bold : FontWeight.w600,
                          color: isWinning ? Colors.green.shade800 : Colors.black87,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (isWinning) ...[
                          Icon(Icons.emoji_events, color: Colors.green.shade600, size: 16),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '${meal.value.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isWinning ? Colors.green.shade700 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percent.clamp(0.0, 1.0), // Ensure value is between 0 and 1
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isWinning ? Colors.green.shade600 : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Load menu sets from Firestore
  Future<void> _loadMenuSets() async {
    setState(() {
      _isLoadingMenuSets = true;
    });

    try {
      final menuSets = await MenuSetService.getAllMenuSets();
      setState(() {
        _menuSets = menuSets;
        _isLoadingMenuSets = false;
      });
      debugPrint("✅ Menu sets loaded successfully");
    } catch (e) {
      debugPrint("❌ Error loading menu sets: $e");
      setState(() {
        _isLoadingMenuSets = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading menu sets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Save menu set to Firestore
  Future<void> _saveMenuSet() async {
    // Validate that all 3 options are filled
    List<Map<String, String>> options = [];
    List<String> missingFields = [];

    for (int i = 0; i < 3; i++) {
      final title = _menuTitleControllers[i].text.trim();
      final price = _menuPriceControllers[i].text.trim();
      final image = _menuImageControllers[i].text.trim();

      if (title.isEmpty || price.isEmpty || image.isEmpty) {
        missingFields.add('Option ${i + 1}');
      } else {
        options.add({
          'title': title,
          'price': price,
          'image': image,
        });
      }
    }

    if (options.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Please fill all fields for all 3 options. Missing: ${missingFields.join(", ")}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    try {
      await MenuSetService.saveMenuSetOptions(
        day: _menuSetSelectedDay,
        mealType: _selectedMealType,
        options: options,
      );

      // Clear form
      for (var controller in _menuTitleControllers) {
        controller.clear();
      }
      for (var controller in _menuPriceControllers) {
        controller.clear();
      }
      for (var controller in _menuImageControllers) {
        controller.clear();
      }

      // Reload menu sets
      await _loadMenuSets();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '3 menu options saved successfully for $_menuSetSelectedDay $_selectedMealType'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error saving menu set: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving menu set: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Delete menu set
  Future<void> _deleteMenuSet(String documentId) async {
    try {
      await MenuSetService.deleteMenuSet(documentId);
      await _loadMenuSets();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu set deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error deleting menu set: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting menu set: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Load existing menu options for editing
  Future<void> _loadExistingMenuOptions(String day, String mealType) async {
    try {
      final menuSets = await MenuSetService.getMenuSetsForDay(day);
      final options = menuSets[mealType.toLowerCase()] ?? [];

      // Clear existing form data
      for (var controller in _menuTitleControllers) {
        controller.clear();
      }
      for (var controller in _menuPriceControllers) {
        controller.clear();
      }
      for (var controller in _menuImageControllers) {
        controller.clear();
      }

      // Load existing data into form (up to 3 options)
      for (int i = 0; i < options.length && i < 3; i++) {
        _menuTitleControllers[i].text = options[i]['title'] ?? '';
        _menuPriceControllers[i].text = options[i]['price'] ?? '';
        _menuImageControllers[i].text = options[i]['image'] ?? '';
      }

      setState(() {
        _menuSetSelectedDay = day;
        _selectedMealType = mealType.toLowerCase();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded existing options for $day $mealType'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error loading existing menu options: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading existing options: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Admin voting control methods
  Future<void> _loadVotingStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('voting_control')
          .get();
      
      if (mounted) {
        setState(() {
          _isVotingEnabled = doc.exists ? (doc.data()?['enabled'] ?? false) : false;
          _isLoadingVotingStatus = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error loading voting status: $e");
      if (mounted) {
        setState(() {
          _isLoadingVotingStatus = false;
        });
      }
    }
  }

  Future<void> _toggleVotingStatus() async {
    try {
      final newStatus = !_isVotingEnabled;
      
      await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('voting_control')
          .set({
        'enabled': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': _currentUserName,
      });
      
      if (mounted) {
        setState(() {
          _isVotingEnabled = newStatus;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus 
                ? '✅ Voting enabled for all users' 
                : '❌ Voting disabled (Saturday-only mode)'),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error toggling voting status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating voting status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build menu set configuration section
  Widget _buildMenuSetConfigurationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, color: Colors.green.shade700, size: 24),
              const SizedBox(width: 10),
              Text(
                'Menu Set Configuration',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loadMenuSets,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'Configure exactly 3 menu options for each meal type (breakfast, lunch, dinner) for each day. Users will select from these 3 options when voting.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),

          // Add new menu set form
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configure 3 Menu Options',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add exactly 3 menu options for users to choose from',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 15),

                // Day and meal type selection
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _menuSetSelectedDay,
                        decoration: const InputDecoration(
                          labelText: 'Day',
                          border: OutlineInputBorder(),
                        ),
                        items: days.map((String day) {
                          return DropdownMenuItem<String>(
                            value: day,
                            child: Text(day),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _menuSetSelectedDay = newValue;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedMealType,
                        decoration: const InputDecoration(
                          labelText: 'Meal Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'breakfast', child: Text('Breakfast')),
                          DropdownMenuItem(
                              value: 'lunch', child: Text('Lunch')),
                          DropdownMenuItem(
                              value: 'dinner', child: Text('Dinner')),
                        ],
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedMealType = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Menu details - 3 required options
                Text(
                  'Configure 3 menu options (all required):',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 10),

                ...List.generate(
                    3,
                    (index) => Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green.shade200),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.green.shade50,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Option ${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Required',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _menuTitleControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Menu Title *',
                                  hintText: 'e.g., Bhuna Khichuri',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  labelStyle: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade600),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _menuPriceControllers[index],
                                      decoration: InputDecoration(
                                        labelText: 'Price *',
                                        hintText: 'e.g., ৳ 40',
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                        labelStyle: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green.shade600),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _menuImageControllers[index],
                                      decoration: InputDecoration(
                                        labelText: 'Image *',
                                        hintText: 'e.g., 1.png',
                                        border: const OutlineInputBorder(),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                        labelStyle: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green.shade600),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),

                ElevatedButton.icon(
                  onPressed: _saveMenuSet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Save 3 Menu Options'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Display existing menu sets
          if (_isLoadingMenuSets)
            const Center(child: CircularProgressIndicator())
          else
            _buildMenuSetsList(),
        ],
      ),
    );
  }

  // Build menu sets list
  Widget _buildMenuSetsList() {
    if (_menuSets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(Icons.restaurant_menu, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No menu sets configured',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add menu sets that users can vote for',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Existing Menu Sets',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
        const SizedBox(height: 10),
        ...days.map((day) => _buildDayMenuSets(day)).toList(),
      ],
    );
  }

  // Build menu sets for a specific day
  Widget _buildDayMenuSets(String day) {
    final dayMenuSets = _menuSets[day];
    if (dayMenuSets == null ||
        (dayMenuSets['breakfast']!.isEmpty &&
            dayMenuSets['lunch']!.isEmpty &&
            dayMenuSets['dinner']!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ExpansionTile(
        title: Text(
          day,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          if (dayMenuSets['breakfast']!.isNotEmpty)
            _buildMealTypeMenuSets('Breakfast', dayMenuSets['breakfast']!),
          if (dayMenuSets['lunch']!.isNotEmpty)
            _buildMealTypeMenuSets('Lunch', dayMenuSets['lunch']!),
          if (dayMenuSets['dinner']!.isNotEmpty)
            _buildMealTypeMenuSets('Dinner', dayMenuSets['dinner']!),
        ],
      ),
    );
  }

  // Build menu sets for a specific meal type
  Widget _buildMealTypeMenuSets(
      String mealType, List<Map<String, dynamic>> menuSets) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$mealType (${menuSets.length}/3 options)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              if (menuSets.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _loadExistingMenuOptions(
                      menuSets[0]['day'] ?? _menuSetSelectedDay, mealType),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (menuSets.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.restaurant_menu, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No options configured for $mealType',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure 3 menu options above',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                // Show status indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: menuSets.length == 3
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: menuSets.length == 3
                          ? Colors.green.shade300
                          : Colors.orange.shade300,
                    ),
                  ),
                  child: Text(
                    menuSets.length == 3
                        ? 'Complete (3/3 options)'
                        : 'Incomplete (${menuSets.length}/3 options)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: menuSets.length == 3
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Show all menu options
                ...menuSets.asMap().entries.map((entry) {
                  final index = entry.key;
                  final menuSet = entry.value;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/${menuSet['image']}',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey.shade300,
                                  child: Icon(Icons.image_not_supported,
                                      color: Colors.grey.shade600),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        menuSet['title'] ?? 'Unknown Menu',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        menuSet['price'] ?? 'No price',
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteMenuSet(menuSet['id']),
                        tooltip: 'Delete this option',
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        // Ensure remarks are updated for the current day and language
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateRemarks(context);
        });

        // Show loading screen while authenticating
        if (_isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          drawer: Drawer(
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
                    children: [
                      const CircleAvatar(
                        backgroundImage: AssetImage('assets/me.png'),
                        radius: 30,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentUserName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_currentUserData != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _currentUserData!['role'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'BA: ${_currentUserData!['ba_no'] ?? ''}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildSidebarTile(
                        icon: Icons.dashboard,
                        title: AppLocalizations.of(context)!.home,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminHomeScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSidebarTile(
                        icon: Icons.people,
                        title: AppLocalizations.of(context)!.users,
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
                        title: AppLocalizations.of(context)!.pendingIds,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminPendingIdsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSidebarTile(
                        icon: Icons.history,
                        title: AppLocalizations.of(context)!.shoppingHistory,
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
                        title: AppLocalizations.of(context)!.voucherList,
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
                        title: AppLocalizations.of(context)!.inventory,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminInventoryScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSidebarTile(
                        icon: Icons.food_bank,
                        title: AppLocalizations.of(context)!.messing,
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
                        title: AppLocalizations.of(context)!.monthlyMenu,
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
                        title: AppLocalizations.of(context)!.mealState,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminMealStateScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSidebarTile(
                        icon: Icons.thumb_up,
                        title: AppLocalizations.of(context)!.menuVote,
                        onTap: () => Navigator.pop(context),
                        selected: true,
                      ),
                      _buildSidebarTile(
                        icon: Icons.receipt_long,
                        title: AppLocalizations.of(context)!.bills,
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
                        title: AppLocalizations.of(context)!.payments,
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
                        title: AppLocalizations.of(context)!.diningMemberState,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DiningMemberStatePage(),
                            ),
                          );
                        },
                      ),
                      _buildSidebarTile(
                        icon: Icons.manage_accounts,
                        title: AppLocalizations.of(context)!.staffState,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminStaffStateScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 8,
                      top: 8,
                    ),
                    child: _buildSidebarTile(
                      icon: Icons.logout,
                      title: AppLocalizations.of(context)!.logout,
                      onTap: _logout,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          appBar: AppBar(
            backgroundColor: const Color(0xFF002B5B),
            iconTheme: const IconThemeData(color: Colors.white),
            centerTitle: true,
            title: Text(
              AppLocalizations.of(context)!.menuVote,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            actions: [
              PopupMenuButton<Locale>(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: const Size(24, 16),
                      painter:
                          languageProvider.currentLocale.languageCode == 'en'
                              ? _EnglandFlagPainter()
                              : _BangladeshFlagPainter(),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down, color: Colors.white),
                  ],
                ),
                onSelected: (Locale locale) {
                  languageProvider.changeLanguage(locale);
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<Locale>(
                    value: const Locale('en', ''),
                    child: Row(
                      children: [
                        CustomPaint(
                          size: const Size(20, 14),
                          painter: _EnglandFlagPainter(),
                        ),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.english),
                      ],
                    ),
                  ),
                  PopupMenuItem<Locale>(
                    value: const Locale('bn', ''),
                    child: Row(
                      children: [
                        CustomPaint(
                          size: const Size(20, 14),
                          painter: _BangladeshFlagPainter(),
                        ),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.bangla),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            // Changed to SingleChildScrollView
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search and Add New Set Button
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _searchController,
                          //onChanged: _filterRecords,
                          decoration: InputDecoration(
                            hintText:
                                AppLocalizations.of(context)!.searchMealSets,
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _getData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.refresh,
                                color: Colors.white, size: 20),
                        label: Text(
                          'Refresh',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _debugFetchAllRecords,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.bug_report,
                            color: Colors.white, size: 20),
                        label: Text(
                          'Debug',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Day selection dropdown
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Select Day: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedDay,
                            icon: const Icon(Icons.arrow_drop_down),
                            style: const TextStyle(
                                color: Colors.black, fontSize: 14),
                            items: days.map((String day) {
                              return DropdownMenuItem<String>(
                                value: day,
                                child: Text(getLocalizedDay(context, day)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedDay = newValue;
                                  // Re-apply filter based on the new day
                                  //_filterRecords(_searchController.text);
                                  _updateRemarks(
                                      context); // Update remarks for the new day instantly
                                  _getData(); // Fetch data for the selected day
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Meal Vote Statistics Section
                  ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLocalizations.of(context)!.mealVoteStatistics,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        if (_totalVoteCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Total Votes: $_totalVoteCount',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Check if there's any voting data
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _hasAnyVotes()
                            ? Column(
                                children: mealData.entries.map((entry) {
                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Highlighted meal time (Breakfast, Lunch, Dinner)
                                          Text(
                                            getLocalizedMealType(
                                                context, entry.key),
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 10),
                                          _buildMealVoteList(entry.value),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            : Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.poll_outlined,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No voting data available for ${getLocalizedDay(context, selectedDay)}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Users haven\'t voted for meals on this day yet.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                  ],

                  // --- Menu Set Configuration Section ---
                  const SizedBox(height: 30),
                  const Divider(thickness: 2),
                  const SizedBox(height: 20),
                  _buildMenuSetConfigurationSection(),

                  // --- Horizontal Line before Remarks ---
                  const SizedBox(height: 20),
                  const Divider(), // Added a divider for visual separation
                  const SizedBox(height: 20),
                  // --- Remarks Section at the very end (scrollable into view) ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.insightsRemarks,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF002B5B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Display remarks content directly
                        dynamicRemarks.isEmpty
                            ? Text(
                                AppLocalizations.of(context)!
                                    .noRemarksAvailable,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: dynamicRemarks
                                    .map(
                                      (remark) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.info_outline,
                                                size: 18,
                                                color: Colors.blueGrey),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                remark,
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      drawer: Drawer(
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
                children: [
                  const CircleAvatar(
                    backgroundImage: AssetImage('assets/me.png'),
                    radius: 30,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentUserName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_currentUserData != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _currentUserData!['role'] ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'BA: ${_currentUserData!['ba_no'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSidebarTile(
                    icon: Icons.dashboard,
                    title: AppLocalizations.of(context)!.home,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminHomeScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.people,
                    title: AppLocalizations.of(context)!.users,
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
                    title: AppLocalizations.of(context)!.pendingIds,
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
                    title: AppLocalizations.of(context)!.shoppingHistory,
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
                    title: AppLocalizations.of(context)!.voucherList,
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
                    title: AppLocalizations.of(context)!.inventory,
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
                    title: AppLocalizations.of(context)!.messing,
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
                    title: AppLocalizations.of(context)!.monthlyMenu,
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
                    title: AppLocalizations.of(context)!.mealState,
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
                    title: AppLocalizations.of(context)!.menuVote,
                    onTap: () => Navigator.pop(context),
                    selected: true,
                  ),
                  _buildSidebarTile(
                    icon: Icons.receipt_long,
                    title: AppLocalizations.of(context)!.bills,
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
                    title: AppLocalizations.of(context)!.payments,
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
                    title: AppLocalizations.of(context)!.diningMemberState,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DiningMemberStatePage(),
                        ),
                      );
                    },
                  ),
                  _buildSidebarTile(
                    icon: Icons.manage_accounts,
                    title: AppLocalizations.of(context)!.staffState,
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
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                  top: 8,
                ),
                child: _buildSidebarTile(
                  icon: Icons.logout,
                  title: AppLocalizations.of(context)!.logout,
                  onTap: _logout,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.menuVote,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          // Voting control toggle button
          if (!_isLoadingVotingStatus)
            IconButton(
              onPressed: _toggleVotingStatus,
              icon: Icon(
                _isVotingEnabled ? Icons.how_to_vote : Icons.block,
                color: _isVotingEnabled ? Colors.green : Colors.orange,
              ),
              tooltip: _isVotingEnabled 
                  ? 'Voting Enabled (Click to disable)' 
                  : 'Saturday-only voting (Click to enable anytime)',
            ),
          PopupMenuButton<Locale>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  size: const Size(24, 16),
                  painter: languageProvider.currentLocale.languageCode == 'en'
                      ? _EnglandFlagPainter()
                      : _BangladeshFlagPainter(),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
            onSelected: (Locale locale) {
              languageProvider.changeLanguage(locale);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<Locale>(
                value: const Locale('en', ''),
                child: Row(
                  children: [
                    CustomPaint(
                      size: const Size(20, 14),
                      painter: _EnglandFlagPainter(),
                    ),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.english),
                  ],
                ),
              ),
              PopupMenuItem<Locale>(
                value: const Locale('bn', ''),
                child: Row(
                  children: [
                    CustomPaint(
                      size: const Size(20, 14),
                      painter: _BangladeshFlagPainter(),
                    ),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.bangla),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Changed to SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search and Add New Set Button
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      //onChanged: _filterRecords,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchMealSets,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _getData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.refresh, color: Colors.white, size: 20),
                    label: Text(
                      'Refresh',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _debugFetchAllRecords,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.bug_report, color: Colors.white, size: 20),
                    label: Text(
                      'Debug',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Day selection dropdown
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select Day: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedDay,
                        icon: const Icon(Icons.arrow_drop_down),
                        style:
                            const TextStyle(color: Colors.black, fontSize: 14),
                        items: days.map((String day) {
                          return DropdownMenuItem<String>(
                            value: day,
                            child: Text(getLocalizedDay(context, day)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedDay = newValue;
                              // Re-apply filter based on the new day
                              //_filterRecords(_searchController.text);
                              _getData(); // Fetch data for the selected day
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Meal Vote Statistics Section
               ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.mealVoteStatistics,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Dynamic voting results for ${getLocalizedDay(context, selectedDay)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    if (_totalVoteCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Total Votes: $_totalVoteCount',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Check if there's any voting data
                _isLoading 
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _hasAnyVotes() 
                    ? Column(
                        children: mealData.entries.map((entry) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Highlighted meal time (Breakfast, Lunch, Dinner)
                                  Text(
                                    getLocalizedMealType(context, entry.key),
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildMealVoteList(entry.value),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    : Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.poll_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No voting data available for ${getLocalizedDay(context, selectedDay)}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Users haven\'t voted for meals on this day yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ] ,
              
              // --- Menu Set Configuration Section ---
              const SizedBox(height: 30),
              const Divider(thickness: 2),
              const SizedBox(height: 20),
              _buildMenuSetConfigurationSection(),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}

// Custom painter for England flag
class _EnglandFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // White background
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Red cross
    paint.color = Colors.red;
    // Vertical line
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.4, 0, size.width * 0.2, size.height),
        paint);
    // Horizontal line
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.2),
        paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom painter for Bangladesh flag
class _BangladeshFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Green background
    paint.color = const Color(0xFF006A4E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Red circle
    paint.color = const Color(0xFFF42A41);
    canvas.drawCircle(
        Offset(size.width * 0.4, size.height * 0.5), size.height * 0.3, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

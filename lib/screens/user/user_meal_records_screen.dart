import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserMealRecordsScreen extends StatefulWidget {
  const UserMealRecordsScreen({super.key});

  @override
  State<UserMealRecordsScreen> createState() => _UserMealRecordsScreenState();
}

class _UserMealRecordsScreenState extends State<UserMealRecordsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _mealRecords = [];
  String _userBaNo = '';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _fetchUserMealRecords();
  }

  Future<void> _fetchUserMealRecords() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get user profile to get BA number
      final userDoc = await FirebaseFirestore.instance
          .collection('user_requests')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw 'User profile not found';
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      _userBaNo = userData['ba_no'] as String? ?? '';
      _userName = userData['name'] as String? ?? '';

      if (_userBaNo.isEmpty) {
        throw 'BA number not found in profile';
      }

      // Fetch meal records from user_meal_state collection
      // Note: We fetch all documents and sort client-side to avoid Firestore index requirements
      final querySnapshot =
          await FirebaseFirestore.instance.collection('user_meal_state').get();

      List<Map<String, dynamic>> records = [];

      for (var doc in querySnapshot.docs) {
        final docData = doc.data();
        final date = doc.id;

        // Check if this user has data for this date
        if (docData.containsKey(_userBaNo)) {
          final userMealData = docData[_userBaNo] as Map<String, dynamic>;

          records.add({
            'date': date,
            'data': userMealData,
          });
        }
      }

      // Sort records by date (most recent first) and limit to 50
      records.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['date'] as String);
          final dateB = DateTime.parse(b['date'] as String);
          return dateB.compareTo(dateA); // Descending order (newest first)
        } catch (e) {
          return 0; // If date parsing fails, maintain current order
        }
      });

      // Limit to last 50 records
      if (records.length > 50) {
        records = records.take(50).toList();
      }

      setState(() {
        _mealRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading records: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDisplayDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildMealIcon(String mealType, bool isSelected) {
    IconData icon;
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        icon = Icons.free_breakfast;
        break;
      case 'lunch':
        icon = Icons.lunch_dining;
        break;
      case 'dinner':
        icon = Icons.dinner_dining;
        break;
      default:
        icon = Icons.restaurant;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.green.shade400 : Colors.grey.shade300,
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.green.shade700 : Colors.grey.shade500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _userName.isNotEmpty
              ? '$_userName\'s Meal Records'
              : 'My Meal Records',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF002B5B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your meal records...'),
                ],
              ),
            )
          : _mealRecords.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.no_meals,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No meal records found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your meal submissions will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchUserMealRecords,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _mealRecords.length,
                    itemBuilder: (context, index) {
                      final record = _mealRecords[index];
                      final date = record['date'] as String;
                      final data = record['data'] as Map<String, dynamic>;

                      final breakfast = data['breakfast'] as bool? ?? false;
                      final lunch = data['lunch'] as bool? ?? false;
                      final dinner = data['dinner'] as bool? ?? false;
                      final disposal = data['disposal'] as bool? ?? false;
                      final remarks = data['remarks'] as String? ?? '';
                      final disposalType =
                          data['disposal_type'] as String? ?? '';
                      final disposalFrom =
                          data['disposal_from'] as String? ?? '';
                      final disposalTo = data['disposal_to'] as String? ?? '';
                      final autoLoopGenerated =
                          data['auto_loop_generated'] as bool? ?? false;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date and source header
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                    color: Colors.blue.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDisplayDate(date),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF002B5B),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (autoLoopGenerated)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.purple.shade200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.loop,
                                            size: 12,
                                            color: Colors.purple.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Auto Loop',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.purple.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Meals selection
                              Row(
                                children: [
                                  const Text(
                                    'Meals: ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildMealIcon('breakfast', breakfast),
                                  const SizedBox(width: 8),
                                  _buildMealIcon('lunch', lunch),
                                  const SizedBox(width: 8),
                                  _buildMealIcon('dinner', dinner),
                                  const SizedBox(width: 16),
                                  if (!breakfast && !lunch && !dinner)
                                    const Text(
                                      'No meals selected',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    )
                                  else
                                    Text(
                                      [
                                        if (breakfast) 'Breakfast',
                                        if (lunch) 'Lunch',
                                        if (dinner) 'Dinner',
                                      ].join(', '),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),

                              // Disposal information
                              if (disposal) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.orange.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: Colors.orange.shade700,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Disposal: $disposalType',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (disposalFrom.isNotEmpty &&
                                          disposalTo.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'From: $disposalFrom  To: $disposalTo',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],

                              // Remarks
                              if (remarks.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.note,
                                        size: 16,
                                        color: Colors.blue.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          remarks,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

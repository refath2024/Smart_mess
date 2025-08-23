import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class VotingStatisticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get voting statistics for a specific day based on actual menu options
  static Future<Map<String, Map<String, dynamic>>> getVotingStatisticsForDay(String day) async {
    try {
      debugPrint("🔍 Fetching voting statistics for day: $day");
      
      // Get all voting records for the specified day
      final votingRecords = await _firestore
          .collection('voting_records')
          .where('selectedDay', isEqualTo: day)
          .get();

      debugPrint("📊 Found ${votingRecords.docs.length} voting records for $day");

      // Initialize result structure
      Map<String, Map<String, dynamic>> result = {
        'breakfast': {
          'votes': <String, int>{},
          'percentages': <String, double>{},
          'totalVotes': 0,
        },
        'lunch': {
          'votes': <String, int>{},
          'percentages': <String, double>{},
          'totalVotes': 0,
        },
        'dinner': {
          'votes': <String, int>{},
          'percentages': <String, double>{},
          'totalVotes': 0,
        },
      };

      // Count votes for each meal type
      for (var doc in votingRecords.docs) {
        final data = doc.data();
        
        // Count breakfast votes
        final breakfast = data['selectedBreakfast']?.toString();
        if (breakfast != null && breakfast.isNotEmpty && breakfast != 'No selection') {
          result['breakfast']!['votes'][breakfast] = 
              (result['breakfast']!['votes'][breakfast] as int? ?? 0) + 1;
          result['breakfast']!['totalVotes'] = 
              (result['breakfast']!['totalVotes'] as int) + 1;
        }

        // Count lunch votes
        final lunch = data['selectedLunch']?.toString();
        if (lunch != null && lunch.isNotEmpty && lunch != 'No selection') {
          result['lunch']!['votes'][lunch] = 
              (result['lunch']!['votes'][lunch] as int? ?? 0) + 1;
          result['lunch']!['totalVotes'] = 
              (result['lunch']!['totalVotes'] as int) + 1;
        }

        // Count dinner votes
        final dinner = data['selectedDinner']?.toString();
        if (dinner != null && dinner.isNotEmpty && dinner != 'No selection') {
          result['dinner']!['votes'][dinner] = 
              (result['dinner']!['votes'][dinner] as int? ?? 0) + 1;
          result['dinner']!['totalVotes'] = 
              (result['dinner']!['totalVotes'] as int) + 1;
        }
      }

      // Calculate percentages
      for (String mealType in ['breakfast', 'lunch', 'dinner']) {
        final totalVotes = result[mealType]!['totalVotes'] as int;
        final votes = result[mealType]!['votes'] as Map<String, int>;
        final percentages = result[mealType]!['percentages'] as Map<String, double>;

        if (totalVotes > 0) {
          for (String menuOption in votes.keys) {
            final voteCount = votes[menuOption]!;
            percentages[menuOption] = (voteCount / totalVotes) * 100;
          }
        }
      }

      debugPrint("✅ Voting statistics calculated successfully:");
      for (String mealType in ['breakfast', 'lunch', 'dinner']) {
        final totalVotes = result[mealType]!['totalVotes'];
        final votes = result[mealType]!['votes'] as Map<String, int>;
        debugPrint("   $mealType: $totalVotes total votes");
        votes.forEach((option, count) {
          final percentage = result[mealType]!['percentages'][option] ?? 0.0;
          debugPrint("     $option: $count votes (${percentage.toStringAsFixed(1)}%)");
        });
      }

      return result;
    } catch (e) {
      debugPrint("❌ Error fetching voting statistics: $e");
      rethrow;
    }
  }

  /// Get total vote count for a specific day
  static Future<int> getTotalVoteCountForDay(String day) async {
    try {
      final votingRecords = await _firestore
          .collection('voting_records')
          .where('selectedDay', isEqualTo: day)
          .get();

      return votingRecords.docs.length;
    } catch (e) {
      debugPrint("❌ Error fetching total vote count: $e");
      return 0;
    }
  }
}

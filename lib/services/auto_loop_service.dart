import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AutoLoopService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Manual batch processing for auto loop - can be triggered anytime by admin
  /// This approach works without keeping the app open and provides full control
  static Future<Map<String, dynamic>> runManualAutoLoopBatch(
      {String? targetDate}) async {
    try {
      debugPrint('🔄 Manual Auto Loop Batch Processing Started');

      // Use provided target date or calculate based on 21:00 cutoff logic
      final String processDate = targetDate ?? _getTargetMealDate();
      debugPrint('📅 Processing auto loop for date: $processDate');

      // Step 1: Get all enabled auto loop users
      final autoLoopSnapshot = await _firestore
          .collection('user_auto_loop')
          .where('enabled', isEqualTo: true)
          .get();

      if (autoLoopSnapshot.docs.isEmpty) {
        debugPrint('📝 No auto loop users found');
        return {
          'success': true,
          'message': 'No users with auto loop enabled',
          'processed': 0,
          'skipped': 0,
          'total_auto_loop_users': 0,
        };
      }

      debugPrint(
          '📝 Found ${autoLoopSnapshot.docs.length} enabled auto loop users');

      // Step 2: Check existing meal states for target date
      final existingMealStateDoc =
          await _firestore.collection('user_meal_state').doc(processDate).get();

      final existingMealStates = existingMealStateDoc.exists
          ? (existingMealStateDoc.data() as Map<String, dynamic>)
          : <String, dynamic>{};

      debugPrint(
          '📋 Found ${existingMealStates.length} existing meal states for $processDate');

      // Step 3: Process auto loop users
      int processedCount = 0;
      int skippedCount = 0;
      List<String> processedUsers = [];
      List<String> skippedUsers = [];

      final batch = _firestore.batch();
      final mealStateRef =
          _firestore.collection('user_meal_state').doc(processDate);

      for (final doc in autoLoopSnapshot.docs) {
        final loopData = doc.data();
        final baNo = loopData['ba_no']?.toString() ?? '';
        final userName = loopData['name']?.toString() ?? '';
        final mealPattern =
            loopData['meal_pattern'] as Map<String, dynamic>? ?? {};

        debugPrint('👤 Processing user: $baNo ($userName)');

        // Step 4: Check if user already has meal state for this date
        if (existingMealStates.containsKey(baNo)) {
          debugPrint('⏭️ Skipping $baNo - meal state already exists');
          skippedCount++;
          skippedUsers.add('$baNo ($userName)');
          continue;
        }

        // Step 5: Create meal state for auto loop user
        final mealStateData = {
          'name': userName,
          'rank': loopData['rank']?.toString() ?? '',
          'breakfast': mealPattern['breakfast'] ?? false,
          'lunch': mealPattern['lunch'] ?? false,
          'dinner': mealPattern['dinner'] ?? false,
          'remarks': '',
          'disposal': false,
          'disposal_type': '',
          'disposal_from': '',
          'disposal_to': '',
          'timestamp': FieldValue.serverTimestamp(),
          'admin_generated': false,
          'auto_loop_generated': true,
        };

        // Add to batch
        batch.set(
            mealStateRef,
            {
              baNo: mealStateData,
            },
            SetOptions(merge: true));

        processedCount++;
        processedUsers.add('$baNo ($userName)');
        debugPrint('✅ Queued auto loop meal state for $baNo ($userName)');
      }

      // Step 6: Commit batch if there are changes
      if (processedCount > 0) {
        await batch.commit();
        debugPrint(
            '🎉 Successfully processed $processedCount auto loop meal states');
      } else {
        debugPrint('ℹ️ No new auto loop meal states to process');
      }

      // Return detailed results
      return {
        'success': true,
        'message': 'Auto loop batch processing completed successfully',
        'processed': processedCount,
        'skipped': skippedCount,
        'total_auto_loop_users': autoLoopSnapshot.docs.length,
        'target_date': processDate,
        'processed_users': processedUsers,
        'skipped_users': skippedUsers,
      };
    } catch (e) {
      debugPrint('❌ Manual auto loop batch failed: $e');
      return {
        'success': false,
        'message': 'Auto loop batch processing failed: $e',
        'processed': 0,
        'skipped': 0,
        'total_auto_loop_users': 0,
      };
    }
  }

  /// Helper method to calculate target date based on current time
  /// Date logic based on 21:00 cutoff time for user submissions
  static String _getTargetMealDate() {
    final now = DateTime.now();
    // Before 21:00: Submit for next day
    // After 21:00: Submit for day after next (next day submission is closed)
    final target = (now.hour >= 21)
        ? now.add(const Duration(days: 2)) // Day after next
        : now.add(const Duration(days: 1)); // Next day

    return '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
  }

  /// Get statistics about auto loop users and last runs
  static Future<Map<String, dynamic>> getAutoLoopStats() async {
    try {
      final String targetDate = _getTargetMealDate();

      // Get auto loop settings
      final autoLoopSettingsDoc =
          await _firestore.collection('system_settings').doc('auto_loop').get();

      final Map<String, dynamic> settings = autoLoopSettingsDoc.exists
          ? (autoLoopSettingsDoc.data() as Map<String, dynamic>)
          : {};

      // Get enabled auto loop users count
      final autoLoopSnapshot = await _firestore
          .collection('user_auto_loop')
          .where('enabled', isEqualTo: true)
          .get();

      // Get existing meal states for target date
      final existingMealStateDoc =
          await _firestore.collection('user_meal_state').doc(targetDate).get();

      final int existingMealStatesCount = existingMealStateDoc.exists
          ? (existingMealStateDoc.data() as Map<String, dynamic>).length
          : 0;

      return {
        'target_date': targetDate,
        'enabled_auto_loop_users': autoLoopSnapshot.docs.length,
        'existing_meal_states_for_target': existingMealStatesCount,
        'last_run': settings['last_run'],
        'last_run_date': settings['last_run_date'],
        'last_processed_count': settings['processed_count'] ?? 0,
        'last_processed_users': settings['last_processed_users'] ?? 0,
      };
    } catch (e) {
      debugPrint('❌ Error getting auto loop stats: $e');
      return {
        'error': e.toString(),
      };
    }
  }
}

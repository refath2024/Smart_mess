import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MenuOptionsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Load menu options for a specific day and meal type
  static Future<List<String>> getMenuOptions(String day, String mealType) async {
    try {
      final docSnapshot = await _firestore
          .collection('voting_menu_options')
          .doc('${day.toLowerCase()}_$mealType')
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return List<String>.from(data['options'] ?? []);
      } else {
        // Return default options if admin hasn't configured them
        return _getDefaultOptions(mealType);
      }
    } catch (e) {
      debugPrint('Error loading menu options for $day $mealType: $e');
      return _getDefaultOptions(mealType);
    }
  }

  /// Load all menu options for a specific day (breakfast, lunch, dinner)
  static Future<Map<String, List<String>>> getAllMenuOptionsForDay(String day) async {
    final Map<String, List<String>> menuOptions = {};
    
    try {
      // Load options for all meal types
      for (String mealType in ['breakfast', 'lunch', 'dinner']) {
        menuOptions[mealType] = await getMenuOptions(day, mealType);
      }
    } catch (e) {
      debugPrint('Error loading menu options for $day: $e');
      // Fallback to default options
      menuOptions['breakfast'] = _getDefaultOptions('breakfast');
      menuOptions['lunch'] = _getDefaultOptions('lunch');
      menuOptions['dinner'] = _getDefaultOptions('dinner');
    }
    
    return menuOptions;
  }

  /// Save menu options for a specific day and meal type (Admin only)
  static Future<void> saveMenuOptions(String day, String mealType, List<String> options) async {
    try {
      await _firestore
          .collection('voting_menu_options')
          .doc('${day.toLowerCase()}_$mealType')
          .set({
        'day': day,
        'mealType': mealType,
        'options': options,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Menu options saved for $day $mealType');
    } catch (e) {
      debugPrint('❌ Error saving menu options for $day $mealType: $e');
      rethrow;
    }
  }

  /// Check if menu options exist for a specific day and meal type
  static Future<bool> hasMenuOptions(String day, String mealType) async {
    try {
      final docSnapshot = await _firestore
          .collection('voting_menu_options')
          .doc('${day.toLowerCase()}_$mealType')
          .get();
      
      return docSnapshot.exists && 
             (docSnapshot.data()?['options'] as List?)?.isNotEmpty == true;
    } catch (e) {
      debugPrint('Error checking menu options for $day $mealType: $e');
      return false;
    }
  }

  /// Get default menu options if admin hasn't configured them
  static List<String> _getDefaultOptions(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return [
          'Bhuna Khichuri',
          'Luchi with Alur dom',
          'Luchi with curry',
        ];
      case 'lunch':
        return [
          'Rice with Dal and Vegetables',
          'Biriyani',
          'Khichuri with Fish Curry',
        ];
      case 'dinner':
        return [
          'Rice with Chicken Curry',
          'Fried Rice',
          'Polao with Beef',
        ];
      default:
        return [];
    }
  }

  /// Get estimated price for meal options (can be made configurable later)
  static String getEstimatedPrice(String mealType, int optionIndex) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return ['40', '50', '70', '45', '60', '55'][optionIndex % 6];
      case 'lunch':
        return ['60', '70', '55', '65', '50', '75'][optionIndex % 6];
      case 'dinner':
        return ['50', '45', '75', '55', '60', '65'][optionIndex % 6];
      default:
        return '50';
    }
  }

  /// Delete menu options for a specific day and meal type (Admin only)
  static Future<void> deleteMenuOptions(String day, String mealType) async {
    try {
      await _firestore
          .collection('voting_menu_options')
          .doc('${day.toLowerCase()}_$mealType')
          .delete();
      debugPrint('✅ Menu options deleted for $day $mealType');
    } catch (e) {
      debugPrint('❌ Error deleting menu options for $day $mealType: $e');
      rethrow;
    }
  }

  /// Get all configured days with menu options
  static Future<List<String>> getConfiguredDays() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('voting_menu_options')
          .get();
      
      final Set<String> days = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final day = data['day'] as String?;
        if (day != null) {
          days.add(day);
        }
      }
      
      return days.toList()..sort();
    } catch (e) {
      debugPrint('Error getting configured days: $e');
      return [];
    }
  }
}

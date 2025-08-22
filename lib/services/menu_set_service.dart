import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MenuSetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'menu set';

  /// Save menu set options for a specific day and meal type (3 options)
  static Future<void> saveMenuSetOptions({
    required String day,
    required String mealType,
    required List<Map<String, String>> options,
  }) async {
    try {
      // Create document ID as "day_mealType" (e.g., "sunday_breakfast")
      final docId = '${day.toLowerCase()}_${mealType.toLowerCase()}';
      
      final menuSetData = {
        'day': day,
        'mealType': mealType,
        'options': options,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      await _firestore
          .collection(collectionName)
          .doc(docId)
          .set(menuSetData, SetOptions(merge: true));

      debugPrint("✅ Menu set options saved successfully: $docId");
    } catch (e) {
      debugPrint("❌ Error saving menu set options: $e");
      rethrow;
    }
  }

  /// Save individual menu set for a specific day and meal type
  static Future<void> saveMenuSet({
    required String day,
    required String mealType,
    required String title,
    required String price,
    required String image,
  }) async {
    try {
      // Create document ID as "day_mealType" (e.g., "sunday_breakfast")
      final docId = '${day.toLowerCase()}_${mealType.toLowerCase()}';
      
      final menuSetData = {
        'day': day,
        'mealType': mealType,
        'title': title,
        'price': price,
        'image': image,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      await _firestore
          .collection(collectionName)
          .doc(docId)
          .set(menuSetData, SetOptions(merge: true));

      debugPrint("✅ Menu set saved successfully: $docId");
    } catch (e) {
      debugPrint("❌ Error saving menu set: $e");
      rethrow;
    }
  }

  /// Get all menu sets for a specific day
  static Future<Map<String, List<Map<String, dynamic>>>> getMenuSetsForDay(
      String day) async {
    try {
      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('day', isEqualTo: day)
          .where('isActive', isEqualTo: true)
          .get();

      Map<String, List<Map<String, dynamic>>> menuSets = {
        'breakfast': [],
        'lunch': [],
        'dinner': [],
      };

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final mealType = data['mealType']?.toString().toLowerCase() ?? '';
        
        if (menuSets.containsKey(mealType)) {
          // Check if document has 'options' field (new format) or single meal (old format)
          if (data['options'] != null) {
            final options = List<Map<String, dynamic>>.from(data['options']);
            for (int i = 0; i < options.length; i++) {
              final option = options[i];
              menuSets[mealType]!.add({
                'id': '${doc.id}_option_$i',
                'title': option['title'] ?? '',
                'price': option['price'] ?? '',
                'image': option['image'] ?? '',
                'day': data['day'] ?? '',
                'mealType': data['mealType'] ?? '',
              });
            }
          } else {
            // Handle old format
            menuSets[mealType]!.add({
              'id': doc.id,
              'title': data['title'] ?? '',
              'price': data['price'] ?? '',
              'image': data['image'] ?? '',
              'day': data['day'] ?? '',
              'mealType': data['mealType'] ?? '',
            });
          }
        }
      }

      debugPrint("✅ Loaded menu sets for $day: ${menuSets.keys}");
      return menuSets;
    } catch (e) {
      debugPrint("❌ Error loading menu sets for $day: $e");
      return {
        'breakfast': [],
        'lunch': [],
        'dinner': [],
      };
    }
  }

  /// Get all menu sets
  static Future<Map<String, Map<String, List<Map<String, dynamic>>>>> getAllMenuSets() async {
    try {
      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('isActive', isEqualTo: true)
          .get();

      Map<String, Map<String, List<Map<String, dynamic>>>> allMenuSets = {};

      final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      
      // Initialize structure
      for (String day in days) {
        allMenuSets[day] = {
          'breakfast': [],
          'lunch': [],
          'dinner': [],
        };
      }

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final day = data['day']?.toString() ?? '';
        final mealType = data['mealType']?.toString().toLowerCase() ?? '';
        
        if (allMenuSets.containsKey(day) && allMenuSets[day]!.containsKey(mealType)) {
          allMenuSets[day]![mealType]!.add({
            'id': doc.id,
            'title': data['title'] ?? '',
            'price': data['price'] ?? '',
            'image': data['image'] ?? '',
            'day': data['day'] ?? '',
            'mealType': data['mealType'] ?? '',
          });
        }
      }

      debugPrint("✅ Loaded all menu sets");
      return allMenuSets;
    } catch (e) {
      debugPrint("❌ Error loading all menu sets: $e");
      return {};
    }
  }

  /// Delete a menu set
  static Future<void> deleteMenuSet(String documentId) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(documentId)
          .update({'isActive': false, 'updatedAt': FieldValue.serverTimestamp()});

      debugPrint("✅ Menu set deactivated successfully: $documentId");
    } catch (e) {
      debugPrint("❌ Error deactivating menu set: $e");
      rethrow;
    }
  }

  /// Update a menu set
  static Future<void> updateMenuSet({
    required String documentId,
    required String title,
    required String price,
    required String image,
  }) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(documentId)
          .update({
        'title': title,
        'price': price,
        'image': image,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Menu set updated successfully: $documentId");
    } catch (e) {
      debugPrint("❌ Error updating menu set: $e");
      rethrow;
    }
  }

  /// Get menu sets count for dashboard
  static Future<int> getMenuSetsCount() async {
    try {
      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint("❌ Error getting menu sets count: $e");
      return 0;
    }
  }
}

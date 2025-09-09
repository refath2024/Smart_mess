import 'package:cloud_firestore/cloud_firestore.dart';

class PremiumRequest {
  final String id;
  final String userId;
  final String userName;
  final String userRank;
  final String baNumber;
  final String requestType;
  final String mealType; // breakfast, lunch, dinner
  final String preferredMeal;
  final DateTime requestedDate;
  final String reason;
  final String status; // pending, approved, rejected
  final DateTime createdAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final double? additionalCost;

  PremiumRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRank,
    required this.baNumber,
    required this.requestType,
    required this.mealType,
    required this.preferredMeal,
    required this.requestedDate,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.additionalCost,
  });

  factory PremiumRequest.fromMap(Map<String, dynamic> map, String id) {
    return PremiumRequest(
      id: id,
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? '',
      userRank: map['user_rank'] ?? '',
      baNumber: map['ba_number'] ?? '',
      requestType: map['request_type'] ?? '',
      mealType: map['meal_type'] ?? '',
      preferredMeal: map['preferred_meal'] ?? '',
      requestedDate: (map['requested_date'] as Timestamp).toDate(),
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['created_at'] as Timestamp).toDate(),
      approvedBy: map['approved_by'],
      approvedAt: map['approved_at'] != null 
          ? (map['approved_at'] as Timestamp).toDate() 
          : null,
      rejectionReason: map['rejection_reason'],
      additionalCost: map['additional_cost']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_rank': userRank,
      'ba_number': baNumber,
      'request_type': requestType,
      'meal_type': mealType,
      'preferred_meal': preferredMeal,
      'requested_date': Timestamp.fromDate(requestedDate),
      'reason': reason,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
      'approved_by': approvedBy,
      'approved_at': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejection_reason': rejectionReason,
      'additional_cost': additionalCost,
    };
  }
}

// Premium meal options available for request
class PremiumMealOptions {
  static const Map<String, List<String>> premiumMeals = {
    'breakfast': [
      'Continental Breakfast',
      'Full English Breakfast',
      'Pancakes with Maple Syrup',
      'Eggs Benedict',
      'Smoked Salmon Bagel',
    ],
    'lunch': [
      'Grilled Salmon',
      'Beef Wellington',
      'Lamb Chops',
      'Lobster Bisque',
      'Prime Rib',
    ],
    'dinner': [
      'Beef Steak',
      'Seafood Boil',
      'Roasted Duck',
      'Surf and Turf',
      'Rack of Lamb',
    ],
  };

  static const Map<String, double> premiumMealCosts = {
    'Continental Breakfast': 15.0,
    'Full English Breakfast': 18.0,
    'Pancakes with Maple Syrup': 12.0,
    'Eggs Benedict': 16.0,
    'Smoked Salmon Bagel': 20.0,
    'Grilled Salmon': 25.0,
    'Beef Wellington': 35.0,
    'Lamb Chops': 30.0,
    'Lobster Bisque': 22.0,
    'Prime Rib': 28.0,
    'Beef Steak': 32.0,
    'Seafood Boil': 40.0,
    'Roasted Duck': 38.0,
    'Surf and Turf': 45.0,
    'Rack of Lamb': 42.0,
  };

  static List<String> getMealsForType(String mealType) {
    return premiumMeals[mealType] ?? [];
  }

  static double getCostForMeal(String mealName) {
    return premiumMealCosts[mealName] ?? 0.0;
  }
}
# Premium Request Feature Documentation

## What is a Premium Request?

A **Premium Request** in the Smart Mess Management System is a feature that allows mess members to request special premium meals beyond the regular menu offerings. This system caters to special occasions, dietary preferences, or when members want upgraded meal options.

## Overview

The Premium Request system consists of:

1. **User Interface**: Members can submit requests for premium meals through the mobile app
2. **Admin Management**: Administrative staff can review, approve, or reject these requests
3. **Cost Management**: Each premium meal has an associated additional cost
4. **Kitchen Planning**: Approved requests are visible to kitchen staff for meal preparation

## Key Features

### For Users
- **Request Premium Meals**: Choose from predefined premium meal options for breakfast, lunch, or dinner
- **Schedule Requests**: Select specific dates for premium meals (up to 30 days in advance)
- **Cost Transparency**: See additional costs upfront before submitting requests
- **Request Management**: View status of submitted requests and delete pending ones
- **Reason Documentation**: Provide reasons for premium meal requests

### For Administrators
- **Request Review**: View all pending premium requests with user details
- **Approval Workflow**: Approve or reject requests with reason documentation
- **Statistics Dashboard**: Track request volumes, approval rates, and revenue
- **Kitchen Planning**: View approved premium orders by date and meal type
- **Revenue Tracking**: Monitor additional revenue from premium meals

## Premium Meal Options

### Breakfast Options
- Continental Breakfast ($15.00)
- Full English Breakfast ($18.00)
- Pancakes with Maple Syrup ($12.00)
- Eggs Benedict ($16.00)
- Smoked Salmon Bagel ($20.00)

### Lunch Options
- Grilled Salmon ($25.00)
- Beef Wellington ($35.00)
- Lamb Chops ($30.00)
- Lobster Bisque ($22.00)
- Prime Rib ($28.00)

### Dinner Options
- Beef Steak ($32.00)
- Seafood Boil ($40.00)
- Roasted Duck ($38.00)
- Surf and Turf ($45.00)
- Rack of Lamb ($42.00)

## User Workflow

### Submitting a Premium Request

1. **Access Feature**: Navigate to "Premium Requests" from the user menu
2. **Select Meal Type**: Choose breakfast, lunch, or dinner
3. **Choose Premium Meal**: Select from available premium options with pricing
4. **Set Date**: Pick the desired date (next day to 30 days ahead)
5. **Provide Reason**: Explain why the premium meal is requested
6. **Submit**: Review costs and submit the request

### Request States
- **Pending**: Request submitted and awaiting admin review
- **Approved**: Request approved by admin, meal will be prepared
- **Rejected**: Request denied by admin with reason provided

## Admin Workflow

### Managing Premium Requests

1. **Access Management**: Navigate to "Premium Requests" in admin panel
2. **Review Requests**: View pending requests with user details and justification
3. **Make Decision**: Approve or reject based on availability and criteria
4. **Track Performance**: Monitor statistics and revenue through dashboard

### Admin Tabs
- **Pending**: Review and process new requests
- **All Requests**: View complete history with filtering
- **Statistics**: Track metrics and performance
- **Today's Orders**: See approved premium meals for current day

## Role-Based Access

### Users with Premium Request Access
- All registered mess members can submit premium requests

### Administrators with Management Access
- **PMC**: Full access to all premium request features
- **G2 (Mess)**: Complete management capabilities
- **Mess Secretary**: Full premium request administration
- **Asst Mess Secretary**: Complete access to premium requests
- **Butler**: Can manage premium requests for kitchen planning
- **Mess Sgt**: Full access for mess operations
- **Asst Mess Sgt**: Complete premium request management

## Technical Implementation

### Data Structure
```dart
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
}
```

### Firestore Collections
- **premium_requests**: Stores all premium meal requests
- **user_requests**: Used to validate user information

### Key Services
- **PremiumRequestService**: Handles all premium request operations
- **Models**: PremiumRequest and PremiumMealOptions classes
- **Screens**: User request interface and admin management panels

## Benefits

### For Mess Management
- **Revenue Generation**: Additional income from premium meal surcharges
- **Member Satisfaction**: Ability to cater to special preferences and occasions
- **Operational Planning**: Advance notice for kitchen preparation
- **Data Analytics**: Insights into member preferences and demand patterns

### For Members
- **Meal Variety**: Access to high-quality premium meal options
- **Special Occasions**: Ability to celebrate with upgraded meals
- **Transparency**: Clear pricing and approval process
- **Convenience**: Easy mobile app interface for requests

## Usage Guidelines

### For Users
- Submit requests at least 24 hours in advance
- Provide clear, valid reasons for premium meal requests
- Be aware that approval is not guaranteed and depends on availability
- Check request status regularly for updates

### For Administrators
- Review requests promptly to ensure kitchen planning time
- Consider operational capacity when approving requests
- Provide clear reasons when rejecting requests
- Monitor budget and revenue targets

## Future Enhancements

- **Meal Customization**: Allow users to specify dietary restrictions or modifications
- **Bulk Ordering**: Enable requests for multiple people or events
- **Seasonal Menus**: Rotate premium options based on seasons or availability
- **Member Tiers**: Different premium options based on membership levels
- **Integration**: Connect with billing system for automatic charge processing
- **Notifications**: Real-time updates on request status changes

This premium request feature enhances the Smart Mess Management System by providing flexibility, improving member satisfaction, and generating additional revenue while maintaining operational control and planning capabilities.
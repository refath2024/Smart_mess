import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Mess'**
  String get appTitle;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @pendingIds.
  ///
  /// In en, this message translates to:
  /// **'Pending IDs'**
  String get pendingIds;

  /// No description provided for @shoppingHistory.
  ///
  /// In en, this message translates to:
  /// **'Shopping History'**
  String get shoppingHistory;

  /// No description provided for @voucherList.
  ///
  /// In en, this message translates to:
  /// **'Voucher List'**
  String get voucherList;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @messing.
  ///
  /// In en, this message translates to:
  /// **'Messing'**
  String get messing;

  /// No description provided for @monthlyMenu.
  ///
  /// In en, this message translates to:
  /// **'Monthly Menu'**
  String get monthlyMenu;

  /// No description provided for @mealState.
  ///
  /// In en, this message translates to:
  /// **'Meal State'**
  String get mealState;

  /// No description provided for @menuVote.
  ///
  /// In en, this message translates to:
  /// **'Menu Vote'**
  String get menuVote;

  /// No description provided for @bills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get bills;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @diningMemberState.
  ///
  /// In en, this message translates to:
  /// **'Dining Member State'**
  String get diningMemberState;

  /// No description provided for @staffState.
  ///
  /// In en, this message translates to:
  /// **'Staff State'**
  String get staffState;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get pendingRequests;

  /// No description provided for @monthlyExpense.
  ///
  /// In en, this message translates to:
  /// **'Monthly Expense'**
  String get monthlyExpense;

  /// No description provided for @activeMembers.
  ///
  /// In en, this message translates to:
  /// **'Active Members'**
  String get activeMembers;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @viewReports.
  ///
  /// In en, this message translates to:
  /// **'View Reports'**
  String get viewReports;

  /// No description provided for @manageInventory.
  ///
  /// In en, this message translates to:
  /// **'Manage Inventory'**
  String get manageInventory;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get systemSettings;

  /// No description provided for @recentActivities.
  ///
  /// In en, this message translates to:
  /// **'Recent Activities'**
  String get recentActivities;

  /// No description provided for @addInventoryEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Inventory Entry'**
  String get addInventoryEntry;

  /// No description provided for @addVoucher.
  ///
  /// In en, this message translates to:
  /// **'Add Voucher'**
  String get addVoucher;

  /// No description provided for @addShoppingData.
  ///
  /// In en, this message translates to:
  /// **'Add Shopping Data'**
  String get addShoppingData;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @index.
  ///
  /// In en, this message translates to:
  /// **'Index'**
  String get index;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @quantityHeld.
  ///
  /// In en, this message translates to:
  /// **'Quantity Held'**
  String get quantityHeld;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @buyerName.
  ///
  /// In en, this message translates to:
  /// **'Buyer Name'**
  String get buyerName;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @voucherId.
  ///
  /// In en, this message translates to:
  /// **'Voucher ID'**
  String get voucherId;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price (Per Kg/Qty)'**
  String get unitPrice;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount (Kg/Qty)'**
  String get amount;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @bangla.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get bangla;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get noDataFound;

  /// No description provided for @addSomeDataToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add some data to get started'**
  String get addSomeDataToGetStarted;

  /// No description provided for @noInventoryItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No inventory items found'**
  String get noInventoryItemsFound;

  /// No description provided for @addSomeInventoryItems.
  ///
  /// In en, this message translates to:
  /// **'Add some inventory items to get started'**
  String get addSomeInventoryItems;

  /// No description provided for @noVouchersFound.
  ///
  /// In en, this message translates to:
  /// **'No vouchers found'**
  String get noVouchersFound;

  /// No description provided for @addSomeVouchers.
  ///
  /// In en, this message translates to:
  /// **'Add some vouchers to get started'**
  String get addSomeVouchers;

  /// No description provided for @noShoppingDataFound.
  ///
  /// In en, this message translates to:
  /// **'No shopping data found'**
  String get noShoppingDataFound;

  /// No description provided for @addSomeShoppingEntries.
  ///
  /// In en, this message translates to:
  /// **'Add some shopping entries to get started'**
  String get addSomeShoppingEntries;

  /// No description provided for @areYouSureYouWantToDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get areYouSureYouWantToDelete;

  /// No description provided for @inventoryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Inventory updated'**
  String get inventoryUpdated;

  /// No description provided for @voucherUpdated.
  ///
  /// In en, this message translates to:
  /// **'Voucher updated'**
  String get voucherUpdated;

  /// No description provided for @shoppingEntryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Shopping entry updated'**
  String get shoppingEntryUpdated;

  /// No description provided for @inventoryItemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Inventory item deleted'**
  String get inventoryItemDeleted;

  /// No description provided for @voucherDeleted.
  ///
  /// In en, this message translates to:
  /// **'Voucher deleted'**
  String get voucherDeleted;

  /// No description provided for @shoppingEntryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Shopping entry deleted'**
  String get shoppingEntryDeleted;

  /// No description provided for @errorLoadingInventory.
  ///
  /// In en, this message translates to:
  /// **'Error loading inventory'**
  String get errorLoadingInventory;

  /// No description provided for @errorLoadingVouchers.
  ///
  /// In en, this message translates to:
  /// **'Error loading vouchers'**
  String get errorLoadingVouchers;

  /// No description provided for @errorLoadingShoppingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading shopping data'**
  String get errorLoadingShoppingData;

  /// No description provided for @errorUpdatingInventory.
  ///
  /// In en, this message translates to:
  /// **'Error updating inventory'**
  String get errorUpdatingInventory;

  /// No description provided for @errorUpdatingVoucher.
  ///
  /// In en, this message translates to:
  /// **'Error updating voucher'**
  String get errorUpdatingVoucher;

  /// No description provided for @errorUpdatingShoppingEntry.
  ///
  /// In en, this message translates to:
  /// **'Error updating shopping entry'**
  String get errorUpdatingShoppingEntry;

  /// No description provided for @errorDeletingInventory.
  ///
  /// In en, this message translates to:
  /// **'Error deleting inventory'**
  String get errorDeletingInventory;

  /// No description provided for @errorDeletingVoucher.
  ///
  /// In en, this message translates to:
  /// **'Error deleting voucher'**
  String get errorDeletingVoucher;

  /// No description provided for @errorDeletingShoppingEntry.
  ///
  /// In en, this message translates to:
  /// **'Error deleting shopping entry'**
  String get errorDeletingShoppingEntry;

  /// No description provided for @addShoppingVoucher.
  ///
  /// In en, this message translates to:
  /// **'Add Shopping Voucher'**
  String get addShoppingVoucher;

  /// No description provided for @addInventoryItem.
  ///
  /// In en, this message translates to:
  /// **'Add Inventory Item'**
  String get addInventoryItem;

  /// No description provided for @addShoppingEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Shopping Entry'**
  String get addShoppingEntry;

  /// No description provided for @searchByProductName.
  ///
  /// In en, this message translates to:
  /// **'Search by Product Name, Type...'**
  String get searchByProductName;

  /// No description provided for @breakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get breakfast;

  /// No description provided for @lunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get lunch;

  /// No description provided for @dinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get dinner;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @authenticationRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get authenticationRequired;

  /// No description provided for @adminUser.
  ///
  /// In en, this message translates to:
  /// **'Admin User'**
  String get adminUser;

  /// No description provided for @todaysMenu.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Menu'**
  String get todaysMenu;

  /// No description provided for @searchByBuyerDate.
  ///
  /// In en, this message translates to:
  /// **'Search by Buyer, Date...'**
  String get searchByBuyerDate;

  /// No description provided for @searchByVoucherIdBuyerDate.
  ///
  /// In en, this message translates to:
  /// **'Search by Voucher ID, Buyer, Date...'**
  String get searchByVoucherIdBuyerDate;

  /// No description provided for @viewImages.
  ///
  /// In en, this message translates to:
  /// **'View Images'**
  String get viewImages;

  /// No description provided for @viewImagesFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'View Images - Feature coming soon'**
  String get viewImagesFeatureComingSoon;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @fresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get fresh;

  /// No description provided for @utensils.
  ///
  /// In en, this message translates to:
  /// **'Utensils'**
  String get utensils;

  /// No description provided for @ration.
  ///
  /// In en, this message translates to:
  /// **'Ration'**
  String get ration;

  /// No description provided for @welcomeBackAdmin.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, Admin!'**
  String get welcomeBackAdmin;

  /// No description provided for @monitorUserActivity.
  ///
  /// In en, this message translates to:
  /// **'Monitor user activity, update menus, and manage system settings from here.'**
  String get monitorUserActivity;

  /// No description provided for @tomorrowsMenu.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow\'s Menu'**
  String get tomorrowsMenu;

  /// No description provided for @activeMeals.
  ///
  /// In en, this message translates to:
  /// **'Active Meals'**
  String get activeMeals;

  /// No description provided for @parathaVegetablesTea.
  ///
  /// In en, this message translates to:
  /// **'Paratha, Vegetables, Tea'**
  String get parathaVegetablesTea;

  /// No description provided for @riceChickenCurryDal.
  ///
  /// In en, this message translates to:
  /// **'Rice, Chicken Curry, Dal'**
  String get riceChickenCurryDal;

  /// No description provided for @riceFishCurryMixedVegetables.
  ///
  /// In en, this message translates to:
  /// **'Rice, Fish Curry, Mixed Vegetables'**
  String get riceFishCurryMixedVegetables;

  /// No description provided for @rutiEggCurryTea.
  ///
  /// In en, this message translates to:
  /// **'Ruti, Egg Curry, Tea'**
  String get rutiEggCurryTea;

  /// No description provided for @riceBeefCurryDal.
  ///
  /// In en, this message translates to:
  /// **'Rice, Beef Curry, Dal'**
  String get riceBeefCurryDal;

  /// No description provided for @biriyaniChickenRoastSalad.
  ///
  /// In en, this message translates to:
  /// **'Biriyani, Chicken Roast, Salad'**
  String get biriyaniChickenRoastSalad;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get logoutFailed;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @division.
  ///
  /// In en, this message translates to:
  /// **'Division'**
  String get division;

  /// No description provided for @adminLogin.
  ///
  /// In en, this message translates to:
  /// **'Admin Login'**
  String get adminLogin;

  /// No description provided for @loginToAdmin.
  ///
  /// In en, this message translates to:
  /// **'Login to Admin Panel'**
  String get loginToAdmin;

  /// No description provided for @backToUserLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to User Login'**
  String get backToUserLogin;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get pleaseEnterPassword;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials'**
  String get invalidCredentials;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @baNumber.
  ///
  /// In en, this message translates to:
  /// **'BA Number'**
  String get baNumber;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users...'**
  String get searchUsers;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @totalMembers.
  ///
  /// In en, this message translates to:
  /// **'Total Members'**
  String get totalMembers;

  /// No description provided for @diningMembers.
  ///
  /// In en, this message translates to:
  /// **'Dining Members'**
  String get diningMembers;

  /// No description provided for @activeDiningMembers.
  ///
  /// In en, this message translates to:
  /// **'Active Dining Members'**
  String get activeDiningMembers;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @loadingUsers.
  ///
  /// In en, this message translates to:
  /// **'Loading users...'**
  String get loadingUsers;

  /// No description provided for @errorLoadingUsers.
  ///
  /// In en, this message translates to:
  /// **'Error loading users'**
  String get errorLoadingUsers;

  /// No description provided for @errorLoadingUsersData.
  ///
  /// In en, this message translates to:
  /// **'Error loading users data'**
  String get errorLoadingUsersData;

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rank;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// No description provided for @totalDiningMembers.
  ///
  /// In en, this message translates to:
  /// **'Total Dining Members'**
  String get totalDiningMembers;

  /// No description provided for @totalActiveDiningMembers.
  ///
  /// In en, this message translates to:
  /// **'Total Active Dining Members'**
  String get totalActiveDiningMembers;

  /// No description provided for @totalStaffs.
  ///
  /// In en, this message translates to:
  /// **'Total Staffs'**
  String get totalStaffs;

  /// No description provided for @memberSummary.
  ///
  /// In en, this message translates to:
  /// **'Member Summary'**
  String get memberSummary;

  /// No description provided for @requestedAt.
  ///
  /// In en, this message translates to:
  /// **'Requested At'**
  String get requestedAt;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @confirmAccept.
  ///
  /// In en, this message translates to:
  /// **'Confirm Accept'**
  String get confirmAccept;

  /// No description provided for @confirmReject.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reject'**
  String get confirmReject;

  /// No description provided for @acceptUserMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to accept this user? This action will approve their application and grant them access to the system.'**
  String get acceptUserMessage;

  /// No description provided for @rejectUserMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this user? This action will deny their application. They will be able to reapply later with updated information.'**
  String get rejectUserMessage;

  /// No description provided for @userAccepted.
  ///
  /// In en, this message translates to:
  /// **'User has been accepted and can now log in to the system.'**
  String get userAccepted;

  /// No description provided for @userRejected.
  ///
  /// In en, this message translates to:
  /// **'User has been rejected.'**
  String get userRejected;

  /// No description provided for @failedToAcceptUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept user'**
  String get failedToAcceptUser;

  /// No description provided for @failedToRejectUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject user'**
  String get failedToRejectUser;

  /// No description provided for @indlEntry.
  ///
  /// In en, this message translates to:
  /// **'Indl Entry'**
  String get indlEntry;

  /// No description provided for @miscEntry.
  ///
  /// In en, this message translates to:
  /// **'Misc Entry'**
  String get miscEntry;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @changeDate.
  ///
  /// In en, this message translates to:
  /// **'Change Date'**
  String get changeDate;

  /// No description provided for @breakfastEntries.
  ///
  /// In en, this message translates to:
  /// **'Breakfast Entries'**
  String get breakfastEntries;

  /// No description provided for @lunchEntries.
  ///
  /// In en, this message translates to:
  /// **'Lunch Entries'**
  String get lunchEntries;

  /// No description provided for @dinnerEntries.
  ///
  /// In en, this message translates to:
  /// **'Dinner Entries'**
  String get dinnerEntries;

  /// No description provided for @viewingDate.
  ///
  /// In en, this message translates to:
  /// **'Viewing Date:'**
  String get viewingDate;

  /// No description provided for @totalPriceExpended.
  ///
  /// In en, this message translates to:
  /// **'Total Price Expended'**
  String get totalPriceExpended;

  /// No description provided for @totalPricePerMember.
  ///
  /// In en, this message translates to:
  /// **'Total Price per Member'**
  String get totalPricePerMember;

  /// No description provided for @editMenuFor.
  ///
  /// In en, this message translates to:
  /// **'Edit Menu for'**
  String get editMenuFor;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @confirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancel'**
  String get confirmCancel;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to discard changes?'**
  String get discardChanges;

  /// No description provided for @confirmSave.
  ///
  /// In en, this message translates to:
  /// **'Confirm Save'**
  String get confirmSave;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to save changes?'**
  String get saveChanges;

  /// No description provided for @savingChanges.
  ///
  /// In en, this message translates to:
  /// **'Saving changes...'**
  String get savingChanges;

  /// No description provided for @menuUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Menu updated successfully!'**
  String get menuUpdatedSuccessfully;

  /// No description provided for @errorUpdatingMenu.
  ///
  /// In en, this message translates to:
  /// **'Error updating menu'**
  String get errorUpdatingMenu;

  /// No description provided for @deleteMenuItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this menu item?'**
  String get deleteMenuItemConfirm;

  /// No description provided for @deletingMenu.
  ///
  /// In en, this message translates to:
  /// **'Deleting menu...'**
  String get deletingMenu;

  /// No description provided for @menuItemDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Menu item deleted successfully'**
  String get menuItemDeletedSuccessfully;

  /// No description provided for @errorDeletingMenu.
  ///
  /// In en, this message translates to:
  /// **'Error deleting menu'**
  String get errorDeletingMenu;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @confirmSaveMealState.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to save the changes?'**
  String get confirmSaveMealState;

  /// No description provided for @recordUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Record updated successfully'**
  String get recordUpdatedSuccessfully;

  /// No description provided for @errorUpdatingRecord.
  ///
  /// In en, this message translates to:
  /// **'Error updating record'**
  String get errorUpdatingRecord;

  /// No description provided for @deleteRecordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this record?'**
  String get deleteRecordConfirm;

  /// No description provided for @recordDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Record deleted successfully'**
  String get recordDeletedSuccessfully;

  /// No description provided for @errorDeletingRecord.
  ///
  /// In en, this message translates to:
  /// **'Error deleting record'**
  String get errorDeletingRecord;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @seeRecords.
  ///
  /// In en, this message translates to:
  /// **'See Records'**
  String get seeRecords;

  /// No description provided for @eatingBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Eating Breakfast'**
  String get eatingBreakfast;

  /// No description provided for @eatingLunch.
  ///
  /// In en, this message translates to:
  /// **'Eating Lunch'**
  String get eatingLunch;

  /// No description provided for @eatingDinner.
  ///
  /// In en, this message translates to:
  /// **'Eating Dinner'**
  String get eatingDinner;

  /// No description provided for @errorFetchingMealStateData.
  ///
  /// In en, this message translates to:
  /// **'Error fetching meal state data'**
  String get errorFetchingMealStateData;

  /// No description provided for @disposals.
  ///
  /// In en, this message translates to:
  /// **'Disposals'**
  String get disposals;

  /// No description provided for @remarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarks;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @dash.
  ///
  /// In en, this message translates to:
  /// **'-'**
  String get dash;

  /// No description provided for @siq.
  ///
  /// In en, this message translates to:
  /// **'SIQ'**
  String get siq;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @addNewSet.
  ///
  /// In en, this message translates to:
  /// **'Add New Set'**
  String get addNewSet;

  /// No description provided for @searchMealSets.
  ///
  /// In en, this message translates to:
  /// **'Search meal sets...'**
  String get searchMealSets;

  /// No description provided for @noMealVoteData.
  ///
  /// In en, this message translates to:
  /// **'No meal vote data available for the selected day or search query.'**
  String get noMealVoteData;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @mealVoteStatistics.
  ///
  /// In en, this message translates to:
  /// **'Meal Vote Statistics'**
  String get mealVoteStatistics;

  /// No description provided for @insightsRemarks.
  ///
  /// In en, this message translates to:
  /// **'Insights & Remarks'**
  String get insightsRemarks;

  /// No description provided for @noRemarksAvailable.
  ///
  /// In en, this message translates to:
  /// **'No specific remarks available at the moment. Please check back later.'**
  String get noRemarksAvailable;

  /// No description provided for @parathaSet.
  ///
  /// In en, this message translates to:
  /// **'Paratha Set'**
  String get parathaSet;

  /// No description provided for @rutiSet.
  ///
  /// In en, this message translates to:
  /// **'Ruti Set'**
  String get rutiSet;

  /// No description provided for @naanSet.
  ///
  /// In en, this message translates to:
  /// **'Naan Set'**
  String get naanSet;

  /// No description provided for @chickenSet.
  ///
  /// In en, this message translates to:
  /// **'Chicken Set'**
  String get chickenSet;

  /// No description provided for @fishSet.
  ///
  /// In en, this message translates to:
  /// **'Fish Set'**
  String get fishSet;

  /// No description provided for @vegetableSet.
  ///
  /// In en, this message translates to:
  /// **'Vegetable Set'**
  String get vegetableSet;

  /// No description provided for @biriyaniSet.
  ///
  /// In en, this message translates to:
  /// **'Biriyani Set'**
  String get biriyaniSet;

  /// No description provided for @riceSet.
  ///
  /// In en, this message translates to:
  /// **'Rice Set'**
  String get riceSet;

  /// No description provided for @khichuriSet.
  ///
  /// In en, this message translates to:
  /// **'Khichuri Set'**
  String get khichuriSet;

  /// No description provided for @sundayRemark1.
  ///
  /// In en, this message translates to:
  /// **'Sunday dinner, Biriyani is a clear favorite, indicating a strong preference for hearty meals at the end of the week.'**
  String get sundayRemark1;

  /// No description provided for @sundayRemark2.
  ///
  /// In en, this message translates to:
  /// **'Breakfast options on Sunday show a good mix of preferences, suggesting variety is appreciated.'**
  String get sundayRemark2;

  /// No description provided for @sundayRemark3.
  ///
  /// In en, this message translates to:
  /// **'Lunch on Sunday could benefit from more diverse protein sources based on current vote distribution.'**
  String get sundayRemark3;

  /// No description provided for @mondayRemark1.
  ///
  /// In en, this message translates to:
  /// **'Pizza for Monday dinner received overwhelming votes; consider making it a regular special.'**
  String get mondayRemark1;

  /// No description provided for @mondayRemark2.
  ///
  /// In en, this message translates to:
  /// **'Breakfast on Monday sees a strong preference for Egg Toast, indicating a need for quick and familiar options.'**
  String get mondayRemark2;

  /// No description provided for @mondayRemark3.
  ///
  /// In en, this message translates to:
  /// **'Lunch options on Monday are fairly balanced, but Pasta Bake leads the preferences.'**
  String get mondayRemark3;

  /// No description provided for @tuesdayRemark1.
  ///
  /// In en, this message translates to:
  /// **'South Indian breakfast options are popular on Tuesdays.'**
  String get tuesdayRemark1;

  /// No description provided for @tuesdayRemark2.
  ///
  /// In en, this message translates to:
  /// **'Dal Makhani is a preferred lunch item, consider its regular inclusion.'**
  String get tuesdayRemark2;

  /// No description provided for @tuesdayRemark3.
  ///
  /// In en, this message translates to:
  /// **'Chicken Curry remains a strong contender for dinner choice.'**
  String get tuesdayRemark3;

  /// No description provided for @wednesdayRemark1.
  ///
  /// In en, this message translates to:
  /// **'Western breakfast is highly favored on Wednesdays.'**
  String get wednesdayRemark1;

  /// No description provided for @wednesdayRemark2.
  ///
  /// In en, this message translates to:
  /// **'Fish & Chips stands out for lunch, a good option for variety.'**
  String get wednesdayRemark2;

  /// No description provided for @wednesdayRemark3.
  ///
  /// In en, this message translates to:
  /// **'Beef Steak is the top pick for dinner, indicating demand for premium options.'**
  String get wednesdayRemark3;

  /// No description provided for @thursdayRemark1.
  ///
  /// In en, this message translates to:
  /// **'Healthy breakfast options like Oatmeal and Yogurt Parfait are well-received.'**
  String get thursdayRemark1;

  /// No description provided for @thursdayRemark2.
  ///
  /// In en, this message translates to:
  /// **'Sushi is surprisingly popular for lunch, consider expanding Asian cuisine.'**
  String get thursdayRemark2;

  /// No description provided for @thursdayRemark3.
  ///
  /// In en, this message translates to:
  /// **'Tacos are a clear winner for dinner; a themed night could work well.'**
  String get thursdayRemark3;

  /// No description provided for @fridayRemark1.
  ///
  /// In en, this message translates to:
  /// **'Pastries are a good choice for Friday breakfast.'**
  String get fridayRemark1;

  /// No description provided for @fridayRemark2.
  ///
  /// In en, this message translates to:
  /// **'Pizza is overwhelmingly popular for Friday lunch, consider offering more toppings.'**
  String get fridayRemark2;

  /// No description provided for @fridayRemark3.
  ///
  /// In en, this message translates to:
  /// **'BBQ Ribs are highly demanded for Friday dinner, a good end-of-week treat.'**
  String get fridayRemark3;

  /// No description provided for @saturdayRemark1.
  ///
  /// In en, this message translates to:
  /// **'Hearty breakfast options are preferred on Saturdays.'**
  String get saturdayRemark1;

  /// No description provided for @saturdayRemark2.
  ///
  /// In en, this message translates to:
  /// **'Burgers are a casual and popular lunch choice for the weekend.'**
  String get saturdayRemark2;

  /// No description provided for @saturdayRemark3.
  ///
  /// In en, this message translates to:
  /// **'Seafood Boil is a top choice for Saturday dinner, indicating a preference for special meals.'**
  String get saturdayRemark3;

  /// No description provided for @noSpecificRemarks.
  ///
  /// In en, this message translates to:
  /// **'No specific remarks available for this day yet.'**
  String get noSpecificRemarks;

  /// No description provided for @dataCollectionOngoing.
  ///
  /// In en, this message translates to:
  /// **'Data collection is ongoing; encourage more members to vote to gather comprehensive insights.'**
  String get dataCollectionOngoing;

  /// No description provided for @exportBills.
  ///
  /// In en, this message translates to:
  /// **'Export Bills'**
  String get exportBills;

  /// No description provided for @baNo.
  ///
  /// In en, this message translates to:
  /// **'BA No'**
  String get baNo;

  /// No description provided for @previousArrear.
  ///
  /// In en, this message translates to:
  /// **'Previous Arrear'**
  String get previousArrear;

  /// No description provided for @currentBill.
  ///
  /// In en, this message translates to:
  /// **'Current Bill'**
  String get currentBill;

  /// No description provided for @totalDue.
  ///
  /// In en, this message translates to:
  /// **'Total Due'**
  String get totalDue;

  /// No description provided for @noBillsToExport.
  ///
  /// In en, this message translates to:
  /// **'No bills to export'**
  String get noBillsToExport;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

/// Returns the list of allowed admin screen IDs for a given role.
List<String> getAllowedAdminScreensForRole(String role) {
  return roleScreenAccess[role] ?? [];
}

/// Returns true if the given role can access the given admin screen ID.
bool canAccessAdminScreen(String role, String screenId) {
  return getAllowedAdminScreensForRole(role).contains(screenId);
}

// Common screens for all roles
final List<String> commonAdminScreens = [
  AdminScreenIds.login,
  AdminScreenIds.home,
  AdminScreenIds.notification,
  AdminScreenIds.notificationHistory,
  AdminScreenIds.activityLog,
  AdminScreenIds.staffLoginSessions,
  AdminScreenIds.forgotPassword,
  AdminScreenIds.users,
];
// role_screen_access.dart
// Central mapping of staff roles to allowed admin screen IDs/routes.

class AdminScreenIds {
  static List<String> get values => [
        login,
        home,
        notification,
        notificationHistory,
        activityLog,
        staffLoginSessions,
        forgotPassword,
        users,
        pendingIds,
        shoppingHistory,
        voucher,
        inventory,
        messing,
        monthlyMenu,
        mealState,
        menuVote,
        mealStateRecord,
        autoLoopUsers,
        bills,
        payments,
        diningMember,
        staffState,
        allLoginSessions,
        allStaffActivityLog,
        allUserLoginSessions,
        allUserActivityLog,
        addDiningMember,
        addInventory,
        addIndlEntry,
        addMenuList,
        addMenuSet,
        addMessing,
        addMiscEntry,
        addShopping,
        addStaff,
        addTransaction,
        addVoucher,
        premiumRequests,
      ];
  static const login = 'admin_login_screen';
  static const home = 'admin_home_screen';
  static const notification = 'admin_notification_screen';
  static const notificationHistory = 'admin_notification_history_screen';
  static const activityLog = 'staff_own_activity_log_screen';
  static const staffLoginSessions = 'admin_staff_login_sessions_screen';
  static const forgotPassword = 'admin_forgot_password_screen';
  static const users = 'admin_users_screen';
  static const messing = 'admin_messing_screen';
  static const inventory = 'admin_inventory_screen';
  static const monthlyMenu = 'admin_monthly_menu_screen';
  static const mealState = 'admin_meal_state_screen';
  static const mealStateRecord = 'meal_state_record_screen';
  static const autoLoopUsers = 'auto_loop_users_screen';
  static const shoppingHistory = 'admin_shopping_history';
  static const voucher = 'admin_voucher_screen';
  static const diningMember = 'admin_dining_member_state';
  static const pendingIds = 'admin_pending_ids_screen';
  static const menuVote = 'admin_menu_vote_screen';
  static const bills = 'admin_bill_screen';
  static const payments = 'admin_payment_history';
  static const staffState = 'admin_staff_state_screen';
  static const allLoginSessions = 'admin_all_login_sessions_screen';
  static const allStaffActivityLog = 'admin_all_staff_activity_log_screen';
  static const allUserLoginSessions = 'admin_all_user_login_sessions_screen';
  static const allUserActivityLog = 'admin_all_user_activity_log_screen';
  static const addDiningMember = 'add_dining_member';
  static const addInventory = 'add_inventory';
  static const addIndlEntry = 'add_indl_entry';
  static const addMenuList = 'add_menu_list';
  static const addMenuSet = 'add_menu_set';
  static const addMessing = 'add_messing';
  static const addMiscEntry = 'add_misc_entry';
  static const addShopping = 'add_shopping';
  static const addStaff = 'add_staff';
  static const addTransaction = 'add_transaction';
  static const addVoucher = 'add_voucher';
  static const premiumRequests = 'admin_premium_requests_screen';
}

final Map<String, List<String>> roleScreenAccess = {
  // 1. PMC, G2, Mess Secretary, Asst Mess Secretary: all screens
  'PMC': AdminScreenIds.values,
  'G2 (Mess)': AdminScreenIds.values,
  'Mess Secretary': AdminScreenIds.values,
  'Asst Mess Secretary': AdminScreenIds.values,
  // 2. Butler
  'Butler': [
    ...commonAdminScreens,
    AdminScreenIds.messing,
    AdminScreenIds.inventory,
    AdminScreenIds.monthlyMenu,
    AdminScreenIds.mealState,
    AdminScreenIds.mealStateRecord,
    AdminScreenIds.autoLoopUsers,
    AdminScreenIds.premiumRequests,
    // All add_xxx forms related to above
    AdminScreenIds.addMessing,
    AdminScreenIds.addInventory,
    AdminScreenIds.addMenuList,
    AdminScreenIds.addMenuSet,
    AdminScreenIds.addMiscEntry,
    AdminScreenIds.addShopping,
    AdminScreenIds.addTransaction,
  ],
  // 3. Barrack NCO
  'Barrack NCO': [
    ...commonAdminScreens,
    AdminScreenIds.shoppingHistory,
    AdminScreenIds.voucher,
    AdminScreenIds.inventory,
    AdminScreenIds.diningMember,
    // All add_xxx forms related to shopping, voucher, inventory, dining member
    AdminScreenIds.addShopping,
    AdminScreenIds.addVoucher,
    AdminScreenIds.addInventory,
    AdminScreenIds.addDiningMember,
  ],
  // 4. RP NCO
  'RP NCO': [
    ...commonAdminScreens,
    AdminScreenIds.shoppingHistory,
    AdminScreenIds.voucher,
    // All add_xxx forms related to shopping and voucher
    AdminScreenIds.addShopping,
    AdminScreenIds.addVoucher,
  ],
  // 5. Mess Sgt, Asst Mess Sgt
  'Mess Sgt': [
    ...commonAdminScreens,
    AdminScreenIds.shoppingHistory,
    AdminScreenIds.voucher,
    AdminScreenIds.inventory,
    AdminScreenIds.pendingIds,
    AdminScreenIds.messing,
    AdminScreenIds.monthlyMenu,
    AdminScreenIds.mealState,
    AdminScreenIds.mealStateRecord,
    AdminScreenIds.autoLoopUsers,
    AdminScreenIds.menuVote,
    AdminScreenIds.bills,
    AdminScreenIds.payments,
    AdminScreenIds.diningMember,
    AdminScreenIds.premiumRequests,
    // All add_xxx forms related to above
    AdminScreenIds.addShopping,
    AdminScreenIds.addVoucher,
    AdminScreenIds.addInventory,
    AdminScreenIds.addMessing,
    AdminScreenIds.addMenuList,
    AdminScreenIds.addMenuSet,
    AdminScreenIds.addMiscEntry,
    AdminScreenIds.addTransaction,
  ],
  'Asst Mess Sgt': [
    ...commonAdminScreens,
    AdminScreenIds.shoppingHistory,
    AdminScreenIds.voucher,
    AdminScreenIds.inventory,
    AdminScreenIds.pendingIds,
    AdminScreenIds.messing,
    AdminScreenIds.monthlyMenu,
    AdminScreenIds.mealState,
    AdminScreenIds.mealStateRecord,
    AdminScreenIds.autoLoopUsers,
    AdminScreenIds.menuVote,
    AdminScreenIds.bills,
    AdminScreenIds.payments,
    AdminScreenIds.diningMember,
    AdminScreenIds.premiumRequests,
    // All add_xxx forms related to above
    AdminScreenIds.addShopping,
    AdminScreenIds.addVoucher,
    AdminScreenIds.addInventory,
    AdminScreenIds.addMessing,
    AdminScreenIds.addMenuList,
    AdminScreenIds.addMenuSet,
    AdminScreenIds.addMiscEntry,
    AdminScreenIds.addTransaction,
  ],
  // 6. Cook, Waiter
  'Cook': [
    ...commonAdminScreens,
    AdminScreenIds.inventory,
    AdminScreenIds.messing,
    AdminScreenIds.monthlyMenu,
    AdminScreenIds.mealState,
    // All add_xxx forms related to above
    AdminScreenIds.addInventory,
    AdminScreenIds.addMessing,
    AdminScreenIds.addMenuList,
    AdminScreenIds.addMenuSet,
    AdminScreenIds.addMiscEntry,
  ],
  'Waiter': [
    ...commonAdminScreens,
    AdminScreenIds.inventory,
    AdminScreenIds.messing,
    AdminScreenIds.monthlyMenu,
    AdminScreenIds.mealState,
    // All add_xxx forms related to above
    AdminScreenIds.addInventory,
    AdminScreenIds.addMessing,
    AdminScreenIds.addMenuList,
    AdminScreenIds.addMenuSet,
    AdminScreenIds.addMiscEntry,
  ],
  // 7. Clerk
  'Clerk': [
    ...commonAdminScreens,
    AdminScreenIds.pendingIds,
    AdminScreenIds.diningMember,
    AdminScreenIds.staffState,
    AdminScreenIds.bills,
    AdminScreenIds.payments,
    AdminScreenIds.menuVote,
    // All add_xxx forms related to above
    AdminScreenIds.addDiningMember,
    AdminScreenIds.addStaff,
    AdminScreenIds.addTransaction,
  ],
  // 8. NC(E): only common screens
  'NC(E)': [
    ...commonAdminScreens,
  ],
};

bool canAccessScreen(String role, String screenId) {
  return roleScreenAccess[role]?.contains(screenId) ?? false;
}

#!/bin/bash

# Script to help update admin screens with localization
# This script identifies hardcoded strings that need to be replaced

echo "=== Admin Screen Localization Helper ==="
echo "Searching for hardcoded strings in admin screens..."

# List of admin screens to update
screens=(
    "admin_users_screen.dart"
    "admin_pending_ids_screen.dart"
    "admin_shopping_history.dart"
    "admin_voucher_screen.dart"
    "admin_inventory_screen.dart"
    "admin_messing_screen.dart"
    "admin_staff_state_screen.dart"
    "admin_dining_member_state.dart"
    "admin_payment_history.dart"
    "admin_meal_state_screen.dart"
    "admin_bill_screen.dart"
    "admin_monthly_menu_screen.dart"
    "admin_menu_vote_screen.dart"
    "admin_forgot_password_screen.dart"
)

# Common patterns to search for
patterns=(
    '"[A-Z][a-zA-Z ]*"'  # Strings starting with capital letter
    "'[A-Z][a-zA-Z ]*'"  # Single quoted strings
    "Text(\s*['\"][A-Z]"  # Text widgets with hardcoded strings
)

for screen in "${screens[@]}"; do
    file_path="lib/screens/admin/$screen"
    if [ -f "$file_path" ]; then
        echo ""
        echo "=== $screen ==="
        
        # Search for common hardcoded strings
        grep -n "Text(" "$file_path" | grep -v "AppLocalizations" | head -10
        
        echo "Requires imports:"
        echo "import '../../l10n/app_localizations.dart';"
        echo ""
    fi
done

echo ""
echo "=== Next Steps ==="
echo "1. Add import to each screen: import '../../l10n/app_localizations.dart';"
echo "2. Replace Text('String') with Text(AppLocalizations.of(context)!.key)"
echo "3. Add missing strings to ARB files"
echo "4. Run: flutter gen-l10n"
echo "5. Test language switching"

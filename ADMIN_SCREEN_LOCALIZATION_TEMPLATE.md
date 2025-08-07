# Admin Screen Localization Template

This template shows how to quickly add language switching to any admin screen.

**Note**: Admin login screen is kept in English only per design requirements.

## 1. Add Required Imports

Add these imports at the top of your admin screen file:

```dart
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
```

## 2. Add Language Toggle to AppBar

Replace your existing AppBar with this one that includes language switching:

```dart
AppBar(
  title: Text(AppLocalizations.of(context)!.screenTitle), // Replace screenTitle with appropriate key
  backgroundColor: const Color(0xFF002B5B),
  iconTheme: const IconThemeData(color: Colors.white),
  actions: [
    PopupMenuButton<String>(
      icon: const Icon(Icons.language, color: Colors.white),
      onSelected: (String value) {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        if (value == 'en') {
          languageProvider.changeLanguage(const Locale('en'));
        } else if (value == 'bn') {
          languageProvider.changeLanguage(const Locale('bn'));
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'en',
          child: Row(
            children: [
              const Icon(Icons.language),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.english),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'bn',
          child: Row(
            children: [
              const Icon(Icons.language),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.bangla),
            ],
          ),
        ),
      ],
    ),
  ],
),
```

## 3. Replace Hardcoded Strings

### Text Widgets
```dart
// Before:
Text("Users")
Text("Search")
Text("Add User")
Text("Edit")
Text("Delete")
Text("Save")
Text("Cancel")

// After:
Text(AppLocalizations.of(context)!.users)
Text(AppLocalizations.of(context)!.search)
Text(AppLocalizations.of(context)!.addUser)
Text(AppLocalizations.of(context)!.edit)
Text(AppLocalizations.of(context)!.delete)
Text(AppLocalizations.of(context)!.save)
Text(AppLocalizations.of(context)!.cancel)
```

### Form Fields
```dart
// Before:
TextField(
  decoration: InputDecoration(
    labelText: 'Search users...',
  ),
)

// After:
TextField(
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context)!.searchUsers,
  ),
)
```

### Dialog Boxes
```dart
// Before:
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text("Confirm Delete"),
    content: Text("Are you sure?"),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text("Cancel"),
      ),
      TextButton(
        onPressed: () => deleteUser(),
        child: Text("Delete"),
      ),
    ],
  ),
);

// After:
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(AppLocalizations.of(context)!.confirmDelete),
    content: Text(AppLocalizations.of(context)!.areYouSure),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(AppLocalizations.of(context)!.cancel),
      ),
      TextButton(
        onPressed: () => deleteUser(),
        child: Text(AppLocalizations.of(context)!.delete),
      ),
    ],
  ),
);
```

### SnackBar Messages
```dart
// Before:
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('User deleted successfully')),
);

// After:
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(AppLocalizations.of(context)!.userDeletedSuccessfully)),
);
```

## 4. Add Missing Strings to ARB Files

If you use a new string like `userDeletedSuccessfully`, add it to both ARB files:

### lib/l10n/app_en.arb
```json
"userDeletedSuccessfully": "User deleted successfully"
```

### lib/l10n/app_bn.arb  
```json
"userDeletedSuccessfully": "ব্যবহারকারী সফলভাবে মুছে ফেলা হয়েছে"
```

## 5. Regenerate Localization Files

After adding new strings, run:
```bash
flutter gen-l10n
```

## 6. Common String Keys Available

These strings are already available in the ARB files:

- `users` / `ব্যবহারকারী`
- `search` / `অনুসন্ধান`
- `edit` / `সম্পাদনা`
- `delete` / `মুছুন`
- `save` / `সংরক্ষণ`
- `cancel` / `বাতিল`
- `add` / `যোগ করুন`
- `view` / `দেখুন`
- `name` / `নাম`
- `status` / `অবস্থা`
- `active` / `সক্রিয়`
- `inactive` / `নিষ্ক্রিয়`

## Example: Quick Update for Admin Users Screen

1. Add imports to `admin_users_screen.dart`
2. Add language toggle to AppBar
3. Replace `Text("Users")` with `Text(AppLocalizations.of(context)!.users)`
4. Replace search placeholder with `AppLocalizations.of(context)!.searchUsers`
5. Run `flutter gen-l10n`

That's it! The screen will now support language switching.

import '../../services/admin_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMiscEntryScreen extends StatefulWidget {
  const AddMiscEntryScreen({super.key});

  @override
  State<AddMiscEntryScreen> createState() => _AddMiscEntryScreenState();
}

class _AddMiscEntryScreenState extends State<AddMiscEntryScreen> {
  // Loading state
  bool _isLoading = true;

  // Dynamic fields storage
  Map<String, Map<String, TextEditingController>> _dynamicFields = {
    'Subscriptions': {},
    'Regimental Cuttings': {},
    'Miscellaneous': {},
  };

  // Static field configurations (these cannot be deleted)
  final Map<String, Map<String, String>> _staticFields = {
    'Subscriptions': {
      'orderly_pay': 'Orderly Pay',
      'mess_maintenance': 'Mess Maintenance',
      'garden': 'Garden',
      'newspaper': 'Newspaper',
      'silver': 'Silver',
      'dish_antenna': 'Dish Antenna',
      'sports': 'Sports',
      'breakage_charge': 'Breakage Charge',
      'internet_bill': 'Internet Bill',
      'washerman_bill': 'Washerman Bill',
    },
    'Regimental Cuttings': {
      'regimental_cuttings': 'Regimental Cuttings',
      'cantt_sta_sports': 'Cantt Sta Sports',
      'mosque': 'Mosque',
      'reunion': 'Reunion',
      'band': 'Band',
    },
    'Miscellaneous': {
      'miscellaneous': 'Miscellaneous',
      'crest': 'Crest',
      'cleaners_bill': 'Cleaners Bill',
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeStaticFields();
    _loadExistingData();
  }

  void _initializeStaticFields() {
    // Initialize static field controllers
    for (String section in _staticFields.keys) {
      _dynamicFields[section] = {};
      for (String fieldKey in _staticFields[section]!.keys) {
        _dynamicFields[section]![fieldKey] = TextEditingController(text: '0');
      }
    }
  }

  Future<void> _loadExistingData() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Load data for each section
      for (String section in [
        'Subscriptions',
        'Regimental Cuttings',
        'Miscellaneous'
      ]) {
        final doc = await firestore.collection('misc_entry').doc(section).get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;

          // Load existing static fields
          for (String fieldKey in _staticFields[section]!.keys) {
            if (_dynamicFields[section]!.containsKey(fieldKey)) {
              _dynamicFields[section]![fieldKey]!.text =
                  (data[fieldKey] ?? 0.0).toString();
            }
          }

          // Load dynamic fields that aren't in static fields
          data.forEach((key, value) {
            if (key != 'last_updated' &&
                !_staticFields[section]!.containsKey(key)) {
              if (!_dynamicFields[section]!.containsKey(key)) {
                _dynamicFields[section]![key] =
                    TextEditingController(text: value.toString());
              }
            }
          });
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _saveEntries() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Save'),
          content: const Text('Are you sure you want to save the entries?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        final firestore = FirebaseFirestore.instance;
        final batch = firestore.batch();
        final adminData = await AdminAuthService().getCurrentAdminData();
        final adminBaNo = adminData?['ba_no'] ?? '';
        final adminName = adminData?['name'] ?? 'Unknown';
        final List<String> logMessages = [];

        // Fetch old data for all sections
        Map<String, Map<String, dynamic>> oldData = {};
        for (String section in _dynamicFields.keys) {
          final doc =
              await firestore.collection('misc_entry').doc(section).get();
          oldData[section] =
              doc.exists ? (doc.data() as Map<String, dynamic>) : {};
        }

        // Save data for each section and compare for changes
        for (String section in _dynamicFields.keys) {
          Map<String, dynamic> sectionData = {};
          final oldSection = oldData[section] ?? {};

          _dynamicFields[section]!.forEach((fieldKey, controller) {
            final newValue = double.tryParse(controller.text) ?? 0.0;
            sectionData[fieldKey] = newValue;
            final oldValue = oldSection[fieldKey] is num
                ? oldSection[fieldKey].toDouble()
                : double.tryParse((oldSection[fieldKey] ?? '0').toString()) ??
                    0.0;
            if (oldSection.containsKey(fieldKey) && oldValue != newValue) {
              // Log only changed fields
              logMessages.add(
                '$adminName changed the ${_getFieldLabel(section, fieldKey)} from ${oldValue.toStringAsFixed(2)} to ${newValue.toStringAsFixed(2)}.',
              );
            }
          });

          sectionData['last_updated'] = FieldValue.serverTimestamp();
          batch.set(
            firestore.collection('misc_entry').doc(section),
            sectionData,
            SetOptions(merge: true),
          );
        }

        // Commit the batch
        await batch.commit();

        // Log activity for changed fields only
        if (adminBaNo.isNotEmpty) {
          for (final msg in logMessages) {
            await firestore
                .collection('staff_activity_log')
                .doc(adminBaNo)
                .collection('logs')
                .add({
              'timestamp': FieldValue.serverTimestamp(),
              'actionType': 'Edit Misc Entry',
              'message': msg,
              'admin_id': adminData?['uid'] ?? '',
              'admin_name': adminName,
            });
          }
        }

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entries saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        // Close loading dialog
        if (mounted) Navigator.pop(context);

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving entries: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _addNewField(String section) async {
    final TextEditingController fieldNameController = TextEditingController();
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Field to $section'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fieldNameController,
                decoration: const InputDecoration(
                  labelText: 'Field Name',
                  hintText: 'e.g., Wedding Programme',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: Field name will be converted to snake_case for database storage',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (fieldNameController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(true);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result == true && fieldNameController.text.trim().isNotEmpty) {
      final String fieldName = fieldNameController.text.trim();
      final String fieldKey = _convertToSnakeCase(fieldName);

      // Check if field already exists
      if (_dynamicFields[section]!.containsKey(fieldKey)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Field already exists!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      setState(() {
        _dynamicFields[section]![fieldKey] = TextEditingController(text: '0');
      });

      // Log activity for add field
      final adminData = await AdminAuthService().getCurrentAdminData();
      final adminBaNo = adminData?['ba_no'] ?? '';
      final adminName = adminData?['name'] ?? 'Unknown';
      if (adminBaNo.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('staff_activity_log')
            .doc(adminBaNo)
            .collection('logs')
            .add({
          'timestamp': FieldValue.serverTimestamp(),
          'actionType': 'Add Misc Field',
          'message':
              'Admin $adminName added new field "$fieldName" ($fieldKey) to $section.',
          'admin_id': adminData?['uid'] ?? '',
          'admin_name': adminName,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "$fieldName" to $section'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
    fieldNameController.dispose();
  }

  Future<void> _deleteField(String section, String fieldKey) async {
    // Don't allow deletion of static fields
    if (_staticFields[section]!.containsKey(fieldKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete default fields!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final String fieldLabel = _getFieldLabel(section, fieldKey);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
              'Are you sure you want to delete "$fieldLabel"?\n\nThis will permanently remove the field from the database.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // Remove from Firebase
        await FirebaseFirestore.instance
            .collection('misc_entry')
            .doc(section)
            .update({fieldKey: FieldValue.delete()});

        // Log activity for delete field
        final adminData = await AdminAuthService().getCurrentAdminData();
        final adminBaNo = adminData?['ba_no'] ?? '';
        final adminName = adminData?['name'] ?? 'Unknown';
        if (adminBaNo.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('staff_activity_log')
              .doc(adminBaNo)
              .collection('logs')
              .add({
            'timestamp': FieldValue.serverTimestamp(),
            'actionType': 'Delete Misc Field',
            'message':
                'Admin $adminName deleted field "$fieldLabel" ($fieldKey) from $section.',
            'admin_id': adminData?['uid'] ?? '',
            'admin_name': adminName,
          });
        }

        // Remove from local state
        setState(() {
          _dynamicFields[section]![fieldKey]?.dispose();
          _dynamicFields[section]!.remove(fieldKey);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "$fieldLabel" from $section'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting field: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _convertToSnakeCase(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String _getFieldLabel(String section, String fieldKey) {
    // Check if it's a static field first
    if (_staticFields[section]!.containsKey(fieldKey)) {
      return _staticFields[section]![fieldKey]!;
    }

    // Convert snake_case back to readable format
    return fieldKey
        .split('_')
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Future<void> _cancelEntries() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Cancel'),
          content: const Text('Are you sure you want to discard the changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      Navigator.pop(context);
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String section,
    required String fieldKey,
  }) {
    final bool canDelete = !_staticFields[section]!.containsKey(fieldKey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          if (canDelete) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _deleteField(section, fieldKey),
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete custom field',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({required String section}) {
    final fields = _dynamicFields[section]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                section,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002B5B),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _addNewField(section),
              icon: const Icon(Icons.add_circle, color: Colors.green),
              tooltip: 'Add new field',
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...fields.entries.map((entry) {
          final fieldKey = entry.key;
          final controller = entry.value;
          final label = _getFieldLabel(section, fieldKey);

          return _buildTextField(
            label: label,
            controller: controller,
            section: section,
            fieldKey: fieldKey,
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _cancelEntries,
        ),
        title: const Text(
          'Misc Entry',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dynamic sections
                            _buildSection(section: 'Subscriptions'),
                            _buildSection(section: 'Regimental Cuttings'),
                            _buildSection(section: 'Miscellaneous'),

                            // Buttons
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _saveEntries,
                                  icon: const Icon(Icons.save),
                                  label: const Text('Save'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A4D8F),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: _cancelEntries,
                                  icon: const Icon(Icons.cancel),
                                  label: const Text('Cancel'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    // Dispose all dynamic controllers
    for (String section in _dynamicFields.keys) {
      for (TextEditingController controller
          in _dynamicFields[section]!.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }
}

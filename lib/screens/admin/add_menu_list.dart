import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_auth_service.dart';

final AdminAuthService _adminAuthService = AdminAuthService();
Map<String, dynamic>? _currentUserData;

class AddMenuListScreen extends StatefulWidget {
  const AddMenuListScreen({super.key});

  @override
  State<AddMenuListScreen> createState() => _AddMenuListScreenState();
}

class _AddMenuListScreenState extends State<AddMenuListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  final TextEditingController _breakfastItemController =
      TextEditingController();
  final TextEditingController _breakfastPriceController =
      TextEditingController();
  final TextEditingController _lunchItemController = TextEditingController();
  final TextEditingController _lunchPriceController = TextEditingController();
  final TextEditingController _dinnerItemController = TextEditingController();
  final TextEditingController _dinnerPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final data = await _adminAuthService.getCurrentAdminData();
    if (mounted) {
      setState(() {
        _currentUserData = data;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _breakfastItemController.dispose();
    _breakfastPriceController.dispose();
    _lunchItemController.dispose();
    _lunchPriceController.dispose();
    _dinnerItemController.dispose();
    _dinnerPriceController.dispose();
    super.dispose();
  }

  bool _isLoading = false;
  bool _isLoadingExistingData = false;

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      // Check if date is selected
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final firestore = FirebaseFirestore.instance;

        // Format date as document ID (YYYY-MM-DD)
        final String dateId =
            '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

        final docRef = firestore.collection('monthly_menu').doc(dateId);

        // Check if document exists
        final docSnapshot = await docRef.get();

        // Prepare data with smart NULL handling - only include non-empty fields
        Map<String, dynamic> menuData = {};

        // Add breakfast data if provided
        if (_breakfastItemController.text.isNotEmpty ||
            _breakfastPriceController.text.isNotEmpty) {
          menuData['breakfast'] = {
            if (_breakfastItemController.text.isNotEmpty)
              'item': _breakfastItemController.text.trim(),
            if (_breakfastPriceController.text.isNotEmpty)
              'price': double.tryParse(_breakfastPriceController.text) ?? 0.0,
          };
        }

        // Add lunch data if provided
        if (_lunchItemController.text.isNotEmpty ||
            _lunchPriceController.text.isNotEmpty) {
          menuData['lunch'] = {
            if (_lunchItemController.text.isNotEmpty)
              'item': _lunchItemController.text.trim(),
            if (_lunchPriceController.text.isNotEmpty)
              'price': double.tryParse(_lunchPriceController.text) ?? 0.0,
          };
        }

        // Add dinner data if provided
        if (_dinnerItemController.text.isNotEmpty ||
            _dinnerPriceController.text.isNotEmpty) {
          menuData['dinner'] = {
            if (_dinnerItemController.text.isNotEmpty)
              'item': _dinnerItemController.text.trim(),
            if (_dinnerPriceController.text.isNotEmpty)
              'price': double.tryParse(_dinnerPriceController.text) ?? 0.0,
          };
        }

        // Add metadata
        menuData['date'] = _selectedDate!;
        menuData['lastUpdated'] = FieldValue.serverTimestamp();

        if (docSnapshot.exists) {
          // Document exists - merge with existing data (smart update)
          await docRef.update(menuData);
          // Log update activity
          final adminName = _currentUserData?['name'] ?? 'Admin';
          final baNo = _currentUserData?['ba_no'] ?? '';
          if (baNo.isNotEmpty) {
            final details =
                'Breakfast: \\${menuData['breakfast'] ?? {}}; Lunch: \\${menuData['lunch'] ?? {}}; Dinner: \\${menuData['dinner'] ?? {}}; Date: $dateId';
            await firestore
                .collection('staff_activity_log')
                .doc(baNo)
                .collection('logs')
                .add({
              'timestamp': FieldValue.serverTimestamp(),
              'actionType': 'Update Menu Entry',
              'message': '$adminName updated menu entry. Details: $details',
              'name': adminName,
            });
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu updated successfully!')),
          );
        } else {
          // Document doesn't exist - create new
          await docRef.set(menuData);
          // Log create activity
          final adminName = _currentUserData?['name'] ?? 'Admin';
          final baNo = _currentUserData?['ba_no'] ?? '';
          if (baNo.isNotEmpty) {
            final details =
                'Breakfast: \\${menuData['breakfast'] ?? {}}; Lunch: \\${menuData['lunch'] ?? {}}; Dinner: \\${menuData['dinner'] ?? {}}; Date: $dateId';
            await firestore
                .collection('staff_activity_log')
                .doc(baNo)
                .collection('logs')
                .add({
              'timestamp': FieldValue.serverTimestamp(),
              'actionType': 'Add Menu Entry',
              'message': '$adminName added menu entry. Details: $details',
              'name': adminName,
            });
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu created successfully!')),
          );
        }

        Navigator.pop(context, true); // Return true to indicate success
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving menu: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleCancel() async {
    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancel'),
        content: const Text('Are you sure you want to cancel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      Navigator.pop(context);
    }
  }

  Widget _buildMealInput(String label, TextEditingController itemController,
      TextEditingController priceController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: itemController,
                decoration: InputDecoration(
                  hintText: 'Item name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Price',
                  prefixText: '৳',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Invalid price';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Manage Menu Entry",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Manage Menu Entry",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF002B5B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Select a date to create new menu or edit existing menu",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Meal Date:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final DateTime? picked =
                                        await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _selectedDate ?? DateTime.now(),
                                      firstDate: DateTime(2020, 1, 1),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _selectedDate = picked;
                                      });
                                      // Check if menu exists for picked date
                                      final firestore =
                                          FirebaseFirestore.instance;
                                      final String dateId =
                                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                      final docSnapshot = await firestore
                                          .collection('monthly_menu')
                                          .doc(dateId)
                                          .get();
                                      if (docSnapshot.exists) {
                                        final data = docSnapshot.data()!;
                                        // Show dialog with current data and update option
                                        await showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text(
                                                  'Menu already exists for this date'),
                                              content: SingleChildScrollView(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (data['breakfast'] !=
                                                        null)
                                                      Text(
                                                          'Breakfast: \\nItem: \\${data['breakfast']['item'] ?? ''} \\nPrice: \\${data['breakfast']['price'] ?? ''}'),
                                                    if (data['lunch'] != null)
                                                      Text(
                                                          'Lunch: \\nItem: \\${data['lunch']['item'] ?? ''} \\nPrice: \\${data['lunch']['price'] ?? ''}'),
                                                    if (data['dinner'] != null)
                                                      Text(
                                                          'Dinner: \\nItem: \\${data['dinner']['item'] ?? ''} \\nPrice: \\${data['dinner']['price'] ?? ''}'),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    // Pre-fill form fields for update
                                                    if (data['breakfast'] !=
                                                        null) {
                                                      _breakfastItemController
                                                              .text =
                                                          data['breakfast']
                                                                  ['item'] ??
                                                              '';
                                                      _breakfastPriceController
                                                              .text =
                                                          data['breakfast']
                                                                      ['price']
                                                                  ?.toString() ??
                                                              '';
                                                    } else {
                                                      _breakfastItemController
                                                          .clear();
                                                      _breakfastPriceController
                                                          .clear();
                                                    }
                                                    if (data['lunch'] != null) {
                                                      _lunchItemController
                                                          .text = data['lunch']
                                                              ['item'] ??
                                                          '';
                                                      _lunchPriceController
                                                          .text = data['lunch']
                                                                  ['price']
                                                              ?.toString() ??
                                                          '';
                                                    } else {
                                                      _lunchItemController
                                                          .clear();
                                                      _lunchPriceController
                                                          .clear();
                                                    }
                                                    if (data['dinner'] !=
                                                        null) {
                                                      _dinnerItemController
                                                          .text = data['dinner']
                                                              ['item'] ??
                                                          '';
                                                      _dinnerPriceController
                                                          .text = data['dinner']
                                                                  ['price']
                                                              ?.toString() ??
                                                          '';
                                                    } else {
                                                      _dinnerItemController
                                                          .clear();
                                                      _dinnerPriceController
                                                          .clear();
                                                    }
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('Update'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  child: const Text('Cancel'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      } else {
                                        // No existing data - clear all fields
                                        _breakfastItemController.clear();
                                        _breakfastPriceController.clear();
                                        _lunchItemController.clear();
                                        _lunchPriceController.clear();
                                        _dinnerItemController.clear();
                                        _dinnerPriceController.clear();
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: Colors.grey[600],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        if (_isLoadingExistingData)
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        else
                                          Text(
                                            _selectedDate == null
                                                ? 'Select date'
                                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                            style: TextStyle(
                                              color: _selectedDate == null
                                                  ? Colors.grey[600]
                                                  : Colors.black,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildMealInput(
                                'Breakfast',
                                _breakfastItemController,
                                _breakfastPriceController),
                            const SizedBox(height: 20),
                            _buildMealInput('Lunch', _lunchItemController,
                                _lunchPriceController),
                            const SizedBox(height: 20),
                            _buildMealInput('Dinner', _dinnerItemController,
                                _dinnerPriceController),
                            const SizedBox(height: 30),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final buttonWidth =
                                    (constraints.maxWidth - 16) / 2;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: buttonWidth.clamp(120, 150),
                                      height: 45,
                                      child: ElevatedButton(
                                        onPressed: _handleCancel,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: buttonWidth.clamp(120, 150),
                                      height: 45,
                                      child: ElevatedButton(
                                        onPressed:
                                            _isLoading ? null : _handleSave,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF007bff),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text(
                                                'Save',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

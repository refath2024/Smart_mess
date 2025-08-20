import '../../services/admin_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMessingScreen extends StatefulWidget {
  const AddMessingScreen({super.key});

  @override
  State<AddMessingScreen> createState() => _AddMessingScreenState();
}

class _AddMessingScreenState extends State<AddMessingScreen> {
  // Page states
  int _currentStep = 0; // 0: Date, 1: Meal Selection, 2: Form
  DateTime? _selectedDate;
  String _selectedMealType = '';
  bool _isSubmitting = false;

  // Form controllers
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _amountUsedController = TextEditingController();
  final TextEditingController _diningMembersController =
      TextEditingController();

  // Inventory integration
  List<Map<String, dynamic>> _inventoryItems = [];
  Map<String, dynamic>? _selectedInventoryItem;
  bool _isLoadingInventory = false;
  double _availableQuantity = 0.0;

  // Calculated fields
  double _priceExpended = 0.0;
  double _pricePerMember = 0.0;

  @override
  void initState() {
    super.initState();
    _setupCalculationListeners();
    _loadInventoryItems();
  }

  void _setupCalculationListeners() {
    _unitPriceController.addListener(_calculatePriceExpended);
    _amountUsedController.addListener(_calculatePriceExpended);
    _diningMembersController.addListener(_calculatePricePerMember);
  }

  Future<void> _loadInventoryItems() async {
    setState(() {
      _isLoadingInventory = true;
    });

    try {
      print('🔄 Loading inventory items...');
      final snapshot =
          await FirebaseFirestore.instance.collection('inventory').get();

      print('📦 Found ${snapshot.docs.length} inventory documents');

      List<Map<String, dynamic>> items = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String?;
        final productName = data['productName'] as String?;
        final quantityHeld = data['quantityHeld'];

        print(
            '🏷️ Processing item: $productName, type: $type, quantity: $quantityHeld');

        // Only include 'fresh' and 'ration' type items
        if (type == 'fresh' || type == 'ration') {
          items.add({
            'id': doc.id,
            'productName': productName ?? 'Unknown',
            'quantityHeld': (quantityHeld ?? 0).toDouble(),
            'type': type,
          });
          print('✅ Added item: $productName (${type})');
        } else {
          print('❌ Skipped item: $productName (type: $type)');
        }
      }

      print('📋 Total filtered items: ${items.length}');

      setState(() {
        _inventoryItems = items;
        _isLoadingInventory = false;
      });

      print('🎉 Inventory loading completed successfully');
    } catch (e) {
      print('❌ Error loading inventory: $e');
      setState(() {
        _isLoadingInventory = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading inventory: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String? _validateAmountUsed(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number';
    }

    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }

    if (amount > _availableQuantity) {
      return 'Amount exceeds available quantity (${_availableQuantity.toStringAsFixed(2)})';
    }

    return null;
  }

  Future<void> _updateInventoryQuantity(
      String inventoryId, double amountUsed) async {
    try {
      final inventoryDoc = await FirebaseFirestore.instance
          .collection('inventory')
          .doc(inventoryId)
          .get();

      if (inventoryDoc.exists) {
        final currentQuantity =
            (inventoryDoc.data()!['quantityHeld'] ?? 0).toDouble();
        final newQuantity = currentQuantity - amountUsed;

        await FirebaseFirestore.instance
            .collection('inventory')
            .doc(inventoryId)
            .update({
          'quantityHeld': newQuantity >= 0 ? newQuantity : 0,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        print(
            '✅ Updated inventory: ${inventoryDoc.data()!['productName']} - Used: $amountUsed, Remaining: $newQuantity');
      }
    } catch (e) {
      print('Error updating inventory quantity: $e');
      throw e; // Re-throw to handle in calling function
    }
  }

  void _calculatePriceExpended() {
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
    final amountUsed = double.tryParse(_amountUsedController.text) ?? 0.0;
    setState(() {
      _priceExpended = unitPrice * amountUsed;
    });
    _calculatePricePerMember();
  }

  void _calculatePricePerMember() {
    final diningMembers = double.tryParse(_diningMembersController.text) ?? 0.0;
    setState(() {
      _pricePerMember =
          diningMembers > 0 ? _priceExpended / diningMembers : 0.0;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _currentStep = 1;
      });
    }
  }

  void _selectMealType(String mealType) {
    setState(() {
      _selectedMealType = mealType;
      _currentStep = 2;
    });
  }

  Future<int> _getNextMealNumber() async {
    if (_selectedDate == null) return 1;

    final dateStr =
        "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

    try {
      final doc = await FirebaseFirestore.instance
          .collection('messing_data')
          .doc(dateStr)
          .get();

      if (!doc.exists) return 1;

      final data = doc.data() as Map<String, dynamic>;
      String prefix = _selectedMealType == 'Breakfast'
          ? 'B'
          : _selectedMealType == 'Lunch'
              ? 'L'
              : 'D';

      int maxNumber = 0;
      for (String key in data.keys) {
        if (key.startsWith(prefix)) {
          final match = RegExp(r'^[BLD](\d+)_').firstMatch(key);
          if (match != null) {
            final number = int.tryParse(match.group(1)!) ?? 0;
            if (number > maxNumber) maxNumber = number;
          }
        }
      }

      return maxNumber + 1;
    } catch (e) {
      print('Error getting next meal number: $e');
      return 1;
    }
  }

  Future<void> _submitForm() async {
    if (_selectedDate == null || _selectedMealType.isEmpty) return;

    // Validate required fields
    if (_productNameController.text.trim().isEmpty ||
        _unitPriceController.text.trim().isEmpty ||
        _amountUsedController.text.trim().isEmpty ||
        _diningMembersController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // Validate inventory selection and amount
    if (_selectedInventoryItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product from inventory')),
      );
      return;
    }

    final amountUsed = double.tryParse(_amountUsedController.text) ?? 0.0;
    final validationError = _validateAmountUsed(_amountUsedController.text);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final mealNumber = await _getNextMealNumber();
      final dateStr =
          "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

      String prefix = _selectedMealType == 'Breakfast'
          ? 'B'
          : _selectedMealType == 'Lunch'
              ? 'L'
              : 'D';

      final mealData = {
        '$prefix${mealNumber}_product_name': _productNameController.text.trim(),
        '$prefix${mealNumber}_unit_price':
            double.parse(_unitPriceController.text),
        '$prefix${mealNumber}_amount_used': amountUsed,
        '$prefix${mealNumber}_dining_members':
            double.parse(_diningMembersController.text),
        '$prefix${mealNumber}_price_expended': _priceExpended,
        '$prefix${mealNumber}_price_per_member': _pricePerMember,
        '$prefix${mealNumber}_meal_type': _selectedMealType,
        '$prefix${mealNumber}_inventory_item_id': _selectedInventoryItem!['id'],
        '$prefix${mealNumber}_timestamp': FieldValue.serverTimestamp(),
      };

      // Add the new meal item
      // Log activity after successful add
      final adminData = await AdminAuthService().getCurrentAdminData();
      final adminBaNo = adminData?['ba_no'] ?? '';
      final adminName = adminData?['name'] ?? 'Unknown';
      if (adminBaNo.isNotEmpty) {
        final msg =
            '$adminName added a messing entry on $dateStr: Meal Type: $_selectedMealType, Product: ${_productNameController.text.trim()}, Unit Price: ${_unitPriceController.text}, Amount Used: ${_amountUsedController.text}, Dining Members: ${_diningMembersController.text}, Price Expended: $_priceExpended, Price Per Member: $_pricePerMember, Inventory Item ID: ${_selectedInventoryItem!['id']}.';
        await FirebaseFirestore.instance
            .collection('staff_activity_log')
            .doc(adminBaNo)
            .collection('logs')
            .add({
          'timestamp': FieldValue.serverTimestamp(),
          'actionType': 'Add Messing Entry',
          'message': msg,
          'admin_id': adminData?['uid'] ?? '',
          'admin_name': adminName,
        });
      }
      await FirebaseFirestore.instance
          .collection('messing_data')
          .doc(dateStr)
          .set(mealData, SetOptions(merge: true));

      // Update inventory - deduct the amount used
      await _updateInventoryQuantity(_selectedInventoryItem!['id'], amountUsed);

      // Calculate and update meal totals
      await _updateMealTotals(dateStr, prefix);

      // Reload inventory to get updated quantities
      await _loadInventoryItems();

      // Clear form for next entry
      setState(() {
        _selectedInventoryItem = null;
        _availableQuantity = 0.0;
        _priceExpended = 0.0;
        _pricePerMember = 0.0;
      });
      _productNameController.clear();
      _unitPriceController.clear();
      _amountUsedController.clear();
      _diningMembersController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    '$_selectedMealType item saved and inventory updated! ✓'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _updateMealTotals(String dateStr, String prefix) async {
    try {
      // Get the current document
      final doc = await FirebaseFirestore.instance
          .collection('messing_data')
          .doc(dateStr)
          .get();

      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;

      // Calculate totals for the specific meal type
      double totalPriceExpended = 0.0;
      double totalPricePerMember = 0.0;

      for (String key in data.keys) {
        if (key.startsWith('${prefix}') && key.contains('_')) {
          if (key.endsWith('_price_expended')) {
            final value = data[key];
            if (value is num) {
              totalPriceExpended += value.toDouble();
            }
          } else if (key.endsWith('_price_per_member')) {
            final value = data[key];
            if (value is num) {
              totalPricePerMember += value.toDouble();
            }
          }
        }
      }

      // Determine meal type name for the total fields
      String mealTypeName = prefix == 'B'
          ? 'breakfast'
          : prefix == 'L'
              ? 'lunch'
              : 'dinner';

      // Update the totals in the messing_data document
      final totalFields = {
        '${mealTypeName}_total_price_expended': totalPriceExpended,
        '${mealTypeName}_total_price_per_member': totalPricePerMember,
        '${mealTypeName}_last_updated': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('messing_data')
          .doc(dateStr)
          .set(totalFields, SetOptions(merge: true));

      // TRIGGER: Update the monthly_menu collection with the calculated price per member
      await _updateMonthlyMenuPrice(dateStr, mealTypeName, totalPricePerMember);
    } catch (e) {
      print('Error updating meal totals: $e');
      // Don't throw error to prevent breaking the main flow
    }
  }

  Future<void> _updateMonthlyMenuPrice(
      String dateStr, String mealType, double pricePerMember) async {
    try {
      // Update the price subfield in monthly_menu collection
      final menuPriceData = {
        'price': pricePerMember,
        'updated_from_messing': true,
        'last_updated': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('monthly_menu')
          .doc(dateStr)
          .set({
        mealType: menuPriceData,
      }, SetOptions(merge: true));

      print(
          '✅ Updated $mealType price in monthly_menu: ${pricePerMember.toStringAsFixed(2)} BDT');
    } catch (e) {
      print('Error updating monthly menu price: $e');
      // Don't throw error to prevent breaking the main flow
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        if (_currentStep == 0) {
          _selectedDate = null;
          _selectedMealType = '';
        } else if (_currentStep == 1) {
          _selectedMealType = '';
        }
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _cancelToMain() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _unitPriceController.dispose();
    _amountUsedController.dispose();
    _diningMembersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _goBack,
        ),
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done, color: Colors.white),
            onPressed: _cancelToMain,
            tooltip: 'Done',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildCurrentStep(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentStep) {
      case 0:
        return 'Select Date';
      case 1:
        return 'Select Meal Time';
      case 2:
        return '$_selectedMealType - ${_getFormattedDate()}';
      default:
        return 'Add Messing Data';
    }
  }

  String _getFormattedDate() {
    if (_selectedDate == null) return '';
    return "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildDateSelection();
      case 1:
        return _buildMealSelection();
      case 2:
        return _buildMessingForm();
      default:
        return _buildDateSelection();
    }
  }

  Widget _buildDateSelection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.calendar_today,
          size: 64,
          color: Color(0xFF002B5B),
        ),
        const SizedBox(height: 20),
        const Text(
          'Select Date for Messing Data',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF002B5B),
          ),
        ),
        const SizedBox(height: 20),
        if (_selectedDate != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              'Selected: ${_getFormattedDate()}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_month),
            label: Text(_selectedDate == null ? 'Choose Date' : 'Change Date'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A4D8F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealSelection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.restaurant,
          size: 64,
          color: Color(0xFF002B5B),
        ),
        const SizedBox(height: 20),
        const Text(
          'Select Meal Time',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF002B5B),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Date: ${_getFormattedDate()}',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 30),
        _buildMealButton('Breakfast', Icons.free_breakfast),
        const SizedBox(height: 15),
        _buildMealButton('Lunch', Icons.lunch_dining),
        const SizedBox(height: 15),
        _buildMealButton('Dinner', Icons.dinner_dining),
      ],
    );
  }

  Widget _buildMealButton(String mealType, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _selectMealType(mealType),
        icon: Icon(icon),
        label: Text(mealType),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A4D8F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildMessingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with meal info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Text(
                _selectedMealType,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002B5B),
                ),
              ),
              Text(
                'Date: ${_getFormattedDate()}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Manual reload button for debugging
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoadingInventory
                    ? null
                    : () {
                        _loadInventoryItems();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🔄 Manually reloading inventory...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                icon: const Icon(Icons.refresh),
                label: Text(
                    _isLoadingInventory ? 'Loading...' : 'Reload Inventory'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Form fields
        _buildProductDropdown(),

        // Debug info (can be removed in production)
        if (_inventoryItems.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📦 Inventory Status: ${_inventoryItems.length} items loaded',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Types: ${_inventoryItems.map((item) => item['type']).toSet().join(', ')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),

        _buildTextField(
          label: 'Unit Price (Per Litre/Kg) *',
          controller: _unitPriceController,
          keyboardType: TextInputType.number,
          suffixText: 'BDT',
        ),
        _buildAmountUsedField(),

        // Calculated Price Expended (Read-only)
        _buildCalculatedField(
          label: 'Price Expended',
          value: _priceExpended.toStringAsFixed(2),
          suffixText: 'BDT',
        ),

        _buildTextField(
          label: 'Dining Members *',
          controller: _diningMembersController,
          keyboardType: TextInputType.number,
        ),

        // Calculated Price Per Member (Read-only)
        _buildCalculatedField(
          label: 'Price per Member',
          value: _pricePerMember.toStringAsFixed(2),
          suffixText: 'BDT',
        ),

        const SizedBox(height: 32),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitForm,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                    _isSubmitting ? 'Saving Data...' : 'Save Item & Add More'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Navigation buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = 1;
                  });
                },
                icon: const Icon(Icons.restaurant),
                label: const Text('Change Meal'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                  });
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Change Date'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? suffixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffixText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatedField({
    required String label,
    required String value,
    String? suffixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: TextEditingController(text: value),
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffixText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildProductDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Product Name *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_selectedInventoryItem != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _availableQuantity > 0
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _availableQuantity > 0 ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Available: ${_availableQuantity.toStringAsFixed(2)} ${_selectedInventoryItem!['type']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _availableQuantity > 0
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Loading indicator
          if (_isLoadingInventory)
            Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Loading inventory items...'),
                  ],
                ),
              ),
            )

          // No items found
          else if (_inventoryItems.isEmpty)
            Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.orange.shade50,
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'No fresh/ration items found in inventory',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ),
            )

          // Dropdown with items
          else
            GestureDetector(
              onTap: () async {
                final selected = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) {
                    String search = '';
                    List<Map<String, dynamic>> filtered = _inventoryItems;
                    return StatefulBuilder(
                      builder: (context, setState) {
                        filtered = _inventoryItems.where((item) {
                          final s = search.toLowerCase();
                          return (item['productName'] != null &&
                                  item['productName']
                                      .toString()
                                      .toLowerCase()
                                      .contains(s)) ||
                              (item['type'] != null &&
                                  item['type']
                                      .toString()
                                      .toLowerCase()
                                      .contains(s));
                        }).toList();
                        return AlertDialog(
                          title: const Text('Search Inventory'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  decoration: const InputDecoration(
                                      hintText: 'Type to search...'),
                                  onChanged: (val) =>
                                      setState(() => search = val),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.maxFinite,
                                  height: 300,
                                  child: filtered.isEmpty
                                      ? const Center(
                                          child: Text('No items found'))
                                      : ListView.builder(
                                          itemCount: filtered.length,
                                          itemBuilder: (context, idx) {
                                            final item = filtered[idx];
                                            return ListTile(
                                              title: Text(
                                                  '${item['productName']}'),
                                              subtitle: Text(
                                                  'Type: ${item['type']} | Qty: ${item['quantityHeld'].toStringAsFixed(2)}'),
                                              onTap: () => Navigator.of(context)
                                                  .pop(item),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
                if (selected != null) {
                  setState(() {
                    _selectedInventoryItem = selected;
                    _productNameController.text = selected['productName'];
                    _availableQuantity =
                        selected['quantityHeld']?.toDouble() ?? 0.0;
                  });
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  hintText: 'Select product from inventory',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  _selectedInventoryItem == null
                      ? 'Choose a product'
                      : '${_selectedInventoryItem!['productName']} (${_selectedInventoryItem!['type']}, ${_selectedInventoryItem!['quantityHeld'].toStringAsFixed(2)})',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

          // Add refresh button if loading failed
          if (!_isLoadingInventory && _inventoryItems.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: _loadInventoryItems,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Loading Inventory'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmountUsedField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _amountUsedController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Amount Used (Litre/Kg) *',
          hintText: _selectedInventoryItem != null
              ? 'Max: ${_availableQuantity.toStringAsFixed(2)}'
              : 'Select product first',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          errorMaxLines: 2,
        ),
        enabled: _selectedInventoryItem != null,
        validator: _validateAmountUsed,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }
}

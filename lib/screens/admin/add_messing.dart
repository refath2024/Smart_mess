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

  // Calculated fields
  double _priceExpended = 0.0;
  double _pricePerMember = 0.0;

  @override
  void initState() {
    super.initState();
    _setupCalculationListeners();
  }

  void _setupCalculationListeners() {
    _unitPriceController.addListener(_calculatePriceExpended);
    _amountUsedController.addListener(_calculatePriceExpended);
    _diningMembersController.addListener(_calculatePricePerMember);
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
        '$prefix${mealNumber}_amount_used':
            double.parse(_amountUsedController.text),
        '$prefix${mealNumber}_dining_members':
            double.parse(_diningMembersController.text),
        '$prefix${mealNumber}_price_expended': _priceExpended,
        '$prefix${mealNumber}_price_per_member': _pricePerMember,
        '$prefix${mealNumber}_meal_type': _selectedMealType,
        '$prefix${mealNumber}_timestamp': FieldValue.serverTimestamp(),
      };

      // Add the new meal item
      await FirebaseFirestore.instance
          .collection('messing_data')
          .doc(dateStr)
          .set(mealData, SetOptions(merge: true));

      // Calculate and update meal totals
      await _updateMealTotals(dateStr, prefix);

      // Clear form for next entry
      _productNameController.clear();
      _unitPriceController.clear();
      _amountUsedController.clear();
      _diningMembersController.clear();
      setState(() {
        _priceExpended = 0.0;
        _pricePerMember = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('$_selectedMealType item saved successfully! ✓'),
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

        // Form fields
        _buildTextField(
          label: 'Product Name *',
          controller: _productNameController,
        ),
        _buildTextField(
          label: 'Unit Price (Per Litre/Kg) *',
          controller: _unitPriceController,
          keyboardType: TextInputType.number,
          suffixText: 'BDT',
        ),
        _buildTextField(
          label: 'Amount Used (Litre/Kg) *',
          controller: _amountUsedController,
          keyboardType: TextInputType.number,
        ),

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
}

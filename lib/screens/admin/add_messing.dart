import 'package:flutter/material.dart';

class AddMessingScreen extends StatefulWidget {
  const AddMessingScreen({super.key});

  @override
  State<AddMessingScreen> createState() => _AddMessingScreenState();
}

class _AddMessingScreenState extends State<AddMessingScreen> {
  bool _showMealSelection = true;
  String _selectedMealType = '';

  // Controllers for product entries
  final List<ProductEntry> _productEntries = [];

  @override
  void initState() {
    super.initState();
    // Add initial product entry
    _addProductEntry();
  }

  void _selectMealType(String mealType) {
    setState(() {
      _selectedMealType = mealType;
      _showMealSelection = false;
    });
  }

  void _addProductEntry() {
    setState(() {
      _productEntries.add(ProductEntry(
        onRemove: _removeProductEntry,
      ));
    });
  }

  void _removeProductEntry(ProductEntry entry) {
    if (_productEntries.length > 1) {
      setState(() {
        _productEntries.remove(entry);
      });
    }
  }

  Future<void> _submitForm() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Submit'),
          content: const Text('Are you sure you want to submit this entry?'),
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
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // TODO: Implement API call here
      // For now, just show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry successfully submitted!')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _cancelForm() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _cancelForm,
        ),
        title: Text(
          _showMealSelection ? 'Select Meal Time' : _selectedMealType,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _showMealSelection
                    ? _buildMealSelection()
                    : _buildMessingForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealSelection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Select Meal Time',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF002B5B),
          ),
        ),
        const SizedBox(height: 20),
        _buildMealButton('Breakfast'),
        const SizedBox(height: 10),
        _buildMealButton('Lunch'),
        const SizedBox(height: 10),
        _buildMealButton('Dinner'),
      ],
    );
  }

  Widget _buildMealButton(String mealType) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _selectMealType(mealType),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A4D8F),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          mealType,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._productEntries,
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _addProductEntry,
          icon: const Icon(Icons.add),
          label: const Text('Add More Item'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A4D8F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Submit'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _cancelForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ProductEntry extends StatefulWidget {
  final Function(ProductEntry) onRemove;

  final TextEditingController productNameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController membersController = TextEditingController();

  ProductEntry({
    super.key,
    required this.onRemove,
  });

  @override
  State<ProductEntry> createState() => _ProductEntryState();
}

class _ProductEntryState extends State<ProductEntry> {
  @override
  void dispose() {
    widget.productNameController.dispose();
    widget.amountController.dispose();
    widget.priceController.dispose();
    widget.membersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => widget.onRemove(widget),
              ),
            ],
          ),
          _buildTextField(
            label: 'Product Name',
            controller: widget.productNameController,
          ),
          _buildTextField(
            label: 'Amount (in gram)',
            controller: widget.amountController,
            keyboardType: TextInputType.number,
          ),
          _buildTextField(
            label: 'Price',
            controller: widget.priceController,
            keyboardType: TextInputType.number,
          ),
          _buildTextField(
            label: 'Dine-in Members',
            controller: widget.membersController,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
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
}

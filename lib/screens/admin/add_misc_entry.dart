import 'package:flutter/material.dart';

class AddMiscEntryScreen extends StatefulWidget {
  const AddMiscEntryScreen({super.key});

  @override
  State<AddMiscEntryScreen> createState() => _AddMiscEntryScreenState();
}

class _AddMiscEntryScreenState extends State<AddMiscEntryScreen> {
  // Subscriptions Controllers
  final TextEditingController _orderlyPayController =
      TextEditingController(text: '0');
  final TextEditingController _messMaintenanceController =
      TextEditingController(text: '0');
  final TextEditingController _gardenController =
      TextEditingController(text: '0');
  final TextEditingController _newspaperController =
      TextEditingController(text: '0');
  final TextEditingController _silverController =
      TextEditingController(text: '0');
  final TextEditingController _dishAntennaController =
      TextEditingController(text: '0');
  final TextEditingController _sportsController =
      TextEditingController(text: '0');
  final TextEditingController _breakageChargeController =
      TextEditingController(text: '0');
  final TextEditingController _internetBillController =
      TextEditingController(text: '0');
  final TextEditingController _washermanBillController =
      TextEditingController(text: '0');

  // Regimental Cuttings Controllers
  final TextEditingController _regimentalCuttingsController =
      TextEditingController(text: '0');
  final TextEditingController _canttStaSportsController =
      TextEditingController(text: '0');
  final TextEditingController _mosqueController =
      TextEditingController(text: '0');
  final TextEditingController _reunionController =
      TextEditingController(text: '0');
  final TextEditingController _bandController =
      TextEditingController(text: '0');

  // Miscellaneous Controllers
  final TextEditingController _miscellaneousController =
      TextEditingController(text: '0');
  final TextEditingController _crestController =
      TextEditingController(text: '0');
  final TextEditingController _cleanersBillController =
      TextEditingController(text: '0');

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
      // TODO: Implement API call to save data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entries saved successfully!')),
      );
      Navigator.pop(context);
    }
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF002B5B),
          ),
        ),
        const SizedBox(height: 16),
        ...children,
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
      body: SingleChildScrollView(
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
                      // Subscriptions Section
                      _buildSection(
                        title: 'Subscriptions',
                        children: [
                          _buildTextField(
                              label: 'Orderly Pay',
                              controller: _orderlyPayController),
                          _buildTextField(
                              label: 'Mess Maintenance',
                              controller: _messMaintenanceController),
                          _buildTextField(
                              label: 'Garden', controller: _gardenController),
                          _buildTextField(
                              label: 'Newspaper',
                              controller: _newspaperController),
                          _buildTextField(
                              label: 'Silver', controller: _silverController),
                          _buildTextField(
                              label: 'Dish Antenna',
                              controller: _dishAntennaController),
                          _buildTextField(
                              label: 'Sports', controller: _sportsController),
                          _buildTextField(
                              label: 'Breakage Charge',
                              controller: _breakageChargeController),
                          _buildTextField(
                              label: 'Internet Bill',
                              controller: _internetBillController),
                          _buildTextField(
                              label: 'Washerman Bill',
                              controller: _washermanBillController),
                        ],
                      ),

                      // Regimental Cuttings Section
                      _buildSection(
                        title: 'Regimental Cuttings',
                        children: [
                          _buildTextField(
                              label: 'Regimental Cuttings',
                              controller: _regimentalCuttingsController),
                          _buildTextField(
                              label: 'Cantt Sta Sports',
                              controller: _canttStaSportsController),
                          _buildTextField(
                              label: 'Mosque', controller: _mosqueController),
                          _buildTextField(
                              label: 'Reunion', controller: _reunionController),
                          _buildTextField(
                              label: 'Band', controller: _bandController),
                        ],
                      ),

                      // Miscellaneous Section
                      _buildSection(
                        title: 'Miscellaneous',
                        children: [
                          _buildTextField(
                              label: 'Miscellaneous',
                              controller: _miscellaneousController),
                          _buildTextField(
                              label: 'Crest', controller: _crestController),
                          _buildTextField(
                              label: 'Cleaners Bill',
                              controller: _cleanersBillController),
                        ],
                      ),

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
    // Dispose all controllers
    _orderlyPayController.dispose();
    _messMaintenanceController.dispose();
    _gardenController.dispose();
    _newspaperController.dispose();
    _silverController.dispose();
    _dishAntennaController.dispose();
    _sportsController.dispose();
    _breakageChargeController.dispose();
    _internetBillController.dispose();
    _washermanBillController.dispose();
    _regimentalCuttingsController.dispose();
    _canttStaSportsController.dispose();
    _mosqueController.dispose();
    _reunionController.dispose();
    _bandController.dispose();
    _miscellaneousController.dispose();
    _crestController.dispose();
    _cleanersBillController.dispose();
    super.dispose();
  }
}

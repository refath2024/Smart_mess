import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/premium_request.dart';
import '../../services/premium_request_service.dart';
import '../../theme_provider.dart';
import 'package:provider/provider.dart';

class PremiumRequestScreen extends StatefulWidget {
  const PremiumRequestScreen({super.key});

  @override
  State<PremiumRequestScreen> createState() => _PremiumRequestScreenState();
}

class _PremiumRequestScreenState extends State<PremiumRequestScreen> {
  final PremiumRequestService _premiumRequestService = PremiumRequestService();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedMealType = 'dinner';
  String? _selectedMeal;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _mealTypes = ['breakfast', 'lunch', 'dinner'];

  @override
  void initState() {
    super.initState();
    _updateMealOptions();
  }

  void _updateMealOptions() {
    final meals = PremiumMealOptions.getMealsForType(_selectedMealType);
    if (meals.isNotEmpty) {
      _selectedMeal = meals.first;
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMeal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a meal')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final requestId = await _premiumRequestService.submitPremiumRequest(
        mealType: _selectedMealType,
        preferredMeal: _selectedMeal!,
        requestedDate: _selectedDate,
        reason: _reasonController.text.trim(),
      );

      if (requestId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit request. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _resetForm() {
    _selectedMealType = 'dinner';
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _reasonController.clear();
    _updateMealOptions();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Meal Request'),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          color: Colors.orange[600],
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Request Premium Meals',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Request special premium meals for special occasions or personal preferences. Additional charges apply.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Request Form
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meal Type Selection
                      const Text(
                        'Meal Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedMealType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.schedule),
                        ),
                        items: _mealTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMealType = value!;
                            _updateMealOptions();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Premium Meal Selection
                      const Text(
                        'Premium Meal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedMeal,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.restaurant),
                        ),
                        items: PremiumMealOptions.getMealsForType(_selectedMealType)
                            .map((meal) {
                          final cost = PremiumMealOptions.getCostForMeal(meal);
                          return DropdownMenuItem(
                            value: meal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(meal)),
                                Text(
                                  '\$${cost.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMeal = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a premium meal';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Date Selection
                      const Text(
                        'Requested Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 12),
                              Text(DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Reason TextField
                      const Text(
                        'Reason for Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.note),
                          hintText: 'e.g., Special occasion, dietary preference, etc.',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please provide a reason for your request';
                          }
                          if (value.trim().length < 10) {
                            return 'Please provide a more detailed reason (min 10 characters)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Cost Display
                      if (_selectedMeal != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            border: Border.all(color: Colors.orange[200]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.attach_money, color: Colors.orange[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Additional Cost: \$${PremiumMealOptions.getCostForMeal(_selectedMeal!).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSubmitting
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Submitting...'),
                                  ],
                                )
                              : const Text(
                                  'Submit Premium Request',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // My Requests Section
            StreamBuilder<List<PremiumRequest>>(
              stream: _premiumRequestService.getUserPremiumRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No premium requests yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Premium Requests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...snapshot.data!.map((request) => _buildRequestCard(request)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(PremiumRequest request) {
    Color statusColor;
    IconData statusIcon;
    
    switch (request.status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          '${request.preferredMeal} (${request.mealType.toUpperCase()})',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${DateFormat('MMM dd, yyyy').format(request.requestedDate)}'),
            Text('Status: ${request.status.toUpperCase()}'),
            if (request.additionalCost != null)
              Text('Cost: \$${request.additionalCost!.toStringAsFixed(2)}'),
            if (request.rejectionReason != null)
              Text(
                'Reason: ${request.rejectionReason}',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
        trailing: request.status == 'pending'
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteRequest(request.id),
              )
            : null,
      ),
    );
  }

  Future<void> _deleteRequest(String requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: const Text('Are you sure you want to delete this premium request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _premiumRequestService.deletePremiumRequest(requestId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
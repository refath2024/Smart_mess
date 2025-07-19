import 'package:flutter/material.dart';
import '../login_screen.dart';
import 'admin_users_screen.dart';
import 'admin_pending_ids_screen.dart';
import 'admin_shopping_history.dart';
import 'admin_voucher_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_messing_screen.dart';
import 'admin_staff_state_screen.dart';
import 'admin_dining_member_state.dart';
import 'admin_payment_history.dart';
import 'admin_meal_state_screen.dart';
import 'admin_bill_screen.dart';
import 'admin_home_screen.dart';

class EditMenuScreen extends StatefulWidget {
  const EditMenuScreen({super.key});

  @override
  State<EditMenuScreen> createState() => _EditMenuScreenState();
}

class _EditMenuScreenState extends State<EditMenuScreen> {
  List<Map<String, dynamic>> menuData = [];

  @override
  void initState() {
    super.initState();
    fetchMenu();
  }

  void fetchMenu() async {
    // Simulated fetch. Replace with actual HTTP GET from your API.
    setState(() {
      menuData = [
        {
          'id': '1',
          'date': '2025-07-16',
          'breakfast': 'Paratha',
          'breakfastPrice': '30',
          'lunch': 'Rice & Chicken',
          'lunchPrice': '70',
          'dinner': 'Khichuri',
          'dinnerPrice': '50',
        },
        // Add more items here
      ];
    });
  }

  void editRow(int index) {
    showDialog(
      context: context,
      builder: (context) {
        final item = menuData[index];
        final breakfastController =
            TextEditingController(text: item['breakfast']);
        final lunchController = TextEditingController(text: item['lunch']);
        final dinnerController = TextEditingController(text: item['dinner']);

        return AlertDialog(
          title: const Text('Edit Menu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: breakfastController,
                decoration: const InputDecoration(labelText: 'Breakfast'),
              ),
              TextField(
                controller: lunchController,
                decoration: const InputDecoration(labelText: 'Lunch'),
              ),
              TextField(
                controller: dinnerController,
                decoration: const InputDecoration(labelText: 'Dinner'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  menuData[index]['breakfast'] = breakfastController.text;
                  menuData[index]['lunch'] = lunchController.text;
                  menuData[index]['dinner'] = dinnerController.text;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void deleteRow(int index) {
    setState(() {
      menuData.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Menu'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Go'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Create'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: menuData.length,
                itemBuilder: (context, index) {
                  final item = menuData[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text('Date: ${item['date']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Breakfast: ${item['breakfast']} (৳${item['breakfastPrice']})'),
                          Text(
                              'Lunch: ${item['lunch']} (৳${item['lunchPrice']})'),
                          Text(
                              'Dinner: ${item['dinner']} (৳${item['dinnerPrice']})'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => editRow(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteRow(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

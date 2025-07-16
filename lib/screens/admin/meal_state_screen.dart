import 'package:flutter/material.dart';

// To use routing, add this route to your MaterialApp routes:
// routes: {
//   '/mealState': (context) => const MealStateScreen(),
// }

// To navigate:
// Navigator.pushNamed(context, '/mealState');
class MealStateScreen extends StatefulWidget {
  const MealStateScreen({Key? key}) : super(key: key);

  @override
  State<MealStateScreen> createState() => _MealStateScreenState();
}

class _MealStateScreenState extends State<MealStateScreen> {
  final TextEditingController _searchController = TextEditingController();
  final String date = '17/07/2025';

  // Dummy data for table
  final List<Map<String, String>> records = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Officer Meal State'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search All Text Columns',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Go'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('See Records'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Date: $date', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('BA No')),
                    DataColumn(label: Text('Rk')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Breakfast')),
                    DataColumn(label: Text('Lunch')),
                    DataColumn(label: Text('Dinner')),
                    DataColumn(label: Text('Disposals')),
                    DataColumn(label: Text('Remarks')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: records.isEmpty
                      ? [
                          DataRow(cells: List.generate(9, (index) => const DataCell(Text('-')))),
                        ]
                      : records.map((record) {
                          return DataRow(cells: [
                            DataCell(Text(record['BA No'] ?? '')),
                            DataCell(Text(record['Rk'] ?? '')),
                            DataCell(Text(record['Name'] ?? '')),
                            DataCell(Text(record['Breakfast'] ?? '')),
                            DataCell(Text(record['Lunch'] ?? '')),
                            DataCell(Text(record['Dinner'] ?? '')),
                            DataCell(Text(record['Disposals'] ?? '')),
                            DataCell(Text(record['Remarks'] ?? '')),
                            DataCell(
                              ElevatedButton(
                                onPressed: () {},
                                child: const Text('Edit'),
                              ),
                            ),
                          ]);
                        }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Total Breakfast Members: 0', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Total Lunch Members: 0', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Total Dinner Members: 0', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Total Disposals: SIQ = 0, Leave = 0, Mess Out = 0', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Remarks: 0', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

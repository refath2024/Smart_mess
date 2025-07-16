import 'package:flutter/material.dart';
import '../login_screen.dart';
import 'admin_home_screen.dart';
import 'admin_users_screen.dart';
import 'admin_pending_ids_screen.dart';
import 'admin_shopping_history.dart';
import 'admin_voucher_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_messing_screen.dart';
import 'admin_staff_state_screen.dart';
import 'admin_dining_member_state.dart';
import 'admin_payment_history.dart';
import 'meal_state_screen.dart';

class BillScreen extends StatefulWidget {
  const BillScreen({Key? key}) : super(key: key);

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  List<Map<String, dynamic>> bills = []; // will hold bill data
  String searchTerm = "";

  @override
  void initState() {
    super.initState();
    fetchBills(); // Simulated fetch
  }

  void fetchBills() {
    // Simulated API data fetch (replace with actual logic)
    setState(() {
      bills = [
        {
          "ba_no": "123456",
          "rank": "Captain",
          "name": "Rahim",
          "bill_status": "Unpaid",
          "previous_arrear": 500,
          "current_bill": 1500,
          "total_due": 2000
        },
        {
          "ba_no": "654321",
          "rank": "Major",
          "name": "Karim",
          "bill_status": "Paid",
          "previous_arrear": 0,
          "current_bill": 1700,
          "total_due": 1700
        },
        // Add more dummy data as needed
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredBills = bills.where((bill) {
      final combined = (bill['ba_no'] + bill['rank'] + bill['name']).toLowerCase();
      return combined.contains(searchTerm.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchBills,
            tooltip: 'Refresh Bills',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by BA No, Name or Rank...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) => setState(() => searchTerm = val),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    // Replace with PDF generation logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("PDF generation not implemented")),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Generate Bills"),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Table headers
            Container(
              color: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                children: const [
                  Expanded(flex: 2, child: Text("BA No")),
                  Expanded(flex: 2, child: Text("Rank")),
                  Expanded(flex: 3, child: Text("Name")),
                  Expanded(flex: 2, child: Text("Status")),
                  Expanded(flex: 2, child: Text("Arrear")),
                  Expanded(flex: 2, child: Text("Current Bill")),
                  Expanded(flex: 2, child: Text("Total Due")),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Bill list
            Expanded(
              child: filteredBills.isEmpty
                  ? const Center(child: Text("No bills found."))
                  : ListView.builder(
                      itemCount: filteredBills.length,
                      itemBuilder: (context, index) {
                        final bill = filteredBills[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade100,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text(bill['ba_no'])),
                              Expanded(flex: 2, child: Text(bill['rank'])),
                              Expanded(flex: 3, child: Text(bill['name'])),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  bill['bill_status'],
                                  style: TextStyle(
                                    color: bill['bill_status'] == "Paid" ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(flex: 2, child: Text("${bill['previous_arrear']}")),
                              Expanded(flex: 2, child: Text("${bill['current_bill']}")),
                              Expanded(flex: 2, child: Text("${bill['total_due']}")),
                            ],
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

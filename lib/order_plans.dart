import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'edit_order_plan.dart';

class OrderPlans extends StatefulWidget {
  const OrderPlans({super.key});

  @override
  _OrderPlansState createState() => _OrderPlansState();
}

class _OrderPlansState extends State<OrderPlans> {
  final DatabaseHelper storageManager = DatabaseHelper();
  List<Map<String, dynamic>> plansData = [];

  @override
  void initState() {
    super.initState();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    final fetchedPlans = await storageManager.getAllPlans();
    setState(() {
      plansData = fetchedPlans;
    });
  }

  Future<void> removePlan(int planId) async {
    await storageManager.removePlan(planId);
    fetchPlans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plans')),
      body: plansData.isEmpty
          ? const Center(
        child: Text(
          'Zero Plans found',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      )
          : ListView.builder(
        itemCount: plansData.length,
        itemBuilder: (context, index) {
          final planDetails = plansData[index];
          return Card(
            color: Colors.grey[850],
            margin: const EdgeInsets.all(8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 3,
            child: ListTile(
              title: Text(
                'Date: ${planDetails['date']}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Budget: \$${planDetails['target_cost']}'),
                  Text('Items: ${planDetails['items']}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditOrderPlan(
                            planIdentifier: planDetails['id'],
                            planDate: planDetails['date'],
                            budgetLimit: planDetails['target_cost'],
                            includedItems: planDetails['items'],
                          ),
                        ),
                      ).then((_) => fetchPlans());
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.green),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          backgroundColor: Colors.grey[900],
                          title: const Text('Delete Plan'),
                          content: const Text(
                            'Do you want to delete this plan?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                removePlan(planDetails['id']);
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

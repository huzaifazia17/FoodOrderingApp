import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'order_plans.dart';

void main() {
  runApp(const FoodOrderingApp());
}

class FoodOrderingApp extends StatelessWidget {
  const FoodOrderingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Ordering App',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      home: const ItemSelectionScreen(),
    );
  }
}

class ItemSelectionScreen extends StatefulWidget {
  const ItemSelectionScreen({super.key});

  @override
  _ItemSelectionScreenState createState() => _ItemSelectionScreenState();
}

class _ItemSelectionScreenState extends State<ItemSelectionScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> availableItems = [];
  Map<String, int> selectedQuantities = {};
  double budgetLimit = 0.0;
  double totalCost = 0.0;
  String selectedDay = 'DATE NOT SELECTED';
  final TextEditingController budgetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAvailableItems();
  }

  Future<void> fetchAvailableItems() async {
    final items = await dbHelper.getItems();
    setState(() {
      availableItems = items;
    });
  }

  void displayError(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Error',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        );
      },
    );
  }

  void incrementItem(Map<String, dynamic> item) {
    final name = item['name'];
    final cost = item['cost'];

    if (totalCost + cost <= budgetLimit) {
      setState(() {
        selectedQuantities[name] = (selectedQuantities[name] ?? 0) + 1;
        totalCost += cost;
      });
    } else {
      displayError('Adding this item exceeds your budget!');
    }
  }

  void decrementItem(String name) {
    if (selectedQuantities[name] != null && selectedQuantities[name]! > 0) {
      final item = availableItems.firstWhere(
            (element) => element['name'] == name,
        orElse: () => {},
      );

      if (item.isNotEmpty) {
        setState(() {
          totalCost -= item['cost'];
          if (selectedQuantities[name] == 1) {
            selectedQuantities.remove(name);
          } else {
            selectedQuantities[name] = selectedQuantities[name]! - 1;
          }
        });
      }
    }
  }

  void setBudget(double newBudget) {
    if (newBudget < totalCost) {
      displayError('Budget may not be less than total expense! The items have been reset.');
      setState(() {
        selectedQuantities.clear();
        totalCost = 0.0;
      });
    } else {
      setState(() {
        budgetLimit = newBudget;
      });
    }
  }

  Future<void> saveOrder() async {
    if (selectedDay == 'DATE NOT SELECTED' || selectedQuantities.isEmpty || budgetLimit <= 0) {
      displayError('Fill in required fields');
      return;
    }

    List<String> itemList = [];
    selectedQuantities.forEach((name, quantity) {
      for (int i = 0; i < quantity; i++) {
        itemList.add(name);
      }
    });
    String items = itemList.join(', ');

    await dbHelper.addPlan(selectedDay, items, budgetLimit);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Success',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Order plan saved.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );

    setState(() {
      selectedQuantities.clear();
      totalCost = 0.0;
    });
  }

  void pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDay = '${picked.year}-${picked.month}-${picked.day}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: budgetController,
                      decoration: const InputDecoration(
                        labelText: 'Budget',
                        labelStyle: TextStyle(fontSize: 18),
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 20),
                      onChanged: (value) {
                        final newBudget = double.tryParse(value) ?? 0.0;
                        setBudget(newBudget);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Select Date'),
                          onPressed: pickDate,
                        ),
                        Text(
                          selectedDay,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      'Total Cost: \$${totalCost.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: availableItems.length,
              itemBuilder: (context, index) {
                final item = availableItems[index];
                final name = item['name'];
                final quantity = selectedQuantities[name] ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text('\$${item['cost']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.remove_circle, color: Colors.green),
                          onPressed: quantity > 0 ? () => decrementItem(name) : null,
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.add_circle, color: Colors.blue),
                          onPressed: () => incrementItem(item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: saveOrder,
                  child: const Text('Save'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OrderPlans()),
                    );
                  },
                  child: const Text('View My Orders'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

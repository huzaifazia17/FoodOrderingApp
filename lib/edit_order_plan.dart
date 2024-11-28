import 'package:flutter/material.dart';
import 'database_helper.dart';

class EditOrderPlan extends StatefulWidget {
  final int planIdentifier;
  final String planDate;
  final double budgetLimit;
  final String includedItems;

  const EditOrderPlan({
    super.key,
    required this.planIdentifier,
    required this.planDate,
    required this.budgetLimit,
    required this.includedItems,
  });

  @override
  _EditOrderPlanState createState() => _EditOrderPlanState();
}

class _EditOrderPlanState extends State<EditOrderPlan> {
  final DatabaseHelper dbManager = DatabaseHelper();
  List<Map<String, dynamic>> availableItems = [];
  Map<String, int> chosenItems = {};
  double totalExpense = 0.0;
  double maxBudget = 0.0;

  @override
  void initState() {
    super.initState();
    maxBudget = widget.budgetLimit;
    loadAvailableItems();
  }

  Future<void> loadAvailableItems() async {
    final items = await dbManager.getItems();
    setState(() {
      availableItems = items;
    });

    List<String> initialSelectedItems = widget.includedItems.split(', ');
    for (var item in initialSelectedItems) {
      if (item.isNotEmpty) {
        chosenItems[item] = (chosenItems[item] ?? 0) + 1;
      }
    }

    calculateTotalExpense();
  }

  void calculateTotalExpense() {
    double expense = 0.0;
    chosenItems.forEach((itemName, quantity) {
      final item = availableItems.firstWhere(
            (element) => element['name'] == itemName,
        orElse: () => {},
      );
      if (item.isNotEmpty) {
        expense += item['cost'] * quantity;
      }
    });
    setState(() {
      totalExpense = expense;
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

  void addItem(Map<String, dynamic> item) {
    final itemName = item['name'];
    final itemCost = item['cost'];

    if (totalExpense + itemCost <= maxBudget) {
      setState(() {
        chosenItems[itemName] = (chosenItems[itemName] ?? 0) + 1;
        totalExpense += itemCost;
      });
    } else {
      displayError('This item will increase your budget!');
    }
  }

  void removeItem(String itemName) {
    if (chosenItems[itemName] != null && chosenItems[itemName]! > 0) {
      final item = availableItems.firstWhere(
            (element) => element['name'] == itemName,
        orElse: () => {},
      );

      if (item.isNotEmpty) {
        setState(() {
          totalExpense -= item['cost'];
          if (chosenItems[itemName] == 1) {
            chosenItems.remove(itemName);
          } else {
            chosenItems[itemName] = chosenItems[itemName]! - 1;
          }
        });
      }
    }
  }

  void adjustBudget(double newBudget) {
    if (newBudget < totalExpense) {
      displayError('Budget may not be less than total expense! The items have been reset.');
      setState(() {
        chosenItems.clear();
        totalExpense = 0.0;
      });
    } else {
      setState(() {
        maxBudget = newBudget;
      });
    }
  }

  Future<void> savePlanChanges() async {
    if (chosenItems.isEmpty || maxBudget <= 0) {
      displayError('Fill in required fields');
      return;
    }

    List<String> updatedItemList = [];
    chosenItems.forEach((itemName, quantity) {
      for (int i = 0; i < quantity; i++) {
        updatedItemList.add(itemName);
      }
    });
    String updatedItems = updatedItemList.join(', ');

    await dbManager.updatePlan(widget.planIdentifier, maxBudget.toString(), updatedItems);

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
            'Order plan updated!',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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
  }

  void openBudgetEditDialog() {
    final TextEditingController budgetController =
    TextEditingController(text: maxBudget.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Edit Budget',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.blue,
            ),
          ),
          content: TextField(
            controller: budgetController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: const InputDecoration(
              labelText: 'Budget',
              labelStyle: TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.green),
              ),
            ),
            TextButton(
              onPressed: () {
                final newBudget = double.tryParse(budgetController.text) ?? maxBudget;
                adjustBudget(newBudget);
                Navigator.pop(context);
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit My Order Plan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  widget.planDate,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'The Budget: \$${maxBudget.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: openBudgetEditDialog,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'The Total: \$${totalExpense.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: availableItems.length,
              itemBuilder: (context, index) {
                final item = availableItems[index];
                final itemName = item['name'];
                final itemCount = chosenItems[itemName] ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    title: Text(
                      itemName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('\$${item['cost']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.remove_circle, color: Colors.green),
                          onPressed: itemCount > 0 ? () => removeItem(itemName) : null,
                        ),
                        Text(
                          '$itemCount',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.add_circle, color: Colors.blue),
                          onPressed: () => addItem(item),
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
            child: ElevatedButton(
              onPressed: savePlanChanges,
              child: const Text('Save My Changes'),
            ),
          ),
        ],
      ),
    );
  }
}

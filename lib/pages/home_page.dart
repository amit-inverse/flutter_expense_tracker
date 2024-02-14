import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // text controllers
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  // open new expense box
  void openNewExpenseBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // user input -> expense name
            TextField(
              controller: nameController,
            ),

            // user input -> expense amount
            TextField(
              controller: amountController,
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: openNewExpenseBox,
        child: const Icon(Icons.add),
      ),
    );
  }
}

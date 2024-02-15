import 'package:expense_tracker/databases/expense_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../bar_graphs/bar_graph.dart';
import '../components/my_list_tile.dart';
import '../helpers/helper_functions.dart';
import '../models/expense.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // text controllers
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  // futures to load graph data
  Future<Map<int, double>>? _monthlyTotalsFuture;

  @override
  void initState() {
    // read db on initial startup
    Provider.of<ExpenseDatabase>(context, listen: false).readExpense();

    // load futures
    refreshGraphData();

    super.initState();
  }

  // refresh graph data
  void refreshGraphData() {
    _monthlyTotalsFuture = Provider.of<ExpenseDatabase>(context, listen: false)
        .calculateMonthlyTotals();
  }

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
              decoration: const InputDecoration(hintText: "Name"),
            ),

            // user input -> expense amount
            TextField(
              controller: amountController,
              decoration: const InputDecoration(hintText: "Amount"),
            )
          ],
        ),
        actions: [
          // cancel button
          _cancelButton(),

          // save button
          _createNewExpenseButton(),
        ],
      ),
    );
  }

  // open edit box
  void openEditBox(Expense expense) {
    // pre-fill existing values into textfields
    String existingName = expense.name;
    String existingAmount = expense.amount.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // user input -> expense name
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: existingName),
            ),

            // user input -> expense amount
            TextField(
              controller: amountController,
              decoration: InputDecoration(hintText: existingAmount),
            )
          ],
        ),
        actions: [
          // cancel button
          _cancelButton(),

          // save button
          _editExpenseButton(expense),
        ],
      ),
    );
  }

  // open delete box
  void openDeleteBox(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense'),
        actions: [
          // cancel button
          _cancelButton(),

          // delete button
          _deleteExpenseButton(expense.id),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseDatabase>(
      builder: (context, value, child) {
        // get dates
        int startMonth = value.geetStartMonth();
        int startYear = value.geetStartYear();
        int currentMonth = DateTime.now().month;
        int currentYear = DateTime.now().year;

        // calculate the number of months since the first month
        int monthCount = calculateMonthCount(
            startYear, startMonth, currentYear, currentMonth);

        // only display the expenses for the current month

        // return ui
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: openNewExpenseBox,
            child: const Icon(Icons.add),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // graph ui
                SizedBox(
                  height: 250,
                  child: FutureBuilder(
                    future: _monthlyTotalsFuture,
                    builder: (context, snapshot) {
                      // data is loaded
                      if (snapshot.connectionState == ConnectionState.done) {
                        final monthlyTotals = snapshot.data ?? {};

                        // create the list of monthly summary
                        List<double> monthlySummary = List.generate(
                            monthCount,
                            (index) =>
                                monthlyTotals[startMonth + index] ?? 0.0);

                        return MyBarGraph(
                            monthlySummary: monthlySummary,
                            startMonth: startMonth);
                      }

                      // loading...
                      else {
                        return const Center(
                          child: Text("Loading..."),
                        );
                      }
                    },
                  ),
                ),

                // expanded list ui
                Expanded(
                  child: ListView.builder(
                    itemCount: value.allExpense.length,
                    itemBuilder: (context, index) {
                      // get individual expense
                      Expense individualExpense = value.allExpense[index];

                      // return list tile ui
                      return MyListTile(
                        title: individualExpense.name,
                        trailing: formatAmount(individualExpense.amount),
                        onEditPressed: (context) =>
                            openEditBox(individualExpense),
                        onDeletePressed: (context) =>
                            openDeleteBox(individualExpense),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // cancel button
  Widget _cancelButton() {
    return MaterialButton(
      onPressed: () {
        // pop box
        Navigator.pop(context);

        // clear controllers
        nameController.clear();
        amountController.clear();
      },
      child: const Text('Cancel'),
    );
  }

  // save button -> create new expense
  Widget _createNewExpenseButton() {
    return MaterialButton(
      onPressed: () async {
        // only save if there is something in the textfields to save
        if (nameController.text.isNotEmpty &&
            amountController.text.isNotEmpty) {
          // pop box
          Navigator.pop(context);

          // create new expense
          Expense newExpense = Expense(
            name: nameController.text,
            amount: convertStringToDouble(amountController.text),
            date: DateTime.now(),
          );

          // save to db
          await context.read<ExpenseDatabase>().createNewExpense(newExpense);

          // refresh graph
          refreshGraphData();

          // clear controllers
          nameController.clear();
          amountController.clear();
        }
      },
      child: const Text('Save'),
    );
  }

  // save button -> edit existing expense
  Widget _editExpenseButton(Expense expense) {
    return MaterialButton(
      onPressed: () async {
        // save as long as at least one textfield has been changed
        if (nameController.text.isNotEmpty ||
            amountController.text.isNotEmpty) {
          // pop box
          Navigator.pop(context);

          // create a new updated expense
          Expense updatedExpense = Expense(
            name: nameController.text.isNotEmpty
                ? nameController.text
                : expense.name,
            amount: amountController.text.isNotEmpty
                ? convertStringToDouble(amountController.text)
                : expense.amount,
            date: DateTime.now(),
          );

          // old expense id
          int existingId = expense.id;

          // save to db
          await context
              .read<ExpenseDatabase>()
              .updateExpense(existingId, updatedExpense);

          // refresh graph
          refreshGraphData();

          // clear controllers
          nameController.clear();
          amountController.clear();
        }
      },
      child: const Text('Save'),
    );
  }

  // delete button
  Widget _deleteExpenseButton(int id) {
    return MaterialButton(
      onPressed: () async {
        // pop box
        Navigator.pop(context);

        // delete expense from db
        await context.read<ExpenseDatabase>().deleteExpense(id);

        // refresh graph
        refreshGraphData();
      },
      child: const Text('Delete'),
    );
  }
}

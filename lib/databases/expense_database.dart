import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/expense.dart';

class ExpenseDatabase extends ChangeNotifier {
  static late Isar isar;
  List<Expense> _allExpenses = [];

  /*

  S E T U P

  */

  // initialize db
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([ExpenseSchema], directory: dir.path);
  }

  /*

  G E T T E R S

  */

  List<Expense> get allExpense => _allExpenses;

  /*

  O P E R A T I O N S

  */

  // Create - add a new expense
  Future<void> createNewExpense(Expense newExpense) async {
    // add to db
    await isar.writeTxn(() => isar.expenses.put(newExpense));

    // re-read from db
    await readExpense();
  }

  // Read - expenses from db
  Future<void> readExpense() async {
    // fetch all existing expenses from db
    List<Expense> fetchedExpenses = await isar.expenses.where().findAll();

    // give to local expense list
    _allExpenses.clear();
    _allExpenses.addAll(fetchedExpenses);

    // update UI
    notifyListeners();
  }

  // Update - edit an expense in db
  Future<void> updateExpense(int id, Expense updatedExpense) async {
    // make sure new expense has same id as existing one
    updatedExpense.id = id;

    // update in db
    await isar.writeTxn(() => isar.expenses.put(updatedExpense));

    // re-read from db
    await readExpense();
  }

  // Delete - an expense
  Future<void> deleteExpense(int id) async {
    // delete from db
    await isar.writeTxn(() => isar.expenses.delete(id));

    // re-read from db
    await readExpense();
  }

  /*

  H E L P E R S

  */

  // calculate total expenses for each month
  Future<Map<int, double>> calculateMonthlyTotals() async {
    // ensure the expenses are read from the db
    await readExpense();

    // create a map to keep track of total expenses per month
    Map<int, double> monthlyTotals = {
      // 0: 25    jan
      // 1: 100   feb
    };

    // iterate over all expenses
    for (var expense in _allExpenses) {
      // extract the month from the date of the expense
      int month = expense.date.month;

      // if the month is not yet in the map, initialize to 0
      if (!monthlyTotals.containsKey(month)) {
        monthlyTotals[month] = 0;
      }

      // add the expense amount to the total for the month
      monthlyTotals[month] = monthlyTotals[month]! + expense.amount;
    }

    return monthlyTotals;
  }

  // get start month
  int geetStartMonth() {
    if (_allExpenses.isEmpty) {
      return DateTime.now()
          .month; // default to current month if no expenses are recorded
    }

    // sort expenses by date to find the earliest
    _allExpenses.sort((a, b) => a.date.compareTo(b.date));

    return _allExpenses.first.date.month;
  }

  // gete start year
  int geetStartYear() {
    if (_allExpenses.isEmpty) {
      return DateTime.now()
          .year; // default to current year if no expenses are recorded
    }

    // sort expenses by date to find the earliest
    _allExpenses.sort((a, b) => a.date.compareTo(b.date));

    return _allExpenses.first.date.year;
  }
}

/*

These are some helpful functions used accross the app

*/

import 'package:intl/intl.dart';

// convert string to a double
double convertStringToDouble(String string) {
  double? amount = double.tryParse(string);

  return amount ?? 0;
}

// format double amount into rupee & paisa
String formatAmount(double amount) {
  final format = NumberFormat.currency(
    locale: "en_US",
    symbol: "₹",
    decimalDigits: 2,
  );

  return format.format(amount);
}

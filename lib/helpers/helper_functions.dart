/*

These are some helpful functions used accross the app

*/

// convert string to a double
double convertStringToDouble(String string) {
  double? amount = double.tryParse(string);

  return amount ?? 0;
}
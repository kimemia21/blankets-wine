enum users { nobody, cashier, stockist, bartender }

users user =users.nobody;

String formatWithCommas(String value) {
  try {
    final number = int.parse(value);
    final formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
    return formatted;
  } catch (e) {
    return value; // Return original string if parsing fails
  }
}

import 'package:blankets_and_wines_example/core/constants.dart';
import 'package:blankets_and_wines_example/core/utils/Comms.dart';
import 'package:blankets_and_wines_example/features/cashier/data/UserCashier.dart';

String qrcode = "";
Comms comms = Comms();

UserCashier userCashier = UserCashier.empty();
String baseUrl = "http://167.99.15.36:8080/api/v1";

String userToString(users user) {
  switch (user) {
    case users.nobody:
      return "nobody";
    case users.cashier:
      return "cashier";
    case users.stockist:
      return "stockist";
    default:
      return "unknown";
  }
}

String userDesc(users user) {
  switch (user) {
    case users.nobody:
      return "User not registered in the system";
    case users.cashier:
      return "Staff member responsible for handling transactions and payments";
    case users.stockist:
      return "Staff member responsible for managing inventory and stock";
    default:
      return "Unknown user type";
  }
}


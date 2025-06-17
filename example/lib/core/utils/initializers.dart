import 'package:blankets_and_wines_example/core/constants.dart';
import 'package:blankets_and_wines_example/core/utils/Comms.dart';
import 'package:blankets_and_wines_example/data/models/UserDataPref.dart';
import 'package:blankets_and_wines_example/features/cashier/data/UserCashier.dart';
import 'package:blankets_and_wines_example/features/cashier/models/CartItems.dart';
import 'package:blankets_and_wines_example/preferrences/userPreferences.dart';

String qrcode = "";
Comms comms = Comms();

UserCashier userCashier = UserCashier.empty();
UserPreferencesManager preferences = UserPreferencesManager();
UserData userData = UserData.empty();

Cart cartG = Cart();
String baseUrl = "http://167.99.15.36:8080/api/v1";

users stringToUser(String user) {
  switch (user.toLowerCase()) {
    case "nobody":
      return users.nobody;
    case "cashier":
      return users.cashier;
    case "stockist":
      return users.stockist;
    default:
      return users.nobody;
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

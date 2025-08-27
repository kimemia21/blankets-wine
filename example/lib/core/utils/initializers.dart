import 'package:blankets_and_wines/blankets_and_wines.dart';
import 'package:blankets_and_wines_example/core/constants.dart';
import 'package:blankets_and_wines_example/core/utils/Comms.dart';
import 'package:blankets_and_wines_example/data/models/UserData.dart';
import 'package:blankets_and_wines_example/features/cashier/data/UserCashier.dart';
import 'package:blankets_and_wines_example/features/cashier/models/CartItems.dart';
import 'package:blankets_and_wines_example/preferrences/userPreferences.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';


String qrcode = "";
Comms comms = Comms();

AppUser appUser = AppUser.empty();
UserPreferencesManager preferences = UserPreferencesManager();
UserData userData = UserData.empty();
DeviceInfo deviceInfo = DeviceInfo.empty();



Cart cartG = Cart();
String baseUrl = 
// "http://192.168.100.56:8002/api/v1";
 "http://167.99.15.36:8080/api/v1";

String mode = "online"; // online or offline


users stringToUser(String user) {
  switch (user.toLowerCase()) {
    case "nobody":
      return users.nobody;
    case "cashier":
      return users.cashier;
    case "stockist":
      return users.stockist;
    case "bartender":
      return users.bartender;
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

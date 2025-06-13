import 'package:blankets_and_wines_example/core/utils/ToastService.dart';
import 'package:blankets_and_wines_example/core/utils/initializers.dart';
import 'package:blankets_and_wines_example/features/cashier/data/UserCashier.dart';

class CashierAuth {
  static Future<bool> login({required data}) async {
    try {
      final reg = await comms.postRequest(endpoint: "auth/login", data: data);
      print("#######rsp$reg ##########");

      // Safe null checking
      if (reg["rsp"]?["success"]) {
        userCashier = UserCashier.fromJson(reg["rsp"]["data"]);
        comms.setAuthToken(reg["rsp"]["data"]["token"]);
        ToastService.showSuccess("Success");
        return true;
      } else {
        ToastService.showError(reg["rsp"]["message"]);
        return false;
      }
    } catch (e) {
      // Catches all throwable objects
      ToastService.showError("Error: $e");
      return false;
    }
  }
}

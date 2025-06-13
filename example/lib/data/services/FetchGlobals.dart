import 'package:flutter/material.dart';

Future<List<T>> fetchGlobal<T>({
  required Future<Map<String, dynamic>> Function(String endpoint) getRequests,
  required T Function(Map<String, dynamic> json) fromJson,
  required String endpoint,
}) async {
  try {
    final response = await getRequests(endpoint);

    if (response["success"]) {

      List data = response["rsp"]["data"];
      print(response);
      return data.map((item) => fromJson(item)).toList();
    } else {
      debugPrint("Error fetching data: ${response["rsp"]}");
      return [];
    }
  } catch (e) {
    debugPrint("Exception fetching data: $e");
    return [];
  }
}
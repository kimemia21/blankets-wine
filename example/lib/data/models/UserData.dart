import 'package:hive/hive.dart';
import 'hive_type_ids.dart';
 part 'UserData.g.dart';

@HiveType(typeId: HiveTypeId.userDataPref)
class UserData extends HiveObject {
  @HiveField(0)
  final String userRole;

  @HiveField(1)
  final int userRoleId;

  @HiveField(2)
  final String username;

  @HiveField(3)
  final String password;

  @HiveField(4)
  final bool isLoggedIn;

  @HiveField(5)
  final String phoneNumber;

  UserData({
    required this.userRole,
    required this.userRoleId,
    required this.username,
    required this.password,
    required this.isLoggedIn,
    required this.phoneNumber,
  });

  /// JSON serialization
  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userRole: json['user_role'] ?? '',
      userRoleId: json['user_role_id'] ?? 0,
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      isLoggedIn: json['is_logged_in'] ?? false,
      phoneNumber: json['phone_number'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_role': userRole,
      'user_role_id': userRoleId,
      'username': username,
      'password': password,
      'is_logged_in': isLoggedIn,
      'phone_number': phoneNumber,
    };
  }

  /// Empty debug user
  factory UserData.empty() {
    return UserData(
      userRole: 'debug_role',
      userRoleId: 0,
      username: 'debug_user',
      password: 'debug_password',
      isLoggedIn: false,
      phoneNumber: '+1234567890',
    );
  }

  /// Copy with override
  UserData copyWith({
    String? userRole,
    int? userRoleId,
    String? username,
    String? password,
    bool? isLoggedIn,
    String? phoneNumber,
  }) {
    return UserData(
      userRole: userRole ?? this.userRole,
      userRoleId: userRoleId ?? this.userRoleId,
      username: username ?? this.username,
      password: password ?? this.password,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  String toString() {
    return 'UserData(userRole: $userRole, userRoleId: $userRoleId, username: $username, isLoggedIn: $isLoggedIn, phoneNumber: $phoneNumber)';
  }
}

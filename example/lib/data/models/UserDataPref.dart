class UserData {
  final String userRole;
  final int userRoleId;
  final String username;
  final String password;
  final bool isLoggedIn;
  final String phoneNumber; 

  UserData({
    required this.userRole,
    required this.userRoleId,
    required this.username,
    required this.password,
    required this.isLoggedIn,
    required this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'userRole': userRole,
      'userRoleId': userRoleId,
      'username': username,
      'password': password,
      'isLoggedIn': isLoggedIn,
      'phoneNumber': phoneNumber,
    };
  }

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

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      userRole: map['userRole'] ?? '',
      userRoleId: map['userRoleId'] ?? 0,
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      isLoggedIn: map['isLoggedIn'] ?? false,
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }

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
    return 'UserData(userRole: $userRole, userRoleId: $userRoleId, username: $username, isLoggedIn: $isLoggedIn)';
  }
}
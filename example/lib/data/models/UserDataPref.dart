
// Data model class for user information
class UserData {
  final String userRole;
  final String username;
  final String password;
  final bool isLoggedIn;

  UserData({
    required this.userRole,
    required this.username,
    required this.password,
    required this.isLoggedIn,
  });

  // Convert to Map for easy serialization
  Map<String, dynamic> toMap() {
    return {
      'userRole': userRole,
      'username': username,
      'password': password,
      'isLoggedIn': isLoggedIn,
    };
  }
  // Create an empty instance with debug data
  factory UserData.empty() {
    return UserData(
      userRole: 'debug_role',
      username: 'debug_user',
      password: 'debug_password',
      isLoggedIn: false,
    );
  }



  // Create from Map
  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      userRole: map['userRole'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      isLoggedIn: map['isLoggedIn'] ?? false,
    );
  }

  // Copy with method for easy updates
  UserData copyWith({
    String? userRole,
    String? username,
    String? password,
    bool? isLoggedIn,
  }) {
    return UserData(
      userRole: userRole ?? this.userRole,
      username: username ?? this.username,
      password: password ?? this.password,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }

  @override
  String toString() {
    return 'UserData(userRole: $userRole, username: $username, isLoggedIn: $isLoggedIn)';
  }
}

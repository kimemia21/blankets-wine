class UserData {
  final String userRole;
  final String username;
  final String password;
  final bool isLoggedIn;
  final String phoneNumber; // Added phone number field

  UserData({
    required this.userRole,
    required this.username,
    required this.password,
    required this.isLoggedIn,
    required this.phoneNumber, // Added to constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'userRole': userRole,
      'username': username,
      'password': password,
      'isLoggedIn': isLoggedIn,
      'phoneNumber': phoneNumber, // Added to map
    };
  }

  factory UserData.empty() {
    return UserData(
      userRole: 'debug_role',
      username: 'debug_user',
      password: 'debug_password',
      isLoggedIn: false,
      phoneNumber: '+1234567890', // Added default phone number
    );
  }

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      userRole: map['userRole'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      isLoggedIn: map['isLoggedIn'] ?? false,
      phoneNumber: map['phoneNumber'] ?? '', // Added to fromMap
    );
  }

  UserData copyWith({
    String? userRole,
    String? username,
    String? password,
    bool? isLoggedIn,
    String? phoneNumber, // Added to copyWith
  }) {
    return UserData(
      userRole: userRole ?? this.userRole,
      username: username ?? this.username,
      password: password ?? this.password,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      phoneNumber: phoneNumber ?? this.phoneNumber, // Added to copyWith
    );
  }

  @override
  String toString() {
    return 'UserData(userRole: $userRole, username: $username, isLoggedIn: $isLoggedIn)';
  }
}

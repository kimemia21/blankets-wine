class UserCashier {
  final String fName;
  final String lName;
  final int barId;
  final bool isAdmin;
  final String token;

  UserCashier({
    required this.fName,
    required this.lName,
    required this.barId,
    required this.isAdmin,
    required this.token,
  });


  factory UserCashier.fromJson(Map<String, dynamic> json) {
    return UserCashier(
      fName: json['fName'] ?? '',
      lName: json['lName'] ?? '',
      barId: json['barId'] ?? 0,
      isAdmin: json['isAdmin'] ?? false,
      token: json['token'] ?? '',
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'fName': fName,
      'lName': lName,
      'barId': barId,
      'isAdmin': isAdmin,
      'token': token,
    };
  }
}

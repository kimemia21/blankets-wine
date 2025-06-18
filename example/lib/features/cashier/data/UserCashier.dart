class AppUser {
  final String fName;
  final String lName;
  final int barId;
  final bool isAdmin;
  final String token;

  AppUser({
    required this.fName,
    required this.lName,
    required this.barId,
    required this.isAdmin,
    required this.token,
  });


  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      fName: json['fName'] ?? '',
      lName: json['lName'] ?? '',
      barId: json['barId'] ?? 0,
      isAdmin: json['isAdmin'] ?? false,
      token: json['token'] ?? '',
    );
  }
  factory AppUser.empty() {
    return AppUser(
      fName: '',
      lName: '',
      barId: 1,
      isAdmin: false,
      token: '',
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

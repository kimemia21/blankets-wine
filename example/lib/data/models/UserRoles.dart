class UserRoles {
  final int id;
  final String name;
  final String? description; 

  UserRoles({
    required this.id,
    required this.name,
    this.description,
  });

  factory UserRoles.fromJson(Map<String, dynamic> json) {
    return UserRoles(
      id: json['id'],
      name: json['name'],
      description: json['decription']??"NO DESC", // Note: check spelling
    );
  }

  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'decription': description, // Same spelling as original input
    };
  }
}

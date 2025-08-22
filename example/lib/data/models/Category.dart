class DrinnksCategory {
  final int id;
  final String name;
  final String slug;

  DrinnksCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  // Factory constructor for creating a new DrinnksCategory from a map (JSON)
  factory DrinnksCategory.fromJson(Map<String, dynamic> json) {
    return DrinnksCategory(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
    );
  }

  // Method for converting a DrinnksCategory to a map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }
}

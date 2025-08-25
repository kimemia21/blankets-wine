import 'package:hive/hive.dart';
import 'hive_type_ids.dart';

 part 'DrinkCategory.g.dart';

@HiveType(typeId: HiveTypeId.drinkCategory)
class DrinkCategory extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String slug;

  DrinkCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory DrinkCategory.fromJson(Map<String, dynamic> json) {
    return DrinkCategory(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }
}

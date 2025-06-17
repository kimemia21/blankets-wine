import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/categories_table.dart';
import 'tables/products_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Categories, Products])
class BnwDatabase extends _$BnwDatabase {
  BnwDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Insert default categories if needed
        // await _insertDefaultCategories();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future schema upgrades here
      },
    );
  }

  // // Insert some default categories
  // Future<void> _insertDefaultCategories() async {
  //   final defaultCategories = [
  //     'Electronics',
  //     'Clothing',
  //     'Books',
  //     'Home & Garden',
  //     'Sports',
  //   ];

  //   for (String categoryName in defaultCategories) {
  //     await into(categories).insertOnConflictUpdate(
  //       CategoriesCompanion.insert(name: categoryName),
  //     );
  //   }
  // }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'bnw.db'));
    return NativeDatabase.createInBackground(file);
  });
}
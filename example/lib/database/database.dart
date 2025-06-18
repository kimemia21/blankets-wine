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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      // This will drop and recreate all tables
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onCreate: (Migrator m) async {
        // Create all tables
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Recreate approach: Drop and recreate the Products table
        if (from < 2) {
          // Drop the Products table (this will lose all data)
          await m.drop(products);
          // Recreate the Products table with new schema
          await m.create(products);
        }
      },
    );
  }
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


LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'bnw.db'));
    return NativeDatabase.createInBackground(file);
  });
}
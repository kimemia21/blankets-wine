import 'package:drift/drift.dart';
import 'categories_table.dart';

@DataClassName('Product')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get image => text().nullable()();
  RealColumn get price => real()();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  IntColumn get reorder => integer().withDefault(const Constant(0))();
  IntColumn get productCategory => integer().named('product_category').references(Categories, #id)();
}


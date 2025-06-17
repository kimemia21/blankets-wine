import 'package:drift/drift.dart';
import 'categories_table.dart';

@DataClassName('Product')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  RealColumn get salePrice => real().named('sale_price')();
  RealColumn get retailPrice => real().named('retail_price')();
  BoolColumn get isActive => boolean().withDefault(const Constant(true)).nullable()();
  IntColumn get productCategory => integer().named('product_category').references(Categories, #id)();
  TextColumn get image => text().nullable()();
}   
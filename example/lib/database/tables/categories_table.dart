import 'package:drift/drift.dart';

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().unique()();
  TextColumn get name => text().withLength(min: 1, max: 100).unique()();
}




// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ProductCategory.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductCategoryAdapter extends TypeAdapter<ProductCategory> {
  @override
  final int typeId = 21;

  @override
  ProductCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductCategory(
      categoryId: fields[0] as int,
      categoryName: fields[1] as String,
      products: (fields[2] as List).cast<Product>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProductCategory obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.categoryId)
      ..writeByte(1)
      ..write(obj.categoryName)
      ..writeByte(2)
      ..write(obj.products);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

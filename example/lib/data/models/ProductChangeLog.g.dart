// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ProductChangeLog.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductChangeLogAdapter extends TypeAdapter<ProductChangeLog> {
  @override
  final int typeId = 23;

  @override
  ProductChangeLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductChangeLog(
      id: fields[0] as int,
      productId: fields[1] as int,
      fieldName: fields[2] as String,
      originalValue: fields[3] as String,
      updatedValue: fields[4] as String,
      updatedBy: fields[5] as String,
      timestamp: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ProductChangeLog obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.fieldName)
      ..writeByte(3)
      ..write(obj.originalValue)
      ..writeByte(4)
      ..write(obj.updatedValue)
      ..writeByte(5)
      ..write(obj.updatedBy)
      ..writeByte(6)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductChangeLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

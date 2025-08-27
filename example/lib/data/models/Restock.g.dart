// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Restock.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RestockAdapter extends TypeAdapter<Restock> {
  @override
  final int typeId = 22;

  @override
  Restock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Restock(
      product: fields[0] as Product,
      quantity: fields[1] as int,
      previousQuantity: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Restock obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.product)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.previousQuantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

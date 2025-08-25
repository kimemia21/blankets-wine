// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'DrinkItem.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DrinkItemAdapter extends TypeAdapter<DrinkItem> {
  @override
  final int typeId = 11;

  @override
  DrinkItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DrinkItem(
      productName: fields[0] as String?,
      quantity: fields[1] as int,
      price: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, DrinkItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.productName)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.price);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrinkItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

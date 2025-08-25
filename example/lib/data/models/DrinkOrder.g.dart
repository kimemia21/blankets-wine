// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'DrinkOrder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DrinkOrderAdapter extends TypeAdapter<DrinkOrder> {
  @override
  final int typeId = 12;

  @override
  DrinkOrder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DrinkOrder(
      orderNo: fields[0] as String,
      paymentStatus: fields[1] as int,
      orderDate: fields[2] as DateTime,
      orderTotal: fields[3] as double,
      customerFirstName: fields[4] as String,
      customerLastName: fields[5] as String,
      customerEmail: fields[6] as String,
      customerPhone: fields[7] as String,
      orderItems: (fields[8] as List).cast<DrinkItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, DrinkOrder obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.orderNo)
      ..writeByte(1)
      ..write(obj.paymentStatus)
      ..writeByte(2)
      ..write(obj.orderDate)
      ..writeByte(3)
      ..write(obj.orderTotal)
      ..writeByte(4)
      ..write(obj.customerFirstName)
      ..writeByte(5)
      ..write(obj.customerLastName)
      ..writeByte(6)
      ..write(obj.customerEmail)
      ..writeByte(7)
      ..write(obj.customerPhone)
      ..writeByte(8)
      ..write(obj.orderItems);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrinkOrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

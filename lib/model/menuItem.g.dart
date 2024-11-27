// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menuItem.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MenuItemAdapter extends TypeAdapter<MenuItem> {
  @override
  final int typeId = 0;

  @override
  MenuItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MenuItem(
      id: fields[0] as String,
      name: fields[1] as String,
      price: fields[2] as double,
      offerPrice: fields[3] as double,
      stock: fields[4] as int,
      category: fields[5] as String,
      subCategory: fields[6] as String?,
      unitType: fields[7] as String,
      description: fields[8] as String?,
      imageUrl: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MenuItem obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.offerPrice)
      ..writeByte(4)
      ..write(obj.stock)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.subCategory)
      ..writeByte(7)
      ..write(obj.unitType)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

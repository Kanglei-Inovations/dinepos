// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoiceAdapter extends TypeAdapter<Invoice> {
  @override
  final int typeId = 1;

  @override
  Invoice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Invoice(
      id: fields[0] as int,
      userId: fields[1] as String,
      name: fields[2] as String,
      phone: fields[3] as String,
      address: fields[4] as String,
      status: fields[5] as String,
      subtotal: fields[6] as double,
      discount: fields[7] as double,
      taxRate: fields[8] as double,
      amountPaid: fields[9] as double,
      paymentType: fields[10] as String,
      createdAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Invoice obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.address)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.subtotal)
      ..writeByte(7)
      ..write(obj.discount)
      ..writeByte(8)
      ..write(obj.taxRate)
      ..writeByte(9)
      ..write(obj.amountPaid)
      ..writeByte(10)
      ..write(obj.paymentType)
      ..writeByte(11)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionRecordAdapter extends TypeAdapter<TransactionRecord> {
  @override
  final typeId = 1;

  @override
  TransactionRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionRecord(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      items: (fields[2] as List).cast<CartItem>(),
      subtotal: (fields[3] as num).toDouble(),
      totalProfit: (fields[4] as num).toDouble(),
      amountPaid: (fields[5] as num).toDouble(),
      change: (fields[6] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, TransactionRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.subtotal)
      ..writeByte(4)
      ..write(obj.totalProfit)
      ..writeByte(5)
      ..write(obj.amountPaid)
      ..writeByte(6)
      ..write(obj.change);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

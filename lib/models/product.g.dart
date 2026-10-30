// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final typeId = 0;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Product(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      unit: fields[3] as String,
      hpp: (fields[4] as num).toDouble(),
      retailPrice: (fields[5] as num).toDouble(),
      wholesalePrice: (fields[6] as num).toDouble(),
      sackPrice: (fields[7] as num).toDouble(),
      stock: (fields[8] as num).toDouble(),
      conversionFactor: fields[9] == null
          ? 50.0
          : (fields[9] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.hpp)
      ..writeByte(5)
      ..write(obj.retailPrice)
      ..writeByte(6)
      ..write(obj.wholesalePrice)
      ..writeByte(7)
      ..write(obj.sackPrice)
      ..writeByte(8)
      ..write(obj.stock)
      ..writeByte(9)
      ..write(obj.conversionFactor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

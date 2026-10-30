// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PriceTypeAdapter extends TypeAdapter<PriceType> {
  @override
  final typeId = 3;

  @override
  PriceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PriceType.eceran;
      case 1:
        return PriceType.grosir;
      case 2:
        return PriceType.sak;
      default:
        return PriceType.eceran;
    }
  }

  @override
  void write(BinaryWriter writer, PriceType obj) {
    switch (obj) {
      case PriceType.eceran:
        writer.writeByte(0);
      case PriceType.grosir:
        writer.writeByte(1);
      case PriceType.sak:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

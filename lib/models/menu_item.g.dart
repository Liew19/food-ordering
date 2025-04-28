// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MenuItemAdapter extends TypeAdapter<MenuItem> {
  @override
  final int typeId = 1;

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
      category: fields[3] as String,
      itemId: fields[4] as String,
      imageUrl: fields[5] as String,
      description: fields[6] as String?,
      rating: fields[7] as double?,
      isPopular: fields[8] as bool,
      preparationTime: fields[9] as double,
      canPrepareInParallel: fields.containsKey(10) ? fields[10] as bool : true,
    );
  }

  @override
  void write(BinaryWriter writer, MenuItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.itemId)
      ..writeByte(5)
      ..write(obj.imageUrl)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.rating)
      ..writeByte(8)
      ..write(obj.isPopular)
      ..writeByte(9)
      ..write(obj.preparationTime)
      ..writeByte(10)
      ..write(obj.canPrepareInParallel);
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

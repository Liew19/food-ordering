// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_table.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SharedTableAdapter extends TypeAdapter<SharedTable> {
  @override
  final int typeId = 3;

  @override
  SharedTable read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SharedTable(
      tableId: fields[0] as int,
      status: fields[1] as TableStatus,
      description: fields[2] as String?,
      capacity: fields[3] as int,
      occupiedSeats: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SharedTable obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.tableId)
      ..writeByte(1)
      ..write(obj.status)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.capacity)
      ..writeByte(4)
      ..write(obj.occupiedSeats);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharedTableAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TableStatusAdapter extends TypeAdapter<TableStatus> {
  @override
  final int typeId = 2;

  @override
  TableStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TableStatus.available;
      case 1:
        return TableStatus.occupied;
      case 2:
        return TableStatus.sharing;
      default:
        return TableStatus.available;
    }
  }

  @override
  void write(BinaryWriter writer, TableStatus obj) {
    switch (obj) {
      case TableStatus.available:
        writer.writeByte(0);
        break;
      case TableStatus.occupied:
        writer.writeByte(1);
        break;
      case TableStatus.sharing:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

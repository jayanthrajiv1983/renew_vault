// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppLogAdapter extends TypeAdapter<AppLog> {
  @override
  final int typeId = 0;

  @override
  AppLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppLog(
      timestamp: fields[0] as String,
      level: fields[1] as String,
      category: fields[2] as String,
      message: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppLog obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.level)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.message);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

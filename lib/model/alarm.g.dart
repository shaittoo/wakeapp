// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlarmAdapter extends TypeAdapter<Alarm> {
  @override
  final int typeId = 0;

  @override
  Alarm read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Alarm(
      name: fields[0] as String,
      onEnter: fields[1] as bool,
      onExit: fields[2] as bool,
      radius: fields[3] as double,
      // repeat: fields[4] as bool,
      // days: (fields[5] as List).cast<bool>(),
      // favorite: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Alarm obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.onEnter)
      ..writeByte(2)
      ..write(obj.onExit)
      ..writeByte(3)
      ..write(obj.radius)
      ..writeByte(4);
    // ..write(obj.repeat)
    // ..writeByte(5)
    // ..write(obj.days)
    // ..writeByte(6)
    // ..write(obj.favorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

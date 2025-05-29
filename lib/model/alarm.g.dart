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
      radius: fields[3] as double,
      currentLocation: fields[6] as String,
      destination: fields[7] as String,
      distance: fields[4] as int?,
      travelTime: fields[5] as int?,
      startTrip: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Alarm obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.radius)
      ..writeByte(4)
      ..write(obj.distance)
      ..writeByte(5)
      ..write(obj.travelTime)
      ..writeByte(6)
      ..write(obj.currentLocation)
      ..writeByte(7)
      ..write(obj.destination)
      ..writeByte(8)
      ..write(obj.startTrip);
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

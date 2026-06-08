// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_action.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingActionAdapter extends TypeAdapter<PendingAction> {
  @override
  final int typeId = 2;

  @override
  PendingAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingAction(
      action: fields[0] as String,
      entityType: fields[1] as String,
      entityId: fields[2] as String,
      timestamp: fields[4] as DateTime,
      payload: (fields[3] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, PendingAction obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.action)
      ..writeByte(1)
      ..write(obj.entityType)
      ..writeByte(2)
      ..write(obj.entityId)
      ..writeByte(3)
      ..write(obj.payload)
      ..writeByte(4)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

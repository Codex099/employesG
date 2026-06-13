// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PublicNoteAdapter extends TypeAdapter<PublicNote> {
  @override
  final int typeId = 6;

  @override
  PublicNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PublicNote(
      id: fields[0] as String,
      content: fields[1] as String,
      author: fields[2] as String,
      timestamp: fields[3] as String,
      deletedAt: fields[4] as String?,
      version: fields[5] as int,
      updatedAt: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PublicNote obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.deletedAt)
      ..writeByte(5)
      ..write(obj.version)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

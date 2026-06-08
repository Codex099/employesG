// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmployeeAdapter extends TypeAdapter<Employee> {
  @override
  final int typeId = 3;

  @override
  Employee read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Employee(
      name: fields[0] as String,
      reg: fields[1] as String,
      phone: fields[2] as String,
      address: fields[3] as String,
      status: fields[4] as String,
      blood: fields[5] as String,
      workplace: fields[6] as String,
      children: fields[7] as int?,
      notes: fields[8] as String,
      created: fields[9] as int,
      absence: fields[10] as Absence?,
      deletedAt: fields[11] as String?,
      version: fields[12] as int,
      updatedAt: fields[13] as String,
      archivedAbsences: (fields[14] as List).cast<Absence>(),
      pendingDelete: fields[15] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Employee obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.reg)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.blood)
      ..writeByte(6)
      ..write(obj.workplace)
      ..writeByte(7)
      ..write(obj.children)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.created)
      ..writeByte(10)
      ..write(obj.absence)
      ..writeByte(11)
      ..write(obj.deletedAt)
      ..writeByte(12)
      ..write(obj.version)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.archivedAbsences)
      ..writeByte(15)
      ..write(obj.pendingDelete);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

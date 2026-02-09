// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'money_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MoneyTransactionAdapter extends TypeAdapter<MoneyTransaction> {
  @override
  final int typeId = 1;

  @override
  MoneyTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoneyTransaction(
      id: fields[0] as String,
      personName: fields[1] as String,
      amount: fields[2] as double,
      isCredit: fields[3] as bool,
      note: fields[4] as String,
      date: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MoneyTransaction obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.personName)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.isCredit)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoneyTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookAdapter extends TypeAdapter<Book> {
  @override
  final int typeId = 1;

  @override
  Book read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Book(
      id: fields[0] as String,
      title: fields[1] as String,
      titleSomali: fields[2] as String?,
      description: fields[3] as String?,
      descriptionSomali: fields[4] as String?,
      authors: fields[5] as String?,
      authorsSomali: fields[6] as String?,
      categories: (fields[7] as List?)?.cast<String>(),
      categoryNames: (fields[8] as List?)?.cast<String>(),
      language: fields[9] as String,
      format: fields[10] as String,
      coverImageUrl: fields[11] as String?,
      audioUrl: fields[12] as String?,
      ebookUrl: fields[13] as String?,
      sampleUrl: fields[14] as String?,
      ebookContent: fields[15] as String?,
      duration: fields[16] as int?,
      pageCount: fields[17] as int?,
      rating: fields[18] as double?,
      reviewCount: fields[19] as int?,
      isFeatured: fields[20] as bool,
      isNewRelease: fields[21] as bool,
      isPremium: fields[22] as bool,
      metadata: (fields[23] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[24] as DateTime,
      updatedAt: fields[25] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Book obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.titleSomali)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.descriptionSomali)
      ..writeByte(5)
      ..write(obj.authors)
      ..writeByte(6)
      ..write(obj.authorsSomali)
      ..writeByte(7)
      ..write(obj.categories)
      ..writeByte(8)
      ..write(obj.categoryNames)
      ..writeByte(9)
      ..write(obj.language)
      ..writeByte(10)
      ..write(obj.format)
      ..writeByte(11)
      ..write(obj.coverImageUrl)
      ..writeByte(12)
      ..write(obj.audioUrl)
      ..writeByte(13)
      ..write(obj.ebookUrl)
      ..writeByte(14)
      ..write(obj.sampleUrl)
      ..writeByte(15)
      ..write(obj.ebookContent)
      ..writeByte(16)
      ..write(obj.duration)
      ..writeByte(17)
      ..write(obj.pageCount)
      ..writeByte(18)
      ..write(obj.rating)
      ..writeByte(19)
      ..write(obj.reviewCount)
      ..writeByte(20)
      ..write(obj.isFeatured)
      ..writeByte(21)
      ..write(obj.isNewRelease)
      ..writeByte(22)
      ..write(obj.isPremium)
      ..writeByte(23)
      ..write(obj.metadata)
      ..writeByte(24)
      ..write(obj.createdAt)
      ..writeByte(25)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

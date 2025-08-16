import 'package:hive/hive.dart';

@HiveType(typeId: 1)
enum ClipCategory {
  @HiveField(0)
  link,
  @HiveField(1)
  email,
  @HiveField(2)
  phone,
  @HiveField(3)
  code,
  @HiveField(4)
  note,
}

@HiveType(typeId: 2)
class ClipItem {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String content;
  @HiveField(2)
  final ClipCategory category;
  @HiveField(3)
  final DateTime timestamp;
  @HiveField(4)
  final bool isFavorite;

  const ClipItem({
    required this.id,
    required this.content,
    required this.category,
    required this.timestamp,
    this.isFavorite = false,
  });

  ClipItem copyWith({
    String? id,
    String? content,
    ClipCategory? category,
    DateTime? timestamp,
    bool? isFavorite,
  }) {
    return ClipItem(
      id: id ?? this.id,
      content: content ?? this.content,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

// ========== Manual TypeAdapters (no build_runner needed) ==========
class ClipCategoryAdapter extends TypeAdapter<ClipCategory> {
  @override
  final int typeId = 1;

  @override
  ClipCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ClipCategory.link;
      case 1:
        return ClipCategory.email;
      case 2:
        return ClipCategory.phone;
      case 3:
        return ClipCategory.code;
      case 4:
      default:
        return ClipCategory.note;
    }
  }

  @override
  void write(BinaryWriter writer, ClipCategory obj) {
    switch (obj) {
      case ClipCategory.link:
        writer.writeByte(0);
        break;
      case ClipCategory.email:
        writer.writeByte(1);
        break;
      case ClipCategory.phone:
        writer.writeByte(2);
        break;
      case ClipCategory.code:
        writer.writeByte(3);
        break;
      case ClipCategory.note:
        writer.writeByte(4);
        break;
    }
  }
}

class ClipItemAdapter extends TypeAdapter<ClipItem> {
  @override
  final int typeId = 2;

  @override
  ClipItem read(BinaryReader reader) {
    final id = reader.readString();
    final content = reader.readString();
    final category = ClipCategoryAdapter().read(reader);
    final timestamp = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final isFavorite = reader.readBool();
    return ClipItem(
      id: id,
      content: content,
      category: category,
      timestamp: timestamp,
      isFavorite: isFavorite,
    );
  }

  @override
  void write(BinaryWriter writer, ClipItem obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.content);
    ClipCategoryAdapter().write(writer, obj.category);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    writer.writeBool(obj.isFavorite);
  }
}

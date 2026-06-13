import 'dart:convert';
import 'package:hive/hive.dart';

part 'public_note.g.dart';

@HiveType(typeId: 6)
class PublicNote extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final String author;

  @HiveField(3)
  final String timestamp; // ISO Date

  @HiveField(4)
  final String? deletedAt;

  @HiveField(5)
  final int version;

  @HiveField(6)
  final String updatedAt;

  PublicNote({
    required this.id,
    required this.content,
    required this.author,
    required this.timestamp,
    this.deletedAt,
    this.version = 1,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'author': author,
      'timestamp': timestamp,
      'deletedAt': deletedAt ?? '',
      'version': version,
      'updatedAt': updatedAt,
    };
  }

  factory PublicNote.fromMap(Map<dynamic, dynamic> map) {
    return PublicNote(
      id: map['id']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      author: map['author']?.toString() ?? '',
      timestamp: map['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      deletedAt: map['deletedAt']?.toString() == '' ? null : map['deletedAt']?.toString(),
      version: int.tryParse(map['version']?.toString() ?? '1') ?? 1,
      updatedAt: map['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  String toJson() => json.encode(toMap());

  factory PublicNote.fromJson(String source) => PublicNote.fromMap(json.decode(source));
}

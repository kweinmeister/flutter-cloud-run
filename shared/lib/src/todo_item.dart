import 'package:json_annotation/json_annotation.dart';
import 'constants.dart';

part 'todo_item.g.dart';

/// A todo item in the task list.
///
/// Server-side:
/// - `id` is auto-generated and immutable
/// - `createdAt` is set to server timestamp on creation
///
/// Client-side:
/// - Can toggle `isDone` status
/// - Can update `title` (subject to validation)
@JsonSerializable()
class TodoItem {
  @JsonKey(defaultValue: '')
  final String id;
  final String title;

  @JsonKey(defaultValue: false)
  final bool isDone;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  TodoItem({
    required this.id,
    required this.title,
    required this.createdAt,
    this.isDone = false,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) =>
      _$TodoItemFromJson(json);

  Map<String, dynamic> toJson() => _$TodoItemToJson(this);

  TodoItem copyWith({
    String? id,
    String? title,
    bool? isDone,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

extension TodoItemValidation on TodoItem {
  // Returns sanitized title
  String get sanitizedTitle => title
      .trim()
      .replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  // Returns null if valid, or error message string
  String? validate() {
    if (sanitizedTitle.isEmpty) return 'Title cannot be empty';
    if (sanitizedTitle.length > ApiConstants.maxTitleLength) {
      return 'Title too long (max ${ApiConstants.maxTitleLength})';
    }
    return null;
  }
}

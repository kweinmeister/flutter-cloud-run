// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TodoItem _$TodoItemFromJson(Map<String, dynamic> json) => TodoItem(
  id: json['id'] as String? ?? '',
  title: json['title'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  isDone: json['isDone'] as bool? ?? false,
);

Map<String, dynamic> _$TodoItemToJson(TodoItem instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'isDone': instance.isDone,
  'created_at': instance.createdAt.toIso8601String(),
};

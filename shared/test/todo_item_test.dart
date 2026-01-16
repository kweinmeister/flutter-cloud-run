import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('TodoItem', () {
    test('creates TodoItem from JSON', () {
      final json = {
        'id': 'test-123',
        'title': 'Test Todo',
        'isDone': true,
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final item = TodoItem.fromJson(json);

      expect(item.id, equals('test-123'));
      expect(item.title, equals('Test Todo'));
      expect(item.isDone, equals(true));
      expect(item.createdAt, isA<DateTime>());
    });

    test('converts TodoItem to JSON', () {
      final item = TodoItem(
        id: 'test-456',
        title: 'My Task',
        isDone: false,
        createdAt: DateTime.utc(2024, 1, 15, 10, 30),
      );

      final json = item.toJson();

      expect(json['id'], equals('test-456'));
      expect(json['title'], equals('My Task'));
      expect(json['isDone'], equals(false));
      expect(json['created_at'], isNotNull);
    });

    test('uses default value for isDone if not provided', () {
      final json = {
        'id': 'test',
        'title': 'Test',
        'created_at': DateTime.now().toIso8601String(),
      };

      final item = TodoItem.fromJson(json);

      expect(item.isDone, equals(false));
    });

    test('roundtrip conversion preserves data', () {
      final original = TodoItem(
        id: 'original',
        title: 'Round Trip Test',
        isDone: true,
        createdAt: DateTime.utc(2024, 1, 1),
      );

      final json = original.toJson();
      final restored = TodoItem.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.isDone, equals(original.isDone));
      expect(
        restored.createdAt.toIso8601String(),
        equals(original.createdAt.toIso8601String()),
      );
    });

    test('copyWith creates new instance', () {
      final original = TodoItem(
        id: 'test',
        title: 'Original',
        isDone: false,
        createdAt: DateTime.utc(2024, 1, 1),
      );

      final updated = original.copyWith(title: 'Updated');

      expect(original.title, equals('Original'));
      expect(updated.title, equals('Updated'));
      expect(updated.id, equals(original.id));
      expect(updated.isDone, equals(original.isDone));
    });

    test('copyWith with all fields', () {
      final original = TodoItem(
        id: 'old-id',
        title: 'Old Title',
        isDone: false,
        createdAt: DateTime.utc(2024, 1, 1),
      );

      final updated = original.copyWith(
        id: 'new-id',
        title: 'New Title',
        isDone: true,
        createdAt: DateTime.utc(2024, 1, 2),
      );

      expect(updated.id, equals('new-id'));
      expect(updated.title, equals('New Title'));
      expect(updated.isDone, isTrue);
      expect(updated.createdAt, equals(DateTime.utc(2024, 1, 2)));
    });

    test('copyWith with no fields keeps original', () {
      final original = TodoItem(
        id: 'test',
        title: 'Test',
        isDone: true,
        createdAt: DateTime.utc(2024, 1, 1),
      );

      final copy = original.copyWith();

      expect(copy.id, equals(original.id));
      expect(copy.title, equals(original.title));
      expect(copy.isDone, equals(original.isDone));
      expect(copy.createdAt, equals(original.createdAt));
    });
  });

  group('ApiConstants', () {
    test('has expected values', () {
      expect(ApiConstants.todosPath, equals('/api/todos'));
      expect(ApiConstants.todoOrderBy, equals('created_at desc'));
      expect(ApiConstants.maxTitleLength, equals(255));
      expect(ApiConstants.defaultPageSize, equals(50));
      expect(ApiConstants.defaultPort, equals(8080));
      expect(ApiConstants.localBackendUrl, equals('http://localhost:8080'));
    });

    test('maxTitleLength is reasonable', () {
      expect(ApiConstants.maxTitleLength, greaterThan(0));
      expect(ApiConstants.maxTitleLength, lessThan(1000));
    });

    test('defaultPageSize is reasonable', () {
      expect(ApiConstants.defaultPageSize, greaterThan(0));
      expect(ApiConstants.defaultPageSize, lessThanOrEqualTo(100));
    });
  });
}

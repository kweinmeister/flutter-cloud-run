import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:frontend/todo_client.dart';

void main() {
  group('TodoClient', () {
    // Note: The tests for fetchTodos, createTodo, etc. are currently disabled
    // because MockClient injection is not yet implemented in TodoClient.

    group('TodosResponse', () {
      test('constructs with items and token', () {
        final items = [
          TodoItem(
            id: '1',
            title: 'Test',
            createdAt: DateTime.now(),
            isDone: false,
          ),
        ];
        final response = TodosResponse(items, 'token-123');

        expect(response.items, hasLength(1));
        expect(response.nextPageToken, equals('token-123'));
      });

      test('constructs with null token', () {
        final response = TodosResponse([], null);
        expect(response.nextPageToken, isNull);
      });
    });
  });
}
